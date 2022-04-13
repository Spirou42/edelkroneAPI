/**
 edelkroneAPI.swift
 edelkroneTest
 
 Created by Carsten Müller on 04.03.2022.
 Copyright © 2022 Carsten Müller. All rights reserved.
 */

import Foundation
import SwiftUI

protocol commandEnum {}

protocol edelkroneNetwork{
  func executeSession<T:ApiResult>(request: URLRequest, uploadData: Data, with:@escaping (Bool, T?, Any?)->Void, context: Any?) -> Void
  func getCommand(_ command :String ) -> Dictionary<String, Any>
  func commandToJSON(_commandDict: Dictionary<String, Any>) -> Data?
  func getURL(adapterID:String, type:edelkroneAPI.requestType)->URL?
  func getURL(adapter:LinkAdapter,  type:edelkroneAPI.requestType)->URL?
  func getURL(_ type: edelkroneAPI.requestType ) -> URL?
}

// MARK: - edelkroneAPI -

/**
 encapsulates the edelkrone API calls and is the single point of information for the application.
 */
class edelkroneAPI : ObservableObject{
  static let shared = edelkroneAPI()
  
  /// Model for a single edelkrone LinkAdapter
  
  enum commands : String, commandEnum {
    enum pairing {
      enum wireless : String, commandEnum {
        case scanStart = "wirelessPairingScanStart",
             scanResults = "wirelessPairingScanResults",
             createBundle = "wirelessPairingCreateBundle",
             attachToBundle = "wirelessPairingAttachToBundle",
             status = "wirelessPairingStatus",
             disconnect
      }
      enum linked : String, commandEnum {
        case scanResults = "link2PairingScanResults",
             connect = "link2PairingConnect",
             status = "link2PairingStatus",
             disconnect
      }
    }
    enum keypose : String, commandEnum {
      case storeCurrentPose = "keyposeStoreCurrentPose",
           storeWithNumericData = "keyposeStoreWithNumericData",
           moveFixedDuration = "keyposeMoveFixedDuration",
           moveFixedSpeed = "keyposeMoveFixedSpeed",
           loopFixedDuration = "keyposeLoopFixedDuration",
           loopFixedSpeed = "keyposeLoopFixedSpeed",
           readNumericValues = "keyposeReadNumericValues",
           delete  = "keyposeDeletePose"
    }
    enum realTimeMove : String, commandEnum {
      case fixedDuration = "realTimeMoveFixedDuration"
    }
    case joystickMove = "joystickMove"
    case focusMove = "focusManualMove"
    case motionAbort = "motionAbort"
    case calibrate = "calibrate"
    case status = "status"
    enum link : String, commandEnum {
      case status = "linkStatus",
           detect = "detect"
      // the firmeware update command like: startLinkDeviceFirmwareUpdate, linkDeviceFirmwareUpdateStatus, startLinkRadioFirmwareUpdate, linkRadioFirmwarUpdateStatus are unsuported
    }
    case shutter = "shutterTrigger"
  }
  
  enum requestType : String {
    case link, bundle, device
  }
  
  enum ConnectionState : String {
    case presentLinkAdapters
    case pairMotionControlSystems
    case showMotionControlInterface
  }
  /// Array, containing all found LinkAdapters
  @Published var scannedLinkAdapters:[LinkAdapter] = []    // list of deteced LinkAdapters
  
  /// Array containing all scanned MCSs
  @Published var scannedMotionControlSystems:[MotionControlSystem] = []
  
  /// Array containing all ungrouped MCSs
  @Published var ungroupedMotionControlSystems:[MotionControlSystem] = []
  
  /// Array of all PairingGroups
  @Published var motionControlGroups:[PairingGroup] = []
  
  /// the Adapters organised by LinkID
  @Published var adaptertDict:[String:LinkAdapter] = [:]
  
  /// MotionControlSystems organised by mcaAddress
  @Published var motionControlSystemsDict:[String:MotionControlSystem] = [:]
  
  /// the Groups organised be GroupID (Int)
  @Published var motionControlGroupDict:[Int:PairingGroup] = [:]
  
  // flag to determine if the link to the edelkrone API is established
  @Published var isConnected : Bool = false
  @Published var isPaired : Bool = false
  @Published var hasAdapters : Bool = false
  @Published var connectedAdapterID: String = ""
  @Published var hasScannedMCS = false
  
  @Published var apiState:ConnectionState = .presentLinkAdapters
  
  @Published var periodicMCSStatus :PeriodicStatus = PeriodicStatus()
  
  @Published var motionControlStatus: MotionControlStatus = MotionControlStatus()
  
  // Variables from Preferences to indicate what was used in the last run
  @AppStorage(Preferences.Hostname.rawValue) fileprivate  var hostname = ""
  @AppStorage(Preferences.Port.rawValue) fileprivate var port = 8080
  @AppStorage(Preferences.LinkAdapter.rawValue) fileprivate var linkID = ""
  
  
  // some private threads
  /// the thread for getting scanResults
  ///
  // MARK: Threads
  fileprivate var scanResultThread: Thread? = nil
  @Published var scanResultThreadIsRunning:Bool = false
  
  /// and a thread for retrieving pairing status
  fileprivate var pairingStatusThread: Thread? = nil
  @Published var pairingStatusThreadIsRunning:Bool = false
  
  /// and for periodic updates
  fileprivate var periodicStatusThread: Thread? = nil
  @Published var periodicStatusThreadIsRunning:Bool = false
  
  /// and the joystick update thread is not existing but work is done by the periodic thread
  fileprivate var joystickThread: Thread? = nil
  
  
  init(){
    
  }
  
  //thread selectors
  @objc func requestScanResults(_ object:Any) -> Void {
    
    while(Thread.current.isCancelled == false){
      //      for l in self.scannedMotionControlSystems{
      //        print(l.macAddress+" "+String(l.useInPairing))
      //      }
      wirelessPairingScanResults()
      Thread.sleep(forTimeInterval: 0.10)
    }
    print("ScanThread cancel")
    
    Thread.exit()
  }
  
  
  
  func linkStatus() -> Void{
    
  }
  
  public func stopAllThreads() {
    stopScanResultsThread()
    stopPairingStatusThread()
    stopPeriodicStatusThread()
  }
  
}

// MARK: - edelkroneNetwork -
/**
 This extension enriches the edelkrone API with a cople of network methods.
 */
extension edelkroneAPI:edelkroneNetwork{
  
  func executeSession<T:ApiResult>(request: URLRequest, uploadData: Data, with:@escaping (Bool, T?, Any?)->Void, context: Any?){
    let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
      if let error = error {
        print ("error: \(error)")
        DispatchQueue.main.async {
          with(false,nil, context)
        }
      }
      
      guard (response as? HTTPURLResponse) != nil else {
        print ("server error " )
        DispatchQueue.main.async {
          with(false,nil,context)
        }
        return
      }
      let data = data ?? Data()
      //      let dataString = String(data: data, encoding: .utf8)
      //      print ("got data: \(dataString!)")
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .secondsSince1970
      let returns = try? decoder.decode(T.self, from: data)
      var success = false
      if returns?.message != nil{
        success = false
      }else{
        success = true
      }
      DispatchQueue.main.async {
        with(success,returns,context)
      }
      
    }
    task.resume()
  }
  
  func executeSessionGet<T:ApiResult>(request: URLRequest, with:@escaping (Bool, T?, Any?)->Void, context: Any?){
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        print ("error: \(error)")
        DispatchQueue.main.async {
          with(false,nil, context)
        }
      }
      
      guard (response as? HTTPURLResponse) != nil else {
        print ("server error " )
        DispatchQueue.main.async {
          with(false,nil,context)
        }
        return
      }
      let data = data ?? Data()
      //      let dataString = String(data: data, encoding: .utf8)
      //      print ("got data: \(dataString!)")
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .secondsSince1970
      let returns = try? decoder.decode(T.self, from: data)
      var success = false
      if returns?.message != nil{
        success = false
      }else{
        success = true
      }
      DispatchQueue.main.async {
        with(success,returns,context)
      }
      
    }
    task.resume()
  }
  
  func getCommand(_ command :String ) -> Dictionary<String, Any>{
    let someDict:Dictionary = ["command": command]
    return someDict
  }
  
  func commandToJSON(_commandDict: Dictionary<String, Any>) -> Data?{
    var result : Data? = nil
    do{
      result = try JSONSerialization.data(withJSONObject: _commandDict, options: .prettyPrinted)
    }catch{
      result = nil
    }
    return result
  }
  
  func getURL(adapterID:String, type:requestType)->URL?{
    @AppStorage(Preferences.Hostname.rawValue)   var hostname = ""
    @AppStorage(Preferences.Port.rawValue)  var port = 8080
    
    let base = "http://"+hostname+":"+String(port)+"/v1/"
    
    var variant  = type.rawValue
    if (type != requestType.device){
      variant += "/"+adapterID
    }
    
    let p = URL(string: base+variant)
    return p
  }
  
  func getURL(adapter:LinkAdapter,  type:requestType)->URL?{
    return getURL(adapterID: adapter.id, type: type)
  }
  
  func getURL(_ type: requestType ) -> URL?{
    @AppStorage(Preferences.LinkAdapter.rawValue)  var linkID = ""
    return getURL(adapterID: linkID, type: type)
  }
  
  func getRequestFor(url: URL, command:Dictionary<String, Any> ) -> URLRequest{
    let requestData = commandToJSON(_commandDict: command) ?? Data()
    var request = URLRequest(url: url)
    request.httpMethod="POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = requestData
    return request
  }
  
  
}

// MARK: - edelkrone Commands -
extension edelkroneAPI {
  
  
  func reset() -> Void{
    isConnected = false
    isPaired = false
    hasAdapters = false
    hasScannedMCS = false
    connectedAdapterID = ""
    scannedLinkAdapters = []
    scannedMotionControlSystems = []
    adaptertDict = [:]
    ungroupedMotionControlSystems = []
    motionControlGroups = []
    motionControlGroupDict = [:]
    stopAllThreads()
    self.disconnectNoResult()
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now().advanced(by: .milliseconds(200)), execute: {

      self.scanLinkAdapters()
      
    })
    apiState = .presentLinkAdapters
  }
  
  func disconnectNoResult() -> Void {
    let requestDict = getCommand(commands.pairing.wireless.disconnect.rawValue)
    if let requestURL = getURL(.link){
      let request = getRequestFor(url: requestURL, command: requestDict)
      executeSession(request: request, uploadData: request.httpBody!, with: { (success:Bool,result:DefaultReturns?,context:Any) in  }, context: nil)
    }
  }
  
  
  func disconnect() -> Void {
    let requestDict = getCommand(commands.pairing.wireless.disconnect.rawValue)
    if let requestURL = getURL(.link){
      let request = getRequestFor(url: requestURL, command: requestDict)
      executeSession(request: request, uploadData: request.httpBody!, with: disconnectResult, context: nil)
    }
  }
  
  func disconnectResult(_ success:Bool, result:DefaultReturns?,context: Any) -> Void{
    if(success){
      //      scannedLinkAdapters = []
      stopAllThreads()
      if(connectedAdapterID != ""){
        adaptertDict[connectedAdapterID]?.isConnected = false
        //        connectedAdapterID = ""
      }
      isConnected = false
      wirelessPairingScanStart(adapter: adaptertDict[connectedAdapterID]!)
      apiState = .pairMotionControlSystems
      //      startScanResultsThread()
      
    }
  }
  
  
  // MARK: - LinkAdapters -
  /**
   find connected edelkrone link adapters
   */
  func scanLinkAdapters() -> Void{
    //    print("Initiate Scan for LinkAdapters on" + hostname + ":"+String(port) )
    let requestDict = getCommand(commands.link.status.rawValue)
    if let requestURL = getURL(.device){
      let request = getRequestFor(url: requestURL, command: requestDict)
      executeSession(request: request, uploadData: request.httpBody!, with: scanLinkAdaptersResult, context: nil)
    }
  }
  
  func scanLinkAdaptersResult(_ success:Bool, result: ResultArrayWrapper<LinkAdapter>?, context:Any) -> Void{
    if success {
      if result != nil && result!.message == nil{
        DispatchQueue.main.async {
          self.hasAdapters = true
          for k in result!.data!{
            if k.isValid{
              self.scannedLinkAdapters.append(k)
              self.adaptertDict[k.id] = k
            }
          }
          self.hasAdapters =  (self.scannedLinkAdapters.count > 0)
        }
      }
    }
  }
  
  func detect(adapter: LinkAdapter){
    //    print("Stry to detect a given link adapter")
    var url = getURL(adapter: adapter, type: .link)
    url?.appendPathComponent("detect")
    //    print("Got a URL: "+(url?.description ?? "failed"))
    let task = URLSession.shared.downloadTask(with: url!)
    task.resume()
  }
  
  // MARK: - wirelessPairingScanStart -
  
  func wirelessPairingScanStart( adapter:  LinkAdapter) -> Void{
    
    let requestStruct = getCommand(commands.pairing.wireless.scanStart.rawValue)
    if let requestURL = getURL(adapter: adapter,type: .link){
      let request = getRequestFor(url: requestURL, command: requestStruct)
      executeSession(request: request, uploadData: request.httpBody!,with: wirelessPairingScanStart_Result, context:adapter)
    }else{
      isConnected = false
      connectedAdapterID = ""
      adapter.isConnected = false
    }
  }
  
  fileprivate func stopScanResultsThread() {
    if((self.scanResultThread?.isExecuting) != nil){
      self.scanResultThread?.cancel()
      self.scanResultThread = nil
      self.scanResultThreadIsRunning = false
    }
  }
  
  fileprivate func startScanResultsThread() {
    // now trigger the retrieving of the scan results
    self.scanResultThread = Thread(target: self, selector: #selector(requestScanResults), object: nil)
    self.scanResultThread?.start()
    self.scanResultThreadIsRunning = true
  }
  
  func wirelessPairingScanStart_Result (_ success:Bool, result:DefaultReturns?, context: Any?)->Void{
    
    guard let adapter = context as? LinkAdapter else{
      connectedAdapterID = ""
      isConnected = false
      return
    }
    
    if success {
      isConnected = true
      adapter.isConnected = true
      connectedAdapterID = adapter.id
      startScanResultsThread()
    }else{
      isConnected = false
      adapter.isConnected = false
      connectedAdapterID = ""
    }
    
  }
  
  // MARK: - wirelessPairingScanResults -
  
  func wirelessPairingScanResults() -> Void {
    let requestStruct = getCommand(commands.pairing.wireless.scanResults.rawValue)
    
    if let requestURL = getURL(adapterID: connectedAdapterID, type: .link){
      let request = getRequestFor(url: requestURL, command: requestStruct)
      executeSession(request: request, uploadData: request.httpBody!, with: wirelessPairingScanResults_Result, context: nil)
    }
  }
  
  func getPairingGroupFor(id: Int)->PairingGroup?{
    if id == .noGroup{
      return nil
    }
    if(motionControlGroupDict.keys.contains(id)){
      return motionControlGroupDict[id]!
    }else{
      let l = PairingGroup(groupID: id)
      motionControlGroups.append(l)
      motionControlGroupDict[id] = l
      return l
    }
  }
  
  func removeElementFromPairingGroup(_ mcs:MotionControlSystem){
    guard let group = getPairingGroupFor(id: mcs.groupID) else {
      return
    }
    group.removeMotionControlSystem(mcs)
    if(group.isEmpty){
      let id = group.groupID
      motionControlGroupDict.removeValue(forKey: id)
      motionControlGroups.removeAll(where: {$0.groupID == id})
    }
    
    
  }
  func updateMotionControlGroup(_ mcs: MotionControlSystem)
  {
    if  motionControlSystemsDict.keys.contains(mcs.macAddress) {
      let orginol = motionControlSystemsDict[mcs.macAddress]!
      if mcs.groupID != .noGroup{
        let group = getPairingGroupFor(id: mcs.groupID)!
        group.addMotionControlSystem(mcs)
      }
      if orginol.groupID != mcs.groupID{
        if(orginol.groupID != .noGroup){
          removeElementFromPairingGroup(orginol)
          self.ungroupedMotionControlSystems.append(orginol)
        }
        orginol.groupID = mcs.groupID
        if(orginol.groupID != .noGroup){
          let group = getPairingGroupFor(id: orginol.groupID)
          group?.addMotionControlSystem(orginol)
        }
      }
    }
  }
  
  func wirelessPairingScanResults_Result(_ success:Bool, result: ResultArrayWrapper<MotionControlSystem>?, context:Any) -> Void{
    if success{
      let someMSC = result!.data!
      //      print (someMSC.description)
      //      self.scannedMotionControlSystems.removeAll()
      //      self.MotionControlSystemsDict.removeAll()
      // adding new ones
      for  k in someMSC {
        if(!self.scannedMotionControlSystems.contains(k)){
          self.scannedMotionControlSystems.append(k)
          self.motionControlSystemsDict[k.id] = k
          if k.groupID == .noGroup {
            self.ungroupedMotionControlSystems.append(k)
          }
        }
        updateMotionControlGroup(k)
      }
      
      
      // removing old ones
      let scannedSystems = Set<MotionControlSystem>(someMSC)
      let knownSystems = Set<MotionControlSystem>(self.scannedMotionControlSystems)
      let toRemove = knownSystems.subtracting(scannedSystems)
      if toRemove.count>0{
        for removedElement in toRemove{
          self.scannedMotionControlSystems.removeAll(where: {$0.macAddress == removedElement.macAddress})
          self.motionControlSystemsDict.removeValue(forKey: removedElement.macAddress)
          self.ungroupedMotionControlSystems.removeAll(where: {$0.macAddress == removedElement.macAddress})
          if(removedElement.groupID != .noGroup){
            removeElementFromPairingGroup(removedElement)
          }
        }
      }
      self.hasScannedMCS = true
      self.apiState = .pairMotionControlSystems
    }
  }
  
  // MARK: - create Bundle -
  func wirelessPairingCreateBundle() -> Void{
    // first we collect the mac adresses of all the marked devices
    var pairingMacs:[String] = []
    var pairingMaster:String? = nil
    for mcs in scannedMotionControlSystems{
      if mcs.useInPairing {
        pairingMacs.append(mcs.macAddress)
        if(pairingMaster == nil){
          pairingMaster = mcs.macAddress
        }
        mcs.useInPairing = false
      }
    }
    var requestStruct = getCommand(commands.pairing.wireless.createBundle.rawValue)
    requestStruct["deviceCount"] = pairingMacs.count
    requestStruct["forceMasterDevice"] = pairingMaster
    requestStruct["macList"] = pairingMacs
    if let requestURL = getURL(adapterID: connectedAdapterID, type: .link){
      let request = getRequestFor(url: requestURL, command: requestStruct)
      executeSession(request: request, uploadData: request.httpBody!, with: wirelessPairingCreateBundle_Result, context: nil)
    }
  }
  
  func wirelessPairingCreateBundle_Result(_ success:Bool, result:DefaultReturns?, context:Any?) -> Void {
    if success{
      print("creation of bundle succeded")
      // stop the scanning thread and start with the pairing status thread
      stopScanResultsThread()
      startPairingStatusThread()
    }else{
      print("creation of bundle failed")
    }
  }
  
  // MARK: - attach bundle -
  func attachToBundle(_ bundle: PairingGroup) -> Void {
    var requestDict = getCommand(commands.pairing.wireless.attachToBundle.rawValue)
    requestDict["mac"] = bundle.groupMaster?.macAddress
    if let requestURL = getURL(.link) {
      let request = getRequestFor(url: requestURL, command: requestDict)
      executeSession(request: request, uploadData: request.httpBody!, with: attachToBundle_Result, context: nil)
    }
  }
  
  func attachToBundle_Result(_ success: Bool, result: DefaultReturns?, context: Any?) -> Void{
    if success {
      self.apiState = .showMotionControlInterface
      stopAllThreads()
      self.motionControlStatus.axelStatus = [:]
      //      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now().advanced(by: .milliseconds(1000))) {
      print("Doing the twist")
      self.startPeriodicStatusThread()
      //      }
    }
  }
  
  // MARK: - pairingStatus -
  func wirelessPairingStatus() -> Void{
    let requestDict = getCommand(commands.pairing.wireless.status.rawValue)
    if let requestURL = getURL(.link){
      let request = getRequestFor(url: requestURL, command: requestDict)
      executeSession(request: request, uploadData: request.httpBody!, with: wirelessPairingStatus_Result, context: nil)
    }
    
  }
  
  func wirelessPairingStatus_Result(_ success:Bool, result:PairingStatusReturn?,context:Any?) -> Void {
    if success {
      print("got a pairing status " )
      guard let k = result else { return }
      switch k.status?.pairState {
      case .none:
        fallthrough
      case .idle:
        fallthrough
      case .connecting:
        break
      case .connectionOk:
        stopPairingStatusThread()
        startPeriodicStatusThread()
        apiState = .showMotionControlInterface
      case .problem:
        stopPairingStatusThread()
        apiState = .presentLinkAdapters
      }
    }else{
      stopPairingStatusThread()
      startPeriodicStatusThread()
      // this could only mean, that we got a message and the pairing is done
      apiState = .showMotionControlInterface
    }
    if apiState == .showMotionControlInterface{
      self.motionControlStatus.axelStatus = [:]
    }
  }
  
  
  @objc func requestPairingStatus(_ object: Any) -> Void{
    while(Thread.current.isCancelled == false){
      wirelessPairingStatus()
      Thread.sleep(forTimeInterval: 0.02)
    }
    Thread.exit()
  }
  
  
  fileprivate func stopPairingStatusThread() {
    if((self.pairingStatusThread?.isExecuting) != nil){
      self.pairingStatusThread?.cancel()
      self.pairingStatusThread = nil
      self.pairingStatusThreadIsRunning = false
    }
  }
  
  fileprivate func startPairingStatusThread() {
    // now trigger the retrieving of the scan results
    self.pairingStatusThread = Thread(target: self, selector: #selector(requestPairingStatus), object: nil)
    self.pairingStatusThread?.start()
    self.pairingStatusThreadIsRunning = true
  }
  
  // MARK: - Periodic Status
  
  func attachConnectedAdapter(adapterID:String ) -> Void {
    apiState = .showMotionControlInterface
    self.connectedAdapterID = adapterID
    self.motionControlStatus.axelStatus = [:]
    startPeriodicStatusThread()
  }
  
  func getPeriodicStatus() -> Void{
    if var requestURL = getURL(adapterID: connectedAdapterID, type: .bundle){
      requestURL.appendPathComponent("status")
      let request = URLRequest(url: requestURL)
      executeSessionGet(request: request, with: getPeriodicStatus_Result, context: nil)
    }
  }
  
  func getPeriodicStatus_Result(_ success:Bool, result:PeriodicStatusReturn?, context:Any?) -> Void{
    //    var requestStruct = getCommand(commands.status.rawValue)
    //    print("Periodic Status: " + (result?.status.state.rawValue ?? "Failed"))
    guard let k = result?.status else { return }
    self.periodicMCSStatus &= k
    self.motionControlStatus &= k
  }
  
  @objc func requestPeriodicStatus(_ object: Any) -> Void{
    while(Thread.current.isCancelled == false){
      getPeriodicStatus()
      sendJoystickMove()
      Thread.sleep(forTimeInterval: 0.5)
    }
    Thread.exit()
  }
  
  fileprivate func stopPeriodicStatusThread() {
    if((self.periodicStatusThread?.isExecuting) != nil){
      self.periodicStatusThread?.cancel()
      self.periodicStatusThread = nil
      self.periodicStatusThreadIsRunning = false
    }
  }
  
  fileprivate func startPeriodicStatusThread() {
    // now trigger the retrieving of the scan results
    
    self.periodicStatusThread = Thread(target: self, selector: #selector(requestPeriodicStatus(_:)), object: nil)
    self.periodicStatusThread?.start()
    self.periodicStatusThreadIsRunning = true
  }
  
  
  // MARK: - Joystick Move
  
  func sendJoystickMove() -> Void {
    // first we collect all axis and values that are currently manipulated by a joystick
    let controlledAxels = motionControlStatus.joystickControlled()
    if !controlledAxels.isEmpty {
      var requestDict = getCommand(commands.joystickMove.rawValue)
      for movingAxel in controlledAxels {
        requestDict[movingAxel.axelName.rawValue] = movingAxel.moveValue
        if movingAxel.isLastMove  {
          movingAxel.shouldMove = false
          movingAxel.isLastMove = false
        }
      }
      if let requestURL = getURL(.bundle){
        let request = getRequestFor(url: requestURL, command: requestDict)
        executeSession(request: request, uploadData: request.httpBody!, with: sendJoystickMove_Result, context: nil)
      }
    }
  }
  
  func sendJoystickMove_Result(_ success:Bool, result:DefaultReturns?, context:Any?) -> Void{
    if success {
      //      print("Moving")
    }
  }
  
}
