//
//  UserCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 11/15/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth
import SVProgressHUD

protocol DiscoverUserCellDelegate {
    func goToPost(postId: String, ref_listId: String?, ref_userId: String?)
    func goToUser(user: User?, filter: String?)
    func goToUserList(user: User?)
    func selectUserFollowers(user: User?)
    func refreshAll()
}

class DiscoverUserCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, GridPhotoOnlyCellDelegate, EmojiButtonArrayDelegate {
    
    
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
        guard let user = user else {return}
        self.delegate?.goToUser(user: user, filter: emoji)
    }
    

    
    var user: User?{
        didSet {
            guard let user = user else {return}
            var topEmojis = ""
            if (user.topEmojis.count) > 0 {
                topEmojis = Array((user.topEmojis.prefix(3))).joined()
            } else {
                topEmojis = ""
            }
            emojiLabel.text = topEmojis
            emojiLabel.sizeToFit()
            
            let displayEmojis = user.topEmojis
            if displayEmojis.count > 0{
                emojiArray.emojiLabels = Array(displayEmojis.prefix(3))
            } else {
                emojiArray.emojiLabels = []
            }
            emojiArray.setEmojiButtons()
            emojiArray.sizeToFit()
            
            
            setupUsernameLabel()
            setupFollowButton()
            setupSocialStatsLabel()
            self.listCollectionView.reloadData()
        }
    }
    
    var delegate: DiscoverUserCellDelegate?
    
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
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.adjustsFontSizeToFitWidth = false
        //        label.numberOfLines = 0
        return label
    }()
    
    
    let socialStatsLabel: UILabel = {
        let label = UILabel()
        label.text = "SocialStats"
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
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
    
    let emojiLabel: UILabel = {
        let label = UILabel()
        label.text = "Emoji"
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()
    
    lazy var followButton: UIButton = {
        let button = UIButton()
        button.setTitle("Follow", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.backgroundColor = UIColor.ianLegitColor()
        button.addTarget(self, action: #selector(handleFollow), for: .touchUpInside)
        button.layer.cornerRadius = 2
        button.layer.masksToBounds = true
        return button
        
    }()
    
    func setupUsernameLabel() {
        self.profileImageView.loadImage(urlString: (self.user?.profileImageUrl)!)
        
        let usernameLabelText = NSMutableAttributedString()
        
        let usernameString = NSMutableAttributedString(string: "\((self.user?.username)!)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkLegitColor(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .helveticaNeueBold, size: 18)]))
        
        usernameLabelText.append(usernameString)
        
        self.usernameLabel.attributedText = usernameLabelText
        self.usernameLabel.sizeToFit()
        
        followerCountLabel.text = ""
        if let followerCount = self.user?.followersCount {
            if followerCount > 0 {
                let followerCountString = NSMutableAttributedString(string: "\(followerCount) Followers ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
                    followerCountLabel.attributedText = followerCountString
                    followerCountLabel.sizeToFit()
            }
        }
        
//        if let credCount = self.user?.total_cred {
//            if credCount > 0 {
//                let credButtonString = NSMutableAttributedString(string: "  \(credCount) ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 13)]))
//                usernameLabelText.append(credButtonString)
//
//                let image1Attachment = NSTextAttachment()
//                //                let inputImage = UIImage(named: "cred")!
//                let inputImage = #imageLiteral(resourceName: "drool")
//
//                image1Attachment.image = inputImage
//
//                image1Attachment.bounds = CGRect(x: 0, y: (usernameLabel.font.capHeight - (inputImage.size.height)).rounded() / 2, width: inputImage.size.width, height: inputImage.size.height)
//
//                let image1String = NSAttributedString(attachment: image1Attachment)
//                usernameLabelText.append(image1String)
//
//            }
//        }
        

        
    }
    
    func setupSocialStatsLabel() {
        let socialStats = NSMutableAttributedString()
        
//        if let followerCount = self.user?.followersCount {
//            if followerCount > 0 {
//                let followerCountString = NSMutableAttributedString(string: "\(followerCount) Followers ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
//                socialStats.append(followerCountString)
//
//            }
//        }
        
        if let listCount = self.user?.lists_created {
            if listCount > 0 {
                let credCountString = NSMutableAttributedString(string: "\(listCount) Lists ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
                socialStats.append(credCountString)
            }
        }
        
        if let postCount = self.user?.posts_created {
            if postCount > 0 {
                let postCountString = NSMutableAttributedString(string: "\(postCount) Posts ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
                socialStats.append(postCountString)
            }
        }
        

        
        socialStatsLabel.attributedText = socialStats
        socialStatsLabel.sizeToFit()
        
        
//        if let credCount = self.user?.total_cred {
//            if credCount > 0 {
//
//
//                let image1Attachment = NSTextAttachment()
//                //                let inputImage = UIImage(named: "cred")!
//                let imageSize = CGSize(width: 14, height: 14)
//                let inputImage = #imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
//
//                image1Attachment.image = inputImage
//
//                image1Attachment.bounds = CGRect(x: 0, y: (usernameLabel.font.capHeight - (inputImage.size.height)).rounded() / 2, width: inputImage.size.width, height: inputImage.size.height)
//
//                let image1String = NSAttributedString(attachment: image1Attachment)
//                socialStats.append(image1String)
//
//                let credButtonString = NSMutableAttributedString(string: "\(credCount) ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
//                socialStats.append(credButtonString)
//
//            }
//        }

        

        
        //        if let fanCount = self.user?.followersCount {
        //            if fanCount > 0 {
        //                let fanCountString = NSMutableAttributedString(string: "\(fanCount) Followers ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 14)]))
        //                socialStats.append(fanCountString)
        //            }
        //        }

    }
    
    func gridPhotoLabelTapped(){
        self.handleFollow()
    }
    
    func setupFollowButton(){
        

//        self.followButton.isHidden = user?.uid == Auth.auth().currentUser?.uid
        self.followButton.isHidden = ((user?.isFollowing)! || (user?.uid == Auth.auth().currentUser?.uid))
        self.emojiArray.isHidden = !((user?.isFollowing)! || (user?.uid == Auth.auth().currentUser?.uid))
        
        
        
//        if (user?.isFollowing)! || (user?.uid == Auth.auth().currentUser?.uid){
//            self.followButton.isHidden = true
//            self.emojiArray.isHidden = false
//
////            self.emojiArrayHeight?.constant = 30
////            self.emojiArrayCenter?.isActive = true
////            self.emojiArrayBottom?.isActive = false
////            self.followButton.setTitle("Unfollow", for: .normal)
////            self.followButton.backgroundColor = UIColor.orange
//        } else {
//            self.followButton.setTitle("Follow", for: .normal)
//            self.followButton.backgroundColor = UIColor.mainBlue()
//            self.followButtonHeight?.constant = 30
//            self.followButton.isHidden = false
//            self.emojiArrayHeight?.constant = 25
//            self.emojiArrayCenter?.isActive = false
//            self.emojiArrayBottom?.isActive = true
//        }
    }
    
    func handleFollow(){
        
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else {return}
        guard let userId = user?.uid else {return}
        guard let username = user?.username else {return}
        if currentLoggedInUserId == userId {return}
        
        Database.handleFollowing(userUid: userId) {
            var displayString = self.user?.isFollowing ?? false ? "Unfollowed" : "Followed"
            SVProgressHUD.showSuccess(withStatus: "\(displayString) \(username)")
            SVProgressHUD.dismiss(withDelay: 1)
            self.delegate?.refreshAll()
        }
        
    }
    
    override var isSelected: Bool {
        didSet {
            self.backgroundColor = self.isSelected ? UIColor.mainBlue().withAlphaComponent(0.2) : UIColor.white
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
    
    let followerCountLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.textColor = UIColor.gray
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.adjustsFontSizeToFitWidth = false
        label.isUserInteractionEnabled = true
        //        label.numberOfLines = 0
        return label
    }()
    
    let cellId = "CellId"
    
    var followButtonHeight: NSLayoutConstraint?
    var emojiArrayHeight: NSLayoutConstraint?
    var emojiArrayCenter: NSLayoutConstraint?
    var emojiArrayBottom: NSLayoutConstraint?


    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let cellView = UIView()
        addSubview(cellView)
        cellView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 70)
        cellView.isUserInteractionEnabled = true
        cellView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(userTapped)))
        
    // OK TO HAVE USER PROFILE IMAGE A LITTLE BIGGER FOR USER CELL
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 50, height: 50)
        //        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        profileImageView.layer.cornerRadius = 50/2
        
        addSubview(followButton)
        followButton.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 100, height: 0)
        followButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        
        addSubview(emojiArray)
        emojiArray.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 15, width: 0, height: 30)
        emojiArray.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        
        emojiArray.delegate = self
        emojiArray.alignment = .right
        emojiArray.backgroundColor = UIColor.clear
        
    
        addSubview(usernameLabel)
        usernameLabel.anchor(top: profileImageView.topAnchor, left: profileImageView.rightAnchor, bottom: nil, right: emojiArray.leftAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        
        addSubview(followerCountLabel)
        followerCountLabel.anchor(top: usernameLabel.bottomAnchor, left: usernameLabel.leftAnchor, bottom: nil, right: emojiArray.leftAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        let followerTap = UITapGestureRecognizer(target: self, action: #selector(followerCountTapped))
//        followerCountLabel.addGestureRecognizer(followerTap)
        
        addSubview(socialStatsLabel)
        socialStatsLabel.anchor(top: followerCountLabel.bottomAnchor, left: profileImageView.rightAnchor, bottom: nil, right: emojiArray.leftAnchor, paddingTop: 2, paddingLeft: 10, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        let socialTap = UITapGestureRecognizer(target: self, action: #selector(socialTapped))
//        socialStatsLabel.addGestureRecognizer(socialTap)
        
        addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top: nil, left: nil, bottom: nil, right: emojiArray.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        emojiDetailLabel.centerYAnchor.constraint(equalTo: emojiArray.centerYAnchor).isActive = true
        emojiDetailLabel.sizeToFit()
        self.hideEmojiDetailLabel()
        
        addSubview(listCollectionView)
//        listCollectionView.anchor(top: cellView.bottomAnchor, left: profileImageView.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        listCollectionView.anchor(top: cellView.bottomAnchor, left: profileImageView.leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 90)

        
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        addSubview(separatorView)
        separatorView.anchor(top: topAnchor, left: leftAnchor, bottom: topAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
        
        setupListCollectionView()


        
        
        
        //        addSubview(emojiLabel)
        //        emojiLabel.anchor(top: socialStatsLabel.bottomAnchor, left: profileImageView.rightAnchor, bottom: nil, right: followButton.leftAnchor, paddingTop: 1, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        
    }
    
    @objc func userTapped(){
        self.delegate?.goToUser(user: user, filter: nil)
    }
    
    @objc func followerCountTapped(){
        self.delegate?.selectUserFollowers(user: user)
    }
    
    @objc func socialTapped(){
        self.delegate?.goToUserList(user: user)
    }
    
    func hideEmojiDetailLabel(){
        self.emojiDetailLabel.alpha = 0
    }
    
    func setupListCollectionView(){
        listCollectionView.register(GridPhotoOnlyCell.self, forCellWithReuseIdentifier: cellId)
        let layout = ListDisplayFlowLayout()
        listCollectionView.collectionViewLayout = layout
        listCollectionView.backgroundColor = UIColor.clear
        listCollectionView.isScrollEnabled = true
        listCollectionView.showsHorizontalScrollIndicator = false
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let imageCount = self.user?.popularImageUrls.count ?? 0
        let isCurrentUser = self.user?.uid == Auth.auth().currentUser?.uid

        if imageCount > 0 {
            return imageCount //+ ((self.user?.isFollowing ?? true && !isCurrentUser) ? 0 : 1)
        } else {
            return 0
        }
        
        //        return paginatePostsCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        //        if indexPath.item == self.paginatePostsCount - 1 && !self.finishPaging {
        ////            print("Image Paginate")
        //            paginatePosts()
        //        }
        var listImageUrl = self.user?.popularImageUrls[indexPath.row]
        var refPost = self.user?.popularImagePostIds[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! GridPhotoOnlyCell
        cell.delegate = self
        cell.imageUrl = listImageUrl
        cell.postIdLink = refPost
        
        return cell
        
//        if indexPath.row == self.user?.popularImageUrls.count {
//            // LAST ROW
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! GridPhotoOnlyCell
//            if self.user?.isFollowing ?? false {
//                cell.showLabel(string: "UnFollow")
//            } else {
//                cell.showLabel(string: "Follow")
//            }
//            cell.delegate = self
//            return cell
//            
//        } else {
//            var listImageUrl = self.user?.popularImageUrls[indexPath.row]
//            var refPost = self.user?.popularImagePostIds[indexPath.row]
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! GridPhotoOnlyCell
//            cell.delegate = self
//            cell.imageUrl = listImageUrl
//            cell.postIdLink = refPost
//            
//            return cell
//        }

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
    
    func goToPost(postId: String?) {
        if let postId = postId {
            self.delegate?.goToPost(postId: postId, ref_listId: nil, ref_userId: self.user?.uid)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.profileImageView.image = UIImage()
        self.socialStatsLabel.text = ""
        self.user = nil
        self.listCollectionView.reloadData()


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
