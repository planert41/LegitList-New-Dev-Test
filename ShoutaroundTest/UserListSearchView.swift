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

protocol UserListSearchViewDelegate {
    func userSelected(user: User?)
    func listSelected(list: List?)
}


class UserListSearchView : UITableViewController, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate{


    
    let UserCellId = "UserCellId"
    let ListCellId = "ListCellId"
    
    
    var inputUser: User?
    var delegate: UserListSearchViewDelegate?

    var scopeBarOptions:[String] = FriendSortOptions {
        didSet {
            setScopeBarOptions()
        }
    }
    
    var searchUser: Bool = true {
        didSet {
            if searchUser {
                self.searchList = false
                updateSearchView()}
        }
    }
    var searchList: Bool = false {
        didSet {
            if searchList {
                self.searchUser = false
                updateSearchView()}
        }
    }
        
    func updateSearchView() {
        print("UserListSearchView | updateSearchView | searchUser: \(searchUser) | searchList: \(searchList)")
        setupNavigationItems()
        setScopeBarOptions()
        if searchList {
            self.fetchAllListsForUser()
        } else if searchUser {
            self.fetchAllUsers()
        }
    }
    
    
    func setScopeBarOptions() {
        if searchUser {
            let followingText = scopeBarOptions[0] + " \(self.followingUsers.count)"
            let otherText = scopeBarOptions[0] + " \(self.otherUsers.count)"
            self.searchBar.scopeButtonTitles = [followingText, otherText]
        } else if searchList {
            let createdText = scopeBarOptions[0] + " \(self.createdLists.count)"
            let followText = scopeBarOptions[0] + " \(self.followingLists.count)"
            self.searchBar.scopeButtonTitles = [createdText, followText]
        }
    }
    

    var searchTerm: String? = nil
    var isFiltering: Bool = false {
        didSet{
            // Reloads tableview when stops filtering
            self.tableView.reloadData()
        }
    }
    
// LIST - All List / Friend Lists
    var displayFollowing: Bool = false {
        didSet{
            self.selectedScope = self.displayFollowing ? 0 : 1
        }
    }
    
// USER - Following / Followers
    var displayUserFollowing: Bool = false {
        didSet{
            self.selectedScope = self.displayUserFollowing ? 0 : 1
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
    
    var createdLists = [List]()
    var followingLists = [List]()
    var filteredList = [List]()

    
    
    let searchController = UISearchController(searchResultsController: nil)
    var searchBar = UISearchBar()
    
    func fetchAllUsers(){
        guard let inputUser = inputUser else {return}
        let uid = inputUser.uid
        
        self.otherUsers.removeAll()
        self.followingUsers.removeAll()
        
        Database.fetchALLUsers(includeSelf: true) { (fetchedUsers) in
            
            for user in fetchedUsers {
                if CurrentUser.followingUids.contains(user.uid) || (uid == user.uid) {
                    self.followingUsers.append(user)
                } else {
                    self.otherUsers.append(user)
                }
            }
            
            self.otherUsers = self.otherUsers.sorted(by: { (u1, u2) -> Bool in
                u1.posts_created > u2.posts_created
            })
            
            self.followingUsers = self.followingUsers.sorted(by: { (u1, u2) -> Bool in
                u1.posts_created > u2.posts_created
            })
            
        // MOVE SELF TO FIRST
            if let index = self.followingUsers.firstIndex(where: { (user) -> Bool in
                return user.uid == inputUser.uid
            }) {
                let temp = self.followingUsers.remove(at: index)
                self.followingUsers.insert(temp, at: 0)
            }
            
        // MOVE SELECTED USER TO FIRST
            if let selectedUser = self.selectedUser {
                if let index = self.followingUsers.firstIndex(where: { (user) -> Bool in
                    return user.uid == selectedUser.uid
                }) {
                    let temp = self.followingUsers.remove(at: index)
                    self.followingUsers.insert(temp, at: 0)
                }
                
                if let index = self.otherUsers.firstIndex(where: { (user) -> Bool in
                    return user.uid == selectedUser.uid
                }) {
                    let temp = self.otherUsers.remove(at: index)
                    self.otherUsers.insert(temp, at: 0)
                }
            }
            
          
            print("   Fetched \(self.otherUsers.count + self.followingUsers.count) Users: \(self.followingUsers.count) Followed | \(self.otherUsers.count) Other")

            self.setScopeBarOptions()
            self.tableView.reloadData()
        }
    }


    
    func fetchAllListsForUser(){
        guard let inputUser = inputUser else {return}
        let uid = inputUser.uid

        self.createdLists.removeAll()
        self.followingLists.removeAll()
        
        Database.fetchAllListsForUser(userUid: uid) { (fetchedLists) in
            for list in fetchedLists {
                if list.creatorUID == uid {
                    self.createdLists.append(list)
                } else {
                    self.followingLists.append(list)
                }
            }
            
            self.createdLists.sort(by: { (l1, l2) -> Bool in
                (l1.postIds?.count ?? 0) > (l2.postIds?.count ?? 0)
            })
            self.followingLists.sort(by: { (l1, l2) -> Bool in
                (l1.postIds?.count ?? 0) > (l2.postIds?.count ?? 0)
            })
            
        // MOVE SELECTED USER TO FIRST
            if let selectedList = self.selectedList {
                if let index = self.createdLists.firstIndex(where: { (list) -> Bool in
                    return list.id == selectedList.id
                }) {
                    let temp = self.createdLists.remove(at: index)
                    self.createdLists.insert(temp, at: 0)
                }
            
                if let index = self.followingLists.firstIndex(where: { (list) -> Bool in
                    return list.id == selectedList.id
                }) {
                    let temp = self.followingLists.remove(at: index)
                    self.followingLists.insert(temp, at: 0)
                }
            
            }
            
            print("   Fetched \(self.createdLists.count + self.followingLists.count) Lists: \(self.createdLists.count) Created | \(self.followingLists.count) Following | \(inputUser.listIds.count) List IDs | \(inputUser.username)")
            
            self.setScopeBarOptions()
            self.tableView.reloadData()
        }
        
    }
    
    
    lazy var navBackButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
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

        setupSearchController()
        setupNavigationItems()

        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(increaseScope))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleBackPressNav))
        swipeRight.direction = .right
        self.tableView.addGestureRecognizer(swipeRight)
        
    }
    
        
    override func viewWillDisappear(_ animated: Bool) {
        //      Remove Searchbar scope during transition
        self.searchBar.isHidden = true
        //        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //      Show Searchbar scope during transition
        self.setupNavigationItems()
        self.searchBar.isHidden = false
        self.searchBar.selectedScopeButtonIndex = self.selectedScope
        self.tableView.reloadData()
        //        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
//            self.searchController.searchBar.becomeFirstResponder()
        }
    }
        
    
    
    @objc func handleBackPressNav(){
        self.handleDismiss()
    }
    

    func setupNavigationItems(){
        
    // Header

        
//        self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.ianLegitColor(), NSAttributedString.Key.font.rawValue: UIFont(name: "Poppins-Bold", size: 18)])
        var titleString = self.searchList ? "Lists" : (self.searchUser ? "Users" : "" )
        
        let navLabel = UILabel()
        let customFont = UIFont(name: "Poppins-Bold", size: 18)
        let headerTitle = NSAttributedString(string:titleString, attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianWhiteColor(), NSAttributedString.Key.font: customFont])
        navLabel.attributedText = headerTitle
        self.navigationItem.titleView = navLabel
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = UIColor.ianLegitColor()
        self.navigationController?.navigationBar.tintColor = UIColor.ianLegitColor()
        self.navigationController?.view.backgroundColor = UIColor.ianLegitColor()
        self.navigationController?.navigationBar.backgroundColor = UIColor.ianLegitColor()
        self.navigationController?.navigationBar.layoutIfNeeded()


    // Nav Back Buttons
        
        navBackButton.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        let barButton2 = UIBarButtonItem.init(customView: navBackButton)
        self.navigationItem.rightBarButtonItem = barButton2
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
        searchBar.scopeButtonTitles = scopeBarOptions
        searchBar.showsScopeBar = true
        searchBar.sizeToFit()
        searchBar.delegate = self
        searchBar.searchBarStyle = .prominent
        searchBar.placeholder =  searchBarPlaceholderText
        searchBar.barTintColor = UIColor.white
        searchBar.tintColor = UIColor.mainBlue()
        definesPresentationContext = true
        searchBar.backgroundColor = UIColor.mainBlue()


        for s in searchBar.subviews[0].subviews {
            
            if s is UITextField {
                s.layer.borderWidth = 0.5
                s.layer.borderColor = UIColor.gray.cgColor
                s.layer.cornerRadius = 10
                s.clipsToBounds = true
                s.layer.backgroundColor = UIColor.white.cgColor
                s.backgroundColor = UIColor.white
            }
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

            // Users
        if self.searchUser{
            if self.selectedScope == 0 {
                filteredUsers = self.followingUsers.filter { (user) -> Bool in
                    return user.username.lowercased().contains(searchText.lowercased())
                }
            } else {
                filteredUsers = self.otherUsers.filter { (user) -> Bool in
                    return user.username.lowercased().contains(searchText.lowercased())
                }
            }
        }
        
        else if self.searchList {
            if self.selectedScope == 0 {
                filteredList = self.followingLists.filter { (list) -> Bool in
                    return list.name.lowercased().contains(searchText.lowercased())
                }
            } else {
                filteredList = self.createdLists.filter { (list) -> Bool in
                    return list.name.lowercased().contains(searchText.lowercased())
                }
            }
        }
        
        else {
            filteredUsers = []
            filteredList = []
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


extension UserListSearchView {
    
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

            // Users
        if self.searchUser{
            if isFiltering {
                return filteredUsers.count
            } else {
                if self.selectedScope == 0 {
                    print("Follow User| ",followingUsers.count)
                    return followingUsers.count
                } else{
                    print("Other User| ",otherUsers.count)
                    return otherUsers.count
                }
            }
        }
        else if self.searchList {
            if isFiltering {
                return filteredList.count
            } else {
                if self.selectedScope == 0 {
                    print("Created List| ",createdLists.count)
                    return createdLists.count
                } else{
                    print("Follow List | ",followingLists.count)
                    return followingLists.count
                }
            }
        }
            
        else {
            return 0
        }
    }
    
//    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 70 + 90 + 10
//    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Users
        if self.searchUser{
            let cell = tableView.dequeueReusableCell(withIdentifier: UserCellId, for: indexPath) as! UserAndListCell
            let filterUser = self.isFiltering ? filteredUsers[indexPath.row] : (self.selectedScope == 0 ? followingUsers[indexPath.row] : otherUsers[indexPath.row])
            cell.user = filterUser
            cell.isSelected = (selectedUser?.uid == filterUser.uid)
            return cell
        }
        
        // Lists
        else if self.searchList{
            let cell = tableView.dequeueReusableCell(withIdentifier: ListCellId, for: indexPath) as! NewListCell
            let filterList = self.isFiltering ? filteredList[indexPath.row] : (self.selectedScope == 0 ? createdLists[indexPath.row] : followingLists[indexPath.row])
            cell.list = filterList
            cell.isSelected = (selectedList?.id == filterList.id)
            return cell
        }
        
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: UserCellId, for: indexPath) as! UserAndListCell
            return cell
        }
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                
        // User Selected
        if self.searchUser{
            var userSelected: User?
            if isFiltering{
                userSelected = filteredUsers[indexPath.row]
            } else {
                if self.selectedScope == 0 {
                    userSelected = followingUsers[indexPath.row]
                } else {
                    userSelected = otherUsers[indexPath.row]
                }
            }
            print("UserListSearchView | TableView Select | User: \(userSelected?.username) | \(indexPath.row) ")
            self.userSelected(user: userSelected)
        }

        else if self.searchList{
            var listSelected: List?
            if isFiltering{
                listSelected = filteredList[indexPath.row]
            } else {
                if self.selectedScope == 0 {
                    listSelected = createdLists[indexPath.row]
                } else {
                    listSelected = followingLists[indexPath.row]
                }
            }
            print("UserListSearchView | TableView Select | List: \(listSelected?.name) | \(indexPath.row)")
            self.listSelected(list: listSelected)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func userSelected(user: User?) {
        self.delegate?.userSelected(user: user)
        self.dismiss(animated: true) {
            print("UserListSearchView | User Selected | User: \(user?.username)")
        }
    }

    func listSelected(list: List?) {
        self.delegate?.listSelected(list: list)
        self.dismiss(animated: true) {
            print("UserListSearchView | List Selected | User: \(list?.name)")
        }
    }
    
    @objc func handleDismiss() {
        print("UserListSearchView | Dismiss")
        self.dismiss(animated: true, completion: nil)
    }
    
}
