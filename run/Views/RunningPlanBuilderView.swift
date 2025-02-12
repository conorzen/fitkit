import SwiftUI
import WorkoutKit

enum RunningGoal: Equatable {
    case beginnerFitness
    case couchTo5K
    case raceTraining(distance: Double, targetTime: TimeInterval)
    case improvePace
    
    static func == (lhs: RunningGoal, rhs: RunningGoal) -> Bool {
        switch (lhs, rhs) {
        case (.beginnerFitness, .beginnerFitness):
            return true
        case (.couchTo5K, .couchTo5K):
            return true
        case let (.raceTraining(d1, t1), .raceTraining(d2, t2)):
            return d1 == d2 && t1 == t2
        case (.improvePace, .improvePace):
            return true
        default:
            return false
        }
    }
}

struct RunningPlanBuilderView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedGoal: Models.RunningGoal = .beginnerFitness
    @State private var fitnessLevel: Models.FitnessLevel = .beginner
    @State private var targetDate = Date().addingTimeInterval(8 * 7 * 24 * 60 * 60)
    @State private var raceDistance: Double = 5.0
    @State private var targetTime: TimeInterval = 1800
    @State private var showSummary = false
    @State var availableDays: Set<Models.Weekday> = [.monday, .wednesday, .friday]
    @State var preferredTimeOfDay: Models.TimeOfDay = .morning
    @State private var authorizationState: WorkoutScheduler.AuthorizationState = .notDetermined
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    Picker("Goal", selection: $selectedGoal) {
                        ForEach(Models.RunningGoal.allCases, id: \.self) { goal in
                            Text(goal.rawValue).tag(goal)
                        }
                    }
                }
                
                if selectedGoal == .raceTraining {
                    Section("Race Details") {
                        // Race distance and time inputs
                    }
                }
                
                // ... rest of the form ...
                
                Section {
                    switch authorizationState {
                    case .notDetermined:
                        Button("Request Watch Authorization") {
                            Task {
                                let newState = await WorkoutScheduler.shared.requestAuthorization()
                                await MainActor.run {
                                    authorizationState = newState
                                }
                            }
                        }
                    case .authorized:
                        Button("Schedule Workouts") {
                            Task {
                                await scheduleWorkouts()
                            }
                        }
                    case .denied:
                        Text("Watch access denied. Please enable in Settings.")
                            .foregroundColor(.red)
                    case .restricted:
                        Text("Watch access restricted.")
                            .foregroundColor(.red)
                    @unknown default:
                        Text("Unknown authorization state")
                            .foregroundColor(.red)
                    }
                } footer: {
                    Text("Current authorization state: \(authorizationStateDescription)")
                }
            }
            .navigationTitle("Create Training Plan")
            .task {
                // Check authorization state when view appears
                authorizationState = await WorkoutScheduler.shared.authorizationState
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func scheduleWorkouts() async {
        do {
            // Generate workouts based on the selected goal and fitness level
            let trainingPlan = TrainingPlan.create(
                userId: authManager.currentUser?.id ?? UUID(),
                name: "Training Plan",
                goal: selectedGoal,
                startDate: Date(),
                endDate: targetDate,
                fitnessLevel: fitnessLevel,
                workoutDays: Array(availableDays),
                preferredTime: preferredTimeOfDay,
                current5KTime: nil,
                targetRaceDistance: raceDistance,
                targetRaceTime: targetTime
            )
            
            // Schedule each workout
            for workout in trainingPlan.workouts {
                // Convert PlannedWorkout to WorkoutPlan using TrainingPlanService
                let workoutPlan = createWorkoutPlan(from: workout)
                
                var dateComponents = Calendar.current.dateComponents(
                    [.year, .month, .day],
                    from: workout.date
                )
                
                // Add preferred time
                switch preferredTimeOfDay {
                case .morning: dateComponents.hour = 8
                case .afternoon: dateComponents.hour = 14
                case .evening: dateComponents.hour = 18
                }
                dateComponents.minute = 0
                
                // Schedule with WorkoutKit
                try await WorkoutScheduler.shared.schedule(workoutPlan, at: dateComponents)
            }
            
            await MainActor.run {
                dismiss()
            }
        } catch {
            print("Error scheduling workouts: \(error)")
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func createWorkoutPlan(from workout: PlannedWorkout) -> WorkoutPlan {
        // Create warmup - 10 minute easy jog
        let warmupStep = WorkoutStep(
            goal: .time(10, .minutes),
            displayName: "Warm Up - Easy Jog"
        )
        
        // Create main workout block based on workout type
        var workStep = IntervalStep(.work)
        if let distance = workout.distance {
            workStep.step.goal = .distance(distance, .kilometers)
        } else {
            workStep.step.goal = .time(workout.duration, .seconds)
        }
        workStep.step.displayName = workout.workoutType.title
        
        // Create cooldown - 5 minute walk
        let cooldownStep = WorkoutStep(
            goal: .time(5, .minutes),
            displayName: "Cool Down - Walk"
        )
        
        // Create the complete workout
        let customWorkout = CustomWorkout(
            activity: .running,
            location: .outdoor,
            displayName: workout.workoutType.title,
            warmup: warmupStep,
            blocks: [IntervalBlock(steps: [workStep], iterations: 1)],
            cooldown: cooldownStep
        )
        
        return WorkoutPlan(.custom(customWorkout))
    }
    
    private var authorizationStateDescription: String {
        switch authorizationState {
        case .notDetermined: return "Not yet requested"
        case .restricted: return "Restricted by system"
        case .denied: return "Denied by user"
        case .authorized: return "Authorized"
        @unknown default: return "Unknown"
        }
    }
}

extension Weekday {
    var dayValue: Int {
        switch self {
        case .monday: return 0
        case .tuesday: return 1
        case .wednesday: return 2
        case .thursday: return 3
        case .friday: return 4
        case .saturday: return 5
        case .sunday: return 6
        }
    }
}

extension Models.Weekday {
    var calendarWeekday: Int {
        switch self {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        }
    }
}

// MARK: - Supporting Views

struct StepProgressView: View {
    let currentStep: Int
    
    var body: some View {
        HStack {
            ForEach(1...4, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? Color.blue : Color.gray)
                    .frame(width: 10, height: 10)
                
                if step < 4 {
                    Rectangle()
                        .fill(step < currentStep ? Color.blue : Color.gray)
                        .frame(height: 2)
                }
            }
        }
    }
}


#Preview{
    RunningPlanBuilderView()
}

