import Foundation

public struct RecentRun: Identifiable {
    public let id = UUID()
    public let date: Date
    public let distance: Double
    public let duration: String
    public let calories: Double
    public let averagePace: Double
    
    public init(date: Date, distance: Double, duration: String, calories: Double, averagePace: Double) {
        self.date = date
        self.distance = distance
        self.duration = duration
        self.calories = calories
        self.averagePace = averagePace
    }
} 