//
//  LegitHomeView.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/14/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit
import Foundation
import EmptyDataSet_Swift
import Kingfisher
import SVProgressHUD
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth

import CoreLocation

class LegitHomeView: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    
    // POST VARIABLES
    
    var fetchedPostIds: [PostId] = []
    var displayedPosts: [Post] = []
    var tempSearchBarText: String? = nil
    var isFetchingPosts = false
    var setListener = false

    
    var fetchTypeInd: String = HomeFetchDefault {
        didSet{
//            self.handleRefresh()
        }
    }
    var fetchUser: User? = nil {
        didSet {
            refreshDropDownView()
        }
    }
    var fetchList: List? = nil {
        didSet {
            refreshDropDownView()
        }
    }

    var top100EmojiCounts: [String:Int] = [:]
//    var noCaptionFilterEmojiCounts: [String:Int] = [:]
//    var noCaptionFilterPlaceCounts: [String:Int] = [:]
//    var noCaptionFilterCityCounts: [String:Int] = [:]
    
    var noFilterTagCounts: PostTagCounts = PostTagCounts.init()
    var currentPostTagCounts: PostTagCounts = PostTagCounts.init()

    var noCaptionFilterTagCounts: [String:Int] = [:]
    var currentPostsFilterTagCounts: [String:Int] = [:]

    
    // Pagination Variables
    let HomeFullCellId = "HomeFullCellId"
    let HomeGridCellId = "HomeGridCellId"
    let HomeHeaderId = "HomeHeaderId"
    
    
    let EmojiCellId = "EmojiCellId"
    let UserCellId = "UserCellId"
    let LocationCellId = "LocationCellId"
    let ListCellId = "ListCellId"
    let TestCellId = "TestCellId"

    
    let headerHeight = /*180*/ 80 + UIApplication.shared.statusBarFrame.height
    var isPostView: Bool = false {
        didSet {
//            SVProgressHUD.show(withStatus: "Updating Post Format")
            self.postSortFormatBar.isGridView = !self.isPostView
//            self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
            self.collectionView.reloadData()
        }
    }
    
    var paginatePostsCount: Int = 0
    var isFinishedPaging = false {
        didSet{
            if isFinishedPaging == true {
                //                print("Finished Paging :", self.paginatePostsCount)
            }
        }
    }
    
    
    // SORT SEARCH
    let searchViewController = LegitSearchViewControllerNew()
    var viewFilter: Filter = Filter.init(defaultSort: defaultRecentSort) {
        didSet {
            print("Home viewFilter Check: ", viewFilter.searchTerms)
        }
    }
    
    
    static let finishFetchingPostIdsNotificationName = NSNotification.Name(rawValue: "HomeFinishFetchingPostIds")
    static let searchRefreshNotificationName = NSNotification.Name(rawValue: "HomeSearchRefresh")
    static let refreshListViewNotificationName = NSNotification.Name(rawValue: "HomeRefreshListView")
    
    
//    let dropDownView = LegitNavHeader()
    let dropDownView = NewLegitFeedSelectView()

    
    // BOTTOM EMOJI BAR
    var bottomEmojiBar = BottomEmojiBar()
    var bottomEmojiBarHide: NSLayoutConstraint?
    var bottomEmojiBarHeight: CGFloat = 50
    
    
// SEARCH RESULTS
    
    var hideSearchBar = false
    
    // SEARCH REC TABLE VIEW
    lazy var searchTableView : UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        tv.estimatedRowHeight = 100
        tv.allowsMultipleSelection = false
        return tv
    }()
    
    var searchTypeSegment = UISegmentedControl()

    var selectedSearchType: Int = 0
    var searchOptions = SearchBarOptions
    var searchFiltering = false
    
    var searchUserText: String? = nil
    var searchUser: User? = nil
    var searchText: String? = nil
    
// DEFAULT EMOJI AND LOCATION FROM FEED
    var defaultEmojiCounts:[String:Int] = [:]
    var defaultPlaceCounts:[String:Int] = [:]
    var defaultCityCounts:[String:Int] = [:]

// SEARCH TEMPS
    var displayEmojis:[EmojiBasic] = []
    var filteredEmojis:[EmojiBasic] = []
    
    var displayPlaces: [String] = []
    var filteredPlaces: [String] = []
    var selectedPlace: String? = nil
    var singleSelection = true
    
    var displayCity: [String] = []
    var filteredCity: [String] = []
    var selectedCity: String? = nil
    
    
    
    var allUsers = [User]()
    var filteredUsers = [User]()
    
    var allResultsDic: [String:String] = [:]
    var defaultAllResults:[String] = []
    var aggregateAllResults:[String] = []
    var filteredAllResults:[String] = []
    var currentPostRatingCounts = RatingCountArray

    override func viewWillAppear(_ animated: Bool) {
        self.setupNavigationItems()
//        self.initSearchSelections()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    // MARK: VIEW DID LOAD

    
    let addPhotoButton = UIButton()
    
    @objc func didTapAddPhoto() {
        self.extCreateNewPhoto()
    }
    
    let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "search_selected").withRenderingMode(.alwaysOriginal), for: .normal)
        button.contentMode = .scaleAspectFill
        button.backgroundColor = UIColor.clear
        button.addTarget(self, action: #selector(didTapSearchButton), for: .touchUpInside)
        return button
    }()
    
    let postSortFormatBar = PostSortFormatBar()
    
    var defaultHeight: CGFloat  = 1792.0
    var scalar: CGFloat = 1.0
    
    let newPostButton: UIButton = {
        let button = UIButton(type: .system)
//        button.setImage(#imageLiteral(resourceName: "search_selected").withRenderingMode(.alwaysOriginal), for: .normal)
        button.contentMode = .scaleAspectFill
        button.backgroundColor = UIColor.ianLegitColor()
        button.addTarget(self, action: #selector(didTapAddPhoto), for: .touchUpInside)
        return button
    }()
    
    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        collectionView.collectionViewLayout.invalidateLayout()
//    }
    
    var sortSegmentControl: UISegmentedControl = TemplateObjects.createPostSortButton()
    var segmentWidth_selected: CGFloat = 110.0
    var segmentWidth_unselected: CGFloat = 80.0
    
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
        button.backgroundColor = UIColor.lightBackgroundGrayColor()
//        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        button.tintColor = UIColor.ianLegitColor()
        button.titleLabel?.font =  UIFont(font: .avenirNextBold, size: 14)
        button.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        button.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12)
        button.imageView?.contentMode = .scaleAspectFit

        return button
    }()
    
    func toggleNavMapButton() {
        self.navMapButton.isHidden = !self.viewFilter.isFiltering
        self.addPhotoButton.isHidden = !self.navMapButton.isHidden
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.view.backgroundColor = UIColor.lightGray
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } 
        
        setupNavigationItems()
        setupCollectionView()
        fetchPostIds()
        
        NotificationCenter.default.addObserver(self, selector: #selector(fetchSortFilterPosts), name: LegitHomeView.finishFetchingPostIdsNotificationName, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: SharePhotoListController.updateFeedNotificationName, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: LegitHomeView.searchRefreshNotificationName, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didTapHomeButton), name: MainTabBarController.tapHomeTabBarButtonNotificationName, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.newUserPost(_:)), name: MainTabBarController.newUserPost, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.postEdited(_:)), name: AppDelegate.refreshPostNotificationName, object: nil)


//        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
//
//        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        
        self.view.addSubview(dropDownView)
        dropDownView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        dropDownView.viewFilter = self.viewFilter
        dropDownView.fetchTypeInd = self.fetchTypeInd
//        dropDownView.isHidden = true
        dropDownView.alpha = 0
        dropDownView.delegate = self
        
//        self.view.addSubview(bottomEmojiBar)
//        bottomEmojiBar.delegate = self
//        bottomEmojiBar.anchor(top: nil, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
//        bottomEmojiBar.layer.applySketchShadow(
//        color: UIColor.rgb(red: 0, green: 0, blue: 0),
//        alpha: 0.1,
//        x: 0,
//        y: 0,
//        blur: 10,
//        spread: 0)
        
        let emojiContainer = UIView()

        emojiContainer.addSubview(bottomEmojiBar)
        bottomEmojiBar.delegate = self
        bottomEmojiBar.anchor(top: emojiContainer.topAnchor, left: emojiContainer.leftAnchor, bottom: emojiContainer.bottomAnchor, right: emojiContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        bottomEmojiBar.layer.cornerRadius = 5
        bottomEmojiBar.layer.masksToBounds = true

        
        self.view.addSubview(emojiContainer)
        emojiContainer.anchor(top: nil, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        emojiContainer.layer.applySketchShadow(color: UIColor(red: 0, green: 0, blue: 0, alpha: 1), alpha: 0.5, x: 0, y: 3, blur: 4, spread: 0)
        bottomEmojiBarHide = emojiContainer.heightAnchor.constraint(equalToConstant: 0)
        bottomEmojiBarHide?.isActive = true

        
        
        self.setupTableView()
        self.view.addSubview(searchTableView)
        searchTableView.anchor(top: collectionView.topAnchor, left: view.leftAnchor, bottom: emojiContainer.topAnchor, right: view.rightAnchor, paddingTop: headerHeight - 8, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        searchTableView.alpha = 0
        searchTableView.layer.applySketchShadow(
            color: UIColor.rgb(red: 0, green: 0, blue: 0),
            alpha: 0.1,
            x: 0,
            y: 0,
            blur: 10,
            spread: 0)
 
        self.scalar = min(1, UIScreen.main.nativeBounds.height / defaultHeight)
        print(" ~ addPhotoButton Scalar", self.scalar, UIScreen.main.nativeBounds.height, defaultHeight)
        let addPhotoButtonSize: CGFloat = min(150, 75 * scalar)

        

//        searchTableView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        
//        postSortFormatBar.delegate = self
//        self.view.addSubview(postSortFormatBar)
//        postSortFormatBar.anchor(top: nil, left: view.leftAnchor, bottom: searchTableView.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 15, paddingRight: 10, width: 0, height: 40)
//        postSortFormatBar.navGridToggleButton.isHidden = true
////        postSortFormatBar.navMapButton.isHidden = false
//
//        self.view.addSubview(addPhotoButton)
//        addPhotoButton.anchor(top: nil, left: nil, bottom: postSortFormatBar.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: addPhotoButtonSize, height: addPhotoButtonSize)
//        addPhotoButton.layer.cornerRadius = addPhotoButtonSize / 2
//        setupAddPhotoButton()
//
//
//        self.view.addSubview(searchButton)
//        searchButton.anchor(top: nil, left: nil, bottom: addPhotoButton.topAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 15, paddingRight: 15, width: addPhotoButtonSize * 0.8, height: addPhotoButtonSize * 0.8)
//        searchButton.centerXAnchor.constraint(equalTo: addPhotoButton.centerXAnchor).isActive = true
//        searchButton.layer.cornerRadius = (addPhotoButtonSize * 0.8)/2
//        searchButton.layer.masksToBounds = true
//        searchButton.layer.borderColor = UIColor.darkGray.cgColor
//        searchButton.tintColor = UIColor.darkGray
//        searchButton.layer.borderWidth = 0
//        searchButton.backgroundColor = UIColor.white
//        searchButton.setImage(#imageLiteral(resourceName: "search_blank").withRenderingMode(.alwaysTemplate), for: .normal)
//        searchButton.contentMode = .scaleAspectFill
////        searchButton.addTarget(self, action: #selector(didTapAddPhoto), for: .touchUpInside)
//        searchButton.alpha = 0.7
//        searchButton.alpha = 0
//
//
        setupSegmentControl()
        
        sortSegmentControl.layer.borderWidth = 1
        view.addSubview(sortSegmentControl)
        sortSegmentControl.anchor(top: nil, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 10, paddingRight: 10, width: 0, height: 40)
        sortSegmentControl.alpha = 0.9
//        sortSegmentControl.rightAnchor.constraint(lessThanOrEqualTo: navMapButton.leftAnchor, constant: 15).isActive = true

//        sortSegmentControl.centerXAnchor.constraint(equalTo: barView.centerXAnchor).isActive = true
        self.selectSort(sender: sortSegmentControl)
        
        
        view.addSubview(newPostButton)
        newPostButton.anchor(top: nil, left: sortSegmentControl.rightAnchor, bottom: bottomLayoutGuide.topAnchor, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 10, paddingRight: 15, width: 120, height: 40)
//        newPostButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        newPostButton.setTitle("📷  Add Post", for: .normal)
        newPostButton.sizeToFit()
        newPostButton.tintColor = UIColor.ianWhiteColor()
        newPostButton.backgroundColor = UIColor.ianLegitColor()
        newPostButton.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
        newPostButton.layer.cornerRadius = 10
        newPostButton.layer.masksToBounds = true
        newPostButton.layer.borderWidth = 1
        newPostButton.layer.borderColor = UIColor.ianLegitColor().cgColor
        let headerTitle = NSAttributedString(string: "📷  New Post", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 14)])

        newPostButton.setAttributedTitle(headerTitle, for: .normal)

        view.addSubview(navMapButton)
//        navMapButton.anchor(top: nil, left: sortSegmentControl.rightAnchor, bottom: bottomLayoutGuide.topAnchor, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 10, paddingRight: 15, width: 120, height: 40)
        navMapButton.anchor(top: nil, left: newPostButton.leftAnchor, bottom: newPostButton.topAnchor, right: newPostButton.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 0, height: 40)

        navMapButton.layer.cornerRadius = 30/2
        navMapButton.layer.masksToBounds = true
        navMapButton.clipsToBounds = true
        navMapButton.addTarget(self, action: #selector(toggleMapFunction), for: .touchUpInside)
        navMapButton.isHidden = true
        toggleNavMapButton()

        
        self.view.addSubview(searchViewController.view)
        searchViewController.view.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        searchViewController.view.alpha = 0
        setupSearchView()


    }
    
    @objc func postEdited(_ notification: NSNotification) {
        let postId = (notification.userInfo?["updatedPostId"] ?? "")! as! String
        Database.fetchPostWithPostID(postId: postId) { (post, error) in
            if let post = post {
                self.refreshPost(post: post)
            }
        }
    }
    
    @objc func newUserPost(_ notification: NSNotification) {
        
        let postId = (notification.userInfo?["postId"] ?? "")! as! String
        let userId = (notification.userInfo?["uid"] ?? "")! as! String
        
        var tuserId: String! = userId
        var tpostId: String! = postId
        
//        tuserId = userId ?? ""
//        tpostId = postId ?? ""
        
        print("New User Post Notification ", tuserId, tpostId)
        
        
        if self.isFetchingPosts {return}
        if self.fetchTypeInd == HomeFetchOptions[0] {
            if let postId = notification.userInfo?["postId"] as? String {
                if !self.fetchedPostIds.contains(where: { (curPostId) -> Bool in
                    return curPostId.id == postId
                }) {
                    self.refreshPostsForSearch()
                    print("NEW FOLLOWING POST, REFRESHING ", postId )
                }
            }
        } else if self.fetchTypeInd == HomeFetchOptions[2] {
            if let userId = notification.userInfo?["uid"] as? String {
                if self.fetchUser?.uid == userId {
                    if let postId = notification.userInfo?["postId"] as? String {
                        if !self.fetchedPostIds.contains(where: { (curPostId) -> Bool in
                            return curPostId.id == postId
                        }) {
                            self.refreshPostsForSearch()
                            print("NEW USER POST, REFRESHING ", userId )
                        }
                    }
                }
            }
        }
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

    
    func setupAddPhotoButton() {
        addPhotoButton.layer.masksToBounds = true
        addPhotoButton.layer.borderColor = UIColor.ianLegitColor().cgColor
        addPhotoButton.layer.borderWidth = 0
        addPhotoButton.backgroundColor = UIColor.white
//        addPhotoButton.setImage(#imageLiteral(resourceName: "add_color").withRenderingMode(.alwaysOriginal), for: .normal)
//        let addPhotoImage = #imageLiteral(resourceName: "add_test").resizeImageWith(newSize: CGSize(width: addPhotoButtonSize * 0.8, height: addPhotoButtonSize * 0.8))
        let addPhotoImage = #imageLiteral(resourceName: "add_test_2")
//        let addPhotoImage = #imageLiteral(resourceName: "add_white_thick")

        addPhotoButton.tintColor = UIColor.ianLegitColor()

        addPhotoButton.setImage(addPhotoImage.withRenderingMode(.alwaysTemplate), for: .normal)

        addPhotoButton.contentMode = .scaleToFill
        addPhotoButton.addTarget(self, action: #selector(didTapAddPhoto), for: .touchUpInside)
        
        addPhotoButton.tintColor = UIColor.ianWhiteColor()
        addPhotoButton.backgroundColor = UIColor.ianLegitColor()
        addPhotoButton.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)

//        addPhotoButton.isHidden = true

        
    }
    
    
    
    @objc func didTapHomeButton() {
//        if self.dropDownView.isHidden == false {
//            self.hideDropDown()
//        } else {
//            self.handleRefresh()
//        }
        if self.dropDownView.alpha == 1 {
            self.hideDropDown()
        } else {
            self.handleRefresh()
        }
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            collectionView.contentInset = UIEdgeInsets(top: -UIApplication.shared.statusBarFrame.height, left: 0, bottom: 0, right: 0)
        } else {
        collectionView.contentInset = UIEdgeInsets(top: -UIApplication.shared.statusBarFrame.height, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)

        }

        collectionView.scrollIndicatorInsets = collectionView.contentInset

//        let selectedRange = collectionView.selectedRange
//        collectionView.scrollRangeToVisible(selectedRange)
    }
    
    func refreshDropDownView() {
        dropDownView.fetchUser = self.fetchUser
        dropDownView.fetchList = self.fetchList
        dropDownView.fetchTypeInd = self.fetchTypeInd
        dropDownView.resetViews()
        dropDownView.dropdownCollectionView.reloadData()

    }
    
    func showDropDown(){
        print("showDropDown")
        self.scrollToHeader()
        self.refreshDropDownView()
//        dropDownView.viewFilter = self.viewFilter

        dropDownView.searchUserView.fullSearchBar.resignFirstResponder()
        dropDownView.userSearchBar.text = nil
        dropDownView.refreshCollectionViews()
//        dropDownView.userSummary.fetchFollowingUsers()
        self.view.bringSubviewToFront(dropDownView)

        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
//            self.dropDownView.isHidden = false
            self.dropDownView.alpha = 1
        }, completion: nil)

    }
    
    func hideDropDown(){
        print("hideDropDown")
//        self.scrollToSectionHeader()
        self.scrollToHeader()
        self.dropDownView.alpha = 0

//        UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut, animations: {
////            self.dropDownView.isHidden = true
//            self.dropDownView.alpha = 0
//        }, completion: nil)
    }
    
    func scrollToSectionHeader(){
        let indexPath = IndexPath(row: 0, section: 0)
        guard let attribs = self.collectionView.layoutAttributesForSupplementaryElement(ofKind: UICollectionView.elementKindSectionHeader, at: indexPath) else {
            self.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
            return
        }
        //let headerTop = CGPoint(x: 0, y: attribs.frame.origin.y - self.collectionView.contentInset.top)
        let headerTop = CGPoint(x: 0, y: attribs.frame.origin.y )
//UIApplication.shared.statusBarFrame.height
        self.collectionView.setContentOffset(headerTop, animated: true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
    
    fileprivate func setupNavigationItems() {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.isNavigationBarHidden = true
//        guard let statusBarView = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else {
//            return
//        }
//        statusBarView.backgroundColor = UIColor.white
    }

    
    fileprivate func setupCollectionView() {
        
        let layout: UICollectionViewFlowLayout = ListViewFlowLayout()
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 5
        
        self.collectionView! = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        let cv = self.collectionView!
        cv.register(FullPictureCell.self, forCellWithReuseIdentifier: HomeFullCellId)
        cv.register(TestGridPhotoCell.self, forCellWithReuseIdentifier: HomeGridCellId)
        cv.register(NewLegitHomeHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: HomeHeaderId)
        cv.register(TestHomePhotoCell.self, forCellWithReuseIdentifier: TestCellId)
        
        
//        cv.register(LegitHomeHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: HomeHeaderId)
        cv.backgroundColor = UIColor.backgroundGrayColor()
//        cv.backgroundColor = UIColor.lightBackgroundGrayColor()

        cv.prefetchDataSource = self
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        cv.refreshControl = refreshControl
        cv.alwaysBounceVertical = true
        cv.keyboardDismissMode = .onDrag
        cv.delegate = self
        cv.dataSource = self
        cv.prefetchDataSource = self
        cv.contentInset = UIEdgeInsets(top: -UIApplication.shared.statusBarFrame.height, left: 0, bottom: 0, right: 0)
        cv.showsVerticalScrollIndicator = false
        //        collectionView?.contentInset = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
        
        // Adding Empty Data Set
        //        collectionView?.contentInset = UIEdgeInsets(top: 1, left: 2, bottom: 1, right: 2)
        cv.emptyDataSetSource = self
        cv.emptyDataSetDelegate = self
        cv.emptyDataSetView { (emptyview) in
            emptyview.isUserInteractionEnabled = true
        }
    }
    

    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        if collectionView == self.collectionView
        {
            return self.paginatePostsCount
        }
        else
        {
            return 0
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == self.collectionView {


            if indexPath.item == self.paginatePostsCount - 1 && !isFinishedPaging{
                print("CollectionView Paginate")
                paginatePosts()
            }
            
            var displayPost = displayedPosts[indexPath.item]
            SVProgressHUD.dismiss()
            // Can't Be Selected
            
            if self.viewFilter.filterLocation != nil && displayPost.locationGPS != nil {
                displayPost.distance = Double((displayPost.locationGPS?.distance(from: (self.viewFilter.filterLocation!)))!)
            }
            
            if isPostView {
                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeFullCellId, for: indexPath) as! FullPictureCell
                cell.post = displayPost
                cell.enableDelete = true
                cell.showDistance = self.viewFilter.filterSort == defaultNearestSort
                
                cell.delegate = self
                cell.currentImage = 1
                
//                cell.postDetailView.backgroundColor = (indexPath.item % 2 == 0) ? UIColor.mainBlue() : UIColor.clear
                
                
                return cell
            } else {
                
                
//                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeGridCellId, for: indexPath) as! TestGridPhotoCell

                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TestCellId, for: indexPath) as! TestHomePhotoCell
                cell.layer.cornerRadius = 14
                cell.layer.masksToBounds = true
                
                cell.delegate = self
                cell.showDistance = self.viewFilter.filterSort == defaultNearestSort
//                cell.emojiLabel.isHidden = !(self.viewFilter.filterSort == defaultNearestSort)
                cell.post = displayPost
                cell.emojiArray.alpha = 1
//                cell.infoView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
                // HIDE PROFILE IMAGE FOR RECENT BUT SHOW FOR NEAREST/TRENDING
                //cell.showUserProfileImage = !(self.viewFilter.filterSort == defaultRecentSort)
                cell.showUserProfileImage = true
                cell.layer.backgroundColor = UIColor.clear.cgColor
                cell.locationDistanceLabel.textColor = UIColor.mainBlue()
//                cell.locationDistanceLabel.isHidden = true
//                cell.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 1, x: 5, y: 5, blur: 10, spread: 3)
                //                cell.locationDistanceLabel.backgroundColor = UIColor.wh
                
                cell.layer.shadowColor = UIColor.lightGray.cgColor
                cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
                cell.layer.shadowRadius = 2.0
                cell.layer.shadowOpacity = 0.5
                cell.layer.masksToBounds = false
                cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: 14).cgPath
                //            cell.selectedHeaderSort = self.viewFilter.filterSort
                return cell
            }
            
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeGridCellId, for: indexPath) as! TestGridPhotoCell
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.collectionView {
            if isPostView {
                var displayPost = displayedPosts[indexPath.item]

                var height: CGFloat = 35 //headerview = username userprofileimageview
                height += view.frame.width  // Picture
                height += 160
                height += 20  // List
//                height += 60  // List

                height += (displayPost.likeCount > 0 || displayPost.comments.count > 0) ? 20 : 0 // Emoji Array + Star Rating
                height += !(displayPost.urlLink?.isEmptyOrWhitespace() ?? true) ? 15 : 0 // Emoji Array + Star Rating
                //            height += 25    // Date Bar
//                return CGSize(width: view.frame.width - 16, height: height)
                
                let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: height)
                let dummyCell = FullPictureCell(frame: frame)
                dummyCell.post = displayPost
                dummyCell.enableDelete = true
                dummyCell.layoutIfNeeded()
                
                let targetSize = CGSize(width: view.frame.width, height: height)
                let estimatedSize = dummyCell.systemLayoutSizeFitting(targetSize)
                
                let tempheight = max(300, estimatedSize.height)
                
                return CGSize(width: view.frame.width - 30, height: tempheight)
                
                
                
            } else {
                // Grid View Size
                //            let width = (view.frame.width - 2) / 3
//                let width = (view.frame.width - 20 - 15) / 2
                let width = (view.frame.width - 30 - 15) / 2
                
                let height = (GridCellImageHeightMult * width + GridCellEmojiHeight)
//                let height = (GridCellImageHeightMult * width)

                return CGSize(width: width, height: height)
                
                
                
            }
        }
        else
        {
            return CGSize(width: 40, height: 40)
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        

    }
    
     override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

//            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HomeHeaderId, for: indexPath) as! LegitHomeHeader
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HomeHeaderId, for: indexPath) as! NewLegitHomeHeader

            header.isGridView = !self.isPostView
            header.viewFilter = self.viewFilter
            header.fetchUser = self.fetchUser
            header.fetchTypeInd = self.fetchTypeInd
            header.delegate = self
            header.headerView.backgroundColor = UIColor.backgroundGrayColor()
            header.backgroundColor = UIColor.backgroundGrayColor()
        
            header.topSearchBar.viewFilter = self.viewFilter
            header.topSearchBar.filteredPostCount = displayedPosts.count
            header.topSearchBar.displayedEmojisCounts = self.top100EmojiCounts
            header.displayedEmojisCounts = self.top100EmojiCounts
        
//            header.emojiSearchBar.viewFilter = self.viewFilter
        
//            header.emojiSearchBar.backgroundColor = UIColor.clear
//            header.emojiSearchBar.searchBarView.backgroundColor = UIColor.clear
//            header.emojiSearchBar.fullSearchBar.isHidden = true
//            header.emojiSearchBar.filteringLabel.isHidden = true
//            header.emojiSearchBar.navEmojiButton.alpha = 0.5
//            header.emojiSearchBar.filteredPostCount = displayedPosts.count
//            header.emojiSearchBar.displayedEmojisCounts = self.top100EmojiCounts
//            header.emojiSearchBar.hideEmojiBar()
//            header.didTapEmojiBackButton()
        
            var isFiltering = self.viewFilter.isFiltering || self.fetchUser != nil || self.fetchList != nil
//            header.navMapButton.isHidden = !isFiltering
//            header.navMapButton.setTitle(isFiltering ? " Map Posts" : "", for: .normal)
            self.refreshBottomEmojiBar()

            return header
        }


       func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
            return CGSize(width: view.frame.width, height: headerHeight)
        }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 15, bottom: 0, right: 15)
//        return UIEdgeInsets(top: 10, left: 15, bottom: 0, right: 15)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
//        return 2
        return 15

    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
//        return 2
        return 15
    }
    
    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}

extension LegitHomeView {
    // HANDLE REFRESH FUNCTIONS
    
    @objc func handleRefresh(){
        print("LegitHomeView | handleRefresh")
        SVProgressHUD.show(withStatus: "Refreshing Feed")
        self.clearFilter()
        self.fetchPostIds()
        self.hideDropDown()
        self.toggleNavMapButton()
//        self.scrollToHeader()
        self.collectionView.refreshControl?.endRefreshing()
    }
    
    func refreshPostsForSearch(){
        print("LegitHomeView Refresh Posts For Search, SEARCH PostIds by \(self.viewFilter.filterSort)")
        self.toggleNavMapButton()
        self.fetchPostIds()
//        self.scrollToHeader()
        self.collectionView.refreshControl?.endRefreshing()
    }
    
    func refreshPostsForSort(){
        print("Refresh Posts, SORT PostIds by \(self.viewFilter.filterSort)")
        // Does not repull post ids, just resorts displayed posts
        self.fetchSortFilterPosts()
        self.scrollToHeader()
        self.paginatePosts()
        self.collectionView.refreshControl?.endRefreshing()
    }
    
    func clearFilter(){
        self.viewFilter.clearFilter()
        self.fetchTypeInd = HomeFetchOptions[0]
        self.fetchUser = nil
        self.fetchList = nil
    }
    
    func refreshPagination(){
        self.isFinishedPaging = false
        self.paginatePostsCount = 0
        self.collectionView.reloadData()
    }
    
    func clearAllPosts(){
        self.fetchedPostIds = []
        self.displayedPosts = []
        self.refreshPagination()
    }
    
}

extension LegitHomeView: LegitHomeHeaderDelegate, LegitNavHeaderDelegate, BottomEmojiBarDelegate, PostSortFormatBarDelegate {
    @objc func toggleMapFunction() {
        var tempFilter = self.viewFilter ?? Filter.init()
        print("toggleMapFunction | Legit Home View | \(tempFilter.filterCaptionArray) IsFiltering: \(tempFilter.isFiltering)")
        appDelegateFilter = tempFilter
        self.toggleMapView()
    }
    
    func didTapCell(tag: String) {
        print("LegitHomeView | didTapCell \(tag)")
    }
    

    func goToUser(uid: String?) {
        print("goToUser  \(uid)")
        guard let uid = uid else {return}
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = uid
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func goToList(listId: String?) {
        print("goToList  \(listId)")
        guard let listId = listId else {return}
        Database.fetchListforSingleListId(listId: listId) { (list) in
            guard let list = list else {return}
            let listViewController = LegitListViewController()
            listViewController.currentDisplayList = list
            listViewController.refreshPostsForFilter()
            self.navigationController?.pushViewController(listViewController, animated: true)
        }
    }
    
    
    func refreshBottomEmojiBar() {
        bottomEmojiBar.viewFilter = self.viewFilter
        bottomEmojiBar.filteredPostCount = self.displayedPosts.count
        
        // SHOW TOP 50 EMOJIS
        let sorted = self.top100EmojiCounts.sorted(by: {$0.value > $1.value})
        var topEmojis: [String] = []
        for (index,value) in sorted {
            if index.isSingleEmoji /*&& topEmojis.count < 4*/ {
                topEmojis.append(index)
            }
        }
        bottomEmojiBar.displayedEmojis = topEmojis
        
        let showBottomEmojiBar = (self.viewFilter.isFiltering || self.viewFilter.filterSort != defaultRecentSort)
        bottomEmojiBarHide?.constant = 0

//        bottomEmojiBarHide?.constant = showBottomEmojiBar ? bottomEmojiBarHeight : 0
        self.view.layoutIfNeeded()
        
    }
    
    func setupSearchView() {
        searchViewController.delegate = self
        searchViewController.searchViewFilter = self.viewFilter
        searchViewController.noFilterTagCounts = self.noFilterTagCounts
        searchViewController.currentPostTagCounts = self.currentPostTagCounts
        searchViewController.currentRatingCounts = self.currentPostRatingCounts
        searchViewController.searchBar.text = ""
    }
    
    
    @objc func didTapSearchButton() {
        print("Tap Search | \(self.currentPostsFilterTagCounts.count) Tags | \(self.viewFilter.searchTerms)")
        searchViewController.inputViewFilter = self.viewFilter
//        searchViewController.searchViewFilter = self.viewFilter
//        search.noCaptionFilterTagCounts = self.noCaptionFilterTagCounts
//        search.currentPostsFilterTagCounts = self.currentPostsFilterTagCounts
        searchViewController.noFilterTagCounts = self.noFilterTagCounts
        searchViewController.currentPostTagCounts = self.currentPostTagCounts
        searchViewController.currentRatingCounts = self.currentPostRatingCounts
        searchViewController.searchBar.text = ""
        searchViewController.singleSearch = !(self.viewFilter.searchTerms.count > 1)
        searchViewController.viewWillAppear(true)
//        let testNav = UINavigationController(rootViewController: search)
//
//        let transition = CATransition()
//        transition.duration = 0.5
//        transition.type = CATransitionType.fade
//        transition.subtype = CATransitionSubtype.fromTop
//        transition.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeIn)
//        view.window!.layer.add(transition, forKey: kCATransition)
//
//        self.present(testNav, animated: true) {
//            print("   Presenting List Option View")
//        }
        
//        self.present(self.search, animated: true) {
//            print("   Presenting List Option View")
//        }
        
        UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.transitionCrossDissolve, animations:
            {
                self.searchViewController.presentView()
        }
            , completion: { (finished: Bool) in
        })
        
        
        
        
    }
    
    
    
    func headerSortSelected(sort: String) {
        self.viewFilter.filterSort = sort
        
        let timeSinceLastLocation = Date().timeIntervalSince(self.viewFilter.filterLocationTime)
        
        if timeSinceLastLocation > 3600 {
            self.viewFilter.filterLocation = nil
            print("Refreshing Location Due to Too Long:", timeSinceLastLocation)
        }
        
        if !self.viewFilter.isFiltering {
            print("Not Filtering | ReSort Posts | \(sort) | \(self.viewFilter.isFiltering)")
            // Not Filtering for anything, so Pull in Post Ids by Recent or Social
            if (self.viewFilter.filterSort == HeaderSortOptions[1] && (self.viewFilter.filterLocation == nil)){
                print("Sort by Nearest, No Location, Look up Current Location")
                SVProgressHUD.show(withStatus: "Fetching Current Location")
                LocationSingleton.sharedInstance.determineCurrentLocation()
                let when = DispatchTime.now() + defaultGeoWaitTime // change 2 to desired number of seconds
                DispatchQueue.main.asyncAfter(deadline: when) {
                    //Delay for 1 second to find current location
                    self.viewFilter.filterLocation = CurrentUser.currentLocation
                    print("  - CURRENT USER LOCATION LOADED | headerSortSelected | \(CurrentUser.currentLocation)")
                    self.refreshPostsForSort()
                }
            } else {
                self.refreshPostsForSearch()
            }
        }
        else
        {
            // Filtered for something else, so just resorting posts based on social
            print("Filtering | ReSort Posts With Filter | \(sort) | \(self.viewFilter.isFiltering)")

            self.refreshPostsForSort()
        }
    }
    
    func toggleFeedType() {
//        if dropDownView.isHidden {
        if dropDownView.alpha == 0 {
            self.showDropDown()
        } else {
            self.hideDropDown()
        }
//        self.isPostView = !self.isPostView
    }
    
    func feedTypeSelected(type: String) {
        self.fetchTypeInd = type
        
        if let header = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? NewLegitHomeHeader {
            // Do your stuff here
            header.fetchTypeInd = self.fetchTypeInd
        }
        
        self.hideDropDown()
        self.refreshPostsForSearch()
    }
    
    func userFeedSelected(user: User) {
        self.viewFilter.clearFilter()
        self.viewFilter.filterUser = user
        self.fetchUser = user
        self.fetchList = nil
        self.fetchTypeInd = HomeFetchOptions[2]

        if let header = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? NewLegitHomeHeader {
            // Do your stuff here
            header.fetchTypeInd = self.fetchTypeInd
            header.fetchUser = user
        }
        
        self.hideDropDown()
        self.refreshPostsForSearch()
    }
    
    func userFeedSelected(list: List) {
        self.fetchList = list
        self.fetchUser = nil
        self.viewFilter.clearFilter()
        self.viewFilter.filterList = list
        self.fetchTypeInd = HomeFetchOptions[3]

        if let header = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? NewLegitHomeHeader {
            // Do your stuff here
            header.fetchTypeInd = self.fetchTypeInd
            header.fetchList = list
        }
        
        self.hideDropDown()
        self.refreshPostsForSearch()
    }

    func didRemoveTag(tag: String) {
        if tag == self.viewFilter.filterLocationSummaryID {
            self.viewFilter.filterLocationSummaryID = nil
            print("Remove Search | \(tag) | City | \(self.viewFilter.filterLocationSummaryID)")
        } else if tag == self.viewFilter.filterLocationName {
            self.viewFilter.filterLocationName = nil
            self.viewFilter.filterGoogleLocationID = nil
            print("Remove Search | \(tag) | Location | \(self.viewFilter.filterLocationName) | LegitHomeView")

        } else if self.viewFilter.filterCaptionArray.count > 0 {
            
            var tempArray = self.viewFilter.filterCaptionArray.map {$0.lowercased()}
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

        self.refreshPostsForSearch()
    }

    
    func didRemoveLocationFilter(location: String) {
        if self.viewFilter.filterLocationName?.lowercased() == location.lowercased() {
            self.viewFilter.filterLocationName = nil
        } else if self.viewFilter.filterLocationSummaryID?.lowercased() == location.lowercased() {
            self.viewFilter.filterLocationSummaryID = nil
        }
        self.refreshPostsForSearch()
    }
    
    func didRemoveRatingFilter(rating: String) {
        if extraRatingEmojis.contains(rating) {
            self.viewFilter.filterRatingEmoji = nil
        } else if rating.contains("⭐️") {
            self.viewFilter.filterMinRating = 0
        }
        self.refreshPostsForSearch()
    }
    
    
    func didTapAddTag(addTag: String) {
        // ONLY EMOJIS BECAUSE CAN ONLY ADD EMOJI TAGS FROM HEADER
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
        self.refreshPostsForSearch()

/*
        guard let filterCaption = self.viewFilter.filterCaption?.lowercased() else {
            self.viewFilter.filterCaption = tempAddTag
            self.refreshPostsForSearch()
            return
        }
        
        if filterCaption.contains(tempAddTag) {
            self.viewFilter.filterCaption = filterCaption.replacingOccurrences(of: tempAddTag, with: "")
        } else {
            if self.viewFilter.filterCaption == nil {
                self.viewFilter.filterCaption = tempAddTag
            } else {
                self.viewFilter.filterCaption = filterCaption + tempAddTag
            }
        }
        
        
//        self.viewFilter.filterCaption = "TESTESGFESGE "

        self.refreshPostsForSearch()
 */
        
    }
    
    func didTapGridButton() {
//        NotificationCenter.default.post(name: MainTabBarController.showOnboarding, object: nil)

        self.isPostView = !self.isPostView
//        SVProgressHUD.showProgress(status: "Updating Post Format")
        if self.isPostView {
            SVProgressHUD.show(withStatus: "Loading Full Posts")
        }
        
        print("didTapGridButton | Legit Home View | \(self.isPostView) self.isPostView")
    }
    
    func didTapMapButton() {
        print("didTapMapButton | Legit Home View | \(self.viewFilter) IsFiltering")
        appDelegateFilter = self.viewFilter
        self.toggleMapView()
    }
    
    @objc func didTapNotification(){
        let note = UserEventViewController()
        self.navigationController?.pushViewController(note, animated: true)
    }
    
    func showSearchView() {
        self.scrollToHeader()

        UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.transitionCrossDissolve, animations:
            {
                self.searchTableView.alpha = 1
        }
            , completion: { (finished: Bool) in
        })
        self.collectionView.isScrollEnabled = false
    }
    func hideSearchView() {
        UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.transitionCrossDissolve, animations:
            {
                self.searchTableView.alpha = 0
        }
            , completion: { (finished: Bool) in
        })
        self.collectionView.isScrollEnabled = true

    }
    
    func openNotifications() {
        let note = UserEventViewController()
        self.navigationController?.pushViewController(note, animated: true)
    }

    
    func scrollToHeader(){
        if let header = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? NewLegitHomeHeader {

            let curOffset  = self.collectionView.contentOffset
            let maxY = (self.collectionView.convert(header.frame, to: self.view).maxY)

            let yOffset = (header.frame.height) - maxY

            self.collectionView.setContentOffset(CGPoint(x: 0, y: curOffset.y - yOffset), animated: true)
//            print(header.frame.maxY)
//            print("CONVERT | \(fra)")
        }
        
        if self.collectionView.numberOfItems(inSection: 0) > 0 {
            let indexPath = IndexPath(item: 0, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
        }
        
//        print("SCROLL TO TOP")

    }
    
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let header = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? NewLegitHomeHeader {
            let minY = (self.collectionView.convert(header.frame, to: self.view).minY)
            let maxY = (self.collectionView.convert(header.frame, to: self.view).maxY)
            let midY = (self.collectionView.convert(header.frame, to: self.view).midY)
//            print("Min: \(minY) | Max: \(maxY) | \(header.frame.height)")
            
        }
        
    }
    
    
    
    
}

extension LegitHomeView: FullPictureCellDelegate, TestGridPhotoCellDelegate, SharePhotoListControllerDelegate, SinglePostViewDelegate {

    func didTapBookmark(post: Post) {
        let sharePhotoListController = SharePhotoListController()
        sharePhotoListController.uploadPost = post
        sharePhotoListController.isBookmarkingPost = true
        sharePhotoListController.delegate = self
        navigationController?.pushViewController(sharePhotoListController, animated: true)
    }
    
    func didTapUser(post: Post) {
//        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
//        userProfileController.displayUserId = post.user.uid
//        navigationController?.pushViewController(userProfileController, animated: true)
                self.extTapUser(userId: post.user.uid)
    }
    
    func didTapLike(post: Post) {
//        print("didTapLike")
//        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func didTapComment(post: Post) {
        let commentsController = CommentsController(collectionViewLayout: UICollectionViewFlowLayout())
        commentsController.post = post
        navigationController?.pushViewController(commentsController, animated: true)
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
    
    func didTapMessage(post: Post) {
        self.showMessagingOptions(post: post)
    }
    
    func refreshPost(post: Post) {
        if let index = displayedPosts.firstIndex(where: { (fetchedPost) -> Bool in
            fetchedPost.id == post.id
        }){
            displayedPosts[index] = post
            let indexPath = IndexPath(row: index, section: 0)
            print("Refresh Post Legit Home View : \(post.id) | \(index) Index | \(self.collectionView.visibleCells.count) Visible Cells")
            if index < self.collectionView.visibleCells.count {
                self.collectionView.reloadItems(at: [indexPath])
            }
        }
        
        // Update Cache
//        let postId = post.id
//        postCache[postId!] = post
        

    }
    
    func didTapPicture(post: Post) {
        self.extTapPicture(post: post)

//        let pictureController = SinglePostView()
//        let pictureController = NewSinglePostView()
//
//        if let tempPost = postCache[post.id!] {
//            pictureController.post = tempPost
//        } else {
//            pictureController.post = post
//        }
//
//        pictureController.delegate = self
//        navigationController?.pushViewController(pictureController, animated: true)
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
        
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        present(optionsAlert, animated: true, completion: nil)
        
    }
    
    func didTapExtraTag(tagName: String, tagId: String, post: Post) {
        // Check Current User List
        if let listIndex = CurrentUser.lists.firstIndex(where: { (currentList) -> Bool in
            currentList.id == tagId
        }) {
            let listViewController = LegitListViewController()
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
                    let listViewController = LegitListViewController()
                    listViewController.currentDisplayList = fetchedList
                    listViewController.refreshPostsForFilter()
                    self.navigationController?.pushViewController(listViewController, animated: true)
                }
            })
        }
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
    
    func didTapListCancel(post: Post) {
        
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
            self.collectionView.deleteItems(at: [filteredindexpath])
            Database.deletePost(post: post)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        present(deleteAlert, animated: true, completion: nil)
        
    }
    
    
    
}

// MARK: - UICollectionViewDataSourcePrefetching
extension LegitHomeView: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        if displayedPosts.count != indexPaths.count {
            return
        }
        
        var prefetchUrls: [URL] = []
        for indexPath in indexPaths {
            let post = displayedPosts[indexPath.row]
            let urls = post.imageUrls.flatMap { URL(string: $0) }
            prefetchUrls += urls
        }
        
        ImagePrefetcher(urls: prefetchUrls).start()
    }
}


// MARK: EMPTY DATA SET


extension LegitHomeView: EmptyDataSetSource, EmptyDataSetDelegate {

    // EMPTY DATA SET DELEGATES

    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        if viewFilter.isFiltering {
            text = "SORRY!"
        } else {
            text = ""
            //            let number = arc4random_uniform(UInt32(tipDefaults.count))
            //            text = tipDefaults[Int(number)]
        }
        
        font = UIFont(name: "Poppins-Bold", size: 40)
        //        textColor = UIColor(hexColor: "25282b")
        textColor = UIColor.ianBlackColor()
        
        
        if text == nil {
            return nil
        }
        
        let descTitle = NSAttributedString(string: text!, attributes: [NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.font: font])

        return descTitle
        
    }

    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        font = UIFont.systemFont(ofSize: 14)
        textColor = UIColor.rgb(red: 43, green: 43, blue: 43)
        
        if viewFilter.isFiltering {
            text = "Nothing Legit Here! 😭"
        } else {
            text = ""
        }
        
        if text == nil {
            return nil
        }
        
        let descTitle = NSAttributedString(string: text!, attributes: [NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.font: font])

        return descTitle
        
    }

    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        //        return #imageLiteral(resourceName: "amaze").resizeVI(newSize: CGSize(width: view.frame.width/2, height: view.frame.height/2))
        var image: UIImage?
        if viewFilter.isFiltering {
            image = #imageLiteral(resourceName: "noResults_pic")
        } else {
            image = #imageLiteral(resourceName: "Legit_Vector")
        }
        
        return image
        
    }
    
    func buttonImage(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> UIImage? {
        var image: UIImage?
        if viewFilter.isFiltering {
            image = #imageLiteral(resourceName: "noResults_pic")
        } else {
            image = #imageLiteral(resourceName: "Legit_Vector")
        }
        
        return nil
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
        
        
        font = UIFont.systemFont(ofSize: 14)
        textColor = UIColor.rgb(red: 43, green: 43, blue: 43)
        
        if viewFilter.isFiltering {
            text = "Nothing Legit Here! 😭"
        } else {
            text = ""
        }
        
        if text == nil {
            return nil
        }
        
        
        let descTitle = NSAttributedString(string: text!, attributes: [NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.font: font])
        
        return nil

        
    }
    
    func emptyDataSetShouldAllowTouch(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return true
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
//        return UIColor.lightGray

    }

    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {
        self.handleRefresh()

//        if viewFilter.isFiltering {
////            self.openFilter()
//        } else {
//            // Returns To Home Tab
//            self.tabBarController?.selectedIndex = 1
//        }
    }

    func emptyDataSet(_ scrollView: UIScrollView, didTapView view: UIView) {
        self.handleRefresh()
    }

        func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
            let offset = (self.collectionView.frame.height) / 5
            return 40
        }

    func spaceHeight(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return 9
    }
}

extension LegitHomeView {
    // CALLING FUNCTIONS

    func fetchPostIds(){
        if self.isFetchingPosts {
            print("Is Fetching Post")
            return
        } else {
            self.isFetchingPosts = true
        }
        self.showFetchProgressDetail()
        
    // FETCHING FRIENDS
        if self.fetchTypeInd == HomeFetchOptions[0] {
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
            
        }
    // FETCHING SELF
        else if self.fetchTypeInd == HomeFetchOptions [2] && self.fetchUser?.uid == CurrentUser.uid {
            // Enables Guest Mode
            fetchSelfPostIds()
        }
        
    // FETCHING USER
        else if self.fetchTypeInd == HomeFetchOptions [2] && self.fetchUser != nil {
            fetchUserPostIds()
        }
        
    // FETCHING LIST
        else if self.fetchTypeInd == HomeFetchOptions [3] && self.fetchList != nil {
            fetchListPostIds()
        }
        
    }
    
    
    
    func showFetchProgressDetail(){
        
        print("showFetchProgressDetail | Filtering: \(self.viewFilter.isFiltering)")
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
        else if self.viewFilter.filterCaptionArray.count > 0 || self.viewFilter.filterTypeArray.count > 0
        {
            var searchText = self.viewFilter.filterCaptionArray.count > 0 ? self.viewFilter.filterCaptionArray.joined(separator: " ") : ""
            searchText += self.viewFilter.filterTypeArray.count > 0 ? self.viewFilter.filterTypeArray.joined(separator: " ") : ""
            SVProgressHUD.show(withStatus: "Searching Posts for \(searchText)")
        }
        else if self.viewFilter.filterLocationSummaryID != nil
        {
            SVProgressHUD.show(withStatus: "Searching Posts at \((self.viewFilter.filterLocationSummaryID!.capitalizingFirstLetter()))")
        }
        else if let googleId = self.viewFilter.filterGoogleLocationID
        {
            let locationName = locationGoogleIdDictionary.key(forValue: googleId) ?? ""
            SVProgressHUD.show(withStatus: "Searching Posts at \((locationName.capitalizingFirstLetter()))")
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
        else if self.viewFilter.filterLocation != nil
        {
            guard let coord = self.viewFilter.filterLocation?.coordinate else {return}
            let lat = Double(coord.latitude).rounded(toPlaces: 2)
            let long = Double(coord.longitude).rounded(toPlaces: 2)
            
            var coordinate = "(\(lat),\(long))"
            SVProgressHUD.show(withStatus: "Searching Posts at \n GPS: \(coordinate)")
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
            NotificationCenter.default.post(name: LegitHomeView.finishFetchingPostIdsNotificationName, object: nil)
            
            // SET LISTENER ONCE AFTER FETCHING POSTS
            if !self.setListener {
                if CurrentUser.followingUids.count > 0 {
                    Database.setupUserFollowingListener(uids: CurrentUser.followingUids)
                    print(" 3 | FETCH_CURRENT_USER | Setup Listeners for \(CurrentUser.followingUids.count) Following Users")
                    self.setListener = true
                }
            }
            
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
            NotificationCenter.default.post(name: LegitHomeView.finishFetchingPostIdsNotificationName, object: nil)
            
        }
    }
    
    func fetchUserPostIds(){
        guard let fetchUser = fetchUser else {return}
        let uid = fetchUser.uid

        Database.fetchAllPostIDWithCreatorUID(creatoruid: uid) { (postIds) in
            print("Home| fetchUserPostIds | \(fetchUser.username) | Fetched \(postIds.count) Post Ids")
            self.fetchedPostIds = postIds
            NotificationCenter.default.post(name: LegitHomeView.finishFetchingPostIdsNotificationName, object: nil)
        }
    }
    
    func fetchListPostIds(){
        guard let list = self.fetchList else {return}
        guard let listId = self.fetchList?.id else {return}

        Database.fetchAllPostIdsForMultLists(listIds: [listId]) { (postIds) in
            print("Home| fetchListPostIds | \(list.name) | Fetched \(postIds.count) Post Ids")
            self.fetchedPostIds = postIds
            NotificationCenter.default.post(name: LegitHomeView.finishFetchingPostIdsNotificationName, object: nil)
        }
    }
    
    func fetchPostIdsByDate(){
        print("Fetching Post Id By \(self.viewFilter.filterSort)")
        Database.fetchAllPostByCreationDate(fetchLimit: 100) { (fetchedPosts, fetchedPostIds) in
            self.isFetchingPosts = false
            self.fetchedPostIds = fetchedPostIds
            self.displayedPosts = fetchedPosts
            print("Fetch Posts By Date: Success, Posts: \(self.displayedPosts.count)")
            self.filterSortFetchedPosts()
        }
    }
    
    
    func fetchPostIdsByTrending(){
        let trendingStat = "Votes"
        print("Fetching Post Id By \(trendingStat)")
        Database.fetchPostIDBySocialRank(firebaseRank: trendingStat, fetchLimit: 250) { (postIds) in
            guard let postIds = postIds else {
                print("Fetched Post Id By \(trendingStat) : Error, No Post Ids")
                return}
            print("Fetched Post Id By \(trendingStat) : Success, \(postIds.count) Post Ids")
            self.fetchedPostIds = postIds
            NotificationCenter.default.post(name: LegitHomeView.finishFetchingPostIdsNotificationName, object: nil)
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
                NotificationCenter.default.post(name: LegitHomeView.finishFetchingPostIdsNotificationName, object: nil)
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
            self.isFetchingPosts = false
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
            self.isFetchingPosts = false
            self.fetchedPostIds = fetchedPostIds
            self.displayedPosts = fetchedPosts
            self.filterSortFetchedPosts()
            print("Fetch Posts By Location: Success, Posts: \(self.displayedPosts.count), Google Place Id: \(googlePlaceID)")
        }
    }
    

    
}

extension LegitHomeView {

    @objc func fetchSortFilterPosts(){
        Database.fetchAllPosts(fetchedPostIds: self.fetchedPostIds, completion: { (firebaseFetchedPosts) in
            self.isFetchingPosts = false
            self.displayedPosts = firebaseFetchedPosts
            self.filterSortFetchedPosts()
        })
    }
    
    func updateNoFilterCounts(){
        
        Database.summarizePostTags(posts: self.displayedPosts) { (tagCounts) in
            self.currentPostTagCounts = tagCounts
            self.currentPostsFilterTagCounts = tagCounts.allCounts
            if !self.viewFilter.isFiltering {
                self.noCaptionFilterTagCounts = tagCounts.allCounts
                self.noFilterTagCounts = tagCounts
            }
        }
        
        Database.summarizeRatings(posts: self.displayedPosts) { (ratingCounts) in
            self.currentPostRatingCounts = ratingCounts
        }
        
        let first50 = Array(self.displayedPosts.prefix(100))
        Database.countEmojis(posts: first50, onlyEmojis: true) { (emojiCounts) in
            self.top100EmojiCounts = emojiCounts
//            self.initSearchSelections()
            print("   HomeView | NoFilter Emoji Count | \(emojiCounts.count)")
            self.refreshBottomEmojiBar()
        }
        
        
    }
    
    
// DATA HANDLING
    func filterSortFetchedPosts(){
        // Filter Posts
        Database.filterPostsNew(inputPosts: self.displayedPosts, postFilter: self.viewFilter) { (filteredPosts) in
            
            // Sort Posts
            Database.sortPosts(inputPosts: filteredPosts, selectedSort: self.viewFilter.filterSort, selectedLocation: self.viewFilter.filterLocation, completion: { (filteredPosts) in
                
                self.displayedPosts = []
                if filteredPosts != nil {
                    self.displayedPosts = filteredPosts!
                }
                
                self.scrollToHeader()
                
                print("Filter Sort Post: Success: \(self.displayedPosts.count) Posts")
                self.updateNoFilterCounts()
                self.paginatePosts()
//                self.showFilterView()
                
            })
        }
    }
    
    
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
        DispatchQueue.main.async(execute: {
            self.collectionView.reloadData()
             })
            SVProgressHUD.dismiss()
        //        DispatchQueue.main.async(execute: { self.collectionView?.reloadSections(IndexSet(integer: 0)) })
        
        
    }
    
    

}

// MARK: TABLE VIEW DELEGATES


extension LegitHomeView: UITableViewDelegate, UITableViewDataSource, LegitSearchViewControllerDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of sections
        let searchType = searchOptions[self.selectedSearchType]
        let isFiltering = self.searchFiltering
        
        // All
        if searchType == SearchAll {
            return isFiltering ? filteredAllResults.count : defaultAllResults.count
        }
            
            // Emoji
        else if searchType == SearchEmojis {
            return isFiltering ? filteredEmojis.count : displayEmojis.count
        }
            
            // Places
        else if searchType == SearchPlace {
            return isFiltering ? filteredPlaces.count : displayPlaces.count
        }
            
            // Locations
        else if searchType == SearchCity {
            return isFiltering ? filteredCity.count : displayCity.count
        }
            
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let searchType = searchOptions[self.selectedSearchType]
        let isFiltering = self.searchFiltering

        //        let cell = tableView.dequeueReusableCell(withIdentifier: EmojiCellId, for: indexPath) as! EmojiCell
        //        return cell
        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: EmojiCellId, for: indexPath) as! SearchResultsCell
        
    
//        cell.isSelected = false
        if searchType == SearchAll {
            if (isFiltering && self.filteredAllResults.count == 0) {
                return cell
            }
            
            let displayTerm = isFiltering ? self.filteredAllResults[indexPath.row] : self.defaultAllResults[indexPath.row]
            let displayType = allResultsDic[displayTerm] ?? ""
            
            if displayType == SearchEmojis {
                
                let emoji = self.displayEmojis.filter { (emoji) -> Bool in
                    emoji.name == displayTerm
                }
                let displayEmoji = emoji[0]
                cell.emoji = displayEmoji
                cell.postCount = (defaultEmojiCounts[displayEmoji.emoji] ?? 0) + (defaultEmojiCounts[displayEmoji.name!] ?? 0)
                cell.isSelected = (self.searchText?.contains(displayEmoji.emoji) ?? false) || (self.searchText?.contains(displayEmoji.name ?? "     ") ?? false)
                // USING "     " as default because search text won't have that much space
//                cell.isSelected = (isFiltering) ? (self.searchText?.contains((cell.emoji?.emoji)!))! : false
            }
                
            else if displayType == SearchPlace {
                
                cell.locationName = displayTerm
                cell.postCount = defaultPlaceCounts[displayTerm] ?? 0
                let googleId = locationGoogleIdDictionary[displayTerm]
                cell.isSelected = (displayTerm == self.viewFilter.filterLocationName) || googleId == self.viewFilter.filterGoogleLocationID
            }
                
            else if displayType == SearchCity {
                
                cell.locationName = displayTerm
                cell.postCount = defaultCityCounts[displayTerm] ?? 0
                cell.isSelected = (displayTerm == self.viewFilter.filterLocationSummaryID)
            }
                
            else if displayType == SearchUser {
                
                let user = self.allUsers.filter { (user) -> Bool in
                    user.username == displayTerm
                }
                cell.user = user[0]
                cell.isSelected = false
            }
            else
            {
                cell.isSelected = false
            }
            
            
//            cell.tempView.backgroundColor = cell.isSelected ? UIColor.mainBlue().withAlphaComponent(0.2) : UIColor.white

            return cell
            
        }
            
        else if searchType == SearchEmojis {
            let displayTerm = isFiltering ? self.filteredEmojis[indexPath.row] : self.displayEmojis[indexPath.row]
            cell.emoji = displayTerm
            cell.postCount = (defaultEmojiCounts[displayTerm.emoji] ?? 0) + (defaultEmojiCounts[displayTerm.name!] ?? 0)
//            cell.isSelected = (self.searchText != nil) ? (self.searchText?.contains((cell.emoji?.emoji)!))! : false
            cell.isSelected = (self.searchText?.contains(displayTerm.emoji) ?? false) || (self.searchText?.contains(displayTerm.name ?? "     ") ?? false)
//            cell.tempView.backgroundColor = cell.isSelected ? UIColor.mainBlue().withAlphaComponent(0.2) : UIColor.white

            return cell
        }
            
        else if searchType == SearchCity {
            let curLabel = isFiltering ? filteredCity[indexPath.row] : displayCity[indexPath.row]
            cell.locationName = curLabel
            cell.postCount = defaultCityCounts[curLabel] ?? 0
            cell.isSelected = (curLabel == self.viewFilter.filterLocationSummaryID)
//            cell.tempView.backgroundColor = cell.isSelected ? UIColor.mainBlue().withAlphaComponent(0.2) : UIColor.white

            return cell
        }
            
        else if searchType == SearchPlace {
            let curLabel = isFiltering ? filteredPlaces[indexPath.row] : displayPlaces[indexPath.row]
            cell.locationName = curLabel
            cell.postCount = defaultPlaceCounts[curLabel] ?? 0
            cell.isSelected = (curLabel == self.viewFilter.filterLocationName)
//            cell.tempView.backgroundColor = cell.isSelected ? UIColor.mainBlue().withAlphaComponent(0.2) : UIColor.white

            return cell
        }
            
        else if searchType == SearchUser {
            let displayUser = isFiltering ? filteredUsers[indexPath.row] : allUsers[indexPath.row]
            cell.user = displayUser
            cell.isSelected = false
//            cell.tempView.backgroundColor = cell.isSelected ? UIColor.mainBlue().withAlphaComponent(0.2) : UIColor.white

            return cell
        }
            
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: EmojiCellId, for: indexPath) as! SearchResultsCell
            return cell
        }
        
    }
    

    func setupTableView(){
        searchTableView.register(SearchResultsCell.self, forCellReuseIdentifier: EmojiCellId)
        searchTableView.register(UserAndListCell.self, forCellReuseIdentifier: UserCellId)
        searchTableView.register(LocationCell.self, forCellReuseIdentifier: LocationCellId)
        searchTableView.register(NewListCell.self, forCellReuseIdentifier: ListCellId)
        
        searchTableView.backgroundColor = UIColor.white
        searchTableView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        searchTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        searchTableView.rowHeight = UITableView.automaticDimension
        searchTableView.estimatedRowHeight = 160
        searchTableView.separatorStyle = .none
        
//        searchTableView.contentSize = CGSize(width: self.view.frame.size.width - 20, height: searchTableView.contentSize.height)
        setupSegments()
        searchTableView.tableHeaderView = searchTypeSegment
    }
    
    
    
    
    
    func setupSegments(){
        searchTypeSegment = UISegmentedControl(items: searchOptions)
        searchTypeSegment.selectedSegmentIndex = self.selectedSearchType
        searchTypeSegment.addTarget(self, action: #selector(selectSort), for: .valueChanged)
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        searchTypeSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont(name: "Poppins-Regular", size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
        searchTypeSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 15), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)

        
        searchTypeSegment.backgroundColor = .white
        searchTypeSegment.tintColor = .white
        
//        searchTypeSegment.addUnderlineForSelectedSegment()
        
        // This needs to be false since we are using auto layout constraints
        //        headerSortSegment.translatesAutoresizingMaskIntoConstraints = false
        //        buttonBar.translatesAutoresizingMaskIntoConstraints = false
        //        headerSortSegment.apportionsSegmentWidthsByContent = true
    }
    
    @objc func selectSort(sender: UISegmentedControl) {
        self.selectedSearchType = sender.selectedSegmentIndex
        self.searchTableView.reloadData()
        
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
 
    
    func initSearchSelections(){
        // SET DEFAULT PARAMETERS
        self.defaultEmojiCounts = self.noCaptionFilterTagCounts
        self.defaultPlaceCounts = self.noCaptionFilterTagCounts
        self.defaultCityCounts = self.noCaptionFilterTagCounts
        
        // EMOJIS
//        print("INPUT: ",allSearchEmojis)
//        print("DEFAULT: ",defaultEmojiCounts)
        Database.sortEmojisWithCounts(inputEmojis: allSearchEmojis, emojiCounts: defaultEmojiCounts, dictionaryMatch: false, sort: true) { (userEmojis) in
            
            
            // Output should not include the meal types
            var tempNonCuisineEmojis: [EmojiBasic] = userEmojis.filter { (emoji) -> Bool in
                return !cuisineEmojiSelect.contains(emoji.emoji)
            }
            
            let sortedEmojis = tempNonCuisineEmojis.sorted(by: { (p1, p2) -> Bool in
                p1.count > p2.count
            })
        
            
            self.displayEmojis = sortedEmojis
            self.filteredEmojis = sortedEmojis
//            print("DISPLAY: ",sortedEmojis)

        }
        
        // USERS
        //            for x in allUsers {
        //                allResults[x.username.lowercased()] = SearchUser
        //            }
        
        // PLACES
        var tempPlace: [String] = []
        
        let tempPlaceCounts = defaultPlaceCounts.sorted { (val1, val2) -> Bool in
            return val1.value > val2.value
        }
        
        for (y,value) in tempPlaceCounts {
            tempPlace.append(y)
        }
        
        self.displayPlaces = tempPlace
        self.filteredPlaces = tempPlace
        
        // CITY
        var tempLocation: [String] = []
        let tempCounts = defaultCityCounts.sorted { (val1, val2) -> Bool in
            return val1.value > val2.value
        }
        
        for (y,value) in tempCounts {
            tempLocation.append(y)
        }
        
        self.displayCity = tempLocation
        self.filteredCity = tempLocation
        

        // ALL RESULT OPTIONS
        allResultsDic = [:]
        defaultAllResults = []

    // ADDING TOP 10 TO ALL RESULTS
        for (index, a) in self.displayEmojis.enumerated() {
            if let name = a.name {
                allResultsDic[name] = SearchEmojis
                
            // ADD TOP 10 EMOJIS TO ALL RESULTS
                if index <= 10 {
                    defaultAllResults.append(name)
                }
            }
        }
        
        for (index, b) in self.displayPlaces.enumerated() {
            allResultsDic[b] = SearchPlace
            
            if index <= 10 {
                defaultAllResults.append(b)
            }
        }
        
        for (index, b) in self.displayCity.enumerated() {
            allResultsDic[b] = SearchCity
            
            if index <= 10 {
                defaultAllResults.append(b)
            }
        }
        
        
        // ALL RESULTS - Emoji Name, Location Name, User Name
        for (key,value) in allResultsDic {
            self.aggregateAllResults.append(key)
        }
        
        // DEFAULT ALL RESULTS - Show top 10 of all Results
        print("Set Selections | \(self.displayEmojis.count) Emojis | \(self.displayPlaces.count) Locations")
        self.searchTableView.reloadData()
        
        
    }
    
    
        func filterContentForSearchText(_ searchText: String) {
//            self.tempSearchBarText = searchText
//            var fetchedPosts: [Post] = []
//            print("filterContentForSearchText | \(searchText)")
//
//            Database.fetchAllPosts(fetchedPostIds: self.fetchedPostIds, completion: { (firebaseFetchedPosts) in
//                self.displayedPosts = firebaseFetchedPosts
////                self.filterSortFetchedPosts()
//
//                    Database.sortPosts(inputPosts: self.displayedPosts, selectedSort: self.viewFilter.filterSort, selectedLocation: self.viewFilter.filterLocation, completion: { (sortedPosts) in
//                        fetchedPosts = sortedPosts ?? []
//
//                    let tempFilter = self.viewFilter.copy() as! Filter
//                        var isFiltering = self.viewFilter.isFiltering
//
//                     if let searchText = self.tempSearchBarText {
//                         tempFilter.filterCaptionArray.append(searchText)
//                        if !searchText.isEmptyOrWhitespace() {
//                            isFiltering = true
//                        }
//                     }
//
//
//                        Database.filterPostsNew(inputPosts: fetchedPosts, postFilter: tempFilter) { (filteredPosts) in
//
//                            self.displayedPosts = filteredPosts ?? []
//
//                            print("  ~ FINISH | filterContentForSearchText | Post \(filteredPosts?.count) Posts | Pre \(fetchedPosts.count) | \(self.fetchUser?.username) | \(tempFilter.filterCaptionArray)")
//                            if (filteredPosts?.count ?? 0) > 0 {
//                                let temp = filteredPosts![0] as Post
//                                print(temp.locationName)
//                            }
//
//                            self.isFinishedPaging = false
//                            self.paginatePostsCount = min(10, self.displayedPosts.count)
////                            self.collectionView.reloadSections(IndexSet(integer: 0))
//                            DispatchQueue.main.async(execute: {
//                                self.collectionView.reloadData()
//                                 })
////                            self.refreshPagination()
////                            self.paginatePosts()
//
////                            self.collectionView.reloadSections(IndexSet(integer: 1))
//            //
//            //                self.refreshPagination()
//            //                self.paginatePosts()
//            //                self.imageCollectionView.reloadSections(IndexSet(integer: 1))
//
//                        }
//                    })
            
//
//            })
//            
            
            
            


        }
    
//    func filterContentForSearchText(_ searchText: String) {
//
//        let searchCaption = searchText.emojilessString.lowercased()
//        let searchCaptionArray = searchText.emojilessString.lowercased().components(separatedBy: " ")
//        let searchCaptionEmojis = searchText.emojis
//        var lastWord = searchCaptionArray[searchCaptionArray.endIndex - 1]
//
//        if searchCaption == "" {
//            filteredAllResults = aggregateAllResults
//            filteredEmojis = displayEmojis
//            filteredUsers = allUsers
//            filteredPlaces = displayPlaces
//            filteredCity = displayCity
//            self.searchFiltering = false
//
//        } else {
//            self.searchFiltering = true
//
//            if SearchBarOptions[self.selectedSearchType] == SearchAll {
//
//                filteredAllResults = aggregateAllResults.filter { (option) -> Bool in
//                    return option.lowercased().contains(searchCaption) || searchCaptionArray.contains(option.lowercased()) || searchCaptionEmojis.contains(option)
//                }
//
//                if searchCaption.removingWhitespaces() == "" {
//                    filteredAllResults += (self.defaultAllResults)
//                }
//
//
//                filteredAllResults.sort { (p1, p2) -> Bool in
//
//                    let p1Type = allResultsDic[p1] ?? ""
//                    let p2Type = allResultsDic[p2] ?? ""
//
//                // SORT BY EMOJI, PLACE, CITY
//                    if allResultsDic[p1] != allResultsDic[p2] {
//                        let p1TypeInd = SearchBarTypeIndex[p1Type] ?? 999
//                        let p2TypeInd = SearchBarTypeIndex[p2Type] ?? 999
//
//                        return p1TypeInd < p2TypeInd
//                    }
//
//                // SORT BY POST COUNT
//                    else
//                    {
//
//                        var p1Count = 0
//                        var p2Count = 0
//
//                        if p1Type == SearchEmojis {
//                            p1Count = defaultEmojiCounts[p1] ?? 0
//                        } else if p1Type == SearchPlace {
//                            p1Count = defaultPlaceCounts[p1] ?? 0
//                        }  else if p1Type == SearchCity {
//                            p1Count = defaultCityCounts[p1] ?? 0
//                        } else {
//                            p1Count = 0
//                        }
//
//                        if p2Type == SearchEmojis {
//                            p2Count = defaultEmojiCounts[p2] ?? 0
//                        } else if p2Type == SearchPlace {
//                            p2Count = defaultPlaceCounts[p2] ?? 0
//                        }  else if p2Type == SearchCity {
//                            p2Count = defaultCityCounts[p2] ?? 0
//                        } else {
//                            p2Count = 0
//                        }
//
//                        return p1Count > p2Count
//                    }
//                }
//
//                // REMOVE DUPS
//                var tempResults: [String] = []
//                for x in filteredAllResults {
//                    if !tempResults.contains(x) {
//                        tempResults.append(x)
//                    }
//                }
//                filteredAllResults = tempResults
//                print("FilterContentResults | \(searchText) | \(filteredAllResults.count) Filtered All | \(defaultAllResults.count) All")
//
//            }
//
//            else if SearchBarOptions[self.selectedSearchType] == SearchEmojis {
//                // Filter Food
//                if searchCaption.removingWhitespaces() == "" {
//                    filteredEmojis = displayEmojis
//                    self.searchTableView.reloadData()
//                    return
//                } else {
//                    filteredEmojis = displayEmojis.filter({( emoji : Emoji) -> Bool in
//                        return searchCaptionArray.contains(emoji.name!) || searchCaptionEmojis.contains(emoji.emoji) || (emoji.name?.contains(lastWord))!})
//                }
//
//                filteredEmojis.sort { (p1, p2) -> Bool in
//                    let p1Ind = ((p1.name?.hasPrefix(lastWord.lowercased()))! ? 0 : 1)
//                    let p2Ind = ((p2.name?.hasPrefix(lastWord.lowercased()))! ? 0 : 1)
//                    if p1Ind != p2Ind {
//                        return p1Ind < p2Ind
//                    } else {
//                        return p1.count > p2.count
//                    }
//                }
//
//                // REMOVE DUPS
//                var tempResults: [Emoji] = []
//
//                for x in filteredEmojis {
//                    if !tempResults.contains(where: { (emoji) -> Bool in
//                        return emoji.name == x.name
//                    }){
//                        tempResults.append(x)
//                    }
//                }
//
//                filteredEmojis = tempResults
//                print("FilterContentResults | \(searchText) | \(filteredEmojis.count) Filtered Emojis | \(displayEmojis.count) Emojis")
//
//            }
//
//            else if SearchBarOptions[self.selectedSearchType] == SearchUser {
//                if searchCaption.removingWhitespaces() == "" {
//                    filteredUsers = allUsers
//                    self.searchTableView.reloadData()
//                    return
//
//                } else {
//                    filteredUsers = allUsers.filter({ (user) -> Bool in
//                        return user.username.lowercased().contains(searchCaption.lowercased())
//                    })
//                }
//
//
//                filteredUsers.sort { (p1, p2) -> Bool in
//                    let p1Ind = ((p1.username.hasPrefix(searchCaption.lowercased())) ? 0 : 1)
//                    let p2Ind = ((p2.username.hasPrefix(searchCaption.lowercased())) ? 0 : 1)
//                    if p1Ind != p2Ind {
//                        return p1Ind < p2Ind
//                    } else {
//                        return p1.posts_created > p2.posts_created
//                    }
//                }
//
//                // REMOVE DUPS
//                var tempResults: [User] = []
//
//                for x in filteredUsers {
//                    if !tempResults.contains(where: { (user) -> Bool in
//                        return user.username == x.username
//                    }){
//                        tempResults.append(x)
//                    }
//                }
//                filteredUsers = tempResults
//                print("FilterContentResults | \(searchText) | \(filteredUsers.count) Filtered Users | \(allUsers.count) Users")
//
//            }
//
//            else if SearchBarOptions[self.selectedSearchType] == SearchPlace {
//                if searchCaption.removingWhitespaces() == "" {
//                    filteredPlaces = displayPlaces
//                    self.searchTableView.reloadData()
//                    return
//                } else {
//                    filteredPlaces = displayPlaces.filter({ (string) -> Bool in
//                        return string.lowercased().contains(searchCaption.lowercased())
//                    })
//                }
//
//
//
//                filteredPlaces.sort { (p1, p2) -> Bool in
//                    let p1Ind = ((p1.hasPrefix(searchCaption.lowercased())) ? 0 : 1)
//                    let p2Ind = ((p2.hasPrefix(searchCaption.lowercased())) ? 0 : 1)
//                    if p1Ind != p2Ind {
//                        return p1Ind < p2Ind
//                    } else {
//                        return p1.count > p2.count
//                    }
//                }
//
//                // REMOVE DUPS
//                var tempResults: [String] = []
//
//                for x in filteredPlaces {
//                    if !tempResults.contains(x) {
//                        tempResults.append(x)
//                    }
//                }
//                filteredPlaces = tempResults
//                print("FilterContentResults | \(searchText) | \(filteredPlaces.count) Filtered Locations | \(displayPlaces.count) Locations")
//            }
//        }
//        self.searchTableView.reloadData()
//
//    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.backgroundColor = UIColor.mainBlue().withAlphaComponent(0.2)
        
        let searchType = searchOptions[self.selectedSearchType]
        let isFiltering = self.searchFiltering
        
        if singleSelection {
            self.searchText = nil
            self.selectedPlace = nil
            self.searchUser = nil
            self.selectedCity = nil
        }
        
        
        if searchType == SearchAll {
            let displayTerm = isFiltering ? self.filteredAllResults[indexPath.row] : self.defaultAllResults[indexPath.row]
            let displayType = allResultsDic[displayTerm] ?? ""
            
            if displayType == SearchEmojis {
                let emoji = self.displayEmojis.filter { (emoji) -> Bool in
                    emoji.name == displayTerm
                }
                self.addEmojiToSearchTerm(inputEmoji: emoji[0])
            }
            else if displayType == SearchPlace {
                self.selectedPlace = displayTerm
            }
            else if displayType == SearchUser {
                let user = self.allUsers.filter { (user) -> Bool in
                    user.username == displayTerm
                }
                self.searchUser = user[0]
            }
            
            self.handleFilter()
            
        }
            
        else if searchType == SearchEmojis {
            let displayTerm = isFiltering ? self.filteredEmojis[indexPath.row] : self.displayEmojis[indexPath.row]
            let displayEmoji = displayTerm.emoji
            
            self.addEmojiToSearchTerm(inputEmoji: displayTerm)
            self.handleFilter()
            
            //            self.searchText = displayTerm.emoji
            
        }
            
        else if searchType == SearchPlace {
            let curLabel = isFiltering ? filteredPlaces[indexPath.row] : displayPlaces[indexPath.row]
            self.selectedPlace = curLabel
            self.handleFilter()
            
        }
            
        else if searchType == SearchCity {
            let curLabel = isFiltering ? filteredCity[indexPath.row] : displayCity[indexPath.row]
            self.selectedCity = curLabel
            self.handleFilter()
            
        }
            
        else if searchType == SearchUser {
            let displayUser = isFiltering ? filteredUsers[indexPath.row] : allUsers[indexPath.row]
            self.searchUser = displayUser
            self.handleFilter()
            
            //            let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
            //            userProfileController.displayUserId = displayUser.uid
            //            self.navigationController?.pushViewController(userProfileController, animated: true)
            
        }
    }
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text?.lowercased() else {
            self.handleRefresh()
            print("Search Bar Empty | Refresh")
            return
        }
        
        self.searchText = text
        self.handleFilter()

    }
    
    
    func addEmojiToSearchTerm(inputEmoji: EmojiBasic?) {
        self.searchText = inputEmoji?.emoji
    }
    
    func handleFilter(){
        
        self.viewFilter.clearFilter()
        self.viewFilter.filterCaption = self.searchText
        self.viewFilter.filterUser = self.searchUser
        
        if let loc = selectedPlace {
            if let _ = self.noCaptionFilterTagCounts[loc] {
                if let googleId = locationGoogleIdDictionary[loc] {
                    self.viewFilter.filterGoogleLocationID = googleId
                    print("Filter by GoogleLocationID | \(googleId)")
                } else {
                    self.viewFilter.filterLocationName = loc
                    print("Filter by Location Name , No Google ID | \(loc)")
                }
            }
        }
        
        self.viewFilter.filterLocationSummaryID = self.selectedCity


//        self.viewFilter.filterLocationSummaryID = selectedLocation
        self.view.endEditing(true)
        self.hideSearchView()
        self.hideSearchBar = true
        self.refreshPostsForSearch()
    }
    
    func filterControllerSelected(filter: Filter?) {
        print("LegitHomeView | Received Filter | \(filter)")
        guard let filter = filter else {return}
        self.viewFilter = filter
        self.refreshPostsForSearch()
        
        
//        self.viewFilter.clearFilter()
//        self.viewFilter.filterCaption = filter?.filterCaption
//
//        if let loc = filter?.filterLocationName {
//            if let _ = self.noCaptionFilterPlaceCounts[loc] {
//                if let googleId = locationGoogleIdDictionary[loc] {
//                    self.viewFilter.filterGoogleLocationID = googleId
//                    print("Filter by GoogleLocationID | \(googleId)")
//                } else {
//                    self.viewFilter.filterLocationName = loc
//                    print("Filter by Location Name , No Google ID | \(loc)")
//                }
//            }
//        }
//
//        self.viewFilter.filterLocationSummaryID = filter?.filterLocationSummaryID


    }

    func refreshAll() {
        self.handleRefresh()
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
    
    
}




