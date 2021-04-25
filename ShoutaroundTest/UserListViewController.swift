//
//  UserListViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/6/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import FBSDKLoginKit


protocol UserListViewControllerDelegate {
    func userListSelected(user: User?)
}

class UserListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate, MainUserProfileViewDelegate {
    
    
    var delegate: UserListViewControllerDelegate?
    
    // USER PROFILE
    
    var displayUser: User? = nil {
        didSet{
            if let _ = displayUser {
                print("MainListView User |\(displayUser?.username)")
                self.userProfileView.user = self.displayUser
                self.fetchAllUsers()
            }
        }
    }
    
    
    func fetchAllUsers(){
        self.allUsers = []
        // Load Users
        Database.fetchALLUsers { (fetchedUsers) in
            self.allUsers = fetchedUsers.sorted(by: { (p1, p2) -> Bool in
                p1.votes_received > p2.votes_received
            })

            self.allFollowingUsers = self.allUsers.filter({ (user) -> Bool in
                user.isFollowing!
            })
            print("Following Users | \(self.allFollowingUsers.count)")

            self.filteredUsers = self.allUsers
            self.updateScopeBarCount()
            self.userTableView.reloadData()
        }
    }
    
    // Users
    var selectedUser: User? = nil
    let UserCellId = "UserCellId"
    var allUsers = [User]()
    var allFollowingUsers = [User]()
    var filteredUsers = [User]()
    
    var tableEdit: Bool = false
    
    lazy var userTableView : UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        tv.estimatedRowHeight = 140
        tv.allowsMultipleSelection = false
        return tv
    }()
    
    
//    let searchController = CustomSearchController(searchResultsController: nil)
    
    var searchController: UISearchController = ({
        let controller = CustomSearchController(searchResultsController: nil)
        controller.hidesNavigationBarDuringPresentation = false
        controller.dimsBackgroundDuringPresentation = false
        controller.searchBar.searchBarStyle = .minimal
        controller.searchBar.sizeToFit()
        return controller
    })()
    
    
    var searchBar = UISearchBar()
    var searchScopeButtons = ["Following", "All"]
    
    var isFiltering: Bool = false {
        didSet{
            self.userTableView.reloadData()
        }
    }
    
    // USER PROFILE ITEMS
    
    lazy var userProfileView : MainUserProfileView = {
        let view = MainUserProfileView()
        view.delegate = self
        return view
    }()
    
    // EMOJI DETAIL LABEL
    
    let emojiDetailLabel: PaddedUILabel = {
        let label = PaddedUILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 25)
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.rgb(red: 255, green: 242, blue: 230)
        label.layer.cornerRadius = 30/2
        label.layer.borderWidth = 0.25
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.masksToBounds = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationItems()
        setupViews()
        setupSearchController()
        setupTableView()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.setupNavigationItems()
    }
    
    
    func setupNavigationItems(){
//        let tempImage = UIImage.init(color: UIColor.legitColor())
//        self.navigationController?.navigationBar.setBackgroundImage(tempImage, for: .default)
        self.navigationController?.view.backgroundColor = UIColor.legitColor()
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.white, NSAttributedString.Key.font.rawValue: UIFont(font: .noteworthyBold, size: 20)])
        self.navigationItem.title = "Filter For User"
        self.navigationController?.navigationBar.layoutIfNeeded()


//        if displayUser?.uid == Auth.auth().currentUser?.uid {
//            navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "signout").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleLogOut))
//        }
//
        
//        self.navigationController?.navigationBar.isTranslucent = false
        
//        let tempImage = UIImage.init(color: UIColor.legitColor())
//        self.navigationController?.navigationBar.setBackgroundImage(tempImage, for: .default)
//        self.navigationController?.view.backgroundColor = UIColor.legitColor()
//
//        self.navigationController?.navigationBar.tintColor = UIColor.white
//        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        
//        let tempImage = UIImage.init(color: UIColor.legitColor())
//        self.navigationController?.navigationBar.setBackgroundImage(tempImage, for: .default)
//        self.navigationController?.navigationBar.isTranslucent = false
//        self.navigationController?.view.backgroundColor = UIColor.legitColor()
//        self.navigationController?.navigationBar.shadowImage = UIImage()
//        self.navigationItem.title = "Users"
////        self.navigationController?.navigationBar.layoutIfNeeded()
//
//        self.navigationController?.navigationBar.tintColor = UIColor.white
//        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont(font: .noteworthyBold, size: 20)]



        
        
        
        
        
//        let tempImage = UIImage.init(color: UIColor.legitColor())
//        self.navigationController?.navigationBar.setBackgroundImage(tempImage, for: .default)
//        self.navigationController?.navigationBar.tintColor = UIColor.white
//
//        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont(font: .noteworthyBold, size: 20)]
//
//        self.navigationItem.title = "Users"
//        self.navigationController?.navigationBar.layoutIfNeeded()
//        self.view.layoutIfNeeded()

    }
    
    
    override func viewDidLayoutSubviews() {
        self.searchController.searchBar.sizeToFit()
    }
    
    func handleLogOut() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { (_) in
            
            do {
                
                if Auth.auth().currentUser?.isAnonymous == true {
                    let user = Auth.auth().currentUser
                    user?.delete { error in
                        if let error = error {
                            print("Error Deleting Guest User")
                        } else {
                            print("Guest User Deleted")
                        }
                    }
                }
                
                try Auth.auth().signOut()
                CurrentUser.clear()
                let manager = LoginManager()
                try manager.logOut()
                let loginController = LoginController()
                let navController = UINavigationController( rootViewController: loginController)
                self.navigationController?.popToRootViewController(animated: true)
                self.present(navController, animated: true, completion: nil)

//                self.dismiss(animated: true, completion: {
//                    self.present(navController, animated: true, completion: nil)
//                })
//                self.present(loginController, animated: true, completion: nil)
                
            } catch let signOutErr {
                print("Failed to sign out:", signOutErr)
            }
            
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func setupViews(){
        // USER PROFILE VIEW
        view.addSubview(userProfileView)
        userProfileView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 100)
        
        // TABLEVIEW
        view.addSubview(userTableView)
        userTableView.anchor(top: userProfileView.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        view.addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top:topLayoutGuide.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        emojiDetailLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        emojiDetailLabel.alpha = 0
        
    }
    
    
    func loadUserView(){
        self.userProfileView.user = self.displayUser
        
    }
    
    func setupTableView(){
        userTableView.register(UserAndListCell.self, forCellReuseIdentifier: UserCellId)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshList), for: .valueChanged)
        userTableView.refreshControl = refreshControl
        userTableView.alwaysBounceVertical = true
        userTableView.keyboardDismissMode = .onDrag
    }
    
    func refreshList(){
        self.fetchAllUsers()
    }
    
    func updateScopeBarCount(){
        var tempScopeBar = searchScopeButtons
        let followingUserCount = allFollowingUsers.count
        let allUserCount = allUsers.count
        tempScopeBar[0] = tempScopeBar[0] + " (\(followingUserCount))"
        tempScopeBar[1] = tempScopeBar[1] + " (\(allUserCount))"

        searchBar.scopeButtonTitles = tempScopeBar

    }
    
    func setupSearchController(){
        self.extendedLayoutIncludesOpaqueBars = true
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        
        searchBar = searchController.searchBar
        searchBar.scopeButtonTitles = searchScopeButtons
        searchBar.showsScopeBar = true
        searchBar.showsCancelButton = false
        
        searchBar.sizeToFit()
        searchBar.delegate = self
        searchBar.placeholder =  searchBarPlaceholderText
        //        searchBar.barTintColor = UIColor.white
        searchBar.tintColor = UIColor.white
        //        searchBar.backgroundColor = UIColor.legitColor()
        definesPresentationContext = true
        
        for s in searchBar.subviews[0].subviews {
            if s is UITextField {
                s.layer.borderWidth = 0.5
                s.layer.borderColor = UIColor.gray.cgColor
                s.layer.backgroundColor = UIColor.white.cgColor
                s.layer.cornerRadius = 10
                s.clipsToBounds = true
            }
        }
        
        self.userTableView.tableHeaderView = searchBar
        searchBar.backgroundColor = UIColor.legitColor()
        searchBar.barTintColor = UIColor.legitColor()
        searchBar.showsCancelButton = false
        
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
//        searchController.searchBar.showsCancelButton = false
        return true
    }
    
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
//        self.searchController.searchBar.showsScopeBar = true
//        self.searchController.searchBar.sizeToFit()
//        self.userTableView.tableHeaderView = self.searchController.searchBar
    }
    
    //    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
    //        self.searchBar.showsScopeBar = true
    //        return true
    //    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        //        self.searchBar.showsScopeBar = true
        //        self.searchBar.sizeToFit()
        //        self.searchBar.text = ""
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
            self.userTableView.reloadData()
        }
    }
    
    func filterContentForSearchText(_ searchText: String) {
        // Filter List Table View
        
        if self.searchBar.selectedScopeButtonIndex == 0 {
            filteredUsers = allFollowingUsers.filter({ (user) -> Bool in
                return user.username.lowercased().contains(searchText.lowercased())
            })
        } else if self.searchBar.selectedScopeButtonIndex == 1 {
            filteredUsers = allUsers.filter({ (user) -> Bool in
                return user.username.lowercased().contains(searchText.lowercased())
            })
        }

        filteredUsers.sort { (p1, p2) -> Bool in
            ((p1.username.hasPrefix(searchText.lowercased())) ? 0 : 1) < ((p2.username.hasPrefix(searchText.lowercased())) ? 0 : 1)
        }
        
        self.userTableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        self.userTableView.reloadData()
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering{
            return filteredUsers.count
        } else {
            return self.searchBar.selectedScopeButtonIndex == 0 ? allFollowingUsers.count : allUsers.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var user: User? = nil
        if isFiltering{
            user = filteredUsers[indexPath.row]
        } else {
            user = self.searchBar.selectedScopeButtonIndex == 0 ? allFollowingUsers[indexPath.row] : allUsers[indexPath.row]
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: UserCellId, for: indexPath) as! UserAndListCell
        cell.user = user

        if user?.uid == self.selectedUser?.uid {
            cell.isSelected = true
        } else {
            cell.isSelected = false
        }
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var selectedUser: User?
        
        if isFiltering {
            selectedUser = filteredUsers[indexPath.row]
        } else {
            selectedUser = self.searchBar.selectedScopeButtonIndex == 0 ? allFollowingUsers[indexPath.row] : allUsers[indexPath.row]
        }
        
        if selectedUser?.uid == self.selectedUser?.uid {
            print("Deselect | \(selectedUser?.username)")
            self.delegate?.userListSelected(user: nil)

        } else {
        print("Selected | \(selectedUser?.username)")
        self.delegate?.userListSelected(user: selectedUser!)
        }
//        self.delegate?.listSelected(list: selectedList!)
        self.navigationController?.popViewController(animated: true)
    }
    
    func didTapUserView() {
        self.delegate?.userListSelected(user: self.displayUser)
        self.navigationController?.popViewController(animated: true)

    }
    
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {

        print("Deselected | \(selectedUser?.username)")
        self.delegate?.userListSelected(user: nil)

        self.navigationController?.popViewController(animated: true)

        
    }
    
    func didTapUserUid(uid: String) {
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = uid
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    

    

    
    func didTapEmoji(index: Int, emoji: String) {
        
        
        guard let  displayEmojiTag = EmojiDictionary[emoji] else {return}
        //        self.delegate?.displaySelectedEmoji(emoji: displayEmoji, emojitag: displayEmojiTag)
        
        print("Selected Emoji | \(index) | \(emoji) | \(displayEmojiTag)")
        
        var captionDelay = 3
        emojiDetailLabel.text = "\(emoji)  \(displayEmojiTag)"
        emojiDetailLabel.alpha = 1
        emojiDetailLabel.sizeToFit()
        
        UIView.animate(withDuration: 0.5, delay: TimeInterval(captionDelay), options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.emojiDetailLabel.alpha = 0
        }, completion: { (finished: Bool) in
        })
    }
    
    

    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
