////
//  ListView.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/7/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

import CoreLocation
import EmptyDataSet_Swift
import DropDown
import SVProgressHUD
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth
import Kingfisher

class TestHomeController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, ListPhotoCellDelegate, EmptyDataSetSource, EmptyDataSetDelegate, ExplorePhotoCellDelegate, NewListPhotoCellDelegate, SearchFilterControllerDelegate, MainSearchControllerDelegate, FullPictureCellDelegate, TestGridPhotoCellDelegate, SharePhotoListControllerDelegate, NewHeaderDelegate, HomeDropDownViewDelegate, HomeSearchBarHeaderDelegate, SinglePostViewDelegate, HomeFilterBarHeaderDelegate, SearchBarTableViewControllerDelegate {

    func didTapLike(post: Post) {
        
    }

    
    lazy var postCollectionView : UICollectionView = {
        
        let layout: UICollectionViewFlowLayout = ListViewControllerHeaderFlowLayout()
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = UIColor.rgb(red: 249, green: 249, blue: 249)
        cv.isScrollEnabled = false
        
        return cv
    }()
    
    var headerSortSegment = UISegmentedControl()
    var searchBarSortSegment = UISegmentedControl()

    let buttonBar = UIView()
    

    @objc func didTapInfo() {
        showEmojiInfo()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
//        SVProgressHUD.show(withStatus: "Fetching Posts")
        postCollectionView.collectionViewLayout.invalidateLayout()
        postCollectionView.layoutIfNeeded()
        // REMOVE KEYBOARD HACK
        self.view.endEditing(true)
        
        self.setupNavigationItems()
        
        if newUser {
            print("*** NEW USER *** SHOW ONBOARDING")
            showOnboarding()
            newUser = false
        }
//        print(self.navigationController?.navigationBar.frame.height)

    }
    
    lazy var showOnboardingButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "notification"), for: .normal)
        button.addTarget(self, action: #selector(showEmojiInfo), for: .touchUpInside)
        button.tintColor = UIColor.ianLegitColor()
        return button
    }()
    
    func showOnboarding(){
        let welcomeView = NewUserOnboardingView()
        let testNav = UINavigationController(rootViewController: welcomeView)
        self.present(testNav, animated: true, completion: nil)
//        self.navigationController?.pushViewController(listView, animated: true)

    }
    
    
    
    func showEmojiInfo(){
        let welcomeView = EmojiInfoView()
//        self.navigationController?.pushViewController(welcomeView, animated: true)

        let testNav = UINavigationController(rootViewController: welcomeView)
        self.present(testNav, animated: true, completion: nil)
        //        self.navigationController?.pushViewController(listView, animated: true)
        
    }
    //INPUT
    var fetchedPostIds: [PostId] = []
    var displayedPosts: [Post] = []
    
    
    // Navigation Bar
    var defaultSearchBar = UISearchBar()
    
    var isPostView: Bool = true {
        didSet{
            formatButton.setImage(self.isPostView ? #imageLiteral(resourceName: "grid") :#imageLiteral(resourceName: "postview"), for: .normal)
        }
    }
    
    lazy var formatButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(self.isPostView ? #imageLiteral(resourceName: "postview") :#imageLiteral(resourceName: "grid"), for: .normal)
        button.addTarget(self, action: #selector(toggleFormatView), for: .touchUpInside)
        button.tintColor = UIColor.ianLegitColor()
        return button
    }()
    
    func toggleFormatView(){
        self.isPostView = !self.isPostView
        postCollectionView.reloadData()
    }
    
    let listCellId = "bookmarkCellId"
    let exploreCellId = "exploreCellId"
    let listHeaderId = "listHeaderId"
    
    // Pagination Variables
    var paginatePostsCount: Int = 0
    var isFinishedPaging = false {
        didSet{
            if isFinishedPaging == true {
                //                print("Finished Paging :", self.paginatePostsCount)
            }
        }
    }
    
    // Filtering Variables
    
    lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "search_tab_fill").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(showSearchBar), for: .touchUpInside)
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.ianOrangeColor().cgColor
        button.backgroundColor = UIColor.white
        button.clipsToBounds = true
        return button
    }()
    
    var viewFilter: Filter = Filter.init(defaultSort: defaultRecentSort) {
        didSet{
            setupNavigationItems()
        }
    }
    
    func showFilterView(){
        
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
    
    let signOutButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "signout").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.ianLegitColor()
        button.setTitle("Logout", for: .normal)
        let headerTitle = NSAttributedString(string: "Logout", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Regular", size: 14)])

        button.setAttributedTitle(headerTitle, for: .normal)

        button.addTarget(self, action: #selector(handleGuestLogOut), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.borderColor = UIColor.gray.cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 30/2
        button.titleLabel?.textColor = UIColor.ianLegitColor()
        //        button.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        //        button.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        //        button.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        return button
    }()
    
    let notificationButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "alert").withRenderingMode(.alwaysTemplate), for: .normal)
        //        button.layer.cornerRadius = button.frame.width/2
        button.tintColor = UIColor.ianBlackColor()
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
    
    @objc func openNotifications(){
        let note = UserEventViewController()
        self.navigationController?.pushViewController(note, animated: true)
    }
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .white
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    
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
        label.numberOfLines = 0
        //        label.backgroundColor = UIColor.rgb(red: 255, green: 242, blue: 230)
        label.textColor = UIColor.legitColor()
        //        label.layer.borderColor = UIColor.black.cgColor
        //        label.layer.masksToBounds = true
        return label
    }()

    
    lazy var cancelFilterButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        button.setImage(#imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysOriginal), for: .normal)
        button.backgroundColor = UIColor.white
        button.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        return button
    }()
    
    func didTapCancel(){
        self.refreshAll()
    }
    
    
    // Header Sort Variables
    // Default Sort is Most Recent Listed Date, But Set to Default Rank
    //    var selectedHeaderSort:String = defaultRecentSort
    
    static let finishFetchingPostIdsNotificationName = NSNotification.Name(rawValue: "HomeFinishFetchingPostIds")
    static let searchRefreshNotificationName = NSNotification.Name(rawValue: "HomeSearchRefresh")
    static let refreshListViewNotificationName = NSNotification.Name(rawValue: "HomeRefreshListView")
    
    
    let navFriendButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
//        button.setImage(#imageLiteral(resourceName: "friendship"), for: .normal)
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
        postSocialController.displayFollowing = true
        postSocialController.displayUser = true
        postSocialController.inputUser = CurrentUser.user
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    @objc func openUserProfile(){
        print("Open User Profile| ",CurrentUser.user?.uid)
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = CurrentUser.user?.uid
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    var fetchTypeInd: String = HomeFetchDefault {
        didSet{
            self.handleRefresh()
        }
    }
    
    var buttonBarPosition: NSLayoutConstraint?
    var buttonBarWidth: NSLayoutConstraint?

    let searchBarView = SearchBarTableViewController()
    var showCancelButtonWidth: NSLayoutConstraint?

    
    override func viewDidLoad() {
        super.viewDidLoad()
//        view.backgroundColor = UIColor.rgb(red: 249, green: 249, blue: 249)
        view.backgroundColor = UIColor.white

        self.navigationController?.navigationBar.tintColor = UIColor.white
        let topNavContainer = UIView()
        view.addSubview(topNavContainer)
        topNavContainer.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//
//        view.addSubview(navSortLabel)
//        navSortLabel.anchor(top: topNavContainer.topAnchor, left: topNavContainer.leftAnchor, bottom: topNavContainer.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
//        navSortLabel.isUserInteractionEnabled = true
//        navSortLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleSort)))
//        navSortLabel.text = self.viewFilter.filterSort
//        navSortLabel.sizeToFit()
        
        let searchBarContainer = UIView()
        view.addSubview(searchBarContainer)
        searchBarContainer.anchor(top: topNavContainer.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        searchbarContainerHeight = searchBarContainer.heightAnchor.constraint(equalToConstant: searchbarContainerHeightInput)
        searchbarContainerHeight?.isActive = true
        
//        let mapButtonTest = TemplateObjects.NavBarMapButton()
//        view.addSubview(mapButtonTest)
//        mapButtonTest.anchor(top: searchBarContainer.topAnchor, left: nil, bottom: searchBarContainer.bottomAnchor, right: searchBarContainer.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 10, width: 0, height: 0)

//        view.addSubview(showOnboardingButton)
//        showOnboardingButton.anchor(top: searchBarContainer.topAnchor, left: nil, bottom: searchBarContainer.bottomAnchor, right: searchBarContainer.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 10, width: 0, height: 0)
        
        view.addSubview(filterButton)
        filterButton.anchor(top: searchBarContainer.topAnchor, left: nil, bottom: searchBarContainer.bottomAnchor, right: searchBarContainer.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 10, width: 0, height: 0)
        
        view.addSubview(cancelFilterButton)
        cancelFilterButton.anchor(top: searchBarContainer.topAnchor, left: searchBarContainer.leftAnchor, bottom: searchBarContainer.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 0, height: 0)
        showCancelButtonWidth = cancelFilterButton.widthAnchor.constraint(equalToConstant: 0)
        showCancelButtonWidth?.isActive = true
        
        setupAddTagCollectionView()
        view.addSubview(addTagCollectionView)
        addTagCollectionView.anchor(top: searchBarContainer.topAnchor, left: cancelFilterButton.rightAnchor, bottom: searchBarContainer.bottomAnchor, right: filterButton.leftAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)

        self.setupSegments()
        view.addSubview(headerSortSegment)
        headerSortSegment.anchor(top: searchBarContainer.bottomAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
        view.addSubview(formatButton)
        formatButton.anchor(top: nil, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 30, height: 30)
        formatButton.centerYAnchor.constraint(equalTo: headerSortSegment.centerYAnchor).isActive = true
        headerSortSegment.rightAnchor.constraint(equalTo: formatButton.leftAnchor, constant: 5).isActive = true

        

        self.setupSearchSegment()
        view.addSubview(searchBarSortSegment)
        searchBarSortSegment.anchor(top: searchBarContainer.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        searchBarSortSegment.isHidden = true
        
        let segmentWidth = (self.view.frame.width - 30) / 3
//        let segmentWidth = (self.view.frame.width - 10) / sortOptions.count
//                let segmentWidth = headerSortSegment.frame.width / CGFloat(headerSortSegment.numberOfSegments)
        
        //        print("TotalWidth | \(headerSortSegment.frame.width) | \(headerSortSegment.widthAnchor) | Segment Width | \(segmentWidth) | View Width | \(self.frame.width)")
        
//        let shadowView = UIView()
//        shadowView.backgroundColor = UIColor.rgb(red: 0, green: 0, blue: 0).withAlphaComponent(0.05)
//        view.addSubview(shadowView)
//        shadowView.anchor(top: headerSortSegment.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 7)

        buttonBar.backgroundColor = UIColor.ianLegitColor()
        view.addSubview(buttonBar)
        buttonBar.anchor(top: nil, left: nil, bottom: headerSortSegment.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: segmentWidth, height: 3)
        buttonBar.leftAnchor.constraint(lessThanOrEqualTo: headerSortSegment.leftAnchor).isActive = true
        buttonBar.rightAnchor.constraint(lessThanOrEqualTo: headerSortSegment.rightAnchor).isActive = true
        buttonBarPosition = buttonBar.leftAnchor.constraint(equalTo: headerSortSegment.leftAnchor, constant: 5)
        buttonBarPosition?.isActive = true
        buttonBarWidth = buttonBar.widthAnchor.constraint(equalToConstant: segmentWidth)
        buttonBarWidth?.isActive = true
        self.underlineSegment(segment: sortOptions.firstIndex(of: self.viewFilter.filterSort!)!)

        view.addSubview(postCollectionView)
        postCollectionView.anchor(top: headerSortSegment.bottomAnchor, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        setupNavigationItems()
        setupCollectionView()
        
        
        view.addSubview(searchBarView.view)
        searchBarView.delegate = self
        searchBarView.view.anchor(top: headerSortSegment.bottomAnchor, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        searchBarView.view.isHidden = true
        
        //setupFilterDetailView()

        
        //        1. Fetches Post Ids Based on Social/Location
        //        2. Fetches All Post for Post Ids
        //        3. Filter Sorts Post based on Criteria
        //        4. Paginates and Refreshes
        
        fetchPostIds()
        
        NotificationCenter.default.addObserver(self, selector: #selector(fetchSortFilterPosts), name: TestHomeController.finishFetchingPostIdsNotificationName, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: SharePhotoListController.updateFeedNotificationName, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: TestHomeController.searchRefreshNotificationName, object: nil)
        
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        
    }
    
    func showSearchBar(){
        
        // Option Counts for Current Filter
//        Database.countEmojis(posts: self.displayedPosts) { (emojiCounts) in
//            searchBarView.defaultEmojiCounts = self.noCaptionFilterEmojiCounts
//        }
//        Database.countLocationIds(posts: self.displayedPosts) { (locationCounts) in
//            searchBarView.defaultLocationCounts = locationCounts
//        }
        
        searchBarView.fetchAllUsers()
        searchBarView.searchFilter = self.viewFilter
        self.showCancelButtonWidth?.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.navigationController?.isNavigationBarHidden = true
            
            self.searchbarContainerHeight?.constant = 0
            self.searchBarSortSegment.isHidden = false
            self.searchBarView.view.isHidden = false
            self.underlineSegment(segment: self.searchBarSortSegment.selectedSegmentIndex)

        }
    }
    
    func hideSearchBar(){
        
        setupNavigationItems()
        
        UIView.animate(withDuration: 0.3) {
            self.navigationController?.isNavigationBarHidden = false
            self.searchbarContainerHeight?.constant = self.searchbarContainerHeightInput
            self.searchBarSortSegment.isHidden = true
            self.searchBarView.view.isHidden = true
            self.underlineSegment(segment: self.headerSortSegment.selectedSegmentIndex)
        }
        
    }
    
    func setupSearchSegment(){
        searchBarSortSegment = UISegmentedControl(items: SearchBarOptions)
        searchBarSortSegment.selectedSegmentIndex = 0
        searchBarSortSegment.addTarget(self, action: #selector(selectSearchBarSort(sender:)), for: .valueChanged)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        searchBarSortSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
        searchBarSortSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)
        
        searchBarSortSegment.backgroundColor = .white
        searchBarSortSegment.tintColor = .white
        searchBarSortSegment.layer.applySketchShadow()
    }
    

    
    
    func keyboardWillHide(_ notification: NSNotification) {
//        self.hideSearchBar()
        
    }
    
    func setupSegments(){
        headerSortSegment = UISegmentedControl(items: sortOptions)
        print(sortOptions.firstIndex(of: self.viewFilter.filterSort!)!)
        headerSortSegment.selectedSegmentIndex = sortOptions.firstIndex(of: self.viewFilter.filterSort!)!
        headerSortSegment.addTarget(self, action: #selector(selectSort), for: .valueChanged)
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        headerSortSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
        headerSortSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)
        
        headerSortSegment.backgroundColor = .white
        headerSortSegment.tintColor = .white
        headerSortSegment.layer.applySketchShadow()
        // This needs to be false since we are using auto layout constraints
        //        headerSortSegment.translatesAutoresizingMaskIntoConstraints = false
        //        buttonBar.translatesAutoresizingMaskIntoConstraints = false
        //        headerSortSegment.apportionsSegmentWidthsByContent = true
    }
    
    var sortOptions: [String] = HeaderSortOptions
    var searchBarSortOptions: [String] = SearchBarOptions

    lazy var navSortLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Test"
        ul.isUserInteractionEnabled = true
        ul.font = UIFont(name: "Poppins-Bold", size: 15)
        ul.textColor = UIColor.ianLegitColor()
        ul.numberOfLines = 0
        ul.textAlignment = NSTextAlignment.left
        ul.backgroundColor = UIColor.clear
        ul.layer.masksToBounds = true
        return ul
    }()
    
    @objc func toggleSort(){
        var curSortIndex = sortOptions.firstIndex(of: self.viewFilter.filterSort!)!
        if curSortIndex >= sortOptions.count - 1
        {
            curSortIndex = 0
        }
        else
        {
            curSortIndex += 1
        }
        
        self.headerSortSelected(sort: sortOptions[curSortIndex])
    }
    

    @objc func selectSort(sender: UISegmentedControl) {
        self.headerSortSelected(sort: sortOptions[sender.selectedSegmentIndex])
        self.underlineSegment(segment: sender.selectedSegmentIndex)
    }
    
    @objc func selectSearchBarSort(sender: UISegmentedControl) {
        self.searchBarView.searchCategory = sender.selectedSegmentIndex
        print("Search Bar Sort Selected | \(searchBarSortOptions[sender.selectedSegmentIndex])")
        self.underlineSegment(segment: sender.selectedSegmentIndex)
    }
    
    func underlineSegment(segment: Int? = 0){
        
        let segmentCount = self.searchBarSortSegment.isHidden ? self.headerSortSegment.numberOfSegments : self.searchBarSortSegment.numberOfSegments
        if segmentCount == 0 {
            return
        }
        let segmentWidth = ((self.view.frame.width) - (self.searchBarSortSegment.isHidden ? 40 : 0)) / CGFloat(segmentCount)
        buttonBarWidth?.constant = segmentWidth
//        let tempX = self.buttonBar.frame.origin.x
        UIView.animate(withDuration: 0.3) {
//            self.buttonBarPosition?.isActive = false
            self.buttonBar.frame.origin.x = segmentWidth * CGFloat(segment ?? 0) + 5
            self.buttonBarPosition?.constant = segmentWidth * CGFloat(segment ?? 0) + 5
            self.buttonBarPosition?.isActive = true
        }
        print(" underlineSegment | \(segment) | HomeViewController")
    }
    
    
    func setupFilterDetailView(){
        view.addSubview(filterDetailView)
        filterDetailView.anchor(top: nil, left: nil, bottom: bottomLayoutGuide.topAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 3, paddingRight: 0, width: 0, height: 0)
        filterDetailView.widthAnchor.constraint(lessThanOrEqualToConstant: self.view.frame.width - 20).isActive = true
        filterDetailView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        filterDetailView.addSubview(cancelFilterButton)
        cancelFilterButton.anchor(top: nil, left: nil, bottom: nil, right: filterDetailView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        cancelFilterButton.centerYAnchor.constraint(equalTo: filterDetailView.centerYAnchor).isActive = true
        
        filterDetailView.addSubview(filteringDetailLabel)
        filteringDetailLabel.anchor(top: filterDetailView.topAnchor, left: filterDetailView.leftAnchor, bottom: filterDetailView.bottomAnchor, right: cancelFilterButton.leftAnchor, paddingTop: 3, paddingLeft: 5, paddingBottom: 3, paddingRight: 0, width: 0, height: 0)
        
        filterDetailView.isHidden = true
    }
    
    func updateNavHeader(){
        var attributedHeaderTitle = NSMutableAttributedString()
        let customFont = UIFont(name: "Poppins-Bold", size: 18)
        let headerTitle = NSAttributedString(string: self.fetchTypeInd + " ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: customFont])
        
        attributedHeaderTitle.append(headerTitle)
        
        guard let legitIcon = #imageLiteral(resourceName: "iconDropdown").withRenderingMode(.alwaysOriginal).resizeVI(newSize: CGSize(width: 8, height: 8)) else {return}
        let legitImage = NSTextAttachment()
        legitImage.bounds = CGRect(x: 0, y: ((headerActionView.titleLabel?.font.capHeight)! - legitIcon.size.height).rounded() / 2, width: legitIcon.size.width, height: legitIcon.size.height)
        legitImage.image = legitIcon
        let legitImageString = NSAttributedString(attachment: legitImage)
        attributedHeaderTitle.append(legitImageString)
        
        headerActionView.tintColor = UIColor.ianBlackColor()
        headerActionView.setTitleColor(UIColor.ianBlackColor(), for: .normal)

        
        UIView.transition(with: headerActionView,
                          duration: 0.5,
                          options: [.transitionFlipFromBottom],
                          animations: {
                            
                            self.headerActionView.setAttributedTitle(attributedHeaderTitle, for: .normal)
                            self.headerActionView.sizeToFit()

        },
                          completion: nil)

    }
    
    
    fileprivate func setupNavigationItems() {
        
        navigationController?.navigationBar.barTintColor = UIColor.white
        let rectPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 5))
        UIColor.white.setFill()
        rectPath.fill()
        let finalImg = UIGraphicsGetImageFromCurrentImageContext()
        navigationController?.navigationBar.shadowImage = finalImg
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
    
        // REMOVES THE 1PX BOTTOM LINE IN NAV BAR
        navigationController?.navigationBar.shadowImage = UIImage()

        showCancelButtonWidth?.constant = self.viewFilter.isFiltering ? 30 : 0
        
        
        
        //        headerActionView.setTitle(self.fetchTypeInd + " ", for: .normal)

        
//        let headerTitle = NSAttributedString(string: self.fetchTypeInd + " ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Regular", size: 17)])

        guard let customFont = UIFont(name: "Poppins-Bold", size: 18) else {
            fatalError("""
        Failed to load the "CustomFont-Light" font.
        Make sure the font file is included in the project and the font name is spelled correctly.
        """
            )
        }
        
        var attributedHeaderTitle = NSMutableAttributedString()

        //let headerTitle = NSAttributedString(string: self.fetchTypeInd + " ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextBold, size: 18)])
        
        let headerTitle = NSAttributedString(string: self.fetchTypeInd + " ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: customFont])

        
        attributedHeaderTitle.append(headerTitle)
        
        guard let legitIcon = #imageLiteral(resourceName: "iconDropdown").withRenderingMode(.alwaysOriginal).resizeVI(newSize: CGSize(width: 8, height: 8)) else {return}
        let legitImage = NSTextAttachment()
        legitImage.bounds = CGRect(x: 0, y: ((headerActionView.titleLabel?.font.capHeight)! - legitIcon.size.height).rounded() / 2, width: legitIcon.size.width, height: legitIcon.size.height)
        legitImage.image = legitIcon
        let legitImageString = NSAttributedString(attachment: legitImage)
        attributedHeaderTitle.append(legitImageString)
        
        headerActionView.tintColor = UIColor.ianBlackColor()
        headerActionView.setAttributedTitle(attributedHeaderTitle, for: .normal)
        headerActionView.setTitleColor(UIColor.ianBlackColor(), for: .normal)
        headerActionView.sizeToFit()
        headerActionView.addTarget(self, action: #selector(showDropDown), for: .touchUpInside)

//        headerActionView.layoutIfNeeded()
        
        if navigationItem.titleView == self.headerActionView {
            self.updateNavHeader()
        } else {
            navigationItem.titleView = headerActionView
        }
        

        
        
        // Nav Bar Buttons
        let tempNavBarButton = NavBarMapButton.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        tempNavBarButton.addTarget(self, action: #selector(toggleMapFunction), for: .touchUpInside)
        let barButton1 = UIBarButtonItem.init(customView: tempNavBarButton)
        self.navigationItem.rightBarButtonItems = [barButton1]
        
//        if Auth.auth().currentUser?.isAnonymous == true {
//            let signOutButton = UIBarButtonItem(image: #imageLiteral(resourceName: "signout").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleGuestLogOut))
//            signOutButton.title = "Logout"
//            navigationItem.rightBarButtonItem = signOutButton
//        } else {
//            navFriendButton.addTarget(self, action: #selector(openFriends), for: .touchUpInside)
//            let friendButton = UIBarButtonItem.init(customView: navFriendButton)
//
//
//        // SET RIGHT NAR BAR BUTTON AS PROFILE PIC
//            let tempNavUserProfileBarButton = NavUserProfileButton.init(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
//            tempNavUserProfileBarButton.setProfileImage(imageUrl: CurrentUser.user?.profileImageUrl)
//            tempNavUserProfileBarButton.addTarget(self, action: #selector(openUserProfile), for: .touchUpInside)
////            navigationItem.setRightBarButtonItems([barButton2,friendButton], animated: false)
//        }
        
        // SET RIGHT BAR AS NOTIFICATION
        notificationButton.addTarget(self, action: #selector(openNotifications), for: .touchUpInside)
        if CurrentUser.unreadEventCount > 0 {
            //                let attributedTitle = NSMutableAttributedString(string: String(CurrentUser.unreadEventCount), attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Poppins-Bold", size: 18), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.ianLegitColor()]))
            //                notificationButton.setAttributedTitle(attributedTitle, for: .normal)
            notificationLabel.text = String(CurrentUser.unreadEventCount)
            notificationButton.addSubview(notificationLabel)
            notificationLabel.isHidden = false
            notificationLabel.isHidden = true

            
        } else {
            notificationLabel.text = ""
            notificationLabel.isHidden = true
            //                notificationButton.setTitle("", for: .normal)
        }
        
        if Auth.auth().currentUser?.isAnonymous == true {
            let signOutButton = UIBarButtonItem(image: #imageLiteral(resourceName: "signout").withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(handleGuestLogOut))
            signOutButton.tintColor = UIColor.ianLegitColor()
            signOutButton.title = "Logout"
            signOutButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 14)], for: .normal)
            navigationItem.leftBarButtonItem = signOutButton
        } else {
            let notificationBarButton = UIBarButtonItem.init(customView: notificationButton)
            navigationItem.leftBarButtonItem = notificationBarButton
        }
        
    }

    
    func didTapUserUid(uid: String) {
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = uid
        navigationController?.pushViewController(userProfileController, animated: true)
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
    
    
    func rangeSelected(range: String) {
        
    }
    
    func refreshAll() {
        self.handleRefresh()
    }
    
    func didTapListCancel(post: Post) {
        
    }
    
    
    func deletePostFromList(post: Post) {
        // No Deleting Posts Allowed From Explore Controller
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
    
    @objc func toggleMapFunction(){
        appDelegateFilter = self.viewFilter
        self.toggleMapView()
    }
    
    lazy var headerActionView : UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
//        let button = UIButton(type: .system)
        //        button.setTitle(self.currentDisplayList?.name, for: .normal)
        button.addTarget(self, action: #selector(showDropDown), for: .touchUpInside)
        button.backgroundColor = UIColor.clear

//        button.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
//        button.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
//        button.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        return button
    }()
    
    var dropdownView = HomeDropDownView()
    
    @objc func showDropDown(){

        dropdownView.viewFilter = viewFilter
        dropdownView.selectedVar = self.fetchTypeInd
        dropdownView.delegate = self
        dropdownView.show()
    }
    
    
    func dropDownSelected(string: String) {
        print("Selected item: \(string) at index: \(index)")
        self.fetchTypeInd = string
    }
    
    func refreshSearchBar(){
        if (self.viewFilter.isFiltering) {
            let currentFilter = self.viewFilter
            var searchCaption: String = ""
            
            if currentFilter.filterCaption != nil {
                searchCaption.append("\((currentFilter.filterCaption)!)")
            }
            
            if currentFilter.filterLocationName != nil {
                var locationNameText = currentFilter.filterLocationName
                if locationNameText == "Current Location" || currentFilter.filterLocation == CurrentUser.currentLocation {
                    // NOTHING. DON'T DISPLAY CURRENT LOCATION
                } else {
                    if searchCaption != "" {
                        searchCaption.append(" & ")
                    }
                    searchCaption.append("\(locationNameText!)")
                }
            }
            
            if currentFilter.filterLocationSummaryID != nil {
                var locationSummaryText = currentFilter.filterLocationSummaryID
                
                let cityID = locationSummaryText?.components(separatedBy: ",")[0]
                if searchCaption != "" {
                    searchCaption.append(" & ")
                }
                searchCaption.append("\(cityID!)")
            }
            
            if (currentFilter.filterLegit) {
                if searchCaption != "" {
                    searchCaption.append(" & ")
                }
                searchCaption.append("👌")
            }
            
            if currentFilter.filterMinRating != 0 {
                if searchCaption != "" {
                    searchCaption.append(" & ")
                }
                searchCaption.append("\((currentFilter.filterMinRating)) Stars")
            }
            print("MainViewController | Search Bar Display | \(searchCaption)")
            defaultSearchBar.text = searchCaption
        } else {
            defaultSearchBar.text = nil
        }
    }
    
    func setupCollectionView(){
        
        postCollectionView.register(FullPictureCell.self, forCellWithReuseIdentifier: listCellId)
        postCollectionView.register(TestGridPhotoCell.self, forCellWithReuseIdentifier: exploreCellId)
//        collectionView?.register(ExplorePhotoCell.self, forCellWithReuseIdentifier: exploreCellId)
        
//        collectionView.register(HomeSearchBarHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: listHeaderId)
        postCollectionView.register(HomeFilterBarHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: listHeaderId)

        
        
        //        collectionView?.backgroundColor = .white
        postCollectionView.backgroundColor = UIColor.rgb(red: 249, green: 249, blue: 249)
        postCollectionView.prefetchDataSource = self
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        postCollectionView.refreshControl = refreshControl
        postCollectionView.alwaysBounceVertical = true
        postCollectionView.keyboardDismissMode = .onDrag
        postCollectionView.delegate = self
        postCollectionView.dataSource = self
        postCollectionView.prefetchDataSource = self
        //        collectionView?.contentInset = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
        
        // Adding Empty Data Set
//        collectionView?.contentInset = UIEdgeInsets(top: 1, left: 2, bottom: 1, right: 2)
        postCollectionView.emptyDataSetSource = self
        postCollectionView.emptyDataSetDelegate = self
        postCollectionView.emptyDataSetView { (emptyview) in
            emptyview.isUserInteractionEnabled = false
        }
    }
    
    // Setup for Geo Range Button, Dummy TextView and UIPicker
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
//        self.openSearch(index: 0)
        return false
    }
    
    
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText.count == 0) {
            self.viewFilter.filterCaption = nil
            self.handleRefresh()
            searchBar.endEditing(true)
        }
    }
    
    //    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    //        self.fetchCaptionSearchPostIds()
    //    }
    //
    
    var noCaptionFilterEmojiCounts: [String:Int] = [:] {
        didSet {
            searchBarView.defaultEmojiCounts = noCaptionFilterEmojiCounts
            self.refreshEmojiSearchBar()
            
//            collectionView.reloadData()
//            collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    var displaySearchEmojis: [String] = [] {
        didSet {
            print(" displaySearchEmojis | \(displaySearchEmojis.count) Emojis")
            addTagCollectionView.reloadData()

        }
    }
    
    func refreshEmojiSearchBar(){
        
        var tempEmojis: [String] = []
        // ADD OTHER EMOJIS
        
        var filterCaption = self.viewFilter.filterCaption ?? ""
        
        for (key, value) in noCaptionFilterEmojiCounts.sorted(by: { $0.value > $1.value }) {
            if key.isSingleEmoji {
                if (filterCaption).contains(key) {
                    filterCaption = filterCaption.replacingOccurrences(of: key, with: "")
                    tempEmojis.insert(key, at: 0)
                } else {
                    tempEmojis.append(key)
                }
            }
        }
        
    // EMOJIS
        if filterCaption.removingWhitespaces() != "" {
            tempEmojis.insert(filterCaption, at: 0)
        }
        
    // USER
        if let filterUser = self.viewFilter.filterUser {
            tempEmojis.insert(filterUser.username, at: 0)
        }
        
    // LOCATION
        if let filterLoc = self.viewFilter.filterLocationSummaryID {
            tempEmojis.insert(filterLoc, at: 0)
        }
        
        

        displaySearchEmojis = tempEmojis
        
        
        
        
        self.addTagCollectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .left, animated: true)
        
    }
    
    
    var noCaptionFilterLocationCounts: [String:Int] = [:] {
        didSet {
            searchBarView.defaultLocationCounts = self.noCaptionFilterLocationCounts
        }
    }
    
    let addTagCollectionView: UICollectionView = {
        
        let uploadLocationTagList = UploadLocationTagList()
        uploadLocationTagList.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        uploadLocationTagList.estimatedItemSize = CGSize(width: 30, height: 30)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadLocationTagList)
        cv.layer.borderWidth = 0
        cv.backgroundColor = UIColor.clear
        return cv
    }()
    
    let addTagId = "addTagId"
    var searchbarContainerHeight: NSLayoutConstraint?
    var searchbarContainerHeightInput: CGFloat = 40
    
    func setupAddTagCollectionView(){
        addTagCollectionView.backgroundColor = UIColor.white
        addTagCollectionView.register(HomeFilterBarCell.self, forCellWithReuseIdentifier: addTagId)
        addTagCollectionView.delegate = self
        addTagCollectionView.dataSource = self
        addTagCollectionView.showsHorizontalScrollIndicator = false
        
        let uploadLocationTagList = UploadLocationTagList()
        uploadLocationTagList.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        uploadLocationTagList.estimatedItemSize = CGSize(width: 30, height: 30)
        addTagCollectionView.setCollectionViewLayout(uploadLocationTagList, animated: true)
        addTagCollectionView.reloadData()
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
    
    // Home Post Search Delegates
    
    func filterCaptionSelected(searchedText: String?){
        
        if searchedText == nil {
            self.handleRefresh()
            
        } else {
            print("Searching for \(searchedText)")
            defaultSearchBar.text = searchedText!
            self.viewFilter.filterCaption = searchedText
            self.refreshPostsForSearch()
        }
    }
    
    func userSelected(uid: String?){
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = uid
        self.navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    
    
    // Post Fetching
    
    @objc func fetchSortFilterPosts(){
        Database.fetchAllPosts(fetchedPostIds: self.fetchedPostIds, completion: { (firebaseFetchedPosts) in
            self.displayedPosts = firebaseFetchedPosts
            self.filterSortFetchedPosts()
        })
    }
    
    func showFetchProgressDetail(){
        
    // DEFAULT NOT FILTERING
        if !self.viewFilter.isFiltering {
            var sortString =  "Fetching Posts"
            if self.viewFilter.filterSort == sortNew {
                sortString = "Fetching Latest Posts"
            } else if self.viewFilter.filterSort == sortNearest {
                sortString = "Fetching Nearest Posts to You"
            } else if self.viewFilter.filterSort == sortTrending {
                sortString = "Fetching Most Popular Posts"
            }
            
            SVProgressHUD.show(withStatus: sortString)
        }
    
    // FILTERING FOR SOMETHING
        else if self.viewFilter.filterCaption != nil
        {
            SVProgressHUD.show(withStatus: "Searching Posts for \((self.viewFilter.filterCaption?.capitalizingFirstLetter())!)")
        }
        else if self.viewFilter.filterLocationSummaryID != nil
        {
            SVProgressHUD.show(withStatus: "Searching Posts at \((self.viewFilter.filterLocationSummaryID!.capitalizingFirstLetter()))")
        }
        else if self.viewFilter.filterLocation != nil
        {
            guard let coord = self.viewFilter.filterLocation?.coordinate else {return}
            let lat = Double(coord.latitude).rounded(toPlaces: 2)
            let long = Double(coord.longitude).rounded(toPlaces: 2)
            
            var coordinate = "(\(lat),\(long))"
            SVProgressHUD.show(withStatus: "Searching Posts at \n GPS: \(coordinate)")
        }
        else if self.viewFilter.filterUser != nil
        {
            guard let user = self.viewFilter.filterUser else {return}
            SVProgressHUD.show(withStatus: "Searching Posts by \(user.username.capitalizingFirstLetter())")
        }
        else if self.viewFilter.filterType != nil
        {
            SVProgressHUD.show(withStatus: "Searching Posts by \(self.viewFilter.filterType!.capitalizingFirstLetter())")
        }
        else if self.viewFilter.isFiltering
        {
            SVProgressHUD.show(withStatus: "Searching Posts")
        }
        else
        {
            SVProgressHUD.show(withStatus: "Fetching Posts")
        }
        
    }
    
    func fetchPostIdsFromCommunity(){
        
        if self.fetchTypeInd != HomeFetchOptions [1] {
            print("TestHomeViewController | fetchPostIdsFromCommunity | Wrong Fetch ID")
        return}
        
        if (self.viewFilter.filterGoogleLocationID != nil) {
            fetchPostIdsByRestaurant()
        } else if viewFilter.filterLocation != nil && viewFilter.filterRange != nil {
            fetchPostIdsByLocation()
        }
        
        
        // FETCHING EVERYONE
        if viewFilter.filterLocation != nil && viewFilter.filterRange != nil {
            // If has Filter Location, Pull all Post Id for Location
            if (self.viewFilter.filterGoogleLocationID != nil) {
                // Selected Google Location is a restaurant, search posts by Restaurant
                fetchPostIdsByRestaurant()
            } else {
                // Selected Google Location not a restaurant, search posts by Location with Range
                fetchPostIdsByLocation()
            }
        }  else if viewFilter.filterCaption != nil && viewFilter.filterRange == nil {
            // Fetch All Posts with Emoji Tags
            fetchPostIdsByTag()
        } else if viewFilter.filterRange == nil && viewFilter.filterCaption == nil {
            // No Caption or Location Filter
            if viewFilter.filterSort == defaultRecentSort{
                // Find Most Recent Posts
                print("HomeViewController | fetchPostIds | fetchPostIdsByDate")
                fetchPostIdsByDate()
            } else {
                // Find Posts Ranked by Social Stats
                fetchPostIdsByTrending()
            }
        }
    }
    
    func fetchPostIds(){

        self.showFetchProgressDetail()
        
        if self.fetchTypeInd == HomeFetchOptions[0] {
        // FETCHING CREW
            fetchCrewPostIds()
            
        }
        
    // FETCHING FROM COMMUNITY
        else if self.fetchTypeInd == HomeFetchOptions [1] {
            
        // FETCHING EVERYONE
            if viewFilter.filterLocation != nil && viewFilter.filterRange != nil {
                // If has Filter Location, Pull all Post Id for Location
                if (self.viewFilter.filterGoogleLocationID != nil) {
                    // Selected Google Location is a restaurant, search posts by Restaurant
                    fetchPostIdsByRestaurant()
                } else {
                    // Selected Google Location not a restaurant, search posts by Location with Range
                    fetchPostIdsByLocation()
                }
            }  else if viewFilter.filterCaption != nil && viewFilter.filterRange == nil {
                // Fetch All Posts with Emoji Tags
                fetchPostIdsByTag()
            } else if viewFilter.filterRange == nil && viewFilter.filterCaption == nil {
                // No Caption or Location Filter
                if viewFilter.filterSort == defaultRecentSort{
                    // Find Most Recent Posts
                    print("HomeViewController | fetchPostIds | fetchPostIdsByDate")
                    fetchPostIdsByDate()
                } else {
                    // Find Posts Ranked by Social Stats
                    fetchPostIdsByTrending()
                }
            }
            
            
        } else if self.fetchTypeInd == HomeFetchOptions [2] {
        // FETCHING SELF
            fetchSelfPostIds()
        }

    }
    
    func fetchCrewPostIds(){
        var uid: String?
        if (Auth.auth().currentUser?.isAnonymous)! {
            print("HomeViewController | fetchCrewPostIds | Guest User | Defaulting to WZ")
            uid = "2G76XbYQS8Z7bojJRrImqpuJ7pz2"
        } else {
            uid = Auth.auth().currentUser?.uid
        }
        
        Database.fetchAllHomeFeedPostIds(uid: uid) { (postIds) in
            print("Home| fetchCrewPostIds| Fetched \(postIds.count) Post Ids")
            self.fetchedPostIds = postIds
            NotificationCenter.default.post(name: TestHomeController.finishFetchingPostIdsNotificationName, object: nil)

        }
    }
    
    func fetchSelfPostIds(){
        var uid: String?
        if (Auth.auth().currentUser?.isAnonymous)! {
            print("HomeViewController | fetchCrePostIds | Guest User | Defaulting to WZ")
            uid = "2G76XbYQS8Z7bojJRrImqpuJ7pz2"
        } else {
            uid = Auth.auth().currentUser?.uid
        }
        
        Database.fetchAllPostIDWithCreatorUID(creatoruid: uid) { (postIds) in
            print("Home| fetchSelfPostIds| Fetched \(postIds.count) Post Ids")
            self.fetchedPostIds = postIds
            NotificationCenter.default.post(name: TestHomeController.finishFetchingPostIdsNotificationName, object: nil)
            
        }
    }
    
    func fetchPostIdsByDate(){
        print("Fetching Post Id By \(self.viewFilter.filterSort)")
        Database.fetchAllPostByCreationDate(fetchLimit: 100) { (fetchedPosts, fetchedPostIds) in
            self.fetchedPostIds = fetchedPostIds
            self.displayedPosts = fetchedPosts
            print("Fetch Posts By Date: Success, Posts: \(self.displayedPosts.count)")
            self.filterSortFetchedPosts()
        }
    }
    
    //    func fetchPostIdsBySocialRank(){
    //        print("Fetching Post Id By \(self.selectedHeaderSort)")
    //        Database.fetchPostIDBySocialRank(firebaseRank: self.selectedHeaderSort, fetchLimit: 250) { (postIds) in
    //            guard let postIds = postIds else {
    //                print("Fetched Post Id By \(self.selectedHeaderSort) : Error, No Post Ids")
    //                return}
    //
    //            print("Fetched Post Id By \(self.selectedHeaderSort) : Success, \(postIds.count) Post Ids")
    //            self.fetchedPostIds = postIds
    //            NotificationCenter.default.post(name: ExploreController.finishFetchingPostIdsNotificationName, object: nil)
    //        }
    //    }
    
    func fetchPostIdsByTrending(){
        let trendingStat = "Votes"
        print("Fetching Post Id By \(trendingStat)")
        Database.fetchPostIDBySocialRank(firebaseRank: trendingStat, fetchLimit: 250) { (postIds) in
            guard let postIds = postIds else {
                print("Fetched Post Id By \(trendingStat) : Error, No Post Ids")
                return}
            
            print("Fetched Post Id By \(trendingStat) : Success, \(postIds.count) Post Ids")
            self.fetchedPostIds = postIds
            NotificationCenter.default.post(name: TestHomeController.finishFetchingPostIdsNotificationName, object: nil)
        }
    }
    
    func fetchPostIdsByTag(){
        
        guard let searchText = self.viewFilter.filterCaption else {return}
        
        
        Database.translateToEmojiArray(stringInput: searchText) { (emojiTags) in
            guard let emojiTags = emojiTags else {
                print("Search Post With Emoji Tags: ERROR, No Emoji Tags")
                return
            }
            
            var tempPostIds: [PostId] = []
            let myGroup = DispatchGroup()
            
            for emoji in emojiTags {
                if !emoji.isEmptyOrWhitespace(){
                    myGroup.enter()
                    Database.fetchAllPostIDWithTag(emojiTag: emoji, completion: { (fetchedPostIds) in
                        myGroup.leave()
                        let fetchedPostCount = fetchedPostIds?.count ?? 0
                        print("\(emoji): \(fetchedPostCount) Posts")
                        if let fetchedPostIds = fetchedPostIds {
                            tempPostIds = tempPostIds + fetchedPostIds
                        }
                    })
                }
            }
            
            myGroup.notify(queue: .main) {
                print("\(emojiTags) Fetched Total \(tempPostIds.count) Posts")
                self.fetchedPostIds = tempPostIds
                NotificationCenter.default.post(name: TestHomeController.finishFetchingPostIdsNotificationName, object: nil)
            }
        }
    }
    
    
    func fetchPostIdsByLocation(){
        guard let location = self.viewFilter.filterLocation else {
            print("Fetch Post ID By Location GPS: ERROR, No Location GPS")
            return}
        
        if (self.viewFilter.filterGoogleLocationID != nil){
            print("Fetch Post ID By Location: ERROR, Is an Establishment")
            return}
        
        Database.fetchAllPostWithLocation(location: location, distance: Double(self.viewFilter.filterRange!)! ) { (fetchedPosts, fetchedPostIds) in
            self.fetchedPostIds = fetchedPostIds
            self.displayedPosts = fetchedPosts
            self.filterSortFetchedPosts()
            print("Fetch Posts By Location: Success, Posts: \(self.displayedPosts.count), Range: \(self.viewFilter.filterRange), Location: \(location.coordinate.latitude),\(location.coordinate.longitude)")
        }
        
        
    }
    
    func fetchPostIdsByRestaurant(){
        guard let googlePlaceID = self.viewFilter.filterGoogleLocationID else {
            print("Fetch Post ID By Restaurant: ERROR, No Google Place ID")
            return}
        
        
        Database.fetchAllPostWithGooglePlaceID(googlePlaceId: googlePlaceID) { (fetchedPosts, fetchedPostIds) in
            
            self.fetchedPostIds = fetchedPostIds
            self.displayedPosts = fetchedPosts
            self.filterSortFetchedPosts()
            print("Fetch Posts By Location: Success, Posts: \(self.displayedPosts.count), Google Place Id: \(googlePlaceID)")
        }
    }
    

    
    func filterSortFetchedPosts(){
        
        if self.noCaptionFilterLocationCounts.count == 0 {
            Database.countCityIds(posts: self.displayedPosts) { (locationCounts) in
                self.noCaptionFilterLocationCounts = locationCounts
                print("   HomeView | NoFilter Location Count | \(locationCounts.count)")
            }
        }
        
        if self.noCaptionFilterEmojiCounts.count == 0 {
            Database.countEmojis(posts: self.displayedPosts) { (emojiCounts) in
                self.noCaptionFilterEmojiCounts = emojiCounts
                print("   HomeView | NoFilter Emoji Count | \(emojiCounts.count)")

            }
        }
        
//        Database.filterPostsNew(inputPosts: self.displayedPosts, postFilter: Filter.init()) { (filteredPosts) in
//            print("HomeController | filterSortFetchedPosts | NoCaptionLocationFilter")
//
//        }
        
        
        // Filter Posts
        Database.filterPostsNew(inputPosts: self.displayedPosts, postFilter: self.viewFilter) { (filteredPosts) in
            
            // Sort Posts
            Database.sortPosts(inputPosts: filteredPosts, selectedSort: self.viewFilter.filterSort, selectedLocation: self.viewFilter.filterLocation, completion: { (filteredPosts) in
                
                self.displayedPosts = []
                if filteredPosts != nil {
                    self.displayedPosts = filteredPosts!
                }
                if self.postCollectionView.numberOfItems(inSection: 0) > 0 {
                    let indexPath = IndexPath(item: 0, section: 0)
                    self.postCollectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
                }

                print("Filter Sort Post: Success: \(self.displayedPosts.count) Posts")
                self.paginatePosts()
                SVProgressHUD.dismiss()
                self.showFilterView()

            })
        }
    }
    
    // Refresh Functions
    @objc func handleRefresh(){
        print("Refresh All")
        SVProgressHUD.show(withStatus: "Refreshing Feed")
//        self.clearAllPosts()
        self.clearFilter()
        self.setupNavigationItems()
        self.fetchPostIds()
        self.refreshEmojiSearchBar()
        self.postCollectionView.refreshControl?.endRefreshing()
    }
    
    @objc func handleRefreshForNewPost(){
        print("Refresh All")
        SVProgressHUD.show(withStatus: "Updating Feed With New Post")
        //        self.clearAllPosts()
        self.clearFilter()
        self.viewFilter.filterSort = defaultRecentSort
        self.setupNavigationItems()
        self.fetchPostIds()
        self.refreshEmojiSearchBar()
        self.postCollectionView.refreshControl?.endRefreshing()
    }
    
    func refreshPostsForSearch(){
        print("Refresh Posts, SEARCH PostIds by \(self.viewFilter.filterSort)")
//        self.showFilterView()
//        self.clearAllPosts()
        self.fetchPostIds()
        self.refreshEmojiSearchBar()
        self.postCollectionView.refreshControl?.endRefreshing()
        self.setupNavigationItems()
    }
    
    func clearDisplayedPosts(){
        self.displayedPosts = []
        self.refreshPagination()
        self.postCollectionView.reloadData()
    }
    
    func refreshPostsForSort(){
        print("Refresh Posts, SORT PostIds by \(self.viewFilter.filterSort)")
        // Does not repull post ids, just resorts displayed posts
        self.clearDisplayedPosts()
        self.fetchSortFilterPosts()
        self.paginatePosts()
        self.postCollectionView.refreshControl?.endRefreshing()
    }
    
    func clearAllPosts(){
        self.fetchedPostIds = []
        self.displayedPosts = []
        self.refreshPagination()
    }
    
    func clearFilter(){
        self.viewFilter.clearFilter()
        self.defaultSearchBar.text?.removeAll()
//        self.viewFilter.filterSort = defaultRank
//        self.showFilterView()
        
    }
    
    func refreshPagination(){
        self.isFinishedPaging = false
        self.paginatePostsCount = 0
        self.postCollectionView.reloadData()
    }
    
    // Search Delegates
    
    func filterControllerSelected(filter: Filter?) {
        guard let filter = filter else {return}
        self.hideSearchBar()
        self.viewFilter = filter
        self.refreshPostsForSearch()
    }
    
    
    // Pagination
    
    func paginatePosts(){
        
        let paginateFetchPostSize = 9
        
        self.paginatePostsCount = min(self.paginatePostsCount + paginateFetchPostSize, self.displayedPosts.count)
        
        if self.paginatePostsCount == self.displayedPosts.count {
            self.isFinishedPaging = true
        } else {
            self.isFinishedPaging = false
        }
        
        print("Home Paginate \(self.paginatePostsCount) : \(self.displayedPosts.count), Finished Paging: \(self.isFinishedPaging)")
        
        // NEED TO RELOAD ON MAIN THREAD OR WILL CRASH COLLECTIONVIEW
        DispatchQueue.main.async(execute: { self.postCollectionView.reloadData() })
//        DispatchQueue.main.async(execute: { self.collectionView?.reloadSections(IndexSet(integer: 0)) })

        
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    
    let postHeight: CGFloat = 180 //150
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        if collectionView == self.postCollectionView {
            if isPostView {
                var height: CGFloat = 35 //headerview = username userprofileimageview
                height += view.frame.width  // Picture
                height += 150    // Action Bar + List Count
    //            height += 25    // Date Bar
                return CGSize(width: view.frame.width, height: height)

            } else {
                // Grid View Size
                //            let width = (view.frame.width - 2) / 3
                let width = (view.frame.width - 2) / 2
                return CGSize(width: width, height: width)
            }
        } else if collectionView == self.addTagCollectionView {
            return CGSize(width: 40, height: 40)
        } else{
            return CGSize(width: 40, height: 40)
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return 0
        if collectionView == addTagCollectionView {
            print("addTagCollectionView | \(displaySearchEmojis.count)")
            return displaySearchEmojis.count
        }
        else if collectionView == self.postCollectionView
        {
            return self.paginatePostsCount
        }
        else
        {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let selectedText = displaySearchEmojis[indexPath.item].lowercased()
        let filterUsername = self.viewFilter.filterUser?.username.lowercased() ?? ""
        let filterLocationName = self.viewFilter.filterLocationSummaryID?.lowercased() ?? ""
        
        if collectionView == addTagCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: addTagId, for: indexPath) as! HomeFilterBarCell
            let option = displaySearchEmojis[indexPath.item].lowercased()
            
            
            // Only Emojis and Post type are tagged. Anything else is a caption search
            
            var displayText = ""
            
            var isSelected: Bool = (self.viewFilter.filterCaption ?? "").contains(option) || filterUsername == (option) || filterLocationName == (option)
            
            
        // ONLY SHOW DIC TEXT IF SELECTED
            if option.isSingleEmoji {
                displayText = option + (isSelected ? " \((EmojiDictionary[option] ?? "").capitalizingFirstLetter())" : "")
            } else {
                if ReverseEmojiDictionary[option] == nil {
                    displayText = option.capitalizingFirstLetter()
                } else {
                    displayText = (ReverseEmojiDictionary[option] ?? "") + (isSelected ? " \(option.capitalizingFirstLetter())" : "")
                }
            }
            
            
            cell.uploadLocations.text = displayText
            cell.uploadLocations.textColor = isSelected ? UIColor.ianBlackColor() : UIColor.gray
            cell.uploadLocations.font = isSelected ? UIFont(font: .avenirNextDemiBold, size: 20) : UIFont(font: .avenirNextRegular, size: 25)
            cell.layer.borderColor = isSelected ? UIColor.clear.cgColor : UIColor.gray.cgColor
            cell.backgroundColor = isSelected ? UIColor.ianOrangeColor() : UIColor.clear
                        cell.layer.borderWidth = 0
            
            return cell
            
        } else {

            var displayPost = displayedPosts[indexPath.item]
            
            if indexPath.item == self.paginatePostsCount - 1 && !isFinishedPaging{
                print("CollectionView Paginate")
                paginatePosts()
            }
            
            if isPostView {
                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: listCellId, for: indexPath) as! FullPictureCell
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
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: exploreCellId, for: indexPath) as! TestGridPhotoCell
                cell.delegate = self
                cell.showDistance = self.viewFilter.filterSort == defaultNearestSort
                cell.post = displayPost
                

                    cell.locationDistanceLabel.textColor = UIColor.ianBlackColor()
    //                cell.locationDistanceLabel.backgroundColor = UIColor.wh

                
                //            cell.selectedHeaderSort = self.viewFilter.filterSort
                return cell
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let selectedText = displaySearchEmojis[indexPath.item].lowercased()
        let filterUsername = self.viewFilter.filterUser?.username.lowercased() ?? ""
        let filterLocationName = self.viewFilter.filterLocationSummaryID?.lowercased() ?? ""

        if collectionView == addTagCollectionView {
            let option = displaySearchEmojis[indexPath.item].lowercased()
            if option.isSingleEmoji {
                self.didTapAddTag(addTag: option)
            } else if filterUsername == selectedText {
                self.viewFilter.filterUser = nil
                self.refreshPostsForSearch()
            } else if filterLocationName == selectedText {
                self.viewFilter.filterLocationSummaryID = nil
                self.refreshPostsForSearch()
            }
        }
    }
    
    // SORT FILTER HEADER
    
//    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//
////        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: listHeaderId, for: indexPath) as! HomeSearchBarHeader
//        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: listHeaderId, for: indexPath) as! HomeFilterBarHeader
//
//
//        header.selectedCaption = self.viewFilter.filterCaption
//        header.selectedPostType = self.viewFilter.filterType
//
//        let sorted = self.noCaptionFilterEmojiCounts.sorted(by: {$0.value > $1.value})
//        var topEmojis: [String] = []
//        for (index,value) in sorted {
//            if index.isSingleEmoji /*&& topEmojis.count < 4*/ {
//                topEmojis.append(index)
//            }
//        }
//        header.displayedEmojis = topEmojis
//        header.delegate = self
//        header.refreshFilterBar()
//
////        let testEmojis = ["🥓","🥩","🍗","🍖","🌭"]
////        header.displayedEmojis = testEmojis
//
////        print("Display Emojis | \(topEmojis.prefix(5))")
////        print("CollectionView SORT | \(self.viewFilter.filterSort) | \(header.headerSortSegment.selectedSegmentIndex) | \(header.buttonBar.frame.origin.x)")
//
//        return header
//    }
//
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        return CGSize(width: 150, height: 50 + 10)
//
//        //        return CGSize(width: view.frame.width, height: 30 + 5 + 5)
//    }
//
    
    func clearCaptionSearch() {
        self.viewFilter.filterCaption = nil
        self.refreshPostsForSearch()
    }
    
    func didTapEmoji(index: Int?, emoji: String) {
        let tempEmoji = emoji.lowercased()
        
        guard let caption = self.viewFilter.filterCaption else {
            self.viewFilter.filterCaption = tempEmoji
            self.refreshPostsForSearch()
            return
        }
        
        var filterCaption = caption.lowercased()
        
        if filterCaption == tempEmoji {
            self.viewFilter.filterCaption = nil
        }
        else if filterCaption.contains(tempEmoji) {
            self.viewFilter.filterCaption = filterCaption.replacingOccurrences(of: tempEmoji, with: "")
        }
        
        else {
            self.viewFilter.filterCaption = tempEmoji
        }
        self.refreshPostsForSearch()
    }
    
    func didTapAddTag(addTag: String) {
        // Can tap either post type string (breakfast, lunch dinner) or most popular emojis
        let tempAddTag = addTag.lowercased()

        guard let caption = self.viewFilter.filterCaption else {
            self.viewFilter.filterCaption = tempAddTag
            self.refreshPostsForSearch()
            return
        }
        var filterCaption = caption.lowercased()

        
        if tempAddTag.isSingleEmoji
        {
            // EMOJI
            if filterCaption.contains(tempAddTag) {
                self.viewFilter.filterCaption = filterCaption.replacingOccurrences(of: tempAddTag, with: "")
            } else {
                if self.viewFilter.filterCaption == nil {
                    self.viewFilter.filterCaption = tempAddTag
                } else {
                    self.viewFilter.filterCaption = filterCaption + tempAddTag
                }
            }
        }
        else
        {
            // STRING
            print(tempAddTag.capitalizingFirstLetter())
            print(UploadPostTypeString)

            if UploadPostTypeString.contains(tempAddTag.capitalizingFirstLetter()) {
                // CHECK IF IS MEAL TYPE
                if self.viewFilter.filterType == tempAddTag {
                    self.viewFilter.filterType = nil
                    self.viewFilter.filterCaption = filterCaption.replacingOccurrences(of: tempAddTag, with: "")
                } else {
                    self.viewFilter.filterType = tempAddTag
                }
            } else {
                // IS SEARCH STRING
                if filterCaption.contains(tempAddTag) {
                    self.viewFilter.filterCaption = filterCaption.replacingOccurrences(of: tempAddTag, with: "")
                } else {
                    self.viewFilter.filterCaption = filterCaption + tempAddTag
                }
                    
            }
        }
        
        self.refreshPostsForSearch()
        
    }
    
    
    
    // Empty Data Set Delegates
    
    // EMPTY DATA SET DELEGATES
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        if viewFilter.isFiltering {
            text = "Couldn't Find Anything Legit"
        } else {
            text = ""
//            let number = arc4random_uniform(UInt32(tipDefaults.count))
//            text = tipDefaults[Int(number)]
        }
        
        text = ""
        font = UIFont.boldSystemFont(ofSize: 17.0)
//        textColor = UIColor(hexColor: "25282b")
        textColor = UIColor.ianBlackColor()

        
        if text == nil {
            return nil
        }
        
        return NSMutableAttributedString(string: text!, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): font, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): textColor]))
        
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        font = UIFont(name: "Poppins-Regular", size: 15)
        textColor = UIColor.ianBlackColor()
        
        if viewFilter.isFiltering {
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
        
        if viewFilter.isFiltering {
            text = "Search For Something Else"
        } else {
            text = "Click to Discover New Things"
        }
        text = ""
        font = UIFont(name: "Poppins-Bold", size: 14)
        textColor = UIColor.ianBlueColor()
        
        if text == nil {
            return nil
        }
        
        return NSMutableAttributedString(string: text!, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): font, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): textColor]))
        
    }
    
    //    func buttonBackgroundImage(forEmptyDataSet scrollView: UIScrollView, for state: UIControlState) -> UIImage? {
    //
    //        var capInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    //        var rectInsets = UIEdgeInsets.zero
    //
    //        capInsets = UIEdgeInsets(top: 25, left: 25, bottom: 25, right: 25)
    //        rectInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    //
    //        let image = #imageLiteral(resourceName: "emptydatasetbutton")
    //        return image.resizableImage(withCapInsets: capInsets, resizingMode: .stretch).withAlignmentRectInsets(rectInsets)
    //    }
    
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
//        return UIColor.rgb(red: 249, green: 249, blue: 249)
        return UIColor.backgroundGrayColor()
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {
        if viewFilter.isFiltering {
            self.openFilter()
        } else {
            // Returns To Home Tab
            self.tabBarController?.selectedIndex = 1
        }
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapView view: UIView) {
        self.handleRefresh()
    }
    
    //    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
    //        let offset = (self.collectionView.frame.height) / 5
    //        return -50
    //    }
    
    func spaceHeight(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return 9
    }
    
    
    
    
    
    // List Header Delegate

    
    func didChangeToListView(){
        self.isPostView = true
        postCollectionView.reloadData()
    }
    
    func didChangeToGridView() {
        self.isPostView = false
        postCollectionView.reloadData()
    }
    
    
    func openFilter(){
        let filterController = SearchFilterController()
        filterController.delegate = self
        filterController.searchFilter = self.viewFilter
        self.navigationController?.pushViewController(filterController, animated: true)
    }
    
    
    lazy var rankLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Top 250"
        ul.isUserInteractionEnabled = true
        ul.font = UIFont.boldSystemFont(ofSize: 12)
        ul.numberOfLines = 0
        ul.textAlignment = NSTextAlignment.center
        ul.backgroundColor = UIColor.white
        ul.layer.cornerRadius = 10
        ul.layer.masksToBounds = true
        return ul
    }()
    
    func headerSortSelected(sort: String){
        self.viewFilter.filterSort = sort
        
        
        UIView.transition(with: navSortLabel,
                          duration: 0.5,
                          options: [.transitionFlipFromBottom],
                          animations: {
                            
                            self.navSortLabel.text = sort
                            self.navSortLabel.sizeToFit()
                            
        },
                          completion: nil)
        
//        if sort == defaultNearestSort {
//            self.isPostView = false
//        } else if sort == defaultRecentSort {
//            self.isPostView = true
//        }
        
        if !self.viewFilter.isFiltering {
            // Not Filtering for anything, so Pull in Post Ids by Recent or Social
            if (self.viewFilter.filterSort == HeaderSortOptions[1] && self.viewFilter.filterLocation == nil){
                print("Sort by Nearest, No Location, Look up Current Location")
                SVProgressHUD.show(withStatus: "Fetching Current Location")
                LocationSingleton.sharedInstance.determineCurrentLocation()
                let when = DispatchTime.now() + defaultGeoWaitTime // change 2 to desired number of seconds
                DispatchQueue.main.asyncAfter(deadline: when) {
                    //Delay for 1 second to find current location
                    self.viewFilter.filterLocation = CurrentUser.currentLocation
                    self.refreshPostsForSort()
                }
            } else {
                self.refreshPostsForSearch()
            }
        }
        else
        {
            // Filtered for something else, so just resorting posts based on social
            self.refreshPostsForSort()
        }
        
        // Add rank Label Animation
        //        view.addSubview(rankLabel)
        //        rankLabel.anchor(top: topLayoutGuide.bottomAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 3, paddingBottom: 0, paddingRight: 2, width: 55, height: 40)
        //        rankLabel.text = "Most \(self.selectedHeaderSort)"
        //        rankLabel.adjustsFontSizeToFitWidth = true
        //
        //        rankLabel.force = 0.5
        //        rankLabel.duration = 0.5
        //        rankLabel.animation = "zoomIn"
        //        rankLabel.curve = "spring"
        //
        //        // Display only if there is caption
        //
        //        rankLabel.animateNext {
        //            self.rankLabel.animation = "fadeOut"
        //            self.rankLabel.delay = 1
        //            self.rankLabel.animate()
        //        }
        
    }
    
    func locationSelected(){
        let locationController = LocationController()
        locationController.googlePlaceId = self.viewFilter.filterGoogleLocationID
        navigationController?.pushViewController(locationController, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Remove Rank Label is Scroll
        rankLabel.removeFromSuperview()
    }
    
    
    // HOME POST CELL DELEGATE METHODS
    
    func didTapBookmark(post: Post) {
        
        let sharePhotoListController = SharePhotoListController()
        sharePhotoListController.uploadPost = post
        sharePhotoListController.isBookmarkingPost = true
        sharePhotoListController.delegate = self
        navigationController?.pushViewController(sharePhotoListController, animated: true)
    }
    
    
    func didTapPicture(post: Post) {

        let pictureController = SinglePostView()
        if let tempPost = postCache[post.id!] {
            pictureController.post = tempPost
        } else {
            pictureController.post = post
        }
        
        pictureController.delegate = self
        navigationController?.pushViewController(pictureController, animated: true)

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
            self.viewFilter.filterMaxPrice = tagName
            self.refreshPostsForSearch()
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
                let listViewController = NewListCollectionView()
                listViewController.currentDisplayList = CurrentUser.lists[listIndex]
                listViewController.refreshPostsForFilter()
                
//                let listViewController = ListViewController()
//                listViewController.imageCollectionView.collectionViewLayout = HomeSortFilterHeaderFlowLayout()
//                listViewController.currentDisplayList = CurrentUser.lists[listIndex]
                self.navigationController?.pushViewController(listViewController, animated: true)
            }
            else {
                // List Tag Selected
                Database.checkUpdateListDetailsWithPost(listName: tagName, listId: tagId, post: post, completion: { (fetchedList) in
                    if fetchedList == nil {
                        // List Does not Exist
                        self.alert(title: "List Error", message: "List Does Not Exist Anymore")
                    } else {
//                        let listViewController = ListViewController()
//                        listViewController.imageCollectionView.collectionViewLayout = HomeSortFilterHeaderFlowLayout()
//                        listViewController.currentDisplayList = fetchedList
                        let listViewController = NewListCollectionView()
                        listViewController.currentDisplayList = fetchedList
                        listViewController.refreshPostsForFilter()
                        self.navigationController?.pushViewController(listViewController, animated: true)
                    }
                })
            }
        }
    }
    

    func refreshPost(post: Post) {
        
        if let index = displayedPosts.firstIndex(where: { (fetchedPost) -> Bool in
            fetchedPost.id == post.id
        }){
            displayedPosts[index] = post
        }
        
        // Update Cache
        
        let postId = post.id
        postCache[postId!] = post
        
        //        self.collectionView?.reloadItems(at: [filteredindexpath])
    }
    
    func didTapMessage(post: Post) {
        self.showMessagingOptions(post: post)
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
            self.postCollectionView.deleteItems(at: [filteredindexpath])
            Database.deletePost(post: post)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        present(deleteAlert, animated: true, completion: nil)
        
    }
    
}


// MARK: - UICollectionViewDataSourcePrefetching
extension TestHomeController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        var prefetchUrls: [URL] = []
        for indexPath in indexPaths {
            let post = displayedPosts[indexPath.row]
            let urls = post.imageUrls.flatMap { URL(string: $0) }
            prefetchUrls += urls
        }
    
        ImagePrefetcher(urls: prefetchUrls).start()
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
