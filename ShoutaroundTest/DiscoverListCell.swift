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

protocol DiscoverListCellDelegate {
    func goToList(list:List?, filter:String?)
    func goToPost(postId: String)
    func displayListFollowingUsers(list: List, following: Bool)
    func refreshAll()
}

class DiscoverListCell: UITableViewCell, EmojiButtonArrayDelegate, UICollectionViewDataSource, UICollectionViewDelegate, GridPhotoOnlyCellDelegate, UICollectionViewDelegateFlowLayout {
    

    var delegate: DiscoverListCellDelegate?
    
    var emojiArrayHideConstraint:NSLayoutConstraint?
    var profileImageHideConstraint:NSLayoutConstraint?

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
            
            loadListIndexImage()
            setupSocialStatsLabel()
            setupLastDateLabel()
            setupListFollowButton()

//            self.paginatePosts()
            self.listCollectionView.reloadData()
        }
    }
    
    let userProfileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        return iv
    }()
    
    var refUser: User? = nil {
        didSet {
            if self.list?.creatorUID == refUser?.uid {
                self.hideProfileImage = true
            }
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
        button.setTitleColor(.darkLegitColor(), for: .normal)
        button.layer.borderColor = UIColor.darkLegitColor().cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 10
        button.backgroundColor = UIColor.selectedColor()
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
            listFollowButton.backgroundColor = UIColor.legitColor()
            
        } else {
            listFollowButton.setTitle("Follow", for: .normal)
            listFollowButton.backgroundColor = UIColor.clear
        }
        listFollowButton.sizeToFit()
    }
    
    
    var listUser: User? {
        didSet {
            guard let profileImageUrl = listUser?.profileImageUrl else {return}
            usernameLabel.text = listUser?.username
            self.loadListIndexImage()
        }
    }
    
    var notificationPostIds:[String] = []
    
    func setupListName(){
        
        guard let list = list else {
            return
        }
        
        let listNameText = NSMutableAttributedString()
    
        
        let listNameString = NSMutableAttributedString(string: (list.name) + " ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkLegitColor(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .helveticaNeueBold, size: 18)]))
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
        
        notificationPostIds = []
        
        if list.newNotificationsCount > 0 {
            let newNotificationString = NSMutableAttributedString(string: String(list.newNotificationsCount) + " New", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.red, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .helveticaNeueBold, size: 14)]))
            listNameText.append(newNotificationString)
            
            
            
            
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
    
    func loadListIndexImage(){
        
        //        self.profileImageView.image = UIImage()
        //        self.profileImageView.backgroundColor = UIColor.clear
        
        if (list?.name)! == legitListName {
            //            listIndLabel.setImage(#imageLiteral(resourceName: "legit"), for: .normal)
            listIndLabel.setImage(#imageLiteral(resourceName: "legit_large"), for: .normal)
            
            listIndLabel.backgroundColor = UIColor.legitColor()
        }
            
        else if (list?.name)! == bookmarkListName {
            listIndLabel.setImage(#imageLiteral(resourceName: "bookmark_filled"), for: .normal)
            listIndLabel.backgroundColor = UIColor.selectedColor()
        }
            
        else if list?.publicList == 0 {
            listIndLabel.setImage(#imageLiteral(resourceName: "private"), for: .normal)
            listIndLabel.backgroundColor = UIColor.clear
        } else {
            guard let profileImageUrl = listUser?.profileImageUrl else {return}
            userProfileImageView.loadImage(urlString: profileImageUrl)
            
//            //            self.loadListProfileImage()
//            if self.listUser?.uid != refUser?.uid {
//                guard let profileImageUrl = listUser?.profileImageUrl else {return}
//                profileImageView.loadImage(urlString: profileImageUrl)
//                listIndLabel.setImage(profileImageView.image, for: .normal)
//            }
//            listIndLabel.backgroundColor = UIColor.clear
        }
        
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
        label.numberOfLines = 0
        return label
    }()
    
    let followerCountLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.textColor = UIColor.gray
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.adjustsFontSizeToFitWidth = true
        label.isUserInteractionEnabled = true
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
    
    
    let emojiLabel: UILabel = {
        let label = UILabel()
        label.text = "Emoji"
        label.font = UIFont.systemFont(ofSize: 14)
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
    
    let socialStatsFontSize:CGFloat = 14.0
    
    func setupSocialStatsLabel() {
        let socialStats = NSMutableAttributedString()
        
        socialStatsLabel.font = UIFont.systemFont(ofSize: socialStatsFontSize)
        let imageSize = CGSize(width: socialStatsFontSize, height: socialStatsFontSize)
        
        if let postCount = self.list?.postIds?.count {
            if postCount > 0 {
                let postCountString = NSMutableAttributedString(string: "\(postCount) Posts ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.gray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: socialStatsFontSize)]))
                socialStats.append(postCountString)
                
                //                let postCountString2 = NSMutableAttributedString(string: " Posts ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.gray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: socialStatsFontSize)]))
                //                socialStats.append(postCountString2)
            }
        }
        
        if let followerCount = self.list?.followerCount {
            if followerCount > 0 {
                let postCountString = NSMutableAttributedString(string: "\(followerCount) Followers ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.gray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: socialStatsFontSize)]))
                socialStats.append(postCountString)
            }
        }


//        followerCountLabel.sizeToFit()
        
        socialStatsLabel.attributedText = socialStats
        socialStatsLabel.sizeToFit()
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
                profileImageHideConstraint?.isActive = hideProfileImage
            } else {
                profileImageHideConstraint?.isActive = false
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let cellView = UIView()
        addSubview(cellView)
        cellView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 70)
        
        //        addSubview(profileImageView)
        //        profileImageView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 50, height: 50)
        //        //        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        //        profileImageView.layer.cornerRadius = 50/2
        
        
        //        addSubview(profileImageView)
        //        profileImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 50, height: 50)
        //        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        //        profileImageView.layer.cornerRadius = 50/2
        
        //        listIndLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        //        listIndLabel.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor).isActive = true
        
        
        addSubview(userProfileImageView)
        userProfileImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 45, height: 45)
        userProfileImageView.centerYAnchor.constraint(equalTo: cellView.centerYAnchor).isActive = true
        
        userProfileImageView.layer.cornerRadius = 45/2
        userProfileImageView.layer.masksToBounds = true
        profileImageHideConstraint = userProfileImageView.widthAnchor.constraint(equalToConstant: 0)
//        userProfileImageView.isHidden = true
        
        addSubview(emojiArray)
        emojiArray.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 30)
        emojiArray.centerYAnchor.constraint(equalTo: userProfileImageView.centerYAnchor).isActive = true
        emojiArray.delegate = self
        emojiArray.alignment = .right
        emojiArray.backgroundColor = UIColor.clear
        emojiArrayHideConstraint = emojiArray.widthAnchor.constraint(equalToConstant: 0)
        
        
        
//        addSubview(listFollowButton)
//        listFollowButton.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 25)
//        setupListFollowButton()
        
        addSubview(listnameLabel)
        listnameLabel.anchor(top: userProfileImageView.topAnchor, left: userProfileImageView.rightAnchor, bottom: nil, right: emojiArray.leftAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        
//        addSubview(followerCountLabel)
//        followerCountLabel.anchor(top: nil, left: listnameLabel.rightAnchor, bottom: listnameLabel.bottomAnchor, right: emojiArray.leftAnchor, paddingTop: 0, paddingLeft: 3, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//
//        let followerTap = UITapGestureRecognizer(target: self, action: #selector(followerCountTapped))
//        followerCountLabel.addGestureRecognizer(followerTap)
//        listnameLabel.rightAnchor.constraint(lessThanOrEqualTo: listFollowButton.leftAnchor).isActive = true
        
        
        addSubview(socialStatsLabel)
        socialStatsLabel.anchor(top: listnameLabel.bottomAnchor, left: listnameLabel.leftAnchor, bottom: userProfileImageView.bottomAnchor, right: emojiArray.leftAnchor, paddingTop: 1, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 15)
        
        
//        addSubview(lastDateLabel)
//        lastDateLabel.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
//        lastDateLabel.centerYAnchor
//        lastDateLabel.leftAnchor.constraint(lessThanOrEqualTo: listnameLabel.rightAnchor).isActive = true
//        lastDateLabel.sizeToFit()
        

        addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top: nil, left: nil, bottom: nil, right: emojiArray.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        emojiDetailLabel.centerYAnchor.constraint(equalTo: emojiArray.centerYAnchor).isActive = true
        emojiDetailLabel.sizeToFit()
        self.hideEmojiDetailLabel()
        
        addSubview(listCollectionView)
//        listCollectionView.anchor(top: cellView.bottomAnchor, left: listnameLabel.leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        listCollectionView.anchor(top: cellView.bottomAnchor, left: userProfileImageView.leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

        
        
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        addSubview(separatorView)
        separatorView.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
        
        
        setupListCollectionView()
        
        
    }
    
    @objc func followerCountTapped(){
        guard let list = list else {return}
       self.delegate?.displayListFollowingUsers(list: list, following: true)
    }
    
    func setupListCollectionView(){
        listCollectionView.register(GridPhotoOnlyCell.self, forCellWithReuseIdentifier: cellId)
        let layout = ListDisplayFlowLayout()
        listCollectionView.collectionViewLayout = layout
        listCollectionView.backgroundColor = UIColor.clear
        listCollectionView.isScrollEnabled = true
        listCollectionView.showsHorizontalScrollIndicator = false
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
    
    func doubleTapEmoji(index: Int?, emoji: String) {
        self.delegate?.goToList(list: list, filter: emoji)
    }
    
    func gridPhotoLabelTapped() {
        self.handleFollowingList()
    }
    

    
    func goToPost(postId: String?){
        if let postId = postId {
            self.delegate?.goToPost(postId: postId)
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
        
        if imageCount > 0 {
            return imageCount + (self.listUser?.isFollowing ?? true ? 0 : 1)
        } else {
            return self.list?.creatorUID == Auth.auth().currentUser?.uid ? 1 : 0
        }
        
//        return paginatePostsCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

//        if indexPath.item == self.paginatePostsCount - 1 && !self.finishPaging {
////            print("Image Paginate")
//            paginatePosts()
//        }]
        

        /*if indexPath.row == self.list?.listImageUrls.count {
            // LAST ROW
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! GridPhotoOnlyCell
            let listId = self.list?.id ?? "999"
            if indexPath.row == 0 {
                cell.showLabel(string: "No/n Posts")
                cell.label.layer.borderWidth = 0
            } else {
                if CurrentUser.followedListIds.contains(listId) {
                    cell.showLabel(string: "UnFollow")
                } else {
                    cell.showLabel(string: "Follow")
                }
                cell.label.layer.borderWidth = 1
            }
            
            cell.delegate = self

            return cell
            
        } else {*/
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! GridPhotoOnlyCell
            var listImageUrl = self.list?.listImageUrls[indexPath.row]
            var refPost = self.list?.listImagePostIds[indexPath.row]
            cell.delegate = self
            cell.postIdLink = refPost
            
            cell.imageUrl = listImageUrl
            
            // ASSUME THE FIRST N PICS ARE THE MOST RECENTLY ADDED ONES - SET THAT WAY IN FIREBASE
            cell.label.layer.borderColor = (indexPath.row < self.list?.newNotificationsCount ?? 0) ? UIColor.ianLegitColor().cgColor : UIColor.clear.cgColor
            cell.label.layer.borderWidth = (indexPath.row < self.list?.newNotificationsCount ?? 0) ? 5 : 0
            cell.highlightCell = indexPath.row < (self.list?.newNotificationsCount ?? 0)
//            cell.highlightCell = indexPath.row == 4
            return cell

        //}
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: 80, height: 80)
        
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
        self.userProfileImageView.image = UIImage()
        self.listIndLabel.setImage(UIImage(), for: .normal)
        self.listnameLabel.text = ""
        self.followerCountLabel.text = ""
        self.socialStatsLabel.text = ""
        self.listUser = nil
        self.list = nil
        self.listCollectionView.reloadData()
        self.refreshPagination()
        self.enableSelection = false
        self.hideProfileImage = false

        
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
