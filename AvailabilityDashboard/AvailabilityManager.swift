//
//  AvailabilityRepository.swift
//  AvailabilityDashboard
//
//  Created by Kamen Angelov on 2015-05-15.
//  Copyright (c) 2015 Kamen Angelov. All rights reserved.
//

import Foundation
import CoreData
import Alamofire
import SwiftyJSON

let AvailabilityChangedNotification = "AvailabilityChangedNotification"

class AvailabilityManager {
    
    let managedObjectContext : NSManagedObjectContext
    
    let saveContext : () -> Void
    
    init(managedObjectContext : NSManagedObjectContext, saveContext : () -> Void) {
        self.managedObjectContext = managedObjectContext
        self.saveContext = saveContext
    }
    
    func refreshAvailability(delegate: AvailabilityManagerDelegate?, deviceToken: NSData?) {
        let defaults = NSUserDefaults.standardUserDefaults()
        let url = defaults.stringForKey("url") as String!
//        if (deviceToken != nil) {
//            url = url + "?token=\(deviceToken!)"
//        }
        let user = defaults.stringForKey("user") as String!
        let pass = defaults.stringForKey("password") as String!
        NSLog("About to call backend at \(url)")
        if url != nil {
            NSURLCache.sharedURLCache().removeAllCachedResponses()
            var request = Alamofire.request(.GET, url, parameters: nil, encoding: .JSON)
            if (user != nil && !user.isEmpty && pass != nil && !pass.isEmpty) {
                request = request.authenticate(user: user, password: pass)
            }
            request.responseJSON { request, response, result in
                    if(result.error != nil) {
                        NSLog("Error: \(result.error)")
                        NSLog("REQUEST: \(request)")
                        NSLog("RESPONSE: \(response)")
                        delegate?.refreshError(self, error: result.error!)
                    }
                    else {
                        //NSLog("Success: \(json)")
                        self.updateCoreData(JSON(result.value!))
                        delegate?.refreshSuccess(self)
                    }
            }
        } else {
            let error = NSError(domain: "Invalid source URL. Please go into Settings and configure a valid URL.", code: -1, userInfo: nil)
            delegate?.refreshError(self, error: error);
        }
    }
    
    private func updateCoreData(json: JSON) {
        for (key, subJSON) in json {
            if (key == "environments") {
                //Clear stale environments
                let request = NSFetchRequest(entityName: "Environment")
                if let storedEnvironments = try! self.managedObjectContext.executeFetchRequest(request) as? [Environment] {
                    for env in storedEnvironments {
                        self.managedObjectContext.deleteObject(env)
                    }
                }
                //Clear stale metadata
                let metadataRequest = NSFetchRequest(entityName: "Metadata")
                if let storedMetadata = try! self.managedObjectContext.executeFetchRequest(metadataRequest) as? [Metadata] {
                    for m in storedMetadata {
                        self.managedObjectContext.deleteObject(m)
                    }
                }
                //Need something to clear CoreStorage
                for(_, envJSON) in subJSON {
                    let newenv = NSEntityDescription.insertNewObjectForEntityForName("Environment", inManagedObjectContext: self.managedObjectContext) as! Environment
                    print(envJSON["name"].stringValue)
                    newenv.name = envJSON["name"].stringValue
                    newenv.status = envJSON["status"].stringValue
                    newenv.services = NSOrderedSet(array: getServiceList(envJSON))
                }
                let metadata = NSEntityDescription.insertNewObjectForEntityForName("Metadata", inManagedObjectContext: self.managedObjectContext) as! Metadata
                metadata.lastFetchTime = NSDate()
                metadata.lastUpdateTime = getLastUpdateDate(json)!
                self.saveContext()
            }
        }
    }
    
    func getEnvironmentList() -> [Environment]? {
        let request = NSFetchRequest(entityName: "Environment")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        if let storedEnvironments = try! self.managedObjectContext.executeFetchRequest(request) as? [Environment] {
            return storedEnvironments
        }
        return nil
    }
    
    func getLastUpdateTime() -> NSDate? {
        let request = NSFetchRequest(entityName: "Metadata")
        if let storedMetadata = try! self.managedObjectContext.executeFetchRequest(request) as? [Metadata] {
            if storedMetadata.count == 1 {
                return storedMetadata[0].lastUpdateTime
            }
        }
        return nil
    }

    func getLastFetchTime() -> NSDate? {
        let request = NSFetchRequest(entityName: "Metadata")
        if let storedMetadata = try! self.managedObjectContext.executeFetchRequest(request) as? [Metadata] {
            if storedMetadata.count == 1 {
                return storedMetadata[0].lastFetchTime
            }
        }
        return nil
    }
    
    private func getServiceList(envJSON: JSON) -> [Service] {
        var serviceList : [Service] = []
        for (_, servJSON) in envJSON["services"] {
            let newserv = NSEntityDescription.insertNewObjectForEntityForName("Service", inManagedObjectContext: self.managedObjectContext) as! Service
            newserv.name = servJSON["name"].stringValue
            newserv.status = servJSON["status"].stringValue
            newserv.nodes = NSOrderedSet(array: getNodeList(servJSON))
            serviceList.append(newserv)
        }
        return serviceList
    }
    
    private func getNodeList(servJSON: JSON) -> [Node] {
        var nodeList : [Node] = []
        for (_, nodeJSON) in servJSON["nodes"] {
            let newnode = NSEntityDescription.insertNewObjectForEntityForName("Node", inManagedObjectContext: self.managedObjectContext) as! Node
            newnode.name = nodeJSON["name"].stringValue
            newnode.status = nodeJSON["status"].stringValue
            newnode.version = nodeJSON["version"].stringValue
            newnode.response = nodeJSON["response"].stringValue
            nodeList.append(newnode)
        }
        return nodeList
    }
    
    private func getLastUpdateDate(json: JSON) -> NSDate? {
        for (key, subJSON) in json {
            if key == "updateTime" {
                return NSDate(timeIntervalSince1970: subJSON.doubleValue / 1000)
            }
        }
        return nil
    }
    
}

protocol AvailabilityManagerDelegate {
    
    func refreshSuccess(manager: AvailabilityManager)
    
    func refreshError(manager: AvailabilityManager, error: ErrorType)

}