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
    //let hueApi: HueApi = HueApi(ipAddress: "127.0.0.1:8000", username: "newdeveloper")
    let hueApi: HueApi = HueApi(ipAddress: "192.168.1.108", username: "newdeveloper")
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let icon = NSImage(named: "bulbIcon")
        icon?.setTemplate(true)
        statusItem.image = icon
        statusItem.menu = lightControlMenu
        
        hueApi.getGroups({
            groupDict in
            for (id, group) in groupDict {
                self.addLightGroupItem(group.name, id: group.id, on: group.on, value: group.brightness)
                println(group)
            }
        })
        
        hueApi.getScenes({
            sceneDict in
            for (id, scene) in sceneDict {
                println(scene)
            }
        })
        
    }

    @IBAction func lightsOn(sender: NSMenuItem) {
        NSLog("LightsOn pressed")
        
        let reachableLights : [String] = getReachableLights();
        for (light: String) in reachableLights {
            hueApi.setLightState(light, on: true)
        }
        
    }
    
    func addLightGroupItem(name: String, id: String, on: Bool, value: NSInteger) {
        var menuItem = NSMenuItem()
        menuItem.representedObject = id;
        
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
        slider.continuous = true;
        slider.integerValue = value
        view.addSubview(slider)
        menuItem.view = view
        
        lightControlMenu.insertItem(NSMenuItem.separatorItem(), atIndex: 0)
        lightControlMenu.insertItem(menuItem, atIndex: 0)
    }
    
    func switchChanged(sender: SwitchControl) {
        NSLog("Switch: @", sender.isOn)
        hueApi.groupState("3", on: sender.isOn)
    }
    
    func onSlide(sender: NSSlider) {
        hueApi.groupState("3", on: true, brightness: UInt8(sender.integerValue))
        NSLog(String(sender.integerValue))
    }
    
    @IBAction func lightsOff(sender: NSMenuItem) {
        NSLog("LightsOff pressed")
        
        let reachableLights : [String] = getReachableLights();
        for (light: String) in reachableLights {
            hueApi.setLightState(light, on: false)
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

