//
//  FeedVC.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 11. 14..
//

import UIKit
import GoogleMobileAds
import Firebase

class FeedVC: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet private weak var cityButton: UIButton!
    @IBOutlet private weak var uniButton: UIButton!
    @IBOutlet private weak var clearButton: UIButton!
    @IBOutlet private weak var buttonsStack: UIStackView!
    @IBOutlet private weak var filterSpinner: UITextField!
    @IBOutlet weak var banner: GADBannerView!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var navgItem: UINavigationItem!
    @IBOutlet private weak var indicator: UIActivityIndicatorView!
    private var selectedFilter : String?
    private var lastPage = false
    private var fCheck = false
    private var pickerList = [String]()
    private var idsList = [String]()
    private var ref = DatabaseReference()
    private var sCheck = 0
    private var comments = [CommentItem]()
    private var ids = [String]()
    private let cellID = "commentCell"
    private var numOfItems = 20
    private var fNumber = 0
    private var commentNum : Int?
    private let design : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    private var sendProfId : String?
    private var sendUserId : String?
    private var refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: true)
        ref = Database.database().reference()
        setViews()
        createPickerView()
        dismissPickerView()
        setBanListener()
        self.collectionView.dataSource = self
        self.collectionView.delegate = collectionView.dataSource as? UICollectionViewDelegate
        design.minimumLineSpacing = 0
        collectionView.collectionViewLayout = design
        loadData()
        refreshControl.attributedTitle = NSAttributedString(string: NSLocalizedString("refresh", comment: ""))
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        collectionView.addSubview(refreshControl)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        banner.adUnitID = "ca-app-pub-4004348027309516/5995817159"
        banner.rootViewController = self
        banner.delegate  = self
        banner.load(GADRequest())
    }
    
    //MARK: onClick Actions
    
    @objc func refresh(_ sender: AnyObject) {
        lastPage = false
        comments.removeAll()
        collectionView.reloadData()
        if selectedFilter != nil && !(selectedFilter?.isEmpty ?? true) {
            idsList.removeAll()
            fNumber = 0
            self.loadFilteredData()
        } else {
            numOfItems = 20
            self.loadData()
        }
        refreshControl.endRefreshing()
    }
    
    @IBAction func filterPressed(_ sender: UIButton) {
        sCheck = 0
        if buttonsStack.isHidden {
            buttonsStack.isHidden = false
        } else {
            buttonsStack.isHidden = true
            filterSpinner.isHidden = true
        }
    }
    
    @IBAction func cityPressed(_ sender: UIButton) {
        fCheck = true
        spinnerList(mRef: ref.child("Cities"))
    }
    
    @IBAction func uniPressed(_ sender: UIButton) {
        fCheck = false
        spinnerList(mRef: ref.child("Universities"))
    }
    
    @IBAction func clearPressed(_ sender: UIButton) {
        clearButton.isHidden = true
        selectedFilter = ""
        filterSpinner.text = ""
        lastPage = false
        idsList.removeAll()
        comments.removeAll()
        fNumber = 0
        numOfItems = 20
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            self.loadData()
        }
    }
    //MARK: Utils
    private func spinnerList(mRef : DatabaseQuery) {
        filterSpinner.isHidden = false
        pickerList.removeAll()
        filterSpinner.text = ""
        lastPage = false
        fNumber = 0
        if fCheck {
            pickerList = [NSLocalizedString("city_name", comment: "")]
            filterSpinner.placeholder = NSLocalizedString("feed_city", comment: "")
        } else {
            pickerList = [NSLocalizedString("uni_name", comment: "")]
            filterSpinner.placeholder = NSLocalizedString("feed_uni", comment: "")
        }
        mRef.observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            for d in snapshot.children {
                let snap = d as! DataSnapshot
                if self.fCheck {
                    self.pickerList.append(CityName().nameFix(name: snap.key))
                } else {
                    self.pickerList.append(snap.key)
                }
            }
        }
    }
    
    private func setViews() {
        let logo = UIImage.resizeImage(image: UIImage(named: "roundLogo.png")!, targetSize: CGSize(width: 40, height: 40))
        let imageView = UIImageView(image:logo)
        let bannerWidth = self.navigationController?.navigationBar.frame.size.width
        let bannerHeight = self.navigationController?.navigationBar.frame.size.height
        let bannerX = bannerWidth! / 2 - (logo.size.width ) / 2
        let bannerY = bannerHeight! / 2 - (logo.size.height ) / 2
        imageView.frame = CGRect(x: bannerX, y: bannerY, width: bannerWidth ?? 0, height: bannerHeight ?? 0)
        imageView.contentMode = .center
        navgItem.titleView = imageView
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DismissKeyboard))
        view.addGestureRecognizer(tap)
        filterSpinner.delegate = self
        cityButton.layer.cornerRadius = 6
        cityButton.contentEdgeInsets = UIEdgeInsets.init(top: 4, left: 4, bottom: 4, right: 4)
        cityButton.titleLabel?.numberOfLines = 0;
        cityButton.titleLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
        uniButton.layer.cornerRadius = 6
        uniButton.contentEdgeInsets = UIEdgeInsets.init(top: 4, left: 4, bottom: 4, right: 4)
        uniButton.titleLabel?.numberOfLines = 0;
        uniButton.titleLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
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
    
    @objc fileprivate func setBanListener() {
        ref.child("bannedUsers").observe(.value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            if snapshot.exists() && Auth.auth().currentUser != nil {
                var check = false
                snapshot.children.forEach { (child) in
                    let snap = child as! DataSnapshot
                    if snap.key.elementsEqual(Auth.auth().currentUser?.uid ?? "") {
                        check = true
                    }
                }
                if check {
                    let alertController = UIAlertController(title: NSLocalizedString("info", comment: ""), message: NSLocalizedString("info_banned", comment: ""), preferredStyle: .alert)
                    self.present(alertController, animated: true, completion: nil)
                    let when = DispatchTime.now() + 5
                    DispatchQueue.main.asyncAfter(deadline: when){
                        alertController.dismiss(animated: true, completion: nil)
                    }
                    do {
                        try Auth.auth().signOut()
                    } catch {
                        fatalError("unable to sign out")
                    }
                } else {
                    let timeStamp = Int(1000 * Date().timeIntervalSince1970)
                    self.ref.child("users").child(Auth.auth().currentUser?.uid ?? "").child("lastEntrance").setValue(timeStamp)
                }
            }
        }
    }
    //MARK: PrepareSegue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "feedToProfSegue" {
           let cv = segue.destination as! ClickedProfVC
           cv.profID = sendProfId
        } else if segue.identifier == "feedToUserSegue" {
           let cv = segue.destination as! ClickedUserVC
           cv.userID = sendUserId
        }
    }
    
    //MARK: LoadData
    private func loadData() {
        var spinner = UIActivityIndicatorView()
        if #available(iOS 13.0, *) {
            spinner = UIActivityIndicatorView(style: .large)
        } else {
            spinner = UIActivityIndicatorView(style: .gray)
        }
        spinner.color = UIColor.init(named: "appBlueColor")
        spinner.startAnimating()
        collectionView.backgroundView = spinner
        ref.child("ratings").child("withComment").observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            self.commentNum = Int(snapshot.childrenCount)
        }
        ref.child("ratings").child("withComment").queryOrderedByKey().queryLimited(toLast: UInt(numOfItems)).observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            self.comments.removeAll()
            for d in snapshot.children {
                let snap = d as! DataSnapshot
                self.addRating(ratingID: snap.key)
            }
        }
    }
    //MARK: LoadMore
    private func loadMore() {
        ref.child("ratings").child("withComment").queryOrderedByKey().queryLimited(toLast: UInt(numOfItems)).observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            self.ids.removeAll()
            var count = 0
            for d in snapshot.children.reversed() {
                let snap = d as! DataSnapshot
                self.ids.append(snap.key)
            }
            for s in self.ids {
                if count >= self.comments.count {
                    if self.selectedFilter != nil && !(self.selectedFilter?.isEmpty ?? true) {
                        self.ref.child("Professors").child(snapshot.childSnapshot(forPath: s).childSnapshot(forPath: "profID").value as? String ?? "").observeSingleEvent(of: .value) { (snapshot2,error2) in
                            if let error = error2 {
                                print("error",error)
                                return
                            }
                            if self.fCheck {
                                if self.selectedFilter == CityName().nameFix(name: snapshot2.childSnapshot(forPath: "city").value as? String ?? "") {
                                    self.addRating(ratingID: s)
                                } else {
                                    self.numOfItems -= 1
                                }
                            } else {
                                if self.selectedFilter == snapshot2.childSnapshot(forPath: "uni_name").value as? String ?? "" {
                                    self.addRating(ratingID: s)
                                } else {
                                    self.numOfItems -= 1
                                }
                            }
                        }
                    } else {
                        print("deneme ids",s)
                        self.addRating(ratingID: s)
                    }
                }
                count += 1
            }
            
        }
    }
    
    //MARK: LoadFilteredData
    private func loadFilteredData(){
        var spinner = UIActivityIndicatorView()
        if #available(iOS 13.0, *) {
            spinner = UIActivityIndicatorView(style: .large)
        } else {
            spinner = UIActivityIndicatorView(style: .gray)
        }
        spinner.color = UIColor.init(named: "appBlueColor")
        spinner.startAnimating()
        collectionView.backgroundView = spinner
        comments.removeAll()
        idsList.removeAll()
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        ref.child("ratings").child("withComment").queryOrderedByKey().observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            var fc = 0
            let tNum = snapshot.childrenCount
            if tNum == 0 {
                self.collectionView.backgroundView = nil
            }
            for d in snapshot.children {
                let snap = d as! DataSnapshot
                self.ref.child("Professors").child(snap.childSnapshot(forPath: "profID").value as? String ?? "").observeSingleEvent(of: .value) { (snapshot2,error2) in
                    if let error = error2 {
                        print("error",error)
                        return
                    }
                    if self.selectedFilter != nil && !(self.selectedFilter?.isEmpty ?? true) {
                        if self.fCheck {
                            if self.selectedFilter == CityName().nameFix(name: snapshot2.childSnapshot(forPath: "city").value as? String ?? "") {
                                self.idsList.append(snap.key)
                            }
                        } else {
                            if self.selectedFilter == snapshot2.childSnapshot(forPath: "uni_name").value as? String ?? "" {
                                self.idsList.append(snap.key)
                            }
                        }
                    }
                    fc += 1
                    if fc == tNum {
                        self.idsList.reverse()
                        self.addFiltered()
                    }
                }
            }
        }
    }
    //MARK: AddFiltered
    private func addFiltered() {
        var count = 0
        for s in idsList {
            if (count >= fNumber) && ((count-fNumber) < 20) {
                self.addRating(ratingID: s)
            }
            count += 1
        }
        if count == 0 {
            self.collectionView.backgroundView = nil
        }
        if count == fNumber {
            self.indicator.stopAnimating()
            self.indicator.isHidden = true
        }
    }
    
    //MARK: AddRating
    private func addRating(ratingID : String) {
        ref.child("ratings").child("withComment").child(ratingID).observeSingleEvent(of: .value) { (snapshot,error) in
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
                        let cItem = ["username" : snapshot2.childSnapshot(forPath: "username").value as? String ?? "", "photo" : snapshot2.childSnapshot(forPath: "photo").value as? String ?? "pp1", "userID" : snapshot.childSnapshot(forPath: "userID").value as? String ?? "", "university" : snapshot2.childSnapshot(forPath: "university").value as? String ?? "", "faculty" : snapshot2.childSnapshot(forPath: "faculty").value as? String ?? "", "avgRating" : avg, "helpNum" : help, "diffNum" : diff, "lecNum" : lec, "comment" : snapshot.childSnapshot(forPath: "comment").value as? String ?? "", "time" : snapshot.childSnapshot(forPath: "time").value as? UInt ?? 0, "popularity" : snapshot.childSnapshot(forPath: "popularity").value as? UInt ?? 0, "itemID" : ratingID, "profID" : snapshot.childSnapshot(forPath: "profID").value as? String ?? "", "check" : true] as [String : Any]
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
                        commentItem.type = "5"
                        self.comments.append(commentItem)
                        self.comments.sort {
                           $0.time > $1.time
                        }
                        DispatchQueue.main.async {
                            self.collectionView.backgroundView = nil
                            self.collectionView.reloadData()
                            self.indicator.stopAnimating()
                            self.indicator.isHidden = true
                        }
                    }
                }
            }
        }
    }
    
    //MARK: PickerView
    private func createPickerView() {
       let pickerView = UIPickerView()
       pickerView.delegate = self
       filterSpinner.inputView = pickerView
   }
       
   private func dismissPickerView() {
       let toolBar = UIToolbar()
       toolBar.sizeToFit()
       let button = UIBarButtonItem(title: NSLocalizedString("done", comment: ""), style: .plain, target: self, action: #selector(self.action))
       toolBar.setItems([button], animated: true)
       toolBar.isUserInteractionEnabled = true
       filterSpinner.inputAccessoryView = toolBar
   }
   
   @objc private func action() {
       view.endEditing(true)
   }
    
   @objc private func DismissKeyboard(){
       view.endEditing(true)
   }
   
   func numberOfComponents(in pickerView: UIPickerView) -> Int {
       return 1
   }
   
   func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
   {
       return pickerList.count
   }
       
   func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerList[row]
   }
   
   func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedFilter = pickerList[row]
        filterSpinner.text = selectedFilter
         if selectedFilter?.isEmpty ?? true || selectedFilter?.elementsEqual(NSLocalizedString("city_name", comment: "")) ?? false || selectedFilter?.elementsEqual(NSLocalizedString("uni_name", comment: "")) ?? false {
            selectedFilter = ""
            filterSpinner.text = selectedFilter
            clearButton.isHidden = true
            lastPage = false
            if sCheck != 0 {
                DispatchQueue.main.async {
                    self.comments.removeAll()
                    self.collectionView.reloadData()
                    self.loadData()
                }
            }
         } else {
            clearButton.isHidden = false
            self.loadFilteredData()
            sCheck += 1
         }
   }
}
//MARK: CollectionView Extensions
extension FeedVC: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate, CommentCellDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return comments.count
    }
        
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! CommentCell
        cell.configure(with: self.comments[indexPath.row])
        cell.delegate = self
        return cell
    }

   func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 246 //dummyCell.header.bounds.height
        let yourString = comments[indexPath.row].comment
        let textSize = yourString.size(width: collectionView.frame.width - 30)
        height += textSize.height
        if comments[indexPath.row].attNum != nil && comments[indexPath.row].txtNum != nil {
            height += 37
        }else if comments[indexPath.row].attNum != nil || comments[indexPath.row].txtNum != nil  {
            height += 15
        }else {
            height -= 5
        }
        return CGSize(width: collectionView.frame.width, height: height)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView == collectionView {
            if ((scrollView.contentOffset.y + scrollView.frame.size.height) >= scrollView.contentSize.height) {
                if indicator.color != UIColor.init(named: "appBlueColor") {
                    indicator.color = UIColor.init(named: "appBlueColor")
                }
                if !lastPage {
                    if selectedFilter != nil && !(selectedFilter?.isEmpty ?? true) {
                        self.indicator.isHidden = false
                        self.indicator.startAnimating()
                        if (idsList.count - fNumber) > 20 {
                            fNumber += 20
                        } else {
                            fNumber += idsList.count - fNumber
                            lastPage = true
                        }
                        self.addFiltered()
                    } else {
                        if self.comments.count > 19 {
                            self.indicator.isHidden = false
                            self.indicator.startAnimating()
                            if ((commentNum ?? 0) - numOfItems) > 20 {
                                numOfItems += 20
                            } else {
                                numOfItems += ((commentNum ?? 0) - numOfItems)
                                lastPage = true
                            }
                            if !(self.comments.count < 20) {
                                DispatchQueue.main.async {
                                    self.loadMore()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    //MARK: onClick Actions
    func postLiked(cell: CommentCell, likeCheck: Bool, dislikeCheck: Bool) {
        if Auth.auth().currentUser != nil {
            guard let indexPath = collectionView.indexPath(for: cell) else {return}
            let comment = self.comments[indexPath.row]
            //MARK: Like
            if likeCheck { // only like exists //remove like
                cell.likeCheck = false
                cell.likeButton?.setImage(UIImage.init(named: "likeEmpty"), for: .normal)
                var lNum = Int(comment.likeNum ?? 0)
                lNum -= 1
                self.comments[indexPath.row].likeNum = lNum
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
                self.comments[indexPath.row].likeNum = lNum
                self.comments[indexPath.row].dislikeNum = disNum
                cell.likeNum?.text = String(lNum)
                cell.dislikeNum?.text = String(disNum)
                HandleLikeActions().likeDislikeProcess(type: 3, likeType: true, item: comment, ratingLikeCheck: 2)
            } else { // none exists // add like
                cell.likeCheck = true
                cell.likeButton?.setImage(UIImage.init(named: "likeFull"), for: .normal)
                var lNum = Int(comment.likeNum ?? 0)
                lNum += 1
                self.comments[indexPath.row].likeNum = lNum
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
            let comment = self.comments[indexPath.row]
            if likeCheck { // only like exists // remove like, add dislike
                cell.likeCheck = false
                cell.dislikeCheck = true
                cell.dislikeButton?.setImage(UIImage.init(named: "dislikeFull"), for: .normal)
                cell.likeButton?.setImage(UIImage.init(named: "likeEmpty"), for: .normal)
                var disNum = Int(comment.dislikeNum ?? 0)
                disNum += 1
                var lNum = Int(comment.likeNum ?? 0)
                lNum -= 1
                self.comments[indexPath.row].likeNum = lNum
                self.comments[indexPath.row].dislikeNum = disNum
                cell.likeNum?.text = String(lNum)
                cell.dislikeNum?.text = String(disNum)
                HandleLikeActions().likeDislikeProcess(type: 3, likeType: false, item: comment, ratingLikeCheck: 2)
            } else if dislikeCheck { // only dislike exists // remove dislike
                cell.dislikeCheck = false
                cell.dislikeButton?.setImage(UIImage.init(named: "dislikeEmpty"), for: .normal)
                var dNum = Int(comment.dislikeNum ?? 0)
                dNum -= 1
                self.comments[indexPath.row].dislikeNum = dNum
                cell.dislikeNum?.text = String(dNum)
                HandleLikeActions().likeDislikeProcess(type: 3, likeType: false, item: comment, ratingLikeCheck: 1)
            } else { // none exists // add dislike
                cell.dislikeCheck = true
                cell.dislikeButton?.setImage(UIImage.init(named: "dislikeFull"), for: .normal)
                var disNum = Int(comment.dislikeNum ?? 0)
                disNum += 1
                self.comments[indexPath.row].dislikeNum = disNum
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
            let comment = self.comments[indexPath.row]
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
                    self.comments.remove(at: indexPath.row)
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
            let comment = self.comments[indexPath.row]
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
        guard let indexPath = collectionView.indexPath(for: cell) else {return}
        let comment = self.comments[indexPath.row]
        sendProfId = comment.profID
        performSegue(withIdentifier: "feedToProfSegue", sender: self)
    }
    
    func userClicked(cell: CommentCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else {return}
        let comment = self.comments[indexPath.row]
        sendUserId = comment.userID
        performSegue(withIdentifier: "feedToUserSegue", sender: self)
    }
}
extension FeedVC: GADBannerViewDelegate {
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("Banner loaded successfully")
    }

    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print("Fail to receive ads")
        print(error)
    }
}

