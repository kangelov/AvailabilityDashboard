//
//  DetailViewController.swift
//  AvailabilityDashboard
//
//  Created by Kamen Angelov on 2015-05-11.
//  Copyright (c) 2015 Kamen Angelov. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet var nodeTitleLabel: UINavigationItem!
    
    @IBOutlet var webServiceNameText: UITextField!
    
    @IBOutlet var versionText: UITextField!
    
    @IBOutlet var statusText: UITextField!
    
    @IBOutlet var statusBackgroundImage: UIImageView!
    
    @IBOutlet var pingResponseArea: UITextView!
    
    var service: Service? {
        didSet {
            self.configureView()
        }
    }
    var node: Node? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let node: Node = self.node {
            if let service: Service = self.service {
                nodeTitleLabel?.title = node.name
                webServiceNameText?.text = service.name
                versionText?.text = node.version
                statusText?.text = node.status
                pingResponseArea?.text = node.response
                pingResponseArea?.font = UIFont(name: "Courier New", size: 17.0) //no idea why I can't set this with the UI Editor
                switch (node.status) {
                case "OK":
                    statusBackgroundImage?.image = UIImage(named: "OKBG")
                case "FAILED":
                    statusBackgroundImage?.image = UIImage(named: "FailedBG")
                case "WRONG_VERSION":
                    statusBackgroundImage?.image = UIImage(named: "WrongVersionBG")
                default:
                    statusBackgroundImage?.image = UIImage(named: "UnknownBG")
                }
                self.becomeFirstResponder()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

