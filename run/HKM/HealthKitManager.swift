//
//  HealthKitManager.swift
//  run
//
//  Created by Conor Reid Admin on 09/02/2025.
//

import SwiftUI
import HealthKit
import UserNotifications
import WatchConnectivity
import WorkoutKit

class HealthKitManager: NSObject, ObservableObject {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    private var workoutBuilder: HKWorkoutBuilder?

    
    
    @Published var currentPace: Double = 0
    @Published var isHealthKitAvailable = false
    @Published var isAuthorized = false
    @Published var currentHeartRate: Double = 0
    @Published var currentDistance: Double = 0
    @Published var currentCalories: Double = 0
    @Published var isWorkoutActive = false
    @AppStorage("isHealthKitEnabled") private var isHealthKitEnabled = false
    
    private var heartRateQuery: HKQuery?
    private var distanceQuery: HKQuery?
    private var caloriesQuery: HKQuery?
    
    private let session: WCSession?
    
    override init() {
        if WCSession.isSupported() {
            self.session = WCSession.default
        } else {
            self.session = nil
        }
        
        super.init()
        session?.delegate = self
        session?.activate()
        checkAvailability()
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
    
    private func checkAvailability() {
        isHealthKitAvailable = HKHealthStore.isHealthDataAvailable()
        if isHealthKitAvailable && isHealthKitEnabled {
            Task {
                await requestAuthorization()
            }
        }
    }
    
    public func requestAuthorization() async {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.workoutType()
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            DispatchQueue.main.async {
                self.isAuthorized = true
            }
        } catch {
            print("Authorization failed: \(error)")
        }
    }
    
    func startWorkoutSession() {
        guard isAuthorized else { return }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor
        
        let startDate = Date()
        workoutBuilder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: nil)
        
        do {
            try workoutBuilder?.beginCollection(withStart: startDate) { success, error in
                if success {
                    DispatchQueue.main.async {
                        self.isWorkoutActive = true
                    }
                    self.startMonitoringWorkoutMetrics()
                } else if let error = error {
                    print("Failed to begin workout collection: \(error)")
                }
            }
        } catch {
            print("Failed to start workout session: \(error)")
        }
    }
    
    func startMonitoringWorkoutMetrics() {
        startHeartRateQuery()
        startDistanceQuery()
        startCaloriesQuery()
    }
    
    private func startHeartRateQuery() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] query, completion, error in
            guard error == nil else {
                print("Error monitoring heart rate: \(String(describing: error))")
                return
            }
            
            let heartRateQuery = HKStatisticsQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: nil,
                options: .discreteAverage
            ) { _, statistics, _ in
                DispatchQueue.main.async {
                    let heartRate = statistics?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) ?? 0
                    self?.currentHeartRate = heartRate
                }
            }
            
            self?.healthStore.execute(heartRateQuery)
        }
        
        healthStore.execute(query)
    }
    
    private func startDistanceQuery() {
        guard let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }
        
        let query = HKStatisticsCollectionQuery(
            quantityType: distanceType,
            quantitySamplePredicate: nil,
            options: .cumulativeSum,
            anchorDate: Date(),
            intervalComponents: DateComponents(second: 1)
        )
        
        query.initialResultsHandler = { [weak self] query, results, error in
            guard let statistics = results?.statistics().last else { return }
            DispatchQueue.main.async {
                self?.currentDistance = statistics.sumQuantity()?.doubleValue(for: HKUnit.meter()) ?? 0
            }
        }
        
        healthStore.execute(query)
    }
    
    private func startCaloriesQuery() {
        guard let caloriesType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let query = HKStatisticsCollectionQuery(
            quantityType: caloriesType,
            quantitySamplePredicate: nil,
            options: .cumulativeSum,
            anchorDate: Date(),
            intervalComponents: DateComponents(second: 1)
        )
        
        query.initialResultsHandler = { [weak self] query, results, error in
            guard let statistics = results?.statistics().last else { return }
            DispatchQueue.main.async {
                self?.currentCalories = statistics.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
            }
        }
        
        healthStore.execute(query)
    }
    
    func stopWorkoutSession() {
        guard let builder = workoutBuilder else { return }
        
        let endDate = Date()
        
        do {
            try builder.endCollection(withEnd: endDate) { success, error in
                if success {
                    builder.finishWorkout { workout, error in
                        if let error = error {
                            print("Error saving workout: \(error)")
                        } else {
                            print("Workout saved successfully")
                        }
                        
                        // Cleanup
                        [self.heartRateQuery, self.distanceQuery, self.caloriesQuery].forEach { query in
                            if let query = query {
                                self.healthStore.stop(query)
                            }
                        }
                        
                        self.heartRateQuery = nil
                        self.distanceQuery = nil
                        self.caloriesQuery = nil
                        self.workoutBuilder = nil
                        
                        DispatchQueue.main.async {
                            self.isWorkoutActive = false
                            self.currentHeartRate = 0
                            self.currentDistance = 0
                            self.currentCalories = 0
                        }
                    }
                }
            }
        } catch {
            print("Failed to end workout: \(error)")
        }
    }
    
    func fetchYearlyRunningStats(completion: @escaping (RunningStatistics) -> Void) {
        let workoutType = HKObjectType.workoutType()
        let calendar = Calendar.current
        let now = Date()
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
        
        let predicate = HKQuery.predicateForWorkouts(with: .running)
        let datePredicate = HKQuery.predicateForSamples(withStart: startOfYear, end: now, options: .strictStartDate)
        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, datePredicate])
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: workoutType, predicate: compound, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard let workouts = samples as? [HKWorkout], error == nil else {
                DispatchQueue.main.async {
                    print("Error fetching workouts: \(String(describing: error))")
                    let emptyStats = RunningStatistics(totalRuns: 0, totalDistance: 0, averagePace: 0)
                    completion(emptyStats)
                }
                return
            }
            
            let totalRuns = workouts.count
            let totalDistance = workouts.reduce(0.0) { $0 + ($1.totalDistance?.doubleValue(for: .meter()) ?? 0) }
            let totalTime = workouts.reduce(0.0) { $0 + $1.duration }
            
            let averagePace: Double
            if totalDistance > 0 {
                averagePace = totalTime / (totalDistance / 1000) / 60
            } else {
                averagePace = 0
            }
            
            DispatchQueue.main.async {
                let stats = RunningStatistics(
                    totalRuns: totalRuns,
                    totalDistance: totalDistance,
                    averagePace: averagePace
                )
                completion(stats)
            }
        }
        
        do {
            healthStore.execute(query)
        } catch {
            print("Error executing query: \(error)")
            let emptyStats = RunningStatistics(totalRuns: 0, totalDistance: 0, averagePace: 0)
            completion(emptyStats)
        }
    }
    
    func fetchRecentRuns(completion: @escaping ([RecentRun]) -> Void) {
        let workoutType = HKObjectType.workoutType()
        
        let predicate = HKQuery.predicateForWorkouts(with: .running)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(
            sampleType: workoutType,
            predicate: predicate,
            limit: 5,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            guard let workouts = samples as? [HKWorkout], error == nil else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            let recentRuns = workouts.map { workout in
                let duration = self.formatDuration(workout.duration)
                let distance = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
                let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                let pace = workout.duration / (distance / 1000) / 60
                
                return RecentRun(
                    date: workout.startDate,
                    distance: distance,
                    duration: duration,
                    calories: calories,
                    averagePace: pace
                )
            }
            
            DispatchQueue.main.async {
                completion(recentRuns)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        let seconds = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    func toggleHealthKit(isEnabled: Bool) {
        isHealthKitEnabled = isEnabled
        if isEnabled {
            checkAvailability()
        } else {
            isAuthorized = false
            stopWorkoutSession()
        }
    }
    
    func createWorkoutConfiguration(name: String, type: HKWorkoutActivityType, distance: Double, targetPace: Double) {
        guard isAuthorized else { return }
        
        // Create a future date for the workout (e.g., tomorrow at 9 AM)
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1  // Tomorrow
        components.hour = 9   // 9 AM
        components.minute = 0
        components.second = 0
        
        let startDate = calendar.date(from: components)!
        let estimatedDuration = distance * targetPace / 1000
        let endDate = startDate.addingTimeInterval(estimatedDuration)
        
        // Create the workout configuration
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = type
        configuration.locationType = .outdoor
        
        do {
            // Create the workout
            let workout = HKWorkout(
                activityType: type,
                start: startDate,
                end: endDate,
                duration: estimatedDuration,
                totalEnergyBurned: nil,
                totalDistance: HKQuantity(unit: .meter(), doubleValue: distance),
                device: nil,
                metadata: [
                    "com.apple.health.workout.scheduled": true,
                    "com.apple.health.workout.name": name,
                    "com.apple.health.workout.goal.type": "distance",
                    "com.apple.health.workout.goal.value": distance,
                    "com.apple.health.workout.target.pace": targetPace,
                    "com.apple.health.workout.template": true,
                    "com.apple.health.workout.template.source": Bundle.main.bundleIdentifier ?? "RunAI",
                    "com.apple.health.workout.template.time": startDate.timeIntervalSince1970
                ]
            )
            
            try healthStore.save(workout) { success, error in
                if success {
                    print("Workout scheduled successfully")
                    
                    // Schedule notification
                    let content = UNMutableNotificationContent()
                    content.title = "Scheduled Run: \(name)"
                    content.body = "Your \(String(format: "%.1f", distance/1000))km run is scheduled to start"
                    content.sound = .default
                    
                    let trigger = UNCalendarNotificationTrigger(
                        dateMatching: components,
                        repeats: false
                    )
                    
                    let request = UNNotificationRequest(
                        identifier: workout.uuid.uuidString,
                        content: content,
                        trigger: trigger
                    )
                    
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print("Error scheduling notification: \(error)")
                        }
                    }
                } else if let error = error {
                    print("Error scheduling workout: \(error)")
                }
            }
        } catch {
            print("Error creating workout: \(error)")
        }
    }
    
    func fetchWeeklyRuns(from startDate: Date, completion: @escaping ([RecentRun]) -> Void) {
        let workoutType = HKObjectType.workoutType()
        let endDate = Date()
        
        let predicate = HKQuery.predicateForWorkouts(with: .running)
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, datePredicate])
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(
            sampleType: workoutType,
            predicate: compound,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            guard let workouts = samples as? [HKWorkout], error == nil else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            let recentRuns = workouts.map { workout in
                let duration = self.formatDuration(workout.duration)
                let distance = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
                let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                let pace = workout.duration / (distance / 1000) / 60
                
                return RecentRun(
                    date: workout.startDate,
                    distance: distance,
                    duration: duration,
                    calories: calories,
                    averagePace: pace
                )
            }
            
            DispatchQueue.main.async {
                completion(recentRuns)
            }
        }
        
        healthStore.execute(query)
    }
}

// MARK: - WCSessionDelegate
extension HealthKitManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("Session activation failed: \(error.localizedDescription)")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Session became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate the session
        session.activate()
    }
}

