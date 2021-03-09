//
//  CommentListVC.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 06..
//

import UIKit
import Firebase
import GoogleMobileAds

class CommentListVC: UIViewController {
    
    private var comments = [CommentItem]()
    private var ids = [String]()
    private let cellID = "commentCell"
    var type : String?
    var userModel : User?
    var commentNum : Int?
    private var numOfItems = 10
    private var lastPage = false
    private let ref = Database.database().reference()
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var banner: GADBannerView!
    private let design : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    private var sendProfId : String?
    private var sendUserId : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadRatings()
        self.collectionView.dataSource = self
        self.collectionView.delegate = collectionView.dataSource as? UICollectionViewDelegate
        design.minimumLineSpacing = 0
        collectionView.collectionViewLayout = design
        if type == "likes" {
            self.title = NSLocalizedString("my_likes", comment: "")
        } else if type == "dislikes" {
            self.title = NSLocalizedString("my_dislikes", comment: "")
        } else if type == "rating" {
            self.title = NSLocalizedString("my_ratings", comment: "")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        banner.adUnitID = "ca-app-pub-4004348027309516/8681030138"
        banner.rootViewController = self
        banner.load(GADRequest())
    }
    
    //MARK: Load Data
    @objc fileprivate func loadRatings() {
        var typeStr = String()
        var ref2 = DatabaseQuery()
        if type == "likes" {
            typeStr = "myLikes"
            ref2 = self.ref.child("users").child(userModel?.userID ?? "").child(typeStr).queryOrderedByValue().queryLimited(toLast: UInt(numOfItems))
        } else if type == "dislikes" {
            typeStr = "myDislikes"
            ref2 = self.ref.child("users").child(userModel?.userID ?? "").child(typeStr).queryOrderedByValue().queryLimited(toLast: UInt(numOfItems))
        } else if type == "rating" {
            typeStr = "myRatings"
            ref2 = self.ref.child("users").child(userModel?.userID ?? "yok").child(typeStr).queryOrderedByKey().queryLimited(toLast: UInt(numOfItems))
        }
        ref2.observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error", error)
                return
            }
            if snapshot.exists() {
                self.comments.removeAll()
                snapshot.children.forEach { (child) in
                    let snap = child as! DataSnapshot
                    if self.type == "rating" {
                        if (snap.value as? Bool ?? true) {
                            self.addRating2(ratingID: snap.key, cCheck: true)
                        } else {
                            self.addRating2(ratingID: snap.key, cCheck: false)
                        }
                    } else {
                        self.addRating(ratingID: snap.key)
                    }
                }
            }
        }
    }
    //MARK: LoadMore
    @objc fileprivate func loadMore() {
        var typeStr = String()
        var ref2 = DatabaseQuery()
        let num = comments.count
        let startKey = comments[num-1].itemID
        if type == "likes" {
            typeStr = "myLikes"
            ref2 = self.ref.child("users").child(userModel?.userID ?? "").child(typeStr).queryOrderedByValue().queryEnding(atValue: startKey).queryLimited(toLast: UInt(numOfItems))
        } else if type == "dislikes" {
            typeStr = "myDislikes"
            ref2 = self.ref.child("users").child(userModel?.userID ?? "").child(typeStr).queryOrderedByValue().queryEnding(atValue: startKey).queryLimited(toLast: UInt(numOfItems))
        } else if type == "rating" {
            typeStr = "myRatings"
            ref2 = self.ref.child("users").child(userModel?.userID ?? "").child(typeStr).queryOrderedByKey().queryLimited(toLast: UInt(numOfItems))
        }
        ref2.observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error", error)
                return
            }
            if snapshot.exists() {
                var count = 0
                self.ids.removeAll()
                snapshot.children.reversed().forEach { (child) in
                    let snap = child as! DataSnapshot
                    self.ids.append(snap.key)
                }
                for s in self.ids {
                    if count >= num {
                        if self.type == "rating" {
                            if (snapshot.childSnapshot(forPath: s).value as? Bool ?? true) {
                                self.addRating2(ratingID: s, cCheck: true)
                            } else {
                                self.addRating2(ratingID: s, cCheck: false)
                            }
                        } else {
                            self.addRating(ratingID: s)
                        }
                    }
                    count += 1
                }
            }
        }
    }
    //MARK: Add Rating2
    @objc fileprivate func addRating2(ratingID: String, cCheck: Bool) {
        if cCheck {
            addRating(ratingID: ratingID)
        } else {
            ref.child("ratings").child("noComment").child(ratingID).observeSingleEvent(of: .value) { (snapshot,error) in
                if let error = error {
                    print("error",error)
                    return
                }
                if snapshot.exists() {
                    self.ref.child("users").child(snapshot.childSnapshot(forPath: "userID").value as? String ?? "").observeSingleEvent(of: .value) { (snapshot2,error2) in
                        if let error = error2 {
                            print("error",error)
                            return
                        }
                        if snapshot2.exists() {
                            let avg = snapshot.childSnapshot(forPath: "avg_rating").value as? Double ?? 0.0
                            let help = Double(snapshot.childSnapshot(forPath: "helpfulness").value as? String ?? "0") ?? 0.0
                            let diff = Double(snapshot.childSnapshot(forPath: "difficulty").value as? String ?? "0") ?? 0.0
                            let lec = Double(snapshot.childSnapshot(forPath: "lecture").value as? String ?? "0") ?? 0.0
                            let cItem = ["username" : self.userModel?.username ?? "", "photo" : self.userModel?.photo ?? "", "userID" : self.userModel?.userID ?? "", "university" : self.userModel?.university ?? "", "faculty" : self.userModel?.faculty ?? "", "avgRating" : avg, "helpNum" : help, "diffNum" : diff, "lecNum" : lec, "comment" : snapshot.childSnapshot(forPath: "comment").value as? String ?? "", "time" : snapshot.childSnapshot(forPath: "time").value as? UInt ?? 0, "popularity" : snapshot.childSnapshot(forPath: "popularity").value as? UInt ?? 0, "itemID" : ratingID, "profID" : snapshot.childSnapshot(forPath: "profID").value as? String ?? "", "check" : true] as [String : Any]
                            var commentItem = CommentItem(commentData: cItem as [String : Any])
                            if snapshot.childSnapshot(forPath: "attendance").exists() {
                                commentItem.attNum = snapshot.childSnapshot(forPath: "attendance").value as? Double ?? 0.0
                            }
                            if snapshot.childSnapshot(forPath: "textbook").exists() {
                                commentItem.txtNum = snapshot.childSnapshot(forPath: "textbook").value as? Double ?? 0.0
                            }
                            commentItem.type = self.type
                            self.comments.append(commentItem)
                            self.comments.sort {
                               $0.time > $1.time
                            }
                            DispatchQueue.main.async {
                                self.collectionView.reloadData()
                            }
                        }
                    }
                }
            }
        }
        
    }
    //MARK: Add Rating
    @objc fileprivate func addRating(ratingID: String) {
        ref.child("ratings").child("withComment").child(ratingID).observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            if snapshot.exists() {
                self.ref.child("users").child(snapshot.childSnapshot(forPath: "userID").value as? String ?? "").observeSingleEvent(of: .value) { (snapshot2,error2) in
                    if let error = error2 {
                        print("error",error)
                        return
                    }
                    if snapshot2.exists() {
                        let avg = snapshot.childSnapshot(forPath: "avg_rating").value as? Double ?? 0.0
                        let help = Double(snapshot.childSnapshot(forPath: "helpfulness").value as? String ?? "0") ?? 0.0
                        let diff = Double(snapshot.childSnapshot(forPath: "difficulty").value as? String ?? "0") ?? 0.0
                        let lec = Double(snapshot.childSnapshot(forPath: "lecture").value as? String ?? "0") ?? 0.0
                        let cItem = ["username" : snapshot2.childSnapshot(forPath: "username").value as? String ?? "", "photo" : snapshot2.childSnapshot(forPath: "photo").value as? String ?? "pp1", "userID" : snapshot.childSnapshot(forPath: "userID").value as? String ?? "", "university" : snapshot2.childSnapshot(forPath: "university").value as? String ?? "", "faculty" : snapshot2.childSnapshot(forPath: "faculty").value as? String ?? "", "avgRating" : avg, "helpNum" : help, "diffNum" : diff, "lecNum" : lec, "comment" : snapshot.childSnapshot(forPath: "comment").value as? String ?? "", "time" : snapshot.childSnapshot(forPath: "time").value as? UInt ?? 0, "popularity" : snapshot.childSnapshot(forPath: "popularity").value as? UInt ?? 0, "itemID" : ratingID, "profID" : snapshot.childSnapshot(forPath: "profID").value as? String ?? "", "check" : true] as [String : Any]
                        var commentItem = CommentItem(commentData: cItem as [String : Any])
                        if snapshot.childSnapshot(forPath: "attendance").exists() {
                            commentItem.attNum = snapshot.childSnapshot(forPath: "attendance").value as? Double ?? 0.0
                        }
                        if snapshot.childSnapshot(forPath: "textbook").exists() {
                            commentItem.txtNum = snapshot.childSnapshot(forPath: "textbook").value as? Double ?? 0.0
                        }
                        if snapshot.childSnapshot(forPath: "likes").exists() {
                            commentItem.likeNum = Int(snapshot.childSnapshot(forPath: "likes").childrenCount)
                        }
                        if snapshot.childSnapshot(forPath: "dislikes").exists() {
                            commentItem.dislikeNum = Int(snapshot.childSnapshot(forPath: "dislikes").childrenCount)
                        }
                        if snapshot2.childSnapshot(forPath: "myLikedNumber").exists() {
                            commentItem.userLikedNum = Int(snapshot2.childSnapshot(forPath: "myLikedNumber").value as? String ?? "0") ?? 0
                        }
                        if snapshot2.childSnapshot(forPath: "myDislikedNumber").exists() {
                            commentItem.userDislikedNum = Int(snapshot2.childSnapshot(forPath: "myDislikedNumber").value as? String ?? "0") ?? 0
                        }
                        commentItem.type = self.type
                        self.comments.append(commentItem)
                        self.comments.sort {
                           $0.time > $1.time
                        }
                        DispatchQueue.main.async {
                            self.collectionView.reloadData()
                        }
                    }
                }
            }
        }
    }
    //MARK: PrepareSegue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "commentToProfSegue" {
           let cv = segue.destination as! ClickedProfVC
           cv.profID = sendProfId
        } else if segue.identifier == "commentToUserSegue" {
           let cv = segue.destination as! ClickedUserVC
           cv.userID = sendUserId
        }
    }
}
//MARK: CollectionView Extensions
extension CommentListVC: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate, CommentCellDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return comments.count
    }
        
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! CommentCell
        cell.configure(with: self.comments[indexPath.row])
        cell.delegate = self
        return cell
    }

   func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 246 //dummyCell.header.bounds.height
        let yourString = comments[indexPath.row].comment
        let textSize = yourString.size(width: collectionView.frame.width - 30)
        height += textSize.height
        if comments[indexPath.row].attNum != nil && comments[indexPath.row].txtNum != nil {
            height += 37
        }else if comments[indexPath.row].attNum != nil || comments[indexPath.row].txtNum != nil  {
            height += 15
        }else {
            height -= 5
        }
        return CGSize(width: collectionView.frame.width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == self.comments.count - 1 && !lastPage{
            if ((commentNum ?? 0) - numOfItems) > 10 {
                numOfItems += 10
            } else {
                numOfItems += ((commentNum ?? 0) - numOfItems)
                lastPage = true
            }
            if !(self.comments.count < 10) {
                DispatchQueue.main.async {
                    self.loadMore()
                }
            }
        }
    }
    //MARK: onClick Actions
    func postLiked(cell: CommentCell, likeCheck: Bool, dislikeCheck: Bool) {
        guard let indexPath = collectionView.indexPath(for: cell) else {return}
        let comment = self.comments[indexPath.row]
        //MARK: Like
        if type == "likes" { // remove like
            cell.likeButton?.setImage(UIImage.init(named: "likeEmpty"), for: .normal)
            var lNum = Int(comment.likeNum ?? 0)
            lNum -= 1
            cell.likeNum?.text = String(lNum)
            self.comments[indexPath.row].likeNum = lNum
            let when = DispatchTime.now() + 1
            DispatchQueue.main.asyncAfter(deadline: when){
                self.comments.remove(at: indexPath.row)
                self.collectionView.reloadData()
                HandleLikeActions().likeDislikeProcess(type: 1, likeType: true, item: comment, ratingLikeCheck: 0)
            }
        } else if type == "dislikes" { // remove dislike, add like
            cell.dislikeButton?.setImage(UIImage.init(named: "dislikeEmpty"), for: .normal)
            cell.likeButton?.setImage(UIImage.init(named: "likeFull"), for: .normal)
            var disNum = Int(comment.dislikeNum ?? 0)
            disNum -= 1
            var lNum = Int(comment.likeNum ?? 0)
            lNum += 1
            self.comments[indexPath.row].likeNum = lNum
            self.comments[indexPath.row].dislikeNum = disNum
            cell.likeNum?.text = String(lNum)
            cell.dislikeNum?.text = String(disNum)
            let when = DispatchTime.now() + 1
            DispatchQueue.main.asyncAfter(deadline: when){
                self.comments.remove(at: indexPath.row)
                self.collectionView.reloadData()
                HandleLikeActions().likeDislikeProcess(type: 2, likeType: true, item: comment, ratingLikeCheck: 0)
            }
        } else if type == "rating" {
            if likeCheck { // only like exists //remove like
                cell.likeCheck = false
                cell.likeButton?.setImage(UIImage.init(named: "likeEmpty"), for: .normal)
                var lNum = Int(comment.likeNum ?? 0)
                lNum -= 1
                self.comments[indexPath.row].likeNum = lNum
                cell.likeNum?.text = String(lNum)
                HandleLikeActions().likeDislikeProcess(type: 3, likeType: true, item: comment, ratingLikeCheck: 1)
            } else if dislikeCheck { // only dislike exists // remove dislike, add like
                cell.dislikeCheck = false
                cell.likeCheck = true
                cell.dislikeButton?.setImage(UIImage.init(named: "dislikeEmpty"), for: .normal)
                cell.likeButton?.setImage(UIImage.init(named: "likeFull"), for: .normal)
                var disNum = Int(comment.dislikeNum ?? 0)
                disNum -= 1
                var lNum = Int(comment.likeNum ?? 0)
                lNum += 1
                self.comments[indexPath.row].likeNum = lNum
                self.comments[indexPath.row].dislikeNum = disNum
                cell.likeNum?.text = String(lNum)
                cell.dislikeNum?.text = String(disNum)
                HandleLikeActions().likeDislikeProcess(type: 3, likeType: true, item: comment, ratingLikeCheck: 2)
            } else { // none exists // add like
                cell.likeCheck = true
                cell.likeButton?.setImage(UIImage.init(named: "likeFull"), for: .normal)
                var lNum = Int(comment.likeNum ?? 0)
                lNum += 1
                self.comments[indexPath.row].likeNum = lNum
                cell.likeNum?.text = String(lNum)
                HandleLikeActions().likeDislikeProcess(type: 3, likeType: true, item: comment, ratingLikeCheck: 3)
            }
        }
    }
    //MARK: Dislike
    func postDisliked(cell: CommentCell, likeCheck: Bool, dislikeCheck: Bool) {
        guard let indexPath = collectionView.indexPath(for: cell) else {return}
        let comment = self.comments[indexPath.row]
        if type == "likes" { // remove like, add dislike
            cell.dislikeButton?.setImage(UIImage.init(named: "dislikeFull"), for: .normal)
            cell.likeButton?.setImage(UIImage.init(named: "likeEmpty"), for: .normal)
            var disNum = Int(comment.dislikeNum ?? 0)
            disNum += 1
            var lNum = Int(comment.likeNum ?? 0)
            lNum -= 1
            self.comments[indexPath.row].likeNum = lNum
            self.comments[indexPath.row].dislikeNum = disNum
            cell.likeNum?.text = String(lNum)
            cell.dislikeNum?.text = String(disNum)
            let when = DispatchTime.now() + 1
            DispatchQueue.main.asyncAfter(deadline: when){
                self.comments.remove(at: indexPath.row)
                self.collectionView.reloadData()
                HandleLikeActions().likeDislikeProcess(type: 1, likeType: false, item: comment, ratingLikeCheck: 0)
            }
        } else if type == "dislikes" { // remove dislike
            cell.dislikeButton?.setImage(UIImage.init(named: "dislikeEmpty"), for: .normal)
            var dNum = Int(comment.dislikeNum ?? 0)
            dNum -= 1
            self.comments[indexPath.row].dislikeNum = dNum
            cell.dislikeNum?.text = String(dNum)
            let when = DispatchTime.now() + 1
            DispatchQueue.main.asyncAfter(deadline: when){
                self.comments.remove(at: indexPath.row)
                self.collectionView.reloadData()
                HandleLikeActions().likeDislikeProcess(type: 2, likeType: false, item: comment, ratingLikeCheck: 0)
            }
        } else if type == "rating" {
            if likeCheck { // only like exists // remove like, add dislike
                cell.likeCheck = false
                cell.dislikeCheck = true
                cell.dislikeButton?.setImage(UIImage.init(named: "dislikeFull"), for: .normal)
                cell.likeButton?.setImage(UIImage.init(named: "likeEmpty"), for: .normal)
                var disNum = Int(comment.dislikeNum ?? 0)
                disNum += 1
                var lNum = Int(comment.likeNum ?? 0)
                lNum -= 1
                self.comments[indexPath.row].likeNum = lNum
                self.comments[indexPath.row].dislikeNum = disNum
                cell.likeNum?.text = String(lNum)
                cell.dislikeNum?.text = String(disNum)
                HandleLikeActions().likeDislikeProcess(type: 3, likeType: false, item: comment, ratingLikeCheck: 2)
            } else if dislikeCheck { // only dislike exists // remove dislike
                cell.dislikeCheck = false
                cell.dislikeButton?.setImage(UIImage.init(named: "dislikeEmpty"), for: .normal)
                var dNum = Int(comment.dislikeNum ?? 0)
                dNum -= 1
                self.comments[indexPath.row].dislikeNum = dNum
                cell.dislikeNum?.text = String(dNum)
                HandleLikeActions().likeDislikeProcess(type: 3, likeType: false, item: comment, ratingLikeCheck: 1)
            } else { // none exists // add dislike
                cell.dislikeCheck = true
                cell.dislikeButton?.setImage(UIImage.init(named: "dislikeFull"), for: .normal)
                var disNum = Int(comment.dislikeNum ?? 0)
                disNum += 1
                self.comments[indexPath.row].dislikeNum = disNum
                cell.dislikeNum?.text = String(disNum)
                HandleLikeActions().likeDislikeProcess(type: 3, likeType: false, item: comment, ratingLikeCheck: 3)
            }
        }
    }
    //MARK: Delete
    func delete(cell: CommentCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else {return}
        let comment = self.comments[indexPath.row]
        let alert = UIAlertController(title: NSLocalizedString("delete", comment: ""), message: NSLocalizedString("delete_comment_exp", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .default, handler: { [weak alert] (_) in
            alert?.dismiss(animated: true, completion: {})
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("delete", comment: ""), style: .default, handler: { [weak alert] (_) in
            alert?.dismiss(animated: true, completion: {})
            let when = DispatchTime.now() + 2
            let alertController = UIAlertController(title: NSLocalizedString("successful", comment: ""), message: NSLocalizedString("deleted_comment", comment: ""), preferredStyle: .alert)
            self.present(alertController, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: when){
                self.comments.remove(at: indexPath.row)
                self.collectionView.reloadData()
                HandleDeleteReportActions().deleteProcess(item: comment)
                alertController.dismiss(animated: true, completion: nil)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    //MARK: Report
    func report(cell: CommentCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else {return}
        let comment = self.comments[indexPath.row]
        let alert = UIAlertController(title: NSLocalizedString("send_report", comment: ""), message: NSLocalizedString("send_report_exp", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("no", comment: ""), style: .default, handler: { [weak alert] (_) in
            alert?.dismiss(animated: true, completion: {})
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("yes", comment: ""), style: .default, handler: { [weak alert] (_) in
            alert?.dismiss(animated: true, completion: {})
            let when = DispatchTime.now() + 2
            HandleDeleteReportActions().reportProcess(item: comment)
            let alertController = UIAlertController(title: NSLocalizedString("successful", comment: ""), message: NSLocalizedString("sent_report", comment: ""), preferredStyle: .alert)
            self.present(alertController, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: when){
                alertController.dismiss(animated: true, completion: nil)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func profClicked(cell: CommentCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else {return}
        let comment = self.comments[indexPath.row]
        sendProfId = comment.profID
        performSegue(withIdentifier: "commentToProfSegue", sender: self)
    }
    
    func userClicked(cell: CommentCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else {return}
        let comment = self.comments[indexPath.row]
        sendUserId = comment.userID
        performSegue(withIdentifier: "commentToUserSegue", sender: self)
    }
}
