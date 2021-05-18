//
//  SearchBarTableViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 7/30/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit

import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth

protocol SearchBarTableViewControllerDelegate: class {
    func hideSearchBar()
    func filterControllerSelected(filter: Filter?)
//    func locationSearchTap()
//    func filterControllerSelected(filter: Filter?)
//    func refreshFilter()
    //    func filterControllerSelected(filter: Filter?)
}

class SearchBarTableViewController: UITableViewController, UISearchBarDelegate, UISearchResultsUpdating, UISearchControllerDelegate {

    var delegate: SearchBarTableViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    
    
    func setupRandomPlaceholder(){
        
        let randomFood = SET_FoodEmojis[Int.random(in: 0 ... (SET_FoodEmojis.count - 1))]
        let randomFlag = cuisineEmojiSelect[Int.random(in: 0 ... (cuisineEmojiSelect.count - 1))]
        let randomSnack = SET_SnackEmojis[Int.random(in: 0 ... (SET_SnackEmojis.count - 1))]

        let placeholderText = "Search Food  \(randomFood)  Or Cuisine  \(randomFlag)"
        searchBar.placeholder = placeholderText
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.setupRandomPlaceholder()
        self.searchBar.becomeFirstResponder()
        self.setSelections()

//        self.fetchAllUsers()
    }

    let EmojiCellId = "EmojiCellId"
    let UserCellId = "UserCellId"
    let ListCellId = "ListCellId"
    let LocationCellId = "LocationCellId"

    var searchFilter: Filter? {
        didSet {
            self.searchText = self.searchFilter?.filterCaption
            self.selectedLocation = self.searchFilter?.filterLocationSummaryID

            self.filterContentForSearchText(self.searchFilter?.filterCaption ?? "")
            self.searchUserText = self.searchFilter?.filterUser?.username
            self.searchUser = self.searchFilter?.filterUser
            self.isFiltering = self.searchFilter?.isFiltering ?? false
        }
    }
    
    var isFiltering: Bool = false
    
    var searchUserText: String? = nil
    var searchUser: User? = nil
    var searchText: String? = nil {
        didSet {
            self.searchBar.text = searchText
        }
    }
    
    var searchCategory: Int = 0 {
        didSet {
            if let searchText = self.searchBar.text {
                self.filterContentForSearchText(searchText)
            }
            self.tableView.reloadData()
        }
    }
    var searchOptions = SearchBarOptions

    
    /*
     // Home Search Bar Sort
     var SearchBarOptions:[String] = [SearchAll, SearchEmojis, SearchLocation,SearchUser]
     
     let SearchBarOptionsDefault:String = SearchBarOptions[0]
     0 var SearchAll = "All"
     1 var SearchEmojis = "Emoji"
     2 var SearchUser = "User"
     3 var SearchLocation = "Location"
     */

    
    var defaultEmojiCounts:[String:Int] = [:] {
        didSet {
//            self.setSelections()
        }
    }
    var displayEmojis:[EmojiBasic] = []
    var filteredEmojis:[EmojiBasic] = []
    
    
    var defaultLocationCounts:[String:Int] = [:] {
        didSet {
//            self.setSelections()
        }
    }
    var displayLocations: [String] = []
    var filteredLocations: [String] = []
    var selectedLocation: String? = nil
    
    var allUsers = [User]()
    var filteredUsers = [User]()
    
    var allResultsDic: [String:String] = [:]
    var defaultAllResults:[String] = []
    var aggregateAllResults:[String] = []
    var filteredAllResults:[String] = []

    func clearDisplayOptions(){
        displayEmojis.removeAll()
        filteredEmojis.removeAll()
        displayLocations.removeAll()
        filteredLocations.removeAll()
        allUsers.removeAll()
        filteredUsers.removeAll()
        aggregateAllResults.removeAll()
        filteredAllResults.removeAll()
    }
    
    func fetchAllUsers(){
        // Load Users
        Database.fetchALLUsers { (fetchedUsers) in
//            self.allUsers = fetchedUsers
            
            self.allUsers = fetchedUsers.sorted(by: { (p1, p2) -> Bool in
                p1.posts_created > p2.posts_created
            })
            
            self.filteredUsers = self.allUsers
            self.setSelections()
            self.tableView.reloadData()
        }
    }
    
    func setSelections(){
    // EMOJIS
            Database.sortEmojisWithCounts(inputEmojis: allSearchEmojis, emojiCounts: defaultEmojiCounts, dictionaryMatch: true, sort: true) { (userEmojis) in
                
                let sortedEmojis = userEmojis.sorted(by: { (p1, p2) -> Bool in
                    p1.count > p2.count
                })
                
                self.displayEmojis = sortedEmojis
                self.filteredEmojis = sortedEmojis
            }
        
        // USERS
//            for x in allUsers {
//                allResults[x.username.lowercased()] = SearchUser
//            }
        
        
        // LOCATIONS
        var tempLocation: [String] = []

        let tempCounts = defaultLocationCounts.sorted { (val1, val2) -> Bool in
            
            return val1.value > val2.value
        }
        
            for (y,value) in tempCounts {
                allResultsDic[y.lowercased()] = SearchPlace
                tempLocation.append(y)
            }
        
        self.displayLocations = tempLocation
        self.filteredLocations = tempLocation
        
    // ALL RESULT OPTIONS
        allResultsDic = [:]
        defaultAllResults = []
        
        for (index, a) in self.displayEmojis.enumerated() {
//            let emoji = a.emoji
//            allResultsDic[a.emoji] = SearchEmojis
            
            if let name = a.name {
                allResultsDic[name] = SearchEmojis
                
                if index <= 10 {
                    defaultAllResults.append(name)
                }
            }
        }
        
        for (index, b) in self.displayLocations.enumerated() {
            allResultsDic[b] = SearchPlace
            
            if index <= 10 {
                defaultAllResults.append(b)
            }
        }
        
        for (index, c) in self.allUsers.enumerated() {
            allResultsDic[c.username] = SearchUser
            
            if index <= 10 {
                defaultAllResults.append(c.username)
            }
        }
        
        
        // ALL RESULTS - Emoji Name, Location Name, User Name
        for (key,value) in allResultsDic {
            self.aggregateAllResults.append(key)
        }
        
        
        
        // DEFAULT ALL RESULTS - Show top 10 of all Results
        
        
        print("Set Selections | \(self.displayEmojis.count) Emojis | \(self.displayLocations.count) Locations")
        self.tableView.reloadData()

        
    }
    
    var headerView = UIView()
    let searchController = UISearchController(searchResultsController: nil)

    var searchBar = UISearchBar()


    lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
//        button.setImage(#imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysOriginal), for: .normal)
        let cancelTitle = NSAttributedString(string: "Cancel", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextMedium, size: 16)])
        
        button.setAttributedTitle(cancelTitle, for: .normal)
        button.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.clipsToBounds = true
        return button
    }()
    
    func didTapCancel(){
//        self.view.isHidden = true
        print(" SearchBarTV - Hide Search Bar")
        self.searchBar.resignFirstResponder()
        self.delegate?.hideSearchBar()
    }
    
    
    
    func setupSearchBar(){
        searchBar.sizeToFit()
        searchBar.delegate = self
        searchBar.placeholder =  searchBarPlaceholderText_Emoji
        searchBar.showsCancelButton = false
        
        searchBar.barTintColor = UIColor.white
        searchBar.tintColor = UIColor.white
        searchBar.backgroundColor = UIColor.white
        searchBar.searchBarStyle = .minimal
        searchBar.layer.borderWidth = 0
        definesPresentationContext = false
        
        searchBar.layer.applySketchShadow()
        self.setupRandomPlaceholder()
        
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
        
        tableView.tableHeaderView = searchController.searchBar
        navigationItem.hidesSearchBarWhenScrolling  = false
        
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
            filterContentForSearchText(searchBar.text!)
        } else {
            
        }
        
    }

    
    func filterContentForSearchText(_ searchText: String) {
        let searchCaption = searchText.emojilessString.lowercased()
        let searchCaptionArray = searchText.emojilessString.lowercased().components(separatedBy: " ")
        let searchCaptionEmojis = searchText.emojis
        var lastWord = searchCaptionArray[searchCaptionArray.endIndex - 1]

        if searchCaption == "" {
            filteredAllResults = aggregateAllResults
            filteredEmojis = displayEmojis
            filteredUsers = allUsers
            filteredLocations = displayLocations
        } else {
            
        if SearchBarOptions[self.searchCategory] == SearchAll {
            // ALL RESULTS
//            if searchCaption.removingWhitespaces() == "" {
//                filteredAllResults = self.aggregateAllResults
//                self.tableView.reloadData()
//                return
//            } else {
//                filteredAllResults = aggregateAllResults.filter { (option) -> Bool in
//                    return option.lowercased().contains(searchCaption) || searchCaptionArray.contains(option.lowercased()) || searchCaptionEmojis.contains(option)
//                }
//            }
            
            filteredAllResults = aggregateAllResults.filter { (option) -> Bool in
                return option.lowercased().contains(searchCaption) || searchCaptionArray.contains(option.lowercased()) || searchCaptionEmojis.contains(option)
            }
            
            if searchCaption.removingWhitespaces() == "" {
                filteredAllResults += (self.defaultAllResults)
            }

            
            filteredAllResults.sort { (p1, p2) -> Bool in
            
                var p1Count = 0
                var p2Count = 0
                
                if allResultsDic[p1] == SearchEmojis {
                    p1Count = defaultEmojiCounts[p1] ?? 0
                } else if allResultsDic[p1] == SearchPlace {
                    p1Count = defaultLocationCounts[p1] ?? 0
                } else if allResultsDic[p1] == SearchUser {
                    var tempUser = allUsers.filter({ (user) -> Bool in
                        return user.username.contains(p1)
                    })
                    if tempUser.count > 0 {
                        p1Count = tempUser[0].posts_created
                    } else {
                        p1Count = 0
                    }                } else {
                    p1Count = 0
                }
                
                if allResultsDic[p2] == SearchEmojis {
                    p2Count = defaultEmojiCounts[p2] ?? 0
                } else if allResultsDic[p2] == SearchPlace {
                    p2Count = defaultLocationCounts[p2] ?? 0
                } else if allResultsDic[p2] == SearchUser {
                    var tempUser = allUsers.filter({ (user) -> Bool in
                        return user.username.contains(p2)
                    })
                    if tempUser.count > 0 {
                        p2Count = tempUser[0].posts_created
                    } else {
                        p2Count = 0
                    }
                } else {
                    p2Count = 0
                }
                
                return p1Count > p2Count
            }
            
            // REMOVE DUPS
            var tempResults: [String] = []
            for x in filteredAllResults {
                if !tempResults.contains(x) {
                    tempResults.append(x)
                }
            }
            filteredAllResults = tempResults
            print("FilterContentResults | \(searchText) | \(filteredAllResults.count) Filtered All | \(defaultAllResults.count) All")
            
        }
        
        else if SearchBarOptions[self.searchCategory] == SearchEmojis {
        // Filter Food
            if searchCaption.removingWhitespaces() == "" {
                 filteredEmojis = displayEmojis
                self.tableView.reloadData()
                return
            } else {
                filteredEmojis = displayEmojis.filter({( emoji : EmojiBasic) -> Bool in
                    return searchCaptionArray.contains(emoji.name!) || searchCaptionEmojis.contains(emoji.emoji) || (emoji.name?.contains(lastWord))!})
            }
            
            filteredEmojis.sort { (p1, p2) -> Bool in
                let p1Ind = ((p1.name?.hasPrefix(lastWord.lowercased()))! ? 0 : 1)
                let p2Ind = ((p2.name?.hasPrefix(lastWord.lowercased()))! ? 0 : 1)
                if p1Ind != p2Ind {
                    return p1Ind < p2Ind
                } else {
                    return p1.count > p2.count
                }
            }
            
            // REMOVE DUPS
            var tempResults: [EmojiBasic] = []
            
            for x in filteredEmojis {
                if !tempResults.contains(where: { (emoji) -> Bool in
                    return emoji.name == x.name
                }){
                    tempResults.append(x)
                }
            }

            filteredEmojis = tempResults
            print("FilterContentResults | \(searchText) | \(filteredEmojis.count) Filtered Emojis | \(displayEmojis.count) Emojis")

        }
            
        else if SearchBarOptions[self.searchCategory] == SearchUser {
            if searchCaption.removingWhitespaces() == "" {
                filteredUsers = allUsers
                self.tableView.reloadData()
                return

            } else {
                filteredUsers = allUsers.filter({ (user) -> Bool in
                    return user.username.lowercased().contains(searchCaption.lowercased())
                })
            }
            

            filteredUsers.sort { (p1, p2) -> Bool in
                let p1Ind = ((p1.username.hasPrefix(searchCaption.lowercased())) ? 0 : 1)
                let p2Ind = ((p2.username.hasPrefix(searchCaption.lowercased())) ? 0 : 1)
                if p1Ind != p2Ind {
                    return p1Ind < p2Ind
                } else {
                    return p1.posts_created > p2.posts_created
                }
            }
            
            // REMOVE DUPS
            var tempResults: [User] = []
            
            for x in filteredUsers {
                if !tempResults.contains(where: { (user) -> Bool in
                    return user.username == x.username
                }){
                    tempResults.append(x)
                }
            }
            filteredUsers = tempResults
            print("FilterContentResults | \(searchText) | \(filteredUsers.count) Filtered Users | \(allUsers.count) Users")
            
        }
        
        else if SearchBarOptions[self.searchCategory] == SearchPlace {
            if searchCaption.removingWhitespaces() == "" {
                filteredLocations = displayLocations
                self.tableView.reloadData()
                return
            } else {
                filteredLocations = displayLocations.filter({ (string) -> Bool in
                    return string.lowercased().contains(searchCaption.lowercased())
                })
            }
            
            

            filteredLocations.sort { (p1, p2) -> Bool in
                let p1Ind = ((p1.hasPrefix(searchCaption.lowercased())) ? 0 : 1)
                let p2Ind = ((p2.hasPrefix(searchCaption.lowercased())) ? 0 : 1)
                if p1Ind != p2Ind {
                    return p1Ind < p2Ind
                } else {
                    return p1.count > p2.count
                }
            }
            
            // REMOVE DUPS
            var tempResults: [String] = []
            
            for x in filteredLocations {
                if !tempResults.contains(x) {
                    tempResults.append(x)
                }
            }
        
            filteredLocations = tempResults
            print("FilterContentResults | \(searchText) | \(filteredLocations.count) Filtered Locations | \(displayLocations.count) Locations")

            }
            
    }
        self.tableView.reloadData()
        
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
//        let searchBar = searchController.searchBar
        if (searchBar.text?.isEmpty)! {
            // Displays Default Search Results even if search bar is empty
            self.isFiltering = false
            searchController.searchResultsController?.view.isHidden = false
        } else {
            self.isFiltering = true
            filterContentForSearchText(searchBar.text!)
        }
        self.tableView.reloadData()

//        self.isFiltering = searchController.isActive && !(searchBar.text?.isEmpty)!
//        if self.isFiltering {
//            filterContentForSearchText(searchBar.text!)
//        } else {
//
//        }
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {

        self.isFiltering = !(searchBar.text?.isEmpty)!
        self.searchText = searchBar.text!        
        self.handleFilter()

    }
    
    // MARK: - Table view data source
    func setupTableView(){
        self.view.backgroundColor = UIColor.backgroundGrayColor()
//        tableView.backgroundColor = UIColor.white
        tableView.register(SearchResultsCell.self, forCellReuseIdentifier: EmojiCellId)
        tableView.register(UserAndListCell.self, forCellReuseIdentifier: UserCellId)
        tableView.register(LocationCell.self, forCellReuseIdentifier: LocationCellId)
        tableView.register(NewListCell.self, forCellReuseIdentifier: ListCellId)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            
        tableView.allowsMultipleSelection = true
        // Google Locations are only loaded when Locations are selected
        
        //        tableDataSource = GMSAutocompleteTableDataSource()
        //        tableDataSource?.delegate = self
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 160
        //        tableView.estimatedRowHeight = 200
        
        
        //        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(increaseScope))
        //        swipeLeft.direction = .left
        //        self.tableView.addGestureRecognizer(swipeLeft)
        //
        //        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(decreaseScope))
        //        swipeRight.direction = .right
        //        self.tableView.addGestureRecognizer(swipeRight)
        
        let tv = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 60))
        tv.backgroundColor = UIColor.lightBackgroundGrayColor()
        tv.addSubview(cancelButton)
        cancelButton.anchor(top: nil, left: nil, bottom: nil, right: tv.rightAnchor, paddingTop: 3, paddingLeft: 5, paddingBottom: 5, paddingRight: 15, width: 0, height: 40)
        cancelButton.sizeToFit()
        cancelButton.centerYAnchor.constraint(equalTo: tv.centerYAnchor).isActive = true
        
        setupSearchBar()
        tv.addSubview(searchBar)
        searchBar.anchor(top: tv.topAnchor, left: tv.leftAnchor, bottom: tv.bottomAnchor, right: cancelButton.leftAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 5, width: 0, height: 50)
        searchBar.centerYAnchor.constraint(equalTo: tv.centerYAnchor).isActive = true
        tableView.tableHeaderView = tv
        
        
    }
    

//    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let tv = UIView()
//        tv.backgroundColor = UIColor.white
//        tv.addSubview(cancelButton)
//        cancelButton.anchor(top: nil, left: nil, bottom: nil, right: tv.rightAnchor, paddingTop: 3, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 40, height: 40)
//        cancelButton.centerYAnchor.constraint(equalTo: tv.centerYAnchor).isActive = true
//
//        setupSearchBar()
//        tv.addSubview(searchBar)
//        searchBar.anchor(top: nil, left: tv.leftAnchor, bottom: nil, right: cancelButton.leftAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
//        searchBar.centerYAnchor.constraint(equalTo: tv.centerYAnchor).isActive = true
//
//        return tv
//    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        if section == 0 {
//            let tv = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 60))
//            tv.backgroundColor = UIColor.lightBackgroundGrayColor()
//            tv.addSubview(cancelButton)
//            cancelButton.anchor(top: nil, left: nil, bottom: nil, right: tv.rightAnchor, paddingTop: 3, paddingLeft: 5, paddingBottom: 5, paddingRight: 15, width: 0, height: 40)
//            cancelButton.sizeToFit()
//            cancelButton.centerYAnchor.constraint(equalTo: tv.centerYAnchor).isActive = true
//
//            setupSearchBar()
//            tv.addSubview(searchBar)
//            searchBar.anchor(top: tv.topAnchor, left: tv.leftAnchor, bottom: tv.bottomAnchor, right: cancelButton.leftAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 5, width: 0, height: 50)
//            searchBar.centerYAnchor.constraint(equalTo: tv.centerYAnchor).isActive = true
//            tableView.tableHeaderView = tv
//            return tv
//        } else {
//            let headerView = UIView()
//            headerView.backgroundColor = UIColor.clear
//            return headerView
//        }
        
        let headerView = UIView()
        headerView.backgroundColor = UIColor.backgroundGrayColor()
        return headerView

    }
    
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        let searchType = searchOptions[self.searchCategory]

        // All
        if searchType == SearchAll {
            return isFiltering ? filteredAllResults.count : defaultAllResults.count
        }
            
        // Emoji
        else if searchType == SearchEmojis {
            return isFiltering ? filteredEmojis.count : displayEmojis.count
        }
            
            // Users
        else if searchType == SearchUser {
            return isFiltering ? filteredUsers.count : allUsers.count
        }
            
            // Locations
        else if searchType == SearchPlace {
            return isFiltering ? filteredLocations.count : displayLocations.count
        }
            
        else {
            return 0
        }

    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        var cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        let searchType = searchOptions[self.searchCategory]
        
//        let cell = tableView.dequeueReusableCell(withIdentifier: EmojiCellId, for: indexPath) as! EmojiCell
//        return cell
        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: EmojiCellId, for: indexPath) as! SearchResultsCell
        
        

        if searchType == SearchAll {
            if (self.isFiltering && self.filteredAllResults.count == 0) {
                return cell
            }
            
            let displayTerm = self.isFiltering ? self.filteredAllResults[indexPath.section] : self.defaultAllResults[indexPath.section]
            let displayType = allResultsDic[displayTerm] ?? ""
            
            if displayType == SearchEmojis {
                
                let emoji = self.displayEmojis.filter { (emoji) -> Bool in
                    emoji.name == displayTerm
                }
                cell.emoji = emoji[0]
                cell.postCount = (defaultEmojiCounts[emoji[0].emoji] ?? 0) + (defaultEmojiCounts[emoji[0].name!] ?? 0)
                cell.isSelected = (self.searchText != nil) ? (self.searchText?.contains((cell.emoji?.emoji)!))! : false
            }
            
            else if displayType == SearchPlace {
                
                cell.locationName = displayTerm
                cell.postCount = defaultLocationCounts[displayTerm] ?? 0
                if let filter = searchFilter {
                    cell.isSelected = (displayTerm == filter.filterLocationSummaryID)
                }
            }
            
            else if displayType == SearchUser {
                
                let user = self.allUsers.filter { (user) -> Bool in
                    user.username == displayTerm
                }
                cell.user = user[0]
                cell.isSelected = false
            }
            
            return cell
            
        }
        
        else if searchType == SearchEmojis {
            let displayTerm = self.isFiltering ? self.filteredEmojis[indexPath.section] : self.displayEmojis[indexPath.section]
            cell.emoji = displayTerm
            cell.postCount = (defaultEmojiCounts[displayTerm.emoji] ?? 0) + (defaultEmojiCounts[displayTerm.name!] ?? 0)
            cell.isSelected = (self.searchText != nil) ? (self.searchText?.contains((cell.emoji?.emoji)!))! : false
            return cell
        }
            
        else if searchType == SearchPlace {
            let curLabel = isFiltering ? filteredLocations[indexPath.section] : displayLocations[indexPath.section]
            cell.locationName = curLabel
            cell.postCount = defaultLocationCounts[curLabel] ?? 0
            if let filter = searchFilter {
                cell.isSelected = (curLabel == filter.filterLocationSummaryID)
            }
            return cell
        }
        
        else if searchType == SearchUser {
            let displayUser = isFiltering ? filteredUsers[indexPath.section] : allUsers[indexPath.section]
            cell.user = displayUser
            cell.isSelected = false
            return cell
        }
        
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: EmojiCellId, for: indexPath) as! SearchResultsCell
            return cell
        }
        
        // Configure the cell...

    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.backgroundColor = UIColor.mainBlue().withAlphaComponent(0.2)

        let searchType = searchOptions[self.searchCategory]

        if searchType == SearchAll {
            let displayTerm = self.isFiltering ? self.filteredAllResults[indexPath.section] : self.defaultAllResults[indexPath.section]
            let displayType = allResultsDic[displayTerm] ?? ""
            
            if displayType == SearchEmojis {
                let emoji = self.displayEmojis.filter { (emoji) -> Bool in
                    emoji.name == displayTerm
                }
                self.addEmojiToSearchTerm(inputEmoji: emoji[0])
            }
            else if displayType == SearchPlace {
                self.selectedLocation = displayTerm
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
            let displayTerm = self.isFiltering ? self.filteredEmojis[indexPath.section] : self.displayEmojis[indexPath.section]
            let displayEmoji = displayTerm.emoji
            
            self.addEmojiToSearchTerm(inputEmoji: displayTerm)
            self.handleFilter()
            
//            self.searchText = displayTerm.emoji
            
        }
            
        else if searchType == SearchPlace {
            let curLabel = isFiltering ? filteredLocations[indexPath.section] : displayLocations[indexPath.section]
            self.selectedLocation = curLabel
            self.handleFilter()

        }
            
        else if searchType == SearchUser {
            let displayUser = isFiltering ? filteredUsers[indexPath.section] : allUsers[indexPath.section]
            self.searchUser = displayUser
            self.handleFilter()

//            let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
//            userProfileController.displayUserId = displayUser.uid
//            self.navigationController?.pushViewController(userProfileController, animated: true)
            
        }

        
        
        
    }
    
    func addEmojiToSearchTerm(inputEmoji: EmojiBasic?) {
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

        self.searchText = finalSearchCaption

        
    }
    
    
    func handleFilter(){

        self.searchFilter?.filterCaption = self.searchText
        self.searchFilter?.filterUser = self.searchUser
        self.searchFilter?.filterLocationSummaryID = selectedLocation
        
        self.searchBar.resignFirstResponder()
        self.delegate?.filterControllerSelected(filter: searchFilter)
        self.navigationController?.popViewController(animated: true)
    }
    
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
