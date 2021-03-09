//
//  SearchCell.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 12..
//

import UIKit

class SearchCell: UITableViewCell {
    
    @IBOutlet private weak var photo: UIImageView!
    @IBOutlet private weak var ratingNum: UILabel!
    @IBOutlet private weak var profName: UILabel!
    @IBOutlet private weak var fieldName: UILabel!
    @IBOutlet private weak var cityUniName: UILabel!
    
    func configure(with item: SearchItem){
        var pName = item.profName
        let title = item.title ?? ""
        if !title.isEmpty {
            pName = title+" "+pName
        }
        self.profName.text = pName
        self.fieldName.text = item.fieldName
        self.cityUniName.text = item.cityUniName
        self.ratingNum.text = String(format: "%.1f", item.ratingNum)
        self.ratingNum.textColor = UIColor().setColorRating(number: item.ratingNum)
        if item.photo == 1 || String(item.photo) == "1" {
            self.photo.image = UIImage.init(named: "teacher_man")
        } else {
            self.photo.image = UIImage.init(named: "teacher_woman")
        }
    }
}
