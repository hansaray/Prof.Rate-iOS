//
//  BiggerRatingVC.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 18..
//

import UIKit
import Firebase
import GoogleMobileAds

class BiggerRatingVC: UIViewController {
    
    var object : NotificationItem?
    var info : String?
    var notRatingID : String?
    private var userObject : User?
    private var ref = DatabaseReference()
    private var likeCheck = false
    private var dislikeCheck = false
    private var profID,commentTxt : String?
    private var likeNumber,dislikeNumber,myLiked,myDisliked : UInt?
    private var help,diff,lec : Double?
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var banner: GADBannerView!
    @IBOutlet private weak var profName: UILabel!
    @IBOutlet private weak var userImage: UIImageView!
    @IBOutlet private weak var username: UILabel!
    @IBOutlet private weak var avgNum: UILabel!
    @IBOutlet private weak var comment: UILabel!
    @IBOutlet private weak var helpNum: UILabel!
    @IBOutlet private weak var diffNum: UILabel!
    @IBOutlet private weak var lecNum: UILabel!
    @IBOutlet private weak var attStack: UIStackView!
    @IBOutlet private weak var attNum: UILabel!
    @IBOutlet private weak var txtStack: UIStackView!
    @IBOutlet private weak var txtNum: UILabel!
    @IBOutlet private weak var delete: UIButton!
    @IBOutlet private weak var report: UIButton!
    @IBOutlet private weak var like: UIButton!
    @IBOutlet private weak var likeNum: UILabel!
    @IBOutlet private weak var dislike: UIButton!
    @IBOutlet private weak var dislikeNum: UILabel!
    @IBOutlet private weak var time: UILabel!
    @IBOutlet private weak var faculty: UILabel!
    @IBOutlet private weak var university: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(profNamePressed))
        profName.addGestureRecognizer(tap)
        let tap1: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(userPressed))
        username.addGestureRecognizer(tap1)
        userImage.addGestureRecognizer(tap1)
        if object?.object != nil {
            userObject = object?.object
            if !(info?.isEmpty ?? true) {
                delete.isHidden = true
                self.loadDeletedData()
            } else {
                self.loadData()
            }
        } else if notRatingID != nil && !(notRatingID?.isEmpty ?? true){
            self.object?.ratingID = notRatingID ?? ""
            self.loadDataFromNotification(notID: notRatingID ?? "")
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        banner.adUnitID = "ca-app-pub-4004348027309516/7099175522"
        banner.rootViewController = self
        banner.load(GADRequest())
    }
    
    //MARK: onClick Actions
    @IBAction func deletePressed(_ sender: UIButton) {
        if Auth.auth().currentUser != nil {
            //MARK: Delete
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
                    HandleDeleteReportActions().deleteProcess2(profID: self.profID ?? "", itemID: self.object?.ratingID ?? "", helpNum: self.help ?? 0.0, diffNum: self.diff ?? 0.0, lecNum: self.lec ?? 0.0)
                    _ = self.navigationController?.popViewController(animated: true)
                    alertController.dismiss(animated: true, completion: nil)
                }
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.showAlert(type: 2)
        }
    }
    //MARK: Report
    @IBAction func reportPressed(_ sender: UIButton) {
        if Auth.auth().currentUser != nil {
            let alert = UIAlertController(title: NSLocalizedString("send_report", comment: ""), message: NSLocalizedString("send_report_exp", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("no", comment: ""), style: .default, handler: { [weak alert] (_) in
                alert?.dismiss(animated: true, completion: {})
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("yes", comment: ""), style: .default, handler: { [weak alert] (_) in
                alert?.dismiss(animated: true, completion: {})
                let when = DispatchTime.now() + 2
                HandleDeleteReportActions().reportProcess2(commentID: self.object?.ratingID ?? "")
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
    //MARK: Like
    @IBAction func likePressed(_ sender: UIButton) {
        if Auth.auth().currentUser != nil {
            let myID = Auth.auth().currentUser?.uid ?? ""
            if likeCheck { // only like exists //remove like
                likeCheck = false
                like.setImage(UIImage.init(named: "likeEmpty"), for: .normal)
                var lNum = likeNumber ?? 0
                lNum = lNum - 1
                likeNum.text = String(lNum)
                HandleLikeActions().likeDislikeProcess2(likeType: true, ratingLikeCheck: 1, itemID: self.object?.ratingID ?? "", profID: profID ?? "", userID: myID, uLikeNum: Int(myLiked ?? 0), uDislikeNum: Int(myDisliked ?? 0))
            } else if dislikeCheck { // only dislike exists // remove dislike, add like
                dislikeCheck = false
                likeCheck = true
                dislike.setImage(UIImage.init(named: "dislikeEmpty"), for: .normal)
                like.setImage(UIImage.init(named: "likeFull"), for: .normal)
                var disNum = dislikeNumber ?? 0
                disNum = disNum - 1
                var lNum = likeNumber ?? 0
                lNum = lNum + 1
                likeNum.text = String(lNum)
                dislikeNum.text = String(disNum)
                HandleLikeActions().likeDislikeProcess2(likeType: true, ratingLikeCheck: 2, itemID: self.object?.ratingID ?? "", profID: profID ?? "", userID: myID, uLikeNum: Int(myLiked ?? 0), uDislikeNum: Int(myDisliked ?? 0))
            } else { // none exists // add like
                likeCheck = true
                like.setImage(UIImage.init(named: "likeFull"), for: .normal)
                var lNum = likeNumber ?? 0
                lNum = lNum + 1
                likeNum.text = String(lNum)
                HandleLikeActions().likeDislikeProcess2(likeType: true, ratingLikeCheck: 3, itemID: self.object?.ratingID ?? "", profID: profID ?? "", userID: myID, uLikeNum: Int(myLiked ?? 0), uDislikeNum: Int(myDisliked ?? 0))
            }
        } else {
            self.showAlert(type: 1)
        }
    }
    //MARK: Dislike
    @IBAction func dislikePressed(_ sender: UIButton) {
        if Auth.auth().currentUser != nil {
            let myID = Auth.auth().currentUser?.uid ?? ""
            if likeCheck { // only like exists // remove like, add dislike
                likeCheck = false
                dislikeCheck = true
                dislike.setImage(UIImage.init(named: "dislikeFull"), for: .normal)
                like.setImage(UIImage.init(named: "likeEmpty"), for: .normal)
                var disNum = dislikeNumber ?? 0
                disNum = disNum + 1
                var lNum = likeNumber ?? 0
                lNum = lNum - 1
                likeNum.text = String(lNum)
                dislikeNum.text = String(disNum)
                HandleLikeActions().likeDislikeProcess2(likeType: false, ratingLikeCheck: 2, itemID: self.object?.ratingID ?? "", profID: profID ?? "", userID: myID, uLikeNum: Int(myLiked ?? 0), uDislikeNum: Int(myDisliked ?? 0))
            } else if dislikeCheck { // only dislike exists // remove dislike
                dislikeCheck = false
                dislike.setImage(UIImage.init(named: "dislikeEmpty"), for: .normal)
                var dNum = dislikeNumber ?? 0
                dNum = dNum - 1
                dislikeNum.text = String(dNum)
                HandleLikeActions().likeDislikeProcess2(likeType: false, ratingLikeCheck: 1, itemID: self.object?.ratingID ?? "", profID: profID ?? "", userID: myID, uLikeNum: Int(myLiked ?? 0), uDislikeNum: Int(myDisliked ?? 0))
            } else { // none exists // add dislike
                dislikeCheck = true
                dislike.setImage(UIImage.init(named: "dislikeFull"), for: .normal)
                var disNum = dislikeNumber ?? 0
                disNum = disNum + 1
                dislikeNum.text = String(disNum)
                HandleLikeActions().likeDislikeProcess2(likeType: false, ratingLikeCheck: 3, itemID: self.object?.ratingID ?? "", profID: profID ?? "", userID: myID, uLikeNum: Int(myLiked ?? 0), uDislikeNum: Int(myDisliked ?? 0))
            }
        } else {
            self.showAlert(type: 1)
        }
    }
    
    @objc private func profNamePressed() {
        performSegue(withIdentifier: "biggerRatingToProfSegue", sender: self)
    }
    
    @objc private func userPressed() {
        performSegue(withIdentifier: "biggerRatingToUserSegue", sender: self)
    }
    //MARK: Load Data
    @objc fileprivate func loadData() {
        self.loadUtil(mRef: ref.child("ratings").child("withComment").child(object?.ratingID ?? ""))
        self.extraUtil()
    }
    //MARK: Load Data From Notification
    private func loadDataFromNotification(notID: String) {
        self.loadUtil(mRef: ref.child("ratings").child("withComment").child(notID))
        self.extraUtil()
    }
    //MARK: Load Deleted Data
    @objc fileprivate func loadDeletedData() {
        self.like.isUserInteractionEnabled = false
        self.dislike.isUserInteractionEnabled = false
        self.report.isUserInteractionEnabled = false
        self.delete.isUserInteractionEnabled = false
        self.loadUtil(mRef: ref.child("deletedComments").child(object?.ratingID ?? ""))
    }
    //MARK: Utils
    @objc fileprivate func loadUtil(mRef : DatabaseQuery) {
        mRef.observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            self.profID = snapshot.childSnapshot(forPath: "profID").value as? String ?? ""
            if snapshot.childSnapshot(forPath: "comment").exists() {
                self.commentTxt = snapshot.childSnapshot(forPath: "comment").value as? String ?? ""
                self.comment.text = self.commentTxt
            }
            self.likeNumber = snapshot.childSnapshot(forPath: "likes").childrenCount
            self.dislikeNumber = snapshot.childSnapshot(forPath: "dislikes").childrenCount
            if self.object != nil {
                self.username.text = self.userObject?.username
                self.faculty.text = self.userObject?.faculty
                self.university.text = self.userObject?.university
                self.userImage.image = UIImage.init(named: self.userObject?.photo ?? "pp1")
            } else {
                self.ref.child("users").child(Auth.auth().currentUser?.uid ?? "").observeSingleEvent(of: .value) { (snapshot1,error1) in
                    if let error = error1 {
                        print("error",error)
                        return
                    }
                    self.username.text = snapshot1.childSnapshot(forPath: "username").value as? String ?? ""
                    self.faculty.text = snapshot1.childSnapshot(forPath: "faculty").value as? String ?? ""
                    self.university.text = snapshot1.childSnapshot(forPath: "university").value as? String ?? ""
                    self.userImage.image = UIImage.init(named: snapshot1.childSnapshot(forPath: "photo").value as? String ?? "pp1")
                }
            }
            self.ref.child("Professors").child(self.profID ?? "").observeSingleEvent(of: .value) { (snapshot,error) in
                if let error = error {
                    print("error",error)
                    return
                }
                var pName = ""
                if self.object != nil {
                    pName = self.object?.profName ?? ""
                } else {
                    pName = snapshot.childSnapshot(forPath: "prof_name").value as? String ?? ""
                }
                if snapshot.childSnapshot(forPath: "title").exists() {
                    let title = snapshot.childSnapshot(forPath: "title").value as? String ?? ""
                    pName = title+" "+pName
                }
                let font = UIFont.systemFont(ofSize: 12)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.init(named: "appBlueColor") ?? .blue,
                ]
                let finalStr = NSMutableAttributedString(string: "Professor name: ", attributes: attributes)
                let attributes2: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.init(named: "textColor") ?? .black,
                ]
                let finalStr2 = NSAttributedString(string: pName, attributes: attributes2)
                finalStr.append(finalStr2)
                self.profName.attributedText = finalStr
            }
            let avg = snapshot.childSnapshot(forPath: "avg_rating").value as? Double ?? 0.0
            self.help = Double(snapshot.childSnapshot(forPath: "helpfulness").value as? String ?? "0") ?? 0.0
            self.diff = Double(snapshot.childSnapshot(forPath: "difficulty").value as? String ?? "0") ?? 0.0
            self.lec = Double(snapshot.childSnapshot(forPath: "lecture").value as? String ?? "0") ?? 0.0
            let time1 = snapshot.childSnapshot(forPath: "time").value as? UInt ?? 0
            self.avgNum.text = String(format: "%.1f", avg)
            self.avgNum.textColor = UIColor().setColorRating(number: avg)
            self.helpNum.text = String(self.help ?? 0.0)
            self.helpNum.textColor = UIColor().setColorRating(number: self.help ?? 0.0)
            self.diffNum.text = String(self.diff ?? 0.0)
            self.diffNum.textColor = UIColor().setColorRatingOpposite(number: self.diff ?? 0.0)
            self.lecNum.text = String(self.lec ?? 0.0)
            self.lecNum.textColor = UIColor().setColorRating(number: self.lec ?? 0.0)
            if snapshot.childSnapshot(forPath: "attendance").exists() {
                self.attStack.isHidden = false
                if (snapshot.childSnapshot(forPath: "attendance").value as? Double ?? 0.0) == 1.0 {
                    self.attNum.text = NSLocalizedString("not_mandatory", comment: "")
                    self.attNum.textColor = UIColor.init(named: "ratingGreen") ?? .green
                } else {
                    self.attNum.text = NSLocalizedString("mandatory", comment: "")
                    self.attNum.textColor = UIColor.init(named: "ratingRed") ?? .red
                }
            } else {
                self.attStack.isHidden = true
            }
            if snapshot.childSnapshot(forPath: "textbook").exists() {
                self.txtStack.isHidden = false
                if (snapshot.childSnapshot(forPath: "textbook").value as? Double ?? 0.0) == 1.0 {
                    self.txtNum.text = NSLocalizedString("not_mandatory", comment: "")
                    self.txtNum.textColor = UIColor.init(named: "ratingGreen") ?? .green
                } else {
                    self.txtNum.text = NSLocalizedString("mandatory", comment: "")
                    self.txtNum.textColor = UIColor.init(named: "ratingRed") ?? .red
                }
            } else {
                self.txtStack.isHidden = true
            }
            self.likeNum.text = String(self.likeNumber ?? 0)
            self.dislikeNum.text = String(self.dislikeNumber ?? 0)
            self.time.text = String().convert(time: time1)
        }
    }
    
    @objc fileprivate func extraUtil() {
        if(Auth.auth().currentUser != nil){
            self.ref.child("users").child(Auth.auth().currentUser?.uid ?? "yok").observeSingleEvent(of: .value) { (snapshot,error) in
                if let error = error {
                    print("error",error)
                    return
                }
                if snapshot.childSnapshot(forPath: "myLikedNumber").exists() {
                    self.myLiked = snapshot.childSnapshot(forPath: "myLikedNumber").value as? UInt ?? 0
                }
                if snapshot.childSnapshot(forPath: "myDislikedNumber").exists() {
                    self.myDisliked = snapshot.childSnapshot(forPath: "myDislikedNumber").value as? UInt ?? 0
                }
                self.likeCheck = false
                self.dislikeCheck = false
                if snapshot.exists() {
                    if snapshot.childSnapshot(forPath: "myLikes").exists() {
                        for d in snapshot.childSnapshot(forPath: "myLikes").children {
                            let snap = d as! DataSnapshot
                            if snap.key == self.object?.ratingID {
                                self.likeCheck = true
                                self.like.setImage(UIImage.init(named: "likeFull")?.withRenderingMode(.alwaysOriginal), for: .normal)
                                self.dislike.setImage(UIImage.init(named: "dislikeEmpty")?.withRenderingMode(.alwaysOriginal), for: .normal)
                                break
                            }
                        }
                    }
                    if !self.likeCheck {
                        self.like.setImage(UIImage.init(named: "likeEmpty"), for: .normal)
                        if snapshot.childSnapshot(forPath: "myDislikes").exists() {
                            for d in snapshot.childSnapshot(forPath: "myDislikes").children {
                                let snap = d as! DataSnapshot
                                if snap.key == self.object?.itemID {
                                    self.dislikeCheck = true
                                    self.dislike.setImage(UIImage.init(named: "dislikeFull")?.withRenderingMode(.alwaysOriginal), for: .normal)
                                    break
                                }
                            }
                        }
                        if !self.dislikeCheck {
                            self.dislike.setImage(UIImage.init(named: "dislikeEmpty")?.withRenderingMode(.alwaysOriginal), for: .normal)
                        }
                    }
                }
            }
        }
    }
    
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
        if segue.identifier == "biggerRatingToProfSegue" {
            let vc = segue.destination as? ClickedProfVC
            vc?.profID = profID
        } else if segue.identifier == "biggerRatingToUserSegue" {
            let vc = segue.destination as? ClickedUserVC
            vc?.userID = Auth.auth().currentUser?.uid
        }
    }
}
