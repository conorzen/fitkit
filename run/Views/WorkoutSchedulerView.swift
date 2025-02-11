import SwiftUI
import WorkoutKit
import HealthKit

struct WorkoutSchedulerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var workoutName = ""
    @State private var selectedDistance = 5.0
    @State private var targetPace = 5.5 // minutes per km
    @State private var showingDatePicker = false
    @State private var scheduledDate = Date()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showingPreview = false
    @State private var isAuthorized = false
    
    // New workout structure states
    @State private var includeWarmup = false
    @State private var warmupDuration = 5.0 // minutes
    @State private var isIntervalWorkout = false
    @State private var intervalCount = 4
    @State private var intervalWorkDistance = 0.4 // km
    @State private var intervalRestDistance = 0.1 // km
    
    let distances = [3.0, 5.0, 10.0, 21.1, 42.2] // Common running distances in km
    let warmupDurations = [5.0, 10.0, 15.0, 20.0]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Workout Details")) {
                    TextField("Workout Name", text: $workoutName)
                    
                    if !isIntervalWorkout {
                        Picker("Distance", selection: $selectedDistance) {
                            ForEach(distances, id: \.self) { distance in
                                Text(formatDistance(distance))
                            }
                        }
                    }
                    
                    Toggle("Interval Workout", isOn: $isIntervalWorkout)
                }
                
                if isIntervalWorkout {
                    Section(header: Text("Interval Structure")) {
                        Stepper("Intervals: \(intervalCount)", value: $intervalCount, in: 1...20)
                        
                        HStack {
                            Text("Work Distance")
                            Spacer()
                            HStack {
                                Button(action: { adjustIntervalWork(-0.1) }) {
                                    Image(systemName: "minus.circle.fill")
                                }
                                Text(formatDistance(intervalWorkDistance))
                                    .frame(width: 70)
                                Button(action: { adjustIntervalWork(0.1) }) {
                                    Image(systemName: "plus.circle.fill")
                                }
                            }
                        }
                        
                        HStack {
                            Text("Rest Distance")
                            Spacer()
                            HStack {
                                Button(action: { adjustIntervalRest(-0.1) }) {
                                    Image(systemName: "minus.circle.fill")
                                }
                                Text(formatDistance(intervalRestDistance))
                                    .frame(width: 70)
                                Button(action: { adjustIntervalRest(0.1) }) {
                                    Image(systemName: "plus.circle.fill")
                                }
                            }
                        }
                        
                        Text("Total Distance: \(formatDistance(calculateTotalDistance()))")
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("Warm-up")) {
                    Toggle("Include Warm-up", isOn: $includeWarmup)
                    
                    if includeWarmup {
                        Picker("Duration", selection: $warmupDuration) {
                            ForEach(warmupDurations, id: \.self) { duration in
                                Text("\(Int(duration)) minutes")
                            }
                        }
                    }
                }
                
                Section(header: Text("Target Pace")) {
                    HStack {
                        Text("Target Pace")
                        Spacer()
                        HStack {
                            Button(action: { adjustPace(-0.1) }) {
                                Image(systemName: "minus.circle.fill")
                            }
                            Text(formatPace(targetPace))
                                .frame(width: 70)
                            Button(action: { adjustPace(0.1) }) {
                                Image(systemName: "plus.circle.fill")
                            }
                        }
                    }
                }
                
                Section(header: Text("Schedule")) {
                    DatePicker(
                        "Start Time",
                        selection: $scheduledDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                
                Section {
                    Button(action: { showingPreview = true }) {
                        HStack {
                            Spacer()
                            Text("Preview Workout")
                            Spacer()
                        }
                    }
                    .foregroundColor(.white)
                    .listRowBackground(
                        LinearGradient(
                            colors: [CustomColors.Brand.primary, CustomColors.Brand.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
            }
            .navigationTitle("Schedule Run")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .alert("Workout Scheduler", isPresented: $showAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text(alertMessage)
            }
            .workoutPreview(WorkoutPlan(.custom(createWorkout())), isPresented: $showingPreview)
            .task {
                await requestWorkoutAuthorization()
            }
        }
    }
    
    private func requestWorkoutAuthorization() async {
        do {
            try await WorkoutScheduler.shared.requestAuthorization()
            isAuthorized = true
        } catch {
            alertMessage = "Failed to get workout authorization: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func createWorkout() -> CustomWorkout {
        var blocks: [IntervalBlock] = []
        
        // Create the main workout blocks
        if isIntervalWorkout {
            // Create interval workout
            let workStep = IntervalStep(
                .work,
                goal: .distance(intervalWorkDistance * 1000, .meters)
            )
            
            let restStep = IntervalStep(
                .recovery,
                goal: .distance(intervalRestDistance * 1000, .meters)
            )
            
            blocks.append(IntervalBlock(
                steps: [workStep, restStep],
                iterations: intervalCount
            ))
        } else {
            // Create regular distance workout
            let mainStep = IntervalStep(
                .work,
                goal: .distance(selectedDistance * 1000, .meters)
            )
            blocks.append(IntervalBlock(steps: [mainStep], iterations: 1))
        }
        
        // Create warm-up if included
        let warmup = includeWarmup ? WorkoutStep(
            goal: .time(warmupDuration * 60, .seconds)
        ) : nil
        
        return CustomWorkout(
            activity: .running,
            location: .outdoor,
            displayName: workoutName.isEmpty ? "Scheduled Run" : workoutName,
            warmup: warmup,
            blocks: blocks
        )
    }
    
    private func scheduleWorkout() {
        Task {
            do {
                guard isAuthorized else {
                    await requestWorkoutAuthorization()
                    return
                }
                
                let workout = createWorkout()
                let plan = WorkoutPlan(.custom(workout))
                
                let calendar = Calendar.current
                let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledDate)
                
                try await WorkoutScheduler.shared.schedule(plan, at: dateComponents)
                
                DispatchQueue.main.async {
                    alertMessage = "Workout scheduled successfully!"
                    showAlert = true
                }
                
            } catch {
                DispatchQueue.main.async {
                    alertMessage = "Failed to schedule workout: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    private func adjustPace(_ adjustment: Double) {
        targetPace = max(3.0, min(10.0, targetPace + adjustment))
    }
    
    private func adjustIntervalWork(_ adjustment: Double) {
        intervalWorkDistance = max(0.1, min(2.0, intervalWorkDistance + adjustment))
    }
    
    private func adjustIntervalRest(_ adjustment: Double) {
        intervalRestDistance = max(0.1, min(1.0, intervalRestDistance + adjustment))
    }
    
    private func calculateTotalDistance() -> Double {
        if isIntervalWorkout {
            return Double(intervalCount) * (intervalWorkDistance + intervalRestDistance)
        }
        return selectedDistance
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(distance))km"
        } else {
            return String(format: "%.1fkm", distance)
        }
    }
    
    private func formatPace(_ pace: Double) -> String {
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d/km", minutes, seconds)
    }
}

#Preview {
    WorkoutSchedulerView()
} 
