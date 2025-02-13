import SwiftUI
import Supabase
import AuthenticationServices
import FacebookLogin

struct AuthenticationView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("isSignedIn") private var isSignedIn = false
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("Welcome to RunAI")
                .font(.title)
                .bold()
            
            VStack(spacing: 15) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .disabled(isLoading)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isLoading)
                
                Button(action: signIn) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign In")
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
                .disabled(isLoading)
                
                Text("Or continue with")
                    .foregroundColor(.gray)
                    .padding(.vertical)
                
                HStack(spacing: 20) {
                    Button(action: signInWithFacebook) {
                        HStack {
                            Image(systemName: "f.circle.fill")
                            Text("Facebook")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    
                    Button(/*action:*/ "signInWithInstagram") {
                        HStack {
                            Image(systemName: "camera.circle.fill")
                            Text("Instagram")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(10)
                    }
                }
                
                Button(action: signUp) {
                    Text("Create Account")
                        .foregroundColor(.blue)
                }
                .disabled(isLoading)
            }
            .padding(.horizontal, 40)
        }
        .padding()
        .alert("Authentication Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                _ = try await SupabaseConfig.client.auth.signIn(
                    email: email,
                    password: password
                )
                
                DispatchQueue.main.async {
                    isLoading = false
                    isSignedIn = true
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func signUp() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                _ = try await SupabaseConfig.client.auth.signUp(
                    email: email,
                    password: password
                )
                
                DispatchQueue.main.async {
                    isLoading = false
                    isSignedIn = true
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func signInWithFacebook() {
        isLoading = true
        let loginManager = LoginManager()
        loginManager.logIn(permissions: ["public_profile", "email"], from: nil) { result, error in
            if let error = error {
                print("Facebook login error: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
                return
            }
            
            if let result = result, !result.isCancelled {
                print("Facebook login success")
                Task {
                    do {
                        let redirectURL = URL(string: "https://ayxsbkcgebkjoeywmabj.supabase.co/auth/v1/callback")!
                        let authURL = try await SupabaseConfig.client.auth.getOAuthSignInURL(
                            provider: .facebook,
                            scopes: "email,public_profile",
                            redirectTo: redirectURL
                        )
                        await UIApplication.shared.open(authURL)
                        await checkForAuth()
                    } catch {
                        print("Supabase auth error: \(error)")
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.errorMessage = error.localizedDescription
                            self.showError = true
                        }
                    }
                }
            } else {
                print("Facebook login cancelled")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func checkForAuth() async {
        print("Starting auth check...")
        let maxAttempts = 30
        let delaySeconds: UInt64 = 2_000_000_000 // 2 seconds between checks
        
        for attempt in 1...maxAttempts {
            print("Auth check attempt \(attempt)/\(maxAttempts)")
            
            // Check if we have a session
            if let session = try? await SupabaseConfig.client.auth.session {
                print("Found session: \(session)")
                DispatchQueue.main.async {
                    UserDefaults.standard.set(false, forKey: "awaitingFacebookAuth")
                    isLoading = false
                    isSignedIn = true
                    print("Successfully signed in!")
                }
                return
            }
            
            // If we're no longer awaiting Facebook auth, stop checking
            if !UserDefaults.standard.bool(forKey: "awaitingFacebookAuth") {
                print("No longer awaiting Facebook auth")
                break
            }
            
            if attempt < maxAttempts {
                try? await Task.sleep(nanoseconds: delaySeconds)
            }
        }
        
        print("Auth check timed out")
        DispatchQueue.main.async {
            UserDefaults.standard.set(false, forKey: "awaitingFacebookAuth")
            isLoading = false
            errorMessage = "Authentication timed out. Please try again."
            showError = true
        }
    }
    
    // private func signInWithInstagram() {
    //     isLoading = true
    //     Task {
    //         do {
    //             let authURL = try await SupabaseConfig.client.auth.getOAuthSignInURL(
    //                 provider: .instagram,
    //                 redirectTo: URL(string: "run://login-callback")
    //             )
    //             await UIApplication.shared.open(authURL)
    //         } catch {
    //             DispatchQueue.main.async {
    //                 isLoading = false
    //                 errorMessage = error.localizedDescription
    //                 showError = true
    //             }
    //         }
    //     }
    // }
}

#Preview {
    AuthenticationView()
} 
