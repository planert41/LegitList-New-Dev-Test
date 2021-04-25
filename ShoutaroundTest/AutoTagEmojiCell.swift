//
//  EmojiCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/17/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

class AutoTagCell: UITableViewCell {
    
    var emoji: Emoji? {
        didSet{
            emojiLabel.text = emoji?.emoji
            if ((emoji?.emoji ?? "") != "" && ((emoji?.name ?? "").isEmptyOrWhitespace())) {
                let emptyEmojiName = NSAttributedString(string: "N/A : Tap to Add Emoji Name", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.font: UIFont(font: .avenirNextMediumItalic, size: 12)])
                emojiTextLabel.attributedText = emptyEmojiName
            } else {
                let emptyEmojiName = NSAttributedString(string: "\(String(emoji?.name?.capitalizingFirstLetter() ?? ""))", attributes: [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20)])
                emojiTextLabel.attributedText = emptyEmojiName
            }
        }
    }
    
    var emojiTextInput: String? {
        didSet{
            guard let emojiTextInput = emojiTextInput else {return}
            emojiLabel.text = emojiTextInput
            emojiTextLabel.text = EmojiDictionary[emojiTextInput] ?? ""
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
        label.font = UIFont.boldSystemFont(ofSize: 20)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = UIColor.white
        
        addSubview(emojiLabel)
        addSubview(emojiTextLabel)
        
        emojiLabel.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 50, height: 40)
        emojiTextLabel.anchor(top: topAnchor, left: emojiLabel.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    }
    
    override var isSelected: Bool {
        didSet {
            // Selection checkmark
            if isSelected {
                backgroundColor = UIColor.selectedColor().withAlphaComponent(0.8)
                emojiTextLabel.textColor = UIColor.black
                tintColor = UIColor.black

//                emojiTextLabel.textColor = UIColor.white
//                tintColor = UIColor.white
                accessoryType = .checkmark
            } else {
                backgroundColor = UIColor.white
                emojiTextLabel.textColor = UIColor.black
                tintColor = UIColor.black
                accessoryType = .none
            }
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

