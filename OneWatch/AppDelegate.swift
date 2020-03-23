//
//  AppDelegate.swift
//  HealthKitTest
//
//  Created by jmartin on 22/01/2020.
//  Copyright © 2020 jmartin. All rights reserved.
//

import UIKit
import HealthKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    private let healthStore: HKHealthStore
    
    override init() {
        guard HKHealthStore.isHealthDataAvailable() else { fatalError("This app requires a device that supports HealthKit") }

        healthStore = HKHealthStore()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Enumerate the view controller hierarchy and set the health store where appropriate.
        window?.rootViewController?.enumerateHierarchy { viewController in
            guard let healthStoreContainer = viewController as? HealthStoreContainer else { return }
            healthStoreContainer.healthStore = healthStore
        }
        
        // The quantity type to write to the health store.
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]
        
        // Create the heart rate and heartbeat type identifiers.
        let permissions = Set([HKObjectType.workoutType(),
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .distanceCycling)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!])
        
        // Request permission to read and write heart rate and heartbeat data.
        healthStore.requestAuthorization(toShare: typesToShare, read: permissions) { (success, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            
            print("PERMISSIONS GRANTED!!")
        }
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

extension UIViewController {
    // Executes the provided closure on the current view controller
    // and on all of its descendants in the view controller hierarchy.
    func enumerateHierarchy(_ closure: (UIViewController) -> Void) {
        closure(self)
        
        for child in children {
            child.enumerateHierarchy(closure)
        }
    }
}

