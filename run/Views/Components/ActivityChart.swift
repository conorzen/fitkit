 import SwiftUI
 import HealthKit

 struct WeeklyActivityChart: View {
    @StateObject private var healthKit = HealthKitManager.shared
    @State private var selectedDay: Int? = nil
    @State private var weeklyActivities: [DayActivity] = []
    
    // Data structure for runs
    struct DayActivity: Identifiable {
        let id = UUID()
        let day: String
        let shortDay: String
        let distance: Double
        let duration: String
        let date: Date
        let calories: Double
        let averagePace: Double
    }
    
    // Fetch weekly data
    private func fetchWeeklyData() {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: today))!
        
        healthKit.fetchWeeklyRuns(from: startOfWeek) { runs in
            // Create a dictionary to store runs by day
            var runsByDay: [Date: DayActivity] = [:]
            
            // Create date formatter for day names
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            let shortFormatter = DateFormatter()
            shortFormatter.dateFormat = "EE"
            
            // Initialize all days of the week with zero values
            for dayOffset in 0...6 {
                let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
                let day = formatter.string(from: date)
                let shortDay = shortFormatter.string(from: date)
                
                runsByDay[date] = DayActivity(
                    day: day,
                    shortDay: shortDay,
                    distance: 0,
                    duration: "0 min",
                    date: date,
                    calories: 0,
                    averagePace: 0
                )
            }
            
            // Fill in actual run data
            for run in runs {
                let runDate = calendar.startOfDay(for: run.date)
                if let existingActivity = runsByDay[runDate] {
                    runsByDay[runDate] = DayActivity(
                        day: existingActivity.day,
                        shortDay: existingActivity.shortDay,
                        distance: run.distance / 1000, // Convert to km
                        duration: run.duration,
                        date: run.date,
                        calories: run.calories,
                        averagePace: run.averagePace
                    )
                }
            }
            
            // Sort activities by date
            self.weeklyActivities = runsByDay.values.sorted { $0.date < $1.date }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Weekly Activity")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text("This Week")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Chart
            VStack(spacing: 20) {
                // Bars
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(weeklyActivities.enumerated()), id: \.element.id) { index, activity in
                        VStack(spacing: 8) {
                            // Distance label
                            Text(String(format: "%.1f", activity.distance))
                                .font(.caption)
                                .foregroundColor(.gray)
                                .opacity(selectedDay == index ? 1 : 0)
                            
                            // Bar
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: selectedDay == index ?
                                            [CustomColors.Brand.primary, CustomColors.Brand.secondary] :
                                            [CustomColors.Brand.primary.opacity(0.3), CustomColors.Brand.secondary.opacity(0.3)],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(height: max(activity.distance * 10, 20))
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        selectedDay = selectedDay == index ? nil : index
                                    }
                                }
                            
                            // Day label
                            Text(activity.shortDay)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 180)
                
                // Selected day details
                if let selectedDay = selectedDay {
                    let activity = weeklyActivities[selectedDay]
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(activity.day)
                                .font(.headline)
                            Text(formatDate(activity.date))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            if activity.distance > 0 {
                                Text("\(String(format: "%.1f", activity.distance))km")
                                    .font(.headline)
                                Text(activity.duration)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            } else {
                                Text("No run")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8)
        }
        .onAppear {
            fetchWeeklyData()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}
 
 #Preview {

   WeeklyActivityChart()
 }
