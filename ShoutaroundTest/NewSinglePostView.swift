//
//  NewSinglePostView.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/21/20.
//  Copyright © 2020 Wei Zou Ang. All rights reserved.
//

import UIKit
import mailgun

import Cosmos
import GeoFire
import CoreGraphics
import CoreLocation
import DropDown
import MessageUI
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import AudioToolbox
import SwiftyJSON



class NewSinglePostView: UIViewController {
    var delegate: SinglePostViewDelegate?

    var post: Post? {
        didSet {
            var creatorName = ""
            if let cache = userCache[post?.creatorUID ?? ""] {
                creatorName = cache.username
            } else {
                creatorName = post?.creatorUID ?? ""
            }
            print(" ~~~ NewSinglePostView | LOAD POST | ID: \((post?.id)!) | LOC: \((post?.locationName)!) | USER: \(creatorName)")

            guard let imageUrls = post?.imageUrls else {
                print("Read Post, No Image URLs Error")
                return}
            
            setupPostLikes()
            setupAttributedLocationName()
            setupPicturesScroll()
            setupUser()
            setupRatingLegitIcon()
            setupTaggedList()
//            setupEmojis()
            setupPostDetails()
            bottomActionBar.post = post
            scrollview.contentSize = scrollview.intrinsicContentSize
            updateLocationView()
            setupNavigationItems()
            setupImageCountLabel()
            updateLinkLabel()
            self.view.layoutIfNeeded()
            print("***\(post?.id) POST | New Single Picture Controller ")
//            print("ScrollView Size | Content \(self.scrollview.contentSize) | Intrinsic \(scrollview.intrinsicContentSize)")
        }
    }
    
    var currentImage = 1
    
    let scrollview: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = UIColor.white
        sv.isScrollEnabled = true
        sv.showsVerticalScrollIndicator = false
        return sv
    }()
    
// NAV BUTTONS
    lazy var navBackButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        let icon = #imageLiteral(resourceName: "back_icon").withRenderingMode(.alwaysTemplate)
        button.setImage(icon, for: .normal)
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.borderColor = UIColor.ianLegitColor().cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 2
        button.clipsToBounds = true
        button.contentHorizontalAlignment = .center
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        button.tintColor = UIColor.ianBlackColor()
        button.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
        return button
    }()
    
    
    lazy var navShareButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//        let icon = #imageLiteral(resourceName: "share").withRenderingMode(.alwaysTemplate)
        let icon = #imageLiteral(resourceName: "message_fill").withRenderingMode(.alwaysTemplate)

        button.setImage(icon, for: .normal)
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.borderColor = UIColor.ianLegitColor().cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 2
        button.clipsToBounds = true
        button.contentHorizontalAlignment = .center
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        button.tintColor = UIColor.ianBlackColor()
        button.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 8)
        return button
    }()
    
// IMAGE
    let photoImageScrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.backgroundColor = .white
        scroll.showsHorizontalScrollIndicator = false
        return scroll
    }()
    
    var originalImageCenter:CGPoint?
    var isZooming = false
    var popView = UIView()

    
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
        label.backgroundColor = UIColor.clear
        label.layer.cornerRadius = 5
        label.layer.borderWidth = 0
        label.layer.masksToBounds = true
        label.alpha = 1
        return label
    }()
    
    
    func setupImageCountLabel(){
        let imageCount = (self.post?.imageCount) ?? 1
        
        if imageCount == 1 {
            photoCountLabel.isHidden = true
        } else {
            photoCountLabel.isHidden = false
        }
        
        if imageCount > 1 {
            self.photoCountLabel.text = "\(currentImage)/\(imageCount)"
        } else {
            self.photoCountLabel.text = ""
        }
        photoCountLabel.sizeToFit()
        photoCountLabel.reloadInputViews()
    }
    
    
// LIKE STATS
    var postLikedLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(font: .appleSDGothicNeoBold, size: 13)
        label.textColor = UIColor.ianBlackColor()
        label.textAlignment = NSTextAlignment.left
//        label.isUserInteractionEnabled = true
//        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showLikes)))
        return label
    }()
    
    var postLikedLabelHide: NSLayoutConstraint?
    
    @objc func showLikes() {
        guard let post = post else {return}
        self.extShowUsersForPost(post: post, following: true)
    }
    
    
// CAPTION
    var captionView: UIView = {
        let view = UIView()
        //        view.layer.backgroundColor = UIColor.lightGray.cgColor.copy(alpha: 0.5)
        view.layer.backgroundColor = UIColor.white.cgColor.copy(alpha: 0.5)
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    var captionDisplayed: Bool = false
    
    let captionBubble: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 30)
        label.textAlignment = NSTextAlignment.center
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    var captionViewHeightConstraint: NSLayoutConstraint? = nil

    let userProfileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 2
        return iv
    }()
    var profileImageSize: CGFloat = 35

    var ratingEmojiLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:25)
        label.textColor = UIColor.lightLegitColor()
        label.textAlignment = NSTextAlignment.center
        label.isUserInteractionEnabled = true
        label.backgroundColor = UIColor.clear
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        return label
    }()
    
    var hideRatingEmojiConstraint: NSLayoutConstraint? = nil
    
    func displayExtraRatingInfo(){
        self.didTapRatingEmoji()
//        self.extDisplayExtraRatingInfo()
    }
    
    let locationNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Poppins-Bold", size: 16)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.left
        label.lineBreakMode = .byWordWrapping
        label.lineBreakMode = .byClipping
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.baselineAdjustment = .alignCenters
        return label
    }()
    
        
    let locationCityLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(font: .avenirNextRegular, size: 16)
        label.textColor = UIColor.lightGray
        label.textAlignment = NSTextAlignment.right
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    var locationCityViewHeight: NSLayoutConstraint? = nil
    
    let starRating: CosmosView = {
        let iv = CosmosView()
        iv.settings.fillMode = .half
        iv.settings.totalStars = 5
        //        iv.settings.starSize = 30
        iv.settings.starSize = 25
        iv.settings.updateOnTouch = false
//        iv.settings.filledImage = #imageLiteral(resourceName: "star_rating_filled_mid").withRenderingMode(.alwaysOriginal)
//        iv.settings.emptyImage = #imageLiteral(resourceName: "star_rating_unfilled").withRenderingMode(.alwaysOriginal)
        iv.settings.filledImage = #imageLiteral(resourceName: "new_star").withRenderingMode(.alwaysTemplate)
        iv.settings.emptyImage = #imageLiteral(resourceName: "new_star_gray").withRenderingMode(.alwaysTemplate)
//        iv.settings.emptyImage = #imageLiteral(resourceName: "new_star_black").withRenderingMode(.alwaysTemplate)
        iv.rating = 0
        iv.settings.starMargin = 1
        return iv
    }()

    var pageControl : UIPageControl = UIPageControl()
    func setupPageControl(){
        self.pageControl.numberOfPages = (self.post?.imageCount)!
        self.pageControl.currentPage = 0
        self.pageControl.tintColor = UIColor.red
        self.pageControl.pageIndicatorTintColor = UIColor.white
        self.pageControl.currentPageIndicatorTintColor = UIColor.ianLegitColor()
        self.pageControl.isHidden = self.pageControl.numberOfPages == 1
//        self.pageControl.backgroundColor = UIColor.rgb(red: 68, green: 68, blue: 68)
    }
    
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


    let captionTextView: UILabel = {
        let tv = UILabel()
        tv.numberOfLines = 0
//        tv.isScrollEnabled = false
//        tv.textContainer.maximumNumberOfLines = 0
//        tv.textContainerInset = UIEdgeInsets.zero
//        tv.textContainer.lineBreakMode = .byTruncatingTail
//        tv.translatesAutoresizingMaskIntoConstraints = false
//        tv.isEditable = false
        return tv
    }()
    
    let commentLabel: UILabel = {
        let tv = UILabel()
        tv.numberOfLines = 0
        tv.font = UIFont.systemFont(ofSize: 13)
        tv.textColor = UIColor.darkGray
        return tv
    }()
    var hideComment: NSLayoutConstraint?
    
    
    //  DATE
    
    let postDateLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.gray
        label.numberOfLines = 0
        return label
    }()
    
    //   OPTIONS
    
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
        self.userOptionPost(post: post)
    }
    
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
    
    
    let locationViewController = LocationSummaryView()

    let taggedListTopDiv = UIView()
    let taggedListBottomDiv = UIView()
    let taggedListContainer = UIView()
    var taggedListView = ListSummaryView()
    var taggedListHeightConstraint: NSLayoutConstraint? = nil

// BOTTOM EMOJI BAR
    let bottomActionBar = BottomActionBar()
    let userHeaderView = UserHeaderView()
    
    
// PRICE
    let priceLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ianLightGrayColor()
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textAlignment = NSTextAlignment.right
        return label
    }()
    
    var defaultEmojiArray = EmojiButtonArray(emojis: [], frame: CGRect(x: 0, y: 0, width: 0, height: 15))

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
    
    
    var headerView = UIView()
    let headerLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Poppins-Bold", size: 16)
        label.textColor = UIColor.ianBlackColor()
        label.textAlignment = NSTextAlignment.center
        label.lineBreakMode = .byWordWrapping
        label.lineBreakMode = .byClipping
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.baselineAdjustment = .alignCenters
        return label
    }()
    
    func setupHeaderView() {
        setupUser()
        setupRatingLegitIcon()

        var headerText = " "

        headerText += post?.user.username ?? ""
//        if let ratingEmoji = (post?.ratingEmoji) {
//            headerText += " \(ratingEmoji)"
//        }social
                
        
        headerLabel.text = headerText

    }
    
    // MARK: VIEW DID LOAD
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        
        // Setup Navigation Look

        
        
        // USER PROFILE
            headerView.addSubview(userProfileImageView)
        userProfileImageView.anchor(top: headerView.topAnchor, left: headerView.leftAnchor, bottom: headerView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 3, paddingBottom: 0, paddingRight: 10, width: profileImageSize, height: profileImageSize)
//            userProfileImageView.centerYAnchor.constraint(equalTo: locationView.centerYAnchor).isActive = true
            userProfileImageView.layer.cornerRadius = profileImageSize/2
            userProfileImageView.layer.borderWidth = 0
            userProfileImageView.layer.borderColor = UIColor.white.cgColor
            userProfileImageView.isUserInteractionEnabled = true
            userProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(usernameTap)))

        headerView.addSubview(headerLabel)
        headerLabel.anchor(top: nil, left: userProfileImageView.rightAnchor, bottom: nil, right: headerView.rightAnchor, paddingTop: 0, paddingLeft: 3, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        headerLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        headerLabel.isUserInteractionEnabled = true
        headerLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(usernameTap)))

        
        setupNavigationItems()
//
//        view.addSubview(bottomActionBar)
//        bottomActionBar.anchor(top: nil, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 45)
//        bottomActionBar.delegate = self
        
        scrollview.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height - 40)
        scrollview.contentSize = CGSize(width: view.frame.width, height: view.frame.height + 400)
        view.addSubview(scrollview)
        scrollview.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        scrollview.contentInsetAdjustmentBehavior = .never
        scrollview.backgroundColor = UIColor.ianWhiteColor()
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleBackPressNav))
        swipeRight.direction = .right
        self.scrollview.addGestureRecognizer(swipeRight)

                
                
    // HEADER VIEW
        let headerView = UIView()
        scrollview.addSubview(headerView)
        headerView.anchor(top: scrollview.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)


    // LOCATION
        let locationView = UIView()
        headerView.addSubview(locationView)
        locationView.anchor(top: headerView.topAnchor, left: headerView.leftAnchor, bottom: headerView.bottomAnchor, right: headerView.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)


    // USER PROFILE
//        locationView.addSubview(userProfileImageView)
//        userProfileImageView.anchor(top: nil, left: nil, bottom: nil, right: locationView.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: profileImageSize, height: profileImageSize)
//        userProfileImageView.centerYAnchor.constraint(equalTo: locationView.centerYAnchor).isActive = true
//        userProfileImageView.layer.cornerRadius = profileImageSize/2
//        userProfileImageView.layer.borderWidth = 2
//        userProfileImageView.layer.borderColor = UIColor.white.cgColor
//        userProfileImageView.isUserInteractionEnabled = true
//        userProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(usernameTap)))
    
        
        
                



    // LOCATIONN NAME
        locationView.addSubview(locationNameLabel)
        locationNameLabel.anchor(top: locationView.topAnchor, left: locationView.leftAnchor, bottom: locationView.bottomAnchor, right: locationView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        locationNameLabel.isUserInteractionEnabled = true
        locationNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapLocation)))



    
        
    // IMAGE SCROLL VIEW
        scrollview.addSubview(photoImageScrollView)
        photoImageScrollView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.width)
        photoImageScrollView.anchor(top: headerView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        photoImageScrollView.heightAnchor.constraint(equalTo: photoImageScrollView.widthAnchor, multiplier: 1).isActive = true
        photoImageScrollView.isPagingEnabled = true
        photoImageScrollView.delegate = self
        setupPhotoImageScrollView()
        


        
        
    // PAGE CONTROL
        let pageControlView = UIView()
        scrollview.addSubview(pageControlView)
        pageControlView.anchor(top: nil, left: view.leftAnchor, bottom: photoImageScrollView.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 0, height: 15)
        scrollview.addSubview(pageControl)
        pageControl.anchor(top: nil, left: nil, bottom: pageControlView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 10)
        pageControl.centerXAnchor.constraint(equalTo: pageControlView.centerXAnchor).isActive = true
        setupPageControl()

    
    // EMOJI DETAIL
        scrollview.addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top: nil, left: nil, bottom: pageControl.topAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 15, paddingRight: 0, width: 0, height: 0)
        emojiDetailLabel.sizeToFit()
        emojiDetailLabel.centerXAnchor.constraint(equalTo: photoImageScrollView.centerXAnchor).isActive = true
        emojiDetailLabel.alpha = 0

        // LOCATION DISTANCE
            scrollview.addSubview(locationDistanceLabel)
        locationDistanceLabel.anchor(top: nil, left: photoImageScrollView.leftAnchor, bottom: photoImageScrollView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)
//            locationDistanceLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
            locationDistanceLabel.isUserInteractionEnabled = true
            locationDistanceLabel.sizeToFit()
            
                    
                    
        
        
// ACTION BAR
        
        scrollview.addSubview(bottomActionBar)
        bottomActionBar.anchor(top: photoImageScrollView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        bottomActionBar.delegate = self
        bottomActionBar.backgroundColor = UIColor.white
        

        
        

// RATING VIEW
    // STAR RATING
        let detailView = UIView()
        scrollview.addSubview(detailView)
        detailView.anchor(top: bottomActionBar.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        

//        detailView.addSubview(userProfileImageView)
//        userProfileImageView.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: profileImageSize, height: profileImageSize)
//        userProfileImageView.centerYAnchor.constraint(equalTo: detailView.centerYAnchor).isActive = true
//        userProfileImageView.layer.cornerRadius = profileImageSize/2
//        userProfileImageView.layer.borderWidth = 2
//        userProfileImageView.layer.borderColor = UIColor.white.cgColor
//        userProfileImageView.isUserInteractionEnabled = true
//        userProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(usernameTap)))
        
        
        

        emojiArray.isHidden = false
        emojiArray.alignment = .left
        emojiArray.delegate = self
        emojiArray.heightAnchor.constraint(equalToConstant: 30).isActive = true
        detailView.addSubview(emojiArray)
        emojiArray.anchor(top: nil, left: detailView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        emojiArray.centerYAnchor.constraint(equalTo: detailView.centerYAnchor).isActive = true
        setupEmojis()

        
        detailView.addSubview(starRating)
        starRating.anchor(top: nil, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        starRating.centerYAnchor.constraint(equalTo: detailView.centerYAnchor).isActive = true


        detailView.addSubview(ratingEmojiLabel)
        ratingEmojiLabel.anchor(top: nil, left: nil, bottom: nil, right: starRating.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 3, width: 0, height: 30)
        ratingEmojiLabel.centerYAnchor.constraint(equalTo: detailView.centerYAnchor).isActive = true
//        ratingEmojiLabel.layer.cornerRadius = 30/2
//        ratingEmojiLabel.layer.masksToBounds = true
        ratingEmojiLabel.isUserInteractionEnabled = true
        ratingEmojiLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayExtraRatingInfo)))
        ratingEmojiLabel.backgroundColor = UIColor.clear

        hideRatingEmojiConstraint = ratingEmojiLabel.widthAnchor.constraint(equalToConstant: 0)
        hideRatingEmojiConstraint?.isActive = true

        setupRatingLegitIcon()
                
                        
        
        
//        detailView.addSubview(photoCountLabel)
//        photoCountLabel.anchor(top: nil, left: nil, bottom: nil, right: detailView.rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 10, paddingRight: 10, width: 0, height: 0)
//        photoCountLabel.centerYAnchor.constraint(equalTo: detailView.centerYAnchor).isActive = true
        


        
    // IMAGE COUNT
//        detailView.addSubview(pageControl)
//        pageControl.anchor(top: nil, left: nil, bottom: nil, right: detailView.rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 10, paddingRight: 10, width: 0, height: 5)
//        pageControl.centerYAnchor.constraint(equalTo: detailView.centerYAnchor).isActive = true
//        setupPageControl()

                
                        
    // LIKE STATS
            scrollview.addSubview(postLikedLabel)
            postLikedLabel.anchor(top: detailView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 2, paddingLeft: 10, paddingBottom: 2, paddingRight: 10, width: 0, height: 0)
            postLikedLabelHide = postLikedLabel.heightAnchor.constraint(equalToConstant: 0)
            postLikedLabel.backgroundColor = UIColor.clear
            postLikedLabel.isUserInteractionEnabled = true
            postLikedLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showLikes)))
            
        
    // CAPTION

        scrollview.addSubview(captionTextView)
        captionTextView.anchor(top: postLikedLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 8, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        captionTextView.backgroundColor = UIColor.clear
        captionTextView.sizeToFit()
        captionTextView.isUserInteractionEnabled = true
        let textViewTap = UITapGestureRecognizer(target: self, action: #selector(handleComment))

        textViewTap.delegate = self
        captionTextView.addGestureRecognizer(textViewTap)
        
    // LINK
        scrollview.addSubview(linkLabel)
        linkLabel.anchor(top: captionTextView.bottomAnchor, left: captionTextView.leftAnchor, bottom: nil, right: captionTextView.rightAnchor, paddingTop: 4, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        linkLabel.isUserInteractionEnabled = true
        linkLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(activateBrowser)))
        updateLinkLabel()
        
    // COMMENTS
        scrollview.addSubview(commentLabel)
        commentLabel.anchor(top: linkLabel.bottomAnchor, left: captionTextView.leftAnchor, bottom: nil, right: captionTextView.rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        commentLabel.isUserInteractionEnabled = true
        commentLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleComment)))
        
        hideComment = commentLabel.heightAnchor.constraint(equalToConstant: 0)
        
        
    // ADDITIONAL POST DETAILS - DATE, CITY, DEFAULT EMOJI TAGS
        let postAddDetailView = UIView()
        scrollview.addSubview(postAddDetailView)
        postAddDetailView.anchor(top: commentLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 25)
        
        postAddDetailView.addSubview(postDateLabel)
        postDateLabel.anchor(top: postAddDetailView.topAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 0, width: 0, height: 15)
        postDateLabel.sizeToFit()
        
        
        postAddDetailView.addSubview(defaultEmojiArray)
        defaultEmojiArray.anchor(top: postAddDetailView.topAnchor, left: postDateLabel.rightAnchor, bottom: postAddDetailView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 4, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        defaultEmojiArray.centerYAnchor.constraint(equalTo: postAddDetailView.centerYAnchor).isActive = true
        defaultEmojiArray.alignment = .left
        defaultEmojiArray.delegate = self
        defaultEmojiArray.alpha = 0.5
        setupEmojis()

        postAddDetailView.addSubview(priceLabel)
        priceLabel.anchor(top: nil, left: defaultEmojiArray.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        priceLabel.centerYAnchor.constraint(equalTo: postAddDetailView.centerYAnchor).isActive = true

        postAddDetailView.addSubview(optionsButton)
        optionsButton.anchor(top: nil, left: nil, bottom: nil, right: postAddDetailView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 40, height: 20)
        optionsButton.centerYAnchor.constraint(equalTo: postAddDetailView.centerYAnchor).isActive = true
        optionsButton.isHidden = true
        


//        locationDistanceLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(activateMap)))
        
//        postAddDetailView.addSubview(optionsButton)
//        optionsButton.anchor(top: postDateLabel.topAnchor, left: nil, bottom: nil, right: postAddDetailView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 40, height: 15)
//        //        optionsButton.widthAnchor.constraint(equalTo: optionsButton.heightAnchor).isActive = true
//        optionsButton.centerYAnchor.constraint(equalTo: postDateLabel.centerYAnchor).isActive = true
//        optionsButton.isHidden = true

            
        // TAGGED LIST DIV
            scrollview.addSubview(taggedListTopDiv)
            taggedListTopDiv.anchor(top: postAddDetailView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 3)
            taggedListTopDiv.backgroundColor = UIColor.ianLegitColor()
            
            
        // TAGGED LIST CONTAINER
            scrollview.addSubview(taggedListContainer)
            taggedListContainer.anchor(top: taggedListTopDiv.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            
            
            
            setupTaggedList()
            taggedListContainer.addSubview(taggedListView)
            taggedListView.anchor(top: taggedListContainer.topAnchor, left: taggedListContainer.leftAnchor, bottom: taggedListContainer.bottomAnchor, right: taggedListContainer.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 0, height: 0)
            taggedListHeightConstraint = taggedListView.heightAnchor.constraint(equalToConstant: 0)
            taggedListContainer.backgroundColor = UIColor.backgroundGrayColor()
            taggedListView.backgroundColor = UIColor.backgroundGrayColor()
        
        // TAGGED LIST DIV
            scrollview.addSubview(taggedListBottomDiv)
            taggedListBottomDiv.anchor(top: taggedListContainer.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 3)
            taggedListBottomDiv.backgroundColor = UIColor.ianLegitColor()
        

        
    // LOCATION VIEW
        locationViewController.showSelectedPostPicture = false
        locationViewController.selectedPost = self.post
        locationViewController.delegate = self
        scrollview.addSubview(locationViewController)
        locationViewController.anchor(top: taggedListBottomDiv.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        locationViewController.sizeToFit()
//        locationViewController.view.sizeToFit()
//        locationContainerHeight = locationViewController.view.heightAnchor.constraint(equalToConstant: self.view.frame.height)
//        locationContainerHeight?.isActive = true
        



        
        self.view.bringSubviewToFront(photoImageScrollView)
        self.view.bringSubviewToFront(photoImageView)


    }
    
    func updateLinkLabel() {
        self.linkLabel.text = self.post?.urlLink
        self.linkLabel.sizeToFit()
        self.linkLabel.isHidden = self.post?.urlLink?.isEmptyOrWhitespace() ?? true
    }
    
    func updateLocationView(){
        locationViewController.selectedPost = self.post
        locationViewController.sizeToFit()
        view.layoutIfNeeded()
    }
    
    
//        override var preferredStatusBarStyle: UIStatusBarStyle {
//            return .lightContent
//        }
        
    override func viewWillDisappear(_ animated: Bool) {
        navigationItem.titleView = nil
        emojiArray.isHidden = false
        navigationController?.navigationBar.layer.shadowColor = UIColor.clear.cgColor

    }
    
        override func viewDidAppear(_ animated: Bool) {
            setupNavigationItems()
        }
    
        override func viewWillLayoutSubviews() {
            super.viewWillLayoutSubviews()
            var contentRect = CGRect.zero
            for view: UIView in scrollview.subviews {
                contentRect = contentRect.union(view.frame)
            }
            contentRect.size.width = self.view.frame.width
            contentRect.size.height = contentRect.size.height
            contentRect.size.height = 1600

            scrollview.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height - 40)
            scrollview.contentSize = contentRect.size
//            print("viewWillLayoutSubviews | \(scrollview.frame) Frame | \(scrollview.contentSize) Content")
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
//            var contentRect = CGRect.zero
//            for view: UIView in scrollview.subviews {
//                contentRect = contentRect.union(view.frame)
//            }
//            contentRect.size.width = self.view.frame.width
//            contentRect.size.height = contentRect.size.height
//
//            scrollview.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height - 40)
//            scrollview.contentSize = contentRect.size
//            print("viewDidLayoutSubviews | \(scrollview.frame) Frame | \(scrollview.contentSize) Content")
        }
        
        override func viewWillAppear(_ animated: Bool) {
            setupNavigationItems()
        }
    
    
    
    
    func setupTaggedList() {
        taggedListView.refreshAll()
        taggedListView.post = self.post
        taggedListView.delegate = self
        taggedListView.sortListByDate = true
        taggedListView.listHeaderLabel.font = UIFont(name: "Poppins-Bold", size: 20)
        taggedListView.listHeaderLabel.font = UIFont(name: "Poppins-Regular", size: 20)
        taggedListView.listHeaderLabel.font = UIFont(font: .avenirNextBold, size: 18)
        taggedListHeightConstraint?.isActive = (post?.allList.count == 0)
        taggedListContainer.isHidden = (post?.creatorListId?.count == 0)
        taggedListTopDiv.isHidden = (post?.creatorListId?.count == 0)
    }
    
        
    func setupNavigationItems(){
        let tempImage = UIImage.init(color: UIColor.backgroundGrayColor())
        navigationController?.navigationBar.setBackgroundImage(tempImage, for: .default)
        navigationController?.view.backgroundColor = UIColor.backgroundGrayColor()
        navigationController?.isNavigationBarHidden = false
        
        navigationController?.navigationBar.barTintColor = UIColor.ianWhiteColor()
        navigationController?.navigationBar.tintColor = UIColor.ianLegitColor()
        navigationController?.navigationBar.isTranslucent = false

        // REMOVES THE 1PX BOTTOM LINE IN NAV BAR
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
        
        self.navigationController?.navigationBar.layer.shadowColor = UIColor.gray.cgColor
        self.navigationController?.navigationBar.layer.shadowOffset = CGSize(width: 0.0, height: 1)
        self.navigationController?.navigationBar.layer.shadowRadius = 1.0
        self.navigationController?.navigationBar.layer.shadowOpacity = 0.5
        self.navigationController?.navigationBar.layer.masksToBounds = false
        
        navShareButton.addTarget(self, action: #selector(showMessagingOptionsNav), for: .touchUpInside)
        navBackButton.addTarget(self, action: #selector(handleBackPressNav), for: .touchUpInside)
        navShareButton.setTitle(" Share", for: .normal)
        navShareButton.setTitleColor(UIColor.gray, for: .normal)
        
        let shareBarButton = UIBarButtonItem.init(customView: navShareButton)
        let backBarButton = UIBarButtonItem.init(customView: navBackButton)

        self.navigationItem.rightBarButtonItem = shareBarButton
        self.navigationItem.leftBarButtonItem = backBarButton
        
//        userHeaderView.user = post?.user
//        setupEmojis()
//        emojiArray.isHidden = false
//        emojiArray.alignment = .right
//        emojiArray.delegate = self
//        emojiArray.heightAnchor.constraint(equalToConstant: 30).isActive = true
//        emojiArray.heightAnchor.constraint(lessThanOrEqualToConstant: 30).isActive = true
        //        navigationController?.navigationBar.topItem?.titleView = emojiArray

//        setupRatingLegitIcon()
//        navigationItem.titleView = ratingEmojiLabel
        
        setupHeaderView()
        navigationItem.titleView = headerView

    }
    
    func setupCaptionBubble(){
        
        scrollview.addSubview(captionView)
        captionView.anchor(top: nil, left: view.leftAnchor, bottom: photoImageScrollView.bottomAnchor, right: view.rightAnchor, paddingTop: 30, paddingLeft: 50, paddingBottom: 40, paddingRight: 50, width: 0, height: 0)
        captionView.bottomAnchor.constraint(lessThanOrEqualTo: photoImageScrollView.bottomAnchor).isActive = true
        
        scrollview.addSubview(captionBubble)
        captionBubble.anchor(top: captionView.topAnchor, left: captionView.leftAnchor, bottom: captionView.bottomAnchor, right: captionView.rightAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 0, height: 0)
        captionBubble.contentMode = .center
    
        // Hide initial caption bubbles
        hideCaptionBubble()
        //        testMapButton.alpha = 1
        
    }
    
    func hideCaptionBubble(){
        self.captionView.alpha = 0
        self.captionBubble.alpha = 0
    }
    
    func showCaptionBubble(){
        self.captionView.alpha = 1
        self.captionBubble.alpha = 1
    }
    
    
    // MARK: - Navigation


    @objc func handleBackPressNav(){
        guard let post = self.post else {return}
        self.handleBack()
    }
    
    @objc func showMessagingOptionsNav(){
        guard let post = self.post else {return}
        
        self.handleMessage(post: post)
    
//        self.showMessagingOptions(post: post)
    }
    
    
    
    // MARK: - POST SETUP

    func setupPostLikes(){
        var totalLikes = post?.likeCount ?? 0
        var totalFriendLikes = post?.followingVote.count ?? 0
        var selfLike = post?.hasLiked ?? false
        var likeString = ""
        if (totalFriendLikes + (selfLike ? 1 : 0)) > 0 {
            likeString = "Legit by"
            if selfLike {
                likeString += " You"
            }
            
            if post?.followingVote.count ?? 0 > 0 {
                if let uid = post?.followingVote[0] {
                    Database.fetchUserWithUID(uid: uid) { (user) in
                        guard let username = user?.username else {return}
                        likeString += "\(selfLike ? ", " : "") \(username) "
                        if selfLike {
                            likeString += ((totalLikes - 2) > 0 ) ? "& \(totalLikes - 2) Others" : ""
                        } else {
                            likeString += ((totalLikes - 1) > 0 ) ? "& \(totalLikes - 1) Others" : ""
                        }
                    }
                }
            }
        } else if totalLikes > 0 {
            likeString =  "Legit by \(totalLikes) Users"
        } else {
            likeString = ""
        }
        
        postLikedLabelHide?.isActive = (likeString == "")
        postLikedLabel.text = likeString
        postLikedLabel.sizeToFit()
        
    }
    
    
    func setupPicturesScroll() {
        
        if post?.images != nil {
            photoImageView.image = post?.images![0]
        } else {
            photoImageView.loadImage(urlString: post?.imageUrls.first!)
        }
        
        //        guard let _ = post?.imageUrls else {return}
        
        photoImageScrollView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.width)
        photoImageScrollView.contentSize.width = photoImageScrollView.frame.width * CGFloat((post?.imageCount)!)
        photoImageScrollView.backgroundColor = UIColor.gray
        //        print("setupPicturesScroll | PhotoImageView ", photoImageScrollView.contentSize)
        
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
        setupPageControl()
        //        photoImageScrollView.reloadInputViews()
    }

    
    func setupUser(){
//        usernameLabel.text = post?.user.username
//        usernameLabel.sizeToFit()
//        usernameLabel.adjustsFontSizeToFitWidth = true
//
//        usernameLabel.isUserInteractionEnabled = true
//        let usernameTapGesture = UITapGestureRecognizer(target: self, action: #selector(usernameTap))
//        usernameLabel.addGestureRecognizer(usernameTapGesture)
        
        guard let profileImageUrl = post?.user.profileImageUrl else {return}
        userProfileImageView.loadImage(urlString: profileImageUrl)
    }
    
    func setupRatingLegitIcon(){
        
        if (self.post?.rating)! != 0 {
            self.starRating.rating = (self.post?.rating)!
            starRating.tintColor = starRating.rating >= 4 ? UIColor.ianLegitColor() : UIColor.selectedColor()
            self.starRating.isHidden = false

        } else {
            self.starRating.isHidden = true
        }
        
        var display = ""
        if let ratingEmoji = self.post?.ratingEmoji {
            display = ratingEmoji + "" + (extraRatingEmojisDic[ratingEmoji] ?? "").capitalizingFirstLetter()
            display = ratingEmoji

        }
        
        hideRatingEmojiConstraint?.constant = (display == "") ? 0 : 30
        
        ratingEmojiLabel.text = display
        ratingEmojiLabel.font = UIFont(font: .avenirNextDemiBold, size: 25)
        ratingEmojiLabel.textColor = UIColor.ianBlackColor()
        ratingEmojiLabel.isHidden = display == ""
        ratingEmojiLabel.backgroundColor = UIColor.clear
        ratingEmojiLabel.layer.borderWidth = 0
        ratingEmojiLabel.layer.borderColor = UIColor.ianLegitColor().cgColor
        ratingEmojiLabel.sizeToFit()
        
    }
    
    fileprivate func setupAttributedLocationName(){
        
        guard let post = self.post else {return}
        
        var displayLocationName: String = ""
        
        var shortDisplayLocationName: String = ""
        var locationCountry: String = ""
        var locationState: String = ""
        var locationCity: String = ""
        var locationAdress: String = ""
        
        self.locationCityLabel.text = ""
        
        if post.locationGPS == nil {
            displayLocationName = ""
        }
        else if post.locationGooglePlaceID! == "" && post.locationName == post.locationAdress {
            // Not Google Tagged Location, Display by City, State
            // User might tag location name without locationGooglePlaceID
            displayLocationName = self.displayLocationAdress(adressString: self.post?.locationAdress)
            
        } else {
            // Google Tagged Location. Display Google Location Name
            displayLocationName = post.locationName
            if let tempCity = self.post?.locationSummaryID{
                
                var displayCityString = ""
                // Display City Location with Restaurant Tag
                var tempCityArray = tempCity.components(separatedBy: ",")
                tempCityArray = tempCityArray.reversed()
                
                for text in tempCityArray {
                    if text != " US" && (displayCityString.count + text.count) < 25 {
                        if displayCityString == "" {
                            displayCityString = text
                        } else {
                            displayCityString = text + "," + displayCityString
                        }
                    }
                }
                
                self.locationCityLabel.text = displayCityString
                
                //                if tempCity.suffix(4) == ", US" {
                //                    let endIndex = tempCity.index(tempCity.endIndex, offsetBy: -4)
                //                    let truncated = tempCity.substring(to: endIndex)
                //                    self.locationCityLabel.text = truncated
                //                } else {
                //                    self.locationCityLabel.text = tempCity
                //                }
            }
        }
        
        if self.locationCityLabel.text != "" {
            self.locationCityViewHeight?.constant = 14
        } else {
            self.locationCityViewHeight?.constant = 0
        }
        
        self.locationCityLabel.sizeToFit()
        
        if let ratingEmoji = self.post?.ratingEmoji {
            if extraRatingEmojis.contains(ratingEmoji) {
//                displayLocationName.append(" \(ratingEmoji)")
            }
        }
        
        
        let locationNameFont = UIFont(name: "Poppins-Bold", size: 18)

        
        let attributedTextCaption = NSMutableAttributedString(string: displayLocationName, attributes: [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: locationNameFont])
        
        
        let paragraphStyle = NSMutableParagraphStyle()
        
        // *** set LineSpacing property in points ***
        paragraphStyle.lineSpacing = 0 // Whatever line spacing you want in points
        
        // *** Apply attribute to string ***
        attributedTextCaption.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedTextCaption.length))
        
        // *** Set Attributed String to your label ***
//        self.locationNameLabel.attributedText = attributedTextCaption
        self.locationNameLabel.text = displayLocationName
        self.locationNameLabel.adjustsFontSizeToFitWidth = true
        self.locationNameLabel.sizeToFit()
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
        
        if let _ = postDateString {
            if let tempCity = self.post?.locationSummaryID{
                
                var displayCityString = ""
                // Display City Location with Restaurant Tag
                var tempCityArray = tempCity.components(separatedBy: ",")
                tempCityArray = tempCityArray.reversed()
                
                for text in tempCityArray {
                    if text != " US" && (displayCityString.count + text.count) < 25 {
                        if displayCityString == "" {
                            displayCityString = text
                        } else {
                            displayCityString = text + "," + displayCityString
                        }
                    }
                }
                
                postDateString! += ", " + displayCityString
            }
            
            
            let attributedText = NSMutableAttributedString(string: postDateString!, attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)])

            self.postDateLabel.attributedText = attributedText
            self.postDateLabel.sizeToFit()
            
            self.optionsButton.isHidden = !(post.creatorUID == Auth.auth().currentUser?.uid)
            self.optionsButton.isUserInteractionEnabled = true
        }

        
        locationDistanceLabel.text = SharedFunctions.formatDistance(inputDistance: post.distance)
//        locationDistanceLabel.adjustsFontSizeToFitWidth = true
        locationDistanceLabel.sizeToFit()
        
    // CAPTION

        let nameFont = UIFont(name: "Poppins-Bold", size: 13)
        let attributedNameCaption = NSMutableAttributedString(string: "\((self.post?.user.username)!) ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: nameFont])

        let captionFont = UIFont(name: "Poppins-Regular", size: 12)
        let attributedTextCaption = NSMutableAttributedString(string: "\(post.caption)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: captionFont])

        attributedNameCaption.append(attributedTextCaption)
        
        self.captionTextView.attributedText = attributedNameCaption
        self.captionTextView.sizeToFit()
        
        
    // COMMENTS
        let commentCount = self.post?.comments.count ?? 0
        commentLabel.isHidden = (commentCount == 0)
        hideComment?.isActive = (commentCount == 0)
        
        if commentCount > 0 {
            commentLabel.text = "View \(commentCount) Comments"
        } else {
            commentLabel.text = ""
        }
        
        
        
    }
    
    func setupEmojis(){
        
        priceLabel.text = "\(self.post?.price ?? "")"
        priceLabel.sizeToFit()

        
        emojiArray.emojiLabels = self.post?.nonRatingEmoji ?? []
        emojiArray.setEmojiButtons()
        emojiArray.sizeToFit()
        //        print("UPDATED EMOJI ARRAY: \(emojiArray.emojiLabels)")

        ratingEmojiLabel.text = self.post?.ratingEmoji ?? ""
        ratingEmojiLabel.sizeToFit()
        
        defaultEmojiArray.emojiLabels = self.post?.autoTagEmoji ?? []
        defaultEmojiArray.setEmojiButtons()
        defaultEmojiArray.sizeToFit()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.currentImage = scrollView.currentPage
        self.pageControl.currentPage = self.currentImage - 1
        self.setupImageCountLabel()
        print(self.currentImage, self.pageControl.currentPage)
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.hideEmojiDetailLabel()
    }
    
    
    
}

extension NewSinglePostView: UIScrollViewDelegate, UIGestureRecognizerDelegate, EmojiButtonArrayDelegate, LocationSummaryViewDelegate, ListSummaryDelegate, BottomActionBarDelegate, UploadPhotoListControllerDelegate, UserHeaderViewDelegate, SharePhotoListControllerDelegate {
    func doShowListView() {
        self.taggedListHeightConstraint?.isActive = false
    }
    
    func doHideListView() {
        self.taggedListHeightConstraint?.isActive = true
    }
    
    func didTapAddList() {
        self.extCreateNewList()
    }
    

    func refreshPost(post: Post) {
        print("   -refreshPost | NewSinglePostView")
        self.post = post
        postCache.removeValue(forKey: post.id!)
        postCache[post.id!] = post
    }
    

    func didTapList(list: List?) {
        guard let list = list else {return}
        self.extTapList(list: list)
    }
    
    func didTapUser(user: User?) {
        guard let uid = user?.uid else {return}
        self.extTapUser(userId: uid)
    }
    
    
    func toggleMapFunction() {
        print("MAP FUNCTION")
    }
    
    func didTapLocationHours(hours: [JSON]?){
        print("LocationController | locationHoursIconTapped")

            let presentedViewController = LocationHoursViewController()
            presentedViewController.hours = hours
            presentedViewController.setupViews()
            presentedViewController.providesPresentationContextTransitionStyle = true
            presentedViewController.definesPresentationContext = true
            presentedViewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            presentedViewController.modalTransitionStyle = .crossDissolve
            presentedViewController.view.backgroundColor = UIColor.clear
            presentedViewController.view.layer.cornerRadius = 5
            presentedViewController.view.layer.masksToBounds = true
            presentedViewController.view.layer.borderColor = UIColor.lightGray.cgColor
            presentedViewController.view.layer.borderWidth = 1


            //presentedViewController.view.backgroundColor = UIColor.init(white: 0.4, alpha: 0.8)
            self.present(presentedViewController, animated: true, completion: nil)
    }
    
    func didTapPost(post: Post?) {
        guard let post = post else {return}
        self.extTapPicture(post: post)
    }
    
    func didTapLocation(){
        guard let post = post else {return}
        self.extTapLocation(post: post)
    }
    
    func didTapRatingEmoji() {
        guard let emoji = self.post?.ratingEmoji else {return}
        self.didTapEmoji(index: 0, emoji: emoji)
    }
    
    func didTapEmoji(index: Int?, emoji: String) {
        guard let index = index else {
            print("No Index For emoji \(emoji)")
            return
        }
//        guard let displayEmoji = self.post?.nonRatingEmoji[index] else {return}
//        guard let  displayEmojiTag = self.post?.nonRatingEmojiTags[index] else {return}
        //        self.delegate?.displaySelectedEmoji(emoji: displayEmoji, emojitag: displayEmojiTag)
        
        // Reference Tag From Post
        var displayEmojiTag = ""
        if let emojiIndex = self.post?.nonRatingEmoji.index(of: emoji) {
            displayEmojiTag = (self.post?.nonRatingEmojiTags[emojiIndex]) ?? ""
        }
        
//        guard let  displayEmojiTag = EmojiDictionary[emoji]?.capitalizingFirstLetter() else {return}
        
        print("Selected Emoji \(index) | \(emoji) | \(displayEmojiTag)")
        
        var captionDelay = 3
        emojiDetailLabel.text = "\(emoji)  \(displayEmojiTag)"
        emojiDetailLabel.alpha = 1
        emojiDetailLabel.sizeToFit()
        
        UIView.animate(withDuration: 0.5, delay: TimeInterval(captionDelay), options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.hideEmojiDetailLabel()
        }, completion: { (finished: Bool) in
        })
    }
    
    func hideEmojiDetailLabel(){
        self.emojiDetailLabel.alpha = 0
    }
    
    func doubleTapEmoji(index: Int?, emoji: String) {
        print("doubleTapEmoji | \(index) | \(emoji)")
    }
    


    func setupPhotoImageScrollView(){

        photoImageScrollView.contentSize.width = photoImageScrollView.frame.width
        photoImageScrollView.addSubview(photoImageView)
        photoImageScrollView.isPagingEnabled = true
        photoImageScrollView.delegate = self
        
        photoImageView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.width)
        photoImageView.tag = 0
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.pinch(sender:)))
        pinch.delegate = self
        self.photoImageScrollView.addGestureRecognizer(pinch)
        
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.pan(sender:)))
        pan.delegate = self
        self.photoImageScrollView.addGestureRecognizer(pan)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(photoDoubleTapped))
        doubleTap.numberOfTapsRequired = 2
        photoImageScrollView.addGestureRecognizer(doubleTap)
        photoImageScrollView.isUserInteractionEnabled = true
        
        
        let firstdoubleTap = UITapGestureRecognizer(target: self, action: #selector(photoDoubleTapped))
        firstdoubleTap.numberOfTapsRequired = 2
        photoImageView.addGestureRecognizer(firstdoubleTap)
        photoImageView.isUserInteractionEnabled = true
        
    }
    
    @objc func pinch(sender:UIPinchGestureRecognizer) {
        
        if sender.state == .began {
            let currentScale = self.photoImageScrollView.frame.size.height / self.photoImageScrollView.bounds.size.height
            let newScale = currentScale*sender.scale
            self.view.bringSubviewToFront(self.photoImageScrollView)
            
            
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
                self.view.bringSubviewToFront(self.captionView)
                self.view.bringSubviewToFront(self.photoCountLabel)
            })
        }
    }
    
    
    @objc func pan(sender: UIPanGestureRecognizer) {
        if self.isZooming && sender.state == .began {
            self.originalImageCenter = sender.view?.center
            self.view.bringSubviewToFront(self.photoImageScrollView)
            self.view.bringSubviewToFront(self.photoImageView)
        } else if self.isZooming && sender.state == .changed {
            let translation = sender.translation(in: self.view)
            if let view = sender.view {
                view.center = CGPoint(x:view.center.x + translation.x,
                                      y:view.center.y + translation.y)
            }
            sender.setTranslation(CGPoint.zero, in: self.photoImageScrollView.superview)
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func photoDoubleTapped(){
        print("Double Tap | Handle Like")
        self.handleLike()

    }
    
    @objc func captionBubbleTap(){

    }
    
    @objc func usernameTap() {
        print("Tap username label", post?.user.username ?? "")
        guard let post = post else {return}
        self.extTapUser(post: post)
    }
    
    func userOptionPost(post:Post){
        
        let optionsAlert = UIAlertController(title: "User Options", message: "", preferredStyle: UIAlertController.Style.alert)
        
        optionsAlert.addAction(UIAlertAction(title: "Edit Post", style: .default, handler: { (action: UIAlertAction!) in
            // Allow Editing
            self.editPost(post: post)
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Delete Post", style: .default, handler: { (action: UIAlertAction!) in
            self.deletePost(post: post)
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        present(optionsAlert, animated: true, completion: nil)
    }
    
    func editPost(post:Post){
        let editPost = UploadPhotoController()
        // Post Edit Inputs
        editPost.editPostInd = true
        editPost.editPost = post
        
        let navController = UINavigationController(rootViewController: editPost)
        self.present(navController, animated: false, completion: nil)
    }
    
    
    func deletePost(post:Post){
        
        let deleteAlert = UIAlertController(title: "Delete", message: "All data will be lost.", preferredStyle: UIAlertController.Style.alert)
        deleteAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            // Remove from Current View
            self.dismiss(animated: true, completion: nil)
            self.navigationController?.popToRootViewController(animated: true)
            Database.deletePost(post: post)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        present(deleteAlert, animated: true, completion: nil)
        
    }
    
    
    func displayLocationAdress(adressString: String?) -> String {
        guard let adressString = adressString else {
            print("PictureController | DisplayLocationAdress Error | No Location Adress")
            return ""}
        
        var displayLocationName: String = ""
        
        var shortDisplayLocationName: String = ""
        var locationCountry: String = ""
        var locationState: String = ""
        var locationCity: String = ""
        var locationAdress: String = ""
        
        let locationNameTextArray = adressString.components(separatedBy: ",")
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
        return shortDisplayLocationName
    }
    
    
    @objc func handleComment() {
        guard let post = post else {return}
        self.extTapComment(post: post)
//        self.didTapComment(post: post)
    }
    
    @objc func handleLike() {
        //      delegate?.didLike(for: self)
        
        guard let postId = self.post?.id else {return}
        guard let creatorId = self.post?.creatorUID else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        // Animates before database function is complete
        
        if (self.post?.hasLiked)! {
            // Unselect Upvote
            self.post?.hasLiked = false
            self.post?.likeCount -= 1
            Database.handleVote(post: post, creatorUid: creatorId, vote: 0) {}
        } else {
            // Upvote
            self.post?.hasLiked = true
            self.post?.likeCount += 1
            Database.handleVote(post: post, creatorUid: creatorId, vote: 1) {}
        }
        
        
        if self.post?.hasLiked != bottomActionBar.post?.hasLiked {
            print("handleLike | Bottom Action Bar Like \(bottomActionBar.post?.hasLiked) Not Matching Post \(self.post?.hasLiked)")
            self.bottomActionBar.post = self.post
        }

        self.delegate?.refreshPost(post: self.post!)
        
        // POP OUT LIKE VIEW ON PHOTO IMAGE
        
        if (self.post?.hasLiked)! {
//            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            AudioServicesPlaySystemSound(1520)
//            var origin: CGPoint = self.photoImageScrollView.center;
//            popView = UIView(frame: CGRect(x: origin.x, y: origin.y, width: 100, height: 100))
////            popView = UIImageView(image: #imageLiteral(resourceName: "like_filled").resizeImageWith(newSize: CGSize(width: 100, height: 100)).withRenderingMode(.alwaysOriginal))
//            popView = UIImageView(image: #imageLiteral(resourceName: "like_filled_vector").withRenderingMode(.alwaysOriginal))
//
//
//            popView.contentMode = .scaleToFill
//            popView.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
//            popView.frame.origin.x = origin.x
//            popView.frame.origin.y = origin.y * 0.5
//
//            photoImageView.addSubview(popView)
//            popView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 100, height: 100)
//            popView.centerXAnchor.constraint(equalTo: self.photoImageScrollView.centerXAnchor).isActive = true
//            popView.centerYAnchor.constraint(equalTo: self.photoImageScrollView.centerYAnchor, constant: 0).isActive = true
//            self.popView.isHidden = false
//
////            popView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 100, height: 100)
//            UIView.animate(withDuration: 1,
//                           delay: 0,
//                           usingSpringWithDamping: 0.2,
//                           initialSpringVelocity: 6.0,
//                           options: .allowUserInteraction,
//                           animations: { [weak self] in
//                            self?.popView.transform = .identity
//            }) { (done) in
//                self.popView.removeFromSuperview()
//                self.popView.alpha = 0
//                self.popView.isHidden = true
//            }
//
//            let when = DispatchTime.now() + 2
//            DispatchQueue.main.asyncAfter(deadline: when) {
//                self.popView.removeFromSuperview()
//                self.popView.alpha = 0
//                self.popView.isHidden = true
//            }
        }
    }
    
    func handleTagList() {
        guard let post = post else {return}
        self.didTapBookmark(post: post)
    }
    
    func didTapBookmark(post: Post) {
        
//        let sharePhotoListController = UploadPhotoListController()
//        sharePhotoListController.uploadPost = post
//        sharePhotoListController.isBookmarkingPost = true
//        sharePhotoListController.delegate = self
        let sharePhotoListController = SharePhotoListController()
        sharePhotoListController.uploadPost = post
        sharePhotoListController.isBookmarkingPost = true
        sharePhotoListController.delegate = self
        navigationController?.pushViewController(sharePhotoListController, animated: true)
    }
        
    func activateAppleMap(post: Post?) {
        guard let post = post else {return}
        print("activateAppleMap | \(post.locationName) | \(post.locationAdress) | \(post.locationGPS)")
        guard let location = post.locationGPS else {return}
        
        let latitude: CLLocationDegrees = location.coordinate.latitude
        let longitude: CLLocationDegrees = location.coordinate.longitude

        let regionDistance:CLLocationDistance = 10000
        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        let regionSpan = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "\(post.locationName)"
        mapItem.openInMaps(launchOptions: options)
    }
    
    
}

protocol UserHeaderViewDelegate {
//    func listSelected(list: List?)
    func didTapUser(user: User?)
    func displayExtraRatingInfo()
    
}

class UserHeaderView: UIView {
    
    var delegate: UserHeaderViewDelegate?
    
    let userProfileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 2
        iv.layer.cornerRadius = 30/2
        iv.layer.masksToBounds = true
        return iv
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(font: .avenirNextRegular, size: 14)
        label.font = UIFont(font: .avenirNextDemiBold, size: 14)
        label.font = UIFont(name: "Poppins-Bold", size: 16)
        
    var emojiArray = EmojiButtonArray(emojis: [], frame: CGRect(x: 0, y: 0, width: 0, height: 25))
    var ratingEmojiLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(name: "Poppins-Bold", size: 20)
        label.textColor = UIColor.ianLegitColor()
        label.textAlignment = NSTextAlignment.center
        label.isUserInteractionEnabled = true
        label.backgroundColor = UIColor.clear
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayExtraRatingInfo)))
        return label
    }()

//        label.font = UIFont(name: "Poppins-Regular", size: 14)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.left
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    var user: User? {
        didSet {
            guard let user = user else {return}
            let profileImageUrl = user.profileImageUrl
            userProfileImageView.loadImage(urlString: profileImageUrl)
            
            usernameLabel.text = user.username
            usernameLabel.sizeToFit()
        }
    }
    
    var post: Post? {
        didSet {
            guard let post = post else {return}
            var locationName = post.locationName
            if locationName == "" {
                locationName = post.locationSummaryID ?? ""
            }
            if locationName == "" {
                locationName = post.locationAdress ?? ""
            }
            usernameLabel.text = locationName
            usernameLabel.sizeToFit()
        }
    }
    
    @objc func displayExtraRatingInfo() {
        self.delegate?.displayExtraRatingInfo()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
//        emojiArray.alignment = .right
//        emojiArray.delegate = self
//        addSubview(emojiArray)
//        emojiArray.anchor
//
//        addSubview(userProfileImageView)
//        userProfileImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 30, height: 30)
//        userProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapUser)))
//        userProfileImageView.isUserInteractionEnabled = true
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 2, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        usernameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapUser)))
        usernameLabel.isUserInteractionEnabled = true
        
    }
    
    func didTapUser(){
        guard let user = user else {return}
        self.delegate?.didTapUser(user: user)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
