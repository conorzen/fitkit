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
        Form {
            Section {
                ForEach(goalItems, id: \.title) { item in
                    Button {
                        selectedGoal = item.goal
                    } label: {
                        GoalCell(
                            title: item.title,
                            subtitle: item.subtitle,
                            icon: item.icon,
                            isSelected: selectedGoal == item.goal
                        )
                    }
                }
            } header: {
                Text("What's your running goal?")
            }
        }
    }
}

