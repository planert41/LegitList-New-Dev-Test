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

@objc protocol PostSocialDisplayTableViewControllerDelegate {
    func filterControllerFinished(selectedCaption: String?, selectedRange: String?, selectedLocation: CLLocation?, selectedLocationName: String?, selectedGooglePlaceId: String?, selectedGooglePlaceType: [String]?, selectedMinRating: Double, selectedType: String?, selectedMaxPrice: String?, selectedSort: String, selectedLegit: Bool)
    
    //    func filterCaptionSelected(searchedText: String?)
    @objc optional func userSelected(uid: String?)
    @objc optional func locationSelected(googlePlaceId: String?, googlePlaceName: String?, googlePlaceLocation: CLLocation?, googlePlaceType: [String]?)
}


class PostSocialDisplayTableViewController : UITableViewController, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate, DiscoverListCellNewDelegate, ListViewControllerDelegate, DiscoverUserCellDelegate {

    
    
 
    let UserCellId = "UserCellId"
    let ListCellId = "ListCellId"
    
    var scopeBarOptions:[String] = FriendSortOptions {
        didSet {
            if scopeBarOptions.count > 1 {
                self.searchBar.scopeButtonTitles = scopeBarOptions
            }
        }
    }
    
    // 1. Show Lists that pinned input Post
    // 2. Show Users that like input Post
    
    var inputPost: Post? {
        didSet {
            if displayList {
                self.fetchPostAllLists()
            } else if displayUser {
                self.fetchPostAllUsers()
            }
        }
    }
    
    var inputList: List? {
        didSet {
            guard let inputList = inputList else {return}
            if inputList.followerCount > 0 && inputList.followers?.count == 0 {
                print("PostSocialDisplayTableViewController | Fetching List Followers \(inputList.id) | \(inputList.followerCount)")
                Database.checkListForFollowers(list: inputList) { (tempList) in
                    self.inputList = tempList
                }
            }
            
            if displayUser {
                self.fetchListFollowingUsers()
            }
        }
    }

    // 3. Show Following/Followers of input User

    var inputUser: User? {
        didSet {
            if displayUser {
                if self.displayAllUsers {
                    self.fetchAllUsers()
                } else {
                    self.fetchUserAllFollowingFollowers()
                }
            }
        }
    }

    var displayList: Bool = false {
        didSet{
            if self.displayUser == self.displayList{
                self.displayUser = !self.displayList
            }
            setupNavigationItems()
        }
    }
    
    var displayUser: Bool = false {
        didSet{
            if self.displayUser == self.displayList{
                self.displayList = !self.displayUser
            }
            setupNavigationItems()
        }
    }
    
    var displayAllUsers:Bool = false
    
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
    
    var otherUsers = [User]()
    var followingUsers = [User]()
    var filteredUsers = [User]()
    
    var allLists = [List]()
    var followingLists = [List]()
    var filteredList = [List]()

    
    
    let searchController = UISearchController(searchResultsController: nil)
    var searchBar = UISearchBar()
    
    func fetchAllUsers(){
        
        guard let uid = inputUser?.uid else {
            print("PostSocialDisplayTVC | fetchAllUsers ERROR | No UID")
            return
        }
        
        self.otherUsers.removeAll()
        self.followingUsers.removeAll()
        
        Database.fetchFollowingUserUids(uid: uid) { (fetchedUids) in
            let followingUserId = fetchedUids
            
            Database.fetchALLUsers { (fetchedUsers) in
                for user in fetchedUsers {
                    if  followingUserId.contains(user.uid) {
                        var tempUser = user
                        tempUser.isFollowing = true
                        self.followingUsers.append(tempUser)
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
                self.searchBar.scopeButtonTitles = ["Following", "Other Users"]

                self.tableView.reloadData()
            }
        }
        

    }
    
    func fetchUserAllFollowingFollowers(){
        self.otherUsers.removeAll()
        self.followingUsers.removeAll()
        
        var followingUserId: [String] = []
        var followerUserId: [String] = []
        
        guard let uid = inputUser?.uid else {
            print("PostSocialDisplayTVC | FetchFollowingUser ERROR | No UID")
            return
        }
        
        let dispatchGroup = DispatchGroup()
        
        // Fetch Follower Users
        dispatchGroup.enter()
        Database.fetchFollowerUserUids(uid: uid) { (fetchedUids) in
            dispatchGroup.leave()
            followerUserId = fetchedUids
        }
        
        dispatchGroup.enter()
        Database.fetchFollowingUserUids(uid: uid) { (fetchedUids) in
            dispatchGroup.leave()
            followingUserId = fetchedUids
        }
        
        dispatchGroup.notify(queue: .main) {
            var allIds = followingUserId + followerUserId
            let fetchGroup = DispatchGroup()
            print("PostSocialDisplayTVC | Fetching Users | UID \(self.inputUser?.uid) | \(followingUserId.count) Following | \(followerUserId.count) Follower")
            
            for id in followingUserId{
                fetchGroup.enter()
                Database.fetchUserWithUID(uid: id, completion: { (fetchedUser) in
                    if let fetchedUser = fetchedUser {
                        self.followingUsers.append(fetchedUser)
                    }  else {
                        print("PostSocialDisplayTVC | FetchFollowingUser ERROR | No Following User Fetched | UID \(id)")
                    }
                    fetchGroup.leave()

                })
            }
            
            for id in followerUserId{
                fetchGroup.enter()

                Database.fetchUserWithUID(uid: id, completion: { (fetchedUser) in
                    if let fetchedUser = fetchedUser {
                        self.otherUsers.append(fetchedUser)
                    }  else {
                        print("PostSocialDisplayTVC | FetchFollowingUser ERROR | No Follower User Fetched | UID \(id)")
                    }
                    fetchGroup.leave()

                })
            }
        
            fetchGroup.notify(queue: .main) {
                print("Following \(self.followingUsers.count) | Follower \(self.otherUsers.count) Users ")
//                self.searchBar.scopeButtonTitles = ["Following (\(self.followingUsers.count))", "Follower (\(self.otherUsers.count))"]
                
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = .center
                self.searchBar.setScopeBarButtonTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
                self.searchBar.setScopeBarButtonTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)

                
                self.searchBar.scopeButtonTitles = ["Following", "Follower"]
                self.updateSearchBarCount()


                self.otherUsers = self.otherUsers.sorted(by: { (u1, u2) -> Bool in
                    u1.followersCount > u2.followersCount
                })
                
                self.followingUsers = self.followingUsers.sorted(by: { (u1, u2) -> Bool in
                    u1.followersCount > u2.followersCount
                })
                
                self.tableView.reloadData()
                
                // Check User Social Stats
                if self.inputUser?.followersCount != followerUserId.count {
                    print("PostSocialDisplayTVC | User Social Check | Need To update Follower Count for \(self.inputUser?.uid) | Old \(self.inputUser?.followersCount) | New \(followerUserId.count)")
                    Database.spotUpdateSocialCountForUserFinal(creatorUid: self.inputUser?.uid, socialField: "followerCount", final: followerUserId.count)
                }
                
                if self.inputUser?.followingCount != followingUserId.count {
                    print("PostSocialDisplayTVC | User Social Check | Need To update Following Count for \(self.inputUser?.uid) | Old \(self.inputUser?.followingCount) | New \(followingUserId.count)")
                    Database.spotUpdateSocialCountForUserFinal(creatorUid: self.inputUser?.uid, socialField: "followingCount", final: followingUserId.count)
                }
                
            }
        }
    }

    func displayUsers(){
        
    }
    
    
    func fetchListFollowingUsers(){
        self.otherUsers.removeAll()
        self.followingUsers.removeAll()
        let myGroup = DispatchGroup()
        
        for (uid,value) in (self.inputList?.followers)! {
            myGroup.enter()
            Database.fetchUserWithUID(uid: uid) { (user) in
                if user != nil {
                    if (user?.isFollowing) ?? false{
                        self.followingUsers.append(user!)
                    } else {
                        self.otherUsers.append(user!)
                    }
                }

                myGroup.leave()
            }
        }
        
        myGroup.notify(queue: .main) {
            print("List Followed By \(self.followingUsers.count) | Fetched \(self.otherUsers.count) Users ")
            
//            self.searchBar.scopeButtonTitles = ["Following (\(self.followingUsers.count))", "Other (\(self.otherUsers.count))"]
            self.otherUsers = self.otherUsers.sorted(by: { (u1, u2) -> Bool in
                u1.followersCount > u2.followersCount
            })
            
            self.followingUsers = self.followingUsers.sorted(by: { (u1, u2) -> Bool in
                u1.followersCount > u2.followersCount
            })
            self.updateSearchBarCount()

            
            self.tableView.reloadData()
        }
    }
    
    
    
    
    func fetchPostAllUsers(){
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
            
            self.tableView.reloadData()
            self.updateSearchBarCount()

        }
    }
    
    func fetchPostAllLists(){
        self.allLists.removeAll()
        self.followingLists.removeAll()

        let myGroup = DispatchGroup()
        for (key,value) in (self.inputPost?.allList)! {
            myGroup.enter()
            Database.fetchListforSingleListId(listId: key) { (list) in

                if let list = list {

                    if CurrentUser.followingUids.contains((list.creatorUID)!){
                        self.followingLists.append(list)
                    } else {
                        self.allLists.append(list)
                    }
                    
//                    self.otherLists.append(list)

                    
                } else {
                    print("PostSocialDisplayTableView | ERROR | No List Found for \(key) | Remove Post From List \(key)")
                    Database.DeletePostForList(postId: (self.inputPost?.id)!, postCreatorUid: (self.inputPost?.creatorUID)!, listId: key, postCreationDate: self.inputPost?.creationDate.timeIntervalSince1970)
                }

                myGroup.leave()
            }
        }
        
        myGroup.notify(queue: .main) {
            print("Fetched \(self.allLists.count) Lists | Following \(self.followingLists.count)")
            //self.searchBar.scopeButtonTitles = ["Following (\(self.followingLists.count))", "Other (\(self.otherLists.count))"]
            
//            self.searchBar.scopeButtonTitles = ["Followed Users Lists", "All Lists"]
            self.searchBar.scopeButtonTitles = ["Following", "Other"]

            self.allLists.sort(by: { (l1, l2) -> Bool in
                l1.totalCred > l2.totalCred
            })
            self.followingLists.sort(by: { (l1, l2) -> Bool in
                l1.totalCred > l2.totalCred
            })
            
            var tempList: [List] = []
            
            // POST CREATOR LISTS FIRST
            for list in self.allLists {
                if list.creatorUID == self.inputPost?.creatorUID {
                    if !tempList.contains(where: {$0.id == list.id}){
                        tempList.append(list)
                    }
                }
            }
            
            // CURRENT USER LIST 2nd
            for list in self.allLists {
                if list.creatorUID == Auth.auth().currentUser?.uid {
                    if !tempList.contains(where: {$0.id == list.id}){
                        tempList.append(list)
                    }
                }
            }
            
            // OTHER LISTS
            for list in self.allLists {
                if !tempList.contains(where: {$0.id == list.id}){
                    tempList.append(list)
                }
            }
            
            self.tableView.reloadData()
            self.updateSearchBarCount()
        }
    }
    
    
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
    
    @objc func handleBackPressNav(){
        self.handleBack()
    }
    
    func setupTableView(){
        tableView.backgroundColor = UIColor.white
        tableView.register(DiscoverUserCell.self, forCellReuseIdentifier: UserCellId)
        //        tableView.register(TestListCell.self, forCellReuseIdentifier: ListCellId)
        tableView.register(DiscoverListCellNew.self, forCellReuseIdentifier: ListCellId)
        tableView.estimatedRowHeight = 200
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.alwaysBounceVertical = true
        let adjustForTabbarInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
        tableView.contentInset = adjustForTabbarInsets
        tableView.scrollIndicatorInsets = adjustForTabbarInsets

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
    
    func selectUserFollowers(user: User?) {
        guard let user = user else {return}
        print("Display Follower User| ",user.uid)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayUser = true
        postSocialController.displayFollowing = false
        postSocialController.inputUser = user
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    
    func listSelected(list: List?) {
        self.goToList(list: list, filter: nil)
    }
    
    func deleteList(list: List?) {
        guard let list = list else {return}
        guard let listId = list.id else {return}
        
        print("TabListViewController | Deleting List \(list.id) from view")
        
        
        if self.selectedScope == 0 {
            if let deleteIndex = self.followingLists.firstIndex(where: {$0.id == listId}) {
                self.followingLists.remove(at: deleteIndex)
            }
        } else {
            if let deleteIndex = self.allLists.firstIndex(where: {$0.id == listId}) {
                self.allLists.remove(at: deleteIndex)
            }
        }
        
        
        if let deleteIndex = self.filteredList.firstIndex(where: {$0.id == listId}) {
            self.filteredList.remove(at: deleteIndex)
        }
        
        self.tableView.reloadData()
        
    }
    
    
    func goToList(list: List?, filter: String?) {
        
        guard let list = list else {return}
        let listViewController = ListViewController()
        listViewController.currentDisplayList = list
        listViewController.viewFilter?.filterCaption = filter
        listViewController.refreshPostsForFilter()
        listViewController.delegate = self
        print("DiscoverController | goToList | \(list.name) | \(filter) | \(list.id)")
        
        self.navigationController?.pushViewController(listViewController, animated: true)
        
    }
    
    func goToPost(postId: String, ref_listId: String?, ref_userId: String?) {
        Database.fetchPostWithPostID(postId: postId) { (post, error) in
            if let error = error {
                print("goToPost \(error)")
            } else {
                guard let post = post else {
                    self.alert(title: "Sorry", message: "Post Does Not Exist Anymore 😭")
                    if let listId = ref_listId {
                        print("SocialUserListDisplay | No More Post. Refreshing List to Update | ",listId)
                        Database.refreshListItems(listId: listId)
                    }
                    
                    if let userId = ref_userId {
                        print("SocialUserListDisplay | No More Post. Refreshing User to Update | ",userId)
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
    
//    func goToPost(postId: String) {
//        Database.fetchPostWithPostID(postId: postId) { (post, error) in
//            if let error = error {
//                print("goToPost \(error)")
//            } else {
//                guard let post = post else {
//                    self.alert(title: "Sorry", message: "Post Does Not Exist Anymore 😭")
//                    return
//                }
//                let pictureController = SinglePostView()
//                pictureController.post = post
//                self.navigationController?.pushViewController(pictureController, animated: true)
//            }
//        }
//    }
    
    func displayListFollowingUsers(list: List, following: Bool) {
        print("Display Users| Following: ",list.id)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayUser = true
        postSocialController.displayFollowing = false
        postSocialController.inputList = list
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    func refreshAll() {
        
    }
    
    func goToUser(userId: String?) {
        guard let userId = userId else {return}
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = userId
        self.navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    
    
    
    func setupNavigationItems(){
        
    // Header

        
//        self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.ianLegitColor(), NSAttributedString.Key.font.rawValue: UIFont(name: "Poppins-Bold", size: 18)])
        var titleString = self.displayList ? "Lists" : (self.displayUser ? "Users" : "" )
        
        let navLabel = UILabel()
        let customFont = UIFont(name: "Poppins-Bold", size: 18)
        let headerTitle = NSAttributedString(string:titleString, attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: customFont])
        navLabel.attributedText = headerTitle
        self.navigationItem.titleView = navLabel
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = UIColor.ianLegitColor()
        self.navigationController?.navigationBar.tintColor = UIColor.ianLegitColor()

        self.navigationController?.navigationBar.backgroundColor = UIColor.ianLegitColor()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)

        self.navigationController?.navigationBar.layoutIfNeeded()
        self.setNeedsStatusBarAppearanceUpdate()

        
    // Nav Back Buttons
        let navBackButton = navBackButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        navBackButton.tintColor = UIColor.white
        navBackButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
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

    func updateSearchBarCount(){
        
        if self.displayList {
            self.followingCount = self.followingLists.count
            self.otherCount = self.allLists.count
        } else if self.displayUser {
            self.followingCount = self.followingUsers.count
            self.otherCount = self.otherUsers.count
        }

        let followString = self.followingCount > 0 ? " : \(String(self.followingCount))" : ""
        let otherString = self.otherCount > 0 ? " : \(String(self.otherCount))" : ""

//        searchBar.scopeButtonTitles = ["\(scopeBarOptions[0]) \(followString)","\(scopeBarOptions[1]) \(otherString)"]
        if self.displayUser {
            searchBar.scopeButtonTitles = ["\(scopeBarOptions[0])\(followString)","\(scopeBarOptions[1])\(otherString)"]
        } else if self.displayList {
            searchBar.scopeButtonTitles = ["\(scopeBarOptions[0])\(followString)","\(scopeBarOptions[1])\(otherString)"]

//            searchBar.scopeButtonTitles = ["All Lists","Friends Lists"]
        }

    }
    
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
        searchBar.backgroundColor = UIColor.ianWhiteColor()
        
        definesPresentationContext = true
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        searchBar.setScopeBarButtonTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
        searchBar.setScopeBarButtonTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)
        
        formatSearchBar()

        
//        self.updateSearchBarCount()
//
//        for s in searchBar.subviews[0].subviews {
//            if s is UITextField {
//                s.layer.borderWidth = 0.5
//                s.layer.borderColor = UIColor.gray.cgColor
//                s.layer.cornerRadius = 10
//                s.clipsToBounds = true
//                s.layer.backgroundColor = UIColor.white.cgColor
//            }
//        }
//
        
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling  = false
//            searchBar.backgroundColor = UIColor.ianLegitColor()
//            searchBar.barTintColor = UIColor.white
            
        } else {
            self.tableView.tableHeaderView = searchBar
//            searchBar.backgroundColor = UIColor.ianLegitColor()
//            searchBar.barTintColor = UIColor.white
        }
        
    }
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

            // Users
        if self.displayUser{
            if isFiltering {
                return filteredUsers.count
            } else {
                if self.selectedScope == 0 {
                    return followingUsers.count
                } else{
                    return otherUsers.count
                }
            }
        }
        else if self.displayList {
            if isFiltering {
                return filteredList.count
            } else {
                if self.selectedScope == 0 {
//                    print("Follow | ",followingLists.count)
                    return followingLists.count
                } else{
//                    print("Other | ",otherLists.count)
                    return allLists.count
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
        if self.displayUser{
            let cell = tableView.dequeueReusableCell(withIdentifier: UserCellId, for: indexPath) as! DiscoverUserCell
            if isFiltering{
                cell.user = filteredUsers[indexPath.row]
            } else {
                if self.selectedScope == 0 {
                    var tempUser = followingUsers[indexPath.row]
                    tempUser.isFollowing = true
                    cell.user = tempUser
                } else {
                    cell.user = otherUsers[indexPath.row]
                }
            }
            
            cell.isSelected =  false
            cell.delegate = self
            cell.selectionStyle = .none
            return cell
        }
        
        // Lists
        else if self.displayList{
            let cell = tableView.dequeueReusableCell(withIdentifier: ListCellId, for: indexPath) as! DiscoverListCellNew

            
            
            if isFiltering{
                cell.list = filteredList[indexPath.row]
            } else {
                cell.list = self.selectedScope == 0 ? followingLists[indexPath.row] : allLists[indexPath.row]
            }
            cell.list?.newNotificationsCount = 0
            
            cell.isSelected = false
            cell.enableSelection = false
            cell.hideProfileImage = true
            cell.backgroundColor = UIColor.white
            cell.delegate = self
            cell.refUser = CurrentUser.user
            cell.selectionStyle = .none
            cell.refUser = CurrentUser.user

            return cell
        }
        
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: UserCellId, for: indexPath) as! DiscoverUserCell
            return cell
        }
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // User Selected
        if self.displayUser{
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
            self.displayUser(user: userSelected!)
        }

        else if self.displayList{
            var listSelected: List?
            if isFiltering{
                listSelected = filteredList[indexPath.row]
            } else {
                if self.selectedScope == 0 {
                    listSelected = followingLists[indexPath.row]
                } else {
                    listSelected = allLists[indexPath.row]
                }
            }
            self.displayList(list: listSelected)
        }
    }
    
    
    func filterContentForSearchText(_ searchText: String) {
        // Filter for Emojis and Users

            // Users
        if self.displayUser{
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
        
        else if self.displayList {
            if self.selectedScope == 0 {
                filteredList = self.followingLists.filter { (list) -> Bool in
                    return list.name.lowercased().contains(searchText.lowercased())
                }
            } else {
                filteredList = self.allLists.filter { (list) -> Bool in
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
    
    override func viewWillDisappear(_ animated: Bool) {
        //      Remove Searchbar scope during transition
        self.searchBar.isHidden = true
        //        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //      Show Searchbar scope during transition
        self.searchBar.isHidden = false
        self.searchBar.selectedScopeButtonIndex = self.selectedScope
        self.tableView.reloadData()
        //        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            self.formatSearchBar()
//            self.searchController.searchBar.becomeFirstResponder()
        }
    }
    
    func formatSearchBar() {
        if let textField = self.searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = UIColor.lightGray.withAlphaComponent(0.6)

            let backgroundView = textField.subviews.first
            if #available(iOS 11.0, *) { // If `searchController` is in `navigationItem`
                backgroundView?.backgroundColor = UIColor.lightGray.withAlphaComponent(0.6) //Or any transparent color that matches with the `navigationBar color`
                backgroundView?.subviews.forEach({ $0.removeFromSuperview() }) // Fixes an UI bug when searchBar appears or hides when scrolling
            }
            backgroundView?.layer.cornerRadius = 10.5
            backgroundView?.layer.masksToBounds = true
            //Continue changing more properties...
        }
        
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
        self.updateSearchBarCount()
        self.tableView.reloadData()
    }
    
    func displayList(list: List?){
        guard let list = list else{return}
        let listViewController = ListViewController()
        listViewController.imageCollectionView.collectionViewLayout = HomeSortFilterHeaderFlowLayout()
        listViewController.currentDisplayList = list
        self.navigationController?.pushViewController(listViewController, animated: true)
    }
    
    func displayUser(user: User?){
        guard let user = user else{return}
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = user.uid
        self.navigationController?.pushViewController(userProfileController, animated: true)
    }
    

    
    
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
