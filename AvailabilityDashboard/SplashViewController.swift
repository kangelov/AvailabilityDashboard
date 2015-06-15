//
//  SplashViewController.swift
//  AvailabilityDashboard
//
//  Created by Kamen Angelov on 2015-06-15.
//  Copyright (c) 2015 Kamen Angelov. All rights reserved.
//

import UIKit

class SplashViewController : UIViewController {
    
    override func viewDidLoad() {
        println("I am in splash!")
    }
    
    override func viewDidAppear(animated: Bool) {
        sleep(3)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
