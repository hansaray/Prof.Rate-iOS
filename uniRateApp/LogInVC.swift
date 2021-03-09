//
//  LogInVC.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 01..
//

import UIKit
import Firebase
import JGProgressHUD

class LogInVC: UIViewController, UITextFieldDelegate {

    @IBOutlet private weak var password: UITextField!
    @IBOutlet private weak var loginName: UITextField!
    @IBOutlet private weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginButton.isEnabled = false
        password.delegate = self
        loginName.delegate = self
        loginName.tag = 0
        password.tag = 1
        loginButton.layer.cornerRadius = 6
        loginButton.contentEdgeInsets = UIEdgeInsets.init(top: 4, left: 4, bottom: 4, right: 4)
        loginButton.titleLabel?.numberOfLines = 0;
        loginButton.titleLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
        password.isSecureTextEntry = true
        password.addTarget(self, action: #selector(textWatcher), for: .editingChanged)
        loginName.addTarget(self, action: #selector(textWatcher), for: .editingChanged)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc private func DismissKeyboard(){
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1
        if let nextResponder = textField.superview?.viewWithTag(nextTag) {
            nextResponder.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    @objc fileprivate func textWatcher() {
        let formControl = (password.text?.count ?? 0) > 5 &&
            (loginName.text?.count ?? 0) > 1
        if formControl {
            loginButton.backgroundColor = UIColor.init(named: "appBlueColor")
            loginButton.isEnabled = true
        } else {
            loginButton.backgroundColor = UIColor.init(named: "buttonBlueTint")
            loginButton.isEnabled = false
        }
    }

    @IBAction private func btnPressed(_ sender: UIButton) {
        userDataCheck()
    }
    
    @objc fileprivate func userDataCheck(){ //Checking if user exists
        guard let logInName = loginName.text, let password = password.text else {return}
        var userCheck = false
        let ref = Database.database().reference().child("users");
        ref.observeSingleEvent(of: .value) { (snapShot, error) in
            if let error = error {
                let alertController = UIAlertController(title: NSLocalizedString("error", comment: ""), message: error, preferredStyle: .alert)
                self.present(alertController, animated: true, completion: nil)
                let when = DispatchTime.now() + 1
                DispatchQueue.main.asyncAfter(deadline: when){
                    alertController.dismiss(animated: true, completion: nil)
                }
                return
            }
            if snapShot.exists() {
                let users : NSArray = snapShot.children.allObjects as NSArray
                for user in users {
                let snap = user as! DataSnapshot
                if snap.childSnapshot(forPath: "email").exists() && snap.childSnapshot(forPath: "email").value as? String == logInName {
                    self.logInProcess(loginName: logInName, loginPassword: password)
                    userCheck = true
                    break
                } else if snap.childSnapshot(forPath: "username").value as? String == logInName {
                    if snap.childSnapshot(forPath: "email").exists() {
                    self.logInProcess(loginName: snap.childSnapshot(forPath: "email").value as! String, loginPassword: password)
                    }
                    userCheck = true
                    break
                }
            }
            if !userCheck { // there is no such user
                let alertController = UIAlertController(title: NSLocalizedString("error", comment: ""), message: NSLocalizedString("no_username", comment: ""), preferredStyle: .alert)
                self.present(alertController, animated: true, completion: nil)
                let when = DispatchTime.now() + 2
                DispatchQueue.main.asyncAfter(deadline: when){
                    alertController.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
}
    
    @objc fileprivate func logInProcess(loginName : String, loginPassword : String) {
        let hud = JGProgressHUD(style : .light)
        hud.textLabel.text = NSLocalizedString("logging_in", comment: "")
        hud.show(in: self.view)
        
        Auth.auth().signIn(withEmail: loginName, password: loginPassword) { (result, error) in
            if error != nil {
                hud.dismiss(animated: true)
                let errorHud = JGProgressHUD(style: .light)
                errorHud.textLabel.text = NSLocalizedString("pass_wrong", comment: "")
                errorHud.show(in: self.view)
                errorHud.dismiss(afterDelay: 4, animated: true)
                return
            }
            hud.dismiss(animated: true)
            if Auth.auth().currentUser != nil {
                let pushManager = PushNotificationManager(userID: Auth.auth().currentUser?.uid ?? "")
                pushManager.registerForPushNotifications()
            }
            self.performSegue(withIdentifier: "loginSegue", sender: self)
        }
    }
}
