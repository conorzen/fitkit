import SwiftUI

struct ScheduleView: View {
    @Binding var availableDays: Set<Models.Weekday>
    @Binding var preferredTimeOfDay: Models.TimeOfDay
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
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Weekly Availability Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Weekly Availability")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    WeekdaySelector(selectedDays: $availableDays)
                        .padding(.vertical, 8)
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    HStack {
                        Text("Preferred Time")
                            .foregroundColor(.white)
                        Spacer()
                        Picker("", selection: $preferredTimeOfDay) {
                            ForEach(Models.TimeOfDay.allCases, id: \.self) { time in
                                Text(time.rawValue).tag(time)
                            }
                        }
                        .tint(.white)
                    }
                }
                .padding(20)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            CustomColors.Brand.primary,
                            CustomColors.Brand.secondary
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .shadow(radius: 5)
                
                // Plan Duration Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Plan Duration")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    DatePicker(
                        "Target Date",
                        selection: $targetDate,
                        in: Calendar.current.date(byAdding: .weekOfYear, value: minimumWeeks, to: Date())!...,
                        displayedComponents: .date
                    )
                    .tint(.white)
                    .foregroundColor(.white)
                    
                    let weeks = Calendar.current.dateComponents([.weekOfYear], from: Date(), to: targetDate).weekOfYear ?? 0
                    
                    if weeks < minimumWeeks {
                        TimelineWarning(
                            message: "We recommend at least \(minimumWeeks) weeks for this goal",
                            icon: "exclamationmark.triangle",
                            color: .orange
                        )
                    } else if weeks > recommendedWeeks + 4 {
                        TimelineWarning(
                            message: "Consider a shorter plan for better focus",
                            icon: "info.circle",
                            color: .blue
                        )
                    }
                    
                    Text("\(weeks) weeks of training")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(20)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            CustomColors.Brand.primary,
                            CustomColors.Brand.secondary
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .shadow(radius: 5)
                
                // Training Timeline Card
                if !availableDays.isEmpty {
                    let weeks = Calendar.current.dateComponents([.weekOfYear], from: Date(), to: targetDate).weekOfYear ?? 0
                    TrainingTimelineCard(weeks: weeks)
                }
            }
            .padding(.horizontal)
        }
        .padding(.top)
        .background(Color(.systemGroupedBackground))
    }
} 