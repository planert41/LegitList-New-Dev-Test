//
//  UploadLocationCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/5/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit

class EmojiFilterCell: UICollectionViewCell {
    
    let uploadLocations: UILabel = {
        
        let iv = UILabel()
        iv.backgroundColor = .clear
        iv.textColor = UIColor.ianBlackColor()
        iv.font =  UIFont(name: "Poppins-Regular", size: 12)
        return iv
        
    }()
    
    let bottomDiv = UIView()
    
    override var isSelected: Bool {
        didSet {
            uploadLocations.font = isSelected ? UIFont(name: "Poppins-Bold", size: 12) : UIFont(name: "Poppins-Regular", size: 12)
            bottomDiv.isHidden = !isSelected
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
//        backgroundColor = UIColor.mainBlue().withAlphaComponent(0.5)
        backgroundColor = UIColor.clear

        addSubview(uploadLocations)
        uploadLocations.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        
        addSubview(bottomDiv)
        bottomDiv.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 2)
        bottomDiv.backgroundColor = UIColor.ianLegitColor()
        bottomDiv.isHidden = true
        
        layer.borderWidth = 0
        layer.borderColor = UIColor.black.cgColor
        layer.cornerRadius = 5
        layer.masksToBounds = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init coder error")
    }
    
    override func prepareForReuse() {
//        self.backgroundColor = UIColor.white
//        self.uploadLocations.text = "          "
//        self.uploadLocations.sizeToFit()
//        self.sizeToFit()
//        self.layoutIfNeeded()
//        self.uploadLocations.text = ""
    }
    
}
