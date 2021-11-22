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
import GooglePlaces
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

//@objc protocol PostSocialDisplayTableViewControllerDelegate {
//    func filterControllerFinished(selectedCaption: String?, selectedRange: String?, selectedLocation: CLLocation?, selectedLocationName: String?, selectedGooglePlaceId: String?, selectedGooglePlaceType: [String]?, selectedMinRating: Double, selectedType: String?, selectedMaxPrice: String?, selectedSort: String, selectedLegit: Bool)
//
//    //    func filterCaptionSelected(searchedText: String?)
//    @objc optional func userSelected(uid: String?)
//    @objc optional func locationSelected(googlePlaceId: String?, googlePlaceName: String?, googlePlaceLocation: CLLocation?, googlePlaceType: [String]?)
//}


class UserEventViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, EventCellDelegate {
    
    static let refreshNotificationName = NSNotification.Name(rawValue: "RefreshNotifications")

    
    let EventCellId = "EventCellId"
    
    // 1. Show Lists that pinned input Post
    // 2. Show Users that like input Post
    
    var userEvents: [Event] = [] {
        didSet {
            self.updateUnreadEventCount()
        }
    }
    var followingEvents: [Event] = []

    var displayFollowing: Bool = false {
        didSet{
//            self.selectedScope = self.displayFollowing ? 0 : 1
        }
    }
    
    var unReadEventCount = 0 {
        didSet {
//            NotificationCenter.default.post(name: MainTabBarController.NewNotificationName, object: nil)
        }
    }
    var filterSegment = UISegmentedControl()
    lazy var tableView : UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        tv.estimatedRowHeight = 100
        tv.allowsMultipleSelection = false
        return tv
    }()
    
    let navClearButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        button.setTitle("Clear", for: .normal)
        button.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 12)
        //        button.layer.cornerRadius = button.frame.width/2
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(clearUpdates), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.borderColor = UIColor.gray.cgColor
        button.layer.borderWidth = 0
        return button
    }()
    
    @objc func clearUpdates(){
        var updateCount = 0
        
        var tempEvents: [Event] = []
        
        for event in self.userEvents {
            if !event.read {
                Database.saveEventInteraction(event: event)
                updateCount += 1
                event.read = true
            }
            tempEvents.append(event)
        }
        
        print("UserEventViewController | Clear Updates | Cleared \(updateCount) Notifications")
        self.userEvents = tempEvents
        CurrentUser.unreadEventCount = 0
        self.refreshSegmentCounts()
        self.tableView.reloadData()
        NotificationCenter.default.post(name: UserProfileController.RefreshNotificationName, object: nil)
    }
    
    let buttonBar = UIView()

    var buttonBarPosition: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        setupNavigationItems()
        SharedFunctions.checkNotificationAccess()

        NotificationCenter.default.addObserver(self, selector: #selector(refreshAll), name: UserEventViewController.refreshNotificationName, object: nil)

//        let filterView = UIView()
//        filterView.backgroundColor = UIColor.white
//        view.addSubview(filterView)
//        filterView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//
//        setupFilterSegment()
//        view.addSubview(filterSegment)
//        filterSegment.anchor(top: filterView.topAnchor, left: filterView.leftAnchor, bottom: filterView.bottomAnchor, right: filterView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        let segmentWidth = (self.view.frame.width - 40) / 2
        
//        buttonBar.backgroundColor = UIColor.ianLegitColor()
//
//        view.addSubview(buttonBar)
//        buttonBar.anchor(top: nil, left: nil, bottom: filterSegment.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: segmentWidth, height: 5)
//        buttonBarPosition = buttonBar.leftAnchor.constraint(equalTo: filterSegment.leftAnchor, constant: 5)
//        self.underlineSegment(segment: filterSegment.selectedSegmentIndex)
////        buttonBarPosition?.isActive = true
////        buttonBar.leftAnchor.constraint(lessThanOrEqualTo: filterSegment.leftAnchor).isActive = true
////        buttonBar.rightAnchor.constraint(lessThanOrEqualTo: filterSegment.rightAnchor).isActive = true

        
        setupTableView()
        
        view.addSubview(tableView)
        tableView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        fetchEvents()

        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(increaseScope))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(decreaseScope))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
    }
    
    func setupTableView(){
        tableView.backgroundColor = UIColor.white
        tableView.register(EventCell.self, forCellReuseIdentifier: EventCellId)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 70
        tableView.allowsSelection = false
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshAll), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.alwaysBounceVertical = true
        tableView.keyboardDismissMode = .onDrag
    }
    
    func setupFilterSegment(){
        var segmentString = ["Following", "Self"]
        if CurrentUser.unreadEventCount > 0 {
            segmentString[1] += " (\(CurrentUser.unreadEventCount))"
        }
        
        filterSegment = UISegmentedControl(items: segmentString)
        filterSegment.addTarget(self, action: #selector(selectFilter), for: .valueChanged)
        filterSegment.selectedSegmentIndex = 1

        //        headerSortSegment.tintColor = UIColor(hexColor: "107896")
//        filterSegment.tintColor = UIColor.legitColor()
//        filterSegment.backgroundColor = UIColor.white
        filterSegment.layer.cornerRadius = 5
        filterSegment.clipsToBounds = true
//        filterSegment.setTitleTextAttributes([NSAttributedString.Key.font: HeaderFontSizeDefault], for: .normal)
        
        filterSegment.backgroundColor = .white
        filterSegment.tintColor = .white
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        filterSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: 16), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
        filterSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 16), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)
    }
    
    func underlineSegment(segment: Int? = 0){
        
        let segmentWidth = (self.view.frame.width) / CGFloat(self.filterSegment.numberOfSegments)
        let tempX = self.buttonBar.frame.origin.x
        UIView.animate(withDuration: 0.3) {
            //            self.buttonBarPosition?.isActive = false
            self.buttonBar.frame.origin.x = segmentWidth * CGFloat(segment ?? 0) + 5
            self.buttonBarPosition?.constant = segmentWidth * CGFloat(segment ?? 0) + 5
            self.buttonBarPosition?.isActive = true
        }
        
    }
    
    
    func refreshSegmentCounts(){
        var segmentString = ["Following", "Self"]
        if CurrentUser.unreadEventCount > 0 {
            self.navigationItem.title = "Notifications (\(CurrentUser.unreadEventCount))"
        } else {
            self.navigationItem.title = "Notifications"
        }
        
//        filterSegment.setTitle(segmentString[1] , forSegmentAt: 1)
        NotificationCenter.default.post(name: MainTabBarController.NewNotificationName, object: nil)
        print("Trigger |  MainTabBarController.NewNotificationName")

        self.tableView.reloadData()
    }
    
    @objc func refreshAll() {
        self.fetchEvents()
    }
    
    @objc func selectFilter(sender: UISegmentedControl) {
        
        self.displayFollowing = sender.selectedSegmentIndex == 0
        self.underlineSegment(segment: sender.selectedSegmentIndex)
        self.tableView.reloadData()
        print("UserEventViewController | DisplayFollowing : ",self.displayFollowing)
    }
    
    
    func setupNavigationItems(){
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        
        self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.ianLegitColor(), NSAttributedString.Key.font.rawValue: UIFont(name: "Poppins-Bold", size: 18)])
//        self.navigationItem.title = "Alerts" + ((self.unReadEventCount > 0) ? " (\(self.unReadEventCount))" : "")
        self.navigationItem.title = "Notifications"

//        self.navigationItem.titleView = filterSegment
        
        // Nav Back Buttons
        let navBackButton = navBackButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        navBackButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        let barButton2 = UIBarButtonItem.init(customView: navBackButton)
        self.navigationItem.leftBarButtonItem = barButton2
        
        // Clear Button
        navClearButton.addTarget(self, action: #selector(clearUpdates), for: .touchUpInside)
        let clearButton = UIBarButtonItem.init(customView: navClearButton)
        navigationItem.rightBarButtonItem = clearButton
        
//        let tempNavUserProfileBarButton = NavUserProfileButton.init(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
//        tempNavUserProfileBarButton.setProfileImage(imageUrl: CurrentUser.user?.profileImageUrl)
//        tempNavUserProfileBarButton.addTarget(self, action: #selector(openUserProfile), for: .touchUpInside)
//        let barButton2 = UIBarButtonItem.init(customView: tempNavUserProfileBarButton)
//        navigationItem.rightBarButtonItem = barButton2
        
        // REMOVES THE 1PX BOTTOM LINE IN NAV BAR
        navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    func updateUnreadEventCount(){
        self.unReadEventCount = self.userEvents.filter({ (event) -> Bool in
            return !event.read && event.creatorUid != Auth.auth().currentUser?.uid
        }).count
        
        print("UserEventViewController | updateUnreadEventCount | \(self.userEvents.count) Events | \(self.unReadEventCount) New")
        CurrentUser.unreadEventCount = self.unReadEventCount
//        self.setupNavigationItems()
    }
    
    
    @objc func increaseScope(){
        self.displayFollowing = false
        self.tableView.reloadData()
    }
    
    @objc func decreaseScope(){
        self.displayFollowing = true
        self.tableView.reloadData()
    }
    
    func fetchEvents(){
        guard let uid = Auth.auth().currentUser?.uid else {return}
        self.fetchSelfEvents()
        
        if CurrentUser.followerUids.count == 0 {
            Database.fetchFollowingUserUids(uid: uid) { (uids) in
                CurrentUser.followerUids = uids
                self.fetchFollowingEvents()
            }
        } else {
            self.fetchFollowingEvents()
        }
    }
    
    func fetchSelfEvents(){
        guard let uid = Auth.auth().currentUser?.uid else {return}
        Database.fetchEventForUID(uid: uid) { (events) in
            var tempEvents = events.sorted(by: { (event1, event2) -> Bool in
                return event1.eventTime.compare(event2.eventTime) == .orderedDescending
            })
            
            tempEvents = Database.filterEvents(events: tempEvents, filterSelf: true)

            self.userEvents = tempEvents.sorted(by: { (event1, event2) -> Bool in
                return event1.eventTime.compare(event2.eventTime) == .orderedDescending
            })
            
            print("UserEventViewController | fetchSelfEvents | \(uid) | \(events.count) Fetched | \(self.userEvents.count) Final")

            
            if !self.displayFollowing {
                self.tableView.refreshControl?.endRefreshing()
                self.tableView.reloadData()
            }
        }
    }
    
//    func filterEvents(events: [Event]?, following: Bool? = false) -> [Event] {
//        guard let events = events else {return []}
//        guard let uid = Auth.auth().currentUser?.uid else {return []}
//        var tempEvents = events
//
//    // Filter out unfollows
//        tempEvents = tempEvents.filter { (event) -> Bool in
//            return event.value == 1
//        }
//
//    // Filter your own actions
////        tempEvents = tempEvents.filter { (event) -> Bool in
////            return event.creatorUid != uid
////        }
//
//    // Filter self actions
//        tempEvents = tempEvents.filter { (event) -> Bool in
//            return event.creatorUid != event.receiverUid
//        }
//
//    // REMOVE ALL EVENTS THAT INCLUDE YOU
//        if displayFollowing {
//            tempEvents = tempEvents.filter { (event) -> Bool in
//                return (event.creatorUid != uid && event.receiverUid != uid)
//            }
//        } else {
//            tempEvents = tempEvents.filter { (event) -> Bool in
//                return (event.creatorUid != uid)
//            }
//        }
//
//
//    // Filter Ignore later duplicates
//        var tempKeys:[String] = []
//        var finalEvents: [Event] = []
//
//        for event in tempEvents {
//            guard let id = event.creatorUid else {continue}
//            guard let action = event.action?.rawValue else {continue}
//            let postId = event.postId ?? ""
//            let listId = event.listId ?? ""
//            let userId = event.receiverUid ?? ""
//
//            var key = id + action + postId + listId + userId
//
//            if !tempKeys.contains(key) {
//                tempKeys.append(key)
//                finalEvents.append(event)
//            }
//        }
//
//
//        return finalEvents
//    }
    
    func fetchFollowingEvents(){
        let thisGroup = DispatchGroup()
        var tempEvents: [Event] = []
        
//        print("UserEventViewController | fetchFollowingEvents")
//        for id in CurrentUser.followingUids {
//            thisGroup.enter()
//            Database.fetchEventForUID(uid: id) { (event) in
//                if event.count > 0 {
//                    tempEvents += event
//                }
//                thisGroup.leave()
//            }
//        }
//
        guard let uid = Auth.auth().currentUser?.uid else {return}

        thisGroup.enter()
        Database.fetchUserFollowingListEventForUID(uid: uid) { (events) in
            tempEvents += events
            thisGroup.leave()
        }
        
        thisGroup.notify(queue: .main) {
            if tempEvents.count > 0 {
                tempEvents = Database.filterEvents(events: tempEvents)
                
                
                self.followingEvents = tempEvents.sorted(by: { (event1, event2) -> Bool in
                    return event1.eventTime.compare(event2.eventTime) == .orderedDescending
                })
            }

            if self.displayFollowing {
                self.tableView.refreshControl?.endRefreshing()
                self.tableView.reloadData()
            }
            print("UserEventViewController | fetchFollowingEvents | \(CurrentUser.followingUids.count) Users : \(self.followingEvents.count) Events")
        }
    }
    
// DELEGATE FUNCTIONS
    
    func saveInteraction(event: Event?) {
        guard let event = event else {return}
        if (self.displayFollowing && !event.userFollowedListObject) {return}
        
        Database.saveEventInteraction(event: event)
        if let row = self.userEvents.firstIndex(where: {$0.id == event.id}) {
            let tempEvent = self.userEvents[row]
            tempEvent.readTime = Date()
            tempEvent.read = true
            self.userEvents[row] = tempEvent
            let indexPath = IndexPath(row: row, section: 0)
            self.tableView.reloadRows(at: [indexPath], with: .none)
            self.updateUnreadEventCount()
        } else {
            print("saveInteraction | TableView | Can't Find Row | \(event.id)")
        }
    }
    
    func openUserProfile(){
        print("UserEventController | Open Current User Profile ")
        guard let uid = CurrentUser.user?.uid else {return}
        self.extTapUser(userId: uid)
//        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
//        userProfileController.displayUserId = CurrentUser.user?.uid
//        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapUsername(user:User?) {
        print("UserEventController | didTapUsername : \(user?.uid) \(user?.username) ")
        guard let uid = user?.uid else {return}
        self.extTapUser(userId: uid)
//        guard let user = user else {return}
//        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
//        userProfileController.displayUserId = user.uid
//        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapListname(listId: String?) {
        print("UserEventController | didTapListname : \(listId)")
        guard let listId = listId else {return}
        self.extTapListId(listId: listId)

//        let listViewController = ListViewController()
//        listViewController.imageCollectionView.collectionViewLayout = HomeSortFilterHeaderFlowLayout()
//        listViewController.inputDisplayListId = listId
//        self.navigationController?.pushViewController(listViewController, animated: true)
    }
    
    func showPost(post: Post?) {
        print("UserEventController | showPost : \(post?.id)")
        guard let post = post else {return}
        self.extTapPicture(post: post)
//        let pictureController = SinglePostView()
//        pictureController.post = post
//        navigationController?.pushViewController(pictureController, animated: true)
    }
    
    func showPostComments(post: Post?) {
        print("UserEventController | showPostComments : \(post?.id)")
        guard let post = post else {return}
        self.extTapComment(post: post)
//        self.extTapPictureComment(post: post)
//        let pictureController = SinglePostView()
//        pictureController.post = post
//        navigationController?.pushViewController(pictureController, animated: true)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // SELF NOTIFICATIONS
        return self.displayFollowing ? followingEvents.count : userEvents.count
        
    }
    
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let tv = UIView()
//        tv.addSubview(filterSegment)
//        filterSegment.anchor(top: tv.topAnchor, left: tv.leftAnchor, bottom: tv.bottomAnchor, right: tv.rightAnchor, paddingTop: 3, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
//        return tv
//    }
    
//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 40
//    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: EventCellId, for: indexPath) as! EventCell
        let row = indexPath.row
        let eventCell = self.displayFollowing ? followingEvents[row] : userEvents[row]
        cell.event = eventCell
        cell.currentUserEvent = !self.displayFollowing || eventCell.userFollowedListObject
        cell.delegate = self
        if self.displayFollowing {
            cell.read = true
        }
        cell.contentView.isUserInteractionEnabled = false
            
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let eventCell = self.displayFollowing ? followingEvents[indexPath.row] : userEvents[indexPath.row]
        print("Selected Event | \(eventCell.id)")
        CurrentUser.unreadEventCount += -1
//        self.setupFilterSegment()
        Database.saveEventInteraction(event: eventCell)

    }
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 70
//    }
//    
    
    override func viewWillDisappear(_ animated: Bool) {
        //      Remove Searchbar scope during transition
//        self.searchBar.isHidden = true
        //        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.setupNavigationItems()
        //      Show Searchbar scope during transition
//        self.searchBar.isHidden = false
//        self.searchBar.selectedScopeButtonIndex = self.selectedScope
//        self.tableView.reloadData()
        //        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            self.refreshSegmentCounts()
            //            self.searchController.searchBar.becomeFirstResponder()
        }
    }
    
    
    
    
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input = input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
