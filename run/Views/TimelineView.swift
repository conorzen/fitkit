import SwiftUI

struct TimelineView: View {
    @Binding var targetDate: Date
    let selectedGoal: Models.RunningGoal
    
    private var minimumWeeks: Int {
        switch selectedGoal {
        case .beginnerFitness: return 4
        case .couchTo5K: return 8
        case .raceTraining: return 12
        case .improvePace: return 6
        }
    }
    
    private var recommendedWeeks: Int {
        switch selectedGoal {
        case .beginnerFitness: return 8
        case .couchTo5K: return 12
        case .raceTraining: return 16
        case .improvePace: return 8
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("When is your target date?")
                .font(.title2)
                .padding()
            
            DatePicker(
                "Target Date",
                selection: $targetDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
            
            Text("Training Duration: \(weeksBetween(start: Date(), end: targetDate)) weeks")
                .foregroundColor(.secondary)
        }
    }
    
    private func weeksBetween(start: Date, end: Date) -> Int {
        Calendar.current.dateComponents([.weekOfYear], from: start, to: end).weekOfYear ?? 0
    }
}

struct TimelineWarning: View {
    let message: String
    let icon: String
    var color: Color = .orange
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct TrainingTimelineCard: View {
    let weeks: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Training Journey")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 12) {
                TimelinePhase(
                    phase: "Foundation",
                    duration: "\(max(1, weeks / 4)) weeks",
                    description: "Build your base and establish routine"
                )
                
                TimelinePhase(
                    phase: "Development",
                    duration: "\(max(1, weeks / 2)) weeks",
                    description: "Increase distance and improve form"
                )
                
                TimelinePhase(
                    phase: "Peak",
                    duration: "\(max(1, weeks / 4)) weeks",
                    description: "Fine-tune and reach your goal"
                )
            }
        }
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

struct TimelinePhase: View {
    let phase: String
    let duration: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 8, height: 8)
                .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(phase)
                        .font(.headline)
                    Text("·")
                    Text(duration)
                        .font(.subheadline)
                }
                .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
} 

//#Preview{
//    TimelineView()
//}
