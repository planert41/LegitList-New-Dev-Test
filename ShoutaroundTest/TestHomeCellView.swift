//
//  UserProfilePhotoCell.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/29/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import Cosmos

//protocol TestGridPhotoCellDelegate {
//    func didTapPicture(post:Post)
//    func didTapListCancel(post:Post)
//}
//
//protocol TestGridPhotoCellDelegateObjc {
//    func didTapCell(int: Int)
//}

class TestHomePhotoCell: UICollectionViewCell, UIGestureRecognizerDelegate, UIScrollViewDelegate, EmojiButtonArrayDelegate {
    
    
    
    // INPUT SIZES
    let headerInfoHeight: CGFloat = 30 //35
    
    var emojiFontSize: CGFloat = 15 {
        didSet {
            setupEmojis()
        }
    }
    
    

    
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
            
            var tempRatingEmoji = post?.ratingEmoji ?? ""
            //let tempExtraRatingEmoji = " " + (post?.emoji ?? "") + " "
            var tempEmojis = (post?.emoji ?? "")
            
//            if showDistance {
//                tempEmojis += tempRatingEmoji
//                tempRatingEmoji = ""
//            }
            
            setupEmojis()

            let likeString = self.likeCount > 0 ? "\(String(self.likeCount)) " : ""
//            print(likeString, post?.locationName)
            likeCountButton.setTitle(likeString, for: .normal)
            likeCountButton.isHidden = !(self.likeCount > 0)
            likeCountButton.setTitleColor(UIColor.darkGray, for: .normal)
            likeCountButton.sizeToFit()
            
            let ratingEmojiTitle = NSAttributedString(string: tempRatingEmoji, attributes: [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont(font: .avenirNextBold, size: 25)])
            ratingEmojiTestLabel.attributedText = ratingEmojiTitle
            ratingEmojiTestLabel.sizeToFit()

//            emojiLabel.text = tempExtraRatingEmoji.replacingOccurrences(of: tempRatingEmoji, with: "")
            

            ratingEmojiLabel.text = tempRatingEmoji
            ratingEmojiLabel.isHidden = ratingEmojiLabel.text == ""
            hideRatingEmoji?.constant = ratingEmojiLabel.text == "" ? 0 : 25
//            ratingEmojiWidth?.constant = ratingEmojiLabel.text == "" ? 0 : 22
            
            setupAttributedSocialCount()
            setupRatingLegitIcon()
            
            locationDistanceLabel.text = showDistance ? SharedFunctions.formatDistance(inputDistance: post?.distance) : ""
            if showDistance {
                locationDistanceLabel.isHidden = locationDistanceLabel.text?.isEmptyOrWhitespace() ?? true
            } else {
                locationDistanceLabel.isHidden = true
            }
            locationDistanceLabel.adjustsFontSizeToFitWidth = true
            locationDistanceLabel.sizeToFit()
            
            
            if let postRank = self.post?.listedRank {
                rankLabel.text = "#\(String(postRank))"
            } else {
                rankLabel.text = ""
            }
            
        // LOCATION NAME
            
        // Has google Location, show name
            if self.post?.locationGooglePlaceID != "" {
                locationNameLabel.text = self.post?.locationName
            }
        // SHOW CITY
            else if self.post?.locationSummaryID != "" {
                locationNameLabel.text = self.post?.locationSummaryID
            } else {
                locationNameLabel.text = ""

            }
            
            self.locationNameFade.text = locationNameLabel.text
            self.locationNameFade.sizeToFit()
            
            var locationNameLabelString = NSMutableAttributedString()
            
            let locationString = NSMutableAttributedString(string: locationNameLabel.text ?? "", attributes: [NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 14), NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor()])

            
            let captionString1 = String(post?.caption ?? "")
            
            let captionString = NSMutableAttributedString(string: "\n \(captionString1) ", attributes: [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 12), NSAttributedString.Key.foregroundColor: UIColor.darkGray])

         
            locationNameLabelString.append(locationString)
            locationNameLabelString.append(captionString)
            
        
            self.locationNameFade.attributedText = locationNameLabelString

            
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
    
    var showDistance: Bool = false {
        didSet {
            locationDistanceLabel.isHidden = !showDistance
        }
    }
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
    
    var locationNameFade: PaddedUILabel = {
        let label = PaddedUILabel()
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        label.textColor = UIColor.darkLegitColor()
        label.font = UIFont(name: "Poppins-Bold", size: 14)
        label.layer.cornerRadius = 3
        label.layer.masksToBounds = true
        label.numberOfLines = 0
//        label.backgroundColor = UIColor(white: 0, alpha: 0.4)
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
    
    let ratingEmojiTestLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = UIColor.black
        label.isUserInteractionEnabled = true
        label.textAlignment = NSTextAlignment.right
        return label
    }()
    
//    let ratingEmojiLabel: UILabel = {
//        let label = UILabel()
//        label.text = ""
//        label.font = UIFont.boldSystemFont(ofSize: 14)
//        label.textColor = UIColor.black
//        label.isUserInteractionEnabled = true
//        label.textAlignment = NSTextAlignment.center
//        label.backgroundColor = UIColor.white.withAlphaComponent(0.8)
//        label.backgroundColor = UIColor.clear
//        label.layer.cornerRadius = 22/2
//        label.layer.masksToBounds = true
//        label.layer.borderWidth = 0
//        label.layer.borderColor = UIColor.ianLegitColor().cgColor
//
//        return label
//    }()
    
    let ratingEmojiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textColor = UIColor.black
        label.backgroundColor = UIColor.clear
        label.textAlignment = NSTextAlignment.center
        label.alpha = 1
//        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    var hideRatingEmoji: NSLayoutConstraint?

    
    var emojiArray = EmojiButtonArray(emojis: [], frame: CGRect(x: 0, y: 0, width: 0, height: 15))
    var emojiArrayWidth: NSLayoutConstraint?

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
    
    
    let locationDistanceLabel: LightPaddedUILabel = {
        let label = LightPaddedUILabel()
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.textColor = UIColor.ianBlackColor()
        label.textAlignment = NSTextAlignment.right
        label.layer.cornerRadius = 1
        label.layer.borderWidth = 0
        label.layer.masksToBounds = true
        label.backgroundColor = UIColor.ianWhiteColor().withAlphaComponent(0.8)
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
    
    let margin = 0 as CGFloat
    
    var pageControl : UIPageControl = UIPageControl()
//    var pageControlMini : UIPageControl = UIPageControl()

    lazy var pageControlMini: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        button.setImage(#imageLiteral(resourceName: "multiplePics").withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = UIColor.backgroundGrayColor()
        button.tintColor = UIColor.ianLegitColor()
//        button.tintColor = UIColor.ianWhiteColor()
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
        self.pageControl.isHidden = imageCount <= 1
        self.pageControl.alpha = 0.6

//        self.pageControlMini.isHidden = imageCount <= 1
        
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
    
    let locationNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Poppins-Bold", size: 12)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.left
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = false
        return label
    }()
    
    let likeCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Poppins-Bold", size: 10)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.right
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = false
        return label
    }()
    
    let likeCountButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 15))
//        let scaledImage = #imageLiteral(resourceName: "like_filled").withRenderingMode(.alwaysOriginal).resizeVI(newSize: CGSize(width: 10, height: 10))
        let scaledImage = #imageLiteral(resourceName: "heart").withRenderingMode(.alwaysOriginal).resizeVI(newSize: CGSize(width: 10, height: 10))

        button.setImage(scaledImage, for: .normal)
//        button.tintColor = UIColor.darkGray
        //        button.layer.cornerRadius = button.frame.width/2
//        button.layer.masksToBounds = true
        button.setTitle("", for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 10)
//        button.addTarget(self, action: #selector(openNotifications), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.borderColor = UIColor.gray.cgColor
        button.layer.borderWidth = 0
//        button.layer.cornerRadius = 30/2
        button.titleLabel?.textColor = UIColor.ianBlackColor()
        button.contentMode = .scaleAspectFill
        button.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        button.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        button.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        return button
    }()
    
    let infoView = UIView()


    override init(frame: CGRect) {
        super.init(frame:frame)
        self.backgroundColor = UIColor.white
        
        self.layer.backgroundColor = UIColor.clear.cgColor
        self.layer.shadowColor = UIColor.lightGray.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.layer.shadowRadius = 2.0
        self.layer.shadowOpacity = 0.5
        self.layer.masksToBounds = false
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: 14).cgPath
        
        let cellView = UIView()
        addSubview(cellView)
        cellView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        cellView.layer.cornerRadius = 14
        cellView.layer.masksToBounds = true
        
//            var likeImage = (self.post?.hasLiked)! ? #imageLiteral(resourceName: "like_filled").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "like_unfilled").withRenderingMode(.alwaysTemplate)

        
        // Photo Image
        cellView.addSubview(photoImageScrollView)
        photoImageScrollView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height - 15)
        photoImageScrollView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: margin, paddingLeft: margin, paddingBottom: margin, paddingRight: margin, width: 0, height: 0)
//        photoImageScrollView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
        photoImageScrollView.isPagingEnabled = true
        photoImageScrollView.delegate = self
        
        photoImageScrollView.contentSize.width = photoImageScrollView.frame.width - margin * 2
        photoImageScrollView.layer.cornerRadius = 1
        photoImageScrollView.layer.masksToBounds = true
        
        
        photoImageView.frame = CGRect(x: 0, y: 0, width: self.frame.width - margin * 2, height: self.frame.height - margin * 2)
        photoImageScrollView.addSubview(photoImageView)
        photoImageView.tag = 0
//        photoImageView.contentMode = .
        
        photoImageScrollView.layer.cornerRadius = 3
        photoImageScrollView.layer.masksToBounds = true
        photoImageScrollView.showsHorizontalScrollIndicator = false
        photoImageView.layer.cornerRadius = 3
        photoImageView.layer.masksToBounds = true
        
        
        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(GridPhotoCell.handlePictureTap))
        photoImageScrollView.addGestureRecognizer(TapGesture)
        photoImageScrollView.isUserInteractionEnabled = true
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(GridPhotoCell.handleLongPress(_:)))
        longPress.minimumPressDuration = 0.25
        longPress.delegate = self
        photoImageScrollView.addGestureRecognizer(longPress)
        

        
        cellView.addSubview(infoView)
        infoView.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: headerInfoHeight)
//        infoView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        infoView.backgroundColor = UIColor.white.withAlphaComponent(0.15)

        
        
        
        addSubview(ratingEmojiLabel)
        ratingEmojiLabel.anchor(top: nil, left: nil, bottom: nil, right: infoView.rightAnchor, paddingTop: 8, paddingLeft: 8, paddingBottom: 8, paddingRight: 5, width: 0, height: 25)
        ratingEmojiLabel.centerYAnchor.constraint(equalTo: infoView.centerYAnchor).isActive = true
        ratingEmojiLabel.layer.cornerRadius = 25/2
        ratingEmojiLabel.layer.masksToBounds = true
        ratingEmojiLabel.isUserInteractionEnabled = true
        ratingEmojiLabel.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        ratingEmojiLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapRatingEmoji)))

        
        hideRatingEmoji = ratingEmojiLabel.widthAnchor.constraint(equalToConstant: 25)
        hideRatingEmoji?.isActive = true

        
        
        
        addSubview(userProfileImageView)
        userProfileImageView.anchor(top: nil, left: infoView.leftAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 8, paddingBottom: 8, paddingRight: 5, width: 0, height: userProfileImageWidth)
        userProfileImageView.centerYAnchor.constraint(equalTo: infoView.centerYAnchor).isActive = true

        showUserProfileWidth = userProfileImageView.widthAnchor.constraint(equalToConstant: userProfileImageWidth)
        showUserProfileWidth?.isActive = true
        userProfileImageView.layer.cornerRadius = userProfileImageWidth/2
        userProfileImageView.layer.masksToBounds = true
        userProfileImageView.layer.borderColor = UIColor.darkGray.cgColor
        userProfileImageView.layer.borderWidth = 0
        userProfileImageView.alpha = 0.8
        showUserProfileImage = true
        userProfileImageView.isUserInteractionEnabled = true
        userProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleUserProfileImageTap)))

                

        
        
        // EMOJI ARRAY
        emojiArray.alignment = .right
        emojiArray.delegate = self
        emojiArray.emojiLimit = 4
        emojiArray.alpha = 0.7
        addSubview(emojiArray)
        //        emojiArray.anchor(top: nil, left: nil, bottom: nil, right: userProfileView.rightAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 0, height: 25)
        emojiArray.anchor(top: nil, left: nil, bottom: nil, right: ratingEmojiLabel.leftAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: emojiFontSize + 5)
        emojiArray.centerYAnchor.constraint(equalTo: infoView.centerYAnchor).isActive = true
//        emojiArrayWidth = emojiArray.widthAnchor.constraint(equalToConstant: 0)
        emojiArrayWidth = emojiArray.widthAnchor.constraint(lessThanOrEqualToConstant: 0)
        emojiArrayWidth?.isActive = true
        setupEmojis()
        
        ratingEmojiTestLabel.layer.cornerRadius = 25
        ratingEmojiTestLabel.layer.masksToBounds = true

        

        
        
        
        // IMAGE COUNT
//        addSubview(pageControl)
//        pageControl.anchor(top: nil, left: nil, bottom: infoView.topAnchor, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 5, paddingRight: 10, width: 0, height: 10)
//        pageControl.centerXAnchor.constraint(equalTo: photoImageScrollView.centerXAnchor).isActive = true
//
//
        addSubview(pageControl)
        pageControl.anchor(top: photoImageScrollView.topAnchor, left: photoImageScrollView.leftAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: -30, paddingBottom: 10, paddingRight: 10, width: 0, height: 10)
        pageControl.isHidden = false
        
        
//        addSubview(likeCountButton)
//        likeCountButton.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 15)
//        likeCountButton.centerYAnchor.constraint(equalTo: infoView.centerYAnchor).isActive = true


//        emojiArray.backgroundColor = UIColor.ianLegitColor()
//        addSubview(emojiLabel)
////        emojiLabel.anchor(top: nil, left: ratingEmojiLabel.rightAnchor, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 3, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
//        emojiLabel.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
//        emojiLabel.centerYAnchor.constraint(equalTo: infoView.centerYAnchor).isActive = true
//        emojiLabel.sizeToFit()

//        addSubview(ratingEmojiTestLabel)
//        ratingEmojiTestLabel.anchor(top: nil, left: emojiArray.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
//        ratingEmojiTestLabel.centerYAnchor.constraint(equalTo: infoView.centerYAnchor).isActive = true
//        ratingEmojiTestLabel.sizeToFit()

//        ratingEmojiTestLabel.back
        



        //emojiLabel.backgroundColor = UIColor.ianWhiteColor().withAlphaComponent(0.5)

    
    // LOCATION NAME
//        let locationNameView = UIView()
//        cellView.addSubview(locationNameView)
//        locationNameView.anchor(top: nil, left: leftAnchor, bottom: infoView.topAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 20)
//        locationNameView.backgroundColor = UIColor.white
//
//        locationNameView.addSubview(locationNameLabel)
//        locationNameLabel.anchor(top: nil, left: locationNameView.leftAnchor, bottom: nil, right: locationNameView.rightAnchor, paddingTop: 2  , paddingLeft: 10, paddingBottom: 2, paddingRight: 10, width: 0, height: 0)
//        locationNameLabel.centerYAnchor.constraint(equalTo: locationNameView.centerYAnchor).isActive = true
                
            

    

        
                
        addSubview(locationDistanceLabel)
        locationDistanceLabel.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 20)
//        locationDistanceLabel.backgroundColor = UIColor.ianWhiteColor().withAlphaComponent(0.8)
        locationDistanceLabel.layer.cornerRadius = 5
        locationDistanceLabel.layer.masksToBounds = true
//        locationDistanceLabel.centerYAnchor.constraint(equalTo: infoView.centerYAnchor).isActive = true


        addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top: photoImageScrollView.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 50, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

//        emojiDetailLabel.centerYAnchor.constraint(equalTo: photoImageScrollView.centerYAnchor).isActive = true
        emojiDetailLabel.centerXAnchor.constraint(equalTo: photoImageScrollView.centerXAnchor).isActive = true
        emojiDetailLabel.sizeToFit()
        emojiDetailLabel.alpha = 0

                
//        addSubview(userProfileImageView)
//        userProfileImageView.anchor(top: nil, left: nil, bottom: photoImageScrollView.bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 8, paddingRight: 8, width: 0, height: userProfileImageWidth)
////        userProfileImageView.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 8, paddingRight: 8, width: 0, height: userProfileImageWidth)
////        userProfileImageView.centerYAnchor.constraint(equalTo: infoView.centerYAnchor).isActive = true
//
//        showUserProfileWidth = userProfileImageView.widthAnchor.constraint(equalToConstant: userProfileImageWidth)
//        showUserProfileWidth?.isActive = true
//        userProfileImageView.layer.cornerRadius = userProfileImageWidth/2
//        userProfileImageView.layer.masksToBounds = true
//        userProfileImageView.layer.borderColor = UIColor.white.cgColor
//        userProfileImageView.layer.borderWidth = 0
//        userProfileImageView.alpha = 1
//        showUserProfileImage = true
//        userProfileImageView.isUserInteractionEnabled = true
//        userProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleUserProfileImageTap)))
//
        

        
//        addSubview(rankLabel)
//        rankLabel.anchor(top: photoImageScrollView.topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)



        
        addSubview(socialCount)
        socialCount.anchor(top: nil, left: nil, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 2, paddingRight: 2, width: 0, height: 15)
        socialCount.alpha = 0
        
        addSubview(locationNameFade)
        locationNameFade.anchor(top: locationDistanceLabel.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 15, paddingBottom: 10, paddingRight: 15, width: 0, height: 0)
        locationNameFade.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor).isActive = true
        locationNameFade.alpha = 0

        
        
//        addSubview(emojiLabel)
////        emojiLabel.anchor(top: nil, left: ratingEmojiLabel.rightAnchor, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 3, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
//        emojiLabel.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
//
//        //emojiLabel.backgroundColor = UIColor.ianWhiteColor().withAlphaComponent(0.5)
//        emojiLabel.sizeToFit()
        
//        addSubview(ratingEmojiLabel)
//        ratingEmojiLabel.anchor(top: nil, left: nil, bottom: photoImageScrollView.bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 8, paddingBottom: 5, paddingRight: 8, width: 0, height: 25)
//        ratingEmojiWidth = ratingEmojiLabel.widthAnchor.constraint(equalToConstant: 0)
//        ratingEmojiWidth?.isActive = true


        // IMAGE COUNT
//        addSubview(pageControlMini)
//        pageControlMini.anchor(top: nil, left: nil, bottom: photoImageScrollView.bottomAnchor, right: rightAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 20, height: 20)



        addSubview(cancelPostButton)
        cancelPostButton.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 30, height: 30)
        cancelPostButton.isHidden = true
        
        addSubview(photoCheckMark)
        photoCheckMark.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 25, height: 25)
        photoCheckMark.isHidden = true
        
        

        
        
    }
    
    @objc func didTapRatingEmoji() {
        guard let emoji = self.post?.ratingEmoji else {return}
        self.didTapEmoji(index: 0, emoji: emoji)
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
        self.pageControl.isHidden = false
        
        if self.pageControl.currentPage > 0 {
            self.pageControl.alpha = 1
//            self.pageControl.isHidden = false
//            self.pageControlMini.isHidden = !self.pageControl.isHidden
//            self.pageControlMini.currentPage = (self.pageControl.currentPage > 0) ? 1 : 0
        } else {
        // FADE OUT PAGE CONTROL
            let animationDuration = 2.0
            UIView.animate(withDuration: animationDuration, animations: { () -> Void in
                self.pageControl.alpha = 0.6
//                self.pageControl.isHidden = true
//                self.pageControlMini.isHidden = !self.pageControl.isHidden
//                self.pageControlMini.currentPage = (self.pageControl.currentPage > 0) ? 1 : 0
            }) { (Bool) -> Void in
            }
        }
//        self.pageControlMini.currentPage = !self.pageControl.isHidden ? 0 : 1
        print(self.currentImage, self.pageControl.currentPage)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.hideEmojiDetailLabel()
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
    
    @objc func handleUserProfileImageTap() {
        if let post = post {
            print("Tap Picture")
            delegate?.didTapUser(post: post)
        }
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
//                    self.socialCount.alpha = 1
                    self.locationNameFade.alpha = 1
                }) { (Bool) -> Void in
                }
            }
            else if gestureReconizer.state != UIGestureRecognizer.State.changed {
                // Fade Out Social Counts when released
                UIView.animate(withDuration: animationDuration, animations: { () -> Void in
//                    self.socialCount.alpha = 0
                    self.locationNameFade.alpha = 0
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
        setupEmojis()
        
    }
    
    
    func didTapEmoji(index: Int?, emoji: String) {
        guard let index = index else {
            print("No Index For emoji \(emoji)")
            return
        }
//        guard let displayEmoji = self.post?.nonRatingEmoji[index] else {return}
//        guard let  displayEmojiTag = self.post?.nonRatingEmojiTags[index] else {return}
        //        self.delegate?.displaySelectedEmoji(emoji: displayEmoji, emojitag: displayEmojiTag)
        
//        guard let displayEmoji = emoji else {return}
//        guard let  displayEmojiTag = self.post?.nonRatingEmojiTags[index] else {return}
        
        var refString = "\(emoji)"
        
        if let refText = EmojiDictionary[emoji]?.capitalizingFirstLetter() {
            refString += "  \(String(refText))"
        }

        
        
        print("Selected Emoji \(index) | \(emoji) | \(refString)")
        
        
        
        
        var captionDelay = 3
        emojiDetailLabel.text = refString
        emojiDetailLabel.alpha = 1
        emojiDetailLabel.sizeToFit()
        
        UIView.animate(withDuration: 0.5, delay: TimeInterval(captionDelay), options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.hideEmojiDetailLabel()
        }, completion: { (finished: Bool) in
        })
    }
    
    func doubleTapEmoji(index: Int?, emoji: String) {
        
    }
    
    
    func hideEmojiDetailLabel(){
        self.emojiDetailLabel.alpha = 0
    }
    
    func setupEmojis(){
        emojiArray.lockEmojiWidthToFrame = false
        emojiArray.emojiLimit = 4
        emojiArray.emojiFontSize = emojiFontSize
        //        print("REFRESH EMOJI ARRAYS")
        var tempEmojis: [String] = Array(self.post?.nonRatingEmoji.prefix(3) ?? [])
        if let rating = self.post?.ratingEmoji {
//             tempEmojis.append(rating)
        }
        
//        emojiArray = EmojiButtonArray(emojis: tempEmojis, frame: CGRect(x: 0, y: 0, width: 0, height: emojiFontSize))
        emojiArray.emojiLabels = tempEmojis

//        if let displayEmojis = self.post?.nonRatingEmoji{
//            emojiArray.emojiLabels = displayEmojis
//        } else {
//            emojiArray.emojiLabels = []
//        }
        emojiArrayWidth?.constant = CGFloat((self.post?.nonRatingEmoji.count ?? 0) * 30) + 10
        emojiArrayWidth?.isActive = false
        
        emojiArray.lockEmojiWidthToFrame = true

        //        print("UPDATED EMOJI ARRAY: \(emojiArray.emojiLabels)")
        emojiArray.setEmojiButtons()
        emojiArray.sizeToFit()
//        emojiArray.sizeToFit()
        //        print("REFRESH EMOJI ARRAYS - setEmojiButtons")
//
//        self.ratingEmojiLabel.text = self.post?.ratingEmoji ?? ""
//        self.ratingEmojiLabel.sizeToFit()
        
        var tempRatingEmoji = post?.ratingEmoji ?? ""
        var tempEmojisCur = (post?.emoji ?? "")
        var emojiText = tempRatingEmoji + tempEmojisCur.replacingOccurrences(of: tempRatingEmoji, with: "")
        emojiLabel.text = emojiText

        var tempText = tempEmojisCur + " " + (tempRatingEmoji)
        
        let emojiTitle = NSAttributedString(string: tempText, attributes: [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont(font: .avenirNextBold, size: 25)])
        emojiLabel.attributedText = emojiTitle
        emojiLabel.sizeToFit()
        
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
