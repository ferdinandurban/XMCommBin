//
//  Models.swift
//  XMCommDemo
//
//  Created by Ferdinand Urban on 08.01.2022.
//

import Foundation

struct RestResponse: Codable {
  var code: Int
  var id: Int?
  var idText: String?
  var message: String
}

struct LoginDataResponse: Codable {
  var accessToken: String
  var refreshToken: String
  var refreshTokenExpiresIn: Int
  var accessTokenExpiresIn: Int
  var userGuid: String
}

struct LoginResponse: Codable {
  var data: LoginDataResponse?
  var code: Int
  var message: String
}

public enum CarBoxStatus: Int, Codable {
  case unknown = 0, notAuthorized, awaitingAuthorization, authorized
  
  init(string aStringValue: String) {
    switch aStringValue {
      case "NotAuthorized":
        self = .notAuthorized
      case "AwaitingAuthorization":
        self = .awaitingAuthorization
      case "Authorized":
        self = .authorized
      default:
        self = .unknown
    }
  }  
}

struct BoxInfo: Codable {
  var publicId: String
  var publicKey: String
  var authorizationStatus: String
  var btBoxUUID: String?
  var temporaryKey: [Data]?
}

struct Car: Codable {
  var id: Int
  var registrationNumber: String?
  var communicationState: Int?
  var fullModelName: String?
  var nickName: String?
//  var capabilities: [BoxPropertyType]
  var currencyCode: String?
  var isFavourite: Bool?
  var requestTakeover: Bool?
  var boxInfo: BoxInfo
}
