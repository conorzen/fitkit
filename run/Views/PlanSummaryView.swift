import SwiftUI

struct PlanSummaryView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var trainingPlanService: TrainingPlanService
    @Environment(\.dismiss) var dismiss
    
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showAuth = false
    
    let goal: Models.RunningGoal
    let fitnessLevel: Models.FitnessLevel
    let targetDate: Date
    let raceDistance: Double
    let targetTime: TimeInterval
    let availableDays: [Models.Weekday]
    
    private var weeks: Int {
        Calendar.current.dateComponents([.weekOfYear], from: Date(), to: targetDate).weekOfYear ?? 0
    }
    
    private func generatePlanName() -> String {
        switch goal {
        case .beginnerFitness:
            return "Beginner Fitness Plan"
        case .couchTo5K:
            return "Couch to 5K Plan"
        case .raceTraining:
            return "\(formatDistance(raceDistance)) Race Plan"
        case .improvePace:
            return "Speed Improvement Plan"
        }
    }
    
    private func createPlan() {
        isLoading = true
        
        Task {
            do {
                // First check if we're authenticated
                if authManager.currentUser == nil {
                    print("No user logged in, showing authentication")
                    await MainActor.run {
                        isLoading = false
                        showAuth = true
                    }
                    return
                }
                
                print("Current user: \(String(describing: authManager.currentUser))")
                
                guard let user = authManager.currentUser else {
                    throw NSError(domain: "PlanSummaryView", code: 1, 
                                userInfo: [NSLocalizedDescriptionKey: "Please log in to create a plan"])
                }
                
                let plan = TrainingPlan(
                    id: UUID(),
                    userId: user.id,
                    name: generatePlanName(),
                    goal: goal,
                    startDate: Date(),
                    endDate: targetDate,
                    fitnessLevel: fitnessLevel,
                    workoutDays: availableDays,
                    preferredTime: .morning,
                    workouts: [],
                    current5KTime: nil,
                    targetRaceDistance: goal == .raceTraining ? raceDistance : nil,
                    targetRaceTime: goal == .raceTraining ? targetTime : nil,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                try await trainingPlanService.savePlan(plan)
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showError = true
                    errorMessage = error.localizedDescription
                    print("Error creating plan: \(error)")
                }
            }
        }
    }
    
    private func generateWorkoutDays() -> [Models.Weekday] {
        switch fitnessLevel {
        case .beginner:
            return [.monday, .wednesday, .saturday]
        case .intermediate:
            return [.monday, .wednesday, .friday, .sunday]
        case .advanced:
            return [.monday, .tuesday, .thursday, .friday, .sunday]
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Goal Summary Card
                SummaryCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(
                            goalTitle,
                            systemImage: goalIcon
                        )
                        .font(.headline)
                        
                        Text(goalDescription)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                // Training Details
                VStack(alignment: .leading, spacing: 16) {
                    Text("Training Details")
                        .font(.headline)
                    
                    DetailRow(
                        title: "Duration",
                        value: "\(weeks) weeks",
                        icon: "calendar"
                    )
                    
                    DetailRow(
                        title: "Weekly Runs",
                        value: recommendedRunsPerWeek,
                        icon: "figure.run"
                    )
                    
                    if case .raceTraining = goal {
                        DetailRow(
                            title: "Target Distance",
                            value: formatDistance(raceDistance),
                            icon: "flag.checkered"
                        )
                        
                        DetailRow(
                            title: "Target Time",
                            value: formatTime(targetTime),
                            icon: "stopwatch"
                        )
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // Training Phases
                VStack(alignment: .leading, spacing: 16) {
                    Text("Training Phases")
                        .font(.headline)
                    
                    ForEach(trainingPhases, id: \.phase) { phase in
                        PhaseSummaryRow(
                            phase: phase.phase,
                            duration: phase.duration,
                            focus: phase.focus
                        )
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                Button(action: createPlan) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Create Training Plan")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [CustomColors.Brand.primary, CustomColors.Brand.secondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .padding(.top)
                .disabled(isLoading)
            }
            .padding()
        }
        .navigationTitle("Plan Summary")
        .background(Color(.systemGroupedBackground))
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showAuth) {
            AuthenticationView()
        }
    }
    
    private var goalTitle: String {
        switch goal {
        case .beginnerFitness: return "Get Fit"
        case .couchTo5K: return "Couch to 5K"
        case .raceTraining: return "Race Training"
        case .improvePace: return "Improve Pace"
        }
    }
    
    private var goalIcon: String {
        switch goal {
        case .beginnerFitness: return "figure.run"
        case .couchTo5K: return "figure.run.circle"
        case .raceTraining: return "flag.checkered"
        case .improvePace: return "speedometer"
        }
    }
    
    private var goalDescription: String {
        switch goal {
        case .beginnerFitness:
            return "A balanced plan to build your fitness through running"
        case .couchTo5K:
            return "Progressive training to reach your first 5K"
        case .raceTraining:
            return "Structured training for your \(formatDistance(raceDistance)) race"
        case .improvePace:
            return "Speed work and endurance training to increase your pace"
        }
    }
    
    private var recommendedRunsPerWeek: String {
        switch fitnessLevel {
        case .beginner: return "3-4 runs"
        case .intermediate: return "4-5 runs"
        case .advanced: return "5-6 runs"
        }
    }
    
    private var trainingPhases: [(phase: String, duration: String, focus: String)] {
        let basePhases = [
            ("Foundation", "\(max(1, weeks / 4)) weeks", "Build endurance and consistency"),
            ("Development", "\(max(1, weeks / 2)) weeks", "Increase distance and intensity"),
            ("Peak", "\(max(1, weeks / 4)) weeks", "Fine-tune and prepare for goal")
        ]
        return basePhases
    }
}

struct SummaryCard<Content: View>: View {
    let content: () -> Content
    
    var body: some View {
        content()
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [CustomColors.Brand.primary, CustomColors.Brand.secondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(radius: 5)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(CustomColors.Brand.primary)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .bold()
        }
    }
}

struct PhaseSummaryRow: View {
    let phase: String
    let duration: String
    let focus: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(phase)
                    .font(.headline)
                Spacer()
                Text(duration)
                    .foregroundColor(.secondary)
            }
            
            Text(focus)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// Helper functions
private func formatDistance(_ distance: Double) -> String {
    if distance == 21.1 {
        return "Half Marathon"
    } else if distance == 42.2 {
        return "Marathon"
    } else {
        return "\(Int(distance))K"
    }
}

// Add this extension to help with goal type checking
extension Models.RunningGoal {
    var isRaceTraining: Bool {
        switch self {
        case .raceTraining: return true
        default: return false
        }
    }
}

