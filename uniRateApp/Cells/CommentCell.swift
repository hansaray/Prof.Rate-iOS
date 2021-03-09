//
//  CommentCell.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 06..
//

import UIKit
import Firebase

protocol CommentCellDelegate {
    func postLiked(cell: CommentCell, likeCheck: Bool, dislikeCheck: Bool)
    func postDisliked(cell: CommentCell, likeCheck: Bool, dislikeCheck: Bool)
    func delete(cell: CommentCell)
    func report(cell: CommentCell)
    func profClicked(cell: CommentCell)
    func userClicked(cell: CommentCell)
}

class CommentCell: UICollectionViewCell {
    
    var delegate : CommentCellDelegate?
    @IBOutlet private weak var profName: UILabel!
    @IBOutlet private weak var userImage: UIImageView!
    @IBOutlet private weak var username: UILabel!
    @IBOutlet private weak var faculty: UILabel!
    @IBOutlet private weak var university: UILabel!
    @IBOutlet private weak var avgRating: UILabel!
    @IBOutlet private weak var helpNum: UILabel!
    @IBOutlet private weak var diffNum: UILabel!
    @IBOutlet private weak var lecNum: UILabel!
    @IBOutlet private weak var attStack: UIStackView!
    @IBOutlet private weak var attNum: UILabel!
    @IBOutlet private weak var txtStack: UIStackView!
    @IBOutlet private weak var txtNum: UILabel!
    @IBOutlet weak var ratingsStack: UIStackView!
    @IBOutlet weak var comment: UILabel!
    @IBOutlet weak var likeNum: UILabel!
    @IBOutlet weak var dislikeNum: UILabel!
    @IBOutlet private weak var time: UILabel!
    @IBOutlet private weak var line: UIView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var dislikeButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var reportButton: UIButton!
    var likeCheck = false
    var dislikeCheck = false
    
    //MARK: Configure
    func configure(with item: CommentItem){
        if item.type != "4" {
            let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(profNamePressed))
            profName.addGestureRecognizer(tap)
        }
        let tap1: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(userPressed))
        username.addGestureRecognizer(tap1)
        userImage.addGestureRecognizer(tap1)
        if item.type == "likes" {
            self.likeButton?.setImage(UIImage.init(named: "likeFull"), for: .normal)
            self.dislikeButton?.setImage(UIImage.init(named: "dislikeEmpty"), for: .normal)
            if(item.userID == (Auth.auth().currentUser?.uid ?? "")) {
                self.deleteButton?.isHidden = false
                self.reportButton?.isHidden = true
            }else{
                self.deleteButton?.isHidden = true
                self.reportButton?.isHidden = false
            }
        } else if item.type == "dislikes" {
            self.likeButton?.setImage(UIImage.init(named: "likeEmpty"), for: .normal)
            self.dislikeButton?.setImage(UIImage.init(named: "dislikeFull"), for: .normal)
            if(item.userID == (Auth.auth().currentUser?.uid ?? "")) {
                self.deleteButton?.isHidden = false
                self.reportButton?.isHidden = true
            }else{
                self.deleteButton?.isHidden = true
                self.reportButton?.isHidden = false
            }
        } else if item.type == "rating" || item.type == "4" || item.type == "5" {
            if item.type == "rating" {
                self.deleteButton?.isHidden = false
                self.reportButton?.isHidden = true
                if item.comment == "" {
                    self.likeButton?.isUserInteractionEnabled = false
                    self.dislikeButton?.isUserInteractionEnabled = false
                } else {
                    self.likeButton?.isUserInteractionEnabled = true
                    self.dislikeButton?.isUserInteractionEnabled = true
                }
            } else {
                if Auth.auth().currentUser != nil {
                    if item.userID == Auth.auth().currentUser?.uid ?? "" {
                        self.deleteButton?.isHidden = false
                        self.reportButton?.isHidden = true
                    } else {
                        self.deleteButton?.isHidden = true
                        self.reportButton?.isHidden = false
                    }
                } else {
                    self.deleteButton?.isHidden = true
                    self.reportButton?.isHidden = false
                }
                if item.type == "5" {
                    if item.comment == "" {
                        self.likeButton?.isUserInteractionEnabled = false
                        self.dislikeButton?.isUserInteractionEnabled = false
                    } else {
                        self.likeButton?.isUserInteractionEnabled = true
                        self.dislikeButton?.isUserInteractionEnabled = true
                    }
                }
            }
            let ref = Database.database().reference()
            if(Auth.auth().currentUser != nil){
                ref.child("users").child(Auth.auth().currentUser?.uid ?? "yok").observeSingleEvent(of: .value) { (snapshot,error) in
                    if let error = error {
                        print("error",error)
                        return
                    }
                    self.likeCheck = false
                    self.dislikeCheck = false
                    if snapshot.exists() {
                        if snapshot.childSnapshot(forPath: "myLikes").exists() {
                            for d in snapshot.childSnapshot(forPath: "myLikes").children {
                                let snap = d as! DataSnapshot
                                if snap.key == item.itemID {
                                    self.likeCheck = true
                                    self.likeButton?.setImage(UIImage.init(named: "likeFull"), for: .normal)
                                    self.dislikeButton?.setImage(UIImage.init(named: "dislikeEmpty"), for: .normal)
                                    break
                                }
                            }
                        }
                        if !self.likeCheck {
                            self.likeButton?.setImage(UIImage.init(named: "likeEmpty"), for: .normal)
                            if snapshot.childSnapshot(forPath: "myDislikes").exists() {
                                for d in snapshot.childSnapshot(forPath: "myDislikes").children {
                                    let snap = d as! DataSnapshot
                                    if snap.key == item.itemID {
                                        self.dislikeCheck = true
                                        self.dislikeButton?.setImage(UIImage.init(named: "dislikeFull"), for: .normal)
                                        break
                                    }
                                }
                            }
                            if !self.dislikeCheck {
                                self.dislikeButton?.setImage(UIImage.init(named: "dislikeEmpty"), for: .normal)
                            }
                        }
                    }
                }
            }
        }
        self.line?.widthAnchor.constraint(equalToConstant: frame.width).isActive = true
        self.userImage?.image = UIImage.init(named: item.photo)
        self.username?.text = item.username
        self.faculty?.text = item.faculty
        self.university?.text = item.university
        self.avgRating?.text = String(format: "%.1f", item.avgRating)
        self.avgRating?.textColor = UIColor().setColorRating(number: item.avgRating)
        self.helpNum?.text = String(item.helpNum)
        self.helpNum?.textColor = UIColor().setColorRating(number: item.helpNum)
        self.diffNum?.text = String(item.diffNum)
        self.diffNum?.textColor = UIColor().setColorRatingOpposite(number: item.diffNum)
        self.lecNum?.text = String(item.lecNum)
        self.lecNum?.textColor = UIColor().setColorRating(number: item.lecNum)
        if item.attNum != nil {
            self.attStack?.isHidden = false
            if item.attNum == 1 {
                self.attNum?.text = NSLocalizedString("not_mandatory", comment: "")
                self.attNum?.textColor = UIColor.init(named: "ratingGreen") ?? .green
            } else {
                self.attNum?.text = NSLocalizedString("mandatory", comment: "")
                self.attNum?.textColor = UIColor.init(named: "ratingRed") ?? .red
            }
        } else {
            self.attStack?.isHidden = true
        }
        if item.txtNum != nil {
            self.txtStack?.isHidden = false
            if item.txtNum == 1 {
                self.txtNum?.text = NSLocalizedString("not_mandatory", comment: "")
                self.txtNum?.textColor = UIColor.init(named: "ratingGreen") ?? .green
            } else {
                self.txtNum?.text = NSLocalizedString("mandatory", comment: "")
                self.txtNum?.textColor = UIColor.init(named: "ratingRed") ?? .red
            }
        } else {
            self.txtStack?.isHidden = true
        }
        self.comment?.text = item.comment
        self.likeNum?.text = String(item.likeNum ?? 0)
        self.dislikeNum?.text = String(item.dislikeNum ?? 0)
        self.time?.text = String().convert(time: item.time)
        if item.type != "4" {
            Database.database().reference().child("Professors").child(item.profID).observeSingleEvent(of: .value) { (snapshot,error) in
                if let error = error {
                    print("error", error)
                    return
                }
                var profNameStr = snapshot.childSnapshot(forPath: "prof_name").value as? String ?? ""
                if snapshot.childSnapshot(forPath: "title").exists() {
                    let title = snapshot.childSnapshot(forPath: "title").value as? String ?? ""
                    profNameStr = title+" "+profNameStr
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
                let finalStr2 = NSAttributedString(string: profNameStr, attributes: attributes2)
                finalStr.append(finalStr2)
                self.profName?.attributedText = finalStr
            }
        }
    }
    //MARK: onClick Actions
    @IBAction func likePressed(_ sender: UIButton) {
        self.delegate?.postLiked(cell: self,likeCheck: likeCheck,dislikeCheck: dislikeCheck)
    }
    
    @IBAction func dislikePressed(_ sender: UIButton) {
        self.delegate?.postDisliked(cell: self,likeCheck: likeCheck,dislikeCheck: dislikeCheck)
    }
    
    
    @IBAction func deletePressed(_ sender: UIButton) {
        self.delegate?.delete(cell: self)
    }
    
    @IBAction func reportPressed(_ sender: UIButton) {
        self.delegate?.report(cell: self)
    }
    
    @objc private func profNamePressed(){
        self.delegate?.profClicked(cell: self)
    }
    
    @objc private func userPressed(){
        self.delegate?.userClicked(cell: self)
    }
    
}
