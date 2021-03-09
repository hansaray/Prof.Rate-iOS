//
//  EditProfileVC.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 04..
//

import UIKit
import Firebase
import JGProgressHUD

class EditProfileVC: UIViewController {
    
    @IBOutlet private weak var editImage: UIImageView!
    @IBOutlet private weak var editUsername: UILabel!
    @IBOutlet private weak var editUniName: UITextField!
    @IBOutlet private weak var editFieldName: UITextField!
    @IBOutlet private weak var editEmail: UITextField!
    private var chosenPhoto : String?
    var currentUser : User?
    private let ref = Database.database().reference()
    private let hud = JGProgressHUD(style : .light)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DismissKeyboard))
        view.addGestureRecognizer(tap)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        editImage.isUserInteractionEnabled = true
        editImage.addGestureRecognizer(tapGestureRecognizer)
        if currentUser != nil {
            setViews()
        } else {
            loadData()
        }
    }
    // MARK: SetViews
    @objc fileprivate func setViews() {
        editImage.image = UIImage.init(named: currentUser?.photo ?? "pp1")
        editUsername.text = currentUser?.username
        editUniName.placeholder = currentUser?.university
        editFieldName.placeholder = currentUser?.faculty
        editEmail.placeholder = currentUser?.email
    }
    
    @objc fileprivate func loadData() {
        ref.child("users").child(Auth.auth().currentUser?.uid ?? "").observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            self.editUsername.text = snapshot.childSnapshot(forPath: "username").value as? String
            self.editUniName.placeholder = snapshot.childSnapshot(forPath: "university").value as? String
            self.editFieldName.placeholder = snapshot.childSnapshot(forPath: "faculty").value as? String
            self.editEmail.placeholder = snapshot.childSnapshot(forPath: "email").value as? String
            self.editImage.image = UIImage.init(named: snapshot.childSnapshot(forPath: "photo").value as? String ?? "pp1")
        }
    }
    //MARK: SaveProcess
    private func saveProcess() {
        let uniNameStr = editUniName.text
        let fieldNameStr = editFieldName.text
        let emailStr = editEmail.text
        if !(uniNameStr?.isEmpty ?? true) || !(fieldNameStr?.isEmpty ?? true) || !(emailStr?.isEmpty ?? true) || !(chosenPhoto?.isEmpty ?? true) {
            ref.child("users").child(currentUser?.userID ?? "").observeSingleEvent(of: .value) { (snapshot,error) in
                if let error = error {
                    self.hud.dismiss(animated: true)
                    self.saved(title: "error", message: error)
                    return
                }
                var check = false
                if !(uniNameStr?.isEmpty ?? true) && uniNameStr != self.currentUser?.university {
                    self.ref.child("users").child(self.currentUser?.userID ?? "").child("university").setValue(uniNameStr)
                }
                if !(fieldNameStr?.isEmpty ?? true) && fieldNameStr != self.currentUser?.faculty {
                    self.ref.child("users").child(self.currentUser?.userID ?? "").child("faculty").setValue(fieldNameStr)
                }
                if !(self.chosenPhoto?.isEmpty ?? true) && self.chosenPhoto != self.currentUser?.photo {
                    self.ref.child("users").child(self.currentUser?.userID ?? "").child("photo").setValue(self.chosenPhoto)
                }
                if !(emailStr?.isEmpty ?? true) && emailStr != self.currentUser?.email && self.isValidEmail(emailStr ?? "") {
                    check = true
                    self.emailUpdate(newEmail: emailStr ?? "")
                }
                if !check {
                    self.hud.dismiss(animated: true)
                    self.saved(title: "saved",message: "saved_exp")
                    _ = self.navigationController?.popViewController(animated: true)
                }
            }
        } else {
            self.hud.dismiss(animated: true)
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func emailUpdate(newEmail : String) {
        if currentUser?.email != nil && !(currentUser?.email.isEmpty ?? true) && currentUser?.email != newEmail {
            reAuthenticate(currentEmail: currentUser?.email ?? "",newEmail: newEmail);
        } else {
            hud.dismiss(animated: true)
            saved(title: "saved",message: "saved_exp")
        }
    }
    
    private func reAuthenticate(currentEmail : String, newEmail : String) {
        let cUser = Auth.auth().currentUser
        hud.dismiss(animated: true)
        if cUser != nil {
            let alert = UIAlertController(title: NSLocalizedString("password", comment: ""), message: NSLocalizedString("email_change_pass", comment: ""), preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.placeholder = NSLocalizedString("password", comment: "")
                textField.isSecureTextEntry = true
            }
            alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .default, handler: { [weak alert] (_) in
                alert?.dismiss(animated: true, completion: {})
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { [weak alert] (_) in
                self.hud.textLabel.text = NSLocalizedString("email_changing", comment: "")
                self.hud.show(in: self.view)
                let pass = alert?.textFields![0].text
                if !(pass?.isEmpty ?? true) {
                    let credential = EmailAuthProvider.credential(withEmail: currentEmail, password: pass ?? "")
                    cUser?.reauthenticate(with: credential, completion: { (result, error) in
                        if let error = error {
                            self.hud.dismiss(animated: true)
                            self.saved(title: "error", message: error.localizedDescription)
                            return
                        }
                        cUser?.updateEmail(to: newEmail, completion: { (error) in
                            if let error = error {
                                self.hud.dismiss(animated: true)
                                self.saved(title: "error", message: error.localizedDescription)
                                _ = self.navigationController?.popViewController(animated: true)
                                return
                            }
                            self.ref.child("users").child(self.currentUser?.userID ?? "").child("email").setValue(newEmail)
                            cUser?.sendEmailVerification(completion: { (error) in
                                if let error = error {
                                    self.hud.dismiss(animated: true)
                                    self.saved(title: "done",message: "email_done_exp2")
                                    print("error",error)
                                    return
                                }
                                self.hud.dismiss(animated: true)
                                self.saved(title: "done",message: "email_done_exp")
                                _ = self.navigationController?.popViewController(animated: true)
                            })
                        })
                    })
                }
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            saved(title: "saved",message: "saved_exp")
            _ = navigationController?.popViewController(animated: true)
        }
    }
    
    func isValidEmail(_ email: String) -> Bool {
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            return emailPred.evaluate(with: email)
    }
    
    private func saved(title : String, message : String) {
        let alertController = UIAlertController(title: NSLocalizedString(title, comment: ""), message: NSLocalizedString(message, comment: ""), preferredStyle: .alert)
        self.present(alertController, animated: true, completion: nil)
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when){
            alertController.dismiss(animated: true, completion: nil)
        }
    }
    // MARK: onCLick Actions
    @objc private func DismissKeyboard(){
        view.endEditing(true)
    }
    
    @objc fileprivate func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        self.performSegue(withIdentifier: "editToPhotoSegue", sender: self)
    }
    
    
    @IBAction func donePressed(_ sender: UIBarButtonItem) {
        hud.textLabel.text = NSLocalizedString("saving", comment: "")
        hud.show(in: self.view)
        saveProcess()
    }
    
    @IBAction func deletePressed(_ sender: UIButton) {
        let alert = UIAlertController(title: NSLocalizedString("delete", comment: ""), message: NSLocalizedString("delete_exp", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .default, handler: { [weak alert] (_) in
            alert?.dismiss(animated: true, completion: {})
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("delete", comment: ""), style: .default, handler: { [weak alert] (_) in
            self.deleteProcess()
            alert?.dismiss(animated: true, completion: {})
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editToPhotoSegue" {
            let cvc = segue.destination as! ChoosePhotoCVC
            cvc.delegate = self
        } else if segue.identifier == "editLikesToCommentSegue" {
            let cvc = segue.destination as! CommentListVC
            cvc.type = "likes"
            cvc.commentNum = Int(currentUser?.likeNum ?? 0)
            cvc.userModel = currentUser
        } else if segue.identifier == "editDislikesToCommentSegue" {
            let cvc = segue.destination as! CommentListVC
            cvc.type = "dislikes"
            cvc.commentNum = Int(currentUser?.dislikeNum ?? 0)
            cvc.userModel = currentUser
        } else if segue.identifier == "editRatingsToCommentSegue" {
            let cvc = segue.destination as! CommentListVC
            cvc.type = "rating"
            cvc.commentNum = Int(currentUser?.ratingNum ?? 0)
            cvc.userModel = currentUser
        }
    }
    //MARK: DeleteProcess
    @objc fileprivate func deleteProcess() {
        hud.textLabel.text = NSLocalizedString("saving", comment: "")
        hud.show(in: self.view)
        let myUid = Auth.auth().currentUser?.uid ?? ""
        ref.child("users").child(myUid).observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                self.hud.dismiss(animated: true)
                self.saved(title: "error", message: error)
                return
            }
            let cUser = Auth.auth().currentUser
            self.hud.dismiss(animated: true)
            let alert = UIAlertController(title: NSLocalizedString("password", comment: ""), message: NSLocalizedString("delete_pass", comment: ""), preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.placeholder = NSLocalizedString("password", comment: "")
                textField.isSecureTextEntry = true
            }
            alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .default, handler: { [weak alert] (_) in
                alert?.dismiss(animated: true, completion: {})
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { [weak alert] (_) in
                self.hud.textLabel.text = NSLocalizedString("deleting", comment: "")
                self.hud.show(in: self.view)
                let pass = alert?.textFields![0].text
                if !(pass?.isEmpty ?? true) {
                    let credential = EmailAuthProvider.credential(withEmail: self.currentUser?.email ?? "", password: pass ?? "")
                    cUser?.reauthenticate(with: credential, completion: { (result, error) in
                        if let error = error {
                            self.hud.dismiss(animated: true)
                            self.saved(title: "error", message: error.localizedDescription)
                            return
                        }
                        Auth.auth().currentUser?.delete(completion: { (error) in
                            if let error = error {
                                self.hud.dismiss(animated: true)
                                self.saved(title: "error", message: error.localizedDescription)
                                return
                            }
                            if snapshot.childSnapshot(forPath: "myLikes").exists() {
                                for d in snapshot.childSnapshot(forPath: "myLikes").children {
                                    let snap = d as! DataSnapshot
                                    self.ref.child("ratings").child("withComment").child(snap.key).child("likes").child(myUid).removeValue();
                                }
                            }
                            if snapshot.childSnapshot(forPath: "myDislikes").exists() {
                                for d in snapshot.childSnapshot(forPath: "myDislikes").children {
                                    let snap = d as! DataSnapshot
                                    self.ref.child("ratings").child("withComment").child(snap.key).child("dislikes").child(myUid).removeValue();
                                }
                            }
                            if snapshot.childSnapshot(forPath: "myRatings").exists() {
                                for d in snapshot.childSnapshot(forPath: "myRatings").children {
                                    let snap = d as! DataSnapshot
                                    if snap.value as? String == "true" {
                                        self.ref.child("ratings").child("noComment").child(snap.key).observeSingleEvent(of: .value) { (snapshot2,error2) in
                                            if let error = error2 {
                                                self.hud.dismiss(animated: true)
                                                print("error",error)
                                                return
                                            }
                                            let profID = snapshot2.childSnapshot(forPath: "profID").value as? String
                                            self.ref.child("Professors").child(profID ?? "").child("ratings_total").child(snap.key).removeValue()
                                            self.ref.child("ratings").child("noComment").child(snap.key).removeValue()
                                            HandleDeleteReportActions().updateRating(profID: profID ?? "")
                                        }
                                    } else {
                                        self.ref.child("ratings").child("withComment").child(snap.key).observeSingleEvent(of: .value) { (snapshot2,error2) in
                                            if let error = error2 {
                                                self.hud.dismiss(animated: true)
                                                print("error",error)
                                                return
                                            }
                                            let profID = snapshot2.childSnapshot(forPath: "profID").value as? String
                                            self.ref.child("Professors").child(profID ?? "").child("ratings_total").child(snap.key).removeValue()
                                            self.ref.child("Professors").child(profID ?? "").child("ratings_comment").child(snap.key).removeValue()
                                            self.ref.child("ratings").child("withComment").child(snap.key).removeValue()
                                            HandleDeleteReportActions().updateRating(profID: profID ?? "")
                                        }
                                    }
                                }
                            }
                            self.hud.dismiss(animated: true)
                            self.saved(title: "done", message: "deleted")
                            self.ref.child("users").child(myUid).removeValue();
                        })
                    })
                }
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension EditProfileVC: ChosenPhotoDelegate {
    func onClickPhoto(photo: String)
    {
        chosenPhoto = photo
        self.editImage.image = UIImage.init(named: photo)
    }
}
