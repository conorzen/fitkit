//
//  SettingsView.swift
//  run
//
//  Created by Conor Reid Admin on 09/02/2025.
//

import SwiftUI
import Supabase

struct SettingsView: View {
    @AppStorage("isSignedIn") private var isSignedIn = false
    @State private var currentUser: User?
    // State variables for user preferences
    @State private var username = "Runner123"
    @State private var isHealthKitEnabled = false
    @State private var isNotificationsEnabled = true
    @State private var selectedDistanceUnit = DistanceUnit.miles
    @State private var selectedVoiceFeedback = VoiceFeedback.everyMile
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var healthKit = HealthKitManager.shared
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section {
                    HStack {
                        if let profileUrl = currentUser?.profileImageUrl,
                           let url = URL(string: profileUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.blue)
                            }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentUser?.name ?? username)
                                .font(.headline)
                            if let email = currentUser?.email {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Text("Member since 2024")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.vertical, 4)
                    
                    NavigationLink("Edit Profile") {
                        Text("Edit Profile View")
                    }
                } header: {
                    Text("Profile")
                }
                
                // Preferences Section
                Section(header: Text("Preferences")) {
                    Picker("Distance Unit", selection: $selectedDistanceUnit) {
                        ForEach(DistanceUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    
                    Picker("Voice Feedback", selection: $selectedVoiceFeedback) {
                        ForEach(VoiceFeedback.allCases, id: \.self) { feedback in
                            Text(feedback.rawValue).tag(feedback)
                        }
                    }
                }
                
                // Appearance Section
                Section(header: Text("Appearance")) {
                    Picker("App Theme", selection: $themeManager.selectedTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                }
                
                // Health & Tracking Section
                Section(header: Text("Health & Tracking")) {
                    Toggle("HealthKit Integration", isOn: Binding(
                        get: { isHealthKitEnabled },
                        set: { newValue in
                            isHealthKitEnabled = newValue
                            healthKit.toggleHealthKit(isEnabled: newValue)
                        }
                    ))
                    
                    if isHealthKitEnabled {
                        if healthKit.isHealthKitAvailable {
                            if healthKit.isAuthorized {
                                Text("Connected to HealthKit")
                                    .foregroundColor(.green)
                            } else {
                                Text("Authorization Required")
                                    .foregroundColor(.orange)
                                Button("Authorize HealthKit") {
                                    Task {
                                        await healthKit.requestAuthorization()
                                    }
                                }
                            }
                        } else {
                            Text("HealthKit not available on this device")
                                .foregroundColor(.red)
                        }
                    }
                    
                    Toggle("Allow Notifications", isOn: $isNotificationsEnabled)
                    
                    NavigationLink("Privacy Settings") {
                        Text("Privacy Settings View")
                    }
                    
                    NavigationLink("Export Running Data") {
                        Text("Data Export View")
                    }
                }
                
                // Integration Section
                Section(header: Text("Devices and connections")) {
                    NavigationLink {
                        Devices()
                    } label: {
                        HStack {
                            Text("Devices")
                            Spacer()
                            Image(systemName: "applewatch")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    NavigationLink {
                        Text("Metrics View")
                    } label: {
                        HStack {
                            Text("Customize Metrics")
                            Spacer()
                            Image(systemName: "speedometer")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // About Section
                Section(header: Text("About")) {
                    NavigationLink("Help & Support") {
                        Text("Help Center View")
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    Button(role: .destructive) {
                        Task {
                            do {
                                try await SupabaseConfig.signOut()
                                isSignedIn = false
                            } catch {
                                print("Error signing out: \(error)")
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Log Out")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .task {
                await loadUserProfile()
            }
        }
    }
    
    private func loadUserProfile() async {
        do {
            currentUser = try await SupabaseConfig.getCurrentUser()
        } catch {
            print("Error loading user profile: \(error)")
        }
    }
}

// MARK: - Supporting Types
enum DistanceUnit: String, CaseIterable {
    case miles = "Miles"
    case kilometers = "Kilometers"
}

enum VoiceFeedback: String, CaseIterable {
    case off = "Off"
    case everyMinute = "Every Minute"
    case everyMile = "Every Mile"
    case everyKilometer = "Every Kilometer"
}

// MARK: - Preview Provider
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .preferredColorScheme(.light)
        
        SettingsView()
            .preferredColorScheme(.dark)
    }
}

// MARK: - Helper Views
struct SettingsToggle: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(title, isOn: $isOn)
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundColor(color)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
    }
}
            
            
            
            
            
             
        
           
    
       
    
    








#Preview{
    
    
    SettingsView()
 
    
}
