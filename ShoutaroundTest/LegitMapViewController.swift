//
//  LegitMapViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/1/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit

import mailgun
import GeoFire
import CoreGraphics
import CoreLocation
import EmptyDataSet_Swift
import UIFontComplete
import SVProgressHUD
import MapKit
import BSImagePicker
import TLPhotoPicker
import Photos
import CropViewController
import SKPhotoBrowser
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth

class LegitMapViewController: UIViewController {

    // MARK: - MAP

    let mapView = MKMapView()
    var postDisplayed: Bool = false {
        didSet {
//            self.postCollectionView.isHidden = !postDisplayed
        }
    }
    
    let mapPinReuseInd = "MapPin"
    let regionRadius: CLLocationDistance = 5000
    
    var mapPins: [MapPin] = []
    // THIS IS TO BYPASS SCROLLVIEW CALL FUNCTION WHEN SCROLLTOITEM IS CALLED
    var enableScroll: Bool = true
    
    // MARK: - SEARCH
    var mapFilter: Filter = Filter.init(defaultSort: defaultNearestSort){
        didSet{
            mapFilter.filterLocationName = (mapFilter.filterLocation == CurrentUser.currentLocation) ? CurrentUserLocation : mapFilter.filterLocationName
            self.updateSearchTerms()

            setupNavigationItems()
        }
    }
    
    func updateSearchTerms() {
        searchTerms = Array(Set(self.mapFilter.searchTerms))
        self.emojiCollectionView.reloadData()
    }
    
    let search = LegitSearchViewController()
    
    var noFilterTagCounts: PostTagCounts = PostTagCounts.init()
    var currentPostTagCounts: PostTagCounts = PostTagCounts.init()
    var noCaptionFilterTagCounts: [String:Int] = [:]
    var currentPostsFilterTagCounts: [String:Int] = [:]
    var first50EmojiCounts: [String:Int] = [:]
    var searchTerms: [String] = []

    @objc func didTapSearchButton() {
        print("Tap Search | \(self.currentPostsFilterTagCounts.count) Tags | \(self.mapFilter.searchTerms)")
        search.delegate = self
        search.viewFilter = self.mapFilter
//        search.noCaptionFilterTagCounts = self.noCaptionFilterTagCounts
//        search.currentPostsFilterTagCounts = self.currentPostsFilterTagCounts
        search.noFilterTagCounts = self.noFilterTagCounts
        search.currentPostTagCounts = self.currentPostTagCounts
        search.searchBar.text = ""

        let testNav = UINavigationController(rootViewController: search)
        
//        let transition = CATransition()
//        transition.duration = 0.5
//        transition.type = CATransitionType.push
//        transition.subtype = CATransitionSubtype.fromBottom
//        transition.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
//        view.window!.layer.add(transition, forKey: kCATransition)
        self.present(testNav, animated: true) {
            print("   Presenting List Option View")
        }
    }
    
    
    
    func checkAppDelegateFilter(){

        if appDelegateFilter != nil {
            let transferFilter = appDelegateFilter!
            if self.mapFilter.filterSummary() == transferFilter.filterSummary()
            {
                print("checkAppDelegateFilter | Same Filter | No Refresh")
            }
            else {
                self.mapFilter = appDelegateFilter!
                self.mapFilter.filterSort = defaultNearestSort
                print("checkAppDelegateFilter | Reload App Delegate Filter | Refresh Map")
                appDelegateFilter = nil
                self.refreshPostsForFilter()
            }
        } else {
            print("checkAppDelegateFilter | No App Delegate Filter")
        }
        

    }
    

    // MARK: - NAVIGATION

    var navHomeButton: UIButton = TemplateObjects.NavBarHomeButton()
    var navSearchButton: UIButton = TemplateObjects.NavSearchButton()
    var navSearchButtonFull: UIButton = TemplateObjects.NavSearchButton()

//    var navCancelButton: UIButton = TemplateObjects.NavCancelButton()


    // MARK: - NAVIGATION - SEARCH BAR

    let fullSearchBarView = UIView()
    var fullSearchBar = UISearchBar()
    lazy var fullSearchBarCancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.tintColor = UIColor.ianBlackColor()
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.addTarget(self, action: #selector(tapCancelButton), for: .touchUpInside)
        return button
    }()
    
    
    @objc func tapCancelButton() {
        self.handleRefresh()
    }

    
    @objc func toggleListView(){
        
        appDelegateFilter = self.mapFilter
        if self.mapFilter.filterList != nil {
            appDelegateViewPage = 1
            print("Toggle MapView | List View | \(appDelegateViewPage)")
        } else if self.mapFilter.filterUser != nil {
            appDelegateViewPage = 2
            print("Toggle MapView | User View | \(appDelegateViewPage)")
        } else {
            appDelegateViewPage = 0
            print("Toggle MapView | Home View | \(appDelegateViewPage)")
        }
        
        NotificationCenter.default.post(name: AppDelegate.SwitchToListNotificationName, object: nil)
        
    }
    
    var keyboardTap = UITapGestureRecognizer()
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if (self.isViewLoaded && (self.view.window != nil)) {
            print("keyboardWillShow | Add Tap Gesture | SingleUserProfileViewController")
            self.view.addGestureRecognizer(self.keyboardTap)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification){
        if (self.isViewLoaded && (self.view.window != nil)) {
            print("keyboardWillHide | Remove Tap Gesture | SingleUserProfileViewController")
            self.view.removeGestureRecognizer(self.keyboardTap)
        }
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
//        userSearchBar.resignFirstResponder()
        print("dismissKeyboard | SingleUserProfileViewController")
        self.view.endEditing(true)
    }
        
    
    
    // MARK: - COLLECTIONVIEW - EMOJIS
    
    let emojiCollectionView: UICollectionView = {
        let uploadEmojiList = UICollectionViewFlowLayout()
//        uploadEmojiList.estimatedItemSize = CGSize(width: 30, height: 30)
        uploadEmojiList.estimatedItemSize = CGSize(width: 120, height: 35)
        uploadEmojiList.sectionInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        uploadEmojiList.scrollDirection = .horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadEmojiList)
        cv.layer.borderWidth = 0
        cv.backgroundColor = UIColor.white
        return cv
    }()
    
    let addTagId = "addTagId"
    let filterTagId = "filterTagId"
    let refreshTagId = "refreshTagId"

    var displayedEmojis: [String] = [] {
        didSet {
            print("LegitHomeHeader | \(displayedEmojis.count) Emojis")
            self.emojiCollectionView.reloadData()
        }
    }
    
    var listDefaultEmojis = mealEmojisSelect
    
    
    // MARK: - COLLECTIONVIEW - POSTS
    lazy var postCollectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = .white
        cv.layer.borderColor = UIColor.darkLegitColor().cgColor
        return cv
    }()
    
    let postCollectionViewFlowLayout = UICollectionViewFlowLayout()
    
    let cellId = "cellId"
    let gridCellId = "gridcellId"
    let listHeaderId = "headerId"
    var scrolltoFirst: Bool = false
    
    let postContainer = UIView()
    var postContainerHeightConstraint:NSLayoutConstraint?
    var postHalfHeight = 100
    var postFullHeight = 350
    var isPostFullView: Bool = false {
        didSet {
//            self.refreshPostCollectionView()
            self.togglePostHeight()
        }
    }

    var pageControl : UIPageControl = UIPageControl()

    let emojiDetailLabel: LightPaddedUILabel = {
        let label = LightPaddedUILabel()
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
    
    /*
    var hidePostHeightConstraint:NSLayoutConstraint?
    var postViewHeightConstraint:NSLayoutConstraint?
    var fullListViewConstraint:NSLayoutConstraint?
    
    var mapViewHeightConstraint:NSLayoutConstraint?
    
    let hideMapViewHideHeight: CGFloat = UIApplication.shared.statusBarFrame.height
    
    let headerHeight: CGFloat = 40 //40
    let postHeight: CGFloat = 180 //150
    let fullHeight: CGFloat = UIScreen.main.bounds.height - UIApplication.shared.statusBarFrame.height
    */
    
    let navView = UIView()
    let navSearchView = UIView()
    
    lazy var expandListButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "listFormat").withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.tintColor = UIColor.white
        button.backgroundColor = UIColor.ianBlackColor()
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.addTarget(self, action: #selector(expandList), for: .touchUpInside)
        return button
    }()

    @objc func expandList(){
        print("Expand List")
    }
    
    lazy var trackingButton: MKUserTrackingButton = {
        let button = MKUserTrackingButton()
        //        button.layer.backgroundColor = UIColor(white: 1, alpha: 0.8).cgColor
        button.layer.backgroundColor = UIColor.lightGray.withAlphaComponent(0.25).cgColor
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 5
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()
    
    lazy var zoomOutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "listFormat").withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.tintColor = UIColor.white
        button.backgroundColor = UIColor.ianBlackColor()
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.addTarget(self, action: #selector(expandList), for: .touchUpInside)
        return button
    }()
    
    fileprivate func setupNavigationItems() {
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.isNavigationBarHidden = true
        
        self.navigationController?.navigationBar.isTranslucent = true
        // REMOVES THE 1PX BOTTOM LINE IN NAV BAR
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        

 
//        self.setupButtons()
        // SEARCH BAR
//        self.refreshSearchBar()
        
    }
    


    
    func showClearNavBar(){
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.layoutIfNeeded()
        
        
    }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } 
        
        if appDelegateFilter != nil {
            print("MainViewController | Filter Init | Load AppDelegateFilter")
            self.checkAppDelegateFilter()
//            self.mapFilter = appDelegateFilter!
        } else {
            print("MainViewController | Filter Init | No AppDelegateFilter - Self Init")
//            self.mapFilter = Filter.init()
        }

        setupNotificationCenters()
        setupNavigationItems()
        
    // ADD MAP VIEW
        setupMap()
        view.addSubview(mapView)
        mapView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        self.centerMapOnLocation(location: (self.mapFilter.filterLocation != nil) ? self.mapFilter.filterLocation : CurrentUser.currentLocation)
        
        
    // ADD TOP NAV BARS
        navView.backgroundColor = UIColor.clear
        view.addSubview(navView)
        navView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 60)
        
        navHomeButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleListView)))
        view.addSubview(navHomeButton)
        navHomeButton.anchor(top: nil, left: navView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 0, width: 80, height: 30)
        navHomeButton.centerYAnchor.constraint(equalTo: navView.centerYAnchor).isActive = true
        
        
        view.addSubview(navSearchView)
        navSearchView.anchor(top: nil, left: navHomeButton.rightAnchor, bottom: nil, right: navView.rightAnchor, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 20, width: 0, height: 35)
        navSearchView.backgroundColor = UIColor.white
        navSearchView.centerYAnchor.constraint(equalTo: navView.centerYAnchor).isActive = true
        navSearchView.layer.applySketchShadow(color: UIColor(red: 0, green: 0, blue: 0, alpha: 0.5), alpha: 0.5, x: 0, y: 2, blur: 4, spread: 0)
        
        navSearchView.addSubview(navSearchButton)
        navSearchButton.anchor(top: navSearchView.topAnchor, left: nil, bottom: navSearchView.bottomAnchor, right: navSearchView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 35, height: 35)
        navSearchButton.centerYAnchor.constraint(equalTo: navSearchView.centerYAnchor).isActive = true
        navSearchButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapSearchButton)))
        
        setupEmojiCollectionView()
        
        navSearchView.addSubview(emojiCollectionView)
        emojiCollectionView.anchor(top: navSearchView.topAnchor, left: navSearchView.leftAnchor, bottom: navSearchView.bottomAnchor, right: navSearchButton.leftAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 20, width: 0, height: 35)
        
        emojiCollectionView.centerYAnchor.constraint(equalTo: navSearchView.centerYAnchor).isActive = true
        
/*
        // FULL SEARCH BAR
        navSearchView.addSubview(fullSearchBarView)
        fullSearchBarView.anchor(top: navSearchView.topAnchor, left: navSearchView.leftAnchor, bottom: navSearchView.bottomAnchor, right: navSearchView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        fullSearchBarView.layer.borderColor = UIColor.ianBlackColor().cgColor
        fullSearchBarView.layer.borderWidth = 0
        fullSearchBarView.backgroundColor = UIColor.white
        
        fullSearchBarView.addSubview(fullSearchBarCancelButton)
        fullSearchBarCancelButton.anchor(top: nil, left: nil, bottom: nil, right: fullSearchBarView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 20, height: 20)
        fullSearchBarCancelButton.centerYAnchor.constraint(equalTo: fullSearchBarView.centerYAnchor).isActive = true
        
        setupSearchBar()
        
        fullSearchBarView.addSubview(fullSearchBar)
        fullSearchBar.anchor(top: fullSearchBarView.topAnchor, left: fullSearchBarView.leftAnchor, bottom: fullSearchBarView.bottomAnchor, right: fullSearchBarCancelButton.leftAnchor, paddingTop: 3, paddingLeft: 8, paddingBottom: 3, paddingRight: 5, width: 0, height: 0)
        
        fullSearchBarView.addSubview(navSearchButtonFull)
        navSearchButtonFull.layer.borderWidth = 0
        navSearchButtonFull.anchor(top: fullSearchBarView.topAnchor, left: fullSearchBarView.leftAnchor, bottom: fullSearchBarView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 30, height: 30)
        
        fullSearchBarView.alpha = 0
*/
        
        
    // ADD BOTTOM NAV
        view.addSubview(expandListButton)
        expandListButton.anchor(top: nil, left: nil, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 15, paddingRight: 20, width: 30, height: 30)

        
        view.addSubview(trackingButton)
        trackingButton.anchor(top: nil, left: nil, bottom: expandListButton.topAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 20, width: 30, height: 30)
        trackingButton.centerXAnchor.constraint(equalTo: expandListButton.centerXAnchor).isActive = true
        trackingButton.isHidden = false
        trackingButton.backgroundColor = UIColor.white.withAlphaComponent(0.75)
        
        
        
        view.addSubview(postContainer)
//        postContainer.anchor(top: nil, left: expandListButton.rightAnchor, bottom: expandListButton.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        postContainer.anchor(top: nil, left: view.leftAnchor, bottom: expandListButton.bottomAnchor, right: expandListButton.leftAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        postContainerHeightConstraint = postContainer.heightAnchor.constraint(equalToConstant: 20)
        postContainerHeightConstraint?.isActive = true
        postContainer.backgroundColor = UIColor.lightBackgroundGrayColor()
        postContainer.layer.applySketchShadow(color: UIColor(red: 0, green: 0, blue: 0, alpha: 1), alpha: 0.5, x: 0, y: 8, blur: 4, spread: 0)
        
        
        let pageControlContainer = UIView()
        postContainer.addSubview(pageControlContainer)
        pageControlContainer.anchor(top: nil, left: postContainer.leftAnchor, bottom: postContainer.bottomAnchor, right: postContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 25)
        pageControlContainer.backgroundColor = UIColor.lightBackgroundGrayColor()

        
        setupPageControl()
        view.addSubview(pageControl)
//        pageControl.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 10)
//        pageControl.leftAnchor.constraint(lessThanOrEqualTo: pageControlContainer.leftAnchor, constant: 10).isActive = true
//        pageControl.rightAnchor.constraint(lessThanOrEqualTo: pageControlContainer.rightAnchor, constant: 10).isActive = true
//        pageControl.centerXAnchor.constraint(equalTo: pageControlContainer.centerXAnchor).isActive = true
//        pageControl.centerYAnchor.constraint(equalTo: pageControlContainer.centerYAnchor).isActive = true

        pageControl.anchor(top: pageControlContainer.topAnchor, left: pageControlContainer.leftAnchor, bottom: pageControlContainer.bottomAnchor, right: pageControlContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        pageControl.backgroundColor = UIColor.mainBlue()

        
        setupPostCollectionView()
        postContainer.addSubview(postCollectionView)
        postCollectionView.anchor(top: postContainer.topAnchor, left: postContainer.leftAnchor, bottom: pageControlContainer.topAnchor, right: postContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        view.addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top: nil, left: nil, bottom: postContainer.topAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 3, paddingRight: 0, width: 0, height: 0)
        emojiDetailLabel.centerXAnchor.constraint(equalTo: postContainer.centerXAnchor).isActive = true
        self.hideEmojiDetailLabel()

        
        
    }
    
    
    func setupPageControl(){
        self.pageControl.numberOfPages = (self.fetchedPosts.count) ?? 3
        self.pageControl.currentPage = 0
        self.pageControl.tintColor = UIColor.lightGray
        self.pageControl.pageIndicatorTintColor = UIColor.lightGray
        self.pageControl.currentPageIndicatorTintColor = UIColor.ianLegitColor()
//        self.pageControl.isHidden = (self.pageControl.numberOfPages == 0)
        //        self.pageControl.backgroundColor = UIColor.rgb(red: 68, green: 68, blue: 68)
    }

    
    
    func setupNotificationCenters(){
        
        // FUNCTIONS FOR NEW POSTS
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateFeed), name: SharePhotoListController.updateFeedNotificationName, object: nil)
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.setupNavigationItems()
        self.checkAppDelegateFilter()
        if CurrentUser.user == nil {
            Database.loadCurrentUser(inputUser: nil) {
                self.fetchAllPostIds()
            }
        }
        
           // KEYBOARD TAPS TO EXIT INPUT
           self.keyboardTap = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
           NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
           NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - POST FETCHING AND HANDLING
    
    // POST VARIABLES
    var selectedMapPost: Post? = nil {
        didSet {
            print("  ~ selectedMapPost | \(selectedMapPost?.id)")
//            self.showSelectedPost()
        }
    }
    var fetchedPostIds: [PostId] = []
    var fetchedPosts: [Post] = [] {
        didSet{
//            self.setupPageControl()
//            self.postCountLabel.text = "\(self.fetchedPosts.count) Posts"
//            self.postCountLabel.sizeToFit()
        }
    }
    var isFetching = false

    var noCaptionFilterEmojiCounts: [String:Int] = [:]
    var noCaptionFilterPlaceCounts: [String:Int] = [:]
    var noCaptionFilterCityCounts: [String:Int] = [:]
    
    
    // FETCHING POSTS
    fileprivate func fetchAllPostIds(){
        SVProgressHUD.show(withStatus: "Loading Posts")
        Database.fetchCurrentUserAllPostIds { (postIds) in
            print("   ~ Database | Fetched PostIds | \(postIds.count)")
            self.fetchedPostIds = postIds
            self.fetchAllPosts()
//            NotificationCenter.default.post(name: MainViewController.finishFetchingUserPostIdsNotificationName, object: nil)
        }
    }

    
    @objc func finishFetchingPostIds(){
        self.fetchAllPosts()
    }
    
    func fetchAllPosts(){
        if isFetching {
            print(" ~ BUSY FETCHING POSTS")
        } else {
            isFetching = true
        }
        
        print("MainView | Fetching All Post, Current Location: ", CurrentUser.currentLocation?.coordinate)
        Database.fetchAllPosts(fetchedPostIds: self.fetchedPostIds){fetchedPostsFirebase in
            
            self.fetchedPosts = fetchedPostsFirebase
            
            // Remove all post without GPS Location
            for post in self.fetchedPosts {
                if post.locationGPS == nil || (post.locationGPS?.coordinate.latitude == 0 && post.locationGPS?.coordinate.longitude == 0) {
                    if let index = self.fetchedPosts.firstIndex(where: { (curpost) -> Bool in
                        return curpost.id == post.id
                    }){
                        self.fetchedPosts.remove(at: index)
                    }
                }
            }
            
            self.filterSortFetchedPosts()
        }
    }
    
    func updateNoFilterCounts(){
        
        Database.summarizePostTags(posts: self.fetchedPosts) { (tagCounts) in
            self.currentPostTagCounts = tagCounts
            self.currentPostsFilterTagCounts = tagCounts.allCounts
            if !self.mapFilter.isFiltering {
                self.noCaptionFilterTagCounts = tagCounts.allCounts
                self.noFilterTagCounts = tagCounts
            }
        }
        
        let first50 = Array(self.fetchedPosts.prefix(50))
    
        Database.countEmojis(posts: first50) { (emojiCounts) in
            self.first50EmojiCounts = emojiCounts
//            self.initSearchSelections()
            print("   HomeView | NoFilter Emoji Count | \(emojiCounts.count)")
        }
        
        /*
        if self.noCaptionFilterCityCounts.count == 0 {
            Database.countCityIds(posts: self.fetchedPosts) { (locationCounts) in
                self.noCaptionFilterCityCounts = locationCounts
//                self.initSearchSelections()
                print("   LegitMapView | NoFilter City Count | \(locationCounts.count)")
            }
        }
        
        if self.noCaptionFilterPlaceCounts.count == 0 {
            Database.countLocationNames(posts: self.fetchedPosts) { (locationCounts) in
                self.noCaptionFilterPlaceCounts = locationCounts
//                self.initSearchSelections()
                print("   LegitMapView | NoFilter Location Name Count | \(locationCounts.count)")
            }
        }
        
        if self.noCaptionFilterEmojiCounts.count == 0 {
            Database.countEmojis(posts: self.fetchedPosts) { (emojiCounts) in
                self.noCaptionFilterEmojiCounts = emojiCounts
//                self.initSearchSelections()
                print("   LegitMapView | NoFilter Emoji Count | \(emojiCounts.count)")
                
            }
        }
         */


    }
    

    
    func filterSortFetchedPosts(){
        
        updateNoFilterCounts()
        
        // Filter Posts
        Database.filterPostsNew(inputPosts: self.fetchedPosts, postFilter: self.mapFilter) { (filteredPosts) in
            
            // Sort Posts
            Database.sortPosts(inputPosts: filteredPosts, selectedSort: self.mapFilter.filterSort, selectedLocation: self.mapFilter.filterLocation, completion: { (filteredPosts) in
                

                
                self.fetchedPosts = []
                if filteredPosts != nil {
                    self.fetchedPosts = filteredPosts!
                    print("   ~ Database | \(filteredPosts!.count ?? 0) Posts | After Sort/Filter")
                }

                if (self.mapFilter.isFiltering) {
                    // IF SELECTED SPECIFIC POST ID
                    if let filterPostId = self.mapFilter.filterPostId {
                        self.selectedMapPost = self.fetchedPosts.filter({ (post) -> Bool in
                            post.id == filterPostId
                        }).first
                        self.showSelectedPost()
                    }
                        
                    else if self.fetchedPosts.count > 0 {
                        print("Filter Sort | Is Filtering | Auto selected post | \(self.selectedMapPost?.id)")
                        self.selectedMapPost = self.fetchedPosts[0]
                        
                        //                        if self.mapFilter?.filterSort == defaultNearestSort {
                        //                            if let closestLocation = self.fetchedPosts[0].locationGPS{
                        //                                self.centerMapOnLocation(location: self.mapFilter?.filterLocation, closestLocation: closestLocation)
                        //                            }
                        //                        }
                        
                    } else if self.fetchedPosts.count == 0 {
                        print("Filter Sort | Is Filtering | No Post")
                        self.hidePost()
                    }
                }
                
                self.isFetching = false
                self.refreshMap()
//                self.setupPageControl()
                self.refreshPostCollectionView()
                print("Filter Sorted Post: \(self.fetchedPosts.count) || Selected | \(self.selectedMapPost?.id) ")

//                NotificationCenter.default.post(name: MainViewController.finishSortingFetchedPostsNotificationName, object: nil)
                //                self.showFilterView()
                
            })
        }
    }
    
    func refreshPostCollectionView(){
//        self.setupPageControl()
//        self.pageControl.numberOfPages = (self.fetchedPosts.count) ?? 0
//        self.pageControl.sizeToFit()
//        self.postCollectionViewFlowLayout.estimatedItemSize = CGSize(width: self.postCollectionView.frame.width, height: CGFloat(self.isPostFullView ? self.postFullHeight : self.postHalfHeight))
        
        self.postCollectionViewFlowLayout.estimatedItemSize = CGSize(width: self.postCollectionView.frame.width, height: CGFloat(self.postFullHeight))
        self.postCollectionView.collectionViewLayout = self.postCollectionViewFlowLayout
        self.view.layoutIfNeeded()
        self.postContainerHeightConstraint?.constant = CGFloat(20 + (self.isPostFullView ? self.postFullHeight : self.postHalfHeight))

        self.postCollectionView.reloadData()
        SVProgressHUD.dismiss()
        print("LegitMapViewController | refreshPostCollectionView | Complete")
        


    }
    
    func togglePostHeight(){
        self.postContainerHeightConstraint?.constant = CGFloat(20 + (self.isPostFullView ? self.postFullHeight : self.postHalfHeight))
//        self.postCollectionViewFlowLayout.estimatedItemSize = CGSize(width: self.postCollectionView.frame.width, height: CGFloat(self.isPostFullView ? self.postFullHeight : self.postHalfHeight))
//        self.postCollectionView.collectionViewLayout = self.postCollectionViewFlowLayout
        self.showSelectedPost()
    }
    
    func showSelectedPost() {
        guard let selectedPostId = self.selectedMapPost?.id else {return}
        if let index = self.fetchedPosts.firstIndex(where: { (post) -> Bool in
            return post.id == selectedPostId
        }) {
            
            let currentIndex = Int(self.postCollectionView.contentOffset.x / self.postCollectionView.frame.size.width)
            if index != currentIndex {
                print("Need to Scroll Post to Selected Index | selected \(index) | current \(currentIndex)")
                
                if self.postCollectionView.numberOfItems(inSection: 0) >= index {
                    let indexpath = IndexPath(row:index, section: 0)
                    self.postCollectionView.reloadItems(at: [indexpath])
                    self.postCollectionView.scrollToItem(at: indexpath, at: .centeredHorizontally, animated: false)
                    print("showSelectedPost | Scroll to Post | \(index) | \(self.selectedMapPost?.id)")
                } else {
                    print("showSelectedPost | No Post Yet. Need to reload | \(index) | \(self.postCollectionView.numberOfItems(inSection: 0)) | \(self.selectedMapPost?.id)")
                    self.postCollectionView.reloadData()
                }

            } else {
                print("Already Scrolled to Selected Index | selected \(index) | current \(currentIndex)")
            }
        } else {
            // CAN'T FIND SELECTED POST ID IN FETCHED POST
            self.postCollectionView.reloadData()
            print("showSelectedPost | Can't Find Post - Reloading Post CV | \(self.selectedMapPost?.id)")
        }
    }
    
    
    func showSelectedPostOnMap() {
        let selectedPostId = self.selectedMapPost?.id ?? ""
        let postLocationName = self.selectedMapPost?.locationName ?? ""
        let postLocationGoogleId = self.selectedMapPost?.locationGooglePlaceID ?? ""

        var selectedAnnotation: MKAnnotation?
        
        
    // PICK ANNOTATION BY GOOGLE ID FIRST
        if postLocationGoogleId != ""
        {
            print(self.mapView.annotations)
             selectedAnnotation = self.mapView.annotations.first { (annotationPost) -> Bool in
                if let annotation = annotationPost as? MapPin {
                    return annotation.locationGoogleId == postLocationGoogleId
                } else {
                    print("showSelectedPostOnMap | Can't find the annotation | postLocationGoogleId | \(selectedPostId)")
                    return false
                }
            }
        }
            
    // PICK ANNOTATION BY LOCATION NAME

        else if postLocationName != ""
        {
             selectedAnnotation = self.mapView.annotations.first { (annotationPost) -> Bool in
                if let annotation = annotationPost as? MapPin {
                    return annotation.locationName == postLocationName
                } else {
                    print("showSelectedPostOnMap | Can't find the annotation | postLocationName | \(selectedPostId)")
                    return false
                }
            }
        }
        
    // PICK ANNOTATION BY POST ID

            else if selectedPostId != ""
            {
                 selectedAnnotation = self.mapView.annotations.first { (annotationPost) -> Bool in
                    if let annotation = annotationPost as? MapPin {
                        return annotation.postId == selectedPostId
                    } else {
                        print("showSelectedPostOnMap | Can't find the annotation | selectedPostId | \(selectedPostId)")
                        return false
                    }
                }
            }
        

        
        if let selectedAnnotation = selectedAnnotation
        {
            self.mapView.selectAnnotation(selectedAnnotation, animated: true)
            let tempLoc = CLLocation(latitude: selectedAnnotation.coordinate.latitude, longitude: selectedAnnotation.coordinate.longitude)
            self.centerMapOnLocation(location: tempLoc, radius: 5000, closestLocation: nil)
            print(" Go to Post Selected - \(selectedPostId)")
        } else {
            print(" Going to Cur Loc, Failed to Selected Post - \(selectedPostId)")
            self.centerMapOnLocation(location: CurrentUser.currentLocation)
        }
    }
    
    
    func showPostSummary(){
        
    }
    
    
    func showPostFull(){
        
    }
    
    func showListFull(){
        
    }
    
    func hidePost(){
        
    }
    
    // MARK: - REFRESH FUNCTIONS
    func clearPostIds(){
        self.fetchedPostIds.removeAll()
    }
    
    func clearAllPosts(){
        self.fetchedPostIds.removeAll()
        self.fetchedPosts.removeAll()
        self.refreshPagination()
    }
    
    func clearSort(){
        self.mapFilter.refreshSort()
    }
    
    func clearCaptionSearch(){
        self.mapFilter.filterCaption = nil
        self.fullSearchBar.text = nil
        self.refreshPostsForFilter()
    }
    
    func clearFilter(){
        self.mapFilter.clearFilter()
        self.emojiCollectionView.reloadData()
    }
    
    func clearList(){
        self.mapFilter.filterList = nil
        self.refreshPostsForFilter()
    }
    
    func refreshPagination(){
        self.isFinishedPaging = false
        self.paginatePostsCount = 0
//        self.userPostIdFetched = false
//        self.followingPostIdFetched = false
    }
    
    func refreshAll(){
        self.clearCaptionSearch()
        self.clearFilter()
        self.clearSort()
        self.clearPostIds()
        self.refreshPagination()
        self.setupNavigationItems()
        self.fetchAllPostIds()
        self.refreshSearchBar()
        //        self.postCollectionView.reloadData()
        //        self.collectionView?.reloadData()
    }
    
    func refreshPosts(){
        self.clearAllPosts()
    }
    
    func refreshPostsForFilter(){
        self.setupNavigationItems()
        self.clearAllPosts()
        //        self.postCollectionView.reloadData()
        //        self.postCollectionView.layoutIfNeeded()
        self.refreshSearchBar()
        self.scrolltoFirst = true
        self.fetchAllPostIds()
        self.emojiCollectionView.reloadData()
        
    }

    
    @objc func handleUpdateFeed() {
        
        // Check for new post that was edited or uploaded
        if newPost != nil && newPostId != nil {#imageLiteral(resourceName: "icons8-hash-30.png")
            self.fetchedPosts.insert(newPost!, at: 0)
            self.fetchedPostIds.insert(newPostId!, at: 0)
            
            self.postCollectionView.reloadData()
            if self.postCollectionView.numberOfItems(inSection: 0) != 0 {
                let indexPath = IndexPath(item: 0, section: 0)
                self.postCollectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
            }
            print("Pull in new post")
            
        } else {
            self.handleRefresh()
        }
    }
    
    func refreshWithoutMovingMap(){
        self.refreshAll()
        self.postCollectionView.refreshControl?.endRefreshing()
    }
    
    @objc func handleRefresh() {
        self.refreshAll()
        self.postCollectionView.refreshControl?.endRefreshing()
        print("Refresh Home Feed. FetchPostIds: ", self.fetchedPostIds.count, "FetchedPostCount: ", self.fetchedPosts.count, " DisplayedPost: ", self.paginatePostsCount)
        self.centerMapOnLocation(location: CurrentUser.currentLocation)
    }
    
    
    // MARK: - PAGINATION

    
    var paginatePostsCount: Int = 0
    
    var isFinishedPaging = false {
        didSet{
            if isFinishedPaging == true {
                print("Paging Finish: \(self.isFinishedPaging), \(self.paginatePostsCount) Posts")
            }
        }
    }
    

    
}

// MARK: - MAP

extension LegitMapViewController : MKMapViewDelegate {

    func setupMap(){
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.mapType = MKMapType.standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.register(MapPinMarkerView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.register(ClusterMapPinMarkerView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        
        mapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapMap)))
        
        
        trackingButton = MKUserTrackingButton(mapView: mapView)
        //        button.layer.backgroundColor = UIColor(white: 1, alpha: 0.8).cgColor
        trackingButton.layer.backgroundColor = UIColor.lightGray.withAlphaComponent(0.25).cgColor
        trackingButton.layer.borderColor = UIColor.white.cgColor
        trackingButton.layer.borderColor = UIColor.mainBlue().cgColor
        
        trackingButton.layer.borderWidth = 1
        trackingButton.layer.cornerRadius = 5
        trackingButton.translatesAutoresizingMaskIntoConstraints = true
    }
    
    @objc func didTapMap(){
        
//        if self.isPostFullView {
//            print("Tap Map | Minimize Post View ")
//            self.isPostFullView = false
//        }
    }
    
    @objc func minimizeCollectionView(){
        if self.isPostFullView {
            print("Minimize Post View | hideMinimizeCollectionView")
            self.isPostFullView = false
        }
    }
    
    @objc func refreshMap(){
        print("LegitMapViewController | Refresh Map ")
        self.addMapPins()
    }

    func removeMapPins(){
        print("LegitMapViewController | Remove All Map Pins ")

        for annotation in self.mapView.annotations {
            // REMOVE ALL ANNOTATION BESIDES USER CURRENT LOCATION
            if (!annotation.isKind(of: MKUserLocation.self)){
                self.mapView.removeAnnotation(annotation)
            }
        }
    }
    
    func addMapPins(){
        print("LegitMapViewController | Adding Map Pins ")
        SVProgressHUD.show(withStatus: "Refreshing Map Pins")
        
        self.mapPins = []
        self.removeMapPins()
        
        if self.fetchedPosts.count == 0 {
            print("LegitMapViewController | No Posts | Adding 0 Map Pins ")
            return
        }
        
    // ADD MAP PINS
        for post in self.fetchedPosts {
            if post.locationGPS != nil && post.id != nil {
                self.mapPins.append(MapPin(post: post))
            }
        }
        mapView.addAnnotations(self.mapPins)
        print("Added Map Pins | Added \(mapView.annotations.count) Pins | \(self.mapPins.count) Posts ")
        
        
    // MAPVIEW FOCUS
        
        let tempSortPost = self.fetchedPosts.sorted(by: { (p1, p2) -> Bool in
            return (Double(p1.distance ?? 9999)) <= (Double(p2.distance  ?? 9999))
        })
        
        let closestPost = (tempSortPost.count > 0) ? tempSortPost[0] : nil
        let filterLocation = self.mapFilter.filterLocation ?? nil
        
        // SELECTED POST ID
        var selectedPostId: String? = nil
        selectedPostId = (appDelegatePostID != nil) ? appDelegatePostID : selectedPostId
        selectedPostId = (mapFilter.filterPostId != nil) ? mapFilter.filterPostId : selectedPostId
        selectedPostId = (self.selectedMapPost?.id != nil) ? self.selectedMapPost?.id : selectedPostId
        
        
    // POST WAS SELECTED - ZOOM TO SELECTED POST LOCATION
        if selectedPostId != nil {
            let selectedAnnotation = self.mapView.annotations.first { (annotationPost) -> Bool in
                if let annotation = annotationPost as? MapPin {
                    return annotation.postId == selectedPostId
                } else {
                    return false
                }
            }

            
            if let selectedAnnotation = selectedAnnotation
            {
                self.mapView.selectAnnotation(selectedAnnotation, animated: true)
                let tempLoc = CLLocation(latitude: selectedAnnotation.coordinate.latitude, longitude: selectedAnnotation.coordinate.longitude)
                self.centerMapOnLocation(location: tempLoc, radius: 5000, closestLocation: nil)
                print(" Go to Post Selected - \(selectedPostId)")
            } else {
                print(" Going to Cur Loc, Failed to Selected Post - \(selectedPostId)")
                self.centerMapOnLocation(location: CurrentUser.currentLocation)
            }
            
            appDelegatePostID = nil
        }
        
        
        
    // USER SEARCHED FOR SPECIFIC LOCATION - ZOOM TO LOCATION
        else if filterLocation != nil && self.mapFilter.filterLocationName != CurrentUserLocation
        {
            let annotation = MKPointAnnotation()
            let centerCoordinate = CLLocationCoordinate2D(latitude: (filterLocation?.coordinate.latitude)!, longitude:(filterLocation?.coordinate.longitude)!)
            annotation.coordinate = centerCoordinate
            annotation.title = self.mapFilter.filterLocationName
            mapView.addAnnotation(annotation)
            print("addMapPins | Center @ CurFilterLoc | \(filterLocation)")
            self.centerMapOnLocation(location: filterLocation)
        }
           
    // POSTS ARE TOO FAR FROM USER - ZOOM TO SHOW CENTER OF ALL POSTS
        else if (closestPost?.distance ?? 0) >= (regionRadius * 100) {
            var locations = [] as [CLLocation]
            for post in tempSortPost {
                if let loc = post.locationGPS {
                    locations.append(loc)
                }
            }
            
            mapView.setRegion(SharedFunctions.mapCenterForCoordinates(listCoords: locations), animated: true)
            print("Nearest Post Too Far | Show Center For All Posts")
        }
        
    // SHOW CLOSEST POST
        else if let nearestLoc = closestPost?.locationGPS {
            self.centerMapOnLocation(location: nearestLoc)
        }
            
    // SHOW CURRENT USER LOCATION
        else {
            self.centerMapOnLocation(location: CurrentUser.currentLocation)
        }
        
        SVProgressHUD.dismiss()
    
    }
    
    
    

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        let annotation = view.annotation as! MapPin
        
        let postId = annotation.postId
        let post = fetchedPosts.filter { (post) -> Bool in
            post.id == postId
        }
        
        let pictureController = SinglePostView()
        pictureController.post = post.first
        
        navigationController?.pushViewController(pictureController, animated: true)
        
        //        if control == view.rightCalloutAccessoryView  || control == view.detailCalloutAccessoryView{
        //            let postId = annotation.postId
        //            let post = fetchedPosts.filter { (post) -> Bool in
        //                post.id == postId
        //            }
        //
        //            let pictureController = PictureController(collectionViewLayout: UICollectionViewFlowLayout())
        //            pictureController.selectedPost = post.first
        //
        //            navigationController?.pushViewController(pictureController, animated: true)
        //        }
        
    }
    
    @objc func zoomOut() {
        
        guard let location = CurrentUser.currentLocation else {
            return
        }
        
        let curLat = mapView.region.span.latitudeDelta
        let curLong = mapView.region.span.longitudeDelta
        let center = mapView.region.center
        
        let coordinateRegion = MKCoordinateRegion.init(center: center,latitudinalMeters: curLat * 3, longitudinalMeters: curLong * 3)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    
    func showFullMap() {
        // Reset to Full Map. Minimize Post Collection View
        
        
    }
    
    
//    @objc func showGlobe(){
//        guard let location = CurrentUser.currentLocation else {
//            return
//        }
//
//        print("centerMapOnLocation | \(location.coordinate)")
//        let coordinateRegion = MKCoordinateRegion.init(center: location.coordinate,
//                                                       latitudinalMeters: regionRadius*1000, longitudinalMeters: regionRadius*1000)
//        //        mapView?.region = coordinateRegion
//        mapView.setRegion(coordinateRegion, animated: true)
//
//        self.showFullMap()
//    }
    
    func centerMapOnLocation(location: CLLocation?, radius: CLLocationDistance? = 0, closestLocation: CLLocation? = nil) {
        guard let location = location else {
            print("centerMapOnLocation | NO LOCATION")
            return}
        print("centerMapOnLocation | Input | \(location.coordinate) | Radius \(radius) | Closest \(closestLocation?.coordinate)")
        
        var displayRadius: CLLocationDistance = radius == 0 ? regionRadius : radius!
        var coordinateRegion: MKCoordinateRegion?
        
        if let closestLocation = closestLocation {
            let closestDisplayRadius = location.distance(from: closestLocation)*2
            print("centerMapOnLocation | Distance Cur Location and Closest Post | \(displayRadius/2)")
            if closestDisplayRadius > 500000 {
                coordinateRegion = MKCoordinateRegion.init(center: (closestLocation.coordinate),latitudinalMeters: displayRadius, longitudinalMeters: displayRadius)
                //                mapView.setRegion(coordinateRegion!, animated: true)
                print("centerMapOnLocation | First Post Too Far, Default to first post location")
            } else {
                displayRadius = max(displayRadius, closestDisplayRadius)
                coordinateRegion = MKCoordinateRegion.init(center: (location.coordinate),latitudinalMeters: displayRadius, longitudinalMeters: displayRadius)
            }
        } else {
            coordinateRegion = MKCoordinateRegion.init(center: location.coordinate,latitudinalMeters: displayRadius, longitudinalMeters: displayRadius)
        }
        
        //        mapView?.region = coordinateRegion
        print("centerMapOnLocation | Result | \(location.coordinate) | Radius \(displayRadius)")
        mapView.setRegion(coordinateRegion!, animated: true)
        
    }
    

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView = MKMarkerAnnotationView()
        guard let annotation = annotation as? MKMarkerAnnotationView else {return nil}
        
        return annotation
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if let markerView = view as? MapPinMarkerView {
            markerView.markerTintColor = markerView.defaultPinColor
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        print("  ~ MAPVIEW SELECTED | \(view.annotation)")
        
        if let annotation = view.annotation as? MapPin {
            print("Map Pin Selected | \(annotation.postId)")
            annotation.title = annotation.locationName
            
            let tempPost = fetchedPosts.first { (post) -> Bool in
                post.id == annotation.postId
            }
            
            if tempPost != nil {
                self.selectedMapPost = tempPost
                self.showSelectedPost()
            }
            
        } else {
            print("ERROR Casting Annotation to MapPin | \(view.annotation)")
        }
        
        // ADDITIONAL TINT COLOR FOR SELECTED MAP PIN
        if let markerView = view as? MapPinMarkerView {
            
            markerView.markerTintColor = UIColor.ianLegitColor()
            markerView.detailCalloutAccessoryView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(passToSelectedPost)))
            markerView.rightCalloutAccessoryView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(passToSelectedPost)))
            markerView.leftCalloutAccessoryView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(passToSelectedPost)))
            markerView.markerTintColor = UIColor.ianLegitColor()
            //            markerView.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(passToSelectedPost)))
            //
            //            markerView.inputAccessoryView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(passToSelectedPost)))
            //            markerView.inputView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(passToSelectedPost)))
            //            markerView.plainView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(passToSelectedPost)))
        } else {
            print("mapView | didSelect | Can't find marker view | \(self.selectedMapPost?.id)")
        }
        
        
        
    }
    
    
    @objc func passToSelectedPost(){
        
        let pictureController = SinglePostView()
        pictureController.post = self.selectedMapPost
        
        navigationController?.pushViewController(pictureController, animated: true)
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
//        self.hideMinimizeCollectionView()
        //        print(mapView.getCurrentZoom())
        
    }

    
    




}


extension LegitMapViewController : UICollectionViewDelegate, UICollectionViewDataSource, LegitMapPostCollectionViewCellDelegate {
    
    func setupEmojiCollectionView(){
        emojiCollectionView.backgroundColor = UIColor.clear
        emojiCollectionView.register(HomeFilterBarCell.self, forCellWithReuseIdentifier: addTagId)
        emojiCollectionView.register(SelectedFilterBarCell.self, forCellWithReuseIdentifier: filterTagId)
        emojiCollectionView.register(RefreshFilterBarCell.self, forCellWithReuseIdentifier: refreshTagId)
        emojiCollectionView.delegate = self
        emojiCollectionView.dataSource = self
        emojiCollectionView.showsHorizontalScrollIndicator = false
        emojiCollectionView.isScrollEnabled = true
    }
    
    func setupPostCollectionView(){
        postCollectionView.backgroundColor = UIColor.white
        postCollectionView.layer.borderColor = UIColor.lightGray.cgColor
        
        postCollectionView.register(LegitMapPostCollectionViewCell.self, forCellWithReuseIdentifier: cellId)
        postCollectionView.register(GridPhotoCell.self, forCellWithReuseIdentifier: gridCellId)
//        postCollectionView.register(MainListViewViewHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: listHeaderId)


//        let layout = UICollectionViewFlowLayout()
//        layout.scrollDirection = .horizontal
//
////        layout.estimatedItemSize = CGSize(width: 350, height: 250)
//        layout.estimatedItemSize = CGSize(width: self.postCollectionView.frame.width, height: CGFloat(postFullHeight))
//
        postCollectionViewFlowLayout.scrollDirection = .horizontal
        postCollectionViewFlowLayout.estimatedItemSize = CGSize(width: self.postCollectionView.frame.width, height: CGFloat(postFullHeight))
        postCollectionViewFlowLayout.minimumInteritemSpacing = 1
        postCollectionViewFlowLayout.minimumLineSpacing = 0
        postCollectionView.collectionViewLayout = postCollectionViewFlowLayout
        postCollectionView.allowsSelection = true
        postCollectionView.allowsMultipleSelection = false
        postCollectionView.isPagingEnabled = true
        postCollectionView.showsHorizontalScrollIndicator = false
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        //        postCollectionView.refreshControl = refreshControl
        //        postCollectionView.alwaysBounceVertical = true
        postCollectionView.keyboardDismissMode = .onDrag
        
        //        postCollectionView.register(MainViewHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: listHeaderId)
        
        //        layout.minimumLineSpacing = 1
        //        layout.sectionInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        //        postCollectionView.collectionViewLayout = layout
        //        postCollectionView.collectionViewLayout = ListViewControllerHeaderFlowLayout()
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        //  SHOW DEFAULT EMOJIS IF NO EMOJIS FROM FEED - TO WORK AROUND BLANK INITIAL VIEW WHEN LOADING
        if collectionView == emojiCollectionView
        {
            if self.mapFilter.isFiltering {
                print("SearchTerms \(searchTerms.count) | \(searchTerms)")
                return searchTerms.count + 1
                
            } else {
            //  SHOW DEFAULT EMOJIS IF NO EMOJIS FROM FEED - TO WORK AROUND BLANK INITIAL VIEW WHEN LOADING
                return (displayedEmojis.count == 0 ? listDefaultEmojis.count : displayedEmojis.count)
            }
            
            
            //return displayedEmojis.count == 0 ? listDefaultEmojis.count : displayedEmojis.count
        }
        else if collectionView == postCollectionView
        {
            return fetchedPosts.count
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
    // EMOJI COLLECTIONVIEW
        if collectionView == emojiCollectionView
        {
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: addTagId, for: indexPath) as! HomeFilterBarCell
//
//            let option = (displayedEmojis.count == 0) ? listDefaultEmojis[indexPath.item].lowercased() : displayedEmojis[indexPath.item].lowercased()
//
//            var isSelected: Bool = (self.mapFilter != nil) ? (mapFilter.filterCaption?.contains(option) ?? false) : false
//            cell.uploadLocations.text = option
//            cell.backgroundColor = isSelected ? UIColor.ianOrangeColor() : UIColor.clear
//            return cell
            
            if self.mapFilter.isFiltering {
                if indexPath.item == 0 {
                let refreshCell = collectionView.dequeueReusableCell(withReuseIdentifier: refreshTagId, for: indexPath) as! RefreshFilterBarCell
                    refreshCell.delegate = self
    //                var displayText = "Search Terms"
                    var displayText = "\(fetchedPosts.count) \nPosts"

                    refreshCell.uploadLocations.text = displayText
                    refreshCell.uploadLocations.font =  UIFont.boldSystemFont(ofSize: 10)
                    refreshCell.uploadLocations.textColor = UIColor.ianBlackColor()
                    refreshCell.uploadLocations.sizeToFit()
                    refreshCell.backgroundColor = UIColor.clear
                    refreshCell.layoutIfNeeded()

                    return refreshCell

                } else {
                        let filterCell = collectionView.dequeueReusableCell(withReuseIdentifier: filterTagId, for: indexPath) as! SelectedFilterBarCell
            //            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: addTagId, for: indexPath) as! HomeFilterBarCell
                        var displayTerm = searchTerms[indexPath.item - 1].capitalizingFirstLetter()
                        var isEmoji = displayTerm.containsOnlyEmoji
                    
                        filterCell.searchTerm = displayTerm

                        if let text = EmojiDictionary[displayTerm] {
                            displayTerm += " \(text.capitalizingFirstLetter())"
                        }
                    

                        filterCell.uploadLocations.text = displayTerm
                        filterCell.uploadLocations.sizeToFit()
                        print("Filter Cell | \(filterCell.uploadLocations.text) | \(indexPath.item - 1)")

                    
                    filterCell.uploadLocations.font =  isEmoji ? UIFont(name: "Poppins-Bold", size: 12) : UIFont(name: "Poppins-Regular", size: 12)
                        filterCell.uploadLocations.textColor = UIColor.ianBlackColor()
                    filterCell.layer.borderColor = filterCell.uploadLocations.textColor.cgColor

                        filterCell.uploadLocations.sizeToFit()
                        filterCell.delegate = self
            //            filterCell.backgroundColor = UIColor.mainBlue()
                        filterCell.isUserInteractionEnabled = true
                        filterCell.layoutIfNeeded()
                        return filterCell

                }
            }

        // NO FILTER SELECTED
            else {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: addTagId, for: indexPath) as! HomeFilterBarCell

                    let option = (displayedEmojis.count == 0) ? listDefaultEmojis[indexPath.item].lowercased() : displayedEmojis[indexPath.item].lowercased()
                    var isSelected = self.mapFilter.filterCaption?.contains(option) ?? false
                    cell.uploadLocations.text = option
                    cell.uploadLocations.font =  UIFont(name: "Poppins-Bold", size: 20)
                    cell.uploadLocations.textColor = UIColor.ianBlackColor()

                    cell.uploadLocations.sizeToFit()
                    cell.backgroundColor = isSelected ? UIColor.ianOrangeColor() : UIColor.clear
                    return cell
            }

        }
        else if collectionView == postCollectionView
        {
            var displayPost = fetchedPosts[indexPath.item]

            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! LegitMapPostCollectionViewCell
//            cell.bookmarkDate = displayPost.creationDate
            cell.post = displayPost
            // Can't Be Selected
            
//            cell.isSelected = (displayPost.id == self.selectedMapPost?.id)
            
            cell.backgroundColor = UIColor.white.withAlphaComponent(0.8)

            if self.mapFilter.filterLocation != nil && cell.post?.locationGPS != nil {
                cell.post?.distance = Double((cell.post?.locationGPS?.distance(from: (self.mapFilter.filterLocation!)))!)
            }
            
            cell.showMinimzeButton = self.isPostFullView
            cell.delegate = self
            // Disable Selection to enable any tap to select cell
//            cell.allowSelect = false
            
            // Only show cell cancel button when showing post view
//            cell.showCancelButton = self.isPostFullView
            cell.currentImage = 1
            cell.cellWidth = self.postCollectionView.frame.width
            
//            cell.layer.borderColor = UIColor.mainBlue().cgColor
//            cell.layer.borderWidth = 1
            
//            print("POST CV WIDTH | ",self.postCollectionView.frame.width)
            return cell
        }
        else
        {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! NewListPhotoCell
            return cell
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //        let emoji = displayedEmojis[indexPath.item].lowercased()
        if collectionView == emojiCollectionView
        {
//            let emoji = (displayedEmojis.count == 0) ? listDefaultEmojis[indexPath.item].lowercased() : displayedEmojis[indexPath.item].lowercased()
//            self.filterCaptionPost(searchText: emoji)
            
            if !self.mapFilter.isFiltering {
                let emoji = (displayedEmojis.count == 0) ? listDefaultEmojis[indexPath.row].lowercased() : displayedEmojis[indexPath.row].lowercased()
                print("\(emoji) SELECTED | CV didSelect")
                self.didTapAddTag(addTag: emoji)
            }
            
            else if self.mapFilter.isFiltering && indexPath.row == 0 {
                print("Open search From Emoji CV")
                self.refreshAll()
//                self.didTapSearchButton()
            }
            
            else if self.mapFilter.isFiltering {
                let emoji = searchTerms[indexPath.item - 1]
                print("\(emoji) REMOVE TAG | CV didSelect")
                self.didRemoveTag(tag: emoji)
            }
            
            
        }
        else if collectionView == postCollectionView
        {
            var displayPost = fetchedPosts[indexPath.item]
            self.didTapPicture(post: displayPost)
            self.isPostFullView = !self.isPostFullView
            print("TAP POST")
        }

        
//        self.delegate?.didTapAddTag(addTag: emoji)
    }

    
    func filterCaptionPost(searchText: String) {
        print("filterCaptionPost | ", searchText)
        let tempAddTag = searchText.lowercased()
        
        guard let filterCaption = self.mapFilter.filterCaption?.lowercased() else {
            self.mapFilter.filterCaption = tempAddTag
            self.refreshPostsForFilter()
            return
        }
        
        if filterCaption.contains(tempAddTag) {
            self.mapFilter.filterCaption = filterCaption.replacingOccurrences(of: tempAddTag, with: "")
        } else {
            if self.mapFilter.filterCaption == nil {
                self.mapFilter.filterCaption = tempAddTag
            } else {
                self.mapFilter.filterCaption = filterCaption + tempAddTag
            }
        }
        
        self.refreshPostsForFilter()
    }
 
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == postCollectionView
        {
            let currentIndex = Int(self.postCollectionView.contentOffset.x / self.postCollectionView.frame.size.width)
            print("scrollViewDidEndDecelerating | Show Selected Post on Map | \(currentIndex)")
            self.selectedMapPost = self.fetchedPosts[currentIndex]
            self.showSelectedPostOnMap()
        }
    }
    
    
    
}

// MARK: - SEARCH BAR


extension LegitMapViewController : UISearchBarDelegate {
    
    func setupSearchBar() {
//        fullSearchBar.searchBarStyle = .prominent
        fullSearchBar.searchBarStyle = .minimal

        fullSearchBar.isTranslucent = false
        fullSearchBar.tintColor = UIColor.ianBlackColor()
        fullSearchBar.placeholder = "Search food, locations, categories"
        fullSearchBar.delegate = self
        fullSearchBar.showsCancelButton = false
        fullSearchBar.sizeToFit()
        fullSearchBar.clipsToBounds = true
        fullSearchBar.backgroundImage = UIImage()
        fullSearchBar.backgroundColor = UIColor.white
        
        // CANCEL BUTTON
        let attributes = [
            NSAttributedString.Key.foregroundColor : UIColor.ianLegitColor(),
            NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 13)
        ]
//        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(attributes, for: .normal)
        
        
        let searchImage = #imageLiteral(resourceName: "search_selected").withRenderingMode(.alwaysTemplate)
        fullSearchBar.setImage(UIImage(), for: .search, state: .normal)
        
        //        let cancelImage = #imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysTemplate)
        //        fullSearchBar.setImage(cancelImage, for: .clear, state: .normal)
        
        fullSearchBar.layer.borderWidth = 0
        fullSearchBar.layer.borderColor = UIColor.ianBlackColor().cgColor
        
        let textFieldInsideSearchBar = fullSearchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = UIColor.ianBlackColor()
        textFieldInsideSearchBar?.font = UIFont.systemFont(ofSize: 14)
        textFieldInsideSearchBar?.layer.backgroundColor = UIColor.white.cgColor
        // REMOVE SEARCH BAR ICON
        //        let searchTextField:UITextField = fullSearchBar.subviews[0].subviews.last as! UITextField
        //        searchTextField.leftView = nil
        
        
        for s in fullSearchBar.subviews[0].subviews {
            if s is UITextField {
                s.backgroundColor = UIColor.clear
                s.layer.backgroundColor = UIColor.clear.cgColor
                s.backgroundColor = UIColor.white
                s.layer.backgroundColor = UIColor.white.cgColor

                if let backgroundview = s.subviews.first {
                    
                    // Background color
                    //                    backgroundview.backgroundColor = UIColor.white
                    backgroundview.clipsToBounds = true
                    backgroundview.layer.backgroundColor = UIColor.clear.cgColor
                    backgroundview.layer.backgroundColor = UIColor.white.cgColor

                    // Rounded corner
                    //                    backgroundview.layer.cornerRadius = 30/2
                    //                    backgroundview.layer.masksToBounds = true
                    //                    backgroundview.clipsToBounds = true
                }

            }
        }
        
    }
    
    func showFullSearchBar(){
        
        UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.transitionCrossDissolve, animations:
            {
                self.fullSearchBarView.alpha = 1
        }
            , completion: { (finished: Bool) in
        })
        
//        self.fullSearchBar.becomeFirstResponder()
        self.fullSearchBar.becomeFirstResponder()
        self.showSearchTableView()
    }
    
    func hideFullSearchBar() {
        
        UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.transitionCrossDissolve, animations:
            {
                if self.mapFilter.isFiltering {
                    self.fullSearchBarView.alpha = 1
                } else {
                    self.fullSearchBarView.alpha = 0
                }
        }
            , completion: { (finished: Bool) in
        })
        self.fullSearchBar.resignFirstResponder()
        self.hideSearchTableView()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.hideFullSearchBar()
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        self.delegate?.filterContentForSearchText(searchText)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.showFullSearchBar()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text?.lowercased() else {
            self.refreshAll()
            print("Search Bar Empty | Refresh")
            return
        }
        
        self.filterCaptionPost(searchText: text)
    }
    
    
    func showSearchTableView() {
        
    }
    
    func hideSearchTableView() {
        
    }
    
    func refreshSearchBar() {
        /*
        if mapFilter.isFiltering
        {
            if let captionSearch = mapFilter.filterCaption {
                var displaySearch = captionSearch
                if displaySearch.isSingleEmoji {
                    // ADD EMOJI TRANSLATION
                    if let emojiTranslate = EmojiDictionary[displaySearch] {
                        displaySearch += " \(emojiTranslate.capitalizingFirstLetter())"
                    }
                }
                
                fullSearchBar.text = displaySearch
            } else if mapFilter.filterLocationName != nil {
                fullSearchBar.text = mapFilter.filterLocationName
            } else if let googleID = mapFilter.filterGoogleLocationID {
                if let locationName = locationGoogleIdDictionary.key(forValue: googleID) {
                    fullSearchBar.text = locationName
                } else {
                    fullSearchBar.text = googleID
                }
                
            } else if mapFilter.filterLocationSummaryID != nil {
                fullSearchBar.text = mapFilter.filterLocationSummaryID
            } else {
                fullSearchBar.text = ""
            }
            self.showFullSearchBar()
        }
        else
        {
            self.hideFullSearchBar()
        }*/
    }
    
    

    
    
}


// MARK: - COLLECTIONVIEW CELL DELEGATES


extension LegitMapViewController : NewListPhotoCellDelegate, MessageControllerDelegate, SharePhotoListControllerDelegate, ListViewControllerDelegate, LegitSearchViewControllerDelegate, RefreshFilterBarCellDelegate, SelectedFilterBarCellDelegate {
    func didTapCell(tag: String) {
    }
    
    func didRemoveLocationFilter(location: String) {
        print("LegitMapViewController | didRemoveLocationFilter \(location)")

    }
    
    func didRemoveRatingFilter(rating: String) {
        print("LegitMapViewController | didRemoveRatingFilter \(rating)")

    }
    
    
    
    func didTapAddTag(addTag: String) {
        // ONLY EMOJIS BECAUSE CAN ONLY ADD EMOJI TAGS FROM HEADER
        let tempAddTag = addTag.lowercased()
        var tempArray = self.mapFilter.filterCaptionArray
        
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
        
        self.mapFilter.filterCaptionArray = tempArray
        self.refreshPostsForFilter()
        
        }
    
    func didRemoveTag(tag: String) {
        if tag == self.mapFilter.filterLocationSummaryID {
            self.mapFilter.filterLocationSummaryID = nil
            print("Remove Search | \(tag) | City | \(self.mapFilter.filterLocationSummaryID)")
        } else if tag == self.mapFilter.filterLocationName {
            self.mapFilter.filterLocationName = nil
            self.mapFilter.filterGoogleLocationID = nil
            print("Remove Search | \(tag) | Location | \(self.mapFilter.filterLocationName)")

        } else if self.mapFilter.filterCaptionArray.count > 0 {
            
            var tempArray = self.mapFilter.filterCaptionArray.map {$0.lowercased()}
            let tagText = tag.lowercased()
            if tempArray.contains(tagText) {
                let oldCount = tempArray.count
                tempArray.removeAll { (text) -> Bool in
                    text == tagText
                }
                print("didRemoveTag | Remove \(tagText) from Search | \(tempArray)")
            }
            self.mapFilter.filterCaptionArray = tempArray
        }

        self.refreshPostsForFilter()
    }
    
    
    func filterControllerSelected(filter: Filter?) {
        print("LegitMapView | Received Filter | \(filter)")
        guard let filter = filter else {return}
        self.mapFilter = filter
        self.refreshPostsForFilter()
    }
    
    func listSelected(list: List?) {
        print("Selected | \(list?.name)")
        self.mapFilter.filterList = list
        self.mapFilter.filterCaption = nil
        self.showFullMap()
        self.refreshPostsForFilter()
    }
    
    func deleteList(list: List?) {
        print("MainViewController | DELETE")

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
    
    func didTapMessage(post: Post) {
        let messageController = MessageController()
        messageController.post = post
        messageController.delegate = self
        navigationController?.pushViewController(messageController, animated: true)
    }
    
    func refreshPost(post: Post) {
        let index = fetchedPosts.firstIndex { (filteredpost) -> Bool in
            filteredpost.id  == post.id
        }
        print("Refreshing Post @ \(index) for post \(post.id)")
        let filteredindexpath = IndexPath(row:index!, section: 0)
        
        self.fetchedPosts[index!] = post
        self.postCollectionView.reloadItems(at: [filteredindexpath])
        
        // Update Cache
        postCache.removeValue(forKey: post.id!)
        postCache[post.id!] = post
    }
    
    func didTapBookmark(post: Post) {
        let sharePhotoListController = SharePhotoListController()
        sharePhotoListController.uploadPost = post
        sharePhotoListController.isBookmarkingPost = true
        sharePhotoListController.delegate = self
        navigationController?.pushViewController(sharePhotoListController, animated: true)
    }
    
    func deletePostFromList(post: Post) {
        
    }
    
    func didTapPicture(post: Post) {
        self.extTapPicture(post: post)
//        let pictureController = SinglePostView()
//        pictureController.post = post
//        navigationController?.pushViewController(pictureController, animated: true)
    }
    
    
    func didTapExtraTag(tagName: String, tagId: String, post: Post) {
        // Tap tagged list
        // Check Current User List
        if let listIndex = CurrentUser.lists.firstIndex(where: { (currentList) -> Bool in
            currentList.id == tagId
        }) {
            let listViewController = ListViewController()
            listViewController.delegate = self
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
                    listViewController.delegate = self
                    self.navigationController?.pushViewController(listViewController, animated: true)
                }
            })
        }
    }
    
    func didTapListCancel(post: Post) {
        
    }
    
    
    func showEmojiDetail(emoji: String?) {
        guard let emoji = emoji else {
            print("showEmojiDetail | No Emoji")
            return
        }
        
        var emojiDetail = ""

        if let _ = EmojiDictionary[emoji] {
            emojiDetail = EmojiDictionary[emoji]!
        } else {
            print("No Dictionary Value | \(emojiDetail) | \(emoji)")
            emojiDetail = ""
        }
        
        
        var captionDelay = 3
        emojiDetailLabel.text = "\(emoji)  \(emojiDetail)"
        emojiDetailLabel.alpha = 1
        emojiDetailLabel.adjustsFontSizeToFitWidth = true
        //        emojiDetailLabel.sizeToFit()
        
        UIView.animate(withDuration: 0.5, delay: TimeInterval(captionDelay), options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.hideEmojiDetailLabel()
        }, completion: { (finished: Bool) in
        })
    
    }
    
    func hideEmojiDetailLabel(){
        self.emojiDetailLabel.alpha = 0
    }

    func togglePost() {
        self.isPostFullView = !self.isPostFullView
        print("TOGGLE POST")
    }

}
