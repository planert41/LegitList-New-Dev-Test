//
//  HomePostCell.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/29/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import mailgun
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import Cosmos


protocol FullPostCellDelegate {
    func didTapBookmark(post:Post)
    func didTapComment(post:Post)
    func didTapUser(post:Post)
    func didTapUserUid(uid:String)
    func didTapLocation(post:Post)
    func didTapMessage(post:Post)
    func refreshPost(post:Post)
    
    func userOptionPost(post:Post)
    
    func displaySelectedEmoji(emoji: String, emojitag: String)
    func didTapExtraTag(tagName: String, tagId: String, post: Post)
    
    func displayPostSocialUsers(post:Post, following: Bool)
    func displayPostSocialLists(post:Post, following: Bool)
//    func expandPost(post:Post, newHeight: CGFloat)

    
}

class FullPostCell: UICollectionViewCell, UIGestureRecognizerDelegate, UIScrollViewDelegate, EmojiButtonArrayDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    func doubleTapEmoji(index: Int?, emoji: String) {
        
    }
    

    var delegate: FullPostCellDelegate?
    
    var popView = UIView()
    var enableDelete: Bool = false
    var isZooming = false
    var currentImage = 1 {
        didSet {
            setupImageCountLabel()
        }
    }
    var imageCount = 0
    
    // Settings
    var postCaptionTextSize = 15
    
    var post: Post? {
        didSet {
            
            guard let imageUrls = post?.imageUrls else {
                print("Read Post, No Image URLs Error")
                return}
            
            setupImageCountLabel()
            fillInCaptionBubble()
            
            setupPicturesScroll()
            if post?.images != nil {
                photoImageView.image = post?.images![0]
            } else {
                photoImageView.loadImage(urlString: imageUrls.first!)
            }
            
            setupUser()
            setupActionButtons()
            setupEmojis()
            refreshListCollectionView()
//            setupExtraTags()
            setupRatingLegitIcon()
            setupAttributedLocationName()
            setupPostDetails()
            setupAttributedSocialCount()
            
            //            captionBubble.text = post?.caption
            //            captionBubble.sizeToFit()
            
        }
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        return contentView.systemLayoutSizeFitting(CGSize(width: targetSize.width, height: 10))
    }
    
    func setupUser(){
        usernameLabel.text = post?.user.username
        usernameLabel.sizeToFit()
        usernameLabel.adjustsFontSizeToFitWidth = true
        
        usernameLabel.isUserInteractionEnabled = true
        let usernameTap = UITapGestureRecognizer(target: self, action: #selector(HomePostCell.usernameTap))
        usernameLabel.addGestureRecognizer(usernameTap)
        
        guard let profileImageUrl = post?.user.profileImageUrl else {return}
        userProfileImageView.loadImage(urlString: profileImageUrl)
    }
    
    func refreshListCollectionView(){
        self.postListIds = []
        self.postListNames = []

        if self.post?.creatorListId != nil {
            for (key,value) in (self.post?.creatorListId)! {
                if value == legitListName{
                    self.postListIds.append(key)
                    self.postListNames.append(value)
                }
            }
            
            for (key,value) in (self.post?.creatorListId)! {
                if value == bookmarkListName{
                    self.postListIds.append(key)
                    self.postListNames.append(value)
                }
            }
            
            for (key,value) in (self.post?.creatorListId)! {
                if value != legitListName && value != bookmarkListName{
                    self.postListIds.append(key)
                    self.postListNames.append(value)
                }
            }
        }
        
        if self.post?.selectedListId != nil && self.post?.creatorUID != Auth.auth().currentUser?.uid {
            for (key,value) in (self.post?.selectedListId)! {
                if value == legitListName{
                    self.postListIds.append(key)
                    self.postListNames.append(value)
                }
            }
            
            for (key,value) in (self.post?.selectedListId)! {
                if value == bookmarkListName{
                    self.postListIds.append(key)
                    self.postListNames.append(value)
                }
            }
            
            for (key,value) in (self.post?.selectedListId)! {
                if value != legitListName && value != bookmarkListName{
                    self.postListIds.append(key)
                    self.postListNames.append(value)
                }
            }
        }
        
        if self.postListNames.count == 0 {
            self.hideListCollectionViewConstraint?.isActive = true
            self.showListCollectionViewConstraint?.isActive = false
        } else {
            self.hideListCollectionViewConstraint?.isActive = false
            self.showListCollectionViewConstraint?.isActive = true
        }
        self.updateConstraintsIfNeeded()
        self.layoutIfNeeded()
        self.listCollectionView.reloadData()
    }
    
    func setupImageCountLabel(){
        imageCount = (self.post?.imageCount)!
        
        if imageCount == 1 {
            photoCountLabel.isHidden = true
        } else {
            photoCountLabel.isHidden = false
        }
        
        if imageCount > 1 {
            self.photoCountLabel.text = "\(currentImage)\\\(imageCount)"
        } else {
            self.photoCountLabel.text = ""
        }
        photoCountLabel.reloadInputViews()
    }
    
    @objc func usernameTap() {
        print("Tap username label", post?.user.username ?? "")
        guard let post = post else {return}
        delegate?.didTapUser(post: post)
    }
    
    @objc func locationTap() {
        print("Post Information: ", post)
        
        print("Tap location label", post?.locationName ?? "")
        guard let post = post else {return}
        delegate?.didTapLocation(post: post)
    }
    
    var bookmarkLabelConstraint: NSLayoutConstraint? = nil
    var displayNames: [String] = []
    var displayNamesUid: [String:String] = [:]

    let socialViewHeight = 25 as CGFloat
    
    fileprivate func updateVoteTextView(){
        let attributedVoteText = NSMutableAttributedString()

        if self.displayNames.count > 0 {
            let attributedVoteText = NSMutableAttributedString(string: "from ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray]))
            
            attributedVoteText.append(NSAttributedString(string: self.displayNames.joined(separator: ", "), attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 15), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.legitColor()])))
            
            self.voteStatsTextView.attributedText = attributedVoteText
//            print(attributedVoteText)
            self.voteStatsTextView.reloadInputViews()
        } else {
            self.voteStatsTextView.attributedText = NSMutableAttributedString()
        }
        
//        print(self.voteStatsTextView.attributedText)
        self.voteStatsTextView.reloadInputViews()
        self.voteStatsTextView.sizeToFit()

    }
    
    fileprivate func setupAttributedSocialCount(){
        
        guard let post = self.post else {return}
        displayNames = []
        displayNamesUid = [:]

        
        
    // Follower Vote Count
        let followingVoteText = NSMutableAttributedString()

        if post.followingVote.count > 0 {
            let voteString = NSMutableAttributedString(string: String(post.followingVote.count) + " Cred", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
            followingVoteText.append(voteString)
        }
        
        followVoteStatsLabel.attributedText = followingVoteText
        
    // Follower List Count
        let followingListText = NSMutableAttributedString()
        
        if post.followingList.count > 0 {
            if post.followingVote.count > 0 {
                let andString = NSMutableAttributedString(string: "& ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 14)]))
                followingListText.append(andString)
            }
            
            let followString = NSMutableAttributedString(string: String(post.followingList.count) + " Lists", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
            followingListText.append(followString)
        }
        
        followListStatsLabel.attributedText = followingListText
        
    // Additional Following User Display
        
        var followingUserIds: [String] = []
        if post.followingList.count > 0 {
            for (listId, userId) in post.followingList {
                if !followingUserIds.contains(userId){
                    followingUserIds.append(userId)
                }
            }
        }
        
        if post.followingVote.count > 0 {
            for userId in post.followingVote{
                if !followingUserIds.contains(userId){
                    followingUserIds.append(userId)
                }
            }
        }
        
        for userId in followingUserIds {
            if displayNames.count < 3 {
                Database.fetchUserWithUID(uid: userId) { (user) in
                    var displayName = (user?.username)!.replacingOccurrences(of: "@", with: "")
                    self.displayNames.append(displayName)
                    self.displayNamesUid[displayName] = (user?.uid)!
                    self.updateVoteTextView()
                }
            }
        }

        if post.followingList.count == 0 && post.followingVote.count == 0 {
            self.socialStatsViewHeight?.constant = 0
            self.updateVoteTextView()
        } else {
            self.socialStatsViewHeight?.constant = socialViewHeight
        }
        
        
// ACTION BUTTON COUNTS
        
    // Button Counts

        if post.likeCount != 0 {
            self.voteCount.text = String(post.likeCount)
        } else {
            self.voteCount.text = ""
        }
        
        if post.commentCount != 0 {
            self.commentCount.text = String(post.commentCount)
        } else {
            self.commentCount.text = ""
        }
        
        if post.messageCount > 0 {
            self.messageCount.text = String( post.messageCount)
        } else {
            self.messageCount.text = ""
        }
        
        if post.listCount > 0 {
            self.listCount.text = String( post.listCount)
        } else {
            self.listCount.text = ""
        }
        
        // Resizes bookmark label to fit new count
        bookmarkLabelConstraint?.constant = self.listCount.frame.size.width
        //        self.layoutIfNeeded()
        
    }
    
    fileprivate func setupPostDetails(){
        
        guard let post = self.post else {return}
        
        // Setup Post Date
        let formatter = DateFormatter()
        let calendar = NSCalendar.current
        
        let yearsAgo = calendar.dateComponents([.year], from: post.creationDate, to: Date())
        if (yearsAgo.year)! > 0 {
            formatter.dateFormat = "MMM d yy, h:mm a"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }
        
        let daysAgo =  calendar.dateComponents([.day], from: post.creationDate, to: Date())
        var postDateString: String?
        
        // If Post Date < 7 days ago, show < 7 days, else show date
        if (daysAgo.day)! <= 7 {
            postDateString = post.creationDate.timeAgoDisplay()
        } else {
            let dateDisplay = formatter.string(from: post.creationDate)
            postDateString = dateDisplay
        }
        
        let attributedText = NSAttributedString(string: postDateString!, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 12),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.lightGray]))
        
        self.postDateLabel.attributedText = attributedText
        self.postDateLabel.sizeToFit()
        
        locationDistanceLabel.text = SharedFunctions.formatDistance(inputDistance: post.distance)
        locationDistanceLabel.adjustsFontSizeToFitWidth = true
        locationDistanceLabel.sizeToFit()
        
        // Set Up Caption
        
        // Expand Caption if no list CollectionView
        var truncateText: Int = 80
        
//        if (self.post?.creatorListId?.count) == 0 {
//            self.hideListCollectionViewConstraint?.isActive = true
//            self.showListCollectionViewConstraint?.isActive = false
//            captionTextView.textContainer.maximumNumberOfLines = 0
//            self.layoutIfNeeded()
//            self.updateConstraintsIfNeeded()
//            truncateText = 400
//        } else {
//            self.hideListCollectionViewConstraint?.isActive = false
//            self.showListCollectionViewConstraint?.isActive = true
//            captionTextView.textContainer.maximumNumberOfLines = 2
//            self.layoutIfNeeded()
//            self.updateConstraintsIfNeeded()
//            truncateText = 80
//        }
        
        captionTextView.textContainer.maximumNumberOfLines = 0

        
        let attributedTextCaption = NSMutableAttributedString(string: post.user.username, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
        
//        attributedTextCaption.append(NSAttributedString(string: " \(post.nonRatingEmoji.joined())", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)]))
        
        let captionCount = post.caption.count
        
//        if captionCount > truncateText {
//            attributedTextCaption.append(NSAttributedString(string: " \(post.caption.truncate(length: truncateText))", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)]))
//            attributedTextCaption.append(NSAttributedString(string: "more", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14), NSForegroundColorAttributeName: UIColor.lightGray]))
//        } else {
//            attributedTextCaption.append(NSAttributedString(string: " \(post.caption)", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)]))
//        }
        
        attributedTextCaption.append(NSAttributedString(string: " \(post.caption)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 14)])))

        
        attributedTextCaption.append(NSAttributedString(string: "\n\n", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 4)])))
    
        self.captionTextView.attributedText = attributedTextCaption
        self.captionTextView.sizeToFit()
    }
    
    fileprivate func setupAttributedLocationName(){
        
        guard let post = self.post else {return}
        
        var displayLocationName: String = ""
        
        var shortDisplayLocationName: String = ""
        var locationCountry: String = ""
        var locationState: String = ""
        var locationCity: String = ""
        var locationAdress: String = ""
        
        if post.locationGPS == nil {
            self.locationNameLabel.text = ""
        }
        else if post.locationGooglePlaceID! == "" {
            // Not Google Tagged Location, Display by City, State
            
            let locationNameTextArray = post.locationAdress.components(separatedBy: ",")
            let locationNameReverse = Array(locationNameTextArray.reversed())
            
            locationCountry = locationNameReverse[0]
            
            if locationNameReverse.count > 1 {
                locationState = locationNameReverse[1]
            }
            if locationNameReverse.count > 2 {
                locationCity = locationNameReverse[2]
            }
            
            if locationNameReverse.count > 3 {
                locationAdress = locationNameReverse[3]
            }
            
            if !(locationCity.isEmptyOrWhitespace()) && !(locationCountry.isEmptyOrWhitespace()){
                shortDisplayLocationName = locationCity + "," + locationCountry
            } else {
                shortDisplayLocationName = locationCity + locationCountry
            }
            
            // Last 3 items are City, State, Country
            displayLocationName = locationNameTextArray.suffix(3).joined(separator: ",")
            
        } else {
            // Google Tagged Location. Display Google Tag Name
            displayLocationName = post.locationName
            shortDisplayLocationName = post.locationName
            
            
//            shortDisplayLocationName = post.locationName.cutoff(length: 25)
        }
        
        if let ratingEmoji = self.post?.ratingEmoji {
            if extraRatingEmojis.contains(ratingEmoji) {
                shortDisplayLocationName.append(" \(ratingEmoji)")
            }
        }
        
        let attributedTextCaption = NSMutableAttributedString(string: shortDisplayLocationName, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.legitColor(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .noteworthyBold, size: 16)]))
        
        
        let paragraphStyle = NSMutableParagraphStyle()
        
        // *** set LineSpacing property in points ***
        paragraphStyle.lineSpacing = 0 // Whatever line spacing you want in points
        
        // *** Apply attribute to string ***
        attributedTextCaption.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedTextCaption.length))
        
        // *** Set Attributed String to your label ***
        self.locationNameLabel.attributedText = attributedTextCaption
        self.locationNameLabel.sizeToFit()
    }
    
//  PHOTOS
    
    let userProfileImageView: CustomImageView = {
        
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 2
        return iv
        
    }()
    
    let photoImageScrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.backgroundColor = .white
        return scroll
    }()
    
    let photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .white
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        
        return iv
        
    }()
    
    let photoCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textColor = UIColor.darkGray
        label.backgroundColor = UIColor.white
        label.layer.cornerRadius = 5
        label.layer.borderWidth = 0
        label.layer.masksToBounds = true
        label.alpha = 0.5
        return label
    }()
    
// STAR RATING

    var starRatingLabel = RatingLabel(ratingScore: 0, frame: CGRect.zero)
    var starRatingHide: NSLayoutConstraint?
    var starRatingDisplay: NSLayoutConstraint?
    
    
    let starRating: CosmosView = {
        let iv = CosmosView()
        iv.settings.fillMode = .half
        iv.settings.totalStars = 5
        //        iv.settings.starSize = 30
        iv.settings.starSize = 15
        iv.settings.updateOnTouch = false
        iv.settings.filledImage = #imageLiteral(resourceName: "star_rating_filled_mid").withRenderingMode(.alwaysOriginal)
        iv.settings.emptyImage = #imageLiteral(resourceName: "star_rating_unfilled").withRenderingMode(.alwaysOriginal)
        iv.rating = 0
        iv.settings.starMargin = 1
        return iv
    }()
    
//    LEGIT ICON
    
    lazy var legitIcon: UILabel = {
        let label = UILabel()
        label.text = "👌"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textAlignment = NSTextAlignment.right
        label.backgroundColor = UIColor.clear
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openLegitList)))
        label.isUserInteractionEnabled = true
        return label
    }()
    var legitIconWidth: NSLayoutConstraint?

    
    @objc func openLegitList(){
        print("Open Legit List")
        if let legitIndex = self.postListNames.firstIndex(of: legitListName){
            var selectedListName = self.postListNames[legitIndex]
            var selectedListId = self.postListIds[legitIndex]
            delegate?.didTapExtraTag(tagName: selectedListName, tagId: selectedListId, post: post!)
        }
    }
    
//    BOOKMARK ICON
    lazy var bookmarkIcon: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal), for: .normal)
        button.backgroundColor = UIColor.clear
        button.addTarget(self, action: #selector(openBookmark), for: .touchUpInside)
        return button
    }()
    
    var bookmarkIconHide: NSLayoutConstraint?

    
    
    @objc func openBookmark(){
        print("Open Bookmark List")
            if let bookmarkId = self.post?.selectedListId?.key(forValue: bookmarkListName){
                delegate?.didTapExtraTag(tagName: bookmarkListName, tagId: bookmarkId, post: post!)
            } else if let bookmarkListIndex = CurrentUser.lists.firstIndex(where: { (list) -> Bool in
                list.name == bookmarkListName
            }) {
                delegate?.didTapExtraTag(tagName: bookmarkListName, tagId: CurrentUser.lists[bookmarkListIndex].id!, post: post!)
            } else {
                print("Can't Find User Bookmark List: ", CurrentUser.uid)
            }
        }

    
//  LOCATION
    
    let locationView: UIView = {
        let uv = UIView()
        let locationTapGesture = UITapGestureRecognizer(target: self, action: #selector(locationTap))
        uv.addGestureRecognizer(locationTapGesture)
        uv.isUserInteractionEnabled = true
        uv.backgroundColor = UIColor.clear
        return uv
    }()
    
    let locationDistanceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.mainBlue()
        label.textAlignment = NSTextAlignment.left
        return label
    }()
    
    let locationNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.left
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
// Price
    
    let priceLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.init(hexColor: "4caf50")
        label.textColor = UIColor.init(hexColor: "ffc107")
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textAlignment = NSTextAlignment.center
        label.lineBreakMode = .byCharWrapping
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true

        return label
    }()
    
    
// USERNAME

    let usernameView: UIView = {
        let uv = UIView()
        uv.backgroundColor = UIColor.clear
        let locationTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleComment))
        uv.addGestureRecognizer(locationTapGesture)
        uv.isUserInteractionEnabled = true
        uv.backgroundColor = UIColor.clear
        return uv
    }()
    
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    
    
//  EMOJIS
    
    var emojiArray = EmojiButtonArray(emojis: [], frame: CGRect(x: 0, y: 0, width: 0, height: 25))

    
    let emojiDetailLabel: PaddedUILabel = {
        let label = PaddedUILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 25)
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.rgb(red: 255, green: 242, blue: 230)
        label.layer.cornerRadius = 30/2
        label.layer.borderWidth = 0.25
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.masksToBounds = true
        return label
    }()
    
    
    func didTapEmoji(index: Int?, emoji: String) {
        guard let index = index else {
            print("No Index For emoji \(emoji)")
            return
        }
        guard let displayEmoji = self.post?.nonRatingEmoji[index] else {return}
        guard let  displayEmojiTag = self.post?.nonRatingEmojiTags[index] else {return}
//        self.delegate?.displaySelectedEmoji(emoji: displayEmoji, emojitag: displayEmojiTag)
        
        print("Selected Emoji \(emoji) : \(index)")
        
        var captionDelay = 3
        emojiDetailLabel.text = "\(displayEmoji)  \(displayEmojiTag)"
        emojiDetailLabel.alpha = 1
        emojiDetailLabel.sizeToFit()
        
        UIView.animate(withDuration: 0.5, delay: TimeInterval(captionDelay), options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.emojiDetailLabel.alpha = 0
        }, completion: { (finished: Bool) in
        })
    }
    
    func hideEmojiDetailLabel(){
        self.emojiDetailLabel.alpha = 0
    }
    
    func setupEmojis(){
        
        if let price = self.post?.price {
            priceLabel.text = "\(price) "
            priceLabel.sizeToFit()
        } else {
            priceLabel.text = ""
            priceLabel.sizeToFit()
        }
        
        
//        print("REFRESH EMOJI ARRAYS")
        if let displayEmojis = self.post?.nonRatingEmoji{
            emojiArray.emojiLabels = displayEmojis
        } else {
            emojiArray.emojiLabels = []
        }
//        print("UPDATED EMOJI ARRAY: \(emojiArray.emojiLabels)")
        emojiArray.setEmojiButtons()
        emojiArray.sizeToFit()
//        print("REFRESH EMOJI ARRAYS - setEmojiButtons")
    }
    
// CAPTION

    let captionTextView: UITextView = {
        let tv = UITextView()
        tv.isScrollEnabled = false
        tv.textContainer.maximumNumberOfLines = 0
        tv.textContainerInset = UIEdgeInsets.zero
        tv.textContainer.lineBreakMode = .byTruncatingTail
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.isEditable = false
        return tv
    }()
    
    func expandTextView(){
        guard let post = self.post else {return}
        captionViewHeightConstraint?.isActive = false
        captionTextView.textContainer.maximumNumberOfLines = 0
        
        // Set Up Caption
        
        let attributedTextCaption = NSMutableAttributedString(string: post.user.username, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
        
        attributedTextCaption.append(NSAttributedString(string: " \(post.caption)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 14)])))
        
//        attributedTextCaption.append(NSAttributedString(string: "\n\n", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 4)]))
        
        self.captionTextView.attributedText = attributedTextCaption
        self.captionTextView.sizeToFit()
        
        
        
//        self.delegate?.expandPost(post: post, newHeight: self.captionTextView.frame.height - captionViewHeight)
//        print(self.captionTextView.frame.height, self.captionTextView.intrinsicContentSize)
        
    }
    
    @objc func HandleTap(sender: UITapGestureRecognizer) {
        
        let myTextView = sender.view as! UITextView //sender is TextView
        let layoutManager = myTextView.layoutManager //Set layout manager
        
        // location of tap in myTextView coordinates
        
        var location = sender.location(in: myTextView)
        
        if let tapPosition = captionTextView.closestPosition(to: location) {
            if let textRange = captionTextView.tokenizer.rangeEnclosingPosition(tapPosition , with: .word, inDirection: convertToUITextDirection(1)) {
                let tappedWord = captionTextView.text(in: textRange)
                print("Word: \(tappedWord)" ?? "")
                if tappedWord == post?.user.username.replacingOccurrences(of: "@", with: "") {
                    self.delegate?.didTapUser(post: self.post!)
                } else {
//                    self.expandTextView()
                    self.handleComment()
//                    self.delegate?.didTapComment(post: self.post!)
                }
            }
        }
        
        //        To Detect if textview is truncated
        //        if textView.contentSize.height > textView.bounds.height

        
    }
    
    func word(atPosition: CGPoint) -> String? {
        if let tapPosition = captionTextView.closestPosition(to: atPosition) {
            if let textRange = captionTextView.tokenizer.rangeEnclosingPosition(tapPosition , with: .word, inDirection: convertToUITextDirection(1)) {
                let tappedWord = captionTextView.text(in: textRange)
                print("Word: \(tappedWord)" ?? "")
                return tappedWord
            }
            return nil
        }
        return nil
    }
    
    let captionView: UIView = {
        let view = UIView()
//        view.layer.backgroundColor = UIColor.lightGray.cgColor.copy(alpha: 0.5)
        view.layer.backgroundColor = UIColor.white.cgColor.copy(alpha: 0.5)

        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    var captionViewHeightConstraint: NSLayoutConstraint? = nil
    var showListCollectionViewConstraint: NSLayoutConstraint? = nil
    var hideListCollectionViewConstraint: NSLayoutConstraint? = nil

    
    var captionDisplayed: Bool = false
    
    let captionBubble: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 30)
        label.textAlignment = NSTextAlignment.center
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        label.adjustsFontSizeToFitWidth = true
        return label
    }()

    
//        DATE

    let postDateLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.lightGray
        label.numberOfLines = 0
        return label
    }()
    
//    OPTIONS
    
    lazy var optionsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("•••", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(handleOptions), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        return button
    }()
    

    @objc func handleOptions() {
        guard let post = post else {return}
        print("Options Button Pressed")
        delegate?.userOptionPost(post: post)
    }

    
// LISTS
    var creatorListIds: [String] = []
    var postListIds: [String] = []
    var postListNames: [String] = []
    
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
//
//
//// Extra Tags
//
//    let extraTagView: UIView = {
//        let uv = UIView()
//        uv.backgroundColor = UIColor.white
//        return uv
//    }()
//
//    let extraTagFontSize: CGFloat = 13
//    let extraTagViewHeightSize: CGFloat = 40
//    var extraTagViewHeight:NSLayoutConstraint?
//
//    var extraTagsNameArray: [String] = []
//    var extraTagsIdArray: [String] = []
//    var userTagsNameArray: [String] = []
//    var userTagsIdArray: [String] = []
//    var creatorTagsNameArray: [String] = []
//    var creatorTagsIdArray: [String] = []
//
//    var extraTagsArray:[UIButton] = []
//    lazy var extraTagLabel1 = UIButton()
//    lazy var extraTagLabel2 = UIButton()
//    lazy var extraTagLabel3 = UIButton()
//    lazy var extraTagLabel4 = UIButton()
//    lazy var extraTagLabel5 = UIButton()
//    lazy var extraTagLabel6 = UIButton()
//
//
//    func extraTagselected(_ sender: UIButton){
//        guard let post = post else {return}
//        let listTag = sender.tag
//
//        var selectedListName = self.extraTagsNameArray[listTag]
//        var selectedListId = self.extraTagsIdArray[listTag]
//
//        print("Selected Creator Tag: \(selectedListName), \(selectedListId)")
//        delegate?.didTapExtraTag(tagName: selectedListName, tagId: selectedListId, post: post)
//    }
//
//    func setupExtraTags() {
//
//        // Refresh Tags
//        extraTagsNameArray.removeAll()
//        extraTagsIdArray.removeAll()
//        userTagsNameArray.removeAll()
//        userTagsIdArray.removeAll()
//        creatorTagsNameArray.removeAll()
//        creatorTagsIdArray.removeAll()
//
//        // Reset Extra Tags
//        extraTagsArray = [extraTagLabel1, extraTagLabel2, extraTagLabel3, extraTagLabel4,extraTagLabel5,extraTagLabel6]
//
//
//        guard let uid = Auth.auth().currentUser?.uid else {
//            print("SetupUserTag: Invalid Current User UID")
//            return
//        }
//
//        let userCreatorInd = self.post?.creatorUID == uid
//
//        for label in self.extraTagsArray {
//            label.setTitle(nil, for: .normal)
//            label.setImage(nil, for: .normal)
//            label.layer.borderWidth = 0
//            label.removeFromSuperview()
//        }
//
//        // Creator Created Tags
//        if post?.creatorListId != nil {
//            var listCount = post?.creatorListId?.count
//
//            // Add Legit List
//            for list in (post?.creatorListId)! {
//                if list.value == legitListName {
//                    creatorTagsNameArray.append(list.value)
//                    creatorTagsIdArray.append(list.key)
//                }
//            }
//
//            // Add Other List
//            for list in (post?.creatorListId)! {
//                if list.value != legitListName && list.value != bookmarkListName {
//                    if userCreatorInd && creatorTagsNameArray.count > 3 {
//                        // If user is creator, show up to 3 full tags
//                        creatorTagsNameArray.append("+\(listCount! - 3)")
//                        creatorTagsIdArray.append("creatorLists")
//                    } else if !userCreatorInd && creatorTagsNameArray.count > 2 {
//                        // If user is NOT creator, show up to 2 full tags
//                        creatorTagsNameArray.append("+\(listCount! - 2)")
//                        creatorTagsIdArray.append("creatorLists")
//                    } else {
//                        creatorTagsNameArray.append(list.value)
//                        creatorTagsIdArray.append(list.key)
//                    }
//                }
//            }
//        }
//
//        // User Created Tags if user is not creator
//
//
//        // We only include select list extra tags if the current user is not the post creator, since they will already be included in the creator's list
//
//        if post?.creatorUID != uid && post?.selectedListId != nil {
//
//            var userListCount = post?.selectedListId?.count
//
//            // User Bookmarks
////            for list in (post?.selectedListId)! {
////                if list.value == bookmarkListName {
////                    userTagsNameArray.append(list.value)
////                    userTagsIdArray.append(list.key)
////                }
////            }
//
//            // Add Other User List
//            for list in (post?.selectedListId)! {
//                if list.value != legitListName && list.value != bookmarkListName {
//                    if (creatorTagsNameArray.count + userTagsNameArray.count) > 5 {
//                        userTagsNameArray.append("+\(userListCount! - userTagsNameArray.count)")
//                        userTagsIdArray.append("userLists")
//                    } else {
//                        userTagsNameArray.append(list.value)
//                        userTagsIdArray.append(list.key)
//                    }
//                }
//            }
//        }
//
//
//
//
//        // Creator Price Tag
//        //        if post?.price != nil {
//        //            creatorTagsNameArray.append((post?.price)!)
//        //            creatorTagsIdArray.append("price")
//        //        }
//
//        // Add User Tags to Extra Tags
//        extraTagsNameArray = creatorTagsNameArray + userTagsNameArray
//        extraTagsIdArray = creatorTagsIdArray + userTagsIdArray
//
//        // Creator Tag Button Label
//        if extraTagsNameArray.count > 0 {
//            for (index, listName) in (self.extraTagsNameArray.enumerated()) {
//
//                // Default Tag Settings
//
//                extraTagsArray[index].tag = index
//                extraTagsArray[index].setTitle(extraTagsNameArray[index], for: .normal)
//                extraTagsArray[index].titleLabel?.font = UIFont.boldSystemFont(ofSize: extraTagFontSize)
//                extraTagsArray[index].titleLabel?.textAlignment = NSTextAlignment.center
//                extraTagsArray[index].setTitleColor(UIColor.white, for: .normal)
//
//
////                extraTagsArray[index].layer.backgroundColor = UIColor.legitColor().cgColor
//                extraTagsArray[index].layer.backgroundColor = UIColor.legitColor().cgColor
//                extraTagsArray[index].layer.borderColor = UIColor.white.cgColor
//                extraTagsArray[index].layer.borderWidth = 1
//
//                extraTagsArray[index].layer.cornerRadius = 5
//                extraTagsArray[index].layer.masksToBounds = true
//                extraTagsArray[index].contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
//                extraTagsArray[index].addTarget(self, action: #selector(extraTagselected(_:)), for: .touchUpInside)
//
//
//                // Creator Tags
//                if index < creatorTagsNameArray.count && post?.creatorUID != uid{
//                    extraTagsArray[index].layer.backgroundColor = UIColor(hexColor: "FE5F55").cgColor
//
//                }
//
//                if extraTagsNameArray[index] == bookmarkListName {
//                    // Only non creator can bookmark
//                    extraTagsArray[index].setImage(#imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal), for: .normal)
//                    extraTagsArray[index].layer.backgroundColor = UIColor.clear.cgColor
//                    extraTagsArray[index].layer.borderColor = UIColor.clear.cgColor
//                    extraTagsArray[index].setTitle(nil, for: .normal)
//                }
//
//                else if extraTagsNameArray[index] == legitListName {
//                    // Only Post Creator can put it as legit
//                    extraTagsArray[index].setImage(#imageLiteral(resourceName: "legit").withRenderingMode(.alwaysOriginal), for: .normal)
//                }
//
////                else if extraTagsIdArray[index] == "price" {
////                    extraTagsArray[index].setTitleColor(UIColor.white, for: .normal)
////                    extraTagsArray[index].layer.backgroundColor = UIColor.legitColor().cgColor
////                }
//
//                else {
//                    // Non Legit or Bookmark Extra Tags
//
//                    // Adding # to tag Names
//                    if extraTagsIdArray[index] == "creatorLists" || extraTagsIdArray[index] == "userLists" {
//                        extraTagsArray[index].setTitle(extraTagsNameArray[index].truncate(length: 10) + "#", for: .normal)
//                    } else {
//                        extraTagsArray[index].setTitle("#" + extraTagsNameArray[index].truncate(length: 10), for: .normal)
//                    }
//
//                    // Creator Tags
//                    if index < creatorTagsNameArray.count && post?.creatorUID != uid{
////                        Color creator extra tags differently if user is not post creator
//                        extraTagsArray[index].layer.backgroundColor = UIColor(hexColor: "FE5F55").cgColor
////                        extraTagsArray[index].setTitleColor(UIColor.black, for: .normal)
//
//                    }
//                }
//
//                // Check If Private
//                if let curList = CurrentUser.lists.first(where: { (list) -> Bool in
//                    list.id == extraTagsIdArray[index]
//                }){
//                    if curList.publicList == 0{
//                        //Private List
//                        extraTagsArray[index].setTitleColor(UIColor.privateColor(), for: .normal)
//                    }
//                }
//
//                // Add Tags to View
//                let displayButton = extraTagsArray[index]
//                self.addSubview(displayButton)
//
//                if index == 0{
//                    displayButton.anchor(top: nil, left: extraTagView.leftAnchor, bottom: nil, right: nil, paddingTop: 3, paddingLeft: 10, paddingBottom: 3, paddingRight: 0, width: 0, height: 25)
//                    displayButton.centerYAnchor.constraint(equalTo: extraTagView.centerYAnchor).isActive = true
//                    displayButton.rightAnchor.constraint(lessThanOrEqualTo: locationDistanceLabel.leftAnchor, constant: 1).isActive = true
//                } else {
//                    displayButton.anchor(top: nil, left: extraTagsArray[index - 1].rightAnchor, bottom: nil, right: nil, paddingTop: 3, paddingLeft: 6, paddingBottom: 3, paddingRight: 0, width: 0, height: 25)
//                    displayButton.centerYAnchor.constraint(equalTo: extraTagView.centerYAnchor).isActive = true
//                    displayButton.rightAnchor.constraint(lessThanOrEqualTo: locationDistanceLabel.leftAnchor, constant: 1).isActive = true
//
//                }
//            }
//        }
//
////        if extraTagsNameArray.count == 0 {
////            extraTagViewHeight?.constant = 0
////        } else {
////            extraTagViewHeight?.constant = extraTagViewHeightSize
////        }
//    }
//
    func setupRatingLegitIcon(){
        
        if (self.post?.rating)! != 0 {
//            starRatingLabel.rating = (self.post?.rating)!
//            self.starRatingLabelWidth?.constant = self.starRatingSize
//            self.starRatingLabelWidth?.isActive = false
            
            self.starRating.rating = (self.post?.rating)!
            if starRating.rating >= 4 {
                starRating.settings.filledImage = #imageLiteral(resourceName: "star_rating_filled_high").withRenderingMode(.alwaysOriginal)
            } else {
                starRating.settings.filledImage = #imageLiteral(resourceName: "star_rating_filled_mid").withRenderingMode(.alwaysOriginal)
            }
            
            self.starRatingHide?.isActive = false
            self.starRating.isHidden = (self.starRatingHide?.isActive)!
            self.starRating.sizeToFit()

//            self.starRatingDisplay?.isActive = true
//            self.starRatingLabel.sizeToFit()
        } else {
//            self.starRatingLabelWidth?.constant = 0
            self.starRatingHide?.isActive = true
            self.starRating.isHidden = (self.starRatingHide?.isActive)!
            self.starRating.sizeToFit()

//            self.starRatingDisplay?.isActive = false

        }
        
        if (self.post?.isLegit)! {
            self.legitIconWidth?.isActive = false
            self.legitIcon.sizeToFit()
        } else {
            self.legitIconWidth?.isActive = true
        }
        
        if (self.post?.selectedListId?.contains(where: { (key, value) -> Bool in
            value == bookmarkListName
        }))!{
            self.bookmarkIconHide?.isActive = false
            self.bookmarkIcon.sizeToFit()
        } else {
            self.bookmarkIconHide?.isActive = true
        }
        
    }

    @objc func captionBubbleTap(){
        
        print(post)
        
        if captionDisplayed {
            captionView.alpha = 0
            captionDisplayed = false
            captionView.layer.removeAllAnimations()
        } else {
            captionView.alpha = 1
            captionDisplayed = true
            
            //            let captionViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(testprint))
            //            captionView.isUserInteractionEnabled = true
            //            captionView.addGestureRecognizer(captionViewTapGesture)
            //
            //            let captionTapGesture = UITapGestureRecognizer(target: self, action: #selector(testprint))
            //            captionBubble.isUserInteractionEnabled = true
            //            captionBubble.addGestureRecognizer(captionTapGesture)
            
            // Makes Captions Disappear fast if there is no caption
            
            var captionDelay = 0.0 as Double
            
            if (captionBubble.attributedText?.length)! > 1 && (captionBubble.text != "No Caption") {
                captionDelay = 3
            } else {
                captionDelay = 1
            }
            
            UIView.animate(withDuration: 0.5, delay: captionDelay, options: UIView.AnimationOptions.curveEaseOut, animations: {
                self.captionView.alpha = 0
            }, completion: { (finished: Bool) in
                self.captionDisplayed = false
            })
        }
    }
    
    func hideCaptionBubble(){
        
        self.captionView.alpha = 0
        
    }
    
    func fadeViewInThenOut(inputView : UIView, delay: TimeInterval) {
        
        inputView.alpha = 1
        inputView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        let animationDuration = 0.0
        
        // Fade in the view
        UIView.animate(withDuration: animationDuration,delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak inputView] in
                        
                        inputView?.transform = .identity
                        
        }) { (Bool) -> Void in
            
            // After the animation completes, fade out the view after a delay
            
            UIView.animate(withDuration: animationDuration, delay: delay, options: .curveEaseInOut, animations: { () -> Void in
                inputView.alpha = 0
            },
                           completion: nil)
        }
    }
    
    
    
    var locationViewHeight: CGFloat = 30
    var captionViewHeight: CGFloat = 45

    var profileImageSize: CGFloat = 50 - 10
    var starRatingSize: CGFloat = 50 - 10 - 10 - 5

    var headerHeight: CGFloat = 45 //40
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // INITT
        self.backgroundColor = UIColor.clear
        
        addSubview(photoImageScrollView)
        addSubview(userProfileImageView)
        addSubview(listButton)
        
        let headerView = UIView()
        addSubview(headerView)
        headerView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: headerHeight)
        
        // Star Rating and Legit
//        starRatingLabel = RatingLabel.init(ratingScore: 0, frame: CGRect(x: 0, y: 0, width: starRatingSize, height: starRatingSize))
//        starRatingLabel.layer.borderColor = UIColor.black.cgColor
//        addSubview(starRatingLabel)
//
//        starRatingLabel.anchor(top: nil, left: nil, bottom: nil, right: headerView.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: starRatingSize)
//        starRatingLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
//
//        starRatingHide = starRatingLabel.widthAnchor.constraint(equalToConstant: 0)
//        starRatingDisplay = starRatingLabel.widthAnchor.constraint(equalToConstant: starRatingSize)
//        starRatingHide?.isActive = true
        
        
        addSubview(starRating)
        starRating.anchor(top: nil, left: nil, bottom: nil, right: headerView.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        starRating.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        starRating.sizeToFit()
        starRatingHide = starRating.widthAnchor.constraint(equalToConstant: 0)
        starRatingDisplay = starRating.heightAnchor.constraint(equalToConstant: starRatingSize)
        starRatingHide?.isActive = true
        
        
        // Add Location Distance
        addSubview(locationDistanceLabel)
        locationDistanceLabel.anchor(top: nil, left: nil, bottom: nil, right: starRating.leftAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        locationDistanceLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        locationDistanceLabel.sizeToFit()
        locationDistanceLabel.isUserInteractionEnabled = true
        locationDistanceLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(activateMap)))
        
        
        // Add Location Name
        addSubview(locationNameLabel)
//        locationNameLabel.anchor(top: nil, left: headerView.leftAnchor, bottom: nil, right: locationDistanceLabel.leftAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        locationNameLabel.anchor(top: nil, left: headerView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 3, paddingRight: 10, width: 0, height: 0)
        locationNameLabel.bottomAnchor.constraint(lessThanOrEqualTo: headerView.bottomAnchor).isActive = true
        locationNameLabel.rightAnchor.constraint(lessThanOrEqualTo: locationDistanceLabel.leftAnchor).isActive = true
//        locationNameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: frame.width/2).isActive = true
        locationNameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: frame.width * 2 / 3).isActive = true

        
        locationNameLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        locationNameLabel.sizeToFit()
        locationNameLabel.isUserInteractionEnabled = true
        locationNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(locationTap)))
    

        // Photo Image View and Complex User Interactions
        
        // Need to set the frame as scroll view frame width goes to 0 when new cell after the first cell is being made for some reason.
        
        photoImageScrollView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.width)
        photoImageScrollView.anchor(top: headerView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        photoImageScrollView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
        photoImageScrollView.isPagingEnabled = true
        photoImageScrollView.delegate = self
        
        setupPhotoImageScrollView()


//        addSubview(bookmarkIcon)
//        bookmarkIcon.anchor(top: nil, left: nil, bottom: nil, right: starRatingLabel.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 2, width: 0, height: 0)
//        bookmarkIcon.centerYAnchor.constraint(equalTo: extraTagView.centerYAnchor).isActive = true
//        bookmarkIconHide = bookmarkIcon.widthAnchor.constraint(equalToConstant: 0)
//        bookmarkIconHide?.isActive = true

        

        
//        addSubview(legitIcon)
//        legitIcon.anchor(top: nil, left: nil, bottom: photoImageView.topAnchor, right: nil, paddingTop: 10, paddingLeft: 0, paddingBottom: 3, paddingRight: 10, width: 0, height: starRatingSize)
////        legitIcon.centerXAnchor.constraint(equalTo: userProfileImageView.centerXAnchor).isActive = true
//        legitIcon.centerXAnchor.constraint(equalTo: userProfileImageView.centerXAnchor).isActive = true
//        legitIcon.centerYAnchor.constraint(equalTo: extraTagView.centerYAnchor).isActive = true
////        legitIcon.centerYAnchor.constraint(equalTo: starRatingLabel.centerYAnchor).isActive = true
        legitIconWidth = legitIcon.widthAnchor.constraint(equalToConstant: 0)
//        legitIconWidth?.isActive = true
        
        
        
        // Username Profile Picture
        userProfileImageView.anchor(top: photoImageScrollView.topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: profileImageSize, height: profileImageSize)
        userProfileImageView.layer.cornerRadius = profileImageSize/2
        userProfileImageView.layer.borderWidth = 2
        userProfileImageView.layer.borderColor = UIColor.white.cgColor
        
        userProfileImageView.isUserInteractionEnabled = true
        userProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(usernameTap)))
        
        // Add Message Button
//        addSubview(sendMessageButton)
//        sendMessageButton.anchor(top: nil, left: nil, bottom: photoImageScrollView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 25, height: 25)
//        sendMessageButton.centerXAnchor.constraint(equalTo: userProfileImageView.centerXAnchor).isActive = true
//
//
        setupEmojiDetails()
        setupActionBar()
       // setupSocialStats()
        setupPostCaptions()
//        setupListCollectionView()
        setupCaptionBubble()
    
    }
    
    func setupPhotoImageScrollView(){
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(photoDoubleTapped))
        doubleTap.numberOfTapsRequired = 2
        photoImageScrollView.addGestureRecognizer(doubleTap)
        photoImageScrollView.isUserInteractionEnabled = true
        
        //        let captionTapGesture = UITapGestureRecognizer(target: self, action: #selector(displayCaptionBubble))
        let photoTapGesture = UITapGestureRecognizer(target: self, action: #selector(captionBubbleTap))
        photoImageScrollView.addGestureRecognizer(photoTapGesture)
        photoTapGesture.require(toFail: doubleTap)
        
        photoImageScrollView.contentSize.width = photoImageScrollView.frame.width
        
        photoImageView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.width)
        photoImageScrollView.addSubview(photoImageView)
        photoImageView.tag = 0
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.pinch(sender:)))
        pinch.delegate = self
        //        self.photoImageView.addGestureRecognizer(pinch)
        self.photoImageScrollView.addGestureRecognizer(pinch)
        
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.pan(sender:)))
        pan.delegate = self
        //        self.photoImageView.addGestureRecognizer(pan)
        self.photoImageScrollView.addGestureRecognizer(pan)
        
        
        // Add Photo Count Label
        
        addSubview(photoCountLabel)
        photoCountLabel.anchor(top: nil, left: leftAnchor, bottom: photoImageScrollView.bottomAnchor, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 5, width: 0, height: 0)
        photoCountLabel.sizeToFit()
    }
    
    func testprint(){
        print("test")
    }
    
    @objc func activateMap() {
        SharedFunctions.openGoogleMaps(lat: self.post?.locationGPS?.coordinate.latitude, long: self.post?.locationGPS?.coordinate.longitude)
    }
    


    
    func setupActionBar(){
        // Action Bar
        addSubview(actionBar)
        actionBar.anchor(top: photoImageScrollView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        setupActionButtons()
        
    }
    
    func setupListCollectionView(){
        listCollectionView.register(ListDisplayCell.self, forCellWithReuseIdentifier: cellId)
        let layout = ListDisplayFlowLayout()
        listCollectionView.collectionViewLayout = layout
        listCollectionView.backgroundColor = UIColor.clear
        listCollectionView.isScrollEnabled = true
        listCollectionView.showsHorizontalScrollIndicator = false
        
//        addSubview(listCollectionView)
//        listCollectionView.anchor(top: photoImageScrollView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: locationViewHeight)
        
    }
    
    func setupEmojiDetails(){
        emojiArray.alignment = .right
        emojiArray.delegate = self
        addSubview(emojiArray)
        emojiArray.anchor(top: nil, left: nil, bottom: photoImageScrollView.bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 10, paddingRight: 10, width: 0, height: 25)
        
        addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top: nil, left: leftAnchor, bottom: photoImageScrollView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 3, paddingRight: 0, width: 0, height: 0)
        //        emojiDetailLabel.centerXAnchor.constraint(equalTo: photoImageScrollView.centerXAnchor).isActive = true
        emojiDetailLabel.alpha = 0
        

//        // Location Bar
//        addSubview(locationView)
//        locationView.anchor(top: actionBar.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: locationViewHeight)

        
//        addSubview(priceLabel)
//        priceLabel.anchor(top: nil, left: locationNameLabel.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        priceLabel.centerYAnchor.constraint(equalTo: locationNameLabel.centerYAnchor).isActive = true
//
//        addSubview(emojiArray)
//        emojiArray.anchor(top: nil, left: priceLabel.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 20)
//        emojiArray.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor)
        

//        emojiArray.centerYAnchor.constraint(equalTo: locationNameLabel.centerYAnchor).isActive = true
//
//        addSubview(priceLabel)
//        priceLabel.anchor(top: nil, left: emojiArray.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        priceLabel.centerYAnchor.constraint(equalTo: emojiArray.centerYAnchor).isActive = true

    }
    
    func setupSocialStats(){
        // Stats View
        addSubview(socialStatsView)
        socialStatsView.anchor(top: captionTextView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        socialStatsViewHeight = socialStatsView.heightAnchor.constraint(equalToConstant: socialViewHeight)
        socialStatsViewHeight?.isActive = true
        

        
        addSubview(followVoteStatsLabel)
        followVoteStatsLabel.anchor(top: nil, left: socialStatsView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        followVoteStatsLabel.centerYAnchor.constraint(equalTo: socialStatsView.centerYAnchor).isActive = true
        followVoteStatsLabel.isUserInteractionEnabled = true
        followVoteStatsLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayFollowingVotes)))
        
        addSubview(followListStatsLabel)
        followListStatsLabel.anchor(top: nil, left: followVoteStatsLabel.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        followListStatsLabel.centerYAnchor.constraint(equalTo: socialStatsView.centerYAnchor).isActive = true
        followListStatsLabel.isUserInteractionEnabled = true
        followListStatsLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayFollowLists)))
        
        addSubview(voteStatsTextView)
        voteStatsTextView.anchor(top: nil, left: followListStatsLabel.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        voteStatsTextView.centerYAnchor.constraint(equalTo: socialStatsView.centerYAnchor).isActive = true
//        voteStatsTextView.backgroundColor = UIColor.yellow
        voteStatsTextView.sizeToFit()
        voteStatsTextView.isUserInteractionEnabled = true
        
        let voteStatsTextViewTap = UITapGestureRecognizer(target: self, action: #selector(self.HandleVoteStatsTap(sender:)))
        voteStatsTextViewTap.delegate = self
        voteStatsTextView.addGestureRecognizer(voteStatsTextViewTap)

        
    }
    
    
    func setupPostCaptions(){


    // Username View
//        addSubview(usernameView)
//        usernameView.anchor(top: locationView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: captionViewHeight)
//
//        addSubview(usernameLabel)
//        usernameLabel.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        usernameLabel.centerYAnchor.constraint(equalTo: usernameView.centerYAnchor).isActive = true
        
        
        addSubview(postDateLabel)
        postDateLabel.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 2, paddingLeft: 10, paddingBottom: 5, paddingRight: 0, width: 0, height: 15)
        postDateLabel.sizeToFit()
        
        addSubview(optionsButton)
        optionsButton.anchor(top: postDateLabel.topAnchor, left: nil, bottom: postDateLabel.bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        optionsButton.widthAnchor.constraint(equalTo: optionsButton.heightAnchor).isActive = true
        optionsButton.centerYAnchor.constraint(equalTo: postDateLabel.centerYAnchor).isActive = true
        optionsButton.isHidden = true
        
        listCollectionView.register(ListDisplayCell.self, forCellWithReuseIdentifier: cellId)
        let layout = ListDisplayFlowLayout()
        listCollectionView.collectionViewLayout = layout
        listCollectionView.backgroundColor = UIColor.clear
        listCollectionView.isScrollEnabled = true
        listCollectionView.showsHorizontalScrollIndicator = false
        
        addSubview(listCollectionView)
        listCollectionView.anchor(top: nil, left: leftAnchor, bottom: postDateLabel.topAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 3, paddingRight: 0, width: 0, height: locationViewHeight)
        
        addSubview(captionTextView)
        captionTextView.anchor(top: actionBar.bottomAnchor, left: leftAnchor, bottom: listCollectionView.topAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        showListCollectionViewConstraint = captionTextView.bottomAnchor.constraint(equalTo: listCollectionView.topAnchor)
        hideListCollectionViewConstraint = captionTextView.bottomAnchor.constraint(equalTo: postDateLabel.topAnchor)
        showListCollectionViewConstraint?.isActive = true
//        captionViewHeightConstraint = captionTextView.heightAnchor.constraint(equalToConstant: captionViewHeight)
//        captionViewHeightConstraint?.isActive = true
        captionTextView.backgroundColor = UIColor.clear
        captionTextView.sizeToFit()
        captionTextView.isUserInteractionEnabled = true
//        captionTextView.backgroundColor = UIColor.blue.withAlphaComponent(0.5)

        let textViewTap = UITapGestureRecognizer(target: self, action: #selector(self.HandleTap(sender:)))
        textViewTap.delegate = self
        captionTextView.addGestureRecognizer(textViewTap)

        

        


        
//        let bottomDivider = UIView()
//        addSubview(bottomDivider)
//        bottomDivider.backgroundColor = UIColor.lightGray
//        bottomDivider.anchor(top: bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
        
    }
    
    func fillInCaptionBubble(){
        guard let post = self.post else {return}
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        let attributedString = NSMutableAttributedString(string: "", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 30)]))
        
        // Add Location Name
        var attributedCaption = NSMutableAttributedString(string: "\(post.locationName)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .noteworthyBold, size: 20), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkLegitColor()]))
        attributedString.append(attributedCaption)
        
        
        // Add Location Adress
        attributedCaption = NSMutableAttributedString(string: "\n\(post.locationAdress)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 18), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black]))
        attributedString.append(attributedCaption)
        
        for (index,tag) in post.autoTagEmojiTags.enumerated() {
            attributedCaption = NSMutableAttributedString(string: "\n\(post.autoTagEmoji[index]) \(post.autoTagEmojiTags[index].capitalizingFirstLetter())", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 15), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray]))
            attributedString.append(attributedCaption)
        }
        
        if post.price != nil {
            attributedCaption = NSMutableAttributedString(string: "\n\(post.price!)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 18), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.rgb(red: 0, green: 128, blue: 0)]))
            attributedString.append(attributedCaption)

//            var attributedPrice = NSMutableAttributedString(string: "\n", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 15)])
//            attributedString.append(attributedPrice)
//
//            attributedPrice = NSMutableAttributedString(string: "\(post.price!)", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 15), NSForegroundColorAttributeName: UIColor.white, NSBackgroundColorAttributeName: UIColor.rgb(red: 0, green: 204, blue: 102)])
//            attributedString.append(attributedPrice)
        }
        
        
//        if post.caption.length > 0 {
//            let attributedCaption = NSMutableAttributedString(string: "\(post.caption)", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 30)])
//            attributedString.append(attributedCaption)
//        }
        
        //        let rating = NSAttributedString(string: String(describing: " \(post.rating!) "), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 30), NSForegroundColorAttributeName: RatingColors.ratingColor(rating: post.rating)])
        //
        //        if post.rating! > 0 {
        //            attributedString.append(rating)
        //        }
        
//        if post.price != nil {
//            let attributedPrice = NSMutableAttributedString(string: "\(post.price!)", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 25), NSForegroundColorAttributeName: UIColor.white, NSBackgroundColorAttributeName: UIColor.rgb(red: 0, green: 204, blue: 102)])
//            attributedString.append(attributedPrice)
//        }
        
        //        print("AutoTag Emoji: \(post.autoTagEmoji.joined())")
//        if post.autoTagEmoji.count > 0 {
//            let attributedAutoTagEmoji = NSMutableAttributedString(string: " \(post.autoTagEmoji.joined()) ", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 25), NSForegroundColorAttributeName: UIColor.legitColor()])
//
//            attributedString.append(attributedAutoTagEmoji)
//        }
        
        //        captionBubble.numberOfLines = 0
        //        captionBubble.lineBreakMode = .byWordWrapping
        captionBubble.attributedText = attributedString
        captionBubble.numberOfLines = 0
        captionBubble.sizeToFit()

    }
    
    func setupCaptionBubble(){
        
        addSubview(captionView)
        captionView.anchor(top: photoImageScrollView.topAnchor, left: photoImageScrollView.leftAnchor, bottom: nil, right: photoImageScrollView.rightAnchor, paddingTop: 30, paddingLeft: 50, paddingBottom: 0, paddingRight: 50, width: 0, height: 0)
        captionView.bottomAnchor.constraint(lessThanOrEqualTo: photoImageScrollView.bottomAnchor).isActive = true
        
        captionView.addSubview(captionBubble)
        captionBubble.anchor(top: captionView.topAnchor, left: captionView.leftAnchor, bottom: captionView.bottomAnchor, right: captionView.rightAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 0, height: 0)
        //        captionBubble.centerXAnchor.constraint(equalTo: captionView.centerXAnchor).isActive = true
        //        captionBubble.leftAnchor.constraint(lessThanOrEqualTo: captionView.leftAnchor).isActive = true
        //        captionBubble.rightAnchor.constraint(lessThanOrEqualTo: captionView.rightAnchor).isActive = true
        captionBubble.contentMode = .center
        
        // Hide initial caption bubbles
        captionView.alpha = 0
        captionBubble.alpha = 1
    }
    
    
    
    func setupPicturesScroll() {
        
        //        guard let _ = post?.imageUrls else {return}
        
        photoImageScrollView.contentSize.width = photoImageScrollView.frame.width * CGFloat((post?.imageCount)!)
        
        for i in 1 ..< (post?.imageCount)! {
            
            let imageView = CustomImageView()
            if post?.imageUrls[i] == nil && post?.images != nil {
                imageView.image = post?.images![i]
            } else {
                imageView.loadImage(urlString: (post?.imageUrls[i])!)
            }
            imageView.backgroundColor = .white
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.isUserInteractionEnabled = true
            
            let xPosition = self.photoImageScrollView.frame.width * CGFloat(i)
            imageView.frame = CGRect(x: xPosition, y: 0, width: photoImageScrollView.frame.width, height: photoImageScrollView.frame.height)
            
            photoImageScrollView.addSubview(imageView)
            
        }
        //        photoImageScrollView.reloadInputViews()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.currentImage = scrollView.currentPage
    }
    
    
    // Following Creds
    var socialStatsView: UIView = {
        let view = UIView()
        return view
    }()
    var socialStatsViewHeight: NSLayoutConstraint? = nil

    
    let voteStatsTextView: UITextView = {
        let tv = UITextView()
        tv.isScrollEnabled = false
        tv.textContainer.maximumNumberOfLines = 2
        tv.textContainerInset = UIEdgeInsets.zero
        tv.textContainer.lineBreakMode = .byTruncatingTail
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.font = UIFont.boldSystemFont(ofSize: 15)
        tv.textColor = UIColor.legitColor()
        tv.isEditable = false
        return tv
    }()
    
    @objc func HandleVoteStatsTap(sender: UITapGestureRecognizer) {
        
        let myTextView = sender.view as! UITextView //sender is TextView
        let layoutManager = myTextView.layoutManager //Set layout manager
        
        // location of tap in myTextView coordinates
        
        var location = sender.location(in: myTextView)
        
        if let tapPosition = myTextView.closestPosition(to: location) {
            if let textRange = myTextView.tokenizer.rangeEnclosingPosition(tapPosition , with: .word, inDirection: convertToUITextDirection(1)) {
                let tappedWord = myTextView.text(in: textRange)?.replacingOccurrences(of: ",", with: "")
                print("Word: \(tappedWord)" ?? "")
                if displayNamesUid[tappedWord!] != nil {
                    self.delegate?.didTapUserUid(uid: displayNamesUid[tappedWord!]!)
                } else {
//                    self.delegate?.displayPostSocialUsers(post: self.post!, following: true)
                }
            }
        }
    }
    

    var followListStatsLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:14)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.left
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayFollowLists)))
        return label
    }()
    
    var followVoteStatsLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:14)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.left
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayFollowingVotes)))
        return label
    }()
    
    @objc func displayFollowLists(){
        self.delegate?.displayPostSocialLists(post: self.post!, following: true)
    }
    
    @objc func displayFollowingVotes(){
        self.delegate?.displayPostSocialUsers(post: self.post!, following: true)
    }

    @objc func displayAllLists(){
        self.delegate?.displayPostSocialLists(post: self.post!, following: false)
    }
    
    @objc func displayAllVotes(){
        self.delegate?.displayPostSocialUsers(post: self.post!, following: false)
    }
    
    
    // Action Buttons
    
    var actionBar: UIView = {
        let view = UIView()
        //        view.backgroundColor = UIColor.white
        return view
    }()
    
    lazy var voteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "like_unselected").withRenderingMode(.alwaysOriginal), for: .normal)
        button.setImage(#imageLiteral(resourceName: "drool").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleVote), for: .touchUpInside)
        return button
        
    }()
    
    @objc func handleVote() {
        //      delegate?.didLike(for: self)
        
        guard let postId = self.post?.id else {return}
        guard let creatorId = self.post?.creatorUID else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        self.voteButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        self.layoutIfNeeded()
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.voteButton.transform = .identity
                        self?.voteButton.layoutIfNeeded()
                        
            },
                       completion: nil)
        
        var origin: CGPoint = self.photoImageScrollView.center;
        popView = UIView(frame: CGRect(x: origin.x, y: origin.y, width: 200, height: 200))
        popView = UIImageView(image: #imageLiteral(resourceName: "cred_filled").withRenderingMode(.alwaysOriginal))
        popView.contentMode = .scaleToFill
        popView.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
        popView.frame.origin.x = origin.x
        popView.frame.origin.y = origin.y * 0.5
        
        photoImageView.addSubview(popView)
        
        UIView.animate(withDuration: 1,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.popView.transform = .identity
        }) { (done) in
            self.popView.alpha = 0
        }
        
        
        
        
        // Animates before database function is complete
        Database.handleLike(post: self.post) { post in
            self.post = post
            self.setupAttributedSocialCount()
            self.delegate?.refreshPost(post: self.post!)
        }
    }
    
    // Bookmark
    
    lazy var listButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "bookmark_unselected").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleBookmark), for: .touchUpInside)
        button.layer.cornerRadius = button.bounds.size.width/2
        button.layer.masksToBounds = true
        button.clipsToBounds = true
        return button
        
    }()
    
    @objc func handleBookmark() {
        guard let post = post else {return}
        delegate?.didTapBookmark(post: post)
        
    }
    
    // Comments
    
    lazy var commentButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(handleComment), for: .touchUpInside)
        return button
        
    }()
    
    @objc func handleComment() {
        guard let post = post else {return}
        delegate?.didTapComment(post: post)
    }
    
    // Send Message
    
    lazy var sendMessageButton: UIButton = {
        let button = UIButton(type: .system)
        //        button.setImage(#imageLiteral(resourceName: "message").withRenderingMode(.alwaysOriginal), for: .normal)
        button.setImage(#imageLiteral(resourceName: "send_plane").withRenderingMode(.alwaysOriginal), for: .normal)
        
        button.addTarget(self, action: #selector(handleMessage), for: .touchUpInside)
        return button
        
    }()
    
    @objc func handleMessage(){
        guard let post = post else {return}
        delegate?.didTapMessage(post: post)
        
    }
    
    
    let postCountColor = UIColor.darkGray
    
    let listCount: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:14)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.right
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let messageCount: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:14)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.left
        return label
    }()
    
    let commentCount: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:14)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.left
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let voteCount: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:14)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.center
        label.isUserInteractionEnabled = true
        return label
    }()

    
    fileprivate func setupActionButtons() {
        
        guard let post = post else {return}
        
        let voteView = UIView()
        //        voteView.backgroundColor = UIColor.blue
        
        let commentView = UIView()
        //        commentView.backgroundColor = UIColor.yellow
        
        let bookmarkView = UIView()
        //        bookmarkView.backgroundColor = UIColor.blue
        
        let messageView = UIView()
        //        messageView.backgroundColor = UIColor.yellow
        
        let voteContainer = UIView()
        let commentContainer = UIView()
        let listContainer = UIView()
        let messageContainer = UIView()
        let actionStackView = UIStackView(arrangedSubviews: [voteView, commentView, bookmarkView])
        actionStackView.distribution = .fillEqually
        
        addSubview(actionStackView)
        
        
        actionStackView.anchor(top: actionBar.topAnchor, left: leftAnchor, bottom: actionBar.bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
//        addSubview(upVoteButton)
//        addSubview(downVoteButton)
//        addSubview(voteCount)
//
//        upVoteButton.anchor(top: voteView.topAnchor, left: nil, bottom: voteView.bottomAnchor, right: voteView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
//        upVoteButton.widthAnchor.constraint(equalTo: upVoteButton.heightAnchor, multiplier: 1).isActive = true
//
//        downVoteButton.anchor(top: voteView.topAnchor, left: voteView.leftAnchor, bottom: voteView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
//        downVoteButton.widthAnchor.constraint(equalTo: downVoteButton.heightAnchor, multiplier: 1).isActive = true
//
//        voteCount.anchor(top: voteView.topAnchor, left: downVoteButton.rightAnchor, bottom: voteView.bottomAnchor, right: upVoteButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        voteCount.sizeToFit()
        
        // Cred
        voteContainer.addSubview(voteButton)
        voteContainer.addSubview(voteCount)
//        credView.backgroundColor = UIColor.init(hex: "009688")

//        credView.backgroundColor = UIColor.init(hex: "#26A69A")
        voteView.backgroundColor = UIColor.white

        voteButton.anchor(top: voteContainer.topAnchor, left: voteContainer.leftAnchor, bottom: voteContainer.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        voteButton.widthAnchor.constraint(equalTo: voteButton.heightAnchor, multiplier: 1).isActive = true
        
        voteCount.anchor(top: voteContainer.topAnchor, left: voteButton.rightAnchor, bottom: voteContainer.bottomAnchor, right: voteContainer.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        voteCount.centerYAnchor.constraint(equalTo: voteButton.centerYAnchor).isActive = true
        voteCount.sizeToFit()
        voteCount.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayAllVotes)))

        
        addSubview(voteContainer)
        voteContainer.anchor(top: voteView.topAnchor, left: nil, bottom: voteView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        voteContainer.centerXAnchor.constraint(equalTo: voteView.centerXAnchor).isActive = true
        
        // Comments
        
        commentContainer.addSubview(commentButton)
        commentContainer.addSubview(commentCount)
        commentView.backgroundColor = UIColor.white

        commentButton.anchor(top: commentContainer.topAnchor, left: commentContainer.leftAnchor, bottom: commentContainer.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        commentButton.widthAnchor.constraint(equalTo: commentButton.heightAnchor, multiplier: 1).isActive = true
        
        commentCount.anchor(top: commentContainer.topAnchor, left: commentButton.rightAnchor, bottom: commentContainer.bottomAnchor, right: commentContainer.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        commentCount.centerYAnchor.constraint(equalTo: commentButton.centerYAnchor).isActive = true
        commentCount.sizeToFit()
        commentCount.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleComment)))
        
        addSubview(commentContainer)
        commentContainer.anchor(top: commentView.topAnchor, left: nil, bottom: commentView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        commentContainer.centerXAnchor.constraint(equalTo: commentView.centerXAnchor).isActive = true
        
        // Bookmarks
        
        listContainer.addSubview(listButton)
        listContainer.addSubview(listCount)
        bookmarkView.backgroundColor = UIColor.white

        listButton.anchor(top: listContainer.topAnchor, left: listContainer.leftAnchor, bottom: listContainer.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        listButton.widthAnchor.constraint(equalTo: listButton.heightAnchor, multiplier: 1).isActive = true
        listButton.layer.cornerRadius = listButton.bounds.size.width/2

        
        listCount.anchor(top: listContainer.topAnchor, left: listButton.rightAnchor, bottom: listContainer.bottomAnchor, right: listContainer.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        listCount.centerYAnchor.constraint(equalTo: listButton.centerYAnchor).isActive = true
        
        listCount.sizeToFit()
        listCount.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayAllLists)))

        
        addSubview(listContainer)
        listContainer.anchor(top: bookmarkView.topAnchor, left: nil, bottom: bookmarkView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        listContainer.centerXAnchor.constraint(equalTo: bookmarkView.centerXAnchor).isActive = true
        
        
        // Message
        
//        messageContainer.addSubview(sendMessageButton)
//        messageContainer.addSubview(messageCount)
//
//        sendMessageButton.anchor(top: messageContainer.topAnchor, left: messageContainer.leftAnchor, bottom: messageContainer.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        sendMessageButton.widthAnchor.constraint(equalTo: sendMessageButton.heightAnchor, multiplier: 1).isActive = true
//
//        messageCount.anchor(top: messageContainer.topAnchor, left: sendMessageButton.rightAnchor, bottom: messageContainer.bottomAnchor, right: messageContainer.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 20, height: 20)
//        messageCount.centerYAnchor.constraint(equalTo: sendMessageButton.centerYAnchor).isActive = true
//
//        messageCount.text = "10"
//        messageCount.sizeToFit()
        
//        addSubview(messageContainer)
//        messageContainer.anchor(top: messageView.topAnchor, left: nil, bottom: messageView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
//        messageContainer.centerXAnchor.constraint(equalTo: messageView.centerXAnchor).isActive = true
        
        // Format Action Buttons
        
//        voteButton.setImage(post?.hasVoted == 1 ? #imageLiteral(resourceName: "cred_filled").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "cred_unfilled").withRenderingMode(.alwaysOriginal), for: .normal)
        voteButton.setImage(#imageLiteral(resourceName: "drool").alpha((post.hasLiked) ? 1 : 0.5).withRenderingMode(.alwaysOriginal), for: .normal)
        
        listButton.setImage(post.hasPinned == true ? #imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "bookmark_unfilled").withRenderingMode(.alwaysOriginal), for: .normal)

        commentButton.setImage(#imageLiteral(resourceName: "comment_gray").withRenderingMode(.alwaysOriginal), for: .normal)

        
//        listButton.backgroundColor = post?.hasBookmarked == true ? UIColor.white : UIColor.clear
        
//        upVoteButton.setImage(post?.hasVoted == 1 ? #imageLiteral(resourceName: "upvote_selected").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "upvote").withRenderingMode(.alwaysOriginal), for: .normal)
//
//        downVoteButton.setImage(post?.hasVoted == -1 ? #imageLiteral(resourceName: "downvote_selected").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "downvote").withRenderingMode(.alwaysOriginal), for: .normal)
//
//        sendMessageButton.setImage(post?.hasMessaged == true ? #imageLiteral(resourceName: "message_fill").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "message_unfill").withRenderingMode(.alwaysOriginal), for: .normal)
        
        if post.creatorUID == Auth.auth().currentUser?.uid {
            optionsButton.isHidden = false
        } else {
            optionsButton.isHidden = true
        }
        
        // Dividers
        //
        //        let dividerColor = UIColor.lightGray
        //
        //        let div1 = UIView()
        //        div1.backgroundColor = dividerColor
        //        addSubview(div1)
        //        div1.anchor(top: actionStackView.topAnchor, left: commentView.leftAnchor, bottom: actionStackView.bottomAnchor, right: nil, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 1, height: 0)
        //        div1.heightAnchor.constraint(equalTo: actionStackView.heightAnchor, multiplier: 0.4).isActive = true
        //
        //        let div2 = UIView()
        //        div2.backgroundColor = dividerColor
        //        addSubview(div2)
        //        div2.anchor(top: actionStackView.topAnchor, left: bookmarkView.leftAnchor, bottom: actionStackView.bottomAnchor, right: nil, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 1, height: 0)
        //        div2.heightAnchor.constraint(equalTo: actionStackView.heightAnchor, multiplier: 0.4).isActive = true
        //
        //
        //        let div3 = UIView()
        //        div3.backgroundColor = dividerColor
        //        addSubview(div3)
        //        div3.anchor(top: actionStackView.topAnchor, left: messageView.leftAnchor, bottom: actionStackView.bottomAnchor, right: nil, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 1, height: 0)
        //        div3.heightAnchor.constraint(equalTo: actionStackView.heightAnchor, multiplier: 0.4).isActive = true
        //
        //
        
        //        for i in 1 ..< (actionStackView.arrangedSubviews.count - 1){
        //            let div = UIView()
        //            div.widthAnchor.constraint(equalToConstant: 1).isActive = true
        //            div.backgroundColor = .black
        //            addSubview(div)
        //            div.heightAnchor.constraint(equalTo: actionStackView.heightAnchor, multiplier: 0.4).isActive = true
        //            div.centerXAnchor.constraint(equalTo: actionStackView.arrangedSubviews[i].leftAnchor).isActive = true
        //            div.centerYAnchor.constraint(equalTo: actionStackView.centerYAnchor).isActive = true
        //        }
        
        
        
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    var originalImageCenter:CGPoint?
    
    @objc func pan(sender: UIPanGestureRecognizer) {
        if self.isZooming && sender.state == .began {
            self.originalImageCenter = sender.view?.center
        } else if self.isZooming && sender.state == .changed {
            let translation = sender.translation(in: self)
            if let view = sender.view {
                view.center = CGPoint(x:view.center.x + translation.x,
                                      y:view.center.y + translation.y)
            }
            sender.setTranslation(CGPoint.zero, in: self.photoImageScrollView.superview)
        }
    }
    
    @objc func pinch(sender:UIPinchGestureRecognizer) {
        
        if sender.state == .began {
            let currentScale = self.photoImageScrollView.frame.size.height / self.photoImageScrollView.bounds.size.height
            let newScale = currentScale*sender.scale
            self.bringSubviewToFront(self.photoImageScrollView)
            
            
            if newScale > 1 {
                self.isZooming = true
            }
            
        } else if sender.state == .changed {
            guard let view = sender.view else {return}
            let pinchCenter = CGPoint(x: sender.location(in: view).x - view.bounds.midX,
                                      y: sender.location(in: view).y - view.bounds.midY)
            let transform = view.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y)
                .scaledBy(x: sender.scale, y: sender.scale)
                .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
            
            let currentScale = self.photoImageScrollView.frame.size.height / self.photoImageScrollView.bounds.size.height
            var newScale = currentScale*sender.scale
            
            if newScale < 1 {
                newScale = 1
                let transform = CGAffineTransform(scaleX: newScale, y: newScale)
                self.photoImageScrollView.transform = transform
                sender.scale = 1
            }else {
                view.transform = transform
                sender.scale = 1
            }
            
        } else if sender.state == .ended || sender.state == .failed || sender.state == .cancelled {
            print("End Scaling")
            UIView.animate(withDuration: 0.3, animations: {
                self.photoImageScrollView.transform = CGAffineTransform.identity
                if let center = self.originalImageCenter {
                    self.photoImageScrollView.center = center
                }
            }, completion: { _ in
                self.isZooming = false
                self.bringSubviewToFront(self.captionView)
                self.bringSubviewToFront(self.photoCountLabel)
            })
        }
    }
    
    //    func pinch(sender:UIPinchGestureRecognizer) {
    //        if sender.state == .began {
    //            let currentScale = self.photoImageView.frame.size.width / self.photoImageView.bounds.size.width
    //            let newScale = currentScale*sender.scale
    //            if newScale > 1 {
    //                self.isZooming = true
    //            }
    //        } else if sender.state == .changed {
    //            guard let view = sender.view else {return}
    //            let pinchCenter = CGPoint(x: sender.location(in: view).x - view.bounds.midX,
    //                                      y: sender.location(in: view).y - view.bounds.midY)
    //            let transform = view.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y)
    //                .scaledBy(x: sender.scale, y: sender.scale)
    //                .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
    //            let currentScale = self.photoImageView.frame.size.width / self.photoImageView.bounds.size.width
    //            var newScale = currentScale*sender.scale
    //
    //            if newScale < 1 {
    //                newScale = 1
    //                let transform = CGAffineTransform(scaleX: newScale, y: newScale)
    //                self.photoImageView.transform = transform
    //                sender.scale = 1
    //            }else {
    //                view.transform = transform
    //                sender.scale = 1
    //            }
    //        } else if sender.state == .ended || sender.state == .failed || sender.state == .cancelled {
    //            guard let center = self.originalImageCenter else {return}
    //            UIView.animate(withDuration: 0.3, animations: {
    //                self.photoImageView.transform = CGAffineTransform.identity
    //                self.photoImageView.center = center
    //                //                self.superview?.bringSubview(toFront: self.photoImageView)
    //            }, completion: { _ in
    //                self.isZooming = false
    //            })
    //        }
    //    }
    
    
    
    
    
    //    func swipe(sender:UISwipeGestureRecognizer) {
    //
    //        guard let imageUrls = self.post?.imageUrls else {return}
    //
    //        switch sender.direction {
    //        case UISwipeGestureRecognizerDirection.left:
    //            if currentImage == (self.post?.imageCount)! - 1 {
    //                currentImage = 0
    //
    //            }else{
    //                currentImage += 1
    //            }
    //            photoImageView.loadImage(urlString: imageUrls[currentImage])
    //
    //        case UISwipeGestureRecognizerDirection.right:
    //            if currentImage == 0 {
    //                currentImage = (self.post?.imageCount)! - 1
    //            }else{
    //                currentImage -= 1
    //            }
    //            photoImageView.loadImage(urlString: imageUrls[currentImage])
    //        default:
    //            break
    //        }
    //
    //    }
    
    
    @objc func photoDoubleTapped(){
        print("Double Tap")
        self.handleVote()
        
        // Double Tap For Upvote - If Already Upvoted will change vote to 0. Upvote code handles it
        
        //        self.locationTap()
        
        
        //        self.handleLike()
        //        var origin: CGPoint = self.photoImageView.center;
        //        popView = UIView(frame: CGRect(x: origin.x, y: origin.y, width: 200, height: 200))
        //        popView = UIImageView(image: #imageLiteral(resourceName: "heart"))
        //        popView.contentMode = .scaleToFill
        //        popView.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
        //        popView.frame.origin.x = origin.x
        //        popView.frame.origin.y = origin.y * (1/3)
        //
        //        photoImageView.addSubview(popView)
        //
        //            UIView.animate(withDuration: 1.5,
        //                       delay: 0,
        //                       usingSpringWithDamping: 0.2,
        //                       initialSpringVelocity: 6.0,
        //                       options: .allowUserInteraction,
        //                       animations: { [weak self] in
        //                        self?.popView.transform = .identity
        //                }) { (done) in
        //                    self.popView.alpha = 0
        //                }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        if self.post?.creatorListId != nil {
//            return (self.post?.creatorListId?.count)!
//        } else {return 0}
        
        return self.postListNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ListDisplayCell

        let displayListName = self.postListNames[indexPath.row]
        let displayListId = self.postListIds[indexPath.row]
        
        if self.post?.creatorUID == Auth.auth().currentUser?.uid {
            // Current User is Creator
            cell.otherUser = false
        } else if let creatorListIds = self.post?.creatorListId {
            // Current User is not Creator
            if creatorListIds[displayListId] != nil {
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
        
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.didTapExtraTag(tagName: self.postListNames[indexPath.row], tagId: self.postListIds[indexPath.row], post: self.post!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        let subViews = self.photoImageScrollView.subviews
        
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
        
        // Clear Items
        self.voteCount.text = ""
        self.listCount.text = ""
        self.starRatingLabel.rating = 0
        self.starRating.rating = 0
//        self.extraTagsArray.removeAll()
        self.bookmarkIcon.isHidden = true
        self.usernameLabel.text = ""
        self.emojiArray.emojiLabels = []
        self.locationNameLabel.text = ""
        self.socialStatsViewHeight?.constant = 0
        
        
        listButton.layer.cornerRadius = listButton.bounds.size.width/2
        photoImageScrollView.contentSize.width = photoImageScrollView.frame.width
        currentImage = 1
        
        photoImageView.image = nil
        photoImageView.cancelImageRequestOperation()
        starRatingHide?.isActive = true
        starRatingDisplay?.isActive = false
        bookmarkIconHide?.isActive = true
        locationDistanceLabel.text = ""
        legitIconWidth?.constant = 0
        voteStatsTextView.text = ""
        captionTextView.textContainer.maximumNumberOfLines = 0
        captionViewHeightConstraint?.isActive = true
//        listCollectionViewHeightConstraint?.constant = locationViewHeight
//        captionViewHeightConstraint?.constant = captionViewHeight
        
        
        //
        //        // Reset Zoom
        //        photoImageView.transform = CGAffineTransform.identity
        //        photoImageView.center = center
        //        self.isZooming = false
        
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

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUITextDirection(_ input: Int) -> UITextDirection {
	return UITextDirection(rawValue: input)
}
