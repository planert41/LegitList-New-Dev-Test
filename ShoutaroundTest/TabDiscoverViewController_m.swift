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

class TabSearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UISearchBarDelegate, DiscoverListCellDelegate, UIScrollViewDelegate, DiscoverUserCellDelegate, DiscoverListCellNewDelegate, UserAndListCellDelegate {
   
    static let refreshListNotificationName = NSNotification.Name(rawValue: "RefreshList")
    
// FETCH INPUTS
    
    var allUsers: [User] = []
    var filteredUsers: [User] = []
    
    var allLists: [List] = []
    var filteredLists: [List] = []

    var allPlaces: [Location] = []
    var filteredPlaces: [Location] = []
    
    var allCity: [City] = []
    var filteredCity: [City] = []

    var searchFiltering = false
    var searchText: String?
    var searchTerms: [String] = []
    var searchTermsType: [String] = []
    
    var followingLists: [List] = []
    var yourLists: [List] = []

    var fetchedList: [List] = []
    var filteredDisplayList: [List] = []
    
    var selectedSearchSegmentIndex: Int? = nil
//    var searchSegment: ReselectableSegmentedControl = {
//        var segment = ReselectableSegmentedControl(items: TabSearchOptions)
//        return segment
//    }()
    
    var searchSegment: UISegmentedControl = {
        var segment = UISegmentedControl(items: TabSearchOptions)
        return segment
    }()
    var searchTypeOptions: [String] = TabSearchOptions
//    var TabSearchOptions:[String] = [DiscoverUser, DiscoverList, DiscoverPlaces, DiscoverCities]

    
    var searchType: String = DiscoverUser {
        didSet {
            self.refreshItems()
        }
    }
    

    let listCellId = "ListCellId"
    let userCellId = "UserCellId"
    let searchResultCellId = "searchResultCellId"

    
    var sortOptions: [String] = DiscoverSortOptions
    var selectedSort: String = DiscoverSortDefault {
        didSet{
            self.sortItems()
            setupSortButton()
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
        print("Display Friends For Current User| ",CurrentUser.user?.uid)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayAllUsers = true
        postSocialController.displayUserFollowing = true
        postSocialController.displayUser = true
        postSocialController.inputUser = CurrentUser.user
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    let buttonBar = UIView()

    
    
    let createNewListButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        button.setImage(#imageLiteral(resourceName: "add_list").withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTitle(" New List", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
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
        self.createNewListButton.isHidden = !(searchType == ListYours)
    }
    @objc  
    func didCreateNewList() {
        print("New Lists Created | Discover Controller")
        self.selectedSort = sortNew
        self.fetchAllItems()
    }
    
    var sortSegmentControl: UISegmentedControl = UISegmentedControl(items: ItemSortOptions)
    var segmentWidth_selected: CGFloat = 110.0
    var segmentWidth_unselected: CGFloat = 80.0
    var defaultWidth: CGFloat  = 828.0
    var scalar: CGFloat = 1.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(didCreateNewList), name:TabListViewController.refreshListNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(locationDenied), name: AppDelegate.LocationDeniedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(locationUpdated), name: AppDelegate.LocationUpdatedNotificationName, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(refreshItems), name: AppDelegate.UserFollowUpdatedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.newUserFollow(_:)), name: AppDelegate.UserFollowUpdatedNotificationName, object: nil)

        
        setupNavigationItems()
        setupSortButton()
        setupDropDown()
        setupTableView()
        fetchAllItems()
        
        view.addSubview(actionView)
        actionView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        actionView.backgroundColor = UIColor.white
        

        actionView.addSubview(searchSegment)
        searchSegment.anchor(top: actionView.topAnchor, left: actionView.leftAnchor, bottom: actionView.bottomAnchor, right: actionView.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 10, width: 0, height: 50)
        actionView.layer.applySketchShadow(color: UIColor(red: 0, green: 0, blue: 0, alpha: 0.5), alpha: 0.5, x: 0, y: 2, blur: 4, spread: 0)
        setupTypeSegment()
        
        
        view.addSubview(tableView)
        tableView.anchor(top: actionView.bottomAnchor, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        
        setupSegmentControl()
        view.addSubview(sortSegmentControl)
        sortSegmentControl.anchor(top: nil, left: nil, bottom: bottomLayoutGuide.topAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 10, width: 0, height: 40)
        sortSegmentControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        sortSegmentControl.alpha = 0.9

//        sortSegmentControl.rightAnchor.constraint(lessThanOrEqualTo: navMapButton.leftAnchor, constant: 15).isActive = true

//        sortSegmentControl.centerXAnchor.constraint(equalTo: barView.centerXAnchor).isActive = true
        self.refreshSort(sender: sortSegmentControl)

        
    }
    
    func setupSegmentControl() {
        sortSegmentControl = UISegmentedControl(items: ItemSortOptions)
        sortSegmentControl.selectedSegmentIndex = 0
        sortSegmentControl.addTarget(self, action: #selector(selectItemSort), for: .valueChanged)
        sortSegmentControl.backgroundColor = UIColor.white
        sortSegmentControl.tintColor = UIColor.oldLegitColor()
        sortSegmentControl.layer.borderWidth = 1
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
    
    @objc func locationUpdated() {
        if self.isPresented  {
            if self.selectedSort  == sortNearest && (CurrentUser.currentLocation != nil){
                self.sortItems()
            }
        }
    }
    
    @objc func locationDenied() {
        if self.isPresented {
            self.missingLocAlert()
            self.sortSegmentControl.selectedSegmentIndex = HeaderSortOptions.index(of: sortNew) ?? 0
            self.selectedSort = sortNew
            print("LegitHomeView Location Denied Function")
        }
    }

    func initFetchAllItems() {
        Database.fetchALLLists { (allLists) in
            self.allLists = allLists
            self.filteredLists = allLists
            print("Fetched \(self.allLists.count) Lists | Fetch All Items - TabSearchViewController")
        }
        
        Database.fetchALLUsers { (users) in
            self.allUsers = users
            self.filteredUsers = users
            print("Fetched \(self.allUsers.count) Users | Fetch All Items - TabSearchViewController")
        }
        
        Database.fetchAllLocations { (locations) in
            self.allPlaces = locations
            self.filteredPlaces = locations
        }
        
        Database.fetchAllCities { (cities) in
            self.allCity = cities
            self.filteredCity = cities
        }
        
    }
    
    
    func fetchAllItems() {
        if searchType == DiscoverList {
            if self.allLists.count == 0 {
                SVProgressHUD.show(withStatus: "Fetching Lists")
                Database.fetchALLLists { (allLists) in
                    self.allLists = allLists
                    self.filteredLists = allLists
                    self.filterLists()
                    print("Fetched \(self.allLists.count) Lists | Fetch All Items - TabSearchViewController")
                }
            } else {
                self.filterLists()
            }

        }
        
        else if searchType == DiscoverUser {
            if allUsersFetched.count == 0  {
                SVProgressHUD.show(withStatus: "Fetching Users")
                Database.fetchALLUsers { (users) in
                    self.allUsers = users
                    self.filteredUsers = users
                    self.filterUsers()
                    print("Fetched \(self.allUsers.count) Users | Fetch All Items - TabSearchViewController")
                }
            } else {
                self.allUsers = allUsersFetched
                self.filteredUsers = allUsersFetched
                self.filterUsers()
            }
        }
        
        else if searchType == DiscoverPlaces{
            if self.allPlaces.count == 0 {
                SVProgressHUD.show(withStatus: "Fetching Places")
                Database.fetchAllLocations { (locations) in
                    self.allPlaces = locations
                    self.filteredPlaces = locations
                    self.filterPlaces()
                }
            } else {
                self.filterPlaces()
            }
    
        }
        
        else if searchType == DiscoverCities {
            if self.allCity.count == 0 {
                SVProgressHUD.show(withStatus: "Fetching Cities")
                Database.fetchAllCities { (cities) in
                    self.allCity = cities
                    self.filteredCity = cities
                    self.filterCities()
                }
            } else {
                self.filterCities()
            }
        }
        
    }
    
    func sortItems() {
        if searchType == DiscoverUser {
            Database.sortUsers(inputUsers: self.isFiltering ? self.filteredUsers : self.allUsers, selectedSort: self.selectedSort, selectedLocation: nil) { (sortedUsers) in
                if self.isFiltering {
                    self.filteredUsers = sortedUsers ?? []
                } else {
                    self.allUsers = sortedUsers ?? []
                }
                self.tableView.refreshControl?.endRefreshing()
                self.tableView.reloadData()
            }
        } else if searchType == DiscoverList {
            Database.sortList(inputList: self.isFiltering ? self.filteredLists : self.allLists, sortInput: self.selectedSort, completion: { (lists) in
                if self.isFiltering {
                    self.filteredLists = lists
                } else {
                    self.allLists = lists
                }
                self.tableView.refreshControl?.endRefreshing()
                self.tableView.reloadData()
            })
        } else if searchType == DiscoverPlaces {
            Database.sortLocation(inputLocation: self.isFiltering ? self.filteredPlaces : self.allPlaces, sortInput: self.selectedSort, completion: { (places) in
                if self.isFiltering {
                    self.filteredPlaces = places
                } else {
                    self.allPlaces = places
                }
                self.tableView.refreshControl?.endRefreshing()
                self.tableView.reloadData()
            })
        } else if searchType == DiscoverCities {
            Database.sortCities(inputCity: self.isFiltering ? self.filteredCity : self.allCity, sortInput: self.selectedSort, completion: { (cities) in
                if self.isFiltering {
                    self.filteredCity = cities
                } else {
                    self.allCity = cities
                }
                self.tableView.refreshControl?.endRefreshing()
                self.tableView.reloadData()
            })
        }

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
        tableView.register(SearchResultsCell.self, forCellReuseIdentifier: searchResultCellId)
        tableView.register(UserAndListCell.self, forCellReuseIdentifier: newCellId)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshAll), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.alwaysBounceVertical = true
        tableView.keyboardDismissMode = .onDrag
        tableView.allowsSelection = false
        tableView.delegate = self

    }
    
    func setupTypeSegment(){
        searchSegment.selectedSegmentIndex = searchTypeOptions.firstIndex(of: self.searchType) ?? 0
        searchSegment.selectedSegmentTintColor = UIColor.ianLegitColor()
        searchSegment.addTarget(self, action: #selector(selectFetchType), for: .valueChanged)
        searchSegment.backgroundColor = .white
        searchSegment.tintColor = .white
        
        UILabel.appearance(whenContainedInInstancesOf: [UISegmentedControl.self]).numberOfLines = 2
                
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attributes = [
            NSAttributedString.Key.foregroundColor : UIColor.white,
            NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 12),
            NSAttributedString.Key.paragraphStyle: paragraph
        ]
        
        let selectedAttributes = [
            NSAttributedString.Key.foregroundColor : UIColor.ianWhiteColor(),
            NSAttributedString.Key.font : UIFont(font: .avenirNextBold, size: 15),
            NSAttributedString.Key.paragraphStyle: paragraph
        ]
        
        let unSelectedAttributes = [
            NSAttributedString.Key.foregroundColor : UIColor.ianBlackColor(),
            NSAttributedString.Key.font : UIFont(font: .avenirNextMedium, size: 14),
            NSAttributedString.Key.paragraphStyle: paragraph
        ]
        
        searchSegment.setTitleTextAttributes(unSelectedAttributes, for: .normal)
        searchSegment.setTitleTextAttributes(selectedAttributes, for: .selected)
        searchSegment.apportionsSegmentWidthsByContent = true
        searchSegment.tintColor = UIColor.ianWhiteColor()
        searchSegment.backgroundColor = UIColor.clear
        
        refreshTypeSegment()
        
    }

    func refreshTypeSegment() {

        for (index, sortOptions) in searchTypeOptions.enumerated()
        {
            var isSelected = (index == self.selectedSearchSegmentIndex)
            var searchType = String(SearchSegmentLookup.key(forValue: sortOptions) ?? "")
            
//            var searchTypeText = SearchSegmentLookup.index(forKey: searchType)

            var displayFilter = "\(searchType) \n \(sortOptions)"

            searchSegment.setTitle(displayFilter, forSegmentAt: index)
//            print(index, displayFilter)
//            searchSegment.setWidth((isSelected) ? selectedSegmentWidth : unselectedSegmentWidth, forSegmentAt: index)
//            (searchSegment.subviews[index] as! UIView).tintColor = isSelected ? UIColor.ianLegitColor() : UIColor.ianWhiteColor()

        }
        searchSegment.layoutIfNeeded()
        searchSegment.apportionsSegmentWidthsByContent = true
        self.view.layoutIfNeeded()
    }

    
    @objc func selectFetchType(sender: UISegmentedControl) {
        self.searchType = self.searchTypeOptions[sender.selectedSegmentIndex]
        print("DiscoverController | Type Selected | \(self.searchType)")
    }
    

    
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
//        searchBar.searchBarStyle = .default
        searchBar.searchBarStyle = .prominent
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
            let searchPlaceHolder = "Search " + searchType
            searchTextField!.attributedPlaceholder = NSAttributedString(string: searchPlaceHolder, attributes: attributeDict)
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

//        self.view.addSubview(dropDownMenu)
//        dropDownMenu.anchor(top: topLayoutGuide.bottomAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 50, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)

        
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
        
        if searchType == DiscoverList {
            self.filterLists()
        } else if searchType == DiscoverUser {
            self.filterUsers()
        } else if searchType == DiscoverPlaces {
            self.filterPlaces()
        } else if searchType == DiscoverCities {
            self.filterCities()
        }
    }
    
    func filterLists() {
        guard let searchText = searchBar.text else {
            self.isFiltering = false
            self.filteredLists = self.allLists
            self.sortItems()
            return
        }
        
        self.isFiltering = searchText.count != 0
        
        let searchTerms = searchText.lowercased().components(separatedBy: " ")
        
        self.filteredLists = allLists.filter({ (list) -> Bool in
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
        
        filteredLists.sort { (p1, p2) -> Bool in
            ((p1.name.hasPrefix(searchText.lowercased())) ? 0 : 1) < ((p2.name.hasPrefix(searchText.lowercased())) ? 0 : 1)
        }
        self.sortItems()
    }
    
    func filterUsers() {
        guard let searchText = searchBar.text else {
            self.isFiltering = false
            self.filteredUsers = self.allUsers
            self.sortItems()
            return
        }
        
        self.isFiltering = searchText.count != 0
        
        let searchTerms = searchText.lowercased().components(separatedBy: " ")
        
        self.filteredUsers = allUsers.filter({ (user) -> Bool in
            var emojiTranslateArray: [String] = []
            var emojiFilter = false

            return user.username.lowercased().contains(searchText.lowercased())
        })
        
        filteredUsers.sort { (p1, p2) -> Bool in
            ((p1.username.hasPrefix(searchText.lowercased())) ? 0 : 1) < ((p2.username.hasPrefix(searchText.lowercased())) ? 0 : 1)
        }
        self.sortItems()
    }
    
    func filterPlaces() {
        guard let searchText = searchBar.text else {
            self.isFiltering = false
            self.filteredPlaces = self.allPlaces
            self.sortItems()
            return
        }
        
        self.isFiltering = searchText.count != 0
        
        let searchTerms = searchText.lowercased().components(separatedBy: " ")
        
        self.filteredPlaces = allPlaces.filter({ (place) -> Bool in
            var emojiTranslateArray: [String] = []
            var emojiFilter = false

            let locName = place.locationName ?? ""
            let locAdress = place.locationAdress ?? ""
            let locCity = place.locationSummaryID ?? ""

            return locName.lowercased().contains(searchText.lowercased()) || locAdress.lowercased().contains(searchText.lowercased()) || locCity.lowercased().contains(searchText.lowercased())
        })
        
        filteredPlaces.sort { (p1, p2) -> Bool in
            (((p1.locationName ?? "").hasPrefix(searchText.lowercased())) ? 0 : 1) < (((p2.locationName ?? "").hasPrefix(searchText.lowercased())) ? 0 : 1)
        }
        self.sortItems()
    }
    
    func filterCities() {
        guard let searchText = searchBar.text else {
            self.isFiltering = false
            self.filteredCity = self.allCity
            self.sortItems()
            return
        }
        
        self.isFiltering = searchText.count != 0
        
        let searchTerms = searchText.lowercased().components(separatedBy: " ")
        
        self.filteredCity = allCity.filter({ (place) -> Bool in
            var emojiTranslateArray: [String] = []
            var emojiFilter = false

            let locName = place.cityName ?? ""

            return locName.lowercased().contains(searchText.lowercased())
        })
        
        filteredCity.sort { (p1, p2) -> Bool in
            (((p1.cityName ?? "").hasPrefix(searchText.lowercased())) ? 0 : 1) < (((p2.cityName ?? "").hasPrefix(searchText.lowercased())) ? 0 : 1)
        }
        self.sortItems()
    }
    
    @objc func newUserFollow(_ notification: NSNotification) {
        let uid = (notification.userInfo?["uid"] ?? "")! as! String
        let following = ((notification.userInfo?["following"] ?? 0)! as? Int) ?? 0
        print("NEW USER FOLLOW | \(uid) : \(following)")
        self.refreshUserFollowing()
        self.tableView.reloadData()
                
//        if let index = allUsers.firstIndex(where: { (user) -> Bool in
//            user.uid == uid
//        }){
//            var temp = allUsers[index] as User
//            temp.isFollowing = following == 1
//            allUsers[index] = temp
//            print("newUserFollow", index, temp.username, temp.isFollowing, allUsers[index].isFollowing)
//            if searchType == DiscoverUser && !self.isFiltering {
//                let indexPath = IndexPath(row: index, section: 0)
//                if index < self.tableView.visibleCells.count {
//                    self.tableView.reloadRows(at: [indexPath], with: .none)
//                }
//            }
//        }
//        
//        if let index = filteredUsers.firstIndex(where: { (user) -> Bool in
//            user.uid == uid
//        }){
//            var temp = filteredUsers[index] as User
//            temp.isFollowing = following == 1
//            filteredUsers[index] = temp
//            print("newUserFollow", index, temp.username, temp.isFollowing, filteredUsers[index].isFollowing)
//            if searchType == DiscoverUser && self.isFiltering {
//                let indexPath = IndexPath(row: index, section: 0)
//                if index < self.tableView.visibleCells.count {
//                    self.tableView.reloadRows(at: [indexPath], with: .none)
//                }
//            }
//        }
    }
    
    func refreshUserFollowing() {
        for (index, user) in self.allUsers.enumerated() {
            var x = user
            let uid = x.uid
            var curFollowing = x.isFollowing
            var newFollowing = CurrentUser.followingUids.contains(uid)
            
            if curFollowing != newFollowing {
                x.isFollowing = newFollowing
                self.allUsers[index] = x
                print("refreshUserFollowing allUser", uid, curFollowing, newFollowing, x.isFollowing)
            }
        }
        
        for (index, user) in self.filteredUsers.enumerated() {
            var x = user
            let uid = x.uid
            var curFollowing = x.isFollowing
            var newFollowing = CurrentUser.followingUids.contains(uid)
            
            if curFollowing != newFollowing {
                x.isFollowing = newFollowing
                self.filteredUsers[index] = x
                print("refreshUserFollowing filterUser", uid, curFollowing, newFollowing, x.isFollowing)
            }
        }
    }
    
    @objc func refreshItems(){
        self.setupTypeSegment()
        self.fetchAllItems()
        self.showHideAddListButton()
        self.setupNavigationItems()

    }

    @objc func refreshAll(){
        print("DiscoverController | Refresh All")
        self.searchBar.text == ""
        self.isFiltering = false
        self.refreshItems()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.setupNavigationItems()
        if self.allLists.count == 0 || allUsers.count == 0 {
            self.fetchAllItems()
        }
        self.setupTypeSegment()
        self.view.layoutIfNeeded()
        //        self.setupLists()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.setupTypeSegment()
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
        
        if searchType == DiscoverUser {
            return max(0, self.isFiltering ? self.filteredUsers.count : self.allUsers.count)
        } else if searchType == DiscoverList {
            return max(0, self.isFiltering ? self.filteredLists.count : self.allLists.count)
        } else if searchType == DiscoverPlaces {
            return max(0, self.isFiltering ? self.filteredPlaces.count : self.allPlaces.count)
        } else if searchType == DiscoverCities {
            return max(0, self.isFiltering ? self.filteredCity.count : self.allCity.count)
        } else {
            return 0
        }
    }
    
    //    var TabSearchOptions:[String] = [DiscoverUser, DiscoverList, DiscoverPlaces, DiscoverCities]

//    tableView.register(SearchResultsCell.self, forCellReuseIdentifier: searchResultCellId)
//    tableView.register(UserAndListCell.self, forCellReuseIdentifier: newCellId)
    
//    func returnEmptyCell() -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: searchResultCellId, for: IndexPath(row: 0, section: 0)) as! SearchResultsCell
//        cell.emojiTextLabel.textAlignment = .center
//        cell.locationName = "No Results Available"
//        cell.selectionStyle = .none
//        cell.postCountLabel.isHidden = true
//        return cell
//    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        SVProgressHUD.dismiss()
        let cell = tableView.dequeueReusableCell(withIdentifier: newCellId, for: indexPath) as! UserAndListCell
        cell.cellType = self.searchType
        cell.delegate = self
        cell.contentView.isUserInteractionEnabled = false
        
        if searchType == DiscoverUser {
//            if (allUsers.count == 0 || (isFiltering && filteredUsers.count == 0)) {
//                return returnEmptyCell()
//            }
            let currentUser = isFiltering ? filteredUsers[indexPath.row] : allUsers[indexPath.row]
            cell.user = currentUser
            cell.selectionStyle = .none
            cell.cellHeight?.constant = 80
            return cell
        }
        else if searchType == DiscoverList {
//            if (allLists.count == 0 || (isFiltering && filteredLists.count == 0)) {
//                return returnEmptyCell()
//            }
            let currentList = isFiltering ? filteredLists[indexPath.row] : allLists[indexPath.row]
            cell.cellHeight?.constant = 90
            cell.list = currentList
            return cell
        }
        else if searchType == DiscoverPlaces {
//            if (allPlaces.count == 0 || (isFiltering && filteredPlaces.count == 0)) {
//                return returnEmptyCell()
//            }
            let currentLoc = isFiltering ? filteredPlaces[indexPath.row] : allPlaces[indexPath.row]
            cell.cellHeight?.constant = 80
            cell.location = currentLoc
            return cell
        }
        else if searchType == DiscoverCities {
//            if (allCity.count == 0 || (isFiltering && filteredCity.count == 0)) {
//                return returnEmptyCell()
//            }
            let tempCity = isFiltering ? filteredCity[indexPath.row] : allCity[indexPath.row]
            cell.cellHeight?.constant = 80
            cell.city = tempCity
            return cell
        }
        
        
        
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: newCellId, for: indexPath) as! UserAndListCell
            return cell
        }

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if searchType == DiscoverUser {
            let currentUser = isFiltering ? filteredUsers[indexPath.row] : allUsers[indexPath.row]
            self.extTapUser(userId: currentUser.uid)
        } else if searchType == DiscoverList {
            let currentList = isFiltering ? filteredLists[indexPath.row] : allLists[indexPath.row]
            self.extTapList(list: currentList)
        } else if searchType == DiscoverPlaces {
            let currentLoc = isFiltering ? filteredPlaces[indexPath.row] : allPlaces[indexPath.row]
            self.goToLocation(location: currentLoc)
        } else if searchType == DiscoverCities {
            let tempCity = isFiltering ? filteredCity[indexPath.row] : allCity[indexPath.row]
            self.showCity(city: tempCity)
        }
    }
    
    func showCity(city: City) {
        let cityFilter = Filter.init()
        cityFilter.filterLocationSummaryID = city.cityName
        
        appDelegateFilter = cityFilter
        NotificationCenter.default.post(name: AppDelegate.ShowCityNotificationName, object: nil)
    }
    
    
    func goToLocation(location: Location?) {
        guard let location = location else {return}
//        if (location.postIds?.count ?? 0) > 0 {
//            let tmp = location.postIds![0]
//            Database.fetchPostWithPostID(postId: tmp, force: false) { (post, err) in
//                guard let post = post else {return}
//                self.extTapLocation(post: post)
//            }
//        }
        self.extTapLocation(location: location)

//        Database.fetchLocationWithLocID(locId: location.locationGoogleID) { (loc) in
//            if loc == nil {
//                print("No Location Found for \(loc?.locationGoogleID)")
//                if (loc?.postIds?.count ?? 0) > 0 {
//                    guard let tmp = loc?.postIds![0] else {return}
//                    Database.fetchPostWithPostID(postId: tmp, force: false) { (post, err) in
//                        guard let post = post else {return}
//                        print("Using first post for Location: \(tmp) Post : \(loc?.locationGoogleID) Loc")
//                        self.extTapLocation(post: post)
//                    }
//                }
//            } else {
//                self.extTapLocation(location: loc)
//            }
//        }
    }
    
    func goToUser(userId: String?)
    {
        guard let userId = userId else {return}
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = userId
        self.navigationController?.pushViewController(userProfileController, animated: true)
    }

    
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
        
        return self.searchType == DiscoverList ? 90 : 80

    }
    
    
     func scrollViewDidScroll(_ scrollView: UIScrollView) {

    }
    
}


