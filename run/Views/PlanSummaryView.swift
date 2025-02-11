import SwiftUI

struct PlanSummaryView: View {
    let goal: RunningGoal
    let fitnessLevel: Models.FitnessLevel
    let targetDate: Date
    let raceDistance: Double
    let targetTime: TimeInterval
    let onConfirm: () -> Void
    
    private var weeks: Int {
        Calendar.current.dateComponents([.weekOfYear], from: Date(), to: targetDate).weekOfYear ?? 0
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
                    
                    if case .raceTraining(let distance, _) = goal {
                        DetailRow(
                            title: "Target Distance",
                            value: formatDistance(distance),
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
                
                Button(action: onConfirm) {
                    Text("Create Training Plan")
                        .font(.headline)
                        .foregroundColor(.white)
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
                }
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle("Plan Summary")
        .background(Color(.systemGroupedBackground))
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
        case .raceTraining(let distance, _):
            return "Structured training for your \(formatDistance(distance)) race"
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

//private func formatTime(_ timeInterval: TimeInterval) -> String {
//    let hours = Int(timeInterval) / 3600
//    let minutes = (Int(timeInterval) % 3600) / 60
//    return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
//} 
