//
//  SettingsVC.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 09. 30..
//

import UIKit
import Firebase
import GoogleMobileAds
import StoreKit

class SettingsVC: UIViewController {
    
    @IBOutlet private weak var loginCard: UIView!
    @IBOutlet private weak var signOut: UIButton!
    @IBOutlet private weak var addProf: UIButton!
    @IBOutlet private weak var settingsStack: UIStackView!
    @IBOutlet private weak var profileCard: UIView!
    @IBOutlet private weak var previewTitle: UILabel!
    @IBOutlet private weak var editButton: UIButton!
    @IBOutlet private weak var ppImage: UIImageView!
    @IBOutlet private weak var username: UILabel!
    @IBOutlet private weak var uniName: UILabel!
    @IBOutlet private weak var fieldName: UILabel!
    @IBOutlet private weak var totalRatings: UILabel!
    @IBOutlet private weak var likesNum: UILabel!
    @IBOutlet private weak var dislikesNum: UILabel!
    @IBOutlet private weak var likedNum: UILabel!
    @IBOutlet private weak var dislikedNum: UILabel!
    @IBOutlet private weak var userAvg: UILabel!
    @IBOutlet private weak var notificationButton: UIBarButtonItem!
    @IBOutlet private weak var banner: GADBannerView!
    private let ref = Database.database().reference()
    private var currentUser : User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        banner.adUnitID = "ca-app-pub-4004348027309516/9076615951"
        banner.rootViewController = self
        banner.load(GADRequest())
    }
    
    //MARK: Set Views
    @objc fileprivate func setViews() {
        loginCard.layer.cornerRadius = 8.0
        loginCard.layer.masksToBounds = true
        loginCard.layer.borderColor = UIColor(named: "appBlueColor")?.cgColor
        loginCard.layer.borderWidth = 1.0
        profileCard.layer.cornerRadius = 8.0
        profileCard.layer.masksToBounds = true
        profileCard.layer.borderColor = UIColor(named: "appBlueColor")?.cgColor
        profileCard.layer.borderWidth = 1.0
        let firstView = settingsStack.arrangedSubviews[1] //signOut button
        let secondView = settingsStack.arrangedSubviews[3] // addProf button
        if Auth.auth().currentUser != nil {
            firstView.isHidden = false
            secondView.isHidden = false
            loginCard.isHidden = true
            profileCard.isHidden = false
            previewTitle.isHidden = false
            editButton.isHidden = false
            self.notificationButton.image = UIImage(named:"notificationEmpty")?.withRenderingMode(.alwaysOriginal)
            iconChange()
            loadData()
        } else {
            self.navigationItem.rightBarButtonItem = nil
            firstView.isHidden = true
            secondView.isHidden = true
            loginCard.isHidden = false
            profileCard.isHidden = true
            previewTitle.isHidden = true
            editButton.isHidden = true
        }
    }
    //MARK: Load Data
    @objc fileprivate func loadData() {
        ref.child("users").child(Auth.auth().currentUser?.uid ?? "").observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            if snapshot.exists() {
                let usernameStr = snapshot.childSnapshot(forPath: "username").value as? String
                let uniNameStr = snapshot.childSnapshot(forPath: "university").value as? String
                let fieldNameStr = snapshot.childSnapshot(forPath: "faculty").value as? String
                self.username.text = usernameStr
                self.uniName.text = uniNameStr
                self.fieldName.text = fieldNameStr
                if snapshot.childSnapshot(forPath: "myRatings").exists() {
                    let num = snapshot.childSnapshot(forPath: "myRatings").childrenCount as UInt
                    self.totalRatings.text = String(num)
                } else {
                    self.totalRatings.text = "0"
                }
                if snapshot.childSnapshot(forPath: "myLikes").exists() {
                    let num = snapshot.childSnapshot(forPath: "myLikes").childrenCount as UInt
                    self.likesNum.text = String(num)
                } else {
                    self.likesNum.text = "0"
                }
                if snapshot.childSnapshot(forPath: "myDislikes").exists() {
                    let num = snapshot.childSnapshot(forPath: "myDislikes").childrenCount as UInt
                    self.dislikesNum.text = String(num)
                } else {
                    self.dislikesNum.text = "0"
                }
                var lNum = 0, dNum = 0
                if snapshot.childSnapshot(forPath: "myLikedNumber").exists() {
                    lNum = snapshot.childSnapshot(forPath: "myLikedNumber").value as? Int ?? 0
                    self.likedNum.text = String(lNum)
                } else {
                    self.likedNum.text = "0"
                }
                if snapshot.childSnapshot(forPath: "myDislikedNumber").exists() {
                    dNum = snapshot.childSnapshot(forPath: "myDislikedNumber").value as? Int ?? 0
                    self.dislikedNum.text = String(dNum)
                } else {
                    self.dislikedNum.text = "0"
                }
                let avgNum = lNum - dNum
                self.userAvg.text = "("+String(avgNum)+")"
                let photoStr = snapshot.childSnapshot(forPath: "photo").value as? String
                self.ppImage.image = UIImage.init(named: photoStr ?? "pp1")
                let userData = ["username" : usernameStr ?? "", "photo" : photoStr ?? "", "userID" : Auth.auth().currentUser?.uid ?? "", "university" : uniNameStr ?? "", "faculty" : fieldNameStr ?? "", "email" : snapshot.childSnapshot(forPath: "email").value as? String ?? "", "likeNum" : UInt(self.likesNum.text ?? "0") ?? 0, "dislikeNum" : UInt(self.dislikesNum.text ?? "0") ?? 0, "ratingNum" : UInt(self.totalRatings.text ?? "0") ?? 0] as [String : Any]
                self.currentUser = User(userData: userData as [String : Any])
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is EditProfileVC {
            let vc = segue.destination as? EditProfileVC
            vc?.currentUser = currentUser
        } else if segue.identifier == "settingsToContactSegue" {
            let vc = segue.destination as? ContactUsVC
            vc?.userMail = currentUser?.email ?? ""
        } else if segue.identifier == "settingsToNotSegue" {
            let vc = segue.destination as? NotificationsVC
            vc?.object = currentUser
        }
    }
    
    @objc fileprivate func iconChange() {
        ref.child("users").child(Auth.auth().currentUser?.uid ?? "").child("myNotifications").queryOrdered(byChild: "time").observe(.childAdded) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            if snapshot.exists() {
                if snapshot.childSnapshot(forPath: "seen").exists() {
                    self.notificationButton.image = UIImage(named:"notificationEmpty")?.withRenderingMode(.alwaysOriginal)
                } else {
                    self.notificationButton.image = UIImage(named:"notificationFull")?.withRenderingMode(.alwaysOriginal)
                }
                self.navigationItem.rightBarButtonItem = self.notificationButton
            } else {
                self.notificationButton.image = UIImage(named:"notificationEmpty")?.withRenderingMode(.alwaysOriginal)
            }
        }
        ref.child("users").child(Auth.auth().currentUser?.uid ?? "").child("myNotifications").queryOrdered(byChild: "time").observe(.childChanged) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            if snapshot.exists() {
                if snapshot.childSnapshot(forPath: "seen").exists() {
                    self.notificationButton.image = UIImage(named:"notificationEmpty")?.withRenderingMode(.alwaysOriginal)
                } else {
                    self.notificationButton.image = UIImage(named:"notificationFull")?.withRenderingMode(.alwaysOriginal)
                }
                self.navigationItem.rightBarButtonItem = self.notificationButton
            } else {
                self.notificationButton.image = UIImage(named:"notificationEmpty")?.withRenderingMode(.alwaysOriginal)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        ref.removeAllObservers()
    }
    
    //MARK: onClick Actions
    @IBAction func languagePressed(_ sender: UIButton) {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }
    
    @IBAction func signOutPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: NSLocalizedString("sign_out", comment: ""), message: NSLocalizedString("sign_out_exp", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("no", comment: ""), style: .default, handler: { [weak alert] (_) in
            alert?.dismiss(animated: true, completion: {})
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("yes", comment: ""), style: .default, handler: { [weak alert] (_) in
            alert?.dismiss(animated: true, completion: {})
            let when = DispatchTime.now() + 2
            var errorCheck = false
            var alertController = UIAlertController()
            do {
              try Auth.auth().signOut()
            } catch let signOutError as NSError {
                errorCheck = true
                alertController = UIAlertController(title: NSLocalizedString("error", comment: ""), message: signOutError as? String ?? "error", preferredStyle: .alert)
                self.present(alertController, animated: true, completion: nil)
            }
            if !errorCheck {
                alertController = UIAlertController(title: NSLocalizedString("successful", comment: ""), message: NSLocalizedString("signed_out", comment: ""), preferredStyle: .alert)
                self.present(alertController, animated: true, completion: nil)
            }
            DispatchQueue.main.asyncAfter(deadline: when){
                alertController.dismiss(animated: true, completion: nil)
                _ = self.navigationController?.popViewController(animated: true)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
}
