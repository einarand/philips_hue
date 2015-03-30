//
//  AppDelegate.swift
//  Huebar
//
//  Created by Einar Hagen on 28/03/15.
//  Copyright (c) 2015 Einar Hagen. All rights reserved.
//

import Cocoa
import AppKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var lightControlMenu: NSMenu!
    @IBOutlet weak var sliderItem: NSView!
    
    let ipAdress: String = "192.168.1.108"
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let icon = NSImage(named: "bulbIcon")
        icon?.setTemplate(true)
        statusItem.image = icon
        statusItem.menu = lightControlMenu
        
        getGroups()
    }

    @IBAction func lightsOn(sender: NSMenuItem) {
        NSLog("LightsOn pressed")
        
        let reachableLights : [String] = getReachableLights();
        for (light: String) in reachableLights {
            lightState(light, on: true)
        }
        
    }
    
    func addLightGroupItem(name: String, id: String, on: Bool, value: NSInteger) {
        var menuItem = NSMenuItem()
        
        var view = NSView(frame: NSRect(x: 0,y: 0,width: 200,height: 40))
        var txt = NSTextField(frame: NSRect(x: 40, y:10, width: 200, height: 30))
        txt.stringValue = name
        txt.bezeled = false;
        txt.drawsBackground = false;
        txt.editable = false;
        txt.selectable = false;
        view.addSubview(txt)
        
        
        var switchControl = SwitchControl(frame: NSRect(x: 5, y:5, width: 30, height: 15))
        switchControl.isOn = on
        switchControl.target = self
        switchControl.action = Selector("switchChanged:")
        view.addSubview(switchControl)
        
        var slider = NSSlider(frame: NSRect(x: 40, y:3, width: 150, height: 20))
        slider.target = self;
        slider.action = Selector("onSlide:")
        slider.maxValue = 255;
        slider.minValue = 0;
        slider.continuous = false;
        slider.integerValue = value
        view.addSubview(slider)
        menuItem.view = view
        
        lightControlMenu.insertItem(NSMenuItem.separatorItem(), atIndex: 0)
        lightControlMenu.insertItem(menuItem, atIndex: 0)
    }
    
    func switchChanged(sender: SwitchControl) {
        NSLog("Switch: @", sender.isOn)
        groupState("3", on: sender.isOn, bri: nil)
    }
    
    func onSlide(sender: NSSlider) {
        groupState("3", on: true, bri: sender.integerValue)
        NSLog(String(sender.integerValue))
    }
    
    @IBAction func lightsOff(sender: NSMenuItem) {
        NSLog("LightsOff pressed")
        
        let reachableLights : [String] = getReachableLights();
        for (light: String) in reachableLights {
            lightState(light, on: false)
        }
    }
    
    func getGroups() {
        let url: NSURL = NSURL(string: "http://" + ipAdress + "/api/newdeveloper/groups")!
        var request:NSMutableURLRequest = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"
        
        if let data = NSURLConnection.sendSynchronousRequest(request, returningResponse: nil, error: nil) {
            let json = JSON(data: data)
            
            for (id: String, groupJson: JSON) in json {
                let name = groupJson["name"].stringValue
                let value = groupJson["action"]["bri"].intValue
                let on = groupJson["action"]["on"].boolValue
                addLightGroupItem(name, id: id, on: on, value: value)
            }
        } else {
            NSLog("Failed")
        }
        
    }
    
    func groupState(groupId: NSString, on: Bool?, bri: NSInteger?) {
        let url: NSURL = NSURL(string: "http://" + ipAdress + "/api/newdeveloper/groups/" + groupId + "/action")!
        var request:NSMutableURLRequest = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "PUT"
        var json: JSON = [:]
        if let onState = on? {
            json["on"].boolValue = onState
        }
        if let briValue = bri? {
            json["bri"].intValue = briValue
        }
        let rawJson = json.rawData()!
        
        NSLog(NSString(data: rawJson, encoding: NSUTF8StringEncoding)!)
        request.HTTPBody = rawJson
        if let data = NSURLConnection.sendSynchronousRequest(request, returningResponse: nil, error: nil) {
            NSLog("Response: " + NSString(data: data, encoding: NSUTF8StringEncoding)!)
        }
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
    
    func lightState(id: NSString, on: Bool) {
        let url: NSURL = NSURL(string: "http://" + ipAdress + "/api/newdeveloper/lights/" + id + "/state")!
        var request:NSMutableURLRequest = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "PUT"
        request.HTTPBody = JSON(["on": on]).rawData()!
        if let data = NSURLConnection.sendSynchronousRequest(request, returningResponse: nil, error: nil) {
            NSLog("Response: " + NSString(data: data, encoding: NSUTF8StringEncoding)!)
        }
    }
    
    func lightState(id: NSString) -> NSInteger {
        let url: NSURL = NSURL(string: "http://" + ipAdress + "/api/newdeveloper/lights/" + id + "/state")!
        var request:NSMutableURLRequest = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"
        if let data = NSURLConnection.sendSynchronousRequest(request, returningResponse: nil, error: nil) {
            NSLog("Response: " + NSString(data: data, encoding: NSUTF8StringEncoding)!)
        }
        return 0
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

}

protocol HueControl {
        
    func lightState(id: NSString, on: Bool)
        
}

