//
//  UserCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 11/15/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

class ListCell: UITableViewCell, EmojiButtonArrayDelegate {
    func doubleTapEmoji(index: Int?, emoji: String) {
        
    }
    
    
    var list: List?{
        didSet {
            
            if let displayEmojis = self.list?.topEmojis{
                emojiArray.emojiLabels = displayEmojis
            } else {
                emojiArray.emojiLabels = []
            }
            emojiArray.setEmojiButtons()
            emojiArray.sizeToFit()
            
//            var topEmojis = ""
//            if (list?.topEmojis.count)!>0{
//                topEmojis = Array((list?.topEmojis.prefix(5))!).joined()
//            }
//            emojiLabel.text = topEmojis
//            emojiLabel.sizeToFit()
            setupListName()

            fetchListUser()
            fetchEarliestPost()
            setupSocialStatsLabel()
        }
    }
    
    
    var listUser: User? {
        didSet {
            guard let profileImageUrl = listUser?.profileImageUrl else {return}
//            profileImageView.loadImage(urlString: profileImageUrl)
            usernameLabel.text = listUser?.username
        }
    }
    
    func setupListName(){

        
        let listNameText = NSMutableAttributedString()
        
        let listNameString = NSMutableAttributedString(string: (list?.name)! + " ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 15)]))
        listNameText.append(listNameString)

        if (list?.name)! == legitListName {
            let image1Attachment = NSTextAttachment()
            let inputImage = #imageLiteral(resourceName: "legit")
            image1Attachment.image = inputImage
            
            image1Attachment.bounds = CGRect(x: 0, y: (listnameLabel.font.capHeight - (inputImage.size.height)).rounded() / 2, width: inputImage.size.width, height: inputImage.size.height)
            
            let image1String = NSAttributedString(attachment: image1Attachment)
            listNameText.append(image1String)
        }
        
        else if (list?.name)! == bookmarkListName {
            let image1Attachment = NSTextAttachment()
            let inputImage = #imageLiteral(resourceName: "bookmark_filled")
            image1Attachment.image = inputImage
            
            image1Attachment.bounds = CGRect(x: 0, y: (listnameLabel.font.capHeight - (inputImage.size.height)).rounded() / 2, width: inputImage.size.width, height: inputImage.size.height)
            
            let image1String = NSAttributedString(attachment: image1Attachment)
            listNameText.append(image1String)
        }
        
        else if list?.publicList == 0 {
            let image1Attachment = NSTextAttachment()
            let inputImage = #imageLiteral(resourceName: "private")
            image1Attachment.image = inputImage
            
            image1Attachment.bounds = CGRect(x: 0, y: (listnameLabel.font.capHeight - (inputImage.size.height)).rounded() / 2, width: inputImage.size.width, height: inputImage.size.height)
            
            let image1String = NSAttributedString(attachment: image1Attachment)
            listNameText.append(image1String)
        }
     
        listnameLabel.attributedText = listNameText
        listnameLabel.sizeToFit()
        
    }
    
    func fetchEarliestPost(){
        
        var earliestPost = ""
        var earliestPostDate = 0.0
        for (key,value) in (self.list?.postIds)! {
            let value = value as! Double
            if earliestPostDate == 0.0 {
                earliestPost = key
                earliestPostDate = value
            } else if value < earliestPostDate {
                earliestPost = key
                earliestPostDate = value
            }
        }
        
        if earliestPost != "" {
            Database.fetchPostWithPostID(postId: earliestPost) { (post, err) in
                if let err = err {
                    print("Error Fetching \(earliestPost) for List Picture")
                }
                self.profileImageView.loadImage(urlString: (post?.imageUrls.first)!)
            }
        } else {
            self.profileImageView.image = #imageLiteral(resourceName: "blank_gray")
        }
    }
    
    func fetchListUser(){
        guard let creatorUid = self.list?.creatorUID else {return}
        if listUser?.uid != creatorUid {
            Database.fetchUserWithUID(uid: creatorUid) { (user) in
                self.listUser = user
            }
        }
    }
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .white
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.textColor = UIColor.darkGray
        label.font = UIFont.systemFont(ofSize: 14)
        label.adjustsFontSizeToFitWidth = true
        //        label.numberOfLines = 0
        return label
    }()
    
    let listnameLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.adjustsFontSizeToFitWidth = true
        //        label.numberOfLines = 0
        return label
    }()
    
    
    let socialStatsLabel: UILabel = {
        let label = UILabel()
        label.text = "SocialStats"
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 0
        return label
    }()
    
    
    let emojiLabel: UILabel = {
        let label = UILabel()
        label.text = "Emoji"
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()
    
    var emojiArray = EmojiButtonArray(emojis: [], frame: CGRect(x: 0, y: 0, width: 0, height: 20))
    
    let emojiDetailLabel: PaddedUILabel = {
        let label = PaddedUILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.rgb(red: 255, green: 242, blue: 230)
        label.layer.cornerRadius = 20/2
        label.layer.borderWidth = 0.25
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.masksToBounds = true
        return label
    }()

    let socialStatsFontSize:CGFloat = 12.0
    
    func setupSocialStatsLabel() {
        let socialStats = NSMutableAttributedString()
        
        socialStatsLabel.font = UIFont.systemFont(ofSize: socialStatsFontSize)
        let imageSize = CGSize(width: socialStatsFontSize, height: socialStatsFontSize)

        
        if let credCount = self.list?.totalCred {
            if credCount > 0 {
                let credButtonString = NSMutableAttributedString(string: "  \(credCount) ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: socialStatsFontSize)]))
                socialStats.append(credButtonString)
                
                let image1Attachment = NSTextAttachment()
                let inputImage = UIImage(named: "cred")!.resizeImageWith(newSize: imageSize)
                image1Attachment.image = inputImage

                image1Attachment.bounds = CGRect(x: 0, y: (socialStatsLabel.font.capHeight - (inputImage.size.height)).rounded() / 2, width: inputImage.size.width, height: inputImage.size.height)

                let image1String = NSAttributedString(attachment: image1Attachment)
                socialStats.append(image1String)
                
            }
        }
        
        
        if let postCount = self.list?.postIds?.count {
            if postCount > 0 {
                let postCountString = NSMutableAttributedString(string: "  \(postCount) ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: socialStatsFontSize)]))
                socialStats.append(postCountString)
                
                let image1Attachment = NSTextAttachment()
                let inputImage = UIImage(named: "dining")!.resizeImageWith(newSize: imageSize)
                image1Attachment.image = inputImage
                
                image1Attachment.bounds = CGRect(x: 0, y: (socialStatsLabel.font.capHeight - (inputImage.size.height)).rounded() / 2, width: inputImage.size.width, height: inputImage.size.height)

                let image1String = NSAttributedString(attachment: image1Attachment)
                socialStats.append(image1String)
            }
        }

        
        socialStatsLabel.attributedText = socialStats
        socialStatsLabel.sizeToFit()
    }
    

    override var isSelected: Bool {
        didSet {
            self.backgroundColor = self.isSelected ? UIColor.mainBlue().withAlphaComponent(0.2) : UIColor.white
        }
    }
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let cellView = UIView()
        addSubview(cellView)
        cellView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 65)
        
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 50, height: 50)
        //        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        profileImageView.layer.cornerRadius = 50/2
        
        addSubview(listnameLabel)
        listnameLabel.anchor(top: profileImageView.topAnchor, left: profileImageView.rightAnchor, bottom: profileImageView.centerYAnchor, right: nil, paddingTop: 5, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        
        addSubview(socialStatsLabel)
        socialStatsLabel.anchor(top: profileImageView.centerYAnchor, left: profileImageView.rightAnchor, bottom: profileImageView.bottomAnchor, right: nil, paddingTop: 1, paddingLeft: 10, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)
        
        
        
//        addSubview(usernameLabel)
//        usernameLabel.anchor(top: nil, left: listnameLabel.rightAnchor, bottom: nil, right: nil, paddingTop: 1, paddingLeft: 5, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
//        usernameLabel.centerYAnchor.constraint(equalTo: listnameLabel.centerYAnchor).isActive = true
        
//        addSubview(usernameLabel)
//        usernameLabel.anchor(top: listnameLabel.bottomAnchor, left: profileImageView.rightAnchor, bottom: nil, right: nil, paddingTop: 1, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)

        addSubview(emojiArray)
        emojiArray.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 25)
        emojiArray.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        emojiArray.delegate = self
        emojiArray.alignment = .right

        addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top: profileImageView.topAnchor, left: nil, bottom: profileImageView.bottomAnchor, right: emojiArray.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        emojiDetailLabel.sizeToFit()
        emojiDetailLabel.centerYAnchor.constraint(equalTo: emojiArray.centerYAnchor).isActive = true
        self.hideEmojiDetailLabel()

//        addSubview(emojiLabel)
//        emojiLabel.anchor(top: nil, left: profileImageView.rightAnchor, bottom: profileImageView.bottomAnchor, right: nil, paddingTop: 1, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
//        socialStatsLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true


        
        
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        addSubview(separatorView)
        separatorView.anchor(top: cellView.bottomAnchor, left: listnameLabel.leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
    }
    
    func hideEmojiDetailLabel(){
        self.emojiDetailLabel.alpha = 0
    }
    
    func didTapEmoji(index: Int?, emoji: String) {
        
        guard let index = index else {
            print("No Index For emoji \(emoji)")
            return
        }
        
        let displayEmoji = emoji
        var displayTag = displayEmoji
        
        print("Selected Emoji \(emoji) : \(index)")
        if displayTag == displayEmoji {
            if let _ = EmojiDictionary[displayEmoji] {
                displayTag = EmojiDictionary[displayEmoji]!
            } else {
                print("No Dictionary Value | \(displayTag)")
                displayTag = ""
            }
        }
        
        var captionDelay = 3
        emojiDetailLabel.text = "\(displayEmoji)  \(displayTag)"
        emojiDetailLabel.alpha = 1
        emojiDetailLabel.adjustsFontSizeToFitWidth = true
        //        emojiDetailLabel.sizeToFit()
        
        UIView.animate(withDuration: 0.5, delay: TimeInterval(captionDelay), options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.emojiDetailLabel.alpha = 0
        }, completion: { (finished: Bool) in
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
