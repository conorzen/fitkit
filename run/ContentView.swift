//
//  ContentView.swift
//  run
//
//  Created by Conor Reid Admin on 08/02/2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("isSignedIn") private var isSignedIn = false
    @State private var showError = false
    @State private var errorMessage = ""
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        if !isSignedIn {
            AuthenticationView()
                .preferredColorScheme(themeManager.selectedTheme.colorScheme)
        } else {
            NavigationView {
                TabView {
                    RunningView()
                        .tabItem {
                            Label("run", systemImage: "figure.run")
                        }
                    
                    WorkoutCalendarView()
                        .tabItem {
                            Label("Training", systemImage: "calendar")
                        }
                    
                    VoiceCoachView()
                        .tabItem {
                            Label("Coach", systemImage: "waveform.and.mic")
                        }
                    
                    RouteView()
                        .tabItem {
                            Label("Routes", systemImage: "map")
                        }
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape")
                        }
                }
                .preferredColorScheme(themeManager.selectedTheme.colorScheme)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        
                    }
                }
                .alert("Error", isPresented: $showError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(errorMessage)
                }
            }
        }
    }
    
}



struct TrainingPlanView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Training Plans")
                    .font(.title)
                
                Button(action: {
                    // Generate training plan
                }) {
                    Label("Create Plan", systemImage: "plus")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Training")
        }
        .preferredColorScheme(themeManager.selectedTheme.colorScheme)
    }
}

struct VoiceCoachView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Voice Coach")
                    .font(.title)
                
                Button(action: {
                    // Start voice coaching
                }) {
                    Label("Start Coaching", systemImage: "play.circle")
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Coach")
        }
        .preferredColorScheme(themeManager.selectedTheme.colorScheme)
    }
}

struct RouteView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Route Generator")
                    .font(.title)
                
                Button(action: {
                    // Generate new route
                }) {
                    Label("Generate Route", systemImage: "map")
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Routes")
        }
        .preferredColorScheme(themeManager.selectedTheme.colorScheme)
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
