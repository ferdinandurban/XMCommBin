//
//  XMRestService.swift
//  XMCommDemo
//
//  Created by Ferdinand Urban on 08.01.2022.
//

import Foundation
import XMComm

public enum RestResponseCode: Int {
  
  case unknown             = -10_000
  case ok                  = 0
  case alreadyDone         = 1
  case missingPuk          = 10_001
  case forbidden           = 10_002
  case carNotAuthorized    = 10_004
  case missingPuk2         = 10_100
  case blockedDevice       = 10_101
  case invalidDevice       = 10_102
  case invalidUser         = 10_104
  case deviceNotAuthorized = 10_133
  case missingPhone        = 10_150
  case stolenPhone         = 10_165
  case missingPuk4         = 10_190
  case missingPuk5         = 10_191
  case invalidDevice2      = 10_192
  case invalidDevice3      = 10_193
  case unknownPushId       = 10_331
  case tooMuchDevices      = 10_494
  case notForDemo          = 10003
  
}

enum NetworkError: Error {
  case anyError
  case invalidGrant
}

class XMRestService {
  
  public static let sharedInstance = XMRestService()
  public var deviceId: String?
  public var accessToken: String?
  public var refreshToken: String?
  
  let defaults = UserDefaults.standard
  let url_base = "https://mobile.xmarton.com/api/v1.5"
  let session: URLSession = URLSession.shared
  
  init(){}
  
  public func loginUser(username: String,
                        password: String,
                        completion: @escaping (Result<LoginResponse, NetworkError>) -> Void) {
    let url = url_base + "/auth/login"
    let Url = String(format: url)
    
    guard let serviceUrl = URL(string: Url) else { return }
    
    let parameterDictionary = ["username" : username, "password" : password, "installId": deviceId]
    
    var request = URLRequest(url: serviceUrl)
    request.httpMethod = "POST"
    request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
    
    guard let httpBody = try? JSONSerialization.data(withJSONObject: parameterDictionary, options: []) else {
      return
    }
    request.httpBody = httpBody
    
    session.dataTask(with: request) { [weak self](data, response, error) in
      guard let theSelf = self, let theData = data else { return }
            
      do {
        let decoder = JSONDecoder()
        let json = try decoder.decode(LoginResponse.self, from: theData)
        
        if let data = json.data {
          theSelf.accessToken = data.accessToken
          theSelf.refreshToken = data.refreshToken
        }
        
        if json.code == 10_133 {
          theSelf.authorizeDevice()
        }
        
        if json.code == 10_137 {
          completion(.failure(.invalidGrant))
        }
        
        completion(.success(json))
      } catch {
        XMLog("Error: \(error)")
        completion(.failure(.anyError))
      }
    }.resume()
  }

  public func loginToken(token: String,
                        completion: @escaping (Result<RestResponse, Error>) -> Void) {
    let url = url_base + "/auth/login/token"
    let Url = String(format: url)
    
    guard let serviceUrl = URL(string: Url) else { return }
    
    let parameterDictionary = ["token" : token]
    
    var request = URLRequest(url: serviceUrl)
    request.httpMethod = "POST"
    request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
    
    guard let httpBody = try? JSONSerialization.data(withJSONObject: parameterDictionary, options: []) else {
      return
    }
    request.httpBody = httpBody
    
    session.dataTask(with: request) { (data, response, error) in
      guard let theData = data else { return }
      
      do {
        let decoder = JSONDecoder()
        let json = try decoder.decode(RestResponse.self, from: theData)
        completion(.success(json))
      } catch {
        XMLog("Error: \(error)")
        completion(.failure(error))
      }
    }.resume()
  }
  
  func authorizeDevice() {
    guard let theDeviceId = deviceId,
    let theToken = accessToken else {
      XMLog("no device id or token")
      return
    }
    
    let url = url_base + "/auth/mobile"
    let Url = String(format: url)
    
    guard let serviceUrl = URL(string: Url) else { return }
    
    let parameterDictionary = ["deviceOsVersion":"15.2",
                               "appVersion":"1.2.2",
                               "deviceID":"\(theDeviceId)",
                               "deviceMaker":"Apple",
                               "deviceModel":"iPhone6s",
                               "platform":"iOS"]
    
    let auth = "Bearer \(theToken)"
    var request = URLRequest(url: serviceUrl)
    request.httpMethod = "POST"
    request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(auth, forHTTPHeaderField: "Authorization")
    
    guard let httpBody = try? JSONSerialization.data(withJSONObject: parameterDictionary, options: []) else {
      return
    }
    request.httpBody = httpBody
    
    session.dataTask(with: request) { [weak self](data, response, error) in
      guard let theSelf = self, let theData = data else { return }
      
      do {
        let decoder = JSONDecoder()
        let json = try decoder.decode(RestResponse.self, from: theData)
        XMLog("Authorize device response: \(json)")
        theSelf.defaults.setValue(json.idText, forKey: "mobileDeviceGuid")
      } catch {
        XMLog("Error: \(error)")
      }
    }.resume()
  }
  
  public func getCars(completion: @escaping (Result<[Car], Error>) -> Void) {
    guard let theDeviceId = deviceId,
          let theToken = accessToken else {
            XMLog("no device id or token")
            return
          }
    
    let url = url_base + "/cars"
    
    let params = ["idApp": theDeviceId,
                  "withTempKey": "true",
                  "idUser": ""]
    
    let urlComp = NSURLComponents(string: url)!
    
    var items = [URLQueryItem]()
    
    for (key,value) in params {
      items.append(URLQueryItem(name: key, value: value))
    }
    
    let auth = "Bearer \(theToken)"
    var request = URLRequest(url: urlComp.url!)
    request.httpMethod = "GET"
    request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(auth, forHTTPHeaderField: "Authorization")
    
    
    session.dataTask(with: request) { (data, response, error) in
      guard let theData = data else { return }
      
      do {
        let decoder = JSONDecoder()
        let json = try decoder.decode([Car].self, from: theData)
        completion(.success(json))
        
      } catch {
        XMLog("Error: \(error)")
        completion(.failure(error))
      }
    }.resume()
  }
}
