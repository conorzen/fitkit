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
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @State var currentStep = 0
    @State var selectedGoal: Models.RunningGoal = .beginnerFitness
    @State var fitnessLevel: Models.FitnessLevel = .beginner
    @State var raceDistance: Double = 5.0
    @State var targetTime: TimeInterval = 30 * 60
    @State var availableDays = Set<Models.Weekday>()
    @State var preferredTimeOfDay: Models.TimeOfDay = .morning
    @State var current5KTime: TimeInterval = 30 * 60
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showingSummary = false
    @State private var targetDate = Date().addingTimeInterval(8 * 7 * 24 * 60 * 60) // 8 weeks from now
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Progress indicator
                    HStack(spacing: 24) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(index <= currentStep ? CustomColors.Brand.primary : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.top)
                    
                    // Main content
                    TabView(selection: $currentStep) {
                        steps.firstStep
                            .tag(0)
                        steps.secondStep
                            .tag(1)
                        steps.thirdStep
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbar.makeToolbarContent()
            }
            .sheet(isPresented: $showingSummary) {
                NavigationView {
                    PlanSummaryView(
                        goal: convertToRunningGoal(selectedGoal),
                        fitnessLevel: fitnessLevel,
                        targetDate: targetDate,
                        raceDistance: raceDistance,
                        targetTime: targetTime,
                        onConfirm: {
                            showingSummary = false
                            createPlan()
                        }
                    )
                }
            }
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func convertToRunningGoal(_ goal: Models.RunningGoal) -> RunningGoal {
        switch goal {
        case .beginnerFitness:
            return .beginnerFitness
        case .couchTo5K:
            return .couchTo5K
        case .raceTraining:
            return .raceTraining(distance: raceDistance, targetTime: targetTime)
        case .improvePace:
            return .improvePace
        }
    }
    
    private var steps: RunningPlanSteps {
        RunningPlanSteps(
            selectedGoal: $selectedGoal,
            fitnessLevel: $fitnessLevel,
            raceDistance: $raceDistance,
            targetTime: $targetTime,
            availableDays: $availableDays,
            preferredTimeOfDay: $preferredTimeOfDay,
            current5KTime: $current5KTime,
            targetDate: $targetDate
        )
    }
    
    private var toolbar: RunningPlanToolbar {
        RunningPlanToolbar(
            currentStep: currentStep,
            canProceedToNextStep: canProceedToNextStep,
            canCreatePlan: canCreatePlan,
            onBack: { currentStep -= 1 },
            onNext: { currentStep += 1 },
            onCreatePlan: { showingSummary = true }
        )
    }
    
    private var navigationTitle: String {
        switch currentStep {
        case 0: return "Choose Your Goal"
        case 1: return "Your Experience"
        case 2: return "Schedule"
        default: return ""
        }
    }
    
    private var canProceedToNextStep: Bool {
        switch currentStep {
        case 0:
            return true
        case 1:
            if case .raceTraining = selectedGoal {
                return raceDistance > 0 && targetTime > 0
            }
            return true  // Allow proceeding from fitness details for non-race goals
        default:
            return true
        }
    }
    
    private var canCreatePlan: Bool {
        !availableDays.isEmpty
    }
    
    private func createPlan() {
        var workouts: [Date: [WorkoutItem]] = [:]
        let calendar = Calendar.current
        let numberOfWeeks = Calendar.current.dateComponents([.weekOfYear], from: Date(), to: targetDate).weekOfYear ?? 8
        
        // Generate workouts for each week
        for weekOffset in 0..<numberOfWeeks {
            for day in availableDays {
                guard let date = calendar.date(byAdding: .day, value: weekOffset * 7 + day.dayValue - calendar.component(.weekday, from: Date()), to: Date()) else { continue }
                
                let workout = createWorkoutForWeek(
                    week: weekOffset,
                    totalWeeks: numberOfWeeks,
                    goal: selectedGoal,
                    fitnessLevel: fitnessLevel
                )
                
                workouts[date] = [workout]
            }
        }
        
        // Post notification with workouts
        NotificationCenter.default.post(
            name: .planCreated,
            object: workouts
        )
        dismiss()
    }
    
    private func createWorkoutForWeek(week: Int, totalWeeks: Int, goal: Models.RunningGoal, fitnessLevel: Models.FitnessLevel) -> WorkoutItem {
        let phase: String
        let details: String
        
        // Determine training phase
        if week < totalWeeks / 4 {
            phase = "Foundation"
        } else if week < (totalWeeks * 3) / 4 {
            phase = "Development"
        } else {
            phase = "Peak"
        }
        
        // Create workout based on goal and phase
        switch goal {
        case .beginnerFitness:
            details = createBeginnerWorkout(week: week, phase: phase)
        case .couchTo5K:
            details = createCouch5KWorkout(week: week, phase: phase)
        case .raceTraining:
            details = createRaceWorkout(week: week, phase: phase, distance: raceDistance)
        case .improvePace:
            details = createSpeedWorkout(week: week, phase: phase, fitnessLevel: fitnessLevel)
        }
        
        return WorkoutItem(
            title: "\(phase) Training",
            details: details,
            iconName: "figure.run",
            gradient: [CustomColors.Brand.primary, CustomColors.Brand.secondary]
        )
    }
    
    private func createBeginnerWorkout(week: Int, phase: String) -> String {
        switch phase {
        case "Foundation":
            return "20-30 min • Easy Pace"
        case "Development":
            return "30-40 min • Easy-Moderate Pace"
        case "Peak":
            return "40-45 min • Moderate Pace"
        default:
            return "30 min • Easy Pace"
        }
    }
    
    private func createCouch5KWorkout(week: Int, phase: String) -> String {
        switch phase {
        case "Foundation":
            return "Run/Walk • 20-30 min"
        case "Development":
            return "Run • 25-35 min"
        case "Peak":
            return "5K Practice • 30-40 min"
        default:
            return "Run/Walk • 30 min"
        }
    }
    
    private func createRaceWorkout(week: Int, phase: String, distance: Double) -> String {
        switch phase {
        case "Foundation":
            return "Base Building • \(Int(distance * 0.4))K"
        case "Development":
            return "Race Pace • \(Int(distance * 0.6))K"
        case "Peak":
            return "Race Simulation • \(Int(distance * 0.8))K"
        default:
            return "Easy Run • \(Int(distance * 0.5))K"
        }
    }
    
    private func createSpeedWorkout(week: Int, phase: String, fitnessLevel: Models.FitnessLevel) -> String {
        switch phase {
        case "Foundation":
            return "Tempo Run • 30-40 min"
        case "Development":
            return "Intervals • 40-50 min"
        case "Peak":
            return "Speed Work • 45-60 min"
        default:
            return "Easy Run • 40 min"
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

