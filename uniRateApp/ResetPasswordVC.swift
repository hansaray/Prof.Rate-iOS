//
//  ResetPasswordVC.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 19..
//

import UIKit
import Firebase
import JGProgressHUD

class ResetPasswordVC: UIViewController {
    
    @IBOutlet private weak var resetName: UITextField!
    @IBOutlet private weak var resetButton: UIButton!
    private let hud = JGProgressHUD(style : .light)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DismissKeyboard))
        view.addGestureRecognizer(tap)
        resetButton.layer.cornerRadius = 6
        resetButton.contentEdgeInsets = UIEdgeInsets.init(top: 4, left: 4, bottom: 4, right: 4)
        resetButton.titleLabel?.numberOfLines = 0;
        resetButton.titleLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
        resetName.addTarget(self, action: #selector(textWatcher), for: .editingChanged)
    }
    //MARK: onClick Actions
    @objc private func DismissKeyboard(){
        view.endEditing(true)
    }
    
    @IBAction func resetPressed(_ sender: UIButton) {
        if !(resetName.text?.isEmpty ?? true) {
            self.resetProcess()
        } else {
            self.showAlert(title: NSLocalizedString("error", comment: ""), msg: NSLocalizedString("empty_form2", comment: ""))
        }
    }
    //MARK: Reset Process
    @objc fileprivate func resetProcess() {
        hud.textLabel.text = NSLocalizedString("checking", comment: "")
        hud.show(in: self.view)
        let ref = Database.database().reference()
        let name = self.resetName.text
        if (name ?? "").contains("@") {
            ref.child("users").observeSingleEvent(of: .value) { (snapshot,error) in
                if let error = error {
                    print("error",error)
                    return
                }
                var check = false
                for d in snapshot.children {
                    let snap = d as! DataSnapshot
                    if (snap.childSnapshot(forPath: "email").value as? String ?? "") == name {
                        check = true
                        self.resetPass(address: name ?? "")
                        break
                    }
                }
                if !check {
                    self.hud.dismiss(animated: true)
                    self.showAlert(title: NSLocalizedString("error", comment: ""), msg: NSLocalizedString("user_not_exist_email", comment: ""))
                }
            }
        } else {
            ref.child("users").observeSingleEvent(of: .value) { (snapshot,error) in
                if let error = error {
                    print("error",error)
                    return
                }
                var check = false
                for d in snapshot.children {
                    let snap = d as! DataSnapshot
                    if (snap.childSnapshot(forPath: "username").value as? String ?? "") == name {
                        check = true
                        self.resetPass(address: snap.childSnapshot(forPath: "email").value as? String ?? "")
                        break
                    }
                }
                if !check {
                    self.hud.dismiss(animated: true)
                    self.showAlert(title: NSLocalizedString("error", comment: ""), msg: NSLocalizedString("user_not_exist", comment: ""))
                }
            }
        }
    }
    //MARK: Utils
    @objc fileprivate func resetPass(address: String) {
        Auth.auth().sendPasswordReset(withEmail: address) { (error) in
            if let error = error {
                self.hud.dismiss(animated: true)
                self.showAlert(title: NSLocalizedString("error", comment: ""), msg: error.localizedDescription)
            }
            self.hud.dismiss(animated: true)
            self.showAlert(title: NSLocalizedString("successful", comment: ""), msg: NSLocalizedString("reset_mail_sent", comment: ""))
        }
    }
    
    @objc fileprivate func showAlert(title: String,msg: String) {
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        self.present(alertController, animated: true, completion: nil)
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when){
            alertController.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc fileprivate func textWatcher() {
        let formControl = (resetName.text?.count ?? 0) >= 2
        if formControl {
            resetButton.backgroundColor = UIColor.init(named: "appBlueColor")
            resetButton.isEnabled = true
        } else {
            resetButton.backgroundColor = UIColor.init(named: "buttonBlueTint")
            resetButton.isEnabled = false
        }
    }

}
