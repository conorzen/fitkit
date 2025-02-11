import SwiftUI
import WatchKit

struct RunningView: View {
    @StateObject private var sessionManager = WatchSessionManager.shared
    @State private var isRunning = false
    
    var body: some View {
        if let config = sessionManager.latestRunConfig {
            VStack(spacing: 10) {
                Text(config.type)
                    .font(.headline)
                
                HStack {
                    Image(systemName: "arrow.left.and.right")
                    Text(String(format: "%.1f km", config.targetDistance))
                }
                
                HStack {
                    Image(systemName: "speedometer")
                    Text(formatPace(config.targetPace))
                }
                
                if isRunning {
                    Button("Stop Run") {
                        isRunning = false
                        // Stop workout
                    }
                    .tint(.red)
                } else {
                    Button("Start Run") {
                        isRunning = true
                        // Start workout
                    }
                    .tint(.green)
                }
            }
        } else {
            Text("Waiting for run configuration...")
        }
    }
    
    private func formatPace(_ pace: Double) -> String {
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d /km", minutes, seconds)
    }
} 