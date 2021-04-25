//
//  UserProfilePhotoCell.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/29/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import Cosmos

protocol ExplorePhotoCellDelegate {
    func didTapPicture(post:Post)
    func didTapLocation(post: Post)
}

class ExplorePhotoCell: UICollectionViewCell, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    
    var delegate: ExplorePhotoCellDelegate?
    var post: Post? {
        didSet {
            guard let imageUrl = post?.imageUrl else {return}
            //            guard let url = URL(string: imageUrl) else {return}
            //            photoImageView.setImageWith(url)
            setupImageCountLabel()
            setupPicturesScroll()
            photoImageView.loadImage(urlString: (post?.imageUrls.first)!)
            userProfileImageView.loadImage(urlString: (post?.user.profileImageUrl)!)
            usernameLabel.text = post?.user.username
            
            self.credCount = post?.credCount ?? 0
            self.listCount = post?.listCount ?? 0
            self.messageCount = post?.messageCount ?? 0
            
            self.ratingEmojiLabel.text = self.post?.ratingEmoji
            self.ratingEmojiLabel.sizeToFit()
            setupAttributedSocialCount()
            setupRatingLegitIcon()
        }
    }
    var currentImage = 1 {
        didSet {
            setupImageCountLabel()
        }
    }
    
    
    func setupRatingLegitIcon(){
        
        if (self.post?.rating)! != 0 {
            
            self.starRating.rating = (self.post?.rating)!
            if starRating.rating >= 4 {
                starRating.settings.filledImage = #imageLiteral(resourceName: "star_rating_filled_high").withRenderingMode(.alwaysOriginal)
            } else {
                starRating.settings.filledImage = #imageLiteral(resourceName: "star_rating_filled_mid").withRenderingMode(.alwaysOriginal)
            }
            
            self.starRatingHide?.isActive = false
            self.starRating.isHidden = (self.starRatingHide?.isActive)!
            self.starRating.sizeToFit()
            
        } else {
            self.starRatingHide?.isActive = true
            self.starRating.isHidden = (self.starRatingHide?.isActive)!
            self.starRating.sizeToFit()
        }
        
    }
    
    let starRating: CosmosView = {
        let iv = CosmosView()
        iv.settings.fillMode = .half
        iv.settings.totalStars = 5
        //        iv.settings.starSize = 30
        iv.settings.starSize = 12
        iv.settings.updateOnTouch = false
        iv.settings.filledImage = #imageLiteral(resourceName: "star_rating_filled_mid").withRenderingMode(.alwaysOriginal)
        iv.settings.emptyImage = #imageLiteral(resourceName: "star_rating_unfilled").withRenderingMode(.alwaysOriginal)
        iv.rating = 0
        iv.settings.starMargin = 1
        return iv
    }()
    
    var starRatingHide: NSLayoutConstraint?
    var starRatingDisplay: NSLayoutConstraint?
    
    var imageCount = 0
    
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
    
    var selectedHeaderSort: String? = nil {
        didSet{
            setupPhotoDetails()
        }
    }
    
    var socialHide: Bool = true {
        didSet{
            if socialHide{
                self.socialCount.alpha = 0
            } else {
                self.socialCount.alpha = 1
            }
        }
    }
    
    var credCount: Int = 0
    var listCount: Int = 0
    var messageCount: Int = 0
    
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
    
    
    
    var socialCount: UILabel = {
        let label = UILabel()
        label.textAlignment = NSTextAlignment.right
        label.textColor = UIColor.darkLegitColor()
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 0
        return label
    }()
    
    let labelFontSize = 12 as CGFloat
    
    let locationLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.textColor = UIColor.black
        label.isUserInteractionEnabled = true
        label.textAlignment = NSTextAlignment.left
        return label
    }()
    
    func tapLocation(){
        self.delegate?.didTapLocation(post: self.post!)
    }
    
    let emojiLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = UIColor.black
        label.isUserInteractionEnabled = true
        label.textAlignment = NSTextAlignment.right
        return label
    }()
    
    let ratingEmojiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.black
        label.isUserInteractionEnabled = true
        label.textAlignment = NSTextAlignment.left
        return label
    }()
    
    let metricLabel: UILabel = {
        let label = UILabel()
        label.isUserInteractionEnabled = true
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.mainBlue()
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
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(font: .appleSDGothicNeoBold, size: 12)
        label.textColor = UIColor.white
        return label
    }()
    
    var photoDetailView = UIView()
    
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        self.layer.cornerRadius = 5
        self.layer.masksToBounds = true
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 0
        self.backgroundColor = UIColor.white
        
    // Photo Detail View - Emoji and Metrics
        
        addSubview(photoDetailView)
        photoDetailView.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
        // Location Distance
        addSubview(metricLabel)
        metricLabel.anchor(top: photoDetailView.topAnchor, left: nil, bottom: photoDetailView.centerYAnchor, right: photoDetailView.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 3, width: 0, height: 0)
        
        
        // Location Name
        addSubview(locationLabel)
        locationLabel.anchor(top: photoDetailView.topAnchor, left: photoDetailView.leftAnchor, bottom: photoDetailView.centerYAnchor, right: metricLabel.leftAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        //        locationLabel.bottomAnchor.constraint(lessThanOrEqualTo: emojiLabel.topAnchor).isActive = true
        //        locationLabel.bottomAnchor.constraint(lessThanOrEqualTo: metricLabel.topAnchor).isActive = true
        locationLabel.sizeToFit()
        locationLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapLocation)))

        
        addSubview(starRating)
        starRating.anchor(top: locationLabel.bottomAnchor, left: photoDetailView.leftAnchor, bottom: photoDetailView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        starRatingHide = starRating.widthAnchor.constraint(equalToConstant: 0)
        starRatingDisplay = starRating.heightAnchor.constraint(equalToConstant: photoDetailView.frame.height/2)
        
        
        addSubview(ratingEmojiLabel)
        ratingEmojiLabel.anchor(top: starRating.topAnchor, left: starRating.rightAnchor, bottom: starRating.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        ratingEmojiLabel.sizeToFit()
        
        addSubview(socialCount)
        socialCount.anchor(top: starRating.topAnchor, left: ratingEmojiLabel.rightAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: photoDetailView.frame.height/2)
        socialCount.alpha = 1
        
        
//        addSubview(emojiLabel)
//        emojiLabel.anchor(top: nil, left: nil, bottom: userProfileImageView.bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: photoDetailView.frame.height/2)
        




    // Photo Image
        addSubview(photoImageScrollView)
        photoImageScrollView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.width)
        photoImageScrollView.anchor(top: topAnchor, left: leftAnchor, bottom: photoDetailView.topAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        photoImageScrollView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
        photoImageScrollView.isPagingEnabled = true
        photoImageScrollView.delegate = self

        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(ExplorePhotoCell.handlePictureTap))
        photoImageScrollView.addGestureRecognizer(TapGesture)
        photoImageScrollView.isUserInteractionEnabled = true
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(ExplorePhotoCell.handleLongPress(_:)))
        longPress.minimumPressDuration = 0.25
        longPress.delegate = self
        photoImageScrollView.addGestureRecognizer(longPress)
        
        photoImageScrollView.contentSize.width = photoImageScrollView.frame.width
        
        photoImageView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.width)
        photoImageScrollView.addSubview(photoImageView)
        photoImageView.tag = 0
        
        // Add Photo Count Label
        
        addSubview(photoCountLabel)
        photoCountLabel.anchor(top: photoImageScrollView.topAnchor, left: nil, bottom: nil, right: photoImageScrollView.rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        photoCountLabel.sizeToFit()

        
        addSubview(emojiLabel)
        emojiLabel.anchor(top: nil, left: nil, bottom: photoImageScrollView.bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 3, paddingRight: 5, width: 0, height: photoDetailView.frame.height/2)
        
        
        addSubview(userProfileImageView)
        userProfileImageView.anchor(top: nil, left: photoImageScrollView.leftAnchor, bottom: photoImageScrollView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 4, paddingBottom: 5, paddingRight: 5, width: 30, height: 30)
        userProfileImageView.widthAnchor.constraint(equalTo: userProfileImageView.heightAnchor, multiplier: 1).isActive = true
        userProfileImageView.layer.cornerRadius = (40-10)/2
        userProfileImageView.layer.borderWidth = 0.5
        userProfileImageView.layer.borderColor = UIColor.white.cgColor
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: nil, left: userProfileImageView.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 2, paddingBottom: 0, paddingRight: 2, width: 0, height: 0)
        usernameLabel.centerYAnchor.constraint(equalTo: userProfileImageView.centerYAnchor).isActive = true
        usernameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: self.frame.width/2)
        usernameLabel.sizeToFit()
        usernameLabel.isHidden = true
        
    }
    
    
    func setupPicturesScroll() {
        
        guard let _ = post?.imageUrls else {return}
        
        photoImageScrollView.contentSize.width = photoImageScrollView.frame.width * CGFloat((post?.imageCount)!)
        
        for i in 1 ..< (post?.imageCount)! {
            
            let imageView = CustomImageView()
            imageView.loadImage(urlString: (post?.imageUrls[i])!)
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
    
    func setupPhotoDetails(){
    // Setup Emojis
        emojiLabel.text = post?.emoji
        
        if (self.post?.isLegit)! {
            (emojiLabel.text)! += legitString
        }
        
    // Setup Location Labels
        var displayLocationName: String = ""
        guard let post = self.post else {return}

        if post.locationGooglePlaceID! == "" {
            // Detect Not Google Tagged Location
            
            let locationNameTextArray = post.locationAdress.components(separatedBy: ",")
            // Last 3 items are City, State, Country
            displayLocationName = locationNameTextArray.suffix(3).joined(separator: ",")
        } else {
            displayLocationName = post.locationName
        }
        
        self.locationLabel.text = displayLocationName
        
    // Setup Social
        var attributedText: NSMutableAttributedString = NSMutableAttributedString(string: "")
        
        let imageSize = CGSize(width: labelFontSize, height: labelFontSize)

        if selectedHeaderSort == "Votes" && self.credCount > 0 {
            let attributedString = NSMutableAttributedString(string: "  \(String(self.credCount)) ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: labelFontSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.lightGray]))
            let likeImage = NSTextAttachment()
            likeImage.image = #imageLiteral(resourceName: "cred_filled").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
            let likeImageString = NSAttributedString(attachment: likeImage)
            attributedText.append(attributedString)
            attributedText.append(likeImageString)
        }
        else if selectedHeaderSort == "Lists" && self.listCount > 0{
            let attributedString = NSMutableAttributedString(string: "  \(String(self.listCount)) ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: labelFontSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.lightGray]))
            let likeImage = NSTextAttachment()
            likeImage.image = #imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
            let likeImageString = NSAttributedString(attachment: likeImage)
            attributedText.append(attributedString)
            attributedText.append(likeImageString)
        }
        else if selectedHeaderSort == "Messages" && self.messageCount > 0{
            let attributedString = NSMutableAttributedString(string: "  \(String(self.messageCount)) ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: labelFontSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.lightGray]))
            let likeImage = NSTextAttachment()
            likeImage.image = #imageLiteral(resourceName: "message_fill").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
            let likeImageString = NSAttributedString(attachment: likeImage)
            attributedText.append(attributedString)
            attributedText.append(likeImageString)
        }  else if selectedHeaderSort == "Nearest"{
            
            // Setup Distance
            var postDistance: String = ""
            guard let postdistance = post.distance else {return}
            let distanceInKM = postdistance/1000
            let locationDistance = Measurement.init(value: distanceInKM, unit: UnitLength.kilometers)
            
            if distanceInKM < 100 {
                postDistance =  CurrentUser.distanceFormatter.string(from: locationDistance)
            }  else if distanceInKM < 300 {
                postDistance =  "🚗"+CurrentUser.distanceFormatter.string(from: locationDistance)
            }  else if distanceInKM >= 300 {
                postDistance =  "✈️"+CurrentUser.distanceFormatter.string(from: locationDistance)
            }
            
            
            
            let attributedString = NSMutableAttributedString(string: "  \(String.init(postDistance)) ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: labelFontSize - 2), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.mainBlue()]))
            attributedText.append(attributedString)
            
        } else if selectedHeaderSort == "Trending" && self.credCount > 0 {
            let attributedString = NSMutableAttributedString(string: "  \(String(self.credCount)) ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: labelFontSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.lightGray]))
            let likeImage = NSTextAttachment()
            likeImage.image = #imageLiteral(resourceName: "cred_filled").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
            let likeImageString = NSAttributedString(attachment: likeImage)
            attributedText.append(attributedString)
            attributedText.append(likeImageString)
        }

//        metricLabel.attributedText = attributedText
//        metricLabel.sizeToFit()
        
        metricLabel.text = SharedFunctions.formatDistance(inputDistance: post.distance)
        metricLabel.sizeToFit()
        metricLabel.adjustsFontSizeToFitWidth = true
    }
    
    func setupAttributedSocialCount(){
        
        let socialCountSize = labelFontSize
        let socialCountColor = UIColor.darkGray
        let imageSize = CGSize(width: socialCountSize, height: socialCountSize)
        
        let attributedText = NSMutableAttributedString(string: "")
        
        
        // Bookmarks
        if self.listCount > 0 {
            let bookmarkText = NSMutableAttributedString(string: "  \(String(self.listCount))  ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: socialCountSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): socialCountColor]))
            attributedText.append(bookmarkText)
            let bookmarkImage = NSTextAttachment()
            bookmarkImage.image = ((self.post?.hasPinned)! ? #imageLiteral(resourceName: "pin_filled") : #imageLiteral(resourceName: "pin_unfilled")).withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
            let bookmarkImageString = NSAttributedString(attachment: bookmarkImage)
            attributedText.append(bookmarkImageString)
        }
        
        
        // Votes
        if self.credCount > 0 {
            let attributedString = NSMutableAttributedString(string: "  \(String(self.credCount))  ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: socialCountSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): socialCountColor]))
            let voteImage = NSTextAttachment()
            voteImage.image = ((self.post?.hasLiked)! ? #imageLiteral(resourceName: "drool") : #imageLiteral(resourceName: "drool").alpha(0.5)).withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
            let voteImageString = NSAttributedString(attachment: voteImage)
            attributedText.append(attributedString)
            attributedText.append(voteImageString)
        }

        socialCount.attributedText = attributedText
        socialCount.sizeToFit()
        
        // Messages
//        if self.messageCount > 0 {
//            let messageText = NSMutableAttributedString(string: "  \(String(self.messageCount))  ", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: socialCountSize), NSForegroundColorAttributeName: socialCountColor])
//            attributedText.append(messageText)
//            let messageImage = NSTextAttachment()
//            messageImage.image = #imageLiteral(resourceName: "message_fill").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
//            let messageImageString = NSAttributedString(attachment: messageImage)
//            attributedText.append(messageImageString)
//        }
        

//
//        if let caption = self.post?.caption{
//            let attributedCaptionSpace = NSMutableAttributedString(string: "\n\n", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: labelFontSize - 2), NSForegroundColorAttributeName: socialCountColor])
//
//            let attributedCaptionString = NSMutableAttributedString(string: "\(caption)  ", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: labelFontSize + 2), NSForegroundColorAttributeName: socialCountColor])
//
//            // Legit Icon or Rating Score
//
//            if (self.post?.isLegit)! {
//                let legitImage = NSTextAttachment()
//                legitImage.image = #imageLiteral(resourceName: "legit").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
//                let legitImageString = NSAttributedString(attachment: legitImage)
//                attributedCaptionString.append(legitImageString)
//            }
//            else if (self.post?.rating)! > 0 {
//                let attributedRatingString = NSAttributedString(string: String(describing: (self.post?.rating)!), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: labelFontSize + 2), NSForegroundColorAttributeName: RatingColors.ratingColor(rating: post?.rating)])
//                attributedCaptionString.append(attributedRatingString)
//            }
//
//            // Take out Space if there are no social Stats
//            if self.credCount == 0 && self.listCount == 0 && self.messageCount == 0 {
//                let attributedText = attributedCaptionString
//            } else {
//                attributedText.append(attributedCaptionSpace)
//                attributedText.append(attributedCaptionString)
//            }
//        }
//
        
        
        // Set Label
//        socialCount.attributedText = attributedText
//        socialCount.sizeToFit()
    }
    
    
    func handlePictureTap() {
        guard let post = post else {return}
        print("Tap Picture")
        delegate?.didTapPicture(post: post)
    }
    
    func handleLongPress(_ gestureReconizer: UILongPressGestureRecognizer) {
        
        let animationDuration = 0.25
        
        if socialHide {
            if gestureReconizer.state != UIGestureRecognizer.State.recognized {
                // Fade in Social Counts when held
                UIView.animate(withDuration: animationDuration, animations: { () -> Void in
                    self.socialCount.alpha = 1
                }) { (Bool) -> Void in
                }
            }
            else if gestureReconizer.state != UIGestureRecognizer.State.changed {
                // Fade Out Social Counts when released
                UIView.animate(withDuration: animationDuration, animations: { () -> Void in
                    self.socialCount.alpha = 0
                }) { (Bool) -> Void in
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        //Flickering is caused by reused cell having previous photo or loading prior image request
        photoImageScrollView.contentSize.width = photoImageScrollView.frame.width
        currentImage = 1
        photoImageView.image = nil
        photoImageView.cancelImageRequestOperation()
        post = nil
        metricLabel.attributedText = NSAttributedString(string: "")        
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
