//
//  EnvironmentController.swift
//  AvailabilityDashboard
//
//  Created by Kamen Angelov on 2015-05-12.
//  Copyright (c) 2015 Kamen Angelov. All rights reserved.
//

import UIKit

class EnvironmentViewController: BaseController {
    
    
    var serviceViewController: ServicesViewController? = nil
    
    var environments: [Environment] = [] {
        didSet {
            environments.sortInPlace({ (a: Environment, b: Environment) -> Bool in return a.name < b.name })
        }
    }
    
    var didShowSplash : Bool = false
    
    //CoreData yanks any object that has been deleted from the database, 
    //so I have to copy the key out in order to find it again after a refresh.
    var selectedEnvironmentName: String?
    var selectedEnvironment: Environment?
    
    override func updateViewForRefresh(path: [BaseController], envList: [Environment]) {
        print("EnvironmentViewController.updateViewForRefresh")
        self.environments = envList
        self.tableView.reloadData()
        self.tableView.setNeedsDisplay()
        self.selectedEnvironment = nil
        for env in envList {
            if env.name == selectedEnvironmentName {
                self.selectedEnvironment = env
            }
        }
        if self.selectedEnvironment == nil && self.selectedEnvironmentName != nil {
            self.selectedEnvironmentName = nil
            let alert: UIAlertView = UIAlertView(title: "Cannot refresh environments.", message: "Selected environment is no longer available.", delegate: nil, cancelButtonTitle: "Dismiss")
            alert.show()
            self.navigationController?.popToViewController(self, animated: true)
        }
    }

    
    override func viewDidLoad() {
        print("EnvironmentViewController.viewDidLoad")
        
        super.viewDidLoad()
        
        if (environments.isEmpty) {
            //In case of no data, read the stale response if there is one, then force a refresh.
            if let availabilityManager = (UIApplication.sharedApplication().delegate as! AppDelegate).availabilityManager {
                if let envList = availabilityManager.getEnvironmentList() {
                    if envList.count > 0 {
                        updateViewForRefresh(path, envList: envList)
                    }
                    
                    if let lastUpdate = availabilityManager.getLastUpdateTime() {
                        self.lastUpdate = lastUpdate
                    }
                    if let lastFetchDate = availabilityManager.getLastFetchTime() {
                        self.lastFetchDate = lastFetchDate
                    }
                }
                self.updateStatusBarButton()
                availabilityManager.refreshAvailability(self, deviceToken: (UIApplication.sharedApplication().delegate as! AppDelegate).deviceToken)
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        self.selectedEnvironment = nil
        self.selectedEnvironmentName = nil
        
        if (!didShowSplash) {
            let splash = storyboard!.instantiateViewControllerWithIdentifier("Splash") as UIViewController
            self.presentViewController(splash, animated: false, completion: nil)
            didShowSplash = true
        }
    }

    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showServices" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let object = environments[indexPath.row] as Environment
                let controller = segue.destinationViewController as! ServicesViewController
                self.selectedEnvironment = object
                self.selectedEnvironmentName = object.name
                handleSelection(controller)
            }
        }
    }
    
    override func handleSelection(controller: BaseController) {
        if let destController = controller as? ServicesViewController {
            super.populateForSegue(destController)
            destController.services = []
            for s in self.selectedEnvironment!.services {
                destController.services.append(s as! Service);
                destController.tableView.reloadData()
                destController.tableView.setNeedsDisplay()
            }
        }
    }
    
    // MARK: - Table View
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if environments.count == 0 {
            let emptyTableMessage = UILabel(frame: CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height))
            emptyTableMessage.text = "No data is available. Please pull down to refresh."
            emptyTableMessage.textColor = UIColor.blackColor()
            emptyTableMessage.textAlignment = NSTextAlignment.Center
            emptyTableMessage.numberOfLines = 0
            emptyTableMessage.font = UIFont(name: "Palatino-Italic", size: 20)
            emptyTableMessage.sizeToFit()
            tableView.backgroundView = emptyTableMessage
            tableView.separatorStyle = UITableViewCellSeparatorStyle.None
            return 0
        } else {
            tableView.backgroundView = nil
        }
        tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return environments.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell
            let env = environments[indexPath.row] as Environment
            switch env.status {
            case "WRONG_VERSION":
                cell = tableView.dequeueReusableCellWithIdentifier("WrongEnvironmentItem", forIndexPath: indexPath)
            case "OK":
                cell = tableView.dequeueReusableCellWithIdentifier("OKEnvironmentItem", forIndexPath: indexPath)
            case "FAILED":
                cell = tableView.dequeueReusableCellWithIdentifier("FailedEnvironmentItem", forIndexPath: indexPath)
            default:
                cell = tableView.dequeueReusableCellWithIdentifier("UnknownEnvironmentItem", forIndexPath: indexPath)
            }
            cell.textLabel!.text = env.name
            //        cell.detailTextLabel!.text = env.status
        return cell
        
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
    
}
