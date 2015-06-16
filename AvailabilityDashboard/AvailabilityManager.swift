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
    
    let deviceToken : NSData?
    
    init(managedObjectContext : NSManagedObjectContext, saveContext : () -> Void, deviceToken : NSData?) {
        self.managedObjectContext = managedObjectContext
        self.saveContext = saveContext
        self.deviceToken = deviceToken
    }
    
    func refreshAvailability(delegate: AvailabilityManagerDelegate?) {
        let defaults = NSUserDefaults.standardUserDefaults()
        var url = defaults.stringForKey("url") as String!
        if (deviceToken != nil) {
            url = url + "?token=\(deviceToken)"
        }
        let user = defaults.stringForKey("user") as String!
        let pass = defaults.stringForKey("password") as String!
        NSLog("About to call backend at \(url)")
        if url != nil {
            NSURLCache.sharedURLCache().removeAllCachedResponses()
            var request = Alamofire.request(.GET, url, parameters: nil, encoding: .JSON)
                .validate(statusCode: 200..<300)
                .validate(contentType: ["application/json"])
            if (user != nil && !user.isEmpty && pass != nil && !pass.isEmpty) {
                request = request.authenticate(user: user, password: pass)
            }
            request.responseJSON { (req, res, json, error) in
                    if(error != nil) {
                        NSLog("Error: \(error)")
                        NSLog("REQUEST: \(req)")
                        NSLog("RESPONSE: \(res)")
                        delegate?.refreshError(self, error: error)
                    }
                    else {
                        //NSLog("Success: \(json)")
                        self.updateCoreData(JSON(json!))
                        delegate?.refreshSuccess(self)
                    }
            }
        } else {
            var error = NSError(domain: "Invalid source URL. Please go into Settings and configure a valid URL.", code: -1, userInfo: nil)
            delegate?.refreshError(self, error: error);
        }
    }
    
    private func updateCoreData(json: JSON) {
        for (key: String, subJSON: JSON) in json {
            if (key == "environments") {
                //Clear stale environments
                let request = NSFetchRequest(entityName: "Environment")
                if let storedEnvironments = self.managedObjectContext.executeFetchRequest(request, error: nil) as? [Environment] {
                    for env in storedEnvironments {
                        self.managedObjectContext.deleteObject(env)
                    }
                }
                //Clear stale metadata
                let metadataRequest = NSFetchRequest(entityName: "Metadata")
                if let storedMetadata = self.managedObjectContext.executeFetchRequest(metadataRequest, error: nil) as? [Metadata] {
                    for m in storedMetadata {
                        self.managedObjectContext.deleteObject(m)
                    }
                }
                //Need something to clear CoreStorage
                for(env: String, envJSON: JSON) in subJSON {
                    let newenv = NSEntityDescription.insertNewObjectForEntityForName("Environment", inManagedObjectContext: self.managedObjectContext) as! Environment
                    println(envJSON["name"].stringValue)
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
        if let storedEnvironments = self.managedObjectContext.executeFetchRequest(request, error: nil) as? [Environment] {
            return storedEnvironments
        }
        return nil
    }
    
    func getLastUpdateTime() -> NSDate? {
        let request = NSFetchRequest(entityName: "Metadata")
        if let storedMetadata = self.managedObjectContext.executeFetchRequest(request, error: nil) as? [Metadata] {
            if storedMetadata.count == 1 {
                return storedMetadata[0].lastUpdateTime
            }
        }
        return nil
    }

    func getLastFetchTime() -> NSDate? {
        let request = NSFetchRequest(entityName: "Metadata")
        if let storedMetadata = self.managedObjectContext.executeFetchRequest(request, error: nil) as? [Metadata] {
            if storedMetadata.count == 1 {
                return storedMetadata[0].lastFetchTime
            }
        }
        return nil
    }
    
    private func getServiceList(envJSON: JSON) -> [Service] {
        var serviceList : [Service] = []
        for (serv: String, servJSON: JSON) in envJSON["services"] {
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
        for (node: String, nodeJSON: JSON) in servJSON["nodes"] {
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
        for (key: String, subJSON: JSON) in json {
            if key == "updateTime" {
                return NSDate(timeIntervalSince1970: subJSON.doubleValue / 1000)
            }
        }
        return nil
    }
    
}

protocol AvailabilityManagerDelegate {
    
    func refreshSuccess(manager: AvailabilityManager)
    
    func refreshError(manager: AvailabilityManager, error: NSError?)

}