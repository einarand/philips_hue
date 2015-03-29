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
    
    let ipAdress: String = "192.168.1.108"
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let icon = NSImage(named: "bulbIcon")
        icon?.setTemplate(true)
        statusItem.image = icon
        statusItem.menu = lightControlMenu
    }
    

    @IBAction func lightsOn(sender: NSMenuItem) {
        NSLog("LightsOn pressed")
        
        let reachableLights : [String] = getReachableLights();
        for (light: String) in reachableLights {
            setLightState(light, on: true)
        }
        let menuItem = NSMenuItem(title: "Test", action:Selector("lightsOff:"), keyEquivalent: "a")
        lightControlMenu.insertItem(menuItem, atIndex: 0)
        
    }
    
    @IBAction func lightsOff(sender: NSMenuItem) {
        NSLog("LightsOff pressed")
        
        let reachableLights : [String] = getReachableLights();
        for (light: String) in reachableLights {
            setLightState(light, on: false)
        }
    }
    
    func backup() {
        let json = JSON(["persons":[["name":"Einar", "age": 36], ["name":"Per", "age": 23]]])
        
        let str = NSString(data: json.rawData()!, encoding: NSUTF8StringEncoding)
        NSLog(str!)
        
        for (index: String, subJson: JSON) in json["persons"] {
            if let name = subJson["name"].string {
                NSLog(name)
            } else {
                NSLog("Feil")
            }
        }
    }
    
    enum LightState {
        case On, Off
    }
    
    func getReachableLights() -> [String] {
        let url: NSURL = NSURL(string: "http://" + ipAdress + "/api/newdeveloper/lights")!
        var request:NSMutableURLRequest = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"
        var lights = [String]()
        
        if let data = NSURLConnection.sendSynchronousRequest(request, returningResponse: nil, error: nil) {
            let json = JSON(data: data)
            
            for (key: String, lightJson: JSON) in json {
                if (lightJson["state"]["reachable"].boolValue) {
                    lights.append(key)
                }
            }
        } else {
            NSLog("Failed")
        }
        return lights
    }
    
    func setLightState(id: NSString, on: Bool) {
        let url: NSURL = NSURL(string: "http://" + ipAdress + "/api/newdeveloper/lights/" + id + "/state")!
        var request:NSMutableURLRequest = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "PUT"
        request.HTTPBody = JSON(["on": on]).rawData()!
        if let data = NSURLConnection.sendSynchronousRequest(request, returningResponse: nil, error: nil) {
            NSLog("Response: " + NSString(data: data, encoding: NSUTF8StringEncoding)!)
        }
    }
}

