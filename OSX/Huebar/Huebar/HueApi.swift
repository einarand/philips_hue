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
    
    let queue:NSOperationQueue = NSOperationQueue()
    
    init(ipAddress: String, username: String, deviceName: String, applicationName: String) {
        self.username = username
        self.deviceName = deviceName
        self.applicationName = applicationName
        baseUrl = NSURL(string: "http://\(ipAddress)/api/\(username)")!
    }
    
    func createUser() {
        baseUrl
        
    }
    
    func groupState(groupId: String, on: Bool?=nil, brightness: Int?=nil, success: (() -> ())?=nil, failure: (NSError -> ())?=nil) {
        
        let jsonLiteral = JSON([:])
        
        let url = NSURL(string: "/groups", relativeToURL: baseUrl)!
        
        put(url, json: jsonLiteral, success: {
            (json2: JSON) -> Void in
            println("hei")
            success?()
        })
        
        failure?(NSError(domain: "somedomain", code: 2, userInfo: ["test": 123] ))
    }
    
    struct Group {
        var id: String
        var name: String
        var on: Bool
        var brightness: Int
    }
    
    func put(url: NSURL, json: JSON, success: (JSON -> ())?=nil, failure: (NSError -> ())?=nil) {
        var request1 = NSMutableURLRequest(URL: url)
        request1.HTTPMethod = "PUT"
        
        let data = json.rawData()!
        NSLog(NSString(data: data, encoding: NSUTF8StringEncoding)!)
        
        request1.timeoutInterval = 60
        request1.HTTPBody = data
        request1.HTTPShouldHandleCookies = false
        
        NSURLConnection.sendAsynchronousRequest(request1, queue: queue, completionHandler:{
            (response: NSURLResponse!, data: NSData!, error: NSError!) -> () in
                let json = JSON(data: data)
                success?(json)
        })
        
    }
    
}