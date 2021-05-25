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


class DisplayOnlyUsersSearchView : UITableViewController, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate{


    
    let UserCellId = "UserCellId"
    let ListCellId = "ListCellId"
    
    
    var inputPost: Post? {
        didSet {
            self.fetchAllLikeUsersForPost()
            setupNavigationItems()
            setScopeBarOptions()
        }
    }
    
    var inputUser: User? {
        didSet {
            fetchUserInfo()
            updateSearchView()
        }
    }
    
    var specificUids:[String] = [] {
        didSet {
            fetchSpecificUsers()
        }
    }
    
//    var inputList: List? = nil
    
    var displayListOfUsers: Bool = true {
        didSet {
            if displayListOfUsers {
                displayListsByUser = false
            }
        }
    }
    
    var followingUids: [String] = []
    var followerUids: [String] = []

    var displayListsByUser: Bool = false  {
       didSet {
           if displayListsByUser {
               displayListOfUsers = false
           }
       }
   }
    
    var displayUsersFollowingList: Bool = false
    
    
    var delegate: UserListSearchViewDelegate?

    var scopeBarOptions:[String] = FriendSortOptions {
        didSet {
//            setScopeBarOptions()
        }
    }
    
    func fetchUserInfo() {
        guard let uid = inputUser?.uid else {return}
        if uid == CurrentUser.uid {
            self.followingUids = CurrentUser.followingUids
            self.followerUids = CurrentUser.followerUids
            self.followingListIds = CurrentUser.followedListIds
            self.createdListsIds = CurrentUser.listIds
        } else {
            Database.fetchFollowingUserUids(uid: uid) { (following) in
                self.followingUids = following
            }
            
            Database.fetchFollowerUserUids(uid: uid) { (follower) in
                self.followerUids = follower
            }
            
            Database.fetchFollowedListIDs(userUid: uid) { (listIds) in
                self.followingListIds = listIds.compactMap({$0.listId})
            }
            
            self.createdListsIds = inputUser?.listIds ?? []
        }
    }
    
    
    func updateSearchView() {
        setupNavigationItems()
        setScopeBarOptions()
//        self.fetchAllListsForUser()
        if displayListOfUsers {
            self.fetchAllUsers()
        } else if displayListsByUser {
            self.fetchListsByUser()
        }
    }
    
    
    func setScopeBarOptions() {
        if displayListOfUsers
        {
            self.scopeBarOptions = FriendSortOptions
            let followingText = "🙋‍♂️ " + FriendSortOptions[0] +  " \(self.followingUsers.count)"
            let otherUserText = "👥 " + FriendSortOptions[1] +  " \(self.otherUsers.count)"
            self.searchBar.scopeButtonTitles = [followingText, otherUserText]
        }
        else if displayListsByUser
        {
            self.scopeBarOptions = ListSearchOptions
            let createdText = "📕 " + ListSearchOptions[0] +  " \(self.createdLists.count)"
            let followingText = "👥 " + ListSearchOptions[1] +  " \(self.followingLists.count)"
            self.searchBar.scopeButtonTitles = [createdText, followingText]
        }

    }
    

    var searchTerm: String? = nil
    var isFiltering: Bool = false {
        didSet{
            // Reloads tableview when stops filtering
            self.tableView.reloadData()
        }
    }
    
    var selectedScope = 0 {
        didSet{
            self.searchBar.selectedScopeButtonIndex = self.selectedScope
            self.tableView.reloadData()
        }
    }
    
    var selectedUser: User?
    var selectedList: List?
    
    // MARK: - USER AND LIST OBJECTS

    
    var otherUsers = [User]()
    var followingUsers = [User]()
    var filteredUsers = [User]()
    var allUsers = [User]()

    var createdListsIds : [String] = []
    var followingListIds: [String] = []
    var createdLists = [List]()
    var followingLists = [List]()
    var filteredList = [List]()
    var allLists = [List]()
    
    let searchController = UISearchController(searchResultsController: nil)
    var searchBar = UISearchBar()
    
    func fetchListsByUser() {
        guard let inputUser = inputUser else {return}
        let uid = inputUser.uid
        
        self.createdLists.removeAll()
        self.followingLists.removeAll()
        self.filteredList.removeAll()
        self.allLists.removeAll()
        
        Database.fetchAllListsForUser(userUid: uid) { (lists) in
            self.allLists = lists
            
            self.allLists = self.allLists.sorted(by: { (p1, p2) -> Bool in
                if p1.postIds?.count != p2.postIds?.count {
                    return (p1.postIds?.count ?? 0) > (p2.postIds?.count ?? 0)
                } else {
                    return p1.latestNotificationTime > p2.latestNotificationTime
                }
            })
            
            for list in self.allLists {
                guard let listId = list.id else {continue}
                if self.createdListsIds.contains(listId)  {
                    self.createdLists.append(list)
                }
                
                else if self.followingListIds.contains(listId)  {
                    self.followingLists.append(list)
                }
            }
            
            print("\(self.createdLists.count) Created Lists | \(self.followingListIds.count) Followed List | \(self.allLists.count) Total Lists")

            self.setScopeBarOptions()
            self.tableView.reloadData()

        }
        
    }
    
    func fetchSpecificUsers() {
        self.otherUsers.removeAll()
        self.followingUsers.removeAll()
        let myGroup = DispatchGroup()

        for vote in (self.specificUids) {
            myGroup.enter()
            Database.fetchUserWithUID(uid: vote) { (user) in
                self.followingUsers.append(user!)
                self.otherUsers.append(user!)
                myGroup.leave()
            }
        }
        myGroup.notify(queue: .main) {
            print("Following \(self.followingUsers.count) | Fetched \(self.otherUsers.count) Users ")
            self.searchBar.scopeButtonTitles = ["Following (\(self.followingUsers.count))", "Other (\(self.otherUsers.count))"]
            self.searchBar.showsScopeBar = false
//            self.otherUsers = self.otherUsers.sorted(by: { (u1, u2) -> Bool in
//                u1.followersCount > u2.followersCount
//            })
//
//            self.followingUsers = self.followingUsers.sorted(by: { (u1, u2) -> Bool in
//                u1.followersCount > u2.followersCount
//            })
            
//            self.otherUsers = self.otherUsers.sorted(by: { (u1, u2) -> Bool in
//                u1.posts_created > u2.posts_created
//            })
//
//            self.followingUsers = self.followingUsers.sorted(by: { (u1, u2) -> Bool in
//                u1.posts_created > u2.posts_created
//            })
            
            self.setScopeBarOptions()
            self.tableView.reloadData()

        }
    }
    
    
    func fetchAllLikeUsersForPost(){
        self.otherUsers.removeAll()
        self.followingUsers.removeAll()
        let myGroup = DispatchGroup()

        for vote in (self.inputPost?.allVote)! {
            myGroup.enter()
            Database.fetchUserWithUID(uid: vote) { (user) in
                if (user?.isFollowing)!{
                    self.followingUsers.append(user!)
                } else {
                    self.otherUsers.append(user!)
                }
                myGroup.leave()
            }
        }
        myGroup.notify(queue: .main) {
            print("Following \(self.followingUsers.count) | Fetched \(self.otherUsers.count) Users ")
            self.searchBar.scopeButtonTitles = ["Following (\(self.followingUsers.count))", "Other (\(self.otherUsers.count))"]
//            self.otherUsers = self.otherUsers.sorted(by: { (u1, u2) -> Bool in
//                u1.followersCount > u2.followersCount
//            })
//
//            self.followingUsers = self.followingUsers.sorted(by: { (u1, u2) -> Bool in
//                u1.followersCount > u2.followersCount
//            })
            
            self.otherUsers = self.otherUsers.sorted(by: { (u1, u2) -> Bool in
                u1.posts_created > u2.posts_created
            })
            
            self.followingUsers = self.followingUsers.sorted(by: { (u1, u2) -> Bool in
                u1.posts_created > u2.posts_created
            })
            
            self.setScopeBarOptions()
            self.tableView.reloadData()

        }
    }
    
    
    func fetchAllUsers(){
        guard let inputUser = inputUser else {return}
        let uid = inputUser.uid
        
        self.otherUsers.removeAll()
        self.followingUsers.removeAll()
        self.allUsers.removeAll()
        self.filteredUsers.removeAll()

        Database.fetchALLUsers(includeSelf: true) { (fetchedUsers) in
            
            self.allUsers = fetchedUsers
//            self.allUsers = self.allUsers.sorted(by: { (u1, u2) -> Bool in
//                u1.posts_created > u2.posts_created
//            })
                
            self.allUsers = self.allUsers.sorted(by: { (p1, p2) -> Bool in
                if p1.posts_created != p2.posts_created {
                    return p1.lists_created > p2.lists_created
                } else if p1.lists_created != p2.lists_created {
                    return p1.lists_created > p2.lists_created
                } else {
                    return (p1.profileImageUrl == "" ? 0 : 1) >= (p2.profileImageUrl == "" ? 0 : 1)
                }
            })
                

        // MOVE SELF TO FIRST
            if let index = self.allUsers.firstIndex(where: { (user) -> Bool in
                return user.uid == inputUser.uid
            }) {
                let temp = self.allUsers.remove(at: index)
                self.allUsers.insert(temp, at: 0)
            }
            
        // MOVE SELECTED USER TO FIRST
            if let selectedUser = self.selectedUser {
                if let index = self.allUsers.firstIndex(where: { (user) -> Bool in
                    return user.uid == selectedUser.uid
                }) {
                    let temp = self.allUsers.remove(at: index)
                    self.followingUsers.insert(temp, at: 0)
                }
            }
            
            for user in self.allUsers {
                if self.followingUids.contains(user.uid)  {
                    self.followingUsers.append(user)
                }
                
                if self.followerUids.contains(user.uid)  {
                    self.otherUsers.append(user)
                }
            }
            
            print("\(self.followingUids.count) Following UID | \(self.followerUids.count) Follower UID")

            
            
            // SORT
            self.followingUsers.sort { (p1, p2) -> Bool in
//                if p1.posts_created == p2.posts_created {
//                    return p1.lists_created > p2.lists_created
//                } else {
//                    return p1.posts_created > p2.posts_created
//                }
                if p1.posts_created != p2.posts_created {
                    return p1.lists_created > p2.lists_created
                } else if p1.lists_created != p2.lists_created {
                    return p1.lists_created > p2.lists_created
                } else {
                    return (p1.profileImageUrl == "" ? 0 : 1) >= (p2.profileImageUrl == "" ? 0 : 1)
                }
            }
            
            self.otherUsers.sort { (p1, p2) -> Bool in
                if p1.posts_created != p2.posts_created {
                    return p1.lists_created > p2.lists_created
                } else if p1.lists_created != p2.lists_created {
                    return p1.lists_created > p2.lists_created
                } else {
                    return (p1.profileImageUrl == "" ? 0 : 1) >= (p2.profileImageUrl == "" ? 0 : 1)
                }
            }

            
            
            print("   Fetched \(self.allUsers.count) Users")
            self.setScopeBarOptions()
            self.tableView.reloadData()
        }
    }

//    func fetchUsersFollowingList(){
//        guard let inputList = inputList else {return}
//        let listId = inputList.id
//
////        Database.fetchli
//
//    }

    
    
    
    
    lazy var navBackButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 16)
//        button.setImage(#imageLiteral(resourceName: "dropdownXLarge").withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.tintColor = UIColor.lightGray
        return button
    }()
    
    // MARK: - VIEW DID LOAD

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        setupTableView()
        setupNavigationItems()
        setupSearchController()

        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(increaseScope))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleBackPressNav))
        swipeRight.direction = .right
        self.tableView.addGestureRecognizer(swipeRight)
        
    }
    
        
    override func viewWillDisappear(_ animated: Bool) {
        //      Remove Searchbar scope during transition
//        self.searchBar.isHidden = true
        //        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.setupNavigationItems()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //      Show Searchbar scope during transition
        self.setupNavigationItems()
        self.searchBar.isHidden = false
        self.searchBar.selectedScopeButtonIndex = self.selectedScope
        self.tableView.reloadData()
        
        DispatchQueue.main.async {
            if let textField = self.searchBar.value(forKey: "searchField") as? UITextField {
                textField.backgroundColor = UIColor.white
                //textField.font = myFont
                //textField.textColor = myTextColor
                //textField.tintColor = myTintColor
                // And so on...

                let backgroundView = textField.subviews.first
                if #available(iOS 11.0, *) { // If `searchController` is in `navigationItem`
                    backgroundView?.backgroundColor = UIColor.white //Or any transparent color that matches with the `navigationBar color`
                    backgroundView?.subviews.forEach({ $0.removeFromSuperview() }) // Fixes an UI bug when searchBar appears or hides when scrolling
                }
                backgroundView?.layer.cornerRadius = 10.5
                backgroundView?.layer.masksToBounds = true
                //Continue changing more properties...
            }
//            self.searchController.searchBar.becomeFirstResponder()
        }
        //        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
        
        
    }
    
    /*
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            if let textField = self.searchBar.value(forKey: "searchField") as? UITextField {
                textField.backgroundColor = UIColor.white
                //textField.font = myFont
                //textField.textColor = myTextColor
                //textField.tintColor = myTintColor
                // And so on...

                let backgroundView = textField.subviews.first
                if #available(iOS 11.0, *) { // If `searchController` is in `navigationItem`
                    backgroundView?.backgroundColor = UIColor.white //Or any transparent color that matches with the `navigationBar color`
                    backgroundView?.subviews.forEach({ $0.removeFromSuperview() }) // Fixes an UI bug when searchBar appears or hides when scrolling
                }
                backgroundView?.layer.cornerRadius = 10.5
                backgroundView?.layer.masksToBounds = true
                //Continue changing more properties...
            }
//            self.searchController.searchBar.becomeFirstResponder()
        }
    }
        
    */
    
    @objc func handleBackPressNav(){
        self.handleDismiss()
    }
    

    func setupNavigationItems(){
        
    // Header

        
//        self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.ianLegitColor(), NSAttributedString.Key.font.rawValue: UIFont(name: "Poppins-Bold", size: 18)])
        var titleString = displayListOfUsers ? "Users" : (displayListsByUser ? "Lists" : "" )

        let navLabel = UILabel()
        let customFont = UIFont(name: "Poppins-Bold", size: 18)
        let headerTitle = NSAttributedString(string:titleString, attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianWhiteColor(), NSAttributedString.Key.font: customFont])
        navLabel.attributedText = headerTitle
        self.navigationItem.titleView = navLabel
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.isTranslucent = false
        
        let navColor = UIColor.ianLegitColor()
        
        self.navigationController?.navigationBar.barTintColor = navColor
        let tempImage = UIImage.init(color: UIColor.ianLegitColor())
        navigationController?.navigationBar.setBackgroundImage(tempImage, for: .default)
        self.navigationController?.navigationBar.tintColor = UIColor.ianLegitColor()
        self.navigationController?.view.backgroundColor = UIColor.ianLegitColor()
        self.navigationController?.navigationBar.backgroundColor = navColor
        self.navigationController?.navigationBar.layer.shadowColor = navColor.cgColor
        self.navigationController?.navigationBar.layoutIfNeeded()


    // Nav Back Buttons
        
        navBackButton.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        navBackButton.setTitle("Back", for: .normal)
        let barButton2 = UIBarButtonItem.init(customView: navBackButton)
        self.navigationItem.leftBarButtonItem = barButton2
    }
    
    
    @objc func increaseScope(){
        self.changeScope(change: 1)
    }
    
    func decreaseScope(){
        self.changeScope(change: -1)
    }
    
    func changeScope(change: Int){
        self.selectedScope = min(max(0, self.selectedScope + change),(searchBar.scopeButtonTitles?.count)! - 1)
        self.searchBar.selectedScopeButtonIndex = self.selectedScope
    }
    
    var followingCount: Int = 0
    var otherCount: Int = 0

    
    
    // MARK: - SEARCH BAR

    
    func setupSearchController(){
        //        navigationController?.navigationBar.barTintColor = UIColor.white
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchBar = searchController.searchBar

        searchBar.backgroundImage = UIImage()
        searchBar.scopeButtonTitles = scopeBarOptions
        searchBar.showsScopeBar = true
        searchBar.sizeToFit()
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder =  searchBarPlaceholderText
        searchBar.barTintColor = UIColor.ianLegitColor()
        searchBar.tintColor = UIColor.ianLegitColor()
        
        searchBar.barTintColor = UIColor.backgroundGrayColor()
        searchBar.tintColor = UIColor.backgroundGrayColor()
        searchBar.backgroundColor = UIColor.backgroundGrayColor()

        definesPresentationContext = true
        searchBar.backgroundColor = UIColor.ianLegitColor()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
//        searchBar.scopeBarBackgroundImage = UIImage.imageWithColor(color: UIColor.blue)

        for subview in searchBar.subviews {
            if subview is UISegmentedControl {
                subview.tintColor = UIColor.mainBlue()
            }
        }
        
        searchBar.setScopeBarButtonTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)
        searchBar.setScopeBarButtonTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianWhiteColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
        
        if let textField = self.searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = UIColor.white
            //textField.font = myFont
            //textField.textColor = myTextColor
            //textField.tintColor = myTintColor
            // And so on...

            let backgroundView = textField.subviews.first
            if #available(iOS 11.0, *) { // If `searchController` is in `navigationItem`
                backgroundView?.backgroundColor = UIColor.white //Or any transparent color that matches with the `navigationBar color`
                backgroundView?.subviews.forEach({ $0.removeFromSuperview() }) // Fixes an UI bug when searchBar appears or hides when scrolling
            }
            backgroundView?.layer.cornerRadius = 10.5
            backgroundView?.layer.masksToBounds = true
            //Continue changing more properties...
        }
        
        
        
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling  = false
            
        } else {
            self.tableView.tableHeaderView = searchBar
        }
        
    }
    
    
    func filterContentForSearchText(_ searchText: String) {
        // Filter for Emojis and Users
        filteredUsers = (self.selectedScope == 0 ? self.followingUsers : self.followingUsers).filter { (user) -> Bool in
            return user.username.lowercased().contains(searchText.lowercased())
        }
        
        filteredList = (self.selectedScope == 0 ? self.createdLists : self.followingLists).filter { (list) -> Bool in
            return list.name.lowercased().contains(searchText.lowercased())
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
            if self.selectedScope == 0 || self.selectedScope == 1 {
                filterContentForSearchText(searchBar.text!)
            }
        }
    }
    
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        self.searchBar.sizeToFit()
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        self.searchBar.sizeToFit()
        return true
    }

    

    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchBar.text?.isEmpty)! {
            self.searchTerm = nil
            self.isFiltering = false
        } else {
            self.isFiltering = true
            self.searchTerm = searchText
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        if !(searchBar.text?.isEmptyOrWhitespace())! {
//            self.filterCaptionSelected(searchedText: searchBar.text)
//        } else {
//            self.filterCaptionSelected(searchedText: nil)
//        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//        if !(searchBar.text?.isEmptyOrWhitespace())! {
//            self.filterCaptionSelected(searchedText: searchBar.text)
//        } else {
//            self.filterCaptionSelected(searchedText: nil)
//        }
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        print("Selected Scope is: ", selectedScope)
        self.selectedScope = selectedScope
        self.tableView.reloadData()
    }

    
}


extension DisplayOnlyUsersSearchView {
    
    func setupTableView(){
        tableView.backgroundColor = UIColor.white
        tableView.register(UserAndListCell.self, forCellReuseIdentifier: UserCellId)
        //        tableView.register(TestListCell.self, forCellReuseIdentifier: ListCellId)
        tableView.register(NewListCell.self, forCellReuseIdentifier: ListCellId)
        tableView.estimatedRowHeight = 200
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.alwaysBounceVertical = true
        let adjustForTabbarInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
        tableView.contentInset = adjustForTabbarInsets
        tableView.scrollIndicatorInsets = adjustForTabbarInsets

    }
    

    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if displayListOfUsers
        {
            return isFiltering ? filteredUsers.count : (self.selectedScope == 0 ? followingUsers.count : otherUsers.count)
        }
        else if displayListsByUser
        {
            return isFiltering ? filteredList.count : (self.selectedScope == 0 ? createdLists.count : followingLists.count)
        } else {
            return 0
        }

    }
    
//    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 70 + 90 + 10
//    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        

        let cell = tableView.dequeueReusableCell(withIdentifier: UserCellId, for: indexPath) as! UserAndListCell
        if displayListOfUsers {
            var user = self.isFiltering ? filteredUsers[indexPath.row] : (self.selectedScope == 0 ? followingUsers[indexPath.row] : otherUsers[indexPath.row])
            cell.user = user
        } else if displayListsByUser {
            var list = self.isFiltering ? filteredList[indexPath.row] : (self.selectedScope == 0 ? createdLists[indexPath.row] : followingLists[indexPath.row])
            cell.list = list
        }
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                
        if displayListOfUsers {
            var user = self.isFiltering ? filteredUsers[indexPath.row] : (self.selectedScope == 0 ? followingUsers[indexPath.row] : otherUsers[indexPath.row])
            self.userSelected(user: user)
        } else if displayListsByUser {
            var list = self.isFiltering ? filteredList[indexPath.row] : (self.selectedScope == 0 ? createdLists[indexPath.row] : followingLists[indexPath.row])
            self.listSelected(list: list)
        }

        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func userSelected(user: User?) {
        guard let user = user else {return}
        self.extTapUser(userId: user.uid)
//        self.delegate?.userSelected(user: user)
        self.dismiss(animated: true) {
            print("UserListSearchView | User Selected | User: \(user.username)")
        }
    }

    func listSelected(list: List?) {
        guard let list = list else {return}
        self.extTapList(list: list)
        self.delegate?.listSelected(list: list)
        self.dismiss(animated: true) {
            print("UserListSearchView | List Selected | User: \(list.name)")
        }
    }
    
    @objc func handleDismiss() {
        print("UserListSearchView | Dismiss")
        self.navigationController?.popViewController(animated: true)
    }
    
}
