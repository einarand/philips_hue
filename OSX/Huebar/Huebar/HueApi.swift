//
//  HueApi.swift
//  Huebar
//
//  Created by Einar Hagen on 31/03/15.
//  Copyright (c) 2015 Einar Hagen. All rights reserved.
//

import Foundation
import Cocoa

public struct Group: Printable {
    let id: String
    let name: String
    let on: Bool
    let brightness: Int
    public var description: String {
        return ("id:\(id), name:\(name), on:\(on), brightness:\(brightness)")
    }
}

public struct Light: Printable {
    let id: String
    let name: String
    let on: Bool
    let brightness: Int
    public var description: String {
        return ("id:\(id), name:\(name), on:\(on), brightness:\(brightness)")
    }
}

public struct Scene: Printable {
    let id: String
    let name: String
    let lights: [String]
    let active: Bool
    public var description: String {
        return ("id:\(id), name:\(name), lights:\(lights), active:\(active)")
    }
}

public struct XY: RawRepresentable {
    let x: Float
    let y: Float
    
    public init?(rawValue: String) {
        x=1
        y=0.5
    }
    
    public var rawValue: String { get {
        return ("[\(x),\(y)]")
    }}
   
}

enum Alert: String {
    case none = "none"
    case select = "select"
    case lselect = "lselect"
}

enum Effect: String {
    case colorloop = "colorloop"
    case none = "none"
}

public class HueApi {
    
    let baseUrl: NSURL
    
    let username: String
    let deviceName: String
    let applicationName: String
    
    var sequenceNumber = 0;
    
    init(ipAddress: String, username: String, deviceName: String?="OSX", applicationName: String?="HueApi") {
        self.username = username
        self.deviceName = deviceName!
        self.applicationName = applicationName!
        baseUrl = NSURL(string: "http://\(ipAddress)/api/\(username)/")!
    }
    
    func getBridgeIpAddress(success: [[String:String]] -> (), failure: (NSError -> ())?=nil) {
        get(NSURL(fileURLWithPath: "https://www.meethue.com/api/nupnp")!, success: {
            (json: JSON) -> Void in
            NSLog("")
            success([["id":json[0]["id"].stringValue], ["internalIpAddress":json[0]["interalIpAddress"].stringValue]])
            }, failure: failure)
    }
    
    func setLightState(lightId: String,
        on: Bool?=nil,
        brightness: UInt8?=nil,
        hue: UInt16?=nil,
        sat: UInt8?=nil,
        xy: XY?=nil,
        ct: UInt16?=nil,
        alert: Alert?=nil,
        effect: Effect?=nil,
        transitionTime: UInt16?=nil,
        scene: String?=nil,
        success: (() -> ())?=nil, failure: (NSError -> ())?=nil) {
           
        var json = JSON([:])
        if let on = on { json["on"].boolValue = on }
        if let brightness = brightness { json["bri"].uInt8 = brightness }
        if let hue = hue { json["hue"].uInt16 = hue }
        if let xy = xy { json["xy"].string = xy.rawValue }
        if let alert = alert { json["alert"].string = alert.rawValue }
        if let effect = effect { json["effect"].string = effect.rawValue }
        if let transitionTime = transitionTime { json["transitiontime"].uInt16 = transitionTime }
        if let scene = scene { json["scene"].string = scene }
            
        put(NSURL(string: "lights/\(lightId)/state", relativeToURL: baseUrl)!, json: json, success: {
            (json: JSON) -> Void in
            NSLog("")
            success?()
            }, failure: failure)
            
    }
    
    func getLightState(lightId: String, success: Light -> (), failure: (NSError -> ())?=nil) {
        get(NSURL(string: "lights/\(lightId)", relativeToURL: baseUrl)!, success: {
            (json: JSON) -> Void in
            success(Light(id: lightId, name: json["name"].stringValue, on: json["state"]["on"].boolValue, brightness: json["state"]["bri"].intValue))
            }, failure: failure)
        
    }
    
    func setGroupState(groupId: String,
        on: Bool?=nil,
        brightness: UInt8?=nil,
        hue: UInt16?=nil,
        sat: UInt8?=nil,
        xy: XY?=nil,
        ct: UInt16?=nil,
        alert: Alert?=nil,
        effect: Effect?=nil,
        transitionTime: UInt16?=nil,
        scene: String?=nil,
        success: (() -> ())?=nil, failure: (NSError -> ())?=nil) {
            
        var json = JSON([:])
        if let on = on { json["on"].boolValue = on }
        if let brightness = brightness { json["bri"].uInt8 = brightness }
        if let hue = hue { json["hue"].uInt16 = hue }
        if let xy = xy { json["xy"].string = xy.rawValue }
        if let alert = alert { json["alert"].string = alert.rawValue }
        if let effect = effect { json["effect"].string = effect.rawValue }
        if let transitionTime = transitionTime { json["transitiontime"].uInt16 = transitionTime }
        if let scene = scene { json["scene"].string = scene }
        
        put(NSURL(string: "groups/\(groupId)/action", relativeToURL: baseUrl)!, json: json, success: {
            (json: JSON) -> Void in
                NSLog("")
                success?()
            }, failure: failure)
    }
    
    func getGroupState(groupId: String, success: Group -> (), failure: (NSError -> ())?=nil) {
        get(NSURL(string: "groups/\(groupId)", relativeToURL: baseUrl)!, success: {
            (json: JSON) -> Void in
            success(Group(id: groupId, name: json["name"].stringValue, on: json["action"]["on"].boolValue, brightness: json["action"]["bri"].intValue))
            }, failure: failure)
        
    }
    
    func getGroups(success: [String:Group] -> (), failure: (NSError -> ())?=nil) {
        get(NSURL(string: "groups", relativeToURL: baseUrl)!, success: {
            (json: JSON) -> Void in
            var groupDict: [String:Group] = [:]
            
            for (id: String, groupJson: JSON) in json {
                groupDict[id] = Group(id: id,
                    name: groupJson["name"].stringValue,
                    on: groupJson["action"]["on"].boolValue,
                    brightness: groupJson["action"]["bri"].intValue)
            }
            success(groupDict)
            }, failure: failure)
    }
    
    func getScenes(success: [String:Scene] -> (), failure: (NSError -> ())?=nil)  {
        get(NSURL(string: "scenes", relativeToURL: baseUrl)!, success: {
            (json: JSON) -> Void in
            var sceneDict: [String:Scene] = [:]
            
            for (id: String, sceneJson: JSON) in json {
                sceneDict[id] = Scene(id: id,
                    name: sceneJson["name"].stringValue,
                    lights: sceneJson["lights"].arrayObject as! [String],
                    active: sceneJson["active"].boolValue)
            }
            success(sceneDict)
            }, failure: failure)
    }
    
    func get(url: NSURL, success: (JSON -> ())?=nil, failure: (NSError -> ())?=nil) {
        RESTCall("GET", url: url, json: nil, success: success, failure: failure)
    }
    
    func put(url: NSURL, json: JSON, success: (JSON -> ())?=nil, failure: (NSError -> ())?=nil) {
        RESTCall("PUT", url: url, json: json, success: success, failure: failure)
    }
    
    func RESTCall(httpMethod: String, url: NSURL, json: JSON?, success: (JSON -> ())?=nil, failure: (NSError -> ())?=nil) {
        sequenceNumber++;

        var request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = httpMethod
        request.addValue(String(sequenceNumber), forHTTPHeaderField: "sequenceNumber")
        request.timeoutInterval = 30
        request.HTTPShouldHandleCookies = false
        var body: String = ""
        if json != nil {
            request.HTTPBody = json!.rawData()!
            body = jsonToString(json!)
        }
        NSLog("Request (\(sequenceNumber)): \(httpMethod) \(url.absoluteURL!) body:\(body)")
        
        var task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            (data, response, error) -> Void in
            
            if response != nil {
                let httpResponse = response as! NSHTTPURLResponse
                var sequenceNumberStr = request.valueForHTTPHeaderField("sequenceNumber")!
                NSLog("Response(\(sequenceNumberStr)): statusCode:\(httpResponse.statusCode) body:\(self.dataToString(data))")
            }
            
            if error != nil {
                failure?(error)
            } else {
                let json = JSON(data: data)
                let errorJson = json[0]["error"]
                if (errorJson != nil) {
                    let errorDescription = errorJson["description"].stringValue
                    let errorCode = errorJson["type"].intValue
                    failure?(NSError(domain: errorDescription, code: errorCode, userInfo: nil))
                } else {
                    success?(json)
                }
            }
        }
        task.resume()
    }
    
    func jsonToString(json: JSON) -> String {
        return NSString(data: json.rawData()!, encoding: NSUTF8StringEncoding) as! String
    }
    
    func dataToString(data: NSData) -> NSString {
        return NSString(data: data, encoding: NSUTF8StringEncoding)!
    }
    
}