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
import FirebaseStorage
import FirebaseAuth
import FirebaseDatabase


protocol DiscoverListViewDelegate {
    func goToList(list:List?, filter:String?)
    func goToPost(postId: String, ref_listId: String?, ref_userId: String?)
    func displayListFollowingUsers(list: List, following: Bool)
    func showUserLists()
    func didTapExtraTag(tagName: String, tagId: String, post: Post)
    func refreshAll()
}

class DiscoverListView: UIView, EmojiButtonArrayDelegate, UICollectionViewDataSource, UICollectionViewDelegate, GridPhotoOnlyCellDelegate, UICollectionViewDelegateFlowLayout {
    
    
    var delegate: DiscoverListViewDelegate?
    
    var emojiArrayHideConstraint:NSLayoutConstraint?
    var profileImageHideConstraint:NSLayoutConstraint?
    var post: Post? {
        didSet {
            self.refreshListCollectionView()
        }
    }
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
            self.refreshListCollectionView()
//            self.creatorListCollectionView.reloadData()
            print("DiscoverListView | Displayed List | \(list.name) | \(list.id)")
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
            
            self.hideProfileImage = self.list?.creatorUID == refUser?.uid
            self.showLargeFollowerCount = self.list?.creatorUID == refUser?.uid

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
    
    // FOLLOW UNFOLLOW BUTTON
    lazy var listFollowButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont(font: .avenirNextBold, size: 14)
        button.setTitle("Follow List", for: .normal)
        button.setTitleColor(.darkLegitColor(), for: .normal)
        button.layer.borderColor = UIColor.darkLegitColor().cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 10
        button.backgroundColor = UIColor.selectedColor()
        button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 5, bottom: 3, right: 5)
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
                self.setupListFollowButton()
                //                self.alert(title: "", message: "\((list.name)!) List UnFollowed")
            }
        } else {
            Database.handleFollowingList(userUid: uid, followedList: followingList) {
                SVProgressHUD.showSuccess(withStatus: "Followed \(followingList.name)")
                SVProgressHUD.dismiss(withDelay: 1)
                self.delegate?.refreshAll()
                self.setupListFollowButton()
                //                self.alert(title: "", message: "\((list.name)!) List Followed")
            }
        }
    }
    
    func setupListFollowButton() {
        self.listFollowButton.isHidden = self.list?.creatorUID == Auth.auth().currentUser?.uid
        guard let list = list else {return}
        if CurrentUser.followedListIds.contains((list.id)!){
            listFollowButton.setTitle("Following", for: .normal)
            listFollowButton.backgroundColor = UIColor.ianLegitColor()
            listFollowButton.setTitleColor(UIColor.white, for: .normal)
            listFollowButton.layer.borderWidth = 0
            
        } else {
            listFollowButton.setTitle("Follow", for: .normal)
            listFollowButton.backgroundColor = UIColor.clear
            listFollowButton.backgroundColor = UIColor.white
            listFollowButton.setTitleColor(UIColor.ianLegitColor(), for: .normal)
            listFollowButton.layer.borderWidth = 1
            listFollowButton.layer.borderColor = UIColor.ianLegitColor().cgColor

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
    
    func setupListName(){
        
        guard let list = list else {
            return
        }
        
        let listNameText = NSMutableAttributedString()
        
        
        let listNameString = NSMutableAttributedString(string: (list.name) + " ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkLegitColor(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Poppins-Bold", size: 16)]))
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
        
        if let displayEmojis = self.list?.topEmojis{
            if displayEmojis.count > 0 {
                let emojiString = Array(displayEmojis.prefix(3)).joined()
                let listNameString = NSMutableAttributedString(string: " " + emojiString, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkLegitColor(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Poppins-Bold", size: 16)]))
                listNameText.append(listNameString)
            }
        }

        
        listnameLabel.attributedText = listNameText
        listnameLabel.sizeToFit()
        
//        followerCountLabel.text = ""
//        if let followerCount = self.list?.followerCount {
//            if followerCount > 0 {
//                let postCountString = NSMutableAttributedString(string: "\(followerCount) Followers \n", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.gray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 15)]))
//                //                followerCountLabel.attributedText = postCountString
//            }
//        }
//        followerCountLabel.sizeToFit()
        
    }
    
    func refreshListCollectionView(){
        
        // CLEAR CURRENT OBJECTS
        self.postCurrentUserListIds = []
        self.postCurrentUserListNames = []
        self.postCreatorListIds = []
        self.postCreatorListNames = []
        
        // CREATOR TAGGED LISTS
        if self.post?.creatorListId != nil {
            for (key,value) in (self.post?.creatorListId)! {
                self.postCreatorListIds.append(key)
                self.postCreatorListNames.append(value)
            }
        }
        
        // CURRENT USER TAGGED LISTS
        if self.post?.selectedListId != nil {
            for (key,value) in (self.post?.selectedListId)! {
                self.postCurrentUserListIds.append(key)
                self.postCurrentUserListNames.append(value)
            }
        }
        
//        var tagCount: String = (self.postCreatorListNames.count < 4) ? "" : (String(self.postCreatorListNames.count - 3) + " ")
        var tagCount: String = (self.postCreatorListNames.count < 0) ? "" : (String(self.postCreatorListNames.count) + " ")
        self.userTaggedListCountLabel.isHidden = tagCount == ""
        self.userTaggedListCountLabel.text = "\(tagCount) TAGGED " + ((self.postCreatorListNames.count > 1) ? "LISTS" : "LIST")
        
        print("DiscoverListView | refreshListCollectionView | \(self.postCreatorListNames.count) Lists")
        self.creatorListCollectionView.reloadData()
        //        self.view.updateConstraintsIfNeeded()
        //        self.view.layoutIfNeeded()
        
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
        label.numberOfLines = 1
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
    
    let userListLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont(name: "Poppins-Bold", size: 12)
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = NSTextAlignment.center
        label.textColor = UIColor.ianLegitColor()
        //        label.numberOfLines = 0
        return label
    }()
    
    let socialStatsLabel: UILabel = {
        let label = UILabel()
        label.text = "SocialStats"
        label.font = UIFont(name: "Poppins-Regular", size: 12)
        label.numberOfLines = 1
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.clear
        return label
    }()
    
    let followerStatsLabel: UILabel = {
        let label = UILabel()
        label.text = "SocialStats"
        label.font = UIFont(name: "Poppins-Regular", size: 12)
        label.numberOfLines = 1
        label.textAlignment = NSTextAlignment.right
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
    
    var emojiArray = EmojiButtonArray(emojis: [], frame: CGRect(x: 0, y: 0, width: 0, height: 25))
    

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
    
    var showLargeFollowerCount = false {
        didSet{
            setupSocialStatsLabel()
        }
    }
    
    
    func setupSocialStatsLabel() {
        let socialStats = NSMutableAttributedString()
        
        socialStatsLabel.font = UIFont.systemFont(ofSize: socialStatsFontSize)
        let imageSize = CGSize(width: socialStatsFontSize, height: socialStatsFontSize)
        
        if let postCount = self.list?.postIds?.count {
            if postCount > 0 {
                let postCountString = NSMutableAttributedString(string: "\(postCount) Posts ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.gray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Poppins-Bold", size: socialStatsFontSize)]))
                socialStats.append(postCountString)
                
                //                let postCountString2 = NSMutableAttributedString(string: " Posts ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.gray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: socialStatsFontSize)]))
                //                socialStats.append(postCountString2)
            }
        }
        
        socialStatsLabel.attributedText = socialStats
        socialStatsLabel.sizeToFit()
        
        let followerStats = NSMutableAttributedString()
        let largeFollowerStats = NSMutableAttributedString()

        if let followerCount = self.list?.followerCount {
            if followerCount > 0 {
                let postCountString = NSMutableAttributedString(string: "\(followerCount) Followers", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.gray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Poppins-Regular", size: socialStatsFontSize - 1)]))
                followerStats.append(postCountString)
                
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineSpacing = 50
                
                let countString = NSMutableAttributedString(string: String(followerCount), attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Poppins-Bold", size: 20)]))
                //                countString.addAttribute(.paragraphStyle, value:paragraph, range:NSMakeRange(0, countString.length))
                
                largeFollowerStats.append(countString)
                
                var displayString = ((followerCount == 1) ? "Follower" : "Followers")
                let postCountString2 = NSMutableAttributedString(string: "\n" + displayString, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.ianLegitColor(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .avenirHeavy, size: 14)]))
                //                postCountString.addAttribute(.paragraphStyle, value:paragraph, range:NSMakeRange(0, postCountString.length))
                
                largeFollowerStats.append(postCountString2)
            }
        }
        
        followerStatsLabel.attributedText = followerStats
        followerStatsLabel.sizeToFit()
        
        largeFollowerCountLabel.attributedText = largeFollowerStats
        largeFollowerCountLabel.sizeToFit()
        
        followerStatsLabel.isHidden = showLargeFollowerCount
        listFollowButton.isHidden = showLargeFollowerCount
        largeFollowerCountLabel.isHidden = !showLargeFollowerCount
        //        followerCountLabel.sizeToFit()
        

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
    
//    override var isSelected: Bool {
//        didSet {
//            if enableSelection {
//                self.backgroundColor = self.isSelected ? UIColor.mainBlue().withAlphaComponent(0.2) : UIColor.white
//            } else {
//                self.backgroundColor = UIColor.white
//            }
//        }
//    }
    
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
    
    lazy var creatorListCollectionView : UICollectionView = {

        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout())
//        let cv = UICollectionView(frame: CGRect.zero)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = .white
        return cv
    }()

    
    let userTaggedListCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Poppins-Bold", size: 12)
        label.textColor = UIColor.ianLegitColor()
        label.textColor = UIColor.darkGray

        label.textAlignment = NSTextAlignment.left
        return label
    }()
    

    
    // LISTS
    var creatorListIds: [String] = []
    var postCreatorListIds: [String] = []
    var postCreatorListNames: [String] = []
    
    var postCurrentUserListIds: [String] = []
    var postCurrentUserListNames: [String] = []
    
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let cellView = UIView()
        addSubview(cellView)
        cellView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 150 + 40 + 5)
        cellView.layer.applySketchShadow()
        
        
    // USER LIST
        let userListView = UIView()
        addSubview(userListView)
        userListView.anchor(top: cellView.topAnchor, left: cellView.leftAnchor, bottom: nil, right: cellView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 35)
        //        userListView.backgroundColor = UIColor.rgb(red: 249, green: 249, blue: 249)
        
        
        addSubview(userTaggedListCountLabel)
        userTaggedListCountLabel.anchor(top: nil, left: userListView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        userTaggedListCountLabel.centerYAnchor.constraint(equalTo: userListView.centerYAnchor).isActive = true
        userTaggedListCountLabel.sizeToFit()
        userTaggedListCountLabel.isUserInteractionEnabled = true
        userTaggedListCountLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showUserLists)))
        
        setupCreatorTagCollectionView()
        addSubview(creatorListCollectionView)
        creatorListCollectionView.anchor(top: nil, left: userTaggedListCountLabel.rightAnchor, bottom: nil, right: userListView.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 2, paddingRight: 5, width: 0, height: 35)
        //        creatorListCollectionView.rightAnchor.constraint(lessThanOrEqualTo: userTaggedListCountLabel.leftAnchor).isActive = true
                creatorListCollectionView.centerYAnchor.constraint(equalTo: userListView.centerYAnchor).isActive = true
        creatorListCollectionView.backgroundColor = UIColor.white
        
        
    // DISPLAYED LIST
        setupListCollectionView()

        addSubview(listCollectionView)
        listCollectionView.anchor(top: userListView.bottomAnchor, left: cellView.leftAnchor, bottom: nil, right: cellView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 100)


    // ADDITIONAL TAGGED LIST DETAILS
        
        let detailView = UIView()
        addSubview(detailView)
        detailView.anchor(top: listCollectionView.bottomAnchor, left: cellView.leftAnchor, bottom: nil, right: cellView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
        detailView.isUserInteractionEnabled = true
        detailView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToList)))
        
        setupListFollowButton()
        addSubview(listFollowButton)
        listFollowButton.anchor(top: detailView.topAnchor, left: nil, bottom: nil, right: cellView.rightAnchor, paddingTop: 1, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 80, height: 25)
        //        listFollowButton.centerYAnchor.constraint(equalTo: detailView.centerYAnchor).isActive = true
        
        addSubview(listnameLabel)
        listnameLabel.anchor(top: detailView.topAnchor, left: detailView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        listnameLabel.rightAnchor.constraint(lessThanOrEqualTo: listFollowButton.leftAnchor, constant: 10).isActive = true
//        listnameLabel.centerYAnchor.constraint(equalTo: detailView.centerYAnchor).isActive = true
        listnameLabel.isUserInteractionEnabled = true
        listnameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToList)))
        
        
        let socialStatsView = UIView()
        addSubview(socialStatsView)
        socialStatsView.anchor(top: detailView.bottomAnchor, left: cellView.leftAnchor, bottom: cellView.bottomAnchor, right: cellView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 25)
        socialStatsView.isUserInteractionEnabled = true
        socialStatsView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToList)))
        
        
        addSubview(socialStatsLabel)
        socialStatsLabel.anchor(top: socialStatsView.topAnchor, left: socialStatsView.leftAnchor, bottom: nil, right: nil, paddingTop: 1, paddingLeft: 5, paddingBottom: 2, paddingRight: 0, width: 0, height: 0)
        //        socialStatsLabel.centerYAnchor.constraint(equalTo: socialStatsView.centerYAnchor).isActive = true
        
        
        addSubview(followerStatsLabel)
        followerStatsLabel.anchor(top: socialStatsView.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 1, paddingLeft: 5, paddingBottom: 2, paddingRight: 10, width: 0, height: 15)
        followerStatsLabel.centerXAnchor.constraint(equalTo: listFollowButton.centerXAnchor).isActive = true
        
        addSubview(largeFollowerCountLabel)
        largeFollowerCountLabel.anchor(top: listnameLabel.topAnchor, left: nil, bottom: socialStatsView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 2, paddingRight: 0, width: 0, height: 0)
        largeFollowerCountLabel.centerXAnchor.constraint(equalTo: listFollowButton.centerXAnchor).isActive = true
        largeFollowerCountLabel.isHidden = true
        //        largeFollowerCountLabel.backgroundColor = UIColor.yellow
        largeFollowerCountLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(followerCountTapped)))
        
        
        
    }
    
    @objc func showUserLists(){
        guard let list = list else {return}
        self.delegate?.showUserLists()
    }
    
    @objc func followerCountTapped(){
        guard let list = list else {return}
        self.delegate?.displayListFollowingUsers(list: list, following: true)
    }
    
    func setupListCollectionView(){
        listCollectionView.register(GridPhotoOnlyCell.self, forCellWithReuseIdentifier: cellId)
        let layout = ListDisplayFlowLayout()
        layout.minimumLineSpacing = 10
        layout.scrollDirection = .horizontal
        listCollectionView.collectionViewLayout = layout
        listCollectionView.backgroundColor = UIColor.white
        listCollectionView.isScrollEnabled = true
        listCollectionView.showsHorizontalScrollIndicator = false
    }
    
    func setupCreatorTagCollectionView(){
        creatorListCollectionView.register(ListDisplayCell.self, forCellWithReuseIdentifier: cellId)
        let layout = UploadLocationTagList()
        layout.sectionInset =  UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        layout.minimumInteritemSpacing = 5
        creatorListCollectionView.collectionViewLayout = layout
        creatorListCollectionView.isScrollEnabled = true
        creatorListCollectionView.showsHorizontalScrollIndicator = false
        creatorListCollectionView.semanticContentAttribute = UISemanticContentAttribute.forceRightToLeft

        //        creatorListCollectionView.backgroundColor = UIColor.clear
        //        layout.minimumInteritemSpacing = 3
        //        layout.minimumLineSpacing = 1
        //        layout.estimatedItemSize = CGSize(width: 30, height: 30)
        //        layout.sectionInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 0)
        //        layout.scrollDirection = .horizontal
//        creatorListCollectionView.backgroundColor = UIColor.yellow
        //        creatorListCollectionView.semanticContentAttribute = UISemanticContentAttribute.forceRightToLeft
        
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
    
    @objc func goToList(){
        self.delegate?.goToList(list: list, filter: nil)
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == creatorListCollectionView {
            
            let displayListName = self.postCreatorListNames[indexPath.row]
            let displayListId = self.postCreatorListIds[indexPath.row] 
            guard let post = self.post else {return}

            
            self.delegate?.didTapExtraTag(tagName: displayListName, tagId: displayListId, post: post)
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let imageCount = self.list?.listImageUrls.count ?? 0
        let userIsCreator = self.list?.creatorUID == Auth.auth().currentUser?.uid
        
        if collectionView == creatorListCollectionView
        {
            //print("creatorListCollectionView | CellCount | \(self.postCreatorListNames.count)")
            return self.postCreatorListNames.count
        }
        else if collectionView == listCollectionView
        {
            if imageCount > 0 {
                return imageCount /*+ (self.listUser?.isFollowing ?? true ? 0 : 1)*/
            } else {
                return 0 //self.list?.creatorUID == Auth.auth().currentUser?.uid ? 1 : 0
            }
        }
        else{
            return 0
        }
        

        //        return paginatePostsCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == creatorListCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ListDisplayCell
            
            var displayListName: String?
            var displayListId: String?
            
            if collectionView == creatorListCollectionView {
                displayListName = self.postCreatorListNames[indexPath.row]
                displayListId = self.postCreatorListIds[indexPath.row]
                cell.otherUser = !(self.post?.creatorUID == Auth.auth().currentUser?.uid)
            }
            
            if self.post?.creatorUID == Auth.auth().currentUser?.uid {
                // Current User is Creator
                cell.otherUser = false
            } else if let creatorListIds = self.post?.creatorListId {
                // Current User is not Creator
                if creatorListIds[displayListId!] != nil {
                    //Is Non-Current User Creator ID
                    cell.otherUser = true
                } else {
                    //Is Non-Current User Selected ID
                    cell.otherUser = false
                }
            } else {
                cell.otherUser = false
            }
            
            cell.displayListName = displayListName
            cell.displayListId = displayListId
            cell.displayFont = 13
            
            //print("creatorListCollectionView | \(displayListName) | \(displayListId)")
            
            
            return cell
        }
        
        else if collectionView == listCollectionView {
            if indexPath.row == self.list?.listImageUrls.count {
                // LAST ROW
                let listId = self.list?.id ?? "999"
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! GridPhotoOnlyCell
                if indexPath.row == 0 {
                    cell.showLabel(string: "No Posts")
                    cell.label.layer.borderWidth = 0
                } else {
                    cell.showLabel(string: CurrentUser.followedListIds.contains(listId) ? "UnFollow List" : "Follow List")
                    cell.label.layer.borderWidth = 1
                }
                
                cell.delegate = self
                cell.highlightCell = false
                
                return cell
                
            } else {
                var listImageUrl = self.list?.listImageUrls[indexPath.row]
                var refPost = self.list?.listImagePostIds[indexPath.row]
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! GridPhotoOnlyCell
                cell.delegate = self
                cell.postIdLink = refPost
                
                //            if listImageUrl == nil || listImageUrl == ""{
                //                Database.updatePostSmallImages(postId: refPost) { (smallImageUrl) in
                //                    cell.imageUrl = listImageUrl
                //                }
                //            } else {
                //                cell.imageUrl = listImageUrl
                //            }
                
                cell.imageUrl = listImageUrl
                
                return cell
                
            }
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! GridPhotoOnlyCell
            return cell
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == self.creatorListCollectionView {
            return 5
        } else {
            return 1
        }
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
    
//    override func prepareForReuse() {
//        super.prepareForReuse()
//
//        //        self.profileImageView.image = UIImage()
//        self.userProfileImageView.image = UIImage()
//        self.listIndLabel.setImage(UIImage(), for: .normal)
//        self.listnameLabel.text = ""
//        self.followerCountLabel.text = ""
//        self.socialStatsLabel.text = ""
//        self.listUser = nil
//        self.list = nil
//        self.listCollectionView.reloadData()
//        self.refreshPagination()
//        self.enableSelection = false
//        self.hideProfileImage = false
//
//
//        let subViews = self.subviews
//
//        // Reused cells removes extra pictures and shrinks back contentsize width. It gets expanded and added back later if >1 pic
//
//        for subview in subViews{
//            if let img = subview as? CustomImageView {
//                img.image = nil
//                img.cancelImageRequestOperation()
//                if img.tag != 0 {
//                    img.removeFromSuperview()
//                }
//            }
//        }
//
//    }
    
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
