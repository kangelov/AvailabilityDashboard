//
//  ServicesViewController.swift
//  AvailabilityDashboard
//
//  Created by Kamen Angelov on 2015-05-13.
//  Copyright (c) 2015 Kamen Angelov. All rights reserved.
//

import Foundation
import UIKit

class ServicesViewController: BaseController {
    
    var nodesViewController: NodesViewController? = nil
    
    var services: [Service] = []
    
    var service: Service?
    
    override func updateViewForRefresh(path: [BaseController], envList: [Environment]) {
        if let envController = path[0] as? EnvironmentViewController {
            envController.updateViewForRefresh(path, envList: envList)
            if let selectedEnv = envController.environment {
                envController.handleSelection(self)
                if let selectedService = self.service {
                    self.service = nil
                    for s in selectedEnv.services {
                        if s.name == selectedService.name {
                            self.service = s as! Service
                        }
                    }
                    if self.service == nil {
                        var alert: UIAlertView = UIAlertView(title: "Cannot refresh services.", message: "Selected service is no longer available.", delegate: nil, cancelButtonTitle: "Dismiss")
                        alert.show()
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        super.updateStatusBarButton()
    }
    
    override func viewDidAppear(animated: Bool) {
        self.service = nil
    }
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showNodes" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                let object = services[indexPath.row] as Service
                let controller = segue.destinationViewController as! NodesViewController
                self.service = object
                handleSelection(controller)
            }
        }
    }
    
    override func handleSelection(controller: BaseController) {
        if let destController = controller as? NodesViewController {
            destController.nodes = []
            destController.service = self.service
            for n in self.service!.nodes {
                destController.nodes.append(n as! Node);
            }
            super.populateForSegue(controller)
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
