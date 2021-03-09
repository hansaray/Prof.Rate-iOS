//
//  OfferProfVC.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 09..
//

import UIKit
import Firebase
import GoogleMobileAds

class OfferProfVC: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var cityName: UITextField!
    @IBOutlet private weak var uniName: UITextField!
    @IBOutlet private weak var fieldName: UITextField!
    @IBOutlet private weak var profName: UITextField!
    @IBOutlet private weak var banner: GADBannerView!
    private var cityList: [String] = [String]()
    private var uniList: [String] = [String]()
    private var fieldList: [String] = [String]()
    private var uniLimitedList: [String] = [String]()
    private var fieldLimitedList: [String] = [String]()
    private var selectedCity : String?
    private var selectedUni : String?
    private var selectedField : String?
    private let ref = Database.database().reference()
    private var scrollSize = CGFloat()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cityList = [NSLocalizedString("city_name", comment: "")]
        uniList = [NSLocalizedString("uni_name", comment: "")]
        fieldList = [NSLocalizedString("field_name", comment: "")]
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
    
    //MARK: onClick Actions
    @IBAction func donePressed(_ sender: UIBarButtonItem) {
        let profStr = profName.text
        if !(profStr?.isEmpty ?? true) && !(selectedUni?.isEmpty ?? true) && !(selectedField?.isEmpty ?? true) {
            let cTime = Date().currentTimeMillis()
            let offer = ["prof_name" : profStr ?? "", "uni_name" : selectedUni ?? "", "field_name" : selectedField ?? "", "time" : cTime] as [String : Any]
            let key = self.ref.child("profOffer").childByAutoId()
            key.setValue(offer)
            if !(selectedCity?.isEmpty ?? true) {
                key.child("city_name").setValue(selectedCity)
            }
            if Auth.auth().currentUser != nil {
                key.child("userID").setValue(Auth.auth().currentUser?.uid ?? "")
            }
            let when = DispatchTime.now() + 2
            let alertController = UIAlertController(title: NSLocalizedString("successful", comment: ""), message: NSLocalizedString("successful", comment: ""), preferredStyle: .alert)
            self.present(alertController, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: when){
                alertController.dismiss(animated: true, completion: nil)
                _ = self.navigationController?.popViewController(animated: true)
            }
        } else {
            let when = DispatchTime.now() + 2
            let alertController = UIAlertController(title: NSLocalizedString("error", comment: ""), message: NSLocalizedString("empty_form2", comment: ""), preferredStyle: .alert)
            self.present(alertController, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: when){
                alertController.dismiss(animated: true, completion: nil)
            }
        }
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
        scrollView.contentSize = CGSize(width: self.scrollView.frame.size.width, height: (scrollView.frame.size.height + 10))// To be more specific, I have used multiple textfields so wanted to scroll to the end.So have given the constant 300.
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
        pickerView.delegate = self
        pickerView2.delegate = self
        pickerView3.delegate = self
        cityName.inputView = pickerView
        fieldName.inputView = pickerView2
        uniName.inputView = pickerView3
        
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
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if cityName.isFirstResponder{
            return cityList.count
        }else if uniName.isFirstResponder{
            return uniList.count
        }else {
            return fieldList.count
        }
    }
        
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if cityName.isFirstResponder{
            return cityList[row]
        }else if uniName.isFirstResponder{
            return uniList[row]
        }else if fieldName.isFirstResponder{
            return fieldList[row]
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
