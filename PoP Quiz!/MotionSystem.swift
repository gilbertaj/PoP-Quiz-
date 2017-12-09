//
//  MotionSystem.swift
//  Assignment5
//
//  Created by Joe Kickass on 5/4/17.
//  Copyright (c) 2017 Joe Kickass. All rights reserved.
//

import Foundation
import CoreMotion

class MotionSystem {
    // BEGIN THINGS YOU MAY WANT TO MODIFY
    let motionThresholdHorizontal = 50.0 // Makes selection by motion more (lower values) or less (higher values) sensitive.
    let motionThresholdVertical = 30.0
    let accelerationSubmitThreshold = -1.1
    let yawSubmitThreshold = 30.0
    var select = "";
    
    
    func moveSelectionRight() {
        if(select != "") {
            return
        }
        select = "RIGHT"
    }
    
    func moveSelectionLeft() {
        if(select != "") {
            return
        }
        select = "LEFT"
    }
    
    func moveSelectionUp() {
        if(select != "") {
            return
        }
        select = "UP"
    }
    
    func moveSelectionDown() {
        if(select != "") {
            return
        }
        select = "DOWN"
    }
    
    func submitAnswer() {
        if(select != "") {
            return
        }
        select = "SUBMIT"
    }
    
    func getSelected() -> String {
        return select
    }
    
    func setSelected(select: String) {
        self.select = select
    }
    // END THINGS YOU MAY WANT TO MODIFY
    
    let motionManager = CMMotionManager()
    // For reference, when phone is flat with screen facing towards the sky, pitch = 0. When phone
    // is tilted up to face directly to you, pitch = 90.
    // IMPORTANT: These values do NOT necessarily "update nicely" by which I mean if you rotate the phone from flat to towards you, pitch will increase from 0 to 90. If you keep rotating it forward, pitch will start decreasing from 90 back to 0. Basically, taking the difference between these values at different points in time can give unexpected results because of this.
    // TL;DR:
    // * Using these values to determine device orientation = OKAY!
    // * Using these values to do more complex math like determine speed of rotation = NOT OKAY! (At least without some very careful math)
    var pitch = -1000.0
    var roll = -1000.0
    var yaw = -1000.0
    var lastYawed = false
    var lastYawedRight = false
    var count = 0
    
    init() {
        if motionManager.isAccelerometerAvailable {
            motionManager.startAccelerometerUpdates()
            motionManager.accelerometerUpdateInterval = 0.1
        }
        
        if motionManager.isDeviceMotionAvailable {
            // do something interesting
            motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {
                (deviceMotion, error) -> Void in
                
                if(error == nil) {
                    self.handleDeviceMotionUpdate(deviceMotion: deviceMotion!)
                } else {
                    // handle the error
                }
            })
            motionManager.deviceMotionUpdateInterval = 0.1
        }
        
        
    }
    
    private func degrees(radians:Double) -> Double {
        return 180/M_PI * radians
    }
    
    func handleAccelerometerUpdates(motion : CMAccelerometerData) {
        let acceleration = 0.0
        print(acceleration)
        if(acceleration < accelerationSubmitThreshold) {
            print(acceleration)
        }
    }
    
    
    func handleDeviceMotionUpdate(deviceMotion: CMDeviceMotion) {
        var acceleration = deviceMotion.userAcceleration.z
        var attitude = deviceMotion.attitude
        var roll1 = degrees(radians: attitude.roll)
        var pitch1 = degrees(radians: attitude.pitch)
        var yaw1 = degrees(radians: attitude.yaw)
        
        if(roll == -1000.0 || pitch == -1000.0 || yaw == -1000.0) {
            roll = roll1
            pitch = pitch1
            yaw = yaw1
            return
        }
        
        var dpitch = pitch1 - pitch
        var droll = roll1 - roll
        var dyaw = yaw1 - yaw
        
        // This makes it so you have to "jerk" the phone in the direction you want to move.
        // The idea is it can distinguish between attempts to change the phone's orientation and attempts
        // to change the selection.
        // It can be made more or less sensitive by increasing or decreasing this threshold, respectively.
        if(abs(dpitch) > motionThresholdVertical) {
            if(dpitch < 0) {
                moveSelectionUp()
            } else {
                moveSelectionDown()
            }
        }
        count += 1
        if(count >= 20) {
            lastYawed = false
        }
        if(abs(dyaw) > yawSubmitThreshold) {
            if(lastYawed == true) {
                if(lastYawedRight != (dyaw < 0)) {
                    // We've just had two powerful yaw movements in different directions. This is cause to submit.
                    submitAnswer()
                }
            }
            count = 0
            lastYawed = true
            lastYawedRight = dyaw < 0
        }
        if(abs(droll) > motionThresholdHorizontal) {
            if(droll > 0) {
                moveSelectionRight()
            } else {
                moveSelectionLeft()
            }
        }

        if(acceleration < accelerationSubmitThreshold) {
            submitAnswer()
        }
    }
    
}

