//
//  PostSearchTableViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/23/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit

import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth

protocol PostSearchTableViewControllerDelegate {
    func hideSearchView()
    func showSearchView()
    func filterSelected(filter: Filter)
    
}


class PostSearchTableViewController: UITableViewController {

    var delegate: PostSearchTableViewControllerDelegate?
    
    var searchTypeSegment = UISegmentedControl()
    var viewFilter: Filter = Filter.init(defaultSort: defaultRecentSort)

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
    var displayEmojis:[Emoji] = []
    var filteredEmojis:[Emoji] = []
    
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
    
    let EmojiCellId = "EmojiCellId"
    let UserCellId = "UserCellId"
    let LocationCellId = "LocationCellId"
    let ListCellId = "ListCellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupTableView()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    func setupTableView(){
        tableView.register(SearchResultsCell.self, forCellReuseIdentifier: EmojiCellId)
        tableView.register(UserAndListCell.self, forCellReuseIdentifier: UserCellId)
        tableView.register(LocationCell.self, forCellReuseIdentifier: LocationCellId)
        tableView.register(NewListCell.self, forCellReuseIdentifier: ListCellId)
        
        tableView.backgroundColor = UIColor.white
        tableView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 160
        tableView.separatorStyle = .none
        
//        searchTableView.contentSize = CGSize(width: self.view.frame.size.width - 20, height: searchTableView.contentSize.height)
        setupSegments()
        tableView.tableHeaderView = searchTypeSegment
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
        self.tableView.reloadData()
//        self.searchTypeSegment.changeUnderlinePosition()
    }
 
    
    func initSearchSelections(){
        
        print("PostSearchTableViewController | Init Search Selections")
        // SET DEFAULT PARAMETERS
//        self.defaultEmojiCounts = self.noCaptionFilterEmojiCounts
//        self.defaultPlaceCounts = self.noCaptionFilterPlaceCounts
//        self.defaultCityCounts = self.noCaptionFilterCityCounts
//
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
        self.tableView.reloadData()
        
        
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
            filteredPlaces = displayPlaces
            filteredCity = displayCity
            self.searchFiltering = false

        } else {
            self.searchFiltering = true

            if SearchBarOptions[self.selectedSearchType] == SearchAll {
                
                filteredAllResults = aggregateAllResults.filter { (option) -> Bool in
                    return option.lowercased().contains(searchCaption) || searchCaptionArray.contains(option.lowercased()) || searchCaptionEmojis.contains(option)
                }
                
                if searchCaption.removingWhitespaces() == "" {
                    filteredAllResults += (self.defaultAllResults)
                }
                
                
                filteredAllResults.sort { (p1, p2) -> Bool in
                    
                    let p1Type = allResultsDic[p1] ?? ""
                    let p2Type = allResultsDic[p2] ?? ""
                    
                // SORT BY EMOJI, PLACE, CITY
                    if allResultsDic[p1] != allResultsDic[p2] {
                        let p1TypeInd = SearchBarTypeIndex[p1Type] ?? 999
                        let p2TypeInd = SearchBarTypeIndex[p2Type] ?? 999

                        return p1TypeInd < p2TypeInd
                    }
                    
                // SORT BY POST COUNT
                    else
                    {
                        
                        var p1Count = 0
                        var p2Count = 0
                        
                        if p1Type == SearchEmojis {
                            p1Count = defaultEmojiCounts[p1] ?? 0
                        } else if p1Type == SearchPlace {
                            p1Count = defaultPlaceCounts[p1] ?? 0
                        }  else if p1Type == SearchCity {
                            p1Count = defaultCityCounts[p1] ?? 0
                        } else {
                            p1Count = 0
                        }
                        
                        if p2Type == SearchEmojis {
                            p2Count = defaultEmojiCounts[p2] ?? 0
                        } else if p2Type == SearchPlace {
                            p2Count = defaultPlaceCounts[p2] ?? 0
                        }  else if p2Type == SearchCity {
                            p2Count = defaultCityCounts[p2] ?? 0
                        } else {
                            p2Count = 0
                        }
                        
                        return p1Count > p2Count
                    }
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
                
            else if SearchBarOptions[self.selectedSearchType] == SearchEmojis {
                // Filter Food
                if searchCaption.removingWhitespaces() == "" {
                    filteredEmojis = displayEmojis
                    self.tableView.reloadData()
                    return
                } else {
                    filteredEmojis = displayEmojis.filter({( emoji : Emoji) -> Bool in
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
                var tempResults: [Emoji] = []
                
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
                
            else if SearchBarOptions[self.selectedSearchType] == SearchUser {
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
                
            else if SearchBarOptions[self.selectedSearchType] == SearchPlace {
                if searchCaption.removingWhitespaces() == "" {
                    filteredPlaces = displayPlaces
                    self.tableView.reloadData()
                    return
                } else {
                    filteredPlaces = displayPlaces.filter({ (string) -> Bool in
                        return string.lowercased().contains(searchCaption.lowercased())
                    })
                }
                
                
                
                filteredPlaces.sort { (p1, p2) -> Bool in
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
                
                for x in filteredPlaces {
                    if !tempResults.contains(x) {
                        tempResults.append(x)
                    }
                }
                filteredPlaces = tempResults
                print("FilterContentResults | \(searchText) | \(filteredPlaces.count) Filtered Locations | \(displayPlaces.count) Locations")
            }
        }
        self.tableView.reloadData()
        
    }
    
        func handleFilter(){
            
            self.viewFilter.clearFilter()
            self.viewFilter.filterCaption = self.searchText
            self.viewFilter.filterUser = self.searchUser
            
            if let loc = selectedPlace {
                if let _ = self.defaultPlaceCounts[loc] {
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
            self.delegate?.hideSearchView()
            self.delegate?.filterSelected(filter: self.viewFilter)
//            self.hideSearchView()
//            self.hideSearchBar = true
//            self.refreshPostsForSearch()
        }
    
    func addEmojiToSearchTerm(inputEmoji: Emoji?) {
        self.searchText = inputEmoji?.emoji
    }
    
    
    // MARK: - Table view data source

//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 1
//    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return 0
        // #warning Incomplete implementation, return the number of rows
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

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
    
    
    
    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

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
