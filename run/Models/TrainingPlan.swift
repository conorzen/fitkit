import Foundation
import SwiftUI

// Move FitnessLevel here since it's used across multiple files
enum FitnessLevel: String, Codable, CaseIterable {
    case beginner = "New to Running"
    case intermediate = "Run Occasionally"
    case advanced = "Regular Runner"
}

enum TimeOfDay: String, Codable, CaseIterable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
}

struct TrainingPlan: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let name: String
    let goal: Models.RunningGoal
    let startDate: Date
    let endDate: Date
    let fitnessLevel: Models.FitnessLevel
    let workoutDays: [Models.Weekday]
    let preferredTime: Models.TimeOfDay
    let workouts: [PlannedWorkout]
    let current5KTime: TimeInterval?
    let targetRaceDistance: Double?
    let targetRaceTime: TimeInterval?
    let createdAt: Date?
    let updatedAt: Date?
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        name: String,
        goal: Models.RunningGoal,
        startDate: Date,
        endDate: Date,
        fitnessLevel: Models.FitnessLevel,
        workoutDays: [Models.Weekday],
        preferredTime: Models.TimeOfDay,
        workouts: [PlannedWorkout],
        current5KTime: TimeInterval?,
        targetRaceDistance: Double?,
        targetRaceTime: TimeInterval?,
        createdAt: Date?,
        updatedAt: Date?
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.goal = goal
        self.startDate = startDate
        self.endDate = endDate
        self.fitnessLevel = fitnessLevel
        self.workoutDays = workoutDays
        self.preferredTime = preferredTime
        self.workouts = workouts
        self.current5KTime = current5KTime
        self.targetRaceDistance = targetRaceDistance
        self.targetRaceTime = targetRaceTime
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case goal
        case startDate = "start_date"
        case endDate = "end_date"
        case fitnessLevel = "fitness_level"
        case workoutDays = "workout_days"
        case preferredTime = "preferred_time"
        case workouts
        case current5KTime = "current_5k_time"
        case targetRaceDistance = "target_race_distance"
        case targetRaceTime = "target_race_time"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(name, forKey: .name)
        try container.encode(goal, forKey: .goal)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(fitnessLevel, forKey: .fitnessLevel)
        try container.encode(workoutDays, forKey: .workoutDays)
        try container.encode(preferredTime, forKey: .preferredTime)
        try container.encode(workouts, forKey: .workouts)
        try container.encodeIfPresent(current5KTime, forKey: .current5KTime)
        try container.encodeIfPresent(targetRaceDistance, forKey: .targetRaceDistance)
        try container.encodeIfPresent(targetRaceTime, forKey: .targetRaceTime)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
    
    var durationInWeeks: Int {
        Calendar.current.dateComponents([.weekOfYear], from: startDate, to: endDate).weekOfYear ?? 0
    }
    
    static func create(
        userId: UUID,
        name: String,
        goal: Models.RunningGoal,
        startDate: Date,
        endDate: Date,
        fitnessLevel: Models.FitnessLevel,
        workoutDays: [Models.Weekday],
        preferredTime: Models.TimeOfDay,
        current5KTime: TimeInterval?,
        targetRaceDistance: Double?,
        targetRaceTime: TimeInterval?
    ) -> TrainingPlan {
        let workouts = generateWorkouts(
            goal: goal,
            fitnessLevel: fitnessLevel,
            startDate: startDate,
            endDate: endDate,
            workoutDays: workoutDays
        )
        
        return TrainingPlan(
            id: UUID(),
            userId: userId,
            name: name,
            goal: goal,
            startDate: startDate,
            endDate: endDate,
            fitnessLevel: fitnessLevel,
            workoutDays: workoutDays,
            preferredTime: preferredTime,
            workouts: workouts,
            current5KTime: current5KTime,
            targetRaceDistance: targetRaceDistance,
            targetRaceTime: targetRaceTime,
            createdAt: nil,
            updatedAt: nil
        )
    }
    
    private static func generateWorkouts(
        goal: Models.RunningGoal,
        fitnessLevel: Models.FitnessLevel,
        startDate: Date,
        endDate: Date,
        workoutDays: [Models.Weekday]
    ) -> [PlannedWorkout] {
        var workouts: [PlannedWorkout] = []
        let calendar = Calendar.current
        let totalWeeks = calendar.dateComponents([.weekOfYear], from: startDate, to: endDate).weekOfYear ?? 8
        
        for weekOffset in 0..<totalWeeks {
            let phase = determinePhase(week: weekOffset, totalWeeks: totalWeeks)
            
            for day in workoutDays {
                guard let date = calendar.date(byAdding: .day, value: weekOffset * 7 + day.dayValue, to: startDate) else { continue }
                
                let workout = createWorkoutForDay(
                    date: date,
                    phase: phase,
                    goal: goal,
                    fitnessLevel: fitnessLevel,
                    dayOfWeek: day
                )
                workouts.append(workout)
            }
        }
        
        return workouts
    }
    
    private static func determinePhase(week: Int, totalWeeks: Int) -> TrainingPhase {
        let phaseLength = totalWeeks / 3
        switch week {
        case 0..<phaseLength:
            return .foundation
        case phaseLength..<(phaseLength * 2):
            return .development
        default:
            return .peak
        }
    }
    
    private static func createWorkoutForDay(
        date: Date,
        phase: TrainingPhase,
        goal: Models.RunningGoal,
        fitnessLevel: Models.FitnessLevel,
        dayOfWeek: Models.Weekday
    ) -> PlannedWorkout {
        switch goal {
        case .beginnerFitness:
            return createBeginnerWorkout(date: date, phase: phase, fitnessLevel: fitnessLevel, dayOfWeek: dayOfWeek)
        case .couchTo5K:
            return createCouch5KWorkout(date: date, phase: phase, fitnessLevel: fitnessLevel, dayOfWeek: dayOfWeek)
        case .raceTraining:
            return createRaceWorkout(date: date, phase: phase, fitnessLevel: fitnessLevel, dayOfWeek: dayOfWeek)
        case .improvePace:
            return createSpeedWorkout(date: date, phase: phase, fitnessLevel: fitnessLevel, dayOfWeek: dayOfWeek)
        }
    }
}

struct PlannedWorkout: Codable, Identifiable {
    let id: UUID
    let date: Date
    let workoutType: WorkoutType
    let duration: TimeInterval
    let distance: Double?
    let intensity: WorkoutIntensity
    let description: String
    
    var asWorkoutItem: WorkoutItem {
        WorkoutItem(
            title: workoutType.title,
            details: "\(formatTime(duration)) • \(intensity.description)",
            iconName: workoutType.iconName,
            gradient: intensity.gradient
        )
    }
}

// Helper function for formatting time
//func formatTime(_ timeInterval: TimeInterval) -> String {
//    let minutes = Int(timeInterval) / 60
//    let seconds = Int(timeInterval) % 60
//    return String(format: "%d:%02d", minutes, seconds)
//}

enum WorkoutType: String, Codable {
    case easy = "Easy Run"
    case longRun = "Long Run"
    case tempo = "Tempo Run"
    case intervals = "Interval Training"
    case recovery = "Recovery Run"
    
    var title: String { rawValue }
    
    var iconName: String {
        switch self {
        case .easy: return "figure.run"
        case .longRun: return "arrow.right.circle"
        case .tempo: return "speedometer"
        case .intervals: return "timer"
        case .recovery: return "heart.circle"
        }
    }
}

enum WorkoutIntensity: String, Codable {
    case low = "Easy"
    case moderate = "Moderate"
    case high = "Hard"
    
    var description: String { rawValue }
    
    var gradient: [Color] {
        switch self {
        case .low:
            return [.customColors.emerald, .customColors.teal]
        case .moderate:
            return [.customColors.orange, .customColors.red]
        case .high:
            return [CustomColors.Brand.primary, CustomColors.Brand.secondary]
        }
    }
}

// MARK: - Specific Workout Generators
extension TrainingPlan {
    private static func createBeginnerWorkout(
        date: Date,
        phase: TrainingPhase,
        fitnessLevel: Models.FitnessLevel,
        dayOfWeek: Models.Weekday
    ) -> PlannedWorkout {
        let baseDistance = fitnessLevel.recommendedDistance
        let baseDuration: TimeInterval = 30 * 60 // 30 minutes
        
        switch (phase, dayOfWeek) {
        case (_, .saturday), (_, .sunday): // Weekend runs are longer
            return PlannedWorkout(
                id: UUID(),
                date: date,
                workoutType: .longRun,
                duration: baseDuration * 1.5,
                distance: baseDistance * 1.5,
                intensity: .low,
                description: "Long Easy Run"
            )
            
        default: // Weekday runs
            let (type, duration, distance, intensity) = phase.beginnerWorkout(baseDistance: baseDistance, baseDuration: baseDuration)
            return PlannedWorkout(
                id: UUID(),
                date: date,
                workoutType: type,
                duration: duration,
                distance: distance,
                intensity: intensity,
                description: "\(type.title) - \(phase.rawValue) Phase"
            )
        }
    }
    
    private static func createCouch5KWorkout(
        date: Date,
        phase: TrainingPhase,
        fitnessLevel: Models.FitnessLevel,
        dayOfWeek: Models.Weekday
    ) -> PlannedWorkout {
        let (duration, runInterval, walkInterval) = phase.couch5KIntervals(weekNumber: 0)
        
        return PlannedWorkout(
            id: UUID(),
            date: date,
            workoutType: .intervals,
            duration: duration,
            distance: nil, // Distance will vary based on pace
            intensity: .moderate,
            description: "Run \(runInterval)min / Walk \(walkInterval)min intervals"
        )
    }
    
    private static func createRaceWorkout(
        date: Date,
        phase: TrainingPhase,
        fitnessLevel: Models.FitnessLevel,
        dayOfWeek: Models.Weekday
    ) -> PlannedWorkout {
        let baseDistance = phase.distanceMultiplier * fitnessLevel.recommendedDistance
        let intensity: WorkoutIntensity = dayOfWeek == .saturday || dayOfWeek == .sunday ? .low : phase.intensity
        
        return PlannedWorkout(
            id: UUID(),
            date: date,
            workoutType: phase.workoutType(dayOfWeek: dayOfWeek),
            duration: baseDistance * fitnessLevel.recommendedPace,
            distance: baseDistance,
            intensity: intensity,
            description: phase.workoutDescription(distance: baseDistance)
        )
    }
    
    private static func createSpeedWorkout(
        date: Date,
        phase: TrainingPhase,
        fitnessLevel: Models.FitnessLevel,
        dayOfWeek: Models.Weekday
    ) -> PlannedWorkout {
        let baseDistance = fitnessLevel.recommendedDistance
        let baseDuration = baseDistance * fitnessLevel.recommendedPace
        
        switch (phase, dayOfWeek) {
        case (_, .saturday):
            return PlannedWorkout(
                id: UUID(),
                date: date,
                workoutType: .longRun,
                duration: baseDuration * 1.5,
                distance: baseDistance * 1.5,
                intensity: .low,
                description: "Long Easy Run"
            )
        case (.peak, .wednesday):
            return PlannedWorkout(
                id: UUID(),
                date: date,
                workoutType: .intervals,
                duration: 45 * 60,
                distance: 5.0,
                intensity: .high,
                description: "Speed Intervals"
            )
        default:
            return PlannedWorkout(
                id: UUID(),
                date: date,
                workoutType: .tempo,
                duration: baseDuration,
                distance: baseDistance,
                intensity: .moderate,
                description: "Tempo Run"
            )
        }
    }
}

// MARK: - Training Phase Extensions
extension TrainingPlan.TrainingPhase {
    var distanceMultiplier: Double {
        switch self {
        case .foundation: return 0.6
        case .development: return 0.8
        case .peak: return 1.0
        }
    }
    
    var intensity: WorkoutIntensity {
        switch self {
        case .foundation: return .low
        case .development: return .moderate
        case .peak: return .high
        }
    }
    
    func workoutType(dayOfWeek: Models.Weekday) -> WorkoutType {
        switch (self, dayOfWeek) {
        case (_, .saturday), (_, .sunday):
            return .longRun
        case (.peak, .wednesday):
            return .intervals
        case (.development, .wednesday):
            return .tempo
        default:
            return .easy
        }
    }
    
    func workoutDescription(distance: Double) -> String {
        switch self {
        case .foundation:
            return "Base Building Run"
        case .development:
            return "Progressive Run"
        case .peak:
            return "Race Pace Run"
        }
    }
    
    func couch5KIntervals(weekNumber: Int) -> (duration: TimeInterval, runInterval: Int, walkInterval: Int) {
        switch weekNumber {
        case 0...1:
            return (30 * 60, 1, 2)
        case 2...3:
            return (30 * 60, 2, 2)
        case 4...5:
            return (35 * 60, 3, 1)
        case 6...7:
            return (35 * 60, 5, 1)
        default:
            return (40 * 60, 8, 1)
        }
    }
}

// MARK: - Supporting Types
extension TrainingPlan {
    enum TrainingPhase: String {
        case foundation = "Foundation"
        case development = "Development"
        case peak = "Peak"
        
        func beginnerWorkout(baseDistance: Double, baseDuration: TimeInterval) -> (WorkoutType, TimeInterval, Double, WorkoutIntensity) {
            switch self {
            case .foundation:
                return (.easy, baseDuration, baseDistance, .low)
            case .development:
                return (.tempo, baseDuration * 1.2, baseDistance * 1.2, .moderate)
            case .peak:
                return (.intervals, baseDuration * 1.3, baseDistance * 1.3, .high)
            }
        }
    }
} 
