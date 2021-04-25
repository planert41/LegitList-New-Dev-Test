//
//  RatingLabel.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 12/21/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit

class RatingLabelNew: UILabel {
    
    var rating: Double = 0 {
        didSet{
            self.setRatingView()
        }
    }
    
    init(ratingScore: Double?, frame: CGRect) {
        super.init(frame: frame)
//        self.layer.cornerRadius = self.frame.width/2
        self.layer.masksToBounds = true
//        self.layer.borderWidth = 1
//        self.layer.borderColor = UIColor.black.cgColor
        self.textAlignment = NSTextAlignment.center
        self.backgroundColor = UIColor.clear
        
//        self.font = UIFont.boldSystemFont(ofSize: self.frame.height/2)
        self.font = UIFont(font: .noteworthyBold, size: self.frame.height)
        self.textColor = UIColor.darkGray
        
        self.rating = (ratingScore != nil) ? ratingScore! : 0
        setRatingView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        // decode clientName and time if you want
        super.init(coder: aDecoder)
    }
    
    func ratingBackgroundColor() -> UIColor {
        
        let cellRating = self.rating
        
        if cellRating == 0 {
            return UIColor.clear    }
        else if cellRating <= Double(1) {
            return UIColor.rgb(red: 227, green: 27, blue: 35)   }
        else if cellRating <= Double(2) {
            return UIColor.rgb(red: 227, green: 27, blue: 35).withAlphaComponent(0.55)  }
        else if cellRating <= Double(3) {
            return UIColor.rgb(red: 255, green: 173, blue: 0).withAlphaComponent(0.55)  }
        else if cellRating <= Double(4) {
            return UIColor.rgb(red: 255, green: 173, blue: 0)   }
        else if cellRating <= Double(5) {
            return UIColor.rgb(red: 252, green: 227, blue: 0).withAlphaComponent(0.55)  }
        else if cellRating <= Double(6) {
            return UIColor.rgb(red: 252, green: 227, blue: 0)   }
        else if cellRating <= Double(7) {
            return UIColor.rgb(red: 91, green: 197, blue: 51)    }
        else {
            return UIColor.clear
        }
    }
    
    func setRatingView(){
        let cellRating = self.rating
//        self.font = UIFont(font: .noteworthyBold, size: self.frame.height)
//        var textColor = UIColor.clear
        
        if cellRating == 0 {
            //            self.text = "0"
            self.text = ""
//            self.textColor = UIColor.darkGray
        } else {
            self.text = String(format: "%.0f", cellRating)
//            self.textColor = UIColor.black
        }
        
        if cellRating == 0 {
            self.textColor = UIColor.clear
        } else if cellRating <= Double(2) {
            self.textColor = UIColor.rgb(red: 204, green: 51, blue: 0)
        } else if cellRating <= Double(5) {
            self.textColor = UIColor.rgb(red: 204, green: 102, blue: 0)
        } else if cellRating <= Double(7) {
            self.textColor = UIColor.rgb(red: 0, green: 153, blue: 153)
        } else if cellRating <= Double(9) {
            self.textColor = UIColor.rgb(red: 0, green: 128, blue: 0)
        }
        
//        self.text = "TEST"
        
    }
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
}



