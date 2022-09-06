//
//  EmojiCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/17/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

class SearchResultsCell: UITableViewCell {
    
// INPUTS
    
    
    var emoji: EmojiBasic? {
        didSet{
            self.refreshCell()
            emojiLabel.text = emoji?.emoji ?? ""
            emojiTextLabel.text = emoji?.name?.capitalizingFirstLetter() ?? ""
            self.postCount = (emoji?.count) ?? 0
            self.hideEmojiLabel?.isActive = false
//            setFormats()
        }
    }
    
    var locationName: String? {
        didSet {
            self.refreshCell()
            if !((locationName?.isEmptyOrWhitespace()) ?? true) {
                emojiLabel.text = ""
                setupLocationName()
                setupPostCount()
//                emojiTextLabel.text = locationName
                self.hideEmojiLabel?.isActive = true
            } else {
                self.hideEmojiLabel?.isActive = false
            }
//            setFormats()
        }
    }
    
    func setupLocationName(){
        guard let tempWords = locationName?.components(separatedBy: " ") else { return }
        var tempOutput: [String] = []
        for x in tempWords {
            tempOutput.append(x.capitalizingFirstLetter())
        }
        self.emojiTextLabel.text = tempOutput.joined(separator: " ").cutoff(length: 40)
        self.emojiTextLabel.sizeToFit()
    }
    
    var showDefaultCounts = false
    
    var user: User?{
        didSet {
            self.refreshCell()
            var topEmojis = ""
            if let user = user {
                
                var displayName = user.username
                
                if (user.topEmojis.count)>0{
                    topEmojis = Array((user.topEmojis.prefix(3))).joined()
                    displayName += " \(topEmojis)"
                }

                
                emojiTextLabel.text = displayName
                emojiLabel.sizeToFit()
                self.profileImageView.loadImage(urlString: (self.user?.profileImageUrl)!)
                self.profileImageView.isHidden = false
                self.postCount = user.posts_created ?? 0
            }
//            setFormats()

        }
    }
    
    func refreshCell(){
        self.profileImageView.image = UIImage()
        self.profileImageView.isHidden = true
        self.emojiLabel.text = ""
        self.emojiTextLabel.text = ""
        self.hideEmojiLabel?.isActive = false
        self.postCountLabel.text = ""
    }
    
    func setFormats(){
        self.profileImageView.image = UIImage()
        self.emojiLabel.text = ""
        self.emojiTextLabel.text = ""
        
        self.profileImageView.isHidden = user == nil
        self.hideEmojiLabel?.isActive = locationName?.isEmptyOrWhitespace() ?? false
    }
    
    func setupPostCount(){
        if postCount > 0 {
            self.postCountLabel.text = "\(postCount) POSTS"
            self.postCountLabel.font = UIFont(font: .avenirNextDemiBold, size: 10)
            self.postCountLabel.textColor = UIColor.darkGray
            self.postCountLabel.isHidden = false
        } else if defaultPostCount > 0 && showDefaultCounts {
            self.postCountLabel.text = "\(defaultPostCount) POSTS"
            self.postCountLabel.font = UIFont(font: .avenirNextRegular, size: 10)
            self.postCountLabel.textColor = UIColor.gray
            self.postCountLabel.isHidden = false
        } else {
            self.postCountLabel.isHidden = true
        }

    }
    
    
    var postCount: Int = 0 {
        didSet {
            self.setupPostCount()
        }
    }
    
    var defaultPostCount: Int = 0 {
        didSet {
            self.setupPostCount()
        }
    }
    
    var grayed: Bool = false {
        didSet {
            if grayed {
                self.postCountLabel.textColor = UIColor.lightGray
                self.emojiTextLabel.textColor = UIColor.gray
                self.emojiLabel.alpha = 0.5
            } else {
                self.postCountLabel.textColor = UIColor.darkGray
                self.emojiTextLabel.textColor = UIColor.darkLegitColor()
                self.emojiLabel.alpha = 1
            }
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
        label.font = UIFont(font: .avenirNextMedium, size: 16)
        return label
    }()
    
    let postCountLabel: UILabel = {
        let label = UILabel()
        label.text = "Posts"
        label.textColor = UIColor.gray
        label.font = UIFont(font: .avenirNextRegular, size: 10)
        label.textAlignment = NSTextAlignment.right
        label.backgroundColor = UIColor.clear
        return label
        
    }()
    
    override var isSelected: Bool {
        didSet {
            self.tempView.backgroundColor = self.isSelected ? UIColor.mainBlue().withAlphaComponent(0.2) : UIColor.white
        }
    }
    
    var hideEmojiLabel: NSLayoutConstraint?
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .white
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    var tempView = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.backgroundGrayColor()

        addSubview(tempView)
        tempView.backgroundColor = UIColor.ianLightGrayColor()
        tempView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        tempView.addSubview(emojiLabel)
        tempView.addSubview(emojiTextLabel)
        tempView.addSubview(postCountLabel)
        tempView.addSubview(profileImageView)
        
        
        postCountLabel.anchor(top: nil, left: nil, bottom: nil, right: tempView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        postCountLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        postCountLabel.isHidden = true
        
        
        emojiLabel.anchor(top: tempView.topAnchor, left: tempView.leftAnchor, bottom: tempView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 0, width: 50, height: 40)
        
        profileImageView.anchor(top: nil, left: tempView.leftAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 0, width: 45, height: 45)
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.layer.cornerRadius = 45/2
        profileImageView.layer.masksToBounds = true
        profileImageView.isHidden = true
        
        
        emojiTextLabel.anchor(top: tempView.topAnchor, left: emojiLabel.rightAnchor, bottom: tempView.bottomAnchor, right: postCountLabel.leftAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        emojiTextLabel.sizeToFit()
        
        hideEmojiLabel = emojiTextLabel.leftAnchor.constraint(equalTo: tempView.leftAnchor, constant: 30)
        hideEmojiLabel?.isActive = false


        

    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    override func prepareForReuse() {
        super.prepareForReuse()
        postCountLabel.isHidden = true
        grayed = false
        self.user = nil
        self.locationName = nil
        self.postCount = 0
        self.defaultPostCount = 0
        self.postCountLabel.text = ""
        self.isSelected = false
        self.emoji = nil
        self.tempView.backgroundColor = UIColor.ianLightGrayColor()
        self.refreshCell()

    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

    }
    
    
}
