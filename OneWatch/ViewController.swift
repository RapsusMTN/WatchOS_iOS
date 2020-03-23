//
//  ViewController.swift
//  OneWatch
//
//  Created by jmartin on 05/02/2020.
//  Copyright © 2020 jmartin. All rights reserved.
//

import UIKit
import HealthKit
import WatchConnectivity

class ViewController: UIViewController {
    
    var healthStore: HKHealthStore = HKHealthStore()
    
    var query: HKObserverQuery?
    
    var wcSession : WCSession! = nil

    var builder: HKWorkoutBuilder?
    
    @IBOutlet weak var bpmLabel: UILabel!
    
    @IBOutlet weak var caloriesLabel: UILabel!
    
    @IBOutlet weak var bikeDistance: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        wcSession = WCSession.default
        wcSession.delegate = self
        wcSession.activate()
        
        if wcSession.isPaired {
            print("APPLE WATCH IS PAIRED")
        } else {
            print("APPLE WATCH DOESNT PAIRED")
        }
    }

    private func observeValues() {
        guard let sample = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        self.query = HKObserverQuery(sampleType: sample, predicate: nil) { [weak self] (query, completion, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            self?.readLatestValue(completion: { (sample) in
                guard let sample = sample else { return }
                
                DispatchQueue.main.async {
                    let heartRateUnit = HKUnit(from: "count/min")
                    let heartRate = sample
                    .quantity
                    .doubleValue(for: heartRateUnit)
                    
                    self?.bpmLabel.text = "\(Int(heartRate))"
                }
            })
        }
        guard let query = self.query else { return }
        self.healthStore.execute(query)
    }
    
    private func readLatestValue(completion: @escaping(HKQuantitySample?) -> Void) {
        
        guard let sampleType = HKObjectType
          .quantityType(forIdentifier: .heartRate) else {
            completion(nil)
          return
        }
        
        let query = HKSampleQuery(sampleType: sampleType, predicate: nil, limit: Int(HKObjectQueryNoLimit), sortDescriptors: nil) { (query, samples, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            completion(samples?.last as? HKQuantitySample)
            print(samples)
        }
        
        self.healthStore.execute(query)
    }
    
    private func createWorkout() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .cycling
        configuration.locationType = .outdoor
        
        builder = HKWorkoutBuilder(healthStore: self.healthStore, configuration: configuration, device: .local())
        
        builder?.beginCollection(withStart: Date(), completion: { (success, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            
            print("COLLECTION BEGINNIG!!!")
            
            guard let sampleType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
            
        })
    }
    
    private func sampleQuery() {
        var dateComponents = DateComponents()
        dateComponents.year = 2019
        dateComponents.day = 7
        dateComponents.month = 2
        dateComponents.hour = 9
        dateComponents.minute = 10
        
        let calendar = NSCalendar.current
        
        guard let startDate = calendar.date(from: dateComponents) else { return }
    
        guard let sampleType = HKSampleType.quantityType(forIdentifier: .heartRate) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: [])
        
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: 20, sortDescriptors: nil) { (query, results, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            
            guard let samples = results as? [HKQuantitySample] else { return }
            
            for sample in samples {
                print(sample)
            }
            
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Action Selector
    @IBAction func startTapped(_ sender: Any) {
        observeValues()
    }
    
    @IBAction func startWorkoutBuilder(_ sender: Any) {
        createWorkout()
    }
    
    @IBAction func executeQuery(_ sender: Any) {
        sampleQuery()
    }
    
}

extension ViewController: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print(activationState.rawValue)
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let bpms = message["heart_rate_bpm"] as? Double {
            DispatchQueue.main.async { [weak self] in
                self?.bpmLabel.text = "\(Int(bpms))"
            }
        }
        
        if let calories = message["calories"] as? Double {
            DispatchQueue.main.async { [weak self] in
                self?.caloriesLabel.text = "\(Int(calories))"
            }
        }
        
        if let bikeDistance = message["bike_distance"] as? Double {
            DispatchQueue.main.async { [weak self] in
                self?.bikeDistance.text = "\(Int(bikeDistance))"
            }
        }
        
        
    }
}
