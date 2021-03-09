//
//  StatsCell.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 11. 15..
//

import UIKit

class StatsCell: UITableViewCell {
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var num: UILabel!
    
    func configure(with item: statsItem){
        self.name.text = item.name
        self.num.text = "\(item.num)"
    }
}
