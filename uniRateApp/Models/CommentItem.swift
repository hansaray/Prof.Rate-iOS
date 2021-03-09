//
//  CommentItem.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 06..
//

import Foundation

struct CommentItem {
    let username : String
    let university : String
    let faculty : String
    let photo : String
    let userID : String
    let avgRating : Double
    let helpNum : Double
    let diffNum : Double
    let lecNum : Double
    var attNum : Double?
    var txtNum : Double?
    var comment : String
    var likeNum : Int?
    var dislikeNum : Int?
    var userLikedNum : Int?
    var userDislikedNum : Int?
    let time : UInt
    let popularity : Int
    let itemID : String
    let profID : String
    let check : Bool
    var type : String?
    
    init(commentData : [String : Any]) {
        self.username = commentData["username"] as? String ?? ""
        self.photo = commentData["photo"] as? String ?? ""
        self.userID = commentData["userID"] as? String ?? ""
        self.university = commentData["university"] as? String ?? ""
        self.faculty = commentData["faculty"] as? String ?? ""
        self.avgRating = commentData["avgRating"] as? Double ?? 0.0
        self.helpNum = commentData["helpNum"] as? Double ?? 0.0
        self.diffNum = commentData["diffNum"] as? Double ?? 0.0
        self.lecNum = commentData["lecNum"] as? Double ?? 0.0
        self.comment = commentData["comment"] as? String ?? ""
        self.time = commentData["time"] as? UInt ?? 0
        self.popularity = commentData["popularity"] as? Int ?? 0
        self.itemID = commentData["itemID"] as? String ?? ""
        self.profID = commentData["profID"] as? String ?? ""
        self.check = commentData["check"] as? Bool ?? true
    }
    
}

