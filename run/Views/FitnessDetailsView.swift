import SwiftUI

struct FitnessDetailsView: View {
    @Binding var fitnessLevel: Models.FitnessLevel
    let selectedGoal: Models.RunningGoal
    @Binding var raceDistance: Double
    @Binding var targetTime: TimeInterval
    @Binding var availableDays: Set<Models.Weekday>
    @Binding var preferredTimeOfDay: Models.TimeOfDay
    @Binding var current5KTime: TimeInterval
    @Binding var targetDate: Date
    @State private var showingLevelInfo = false
    
    let commonDistances = [5.0, 10.0, 21.1, 42.2]
    
    var body: some View {
        Form {
            makeExperienceSection()
            if case .raceTraining = selectedGoal {
                makeRaceDetailsSection()
            }
        }
        .navigationTitle("Your Profile")
        .sheet(isPresented: $showingLevelInfo) {
            FitnessLevelInfoView(fitnessLevel: $fitnessLevel)
        }
    }
    
    private func makeExperienceSection() -> some View {
        Section("Your Experience") {
            Picker("Current Level", selection: $fitnessLevel) {
                ForEach(Models.FitnessLevel.allCases, id: \.self) { level in
                    Text(level.rawValue)
                        .tag(level)
                }
            }
            
            Button(action: { showingLevelInfo = true }) {
                Text("What do these levels mean?")
                    .font(.subheadline)
                    .foregroundColor(CustomColors.Brand.primary)
            }
            
            if fitnessLevel != .beginner {
                TimePicker(
                    title: "Current 5K Time",
                    timeInterval: $current5KTime
                )
            }
        }
    }
    
    private func makeRaceDetailsSection() -> some View {
        Section("Race Details") {
            Picker("Race Distance", selection: $raceDistance) {
                ForEach(commonDistances, id: \.self) { distance in
                    Text(formatDistance(distance)).tag(distance)
                }
            }
            
            TimePicker(
                title: "Target Time",
                timeInterval: $targetTime
            )
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 10 {
            return String(format: "%.1f km", distance)
        } else {
            return String(format: "%.0f km", distance)
        }
    }
}

struct ExperienceLevelCard: View {
    let fitnessLevel: Models.FitnessLevel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(fitnessLevel.rawValue)
                .font(.headline)
            
            Text(fitnessLevel.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct TimePicker: View {
    let title: String
    @Binding var timeInterval: TimeInterval
    @State private var selectedHours: Int
    @State private var selectedMinutes: Int
    
    init(title: String, timeInterval: Binding<TimeInterval>) {
        self.title = title
        self._timeInterval = timeInterval
        let hours = Int(timeInterval.wrappedValue) / 3600
        let minutes = (Int(timeInterval.wrappedValue) % 3600) / 60
        self._selectedHours = State(initialValue: hours)
        self._selectedMinutes = State(initialValue: minutes)
    }
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            HStack(spacing: 4) {
                Picker("Hours", selection: $selectedHours) {
                    ForEach(0...6, id: \.self) { hour in
                        Text("\(hour)").tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 50)
                .clipped()
                .onChange(of: selectedHours) { newValue in
                    timeInterval = TimeInterval(newValue * 3600 + selectedMinutes * 60)
                }
                
                Text("h")
                
                Picker("Minutes", selection: $selectedMinutes) {
                    ForEach(0...59, id: \.self) { minute in
                        Text("\(minute)").tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 50)
                .clipped()
                .onChange(of: selectedMinutes) { newValue in
                    timeInterval = TimeInterval(selectedHours * 3600 + newValue * 60)
                }
                
                Text("m")
            }
        }
    }
}

enum Weekday: String, CaseIterable {
    case monday = "Mon"
    case tuesday = "Tue"
    case wednesday = "Wed"
    case thursday = "Thu"
    case friday = "Fri"
    case saturday = "Sat"
    case sunday = "Sun"
    
    var shortName: String {
        String(rawValue.prefix(2))
    }
}

//enum TimeOfDay: String, CaseIterable {
//    case morning = "Morning"
//    case afternoon = "Afternoon"
//    case evening = "Evening"
//}

struct DayToggle: View {
    let day: Models.Weekday
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(day.shortName)
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 40)
                .padding(.vertical, 8)
                .background(
                    isSelected ?
                    LinearGradient(
                        colors: [CustomColors.Brand.primary, CustomColors.Brand.secondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        colors: [Color(.systemGray5), Color(.systemGray5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct TrainingSummaryCard: View {
    let daysPerWeek: Int
    let timeOfDay: Models.TimeOfDay
    let current5KTime: TimeInterval?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(CustomColors.Brand.primary)
                VStack(alignment: .leading) {
                    Text("\(daysPerWeek) training days per week")
                        .font(.headline)
                    Text("Preferred time: \(timeOfDay.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if let time = current5KTime {
                HStack {
                    Image(systemName: "stopwatch")
                        .foregroundColor(CustomColors.Brand.primary)
                    VStack(alignment: .leading) {
                        Text("Current 5K Time")
                            .font(.headline)
                        Text(formatTime(time))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

//private func formatTime(_ timeInterval: TimeInterval) -> String {
//    let minutes = Int(timeInterval) / 60
//    let seconds = Int(timeInterval) % 60
//    return String(format: "%d:%02d", minutes, seconds)
//}

//enum FitnessLevel: String, CaseIterable {
//    case beginner = "New to Running"
//    case intermediate = "Run Occasionally"
//    case advanced = "Regular Runner"
    

    



struct RunnerLevelInfoView: View {
    let level: Models.FitnessLevel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: levelIcon)
                    .font(.title2)
                    .foregroundColor(CustomColors.Brand.primary)
                
                Text(level.rawValue)
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Typical Profile:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(level.description)
                    .font(.subheadline)
                
                Divider()
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Label("Weekly Runs", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(level.recommendedWeeklyRuns)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    VStack(alignment: .leading) {
                        Label("Typical Pace", systemImage: "speedometer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(level.typicalPace)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 5)
        )
    }
    
    private var levelIcon: String {
        switch level {
        case .beginner:
            return "figure.walk"
        case .intermediate:
            return "figure.run"
        case .advanced:
            return "figure.run.circle.fill"
        }
    }
}

struct FitnessLevelInfoView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var fitnessLevel: Models.FitnessLevel
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(Models.FitnessLevel.allCases, id: \.self) { level in
                        Button {
                            fitnessLevel = level
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(level.rawValue)
                                    .font(.headline)
                                Text(level.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Recommended weekly runs: \(level.recommendedWeeklyRuns)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("Fitness Levels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
