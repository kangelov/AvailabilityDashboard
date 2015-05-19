//
//  Node.swift
//  AvailabilityDashboard
//
//  Created by Kamen Angelov on 2015-05-14.
//  Copyright (c) 2015 Kamen Angelov. All rights reserved.
//

import Foundation
import CoreData

class Node: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var version: String
    @NSManaged var status: String
    @NSManaged var response: String

}
