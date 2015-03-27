//
//  AppDelegate.swift
//  Huebar
//
//  Created by Einar Hagen on 28/03/15.
//  Copyright (c) 2015 Einar Hagen. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var lightControlMenu: NSMenu!
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
    


    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let icon = NSImage(named: "bulbIcon")
        icon?.setTemplate(true)
        
        statusItem.image = icon
        statusItem.menu = lightControlMenu
    }
    

    @IBAction func lightsOn(sender: NSMenuItem) {
    }
    
    @IBAction func lightsOff(sender: NSMenuItem) {
    }
}

