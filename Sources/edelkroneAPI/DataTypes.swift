/**
 DataTypes.swift
 edelkroneTest (macOS)
 
 Created by Carsten Müller on 04.03.22.
 Copyright © 2022 Carsten Müller. All rights reserved.
 */


import Foundation

public enum Preferences : String {
  case Hostname, Port, LinkAdapter
}

public struct DegreeOfFreedom:OptionSet, Hashable {
  public let rawValue: Int
  public static let none:DegreeOfFreedom = []
  public static let horizontal = DegreeOfFreedom(rawValue: 1)
  public static let vertical = DegreeOfFreedom(rawValue: 2)
  public static let all:DegreeOfFreedom = [.horizontal, .vertical]
  public init(rawValue:Int){
    self.rawValue = rawValue
  }
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.rawValue)
  }
  public func numberOfFreedoms() -> Int{
    var result:Int = 0
    if self.contains(.horizontal) {
      result+=1
    }
    if self.contains(.vertical) {
      result+=1
    }
    return result
  }
}

/// Devices of edelkrone
public enum EdelkroneDevice : String, Decodable{
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
      case .sliderOne:       fallthrough
      case .sliderOnePro:    fallthrough
      case .dollyOne:        fallthrough
      case .dollyPlus:      fallthrough
      case .dollyPlusPro:    result = false
      default:               result = true
      }
      return result
    }
  }
  
  public func toString() -> String {
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

public enum AxelID:String, Decodable, Comparable{
  
  case headPan, headTilt, slide, focus, jibPlusPan, jibPlusTilt
  
  public static func < (lhs: AxelID, rhs: AxelID) -> Bool {
    return lhs.value() < rhs.value()
  }
  
  public func value() -> Int{
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
  
  public func toString() -> String{
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
