/**
 PairingGroup.swift
 edelkroneAPI
 
 PairingGroup
 
 Created by Carsten Müller on 07.03.2022.
 Copyright © 2022 Carsten Müller. All rights reserved.
 */

import Foundation
import SwiftUI

public class PairingGroup: Identifiable,ObservableObject, Hashable{
  
  @Published public var groupedControlSystems:[MotionControlSystem] = []
  @Published public var groupID : Int = .noGroup // the default nogroup marker
  
  @Published public var groupMaster: MotionControlSystem?
  @Published public var isConnected:Bool = false
  
  public init(groupID: Int){
    self.groupID = groupID
  }
  
  public init(){
    self.groupID = Int.random(in: 1000...10000)
    var mcs = MotionControlSystem()
    mcs.groupID = self.groupID
    mcs.setup = "panTilt"
    mcs.deviceType = .headOne
    mcs.macAddress = "24:0A:C4:F2:9F:D2"
    self.groupedControlSystems.append(mcs)
    self.groupMaster = mcs
    
    
    mcs = MotionControlSystem()
    mcs.groupID = self.groupID
    mcs.setup = "groupMember"
    mcs.deviceType = .headOne
    mcs.isTilted = true
    mcs.macAddress = "24:0A:C4:F1:3B:AA"
    self.groupedControlSystems.append(mcs)
    
    
  }
  
  public static func == (lhs: PairingGroup, rhs: PairingGroup) -> Bool {
    lhs.groupID == rhs.groupID
  }
  
  public var id:Int {
    return groupID
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(groupID)
    for mcs in groupedControlSystems {
      hasher.combine(mcs)
    }
  }
  
  public func addMotionControlSystem(_ mcs: MotionControlSystem){
    if (mcs.groupID == self.groupID) && ( !groupedControlSystems.contains(mcs))  {
      groupedControlSystems.append(mcs)
      if MotionControlSystem.masterIndicator.contains(mcs.setup)  {
        groupMaster = mcs
      }
    }
  }
  
  public func removeMotionControlSystem(_ mcs:MotionControlSystem){
    if (mcs.groupID == self.groupID) || (mcs.groupID == .noGroup){
      groupedControlSystems.removeAll(where: {$0.macAddress == mcs.macAddress})
      if mcs == groupMaster {
        groupMaster = nil
      }
    }
  }
  public var isEmpty:Bool {
    get{
      return groupedControlSystems.isEmpty
    }
  }
}
