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
    
    var environments: [Environment] = []
    
    var environment: Environment?
    
    override func updateViewForRefresh(path: [BaseController], envList: [Environment]) {
        self.environments = envList
        if let selectedEnv = environment {
            self.environment = nil
            for env in envList {
                if env.name == selectedEnv.name {
                    self.environment = env
                }
            }
            if self.environment == nil {
                var alert: UIAlertView = UIAlertView(title: "Cannot refresh environments.", message: "Selected environment is no longer available.", delegate: nil, cancelButtonTitle: "Dismiss")
                alert.show()
            }
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (environments.isEmpty) {
            if let availabilityManager = (UIApplication.sharedApplication().delegate as! AppDelegate).availabilityManager {
                availabilityManager.refreshAvailability(self)
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        self.environment = nil
    }

    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showServices" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                let object = environments[indexPath.row] as Environment
                let controller = segue.destinationViewController as! ServicesViewController
                self.environment = object
                handleSelection(controller)
            }
        }
    }
    
    override func handleSelection(controller: BaseController) {
        if let destController = controller as? ServicesViewController {
            destController.services = []
            for s in self.environment!.services {
                destController.services.append(s as! Service);
            }
            super.populateForSegue(destController)
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
                cell = tableView.dequeueReusableCellWithIdentifier("WrongEnvironmentItem", forIndexPath: indexPath) as! UITableViewCell
            case "OK":
                cell = tableView.dequeueReusableCellWithIdentifier("OKEnvironmentItem", forIndexPath: indexPath) as! UITableViewCell
            case "FAILED":
                cell = tableView.dequeueReusableCellWithIdentifier("FailedEnvironmentItem", forIndexPath: indexPath) as! UITableViewCell
            default:
                cell = tableView.dequeueReusableCellWithIdentifier("UnknownEnvironmentItem", forIndexPath: indexPath) as! UITableViewCell
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
