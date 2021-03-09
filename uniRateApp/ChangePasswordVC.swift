//
//  ChangePasswordVC.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 05..
//

import UIKit
import Firebase
import JGProgressHUD

class ChangePasswordVC: UIViewController {
    
    @IBOutlet private weak var currentPass: UITextField!
    @IBOutlet private weak var newPass: UITextField!
    @IBOutlet private weak var newPass2: UITextField!
    private let ref = Database.database().reference()
    private let hud = JGProgressHUD(style : .light)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentPass.isSecureTextEntry = true
        newPass.isSecureTextEntry = true
        newPass2.isSecureTextEntry = true
    }
    
    @IBAction func donePressed(_ sender: UIBarButtonItem) {
        hud.textLabel.text = NSLocalizedString("saving", comment: "")
        hud.show(in: self.view)
        changeProcess()
    }
    
    private func changeProcess() {
        let current = currentPass.text
        let new = newPass.text
        let new2 = newPass2.text
        if !(current?.isEmpty ?? true) {
            let cUser = Auth.auth().currentUser
            if cUser != nil {
                let credential = EmailAuthProvider.credential(withEmail: cUser?.email ?? "", password: current ?? "")
                cUser?.reauthenticate(with: credential, completion: { (result, error) in
                    if let error = error {
                        self.hud.dismiss(animated: true)
                        print("error",error)
                        return
                    }
                    if new == new2 {
                        if new?.count ?? 0 > 6 {
                            cUser?.updatePassword(to: new ?? "", completion: { (error) in
                                if let error = error {
                                    self.hud.dismiss(animated: true)
                                    print("error",error)
                                    return
                                }
                                self.hud.dismiss(animated: true)
                                self.saved(title: "successful", message: "pass_changed")
                            })
                        } else {
                            self.hud.dismiss(animated: true)
                            self.saved(title: "error", message: "pass_short")
                        }
                    } else {
                        self.hud.dismiss(animated: true)
                        self.saved(title: "error", message: "pass_not_match")
                    }
                })
            }
        } else {
            hud.dismiss(animated: true)
            saved(title: "error", message: "current_pass_empty")
        }
    }
    
    private func saved(title : String, message : String) {
        let alertController = UIAlertController(title: NSLocalizedString(title, comment: ""), message: NSLocalizedString(message, comment: ""), preferredStyle: .alert)
        self.present(alertController, animated: true, completion: nil)
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when){
            alertController.dismiss(animated: true, completion: nil)
        }
    }
}
