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
    @State private(set) var availableDays: Set<Models.Weekday> = []
    @State var preferredTimeOfDay: Models.TimeOfDay = .morning
    @State var current5KTime: TimeInterval = 30 * 60
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private var steps: RunningPlanSteps {
        RunningPlanSteps(
            selectedGoal: $selectedGoal,
            fitnessLevel: $fitnessLevel,
            raceDistance: $raceDistance,
            targetTime: $targetTime,
            availableDays: $availableDays,
            preferredTimeOfDay: $preferredTimeOfDay,
            current5KTime: $current5KTime
        )
    }
    
    private var toolbar: RunningPlanToolbar {
        RunningPlanToolbar(
            currentStep: currentStep,
            canProceedToNextStep: canProceedToNextStep,
            canCreatePlan: canCreatePlan,
            onBack: { currentStep -= 1 },
            onNext: { currentStep += 1 },
            onCreatePlan: createPlan
        )
    }
    
    var body: some View {
        NavigationView {
            TabView(selection: $currentStep) {
                steps.firstStep
                steps.secondStep
                steps.thirdStep
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbar.makeToolbarContent()
            }
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
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
                return !availableDays.isEmpty && raceDistance > 0 && targetTime > 0
            }
            return !availableDays.isEmpty
        default:
            return true
        }
    }
    
    private var canCreatePlan: Bool {
        !availableDays.isEmpty
    }
    
    private func createPlan() {
        generatePlan()
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

