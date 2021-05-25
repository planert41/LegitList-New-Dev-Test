//
//  NewUserWelcomeFollowViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 6/29/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

import DropDown
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth

class NewUserWelcomeFollowViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DiscoverUserCellDelegate, DiscoverListCellNewDelegate {
    

    let welcomeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = UIFont(name: "Poppins-Bold", size: 30)
        label.backgroundColor = UIColor.clear
        label.text = "Curating Your Feed"
        label.textColor = UIColor.ianLegitColor()
        return label
    }()
    
    let missionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = UIFont(name: "Poppins-Regular", size: 16)
        //        label.textColor = UIColor.ianOrangeColor()
        label.backgroundColor = UIColor.clear
//        label.text = "Find people and lists to follow to curate a feed based on your taste! You are new here, so we hooked you up with some legit people to start with"
        label.text = "Follow people who share your taste or find lists that interests you. You are already following some pretty legit people and lists to start 🥳"

        label.textColor = UIColor.ianBlackColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    let addListButton: UIButton = {
        let button = UIButton()
        button.setTitle("Next - Create A List", for: .normal)
        button.titleLabel?.textColor = UIColor.white
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.ianLegitColor()
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.legitColor().cgColor
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        button.layer.cornerRadius = 10
        button.titleLabel?.textAlignment = NSTextAlignment.center
        
        button.addTarget(self, action: #selector(addList), for: .touchUpInside)
        return button
    } ()
    
    @objc func addList(){
        let listView = CreateNewListController()
        self.navigationController?.pushViewController(listView, animated: true)
        //        self.navigationController?.present(listView, animated: true, completion: nil)
    }
    
    var fetchTypeSegment = UISegmentedControl()
    var selectedType: String = DiscoverOptions[0] {
        didSet {
            fetchTypeSegment.selectedSegmentIndex = scopeBarOptions.firstIndex(of: selectedType)!
//            self.refreshAll()
        }
    }
    
    var scopeBarOptions:[String] = DiscoverOptions
    let buttonBar = UIView()
    var buttonBarPosition: NSLayoutConstraint?

    lazy var tableView : UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        tv.estimatedRowHeight = 100
        tv.allowsMultipleSelection = false
        return tv
    }()
    
    let listCellId = "listCellId"
    
    var followingUsers: [User] = []
    var otherUsers: [User] = []
    
    // Auto Follow Users
    let weizouID = "2G76XbYQS8Z7bojJRrImqpuJ7pz2"
    let meimeiID = "nWc6VAl9fUdIx0Yf05yQFdwGd5y2"
    let maynardID = "srHzEjoRYKcKGqAgiyG4E660amQ2"
    
    func fetchUsers(){
        print("NewUserWelcomeFollowing | Fetch Users ")
        
        self.otherUsers.removeAll()
        self.followingUsers.removeAll()
        let autoIds: [String] = [weizouID, meimeiID, maynardID]

        Database.fetchALLUsers(includeSelf: false, completion: { (allUsers) in
            for user in allUsers {
                if autoIds.contains(user.uid) {
                    var tempUser = user
                    tempUser.isFollowing = true
                    self.followingUsers.append(tempUser)
                }
                else if (user.isFollowing)! {
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
            
            print("NewUserWelcomeFollowing | Fetched \(allUsers.count) Users | \(self.followingUsers.count) Following | \(self.otherUsers.count) Others")

            self.refreshAll()
            
        })
    }
    
    var followingLists: [List] = []

    let mayneats = "CBD367A0-4B4B-480F-BEDE-3A85476ECCC1"
    let breakfast = "A3EFD19E-7C97-4A9B-8A87-AAF64E4D0017"
    let malaysia = "10A3773F-3950-4510-8329-FB86C572282E"
    let denver = "4C202E90-AC03-4BD5-98F9-AE9C1C37E842"
    // CBD367A0-4B4B-480F-BEDE-3A85476ECCC1 - MaynEats
    // 10A3773F-3950-4510-8329-FB86C572282E - Malaysia
    // A3EFD19E-7C97-4A9B-8A87-AAF64E4D0017 - Breakfast/Brunch
    // 4C202E90-AC03-4BD5-98F9-AE9C1C37E842 - Denver
    
    func fetchLists(){
        print("NewUserWelcomeFollowing | Fetch Users ")
        
        self.followingLists.removeAll()
        let autoIds: [String] = [mayneats, breakfast, malaysia, denver]
        CurrentUser.followedListIds = autoIds

        Database.fetchListForMultListIds(listUid: autoIds) { (lists) in
            self.followingLists = lists
            print("NewUserWelcomeFollowing | Fetched \(lists.count) Lists")

            self.refreshAll()
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.backgroundGrayColor()
        self.navigationController?.isNavigationBarHidden = true
        
        self.view.isUserInteractionEnabled = true
//        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleBackPressNav))
//        swipeRight.direction = .right
//        self.view.addGestureRecognizer(swipeRight)
//
//        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(addList))
//        swipeLeft.direction = .left
//        self.view.addGestureRecognizer(swipeLeft)
        
        
        self.view.addSubview(addListButton)
        addListButton.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 40, paddingBottom: 30, paddingRight: 40, width: 0, height: 50)
        addListButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        addListButton.sizeToFit()
        
        self.view.addSubview(welcomeLabel)
        welcomeLabel.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        //        welcomeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        welcomeLabel.sizeToFit()
        
        self.view.addSubview(missionLabel)
        missionLabel.anchor(top: welcomeLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        missionLabel.sizeToFit()
        missionLabel.isUserInteractionEnabled = true
        let swipeRight1 = UISwipeGestureRecognizer(target: self, action: #selector(handleBackPressNav))
        swipeRight1.direction = .right
        self.missionLabel.addGestureRecognizer(swipeRight1)
        
        let swipeLeft1 = UISwipeGestureRecognizer(target: self, action: #selector(addList))
        swipeLeft1.direction = .left
        self.missionLabel.addGestureRecognizer(swipeLeft1)
        
        
        setupTypeSegment()
        let sortSegmentView = UIView()
        sortSegmentView.backgroundColor = UIColor.white
        view.addSubview(sortSegmentView)
        sortSegmentView.anchor(top: missionLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 45)

        
        view.addSubview(fetchTypeSegment)
        fetchTypeSegment.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 40)
        fetchTypeSegment.centerYAnchor.constraint(equalTo: sortSegmentView.centerYAnchor).isActive = true
        fetchTypeSegment.backgroundColor = .white
        fetchTypeSegment.tintColor = .white
        fetchTypeSegment.layer.applySketchShadow()
        
        fetchTypeSegment.selectedSegmentIndex = 0
        
        buttonBar.backgroundColor = UIColor.ianLegitColor()
        
        let segmentWidth = (self.view.frame.width - 30) / 2
        
        view.addSubview(buttonBar)
        buttonBar.anchor(top: nil, left: nil, bottom: fetchTypeSegment.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: segmentWidth, height: 5)
        buttonBar.leftAnchor.constraint(lessThanOrEqualTo: fetchTypeSegment.leftAnchor).isActive = true
        buttonBar.rightAnchor.constraint(lessThanOrEqualTo: fetchTypeSegment.rightAnchor).isActive = true
        buttonBarPosition = buttonBar.leftAnchor.constraint(equalTo: fetchTypeSegment.leftAnchor, constant: 5)
        buttonBarPosition?.isActive = true
        
        tableView.register(DiscoverUserCell.self, forCellReuseIdentifier: userCellId)
        tableView.register(DiscoverListCellNew.self, forCellReuseIdentifier: listCellId)

        view.addSubview(tableView)
        tableView.anchor(top: fetchTypeSegment.bottomAnchor, left: view.leftAnchor, bottom: addListButton.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 10, paddingRight: 5, width: 0, height: 0)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshAll), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.alwaysBounceVertical = true
        tableView.keyboardDismissMode = .onDrag
        tableView.backgroundColor = UIColor.white
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleBackPressNav))
        swipeRight.direction = .right
        self.tableView.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(addList))
        swipeLeft.direction = .left
        self.tableView.addGestureRecognizer(swipeLeft)
        
        self.fetchUsers()
        self.fetchLists()
        
        // Do any additional setup after loading the view.
    }
    
    @objc func refreshAll(){
        self.tableView.reloadData()
    }
    
    func setupTypeSegment(){
        fetchTypeSegment = UISegmentedControl(items: scopeBarOptions)
        fetchTypeSegment.selectedSegmentIndex = scopeBarOptions.firstIndex(of: self.selectedType) ?? 0
        fetchTypeSegment.addTarget(self, action: #selector(selectFetchType), for: .valueChanged)
        fetchTypeSegment.layer.applySketchShadow()

        fetchTypeSegment.backgroundColor = .white
        fetchTypeSegment.tintColor = .white
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        fetchTypeSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: 18), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
        fetchTypeSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 18), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)
        //        fetchTypeSegment.setTitleTextAttributes([NSAttributedString.Key.font: HeaderFontSizeDefault], for: .normal)
    }
    
    
    func underlineSegment(segment: Int? = 0){
        
        let segmentWidth = (self.view.frame.width) / CGFloat(self.fetchTypeSegment.numberOfSegments)
        let tempX = self.buttonBar.frame.origin.x
        UIView.animate(withDuration: 0.3) {
            //            self.buttonBarPosition?.isActive = false
            self.buttonBar.frame.origin.x = segmentWidth * CGFloat(segment ?? 0) + 5
            self.buttonBarPosition?.constant = segmentWidth * CGFloat(segment ?? 0) + 5
            self.buttonBarPosition?.isActive = true
        }
    }
    
    @objc func selectFetchType(sender: UISegmentedControl) {
        self.selectedType = self.scopeBarOptions[sender.selectedSegmentIndex]
        self.underlineSegment(segment: sender.selectedSegmentIndex)
        print("NewUserWelcomeController | Type Selected | \(self.selectedType)")
        self.refreshAll()
    }
    
    @objc func handleBackPressNav(){
        //        guard let post = self.selectedPost else {return}
        self.handleBack()
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
    
    func goToUser(user: User?, filter: String?) {
        guard let userId = user?.uid else {return}
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = userId
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
        postSocialController.displayUserFollowing = false
        postSocialController.inputUser = user
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    

    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.fetchTypeSegment.selectedSegmentIndex == 0 {
            return followingLists.count
        } else if self.fetchTypeSegment.selectedSegmentIndex == 1 {
            return followingUsers.count
        } else {
            return 0
        }

    }
    
    let userCellId = "userCellId"
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.fetchTypeSegment.selectedSegmentIndex == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: listCellId, for: indexPath) as! DiscoverListCellNew
            let currentList = followingLists[indexPath.row]
            cell.list = currentList
            cell.list?.newNotificationsCount = 0
            cell.isSelected = false
            cell.enableSelection = false
            cell.refUser = CurrentUser.user
            cell.backgroundColor = UIColor.white
            cell.hideProfileImage = true
            cell.delegate = self
            cell.selectionStyle = .none
            return cell
        }
        
        else if self.fetchTypeSegment.selectedSegmentIndex == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: userCellId, for: indexPath) as! DiscoverUserCell
            let currentUser = followingUsers[indexPath.row]
            cell.user = currentUser
            cell.isSelected =  false
            cell.delegate = self
            cell.selectionStyle = .none
            
            return cell
        }
        
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: userCellId, for: indexPath) as! DiscoverUserCell
            let currentUser = (self.fetchTypeSegment.selectedSegmentIndex == 0) ? followingUsers[indexPath.row] : otherUsers[indexPath.row]
            cell.user = currentUser
            cell.isSelected =  false
            cell.delegate = self
            cell.selectionStyle = .none
            return cell
        }
        

    }
    

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
    
    func goToList(list: List?, filter: String?) {
        guard let list = list else {return}
        let listViewController = ListViewController()
        listViewController.currentDisplayList = list
        listViewController.viewFilter?.filterCaption = filter
        listViewController.refreshPostsForFilter()
        print("DiscoverController | goToList | \(list.name) | \(filter) | \(list.id)")
        
        self.navigationController?.pushViewController(listViewController, animated: true)
    }
    
    func displayListFollowingUsers(list: List, following: Bool) {
        print("Display Users| Following: ",list.id)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayUser = true
        postSocialController.displayUserFollowing = false
        postSocialController.inputList = list
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    func goToUser(userId: String?) {
        guard let userId = userId else {return}
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = userId
        self.navigationController?.pushViewController(userProfileController, animated: true)
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
