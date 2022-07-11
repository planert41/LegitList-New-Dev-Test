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
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth
import SVProgressHUD
import CoreLocation


class ListViewControllerNew: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UISearchBarDelegate, DiscoverListCellDelegate, UIScrollViewDelegate, DiscoverUserCellDelegate, DiscoverListCellNewDelegate {
   
    static let refreshListNotificationName = NSNotification.Name(rawValue: "RefreshList")
    static let CurrentUserLoadedNotificationName = NSNotification.Name(rawValue: "LoadUser")

// FETCH INPUTS
    
    var inputUid: String? {
        didSet {
            if let _ = inputUid {
                self.fetchUser()
            }
        }
    }
    
    func fetchUser(){
        guard let uid = inputUid else {
            print("User Profile: Fetch Posts Error, No UID")
            return
        }
        
        Database.fetchUserWithUID(uid: uid) { (fetchedUser) in
            self.inputUser = fetchedUser
            print("SingleUserprofileController | Fetched User | \(uid)")
        }
    }
    
    var inputUser: User? {
        didSet {
            self.fetchLists()
            self.loadCurrentUserPosts()
            if let emojis = inputUser?.mostUsedEmojis {
                self.mostUsedEmojis = inputUser?.mostUsedEmojis
            }
            
            if let cities = inputUser?.mostUsedCities {
                self.mostUsedCities = inputUser?.mostUsedCities
            }
        }
    }
    var mostUsedEmojis: [String]? = []
    var mostUsedCities: [String]? = []
    
    var allLists: [List] = []
    var followingLists: [List] = []
    var yourLists: [List] = []
    
    var userPosts:[Post] = [] {
        didSet {
            Database.countMostUsedEmojis(posts: userPosts) { emojis in
                self.mostUsedEmojis = emojis
            }
            Database.countMostUsedCities(posts: userPosts) { cities in
                self.mostUsedCities
            }
            self.userPostsDic.removeAll()
            for post in userPosts {
                if let id = post.id {
                    userPostsDic[id] = post
                }
            }
//            self.updateUserPostFavCounts()
        }
    }
    
    var userPostsDic: [String:Post] = [:]

//    var userPostsFavCounts:[String:Int] = [:]
    var userFavs = extraRatingEmojisForList
    var filteredUserFavs: [String] = []
    var userFavsLists:[String: List] = [:]

    
//    var userPostsCityCounts:[String:Int] = [:]
    var userCity: [String] = []
    var filteredUserCity: [String] = []
    var userCityLists:[String: List] = [:]

    
    func loadCurrentUserPosts(){
        if self.userPosts.count == 0 {
            print("No Current User Posts. Fetch Posts | ListViewControllerNew")
            if self.isViewLoaded && self.view.window != nil {
                SVProgressHUD.show(withStatus: "Refreshing Lists")
            }
            guard let uid = self.inputUser?.uid else {
                print("No Current User UID")
                if self.isViewLoaded && self.view.window != nil {
                    SVProgressHUD.dismiss()
                }
                return
            }
            Database.fetchAllPostWithUID(creatoruid: uid) { fetchedPosts in
                self.userPosts = fetchedPosts
                
                Database.refreshCurrentUserMostUsed(posts: fetchedPosts) {
                    self.createUserAutoLists()
                }
            }
        } else {
            self.createUserAutoLists()
        }
    }
    
    func createUserAutoLists() {
        self.userFavs = extraRatingEmojisForList + (self.mostUsedEmojis ?? [])
        self.userCity = self.mostUsedCities ?? []
        print("ListViewControllerNew - Most Used Emojis: \(CurrentUser.mostUsedEmojis.count) | Most Used Cities \(CurrentUser.mostUsedCities.count)")
        self.createTempListsForUserFavs()
        self.createTempListsForUserCities()
        if self.isViewLoaded && self.view.window != nil {
            SVProgressHUD.dismiss()
        }
        self.tableView.reloadData()
    }
    
//    func updateUserPostFavCounts() {
//        var tempCounts:[String:Int] = [:]
//        var tempCityCounts:[String:Int] = [:]
//
//        for post in userPosts {
//            if let x = post.ratingEmoji {
//                tempCounts[x] = (tempCounts[x] ?? 0) + 1
//            }
//            if let x = post.locationSummaryID {
//                tempCityCounts[x] = (tempCityCounts[x] ?? 0) + 1
//            }
//        }
//        self.userPostsFavCounts = tempCounts
//        self.userPostsCityCounts = tempCityCounts
//    }
    
    
    func createTempListsForUserCities() {
        print("Creating Temp Location Lists \(CurrentUser.posts.count) User Posts | ListViewControllerNew")

        var tempListPostIds:[String:[String: Double]] = [:]
        var tempLocations:[String] = []
        var tempLists:[String: List] = [:]
        var tempListsLocation:[String: CLLocation] = [:]
        var tempListsDates:[String: Date] = [:]

        
        // Loop through posts for Locations
        for (id, post) in self.userPostsDic {
            if self.isFilteringLegit && post.ratingEmoji == nil {
                continue
            }
            
            if post.locationSummaryID != nil {
                guard let city = post.locationSummaryID else {return}
                if !tempLocations.contains(city) {
                    tempLocations.append(city)
                    if let loc = post.locationGPS {
                        tempListsLocation[city] = loc
                    }
                    tempListPostIds[city] = [:]
                }
                
                if let loc = post.locationGPS {
                    if tempListsLocation[city] == nil {
                        tempListsLocation[city] = loc
                    }
                }
                
                if post.creationDate > (tempListsDates[city] ?? Date.distantPast) {
                    tempListsDates[city] = post.creationDate
                }
                
                // Update Post ID to temp City
                var temp = tempListPostIds[city]
                temp?[id] = post.creationSecondsFrom1970 ?? 0
                tempListPostIds[city] = temp
            }
        }
        
        // LOOP through city names to create default lists
        for city in tempLocations {
            var temp = List.init(id: city, name: city.capitalizingFirstLetter(), publicList: 0)
            temp.creatorUID = inputUser?.uid
            var postIds = tempListPostIds[city]
            temp.postIds = postIds ?? [:]
            temp.listGPS = tempListsLocation[city]

            if let location = CurrentUser.currentLocation {
                temp.listDistance = temp.listGPS?.distance(from: location)
            }
            temp.mostRecentDate = tempListsDates[city] ?? Date.distantPast
            temp.isLegitList = self.isFilteringLegit
            
            if (postIds?.count) ?? 0 > 0 {
                let latestPost = postIds!.max { a, b in a.value < b.value }
                if let post = self.userPostsDic[(latestPost?.key)!] {
                    var imageUrl = post.imageUrls.first
                    temp.heroImageUrl = imageUrl
                }
            }
            tempLists[city] = temp
//            print(name, temp.postIds?.count, "Posts")
        }

        // SORT BY NUMBER OF POSTS
        var allLists: [List] = []
        var sortedCities:[String] = []
        for (city, list) in tempLists {
            allLists.append(list)
        }
        
        
        allLists.sort { p1, p2 in
            return p1.postIds?.count ?? 0 > p2.postIds?.count ?? 0
        }
        
        for list in allLists {
            sortedCities.append(list.id ?? "")
        }
                
        self.userCity = sortedCities
        self.userCityLists = tempLists
    }
    
    
    func createTempListsForUserFavs() {
        print("Creating Temp Fav Lists \(self.userPosts.count) User Posts | ListViewControllerNew")

        var tempListPostIds:[String:[String: Double]] = [:]
        var tempLists:[String: List] = [:]

        // Create empty sets and default lists
        for emoji in userFavs {
            tempListPostIds[emoji] = [:]
        }
        
        // Loop through posts for rating emojis
        for (id, post) in self.userPostsDic {
            // SKIP NON LEGIT POSTS IF FILTERING LEGIT
            if self.isFilteringLegit && post.ratingEmoji == nil {
                continue
            }
            
            if post.ratingEmoji != nil {
                guard let emoji = post.ratingEmoji else {return}
                var temp = tempListPostIds[emoji]
                temp?[id] = post.creationSecondsFrom1970 ?? 0
                tempListPostIds[emoji] = temp
            }
            
            if post.nonRatingEmoji.count > 0 {
                for emoji in post.nonRatingEmoji {
                    var temp = tempListPostIds[emoji]
                    temp?[id] = post.creationSecondsFrom1970 ?? 0
                    tempListPostIds[emoji] = temp
                }
            }
        }
        
        // Attach post ids to rating lists
        for emoji in userFavs {
            
            // CREATE EMPTY LIST
            var name: String! = ""
            if let ratingName = extraRatingEmojisDic[emoji] {
                name = ratingName.capitalized
            } else if let emojiName = EmojiDictionary[emoji] {
                name = emojiName.capitalized
            }
            var temp = List.init(id: emoji, name: "\(emoji) \(name!)", publicList: 0)
            temp.isRatingList = true
            temp.creatorUID = inputUser?.uid
            temp.isLegitList = self.isFilteringLegit || extraRatingEmojis.contains(emoji)

            var postIds = tempListPostIds[emoji]
            
            // ATTACH ONLY NON ZERO LISTS
            if (postIds?.count ?? 0) > 0 {
                temp.postIds = postIds ?? [:]
                
                if (postIds?.count) ?? 0 > 0 {
                    let latestPost = postIds!.max { a, b in a.value < b.value }
                    if let post = self.userPostsDic[(latestPost?.key)!] {
                        var imageUrl = post.imageUrls.first
                        temp.heroImageUrl = imageUrl
                    }
                }
                
                tempLists[emoji] = temp
            }
        }
        self.userFavsLists = tempLists
        
        self.tableView.reloadData()
    }
    
    
    

    
    
    var fetchedList: [List] = []
    var filteredDisplayList: [List] = []
    
    var fetchTypeSegment = UISegmentedControl()
    var fetchTypeOptions: [String] = ListOptions
    var fetchType: String = ListDefault {
        didSet {
            updateFilterLegitButton()
            if self.fetchType == ListAll {
                self.fetchAllLists()
            } else if self.fetchType == ListFav || self.fetchType == ListCities {
                self.loadCurrentUserPosts()
            } else {
                self.sortDisplayLists()
            }
        }
    }
    

    let listCellId = "ListCellId"
    let userCellId = "UserCellId"
    
    
    var sortOptions: [String] = DiscoverSortOptions
    var selectedSort: String = DiscoverSortDefault {
        didSet{
            self.sortDisplayLists()
            setupSortButton()
            if let index = sortOptions.index(of: self.selectedSort) {
                if sortSegmentControl.selectedSegmentIndex != index {
                    sortSegmentControl.selectedSegmentIndex = index
                }
            }
        }
    }
    
    var isFiltering: Bool = false {
        didSet{
            self.tableView.reloadData()
        }
    }

    
    let actionView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    lazy var tableView : UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        tv.estimatedRowHeight = 100
        tv.allowsMultipleSelection = false
        return tv
    }()
    
    var searchBar = UISearchBar()
    

    
    lazy var sortButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(showDropDown), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.white.cgColor
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitleColor(UIColor.darkGray, for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 13)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.gray.cgColor
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        return button
    }()
    
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
        print("Display Friends For Current User| ",self.inputUser?.uid)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayAllUsers = true
        postSocialController.displayUserFollowing = true
        postSocialController.displayUser = true
        postSocialController.inputUser = self.inputUser
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    let buttonBar = UIView()

    
    
    let createNewListButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        button.setImage(#imageLiteral(resourceName: "add_list").withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTitle(" New List", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(didTapCreateNewList), for: .touchUpInside)
        button.tintColor = UIColor.ianWhiteColor()
        button.backgroundColor = UIColor.mainBlue()
        return button
    }()
    
    @objc func didTapCreateNewList() {
        print("Did Tap Create New List | User Profile")
        self.extCreateNewList()
    }
    
    func showHideAddListButton() {
//        self.createNewListButton.isHidden = !(fetchType == ListYours)
//        Always Show
        self.createNewListButton.isHidden = false
    }
    
    @objc func didCreateNewList() {
        print("New Lists Created | Discover Controller")
        self.selectedSort = sortNew
        self.fetchLists()
    }
    
    var sortSegmentControl: UISegmentedControl = UISegmentedControl(items: ItemSortOptions)
    var segmentWidth_selected: CGFloat = 110.0
    var segmentWidth_unselected: CGFloat = 80.0
    
    
    @objc func deletedList(_ notification: NSNotification) {

         if let listId = notification.userInfo?["deleteListId"] as? String {
            print("Deleted List \(listId) Notification ListViewControllerNew")
            
            self.fetchedList.removeAll { (list) -> Bool in
                list.id == listId
            }
            
            self.filteredDisplayList.removeAll { (list) -> Bool in
                list.id == listId
            }
            
            self.tableView.reloadData()
         }
    }
    
    @objc func autoLoadUser(){
        print("ListViewControllerNew - Auto Load User | \(self.mostUsedEmojis?.count) Emojis | \(self.mostUsedCities?.count) Cities")
        self.createUserAutoLists()
    }
    
    var isFilteringLegit: Bool = false {
        didSet {
            createUserAutoLists()
        }
    }
    
    lazy var detailLabel: PaddedUILabel = {
        let ul = PaddedUILabel()
        ul.isUserInteractionEnabled = false
        ul.numberOfLines = 0
        ul.textAlignment = NSTextAlignment.center
        ul.font = UIFont(name: "Poppins-Bold", size: 12)
        ul.textColor = UIColor.darkGray
        ul.backgroundColor = UIColor.lightSelectedColor()
        ul.alpha = 1
        ul.layer.cornerRadius = 10
        ul.clipsToBounds = true
        return ul
    }()
    
    let buttonSemiAlpha: CGFloat = 0.8
    
    let filterLegitButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "legit_icon"), for: .normal)
        button.addTarget(self, action: #selector(filterLegitPosts), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.white.cgColor
        button.layer.cornerRadius = button.frame.width/2
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor.selectedColor().cgColor
        button.layer.borderWidth = 1
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()
    
    func updateFilterLegitButton() {
        filterLegitButton.backgroundColor = self.isFilteringLegit ? UIColor.lightSelectedColor() : UIColor.ianWhiteColor()
        filterLegitButton.alpha = self.isFilteringLegit ? 1 : buttonSemiAlpha
        filterLegitButton.isHidden = (self.fetchType != ListFav)
        detailLabel.isHidden = !(self.isFilteringLegit && !filterLegitButton.isHidden)
        detailLabel.text = "Top Posts"
        detailLabel.sizeToFit()
        detailLabel.textColor = self.isFilteringLegit ? UIColor.customRedColor() : UIColor.gray

    }
    
    @objc func filterLegitPosts() {
        self.isFilteringLegit = !self.isFilteringLegit
        self.updateFilterLegitButton()
        print("Tab List View | filterLegitPosts - \(self.isFilteringLegit)")
//
//        self.updateDetailLabel()
//        self.refreshPostsForFilter()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(didCreateNewList), name:TabListViewController.refreshListNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sortLists), name:TabListViewController.newFollowedListNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deletedList), name:MainTabBarController.deleteList, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(locationDenied), name: AppDelegate.LocationDeniedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(locationUpdated), name: AppDelegate.LocationUpdatedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(autoLoadUser), name:ListViewControllerNew.CurrentUserLoadedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.newUserPost(_:)), name: MainTabBarController.newUserPost, object: nil)

        setupNavigationItems()
        setupTypeSegment()
        setupSortButton()
        setupDropDown()
        setupTableView()
        fetchLists()
        loadCurrentUserPosts()
        
        view.addSubview(actionView)
        actionView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        actionView.backgroundColor = UIColor.white
        

        actionView.addSubview(fetchTypeSegment)
        fetchTypeSegment.anchor(top: actionView.topAnchor, left: actionView.leftAnchor, bottom: actionView.bottomAnchor, right: actionView.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)

        
        view.addSubview(tableView)
        tableView.anchor(top: actionView.bottomAnchor, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        setupSegmentControl()
        view.addSubview(sortSegmentControl)
        sortSegmentControl.anchor(top: nil, left: nil, bottom: bottomLayoutGuide.topAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 10, width: 0, height: 40)
        sortSegmentControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        sortSegmentControl.alpha = 0.9
        self.refreshSort(sender: sortSegmentControl)
        
        
    // FILTER LEGIT BUTTON
        view.addSubview(filterLegitButton)
        filterLegitButton.anchor(top: nil, left: nil, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 12, paddingLeft: 0, paddingBottom: 10, paddingRight: 15, width: 40, height: 40)
        filterLegitButton.layer.cornerRadius = 40/2
        filterLegitButton.isHidden = true

        
    // DETAIL LABEL
        view.addSubview(detailLabel)
        detailLabel.anchor(top: nil, left: nil, bottom: nil, right: filterLegitButton.leftAnchor, paddingTop: 4, paddingLeft: 10, paddingBottom: 10, paddingRight: 2, width: 0, height: 0)
        detailLabel.centerYAnchor.constraint(equalTo: filterLegitButton.centerYAnchor).isActive = true
        detailLabel.isHidden = true
        
        updateFilterLegitButton()

//        let addNewListButtonWidth: CGFloat = 50
//        view.addSubview(createNewListButton)
//        createNewListButton.anchor(top: nil, left: nil, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 20, paddingRight: 15, width: 0, height: 40)
//        createNewListButton.layer.cornerRadius = 5
//        createNewListButton.layer.masksToBounds = true
//        createNewListButton.sizeToFit()
//        self.showHideAddListButton()
        
    }
    
    @objc func newUserPost(_ notification: NSNotification) {

        let postId = (notification.userInfo?["postId"] ?? "")! as! String
        let userId = (notification.userInfo?["uid"] ?? "")! as! String
        
        var tuserId: String! = userId
        var tpostId: String! = postId
        
        // Check for new post that was edited or uploaded
        if newPost != nil && newPostId != nil {#imageLiteral(resourceName: "icons8-hash-30.png")
            guard let newPost = newPost else {return}
            let tempListIds = newPost.creatorListId

            loadCurrentUserPosts()
            if (tempListIds?.count ?? 0) > 0 {
                fetchLists()
            }
        } else {

        }
    }

    func setupSegmentControl() {
        sortSegmentControl = UISegmentedControl(items: ItemSortOptions)
        sortSegmentControl.selectedSegmentIndex = 0
        sortSegmentControl.addTarget(self, action: #selector(selectItemSort), for: .valueChanged)
        sortSegmentControl.backgroundColor = UIColor.white
        sortSegmentControl.tintColor = UIColor.oldLegitColor()
        sortSegmentControl.layer.borderWidth = 1
        sortSegmentControl.layer.borderColor = UIColor.lightGray.cgColor
        if #available(iOS 13.0, *) {
            sortSegmentControl.selectedSegmentTintColor = UIColor.mainBlue()
        }
        
        sortSegmentControl.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 14), NSAttributedString.Key.foregroundColor: UIColor.gray], for: .normal)
        sortSegmentControl.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 13), NSAttributedString.Key.foregroundColor: UIColor.ianWhiteColor()], for: .selected)
    }
    
    @objc func selectItemSort(sender: UISegmentedControl) {
        let selectedSort = ItemSortOptions[sender.selectedSegmentIndex]
        print("DiscoverItemHeader | \(selectedSort) | selectItemSort")

        self.refreshSort(sender: sender)
        self.selectedSort = selectedSort
    }
    
    @objc func refreshSort(sender: UISegmentedControl) {
        let selectedSort = ItemSortOptions[sender.selectedSegmentIndex]
        
        for (index, sortOptions) in ItemSortOptions.enumerated()
        {
            var isSelected = (index == sender.selectedSegmentIndex)
            var displayFilter = (isSelected) ? "Sort \(sortOptions)" : sortOptions
            sender.setTitle(displayFilter, forSegmentAt: index)
            sender.setWidth((isSelected) ? 90 : 60, forSegmentAt: index)
        }
    }
    

    func fetchLists() {
        if self.fetchType != ListAll {
            Database.fetchAllListsForUser(userUid: self.inputUser?.uid) { (userLists) in
                self.yourLists = userLists.filter({ (list) -> Bool in
                    list.creatorUID == self.inputUser?.uid
//                    CurrentUser.listIds.contains(list.id!)
                })
                self.followingLists = userLists.filter({ (list) -> Bool in
                    list.creatorUID != self.inputUser?.uid
//                    CurrentUser.followedListIds.contains(list.id!)
                })
                self.updateSegmentListCount()
                self.sortDisplayLists()
            }
        } else {
            self.fetchAllLists()
        }
    }
    
    func fetchAllLists() {
        Database.fetchALLLists { (allLists) in
            self.allLists = allLists
            self.sortLists()
        }
    }
    
    @objc func locationUpdated() {
        if self.isPresented  {
            if selectedSort == sortNearest {
                self.fetchLists()
                print("ListViewControllerNew Location UPDATED | \(CurrentUser.currentLocation)")
            }
        }
    }
    
    @objc func locationDenied() {
        if self.isPresented {
            self.missingLocAlert()
            self.sortSegmentControl.selectedSegmentIndex = ItemSortOptions.index(of: sortNew) ?? 0
            self.selectItemSort(sender: self.sortSegmentControl)
            print("ListViewControllerNew Location Denied Function")
        }
    }
    
    @objc func sortLists() {
        self.yourLists = allLists.filter({ (list) -> Bool in
            list.creatorUID == self.inputUser?.uid
//            CurrentUser.listIds.contains(list.id!)
        })
        self.followingLists = allLists.filter({ (list) -> Bool in
            list.creatorUID != self.inputUser?.uid

//            CurrentUser.followedListIds.contains(list.id!)
        })
        print("Fetched All Lists | \(self.allLists.count) All Lists, \(self.yourLists.count) Your Lists, \(self.yourLists.count) Following Lists")
        self.updateSegmentListCount()
        self.sortDisplayLists()
    }
    
    func sortDisplayLists() {
        var tempLists: [List] = []
        if self.fetchType == ListYours {
            tempLists = self.yourLists
        } else if self.fetchType == ListFollowing {
            tempLists = self.followingLists
        } else if self.fetchType == ListAll {
            tempLists = self.allLists
        } else if self.fetchType == ListCities {
            tempLists = Array(self.userCityLists.values)
        }
        
        if self.selectedSort == sortNearest && CurrentUser.currentLocation == nil {
            LocationSingleton.sharedInstance.determineCurrentLocation()
            print("ListViewControllerNew Missing Location")
            return
        }
        
        Database.sortList(inputList: tempLists, sortInput: self.selectedSort, completion: { (lists) in
            print("\(self.fetchType) : \(lists.count) Lists : \(self.selectedSort) | sortDisplayLists")
            if self.fetchType == ListYours || self.fetchType == ListFollowing {
                self.fetchedList = lists
                self.filteredDisplayList = lists
            } else if self.fetchType == ListCities {
                var tempCities: [String] = []
                for list in lists {
                    if let id = list.id {
                        tempCities.append(id)
                    }
                }
                self.userCity = tempCities
                self.filteredUserCity = tempCities
            }

            self.tableView.refreshControl?.endRefreshing()
            self.tableView.reloadData()
        })
        
    }
    

    
    
    func setupSortButton(){
        
        var attributedTitle = NSMutableAttributedString()
        
        let sortTitle = NSAttributedString(string: self.selectedSort + " ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray, NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 15)])
        attributedTitle.append(sortTitle)
        
        guard let legitIcon = #imageLiteral(resourceName: "iconDropdown").withRenderingMode(.alwaysOriginal).resizeVI(newSize: CGSize(width: 12, height: 12)) else {return}
        let legitImage = NSTextAttachment()
        legitImage.bounds = CGRect(x: 0, y: ((sortButton.titleLabel?.font.capHeight)! - legitIcon.size.height).rounded() / 2, width: legitIcon.size.width, height: legitIcon.size.height)
        legitImage.image = legitIcon
        let legitImageString = NSAttributedString(attachment: legitImage)
        attributedTitle.append(legitImageString)
        self.sortButton.setAttributedTitle(attributedTitle, for: .normal)
        
//        self.sortButton.attributedTitle(for: .normal) = attributedTitle

//        self.sortButton.setTitle(self.selectedSort, for: .normal)
    }
    
    var newCellId = "newCellId"
    
    func setupTableView(){
        tableView.register(SearchResultsCell.self, forCellReuseIdentifier: listCellId)
//        tableView.register(UserAndListCell.self, forCellReuseIdentifier: newCellId)
        tableView.register(MainTabListCell.self, forCellReuseIdentifier: newCellId)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshAll), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.alwaysBounceVertical = true
        tableView.keyboardDismissMode = .onDrag
        tableView.delegate = self

    }
    
    func setupTypeSegment(){
        fetchTypeSegment = UISegmentedControl(items: fetchTypeOptions)
        fetchTypeSegment.selectedSegmentIndex = fetchTypeOptions.firstIndex(of: self.fetchType) ?? 0
        fetchTypeSegment.selectedSegmentTintColor = UIColor.ianLegitColor()
        fetchTypeSegment.addTarget(self, action: #selector(selectFetchType), for: .valueChanged)
        fetchTypeSegment.backgroundColor = .white
        fetchTypeSegment.tintColor = .white
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        fetchTypeSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: 16), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
        fetchTypeSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(font: .avenirNextBold, size: 16), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)
//        fetchTypeSegment.setTitleTextAttributes([NSAttributedString.Key.font: HeaderFontSizeDefault], for: .normal)
        updateSegmentListCount()
    }
    
    func updateSegmentListCount() {
        if self.fetchTypeSegment.numberOfSegments > 0 {
//            self.fetchTypeSegment.setTitle("\(ListYours) \(String(self.yourLists.count) ?? "")", forSegmentAt: 0)
//            self.fetchTypeSegment.setTitle("\(ListFollowing) \(String(self.followingLists.count) ?? "")", forSegmentAt: 1)
        }
    }
    
    func underlineSegment(segment: Int? = 0){
//        let segmentWidth = (self.fetchTypeSegment.frame.width ) / CGFloat(self.fetchTypeSegment.numberOfSegments)
        let segmentWidth = 100 as CGFloat
        let tempX = self.buttonBar.frame.origin.x
        UIView.animate(withDuration: 0.3) {
            self.buttonBar.frame.origin.x = self.fetchTypeSegment.center.x - (segmentWidth) + (segmentWidth + 10) * CGFloat(segment ?? 0)
        }
    }
    
    @objc func selectFetchType(sender: UISegmentedControl) {
        self.fetchType = self.fetchTypeOptions[sender.selectedSegmentIndex]
        self.underlineSegment(segment: sender.selectedSegmentIndex)
        self.sortSegmentControl.isHidden = (self.fetchType == ListFav /*|| self.fetchType == ListCities*/)
        print("DiscoverController | Type Selected | \(self.fetchType)")
    }
    
    var displayBack: Bool = true {
        didSet{
            setupNavigationItems()
        }
    }
    

    let navBackButton = navBackButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))

    let navUserButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "profile_unselected"), for: .normal)
//        button.addTarget(self, action: #selector(openUserListFilter), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.white.cgColor
        button.layer.cornerRadius = button.frame.width/2
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.layer.borderWidth = 1
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    func setupNavigationItems(){
        //        navigationItem.title = "Manage Lists"
        
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.isTranslucent = false

        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
        navigationController?.navigationBar.backgroundColor = UIColor.white
        self.setNeedsStatusBarAppearanceUpdate()

        navigationController?.navigationBar.barTintColor = UIColor.white
        navigationController?.navigationBar.tintColor = UIColor.white
        // REMOVES THE 1PX BOTTOM LINE IN NAV BAR
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationItem.titleView = searchBar
//        navigationController?.navigationBar.backgroundColor = UIColor.ianLegitColor()
        searchBar.sizeToFit()
        searchBar.delegate = self
//        searchBar.showsCancelButton = false
        
        searchBar.barTintColor = UIColor.white
        searchBar.tintColor = UIColor.ianLegitColor()
        searchBar.backgroundColor = UIColor.white
        searchBar.backgroundImage = UIImage()
        searchBar.layer.borderWidth = 0
        definesPresentationContext = false
        
        searchBar.layer.cornerRadius = 5
        searchBar.layer.masksToBounds = true
        searchBar.clipsToBounds = true
        searchBar.searchBarStyle = .default
        searchBar.isTranslucent = false
        
//        searchBar.layer.borderWidth = 1
//        searchBar.layer.borderColor = UIColor.lightGray.cgColor
        searchBar.placeholder = "Search by emojis or words"
        //        defaultSearchBar.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        //        defaultSearchBar.showsCancelButton = true
        

        var iconImage = #imageLiteral(resourceName: "search_tab_fill").withRenderingMode(.alwaysTemplate)
        searchBar.setImage(iconImage, for: .search, state: .normal)
        searchBar.setSerchTextcolor(color: UIColor.ianLegitColor())
        var searchTextField: UITextField? = searchBar.value(forKey: "searchField") as? UITextField
        if searchTextField!.responds(to: #selector(getter: UITextField.attributedPlaceholder)) {
            let attributeDict = [NSAttributedString.Key.foregroundColor: UIColor.gray]
            searchTextField!.attributedPlaceholder = NSAttributedString(string: "Search Lists", attributes: attributeDict)
        }
        
        let textFieldInsideUISearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.textColor = UIColor.ianLegitColor()
        //        textFieldInsideUISearchBar?.font = textFieldInsideUISearchBar?.font?.withSize(12)

        
        for s in searchBar.subviews[0].subviews {
            if s is UITextField {
                s.layer.borderWidth = 0.5
                s.layer.borderColor = UIColor.gray.cgColor
                s.layer.cornerRadius = 5
                s.clipsToBounds = true
                s.layer.backgroundColor = UIColor.clear.cgColor
                s.backgroundColor = UIColor.white
            }
        }
        
        
        
//        navFriendButton.addTarget(self, action: #selector(openFriends), for: .touchUpInside)
//        let friendButton = UIBarButtonItem.init(customView: navFriendButton)
//        navigationItem.rightBarButtonItem = friendButton
        
        
//        let sortNavButton = UIBarButtonItem.init(customView: sortButton)
//        navigationItem.rightBarButtonItem = sortNavButton
//
//        self.view.addSubview(dropDownMenu)
//        dropDownMenu.anchor(top: topLayoutGuide.bottomAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 50, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        
        let addNewListButtonWidth: CGFloat = 50
//        view.addSubview(createNewListButton)
//        createNewListButton.anchor(top: nil, left: nil, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 20, paddingRight: 15, width: 0, height: 40)
        
        createNewListButton.layer.cornerRadius = 5
        createNewListButton.layer.masksToBounds = true
        createNewListButton.sizeToFit()
        createNewListButton.addTarget(self, action: #selector(didTapCreateNewList), for: .touchUpInside)
        
        
        if let imgUrl = inputUser?.profileImageUrl {
            let temp = CustomImageView()
            temp.loadImage(urlString: imgUrl)
            navUserButton.setImage(temp.image?.resizeVI(newSize: CGSize(width: 30, height: 30)), for: .normal)
        }
        
        if (inputUser?.uid == Auth.auth().currentUser?.uid) {
            let addNavButton = UIBarButtonItem.init(customView: createNewListButton)
            navigationItem.rightBarButtonItem = addNavButton
        } else {
            let addUserButton = UIBarButtonItem.init(customView: navUserButton)
            navigationItem.rightBarButtonItem = addUserButton
        }
        
        // Nav Back Button
        navBackButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        let backButton = UIBarButtonItem.init(customView: navBackButton)
        if displayBack {
            self.navigationItem.leftBarButtonItem = backButton
//            self.navigationItem.leftBarButtonItems = [backButton, userNameButton]
        } else {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem()
        }
        
        // NAV USER BUTTON
//        if

//        self.showHideAddListButton()

        
    }

    
    
    
    var dropDownMenu = DropDown()
    func setupDropDown(){
        dropDownMenu.anchorView = sortButton
        dropDownMenu.dismissMode = .automatic
        dropDownMenu.textColor = UIColor.gray
        dropDownMenu.textFont = UIFont(name: "Poppins-Bold", size: 17)!
        dropDownMenu.backgroundColor = UIColor.white
        dropDownMenu.selectionBackgroundColor = UIColor.ianLegitColor().withAlphaComponent(0.75)
        dropDownMenu.cellHeight = 50
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        dropDownMenu.dataSource = DiscoverSortOptions
        dropDownMenu.selectionAction = { [unowned self] (index: Int, item: String) in
            print("Selected item: \(item) at index: \(index)")
            self.selectedSort = item
            self.dropDownMenu.hide()
        }
        
        if let index = self.dropDownMenu.dataSource.firstIndex(of: self.selectedSort) {
            print("DropDown Menu Preselect \(index) \(self.dropDownMenu.dataSource[index])")
            dropDownMenu.selectRow(index)
        }
    }
    
    @objc func showDropDown(){
        if self.dropDownMenu.isHidden{
            self.dropDownMenu.show()
        } else {
            self.dropDownMenu.hide()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText.count == 0) {
            self.isFiltering = false
            self.tableView.reloadData()
        } else {
            filterContentForSearchText(searchBar.text!)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        let searchText = searchBar.text ?? ""
        if (searchText.count == 0) {
            self.isFiltering = false
            self.tableView.reloadData()
        } else {
            filterContentForSearchText(searchBar.text!)
        }
    }
    
    @objc func filterContentForSearchText(_ searchText: String) {
        self.isFiltering = searchText.count != 0
        
        let searchTerms = searchText.lowercased().components(separatedBy: " ")
        
        if self.fetchType == ListFav {
            self.filteredUserFavs = userFavs.filter({ (emoji) -> Bool in
                return emoji.lowercased().contains(searchText.lowercased()) || (extraRatingEmojisDic[emoji] ?? "").contains(searchText.lowercased())
            })
        }
        
        if self.fetchType == ListCities {
            self.filteredUserCity = userCity.filter({ (city) -> Bool in
                return city.lowercased().contains(searchText.lowercased())
            })
//            print(searchText.lowercased(), filteredUserCity.count, filteredUserCity)
        }
        
        // FILTER LIST TABLE VIEW
                
        self.filteredDisplayList = fetchedList.filter({ (list) -> Bool in
            var emojiTranslateArray: [String] = []
            var emojiFilter = false
            for term in searchTerms {
                for text in list.topEmojis {
                    if let word = EmojiDictionary[text] {
                        if word.contains(term){
                            emojiFilter = true
                        }
                    }
                }
                
                if list.name.lowercased().contains(term) || list.topEmojis.contains(term) {
                    emojiFilter = true
                }
            }

            return list.name.lowercased().contains(searchText.lowercased()) || list.topEmojis.contains(searchText.lowercased()) || emojiFilter
        })
        
        filteredDisplayList.sort { (p1, p2) -> Bool in
            ((p1.name.hasPrefix(searchText.lowercased())) ? 0 : 1) < ((p2.name.hasPrefix(searchText.lowercased())) ? 0 : 1)
        }
        self.tableView.reloadData()

    }
    
    @objc func refreshItems(){
        self.fetchLists()
        self.showHideAddListButton()

    }

    @objc func refreshAll(){
        print("DiscoverController | Refresh All")
        self.searchBar.text == ""
        self.isFiltering = false
        self.refreshItems()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.setupNavigationItems()
        if self.allLists.count == 0 {
            self.fetchLists()
        }
        self.view.layoutIfNeeded()
        //        self.setupLists()
    }
    

    
    func sortList(inputList: [List]?, sortInput: String? = ListSortDefault, completion: @escaping ([List]) -> ()){
        
        var tempList: [List] = []
        guard let inputList = inputList else {
            print("Sort List: ERROR, No List")
            completion([])
            return
        }
        
        if sortInput == ListSortOptions[0] {
            // Auto Sort - Legit and Bookmark First, then number of posts
            // Idea is that the list with the most posts are likely the oldest
            inputList.sorted(by: { (p1, p2) -> Bool in
                let p1Count = p1.postIds?.count ?? 0
                let p2Count = p2.postIds?.count ?? 0
                return p1Count >= p2Count
            })
            
            // Check For Legit
            if let index = inputList.firstIndex(where: {$0.name == legitListName}){
                tempList.append(inputList[index])
            }
            
            //Check For Bookmark
            if let index = inputList.firstIndex(where: {$0.name == bookmarkListName}){
                tempList.append(inputList[index])
            }
            
            // Add Others
            for list in inputList {
                if !tempList.contains(where: {$0.id == list.id}){
                    tempList.append(list)
                }
            }
        } else if sortInput == ListSortOptions[1]{
            // Sort by Most Recent Modified Date - New Lists would have creation date as most recent
            tempList = inputList.sorted(by: { (p1, p2) -> Bool in
                let p1Date = max(p1.mostRecentDate, p1.latestNotificationTime)
                let p2Date = max(p2.mostRecentDate, p2.latestNotificationTime)
                return p1Date.compare(p2Date) == .orderedDescending
            })
        } else if sortInput == ListSortOptions[2]{
            // Sort by Most Cred - Most Cred likely also has the most posts
            tempList = inputList.sorted(by: { (p1, p2) -> Bool in
                let p1Count = p1.totalCred ?? 0
                let p2Count = p2.totalCred ?? 0
                return p1Count >= p2Count
            })
        }
        
        completion(tempList)
        
    }
    
    func displayListFollowingUsers(list: List, following: Bool) {
        print("Display Users| Following: ",list.id)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayUser = true
        postSocialController.displayUserFollowing = false
        postSocialController.inputList = list
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    func selectUserFollowers(user: User?){
        guard let user = user else {return}
        print("Display Follower User| ",user.uid)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayUser = true
        postSocialController.displayUserFollowing = false
        postSocialController.inputUser = user
        navigationController?.pushViewController(postSocialController, animated: true)
    }

    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if self.fetchType == ListFav {
            return self.isFiltering ? self.filteredUserFavs.count : self.userFavs.count
        }
        else if self.fetchType == ListCities {
            return self.isFiltering ? self.filteredUserCity.count : self.userCity.count
        }
        else {
            return max(1, self.isFiltering ? self.filteredDisplayList.count : self.fetchedList.count)
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    // LISTS
        if self.fetchType == ListFav {
            var emoji = isFiltering ? filteredUserFavs[indexPath.row] : userFavs[indexPath.row]
            let currentList = self.userFavsLists[emoji]
            let cell = tableView.dequeueReusableCell(withIdentifier: newCellId, for: indexPath) as! MainTabListCell
            cell.cellHeight?.constant = 100
            cell.list = currentList
            return cell
        }
        else if self.fetchType == ListCities {
            var city = isFiltering ? filteredUserCity[indexPath.row] : userCity[indexPath.row]
            let currentList = self.userCityLists[city]
            let cell = tableView.dequeueReusableCell(withIdentifier: newCellId, for: indexPath) as! MainTabListCell
            cell.cellHeight?.constant = 100
            cell.list = currentList
            return cell
        }
        else if self.isFiltering && filteredDisplayList.count == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: listCellId, for: indexPath) as! SearchResultsCell
            cell.emojiTextLabel.textAlignment = .center
            cell.locationName = "No Lists Available"
            cell.selectionStyle = .none
            cell.postCountLabel.isHidden = true
            return cell
        }
        else if !self.isFiltering && fetchedList.count == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: listCellId, for: indexPath) as! SearchResultsCell
            cell.emojiTextLabel.textAlignment = .center
            var noItemLabel: String = "There are no results"
            if self.fetchType == ListYours {
                noItemLabel = "You Have No Lists. Tap To Create A List"
            } else if self.fetchType == ListYours {
                noItemLabel = "You Are Not Following Any Lists"
            } else if self.fetchType == ListCities {
                noItemLabel = "You Have No Posts Anywhere Yet. Post a Picture!"
            }
            cell.locationName =  noItemLabel
            cell.selectionStyle = .none
            cell.postCountLabel.isHidden = true
            return cell
        }
        else {
            let currentList = isFiltering ? filteredDisplayList[indexPath.row] : fetchedList[indexPath.row]
//            let cell = tableView.dequeueReusableCell(withIdentifier: newCellId, for: indexPath) as! UserAndListCell
            let cell = tableView.dequeueReusableCell(withIdentifier: newCellId, for: indexPath) as! MainTabListCell

            cell.cellHeight?.constant = 100
            cell.list = currentList
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let currentCell = tableView.cellForRow(at: indexPath) as? SearchResultsCell {
            self.didTapCreateNewList()
        } else {
            if self.fetchType == ListFav {
                let emoji = self.isFiltering ? filteredUserFavs[indexPath.row] : userFavs[indexPath.row]
                let list = userFavsLists[emoji]!
                self.extTapList(list: list)
            }
            else if self.fetchType == ListCities {
                let city = self.isFiltering ? filteredUserCity[indexPath.row] : userCity[indexPath.row]
                let list = userCityLists[city]!
                self.extTapList(list: list)
            }
            else {
                let selectedList = self.isFiltering ? filteredDisplayList[indexPath.row] : fetchedList[indexPath.row]
                self.extTapList(list: selectedList)
            }
            

    //            self.goToList(list: selectedList, filter: nil)
            tableView.deselectRow(at: indexPath, animated: false)
        }


    }
    
    func goToUser(userId: String?)
    {
        guard let userId = userId else {return}
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = userId
        self.navigationController?.pushViewController(userProfileController, animated: true)
    }

//    func handleFollowUser(user: User?) {
//        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else {return}
//        guard let userId = user?.uid else {return}
//        if currentLoggedInUserId == userId {return}
//
//        Database.handleFollowing(userUid: userId) { }
//
//    }

// OLD GO TO LIST FUNCTION
//    func goToList(list: List?, filter: String?) {
//        guard let list = list else {return}
//        let listViewController = ListViewController()
//        listViewController.currentDisplayList = list
//        listViewController.viewFilter?.filterCaption = filter
//        listViewController.refreshPostsForFilter()
//        print("DiscoverController | goToList | \(list.name) | \(filter) | \(list.id)")
//
//        self.navigationController?.pushViewController(listViewController, animated: true)
//    }
    
    func goToList(list: List?, filter: String?) {
        guard let list = list else {return}
        //        let listViewController = ListViewController()
        //        let listViewController = NewListViewController()
        let listViewController = LegitListViewController()
        
        listViewController.currentDisplayList = list
        listViewController.viewFilter.filterCaption = filter
        listViewController.refreshPostsForFilter()
//        listViewController.delegate = self
        print(" TabListViewController | DISPLAYING | \(list.name) | \(list.id) | \(list.postIds?.count) Posts | \(filter) | List_ViewController")
        
        //        self.present(listViewController, animated: true, completion: nil)
        self.navigationController?.pushViewController(listViewController, animated: true)
        
    }
    
    func goToUser(user: User?, filter: String?) {
        guard let user = user else {return}
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = user.uid
        userProfileController.viewFilter?.filterCaption = filter
        userProfileController.refreshPostsForFilter()
        print("DiscoverController | goToUser | \(user.username) | \(filter) | \(user.uid)")
        self.navigationController?.pushViewController(userProfileController, animated: true)
        
    }
    
    func goToUserList(user: User?) {
        guard let user = user else {return}
        let tabListController = TabListViewController()
        tabListController.enableAddListNavButton = false
        tabListController.inputUserId = user.uid
        self.navigationController?.pushViewController(tabListController, animated: true)
    }
    
    func goToPost(postId: String, ref_listId: String?, ref_userId: String?) {
        Database.fetchPostWithPostID(postId: postId) { (post, error) in
            if let error = error {
                print("goToPost \(error)")
            } else {
                guard let post = post else {
                    self.alert(title: "Sorry", message: "Post Does Not Exist Anymore 😭")
                    if let listId = ref_listId {
                        print("DiscoverController | No More Post. Refreshing List to Update | ",listId)
                        Database.refreshListItems(listId: listId)
                    }
                    
                    if let userId = ref_userId {
                        print("DiscoverController | No More Post. Refreshing User to Update | ",userId)
                        Database.fetchUserWithUID(uid: userId, completion: { (user) in
                            Database.updateUserPopularImages(user: user)
                        })
                    }
                    return
                }
                let pictureController = SinglePostView()
                pictureController.post = post
                self.navigationController?.pushViewController(pictureController, animated: true)
            }
        }
    }
    
    
    
    func goToPost(postId: String) {
        Database.fetchPostWithPostID(postId: postId) { (post, error) in
            if let error = error {
                print("goToPost \(error)")
            } else {
                guard let post = post else {
                    self.alert(title: "Sorry", message: "Post Does Not Exist Anymore 😭")
                    return
                }
                let pictureController = SinglePostView()
                pictureController.post = post
                self.navigationController?.pushViewController(pictureController, animated: true)
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        //        displayList[indexPath.row].isSelected = false
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
////        return 300
//        if self.fetchType == DiscoverList {
//            return 200
//        } else if self.fetchType == DiscoverUser {
//            return 70 + 90
//        } else {
//            return 0
//        }
        
//        return self.fetchType == DiscoverList ? 100 : 80
        return 80
    }
    
    
     func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        // HIDE EMOJI DETAIL WHEN SCROLLING
//        for cell in (tableView.visibleCells) {
//            let tempCell = cell as! DiscoverListCellNew
//            tempCell.scrollToFirst()
//        }
        
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input = input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
