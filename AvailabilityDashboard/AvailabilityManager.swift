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
    
    var json : JSON? = nil
    
    var lastFetchTime : NSDate? = nil {
        didSet{
            postDataChanged()
        }
    }
    
    init(managedObjectContext : NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }
    
    func refreshAvailability(delegate : AvailabilityManagerDelegate?) {
        //We should have a better logic here to decide when to refresh
        if (json == nil) {
            forceRefreshAvailability(delegate)
        } else {
            delegate?.refreshSuccess(self)
        }
    }
    
    func forceRefreshAvailability(delegate: AvailabilityManagerDelegate?) {
        let defaults = NSUserDefaults.standardUserDefaults()
        let url = defaults.stringForKey("url") as String!
        NSLog("About to call backend at \(url)")
        if url != nil {
            NSURLCache.sharedURLCache().removeAllCachedResponses()
            Alamofire.request(.GET, url, parameters: nil, encoding: .JSON)
                .responseJSON { (req, res, json, error) in
                    if(error != nil) {
                        NSLog("Error: \(error)")
                        NSLog("REQUEST: \(req)")
                        NSLog("RESPONSE: \(res)")
                        self.json = nil
                        delegate?.refreshError(self, error: error)
                    }
                    else {
                        //NSLog("Success: \(json)")
                        self.json = JSON(json!)
                        self.lastFetchTime = NSDate()
                        delegate?.refreshSuccess(self)
                    }
            }
        } else {
            var error = NSError(domain: "Invalid source URL. Please go into Settings and configure a valid URL.", code: -1, userInfo: nil)
            delegate?.refreshError(self, error: error);
        }
    }
    
    func needsRefresh() -> Bool {
        return json == nil
    }
    
    func getEnvironmentList() -> [Environment]? {
        if self.json == nil {
            return nil
        }
        var environments : [Environment] = []
        for (key: String, subJSON: JSON) in self.json! {
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
                if let metadata = self.managedObjectContext.executeFetchRequest(request, error:nil) as? [Metadata] {
                    for m in metadata {
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
                    environments.append(newenv)
                }
                let metadata = NSEntityDescription.insertNewObjectForEntityForName("Metadata", inManagedObjectContext: self.managedObjectContext) as! Metadata
                metadata.lastFetchTime = self.lastFetchTime!
                metadata.lastUpdateTime = getLastUpdateDate()!
                self.managedObjectContext.save(nil)
            }
        }
        return environments
    }
    
    func getStoredEnvironmentList() -> [Environment]? {
        let request = NSFetchRequest(entityName: "Environment")
        if let storedEnvironments = self.managedObjectContext.executeFetchRequest(request, error: nil) as? [Environment] {
            return storedEnvironments
        }
        return nil
    }
    
    func getStoredLastUpdateTime() -> NSDate? {
        let request = NSFetchRequest(entityName: "Metadata")
        if let storedMetadata = self.managedObjectContext.executeFetchRequest(request, error: nil) as? [Metadata] {
            if (storedMetadata.count == 1) {
                return storedMetadata[0].lastUpdateTime
            }
        }
        return nil
    }

    func getStoredLastFetchTime() -> NSDate? {
        let request = NSFetchRequest(entityName: "Metadata")
        if let storedMetadata = self.managedObjectContext.executeFetchRequest(request, error: nil) as? [Metadata] {
            if (storedMetadata.count == 1) {
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
    
    func getLastUpdateDate() -> NSDate? {
        if self.json == nil {
            return nil
        }
        for (key: String, subJSON: JSON) in self.json! {
            if key == "updateTime" {
                return NSDate(timeIntervalSince1970: subJSON.doubleValue / 1000)
            }
        }
        return nil
    }
    
    func getLastFetchTime() -> NSDate? {
        return self.lastFetchTime
    }
    
    func postDataChanged() {
        let center = NSNotificationCenter.defaultCenter()
        center.postNotificationName(AvailabilityChangedNotification, object: self)
    }
    
}

protocol AvailabilityManagerDelegate {
    
    func refreshSuccess(manager: AvailabilityManager)
    
    func refreshError(manager: AvailabilityManager, error: NSError?)

}