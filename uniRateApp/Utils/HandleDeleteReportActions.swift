//
//  HandleDeleteReportActions.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 09..
//

import Foundation
import Firebase

class HandleDeleteReportActions {
    let ref = Database.database().reference()
    
    func deleteProcess(item: CommentItem) {
        ref.child("users").child(Auth.auth().currentUser?.uid ?? "").child("myRatings").child(item.itemID).removeValue()
        ref.child("ratings").child("withComment").child(item.itemID).removeValue()
        ref.child("Professors").child(item.profID).child("ratings_comment").child(item.itemID).removeValue()
        ref.child("Professors").child(item.profID).child("ratings_comment").child(item.itemID).removeValue()
        ref.child("Professors").child(item.profID).child("ratings_comment").child(item.itemID).removeValue()
        ref.child("Professors").child(item.profID).child("ratings_total").child(item.itemID).removeValue()
        ref.child("Professors").child(item.profID).observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            var help = snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "helpfulness").value as? Double ?? 0.0
            help = help - item.helpNum
            var diff = snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "difficulty").value as? Double ?? 0.0
            diff = diff - item.diffNum
            var lec = snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "lecture").value as? Double ?? 0.0
            lec = lec - item.lecNum
            self.ref.child("Professors").child("ratings").child("helpfulness").setValue(help)
            self.ref.child("Professors").child("ratings").child("difficulty").setValue(diff)
            self.ref.child("Professors").child("ratings").child("lecture").setValue(lec)
            self.updateRating(profID: item.profID)
        }
    }
    
    func deleteProcess2(profID: String, itemID: String, helpNum: Double, diffNum: Double, lecNum: Double) {
        ref.child("users").child(Auth.auth().currentUser?.uid ?? "").child("myRatings").child(itemID).removeValue()
        ref.child("ratings").child("withComment").child(itemID).removeValue()
        ref.child("Professors").child(profID).child("ratings_comment").child(itemID).removeValue()
        ref.child("Professors").child(profID).child("ratings_comment").child(itemID).removeValue()
        ref.child("Professors").child(profID).child("ratings_comment").child(itemID).removeValue()
        ref.child("Professors").child(profID).child("ratings_total").child(itemID).removeValue()
        ref.child("Professors").child(profID).observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            var help = snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "helpfulness").value as? Double ?? 0.0
            help = help - helpNum
            var diff = snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "difficulty").value as? Double ?? 0.0
            diff = diff - diffNum
            var lec = snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "lecture").value as? Double ?? 0.0
            lec = lec - lecNum
            self.ref.child("Professors").child(profID).child("ratings").child("helpfulness").setValue(help)
            self.ref.child("Professors").child(profID).child("ratings").child("difficulty").setValue(diff)
            self.ref.child("Professors").child(profID).child("ratings").child("lecture").setValue(lec)
            self.updateRating(profID: profID)
        }
    }
    
    func reportProcess(item: CommentItem) {
        let myID = Auth.auth().currentUser?.uid ?? ""
        let cTime = Date().currentTimeMillis()
        let report = ["time" : cTime, "userID" : myID, "commentID" : item.itemID] as [String : Any]
        ref.child("reports").childByAutoId().setValue(report)
    }
    
    func reportProcess2(commentID: String) {
        let myID = Auth.auth().currentUser?.uid ?? ""
        let cTime = Date().currentTimeMillis()
        let report = ["time" : cTime, "userID" : myID, "commentID" : commentID] as [String : Any]
        ref.child("reports").childByAutoId().setValue(report)
    }
    
    func updateRating(profID : String) {
        ref.child("Professors").child(profID).observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            let total = snapshot.childSnapshot(forPath: "ratings_total").childrenCount
            var ratings = 0.0
            var finalRating = 0.0
            if snapshot.childSnapshot(forPath: "ratings_total").exists() {
                for d in snapshot.childSnapshot(forPath: "ratings_total").children {
                    let snap = d as! DataSnapshot
                    let value = snap.value as? Double ?? 0.0
                    ratings = ratings + value
                }
                finalRating = ratings / Double(total)
            }
            if finalRating == 0 {
                self.ref.child("Professors").child(profID).child("ratings").removeValue()
            }
            self.ref.child("Professors").child(profID).child("avg_rating").setValue(finalRating)
            self.ref.child("Universities").child(snapshot.childSnapshot(forPath: "uni_name").value as? String ?? "").child("All professors").child(profID).setValue(finalRating)
            self.ref.child("Universities").child(snapshot.childSnapshot(forPath: "uni_name").value as? String ?? "").child(snapshot.childSnapshot(forPath: "field_name").value as? String ?? "").child(profID).setValue(finalRating)
            self.ref.child("Faculties").child(snapshot.childSnapshot(forPath: "field_name").value as? String ?? "").child(snapshot.childSnapshot(forPath: "city").value as? String ?? "").child(profID).setValue(finalRating);
            self.ref.child("Faculties").child(snapshot.childSnapshot(forPath: "field_name").value as? String ?? "").child("All professors").child(profID).setValue(finalRating)
            self.ref.child("Cities").child(snapshot.childSnapshot(forPath: "city").value as? String ?? "").child("All professors").child(profID).setValue(finalRating)
        }
    }
}
