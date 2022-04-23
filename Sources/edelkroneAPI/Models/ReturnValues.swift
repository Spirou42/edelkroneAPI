/**
 ReturnValues.swift
 edelkroneAPI
 
 ReturnValues
 
 Created by Carsten Müller on 07.03.2022.
 Copyright © 2022 Carsten Müller. All rights reserved.
 */

import Foundation

public protocol ApiResult: Decodable{
  var result: String{get}
  var message:String?{get}
}

public struct ResultWrapper<T: Decodable>: Decodable,ApiResult{
  public let data: T?
  public let result: String
  public let message: String?
}


public struct ResultArrayWrapper<T: Decodable>: Decodable,ApiResult{
  public let data: [T]?
  public let result: String
  public let message: String?
}


// MARK: Default Returns

public struct DefaultReturns: Decodable,ApiResult{
  public var result:String
  public var message:String?
  
  enum CodingKeys: String, CodingKey{
    case result, message
  }
}

// MARK: PairingStatus
public struct PairingStatus:Decodable{
  public enum pairingState:String,Decodable{
    case idle,connecting,connectionOk,problem
  }
  public var lastPairError: String
  public var pairState: pairingState
  
  enum CodingKeys:String, CodingKey{
    case lastPairError
    case pairState = "wirelessPairState"
  }
}

// MARK: PairingStatusReturn
public struct PairingStatusReturn:Decodable, ApiResult{
  public var result: String
  public var message: String?
  public let status: PairingStatus?
  
  enum CodingKeys:String, CodingKey{
    case result, message,status="data"
  }
}


public protocol AxelDescription {
  var axelName: AxelID { get }
  var device: EdelkroneDevice { get }
  
}

public struct AxelIdentifier:AxelDescription, Decodable, Hashable, Equatable, Identifiable{
  public var id: ObjectIdentifier = ObjectIdentifier(AxelIdentifier.self)
  
  public let axelName: AxelID
  public let device: EdelkroneDevice
  enum CodingKeys: String, CodingKey{
    case axelName = "axis",device
  }
  public func hash(into hasher: inout Hasher) {
    hasher.combine(axelName)
  }
  
  public static func == (lhs: AxelIdentifier, rhs: AxelIdentifier) -> Bool {
    return lhs.axelName == rhs.axelName
  }
}

public struct BundledDeviceInfo:Decodable, Equatable{
  public let batteryLevel:Double
  public let isTilted:Bool?
  public let device:EdelkroneDevice
  enum CodingKeys:String,CodingKey{
    case batteryLevel, isTilted, device="type"
  }
  public static func == (lhs: BundledDeviceInfo, rhs:BundledDeviceInfo) -> Bool{
    return (lhs.batteryLevel == rhs.batteryLevel) && (lhs.device == rhs.device) && (lhs.isTilted == rhs.isTilted)
  }
}

public enum MotionState:String, Decodable{
  case idle, keyposeMove, realTimeMove, focusCalibration, sliderCalibration, joystickMove, unsupportedActivity
  
  public func toString() -> String {
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
public class PeriodicStatus: Decodable{
  public var calibratedAxes:[AxelIdentifier] = []
  public var deviceInfo:[BundledDeviceInfo] = []
  public var deviceInfoReady:Bool = false
  
  public var keyposeLoopActive:Bool = false
  public var keyposeMotionAimIndex: Int = -1
  public var keyposeMotionStartIndex: Int = -1
  public var keyposeSlotsFilled:[Bool] = []
  //
  public var plannedMotionProgress: Double = 0.0
  public var plannedMotionDuration: Double = 0.0
  public var readings:[AxelID:Double] = [:]
  //
  public var realTimeSupportedAxes: [AxelIdentifier] = []
  public var state:MotionState = .idle
  public var supportedAxes:[AxelIdentifier] = []
  //
  public var timestampDevice: Int64
  public var timestampEpoch: Int64
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
  
  public init(){
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
  
  public required init(from decoder: Decoder) throws {
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
  public func deviceFor(name: AxelID) -> EdelkroneDevice{
    for axel in supportedAxes {
      if axel.axelName == name{
        return axel.device
      }
    }
    return .unknown
  }
  
  public func positionFor(name: AxelID) -> Double{
    if readings.keys.contains(name) {
      return readings[name]!
    }
    return 0.0
  }
  public func calibrationStateFor(name:AxelID) -> Bool {
    if deviceInfoReady {
      for axel in calibratedAxes {
        if axel.axelName == name {
          return true
        }
      }
    }
    return false
  }
  
  public func batteryLevelFor(name: AxelID) -> Double {
    if deviceInfoReady {
      for k in 0..<supportedAxes.count {
        if supportedAxes[k].axelName == name {
          return deviceInfo[k].batteryLevel
        }
      }
    }
    return 0.0
  }
  
  
  public static func &= (lhs:PeriodicStatus,rhs:PeriodicStatus){
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

public struct PeriodicStatusReturn: Decodable, ApiResult{
  public var result: String
  public var message: String?
  public let status: PeriodicStatus
  enum CodingKeys:String, CodingKey{
    case result, message, status = "data"
  }
}
