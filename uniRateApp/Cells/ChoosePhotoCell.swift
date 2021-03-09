//
//  ChoosePohotoCell.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 01..
//

import UIKit

class ChoosePhotoCell: UICollectionViewCell {
    
    @IBOutlet weak var ppImage: UIImageView!
    
    func configure(with photoName: String){
        self.ppImage.image = UIImage.init(named: photoName)
    }
    
}
