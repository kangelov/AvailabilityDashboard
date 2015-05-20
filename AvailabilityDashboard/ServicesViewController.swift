//
//  ServicesViewController.swift
//  AvailabilityDashboard
//
//  Created by Kamen Angelov on 2015-05-13.
//  Copyright (c) 2015 Kamen Angelov. All rights reserved.
//

import Foundation
import UIKit

class ServicesViewController: UITableViewController {
    
    var nodesViewController: NodesViewController? = nil
    
    var services: [Service] = []
    

    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showNodes" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                let object = services[indexPath.row] as Service
                let controller = segue.destinationViewController as! NodesViewController
                controller.service = object
                controller.nodes = []
                for n in object.nodes {
                    controller.nodes.append(n as! Node);
                }
            }
        }
    }
    
    // MARK: - Table View
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 70
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let service = services[indexPath.row] as Service
        var cell: UITableViewCell
        switch service.status {
        case "WRONG_VERSION":
            cell = tableView.dequeueReusableCellWithIdentifier("WrongServiceItem", forIndexPath: indexPath) as! UITableViewCell
        case "OK":
            cell = tableView.dequeueReusableCellWithIdentifier("OKServiceItem", forIndexPath: indexPath) as! UITableViewCell
        case "FAILED":
            cell = tableView.dequeueReusableCellWithIdentifier("FailedServiceItem", forIndexPath: indexPath) as! UITableViewCell
        default:
            cell = tableView.dequeueReusableCellWithIdentifier("UnknownServiceItem", forIndexPath: indexPath) as! UITableViewCell
        }
        
        cell.textLabel!.text = service.name
        return cell
        
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }

}
