//
//  HuebarTests.swift
//  HuebarTests
//
//  Created by Einar Hagen on 28/03/15.
//  Copyright (c) 2015 Einar Hagen. All rights reserved.
//

import Cocoa
import XCTest

class HueApiTests: XCTestCase {
    
    var api: HueApi?
    
    override func setUp() {
        super.setUp()
        api = HueApi(ipAddress: "192.168.1.108", username: "newdeveloper",deviceName: "",applicationName: "")
    }
    
    func testSetGroupState() {
        api!.groupState("3", on: true, failure: {
            (error: NSError) -> Void in
            NSLog("Failure: " +  error.description)
        })
    }
    
    func testGetGroup() {
        api!.getGroupState("3", success: {
            (group: Group) -> Void in
            NSLog(group.description)
        }, failure: {
            (error: NSError) -> Void in
            
        })
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
