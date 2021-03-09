//
//  NotificationItem.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 17..
//

import Foundation

struct NotificationItem {
    var object : User?
    let profName : String
    let picName : String
    var ratingID : String
    let itemID : String
    let time : Int
    var totalLikes : Int?
    var totalDislike : Int?
    
    init(notData : [String : Any]) {
        self.profName = notData["profName"] as? String ?? ""
        self.picName = notData["picName"] as? String ?? ""
        self.ratingID = notData["ratingID"] as? String ?? ""
        self.itemID = notData["itemID"] as? String ?? ""
        self.time = notData["time"] as? Int ?? 0
    }
    
}
