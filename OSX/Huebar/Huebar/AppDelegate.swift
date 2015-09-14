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
class AppDelegate: NSObject, NSApplicationDelegate, GCDAsyncUdpSocketDelegate {

    @IBOutlet weak var lightControlMenu: NSMenu!
    @IBOutlet weak var sliderItem: NSView!
    
    var ipAddress: String?
    var hueApi: HueApi?
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)

    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let icon = NSImage(named: "bulbIcon")
        icon?.setTemplate(true)
        statusItem.image = icon
        statusItem.menu = lightControlMenu
        
        HueApi.getBridgeIpAddress({
            ipAddress in
            self.ipAddress = ipAddress;
            self.hueApi = HueApi(ipAddress: ipAddress, username: "newdeveloper")
            self.hueApi!.getGroups({
                groupDict in
                for (id, group) in groupDict {
                    self.addLightGroupItem(group.name, id: group.id, on: group.on, value: group.brightness)
                    println(group)
                }
            })
            
        })
        
    }
    
    func addLightGroupItem(name: String, id: String, on: Bool, value: NSInteger) {
        var menuItem = NSMenuItem()
        menuItem.representedObject = id
        
        var view = NSView(frame: NSRect(x: 0,y: 0,width: 200,height: 40))
        
        var txt = NSTextField(frame: NSRect(x: 40, y:10, width: 200, height: 30))
        txt.stringValue = name
        txt.bezeled = false
        txt.drawsBackground = false
        txt.editable = false
        txt.selectable = false
        view.addSubview(txt)
        
        var switchControl = SwitchControl(frame: NSRect(x: 5, y:5, width: 30, height: 15))
        switchControl.isOn = on
        switchControl.tag = id.toInt()!
        switchControl.target = self
        switchControl.action = Selector("switchChanged:")
        view.addSubview(switchControl)
        
        var slider = HueSlider(frame: NSRect(x: 40, y:3, width: 150, height: 20), callback: {
            slider in
            self.hueApi!.setGroupState("\(slider.tag)", on: true, brightness: UInt8(slider.integerValue), transitionTime: 3)
            switchControl.isOn = on;
        })
        slider.tag = id.toInt()!
        slider.integerValue = value
        view.addSubview(slider)
        menuItem.view = view
        
        lightControlMenu.insertItem(NSMenuItem.separatorItem(), atIndex: 0)
        lightControlMenu.insertItem(menuItem, atIndex: 0)
    }
    
    func switchChanged(sender: SwitchControl) {
        NSLog("Switch: @", sender.isOn)
        hueApi!.setGroupState("\(sender.tag)", on: sender.isOn, transitionTime: 10)
    }
    
    @IBAction func lightsOn(sender: NSMenuItem) {
        NSLog("LightsOn pressed")
        
        let reachableLights : [String] = getReachableLights();
        for (light: String) in reachableLights {
            hueApi!.setLightState(light, on: true)
        }
        
    }
    
    @IBAction func lightsOff(sender: NSMenuItem) {
        NSLog("LightsOff pressed")
        
        let reachableLights : [String] = getReachableLights();
        for (light: String) in reachableLights {
            hueApi!.setLightState(light, on: false)
        }
    }
    
    func getReachableLights() -> [String] {
        let url: NSURL = NSURL(string: "http://" + ipAddress! + "/api/newdeveloper/lights")!
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
    
}

protocol HueControl {
        
    func lightState(id: NSString, on: Bool)
        
}

