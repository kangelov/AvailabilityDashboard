//
//  MasterViewController.swift
//  AvailabilityDashboard
//
//  Created by Kamen Angelov on 2015-05-11.
//  Copyright (c) 2015 Kamen Angelov. All rights reserved.
//

import UIKit

class NodesViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil

    var service: Service?
    var nodes: [Node] = []
    
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
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                let object = nodes[indexPath.row] as Node
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                controller.service = service
                controller.node = object
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
                controller.becomeFirstResponder()
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nodes.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 70
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let node = nodes[indexPath.row] as Node
        var cell: UITableViewCell
        switch node.status {
        case "WRONG_VERSION":
            cell = tableView.dequeueReusableCellWithIdentifier("WrongNodeItem", forIndexPath: indexPath) as! UITableViewCell
        case "OK":
            cell = tableView.dequeueReusableCellWithIdentifier("OKNodeItem", forIndexPath: indexPath) as! UITableViewCell
        case "FAILED":
            cell = tableView.dequeueReusableCellWithIdentifier("FailedNodeItem", forIndexPath: indexPath) as! UITableViewCell
        default:
            cell = tableView.dequeueReusableCellWithIdentifier("UnknownNodeItem", forIndexPath: indexPath) as! UITableViewCell
        }
        
        cell.textLabel!.text = node.name
        cell.detailTextLabel!.text = node.version
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }


}

