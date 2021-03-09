//
//  AddFilterVC.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 12..
//

import UIKit
import Firebase
import GoogleMobileAds

class AddFilterVC: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var moreCheck : UInt16?
    var cityName : String?
    var uniName : String?
    var fieldName : String?
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet private weak var filter1Button: UIButton!
    @IBOutlet private weak var filter2Button: UIButton!
    @IBOutlet private weak var filter1Stack: UIStackView!
    @IBOutlet private weak var filter2Stack: UIStackView!
    @IBOutlet private weak var banner: GADBannerView!
    @IBOutlet private weak var typePickerTxt: UITextField!
    private var ref = DatabaseReference()
    private var sUniList = [String]()
    private var sCityList = [String]()
    private var sFieldList = [String]()
    private var pickerList = [String]()
    private var selectedRating : String?
    private var scrollSize = CGFloat()
    weak var delegate: AddedFilterDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        pickerList = ["",NSLocalizedString("high_rating", comment: ""),NSLocalizedString("low_rating", comment: "")]
        typeControl()
        createPickerView()
        dismissPickerView()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        banner.adUnitID = "ca-app-pub-4004348027309516/2307193477"
        banner.rootViewController = self
        banner.load(GADRequest())
    }
    
    //MARK: onClick Actions
    @IBAction func filter1Pressed(_ sender: UIButton) {
        if filter1Stack.isHidden {
            filter1Stack.isHidden = false
            filter1Button.setImage(UIImage.init(named: "arrowDown"), for: .normal)
        } else {
            filter1Stack.isHidden = true
            filter1Button.setImage(UIImage.init(named: "arrowRight"), for: .normal)
        }
    }
    
    @IBAction func filter2Pressed(_ sender: UIButton) {
        if filter2Stack.isHidden {
            filter2Stack.isHidden = false
            filter2Button.setImage(UIImage.init(named: "arrowDown"), for: .normal)
        } else {
            filter2Stack.isHidden = true
            filter2Button.setImage(UIImage.init(named: "arrowRight"), for: .normal)
        }
    }
    
    @IBAction func donePressed(_ sender: UIBarButtonItem) {
        self.delegate?.filterAdded(cList: sCityList, fList: sFieldList, uList: sUniList, sRating: selectedRating ?? "")
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @objc fileprivate func checked(sender: UIButton!) {
        if moreCheck == 1 {
            self.handleUniList(sender: sender)
        } else if moreCheck == 2 {
            self.handleFieldList(sender: sender)
        } else if moreCheck == 31 {
            self.handleUniList(sender: sender)
        } else if moreCheck == 32 {
            self.handleCityList(sender: sender)
        }
    }
    
    @objc fileprivate func checked2(sender: UIButton!) {
        if moreCheck == 1 {
            self.handleFieldList(sender: sender)
        } else if moreCheck == 32 {
            self.handleUniList(sender: sender)
        }
    }
    
    //MARK: Types
    @objc fileprivate func typeControl(){
        if moreCheck == 1 {
            type1()
        } else if moreCheck == 2 {
            type2()
        } else if moreCheck == 31 {
            type31()
        } else if moreCheck == 32 {
            type32()
        }
    }
    //MARK: Type1
    @objc fileprivate func type1(){ //According to City
        filter1Button.isHidden = false
        filter2Button.isHidden = false
        filter1Button.setTitle(NSLocalizedString("universities", comment: ""), for: .normal)
        filter2Button.setTitle(NSLocalizedString("fields", comment: ""), for: .normal)
        sUniList.removeAll()
        sFieldList.removeAll()
        //First CheckBox layout (Uni names)
        self.query1(mRef: ref.child("Cities").child(cityName ?? ""))
        //Second CheckBox layout (Faculty names)
        self.query2(mRef: ref.child("Faculties"), type: self.cityName ?? "")
    }
    //MARK: Type2
    @objc fileprivate func type2(){ //According to University
        filter1Button.isHidden = false
        filter1Button.setTitle(NSLocalizedString("fields", comment: ""), for: .normal)
        //First CheckBox layout (Faculty names)
        self.query1(mRef: ref.child("Universities").child(uniName ?? ""))
    }
    //MARK: Type31
    @objc fileprivate func type31(){ //City based Faculty
        filter1Button.isHidden = false
        filter1Button.setTitle(NSLocalizedString("universities", comment: ""), for: .normal)
        //First CheckBox layout (Uni names)
        ref.child("Cities").child(cityName ?? "").observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            var cList = [String]()
            let limit = snapshot.childrenCount
            var control = 0
            for d in snapshot.children {
                let snap = d as! DataSnapshot
                if snap.key != "All professors" {
                    cList.append(snap.key)
                }
                control += 1
            }
            if control == limit {
                for s in cList {
                    self.ref.child("Universities").child(s).observeSingleEvent(of: .value) { (snapshot2,error2) in
                        if let error = error2 {
                            print("error",error)
                            return
                        }
                        for d1 in snapshot2.children {
                            let snap1 = d1 as! DataSnapshot
                            if snap1.key != "All professors" {
                                if snap1.key == self.fieldName ?? "" {
                                    let name = s
                                    let btn = UIButton(type: .custom)
                                    btn.setTitle(name, for: .normal)
                                    btn.titleLabel?.font = .systemFont(ofSize: 14)
                                    btn.setTitleColor(UIColor.init(named: "textColor"), for: .normal)
                                    btn.setImage(UIImage.init(named: "checkboxEmpty"), for: .normal)
                                    btn.addTarget(self, action: #selector(self.checked), for: .touchUpInside)
                                    self.filter1Stack.addArrangedSubview(btn)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    //MARK: Type32
    @objc fileprivate func type32(){ //Just Faculty based
        filter1Button.isHidden = false
        filter2Button.isHidden = false
        filter1Button.setTitle(NSLocalizedString("cities", comment: ""), for: .normal)
        filter2Button.setTitle(NSLocalizedString("universities", comment: ""), for: .normal)
        //First CheckBox layout (City names)
        self.query1(mRef: ref.child("Faculties").child(fieldName ?? ""))
        //Second CheckBox layout (Uni names)
        self.query2(mRef: ref.child("Universities"), type: self.fieldName ?? "")
    }
    //MARK: Utils
    @objc fileprivate func handleUniList(sender: UIButton!) {
        if sUniList.count == 0 {
            sender.setImage(UIImage.init(named: "checkboxFull"), for: .normal)
            self.sUniList.append(sender.titleLabel?.text ?? "yok")
        } else {
            var control = 0
            var check = false
            for s in sUniList {
                if s == sender.titleLabel?.text {
                    sender.setImage(UIImage.init(named: "checkboxEmpty"), for: .normal)
                    self.sUniList.remove(at: control)
                    check = true
                    break
                }
                control += 1
            }
            if !check {
                sender.setImage(UIImage.init(named: "checkboxFull"), for: .normal)
                self.sUniList.append(sender.titleLabel?.text ?? "yok")
            }
        }
    }
    
    @objc fileprivate func handleCityList(sender: UIButton!) {
        if sCityList.count == 0 {
            sender.setImage(UIImage.init(named: "checkboxFull"), for: .normal)
            self.sCityList.append(sender.titleLabel?.text ?? "yok")
        } else {
            var control = 0
            var check = false
            for s in sCityList {
                if s == sender.titleLabel?.text {
                    sender.setImage(UIImage.init(named: "checkboxEmpty"), for: .normal)
                    self.sCityList.remove(at: control)
                    check = true
                    break
                }
                control += 1
            }
            if !check {
                sender.setImage(UIImage.init(named: "checkboxFull"), for: .normal)
                self.sCityList.append(sender.titleLabel?.text ?? "yok")
            }
        }
    }
    
    @objc fileprivate func handleFieldList(sender: UIButton!) {
        if sFieldList.count == 0 {
            sender.setImage(UIImage.init(named: "checkboxFull"), for: .normal)
            self.sFieldList.append(sender.titleLabel?.text ?? "yok")
        } else {
            var control = 0
            var check = false
            for s in sFieldList {
                if s == sender.titleLabel?.text {
                    sender.setImage(UIImage.init(named: "checkboxEmpty"), for: .normal)
                    self.sFieldList.remove(at: control)
                    check = true
                    break
                }
                control += 1
            }
            if !check {
                sender.setImage(UIImage.init(named: "checkboxFull"), for: .normal)
                self.sFieldList.append(sender.titleLabel?.text ?? "yok")
            }
        }
    }
    
    @objc fileprivate func query1(mRef: DatabaseQuery) {
        mRef.observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            let control = snapshot.childrenCount
            if control > 1 {
                for d in snapshot.children {
                    let snap = d as! DataSnapshot
                    if snap.key != "All professors" {
                        let name = snap.key
                        let btn = UIButton(type: .custom)
                        btn.setTitle(name, for: .normal)
                        btn.titleLabel?.font = .systemFont(ofSize: 14)
                        btn.setTitleColor(UIColor.init(named: "textColor"), for: .normal)
                        btn.setImage(UIImage.init(named: "checkboxEmpty"), for: .normal)
                        btn.addTarget(self, action: #selector(self.checked), for: .touchUpInside)
                        self.filter1Stack.addArrangedSubview(btn)
                    }
                }
            } else {
                self.filter1Stack.isHidden = true
            }
        }
    }
    
    @objc fileprivate func query2(mRef: DatabaseQuery, type: String) {
        mRef.observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            let control = snapshot.childrenCount
            if control > 1 {
                for d in snapshot.children {
                    let snap = d as! DataSnapshot
                    for d1 in snap.children {
                        let snap1 = d1 as! DataSnapshot
                        if snap1.key == type {
                            let name = snap.key
                            let btn = UIButton(type: .custom)
                            btn.setTitle(name, for: .normal)
                            btn.titleLabel?.font = .systemFont(ofSize: 14)
                            btn.setTitleColor(UIColor.init(named: "textColor"), for: .normal)
                            btn.setImage(UIImage.init(named: "checkboxEmpty"), for: .normal)
                            btn.addTarget(self, action: #selector(self.checked2), for: .touchUpInside)
                            self.filter2Stack.addArrangedSubview(btn)
                            break
                        }
                    }
                }
            } else {
                self.filter2Stack.isHidden = true
            }
        }
    }
    //MARK: PickerView
    private func createPickerView() {
       let pickerView = UIPickerView()
       pickerView.delegate = self
       typePickerTxt.inputView = pickerView
   }
       
   private func dismissPickerView() {
       let toolBar = UIToolbar()
       toolBar.sizeToFit()
       let button = UIBarButtonItem(title: NSLocalizedString("done", comment: ""), style: .plain, target: self, action: #selector(self.action))
       toolBar.setItems([button], animated: true)
       toolBar.isUserInteractionEnabled = true
       typePickerTxt.inputAccessoryView = toolBar
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
        selectedRating = pickerList[row]
        typePickerTxt.text = selectedRating
   }
}
