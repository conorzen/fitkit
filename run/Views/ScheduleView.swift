import SwiftUI

struct ScheduleView: View {
    @Binding var availableDays: Set<Models.Weekday>
    @Binding var preferredTimeOfDay: Models.TimeOfDay
    
    var body: some View {
        Form {
            Section("Weekly Availability") {
                WeekdaySelector(selectedDays: $availableDays)
                
                Picker("Preferred Time", selection: $preferredTimeOfDay) {
                    ForEach(Models.TimeOfDay.allCases, id: \.self) { time in
                        Text(time.rawValue).tag(time)
                    }
                }
            }
        }
    }
} 