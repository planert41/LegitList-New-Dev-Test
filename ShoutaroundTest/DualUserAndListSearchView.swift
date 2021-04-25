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


class DualUserListSearchView : UITableViewController, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate{


    
    let UserCellId = "UserCellId"
    let ListCellId = "ListCellId"
    
    
    var inputUser: User? {
        didSet {
            updateSearchView()
        }
    }
    
    
    
    var delegate: UserListSearchViewDelegate?

    var scopeBarOptions:[String] = DualUserListSearchOptions {
        didSet {
            setScopeBarOptions()
        }
    }
    

    func updateSearchView() {
        setupNavigationItems()
        setScopeBarOptions()
        self.fetchAllListsForUser()
        self.fetchAllUsers()

    }
    
    
    func setScopeBarOptions() {
        let userText = "💁‍♂️ " + DualUserListSearchOptions[0] +  " \(self.allUsers.count)"
        let listText = "📕 " + DualUserListSearchOptions[1] + " \(self.allLists.count)"
        self.searchBar.scopeButtonTitles = [userText, listText]
        
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

    var createdLists = [List]()
    var followingLists = [List]()
    var filteredList = [List]()
    var allLists = [List]()

    
    
    let searchController = UISearchController(searchResultsController: nil)
    var searchBar = UISearchBar()
    
    func fetchAllUsers(){
        guard let inputUser = inputUser else {return}
        let uid = inputUser.uid
        
        self.otherUsers.removeAll()
        self.followingUsers.removeAll()
        
        Database.fetchALLUsers(includeSelf: true) { (fetchedUsers) in
            
            self.allUsers = fetchedUsers
            self.allUsers = self.allUsers.sorted(by: { (u1, u2) -> Bool in
                u1.posts_created > u2.posts_created
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
            
            for user in fetchedUsers {
                if CurrentUser.followingUids.contains(user.uid) || (uid == user.uid) {
                    self.followingUsers.append(user)
                } else {
                    self.otherUsers.append(user)
                }
            }
            
            print("   Fetched \(self.allUsers.count) Users")
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
            self.allLists = fetchedLists
            self.allLists.sort(by: { (l1, l2) -> Bool in
                (l1.postIds?.count ?? 0) > (l2.postIds?.count ?? 0)
            })
            
    // MOVE SELECTED LIST TO FIRST
        if let selectedList = self.selectedList {
            if let index = self.allLists.firstIndex(where: { (list) -> Bool in
                return list.id == selectedList.id
            }) {
                let temp = self.allLists.remove(at: index)
                self.allLists.insert(temp, at: 0)
            }
       
        }
            
            
            print("   Fetched \(self.allLists.count) Lists: \(inputUser.listIds.count) List IDs | \(inputUser.username)")
            self.setScopeBarOptions()
            self.tableView.reloadData()
        }
        
    }
    
    
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
        
    
    
    @objc func handleBackPressNav(){
        self.handleDismiss()
    }
    

    func setupNavigationItems(){
        
    // Header

        
//        self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.ianLegitColor(), NSAttributedString.Key.font.rawValue: UIFont(name: "Poppins-Bold", size: 18)])
        var titleString = "Filter Map"

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
        self.navigationController?.navigationBar.layoutIfNeeded()


    // Nav Back Buttons
        
        navBackButton.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        let barButton2 = UIBarButtonItem.init(customView: navBackButton)
        self.navigationItem.rightBarButtonItem = barButton2
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
        definesPresentationContext = true
        searchBar.backgroundColor = UIColor.ianLegitColor()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
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
        filteredUsers = self.allUsers.filter { (user) -> Bool in
            return user.username.lowercased().contains(searchText.lowercased())
        }
        
        filteredList = self.allLists.filter { (list) -> Bool in
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


extension DualUserListSearchView {
    
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

        if isFiltering {
            if self.selectedScope == 0 {
//                print("Filtered User| ",followingUsers.count)
                return filteredUsers.count
            } else{
//                print("Filtered User| ",otherUsers.count)
                return filteredList.count
            }
        } else {
            if self.selectedScope == 0 {
//                print("User| ",allUsers.count)
                return allUsers.count
            } else{
//                print("Lists| ",allLists.count)
                return allLists.count
            }
        }

    }
    
//    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 70 + 90 + 10
//    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // USERS
        if self.selectedScope == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: UserCellId, for: indexPath) as! UserAndListCell
            let filterUser = self.isFiltering ? filteredUsers[indexPath.row] : allUsers[indexPath.row]
            cell.user = filterUser
            cell.isSelected = (selectedUser?.uid == filterUser.uid)
            return cell
        }
        
        // LIST
        
        else {
//            let cell = tableView.dequeueReusableCell(withIdentifier: ListCellId, for: indexPath) as! NewListCell
            let cell = tableView.dequeueReusableCell(withIdentifier: UserCellId, for: indexPath) as! UserAndListCell
            let filterList = self.isFiltering ? filteredList[indexPath.row] : allLists[indexPath.row]
            cell.list = filterList
            cell.isSelected = (selectedList?.id == filterList.id)
            return cell
        }

    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                
        // USERS
        if self.selectedScope == 0 {
            let filterUser = self.isFiltering ? filteredUsers[indexPath.row] : allUsers[indexPath.row]
            print("UserListSearchView | TableView Select | User: \(filterUser.username) | \(indexPath.row) ")
            self.userSelected(user: filterUser)
        }
        
        // LIST
        
        else {
            let filterList = self.isFiltering ? filteredList[indexPath.row] : allLists[indexPath.row]
            print("UserListSearchView | TableView Select | List: \(filterList.name) | \(indexPath.row)")
            self.listSelected(list: filterList)
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
    
    func handleDismiss() {
        print("UserListSearchView | Dismiss")
        self.dismiss(animated: true, completion: nil)
    }
    
}
