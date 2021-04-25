//
//  BookmarkPhotoCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/22/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//


import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import Cosmos

protocol ListPhotoCellDelegate {
    //    func didTapComment(post:Post)
    func didTapUser(post:Post)
    func didTapLocation(post:Post)
    func didTapMessage(post:Post)
    func refreshPost(post:Post)
    func didTapBookmark(post:Post)
    
    func deletePostFromList(post:Post)
    func didTapPicture(post:Post)
    func didTapExtraTag(tagName: String, tagId: String, post: Post)
}

class ListPhotoCell: UICollectionViewCell, UIGestureRecognizerDelegate, UIScrollViewDelegate, EmojiButtonArrayDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    func doubleTapEmoji(index: Int?, emoji: String) {
        
    }
    

    let adressLabelSize = 8 as CGFloat
    var delegate: ListPhotoCellDelegate?
    var allowDelete: Bool = false
    var allowSelect: Bool = true
    
    var bookmarkDate: Date?{
        didSet{
            //            let timeAgoDisplay = bookmarkDate?.timeAgoDisplay()
            if let bookmarkDate = bookmarkDate {
                let formatter = DateFormatter()
                let calendar = NSCalendar.current
                
                let yearsAgo = calendar.dateComponents([.year], from: bookmarkDate, to: Date())
                if (yearsAgo.year)! > 0 {
                    formatter.dateFormat = "MMM d yy"
                } else {
                    formatter.dateFormat = "MMM d"
                }
                
                let daysAgo =  calendar.dateComponents([.day], from: bookmarkDate, to: Date())
                
                if (daysAgo.day)! <= 7 {
                    dateLabel.text = bookmarkDate.timeAgoDisplay()
                } else {
                    let dateDisplay = formatter.string(from: bookmarkDate)
                    dateLabel.text = dateDisplay
                }
            }
        }
    }
    var post: Post? {
        didSet {
            
            setupImageCountLabel()
            setupPicturesScroll()
            if (post?.images) != nil {
                photoImageView.image = post?.images![0]
            } else {
                photoImageView.loadImage(urlString: (post?.imageUrls.first)!)
            }
            
            // User Profile Image View
            guard let profileImageUrl = post?.user.profileImageUrl else {return}
            userProfileImageView.loadImage(urlString: profileImageUrl)
            
            // Emojis
            nonRatingEmojiLabel.text = (post?.nonRatingEmoji.joined())!

            emojiArray.emojiLabels = []
            if let displayEmojis = self.post?.nonRatingEmoji{
                if displayEmojis.count > 0 {
                    emojiArray.emojiLabels = [displayEmojis[0]]
                }
            }

            //        print("UPDATED EMOJI ARRAY: \(emojiArray.emojiLabels)")
            emojiArray.setEmojiButtons()
            emojiArray.sizeToFit()
            
            // Add Legit Emoji
            if (self.post?.isLegit)!{
                nonRatingEmojiLabel.text! += "👌"
            }
            
            nonRatingEmojiLabel.sizeToFit()
            
            // Location Name
            var locationNameDisplay: String? = ""
            if (self.post?.isLegit)! {
                locationNameDisplay = "👌 "
            }
            
            if let postLocationName = post?.locationName {
                // If no location  name and showing GPS, show the adress instead
                if postLocationName.hasPrefix("GPS"){
                    locationNameDisplay?.append((post?.locationAdress)!)
                } else {
                    locationNameDisplay?.append(postLocationName.formatName())
                }
            }
            
            if let ratingEmoji = self.post?.ratingEmoji {
                if extraRatingEmojis.contains(ratingEmoji) {
                    locationNameDisplay?.append(" \(ratingEmoji)")
                }
            }
            
            locationNameLabel.text = locationNameDisplay
            locationNameLabel.adjustsFontSizeToFitWidth = true
            locationNameLabel.sizeToFit()
            
//            legitEmojiLabel.isHidden = !(self.post?.isLegit)!
            

            // Star Rating
            
            if (post?.rating)! > 0 {
                starRatingLabel.isHidden = false
                starRatingLabel.rating = (post?.rating)!
                starRating.rating = (post?.rating)!
                starRating.isHidden = false
            } else{
                starRatingLabel.isHidden = true
                starRating.isHidden = true
            }
            // Always keep star rating label there even if hidden to keep white space
            //            starRatingLabel.sizeToFit()
            
            // Caption
            captionLabel.text = post?.caption.capitalizingFirstLetter()
            captionLabel.sizeToFit()
            
            // Distance
            
            distanceLabel.text = SharedFunctions.formatDistance(inputDistance: post?.distance, inputType: nil, expand: true)
            distanceLabel.adjustsFontSizeToFitWidth = true
            distanceLabel.sizeToFit()
            
//            setupExtraTags()
            setupAttributedSocialCount()
            
//            setupBookmarkButton()
            
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
            
            self.listCollectionView.reloadData()
            
        }
    }
    
    
    
    func setupBookmarkButton(){
        if self.post?.selectedListId != nil {
            if self.post?.selectedListId?.count == 0 {
                let attributedText = NSAttributedString(string: "#", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 14),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.legitColor()]))
                self.bookmarkActionButton.attributedText = attributedText
                self.bookmarkActionButton.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
                self.bookmarkActionButton.layer.borderColor = UIColor.legitColor().cgColor
                self.bookmarkActionButton.layer.borderWidth = 0

            } else {
                var listCaption: String = ""
                if (self.post?.selectedListId?.count)! == 1 {
                    listCaption = String((self.post?.selectedListId?.first?.value)!)
                } else {
                    listCaption = String((self.post?.selectedListId?.count)!)
                }
                let attributedText = NSAttributedString(string: "#" + listCaption , attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 14),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white]))
                self.bookmarkActionButton.attributedText = attributedText
                self.bookmarkActionButton.backgroundColor = UIColor.legitColor()
//                self.bookmarkActionButton.layer.borderColor = UIColor.legitColor().cgColor
//                self.bookmarkActionButton.layer.borderWidth = 1
            }
        } else {
                let attributedText = NSAttributedString(string: "#", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 14),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkLegitColor()]))
                self.bookmarkActionButton.attributedText = attributedText
                self.bookmarkActionButton.backgroundColor = UIColor.white
                self.bookmarkActionButton.layer.borderColor = UIColor.darkLegitColor().cgColor
                self.bookmarkActionButton.layer.borderWidth = 1
        }
        bookmarkActionButton.sizeToFit()
    }
    
    var currentImage = 1 {
        didSet {
            setupImageCountLabel()
        }
    }
    
    var imageCount = 0
    
    func setupImageCountLabel(){
        imageCount = (self.post?.imageCount)!
        self.photoCountLabel.text = "\(currentImage)\\\(imageCount)"
        photoCountLabel.reloadInputViews()
    }
    
    
//    fileprivate func setupAttributedLocationName(){
//
//        guard let post = self.post else {return}
//
//        let attributedText = NSMutableAttributedString(string: post.locationName.truncate(length: 20), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: adressLabelSize)])
//
//        if post.distance != nil && post.locationGPS?.coordinate.longitude != 0 && post.locationGPS?.coordinate.latitude != 0 {
//
//            let distanceformat = ".2"
//
//            // Convert to M to KM
//            let locationDistance = post.distance!/1000
//
//            attributedText.append(NSAttributedString(string: " \(locationDistance.format(f: distanceformat)) KM", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: adressLabelSize),NSForegroundColorAttributeName: UIColor.mainBlue()]))
//        }
//
//        self.locationNameLabel.attributedText = attributedText
//
//    }
    
    //  EMOJIS
    
    var emojiArray = EmojiButtonArray(emojis: [], frame: CGRect(x: 0, y: 0, width: 0, height: 20))
    
    let emojiDetailLabel: LightPaddedUILabel = {
        let label = LightPaddedUILabel()
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
        
        var displayTag = displayEmojiTag
        
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
    
    func hideEmojiDetailLabel(){
        self.emojiDetailLabel.alpha = 0
    }
    
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.boldSystemFont(ofSize: 11)
        label.sizeToFit()
        return label
    }()
    
    let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 11)
        label.textColor = UIColor.lightGray
        label.textAlignment = NSTextAlignment.right
        return label
    }()
    
    let userProfileImageView: CustomImageView = {
        
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        
        return iv
        
    }()
    
    let userProfileImageHeight: CGFloat = 30
    
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
        label.alpha = 0.75
        return label
    }()
    
    let nonRatingEmojiLabel: UILabel = {
        let label = UILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.clear
        return label
    }()
    
    let legitEmojiLabel: UILabel = {
        let label = UILabel()
        label.text = "👌"
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        return label
    }()
    
    
    let locationNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.font = UIFont(font: .verdanaBold, size: 14)
//        label.font = UIFont(font: .optimaBold, size: 14)

        label.numberOfLines = 2
        label.minimumScaleFactor = 0.5
        label.textColor = UIColor.ianBlackColor()
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.sizeToFit()
        label.frame = CGRect(x: 0, y: 0, width: 100, height: 20)
        return label
    }()
    
    let locationAdressLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.font = UIFont.boldSystemFont(ofSize: 8)
        label.textColor = UIColor.darkGray
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.sizeToFit()
        return label
    }()
    
    let captionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 0
        //        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        //        label.sizeToFit()
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 9)
        label.textAlignment = NSTextAlignment.right
        label.textColor = UIColor.gray
        label.sizeToFit()
        return label
    }()
    
    let captionTextView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.boldSystemFont(ofSize: 12)
        return tv
    }()
    
    lazy var likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "like_unselected").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleLike), for: .touchUpInside)
        return button
        
    }()
    
    var popView = UIView()
    
    func handleLike() {
        //      delegate?.didLike(for: self)
        
        guard let postId = self.post?.id else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let values = [postId: self.post?.hasLiked == true ? 0 : 1]
        Database.database().reference().child("likes").child(uid).updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Failed to like post", err)
                return
            }
            print("Succesfully Saved Likes")
            if (self.post?.hasLiked)! {
                self.post?.likeCount -= 1
            } else {
                self.post?.likeCount += 1
            }
            self.post?.hasLiked = !(self.post?.hasLiked)!
            self.delegate?.refreshPost(post: self.post!)
        }
        
        self.likeButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.likeButton.transform = .identity
            },
                       completion: nil)
        
    
    
    
            var origin: CGPoint = self.photoImageView.center;
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
    
    
    
    }
    
    // Bookmark
    
    lazy var bookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "ribbon").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleBookmark), for: .touchUpInside)
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        return button
    }()
    
    lazy var bookmarkActionButton: LightPaddedUILabel = {
       let label = LightPaddedUILabel()
        label.backgroundColor = UIColor.white
        label.isUserInteractionEnabled = true
        label.layer.cornerRadius = 5
        label.clipsToBounds = true
        return label
    }()
    
    
    func handleBookmark() {
        guard let post = self.post else {return}
        self.delegate?.didTapBookmark(post: post)
        
        //    delegate?.didBookmark(for: self)
        
//        guard let postId = self.post?.id else {return}
//        guard let creatorId = self.post?.creatorUID else {return}
//        guard let uid = Auth.auth().currentUser?.uid else {return}
//
//        Database.handleBookmark(postId: postId, creatorUid: creatorId){
//        }
//
//        // Animates before database function is complete
//
//        if (self.post?.hasBookmarked)! {
//            self.post?.listCount -= 1
//        } else {
//            self.post?.listCount += 1
//        }
//        self.post?.hasBookmarked = !(self.post?.hasBookmarked)!
//        self.delegate?.refreshPost(post: self.post!)
//
//        bookmarkButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
//
//        UIView.animate(withDuration: 1.0,
//                       delay: 0,
//                       usingSpringWithDamping: 0.2,
//                       initialSpringVelocity: 6.0,
//                       options: .allowUserInteraction,
//                       animations: { [weak self] in
//                        self?.bookmarkButton.transform = .identity
//            },
//                       completion: nil)
//
//        // Update Cache
//        postCache.removeValue(forKey: postId)
//        postCache[postId] = post
        
        
    }
    
    
    // Comments
    
    //    lazy var commentButton: UIButton = {
    //        let button = UIButton(type: .system)
    //        button.setImage(#imageLiteral(resourceName: "comment").withRenderingMode(.alwaysOriginal), for: .normal)
    //        button.addTarget(self, action: #selector(handleComment), for: .touchUpInside)
    //        return button
    //
    //    }()
    //
    //    func handleComment() {
    //        guard let post = post else {return}
    //        delegate?.didTapComment(post: post)
    //    }
    
    // Send Message
    
    lazy var sendMessageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "message_unfill").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleMessage), for: .touchUpInside)
        return button
        
    }()
    
    @objc func handleMessage(){
        guard let post = post else {return}
        delegate?.didTapMessage(post: post)
        
    }
    
    // Username/Location Tap
    
    @objc func usernameTap() {
        print("Tap username label", post?.user.username ?? "")
        guard let post = post else {return}
        delegate?.didTapUser(post: post)
    }
    
    @objc func locationTap() {
        print("Tap location label", post?.locationName ?? "")
        guard let post = post else {return}
        delegate?.didTapLocation(post: post)
    }
    
    @objc func handlePictureTap() {
        guard let post = post else {return}
        delegate?.didTapPicture(post: post)
    }
    
    // Social Counts
    let detailView = UIView()
    var socialCounts = UIStackView()
    let socialCountFontSize: CGFloat = 13
    
    var socialLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = NSTextAlignment.left
        return label
    }()
    
    let voteView = UIView()
    var voteCount: UILabel = {
        let label = UILabel()
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    let listView = UIView()
    let listCount: UILabel = {
        let label = UILabel()
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    let messageView = UIView()
    let messageCount: UILabel = {
        let label = UILabel()
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    var starRatingLabel = RatingLabelNew(ratingScore: 0, frame: CGRect.zero)
    let starRating: CosmosView = {
        let iv = CosmosView()
        iv.settings.fillMode = .half
        iv.settings.totalStars = 5
        //        iv.settings.starSize = 30
        iv.settings.starSize = 15
        iv.settings.updateOnTouch = false
        
        iv.settings.filledImage = #imageLiteral(resourceName: "ian_fullstar").withRenderingMode(.alwaysTemplate)
        iv.settings.emptyImage = #imageLiteral(resourceName: "ian_emptystar").withRenderingMode(.alwaysTemplate)
        iv.rating = 0
        iv.settings.starMargin = 1
        return iv
    }()
    
    // Lists
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
    
    // Setup Extra Tags
    
    let extraTagView: UIView = {
        let uv = UIView()
        uv.backgroundColor = UIColor.clear
        return uv
    }()
    
    let extraTagFontSize: CGFloat = 10
    let extraTagViewHeightSize: CGFloat = 20
    var extraTagViewHeight:NSLayoutConstraint?
    
    var extraTagsNameArray: [String] = []
    var extraTagsIdArray: [String] = []
    
    var extraTagsArray:[UIButton] = []
    lazy var extraTagLabel1 = UIButton()
    lazy var extraTagLabel2 = UIButton()
    lazy var extraTagLabel3 = UIButton()
    lazy var extraTagLabel4 = UIButton()
    
    func extraTagselected(_ sender: UIButton){
        guard let post = post else {return}
        let listTag = sender.tag
        
        var selectedListName = self.extraTagsNameArray[listTag]
        var selectedListId = self.extraTagsIdArray[listTag]
        
        print("Selected Creator Tag: \(selectedListName), \(selectedListId)")
        delegate?.didTapExtraTag(tagName: selectedListName, tagId: selectedListId, post: post)
    }
    
    func setupExtraTags(){
        
        // Refresh Tags - Only Creator Tags
        extraTagsNameArray.removeAll()
        extraTagsIdArray.removeAll()
        
        // Reset Extra Tags
        extraTagsArray = [extraTagLabel1, extraTagLabel2, extraTagLabel3, extraTagLabel4]
        
        for label in self.extraTagsArray {
            label.setTitle(nil, for: .normal)
            label.setImage(nil, for: .normal)
            label.layer.borderWidth = 0
            label.removeFromSuperview()
        }
        
        // Creator Created Tags
        if post?.creatorListId != nil {
            var listCount = post?.creatorListId?.count
            
            // Add Legit List
            for list in (post?.creatorListId)! {
                if list.value == legitListName {
                    extraTagsNameArray.append(list.value)
                    extraTagsIdArray.append(list.key)
                }
            }
            
            // Add Other List
            for list in (post?.creatorListId)! {
                if list.value != legitListName && list.value != bookmarkListName {
                    if extraTagsNameArray.count < 2 {
                        extraTagsNameArray.append(list.value)
                        extraTagsIdArray.append(list.key)
                    } else if extraTagsNameArray.count == 2 && listCount! == 3 {
                        extraTagsNameArray.append(list.value)
                        extraTagsIdArray.append(list.key)
                    } else if extraTagsNameArray.count == 2 && listCount! > 3 {
                        extraTagsNameArray.append("\(listCount! - 2)")
                        extraTagsIdArray.append("creatorLists")
                    }
                }
            }
        }
        
        // Creator Price Tag
        if post?.price != nil {
            extraTagsNameArray.append((post?.price)!)
            extraTagsIdArray.append("price")
        }
        
        // Extra Tag Button Label
        if extraTagsNameArray.count > 0 {
            for (index, listName) in (self.extraTagsNameArray.enumerated()) {
                
                extraTagsArray[index].tag = index
                extraTagsArray[index].setTitle(extraTagsNameArray[index], for: .normal)
                extraTagsArray[index].titleLabel?.font = UIFont.boldSystemFont(ofSize: extraTagFontSize)
                extraTagsArray[index].titleLabel?.textAlignment = NSTextAlignment.center
                extraTagsArray[index].layer.borderWidth = 1
                extraTagsArray[index].layer.backgroundColor = UIColor.white.cgColor
                extraTagsArray[index].layer.borderColor = UIColor.white.cgColor
                extraTagsArray[index].layer.cornerRadius = 5
                extraTagsArray[index].layer.masksToBounds = true
                extraTagsArray[index].contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
                extraTagsArray[index].addTarget(self, action: #selector(extraTagselected(_:)), for: .touchUpInside)
                
                
                if extraTagsNameArray[index] == bookmarkListName {
                    extraTagsArray[index].setImage(#imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal), for: .normal)
                    extraTagsArray[index].setTitle(nil, for: .normal)
                    extraTagsArray[index].setTitleColor(UIColor.white, for: .normal)
                    extraTagsArray[index].layer.backgroundColor = UIColor.white.cgColor
                }
                    
                else if extraTagsNameArray[index] == legitListName {
                    extraTagsArray[index].setTitleColor(UIColor.white, for: .normal)
                    extraTagsArray[index].setImage(#imageLiteral(resourceName: "legit").withRenderingMode(.alwaysOriginal), for: .normal)
                    extraTagsArray[index].layer.backgroundColor = UIColor.legitColor().cgColor.copy(alpha: 0.5)
                }
                    
                else if extraTagsIdArray[index] == "price" {
                    extraTagsArray[index].setTitleColor(UIColor.white, for: .normal)
                    extraTagsArray[index].layer.backgroundColor = UIColor.legitColor().cgColor
                }
                    
                else {
                    // Creator Tags
                    extraTagsArray[index].setTitle("#" + extraTagsNameArray[index].truncate(length: 10), for: .normal)
                    extraTagsArray[index].setTitleColor(UIColor.white, for: .normal)
                    extraTagsArray[index].layer.backgroundColor = UIColor.legitColor().cgColor
                }
                
                extraTagsArray[index].layer.borderWidth = 1
                
                // Add Tags to View
                let displayButton = extraTagsArray[index]
                self.addSubview(displayButton)
                
                if index == 0{
                    displayButton.anchor(top: extraTagView.topAnchor, left: extraTagView.leftAnchor, bottom: extraTagView.bottomAnchor, right: nil, paddingTop: 1, paddingLeft: 10, paddingBottom: 1, paddingRight: 0, width: 0, height: 0)
                } else {
                    displayButton.anchor(top: extraTagView.topAnchor, left: extraTagsArray[index - 1].rightAnchor, bottom: extraTagView.bottomAnchor, right: nil, paddingTop: 1, paddingLeft: 6, paddingBottom: 1, paddingRight: 0, width: 0, height: 0)
                }
            }
        }
        
        if extraTagsNameArray.count == 0 {
            extraTagViewHeight?.constant = 0
        } else {
            extraTagViewHeight?.constant = extraTagViewHeightSize
        }
        
    }
    
    override var isSelected: Bool {
        didSet {
            self.backgroundColor = self.isSelected ? UIColor.mainBlue().withAlphaComponent(0.75) : UIColor.white.withAlphaComponent(0.75)
        }
    }
    
    

    override init(frame: CGRect) {
        super.init(frame:frame)
        
//        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleLike))
//        doubleTap.numberOfTapsRequired = 2
//        self.addGestureRecognizer(doubleTap)
        
//        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handlePictureTap))
//        singleTap.numberOfTapsRequired = 1
//        self.addGestureRecognizer(singleTap)
//
        
        pan = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
        pan.delegate = self
        self.addGestureRecognizer(pan)
        
        // Photo Image View
        addSubview(photoImageScrollView)
        photoImageScrollView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 0, width: 0, height: 0)
        photoImageScrollView.widthAnchor.constraint(equalTo: heightAnchor, multiplier: 1).isActive = true
        photoImageScrollView.isPagingEnabled = true
        photoImageScrollView.delegate = self
        photoImageScrollView.layer.cornerRadius = 10
        photoImageScrollView.clipsToBounds = true
        photoImageScrollView.layer.borderWidth = 0.5
        photoImageScrollView.layer.borderColor = UIColor.lightGray.cgColor
        
        let photoDoubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(ListPhotoCell.handleLike))
        photoDoubleTapGesture.numberOfTapsRequired = 2
        
        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(ListPhotoCell.handlePictureTap))
        TapGesture.require(toFail: photoDoubleTapGesture)
        photoImageScrollView.addGestureRecognizer(TapGesture)
        photoImageScrollView.addGestureRecognizer(photoDoubleTapGesture)

        photoImageScrollView.isUserInteractionEnabled = true
        photoImageScrollView.contentSize.width = photoImageScrollView.frame.width
        
        photoImageView.frame = CGRect(x: 0, y: 0, width: self.frame.height, height: self.frame.height)
        photoImageScrollView.addSubview(photoImageView)
        photoImageView.tag = 0
    
            
    // Add User Profile Image
        addSubview(userProfileImageView)
        userProfileImageView.anchor(top: photoImageScrollView.topAnchor, left: photoImageScrollView.leftAnchor, bottom: nil, right: nil, paddingTop: -8, paddingLeft: -8, paddingBottom: 0, paddingRight: 10, width: userProfileImageHeight, height: userProfileImageHeight)
        userProfileImageView.layer.cornerRadius = userProfileImageHeight/2
        userProfileImageView.clipsToBounds = true
        userProfileImageView.layer.borderWidth = 0.25
        userProfileImageView.layer.borderColor = UIColor.legitColor().cgColor
        
        
        addSubview(photoCountLabel)
        photoCountLabel.anchor(top: nil, left: photoImageScrollView.leftAnchor, bottom: photoImageScrollView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        photoCountLabel.sizeToFit()
        
        
                
    // Location Data
        addSubview(locationNameLabel)
        locationNameLabel.anchor(top: topAnchor, left: photoImageScrollView.rightAnchor, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
//        locationNameLabel.centerYAnchor.constraint(equalTo: userProfileImageView.centerYAnchor).isActive = true
//        locationNameLabel.topAnchor.constraint(lessThanOrEqualTo: photoImageScrollView.topAnchor).isActive = true
//        locationNameLabel.centerYAnchor.constraint(lessThanOrEqualTo: userProfileImageView.centerYAnchor).isActive = true

//        locationNameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 140).isActive = true
        locationNameLabel.heightAnchor.constraint(lessThanOrEqualToConstant: 30).isActive = true
        locationNameLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 20).isActive = true
        locationNameLabel.sizeToFit()
//        locationNameLabel.backgroundColor = UIColor.mainBlue()

        
        let ratingView = UIView()
        addSubview(ratingView)
        ratingView.anchor(top: locationNameLabel.bottomAnchor, left: photoImageScrollView.rightAnchor, bottom: nil, right: rightAnchor, paddingTop: 3, paddingLeft: 10, paddingBottom: 5, paddingRight: 10, width: 0, height: 20)
        
        // ADD EMOJIS
        ratingView.addSubview(emojiArray)
        emojiArray.anchor(top: ratingView.topAnchor, left: nil, bottom: ratingView.bottomAnchor, right: ratingView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 15)
        emojiArray.delegate = self
        emojiArray.alignment = .right
        
            
            
    //     Add Star Rating
//        starRatingLabel = RatingLabelNew.init(ratingScore: 0, frame: CGRect(x: 0, y: 0, width: userProfileImageHeight * 0.8, height: userProfileImageHeight * 0.8))
        ratingView.addSubview(starRating)
        starRating.anchor(top: ratingView.topAnchor, left: ratingView.leftAnchor, bottom: ratingView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
//        starRatingLabel.centerYAnchor.constraint(equalTo: userProfileImageView.centerYAnchor).isActive = true

    
        
        addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top: nil, left: emojiArray.leftAnchor, bottom: photoImageScrollView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 25)
        self.hideEmojiDetailLabel()
        
        
//        addSubview(legitEmojiLabel)
//        legitEmojiLabel.anchor(top: photoImageScrollView.topAnchor, left: nil, bottom: nil, right: photoImageScrollView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 20, height: 20)
//        legitEmojiLabel.layer.cornerRadius = 10
//        legitEmojiLabel.layer.masksToBounds = true
//        legitEmojiLabel.isHidden = true
        

        // CAPTION
        addSubview(captionLabel)
        captionLabel.anchor(top: ratingView.bottomAnchor, left: ratingView.leftAnchor, bottom: nil, right: ratingView.rightAnchor, paddingTop: 8, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        captionLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: 3).isActive = true
//        captionLabel.heightAnchor.constraint(lessThanOrEqualToConstant: 40).isActive = true
//        captionLabel.backgroundColor = UIColor.yellow

        if allowSelect {
            captionLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handlePictureTap)))
        }

//
//        // DATE DETAIL VIEW
//        addSubview(detailView)
//        detailView.anchor(top: nil, left: photoImageScrollView.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 15)
//        setupSocialAndDateViews()
//
//        // LIST COLLECTION VIEW
//        addSubview(listCollectionView)
//        listCollectionView.anchor(top: nil, left: photoImageScrollView.rightAnchor, bottom: detailView.topAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 5, width: 0, height: 30)
//        setupListCollectionView()
//
//        addSubview(socialLabel)
//        socialLabel.anchor(top: nil, left: photoImageScrollView.rightAnchor, bottom: listCollectionView.topAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 5, width: 0, height: 20)
//        setupAttributedSocialCount()
        

        


        



        
        
        //
        //        addSubview(legitEmojiLabel)
        //        legitEmojiLabel.anchor(top: nil, left: nil, bottom: nil, right: starRatingLabel.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        //        legitEmojiLabel.centerYAnchor.constraint(equalTo: userProfileImageView.centerYAnchor).isActive = true
        
        //
        //
        //        addSubview(extraTagView)
        //        extraTagView.anchor(top: nil, left: photoImageView.rightAnchor, bottom: detailView.topAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        //        extraTagViewHeight = NSLayoutConstraint(item: extraTagView, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.width, multiplier: 1, constant: extraTagViewHeightSize)
        //        extraTagViewHeight?.isActive = true
        //
        
        
        // Tagged Emoji Data
        
//        addSubview(nonRatingEmojiLabel)
//        nonRatingEmojiLabel.anchor(top: nil, left: photoImageScrollView.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
//        nonRatingEmojiLabel.rightAnchor.constraint(lessThanOrEqualTo: starRatingLabel.leftAnchor).isActive = true
//        nonRatingEmojiLabel.centerYAnchor.constraint(equalTo: userProfileImageView.centerYAnchor).isActive = true
//        nonRatingEmojiLabel.heightAnchor.constraint(lessThanOrEqualTo: userProfileImageView.heightAnchor, multiplier: 0.8).isActive = true
//        nonRatingEmojiLabel.sizeToFit()
    
        

//        addSubview(bookmarkActionButton)
//        bookmarkActionButton.anchor(top: listCollectionView.topAnchor, left: photoImageScrollView.rightAnchor, bottom: listCollectionView.bottomAnchor, right: listCollectionView.leftAnchor, paddingTop: 3, paddingLeft: 10, paddingBottom: 3, paddingRight: 5, width: 0, height: 0)
//        bookmarkActionButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleBookmark)))
//        bookmarkActionButton.sizeToFit()

        

        
        
        // Location Distance
//        addSubview(distanceLabel)
//        distanceLabel.anchor(top: nil, left: nil, bottom: detailView.topAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
//        distanceLabel.sizeToFit()
        

        

        
        
        //
//
//        // Sets maximum caption label size
//        //        captionLabel.frame = CGRect(x: 0, y: 0, width: self.frame.width/2, height: self.frame.height)
//        captionLabel.sizeToFit()
        
        
        // Adding Gesture Recognizers
        
        
        userProfileImageView.isUserInteractionEnabled = true
        let usernameTap = UITapGestureRecognizer(target: self, action: #selector(ListPhotoCell.usernameTap))
        userProfileImageView.addGestureRecognizer(usernameTap)
        userProfileImageView.isUserInteractionEnabled = true
        
        
        let locationTapGesture = UITapGestureRecognizer(target: self, action: #selector(ListPhotoCell.locationTap))
        if allowSelect {
            locationNameLabel.addGestureRecognizer(locationTapGesture)
            locationNameLabel.isUserInteractionEnabled = true
        }

        let locationTapGesture2 = UITapGestureRecognizer(target: self, action: #selector(ListPhotoCell.locationTap))
        
        //        locationAdressLabel.addGestureRecognizer(locationTapGesture2)
        //        locationAdressLabel.isUserInteractionEnabled = true
        
        // Setup Dividers
        
        let topDividerView = UIView()
        topDividerView.backgroundColor = UIColor.lightGray
        
        let bottomDividerView = UIView()
        bottomDividerView.backgroundColor = UIColor.lightGray
        
        addSubview(topDividerView)
        addSubview(bottomDividerView)
        
        topDividerView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
//        bottomDividerView.anchor(top: bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
    }
    
    func setupListCollectionView(){
        listCollectionView.register(ListDisplayCell.self, forCellWithReuseIdentifier: cellId)
        let layout = ListDisplayFlowLayout()
        listCollectionView.collectionViewLayout = layout
        listCollectionView.backgroundColor = UIColor.clear
        listCollectionView.isScrollEnabled = true
        listCollectionView.showsHorizontalScrollIndicator = false
    }
    
    
    func setupPicturesScroll() {
        
        guard let _ = post?.imageUrls else {return}
        if (post?.imageCount)! < 1 {
            return
        }
        
        photoImageScrollView.contentSize.width = photoImageScrollView.frame.width * CGFloat((post?.imageCount)!)
        
        for i in 1 ..< (post?.imageCount)! {
            
            let imageView = CustomImageView()
            guard let images = post?.images else {return}
            
            if let image = post?.images![i] {
                imageView.image = image
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
    
    
    
    var pan: UIPanGestureRecognizer!
    
    
    func onPan(_ pan: UIPanGestureRecognizer){
        if pan.state == UIGestureRecognizer.State.began {
            
        } else if pan.state == UIGestureRecognizer.State.changed {
            self.setNeedsLayout()
        } else {
            if abs(pan.velocity(in: self).x) > 500 {
                if allowDelete{
                    delegate?.deletePostFromList(post: post!)
                }
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    self.setNeedsLayout()
                    self.layoutIfNeeded()
                })
            }
        }
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return abs((pan.velocity(in: pan.view)).x) > abs((pan.velocity(in: pan.view)).y)
    }
    

    
    
    func setupSocialAndDateViews(){
        
        addSubview(dateLabel)
        dateLabel.textAlignment = NSTextAlignment.right
        dateLabel.anchor(top: detailView.topAnchor, left: nil, bottom: detailView.bottomAnchor, right: detailView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        dateLabel.sizeToFit()
        
//        addSubview(socialLabel)
//        socialLabel.anchor(top: detailView.topAnchor, left: detailView.leftAnchor, bottom: detailView.bottomAnchor, right: dateLabel.leftAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//
        
//        let socialCounts = UIStackView(arrangedSubviews: [voteView, listView, messageView])
//        socialCounts.distribution = .fillEqually
//        socialCounts.spacing = 5
//        addSubview(socialCounts)
//        socialCounts.anchor(top: detailView.topAnchor, left: detailView.leftAnchor, bottom: detailView.bottomAnchor, right: dateLabel.leftAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//
//        addSubview(voteCount)
//        voteCount.anchor(top: voteView.topAnchor, left: voteView.leftAnchor, bottom: voteView.bottomAnchor, right: voteView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//
//        addSubview(listCount)
//        listCount.anchor(top: listView.topAnchor, left: listView.leftAnchor, bottom: listView.bottomAnchor, right: listView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//
//        addSubview(messageCount)
//        messageCount.anchor(top: messageView.topAnchor, left: messageView.leftAnchor, bottom: messageView.bottomAnchor, right: messageView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    }
    
    func setupAttributedSocialCount(){
        
        guard let post = post else {return}
        let imageSize = CGSize(width: socialCountFontSize + 3, height: socialCountFontSize + 3)
        var attributedSocialText = NSMutableAttributedString()
        
        // Votes
        if (post.likeCount) > 0 {
            let voteCountString = String(describing: post.likeCount)
            let attributedText = NSMutableAttributedString(string: "  \(voteCountString)  ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: socialCountFontSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black]))
            attributedSocialText.append(attributedText)
            let voteImage = NSTextAttachment()
            let voteIcon = (post.hasLiked ? #imageLiteral(resourceName: "cred_filled") : #imageLiteral(resourceName: "cred_unfilled")).withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
            voteImage.bounds = CGRect(x: 0, y: (socialLabel.font.capHeight - voteIcon.size.height).rounded() / 2, width: voteIcon.size.width, height: voteIcon.size.height)
            voteImage.image = voteIcon
            let voteImageString = NSAttributedString(attachment: voteImage)
            attributedSocialText.append(voteImageString)
        }

        //        voteCount.backgroundColor = UIColor.blue
        
        // Bookmarks
        if (post.listCount) > 0 {
            let listCountString = String(describing: post.listCount)
            let attributedText = NSMutableAttributedString(string: "  \(listCountString)  ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: socialCountFontSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black]))
            attributedSocialText.append(attributedText)

            let listImage = NSTextAttachment()
            let listIcon = (post.hasPinned == true ? #imageLiteral(resourceName: "bookmark_filled") : #imageLiteral(resourceName: "bookmark_unfilled")).withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
            listImage.bounds = CGRect(x: 0, y: (socialLabel.font.capHeight - listIcon.size.height).rounded() / 2, width: listIcon.size.width, height: listIcon.size.height)

            
            listImage.image = listIcon
            let listImageString = NSAttributedString(attachment: listImage)
            attributedSocialText.append(listImageString)
        }

        //        listCount.backgroundColor = UIColor.green
        
        
        // Messages
        var messageCountString: String = ""
        if (post.messageCount) > 0 {
            let messageCountString = String(describing: post.messageCount)
            let attributedText = NSMutableAttributedString(string: " \(messageCountString) ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: socialCountFontSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black]))
            attributedSocialText.append(attributedText)

            let messageImage = NSTextAttachment()
            let messageIcon = ((post.hasMessaged) ? #imageLiteral(resourceName: "message_fill") : #imageLiteral(resourceName: "message_unfill")).withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
            messageImage.bounds = CGRect(x: 0, y: (socialLabel.font.capHeight - messageIcon.size.height).rounded() / 2, width: messageIcon.size.width, height: messageIcon.size.height)

            messageImage.image = messageIcon
            let messageImageString = NSAttributedString(attachment: messageImage)
            attributedSocialText.append(messageImageString)
        }

        socialLabel.attributedText = attributedSocialText
        
        //        messageCount.backgroundColor = UIColor.blue
        
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.post?.creatorListId != nil {
            return (self.post?.creatorListId?.count)!
        } else {return 0}
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ListDisplayCell

        cell.displayListName = self.postListNames[indexPath.row]
        cell.displayListId = self.postListIds[indexPath.row]
        cell.displayFont = 13

        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.didTapExtraTag(tagName: self.postListNames[indexPath.row], tagId: self.postListIds[indexPath.row], post: self.post!)
    }
    
    override func prepareForReuse() {
        self.post?.creatorListId = nil
        self.userProfileImageView.image = UIImage()
        self.currentImage = 1
        self.listCollectionView.reloadData()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
