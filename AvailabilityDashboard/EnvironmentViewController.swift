//
//  EnvironmentController.swift
//  AvailabilityDashboard
//
//  Created by Kamen Angelov on 2015-05-12.
//  Copyright (c) 2015 Kamen Angelov. All rights reserved.
//

import UIKit

class EnvironmentViewController: UITableViewController, AvailabilityManagerDelegate {
    
    
    var serviceViewController: ServicesViewController? = nil
    
    var environments: [Environment] = []
    var lastUpdate: NSDate?
    var lastFetchDate: NSDate?
    
    @IBAction func logoButtonAction(sender: AnyObject) {
        (UIApplication.sharedApplication()).openURL(NSURL(string: "http://www.qualicom.com")!)
    }
    
    func refreshSuccess(manager: AvailabilityManager) {
        if let envList = manager.getEnvironmentList() {
            environments = envList
            self.tableView.reloadData()
            self.tableView.setNeedsDisplay()
        }
        if let lastUpdate = manager.getLastUpdateDate() {
            self.lastUpdate = lastUpdate
        }
        if let lastFetchDate = manager.getLastFetchTime() {
            self.lastFetchDate = lastFetchDate
        }
        self.refreshControl?.endRefreshing()
    }
    
    func refreshError(error: NSError?) {
        self.refreshControl?.endRefreshing()
        var alert: UIAlertView = UIAlertView(title: "Error Fetching Availability Data", message: error?.localizedDescription, delegate: nil, cancelButtonTitle: "Dismiss")
        alert.show()
    }
    
    override func viewDidLoad() {
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: "availabilityChanged:", name: AvailabilityChangedNotification, object: nil)

        self.refreshControl = UIRefreshControl()
        self.refreshControl?.backgroundColor = UIColor.groupTableViewBackgroundColor()
//        self.refreshControl?.attributedTitle = NSAttributedString(string: getLastUpdateDate(self.lastUpdate))
        self.refreshControl?.addTarget(self, action: "handleRefresh:", forControlEvents: UIControlEvents.ValueChanged)
        
        if (environments.isEmpty) {
            if let availabilityManager = (UIApplication.sharedApplication().delegate as! AppDelegate).availabilityManager {
                availabilityManager.refreshAvailability(self)
            }
        }
    }
    
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
        if segue.identifier == "showServices" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                let object = environments[indexPath.row] as Environment
                let controller = segue.destinationViewController as! ServicesViewController
                controller.services = []
                for s in object.services {
                    controller.services.append(s as! Service);
                }
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
        }
        tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return environments.count + 1
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == environments.count {
            return 50
        }
        return 70
    }
    
    func getLastFetchDate(lastUpdate: NSDate?) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("yyyy-MM-dd HH:mm:ss zzz")
        var lastFetchDate = "Last Fetch: "
        if let lastFetch = self.lastFetchDate {
            lastFetchDate += dateFormatter.stringFromDate(lastFetch)
        }
        return lastFetchDate
    }

    func getLastUpdateDate(lastUpdate: NSDate?) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("yyyy-MM-dd HH:mm:ss zzz")
        var lastUpdateDate = "Data As Of: "
        if let lastUpdate = self.lastUpdate {
            lastUpdateDate += dateFormatter.stringFromDate(lastUpdate)
        }
        return lastUpdateDate
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        if indexPath.row == environments.count {
            cell = tableView.dequeueReusableCellWithIdentifier("Footer", forIndexPath: indexPath) as! UITableViewCell
            cell.textLabel?.text = getLastUpdateDate(lastUpdate)
            cell.detailTextLabel?.text = getLastFetchDate(lastFetchDate)
        } else {
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
        }
        return cell
        
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }

    func handleRefresh(sender: AnyObject) {
        if let availabilityManager = (UIApplication.sharedApplication().delegate as! AppDelegate).availabilityManager {
            availabilityManager.forceRefreshAvailability(self)
        }
    }
    
    func availabilityChanged(notification: NSNotification) {
        if let availabilityManager = notification.object as? AvailabilityManager {
            availabilityManager.refreshAvailability(self)
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}
