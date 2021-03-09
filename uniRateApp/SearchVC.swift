//
//  SearchVC.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 12..
//

import UIKit
import Firebase
import GoogleMobileAds

protocol AddedFilterDelegate: AnyObject
{
    func filterAdded(cList: [String], fList: [String], uList: [String], sRating: String)
}

class SearchVC: UIViewController {
    
    private var searchList = [SearchItem]()
    private var selectedItem : SearchItem?
    var cityName : String?
    var uniName : String?
    var fieldName : String?
    var profName : String?
    @IBOutlet private weak var filterButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var banner: GADBannerView!
    @IBOutlet private weak var addProf: UIButton!
    @IBOutlet weak var emptyView: UIView!
    private var ids = [String]()
    var fUniList = [String]()
    var fCityList = [String]()
    var fFieldList = [String]()
    private let cellID = "searchCell"
    private var ref = DatabaseReference()
    private var moreCheck : UInt16 = 0
    private var num : Int = 0
    private var lastPage = false, checkCity = false, checkUni = false, checkField = false, checkProf = false
    var fCheck = false
    private var numOfItems = 20
    var selectedRating = ""
    var loadingData = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        if fCheck {
            loadFilteredResults()
        } else {
            loadData()
        }
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        banner.adUnitID = "ca-app-pub-4004348027309516/6450452610"
        banner.rootViewController = self
        banner.load(GADRequest())
    }
    
    @IBAction func emptyPressed(_ sender: UIButton) {
        print("deneme pressed")
        self.performSegue(withIdentifier: "searchToAddProfSegue", sender: self)
    }
    
    @objc fileprivate func clearFilterPressed() {
        numOfItems = 20
        fCheck = false
        selectedRating = ""
        lastPage = false
        searchList.removeAll()
        self.addProf.fadeOut(1) //isHidden = true
        self.navigationItem.rightBarButtonItem = nil
        loadData()
    }
    //MARK: Number of items Check
    @objc fileprivate func numCheck() {
        if moreCheck == 1 {
            ref.child("Cities").child(cityName ?? "").child("All professors").observeSingleEvent(of: .value) { (snapshot,error) in
                if let error = error {
                    print("error",error)
                    return
                }
                self.num = Int(snapshot.childrenCount)
            }
        } else if moreCheck == 2 {
            ref.child("Universities").child(uniName ?? "").child("All professors").observeSingleEvent(of: .value) { (snapshot,error) in
                if let error = error {
                    print("error",error)
                    return
                }
                self.num = Int(snapshot.childrenCount)
            }
        } else if moreCheck == 3 {
            ref.child("Universities").child(uniName ?? "").child(fieldName ?? "").observeSingleEvent(of: .value) { (snapshot,error) in
                if let error = error {
                    print("error",error)
                    return
                }
                self.num = Int(snapshot.childrenCount)
            }
        } else if moreCheck == 31 {
            ref.child("Faculties").child(fieldName ?? "").child(cityName ?? "").observeSingleEvent(of: .value) { (snapshot,error) in
                if let error = error {
                    print("error",error)
                    return
                }
                self.num = Int(snapshot.childrenCount)
            }
        } else if moreCheck == 32 {
            ref.child("Faculties").child(fieldName ?? "").child("All professors").observeSingleEvent(of: .value) { (snapshot,error) in
                if let error = error {
                    print("error",error)
                    return
                }
                self.num = Int(snapshot.childrenCount)
            }
        }
    }
    //MARK: Load Data
    @objc fileprivate func loadData() {
        self.addProf.fadeOut(1) //isHidden = true
        var spinner = UIActivityIndicatorView()
        if #available(iOS 13.0, *) {
            spinner = UIActivityIndicatorView(style: .large)
        } else {
            spinner = UIActivityIndicatorView(style: .gray)
        }
        spinner.color = UIColor.init(named: "appBlueColor")
        spinner.startAnimating()
        tableView.backgroundView = spinner
        if !(cityName?.isEmpty ?? true) {
            checkCity = true
        }
        if !(uniName?.isEmpty ?? true) {
            checkUni = true
        }
        if !(fieldName?.isEmpty ?? true) {
            checkField = true
        }
        if !(profName?.isEmpty ?? true) {
            checkProf = true
        }
        
        if checkCity && !checkUni && !checkField && !checkProf { //According to City(C---)
            moreCheck = 1
            self.firstQuery(mRef: ref.child("Cities").child(cityName ?? "").child("All professors").queryOrderedByValue().queryLimited(toLast: UInt(numOfItems)))
        } else if (checkCity && checkUni && !checkField && !checkProf) || (!checkCity && checkUni && !checkField && !checkProf) { //According to University (CU--,-U--)
            moreCheck = 2
            self.firstQuery(mRef: ref.child("Universities").child(uniName ?? "").child("All professors").queryOrderedByValue().queryLimited(toLast: UInt(numOfItems)))
        } else if (checkCity && checkUni && checkField && !checkProf) || (!checkCity && checkUni && checkField && !checkProf) || (checkCity && !checkUni && checkField && !checkProf) || (!checkCity && !checkUni && checkField && !checkProf) { //According to Faculty (CUF-,-UF-,C-F-,--F-)
            if (checkCity && checkUni) || (!checkCity && checkUni) { //University based Faculty (CUF-,-UF-)
                moreCheck = 3
                self.firstQuery(mRef: ref.child("Universities").child(uniName ?? "").child(fieldName ?? "").queryOrderedByValue().queryLimited(toLast: UInt(numOfItems)))
            } else if checkCity { //City based Faculty (C-F-)
                moreCheck = 31
                self.firstQuery(mRef: ref.child("Faculties").child(fieldName ?? "").child(cityName ?? "").queryOrderedByValue().queryLimited(toLast: UInt(numOfItems)))
            } else { //Just Faculty based (--F-)
                moreCheck = 32
                self.firstQuery(mRef: ref.child("Faculties").child(fieldName ?? "").child("All professors").queryOrderedByValue().queryLimited(toLast: UInt(numOfItems)))
            }
        } else { //According to Professor
            moreCheck = 4
            ref.child("Professors").observeSingleEvent(of: .value) { (snapshot,error) in
                if let error = error {
                    print("error",error)
                    return
                }
                for d in snapshot.children {
                    let snap = d as! DataSnapshot
                    if (snap.childSnapshot(forPath: "prof_name").value as? String ?? "").lowercased().contains((self.profName ?? "").lowercased()) || (snap.childSnapshot(forPath: "prof_name").value as? String ?? "").lowercased() == (self.profName ?? "").lowercased() {
                        if !self.checkCity && !self.checkUni && !self.checkField {
                            let cityUniName = (snap.childSnapshot(forPath: "city").value as? String ?? "")+","+(snap.childSnapshot(forPath: "uni_name").value as? String ?? "")
                            let sItem = ["cityUniName" : cityUniName, "fieldName" : snap.childSnapshot(forPath: "field_name").value as? String ?? "", "profName" : snap.childSnapshot(forPath: "prof_name").value as? String ?? "", "photoNum" : snap.childSnapshot(forPath: "photo").value as? Int ?? 0, "itemID" : snap.key, "ratingNum" : snap.childSnapshot(forPath: "avg_rating").value as? Double ?? 0.0] as [String : Any]
                            var searchItem = SearchItem(searchData: sItem as [String : Any])
                            if snap.childSnapshot(forPath: "title").exists() {
                                searchItem.title = snap.childSnapshot(forPath: "title").value as? String ?? ""
                            }
                            self.searchList.append(searchItem)
                            self.sort(type: false)
                            DispatchQueue.main.async {
                                self.tableView.backgroundView = nil
                                self.tableView.reloadData()
                                self.tableView.tableFooterView = nil
                                self.loadingData = false
                            }
                        } else {
                            var control = 0
                            if self.checkCity {
                                if self.cityName == (snap.childSnapshot(forPath: "city").value as? String ?? "") {
                                    control = 1;
                                }
                            }
                            if self.checkUni {
                                if self.uniName == (snap.childSnapshot(forPath: "uni_name").value as? String ?? "") {
                                    control = 1;
                                }else{
                                    control = 0;
                                }
                            }
                            if self.checkField {
                                if self.fieldName == (snap.childSnapshot(forPath: "field_name").value as? String ?? "") {
                                    control = 1;
                                }else{
                                    control = 0;
                                }
                            }
                            if control==1 {
                                let cityUniName = (snap.childSnapshot(forPath: "city").value as? String ?? "")+","+(snap.childSnapshot(forPath: "uni_name").value as? String ?? "")
                                let sItem = ["cityUniName" : cityUniName, "fieldName" : snap.childSnapshot(forPath: "field_name").value as? String ?? "", "profName" : snap.childSnapshot(forPath: "prof_name").value as? String ?? "", "photoNum" : snap.childSnapshot(forPath: "photo").value as? Int ?? 0, "itemID" : snap.key, "ratingNum" : snap.childSnapshot(forPath: "avg_rating").value as? Double ?? 0.0] as [String : Any]
                                var searchItem = SearchItem(searchData: sItem as [String : Any])
                                if snap.childSnapshot(forPath: "title").exists() {
                                    searchItem.title = snap.childSnapshot(forPath: "title").value as? String ?? ""
                                }
                                self.searchList.append(searchItem)
                                self.sort(type: false)
                                DispatchQueue.main.async {
                                    self.tableView.backgroundView = nil
                                    self.tableView.reloadData()
                                    self.tableView.tableFooterView = nil
                                    self.loadingData = false
                                }
                            }
                        }
                    }
                }
                if self.searchList.isEmpty {
                    self.setEmptyView()
                } else if self.searchList.count < self.numOfItems {
                    self.addProf.fadeIn(1) //isHidden = false
                }
            }
        }
        if moreCheck != 4 {
            numCheck()
        }
    }
    //MARK: Load More
    @objc fileprivate func loadMore() {
        ref.removeAllObservers()
        let number = searchList.count
        let startKey = searchList[number-1].itemID
        if moreCheck == 1 { //According to City
            self.secondQuery(mRef: ref.child("Cities").child(cityName ?? "").child("All professors").queryOrderedByValue().queryEnding(atValue: startKey).queryLimited(toLast: UInt(numOfItems)), number: number)
        } else if moreCheck == 2 { //According to University
            self.secondQuery(mRef: ref.child("Universities").child(uniName ?? "").child("All professors").queryOrderedByValue().queryEnding(atValue: startKey).queryLimited(toLast: UInt(numOfItems)), number: searchList.count)
        } else if moreCheck == 3 { //According to Faculty (UniBased)
            self.secondQuery(mRef: ref.child("Universities").child(uniName ?? "").child(fieldName ?? "").queryOrderedByValue().queryEnding(atValue: startKey).queryLimited(toLast: UInt(numOfItems)), number: number)
        } else if moreCheck == 31 { //According to Faculty (CityBased)
            self.secondQuery(mRef: ref.child("Faculties").child(fieldName ?? "").child(cityName ?? "").queryOrderedByValue().queryEnding(atValue: startKey).queryLimited(toLast: UInt(numOfItems)), number: number)
        } else if moreCheck == 32 { //According to Faculty (JustFaculty)
            self.secondQuery(mRef: ref.child("Faculties").child(fieldName ?? "").child("All professors").queryOrderedByValue().queryEnding(atValue: startKey).queryLimited(toLast: UInt(numOfItems)), number: number)
        }
    }
    //MARK: Load Filtered Results
    @objc fileprivate func loadFilteredResults() {
        var spinner = UIActivityIndicatorView()
        if #available(iOS 13.0, *) {
            spinner = UIActivityIndicatorView(style: .large)
        } else {
            spinner = UIActivityIndicatorView(style: .gray)
        }
        spinner.color = UIColor.init(named: "appBlueColor")
        spinner.startAnimating()
        tableView.backgroundView = spinner
        self.addProf.isHidden = true
        if moreCheck == 1 {
            if !fUniList.isEmpty && !fFieldList.isEmpty {
                self.searchList.removeAll()
                self.tableView.reloadData()
                for s in fUniList {
                    self.ref.child("Universities").child(s).observeSingleEvent(of: .value) { (snapshot,error) in
                        if let error = error {
                            print("error",error)
                            return
                        }
                        let num = snapshot.childrenCount
                        if num < 2 {
                            self.setEmptyView()
                        } else if num < self.numOfItems {
                            if self.addProf.isHidden {
                                self.addProf.fadeIn(1) //isHidden = false
                            }
                        }
                        for d in snapshot.children {
                            let snap = d as! DataSnapshot
                            if snap.key != "All professors" {
                                for s1 in self.fFieldList {
                                    if snap.key == s1 {
                                        for d1 in snap.children {
                                            let snap1 = d1 as! DataSnapshot
                                            if !(snap1.key == "aaaaa") {
                                                self.addProfessor(profID: snap1.key)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else if !fUniList.isEmpty {
                self.searchList.removeAll()
                self.tableView.reloadData()
                for s in fUniList {
                    self.ref.child("Universities").child(s).child("All professors").observeSingleEvent(of: .value) { (snapshot,error) in
                        if let error = error {
                            print("error",error)
                            return
                        }
                        let num = snapshot.childrenCount
                        if num < 2 {
                            self.setEmptyView()
                        } else if num < self.numOfItems {
                            if self.addProf.isHidden {
                                self.addProf.fadeIn(1) //isHidden = false
                            }
                        }
                        for d in snapshot.children {
                            let snap = d as! DataSnapshot
                            if !(snap.key == "aaaaa") {
                                self.addProfessor(profID: snap.key)
                            }
                        }
                    }
                }
            } else if !fFieldList.isEmpty {
                self.searchList.removeAll()
                self.tableView.reloadData()
                for s in fFieldList {
                    self.ref.child("Faculties").child(s).child(cityName ?? "").observeSingleEvent(of: .value) { (snapshot,error) in
                        if let error = error {
                            print("error",error)
                            return
                        }
                        let num = snapshot.childrenCount
                        if num < 2 {
                            self.setEmptyView()
                        } else if num < self.numOfItems {
                            if self.addProf.isHidden {
                                self.addProf.fadeIn(1) //isHidden = false
                            }
                        }
                        for d in snapshot.children {
                            let snap = d as! DataSnapshot
                            self.addProfessor(profID: snap.key)
                        }
                    }
                }
            } else {
                self.selectedRatingControl(mRef: self.ref.child("Cities").child(cityName ?? "").child("All professors").queryOrderedByValue().queryLimited(toFirst: UInt(numOfItems)))
            }
        } else if moreCheck == 2 {
            if !fFieldList.isEmpty {
                self.searchList.removeAll()
                self.tableView.reloadData()
                for s in fFieldList {
                    self.ref.child("Universities").child(uniName ?? "").child(s).observeSingleEvent(of: .value) { (snapshot,error) in
                        if let error = error {
                            print("error",error)
                            return
                        }
                        let num = snapshot.childrenCount
                        if num < 2 {
                            self.setEmptyView()
                        } else if num < self.numOfItems {
                            if self.addProf.isHidden {
                                self.addProf.fadeIn(1) //isHidden = false
                            }
                        }
                        for d in snapshot.children {
                            let snap = d as! DataSnapshot
                            if !(snap.key == "aaaaa") {
                                self.addProfessor(profID: snap.key)
                            }
                        }
                    }
                }
            } else {
                self.selectedRatingControl(mRef: self.ref.child("Universities").child(uniName ?? "").child("All professors").queryOrderedByValue().queryLimited(toFirst: UInt(numOfItems)))
            }
        } else if moreCheck == 3 {
            fCheck = false
            lastPage = false
            numOfItems = 20
            self.ref.child("Universities").child(uniName ?? "").child(fieldName ?? "").queryOrderedByValue().queryLimited(toFirst: UInt(numOfItems)).observeSingleEvent(of: .value) { (snapshot,error) in
                if let error = error {
                    print("error",error)
                    return
                }
                let num = snapshot.childrenCount
                if num < 2 {
                    self.setEmptyView()
                } else if num < self.numOfItems {
                    if self.addProf.isHidden {
                        self.addProf.fadeIn(1) //isHidden = false
                    }
                }
                self.searchList.removeAll()
                self.tableView.reloadData()
                for d in snapshot.children {
                    let snap = d as! DataSnapshot
                    if !(snap.key == "aaaaa") {
                        self.addProfessor(profID: snap.key)
                    }
                }
            }
        } else if moreCheck == 31 {
            if !fUniList.isEmpty {
                self.searchList.removeAll()
                self.tableView.reloadData()
                for s in fUniList {
                    self.ref.child("Universities").child(s).child(fieldName ?? "").observeSingleEvent(of: .value) { (snapshot,error) in
                        if let error = error {
                            print("error",error)
                            return
                        }
                        let num = snapshot.childrenCount
                        if num < 2 {
                            self.setEmptyView()
                        } else if num < self.numOfItems {
                            if self.addProf.isHidden {
                                self.addProf.fadeIn(1) //isHidden = false
                            }
                        }
                        for d in snapshot.children {
                            let snap = d as! DataSnapshot
                            if !(snap.key == "aaaaa") {
                                self.addProfessor(profID: snap.key)
                            }
                        }
                    }
                }
            } else {
                self.selectedRatingControl(mRef: self.ref.child("Faculties").child(fieldName ?? "").child(cityName ?? "").queryOrderedByValue().queryLimited(toFirst: UInt(numOfItems)))
            }
        } else if moreCheck == 32 {
            if !fCityList.isEmpty {
                self.searchList.removeAll()
                self.tableView.reloadData()
                for s in fCityList {
                    self.ref.child("Faculties").child(fieldName ?? "").child(s).observeSingleEvent(of: .value) { (snapshot,error) in
                        if let error = error {
                            print("error",error)
                            return
                        }
                        let num = snapshot.childrenCount
                        if num < 2 {
                            self.setEmptyView()
                        } else if num < self.numOfItems {
                            if self.addProf.isHidden {
                                self.addProf.fadeIn(1) //isHidden = false
                            }
                        }
                        for d in snapshot.children {
                            let snap = d as! DataSnapshot
                            if !(snap.key == "aaaaa"){
                                self.addProfessor(profID: snap.key)
                            }
                        }
                    }
                }
            }
            if !fUniList.isEmpty {
                self.searchList.removeAll()
                self.tableView.reloadData()
                for s in fUniList {
                    self.ref.child("Universities").child(s).child(fieldName ?? "").observeSingleEvent(of: .value) { (snapshot,error) in
                        if let error = error {
                            print("error",error)
                            return
                        }
                        let num = snapshot.childrenCount
                        if num < 2 {
                            self.setEmptyView()
                        } else if num < self.numOfItems {
                            if self.addProf.isHidden {
                                self.addProf.fadeIn(1) //isHidden = false
                            }
                        }
                        for d in snapshot.children {
                            let snap = d as! DataSnapshot
                            if !(snap.key == "aaaaa") {
                                self.addProfessor(profID: snap.key)
                            }
                        }
                    }
                }
            }
            if (fUniList.isEmpty && fCityList.isEmpty) &&
                (!selectedRating.isEmpty && selectedRating == "low") {
                fCheck = false
                lastPage = false
                numOfItems = 20
                self.ref.child("Faculties").child(fieldName ?? "").child("All professors").queryOrderedByValue().queryLimited(toFirst: UInt(numOfItems)).observeSingleEvent(of: .value) { (snapshot,error) in
                    if let error = error {
                        print("error",error)
                        return
                    }
                    let num = snapshot.childrenCount
                    if num < 2 {
                        self.setEmptyView()
                    } else if num < self.numOfItems {
                        if self.addProf.isHidden {
                            self.addProf.fadeIn(1) //isHidden = false
                        }
                    }
                    self.searchList.removeAll()
                    self.tableView.reloadData()
                    for d in snapshot.children {
                        let snap = d as! DataSnapshot
                        if !(snap.key == "aaaaa") {
                            self.addProfessor(profID: snap.key)
                        }
                    }
                }
            } else if (fUniList.isEmpty && fCityList.isEmpty) &&
                        (!selectedRating.isEmpty && selectedRating == NSLocalizedString("high_rating", comment: "")) {
                fCheck = false
                lastPage = false
                numOfItems = 20
                self.searchList.removeAll()
                self.tableView.reloadData()
                self.loadData()
            }
        } else if moreCheck == 4 {
            if !selectedRating.isEmpty && selectedRating == NSLocalizedString("low_rating", comment: "") {
                self.sort(type: true)
            } else {
                self.sort(type: false)
            }
        }
    }
    //MARK: Add Professor
    @objc fileprivate func addProfessor(profID: String) {
        ref.child("Professors").child(profID).observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            let cityUniName = (snapshot.childSnapshot(forPath: "city").value as? String ?? "")+","+(snapshot.childSnapshot(forPath: "uni_name").value as? String ?? "")
            let sItem = ["cityUniName" : cityUniName, "fieldName" : snapshot.childSnapshot(forPath: "field_name").value as? String ?? "", "profName" : snapshot.childSnapshot(forPath: "prof_name").value as? String ?? "", "photoNum" : snapshot.childSnapshot(forPath: "photo").value as? Int ?? 0, "itemID" : profID, "ratingNum" : snapshot.childSnapshot(forPath: "avg_rating").value as? Double ?? 0.0] as [String : Any]
            var searchItem = SearchItem(searchData: sItem as [String : Any])
            if snapshot.childSnapshot(forPath: "title").exists() {
                searchItem.title = snapshot.childSnapshot(forPath: "title").value as? String ?? ""
            }
            self.searchList.append(searchItem)
            if (!self.fCheck && (!self.selectedRating.isEmpty && self.selectedRating == NSLocalizedString("low_rating", comment: ""))) ||
                (!self.selectedRating.isEmpty && self.selectedRating == NSLocalizedString("low_rating", comment: "")) {
                self.sort(type: true)
            } else {
                self.sort(type: false)
            }
            DispatchQueue.main.async {
                self.tableView.backgroundView = nil
                self.tableView.reloadData()
                self.tableView.tableFooterView = nil
                self.loadingData = false
            }
        }
    }
    //MARK: Utils
    @objc fileprivate func selectedRatingControl(mRef: DatabaseQuery) {
        if !selectedRating.isEmpty && selectedRating == NSLocalizedString("low_rating", comment: "") {
            fCheck = false
            lastPage = false
            numOfItems = 20
            mRef.observeSingleEvent(of: .value) { (snapshot,error) in
                if let error = error {
                    print("error",error)
                    return
                }
                let num = snapshot.childrenCount
                if num <= 2 {
                    self.setEmptyView()
                } else if num < self.numOfItems {
                    if self.addProf.isHidden {
                        self.addProf.fadeIn(1) //isHidden = false
                    }
                }
                self.searchList.removeAll()
                self.tableView.reloadData()
                for d in snapshot.children {
                    let snap = d as! DataSnapshot
                    if !(snap.key == "aaaaa") {
                        self.addProfessor(profID: snap.key)
                    }
                }
            }
        } else if !selectedRating.isEmpty && selectedRating == NSLocalizedString("high_rating", comment: "") {
            fCheck = false
            lastPage = false
            numOfItems = 20
            DispatchQueue.main.async {
                self.searchList.removeAll()
                self.tableView.reloadData()
                self.loadData()
            }
        }
    }
    
    @objc fileprivate func firstQuery(mRef: DatabaseQuery) {
        DispatchQueue.main.async {
            self.searchList.removeAll()
            self.tableView.reloadData()
        }
        mRef.observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            let num = snapshot.childrenCount
            if num < 2 {
                self.setEmptyView()
            } else if num < self.numOfItems {
                self.addProf.fadeIn(1) //isHidden = false
            }
            for d in snapshot.children {
                let snap = d as! DataSnapshot
                if !(snap.key == "aaaaa") {
                    self.addProfessor(profID: snap.key)
                }
            }
        }
    }
    
    @objc fileprivate func secondQuery(mRef: DatabaseQuery, number: Int) {
        mRef.observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            var count = 0
            self.ids.removeAll()
            for d in snapshot.children {
                let snap = d as! DataSnapshot
                if !(snap.key == "aaaaa") {
                    self.ids.append(snap.key)
                }
            }
            if !(!self.selectedRating.isEmpty && self.selectedRating == NSLocalizedString("low_rating", comment: "")){
                self.ids.reverse()
            }
            for s in self.ids {
                if count >= self.searchList.count {
                    self.addProfessor(profID: s)
                }
                count += 1
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "searchToFilterSegue" {
            let vc = segue.destination as? AddFilterVC
            vc?.moreCheck = moreCheck
            vc?.cityName = cityName ?? ""
            vc?.uniName = uniName ?? ""
            vc?.fieldName = fieldName ?? ""
            vc?.delegate = self
        } else if segue.identifier == "searchToClickedProfSegue" {
            let vc = segue.destination as? ClickedProfVC
            vc?.object = selectedItem
        }
    }
    
    private func setEmptyView() {
        self.emptyView.isHidden = false
        self.tableView.backgroundView = nil
    }
    
    //MARK: Sort
    @objc fileprivate func sort(type: Bool) { //true = lower first, false = higher first
        if type {
            self.searchList.sort {
               $0.ratingNum > $1.ratingNum
            }
            searchList.reverse()
        } else {
            self.searchList.sort {
               $0.ratingNum > $1.ratingNum
            }
        }
        var count = 0
        for _ in searchList {
            if count >= 2 {
                if self.searchList[count-2].itemID == self.searchList[count-1].itemID {
                    self.searchList.remove(at: count-2)
                }
            }
            count += 1
        }
    }
}
//MARK: Tableview Extensions
extension SearchVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchList.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedItem = self.searchList[indexPath.row]
        performSegue(withIdentifier: "searchToClickedProfSegue", sender: self)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! SearchCell
        cell.awakeFromNib()
        cell.configure(with: self.searchList[indexPath.row])
      //  cell.delegate = self
        return cell
    }

    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView == tableView {
            if ((scrollView.contentOffset.y + scrollView.frame.size.height) >= scrollView.contentSize.height) {
                if !loadingData && self.searchList.count >= 9 && !lastPage && moreCheck != 4 && !fCheck {
                    loadingData = true
                    if self.addProf.isHidden {
                        self.addProf.fadeIn(1) //isHidden = false
                    }
                    let spinner = UIActivityIndicatorView(style: .gray)
                    spinner.frame = CGRect(x: 0.0, y: 0.0, width: tableView.bounds.width, height: 70)
                    spinner.color = UIColor.init(named: "appBlueColor")
                    spinner.startAnimating()
                    tableView.tableFooterView = spinner
                    if (num - numOfItems) > 20 {
                        numOfItems += 20
                    } else {
                        numOfItems += (num - numOfItems)
                        lastPage = true
                    }
                    DispatchQueue.main.async {
                        self.loadMore()
                    }
                }
            }
        }
    }
}
extension SearchVC: AddedFilterDelegate {
    func filterAdded(cList: [String], fList: [String], uList: [String], sRating: String) {
        if !cList.isEmpty || !fList.isEmpty || !uList.isEmpty  || !sRating.isEmpty {
            self.fCheck = true
            if !cList.isEmpty {
                self.fCityList = cList
            }
            if !fList.isEmpty {
                self.fFieldList = fList
            }
            if !uList.isEmpty {
                self.fUniList = uList
            }
            if !sRating.isEmpty {
                self.selectedRating = sRating
            }
            let rightBtn = UIBarButtonItem(image: UIImage(named: "clearFilter")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(clearFilterPressed))
            self.navigationItem.rightBarButtonItem = rightBtn
            self.loadFilteredResults()
        }
    }
}
