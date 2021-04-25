//
//  PostSearchController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/15/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
//
//  HomePostSearch.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/17/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

import GooglePlaces
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase

protocol MainSearchControllerDelegate {
    func filterControllerSelected(filter: Filter?)
    func refreshAll()
}


class MainSearchController : UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate, GMSAutocompleteTableDataSourceDelegate, SearchFilterControllerDelegate, MoreFilterViewDelegate {
    
    //    var allPosts: [Post] = []
    //    var filteredPosts: [Post] = []
    
    var postCreatorIds: [String] = []
    
    var multiSelect: Bool = false
    lazy var singleSelectButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//        button.layer.backgroundColor = UIColor.blue.cgColor
        button.layer.borderColor = UIColor.ianLegitColor().cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 2
        button.clipsToBounds = true
        button.contentHorizontalAlignment = .center
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        
        let navShareTitle = NSAttributedString(string: "1-Tap", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 10)])

        button.addTarget(self, action: #selector(toggleMultiSelect), for: .touchUpInside)
        button.sizeToFit()

        return button
    }()
    
    lazy var multiSelectButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//        button.layer.backgroundColor = UIColor.blue.cgColor
        button.layer.borderColor = UIColor.ianLegitColor().cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 2
        button.clipsToBounds = true
        button.contentHorizontalAlignment = .center
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        
        let navShareTitle = NSAttributedString(string: "COMBO", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 10)])
        
        button.setAttributedTitle(navShareTitle, for: .normal)
//        button.setImage((#imageLiteral(resourceName: "back_icon").resizeImageWith(newSize: CGSize(width: 20, height: 20))).withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.ianLegitColor()
        button.addTarget(self, action: #selector(toggleMultiSelect), for: .touchUpInside)
        button.sizeToFit()
        return button
    }()
    
    func toggleMultiSelect(){
        self.multiSelect = !self.multiSelect
        self.setupNavigationItems()
    }
    
    lazy var navFilterButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "filter").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleFilter), for: .touchUpInside)
        button.layer.cornerRadius = 30/2
        button.clipsToBounds = true
        button.backgroundColor = UIColor.clear
        button.layer.borderColor = UIColor.selectedColor().cgColor
        button.layer.borderWidth = 0
        return button
    }()
    
    
    
    var selectedScope = 0 {
        didSet{
            self.tableView.reloadData()
        }
    }
    
    var locationFilteredDisplay: String? = nil
    
    var userFiltered: User? = nil
    var isFiltering: Bool = false {
        didSet{
            self.tableView.reloadData()
        }
    }
    var delegate: MainSearchControllerDelegate?
    var enableScopeOptions: Bool = true
    lazy var tableView : UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        //        tv.estimatedRowHeight = 100
        tv.allowsMultipleSelection = false
//        tv.contentInset = UIEdgeInsets(top: 20, left: 40, bottom: 20, right: 40)
        return tv
    }()
    
//    var searchScopeButtons = ["Cuisine","Food","Meal","City","Advanced"]
    
    var searchScopeButtons = ["Food","Users","City","Advanced"]

    // Filter Post Variables
    var searchFilter: Filter? {
        didSet {
            self.searchText = self.searchFilter?.filterCaption
            self.searchUserText = self.searchFilter?.filterUser?.username
        }
    }
    
    // Temp Filter Variables
    var searchLocation: CLLocation?
    var searchText: String? = nil {
        didSet {
            self.searchBar.text = searchText
        }
    }
    var searchUserText: String? = nil

    var searchUser: User? = nil
    
    func refreshFilter(){
        self.searchFilter?.clearFilter()
        self.updateViewsForSearchFilter()
    }
    
    func updateViewsForSearchFilter(){
        
        // Caption Search Bar
        if self.selectedScope == 0 {
            self.searchController.searchBar.text = searchFilter?.filterCaption
        }
        
        // USER
        else if self.selectedScope == 1 {
            self.searchController.searchBar.text = searchFilter?.filterUser?.username
        }
        
        // LOCATION
        else if self.selectedScope == 2 {
            let locationFiltering = searchFilter?.filterLocationSummaryID != nil || searchFilter?.filterLocationName != nil
            var locationSearch: String? = ""
            if let filterCityID = searchFilter?.filterLocationSummaryID {
                //                let cityID = filterCityID.components(separatedBy: ",")[0]
                locationFilteredDisplay = filterCityID
            } else if let filterLocName = searchFilter?.filterLocationName {
                locationFilteredDisplay = filterLocName
            }
        }
    }
    
    
    
    func setupInitialSelections(){
        // Setup Food Emojis
        self.updateSortEmojiCounts(emojiCounts: emojiCounts)
        
        // Setup Locations
        self.updateSortLocationCounts()
        
        // Update Views
        self.updateViewsForSearchFilter()
//        self.updateScopeBarCount()
        
        self.tableView.reloadData()
    }
    
    
    
    func updateSortEmojiCounts(emojiCounts: [String:Int]) {
        // We sort by default first so that the option right after selection with posts is the most populous one
        
        // Sort All Emojis by current emoji Count
        Database.sortEmojisWithCounts(inputEmojis: allSearchEmojis, emojiCounts: emojiCounts, dictionaryMatch: true, sort: true) { (userEmojis) in
            self.userDefaultEmojis = userEmojis
        }
        
//        Database.sortEmojisWithCounts(inputEmojis: allEmojis, emojiCounts: emojiCounts, dictionaryMatch: true, sort: true) { (userEmojis) in
//            self.userDefaultEmojis = userEmojis
//        }
        
        
//
//
//        Database.sortEmojisWithCounts(inputEmojis: defaultEmojis, emojiCounts: defaultEmojiCounts) { (default_sortedEmojis) in
//            Database.sortEmojisWithCounts(inputEmojis: default_sortedEmojis, emojiCounts: emojiCounts) { (sortedEmojis) in
//                sortedFoodEmojis = sortedEmojis
//                self.historicalFoodEmojiCounts = self.countSelectedEmojis(inputEmojis: sortedFoodEmojis)
//            }
//        }
//
//        // Must Apply Dictionary Match For Flags
//        Database.sortEmojisWithCounts(inputEmojis: cuisineEmojis, emojiCounts: defaultEmojiCounts, dictionaryMatch: true) { (default_sortedEmojis) in
//            Database.sortEmojisWithCounts(inputEmojis: default_sortedEmojis, emojiCounts: emojiCounts, dictionaryMatch: true) { (sortedEmojis) in
//                sortedCuisineEmojis = sortedEmojis
//                self.historicalCuisineEmojiCounts = self.countSelectedEmojis(inputEmojis: sortedCuisineEmojis)
//            }
//        }
//
//        // No Sorting For Meal Emojis
//        Database.sortEmojisWithCounts(inputEmojis: mealEmojis + dietEmojis, emojiCounts: defaultEmojiCounts, sort: false) { (default_sortedEmojis) in
//            Database.sortEmojisWithCounts(inputEmojis: default_sortedEmojis, emojiCounts: emojiCounts, sort: false) { (sortedEmojis) in
//                sortedMealEmojis = sortedEmojis
//                self.historicalMealEmojiCounts = self.countSelectedEmojis(inputEmojis: sortedMealEmojis)
//            }
//        }
        
    }
    
    
    func updateSortLocationCounts(){
        // Show all Locations
        var tempLoc: [String] = []

        for (key,value) in self.defaultLocationCounts.sorted(by: { (key1, key2) -> Bool in
            return key1.value >= key2.value}) {
            tempLoc.append(key)
        }
        self.allLocationLabels = tempLoc
        
        // Resort All Location Labels - Reversing to add the smallest one first
        for (key,value) in self.locationCounts.sorted(by: {(key1, key2) -> Bool in
            return key1.value <= key2.value}) {
            if let index = self.allLocationLabels.firstIndex(of: key) {
                let tempLocation = self.allLocationLabels.remove(at: index)
                self.allLocationLabels.insert(tempLocation, at: 0)
            }
        }
//        self.updateScopeBarCount()
        
    }
    
    
    
    // Emojis - Pulls in Default Emojis and Emojis filtered by searchText
    var defaultEmojiCounts:[String:Int] = [:] {
        didSet {
            self.updateAllResults()
        }
    }
    var emojiCounts:[String:Int] = [:]
    
    let EmojiCellId = "EmojiCellId"
    
    func countEmojiNumbers(inputEmojis: [Emoji]?, emojiCount: [String:Int], matchDictionary: Bool = false) -> Int {
        guard let inputEmojis = inputEmojis else {
            print("countSelectedEmojis ERROR | No Emojis")
            return 0}
        
        if emojiCount.count == 0 {
            print("countSelectedEmojis ERROR | No emojiCount")
            return 0}
        
        var temp_num = 0
        for emoji in inputEmojis {
            if matchDictionary {
                if let _ = emojiCount[emoji.emoji] {
                    temp_num += 1
                } else if let _ = emojiCount[emoji.name!] {
                    temp_num += 1
                }
            } else {
                if let _ = emojiCount[emoji.emoji] {
                    temp_num += 1
                }
            }
        }
        return temp_num
        
    }
    
    func countSelectedEmojis(inputEmojis: [Emoji]?) -> Int {
        guard let inputEmojis = inputEmojis else {
            print("countSelectedEmojis ERROR | No Emojis")
            return 0}
        
        var tempCount = 0
        for emoji in inputEmojis {
            if emoji.count > 0 {
                tempCount += 1
            }
        }
        
        return tempCount
    }
    
    
    // ALL RESULTS
    var allResults: [String:String] = [:]
    var filteredAllResults:[String] = []
    var defaultAllResults:[String] = []

    func updateAllResults() {
        allResults = [:]
        
        for a in defaultEmojiCounts {
            let emoji = a.key
            allResults[a.key] = "emoji"
            
            if let emojiDic = EmojiDictionary[emoji] {
                allResults[emojiDic] = "emoji"
            }
            
            // ADD Top
            
        }
        
        for x in allUsers {
            allResults[x.username.lowercased()] = "user"
        }
        
        for y in allLocationLabels {
            allResults[y.lowercased()] = "location"
        }
        
        
        
        
    }
    
    
    // ALL FOOD
    var userDefaultEmojis:[Emoji] = []
    var searchFilteredFoodEmojis:[Emoji] = []
    
    // FOOD
    var sortedFoodEmojis:[Emoji] = defaultEmojis
    var filteredFoodEmojis:[Emoji] = []
    var historicalFoodEmojiCounts: Int = 0
    
    // Cuisine
    var sortedCuisineEmojis:[Emoji] = cuisineEmojis
    var filteredCuisines:[Emoji] = []
    var historicalCuisineEmojiCounts: Int = 0
    
    // Meal
    var sortedMealEmojis:[Emoji] = mealEmojis + dietEmojis
    var filteredMeals:[Emoji] = []
    var historicalMealEmojiCounts: Int = 0
    
    // Users
    let UserCellId = "UserCellId"
    var allUsers = [User]() {
        didSet {
            self.updateAllResults()
        }
    }
    var filteredUsers = [User]()
    
    // Lists
    let ListCellId = "ListCellId"
    var allLists = [List]()
    var filteredLists = [List]()
    
    // Google Locations
    let LocationCellId = "LocationCellId"
    var defaultLocationCounts:[String:Int] = [:] {
        didSet{
            self.updateAllResults()
        }
    }
    var locationCounts:[String:Int] = [:] {
        didSet {
            self.updateSortLocationCounts()
        }
    }
    var allLocationLabels:[String] = [] {
        didSet{
//            self.updateScopeBarCount()
        }
    }
    var filteredLocationLabels:[String] = []
    
    var googleLocationSearchInd: Bool = false {
        didSet {
//            print("googleLocationSearchInd | \(googleLocationSearchInd)")
            self.toggleGoogleLocationSearch()
        }
    }
    
    var googleImage: UIImageView = {
        let img = UIImageView()
        img.image = #imageLiteral(resourceName: "google_tag").withRenderingMode(.alwaysOriginal)
        img.contentMode = .scaleAspectFit
        img.alpha = 0.5
        return img
    }()
    
    
    var tableDataSource: GMSAutocompleteTableDataSource?
    
    let searchController = UISearchController(searchResultsController: nil)
    var searchBar = UISearchBar()
    
    
    // Additional Filters Delegates
    lazy var moreFilterView : MoreFilterView = {
        let view = MoreFilterView()
        view.delegate = self
        return view
    }()
    
    func captionSearchTap() {
        self.headerSortSegment.selectedSegmentIndex = 0
    }
    
    func locationSearchTap() {
        self.headerSortSegment.selectedSegmentIndex = 2
    }
    
    var headerSortSegment = UISegmentedControl()
    var buttonBarPosition: NSLayoutConstraint?
    let buttonBar = UIView()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("MainSearchController | LOAD")
        view.backgroundColor = UIColor.rgb(red: 241, green: 241, blue: 241)
//        setupSearchController()
        setupSearchBar()
        setupNavigationItems()
        setupSegments()
        setupTableView()
        
        let searchBarView = UIView()
        searchBarView.backgroundColor = UIColor.white
        view.addSubview(searchBarView)
        searchBarView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        
        view.addSubview(searchBar)
        searchBar.anchor(top: searchBarView.topAnchor, left: searchBarView.leftAnchor, bottom: searchBarView.bottomAnchor, right: searchBarView.rightAnchor, paddingTop: 5, paddingLeft: 25, paddingBottom: 5, paddingRight: 25, width: 0, height: 0)

        let headerView = UIView()
        headerView.backgroundColor = UIColor.white
        view.addSubview(headerView)
        headerView.anchor(top: searchBarView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)

        view.addSubview(headerSortSegment)
        headerSortSegment.anchor(top: headerView.topAnchor, left: headerView.leftAnchor, bottom: nil, right: headerView.rightAnchor, paddingTop: -1, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        
        let segmentWidth = (self.view.frame.width - 30 - 40) / 4

//        let segmentWidth = self.headerSortSegment.frame.width / searchScopeButtons.count
        buttonBar.backgroundColor = UIColor.ianLegitColor()
        view.addSubview(buttonBar)
        buttonBar.anchor(top: headerSortSegment.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: segmentWidth, height: 5)
        buttonBar.leftAnchor.constraint(lessThanOrEqualTo: headerSortSegment.leftAnchor).isActive = true
        buttonBar.rightAnchor.constraint(lessThanOrEqualTo: headerSortSegment.rightAnchor).isActive = true
        buttonBarPosition = buttonBar.leftAnchor.constraint(equalTo: headerSortSegment.leftAnchor, constant: 5)
        buttonBarPosition?.isActive = true
        

        view.addSubview(tableView)
        tableView.anchor(top: headerSortSegment.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 20, paddingLeft: 30, paddingBottom: 0, paddingRight: 30, width: 0, height: 0)
        

        
        
        // Emojis are loaded in the emoji dictionary
        
        // Load Users
        Database.fetchALLUsers { (fetchedUsers) in
            self.allUsers = []
            if self.postCreatorIds.count > 0 {
                // Filter For User Ids
                for user in fetchedUsers {
                    if self.postCreatorIds.contains(user.uid){
                        self.allUsers.append(user)
                    }
                }
                
            } else {
                self.allUsers = fetchedUsers
            }

            
            self.allUsers = self.allUsers.sorted(by: { (p1, p2) -> Bool in
                p1.votes_received > p2.votes_received
            })
            
            self.filteredUsers = self.allUsers
            self.tableView.reloadData()
        }
        
        
        view.addSubview(googleImage)
        googleImage.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 15)
        googleImage.backgroundColor = UIColor.clear
        googleImage.isHidden = true
        
        view.addSubview(moreFilterView)
        //        moreFilterView.backgroundColor = UIColor.yellow
        moreFilterView.anchor(top: tableView.topAnchor, left: view.leftAnchor, bottom: tableView.bottomAnchor, right: tableView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        moreFilterView.isHidden = true
        
    }
    
    func setupTableView(){
        
        tableView.backgroundColor = UIColor.rgb(red: 249, green: 249, blue: 249)
        tableView.register(SearchResultsCell.self, forCellReuseIdentifier: EmojiCellId)
        tableView.register(UserAndListCell.self, forCellReuseIdentifier: UserCellId)
        tableView.register(LocationCell.self, forCellReuseIdentifier: LocationCellId)
        tableView.register(NewListCell.self, forCellReuseIdentifier: ListCellId)
//        tableView.contentInset = UIEdgeInsets(top: 20, left: 40, bottom: 0, right: 40)
        
        tableView.allowsMultipleSelection = true
        // Google Locations are only loaded when Locations are selected
        
        tableDataSource = GMSAutocompleteTableDataSource()
        tableDataSource?.delegate = self
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 160
        //        tableView.estimatedRowHeight = 200
        
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(increaseScope))
        swipeLeft.direction = .left
        self.tableView.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(decreaseScope))
        swipeRight.direction = .right
        self.tableView.addGestureRecognizer(swipeRight)
    }
    
    func setupSegments(){
        headerSortSegment = UISegmentedControl(items: searchScopeButtons)
        headerSortSegment.selectedSegmentIndex = self.selectedScope
        headerSortSegment.addTarget(self, action: #selector(selectSort), for: .valueChanged)
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        headerSortSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
        headerSortSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)
        
        headerSortSegment.backgroundColor = .white
        headerSortSegment.tintColor = .white
        
        // This needs to be false since we are using auto layout constraints
        //        headerSortSegment.translatesAutoresizingMaskIntoConstraints = false
        //        buttonBar.translatesAutoresizingMaskIntoConstraints = false
        //        headerSortSegment.apportionsSegmentWidthsByContent = true
    }
    
    func underlineSegment(segment: Int? = 0){
        
        let segmentWidth = (self.view.frame.width - 40) / CGFloat(self.headerSortSegment.numberOfSegments)
        let tempX = self.buttonBar.frame.origin.x
        UIView.animate(withDuration: 0.3) {
            //            self.buttonBarPosition?.isActive = false
            // Origin code lets bar slide
            self.buttonBar.frame.origin.x = segmentWidth * CGFloat(segment ?? 0) + 10
            self.buttonBarPosition?.constant = segmentWidth * CGFloat(segment ?? 0) + 10
            self.buttonBarPosition?.isActive = true
        }
    }
    
    
    func setupNavigationItems(){
        
        navigationController?.navigationBar.barTintColor = UIColor.white
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        // REMOVES THE 1PX BOTTOM LINE IN NAV BAR
        navigationController?.navigationBar.shadowImage = UIImage()
        
        let customFont = UIFont(name: "Poppins-Bold", size: 18)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: customFont]
        
        var searchItem = ""
        if self.searchFilter?.filterList != nil {
            searchItem = " " + (self.searchFilter?.filterList?.name)!
        } else if self.searchFilter?.filterUser != nil {
            searchItem = " " + (self.searchFilter?.filterUser?.username)!
        }
        
        self.navigationItem.title = "Search" + searchItem
//        self.navigationController?.navigationBar.layoutIfNeeded()
        
        // Nav Back Buttons
        let navBackButton = navBackButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        navBackButton.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
        let barButton2 = UIBarButtonItem.init(customView: navBackButton)
        self.navigationItem.leftBarButtonItem = barButton2
        
        let multButton = UIBarButtonItem.init(customView: multiSelectButton)
        let singleButton = UIBarButtonItem.init(customView: singleSelectButton)
        self.navigationItem.rightBarButtonItem = self.multiSelect ? multButton : singleButton
        
    }
    
    
    func increaseScope(){
        self.changeScope(change: 1)
    }
    
    func decreaseScope(){
        self.changeScope(change: -1)
    }
    
    func changeScope(change: Int){
        self.selectedScope = min(max(0, self.selectedScope + change),(searchBar.scopeButtonTitles?.count)! - 1)
        self.searchBar.selectedScopeButtonIndex = self.selectedScope
    }
    
    func setupSearchBar(){
        searchBar.sizeToFit()
        searchBar.delegate = self
        searchBar.placeholder =  searchBarPlaceholderText_Emoji
        searchBar.showsCancelButton = false
        searchController.searchBar.showsCancelButton = false
        
        searchBar.barTintColor = UIColor.white
        searchBar.tintColor = UIColor.white
        searchBar.backgroundColor = UIColor.white
        searchBar.searchBarStyle = .minimal
        searchBar.layer.borderWidth = 0
        definesPresentationContext = false
        
        let textFieldInsideUISearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.textColor = UIColor.ianLegitColor()
        //        textFieldInsideUISearchBar?.font = textFieldInsideUISearchBar?.font?.withSize(12)
        
        
        for s in searchBar.subviews[0].subviews {
            if s is UITextField {
                s.layer.borderWidth = 0.5
                s.layer.borderColor = UIColor.gray.cgColor
                s.layer.cornerRadius = 5
                s.clipsToBounds = true
                s.layer.backgroundColor = UIColor.white.cgColor
            }
        }
        
    }
    
    
    func setupSearchController(){
        //        navigationController?.navigationBar.barTintColor = UIColor.white
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchBar = searchController.searchBar
        
        searchBar.sizeToFit()
        searchBar.delegate = self
        searchBar.placeholder =  searchBarPlaceholderText_Emoji
        searchBar.showsCancelButton = false
        searchController.searchBar.showsCancelButton = false
        
        searchBar.barTintColor = UIColor.white
        searchBar.tintColor = UIColor.white
        searchBar.backgroundColor = UIColor.white
        definesPresentationContext = true
        
        let textFieldInsideUISearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.textColor = UIColor.legitColor()
        //        textFieldInsideUISearchBar?.font = textFieldInsideUISearchBar?.font?.withSize(12)
        
        
        for s in searchBar.subviews[0].subviews {
            if s is UITextField {
                s.layer.borderWidth = 0.5
                s.layer.borderColor = UIColor.gray.cgColor
                s.layer.cornerRadius = 5
                s.clipsToBounds = true
                s.layer.backgroundColor = UIColor.white.cgColor
                
            }
        }
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling  = false
        
        
        //        if #available(iOS 11.0, *) {
        //            navigationItem.searchController = searchController
        //            navigationItem.hidesSearchBarWhenScrolling  = false
        //            navigationItem.titleView = searchController.searchBar
        //        } else {
        //            self.tableView.tableHeaderView = searchBar
        //            searchBar.backgroundColor = UIColor.legitColor()
        //            searchBar.barTintColor = UIColor.legitColor()
        //        }
        
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // Emojis
        if self.selectedScope == 0 {
            return isFiltering ? searchFilteredFoodEmojis.count : userDefaultEmojis.count
        }
            
            // Users
        else if self.selectedScope == 1 {
            return isFiltering ? filteredUsers.count : allUsers.count
        }
            
            // Locations
        else if self.selectedScope == 2 && !googleLocationSearchInd{
            return isFiltering ? filteredLocationLabels.count + 1 : allLocationLabels.count + 1
        }
            
            // Other
        else if self.selectedScope == 3 {
            return 0
        }
            
            // Google Locations - Data source changes to Google AutoComplete
        else {
            return 0
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1

    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 5
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        if self.selectedScope == 0 {
            if !isFiltering {
                // Not Filtering. Show Default
            }
            
            
        }
        
        // Emojis
        if self.selectedScope == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: EmojiCellId, for: indexPath) as!  SearchResultsCell
            let displayEmoji = isFiltering ? searchFilteredFoodEmojis[indexPath.section] : userDefaultEmojis[indexPath.section]
            cell.emoji = displayEmoji
            cell.isSelected = (self.searchText != nil) ? (self.searchText?.contains((cell.emoji?.emoji)!))! : false
            cell.postCount = (emojiCounts[displayEmoji.emoji] ?? 0) + (emojiCounts[displayEmoji.name!] ?? 0)
            
            if cell.isSelected && cell.postCount == 0 {
                cell.postCount = (defaultEmojiCounts[displayEmoji.emoji] ?? 0)
            }
            
            return cell
        }
            
            // Users
        else if self.selectedScope == 1 {
            let displayUser = isFiltering ? filteredUsers[indexPath.section] : allUsers[indexPath.section]
            let cell = tableView.dequeueReusableCell(withIdentifier: UserCellId, for: indexPath) as! UserAndListCell
            cell.user = displayUser
            cell.isSelected = self.userFiltered?.uid == displayUser.uid
            return cell
        }
            
            // Locations
        else if self.selectedScope == 2 && !googleLocationSearchInd {
            let cell = tableView.dequeueReusableCell(withIdentifier: LocationCellId, for: indexPath) as! LocationCell
            
            if indexPath.section == 0 {
                // First Row - Add Search for Google Cell
                let curLabel = NSMutableAttributedString(string: "Press Enter To 🔍 Location on Google", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.mainBlue(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 16)]))
                cell.locationName = nil
                cell.postCount = 0
                cell.locationTextLabel.attributedText = curLabel
                
            } else {
                let curLabel = isFiltering ? filteredLocationLabels[indexPath.section-1] : allLocationLabels[indexPath.section-1]
                cell.locationName = curLabel
                cell.isSelected = (curLabel == searchFilter?.filterLocationSummaryID)
                cell.postCount = locationCounts[curLabel] ?? 0
                
                // Display Default Emoji Count if Not Filtering
                //                cell.postCount = isFiltering ? (locationCounts[curLabel] ?? 0) : (defaultLocationCounts[curLabel] ?? 0)
            }
            return cell
        }
            
            // Null
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: EmojiCellId, for: indexPath) as! SearchResultsCell
            return cell
        }
        
    }
    
    func filterControllerSelected(filter: Filter?) {
        //        self.searchFilter = filter
        self.handleFilter()
    }
    
    func handleFilter(){
        if let addFilter = self.moreFilterView.searchFilter {
            // Location Filters always get transferred to advanced tab if exists since one click on location is filtered right away
            // Does not stay on filter once a location is selected
            
            // Only grab caption filter from the main search filter. Rest of filter comes from the advanced tab
            self.searchFilter = addFilter
            if self.searchFilter?.filterRange != nil && self.searchFilter?.filterLocation == nil {
                // Default to Current Location if range selected
                self.searchFilter?.filterLocation = CurrentUser.currentLocation
            }
        }
        self.searchFilter?.filterCaption = self.searchText
        self.searchFilter?.filterUser = self.searchUser

        self.delegate?.filterControllerSelected(filter: searchFilter)
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func handleBackButton(){
        print("MainSearchController | Back Button Tapped")
        if self.selectedScope != 3 && self.searchBar.text == "" {
            print("MainSearchView | Back Button Tapped | Blank Search Bar : Auto-Refresh All")
            self.delegate?.refreshAll()
        }
        
        self.navigationController?.popViewController(animated: true)
        
//        self.navigationController?.popToRootViewController(animated: true)

    }
    
    func filterCaptionSelected(searchedText: String?){
        searchFilter?.filterCaption = searchedText
        self.delegate?.filterControllerSelected(filter: searchFilter)
        self.navigationController?.popViewController(animated: true)
    }
    
    
    func addEmojiToSearchTerm(inputEmoji: Emoji?) {
        guard let inputEmoji = inputEmoji else {return}
        guard let searchBarText = self.searchBar.text else {return}
        print("addEmojiToSearchTerm | \(inputEmoji)")
        
        var tempSearchBarText = searchBarText.components(separatedBy: " ")
        
        var emojiLabel = inputEmoji.name
        var emojiText = inputEmoji.emoji
        var emojiLabel_Array = emojiLabel?.components(separatedBy: " ")
        var finalSearchCaption: String = ""
        
        if searchBarText.contains(emojiText) {
            print("Deselecting \(emojiText) | \(index)")
            finalSearchCaption = searchBarText.replacingOccurrences(of: emojiText + " ", with: "")
//            self.searchFilter?.filterCaption = finalSearchCaption
            self.searchText = finalSearchCaption
            self.searchBar.text = finalSearchCaption
            return
        }
        
        
        if (tempSearchBarText.count) <= 1 {
            // If only one word, then replace it with emoji
            finalSearchCaption = emojiText + " "
        } else {
            // Caption has more than 1 word
            
            var lastWord = tempSearchBarText[tempSearchBarText.endIndex - 1]
            var secondLastWord = tempSearchBarText[tempSearchBarText.endIndex - 2]
            
            if emojiLabel_Array?.count == 1 {
                finalSearchCaption = tempSearchBarText.dropLast().joined(separator: " ") + " " + (emojiText) + " "
            } else if emojiLabel_Array?.count == 2 {
                // Drop last 2 words if the second last word matches the description
                if secondLastWord.lowercased() == emojiLabel_Array![0].lowercased() {
                    finalSearchCaption = tempSearchBarText.dropLast(2).joined(separator: " ") + " " + (emojiText) + " "
                } else {
                    finalSearchCaption = tempSearchBarText.dropLast().joined(separator: " ") + " " + (emojiText) + " "
                }
            }
        }
//        self.searchFilter?.filterCaption = finalSearchCaption
        self.searchText = finalSearchCaption

        self.searchBar.text = finalSearchCaption
        //        self.captionFiltered = finalSearchCaption
        
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.cellForRow(at: indexPath)?.backgroundColor = UIColor.mainBlue().withAlphaComponent(0.2)
        
        // Emoji Selected
        if self.selectedScope == 0 {
            var emojiSelected: Emoji?
            emojiSelected = isFiltering ? searchFilteredFoodEmojis[indexPath.section] : userDefaultEmojis[indexPath.section]
            
            if multiSelect {
                self.addEmojiToSearchTerm(inputEmoji: emojiSelected)
            } else {
                self.searchText = emojiSelected?.emoji
//                self.addEmojiToSearchTerm(inputEmoji: emojiSelected)
                if (self.searchText?.contains(Character((emojiSelected?.emoji)!)))! {
                    // Does not filter if emoji was unselected instead
                    self.handleFilter()
                }
            }
        }
            
        // User Selected
        else if self.selectedScope == 1 {
            let userSelected = isFiltering ? filteredUsers[indexPath.section] : allUsers[indexPath.section]
            self.searchUser = userSelected
//            if !multiSelect {
//                self.handleFilter()
//            } else {
//                self.tableView.reloadRows(at: [indexPath], with: .none)
//            }

            let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
            userProfileController.displayUserId = userSelected.uid
            self.navigationController?.pushViewController(userProfileController, animated: true)
        }
            
            // Location Selected
        else if selectedScope == 2 && !googleLocationSearchInd {
            var locationIDSelected: String?
            if indexPath.section == 0 {
                print("Search Google Location Pressed")
                self.googleLocationSearchInd = true
            } else {
                // Selected a City Summary ID
                locationIDSelected = isFiltering ? filteredLocationLabels[indexPath.section - 1] : allLocationLabels[indexPath.section - 1]
                searchFilter?.clearFilterLocation()
                searchFilter?.filterLocationSummaryID = locationIDSelected
                self.handleFilter()
            }
        }
        
        
        // User Selected
        //        if selectedScope == 2 {
        //            var userSelected: User?
        //            if isFiltering {
        //                userSelected = filteredUsers[indexPath.row]
        //            } else {
        //                userSelected = allUsers[indexPath.row]
        //            }
        //
        //            self.searchFilter?.filterUser = userSelected
        //            self.handleFilter()
        ////            searchFilter?.filterUser  = userSelected
        //        }
        //        self.delegate?.filterControllerSelected(filter: searchFilter)
        //        self.navigationController?.popViewController(animated: true)
        
        // Location Selected is handled by Google Autocomplete below
    }
    
    
    func filterContentForSearchText(_ searchText: String) {
        // Filter for Emojis and Users
        
        let searchCaption = searchText.emojilessString
        let searchCaptionArray = searchText.emojilessString.lowercased().components(separatedBy: " ")
        
        var lastWord = searchCaptionArray[searchCaptionArray.endIndex - 1]
        //        print("searchCaptionArray | \(searchCaptionArray) | lastWord | \(lastWord)")
        
        //     cell.isSelected = (self.captionFiltered != nil) ? (self.captionFiltered?.contains((cell.emoji?.emoji)!))! : false
        
        // Filter All
        if self.selectedScope == 0 {
            var tempFilterResults:[String] = []
            for (key,value) in allResults {
                if key.lowercased().contains(searchCaption.lowercased()) {
                    tempFilterResults.append(key)
                }
            }
            
            
            tempFilterResults.sort { (p1, p2) -> Bool in
                let p1Ind = ((p1.hasPrefix(searchCaption.lowercased())) ? 0 : 1)
                let p2Ind = ((p2.hasPrefix(searchCaption.lowercased())) ? 0 : 1)
                if p1Ind != p2Ind {
                    return p1Ind < p2Ind
                } else {
                    return p1 > p2
                }
            }
            
            filteredAllResults = tempFilterResults
        }
        
        
//        // Filter Food
//        if self.selectedScope == 0 {
//            if lastWord.isEmptyOrWhitespace() {
//                searchFilteredFoodEmojis = userDefaultEmojis
//            } else {
//                // If contains text, filter emojis for remaining word
//                searchFilteredFoodEmojis = allEmojis.filter({( emoji : Emoji) -> Bool in
//                    return searchCaptionArray.contains(emoji.name!) || (emoji.name?.contains(lastWord))!})
//            }
//
//
//            searchFilteredFoodEmojis.sort { (p1, p2) -> Bool in
//                let p1Ind = ((p1.name?.hasPrefix(lastWord.lowercased()))! ? 0 : 1)
//                let p2Ind = ((p2.name?.hasPrefix(lastWord.lowercased()))! ? 0 : 1)
//                if p1Ind != p2Ind {
//                    return p1Ind < p2Ind
//                } else {
//                    return p1.count > p2.count
//                }
//
//            }
//        }
        
            
        else if self.selectedScope == 1 {
            filteredUsers = allUsers.filter({ (user) -> Bool in
                return user.username.lowercased().contains(searchCaption.lowercased())
            })
            filteredUsers.sort { (p1, p2) -> Bool in
                let p1Ind = ((p1.username.hasPrefix(searchCaption.lowercased())) ? 0 : 1)
                let p2Ind = ((p2.username.hasPrefix(searchCaption.lowercased())) ? 0 : 1)
                if p1Ind != p2Ind {
                    return p1Ind < p2Ind
                } else {
                    return p1.posts_created > p2.posts_created
                }
            }
        }
            
        else if self.selectedScope == 2 && !self.googleLocationSearchInd{
            filteredLocationLabels = allLocationLabels.filter({ (string) -> Bool in
                return string.lowercased().contains(searchCaption.lowercased())
            })
            filteredLocationLabels.sort { (p1, p2) -> Bool in
                let p1Ind = ((p1.hasPrefix(searchCaption.lowercased())) ? 0 : 1)
                let p2Ind = ((p2.hasPrefix(searchCaption.lowercased())) ? 0 : 1)
                if p1Ind != p2Ind {
                    return p1Ind < p2Ind
                } else {
                    return p1.count > p2.count
                }
            }
        }

        
        self.tableView.reloadData()
    }
    
    
    func updateSearchResults(for searchController: UISearchController) {
        // Updates Search Results as searchbar is populated
        let searchBar = searchController.searchBar
        if (searchBar.text?.isEmpty)! {
            // Displays Default Search Results even if search bar is empty
            self.isFiltering = false
            searchController.searchResultsController?.view.isHidden = false
        }
        
        self.isFiltering = searchController.isActive && !(searchBar.text?.isEmpty)!
        
        if self.isFiltering {
            if self.selectedScope == 0 || self.selectedScope == 1 || self.selectedScope == 2  && !self.googleLocationSearchInd {
                filterContentForSearchText(searchBar.text!)
            } else if self.selectedScope == 2  && self.googleLocationSearchInd {
                print("Google Search Text |\(searchBar.text!)")
                tableDataSource?.sourceTextHasChanged(searchBar.text!)
            }
        }
    }
    
    

    
    override func viewWillDisappear(_ animated: Bool) {
        self.searchBar.isHidden = true
//        if self.selectedScope != 3 && self.searchBar.text == "" {
//            print("MainSearchView | WillDisappear | Blank Search Bar : Auto-Refresh All")
//            self.delegate?.refreshAll()
//        }
        
        //      Remove Searchbar scope during transition
        //        self.searchBar.isHidden = true
        //        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //      Show Searchbar scope during transition
        //        self.searchBar.isHidden = false
        self.setupInitialSelections()
        self.setupNavigationItems()
        self.searchBar.becomeFirstResponder()
        //        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
//            self.searchController.searchBar.becomeFirstResponder()
        }
    }
    
// SEARCH BAR DELEGATE FUNCTIONS
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
//        self.searchBar.sizeToFit()
        if self.selectedScope == 3 {
            // Activate Food Search Bar if user clicks on search bar at more filter view
            self.captionSearchTap()
        }
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
//        self.searchBar.sizeToFit()
        return true
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchBar.text?.isEmptyOrWhitespace())! {
            // All Search Bar Text is blank but might contain spaces. Remove Spaces
            print("Empty Search Bar. Replacing All Spaces")
            searchBar.text?.replacingOccurrences(of: " ", with: "")
        }
        
        if (searchBar.text?.isEmpty)! {
            // CAPTION
            if self.selectedScope == 0 {
                self.searchText = nil
                self.emojiCounts = self.defaultEmojiCounts
                self.updateSortEmojiCounts(emojiCounts: defaultEmojiCounts)
//                self.searchFilter?.filterCaption = nil
                print("Clear Caption Filter")
            }
            
            // USER
            else if self.selectedScope == 1 {
                self.searchUserText = nil
            }
            
            // LOCATION
            else if self.selectedScope == 2 {
                self.searchFilter?.clearFilterLocation()
                self.locationCounts = self.defaultLocationCounts
                print("Clear Location Filter")
            }
            self.isFiltering = false
            self.googleLocationSearchInd = false
            self.tableView.reloadData()

        } else {
            self.isFiltering = true
            if self.selectedScope == 0 || self.selectedScope == 1 || self.selectedScope == 2  && !self.googleLocationSearchInd {
                filterContentForSearchText(searchBar.text!)
            } else if self.selectedScope == 2  && self.googleLocationSearchInd {
                print("Google Search Text |\(searchBar.text!)")
                tableDataSource?.sourceTextHasChanged(searchBar.text!)
            }
            
            if self.selectedScope == 0 {
                self.searchText = searchText
            } else if self.selectedScope == 1 {
                self.searchUserText = searchText
            }
            
        }
    }
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if self.selectedScope == 2 && !self.googleLocationSearchInd{
            self.googleLocationSearchInd = true
        }
            
            //        else if self.selectedScope == 3 && self.googleLocationSearchInd{
            //            self.captionFiltered = self.captionFiltered + " " + searchBar.text
            //            self.googleLocationSearchInd = true
            //            let firstIndex = IndexPath(row: 0, section: 0)
            //            self.tableView.selectRow(at: firstIndex, animated: true, scrollPosition: .none)
            //            print("Auto Select First Result")
            //        }
            
        else if !(searchBar.text?.isEmptyOrWhitespace())! {
            self.filterCaptionSelected(searchedText: searchBar.text)
        }
            
        else {
            self.filterCaptionSelected(searchedText: nil)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        print("Search Bar Canceled. Refresh All")
//        self.searchController.searchBar.resignFirstResponder()
        
        self.delegate?.refreshAll()
        self.navigationController?.popViewController(animated: true)
        
        //        if !(searchBar.text?.isEmptyOrWhitespace())! {
        //            self.filterCaptionSelected(searchedText: searchBar.text)
        //        } else {
        //            self.filterCaptionSelected(searchedText: nil)
        //        }
    }
    
    var tempCaptionSearchBarText: String = ""
    
    @objc func selectSort(sender: UISegmentedControl) {
        self.selectedScope = sender.selectedSegmentIndex
        self.underlineSegment(segment: self.selectedScope)
        print("Selected Scope is: ", self.searchScopeButtons[self.selectedScope], self.selectedScope)

        self.searchBar.isUserInteractionEnabled = true

        self.tableView.dataSource = self
        self.tableView.delegate = self
        // Refreshes to non-Google Search Location if Search Tab is clicked
        self.googleLocationSearchInd = false
        self.setupInitialSelections()
        // Changing Scope Resets and Resorts all selections inetad of just changing the counts
        
        
        self.moreFilterView.isHidden = (selectedScope != 3)
        
        // CAPTION
        if selectedScope == 0 {
            // Display Filtered Caption when emoji tab selected
            self.searchBar.placeholder = searchBarPlaceholderText_Emoji
            self.searchBar.text = self.searchText
        }
        
        // USER
        else if selectedScope == 1 {
            self.searchBar.text = self.searchUserText
        }
        
        // LOCATION
        else if selectedScope == 2 {
            self.searchBar.placeholder = searchBarPlaceholderText_Location
            
            let locationFiltering = searchFilter?.filterLocationSummaryID != nil || searchFilter?.filterLocationName != nil
            var locationSearch: String? = ""
            if let filterCityID = searchFilter?.filterLocationSummaryID {
                //                let cityID = filterCityID.components(separatedBy: ",")[0]
                locationFilteredDisplay = filterCityID
            } else if let filterLocName = searchFilter?.filterLocationName {
                locationFilteredDisplay = filterLocName
            }
            
            if locationFilteredDisplay != "Current Location" {
                self.searchBar.text = locationFilteredDisplay
            } else {
                self.searchBar.text = ""
            }
            
            // Show all Selection Even if Location Selected
            if self.searchBar.text != "" {
                self.filteredLocationLabels = self.allLocationLabels.sorted { (p1, p2) -> Bool in
                    ((p1.hasPrefix((locationFilteredDisplay?.lowercased())!)) ? 0 : 1) < ((p2.hasPrefix((locationFilteredDisplay?.lowercased())!)) ? 0 : 1)
                }
            }
            
        } else if selectedScope == 3 {
            
            self.searchBar.resignFirstResponder()
            self.searchBar.isUserInteractionEnabled = false
            
            self.searchBar.placeholder = searchBarPlaceholderText_Emoji
            moreFilterView.searchFilter = self.searchFilter
            moreFilterView.filterCaptionLabel.text = self.searchText
            if locationFilteredDisplay == nil {
                let attributedText = NSMutableAttributedString(string: "Current Location", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.legitColor()]))
                moreFilterView.locationNameLabel.attributedText = attributedText
            } else{
                moreFilterView.locationNameLabel.text = locationFilteredDisplay
            }
        }
        
        self.searchController.searchBar.resignFirstResponder()
        self.tableView.reloadData()
    }
    
    func toggleGoogleLocationSearch(){
        
        if searchScopeButtons[self.selectedScope] == "City" && googleLocationSearchInd {
            self.googleImage.isHidden = !googleLocationSearchInd
            self.tableView.dataSource = self.tableDataSource
            self.tableView.delegate = self.tableDataSource
            
            DispatchQueue.main.async {
                
                self.searchController.searchBar.becomeFirstResponder()
                let when = DispatchTime.now() + 0.5 // change 2 to desired number of seconds
                DispatchQueue.main.asyncAfter(deadline: when) {
                    //Delay for 1 second to find current location
                    self.tableView.reloadData()
                }
            }
        } else {
            self.tableView.dataSource = self
            self.tableView.delegate = self
        }
    }
    
    func didRequestAutocompletePredictions(for tableDataSource: GMSAutocompleteTableDataSource) {
        print("Google Request")
    }
    
    func didUpdateAutocompletePredictionsForTableDataSource(tableDataSource: GMSAutocompleteTableDataSource) {
        // Turn the network activity indicator off.
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        // Reload table data.
        self.tableView.reloadData()
    }
    
    func didRequestAutocompletePredictionsForTableDataSource(tableDataSource: GMSAutocompleteTableDataSource) {
        // Turn the network activity indicator on.
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        // Reload table data.
        self.tableView.reloadData()
    }
    
    
    func tableDataSource(_ tableDataSource: GMSAutocompleteTableDataSource, didAutocompleteWith place: GMSPlace) {
        // Do something with the selected place.
        searchFilter?.clearFilterLocation()
        self.searchFilter?.filterLocation = CLLocation.init(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        self.searchFilter?.filterGoogleLocationID = place.placeID
        self.searchFilter?.filterLocationName = place.name
        self.searchFilter?.filterRange = "50"
        self.handleFilter()
        //        self.delegate?.filterControllerSelected(filter: searchFilter)
        //        self.navigationController?.popViewController(animated: true)
        
        print("Selected Google Location is: ", place.placeID, " name: ", place.name, "type: ", place.types, "GPS: ",self.searchFilter?.filterLocation)
        
        
    }
    
    func tableDataSource(_ tableDataSource: GMSAutocompleteTableDataSource, didFailAutocompleteWithError error: Error) {
        // TODO: Handle the error.
        print("Error: \(error)")
    }
    
    func openFilter(){
        let filterController = SearchFilterController()
        filterController.delegate = self
        filterController.searchFilter = self.searchFilter
        
        self.navigationController?.pushViewController(filterController, animated: true)
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
