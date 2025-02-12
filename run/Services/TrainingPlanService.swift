import Foundation
import Supabase
import WorkoutKit
import Combine
import HealthKit

class TrainingPlanService: ObservableObject {
    static let shared = TrainingPlanService()
    
    @Published private(set) var plans: [TrainingPlan] = []
    @Published private(set) var authorizationState: WorkoutScheduler.AuthorizationState = .notDetermined
    
    private let supabase: SupabaseClient
    private let workoutStore: WorkoutStore
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    private init() {
        self.supabase = SupabaseConfig.client
        self.workoutStore = WorkoutStore()
        
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        Task {
            await checkAuthorization()
            try? await loadPlans()
        }
    }
    
    func checkAuthorization() async {
        authorizationState = await WorkoutScheduler.shared.authorizationState
    }
    
    func requestAuthorization() async {
        authorizationState = await WorkoutScheduler.shared.requestAuthorization()
    }
    
    func loadPlans() async throws {
        guard let session = try? await supabase.auth.session,
              let userId = UUID(uuidString: session.user.id.uuidString) else { return }
        
        let decodedPlans: [TrainingPlan] = try await supabase.database
            .from("training_plans")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        
        await MainActor.run {
            plans = decodedPlans
        }
    }
    
    func savePlan(_ plan: TrainingPlan) async throws {
        print("TrainingPlanService: Starting plan save")
        
        // First check/request authorization
        if authorizationState != .authorized {
            print("TrainingPlanService: Requesting WorkoutKit authorization")
            await requestAuthorization()
            
            guard authorizationState == .authorized else {
                throw NSError(domain: "TrainingPlanService", 
                            code: 1, 
                            userInfo: [NSLocalizedDescriptionKey: "WorkoutKit authorization required"])
            }
        }
        
        // Save to Supabase and get response
        print("TrainingPlanService: Saving to Supabase")
        let response: TrainingPlan = try await supabase.database
            .from("training_plans")
            .insert(plan)
            .select()
            .single()
            .execute()
            .value
        
        print("TrainingPlanService: Plan saved successfully")
        
        await MainActor.run {
            plans.append(response)
            NotificationCenter.default.post(
                name: Notification.Name("trainingPlanCreated"),
                object: nil,
                userInfo: ["plan": response]
            )
        }
        
        // Schedule workouts
        print("TrainingPlanService: Scheduling workouts")
        try await scheduleWorkouts(response)
    }
    
    func deletePlan(withId id: UUID) async throws {
        try await supabase.database
            .from("training_plans")
            .delete()
            .eq("id", value: id)
            .execute()
        
        await MainActor.run {
            plans.removeAll { $0.id == id }
            NotificationCenter.default.post(
                name: Notification.Name("trainingPlanDeleted"),
                object: nil,
                userInfo: ["planId": id]
            )
        }
    }
    
    func updatePlan(_ updatedPlan: TrainingPlan) async throws {
        let response: TrainingPlan = try await supabase.database
            .from("training_plans")
            .update(updatedPlan)
            .eq("id", value: updatedPlan.id)
            .select()
            .single()
            .execute()
            .value
        
        await MainActor.run {
            if let index = plans.firstIndex(where: { $0.id == updatedPlan.id }) {
                plans[index] = response
            }
            NotificationCenter.default.post(
                name: Notification.Name("trainingPlanUpdated"),
                object: nil,
                userInfo: ["plan": response]
            )
        }
    }
    
    func getActivePlan() -> TrainingPlan? {
        let today = Date()
        return plans.first { plan in
            today >= plan.startDate && today <= plan.endDate
        }
    }
    
    // MARK: - Watch Integration
    private func scheduleWorkouts(_ plan: TrainingPlan) async throws {
        for workout in plan.workouts {
            let workoutPlan = createWorkoutPlan(from: workout)
            
            // Convert date to components
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: workout.date
            )
            
            // Schedule with WorkoutKit
            try await WorkoutScheduler.shared.schedule(workoutPlan, at: dateComponents)
            print("TrainingPlanService: Scheduled workout for \(workout.date)")
        }
        
        // Refresh scheduled workouts
        let scheduledWorkouts = await WorkoutScheduler.shared.scheduledWorkouts
        print("TrainingPlanService: Total scheduled workouts: \(scheduledWorkouts.count)")
    }
    
    private func createWorkoutPlan(from workout: PlannedWorkout) -> WorkoutPlan {
        // Create warmup - 10 minute easy jog
        let warmupStep = WorkoutStep(
            goal: .time(10, .minutes),
            displayName: "Warm Up - Easy Jog"
        )
        
        // Create main workout block
        var workStep = IntervalStep(.work)
        if let distance = workout.distance {
            workStep.step.goal = .distance(distance, .kilometers)
        } else {
            workStep.step.goal = .time(workout.duration, .seconds)
        }
        workStep.step.displayName = workout.workoutType.title
        
        // Create recovery block if needed
        var recoveryStep = IntervalStep(.recovery)
        recoveryStep.step.goal = .time(2, .minutes)
        recoveryStep.step.displayName = "Recovery"
        
        // Create the interval block
        let block = IntervalBlock(
            steps: [workStep, recoveryStep],
            iterations: 1
        )
        
        // Create cooldown - 5 minute walk
        let cooldownStep = WorkoutStep(
            goal: .time(5, .minutes),
            displayName: "Cool Down - Walk"
        )
        
        // Create the complete workout
        let customWorkout = CustomWorkout(
            activity: .running,
            location: .outdoor,
            displayName: workout.workoutType.title,
            warmup: warmupStep,
            blocks: [block],
            cooldown: cooldownStep
        )
        
        return WorkoutPlan(.custom(customWorkout))
    }
} 
