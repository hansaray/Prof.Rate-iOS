//
//  SignUpVC.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 01..
//

import UIKit
import Firebase
import JGProgressHUD

protocol ChosenPhotoDelegate: AnyObject
{
    func onClickPhoto(photo: String)
}

class SignUpVC: UIViewController, UITextFieldDelegate {

    @IBOutlet private weak var choosePhoto: UIButton!
    @IBOutlet private weak var image: UIImageView!
    @IBOutlet private weak var username: UITextField!
    @IBOutlet private weak var email: UITextField!
    @IBOutlet private weak var password: UITextField!
    @IBOutlet private weak var passwordAgain: UITextField!
    @IBOutlet private weak var uniName: UITextField!
    @IBOutlet private weak var fieldName: UITextField!
    @IBOutlet private weak var scrollview: UIScrollView!
    private var scrollSize = CGFloat()
    private var chosenPhoto : String?
    private let ref = Database.database().reference()
    private let hud = JGProgressHUD(style : .light)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        username.delegate = self
        username.tag = 0
        email.delegate = self
        email.tag = 1
        password.delegate = self
        password.tag = 2
        passwordAgain.delegate = self
        passwordAgain.tag = 3
        uniName.delegate = self
        uniName.tag = 4
        fieldName.delegate = self
        fieldName.tag = 5
        password.isSecureTextEntry = true
        passwordAgain.isSecureTextEntry = true
        scrollSize = scrollview.frame.size.height
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DismissKeyboard))
        view.addGestureRecognizer(tap)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        image.isUserInteractionEnabled = true
        image.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc private func DismissKeyboard(){
        view.endEditing(true)
    }
    
    @objc fileprivate func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        self.performSegue(withIdentifier: "signUpToPhotoSegue", sender: self)
    }
    
    // MARK: Done Pressed
    
    @IBAction private func donePressed(_ sender: UIBarButtonItem) {
        hud.textLabel.text = NSLocalizedString("signing_up", comment: "")
        hud.show(in: self.view)
        let emailStr = email.text ?? ""
        let usernameStr = username.text ?? ""
        let uniNameStr = uniName.text ?? ""
        let fieldNameStr = fieldName.text ?? ""
        if isValidEmail(emailStr) {
            if !(usernameStr.count < 2) && !(usernameStr.contains("@")) {
                if !uniNameStr.isEmpty && !fieldNameStr.isEmpty && (chosenPhoto != nil && !(chosenPhoto?.isEmpty ?? true)) {
                    ref.child("bannedUsers").observeSingleEvent(of: .value) { (snapshot,error) in
                        if let error = error {
                            self.hud.dismiss(animated: true)
                            let alertController = UIAlertController(title: NSLocalizedString("error", comment: ""), message: error, preferredStyle: .alert)
                            self.present(alertController, animated: true, completion: nil)
                            let when = DispatchTime.now() + 1
                            DispatchQueue.main.asyncAfter(deadline: when){
                                alertController.dismiss(animated: true, completion: nil)
                            }
                            return
                        }
                        var banCheck = false
                        if snapshot.exists() {
                            snapshot.children.forEach { (child) in
                                let snap = child as! DataSnapshot
                                if snap.childSnapshot(forPath: "email").value as? String == emailStr {
                                    banCheck = true
                                }
                            }
                        }
                        if !banCheck {
                            self.ref.child("users").observeSingleEvent(of: .value) { (snapshot1,error1) in
                                if let error = error1 {
                                    self.hud.dismiss(animated: true)
                                    let alertController = UIAlertController(title: NSLocalizedString("error", comment: ""), message: error, preferredStyle: .alert)
                                    self.present(alertController, animated: true, completion: nil)
                                    let when = DispatchTime.now() + 1
                                    DispatchQueue.main.asyncAfter(deadline: when){
                                        alertController.dismiss(animated: true, completion: nil)
                                    }
                                    return
                                }
                                var control = false
                                if snapshot1.exists() {
                                    for child in snapshot1.children {
                                        let snap = child as! DataSnapshot
                                        if snap.childSnapshot(forPath: "username").value as? String == usernameStr {
                                            control = true
                                            self.hud.dismiss(animated: true)
                                            let alertController = UIAlertController(title: NSLocalizedString("error", comment: ""), message: NSLocalizedString("user_exist", comment: ""), preferredStyle: .alert)
                                            self.present(alertController, animated: true, completion: nil)
                                            let when = DispatchTime.now() + 2
                                            DispatchQueue.main.asyncAfter(deadline: when){
                                                alertController.dismiss(animated: true, completion: nil)
                                            }
                                            break
                                        }
                                        if snap.childSnapshot(forPath: "email").value as? String == emailStr {
                                            control = true
                                            self.hud.dismiss(animated: true)
                                            let alertController = UIAlertController(title: NSLocalizedString("error", comment: ""), message: NSLocalizedString("email_exist", comment: ""), preferredStyle: .alert)
                                            self.present(alertController, animated: true, completion: nil)
                                            let when = DispatchTime.now() + 2
                                            DispatchQueue.main.asyncAfter(deadline: when){
                                                alertController.dismiss(animated: true, completion: nil)
                                            }
                                            break
                                        }
                                    }
                                    if !control {
                                        self.signUpProcess(emailStr: emailStr, usernameStr: usernameStr, uniNameStr: uniNameStr, fieldNameStr: fieldNameStr)
                                    }
                                } else {
                                    self.signUpProcess(emailStr: emailStr, usernameStr: usernameStr, uniNameStr: uniNameStr, fieldNameStr: fieldNameStr)
                                }
                            }
                        } else {
                            self.hud.dismiss(animated: true)
                            let alertController = UIAlertController(title: NSLocalizedString("error", comment: ""), message: NSLocalizedString("email_banned", comment: ""), preferredStyle: .alert)
                            self.present(alertController, animated: true, completion: nil)
                            let when = DispatchTime.now() + 2
                            DispatchQueue.main.asyncAfter(deadline: when){
                                alertController.dismiss(animated: true, completion: nil)
                            }
                        }
                    }
                } else {
                    hud.dismiss(animated: true)
                    let alertController = UIAlertController(title: NSLocalizedString("error", comment: ""), message: NSLocalizedString("empty_form", comment: ""), preferredStyle: .alert)
                    self.present(alertController, animated: true, completion: nil)
                    let when = DispatchTime.now() + 2
                    DispatchQueue.main.asyncAfter(deadline: when){
                        alertController.dismiss(animated: true, completion: nil)
                    }
                }
            } else {
                hud.dismiss(animated: true)
                let alertController = UIAlertController(title: NSLocalizedString("error", comment: ""), message: NSLocalizedString("username_short", comment: ""), preferredStyle: .alert)
                self.present(alertController, animated: true, completion: nil)
                let when = DispatchTime.now() + 2
                DispatchQueue.main.asyncAfter(deadline: when){
                    alertController.dismiss(animated: true, completion: nil)
                }
            }
        } else {
            hud.dismiss(animated: true)
            let alertController = UIAlertController(title: NSLocalizedString("error", comment: ""), message: NSLocalizedString("email_invalid", comment: ""), preferredStyle: .alert)
            self.present(alertController, animated: true, completion: nil)
            let when = DispatchTime.now() + 2
            DispatchQueue.main.asyncAfter(deadline: when){
                alertController.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    // MARK: SignUp Process
    
    @objc fileprivate func signUpProcess(emailStr: String, usernameStr: String, uniNameStr: String, fieldNameStr : String ){
        let passStr = password.text ?? ""
        let passAgainStr = passwordAgain.text ?? ""
        if !(passStr.count < 6) {
            if passStr == passAgainStr {
                Auth.auth().createUser(withEmail: emailStr, password: passStr) { (result, error) in
                    if let error = error {
                        self.hud.dismiss(animated: true)
                        Auth.auth().currentUser?.delete(completion: { (error1) in
                            if error1 != nil {
                                let errorHud = JGProgressHUD(style: .light)
                                errorHud.textLabel.text =  "Erorr : \(String(describing: error1))"
                                errorHud.show(in: self.view)
                                errorHud.dismiss(afterDelay: 3, animated: true)
                                return
                            }
                            let errorHud = JGProgressHUD(style: .light)
                            errorHud.textLabel.text = "Erorr : \(error)"
                            errorHud.show(in: self.view)
                            errorHud.dismiss(afterDelay: 3, animated: true)
                            return
                        })
                    }
                    let userModel = ["username" : usernameStr, "university" : uniNameStr, "email" : emailStr, "photo" : self.chosenPhoto, "faculty" : fieldNameStr]
                    guard let userID = result?.user.uid else {return}
                    self.ref.child("users").child(userID).setValue(userModel)
                    self.hud.dismiss(animated: true)
                    Auth.auth().currentUser?.sendEmailVerification(completion: { (error) in
                        if error != nil {
                            let alertController = UIAlertController(title: NSLocalizedString("error", comment: ""), message: NSLocalizedString("email_verification_error", comment: ""), preferredStyle: .alert)
                            self.present(alertController, animated: true, completion: nil)
                            let when = DispatchTime.now() + 2
                            DispatchQueue.main.asyncAfter(deadline: when){
                                alertController.dismiss(animated: true, completion: nil)
                            }
                        } else {
                            let alertController = UIAlertController(title: NSLocalizedString("successful", comment: ""), message: NSLocalizedString("email_verf_sent", comment: ""), preferredStyle: .alert)
                            self.present(alertController, animated: true, completion: nil)
                            let when = DispatchTime.now() + 2
                            DispatchQueue.main.asyncAfter(deadline: when){
                                alertController.dismiss(animated: true, completion: nil)
                            }
                        }
                    })
                    if Auth.auth().currentUser != nil {
                        let pushManager = PushNotificationManager(userID: Auth.auth().currentUser?.uid ?? "")
                        pushManager.registerForPushNotifications()
                    }
                    self.performSegue(withIdentifier: "signUpSegue", sender: self)
                }
            } else {
                hud.dismiss(animated: true)
                let alertController = UIAlertController(title: NSLocalizedString("error", comment: ""), message: NSLocalizedString("pass_not_match", comment: ""), preferredStyle: .alert)
                self.present(alertController, animated: true, completion: nil)
                let when = DispatchTime.now() + 2
                DispatchQueue.main.asyncAfter(deadline: when){
                    alertController.dismiss(animated: true, completion: nil)
                }
            }
        } else {
            hud.dismiss(animated: true)
            let alertController = UIAlertController(title: NSLocalizedString("error", comment: ""), message: NSLocalizedString("pass_short", comment: ""), preferredStyle: .alert)
            self.present(alertController, animated: true, completion: nil)
            let when = DispatchTime.now() + 2
            DispatchQueue.main.asyncAfter(deadline: when){
                alertController.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func isValidEmail(_ email: String) -> Bool {
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            return emailPred.evaluate(with: email)
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
    
    private func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollview.contentSize = CGSize(width: self.scrollview.frame.size.width, height: (scrollview.frame.size.height + 10))
    }

    func textFieldDidBeginEditing(_ textField:UITextField) {
        self.scrollview.setContentOffset(textField.frame.origin, animated: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.scrollview.setContentOffset(.zero, animated: true)
        self.scrollview.contentSize = CGSize(width: self.scrollview.frame.size.width, height: (scrollSize))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "signUpToPhotoSegue" {
            let cvc = segue.destination as! ChoosePhotoCVC
            cvc.delegate = self
        }
    }
    
}

extension SignUpVC: ChosenPhotoDelegate {
    func onClickPhoto(photo: String)
    {
        chosenPhoto = photo
        self.image.isHidden = false
        self.choosePhoto.isHidden = true
        self.image.image = UIImage.init(named: photo)
    }
}
