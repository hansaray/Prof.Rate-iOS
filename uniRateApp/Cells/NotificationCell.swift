//
//  NotificationCell.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 17..
//

import UIKit

class NotificationCell: UITableViewCell {
    
    @IBOutlet weak var notImage: UIImageView!
    @IBOutlet private weak var time: UILabel!
    @IBOutlet private weak var notTxt: UILabel!
    
    func configure(with item: NotificationItem){
        let font = UIFont.systemFont(ofSize: 17)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.init(named: "appBlueColor") ?? .blue,
        ]
        let attributes2: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.init(named: "textColor") ?? .blue,
        ]
        if item.picName == "1" {
            self.notImage.image = UIImage(named: "likeFull")
            let attributes3: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.init(named: "ratingGreen") ?? .green,
            ]
            let str = NSMutableAttributedString(string: item.profName+" ", attributes: attributes)
            let str2 = NSMutableAttributedString(string: NSLocalizedString("not_like", comment: "")+" ", attributes: attributes2)
            let str3 = NSMutableAttributedString(string: NSLocalizedString("not_like_total", comment: "")+" ", attributes: attributes2)
            let str4 = NSMutableAttributedString(string: String(item.totalLikes ?? 0), attributes: attributes3)
            str3.append(str4)
            str2.append(str3)
            str.append(str2)
            self.notTxt.attributedText = str
        } else if item.picName == "2" {
            self.notImage.image = UIImage(named: "dislikeFull")
            let attributes3: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.init(named: "likeTxtColor") ?? .red,
            ]
            let str = NSMutableAttributedString(string: item.profName+" ", attributes: attributes)
            let str2 = NSMutableAttributedString(string: NSLocalizedString("not_dislike", comment: "")+" ", attributes: attributes2)
            let str3 = NSMutableAttributedString(string: NSLocalizedString("not_dislike_total", comment: "")+" ", attributes: attributes2)
            let str4 = NSMutableAttributedString(string: String(item.totalLikes ?? 0), attributes: attributes3)
            str3.append(str4)
            str2.append(str3)
            str.append(str2)
            self.notTxt.attributedText = str
        } else {
            self.notImage.image = UIImage(named: "dislikeFull")
            let str = NSMutableAttributedString(string: item.profName+" ", attributes: attributes)
            let str2 = NSMutableAttributedString(string: NSLocalizedString("not_deleted", comment: ""), attributes: attributes2)
            str.append(str2)
            self.notTxt.attributedText = str
        }
        self.time.text = String().convert(time: UInt(item.time))
    }
}
