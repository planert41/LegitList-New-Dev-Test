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

class OldDiscoverController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UISearchBarDelegate, DiscoverListCellDelegate, UIScrollViewDelegate, DiscoverUserCellDelegate, DiscoverListCellNewDelegate {
   
    static let refreshListNotificationName = NSNotification.Name(rawValue: "RefreshList")
    
// FETCH INPUTS

    var fetchedUser: [User] = []
    var filteredDisplayUser: [User] = []

    var fetchedList: [List] = []
    var filteredDisplayList: [List] = []
    
    var fetchTypeSegment = UISegmentedControl()
    var fetchTypeOptions: [String] = DiscoverOptions
    var fetchType: String = DiscoverDefault {
        didSet {
            self.refreshItems()
        }
    }
    
    let listCellId = "ListCellId"
    let userCellId = "UserCellId"
    
    
    var sortOptions: [String] = DiscoverSortOptions
    var selectedSort: String = DiscoverSortDefault {
        didSet{
            self.refreshItems()
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
        button.setTitleColor(UIColor.darkLegitColor(), for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 13)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.layer.borderWidth = 1
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

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationItems()
        setupTypeSegment()
        setupSortButton()
        setupDropDown()
        setupTableView()
        
        view.addSubview(actionView)
        actionView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        
        actionView.addSubview(sortButton)
        sortButton.anchor(top: actionView.topAnchor, left: nil, bottom: actionView.bottomAnchor, right: actionView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 10, width: 120, height: 40)
        
        self.view.addSubview(dropDownMenu)
        dropDownMenu.anchor(top: actionView.bottomAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 50, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        
        actionView.addSubview(fetchTypeSegment)
        fetchTypeSegment.anchor(top: actionView.topAnchor, left: actionView.leftAnchor, bottom: actionView.bottomAnchor, right: sortButton.leftAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)
        
//        let segmentWidth = (fetchTypeSegment.frame.width) / CGFloat(fetchTypeSegment.numberOfSegments)
        let segmentWidth = 100 as CGFloat

        buttonBar.backgroundColor = UIColor.ianLegitColor()
        actionView.addSubview(buttonBar)
        buttonBar.anchor(top: nil, left: nil, bottom: fetchTypeSegment.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: segmentWidth, height: 5)
        buttonBar.leftAnchor.constraint(lessThanOrEqualTo: fetchTypeSegment.leftAnchor).isActive = true
        buttonBar.rightAnchor.constraint(lessThanOrEqualTo: fetchTypeSegment.rightAnchor).isActive = true
        
        view.addSubview(tableView)
        tableView.anchor(top: actionView.bottomAnchor, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
    
        fetchItems()
        
    }
    
    func fetchItems(){
        if self.fetchType == DiscoverList {
            self.fetchLists()
        } else if self.fetchType == DiscoverUser {
            self.fetchUsers()
        }
    }
    
    func fetchLists() {
        print("DiscoverController | Fetch Lists | \(self.selectedSort)")
        Database.fetchALLLists { (allLists) in
        // Fetches All List that are not Legit/Bookmark and >0 Posts
            Database.sortList(inputList: allLists, sortInput: self.selectedSort, completion: { (lists) in
                self.fetchedList = lists
                self.filteredDisplayList = lists
                self.tableView.reloadData()
            })
        }
    }
    
    
    
    func fetchUsers(){
        print("DiscoverController | Fetch Users | \(self.selectedSort)")
        Database.fetchALLUsers(includeSelf: true, completion: { (allUsers) in
            let filteredUsers = allUsers.filter({ (user) -> Bool in
                return user.posts_created > 0
            })
            
            
            Database.sortUsers(inputUsers: allUsers, selectedSort: self.selectedSort, selectedLocation: CurrentUser.currentLocation, completion: { (users) in
                self.fetchedUser = users ?? []
                self.filteredDisplayUser = users ?? []
                self.tableView.reloadData()
            })
            
        })
    }
    
    func setupSortButton(){
        
        var attributedTitle = NSMutableAttributedString()
        
        let sortTitle = NSAttributedString(string: self.selectedSort + " ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 15)])
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
        tableView.register(DiscoverListCellNew.self, forCellReuseIdentifier: listCellId)
        tableView.register(DiscoverUserCell.self, forCellReuseIdentifier: userCellId)
        tableView.register(UserAndListCell.self, forCellReuseIdentifier: newCellId)

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
        fetchTypeSegment.addTarget(self, action: #selector(selectFetchType), for: .valueChanged)
        
        fetchTypeSegment.backgroundColor = .white
        fetchTypeSegment.tintColor = .white
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        fetchTypeSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: 18), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
        fetchTypeSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 18), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)
//        fetchTypeSegment.setTitleTextAttributes([NSAttributedString.Key.font: HeaderFontSizeDefault], for: .normal)
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
        print("DiscoverController | Type Selected | \(self.fetchType)")
    }
    

    
    func setupNavigationItems(){
        //        navigationItem.title = "Manage Lists"
        
        navigationController?.navigationBar.barTintColor = UIColor.white
        navigationController?.navigationBar.tintColor = UIColor.white
        // REMOVES THE 1PX BOTTOM LINE IN NAV BAR
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationItem.titleView = searchBar
//        navigationController?.navigationBar.backgroundColor = UIColor.ianLegitColor()
        searchBar.sizeToFit()
        searchBar.delegate = self
        searchBar.showsCancelButton = true
        
        searchBar.barTintColor = UIColor.white
        searchBar.tintColor = UIColor.ianLegitColor()
        searchBar.backgroundColor = UIColor.white
        searchBar.backgroundImage = UIImage()
        searchBar.layer.borderWidth = 0
        definesPresentationContext = false
        
        searchBar.layer.cornerRadius = 5
        searchBar.layer.masksToBounds = true
        searchBar.clipsToBounds = true
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
            let attributeDict = [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor()]
            searchTextField!.attributedPlaceholder = NSAttributedString(string: "Discover Users & Lists", attributes: attributeDict)
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
//                s.backgroundColor = UIColor.white
            }
        }
        
        
        
        navFriendButton.addTarget(self, action: #selector(openFriends), for: .touchUpInside)
        let friendButton = UIBarButtonItem.init(customView: navFriendButton)
        navigationItem.rightBarButtonItem = friendButton
    }

    
    
    
    var dropDownMenu = DropDown()
    func setupDropDown(){
        dropDownMenu.anchorView = sortButton
        dropDownMenu.dismissMode = .automatic
        dropDownMenu.textColor = UIColor.lightGray
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
    
    @objc func filterContentForSearchText(_ searchText: String) {
        self.isFiltering = searchText.count != 0
        
        let searchTerms = searchText.lowercased().components(separatedBy: " ")
        
        if self.fetchType == DiscoverList {
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
            
        } else if self.fetchType == DiscoverUser {
    // FILTER USER TABLE VIEW

            self.filteredDisplayUser = fetchedUser.filter({ (user) -> Bool in
                
                var emojiTranslateArray: [String] = []
                var emojiFilter = false
                for term in searchTerms {
                    for text in user.topEmojis {
                        if let word = EmojiDictionary[text] {
                            if word.contains(term){
                                emojiFilter = true
                            }
                        }
                    }
                    
                    if user.username.lowercased().contains(term) {
                        emojiFilter = true
                    }
                }
                
                return user.username.lowercased().contains(searchText.lowercased()) || emojiFilter
            })
            
            self.filteredDisplayUser.sort { (p1, p2) -> Bool in
                ((p1.username.hasPrefix(searchText.lowercased())) ? 0 : 1) < ((p2.username.hasPrefix(searchText.lowercased())) ? 0 : 1)
            }
            
            self.tableView.reloadData()
            
        }

    }
    
    @objc func refreshItems(){
        self.fetchedList.removeAll()
        self.filteredDisplayList.removeAll()
        self.fetchedUser.removeAll()
        self.filteredDisplayUser.removeAll()
        self.fetchItems()
        self.tableView.refreshControl?.endRefreshing()
        self.tableView.reloadData()

    }

    @objc func refreshAll(){
        print("DiscoverController | Refresh All")
        self.searchBar.text == ""
        self.isFiltering = false
        self.refreshItems()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //        self.setupLists()
    }
    
    func sortLists(){
        Database.sortList(inputList: self.fetchedList, sortInput: self.selectedSort, completion: { (sortedList) in
            self.fetchedList = sortedList
            self.tableView.reloadData()
        })
    }
    
    // SOMETHING IS WRONG HERE
    
    func displayLists(lists: [List]?){
        
        print("TabList | Displaying \(lists?.count) Lists")
        
        //        if let lists = lists {
        //            self.displayList = lists
        //            self.tableView.reloadData()
        //        }
        
        
        guard let lists = lists else {
            self.fetchedList = []
            self.tableView.reloadData()
            print("TabListViewController | Error | No Lists To Display")
            return
        }
        
        Database.sortList(inputList: lists, sortInput: self.selectedSort, completion: { (sortedList) in
            self.fetchedList = sortedList
            self.tableView.reloadData()
        }
        )
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
        
        if self.fetchType == DiscoverList {
            return filteredDisplayList.count
        } else if self.fetchType == DiscoverUser {
            return filteredDisplayUser.count
        } else {
            return 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if self.fetchType == DiscoverList {
            let cell = tableView.dequeueReusableCell(withIdentifier: newCellId, for: indexPath) as! UserAndListCell
            let currentList = isFiltering ? filteredDisplayList[indexPath.row] : fetchedList[indexPath.row]
            cell.list = currentList

            
//            cell.list = currentList
//            cell.list?.newNotificationsCount = 0
//            cell.isSelected = false
//            cell.enableSelection = false
//            cell.refUser = CurrentUser.user
//            cell.backgroundColor = UIColor.white
//            cell.hideProfileImage = true
//            cell.delegate = self
//            cell.selectionStyle = .none

            return cell
        } else if self.fetchType == DiscoverUser {
            let cell = tableView.dequeueReusableCell(withIdentifier: newCellId, for: indexPath) as! UserAndListCell
            let currentUser = isFiltering ? filteredDisplayUser[indexPath.row] : fetchedUser[indexPath.row]
            cell.user = currentUser
            cell.selectionStyle = .none

//            cell.user = currentUser
//            cell.isSelected =  false
//            cell.delegate = self
//            cell.selectionStyle = .none

            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: listCellId, for: indexPath) as! DiscoverListCellNew
            cell.selectionStyle = .none

            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if self.fetchType == DiscoverList {
            
            let selectedList = self.isFiltering ? filteredDisplayList[indexPath.row] : fetchedList[indexPath.row]
            self.extTapList(list: selectedList)
//            self.goToList(list: selectedList, filter: nil)
            tableView.deselectRow(at: indexPath, animated: false)
            
            

        } else if self.fetchType == DiscoverUser {
            
            let selectedUser = self.isFiltering ? filteredDisplayUser[indexPath.row] : fetchedUser[indexPath.row]
            self.extTapUser(userId: selectedUser.uid)
//            self.goToUser(userId: selectedUser.uid)
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
