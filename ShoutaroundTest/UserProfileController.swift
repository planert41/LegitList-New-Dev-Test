//
//  UserProfileController.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/26/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit

import FBSDKLoginKit
import CoreLocation
import EmptyDataSet_Swift
import CoreGraphics
import SVProgressHUD
import FirebaseAuth
import FirebaseDatabase
import SKPhotoBrowser

class UserProfileController: UICollectionViewController, UICollectionViewDelegateFlowLayout, FullPostCellDelegate, GridPhotoCellDelegate, UISearchBarDelegate, UISearchControllerDelegate, UIGestureRecognizerDelegate, UserProfileHeaderFilterDelegate, EmptyDataSetSource, EmptyDataSetDelegate, MainSearchControllerDelegate, SearchFilterControllerDelegate, FullPictureCellDelegate, NewUserProfileHeaderDelegate, ExplorePhotoCellDelegate, TestGridPhotoCellDelegate, SignUpControllerDelegate, SharePhotoListControllerDelegate, SKPhotoBrowserDelegate {
    func didTapLike(post: Post) {
        
    }
    

    static let RefreshNotificationName = NSNotification.Name(rawValue: "RefreshUser")

    let cellId = "cellId"
    let fullPostCellId = "fullPostCellId"
    let headerId = "headerId"

    var enableSignOut: Bool = false {
        didSet {
            setupNavigationItems()
        }
    }
    
    var scrolltoFirst: Bool = false
    var fetchedPostIds = [PostId]()
    var displayedPosts = [Post]()

    var displayUserId:String? {
        didSet {
            self.enableSignOut = displayUserId == Auth.auth().currentUser?.uid
            fetchUser()
            fetchPostsForUser()
        }
    }
    var displayUser: User? {
        didSet{
//            viewFilter?.filterUser = displayUser
            self.collectionView?.reloadData()
            setupNavigationItems()
        }
    }
    var isGridView = true

    // Pagination Variables
    var paginatePostsCount: Int = 0
    var isFinishedPaging = false {
        didSet{
            if isFinishedPaging == true {
                print("Paging Finish: \(self.isFinishedPaging), \(self.paginatePostsCount) Posts")
            }
        }
    }
    
    
    // Filtering Variables
    
    // Filter Variables
    var viewFilter: Filter? = Filter.init() {
        didSet{
            setupNavigationItems()
            self.refreshPostsForFilter()
        }
    }
    
    var isFilteringText: String? = nil

    func showFilterView(){
        
        guard let viewFilter = viewFilter else {return}
        
        var searchTerm: String = ""
        
        if (viewFilter.isFiltering) {
            let currentFilter = viewFilter
            if currentFilter.filterCaption != nil {
                searchTerm.append("\((currentFilter.filterCaption)!) | ")
            }
            
            if currentFilter.filterLocationName != nil {
                var locationNameText = currentFilter.filterLocationName
                if locationNameText == "Current Location" || currentFilter.filterLocation == CurrentUser.currentLocation {
                    locationNameText = "Here"
                }
                searchTerm.append("\(locationNameText!) | ")
            }
            
            if currentFilter.filterLocationSummaryID != nil {
                var locationNameText = currentFilter.filterLocationSummaryID
                searchTerm.append("\(locationNameText!) | ")
            }
            
            if (currentFilter.filterLegit) {
                searchTerm.append("Legit | ")
            }
            
            if currentFilter.filterMinRating != 0 {
                searchTerm.append("\((currentFilter.filterMinRating)) Stars | ")
            }
        }
        
        self.filteringDetailLabel.text = "Filtering : " + searchTerm
        self.filteringDetailLabel.sizeToFit()
        self.filterDetailView.isHidden = !(viewFilter.isFiltering)
    }
    
    
    let filterDetailView: UIView = {
        let tv = UIView()
        tv.backgroundColor = UIColor.white
        tv.layer.cornerRadius = 5
        tv.layer.masksToBounds = true
        tv.layer.borderWidth = 1
        tv.layer.borderColor = UIColor.legitColor().cgColor

        return tv
    }()
    
    
    let filteringDetailLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textAlignment = NSTextAlignment.center
//        label.backgroundColor = UIColor.rgb(red: 255, green: 242, blue: 230)
        label.textColor = UIColor.legitColor()
        label.numberOfLines = 0
//        label.layer.borderColor = UIColor.black.cgColor
//        label.layer.masksToBounds = true
        return label
    }()
    
    lazy var cancelFilterButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        button.setImage(#imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysOriginal), for: .normal)
        button.backgroundColor = UIColor.clear
        button.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        return button
    }()
    
    @objc func didTapCancel(){
        self.refreshAll()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
        if newUserOnboarding {
            print("*** NEW USER *** SHOW ONBOARDING")
            self.extShowOnboarding()
//            showOnboarding()
//            newUser = false
        }
    }

//    func showOnboarding(){
//        let welcomeView = NewUserOnboardingView()
//        let testNav = UINavigationController(rootViewController: welcomeView)
//        self.present(testNav, animated: true, completion: nil)
//        //        self.navigationController?.pushViewController(listView, animated: true)
//        
//    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        collectionView?.collectionViewLayout.invalidateLayout()
        collectionView?.layoutIfNeeded()
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        print("User Profile Controller | LOAD")
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateFeed), name: SharePhotoListController.updateProfileFeedNotificationName, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(setupNavigationItems), name: MainTabBarController.NewNotificationName, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(newUserEvent), name: UserProfileController.RefreshNotificationName, object: nil)

        
        setupCollectionView()
//        setupEmojiDetailLabel()
        clearFilter()
        self.scrolltoFirst = false
    }
    
    func setupCollectionView(){
        collectionView?.backgroundColor = .white
//        collectionView?.backgroundColor = UIColor.init(white: 0, alpha: 0.1)
//        collectionView?.contentInset = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
//        collectionView?.register(ExplorePhotoCell.self, forCellWithReuseIdentifier: cellId)

        //        collectionView?.collectionViewLayout = StickyHeadersCollectionViewFlowLayout()
        collectionView?.register(NewUserProfileHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerId)
        collectionView?.register(FullPictureCell.self, forCellWithReuseIdentifier: fullPostCellId)
        collectionView?.register(TestGridPhotoCell.self, forCellWithReuseIdentifier: cellId)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        collectionView?.alwaysBounceVertical = true
        collectionView?.keyboardDismissMode = .onDrag
        
        // Adding Empty Data Set
        collectionView?.emptyDataSetSource = self
        collectionView?.emptyDataSetDelegate = self
        collectionView.emptyDataSetView { (emptyview) in
            emptyview.isUserInteractionEnabled = false
        }
        
        let layout: UICollectionViewFlowLayout = HomeSortFilterHeaderFlowLayout()
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 0
        collectionView?.collectionViewLayout = layout
        
        view.addSubview(filterDetailView)
        filterDetailView.anchor(top: nil, left: nil, bottom: bottomLayoutGuide.topAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 3, paddingRight: 0, width: 0, height: 0)
        filterDetailView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        filterDetailView.widthAnchor.constraint(lessThanOrEqualToConstant: self.view.frame.width - 20).isActive = true

        filterDetailView.addSubview(cancelFilterButton)
        cancelFilterButton.anchor(top: nil, left: nil, bottom: nil, right: filterDetailView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        cancelFilterButton.centerYAnchor.constraint(equalTo: filterDetailView.centerYAnchor).isActive = true
        
        filterDetailView.addSubview(filteringDetailLabel)
        filteringDetailLabel.anchor(top: filterDetailView.topAnchor, left: filterDetailView.leftAnchor, bottom: filterDetailView.bottomAnchor, right: cancelFilterButton.leftAnchor, paddingTop: 3, paddingLeft: 5, paddingBottom: 3, paddingRight: 0, width: 0, height: 0)
        
        filterDetailView.isHidden = true

    }
    
    // Emoji Details
    
    let emojiDetailLabel: UILabel = {
        let label = UILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.rgb(red: 255, green: 242, blue: 230)
        label.layer.cornerRadius = 30/2
        label.layer.borderWidth = 0.25
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.masksToBounds = true
        return label
    }()
    
    let notificationLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 15, y: -5, width: 15, height: 15))
        label.layer.borderColor = UIColor.clear.cgColor
        label.layer.borderWidth = 0
        label.layer.cornerRadius = label.bounds.size.height / 2
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = UIFont(name: "Poppins-Bold", size: 10)
        label.textColor = .white
        label.backgroundColor = UIColor.ianBlueColor()
        label.text = "80"
        return label
    }()
    
//    func setupEmojiDetailLabel(){
//        view.addSubview(emojiDetailLabel)
//        emojiDetailLabel.anchor(top: topLayoutGuide.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 150, height: 25)
//        emojiDetailLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        emojiDetailLabel.isHidden = true
//    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        emojiDetailLabel.isHidden = true
    }
    
    var displayBack: Bool = true {
        didSet{
            setupNavigationItems()
        }
    }

    let notificationButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "alert").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.ianLegitColor()
        //        button.layer.cornerRadius = button.frame.width/2
//        button.layer.masksToBounds = true
        button.setTitle("", for: .normal)
        button.addTarget(self, action: #selector(openNotifications), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.borderColor = UIColor.gray.cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 30/2
        button.titleLabel?.textColor = UIColor.darkLegitColor()
//        button.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
//        button.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
//        button.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        return button
    }()
    
    @objc func openNotifications(){
        let note = UserEventViewController()
        self.navigationController?.pushViewController(note, animated: true)
    }
    
    
    @objc func openFriends(){
        print("Display Friends For Current User| ",CurrentUser.user?.uid)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayAllUsers = true
        postSocialController.displayUserFollowing = true
        postSocialController.displayUser = true
        postSocialController.inputUser = CurrentUser.user
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    func openSearch(index: Int) {
        let postSearch = MainSearchController()
        postSearch.delegate = self
        
        // Option Counts for Current Filter
        
        Database.countEmojis(posts: self.displayedPosts) { (emojiCounts) in
            postSearch.emojiCounts = emojiCounts
            postSearch.defaultEmojiCounts = self.noCaptionFilterEmojiCounts
        }
        Database.countCityIds(posts: self.displayedPosts) { (locationCounts) in
            postSearch.locationCounts = locationCounts
            postSearch.defaultLocationCounts = self.noCaptionFilterLocationCounts
        }
        
        
        postSearch.searchFilter = self.viewFilter
        postSearch.setupInitialSelections()
        //        postSearch.postCreatorIds = self.extractCreatorUids(posts: self.displayedPosts)
        
        self.navigationController?.pushViewController(postSearch, animated: true)
        if index != nil {
            postSearch.selectedScope = index
            postSearch.searchController.searchBar.selectedScopeButtonIndex = index
        }
    }
    
    
    
    
    func didTapListCancel(post: Post) {
        self.userOptionPost(post: post)
    }
    
    
    
    func expandPost(post: Post, newHeight: CGFloat) {
        //        collectionHeights[post.id!] = newHeight
        //        print("Added New Height | ",collectionHeights)
    }
    
    
    @objc func setupNavigationItems() {
        
        
        let tempImage = UIImage.init(color: UIColor.white)
        self.navigationController?.navigationBar.setBackgroundImage(tempImage, for: .default)
        self.navigationController?.view.backgroundColor = UIColor.white
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.isNavigationBarHidden = false

        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.barTintColor = UIColor.white
        navigationController?.navigationBar.tintColor = UIColor.ianLegitColor()
        navigationController?.view.backgroundColor = UIColor.white
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.layoutIfNeeded()

        
//        navigationController?.navigationBar.setBackgroundImage(#imageLiteral(resourceName: "button_background"), for: .default)

        // REMOVES THE 1PX BOTTOM LINE IN NAV BAR
        navigationController?.navigationBar.shadowImage = UIImage()
        
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 18)]

        
        var titleString = ""
        if let username = displayUser?.username {
            titleString = username
        } else {
            titleString = "User"
        }
        
        let usernameString = NSMutableAttributedString(string: "\(titleString) ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.ianLegitColor(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Poppins-Bold", size: 18)]))
//        usernameLabelText.append(usernameString)
//        navigationItem.attr
        let titleView = UILabel()
        titleView.attributedText = usernameString
        
        navigationItem.titleView = titleView
        navigationController?.navigationBar.layoutIfNeeded()
        self.setNeedsStatusBarAppearanceUpdate()

        let tempNavBarButton = NavBarMapButton.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        tempNavBarButton.addTarget(self, action: #selector(toggleMapFunction), for: .touchUpInside)
        let barButton1 = UIBarButtonItem.init(customView: tempNavBarButton)
        
        if !displayBack {

            // Display Settings if same user
            if displayUser?.uid == Auth.auth().currentUser?.uid {
//                let editButton = UIBarButtonItem(image: (#imageLiteral(resourceName: "settings_white")).withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(userSettings))
//                navigationItem.rightBarButtonItem = editButton
                
                notificationButton.addTarget(self, action: #selector(openNotifications), for: .touchUpInside)
                if CurrentUser.unreadEventCount > 0 {
//                    let attributedTitle = NSMutableAttributedString(string: String(CurrentUser.unreadEventCount), attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Poppins-Bold", size: 18), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.ianLegitColor()]))
//                    notificationButton.setAttributedTitle(attributedTitle, for: .normal)
                    //                    notificationButton.setTitle(String(CurrentUser.unreadEventCount), for: .normal)

                    notificationLabel.text = String(CurrentUser.unreadEventCount)
                    notificationButton.addSubview(notificationLabel)
                    notificationLabel.isHidden = false
                } else {
//                    notificationButton.setTitle("", for: .normal)
                    notificationLabel.text = ""
                    notificationLabel.isHidden = true
                }
                let notificationBarButton = UIBarButtonItem.init(customView: notificationButton)
                navigationItem.rightBarButtonItem = notificationBarButton
            }
            
            // Display Map Button on Right if not a separate viewcontroller (Only from tab)
            self.navigationItem.leftBarButtonItem = barButton1
        } else {
            // Leave Left Bar Button Blank for BACK button
            // Display Map Button on Right if not a separate viewcontroller (Only from tab)
            self.navigationItem.rightBarButtonItem = barButton1
            
            // Nav Back Buttons
            let navBackButton = navBackButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            navBackButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
            let barButton2 = UIBarButtonItem.init(customView: navBackButton)
            self.navigationItem.leftBarButtonItem = barButton2
            
        }
        
        

        
//        var attributedHeaderTitle = NSMutableAttributedString()
        
        //let headerTitle = NSAttributedString(string: self.fetchTypeInd + " ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextBold, size: 18)])
//        let customFont = UIFont(name: "Poppins-Bold", size: 18)
//        let headerTitle = NSAttributedString(string: titleString, attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: customFont])
        
        
        
//        let legitListTitle = UILabel()
//        legitListTitle.text = "LegitList"
//        //        legitListTitle.font = UIFont(name: "TitilliumWeb-SemiBold", size: 20)
//        legitListTitle.font = UIFont(font: .noteworthyBold, size: 20)
//        legitListTitle.textColor = UIColor.white
//        legitListTitle.textAlignment = NSTextAlignment.center
//        navigationItem.titleView  = legitListTitle
        
        var searchTerm: String = ""
        
        if (self.viewFilter?.isFiltering)! {
            let currentFilter = self.viewFilter
            var searchTerm: String = ""
            
            if currentFilter?.filterCaption != nil {
                searchTerm.append("\((currentFilter?.filterCaption)!) | ")
            }
            
            if currentFilter?.filterLocationName != nil {
                var locationNameText = currentFilter?.filterLocationName
                if locationNameText == "Current Location" || currentFilter?.filterLocation == CurrentUser.currentLocation {
                    locationNameText = "Here"
                }
                searchTerm.append("\(locationNameText!) | ")
            }
            
            if (currentFilter?.filterLegit)! {
                searchTerm.append("Legit | ")
            }
            
            if currentFilter?.filterMinRating != 0 {
                searchTerm.append("\((currentFilter?.filterMinRating)!) Stars | ")
            }
            self.isFilteringText = searchTerm
        } else {
            self.isFilteringText = nil
        }
        
        
    }
    
    @objc func toggleMapFunction(){
        var tempFilter = self.viewFilter ?? Filter.init()
        tempFilter.filterUser = self.displayUser
        appDelegateFilter = tempFilter
        self.toggleMapView()
    }
    
    func openInbox() {
//        let inboxController = InboxController(collectionViewLayout: UICollectionViewFlowLayout())
//        navigationController?.pushViewController(inboxController, animated: true)
    }
    
    func fetchUser(){
        guard let uid = displayUserId else {
            print("User Profile: Fetch Posts Error, No UID")
            return
        }
        
        Database.fetchUserWithUID(uid: uid) { (fetchedUser) in
            self.displayUser = fetchedUser
            print("UserprofileController | Fetched User | \(uid)")
        }
    }
    
    
    func fetchPostsForUser(){
        SVProgressHUD.show(withStatus: "Loading Posts")
        self.fetchPostIdsForUser {
            self.fetchPostForUserPostIds()
        }
    }
    
    func fetchPostIdsForUser(completion:@escaping () ->()){
        guard let uid = displayUserId else {
            print("User Profile: Fetch Posts Error, No UID")
            return
        }
        print("User Profile Controller | Fetching Post IDS | \(uid)")
        
        if uid == Auth.auth().currentUser?.uid && self.fetchedPostIds.count > 0 {
            print("User Profile Controller | Existing Post Ids | \(self.fetchedPostIds.count)")
            completion()
        } else {
            Database.fetchAllPostIDWithCreatorUID(creatoruid: uid) { (fetchedPostIds) in
                self.fetchedPostIds = fetchedPostIds
                print("User Profile \(self.displayUser?.uid): Fetched \(fetchedPostIds.count) Post Ids")
                completion()
            }
        }
    }
    
    
    func fetchPostForUserPostIds(){
        print("User Profile Controller | Fetching Posts | \(displayUserId)")

        Database.fetchAllPosts(fetchedPostIds: fetchedPostIds, completion: { (fetchedPosts) in
            self.displayedPosts = fetchedPosts
            print("User Profile Controller | Success Fetching | \(self.displayedPosts.count) Posts")
//            print("User Profile \(self.displayUser?.uid): Fetched \(self.displayedPosts.count) Posts")
            self.filterSortFetchedPosts()
        })
    }
    
    
    func filterSortFetchedPosts(){
        
        // Fetches All Posts, Refilters assuming no caption filtered, recount emoji/location
        var noCaptionLocationFilter = Filter.init()
        noCaptionLocationFilter.filterUser = self.viewFilter?.filterUser
        noCaptionLocationFilter.filterList = self.viewFilter?.filterList
        
        Database.filterPostsNew(inputPosts: self.displayedPosts, postFilter: noCaptionLocationFilter) { (filteredPosts) in
            Database.countEmojis(posts: filteredPosts) { (emojiCounts) in
                self.noCaptionFilterEmojiCounts = emojiCounts
            }
            
            Database.countCityIds(posts: filteredPosts) { (locationCounts) in
                self.noCaptionFilterLocationCounts = locationCounts
            }
        }
        
        // Filter Posts
        Database.filterPostsNew(inputPosts: self.displayedPosts, postFilter: self.viewFilter) { (filteredPosts) in
            
            Database.sortPosts(inputPosts: filteredPosts, selectedSort: self.viewFilter?.filterSort, selectedLocation: self.viewFilter?.filterLocation, completion: { (filteredPosts) in
                
                self.displayedPosts = []
                if filteredPosts != nil {
                    self.displayedPosts = filteredPosts!
                }
                print("Filter Sorted Post: \(self.displayedPosts.count)")
                self.paginatePosts()
//                self.showFilterView()
            })
        }
    }
    
    
// Refresh Functions
    
    
    func clearPostIds(){
        self.fetchedPostIds.removeAll()
    }
    
    func clearAllPosts(){
        self.fetchedPostIds.removeAll()
        self.displayedPosts.removeAll()
        self.refreshPagination()
    }
    
    func clearSort(){
        self.viewFilter?.filterSort = defaultRecentSort
    }
    
    func clearSearch(){
        self.viewFilter?.filterCaption = nil
        self.showFilterView()
    }
    
    func clearFilter(){
        self.viewFilter?.clearFilter()
        self.clearSort()
        self.showFilterView()
    }
    
    func refreshPagination(){
        self.isFinishedPaging = false
        self.paginatePostsCount = 0
    }
    
    @objc func refreshAll(){
        self.clearFilter()
        self.clearAllPosts()
        self.refreshPagination()
        self.fetchUser()
        self.fetchPostsForUser()
        self.collectionView.reloadData()
    }
    
    func refreshPosts(){
        self.clearAllPosts()
    }
    
    @objc func newUserEvent(){
        self.fetchUser()
    }
    
    func refreshPostsForFilter(){
//        self.displayedPosts.removeAll()
        
//        if self.viewFilter?.filterCaption != nil {
//            SVProgressHUD.show(withStatus: "Searching Posts for \((self.viewFilter?.filterCaption)!)")
//        } else if self.viewFilter?.filterLocationSummaryID != nil {
//            SVProgressHUD.show(withStatus: "Searching Posts at \((self.viewFilter?.filterLocationSummaryID)!)")
//        } else if self.viewFilter?.filterLocation != nil {
//            guard let coord = self.viewFilter?.filterLocation?.coordinate else {return}
//            let lat = Double(coord.latitude).rounded(toPlaces: 2)
//            let long = Double(coord.longitude).rounded(toPlaces: 2)
//            
//            var coordinate = "(\(lat),\(long))"
//            SVProgressHUD.show(withStatus: "Searching Posts at \n GPS: \(coordinate)")
//        }   else if self.viewFilter?.filterUser != nil {
//            guard let user = self.viewFilter?.filterUser else {return}
//            SVProgressHUD.show(withStatus: "Searching Posts by \(user.username)")
//        } else if (self.viewFilter?.isFiltering)! ?? false {
//            SVProgressHUD.show(withStatus: "Searching Posts")
//        } else {
//            SVProgressHUD.show(withStatus: "Fetching Posts")
//        }
        
        
        self.refreshPagination()
        self.fetchPostForUserPostIds()
//        self.collectionView?.reloadData()
        self.scrolltoFirst = true
    }
    
    func refreshPostsForFilterTest(){
        //        self.displayedPosts.removeAll()
        self.refreshPagination()
        self.fetchPostForUserPostIds()
        self.collectionView.reloadSections(IndexSet(integer: 0))
        self.scrolltoFirst = true
    }
    
    @objc func handleUpdateFeed() {
        
        // Check for new post that was edited or uploaded
        if newPost != nil && newPostId != nil {
            self.displayedPosts.insert(newPost!, at: 0)
            self.fetchedPostIds.insert(newPostId!, at: 0)
            
            self.collectionView?.reloadData()
            if self.collectionView?.numberOfItems(inSection: 0) != 0 {
                let indexPath = IndexPath(item: 0, section: 0)
                self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
            }
            print("Pull in new post")
            
        } else {
            self.handleRefresh()
        }
    }
    
    @objc func handleRefresh() {
        self.refreshAll()
        fetchPostsForUser()
        self.collectionView?.refreshControl?.endRefreshing()
        print("Refresh User Profile Feed. FetchPostIds: ", self.fetchedPostIds.count, "FetchedPostCounr: ", self.displayedPosts.count, " DisplayedPost: ", self.paginatePostsCount)
    }
    
    
// HomePost Cell Delegate Functions
    func didTapUserUid(uid: String) {
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = uid
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    
    func didTapBookmark(post: Post) {
        
        let sharePhotoListController = SharePhotoListController()
        sharePhotoListController.uploadPost = post
        sharePhotoListController.isBookmarkingPost = true
        sharePhotoListController.delegate = self
        navigationController?.pushViewController(sharePhotoListController, animated: true)
    }
    
    func didTapComment(post: Post) {
        
        let commentsController = CommentsController(collectionViewLayout: UICollectionViewFlowLayout())
        commentsController.post = post
        
        navigationController?.pushViewController(commentsController, animated: true)
    }
    
    func didTapUser(post: Post) {
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = post.user.uid
        
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapLocation(post: Post) {
        let locationController = LocationController()
        locationController.selectedPost = post
        
        navigationController?.pushViewController(locationController, animated: true)
    }
    
    func didTapExtraTag(tagName: String, tagId: String, post: Post) {
        
        // Check to see if its a list, price or something else
        if tagId == "price"{
            // Price Tag Selected
            print("Price Selected")
            self.viewFilter?.filterMaxPrice = tagName
            self.refreshPostsForFilter()
        }
        else if tagId == "creatorLists"{
            // Additional Tags
            let listController  = ListController()
            listController.displayedPost = post
            listController.displayedListNameDictionary = post.creatorListId
            self.navigationController?.pushViewController(listController, animated: true)
        }
        else if tagId == "userLists"{
            // Additional Tags
            let listController  = ListController()
            listController.displayedPost = post
            listController.displayedListNameDictionary = post.selectedListId
            self.navigationController?.pushViewController(listController, animated: true)
        }
        else {
            // List Tag Selected
            Database.checkUpdateListDetailsWithPost(listName: tagName, listId: tagId, post: post, completion: { (fetchedList) in
                if fetchedList == nil {
                    // List Does not Exist
                    self.alert(title: "List Error", message: "List Does Not Exist Anymore")
                } else {
                    
                    
                    let listViewController = ListViewController()
                    listViewController.imageCollectionView.collectionViewLayout = HomeSortFilterHeaderFlowLayout()
                    listViewController.currentDisplayList = fetchedList
                    self.navigationController?.pushViewController(listViewController, animated: true)
                }
            })
        }
    }

    
    func refreshPost(post: Post) {
        let index = displayedPosts.firstIndex { (filteredpost) -> Bool in
        filteredpost.id  == post.id
            
    }
        let filteredindexpath = IndexPath(row:index!, section: 0)
        self.displayedPosts[index!] = post
        self.collectionView?.reloadItems(at: [filteredindexpath])
        
    }
    
    func didTapMessage(post: Post) {
        
        let messageController = MessageController()
        messageController.post = post
        
        navigationController?.pushViewController(messageController, animated: true)
    }
    
    func userSettings(){
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        if uid != displayUserId {
            return
        }
        
        let optionsAlert = UIAlertController(title: "User Options", message: "", preferredStyle: UIAlertController.Style.alert)
        
        optionsAlert.addAction(UIAlertAction(title: "Change Profile Picture", style: .default, handler: { (action: UIAlertAction!) in
            // Allow Editing
            self.editUser()
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Edit User", style: .default, handler: { (action: UIAlertAction!) in
            // Allow Editing
            self.editUser()
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
    
    func userOptionPost(post:Post){
        
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
        
        present(optionsAlert, animated: true) {
            optionsAlert.view.superview?.isUserInteractionEnabled = true
            optionsAlert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.alertClose(gesture:))))
        }
    }
    
    func editPost(post:Post){
        let editPost = MultSharePhotoController()
        // Post Edit Inputs
        editPost.editPostInd = true
        editPost.editPost = post
        
//        self.navigationController?.pushViewController(editPost, animated: true)
        
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
            self.paginatePostsCount += -1
            self.collectionView?.deleteItems(at: [filteredindexpath])
            Database.deletePost(post: post)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        present(deleteAlert, animated: true, completion: nil)
        
    }
    
    func displaySelectedEmoji(emoji: String, emojitag: String) {
        
        emojiDetailLabel.text = emoji + " " + emojitag
        emojiDetailLabel.isHidden = false
        
    }
    
// Home Post Search Delegates
    
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
        self.handleLogOut()
    }
    
    func successSignUp(){
        print("User Profile Controller | Success Edit User")
        self.displayUserId = Auth.auth().currentUser?.uid
    }
    
    
    func filterCaptionSelected(searchedText: String?){
//        self.openSearch(index: 0)
//        return
        
        if searchedText == nil {
            self.handleRefresh()
        } else {
            var inputText = searchedText ?? ""
            if inputText.isSingleEmoji {
                if let dic = EmojiDictionary[inputText] {
                    inputText += dic
                }
            }
            
         self.viewFilter?.filterCaption = inputText
            self.refreshPostsForFilterTest()
//         self.refreshPostsForFilter()
        }
    }
    
    func openSearch(index: Int?){
        
        //        self.navigationController?.isNavigationBarHidden  = true
        //        return
        
        let postSearch = MainSearchController()
        postSearch.delegate = self
        
        
        // Option Counts for Current Filter
        
        Database.countEmojis(posts: self.displayedPosts) { (emojiCounts) in
            postSearch.emojiCounts = emojiCounts
            postSearch.defaultEmojiCounts = self.noCaptionFilterEmojiCounts
        }
        Database.countCityIds(posts: self.displayedPosts) { (locationCounts) in
            postSearch.locationCounts = locationCounts
            postSearch.defaultLocationCounts = self.noCaptionFilterLocationCounts
            print("TestHomeViewController | openSearch | \(postSearch.locationCounts.count) Loc | \(postSearch.defaultLocationCounts.count) Default No Filter Loc")
        }
        
        
        postSearch.searchFilter = self.viewFilter
        postSearch.setupInitialSelections()
        //        postSearch.postCreatorIds = self.extractCreatorUids(posts: self.displayedPosts)
        
        self.navigationController?.pushViewController(postSearch, animated: true)
        if index != nil {
            postSearch.selectedScope = index!
            postSearch.searchController.searchBar.selectedScopeButtonIndex = index!
        }
        
    }
    
    func userSelected(uid: String?){
        
    }
    
    func locationSelected(googlePlaceId: String?, googlePlaceName: String?, googlePlaceLocation: CLLocation?, googlePlaceType: [String]?) {

    }
    


    
    // Pagination

    
    func paginatePosts(){
        SVProgressHUD.dismiss()

        let paginateFetchPostSize = 4
        
        self.paginatePostsCount = min(self.paginatePostsCount + paginateFetchPostSize, self.displayedPosts.count)
        print("User Profile Paginate \(self.paginatePostsCount) : \(self.displayedPosts.count)")
        
        self.finishPaginationCheck()

    }
    
    func finishPaginationCheck(){
        
        if self.paginatePostsCount == self.displayedPosts.count {
            self.isFinishedPaging = true
            
            if self.isViewLoaded && self.view.window != nil {
                //Currently Active. Don't Refresh
                print("User Profile Controller | finishPaginationCheck | Don't Dismiss Progress Bar, not in view")
                SVProgressHUD.dismiss()
            }
        } else {
            self.isFinishedPaging = false
        }
        
        if self.displayedPosts.count == 0 && self.isFinishedPaging == true {
            print("User Profile Controller | Pagination: No Results | Paging: \(self.isFinishedPaging) | \(self.displayedPosts.count) Posts")
        }
        else if self.displayedPosts.count == 0 && self.isFinishedPaging != true {
            print("User Profile Controller | Pagination: No Results | Paging: \(self.isFinishedPaging) | \(self.displayedPosts.count) Posts")
            self.paginatePosts()
        } else {
            print("User Profile Controller | Paginating \(self.paginatePostsCount) | \(self.displayedPosts.count) Posts | Finish: \(self.isFinishedPaging)")
            DispatchQueue.main.async(execute: {
                
                if self.paginatePostsCount == 0 && !self.isFinishedPaging {
                    
                } else {
                    self.collectionView?.reloadData()
                }
                
                if self.isViewLoaded && self.view.window != nil {
                    //Currently Active. Don't Refresh
                    print("User Profile Controller | finishPaginationCheck | Don't Dismiss Progress Bar, not in view")
                    SVProgressHUD.dismiss()
                }
            })

        }
    }
    

    
      
//    fileprivate func setupLogOutButton() {
//            navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "signout").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleLogOut))
//    }


    func handleLogOut() {
        self.extSignOutUser()
    }
    
    
    func displayPostSocialUsers(post:Post, following: Bool){
        print("Display Vote Users| Following: ",following)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayUser = true
        postSocialController.inputPost = post
        postSocialController.displayUserFollowing = following
        postSocialController.scopeBarOptions = FollowingSortOptions
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    func displayPostSocialLists(post:Post, following: Bool){
        print("Display Lists| Following: ",following)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayList = true
        postSocialController.inputPost = post
        postSocialController.displayFollowing = following
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    // Grid Picture Delegate
    
    func didTapPicture(post: Post) {
        
        let pictureController = SinglePostView()
        pictureController.post = post
        navigationController?.pushViewController(pictureController, animated: true)
    }
    
    
    // Filter Delegate
    
    func filterControllerSelected(filter: Filter?) {
        self.viewFilter = filter
        self.refreshPostsForFilter()
    }
    
    // Filter Header Delegates
    
    func openFilter(){
        let filterController = SearchFilterController()
        filterController.delegate = self
        filterController.searchFilter = self.viewFilter
        self.navigationController?.pushViewController(filterController, animated: true)
    }

    
    func didChangeToPostView() {
        self.isGridView = false
        collectionView?.backgroundColor = .white
        collectionView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView?.reloadData()
    }
    
    func didChangeToGridView() {
        self.isGridView = true
        collectionView?.backgroundColor = UIColor.init(white: 0, alpha: 0.1)
//        collectionView?.contentInset = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
        collectionView?.reloadData()
    }
    
    func clearCaptionSearch() {
        self.viewFilter?.filterCaption = nil
        self.refreshPostsForFilter()
    }
    
    var noCaptionFilterEmojiCounts: [String:Int] = [:] {
        didSet {
//            collectionView.reloadData()
        }
    }
    var noCaptionFilterLocationCounts: [String:Int] = [:]
    
    func didTapEmoji(index: Int?, emoji: String) {
        if self.viewFilter?.filterCaption == emoji {
            self.viewFilter?.filterCaption = nil
        } else {
            self.viewFilter?.filterCaption = emoji
        }
        self.refreshPostsForFilter()
    }

    
    func headerSortSelected(sort: String) {
        self.viewFilter?.filterSort = sort
        
        if (self.viewFilter?.filterSort == HeaderSortOptions[1] && self.viewFilter?.filterLocation == nil){
            print("Sort by Nearest, No Location, Look up Current Location")
            LocationSingleton.sharedInstance.determineCurrentLocation()
            let when = DispatchTime.now() + defaultGeoWaitTime // change 2 to desired number of seconds
            DispatchQueue.main.asyncAfter(deadline: when) {
                //Delay for 1 second to find current location
                self.viewFilter?.filterLocation = CurrentUser.currentLocation
                self.refreshPostsForFilter()
            }
        } else {
            self.refreshPostsForFilter()
        }
        
        print("Filter Sort is ", self.viewFilter?.filterSort)
    }
    
//    func selectUserFollowers(){
//        guard let uid = Auth.auth().currentUser?.uid else {return}
//        let myGroup = DispatchGroup()
//
//
//        Database.fetchFollowerUserUids(uid: uid) { (userIds) in
//            var tempUsers: [User]? = []
//            for id in userIds{
//                myGroup.enter()
//                Database.fetchUserWithUID(uid: id, completion: { (fetchedUser) in
//                    if fetchedUser != nil {
//                        Database.checkUserIsFollowed(user: fetchedUser!, completion: { (fetchedUser) in
//                            tempUsers?.append(fetchedUser)
//                        })
//                    }
//                    myGroup.leave()
//                })
//            }
//
//            myGroup.notify(queue: .main) {
//                let userListController = UserListTableViewController()
//                userListController.users = tempUsers!
//                userListController.headerText = "Followers"
//                self.navigationController?.pushViewController(userListController, animated: true)
//            }
//        }
//    }
    
    
    
//    func selectUserFollowing(){
//        guard let uid = Auth.auth().currentUser?.uid else {return}
//        let myGroup = DispatchGroup()
//
//
//        Database.fetchFollowingUserUids(uid: uid) { (userIds) in
//            var tempUsers: [User]? = []
//            for id in userIds{
//                myGroup.enter()
//                Database.fetchUserWithUID(uid: id, completion: { (fetchedUser) in
//                    if fetchedUser != nil {
//                        Database.checkUserIsFollowed(user: fetchedUser!, completion: { (fetchedUser) in
//                            tempUsers?.append(fetchedUser)
//                        })
//                    }
//                    myGroup.leave()
//                })
//            }
//
//            myGroup.notify(queue: .main) {
//                let userListController = UserListTableViewController()
//                userListController.users = tempUsers!
//                userListController.headerText = "Following"
//                self.navigationController?.pushViewController(userListController, animated: true)
//            }
//        }
//    }
    
    var browser = SKPhotoBrowser()
    
    func tapProfileImage(image: UIImage?){
        guard let image = image else {return}
        var images = [SKPhoto]()
        
//        guard let selectedImages = image else {return}
//        for image in selectedImages {
//            let photo = SKPhoto.photoWithImage(image)// add some UIImage
//            images.append(photo)
//        }
        
        let photo = SKPhoto.photoWithImage(image)// add some UIImage
        images.append(photo)

        
        // 2. create PhotoBrowser Instance, and present from your viewController.
        SKPhotoBrowserOptions.displayCounterLabel = true
        SKPhotoBrowserOptions.displayBackAndForwardButton = true
        SKPhotoBrowserOptions.displayAction = true
        SKPhotoBrowserOptions.actionButtonTitles = ["Edit Photo"]
        SKPhotoBrowserOptions.swapCloseAndDeleteButtons = false
        //        SKPhotoBrowserOptions.enableSingleTapDismiss  = true
        SKPhotoBrowserOptions.bounceAnimation = true
        SKPhotoBrowserOptions.displayDeleteButton = true
        
        browser = SKPhotoBrowser(photos: images)
        browser.delegate = self
        //        browser.updateCloseButton(#imageLiteral(resourceName: "checkmark_teal").withRenderingMode(.alwaysOriginal), size: CGSize(width: 50, height: 50))
        
        browser.initializePageIndex(0)
        present(browser, animated: true, completion: {})
        
    }
    
    
    func selectUserFollowers(){
        print("Display Follower User| ",self.displayUser?.uid)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayUser = true
        postSocialController.displayUserFollowing = false
        postSocialController.inputUser = self.displayUser
        postSocialController.scopeBarOptions = FollowingSortOptions
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    
    func selectUserFollowing(){
        print("Display Following User| ",self.displayUser?.uid)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayUser = true
        postSocialController.displayUserFollowing = true
        postSocialController.inputUser = self.displayUser
        postSocialController.scopeBarOptions = FollowingSortOptions
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    
    func selectUserLists(){
        
//        if let userListIds = displayUser?.listIds {
//            if userListIds.count > 0 {
//                Database.fetchListForMultListIds(listUid: userListIds, completion: { (fetchedLists) in
//                    Database.sortList(inputList: fetchedLists, sortInput: nil, completion: { (sortedLists) in
//
//                        let listController = ListController()
//                        listController.displayUser = self.displayUser
//                        listController.displayedLists = sortedLists
//                        self.navigationController?.pushViewController(listController, animated: true)
//
//                    })
//                })
//            }
//        }
    
        let tabListController = TabListViewController()
        tabListController.enableAddListNavButton = false
        tabListController.inputUserId = displayUser?.uid
        self.navigationController?.pushViewController(tabListController, animated: true)

    
    
    }
    
    
// Collection View Methods
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.paginatePostsCount
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.item == self.paginatePostsCount - 1 && !isFinishedPaging{
            paginatePosts()
        }
        
        if isGridView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! TestGridPhotoCell
            cell.showDistance = self.viewFilter?.filterSort == defaultNearestSort
            cell.post = displayedPosts[indexPath.item]
            cell.delegate = self

//            cell.selectedHeaderSort = (self.viewFilter?.filterSort)!
            return cell
        } else {
            print("UserProfileController | Cell Input | Start")

            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: fullPostCellId, for: indexPath) as! FullPictureCell
            cell.enableDelete = true
            cell.post = displayedPosts[indexPath.item]
            cell.delegate = self
            print("UserProfileController | Cell Input | End")

            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ cofllectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if isGridView {
//        let width = (view.frame.width - 2) / 3
//            return CGSize(width: width, height: width)
            
//            let width = (view.frame.width - 2 - 4) / 2
            let width = (view.frame.width - 2) / 2
//            return CGSize(width: width, height: width + 40)
            return CGSize(width: width, height: width)

        } else {
            var height: CGFloat = 35 //headerview = username userprofileimageview
            height += view.frame.width  // Picture
            height += 160
            height += 30
            height += 30 // Emoji Array + Star Rating
            //            height += 25    // Date Bar
            return CGSize(width: view.frame.width - 16, height: height)
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "headerId", for: indexPath) as! NewUserProfileHeader
        
        
        header.user = self.displayUser
        header.isFiltering = (self.viewFilter?.isFiltering)!
        header.isGridView = self.isGridView
        header.selectedCaption = self.viewFilter?.filterCaption
        header.selectedSort = (self.viewFilter?.filterSort)!
        
        let sorted = self.noCaptionFilterEmojiCounts.sorted(by: {$0.value > $1.value})
        var topEmojis: [String] = []
        for (index,value) in sorted {
            if index.isSingleEmoji /*&& topEmojis.count < 4*/ {
                topEmojis.append(index)
            }
        }

        
        header.displayedEmojis = topEmojis
        header.delegate = self
        
//        header.selectedCaption  = self.viewFilter?.filterCaption
//        header.isFilteringText = self.isFilteringText
        header.delegate = self

        return header
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        return CGSize(width: view.frame.width, height: 220)
        return CGSize(width: view.frame.width, height: 120 + 50 + 40)

    }
    
    // EMPTY DATA SET DELEGATES
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        if (self.viewFilter?.isFiltering)! {
            text = "There's Nothing Here?!"
        } else {
            let number = arc4random_uniform(UInt32(tipDefaults.count))
            text = tipDefaults[Int(number)]
        }
        text = ""
        font = UIFont.boldSystemFont(ofSize: 17.0)
        textColor = UIColor(hexColor: "25282b")
        
        if text == nil {
            return nil
        }
        
        return NSMutableAttributedString(string: text!, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): font, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): textColor]))
        
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        text = nil
        
        font = UIFont(name: "Poppins-Regular", size: 15)
        textColor = UIColor.ianBlackColor()
        
        if (self.viewFilter?.isFiltering)! {
            text = "Nothing Legit Here! 😭"
        } else {
            text = ""
        }
        
        if text == nil {
            return nil
        }
        
        return NSMutableAttributedString(string: text!, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): font, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): textColor]))
        
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        //        return #imageLiteral(resourceName: "amaze").resizeVI(newSize: CGSize(width: view.frame.width/2, height: view.frame.height/2))
        return #imageLiteral(resourceName: "Legit_Vector")
    }
    
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        if (self.viewFilter?.isFiltering)! {
            text = "Tap To Refresh"
        } else {
            text = "Search For Users"
        }
        text = ""
        font = UIFont.boldSystemFont(ofSize: 18.0)
        textColor = UIColor.legitColor()
        
        if text == nil {
            return nil
        }
        
        return NSMutableAttributedString(string: text!, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): font, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): textColor]))
        
    }
    
    
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
        return UIColor.backgroundGrayColor()
        //        80cbc4
        
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {
        if (viewFilter?.isFiltering)! {
            self.openFilter()
        } else {
            self.openSearch(index: 1)
        }
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapView view: UIView) {
//        self.handleRefresh()
    }
    
    //    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
    //        let offset = (self.collectionView?.frame.height)! / 5
    //            return -50
    //    }
    
    func spaceHeight(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return 9
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
