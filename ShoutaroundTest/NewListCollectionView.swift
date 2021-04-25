//
//  NewListCollectionView.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 7/20/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

import CoreLocation
import EmptyDataSet_Swift
import DropDown
import CoreGraphics
import SVProgressHUD
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import SKPhotoBrowser

protocol NewListCollectionViewDelegate {
    func listSelected(list: List?)
    func deleteList(list:List?)
}


class NewListCollectionView: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,UICollectionViewDragDelegate, UICollectionViewDropDelegate, UISearchBarDelegate, UISearchControllerDelegate, UIGestureRecognizerDelegate, EmptyDataSetSource, EmptyDataSetDelegate, MainSearchControllerDelegate, SearchFilterControllerDelegate, TestGridPhotoCellDelegate, SKPhotoBrowserDelegate, NewListPhotoCellDelegate, SharePhotoListControllerDelegate, NewListViewControllerHeaderDelegate, UISearchResultsUpdating {


    static let refreshListViewNotificationName = NSNotification.Name(rawValue: "RefreshListView")

    let gridCellId = "gridCellId"
    let listCellId = "listCellId"
    let listHeaderId = "listHeaderId"

    var delegate: NewListCollectionViewDelegate?

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
            print(" ListCollectionView | DISPLAYING | \(currentDisplayList?.name) | \(currentDisplayList?.id) | \(currentDisplayList?.postIds?.count) Posts |List_ViewController")

            //            print("currentDisplayList | \(currentDisplayList?.name) | \(currentDisplayList?.id) | \(currentDisplayList?.postIds?.count)")
            // CLEAR SEARCH BAR

            fetchPostsForList()
            if displayUser?.uid != currentDisplayList?.creatorUID{
                print("Fetching \(currentDisplayList?.creatorUID) for List \(currentDisplayList?.name): \(currentDisplayList?.id)")
                fetchUserForList()
            }

            self.tempRank = currentDisplayList?.listRanks
            self.heroImageUrl = currentDisplayList?.heroImageUrl
            //            print("currentDisplayList | Set Temp Rank | \(self.tempRank?.count)")

        }
    }
    
    var heroImageUrl: String? = nil
    
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
                    print("ListViewController | Fetched Posts For List | Emoji Check | Updating Emojis | \(self.currentDisplayList?.id) : \(tempEmojis)")
                    Database.updateSocialCountForList(listId: self.currentDisplayList?.id, credCount: nil, emojis: tempEmojis)
                    self.currentDisplayList?.topEmojis = tempEmojis
                    listCache[(self.currentDisplayList?.id)!] = self.currentDisplayList
                }
                
            })
            
            self.filterSortFetchedPosts()
            self.isFetchingPost = false
            
        })
    }

    func fetchUserForList(){
        guard let currentDisplayList = self.currentDisplayList else {
            print("Fetch User For List: Error, No Display List")
            return
        }
        
        Database.fetchUserWithUID(uid: (currentDisplayList.creatorUID)!) { (fetchedUser) in
            self.displayUser = fetchedUser
        }
    }
    
    // Used to fetch lists
    var displayUser: User? = nil {
        didSet{
            print("NewListCollectionView | Current display user: \(displayUser?.username) | \(displayUser?.uid)")
//            self.setupUser()
        }
    }
    
    func setupUser(){
//        guard let displayUser = displayUser else {return}
//        usernameLabel.text = displayUser.username
//        usernameLabel.sizeToFit()
//        usernameLabel.adjustsFontSizeToFitWidth = true
//        usernameLabel.sizeToFit()
//
//        usernameLabel.isUserInteractionEnabled = true
//        let usernameTapGesture = UITapGestureRecognizer(target: self, action: #selector(usernameTap))
//        usernameLabel.addGestureRecognizer(usernameTapGesture)
//
//        let profileImageUrl = displayUser.profileImageUrl
//        userProfileImageView.loadImage(urlString: profileImageUrl)
    }
    
    
    //DISPLAY VARIABLES
    var fetchedPosts: [Post] = [] {
        didSet{
            
            if !(self.viewFilter?.isFiltering)!{
                Database.countMostUsedEmojis(posts: self.fetchedPosts) { (emojis) in
                    self.listDisplayEmojis = emojis
                    //                print("Most Displayed Emojis: \(emojis)")
                }
            }
        }
    }
    var displayedPosts: [Post] = [] {
        didSet {
            if (self.heroImageUrl == "" || self.heroImageUrl == nil) && displayedPosts.count > 0  {
                print("NO HERO IMAGE | Replacing with first post image | NewListView")
                self.heroImageUrl = displayedPosts[0].imageUrls[0]
                self.currentDisplayList?.heroImageUrl = displayedPosts[0].imageUrls[0]
                Database.updateListHeroImage(list: currentDisplayList, imageUrl: displayedPosts[0].imageUrls[0])
            }
        }
    }
    var tempRank:[String:Int]? = [:]

    let saveRankButton = UIButton()
    
    func rerankPostForList(){
        print("rerankPostForList")
        
        // ONLY RERANK IF THERE IS THE SAME AMOUNT OF POSTS - SO NO FILTERED
        guard let filter = self.viewFilter else {
            print("rerankPostForList | No Filter")
            return
        }
        
        if self.fetchedPosts.count == self.currentDisplayList?.postIds?.count && !(self.viewFilter?.isFiltering)!{
            var tempRank: [String:Int] = [:]
            for (index, postObject) in self.fetchedPosts.enumerated() {
                var tempPost = postObject
                tempRank[(postObject.id)!] = index + 1
            }
            self.tempRank = tempRank
            if self.tempRank != self.currentDisplayList?.listRanks {
                self.saveRankButton.isHidden = false
            } else {
                self.saveRankButton.isHidden = true
            }
            self.imageCollectionView.reloadData()
            self.imageCollectionView.reloadItems(at: imageCollectionView.indexPathsForVisibleItems)
            
        }
    }
    
    @objc func savePostRankForList(){
        guard let currentList = self.currentDisplayList else {
            print("ListViewController | savePostRankForList | ERROR | No List")
            return
        }
        if !(self.viewFilter?.isFiltering)! {
            var tempRank: [String:Int] = [:]
            for (index, object) in self.fetchedPosts.enumerated() {
                tempRank[(object.id)!] = index + 1
            }
            // SAVE RANKS IF DIFFERENT RANK FROM SAVED LIST OR DIFFERENT COUNT
            if (tempRank != self.currentDisplayList?.listRanks) || (self.currentDisplayList?.listRanks.count != tempRank.count){
                print("ListViewController | savePostRankForList")
                Database.updateRankForList(listId: currentList.id, newRank: tempRank)
                SVProgressHUD.showSuccess(withStatus: "New Rankings Saved")
                SVProgressHUD.dismiss(withDelay: 1)
                self.tempRank = tempRank
                self.saveRankButton.isHidden = true
            } else {
                print("ListViewController | savePostRankForList | Same Ranking")
                self.saveRankButton.isHidden = true
            }
            
        } else {
            print("ListViewController | savePostRankForList | IsFiltering Is \(self.viewFilter?.isFiltering)")
            self.alert(title: "Saving List Error", message: "List ranks cannot be saved while list is being filtered")
        }
    }
    
    
    var listDisplayEmojis: [String] = [] {
        didSet{
//            self.emojiCollectionView.reloadData()
            self.refreshEmojiArray()
        }
    }
    
    var emojiArray = EmojiButtonArray(emojis: [], frame: CGRect(x: 0, y: 0, width: 0, height: 20))

    
    func refreshEmojiArray(){
        //        print("REFRESH EMOJI ARRAYS")
        
        
        if self.listDisplayEmojis.count > 0 {
//            print("UPDATED EMOJI ARRAY: \(emojiArray.emojiLabels)")
            emojiArray.emojiLabels = self.listDisplayEmojis
            emojiArray.setEmojiButtons()
            emojiArray.sizeToFit()
            for button in emojiArray.emojiButtonArray {
                button.backgroundColor = UIColor.clear
                if let emojiText = button.titleLabel?.text {
                    if self.viewFilter?.filterCaption?.contains(emojiText) ?? false{
                        button.backgroundColor = UIColor.mainBlue()
                    }
                }
            }
        }
    }


    
    // Filtering Variables
    
    var viewFilter: Filter? = Filter.init(defaultSort: defaultRankSort) {
        didSet {
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
            //        self.refreshPostsForFilter()
        }
    }
    
    func searchListForText(text: String?) {
        guard let text = text else {
            self.viewFilter?.filterCaption = nil
            self.isFilteringText = nil
            self.refreshPostsForFilter()
            return}
        self.filterContentForSearchText(text)
        
//        self.viewFilter?.filterCaption = text
//        self.isFilteringText = text
//        self.imageCollectionView.reloadItems(inSection: 0)
//        self.refreshPostsForFilter()

    }
    
    @objc func filterContentForSearchText(_ searchText: String) {

        
        Database.filterPostsNew(inputPosts: self.fetchedPosts, postFilter: self.viewFilter) { (filteredPosts) in
            
            self.displayedPosts = filteredPosts ?? []
            print("  ~ FINISH | Filter and Sorting Post | \(filteredPosts?.count) Posts | \(self.currentDisplayList?.name) - \(self.currentDisplayList?.id)")
            SVProgressHUD.dismiss()
            
            self.imageCollectionView.reloadItems(inSection: 0)

        }
    }
    
    let searchController = UISearchController(searchResultsController: nil)
    func setupSearchController(){
        self.extendedLayoutIncludesOpaqueBars = true
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        
    }
    

    
    func updateSearchResults(for searchController: UISearchController) {
        // Updates Search Results as searchbar is populated
        let searchBar = searchController.searchBar
        self.isFilteringText = searchBar.text
        if (self.isFilteringText?.isEmpty)! {
            // Displays Default Search Results even if search bar is empty
            self.isFilteringText = nil
            searchController.searchResultsController?.view.isHidden = false
        } else {
            filterContentForSearchText(searchBar.text!)
        }

    }
    
    
    var isFilteringText: String? = nil
    
    // CollectionView Setup
    
    var isListView: Bool = true
    
    var postFormatInd: Int = 0
    // 0 Grid View
    // 1 List View
    // 2 Full View
    
    enum postFormat {
        case full
        case list
        case grid
    }
    
    //    var currentPostFormat = postFormat.grid
    
    lazy var imageCollectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: HomeSortFilterHeaderFlowLayout())
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = .white
        return cv
    }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("  START |  NewListCollectionView | ViewdidLoad")
        self.edgesForExtendedLayout = UIRectEdge.top
        setupNavigationItems()
        setupCollectionView()
        self.view.addSubview(imageCollectionView)
        imageCollectionView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: ListViewController.refreshListViewNotificationName, object: nil)
        print("  END |  NewListCollectionView | ViewdidLoad")



    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewWillAppear(_ animated: Bool) {
        self.setNeedsStatusBarAppearanceUpdate()
        imageCollectionView.collectionViewLayout.invalidateLayout()
        imageCollectionView.layoutIfNeeded()
        setupNavigationItems()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.setNeedsStatusBarAppearanceUpdate()
        imageCollectionView.collectionViewLayout.invalidateLayout()
        imageCollectionView.layoutIfNeeded()
        setupNavigationItems()
    }
    
    lazy var navShareButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.layer.backgroundColor = UIColor.white.cgColor
        button.layer.borderColor = UIColor.legitColor().cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 2
        button.clipsToBounds = true
        button.contentHorizontalAlignment = .center
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        return button
    }()
    
    func setupNavigationItems(){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        self.setNeedsStatusBarAppearanceUpdate()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.barTintColor = UIColor.clear
        self.navigationController?.navigationBar.tintColor = UIColor.clear
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.isNavigationBarHidden = false

        // Nav Bar Buttons
//        let tempNavBarButton = NavBarMapButton.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//        tempNavBarButton.tintColor = UIColor.white
//        tempNavBarButton.layer.borderWidth = 1
//        tempNavBarButton.layer.borderColor = UIColor.white.cgColor
//        tempNavBarButton.setTitleColor(UIColor.white, for: .normal)
//        tempNavBarButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
//        tempNavBarButton.addTarget(self, action: #selector(toggleMapFunction), for: .touchUpInside)
//        let barButton1 = UIBarButtonItem.init(customView: tempNavBarButton)
        
        
//        navShareButton.addTarget(self, action: #selector(showMessagingOptionsNav), for: .touchUpInside)
//        let navShareTitle = NSAttributedString(string: " SHARE ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.legitColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 10)])
//        navShareButton.setAttributedTitle(navShareTitle, for: .normal)
//        //        navShareButton.setImage((#imageLiteral(resourceName: "message_fill").resizeImageWith(newSize: CGSize(width: 20, height: 20))).withRenderingMode(.alwaysTemplate), for: .normal)
//        navShareButton.setImage((#imageLiteral(resourceName: "IanShareImage").resizeImageWith(newSize: CGSize(width: 10, height: 10))).withRenderingMode(.alwaysTemplate), for: .normal)
//
//        navShareButton.tintColor = UIColor.legitColor()
//        navShareButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
//        navShareButton.sizeToFit()
//        let barButton1 = UIBarButtonItem.init(customView: navShareButton)

//        self.navigationItem.rightBarButtonItems = [barButton1]
        
        // Nav Back Buttons
        let navBackButton = navBackButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        navBackButton.addTarget(self, action: #selector(handleBackPressNav), for: .touchUpInside)
        let barButton2 = UIBarButtonItem.init(customView: navBackButton)
        self.navigationItem.leftBarButtonItem = barButton2
        
        if let navController = self.navigationController {
            UIApplication.shared.keyWindow!.bringSubviewToFront(navController.navigationBar)
        }
    }
//
//    @objc func showMessagingOptionsNav(){
//        guard let post = self.post else {return}
//        self.showMessagingOptions(post: post)
//    }
//
//    func showMessagingOptions(post: Post?){
//        guard let post = post else {return}
//
//        let optionsAlert = UIAlertController(title: "Share this post via email or IMessage. LegitList is not required to receive posts.", message: "", preferredStyle: UIAlertController.Style.alert)
//
//        optionsAlert.addAction(UIAlertAction(title: "iMessage", style: .default, handler: { (action: UIAlertAction!) in
//            // Allow Editing
//            self.handleIMessage(post: post)
//        }))
//
//        optionsAlert.addAction(UIAlertAction(title: "Email", style: .default, handler: { (action: UIAlertAction!) in
//            self.handleMessage(post: post)
//        }))
//
//        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
//            print("Handle Cancel Logic here")
//        }))
//
//        present(optionsAlert, animated: true) {
//            optionsAlert.view.superview?.isUserInteractionEnabled = true
//            optionsAlert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.alertClose(gesture:))))
//        }
//
//    }
//
    
    
    @objc func handleBackPressNav(){
        //        guard let post = self.selectedPost else {return}
        self.handleBack()
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
    
    
    func setupCollectionView(){
        imageCollectionView.register(NewListPhotoCell.self, forCellWithReuseIdentifier: listCellId)
        imageCollectionView.register(TestGridPhotoCell.self, forCellWithReuseIdentifier: gridCellId)
        imageCollectionView.register(NewListViewControllerHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: listHeaderId)
        var topMargin = CGFloat((self.navigationController?.navigationBar.frame.size.height) ?? 0)
        topMargin += UIApplication.shared.statusBarFrame.height ?? 0
         
        
        imageCollectionView.contentInset = UIEdgeInsets(top: -topMargin, left: 0, bottom: 0, right: 0)
        imageCollectionView.backgroundColor = .white
        imageCollectionView.translatesAutoresizingMaskIntoConstraints = true
//        let layout: UICollectionViewFlowLayout = HomeSortFilterHeaderFlowLayout()
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        imageCollectionView.collectionViewLayout = layout
        
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
    
    
    var noCaptionFilterEmojiCounts: [String:Int] = [:] {
        didSet {
            if noCaptionFilterEmojiCounts.count > 0 {
                var tempEmojis:[String] = []
                for (key,value) in noCaptionFilterEmojiCounts.sorted(by: { $0.value > $1.value }) {
                    if key.containsOnlyEmoji{
                        tempEmojis.append(key)
                    }
                }
                noCaptionFilterMostUsedEmojis = tempEmojis
            }
        }
    }
    var noCaptionFilterMostUsedEmojis: [String] = []
    
    var noCaptionFilterLocationCounts: [String:Int] = [:]
    var noFilterAverageRating: Double = 0.0
    
    func filterSortFetchedPosts(){
        
        var noCaptionLocationFilter = Filter.init()
        noCaptionLocationFilter.filterUser = self.viewFilter?.filterUser
        noCaptionLocationFilter.filterList = self.viewFilter?.filterList
        
        // Fetches All Posts, Refilters assuming no caption filtered, recount emoji/location
        if self.noCaptionFilterEmojiCounts.count == 0 && !self.viewFilter!.isFiltering {
            Database.countEmojis(posts: self.fetchedPosts) { (emojiCounts) in
                self.noCaptionFilterEmojiCounts = emojiCounts
                self.currentDisplayList?.tagCounts = emojiCounts
                print("ListViewController | noCaptionFilterEmojiCounts | \(self.noCaptionFilterEmojiCounts.count)")
            }
        }
        
        if self.noCaptionFilterLocationCounts.count == 0 && !self.viewFilter!.isFiltering {
            Database.countCityIds(posts: self.fetchedPosts) { (locationCounts) in
                self.noCaptionFilterLocationCounts = locationCounts
                self.currentDisplayList?.locationCounts = locationCounts

                print("ListViewController | noCaptionFilterLocationCounts | \(self.noCaptionFilterLocationCounts.count)")
            }
        }
        
        self.noFilterAverageRating = Database.averageRating(posts: self.fetchedPosts)
        
        // Sort Recent Post By Listed Date
        var listSort: String = "Listed"
        if self.viewFilter?.filterSort == defaultRecentSort {
            listSort = "Listed"
        } else {
            listSort = (self.viewFilter?.filterSort)!
        }
        
        Database.sortPosts(inputPosts: self.fetchedPosts, selectedSort: listSort, selectedLocation: self.viewFilter?.filterLocation, completion: { (sortedPosts) in
            self.fetchedPosts = sortedPosts ?? []

            
            Database.filterPostsNew(inputPosts: self.fetchedPosts, postFilter: self.viewFilter) { (filteredPosts) in
                
                self.displayedPosts = filteredPosts ?? []
                print("  ~ FINISH | Filter and Sorting Post | \(filteredPosts?.count) Posts | \(self.currentDisplayList?.name) - \(self.currentDisplayList?.id)")
                SVProgressHUD.dismiss()
                
                if self.imageCollectionView.isDescendant(of: self.view) {
                    self.imageCollectionView.reloadData()
                }
            }
        })
    }
    
    // Refresh Functions
    
    @objc func refreshAll() {
        self.handleRefresh()
    }
    
    @objc func handleRefresh(){
        print("ListViewController | Refresh List | \(self.currentDisplayList?.name)")
        self.refreshList()
        self.clearAllPost()
        self.clearFilter()
        //        self.collectionView.reloadData()
        self.fetchPostsForList()
        self.imageCollectionView.refreshControl?.endRefreshing()
    }
    
    func refreshList(){
        
        guard let listId = self.currentDisplayList?.id else {return}
        
        Database.fetchListforSingleListId(listId: listId) { (fetchedList) in
            self.currentDisplayList = fetchedList
        }
        
    }
    
    
    
    
    func clearAllPost(){
        self.fetchedPosts = []
        self.displayedPosts = []
    }
    
    
    func clearFilter(){
        self.viewFilter?.clearFilter()
    }
    
    @objc func refreshPostsForFilter(){
        self.clearAllPost()
        self.fetchPostsForList()
        self.imageCollectionView.refreshControl?.endRefreshing()
    }
    
    func didTapEmoji(emoji: String) {

        
        
    }
    
    func didTapAddTag(addTag: String) {
        print("   ListCV | didTapAddtag | \(addTag)")
        // Can tap either post type string (breakfast, lunch dinner) or most popular emojis
        let tempAddTag = addTag.lowercased()
        
        
//        guard let caption = self.viewFilter?.filterCaption else {
//            self.viewFilter?.filterCaption = tempAddTag
//            self.refreshPostsForFilter()
//            return
//        }
        var filterCaption = (self.viewFilter?.filterCaption ?? "").lowercased()
        
        
        if tempAddTag.isSingleEmoji
        {
            // EMOJI
            let emojiDic = EmojiDictionary[tempAddTag] ?? ""
            let emojiInput = "\(tempAddTag) \(emojiDic)"
            
            if filterCaption.contains(tempAddTag) {
                self.viewFilter?.filterCaption = filterCaption.replacingOccurrences(of: tempAddTag, with: "")
                self.viewFilter?.filterCaption = filterCaption.replacingOccurrences(of: emojiDic, with: "")

            } else {
                self.viewFilter?.filterCaption = emojiInput

                // ADDS ON TERMS
//                if self.viewFilter?.filterCaption == nil {
//                    self.viewFilter?.filterCaption = emojiInput
//                } else {
//                    self.viewFilter?.filterCaption = filterCaption + emojiInput
//                }
            }
        }
        else
        {
            // STRING
            print(tempAddTag.capitalizingFirstLetter())
            print(UploadPostTypeString)
            
            if UploadPostTypeString.contains(tempAddTag.capitalizingFirstLetter()) {
                // CHECK IF IS MEAL TYPE
                if self.viewFilter?.filterType == tempAddTag {
                    self.viewFilter?.filterType = nil
                    self.viewFilter?.filterCaption = filterCaption.replacingOccurrences(of: tempAddTag, with: "")
                } else {
                    self.viewFilter?.filterType = tempAddTag
                }
            } else {
                // IS SEARCH STRING
                if filterCaption.contains(tempAddTag) {
                    self.viewFilter?.filterCaption = filterCaption.replacingOccurrences(of: tempAddTag, with: "")
                } else {
                    self.viewFilter?.filterCaption = filterCaption + tempAddTag
                }
                
            }
        }
        
        self.isFilteringText = self.viewFilter?.filterCaption
        print("   ListCV | didTapAddTag | \(self.viewFilter?.filterCaption)")
        self.refreshPostsForFilter()
        
    }
    
    func filterControllerSelected(filter: Filter?) {
        self.viewFilter = filter
        self.refreshPostsForFilter()
    }
    

    func didTapPicture(post: Post) {
        let pictureController = SinglePostView()
        pictureController.post = post
        
        navigationController?.pushViewController(pictureController, animated: true)
    }
    
    func didTapListCancel(post: Post) {
        
    }
    

    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if self.postFormatInd == 1 {
            // LIST VIEW
            return CGSize(width: view.frame.width, height: 180)
        } else if self.postFormatInd == 0 {
            // GRID VIEW
            let width = (view.frame.width - 2 - 30) / 2
            return CGSize(width: width, height: width)
        } else {
            return CGSize(width: view.frame.width, height: view.frame.width)
        }

    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return (self.viewFilter?.isFiltering)! ? displayedPosts.count : fetchedPosts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
            var displayPost = (self.viewFilter?.isFiltering)! ? displayedPosts[indexPath.item] : fetchedPosts[indexPath.item]
            
            if let tempRank = self.tempRank {
                displayPost.listedRank = tempRank[(displayPost.id)!]
            }
            
            if self.postFormatInd == 1 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: listCellId, for: indexPath) as! NewListPhotoCell
                cell.delegate = self
                cell.bookmarkDate = displayPost.listedDate
                cell.showRank = self.viewFilter?.filterSort == "Rank"
                cell.post = displayPost
                
                
                if self.currentDisplayList?.creatorUID == Auth.auth().currentUser?.uid {
                    //                cell.allowDelete = true
                    cell.showCancelButton = true
                } else {
                    //                cell.allowDelete = false
                    cell.showCancelButton = false
                }
                return cell
            }
                
            else if self.postFormatInd == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: gridCellId, for: indexPath) as! TestGridPhotoCell
                cell.delegate = self
                cell.showDistance = self.viewFilter?.filterSort == defaultNearestSort
                cell.post = displayPost
                cell.enableCancel = self.currentDisplayList?.creatorUID == Auth.auth().currentUser?.uid
                cell.layer.cornerRadius = 1
                cell.layer.masksToBounds = true
                
                return cell
            }
                
            else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: gridCellId, for: indexPath) as! TestGridPhotoCell
                cell.delegate = self
                cell.post = displayPost
                return cell
            }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        var displayPost = (self.viewFilter?.isFiltering)! ? displayedPosts[indexPath.item] : fetchedPosts[indexPath.item]
        self.didTapPicture(post: displayPost)

    }
    
    // SORT FILTER HEADER
    
     func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: listHeaderId, for: indexPath) as! NewListViewControllerHeader
        header.currentDisplayList = self.currentDisplayList
        header.displayUser = self.displayUser
        header.viewFilter = self.viewFilter
        header.isFilteringText = self.isFilteringText
        header.postFormatInd = self.postFormatInd
//        header.heroImageUrl = self.heroImageUrl
        header.listDisplayEmojis = noCaptionFilterMostUsedEmojis
        header.delegate = self
//        header.searchBar = searchController.searchBar
        //        header.customBackgroundColor =  UIColor.init(white: 0, alpha: 0.2)
        
        return header
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        var height: CGFloat = 280 + 100 + 50 + 30 + 5
        // LIST URL HEIGHT
        height += (self.currentDisplayList?.listUrl == "" ) ? 0 : 15
        height += 40 // Emoji CollectionView

        // Header Sort with 5 Spacing
        return CGSize(width: view.frame.width, height: height)
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let item = self.fetchedPosts[indexPath.row].id
        let itemProvider = NSItemProvider(object: item as! NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            // Get last index path of table view.
            let section = collectionView.numberOfSections - 1
            let row = collectionView.numberOfItems(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }
        
        switch coordinator.proposal.operation
        {
        case .move:
            self.reorderItems(coordinator: coordinator, destinationIndexPath:destinationIndexPath, collectionView: collectionView)
            break
        case .cancel:
            return
        default:
            return
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if self.viewFilter?.filterSort == "Rank" {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        } else {
            return UICollectionViewDropProposal(operation: .cancel, intent: .unspecified)
        }
        
    }
    
    private func reorderItems(coordinator: UICollectionViewDropCoordinator, destinationIndexPath: IndexPath, collectionView: UICollectionView)
    {
        let items = coordinator.items
        if items.count == 1, let item = items.first, let sourceIndexPath = item.sourceIndexPath
        {
            var dIndexPath = destinationIndexPath
            if dIndexPath.row >= collectionView.numberOfItems(inSection: 0)
            {
                dIndexPath.row = collectionView.numberOfItems(inSection: 0) - 1
            }
            collectionView.performBatchUpdates({
                
                let tempPost = fetchedPosts.first(where: { (post) -> Bool in
                    post.id == item.dragItem.localObject as! String
                })
                self.fetchedPosts.remove(at: sourceIndexPath.row)
                self.fetchedPosts.insert(tempPost as! Post, at: dIndexPath.row)
                
                print("ListViewController | reorderItems | Moving \(sourceIndexPath.row) to \(dIndexPath.row)")
                
                collectionView.deleteItems(at: [sourceIndexPath])
                collectionView.insertItems(at: [dIndexPath])
                
                if self.viewFilter?.filterSort == "Rank" {
                    if self.currentDisplayList?.creatorUID == Auth.auth().currentUser?.uid {
                        do {
                            try self.rerankPostForList()
                        } catch {
                            print(error)
                        }
                    }
                }
            })
            
            coordinator.drop(items.first!.dragItem, toItemAt: dIndexPath)
            
        }
    }
    
    
    
    // Empty Data Set Delegates
    
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
        
        if (viewFilter?.isFiltering)! {
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
        
        if (self.viewFilter?.isFiltering)! {
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
        if (self.viewFilter?.isFiltering)! {
            self.openFilter()
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
    
// HEADER DELEGATES
    
    
    func didChangeToGridView() {
        print("ListViewController | Change to Grid View")
        self.postFormatInd = 0
        self.imageCollectionView.reloadData()
    }
    
    func didChangeToListView(){
        print("ListViewController | Change to Grid View")
        self.postFormatInd = 1
        self.imageCollectionView.reloadData()
    }
    
    func deleteList(list:List?){
        
        guard let list = list else {return}
        
        let deleteAlert = UIAlertController(title: "Delete", message: "Are You Sure? All Data Will Be Lost!", preferredStyle: UIAlertController.Style.alert)
        deleteAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            
            Database.deleteList(uploadList: list)
            self.delegate?.deleteList(list: list)
            self.navigationController?.popViewController(animated: true)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        present(deleteAlert, animated: true, completion: nil)
    }
    
    
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
            Database.handleUnfollowList(userUid: uid, followedList: followingList) {
                //                self.setupListFollowButton()
                self.alert(title: "", message: "\((self.currentDisplayList?.name)!) List UnFollowed")
            }
        } else {
            Database.handleFollowingList(userUid: uid, followedList: followingList) {
                //                self.setupListFollowButton()
                self.alert(title: "", message: "\((self.currentDisplayList?.name)!) List Followed")
            }
        }
    }
    
    
    func didTapListSetting() {
        let options = ListOptionsTableViewController()
        options.inputList = self.currentDisplayList
        let testNav = UINavigationController(rootViewController: options)
        
        let transition = CATransition()
        transition.duration = 0.5
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromRight
        transition.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
        view.window!.layer.add(transition, forKey: kCATransition)
        self.present(testNav, animated: true) {
            print("   Presenting List Option View")
        }

    }
    
    func didTapEditList() {
        print("Edit List")
    }
    
    func displayPostSocialUsers(post: Post, following: Bool) {
        print("Display Vote Users| Following: ",following)
        self.extShowUsersForPost(post: post, following: following)
    }
    
    func displayPostSocialLists(post: Post, following: Bool) {
        print("Display Lists| Following: ",following)
        self.extShowListsForPost(post: post, following: following)
    }
    
    func displayListFollowingUsers(list: List, following: Bool) {
        print("Display Users| Following: ",list.id)
        self.extShowUsersFollowingList(list: list, following: following)
    }
    
// CELL DELEGATES

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
    
//    func openFilter(){
//        let filterController = SearchFilterController()
//        filterController.delegate = self
//        filterController.searchFilter = self.viewFilter
//        self.navigationController?.pushViewController(filterController, animated: true)
//    }
    
    func openFilter(){
        
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
        postSearch.selectedScope = 0
        postSearch.searchController.searchBar.selectedScopeButtonIndex = 0
        
        self.navigationController?.pushViewController(postSearch, animated: true)

        
    }
    
    
    func didTapComment(post: Post) {
        self.extTapComment(post: post)
    }
    
    func didTapUser(post: Post) {
        self.extTapUser(post: post)
    }
    
    func didTapLocation(post: Post) {
        self.extTapLocation(post: post)
    }
    
    func didTapMessage(post: Post) {
        self.extTapMessage(post: post)
    }
    
    func refreshPost(post: Post) {
        let index = fetchedPosts.firstIndex { (fetchedPost) -> Bool in
            fetchedPost.id == post.id
        }
        
        // Update Cache
        let postId = post.id
        postCache[postId!] = post
    }

    
    func didTapUser(user: User) {
        self.extTapUserUid(uid: user.uid)
    }
    
    func didTapBookmark(post: Post) {
        let sharePhotoListController = SharePhotoListController()
        sharePhotoListController.uploadPost = post
        sharePhotoListController.isBookmarkingPost = true
        sharePhotoListController.delegate = self
        navigationController?.pushViewController(sharePhotoListController, animated: true)
    }
    
    func deletePostFromList(post: Post) {
        
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
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
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
    }
    



}
