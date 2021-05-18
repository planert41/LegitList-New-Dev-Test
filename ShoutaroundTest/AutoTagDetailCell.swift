//
//  EmojiCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/17/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

class AutoTagDetailCell: UICollectionViewCell {
    
    var emoji: EmojiBasic? {
        didSet{
            emojiLabel.text = emoji?.emoji
            emojiLabel.sizeToFit()
            emojiTextLabel.text = emoji?.name?.capitalizingFirstLetter()
            
            emojiTextLabel.text = "\((emoji?.emoji)!)  \((emoji?.name?.capitalizingFirstLetter())!)"
            emojiTextLabel.adjustsFontSizeToFitWidth = true
        }
    }
    
    let emojiLabel: UILabel = {
        let label = UILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textAlignment = NSTextAlignment.right
        label.backgroundColor = UIColor.clear
        return label
        
    }()
    
    let emojiTextLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.clear
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = UIColor.white
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        backgroundColor = UIColor.legitColor().withAlphaComponent(0.2)
        backgroundColor = UIColor.legitColor().withAlphaComponent(0.8)

//        backgroundColor = UIColor.white

        
//        addSubview(emojiLabel)
//        addSubview(emojiTextLabel)
//
//        emojiLabel.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        emojiLabel.widthAnchor.constraint(equalTo: emojiLabel.heightAnchor, multiplier: 1).isActive = true
//        emojiTextLabel.anchor(top: topAnchor, left: emojiLabel.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
//
        
        addSubview(emojiTextLabel)
        emojiTextLabel.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 3, paddingLeft: 10, paddingBottom: 3, paddingRight: 10, width: 0, height: 0)


        layer.borderWidth = 0.5
        layer.borderColor = UIColor.lightGray.cgColor
        layer.cornerRadius = 10
        layer.masksToBounds = true
        
        
    }
    
    
    override var isSelected: Bool {
        didSet {
            // Selection checkmark
//            if isSelected == true {
//                backgroundColor = UIColor.legitColor()
//                emojiTextLabel.textColor = UIColor.white
//                accessoryType = .checkmark
//            } else {
//                backgroundColor = UIColor.white
//                emojiTextLabel.textColor = UIColor.black
//                accessoryType = .none
//            }
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    
}


