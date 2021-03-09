//
//  StatsVC.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 11. 15..
//

import UIKit
import GoogleMobileAds
import Firebase

class StatsVC: UIViewController {
    
    @IBOutlet private weak var city: UIButton!
    @IBOutlet private weak var uni: UIButton!
    @IBOutlet private weak var field: UIButton!
    @IBOutlet private weak var banner: GADBannerView!
    @IBOutlet private weak var profCount: UILabel!
    @IBOutlet private weak var info: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    private var list = [statsItem]()
    private var ref = DatabaseReference()
    private let cellID = "statsCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        uni.isSelected = true
        loadData()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        info.setTitle("Önemli: Profesör isimlerini her geçen gün uygulamamıza eklemeye devam ediyoruz! Okulunuzun/Bölümüzün profesörleri eklenmemişse, lütfen bize profesör öner kısmından Okulunuzun/Bölümünüzün profesörleri hakkında bilgilendirin", for: .normal)
        info.titleLabel?.numberOfLines = 0;
        info.titleLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
        let textSize = info.title(for: .normal)?.size(width: view.frame.width - 30)
        info.heightAnchor.constraint(equalToConstant: textSize?.height ?? 10).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        banner.adUnitID = "ca-app-pub-4004348027309516/4973206066"
        banner.rootViewController = self
        banner.load(GADRequest())
    }
    
    private func loadData() {
        list.removeAll()
        ref.child("Professors").observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            let num = snapshot.childrenCount - 1
            self.profCount.text = "Sistemimizde şu anda \(num) profesör kayıtlıdır"
        }
        if city.isSelected {
            self.addData(mRef: ref.child("Cities"))
        } else if field.isSelected {
            self.addData(mRef: ref.child("Faculties"))
        } else {
            self.addData(mRef: ref.child("Universities"))
        }
    }
    
    private func addData(mRef : DatabaseQuery){
        mRef.observeSingleEvent(of: .value) { (snapshot,error) in
            if let error = error {
                print("error",error)
                return
            }
            for d in snapshot.children {
                let snap = d as! DataSnapshot
                var num : Int = Int(snapshot.childSnapshot(forPath: snap.key).childSnapshot(forPath: "All professors").childrenCount)
                if !self.city.isSelected {
                    num -= 1
                }
                let sItem = ["name" : snap.key, "num" : num] as [String : Any]
                let StatsItem = statsItem(statsData: sItem as [String : Any])
                self.list.append(StatsItem)
                self.list.sort {
                   $0.num > $1.num
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    @IBAction func groupPressed(_ sender: UIButton) {
        let buttonArray = [city,uni,field]
        buttonArray.forEach{
            $0?.isSelected = false
        }
        sender.isSelected = true
        loadData()
    }
}
//MARK: Tableview Extensions
extension StatsVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! StatsCell
        cell.awakeFromNib()
        cell.configure(with: self.list[indexPath.row])
      //  cell.delegate = self
        return cell
    }
}
