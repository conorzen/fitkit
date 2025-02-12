import Foundation
import SwiftUI

enum Models {
    enum RunningGoal: String, Codable, CaseIterable {
        case beginnerFitness = "General Fitness"
        case couchTo5K = "Couch to 5K"
        case raceTraining = "Race Training"
        case improvePace = "Improve Pace"
        
        var description: String {
            switch self {
            case .beginnerFitness:
                return "Build general fitness through running"
            case .couchTo5K:
                return "Train to run your first 5K"
            case .raceTraining:
                return "Prepare for a specific race"
            case .improvePace:
                return "Get faster at your current distance"
            }
        }
    }

    enum FitnessLevel: String, Codable, CaseIterable {
        case beginner = "New to Running"
        case intermediate = "Run Occasionally"
        case advanced = "Regular Runner"
        
        var description: String {
            switch self {
            case .beginner:
                return "• Little to no running experience\n• Can walk for 30+ minutes\n• Looking to start running regularly"
            case .intermediate:
                return "• Can run 5K without stopping\n• Run 1-2 times per week\n• Have completed a few organized runs"
            case .advanced:
                return "• Regular runner (3+ times per week)\n• Can run 10K comfortably\n• Have completed multiple races"
            }
        }
        
        var recommendedWeeklyRuns: String {
            switch self {
            case .beginner:
                return "2-3 runs per week"
            case .intermediate:
                return "3-4 runs per week"
            case .advanced:
                return "4-6 runs per week"            }
        }
        
        var recommendedDistance: Double {
            switch self {
            case .beginner:
                return 2.0
            case .intermediate:
                return 5.0
            case .advanced:
                return 10.0
            }
        }
        
        var recommendedPace: TimeInterval {
            switch self {
            case .beginner:
                return 7.0 * 60
            case .intermediate:
                return 6.0 * 60
            case .advanced:
                return 5.0 * 60
            }
        }
        var typicalPace: String {
             switch self {
             case .beginner:
                 return "Start with run/walk intervals"
             case .intermediate:
                 return "Comfortable conversational pace"
             case .advanced:
                 return "Varied paces for different workouts"
             }
         }
    }

    enum TimeOfDay: String, Codable, CaseIterable {
        case morning = "Morning"
        case afternoon = "Afternoon"
        case evening = "Evening"
    }

    enum Weekday: String, Codable, CaseIterable {
        case monday = "Monday"
        case tuesday = "Tuesday"
        case wednesday = "Wednesday"
        case thursday = "Thursday"
        case friday = "Friday"
        case saturday = "Saturday"
        case sunday = "Sunday"
        
        
        var dayValue: Int {
            switch self {
            case .monday: return 0
            case .tuesday: return 1
            case .wednesday: return 2
            case .thursday: return 3
            case .friday: return 4
            case .saturday: return 5
            case .sunday: return 6
            }
        }
    }
}

// Keep the shared formatting function outside the namespace
func formatTime(_ timeInterval: TimeInterval) -> String {
    let minutes = Int(timeInterval) / 60
    let seconds = Int(timeInterval) % 60
    return String(format: "%d:%02d", minutes, seconds)
}


// Add notification name
extension Notification.Name {
    static let planCreated = Notification.Name("planCreated")
} 
