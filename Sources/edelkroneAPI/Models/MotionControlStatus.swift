/**
 MotionControlStatus.swift
 edelkroneAPI
 
 Containing basic models for api results
 
 Created by Carsten Müller on 07.03.2022.
 Copyright © 2022 Carsten Müller. All rights reserved.
 */

import Foundation
import SwiftUI

public class AxelStatus : AxelDescription, Hashable, Equatable, Identifiable, ObservableObject, JoystickControlledAxel {
  
  public var id: AxelID{
    get{
      return axelName
    }
  }
  
  @Published public var axelName: AxelID
  @Published public var device:EdelkroneDevice
  
  @Published var calibrated:Bool
  public var needsCalibration:Bool {
    get {
      self.objectWillChange.send()
      return  (self.calibrated == false) && device.canCalibrate
    }
  }
  @Published public var position: Double
  @Published public var batteryLevel: Double
  
  public var shouldMove: Bool = false
  public var isLastMove: Bool = true
  public var moveValue: Double = 0.0
  
  
  public static func == (lhs:AxelStatus, rhs:AxelStatus) -> Bool{
    return lhs.axelName == rhs.axelName
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(axelName)
  }
  
  public init(from: PeriodicStatus, forName:AxelID){
    axelName = forName
    device = from.deviceFor(name:forName)
    position = from.positionFor(name:forName)
    calibrated = from.calibrationStateFor(name:forName)
    batteryLevel = from.batteryLevelFor(name: forName)
  }
  
  public func update(from: PeriodicStatus){
    device = from.deviceFor(name:axelName)
    position = from.positionFor(name:axelName)
    calibrated = from.calibrationStateFor(name: axelName)
    batteryLevel = from.batteryLevelFor(name: axelName)
  }
}

// MARK: - MotionControlStatus
public class MotionControlStatus: ObservableObject {
  @Published public var axelStatus:[AxelID : AxelStatus] = [:]
  
  @Published public var keyposeLoopActive:Bool = false
  @Published public var keyposeTargetIndex: Int = 0
  @Published public var keyposeStartIndex: Int = -1
  @Published public var keyposeMotionProgress: Double = 1.0
  @Published public var keyposeMotionDuration: Double = 0.0
  @Published public var state:MotionState = .idle
  @Published public var filledKeypose:[Bool] = []

  public static func &= (lhs:MotionControlStatus, rhs:PeriodicStatus){
    if rhs.deviceInfoReady == false{
      return
    }
        
    lhs.objectWillChange.send()
    if lhs.keyposeLoopActive != rhs.keyposeLoopActive{
      lhs.keyposeLoopActive = rhs.keyposeLoopActive
    }
    if lhs.keyposeTargetIndex != rhs.keyposeMotionAimIndex {
      lhs.keyposeTargetIndex = rhs.keyposeMotionAimIndex
    }
    if lhs.keyposeStartIndex != rhs.keyposeMotionStartIndex{
      lhs.keyposeStartIndex = rhs.keyposeMotionStartIndex
    }
    if lhs.keyposeMotionProgress != rhs.plannedMotionProgress{
      lhs.keyposeMotionProgress = rhs.plannedMotionProgress
    }
    if lhs.keyposeMotionDuration != rhs.plannedMotionDuration{
      lhs.keyposeMotionDuration = rhs.plannedMotionDuration
    }
    if lhs.state != rhs.state{
      lhs.state = rhs.state
    }
    
    // now update or create entries into axelStatus
    var supportedNames:[AxelID] = []
    for index in 0..<rhs.supportedAxes.count {
      let axel = rhs.supportedAxes[index]
      let name = axel.axelName
      supportedNames.append(name)
      var q:AxelStatus
      if lhs.axelStatus.keys.contains(name) {
        q = lhs.axelStatus[name]!
        q.update(from: rhs)
        
      }else{
        q = AxelStatus(from: rhs, forName: name)
        lhs.axelStatus[name]  = q
      }
    }
    for key in lhs.axelStatus.keys {
      if !supportedNames.contains(key){
        lhs.axelStatus.removeValue(forKey: key)
      }
    }
    
    // update or create keypose slots
    if lhs.filledKeypose.count != rhs.keyposeSlotsFilled.count{
      lhs.filledKeypose.removeAll()
      lhs.filledKeypose = Array(repeating: false, count: rhs.keyposeSlotsFilled.count)
      for idx in 0..<rhs.keyposeSlotsFilled.count {
        lhs.filledKeypose[idx] = rhs.keyposeSlotsFilled[idx]
      }
    }
  }
  
  public init(){
    let t = PeriodicStatus()
    self &= t
  }
  
  public var hasTilt:Bool {
    get{
      return axelStatus.keys.contains(.headTilt) || axelStatus.keys.contains(.jibPlusTilt)
    }
  }
  
  public var hasPan:Bool {
    get{
      return  axelStatus.keys.contains(.headPan) || axelStatus.keys.contains(.jibPlusPan)
    }
  }
  
  public var hasSlide:Bool {
    get {
      return axelStatus.keys.contains(.slide)
    }
  }
  
  public var hasFocus:Bool {
    get {
      return axelStatus.keys.contains(.focus)
    }
  }
  
  public func panTiltObjects() -> [DegreeOfFreedom:JoystickControlledAxel] {
    var result:[DegreeOfFreedom:JoystickControlledAxel] = [:]
    
    if  hasPan {
      result[.horizontal]=axelStatus[.headPan]
    }
    if hasTilt {
      result[.vertical]=axelStatus[.headTilt]
    }
    return result
  }
  
  public func slideObjects() -> [DegreeOfFreedom:JoystickControlledAxel] {
    var result:[DegreeOfFreedom:JoystickControlledAxel] = [:]
    
    if hasSlide {
      result[.horizontal]=axelStatus[.slide]
    }
    return result
  }
  
  public func joystickControlled() -> [AxelStatus] {
    var result:[AxelStatus] = []
    for (_, value) in axelStatus {
      if value.shouldMove{
        result.append(value)
      }
    }
    return result
  }
}
