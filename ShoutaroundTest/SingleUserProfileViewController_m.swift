//
//  SingleUserProfileViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/14/20.
//  Copyright © 2020 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

import FBSDKLoginKit
import CoreLocation
import EmptyDataSet_Swift
import CoreGraphics
import SVProgressHUD
import FirebaseAuth
import FirebaseDatabase
import SKPhotoBrowser

class SingleUserProfileViewController: UIViewController {


    static let RefreshNotificationName = NSNotification.Name(rawValue: "RefreshUser")
    var pageLoadUp: Bool = true

    var displayUserId:String? {
        didSet {
            if displayUserId != oldValue {
                print("Load ID | \(displayUserId) | SingleUserProfileViewController")
                fetchUser()
            }
        }
    }
    var displayUser: User? {
        didSet{
            print("SingleUserProfileViewController | Load User | \(displayUserId)")
            fetchPostsForUser()
//            viewFilter?.filterUser = displayUser
            setupNavigationItems()
//            newPostButton.isHidden = (displayUser?.uid != Auth.auth().currentUser?.uid)
//            navMapButton.isHidden = !newPostButton.isHidden
            postSortFormatBar.navGridToggleButton.isHidden = !addPhotoButton.isHidden
        }
    }
    
    var displayBack: Bool = false {
        didSet{
            setupNavigationItems()
        }
    }
    
    var displaySubscription: Bool = false {
        didSet{
            setupNavigationItems()
        }
    }
    var navNotificationButton: UIButton = TemplateObjects.NavNotificationButton()
    let navBackButton = navBackButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
    let navMapBarButton = NavBarMapButton.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
    var navInboxButton: UIButton = TemplateObjects.NavInboxButton()
    let addPhotoButton = UIButton()
    var navSubscriptionButton: UIButton = TemplateObjects.NavSubscriptionButton()

    
    let navInboxLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 20, y: 0, width: 15, height: 15))
        label.layer.borderColor = UIColor.clear.cgColor
        label.layer.borderWidth = 0
        label.layer.cornerRadius = label.bounds.size.height / 2
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = UIFont(name: "Poppins-Bold", size: 10)
        label.textColor = .white
        label.backgroundColor = UIColor.ianLegitColor()
        label.text = "80"
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openInbox)))
        return label
    }()
    
//    let navNotificationButton: UIButton = {
//        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
//        button.setImage(#imageLiteral(resourceName: "alert").withRenderingMode(.alwaysTemplate), for: .normal)
//        button.tintColor = UIColor.darkGray
//        //        button.layer.cornerRadius = button.frame.width/2
////        button.layer.masksToBounds = true
//        button.setTitle("", for: .normal)
//        button.addTarget(self, action: #selector(openNotifications), for: .touchUpInside)
//        button.layer.backgroundColor = UIColor.clear.cgColor
//        button.layer.borderColor = UIColor.gray.cgColor
//        button.layer.borderWidth = 0
//        button.layer.cornerRadius = 40/2
//        button.titleLabel?.textColor = UIColor.ianLegitColor()
////        button.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
////        button.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
////        button.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
//        return button
//    }()
    
    let notificationLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 25, y: 0, width: 15, height: 15))

//        let label = UILabel(frame: CGRect(x: 15, y: 0, width: 15, height: 15))
        label.layer.borderColor = UIColor.clear.cgColor
        label.layer.borderWidth = 0
        label.layer.cornerRadius = label.bounds.size.height / 2
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = UIFont(name: "Poppins-Bold", size: 10)
        label.textColor = .white
        label.backgroundColor = UIColor.ianLegitColor()
        label.text = "80"
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openNotifications)))
        return label
    }()
    
    @objc func refreshNotifications() {
        if displayUser?.uid != Auth.auth().currentUser?.uid {
            return
        }
        if CurrentUser.unreadEventCount > 0 {
            notificationButton.tintColor = UIColor.ianLegitColor()
            notificationLabel.text = String(CurrentUser.unreadEventCount)
//            navNotificationButton.addSubview(notificationLabel)
            navNotificationButton.tintColor = UIColor.ianLegitColor()
            notificationLabel.isHidden = false
        } else {
//                    notificationButton.setTitle("", for: .normal)
            notificationButton.tintColor = UIColor.gray
            notificationLabel.text = ""
            notificationLabel.isHidden = true
            navNotificationButton.tintColor = UIColor.darkGray
        }
        navNotificationButton.isUserInteractionEnabled = true

    }
    
    @objc func refreshInboxNotifications() {
        if displayUser?.uid != CurrentUser.uid {
            navInboxLabel.isHidden = true
            return
        }
        print("Refresh Inbox | \(CurrentUser.unreadMessageCount)")
        if CurrentUser.unreadMessageCount > 0 {
            navInboxLabel.text = String(CurrentUser.unreadMessageCount)
            navInboxButton.addSubview(navInboxLabel)
            navInboxLabel.tintColor = UIColor.ianLegitColor()
            navInboxLabel.isHidden = false
        } else {
//                    notificationButton.setTitle("", for: .normal)
            navInboxLabel.text = ""
            navInboxLabel.isHidden = true
            navInboxLabel.tintColor = UIColor.darkGray
        }
    }
    
    lazy var otherUserOptionsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("•••", for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 15)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(handleOptions), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        return button
    }()

    
// SEARCH SELECTIONS
    var first100EmojiCounts: [String:Int] = [:]
    var noFilterTagCounts: PostTagCounts = PostTagCounts.init()
    var currentPostTagCounts: PostTagCounts = PostTagCounts.init()
    var currentPostRatingCounts = RatingCountArray
//    let searchViewController = LegitSearchViewController()
    let searchViewController = LegitSearchViewControllerNew()
    var tempSearchBarText: String? = nil

    // BOTTOM EMOJI BAR
     let bottomEmojiBar = BottomEmojiBar()
    var bottomEmojiBarHide: NSLayoutConstraint?
    var bottomEmojiBarHeight: CGFloat = 50
    
    var isFetchingPost = false
    var isFiltering = false
    var viewFilter: Filter = Filter.init(defaultSort: defaultRecentSort) {
        didSet {
            self.isFiltering = self.viewFilter.isFiltering
            self.updateBottomSearchBar()
        }
    }

    var scrolltoFirst: Bool = false
    var fetchedPosts: [Post] = []
    var displayedPosts: [Post] = []
    
    let gridCellId = "gridCellId"
    let fullPostCellId = "fullPostCellId"
    let headerId = "headerId"
    let emptyCellId = "emptyCellId"
    let testCellId = "testCellId"

    var showEmpty = false
    
    var showNewPostButton = false {
        didSet {
            self.toggleNewPostButton()
        }
    }
    
    func toggleNewPostButton() {
        if self.showNewPostButton && displayUser?.uid == Auth.auth().currentUser?.uid {
            self.newPostButton.isHidden = false
            self.newPostButtonHeight?.constant = 40
            self.navMapButtonPosition?.constant = 50
//            self.navMapButtonWithNewPostPosition?.isActive = true
            

//            self.navMapButtonPosition = self.navMapButton.bottomAnchor.constraint(equalTo: self.newPostButton.topAnchor, constant: 10)
        } else {
            self.newPostButton.isHidden = true
            self.newPostButtonHeight?.constant = 0
            self.navMapButtonPosition?.constant = 0
//            self.navMapButtonPosition?.isActive = true
//            self.navMapButtonWithNewPostPosition?.isActive = false
//            self.navMapButtonPosition = self.navMapButton.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor, constant: 10)
        }
    }
    
    lazy var imageCollectionView : UICollectionView = {
        let layout = ListViewFlowLayout()
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 5
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: ProfileHeaderLayout())
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = .white
        cv.collectionViewLayout.invalidateLayout()
        return cv
    }()
    
    
    
    
    // Pagination Variables
    var paginatePostsCount: Int = 0
    var isFinishedPaging = false {
        didSet{
            if isFinishedPaging == true {
                print("Paging Finish: \(self.isFinishedPaging), \(self.paginatePostsCount) Posts")
            }
        }
    }
    
    var postFormatInd: Int = gridFormat {
        didSet {
            self.postSortFormatBar.isGridView == (self.postFormatInd == gridFormat)
            self.bottomSortBar.isGridView == (self.postFormatInd == gridFormat)
            self.imageCollectionView.reloadData()
        }
    }
    // 0 Grid View
    // 1 List View
    // 2 Full View
        
    var browser = SKPhotoBrowser()

    let navHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "User"
        label.font =  UIFont(name: "Poppins-Bold", size: 16)
        label.textColor = UIColor.ianBlackColor()
        label.backgroundColor = UIColor.clear
        label.textAlignment = .center
        return label
    }()
    
    
    let bottomSearchBar = UserSearchBar()
    var bottomSearchBarYHeight: CGFloat?
    
    let postSortFormatBar = PostSortFormatBar()
    
    let navFriendButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        button.setImage(#imageLiteral(resourceName: "friendship"), for: .normal)
        //        button.layer.cornerRadius = button.frame.width/2
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(openFriends), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.borderColor = UIColor.gray.cgColor
        button.layer.borderWidth = 0
        return button
    }()
    
    @objc func openFriends(){
        print("Display Friends For Current User| ",CurrentUser.user?.uid)
        self.extShowUserFollowers(inputUser: self.displayUser)
    }

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
        return button
    }()
    
    @objc func messageUser(){
        guard let user = self.displayUser else {return}

        
        // LOOK FOR CURRENT INBOX THREAD
        var userThread = CurrentUser.inboxThreads.first { (thread) -> Bool in
            return thread.threadUserUids.contains(user.uid)
        }
        
        if let tempThread = userThread {
            print("Found Current Inbox Thread with \(user.username): \(tempThread.threadID) : \(tempThread.threadUserUids)")
            self.extOpenMessage(message: tempThread, reload: true)
            return
        } else {
            print("Start New Inbox Thread withb \(user.username)")
            let messageController = MessageController()
            messageController.respondUser = [user]
            if let m = self.navigationController {
                self.navigationController?.pushViewController(messageController, animated: true)
            }
        }
    }
    
    let addPhotoButtonSize: CGFloat = 70
    var defaultHeight: CGFloat  = 1792.0
    var scalar: CGFloat = 1.0
    
    
    var sortSegmentControl: UISegmentedControl = TemplateObjects.createPostSortButton()
    var segmentWidth_selected: CGFloat = 110.0
    var segmentWidth_unselected: CGFloat = 80.0
    
    var newPostButtonHeight: NSLayoutConstraint?

    
    let newPostButton: UIButton = {
        let button = UIButton(type: .system)
//        button.setImage(#imageLiteral(resourceName: "search_selected").withRenderingMode(.alwaysOriginal), for: .normal)
        button.contentMode = .scaleAspectFill
        button.backgroundColor = UIColor.ianLegitColor()
        button.addTarget(self, action: #selector(didTapAddPhoto), for: .touchUpInside)
        return button
    }()
    
//    lazy var navMapButton: UIButton = {
//        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
//        let icon = #imageLiteral(resourceName: "map").withRenderingMode(.alwaysOriginal)
//        button.setImage(icon, for: .normal)
//        button.contentHorizontalAlignment = .center
//        button.backgroundColor = UIColor.white
////        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
//        button.tintColor = UIColor.gray
//        button.layer.borderWidth = 1
//        button.layer.borderColor = UIColor.oldIanLegitColor().cgColor
//        button.titleLabel?.font =  UIFont(font: .avenirNextBold, size: 13)
//        button.setTitleColor(UIColor.ianLegitColor(), for: .normal)
//        button.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
////        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
//        button.imageView?.contentMode = .scaleAspectFit
//        return button
//    }()

    lazy var navMapButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
//        let icon = #imageLiteral(resourceName: "google_color").withRenderingMode(.alwaysOriginal)
//        let icon = #imageLiteral(resourceName: "location_color").withRenderingMode(.alwaysOriginal)
        let icon = #imageLiteral(resourceName: "map").withRenderingMode(.alwaysTemplate)

        button.setTitle(" Map Posts", for: .normal)
        button.setImage(icon, for: .normal)
        button.layer.borderColor = UIColor.ianLegitColor().cgColor
        button.layer.borderWidth = 1
        button.clipsToBounds = true
        button.contentHorizontalAlignment = .center
        button.backgroundColor = UIColor.ianWhiteColor()
//        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        button.tintColor = UIColor.ianLegitColor()
        button.titleLabel?.font =  UIFont(font: .avenirNextBold, size: 14)
        button.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        button.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12)
        button.imageView?.contentMode = .scaleAspectFit

        return button
    }()
    
    var navMapButtonPosition: NSLayoutConstraint?
    var navMapButtonWithNewPostPosition: NSLayoutConstraint?
    
    
    lazy var detailLabel: PaddedUILabel = {
        let ul = PaddedUILabel()
        ul.isUserInteractionEnabled = false
        ul.numberOfLines = 0
        ul.textAlignment = NSTextAlignment.center
        ul.font = UIFont(name: "Poppins-Bold", size: 12)
        ul.textColor = UIColor.darkGray
        ul.backgroundColor = UIColor.lightSelectedColor()
        ul.alpha = 1
        ul.layer.cornerRadius = 10
        ul.clipsToBounds = true
        return ul
    }()
    
    // FILTER LEGIT BUTTON
    
    let filterLegitButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        button.setImage(#imageLiteral(resourceName: "legit_icon"), for: .normal)
        button.addTarget(self, action: #selector(didTapFilterLegit), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.white.cgColor
        button.layer.cornerRadius = button.frame.width/2
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor.selectedColor().cgColor
        button.layer.borderWidth = 1
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()
    
    func updateFilterLegitButton() {
        filterLegitButton.backgroundColor = self.viewFilter.filterLegit ? UIColor.lightSelectedColor() : UIColor.ianWhiteColor()
        filterLegitButton.alpha = self.viewFilter.filterLegit ? 1 : buttonSemiAlpha
    }
    
    let buttonSemiAlpha: CGFloat = 0.8

    
    // MARK: - VIEWDIDLOAD

    override func viewWillAppear(_ animated: Bool) {
        print("SingleProfileController | viewWillAppear")
        if #available(iOS 13.0, *) {
             navigationController?.navigationBar.setNeedsLayout()
        }
        setupNavigationItems()
        toggleNewPostButton()
        
        // KEYBOARD TAPS TO EXIT INPUT
        self.keyboardTap = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func newUserPost(_ notification: NSNotification) {
        if let userId = notification.userInfo?["uid"] as? String {
            if self.displayUserId == userId || self.displayUser?.uid == userId {
                if let postId = notification.userInfo?["postId"] as? String {
                    if !self.fetchedPosts.contains(where: { (post) -> Bool in
                        return post.id == postId
                    }) {
                        self.fetchPostsForUser()
                        print("NEW USER POST REFRESING ", userId , postId, "ProfileView")
                    }
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageCollectionView.collectionViewLayout.invalidateLayout()
    }
    
    var bottomSortBar = BottomSortBar()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }

        
        setupNavigationItems()
        setupCollectionView()
        self.view.backgroundColor = UIColor.white
        
        
        view.addSubview(bottomSortBar)
        bottomSortBar.anchor(top: nil, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        bottomSortBar.delegate = self
        bottomSortBar.selectSort(sort: self.viewFilter.filterSort ?? HeaderSortDefault)
        bottomSortBar.sideButtonType = .Map
        bottomSortBar.isGridView = (self.postFormatInd == 0)
        
        self.view.addSubview(imageCollectionView)
        imageCollectionView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: bottomSortBar.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        
//    // DETAIL LABEL
//        view.addSubview(detailLabel)
//        detailLabel.anchor(top: nil, left: nil, bottom: (bottomSortBar).topAnchor, right: nil, paddingTop: 4, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 0, height: 0)
//        detailLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        detailLabel.isHidden = true
            
        
        
//        postSortFormatBar.delegate = self
//        self.view.addSubview(postSortFormatBar)
//        postSortFormatBar.anchor(top: nil, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 15, paddingRight: 0, width: 0, height: 40)
//        postSortFormatBar.navGridToggleButton.isHidden = true
//        postSortFormatBar.navMapButton.isHidden = false
////        postSortFormatBar.isHidden = true
//
        self.scalar = min(1, UIScreen.main.nativeBounds.height / defaultHeight)
        print(" ~ addPhotoButton Scalar", self.scalar, UIScreen.main.nativeBounds.height, defaultHeight)
//
//        let addPhotoButtonSize: CGFloat = 75 * scalar
//        self.view.addSubview(addPhotoButton)
//        addPhotoButton.anchor(top: nil, left: nil, bottom: postSortFormatBar.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0 * scalar, paddingRight: 15, width: addPhotoButtonSize, height: addPhotoButtonSize)
//        addPhotoButton.layer.cornerRadius = addPhotoButtonSize/2
//        setupAddPhotoButton()
        


//        setupSegmentControl()
//
//        sortSegmentControl.layer.borderWidth = 1
//        view.addSubview(sortSegmentControl)
//        sortSegmentControl.anchor(top: nil, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 10, paddingRight: 15, width: 0, height: 40)
//        sortSegmentControl.alpha = 0.9
////        sortSegmentControl.rightAnchor.constraint(lessThanOrEqualTo: navMapButton.leftAnchor, constant: 15).isActive = true
//
////        sortSegmentControl.centerXAnchor.constraint(equalTo: barView.centerXAnchor).isActive = true
//        self.selectSort(sender: sortSegmentControl)
        
        view.addSubview(newPostButton)
        newPostButton.anchor(top: nil, left: nil, bottom: bottomSortBar.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 10, paddingRight: 15, width: 120, height: 0)
//        newPostButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        newPostButtonHeight = newPostButton.heightAnchor.constraint(equalToConstant: 40)
        newPostButtonHeight?.isActive = true
        newPostButton.setTitle("📷  Add Post", for: .normal)
        newPostButton.sizeToFit()
        newPostButton.tintColor = UIColor.ianWhiteColor()
        newPostButton.backgroundColor = UIColor.ianLegitColor()
        newPostButton.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
        newPostButton.addTarget(self, action: #selector(didTapAddPhoto), for: .touchUpInside)
        newPostButton.layer.cornerRadius = 10
        newPostButton.layer.masksToBounds = true
        newPostButton.layer.borderWidth = 1
        newPostButton.layer.borderColor = UIColor.ianLegitColor().cgColor
        let headerTitle = NSAttributedString(string: "📷  New Post", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 14)])

        newPostButton.setAttributedTitle(headerTitle, for: .normal)
//        toggleNewPostButton()

        view.addSubview(filterLegitButton)
        filterLegitButton.anchor(top: nil, left: nil, bottom: newPostButton.topAnchor, right: newPostButton.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 40, height: 40)
        filterLegitButton.layer.cornerRadius = 40/2
        filterLegitButton.clipsToBounds = true
        
        
    // DETAIL LABEL
        view.addSubview(detailLabel)
        detailLabel.anchor(top: nil, left: nil, bottom: nil, right: filterLegitButton.leftAnchor, paddingTop: 4, paddingLeft: 10, paddingBottom: 10, paddingRight: 2, width: 0, height: 0)
        detailLabel.centerYAnchor.constraint(equalTo: filterLegitButton.centerYAnchor).isActive = true
        detailLabel.isHidden = true
        
        
//        view.addSubview(navMapButton)
//        navMapButton.anchor(top: nil, left: sortSegmentControl.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 10, paddingRight: 10, width: 120, height: 40)
//        navMapButton.layer.cornerRadius = 30/2
//        navMapButton.layer.masksToBounds = true
//        navMapButton.addTarget(self, action: #selector(toggleMapFunction), for: .touchUpInside)
////        navMapButton.isHidden = true
//        navMapButtonPosition = navMapButton.bottomAnchor.constraint(equalTo: sortSegmentControl.bottomAnchor, constant: 0)
////        navMapButtonWithNewPostPosition = navMapButton.bottomAnchor.constraint(equalTo: sortSegmentControl.bottomAnchor, constant: 60)
////        toggleNewPostButton()
//        navMapButtonPosition?.isActive = true


        
        self.view.addSubview(searchViewController.view)
        searchViewController.view.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        searchViewController.view.alpha = 0
        setupSearchView()
        
        
        
        
//        self.view.addSubview(bottomSearchBar)
//        bottomSearchBar.delegate = self
//        bottomSearchBar.alpha = 0.9
//        bottomSearchBar.anchor(top: nil, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
//        bottomSearchBarYHeight = bottomSearchBar.frame.origin.y
//        print("bottomSearchBarYHeight :", bottomSearchBar.frame.origin.y)
//        print("view :", self.view.frame.origin.y)

        
//        imageCollectionView.bottomAnchor.constraint(lessThanOrEqualTo: bottomSearchBar.topAnchor).isActive = true
//        imageCollectionView.bottomAnchor.constraint(lessThanOrEqualTo: bottomEmojiBar.topAnchor).isActive = true

        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateFeed), name: SharePhotoListController.updateProfileFeedNotificationName, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: TabListViewController.refreshListNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: ListViewController.refreshListViewNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: AppDelegate.UserFollowUpdatedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshInboxNotifications), name: InboxController.newMsgNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.postEdited(_:)), name: MainTabBarController.editUserPost, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.postDeleted(_:)), name: MainTabBarController.deleteUserPost, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(locationDenied), name: AppDelegate.LocationDeniedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(locationUpdated), name: AppDelegate.LocationUpdatedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.newUserPost(_:)), name: MainTabBarController.newUserPost, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshNotifications), name: UserEventViewController.refreshNotificationName, object: nil)
//        self.view.layoutIfNeeded()

        print("  END |  NewListCollectionView | ViewdidLoad")

    }
    
    @objc func postDeleted(_ notification: NSNotification) {
        let postId = (notification.userInfo?["updatedPostId"] ?? "")! as! String
        self.displayedPosts.removeAll(where: {$0.id == postId})
        self.fetchedPosts.removeAll(where: {$0.id == postId})
        self.imageCollectionView.reloadData()
    }
    
    func updateDetailLabel() {
        var postCount = self.displayedPosts.count
        
//        if let filteredUser = self.viewFilter.filteredUser {
//            detailLabel.text = "\(self.mapFilter.filterLegit ? "Top " : "" )\(postCount) Posts from \(filteredUser.username.capitalizingFirstLetter())"
//            detailLabel.sizeToFit()
//            detailLabel.isHidden = false
//        } else if let filteredList = self.viewFilter.filteredList {
//            detailLabel.text = "\(self.mapFilter.filterLegit ? "Top " : "" )\(postCount)Posts in \(filteredList.name.capitalizingFirstLetter()) List"
//            detailLabel.sizeToFit()
//            detailLabel.isHidden = false
//        } else
        if self.viewFilter.filterLegit {
            detailLabel.text = "Top Posts"
            detailLabel.sizeToFit()
            detailLabel.isHidden = false
        }
        else {
            detailLabel.isHidden = true
        }
        
        detailLabel.textColor = self.viewFilter.filterLegit ? UIColor.customRedColor() : UIColor.gray
        updateFilterLegitButton()
    }
    
    
    
    func setupSegmentControl() {
        sortSegmentControl = UISegmentedControl(items: HeaderSortOptions)
        sortSegmentControl.selectedSegmentIndex = 0
        sortSegmentControl.addTarget(self, action: #selector(selectSort), for: .valueChanged)
        sortSegmentControl.backgroundColor = UIColor.white
        sortSegmentControl.tintColor = UIColor.oldLegitColor()
        sortSegmentControl.layer.borderWidth = 1
        sortSegmentControl.layer.borderColor = UIColor.lightGray.cgColor
        if #available(iOS 13.0, *) {
            sortSegmentControl.selectedSegmentTintColor = UIColor.mainBlue()
        }
        
        sortSegmentControl.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 16), NSAttributedString.Key.foregroundColor: UIColor.gray], for: .normal)
        sortSegmentControl.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 15), NSAttributedString.Key.foregroundColor: UIColor.ianWhiteColor()], for: .selected)
    }
    
    @objc func selectSort(sender: UISegmentedControl) {
        let sort = HeaderSortOptions[sender.selectedSegmentIndex]
        self.headerSortSelected(sort: sort)

        for (index, sortOptions) in HeaderSortOptions.enumerated()
        {
            var isSelected = (index == sender.selectedSegmentIndex)
            var displayFilter = (isSelected) ? "Sort \(sortOptions)" : sortOptions
            sender.setTitle(displayFilter, forSegmentAt: index)
            sender.setWidth((isSelected) ? (segmentWidth_selected * scalar) : (segmentWidth_unselected * scalar), forSegmentAt: index)
        }
        
//        self.searchTypeSegment.changeUnderlinePosition()
    }
    
    func setupAddPhotoButton() {
        addPhotoButton.layer.masksToBounds = true
        addPhotoButton.layer.borderColor = UIColor.ianLegitColor().cgColor
        addPhotoButton.layer.borderWidth = 0
        addPhotoButton.backgroundColor = UIColor.ianWhiteColor()
        addPhotoButton.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)

//        addPhotoButton.setImage(#imageLiteral(resourceName: "add_color").withRenderingMode(.alwaysOriginal), for: .normal)
//        let addPhotoImage = #imageLiteral(resourceName: "add_test_2").resizeImageWith(newSize: CGSize(width: addPhotoButtonSize * 0.8, height: addPhotoButtonSize * 0.8))
//
//        let addPhotoImage = #imageLiteral(resourceName: "add_test")
//        let addPhotoImage = #imageLiteral(resourceName: "add_test_2")
        addPhotoButton.tintColor = UIColor.ianLegitColor()
        
        let addPhotoImage = #imageLiteral(resourceName: "add_test_2")

//        let addPhotoImage = #imageLiteral(resourceName: "add_white_thick")
        addPhotoButton.tintColor = UIColor.ianWhiteColor()
        addPhotoButton.backgroundColor = UIColor.ianLegitColor()
        
        addPhotoButton.setImage(addPhotoImage.withRenderingMode(.alwaysTemplate), for: .normal)

        
        addPhotoButton.contentMode = .scaleToFill
        addPhotoButton.addTarget(self, action: #selector(didTapAddPhoto), for: .touchUpInside)
    }

    func setupSearchView() {
        searchViewController.delegate = self
        searchViewController.inputViewFilter = self.viewFilter
        searchViewController.noFilterTagCounts = self.noFilterTagCounts
        searchViewController.currentPostTagCounts = self.currentPostTagCounts
        searchViewController.currentRatingCounts = self.currentPostRatingCounts
        searchViewController.searchBar.text = ""
    }
    
    var notificationButton = UIBarButtonItem()
    
    func setupNavigationItems() {
        let tempImage = UIImage.init(color: UIColor.white)
        navigationController?.isNavigationBarHidden = false
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.barTintColor = UIColor.white
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.backgroundColor = UIColor.white
        navigationController?.view.backgroundColor = UIColor.white
        navigationController?.navigationBar.layer.shadowColor = UIColor.white.cgColor
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.layoutIfNeeded()
        
        
        let usernameNavHeader = UILabel()
        usernameNavHeader.textAlignment = .left
        
//        let profileImageSize = 30.0
//        let profileImage = CustomImageView(frame: CGRect(x: 0, y: 0, width: profileImageSize, height: profileImageSize))
//        profileImage.loadImage(urlString: displayUser?.profileImageUrl)
//        let userImg = profileImage.image?.resizeVI(newSize: CGSize(width: profileImageSize, height: profileImageSize))
//
//        usernameNavHeader.imageView?.frame = CGRect(x: 0, y: 0, width: profileImageSize, height: profileImageSize)
//        usernameNavHeader.imageView?.contentMode = .scaleAspectFit
//        usernameNavHeader.setImage(userImg, for: .normal)
//        usernameNavHeader.imageView?.layer.cornerRadius = CGFloat(profileImageSize) / 2
//        usernameNavHeader.imageView?.layer.masksToBounds = true
//        usernameNavHeader.imageView?.clipsToBounds = true
//        usernameNavHeader.titleLabel?.textAlignment = .left

        
        var usernameText = "  "
        if let name = displayUser?.username {
//            navHeaderLabel.text = username
            usernameText += name
        } else {
            usernameText += "User"
        }
        
        usernameText += " "
        
        let usernameTitle = NSMutableAttributedString()

        usernameTitle.append(NSAttributedString(string:usernameText, attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 16)]))
    
        
    // ADD BADGES
        if let userBadges = displayUser?.userBadges {
            for badge in userBadges {
                let image1Attachment = NSTextAttachment()
                let inputImage = UserBadgesImageRef[badge]
                image1Attachment.image = inputImage.alpha(1)
                image1Attachment.bounds = CGRect(x: 0, y: (usernameNavHeader.font.capHeight - (inputImage.size.height)).rounded() / 2, width: inputImage.size.width, height: inputImage.size.height)

                let image1String = NSAttributedString(attachment: image1Attachment)
                usernameTitle.append(image1String)
            }
        }
        
        


//        usernameNavHeader.setAttributedTitle(usernameTitle, for: .normal)
        usernameNavHeader.attributedText = usernameTitle
        self.navigationItem.titleView = usernameNavHeader
//
//        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 16)]
//
//// TITLE HEADER
//        if let username = displayUser?.username {
////            navHeaderLabel.text = username
//            navigationItem.title = username
//        } else {
////            navHeaderLabel.text = "User"
//            navigationItem.title = "User"
//        }
////        navigationController?.navigationBar.topItem?.titleView = navHeaderLabel

        // REMOVES THE 1PX BOTTOM LINE IN NAV BAR
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
        navigationController?.navigationBar.layoutIfNeeded()
        self.setNeedsStatusBarAppearanceUpdate()

        
// LEFT BAR BUTTON
//        navNotificationButton.addTarget(self, action: #selector(openNotifications), for: .touchUpInside)
//        let notificationCount = (CurrentUser.unreadEventCount > 0) ? String(CurrentUser.unreadEventCount) : ""
//        navNotificationButton.setTitle(notificationCount, for: .normal)
//        navNotificationButton.semanticContentAttribute = .forceRightToLeft
//        let notificationButton = UIBarButtonItem.init(customView: navNotificationButton)

        // Nav Back Button
        navBackButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        let backButton = UIBarButtonItem.init(customView: navBackButton)
        
        navSubscriptionButton.addTarget(self, action: #selector(openSubscriptions), for: .touchUpInside)
        let subscribeButton = UIBarButtonItem.init(customView: navSubscriptionButton)
        
        let userNameButton = UIBarButtonItem.init(customView: usernameNavHeader)

        if displayBack {
            self.navigationItem.leftBarButtonItem = backButton
//            self.navigationItem.leftBarButtonItems = [backButton, userNameButton]
        } else if self.displayUser?.uid == Auth.auth().currentUser?.uid && self.displaySubscription{
            self.navigationItem.leftBarButtonItem = subscribeButton
            //self.navigationItem.leftBarButtonItem = inboxButton
        } else {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem()
        }
        
        


//// RIGHT BAR BUTTON
        navMapBarButton.tintColor = UIColor.ianBlackColor()
        navMapBarButton.setTitleColor(UIColor.ianBlackColor(), for: .normal)
        navMapBarButton.setTitle(" Map ", for: .normal)
        navMapBarButton.addTarget(self, action: #selector(toggleMapFunction), for: .touchUpInside)
        let mapButton = UIBarButtonItem.init(customView: navMapBarButton)
        
        
        navFriendButton.addTarget(self, action: #selector(openFriends), for: .touchUpInside)
        let friendButton = UIBarButtonItem.init(customView: navFriendButton)

        
    // SHARE
        navShareButton.addTarget(self, action: #selector(messageUser), for: .touchUpInside)
        let shareBarButton = UIBarButtonItem.init(customView: navShareButton)
        
    // INBOX
        navInboxButton.addTarget(self, action: #selector(openInbox), for: .touchUpInside)
        let inboxButton = UIBarButtonItem.init(customView: navInboxButton)
        
    // NOTIFICATION
        navNotificationButton.addTarget(self, action: #selector(openNotifications), for: .touchUpInside)
        notificationButton = UIBarButtonItem.init(customView: navNotificationButton)
        notificationButton.customView?.addSubview(notificationLabel)
        self.view.bringSubviewToFront(notificationLabel)
        
    // OTHER USERS
        otherUserOptionsButton.addTarget(self, action: #selector(handleOptions), for: .touchUpInside)
        let navUserSetting = UIBarButtonItem.init(customView: otherUserOptionsButton)
        
  
        
        if Auth.auth().currentUser != nil {
            self.navigationItem.rightBarButtonItem = (self.displayUser?.uid == Auth.auth().currentUser?.uid) ? notificationButton : navUserSetting
        }
        refreshInboxNotifications()
        refreshNotifications()
    }
    
    @objc func toggleMapFunction(){
        var tempFilter = self.viewFilter ?? Filter.init()
        tempFilter.filterUser = self.displayUser
        appDelegateFilter = tempFilter
        self.toggleMapView()
    }
    
    
    @objc func openNotifications(){
        let note = UserEventViewController()
        self.navigationController?.pushViewController(note, animated: true)
    }
    
    
    @objc func didTapAddPhoto() {
        self.extCreateNewPhoto()
    }
    
    @objc func openSubscriptions() {
        if self.displayUser?.uid != Auth.auth().currentUser?.uid {
            self.alert(title: "ERROR", message: "You can't access subscriptions for \(self.displayUser?.username).")
            return
        }
        self.extOpenSubscriptions()
////        note.displayUser = self.displayUser
////        note.isPremiumSub = true
////        note.displayUser = CurrentUser.user
//        self.present(note, animated: true) {
//            print("Show Subscription")
//        }
    }
    
    var keyboardTap = UITapGestureRecognizer()

    
    @objc func keyboardWillShow(notification: NSNotification) {
        if (self.isViewLoaded && (self.view.window != nil)) {
            print("keyboardWillShow | Add Tap Gesture | SingleUserProfileViewController")
//            self.view.addGestureRecognizer(self.keyboardTap)
            
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {

                var bottomInset: CGFloat = 0.0
                if #available(iOS 11.0, *) {
                    bottomInset = CGFloat(view.safeAreaInsets.bottom)
                }
                
                
//                self.view.frame.origin.y = self.topbarHeight - keyboardSize.height + bottomInset
//                print(self.view.frame.origin.y, self.topbarHeight, keyboardSize.height, bottomInset)
                
            }
        }

//        if type(of: self.view.window?.rootViewController?.view) is SingleUserProfileViewController {
//            print("keyboardWillShow | Add Tap Gesture | SingleUserProfileViewController")
//            self.view.addGestureRecognizer(self.keyboardTap)
//        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification){
//        if type(of: self.view.window?.rootViewController?.view) is SingleUserProfileViewController {
//            print("keyboardWillHide | Remove Tap Gesture | SingleUserProfileViewController")
//            self.view.removeGestureRecognizer(self.keyboardTap)
//        }
        
        if (self.isViewLoaded && (self.view.window != nil)) {
            print("keyboardWillHide | Remove Tap Gesture | SingleUserProfileViewController")
//            self.view.removeGestureRecognizer(self.keyboardTap)
            
            
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
//                self.view.frame.origin.y += keyboardSize.height
//                self.view.frame.origin.y = self.topbarHeight
//                print(self.view.frame.origin.y, self.topbarHeight, keyboardSize.height)


            }
            
        }
    }
    
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
//        userSearchBar.resignFirstResponder()
        print("dismissKeyboard | SingleUserProfileViewController")
        self.view.endEditing(true)
    }
    
    
    
}

extension SingleUserProfileViewController {
    func fetchUser(){
        guard let uid = displayUserId else {
            print("User Profile: Fetch Posts Error, No UID")
            return
        }
        
        Database.fetchUserWithUID(uid: uid) { (fetchedUser) in
            self.displayUser = fetchedUser
            print("SingleUserprofileController | Fetched User | \(uid)")
        }
    }
    
    func fetchPostsForUser(){
        guard let uid = displayUser?.uid else {return}
        if (displayUser?.isBlocked ?? false) {
            self.fetchedPosts = []
            print("Blocked User")
            self.filterSortFetchedPosts()
            self.isFetchingPost = false
            return
        }
        if isFetchingPost {
            print("  ~ BUSY | fetchPostsForUser | \(uid) | Fetching: \(isFetchingPost)")
            return
        } else {
            isFetchingPost = true
        }
        
        if self.isViewLoaded && self.view.window != nil {
            SVProgressHUD.show(withStatus: "Loading Posts")
        }
        
        let start = DispatchTime.now() // <<<<<<<<<< Start time
        Database.fetchAllPostWithUID(creatoruid: uid) { (posts) in
            print("Fetched Posts | \(posts.count) | SingleUserProfileViewController")
            let end = DispatchTime.now()   // <<<<<<<<<<   end time
            let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
            let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests

            print("Fetch Single User Post Time: \(timeInterval) seconds")
            if uid == Auth.auth().currentUser?.uid {
                self.countMostUsedEmojis(posts: posts.filter({ (post) -> Bool in
                    post.creatorUID == uid
                }))
                self.countMostUsedCities(posts: posts.filter({ (post) -> Bool in
                    post.creatorUID == uid
                }))
                NotificationCenter.default.post(name: ListViewControllerNew.CurrentUserLoadedNotificationName, object: nil)
            }
            
            self.fetchedPosts = posts
            self.filterSortFetchedPosts()
            self.isFetchingPost = false
        }
    }
    
    func countMostUsedEmojis(posts: [Post]) {
        Database.countMostUsedEmojis(posts: posts) { (emojis) in
            self.displayUser?.mostUsedEmojis = emojis
            if displayUser?.uid == CurrentUser.uid {
                CurrentUser.mostUsedEmojis = emojis
                
                // Check for Top 5 Emojis
                let top5Emoji = Array(emojis.prefix(5))
                if let currentUserTopEmojis = CurrentUser.user?.topEmojis {
                    let dif = top5Emoji.difference(from: currentUserTopEmojis)
                    
                    if dif.count > 0 {
                        Database.checkTop5Emojis(userId: CurrentUser.uid!, emojis: top5Emoji)
                    }
                }
            }

            print(" Updated Current User Most Used Emojis \(emojis.count) | SingleUserProfileViewController")
        }
    }
    
    func countMostUsedCities(posts: [Post]) {
        Database.countMostUsedCities(posts: posts) { (cities) in
            self.displayUser?.mostUsedCities = cities
            if displayUser?.uid == CurrentUser.uid {
                CurrentUser.mostUsedCities = cities
            }
            print(" Updated Current User Most Used Cities \(CurrentUser.mostUsedCities.count) | SingleUserProfileViewController")
        }
    }
    
    func filterSortFetchedPosts(){
        
        
        self.isFiltering = self.viewFilter.isFiltering
        
        Database.filterSortPosts(inputPosts: self.fetchedPosts, postFilter: self.viewFilter) { finalPosts in
            self.pageLoadUp = false
            self.displayedPosts = finalPosts ?? []
            if !self.viewFilter.isFiltering {
                self.fetchedPosts = finalPosts ?? []
            }
            self.updateDetailLabel()

            print("  ~ FINISH | Filter and Sorting Post | \(self.fetchedPosts.count ?? 0) Fetched | \(finalPosts?.count ?? 0) Filtered | \(self.displayUser?.username) - \(self.displayUserId)")
         
            self.updateNoFilterCounts()
            self.updateBottomSearchBar()
        // Reload Data here to reload header, because only update the pics everywhere else
            self.imageCollectionView.reloadData()
            self.imageCollectionView.refreshControl?.endRefreshing()
            self.paginatePosts()
            
        }
    }
    
    func updateNoFilterCounts(){
        Database.summarizePostTags(posts: self.displayedPosts) { (tagCounts) in
            self.currentPostTagCounts = tagCounts
            if !self.viewFilter.isFiltering && !self.isFiltering {
                self.noFilterTagCounts = tagCounts
            }
//            print("   SingleUserProfileViewController | NoFilter Emoji Count | \(tagCounts) | \(self.displayedPosts.count) Posts")
            self.refreshBottomEmojiBar()
        }
        
        let first100 = Array(self.displayedPosts.prefix(100))
        Database.countEmojis(posts: first100, onlyEmojis: true) { (emojiCounts) in
            self.first100EmojiCounts = emojiCounts
            print("   SingleUserProfileViewController | First 50 Emoji Count | \(emojiCounts.count) | \(first100.count) Posts")
            self.refreshEmojiBar()
        }
        
        Database.summarizeRatings(posts: self.displayedPosts) { (ratingCounts) in
            self.currentPostRatingCounts = ratingCounts
        }
    }
    
    func refreshEmojiBar() {
        self.imageCollectionView.reloadData()
    }
    
    func refreshBottomEmojiBar() {
        bottomEmojiBar.viewFilter = self.viewFilter
        bottomEmojiBar.filteredPostCount = self.displayedPosts.count
        let sorted = self.first100EmojiCounts.sorted(by: {$0.value > $1.value})
        
        // Bottom Display First 50 Emojis
        var topEmojis: [String] = []
        for (index,value) in sorted {
            if index.isSingleEmoji /*&& topEmojis.count < 4*/ {
                topEmojis.append(index)
            }
        }
        bottomEmojiBar.displayedEmojis = topEmojis
        let showBottomEmojiBar = (self.viewFilter.isFiltering || self.viewFilter.filterSort != defaultRecentSort)
        bottomEmojiBarHide?.constant = showBottomEmojiBar ? bottomEmojiBarHeight : 0
//        self.view.layoutIfNeeded()
    }
    
    @objc func handleUpdateFeed() {
        
        // Check for new post that was edited or uploaded
        if newPost != nil && newPostId != nil {
            
            self.fetchedPosts.insert(newPost!, at: 0)
            self.filterSortFetchedPosts()
            if self.imageCollectionView.numberOfItems(inSection: 0) != 0 {
                let indexPath = IndexPath(item: 0, section: 0)
                self.imageCollectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
            }
            print("Pull in new post")
            
        } else {
            self.handleRefresh()
        }
    }
    
    @objc func handleRefresh() {
        self.setupNavigationItems()
        self.refreshAll()
//        fetchPostsForUser()
        print("Refresh User Profile Feed. FetchedPostCount: ", self.displayedPosts.count, " DisplayedPost: ", self.paginatePostsCount)
    }
    
    @objc func refreshAll(){
        self.clearFilter()
        self.clearAllPosts()
        self.refreshPagination()
        self.fetchUser()
        self.fetchPostsForUser()
        self.refreshBottomEmojiBar()
    }
    
    func clearFilter(){
        self.viewFilter.clearFilter()
        self.clearSort()
    }

    func clearSort(){
        self.viewFilter.filterSort = defaultRecentSort
    }
    
    
    func clearAllPosts(){
        self.fetchedPosts.removeAll()
        self.displayedPosts.removeAll()
        self.refreshPagination()
    }

    
    func refreshPagination(){
        self.isFinishedPaging = false
        self.paginatePostsCount = 0
    }
    
    @objc func refreshPostsForSort(){
       self.isFiltering = self.viewFilter.isFiltering
        Database.checkLocationForSort(filter: self.viewFilter) {
            Database.sortPosts(inputPosts: self.displayedPosts, selectedSort: self.viewFilter.filterSort, selectedLocation: self.viewFilter.filterLocation, completion: { (sortedPosts) in
                self.displayedPosts = sortedPosts ?? []
                if !self.viewFilter.isFiltering {
                    self.fetchedPosts = sortedPosts ?? []
                }
                print("  ~ FINISH | Sorting Post | \(sortedPosts?.count ?? 0) Posts | \(self.displayUser?.username) - \(self.displayUserId)")
             
                self.updateNoFilterCounts()
                self.imageCollectionView.reloadSections(IndexSet(integer: 0))
            })
        }
    }
    
    
    @objc func locationUpdated() {
        if self.isPresented  {
            if self.viewFilter.filterSort == sortNearest {
                self.viewFilter.filterLocation = CurrentUser.currentLocation
                print("SingleUserProfile Location UPDATED | \(CurrentUser.currentLocation)")
                self.refreshPostsForSort()
            }
        }
    }
    
    @objc func locationDenied() {
        if self.isPresented {
            self.missingLocAlert()
            self.sortSegmentControl.selectedSegmentIndex = HeaderSortOptions.index(of: sortNew) ?? 0
            self.viewFilter.filterSort = sortNew
            self.selectSort(sender: self.sortSegmentControl)
            print("SingleUserProfile Location Denied Function")
        }
    }
    
    
    
    func refreshPostsForFilter() {
        self.refreshPagination()
        self.fetchPostsForUser()
//        self.imageCollectionView.reloadSections(IndexSet(integer: 1))
        self.scrolltoFirst = true
    }
    
    func updateBottomSearchBar(){
        self.bottomSearchBar.viewFilter = self.viewFilter
        self.bottomSearchBar.filteredPostCount = (isFiltering) ? displayedPosts.count : fetchedPosts.count
    }
}

extension SingleUserProfileViewController: BottomEmojiBarDelegate, LegitSearchViewControllerDelegate, TestGridPhotoCellDelegate, FullPictureCellDelegate, SharePhotoListControllerDelegate, SingleUserProfileHeaderDelegate, SignUpControllerDelegate, SKPhotoBrowserDelegate, UserSearchBarDelegate, PostSortFormatBarDelegate, BottomSortBarDelegate {

    func displayAllLists() {
        self.extShowUserLists(inputUser: self.displayUser)
//        let sharePhotoListController = SharePhotoListController()
//        sharePhotoListController.clearAllInfo()
//        sharePhotoListController.selectedSort = sortPost
//        sharePhotoListController.viewListMode = true
//        sharePhotoListController.delegate = self
//        sharePhotoListController.uploadUser = self.displayUser
//        navigationController?.pushViewController(sharePhotoListController, animated: true)
    }
    
    func didTapLike(post: Post) {
        
    }
    
    
    @objc func didTapFilterLegit() {
        self.viewFilter.filterLegit = !self.viewFilter.filterLegit
        self.isFiltering = self.viewFilter.isFiltering
        self.updateFilterLegitButton()
//        self.bottomSortBar.isFilteringLegit = self.viewFilter.filterLegit
        self.refreshPostsForFilter()
    }
    
    
    func didTapEmojiBackButton() {
        
    }
    
    func didTapEmojiButton() {
        
    }
    
    func didTapMapButton() {
        if Auth.auth().currentUser == nil {
            self.alert(title: "Invalid Action", message: "Please Sign In")
            return
        }
        self.toggleMapFunction()
    }
    
    
    func didActivateSearchBar() {
        self.didTapSearchButton()
    }
    

    func filterContentForSearchText(searchText: String) {
        self.filterCaptionSelected(searchedText: searchText)
    }
    
    
    func didRemoveLocationFilter(location: String) {
        if self.viewFilter.filterLocationName?.lowercased() == location.lowercased() {
            self.viewFilter.filterLocationName = nil
        } else if self.viewFilter.filterLocationSummaryID?.lowercased() == location.lowercased() {
            self.viewFilter.filterLocationSummaryID = nil
        }
        self.refreshPostsForFilter()
    }
    
    func didRemoveRatingFilter(rating: String) {
        if extraRatingEmojis.contains(rating) {
            self.viewFilter.filterRatingEmoji = nil
        } else if rating.contains("⭐️") {
            self.viewFilter.filterMinRating = 0
        }
        self.refreshPostsForFilter()
    }
    
    
    func successSignUp() {
        // Refresh User
        print("SingleUserProfileView | Success Edit User | Refresh User")
        self.fetchUser()
    }
    
    func didTapGridButton() {
        if self.postFormatInd == postFormat {
            self.postFormatInd = gridFormat
        } else {
            self.postFormatInd = postFormat
        }
    }
    
    func didChangeToPostView() {
        self.postFormatInd = postFormat
    }
    
    func didChangeToGridView() {
        self.postFormatInd = gridFormat
    }
    
    func openSearch(index: Int?) {
    }
    
    func filterCaptionSelected(searchedText: String?) {
        self.tempSearchBarText = searchedText
        print("filterContentForSearchText | \(searchedText)")
        
        let tempFilter = self.viewFilter.copy() as! Filter
            self.isFiltering = self.viewFilter.isFiltering
            
         if let searchText = self.tempSearchBarText {
             tempFilter.filterCaptionArray.append(searchText)
            if !searchText.isEmptyOrWhitespace() {
                self.isFiltering = true
            }
         }
        
        Database.filterSortPosts(inputPosts: self.fetchedPosts, postFilter: tempFilter) { finalPosts in
            self.displayedPosts = finalPosts ?? []
            if !tempFilter.isFiltering {
                self.fetchedPosts = finalPosts ?? []
            }
            
            print("  ~ FINISH | filterContentForSearchText | Post \(finalPosts?.count) Posts | Pre \(self.fetchedPosts.count) | \(self.displayUser?.username) | \(tempFilter.filterCaptionArray)")
            if (finalPosts?.count ?? 0) > 0 {
                let temp = finalPosts![0] as Post
                print(temp.locationName)
            }
            
            self.paginatePostsCount = (self.isFiltering) ? self.displayedPosts.count : self.fetchedPosts.count
            self.imageCollectionView.reloadSections(IndexSet(integer: 0))
            
        }

    }

    
    @objc func headerSortSelected(sort: String) {
        self.viewFilter.filterSort = sort
        self.refreshPostsForSort()
        print("SingleUserProfile | Sort is  \(self.viewFilter.filterSort) | \(self.displayUser?.username)")
    }
    
    
    @objc func handleOptions() {
        
        print("Options Button Pressed")
        if CurrentUser.uid == displayUser?.uid {
            self.userSettings()
        } else {
            self.otherUserSettings()
        }
    }
    
    func otherUserSettings(){
        guard let curUser = self.displayUser else {return}
                
        let optionsAlert = UIAlertController(title: "User Options", message: "", preferredStyle: UIAlertController.Style.alert)
        
 //       optionsAlert.addAction(UIAlertAction(title: "Change Profile Picture", style: .default, handler: { (action: UIAlertAction!) in
 //           // Allow Editing
 //           self.editUser()
 //       }))
        
        optionsAlert.addAction(UIAlertAction(title: "Block User", style: .default, handler: { (action: UIAlertAction!) in
            // Allow Editing
            self.extBlockUser(user: curUser)
        }))
        
         optionsAlert.addAction(UIAlertAction(title: "Report User", style: .default, handler: { (action: UIAlertAction!) in
             self.extReportUser(user: curUser)
         }))
        
     
        optionsAlert.addAction(UIAlertAction(title: "Message User", style: .default, handler: { (action: UIAlertAction!) in
            self.messageUser()
        }))
     

        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        present(optionsAlert, animated: true) {
            optionsAlert.view.superview?.isUserInteractionEnabled = true
            optionsAlert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.alertClose(gesture:))))
        }

    }
    
   func userSettings(){
       guard let uid = Auth.auth().currentUser?.uid else {return}
       
       if uid != displayUserId {
           return
       }
       
       let optionsAlert = UIAlertController(title: "User Options", message: "", preferredStyle: UIAlertController.Style.alert)
       
//       optionsAlert.addAction(UIAlertAction(title: "Change Profile Picture", style: .default, handler: { (action: UIAlertAction!) in
//           // Allow Editing
//           self.editUser()
//       }))
       
       optionsAlert.addAction(UIAlertAction(title: "Edit User", style: .default, handler: { (action: UIAlertAction!) in
           // Allow Editing
           self.editUser()
       }))
       
        optionsAlert.addAction(UIAlertAction(title: "Contact Us", style: .default, handler: { (action: UIAlertAction!) in
            self.contactUs()
        }))
       
       optionsAlert.addAction(UIAlertAction(title: "Manage Subscriptions", style: .default, handler: { (action: UIAlertAction!) in
           self.openSubscriptions()
       }))
    
       optionsAlert.addAction(UIAlertAction(title: "Sign Out", style: .default, handler: { (action: UIAlertAction!) in
           self.didSignOut()
       }))
    

       optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (action: UIAlertAction!) in
           print("Handle Cancel Logic here")
       }))
       
       present(optionsAlert, animated: true) {
           optionsAlert.view.superview?.isUserInteractionEnabled = true
           optionsAlert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.alertClose(gesture:))))
       }

   }
    
    func selectUserFollowers() {
        self.extShowUserFollowers(inputUser: self.displayUser)
    }
    
    func selectUserFollowing() {
        self.extShowUserFollowing(inputUser: self.displayUser)
    }
    
    func selectUserLists() {
        self.extShowUserLists(inputUser: self.displayUser)
    }
    
    func editUser(){
        let editUserView = SignUpController()
        editUserView.delegate = self
        editUserView.editUserInd = true
        editUserView.editUser = self.displayUser
        editUserView.cancelButton.isHidden = false
//        navigationController?.pushViewController(editUserView, animated: true)
        self.present(editUserView, animated: true, completion: nil)
    }
    
    func didSignOut(){
        self.extSignOutUser()
    }
    
    
    func tapProfileImage(image: UIImage?) {
        guard let image = image else {return}
        let selectedImages = [image]
        self.extShowImage(inputImages: selectedImages)

//        var images = [SKPhoto]()
//
//        guard let selectedImages = image else {return}
//        let photo = SKPhoto.photoWithImage(selectedImages)// add some UIImage
//        images.append(photo)
//
//        // 2. create PhotoBrowser Instance, and present from your viewController.
//        SKPhotoBrowserOptions.displayCounterLabel = true
//        SKPhotoBrowserOptions.displayBackAndForwardButton = true
//        SKPhotoBrowserOptions.displayAction = true
//        SKPhotoBrowserOptions.actionButtonTitles = ["Edit Photo"]
//        SKPhotoBrowserOptions.swapCloseAndDeleteButtons = false
//        //        SKPhotoBrowserOptions.enableSingleTapDismiss  = true
//        SKPhotoBrowserOptions.bounceAnimation = true
//        SKPhotoBrowserOptions.displayDeleteButton = true
//
//        browser = SKPhotoBrowser(photos: images)
//        browser.delegate = self
//        //        browser.updateCloseButton(#imageLiteral(resourceName: "checkmark_teal").withRenderingMode(.alwaysOriginal), size: CGSize(width: 50, height: 50))
//
//        browser.initializePageIndex(0)
//        present(browser, animated: true, completion: {})
    }
    
    func didTapPicture(post: Post) {
        print("Function: \(#function), line: \(#line)")
        self.extTapPicture(post: post)
    }
    
    func didTapListCancel(post: Post) {
        print("Function: \(#function), line: \(#line)")
    }
    
    func didTapBookmark(post: Post) {
        print("Function: \(#function), line: \(#line)")
        let sharePhotoListController = SharePhotoListController()
        sharePhotoListController.uploadPost = post
        sharePhotoListController.isBookmarkingPost = true
        sharePhotoListController.delegate = self
        navigationController?.pushViewController(sharePhotoListController, animated: true)
    }
    
    func didTapUser(post: Post) {
        print("Function: \(#function), line: \(#line)")
        self.extTapUser(post: post)
    }
    
    func didTapComment(post: Post) {
        print("Function: \(#function), line: \(#line)")
        self.extTapComment(post: post)
    }
    
    func didTapUserUid(uid: String) {
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = uid
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapLocation(post: Post) {
        print("Function: \(#function), line: \(#line)")
        self.extTapLocation(post: post)
    }
    
    func didTapMessage(post: Post) {
        print("Function: \(#function), line: \(#line)")
        self.extTapMessage(post: post)
    }
    
    func didTapList(list: List?) {
        print("Function: \(#function), line: \(#line)")
        guard let list = list else {return}
        if list.newNotificationsCount > 0 {
            list.clearAllNotifications()
        }
        self.extTapList(list: list)
    }
    
    @objc func postEdited(_ notification: NSNotification) {
        let postId = (notification.userInfo?["updatedPostId"] ?? "")! as! String
        Database.fetchPostWithPostID(postId: postId) { (post, error) in
            if let post = post {
                self.refreshPost(post: post)
            }
        }
    }
    
    func refreshPost(post: Post) {
        print("Function: \(#function), line: \(#line)")
        if let displayIndex = fetchedPosts.firstIndex(where: { (fetchedPost) -> Bool in
            fetchedPost.id == post.id })
        {
            fetchedPosts[displayIndex] = post
        }
        
        if let displayIndex = displayedPosts.firstIndex(where: { (fetchedPost) -> Bool in
            fetchedPost.id == post.id })
        {
            displayedPosts[displayIndex] = post
        }
        
        
        // Update Cache
        let postId = post.id
        postCache[postId!] = post
        self.fetchPostsForUser()
    }
    
    
    func userOptionPost(post: Post) {
        let optionsAlert = UIAlertController(title: "User Options", message: "", preferredStyle: UIAlertController.Style.alert)
        
        optionsAlert.addAction(UIAlertAction(title: "Edit Post", style: .default, handler: { (action: UIAlertAction!) in
            // Allow Editing
            self.editPost(post: post)
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Delete Post", style: .default, handler: { (action: UIAlertAction!) in
            self.deletePost(post: post)
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        present(optionsAlert, animated: true, completion: nil)
    }
    
    func editPost(post:Post){
        let editPost = MultSharePhotoController()
        
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
            let index = self.displayedPosts.firstIndex { (filteredpost) -> Bool in
                filteredpost.id  == post.id
            }
            
            let filteredindexpath = IndexPath(row:index!, section: 0)
            self.displayedPosts.remove(at: index!)
            
            // Remove from Fetched View
            let fetchedIndex = self.fetchedPosts.firstIndex { (filteredpost) -> Bool in
                filteredpost.id  == post.id
            }
            
            let fetchedindexpath = IndexPath(row:fetchedIndex!, section: 0)
            self.fetchedPosts.remove(at: fetchedIndex!)
            
            if self.isFiltering {
                self.imageCollectionView.deleteItems(at: [filteredindexpath])
            } else {
                self.imageCollectionView.deleteItems(at: [fetchedindexpath])
            }
            Database.deletePost(post: post)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        present(deleteAlert, animated: true, completion: nil)
        
    }
    
    func contactUs() {
        
        let deleteAlert = UIAlertController(title: "Contact Us", message: "Hi there. Please email us at weizouang@gmail.com if you have any feedback or ideas! We would love to hear how we can make Legit better for you!", preferredStyle: UIAlertController.Style.alert)
        deleteAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                print("Contact US - OK")

        }))
        

        present(deleteAlert, animated: true, completion: nil)
        
    }
    
    
    func didTapExtraTag(tagName: String, tagId: String, post: Post) {
        print("Function: \(#function), line: \(#line)")
        guard let uid = Auth.auth().currentUser?.uid else {return}
        // List Tag Selected
        Database.checkUpdateListDetailsWithPost(listName: tagName, listId: tagId, post: post, completion: { (fetchedList) in
            if fetchedList == nil {
                // List Does not Exist
                self.alert(title: "List Display Error", message: "List Does Not Exist Anymore")
            } else {
                if fetchedList?.publicList == 0 && fetchedList?.creatorUID != uid {
                    self.alert(title: "List Display Error", message: "List Is Private")
                } else {
                    let listViewController = ListViewController()
                    listViewController.currentDisplayList = fetchedList
                    self.navigationController?.pushViewController(listViewController, animated: true)
                }
            }
        })
    }
    
    func displayPostSocialUsers(post: Post, following: Bool) {
        print("Display Vote Users| Following: ",following)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayUser = true
        postSocialController.displayUserFollowing = following
        postSocialController.inputPost = post
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    func displayPostSocialLists(post: Post, following: Bool) {
        print("Display Lists| Following: ",following)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayList = true
        postSocialController.displayUserFollowing = (post.followingList.count > 0)
        postSocialController.inputPost = post
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    func filterControllerSelected(filter: Filter?) {
        print("SingleUserProfileView | Received Filter | \(filter?.searchTerms)")
        guard let filter = filter else {return}
        self.viewFilter = filter
        self.refreshPostsForFilter()
    }
    
    func didTapSearchButton() {
        print("Tap Search | \(self.displayedPosts.count) Tags | \(self.viewFilter.searchTerms)")
        searchViewController.delegate = self
        searchViewController.inputViewFilter = self.viewFilter

        searchViewController.noFilterTagCounts = self.noFilterTagCounts
        searchViewController.currentPostTagCounts = self.currentPostTagCounts
        searchViewController.currentRatingCounts = self.currentPostRatingCounts
        searchViewController.searchBar.text = ""
        
        searchViewController.viewWillAppear(true)

        UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.transitionCrossDissolve, animations:
            {
                self.searchViewController.presentView()
        }
            , completion: { (finished: Bool) in
        })
    }
    
    func didTapAddTag(addTag: String) {
        let tempAddTag = addTag.lowercased()
        var tempArray = self.viewFilter.filterCaptionArray
        
        if tempArray.count == 0 {
            tempArray.append(tempAddTag)
            print("\(tempAddTag) | Add To Search | \(tempArray)")
        } else if tempArray.contains(tempAddTag) {
            let oldCount = tempArray.count
            tempArray.removeAll { (text) -> Bool in
                text == tempAddTag
            }
            let dif = tempArray.count - oldCount
            print("\(tempAddTag) Exists | Remove \(dif) from Search | \(tempArray)")
        } else {
            tempArray.append(tempAddTag)
            print("\(tempAddTag) | Add To Search | \(tempArray)")
        }
        
        self.viewFilter.filterCaptionArray = tempArray
        self.tempSearchBarText = nil
        self.refreshPostsForFilter()
    }
    
    func didRemoveTag(tag: String) {
        if tag == self.viewFilter.filterLocationSummaryID {
            self.viewFilter.filterLocationSummaryID = nil
            print("Remove Search | \(tag) | City | \(self.viewFilter.filterLocationSummaryID)")
        } else if tag == self.viewFilter.filterLocationName {
            self.viewFilter.filterLocationName = nil
            self.viewFilter.filterGoogleLocationID = nil
            print("Remove Search | \(tag) | Location | \(self.viewFilter.filterLocationName)")

        } else if self.viewFilter.filterCaptionArray.count > 0 {
           var tempArray = self.viewFilter.filterCaptionArray
            let tagText = tag.lowercased()
            if tempArray.contains(tagText) {
                let oldCount = tempArray.count
                tempArray.removeAll { (text) -> Bool in
                    text == tagText
                }
                print("didRemoveTag | Remove \(tagText) from Search | \(tempArray)")
            }
            self.viewFilter.filterCaptionArray = tempArray
        }

        self.refreshPostsForFilter()
    }
    
    
    func didTapCell(tag: String) {
        self.didTapAddTag(addTag: tag)
    }
    


    func didTapEmptyCell() {
        if self.isFiltering {
            self.handleRefresh()
        } else {
            NotificationCenter.default.post(name: MainTabBarController.OpenAddNewPhoto, object: nil)
        }
    }
    
    
    
    func didTapUserEmojiStatus(){
        selectStatusEmoji()
    }
    
    func didTapCreateNewList() {
        print("Did Tap Create New List | User Profile")
        self.extCreateNewList()
    }
    
    func didTapUserStatus(){

        let statusAlert = UIAlertController(title: "User Status", message: "Update Your Status", preferredStyle: UIAlertController.Style.alert)
        
        //2. Add the text field. You can configure it however you need.
        statusAlert.addTextField { (textField) in
            textField.text = self.displayUser?.status ?? ""
            textField.placeholder = "Add New User Status"
        }
        
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        statusAlert.addAction(UIAlertAction(title: "Update", style: .default, handler: { [weak statusAlert] (_) in
            guard let uid = Auth.auth().currentUser?.uid else {return}
            let textField = statusAlert?.textFields![0].text // Force unwrapping because we know it exists.
            
            if self.displayUser?.status != "" && textField != "" {
                self.displayUser?.status = textField
                Database.updateUserStatus(userUid: uid, status: textField ?? "")
                self.alert(title: "User Status", message: "Update Success 🎉")
                self.imageCollectionView.reloadData()
            } else {
                print("No Status Update, both status nil")
            }


        }))
        
        statusAlert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        
        present(statusAlert, animated: true) {
            statusAlert.view.superview?.isUserInteractionEnabled = true
            statusAlert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.alertClose(gesture:))))
        }
        
    }
    
    func selectStatusEmoji() {
        let emojiTable = SelectEmojiTableView()
        emojiTable.delegate = self
        emojiTable.inputUser = self.displayUser
        navigationController?.pushViewController(emojiTable, animated: true)

    }
    
    func statusEmojiSelected(emoji: String?) {
        guard let uid = Auth.auth().currentUser?.uid else {return}

        self.displayUser?.emojiStatus = emoji
        Database.updateUserEmojiStatus(userUid: uid, emoji: emoji)
        self.imageCollectionView.reloadData()
        
        if emoji != "" && emoji != nil {
            self.didTapUserStatus()
        }
    }

    
    @objc func openInbox() {
        let inboxController = InboxController(collectionViewLayout: UICollectionViewFlowLayout())
        self.navigationController?.pushViewController(inboxController, animated: true)
    }
    
    func didUpdateUserInfo(info: String?) {
        let deleteAlert = UIAlertController(title: "User Update", message: "Updating User Description to \n \(info)", preferredStyle: UIAlertController.Style.alert)
        deleteAlert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { (action: UIAlertAction!) in
            if (info != blankUserDesc) && (info !=  self.displayUser?.description) {
                Database.updateUserDescription(userUid: CurrentUser.uid, description: info)
                self.displayUser?.description = info
                self.imageCollectionView.reloadData()
            }
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
            self.imageCollectionView.reloadData()
        }))
        present(deleteAlert, animated: true, completion: nil)
    }
    
    
    func editUserInfo() {
        let alertController = UIAlertController(title: "Update User Info \n\n\n\n\n\n", message: nil, preferredStyle: UIAlertController.Style.alert)

        let margin:CGFloat = 8.0
        let rect = CGRect(x: margin, y: margin + 40, width: alertController.view.bounds.size.width - 120 - margin * 4.0, height: 100.0)
        let customView = UITextView(frame: rect)

        customView.backgroundColor = UIColor.clear
        customView.font = UIFont(name: "Helvetica", size: 15)
        customView.delegate = self
        if (displayUser?.description?.count) ?? 0 > 0 {
            customView.text = displayUser?.description
            customView.textColor = UIColor.black
        } else {
            customView.text = blankUserDesc
            customView.textColor = UIColor.lightGray
        }


        //  customView.backgroundColor = UIColor.greenColor()
        alertController.view.addSubview(customView)

        
        let somethingAction = UIAlertAction(title: "Update", style: UIAlertAction.Style.default, handler: {(alert: UIAlertAction!) in
            let info = customView.text
            if (info != blankUserDesc) && (info !=  self.displayUser?.description) {
                Database.updateUserDescription(userUid: CurrentUser.uid, description: info)
                self.displayUser?.description = info
                self.imageCollectionView.reloadData()
            }
            print(customView.text)

        })

        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.destructive, handler: {(alert: UIAlertAction!) in print("cancel")})

        alertController.addAction(somethingAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion:{
            customView.becomeFirstResponder()
            alertController.view.frame.origin.y = 200
//            UIView.animate(withDuration: 0, animations: {
//                alertController.view.frame.origin.y = 200
//            })
        })
    }
    
    
    
}

extension SingleUserProfileViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    
    
    
}

extension SingleUserProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, EmptyCellDelegate, SelectEmojiTableViewDelegate {
    
    func setupCollectionView() {
        imageCollectionView.backgroundColor = UIColor.backgroundGrayColor()
        imageCollectionView.register(SingleUserProfileHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerId)
        imageCollectionView.register(FullPictureCell.self, forCellWithReuseIdentifier: fullPostCellId)
        imageCollectionView.register(TestGridPhotoCell.self, forCellWithReuseIdentifier: gridCellId)
        imageCollectionView.register(EmptyCell.self, forCellWithReuseIdentifier: emptyCellId)
        imageCollectionView.register(TestHomePhotoCell.self, forCellWithReuseIdentifier: testCellId)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        imageCollectionView.refreshControl = refreshControl
        imageCollectionView.alwaysBounceVertical = true
        imageCollectionView.keyboardDismissMode = .onDrag
    }
    
    func paginatePosts(){
        
        if self.isPresented {
            //Currently Active. Don't Refresh
            //print("User Profile Controller | paginatePosts | Don't Dismiss Progress Bar, not in view")
            SVProgressHUD.dismiss()
        }
        
        let paginateFetchPostSize = 4
        var totalPostCount = self.isFiltering ? self.displayedPosts.count : self.fetchedPosts.count
        self.paginatePostsCount = min(self.paginatePostsCount + paginateFetchPostSize, totalPostCount)
        print("User Profile Paginate \(self.paginatePostsCount) : \(self.displayedPosts.count) | Finish: \(self.isFinishedPaging)")
        
        self.finishPaginationCheck()

    }
    
    
    func finishPaginationCheck(){
        
        if self.paginatePostsCount == self.displayedPosts.count {
            self.isFinishedPaging = true
            
            if self.isPresented {
                //Currently Active. Don't Refresh
                //print("User Profile Controller | finishPaginationCheck | Don't Dismiss Progress Bar, not in view")
                SVProgressHUD.dismiss()
            }
        } else {
            self.isFinishedPaging = false
        }
        
        if self.displayedPosts.count == 0 && self.isFinishedPaging == true {
           // print("User Profile Controller | Pagination: No Results | Paging: \(self.isFinishedPaging) | \(self.displayedPosts.count) Posts")
        }
        else if self.displayedPosts.count == 0 && self.isFinishedPaging != true {
            //print("User Profile Controller | Pagination: No Results | Paging: \(self.isFinishedPaging) | \(self.displayedPosts.count) Posts")
            self.paginatePosts()
        } else {
            //print("User Profile Controller | Paginating \(self.paginatePostsCount) | \(self.displayedPosts.count) Posts | Finish: \(self.isFinishedPaging)")
            DispatchQueue.main.async(execute: {
//                self.imageCollectionView.reloadSections(IndexSet(integer: 1))

                self.imageCollectionView.reloadData()

//                if self.paginatePostsCount == 0 && !self.isFinishedPaging {
//
//                } else {
//                    self.imageCollectionView.reloadData()
//                }
//
//                if self.navigationController?.visibleViewController == self {
//                    print("User Profile Controller | finishPaginationCheck | Don't Dismiss Progress Bar, not in view")
//                    SVProgressHUD.dismiss()
//                }
                
                if self.isPresented {
                    //Currently Active. Don't Refresh
                    //print("User Profile Controller | finishPaginationCheck | Don't Dismiss Progress Bar, not in view")
                    SVProgressHUD.dismiss()
                }
            })

        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 15
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 15
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 15, bottom: 0, right: 15)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            var postCount = (isFiltering) ? displayedPosts.count : fetchedPosts.count
            self.showEmpty = postCount == 0
            postCount = self.showEmpty ? 1 : self.paginatePostsCount
            return postCount
        } else {
            return 0
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
        
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            
            if showEmpty {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emptyCellId, for: indexPath) as! EmptyCell
                cell.isFiltering = self.isFiltering
                cell.pageLoadUp = self.pageLoadUp
                cell.delegate = self
                return cell
            }
            else
            {
                if indexPath.item == self.paginatePostsCount - 1 && !isFinishedPaging{
                    paginatePosts()
                }
                
                if fetchedPosts.count == 0 {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: fullPostCellId, for: indexPath) as! FullPictureCell
                    return cell
                }
                
                var displayPost = (isFiltering) ? displayedPosts[indexPath.item] : fetchedPosts[indexPath.item]
                

                if self.postFormatInd == 1 {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: fullPostCellId, for: indexPath) as! FullPictureCell
                    
                    cell.post = displayPost
                    cell.enableDelete = true
                    
                    // Can't Be Selected
                    
                    if self.viewFilter.filterLocation != nil && cell.post?.locationGPS != nil {
                        cell.post?.distance = Double((cell.post?.locationGPS?.distance(from: (self.viewFilter.filterLocation!)))!)
                    }
                    cell.showDistance = self.viewFilter.filterSort == defaultNearestSort
                    
                    cell.delegate = self
                    cell.currentImage = 1
                    return cell
                }
                    
                else if self.postFormatInd == 0 {
//                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: gridCellId, for: indexPath) as! TestGridPhotoCell
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: testCellId, for: indexPath) as! TestHomePhotoCell

                    cell.delegate = self
                    cell.showDistance = self.viewFilter.filterSort == defaultNearestSort


                    cell.post = displayPost
                    cell.enableCancel = false
                    cell.layer.cornerRadius = 1
                    cell.layer.masksToBounds = true
                    
                    cell.showUserProfileImage = !(self.viewFilter.filterSort == defaultRecentSort)
                    cell.locationDistanceLabel.textColor = UIColor.mainBlue()
                    cell.layer.backgroundColor = UIColor.clear.cgColor
                    cell.layer.shadowColor = UIColor.lightGray.cgColor
                    cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
                    cell.layer.shadowRadius = 2.0
                    cell.layer.shadowOpacity = 0.5
                    cell.layer.masksToBounds = false
                    cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: 14).cgPath
                    
                    
                    return cell
                }
                    
                else {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: gridCellId, for: indexPath) as! TestGridPhotoCell
                    cell.delegate = self
                    cell.post = displayPost
                    return cell
                }
            }
        }
        else
        {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: gridCellId, for: indexPath) as! TestGridPhotoCell
            return cell
        }
        
}
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if indexPath.section == 0 {
            if self.showEmpty
            {
                return CGSize(width: view.frame.width - 30, height: view.frame.width)
            }
            else if self.postFormatInd == 1 {
                var height: CGFloat = 35 //headerview = username userprofileimageview
                height += view.frame.width  // Picture
                height += 160
                height += 30
                height += 30 // Emoji Array + Star Rating
                //            height += 25    // Date Bar
                return CGSize(width: view.frame.width - 16, height: height)
            } else if self.postFormatInd == 0 {
                // GRID VIEW
//                let width = (view.frame.width - 2 - 30) / 2
//
//                return CGSize(width: width, height: width)
                
                let width = (view.frame.width - 30 - 15) / 2

                let height = (GridCellImageHeightMult * width + GridCellEmojiHeight)
                return CGSize(width: width, height: height)
                
            } else {
                return CGSize(width: view.frame.width, height: view.frame.width)
            }
        } else {
            return CGSize.zero
        }


    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerId, for: indexPath) as! SingleUserProfileHeader
        
        if indexPath.section == 0 {

            if let selectedIndex = HeaderSortOptions.firstIndex(of: self.viewFilter.filterSort ?? HeaderSortOptions[0]) {
                if header.sortSegmentControl.selectedSegmentIndex != selectedIndex {
//                    print("Header Load | \(selectedIndex) | \(self.viewFilter.filterSort) | CUR: \(header.sortSegmentControl.selectedSegmentIndex)")
                    header.sortSegmentControl.selectedSegmentIndex = selectedIndex
//                    header.reloadSegmentControl()
                }
            }
            
            header.user = self.displayUser
            header.displayPostCount = displayedPosts.count
            header.viewFilter = self.viewFilter
            header.postFormatInd = self.postFormatInd
            header.userEmojiCounts = self.noFilterTagCounts.captionCounts
            header.delegate = self
            
            header.searchBar.viewFilter = self.viewFilter
            header.searchBar.filteredPostCount = displayedPosts.count
            header.searchBar.displayedEmojisCounts = self.first100EmojiCounts

        }
        
//        header.isHidden = !(indexPath.section == 0)
        
        
        return header
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        return CGSize(width: view.frame.width, height: 220)
        if section == 0 {
            // Get the view for the first header
            let indexPath = IndexPath(row: 0, section: section)
            let headerView = self.collectionView(collectionView, viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader, at: indexPath)

            // Use this view to calculate the optimal size based on the collection view's width
            return headerView.systemLayoutSizeFitting(CGSize(width: collectionView.frame.width, height: UIView.layoutFittingExpandedSize.height),
                                                      withHorizontalFittingPriority: .required, // Width is fixed
                                                      verticalFittingPriority: .fittingSizeLevel) // Height can be as large as needed
            
        } else {
            return CGSize.zero
        }

    }

    
    
}
