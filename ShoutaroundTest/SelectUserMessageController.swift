//
//  TabNotificationViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 6/19/20.
//  Copyright © 2020 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import GooglePlaces
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class SelectUserMessageController: UIViewController {

    let EventCellId = "EventCellId"
    let InboxCellId = "inboxCellId"
    let ThreadCellId = "threadCellId"
    let UserCellId = "userCellId"

// POST
    var sendingPost: Post? = nil
    
    var displayUserId:String? {
        didSet {
            print("TabNotificationViewController | Load ID | \(displayUserId) ")
            fetchUser()
        }
    }
    var displayUser: User? {
        didSet{
            print("TabNotificationViewController | Load User | \(displayUserId)")
//            fetchUserEvents()
            fetchUserMessageThreads()
            fetchFollowingUsers()
            setupNavigationItems()
        }
    }
    
    
// USER MESSAGES
    
    
    var messageThreads: [MessageThread] = CurrentUser.inboxThreads{
        didSet{
//            self.updateCounts()
        }
    }
    var filteredMessageThreads: [MessageThread] = []
    var unReadMessageCount = 0 {
        didSet {
            setScopeBarOptions()
        }
    }
    
// FRIENDS
    var followingUsers = [User]()
    var filteredUsers = [User]()

// SEARCH AND NAV
    
    let searchController = UISearchController(searchResultsController: nil)
    var searchBar = UISearchBar()
    var searchTerm: String? = nil
    var isFiltering: Bool = false {
        didSet{
            // Reloads tableview when stops filtering
            self.tableView.reloadData()
        }
    }
    
    // 0 - Notifications | 1 - Inbox
    var selectedScope = 0 {
        didSet{
            self.searchBar.selectedScopeButtonIndex = self.selectedScope
            self.tableView.reloadData()
            print("Selected | \(scopeBarOptions[selectedScope]) | \(followingUsers.count) Users | \(messageThreads.count) Messages")
        }
    }
    
    var scopeBarOptions:[String] = ["Users", "Messages"] {
        didSet {
            setScopeBarOptions()
        }
    }
    
    func setScopeBarOptions() {
//        var scopeText: [String] = []
//        var notificationText = (self.unReadEventCount > 0) ? "Notifications (\(self.unReadEventCount))" : "Notifications"
//        scopeText.append(notificationText)
//        var messageText = (self.unReadMessageCount > 0) ? "Messages (\(self.unReadMessageCount))" : "Messages"
//        scopeText.append(messageText)
        self.searchBar.scopeButtonTitles = scopeBarOptions
    }
    
    
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

    
    // NAV BUTTONS
    lazy var navBackButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        let icon = #imageLiteral(resourceName: "back_icon").withRenderingMode(.alwaysTemplate)
        button.setImage(icon, for: .normal)
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.borderColor = UIColor.ianLegitColor().cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 2
        button.clipsToBounds = true
        button.contentHorizontalAlignment = .center
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        button.tintColor = UIColor.ianBlackColor()
        button.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
        return button
    }()
    
    
    lazy var tableView : UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        tv.estimatedRowHeight = 100
        tv.allowsMultipleSelection = false
        return tv
    }()
    
    
    lazy var navMessageButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//        let icon = #imageLiteral(resourceName: "share").withRenderingMode(.alwaysTemplate)
        let icon = #imageLiteral(resourceName: "message_fill").withRenderingMode(.alwaysTemplate)

        button.setImage(icon, for: .normal)
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.borderColor = UIColor.ianLegitColor().cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 2
        button.clipsToBounds = true
        button.contentHorizontalAlignment = .center
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        button.tintColor = UIColor.ianBlackColor()
        button.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationItems()
        setupTableView()
        setupSearchController()
        self.view.backgroundColor = UIColor.white
        view.addSubview(tableView)
        tableView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        fetchUserMessageThreads()
        
        setScopeBarOptions()
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAll), name: MainTabBarController.NewNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(fetchNewMessage), name: MainTabBarController.NewMessageName, object: nil)
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupNavigationItems()
        self.view.layoutIfNeeded()
        self.tableView.reloadData()
    }
    
    func setupNavigationItems() {
        let tempImage = UIImage.init(color: UIColor.white)
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.barTintColor = UIColor.white
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.view.backgroundColor = UIColor.white
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.layoutIfNeeded()
        self.setNeedsStatusBarAppearanceUpdate()
        
// HEADER
        let navHeaderTitle = UILabel()
        let headerTitle = NSMutableAttributedString()

        headerTitle.append(NSAttributedString(string:"Message", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 16)]))
        
        navHeaderTitle.attributedText = headerTitle
        navigationItem.titleView = navHeaderTitle
        
        
// RIGHT BAR BUTTON - FRIENDS
//        navFriendButton.addTarget(self, action: #selector(openFriends), for: .touchUpInside)
//        let friendButton = UIBarButtonItem.init(customView: navFriendButton)
//        navigationItem.rightBarButtonItem = friendButton
        
 // RIGHT BAR BUTTON - CLEAR ALL
        navBackButton.addTarget(self, action: #selector(handleBackPressNav), for: .touchUpInside)
        let backBarButton = UIBarButtonItem.init(customView: navBackButton)
        navigationItem.leftBarButtonItem = backBarButton

//        navMessageButton.addTarget(self, action: #selector(didTapMessage), for: .touchUpInside)
//        let msgButton = UIBarButtonItem.init(customView: navMessageButton)
//        navigationItem.rightBarButtonItem = msgButton
        
    }

    
    @objc func handleBackPressNav(){
        self.handleBack()
    }
    
    @objc func didTapMessage() {
        print("Send Message")
        let messageController = MessageController()
        messageController.post = nil
        self.navigationController?.present(messageController, animated: true, completion: {
            
        })
//        if let m = self.navigationController {
//            self.navigationController?.pushViewController(messageController, animated: true)
//        }
    }
    
    @objc func openFriends(){
        print("Display Friends For Current User| ",CurrentUser.user?.uid)
        self.extShowUserFollowers(inputUser: self.displayUser)

//        let postSocialController = PostSocialDisplayTableViewController()
//        postSocialController.displayAllUsers = true
//        postSocialController.displayUserFollowing = true
//        postSocialController.displayUser = true
//        postSocialController.inputUser = CurrentUser.user
//        navigationController?.pushViewController(postSocialController, animated: true)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension SelectUserMessageController: UISearchResultsUpdating, UISearchBarDelegate {
       
    func fetchUser(){
        guard let uid = displayUserId else {
            print("User Profile: Fetch Posts Error, No UID")
            return
        }
        
        Database.fetchUserWithUID(uid: uid) { (fetchedUser) in
            self.displayUser = fetchedUser
            print("TabNoticiationView | Fetched User | \(uid)")
        }
    }

    
    func fetchUserMessageThreads(){
        guard let uid = self.displayUser?.uid else {return}

        Database.fetchMessageThreadsForUID(userUID: uid) { (messageThreads) in
            
            var tempMsg = messageThreads.sorted(by: { (event1, event2) -> Bool in
                
                if event1.isRead == event2.isRead {
                    return event1.lastMessageDate.compare(event2.lastMessageDate) == .orderedDescending
                } else {
                    return (event1.isRead ? 1 : 0) > (event2.isRead ? 1 : 0)
                }
                
            })
            
            
            self.messageThreads = tempMsg
            self.tableView.reloadData()
        }
    }
    
    @objc func fetchNewMessage() {
        print("TabNotification | Fetch New Msg | Trigger")
        
        var tempMsg = CurrentUser.inboxThreads.sorted(by: { (event1, event2) -> Bool in
            if event1.isRead == event2.isRead {
                return event1.lastMessageDate.compare(event2.lastMessageDate) == .orderedDescending
            } else {
                return (event1.isRead ? 1 : 0) >= (event2.isRead ? 1 : 0)
            }
        })
        
        self.messageThreads = tempMsg
        self.tableView.reloadData()
    }
    
    
    func fetchFollowingUsers() {
        guard let uid = displayUser?.uid else {return}
        
        followingUsers = []
        filteredUsers = []
        
        if CurrentUser.followingUsers.count == 0 {
            Database.fetchFollowingUsers(uid: uid) { (users) in
                var tempUsers = users.sorted { (p1, p2) -> Bool in
                    return p1.posts_created >= p2.posts_created
                }
                self.followingUsers = tempUsers
            }
        } else {
            self.followingUsers = CurrentUser.followingUsers
        }
    }

    
    @objc func refreshAll() {
        if selectedScope == 0 {
            self.fetchFollowingUsers()
        } else {
            self.fetchUserMessageThreads()
        }
        self.tableView.refreshControl?.endRefreshing()
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
        searchBar.showsCancelButton = false

        definesPresentationContext = true

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
//        searchBar.scopeBarBackgroundImage = UIImage.imageWithColor(color: UIColor.blue)

        for subview in searchBar.subviews {
            if subview is UISegmentedControl {
                subview.tintColor = UIColor.mainBlue()
            }
        }
        
    // SCOPE BAR BUTTONS
        if #available(iOS 13.0, *) {
//            searchBar.selectedSegmentTintColor = UIColor.ianLegitColor()
        }
        
        let selectedImage = UIImage(color: UIColor.ianLegitColor())
        
        searchBar.setScopeBarButtonBackgroundImage(selectedImage, for: .selected)
        
        searchBar.setScopeBarButtonTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)
        searchBar.setScopeBarButtonTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
        

        UISegmentedControl.appearance().tintColor = UIColor.ianLegitColor()
        
        if let textField = self.searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = UIColor.lightGray.withAlphaComponent(0.6)
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
    
    func filterContentForSearchText(_ searchText: String) {
        // Filter for Emojis and Users
        var search = searchText.lowercased()
        
        filteredUsers = self.followingUsers.filter({ (user) -> Bool in
            return user.username.contains(search)
        })
        
        filteredMessageThreads = self.messageThreads.filter({ (messageThread) -> Bool in
            
            var creatorName = ""
            var users:[String] = []
            
            creatorName = (userCache[messageThread.creatorUID]?.username ?? "").lowercased()
            
            for user in messageThread.threadUsers {
                users.append(user.lowercased())
            }
            
            return creatorName.contains(search) || users.contains(search)
            
        })
        
        
        self.tableView.reloadData()
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
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        print("Selected Scope is: ", selectedScope)
        self.selectedScope = selectedScope
        self.tableView.reloadData()
    }
    
    
}

extension SelectUserMessageController: UITableViewDelegate, UITableViewDataSource, ThreadCellDelegate, MessageThreadCellDelegate {
    func saveInteraction(event: Event?) {
        print("saveInteraction | SelectUserMsgController")
    }
    
    func saveMessageRead(messageThread: MessageThread) {
        print("saveMessageRead | SelectUserMsgController")
    }
    
    
    func refreshPost(post: Post) {
        postCache.removeValue(forKey: post.id!)
        postCache[post.id!] = post
    }
    
    func didTapPicture(post: Post) {
        self.extTapPicture(post: post)
    }
    
    

    func setupTableView(){
        tableView.backgroundColor = UIColor.white
        tableView.register(EventCell.self, forCellReuseIdentifier: EventCellId)
        tableView.register(MessageThreadCell.self, forCellReuseIdentifier: ThreadCellId)
        tableView.register(UserAndListCell.self, forCellReuseIdentifier: UserCellId)

        
        
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.alwaysBounceVertical = true
        tableView.separatorStyle = .none
        let adjustForTabbarInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
        tableView.contentInset = adjustForTabbarInsets
        tableView.scrollIndicatorInsets = adjustForTabbarInsets
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshAll), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.alwaysBounceVertical = true
        tableView.keyboardDismissMode = .onDrag
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if selectedScope == 0 {
            return isFiltering ? filteredUsers.count : followingUsers.count
        } else {
            return isFiltering ? filteredMessageThreads.count : messageThreads.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if self.selectedScope == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: UserCellId, for: indexPath) as! UserAndListCell
            let row = indexPath.row
            
            if row == 0 {
                cell.altText = "Email"
            } else {
                let user = self.isFiltering ? filteredUsers[row - 1] : followingUsers[row - 1]
                cell.user = user
                cell.altText = nil
                cell.followButton.isHidden = true
            }
            return cell
        } else {
6
            var displayMessage =  self.isFiltering ? filteredMessageThreads[indexPath.row] : messageThreads[indexPath.row]
                    
            let cell = tableView.dequeueReusableCell(withIdentifier: ThreadCellId, for: indexPath) as! MessageThreadCell
//            cell.delegate = self
//            print("Displayed Message Thread", displayMessage.threadID, displayMessage.creatorUID, displayMessage.threadUserDic)
            cell.messageThread = displayMessage
            cell.selectionStyle = .none
            cell.delegate = self
            return cell
            
            
            
        }

    
    
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (self.selectedScope == 0 && indexPath.row == 0) {
            return 65
        } else {
            return (self.selectedScope == 0) ? 80 : 80
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    // NOTIFICATION
        if self.selectedScope == 0 {
            let messageController = MessageController()
            messageController.post = sendingPost
            if indexPath.row == 0 {
                print("Send Email")
            } else {
                let user = self.isFiltering ? filteredUsers[indexPath.row - 1] : followingUsers[indexPath.row - 1]
                messageController.respondUser = [user]
                print("Send Message To User")
            }

            if let m = self.navigationController {
                self.navigationController?.pushViewController(messageController, animated: true)
            }
            
        }
    // MESSAGE
        else {
            var displayMessage =  self.isFiltering ? filteredMessageThreads[indexPath.row] : messageThreads[indexPath.row]
            let user = self.isFiltering ? filteredUsers[indexPath.row] : followingUsers[indexPath.row]
            print("Send Message To Message Tgread")
            let messageController = MessageController()
            messageController.post = sendingPost
            messageController.respondMessage = displayMessage
            if let m = self.navigationController {
                self.navigationController?.pushViewController(messageController, animated: true)
            }
//            self.extOpenMessage(message: displayMessage, reload: true)
        }
    }
    
    func didTapUsername(user: User?) {
        guard let uid = user?.uid else {return}
        self.extTapUserUid(uid: uid, displayBack: true)
    }
    
    func didTapListname(listId: String?) {
        guard let listId = listId else {return}
        self.extTapListId(listId: listId)
    }
    
    func showPost(post: Post?) {
        guard let post = post else {return}
        self.extTapPicture(post: post)
    }
    


}
