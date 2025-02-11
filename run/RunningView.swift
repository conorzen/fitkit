//
//  RunningView.swift
//  run
//
//  Created by Conor Reid Admin on 09/02/2025.

import SwiftUI
import HealthKit
import WorkoutKit

// Add the model structures
struct StatItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let unit: String
    let trend: String
}

struct RunItem: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let distance: String
    let duration: String
    let gradient: [Color]
}

struct MetricsCarouselView: View {
    @State private var currentPage = 0
    private let metrics: [MetricComparison] = [
        MetricComparison(
            title: "Weekly Distance",
            currentValue: "32.5",
            previousValue: "28.2",
            unit: "km",
            trend: "+15%",
            icon: "figure.run",
            gradient: [.customColors.emerald, .customColors.teal]
        ),
        MetricComparison(
            title: "Average Pace",
            currentValue: "5:32",
            previousValue: "5:45",
            unit: "/km",
            trend: "-2%",
            icon: "speedometer",
            gradient: [.customColors.blue, .customColors.indigo]
        ),
        MetricComparison(
            title: "Total Time",
            currentValue: "3:45",
            previousValue: "3:15",
            unit: "hours",
            trend: "+15%",
            icon: "clock.fill",
            gradient: [.customColors.purple, .customColors.indigo]
        ),
        MetricComparison(
            title: "Calories",
            currentValue: "2,450",
            previousValue: "2,100",
            unit: "kcal",
            trend: "+16%",
            icon: "flame.fill",
            gradient: [.customColors.orange, .customColors.red]
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Progress")
                .font(.title3)
                .fontWeight(.bold)
            
            TabView(selection: $currentPage) {
                ForEach(metrics.indices, id: \.self) { index in
                    MetricComparisonCard(metric: metrics[index])
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .frame(height: 200)
        }
    }
}

struct MetricComparison: Identifiable {
    let id = UUID()
    let title: String
    let currentValue: String
    let previousValue: String
    let unit: String
    let trend: String
    let icon: String
    let gradient: [Color]
}

struct MetricComparisonCard: View {
    let metric: MetricComparison
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with icon
            HStack {
                Image(systemName: metric.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                Text(metric.title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            // Current value
            HStack(alignment: .lastTextBaseline) {
                Text(metric.currentValue)
                    .font(.system(size: 36, weight: .bold))
                Text(metric.unit)
                    .font(.body)
            }
            .foregroundColor(.white)
            
            // Comparison section
            HStack {
                VStack(alignment: .leading) {
                    Text("Last Week")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Text(metric.previousValue)
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Trend indicator
                HStack {
                    Image(systemName: metric.trend.hasPrefix("+") ? "arrow.up.right" : "arrow.down.right")
                    Text(metric.trend)
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: metric.gradient),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: metric.gradient[0].opacity(0.3), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
    }
}

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

struct RunningView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var healthKit = HealthKitManager.shared
    @State private var selectedTab = 0
    @State private var isRunning = false
    @State private var yearlyStats: RunningStatistics = .empty
    @State private var recentRuns: [RecentRun] = []
    @State private var showingNewRunSheet = false
    
    // Computed property for stats
    private var stats: [StatItem] {
        [
            StatItem(title: "This Week", value: "\(String(format: "%.1f", yearlyStats.totalDistance/1000))", unit: "km", trend: "+2.3"),
            StatItem(title: "Avg. Pace", value: formatPace(yearlyStats.averagePace), unit: "/km", trend: "-0:15"),
            StatItem(title: "Activities", value: "\(yearlyStats.totalRuns)", unit: "runs", trend: "+3")
        ]
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        // Profile Image - moved to the start
                        Circle()
                            .fill(LinearGradient(
                                colors: [CustomColors.Brand.primary, CustomColors.Brand.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                            )
                            .padding(.trailing, 12)
                        
                        // Welcome text
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hello!")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text(formattedDate())
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    
                    // Add the metrics carousel after the header
                    MetricsCarouselView()
                    
                    // Featured Workout Card
                    FeaturedWorkoutCard()
                    
                    // Quick Actions Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        QuickActionTile(
                            title: "Workout",
                            value: "2 hours",
                            icon: "figure.run",
                            gradient: [CustomColors.Brand.primary, CustomColors.Brand.secondary]
                        )
                        QuickActionTile(
                            title: "Running",
                            value: "12 km",
                            icon: "stopwatch",
                            gradient: [.customColors.rose, .customColors.pink]
                        )
                        QuickActionTile(
                            title: "Food",
                            value: "1832 kcal",
                            icon: "fork.knife",
                            gradient: [.customColors.emerald, .customColors.teal]
                        )
                    }
                    
                    // Activities Chart
                    WeeklyActivityChart()
                }
                .padding()
            }
            .scrollIndicators(.hidden)
            .background(Color.customColors.background)
        }
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, dd MMMM"
        return formatter.string(from: Date())
    }
    
    var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome back!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Ready for today's run?")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var quickActions: some View {
        HStack(spacing: 16) {
            QuickActionButton(
                title: healthKit.isWorkoutActive ? "Stop Run" : "Start Run",
                icon: healthKit.isWorkoutActive ? "stop.fill" : "play.fill",
                gradient: healthKit.isWorkoutActive ? 
                    [.customColors.rose, .customColors.red] :
                    [.customColors.emerald, .customColors.teal]
            ) {
                if healthKit.isWorkoutActive {
                    healthKit.stopWorkoutSession()
                } else {
                    healthKit.startWorkoutSession()
                }
            }
            
            QuickActionButton(
                title: "Schedule",
                icon: "calendar",
                gradient: [.customColors.purple, .customColors.indigo]
            ) {
                showingNewRunSheet = true
            }
        }
    }
    
    var activeWorkoutCard: some View {
        VStack(spacing: 16) {
            Text("Current Activity")
                .font(.title3)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Heart Rate Card
                MetricCard(
                    title: "Heart Rate",
                    value: "\(Int(healthKit.currentHeartRate))",
                    unit: "BPM",
                    icon: "heart.fill",
                    gradient: [.customColors.rose, .customColors.pink]
                )
                
                // Distance Card
                MetricCard(
                    title: "Distance",
                    value: String(format: "%.2f", healthKit.currentDistance/1000),
                    unit: "KM",
                    icon: "figure.run",
                    gradient: [.customColors.blue, .customColors.indigo]
                )
                
                // Calories Card
                MetricCard(
                    title: "Calories",
                    value: "\(Int(healthKit.currentCalories))",
                    unit: "CAL",
                    icon: "flame.fill",
                    gradient: [.customColors.orange, .customColors.red]
                )
                
                // Pace Card
                MetricCard(
                    title: "Current Pace",
                    value: formatPace(healthKit.currentPace),
                    unit: "/KM",
                    icon: "speedometer",
                    gradient: [.customColors.emerald, .customColors.teal]
                )
            }
        }
        .padding()
    }
    
    
    var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Progress")
                .font(.title3)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(stats) { stat in
                    StatCard(stat: stat)
                }
            }
        }
    }
    
    var recentRunsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Runs")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {}) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.customColors.blue)
                }
            }
            
            VStack(spacing: 12) {
                ForEach(recentRuns) { run in
                    RunCard(run: RunItem(
                        title: "Run",
                        date: formatDate(run.date),
                        distance: String(format: "%.1f km", run.distance/1000),
                        duration: run.duration,
                        gradient: [.customColors.purple, .customColors.blue]
                    ))
                }
            }
        }
    }
    
    private func formatPace(_ pace: Double) -> String {
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct FeaturedWorkoutCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("FITNESS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(CustomColors.Brand.primary)
                Spacer()
                Image(systemName: "info.circle")
                    .foregroundColor(.gray)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Training Run")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Starting 5km Run")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                Image("running_illustration") // You'll need to add this asset
                    .resizable()
                    .frame(width: 80, height: 80)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8)
    }
}

struct QuickActionTile: View {
    let title: String
    let value: String
    let icon: String
    let gradient: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .padding(8)
                .background(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.headline)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8)
    }
}

struct ActivityChart: View {
    var body: some View {
        // Placeholder for chart
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(0..<7) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(
                        colors: [CustomColors.Brand.primary, CustomColors.Brand.secondary],
                        startPoint: .bottom,
                        endPoint: .top
                    ))
                    .frame(width: 30, height: CGFloat.random(in: 50...150))
            }
        }
        .frame(height: 150)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let gradient: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.callout)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                LinearGradient(gradient: Gradient(colors: gradient),
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct StatCard: View {
    let stat: StatItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(stat.title)
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(stat.value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(stat.unit)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 2) {
                Image(systemName: stat.trend.hasPrefix("+") ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption)
                Text(stat.trend)
                    .font(.caption)
            }
            .foregroundColor(stat.trend.hasPrefix("+") ? .customColors.emerald : .customColors.rose)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8)
    }
}

struct RunCard: View {
    let run: RunItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(run.title)
                    .font(.headline)
                Text(run.date)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(run.distance)
                    .font(.headline)
                Text(run.duration)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8)
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: run.gradient),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 4)
                .clipped(),
            alignment: .leading
        )
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let gradient: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
            
            Spacer()
            
            // Value and Unit
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                Text(unit)
                    .font(.system(size: 14))
            }
            .foregroundColor(.white)
            
            // Title
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .frame(height: 160)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: gradient),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: gradient[0].opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct CreateRunView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var healthKit = HealthKitManager.shared
    @State private var runName: String = ""
    @State private var workoutType: WorkoutType = .simple
    @State private var targetDistance: Double = 5.0
    @State private var targetPace: Double = 6.0
    @State private var showPreview: Bool = false
    
    // Interval workout specific states
    @State private var intervalDistance: Double = 0.4 // 400m
    @State private var intervalPace: Double = 4.5
    @State private var recoveryPace: Double = 6.0
    @State private var numberOfIntervals: Int = 8
    
    // Progressive workout specific states
    @State private var progressiveBaseDistance: Double = 1.0
    @State private var progressiveBasePace: Double = 5.5
    @State private var numberOfProgressions: Int = 5
    @State private var paceIncrease: Double = 0.5
    
    enum WorkoutType: String, CaseIterable {
        case simple = "Simple Run"
        case interval = "Interval Training"
        case progressive = "Progressive Run"
    }
    
    private var runningWorkoutPlan: WorkoutPlan {
        let customWorkout: CustomWorkout
        
        switch workoutType {
        case .simple:
            customWorkout = WorkoutStore.createSimpleRunWorkout(
                name: runName,
                distance: targetDistance,
                targetPace: targetPace
            )
            
        case .interval:
            let workInterval = WorkoutInterval(
                type: .work,
                distance: intervalDistance,
                targetPaceRange: (intervalPace - 0.25)...(intervalPace + 0.25),
                iterations: numberOfIntervals
            )
            
            let recoveryInterval = WorkoutInterval(
                type: .recovery,
                distance: intervalDistance,
                targetPaceRange: (recoveryPace - 0.25)...(recoveryPace + 0.25),
                iterations: numberOfIntervals
            )
            
            customWorkout = WorkoutStore.createIntervalWorkout(
                name: runName,
                workInterval: workInterval,
                recoveryInterval: recoveryInterval
            )
            
        case .progressive:
            customWorkout = WorkoutStore.createProgressiveWorkout(
                name: runName,
                baseDistance: progressiveBaseDistance,
                basePace: progressiveBasePace,
                numberOfProgressions: numberOfProgressions,
                paceIncrease: paceIncrease
            )
        }
        
        return WorkoutPlan(.custom(customWorkout))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Run Details")) {
                    TextField("Run Name", text: $runName)
                    
                    Picker("Workout Type", selection: $workoutType) {
                        ForEach(WorkoutType.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                }
                
                switch workoutType {
                case .simple:
                    simpleRunSection
                case .interval:
                    intervalRunSection
                case .progressive:
                    progressiveRunSection
                }
                
                Section {
                    Button(action: {
                        showPreview.toggle()
                    }) {
                        HStack {
                            Spacer()
                            Text("Preview & Schedule")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Create Run")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
            .workoutPreview(runningWorkoutPlan, isPresented: $showPreview)
        }
    }
    
    private var simpleRunSection: some View {
        Section(header: Text("Simple Run Details")) {
            HStack {
                Text("Target Distance")
                Spacer()
                TextField("5.0", value: $targetDistance, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text("km")
            }
            
            HStack {
                Text("Target Pace")
                Spacer()
                TextField("6:00", value: $targetPace, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text("min/km")
            }
        }
    }
    
    private var intervalRunSection: some View {
        Section(header: Text("Interval Details")) {
            HStack {
                Text("Interval Distance")
                Spacer()
                TextField("0.4", value: $intervalDistance, format: .number.precision(.fractionLength(2)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text("km")
            }
            
            HStack {
                Text("Work Pace")
                Spacer()
                TextField("4:30", value: $intervalPace, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text("min/km")
            }
            
            HStack {
                Text("Recovery Pace")
                Spacer()
                TextField("6:00", value: $recoveryPace, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text("min/km")
            }
            
            Stepper("Number of Intervals: \(numberOfIntervals)", value: $numberOfIntervals, in: 1...20)
        }
    }
    
    private var progressiveRunSection: some View {
        Section(header: Text("Progressive Run Details")) {
            HStack {
                Text("Base Distance")
                Spacer()
                TextField("1.0", value: $progressiveBaseDistance, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text("km")
            }
            
            HStack {
                Text("Starting Pace")
                Spacer()
                TextField("5:30", value: $progressiveBasePace, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text("min/km")
            }
            
            HStack {
                Text("Pace Increase")
                Spacer()
                TextField("0.5", value: $paceIncrease, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text("min/km")
            }
            
            Stepper("Number of Segments: \(numberOfProgressions)", value: $numberOfProgressions, in: 2...10)
        }
    }
}

#Preview {
    RunningView()
}
