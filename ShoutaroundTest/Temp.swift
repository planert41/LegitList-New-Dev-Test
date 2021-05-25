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
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import GooglePlaces

//@objc protocol MainSearchControllerDelegate {
//
//    func filterControllerFinished(selectedCaption: String?, selectedRange: String?, selectedLocation: CLLocation?, selectedLocationName: String?, selectedGooglePlaceId: String?, selectedGooglePlaceType: [String]?, selectedMinRating: Double, selectedType: String?, selectedMaxPrice: String?, selectedSort: String, selectedLegit: Bool)
//
//
//    //    func filterCaptionSelected(searchedText: String?)
//    @objc optional func userSelected(uid: String?)
//    @objc optional func locationSelected(googlePlaceId: String?, googlePlaceName: String?, googlePlaceLocation: CLLocation?, googlePlaceType: [String]?)
//}

protocol TempMainSearchControllerDelegate {
    func filterControllerSelected(filter: Filter?)
    func refreshAll()
}


class TempMainSearchController : UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate, GMSAutocompleteTableDataSourceDelegate, SearchFilterControllerDelegate, MoreFilterViewDelegate {
    
    //    var allPosts: [Post] = []
    //    var filteredPosts: [Post] = []
    
    
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
        return tv
    }()
    
    var searchScopeButtons = ["Food","Cuisine","Meal","City","Advanced"]
    
    // Filter Post Variables
    var searchFilter: Filter? {
        didSet {
        }
    }
    
    
    func refreshFilter(){
        self.searchFilter?.clearFilter()
        self.updateViewsForSearchFilter()
    }
    
    func updateViewsForSearchFilter(){
        
        // Caption Search Bar
        if self.selectedScope == 0 || self.selectedScope == 1 || self.selectedScope == 2 {
            self.searchController.searchBar.text = searchFilter?.filterCaption
        } else if self.selectedScope == 3 {
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
        // Update Sort Emojis
        self.updateSortEmojiCounts(emojiCounts: emojiCounts)
        
        // Update Sort Location
        self.updateSortLocationCounts()
        
        // Update Views
        self.updateViewsForSearchFilter()
        
        self.tableView.reloadData()
    }
    
    
    
    func updateSortEmojiCounts(emojiCounts: [String:Int]) {
        Database.sortEmojisWithCounts(inputEmojis: defaultEmojis, emojiCounts: emojiCounts) { (sortedEmojis) in
            sortedFoodEmojis = sortedEmojis
            self.historicalFoodEmojiCounts = self.countSelectedEmojis(inputEmojis: sortedFoodEmojis)
        }
        
        Database.sortEmojisWithCounts(inputEmojis: cuisineEmojis, emojiCounts: emojiCounts, dictionaryMatch: true) { (sortedEmojis) in
            sortedCuisineEmojis = sortedEmojis
            self.historicalCuisineEmojiCounts = self.countSelectedEmojis(inputEmojis: sortedCuisineEmojis)
        }
        
        Database.sortEmojisWithCounts(inputEmojis: mealEmojis + dietEmojis, emojiCounts: emojiCounts, sort:false) { (sortedEmojis) in
            sortedMealEmojis = sortedEmojis
            self.historicalMealEmojiCounts = self.countSelectedEmojis(inputEmojis: sortedMealEmojis)
        }
    }
    
    
    func updateSortLocationCounts(){
        // Show all Locations
        var tempLoc: [String] = []
        for (key,value) in self.defaultLocationCounts {
            tempLoc.append(key)
        }
        self.allLocationLabels = tempLoc
        
        // Resort All Location Labels - Reversing to add the smallest one first
        for (key,value) in self.locationCounts.reversed() {
            if let index = self.allLocationLabels.firstIndex(of: key) {
                let tempLocation = self.allLocationLabels.remove(at: index)
                self.allLocationLabels.insert(tempLocation, at: 0)
            }
        }
        
    }
    
    
    
    // Emojis - Pulls in Default Emojis and Emojis filtered by searchText
    var defaultEmojiCounts:[String:Int] = [:]
    var emojiCounts:[String:Int] = [:]
    
    let EmojiCellId = "EmojiCellId"
    
    func countEmojiNumbers(inputEmojis: [EmojiBasic]?, emojiCount: [String:Int], matchDictionary: Bool = false) -> Int {
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
    
    func countSelectedEmojis(inputEmojis: [EmojiBasic]?) -> Int {
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
    
    func updateScopeBarCount(){
        var temp_scope = searchScopeButtons
        
        if self.historicalFoodEmojiCounts > 0 {
            temp_scope[0] = searchScopeButtons[0] + " \(self.historicalFoodEmojiCounts)"
        }
        
        if self.historicalCuisineEmojiCounts > 0 {
            temp_scope[1] = searchScopeButtons[1] + " \(self.historicalCuisineEmojiCounts)"
        }
        
        if self.historicalMealEmojiCounts > 0 {
            temp_scope[2] = searchScopeButtons[2] + " \(self.historicalMealEmojiCounts)"
        }
        
        if self.allLocationLabels.count > 0 {
            temp_scope[3] = searchScopeButtons[3] + " \(self.locationCounts.count)"
        }
        self.searchBar.scopeButtonTitles = temp_scope
    }
    
    // FOOD
    var sortedFoodEmojis:[EmojiBasic] = defaultEmojis
    var filteredFoodEmojis:[EmojiBasic] = []
    var historicalFoodEmojiCounts: Int = 0 {
        didSet{
            self.updateScopeBarCount()
        }
    }
    
    // Cuisine
    var sortedCuisineEmojis:[EmojiBasic] = cuisineEmojis
    var filteredCuisines:[EmojiBasic] = []
    var historicalCuisineEmojiCounts: Int = 0 {
        didSet{
            self.updateScopeBarCount()
        }
    }
    
    // Meal
    var sortedMealEmojis:[EmojiBasic] = mealEmojis + dietEmojis
    var filteredMeals:[EmojiBasic] = []
    var historicalMealEmojiCounts: Int = 0 {
        didSet{
            self.updateScopeBarCount()
        }
    }
    
    // Users
    let UserCellId = "UserCellId"
    var allUsers = [User]()
    var filteredUsers = [User]()
    
    // Google Locations
    let LocationCellId = "LocationCellId"
    var defaultLocationCounts:[String:Int] = [:]
    var locationCounts:[String:Int] = [:] {
        didSet {
            self.updateSortLocationCounts()
        }
    }
    var allLocationLabels:[String] = [] {
        didSet{
            self.updateScopeBarCount()
        }
    }
    var filteredLocationLabels:[String] = []
    
    var googleLocationSearchInd: Bool = false {
        didSet {
            print("googleLocationSearchInd | \(googleLocationSearchInd)")
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
        self.searchController.searchBar.selectedScopeButtonIndex = 0
        searchBar(searchBar, selectedScopeButtonIndexDidChange: 0)
    }
    
    func locationSearchTap() {
        self.searchController.searchBar.selectedScopeButtonIndex = 3
        searchBar(searchBar, selectedScopeButtonIndexDidChange: 3)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.legitColor()
        
        tableView.backgroundColor = UIColor.white
        tableView.register(SearchResultsCell.self, forCellReuseIdentifier: EmojiCellId)
        tableView.register(UserAndListCell.self, forCellReuseIdentifier: UserCellId)
        tableView.register(LocationCell.self, forCellReuseIdentifier: LocationCellId)
        tableView.allowsMultipleSelection = true
        view.addSubview(tableView)
        tableView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        
        
        setupNavigationController()
        setupSearchController()
        
        
        // Emojis are loaded in the emoji dictionary
        
        // Load Users
        Database.fetchALLUsers { (fetchedUsers) in
            self.allUsers = fetchedUsers.sorted(by: { (p1, p2) -> Bool in
                p1.votes_received > p2.votes_received
            })
            self.filteredUsers = self.allUsers
        }
        
        // Google Locations are only loaded when Locations are selected
        
        tableDataSource = GMSAutocompleteTableDataSource()
        tableDataSource?.delegate = self
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 140
        //        tableView.estimatedRowHeight = 200
        
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(increaseScope))
        swipeLeft.direction = .left
        self.tableView.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(decreaseScope))
        swipeRight.direction = .right
        self.tableView.addGestureRecognizer(swipeRight)
        
        
        view.addSubview(googleImage)
        googleImage.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 15)
        googleImage.backgroundColor = UIColor.clear
        googleImage.isHidden = true
        
        view.addSubview(moreFilterView)
        //        moreFilterView.backgroundColor = UIColor.yellow
        moreFilterView.anchor(top: tableView.topAnchor, left: view.leftAnchor, bottom: tableView.bottomAnchor, right: tableView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        moreFilterView.isHidden = true
        
    }
    
    func setupNavigationController(){
        
        self.navigationController?.view.backgroundColor = UIColor.legitColor()
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.barTintColor = UIColor.legitColor()
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.white, NSAttributedString.Key.font.rawValue: UIFont(font: .noteworthyBold, size: 20)])
        
        var searchItem = ""
        if self.searchFilter?.filterList != nil {
            searchItem = " " + (self.searchFilter?.filterList?.name)!
        } else if self.searchFilter?.filterUser != nil {
            searchItem = " " + (self.searchFilter?.filterUser?.username)!
        }
        
        self.navigationItem.title = "Search" + searchItem
        self.navigationController?.navigationBar.layoutIfNeeded()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: (#imageLiteral(resourceName: "filter")).withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleFilter))
    }
    
    
    @objc func increaseScope(){
        self.changeScope(change: 1)
    }
    
    @objc func decreaseScope(){
        self.changeScope(change: -1)
    }
    
    func changeScope(change: Int){
        self.selectedScope = min(max(0, self.selectedScope + change),(searchBar.scopeButtonTitles?.count)! - 1)
        self.searchBar.selectedScopeButtonIndex = self.selectedScope
    }
    
    
    
    func setupSearchController(){
        //        navigationController?.navigationBar.barTintColor = UIColor.white
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchBar = searchController.searchBar
        
        //        navigationItem.titleView = searchController.searchBar
        
        if self.enableScopeOptions {
            searchBar.scopeButtonTitles = searchScopeButtons
            self.updateScopeBarCount()
            searchBar.showsScopeBar = self.enableScopeOptions
        }
        
        
        
        searchBar.sizeToFit()
        searchBar.delegate = self
        searchBar.placeholder =  searchBarPlaceholderText_Emoji
        searchBar.showsCancelButton = false
        searchController.searchBar.showsCancelButton = false
        
        searchBar.barTintColor = UIColor.white
        searchBar.tintColor = UIColor.white
        searchBar.backgroundColor = UIColor.legitColor()
        definesPresentationContext = true
        
        let textFieldInsideUISearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.textColor = UIColor.legitColor()
        //        textFieldInsideUISearchBar?.font = textFieldInsideUISearchBar?.font?.withSize(12)
        
        
        for s in searchBar.subviews[0].subviews {
            if s is UITextField {
                s.layer.borderWidth = 0.5
                s.layer.borderColor = UIColor.gray.cgColor
                s.layer.cornerRadius = 10
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
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // Emojis
        if self.selectedScope == 0 {
            return isFiltering ? filteredFoodEmojis.count : sortedFoodEmojis.count
        }
        
        // Cuisines
        if self.selectedScope == 1 {
            return isFiltering ? filteredCuisines.count : sortedCuisineEmojis.count
        }
        
        // Meals
        if self.selectedScope == 2 {
            return isFiltering ? filteredMeals.count : sortedMealEmojis.count
        }
            
            // Locations
        else if self.selectedScope == 3 && !googleLocationSearchInd{
            return isFiltering ? filteredLocationLabels.count + 1 : allLocationLabels.count + 1
        }
            
            // Other
        else if self.selectedScope == 4 {
            return 0
        }
            
            // Google Locations - Data source changes to Google AutoComplete
        else {
            return 0
        }
    }
    
    
    //            if isFiltering{
    //                cell.emoji = filteredFoodEmojis[indexPath.row]
    //            } else {
    //                cell.emoji = sortedFoodEmojis[indexPath.row]
    //            }
    //
    //            if let count = emojiCounts[(cell.emoji?.emoji)!] {
    //                cell.postCount = count
    //            } else {
    //                cell.postCount = 0
    //            }
    //
    //            if self.captionFiltered != nil {
    //                cell.isSelected = (self.captionFiltered != nil) ? (self.captionFiltered?.contains((cell.emoji?.emoji)!))! : false
    //            } else {
    //                cell.isSelected = false
    //            }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Emojis
        if self.selectedScope == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: EmojiCellId, for: indexPath) as! SearchResultsCell
            let displayEmoji = isFiltering ? filteredFoodEmojis[indexPath.row] : sortedFoodEmojis[indexPath.row]
            cell.emoji = displayEmoji
            cell.isSelected = (self.searchFilter?.filterCaption != nil) ? (self.searchFilter?.filterCaption?.contains((cell.emoji?.emoji)!))! : false
            cell.postCount = (emojiCounts[displayEmoji.emoji] ?? 0)
            
            if isFiltering && cell.postCount == 0 {
                cell.postCount = (defaultEmojiCounts[displayEmoji.emoji] ?? 0)
                cell.grayed = true
            }
            
            
            // Display Default Emoji Count if Not Filtering
            //            cell.postCount = isFiltering ? displayEmoji.count : (defaultEmojiCounts[displayEmoji.emoji] ?? 0)
            
            return cell
        }
            
            // Cuisines
        else if self.selectedScope == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: EmojiCellId, for: indexPath) as! SearchResultsCell
            let displayEmoji = isFiltering ? filteredCuisines[indexPath.row] : sortedCuisineEmojis[indexPath.row]
            cell.emoji = displayEmoji
            //            cell.postCount = emojiCounts[(cell.emoji?.emoji)!] ?? 0
            cell.isSelected = (self.searchFilter?.filterCaption != nil) ? (self.searchFilter?.filterCaption?.contains((cell.emoji?.emoji)!))! : false
            cell.postCount = (emojiCounts[displayEmoji.name!] ?? 0) + (emojiCounts[displayEmoji.emoji] ?? 0)
            
            if isFiltering && cell.postCount == 0 {
                cell.postCount = (defaultEmojiCounts[displayEmoji.name!] ?? 0) + (defaultEmojiCounts[displayEmoji.emoji] ?? 0)
                cell.grayed = true
            }
            
            // Display Default Emoji Count if Not Filtering
            //            cell.postCount = isFiltering ? displayEmoji.count : (defaultEmojiCounts[displayEmoji.name!] ?? 0)
            
            return cell
        }
            
            // Meals
        else if self.selectedScope == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: EmojiCellId, for: indexPath) as! SearchResultsCell
            let displayEmoji = isFiltering ? filteredMeals[indexPath.row] : sortedMealEmojis[indexPath.row]
            cell.emoji = displayEmoji
            //            cell.postCount = emojiCounts[(cell.emoji?.emoji)!] ?? 0
            cell.isSelected = (self.searchFilter?.filterCaption != nil) ? (self.searchFilter?.filterCaption?.contains((cell.emoji?.emoji)!))! : false
            cell.postCount = (emojiCounts[displayEmoji.name!] ?? 0)
            
            if isFiltering && cell.postCount == 0 {
                cell.postCount = (defaultEmojiCounts[displayEmoji.name!] ?? 0)
                cell.grayed = true
            }
            
            // Display Default Emoji Count if Not Filtering
            //            cell.postCount = isFiltering ? displayEmoji.count : (defaultEmojiCounts[displayEmoji.name!] ?? 0)
            return cell
        }
            
            // Locations
            
        else if self.selectedScope == 3 && !googleLocationSearchInd {
            let cell = tableView.dequeueReusableCell(withIdentifier: LocationCellId, for: indexPath) as! LocationCell
            
            if indexPath.row == 0 {
                // First Row - Add Search for Google Cell
                let curLabel = NSMutableAttributedString(string: "Search Google 🔍 (Press Enter)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.mainBlue(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 16)]))
                cell.locationName = nil
                cell.postCount = 0
                cell.locationTextLabel.attributedText = curLabel
                
            } else {
                let curLabel = isFiltering ? filteredLocationLabels[indexPath.row-1] : allLocationLabels[indexPath.row-1]
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
    
    @objc func handleFilter(){
        if let addFilter = self.moreFilterView.searchFilter {
            // Location Filters always get transferred to advanced tab if exists since one click on location is filtered right away
            // Does not stay on filter once a location is selected
            
            // Only grab caption filter from the main search filter. Rest of filter comes from the advanced tab
            addFilter.filterCaption = self.searchFilter?.filterCaption
            self.searchFilter = addFilter
        }
        self.delegate?.filterControllerSelected(filter: searchFilter)
        self.navigationController?.popViewController(animated: true)
    }
    
    func filterCaptionSelected(searchedText: String?){
        searchFilter?.filterCaption = searchedText
        self.delegate?.filterControllerSelected(filter: searchFilter)
        self.navigationController?.popViewController(animated: true)
    }
    
    
    
    
    //    func openGoogleSearch(){
    //            print("Open Google Location Search")
    //            let autocompleteController = GMSAutocompleteViewController()
    //            autocompleteController.delegate = self
    //            present(autocompleteController, animated: true, completion: nil)
    //    }
    
    
    //    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    //        // Emoji Selected
    //        print("Deselect")
    //        if selectedScope == 0 {
    //            var emojiSelected: Emoji?
    //            if isFiltering {
    //                emojiSelected = filteredFoodEmojis[indexPath.row]
    //            } else {
    //                emojiSelected = sortedFoodEmojis[indexPath.row]
    //            }
    //            let filterText = emojiSelected?.emoji
    //            var captionComponents = captionFiltered?.components(separatedBy: " ")
    //            if let index = captionComponents?.index(of: filterText!) {
    //                captionComponents?.remove(at: index)
    //                self.captionFiltered = captionComponents?.joined(separator: " ")
    //            }
    //
    //            //            searchFilter?.filterCaption = filterText
    //        }
    //
    //        // Emoji Selected
    //        if selectedScope == 1 {
    //            var emojiSelected: Emoji?
    //            if isFiltering {
    //                emojiSelected = filteredCuisines[indexPath.row]
    //            } else {
    //                emojiSelected = sortedCuisineEmojis[indexPath.row]
    //            }
    //            let filterText = emojiSelected?.emoji
    //            var captionComponents = captionFiltered?.components(separatedBy: " ")
    //            if let index = captionComponents?.index(of: filterText!) {
    //                captionComponents?.remove(at: index)
    //                self.captionFiltered = captionComponents?.joined(separator: " ")
    //            }
    //        }
    //
    //        // User Selected
    //        if selectedScope == 2 {
    //            var userSelected: User?
    //            if isFiltering {
    //                userSelected = filteredUsers[indexPath.row]
    //            } else {
    //                userSelected = allUsers[indexPath.row]
    //            }
    //
    //            searchFilter?.filterUser = userSelected
    //        }
    //
    //        // Location Selected
    //        if selectedScope == 3 && !googleLocationSearchInd {
    //            var locationIDSelected: String?
    //            if indexPath.row == 0 {
    //                print("Search Google Location Pressed")
    //                self.googleLocationSearchInd = true
    //            } else {
    //                if isFiltering {
    //                    locationIDSelected = filteredLocationLabels[indexPath.row - 1]
    //                } else {
    //                    locationIDSelected = allLocationLabels[indexPath.row - 1]
    //                }
    //                searchFilter?.filterLocationSummaryID = locationIDSelected
    //
    //            }
    //        }
    //    }
    
    func addEmojiToSearchTerm(inputEmoji: EmojiBasic?) {
        guard let inputEmoji = inputEmoji else {return}
        guard let searchBarText = self.searchBar.text else {return}
        var tempSearchBarText = searchBarText.components(separatedBy: " ")
        
        var emojiLabel = inputEmoji.name
        var emojiText = inputEmoji.emoji
        var emojiLabel_Array = emojiLabel?.components(separatedBy: " ")
        var finalSearchCaption: String = ""
        
        if searchBarText.contains(emojiText) {
            print("Deselecting \(emojiText) | \(index)")
            finalSearchCaption = searchBarText.replacingOccurrences(of: emojiText + " ", with: "")
            self.searchFilter?.filterCaption = finalSearchCaption
            self.searchBar.text = finalSearchCaption
            //            self.captionFiltered = finalSearchCaption
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
        self.searchFilter?.filterCaption = finalSearchCaption
        self.searchBar.text = finalSearchCaption
        //        self.captionFiltered = finalSearchCaption
        
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.cellForRow(at: indexPath)?.backgroundColor = UIColor.mainBlue().withAlphaComponent(0.2)
        
        // Emoji Selected
        if self.selectedScope == 0 {
            var emojiSelected: EmojiBasic?
            emojiSelected = isFiltering ? filteredFoodEmojis[indexPath.row] : sortedFoodEmojis[indexPath.row]
            self.addEmojiToSearchTerm(inputEmoji: emojiSelected)
        }
            
        else if self.selectedScope == 1 {
            var emojiSelected: EmojiBasic?
            emojiSelected = isFiltering ? filteredCuisines[indexPath.row] : sortedCuisineEmojis[indexPath.row]
            self.addEmojiToSearchTerm(inputEmoji: emojiSelected)
        }
            
        else if self.selectedScope == 2 {
            var emojiSelected: EmojiBasic?
            emojiSelected = isFiltering ? filteredMeals[indexPath.row] : sortedMealEmojis[indexPath.row]
            self.addEmojiToSearchTerm(inputEmoji: emojiSelected)
        }
            
            // Location Selected
        else if selectedScope == 3 && !googleLocationSearchInd {
            var locationIDSelected: String?
            if indexPath.row == 0 {
                print("Search Google Location Pressed")
                self.googleLocationSearchInd = true
            } else {
                // Selected a City Summary ID
                locationIDSelected = isFiltering ? filteredLocationLabels[indexPath.row - 1] : allLocationLabels[indexPath.row - 1]
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
    
    func sortContentForSearchText(_ searchText: String) {
        // Emojis
        if self.selectedScope <= 2 {
            // Emojis, Diets, Meals
            //                filteredFoodEmojis.sort { (p1, p2) -> Bool in
            //                    ((searchText.contains(p1.emoji)) ? 0 : 1) < ((searchText.contains(p2.emoji)) ? 0 : 1)
            //                }
            filteredFoodEmojis = sortedFoodEmojis
            filteredCuisines = sortedCuisineEmojis
            filteredMeals = sortedMealEmojis
            
            filteredFoodEmojis.sort { (p1, p2) -> Bool in
                ((searchText.contains(p1.emoji)) ? 0 : 1) < ((searchText.contains(p2.emoji)) ? 0 : 1)
            }
            filteredCuisines.sort { (p1, p2) -> Bool in
                ((searchText.contains(p1.emoji)) ? 0 : 1) < ((searchText.contains(p2.emoji)) ? 0 : 1)
            }
            filteredMeals.sort { (p1, p2) -> Bool in
                ((searchText.contains(p1.emoji)) ? 0 : 1) < ((searchText.contains(p2.emoji)) ? 0 : 1)
            }
        } else if self.selectedScope == 3 {
            filteredLocationLabels = allLocationLabels
            filteredLocationLabels.sort { (p1, p2) -> Bool in
                ((searchText.contains(p1)) ? 0 : 1) < ((searchText.contains(p2)) ? 0 : 1)
            }
        }
    }
    
    func filterContentForSearchText(_ searchText: String) {
        // Filter for Emojis and Users
        
        let searchCaption = searchText.emojilessString
        let searchCaptionArray = searchText.emojilessString.lowercased().components(separatedBy: " ")
        
        var lastWord = searchCaptionArray[searchCaptionArray.endIndex - 1]
        //        print("searchCaptionArray | \(searchCaptionArray) | lastWord | \(lastWord)")
        
        //     cell.isSelected = (self.captionFiltered != nil) ? (self.captionFiltered?.contains((cell.emoji?.emoji)!))! : false
        
        
        
        // Emojis
        if self.selectedScope == 0 {
            //            filteredFoodEmojis = sortedFoodEmojis.filter({( emoji : Emoji) -> Bool in
            //                return emoji.emoji.lowercased().contains(searchCaption.lowercased()) || (emoji.name?.contains(searchCaption.lowercased()))! })
            
            if lastWord.isEmptyOrWhitespace() {
                // If no text, all emojis, then no filter. Show all emojis
                filteredFoodEmojis = sortedFoodEmojis
            } else {
                // If contains text, filter emojis for remaining word
                filteredFoodEmojis = sortedFoodEmojis.filter({( emoji : EmojiBasic) -> Bool in
                    return searchCaptionArray.contains(emoji.name!) || (emoji.name?.contains(lastWord))!})
            }
            
            filteredFoodEmojis.sort { (p1, p2) -> Bool in
                ((p1.name?.hasPrefix(lastWord.lowercased()))! ? 0 : 1) < ((p2.name?.hasPrefix(lastWord.lowercased()))! ? 0 : 1)
            }
        }
            
            // Cusines
        else if self.selectedScope == 1 {
            
            if lastWord.isEmptyOrWhitespace() {
                // If no text, all emojis, then no filter. Show all emojis
                filteredCuisines = sortedCuisineEmojis
            } else {
                // If contains text, filter emojis for remaining word
                filteredCuisines = sortedCuisineEmojis.filter({( emoji : EmojiBasic) -> Bool in
                    return searchCaptionArray.contains(emoji.name!) || (emoji.name?.contains(lastWord))!})
            }
            
            filteredCuisines.sort { (p1, p2) -> Bool in
                ((p1.name?.hasPrefix(lastWord.lowercased()))! ? 0 : 1) < ((p2.name?.hasPrefix(lastWord.lowercased()))! ? 0 : 1)
            }
        }
            
            // Cusines
        else if self.selectedScope == 2 {
            
            if lastWord.isEmptyOrWhitespace() {
                // If no text, all emojis, then no filter. Show all emojis
                filteredMeals = sortedMealEmojis
            } else {
                // If contains text, filter emojis for remaining word
                filteredMeals = sortedMealEmojis.filter({( emoji : EmojiBasic) -> Bool in
                    return searchCaptionArray.contains(emoji.name!) || (emoji.name?.contains(lastWord))!})
            }
            
            filteredMeals.sort { (p1, p2) -> Bool in
                ((p1.name?.hasPrefix(lastWord.lowercased()))! ? 0 : 1) < ((p2.name?.hasPrefix(lastWord.lowercased()))! ? 0 : 1)
            }
        }
            
            
            //            // Users
            //        else if self.selectedScope == 2 {
            //            filteredUsers = self.allUsers.filter { (user) -> Bool in
            //                return user.username.lowercased().contains(searchCaption.lowercased())
            //            }
            //        }
            
            // Locations
        else if self.selectedScope == 3 && !self.googleLocationSearchInd{
            filteredLocationLabels = allLocationLabels.filter({ (string) -> Bool in
                return string.lowercased().contains(searchCaption.lowercased())
            })
            filteredLocationLabels.sort { (p1, p2) -> Bool in
                ((p1.hasPrefix(searchCaption.lowercased())) ? 0 : 1) < ((p2.hasPrefix(searchCaption.lowercased())) ? 0 : 1)
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
            if self.selectedScope == 0 || self.selectedScope == 1 || self.selectedScope == 2 || (self.selectedScope == 3 && !self.googleLocationSearchInd){
                filterContentForSearchText(searchBar.text!)
            } else if self.selectedScope == 3  && self.googleLocationSearchInd {
                print("Google Search Text |\(searchBar.text!)")
                tableDataSource?.sourceTextHasChanged(searchBar.text!)
            }
        }
    }
    
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        self.searchBar.sizeToFit()
        if self.selectedScope == 4 {
            // Activate Food Search Bar if user clicks on search bar at more filter view
            self.captionSearchTap()
        }
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        self.searchBar.sizeToFit()
        return true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //      Remove Searchbar scope during transition
        //        self.searchBar.isHidden = true
        //        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //      Show Searchbar scope during transition
        //        self.searchBar.isHidden = false
        self.setupNavigationController()
        //        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            self.searchController.searchBar.becomeFirstResponder()
        }
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchBar.text?.isEmptyOrWhitespace())! {
            // All Search Bar Text is blank but might contain spaces. Remove Spaces
            print("Empty Search Bar. Replacing All Spaces")
            searchBar.text?.replacingOccurrences(of: " ", with: "")
        }
        
        if (searchBar.text?.isEmpty)! {
            if self.selectedScope == 0 || self.selectedScope == 1 || self.selectedScope == 2 {
                self.searchFilter?.filterCaption = nil
            } else if self.selectedScope == 3 {
                self.searchFilter?.clearFilterLocation()
                print("Clear Location Filter")
            }
            self.isFiltering = false
            self.googleLocationSearchInd = false
            self.updateSortEmojiCounts(emojiCounts: defaultEmojiCounts)
        } else {
            self.isFiltering = true
            if self.selectedScope == 0 || self.selectedScope == 1 || self.selectedScope == 2{
                self.searchFilter?.filterCaption = searchText
            }
        }
        
        
    }
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if self.selectedScope == 3 && !self.googleLocationSearchInd{
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
        self.delegate?.refreshAll()
        self.navigationController?.popViewController(animated: true)
        
        //        if !(searchBar.text?.isEmptyOrWhitespace())! {
        //            self.filterCaptionSelected(searchedText: searchBar.text)
        //        } else {
        //            self.filterCaptionSelected(searchedText: nil)
        //        }
    }
    
    var tempCaptionSearchBarText: String = ""
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        print("Selected Scope is: ", selectedScope)
        self.selectedScope = selectedScope
        self.tableView.dataSource = self
        self.tableView.delegate = self
        // Refreshes to non-Google Search Location if Search Tab is clicked
        self.googleLocationSearchInd = false
        
        // Changing Scope Resets and Resorts all selections inetad of just changing the counts
        
        
        
        if selectedScope == 0 || selectedScope == 1 || selectedScope == 2 || selectedScope == 3 {
            if self.isFiltering && self.searchFilter?.filterCaption != nil {
                //                filterContentForSearchText(self.searchBar.text!)
                
                // We show all possibilities but sort it by selected items first. Once they start typing, then we filter out again
                //                sortContentForSearchText(self.searchBar.text!)
                self.setupInitialSelections()
                
            }
            self.moreFilterView.isHidden = true
        } else if selectedScope == 4 {
            self.moreFilterView.isHidden = false
        }
        
        if selectedScope == 0 || selectedScope == 1 || selectedScope == 2 {
            // Display Filtered Caption when emoji tab selected
            self.searchBar.placeholder = searchBarPlaceholderText_Emoji
            self.searchBar.text = self.searchFilter?.filterCaption
            
        } else if selectedScope == 3 {
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
            
        } else if selectedScope == 4 {
            self.searchBar.placeholder = searchBarPlaceholderText_Location
            moreFilterView.searchFilter = self.searchFilter
            moreFilterView.filterCaptionLabel.text = self.searchFilter?.filterCaption
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
