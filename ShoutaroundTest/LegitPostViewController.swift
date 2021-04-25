//
//  LegitPostViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/24/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit
import mailgun

import Cosmos
import DropDown
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

class LegitPostViewController: UIViewController {

    var post: Post? {
        didSet {
            reloadPost()
        }
    }

    var curUser: User?
    
    var imageWidth: CGFloat = 0
    
    let scrollview: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = UIColor.white
        sv.isScrollEnabled = true
        sv.showsVerticalScrollIndicator = false
        return sv
    }()
    
    let headerView = UIView()
    let headerHeight = 60 + UIApplication.shared.statusBarFrame.height

    
    lazy var navBackButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        let icon = #imageLiteral(resourceName: "back_icon").withRenderingMode(.alwaysTemplate)

        button.setImage(icon, for: .normal)
        button.layer.backgroundColor = UIColor.white.cgColor
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
    
    
    // MARK: -  PHOTOS
    
    let userProfileImageView: CustomImageView = {
        
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 2
        return iv
        
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        
        label.font = UIFont(name: "Poppins-Bold", size: 12)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.left
        return label
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
    
    
    var popView = UIView()
    var enableDelete: Bool = false
    var isZooming = false
    var currentImage = 1 {
        didSet {
//            setupImageCountLabel()
        }
    }
    var imageCount = 0
    
    
    var originalImageCenter:CGPoint?

    
    // MARK: -  FOLLOW UNFOLLOW BUTTON
    lazy var listFollowButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Follow List", for: .normal)
        button.titleLabel?.font =  UIFont.systemFont(ofSize: 14)
        button.layer.borderColor = UIColor.ianLegitColor().cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 0
        button.backgroundColor = UIColor.clear
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.addTarget(self, action: #selector(didTapFollowButton), for: .touchUpInside)
        return button
    }()
    
    func didTapFollowButton() {
        
    }
    
    
    var pageControl : UIPageControl = UIPageControl()

    
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
    
    let postDateLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.lightGray
        label.numberOfLines = 0
        return label
    }()
    
    let postInfoView = UIView()
    
    
    // MARK: -  LISTS
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

    var locationViewHeight: CGFloat = 35
    var listCollectionViewHeight: NSLayoutConstraint?

    let cellId = "CellId"
    
    
    let captionTextView: UITextView = {
        let tv = UITextView()
        tv.isScrollEnabled = false
        tv.textContainer.maximumNumberOfLines = 2
        tv.textContainerInset = UIEdgeInsets.zero
        tv.textContainer.lineBreakMode = .byTruncatingTail
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.isEditable = false
        return tv
    }()
    
    // MARK: - EMOJI
    
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
    
    
    // MARK: -  ACTION BAR
    var actionBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    // MARK: - BOOKMARK
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
    
    // MARK: - LIKES
    
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
        label.textColor = UIColor.darkGray
        label.lineBreakMode = .byCharWrapping
        return label
    }()
    
    var likeCountLabelHeight: NSLayoutConstraint?
    
    
    @objc func handleBookmark() {
        guard let post = post else {return}
        let sharePhotoListController = UploadPhotoListController()
        sharePhotoListController.uploadPost = post
        sharePhotoListController.isBookmarkingPost = true
        sharePhotoListController.delegate = self
        navigationController?.pushViewController(sharePhotoListController, animated: true)

    }
    

    
    // MARK: - MESSAGE BUTTON
    
    var messageContainer = UIView()
        
    lazy var sendMessageButton: UIButton = {
        let button = UIButton(type: .system)
        //        button.setImage(#imageLiteral(resourceName: "bookmark_white").withRenderingMode(.alwaysOriginal), for: .normal)
        button.setImage(#imageLiteral(resourceName: "send_plane").resizeImageWith(newSize: CGSize(width: 20, height: 20)).withRenderingMode(.alwaysOriginal), for: .normal)
        
        button.addTarget(self, action: #selector(didTapMessage), for: .touchUpInside)
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
    
    
    @objc func didTapMessage(){
        guard let post = post else {return}
        self.extTapMessage(post: post)
    }
    
    
    var friendSocialLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.italicSystemFont(ofSize: 12)
        label.textColor = UIColor.ianLegitColor()
        label.textAlignment = NSTextAlignment.left
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayFollowLists)))
        return label
    }()
    
    // MARK: - COMMENTS
    
    var commentContainer = UIView()
    
    lazy var commentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "commentButton").withRenderingMode(.alwaysOriginal), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.addTarget(self, action: #selector(handleComment), for: .touchUpInside)
        
//        button.setTitle("Comment", for: .normal)
//        button.setTitleColor(UIColor.ianBlackColor(), for: .normal)
//        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
//        button.tintColor = UIColor.ianBlackColor()
//        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
//        button.layer.borderWidth = 1
//        button.layer.borderColor = UIColor.ianBlackColor().cgColor
        return button
    }()
    
    @objc func handleComment() {
        guard let post = post else {return}
        let commentsController = CommentsController(collectionViewLayout: UICollectionViewFlowLayout())
        commentsController.post = post
        commentsController.delegate = self
        navigationController?.pushViewController(commentsController, animated: true)
    }
    var comments = [Comment]()
    
    lazy var commentSummaryView = UIView()
    
    var commentLabel1 = PaddedUILabel()
    var commentLabel2 = PaddedUILabel()
    var commentLabel3 = PaddedUILabel()

    var hideCommentView: NSLayoutConstraint? = nil
    var commentStackView = UIStackView()
    
    let viewCommentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ianBlackColor()
        return label
    }()
    
 
    // MARK: - LOCATION

    
    let locationSummary = LocationSummary()
    
    // MARK: - OTHER PICS

    var otherPostHeader: UILabel = {
        let label = UILabel()
        label.text = "Other posts from restaurant"
        label.font = UIFont(name: "Poppins-Bold", size: 20)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.left
        return label
    }()
    
    var otherPostSegmentControl = UISegmentedControl()
    var isFilteringFriends: Bool = true
    var otherPostSegmentOptions = ["YOUR FRIENDS","COMMNITY"]

    
    
    lazy var photoCollectionView : DynamicHeightCollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = DynamicHeightCollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = UIColor(white: 0, alpha: 0.03)
        cv.isScrollEnabled = false
        return cv
    }()
    
    let photoCellId = "photoCellId"
    var allPosts = [Post]()
    var friendPosts = [Post]()
    
    
    // MARK: - VIEW DID LOAD

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // INITT
        view.backgroundColor = UIColor.clear
        setupNavigationItems()

        scrollview.frame = view.frame
//        scrollview.contentSize = CGSize(width: view.frame.width, height: view.frame.height + 400)
        scrollview.contentSize = CGSize(width: view.frame.width, height: view.frame.height)
        view.addSubview(scrollview)
        
        scrollview.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
    // THIS CODE MAKES SCROLLVIEW GO ALL THE WAY TO THE TOP
        scrollview.contentInsetAdjustmentBehavior = .never
        scrollview.backgroundColor = UIColor.backgroundGrayColor()
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleBackPressNav))
        swipeRight.direction = .right
        self.scrollview.addGestureRecognizer(swipeRight)
        
        
// MARK: - SETUP HEADER
        scrollview.addSubview(headerView)
        headerView.anchor(top: scrollview.topAnchor, left: scrollview.leftAnchor, bottom: nil, right: scrollview.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: headerHeight)
        
        view.addSubview(navBackButton)
        navBackButton.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 33, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 30, height: 30)
        navBackButton.layer.applySketchShadow()
        
        headerView.addSubview(userProfileImageView)
        userProfileImageView.anchor(top: nil, left: headerView.leftAnchor, bottom: headerView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 50, paddingBottom: 15, paddingRight: 0, width: 30, height: 30)
        
        headerView.addSubview(listFollowButton)
        listFollowButton.anchor(top: nil, left: nil, bottom: nil, right: headerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: 100, height: 30)
        listFollowButton.centerYAnchor.constraint(equalTo: userProfileImageView.centerYAnchor).isActive = true
        
        headerView.addSubview(usernameLabel)
        usernameLabel.anchor(top: nil, left: userProfileImageView.rightAnchor, bottom: nil, right: listFollowButton.leftAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        usernameLabel.centerYAnchor.constraint(equalTo: userProfileImageView.centerYAnchor).isActive = true
        usernameLabel.isUserInteractionEnabled = true
        usernameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapUserName)))
        
// MARK: - SETUP IMAGE
        scrollview.addSubview(photoImageScrollView)
        imageWidth = self.view.frame.width - 16
        photoImageScrollView.frame = CGRect(x: 0, y: 0, width: imageWidth, height: imageWidth)
        photoImageScrollView.anchor(top: headerView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
        photoImageScrollView.heightAnchor.constraint(equalTo: photoImageScrollView.widthAnchor, multiplier: 1).isActive = true
        photoImageScrollView.isPagingEnabled = true
        photoImageScrollView.delegate = self
        setupPhotoImageScrollView()
        
        scrollview.addSubview(locationDistanceLabel)
        locationDistanceLabel.anchor(top: nil, left: photoImageScrollView.leftAnchor, bottom: photoImageScrollView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        
    // PAGE CONTROL
        setupPageControl()
        scrollview.addSubview(pageControl)
        pageControl.anchor(top: nil, left: nil, bottom: photoImageScrollView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 40, height: 5)
        pageControl.centerXAnchor.constraint(equalTo: photoImageScrollView.centerXAnchor).isActive = true
        // Do any additional setup after loading the view.
        
        
    // MARK: - POST CAPTION BUBBLE
        scrollview.addSubview(captionView)
        captionView.anchor(top: photoImageScrollView.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 50, paddingLeft: 50, paddingBottom: 40, paddingRight: 50, width: 0, height: 0)
        captionView.bottomAnchor.constraint(lessThanOrEqualTo: photoImageScrollView.bottomAnchor).isActive = true
        
        scrollview.addSubview(captionBubble)
        captionBubble.anchor(top: captionView.topAnchor, left: captionView.leftAnchor, bottom: captionView.bottomAnchor, right: captionView.rightAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 0, height: 0)
        captionBubble.contentMode = .center
    
        // Hide initial caption bubbles
        hideCaptionBubble()
        
        
        
        
    // MARK: - POST INFO
        scrollview.addSubview(postInfoView)
        postInfoView.anchor(top: photoImageScrollView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 260)
        postInfoView.backgroundColor = UIColor.ianWhiteColor()
        
        // LOCATION - 60
        // LIST - 35
        // CAPTION - 100
        //EMOJI/RATING - FOOTERVIEW - 70
        
        let locationView = UIView()
        postInfoView.addSubview(locationView)
        locationView.anchor(top: postInfoView.topAnchor, left: postInfoView.leftAnchor, bottom: nil, right: postInfoView.rightAnchor, paddingTop: 12, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 60)
        
        locationView.addSubview(locationNameLabel)
        locationNameLabel.anchor(top: locationView.topAnchor, left: locationNameLabel.leftAnchor, bottom: nil, right: locationNameLabel.rightAnchor, paddingTop: 0, paddingLeft: 12, paddingBottom: 0, paddingRight: 12, width: 0, height: 0)
        
        locationView.addSubview(locationCityLabel)
        locationCityLabel.anchor(top: locationNameLabel.bottomAnchor, left: locationView.leftAnchor, bottom: locationView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 12, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        locationView.addSubview(postDateLabel)
        postDateLabel.anchor(top: locationNameLabel.bottomAnchor, left: nil, bottom: locationView.bottomAnchor, right: locationView.rightAnchor, paddingTop: 5, paddingLeft: 12, paddingBottom: 0, paddingRight: 12, width: 0, height: 0)

        // LIST COLLECTIONVIEW
        
        let listContainer = UIView()
        scrollview.addSubview(listContainer)
        listContainer.anchor(top: locationView.bottomAnchor, left: postInfoView.leftAnchor, bottom: nil, right: postInfoView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        listCollectionViewHeight = listContainer.heightAnchor.constraint(equalToConstant: locationViewHeight)
        listCollectionViewHeight?.isActive = true
        
        setupListCollectionView()
        
        listContainer.addSubview(listCollectionView)
        listCollectionView.anchor(top: listContainer.topAnchor, left: listContainer.leftAnchor, bottom: listContainer.bottomAnchor, right: listContainer.rightAnchor, paddingTop: 0, paddingLeft: 12, paddingBottom: 0, paddingRight: 12, width: 0, height: 0)
        
        
        postInfoView.addSubview(captionTextView)
        captionTextView.anchor(top: listContainer.bottomAnchor, left: postInfoView.leftAnchor, bottom: nil, right: postInfoView.rightAnchor, paddingTop: 0, paddingLeft: 12, paddingBottom: 0, paddingRight: 12, width: 0, height: 100)
        
        let footerView = UIView()
        postInfoView.addSubview(footerView)
        footerView.anchor(top: captionTextView.bottomAnchor, left: postInfoView.leftAnchor, bottom: postInfoView.bottomAnchor, right: postInfoView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 16, paddingRight: 0, width: 0, height: 0)

        
    // STAR RATING
        footerView.addSubview(starRating)
        starRating.anchor(top: nil, left: footerView.leftAnchor, bottom: footerView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        // HEADER EMOJIS
        emojiArray.alignment = .right
        emojiArray.delegate = self
        footerView.addSubview(emojiArray)
        emojiArray.anchor(top: nil, left: nil, bottom: footerView.bottomAnchor, right: footerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 25)

        scrollview.addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top: nil, left: nil, bottom: photoImageScrollView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)
        emojiDetailLabel.centerXAnchor.constraint(equalTo: photoImageScrollView.centerXAnchor).isActive = true
        emojiDetailLabel.alpha = 0
        
        let footerDiv = UIView()
        footerView.addSubview(footerDiv)
        footerDiv.anchor(top: nil, left: footerView.leftAnchor, bottom: footerView.bottomAnchor, right: footerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
        footerDiv.backgroundColor = UIColor.ianLightGrayColor()
        
    // ACTION BAR
        scrollview.addSubview(actionBar)
        actionBar.anchor(top: footerView.bottomAnchor, left: postInfoView.leftAnchor, bottom: nil, right: postInfoView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 60)
        actionBar.backgroundColor = UIColor.ianWhiteColor()
        
        let actionStackView = UIStackView(arrangedSubviews: [likeContainer, messageContainer, bookmarkContainer])
        actionStackView.distribution = .fillEqually
        actionStackView.backgroundColor = UIColor.ianWhiteColor()
        likeContainer.backgroundColor = UIColor.ianWhiteColor()
        messageContainer.backgroundColor = UIColor.ianWhiteColor()
        bookmarkContainer.backgroundColor = UIColor.ianWhiteColor()

        actionBar.addSubview(actionStackView)
        actionStackView.anchor(top: nil, left: actionBar.leftAnchor, bottom: nil, right: actionBar.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 30)
        actionStackView.centerYAnchor.constraint(equalTo: actionBar.centerYAnchor).isActive = true
        actionStackView.sizeToFit()
        
    // LIKE BUTTON - LEFT
        likeContainer.addSubview(likeButton)
        likeButton.anchor(top: likeContainer.topAnchor, left: likeContainer.leftAnchor, bottom: likeContainer.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        
    // SHARE BUTTON - LEFT
        messageContainer.addSubview(sendMessageButton)
        sendMessageButton.anchor(top: messageContainer.topAnchor, left: messageContainer.leftAnchor, bottom: messageContainer.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        
    // BOOKMARK BUTTON - RIGHT
        bookmarkContainer.addSubview(bookmarkButton)
        bookmarkButton.anchor(top: commentContainer.topAnchor, left: nil, bottom: bookmarkContainer.bottomAnchor, right: bookmarkContainer.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        
    // COMMENT VIEW
        let commentStackView = UIStackView(arrangedSubviews: [commentLabel1, commentLabel2, commentLabel3])
        commentStackView.distribution = .equalSpacing
        commentStackView.axis = .vertical
        scrollview.addSubview(commentStackView)
        commentStackView.anchor(top: actionBar.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
        
        scrollview.addSubview(commentContainer)
        commentContainer.anchor(top: commentStackView.bottomAnchor, left: commentStackView.leftAnchor, bottom: nil, right: commentStackView.rightAnchor, paddingTop: 16, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
        
        commentContainer.addSubview(commentButton)
        commentButton.anchor(top: commentContainer.topAnchor, left: commentContainer.leftAnchor, bottom: commentContainer.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 100, height: 0)
        
        commentContainer.addSubview(viewCommentLabel)
        viewCommentLabel.anchor(top: commentContainer.topAnchor, left: commentButton.rightAnchor, bottom: commentContainer.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        guard let locView = locationSummary.view else {return}
        scrollview.addSubview(locView)
        locView.anchor(top: commentContainer.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 30, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
        locView.layer.applySketchShadow()
        
        let spacing = UIView()
        spacing.backgroundColor = UIColor.clear
        scrollview.addSubview(spacing)
        spacing.anchor(top: locView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 35)
        
        scrollview.addSubview(otherPostHeader)
        otherPostHeader.anchor(top: spacing.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
        otherPostHeader.sizeToFit()
        
        setupSegmentControl()
        scrollview.addSubview(otherPostSegmentControl)
        otherPostSegmentControl.anchor(top: otherPostHeader.bottomAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        otherPostSegmentControl.sizeToFit()
        
        setupCollectionView()
        scrollview.addSubview(photoCollectionView)
        photoCollectionView.anchor(top: otherPostSegmentControl.bottomAnchor, left: view.leftAnchor, bottom: scrollview.bottomAnchor, right: view.rightAnchor, paddingTop: 8, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
        

        
        
        
    }
    
    func hideCaptionBubble(){
        self.captionView.alpha = 0
        self.captionBubble.alpha = 0
    }
    
    func showCaptionBubble(){
        self.captionView.alpha = 1
        self.captionBubble.alpha = 1
        
    }
    
    @objc func handleBackPressNav(){
//        guard let post = self.post else {return}
        self.handleBack()
    }
    
    func setupNavigationItems(){

        self.setNeedsStatusBarAppearanceUpdate()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.barTintColor = UIColor.clear
        self.navigationController?.navigationBar.tintColor = UIColor.clear
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()

    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}





extension LegitPostViewController: UploadPhotoListControllerDelegate, CommentsControllerDelegate {
    
    // MARK: - LOAD POST

    
    func reloadPost(){
        guard let post = post else {return}
     
        let imageUrls = post.imageUrls
        
        setupPicturesScroll()
        setupPageControl()
        setupUser()
        setupEmojiRatings()
        setupLocationName()
        setupCaptionBubble()
        setupPostDate()
        setupComments()
        setupAttributedSocialCount()
    }
    
    func setupPicturesScroll() {
        
        let picCount = post?.imageUrls.count ?? 1
                
        photoImageScrollView.frame = CGRect(x: 0, y: 0, width: imageWidth, height: imageWidth)
        photoImageScrollView.contentSize.width = imageWidth * CGFloat(picCount)
        
        for i in 0 ..< picCount {
            let imageView = CustomImageView()
            if let image = post?.images?[i] {
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
        print("setupPicturesScroll | \(picCount) Images")
    }
    
    func setupCaptionBubble() {
        guard let post = self.post else {return}
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
    // Add Location Name
        let attributedString = NSMutableAttributedString(string: "\(post.locationName)", attributes: [NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 20), NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor()])
        
    // Add Location Adress
        var attributedtext = NSMutableAttributedString(string: "\n\(post.locationAdress)", attributes: [NSAttributedString.Key.font: UIFont(name: "Poppins-Regular", size: 18), NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor()])
        attributedString.append(attributedtext)
       
    // Add Emojis
        for (index,tag) in post.autoTagEmojiTags.enumerated() {
            
            attributedtext = NSMutableAttributedString(string: "\n\(post.autoTagEmoji[index]) \(post.autoTagEmojiTags[index].capitalizingFirstLetter())", attributes: [NSAttributedString.Key.font: UIFont(name: "Poppins-Regular", size: 15), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
            attributedString.append(attributedtext)
            
        }
        
    // Add Price
        if let price = post.price {
            attributedtext = NSMutableAttributedString(string: "\n\(price)", attributes: [NSAttributedString.Key.font: UIFont(name: "Poppins-Regular", size: 18), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
            attributedString.append(attributedtext)
        }
        
        captionBubble.attributedText = attributedString
        captionBubble.numberOfLines = 0
        captionBubble.sizeToFit()
        

    }
    
    func setupUser(){
        guard let userId = post?.creatorUID else {return}
        
        usernameLabel.text = post?.user.username
        usernameLabel.sizeToFit()
        usernameLabel.adjustsFontSizeToFitWidth = true
        usernameLabel.isUserInteractionEnabled = true
        setupListFollowButton()
        
        guard let profileImageUrl = post?.user.profileImageUrl else {return}
        userProfileImageView.loadImage(urlString: profileImageUrl)
        
        
    }
    
    func setupListFollowButton() {
        guard let userId = post?.creatorUID else {return}

        let isFollowing = CurrentUser.followerUids.contains(userId)
        listFollowButton.setTitle(isFollowing ? "Following" : "Follow", for: .normal)
        let icon = isFollowing ? #imageLiteral(resourceName: "followed").withRenderingMode(.alwaysTemplate) : #imageLiteral(resourceName: "follow").withRenderingMode(.alwaysTemplate)
        listFollowButton.setImage(icon, for: .normal)
        listFollowButton.tintColor = isFollowing ? UIColor.ianBlackColor() : UIColor.ianLegitColor()
    }
    
    
    func setupEmojiRatings() {
        if let displayEmojis = self.post?.nonRatingEmoji{
            emojiArray.emojiLabels = displayEmojis
        } else {
            emojiArray.emojiLabels = []
        }
        emojiArray.setEmojiButtons()
        emojiArray.sizeToFit()
        
        if (self.post?.rating)! != 0 {
            self.starRating.rating = (self.post?.rating)!
            starRating.tintColor = starRating.rating >= 4 ? UIColor.ianLegitColor() : UIColor.selectedColor()
            self.starRating.isHidden = false

        } else {
            self.starRating.isHidden = true
        }
        
    }
    
    func setupLocationName(){
        var locationString = ""
        
        if let locationName = self.post?.locationName {
            locationString = locationName
        } else if let adress = self.post?.locationAdress {
            locationString = adress.cutoff(length: 30)
        } else {
           locationString = "No Location"
        }
        
        if let ratingEmoji = self.post?.ratingEmoji {
            locationString += " \(ratingEmoji)"
        }
        
        self.locationNameLabel.text = locationString
        
        if let tempCity = self.post?.locationSummaryID{
            self.locationCityLabel.text = tempCity
        } else {
            self.locationCityLabel.text = ""
        }
        
    }
    
    fileprivate func setupPostDate(){

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
            
//            let attributedString = NSMutableAttributedString(string: postDateString!, attributes: [NSAttributedString.Key.font: UUIFont.systemFont(ofSize: 12), NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            
            
            self.postDateLabel.text = postDateString
            self.postDateLabel.sizeToFit()
        }
    }
    
    func setupComments() {
        guard let postId = self.post?.id else {return}

        Database.fetchCommentsForPostId(postId: postId) { (commentsFirebase) in
            print("SinglePostView | setupComments | \(commentsFirebase.count) Comments")
            self.comments = []
            self.comments += commentsFirebase
            self.refreshCommentStackView()
        }
    }
    
    
    fileprivate func setupAttributedSocialCount(){
        /*
        guard let post = self.post else {return}
        var displayNames = [] as [String]
        var displayNamesUid = [:] as [String:String]
        
        // Bookmark Counts
        
//        var totalUniqueListUsers = post.allList.countUniqueStringValues()
//        var totalUniqueListedByFollowers = post.followingList.countUniqueStringValues()

        // Following Users - Summarizes User Counts
        var followingUsers: [String: Int] = post.followingList.stringValueCounts()
        followingUsers.sorted(by: { $0.value > $1.value })
        
        // Remove Post Creator ID from following stats
        if let creatorIndex = followingUsers.index(forKey: post.creatorUID!) {
            followingUsers.remove(at: creatorIndex)
        }
        
        var tempFollowingLists = post.followingList.filter { (key, value) -> Bool in
            return value != post.creatorUID
        }
        var listByFollowersCount = tempFollowingLists.count + (post.selectedListId?.count ?? 0)
        var userString: [String] = []
        var otherUserCount = followingUsers.count ?? 0
        
        if self.post?.hasPinned ?? false {
            userString.append("You")
        }
        
        if followingUsers.count > 0 {
            let mostListFollowingUser1 = followingUsers.first?.key
            Database.fetchUserWithUID(uid: mostListFollowingUser1!) { (user) in
                
                if let username = user?.username {
                    userString.append(username)
                    otherUserCount += -1
                }
//                self.updateSocialLabel(listCount: listByFollowersCount, userCount: otherUserCount, usernames: userString)
            }
        } else {
//            self.updateSocialLabel(listCount: listByFollowersCount, userCount: otherUserCount, usernames: userString)
        }
        
        
        // ACTION BUTTON COUNTS
        
        // Button Counts
        
//        self.likeCount.text = post.likeCount != 0 ? String(post.likeCount) : ""
//        self.likeCount.sizeToFit()
//        self.likeButtonLabel.text = "LEGIT"

        let likeText = post.likeCount != 0 ? String(post.likeCount) + "  Legits!" : " Legit"
        self.likeButton.setTitle(likeText, for: .normal)
        
        
        
        self.likeButtonLabel.text = post.likeCount != 0 ? String(post.likeCount) + "  LEGIT" : " LEGIT"
//        self.likeCount.text?.append(" LEGIT")
        
// COMMENTS ARE UPDATED SEPARATELY
    
//        self.commentCount.text = post.commentCount != 0 ? String(post.commentCount) : ""
//        self.commentCount.text?.append(" Comments")
        self.commentCount.text = post.commentCount != 0 ? String(post.commentCount) + "  COMMENT" : " COMMENT"
        self.commentCount.sizeToFit()
        
        self.messageCount.text = post.messageCount > 0 ? String( post.messageCount) : ""
        self.messageCount.text?.append(" Messages")
        
        
//        self.bookmarkButtonLabel.text = "BOOKMARK"
//        self.listCount.text = (self.post?.allList.count ?? 0) > 0 ? String(self.post?.allList.count ?? 0) : ""
        let listAddedString = post.hasPinned ? "LIST TAGGED" : "TAG LIST"
        self.bookmarkButtonLabel.text = post.allList.count != 0 ? String(post.allList.count) + "  LISTS" : listAddedString
        self.listCount.sizeToFit()
        
        //        self.listCount.text?.append(" List")
        
        
        // Resizes bookmark label to fit new count
        bookmarkLabelConstraint?.constant = self.listCount.frame.size.width
        //        self.layoutIfNeeded()
        
    */
    }


    
    
    
    
    
    // MARK: - REFRESH FUNCTIONS

    
    func refreshPost(post: Post) {
        
    }
    
    
    func refreshComments(comments: [Comment]) {
         print("SinglePostView | Refreshing Comments | \(comments.count) Comments")
         self.comments = comments
         self.refreshCommentStackView()
     }
     
         func refreshCommentStackView(){
             let commentArray = [commentLabel1, commentLabel2, commentLabel3]
         // CLEAR ALL COMMENTS
             for label in commentArray {
                 label.text = ""
                 label.numberOfLines = 3
     //            label.sizeToFit()
             }
             
             // SORT COMMENTS
             self.comments.sort(by: { (p1, p2) -> Bool in
                 return p1.creationDate.compare(p2.creationDate) == .orderedAscending
             })
             
             // UPDATE COMMENT COUNT
             if self.post?.commentCount != self.comments.count {
                 self.post?.commentCount = self.comments.count
                 guard let post = self.post else {return}
                 postCache[post.id!] = post
             }
     //        self.commentCount.text = self.comments.count != 0 ? String(self.comments.count) + "  COMMENT" : " COMMENT"
     //        self.commentCount.sizeToFit()
         
         // Fill with Comments
             for (index,label) in commentArray.enumerated() {
                 if index < self.comments.count {
                     
                     let comment = self.comments[index]
                     let username = comment.user.username
                     let commentText = comment.text
                     
                     let attributedText = NSMutableAttributedString(string: username, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12), NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor()])

                 
                     attributedText.append(NSMutableAttributedString(string: "\(commentText)", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12), NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor()]))
                     
                     label.attributedText = attributedText
                     label.sizeToFit()
     //                label.backgroundColor = UIColor.yellow
     //                print("COMMENT \(index) | \(attributedText)")

                 }
             }
             self.commentStackView.sizeToFit()
             
             if self.comments.count > 0 {
                 var commentCount = max(0, self.comments.count - 3)
                 var commentString = "VIEW \((commentCount == 0) ? "" : (String(commentCount) + " "))OTHER COMMENTS"
                 self.viewCommentLabel.text = commentString
                 hideCommentView?.isActive = false

             } else {
                 self.viewCommentLabel.text = "+ COMMENT"
                 hideCommentView?.isActive = true
             }
             self.viewCommentLabel.sizeToFit()
         }
     


    
    
}



extension LegitPostViewController: UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    func setupPageControl(){
        guard let imageCount = self.post?.imageCount else {return}
        self.pageControl.numberOfPages = imageCount
        self.pageControl.currentPage = self.currentImage - 1
        self.pageControl.tintColor = UIColor.red
        self.pageControl.pageIndicatorTintColor = UIColor.white
        self.pageControl.currentPageIndicatorTintColor = UIColor.ianLegitColor()
        self.pageControl.isHidden = self.pageControl.numberOfPages == 1
    }
    
    func captionBubbleTap() {
        if captionDisplayed {
             print("PictureController | Picture Tapped | Hide Caption")
             
             self.hideCaptionBubble()
             captionDisplayed = false
             captionView.layer.removeAllAnimations()
             captionBubble.layer.removeAllAnimations()
         } else {
             print("PictureController | Picture Tapped | Show Caption")
             
             self.showCaptionBubble()
             captionDisplayed = true
             let captionViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapLocation))
             captionView.isUserInteractionEnabled = true
             captionView.addGestureRecognizer(captionViewTapGesture)
             
             
             // Makes Captions Disappear fast if there is no caption
             
             var captionDelay = 0.0 as Double
             
             if (captionBubble.attributedText?.length)! > 1 && (captionBubble.text != "No Caption") {
                 captionDelay = 3
             } else {
                 captionDelay = 1
             }
             
             // User Interaction now allowed when object is being animated. So we delay it before reanimating it away
             let when = DispatchTime.now() + captionDelay // change 2 to desired number of seconds
             DispatchQueue.main.asyncAfter(deadline: when) {
                 UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
                     self.hideCaptionBubble()
                     
                 }, completion: { (finished: Bool) in
                     self.captionDisplayed = false
                 })
             }
         }
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
        
        
//        photoImageView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.width)
//        photoImageScrollView.addSubview(photoImageView)
//        photoImageView.tag = 0
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.pinch(sender:)))
        pinch.delegate = self
        //        self.photoImageView.addGestureRecognizer(pinch)
        self.photoImageScrollView.addGestureRecognizer(pinch)
        
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.pan(sender:)))
        pan.delegate = self
        //        self.photoImageView.addGestureRecognizer(pan)
        self.photoImageScrollView.addGestureRecognizer(pan)
        
        
        // Add Photo Count Label
        
        //        scrollview.addSubview(photoCountLabel)
        //        photoCountLabel.anchor(top: nil, left: view.leftAnchor, bottom: photoImageScrollView.bottomAnchor, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 5, width: 0, height: 0)
        //        photoCountLabel.sizeToFit()
        
    }
    
    func photoDoubleTapped(){
        print("Double Tap")
        self.handleLike()
    }
    
    func handleLike() {
        
    }
    
    @objc func pan(sender: UIPanGestureRecognizer) {
//        if self.isZooming && sender.state == .began {
//            self.originalImageCenter = sender.view?.center
//        } else if self.isZooming && sender.state == .changed {
//            let translation = sender.translation(in: self.view)
//            if let view = sender.view {
//                view.center = CGPoint(x:view.center.x + translation.x,
//                                      y:view.center.y + translation.y)
//            }
//            sender.setTranslation(CGPoint.zero, in: self.photoImageScrollView.superview)
//        }
    }
//
    @objc func pinch(sender:UIPinchGestureRecognizer) {
//
//        if sender.state == .began {
//            let currentScale = self.photoImageScrollView.frame.size.height / self.photoImageScrollView.bounds.size.height
//            let newScale = currentScale*sender.scale
//            self.view.bringSubviewToFront(self.photoImageScrollView)
//
//
//            if newScale > 1 {
//                self.isZooming = true
//            }
//
//        } else if sender.state == .changed {
//            guard let view = sender.view else {return}
//            let pinchCenter = CGPoint(x: sender.location(in: view).x - view.bounds.midX,
//                                      y: sender.location(in: view).y - view.bounds.midY)
//            let transform = view.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y)
//                .scaledBy(x: sender.scale, y: sender.scale)
//                .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
//
//            let currentScale = self.photoImageScrollView.frame.size.height / self.photoImageScrollView.bounds.size.height
//            var newScale = currentScale*sender.scale
//
//            if newScale < 1 {
//                newScale = 1
//                let transform = CGAffineTransform(scaleX: newScale, y: newScale)
//                self.photoImageScrollView.transform = transform
//                sender.scale = 1
//            }else {
//                view.transform = transform
//                sender.scale = 1
//            }
//
//        } else if sender.state == .ended || sender.state == .failed || sender.state == .cancelled {
//            print("End Scaling")
//            UIView.animate(withDuration: 0.3, animations: {
//                self.photoImageScrollView.transform = CGAffineTransform.identity
//                if let center = self.originalImageCenter {
//                    self.photoImageScrollView.center = center
//                }
//            }, completion: { _ in
//                self.isZooming = false
//                self.view.bringSubviewToFront(self.captionView)
//                self.view.bringSubviewToFront(self.photoCountLabel)
//            })
//        }
    }
//

    
    
    
}


extension LegitPostViewController: EmojiButtonArrayDelegate {
    func doubleTapEmoji(index: Int?, emoji: String) {
        print("Double Tapped Emoji \(emoji)")
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
       self.view.bringSubviewToFront(emojiDetailLabel)
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
    
    
}

extension LegitPostViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    
    func setupSegmentControl(){
        otherPostSegmentControl = UISegmentedControl(items: otherPostSegmentOptions)
        otherPostSegmentControl.addTarget(self, action: #selector(selectOtherPostFilter), for: .valueChanged)
        otherPostSegmentControl.selectedSegmentIndex = self.isFilteringFriends ? 0 : 1
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
    otherPostSegmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianLightGrayColor(), NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
    otherPostSegmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)
        
        otherPostSegmentControl.backgroundColor = .white
        otherPostSegmentControl.tintColor = .white
    }
    
    func selectOtherPostFilter(sender: UISegmentedControl) {
        print("Selected Friend Filter | ",sender.selectedSegmentIndex)
        self.isFilteringFriends = (sender.selectedSegmentIndex == 0)
        photoCollectionView.reloadData()
    }
    
    func setupCollectionView(){
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        photoCollectionView.showsHorizontalScrollIndicator = false
        
        photoCollectionView.backgroundColor = UIColor.legitColor().withAlphaComponent(0.8)
        photoCollectionView.backgroundColor = UIColor.clear

        photoCollectionView.register(TestGridPhotoCell.self, forCellWithReuseIdentifier: photoCellId)
    }
    
    
    func setupListCollectionView(){
        
        listCollectionView.register(LegitFullPostListCell.self, forCellWithReuseIdentifier: cellId)
        let layout = ListDisplayFlowLayout()
        layout.estimatedItemSize = CGSize(width: 60, height: 25)
        listCollectionView.collectionViewLayout = layout
        listCollectionView.backgroundColor = UIColor.clear
        listCollectionView.isScrollEnabled = true
        listCollectionView.showsHorizontalScrollIndicator = false
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == photoCollectionView
        {
            return self.isFilteringFriends ? friendPosts.count : allPosts.count
        }
        else if collectionView == listCollectionView
        {
            return postListNames.count ?? 0
        }
        else
        {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == photoCollectionView
        {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! TestGridPhotoCell
            let displayPost = self.isFilteringFriends ? friendPosts[indexPath.row] : allPosts[indexPath.row]
            cell.delegate = self
            cell.showDistance = false
            cell.post = displayPost
            return cell
            
        }
        else if collectionView == listCollectionView
        {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! LegitFullPostListCell
            
            var displayListName = self.postListNames[indexPath.row]
            var displayListId = self.postListIds[indexPath.row]
            cell.displayListName = displayListName
            cell.displayListId = displayListId
            cell.displayFont = 13
            cell.otherUser = self.creatorListIds.contains(where: { (listIds) -> Bool in
                listIds == displayListId
            })
            return cell
            
        }
        else
        {
            return UICollectionViewCell()
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView == photoCollectionView
        {
            let displayPost = self.isFilteringFriends ? friendPosts[indexPath.row] : allPosts[indexPath.row]
            self.extTapPicture(post: displayPost)
        }
        else if collectionView == listCollectionView
        {
            var displayListName = self.postListNames[indexPath.row]
            var displayListId = self.postListIds[indexPath.row]
            self.goToList(listId: displayListId, listName: displayListName)
            
        }
        
        
    }
    

}

extension LegitPostViewController: TestGridPhotoCellDelegate {
    func didTapUser(post: Post) {
        self.extTapUser(post: post)
    }
    
    
    func didTapPicture(post: Post) {
        self.extTapPicture(post: post)
    }
    
    func didTapListCancel(post: Post) {
        
    }
    
    func goToList(listId: String, listName: String) {
        guard let post = self.post else {return}
        Database.checkUpdateListDetailsWithPost(listName: listName, listId: listId, post: post, completion: { (fetchedList) in
            if fetchedList == nil {
                // List Does not Exist
                self.alert(title: "List Error", message: "List Does Not Exist Anymore")
            } else {
                let listViewController = LegitListViewController()
                listViewController.currentDisplayList = fetchedList
                listViewController.refreshPostsForFilter()
                self.navigationController?.pushViewController(listViewController, animated: true)
            }
        })
    }

    func didTapUserName() {
        guard let userId = post?.user.uid else {return}
        self.extTapUser(userId: userId)
    }
    
    func didTapLocation() {
        guard let post = self.post else {return}
        self.extTapLocation(post: post)
    }


    func displayFollowLists() {
        
    }
    

}
