/**
 edelkroneModels.swift
 edelkroneTest
 
 Containing basic models for api results
 
 Created by Carsten Müller on 07.03.2022.
 Copyright © 2022 Carsten Müller. All rights reserved.
 */

import Foundation
import SwiftUI

// MARK: - LinkAdapter
class LinkAdapter: Identifiable, Decodable, ObservableObject, Hashable{
  /// some informations about the firmware status if this link adapter
  enum connectionTypes : String, Decodable{
    case none, canbus, wireless
  }
  let updateAvailable 	: Bool
  let updateRequired 		: Bool
  let firmwareCorrupted : Bool?
  
  let radioUpdateAvailable: Bool
  let radioUpdateRequired : Bool
  
  /// a collection of connection types the linkAdapter uses
  let connactionType : connectionTypes
  
  /// the epoc the adapter was found. This String is only set if the adapter is valid ->
  let foundAt: String
  
  /// if this adapter is currently paired
  @Published var isPaired : Bool
  @Published var isConnected : Bool = false
  @Published var isValid : Bool
  
  @Published var id: String
  var linkType : String
  var portName: String
  
  
  // MARK: Hashable
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
  
  // MARK: Equatable
  static func == (lhs: LinkAdapter, rhs: LinkAdapter) -> Bool {
    return lhs.id == rhs.id
  }
  
  
  init(){
    updateAvailable = false
    updateRequired = true
    firmwareCorrupted = false
    radioUpdateRequired = false
    radioUpdateAvailable = false
    connactionType = .none
    foundAt = "1233"
    isPaired = false
    isConnected = true
    isValid = true
    id="204338635631"
    linkType = "linkAdapter"
    portName = "/dev/cu.usbmodem2043386356311"
  }
  
  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    updateAvailable = try container.decode(Bool.self, forKey: .updateAvailable)
    updateRequired = try container.decode(Bool.self, forKey: .updateRequired)
    firmwareCorrupted = try? container.decode(Bool.self, forKey: .firmwareCorrupted)
    radioUpdateRequired = try container.decode(Bool.self, forKey: .radioUpdateRequired)
    radioUpdateAvailable = try container.decode(Bool.self, forKey: .radioUpdateAvailable)
    connactionType = try container.decode(connectionTypes.self, forKey: .connactionType)
    foundAt = try container.decode(String.self, forKey: .foundAt)
    isPaired = try container.decode(Bool.self, forKey: .isPaired)
    isConnected = false
    isValid = try container.decode(Bool.self, forKey: .isValid)
    id = try container.decode(String.self, forKey: .id)
    linkType = try container.decode(String.self, forKey: .linkType)
    portName = try container.decode(String.self, forKey: .portName)
  }
  
  enum CodingKeys: String, CodingKey {
    case updateAvailable = "isDeviceFirmwareUpdateAvailable"
    case updateRequired = "isDeviceFirmwareUpdateRequired"
    case firmwareCorrupted = "isFirmwareCorrupted"
    case radioUpdateAvailable = "isRadioFirmwareUpdateAvailable"
    case radioUpdateRequired = "isRadioFirmwareUpdateRequired"
    case connactionType = "linkConnectionType"
    case foundAt = "initialFoundEpoch"
    case isPaired = "isPairingDone"
    case isValid = "isValid"
    case id = "linkID"
    case linkType = "linkType"
    case portName = "portName"
  }
  
}

/// Devices of edelkrone
enum EdelkroneDevice : String, Decodable{
  case slideModule
  case slideModuleV3
  case sliderOnePro
  case sliderOne
  case dollyPlus
  case dollyOne
  case dollyPlusPro
  case panPro
  case headOne
  case headPlus
  case headPlusPro
  case headPlusV2
  case headPlusProV2
  case focusPlusPro
  case jibOne
  case unknown
  
  var canCalibrate:Bool {
    get {
      var result:Bool = true
      switch self {
      case .sliderOne:     	fallthrough
      case .sliderOnePro:  	fallthrough
      case .dollyOne:				fallthrough
      case .dollyPlus:			fallthrough
      case .dollyPlusPro:		result = false
      default:               result = true
      }
      return result
    }
  }
  
  func toString() -> String {
    switch self {
    case .slideModule:
      return "Slide Module v2"
    case .slideModuleV3:
      return "Slide Module v3"
    case .sliderOnePro:
      return "SliderONE PRO v2"
    case .sliderOne:
      return "SliderONE v2"
    case .dollyPlus:
      return "DollyPLUS"
    case .dollyOne:
      return "DollyONE"
    case .dollyPlusPro:
      return "DollyPLUS PRO"
    case .panPro:
      return "PanPRO"
    case .headOne:
      return "HeadONE"
    case .headPlus:
      return "HeadPLUS v1"
    case .headPlusPro:
      return "HeadPLUS v1 PRO"
    case .headPlusV2:
      return "HeadPLUS v2"
    case .headPlusProV2:
      return "HeadPLUS v2 PRO"
    case .focusPlusPro:
      return "FocusPLUS PRO"
    case .jibOne:
      return "JibONE"
    case .unknown:
      return "Unknown"
      
      
    }
    
  }
}


// MARK: - MotionControlSystem

class MotionControlSystem: Decodable, Identifiable, ObservableObject, Hashable{
  /// ID of the associated Group if any. Value contains 65535 if not assigned
  @Published var groupID: Int
  
  /// is true if MCS is paired through a canBus 3.2mm connector
  @Published var linkPairigingActive: Bool
  
  /// is true if a HeadOne axis is tilted
  @Published var isTilted: Bool
  /// fix for bug in AIP
  let k:Int
  
  /// the mac-address of the device
  @Published var macAddress: String
  
  /// received signal strength indication
  @Published var rssi: Int
  
  /// is true if a firmeware update is available
  @Published var isFirmewareAvailabe: Bool
  
  /// is true if a radio firmware update is available
  @Published var isRadioUpdateAvailable: Bool
  
  @Published var useInPairing: Bool
  
  var id:String{
    get {
      return macAddress
    }
  }
  
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(macAddress)
  }
  
  static func == (lhs: MotionControlSystem, rhs: MotionControlSystem) -> Bool {
    return lhs.macAddress == rhs.macAddress
  }
  // List of String indication the MCS is a Group Master
  static let masterIndicator = ["panOnly", "tiltOnly", "panTilt", "slideOnly", "dollyOnly", "panAndSlide", "tiltAndSlide", "panAndDolly",
                                "tiltAndDolly", "panTiltAndSlide", "panTiltAndDolly", "panAndJib", "tiltAndJib", "panTiltAndJib",
                                "jibOnly", "panAndJibPlus", "tiltAndJibPlus", "panTiltAndJibPlus", "jibPlusOnly", "followFocusOnly"]
  
  static let memberIndicatores = ["groupMember"]
  
  static let unpaierdIndicators = ["none", "possibleCanbusMaster"]
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
  @Published var setup: String
  
  /** Contains  the device Type of the MotionControlSystem
   
   The possible Values are:
   
   - slideModule			Slide Module v2
   - slideModuleV3			Slide Module v3
   - sliderOnePro			SliderONE PRO v2
   - sliderOne			SliderOne v2
   - dollyPlus			Dolly Plus
   - dollyOne			DollyONE
   - dollyPlusPro			DollyPLUS PRO
   - panPro			PanPRO
   - headOne			HeadONE
   - headPlus			HeadPLUS v1
   - headPlusPro			HeadPLUS v1 PRO
   - headPlusV2			HeadPLUS v2
   - headPlusProV2			HeadPLUS v2 PRO
   - focusPlusPro			FocusPLUS PRO
   - jibOne			JibONE
   */
  
  
  @Published var deviceType: EdelkroneDevice
  
  init(){
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
  
  required init(from decoder: Decoder) throws {
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


// MARK: - PairingGroup
class PairingGroup: Identifiable,ObservableObject, Hashable{
  
  @Published var groupedControlSystems:[MotionControlSystem] = []
  @Published var groupID : Int = .noGroup // the default nogroup marker
  
  @Published var groupMaster: MotionControlSystem?
  @Published var isConnected:Bool = false
  
  init(groupID: Int){
    self.groupID = groupID
  }
  
  init(){
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
  
  static func == (lhs: PairingGroup, rhs: PairingGroup) -> Bool {
    lhs.groupID == rhs.groupID
  }
  
  var id:Int {
    return groupID
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(groupID)
    for mcs in groupedControlSystems {
      hasher.combine(mcs)
    }
  }
  
  func addMotionControlSystem(_ mcs: MotionControlSystem){
    if (mcs.groupID == self.groupID) && ( !groupedControlSystems.contains(mcs))  {
      groupedControlSystems.append(mcs)
      if MotionControlSystem.masterIndicator.contains(mcs.setup)  {
        groupMaster = mcs
      }
    }
  }
  
  func removeMotionControlSystem(_ mcs:MotionControlSystem){
    if (mcs.groupID == self.groupID) || (mcs.groupID == .noGroup){
      groupedControlSystems.removeAll(where: {$0.macAddress == mcs.macAddress})
      if mcs == groupMaster {
        groupMaster = nil
      }
    }
  }
  var isEmpty:Bool {
    get{
      return groupedControlSystems.isEmpty
    }
  }
}

// MARK: - Paired Motion Control System Descriptions

enum AxelID:String, Decodable, Comparable{

  case headPan, headTilt, slide, focus, jibPlusPan, jibPlusTilt
  
  static func < (lhs: AxelID, rhs: AxelID) -> Bool {
    return lhs.value() < rhs.value()
  }
  
  func value() -> Int{
    switch self {
    case .headPan: fallthrough
    case .jibPlusPan:
      return 0
    case .headTilt: fallthrough
    case .jibPlusTilt:
      return 1
    case .slide:
      return 2
    case .focus:
      return 3
    }
  }
  
  func toString() -> String{
    switch self {
    case .headPan:
      return "Pan"
    case .headTilt:
      return "Tilt"
    case .slide:
      return "Slide"
    case .focus:
      return "Focus"
    case .jibPlusPan:
      return "JibPan"
    case .jibPlusTilt:
      return "JibTilt"
    }
  }
}



class AxelStatus : AxelDescription, Hashable, Equatable, Identifiable, ObservableObject, JoystickControlledAxel {
  
  var id: AxelID{
    get{
      return axelName
    }
  }
  
  @Published var axelName: AxelID
  @Published var device:EdelkroneDevice
  
  @Published var calibrated:Bool
  var needsCalibration:Bool {
    get {
      self.objectWillChange.send()
      return  (self.calibrated == false) && device.canCalibrate
    }
  }
  @Published var position: Double
  @Published var batteryLevel: Double
  
  var shouldMove: Bool = false
  var isLastMove: Bool = true
  var moveValue: Double = 0.0
  
  
  static func == (lhs:AxelStatus, rhs:AxelStatus) -> Bool{
    return lhs.axelName == rhs.axelName
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(axelName)
  }
  
  init(from: PeriodicStatus, forName:AxelID){
    axelName = forName
    device = from.deviceFor(name:forName)
    position = from.positionFor(name:forName)
    calibrated = from.calibrationStateFor(name:forName)
    batteryLevel = from.batteryLevelFor(name: forName)
  }
  
  func update(from: PeriodicStatus){
    device = from.deviceFor(name:axelName)
    position = from.positionFor(name:axelName)
    calibrated = from.calibrationStateFor(name: axelName)
    batteryLevel = from.batteryLevelFor(name: axelName)
  }
}

// MARK: - MotionControlStatus
class MotionControlStatus: ObservableObject {
  @Published var axelStatus:[AxelID : AxelStatus] = [:]
  
  @Published var keyposeLoopActive:Bool = false
  @Published var keyposeTargetIndex: Int = 0
  @Published var keyposeStartIndex: Int = -1
  @Published var keyposeMotionProgress: Double = 1.0
  @Published var keyposeMotionDuration: Double = 0.0
  @Published var state:MotionState = .idle

  static func &= (lhs:MotionControlStatus, rhs:PeriodicStatus){
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
  }
  
  init(){
    let t = PeriodicStatus()
    self &= t
  }
  
  var hasTilt:Bool {
    get{
      return axelStatus.keys.contains(.headTilt) || axelStatus.keys.contains(.jibPlusTilt)
    }
  }
  
  var hasPan:Bool {
    get{
      return  axelStatus.keys.contains(.headPan) || axelStatus.keys.contains(.jibPlusPan)
    }
  }
  
  var hasSlide:Bool {
    get {
      return axelStatus.keys.contains(.slide)
    }
  }
  var hasFocus:Bool {
    get {
      return axelStatus.keys.contains(.focus)
    }
  }
  func panTiltObjects() -> [DegreeOfFreedom:JoystickControlledAxel] {
    var result:[DegreeOfFreedom:JoystickControlledAxel] = [:]
    
    if  hasPan {
      result[.horizontal]=axelStatus[.headPan]
    }
    if hasTilt {
      result[.vertical]=axelStatus[.headTilt]
    }
    return result
  }
  
  func slideObjects() -> [DegreeOfFreedom:JoystickControlledAxel] {
    var result:[DegreeOfFreedom:JoystickControlledAxel] = [:]
    
    if hasSlide {
      result[.horizontal]=axelStatus[.slide]
    }
    return result
  }
  
  func joystickControlled() -> [AxelStatus] {
    var result:[AxelStatus] = []
    for (_, value) in axelStatus {
      if value.shouldMove{
        result.append(value)
      }
    }
    return result
  }
}




// MARK: - Return Results

protocol ApiResult: Decodable{
  var result: String{get}
  var message:String?{get}
}

struct ResultArrayWrapper<T: Decodable>: Decodable,ApiResult{
  let data: [T]?
  let result: String
  let message: String?
}


// MARK: Default Returns

struct DefaultReturns: Decodable,ApiResult{
  var result:String
  var message:String?
  
  enum CodingKeys: String, CodingKey{
    case result, message
  }
}

// MARK: PairingStatus
struct PairingStatus:Decodable{
  enum pairingState:String,Decodable{
    case idle,connecting,connectionOk,problem
  }
  var lastPairError: String
  var pairState: pairingState
  
  enum CodingKeys:String, CodingKey{
    case lastPairError
    case pairState = "wirelessPairState"
  }
}

// MARK: PairingStatusReturn
struct PairingStatusReturn:Decodable, ApiResult{
  var result: String
  var message: String?
  let status: PairingStatus?
  
  enum CodingKeys:String, CodingKey{
    case result, message,status="data"
  }
}


protocol AxelDescription {
  var axelName: AxelID { get }
  var device: EdelkroneDevice { get }
  
}

struct AxelIdentifier:AxelDescription, Decodable, Hashable, Equatable, Identifiable{
  var id: ObjectIdentifier = ObjectIdentifier(AxelIdentifier.self)
  
  let axelName: AxelID
  let device: EdelkroneDevice
  enum CodingKeys: String, CodingKey{
    case axelName = "axis",device
  }
  func hash(into hasher: inout Hasher) {
    hasher.combine(axelName)
  }
  
  static func == (lhs: AxelIdentifier, rhs: AxelIdentifier) -> Bool {
    return lhs.axelName == rhs.axelName
  }
}

struct BundledDeviceInfo:Decodable, Equatable{
  let batteryLevel:Double
  let isTilted:Bool?
  let device:EdelkroneDevice
  enum CodingKeys:String,CodingKey{
    case batteryLevel, isTilted, device="type"
  }
  static func == (lhs: BundledDeviceInfo, rhs:BundledDeviceInfo) -> Bool{
    return (lhs.batteryLevel == rhs.batteryLevel) && (lhs.device == rhs.device) && (lhs.isTilted == rhs.isTilted)
  }
}

enum MotionState:String, Decodable{
  case idle, keyposeMove, realTimeMove, focusCalibration, sliderCalibration, joystickMove, unsupportedActivity
  
  func toString() -> String {
    switch self {
    case .idle: return "Idle"
    case .keyposeMove: return "move to Keypose"
    case .realTimeMove: return "realtime move"
    case .focusCalibration: return "calibrate Focus"
    case .sliderCalibration: return "calibrate Slider"
    case .joystickMove: return "Joystick move"
    case .unsupportedActivity: return "unsupported"
    }
  }
}
// MARK: - Periodic Status

class PeriodicStatus: Decodable{
  var calibratedAxes:[AxelIdentifier] = []
  var deviceInfo:[BundledDeviceInfo] = []
  var deviceInfoReady:Bool = false
  
  var keyposeLoopActive:Bool = false
  var keyposeMotionAimIndex: Int = -1
  var keyposeMotionStartIndex: Int = -1
  var keyposeSlotsFilled:[Bool] = []
  //
  var plannedMotionProgress: Double = 0.0
  var plannedMotionDuration: Double = 0.0
  var readings:[AxelID:Double] = [:]
  //
  var realTimeSupportedAxes: [AxelIdentifier] = []
  var state:MotionState = .idle
  var supportedAxes:[AxelIdentifier] = []
  //
  var timestampDevice: Int64
  var timestampEpoch: Int64
  //
  enum CodingKeys:String, CodingKey{
    case calibratedAxes
    case deviceInfo
    case deviceInfoReady = "deviceInfoEverythingReady"
    case keyposeLoopActive, keyposeMotionAimIndex, keyposeMotionStartIndex, keyposeSlotsFilled
    case plannedMotionProgress, plannedMotionDuration, readings
    case realTimeSupportedAxes, state, supportedAxes
    case timestampDevice, timestampEpoch
    
  }
  
  init(){
    let json="""
    {
      "data": {
        "calibratedAxes": [
          {
            "axis": "slide",
            "device": "sliderOne"
          }
        ],
        "deviceInfo": [
          {
            "batteryLevel": 0.1,
            "isTilted": false,
            "type": "headOne"
          },
          {
            "batteryLevel": 0.2,
            "isTilted": true,
            "type": "headOne"
          },
          {
            "batteryLevel": 0.5,
            "type": "sliderOne"
          }
        ],
        "deviceInfoEverythingReady": true,
        "keyposeLoopActive": false,
        "keyposeMotionAimIndex": 0,
        "keyposeMotionStartIndex": 0,
        "keyposeSlotsFilled": [
          false,
          false,
          false,
          false,
          false,
          false
        ],
        "plannedMotionDuration": 0.0,
        "plannedMotionProgress": 1.0,
        "readings": {
          "headPan": 90.01300048828125,
          "headTilt": 89.98899841308594,
          "slide": 0.0
        },
        "realTimeSupportedAxes": [
    
        ],
        "state": "idle",
        "supportedAxes": [
          {
            "axis": "headPan",
            "device": "headOne"
          },
          {
            "axis": "headTilt",
            "device": "headOne"
          },
          {
            "axis": "slide",
            "device": "sliderOne"
          }
        ],
        "timestampDevice": 3631580,
        "timestampEpoch": 1648073281431
      },
      "result": "ok"
    }
    """
    let data = json.data(using: .utf8) ?? Data()
    
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .secondsSince1970
    
    
    let returns = try? decoder.decode(PeriodicStatusReturn.self, from: data)
    timestampDevice = 0
    timestampEpoch = 0
    
    self &= returns!.status
  }
  
  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    calibratedAxes = try container.decode([AxelIdentifier].self, forKey: .calibratedAxes)
    deviceInfo = try container.decode([BundledDeviceInfo].self, forKey: .deviceInfo)
    deviceInfoReady = try container.decode(Bool.self, forKey: .deviceInfoReady)
    
    keyposeLoopActive = try container.decode(Bool.self, forKey: .keyposeLoopActive)
    keyposeMotionAimIndex = try container.decode(Int.self, forKey: .keyposeMotionAimIndex)
    keyposeMotionStartIndex = try container.decode(Int.self, forKey: .keyposeMotionStartIndex)
    keyposeSlotsFilled = try container.decode([Bool].self, forKey: .keyposeSlotsFilled)
    
    plannedMotionDuration = try container.decode(Double.self, forKey: .plannedMotionDuration)
    plannedMotionProgress = try container.decode(Double.self, forKey: .plannedMotionProgress)
    
    let tempReadings = try container.decode([String:Double].self, forKey: .readings)
    var qreadings:[AxelID:Double] = [:]
    for k in tempReadings.keys{
      let q:AxelID = AxelID(rawValue:k) ?? .headPan
      qreadings[q] = tempReadings[k]
    }
    readings = qreadings
    
    realTimeSupportedAxes = try container.decode([AxelIdentifier].self, forKey: .realTimeSupportedAxes)
    
    state = try container.decode(MotionState.self, forKey: .state)
    
    supportedAxes = try container.decode([AxelIdentifier].self, forKey: .supportedAxes)
    timestampEpoch = try container.decode(Int64.self, forKey: .timestampEpoch)
    timestampDevice = try container.decode(Int64.self, forKey: .timestampDevice)
  }
  
  /// some access methods
  func deviceFor(name: AxelID) -> EdelkroneDevice{
    for axel in supportedAxes {
      if axel.axelName == name{
        return axel.device
      }
    }
    return .unknown
  }
  
  func positionFor(name: AxelID) -> Double{
    if readings.keys.contains(name) {
      return readings[name]!
    }
    return 0.0
  }
  func calibrationStateFor(name:AxelID) -> Bool {
    if deviceInfoReady {
      for axel in calibratedAxes {
        if axel.axelName == name {
          return true
        }
      }
    }
    return false
  }
  
  func batteryLevelFor(name: AxelID) -> Double {
    if deviceInfoReady {
      for k in 0..<supportedAxes.count {
        if supportedAxes[k].axelName == name {
          return deviceInfo[k].batteryLevel
        }
      }
    }
    return 0.0
  }
  
  
  static func &= (lhs:PeriodicStatus,rhs:PeriodicStatus){
    if lhs.calibratedAxes != rhs.calibratedAxes{
      lhs.calibratedAxes = rhs.calibratedAxes
    }
    if lhs.deviceInfo != rhs.deviceInfo{
      lhs.deviceInfo = rhs.deviceInfo
    }
    
    if lhs.deviceInfoReady != rhs.deviceInfoReady{
      lhs.deviceInfoReady = rhs.deviceInfoReady
    }
    
    if lhs.keyposeLoopActive != rhs.keyposeLoopActive{
      lhs.keyposeLoopActive = rhs.keyposeLoopActive
    }
    
    if lhs.keyposeMotionAimIndex != rhs.keyposeMotionAimIndex{
      lhs.keyposeMotionAimIndex = rhs.keyposeMotionAimIndex
    }
    
    if lhs.keyposeMotionStartIndex != rhs.keyposeMotionStartIndex{
      lhs.keyposeMotionStartIndex = rhs.keyposeMotionStartIndex
    }
    
    if lhs.keyposeSlotsFilled != rhs.keyposeSlotsFilled{
      lhs.keyposeSlotsFilled = rhs.keyposeSlotsFilled
    }
    
    if lhs.plannedMotionProgress != rhs.plannedMotionProgress{
      lhs.plannedMotionProgress = rhs.plannedMotionProgress
    }
    
    if lhs.plannedMotionDuration != rhs.plannedMotionDuration{
      lhs.plannedMotionDuration = rhs.plannedMotionDuration
    }
    
    if lhs.readings != rhs.readings {
      lhs.readings = rhs.readings
    }
    
    if lhs.realTimeSupportedAxes != rhs.realTimeSupportedAxes{
      lhs.realTimeSupportedAxes = rhs.realTimeSupportedAxes
    }
    if lhs.state != rhs.state{
      lhs.state = rhs.state
    }
    if lhs.supportedAxes != rhs.supportedAxes{
      lhs.supportedAxes = rhs.supportedAxes
    }
    
    //    if lhs.timestampEpoch != rhs.timestampEpoch{
    //      lhs.timestampEpoch = rhs.timestampEpoch
    //    }
    //    if lhs.timestampDevice != rhs.timestampDevice{
    //      lhs.timestampDevice = rhs.timestampDevice
    //    }
  }
}

struct PeriodicStatusReturn: Decodable, ApiResult{
  var result: String
  var message: String?
  let status: PeriodicStatus
  enum CodingKeys:String, CodingKey{
    case result, message, status = "data"
  }
}
