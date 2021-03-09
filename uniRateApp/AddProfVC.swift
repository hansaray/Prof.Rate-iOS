//
//  AddProfVC.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 11. 24..
//

import UIKit
import GoogleMobileAds
import Firebase
import JGProgressHUD

class AddProfVC: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet private weak var cityName: UITextField!
    @IBOutlet private weak var uniName: UITextField!
    @IBOutlet private weak var fieldName: UITextField!
    @IBOutlet private weak var gender: UITextField!
    @IBOutlet private weak var profTitle: UITextField!
    @IBOutlet private weak var profName: UITextField!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var banner: GADBannerView!
    private var cityList: [String] = [String]()
    private var uniList: [String] = [String]()
    private var fieldList: [String] = [String]()
    private var genderList: [String] = [String]()
    private var titleList: [String] = [String]()
    private var uniLimitedList: [String] = [String]()
    private var fieldLimitedList: [String] = [String]()
    private var selectedCity : String?
    private var selectedUni : String?
    private var selectedField : String?
    private var selectedTitle : String?
    private var selectedGender : Int?
    private let ref = Database.database().reference()
    private var scrollSize = CGFloat()
    private var searchItem : SearchItem?
    override func viewDidLoad() {
        super.viewDidLoad()
        cityList = [NSLocalizedString("city_name", comment: "")]
        uniList = [NSLocalizedString("uni_name", comment: "")]
        fieldList = [NSLocalizedString("field_name", comment: "")]
        genderList = [" ",NSLocalizedString("male", comment: ""),NSLocalizedString("female", comment: "")]
        titleList = [" ",NSLocalizedString("p_title_1", comment: ""),NSLocalizedString("p_title_2", comment: ""),NSLocalizedString("p_title_3", comment: ""),NSLocalizedString("p_title_4", comment: ""),NSLocalizedString("p_title_5", comment: ""),NSLocalizedString("p_title_6", comment: ""),NSLocalizedString("p_title_7", comment: ""),NSLocalizedString("p_title_8", comment: ""),NSLocalizedString("p_title_9", comment: ""),NSLocalizedString("p_title_10", comment: ""),NSLocalizedString("p_title_11", comment: ""),NSLocalizedString("p_title_12", comment: ""),NSLocalizedString("p_title_13", comment: "")]
        setTxtFieldBorders()
        createPickerView()
        dismissPickerView()
        setSpinners()
        scrollSize = scrollView.frame.size.height
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        banner.adUnitID = "ca-app-pub-4004348027309516/9400049582"
        banner.rootViewController = self
        banner.load(GADRequest())
    }
    
    @IBAction func donePressed(_ sender: UIBarButtonItem) {
        let hud = JGProgressHUD(style : .light)
        hud.textLabel.text = NSLocalizedString("saving", comment: "")
        hud.show(in: self.view)
        if Auth.auth().currentUser != nil {
            var prof_name = ""
            var check = false
            if !(profName.text?.isEmpty ?? true) {
                prof_name = self.fixName(name: profName.text ?? "")
                if prof_name == "wrong" {
                    prof_name = "";
                    check = true
                    hud.dismiss(animated: true)
                    let alertController = UIAlertController(title: NSLocalizedString("error", comment: ""), message: NSLocalizedString("add_prof_space", comment: ""), preferredStyle: .alert)
                    self.present(alertController, animated: true, completion: nil)
                    let when = DispatchTime.now() + 1
                    DispatchQueue.main.asyncAfter(deadline: when){
                        alertController.dismiss(animated: true, completion: nil)
                    }
                } else {
                    profName.text = ""
                    profName.placeholder = prof_name
                }
            }
            if !prof_name.isEmpty && !(selectedCity?.isEmpty ?? true) && !(selectedUni?.isEmpty ?? true) && !(selectedField?.isEmpty ?? true) && !(selectedTitle?.isEmpty ?? true) && selectedGender != 0 && !check {
                self.ref.child("Universities").child(selectedUni ?? "").child(selectedField ?? "").observeSingleEvent(of: .value) { (snapshot,error) in
                    if let error = error {
                        hud.dismiss(animated: true)
                        print("error",error)
                        return
                    }
                    self.ref.child("Professors").observeSingleEvent(of: .value) { (snapshot2,error2) in
                        if let error = error2 {
                            hud.dismiss(animated: true)
                            print("error",error)
                            return
                        }
                        var tCheck = false
                        for d in snapshot.children {
                            let snap = d as! DataSnapshot
                            if snapshot2.childSnapshot(forPath: snap.key).exists() {
                                if (snapshot2.childSnapshot(forPath: snap.key).childSnapshot(forPath: "prof_name").value as? String ?? "").lowercased().elementsEqual(prof_name.lowercased()) && (snapshot2.childSnapshot(forPath: snap.key).childSnapshot(forPath: "photo").value as? Int ?? 0) == self.selectedGender ?? 0 {
                                    tCheck = true
                                    print("deneme stop")
                                    break
                                }
                            }
                        }
                        if !tCheck {
                            let map = ["avg_rating" : 0.0, "city" : self.selectedCity ?? "", "field_name" : self.selectedField ?? "", "prof_name" : prof_name, "uni_name" : self.selectedUni ?? "", "photo" : self.selectedGender ?? 0, "title" : self.selectedTitle ?? ""] as [String : Any]
                            let key = self.ref.child("Professors").childByAutoId()
                            key.setValue(map)
                            let keyStr = key.key ?? ""
                            self.ref.child("Universities").child(self.selectedUni ?? "").child("All professors").child(keyStr).setValue(0.0);
                            self.ref.child("Universities").child(self.selectedUni ?? "").child(self.selectedField ?? "").child(keyStr).setValue(0.0);
                            self.ref.child("Faculties").child(self.selectedField ?? "").child("All professors").child(keyStr).setValue(0.0);
                            self.ref.child("Faculties").child(self.selectedField ?? "").child(self.selectedCity ?? "").child(keyStr).setValue(0.0);
                            self.ref.child("Cities").child(self.selectedCity ?? "").child("All professors").child(keyStr).setValue(0.0);
                            self.ref.child("addedProf").child(keyStr).setValue(true) { (error, snapshot) in
                                hud.dismiss(animated: true)
                                if error != nil {
                                    let alertController = UIAlertController(title: NSLocalizedString("error", comment: ""), message: error?.localizedDescription, preferredStyle: .alert)
                                    self.present(alertController, animated: true, completion: nil)
                                    let when = DispatchTime.now() + 1
                                    DispatchQueue.main.asyncAfter(deadline: when){
                                        alertController.dismiss(animated: true, completion: nil)
                                    }
                                } else {
                                    let cityUniName = (self.selectedCity ?? "")+","+(self.selectedUni ?? "")
                                    let sItem = ["cityUniName" : cityUniName, "fieldName" : self.selectedField ?? "", "profName" : prof_name, "photoNum" : self.selectedGender ?? 0, "itemID" : keyStr, "ratingNum" : 0.0] as [String : Any]
                                    self.searchItem = SearchItem(searchData: sItem as [String : Any])
                                    self.searchItem?.title = self.selectedTitle ?? ""
                                    let alertController = UIAlertController(title: NSLocalizedString("successful", comment: ""), message: NSLocalizedString("saved", comment: ""), preferredStyle: .alert)
                                    self.present(alertController, animated: true, completion: nil)
                                    let when = DispatchTime.now() + 1
                                    DispatchQueue.main.asyncAfter(deadline: when){
                                        alertController.dismiss(animated: true, completion: nil)
                                      //  _ = self.navigationController?.popViewController(animated: true) //finish activity
                                        self.performSegue(withIdentifier: "addProfToRateSegue", sender: self)//perform segue
                                    }
                                }
                            }
                        }else{
                            hud.dismiss(animated: true)
                            let alertController = UIAlertController(title: NSLocalizedString("error", comment: ""), message: NSLocalizedString("add_info3", comment: ""), preferredStyle: .alert)
                            self.present(alertController, animated: true, completion: nil)
                            let when = DispatchTime.now() + 1
                            DispatchQueue.main.asyncAfter(deadline: when){
                                alertController.dismiss(animated: true, completion: nil)
                            }
                        }
                    }
                }
            } else {
                if !check {
                    hud.dismiss(animated: true)
                    let alertController = UIAlertController(title: NSLocalizedString("error", comment: ""), message: NSLocalizedString("empty_form2", comment: ""), preferredStyle: .alert)
                    self.present(alertController, animated: true, completion: nil)
                    let when = DispatchTime.now() + 1
                    DispatchQueue.main.asyncAfter(deadline: when){
                        alertController.dismiss(animated: true, completion: nil)
                    }
                }
            }
        } else {
            hud.dismiss(animated: true)
            let alertController = UIAlertController(title: NSLocalizedString("info", comment: ""), message: NSLocalizedString("add_info2", comment: ""), preferredStyle: .alert)
            self.present(alertController, animated: true, completion: nil)
            let when = DispatchTime.now() + 1
            DispatchQueue.main.asyncAfter(deadline: when){
                alertController.dismiss(animated: true, completion: nil)
            }
        }
    }
    //MARK: Utils
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addProfToRateSegue" {
            let vc = segue.destination as? RateVC
            vc?.object = self.searchItem
        }
    }
    
    private func fixName(name: String) -> String {
        let s = name.lowercased()
        if s.starts(with: " "){
            return "wrong"
        } else {
            let characters = Array(s)
            var spaceCount = 0
            var cs : Character = "%"
            for c in characters {
                if c == " " {
                    spaceCount += 1
                }
                if cs != "%" {
                    if c == cs {
                        return "wrong"
                    }
                }
                cs = c
            }
            if spaceCount >= 8 {
                return "wrong"
            }
        }
        let substrings = s.components(separatedBy: " ")
        var last = String()
        for s1 in substrings {
            var s2 = String()
            if s1.starts(with: "i") || s1.starts(with: "İ") {
                s2 = " " + s1.capitalized(with: Locale(identifier: "tr"))
            } else {
                s2 = " " + s1.capitalized
            }
            last.append(s2)
        }
        return last.trimmingCharacters(in: .whitespaces)
    }
    
    @objc private func DismissKeyboard(){
        view.endEditing(true)
    }
    
    @objc private func action() {
          view.endEditing(true)
    }
    //MARK: Scrollview setup
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.contentSize = CGSize(width: self.scrollView.frame.size.width, height: (scrollView.frame.size.height + 10))
    }

    func textFieldDidBeginEditing(_ textField:UITextField) {
        if textField.tag == 3 {
            self.scrollView.setContentOffset(textField.frame.origin, animated: true)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.scrollView.setContentOffset(.zero, animated: true)
        self.scrollView.contentSize = CGSize(width: self.scrollView.frame.size.width, height: (scrollSize))
    }
    //MARK: Spinner and View Setup
    @objc fileprivate func setSpinners(){
        ref.child("Cities").observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            snapshot.children.forEach { (child) in
                let snap = child as! DataSnapshot
                self.cityList.append(self.nameFix(name: snap.key))
            }
            
        }
        ref.child("Universities").observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            snapshot.children.forEach { (child) in
                let snap = child as! DataSnapshot
                self.uniList.append(snap.key)
            }
            
        }
        ref.child("Faculties").observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            snapshot.children.forEach { (child) in
                let snap = child as! DataSnapshot
                self.fieldList.append(snap.key)
            }
        }
    }
    
    @objc fileprivate func setTxtFieldBorders() {
        cityName.delegate = self
        cityName.tintColor = .white
        cityName.layer.cornerRadius = 8.0
        cityName.layer.masksToBounds = true
        cityName.layer.borderColor = UIColor(named: "appBlueColor")?.cgColor
        cityName.layer.borderWidth = 1.0
        
        uniName.delegate = self
        uniName.tintColor = .white
        uniName.layer.cornerRadius = 8.0
        uniName.layer.masksToBounds = true
        uniName.layer.borderColor = UIColor(named: "appBlueColor")?.cgColor
        uniName.layer.borderWidth = 1.0
        
        fieldName.delegate = self
        fieldName.tintColor = .white
        fieldName.layer.cornerRadius = 8.0
        fieldName.layer.masksToBounds = true
        fieldName.layer.borderColor = UIColor(named: "appBlueColor")?.cgColor
        fieldName.layer.borderWidth = 1.0
        
        gender.delegate = self
        gender.tintColor = .white
        gender.layer.cornerRadius = 8.0
        gender.layer.masksToBounds = true
        gender.layer.borderColor = UIColor(named: "appBlueColor")?.cgColor
        gender.layer.borderWidth = 1.0
        
        profTitle.delegate = self
        profTitle.tintColor = .white
        profTitle.layer.cornerRadius = 8.0
        profTitle.layer.masksToBounds = true
        profTitle.layer.borderColor = UIColor(named: "appBlueColor")?.cgColor
        profTitle.layer.borderWidth = 1.0
        
        profName.delegate = self
        profName.tag = 3
        profName.layer.cornerRadius = 8.0
        profName.layer.masksToBounds = true
        profName.layer.borderColor = UIColor(named: "appBlueColor")?.cgColor
        profName.layer.borderWidth = 1.0
    }
    //MARK: PickerView Setup
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
        cityName.inputView = pickerView
        fieldName.inputView = pickerView2
        uniName.inputView = pickerView3
        gender.inputView = pickerView4
        profTitle.inputView = pickerView5
    }
        
    private func dismissPickerView() {
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let button = UIBarButtonItem(title: NSLocalizedString("done", comment: ""), style: .plain, target: self, action: #selector(self.action))
        toolBar.setItems([button], animated: true)
        toolBar.isUserInteractionEnabled = true
        cityName.inputAccessoryView = toolBar
        uniName.inputAccessoryView = toolBar
        fieldName.inputAccessoryView = toolBar
        gender.inputAccessoryView = toolBar
        profTitle.inputAccessoryView = toolBar
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if cityName.isFirstResponder{
            return cityList.count
        }else if uniName.isFirstResponder{
            return uniList.count
        }else if fieldName.isFirstResponder{
            return fieldList.count
        }else if gender.isFirstResponder{
            return genderList.count
        }else{
            return titleList.count
        }
    }
        
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if cityName.isFirstResponder{
            return cityList[row]
        }else if uniName.isFirstResponder{
            return uniList[row]
        }else if fieldName.isFirstResponder{
            return fieldList[row]
        }else if gender.isFirstResponder{
            return genderList[row]
        }else if profTitle.isFirstResponder{
            return titleList[row]
        }else {
            return ""
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if cityName.isFirstResponder{
            selectedCity = cityList[row]
            cityName.text = selectedCity
            selectedUni = ""
            uniName.text = selectedUni
            selectedField = ""
            fieldName.text = selectedField
            if selectedCity?.isEmpty ?? true || selectedCity?.elementsEqual(NSLocalizedString("city_name", comment: "")) ?? false {
                //uni, field selection = 0
                selectedCity = ""
                cityName.text = selectedCity
                if !uniLimitedList.isEmpty {
                    uniList.removeAll()
                    uniList.append(contentsOf: uniLimitedList)
                }
            }else {
                setUniLimitedList(city: selectedCity ?? "")
            }
        }else if uniName.isFirstResponder{
            selectedUni = uniList[row]
            uniName.text = selectedUni
            selectedField = ""
            fieldName.text = selectedField
            if selectedUni?.isEmpty ?? true || selectedUni?.elementsEqual(NSLocalizedString("uni_name", comment: "")) ?? false {
                //field selection = 0
                selectedUni = ""
                uniName.text = selectedUni
                if !fieldLimitedList.isEmpty {
                    fieldList.removeAll()
                    fieldList.append(contentsOf: fieldLimitedList)
                }
            }else {
                setFieldLimitedList(uni: selectedUni ?? "")
            }
        }else if fieldName.isFirstResponder{
            selectedField = fieldList[row]
            fieldName.text = selectedField
            if selectedField?.isEmpty ?? true || selectedField?.elementsEqual(NSLocalizedString("field_name", comment: "")) ?? false {
                selectedField = ""
                fieldName.text = selectedField
            }
        }else if gender.isFirstResponder{
            var sGender = genderList[row]
            if sGender == NSLocalizedString("male", comment: "") {
                selectedGender = 1
            } else if sGender == NSLocalizedString("female", comment: "") {
                selectedGender = 2
            } else {
                selectedGender = 0
            }
            gender.text = sGender
            if selectedGender == 0 {
                sGender = ""
                gender.text = sGender
            }
        }else if profTitle.isFirstResponder{
            selectedTitle = titleList[row]
            profTitle.text = selectedTitle
            if selectedTitle?.isEmpty ?? true || selectedTitle?.elementsEqual(" ") ?? false {
                selectedTitle = ""
                profTitle.text = selectedTitle
            }
        }
    }
    //MARK: UniLimited List
    @objc fileprivate func setUniLimitedList(city : String) {
        let n_city = nameFix(name: city)
        if uniLimitedList.isEmpty {
            uniLimitedList.append(contentsOf: uniList)
        }
        uniList.removeAll()
        uniList = [NSLocalizedString("uni_name", comment: "")]
        ref.child("Cities").child(n_city).observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            snapshot.children.forEach { (child) in
                let snap = child as! DataSnapshot
                if !snap.key.elementsEqual("All professors") {
                    self.uniList.append(snap.key)
                }
            }
            
        }
    }
    //MARK: FieldLimited List
    @objc fileprivate func setFieldLimitedList(uni : String) {
        if fieldLimitedList.isEmpty {
            fieldLimitedList.append(contentsOf: fieldList)
        }
        fieldList.removeAll()
        fieldList = [NSLocalizedString("field_name", comment: "")]
        ref.child("Universities").child(uni).observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            snapshot.children.forEach { (child) in
                let snap = child as! DataSnapshot
                if !snap.key.elementsEqual("All professors") {
                    self.fieldList.append(snap.key)
                }
            }
            
        }
    }
    //MARK: NameFix
    private func nameFix(name : String) -> String {
        switch (name) {
            case "Canakkale":
                return "Çanakkale";
            case "Çanakkale":
                return "Canakkale";
            case "Cankırı":
                return "Çankırı";
            case "Çankırı":
                return "Cankırı";
            case "Corum":
                return "Çorum";
            case "Çorum":
                return "Corum";
            case "Istanbul":
                return "İstanbul";
            case "İstanbul":
                return "Istanbul";
            case "Izmir":
                return "İzmir";
            case "İzmir":
                return "Izmir";
            case "Sanlıurfa":
                return "Şanlıurfa";
            case "Şanlıurfa":
                return "Sanlıurfa";
            case "Sırnak":
                return "Şırnak";
            case "Şırnak":
                return "Sırnak";
            default:
                return name;
           }
    }
}
