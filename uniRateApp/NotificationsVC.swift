//
//  NotificationsVC.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 17..
//

import UIKit
import GoogleMobileAds
import Firebase

class NotificationsVC: UIViewController {
    
    var object : User?
    @IBOutlet private weak var banner: GADBannerView!
    @IBOutlet private weak var tableView: UITableView!
    private var list = [NotificationItem]()
    private var selectedItem : NotificationItem?
    private let cellID = "notCell"
    private var ref = DatabaseReference()
    private var moreCheck : UInt16 = 0
    private var num : Int = 0
    private var numOfItems = 7
    private var loadingData = false
    private var lastPage = false
    private var ids = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference().child("users").child(Auth.auth().currentUser?.uid ?? "").child("myNotifications")
        numCheck()
        loadNotifications()
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        banner.adUnitID = "ca-app-pub-4004348027309516/8755215580"
        banner.rootViewController = self
        banner.load(GADRequest())
    }
    
    @objc fileprivate func numCheck() {
        ref.observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            if snapshot.exists() {
                self.num = Int(snapshot.childrenCount)
            } else {
                self.tableView.isHidden = true
            }
        }
    }
    //MARK: Load Notifications
    @objc fileprivate func loadNotifications() {
        ref.queryOrdered(byChild: "time").queryLimited(toLast: UInt(numOfItems)).observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            self.list.removeAll()
            self.tableView.reloadData()
            for d in snapshot.children {
                let snap = d as! DataSnapshot
                self.addNotification(key: snap.key)
            }
        }
    }
    //MARK: Load More
    @objc fileprivate func loadMore() {
        let number = list.count
        let startKey = list[number-1].itemID
        ref.queryOrdered(byChild: "time").queryEnding(atValue: startKey).queryLimited(toLast: UInt(numOfItems)).observeSingleEvent(of: .value) { (snapshot,error) in
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
                if count >= self.list.count {
                    self.addNotification(key: s)
                }
                count += 1
            }
        }
    }
    //MARK: Add Notification
    @objc fileprivate func addNotification(key: String) {
        ref.child(key).observeSingleEvent(of: .value) { (snapshot,error) in
            if snapshot.exists() {
                let nItem = ["profName" : snapshot.childSnapshot(forPath: "profName").value as? String ?? "", "picName" : String(snapshot.childSnapshot(forPath: "picName").value as? Int ?? 0), "ratingID" : snapshot.childSnapshot(forPath: "ratingID").value as? String ?? "", "itemID" : key, "time" : snapshot.childSnapshot(forPath: "time").value as? Int ?? 0] as [String : Any]
                var notItem = NotificationItem(notData: nItem as [String : Any])
                if snapshot.childSnapshot(forPath: "totalLikes").exists() {
                    notItem.totalLikes = snapshot.childSnapshot(forPath: "totalLikes").value as? Int ?? 0
                }
                if snapshot.childSnapshot(forPath: "totalDislikes").exists() {
                    notItem.totalLikes = snapshot.childSnapshot(forPath: "totalDislikes").value as? Int ?? 0
                }
                if self.object != nil {
                    notItem.object = self.object
                }
                self.list.append(notItem)
                self.list.sort {
                    $0.time > $1.time
                }
                var count = 0
                for _ in self.list {
                    if count >= 2 {
                        if self.list[count-2].itemID == self.list[count-1].itemID {
                            self.list.remove(at: count-2)
                        }
                    }
                    count += 1
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.tableView.tableFooterView = nil
                    self.loadingData = false
                }
                self.setSeenInfo()
            }
        }
    }
    //MARK: Utils
    @objc fileprivate func setSeenInfo() {
        if list.count != 0 {
            for o in list {
                self.ref.child(o.itemID).child("seen").setValue(true)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "notToBiggerRatingSegue" {
            let vc = segue.destination as? BiggerRatingVC
            vc?.object = selectedItem
            if selectedItem?.picName == "3" {
                vc?.info = "deleted"
            }
        }
    }
}
//MARK: TableView Extension
extension NotificationsVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedItem = self.list[indexPath.row]
        performSegue(withIdentifier: "notToBiggerRatingSegue", sender: self)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! NotificationCell
        cell.configure(with: self.list[indexPath.row])
        return cell
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView == tableView {
            if ((scrollView.contentOffset.y + scrollView.frame.size.height) >= scrollView.contentSize.height) {
                if !loadingData && self.list.count >= 7 && !lastPage {
                    loadingData = true
                    let spinner = UIActivityIndicatorView(style: .gray)
                    spinner.frame = CGRect(x: 0.0, y: 0.0, width: tableView.bounds.width, height: 70)
                    spinner.color = UIColor.init(named: "appBlueColor")
                    spinner.startAnimating()
                    tableView.tableFooterView = spinner
                    if (num - numOfItems) > 7 {
                        numOfItems += 7
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
