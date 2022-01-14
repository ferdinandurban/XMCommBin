//
//  TableVC+Ex.swift
//  XMCommDemo
//
//  Created by Ferdinand Urban on 11.10.2021.
//

import UIKit
import RxSwift
import XMComm

extension CarListVC {
  internal func readDefaults() {
    let theDeviceId = defaults.object(forKey: "deviceId") as? String
    let theAccessToken = defaults.object(forKey: "accessToken") as? String
    let theRefreshToken = defaults.object(forKey: "refreshToken") as? String
    
    restService.accessToken = theAccessToken
    restService.refreshToken = theRefreshToken
    restService.deviceId = theDeviceId
  }
  
  internal func login() {
    if let theAccessToken = defaults.object(forKey: "accessToken") as? String,
       let theRefreshToken = defaults.object(forKey: "refreshToken") as? String {
      restService.accessToken = theAccessToken
      
      restService.loginToken(token: theRefreshToken) {[weak self](result) in
        guard let theSelf = self else { return }
        switch result {
          case .failure(let error):
            XMLog("error token login: \(error)")
            
            DispatchQueue.main.async {
              theSelf.onFailureLogin()
            }
          case .success(_):
            
            DispatchQueue.main.async {
              theSelf.onSuccessLogin()
            }
        }
      }
    } else {
      getDeviceId()
      #warning("Set the correct username & password")
      let username = "ferdinand.urban@gmail.com"
      let pass = "hekxit-basKom-wipvi7"
      
      restService.loginUser(username: username,
                            password: pass){[weak self](result) in
        guard let theSelf = self else { return }
        switch result {
          case .failure(let error):
            XMLog("error during login username/password: \(error)")
            
            DispatchQueue.main.async {
              theSelf.onFailureLogin()
            }
            
          case .success(let response):
            if let data = response.data {
              theSelf.defaults.setValue(data.accessToken, forKey: "accessToken")
              theSelf.defaults.setValue(data.refreshToken, forKey: "refreshToken")
              theSelf.defaults.setValue(username, forKey: "email")
              
              DispatchQueue.main.async {
                theSelf.onSuccessLogin()
              }
            }
        }
      }
    }
  }
    
  private func getDeviceId() {
    if let theDeviceId = defaults.object(forKey: "deviceId") as? String {
      restService.deviceId = theDeviceId
    } else {
      let uuid = UUID().uuidString
      restService.deviceId = uuid
      defaults.setValue(uuid, forKey: "deviceId")
      XMLog("Generated DeviceId: \(uuid)")
    }
  }
  
  private func onSuccessLogin() {
    loginBtn.setTitle("Logged In", for: .normal)
    userNameLbl.text = defaults.object(forKey: "email") as? String
    getCarsBtn.isEnabled = true
  }
  
  private func onFailureLogin() {
    showErrorAlert(title:"Log In Error",
                   message: "Cannot log in, check for valid username/password")
    userNameLbl.text = "Cannot Log in"
  }
  
  func showErrorAlert(title aTitle: String, message aMessage: String) {
    let alert = UIAlertController(title: aTitle,
                                  message: aMessage,
                                  preferredStyle: UIAlertController.Style.alert)
    
    alert.addAction(UIAlertAction(title: "OK",
                                  style: UIAlertAction.Style.default,
                                  handler: {(_: UIAlertAction!) in
                                    
                                  }))
    self.present(alert, animated: true, completion: nil)
  }
}
