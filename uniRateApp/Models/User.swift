//
//  User.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 05..
//

import Foundation

struct User {
    let username : String
    let photo : String
    let userID : String
    let university : String
    let faculty : String
    let email : String
    let likeNum : UInt
    let dislikeNum : UInt
    let ratingNum : UInt
    init(userData : [String : Any]) {
        self.username = userData["username"] as? String ?? ""
        self.photo = userData["photo"] as? String ?? ""
        self.userID = userData["userID"] as? String ?? ""
        self.university = userData["university"] as? String ?? ""
        self.faculty = userData["faculty"] as? String ?? ""
        self.email = userData["email"] as? String ?? ""
        self.likeNum = userData["likeNum"] as? UInt ?? 0
        self.dislikeNum = userData["dislikeNum"] as? UInt ?? 0
        self.ratingNum = userData["ratingNum"] as? UInt ?? 0
    }
}

