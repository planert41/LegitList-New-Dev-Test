//
//  LegitListViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/21/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit
import EmptyDataSet_Swift

import SVProgressHUD
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth
import SKPhotoBrowser


class SingleListViewController: UIViewController {

    var delegate: LegitListViewControllerDelegate?
    
    // MARK: - LIST/POST Objects
    var browser = SKPhotoBrowser()


    // INPUT - SOURCE
    var inputDisplayListId: String? = nil {
        didSet {
            guard let inputDisplayListId = inputDisplayListId else {
                print("Error No Input List ID")
                return
            }
            
            if self.currentDisplayList?.id != self.inputDisplayListId{
                print("Current Display List Not Match inputDisplayListID. Fetching List: \(self.inputDisplayListId)")
                Database.fetchListforSingleListId(listId: inputDisplayListId) { (fetchedList) in
                    self.currentDisplayList = fetchedList
                }
            }
        }
    }
    
    // INPUT - SOURCE
    var currentDisplayList: List? = nil {
        didSet{
            print(" LegitListCollectionView | DISPLAYING | \(currentDisplayList?.name) | \(currentDisplayList?.id) | \(currentDisplayList?.postIds?.count) Posts |List_ViewController")

            fetchPostsForList()
            if displayUser?.uid != currentDisplayList?.creatorUID{
                print("Fetching \(currentDisplayList?.creatorUID) for List \(currentDisplayList?.name): \(currentDisplayList?.id)")
                fetchUserForList()
            }

            self.tempRank = currentDisplayList?.listRanks
//            self.heroImageUrl = currentDisplayList?.heroImageUrl
            //            print("currentDisplayList | Set Temp Rank | \(self.tempRank?.count)")

        }
    }
    
    // Used to fetch lists
    var displayUser: User? = nil {
        didSet{
            print("NewListCollectionView | Current display user: \(displayUser?.username) | \(displayUser?.uid)")
//            self.setupUser()
        }
    }
    
    var bottomSortBar = BottomSortBar()


    //DISPLAY VARIABLES
    var fetchedPosts: [Post] = []
    var displayedPosts: [Post] = []
    var tempRank:[String:Int]? = [:]
    
    var postFormatInd: Int = 0
    // 0 Grid View
    // 1 List View
    // 2 Full View

    // MARK: - FILTERS

    let searchViewController = LegitSearchViewControllerNew()

    var viewFilter: Filter = Filter.init(defaultSort: defaultRecentSort) {
        didSet {
            if (self.viewFilter.isFiltering) {
                let currentFilter = self.viewFilter
                var searchTerm: String = ""
                
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
                
                if (currentFilter.filterLegit) {
                    searchTerm.append("Legit | ")
                }
                
                if currentFilter.filterMinRating != 0 {
                    searchTerm.append("\((currentFilter.filterMinRating)) Stars | ")
                }
//                self.isFilteringText = searchTerm
            } else {
//                self.isFilteringText = nil
            }
            //        self.refreshPostsForFilter()
        }
    }
    var isFiltering: Bool = false

    
    // MARK: - Collection View Objects


    let gridCellId = "gridCellId"
    let listCellId = "listCellId"
    let listHeaderId = "listHeaderId"
    let emptyHeaderId = "emptyHeaderId"
    let testCellId = "testCellId"
    let testListCellId = "testListCellId"

    var showEmpty = false

    lazy var imageCollectionView : UICollectionView = {
        let layout = ListViewFlowLayout()
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 5
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: HomeSortFilterHeaderFlowLayout())
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = .white
        return cv
    }()

    var displayBack: Bool = false {
        didSet {
            setupNavigationItems()
        }
    }
    
    // NAV BUTTONS
    lazy var navBackButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 70, height: 30))
        let icon = #imageLiteral(resourceName: "back_icon").withRenderingMode(.alwaysTemplate)
        button.setImage(icon, for: .normal)
        button.layer.backgroundColor = UIColor.ianWhiteColor().cgColor
        button.layer.borderColor = UIColor.ianLegitColor().cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 2
        button.clipsToBounds = true
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        button.tintColor = UIColor.ianBlackColor()
        button.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
        let navShareTitle = NSAttributedString(string: " BACK ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 12)])
        button.setAttributedTitle(navShareTitle, for: .normal)
        return button
    }()
    
    
    
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
    
//    lazy var navBackButton: UIButton = {
//        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//        let icon = #imageLiteral(resourceName: "back_icon").withRenderingMode(.alwaysTemplate)
//
//        button.setImage(icon, for: .normal)
//        button.layer.backgroundColor = UIColor.white.cgColor
//        button.layer.borderColor = UIColor.ianLegitColor().cgColor
//        button.layer.borderWidth = 0
//        button.layer.cornerRadius = 2
//        button.clipsToBounds = true
//        button.contentHorizontalAlignment = .center
//        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
//        button.tintColor = UIColor.ianBlackColor()
//        button.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
//        return button
//    }()
    
    func setupNavigationItems(){
        self.navigationController?.isNavigationBarHidden = !displayBack
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.barTintColor = UIColor.clear
        self.navigationController?.navigationBar.tintColor = UIColor.clear
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        self.setNeedsStatusBarAppearanceUpdate()

//        // Nav Back Button
//        navBackButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
//        let backButton = UIBarButtonItem.init(customView: navBackButton)
//        
//        if displayBack {
//            self.navigationItem.leftBarButtonItem = backButton
//        } else {
//            self.navigationItem.leftBarButtonItem = UIBarButtonItem()
//        }
//        
        
//        navBackButton.addTarget(self, action: #selector(handleBackPressNav), for: .touchUpInside)
        
//        let barButton2 = UIBarButtonItem.init(customView: navBackButton)
//        self.navigationItem.leftBarButtonItem = barButton2
    }
    
    @objc func handleBackPressNav(){
        self.handleBack()
    }

    
    override func viewWillAppear(_ animated: Bool) {
        self.setupNavigationItems()
    }
    
    // MARK: - VIEWDIDLOAD

    let headerHeight = 100 + 40 + 40 + 40 + 30 + 30 + 30 + UIApplication.shared.statusBarFrame.height
    
    // BOTTOM EMOJI BAR
    let bottomEmojiBar = BottomEmojiBar()
    var bottomEmojiBarHide: NSLayoutConstraint?
    var bottomEmojiBarHeight: CGFloat = 50
    
    var first100EmojiCounts: [String:Int] = [:]

    var noFilterTagCounts: PostTagCounts = PostTagCounts.init()
    var currentPostTagCounts: PostTagCounts = PostTagCounts.init()
    var currentPostRatingCounts = RatingCountArray

    var noCaptionFilterTagCounts: [String:Int] = [:]
    var currentPostsFilterTagCounts: [String:Int] = [:]

    var searchUserText: String? = nil
    var searchUser: User? = nil
    var searchText: String? = nil
    var selectedCity: String? = nil
    var selectedPlace: String? = nil
    
    var tempSearchBarText: String? = nil

    let postSortFormatBar = PostSortFormatBar()
    
    
    @objc func listDeleted(_ notification: NSNotification) {

         if let listId = notification.userInfo?["deleteListId"] as? String {
            if self.currentDisplayList?.id == listId {
                print("ListDeleted \(listId) \(self.currentDisplayList?.name)| Exiting Single List View")
                self.handleBackPressNav()
            }
         }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        print("  START |  NewListCollectionView | ViewdidLoad")
        NotificationCenter.default.addObserver(self, selector: #selector(self.listDeleted(_:)), name: MainTabBarController.deleteList, object: nil)
        
        self.setupNavigationItems()
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(locationDenied), name: AppDelegate.LocationDeniedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(locationUpdated), name: AppDelegate.LocationUpdatedNotificationName, object: nil)

        self.edgesForExtendedLayout = UIRectEdge.top
        setupNavigationItems()
        setupCollectionView()
        
        
//        self.view.addSubview(bottomEmojiBar)
//        bottomEmojiBar.delegate = self
//        bottomEmojiBar.anchor(top: nil, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: bottomEmojiBarHeight)
//        bottomEmojiBar.layer.applySketchShadow(
//        color: UIColor.rgb(red: 0, green: 0, blue: 0),
//        alpha: 0.1,
//        x: 0,
//        y: 0,
//        blur: 10,
//        spread: 0)
//
//        bottomEmojiBarHide = bottomEmojiBar.heightAnchor.constraint(equalToConstant: 0)
//        bottomEmojiBarHide?.isActive = true
//        refreshBottomEmojiBar()
        
        view.addSubview(bottomSortBar)
        bottomSortBar.anchor(top: nil, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        bottomSortBar.delegate = self
        bottomSortBar.selectSort(sort: self.viewFilter.filterSort ?? HeaderSortDefault)
        
        
        self.view.addSubview(imageCollectionView)
        imageCollectionView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: bottomSortBar.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: ListViewController.refreshListViewNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.postEdited(_:)), name: AppDelegate.refreshPostNotificationName, object: nil)
//
//        postSortFormatBar.delegate = self
//        self.view.addSubview(postSortFormatBar)
//        postSortFormatBar.anchor(top: nil, left: view.leftAnchor, bottom: imageCollectionView.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 0, height: 40)
////        postSortFormatBar.navGridToggleButton.isHidden = true
//        postSortFormatBar.navMapButton.isHidden = false
//        postSortFormatBar.navMapButton.setTitle(" Map List", for: .normal)
//        postSortFormatBar.navMapButtonWidth?.constant = 120
        
//        self.view.addSubview(navMapButton)
//        navMapButton.anchor(top: nil, left: postSortFormatBar.rightAnchor, bottom: imageCollectionView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 10, paddingRight: 15, width: 120, height: 40)
//
//        navMapButton.layer.cornerRadius = 30/2
//        navMapButton.layer.masksToBounds = true
//        navMapButton.clipsToBounds = true
//        navMapButton.addTarget(self, action: #selector(toggleMapFunction), for: .touchUpInside)
//        navMapButton.isHidden = true
        
        navBackButton.addTarget(self, action: #selector(handleBackPressNav), for: .touchUpInside)
        self.view.addSubview(navBackButton)
        navBackButton.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: UIApplication.shared.statusBarFrame.height + 10, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 70, height: 30)

        
        self.view.addSubview(searchViewController.view)
        searchViewController.view.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        searchViewController.view.alpha = 0
        setupSearchView()
        
        print("  END |  NewListCollectionView | ViewdidLoad")
        
        
        // Do any additional setup after loading the view.
    }
    
//    func keyboardWillShow(notification:NSNotification){
//        //give room at the bottom of the scroll view, so it doesn't cover up anything the user needs to tap
//        var userInfo = notification.userInfo!
//        var keyboardFrame:CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
//        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
//
//        var contentInset:UIEdgeInsets = self.imageCollectionView.contentInset
//        contentInset.bottom = keyboardFrame.size.height + 20
//        imageCollectionView.contentInset = contentInset
//    }
//
//    func keyboardWillHide(notification:NSNotification){
//        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
//        imageCollectionView.contentInset = contentInset
//    }
    
    
    // MARK: - FETCHING OBJECTS
    func fetchUserForList(){
        guard let currentDisplayList = self.currentDisplayList else {
            print("Fetch User For List: Error, No Display List")
            return
        }
        
        Database.fetchUserWithUID(uid: (currentDisplayList.creatorUID)!) { (fetchedUser) in
            self.displayUser = fetchedUser
        }
    }
    
    
    func updateNoFilterCounts(){
        Database.summarizePostTags(posts: self.displayedPosts) { (tagCounts) in
            self.currentPostTagCounts = tagCounts
            self.currentPostsFilterTagCounts = tagCounts.allCounts
            if !self.viewFilter.isFiltering && !self.isFiltering {
                self.noCaptionFilterTagCounts = tagCounts.allCounts
                self.noFilterTagCounts = tagCounts
            }
//            print("   SingleListViewController | NoFilter Emoji Count | \(tagCounts) | \(self.displayedPosts.count) Posts")
            self.refreshBottomEmojiBar()
        }
        
        let first100 = Array(self.displayedPosts.prefix(100))
        Database.countEmojis(posts: first100, onlyEmojis: true) { (emojiCounts) in
            self.first100EmojiCounts = emojiCounts
            print("   SingleListViewController | NoFilter Emoji Count | \(emojiCounts.count) | \(first100.count) Posts")
            self.refreshBottomEmojiBar()
        }
        
        Database.summarizeRatings(posts: self.displayedPosts) { (ratingCounts) in
            self.currentPostRatingCounts = ratingCounts
        }
    }
    
    var isFetchingPost = false
    
    func fetchPostsForList(){
        guard let displayListId = currentDisplayList?.id else {
            print("Fetch Post for List: ERROR, No List or ListId")
            return
        }
        
        print("    START | fetchPostsForList | NewListCollectionView")
        
        if isFetchingPost {
            print("  ~ BUSY | fetchPostsForList | \(displayListId) | Fetching: \(isFetchingPost)")
            return
        } else {
            isFetchingPost = true
        }
        
        // LOAD IN TEMP RANK
        let tempList = self.currentDisplayList
        if let tempRank = self.tempRank{
            tempList?.listRanks = self.tempRank!
        }
        
        Database.fetchPostFromList(list: tempList, completion: { (fetchedPosts) in
            print(" SUCCESS | Fetch Post for List |, \(displayListId):\(self.currentDisplayList?.name), Count: \(fetchedPosts?.count) Posts")
            
            // READ IN RANKS FROM LIST
            var tempPosts: [Post] = []
            if let tempRank = self.tempRank {
                for post in fetchedPosts ?? [] {
                    var tempPost = post
                    tempPost.listedRank = tempRank[post.id!]
                    tempPosts.append(post)
                }
                self.fetchedPosts = tempPosts
            }
            
            
            Database.countMostUsedEmojis(posts: self.fetchedPosts, completion: { (mostUsedEmojis) in
                let tempEmojis = Array(mostUsedEmojis.prefix(4))
                
                var updateEmoji = false
                
                for emoji in tempEmojis {
                    if !(self.currentDisplayList?.topEmojis.contains(emoji))! {
                        updateEmoji = true
                    }
                }
                
                if updateEmoji && self.currentDisplayList?.topEmojis != tempEmojis {
                    print("ListViewController | Fetched Posts For List | Emoji Check | Updating Emojis | \(self.currentDisplayList?.id) : \(tempEmojis) | OLD \(self.currentDisplayList?.topEmojis)")
                    Database.updateSocialCountForList(listId: self.currentDisplayList?.id, credCount: nil, emojis: tempEmojis)
                    self.currentDisplayList?.topEmojis = tempEmojis
                    listCache[(self.currentDisplayList?.id)!] = self.currentDisplayList
                }
                
            })
            
//            self.updateNoFilterCounts()
            
            self.filterSortFetchedPosts()
            self.isFetchingPost = false
            
        })
    }
       
       func filterSortFetchedPosts(){
           
           self.isFiltering = self.viewFilter.isFiltering

           // Sort Recent Post By Listed Date
           var listSort: String = sortListed
            if self.viewFilter.filterSort == defaultRecentSort && !(self.currentDisplayList?.isRatingList ?? false){
               listSort = sortListed
           } else {
               listSort = (self.viewFilter.filterSort)!
           }
           

        Database.checkLocationForSort(filter: self.viewFilter) {
            Database.sortPosts(inputPosts: self.fetchedPosts, selectedSort: listSort, selectedLocation: self.viewFilter.filterLocation, completion: { (sortedPosts) in
                self.fetchedPosts = sortedPosts ?? []

             Database.filterPostsNew(inputPosts: self.fetchedPosts, postFilter: self.viewFilter) { (filteredPosts) in
                    
                    self.displayedPosts = filteredPosts ?? []
                    print("  ~ FINISH | Filter and Sorting Post | \(filteredPosts?.count) Posts | \(self.currentDisplayList?.name) - \(self.currentDisplayList?.id)")
                 
                     self.updateNoFilterCounts()
                    if self.imageCollectionView.isDescendant(of: self.view) {
                        self.imageCollectionView.reloadData()
                    }
                }
            })
        }

       }
    
    
    // MARK: - REFRESH

 @objc func handleRefresh(){
     print("ListViewController | Refresh List | \(self.currentDisplayList?.name)")
     self.refreshList()
     self.clearAllPost()
     self.clearFilter()
     //        self.collectionView.reloadData()
     self.fetchPostsForList()
     self.imageCollectionView.refreshControl?.endRefreshing()
 }
 
    
    @objc func refreshPostsForSort(){
        self.filterSortFetchedPosts()
    }
    
    @objc func locationUpdated() {
        if self.isPresented  {
            if self.viewFilter.filterSort == sortNearest {
                self.viewFilter.filterLocation = CurrentUser.currentLocation
                print("SingleListViewController Location UPDATED | \(CurrentUser.currentLocation)")
                self.refreshPostsForSort()
            }
        }
    }
    
    @objc func locationDenied() {
        if self.isPresented {
            self.missingLocAlert()
            self.postSortFormatBar.sortSegmentControl.selectedSegmentIndex = HeaderSortOptions.index(of: sortNew) ?? 0
            self.viewFilter.filterSort = sortNew
            self.headerSortSelected(sort: sortNew)
            print("SingleListViewController Location Denied Function")
        }
    }
    
    
    @objc func refreshPostsForFilter(){
        self.clearAllPost()
        self.fetchPostsForList()
        self.refreshBottomEmojiBar()
        self.imageCollectionView.refreshControl?.endRefreshing()
    }
    
    func refreshList(){
        
        guard let listId = self.currentDisplayList?.id else {return}
        
        Database.fetchListforSingleListId(listId: listId) { (fetchedList) in
            self.currentDisplayList = fetchedList
        }
        
    }
    
    
    func clearFilter(){
        self.viewFilter.clearFilter()
        self.tempSearchBarText = nil
    }
    
    func clearAllPost(){
        self.fetchedPosts = []
        self.displayedPosts = []
    }
    

    
 

}

// MARK: - COLLECTION VIEW DELEGATE

extension SingleListViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDragDelegate, UICollectionViewDropDelegate, UICollectionViewDelegateFlowLayout {
    
    
    func switchCollectionView(){
        let layout = ListViewFlowLayout()
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 5
//        layout.scrollDirection =  (self.postFormatInd == 0) ? .vertical : .horizontal
        layout.scrollDirection = .vertical

        layout.sectionHeadersPinToVisibleBounds = (self.postFormatInd == 0) ? false : true
        imageCollectionView.collectionViewLayout = layout
        imageCollectionView.collectionViewLayout.invalidateLayout()
        imageCollectionView.layoutIfNeeded()
        imageCollectionView.reloadData()
    }
    

    func setupCollectionView(){
        
        let layout: UICollectionViewFlowLayout = HomeSortFilterHeaderFlowLayout()
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 0
        imageCollectionView.collectionViewLayout = layout
        
        imageCollectionView.register(FullPictureCell.self, forCellWithReuseIdentifier: listCellId)
        imageCollectionView.register(ListGridCell.self, forCellWithReuseIdentifier: gridCellId)
//        imageCollectionView.register(NewListViewControllerHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: listHeaderId)
//        imageCollectionView.register(LegitListViewHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: listHeaderId)
        imageCollectionView.register(SingleListViewHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: listHeaderId)
        imageCollectionView.register(EmptyCell.self, forCellWithReuseIdentifier: emptyHeaderId)
        imageCollectionView.register(TestHomePhotoCell.self, forCellWithReuseIdentifier: testCellId)
        imageCollectionView.register(PostForListCell.self, forCellWithReuseIdentifier: testListCellId)
        imageCollectionView.allowsSelection = false
        
        
        
        
        var topMargin = CGFloat((self.navigationController?.navigationBar.frame.size.height) ?? 0)
        topMargin += UIApplication.shared.statusBarFrame.height ?? 0
  
        // if you want full screen collectionview
//        imageCollectionView.contentInset = UIEdgeInsets(top: -UIApplication.shared.statusBarFrame.height, left: 0, bottom: 0, right: 0)

//        imageCollectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        imageCollectionView.contentInset = UIEdgeInsets(top: -UIApplication.shared.statusBarFrame.height, left: 0, bottom: 0, right: 0)

        imageCollectionView.backgroundColor =  UIColor.backgroundGrayColor()
        imageCollectionView.translatesAutoresizingMaskIntoConstraints = true
//        let layout: UICollectionViewFlowLayout = HomeSortFilterHeaderFlowLayout()

        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        imageCollectionView.refreshControl = refreshControl
        imageCollectionView.bounces = true
        imageCollectionView.alwaysBounceVertical = true
        imageCollectionView.keyboardDismissMode = .onDrag
        
        // Adding Empty Data Set
        imageCollectionView.emptyDataSetSource = self
        imageCollectionView.emptyDataSetDelegate = self
        imageCollectionView.emptyDataSetView { (emptyview) in
            emptyview.isUserInteractionEnabled = false
        }
        // Drag and Drop Functions
        imageCollectionView.dragInteractionEnabled = true
        imageCollectionView.dragDelegate = self
        imageCollectionView.dropDelegate = self
        imageCollectionView.reorderingCadence = .fast
    }
        
        func scrollToHeader(){
            if let header = imageCollectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? LegitListViewHeader {

                let curOffset  = self.imageCollectionView.contentOffset
                let maxY = (self.imageCollectionView.convert(header.frame, to: self.view).maxY)

                let yOffset = (header.frame.height) - maxY

                self.imageCollectionView.setContentOffset(CGPoint(x: 0, y: curOffset.y - yOffset), animated: true)
    //            print(header.frame.maxY)
    //            print("CONVERT | \(fra)")
            }
        }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return self.postFormatInd == 1 ? 0 : 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
            return self.postFormatInd == 1 ? 0 : 10
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 15, bottom: 0, right: 15)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if indexPath.section == 1 {
            if self.showEmpty /*&& self.isFiltering*/
            {
                return CGSize(width: view.frame.width - 50, height: view.frame.width - 50)
            }
            else if self.postFormatInd == 0
            {
//                var height: CGFloat = 35 //headerview = username userprofileimageview
//                height += view.frame.width  // Picture
//                height += 160
//                height += 30
//                height += 30 // Emoji Array + Star Rating
//                //            height += 25    // Date Bar
//                return CGSize(width: view.frame.width - 16, height: height)
                
//                 GRID VIEW

                let width = (view.frame.width - 30 - 10) / 2

                let height = (GridCellImageHeightMult * width)
                return CGSize(width: width, height: height + 45)
                
            }
            else if self.postFormatInd == 1
            {
                return CGSize(width: view.frame.width, height: 110)
//
//
//                 GRID VIEW
//
//                let width = (view.frame.width - 30 - 15) / 2
//
//                let height = (GridCellImageHeightMult * width + 40)
//                return CGSize(width: width, height: height)
                
            }
            else
            {
                return CGSize(width: view.frame.width, height: view.frame.width)
            }
        }
        else
        {
            return CGSize.zero
        }


    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return (self.viewFilter.isFiltering) ? displayedPosts.count : fetchedPosts.count
        if section == 1 {
            var postCount = (isFiltering) ? displayedPosts.count : fetchedPosts.count
            self.showEmpty = postCount == 0 // (postCount == 0 && isFiltering)
            postCount = self.showEmpty ? 1 : postCount
            return postCount
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if self.isPresented {
            SVProgressHUD.dismiss()
        }
        
        if indexPath.section == 1 {
            
            if showEmpty /*&& self.isFiltering*/ {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emptyHeaderId, for: indexPath) as! EmptyCell
                cell.delegate = self
                cell.isFiltering = self.isFiltering
                cell.imageSubLabel.text = ""
                return cell
            } else {
                var displayPost = (isFiltering) ? displayedPosts[indexPath.item] : fetchedPosts[indexPath.item]
                
                if let tempRank = self.tempRank {
                    displayPost.listedRank = tempRank[(displayPost.id)!]
                }
                
                if self.postFormatInd == 0 {
//                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: listCellId, for: indexPath) as! FullPictureCell
//
//                    cell.post = displayPost
//                    cell.enableDelete = true
//                    cell.noImageScroll = true
//
//                    // Can't Be Selected
//
//                    if self.viewFilter.filterLocation != nil && cell.post?.locationGPS != nil {
//                        cell.post?.distance = Double((cell.post?.locationGPS?.distance(from: (self.viewFilter.filterLocation!)))!)
//                    }
//                    cell.showDistance = self.viewFilter.filterSort == defaultNearestSort
//
//                    cell.delegate = self
//                    cell.currentImage = 1
//                    return cell
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: gridCellId, for: indexPath) as! ListGridCell
                    cell.delegate = self
                    cell.post = displayPost
                    cell.showDistance = self.viewFilter.filterSort == defaultNearestSort
//                    cell.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
//                    cell.layer.cornerRadius = 10
//                    cell.layer.masksToBounds = true
                    return cell
                    
                    
                }
                    
                else if self.postFormatInd == 1 {

                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: testListCellId, for: indexPath) as! PostForListCell
                    cell.bookmarkDate = displayPost.creationDate
                    cell.post = displayPost
                    cell.backgroundColor = UIColor.white.withAlphaComponent(0.8)
                    cell.delegate = self
                    // Disable Selection to enable any tap to select cell
                    cell.allowSelect = false
                    
                    // Only show cell cancel button when showing post view
                    cell.showCancelButton = false
                    cell.currentImage = 1
                    cell.showDistance = self.viewFilter.filterSort == defaultNearestSort

//                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: testCellId, for: indexPath) as! TestHomePhotoCell
//
//                    cell.delegate = self
//                    cell.showDistance = self.viewFilter.filterSort == defaultNearestSort
//
//
//                    cell.post = displayPost
//                    cell.enableCancel = false
//                    cell.layer.cornerRadius = 1
//                    cell.layer.masksToBounds = true
//
//                    cell.showUserProfileImage = !(self.viewFilter.filterSort == defaultRecentSort)
//                    cell.locationDistanceLabel.textColor = UIColor.mainBlue()
//                    cell.layer.backgroundColor = UIColor.clear.cgColor
//                    cell.layer.shadowColor = UIColor.lightGray.cgColor
//                    cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
//                    cell.layer.shadowRadius = 2.0
//                    cell.layer.shadowOpacity = 0.5
//                    cell.layer.masksToBounds = false
//                    cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: 14).cgPath
//
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
    
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let item = self.fetchedPosts[indexPath.row].id
        let itemProvider = NSItemProvider(object: item as! NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        return [dragItem]
    }
    
    
//    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
//
//    }
    
     func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if indexPath.section == 0 {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: listHeaderId, for: indexPath) as! SingleListViewHeader
            
            if let selectedIndex = HeaderSortOptions.firstIndex(of: self.viewFilter.filterSort ?? HeaderSortOptions[0]) {
                if header.sortSegmentControl.selectedSegmentIndex != selectedIndex {
                    print("Header Load | \(selectedIndex) | \(self.viewFilter.filterSort) | CUR: \(header.sortSegmentControl.selectedSegmentIndex)")
                    header.sortSegmentControl.selectedSegmentIndex = selectedIndex
//                    header.reloadSegmentControl()
                }
            }
            
            header.currentDisplayList = self.currentDisplayList
            header.displayUser = self.displayUser
            header.viewFilter = self.viewFilter
            header.isFilteringText = self.tempSearchBarText
            header.postFormatInd = self.postFormatInd
    //        header.fullSearchBar.text = tempSearchBarText
    //        header.heroImageUrl = self.heroImageUrl
            header.delegate = self
            header.isHidden = false
            

            header.searchBar.viewFilter = self.viewFilter
            header.searchBar.filteredPostCount = displayedPosts.count
            header.searchBar.displayedEmojisCounts = self.first100EmojiCounts
            
            return header
                    
        } else {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: listHeaderId, for: indexPath) as! SingleListViewHeader
            header.frame.size.height = 0
            header.isHidden = true
            return header
        }
        

    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        var height: CGFloat = 280 + 100 + 50 + 30 + 5
//        // LIST URL HEIGHT
//        height += (self.currentDisplayList?.listUrl == "" ) ? 0 : 15
//        height += 40 // Emoji CollectionView
        
        var height: CGFloat = headerHeight
        
        // Header Sort with 5 Spacing
//        if section == 0 {
//            return CGSize(width: view.frame.width, height: height)
//        } else {
//            return CGSize.zero
//        }
        
        
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
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    
}

extension SingleListViewController: TestGridPhotoCellDelegate, TestGridPhotoCellDelegateObjc, NewListPhotoCellDelegate, SharePhotoListControllerDelegate, LegitListViewHeaderDelegate, FullPictureCellDelegate, SingleListViewHeaderDelegate, BottomEmojiBarDelegate, LegitSearchViewControllerDelegate, SKPhotoBrowserDelegate, EmptyCellDelegate, ListOptionsTableViewControllerDelegate, PostSortFormatBarDelegate, UITextViewDelegate, ListGridCellDelegate, BottomSortBarDelegate {
    
    func didTapLike(post: Post) {
        
    }
    
    func didActivateSearchBar() {
        self.didTapSearchButton()
    }
    

    func didTapCell(tag: String) {
        print("SingleListViewController | didTapCell \(tag)")
    }
    
    
    func didRemoveLocationFilter(location: String) {
        print("SingleListViewController | didRemoveLocationFilter \(location)")
    }
    
    func didRemoveRatingFilter(rating: String) {
        print("SingleListViewController | didRemoveRatingFilter \(rating)")
    }
    
    
    func didTapEmptyCell() {
        if self.isFiltering {
            self.handleRefresh()
        }
    }

    func didDeleteList(listId: String?) {
        guard let listId = listId else {return}
        if self.currentDisplayList?.id == listId {
            print("HandleBack | SingleListViewController | didDeleteList | \(listId)")
            self.handleBackPressNav()
        }
        
    }

    
    
    func showSearchView() {
        
    }
    
    func hideSearchView() {
        
    }

    func filterControllerSelected(filter: Filter?) {
        print("SingleListView | Received Filter | \(filter)")
        guard let filter = filter else {return}
        self.viewFilter = filter
        self.refreshPostsForFilter()
    }
    
    func refreshAll() {
        self.handleRefresh()
    }
    
    func setupSearchView() {
        searchViewController.delegate = self
        searchViewController.inputViewFilter = self.viewFilter
        searchViewController.noFilterTagCounts = self.noFilterTagCounts
        searchViewController.currentPostTagCounts = self.currentPostTagCounts
        searchViewController.currentRatingCounts = self.currentPostRatingCounts
        searchViewController.searchBar.text = ""
    }
    
    
    func didTapSearchButton() {
        print("Tap Search | \(self.currentPostsFilterTagCounts.count) Tags | \(self.viewFilter.searchTerms)")
        searchViewController.delegate = self
        searchViewController.inputViewFilter = self.viewFilter
        searchViewController.noFilterTagCounts = self.noFilterTagCounts
        searchViewController.currentPostTagCounts = self.currentPostTagCounts
        searchViewController.searchBar.text = ""

        searchViewController.viewWillAppear(true)

        UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.transitionCrossDissolve, animations:
            {
                self.searchViewController.presentView()
        }
            , completion: { (finished: Bool) in
        })
        
        
//        let testNav = UINavigationController(rootViewController: searchViewController)
        
//        let transition = CATransition()
//        transition.duration = 0.5
//        transition.type = CATransitionType.push
//        transition.subtype = CATransitionSubtype.fromBottom
//        transition.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
//        view.window!.layer.add(transition, forKey: kCATransition)
//        self.present(testNav, animated: true) {
//            print("   Presenting List Option View")
//        }
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
            self.tempSearchBarText = nil
            self.refreshPostsForFilter()

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

    
    func filterContentForSearchText(_ searchText: String) {
        self.tempSearchBarText = searchText
        print("filterContentForSearchText | \(searchText)")

        // Sort Recent Post By Listed Date
        var listSort: String = "Listed"
        if self.viewFilter.filterSort == defaultRecentSort && !(self.currentDisplayList?.isRatingList ?? false){
            listSort = "Listed"
        } else {
            listSort = (self.viewFilter.filterSort)!
        }
        
        
        Database.sortPosts(inputPosts: self.fetchedPosts, selectedSort: listSort, selectedLocation: self.viewFilter.filterLocation, completion: { (sortedPosts) in
            self.fetchedPosts = sortedPosts ?? []

        let tempFilter = self.viewFilter.copy() as! Filter
            self.isFiltering = self.viewFilter.isFiltering
            
         if let searchText = self.tempSearchBarText {
             tempFilter.filterCaptionArray.append(searchText)
            if !searchText.isEmptyOrWhitespace() {
                self.isFiltering = true
            }
         }
            

            Database.filterPostsNew(inputPosts: self.fetchedPosts, postFilter: tempFilter) { (filteredPosts) in
                
                self.displayedPosts = filteredPosts ?? []
                
                print("  ~ FINISH | Filter and Sorting Post | Post \(filteredPosts?.count) Posts | Pre \(self.fetchedPosts.count) | \(self.currentDisplayList?.name) - \(self.currentDisplayList?.id) | \(tempFilter.filterCaptionArray)")
                if (filteredPosts?.count ?? 0) > 0 {
                    let temp = filteredPosts![0] as Post
                    print(temp.locationName)
                }
                
                self.imageCollectionView.reloadSections(IndexSet(integer: 1))

            }
        })
        
        
//        self.filterSortFetchedPosts()
//        self.viewFilter.filterCaptionArray.
//        self.searchTableView.filterContentForSearchText(searchText)
    }
    
    func handleFilter() {
        self.tempSearchBarText = nil
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
        self.refreshPostsForFilter()
    }
    
//    func showSearchView() {
//        self.setupSearchTableView()
//        self.scrollToHeader()
//
//        UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.transitionCrossDissolve, animations:
//            {
//                self.searchTableView.view.alpha = 1
//        }
//            , completion: { (finished: Bool) in
//        })
//        self.imageCollectionView.isScrollEnabled = false
//    }
//    func hideSearchView() {
//        UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.transitionCrossDissolve, animations:
//            {
//                self.searchTableView.view.alpha = 0
//        }
//            , completion: { (finished: Bool) in
//        })
//        self.imageCollectionView.isScrollEnabled = true
//
//    }
    
        
    
    @objc func handleFollowingList(){
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        guard let followingList = self.currentDisplayList else {
            print("List | handleFollowingList ERROR | No List to Follow")
            return
        }
        
        guard let followingListId = followingList.id else {
            print("List | handleFollowingList ERROR | No List ID")
            return
        }
        
        if CurrentUser.followedListIds.contains(followingListId) {
            self.alert(title: "", message: "\((self.currentDisplayList?.name)!) List UnFollowed")
            Database.handleUnfollowList(userUid: uid, followedList: followingList) {
                //                self.setupListFollowButton()
            }
        } else {
            self.alert(title: "", message: "\((self.currentDisplayList?.name)!) List Followed")
            Database.handleFollowingList(userUid: uid, followedList: followingList) {
                //                self.setupListFollowButton()
            }
        }
    }
    
    @objc func headerSortSelected(sort: String) {
//        print("SingleListViewController | \(sort)")
        
        var sortString =  "Fetching Posts"
        if self.viewFilter.filterSort == sortNew {
            sortString = "Fetching Latest Posts"
        } else if self.viewFilter.filterSort == sortNearest {
            sortString = "Fetching Nearest Posts to You"
        } else if self.viewFilter.filterSort == sortTrending {
            sortString = "Fetching Most Popular Posts"
        }
        
        SVProgressHUD.show(withStatus: sortString)
        
        self.viewFilter.filterSort = sort
        self.refreshPostsForSort()
        print("SingleListProfile | Sort is  \(self.viewFilter.filterSort) | \(self.currentDisplayList?.name)")
        
    }
    
    func didTapGridButton() {
        if (postFormatInd == 0) {
            self.didChangeToListView()
        } else if (postFormatInd == 1) {
            self.didChangeToGridView()
        }
    }
    
    @objc func didChangeToGridView() {
        print("ListViewController | Change to Grid View")
        SVProgressHUD.show(withStatus: "Loading View")
        self.postFormatInd = 0
//        self.switchCollectionView()
        self.imageCollectionView.reloadData()
    }
    
    @objc func didChangeToListView() {
        print("ListViewController | Change to List View")
        SVProgressHUD.show(withStatus: "Loading View")
        self.postFormatInd = 1
//        self.switchCollectionView()

        self.imageCollectionView.reloadData()
    }
    
    
    func didTapPicture(post: Post) {
        print("Function: \(#function), line: \(#line)")
        self.extTapPicture(post: post)
//        let pictureController = SinglePostView()
//        pictureController.post = post
//        navigationController?.pushViewController(pictureController, animated: true)
    }
    
    func didTapListCancel(post: Post) {
        print("Function: \(#function), line: \(#line)")
    }
    
    func didTapCell(int: Int) {
        print("Function: \(#function), line: \(#line)")

    }
    
    func didTapComment(post: Post) {
        print("Function: \(#function), line: \(#line)")
        self.extTapComment(post: post)
    }
    
    func didTapUser(post: Post) {
        print("Function: \(#function), line: \(#line)")
        self.extTapUser(post: post)
    }
    
    func goToUser(userId: String?) {
        guard let userId = userId else {return}
        self.extTapUser(userId: userId)
    }
    
    func didTapLocation(post: Post) {
        print("Function: \(#function), line: \(#line)")
        self.extTapLocation(post: post)
    }
    
    func didTapMessage(post: Post) {
        print("Function: \(#function), line: \(#line)")
        self.extTapMessage(post: post)
    }
    
    
    func didTapListSetting() {
        let options = ListOptionsTableViewController()
        options.inputList = self.currentDisplayList
        let testNav = UINavigationController(rootViewController: options)
        
        let transition = CATransition()
        transition.duration = 0.5
        transition.type = CATransitionType.moveIn
        transition.subtype = CATransitionSubtype.fromTop
        transition.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
        view.window!.layer.add(transition, forKey: kCATransition)
        self.present(testNav, animated: true) {
            print("   Presenting List Option View")
        }

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
            self.imageCollectionView.deleteItems(at: [filteredindexpath])
            Database.deletePost(post: post)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        present(deleteAlert, animated: true, completion: nil)
        
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
        let index = fetchedPosts.firstIndex { (fetchedPost) -> Bool in
            fetchedPost.id == post.id
        }
        
        // Update Cache
        let postId = post.id
        postCache[postId!] = post
        
        
    }
    
    
    func didTapUserUid(uid: String) {
        self.extTapUserUid(uid: uid, displayBack: true)
//        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
//        userProfileController.displayUserId = uid
//        navigationController?.pushViewController(userProfileController, animated: true)
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
    
    
    func displayListFollowingUsers(list: List, following: Bool) {
        print("Display Users| Following: ",list.id)
        self.extShowUsersFollowingList(list: list, following: following)
    }
    
    @objc func toggleMapFunction(){
        //        appDelegateFilter = self.viewFilter
        if appDelegateMapViewInd {
            // List Opened while on Map View
            self.delegate?.listSelected(list: currentDisplayList)
            self.navigationController?.popToRootViewController(animated: true)
        } else {
            // List from Tab on Instagram View
            var tempFilter = Filter.init()
            tempFilter.filterList = currentDisplayList
            if let listGPS = currentDisplayList?.listGPS {
                tempFilter.filterLocation = listGPS
            }
            print("ListViewController | toggleMapFunction | GPS | \(tempFilter.filterLocation)")
            
            appDelegateFilter = tempFilter
            //            self.navigationController?.popToRootViewController(animated: false)
            self.toggleMapView()
        }
    }
    
    func didTapBookmark(post: Post) {
        print("Function: \(#function), line: \(#line)")
        let sharePhotoListController = SharePhotoListController()
        sharePhotoListController.uploadPost = post
        sharePhotoListController.isBookmarkingPost = true
        sharePhotoListController.delegate = self
        navigationController?.pushViewController(sharePhotoListController, animated: true)
    }
    
    func deletePostFromList(post: Post) {
        print("Function: \(#function), line: \(#line)")
        let deleteAlert = UIAlertController(title: "Delete", message: "Remove Post From List?", preferredStyle: UIAlertController.Style.alert)
        
        deleteAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
            // Remove from Current View
            let index = self.fetchedPosts.firstIndex { (filteredpost) -> Bool in
                filteredpost.id  == post.id
            }
            
            let deleteindexpath = IndexPath(row:index!, section: 0)
            self.fetchedPosts.remove(at: index!)
            let listdeleteindex = self.currentDisplayList?.postIds?.index(forKey: post.id!)
            self.currentDisplayList?.postIds?.remove(at: listdeleteindex!)
            self.imageCollectionView.deleteItems(at: [deleteindexpath])
            Database.DeletePostForList(postId: post.id, postCreatorUid: (post.creatorUID)!, listId: self.currentDisplayList?.id, postCreationDate: nil)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        if self.currentDisplayList?.creatorUID == uid{
            // Only Allow Deletion if current user is list creator
            present(deleteAlert, animated: true, completion: nil)
        }
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
    
    func didTapListDesc() {
        
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Change List Description", message: "Enter a New Description", preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.text = self.currentDisplayList?.listDescription
        }
        
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            print("Text field: \(textField?.text)")
            self.confirmListDesc(text: textField?.text)
            // Change List Name

        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    func confirmListDesc(text: String?) {
        guard let text = text else {return}
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Confirm List Description", message: "\(text)\n\nAre You Sure?", preferredStyle: .alert)
        
        
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            self.updateListDesc(listDesc: text)
            // Change List Name

        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    func updateListDesc(listDesc: String?) {
        guard let listDesc = listDesc else {return}

        Database.updateListDetails(list: self.currentDisplayList, heroImageUrl: nil, heroImageUrlPostId: nil, listName: nil, description: listDesc, listUrl: nil)
        self.currentDisplayList?.listDescription = listDesc
        self.imageCollectionView.reloadData()

    }
    
    
    @objc func didTapHeaderImage(selectedImages: UIImage?){
        
        guard let selectedImages = selectedImages else {return}
        self.extShowImage(inputImages: [selectedImages])

//        var images = [SKPhoto]()
//
//        guard let selectedImages = selectedImages else {return}
//        let photo = SKPhoto.photoWithImage(selectedImages)// add some UIImage
//        images.append(photo)
        
        /*
        // 2. create PhotoBrowser Instance, and present from your viewController.
        SKPhotoBrowserOptions.displayCounterLabel = true
        SKPhotoBrowserOptions.displayBackAndForwardButton = true
        SKPhotoBrowserOptions.displayAction = true
        SKPhotoBrowserOptions.actionButtonTitles = ["Edit Photo"]
        SKPhotoBrowserOptions.swapCloseAndDeleteButtons = false
        SKPhotoBrowserOptions.bounceAnimation = true
        SKPhotoBrowserOptions.displayDeleteButton = true
        //        SKPhotoBrowserOptions.enableSingleTapDismiss  = true
*/
//        browser = SKPhotoBrowser(photos: images)
//        browser.updateCloseButton(#imageLiteral(resourceName: "checkmark_teal").withRenderingMode(.alwaysOriginal), size: CGSize(width: 50, height: 50))
//        browser.delegate = self
//
//        browser.initializePageIndex(0)
//        present(browser, animated: true, completion: {})
        
    }
    
    func editListDesc() {
        let alertController = UIAlertController(title: "Update List Description \n\n\n\n\n\n", message: nil, preferredStyle: UIAlertController.Style.alert)

        let margin:CGFloat = 8.0
        let rect = CGRect(x: margin, y: margin + 40, width: alertController.view.bounds.size.width - margin * 4.0, height: 100.0)
        let customView = UITextView(frame: rect)

        customView.backgroundColor = UIColor.clear
        customView.font = UIFont(name: "Helvetica", size: 15)
        customView.delegate = self
        if (currentDisplayList?.listDescription?.count) ?? 0 > 0 {
            customView.text = currentDisplayList?.listDescription
            customView.textColor = UIColor.black
        } else {
            customView.text = ""
            customView.textColor = UIColor.lightGray
        }


        //  customView.backgroundColor = UIColor.greenColor()
        alertController.view.addSubview(customView)

        
        let somethingAction = UIAlertAction(title: "Update", style: UIAlertAction.Style.default, handler: {(alert: UIAlertAction!) in
            let info = customView.text
            if (info != ListDescPlaceHolder) && (info !=  self.currentDisplayList?.listDescription) {
                self.confirmListDesc(text: info)
            }
            
            print(customView.text)

        })

        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: {(alert: UIAlertAction!) in print("cancel")})

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

// MARK: - SEARCH FUNCTIONS


extension SingleListViewController: PostSearchTableViewControllerDelegate {
    func filterSelected(filter: Filter) {
        self.hideSearchView()
        self.viewFilter = filter
        self.refreshPostsForFilter()
    }
    
    
    func setupSearchTableView(){
//        self.searchTableView.defaultEmojiCounts = self.noCaptionFilterEmojiCounts
//        self.searchTableView.defaultPlaceCounts = self.noCaptionFilterPlaceCounts
//        self.searchTableView.defaultCityCounts = self.noCaptionFilterCityCounts
//        self.searchTableView.initSearchSelections()
//        self.searchTableView.delegate = self
//        self.searchTableView.viewFilter = self.viewFilter
        
    }
    
    
}

// MARK: - EMPTY SET DELEGATE


extension SingleListViewController: EmptyDataSetSource, EmptyDataSetDelegate {
    // EMPTY DATA SET DELEGATES
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        if (self.viewFilter.isFiltering) {
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
        
        return NSMutableAttributedString(string: text!, attributes: [NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.font: font])
        
        
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        //        if isFiltering {
        //            text = nil
        //        } else {
        //            text = nil
        //        }
        
        //        let number = arc4random_uniform(UInt32(tipDefaults.count))
        //        text = tipDefaults[Int(number)]
        text = nil
        
        font = UIFont(name: "Poppins-Regular", size: 15)
        textColor = UIColor.ianBlackColor()
        
        if (viewFilter.isFiltering) {
            text = "Nothing Legit Here! 😭"
        } else {
            text = ""
        }
        
        if text == nil {
            return nil
        }
        
        return NSMutableAttributedString(string: text!, attributes: [NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.font: font])
        
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return #imageLiteral(resourceName: "Legit_Vector")
    }
    
    
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        if (self.viewFilter.isFiltering) {
            text = "Try Searching For Something Else"
        } else {
            text = "Start Adding Posts to Your Lists!"
        }
        text = ""
        font = UIFont.boldSystemFont(ofSize: 14.0)
        textColor = UIColor(hexColor: "00aeef")
        
        if text == nil {
            return nil
        }
        
        return NSMutableAttributedString(string: text!, attributes: [NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.font: font])
        
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
    //
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
        return UIColor.backgroundGrayColor()
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {
        if (self.viewFilter.isFiltering) {
//            self.showSearch()
        } else {
            // Returns To Home Tab
            self.tabBarController?.selectedIndex = 0
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


}

