//
//  ManageListController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/28/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

import DropDown
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage


class NewTabListViewController: UIViewController {
    
    var displayUserId: String? = nil {
        didSet {
            guard let displayUserId = displayUserId else {return}
            if displayUser?.uid != displayUserId {
                Database.fetchUserWithUID(uid: displayUserId) { (user) in
                    self.displayUser = user
                }
            }
        }
    }
    var displayUser: User? = nil {
        didSet {
            guard let displayUser = displayUser else {return}
            if displayUser.uid != displayUserId {
                displayUserId = displayUser.uid
            }
            updateListObjects()
        }
    }
    
// PROFILE HEADER
    let navHeaderView = UIView()

    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .white
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
//        iv.layer.cornerRadius = 50/2
//        iv.layer.masksToBounds = true
        return iv
    }()
    var profileImageViewWidth: NSLayoutConstraint?
    
    lazy var profileHeaderLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Your Lists"
        ul.isUserInteractionEnabled = true
        ul.numberOfLines = 0
        ul.backgroundColor = UIColor.clear
        ul.textAlignment = NSTextAlignment.left
        ul.font = UIFont(name: "Poppins-Bold", size: 16)
        ul.textColor = UIColor.darkGray
        return ul
    }()
    
    let addNewListButton: UIButton = {
        let button = UIButton()
        button.setTitle("CREATE LIST", for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 12)!
        button.setTitleColor(UIColor.ianBlackColor(), for: .normal)
        button.setImage(#imageLiteral(resourceName: "createNewList_Icon").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.ianLegitColor()
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(initAddList), for: .touchUpInside)
        button.semanticContentAttribute = .forceRightToLeft
        return button
    }()
    
    var displayBack: Bool = false {
        didSet {
            setupNavigationItems()
        }
    }
    
    let navBackButton = navBackButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))

    var navSearchButton: UIButton = TemplateObjects.NavSearchButton()

    
// BOOKMARKS
    let bookmarkContainer = UIView()
    lazy var bookmarkHeaderLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Bookmark"
        ul.font = UIFont(name: "Poppins-Bold", size: 30)
        ul.textColor = UIColor.ianBlackColor()
        ul.textAlignment = NSTextAlignment.left
        ul.numberOfLines = 1
        ul.backgroundColor = UIColor.white
        return ul
    }()
    var bookmarkListView = ListPostSummaryCollectionViewController()
    
    
// CREATED LIST
    let createdListContainer = UIView()
    lazy var createdListLabel: UILabel = {
        let ul = UILabel()
        ul.text = "You Created Lists"
        ul.backgroundColor = UIColor.clear
        ul.font = UIFont(name: "Poppins-Bold", size: 30)
        ul.textColor = UIColor.ianBlackColor()
        ul.textAlignment = NSTextAlignment.left
        ul.numberOfLines = 1
        ul.backgroundColor = UIColor.white
        return ul
    }()
    var createdListView = ListSummaryView()

    
// FOLLOWED LIST
    let followedListContainer = UIView()
    var followedListView = ListSummaryView()
    
    @objc func updateListObjects() {
        refreshHeaderLabels()
        
    // Bookmark
        if let bookmarkId = CurrentUser.bookmarkListId {
            bookmarkListView.currentDisplayListId = bookmarkId
            bookmarkListView.isHidden = !(self.displayUser?.uid == Auth.auth().currentUser?.uid)
            print("Load bookmarkId | \(bookmarkId) | \(bookmarkListView.isHidden)")

        } else {
            bookmarkListView.isHidden = false
        }
        
        setupCreatedList()
        setupFollowedList()
    }
    
    func refreshHeaderLabels() {
        guard let user = self.displayUser else {return}
        let url = user.profileImageUrl
        profileImageView.loadImage(urlString: url)
        profileHeaderLabel.text = user.username
        profileHeaderLabel.sizeToFit()
    }

// RATING EMOJI FILTER POST
    let filterRatingEmojiView = PostByRatingEmojiViewController()
    

    var headerViewHeight: CGFloat = 40
    
    override func viewWillAppear(_ animated: Bool) {
        setupNavigationItems()
        updateListObjects()
    }
    
    let scrollview: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = UIColor.white
        sv.isScrollEnabled = true
        sv.showsVerticalScrollIndicator = false
        return sv
    }()
    
    
    var bookmarkImageHeight: CGFloat = 140
    var bookmarkImageDetailHeight: CGFloat = 30 //50
    var bookmarkHeaderHeight: CGFloat = 35
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        NotificationCenter.default.addObserver(self, selector: #selector(updateListObjects), name: MainTabBarController.CurrentUserListLoaded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newListEventRefresh), name:TabListViewController.refreshListNotificationName, object: nil)

        self.view.backgroundColor = UIColor.backgroundGrayColor()
        NotificationCenter.default.addObserver(self, selector: #selector(newListEventRefresh), name: TabListViewController.newFollowedListNotificationName, object: nil)

    // HEADER VIEW
        self.setupHeader()
        
        let div = UIView()
        div.backgroundColor = UIColor.darkGray
        navHeaderView.addSubview(div)
        div.anchor(top: navHeaderView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 3)
        
            
    // CREATED LIST
        setupCreatedList()
        view.addSubview(createdListContainer)
        createdListContainer.anchor(top: navHeaderView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        
        createdListContainer.addSubview(createdListView)
        createdListView.anchor(top: createdListContainer.topAnchor, left: createdListContainer.leftAnchor, bottom: createdListContainer.bottomAnchor, right: createdListContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    // FOLLOWED LIST
        setupFollowedList()
        view.addSubview(followedListContainer)
        followedListContainer.anchor(top: createdListContainer.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        followedListContainer.addSubview(followedListView)
        followedListView.anchor(top: followedListContainer.topAnchor, left: followedListContainer.leftAnchor, bottom: followedListContainer.bottomAnchor, right: followedListContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
    
    // BOTTOM DIV

//        let bottomDiv = UIView()
//        view.addSubview(bottomDiv)
//        bottomDiv.anchor(top: followedListContainer.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 2)
//        bottomDiv.backgroundColor = UIColor.rgb(red: 221, green: 221, blue: 221)
//
        

        
    // BOOKMARK

        bookmarkContainer.layer.borderColor = UIColor.lightGray.cgColor
//        bookmarkContainer.layer.borderColor = UIColor.ianLegitColor().cgColor

        bookmarkContainer.layer.borderWidth = 0
        bookmarkContainer.backgroundColor = UIColor.ianWhiteColor()
        bookmarkContainer.layer.applySketchShadow(color: UIColor(red: 0, green: 0, blue: 0, alpha: 1), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
        bookmarkContainer.backgroundColor = UIColor.clear

        view.addSubview(bookmarkContainer)
        bookmarkContainer.anchor(top: followedListView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 45, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

        
        bookmarkContainer.addSubview(bookmarkListView)
        bookmarkListView.anchor(top: bookmarkContainer.topAnchor, left: bookmarkContainer.leftAnchor, bottom: bookmarkContainer.bottomAnchor, right: bookmarkContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 15, paddingRight: 0, width: 0, height: bookmarkImageHeight + bookmarkImageDetailHeight + bookmarkHeaderHeight + 40 + 10)
//        bookmarkListView.anchor(top: bookmarkContainer.topAnchor, left: bookmarkContainer.leftAnchor, bottom: bookmarkContainer.bottomAnchor, right: bookmarkContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 15, paddingRight: 0, width: 0, height: bookmarkImageHeight + bookmarkImageDetailHeight + bookmarkHeaderHeight + 15)

        
        bookmarkListView.imageHeight = bookmarkImageHeight
        bookmarkListView.imageDetailHeight = bookmarkImageDetailHeight
        bookmarkListView.headerHeight = bookmarkHeaderHeight
        bookmarkListView.cell.backgroundColor = UIColor.clear
//        bookmarkListView = ListPostSummaryCollectionViewController()
        bookmarkListView.listHeaderLabel.titleLabel?.font = UIFont(font: .avenirNextBold, size: 20)
//        bookmarkListView.listHeaderLabel.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 22)
        bookmarkListView.listHeaderLabel.setTitleColor(UIColor.ianLegitColor(), for: .normal)
//        bookmarkListView.listHeaderLabel.font = UIFont(name: "Poppins-Bold", size: 20)
        bookmarkListView.delegate = self
        bookmarkListView.showDetails = true
        
//        bookmarkListView.listHeaderLabel.textColor = UIColor.oldIanLegitColor()

        updateListObjects()
        

        
        /*
        setupFilterRatingEmojiView()
        view.addSubview(filterRatingEmojiView)
        filterRatingEmojiView.anchor(top: followedListContainer.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 30, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        */
        
    }
    
    func setupHeader() {
        setupNavigationItems()
        view.addSubview(navHeaderView)
        navHeaderView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: UIApplication.shared.statusBarFrame.height, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: headerViewHeight)
        
        navHeaderView.addSubview(addNewListButton)
        addNewListButton.anchor(top: nil, left: nil, bottom: nil, right: navHeaderView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        addNewListButton.centerYAnchor.constraint(equalTo: navHeaderView.centerYAnchor).isActive = true
        addNewListButton.sizeToFit()
        addNewListButton.backgroundColor = UIColor.clear
        addNewListButton.layer.cornerRadius = 5
        addNewListButton.layer.masksToBounds = true
        addNewListButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        addNewListButton.titleLabel?.font =  UIFont(font: .avenirNextBold, size: 10)
//        addNewListButton.contentMode = .scaleToFill
        addNewListButton.sizeToFit()

    
        let profileHeaderView = UIView()
        profileHeaderView.addSubview(profileImageView)
        profileImageView.anchor(top: profileHeaderView.topAnchor, left: profileHeaderView.leftAnchor, bottom: profileHeaderView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: headerViewHeight - 10, height: headerViewHeight - 10)
        profileImageView.layer.cornerRadius = (headerViewHeight - 10)/2
        profileImageView.layer.masksToBounds = true
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapProfile)))
        
        profileHeaderView.addSubview(profileHeaderLabel)
        profileHeaderLabel.anchor(top: nil, left: profileImageView.rightAnchor, bottom: nil, right: profileHeaderView.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        profileHeaderLabel.centerYAnchor.constraint(equalTo: profileHeaderView.centerYAnchor).isActive = true
        profileHeaderLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapProfile)))
        profileHeaderLabel.textColor = UIColor.ianBlackColor()
        
        navHeaderView.addSubview(profileHeaderView)
        profileHeaderView.anchor(top: navHeaderView.topAnchor, left: navHeaderView.leftAnchor, bottom: navHeaderView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        profileHeaderView.rightAnchor.constraint(lessThanOrEqualTo: addNewListButton.leftAnchor, constant: 10).isActive = true
        

        refreshHeaderLabels()
    }

    
    func setupCreatedList() {
        print("setupCreatedList | NewTabListController")
        createdListView.refreshAll()
        createdListView.displayFollowedList = false
        createdListView.showUser = false
        createdListView.user = self.displayUser
        createdListView.delegate = self
        createdListView.sortListByDate = true
        createdListView.listHeaderLabel.font = UIFont(name: "Poppins-Bold", size: 20)
        createdListView.listHeaderLabel.font = UIFont(font: .avenirNextBold, size: 20)


    }
    
    func setupFollowedList() {
        print("setupFollowedList | NewTabListController")
        followedListView.refreshAll()
        followedListView.displayFollowedList = true
        followedListView.showUser = false
        followedListView.user = self.displayUser
        followedListView.delegate = self
        followedListView.sortListByDate = true
        followedListView.listHeaderLabel.font = UIFont(name: "Poppins-Bold", size: 20)
        followedListView.listHeaderLabel.font = UIFont(font: .avenirNextBold, size: 20)

    }
    
    func setupFilterRatingEmojiView() {
        filterRatingEmojiView.refreshAll()
        filterRatingEmojiView.delegate = self
        filterRatingEmojiView.user = self.displayUser
    }

    func setupNavigationItems(){
//        navigationItem.title = "Manage Lists"

        self.navigationController?.view.backgroundColor = UIColor.white
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationController?.navigationBar.layoutIfNeeded()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.isNavigationBarHidden = !displayBack
        
        // Nav Back Button
        navBackButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        let backButton = UIBarButtonItem.init(customView: navBackButton)
        
        if displayBack {
            self.navigationItem.leftBarButtonItem = backButton
        } else {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem()
        }
        
        
        // PROFILE HEADER
//        let barButton1 = UIBarButtonItem.init(customView: profileHeaderLabel)
//        navigationItem.leftBarButtonItem = barButton1
//
//
//        addNewListButton.addTarget(self, action: #selector(initAddList), for: .touchUpInside)
//        let barButton2 = UIBarButtonItem.init(customView: addNewListButton)
//        navigationItem.rightBarButtonItem = barButton2
    }


    @objc func initAddList(){
        self.extCreateNewList()
    }

    
    @objc func newListEventRefresh(){
        self.updateListObjects()
    }


}

extension NewTabListViewController: ListPostSummaryDelegate, SinglePostViewDelegate, ListSummaryDelegate {
    func doShowListView() {
        
    }
    
    func doHideListView() {
        
    }
    
    
    func didTapAddList() {
        self.extCreateNewList()
    }
    
    func didTapList(list: List?) {
        guard let list = list else {return}
        if list.newNotificationsCount > 0 {
            list.clearAllNotifications()
        }
        self.extTapList(list: list)
        
//        let listViewController = ListViewController()
//        let listViewController = LegitListViewController()
//        let listViewController = SingleListViewController()
//
//        listViewController.currentDisplayList = list
//        listViewController.refreshPostsForFilter()
//        print("NewTabListView | goToList | \(list.name)| \(list.id)")
//        self.navigationController?.pushViewController(listViewController, animated: true)
    }
    
    func didTapUser(user: User?) {
        guard let user = user else {return}
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = user.uid
        print("NewTabListView | goToUser | \(user.username) |\(user.uid)")
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    


    func didTapPicture(post: Post?) {
        guard let post = post else {return}
        let pictureController = SinglePostView()
        if let tempPost = postCache[post.id!] {
            pictureController.post = tempPost
        } else {
            pictureController.post = post
        }
        
        pictureController.delegate = self
        navigationController?.pushViewController(pictureController, animated: true)
    }
    
    @objc func didTapProfile() {
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = self.displayUser?.uid
        navigationController?.pushViewController(userProfileController, animated: true)
    }
        
    func refreshPost(post: Post) {
        
    }


}

