import WorkoutKit
import HealthKit

struct WorkoutInterval {
    let type: IntervalStep.Purpose
    let distance: Double  // in kilometers
    let targetPaceRange: ClosedRange<Double>  // in min/km
    let iterations: Int
}

class WorkoutStore {
    // Helper function to create a block from an interval
    private static func createBlock(from interval: WorkoutInterval) -> IntervalBlock {
        // Convert distance to miles
        let distanceInMiles = interval.distance * 0.621371
        
        // Convert pace to MPH
        let avgPace = (interval.targetPaceRange.lowerBound + interval.targetPaceRange.upperBound) / 2
        let paceInMPH = 37.28 / avgPace
        let paceRange = (paceInMPH - 1)...(paceInMPH + 1)
        
        // Create the interval step
        var step = IntervalStep(interval.type)
        step.step.goal = .distance(distanceInMiles, .miles)
        step.step.alert = .speed(paceRange, unit: .milesPerHour, metric: .current)
        
        // Create and return the block
        var block = IntervalBlock()
        block.steps = [step]
        block.iterations = interval.iterations
        return block
    }
    
    static func createRunningCustomWorkout(
        name: String,
        warmupDuration: Double = 5.0,
        cooldownDuration: Double = 5.0,
        intervals: [WorkoutInterval]
    ) -> CustomWorkout {
        // Create warmup and cooldown
        let warmupStep = WorkoutStep(goal: .time(warmupDuration, .minutes))
        let cooldownStep = WorkoutStep(goal: .time(cooldownDuration, .minutes))
        
        // Create blocks
        let blocks = intervals.map { createBlock(from: $0) }
        
        // Create and return the workout
        return CustomWorkout(
            activity: .running,
            location: .outdoor,
            displayName: name.isEmpty ? "Planned Run" : name,
            warmup: warmupStep,
            blocks: blocks,
            cooldown: cooldownStep
        )
    }
    
    static func createSimpleRunWorkout(
        name: String,
        distance: Double,
        targetPace: Double
    ) -> CustomWorkout {
        let interval = WorkoutInterval(
            type: .work,
            distance: distance,
            targetPaceRange: (targetPace - 0.5)...(targetPace + 0.5),
            iterations: 1
        )
        
        return createRunningCustomWorkout(
            name: name,
            intervals: [interval]
        )
    }
    
    static func createIntervalWorkout(
        name: String,
        workInterval: WorkoutInterval,
        recoveryInterval: WorkoutInterval
    ) -> CustomWorkout {
        return createRunningCustomWorkout(
            name: name,
            intervals: [workInterval, recoveryInterval]
        )
    }
    
    static func createProgressiveWorkout(
        name: String,
        baseDistance: Double,
        basePace: Double,
        numberOfProgressions: Int,
        paceIncrease: Double = 0.5
    ) -> CustomWorkout {
        var intervals: [WorkoutInterval] = []
        
        for i in 0..<numberOfProgressions {
            let adjustedPace = basePace - Double(i) * paceIncrease
            let interval = WorkoutInterval(
                type: .work,
                distance: baseDistance,
                targetPaceRange: (adjustedPace - 0.25)...(adjustedPace + 0.25),
                iterations: 1
            )
            intervals.append(interval)
        }
        
        return createRunningCustomWorkout(
            name: name,
            intervals: intervals
        )
    }
}


 let simpleRun = WorkoutStore.createSimpleRunWorkout(
     name: "5K Run",
     distance: 5.0,
     targetPace: 5.0
 )
 
 // Interval training
 let workInterval = WorkoutInterval(
     type: .work,
     distance: 0.4,  // 400m
     targetPaceRange: 4.0...4.5,
     iterations: 8
 )
 
 let recoveryInterval = WorkoutInterval(
     type: .recovery,
     distance: 0.4,
     targetPaceRange: 6.0...6.5,
     iterations: 8
 )
 
 let intervalWorkout = WorkoutStore.createIntervalWorkout(
     name: "8x400m Intervals",
     workInterval: workInterval,
     recoveryInterval: recoveryInterval
 )
 
 // Progressive run
 let progressiveRun = WorkoutStore.createProgressiveWorkout(
     name: "Progressive 5K",
     baseDistance: 1.0,
     basePace: 5.5,
     numberOfProgressions: 5
 )

