//
//  MimicleApi.swift
//  mimicle
//
//  Created by Hyung-Min Noh on 2021/11/29.
//

import Foundation
import Moya
import UIKit

enum MimicleApi {
    case getMeta(osType: String, versionCode: String, model: String, osversion: String, locale: String)
    case setPushInfo(osType: String, versionCode: String, pushkey: String, uuid: String, memno: String)
}

extension MimicleApi: TargetType {
     var baseURL: URL {
         return URL(string: "https://frc.mimicle.art")!
     }

    var path: String {
        switch self {
        case .getMeta:
            return "/app/com/appmeta.php"
        case .setPushInfo:
            return "/app/com/set-push-info.php"
        }
    }

 //moya의 장점 각 메소드가 get 인지 post인지 설정가능
    var method: Moya.Method {
        switch self {
        case .getMeta:
            return .get
        case .setPushInfo:
            return .get
        }
     }

     var sampleData: Data {
         return "@@".data(using: .utf8)!
     }

     var task: Task {
         switch self {
         case .getMeta(let osType, let versionCode, let model, let osversion, let locale):
             return .requestParameters(parameters: ["ostype" : osType, "vcode" : versionCode, "model" : model, "osversion" : osversion, "locale" : locale], encoding: URLEncoding.queryString)
         case .setPushInfo(let osType, let versionCode, let pushkey, let uuid ,let memno):
             return .requestParameters(parameters: ["ostype" : osType, "vcode" : versionCode, "pushkey" : pushkey, "uuid" : uuid, "memno" : memno], encoding: URLEncoding.queryString)
         }
     }

     var validationType: Moya.ValidationType {
         return .successAndRedirectCodes
     }

    var headers: [String : String]? {
        return ["Content-type": "application/json"]
    }
 }
