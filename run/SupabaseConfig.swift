import Foundation
import Supabase

enum SupabaseConfig {
    static let client = SupabaseClient(
        supabaseURL: URL(string: "https://ayxsbkcgebkjoeywmabj.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF5eHNia2NnZWJram9leXdtYWJqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg1OTI4NjMsImV4cCI6MjA1NDE2ODg2M30.-_rxhamoGzgtqzMHq8QT1xWOq2gqlttHiSHl_NDaSTg"
    )
    
    // Add some helper methods for common operations
    static func getCurrentUser() async throws -> User? {
        do {
            let session = try await client.auth.session
            let authUser = session.user
            let metadata = authUser.userMetadata
            
            // Debug print
            print("User metadata: \(metadata)")
            
            // Safely handle metadata conversions
            let name: String? = {
                if let fullName = metadata["full_name"] {
                    return String(describing: fullName)
                }
                if let name = metadata["name"] {
                    return String(describing: name)
                }
                return nil
            }()
            
            let profileUrl: String? = {
                if let avatarUrl = metadata["avatar_url"] {
                    return String(describing: avatarUrl)
                }
                if let picture = metadata["picture"] {
                    return String(describing: picture)
                }
                return nil
            }()
            
            return User(
                id: authUser.id,
                email: authUser.email,
                name: name,
                profileImageUrl: profileUrl,
                createdAt: authUser.createdAt
            )
        } catch {
            print("Error getting session: \(error)")
            return nil
        }
    }
    
    static func signOut() async throws {
        try await client.auth.signOut()
    }
    
    static func handleFacebookCallback(url: URL) async throws -> Bool {
        do {
            _ = try await client.auth.session(from: url)
            return true
        } catch {
            print("Error handling callback: \(error)")
            return false
        }
    }
    
    static func checkAuthStatus() async throws -> Bool {
        do {
            let user = try await client.auth.user()
            print("Found user: \(String(describing: user))")
            return user != nil
        } catch {
            print("Auth check error: \(error)")
            return false
        }
    }
} 
