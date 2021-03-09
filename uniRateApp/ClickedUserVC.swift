//
//  ClickedUserVC.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 09..
//

import UIKit
import Firebase
class ClickedUserVC: UIViewController {
    
    var userID : String?
    @IBOutlet private weak var userImage: UIImageView!
    @IBOutlet private weak var username: UILabel!
    @IBOutlet private weak var uniName: UILabel!
    @IBOutlet private weak var fieldName: UILabel!
    @IBOutlet private weak var totalRatings: UILabel!
    @IBOutlet private weak var likes: UILabel!
    @IBOutlet private weak var dislikes: UILabel!
    @IBOutlet private weak var rLikes: UILabel!
    @IBOutlet private weak var rDislikes: UILabel!
    @IBOutlet private weak var userAvg: UILabel!
    @IBOutlet private weak var emptyView: UIView!
    @IBOutlet private weak var collectionView: UICollectionView!
    private let design : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    private var ref = DatabaseReference()
    private let cellID = "commentCell"
    private var cNumber = 0
    private var numOfItems = 10
    private var lastPage = false
    private var list = [CommentItem]()
    private var ids = [String]()
    private var uName,uField,unName,uPhoto,sendProfId : String?
    private var mLiked,mDisliked : Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        loadUserData()
        loadRatings()
        self.collectionView.dataSource = self
        self.collectionView.delegate = collectionView.dataSource as? UICollectionViewDelegate
        design.minimumLineSpacing = 0
        collectionView.collectionViewLayout = design
    }
    //MARK: Load User Data
    @objc fileprivate func loadUserData() {
        ref.child("users").child(userID ?? "").observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            if snapshot.exists() {
                self.cNumber = Int(snapshot.childSnapshot(forPath: "myRatings").childrenCount)
                self.uName = snapshot.childSnapshot(forPath: "username").value as? String
                self.unName = snapshot.childSnapshot(forPath: "university").value as? String
                self.uField = snapshot.childSnapshot(forPath: "faculty").value as? String
                self.username.text = self.uName
                self.uniName.text = self.unName
                self.fieldName.text = self.uField
                if snapshot.childSnapshot(forPath: "myRatings").exists() {
                    let num = snapshot.childSnapshot(forPath: "myRatings").childrenCount as UInt
                    self.totalRatings.text = String(num)
                } else {
                    self.totalRatings.text = "0"
                }
                if snapshot.childSnapshot(forPath: "myLikes").exists() {
                    let num = snapshot.childSnapshot(forPath: "myLikes").childrenCount as UInt
                    self.likes.text = String(num)
                } else {
                    self.likes.text = "0"
                }
                if snapshot.childSnapshot(forPath: "myDislikes").exists() {
                    let num = snapshot.childSnapshot(forPath: "myDislikes").childrenCount as UInt
                    self.dislikes.text = String(num)
                } else {
                    self.dislikes.text = "0"
                }
                if snapshot.childSnapshot(forPath: "myLikedNumber").exists() {
                    self.mLiked = snapshot.childSnapshot(forPath: "myLikedNumber").value as? Int ?? 0
                    self.rLikes.text = String(self.mLiked ?? 0)
                } else {
                    self.rLikes.text = "0"
                }
                if snapshot.childSnapshot(forPath: "myDislikedNumber").exists() {
                    self.mDisliked = snapshot.childSnapshot(forPath: "myDislikedNumber").value as? Int ?? 0
                    self.rDislikes.text = String(self.mDisliked ?? 0)
                } else {
                    self.rDislikes.text = "0"
                }
                let avgNum = (self.mLiked ?? 0) - (self.mDisliked ?? 0)
                self.userAvg.text = "("+String(avgNum)+")"
                self.uPhoto = snapshot.childSnapshot(forPath: "photo").value as? String
                self.userImage.image = UIImage.init(named: self.uPhoto ?? "pp1")
            }
        }
    }
    //MARK: Load Ratings
    @objc fileprivate func loadRatings() {
        var spinner = UIActivityIndicatorView()
        if #available(iOS 13.0, *) {
            spinner = UIActivityIndicatorView(style: .large)
        } else {
            spinner = UIActivityIndicatorView(style: .gray)
        }
        spinner.color = UIColor.init(named: "appBlueColor")
        spinner.startAnimating()
        collectionView.backgroundView = spinner
        ref.child("users").child(userID ?? "").child("myRatings").queryOrderedByKey().queryLimited(toLast: UInt(numOfItems)).observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            let num = snapshot.childrenCount
            if num == 0 {
                self.collectionView.backgroundView = nil
                if self.emptyView != nil {
                   self.emptyView.isHidden = false
                }
            } else {
                if self.emptyView != nil {
                    self.emptyView.isHidden = true
                }
            }
            if snapshot.exists() {
                self.list.removeAll()
                for d in snapshot.children {
                    let snap = d as! DataSnapshot
                    if snap.value as? Bool ?? true {
                        self.addRating(ratingID: snap.key, check: true)
                    } else {
                        self.addRating(ratingID: snap.key, check: false)
                    }
                }
            }
        }
    }
    //MARK: Load More
    @objc fileprivate func loadMore() {
        let number = list.count
        ref.child("users").child(userID ?? "").child("myRatings").queryOrderedByKey().queryLimited(toLast: UInt(numOfItems)).observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            var count = 0
            self.ids.removeAll()
            for d in snapshot.children {
                let snap = d as! DataSnapshot
                self.ids.append(snap.key)
            }
            self.ids.reverse()
            for s in self.ids {
                if count >= number {
                    if snapshot.childSnapshot(forPath: s).value as? Bool ?? true {
                        self.addRating(ratingID: s, check: true)
                    } else {
                        self.addRating(ratingID: s, check: false)
                    }
                }
                count += 1
            }
        }
    }
    //MARK: Add Rating
    @objc fileprivate func addRating(ratingID: String, check: Bool){
        var mRef = DatabaseQuery()
        if check {
            mRef = ref.child("ratings").child("withComment").child(ratingID)
        } else {
            mRef = ref.child("ratings").child("noComment").child(ratingID)
        }
        mRef.observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            let avg = snapshot.childSnapshot(forPath: "avg_rating").value as? Double ?? 0.0
            let help = Double(snapshot.childSnapshot(forPath: "helpfulness").value as? String ?? "0") ?? 0.0
            let diff = Double(snapshot.childSnapshot(forPath: "difficulty").value as? String ?? "0") ?? 0.0
            let lec = Double(snapshot.childSnapshot(forPath: "lecture").value as? String ?? "0") ?? 0.0
            let cItem = ["username" : self.uName ?? "", "photo" : self.uPhoto ?? "pp1", "userID" : self.userID ?? "", "university" : self.unName ?? "", "faculty" : self.uField ?? "", "avgRating" : avg, "helpNum" : help, "diffNum" : diff, "lecNum" : lec, "comment" : "", "time" : snapshot.childSnapshot(forPath: "time").value as? UInt ?? 0, "popularity" : snapshot.childSnapshot(forPath: "popularity").value as? UInt ?? 0, "itemID" : ratingID, "profID" : snapshot.childSnapshot(forPath: "profID").value as? String ?? "", "check" : true] as [String : Any]
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
            if check {
                commentItem.userLikedNum = self.mLiked ?? 0
                commentItem.userDislikedNum = self.mDisliked ?? 0
                commentItem.comment = snapshot.childSnapshot(forPath: "comment").value as? String ?? ""
            }
            commentItem.type = "5"
            self.list.append(commentItem)
            self.list.sort {
               $0.time > $1.time
            }
            DispatchQueue.main.async {
                self.collectionView.backgroundView = nil
                self.collectionView.reloadData()
            }
        }
    }
    //MARK: Utils
    @objc fileprivate func showAlert(type: Int8) {
        var msg = String()
        if type == 1 {
            msg = NSLocalizedString("likeDislike_exp", comment: "")
        } else if type == 2 {
            msg = NSLocalizedString("reportLogin_exp", comment: "")
        } else {
            msg = NSLocalizedString("rateLogin_exp", comment: "")
        }
        let alert = UIAlertController(title: NSLocalizedString("info", comment: ""), message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .default, handler: { [weak alert] (_) in
            alert?.dismiss(animated: true, completion: {})
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("login", comment: ""), style: .default, handler: { [weak alert] (_) in
            alert?.dismiss(animated: true, completion: {})
            self.performSegue(withIdentifier: "clickedProfToLoginSegue", sender: self)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("sign_up", comment: ""), style: .default, handler: { [weak alert] (_) in
            alert?.dismiss(animated: true, completion: {})
            self.performSegue(withIdentifier: "clickedProfToSignUpSegue", sender: self)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "clickedUserToProfSegue" {
            let vc = segue.destination as? ClickedProfVC
            vc?.profID = sendProfId
        }
    }
}
//MARK: CollectionView Extensions
extension ClickedUserVC: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate, CommentCellDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return list.count
    }
        
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! CommentCell
        cell.configure(with: self.list[indexPath.row])
        cell.delegate = self
        return cell
    }

   func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 246 //dummyCell.header.bounds.height
        let yourString = list[indexPath.row].comment
        let textSize = yourString.size(width: collectionView.frame.width - 30)
        height += textSize.height
        if list[indexPath.row].attNum != nil && list[indexPath.row].txtNum != nil {
            height += 37
        }else if list[indexPath.row].attNum != nil || list[indexPath.row].txtNum != nil  {
            height += 15
        }else {
            height -= 5
        }
        return CGSize(width: collectionView.frame.width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == self.list.count - 1 && !lastPage{
            if ((cNumber) - numOfItems) > 10 {
                numOfItems += 10
            } else {
                numOfItems += ((cNumber) - numOfItems)
                lastPage = true
            }
            if !(self.list.count < 10) {
                DispatchQueue.main.async {
                    self.loadMore()
                }
            }
        }
    }
    //MARK: onClick Actions
    func postLiked(cell: CommentCell, likeCheck: Bool, dislikeCheck: Bool) {
        if Auth.auth().currentUser != nil {
            guard let indexPath = collectionView.indexPath(for: cell) else {return}
            let comment = self.list[indexPath.row]
            //MARK: Like
            if likeCheck { // only like exists //remove like
                cell.likeCheck = false
                cell.likeButton?.setImage(UIImage.init(named: "likeEmpty"), for: .normal)
                var lNum = Int(comment.likeNum ?? 0)
                lNum -= 1
                self.list[indexPath.row].likeNum = lNum
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
                self.list[indexPath.row].likeNum = lNum
                self.list[indexPath.row].dislikeNum = disNum
                cell.likeNum?.text = String(lNum)
                cell.dislikeNum?.text = String(disNum)
                HandleLikeActions().likeDislikeProcess(type: 3, likeType: true, item: comment, ratingLikeCheck: 2)
            } else { // none exists // add like
                cell.likeCheck = true
                cell.likeButton?.setImage(UIImage.init(named: "likeFull"), for: .normal)
                var lNum = Int(comment.likeNum ?? 0)
                lNum += 1
                self.list[indexPath.row].likeNum = lNum
                cell.likeNum?.text = String(lNum)
                HandleLikeActions().likeDislikeProcess(type: 3, likeType: true, item: comment, ratingLikeCheck: 3)
            }
        } else {
            self.showAlert(type: 1)
        }
    }
    //MARK: Dislike
    func postDisliked(cell: CommentCell, likeCheck: Bool, dislikeCheck: Bool) {
        if Auth.auth().currentUser != nil {
            guard let indexPath = collectionView.indexPath(for: cell) else {return}
            let comment = self.list[indexPath.row]
            if likeCheck { // only like exists // remove like, add dislike
                cell.likeCheck = false
                cell.dislikeCheck = true
                cell.dislikeButton?.setImage(UIImage.init(named: "dislikeFull"), for: .normal)
                cell.likeButton?.setImage(UIImage.init(named: "likeEmpty"), for: .normal)
                var disNum = Int(comment.dislikeNum ?? 0)
                disNum += 1
                var lNum = Int(comment.likeNum ?? 0)
                lNum -= 1
                self.list[indexPath.row].likeNum = lNum
                self.list[indexPath.row].dislikeNum = disNum
                cell.likeNum?.text = String(lNum)
                cell.dislikeNum?.text = String(disNum)
                HandleLikeActions().likeDislikeProcess(type: 3, likeType: false, item: comment, ratingLikeCheck: 2)
            } else if dislikeCheck { // only dislike exists // remove dislike
                cell.dislikeCheck = false
                cell.dislikeButton?.setImage(UIImage.init(named: "dislikeEmpty"), for: .normal)
                var dNum = Int(comment.dislikeNum ?? 0)
                dNum -= 1
                self.list[indexPath.row].dislikeNum = dNum
                cell.dislikeNum?.text = String(dNum)
                HandleLikeActions().likeDislikeProcess(type: 3, likeType: false, item: comment, ratingLikeCheck: 1)
            } else { // none exists // add dislike
                cell.dislikeCheck = true
                cell.dislikeButton?.setImage(UIImage.init(named: "dislikeFull"), for: .normal)
                var disNum = Int(comment.dislikeNum ?? 0)
                disNum += 1
                self.list[indexPath.row].dislikeNum = disNum
                cell.dislikeNum?.text = String(disNum)
                HandleLikeActions().likeDislikeProcess(type: 3, likeType: false, item: comment, ratingLikeCheck: 3)
            }
        } else {
            self.showAlert(type: 1)
        }
    }
    //MARK: Delete
    func delete(cell: CommentCell) {
        if Auth.auth().currentUser != nil {
            guard let indexPath = collectionView.indexPath(for: cell) else {return}
            let comment = self.list[indexPath.row]
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
                    self.list.remove(at: indexPath.row)
                    self.collectionView.reloadData()
                    HandleDeleteReportActions().deleteProcess(item: comment)
                    alertController.dismiss(animated: true, completion: nil)
                }
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.showAlert(type: 2)
        }
    }
    //MARK: Report
    func report(cell: CommentCell) {
        if Auth.auth().currentUser != nil {
            guard let indexPath = collectionView.indexPath(for: cell) else {return}
            let comment = self.list[indexPath.row]
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
        } else {
            self.showAlert(type: 2)
        }
    }
    
    func profClicked(cell: CommentCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else {return}
        let comment = self.list[indexPath.row]
        sendProfId = comment.profID
        performSegue(withIdentifier: "clickedUserToProfSegue", sender: self)
    }
    
    func userClicked(cell: CommentCell) {
        //empty
    }
}

