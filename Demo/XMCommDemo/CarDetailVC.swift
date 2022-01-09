//
//  CarDetailVC.swift
//  XMCommDemo
//
//  Created by Ferdinand Urban on 14.10.2021.
//

import UIKit
import RxSwift
import XMComm

class CarDetailVC: UIViewController {

  var car: Car?
  internal var carDetail: XMCarDetail? = nil {
    didSet {
      carDetail?.properties.forEach {
        XMLog("\($0.key) \($0.value)")
      }
      
      if let odometer = carDetail?.properties.filter({$0.key == "odometer"}).first?.value {
        rx_odometer.onNext(Double(odometer))
      }
      
      if let batteryVoltage = carDetail?.properties.filter({$0.key == "batteryLevel"}).first?.value {
        rx_batteryVoltage.onNext(Double(batteryVoltage))
      }
      
      if let engineRunning = carDetail?.properties.filter({$0.key == "FeatureEngineRunning"}).first?.value {
        rx_engineRunning.onNext(UInt(engineRunning))
      }
      
      if let lockedOn = carDetail?.properties.filter({$0.key == "lockedOn"}).first?.value {
        rx_lockState.onNext(Bool(lockedOn))
      }
      
    }
  }
  
  internal var carLocation: DrivePointVO? = nil {
    didSet {
      adressLbl?.text = carLocation?.addressLines?.fullAddress
    }
  }
  
  internal let btService = BluetoothService.sharedInstance
  internal var disposeBag: DisposeBag = DisposeBag()
  internal let commService: XMCommService = XMCommService.instance
  
  internal let rx_batteryVoltage: PublishSubject<Double?> = PublishSubject<Double?>()
  internal let rx_odometer: PublishSubject<Double?> = PublishSubject<Double?>()
  internal let rx_lockState: PublishSubject<Bool?> = PublishSubject<Bool?>()
  internal let rx_engineRunning: PublishSubject<UInt?> = PublishSubject<UInt?>()
  internal let rx_engineSpeed: PublishSubject<Double?> = PublishSubject<Double?>()
  
  @IBOutlet weak var engineSpeedLbl: UILabel!
  @IBOutlet weak var engineRunningLbl: UILabel!
  @IBOutlet weak var btStateLbl: UILabel!
  @IBOutlet weak var odometerLbl: UILabel!
  @IBOutlet weak var batteryVoltageLbl: UILabel!
  @IBOutlet weak var adressLbl: UILabel!
  @IBOutlet weak var carNameLbl: UILabel!
  @IBOutlet weak var regNumberLbl: UILabel!
  @IBOutlet weak var lockSwitch: UISwitch!
  @IBOutlet weak var commandsTV: UITextView!
  
  @IBAction func btConnectClick(_ sender: Any) {
    XMLog("BT Connect Click")
    
    guard let thePubId = car?.boxInfo.publicId, let thePubKey = car?.boxInfo.publicKey else {
      XMLog("Chybi publicID nebo publicKey --> nebudeme pripojovat pres BT")
      return
    }

    btService.connect(publicId: thePubId, publicKey: thePubKey)
  }
  
  @IBAction func consoleClearClick(_ sender: Any) {
    commandsTV.text = ""
  }
  
  @IBAction func lockAction(_ sender: UISwitch) {
    let operation = lockSwitch.isOn ? LockOperation.unlock : LockOperation.lock
    sendCommand(aCommand: .unlockCar, aValue: operation)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    btService.disconnect()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    btStateLbl.adjustsFontSizeToFitWidth = true
    batteryVoltageLbl.adjustsFontSizeToFitWidth = true
    odometerLbl.adjustsFontSizeToFitWidth = true
    
    carNameLbl?.text = car?.fullModelName ?? "CarDetail"
    regNumberLbl?.text = car?.registrationNumber ?? "N/A"
    
    rx_odometer
      .map {
        if let theValue = $0 {
          return String(format: "%.0f km", arguments: [theValue])
        } else {
          return "-- km"
        }
      }
      .bind(to: odometerLbl.rx.text)
      .disposed(by: disposeBag)
    
    rx_batteryVoltage
      .map {
        if let theValue = $0 {
          return String(format: "%.2f V", arguments: [theValue])
        } else {
          return "-- V"
        }
      }
      .bind(to: batteryVoltageLbl.rx.text)
      .disposed(by: disposeBag)
    
    rx_lockState
      .map {$0 ?? false}
      .bind(to: lockSwitch.rx.isOn)
      .disposed(by: disposeBag)
    
    rx_engineSpeed
      .map {
        if let theValue = $0 {
          return String(format: "%.0f rpm", arguments: [theValue])
        } else {
          return "-- rpm"
        }
      }
      .bind(to: engineSpeedLbl.rx.text)
      .disposed(by: disposeBag)
    
    rx_engineRunning
      .map {
        if let theValue = $0 {
          switch (theValue) {
            case 1: return "No"
            case 3: return "Yes"
            default: return "Unknown"
          }
        } else {
          return "--"
        }
      }
      .bind(to: engineRunningLbl.rx.text)
      .disposed(by: disposeBag)
    
    // set mobile device guid obtained during device autorization before the car connection
    if let mobileDeviceGuid = UserDefaults.standard.object(forKey: "mobileDeviceGuid") as? String {
      btService.mobileDeviceGuid = mobileDeviceGuid
      btService.startMonitoring()
    } else {
      XMLog("MobileDeviceGuid NOT SET!")
    }
    
    observeBTState()
  }
  
  func observeBTState() {
    btService.rx.connectionState
      .xmDebug("[BT Connection State]")
      .observe(on: MainScheduler.asyncInstance)
      .subscribe {[weak self](anEvent) in
        guard let theSelf = self else { return }

        switch(anEvent) {
          case .next(let aState):
            DispatchQueue.main.async {
              theSelf.btStateLbl.text = "\(aState)"
              theSelf.addToCommandTextView(aText: "[BT] connection state \(aState)")
            }

            if aState == .authorized {
              theSelf.observeBTValues()
            }

          case .error(let anError):
            XMLog("Error getting car detail: \(anError)")

          case .completed: ()
        }

      }.disposed(by: disposeBag)
  }
  
  func observeBTValues() {
    btService.rx.subscribe(ids: [.lockState, .engineRunning, .engineSpeed, .odometer, .batteryLevel])
      .xmDebug("[BT Values]")
      .observe(on: MainScheduler.asyncInstance)
      .subscribe {[weak self](anEvent) in
        guard let theSelf = self else { return }

        switch(anEvent) {
          case .next(let aResponse):

            XMLog("\(aResponse.id): \(aResponse.value)")

            // handle only values with valid data
            if aResponse.value.state == .available {
              theSelf.addToCommandTextView(aText: "[BT] \(aResponse.id): \(aResponse.value.value ?? "n/a")")

              DispatchQueue.main.async {
                if aResponse.id == .batteryLevel {
                  theSelf.rx_batteryVoltage.onNext(aResponse.value.value as? Double)
                }

                if aResponse.id == .odometer {
                  theSelf.rx_odometer.onNext(aResponse.value.value as? Double)
                }

                if aResponse.id == .lockState {
                  theSelf.rx_lockState.onNext(aResponse.value.value as? Bool)
                }

                if aResponse.id == .engineSpeed {
                  theSelf.rx_engineSpeed.onNext(aResponse.value.value as? Double)
                }

                if aResponse.id == .engineRunning {
                  theSelf.rx_engineRunning.onNext(aResponse.value.value as? UInt)
                }
              }
            }

          case .error(let anError):
            XMLog("Error getting car detail: \(anError)")

          case .completed: ()
        }

      }.disposed(by: disposeBag)
  }
  
  /// Send command to car box
  /// if BT is connected, command is sent via BT
  /// othrewise REST is called
  func sendCommand(aCommand: CarCommandId, aValue: XMCommActionValueType) {
//    if btService.isConnected {
      let text = "[BT] Sending \(aCommand) with value \(aValue)"
      addToCommandTextView(aText: text)
      btService.rx
        .perform(command: aCommand, value: aValue)
        .observe(on: MainScheduler.asyncInstance)
        .subscribe{[weak self](anEvent) in
          guard let theSelf = self else { return }
          switch(anEvent){
            case .next(let aResponse):
              XMLog("\(aResponse)")
              let text = "[BT] Result for \(aCommand): executed."
              theSelf.addToCommandTextView(aText: text)
            case .error(let anError):
              XMLog("\(anError)")
              theSelf.addToCommandTextView(aText: "[BT][ERROR] Executing command \(aCommand). Check log.")
            case .completed:()
          }

        }.disposed(by: disposeBag)
  }
  
  func addToCommandTextView(aText:String) {
    commandsTV.insertText(aText + "\n")
    let range = NSMakeRange(commandsTV.text.count - 1, 0)
    commandsTV.scrollRangeToVisible(range)
  }  
}
