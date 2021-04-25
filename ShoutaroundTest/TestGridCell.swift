//
//  UserProfilePhotoCell.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/29/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import Cosmos

protocol TestGridPhotoCellDelegate {
    func didTapPicture(post:Post)
    func didTapListCancel(post:Post)
    func didTapUser(post: Post)
}

protocol TestGridPhotoCellDelegateObjc {
    func didTapCell(int: Int)
}

class TestGridPhotoCell: UICollectionViewCell, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    
    var delegate: TestGridPhotoCellDelegate?
    var delegateObjc: TestGridPhotoCellDelegateObjc?

    var post: Post? {
        didSet {
            guard let imageUrl = post?.imageUrl else {return}
            //            guard let url = URL(string: imageUrl) else {return}
            //            photoImageView.setImageWith(url)
            setupImageCountLabel()
            setupPageControl()
            setupPicturesScroll()
            photoImageView.loadImage(urlString: (post?.imageUrls.first)!)
            photoImageView.backgroundImage.isHidden = true
            
            refreshUserProfileImage()
            
            self.likeCount = post?.likeCount ?? 0
            self.listCount = post?.listCount ?? 0
            self.messageCount = post?.messageCount ?? 0
            
            let tempRatingEmoji = post?.ratingEmoji ?? ""
            //let tempExtraRatingEmoji = " " + (post?.emoji ?? "") + " "
            let tempExtraRatingEmoji = (post?.emoji ?? "")

            var emojiText = tempRatingEmoji + tempExtraRatingEmoji.replacingOccurrences(of: tempRatingEmoji, with: "")
            
//            emojiLabel.text = tempExtraRatingEmoji.replacingOccurrences(of: tempRatingEmoji, with: "")
            emojiLabel.text = emojiText
            emojiLabel.sizeToFit()

            ratingEmojiLabel.text = tempRatingEmoji
            ratingEmojiLabel.sizeToFit()
            ratingEmojiLabel.isHidden = ratingEmojiLabel.text == ""
            ratingEmojiWidth?.constant = ratingEmojiLabel.text == "" ? 0 : 22
            
            setupAttributedSocialCount()
            setupRatingLegitIcon()
            
            if showDistance {
                locationDistanceLabel.text = SharedFunctions.formatDistance(inputDistance: post?.distance)
                locationDistanceLabel.adjustsFontSizeToFitWidth = true
                locationDistanceLabel.sizeToFit()
            } else {
                locationDistanceLabel.text = ""
            }
            
            if let postRank = self.post?.listedRank {
                rankLabel.text = "#\(String(postRank))"
            } else {
                rankLabel.text = ""
            }
            
        }
    }
    
    var currentImage = 1 {
        didSet {
            setupImageCountLabel()
        }
    }
    
    var enableImageSelection: Bool? = false
    var selectedImage: Int? = nil
    
    
    let userProfileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        return iv
    }()
    
    var showUserProfileImage: Bool = true {
        didSet {
            refreshUserProfileImage()
        }
    }
    
    func refreshUserProfileImage() {
        // User Profile Image View
        guard let profileImageUrl = post?.user.profileImageUrl else {return}
        userProfileImageView.loadImage(urlString: profileImageUrl)
        showUserProfileWidth?.constant = showUserProfileImage ? userProfileImageWidth : 0
    }
    
    var showUserProfileWidth: NSLayoutConstraint?
    
    let userProfileImageWidth: CGFloat = 20
    
    var showDistance: Bool = false
    var enableCancel: Bool = false
    var imageCount = 0
    
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
    
    var socialHide: Bool = true {
        didSet{
            if socialHide{
                self.socialCount.alpha = 0
            } else {
                self.socialCount.alpha = 1
            }
        }
    }
    
    var likeCount: Int = 0
    var listCount: Int = 0
    var messageCount: Int = 0
    
    let photoImageScrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.backgroundColor = .clear
        return scroll
    }()
    
    let photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .lightGray
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        
        return iv
        
    }()
    
    let photoCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 10)
        label.textColor = UIColor.darkGray
        label.backgroundColor = UIColor.white
        label.layer.cornerRadius = 5
        label.layer.borderWidth = 0
        label.layer.masksToBounds = true
        label.alpha = 0.5
        return label
    }()
    
    let rankLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.mainBlue()
        label.layer.cornerRadius = 5
        label.layer.borderWidth = 0
        label.layer.masksToBounds = true
        label.alpha = 0.75
        return label
    }()
    
    var labelFontSize = 10 as CGFloat
    
    var socialCount: UILabel = {
        let label = UILabel()
        label.textAlignment = NSTextAlignment.right
        label.textColor = UIColor.lightGray
        label.backgroundColor = UIColor(white: 0, alpha: 0.4)
        return label
    }()
    
    let photoCheckMark: UIImageView = {
        let label = UIImageView()
        label.image = #imageLiteral(resourceName: "photo_upload_check").withRenderingMode(.alwaysOriginal)

        return label
    }()
    
    let starRating: CosmosView = {
        let iv = CosmosView()
        iv.settings.fillMode = .half
        iv.settings.totalStars = 5
        //        iv.settings.starSize = 30
        iv.settings.starSize = 12
        iv.settings.updateOnTouch = false
//        iv.settings.filledImage = #imageLiteral(resourceName: "ian_fullstar").withRenderingMode(.alwaysTemplate)
//        iv.settings.emptyImage = #imageLiteral(resourceName: "ian_emptystar").withRenderingMode(.alwaysTemplate)
        
        iv.settings.filledImage = #imageLiteral(resourceName: "newStar_Gold").withRenderingMode(.alwaysTemplate)
        iv.settings.emptyImage = #imageLiteral(resourceName: "newStar_gray").withRenderingMode(.alwaysTemplate)
        iv.rating = 0
        iv.settings.starMargin = 1
        return iv
    }()
    
    let emojiLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = UIColor.black
        label.isUserInteractionEnabled = true
        label.textAlignment = NSTextAlignment.left
        return label
    }()
    
    let ratingEmojiLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = UIColor.black
        label.isUserInteractionEnabled = true
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        label.backgroundColor = UIColor.clear
        label.layer.cornerRadius = 22/2
        label.layer.masksToBounds = true
        label.layer.borderWidth = 0
        label.layer.borderColor = UIColor.ianLegitColor().cgColor
        
        return label
    }()
    
    let locationDistanceLabel: LightPaddedUILabel = {
        let label = LightPaddedUILabel()
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.ianBlackColor()
        label.textAlignment = NSTextAlignment.left
        label.layer.cornerRadius = 1
        label.layer.borderWidth = 0
        label.layer.masksToBounds = true
        label.backgroundColor = UIColor.white.withAlphaComponent(0.75)
//        label.backgroundColor = UIColor.clear

        label.layer.cornerRadius = 5
        label.layer.borderWidth = 0
        label.layer.masksToBounds = true
        
//        label.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        return label
    }()
    
    var showCancelButton: Bool = false
    
    lazy var cancelPostButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "icons8-cancel-40").withRenderingMode(.alwaysOriginal), for: .normal)
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = 30/2
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        return button
    }()
    
    @objc func didTapCancel(){
        self.delegate?.didTapListCancel(post: self.post!)
    }
    
    let margin = 1 as CGFloat
    
    var pageControl : UIPageControl = UIPageControl()
//    var pageControlMini : UIPageControl = UIPageControl()

    lazy var pageControlMini: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        button.setImage(#imageLiteral(resourceName: "multiplePics").withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = UIColor.backgroundGrayColor()
        button.tintColor = UIColor.ianLegitColor()
        button.tintColor = UIColor.ianWhiteColor()
//        button.tintColor = UIColor.mainBlue()
        button.alpha = 0.5
        button.isUserInteractionEnabled = false
        return button
    }()
    
    
    func setupPageControl(){
        guard let imageCount = self.post?.imageCount else {return}
        self.pageControl.numberOfPages = imageCount
        self.pageControl.currentPage = 0
        self.pageControl.tintColor = UIColor.red
        self.pageControl.pageIndicatorTintColor = UIColor.white
        self.pageControl.currentPageIndicatorTintColor = UIColor.ianLegitColor()
        self.pageControl.isHidden = true
        
        self.pageControlMini.isHidden = imageCount <= 1
        
//        self.pageControlMini.numberOfPages = 1
//        self.pageControlMini.currentPage = 1
//        self.pageControlMini.tintColor = UIColor.red
//        self.pageControlMini.pageIndicatorTintColor = UIColor.white
//        self.pageControlMini.currentPageIndicatorTintColor = UIColor.white
//        self.pageControlMini.isHidden = imageCount == 1
        
        //        self.pageControl.backgroundColor = UIColor.rgb(red: 68, green: 68, blue: 68)
    }
    
    var ratingEmojiWidth: NSLayoutConstraint?

    var showCheckMark = false {
        didSet {
            self.photoCheckMark.isHidden = !showCheckMark
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        self.backgroundColor = UIColor.clear
        
        
        // Photo Image
        addSubview(photoImageScrollView)
        photoImageScrollView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.width)
        photoImageScrollView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: margin, paddingLeft: margin, paddingBottom: margin, paddingRight: margin, width: 0, height: 0)
        photoImageScrollView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
        photoImageScrollView.isPagingEnabled = true
        photoImageScrollView.delegate = self
        
        photoImageScrollView.contentSize.width = photoImageScrollView.frame.width - margin * 2
        photoImageScrollView.layer.cornerRadius = 1
        photoImageScrollView.layer.masksToBounds = true
        
        
        photoImageView.frame = CGRect(x: 0, y: 0, width: self.frame.width - margin * 2, height: self.frame.width - margin * 2)
        photoImageScrollView.addSubview(photoImageView)
        photoImageView.tag = 0
        
        
        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(GridPhotoCell.handlePictureTap))
        photoImageScrollView.addGestureRecognizer(TapGesture)
        photoImageScrollView.isUserInteractionEnabled = true
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(GridPhotoCell.handleLongPress(_:)))
        longPress.minimumPressDuration = 0.25
        longPress.delegate = self
        photoImageScrollView.addGestureRecognizer(longPress)
        
        

        
//        addSubview(rankLabel)
//        rankLabel.anchor(top: photoImageScrollView.topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)



        
        addSubview(socialCount)
        socialCount.anchor(top: nil, left: nil, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 2, paddingRight: 2, width: 0, height: 15)
        socialCount.alpha = 0
        
        
        addSubview(emojiLabel)
//        emojiLabel.anchor(top: nil, left: ratingEmojiLabel.rightAnchor, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 3, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        emojiLabel.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)

        //emojiLabel.backgroundColor = UIColor.ianWhiteColor().withAlphaComponent(0.5)
        emojiLabel.sizeToFit()
        
//        addSubview(ratingEmojiLabel)
//        ratingEmojiLabel.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 22)
//        ratingEmojiWidth = ratingEmojiLabel.widthAnchor.constraint(equalToConstant: 0)
//        ratingEmojiWidth?.isActive = true

        
        addSubview(userProfileImageView)
        userProfileImageView.anchor(top: nil, left: nil, bottom: bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: userProfileImageWidth)
        showUserProfileWidth = userProfileImageView.widthAnchor.constraint(equalToConstant: userProfileImageWidth)
        showUserProfileWidth?.isActive = true
        userProfileImageView.layer.cornerRadius = userProfileImageWidth/2
        userProfileImageView.layer.masksToBounds = true
        userProfileImageView.layer.borderColor = UIColor.white.cgColor
        userProfileImageView.layer.borderWidth = 0.5
        
//        addSubview(ratingEmojiLabel)
//        ratingEmojiLabel.anchor(top: nil, left: nil, bottom: bottomAnchor, right: userProfileImageView.leftAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 3, width: 0, height: 22)
//        ratingEmojiWidth = ratingEmojiLabel.widthAnchor.constraint(equalToConstant: 0)
//        ratingEmojiWidth?.isActive = true
        
        
//        addSubview(ratingEmojiLabel)
//        ratingEmojiLabel.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 3, width: 0, height: 22)
//        ratingEmojiWidth = ratingEmojiLabel.widthAnchor.constraint(equalToConstant: 0)
//        ratingEmojiWidth?.isActive = true
        
        

//        pageControl.anchor(top: topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 5, paddingBottom: 10, paddingRight: 5, width: 0, height: 5)
//        pageControl.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true

//        pageControl.leftAnchor.constraint(lessThanOrEqualTo: ratingEmojiLabel.rightAnchor).isActive = true

    // OLD LOCATION DISTANCE BOTTOM LEFT
//        addSubview(locationDistanceLabel)
//        locationDistanceLabel.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        
        addSubview(locationDistanceLabel)
        locationDistanceLabel.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        
        // IMAGE COUNT
        addSubview(pageControlMini)
        pageControlMini.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 20, height: 20)

        // IMAGE COUNT
        addSubview(pageControl)
        pageControl.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 0, height: 10)
        pageControl.isHidden = true

        addSubview(cancelPostButton)
        cancelPostButton.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 30, height: 30)
        cancelPostButton.isHidden = true
        
        addSubview(photoCheckMark)
        photoCheckMark.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 25, height: 25)
        photoCheckMark.isHidden = true
        

        
        //        addSubview(starRating)
        //        starRating.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        //        starRating.centerYAnchor.constraint(equalTo: userProfileImageView.centerYAnchor).isActive = true
        
        //        addSubview(photoCountLabel)
        //        photoCountLabel.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        //        photoCountLabel.sizeToFit()
        
        
    }
    
    func setupRatingLegitIcon(){
        
        if (self.post?.rating)! != 0 {
            self.starRating.isHidden = false
            self.starRating.rating = (self.post?.rating)!
            
            self.starRating.settings.filledImage = ((starRating.rating >= 4) ? #imageLiteral(resourceName: "newStar_Red") : #imageLiteral(resourceName: "newStar_Gold")).withRenderingMode(.alwaysOriginal)
            
            self.starRating.sizeToFit()
            self.starRating.settings.filledColor = UIColor.white
            
        } else {
            self.starRating.isHidden = true
        }
        
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
        self.pageControl.currentPage = self.currentImage - 1
        
//        self.pageControlMini.currentPageIndicatorTintColor = (self.pageControl.currentPage == 0) ? UIColor.white : UIColor.ianLegitColor()
        
        if self.pageControl.currentPage > 0 {
            self.pageControl.isHidden = false
            self.pageControlMini.isHidden = !self.pageControl.isHidden
//            self.pageControlMini.currentPage = (self.pageControl.currentPage > 0) ? 1 : 0
        } else {
        // FADE OUT PAGE CONTROL
            let animationDuration = 2.0
            UIView.animate(withDuration: animationDuration, animations: { () -> Void in
                self.pageControl.isHidden = true
                self.pageControlMini.isHidden = !self.pageControl.isHidden
//                self.pageControlMini.currentPage = (self.pageControl.currentPage > 0) ? 1 : 0
            }) { (Bool) -> Void in
            }
        }
//        self.pageControlMini.currentPage = !self.pageControl.isHidden ? 0 : 1
        print(self.currentImage, self.pageControl.currentPage)
    }
    
    func setupAttributedSocialCount(){
        
        let imageSize = CGSize(width: labelFontSize, height: labelFontSize)
        
        // Likes
        let attributedText = NSMutableAttributedString(string: String(self.likeCount), attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: labelFontSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.lightGray]))
        let likeImage = NSTextAttachment()
        likeImage.image = #imageLiteral(resourceName: "like_selected").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
        let likeImageString = NSAttributedString(attachment: likeImage)
        attributedText.append(likeImageString)
        
        // Bookmarks
        let bookmarkText = NSMutableAttributedString(string: String(self.listCount), attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: labelFontSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.lightGray]))
        attributedText.append(bookmarkText)
        let bookmarkImage = NSTextAttachment()
        bookmarkImage.image =  #imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
        let bookmarkImageString = NSAttributedString(attachment: bookmarkImage)
        attributedText.append(bookmarkImageString)
        
        // Messages
        let messageText = NSMutableAttributedString(string: String(self.messageCount), attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: labelFontSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.lightGray]))
        attributedText.append(messageText)
        let messageImage = NSTextAttachment()
        messageImage.image = #imageLiteral(resourceName: "message_fill").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
        let messageImageString = NSAttributedString(attachment: messageImage)
        attributedText.append(messageImageString)
        
        // Set Label
        socialCount.attributedText = attributedText
        socialCount.sizeToFit()
    }
    
    @objc func handlePictureTap() {
        if let post = post {
            print("Tap Picture")
            delegate?.didTapPicture(post: post)
        } else {
            print("Tap Picture | No Post | CELL TAG: \(self.tag)")
            delegateObjc?.didTapCell(int: self.tag)
        }
    }
    
    @objc func handleLongPress(_ gestureReconizer: UILongPressGestureRecognizer) {
        
        let animationDuration = 0.25
        
        if enableCancel {
            self.showCancelButton = true
            if showCancelButton {
                self.cancelPostButton.isHidden = false
                let when = DispatchTime.now() + 4 // change 2 to desired number of seconds
                DispatchQueue.main.asyncAfter(deadline: when) {
                    //Delay for 3 second to dismiss loading button if 0 fetched posts
                    self.cancelPostButton.isHidden = true
                }
            }
        }
        
        
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
        enableCancel = false
        showUserProfileImage = false
        post = nil
        starRating.isHidden = false
        self.pageControl.numberOfPages = 0
        self.pageControl.isHidden = true
        self.pageControlMini.isHidden = true
        self.showCheckMark = false
        
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
