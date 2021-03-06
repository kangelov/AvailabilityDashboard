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
    
    var services: [Service] = [] {
        didSet {
            services.sortInPlace({ (a: Service, b: Service) -> Bool in return a.name < b.name })
        }
    }
    
    var selectedService: Service?
    var selectedServiceName: String?
    
    override func updateViewForRefresh(path: [BaseController], envList: [Environment]) {
        print("ServicesViewController.updateViewForRefresh")
        if let envController = path[0] as? EnvironmentViewController {
            envController.lastFetchDate = self.lastFetchDate
            envController.lastUpdate = self.lastUpdate
            envController.updateStatusBarButton()
            envController.updateViewForRefresh(path, envList: envList)
            if let selectedEnv = envController.selectedEnvironment {
            envController.handleSelection(self)
                self.selectedService = nil
                for s in selectedEnv.services {
                    if s.name == selectedServiceName {
                        self.selectedService = s as? Service
                    }
                }
                if self.selectedService == nil && self.selectedServiceName != nil {
                    self.selectedServiceName = nil
                    let alert: UIAlertView = UIAlertView(title: "Cannot refresh services.", message: "Selected service is no longer available.", delegate: nil,cancelButtonTitle: "Dismiss")
                    alert.show()
                    self.navigationController?.popToViewController(envController, animated: true)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        print("ServicesViewController.viewDidLoad")
        super.viewDidLoad()
        super.updateStatusBarButton()
    }
    
    override func viewDidAppear(animated: Bool) {
        self.selectedService = nil
        self.selectedServiceName = nil
    }
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showNodes" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let object = services[indexPath.row] as Service
                let controller = segue.destinationViewController as! NodesViewController
                self.selectedService = object
                self.selectedServiceName = object.name
                handleSelection(controller)
            }
        }
    }
    
    override func handleSelection(controller: BaseController) {
        if let destController = controller as? NodesViewController {
            super.populateForSegue(controller)
            destController.nodes = []
            destController.service = self.selectedService
            for n in self.selectedService!.nodes {
                destController.nodes.append(n as! Node);
                destController.tableView.reloadData()
                destController.tableView.setNeedsDisplay()
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
            cell = tableView.dequeueReusableCellWithIdentifier("WrongServiceItem", forIndexPath: indexPath)
        case "OK":
            cell = tableView.dequeueReusableCellWithIdentifier("OKServiceItem", forIndexPath: indexPath)
        case "FAILED":
            cell = tableView.dequeueReusableCellWithIdentifier("FailedServiceItem", forIndexPath: indexPath)
        default:
            cell = tableView.dequeueReusableCellWithIdentifier("UnknownServiceItem", forIndexPath: indexPath)
        }
        
        cell.textLabel!.text = service.name
        return cell
        
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }

}
