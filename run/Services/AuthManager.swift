import Foundation
import Combine
import Supabase
import Auth


class AuthManager: ObservableObject {
    @Published var currentUser: Auth.User?
    private let supabase: SupabaseClient
    
    init() {
        self.supabase = SupabaseConfig.client
        Task {
            await checkSession()
        }
    }
    
    @MainActor
    func checkSession() async {
        do {
            if let user = try? await supabase.auth.user() {
                print("User found: \(user)")
                self.currentUser = user as Auth.User
            } else {
                print("No user found")
                self.currentUser = nil
            }
        } catch {
            print("Error checking session: \(error)")
            self.currentUser = nil
        }
    }
    
    func signIn(email: String, password: String) async throws {
        let session = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        await MainActor.run {
            self.currentUser = session.user as Auth.User
        }
    }
    
    func signOut() async throws {
        try await supabase.auth.signOut()
        await MainActor.run {
            self.currentUser = nil
        }
    }
    
    // ... rest of AuthManager implementation ...
} 
