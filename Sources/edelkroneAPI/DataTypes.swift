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



