//
//  CalendarView.swift
//  run
//
//  Created by Conor Reid Admin on 10/02/2025.
//

import SwiftUI

struct WorkoutCalendarView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedDate: Date = Date()
    @State private var showingWorkoutScheduler = false
    @State private var showingPlanBuilder = false
    @State private var plannedWorkouts: [Date: [WorkoutItem]] = [:]
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"  // Day abbreviation
        return formatter
    }()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"  // Day number
        return formatter
    }()
    
    private var calendarDays: [DayItem] {
        let calendar = Calendar.current
        let weekDates = (-3...3).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: Date())
        }
        
        return weekDates.map { date in
            DayItem(
                day: dayFormatter.string(from: date),
                date: dateFormatter.string(from: date),
                fullDate: date,
                isActive: calendar.isDate(date, inSameDayAs: selectedDate),
                hasWorkout: hasWorkoutOn(date)
            )
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.customColors.background.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 24) {
                        calendarStrip
                        focusCard
                        workoutsList
                        
                        HStack(spacing: 12) {
                            quickRunButton
                            createPlanButton
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 80)
                    }
                    .padding()
                }
            }
            .navigationBarItems(trailing: navigationButtons)
            .sheet(isPresented: $showingWorkoutScheduler) {
                WorkoutSchedulerView()
            }
            .sheet(isPresented: $showingPlanBuilder) {
                RunningPlanBuilderView()
            }
            .onAppear {
                setupNotificationObservers()
            }
        }
    }
    
    private var calendarStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(calendarDays, id: \.fullDate) { day in
                    DayView(day: day)
                        .onTapGesture {
                            withAnimation {
                                selectedDate = day.fullDate
                            }
                        }
                }
            }
            .padding(.horizontal)
        }
    }
    
    var focusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock")
                Text("At the moment:")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Text("HEY CONOR - KEEP GOING, YOU GOT THIS!")
                .font(.title3)
                .fontWeight(.bold)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [CustomColors.Brand.primary, CustomColors.Brand.secondary]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 10)
    }
    var workoutsList: some View {
        VStack(spacing: 16) {
            if let dayWorkouts = plannedWorkouts[selectedDate] {
                ForEach(dayWorkouts) { workout in
                    WorkoutCardView(workout: workout, colorScheme: colorScheme)
                }
            } else {
                Text("No workouts scheduled for this day")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
    
    var quickRunButton: some View {
        Button(action: {
            showingWorkoutScheduler = true
        }) {
            HStack {
                Image(systemName: "calendar")
                    .padding(8)
                    .background(Color.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Text("Quick Run")
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.customColors.emerald, .customColors.teal]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.1), radius: 10)
        }
    }
    
    var createPlanButton: some View {
        Button(action: {
            showingPlanBuilder = true
        }) {
            HStack {
                Image(systemName: "figure.run.circle")
                    .padding(8)
                    .background(Color.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Text("Training Plan")
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [CustomColors.Brand.primary, CustomColors.Brand.secondary]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.1), radius: 10)
        }
    }
   
    
    
    
    var navigationButtons: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }
    
    // Function to update planned workouts
    private func addPlannedWorkouts(_ newWorkouts: [Date: [WorkoutItem]]) {
        plannedWorkouts.merge(newWorkouts) { current, new in
            current + new
        }
    }
    
    private func hasWorkoutOn(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return plannedWorkouts.keys.contains { workoutDate in
            calendar.isDate(workoutDate, inSameDayAs: date)
        }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .planCreated,
            object: nil,
            queue: .main
        ) { notification in
            if let plan = notification.object as? TrainingPlan {
                let workoutsByDate = Dictionary(
                    grouping: plan.workouts,
                    by: { $0.date }
                ).mapValues { workouts in
                    workouts.map { $0.asWorkoutItem }
                }
                addPlannedWorkouts(workoutsByDate)
            }
        }
    }
}

struct DayItem: Identifiable {
    let id = UUID()
    let day: String
    let date: String
    let fullDate: Date
    let isActive: Bool
    let hasWorkout: Bool
}

struct WorkoutItem: Identifiable {
    let id = UUID()
    let title: String
    let details: String
    let iconName: String
    let gradient: [Color]
}

struct DayView: View {
    let day: DayItem
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Text(day.day)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(day.date)
                .font(.title3)
                .fontWeight(.bold)
            
            // Workout indicator
            if day.hasWorkout {
                Circle()
                    .fill(CustomColors.Brand.primary)
                    .frame(width: 6, height: 6)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            day.isActive ?
            LinearGradient(
                colors: [CustomColors.Brand.primary, CustomColors.Brand.secondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ) :
            LinearGradient(
                colors: [colorScheme == .dark ? Color.customColors.secondaryBackground : .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .foregroundColor(day.isActive ? .white : (colorScheme == .dark ? .white : .primary))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct WorkoutCardView: View {
    let workout: WorkoutItem
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: workout.iconName)
                    .font(.title2)
                    .foregroundColor(workout.gradient[0])
                    .padding(12)
                    .background(workout.gradient[0].opacity(colorScheme == .dark ? 0.2 : 0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading) {
                    Text(workout.title)
                        .font(.headline)
                    Text(workout.details)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Text("Start")
                        .fontWeight(.medium)
                        .foregroundColor(workout.gradient[0])
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(workout.gradient[0].opacity(colorScheme == .dark ? 0.2 : 0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            Rectangle()
                .fill(LinearGradient(gradient: Gradient(colors: workout.gradient),
                                   startPoint: .leading,
                                   endPoint: .trailing))
                .frame(height: 4)
                .opacity(colorScheme == .dark ? 0.3 : 0.2)
                .clipShape(RoundedRectangle(cornerRadius: 2))
        }
        .padding()
        .background(colorScheme == .dark ? Color.customColors.secondaryBackground : .white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 10)
    }
}


// Preview
struct WorkoutCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutCalendarView()
    }
}

// Color Extension for custom colors
extension Color {
    static let background = Color("Background")
    static let gray100 = Color("Gray100")
}

#Preview{
    WorkoutCalendarView()
}

extension String {
    func toDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"  // matches the format we used to create the string
        return dateFormatter.date(from: self)
    }
}

// Add a method to RunningPlanBuilderView to generate and pass workouts
extension RunningPlanBuilderView {
    func generatePlan() {
        var workouts: [Date: [WorkoutItem]] = [:]
        
        // Generate workouts based on selected days and preferences
        for day in self.availableDays {
            let workoutDate = nextOccurrence(of: day)
            let workout = WorkoutItem(
                title: "Training Run",
                details: "45 min • Easy Pace",
                iconName: "figure.run",
                gradient: [CustomColors.Brand.primary, CustomColors.Brand.secondary]
            )
            workouts[workoutDate] = [workout]
        }
        
        // Post notification with workouts
        NotificationCenter.default.post(
            name: .planCreated,
            object: workouts
        )
        dismiss()
    }
    
    private func nextOccurrence(of weekday: Models.Weekday) -> Date {
        let calendar = Calendar.current
        let today = Date()
        let weekdayIndex = weekday.dayValue
        let currentWeekday = calendar.component(.weekday, from: today)
        let daysToAdd = (weekdayIndex - currentWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: daysToAdd, to: today) ?? today
    }
}

extension Weekday {
    var index: Int {
        switch self {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        }
    }
}
