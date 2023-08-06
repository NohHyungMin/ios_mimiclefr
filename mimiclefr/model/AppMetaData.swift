//
//  AppMetaData.swift
//  mimicle
//
//  Created by Hyung-Min Noh on 2021/12/01.
//

import Foundation

struct AppMetaData: Decodable {
    var result: Int
    var data: Data

    struct Data: Decodable {
        var vname: String
        var vcode: String
        var forcedyn: String
        var strupdate: String
        var mainurl: String
    }
}
