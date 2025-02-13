//
//  RunningView.swift
//  run
//
//  Created by Conor Reid Admin on 09/02/2025.

import SwiftUI
import HealthKit
import WorkoutKit

// Add the model structures
struct StatItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let unit: String
    let trend: String
}

struct RunItem: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let distance: String
    let duration: String
    let gradient: [Color]
}

struct RunningView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var healthKit = HealthKitManager.shared
    @State private var selectedTab = 0
    @State private var isRunning = false
    @State private var yearlyStats: RunningStatistics = .empty
    @State private var recentRuns: [RecentRun] = []
    @State private var showingNewRunSheet = false
    
    // Computed property for stats
    private var stats: [StatItem] {
        [
            StatItem(title: "This Week", value: "\(String(format: "%.1f", yearlyStats.totalDistance/1000))", unit: "km", trend: "+2.3"),
            StatItem(title: "Avg. Pace", value: formatPace(yearlyStats.averagePace), unit: "/km", trend: "-0:15"),
            StatItem(title: "Activities", value: "\(yearlyStats.totalRuns)", unit: "runs", trend: "+3")
        ]
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        // Profile Image - moved to the start
                        Circle()
                            .fill(LinearGradient(
                                colors: [CustomColors.Brand.primary, CustomColors.Brand.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                            )
                            .padding(.trailing, 12)
                        
                        // Welcome text
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hello!")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text(formattedDate())
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    
                    // Add the metrics carousel after the header
                    MetricsCarouselView()
                    
                    // Featured Workout Card
                    FeaturedWorkoutCard()
                    
                    // Quick Actions Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        QuickActionTile(
                            title: "Workout",
                            value: "2 hours",
                            icon: "figure.run",
                            gradient: [CustomColors.Brand.primary, CustomColors.Brand.secondary]
                        )
                        QuickActionTile(
                            title: "Running",
                            value: "12 km",
                            icon: "stopwatch",
                            gradient: [.customColors.rose, .customColors.pink]
                        )
                        QuickActionTile(
                            title: "Food",
                            value: "1832 kcal",
                            icon: "fork.knife",
                            gradient: [.customColors.emerald, .customColors.teal]
                        )
                    }
                    
                    // Activities Chart
                    WeeklyActivityChart()
                }
                .padding()
            }
            .scrollIndicators(.hidden)
            .background(Color.customColors.background)
        }
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, dd MMMM"
        return formatter.string(from: Date())
    }
    
    
    var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Progress")
                .font(.title3)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(stats) { stat in
                    StatCard(stat: stat)
                }
            }
        }
    }
    
   
    private func formatPace(_ pace: Double) -> String {
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}



#Preview {
    RunningView()
}
