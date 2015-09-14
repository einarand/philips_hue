//
//  HueSlider.swift
//  Huebar
//
//  Created by Einar Hagen on 13/09/15.
//  Copyright (c) 2015 Einar Hagen. All rights reserved.
//

import Foundation
import AppKit

class HueSlider: NSSlider {
    
    var callback : HueSlider->()
    var capturing : Bool = false
    var previousValue : Int = 0
    
    init(frame: NSRect, callback: HueSlider->()) {
        self.callback = callback;
        super.init(frame: frame)
        maxValue = 255
        minValue = 0
        continuous = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseDown(theEvent: NSEvent) {
        let thread = NSThread(target: self, selector: "capturer", object: nil)
        thread.start()
        super.mouseDown(theEvent)
        capturing = false
        if (integerValue != previousValue) {
            callback(self)
        }
    }
    
    func capturer() {
        capturing = true
        while(capturing) {
            if (integerValue != previousValue) {
                callback(self)
                previousValue = integerValue
                usleep(400000)
            } else {
                usleep(4000)
            }
        }
    }
    
}
