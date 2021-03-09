//
//  statsItem.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 11. 15..
//

import Foundation

struct statsItem {
    let name : String
    let num : Int
    
    init(statsData : [String : Any]) {
        self.name = statsData["name"] as? String ?? ""
        self.num = statsData["num"] as? Int ?? 0
    }
    
}
