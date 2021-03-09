//
//  HandleLikeActions.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 09..
//

import Foundation
import Firebase

class HandleLikeActions {
    let ref = Database.database().reference()
    
    func likeDislikeProcess(type: UInt8, likeType: Bool, item: CommentItem, ratingLikeCheck: UInt8){
        // true = like, false = dislike , 1 = fromMyLikes, 2 = fromMyDislikes, 3 = fromMyRatings
        if type == 1 {
            if likeType { //removing like
                self.removeLikeDislike(item: item, likesType: "likes", myLikesType: "myLikes", myLikedNumber: "myLikedNumber")
            } else { //removing like, adding Dislike
                self.removeOneAddOne(item: item, likesType: "dislikes", myLikesType: "myDislikes", rLikeType: "likes", rMyLikesType: "myLikes")
            }
        } else if type == 2 {
            if likeType { // removing dislike, adding like
                self.removeOneAddOne(item: item, likesType: "likes", myLikesType: "myLikes", rLikeType: "dislikes", rMyLikesType: "myDislikes")
            } else { // removing dislike
                self.removeLikeDislike(item: item, likesType: "dislikes", myLikesType: "myDislikes", myLikedNumber: "myDislikedNumber")
            }
        } else if type == 3 {
            //true = fromLike, false = fromDislike
            if likeType {
                if ratingLikeCheck == 1 { //removing like
                    self.removeLikeDislike(item: item, likesType: "likes", myLikesType: "myLikes", myLikedNumber: "myLikedNumber")
                } else if ratingLikeCheck == 2 { //remove dislike, add like
                    self.removeOneAddOne(item: item, likesType: "likes", myLikesType: "myLikes", rLikeType: "dislikes", rMyLikesType: "myDislikes")
                } else if ratingLikeCheck == 3 { // add like
                    self.addLikeDislike(item: item, likesType: "likes", myLikesType: "myLikes", myLikedNumber: "myLikedNumber")
                }
            } else { //removing like, adding Dislike
                if ratingLikeCheck == 1 { // removing dislike
                    self.removeLikeDislike(item: item, likesType: "dislikes", myLikesType: "myDislikes", myLikedNumber: "myDislikedNumber")
                } else if ratingLikeCheck == 2 { //remove like, add dislike
                    self.removeOneAddOne(item: item, likesType: "dislikes", myLikesType: "myDislikes", rLikeType: "likes", rMyLikesType: "myLikes")
                } else if ratingLikeCheck == 3 { // add dislike
                    self.addLikeDislike(item: item, likesType: "dislikes", myLikesType: "myDislikes", myLikedNumber: "myDislikedNumber")
                }
            }
        }
    }
    
    func likeDislikeProcess2(likeType: Bool, ratingLikeCheck: UInt8, itemID: String, profID: String, userID: String, uLikeNum: Int, uDislikeNum: Int) { //BiggerRating process
        if likeType {
            if ratingLikeCheck == 1 { //removing like
                self.removeLikeDislike2(itemID: itemID, profID: profID, userID: userID, uLikeNum: uLikeNum, uDislikeNum: uDislikeNum, likesType: "likes", myLikesType: "myLikes", myLikedNumber: "myLikedNumber")
            } else if ratingLikeCheck == 2 { //remove dislike, add like
                self.removeOneAddOne2(itemID: itemID, profID: profID, userID: userID, uLikeNum: uLikeNum, uDislikeNum: uDislikeNum, likesType: "likes", myLikesType: "myLikes", rLikeType: "dislikes", rMyLikesType: "myDislikes")
            } else if ratingLikeCheck == 3 { // add like
                self.addLikeDislike2(itemID: itemID, profID: profID, userID: userID, uLikeNum: uLikeNum, uDislikeNum: uDislikeNum, likesType: "likes", myLikesType: "myLikes", myLikedNumber: "myLikedNumber")
            }
        } else { //removing like, adding Dislike
            if ratingLikeCheck == 1 { // removing dislike
                self.removeLikeDislike2(itemID: itemID, profID: profID, userID: userID, uLikeNum: uLikeNum, uDislikeNum: uDislikeNum, likesType: "dislikes", myLikesType: "myDislikes", myLikedNumber: "myDislikedNumber")
            } else if ratingLikeCheck == 2 { //remove like, add dislike
                self.removeOneAddOne2(itemID: itemID, profID: profID, userID: userID, uLikeNum: uLikeNum, uDislikeNum: uDislikeNum, likesType: "dislikes", myLikesType: "myDislikes", rLikeType: "likes", rMyLikesType: "myLikes")
            } else if ratingLikeCheck == 3 { // add dislike
                self.addLikeDislike2(itemID: itemID, profID: profID, userID: userID, uLikeNum: uLikeNum, uDislikeNum: uDislikeNum, likesType: "dislikes", myLikesType: "myDislikes", myLikedNumber: "myDislikedNumber")
            }
        }
    }
    
    func removeLikeDislike(item: CommentItem, likesType: String, myLikesType: String, myLikedNumber: String) {
        let myID = Auth.auth().currentUser?.uid ?? ""
        ref.child("ratings").child("withComment").child(item.itemID).observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            if snapshot.childSnapshot(forPath: likesType).exists() {
                for d in snapshot.childSnapshot(forPath: likesType).children {
                    let snap = d as! DataSnapshot
                    if snap.key == myID {
                        self.ref.child("ratings").child("withComment").child(item.itemID).child(likesType).child(myID).removeValue()
                        self.ref.child("users").child(item.userID).observeSingleEvent(of: .value) { (snapshot2,error2) in
                            if let error = error2 {
                                print("error",error)
                                return
                            }
                            if snapshot2.childSnapshot(forPath: myLikesType).exists() {
                                for d1 in snapshot2.childSnapshot(forPath: myLikesType).children {
                                    let snap = d1 as! DataSnapshot
                                    if snap.key == item.itemID {
                                        self.ref.child("users").child(myID)
                                            .child(myLikesType).child(item.itemID).removeValue()
                                        var popNum = snapshot.childSnapshot(forPath: "popularity").value as? Int ?? 0
                                        var newNum = snapshot2.childSnapshot(forPath: myLikedNumber).value as? Int ?? 0
                                        if likesType == "likes" {
                                            newNum -= 1
                                            popNum -= 1
                                            HandleNotifications().deleteNotification(type: 1,userID: item.userID,ratingID: item.itemID)
                                        } else if likesType == "dislikes" {
                                            //newNum = Int(item.userDislikedNum ?? 0)
                                            newNum -= 1
                                            popNum += 1
                                            HandleNotifications().deleteNotification(type: 2,userID: item.userID,ratingID: item.itemID)
                                        }
                                        self.ref.child("ratings").child("withComment").child(item.itemID).child("popularity").setValue(popNum)
                                        self.ref.child("Professors").child(item.profID).child("ratings_comment").child(item.itemID).setValue(popNum)
                                        self.ref.child("users").child(item.userID).child(myLikedNumber).setValue(newNum)
                                        break
                                    }
                                }
                            }
                        }
                        break
                    }
                }
            }
        }
    }
    
    func removeLikeDislike2(itemID: String, profID: String, userID: String, uLikeNum: Int, uDislikeNum: Int, likesType: String, myLikesType: String, myLikedNumber: String) {
        let myID = Auth.auth().currentUser?.uid ?? ""
        ref.child("ratings").child("withComment").child(itemID).observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            if snapshot.childSnapshot(forPath: likesType).exists() {
                for d in snapshot.childSnapshot(forPath: likesType).children {
                    let snap = d as! DataSnapshot
                    if snap.key == myID {
                        self.ref.child("ratings").child("withComment").child(itemID).child(likesType).child(myID).removeValue()
                        self.ref.child("users").child(myID).observeSingleEvent(of: .value) { (snapshot2,error2) in
                            if let error = error2 {
                                print("error",error)
                                return
                            }
                            if snapshot2.childSnapshot(forPath: myLikesType).exists() {
                                for d1 in snapshot2.childSnapshot(forPath: myLikesType).children {
                                    let snap = d1 as! DataSnapshot
                                    if snap.key == itemID {
                                        self.ref.child("users").child(myID)
                                            .child(myLikesType).child(itemID).removeValue()
                                        var popNum = snapshot.childSnapshot(forPath: "popularity").value as? Int ?? 0
                                        var newNum = snapshot2.childSnapshot(forPath: myLikedNumber).value as? Int ?? 0
                                        if likesType == "likes" {
                                           // newNum = uLikeNum
                                            newNum -= 1
                                            popNum -= 1
                                            HandleNotifications().deleteNotification(type: 1,userID: userID,ratingID: itemID)
                                        } else if likesType == "dislikes" {
                                          //  newNum = uDislikeNum
                                            newNum -= 1
                                            popNum += 1
                                            HandleNotifications().deleteNotification(type: 2,userID: userID,ratingID: itemID)
                                        }
                                        self.ref.child("ratings").child("withComment").child(itemID).child("popularity").setValue(popNum)
                                        self.ref.child("Professors").child(profID).child("ratings_comment").child(itemID).setValue(popNum)
                                        self.ref.child("users").child(userID).child(myLikedNumber).setValue(newNum)
                                        break
                                    }
                                }
                            }
                        }
                        break
                    }
                }
            }
        }
    }
    
    func addLikeDislike(item: CommentItem, likesType: String, myLikesType: String, myLikedNumber: String) {
        let myID = Auth.auth().currentUser?.uid ?? ""
        let cTime = Date().currentTimeMillis()
        ref.child("ratings").child("withComment").child(item.itemID).child(likesType).child(myID).setValue(true)
        ref.child("users").child(myID).child(myLikesType).child(item.itemID).setValue(cTime)
        ref.child("ratings").child("withComment").child(item.itemID).observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            self.ref.child("users").child(item.userID).observeSingleEvent(of: .value) { (snapshot2,error) in
                if let error = error {
                    print("error",error)
                    return
                }
                var popNum = snapshot.childSnapshot(forPath: "popularity").value as? Int ?? 0
                var newNum = snapshot2.childSnapshot(forPath: myLikedNumber).value as? Int ?? 0
                if likesType == "likes" {
                  //  newNum = Int(item.userLikedNum ?? 0)
                    popNum = popNum + 1;
                    newNum += 1
                    HandleNotifications().addNotification(profID: item.profID,type: 1,userID: item.userID,ratingID: item.itemID)
                } else if likesType == "dislikes" {
                    //newNum = Int(item.userDislikedNum ?? 0)
                    popNum = popNum - 1;
                    newNum += 1
                    HandleNotifications().addNotification(profID: item.profID,type: 2,userID: item.userID,ratingID: item.itemID)
                }
                self.ref.child("ratings").child("withComment").child(item.itemID).child("popularity").setValue(popNum);
                self.ref.child("Professors").child(item.profID).child("ratings_comment").child(item.itemID).setValue(popNum);
                self.ref.child("users").child(item.userID).child(myLikedNumber).setValue(newNum)
            }
        }
    }
    
    func addLikeDislike2(itemID: String, profID: String, userID: String, uLikeNum: Int, uDislikeNum: Int, likesType: String, myLikesType: String, myLikedNumber: String) {
        let myID = Auth.auth().currentUser?.uid ?? ""
        let cTime = Date().currentTimeMillis()
        ref.child("ratings").child("withComment").child(itemID).child(likesType).child(myID).setValue(true)
        ref.child("users").child(myID).child(myLikesType).child(itemID).setValue(cTime)
        ref.child("ratings").child("withComment").child(itemID).observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            self.ref.child("users").child(myID).observeSingleEvent(of: .value) { (snapshot2,error) in
                if let error = error {
                    print("error",error)
                    return
                }
                var popNum = snapshot.childSnapshot(forPath: "popularity").value as? Int ?? 0
                var newNum = snapshot2.childSnapshot(forPath: myLikedNumber).value as? Int ?? 0
                if likesType == "likes" {
                  //  newNum = uLikeNum
                    popNum = popNum + 1;
                    newNum += 1
                    HandleNotifications().addNotification(profID: profID,type: 1,userID: userID,ratingID: itemID)
                } else if likesType == "dislikes" {
                   // newNum = uDislikeNum
                    popNum = popNum - 1;
                    newNum += 1
                    HandleNotifications().addNotification(profID: profID,type: 2,userID: userID,ratingID: itemID)
                }
                self.ref.child("ratings").child("withComment").child(itemID).child("popularity").setValue(popNum);
                self.ref.child("Professors").child(profID).child("ratings_comment").child(itemID).setValue(popNum);
                self.ref.child("users").child(userID).child(myLikedNumber).setValue(newNum)
            }
        }
    }
    
    private func removeOneAddOne(item: CommentItem, likesType: String, myLikesType: String, rLikeType: String, rMyLikesType: String) {
        let myID = Auth.auth().currentUser?.uid ?? ""
        ref.child("ratings").child("withComment").child(item.itemID).observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            let cTime = Date().currentTimeMillis()
            self.ref.child("ratings").child("withComment").child(item.itemID).child(likesType).child(myID).setValue(true);
            self.ref.child("users").child(myID).child(myLikesType).child(item.itemID).setValue(cTime);
            self.ref.child("ratings").child("withComment").child(item.itemID).observeSingleEvent(of: .value) { (snapshot,error) in
                if let error = error {
                    print("error",error)
                    return
                }
                var popNum = snapshot.childSnapshot(forPath: "popularity").value as? Int ?? 0
                if snapshot.childSnapshot(forPath: rLikeType).exists() {
                    for d in snapshot.childSnapshot(forPath: rLikeType).children {
                        let snap = d as! DataSnapshot
                        if snap.key == myID {
                            self.ref.child("ratings").child("withComment").child(item.itemID).child(rLikeType).child(myID).removeValue()
                            self.ref.child("users").child(item.userID).observeSingleEvent(of: .value) { (snapshot2,error2) in
                                if let error = error2 {
                                    print("error",error)
                                    return
                                }
                                if snapshot2.childSnapshot(forPath: rMyLikesType).exists() {
                                    for d1 in snapshot2.childSnapshot(forPath: rMyLikesType).children {
                                        let snap = d1 as! DataSnapshot
                                        if snap.key == item.itemID {
                                            self.ref.child("users").child(myID).child(rMyLikesType).child(item.itemID).removeValue()
                                            var newLiked = snapshot2.childSnapshot(forPath: "myLikedNumber").value as? Int ?? 0
                                            var newDis = snapshot2.childSnapshot(forPath: "myDislikedNumber").value as? Int ?? 0
                                            if likesType == "likes" {
                                                popNum += 2
                                              //  newLiked = Int(item.userLikedNum ?? 0)
                                                newLiked += 1
                                              //  newDis = Int(item.userDislikedNum ?? 0)
                                                newDis -= 1
                                            } else if likesType == "dislikes" {
                                                popNum -= 2
                                              //  newLiked = Int(item.userLikedNum ?? 0)
                                                newLiked -= 1
                                              //  newDis = Int(item.userDislikedNum ?? 0)
                                                newDis += 1
                                            }
                                            self.ref.child("ratings").child("withComment").child(item.itemID).child("popularity").setValue(popNum)
                                            self.ref.child("Professors").child(item.profID).child("ratings_comment").child(item.itemID).setValue(popNum)
                                            self.ref.child("users").child(item.userID).child("myDislikedNumber").setValue(newDis)
                                            self.ref.child("users").child(item.userID).child("myLikedNumber").setValue(newLiked)
                                            if likesType == "likes" {
                                                HandleNotifications().addNotification(profID: item.profID,type: 2,userID: item.userID,ratingID: item.itemID)
                                                HandleNotifications().deleteNotification(type: 1,userID: item.userID,ratingID: item.itemID)
                                            } else if likesType == "dislikes" {
                                                HandleNotifications().addNotification(profID: item.profID,type: 1,userID: item.userID,ratingID: item.itemID)
                                                HandleNotifications().deleteNotification(type: 2,userID: item.userID,ratingID: item.itemID)
                                            }
                                            break
                                        }
                                    }
                                }
                            }
                            break
                        }
                    }
                }
            }
        }
    }
    
    func removeOneAddOne2(itemID: String, profID: String, userID: String, uLikeNum: Int, uDislikeNum: Int, likesType: String, myLikesType: String, rLikeType: String, rMyLikesType: String) {
        let myID = Auth.auth().currentUser?.uid ?? ""
        ref.child("ratings").child("withComment").child(itemID).observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            let cTime = Date().currentTimeMillis()
            self.ref.child("ratings").child("withComment").child(itemID).child(likesType).child(myID).setValue(true);
            self.ref.child("users").child(myID).child(myLikesType).child(itemID).setValue(cTime);
            self.ref.child("ratings").child("withComment").child(itemID).observeSingleEvent(of: .value) { (snapshot,error) in
                if let error = error {
                    print("error",error)
                    return
                }
                var popNum = snapshot.childSnapshot(forPath: "popularity").value as? Int ?? 0
                if snapshot.childSnapshot(forPath: rLikeType).exists() {
                    for d in snapshot.childSnapshot(forPath: rLikeType).children {
                        let snap = d as! DataSnapshot
                        if snap.key == myID {
                            self.ref.child("ratings").child("withComment").child(itemID).child(rLikeType).child(myID).removeValue()
                            self.ref.child("users").child(myID).observeSingleEvent(of: .value) { (snapshot2,error2) in
                                if let error = error2 {
                                    print("error",error)
                                    return
                                }
                                if snapshot2.childSnapshot(forPath: rMyLikesType).exists() {
                                    for d1 in snapshot2.childSnapshot(forPath: rMyLikesType).children {
                                        let snap = d1 as! DataSnapshot
                                        if snap.key == itemID {
                                            self.ref.child("users").child(myID).child(rMyLikesType).child(itemID).removeValue()
                                            var newLiked = snapshot2.childSnapshot(forPath: "myLikedNumber").value as? Int ?? 0
                                            var newDis = snapshot2.childSnapshot(forPath: "myDislikedNumber").value as? Int ?? 0
                                            if likesType == "likes" {
                                                popNum += 2
                                              //  newLiked = uLikeNum
                                                newLiked += 1
                                              //  newDis = uDislikeNum
                                                newDis -= 1
                                            } else if likesType == "dislikes" {
                                                popNum -= 2
                                              //  newLiked = uLikeNum
                                                newLiked -= 1
                                              //  newDis = uDislikeNum
                                                newDis += 1
                                            }
                                            self.ref.child("ratings").child("withComment").child(itemID).child("popularity").setValue(popNum)
                                            self.ref.child("Professors").child(profID).child("ratings_comment").child(itemID).setValue(popNum)
                                            self.ref.child("users").child(userID).child("myDislikedNumber").setValue(newDis)
                                            self.ref.child("users").child(userID).child("myLikedNumber").setValue(newLiked)
                                            if likesType == "likes" {
                                                HandleNotifications().addNotification(profID: profID,type: 2,userID: userID,ratingID: itemID)
                                                HandleNotifications().deleteNotification(type: 1,userID: userID,ratingID: itemID)
                                            } else if likesType == "dislikes" {
                                                HandleNotifications().addNotification(profID: profID,type: 1,userID: userID,ratingID: itemID)
                                                HandleNotifications().deleteNotification(type: 2,userID: userID,ratingID: itemID)
                                            }
                                            break
                                        }
                                    }
                                }
                            }
                            break
                        }
                    }
                }
            }
        }
    }
    
}
