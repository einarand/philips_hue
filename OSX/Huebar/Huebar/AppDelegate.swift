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
    var hueBridgeFound = false
    var hueApi: HueApi?
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)

    //ssdp stuff
    var ssdpAddres          = "239.255.255.250"
    var ssdpPort:UInt16     = 1900
    var ssdpSocket:GCDAsyncUdpSocket!
    var ssdpSocketRec:GCDAsyncUdpSocket!
    var error : NSError?
    //replace ST:roku:ecp with ST:ssdp:all to view all devices
    let data = "M-SEARCH * HTTP/1.1\r\nHost: 239.255.255.250:1900\r\nMan: \"ssdp:discover\"\r\nMX: 3\r\nST: \"ssdp:all\"\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)
    
    func discovery() {
        if ipAddress == nil {
            ssdpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
            ssdpSocket.sendData(data, withTimeout: -1, tag: 0)
            ssdpSocket.bindToPort(ssdpPort, error: &error)
            ssdpSocket.joinMulticastGroup(ssdpAddres, error: &error)
            ssdpSocket.beginReceiving(&error).boolValue
        
            while(!hueBridgeFound) {
                sleep(1)
                println("waiting..")
            }
            ssdpSocket.close()
        }
        
        hueApi = HueApi(ipAddress: ipAddress!, username: "newdeveloper")
        
        hueApi!.getGroups({
            groupDict in
            for (id, group) in groupDict {
                self.addLightGroupItem(group.name, id: group.id, on: group.on, value: group.brightness)
                println(group)
            }
        })
    }
    
    func udpSocket(sock: GCDAsyncUdpSocket!, didReceiveData data: NSData!, fromAddress address: NSData!, withFilterContext filterContext: AnyObject!) {
        
        var host: NSString?
        var port1: UInt16 = 0
        GCDAsyncUdpSocket.getHost(&host, port: &port1, fromAddress: address)
        println("From \(host!)")
        let decodedData: NSString = NSString(data: data!, encoding: NSUTF8StringEncoding)!
        
        println(decodedData)
        if decodedData.containsString("IpBridge") {
            NSLog("Found HueBridge on \(host!)")
            ipAddress = host as? String;
            hueBridgeFound = true;
        }
        
    }

    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let icon = NSImage(named: "bulbIcon")
        icon?.setTemplate(true)
        statusItem.image = icon
        statusItem.menu = lightControlMenu
        
        ipAddress = "192.168.128.2"
        
        let thread = NSThread(target: self, selector: "discovery", object: nil)
        thread.start()
        
        var timer = NSTimer(timeInterval: 10, target: self, selector: Selector("update"), userInfo: nil, repeats: false)
        timer.fire()
        
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
        
        var slider = NSSlider(frame: NSRect(x: 40, y:3, width: 150, height: 20))
        slider.target = self
        slider.tag = id.toInt()!
        slider.action = Selector("onSlide:")
        slider.maxValue = 255
        slider.minValue = 0
        slider.continuous = false
        slider.integerValue = value
        view.addSubview(slider)
        menuItem.view = view
        
        lightControlMenu.insertItem(NSMenuItem.separatorItem(), atIndex: 0)
        lightControlMenu.insertItem(menuItem, atIndex: 0)
    }
    
    func switchChanged(sender: SwitchControl) {
        NSLog("Switch: @", sender.isOn)
        hueApi!.setGroupState("\(sender.tag)", on: sender.isOn, transitionTime: 0)
    }
    
    var ready = true;
    let seconds = 0.3
    
    func onSlide(sender: NSSlider) {
        if (ready) {
            ready = false;
            let delay = seconds * Double(NSEC_PER_SEC)
            var dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            
            dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                self.ready = true;
            })
            hueApi!.setGroupState("\(sender.tag)", on: true, brightness: UInt8(sender.integerValue))
        }
        NSLog(String(sender.integerValue))
    }
    
    func update() {
        
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

