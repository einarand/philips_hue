//
//  HueApi.swift
//  Huebar
//
//  Created by Einar Hagen on 31/03/15.
//  Copyright (c) 2015 Einar Hagen. All rights reserved.
//

import Foundation

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
    
    func groupState(groupId: String, on: Bool?=nil, brightness: Int?=nil, success: (() -> ())?=nil, failure: (NSError -> ())?=nil) {
        var json = JSON([:])
        if let on = on? {
            json["on"].boolValue = on
        }
        if let brightness = brightness? {
            json["bri"].intValue = brightness
        }
        
        put(NSURL(string: "groups/\(groupId)/action", relativeToURL: baseUrl)!, json: json, success: {
            (json: JSON) -> Void in
                NSLog("")
                success?()
            }, failure: failure)
    }
    
    func getGroups(success: (([String:Group]) -> ()), failure: (NSError -> ())?=nil) {
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
    
    func getGroupState(groupId: String, success: ((Group) -> ()), failure: (NSError -> ())?=nil) {
        get(NSURL(string: "groups/\(groupId)", relativeToURL: baseUrl)!, success: {
            (json: JSON) -> Void in
            success(Group(id: groupId, name: json["name"].stringValue, on: json["action"]["on"].boolValue, brightness: json["action"]["bri"].intValue))
        }, failure: failure)
        
    }
    
    public struct Group {
        var id: String
        var name: String
        var on: Bool
        var brightness: Int
        var description: String {
            return ("id:\(id), name:\(name), on:\(on), brightness:\(brightness)")
        }
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
        NSLog("\(httpMethod)(\(sequenceNumber)) \(url.absoluteURL!) body:\(body)")
        
        
        var task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            (data, response, error) -> Void in
            
            if response != nil {
                let httpResponse = response as NSHTTPURLResponse
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
                    failure?(NSError(domain: errorDescription, code: 0, userInfo: nil))
                } else {
                    success?(json)
                }
            }
        }
        task.resume()
    }
    
    func jsonToString(json: JSON) -> NSString {
        return NSString(data: json.rawData()!, encoding: NSUTF8StringEncoding)!
    }
    
    func dataToString(data: NSData) -> NSString {
        return NSString(data: data, encoding: NSUTF8StringEncoding)!
    }
    
    
}