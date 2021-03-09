//
//  HandleNotifications.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 08..
//

import Foundation
import Firebase

class HandleNotifications {
    let ref = Database.database().reference()
    //MARK: Add Notification
    func addNotification(profID: String,type : Int,userID: String,ratingID: String){
        let myID = Auth.auth().currentUser?.uid ?? ""
        ref.child("ratings").child("withComment").child(ratingID).observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            self.ref.child("Professors").child(profID).observeSingleEvent(of: .value) { (snapshot2,error2) in
                if let error = error2 {
                    print("error",error)
                    return
                }
                let cTime = Date().currentTimeMillis()
                let not = ["ratingID" : ratingID, "userID" : myID, "profName" : snapshot2.childSnapshot(forPath: "prof_name").value as? String ?? "", "picName" : type, "time" : cTime] as [String : Any]
                let key = self.ref.child("users").child(userID).child("myNotifications").childByAutoId()
                key.setValue(not)
                if(type==1){
                    key.child("totalLikes").setValue(snapshot.childSnapshot(forPath: "likes").childrenCount)
                    self.sendPushNotification(userID: userID, type: 1,ratingID: ratingID)
                }else{
                    key.child("totalDislikes").setValue(snapshot.childSnapshot(forPath: "dislikes").childrenCount)
                    self.sendPushNotification(userID: userID, type: 2,ratingID: ratingID)
                }
            }
        }
    }
    //MARK: Delete Notification
    func deleteNotification(type: Int,userID: String,ratingID: String){
        let ref2 = ref.child("users").child(userID).child("myNotifications")
        ref2.observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            if snapshot.exists() {
                for d in snapshot.children {
                    let snap = d as! DataSnapshot
                    if ((snap.childSnapshot(forPath: "ratingID").value as? String ?? "") == ratingID) && ((snap.childSnapshot(forPath: "userID").value as? String ?? "") == userID) && ((snap.childSnapshot(forPath: "picName").value as? String ?? "") == String(type)) {
                        ref2.child(snap.key).removeValue()
                    }
                }
            }
        }
    }
    
    func sendPushNotification(userID: String, type: Int8, ratingID: String) {
        print("deneme userID", userID)
        self.ref.child("users").child(userID).observeSingleEvent(of: .value) { (snapshot3,error3) in
            if let error = error3 {
                print("error",error)
                return
            }
            let token = snapshot3.childSnapshot(forPath: "fcm_token").value as? String ?? ""
            let sender = PushNotificationSender()
            if type == 1 {
                let txt = NSLocalizedString("push_not_like", comment: "")
                let title = NSLocalizedString("push_not_like_t", comment: "")
                sender.sendPushNotification(to: token, title: title, body: txt,notID: ratingID)
            } else {
                let txt = NSLocalizedString("push_not_dislike", comment: "")
                let title = NSLocalizedString("push_not_dislike_t", comment: "")
                sender.sendPushNotification(to: token, title: title, body: txt,notID: ratingID)
            }
        }
    }

}
