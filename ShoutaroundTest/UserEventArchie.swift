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


class UserEventViewControllerArchive : UITableViewController, EventCellDelegate {
    
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
    
    let navClearButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        button.setTitle("Clear", for: .normal)
        button.setTitleColor(UIColor.ianLegitColor(), for: .normal)
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
    }
    
    let buttonBar = UIView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAll), name: UserEventViewController.refreshNotificationName, object: nil)
        
        
        fetchEvents()
        
        tableView.backgroundColor = UIColor.white
        tableView.register(EventCell.self, forCellReuseIdentifier: EventCellId)
        
        setupFilterSegment()
        setupNavigationItems()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 70
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshAll), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.alwaysBounceVertical = true
        tableView.keyboardDismissMode = .onDrag
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(increaseScope))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(decreaseScope))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
    }
    
    func setupFilterSegment(){
        var segmentString = ["Following", "Self"]
        if CurrentUser.unreadEventCount > 0 {
            segmentString[1] += " (\(CurrentUser.unreadEventCount))"
        }
        
        filterSegment = UISegmentedControl(items: segmentString)
        filterSegment.selectedSegmentIndex = 1
        filterSegment.addTarget(self, action: #selector(selectFilter), for: .valueChanged)
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
        filterSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: 18), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
        filterSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 18), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)
    }
    
    func underlineSegment(segment: Int? = 0){
        //        let segmentWidth = (self.fetchTypeSegment.frame.width ) / CGFloat(self.fetchTypeSegment.numberOfSegments)
        let segmentWidth = 100 as CGFloat
        let tempX = self.buttonBar.frame.origin.x
        UIView.animate(withDuration: 0.3) {
//            self.buttonBar.frame.origin.x = self.fetchTypeSegment.center.x - (segmentWidth) + (segmentWidth + 10) * CGFloat(segment ?? 0)
        }
    }
    
    
    func refreshSegmentCounts(){
        var segmentString = ["Following", "Self"]
        if CurrentUser.unreadEventCount > 0 {
            segmentString[1] += " (\(CurrentUser.unreadEventCount))"
        }
        
        filterSegment.setTitle(segmentString[1] , forSegmentAt: 1)
        NotificationCenter.default.post(name: MainTabBarController.NewNotificationName, object: nil)
        print("Trigger |  MainTabBarController.NewNotificationName")

        self.tableView.reloadData()
    }
    
    @objc func refreshAll() {
        self.fetchEvents()
    }
    
    @objc func selectFilter(sender: UISegmentedControl) {
        
        self.displayFollowing = sender.selectedSegmentIndex == 0
        self.tableView.reloadData()
        print("UserEventViewController | DisplayFollowing : ",self.displayFollowing)
    }
    
    
    func setupNavigationItems(){
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        
        self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.ianLegitColor(), NSAttributedString.Key.font.rawValue: UIFont(font: .avenirNextDemiBold, size: 20)])
        self.navigationItem.title = "Alerts" + ((self.unReadEventCount > 0) ? " (\(self.unReadEventCount))" : "")
        //        self.navigationItem.titleView = filterSegment
        
        navClearButton.addTarget(self, action: #selector(clearUpdates), for: .touchUpInside)
        let clearButton = UIBarButtonItem.init(customView: navClearButton)
        navigationItem.leftBarButtonItem = clearButton
        
        let tempNavUserProfileBarButton = NavUserProfileButton.init(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        tempNavUserProfileBarButton.setProfileImage(imageUrl: CurrentUser.user?.profileImageUrl)
        tempNavUserProfileBarButton.addTarget(self, action: #selector(openUserProfile), for: .touchUpInside)
        let barButton2 = UIBarButtonItem.init(customView: tempNavUserProfileBarButton)
        navigationItem.rightBarButtonItem = barButton2
        
    }
    
    func updateUnreadEventCount(){
        self.unReadEventCount = self.userEvents.filter({ (event) -> Bool in
            return !event.read && event.creatorUid != Auth.auth().currentUser?.uid
        }).count
        
        print("UserEventViewController | updateUnreadEventCount | \(self.userEvents.count) Events | \(self.unReadEventCount) New")
        CurrentUser.unreadEventCount = self.unReadEventCount
        self.setupNavigationItems()
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
    
    @objc func openUserProfile(){
        print("UserEventController | Open Current User Profile ")
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = CurrentUser.user?.uid
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapUsername(user:User?) {
        print("UserEventController | didTapUsername : \(user?.uid) \(user?.username) ")
        guard let user = user else {return}
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = user.uid
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapListname(listId: String?) {
        print("UserEventController | didTapListname : \(listId)")
        guard let listId = listId else {return}
        let listViewController = ListViewController()
        listViewController.imageCollectionView.collectionViewLayout = HomeSortFilterHeaderFlowLayout()
        listViewController.inputDisplayListId = listId
        self.navigationController?.pushViewController(listViewController, animated: true)
    }
    
    func showPost(post: Post?) {
        print("UserEventController | showPost : \(post?.id)")
        guard let post = post else {return}
        let pictureController = SinglePostView()
        pictureController.post = post
        navigationController?.pushViewController(pictureController, animated: true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // SELF NOTIFICATIONS
        return self.displayFollowing ? followingEvents.count : userEvents.count
        
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let tv = UIView()
        tv.addSubview(filterSegment)
        filterSegment.anchor(top: tv.topAnchor, left: tv.leftAnchor, bottom: tv.bottomAnchor, right: tv.rightAnchor, paddingTop: 3, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        return tv
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: EventCellId, for: indexPath) as! EventCell
        let row = indexPath.row
        let eventCell = self.displayFollowing ? followingEvents[row] : userEvents[row]
        cell.event = eventCell
        cell.currentUserEvent = !self.displayFollowing || eventCell.userFollowedListObject
        cell.delegate = self
        if self.displayFollowing {
            cell.read = true
        }
        
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let eventCell = self.displayFollowing ? followingEvents[indexPath.row] : userEvents[indexPath.row]
        print("Selected Event | \(eventCell.id)")
        CurrentUser.unreadEventCount += -1
        self.setupFilterSegment()
        Database.saveEventInteraction(event: eventCell)
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        //      Remove Searchbar scope during transition
        //        self.searchBar.isHidden = true
        //        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
