//
//  HomeController.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/29/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth
import mailgun
import GeoFire
import CoreGraphics
import CoreLocation
import EmptyDataSet_Swift
import UIFontComplete
import SVProgressHUD
import MapKit

class HomeController: UICollectionViewController, UICollectionViewDelegateFlowLayout, FullPostCellDelegate, UIGestureRecognizerDelegate, UISearchBarDelegate, SortFilterHeaderDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MessageControllerDelegate, SharePhotoListControllerDelegate, EmptyDataSetSource, EmptyDataSetDelegate, MKMapViewDelegate, SearchFilterControllerDelegate, MainSearchControllerDelegate, SearchBarSortHeaderDelegate, FullPictureCellDelegate {


    func didTapLike(post: Post) {
        
    }

    func handleToggleView(){
        NotificationCenter.default.post(name: AppDelegate.SwitchToMapNotificationName, object: nil)
    }
    
    let cellId = "cellId"
    let headerId = "headerId"
    var scrolltoFirst: Bool = false
    var defaultHeader = "LegitList"
    
    var fetchedPostIds: [PostId] = []
    var fetchedPosts: [Post] = []


// Pagination Variables
    
    var userPostIdFetched = false
    var followingPostIdFetched = false
    var followingListFetched = false
    var paginatePostsCount: Int = 0
    
    var isFinishedPaging = false {
        didSet{
            if isFinishedPaging == true {
//                print("Paging Finish: \(self.isFinishedPaging)| \(self.paginatePostsCount) Posts")
            }
        }
    }
    
    
    static let refreshPostsNotificationName = NSNotification.Name(rawValue: "RefreshPosts")
    static let finishFetchingUserPostIdsNotificationName = NSNotification.Name(rawValue: "HomeFinishFetchingUserPostIds")
    static let finishFetchingFollowingPostIdsNotificationName = NSNotification.Name(rawValue: "HomeFinishFetchingFollowingPostIds")
    static let finishSortingFetchedPostsNotificationName = NSNotification.Name(rawValue: "HomeFinishSortingFetchedPosts")
    static let finishPaginationNotificationName = NSNotification.Name(rawValue: "HomeFinishPagination")
    static let refreshNavigationNotificationName = NSNotification.Name(rawValue: "HomeRefreshNavigation")

    
    // Geo Filter Variables
    
    let geoFilterRange = geoFilterRangeDefault
//    let geoFilterImage:[UIImage] = geoFilterImageDefault
    
    
// Filter Variables
    
    // Filter Variables
    var viewFilter: Filter? = Filter.init(filterSort: defaultRecentSort) {
        didSet{
            setupNavigationItems()
            self.refreshPostsForFilter()
//            if mapFilter?.filterLocation == CurrentUser.currentLocation {
//                mapFilter?.filterLocationName = "Current Location"
//            }
        }
    }
    
    var isFilterList: Bool = false
    var isFilterUser: Bool = false
    
    lazy var navFilterButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "filter").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(openFilter), for: .touchUpInside)
        button.layer.cornerRadius = 30/2
        button.clipsToBounds = true
        button.backgroundColor = UIColor.white
        button.layer.borderColor = UIColor.selectedColor().cgColor
        button.layer.borderWidth = 1
        return button
    }()
    
    lazy var navUserButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "profile_tab_unfill").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(openCurrentUserProfile), for: .touchUpInside)
        button.layer.cornerRadius = 30/2
        button.clipsToBounds = true
        button.backgroundColor = UIColor.clear
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1
        return button
    }()
    
    @objc func openCurrentUserProfile(){
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = CurrentUser.user?.uid
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    let refreshButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
//        button.setImage(#imageLiteral(resourceName: "refresh_blue"), for: .normal)
        button.setImage(#imageLiteral(resourceName: "refresh_white"), for: .normal)
        button.addTarget(self, action: #selector(handleRefresh), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.clear.cgColor
        //        button.layer.backgroundColor = UIColor.white.withAlphaComponent(0.75).cgColor
        //        button.layer.borderColor = UIColor.legitColor().cgColor
        //        button.layer.borderWidth = 1
        button.layer.cornerRadius = 30/2
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()
    
    
    lazy var filterLegitButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "legit").withRenderingMode(.alwaysOriginal), for: .normal)
//        button.setImage(#imageLiteral(resourceName: "legit_large").withRenderingMode(.alwaysOriginal), for: .normal)

        button.addTarget(self, action: #selector(filterLegitPosts), for: .touchUpInside)
        button.layer.cornerRadius = button.frame.width/2
        button.layer.borderColor = UIColor(hexColor: "eab543").cgColor
        
        button.layer.borderWidth = 2
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()
  
    @objc func filterLegitPosts(){
        self.viewFilter?.filterLegit = !(self.viewFilter?.filterLegit)!
        self.refreshPostsForFilter()
        setupNavigationItems()
        
        self.filterLegitButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.filterLegitButton.transform = .identity
                        
                        //                        self?.filterLegitButton.alpha = (self?.mapFilter?.filterLegit)! ? 1 : 0.5
                        //                        self?.filterLegitButton.backgroundColor = (self?.mapFilter?.filterLegit)! ? UIColor.legitColor() : UIColor(hexColor: "FE5F55")
                        
            },
                       completion: nil)
    }
    
    // Header Sort Variables
    lazy var singleTap: UIGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(openFilter))
        tap.delegate = self
        return tap
    }()

    
    var defaultSearchBar = UISearchBar()

    override func viewDidLayoutSubviews() {
                
//        let filterBarHeight = (self.filterBar.isHidden == false) ? self.filterBar.frame.height : 0
//        
//        let topinset = (self.navigationController?.navigationBar.frame.size.height)! + UIApplication.shared.statusBarFrame.height + filterBarHeight
//        collectionView?.frame = CGRect(x: 0, y: topinset, width: view.frame.width, height: view.frame.height - topinset - (self.tabBarController?.tabBar.frame.size.height)!)
    }

    
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
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayAllUsers = true
        postSocialController.displayUserFollowing = true
        postSocialController.displayUser = true
        postSocialController.inputUser = CurrentUser.user
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Loading Home")

        self.navigationController?.navigationBar.backgroundColor = UIColor.clear
        
        
//        self.automaticallyAdjustsScrollViewInsets = false

        
        //    1. Fetch All Post Ids to fetchedPostIds
        //    2. Fetch All Posts to fetchedPosts
        //    3. Filter displayedPosts based on Conditions/Sorting (All Fetched Posts are saved to cache anyways)
        //    4. Control Pagination by increasing displayedPostsCount to fetchedpostCount
        
        setupNotificationCenters()
        setupCollectionView()

// 1. Clear out all Filters, Fetched Post Ids and Pagination Variables
        self.refreshAll()
        
// 2. Fetch All Relevant Post Ids, then pull in all Post information to fetchedPosts
        self.scrolltoFirst = false
        
        setupNavigationItems()
        setupEmojiDetailLabel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.barTintColor = UIColor.white
        self.setupNavigationItems()
        collectionView?.collectionViewLayout.invalidateLayout()
        collectionView?.layoutIfNeeded()

    }
    
    private func animate(){
        guard let coordinator = self.transitionCoordinator else {
            return
        }
        
        coordinator.animate(alongsideTransition: {
            [weak self] context in
            self?.setupNavigationItems()
            }, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
//        self.setupNavigationItems()
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.navigationBar.barTintColor = UIColor.white
        collectionView?.collectionViewLayout.invalidateLayout()
        collectionView?.layoutIfNeeded()
        SVProgressHUD.dismiss()
    }
    

// MAP VIEW

//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        let reuseIdentifier = "annotationView"
//        var view = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
//        if #available(iOS 11.0, *) {
//            if view == nil {
//                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
//            }
//            view?.displayPriority = .required
//        } else {
//            if view == nil {
//                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
//            }
//        }
//        view?.annotation = annotation
//        view?.canShowCallout = true
//        return view
//    }

    
// COLLECTION VIEW
    
    
    func setupCollectionView(){
//        let homePostCellLayout = HomePostCellFlowLayout()
//        collectionView?.collectionViewLayout = homePostCellLayout
        
//        collectionView?.backgroundColor = UIColor.rgb(red: 51, green: 204, blue: 255)
        collectionView?.backgroundColor = appBackgroundColor

        collectionView?.register(FullPictureCell.self, forCellWithReuseIdentifier: cellId)
//        collectionView?.register(SortFilterHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerId")
        collectionView?.register(SearchBarSortHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerId)

        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        collectionView?.alwaysBounceVertical = true
        collectionView?.keyboardDismissMode = .onDrag
        collectionView?.delegate = self
        collectionView?.dataSource = self
        
        // Adding Empty Data Set
        collectionView?.emptyDataSetSource = self
        collectionView?.emptyDataSetDelegate = self
        collectionView?.emptyDataSetView { (emptyview) in
            emptyview.isUserInteractionEnabled = false
        }
        let layout: UICollectionViewFlowLayout = HomeSortFilterHeaderFlowLayout()
//        layout.sectionInset = UIEdgeInsets(top: 20, left: 0, bottom: 10, right: 0)
//        layout.itemSize = CGSize(width: screenWidth/3, height: screenWidth/3)
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 0
        collectionView?.collectionViewLayout = layout
        
//        collectionView?.collectionViewLayout = layout

    }
    
//    var layout: UICollectionViewFlowLayout = {
//        let layout = UICollectionViewFlowLayout()
//        let width = UIScreen.main.bounds.size.width
//        layout.estimatedItemSize = CGSize(width: width, height: 10)
//        return layout
//    }()
    
    func setupNotificationCenters(){
        
        // 1.  Checks if Both User and Following Post Ids are colelctved before proceeding
        NotificationCenter.default.addObserver(self, selector: #selector(finishFetchingPostIds), name: HomeController.finishFetchingUserPostIdsNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(finishFetchingPostIds), name: HomeController.finishFetchingFollowingPostIdsNotificationName, object: nil)
        
        // 2.  Fetches all Posts and Filters/Sorts
        
        // 3. Paginates Post by increasing displayedPostCount after Filtering and Sorting
        NotificationCenter.default.addObserver(self, selector: #selector(paginatePosts), name: HomeController.finishSortingFetchedPostsNotificationName, object: nil)
        
        // 4. Checks after pagination Ends
        
        NotificationCenter.default.addObserver(self, selector: #selector(finishPaginationCheck), name: HomeController.finishPaginationNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateFeed), name: SharePhotoListController.updateFeedNotificationName, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: HomeController.refreshPostsNotificationName, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(setupNavigationItems), name: HomeController.refreshNavigationNotificationName, object: nil)


    }

    
    // Emoji description
    
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
    
    func setupEmojiDetailLabel(){
        view.addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top: topLayoutGuide.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        emojiDetailLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        emojiDetailLabel.isHidden = true
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        emojiDetailLabel.isHidden = true
        
//        for cell in (collectionView?.visibleCells)! {
//            let tempCell = cell as! FullPostCell
//            tempCell.hideCaptionBubble()
//            tempCell.hideEmojiDetailLabel()
//        }
        
        
    }
    
    func CGRectMake(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
// Setup for Geo Range Button, Dummy TextView and UIPicker
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        self.openSearch(index: 0)
        return false
    }
    

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText.count == 0) {
            self.viewFilter?.filterCaption = nil
            self.checkFilter()
            self.refreshPostsForFilter()
            searchBar.endEditing(true)
        }
    }
    
    var noCaptionFilterEmojiCounts: [String:Int] = [:]
    var noCaptionFilterLocationCounts: [String:Int] = [:]
    
    func openSearch(index: Int?){

        let postSearch = MainSearchController()
        postSearch.delegate = self
        postSearch.searchFilter = self.viewFilter
        postSearch.searchController.searchBar.text = self.viewFilter?.filterCaption
        
        // Option Counts for Current Filter
        
        Database.countEmojis(posts: self.fetchedPosts) { (emojiCounts) in
            postSearch.emojiCounts = emojiCounts
        }
        Database.countCityIds(posts: self.fetchedPosts) { (locationCounts) in
            postSearch.locationCounts = locationCounts
        }
        
        postSearch.defaultEmojiCounts = self.noCaptionFilterEmojiCounts
        postSearch.defaultLocationCounts = self.noCaptionFilterLocationCounts
        
        postSearch.searchFilter = self.viewFilter
        postSearch.setupInitialSelections()
        
        
//        let transition = CATransition()
//        transition.duration = 0.5
//        transition.type = kCATransitionPush
//        transition.subtype = kCATransitionFromLeft
//        transition.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
//        view.window!.layer.add(transition, forKey: kCATransition)
        
        
        self.navigationController?.pushViewController(postSearch, animated: true)
        if index != nil {
            postSearch.selectedScope = index!
            postSearch.searchController.searchBar.selectedScopeButtonIndex = index!
        }
        
    }
    
    

// Sort Delegate
    
//    func openMap(){
//        print("Open Map")
//        let mapView = MapViewPaginateController()
//        mapView.initview = 0
//        mapView.selectedPostID = nil
//        
//        if CurrentUser.currentLocation == nil {
//            LocationSingleton.sharedInstance.determineCurrentLocation()
//            let when = DispatchTime.now() + defaultGeoWaitTime // change 2 to desired number of seconds
//            DispatchQueue.main.asyncAfter(deadline: when) {
//                //Delay for 1 second to find current location
//                mapView.initLocation = CurrentUser.currentLocation
//                mapView.setupMapView()
//                mapView.filterLocation = CurrentUser.currentLocation
//                mapView.selectedHeaderSort = "Nearest"
//                mapView.fetchedPostIds = self.fetchedPostIds
//                self.navigationController?.pushViewController(mapView, animated: true)
//            }
//        } else {
//            mapView.initLocation = CurrentUser.currentLocation
//            mapView.setupMapView()
//            mapView.filterLocation = CurrentUser.currentLocation
//            mapView.selectedHeaderSort = "Nearest"
//            mapView.fetchedPostIds = self.fetchedPostIds
//            self.navigationController?.pushViewController(mapView, animated: true)
//        }
//    }

    func headerSortSelected(sort: String) {
//        self.selectedHeaderSort = sort
        self.viewFilter?.filterSort = sort
        self.viewFilter?.defaultSort = sort

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
    
    // Search Delegate And Metho@objc ds
    
    @objc func openFilter(){
        let filterController = SearchFilterController()
        filterController.delegate = self
        filterController.searchFilter = self.viewFilter
        self.navigationController?.pushViewController(filterController, animated: true)
    }

    
// Search Delegates
    func filterControllerSelected(filter: Filter?) {
        self.viewFilter = filter
        self.setupNavigationItems()
        self.refreshPostsForFilter()
    }
    
    

    
    func checkFilter(){
//        if self.filterCaption != nil || (self.filterRange != nil) || (self.filterRange == nil && self.filterGoogleLocationID != nil) || (self.filterMinRating != 0) || (self.filterType != nil) || (self.filterMaxPrice != nil) || (self.filterLegit == true) {
//            self.isFiltering = true
//        } else {
//            self.isFiltering = false
//        }
    }

    // Home Post Search Delegates
    
//    func filterCaptionSelected(searchedText: String?){
//
//        if searchedText == nil {
//            self.handleRefresh()
//
//        } else {
//            print("Searching for \(searchedText)")
//            defaultSearchBar.text = searchedText!
//            self.filterCaption = searchedText
//            self.checkFilter()
//            self.refreshPostsForFilter()
//
//        }
//    }
    
    func userSelected(uid: String?){
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = uid
        self.navigationController?.pushViewController(userProfileController, animated: true)
    }
    
//    func locationSelected(googlePlaceId: String?, googlePlaceName: String?, googlePlaceLocation: CLLocation?, googlePlaceType: [String]?) {
//
//        // Will Filter Posts for Only Posts will tagged Google Location ID and Establishment
//
//        var defaultRange: String? = nil
//        if (googlePlaceType?.contains("locality"))! {
//            // Selected City, So range is 25 Miles
//            defaultRange = "25"
//        } else if (googlePlaceType?.contains("neighbourhood"))! {
//            // Selected City, So range is 25 Miles
//            defaultRange = "5"
//        } else if (googlePlaceType?.contains("establishment"))! {
//            defaultRange = nil
//        } else {
//            defaultRange = "5"
//        }
//
//        self.filterRange = defaultRange
//        self.filterLocation = googlePlaceLocation
//        self.filterLocationName = googlePlaceName
//        self.filterGoogleLocationID = googlePlaceId
//
//        // Check for filtering
//        self.checkFilter()
//        self.refreshPostsForFilter()
//    }
    
    
    
// Handle Refresh/Update
    
    func clearPostIds(){
        self.fetchedPostIds.removeAll()
    }
    
    func clearAllPosts(){
        self.fetchedPostIds.removeAll()
        self.fetchedPosts.removeAll()
        self.refreshPagination()
    }
    
    func clearSort(){
        self.viewFilter?.clearFilter()
    }
    
    func clearCaptionSearch(){
        self.viewFilter?.filterCaption = nil
//        self.refreshPostsForFilter()
    }
    
    func clearFilter(){
        self.viewFilter?.clearFilter()
    }
    
    func refreshPagination(){
        self.isFinishedPaging = false
        self.paginatePostsCount = 0
        self.userPostIdFetched = false
        self.followingPostIdFetched = false
        self.followingListFetched = false
    }
    
    func refreshAll(){
        self.scrolltoFirst = true
        self.clearCaptionSearch()
        self.clearFilter()
        self.clearSort()
        self.clearPostIds()
        self.refreshPagination()
        self.setupNavigationItems()
        self.fetchAllPostIds()
//        self.collectionView?.reloadData()
    }
    
    func refreshPosts(){
        self.clearAllPosts()
    }
    
    func refreshPostsForFilter(){
        self.clearAllPosts()
        self.checkFilter()
        self.collectionView?.reloadData()
        self.scrolltoFirst = true
        self.fetchAllPostIds()
    }
    

    @objc func handleUpdateFeed() {
        // Default Sort to Recent so that user sees most recent post
        
        // Check for new post that was edited or uploaded
        if newPost != nil && newPostId != nil {
            
            self.viewFilter?.filterSort = defaultRecentSort
            self.refreshPostsForFilter()

//            self.fetchedPosts.insert(newPost!, at: 0)
//            self.fetchedPostIds.insert(newPostId!, at: 0)
            
            if self.collectionView?.numberOfItems(inSection: 0) != 0 {
                let indexPath = IndexPath(item: 0, section: 0)
                self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
            }
            self.collectionView?.reloadData()
            print("Pull in new post")

        } else {
            self.handleRefresh()
        }
    }
    
    @objc func handleRefresh() {
        self.scrolltoFirst = true
        self.refreshAll()
        self.collectionView?.refreshControl?.endRefreshing()
        print("Refresh Home Feed. FetchPostIds: ", self.fetchedPostIds.count, "FetchedPostCount: ", self.fetchedPosts.count, " DisplayedPost: ", self.paginatePostsCount)
    }

// Post ID Fetching
    fileprivate func fetchAllPostIds(){
        var uid = Auth.auth().currentUser?.uid
        
        if (Auth.auth().currentUser?.isAnonymous)! {
            print("Guest User, default to WZ stream")
            uid = "2G76XbYQS8Z7bojJRrImqpuJ7pz2"
        } else {
            uid = Auth.auth().currentUser?.uid
        }
        
        print("Home | INIT | Fetch All Post Ids")
        SVProgressHUD.show(withStatus: "Fetching Posts")

        fetchUserPostIds(uid: uid)
        fetchFollowingUserPostIds(uid: uid)
        fetchUserFollowedListPostIds(uid: uid)
        
    }
    
    
    fileprivate func fetchUserPostIds(uid: String?){
        
        guard let uid = uid else {return}

        print(" ~ FetchingPostIDForUser | Fetching User PostIDs")

        Database.fetchAllPostIDWithCreatorUID(creatoruid: uid) { (postIds) in

            self.checkDisplayPostIdForDups(postIds: postIds)
            self.fetchedPostIds = self.fetchedPostIds + postIds

            print("Home | Fetching PostIds | Current User | Post IDs: ", self.fetchedPostIds.count)
            
            self.userPostIdFetched = true
            NotificationCenter.default.post(name: HomeController.finishFetchingUserPostIdsNotificationName, object: nil)
            
        }
    }
    


    
    fileprivate func fetchFollowingUserPostIds(uid: String?){
        
        guard let uid = uid else {return}
        let thisGroup = DispatchGroup()
        
        print(" ~ FetchingPostIDForUser | Fetching Followed PostIDs")

        
        Database.fetchFollowingUserUids(uid: uid) { (fetchedFollowingUsers) in
            
            CurrentUser.followingUids = fetchedFollowingUsers
            print("Fetching PostIds | Current User Following | \(fetchedFollowingUsers.count) Users")

            thisGroup.enter()
            for userId in fetchedFollowingUsers {
                thisGroup.enter()
                Database.fetchAllPostIDWithCreatorUID(creatoruid: userId) { (postIds) in
                    
                    self.checkDisplayPostIdForDups(postIds: postIds)
                    self.fetchedPostIds = self.fetchedPostIds + postIds

//                    self.fetchedPostIds.sort(by: { (p1, p2) -> Bool in
//                        return p1.creationDate!.compare(p2.creationDate!) == .orderedDescending
//                    })
                    thisGroup.leave()
                }
            }
            thisGroup.leave()
            
            thisGroup.notify(queue: .main) {
                print("Fetching PostIds | Total User/Following | \(self.fetchedPostIds.count) PostIds")
//                print("Current User And Following Posts: ", self.fetchedPostIds.count)
//                print("Number of Following: ",CurrentUser.followingUids.count)
                self.followingPostIdFetched = true
                NotificationCenter.default.post(name: HomeController.finishFetchingFollowingPostIdsNotificationName, object: nil)
                if !(Auth.auth().currentUser?.isAnonymous)!{
                    Database.checkUserSocialStats(user: CurrentUser.user!, socialField: "followingCount", socialCount: CurrentUser.followingUids.count)
                }
            }
        }
    }
    
    fileprivate func fetchUserFollowedListPostIds(uid: String?){
        guard let uid = uid else {
            print("Home | fetchUserFollowedListPostIds Error| No UID")
            return
        }

        print(" ~ FetchingPostIDForUser | Fetching Followed List | \(uid)")
        
        let thisGroup = DispatchGroup()

        thisGroup.enter()
        Database.fetchFollowedListIDs(userUid: uid) { (listIds) in
            if listIds.count > 0 {
                var tempListIds:[String] = []
                for list in listIds {
                    tempListIds.append(list.listId)
                }
                
                Database.fetchAllPostIdsForMultLists(listIds: tempListIds, completion: { (postIds) in
                    self.checkDisplayPostIdForDups(postIds: postIds)
                    self.fetchedPostIds = self.fetchedPostIds + postIds
//                    self.checkDisplayPostIdForDups(postIds: self.fetchedPostIds)
                    print("Home | \(uid) | \(listIds.count) Followed List | \(postIds.count) Post Ids")
                    thisGroup.leave()
                })
            } else {
                print("Home | \(uid) No List | \(listIds.count) Followed List")
                thisGroup.leave()
            }

        }
        
        thisGroup.notify(queue: .main) {
            self.followingListFetched = true
            NotificationCenter.default.post(name: HomeController.finishFetchingFollowingPostIdsNotificationName, object: nil)

        }
        
    }
    
    fileprivate func checkDisplayPostIdForDups(postIds : [PostId]){
        var dup = 0
        
        // Check if input IDS are dups in fetchedPostIds
        
        for postId in postIds {
            
            let postIdCheck = postId.id
            if let dupIndex = self.fetchedPostIds.firstIndex(where: { (item) -> Bool in
                item.id == postIdCheck
            }) {
                self.fetchedPostIds.remove(at: dupIndex)
                dup += 1
//                print("Deleted from fetchPostIds Dup Post ID: ", postIdCheck)
            }
        }
        if dup > 0 {
            print("In \(postIds.count) Posts | Out \(self.fetchedPostIds.count) Posts | Deleted \(dup) Dups")
        }
    }

    
// Pagination
    
    @objc func finishPaginationCheck(){
        self.isFinishedPaging = false
        
        if self.paginatePostsCount == (self.fetchedPosts.count) {
            self.isFinishedPaging = true
            SVProgressHUD.dismiss()
        print("Home | Pagination: Finish Paging | Paging: \(self.isFinishedPaging) | \(self.fetchedPosts.count) Posts")
        }
        
        if self.fetchedPosts.count == 0 && self.isFinishedPaging == true {
            print("Home | Pagination: No Results | Paging: \(self.isFinishedPaging) | \(self.fetchedPosts.count) Posts")
        }
        else if self.fetchedPosts.count == 0 && self.isFinishedPaging != true {
            print("Home | Pagination: No Results | Paging: \(self.isFinishedPaging) | \(self.fetchedPosts.count) Posts")
            self.paginatePosts()
        } else {
            print("Home | Paginating \(self.paginatePostsCount) | \(self.fetchedPosts.count) Posts")

            DispatchQueue.main.async(execute: {
                self.collectionView?.reloadData()
                SVProgressHUD.dismiss()
                // Scrolling for refreshed results
                if self.scrolltoFirst && self.fetchedPosts.count > 1{
                    print("Home | Refresh Control Status: ", self.collectionView?.refreshControl?.state)
                    self.collectionView?.refreshControl?.endRefreshing()
                    let indexPath = IndexPath(item: 0, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath, at: .top, animated: true)
//                    self.collectionView?.setContentOffset(CGPoint(x: 0, y: 0 - self.topLayoutGuide.length), animated: true)
                    print("Home | Scrolled to Top")
                    self.scrolltoFirst = false
                }
            
            })
        }
    }
    
    @objc func finishFetchingPostIds(){
        
        // Function is called after User Post are called AND following user post ids are called. So need to check that all post are picked up before refresh
//        print("User PostIds Fetched: \(self.userPostIdFetched), Following PostIds Fetched: \(self.followingPostIdFetched)")
        
        if self.userPostIdFetched && self.followingPostIdFetched && self.followingListFetched {
            print("Home | Fetching PostIds | FINISH User/Following | \(fetchedPostIds.count) PostIds")
            self.fetchAllPosts()
        } else {
            print("Home | Fetching PostIds | Waiting | User: \(self.userPostIdFetched) | Followers: \(self.followingPostIdFetched) | Lists: \(self.followingListFetched)")
        }
    }
    
    @objc func fetchAllPosts(){
        print("Home | Fetching All Post")
        SVProgressHUD.show(withStatus: "Fetching Posts")
        
//        self.checkDisplayPostIdForDups(postIds: self.fetchedPostIds)
        
        Database.fetchAllPosts(fetchedPostIds: self.fetchedPostIds){fetchedPostsFirebase in
            self.fetchedPosts = fetchedPostsFirebase
            print("Home | Success Fetching | \(fetchedPostsFirebase.count) Posts")

            // Update Post Distances
            self.updatePostDistances(refLocation: self.viewFilter?.filterLocation, completion: {
                self.filterSortFetchedPosts()
            })
            guard let uid = Auth.auth().currentUser?.uid else {
                print("Count Most Used Emoji: Error, No uid")
                return
            }
            
            self.countMostUsedEmojis(posts: fetchedPostsFirebase.filter({ (post) -> Bool in
                post.creatorUID == uid
            }))
            
        }
    }
    
    func countMostUsedEmojis(posts: [Post]) {
        Database.countMostUsedEmojis(posts: posts) { (emojis) in
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
    }
    
    
    @objc func filterSortFetchedPosts(){
        
        // Fetches All Posts, Refilters assuming no caption filtered, recount emoji/location
        var noCaptionLocationFilter = Filter.init()
        noCaptionLocationFilter.filterUser = self.viewFilter?.filterUser
        noCaptionLocationFilter.filterList = self.viewFilter?.filterList
        
        Database.filterPostsNew(inputPosts: self.fetchedPosts, postFilter: noCaptionLocationFilter) { (filteredPosts) in
            print("HomeController | filterSortFetchedPosts | NoCaptionLocationFilter")
            Database.countEmojis(posts: filteredPosts) { (emojiCounts) in
                self.noCaptionFilterEmojiCounts = emojiCounts
            }
            
            Database.countCityIds(posts: filteredPosts) { (locationCounts) in
                self.noCaptionFilterLocationCounts = locationCounts
            }
        }
        
    // Filter Posts
        Database.filterPostsNew(inputPosts: self.fetchedPosts, postFilter: self.viewFilter) { (filteredPosts) in

            
    // Sort Posts
            Database.sortPosts(inputPosts: filteredPosts, selectedSort: self.viewFilter?.filterSort, selectedLocation: self.viewFilter?.filterLocation, completion: { (filteredPosts) in
                
                self.fetchedPosts = []
                if filteredPosts != nil {
                    self.fetchedPosts = filteredPosts!
                }
                print("Filter Sorted Post: \(self.fetchedPosts.count)")
                    NotificationCenter.default.post(name: HomeController.finishSortingFetchedPostsNotificationName, object: nil)
            })
        }
    }
    
    let paginateFetchPostSize = 4

    @objc func paginatePosts(){
        self.paginatePostsCount = min(self.paginatePostsCount + self.paginateFetchPostSize, self.fetchedPosts.count)
        NotificationCenter.default.post(name: HomeController.finishPaginationNotificationName, object: nil)
    }
    
    
    fileprivate func fetchGroupUserIds() {
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        Database.database().reference().child("group").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let userIdsDictionary = snapshot.value as? [String: Any] else {return}
            var groupUsers: [String] = []
            
            userIdsDictionary.forEach({ (key,value) in
                groupUsers.append(key)
            })
            CurrentUser.groupUids = groupUsers
            
        }) { (err) in
            print("Failed to fetch group user ids:", err)
        }
    }
    
    func handleToggleViewTest(){
        print("TEST")
    }
    

    
    
    @objc func setupNavigationItems() {
    
        var searchTerm: String = ""
        
        if (self.viewFilter?.isFiltering)! {
            
            let currentFilter = self.viewFilter
            var searchTerm: String = ""

            
            if let locationId = currentFilter?.filterLocationSummaryID {
                searchTerm.append("\(locationId) | ")
            }
            
            if currentFilter?.filterMinRating != 0 {
                searchTerm.append("\((currentFilter?.filterMinRating)!) Stars | ")
            }
            
            print("NavigationItem | SearchTerm | \(searchTerm)")
            if searchTerm.suffix(3) == " | " {
                let endIndex = searchTerm.index(searchTerm.endIndex, offsetBy: -3)
                searchTerm = searchTerm.substring(to: endIndex)
            }
            self.navigationItem.title = searchTerm == "" ? defaultHeader : searchTerm
        } else {
            self.navigationItem.title = defaultHeader
        }
        
        self.navigationController?.navigationBar.isTranslucent = true
//        self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: (self.navigationItem.title == defaultHeader) ? UIColor.white : UIColor.selectedColor(), NSAttributedString.Key.font.rawValue: UIFont(font: .noteworthyBold, size: 20)])
        self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: (self.navigationItem.title == defaultHeader) ? UIColor.white : UIColor.selectedColor(), NSAttributedString.Key.font.rawValue: UIFont(font: .avenirNextDemiBold, size: 20)])
//        self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: (self.navigationItem.title == defaultHeader) ? UIColor.white : UIColor.selectedColor(), NSAttributedString.Key.font.rawValue: UIFont(font: .helveticaNeueBold, size: 20)])


        self.navigationController?.navigationBar.layoutIfNeeded()
        
        // Nav Bar Buttons
        let tempNavBarButton = NavBarMapButton.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        tempNavBarButton.addTarget(self, action: #selector(toggleMapFunction), for: .touchUpInside)
        let barButton1 = UIBarButtonItem.init(customView: tempNavBarButton)
        
        self.navigationItem.leftBarButtonItems = [barButton1]

        if Auth.auth().currentUser?.isAnonymous == true {
            let signOutButton = UIBarButtonItem(image: #imageLiteral(resourceName: "signout").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleGuestLogOut))
            signOutButton.title = "Logout"
            navigationItem.rightBarButtonItem = signOutButton
        } else {
            navFriendButton.addTarget(self, action: #selector(openFriends), for: .touchUpInside)
            let friendButton = UIBarButtonItem.init(customView: navFriendButton)
            navigationItem.rightBarButtonItem = friendButton
            
        // USER PROFILE NAV BUTTON
            
//            navUserButton = UIButton.init(frame: CGRectMake(0, 0, 30, 30))
//            navUserButton.layer.cornerRadius = 30/2
//            navUserButton.layer.masksToBounds = true
//            navUserButton.addTarget(self, action: #selector(openCurrentUserProfile), for: .touchUpInside)
//            navUserButton.layer.borderColor = UIColor.white.cgColor
//            navUserButton.layer.borderWidth = 1
//            navUserButton.setImage(#imageLiteral(resourceName: "profile_selected"), for: .normal)
//
//
//            if let _ = CurrentUser.user?.profileImageUrl {
//                let userProfileImage = CustomImageView()
//                userProfileImage.loadImage(urlString: (CurrentUser.user?.profileImageUrl)!)
//                userProfileImage.contentMode = .scaleAspectFill
//                userProfileImage.clipsToBounds = true
//                let userButtonWidth = self.navUserButton.frame.width
//                navUserButton.setImage(userProfileImage.image?.resizeImageWith(newSize: CGSize(width: userButtonWidth, height: userButtonWidth)), for: .normal)
//            }
//            let userButton1 = UIBarButtonItem.init(customView: navUserButton)
//            navigationItem.rightBarButtonItem = userButton1
//            navigationItem.rightBarButtonItem = UIBarButtonItem(image: resizedUserImage, style: .plain, target: self, action: #selector(openCurrentUserProfile))
        }
    }
    
    @objc func toggleMapFunction(){
        appDelegateFilter = self.viewFilter
        self.toggleMapView()
    }
    
    
    @objc func handleGuestLogOut(){
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            alertController.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { (_) in
                
                do {
                    
                    if Auth.auth().currentUser?.isAnonymous == true {
                        let user = Auth.auth().currentUser
                        user?.delete { error in
                            if let error = error {
                                print("Error Deleting Guest User")
                            } else {
                                print("Guest User Deleted")
                            }
                        }
                    }
                    
                    try Auth.auth().signOut()
                    CurrentUser.clear()
                    let loginController = LoginController()
                    let navController = UINavigationController( rootViewController: loginController)
                    self.present(navController, animated: true, completion: nil)
                    
                } catch let signOutErr {
                    print("Failed to sign out:", signOutErr)
                }
                
            }))
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            present(alertController, animated: true, completion: nil)
    }

    
    func openInbox() {
        let inboxController = InboxController(collectionViewLayout: UICollectionViewFlowLayout())
        navigationController?.pushViewController(inboxController, animated: true)
    }


//    var collectionHeights: [String: CGFloat] = [:]
//
//    func expandPost(post: Post, newHeight: CGFloat) {
//        collectionHeights[post.id!] = newHeight
//        print("Added New Height | ",collectionHeights)
//        print(post.id, newHeight)
//
//    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        var height: CGFloat = 35 //headerview = username userprofileimageview
        height += view.frame.width  // Picture
        height += 60    // Action Bar + List Count
        height += 25    // Date Bar
        
//        var dynamicHeight = collectionHeights[fetchedPosts[indexPath.item].id!] ?? 0
//        height += dynamicHeight

////        height += 20    // Social Counts
////        height += 20    // Caption
        
//        return CGSize(width: view.frame.width, height: height)
        return CGSize(width: view.frame.width, height: view.frame.width + 35 + 50 + 25)

    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
//        return min(4, self.displayedPostsCount)
        return paginatePostsCount
//        return displayedPosts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
//        if indexPath.item == self.displayedPosts.count - 1 && !isFinishedPaging{
//            print("CollectionView Paginate")
//            paginatePosts()
//        }
        
        if indexPath.item == self.paginatePostsCount - 1 && !isFinishedPaging{
            print("CollectionView Paginate")
//            SVProgressHUD.show(withStatus: "Loading Pictures")
            paginatePosts()
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! FullPictureCell
//        cell.post = displayedPosts[indexPath.item]
        
        cell.showDistance = self.viewFilter?.filterSort == defaultNearestSort
        cell.post = fetchedPosts[indexPath.item]

        
        if self.viewFilter?.filterLocation != nil && cell.post?.locationGPS != nil {
            cell.post?.distance = Double((cell.post?.locationGPS?.distance(from: (self.viewFilter?.filterLocation!)!))!)
        }
        
        
        
        cell.currentImage = 1
        cell.delegate = self
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //print(displayedPosts[indexPath.item])
    }
    
// SORT FILTER HEADER
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerId, for: indexPath) as! SearchBarSortHeader
        header.isFiltering = (self.viewFilter?.isFiltering)!
        header.delegate = self
        header.selectedCaption = self.viewFilter?.filterCaption
        header.selectedSort = (self.viewFilter?.filterSort)!
        return header
        
    }
    

    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        return CGSize(width: view.frame.width, height: 40 + 35 + 5)
        return CGSize(width: view.frame.width, height: 40)

    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
//    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! FullPostCell
//        if !(cell.captionViewHeightConstraint?.isActive)! {
//            cell.captionViewHeightConstraint?.isActive = true
//            collectionView.reloadItems(at: [indexPath])
//        }
//
//    }
    
// EMPTY DATA SET DELEGATES
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        // Don't display empty dataset if still loading
        
        if SVProgressHUD.isVisible() {
            return false
        } else {
            return true
        }
    }
    
    
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
        if (self.viewFilter?.isFiltering)! {
//            self.randomSearch()
            self.handleRefresh()
            
        } else {
            self.openSearch(index: 1)
        }
    }
    
    @objc func randomSearch(){
        self.clearFilter()
        self.viewFilter?.filterLocation = CurrentUser.currentLocation
        self.viewFilter?.filterRange = geoFilterRangeDefault[4]
        print("Random Search: ",self.viewFilter?.filterRange, self.viewFilter?.filterLocation)
        self.refreshPostsForFilter()
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapView view: UIView) {
        self.handleRefresh()
    }
    
//    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
//        let offset = (self.collectionView?.frame.height)! / 5
//            return -50
//    }
    
    func spaceHeight(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return 9
    }
    
    
// HOME POST CELL DELEGATE METHODS
    
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
    
    func didTapUserUid(uid: String) {
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = uid
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapLocation(post: Post) {
        let locationController = LocationController()
        locationController.selectedPost = post
        
        navigationController?.pushViewController(locationController, animated: true)
    }
    
    func displayPostSocialUsers(post:Post, following: Bool){
        print("Display Vote Users| Following: ",following)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayUser = true
        postSocialController.displayUserFollowing = following
        postSocialController.inputPost = post
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    func displayPostSocialLists(post:Post, following: Bool){
        print("Display Lists| Following: ",following)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayList = true
//        postSocialController.displayFollowing = (post.followingList.count > 0)
        postSocialController.displayFollowing = following

        postSocialController.inputPost = post
        navigationController?.pushViewController(postSocialController, animated: true)
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
            // Check Current User List
            if let listIndex = CurrentUser.lists.firstIndex(where: { (currentList) -> Bool in
                currentList.id == tagId
            }) {
                let listViewController = ListViewController()
                listViewController.imageCollectionView.collectionViewLayout = HomeSortFilterHeaderFlowLayout()
                listViewController.currentDisplayList = CurrentUser.lists[listIndex]
                self.navigationController?.pushViewController(listViewController, animated: true)
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
    }
    
    func refreshPost(post: Post) {
        let index = fetchedPosts.firstIndex { (filteredpost) -> Bool in
            filteredpost.id  == post.id
        }
        print("Refreshing Post @ \(index) for post \(post.id)")
        let filteredindexpath = IndexPath(row:index!, section: 0)
        
        self.fetchedPosts[index!] = post
        self.collectionView?.reloadItems(at: [filteredindexpath])
        
        // Update Cache
        postCache.removeValue(forKey: post.id!)
        postCache[post.id!] = post
    }
    
    func didTapMessage(post: Post) {
        let messageController = MessageController()
        messageController.post = post
        messageController.delegate = self
        navigationController?.pushViewController(messageController, animated: true)
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
        
        self.navigationController?.pushViewController(editPost, animated: true)
        
//        let navController = UINavigationController(rootViewController: editPost)
//        self.present(navController, animated: false, completion: nil)
    }
    
    
    func deletePost(post:Post){
        
        let deleteAlert = UIAlertController(title: "Delete", message: "Are You Sure? All Data Will Be Lost!", preferredStyle: UIAlertController.Style.alert)
        deleteAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            
            // Remove from Current View
            let index = self.fetchedPosts.firstIndex { (filteredpost) -> Bool in
                filteredpost.id  == post.id
            }
            
            let deleteindexpath = IndexPath(row:index!, section: 0)
            self.fetchedPosts.remove(at: index!)
            print("Remove Fetched Post at \(index)")
            self.paginatePostsCount += -1
            self.collectionView!.deleteItems(at: [deleteindexpath])
            print("deletePost| Deleted \(post.id) From Current View | \(deleteindexpath)")
            Database.deletePost(post: post)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        present(deleteAlert, animated: true, completion: nil)
        
    }
    
    func displaySelectedEmoji(emoji: String, emojitag: String) {
        
        emojiDetailLabel.text = emoji + " " + emojitag
        emojiDetailLabel.sizeToFit()
        emojiDetailLabel.isHidden = false
        
    }
    
    
    func deletePostFromList(post: Post) {
        
    }
    
    func didTapPicture(post: Post) {
        
        let pictureController = SinglePostView()
        pictureController.post = post

        navigationController?.pushViewController(pictureController, animated: true)
    }
    

//// LOCATION MANAGER DELEGATE METHODS
//
//    func determineCurrentLocation(){
//
//        CurrentUser.currentLocation = nil
//
//        if CLLocationManager.locationServicesEnabled() {
//            locationManager.startUpdatingLocation()
//        }
//    }
//
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        let userLocation:CLLocation = locations[0] as CLLocation
//
//        if userLocation != nil {
//            print("Current User Location", userLocation)
//            CurrentUser.currentLocation = userLocation
//            self.filterLocation = CurrentUser.currentLocation
//            manager.stopUpdatingLocation()
//        }
//    }
//
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        print("GPS Location Not Found")
//    }
    
    func updatePostDistances(refLocation: CLLocation?, completion:() -> ()){
        if let refLocation = refLocation {
            let count = fetchedPosts.count
            for i in 0 ..< count {
                var tempPost = fetchedPosts[i]
                if let _ = tempPost.locationGPS {
                    tempPost.distance = Double((tempPost.locationGPS?.distance(from: refLocation))!)
                } else {
                    tempPost.distance = nil
                }
                fetchedPosts[i] = tempPost
            }
            completion()
        } else {
            print("No Filter Location")
            completion()
        }
    }
    
    // Camera Functions
    func openCamera(){
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            var imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera;
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)

            // Detect Current Location for Photo
            LocationSingleton.sharedInstance.determineCurrentLocation()

        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        
        picker.dismiss(animated: true) {
            let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as! UIImage
            let inputImage = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation: image.imageOrientation)
//            let vc = SHViewController(image: inputImage)
//            vc.delegate = self
//            self.present(vc, animated:true, completion: nil)
            
            print("Pass Picture To Filter")
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        self.dismiss(animated: true, completion: nil)
        self.navigationController?.popToRootViewController(animated: true)
        
    }
    
    func shViewControllerImageDidFilter(image: UIImage) {
        // Filtered image will be returned here.
        self.dismiss(animated: true) {
//            let sharePhotoController = SharePhotoController()
//            sharePhotoController.selectedImage = image
//            sharePhotoController.selectedImageLocation  = CurrentUser.currentLocation
//            sharePhotoController.selectedImageTime  = Date()
//            let navController = UINavigationController(rootViewController: sharePhotoController)
//            self.present(navController, animated: false, completion: nil)
//            print("Upload Picture")
        }
    }
    
        func shViewControllerDidCancel() {
            // This will be called when you cancel filtering the image.
            self.dismiss(animated: true, completion: nil)
            self.navigationController?.popToRootViewController(animated: true)
        }

    
}







// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
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

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
