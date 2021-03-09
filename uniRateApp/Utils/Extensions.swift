//
//  StringExtensions.swift
//  uniRateApp
//
//  Created by serhan özyılmaz on 2020. 10. 08..
//

import Foundation
import UIKit

//MARK: String Extensions
extension String {
    //Time Converter
    func convert(time : UInt) -> String {
        var time2 = time
        let SECOND_MILLIS : UInt = 1000;
        let MINUTE_MILLIS = 60 * SECOND_MILLIS;
        let HOUR_MILLIS = 60 * MINUTE_MILLIS;
        let DAY_MILLIS = 24 * HOUR_MILLIS;
        
        if (time2 < 1000000000000) {
            // if timestamp given in seconds, convert to millis
            time2 *= 1000;
        }
        
        let now = Date().currentTimeMillis()
        if (time2 > now || time2 <= 0) {
            return NSLocalizedString("now", comment: "")
        }
        
        let diff = now - time2
        if (diff < MINUTE_MILLIS) {
            return NSLocalizedString("just_now", comment: "")
        } else if (diff < 2 * MINUTE_MILLIS) {
            return NSLocalizedString("one_m", comment: "")
        } else if (diff < 50 * MINUTE_MILLIS) {
            return "\(diff / MINUTE_MILLIS)"+NSLocalizedString("m", comment: "")
        } else if (diff < 90 * MINUTE_MILLIS) {
            return NSLocalizedString("one_h", comment: "")
        } else if (diff < 24 * HOUR_MILLIS) {
            return "\(diff / HOUR_MILLIS)"+NSLocalizedString("h", comment: "")
        } else if (diff < 48 * HOUR_MILLIS) {
            return NSLocalizedString("yesterday", comment: "")
        } else {
            return "\(diff / DAY_MILLIS)"+NSLocalizedString("d", comment: "")
        }
    }
    //Label size calculator
    func size(width:CGFloat = 20.0, font: UIFont = UIFont.systemFont(ofSize: 17.0, weight: .regular)) -> CGSize {
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = self

        label.sizeToFit()

        return CGSize(width: label.frame.width, height: label.frame.height)
    }
}
//MARK: UIColor Extensions
extension UIColor {
    func setColorRating(number : Double) -> UIColor{
        if(number == 0){
            return UIColor.init(named: "textHintColor") ?? .gray
        }else if (number >= 0.1 && number <= 1.49){  // 0.1 - 1.4
            return UIColor.init(named: "ratingRed") ?? .red
        }else if (number >= 1.5 && number <= 2.49){ // 1.5 - 2,4
            return UIColor.init(named: "ratingOrange") ?? .orange
        }else if (number >= 2.5 && number <= 3.49){  // 2.5 - 3.4
            return UIColor.init(named: "ratingYellow") ?? .yellow
        }else if (number >= 3.5 && number <= 4.29){  // 3.5 - 4.2
            return UIColor.init(named: "ratingDiffGreen") ?? .green
        }else if (number >= 4.3 && number <= 5.0){ // 4.3  - 5.0
            return UIColor.init(named: "ratingGreen") ?? .green
        }else {
            return UIColor.init(named: "textHintColor") ?? .gray
        }
    }
    func setColorRatingOpposite(number : Double) -> UIColor{
        if(number == 0){
            return UIColor.init(named: "textHintColor") ?? .gray
        }else if (number >= 0.1 && number <= 1.49){  // 0.1 - 1.4
            return UIColor.init(named: "ratingGreen") ?? .green
        }else if (number >= 1.5 && number <= 2.49){ // 1.5 - 2,4
            return UIColor.init(named: "ratingDiffGreen") ?? .green
        }else if (number >= 2.5 && number <= 3.49){  // 2.5 - 3.4
            return UIColor.init(named: "ratingYellow") ?? .yellow
        }else if (number >= 3.5 && number <= 4.29){  // 3.5 - 4.2
            return UIColor.init(named: "ratingOrange") ?? .orange
        }else if (number >= 4.3 && number <= 5.0){ // 4.3  - 5.0
            return UIColor.init(named: "ratingRed") ?? .red
        }else {
            return UIColor.init(named: "textHintColor") ?? .gray
        }
    }
}
//MARK: Date Extensions
extension Date {
    func currentTimeMillis() -> UInt{
        return UInt(self.timeIntervalSince1970 * 1000)
    }
}
//MARK: UIView Extensions
extension UIView {
    public enum Visibility : Int {
        case visible = 0
        case invisible = 1
        case gone = 2
        case goneY = 3
        case goneX = 4
    }

    public var visibility: Visibility {
        set {
            switch newValue {
                case .visible:
                    isHidden = false
                    getConstraintY(false)?.isActive = false
                    getConstraintX(false)?.isActive = false
                case .invisible:
                    isHidden = true
                    getConstraintY(false)?.isActive = false
                    getConstraintX(false)?.isActive = false
                case .gone:
                    isHidden = true
                    getConstraintY(true)?.isActive = true
                    getConstraintX(true)?.isActive = true
                case .goneY:
                    isHidden = true
                    getConstraintY(true)?.isActive = true
                    getConstraintX(false)?.isActive = false
                case .goneX:
                    isHidden = true
                    getConstraintY(false)?.isActive = false
                    getConstraintX(true)?.isActive = true
            }
        }
        get {
            if isHidden == false {
                return .visible
            }
            if getConstraintY(false)?.isActive == true && getConstraintX(false)?.isActive == true {
                return .gone
            }
            if getConstraintY(false)?.isActive == true {
                return .goneY
            }
            if getConstraintX(false)?.isActive == true {
                return .goneX
            }
            return .invisible
        }
    }

    fileprivate func getConstraintY(_ createIfNotExists: Bool = false) -> NSLayoutConstraint? {
        return getConstraint(.height, createIfNotExists)
    }

    fileprivate func getConstraintX(_ createIfNotExists: Bool = false) -> NSLayoutConstraint? {
        return getConstraint(.width, createIfNotExists)
    }

    fileprivate func getConstraint(_ attribute: NSLayoutConstraint.Attribute, _ createIfNotExists: Bool = false) -> NSLayoutConstraint? {
        let identifier = "random_id"
        var result: NSLayoutConstraint? = nil
        for constraint in constraints {
            if constraint.identifier == identifier {
                result = constraint
                break
            }
        }
        if result == nil && createIfNotExists {
            // create and add the constraint
            result = NSLayoutConstraint(item: self, attribute: attribute, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 0)
            result?.identifier = identifier
            addConstraint(result!)
        }
        return result
    }
    
    func fadeIn(_ duration: TimeInterval? = 0.2, onCompletion: (() -> Void)? = nil) {
        self.alpha = 0
        self.isHidden = false
        UIView.animate(withDuration: duration!,
            animations: { self.alpha = 1 },
            completion: { (value: Bool) in
            if let complete = onCompletion { complete() }
            }
        )
    }

    func fadeOut(_ duration: TimeInterval? = 0.2, onCompletion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration!,
            animations: { self.alpha = 0 },
            completion: { (value: Bool) in
            self.isHidden = true
            if let complete = onCompletion { complete() }
            }
        )
    }
    
    func anchor(top : NSLayoutYAxisAnchor?,
                bottom : NSLayoutYAxisAnchor?,
                leading : NSLayoutXAxisAnchor?,
                trailing : NSLayoutXAxisAnchor?,
                paddingTop : CGFloat,
                paddingBottom : CGFloat,
                paddingRight : CGFloat,
                paddingLeft : CGFloat,
                width : CGFloat,
                height : CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false
        if let top = top {
            self.topAnchor.constraint(equalTo: top, constant: paddingTop).isActive = true
        }
        if let bottom = bottom {
            self.bottomAnchor.constraint(equalTo: bottom, constant: paddingBottom).isActive = true
        }
        if let leading = leading {
            self.leadingAnchor.constraint(equalTo: leading, constant: paddingLeft).isActive = true
        }
        if let trailing = trailing {
            self.trailingAnchor.constraint(equalTo: trailing, constant: paddingRight).isActive = true
        }
        if width != 0 {
            widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        if height != 0 {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }
}
//MARK: UIImage Extensions
extension UIImage {
    static func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }

        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
}
