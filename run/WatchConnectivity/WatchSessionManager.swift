import Foundation
import WatchConnectivity

class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()
    @Published var isWatchAppInstalled = false
    
    private let session: WCSession
    
    override init() {
        self.session = WCSession.default
        super.init()
        
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    func sendRunConfiguration(type: String, distance: Double, pace: Double) {
        guard session.isReachable else {
            print("Watch is not reachable")
            return
        }
        
        let runConfig: [String: Any] = [
            "type": type,
            "targetDistance": distance,
            "targetPace": pace
        ]
        
        session.sendMessage(runConfig, replyHandler: nil) { error in
            print("Error sending run config to watch: \(error.localizedDescription)")
        }
    }
}

extension WatchSessionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchAppInstalled = session.isWatchAppInstalled
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
} 