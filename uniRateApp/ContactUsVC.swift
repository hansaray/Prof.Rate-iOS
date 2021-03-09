//
//  ContactUsVC.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 09..
//

import UIKit
import Firebase
import GoogleMobileAds

class ContactUsVC: UIViewController {

    @IBOutlet private weak var email: UITextField!
    @IBOutlet private weak var mTitle: UITextField!
    @IBOutlet private weak var content: UITextView!
    @IBOutlet private weak var banner: GADBannerView!
    var userMail : String?
    private let ref = Database.database().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !(userMail?.isEmpty ?? true) {
            email.text = userMail
        }
        content.layer.cornerRadius = 8.0
        content.layer.masksToBounds = true
        content.layer.borderColor = UIColor(named: "appBlueColor")?.cgColor
        content.layer.borderWidth = 1.0
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        banner.adUnitID = "ca-app-pub-4004348027309516/7288891564"
        banner.rootViewController = self
        banner.load(GADRequest())
    }
    
    @objc private func DismissKeyboard(){
        view.endEditing(true)
    }
    
    @IBAction func donePressed(_ sender: UIBarButtonItem) {
        if !(email.text?.isEmpty ?? true) && !(mTitle.text?.isEmpty ?? true) && !(content.text?.isEmpty ?? true) {
            let eStr = email.text
            let tStr = mTitle.text
            let cStr = content.text
            let cTime = Date().currentTimeMillis() //contactUs
            let message = ["email" : eStr ?? "", "title" : tStr ?? "", "message" : cStr ?? "", "time" : cTime] as [String : Any]
            let key = ref.child("contactUs").childByAutoId()
            key.setValue(message)
            if Auth.auth().currentUser != nil {
                key.child("userID").setValue(Auth.auth().currentUser?.uid ?? "")
            }
            let when = DispatchTime.now() + 2
            let alertController = UIAlertController(title: NSLocalizedString("successful", comment: ""), message: NSLocalizedString("successful", comment: ""), preferredStyle: .alert)
            self.present(alertController, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: when){
                alertController.dismiss(animated: true, completion: nil)
                _ = self.navigationController?.popViewController(animated: true)
            }
        } else {
            let when = DispatchTime.now() + 2
            let alertController = UIAlertController(title: NSLocalizedString("error", comment: ""), message: NSLocalizedString("empty_form2", comment: ""), preferredStyle: .alert)
            self.present(alertController, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: when){
                alertController.dismiss(animated: true, completion: nil)
            }
        }
    }
    
}
