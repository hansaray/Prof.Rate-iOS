//
//  ChoosePhotoCVC.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 01..
//

import UIKit

class ChoosePhotoCVC: UICollectionViewController {
    
    weak var delegate: ChosenPhotoDelegate?
    private let dataSource: [String] = ["pp1","pp2","pp3","pp4","pp5","pp6","pp7","pp8","pp9","pp10","pp11","pp12","pp13","pp14","pp15","pp16"]
    private let reuseIdentifier = "photoCell"

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.onClickPhoto(photo: dataSource[indexPath.row])
        dismiss(animated: true, completion: nil)
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var cell = UICollectionViewCell()
        
        if let customCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? ChoosePhotoCell {
            customCell.configure(with: dataSource[indexPath.row])
            cell = customCell
        }
    
        return cell
    }
}
