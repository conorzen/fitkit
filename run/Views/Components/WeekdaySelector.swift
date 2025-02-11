import SwiftUI

struct WeekdaySelector: View {
    @Binding var selectedDays: Set<Models.Weekday>
    
    private let weekdays: [Models.Weekday] = [
        .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
    ]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(weekdays, id: \.self) { day in
                Button(action: {
                    toggleDay(day)
                }) {
                    Text(day.shortName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(width: 40, height: 40)
                        .background(selectedDays.contains(day) ? Color.white : Color.white.opacity(0.2))
                        .foregroundColor(selectedDays.contains(day) ? CustomColors.Brand.primary : .white)
                        .clipShape(Circle())
                }
            }
        }
    }
    
    private func toggleDay(_ day: Models.Weekday) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
}

extension Models.Weekday {
    var shortName: String {
        switch self {
        case .monday: return "M"
        case .tuesday: return "Tu"
        case .wednesday: return "W"
        case .thursday: return "Th"
        case .friday: return "F"
        case .saturday: return "Sa"
        case .sunday: return "Su"
        }
    }
}
