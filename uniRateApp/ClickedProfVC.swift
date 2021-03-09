//
//  ClickedProfVC.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 09..
//

import UIKit
import Firebase

class ClickedProfVC: UIViewController {
    
    var profID : String?
    var object : SearchItem?
    private var ref = DatabaseReference()
    private let cellID = "commentCell"
    private var cNumber = 0
    private var numOfItems = 10
    private var lastPage = false
    private var list = [CommentItem]()
    private var ids = [String]()
    @IBOutlet private weak var profImage: UIImageView!
    @IBOutlet private weak var profName: UILabel!
    @IBOutlet private weak var fieldName: UILabel!
    @IBOutlet private weak var cityUniName: UILabel!
    @IBOutlet private weak var avgRating: UILabel!
    @IBOutlet private weak var detailButton: UIButton!
    @IBOutlet private weak var totalNum: UILabel!
    @IBOutlet private weak var detailStack: UIStackView!
    @IBOutlet private weak var helpNum: UILabel!
    @IBOutlet private weak var diffNum: UILabel!
    @IBOutlet private weak var lecNum: UILabel!
    @IBOutlet private weak var attStack: UIStackView!
    @IBOutlet private weak var attNum: UILabel!
    @IBOutlet private weak var txtStack: UIStackView!
    @IBOutlet private weak var txtNum: UILabel!
    @IBOutlet private weak var commentNum: UILabel!
    @IBOutlet private weak var navgTitle: UINavigationItem!
    @IBOutlet private weak var emptyView: UIView!
    @IBOutlet private weak var collectionView: UICollectionView!
    
    private let design : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    private var sendUserId : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        if !(profID?.isEmpty ?? true) {
            ref.child("Professors").child(profID ?? "").observeSingleEvent(of: .value) { (snapshot,error) in
                if let error = error {
                    print("error",error)
                    return
                }
                let cityUniName = (snapshot.childSnapshot(forPath: "city").value as? String ?? "")+","+(snapshot.childSnapshot(forPath: "uni_name").value as? String ?? "")
                let sItem = ["cityUniName" : cityUniName, "fieldName" : snapshot.childSnapshot(forPath: "field_name").value as? String ?? "", "profName" : snapshot.childSnapshot(forPath: "prof_name").value as? String ?? "", "photoNum" : snapshot.childSnapshot(forPath: "photo").value as? Int ?? 0, "itemID" : self.profID ?? "", "ratingNum" : snapshot.childSnapshot(forPath: "avg_rating").value as? Double ?? 0.0] as [String : Any]
                self.object = SearchItem(searchData: sItem as [String : Any])
                if snapshot.childSnapshot(forPath: "title").exists() {
                    self.object?.title = snapshot.childSnapshot(forPath: "title").value as? String ?? ""
                }
                self.setInfo()
                self.loadData()
            }
        } else {
            setInfo()
            loadData()
        }
        self.collectionView.dataSource = self
        self.collectionView.delegate = collectionView.dataSource as? UICollectionViewDelegate
        design.minimumLineSpacing = 0
        collectionView.collectionViewLayout = design
        
    }
    //MARK: onClickActions
    @IBAction func detailPressed(_ sender: UIButton) {
        if detailStack.isHidden {
            detailStack.isHidden = false
            detailButton.setImage(UIImage.init(named: "arrowDown"), for: .normal)
        } else {
            detailStack.isHidden = true
            detailButton.setImage(UIImage.init(named: "arrowRight"), for: .normal)
        }
    }
    
    @IBAction func ratingPressed(_ sender: UIBarButtonItem) {
        if Auth.auth().currentUser != nil {
            self.performSegue(withIdentifier: "clickedProfToRateSegue", sender: self)
        } else {
            showAlert(type: 3)
        }
    }
    
    @IBAction func emptyPressed(_ sender: UIButton) {
        if Auth.auth().currentUser != nil {
            self.performSegue(withIdentifier: "clickedProfToRateSegue", sender: self)
        } else {
            showAlert(type: 3)
        }
    }
    
    
    //MARK: Set info
    @objc fileprivate func setInfo() {
        var pName = object?.profName ?? ""
        let title = object?.title ?? ""
        if !title.isEmpty {
            pName = title+" "+pName
        }
        self.profName.text = pName
        self.fieldName.text = object?.fieldName
        self.cityUniName.text = object?.cityUniName
        self.avgRating.text = String(format: "%.1f", object?.ratingNum ?? 0.0)
        self.avgRating.textColor = UIColor().setColorRating(number: object?.ratingNum ?? 0.0)
        if object?.photo == 1 || String(object?.photo ?? 0) == "1" {
            self.profImage.image = UIImage.init(named: "teacher_man")
        } else {
            self.profImage.image = UIImage.init(named: "teacher_woman")
        }
        self.ref.child("addedProf").observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            let nView = UIView()
            let label = UILabel()
            label.text = NSLocalizedString("nvg_title", comment: "")
            label.sizeToFit()
            label.center = nView.center
            label.textAlignment = NSTextAlignment.center
            let image = UIImageView()
            if snapshot.exists() {
                var check = false
                for d in snapshot.children {
                    let snap = d as! DataSnapshot
                    if self.object?.itemID == snap.key {
                        image.image = UIImage(named: "not_verified")?.withRenderingMode(.alwaysOriginal)
                        check = true
                        break
                    }
                }
                if !check {
                    image.image = UIImage(named: "verified")?.withRenderingMode(.alwaysOriginal)
                }
            } else {
                image.image = UIImage(named: "verified")?.withRenderingMode(.alwaysOriginal)
            }
            let imageAspect = image.image!.size.width/image.image!.size.height
            image.frame = CGRect(x: label.frame.origin.x+label.frame.size.width+10, y: label.frame.origin.y, width: label.frame.size.height*imageAspect, height: label.frame.size.height)
            image.contentMode = UIView.ContentMode.scaleAspectFit
            nView.addSubview(label)
            nView.addSubview(image)
            self.navigationItem.titleView = nView
            nView.sizeToFit()
        }
    }
    //MARK: Load Data
    @objc fileprivate func loadData() {
        ref.child("Professors").child(object?.itemID ?? "").observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            if snapshot.exists() {
                let total = snapshot.childSnapshot(forPath: "ratings_total").childrenCount
                self.totalNum.text = String(total)+" "+NSLocalizedString("ratings", comment: "")
                self.cNumber = Int(snapshot.childSnapshot(forPath: "ratings_comment").childrenCount)
                self.commentNum.text = String(self.cNumber)+" "+NSLocalizedString("ratings", comment: "")
                let zero = "0.0"
                let zeroStr = "-"
                if snapshot.childSnapshot(forPath: "ratings").exists() {
                    if snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "helpfulness").exists() {
                        let value = snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "helpfulness").value as? Double ?? 0.0
                        let final = value / Double(total)
                        self.helpNum.text = String(format: "%.1f", final)
                        self.helpNum.textColor = UIColor().setColorRating(number: final)
                    } else {
                        self.helpNum.text = zero
                        self.helpNum.textColor = UIColor.init(named: "textHintColor")
                    }
                    if snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "difficulty").exists() {
                        let value = snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "difficulty").value as? Double ?? 0.0
                        let final = value / Double(total)
                        self.diffNum.text = String(format: "%.1f", final)
                        self.diffNum.textColor = UIColor().setColorRatingOpposite(number: final)
                    } else {
                        self.diffNum.text = zero
                        self.diffNum.textColor = UIColor.init(named: "textHintColor")
                    }
                    if snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "lecture").exists() {
                        let value = snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "lecture").value as? Double ?? 0.0
                        let final = value / Double(total)
                        self.lecNum.text = String(format: "%.1f", final)
                        self.lecNum.textColor = UIColor().setColorRating(number: final)
                    } else {
                        self.lecNum.text = zero
                        self.lecNum.textColor = UIColor.init(named: "textHintColor")
                    }
                    if snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "attendance").exists() {
                        let value = snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "attendance").childSnapshot(forPath: "rating").value as? Double ?? 0.0
                        let times = snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "attendance").childSnapshot(forPath: "times").value as? Double ?? 0.0
                        let final = value / times
                        if final <= 1.5 {
                            self.attNum.text = NSLocalizedString("not_mandatory", comment: "")
                            self.attNum.textColor = UIColor.init(named: "ratingGreen") ?? .green
                        } else {
                            self.attNum.text = NSLocalizedString("mandatory", comment: "")
                            self.attNum.textColor = UIColor.init(named: "ratingRed") ?? .red
                        }
                    } else {
                        self.attNum.text = zeroStr
                        self.attNum.textColor = UIColor.init(named: "textHintColor")
                    }
                    if snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "textbook").exists() {
                        let value = snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "textbook").childSnapshot(forPath: "rating").value as? Double ?? 0.0
                        let times = snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "textbook").childSnapshot(forPath: "times").value as? Double ?? 0.0
                        let final = value / times
                        if final <= 1.5 {
                            self.txtNum.text = NSLocalizedString("not_mandatory", comment: "")
                            self.txtNum.textColor = UIColor.init(named: "ratingGreen") ?? .green
                        } else {
                            self.txtNum.text = NSLocalizedString("mandatory", comment: "")
                            self.txtNum.textColor = UIColor.init(named: "ratingRed") ?? .red
                        }
                    } else {
                        self.txtNum.text = zeroStr
                        self.txtNum.textColor = UIColor.init(named: "textHintColor")
                    }
                } else {
                    self.helpNum.text = zero
                    self.diffNum.text = zero
                    self.lecNum.text = zero
                    self.attNum.text = zeroStr
                    self.txtNum.text = zeroStr
                    self.helpNum.textColor = UIColor.init(named: "textHintColor")
                    self.diffNum.textColor = UIColor.init(named: "textHintColor")
                    self.lecNum.textColor = UIColor.init(named: "textHintColor")
                    self.attNum.textColor = UIColor.init(named: "textHintColor")
                    self.txtNum.textColor = UIColor.init(named: "textHintColor")
                }
                if self.cNumber > 0 {
                    self.loadComments()
                    self.emptyView.isHidden = true
                } else {
                    self.emptyView.isHidden = false
                }
            }
        }
    }
    //MARK: Load Comments
    @objc fileprivate func loadComments() {
        var spinner = UIActivityIndicatorView()
        if #available(iOS 13.0, *) {
            spinner = UIActivityIndicatorView(style: .large)
        } else {
            spinner = UIActivityIndicatorView(style: .gray)
        }
        spinner.color = UIColor.init(named: "appBlueColor")
        spinner.startAnimating()
        collectionView.backgroundView = spinner
        ref.child("Professors").child(object?.itemID ?? "").child("ratings_comment").queryOrderedByValue().queryLimited(toLast: UInt(numOfItems)).observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            self.list.removeAll()
            for d in snapshot.children {
                let snap = d as! DataSnapshot
                self.addComment(commentID: snap.key)
            }
        }
    }
    //MARK: Load More
    @objc fileprivate func loadMore() {
        let number = list.count
        let startKey = list[number-1].itemID
        ref.child("Professors").child(object?.itemID ?? "").child("ratings_comment").queryOrderedByValue().queryEnding(atValue: startKey).queryLimited(toLast: UInt(numOfItems)).observeSingleEvent(of: .value) { (snapshot,error) in
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
                    self.addComment(commentID: s)
                }
                count += 1
            }
        }
    }
    //MARK: Add Comment
    @objc fileprivate func addComment(commentID: String) {
        ref.child("ratings").child("withComment").child(commentID).observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            if snapshot.exists() {
                self.ref.child("users").child(snapshot.childSnapshot(forPath: "userID").value as? String ?? "").observeSingleEvent(of: .value) { (snapshot2,error2) in
                    if let error = error2 {
                        print("error",error)
                        return
                    }
                    if snapshot2.exists() {
                        let avg = snapshot.childSnapshot(forPath: "avg_rating").value as? Double ?? 0.0
                        let help = Double(snapshot.childSnapshot(forPath: "helpfulness").value as? String ?? "0") ?? 0.0
                        let diff = Double(snapshot.childSnapshot(forPath: "difficulty").value as? String ?? "0") ?? 0.0
                        let lec = Double(snapshot.childSnapshot(forPath: "lecture").value as? String ?? "0") ?? 0.0
                        let cItem = ["username" : snapshot2.childSnapshot(forPath: "username").value as? String ?? "", "photo" : snapshot2.childSnapshot(forPath: "photo").value as? String ?? "", "userID" : snapshot.childSnapshot(forPath: "userID").value as? String ?? "", "university" : snapshot2.childSnapshot(forPath: "university").value as? String ?? "", "faculty" : snapshot2.childSnapshot(forPath: "faculty").value as? String ?? "", "avgRating" : avg, "helpNum" : help, "diffNum" : diff, "lecNum" : lec, "comment" : snapshot.childSnapshot(forPath: "comment").value as? String ?? "", "time" : snapshot.childSnapshot(forPath: "time").value as? UInt ?? 0, "popularity" : snapshot.childSnapshot(forPath: "popularity").value as? UInt ?? 0, "itemID" : commentID, "profID" : snapshot.childSnapshot(forPath: "profID").value as? String ?? "", "check" : true] as [String : Any]
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
                        if snapshot2.childSnapshot(forPath: "myLikedNumber").exists() {
                            commentItem.userLikedNum = Int(snapshot2.childSnapshot(forPath: "myLikedNumber").value as? String ?? "0") ?? 0
                        }
                        if snapshot2.childSnapshot(forPath: "myDislikedNumber").exists() {
                            commentItem.userDislikedNum = Int(snapshot2.childSnapshot(forPath: "myDislikedNumber").value as? String ?? "0") ?? 0
                        }
                        commentItem.type = "4"
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
        if segue.identifier == "clickedProfToRateSegue" {
            let vc = segue.destination as? RateVC
            vc?.object = self.object
            vc?.delegate = self
        } else if segue.identifier == "clickedProfToUserSegue" {
            let vc = segue.destination as? ClickedUserVC
            vc?.userID = sendUserId
        }
    }
}
//MARK: CollectionView Extension
extension ClickedProfVC: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate, CommentCellDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return list.count
    }
        
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! CommentCell
        cell.likeCheck = false
        cell.dislikeCheck = false
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
        //empty
    }
    
    func userClicked(cell: CommentCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else {return}
        let comment = self.list[indexPath.row]
        sendUserId = comment.userID
        performSegue(withIdentifier: "clickedProfToUserSegue", sender: self)
    }
}
extension ClickedProfVC: RatedProfDelegate {
    func profRated(object: SearchItem) {
        self.object = object
        self.setInfo()
        self.loadData()
    }
}
