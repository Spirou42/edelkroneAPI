/**
 MotionControlSystem.swift
 edelkroneAPI
 
 MotionControlSystem
 
 Created by Carsten Müller on 07.03.2022.
 Copyright © 2022 Carsten Müller. All rights reserved.
 */

import Foundation
import SwiftUI

public class MotionControlSystem: Decodable, Identifiable, ObservableObject, Hashable{
  /// ID of the associated Group if any. Value contains 65535 if not assigned
  @Published public var groupID: Int
  
  /// is true if MCS is paired through a canBus 3.2mm connector
  @Published public var linkPairigingActive: Bool
  
  /// is true if a HeadOne axis is tilted
  @Published public var isTilted: Bool
  /// fix for bug in AIP
  let k:Int
  
  /// the mac-address of the device
  @Published public var macAddress: String
  
  /// received signal strength indication
  @Published public var rssi: Int
  
  /// is true if a firmeware update is available
  @Published public var isFirmewareAvailabe: Bool
  
  /// is true if a radio firmware update is available
  @Published public var isRadioUpdateAvailable: Bool
  
  @Published public var useInPairing: Bool
  
  public var id:String{
    get {
      return macAddress
    }
  }
  
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(macAddress)
  }
  
  public static func == (lhs: MotionControlSystem, rhs: MotionControlSystem) -> Bool {
    return lhs.macAddress == rhs.macAddress
  }
  // List of String indication the MCS is a Group Master
  public static let masterIndicator = ["panOnly", "tiltOnly", "panTilt", "slideOnly", "dollyOnly", "panAndSlide", "tiltAndSlide", "panAndDolly",
                                "tiltAndDolly", "panTiltAndSlide", "panTiltAndDolly", "panAndJib", "tiltAndJib", "panTiltAndJib",
                                "jibOnly", "panAndJibPlus", "tiltAndJibPlus", "panTiltAndJibPlus", "jibPlusOnly", "followFocusOnly"]
  
  public static let memberIndicatores = ["groupMember"]
  
  public static let unpaierdIndicators = ["none", "possibleCanbusMaster"]
  /** if the device is a group master this variable contains the capabilities of the group encodeed as a string
   The data combines the possibilites of
   pan, tilt, slide, dolly, jib, jibPlus and followFocus
   There are a couple of combinations that cant be used together
   Dolly,  Slider, jib and jibPlus cant be combined together
   The possible values for a bundle master are:
   
   - panOnly
   - tiltOnly
   - panTilt
   - slideOnly
   - dollyOnly
   - panAndSlide
   - tiltAndSlide
   - panAndDolly
   - tiltAndDolly
   - panTiltAndSlide
   - panTiltAndDolly
   - panAndJib
   - tiltAndJib
   - panTiltAndJib
   - jibOnly
   - panAndJibPlus
   - tiltAndJibPlus
   - panTiltAndJibPlus
   - jibPlusOnly
   - followFocusOnly
   
   if the device is a bundle member the value is
   
   - groupMember
   
   In case the device is not paired yet the possible v aues are:
   
   - none
   - possibleCanbusMaster
   
   Other states are:
   
   - bootingUp
   - firmwareError
   */
  @Published public var setup: String
  
  /** Contains  the device Type of the MotionControlSystem
   
   The possible Values are:
   
   - slideModule      Slide Module v2
   - slideModuleV3      Slide Module v3
   - sliderOnePro      SliderONE PRO v2
   - sliderOne      SliderOne v2
   - dollyPlus      Dolly Plus
   - dollyOne      DollyONE
   - dollyPlusPro      DollyPLUS PRO
   - panPro      PanPRO
   - headOne      HeadONE
   - headPlus      HeadPLUS v1
   - headPlusPro      HeadPLUS v1 PRO
   - headPlusV2      HeadPLUS v2
   - headPlusProV2      HeadPLUS v2 PRO
   - focusPlusPro      FocusPLUS PRO
   - jibOne      JibONE
   */
  
  
  @Published public var deviceType: EdelkroneDevice
  
  public init(){
    groupID = 65535
    linkPairigingActive = false
    isTilted = false
    macAddress = "aa:33:3a:f3:b4:4e"
    rssi = 5
    isFirmewareAvailabe = false
    isRadioUpdateAvailable = false
    setup="none"
    deviceType = .headOne
    isTilted = false
    k=0
    useInPairing = false
  }
  
  public required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    groupID = try container.decode(Int.self, forKey: .groupID)
    linkPairigingActive = ((try? container.decode(Bool.self, forKey: .linkPairigingActive)) != nil)
    
    k = (try? container.decode(Int.self, forKey: .k)) ?? 0
    isTilted = k==1
    
    macAddress = try container.decode(String.self, forKey: .macAddress)
    rssi = try container.decode(Int.self, forKey: .rssi)
    isFirmewareAvailabe = try container.decode(Bool.self, forKey: .isFirmewareAvailabe)
    isRadioUpdateAvailable = try container.decode(Bool.self, forKey: .isRadioUpdateAvailable)
    setup = try container.decode(String.self, forKey: .setup)
    deviceType = try container.decode(EdelkroneDevice.self, forKey: .deviceType)
    useInPairing = false
  }
  
  enum CodingKeys: String, CodingKey{
    case groupID = "groupId"
    case linkPairigingActive = "linkPairigingActive"
    case k = "isTilted"
    case macAddress = "mac"
    case rssi = "rssi"
    case isFirmewareAvailabe = "isDeviceFirmwareUpdateAvailable"
    case isRadioUpdateAvailable = "isRadioFirmwareUpdateAvailable"
    case setup = "setup"
    case deviceType = "type"
  }
}

