/**
 
 Keypose.swift
 edelkroneAPI
 
 Keypose slot and Keypose container
 
 Created by Carsten Müller on 20.04.22.
 Copyright © 2022 Carsten Müller. All rights reserved.
 */

import Foundation
import SwiftUI

/// a single axel for a keypose
public class KeyposeAxel: ObservableObject, Hashable{
  
  
  @Published public var axelName:AxelID
  @Published public var axelPosition:Double
  
  @Published public var device:EdelkroneDevice
  
  @Published public var calibrated:Bool
  public var needsCalibration:Bool {
    get {
      self.objectWillChange.send()
      return  (self.calibrated == false) && device.canCalibrate
    }
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(axelName)
  }
  
  required public init(_ name:AxelID = AxelID.slide,
                       _ position:Double = 0.0,
                       _ device:EdelkroneDevice = .sliderOne){
    self.axelName = name
    self.axelPosition = position
    self.calibrated = false
    self.device = device
  }
  
  public init(_ status:AxelStatus){
    self.axelName = status.axelName
    self.axelPosition = status.position
    
    self.device = status.device
    self.calibrated = status.calibrated
  }
  
  public static func == (lhs: KeyposeAxel, rhs: KeyposeAxel) -> Bool {
    return (lhs.axelName == rhs.axelName) && (lhs.device == rhs.device)
  }
  
}

/// a single slot in a keypose
public class KeyposeSlot: ObservableObject, Hashable{
  @Published public var index:Int
  @Published public var axels:[AxelID:KeyposeAxel?]
  
  required public init(_ idx:Int = 0, status:MotionControlStatus){
    self.index = idx
    axels = [:]
    for (key, value) in status.axelStatus {
      let axel = KeyposeAxel(value)
      axels[key] = axel
    }
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(index)
  }
  
  public static func == (lhs:KeyposeSlot, rhs:KeyposeSlot) -> Bool {
    return lhs.index == rhs.index
  }
  
}

public class KeyposeContainer:ObservableObject{
  @Published public var slots:[Int:KeyposeSlot?]
  
  static public func += (lhs: KeyposeContainer, rhs:ResultWrapper<Dictionary<String,Double>>){
    
  }
  
  required public init(_ maxSlots:Int=6){
    slots=[:]
    for k in 0..<maxSlots {
      self.slots[k] = nil
    }
  }
  
  public init(_ status:MotionControlStatus){
    slots = [:]
    for idx in 0..<status.filledKeypose.count {
      let slot = KeyposeSlot(idx, status: status)
      slots[idx] = slot
    }
  }
}
