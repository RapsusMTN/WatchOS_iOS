//
//  HealthStoreContainer.swift
//  OneWatch
//
//  Created by jmartin on 05/02/2020.
//  Copyright © 2020 jmartin. All rights reserved.
//

import HealthKit

protocol HealthStoreContainer: AnyObject {
    var healthStore: HKHealthStore! { get set }
}
