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
    @IBOutlet weak var statusBarButton: UIBarButtonItem!

    var lastUpdate: NSDate?
    var lastFetchDate: NSDate?
    
    func refreshSuccess(manager: AvailabilityManager) {
        preconditionFailure("This method must be overriden.")
    }
    
    func refreshError(error: NSError?) {
        preconditionFailure("This method must be overriden.")
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
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
