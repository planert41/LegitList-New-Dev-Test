//
//  HomePostCell.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/29/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import mailgun

import Cosmos
import DropDown
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

protocol FullPictureCellDelegate {
    func didTapBookmark(post:Post)
    func didTapUser(post:Post)
    func didTapLike(post:Post)
    func didTapComment(post:Post)
    func didTapUserUid(uid:String)
    func didTapLocation(post:Post)
    func didTapMessage(post:Post)
    func refreshPost(post:Post)
    func didTapPicture(post:Post)
    func userOptionPost(post:Post)

    
//    func displaySelectedEmoji(emoji: String, emojitag: String)
    func didTapExtraTag(tagName: String, tagId: String, post: Post)
    
    func displayPostSocialUsers(post:Post, following: Bool)
    func displayPostSocialLists(post:Post, following: Bool)
//    func didRefreshCell()
    //    func expandPost(post:Post, newHeight: CGFloat)
    
    
}

class FullPictureCell: UICollectionViewCell, UIGestureRecognizerDelegate, UIScrollViewDelegate, EmojiButtonArrayDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    func doubleTapEmoji(index: Int?, emoji: String) {
        
    }
    
    var delegate: FullPictureCellDelegate?
    
    var popView = UIView()
    var enableDelete: Bool = false
    var isZooming = false
    var currentImage = 1 {
        didSet {
            setupImageCountLabel()
            setupPageControl()
        }
    }
    var noImageScroll = false
    var imageCount = 0
    
    // Settings
    var postCaptionTextSize: CGFloat = 14.0
    
    
    var post: Post? {
        didSet {
            
            guard let imageUrls = post?.imageUrls else {
                print("Read Post, No Image URLs Error")
                return}
            
            setupImageCountLabel()
            
            setupPicturesScroll()
            if post?.images != nil {
                photoImageView.image = post?.images![0]
            } else {
                photoImageView.loadImage(urlString: imageUrls.first!)
            }
            setupPageControl()
            setupUser()
            setupEmojis()
            refreshListCollectionView()
            setupStarRating()
            setupAttributedLocationName()
            setupPostDetails()
            refreshSocialCount()
            expandTextView()
            updateLinkLabel()
            
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
        let usernameTapGesture = UITapGestureRecognizer(target: self, action: #selector(usernameTap))
        usernameLabel.addGestureRecognizer(usernameTapGesture)
        
        guard let profileImageUrl = post?.user.profileImageUrl else {return}
        userProfileImageView.loadImage(urlString: profileImageUrl)
    }
    
    func refreshListCollectionView(){
        self.postListIds = []
        self.postListNames = []
        self.creatorListIds = []
        
        // USER SELECTED LIST ID
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
        
        
        // CREATOR SELECTED LIST ID
        
        if self.post?.creatorListId != nil {
            for (key,value) in (self.post?.creatorListId)! {
                if value == legitListName{
                    self.postListIds.append(key)
                    self.postListNames.append(value)
                    self.creatorListIds.append(key)
                }
            }
            
            for (key,value) in (self.post?.creatorListId)! {
                if value == bookmarkListName{
                    self.postListIds.append(key)
                    self.postListNames.append(value)
                    self.creatorListIds.append(key)
                }
            }
            
            for (key,value) in (self.post?.creatorListId)! {
                if value != legitListName && value != bookmarkListName{
                    self.postListIds.append(key)
                    self.postListNames.append(value)
                    self.creatorListIds.append(key)
                }
            }
        }
        
//        USER SELECTED LIST ID
        
        self.selectedListIds = []
        self.selectedListNames = []
        
        if self.post?.selectedListId != nil && self.post?.creatorUID != Auth.auth().currentUser?.uid {
            for (key,value) in (self.post?.selectedListId)! {
                if value == legitListName{
                    self.selectedListIds.append(key)
                    self.selectedListNames.append(value)
                }
            }

            for (key,value) in (self.post?.selectedListId)! {
                if value == bookmarkListName{
                    self.selectedListIds.append(key)
                    self.selectedListNames.append(value)
                }
            }

            for (key,value) in (self.post?.selectedListId)! {
                if value != legitListName && value != bookmarkListName{
                    self.selectedListIds.append(key)
                    self.selectedListNames.append(value)
                }
            }
        }
        
        
        self.updateConstraintsIfNeeded()
        self.layoutIfNeeded()
        self.listCollectionView.collectionViewLayout.invalidateLayout()
        self.listCollectionView.sizeToFit()
        self.listCollectionView.reloadData()
        
//        self.selectedListCollectionView.sizeToFit()
//        self.selectedListCollectionView.reloadData()

        let selectedListCount = self.post?.selectedListId?.count ?? 0
        
        if selectedListCount == 1 {
            for (listId, listname) in (self.post?.selectedListId)! {
                self.savedListLabel.text = listname.capitalizingFirstLetter()
            }
        } else if selectedListCount > 1 {
            self.savedListLabel.text = "\(selectedListCount) Lists"
        } else {
            self.savedListLabel.text = ""
        }
        self.savedListLabel.sizeToFit()
        
        
        listCollectionViewHeight?.constant = (self.postListNames.count == 0) ? 0 : locationViewHeight
        listCollectionViewHeight?.isActive = true
        
    }
    
    func setupImageCountLabel(){
        imageCount = (self.post?.imageCount) ?? 1
        
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
    
    var displayNames: [String] = []
    var displayNamesUid: [String:String] = [:]
    


    
    func updateSocialLabel(listCount: Int?, userCount: Int?, usernames: [String]?) {
        let listCount = listCount ?? 0
        let userCount = userCount ?? 0
        let usernames = usernames ?? []
        var otherUserCount = userCount
        
        var userString = ""
        
        if listCount > 0 {
            self.socialStatsListHeight?.constant = 15
            if listCount == 1 {
                userString = "\(listCount) List by"
            } else if listCount > 1 {
                userString = "\(listCount) Lists by"
            }
        } else {
            self.socialStatsListHeight?.constant = 0
            return
        }
        
        if (usernames.count) > 0 {
            for (index, username) in usernames.enumerated() {
                if index == 0 {
                    userString.append(" \(username)")
                } else {
                    userString.append(", \(username)")
                }
            }
            
            otherUserCount = userCount - usernames.count
            if otherUserCount == 1 {
                userString.append(" & 1 User")
            } else if otherUserCount > 1 {
                userString.append(" & \(otherUserCount) Users")
            } else {
                // No other users
            }
        } else {
            // NO LISTS FROM FOLLOWING USERS
            if otherUserCount == 1 {
                userString.append(" 1 User")
            } else if otherUserCount > 1 {
                userString.append(" \(otherUserCount) Users")
            } else {
                // No other users
            }
        }

        self.creatorListLabel.text = userString
        self.creatorListLabel.sizeToFit()
        
    }
    
    
    func refreshActionButtons() {
        guard let post = self.post else {
            return
        }
        
    // Update Likes
//        var likeImage = (self.post?.hasLiked)! ? #imageLiteral(resourceName: "like_filled").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "like_unfilled").withRenderingMode(.alwaysTemplate)
//        var likeImage = (self.post?.hasLiked)! ? #imageLiteral(resourceName: "legit_check").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "like_unfilled").withRenderingMode(.alwaysTemplate)
        var likeImage = (self.post?.hasLiked)! ? #imageLiteral(resourceName: "like_filled").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "like_unfilled").withRenderingMode(.alwaysTemplate)

        likeButton.setImage(likeImage, for: .normal)
        
        var likeCount = post.likeCount ?? 0
        var likeText = "  " + ((likeCount == 0) ? "Legit" : "\(likeCount) Legit")
//        var likeText = "  " + "Legit"

        var likeFont = (post.hasLiked) ? UIFont.boldSystemFont(ofSize: 16) : UIFont.systemFont(ofSize: 16)
        var likeColor = post.hasLiked ? UIColor.ianLegitColor() : UIColor.ianBlackColor()

        let likeString = NSMutableAttributedString(string: likeText, attributes: [NSAttributedString.Key.font: likeFont, NSAttributedString.Key.foregroundColor: likeColor])

        likeButton.setAttributedTitle(likeString, for: .normal)
//        likeButton.setTitle(likeText, for: .normal)
        
    // Update Comments
        commentButton.setImage(#imageLiteral(resourceName: "comment_icon_ian").withRenderingMode(.alwaysTemplate), for: .normal)
        var commentCount = post.commentCount ?? 0
//        var commentText = "  " + ((commentCount == 0) ? "Comment" : "\(commentCount) Comments")
        var commentText = "  " + "Comment"

        var commentFont = UIFont.systemFont(ofSize: 16)

//        var commentFont = (likeCount == 0) ? UIFont.systemFont(ofSize: 16) : UIFont.boldSystemFont(ofSize: 16)

        let commentString = NSMutableAttributedString(string: commentText, attributes: [NSAttributedString.Key.font: commentFont, NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor()])
        
        commentButton.setAttributedTitle(commentString, for: .normal)
//        commentButton.setTitle(commentText, for: .normal)
        
    // Update Bookmark
//        let bookmarkCount = self.post?.selectedListId?.count ?? 0
        let bookmarkCount = self.post?.listCount ?? 0

        bookmarkButton.setImage(#imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate), for: .normal)
        bookmarkButton.tintColor = post.hasPinned ? UIColor.ianLegitColor() : UIColor.ianBlackColor()
        var bookmarkText = "  " + ((bookmarkCount == 0) ? "List" : "\(bookmarkCount) Lists")
        
        var bookmarkFont = (post.hasPinned) ? UIFont.boldSystemFont(ofSize: 16) : UIFont.systemFont(ofSize: 16)
        var bookmarkColor = post.hasPinned ? UIColor.ianLegitColor() : UIColor.ianBlackColor()

        let bookmarkString = NSMutableAttributedString(string: bookmarkText, attributes: [NSAttributedString.Key.font: bookmarkFont, NSAttributedString.Key.foregroundColor: bookmarkColor])
        
        bookmarkButton.setAttributedTitle(bookmarkString, for: .normal)
//        bookmarkButton.setTitle(bookmarkText, for: .normal)
        
        
//        let selectedListCount = post.selectedListId?.count ?? 0
//        bookmarkCountLabel.text = selectedListCount > 0 ? String(selectedListCount) : ""
        
    }
    
    func refreshSocialCount(){
        guard let post = self.post else {
            return
        }

        
        self.refreshActionButtons()
        
        let socialFontSize: CGFloat = 12

        // LIKE COUNT LABEL
//        var likeCount = post.likeCount ?? 0
        var curUserLiked = self.post?.hasLiked ?? false
        var followingCount = post.followingVote.count ?? 0

        likeCountLabel.isHidden = (post.likeCount == 0)
        
        let attDisplay = NSMutableAttributedString()

        var likeImage = #imageLiteral(resourceName: "like_filled").withRenderingMode(.alwaysOriginal)
        let likeImageText = NSTextAttachment()

        likeImageText.bounds = CGRect(x: 0, y: (likeCountLabel.font.capHeight - likeImage.size.height).rounded() / 2, width: likeImage.size.width, height: likeImage.size.height)
        likeImageText.image = likeImage
        
        let likeImageString = NSAttributedString(attachment: likeImageText)
//        attDisplay.append(likeImageString)

        let spacing = NSAttributedString(string: "  ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 13)])
//        attDisplay.append(spacing)
        
        var likeCountLabelFont = UIFont(font: .appleSDGothicNeoBold, size: 13)
        
        let likeTitle = NSAttributedString(string: "Legit by ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: likeCountLabelFont])
        attDisplay.append(likeTitle)

        
        
        if curUserLiked
        {
            let curUserText = "You \((followingCount > 0) ? "," : "") "
            let userTitle = NSAttributedString(string: curUserText, attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray, NSAttributedString.Key.font: likeCountLabelFont])
            attDisplay.append(userTitle)
        }
        
        if followingCount > 0
        {
            // FRIENDS LIKED IT
            var displayFriendId = post.followingVote[0]
            Database.fetchUserWithUID(uid: displayFriendId) { (user) in
                guard let user = user else {
                    self.likeCountLabel.text = (post.likeCount != 0) ? String(post.likeCount) + " Legits" : ""
                    return
                }
                
                let userTitle = NSAttributedString(string: "\(user.username) ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray, NSAttributedString.Key.font: likeCountLabelFont])
                attDisplay.append(userTitle)
                
                if (followingCount - 1) > 0 {
                    let otherCountTitle = NSAttributedString(string: "& \(followingCount - 1) Other Friends ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray, NSAttributedString.Key.font: likeCountLabelFont])
                    attDisplay.append(otherCountTitle)
                }
            }
        }
            
            
//        let otherTitle = NSAttributedString(string: "confirm legit", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Regular", size: 12)])
//        attDisplay.append(otherTitle)
        
        
        var hideSocialCount = (!curUserLiked && followingCount == 0 && post.commentCount == 0)
        socialViewHeight?.constant = hideSocialCount ? 0 : 20
        socialViewHeight?.isActive = true
//        self.in
    
//        print(attDisplay)
        likeCountLabel.attributedText = hideSocialCount ? NSMutableAttributedString() : attDisplay
        likeCountLabel.isHidden = (!curUserLiked && followingCount == 0)
        likeCountLabel.sizeToFit()

//        likeCountLabelHeight?.constant = hideSocialCount ? 0 : 30
//        print(hideSocialCount, likeCountLabelHeight)
        
        bookmarkButton.sizeToFit()

        self.updateConstraints()
        self.setNeedsLayout()
        self.layoutIfNeeded()

        
        
        
        
        // TOTAL LISTS
        
        
        
        
        /*
        if post.listCount > 0 {
            let attributedSocialListString = NSMutableAttributedString()
            let attributedString = NSMutableAttributedString(string: "\(post.listCount)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .appleSDGothicNeoBold, size: 15), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray]))
            attributedSocialListString.append(attributedString)
            
            let imageSize = CGSize(width: 15, height: 15)
            let bookmarkImage = NSTextAttachment()
            let bookmarkIcon = #imageLiteral(resourceName: "lists").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
            bookmarkImage.bounds = CGRect(x: 0, y: (socialListLabel.font.capHeight - bookmarkIcon.size.height).rounded() / 2, width: bookmarkIcon.size.width, height: bookmarkIcon.size.height)
            bookmarkImage.image = bookmarkIcon
            
            let bookmarkImageString = NSAttributedString(attachment: bookmarkImage)
//            attributedSocialListString.append(bookmarkImageString)
            
            let attributedSpace = NSMutableAttributedString(string: "  ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .appleSDGothicNeoBold, size: 15), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray]))
            attributedSocialListString.append(attributedSpace)
            creatorListLabel.attributedText = attributedSocialListString
        } else {
            creatorListLabel.text = ""
        }

 */
        
//        if post.hasPinned {
//            let selectedListCount = self.post?.selectedListId?.count ?? 0
//
//            self.bookmarkButton.setTitle("+\(selectedListCount) ", for: .normal)
//            self.bookmarkButton.sizeToFit()
//        } else {
//            self.bookmarkButton.setTitle("", for: .normal)
//        }
        
        

        

    
    }
    
    var showDistance: Bool = false

    
    fileprivate func setupPostDetails(){
        
        guard let post = self.post else {return}
        
        // Setup Post Date
        let formatter = DateFormatter()
        let calendar = NSCalendar.current
        
        let yearsAgo = calendar.dateComponents([.year], from: post.creationDate, to: Date())
//        if (yearsAgo.year)! > 0 {
//            formatter.dateFormat = "MMM d yy, h:mm a"
//        } else {
//            formatter.dateFormat = "MMM d, h:mm a"
//        }
        
        if (yearsAgo.year)! > 0 {
            formatter.dateFormat = "MMM d yy"
        } else {
            formatter.dateFormat = "MMM d"
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
        
//        let attributedText = NSAttributedString(string: postDateString!, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.italicSystemFont(ofSize: 12),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.lightGray]))
        
        let attributedText = NSMutableAttributedString(string: postDateString!, attributes: [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 12), NSAttributedString.Key.foregroundColor: UIColor.rgb(red: 102, green: 102, blue: 102)])

        
        self.postDateLabel.attributedText = attributedText
        self.postDateLabel.sizeToFit()
        
        if post.creatorUID == Auth.auth().currentUser?.uid {
            optionsButton.isHidden = false
        } else {
            optionsButton.isHidden = true
        }
        
        if showDistance || (post.distance ?? 0) < 100000.0 {
            locationDistanceLabel.text = SharedFunctions.formatDistance(inputDistance: post.distance)
            locationDistanceLabel.adjustsFontSizeToFitWidth = true
            locationDistanceLabel.isHidden = false
        } else {
            locationDistanceLabel.text = ""
            locationDistanceLabel.isHidden = true
        }
        
//        if showDistance {
//            locationDistanceLabel.text = SharedFunctions.formatDistance(inputDistance: post.distance)
//            locationDistanceLabel.adjustsFontSizeToFitWidth = true
//        } else {
//            locationDistanceLabel.text = ""
//        }
        locationDistanceLabel.sizeToFit()

        
    }
    
    
    fileprivate func getCityName() -> String {
        guard let post = self.post else {return ""}
        let locationNameTextArray = post.locationAdress.components(separatedBy: ",")
        let locationNameReverse = Array(locationNameTextArray.reversed())
        
        var cityName: String = ""
        var locationCountry: String = ""
        var locationState: String = ""
        var locationCity: String = ""
        var locationAdress: String = ""
        
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
            cityName = locationCity + "," + locationCountry
        } else {
            cityName = locationCity + locationCountry
        }
        
        return cityName

    }
    
    fileprivate func setupAttributedLocationName(){
        
        guard let post = self.post else {return}
        
//        var displayLocationName: String = ""
        
        var shortDisplayLocationName: String = ""

    
        if post.locationGooglePlaceID! == "" {
            // Not Google Tagged Location, Display by City, State
            
            shortDisplayLocationName.append(self.getCityName())
            
            // Last 3 items are City, State, Country
//            displayLocationName = locationNameTextArray.suffix(3).joined(separator: ",")
            
        } else {
            // Google Tagged Location. Display Google Tag Name
//            displayLocationName = post.locationName
            shortDisplayLocationName.append(post.locationName)
        }
        
        if post.locationGPS == nil {
            self.locationNameLabel.text = ""
        }

        ratingEmojiLabel.isHidden = true
        if let ratingEmoji = self.post?.ratingEmoji {
            if extraRatingEmojis.contains(ratingEmoji) {
//                shortDisplayLocationName.append(" \(ratingEmoji)")
                ratingEmojiLabel.text = ratingEmoji
                ratingEmojiLabel.isHidden = false
            }
        }
        
        hideRatingEmojiLabel?.constant = ratingEmojiLabel.isHidden ? 0 : 30

        
//        let locationNameTextColor = (self.post?.ratingEmoji == nil) ? UIColor.ianBlackColor() : UIColor.ianLegitColor()
        let locationNameTextColor =  UIColor.ianBlackColor()

//        let attributedTextCaption = NSMutableAttributedString(string: shortDisplayLocationName, attributes: [NSForegroundColorAttributeName: UIColor.legitColor(), NSFontAttributeName: UIFont(font: .markerFeltThin, size: 18)])
//        let attributedTextCaption = NSMutableAttributedString(string: shortDisplayLocationName, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.ianBlackColor(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .helveticaNeueBold, size: 18)]))
        let attributedTextCaption = NSMutableAttributedString(string: shortDisplayLocationName, attributes: [NSAttributedString.Key.foregroundColor: locationNameTextColor, NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 18)])

//avenirNextDemiBold

//        avenirNextBold, helveticaNeueBold, avenirNextCondensedBold, markerFeltThin, arialRoundedMTBold
        
        let paragraphStyle = NSMutableParagraphStyle()
        
        // *** set LineSpacing property in points ***
        paragraphStyle.lineSpacing = 0 // Whatever line spacing you want in points
        
        // *** Apply attribute to string ***
        attributedTextCaption.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedTextCaption.length))
        
        // *** Set Attributed String to your label ***
        self.locationNameLabel.attributedText = attributedTextCaption
        
        if let cityName =  post.locationSummaryID {
            // Not Google Tagged Location, Display by City, State
            self.locationCityLabel.text = cityName
        } else {
            self.locationCityLabel.text = ""
        }
        
        self.locationNameLabel.sizeToFit()
        self.locationCityLabel.sizeToFit()
        
    }
    
    //  PHOTOS
    
    let ratingEmojiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 25)
        label.textColor = UIColor.black
        label.backgroundColor = UIColor.white
        label.textAlignment = NSTextAlignment.left
//        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    var hideRatingEmojiLabel: NSLayoutConstraint?

    
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
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.darkGray
        label.backgroundColor = UIColor.white
        label.layer.cornerRadius = 5
        label.layer.borderWidth = 0
        label.layer.masksToBounds = true
        label.alpha = 1
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
        iv.settings.starSize = 25
        iv.settings.updateOnTouch = false
        iv.settings.filledImage = #imageLiteral(resourceName: "new_star").withRenderingMode(.alwaysTemplate)
        iv.settings.emptyImage = #imageLiteral(resourceName: "new_star_gray").withRenderingMode(.alwaysTemplate)
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
    

    func openBookmark(){
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
    
    let locationDistanceLabel: LightPaddedUILabel = {
        let label = LightPaddedUILabel()
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textColor = UIColor.mainBlue()
        label.textAlignment = NSTextAlignment.center
//        label.backgroundColor = UIColor.init(red: 255, green: 255, blue: 255, alpha: 0.5)
        label.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        return label
    }()
    
    let locationRatingEmojiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 25)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.left
//        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    var locationRatingEmojiWidth: NSLayoutConstraint?

    
    let locationNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.left
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    let locationCityLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.italicSystemFont(ofSize: 12)
        label.textColor = UIColor.rgb(red: 102, green: 102, blue: 102)
        label.textAlignment = NSTextAlignment.left
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
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
        label.font = UIFont(font: .appleSDGothicNeoBold, size: 15)
        label.textColor = UIColor.white
        label.textAlignment = NSTextAlignment.right
        return label
    }()
    
    // POST LINK
    
    let linkLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Poppins-Regular", size: 12)
        label.textColor = UIColor.mainBlue()
        label.textAlignment = NSTextAlignment.left
        label.lineBreakMode = .byWordWrapping
        label.lineBreakMode = .byClipping
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.baselineAdjustment = .alignCenters
        return label
    }()
    
    
    
    @objc func activateBrowser(){
        guard let url = URL(string: self.linkLabel.text!) else {return}
        print("activateBrowser | \(url)")
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    
    
    //  EMOJIS
    
    var emojiArray = EmojiButtonArray(emojis: [], frame: CGRect(x: 0, y: 0, width: 0, height: 20))
    var hideEmoji: NSLayoutConstraint?

    
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
    
    @objc func didTapRatingEmoji() {
        guard let emoji = self.post?.ratingEmoji else {return}
        var refString = "\(emoji)"
        
        if let refText = EmojiDictionary[emoji]?.capitalizingFirstLetter() {
            refString += "  \(String(refText))"
        }
        
        var captionDelay = 3
        emojiDetailLabel.text = refString
        emojiDetailLabel.alpha = 1
        emojiDetailLabel.sizeToFit()
        
        UIView.animate(withDuration: 0.5, delay: TimeInterval(captionDelay), options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.hideEmojiDetailLabel()
        }, completion: { (finished: Bool) in
        })
    }
    
    
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
        self.bringSubviewToFront(emojiDetailLabel)
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
            hideEmoji?.isActive = false
            self.updateConstraints()
        } else {
            emojiArray.emojiLabels = []
            hideEmoji?.isActive = true
            self.updateConstraints()
        }
        //        print("UPDATED EMOJI ARRAY: \(emojiArray.emojiLabels)")
        emojiArray.setEmojiButtons()
        emojiArray.sizeToFit()
        //        print("REFRESH EMOJI ARRAYS - setEmojiButtons")
    }
    
    // CAPTION
    
    let otherCommentsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Poppins-Regular", size: 13)
        label.textColor = UIColor.lightGray
        label.textAlignment = NSTextAlignment.right
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    let captionTextView: UITextView = {
        let tv = UITextView()
        tv.isScrollEnabled = false
        tv.textContainer.maximumNumberOfLines = 3
        tv.textContainerInset = UIEdgeInsets.zero
        tv.textContainer.lineBreakMode = .byTruncatingTail
        tv.translatesAutoresizingMaskIntoConstraints = true
        tv.isEditable = false
        return tv
    }()
    
    func expandTextView(){
        guard let post = self.post else {return}
        captionViewHeightConstraint?.isActive = false
        captionViewHeightConstraint?.constant = (post.caption == "") ? 0 : 30
        captionTextView.textContainer.maximumNumberOfLines = 4
        
        // Set Up Caption
        
//        let attributedTextCaption = NSMutableAttributedString(string: post.user.username, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
        
        let attributedTextCaption = NSMutableAttributedString(string: post.user.username, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: postCaptionTextSize), NSAttributedString.Key.foregroundColor: UIColor.darkGray])

        
//        let attributedTextCaption = NSMutableAttributedString(string: post.user.username, attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12)])
        
        

        attributedTextCaption.append(NSAttributedString(string: "  \(post.caption)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: postCaptionTextSize)]))
        
        //        attributedTextCaption.append(NSAttributedString(string: "\n\n", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 4)]))
        
        self.captionTextView.attributedText = attributedTextCaption
        self.captionTextView.sizeToFit()
        
        if post.commentCount == 0 {
            self.otherCommentsLabel.text = ""
        } else {
            self.otherCommentsLabel.text = " \(post.commentCount) comments"
        }
        
        
        //        self.delegate?.expandPost(post: post, newHeight: self.captionTextView.frame.height - captionViewHeight)
        //        print(self.captionTextView.frame.height, self.captionTextView.intrinsicContentSize)
        
    }
    
    func HandleTap(sender: UITapGestureRecognizer) {
        
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
    
    var selectedListIds: [String] = []
    var selectedListNames: [String] = []
    
    lazy var listCollectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = .white
        return cv
    }()
    
    var listCollectionViewHeight: NSLayoutConstraint?

    
//    lazy var selectedListCollectionView : UICollectionView = {
//        let layout = UICollectionViewFlowLayout()
//        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
//        cv.translatesAutoresizingMaskIntoConstraints = false
//        cv.delegate = self
//        cv.dataSource = self
//        cv.backgroundColor = .white
//        return cv
//    }()
    
    let cellId = "CellId"
    
    func setupStarRating(){
        


            
//            if starRating.rating >= 4 {
//                starRating.settings.filledImage = (starRating.rating >= 4) ? #imageLiteral(resourceName: "new_star").withRenderingMode(.alwaysOriginal) :  #imageLiteral(resourceName: "new_star_black").withRenderingMode(.alwaysOriginal)
//                starRating.settings.filledImage = #imageLiteral(resourceName: "rating_filled_high_test").withRenderingMode(.alwaysOriginal)
//
//            } else {
//                starRating.settings.filledImage = #imageLiteral(resourceName: "new_star_black").withRenderingMode(.alwaysOriginal)
//                starRating.settings.filledImage = #imageLiteral(resourceName: "rating_filled_mid_test").withRenderingMode(.alwaysOriginal)
//            }
            
//            starRating.tintColor = starRating.rating >= 4 ? UIColor.ianLegitColor() : UIColor.ianBlackColor()

        if (self.post?.rating)! != 0 {
            
            self.starRating.rating = (self.post?.rating)!
//            starRating.settings.filledImage = (starRating.rating >= 4) ? #imageLiteral(resourceName: "new_star").withRenderingMode(.alwaysOriginal) :  #imageLiteral(resourceName: "new_star_black").withRenderingMode(.alwaysOriginal)
            self.starRatingHide?.isActive = false
            self.starRating.isHidden = (self.starRatingHide?.isActive)!
            self.starRating.sizeToFit()

        } else {
            self.starRatingHide?.isActive = true
            self.starRating.isHidden = (self.starRatingHide?.isActive)!
            self.starRating.sizeToFit()
        }
        
        self.updateConstraints()

        
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
    
    
    
//    var locationViewHeight: CGFloat = 35
    var locationViewHeight: CGFloat = 0
    var captionViewHeight: CGFloat = 45
    
    var starRatingSize: CGFloat = 50 - 10 - 10 - 5
    
    var headerHeight: CGFloat = 60
    var profileImageSize: CGFloat = 30

    var pageControl : UIPageControl = UIPageControl()
    let postDetailView = UIView()

    
    let addSocialView = UIView()
    var socialViewHeight: NSLayoutConstraint?
    
    // MARK: - INITT
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // INITT
        self.backgroundColor = UIColor.white
        self.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        
        
// HEADER VIEW
        
        let headerView = UIView()
        addSubview(headerView)
        headerView.backgroundColor = UIColor.white
        headerView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        headerView.heightAnchor.constraint(greaterThanOrEqualToConstant: headerHeight).isActive = true
        headerView.heightAnchor.constraint(equalToConstant: headerHeight).isActive = true

        
    // USER PROFILE IMAGE
        addSubview(userProfileImageView)
        // Username Profile Picture
        userProfileImageView.anchor(top: nil, left: nil, bottom: nil, right: headerView.rightAnchor, paddingTop: 15, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: profileImageSize, height: profileImageSize)
        userProfileImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true

        userProfileImageView.layer.cornerRadius = profileImageSize/2
        userProfileImageView.layer.borderWidth = 1
        userProfileImageView.layer.borderColor = UIColor.darkGray.cgColor
        userProfileImageView.isUserInteractionEnabled = true
        userProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(usernameTap)))
        
//        locationNameLabel.rightAnchor.constraint(equalTo: userProfileImageView.leftAnchor, constant: 10).isActive = true
        

        

// LOCATION VIEW
        let locationNameView = UIView()
        addSubview(locationNameView)
        locationNameView.anchor(top: headerView.topAnchor, left: headerView.leftAnchor, bottom: headerView.bottomAnchor, right: userProfileImageView.leftAnchor, paddingTop: 10, paddingLeft: 15, paddingBottom: 10, paddingRight: 10, width: 0, height: 0)
        
        
                
    // LOCATION NAME
        addSubview(locationNameLabel)
        locationNameLabel.anchor(top: locationNameView.topAnchor, left: locationNameView.leftAnchor, bottom: nil, right: locationNameView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)

        locationNameLabel.sizeToFit()
        locationNameLabel.isUserInteractionEnabled = true
        locationNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(locationTap)))
        
        

        
    // LOCATION CITY
        addSubview(locationCityLabel)
        locationCityLabel.anchor(top: locationNameLabel.bottomAnchor, left: locationNameView.leftAnchor, bottom: nil, right: nil, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        locationCityLabel.bottomAnchor.constraint(lessThanOrEqualTo: locationNameView.bottomAnchor).isActive = true
//        locationCityLabel.rightAnchor.constraint(lessThanOrEqualTo: postDateLabel.leftAnchor, constant: 20)
        
        

        
    // PHOTO
        addSubview(photoImageScrollView)
        photoImageScrollView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.width)
        photoImageScrollView.anchor(top: headerView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        photoImageScrollView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
        photoImageScrollView.isPagingEnabled = true
        photoImageScrollView.delegate = self
        
        setupPhotoImageScrollView()

        
    // Add Location Distance
        addSubview(locationDistanceLabel)
        locationDistanceLabel.anchor(top: nil, left: leftAnchor, bottom: photoImageScrollView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        //        locationDistanceLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        locationDistanceLabel.sizeToFit()
        locationDistanceLabel.isUserInteractionEnabled = true
        locationDistanceLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(activateMap)))
        locationDistanceLabel.isHidden = true
        
    // PAGE CONTROL
        setupPageControl()
        addSubview(pageControl)
        pageControl.anchor(top: nil, left: nil, bottom: photoImageScrollView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 15, paddingRight: 0, width: 40, height: 5)
        pageControl.centerXAnchor.constraint(equalTo: photoImageScrollView.centerXAnchor).isActive = true


        
        
// LIST COLLECTIONVIEW
        
        let socialDetailsView = UIView()
        addSubview(socialDetailsView)
        socialDetailsView.anchor(top: photoImageScrollView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        listCollectionViewHeight = socialDetailsView.heightAnchor.constraint(equalToConstant: locationViewHeight)
        listCollectionViewHeight?.isActive = true
        
        setupListCollectionView()
        
        socialDetailsView.addSubview(listCollectionView)
        listCollectionView.anchor(top: socialDetailsView.topAnchor, left: socialDetailsView.leftAnchor, bottom: socialDetailsView.bottomAnchor, right: socialDetailsView.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        
        
        let postDetailView = UIView()
        addSubview(postDetailView)
        postDetailView.anchor(top: socialDetailsView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 30)
        
        
    // HEADER EMOJIS
        emojiArray.alignment = .left
        emojiArray.delegate = self
        addSubview(emojiArray)
        emojiArray.anchor(top: nil, left: postDetailView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 25)
        emojiArray.centerYAnchor.constraint(equalTo: postDetailView.centerYAnchor).isActive = true
        hideEmoji = emojiArray.widthAnchor.constraint(equalToConstant: 0)
        hideEmoji?.isActive = true
    



        addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top: nil, left: nil, bottom: pageControl.topAnchor, right: nil, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)
        emojiDetailLabel.centerXAnchor.constraint(equalTo: photoImageScrollView.centerXAnchor).isActive = true
        emojiDetailLabel.alpha = 0
        
        
    // STAR RATING
        addSubview(starRating)
        starRating.anchor(top: nil, left: nil, bottom: nil, right: postDetailView.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 2, width: 0, height: 0)
        starRating.centerYAnchor.constraint(equalTo: postDetailView.centerYAnchor).isActive = true

        starRating.sizeToFit()
        starRatingHide = starRating.widthAnchor.constraint(equalToConstant: 0)
//        starRatingDisplay = starRating.heightAnchor.constraint(equalToConstant: starRatingSize)
//        starRatingHide?.isActive = true


//        listCollectionView.centerYAnchor.constraint(equalTo: socialDetailsView.centerYAnchor).isActive = true

        
         addSubview(ratingEmojiLabel)
         ratingEmojiLabel.anchor(top: nil, left: nil, bottom: nil, right: starRating.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 0, height: 30)
         ratingEmojiLabel.centerYAnchor.constraint(equalTo: starRating.centerYAnchor).isActive = true
         ratingEmojiLabel.layer.cornerRadius = 30/2
         ratingEmojiLabel.layer.masksToBounds = true
         ratingEmojiLabel.sizeToFit()
         ratingEmojiLabel.isUserInteractionEnabled = true
         ratingEmojiLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapRatingEmoji)))

         hideRatingEmojiLabel = ratingEmojiLabel.widthAnchor.constraint(equalToConstant: 30)
         hideRatingEmojiLabel?.isActive = true
             
        

        addSubview(captionTextView)
        captionTextView.anchor(top: postDetailView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 10, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        captionTextView.heightAnchor.constraint(lessThanOrEqualToConstant: 80).isActive = true
        captionTextView.isUserInteractionEnabled = true
        captionTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleComment)))
//        captionTextView.backgroundColor = UIColor.mainBlue()
        
        captionViewHeightConstraint = captionTextView.heightAnchor.constraint(equalToConstant: 0)
        captionViewHeightConstraint?.isActive = true
        captionTextView.sizeToFit()
        expandTextView()

    // DATE
        addSubview(postDateLabel)
        postDateLabel.anchor(top: captionTextView.bottomAnchor, left: captionTextView.leftAnchor, bottom: nil, right: nil, paddingTop: 3, paddingLeft: 5, paddingBottom: 0, paddingRight: 10, width: 0, height: 15)
//            postDateLabel.bottomAnchor.constraint(lessThanOrEqualTo: locationNameView.bottomAnchor).isActive = true
//        postDateLabel.centerYAnchor.constraint(equalTo: addSocialView.centerYAnchor).isActive = true
        postDateLabel.sizeToFit()
        
        addSubview(linkLabel)
        linkLabel.anchor(top: postDateLabel.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 4, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        linkLabel.isUserInteractionEnabled = true
        linkLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(activateBrowser)))
        updateLinkLabel()
        
        // SOCIAL COUNTS

        addSubview(addSocialView)
        addSocialView.anchor(top: linkLabel.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        socialViewHeight = addSocialView.heightAnchor.constraint(equalToConstant: 0)
//        socialViewHeight?.isActive = true
//        addSocialView.backgroundColor = UIColor.mainBlue()
        
        addSubview(likeCountLabel)
        likeCountLabel.anchor(top: addSocialView.topAnchor, left: addSocialView.leftAnchor, bottom: addSocialView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        likeCountLabel.centerYAnchor.constraint(equalTo: addSocialView.centerYAnchor).isActive = true
//        likeCountLabel.bottomAnchor.constraint(lessThanOrEqualTo: addSocialView.bottomAnchor, constant: 3).isActive = true
//        likeCountLabelHeight = addSocialView.heightAnchor.constraint(equalToConstant: 0)
//        likeCountLabelHeight?.isActive = true
        likeCountLabel.isUserInteractionEnabled = true
        likeCountLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayFollowingVotes)))
        
        addSubview(otherCommentsLabel)
        otherCommentsLabel.anchor(top: addSocialView.topAnchor, left: nil, bottom: addSocialView.bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        otherCommentsLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleComment)))
        


                        
        let actionBarDiv = UIView()
        addSubview(actionBarDiv)
        actionBarDiv.anchor(top: addSocialView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
        actionBarDiv.backgroundColor = UIColor.ianLightGrayColor()

                
        
        
        
        
    // ACTION BAR
        
        addSubview(actionBar)
        actionBar.anchor(top: actionBarDiv.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        
        let actionStackView = UIStackView(arrangedSubviews: [likeContainer, commentContainer, bookmarkContainer])
        actionStackView.distribution = .fillEqually

        addSubview(actionStackView)
        actionStackView.anchor(top: actionBar.topAnchor, left: actionBar.leftAnchor, bottom: actionBar.bottomAnchor, right: actionBar.rightAnchor, paddingTop: 10, paddingLeft: 5, paddingBottom: 10, paddingRight: 5, width: 0, height: 30)
        actionStackView.centerYAnchor.constraint(equalTo: actionBar.centerYAnchor).isActive = true
        actionStackView.sizeToFit()
        
        // LIKE BUTTON - LEFT
        likeContainer.addSubview(likeButton)
        likeButton.anchor(top: likeContainer.topAnchor, left: likeContainer.leftAnchor, bottom: likeContainer.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        likeButton.titleLabel?.adjustsFontSizeToFitWidth = true

        // COMMENT BUTTON - MIDDLE
        commentContainer.addSubview(commentButton)
        commentButton.anchor(top: commentContainer.topAnchor, left: nil, bottom: commentContainer.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        commentButton.centerXAnchor.constraint(equalTo: commentContainer.centerXAnchor).isActive = true
        commentButton.rightAnchor.constraint(lessThanOrEqualTo: commentContainer.rightAnchor).isActive = true
        commentButton.leftAnchor.constraint(lessThanOrEqualTo: commentContainer.leftAnchor).isActive = true
        commentButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        
        // BOOKMARK BUTTON - RIGHT
        bookmarkContainer.addSubview(bookmarkButton)
        bookmarkButton.anchor(top: commentContainer.topAnchor, left: nil, bottom: bookmarkContainer.bottomAnchor, right: bookmarkContainer.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        bookmarkButton.titleLabel?.adjustsFontSizeToFitWidth = true


        
        

        
    }
    
    func updateLinkLabel() {
        self.linkLabel.text = self.post?.urlLink
        self.linkLabel.sizeToFit()
        self.linkLabel.isHidden = self.post?.urlLink?.isEmptyOrWhitespace() ?? true
    }
    
    
    func setupPageControl(){
        guard let imageCount = self.post?.imageCount else {return}
        self.pageControl.numberOfPages = imageCount
        self.pageControl.currentPage = self.currentImage - 1
        self.pageControl.tintColor = UIColor.red
        self.pageControl.pageIndicatorTintColor = UIColor.white
        self.pageControl.currentPageIndicatorTintColor = UIColor.ianLegitColor()
        self.pageControl.isHidden = self.pageControl.numberOfPages == 1
    }
    
    @objc func handlePictureTap() {
        guard let post = post else {return}
        delegate?.didTapPicture(post: post)
    }

    func setupPhotoImageScrollView(){
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(photoDoubleTapped))
        doubleTap.numberOfTapsRequired = 2
        photoImageScrollView.addGestureRecognizer(doubleTap)
        photoImageScrollView.isUserInteractionEnabled = true
        
        //        let captionTapGesture = UITapGestureRecognizer(target: self, action: #selector(displayCaptionBubble))
        let photoTapGesture = UITapGestureRecognizer(target: self, action: #selector(handlePictureTap))
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
        
    

    }
    
    func testprint(){
        print("test")
    }
    
    @objc func activateMap() {
        SharedFunctions.openGoogleMaps(lat: self.post?.locationGPS?.coordinate.latitude, long: self.post?.locationGPS?.coordinate.longitude)
    }
    
    

    
    func setupListCollectionView(){
        
        listCollectionView.register(LegitFullPostListCell.self, forCellWithReuseIdentifier: cellId)
        let layout = ListDisplayFlowLayout()
        layout.estimatedItemSize = CGSize(width: 60, height: 25)
        listCollectionView.collectionViewLayout = layout
        listCollectionView.backgroundColor = UIColor.clear
        listCollectionView.isScrollEnabled = true
        listCollectionView.showsHorizontalScrollIndicator = false
        //        listCollectionView.isPagingEnabled = false
        //        listCollectionView.semanticContentAttribute = UISemanticContentAttribute.forceRightToLeft
        
//        selectedListCollectionView.register(LegitFullPostListCell.self, forCellWithReuseIdentifier: cellId)
//        let layout1 = ListDisplayFlowLayout()
//        selectedListCollectionView.collectionViewLayout = layout1
//        selectedListCollectionView.backgroundColor = UIColor.clear
//        selectedListCollectionView.isScrollEnabled = true
//        selectedListCollectionView.showsHorizontalScrollIndicator = false
//
//        selectedListCollectionView.semanticContentAttribute = UISemanticContentAttribute.forceRightToLeft

        
    }
    
    func setupEmojiDetails(){

        
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
    
   
    func setupPicturesScroll() {
        
        var postCount = post?.imageCount ?? 0
        //        guard let _ = post?.imageUrls else {return}
        
        if noImageScroll {
            photoImageScrollView.contentSize.width = 0
        } else {
            photoImageScrollView.contentSize.width = photoImageScrollView.frame.width * CGFloat((postCount))
            
            for i in 1 ..< (postCount) {
                
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
        }

    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.currentImage = scrollView.currentPage
    }
    

    
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
    
    func HandleVoteStatsTap(sender: UITapGestureRecognizer) {
        
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
    
    
//    var followListStatsLabel: UILabel = {
//        let label = UILabel()
//        label.text = ""
//        label.font = UIFont.boldSystemFont(ofSize:14)
//        label.textColor = UIColor.black
//        label.textAlignment = NSTextAlignment.left
//        label.isUserInteractionEnabled = true
//        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayFollowLists)))
//        return label
//    }()
//
//    var followVoteStatsLabel: UILabel = {
//        let label = UILabel()
//        label.text = ""
//        label.font = UIFont.boldSystemFont(ofSize:14)
//        label.textColor = UIColor.black
//        label.textAlignment = NSTextAlignment.left
//        label.isUserInteractionEnabled = true
//        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayFollowingVotes)))
//        return label
//    }()
    
    @objc func displayFollowLists(){
        self.delegate?.displayPostSocialLists(post: self.post!, following: true)
    }
    
    @objc func displayFollowingVotes(){
        self.delegate?.displayPostSocialUsers(post: self.post!, following: true)
    }
    
    func displayAllLists(){
        self.delegate?.displayPostSocialLists(post: self.post!, following: false)
    }
    
    func displayAllVotes(){
        self.delegate?.displayPostSocialUsers(post: self.post!, following: false)
    }
    
    
    // Action Buttons
    
    var actionBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    
    
    // Bookmark
    var bookmarkContainer = UIView()
    
    lazy var bookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "listsHash").withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.addTarget(self, action: #selector(handleBookmark), for: .touchUpInside)
        button.setTitleColor(UIColor.ianBlackColor(), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.tintColor = UIColor.ianBlackColor()
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)

        return button
    }()
    
    
    let bookmarkCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(font: .appleSDGothicNeoBold, size: 15)
        label.textColor = UIColor.darkLegitColor()
        label.isUserInteractionEnabled = true
        return label
    }()
    
    // Like
    
    var likeContainer = UIView()
    
    lazy var likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "like_unfilled").withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.addTarget(self, action: #selector(handleLike), for: .touchUpInside)
        button.setTitleColor(UIColor.ianBlackColor(), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.tintColor = UIColor.ianBlackColor()
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)

        return button
    }()
    
    let likeCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(font: .appleSDGothicNeoBold, size: 13)
        label.textColor = UIColor.ianLegitColor()
        label.lineBreakMode = .byCharWrapping
        return label
    }()
    
    var likeCountLabelHeight: NSLayoutConstraint?
    
    
    @objc func handleBookmark() {
        guard let post = post else {return}
        delegate?.didTapBookmark(post: post)
        
    }
    
    // Comments
    
    var commentContainer = UIView()
    
    lazy var commentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "comment_icon_ian").withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.addTarget(self, action: #selector(handleComment), for: .touchUpInside)
        button.setTitleColor(UIColor.ianBlackColor(), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.tintColor = UIColor.ianBlackColor()
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)

        return button
    }()
    
    @objc func handleComment() {
        guard let post = post else {return}
        delegate?.didTapComment(post: post)
    }
    
    // Send Message
    
    // Like
    lazy var sendMessageButton: UIButton = {
        let button = UIButton(type: .system)
        //        button.setImage(#imageLiteral(resourceName: "bookmark_white").withRenderingMode(.alwaysOriginal), for: .normal)
        button.setImage(#imageLiteral(resourceName: "send_plane").resizeImageWith(newSize: CGSize(width: 20, height: 20)).withRenderingMode(.alwaysOriginal), for: .normal)
        
        button.addTarget(self, action: #selector(handleMessage), for: .touchUpInside)
        button.layer.cornerRadius = button.bounds.size.width/2
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 0
        button.layer.masksToBounds = true
        button.clipsToBounds = true
        return button
    }()
    
    let messageCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(font: .appleSDGothicNeoBold, size: 13)
        label.textColor = UIColor.darkGray
        return label
    }()
    
    
    @objc func handleMessage(){
        guard let post = post else {return}
        delegate?.didTapMessage(post: post)
        
    }
    
    
    

    let actionBarRowHeight: CGFloat = 20
    
    
    func setupActionButtons(mainContainer: UIView, button: UIButton) {
        mainContainer.addSubview(button)
        button.anchor(top: mainContainer.topAnchor, left: nil, bottom: mainContainer.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        button.centerXAnchor.constraint(equalTo: mainContainer.centerXAnchor).isActive = true
        button.rightAnchor.constraint(lessThanOrEqualTo: mainContainer.rightAnchor).isActive = true
        button.leftAnchor.constraint(lessThanOrEqualTo: mainContainer.leftAnchor).isActive = true
    }
    
    
    func setupActionLabels(mainContainer: UIView, icon: UIButton, label: UILabel){
        
        let containerview = UIView()
        containerview.addSubview(icon)
        containerview.addSubview(label)
        containerview.backgroundColor = UIColor.clear
        
        //Icon Height Anchor determines row height
        icon.anchor(top: containerview.topAnchor, left: containerview.leftAnchor, bottom: containerview.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: actionBarRowHeight, height: actionBarRowHeight)
        
        label.anchor(top: containerview.topAnchor, left: icon.rightAnchor, bottom: containerview.bottomAnchor, right: containerview.rightAnchor, paddingTop: 0, paddingLeft: 4, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        mainContainer.addSubview(containerview)
        containerview.centerYAnchor.constraint(equalTo: mainContainer.centerYAnchor).isActive = true
        containerview.centerXAnchor.constraint(equalTo: mainContainer.centerXAnchor).isActive = true
        
        containerview.topAnchor.constraint(lessThanOrEqualTo: mainContainer.topAnchor).isActive = true
        containerview.bottomAnchor.constraint(lessThanOrEqualTo: mainContainer.bottomAnchor).isActive = true
        containerview.leftAnchor.constraint(lessThanOrEqualTo: mainContainer.leftAnchor).isActive = true
        containerview.rightAnchor.constraint(lessThanOrEqualTo: mainContainer.rightAnchor).isActive = true

    }
    
    
    @objc func handleLike() {
        //      delegate?.didLike(for: self)
        
        guard let postId = self.post?.id else {return}
        guard let creatorId = self.post?.creatorUID else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        Database.handleLike(post: self.post) { post in
            self.post = post
            self.refreshSocialCount()
            self.delegate?.refreshPost(post: self.post!)
            
            self.likeButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)

            self.layoutIfNeeded()
            self.delegate?.didTapLike(post:(self.post!))

            UIView.animate(withDuration: 1.0,
                           delay: 0,
                           usingSpringWithDamping: 0.2,
                           initialSpringVelocity: 6.0,
                           options: .allowUserInteraction,
                           animations: { [weak self] in
                            self?.likeButton.transform = .identity
                            self?.likeButton.layoutIfNeeded()
                },
                           completion: nil)
            
            
            // Center Pop Up
            if (self.post?.hasLiked)! {
                var origin: CGPoint = self.photoImageScrollView.center;
                let newImageSize = CGSize(width: 100, height: 100)
                self.popView = UIView(frame: CGRect(x: origin.x, y: origin.y, width: 100, height: 100))
                self.popView = UIImageView(image: #imageLiteral(resourceName: "drool").resizeImageWith(newSize: newImageSize).withRenderingMode(.alwaysOriginal))
                self.popView.contentMode = .scaleToFill
                self.popView.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
                self.popView.frame.origin.x = origin.x
                self.popView.frame.origin.y = origin.y * 0.5
                
                self.photoImageView.addSubview(self.popView)
                
                UIView.animate(withDuration: 2,
                               delay: 0,
                               usingSpringWithDamping: 0.2,
                               initialSpringVelocity: 6.0,
                               options: .allowUserInteraction,
                               animations: { [weak self] in
                                self?.popView.transform = .identity
                }) { (done) in
                    self.popView.alpha = 0
                }
            }
        }

    }
    
    let temp_red = UIColor.init(hexColor: "e60023")
    

// CREATOR LIST LABEL
    var creatorListLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(font: .appleSDGothicNeoBold, size: 12)
        label.textColor = UIColor.darkGray
//        label.isUserInteractionEnabled = true
//        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayAllLists)))
        return label
    }()
    var socialStatsListHeight: NSLayoutConstraint? = nil
    
// TOTAL LIST LABEL
    var socialListLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(font: .appleSDGothicNeoBold, size: 12)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.right
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayFollowLists)))
        return label
    }()
    
    
    
    // Following Creds
    var savedListLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(font: .appleSDGothicNeoBold, size: 12)
        label.textColor = UIColor.pinterestRedColor()
        label.isUserInteractionEnabled = true
        label.textAlignment = NSTextAlignment.center
        label.adjustsFontSizeToFitWidth = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayFollowLists)))
        return label
    }()
    
    
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

    
    
    @objc func photoDoubleTapped(){
        print("Double Tap")
        self.handleLike()
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == listCollectionView {
            return 0
//            return self.postListNames.count
        }/* else if collectionView == selectedListCollectionView {
            return self.selectedListNames.count
        } */else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! LegitFullPostListCell
        
        var displayListName: String?
        var displayListId: String?

        cell.displayFont = 13
        if collectionView == listCollectionView {
            displayListName = self.postListNames[indexPath.row]
            displayListId = self.postListIds[indexPath.row]
//            cell.otherUser = !(self.post?.creatorUID == Auth.auth().currentUser?.uid)

        }/* else if collectionView == selectedListCollectionView {
            displayListName = self.selectedListNames[indexPath.row]
            displayListId = self.selectedListIds[indexPath.row]
//            cell.otherUser = false
        }*/

        cell.displayListName = displayListName
        cell.displayListId = displayListId
        cell.displayFont = 13
        cell.otherUser = self.creatorListIds.contains(where: { (listIds) -> Bool in
            listIds == displayListId
        })
        return cell
        
        
//        let displayListName = self.postListNames[indexPath.row]
//        let displayListId = self.postListIds[indexPath.row]
//
//        if self.post?.creatorUID == Auth.auth().currentUser?.uid {
//            // Current User is Creator
//            cell.otherUser = false
//        } else if let creatorListIds = self.post?.creatorListId {
//            // Current User is not Creator
//            if creatorListIds[displayListId] != nil {
//                //Is Non-Current User Creator ID
//                cell.otherUser = true
//            } else {
//                //Is Non-Current User Selected ID
//                cell.otherUser = false
//            }
//        } else {
//            cell.otherUser = false
//        }
//
//        cell.displayListName = displayListName
//        cell.displayListId = displayListId
//        cell.displayFont = 13
//        return cell
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == listCollectionView {
            self.delegate?.didTapExtraTag(tagName: self.postListNames[indexPath.row], tagId: self.postListIds[indexPath.row], post: self.post!)
        }
        
        /*else if collectionView == selectedListCollectionView {
            self.delegate?.didTapExtraTag(tagName: self.selectedListNames[indexPath.row], tagId: self.selectedListIds[indexPath.row], post: self.post!)
        }*/
        
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
        self.usernameLabel.text = ""
        self.emojiArray.emojiLabels = []
        self.locationNameLabel.text = ""
        
        photoImageScrollView.contentSize.width = photoImageScrollView.frame.width
        currentImage = 1
        noImageScroll = false
        photoImageView.image = nil
        photoImageView.cancelImageRequestOperation()
        starRatingHide?.isActive = true
        starRatingDisplay?.isActive = false
        locationDistanceLabel.text = ""
        self.popView.alpha = 0

        //        listCollectionViewHeightConstraint?.constant = locationViewHeight
        //        captionViewHeightConstraint?.constant = captionViewHeight
        
        
        //
        //        // Reset Zoom
        //        photoImageView.transform = CGAffineTransform.identity
        //        photoImageView.center = center
        //        self.isZooming = false
        
    }
    
    
}

extension FullPictureCell {
    
    
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



// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
