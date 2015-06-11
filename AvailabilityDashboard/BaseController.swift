//
//  BaseController.swift
//  AvailabilityDashboard
//
//  Created by Kamen Angelov on 2015-06-05.
//  Copyright (c) 2015 Kamen Angelov. All rights reserved.
//

import UIKit

class BaseController: UITableViewController, AvailabilityManagerDelegate {

    @IBAction func logoButtonAction(sender: AnyObject) {
        (UIApplication.sharedApplication()).openURL(NSURL(string: "http://www.qualicom.com")!)
    }
    @IBOutlet var statusBarButton: UIBarButtonItem!

    var path: [BaseController] = []
    
    var lastUpdate: NSDate?
    var lastFetchDate: NSDate?
    
    func updateViewForRefresh(path: [BaseController], envList: [Environment]) {
        //Override me for every controller
    }
    
    func refreshSuccess(manager: AvailabilityManager) {
        if let envList = manager.getEnvironmentList() {
            updateViewForRefresh(path, envList: envList)
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
        updateStatusBarButton()
    }
    
    func refreshError(manager: AvailabilityManager, error: NSError?) {
        var alert: UIAlertView = UIAlertView(title: "Error Fetching Availability Data", message: error?.localizedDescription, delegate: nil, cancelButtonTitle: "Dismiss")
        alert.show()

        if let envList = manager.getStoredEnvironmentList() {
            if envList.count > 0 {
                updateViewForRefresh(path, envList: envList)
                self.tableView.reloadData()
                self.tableView.setNeedsDisplay()
            }

            if let lastUpdate = manager.getStoredLastUpdateTime() {
                self.lastUpdate = lastUpdate
            }
            if let lastFetchDate = manager.getStoredLastFetchTime() {
                self.lastFetchDate = lastFetchDate
            }
        }

        self.refreshControl?.endRefreshing()
        self.updateStatusBarButton()
    }
    
    override func viewDidLoad() {
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: "availabilityChanged:", name: AvailabilityChangedNotification, object: nil)
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.backgroundColor = UIColor.groupTableViewBackgroundColor()
        self.refreshControl?.addTarget(self, action: "handleRefresh:", forControlEvents: UIControlEvents.ValueChanged)
    }
    
    func populateForSegue(dest: BaseController) {
        dest.lastFetchDate = lastFetchDate
        dest.lastUpdate = lastUpdate
        dest.path = self.path + [self]
    }
    
    func handleSelection(destController: BaseController) {
        assertionFailure("This method must be overriden or in-place refresh operation won't work.")
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
    
    func getLastFetchDate(lastFetchDate: NSDate?) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("MMM-dd hh:mm")
        var lastFetchTxt = "Last Fetch: "
        if let lastFetch = lastFetchDate {
            lastFetchTxt += dateFormatter.stringFromDate(lastFetch)
        }
        return lastFetchTxt
    }
    
    func getLastUpdateDate(lastUpdateDate: NSDate?) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("MMM-dd hh:mm")
        var lastUpdateTxt = "Data As Of: "
        if let lastUpdate = lastUpdateDate {
            lastUpdateTxt += dateFormatter.stringFromDate(lastUpdate)
        }
        return lastUpdateTxt
    }
    
    func updateStatusBarButton() {
        let statusMessage = UILabel(frame: CGRectMake(0, 0, 300, 50))
        statusMessage.text = self.getLastUpdateDate(self.lastUpdate) + "\n" + self.getLastFetchDate(self.lastFetchDate)
        statusMessage.textColor = UIColor.blackColor()
        statusMessage.textAlignment = NSTextAlignment.Center
        statusMessage.numberOfLines = 3
        statusMessage.font = UIFont(name: "Courier", size: 15)
        statusMessage.sizeToFit()
        self.statusBarButton.customView = statusMessage
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
