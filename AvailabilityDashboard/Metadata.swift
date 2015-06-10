//
//  Metadata.swift
//  AvailabilityDashboard
//
//  Created by Kamen Angelov on 2015-06-10.
//  Copyright (c) 2015 Kamen Angelov. All rights reserved.
//

import Foundation
import CoreData

class Metadata: NSManagedObject {

    @NSManaged var lastFetchTime: NSDate
    @NSManaged var lastUpdateTime: NSDate

}
