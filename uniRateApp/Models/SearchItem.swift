//
//  SearchItem.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 12..
//

import Foundation

struct SearchItem {
    let cityUniName : String
    let fieldName : String
    let profName : String
    let photo : Int
    let itemID : String
    var ratingNum : Double
    var title : String?
    
    init(searchData : [String : Any]) {
        self.cityUniName = searchData["cityUniName"] as? String ?? ""
        self.fieldName = searchData["fieldName"] as? String ?? ""
        self.profName = searchData["profName"] as? String ?? ""
        self.photo = searchData["photoNum"] as? Int ?? 0
        self.itemID = searchData["itemID"] as? String ?? ""
        self.ratingNum = searchData["ratingNum"] as? Double ?? 0.0
    }
    
}
