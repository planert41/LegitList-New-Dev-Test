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

protocol LegitListViewControllerDelegate {
    func listSelected(list: List?)
    func deleteList(list:List?)
}


class LegitListViewController: UIViewController {

    var delegate: LegitListViewControllerDelegate?
    
    // MARK: - LIST/POST Objects
    

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
    

    //DISPLAY VARIABLES
    var fetchedPosts: [Post] = []
    var displayedPosts: [Post] = []
    var tempRank:[String:Int]? = [:]
    
    var postFormatInd: Int = 0
    // 0 Grid View
    // 1 List View
    // 2 Full View

    // MARK: - FILTERS

    
    var viewFilter: Filter = Filter.init(defaultSort: defaultRankSort) {
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
                self.isFilteringText = searchTerm
            } else {
                self.isFilteringText = nil
            }
            //        self.refreshPostsForFilter()
        }
    }
    var isFilteringText: String? = nil

    
    var noCaptionFilterEmojiCounts: [String:Int] = [:]
    var noCaptionFilterPlaceCounts: [String:Int] = [:]
    var noCaptionFilterCityCounts: [String:Int] = [:]
    
    
    // SEARCH RESULTS
    
    let searchTableView = PostSearchTableViewController()
    var hideSearchBar = false
    
//    // SEARCH REC TABLE VIEW
//    lazy var searchTableView : UITableView = {
//        let tv = UITableView()
//        tv.delegate = self
//        tv.dataSource = self
//        tv.estimatedRowHeight = 100
//        tv.allowsMultipleSelection = false
//        return tv
//    }()
//    
//    var searchTypeSegment = UISegmentedControl()
//
//    var selectedSearchType: Int = 0
//    var searchOptions = SearchBarOptions
//    var searchFiltering = false
//    
//    var searchUserText: String? = nil
//    var searchUser: User? = nil
//    var searchText: String? = nil
//    
//    
//    // SEARCH TEMPS
//    var displayEmojis:[Emoji] = []
//    var filteredEmojis:[Emoji] = []
//    
//    var displayPlaces: [String] = []
//    var filteredPlaces: [String] = []
//    var selectedPlace: String? = nil
//    var singleSelection = true
//    
//    var displayCity: [String] = []
//    var filteredCity: [String] = []
//    var selectedCity: String? = nil
//    
//    var allResultsDic: [String:String] = [:]
//    var defaultAllResults:[String] = []
//    var aggregateAllResults:[String] = []
//    var filteredAllResults:[String] = []
    
    // MARK: - Collection View Objects


    let gridCellId = "gridCellId"
    let listCellId = "listCellId"
    let listHeaderId = "listHeaderId"
    
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

    func setupNavigationItems(){
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.barTintColor = UIColor.clear
        self.navigationController?.navigationBar.tintColor = UIColor.clear
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        self.setNeedsStatusBarAppearanceUpdate()

//        navBackButton.addTarget(self, action: #selector(handleBackPressNav), for: .touchUpInside)
        
//        let barButton2 = UIBarButtonItem.init(customView: navBackButton)
//        self.navigationItem.leftBarButtonItem = barButton2
    }
    
    @objc func handleBackPressNav(){
        self.handleBack()
    }
    
    lazy var navBackButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        let icon = #imageLiteral(resourceName: "back_icon").withRenderingMode(.alwaysTemplate)

        button.setImage(icon, for: .normal)
        button.layer.backgroundColor = UIColor.white.cgColor
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
    
    override func viewWillAppear(_ animated: Bool) {
        self.setupNavigationItems()
    }
    
    // MARK: - VIEWDIDLOAD

    let headerHeight = 280 + UIApplication.shared.statusBarFrame.height

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("  START |  NewListCollectionView | ViewdidLoad")
        
        self.setupNavigationItems()
        
        self.edgesForExtendedLayout = UIRectEdge.top
        setupNavigationItems()
        setupCollectionView()
        
        self.view.addSubview(imageCollectionView)
        imageCollectionView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        self.view.addSubview(searchTableView.view)
        searchTableView.view.anchor(top: imageCollectionView.topAnchor, left: view.leftAnchor, bottom: imageCollectionView.bottomAnchor, right: view.rightAnchor, paddingTop: CGFloat(headerHeight - 8 - UIApplication.shared.statusBarFrame.height), paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        searchTableView.view.alpha = 0
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: ListViewController.refreshListViewNotificationName, object: nil)
        print("  END |  NewListCollectionView | ViewdidLoad")
        
        
        
        navBackButton.addTarget(self, action: #selector(handleBackPressNav), for: .touchUpInside)
        self.view.addSubview(navBackButton)
        navBackButton.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: UIApplication.shared.statusBarFrame.height + 10, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

        // Do any additional setup after loading the view.
    }
    
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
        if self.noCaptionFilterCityCounts.count == 0 {
            Database.countCityIds(posts: self.fetchedPosts) { (locationCounts) in
                self.noCaptionFilterCityCounts = locationCounts
//                self.searchTableView.initSearchSelections()
                print("   HomeView | NoFilter Location Count | \(locationCounts.count)")
            }
        }
        
        if self.noCaptionFilterPlaceCounts.count == 0 {
            Database.countLocationNames(posts: self.fetchedPosts) { (locationCounts) in
                self.noCaptionFilterPlaceCounts = locationCounts
//                self.searchTableView.initSearchSelections()
                print("   HomeView | NoFilter Location Name Count | \(locationCounts.count)")
            }
        }
        
        if self.noCaptionFilterEmojiCounts.count == 0 {
            Database.countEmojis(posts: self.fetchedPosts) { (emojiCounts) in
                self.noCaptionFilterEmojiCounts = emojiCounts
//                self.searchTableView.initSearchSelections()
                print("   HomeView | NoFilter Emoji Count | \(emojiCounts.count)")
                
            }
        }
        
        self.setupSearchTableView()
        
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
       
       func filterSortFetchedPosts(){
           
           self.updateNoFilterCounts()
           
           // Sort Recent Post By Listed Date
           var listSort: String = "Listed"
           if self.viewFilter.filterSort == defaultRecentSort {
               listSort = "Listed"
           } else {
               listSort = (self.viewFilter.filterSort)!
           }
           
           Database.sortPosts(inputPosts: self.fetchedPosts, selectedSort: listSort, selectedLocation: self.viewFilter.filterLocation, completion: { (sortedPosts) in
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
 
    
    @objc func refreshPostsForFilter(){
        self.clearAllPost()
        self.fetchPostsForList()
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
    }
    
    func clearAllPost(){
        self.fetchedPosts = []
        self.displayedPosts = []
    }
    

    
 

}

// MARK: - COLLECTION VIEW DELEGATE

extension LegitListViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDragDelegate, UICollectionViewDropDelegate, UICollectionViewDelegateFlowLayout {
    
    


    
    func setupCollectionView(){
        

        
        imageCollectionView.register(FullPictureCell.self, forCellWithReuseIdentifier: listCellId)
        imageCollectionView.register(TestGridPhotoCell.self, forCellWithReuseIdentifier: gridCellId)
//        imageCollectionView.register(NewListViewControllerHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: listHeaderId)
        imageCollectionView.register(LegitListViewHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: listHeaderId)

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
            var height: CGFloat = 35 //headerview = username userprofileimageview
            height += view.frame.width  // Picture
            height += 160
            height += 30
            height += 30 // Emoji Array + Star Rating
            //            height += 25    // Date Bar
            return CGSize(width: view.frame.width - 16, height: height)
        } else if self.postFormatInd == 0 {
            // GRID VIEW
            let width = (view.frame.width - 2 - 30) / 2
            return CGSize(width: width, height: width)
        } else {
            return CGSize(width: view.frame.width, height: view.frame.width)
        }

    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (self.viewFilter.isFiltering) ? displayedPosts.count : fetchedPosts.count

    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var displayPost = (self.viewFilter.isFiltering) ? displayedPosts[indexPath.item] : fetchedPosts[indexPath.item]
        
        if let tempRank = self.tempRank {
            displayPost.listedRank = tempRank[(displayPost.id)!]
        }
        
        if self.postFormatInd == 1 {
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
        }
            
        else if self.postFormatInd == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: gridCellId, for: indexPath) as! TestGridPhotoCell
            cell.delegate = self
            cell.showDistance = self.viewFilter.filterSort == defaultNearestSort
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
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: listHeaderId, for: indexPath) as! LegitListViewHeader
        
        header.currentDisplayList = self.currentDisplayList
        header.displayUser = self.displayUser
        header.viewFilter = self.viewFilter
        header.isFilteringText = self.isFilteringText
        header.postFormatInd = self.postFormatInd
//        header.heroImageUrl = self.heroImageUrl
        header.delegate = self
//        header.searchBar = searchController.searchBar
        //        header.customBackgroundColor =  UIColor.init(white: 0, alpha: 0.2)
        
        let sorted = self.noCaptionFilterEmojiCounts.sorted(by: {$0.value > $1.value})
        var topEmojis: [String] = []
        for (index,value) in sorted {
            if index.isSingleEmoji /*&& topEmojis.count < 4*/ {
                topEmojis.append(index)
            }
        }
        header.displayedEmojis = topEmojis
        
        
        return header
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        var height: CGFloat = 280 + 100 + 50 + 30 + 5
//        // LIST URL HEIGHT
//        height += (self.currentDisplayList?.listUrl == "" ) ? 0 : 15
//        height += 40 // Emoji CollectionView
        var height: CGFloat = headerHeight
        // Header Sort with 5 Spacing
        return CGSize(width: view.frame.width, height: height)
    }
    
    
    
}

extension LegitListViewController: TestGridPhotoCellDelegate, TestGridPhotoCellDelegateObjc, NewListPhotoCellDelegate, SharePhotoListControllerDelegate, LegitListViewHeaderDelegate, FullPictureCellDelegate{
    func didTapLike(post: Post) {
        
    }
    

        func didTapAddTag(addTag: String) {
            let tempAddTag = addTag.lowercased()
            
            guard let filterCaption = self.viewFilter.filterCaption?.lowercased() else {
                self.viewFilter.filterCaption = tempAddTag
                self.refreshPostsForFilter()
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
                    
            self.refreshPostsForFilter()
        }
    
    
    func filterContentForSearchText(_ searchText: String) {
        self.searchTableView.filterContentForSearchText(searchText)
    }
    
    func handleFilter() {
        self.searchTableView.handleFilter()
    }
    
    func showSearchView() {
        self.setupSearchTableView()
        self.scrollToHeader()

        UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.transitionCrossDissolve, animations:
            {
                self.searchTableView.view.alpha = 1
        }
            , completion: { (finished: Bool) in
        })
        self.imageCollectionView.isScrollEnabled = false
    }
    func hideSearchView() {
        UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.transitionCrossDissolve, animations:
            {
                self.searchTableView.view.alpha = 0
        }
            , completion: { (finished: Bool) in
        })
        self.imageCollectionView.isScrollEnabled = true

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
    
    func headerSortSelected(sort: String) {
        self.viewFilter.filterSort = sort
        
        if (self.viewFilter.filterSort == HeaderSortOptions[1] && self.viewFilter.filterLocation == nil){
            print("Sort by Nearest, No Location, Look up Current Location")
            LocationSingleton.sharedInstance.determineCurrentLocation()
            let when = DispatchTime.now() + defaultGeoWaitTime // change 2 to desired number of seconds
            DispatchQueue.main.asyncAfter(deadline: when) {
                //Delay for 1 second to find current location
                self.viewFilter.filterLocation = CurrentUser.currentLocation
                self.refreshPostsForFilter()
            }
        } else {
            self.refreshPostsForFilter()
        }
        
        print("Filter Sort is ", self.viewFilter.filterSort)
    }
    
    @objc func didChangeToGridView() {
        print("ListViewController | Change to Grid View")
        self.postFormatInd = 0
        self.imageCollectionView.reloadData()
    }
    
    @objc func didChangeToListView() {
        print("ListViewController | Change to List View")
        self.postFormatInd = 1
        self.imageCollectionView.reloadData()
    }
    
    
    func didTapPicture(post: Post) {
        print("Function: \(#function), line: \(#line)")
        let pictureController = SinglePostView()
        pictureController.post = post
        
        navigationController?.pushViewController(pictureController, animated: true)
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
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = userId
        self.navigationController?.pushViewController(userProfileController, animated: true)
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
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromBottom
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
    
    
}

// MARK: - SEARCH FUNCTIONS


extension LegitListViewController: PostSearchTableViewControllerDelegate {
    func filterSelected(filter: Filter) {
        self.hideSearchView()
        self.viewFilter = filter
        self.refreshPostsForFilter()
    }
    
    
    func setupSearchTableView(){
        self.searchTableView.defaultEmojiCounts = self.noCaptionFilterEmojiCounts
        self.searchTableView.defaultPlaceCounts = self.noCaptionFilterPlaceCounts
        self.searchTableView.defaultCityCounts = self.noCaptionFilterCityCounts
        self.searchTableView.initSearchSelections()
        self.searchTableView.delegate = self
        self.searchTableView.viewFilter = self.viewFilter
        
    }
    
    
}

// MARK: - EMPTY SET DELEGATE


extension LegitListViewController: EmptyDataSetSource, EmptyDataSetDelegate {
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

