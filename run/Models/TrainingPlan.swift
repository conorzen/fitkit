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
    let userId: String
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
    
    enum CodingKeys: String, CodingKey {
        case id, userId, name, goal, startDate, endDate
        case fitnessLevel, workoutDays, preferredTime, workouts
        case current5KTime, targetRaceDistance, targetRaceTime
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        goal = try container.decode(Models.RunningGoal.self, forKey: .goal)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        fitnessLevel = try container.decode(Models.FitnessLevel.self, forKey: .fitnessLevel)
        workoutDays = try container.decode([Models.Weekday].self, forKey: .workoutDays)
        preferredTime = try container.decode(Models.TimeOfDay.self, forKey: .preferredTime)
        workouts = try container.decode([PlannedWorkout].self, forKey: .workouts)
        current5KTime = try container.decodeIfPresent(TimeInterval.self, forKey: .current5KTime)
        targetRaceDistance = try container.decodeIfPresent(Double.self, forKey: .targetRaceDistance)
        targetRaceTime = try container.decodeIfPresent(TimeInterval.self, forKey: .targetRaceTime)
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
    }
    
    init(id: UUID, userId: String, name: String, goal: Models.RunningGoal, startDate: Date, endDate: Date, 
         fitnessLevel: Models.FitnessLevel, workoutDays: [Models.Weekday], preferredTime: Models.TimeOfDay,
         workouts: [PlannedWorkout], current5KTime: TimeInterval?, targetRaceDistance: Double?, targetRaceTime: TimeInterval?) {
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
    }
    
    var durationInWeeks: Int {
        Calendar.current.dateComponents([.weekOfYear], from: startDate, to: endDate).weekOfYear ?? 0
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
