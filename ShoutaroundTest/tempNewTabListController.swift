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


class TempNewTabListViewController: UIViewController {
    
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
        ul.font = UIFont(name: "Poppins-Bold", size: 20)
        ul.textColor = UIColor.ianBlackColor()
        return ul
    }()
    
    let createNewListButton: UIButton = {
        let button = UIButton()
        button.setTitle(" CREATE NEW LIST", for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 12)!
        button.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        button.setImage(#imageLiteral(resourceName: "createNewList_Icon").withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
        button.tintColor = UIColor.ianLegitColor()
        button.layer.borderColor = button.titleColor(for: .normal)?.cgColor
        button.layer.borderWidth = 1
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
//        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        button.addTarget(self, action: #selector(initAddList), for: .touchUpInside)
        return button
    }()
    
    var displayBack: Bool = false {
        didSet {
            setupNavigationItems()
        }
    }
    
    let navBackButton = navBackButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))

    
    
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
    
    lazy var bookmarkSortButton: UIButton = {
        let button = UIButton(type: .system)
        let img = #imageLiteral(resourceName: "sort_new")
        button.setImage(img.withRenderingMode(.alwaysOriginal), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.setTitleColor(UIColor.ianBlackColor(), for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 12)
//        button.semanticContentAttribute = .forceRightToLeft
        button.tintColor = UIColor.ianLegitColor()
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.layer.borderWidth = 0
        button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 5, bottom: 3, right: 5)
        button.addTarget(self, action: #selector(toggleBookmarkSort), for: .touchUpInside)
        button.semanticContentAttribute = .forceRightToLeft
        return button
    }()
    
    
    @objc func toggleBookmarkSort() {
        self.bookmarkListView.sortListByDate = !self.bookmarkListView.sortListByDate
        self.bookmarkListView.refreshListSortButton()
        self.refreshBookmarkSortButton()
    }
    
    func refreshBookmarkSortButton() {
        let title = self.bookmarkListView.sortListByDate ? "Date " : "Distance "
        self.bookmarkSortButton.setTitle(title, for: .normal)
        self.bookmarkSortButton.sizeToFit()
    }

    
    
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
    
    func updateListObjects() {
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
        
        // ONLY SHOW BOOKMARKS IF ITS CURRENT USER ELSE DISPLAY USER NAME AND BACK BUTTON
        profileHeaderLabel.text = !displayBack ? "Bookmarks 🧣" : user.username //🧣📕
        profileHeaderLabel.textColor = !displayBack ? UIColor.ianBlackColor() : UIColor.ianBlackColor()
        div.backgroundColor = UIColor.ianBlackColor()

        profileImageView.loadImage(urlString: url)
//        profileHeaderLabel.text = user.username
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
    var bookmarkImageDetailHeight: CGFloat = 50
    var bookmarkHeaderHeight: CGFloat = 35
    
    let div = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updateListObjects), name: MainTabBarController.CurrentUserListLoaded, object: nil)

        self.view.backgroundColor = UIColor.backgroundGrayColor()

    // HEADER VIEW
        self.setupHeader()
        
        div.backgroundColor = UIColor.ianBlackColor()
        navHeaderView.addSubview(div)
        div.anchor(top: navHeaderView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 3)
        
        
    // BOOKMARK
        bookmarkListView.imageHeight = bookmarkImageHeight
        bookmarkListView.imageDetailHeight = bookmarkImageDetailHeight
        bookmarkListView.headerHeight = bookmarkHeaderHeight

        
        view.addSubview(bookmarkContainer)
        bookmarkContainer.anchor(top: navHeaderView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        bookmarkContainer.layer.borderColor = UIColor.ianLightGrayColor().cgColor
        bookmarkContainer.layer.borderWidth = 0
        bookmarkContainer.backgroundColor = UIColor.clear
        bookmarkContainer.layer.applySketchShadow(color: UIColor(red: 0, green: 0, blue: 0, alpha: 1), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
        
        
        bookmarkListView.cell.backgroundColor = UIColor.clear
//        bookmarkListView = ListPostSummaryCollectionViewController()
//        bookmarkListView.listHeaderLabel.titleLabel?.font = UIFont(font: .avenirNextBold, size: 22)
        bookmarkListView.listHeaderLabel.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 22)
        bookmarkListView.listHeaderLabel.setTitleColor(UIColor.ianLegitColor(), for: .normal)
//        bookmarkListView.listHeaderLabel.font = UIFont(name: "Poppins-Bold", size: 20)
        bookmarkListView.delegate = self
        bookmarkListView.showDetails = true
        bookmarkListView.showHeader = false
//        bookmarkListView.listHeaderLabel.textColor = UIColor.oldIanLegitColor()
        bookmarkContainer.addSubview(bookmarkListView)
        bookmarkListView.anchor(top: bookmarkContainer.topAnchor, left: bookmarkContainer.leftAnchor, bottom: bookmarkContainer.bottomAnchor, right: bookmarkContainer.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: bookmarkImageHeight + bookmarkImageDetailHeight + 15)
        
        updateListObjects()
        
        
    // BOTTOM DIV
    
        let bottomDiv = UIView()
        view.addSubview(bottomDiv)
        bottomDiv.anchor(top: bookmarkListView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 2)
        bottomDiv.backgroundColor = UIColor.rgb(red: 221, green: 221, blue: 221)
            

    // CREATE NEW LIST BUTTON
        view.addSubview(createNewListButton)
        createNewListButton.anchor(top: bookmarkContainer.bottomAnchor, left: profileImageView.leftAnchor, bottom: nil, right: nil, paddingTop: 30, paddingLeft: 0, paddingBottom: 0, paddingRight: 20, width: 0, height: 30)
        createNewListButton.isHidden = (self.displayUser?.uid != Auth.auth().currentUser?.uid)
        createNewListButton.sizeToFit()
        createNewListButton.layer.applySketchShadow()
            
    // CREATED LIST
        setupCreatedList()
        view.addSubview(createdListContainer)
        createdListContainer.anchor(top: createNewListButton.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop:10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)


        
        createdListContainer.addSubview(createdListView)
        createdListView.anchor(top: createdListContainer.topAnchor, left: createdListContainer.leftAnchor, bottom: createdListContainer.bottomAnchor, right: createdListContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    // FOLLOWED LIST
        setupFollowedList()
        view.addSubview(followedListContainer)
        followedListContainer.anchor(top: createdListContainer.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 30, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        followedListContainer.addSubview(followedListView)
        followedListView.anchor(top: followedListContainer.topAnchor, left: followedListContainer.leftAnchor, bottom: followedListContainer.bottomAnchor, right: followedListContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
    
        

        
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
            
    // ADD NEW LIST BUTTON
//            navHeaderView.addSubview(addNewListButton)
//            addNewListButton.anchor(top: nil, left: nil, bottom: nil, right: navHeaderView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 0, height: 15)
//            addNewListButton.centerYAnchor.constraint(equalTo: navHeaderView.centerYAnchor).isActive = true
//            addNewListButton.sizeToFit()
//            addNewListButton.isHidden = !(self.displayUser?.uid == Auth.auth().currentUser?.uid)
//
        
    // BOOKMARK SORT HEADER
            navHeaderView.addSubview(bookmarkSortButton)
            bookmarkSortButton.anchor(top: nil, left: nil, bottom: nil, right: navHeaderView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
            bookmarkSortButton.centerYAnchor.constraint(equalTo: navHeaderView.centerYAnchor).isActive = true
            bookmarkSortButton.sizeToFit()
            bookmarkSortButton.isHidden = bookmarkListView.isHidden
            refreshBookmarkSortButton()
        
    // NAV BACK BUTTON
            navHeaderView.addSubview(navBackButton)
            navBackButton.anchor(top: nil, left: nil, bottom: nil, right: navHeaderView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
            navBackButton.centerYAnchor.constraint(equalTo: navHeaderView.centerYAnchor).isActive = true
            navBackButton.sizeToFit()
            navBackButton.isHidden = true
        
    // PROFILE HEADER IMAGE
            let profileHeaderView = UIView()
            profileHeaderView.addSubview(profileImageView)
            profileImageView.anchor(top: profileHeaderView.topAnchor, left: profileHeaderView.leftAnchor, bottom: profileHeaderView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: headerViewHeight - 10, height: headerViewHeight - 10)
            profileImageView.layer.cornerRadius = (headerViewHeight - 10)/2
            profileImageView.layer.masksToBounds = true
            profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapProfile)))
            
    // PROFILE HEADER LABEL
            profileHeaderView.addSubview(profileHeaderLabel)
            profileHeaderLabel.anchor(top: nil, left: profileImageView.rightAnchor, bottom: nil, right: profileHeaderView.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            profileHeaderLabel.centerYAnchor.constraint(equalTo: profileHeaderView.centerYAnchor).isActive = true
            profileHeaderLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapProfile)))
            profileHeaderLabel.textColor = UIColor.ianBlackColor()
            
            navHeaderView.addSubview(profileHeaderView)
            profileHeaderView.anchor(top: navHeaderView.topAnchor, left: navHeaderView.leftAnchor, bottom: navHeaderView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            profileHeaderView.rightAnchor.constraint(lessThanOrEqualTo: bookmarkSortButton.leftAnchor, constant: 10).isActive = true
            

            refreshHeaderLabels()
    }

    
    func setupCreatedList() {
        createdListView.refreshAll()
        createdListView.displayFollowedList = false
        createdListView.showUser = false
        createdListView.user = self.displayUser
        createdListView.delegate = self
        createdListView.listHeaderLabel.font = UIFont(name: "Poppins-Bold", size: 20)

    }
    
    func setupFollowedList() {
        followedListView.refreshAll()
        followedListView.displayFollowedList = true
        followedListView.showUser = false
        followedListView.user = self.displayUser
        followedListView.delegate = self
        followedListView.listHeaderLabel.font = UIFont(name: "Poppins-Bold", size: 20)
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
        self.navigationController?.isNavigationBarHidden = true
        
        // Nav Back Button
        navBackButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        self.navBackButton.isHidden = !displayBack
        self.createNewListButton.isHidden = displayBack
        self.refreshHeaderLabels()
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
        let createNewListView = CreateNewListCardController()
        let navController = UINavigationController(rootViewController: createNewListView)
          let transition:CATransition = CATransition()
            transition.duration = 0.5
//        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
//        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromBottom
            self.navigationController!.view.layer.add(transition, forKey: kCATransition)
        self.present(navController, animated: true, completion: nil)
    }



}

extension TempNewTabListViewController: ListPostSummaryDelegate, SinglePostViewDelegate, ListSummaryDelegate {
    func doShowListView() {
        
    }
    
    func doHideListView() {
        
    }
    
    func didTapAddList() {
        self.extCreateNewList()
    }
    
    func didTapList(list: List?) {
        guard let list = list else {return}

//        let listViewController = ListViewController()
//        let listViewController = LegitListViewController()
        let listViewController = SingleListViewController()

        listViewController.currentDisplayList = list
        listViewController.refreshPostsForFilter()
        print("NewTabListView | goToList | \(list.name)| \(list.id)")
        self.navigationController?.pushViewController(listViewController, animated: true)
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
    
    func didTapProfile() {
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = self.displayUser?.uid
        navigationController?.pushViewController(userProfileController, animated: true)
    }
        
    func refreshPost(post: Post) {
        
    }


}

