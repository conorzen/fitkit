//
//  GoalSelectionView.swift
//  run
//
//  Created by Conor Reid Admin on 11/02/2025.
//

import SwiftUI

struct GoalSelectionView: View {
    @Binding var selectedGoal: Models.RunningGoal
    
    // Define your goals data in a separate constant
    let goalItems: [(goal: Models.RunningGoal, title: String, subtitle: String, icon: String)] = [
        (goal: .beginnerFitness, title: "Get Fit", subtitle: "Start running to improve fitness", icon: "figure.run"),
        (goal: .couchTo5K, title: "Couch to 5K", subtitle: "Train for your first 5K", icon: "figure.run.circle"),
        (goal: .raceTraining, title: "Race Training", subtitle: "Prepare for a specific race", icon: "flag.checkered"),
        (goal: .improvePace, title: "Improve Pace", subtitle: "Get faster at your current distance", icon: "speedometer")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Running Goals Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Running Goals")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    VStack(spacing: 12) {
                        ForEach(goalItems, id: \.title) { item in
                            Button {
                                selectedGoal = item.goal
                            } label: {
                                HStack {
                                    Image(systemName: item.icon)
                                        .font(.title2)
                                        .frame(width: 32)
                                    
                                    VStack(alignment: .leading) {
                                        Text(item.title)
                                            .font(.headline)
                                        Text(item.subtitle)
                                            .font(.subheadline)
                                            .opacity(0.9)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedGoal == item.goal {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .background(selectedGoal == item.goal ? Color.white.opacity(0.2) : Color.clear)
                                .cornerRadius(12)
                            }
                            .foregroundColor(.white)
                        }
                    }
                }
                .padding(20)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            CustomColors.Brand.primary,
                            CustomColors.Brand.secondary
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .shadow(radius: 5)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

