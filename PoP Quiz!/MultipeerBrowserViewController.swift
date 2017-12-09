//
//  MultipeerBrowserViewController.swift
//  Assignment5
//
//  Created by Joe Kickass on 5/5/17.
//  Copyright (c) 2017 Joe Kickass. All rights reserved.
//

import Foundation
import UIKit
import MultipeerConnectivity

/*
Presents a browser that establishes multipeer connections.
Should be created in whatever view controller needs toask how to connect to multipeer stuff.
The connect function does all the magic and is probably the only one that should be used.
After the connection is established, this object can safely be disposed of. All the connections will stay around in the MultipeerConection object.

Note that despite the name, this class doesn't need to be used like a typical ViewController. You can just have this as a member variable in the actual view controller of interest, so long as you pass said view controller in the constructor.
*/
class MultipeerBrowserViewController: NSObject, MCBrowserViewControllerDelegate {
    var browser: MCBrowserViewController!
    var viewController: UIViewController!

    init(connection: MultipeerConnection, viewController: UIViewController) {
        super.init()
        self.browser = MCBrowserViewController(serviceType: "pop-quiz", session: connection.session)
        browser.delegate = self
        self.viewController = viewController
    }
    
    func connect() {
        viewController.present(browser, animated: true, completion: nil)
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController!) {
        viewController.dismiss(animated: true, completion: nil)
    }
}
