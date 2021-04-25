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

class TestListCell: UITableViewCell, EmojiButtonArrayDelegate {
    func doubleTapEmoji(index: Int?, emoji: String) {
        
    }
    
    
    var list: List?{
        didSet {
            
            if let displayEmojis = self.list?.topEmojis{
                emojiArray.emojiLabels = Array(displayEmojis.prefix(3))
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
            fetchListUser()
            setupListName()
            
            loadListIndexImage()
            setupSocialStatsLabel()
            setupLastDateLabel()
        }
    }
    
    var refUser: User? = nil
    
    
    func setupLastDateLabel(){
        
        guard let lastDate = list?.mostRecentDate else {
            lastDateLabel.isHidden = true
            return
        }
        
        let formatter = DateFormatter()
        let calendar = NSCalendar.current
        
        let yearsAgo = calendar.dateComponents([.year], from: lastDate, to: Date())
        if (yearsAgo.year)! > 0 {
            formatter.dateFormat = "MMM d yy"
            formatter.dateFormat = "MM/dd/yy"
        } else {
            formatter.dateFormat = "MMM d"
            formatter.dateFormat = "MM/dd"

        }
        let dateDisplay = formatter.string(from: lastDate)
        
        let displayText = NSMutableAttributedString()
//
//        let lastModText = NSAttributedString(string: "Last Mod: ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.italicSystemFont(ofSize: 10),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.gray]))
//        displayText.append(lastModText)
        
        let dateLabel = NSAttributedString(string: "\(dateDisplay)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 10),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray]))
        displayText.append(dateLabel)

        
        self.lastDateLabel.attributedText = displayText
        self.lastDateLabel.sizeToFit()
        self.lastDateLabel.isHidden = false
        
    }
    
    
    var listUser: User? {
        didSet {
            guard let profileImageUrl = listUser?.profileImageUrl else {return}
//            if self.listUser?.uid != refUser?.uid {
//                profileImageView.loadImage(urlString: profileImageUrl)
//                listIndLabel.setImage(profileImageView.image, for: .normal)
//            }
            //            profileImageView.loadImage(urlString: profileImageUrl)
            usernameLabel.text = listUser?.username
            self.setupListName()
        }
    }
    
    func setupListName(){
        
        
        let listNameText = NSMutableAttributedString()
        
        let listNameString = NSMutableAttributedString(string: (list?.name)! + " ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkLegitColor(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .helveticaNeueBold, size: 20)]))
        listNameText.append(listNameString)
        let imageSize = CGSize(width: socialStatsFontSize, height: socialStatsFontSize)

        guard let lastDate = list?.mostRecentDate else {
            lastDateLabel.isHidden = true
            listnameLabel.attributedText = listNameText
            listnameLabel.sizeToFit()
            return
        }
        
        
        let formatter = DateFormatter()
        let calendar = NSCalendar.current
        
        let yearsAgo = calendar.dateComponents([.year], from: lastDate, to: Date())
        if (yearsAgo.year)! > 0 {
            formatter.dateFormat = "MMM d yy"
            formatter.dateFormat = "MM/dd/yy"
        } else {
            formatter.dateFormat = "MMM d"
            formatter.dateFormat = "MM/dd"

        }
        let dateDisplay = formatter.string(from: lastDate)
        
        let displayText = NSMutableAttributedString()
//
//        let lastModText = NSAttributedString(string: "Last Mod: ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.italicSystemFont(ofSize: 10),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.gray]))
//        displayText.append(lastModText)
        
        let dateLabel = NSAttributedString(string: " \(dateDisplay)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 10),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray]))
        listNameText.append(dateLabel)
        
        
//    // ADD USERNAME TO LIST NAME
//        if let username = self.listUser?.username {
//            if username != refUser?.username {
//                let postCountString = NSMutableAttributedString(string: "\(username)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.gray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.italicSystemFont(ofSize: 10)]))
//                listNameText.append(postCountString)
//            }
//        }
        
        
//
//        if let credCount = self.list?.totalCred {
//            if credCount > 0 {
//
//                let credButtonString = NSMutableAttributedString(string: " \(credCount)", attributes: [NSForegroundColorAttributeName: UIColor.gray, NSFontAttributeName: UIFont.boldSystemFont(ofSize: socialStatsFontSize)])
//                listNameText.append(credButtonString)
//
//                let image1Attachment = NSTextAttachment()
//                let inputImage = #imageLiteral(resourceName: "pin_filled").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
//                image1Attachment.image = inputImage
//
//                image1Attachment.bounds = CGRect(x: 0, y: (socialStatsLabel.font.capHeight - (inputImage.size.height)).rounded() / 2, width: inputImage.size.width, height: inputImage.size.height)
//
//                let image1String = NSAttributedString(attachment: image1Attachment)
//                listNameText.append(image1String)
//
//            }
//        }
//
        listnameLabel.attributedText = listNameText
        listnameLabel.sizeToFit()
        
        
        
        
//        if (list?.name)! == legitListName {
//            listIndLabel.setImage(#imageLiteral(resourceName: "legit"), for: .normal)
//            listIndLabel.backgroundColor = UIColor.legitColor()
//        }
//
//        else if (list?.name)! == bookmarkListName {
//            listIndLabel.setImage(#imageLiteral(resourceName: "bookmark_filled"), for: .normal)
//            listIndLabel.backgroundColor = UIColor.selectedColor()
//        }
//
//        else if list?.publicList == 0 {
//            listIndLabel.setImage(#imageLiteral(resourceName: "private"), for: .normal)
//            listIndLabel.backgroundColor = UIColor.clear
//        } else {
//            listIndLabel.setImage(UIImage(), for: .normal)
//            listIndLabel.backgroundColor = UIColor.clear
//        }
//
//        if (list?.name)! == legitListName {
//            let image1Attachment = NSTextAttachment()
//            let inputImage = #imageLiteral(resourceName: "legit")
//            image1Attachment.image = inputImage
//
//            image1Attachment.bounds = CGRect(x: 0, y: (listnameLabel.font.capHeight - (inputImage.size.height)).rounded() / 2, width: inputImage.size.width, height: inputImage.size.height)
//
//            let image1String = NSAttributedString(attachment: image1Attachment)
//            listNameText.append(image1String)
//        }
//
//        else if (list?.name)! == bookmarkListName {
//            let image1Attachment = NSTextAttachment()
//            let inputImage = #imageLiteral(resourceName: "bookmark_filled")
//            image1Attachment.image = inputImage
//
//            image1Attachment.bounds = CGRect(x: 0, y: (listnameLabel.font.capHeight - (inputImage.size.height)).rounded() / 2, width: inputImage.size.width, height: inputImage.size.height)
//
//            let image1String = NSAttributedString(attachment: image1Attachment)
//            listNameText.append(image1String)
//        }
//
//        else if list?.publicList == 0 {
//            let image1Attachment = NSTextAttachment()
//            let inputImage = #imageLiteral(resourceName: "private")
//            image1Attachment.image = inputImage
//
//            image1Attachment.bounds = CGRect(x: 0, y: (listnameLabel.font.capHeight - (inputImage.size.height)).rounded() / 2, width: inputImage.size.width, height: inputImage.size.height)
//
//            let image1String = NSAttributedString(attachment: image1Attachment)
//            listNameText.append(image1String)
//        }
        

        
    }
    
    func loadListIndexImage(){
        
//        self.profileImageView.image = UIImage()
//        self.profileImageView.backgroundColor = UIColor.clear
        
        listIndLabel.isHidden = !((list?.name)! == legitListName || (list?.name)! == bookmarkListName)
        profileImageView.isHidden = !listIndLabel.isHidden

        listIndLabel.backgroundColor = UIColor.clear
        listIndLabel.isHidden = false
//        profileImageView.backgroundImage.isHidden = true
//        profileImageView.backgroundColor = UIColor.legitColor()
//        profileImageView.isHidden = false
        profileImageView.backgroundImage.isHidden = true
        profileImageView.backgroundColor = UIColor.lightGray
        profileImageView.isHidden = false
        
        if (list?.name)! == legitListName {
//            listIndLabel.setImage(#imageLiteral(resourceName: "legit"), for: .normal)
            listIndLabel.setImage(#imageLiteral(resourceName: "legit_large"), for: .normal)
//            listIndLabel.backgroundColor = UIColor.legitColor()
            listIndLabel.backgroundColor = UIColor.ianLegitColor()
            profileImageView.backgroundColor = UIColor.ianLegitColor()
            listIndLabel.isHidden = false
            profileImageView.isHidden = true


        }
            
        else if (list?.name)! == bookmarkListName {
            listIndLabel.setImage(#imageLiteral(resourceName: "bookmark_filled"), for: .normal)
            //            listIndLabel.backgroundColor = UIColor.legitColor()
            listIndLabel.backgroundColor = UIColor.white
            listIndLabel.isHidden = false
            profileImageView.backgroundImage.isHidden = true
            profileImageView.backgroundColor = UIColor.lightBackgroundGrayColor()
            profileImageView.isHidden = true
//            profileImageView.isHidden = false
        }
            
        else if list?.publicList == 0 {
            listIndLabel.setImage(#imageLiteral(resourceName: "private"), for: .normal)
            //            listIndLabel.backgroundColor = UIColor.legitColor()

        } else {
//            self.loadListProfileImage()
//            guard let profileImageUrl = listUser?.profileImageUrl else {return}
//            profileImageView.loadImage(urlString: profileImageUrl)
            
            if let heroUrl = self.list?.heroImageUrl {
                profileImageView.loadImage(urlString: heroUrl)
                profileImageView.backgroundImage.isHidden = true }
            else {
                profileImageView.cancelImageRequestOperation()
                profileImageView.image = nil
                let img = #imageLiteral(resourceName: "list_color_icon")
//                profileImageView.backgroundImage.image = img

                listIndLabel.setImage(img, for: .normal)
                listIndLabel.backgroundColor = UIColor.clear
                listIndLabel.isHidden = false
                profileImageView.backgroundImage.isHidden = true
                profileImageView.backgroundColor = UIColor.backgroundGrayColor()
                profileImageView.isHidden = false
            }
            
//            if self.listUser?.uid != refUser?.uid {
//                guard let profileImageUrl = listUser?.profileImageUrl else {return}
//                profileImageView.loadImage(urlString: profileImageUrl)
//                listIndLabel.setImage(profileImageView.image, for: .normal)
//            }
//            listIndLabel.backgroundColor = UIColor.clear
        }
        

//        print("loadListIndexImage ", )
    
    }
    
    func loadListProfileImage(){
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
                if let imageURL = post?.imageUrls.first {
                    self.profileImageView.loadImage(urlString: (imageURL))
                } else {
                    self.profileImageView.image = #imageLiteral(resourceName: "blank_gray")
                }
            }
        } else {
            self.profileImageView.image = #imageLiteral(resourceName: "blank_gray")

        }
    }
    
    
    func fetchListUser(){
        guard let creatorUid = self.list?.creatorUID else {return}
        Database.fetchUserWithUID(uid: creatorUid) { (user) in
            self.listUser = user
        }
    }
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .white
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    let postImageView: CustomImageView = {
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
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.adjustsFontSizeToFitWidth = true
        //        label.numberOfLines = 0
        return label
    }()
    
    let lastDateLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.italicSystemFont(ofSize: 11)
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = NSTextAlignment.right
        label.textColor = UIColor.gray
        //        label.numberOfLines = 0
        return label
    }()
    
    let socialStatsLabel: UILabel = {
        let label = UILabel()
        label.text = "SocialStats"
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 0
        label.backgroundColor = UIColor.clear
        return label
    }()
    
    let listCountLabel: UILabel = {
        let label = UILabel()
        label.text = "SocialStats"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.numberOfLines = 0
        label.textColor = UIColor.gray
        label.backgroundColor = UIColor.clear
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
        
        let postCountString = NSMutableAttributedString()

//        if let followerCount = self.list?.followerCount {
//            if followerCount > 0 {
//                let followerCountString = NSMutableAttributedString(string: "\(followerCount) Followers ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.gray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 12)]))
//                postCountString.append(followerCountString)
//            }
//        }

        
        
        if let postCount = self.list?.postIds?.count {
            if postCount > 0 {
                let postCountStringText = NSMutableAttributedString(string: "\(postCount)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 13)]))
                postCountString.append(postCountStringText)
                let postCountString2 = NSMutableAttributedString(string: " Posts", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 13)]))
                postCountString.append(postCountString2)
                listCountLabel.attributedText = postCountString
            } else {
                listCountLabel.text = ""
            }
        }
        
        
        let socialStats = NSMutableAttributedString()

        socialStatsLabel.font = UIFont.systemFont(ofSize: socialStatsFontSize)
        let imageSize = CGSize(width: socialStatsFontSize, height: socialStatsFontSize)


        // ADD USERNAME TO LIST NAME
            if let username = self.listUser?.username {
                if username != refUser?.username {
                    let postCountString = NSMutableAttributedString(string: "\(username)  ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.gray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 12)]))
                    socialStats.append(postCountString)
                }
            }
        
        

        if let followerCount = self.list?.followerCount {
            if followerCount > 0 {
                let followerCountString = NSMutableAttributedString(string: "\(followerCount) Followers  ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: socialStatsFontSize)]))
                socialStats.append(followerCountString)
            }
        }
        
        

//        if let credCount = self.list?.totalCred {
//            if credCount > 0 {
//
//                let image1Attachment = NSTextAttachment()
//                let inputImage = #imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
//                image1Attachment.image = inputImage
//
//                image1Attachment.bounds = CGRect(x: 0, y: (socialStatsLabel.font.capHeight - (inputImage.size.height)).rounded() / 2, width: inputImage.size.width, height: inputImage.size.height)
//
//                let image1String = NSAttributedString(attachment: image1Attachment)
//                socialStats.append(image1String)
//
//                let credButtonString = NSMutableAttributedString(string: "\(credCount) ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: socialStatsFontSize)]))
//                socialStats.append(credButtonString)
//
//            }
//        }
        
            guard let lastDate = list?.mostRecentDate else {
                lastDateLabel.isHidden = true
                return
            }
            
        
        
            let formatter = DateFormatter()
            let calendar = NSCalendar.current
            
            let yearsAgo = calendar.dateComponents([.year], from: lastDate, to: Date())
            if (yearsAgo.year)! > 0 {
                formatter.dateFormat = "MMM d yy"
                formatter.dateFormat = "MM/dd/yy"
            } else {
                formatter.dateFormat = "MMM d"
                formatter.dateFormat = "MM/dd"

            }
            let dateDisplay = formatter.string(from: lastDate)
            
            let displayText = NSMutableAttributedString()
    //
    //        let lastModText = NSAttributedString(string: "Last Mod: ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.italicSystemFont(ofSize: 10),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.gray]))
    //        displayText.append(lastModText)
            
            let dateLabel = NSAttributedString(string: "\(dateDisplay)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 11),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray]))
            displayText.append(dateLabel)

            
            self.lastDateLabel.text = ""
            self.lastDateLabel.sizeToFit()
            self.lastDateLabel.isHidden = true
            
//        socialStats.append(displayText)
        
        
        socialStatsLabel.attributedText = socialStats
        socialStatsLabel.sizeToFit()
    }
    
    
    override var isSelected: Bool {
        didSet {
            self.backgroundColor = self.isSelected ? UIColor.mainBlue().withAlphaComponent(0.2) : UIColor.white
        }
    }
    
    let listIndLabel: UIButton = {
        let label = UIButton()
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let cellView = UIView()
        addSubview(cellView)
        cellView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 65)
        
        addSubview(profileImageView)
        profileImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 45, height: 45)
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
//        profileImageView.layer.cornerRadius = 40/2
        profileImageView.layer.cornerRadius = 5

        
//        addSubview(profileImageView)
//        profileImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 50, height: 50)
//        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
//        profileImageView.layer.cornerRadius = 50/2
        
        //        listIndLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        //        listIndLabel.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor).isActive = true
        
        
        addSubview(listIndLabel)
        listIndLabel.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 40, height: 40)
        listIndLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        listIndLabel.layer.cornerRadius = 40/2
        listIndLabel.layer.masksToBounds = true
        
//        addSubview(lastDateLabel)
//        lastDateLabel.anchor(top: profileImageView.topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 3, paddingRight: 5, width: 0, height: 0)
//        lastDateLabel.sizeToFit()
//
        
        addSubview(listCountLabel)
        listCountLabel.anchor(top: nil, left: nil, bottom: cellView.bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 5, width: 0, height: 0)
        
        
        addSubview(listnameLabel)
        listnameLabel.anchor(top: profileImageView.topAnchor, left: listIndLabel.rightAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 25, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        
        

        
        addSubview(socialStatsLabel)
        socialStatsLabel.anchor(top: listnameLabel.bottomAnchor, left: listnameLabel.leftAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 3, paddingRight: 10, width: 0, height: 0)
        
        
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        addSubview(separatorView)
        separatorView.anchor(top: cellView.bottomAnchor, left: listnameLabel.leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        
        addSubview(emojiArray)
        emojiArray.anchor(top: listnameLabel.topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 0, height: 25)
        emojiArray.delegate = self
        emojiArray.alignment = .right
        emojiArray.isHidden = true

        addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top: emojiArray.topAnchor, left: nil, bottom: emojiArray.bottomAnchor, right: emojiArray.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        emojiDetailLabel.sizeToFit()
        emojiDetailLabel.centerYAnchor.constraint(equalTo: emojiArray.centerYAnchor).isActive = true
        self.hideEmojiDetailLabel()
        

        //        addSubview(emojiLabel)
        //        emojiLabel.anchor(top: nil, left: profileImageView.rightAnchor, bottom: profileImageView.bottomAnchor, right: nil, paddingTop: 1, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        //        socialStatsLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        
        
        
        

        
//        let topSeparatorView = UIView()
//        topSeparatorView.backgroundColor = UIColor(white: 0, alpha: 0.5)
//        addSubview(topSeparatorView)
//        topSeparatorView.anchor(top: cellView.topAnchor, left: listnameLabel.leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
//        self.profileImageView.image = UIImage()
        self.listIndLabel.setImage(UIImage(), for: .normal)
        self.listnameLabel.text = ""
        self.socialStatsLabel.text = ""
        self.listUser = nil
        self.lastDateLabel.text = ""
        self.profileImageView.isHidden = false
        
        let subViews = self.subviews
        
        // Reused cells removes extra pictures and shrinks back contentsize width. It gets expanded and added back later if >1 pic
        
        for subview in subViews{
            if let img = subview as? CustomImageView {
                img.image = nil
                img.cancelImageRequestOperation()
                if img.tag != 0 {
                    img.removeFromSuperview()
                }
            }
        }
        
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
