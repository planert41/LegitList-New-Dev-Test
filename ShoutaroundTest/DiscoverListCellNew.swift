//
//  UserCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 11/15/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

import SVProgressHUD
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

protocol DiscoverListCellNewDelegate {
    func goToList(list:List?, filter:String?)
    func goToPost(postId: String, ref_listId: String?, ref_userId: String?)
    func displayListFollowingUsers(list: List, following: Bool)
    func refreshAll()
    func goToUser(userId: String?)
}

class DiscoverListCellNew: UITableViewCell, EmojiButtonArrayDelegate, UICollectionViewDataSource, UICollectionViewDelegate, GridPhotoOnlyCellDelegate, UICollectionViewDelegateFlowLayout, DiscoverListDetailsCellDelegate {
    
    
    var delegate: DiscoverListCellNewDelegate?
    
    var emojiArrayHideConstraint:NSLayoutConstraint?
    var profileImageHideConstraint:NSLayoutConstraint?
    var profileImageShowConstraint:NSLayoutConstraint?

    var list: List?{
        didSet {
            
            guard let list = list else {
                return
            }

            if let displayEmojis = self.list?.topEmojis{
                emojiArray.emojiLabels = Array(displayEmojis.prefix(3))
                emojiArrayHideConstraint?.isActive = false
            } else {
                emojiArray.emojiLabels = []
                emojiArrayHideConstraint?.isActive = true
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
            
            loadProfileImage()
            setupSocialStatsLabel()
            setupLastDateLabel()
            setupListFollowButton()
            setupBackgroundImage()
            
            //            self.paginatePosts()
            self.listCollectionView.reloadData()
        }
    }
    
    func setupBackgroundImage(){
        if let image = self.list?.heroImage {
            self.backgroundImageView.image = image
        } else if let url = self.list?.heroImageUrl {
            self.backgroundImageView.loadImage(urlString: url)
        } else if let url = self.list?.listImageUrls[0] {
            self.backgroundImageView.loadImage(urlString: url)
        } else {
            self.backgroundImageView.image = #imageLiteral(resourceName: "Legit_Vector")
            self.backgroundImageView.backgroundColor = UIColor.lightGray
        }
    }
    
    let backgroundImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor.lightBackgroundGrayColor()
        return iv
    }()
    
    let userProfileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        return iv
    }()
    
    var refUser: User? = nil {
        didSet {
        }
    }
    
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
        
        let dateLabel = NSAttributedString(string: "\(dateDisplay)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.italicSystemFont(ofSize: 11),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.gray]))
        displayText.append(dateLabel)
        
        
        self.lastDateLabel.attributedText = displayText
        self.lastDateLabel.sizeToFit()
        self.lastDateLabel.isHidden = false
        
    }
    
    // FOLLOW UNFOLLOW BUTTON
    lazy var listFollowButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Follow List", for: .normal)
        button.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        button.titleLabel?.font =  UIFont(name: "Poppins-Regular", size: 12)
        button.layer.borderColor = UIColor.mainBlue().cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 5
        button.backgroundColor = UIColor.white
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.addTarget(self, action: #selector(handleFollowingList), for: .touchUpInside)
        return button
    }()
    
    @objc func handleFollowingList(){
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        guard let followingList = list else {
            print("List | handleFollowingList ERROR | No List to Follow")
            return
        }
        
        guard let followingListId = followingList.id else {
            print("List | handleFollowingList ERROR | No List ID")
            return
        }
        
        if CurrentUser.followedListIds.contains(followingListId) {
            Database.handleUnfollowList(userUid: uid, followedList: followingList) {
                SVProgressHUD.showSuccess(withStatus: "Unfollowed \(followingList.name)")
                SVProgressHUD.dismiss(withDelay: 1)
                self.delegate?.refreshAll()
                //                self.setupListFollowButton()
                //                self.alert(title: "", message: "\((list.name)!) List UnFollowed")
            }
        } else {
            Database.handleFollowingList(userUid: uid, followedList: followingList) {
                SVProgressHUD.showSuccess(withStatus: "Followed \(followingList.name)")
                SVProgressHUD.dismiss(withDelay: 1)
                self.delegate?.refreshAll()
                
                //                self.setupListFollowButton()
                //                self.alert(title: "", message: "\((list.name)!) List Followed")
            }
        }
    }
    
    func setupListFollowButton() {
        self.listFollowButton.isHidden = self.list?.creatorUID == Auth.auth().currentUser?.uid
        guard let list = list else {return}
        if CurrentUser.followedListIds.contains((list.id)!){
            listFollowButton.setTitle("Following", for: .normal)
            listFollowButton.setTitleColor(UIColor.ianLegitColor(), for: .normal)
            listFollowButton.layer.borderColor = UIColor.ianLegitColor().cgColor
            listFollowButton.backgroundColor = UIColor.white 


        } else {
            listFollowButton.setTitle("Follow", for: .normal)
            listFollowButton.setTitleColor(UIColor.white, for: .normal)
            listFollowButton.layer.borderColor = UIColor.white.cgColor
            listFollowButton.backgroundColor = UIColor.ianLegitColor()

        }
        listFollowButton.sizeToFit()
    }
    
    
    var listUser: User? {
        didSet {
            guard let profileImageUrl = listUser?.profileImageUrl else {return}
            usernameLabel.text = listUser?.username
            self.loadProfileImage()
        }
    }
    
    var notificationPostIds:[String] = []
    
    func setupListName(){
        
        guard let list = list else {
            return
        }
        
        let listNameText = NSMutableAttributedString()
        
        let textColor = (self.backgroundImageView.image == UIImage()) ? UIColor.darkLegitColor() : UIColor.white
        
        
        
        let listNameString = NSMutableAttributedString(string: (list.name) + " ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.ianLegitColor(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Poppins-Bold", size: 18)]))
        listNameText.append(listNameString)
        let imageSize = CGSize(width: socialStatsFontSize, height: socialStatsFontSize)
        
        
        
        if (list.name) == legitListName {
            let image1Attachment = NSTextAttachment()
            guard let inputImage = #imageLiteral(resourceName: "legit_large").resizeVI(newSize: CGSize(width: 25, height: 25)) else {return}
            image1Attachment.image = inputImage
            
            image1Attachment.bounds = CGRect(x: 0, y: (listnameLabel.font.capHeight - (inputImage.size.height)).rounded() / 2, width: inputImage.size.width, height: inputImage.size.height)
            
            let image1String = NSAttributedString(attachment: image1Attachment)
            listNameText.append(image1String)
        }
            
        else if (list.name) == bookmarkListName {
            let image1Attachment = NSTextAttachment()
            let inputImage = #imageLiteral(resourceName: "bookmark_filled")
            image1Attachment.image = inputImage
            
            image1Attachment.bounds = CGRect(x: 0, y: (listnameLabel.font.capHeight - (inputImage.size.height)).rounded() / 2, width: inputImage.size.width, height: inputImage.size.height)
            
            let image1String = NSAttributedString(attachment: image1Attachment)
            listNameText.append(image1String)
        }

        
        
        // ADD USERNAME TO LIST NAME
        //        if let username = self.listUser?.username {
        //            if username != refUser?.username {
        //                let postCountString = NSMutableAttributedString(string: " \(username) ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.gray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 12)]))
        //                listNameText.append(postCountString)
        //            }
        //        }
        
        listnameLabel.attributedText = listNameText
        listnameLabel.sizeToFit()
        
        followerCountLabel.text = ""
        if let followerCount = self.list?.followerCount {
            if followerCount > 0 {
                let postCountString = NSMutableAttributedString(string: "\(followerCount) Followers \n", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.gray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 15)]))
                //                followerCountLabel.attributedText = postCountString
            }
        }
        followerCountLabel.sizeToFit()
        
    }
    
    func loadProfileImage(){

        if self.list?.creatorUID == refUser?.uid || self.list?.creatorUID == Auth.auth().currentUser?.uid
        {
            self.userProfileImageView.isHidden = true
        }
        else if let profileImageUrl = listUser?.profileImageUrl
        {
            userProfileImageView.loadImage(urlString: profileImageUrl)
            self.userProfileImageView.isHidden = false
        } else
        {
            self.userProfileImageView.isHidden = true
        }
//        print("DiscoverListCellNew | \((listUser?.username)) | \((list?.name)) | \((self.hideProfileImage))")

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
    
    lazy var listCollectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = .white
        return cv
    }()
    
    let cellId = "CellId"
    let listDetailId = "ListDetailId"

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
        label.textColor = UIColor.white
        label.numberOfLines = 1
        label.backgroundColor = UIColor.ianLegitColor()
        label.backgroundColor = UIColor.clear
        label.layer.cornerRadius = 3
        label.layer.masksToBounds = true
        return label
    }()
    
    let followerCountLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.textColor = UIColor.gray
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.adjustsFontSizeToFitWidth = true
        label.isUserInteractionEnabled = true
        label.textAlignment = NSTextAlignment.center
        //        label.numberOfLines = 0
        return label
    }()
    
    let largeFollowerCountLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.textColor = UIColor.gray
        label.font = UIFont.boldSystemFont(ofSize: 14)
//        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 2
        label.isUserInteractionEnabled = true
        label.textAlignment = NSTextAlignment.right
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
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
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
        let socialStats = NSMutableAttributedString()
        
        socialStatsLabel.font = UIFont.systemFont(ofSize: socialStatsFontSize)
        let imageSize = CGSize(width: socialStatsFontSize, height: socialStatsFontSize)
        
        
// NEW NOTIFICATIONS
        if let newNotCount = self.list?.newNotificationsCount, self.list?.newNotificationsCount ?? 0 > 0  {
            let newNotificationString = NSMutableAttributedString(string: String(newNotCount) + " New  ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.red, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .helveticaNeueBold, size: socialStatsFontSize + 1)]))
            socialStats.append(newNotificationString)
        }
        
// POST COUNT
        if let postCount = self.list?.postIds?.count {
            if postCount > 0 {
                let postCountString = NSMutableAttributedString(string: "\(postCount) Posts ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.ianBlackColor(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Poppins-Regular", size: socialStatsFontSize)]))
                socialStats.append(postCountString)

            }
        }

        socialStatsLabel.attributedText = socialStats
        socialStatsLabel.sizeToFit()
        
// FOLLOWER COUNT
        
        let followerStats = NSMutableAttributedString()
        if let followerCount = self.list?.followerCount {
            if followerCount > 0 {
                var displayString = "\(followerCount)  " + ((followerCount == 1) ? "Follower" : "Followers")
                
                let postCountString = NSMutableAttributedString(string: displayString, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Poppins-Bold", size: socialStatsFontSize)]))
                followerStats.append(postCountString)
            }
        }
        followerCountLabel.attributedText = followerStats
        followerCountLabel.sizeToFit()

        let largeFollowerStats = NSMutableAttributedString()
        if let followerCount = self.list?.followerCount {
            if followerCount > 0 {
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineSpacing = 50
                
                
                let countString = NSMutableAttributedString(string: String(followerCount), attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Poppins-Bold", size: 20)]))
//                countString.addAttribute(.paragraphStyle, value:paragraph, range:NSMakeRange(0, countString.length))

                largeFollowerStats.append(countString)

                
                var displayString = ((followerCount == 1) ? "Follower" : "Followers")
                let postCountString = NSMutableAttributedString(string: "\n" + displayString, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.ianLegitColor(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .avenirHeavy, size: 14)]))
//                postCountString.addAttribute(.paragraphStyle, value:paragraph, range:NSMakeRange(0, postCountString.length))

                largeFollowerStats.append(postCountString)
            }
        }
        
        largeFollowerCountLabel.attributedText = largeFollowerStats
        largeFollowerCountLabel.sizeToFit()
        
        self.followerCountLabel.isHidden = self.list?.creatorUID == Auth.auth().currentUser?.uid
        self.largeFollowerCountLabel.isHidden = !self.followerCountLabel.isHidden

        
        
        
        //        socialStatsLabel.backgroundColor = UIColor.yellow
        
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
        
        
    }
    
    var enableSelection = true
    
    override var isSelected: Bool {
        didSet {
            if enableSelection {
                self.backgroundColor = self.isSelected ? UIColor.mainBlue().withAlphaComponent(0.2) : UIColor.white
            } else {
                self.backgroundColor = UIColor.white
            }
        }
    }
    
    let listIndLabel: UIButton = {
        let label = UIButton()
        return label
    }()
    
    var hideProfileImage: Bool? {
        didSet {
            guard let hideProfileImage = hideProfileImage else {return}
            if hideProfileImage {
//                profileImageHideConstraint?.isActive = true
                self.profileImageView.isHidden = true
            } else {
//                profileImageHideConstraint?.isActive = false
                self.profileImageView.isHidden = false
            }
            self.layoutIfNeeded()
        }
    }
    
    let scrollLabel: UILabel = {
        let label = UILabel()
        label.text = "Scroll For More >>>"
        label.textColor = UIColor.lightGray
        label.font = UIFont.boldSystemFont(ofSize: 10)
        label.numberOfLines = 0
        return label
    }()
    
    var showScrollLabel = false {
        didSet {
            self.scrollLabel.isHidden = showScrollLabel
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let cellView = UIView()
        addSubview(cellView)
        cellView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 210)
        cellView.backgroundColor = UIColor.white
        
        addSubview(backgroundImageView)
        backgroundImageView.anchor(top: cellView.topAnchor, left: cellView.leftAnchor, bottom: nil, right: cellView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 160)
        backgroundImageView.image = UIImage()
        backgroundImageView.layer.cornerRadius = 2
        backgroundImageView.layer.masksToBounds = true
        
//        let topDiv = UIView()
//        addSubview(topDiv)
//        topDiv.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        topDiv.backgroundColor = UIColor.lightGray

// LIST COLLECTIONVIEW
        addSubview(listCollectionView)
        listCollectionView.anchor(top: backgroundImageView.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: -30, paddingLeft: 0, paddingBottom: 20, paddingRight: 0, width: 0, height: 80)
        listCollectionView.sizeToFit()
        setupListCollectionView()
        
        addSubview(scrollLabel)
        scrollLabel.anchor(top: nil, left: nil, bottom: listCollectionView.bottomAnchor, right: listCollectionView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        scrollLabel.sizeToFit()
        scrollLabel.isHidden = true
        
//        let gradientMaskLayer:CAGradientLayer = CAGradientLayer()
//        gradientMaskLayer.frame = scrollLabel.bounds
//        gradientMaskLayer.colors = [UIColor.clear.cgColor, UIColor.red.cgColor, UIColor.red.cgColor, UIColor.clear.cgColor ]
//        gradientMaskLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
//        gradientMaskLayer.endPoint = CGPoint(x: 1, y: 0.5)
//        scrollLabel.layer.mask = gradientMaskLayer
        
        UIView.animate(withDuration: 2, delay: 0, options: [.repeat,.autoreverse], animations: {
            self.scrollLabel.alpha = 0.0
            let gradientMaskLayer:CAGradientLayer = CAGradientLayer()
            gradientMaskLayer.frame = self.scrollLabel.bounds
            gradientMaskLayer.colors = [UIColor.clear.cgColor, UIColor.red.cgColor, UIColor.red.cgColor, UIColor.clear.cgColor ]
            gradientMaskLayer.startPoint = CGPoint(x: 0.0, y: 0)
            gradientMaskLayer.endPoint = CGPoint(x: 1, y: 1)
            self.scrollLabel.layer.mask = gradientMaskLayer
        }, completion: nil)
        
//        let gradientMaskLayer:CAGradientLayer = CAGradientLayer()
//        gradientMaskLayer.frame = scrollLabel.bounds
//        gradientMaskLayer.colors = [UIColor.clear.cgColor, UIColor.red.cgColor, UIColor.red.cgColor, UIColor.clear.cgColor ]
//        gradientMaskLayer.startPoint = CGPoint(x: 0.1, y: 0.0)
//        gradientMaskLayer.endPoint = CGPoint(x: 0.55, y: 0.0)
//        scrollLabel.layer.mask = gradientMaskLayer
        
        addSubview(userProfileImageView)
        userProfileImageView.anchor(top: backgroundImageView.topAnchor, left: listCollectionView.leftAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
        userProfileImageView.layer.cornerRadius = 40/2
        userProfileImageView.layer.masksToBounds = true
        userProfileImageView.isUserInteractionEnabled = true
        userProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileImageTapped)))
        userProfileImageView.layer.borderColor = UIColor.white.cgColor
        userProfileImageView.layer.borderWidth = 2
        userProfileImageView.isHidden = true

        
// LIST DETAILS
//        let listDetailView = UIView()
//        addSubview(listDetailView)
//        listDetailView.anchor(top: topAnchor, left: leftAnchor, bottom: listCollectionView.topAnchor, right: rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
//
//
//        addSubview(listFollowButton)
//        listFollowButton.anchor(top: listDetailView.topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 80, height: 25)
//

//        profileImageHideConstraint = userProfileImageView.widthAnchor.constraint(equalToConstant: 0)

        
//        addSubview(listnameLabel)
//        listnameLabel.anchor(top: listDetailView.topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 15, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
//        listnameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: self.frame.width - 120).isActive = true
//
//        addSubview(userProfileImageView)
//        userProfileImageView.anchor(top: nil, left: listnameLabel.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 25, height: 25)
//        userProfileImageView.rightAnchor.constraint(lessThanOrEqualTo: listFollowButton.leftAnchor, constant: 10)
//        userProfileImageView.centerYAnchor.constraint(equalTo: listnameLabel.centerYAnchor).isActive = true
//
//        userProfileImageView.layer.cornerRadius = 25/2
//        userProfileImageView.layer.masksToBounds = true
//        userProfileImageView.isUserInteractionEnabled = true
//        userProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileImageTapped)))
        
//        profileImageHideConstraint = listnameLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 10)
//        profileImageShowConstraint = listnameLabel.leftAnchor.constraint(equalTo: userProfileImageView.rightAnchor, constant: 5)
//        profileImageShowConstraint?.isActive = true
        
        
//        listnameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: self.frame.width * (2 / 3)).isActive = true
        

//        listFollowButton.centerYAnchor.constraint(equalTo: listnameLabel.centerYAnchor).isActive = true

        
//        addSubview(emojiArray)
//        emojiArray.anchor(top: nil, left: listnameLabel.leftAnchor, bottom: listDetailView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 20)
//        //        emojiArray.rightAnchor.constraint(lessThanOrEqualTo: followerCountLabel.leftAnchor).isActive = true
////        emojiArray.centerYAnchor.constraint(equalTo: socialStatsLabel.centerYAnchor).isActive = true
//        emojiArray.delegate = self
//        emojiArray.alignment = .left
//        emojiArray.backgroundColor = UIColor.clear
//        emojiArrayHideConstraint = emojiArray.widthAnchor.constraint(equalToConstant: 0)

//        addSubview(socialStatsLabel)
//        socialStatsLabel.anchor(top: nil, left: listnameLabel.leftAnchor, bottom: listDetailView.bottomAnchor, right: nil, paddingTop: 1, paddingLeft: 0, paddingBottom: 2, paddingRight: 0, width: 0, height: 15)
////        socialStatsLabel.leftAnchor.constraint(lessThanOrEqualTo: listnameLabel.leftAnchor).isActive = true
//
//
//        addSubview(followerCountLabel)
//        followerCountLabel.anchor(top: nil, left: nil, bottom: listDetailView.bottomAnchor, right: nil, paddingTop: 1, paddingLeft: 0, paddingBottom: 2, paddingRight: 0, width: 0, height: 15)
//        followerCountLabel.centerXAnchor.constraint(equalTo: listFollowButton.centerXAnchor).isActive = true
//        followerCountLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(followerCountTapped)))
//
//
//        addSubview(largeFollowerCountLabel)
//        largeFollowerCountLabel.anchor(top: listnameLabel.topAnchor, left: nil, bottom: listDetailView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        largeFollowerCountLabel.centerXAnchor.constraint(equalTo: listFollowButton.centerXAnchor).isActive = true
//        largeFollowerCountLabel.isHidden = true
////        largeFollowerCountLabel.backgroundColor = UIColor.yellow
//        largeFollowerCountLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(followerCountTapped)))
//
//        addSubview(emojiArray)
//        emojiArray.anchor(top: nil, left: socialStatsLabel.rightAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 3, paddingBottom: 0, paddingRight: 10, width: 0, height: 20)
////        emojiArray.rightAnchor.constraint(lessThanOrEqualTo: followerCountLabel.leftAnchor).isActive = true
//        emojiArray.centerYAnchor.constraint(equalTo: socialStatsLabel.centerYAnchor).isActive = true
//        emojiArray.delegate = self
//        emojiArray.alignment = .left
//        emojiArray.backgroundColor = UIColor.clear
//        emojiArrayHideConstraint = emojiArray.widthAnchor.constraint(equalToConstant: 0)


//        let separatorView = UIView()
//        separatorView.backgroundColor = UIColor(white: 0, alpha: 0.5)
//        addSubview(separatorView)
//        separatorView.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
        
        
        //        addSubview(listFollowButton)
        //        listFollowButton.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 25)
        //        setupListFollowButton()

        //        addSubview(followerCountLabel)
        //        followerCountLabel.anchor(top: nil, left: listnameLabel.rightAnchor, bottom: listnameLabel.bottomAnchor, right: emojiArray.leftAnchor, paddingTop: 0, paddingLeft: 3, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        //
        //        let followerTap = UITapGestureRecognizer(target: self, action: #selector(followerCountTapped))
        //        followerCountLabel.addGestureRecognizer(followerTap)
        //        listnameLabel.rightAnchor.constraint(lessThanOrEqualTo: listFollowButton.leftAnchor).isActive = true
        
        //        addSubview(lastDateLabel)
        //        lastDateLabel.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        //        lastDateLabel.centerYAnchor
        //        lastDateLabel.leftAnchor.constraint(lessThanOrEqualTo: listnameLabel.rightAnchor).isActive = true
        //        lastDateLabel.sizeToFit()
        
        
//        addSubview(emojiDetailLabel)
//        emojiDetailLabel.anchor(top: nil, left: nil, bottom: nil, right: emojiArray.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
//        emojiDetailLabel.centerYAnchor.constraint(equalTo: emojiArray.centerYAnchor).isActive = true
//        emojiDetailLabel.sizeToFit()
//        self.hideEmojiDetailLabel()
    }
    
    @objc func profileImageTapped(){
        guard let user = listUser else {return}
        self.delegate?.goToUser(userId: user.uid)
    }
    
    @objc func followerCountTapped(){
        guard let list = list else {return}
        self.delegate?.displayListFollowingUsers(list: list, following: true)
    }
    
    
    
    func setupListCollectionView(){
        listCollectionView.register(GridPhotoOnlyCell.self, forCellWithReuseIdentifier: cellId)
        listCollectionView.register(DiscoverListDetailsCell.self, forCellWithReuseIdentifier: listDetailId)
        let layout = ListDisplayFlowLayout()
        layout.minimumLineSpacing = 5
        listCollectionView.collectionViewLayout = layout
        listCollectionView.backgroundColor = UIColor.clear
        listCollectionView.isScrollEnabled = true
        listCollectionView.showsHorizontalScrollIndicator = false
        listCollectionView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
//        listCollectionView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
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
    
    func scrollToFirst(){
        self.listCollectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .left, animated: true)
    }
    
    func listDetailTapped(){
        self.delegate?.goToList(list: list, filter: nil)
    }
    
    func doubleTapEmoji(index: Int?, emoji: String) {
        self.delegate?.goToList(list: list, filter: emoji)
    }
    
    func gridPhotoLabelTapped() {
        self.handleFollowingList()
    }
    
    
    
    func goToPost(postId: String?){
        if let postId = postId {
            self.delegate?.goToPost(postId: postId, ref_listId: self.list?.id, ref_userId: nil)
        }
    }
    
    //    func didTapPicture(post: Post?) {
    //        if post == nil {
    //            // Maybe change this to show the post if picture is tapped
    //
    //            guard let list = self.list else {return}
    //            self.delegate?.goToList(list: list)
    //        }
    //    }
    
    var paginatePostsCount: Int = 0
    let paginateFetchPostSize = 5
    var finishPaging = false
    
    
    @objc func paginatePosts(){
        let imageCount = self.list?.listImageUrls.count ?? 0
        if self.paginatePostsCount < imageCount && !self.finishPaging {
            self.paginatePostsCount = min(self.paginatePostsCount + self.paginateFetchPostSize, imageCount)
            print("PaginatePosts | Current Count \(self.paginatePostsCount)")
            listCollectionView.reloadData()
        } else {
            self.finishPaging = true
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let imageCount = self.list?.listImageUrls.count ?? 0
        let userIsCreator = self.list?.creatorUID == Auth.auth().currentUser?.uid
        
        if self.list?.creatorUID == Auth.auth().currentUser?.uid {
            return imageCount + 1
        } else if imageCount > 0 {
            return imageCount + 1 /*+ (self.listUser?.isFollowing ?? true ? 0 : 1)*/
        } else {
            //return 0
            return 1
        }
        
        //        return paginatePostsCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        //        if indexPath.item == self.paginatePostsCount - 1 && !self.finishPaging {
        ////            print("Image Paginate")
        //            paginatePosts()
        //        }]
        
        if indexPath.row == 0 {
            // First Cell shows list name etc
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: listDetailId, for: indexPath) as! DiscoverListDetailsCell
            cell.inputList = list
            cell.delegate = self
            return cell
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! GridPhotoOnlyCell
            var listImageUrl = self.list?.listImageUrls[indexPath.row - 1]
            var refPost = self.list?.listImagePostIds[indexPath.row - 1]
            cell.delegate = self
            cell.postIdLink = refPost
            cell.layer.borderWidth = 2
            cell.layer.borderColor = UIColor.white.cgColor
            cell.layer.applySketchShadow()
            cell.layer.cornerRadius = 2
            cell.layer.masksToBounds = true
            cell.imageUrl = listImageUrl
            
            cell.optionalHeight = 25
            cell.showBottomBuffer()
            
            // SHOW New Notification in first picture cell
            if indexPath.row == 1 {
//                cell.optionalHeight = 25
//                cell.showBottomBuffer()
                cell.optionalNewCount = self.list?.newNotificationsCount ?? 0
//                cell.optionalNewCount = 5
            } else {
                cell.optionalNewCount = nil
            }


            return cell
            
        }
        
        
        // ASSUME THE FIRST N PICS ARE THE MOST RECENTLY ADDED ONES - SET THAT WAY IN FIREBASE
        //            cell.photoImageView.layer.borderColor = (indexPath.row < self.list?.newNotificationsCount ?? 0) ? UIColor.selectedColor().cgColor : UIColor.clear.cgColor
        //            cell.photoImageView.layer.borderWidth = (indexPath.row < self.list?.newNotificationsCount ?? 0) ? 0 : 0
        //            cell.highlightCell = (indexPath.row < self.list?.newNotificationsCount ?? 0)
        //            cell.highlightCell = indexPath.row < (self.list?.newNotificationsCount ?? 0)
        //            cell.highlightCell = indexPath.row == 4
        
        /*else if indexPath.row == self.list?.listImageUrls.count {
         // LAST ROW - Only for empty Post
         let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! GridPhotoOnlyCell
         let listId = self.list?.id ?? "999"
         //            if indexPath.row == 0 {
         //                cell.showLabel(string: "No Posts")
         //                cell.label.layer.borderWidth = 0
         //            } else {
         //                if CurrentUser.followedListIds.contains(listId) {
         //                    cell.showLabel(string: "UnFollow")
         //                } else {
         //                    cell.showLabel(string: "Follow")
         //                }
         //                cell.label.layer.borderWidth = 1
         //            }
         
         cell.layer.borderWidth = 1
         cell.layer.borderColor = UIColor.white.cgColor
         cell.delegate = self
         
         return cell
         
         }*/
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.row == 0 {
            return CGSize(width: 70, height: 75)
        } else {
//            return CGSize(width: 50, height: 50)
            return CGSize(width: 50, height: 75)

        }
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    func refreshPagination() {
        self.paginatePostsCount = 0
        self.finishPaging = false
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        //        self.profileImageView.image = UIImage()
        self.userProfileImageView.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        self.userProfileImageView.isHidden = true
        self.listIndLabel.setImage(UIImage(), for: .normal)
        self.listnameLabel.text = ""
        self.followerCountLabel.text = ""
        self.socialStatsLabel.text = ""
        self.listUser = nil
        self.list = nil
        self.listCollectionView.reloadData()
        self.refreshPagination()
        self.enableSelection = false
        self.showScrollLabel = false
        
        
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
