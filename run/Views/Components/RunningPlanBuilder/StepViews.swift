import SwiftUI

struct RunningPlanSteps {
    @Binding var selectedGoal: Models.RunningGoal
    @Binding var fitnessLevel: Models.FitnessLevel
    @Binding var raceDistance: Double
    @Binding var targetTime: TimeInterval
    @Binding var availableDays: Set<Models.Weekday>
    @Binding var preferredTimeOfDay: Models.TimeOfDay
    @Binding var current5KTime: TimeInterval
    @Binding var targetDate: Date
    
    var firstStep: some View {
        GoalSelectionView(selectedGoal: $selectedGoal)
            .tag(0)
    }
    
    var secondStep: some View {
        FitnessDetailsView(
            fitnessLevel: $fitnessLevel,
            selectedGoal: selectedGoal,
            raceDistance: $raceDistance,
            targetTime: $targetTime,
            availableDays: $availableDays,
            preferredTimeOfDay: $preferredTimeOfDay,
            current5KTime: $current5KTime,
            targetDate: $targetDate
        )
        .tag(1)
    }
    
    var thirdStep: some View {
        ScheduleView(
            availableDays: $availableDays,
            preferredTimeOfDay: $preferredTimeOfDay,
            targetDate: $targetDate,
            selectedGoal: selectedGoal
        )
        .tag(2)
    }
} 