import Foundation
import Supabase
import WorkoutKit

class TrainingPlanService {
    static let shared = TrainingPlanService()
    private let supabase: SupabaseClient
    
    private init() {
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: "YOUR_SUPABASE_URL")!,
            supabaseKey: "YOUR_SUPABASE_KEY"
        )
    }
    
    func savePlan(_ plan: TrainingPlan) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(plan)
        
        try await supabase.database
            .from("training_plans")
            .insert(data)
            .execute()
    }
    
    func getPlans(for userId: String) async throws -> [TrainingPlan] {
        let response = try await supabase.database
            .from("training_plans")
            .select()
            .eq("userId", value: userId)
            .execute()
        
        let decoder = JSONDecoder()
        let data = try JSONSerialization.data(withJSONObject: response.data ?? [], options: [])
        return try decoder.decode([TrainingPlan].self, from: data)
    }
    
    func scheduleWorkouts(_ plan: TrainingPlan) async throws {
        // First save to Supabase
        try await savePlan(plan)
        
        // Then schedule on the watch
        for workout in plan.workouts {
            let workoutPlan = try await createWorkoutPlan(from: workout)
            try await scheduleWorkout(workoutPlan, at: workout.date)
        }
    }
    
    private func createWorkoutPlan(from workout: PlannedWorkout) async throws -> CustomWorkout {
        // Create workout using WorkoutKit
        let blocks = try await generateWorkoutBlocks(for: workout)
        
        return CustomWorkout(
            activity: .running,
            location: .outdoor,
            displayName: workout.workoutType.title,
            blocks: blocks
        )
    }
    
    private func generateWorkoutBlocks(for workout: PlannedWorkout) async throws -> [IntervalBlock] {
        var blocks: [IntervalBlock] = []
        
        switch workout.workoutType {
        case .intervals:
            let workStep = IntervalStep(.work, goal: .distance(400, .meters))
            let restStep = IntervalStep(.recovery, goal: .time(60, .seconds))
            blocks.append(IntervalBlock(steps: [workStep, restStep], iterations: 8))
            
        default:
            let mainStep = IntervalStep(
                .work,
                goal: workout.distance != nil ?
                    .distance(workout.distance! * 1000, .meters) :
                    .time(workout.duration, .seconds)
            )
            blocks.append(IntervalBlock(steps: [mainStep], iterations: 1))
        }
        
        return blocks
    }
    
    private func scheduleWorkout(_ workout: CustomWorkout, at date: Date) async throws {
        // Implement workout scheduling using WorkoutKit
        // This will depend on your specific implementation
    }
} 