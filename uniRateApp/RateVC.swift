//
//  RateVC.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 15..
//

import UIKit
import Firebase
import JGProgressHUD
import GoogleMobileAds

protocol RatedProfDelegate: AnyObject
{
    func profRated(object: SearchItem)
}

class RateVC: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet private weak var profImage: UIImageView!
    @IBOutlet private weak var avgRating: UILabel!
    @IBOutlet private weak var profName: UILabel!
    @IBOutlet private weak var fieldName: UILabel!
    @IBOutlet private weak var cityUniName: UILabel!
    @IBOutlet private weak var profView: UIView!
    @IBOutlet private weak var givePointsButton: UIButton!
    @IBOutlet private weak var addCommentButton: UIButton!
    @IBOutlet private weak var commentTxt: UITextView!
    @IBOutlet private weak var helpPicker: UITextField!
    @IBOutlet private weak var diffPicker: UITextField!
    @IBOutlet private weak var lecPicker: UITextField!
    @IBOutlet private weak var attPicker: UITextField!
    @IBOutlet private weak var txtPicker: UITextField!
    @IBOutlet private weak var pointsStack: UIStackView!
    @IBOutlet private weak var helpTitle: UILabel!
    @IBOutlet private weak var diffTitle: UILabel!
    @IBOutlet private weak var lecTitle: UILabel!
    @IBOutlet weak var banner: GADBannerView!
    private var ref = DatabaseReference()
    var object : SearchItem?
    private var ratingList = [String]()
    private var ratingListStr = [String]()
    private var sHelp,sDiff,sLec,sAtt,sTxt : String?
    private let hud = JGProgressHUD(style : .light)
    weak var delegate : RatedProfDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        setViews()
        setInfo()
        createPickerView()
        dismissPickerView()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(sender:)), name: UIResponder.keyboardWillShowNotification, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(sender:)), name: UIResponder.keyboardWillHideNotification, object: nil);
    }
    
    override func viewWillAppear(_ animated: Bool) {
        banner.adUnitID = "ca-app-pub-4004348027309516/1198125932"
        banner.rootViewController = self
        banner.load(GADRequest())
    }
    //MARK: onClick Actions
    @IBAction func givePointsPressed(_ sender: UIButton) {
        if pointsStack.isHidden {
            pointsStack.isHidden = false
            givePointsButton.setImage(UIImage.init(named: "arrowDown"), for: .normal)
        } else {
            pointsStack.isHidden = true
            givePointsButton.setImage(UIImage.init(named: "arrowRight"), for: .normal)
        }
    }
    
    @IBAction func addCommentPressed(_ sender: UIButton) {
        if commentTxt.isHidden {
            commentTxt.isHidden = false
            addCommentButton.setImage(UIImage.init(named: "arrowDown"), for: .normal)
        } else {
            commentTxt.isHidden = true
            addCommentButton.setImage(UIImage.init(named: "arrowRight"), for: .normal)
        }
    }
    
    @IBAction func donePressed(_ sender: UIBarButtonItem) {
        hud.textLabel.text = NSLocalizedString("saving", comment: "")
        hud.show(in: self.view)
        if !(sHelp?.isEmpty ?? true) && !(sDiff?.isEmpty ?? true)
            && !(sLec?.isEmpty ?? true) {
            if commentTxt.text.isEmpty {
                self.hud.dismiss(animated: true)
                let alert = UIAlertController(title: NSLocalizedString("info", comment: ""), message: NSLocalizedString("rate_no_comment", comment: ""), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("yes", comment: ""), style: .default, handler: { [weak alert] (_) in
                    if self.slangWordCheck(text: self.commentTxt.text) {
                        self.slangAlert()
                    } else {
                        self.uploadToDB(check: false)
                    }
                    alert?.dismiss(animated: true, completion: {})
                }))
                alert.addAction(UIAlertAction(title: NSLocalizedString("add_comment", comment: ""), style: .default, handler: { [weak alert] (_) in
                    alert?.dismiss(animated: true, completion: {})
                }))
                self.present(alert, animated: true, completion: nil)
            } else {
                if self.slangWordCheck(text: commentTxt.text) {
                    self.hud.dismiss(animated: true)
                    self.slangAlert()
                } else {
                    self.uploadToDB(check: true)
                }
            }
        } else {
            self.hud.dismiss(animated: true)
            let alert = UIAlertController(title: NSLocalizedString("error", comment: ""), message: NSLocalizedString("rate_fill_all", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { [weak alert] (_) in
                alert?.dismiss(animated: true, completion: {})
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func keyboardWillShow(sender: NSNotification) {
        if self.pointsStack.isHidden {
            self.view.frame.origin.y = -100 // Move view 150 points upward
        } else {
            self.view.frame.origin.y = -300 // Move view 150 points upward
        }
    }

    @objc func keyboardWillHide(sender: NSNotification) {
         self.view.frame.origin.y = 0 // Move view to original position
    }
    
    @objc private func DismissKeyboard(){
        view.endEditing(true)
    }
    
    @objc private func action() {
        view.endEditing(true)
    }
    //MARK: Utils
    @objc fileprivate func slangWordCheck(text: String) -> Bool {
        let list = [NSLocalizedString("slang_1", comment: ""),NSLocalizedString("slang_2", comment: ""),NSLocalizedString("slang_3", comment: ""),NSLocalizedString("slang_4", comment: ""),NSLocalizedString("slang_5", comment: ""),NSLocalizedString("slang_6", comment: ""),NSLocalizedString("slang_7", comment: ""),NSLocalizedString("slang_8", comment: ""),NSLocalizedString("slang_9", comment: ""),NSLocalizedString("slang_15", comment: ""),NSLocalizedString("slang_16", comment: ""),NSLocalizedString("slang_17", comment: ""),NSLocalizedString("slang_18", comment: ""),NSLocalizedString("slang_20", comment: ""),"amınakoduğum","amınakodumun"," amına koduğum"," amına kodumun"," siktiğimin "," nah "]
        var check = false
        for s in list {
            if commentTxt.text.contains(s) {
                check = true
                break
            }
        }
        return check
    }
    
    @objc fileprivate func slangAlert() {
        let alert = UIAlertController(title: NSLocalizedString("info", comment: ""), message: NSLocalizedString("slang_exp", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { [weak alert] (_) in
            alert?.dismiss(animated: true, completion: {})
        }))
        self.present(alert, animated: true, completion: nil)
    }
    //MARK: Upload to DB
    @objc fileprivate func uploadToDB(check: Bool) {
        var key = DatabaseReference()
        let cTime = Date().currentTimeMillis()
        var rate = ["helpfulness" : sHelp ?? "0", "difficulty" : sDiff ?? "0", "lecture" : sLec ?? "0", "userID" : Auth.auth().currentUser?.uid ?? "", "time" : cTime, "profID" : object?.itemID ?? ""] as [String : Any]
        if check {
            key = self.ref.child("ratings").child("withComment").childByAutoId()
            rate["comment"] = self.commentTxt.text
            rate["popularity"] = 0
        } else {
            key = self.ref.child("ratings").child("noComment").childByAutoId()
        }
        let avg = self.calculateRating()
        rate["avg_rating"] = avg
        if !(sAtt?.isEmpty ?? true) {
            if sAtt == NSLocalizedString("mandatory", comment: "") {
                key.child("attendance").setValue(2)
                rate["attendance"] = 2
            } else {
                key.child("attendance").setValue(1)
                rate["attendance"] = 1
            }
        }
        if !(sTxt?.isEmpty ?? true) {
            if sTxt == NSLocalizedString("mandatory", comment: "") {
                key.child("textbook").setValue(2)
                rate["textbook"] = 2
            } else {
                key.child("textbook").setValue(1)
                rate["textbook"] = 1
            }
        }
        key.setValue(rate)
        let keyStr = key.key ?? ""
        if check {
            ref.child("ratings").child("withComment").child(keyStr).setValue(rate)
            ref.child("users").child(Auth.auth().currentUser?.uid ?? "").child("myRatings").child(keyStr).setValue(true)
            ref.child("Professors").child(self.object?.itemID ?? "").child("ratings_total").child(keyStr).setValue(avg)
            ref.child("Professors").child(self.object?.itemID ?? "").child("ratings_comment").child(keyStr).setValue(0)
            self.updateRatings()
        } else {
            ref.child("ratings").child("noComment").child(keyStr).setValue(rate)
            ref.child("users").child(Auth.auth().currentUser?.uid ?? "").child("myRatings").child(keyStr).setValue(false)
            ref.child("Professors").child(self.object?.itemID ?? "").child("ratings_total").child(keyStr).setValue(avg)
            self.updateRatings()
        }
    }
    //MARK: Calculate Rating
    @objc fileprivate func calculateRating() -> Double {
        var value = Double(sDiff ?? "3")
        if value == 5 {
            value = 1
        }else if value == 4 {
            value = 2
        }else if value == 2 {
            value = 4
        }else if value == 1 {
            value = 5
        }
        let dHelp = Double(sHelp ?? "0") ?? 0.0
        let dLec = Double(sLec ?? "0") ?? 0.0
        let add = (dHelp + (value ?? 0.0) + dLec)
        var avg = add / 3
        if !(sAtt?.isEmpty ?? true) {
            if avg > 0.3 && avg < 4.8 {
                if sAtt == NSLocalizedString("mandatory", comment: "") {
                    avg = avg - 0.3
                } else {
                    avg = avg + 0.3
                }
            }
        }
        if !(sTxt?.isEmpty ?? true) {
            if avg > 0.3 && avg < 4.8 {
                if sTxt == NSLocalizedString("mandatory", comment: "") {
                    avg = avg - 0.3
                } else {
                    avg = avg + 0.3
                }
            }
        }
        return avg
    }
    //MARK: Update Ratings
    @objc fileprivate func updateRatings() {
        ref.child("Professors").child(object?.itemID ?? "").observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            if snapshot.exists() {
                if snapshot.childSnapshot(forPath: "ratings_total").exists() {
                    if snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "helpfulness").exists() {
                        var help = snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "helpfulness").value as? Double ?? 0.0
                        help = help + (Double(self.sHelp ?? "0") ?? 0.0)
                        self.ref.child("Professors").child(self.object?.itemID ?? "").child("ratings").child("helpfulness").setValue(help)
                    } else {
                        self.ref.child("Professors").child(self.object?.itemID ?? "").child("ratings").child("helpfulness").setValue(Double(self.sHelp ?? "0") ?? 0.0)
                    }
                    if snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "difficulty").exists() {
                        var diff = snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "difficulty").value as? Double ?? 0.0
                        diff = diff + (Double(self.sDiff ?? "0") ?? 0.0)
                        self.ref.child("Professors").child(self.object?.itemID ?? "").child("ratings").child("difficulty").setValue(diff)
                    } else {
                        self.ref.child("Professors").child(self.object?.itemID ?? "").child("ratings").child("difficulty").setValue(Double(self.sDiff ?? "0") ?? 0.0)
                    }
                    if snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "lecture").exists() {
                        var lec = snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "lecture").value as? Double ?? 0.0
                        lec = lec + (Double(self.sLec ?? "0") ?? 0.0)
                        self.ref.child("Professors").child(self.object?.itemID ?? "").child("ratings").child("lecture").setValue(lec)
                    } else {
                        self.ref.child("Professors").child(self.object?.itemID ?? "").child("ratings").child("lecture").setValue(Double(self.sLec ?? "0") ?? 0.0)
                    }
                    if !(self.sAtt?.isEmpty ?? true) {
                        var attNumber = Double()
                        if self.sAtt == NSLocalizedString("mandatory", comment: "") {
                            attNumber = 2
                        } else {
                            attNumber = 1
                        }
                        if snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "attendance").exists() {
                            var att = snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "attendance").childSnapshot(forPath: "rating").value as? Double ?? 0.0
                            var num = snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "attendance").childSnapshot(forPath: "times").value as? Int ?? 0
                            num = num + 1
                            att = att + attNumber
                            self.ref.child("Professors").child(self.object?.itemID ?? "").child("ratings").child("attendance").child("rating").setValue(att)
                            self.ref.child("Professors").child(self.object?.itemID ?? "").child("ratings").child("attendance").child("times").setValue(num)
                        } else {
                            self.ref.child("Professors").child(self.object?.itemID ?? "").child("ratings").child("attendance").child("rating").setValue(attNumber)
                            self.ref.child("Professors").child(self.object?.itemID ?? "").child("ratings").child("attendance").child("times").setValue(1)
                        }
                    }
                    if !(self.sTxt?.isEmpty ?? true) {
                        var txtNumber = Double()
                        if self.sTxt == NSLocalizedString("mandatory", comment: "") {
                        txtNumber = 2
                        } else {
                        txtNumber = 1
                        }
                        if snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "textbook").exists() {
                        var txt = snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "textbook").childSnapshot(forPath: "rating").value as? Double ?? 0.0
                        var num = snapshot.childSnapshot(forPath: "ratings").childSnapshot(forPath: "textbook").childSnapshot(forPath: "times").value as? Int ?? 0
                        num = num + 1
                        txt = txt + txtNumber
                        self.ref.child("Professors").child(self.object?.itemID ?? "").child("ratings").child("textbook").child("rating").setValue(txt)
                        self.ref.child("Professors").child(self.object?.itemID ?? "").child("ratings").child("textbook").child("times").setValue(num)
                        }else{
                        self.ref.child("Professors").child(self.object?.itemID ?? "").child("ratings").child("textbook").child("rating").setValue(txtNumber)
                        self.ref.child("Professors").child(self.object?.itemID ?? "").child("ratings").child("textbook").child("times").setValue(1)
                        }
                    }
                    let total = snapshot.childSnapshot(forPath: "ratings_total").childrenCount
                    var ratings = 0.0
                    for  d in snapshot.childSnapshot(forPath: "ratings_total").children {
                        let snap = d as! DataSnapshot
                        ratings = ratings + (snap.value as? Double ?? 0.0)
                    }
                    let finalRating = ratings / Double(total)
                    self.ref.child("Professors").child(self.object?.itemID ?? "").child("avg_rating").setValue(finalRating)
                    self.ref.child("Universities").child(snapshot.childSnapshot(forPath: "uni_name").value as? String ?? "").child("All professors").child(self.object?.itemID ?? "").setValue(finalRating)
                    self.ref.child("Universities").child(snapshot.childSnapshot(forPath: "uni_name").value as? String ?? "").child(snapshot.childSnapshot(forPath: "field_name").value as? String ?? "").child(self.object?.itemID ?? "").setValue(finalRating)
                    self.ref.child("Faculties").child(snapshot.childSnapshot(forPath: "field_name").value as? String ?? "").child(snapshot.childSnapshot(forPath: "city").value as? String ?? "").child(self.object?.itemID ?? "").setValue(finalRating)
                    self.ref.child("Faculties").child(snapshot.childSnapshot(forPath: "field_name").value as? String ?? "").child("All professors").child(self.object?.itemID ?? "").setValue(finalRating)
                    self.ref.child("Cities").child(snapshot.childSnapshot(forPath: "city").value as? String ?? "").child("All professors").child(self.object?.itemID ?? "").setValue(finalRating)
                    self.hud.dismiss(animated: true)
                    self.object?.ratingNum = finalRating
                    self.delegate?.profRated(object: self.object!)
                    _ = self.navigationController?.popViewController(animated: true)
                }
            }
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
        if object?.photo == 1 || String(object?.photo ?? 0) == "1"  {
            self.profImage.image = UIImage.init(named: "teacher_man")
        } else {
            self.profImage.image = UIImage.init(named: "teacher_woman")
        }
    }
    //MARK: Set Views
    @objc fileprivate func setViews() {
        ratingList = ["","1","2","3","4","5"]
        ratingListStr = ["",NSLocalizedString("not_mandatory", comment: ""),NSLocalizedString("mandatory", comment: "")]
        profView.layer.cornerRadius = 8.0
        profView.layer.masksToBounds = true
        profView.layer.borderColor = UIColor(named: "appBlueColor")?.cgColor
        profView.layer.borderWidth = 1.0
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DismissKeyboard))
        view.addGestureRecognizer(tap)
        commentTxt.layer.cornerRadius = 8.0
        commentTxt.layer.masksToBounds = true
        commentTxt.layer.borderColor = UIColor(named: "appBlueColor")?.cgColor
        commentTxt.layer.borderWidth = 1.0
        let font = UIFont.systemFont(ofSize: 14)
        let font2 = UIFont.systemFont(ofSize: 17)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.init(named: "textHintColor") ?? .gray,
        ]
        let attributes2: [NSAttributedString.Key: Any] = [
            .font: font2,
            .foregroundColor: UIColor.init(named: "textColor") ?? .black,
        ]
        let str = NSMutableAttributedString(string: NSLocalizedString("scale", comment: ""), attributes: attributes)
        let str2 = NSMutableAttributedString(string: NSLocalizedString("scale_opposite", comment: ""), attributes: attributes)
        let hs = NSMutableAttributedString(string: NSLocalizedString("helpfulness", comment: ""), attributes: attributes2)
        let ds = NSMutableAttributedString(string: NSLocalizedString("difficulty", comment: ""), attributes: attributes2)
        let ls = NSMutableAttributedString(string: NSLocalizedString("lecture", comment: ""), attributes: attributes2)
        hs.append(str)
        ds.append(str2)
        ls.append(str)
        helpTitle.attributedText = hs
        diffTitle.attributedText = ds
        lecTitle.attributedText = ls
    }
    //MARK: PickerView Extensions
    private func createPickerView() {
        let pickerView = UIPickerView()
        let pickerView2 = UIPickerView()
        let pickerView3 = UIPickerView()
        let pickerView4 = UIPickerView()
        let pickerView5 = UIPickerView()
        pickerView.delegate = self
        pickerView2.delegate = self
        pickerView3.delegate = self
        pickerView4.delegate = self
        pickerView5.delegate = self
        helpPicker.inputView = pickerView
        diffPicker.inputView = pickerView2
        lecPicker.inputView = pickerView3
        attPicker.inputView = pickerView4
        txtPicker.inputView = pickerView5
   }
       
   private func dismissPickerView() {
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let button = UIBarButtonItem(title: NSLocalizedString("done", comment: ""), style: .plain, target: self, action: #selector(self.action))
        toolBar.setItems([button], animated: true)
        toolBar.isUserInteractionEnabled = true
        helpPicker.inputAccessoryView = toolBar
        diffPicker.inputAccessoryView = toolBar
        lecPicker.inputAccessoryView = toolBar
        attPicker.inputAccessoryView = toolBar
        txtPicker.inputAccessoryView = toolBar
   }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if helpPicker.isFirstResponder || diffPicker.isFirstResponder || lecPicker.isFirstResponder {
            return ratingList.count
        }else if attPicker.isFirstResponder || txtPicker.isFirstResponder {
            return ratingListStr.count
        }else {
            return 0
        }
    }
        
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if helpPicker.isFirstResponder || diffPicker.isFirstResponder || lecPicker.isFirstResponder {
            return ratingList[row]
        }else if attPicker.isFirstResponder || txtPicker.isFirstResponder {
            return ratingListStr[row]
        }else {
            return ""
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if helpPicker.isFirstResponder{
            sHelp = ratingList[row]
            helpPicker.text = sHelp
        }else if diffPicker.isFirstResponder{
            sDiff = ratingList[row]
            diffPicker.text = sDiff
        }else if lecPicker.isFirstResponder{
            sLec = ratingList[row]
            lecPicker.text = sLec
        }else if attPicker.isFirstResponder{
            sAtt = ratingListStr[row]
            attPicker.text = sAtt
        }else if txtPicker.isFirstResponder{
            sTxt = ratingListStr[row]
            txtPicker.text = sTxt
        }
    }
    
}
