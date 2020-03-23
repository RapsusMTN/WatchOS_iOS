//
//  InterfaceController.swift
//  WatchConnectivityTest WatchKit Extension
//
//  Created by jmartin on 05/02/2020.
//  Copyright © 2020 jmartin. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity
import HealthKit


class InterfaceController: WKInterfaceController {
    
    var healthStore = HKHealthStore()

    var wcSession : WCSession!
    
    var session: HKWorkoutSession?
    
    var builder: HKLiveWorkoutBuilder?
    
    @IBOutlet weak var timer: WKInterfaceTimer!
    
    @IBOutlet weak var receivedTextLabelñ: WKInterfaceLabel!
    
    @IBOutlet weak var heartIconLabel: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        
    }
    
    override func willActivate() {
        super.willActivate()
        
        wcSession = WCSession.default
        wcSession.delegate = self
        wcSession.activate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()

    }
     
    private func createWorkoutSession() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .cycling
        configuration.locationType = .outdoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            // Handle failure here.
            return
        }
        
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
        workoutConfiguration: configuration)
        
        session?.delegate = self
        builder?.delegate = self
        
        session?.startActivity(with: Date())
        builder?.beginCollection(withStart: Date(), completion: { (success, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            if success {
                print("ACTIVITY BEGINS!!!")
            }
        })
    }
    
    private func finishWorkout() {
        session?.end()
        builder?.endCollection(withEnd: Date(), completion: { (success, error) in
            self.builder?.finishWorkout(completion: { (workout, error) in
                if let error = error {
                    print(error.localizedDescription)
                }
                
                print("WORKOUT FINISHED!!")
                print(workout)
            })
        })
    }
    
    // MARK: -Action
    @IBAction func startWorkout() {
        print("START")
        timer.start()
        createWorkoutSession()
    }
    
    @IBAction func stopWorkout() {
        print("FINISH")
        timer.stop()
        finishWorkout()
    }
    
    
}

extension InterfaceController: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        let text = message["message"] as! String
        
        receivedTextLabelñ.setText(text)
    }
}

extension InterfaceController: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print(toState.rawValue)
        print("FROM STATE\(fromState.rawValue)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        
    }
 
}

extension InterfaceController: HKLiveWorkoutBuilderDelegate {
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
            print(collectedTypes)
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate), let calories = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned), let bikeDistance = HKQuantityType.quantityType(forIdentifier: .distanceCycling) else { return }
        
        if collectedTypes.contains(heartRateType) {
            let statics = workoutBuilder.statistics(for: heartRateType)
            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let value = statics?.mostRecentQuantity()?.doubleValue(for: heartRateUnit)
            let roundedValue = Double( round( 1 * value! ) / 1 )
            
            let message = ["heart_rate_bpm":roundedValue]
            
            wcSession.sendMessage(message, replyHandler: nil) { (error) in
                
                print(error.localizedDescription)
                
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.receivedTextLabelñ.setText("\(Int(roundedValue))")
            }
        } else if collectedTypes.contains(calories) {
            let statics = workoutBuilder.statistics(for: calories)
            let caloriesUnit = HKUnit.joule()
            let value = statics?.mostRecentQuantity()?.doubleValue(for: caloriesUnit)
            let roundedValue = Double( round( 1 * value! ) / 1 )
            let message = ["calories": roundedValue]
            
            wcSession.sendMessage(message, replyHandler: nil) { (error) in
                print(error.localizedDescription)
            }
        } else if collectedTypes.contains(bikeDistance) {
            let statics = workoutBuilder.statistics(for: bikeDistance)
            let distanceUnit = HKUnit.meter()
            let value = statics?.mostRecentQuantity()?.doubleValue(for: distanceUnit)
            let roundedValue = Double( round( 1 * value! ) / 1 )
            let message = ["bike_distance": roundedValue]
            
            wcSession.sendMessage(message, replyHandler: nil) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        let timerDate = Date(timeInterval: -self.builder!.elapsedTime, since: Date())
        DispatchQueue.main.async { [weak self] in
            self?.timer.setDate(timerDate)
        }
    }
}
