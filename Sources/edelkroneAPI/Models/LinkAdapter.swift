/**
 LinkAdapter.swift
 edelkroneAPI
 
 LinkAdapter
 
 Created by Carsten Müller on 07.03.2022.
 Copyright © 2022 Carsten Müller. All rights reserved.
 */


import Foundation
import SwiftUI

public class LinkAdapter: Identifiable, Decodable, ObservableObject, Hashable{
  /// some informations about the firmware status if this link adapter
  public enum connectionTypes : String, Decodable{
    case none, canbus, wireless
  }
  public let updateAvailable   : Bool
  public let updateRequired     : Bool
  public let firmwareCorrupted : Bool?
  
  public let radioUpdateAvailable: Bool
  public let radioUpdateRequired : Bool
  
  /// a collection of connection types the linkAdapter uses
  public let connactionType : connectionTypes
  
  /// the epoc the adapter was found. This String is only set if the adapter is valid ->
  public let foundAt: String
  
  /// if this adapter is currently paired
  @Published public var isPaired : Bool
  @Published public var isConnected : Bool = false
  @Published public var isValid : Bool
  
  @Published public var id: String
  public var linkType : String
  public var portName: String
  
  
  // MARK: Hashable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
  
  // MARK: Equatable
  public static func == (lhs: LinkAdapter, rhs: LinkAdapter) -> Bool {
    return lhs.id == rhs.id
  }
  
  public init(){
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
  
  public required init(from decoder: Decoder) throws {
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
