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


protocol MainTabListCellDelegate {
    func extTapUser(userId: String)
    func extTapList(list: List)
    func goToLocation(location: Location?)
    func showCity(city: City)
}

class MainTabListCell: UITableViewCell, EmojiButtonArrayDelegate {
    
    var delegate: MainTabListCellDelegate?
    var cellType: String?
    
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
        
        var captionDelay = 2
        emojiDetailLabel.text = "\(displayEmoji)  \(displayTag)"
        emojiDetailLabel.alpha = 1
        emojiDetailLabel.adjustsFontSizeToFitWidth = true
        //        emojiDetailLabel.sizeToFit()
        
        UIView.animate(withDuration: 0.5, delay: TimeInterval(captionDelay), options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.emojiDetailLabel.alpha = 0
        }, completion: { (finished: Bool) in
        })
    }
    
    func doubleTapEmoji(index: Int?, emoji: String) {
        print("Double Tap \(emoji) | \(index)")
    }
    
    
    var user: User?{
        didSet {
            guard let user = user else {return}
//            var topEmojis = ""
//            if (user.topEmojis.count)>0{
//                topEmojis = Array((user.topEmojis.prefix(3))).joined()
//            }
//            emojiLabel.text = topEmojis
//            emojiLabel.sizeToFit()
            
            self.profileImageView.layer.cornerRadius = 60/2
            let displayEmojis = user.topEmojis
            if displayEmojis.count > 0{
                emojiArray.emojiLabels = Array(displayEmojis.prefix(3))
            } else {
                emojiArray.emojiLabels = []
            }
            emojiArray.emojiFontSize = 25
            emojiArray.setEmojiButtons()
            emojiArray.sizeToFit()
            
            setupUsernameLabel()
            setupFollowButton()
            setupSocialStatsLabel()
            self.followButton.isHidden = false
            self.altTextLabel.isHidden = true
            emojiArray.isHidden = true


        }
    }
    
    var emoji: String? {
        didSet {
            guard let emoji = emoji else {return}
        }
    }
    
    var list: List? {
        didSet {
            guard let list = list else {return}
//            var topEmojis = ""
//            if (list.topEmojis.count)>0{
//                topEmojis = Array((list.topEmojis.prefix(3))).joined()
//                emojiLabel.text = topEmojis
//                emojiLabel.sizeToFit()
//            }
            self.isSelected = list.isSelected
            self.profileImageView.layer.cornerRadius = 5
            let displayEmojis = list.topEmojis
            if displayEmojis.count > 0{
                emojiArray.emojiLabels = Array(displayEmojis.prefix(3))
            } else {
                emojiArray.emojiLabels = []
            }
            emojiArray.emojiFontSize = 25
            emojiArray.setEmojiButtons()
            emojiArray.sizeToFit()
            fetchUserForList()
            setupListnameLabel()
//            setupListSocialStatsLabel()
            self.followButton.isHidden = true
            self.altTextLabel.isHidden = false
            emojiArray.isHidden = true
            
            self.subHeaderLabel.isHidden = list.creatorUID == CurrentUser.uid
            self.subHeaderIcon.isHidden = list.creatorUID == CurrentUser.uid

        }
    }
    
    var location: Location?{
        didSet {
            guard let location = location else {return}

            self.profileImageView.layer.cornerRadius = 10
            let displayEmojis = (location.emojis ?? [:]).sorted(by: { $0.value > $1.value })
            var tempEmojiArray: [String] = []
            
            for (key,value) in displayEmojis {
                if tempEmojiArray.count < 3 {
                    tempEmojiArray.append(key)
                }
            }
            
            
            if tempEmojiArray.count > 0{
                emojiArray.emojiLabels = tempEmojiArray
            } else {
                emojiArray.emojiLabels = []
            }
            emojiArray.emojiFontSize = 25
            emojiArray.setEmojiButtons()
            emojiArray.sizeToFit()
            emojiArray.isHidden = false
            
            setupLocationnameLabel()
            self.followButton.isHidden = true
            self.altTextLabel.isHidden = true

        }
    }
    
    var city: City?{
        didSet {
            guard let city = city else {return}
            
            self.imageWidthConstraint?.constant = 0
            self.profileImageView.layer.cornerRadius = 10
            let displayEmojis = (city.emojis ?? [:]).sorted(by: { $0.value > $1.value })
            var tempEmojiArray: [String] = []
            
            for (key,value) in displayEmojis {
                if tempEmojiArray.count < 3 {
                    tempEmojiArray.append(key)
                }
            }
            
            
            if tempEmojiArray.count > 0{
                emojiArray.emojiLabels = tempEmojiArray
            } else {
                emojiArray.emojiLabels = []
            }
            emojiArray.emojiFontSize = 25
            emojiArray.setEmojiButtons()
            emojiArray.sizeToFit()
            emojiArray.isHidden = false
            
            setupCitynameLabel()
            self.followButton.isHidden = true
            self.altTextLabel.isHidden = true

        }
    }
    
    func fetchUserForList() {
        guard let uid = self.list?.creatorUID else {return}
        Database.fetchUserWithUID(uid: uid) { (user) in
            self.listUser = user
        }
    }
    
    var listUser: User? {
        didSet {
            self.setupListnameLabel()
//            self.setupListUserName()
        }
    }
    
    
    let listNameIcon: UIButton = {
        let button = UIButton()
        let listIcon = #imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate)
        button.setImage(listIcon, for: .normal)
        button.backgroundColor = UIColor.clear
        button.isUserInteractionEnabled = false
        button.tintColor = UIColor.ianBlackColor()
        return button
    }()
        
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .white
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.adjustsFontSizeToFitWidth = true
//        label.numberOfLines = 0
        return label
    }()
    
    let subHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.adjustsFontSizeToFitWidth = true
//        label.numberOfLines = 0
        return label
    }()
    
    lazy var subHeaderIcon: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.contentMode = .scaleAspectFit
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        button.backgroundColor = UIColor.clear
//        button.addTarget(self, action: #selector(handleFollow), for: .touchUpInside)
        return button
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
        label.font = UIFont.systemFont(ofSize: 30)
        label.numberOfLines = 0
        return label
    }()
    
    var emojiArray = EmojiButtonArray(emojis: [], frame: CGRect(x: 0, y: 0, width: 0, height: 30))

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
    
    lazy var followButton: UIButton = {
        let button = UIButton()
        button.setTitle("Follow", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        button.backgroundColor = UIColor.mainBlue()
        button.addTarget(self, action: #selector(handleFollow), for: .touchUpInside)
        return button
    }()
    
    let altView = UIView()
    
    let altTextLabel: UILabel = {
        let label = UILabel()
        label.text = "Email"
        label.font = UIFont(name: "Poppins-Regular", size: 15)
        label.font = UIFont.systemFont(ofSize: 15)
        label.numberOfLines = 0
        return label
    }()
    
    lazy var emailButton: UIButton = {
        let button = UIButton()
        button.setTitle("    Email", for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 20)
        button.setTitleColor(UIColor.darkGray, for: .normal)
        button.titleLabel?.textAlignment = .left
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        let image = #imageLiteral(resourceName: "email").withRenderingMode(.alwaysOriginal)
        button.backgroundColor = UIColor.clear
        button.setImage(image, for: .normal)
//        button.addTarget(self, action: #selector(handleFollow), for: .touchUpInside)
        button.semanticContentAttribute  = .forceLeftToRight
        button.isUserInteractionEnabled = false
        return button
    }()
    
    var altText: String? {
        didSet {
            triggerAltView()
        }
    }
    
    func triggerAltView() {
        altView.isHidden = altText == nil
        cellView.isHidden = !altView.isHidden
        emailButton.setTitle("     \(altText ?? "")", for: .normal)
        emailButton.sizeToFit()
    }
    
    func setupLocationnameLabel() {
        guard let location = location else {return}
        if let url = self.location?.imageUrl {
            self.profileImageView.loadImage(urlString: url)
        }
        
        let locationNameLabelText = NSMutableAttributedString()
        let locationNameString = NSMutableAttributedString(string: "\((self.location?.locationName)!) ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont(font: .helveticaNeueBold, size: 18)])

        locationNameLabelText.append(locationNameString)
        
        self.headerLabel.attributedText = locationNameLabelText
        self.headerLabel.sizeToFit()
        
        let subheaderFont = UIFont.boldSystemFont(ofSize: 14)
        
        if let city = self.location?.locationSummaryID {
            var tempCity = city.cutoff(length: 30)
            let fanCountString = NSMutableAttributedString(string: "\(tempCity)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray, NSAttributedString.Key.font: subheaderFont])
            subHeaderLabel.attributedText = fanCountString
            subHeaderLabel.sizeToFit()
        } else {
            subHeaderLabel.text = ""
        }
        
        let socialFont = UIFont.systemFont(ofSize: 13)
        let socialStats = NSMutableAttributedString()

        if let postCount = self.location?.postIds?.count {
            let postCountString = NSMutableAttributedString(string: "\(postCount) Posts ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: socialFont])
            socialStats.append(postCountString)
            
            socialStatsLabel.attributedText = socialStats
            socialStatsLabel.sizeToFit()
        } else {
            socialStatsLabel.text = ""
            socialStatsLabel.sizeToFit()
        }



        

        subHeaderIcon.setImage(UIImage(), for: .normal)
        subHeaderIcon.sizeToFit()
        altTextLabel.isHidden = true
        
        
    }
    
    func setupCitynameLabel() {
        guard let city = city else {return}
        
        let locationNameLabelText = NSMutableAttributedString()
        let locationNameString = NSMutableAttributedString(string: "\((self.city?.cityName)!) ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont(font: .helveticaNeueBold, size: 18)])

        locationNameLabelText.append(locationNameString)
        
        self.headerLabel.attributedText = locationNameLabelText
        self.headerLabel.sizeToFit()
        
        let subheaderFont = UIFont.boldSystemFont(ofSize: 14)
        
        if let locationCount = self.city?.locationIds?.count {
            let locationCountString = NSMutableAttributedString(string: "\(locationCount ?? 0) Locations ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray, NSAttributedString.Key.font: subheaderFont])
            
            subHeaderLabel.attributedText = locationCountString
            subHeaderLabel.sizeToFit()
        } else {
            subHeaderLabel.text = ""
            subHeaderLabel.sizeToFit()
        }
                
        let socialFont = UIFont.systemFont(ofSize: 13)
        let socialStats = NSMutableAttributedString()

        if let postCount = self.city?.postIds?.count {
            let postCountString = NSMutableAttributedString(string: "\(postCount ?? 0) Posts ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: socialFont])
            socialStats.append(postCountString)
            
            socialStatsLabel.attributedText = socialStats
            socialStatsLabel.sizeToFit()
        } else {
            socialStatsLabel.text = ""
            socialStatsLabel.sizeToFit()
        }

        
        subHeaderIcon.setImage(UIImage(), for: .normal)
        subHeaderIcon.sizeToFit()
        altTextLabel.isHidden = true
        
        
    }
    
    
    
    func setupUsernameLabel() {
        guard let user = user else {return}
        self.profileImageView.loadImage(urlString: (self.user?.profileImageUrl)!)
        
        let usernameLabelText = NSMutableAttributedString()
        let usernameString = NSMutableAttributedString(string: "\((self.user?.username)!) ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont(font: .helveticaNeueBold, size: 18)])

        usernameLabelText.append(usernameString)

    // ADD BADGES
        let usernameBadges = NSMutableAttributedString()
        let userBadges = user.userBadges
        for badge in userBadges {
            let image1Attachment = NSTextAttachment()
            let inputImage = UserBadgesImageRef[badge]
            image1Attachment.image = inputImage.alpha(1)
            image1Attachment.bounds = CGRect(x: 0, y: (headerLabel.font.capHeight - (inputImage.size.height)).rounded() / 2, width: inputImage.size.width, height: inputImage.size.height)

            let image1String = NSAttributedString(attachment: image1Attachment)
            usernameBadges.append(image1String)
        }
        
        usernameLabelText.append(usernameBadges)
        
        self.headerLabel.attributedText = usernameLabelText
        self.headerLabel.sizeToFit()
        
    }
    
    func setupListnameLabel() {
        guard let list = list else {return}
        if let header = list.heroImageUrl {
            self.profileImageView.loadImage(urlString: header)
        }
        else if list.listImageUrls.count > 0 {
            for (x, imgUrl) in (list.listImageUrls ?? []).enumerated() {
                if !imgUrl.isEmptyOrWhitespace() {
                    self.profileImageView.loadImage(urlString: imgUrl)
                    break
                }
            }
        } else {
            self.profileImageView.image = UIImage()
            let img = #imageLiteral(resourceName: "list_color_icon")
//            self.profileImageView.isListBackground = true
            self.profileImageView.backgroundColor = UIColor(patternImage: img)
//            self.profileImageView.backgroundImage.image = img
//            self.profileImageView.backgroundImage.isHidden = false
            self.profileImageView.contentMode = .scaleAspectFit
//            self.profileImageView.backgroundColor = UIColor.backgroundGrayColor()
        }
        
        self.profileImageView.isHidden = list.isRatingList && self.profileImageView.image == UIImage()
                
        let listnameLabelText = NSMutableAttributedString()
        
        var listNameColor = list.isLegitList ? UIColor.ianLegitColor() : UIColor.black

        let image1Attachment = NSTextAttachment()
        let inputImage = self.list?.creatorUID == CurrentUser.uid ? #imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate)
        image1Attachment.image = inputImage.alpha(1)
        image1Attachment.bounds = CGRect(x: 0, y: (headerLabel.font.capHeight - (inputImage.size.height)).rounded() / 2, width: inputImage.size.width, height: inputImage.size.height)

        let image1String = NSAttributedString(attachment: image1Attachment)
        if !(self.list?.isRatingList ?? false) {
            listnameLabelText.append(image1String)
        }
        
        var listNameText = (self.list?.name ?? "").truncate(length: 20)
//        if list.topEmojis.count > 0 {
//            listNameText += "  \(list.topEmojis.prefix(3).joined())"
//        }
        
        
        let listnameString = NSMutableAttributedString(string: " \((listNameText))", attributes: [NSAttributedString.Key.foregroundColor: listNameColor, NSAttributedString.Key.font: UIFont(font: .helveticaNeueBold, size: 18)])
        listnameLabelText.append(listnameString)
        
        self.headerLabel.tintColor = listNameColor
        self.headerLabel.attributedText = listnameLabelText
        self.headerLabel.sizeToFit()
        
        
        let socialStats = NSMutableAttributedString()
        let socialFont = UIFont.systemFont(ofSize: 15)
        altTextLabel.isHidden = true
        altTextLabel.text = ""

        var listAttributedString = NSMutableAttributedString()
        var listCountColor = UIColor.darkGray

        if let postCount = list.postIds?.count {
            if postCount > 0 {
                let postCountString = NSMutableAttributedString(string: "\(postCount) Posts  ", attributes: [NSAttributedString.Key.foregroundColor: listCountColor, NSAttributedString.Key.font: socialFont])
                listAttributedString.append(postCountString)
//                altTextLabel.text = "\(postCount) Posts "
//                altTextLabel.isHidden = false
            } else {
//                altTextLabel.text = "Add Posts"
            }
        }
        
        let followerFont = UIFont.systemFont(ofSize: 14)

        let fanCount = list.followerCount
        if fanCount > 0 {
            let fanCountString = NSMutableAttributedString(string: "\(fanCount) Follows  ", attributes: [NSAttributedString.Key.foregroundColor: listCountColor, NSAttributedString.Key.font: followerFont])
            listAttributedString.append(fanCountString)
        }
        
        
        let usernameFont = UIFont.italicSystemFont(ofSize: 13)
        if let username = self.listUser?.username {
            if self.list?.creatorUID != CurrentUser.uid {
                let listUserString = NSMutableAttributedString(string: "\(username)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: usernameFont])
                listAttributedString.append(listUserString)
            }
        }
        

        
        altTextLabel.attributedText = listAttributedString
        

    }
    
    func setupSocialStatsLabel() {
        let subheaderFont = UIFont.boldSystemFont(ofSize: 14)
        
        if let fanCount = self.user?.followersCount {
            if fanCount > 0 {
                let fanCountString = NSMutableAttributedString(string: "\(fanCount) Followers ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray, NSAttributedString.Key.font: subheaderFont])
                subHeaderLabel.attributedText = fanCountString
                subHeaderLabel.sizeToFit()

//                socialStatsLabel.attributedText = fanCountString
//                socialStatsLabel.sizeToFit()
                
            }
        }
        
        let socialFont = UIFont.systemFont(ofSize: 13)
        let socialStats = NSMutableAttributedString()

        if let postCount = self.user?.posts_created {
            let postCountString = NSMutableAttributedString(string: "\(postCount) Posts ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray, NSAttributedString.Key.font: socialFont])
            socialStats.append(postCountString)
        }
        
        if let listCount = self.user?.lists_created {
            let listCountString = NSMutableAttributedString(string: "\(listCount) Lists ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: socialFont])
            socialStats.append(listCountString)
        }
        
        socialStatsLabel.attributedText = socialStats
        socialStatsLabel.sizeToFit()

        

        subHeaderIcon.setImage(UIImage(), for: .normal)
        subHeaderIcon.sizeToFit()
        altTextLabel.isHidden = true
//        socialStatsLabel.text = ""

        
//        let subHeaderFont = UIFont.systemFont(ofSize: 13)
//
//        if let fanCount = self.user?.followersCount {
//            if fanCount > 0 {
//                let fanCountString = NSMutableAttributedString(string: "\(fanCount) Followers ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: subHeaderFont])
//
//                socialStatsLabel.attributedText = fanCountString
//                socialStatsLabel.sizeToFit()
//
//            }
//        }
        

    }
    
    func setupListUserName() {
        // LIST USER
        guard let listUser = self.listUser else {return}
        subHeaderIcon.setImage(UIImage(), for: .normal)

        let socialFont = UIFont.systemFont(ofSize: 13)
        if let username = self.listUser?.username {
            let listUserString = NSMutableAttributedString(string: "\(username) ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: socialFont])
            
            subHeaderLabel.attributedText = listUserString
            subHeaderLabel.sizeToFit()
            
                        
        // ADD BADGES
            let usernameBadges = NSMutableAttributedString()
            let userBadges = listUser.userBadges
            for badge in userBadges {
                let image1Attachment = NSTextAttachment()
                let inputImage = UserBadgesImageRef[badge]
//                image1Attachment.image = inputImage.alpha(1)
//                image1Attachment.bounds = CGRect(x: 0, y: (subHeaderLabel.font.capHeight - (inputImage.size.height) - 2).rounded() / 2, width: inputImage.size.width - 4, height: inputImage.size.height - 4)
//
//                let image1String = NSAttributedString(attachment: image1Attachment)
//                usernameBadges.append(image1String)
//                listUserString.append(usernameBadges)

                subHeaderIcon.setImage(inputImage, for: .normal)
                subHeaderIcon.sizeToFit()
            }
            
            
        } else {
            subHeaderLabel.text = ""
            subHeaderLabel.sizeToFit()
        }

    }
    
    
    func setupListSocialStatsLabel() {
        guard let list = list else {return}
        let socialStats = NSMutableAttributedString()
        let socialFont = UIFont.boldSystemFont(ofSize: 15)
        altTextLabel.isHidden = true
        altTextLabel.text = ""

        var listAttributedString = NSMutableAttributedString()
        
        if let postCount = list.postIds?.count {
            if postCount > 0 {
                let postCountString = NSMutableAttributedString(string: "\(postCount) Posts  ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: socialFont])
                listAttributedString.append(postCountString)
//                altTextLabel.text = "\(postCount) Posts "
//                altTextLabel.isHidden = false
            } else {
//                altTextLabel.text = "Add Posts"
            }
        }
        
//        let credCount = list.totalCred
//        if credCount > 0 {
//            let credCountString = NSMutableAttributedString(string: "\(credCount) ⭐️ ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)])
//            socialStats.append(credCountString)
//        }
//
        
        let fanCount = list.followerCount
        if fanCount > 0 {
            let fanCountString = NSMutableAttributedString(string: "\(fanCount) Followers ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: socialFont])
            listAttributedString.append(fanCountString)
        }
        altTextLabel.attributedText = listAttributedString
        
        
        
    // LAST UPDATED STRING
//        if list.latestNotificationTime != Date.distantPast {
//            // Setup Post Date
//            let formatter = DateFormatter()
//            let calendar = NSCalendar.current
//
//            let yearsAgo = calendar.dateComponents([.year], from: list.latestNotificationTime, to: Date())
////            if (yearsAgo.year)! > 0 {
////                formatter.dateFormat = "MMM d yy"
////            } else {
////                formatter.dateFormat = "MMM d"
////            }
//
//            if (yearsAgo.year)! > 0 {
////                formatter.dateFormat = "mm/dd/yy"
//                formatter.dateFormat = "MMM d yy"
//            } else {
//                formatter.dateFormat = "MMM d"
//            }
//
//            let daysAgo =  calendar.dateComponents([.day], from: list.latestNotificationTime, to: Date())
//            var postDateString: String? = ""
//
//            // If Post Date < 7 days ago, show < 7 days, else show date
//            if (daysAgo.day)! <= 7 {
//                postDateString = list.latestNotificationTime.timeAgoDisplay()
//            } else if (daysAgo.day)! <= 31 {
//                let dateDisplay = formatter.string(from: list.latestNotificationTime)
//                postDateString = dateDisplay
//            } else {
//                postDateString = ""
//            }
//
//            if postDateString != "" {
//                let listDateString = NSMutableAttributedString(string: "\nUpdated: \(postDateString!)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13)])
//                socialStats.append(listDateString)
//            }
//        }

        socialStatsLabel.attributedText = socialStats
        socialStatsLabel.sizeToFit()
    }
    
    func setupFollowButton(){
        
        if user?.uid == Auth.auth().currentUser?.uid {
            self.followButton.isHidden = true
        }
        
        if (user?.isFollowing)!{
            self.followButton.setTitle("Unfollow", for: .normal)
            self.followButton.backgroundColor = UIColor.orange
        } else {
            self.followButton.setTitle("Follow", for: .normal)
            self.followButton.backgroundColor = UIColor.mainBlue()
            
        }
    }
    
    @objc func didTapCell(){
        if cellType == DiscoverUser {
            guard let userId = self.user?.uid else {return}
            self.delegate?.extTapUser(userId: userId)
        } else if cellType == DiscoverList {
            guard let tempList = self.list else {return}
            self.delegate?.extTapList(list: tempList)
        } else if cellType == DiscoverPlaces {
            guard let tempLoc = self.location else {return}
            self.delegate?.goToLocation(location: tempLoc)
        } else if cellType == DiscoverCities {
            guard let tempCity = self.city else {return}
            self.delegate?.showCity(city: tempCity)
        }
    }
    
    @objc func didTapUser(){
        guard let userId = self.user?.uid else {return}
        self.delegate?.extTapUser(userId: userId)
    }
    
    @objc func handleFollow(){
        
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else {return}
        guard let userId = user?.uid else {return}
        print("handleFollow: ", user?.username ?? "", userId)
        if currentLoggedInUserId == userId {return}
        
        Database.handleFollowing(userUid: userId) { }
        guard let user = self.user else {return}
        var tempUser = user
        tempUser.isFollowing = !(tempUser.isFollowing)!
        self.user = tempUser
        self.setupFollowButton()
        
    }
    
    override var isSelected: Bool {
        didSet {
//            self.backgroundColor = self.isSelected ? UIColor.mainBlue().withAlphaComponent(0.4) : UIColor.white
//            cellView.backgroundColor = self.isSelected ? UIColor.mainBlue().withAlphaComponent(0.4) : UIColor.white
        }
    }
    
//    override func setSelected(_ selected: Bool, animated: Bool) {
////        self.isSelected = selected
//        print("\(self.isSelected) \(list?.name)")
//    }
    
    var cellHeight: NSLayoutConstraint?

    
    let cellView = UIView()
    var imageWidthConstraint: NSLayoutConstraint?
    var imageWidth: CGFloat = 60.0

    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        let bgColorView = UIView()
//        bgColorView.backgroundColor = UIColor.mainBlue().withAlphaComponent(0.4)
//        self.selectedBackgroundView = bgColorView
        
        addSubview(cellView)
        cellView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        cellHeight = cellView.heightAnchor.constraint(equalToConstant: 80)
        cellHeight?.isActive = true
        cellView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapCell)))
        
        cellView.addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: nil, bottom: bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 8, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapUser)))
        imageWidthConstraint = profileImageView.widthAnchor.constraint(equalToConstant: imageWidth)
//        imageWidthConstraint?.isActive = true
        profileImageView.widthAnchor.constraint(equalTo: profileImageView.heightAnchor, multiplier: 1).isActive = true

//        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        profileImageView.layer.cornerRadius = 60/2
        
//        let detailView = UIView()
//        addSubview(detailView)
//        detailView.anchor(top: profileImageView.topAnchor, left: leftAnchor, bottom: profileImageView.bottomAnchor, right: profileImageView.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

        
        cellView.addSubview(headerLabel)
        headerLabel.anchor(top: profileImageView.topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 15, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        headerLabel.rightAnchor.constraint(lessThanOrEqualTo: profileImageView.leftAnchor, constant: 15).isActive = true
        headerLabel.isUserInteractionEnabled = true
        headerLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapCell)))
        headerLabel.adjustsFontSizeToFitWidth = true
        
//        addSubview(emojiLabel)
//        emojiLabel.anchor(top: usernameLabel.topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 1, paddingLeft: 10, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
//        emojiLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
//        cellView.addSubview(emojiArray)
//        emojiArray.anchor(top: headerLabel.topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 1, paddingLeft: 10, paddingBottom: 0, paddingRight: 5, width: 0, height: 30)
//        emojiArray.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
//        emojiArray.delegate = self
//        emojiArray.alignment = .right
//        emojiArray.backgroundColor = UIColor.clear
//        emojiArray.isHidden = true
                
        cellView.addSubview(altTextLabel)
        altTextLabel.anchor(top: headerLabel.bottomAnchor, left: headerLabel.leftAnchor, bottom: nil, right: nil, paddingTop: 6, paddingLeft: 20, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)

//        altTextLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
//        altTextLabel.isHidden = true
        altTextLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapCell)))

        
//        cellView.addSubview(subHeaderLabel)
//        subHeaderLabel.anchor(top: altTextLabel.bottomAnchor, left: headerLabel.leftAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
//        subHeaderLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapCell)))
//
//
//        cellView.addSubview(subHeaderIcon)
//        subHeaderIcon.anchor(top: nil, left: subHeaderLabel.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 2, paddingBottom: 0, paddingRight: 0, width: 15, height: 15)
//        subHeaderIcon.centerYAnchor.constraint(equalTo: subHeaderLabel.centerYAnchor).isActive = true
        
        
        cellView.addSubview(socialStatsLabel)
//        socialStatsLabel.anchor(top: subHeaderLabel.bottomAnchor, left: headerLabel.leftAnchor, bottom: nil, right: followButton.leftAnchor, paddingTop: 1, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        socialStatsLabel.anchor(top: nil, left: nil, bottom: profileImageView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)

        socialStatsLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapCell)))
        socialStatsLabel.isHidden = true

        
//        let separatorView = UIView()
//        separatorView.backgroundColor = UIColor(white: 0, alpha: 0.5)
//        addSubview(separatorView)
//        separatorView.anchor(top: cellView.bottomAnchor, left: usernameLabel.leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
//        cellView.addSubview(emojiDetailLabel)
//        emojiDetailLabel.anchor(top: nil, left: nil, bottom: nil, right: emojiArray.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
//        emojiDetailLabel.centerYAnchor.constraint(equalTo: emojiArray.centerYAnchor).isActive = true
//        emojiDetailLabel.sizeToFit()
//        self.hideEmojiDetailLabel()
        
        
//        addSubview(altView)
//        altView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        altView.backgroundColor = UIColor.backgroundGrayColor().withAlphaComponent(0.8)
//
//        altView.addSubview(emailButton)
//        emailButton.anchor(top: nil, left: altView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 25, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        emailButton.centerYAnchor.constraint(equalTo: altView.centerYAnchor).isActive = true
//        emailButton.sizeToFit()
//        altView.isHidden = true
    }
    
    
    func hideEmojiDetailLabel(){
        self.emojiDetailLabel.alpha = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
 
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.list = nil
        self.user = nil
        self.location = nil
        imageWidthConstraint?.constant = imageWidth

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
