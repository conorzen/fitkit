import Foundation

struct RunConfiguration {
    let type: String
    let targetDistance: Double
    let targetPace: Double
    
    init(from message: [String: Any]) {
        self.type = message["type"] as? String ?? "Outdoor Run"
        self.targetDistance = message["targetDistance"] as? Double ?? 5.0
        self.targetPace = message["targetPace"] as? Double ?? 6.0
    }
} 