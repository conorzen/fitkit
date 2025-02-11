import Foundation

public struct RunningStatistics {
    public let totalRuns: Int
    public let totalDistance: Double
    public let averagePace: Double
    
    public init(totalRuns: Int, totalDistance: Double, averagePace: Double) {
        self.totalRuns = totalRuns
        self.totalDistance = totalDistance
        self.averagePace = averagePace
    }
    
    public static let empty = RunningStatistics(totalRuns: 0, totalDistance: 0, averagePace: 0)
} 