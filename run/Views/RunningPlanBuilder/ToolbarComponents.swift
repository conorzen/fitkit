import SwiftUI

struct RunningPlanToolbar {
    let currentStep: Int
    let canProceedToNextStep: Bool
    let canCreatePlan: Bool
    let onBack: () -> Void
    let onNext: () -> Void
    let onCreatePlan: () -> Void
    
    @ToolbarContentBuilder
    func makeToolbarContent() -> some ToolbarContent {
        makeBackButton()
        makeActionButton()
    }
    
    @ToolbarContentBuilder
    private func makeBackButton() -> some ToolbarContent {
        if currentStep > 0 {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back", action: onBack)
            }
        }
    }
    
    @ToolbarContentBuilder
    private func makeActionButton() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if currentStep < 2 {
                makeNextButton()
            } else {
                makeCreatePlanButton()
            }
        }
    }
    
    private func makeNextButton() -> some View {
        Button("Next", action: onNext)
            .disabled(!canProceedToNextStep)
    }
    
    private func makeCreatePlanButton() -> some View {
        Button("Create Plan", action: onCreatePlan)
            .disabled(!canCreatePlan)
    }
} 