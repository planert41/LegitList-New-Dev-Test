//
//  Firebase.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/30/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//


import GeoFire
import Alamofire
import SwiftyJSON
import Smile
import SVProgressHUD
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import Photos
import RevenueCat

var postCache = [String: Post]()
var voteCache = [String:Int]()
var userCache = [String: User]()
var listCache = [String: List]()
var locationCache = [String: Location]()
var locationGoogleJSONCache = [String: JSON]()
var eventCache = [String: Event]()
var processingCache = [String: Int]()
var listRefreshRecord = [String:Int]()

extension Database{
    
    enum PostError: Error {
        case noPost
    }


    static func setupGuestUser(uid: String?, completion:@escaping () ->()){
        guard let uid = uid else {
            print("Setup Guest Error: No UID")
            return
        }
        
        var guest = User(uid: uid, dictionary: ["username":"Guest"])
        CurrentUser.user = guest
        
        let listAddDate = Date().timeIntervalSince1970
        // Setup Test Lists
        var guestBookmarkListId = NSUUID().uuidString
        var guestLegitListId = NSUUID().uuidString
        
        let guestBookmarkPosts = ["DF5AB928-D1E4-4C64-BB13-2A0B03AE2271":listAddDate,
                                  "981AA6AA-5441-4B72-B0F0-E2135F51927F":listAddDate]
        
        let guestLegitPosts = ["B46CE9EF-D325-47F5-869D-C2CAB466905A":listAddDate,
                               "7C150309-D5CA-4564-8C30-D9AB6CB6FF7B":listAddDate]
        
        var guestBookmarkList = emptyBookmarkList
        guestBookmarkList.id = guestBookmarkListId
        guestBookmarkList.creatorUID = uid
        guestBookmarkList.postIds = guestBookmarkPosts
        
        var guestLegitList = emptyLegitList
        guestLegitList.id = guestLegitListId
        guestLegitList.creatorUID = uid
        guestLegitList.postIds = guestLegitPosts
        
        
        CurrentUser.lists = [guestLegitList,guestBookmarkList]
        CurrentUser.listIds = [guestLegitListId,guestBookmarkListId]
        CurrentUser.user?.listIds = [guestLegitListId,guestBookmarkListId]
        CurrentUser.isGuest = true
        LocationSingleton.sharedInstance.determineCurrentLocation()
        print("Setup Guest User as Current User: \(uid)")
        completion()

    }

    
    
    static func checkUsernameAvailable(username: String?, completion: @escaping(Bool) ->()){

        guard let username = username else {
            completion(false)
            return
        }
        Database.database().reference().child("users").queryOrdered(byChild: "username").queryEqual(toValue: username).observe(DataEventType.value) { (snapshot: DataSnapshot) in
            
            if snapshot.exists() {
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    static func fetchPremiumActivate(){
        let userRef = Database.database().reference().child("activatePremium")
        
        userRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            let activate = snapshot.value as? Bool
            premiumActivated = activate ?? false
            print("fetchPremiumActivate : \(premiumActivated)")
        }) {(err) in
            print("Failed to fetchPremiumActivate:",err)
        }
    }

    
    
    static func loadCurrentUser(inputUser: User?, completion:@escaping () ->()){
        
        print(" 0 | FETCH_CURRENT_USER |START")
        let start = DispatchTime.now() // <<<<<<<<<< Start time

        
        // uid using userID if exist, if not, uses current user, if not uses blank
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("FETCH_CURRENT_USER: ERROR, No User UID")
            return}
        
        Database.fetchPremiumActivate()
        
// 1. FIND CURRENT LOCATION
        
//        if CurrentUser.currentLocation == nil {
//            LocationSingleton.sharedInstance.determineCurrentLocation()
//            print(" 1 | FETCH_CURRENT_USER |Find Current Location")
//        } else {
//            print(" 1 | FETCH_CURRENT_USER |Use Current Location")
//        }
        
// 2. FETCH USER OBJECT
        let fetchedUser = DispatchGroup()
        fetchedUser.enter()
        
        if inputUser == nil {
            Database.fetchUserWithUID(uid: uid) { (user) in
                CurrentUser.user = user
                print(" 2 | FETCH_CURRENT_USER |Fetched User Object | \((CurrentUser.user?.username) ?? "") | \(CurrentUser.user?.isPremium) Premium |\(CurrentUser.listIds.count) Lists")
                
                checkPremiumStatus()

            }
            NotificationCenter.default.post(name: HomeController.refreshNavigationNotificationName, object: nil)
            fetchedUser.leave()

        } else {
            CurrentUser.user = inputUser
            print(" 2 | FETCH_CURRENT_USER | Loaded User Object | \((CurrentUser.user?.username)!) | \((inputUser?.uid)!) | \(CurrentUser.user?.isPremium) Premium | \(CurrentUser.user?.premiumStart) Start | \(CurrentUser.user?.premiumExpiry) Expire")
            if premiumActivated{
                checkPremiumStatus()
            } else {
                print("!!! PREMIUM NOT ACTIVATED YET | LOAD CURRENT USER")
            }
            
            NotificationCenter.default.post(name: HomeController.refreshNavigationNotificationName, object: nil)
            fetchedUser.leave()
        }
        
    // NEED TO FETCH USER FIRST
        fetchedUser.notify(queue: .main) {
            let loadedUser = DispatchGroup()

    // 3. FIND FOLLOWING USERS UIDS
            
//            Database.fetchFollowingUserUids(uid: uid) { (fetchedFollowingUsers) in
//                CurrentUser.followingUids = fetchedFollowingUsers
//                print(" 3 | FETCH_CURRENT_USER |Fetch User Following | \(CurrentUser.user?.username) | \(CurrentUser.followingUids.count) Following Users")
//            }
            
            loadedUser.enter()
            Database.fetchFollowingUsers(uid: uid) { (followingUsers) in
                CurrentUser.followingUsers = followingUsers
                print(" 3 | FETCH_CURRENT_USER |Loaded Users Following | \(CurrentUser.user?.username) | \(CurrentUser.followingUids.count) Following Users")
                loadedUser.leave()
//                if CurrentUser.followingUids.count > 0 {
//                    self.setupUserFollowingListener(uids: CurrentUser.followingUids)
//                    print(" 3 | FETCH_CURRENT_USER | Setup Listeners for \(CurrentUser.followingUids.count) Following Users")
//                }

            }
            
            loadedUser.enter()
            Database.fetchFollowerUserUids(uid: uid) { (fetchedFollowerUsers) in
                CurrentUser.followerUids = fetchedFollowerUsers
                print(" 3 | FETCH_CURRENT_USER |Fetch User Followers | \(CurrentUser.user?.username) | \(CurrentUser.followerUids.count) Followers")
                loadedUser.leave()

            }
            
            
    //4. FETCH LISTS
            loadedUser.enter()
            Database.updateCurrentUserList(uid: uid, completion: {
                NotificationCenter.default.post(name: MainTabBarController.CurrentUserListLoaded, object: nil)
                loadedUser.leave()
            })
            
    //5. FETCH USER LIKES
            loadedUser.enter()

            Database.fetchUserLikedPostIds(uid: uid) { likedIdArray in
                CurrentUser.likedPostIds = likedIdArray
                print(" 6 | FETCH_CURRENT_USER |Fetch Liked Post Ids | \(CurrentUser.user?.username) | \(CurrentUser.likedPostIds.count) Liked Posts")
                loadedUser.leave()

            }
            
    // 6. FETCH NOTIFICATIONS
            loadedUser.enter()

        Database.fetchEventForUID(uid: uid) { (events) in
            
            CurrentUser.events = events
//                CurrentUser.unreadEventCount = CurrentUser.events.filter({ (event) -> Bool in
//                    return !event.read && event.creatorUid != Auth.auth().currentUser?.uid && event.value == 1
//                }).count
            
            // REFRESHES TAB NOTIFICATION COUNT
//                NotificationCenter.default.post(name: MainTabBarController.NewNotificationName, object: nil)
            
            self.setupEventListeners()
            self.setupInboxListeners()
            loadedUser.leave()
            print(" 6 | FETCH_CURRENT_USER  | User Notifications and Listeners | TOTAL NOTIFICATIONS: \(CurrentUser.events.count)| UNREAD: \(CurrentUser.unreadEventCount)")

        }
            

    //5. FETCH INBOX
            loadedUser.enter()
            Database.fetchMessageThreadsForUID(userUID: uid) { (messageThreads) in
                CurrentUser.inboxThreads = messageThreads
                loadedUser.leave()
            }
            
            LocationSingleton.sharedInstance.determineCurrentLocation()
            
            loadedUser.notify(queue: .main) {
                let end = DispatchTime.now()   // <<<<<<<<<<   end time
                let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
                let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests
                print("FINISH Load Current User - Time: \(timeInterval) seconds")

                completion()
            }
            
        }
            
//            Database.fetchUserFollowingListEventForUID(uid: uid) { (events) in
//                CurrentUser.listEvents = events
//                CurrentUser.unreadListEventCount = events.filter({ (event) -> Bool in
//                    return !event.read
//                }).count
//                //            self.setupUserListEventListeners()
//                print(" 5 | FETCH_CURRENT_USER  | FollowingListEvents | UnRead User List Events : \(CurrentUser.unreadListEventCount)")
//            }
            

        
    // 6. UPDATE FOR MOST POPULAR IMAGES
//        Database.updateUserPopularImages(user: inputUser)

    
//
//
//        Database.fetchUserWithUID(uid: uid) { (user) in
//            print("FETCH_CURRENT_USER | 2 | Fetched User Object | \(CurrentUser.user?.username) | \(CurrentUser.listIds.count) Lists")
//            CurrentUser.user = user
//
//            // Refresh Navigation to Load User Profile Image
//            NotificationCenter.default.post(name: HomeController.refreshNavigationNotificationName, object: nil)
//
//// 3. FIND FOLLOWING USERS UIDS
//            Database.fetchFollowingUserUids(uid: uid) { (fetchedFollowingUsers) in
//                print("FETCH_CURRENT_USER | 3 | Fetch User Following | \(CurrentUser.user?.username) | \(fetchedFollowingUsers.count) Following Users")
//
//                CurrentUser.followingUids = fetchedFollowingUsers
//
//// 4. FIND USER LISTS
//                if CurrentUser.listIds.count == 0 {
//
//                    // No lists - Creating Default Legit Bookmark Lists
//                    print("FETCH_CURRENT_USER | 3 | Fetch User Lists | NO LISTS | CREATE DEFAULT LISTS")
//
//                    Database.createDefaultList(uid: uid, completion: { (defaultList, defaultListId) in
//                        CurrentUser.lists = defaultList
//                        CurrentUser.listIds = defaultListId
//                        CurrentUser.user?.listIds = defaultListId
//                        print("FETCH_CURRENT_USER | 3 | Fetch User Lists | Default Lists | \(CurrentUser.user?.username) created \(CurrentUser.lists.count) lists")
//
//                        completion()
//                    })
//                } else {
//                    // Fetch Lists
//                    Database.fetchListForMultListIds(listUid: CurrentUser.listIds, completion: { (fetchedLists) in
//
//                        CurrentUser.lists = fetchedLists
//                        Database.checkUserSocialStats(user: CurrentUser.user!, socialField: "lists_created", socialCount: fetchedLists.count)
//                        print("FETCH_CURRENT_USER | 3 | Fetch User Lists | \(CurrentUser.user?.username) fetched \(CurrentUser.lists.count) lists")
//
//                        completion()
//                    })
//                }
//            }
//
//            // Fetch Inbox
//            Database.fetchMessageThreadsForUID(userUID: uid, completion: { (messageThreads) in
//                CurrentUser.inboxThreads = messageThreads
//                print("Current User Inbox Thread: \(CurrentUser.inboxThreads.count)")
//            })
//        }
        
    }
    
    static func initDefaultList(uid: String, completion:@escaping () ->()){
        Database.createDefaultList(uid: uid, completion: { (defaultList, defaultListId) in
            CurrentUser.lists = defaultList
            CurrentUser.listIds = defaultListId
            CurrentUser.user?.listIds = defaultListId
            print(" 4 | FETCH_CURRENT_USER |Fetch User Lists | Default Lists | \(CurrentUser.user?.username) created \(CurrentUser.lists.count) lists")
            completion()
        })
    }
    
    
    
    static func fetchUserLikedPostIds(uid: String?, completion:@escaping ([String: Double]) ->()){
        guard let uid = uid else {return}
        
        Database.database().reference().child("userlikes").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let temp = snapshot.value as? [String: Double] ?? [:]
            completion(temp)
            print("updateCurrentUserLikedPostIds \(uid) \(temp.count)")

            
        }) { (error) in
            print("Error updateCurrentUserLikedPostIds ", error)
        }
        
        
    }
    
    static func updateCurrentUserList(uid: String?, completion:@escaping () ->()){
        // 4. FIND USER LISTS AFTER USER IS LOADED
        
        guard let uid = uid else {return}
        
        let fetchedUser = DispatchGroup()
        fetchedUser.enter()
        
        Database.fetchCreatedListIds(userUid: uid, completion: { (listIdDict) in
            
            var tempList: [String] = []
            
            for (key,value) in listIdDict ?? [:] {
                tempList.append(key)
            }
            
            if tempList.count > 0 {
                Database.fetchListForMultListIds(listUid: tempList, completion: { (fetchedLists) in
                    
                    if uid == Auth.auth().currentUser?.uid {
                        CurrentUser.listIds = tempList
                        CurrentUser.lists = fetchedLists
                        CurrentUser.updateCurrentUserListPostIds()
                        Database.checkUserSocialStats(user: CurrentUser.user!, socialField: .lists_created, socialCount: fetchedLists.count)
                    }
                    
                    print(" 4 | FETCH_CURRENT_USER |Fetch User Lists | \(uid) fetched \(fetchedLists.count) lists")
                    fetchedUser.leave()
                })
            } else {
                fetchedUser.leave()

//                // No lists - Creating Default Legit Bookmark Lists
//                self.initDefaultList(uid: uid, completion: {
//                    print(" 4 | FETCH_CURRENT_USER |Init Default Lists | \(uid) created 2 Default lists")
//                    fetchedUser.leave()
//                })
            }
        })
 
        // 5. FIND USER FOLLOWED LISTS AFTER USER IS LOADED
        
        fetchedUser.enter()
        Database.fetchFollowedListIDs(userUid: uid, completion: { (followListIds) in
            if followListIds.count > 0 {
                var followedListIdArray: [String] = []
                for list in followListIds {
                    followedListIdArray.append(list.listId)
                }
                
                Database.fetchListForMultListIds(listUid: followedListIdArray, completion: { (fetchedLists) in
                    
                    if uid == Auth.auth().currentUser?.uid {
                        CurrentUser.followedListIdObjects = followListIds
                        CurrentUser.followedListIds = followedListIdArray
                        CurrentUser.followedLists = fetchedLists
                    
                        print("*** Current User | Following LISTS - \(fetchedLists.count) Lists | \(followedListIdArray.count) List IDs")

                        
                        for list in fetchedLists {
                            guard let listId = list.id else {return}
                            if list.newNotifications.count > 0 && !CurrentUser.followedListNotifications.contains(listId) {
                                CurrentUser.followedListNotifications.append(listId)
                            }
                        }
                    }
                    

                    
                    // REFRESHES TAB NOTIFICATION COUNT
                    NotificationCenter.default.post(name: MainTabBarController.NewNotificationName, object: nil)
                    print("Trigger |  updateCurrentUserList | MainTabBarController.NewNotificationName")

                    // SET UP LISTENERS
                    Database.setupUserFollowedListListener(listIds: followListIds)
                    
                    print(" 5 | FETCH_CURRENT_USER | Followed Lists Notifications and Setup | UNREAD LIST NOTIFICATIONS: \(CurrentUser.followedListNotifications.count)")
                    fetchedUser.leave()
                })
            } else {
                print("updateCurrentUserList | \(uid) | Has 0 Followed List")
                fetchedUser.leave()
            }
        })
        
        fetchedUser.notify(queue: .main) {
            print("   ~ SUCCESS | updateCurrentUserList | \(uid) | \(CurrentUser.lists.count) Made Lists | \(CurrentUser.followedLists.count) Followed Lists")
            completion()
        }
        
    }
    
    static func summarizeNotification(event: Event?) {
        guard let event = event else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        guard let action = event.action else {return}
        guard let initUid = event.creatorUid else {return}
        guard let receiveUid = event.receiverUid else {return}
        
        if event.value == 0 {
            return
        }

        
        var dispatchGroup = DispatchGroup()
        dispatchGroup.enter()

    // INIT USER
        var initUser = "A User "
        dispatchGroup.enter()
        if initUid == uid {
            initUser = "You "
            dispatchGroup.leave()
        } else {
            Database.fetchUserWithUID(uid: initUid) { (user) in
                guard let user = user else {return}
                initUser = user.username
                initUser += " "
                dispatchGroup.leave()
            }
        }

    // ACTION - LIST OR LIKE
        var actionString = ""
        
        switch action {
        case .like:
            actionString = "liked"
        case .follow:
            actionString = "followed"
        case .bookmark:
            actionString = "added"
        case .comment:
            actionString = "commented"
        case .create:
            actionString = "created"
        default:
            actionString = ""
        }
        actionString += " "
        
    // RECEIVER
        var receiver = "another user"
        dispatchGroup.enter()

        if receiveUid == uid {
            receiver = "your "
            dispatchGroup.leave()
        } else {
            Database.fetchUserWithUID(uid: receiveUid) { (user) in
                guard let user = user else {return}
                receiver = user.username
                receiver += " "
                dispatchGroup.leave()
            }
        }

        
    // OBJECT
        var itemString = ""
        switch event.eventType {
        case .list:
            // Grid View
            itemString = "list"
        case .post:
            // List View
            itemString = "post"
        case .user:
            // Full Post View
            itemString = "user"
        default:
            itemString = ""
        }
        
        dispatchGroup.leave()

        
        dispatchGroup.notify(queue: .main) {
            var displayString = ""

        // NEW FOLLOWER
            if event.eventAction == .followUser {
                displayString = initUser + actionString + (receiveUid == uid ? "you" : receiver)
                print("FOLLOW | \(initUser)")

                print("FOLLOW | \(actionString)")

                print("FOLLOW | \(displayString)")
            }
                
        // NEW POST ADDED TO LIST
            else if event.eventAction == .addPostToList {
                var listNameString = ""
                if let selectedList = CurrentUser.followedLists.filter({$0.id == event.listId}).first {
                        print("Founds List Name | \(selectedList.name)")
                        listNameString = selectedList.name
                } else {
                    print("Can't Find List Name \(event.listId)")
                }
                displayString = initUser + actionString + receiver + itemString + listNameString
            }
            
            else {
                displayString = initUser + actionString + receiver + itemString
            }
            print(displayString)
            SVProgressHUD.showSuccess(withStatus: displayString)
            SVProgressHUD.dismiss(withDelay: 1)
        }
    }
    
//    static func setupUserListEventListeners(){
//        guard let creatoruid = Auth.auth().currentUser?.uid else {return}
//        print("AppDelegate | setupUserListEventListeners | \(creatoruid)")
//        
//    // NEW EVENT ON THE LIST USERS ARE FOLLOWING
//        let followRef = Database.database().reference().child("user_listEvent").child(creatoruid)
//        followRef.observe(DataEventType.childAdded) { (data) in
//            
//            guard let dictionary = data.value as? [String: Any] else {
//                return}
//            var tempEvent = Event.init(id: data.key, dictionary: dictionary)
//            
//            if !CurrentUser.listEvents.contains(where: { (event) -> Bool in
//                return event.id == tempEvent.id
//            }) {
//                print("setupUserListEventListeners | New Followed List Event | \n\(tempEvent)")
//                CurrentUser.listEvents.append(tempEvent)
//                self.summarizeNotification(event: tempEvent)
//                
//            // CLEAR CACHE TO FORCE RELOAD
//                if let listId = tempEvent.listId {
//                    listCache[listId] = nil
//                }
//                
//            // REFRESHES NOTIFICATION PAGE
//                NotificationCenter.default.post(name: UserEventViewController.refreshNotificationName, object: nil)
//                
//            // REFRESHES TAB NOTIFICATION COUNT
//                NotificationCenter.default.post(name: MainTabBarController.NewNotificationName, object: nil)
//                
//            // REFRESHES TAB LIST
//                NotificationCenter.default.post(name: TabListViewController.refreshListNotificationName, object: nil)
//                
//            }
//        }
//        
//    }
    
    static func filterEvents(events: [Event]?, filterSelf: Bool? = false) -> [Event] {
        guard let events = events else {return []}
        guard let uid = Auth.auth().currentUser?.uid else {return []}
        var tempEvents = events
        var unfollows = 0, selfAction = 0, dup = 0
        
        // Filter out unfollows
        tempEvents = tempEvents.filter { (event) -> Bool in
            return event.value == 1
        }
        unfollows = events.count - tempEvents.count
        
        // Filter your own actions
        if filterSelf!{
            tempEvents = tempEvents.filter { (event) -> Bool in
                return event.creatorUid != uid
            }
        }
        
        // Filter self actions - Creator Not Receiver
        tempEvents = tempEvents.filter { (event) -> Bool in
            return event.creatorUid != event.receiverUid
        }
        selfAction = unfollows - tempEvents.count


        // SORT BY DATE SO THAT FILTER USES THE LATEST EVENT FIRST
        tempEvents = tempEvents.sorted(by: { (p1, p2) -> Bool in
            return p1.eventTime.compare(p2.eventTime) == .orderedDescending
        })
        
        // Filter Ignore later duplicates
        var tempKeys:[String] = []
        var finalEvents: [Event] = []
        
        for event in tempEvents {
//            guard let id = event.creatorUid else {continue}
//            guard let action = event.action?.rawValue else {continue}
//            let value = String(event.value ?? 0)
//            let postId = event.postId ?? ""
//            let listId = event.listId ?? ""
//            let userId = event.receiverUid ?? ""
//
//            var key = id + action + value + postId + listId + userId
            
            if !tempKeys.contains(event.dupKey) {
                tempKeys.append(event.dupKey)
                finalEvents.append(event)
            }
        }
        dup = selfAction - finalEvents.count
        var unread = finalEvents.filter({$0.read == false}).count

//        print("filterEvents | \(events.count) To \(finalEvents.count) | Unread: \(unread) | FilterSelf: \(filterSelf)")
        return finalEvents
    }
    
    static func setupEventListeners(){
        guard let creatoruid = Auth.auth().currentUser?.uid else {return}
        print("AppDelegate | setupEventListeners | \(creatoruid)")
        
    // USER EVENT - NEW USER/LIST FOLLOWS, NEW LIST TAGGING YOUR POST, NEW POST LIKES
        let ref = Database.database().reference().child("user_event").child(creatoruid)
        ref.observe(DataEventType.childAdded) { (data) in
            
            guard let dictionary = data.value as? [String: Any] else {
                return}
            var tempEvent = Event.init(id: data.key, dictionary: dictionary)
            
        // IGNORE READ NOTIFICATIONS OR NOTIFICATIONS CREATED BY USER
            if tempEvent.read || tempEvent.creatorUid == creatoruid || tempEvent.value == 0{
                return
            }
            
        // CHECK FOR REPEAT EVENT ID
            if CurrentUser.events.contains(where: {$0.id == tempEvent.id}) {
                return
            }
            
        // CHECK IF NEW EVENT HAS SIMILAR DUP KEY
//            if let index = CurrentUser.events.firstIndex(where: {$0.dupKey == tempEvent.dupKey}) {
//                // CHECK THAT EVENT ID IF HAS SAME DUPKEY HAS EVENT TIME LATER TO OVERRIDE
//                let curEvent = CurrentUser.events[index]
//                if curEvent.eventTime > tempEvent.eventTime {
//                    return
//                } else {
//                    print("Replacing Old Event | \(tempEvent.id) Replacing \(curEvent.id) | \(curEvent.dupKey)")
//                    CurrentUser.events[index] = tempEvent
//                }
//            } else {
//                // NEW EVENT
//                CurrentUser.events.append(tempEvent)
//            }
//
            var tempEvents = CurrentUser.events
            tempEvents.append(tempEvent)
        // USER FILTER FUNCTION TO TAKE OUT DUPS
            CurrentUser.events = Database.filterEvents(events: tempEvents, filterSelf: true)
            
            if CurrentUser.events.contains(where: {$0.id == tempEvent.id}) {
                
                if tempEvent.isUserFollow {
                    // CLEAR CACHE AFTER USER FOLLOW TO FORCE RELOAD
                    if let creatorUid = tempEvent.creatorUid {
                        userCache[creatorUid] = nil}
                    
                    if let receiveUid = tempEvent.receiverUid {
                        userCache[receiveUid] = nil}
                    
                    print("setupUserListEventListeners | New User Follow | Cleared Creator and Receiver Caches")
                    // REFRESHES USER PROFILE FOR NEW FOLLOWS ETC
                    NotificationCenter.default.post(name: UserProfileController.RefreshNotificationName, object: nil)
                }
                
                // REFRESHES NOTIFICATION PAGE
                print("setupEventListeners | New User Event | \n Init \(tempEvent.id) | \(tempEvent.creatorUid) \(tempEvent.eventAction) \(tempEvent.receiverUid) : \(tempEvent.eventType)")
//                self.summarizeNotification(event: tempEvent)
                NotificationCenter.default.post(name: UserEventViewController.refreshNotificationName, object: nil)

            }
            
            

        }
    }
    
    
    static func setupInboxListeners(){
        guard let creatoruid = Auth.auth().currentUser?.uid else {return}
        print("AppDelegate | setupInboxListeners | \(creatoruid)")

        let inboxRef = Database.database().reference().child("inbox").child(creatoruid)
        inboxRef.observe(DataEventType.childAdded) { (data) in
            guard let newData = data.value as? [String:Any]  else {return}
            print("New Inbox Thread : ", data.key)
//            let newThread = MessageThread.init(threadID: data.key, dictionary: data.value)
            Database.fetchMessageThreadsForUID(userUID: creatoruid) { (threads) in
                CurrentUser.inboxThreads = threads
                NotificationCenter.default.post(name: InboxController.newMsgNotificationName, object: nil)
                print("New Inbox Message For \(creatoruid)")
            }
        }
        
        
        Database.fetchMessageThreadsForUID(userUID: creatoruid) { (messageThreads) in
            for thread in messageThreads {
                let threadId = thread.threadID
                let ref = Database.database().reference().child("messageThreads").child(threadId)

                ref.observe(DataEventType.childChanged) { (data) in
                    
                    guard let newData = data.value as? [String:Any]  else {return}
                    print("New Inbox Message : ", data.key)
                    
                    guard let threadDictionary = data.value as? [String: Any] else {return}
                    
                    var tempThread = MessageThread.init(threadID: threadId, dictionary: threadDictionary)
                    
                    var tempInboxThreads: [MessageThread] = CurrentUser.inboxThreads
                    tempInboxThreads.removeAll { (thread) -> Bool in
                        thread.threadID == tempThread.threadID
                    }
                    
                    tempInboxThreads.append(tempThread)
                    CurrentUser.inboxThreads = tempInboxThreads
                    NotificationCenter.default.post(name: InboxController.newMsgNotificationName, object: nil)
                    print("New Inbox Message For Thread \(threadId)")
                }
            }
        }
        
    }
    
    static func fetchCurrentUserAllPostIds(completion: @escaping ([PostId]) -> ()){
        var tempPostIds: [PostId] = []
        var fetchingUids: [String] = []
        
        var uid = Auth.auth().currentUser?.uid
        
        if (Auth.auth().currentUser?.isAnonymous)! {
            print("Guest User, default to WZ stream")
            uid = "2G76XbYQS8Z7bojJRrImqpuJ7pz2"
        } else {
            uid = Auth.auth().currentUser?.uid
        }
        fetchingUids.append(uid!)
        
        let fetchUserIdGroup = DispatchGroup()
        let fetchPostIdGroup = DispatchGroup()
        
        fetchUserIdGroup.enter()
        if CurrentUser.followingUids.count == 0 {
            // Re-fetch Following Uids
            Database.fetchFollowingUserUids(uid: uid!) { (fetchedFollowingUsers) in
                CurrentUser.followingUids = fetchedFollowingUsers
                fetchingUids += CurrentUser.followingUids
                fetchUserIdGroup.leave()
            }
        } else {
            fetchingUids += CurrentUser.followingUids
            fetchUserIdGroup.leave()
        }
        

        fetchUserIdGroup.notify(queue: .main) {
            print("Fetching Post Ids for \(fetchingUids.count) Users")
            for userId in fetchingUids {
                fetchPostIdGroup.enter()
                Database.fetchAllPostIDWithCreatorUID(creatoruid: userId) { (postIds) in
//                    print("Fetched Post Ids | \(userId) | \(postIds.count) Post Ids")
                    tempPostIds = tempPostIds + postIds
                    fetchPostIdGroup.leave()
                }
            }
            
            
            fetchPostIdGroup.notify(queue: .main) {
                Database.checkDisplayPostIdForDups(postIds: tempPostIds, completion: { (postIds) in
                    tempPostIds = postIds
                    print("fetchCurrentUserAllPostIds | Fetched Post Ids: \(tempPostIds.count)")
                    completion(tempPostIds)
                })
            }
        }
        

    }
        
    

    static func checkDisplayPostIdForDups(postIds: [PostId], completion: @escaping ([PostId]) -> ()) {
        var dup = 0
        var tempPostId: [PostId] = []
        
//        for postId in postIds {
//            let postIdCheck = postId.id
//            if !tempPostId.contains(where: { (postId) -> Bool in
//                postId.id == postIdCheck
//            }){
//                tempPostId.append(postId)
//            } else {
//                dup += 1
//            }
//        }
//        
//        if dup > 0 {
//            print("Deleted from fetchPostIds Dup Post ID: ", dup)
//        }

        tempPostId = Array(Set(postIds))
        completion(tempPostId)
    }
    
    
    
// Alerts
    static func alert(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        
        var topController = UIApplication.shared.keyWindow!.rootViewController as! UIViewController
        
        while ((topController.presentedViewController) != nil) {
            topController = topController.presentedViewController!;
        }
        topController.present(alert, animated:true, completion:nil)
    }
    
    
// MARK: - FETCHING USERS

    static func fetchUserWithUID(uid: String, forceUpdate: Bool = false, completion: @escaping (User?) -> ()) {
        
//        Database.updateSocialCounts(uid: uid)
        if let _ = Auth.auth().currentUser {
            if ((Auth.auth().currentUser?.isAnonymous)! && uid == Auth.auth().currentUser?.uid){
                print("Fetching For Guest User Uid. Returning Guest User Profile")
                if CurrentUser.user == nil {
                    let tempUser = User.init(uid: uid, dictionary: ["username":"guest"])
                    CurrentUser.user = tempUser
                    completion(tempUser)
                } else {
                    completion(CurrentUser.user)
                }
            }
        }
        
        if uid == "" {
            completion(nil)
            return
        }
        
        if !forceUpdate {
            if let cachedUser = userCache[uid] {
                if cachedUser != nil {
//                    print("fetchUserWithUID | Cache | \(uid)")
                    completion(cachedUser)
                    return
                }
            }
        }

        let userRef = Database.database().reference().child("users").child(uid)
        
        userRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let userDictionary = snapshot.value as? [String:Any] else {
                completion(nil)
                return}
            let user = User(uid:uid, dictionary: userDictionary)
            self.checkUserIsFollowed(user: user, completion: { (user) in
                userCache[uid] = user
                completion(user)
            })
        }) {(err) in
            print("Failed to fetch user for posts:",err)
            completion(nil)
        }
        userRef.keepSynced(true)
    }
    
    static func fetchALLUsers(includeSelf: Bool = false, completion: @escaping ([User]) -> ()) {
        let start = DispatchTime.now()   // <<<<<<<<<<   end time
        
        var tempUsers: [User] = []
        let myGroup = DispatchGroup()
        let ref = Database.database().reference().child("users")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionaries = snapshot.value as? [String: Any] else {return}
            
            dictionaries.forEach({ (key,value) in
                myGroup.enter()
                if key == Auth.auth().currentUser?.uid && !includeSelf{
                    print("fetchALLUsers | Found Myself, omit from list")
                    myGroup.leave()
                    return
                }
                
                guard let userDictionary = value as? [String: Any] else {return}
                var user = User(uid: key, dictionary: userDictionary)
                
                if CurrentUser.followingUids.contains(key){
                    user.isFollowing = true
                } else {
                    user.isFollowing = false
                }
                
                user.isBlockedByCurUser = CurrentUser.blockedUsers[key] != nil
                user.isBlockedByUser = user.blockedUsers[(Auth.auth().currentUser?.uid)!] != nil

                if user.username != "" && !user.isBlockedByUser {
                    tempUsers.append(user)
                }
                myGroup.leave()
                
            })
            
            myGroup.notify(queue: .main) {
                tempUsers.sort(by: { (u1, u2) -> Bool in
                    return u1.username.compare(u2.username) == .orderedAscending
                })
                allUsersFetched = tempUsers
                
                
                let end = DispatchTime.now()   // <<<<<<<<<<   end time
                let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
                let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests

                print("   ~ Database | Fetch All Users | \(tempUsers.count) Users | \(allUsersFetched.count) allUsersFetched-MEMORY | Time: \(timeInterval) seconds")
                
                completion(tempUsers)
            }
        })   { (err) in print ("Failed to fetch users for search", err) }

    }
    
    static func fetchFollowingUsers(uid: String?, completion: @escaping ([User]) -> ()) {
        print("   ~ Database | Fetching Users Following \(uid) ")

        guard let uid = uid else {return}
        var tempUsers: [User] = []
        let myGroup = DispatchGroup()
        myGroup.enter()
        self.fetchFollowingUserUids(uid: uid) { (followingIds) in
            if uid == CurrentUser.uid {
                print("Set Following UIDS for Current User :", uid , "fetchFollowingUsers")
                CurrentUser.followingUids = followingIds
            }
            if followingIds.count == 0 {
                completion([])
            } else {
                for id in followingIds {
                    myGroup.enter()
                    self.fetchUserWithUID(uid: id) { (user) in
                        if let fetchedUser = user {
                            tempUsers.append(fetchedUser)
                        }
                        myGroup.leave()
                    }
                }
            }
            myGroup.leave()
        }
        
        myGroup.notify(queue: .main) {
            tempUsers.sort(by: { (u1, u2) -> Bool in
                return u1.username.compare(u2.username) == .orderedAscending
            })
            print("   ~ Database | Fetch Users Following \(uid) | \(tempUsers.count) Users")
            completion(tempUsers)
        }

    }
    
    static func fetchFollowingUserUids(uid: String, completion: @escaping ([String]) -> ()) {
        
        var followingUsers: [String] = []
        var followingRef = Database.database().reference().child("following").child(uid)
        
        followingRef.child("following").observeSingleEvent(of: .value, with: { (snapshot) in
            
            let followingUserList = snapshot.value as? [String: Int] ?? [:]
            
            followingUserList.forEach({ (key,value) in
                if value == 1{
                    followingUsers.append(key)
                } else {
                    print("Error: User Id in Following List is not 1")
                    return
                }
            })
            print("\(uid) Following \(followingUsers.count) Users")
            followingRef.keepSynced(true)
            completion(followingUsers)
            
        }) { (error) in
            print("Error fetching following user uids: ", error)
        }
    }
    
    static func fetchFollowerUserUids(uid: String, completion: @escaping ([String]) -> ()) {
        
        var followerUsers: [String] = []
        
        Database.database().reference().child("follower").child(uid).child("follower").observeSingleEvent(of: .value, with: { (snapshot) in
            
            let followerUserList = snapshot.value as? [String: Int] ?? [:]
            
            followerUserList.forEach({ (key,value) in
                if value == 1{
                    followerUsers.append(key)
                } else {
                    print("Error: User Id in Following List is not 1")
                    return
                }
            })
            print("User: \(uid) is Followed by \(followerUsers.count) Users")
            completion(followerUsers)
            
        }) { (error) in
            print("Error fetching following user uids: ", error)
        }
    }
    
    static func fetchUserWithUsername(username: String, completion: @escaping (User?, Error?) -> ()) {
        var tempUserName = "@"
        tempUserName += username.replacingOccurrences(of: "@", with: "").capitalizingFirstLetter()
        
        
        
        var cacheUserFound = userCache.first { (uid, user) -> Bool in
            return user.username == username
        }?.value
        
        if let cacheUser = cacheUserFound {
            print("Found Cache User For \(username) : \(cacheUser.uid) - \(cacheUser.username) | fetchUserWithUsername")
            completion(cacheUser, nil)
            return
        }

        let myGroup = DispatchGroup()
        var query = Database.database().reference().child("users").queryOrdered(byChild: "username").queryEqual(toValue: username)
        var user: User?
        
        query.observe(.value, with: { (snapshot) in
            
//            print(snapshot)
            guard let queryUsers = snapshot.value as? [String: Any] else {
                completion(nil,nil)
                return}
            queryUsers.forEach({ (key,value) in
                
                myGroup.enter()
                guard let dictionary = value as? [String: Any] else {return}
                
                user = User(uid: key, dictionary: dictionary)
                myGroup.leave()
            })
            myGroup.notify(queue: .main) {
                print("Found User For \(username) : \(user!.uid) | fetchUserWithUsername")
                completion(user!, nil)
            }
        }) { (err) in
            print("Failed to fetch user for Username", err)
            completion(nil, err)
        }
    }
    
//  Update Current User Most Used
    static func refreshCurrentUserMostUsed(posts: [Post], completion: @escaping () -> ()){
        guard let uid = Auth.auth().currentUser?.uid else {return}
        var tempPost = posts.filter { post in
            return post.creatorUID == uid
        }
        self.countMostUsedEmojis(posts: tempPost) { emojis in
            CurrentUser.mostUsedEmojis = emojis
        }
        self.countMostUsedCities(posts: tempPost) { cities in
            CurrentUser.mostUsedCities = cities
        }
        completion()
    }

    
//    Most Used Emojis
    static func countMostUsedEmojis(posts: [Post], completion: ([String]) -> ()) {
        
        var tempEmojis:[String] = []
        var mostUsedEmojis: [String] = []
        
        for post in posts {
            if post.nonRatingEmoji.count > 0 {
                for emoji in post.nonRatingEmoji {
                    tempEmojis.append(emoji)
                }
            }
        }
        
        var emojiCount = tempEmojis.reduce(into: [:]) { $0[$1, default: 0] += 1 }
        
        //        print("EMOJI COUNT: ", emojiCount.sorted(by: { $0.value > $1.value }))
        for (key,value) in emojiCount.sorted(by: { $0.value > $1.value }) {
            mostUsedEmojis.append(key)
        }
        
        completion(mostUsedEmojis)
    }

//    Most Used Cities
    static func countMostUsedCities(posts: [Post], completion: ([String]) -> ()) {
        
        var tempCities:[String] = []
        var mostUsedCities: [String] = []
        
        for post in posts {
            if let city = post.locationSummaryID {
                if !city.isEmptyOrWhitespace() {
                    tempCities.append(city)
                }
            }
        }
        
        var cityCount = tempCities.reduce(into: [:]) { $0[$1, default: 0] += 1 }
        
        //        print("EMOJI COUNT: ", emojiCount.sorted(by: { $0.value > $1.value }))
        for (key,value) in cityCount.sorted(by: { $0.value > $1.value }) {
            mostUsedCities.append(key)
        }
        
        completion(mostUsedCities)
    }
    
    static func averageRating(posts: [Post]?) -> (Double) {
        
        guard let posts = posts else {return 0.0}
        var tempRating = 0.0
        var sumRating = 0.0
        var countRating = 0.0
        for post in posts {
            if post.rating ?? 0.0 > 0.0 {
                sumRating += post.rating ?? 0.0
                countRating += 1.0
            }
        }
        
        if countRating > 0 {
            tempRating = sumRating/countRating
        }
        
        return tempRating
    }
    

    static func summarizePostTags(posts: [Post]?, completion: (PostTagCounts) -> ()) {
        
        var ratingEmojiCounts: [String: Int] = [:]
        var captionCounts: [String: Int] = [:]
        var autotagCounts: [String:Int] = [:]
        var locationCounts: [String: Int] = [:]
        var cityCounts: [String: Int] = [:]
        var allCounts: [String: Int] = [:]

        var arrayCounts = [ratingEmojiCounts, captionCounts, autotagCounts, locationCounts, cityCounts, allCounts]
        var tagCounts = PostTagCounts.init()
        
        
        guard let posts = posts else {
            completion(tagCounts)
            return
        }
        
        for post in posts {
            // Rating Emoji
            if let ratingEmoji = post.ratingEmoji {
                if ratingEmoji.removingWhitespaces() != ""
                {
                    if let curCount = ratingEmojiCounts[ratingEmoji] {
                        ratingEmojiCounts[ratingEmoji]! += 1
                        allCounts[ratingEmoji]! += 1
                    } else {
                        ratingEmojiCounts[ratingEmoji] = 1
                        allCounts[ratingEmoji] = 1
                    }
                }
                
            }
            
            
            // NON RATING EMOJIS
            if post.nonRatingEmoji.count > 0 {
                for emoji in post.nonRatingEmoji {
                    if let curCount = captionCounts[emoji] {
                        captionCounts[emoji]! += 1
                        allCounts[emoji]! += 1
                    } else {
                        captionCounts[emoji] = 1
                        allCounts[emoji] = 1
                    }
                }
            }
            
            // AUTO TAGS
            if post.autoTagEmoji.count > 0 {
                for string in post.autoTagEmoji {
                    if let curCount = autotagCounts[string] {
                        autotagCounts[string]! += 1
                        allCounts[string]! += 1
                    } else {
                        autotagCounts[string] = 1
                        allCounts[string] = 1
                    }
                }
            }
        
            // RESTAURANT
            let name = post.locationName
            let googleId = post.locationGooglePlaceID ?? ""
            
            if name.removingWhitespaces() != "" && name != nil {
                let locationID = "\(name)"
                if let curCount = locationCounts[locationID] {
                    locationCounts[locationID]! += 1
                    allCounts[locationID]! += 1
                } else {
                    locationCounts[locationID] = 1
                    allCounts[locationID] = 1
                }
            }
            
        // ADD LOCATION NAME TO GOOGLE LOCATION ID DIC
            if googleId.removingWhitespaces() != "" && googleId != nil {
                locationGoogleIdDictionary[googleId] = name
            }
            
            // CITY
            if let locationID = post.locationSummaryID {
                if locationID != "" {
                    if let curCount = cityCounts[locationID] {
                        cityCounts[locationID]! += 1
                        allCounts[locationID]! += 1
                    } else {
                        cityCounts[locationID] = 1
                        allCounts[locationID] = 1
                    }
                }
            }
        }
        
        // SORT ARRAYS
        for array in arrayCounts {
            array.sorted { (key1, key2) -> Bool in
                return key1.value >= key2.value
            }
        }
        
        tagCounts.ratingEmojiCounts = captionCounts
        tagCounts.captionCounts = captionCounts
        tagCounts.autotagCounts = autotagCounts
        tagCounts.locationCounts = locationCounts
        tagCounts.cityCounts = cityCounts
        tagCounts.allCounts = allCounts

        completion(tagCounts)
        
    }

    static func countEmojis(posts: [Post]?, onlyEmojis: Bool = false, completion: ([String:Int]) -> ()) {
        
        // Emoji Tags use Emojis as keys, but auto tags (meal,cuisine,diet) use string instead
        var emojiCounts: [String: Int] = [:]
        guard let posts = posts else {
            completion([:])
            return
        }
        
        for post in posts {
            if post.nonRatingEmoji.count > 0 {
                for emoji in post.nonRatingEmoji {
                    if let curCount = emojiCounts[emoji] {
                        emojiCounts[emoji]! += 1
                    } else {
                        emojiCounts[emoji] = 1
                    }
                }
            }
            
            // We count the auto-tag string tags instead of the emoji to separate user tag vs auto-tags
            if post.autoTagEmojiTags.count > 0 && !onlyEmojis {
                for string in post.autoTagEmojiTags {
                    if let curCount = emojiCounts[string] {
                        emojiCounts[string]! += 1
                    } else {
                        emojiCounts[string] = 1
                    }
                }
            }
        }
        
        emojiCounts.sorted { (key1, key2) -> Bool in
            // Reverse Sort Emoji Counts and incrementally move them in front of sorted emoji array
            return key1.value >= key2.value
        }
        
        
        // REMOVE DUPS
        var finalEmojiCounts: [String: Int] = [:]

        for x in emojiCounts {
            let key = x.key ?? ""
            let curCount = finalEmojiCounts[key] ?? 0
            if key != "" {
                if curCount > 0 {
                    finalEmojiCounts[key] = curCount + x.value
                } else {
                    finalEmojiCounts[key] = x.value
                }
            }
        }
        
        
        completion(finalEmojiCounts)
    }
    

    static func summarizeRatings(posts: [Post]?, completion: ([Int:Int]) -> ()) {

        
        var tempRatingArray = RatingCountArray
        
        guard let posts = posts else {
            completion([:])
            return
        }
        
        for post in posts {
            let rating = post.rating ?? 0
            
            if rating == 5 {
                tempRatingArray[5]! += 1
            } else if rating >= 4.0 {
                tempRatingArray[4]! += 1
            } else if rating >= 3.0 {
                tempRatingArray[3]! += 1
            } else if rating >= 2.0 {
                tempRatingArray[2]! += 1
            } else if rating >= 1.0 {
                tempRatingArray[1]! += 1
            }
            
        }
        
//        print("summarizeRatings - \(tempRatingArray)")
        completion(tempRatingArray)
    }
    
    
    
    static func sortEmojisWithCounts(inputEmojis: [EmojiBasic]?, emojiCounts: [String:Int]?, defaultCounts: [String:Int]? = [:], dictionaryMatch: Bool = false, sort: Bool = true, fillMissing: Bool = false, completion: ([EmojiBasic]) -> ()) {
        
        // Food Emojis are tagged as Emojis but Auto-Tags are tagged as the dictionary string.
        // Dictionary Match allows the string to also add counts for the representative emojis, ie: flags, countries, cuisine
        
        guard let inputEmojis = inputEmojis else {
            print("sortEmojis ERROR: No Input Emojis")
            return
        }
        
        guard let emojiCounts = emojiCounts else {
            print("sortEmojis ERROR: No Emoji Counts ")
            completion(inputEmojis)
            return
        }
        
        if emojiCounts.count == 0 {
//            print("sortEmojis ERROR: 0 Emoji Counts")
            completion(inputEmojis)
            return
        }
        
        // REMOVES ALL INPUT EMOJI DUPS
        var tempEmojis = Array(Set(inputEmojis))
        var tempEmojiCounts = emojiCounts
        var tempDefaultEmojiCounts = defaultCounts ?? [:]

        
        // COMBINE EMOJI COUNTS FOR EMOJI == WORD LIKE FLAGS
        if dictionaryMatch {
            // Add Count for Dictionary String
            for (key,value) in tempEmojiCounts {
                // Look up flag Emoji for string. Add Flag Emoji Count to String Count
                if !key.containsOnlyEmoji {
                    if let emo = ReverseEmojiDictionary[key] {
                        if let _ = tempEmojiCounts[emo] {
                            tempEmojiCounts[emo]! += value
                        } else {
                            tempEmojiCounts[emo] = value
                        }
                    }
                }
                /*
                if let repEmoji = cuisineEmojiDictionary.key(forValue: key) {
                    tempEmojiCounts[key] = (tempEmojiCounts[key] ?? 0) + (tempEmojiCounts[repEmoji] ?? 0)
                }*/
            }
        }
            
        // MATCH INPUT EMOJIS WITH EMOJI COUNTS
        for (index,emoji) in tempEmojis.enumerated() {
            var element = tempEmojis.remove(at: index)
            element.count = tempEmojiCounts[emoji.emoji] ?? 0
            element.defaultCount = tempDefaultEmojiCounts[emoji.emoji] ?? 0
            tempEmojis.insert(element, at: index)
        }
        
        // ADD MISSING EMOJI COUNTS
        let tempEmojiCountsSort = tempEmojiCounts.sorted { (key1, key2) -> Bool in
            return key1.value < key2.value
        }
        
        for (key,value) in tempEmojiCounts {
            if let index = tempEmojis.firstIndex(where: { (emoji) -> Bool in
                return dictionaryMatch ? ((emoji.name == key)||(emoji.emoji == key)) : (emoji.emoji == key)
            }){
                let tempEmoji = tempEmojis.remove(at: index)
                tempEmojis.insert(tempEmoji, at: 0)
            }
        }
        
        

        // FILTER DUPS?
        
        
        // Sort
        if sort {
            tempEmojis.sort { (emoji1, emoji2) -> Bool in
                if emoji1.count == emoji2.count {
                    return emoji1.defaultCount >= emoji2.defaultCount
                } else {
                    return emoji1.count >= emoji2.count
                }
            }
            /*
            // Reverse Sort
            let tempEmojiCountsSort = tempEmojiCounts.sorted { (key1, key2) -> Bool in
                return key1.value < key2.value
            }
            
            for (key,value) in tempEmojiCountsSort {
                if let index = tempEmojis.firstIndex(where: { (emoji) -> Bool in
                    return dictionaryMatch ? (emoji.name == key) : (emoji.emoji == key)
                }){
                    let tempEmoji = tempEmojis.remove(at: index)
                    tempEmojis.insert(tempEmoji, at: 0)
                }
            }
 */
            
        }
        



        completion(tempEmojis)
    }
    
    static func sortEmojisWithCounts(inputEmojis: [String]?, emojiCounts: [String:Int]?, dictionaryMatch: Bool = false, completion: ([String]) -> ()) {
        
        // Food Emojis are tagged as Emojis but Auto-Tags are tagged as the dictionary string.
        // Dictionary Match allows the string to also add counts for the representative emojis, ie: flags, countries, cuisine
        
        guard let inputEmojis = inputEmojis else {
            print("sortEmojis ERROR: No Input Emojis")
            completion([])
            return
        }
        
        guard let emojiCounts = emojiCounts else {
            print("sortEmojis ERROR: No Emoji Counts ")
            completion(inputEmojis)
            return
        }
        
        if emojiCounts.count == 0 {
            print("sortEmojis ERROR: 0 Emoji Counts")
            completion(inputEmojis)
            return
        }
        
        // REMOVES ALL INPUT EMOJI DUPS
        var tempEmojis: [String] = []
        var tempEmojiCounts = emojiCounts

        
        // COMBINE EMOJI COUNTS FOR EMOJI == WORD LIKE FLAGS
        if dictionaryMatch {
            // Add Count for Dictionary String
            for (key,value) in tempEmojiCounts {
                // Look up flag Emoji for string. Add Flag Emoji Count to String Count
                if !key.containsOnlyEmoji {
                    if let emo = ReverseEmojiDictionary[key] {
                        if let _ = tempEmojiCounts[emo] {
                            tempEmojiCounts[emo]! += value
                        } else {
                            tempEmojiCounts[emo] = value
                        }
                    }
                }
                /*
                if let repEmoji = cuisineEmojiDictionary.key(forValue: key) {
                    tempEmojiCounts[key] = (tempEmojiCounts[key] ?? 0) + (tempEmojiCounts[repEmoji] ?? 0)
                }*/
            }
        }
            

        // ADD MISSING EMOJI COUNTS
        let tempEmojiCountsSort = tempEmojiCounts.sorted { (key1, key2) -> Bool in
            return key1.value < key2.value
        }
        
        for (key,value) in tempEmojiCounts {
            if inputEmojis.contains(key) {
                tempEmojis.append(key)
            }
        }
        
        
    // FILL IN THE REST
        for x in inputEmojis {
            if !tempEmojis.contains(x) {
                tempEmojis.append(x)
            }
        }

        



        completion(tempEmojis)
    }
    
   
    
// LOCATION COUNTS
    
//    static func countAllNoFilter(posts: [Post]?, completion: ([String:Int],[String:Int],[String:Int]) -> ()) {
//        
//        
//    }
    
    static func countCityIds(posts: [Post]?, completion: ([String:Int]) -> ()) {
        guard let posts = posts else {
            completion([:])
            return
        }
        
        var locationCounts: [String: Int] = [:]
        
        for post in posts {
            if let locationID = post.locationSummaryID {
                if locationID != "" {
                    if let curCount = locationCounts[locationID] {
                        locationCounts[locationID]! += 1
                    } else {
                        locationCounts[locationID] = 1
                    }
                }
            }
        }
        locationCounts.sorted { (key1, key2) -> Bool in
            // Reverse Sort Emoji Counts and incrementally move them in front of sorted emoji array
            return key1.value >= key2.value
        }
        completion(locationCounts)
    }
    
    static func countLocationNames(posts: [Post]?, completion: ([String:Int]) -> ()) {
        guard let posts = posts else {
            completion([:])
            return
        }
        
        var locationCounts: [String: Int] = [:]
        
        for post in posts {
            let name = post.locationName
            let googleId = post.locationGooglePlaceID ?? ""
            
            if name.removingWhitespaces() != "" && name != nil {
                let locationID = "\(name)"
                if let curCount = locationCounts[locationID] {
                    locationCounts[locationID]! += 1
                } else {
                    locationCounts[locationID] = 1
                }
            }
            
        // ADD LOCATION NAME TO GOOGLE LOCATION ID DIC
            if googleId.removingWhitespaces() != "" && googleId != nil {
                locationGoogleIdDictionary[googleId] = name
            }

            
        
        }
        
        locationCounts.sorted { (key1, key2) -> Bool in
            // Reverse Sort Emoji Counts and incrementally move them in front of sorted emoji array
            return key1.value >= key2.value
        }
        completion(locationCounts)
    }
    
    static func addSortedLocationToDefault(defaultLocations: [String]?, locationCounts: [String:Int]?, completion: ([String]) -> ()) {
        
        guard let defaultLocations = defaultLocations else {
            print("addSortedLocationToDefault ERROR: No defaultLocations")
            return
        }
        
        guard let locationCounts = locationCounts else {
            print("addSortedLocationToDefault ERROR: No locationCounts")
            completion(defaultLocations)
            return
        }
        
        var tempLocations = defaultLocations
        
        if locationCounts.count > 0 {
            let sortedLocationCounts = locationCounts.sorted { (key1, key2) -> Bool in
                // Reverse Sort Emoji Counts and incrementally move them in front of sorted emoji array
                return key1.value <= key2.value
            }
            
            for (key,value) in sortedLocationCounts {
                if let index = tempLocations.firstIndex(where: { (locationName) -> Bool in
                    locationName == key
                }) {
                    let element = tempLocations.remove(at: index)
                    tempLocations.insert(element, at: 0)
                }
            }
            completion(tempLocations)
        } else {
            print("No Emoji Counts. Returning Original Emoji Inputs")
            completion(tempLocations)
        }
    }
    
    
// Fetch Emoji For Post Location

    static func extractPostLocationEmojis(googleLocationID: String?, completion: @escaping ([String]?) -> ()){
        guard let googleLocationID = googleLocationID else{
            print("Extract Post Location Emoji: ERROR, No GooglePlaceID")
            return
        }
        
        let myGroup = DispatchGroup()
        var freqEmojis: [String] = []
        
        let ref = Database.database().reference().child("postlocationsID").child(googleLocationID)
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            
            guard let emojis = snapshot.value as? [String: Int] else {
                completion(nil)
                return}
            emojis.sorted(by: { $0.value > $1.value })

            emojis.forEach({ (key,value) in
                myGroup.enter()
                freqEmojis.append(key)
                myGroup.leave()
            })
            
            myGroup.notify(queue: .main) {
                completion(freqEmojis)
            }
        })
    }
    
//    static func saveEmojiToLocation
    
    
// Fetch Bookmark Functions
    
    static func fetchAllBookmarkIdsForUID(uid: String, completion: @escaping ([BookmarkId]) -> ()) {
        
        let myGroup = DispatchGroup()
        var fetchedBookmarkIds = [] as [BookmarkId]
        
        let ref = Database.database().reference().child("users").child(uid).child("bookmarks").child("bookmarks")
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            
            guard let bookmarks = snapshot.value as? [String: Any] else {return}
            bookmarks.forEach({ (key,value) in
                myGroup.enter()
                //                print("Key \(key), Value: \(value)")
                guard let dictionary = value as? [String: Any] else {return}
                let bookmarkTime = dictionary["bookmarkDate"] as? Double ?? 0
                // Substitute Post Id creation date with bookmark time
                let tempId = BookmarkId.init(postId: key, fetchedBookmarkDate: bookmarkTime)
                fetchedBookmarkIds.append(tempId)
                myGroup.leave()
            })
            
            myGroup.notify(queue: .main) {
                completion(fetchedBookmarkIds)
            }
        })
    }
    
    static func fetchAllBookmarksForUID(uid: String, completion: @escaping ([Bookmark]) -> ()) {
        
        let myGroup = DispatchGroup()
        var tempBookmarks:[Bookmark] = []
        
        Database.fetchAllBookmarkIdsForUID(uid: uid) { (bookmarkIds) in
            
            for bookmarkId in bookmarkIds{
                myGroup.enter()
                Database.fetchPostWithPostID(postId: bookmarkId.postId, completion: { (post, error) in
                    if let error = error {
                        print("Failed to fetch post for bookmarks: ",bookmarkId.postId , error)
                        myGroup.leave()
                        return
                    } else if let post = post {
                        let tempBookmark = Bookmark.init(bookmarkDate: bookmarkId.bookmarkDate, post: post)
                        tempBookmarks.append(tempBookmark)
                        myGroup.leave()
                    } else {
                        print("No Result for PostId: ", bookmarkId.postId)
                        //Delete Bookmark since post is unavailable, Present Delete Alert
                        
                        let deleteAlert = UIAlertController(title: "Delete Bookmark", message: "Post Bookmarked on \(bookmarkId.bookmarkDate) Was Deleted", preferredStyle: UIAlertController.Style.alert)
                        
                        deleteAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                            // Delete Bookmark in Database
                            Database.handleBookmark(postId: bookmarkId.postId, creatorUid: nil, completion: {
                            })
                        }))
                        
                        UIApplication.shared.keyWindow?.rootViewController?.present(deleteAlert, animated: true, completion: nil)
                        myGroup.leave()
                    }
                })
            }
            
            myGroup.notify(queue: .main) {
                tempBookmarks.sort(by: { (p1, p2) -> Bool in
                    return p1.bookmarkDate.compare(p2.bookmarkDate) == .orderedDescending
                })
                completion(tempBookmarks)
            }
        }
    }
    
    
// MARK: - SAVE AND CREATE POSTS

//    Sequence
//    1. Save Post Image: Create Image URL
//    2. Save Post Dictionary with Image URL: create Post ID
//    3. Save Post Location in GeoFire with Post ID
//    4. Save Post ID to User Posts
//    5. Create List if Needed
//    6. Add PostId to List if Needed
    
    static func savePostToDatabase(uploadImages: [UIImage]?, uploadDictionary:[String:Any]?,uploadLocation: CLLocation?, lists:[List]?, completion:@escaping () ->()){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let creatorUID = uploadDictionary?["creatorUID"] as? String ?? ""
        
        if creatorUID != uid {
            print("ERROR savePostToDatabase - CREATOR NOT AUTH USER \(uid) \(creatorUID)")
        }

        guard let uploadImages = uploadImages else {
            print("Save Post: ERROR, No Image")
            return
        }
        guard let uploadDictionary = uploadDictionary else {
            print("Save Post: ERROR, No Upload Dictionary")
            return
        }
        
        let uploadTime = uploadDictionary["creationDate"] as! Double?
        
        // Save Image
        self.saveImageToDatabase(uploadImages: uploadImages, smallImage: true) { (imageUrls, smallImageUrl) in
            print("savePostToDatabase Image URL: ",imageUrls)
            print("savePostToDatabase Small Image URL: ",smallImageUrl)
            var tempDic = uploadDictionary
            tempDic["smallImageUrl"] = smallImageUrl
            
            self.savePostDictionaryToDatabase(imageUrls: imageUrls, uploadDictionary: tempDic, completion: { (postId) in
                
                self.savePostLocationToFirebase(postId: postId, uploadLocation: uploadLocation)
                self.savePostIdForUser(postId: postId, userId: uid, uploadTime: uploadTime)

                // Update Emoji Tags
                if let emojiTags = uploadDictionary["nonratingEmoji"] as! [String]? {
                    for emoji in emojiTags {
                        self.updatePostIdForTag(postId: postId, tag: emoji, add: 1)
                    }
                }
                

                // Update New Temp Post for instant reload
                var uploadValues = uploadDictionary
                uploadValues["imageUrls"] = imageUrls
                newPost = Post.init(user: CurrentUser.user!, dictionary: uploadValues)
                newPost?.id = postId
                newPostId = PostId.init(id: postId, creatorUID: uid, sort: nil)
//                print("New Post Temp Uploaded: ",newPost)
                
                
                //Update Cache
                postCache.removeValue(forKey: postId)
                postCache[postId] = newPost
                
                // Update Current User
                if CurrentUser.posts[postId] == nil {
                    var temp = PostId.init(id: postId, creatorUID: CurrentUser.uid, sort: 0)
                    CurrentUser.postIds.append(temp)
                    CurrentUser.posts[postId] = newPost
                    let ps = Array(CurrentUser.posts.values.map{ $0 }) as [Post]

                    Database.refreshCurrentUserMostUsed(posts:  ps) {
                    }
                    
                    if creatorUID == CurrentUser.uid {
                        Database.checkUserSocialStats(user: CurrentUser.user!, socialField: .posts_created, socialCount: CurrentUser.postIds.count)
                    }
                }
                
                let userDataDict:[String: String] = ["uid": uid, "postId": postId]
                NotificationCenter.default.post(name: MainTabBarController.newUserPost, object: nil, userInfo: userDataDict)
//                NotificationCenter.default.post(name: SharePhotoListController.updateFeedNotificationName, object: nil)
//                NotificationCenter.default.post(name: SharePhotoListController.updateProfileFeedNotificationName, object: nil)
//                NotificationCenter.default.post(name: SharePhotoListController.updateListFeedNotificationName, object: nil)
//                NotificationCenter.default.post(name: TabListViewController.refreshListNotificationName, object: nil)
                
                guard let newPost = newPost else {
                    completion()
                    return
                }
                
                // Update List
                if lists != nil {
                    if lists!.count > 0 {
                        for list in lists! {
                            self.addPostForList(post: newPost, postCreatorUid: uid, listId: list.id, postCreationDate: uploadTime, listName: list.name)
                        }
                    }
                }

                completion()
            })
        }
    }
    
    static func saveImageToDatabase(uploadImages:[UIImage]?, smallImage: Bool = false, completion: @escaping ([String], String) -> ()){
        
        guard let images = uploadImages else {
            self.alert(title: "Upload Post Requirement", message: "Please Insert Picture")
            return }
        

        var tempUrls = [String](repeating: "placeholder", count: (uploadImages?.count)!)
        var smallImageUrl: String = ""
        
        let myGroup = DispatchGroup()
        
        for (index,img) in images.enumerated() {
            
            
        // SAVE MAIN IMAGE IN STORAGE
            myGroup.enter()
            // No picture compression for best img quality - 90% gave the most marginal save
            guard let uploadData = img.resizeVI(newSize: defaultPhotoResize)!.jpegData(compressionQuality: 0.9) else {
                self.alert(title: "Upload Post Requirement", message: "Please Insert Picture")
                return}
            
            let imageId = NSUUID().uuidString
            let postStorage = Storage.storage().reference().child("posts").child(imageId)
            
            postStorage.putData(uploadData, metadata: nil) { (metadata, err) in
                if let err = err {
                    print("Save Post FULL Image: ERROR", err)
                    return
                }
                
                postStorage.downloadURL(completion: { (url, error) in
                    if let error = error {
                        print("Download FULL Image URL Error")
                        myGroup.leave()
                        return
                    }
                    
                    guard let imageUrl = url?.absoluteString else {return}
                    print("Save Post FULL Image: SUCCESS:",  imageUrl)
                    // Returns ImageURL
                    tempUrls[index] = imageUrl
                    myGroup.leave()
                })
            }

            
        // SAVE SMALL IMAGE IN STORAGE
            if index == 0 && smallImage{
                myGroup.enter()
                
                let smallImageId = NSUUID().uuidString
                let smallPostStorage = Storage.storage().reference().child("posts").child(smallImageId)

                let smallPhotoSize = CGSize(width: 50, height: 50)
                guard let smallImage = img.resizeVI(newSize: smallPhotoSize)!.jpegData(compressionQuality: 0.9) else {return}
                
                smallPostStorage.putData(smallImage, metadata: nil) { (metadata, err) in
                    if let err = err {
                        print("Save Post SMALL Image: ERROR", err)
                        return
                    }
                    
                    smallPostStorage.downloadURL(completion: { (url, error) in
                        if let error = error {
                            print("Download SMALL Image URL Error")
                            myGroup.leave()
                            return
                        }
                        
                        guard let imageUrl = url?.absoluteString else {return}
                        print("Save Post SMALL Image: SUCCESS:",  imageUrl)
                        // Returns ImageURL
                        smallImageUrl = imageUrl
                        myGroup.leave()
                    })
                }
            }
        }
        
        myGroup.notify(queue: .main) {
            if tempUrls.count != uploadImages?.count || tempUrls.contains("placeholder"){
                print("Image URLS count not matching Image Count OR Placeholder URL still exist")
                return
            } else {
                completion(tempUrls, smallImageUrl)
            }
        }
    }
    
    static func savePostDictionaryToDatabase(imageUrls: [String], uploadDictionary:[String:Any]?, completion: @escaping (String) -> ()){

        guard let uploadDictionary = uploadDictionary else {
            self.alert(title: "Upload Post Requirement", message: "Please Insert Post Dictionary")
            return
        }
        let userPostRef = Database.database().reference().child("posts")
        let postId = NSUUID().uuidString
        let ref = Database.database().reference().child("posts").child(postId)
        let uploadTime = Date().timeIntervalSince1970
        let uploadTimeDictionary = uploadDictionary["creationDate"]

        guard let uid = Auth.auth().currentUser?.uid else {return}

        var uploadValues = uploadDictionary
        uploadValues["imageUrls"] = imageUrls

        // SAVE POST IN POST DATABASE

        ref.updateChildValues(uploadValues) { (err, ref) in
            if let err = err {
                print("Save Post Dictionary: ERROR", err)
                return}

            print("Save Post Dictionary: SUCCESS")
//            Database.spotChangeSocialCountForUser(creatorUid: uid, socialField: "posts_created", change: 1)
            completion(postId)
//            // Put new post in cache
//            self.uploadnewPostCache(uid: uid,postid: ref.key, dictionary: uploadValues)

        }
    }
    
    static func savePostIdForUser(postId: String?, userId: String?, uploadTime: Double?){
        guard let postId = postId else {
            print("Save User PostID: ERROR, No Post ID")
            return
        }
        guard let userId = userId else {
            print("Save User PostID: ERROR, No User ID")
            return
        }
        guard let uploadTime = uploadTime else {
            print("Save User PostID: ERROR, No Upload Time")
            return
        }
        
        let userPostRef = Database.database().reference().child("userposts").child(userId).child(postId)
        let values = ["creationDate": uploadTime] as [String:Any]
        
        userPostRef.updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Save User PostID: ERROR, \(postId)", err)
                return
            }
            print("Save User PostID: SUCCESS, \(postId)")
        }
        
        
        
    }
    
    static func fetchAllCities(completion: @escaping ([City]) -> ()) {
        print("   ~ Database | START Fetch All Locations")
        var tempLocations: [City] = []
        let ref = Database.database().reference().child("cities")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([])
                return}
            
            dictionaries.forEach({ (key,value) in

                guard let locationDictionary = value as? [String: Any] else {
                    completion([])
                    return}
                var location = City.init(locationId: key, dictionary: locationDictionary)
                tempLocations.append(location)
            })
            
            print("   ~ Database | \(tempLocations.count) Locations | Fetch All Cities")
            completion(tempLocations)

        })   { (err) in print ("Failed to fetch all Cities", err) }

    }
    
    static func fetchAllLocations(completion: @escaping ([Location]) -> ()) {
        print("   ~ Database | START Fetch All Locations")
        var tempLocations: [Location] = []
        let ref = Database.database().reference().child("locations")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([])
                print("ERROR - No Dic : fetchAllLocations")
                return}
            
            dictionaries.forEach({ (key,value) in

                guard let locationDictionary = value as? [String: Any] else {
                    completion([])
                    print("ERROR - No Location Value : fetchAllLocations")
                    return}
                var location = Location.init(locationId: key, dictionary: locationDictionary)
                tempLocations.append(location)
            })
            
            print("   ~ Database | \(tempLocations.count) Locations | Fetch All Locations")
            completion(tempLocations)

        })   { (err) in print ("Failed to fetch all locations", err) }

    }
    
    static func fetchLocationWithLocID(locId: String?, force:Bool? = false, completion: @escaping (Location?) -> ()) {
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        var tempLoc: Location? = nil
        
        guard let locId = locId else {
            completion(nil)
            print("ERROR: No Loc ID : FetchLocationWithLocID")
            return
        }
        
        if locId.isEmptyOrWhitespace() {
            completion(nil)
            print("ERROR: Blank Loc ID : FetchLocationWithLocID \(locId)")
            return
        }

    //  TRIES CACHE FIRST IF NOT FORCE REFRESH
        if !force! {
            if let cachedLoc = locationCache[locId] {
                if cachedLoc != nil {
                    tempLoc = cachedLoc
                }
            }

            
            if tempLoc != nil {
                guard let tempLoc = tempLoc else {return}
                var cacheLoc = tempLoc
                // Update Post Distances
                if let curLoc = CurrentUser.currentLocation {
                    if let _ = tempLoc.locationGPS {
                        tempLoc.distance = Double((cacheLoc.locationGPS?.distance(from: curLoc))!)
                    } else {
                        tempLoc.distance = nil
                    }
                }
                
                completion(tempLoc)
                return
            }
        }
        
        let ref = Database.database().reference().child("locations").child(locId)
        
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
//                print("snapshot", snapshot.value)
                guard let dictionaries = snapshot.value as? [String: Any] else {
                    completion(nil)
                    print("ERROR - No Dic : fetchLocation")
                    return}
                
                var location = Location.init(locationId: locId, dictionary: dictionaries)
                locationCache[locId] = location
//                print("   ~ Database | \(tempLocations.count) Locations | Fetch All Locations")
                completion(location)
                

            })   { (err) in print ("Failed to fetch location: \(locId)", err) }
    }
    
    
    static func averageGPS(curGPS: CLLocation?, avgCount: Int?, newGPS: CLLocation?) -> (CLLocation?){
        
        
        guard let newGPSCoord = newGPS?.coordinate else {
            print("ERROR - No New GPS. Return Nil : averageGPS")
            return nil
        }
        
        guard let curGPSCoord = curGPS?.coordinate else {
            print("ERROR - No Current GPS. Return New GPS \(newGPSCoord) : averageGPS")
            return newGPS
        }
        
        print("Averaging GPS: \(avgCount) Locs| \(newGPSCoord) NewGPS | \(curGPSCoord) current GPS")
        
        if avgCount ?? 0 == 0 {
            print("No Other GPS, return New GPS: avergaeGPS")
            return newGPS
        }
        
        
        var n = Double(avgCount ?? 0)
        if n == 0.0 {
            return newGPS
        }
        
        let conv = Double.pi / 180
        
        let lat1 = curGPSCoord.latitude * conv
        let long1 = curGPSCoord.longitude * conv
        
        let x1 = cos(lat1) * cos(long1)
        let y1 = cos(lat1) * sin(long1)
        let z1 = sin(lat1)
        
        let lat2 = newGPSCoord.latitude * conv
        let long2 = newGPSCoord.longitude * conv
        
        let x2 = cos(lat2) * cos(long2)
        let y2 = cos(lat2) * sin(long2)
        let z2 = sin(lat2)
        
        var newX = (x1 * n + x2)
        var newY = (y1 * n + y2)
        var newZ = (z1 * n + z2)
        
        newX = newX / (n + 1)
        newY = newY / (n + 1)
        newZ = newZ / (n + 1)

        var newLong = atan2(newY, newX) / conv
        var newSquareRoot = sqrt(newX * newX + newY * newY)
        var newLat = atan2(newZ, newSquareRoot) / conv
        
        
        print("averageGPS: \(newLat),\(newLong) - \(n) Coords - Cur:  \(curGPSCoord.latitude) \(curGPSCoord.longitude) - New: \(newGPSCoord.latitude) \(newGPSCoord.longitude)")
        return CLLocation(latitude: newLat, longitude: newLong)
        
    }
    
    static func saveLocationToFirebase(post: Post?){
        
        var update = false
        guard let post = post else {return}
        guard let postId = post.id else {return}
        guard let googleLocationId = post.locationGooglePlaceID else {
            print("ERROR saveLocationToFirebase \(post.id) - No Google Location ID")
            return
        }
        if googleLocationId.isEmptyOrWhitespace() {
            print("ERROR saveLocationToFirebase \(post.id) - No Google Location ID")
            return
        }
        
        print("saveLocationToFirebase \(postId) | \(googleLocationId)")
        let locationRef = Database.database().reference().child("locations").child(googleLocationId)

        locationRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            var location = currentData.value as? [String : AnyObject] ?? [:]
            
            var locationName = location["locationName"] as! String? ?? ""
            if locationName.isEmptyOrWhitespace() && !post.locationName.isEmptyOrWhitespace() {
                location["locationName"] = post.locationName as AnyObject
                print(" \(location["locationName"]!) - Added Location Name to \(googleLocationId)")
                update = true
            }
            
            var locationAdress = location["locationAdress"] as! String? ?? ""
            if locationAdress.isEmptyOrWhitespace() && !post.locationAdress.isEmptyOrWhitespace() {
                location["locationAdress"] = post.locationAdress as AnyObject
                print(" \(location["locationAdress"]!) - Added Location Adress to \(googleLocationId)")
                update = true
            }
            
            var locationCity = location["locationCity"] as! String? ?? ""
            if locationCity.isEmptyOrWhitespace() && !(post.locationSummaryID ?? "").isEmptyOrWhitespace() {
                location["locationCity"] = post.locationSummaryID as AnyObject
                print(" \(location["locationCity"]!) - Added Location City to \(googleLocationId)")
                update = true
            }
            
            var locationGPS = location["locationGPS"] as! String? ?? ""
            if locationGPS.isEmptyOrWhitespace() && (post.locationGPS?.coordinate != nil) {
                var uploadedLocationGPSLatitude = String(format: "%f", (post.locationGPS!.coordinate.latitude))
                var uploadedlocationGPSLongitude = String(format: "%f", (post.locationGPS!.coordinate.longitude))
                var uploadedLocationGPS = uploadedLocationGPSLatitude + "," + uploadedlocationGPSLongitude
                location["locationGPS"] = uploadedLocationGPS as AnyObject
                print(" \(location["locationGPS"]!) - Added Location GPS to \(googleLocationId)")
                update = true
            }
            
            var locationImageUrl = location["imageUrl"] as! String? ?? ""
            if locationImageUrl.isEmptyOrWhitespace() && (post.imageUrls.count > 0) {
                location["imageUrl"] = post.imageUrls[0] as AnyObject
                print(" \(location["imageUrl"]!) - Added Image Url to \(googleLocationId)")
                update = true
            }
            
//            print(post.locationGoogleJSON?.rawValue)

            var locationGoogleJson = location["googleJson"] as! JSON?
            if (locationGoogleJson == nil) {
                Database.updateJsonForLocation(locId: googleLocationId) { (json) in
                    print("Updated JSON for \(googleLocationId) | saveLocationToFirebase")
                }
            }
            
            var postIds = location["postIds"] as! [String: Double]? ?? [:]
            if postIds[postId] == nil {
    // NEW POST FOR LOCATION ADD DETAILS
                let postCreationDate = post.creationDate.timeIntervalSince1970
                postIds[postId] = postCreationDate
                location["postIds"] = postIds as AnyObject

                var locationRecentDate = location["mostRecentDate"] as? Double ?? 0
                if locationRecentDate < postCreationDate {
                    location["mostRecentDate"] = postCreationDate as AnyObject
                }
                
                var postCount = (postIds.count) as! Int? ?? 0
                location["postCount"]  = postCount as AnyObject
                
                print("\(postId) - Added PostId to \(googleLocationId) - \(location["postCount"]!) Posts")
                
                var locationRating = location["rating"] as! Double? ?? 0.0
                if (post.rating ?? 0.0) > 0 {
                    var newRating = ((locationRating * Double(postCount) - 1) + (post.rating ?? 0))
                    location["rating"]  = newRating/Double(postCount) as AnyObject
                }
                
                
                var emojis = location["emojis"] as! [String: Int]? ?? [:]
                for emoji in post.nonRatingEmoji {
                    if let _ = emojis[emoji] {
                        emojis[emoji]! += 1
                    } else {
                        emojis[emoji] = 1
                    }
                    print("\(emoji) : \(emojis[emoji]!)- Added Emoji to \(googleLocationId)")
                }
                location["emojis"] = emojis as AnyObject
                
                var ratingEmojis = location["ratingEmojis"] as! [String: Int]? ?? [:]
                if post.ratingEmoji != nil {
                    let emoji = post.ratingEmoji ?? ""
                    if let _ = ratingEmojis[emoji] {
                        ratingEmojis[emoji]! += 1
                    } else {
                        ratingEmojis[emoji] = 1
                    }
                    print("\(emoji) : \(ratingEmojis[emoji]!)- Added Rating Emoji to \(googleLocationId)")
                }
                location["ratingEmojis"] = emojis as AnyObject
                
                update = true
                self.saveCityToFirebase(post: post)

            }
            
            
//            if !postIds.contains(postId) {
//                postIds.append(postId)
//                location["postIds"] = postIds as AnyObject
//
//                var postCount = location["postCount"] as! Int? ?? 0
//                location["postCount"]  = (postCount + 1) as AnyObject
//
//                var locationRecentDate = location["mostRecentDate"] as? Double ?? 0
//                if locationRecentDate < postCreationDate {
//                    location["mostRecentDate"] = postCreationDate as AnyObject
//                }
//
//                print("\(postId) - Added PostId to \(googleLocationId) - \(location["postCount"]) Posts")
//
//
//                var emojis = location["emojis"] as! [String: Int]? ?? [:]
//
//                for emoji in post.nonRatingEmoji {
//                    if let _ = emojis[emoji] {
//                        emojis[emoji]! += 1
//                    } else {
//                        emojis[emoji] = 1
//                    }
//                    print("\(emoji) : \(emojis[emoji]!)- Added Emoji to \(googleLocationId)")
//                }
//                location["emojis"] = emojis as AnyObject
//                update = true
//                self.saveCityToFirebase(post: post)
//            }
            else {
                print("\(postId) - Post Already Exist at \(googleLocationId) - \(location["postCount"]!) Posts")
            }
            
            // Set value and report transaction success
            if update {
                currentData.value = location
                print("Updating Location \(location["locationName"]!) \(googleLocationId) - | \(location["postCount"]!) Posts")
                return TransactionResult.success(withValue: currentData)
            } else {
                print("Location No Need Update")
                return TransactionResult.abort()
            }
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                NotificationCenter.default.post(name: MainTabBarController.newLocationUpdate, object: nil)
                print("Success: Updated Location \(post.locationName) \(googleLocationId)")
            }
        }
    }
    
    
    static func updateJsonForLocation(locId: String?, completion: @escaping (JSON?) -> ()) {
        guard let locId = locId else {
            completion(nil)
            return}
        
        if let json = locationGoogleJSONCache[locId] {
            completion(json)
        }
        
        Database.queryGooglePlaceID(placeId: locId) { (json) in
            guard let json = json else {
                print("NO JSON: \(locId)")
                completion(nil)
                return
            }
            
            Database.saveGoogleJsonForLocation(locId: locId, json: json)
            
            // Update Place Cache
            if let cachedLoc = locationCache[locId] {
                var tempLoc = cachedLoc
                cachedLoc.googleJson = json
                locationCache[locId] = cachedLoc
            }
            
            print("Updated JSON For \(locId) : updateJsonForLocation")
            completion(json)
        }
    }
    
    
    static func saveGoogleJsonForLocation(locId: String?, json: JSON?){
        guard let locId = locId else {
            print("ERROR: No Loc ID: saveGoogleJsonForLocation")
            return}
        guard let json = json else {
            print("ERROR: No JSON: \(locId) saveGoogleJsonForLocation")
            return}

        print("Updating Google JSON for \(locId)")
        let locationRef = Database.database().reference().child("locations").child(locId)

        locationRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            var location = currentData.value as? [String : AnyObject] ?? [:]
    
            var locationGoogleJson = JSON(location["googleJson"]) as? JSON? ?? nil
            if (locationGoogleJson == nil)  {
                location["googleJson"] = json.rawValue as AnyObject
                currentData.value = location
                print("Updating Google JSON for \(locId)")
                return TransactionResult.success(withValue: currentData)
            } else {
                print("Location No Need Update JSON")
                return TransactionResult.abort()
            }
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("Success: Updated Google JSON for \(locId)")
            }
        }
    }

    
    static func saveCityToFirebase(post: Post?){
        guard let post = post else {return}
        guard let postId = post.id else {return}
        guard let tempCity = post.locationSummaryID else {return}
        let tempCityName = tempCity.replacingOccurrences(of: ".", with: "")
        var city = tempCityName
        
        print("Saving City: \(city) from \(post.id)")
        
        if String(city.prefix(4)) == ", , " {
            city = String(city.dropFirst(4))
            print("Drop First 4 Chars: \(city) | From \(tempCityName)")
        }
        else if String(city.prefix(2)) == ", " {
            city = String(city.dropFirst(2))
            print("Drop First 2 Chars: \(city) | From \(tempCityName)")
        } 
                
        
//        print("saveCityToFirebase : \(city) : \(postId) ")
        if city.isEmptyOrWhitespace() {
            print("ERROR - No City in \(postId) | saveCityToFirebase")
            return
        }
                
        let locationRef = Database.database().reference().child("cities").child(city)
        locationRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
//            var postIds = location["postIds"] as! [String]? ?? []
//            if !postIds.contains(postId) {
//                postIds.append(postId)
//                location["postIds"] = postIds as AnyObject
//
//                var postCount = location["postCount"] as! Int? ?? 0
//                location["postCount"]  = (postCount + 1) as AnyObject
//                print("\(postId) - Added PostId to \(city) - \(location["postCount"]) Posts")
//
//                let postCreationDate = post.creationDate.timeIntervalSince1970
//                var locationRecentDate = location["mostRecentDate"] as? Double ?? 0
//                if locationRecentDate < postCreationDate {
//                    location["mostRecentDate"] = postCreationDate as AnyObject
//                }
//
//            }
            var location = currentData.value as? [String : AnyObject] ?? [:]
            var postIds = location["postIds"] as! [String: Double]? ?? [:]

            if postIds[postId] == nil {
                let postCreationDate = post.creationDate.timeIntervalSince1970
                postIds[postId] = postCreationDate
                location["postIds"] = postIds as AnyObject

                var locationRecentDate = location["mostRecentDate"] as? Double ?? 0
                if locationRecentDate < postCreationDate {
                    location["mostRecentDate"] = postCreationDate as AnyObject
                }
                
                var postCount = location["postCount"] as! Int? ?? 0
                location["postCount"] = (postIds.count) as AnyObject
                
                print("\(postId) - Added PostId to \(city) - \(location["postCount"]) Posts")

                var emojis = location["emojis"] as! [String: Int]? ?? [:]
                
                for emoji in post.nonRatingEmoji {
                    if let _ = emojis[emoji] {
                        emojis[emoji]! += 1
                    } else {
                        emojis[emoji] = 1
                    }
                    print("\(emoji) : \(emojis[emoji]!)- Added Emoji to \(city)")
                }
                location["emojis"] = emojis as AnyObject
                
                var locationIds = location["locationIds"] as! [String: Double]? ?? [:]
                
                if let locationId = post.locationGooglePlaceID {
                    if !locationId.isEmptyOrWhitespace() {
                        if locationIds[locationId] == nil {
                            locationIds[locationId] = 1
                        } else {
                            locationIds[locationId] = (locationIds[locationId]) ?? 0 + 1
                        }
                    }
                    location["locationIds"] = locationIds as AnyObject
                }
                location["locationCount"] = locationIds.count as AnyObject
                
                if let postLoc = post.locationGPS {
                    var tempCityGPS: CLLocation? = nil
                    var locationGPS = location["locationGPS"] as! String? ?? ""
                    var locationGPSCount = location["locationGPSCount"] as! Int? ?? 0
                    if !locationGPS.isEmptyOrWhitespace() {
                        let locationGPSTextArray = locationGPS.components(separatedBy: ",")
                        if locationGPSTextArray.count == 2 {
                            tempCityGPS = CLLocation(latitude: Double(locationGPSTextArray[0])!, longitude: Double(locationGPSTextArray[1])!)
                        }
                    }
                    tempCityGPS = Database.averageGPS(curGPS: tempCityGPS, avgCount: locationGPSCount, newGPS: postLoc)
                    
                    var uploadedLocationGPSLatitude = String(format: "%f", (tempCityGPS!.coordinate.latitude))
                    var uploadedlocationGPSLongitude = String(format: "%f", (tempCityGPS!.coordinate.longitude))
                    var uploadedLocationGPS = uploadedLocationGPSLatitude + "," + uploadedlocationGPSLongitude
                    location["locationGPS"] = uploadedLocationGPS as AnyObject
                    location["locationGPSCount"] = (locationGPSCount + 1) as AnyObject
                    print(" \(location["locationGPS"]!) Avg - Total \(location["locationGPSCount"]) GPS to \(city)")
                }
            }
            
            
            
            else {
                print("\(postId) - Post Already Exist at \(city) - \(location["postCount"]) Posts")
            }
            
            // Set value and report transaction success
            currentData.value = location
            print("Updating City \(city)  - | \(location["postCount"]!) Posts")
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print("ERROR : saveLocationToFirebase : \(error.localizedDescription)")
            } else {
                print("Successfully Updated City \(city)")
            }
        }
        
    }

    
    static func savePostLocationToFirebase(postId: String, uploadLocation: CLLocation?){
        guard let uploadLocation = uploadLocation else {
            print("No Upload Location Saved to Firebase for \(postId)")
            return
        }
        
        let geofireRef = Database.database().reference().child("postlocations")
//        guard let geoFire = GeoFire(firebaseRef: geofireRef) else {return}
        let geoFire = GeoFire(firebaseRef: geofireRef)
        
        geoFire.setLocation(uploadLocation, forKey: postId) { (error) in
            if (error != nil) {
                print("An error occured when saving Location \(uploadLocation) for Post \(postId) : \(error)")
            } else {
                print("Saved location successfully! for Post \(postId)")
            }
        }
    }
    
    static func updateUserDescription(userUid: String?, description: String?) {
        
        guard let userUid = userUid else {return}
        
        let updateValue = ["description":description]
        Database.database().reference().child("users").child(userUid).updateChildValues(updateValue) { (err, ref) in
            if let err = err {
                self.alert(title: "Update User Description Failed", message: "Failed To Update Description To:\n\(description)")
                print("Fail to Update Description: ", updateValue, err)
                return
            }
            else {

                if let user = userCache[userUid] {
                    // Update User Cache
                    userCache[userUid]?.description = description
                }
                
                print("Edit User Description and Cache | SUCCESS | ", updateValue)
            }
            
        }
        
    }
    
    
    static func updateUserStatus(userUid: String?, status: String?) {
        
        guard let userUid = userUid else {return}
        
        let updateValue = ["status":status]
        Database.database().reference().child("users").child(userUid).updateChildValues(updateValue) { (err, ref) in
            if let err = err {
                self.alert(title: "Update Status Failed", message: "Failed To Update Status To:\n\(status)")
                print("Fail to Update Status: ", updateValue, err)
                return
            }
            else {

                if let user = userCache[userUid] {
                    // Update User Cache
                    userCache[userUid]?.status = status
                }
                
                print("Edit User Status and Cache | SUCCESS | ", updateValue)
            }
            
        }
        
    }
    
    static func updateUserEmojiStatus(userUid: String?, emoji: String?) {
        
        guard let userUid = userUid else {return}
        
        let updateValue = ["emojiStatus":emoji]
        Database.database().reference().child("users").child(userUid).updateChildValues(updateValue) { (err, ref) in
            if let err = err {
                self.alert(title: "Update Status Emoji Failed", message: "Failed To Update Status To:\n\(emoji)")
                print("Fail to Update Status Emoji: ", updateValue, err)
                return
            }
            else {

                if let user = userCache[userUid] {
                    // Update User Cache
                    userCache[userUid]?.emojiStatus = emoji
                }
                
                print("Edit User Emoji Status and Cache | SUCCESS | ", updateValue)
            }
            
        }
        
    }

// Edit Posts Function
    static func editPostToDatabase(imageUrls: [String]?, postId: String?, uploadDictionary:[String:Any]?,uploadLocation: CLLocation?, prevPost: Post?, completion:@escaping (Post) ->()){
    
        //    1. Update Post Dictionary
        //    2. Update Post Geofire Location
        //    3. Update Emoji Tags
        //    4. Create List if Needed
        //    5. Add PostId to List if Needed
        
        guard let imageUrls = imageUrls else {
            print("Update Post: ERROR, No Image URL")
            return
        }
        
        guard let postId = postId else {
            print("Update Post: ERROR, No Post ID")
            return
        }
        
        guard let uploadDictionary = uploadDictionary else {
            print("Update Post: ERROR, No Post ID")
            return
        }
        
        guard let prevPost = prevPost else {
            print("Update Post: ERROR, No Previous Post")
            return
        }
        
        let userPostRef = Database.database().reference().child("posts").child(postId)
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        var uploadValues = uploadDictionary
        uploadValues["imageUrls"] = imageUrls


        // SAVE EDITED POST IN POST DATABASE
        userPostRef.updateChildValues(uploadValues) { (err, ref) in
            if let err = err {
                print("Update Post Dictionary: ERROR: \(postId)", err)
                return}
            
            print("Update Post Dictionary: SUCCESS: \(postId)")
        }
        
        // UPDATE LOCATION IN GEOFIRE
        savePostLocationToFirebase(postId: postId, uploadLocation: uploadLocation)
        
        // UPDATE EMOJI TAGS
        // Delete Preivous Emojis
        self.DeleteTagsForPost(post: prevPost)
        
        // Update Emoji Tags
        if let emojiTags = uploadDictionary["nonratingEmoji"] as! [String]? {
            for emoji in emojiTags {
                self.updatePostIdForTag(postId: postId, tag: emoji, add: 1)
            }
        }
        
        
        // Replace Post Cache
        var tempPost = Post.init(user: CurrentUser.user!, dictionary: uploadValues)
        tempPost.id = postId
        postCache[postId] = tempPost
        
        let postDict:[String: String] = ["updatedPostId": postId]
        NotificationCenter.default.post(name: MainTabBarController.editUserPost, object: nil, userInfo: postDict)
//        NotificationCenter.default.post(name: SharePhotoListController.updateFeedNotificationName, object: nil)
//        NotificationCenter.default.post(name: SharePhotoListController.updateProfileFeedNotificationName, object: nil)
//        NotificationCenter.default.post(name: SharePhotoListController.updateListFeedNotificationName, object: nil)

//            NotificationCenter.default.post(name: SharePhotoListController.updateListFeedNotificationName, object: nil)
//        let editPostId:[String: String] = ["editPostId": postId]
//        NotificationCenter.default.post(name: NewSinglePostView.editSinglePostNotification, object: nil, userInfo: editPostId)

        // Update New Post Cache
        newPost = tempPost
        newPost?.id = postId
        
        // UPDATE LISTS
        
        // Find Deleted List
        let currentList = uploadValues["lists"] as! [String:String]? ?? [:]
        let previousList = prevPost.creatorListId as! [String:String]? ?? [:]
        var deletedList: [String:String] = [:]
        var addedList: [String:String] = [:]
        let postCreationTime = uploadValues["creationDate"] as! Double?


        
        for (listId,listName) in previousList {
            if currentList[listId] != nil {
                // Is in current list ignore
            } else {
                deletedList[listId] = listName
            }
        }
        
        
        for (listId,listName) in currentList {
            if previousList[listId] != nil {
                // Is in previous list ignore
            } else {
                addedList[listId] = listName
            }
        }
        
        for (list, listname) in deletedList {
            Database.DeletePostForList(postId: tempPost.id, postCreatorUid: uid, listId: list, postCreationDate: postCreationTime)
        }
        
        for (list,listname) in addedList {
            let imageLink = uploadDictionary["smallImageLink"] as! String?
            Database.addPostForList(post: tempPost, postCreatorUid: uid, listId: list, postCreationDate: postCreationTime, listName: listname)
        }
        
        

        
        completion(tempPost)
    
    }
    

    
// MARK: - FETCHING POSTS

    static func fetchPostWithUIDAndPostID(creatoruid: String, postId: String, completion: @escaping (Post) -> ()) {
        Database.fetchUserWithUID(uid: creatoruid) { (user) in

            let ref = Database.database().reference().child("posts").child(postId)
            ref.observeSingleEvent(of: .value, with: {(snapshot) in

            guard let dictionary = snapshot.value as? [String: Any] else {return}
                var post = Post(user: user!, dictionary: dictionary)
                post.id = postId
                post.creatorUID = user?.uid
                completion(post)
                
        }) { (err) in print("Failed to fetchposts:", err) }
        }
    }
    
    static func fetchAllHomeFeedPostIds(uid: String?, first100:Bool = false, completion: @escaping ([PostId]) -> ()) {
        
        print("   ~ Database | fetchAllHomeFeedPostIds | \(uid) | First100: \(first100)")
        guard let uid = uid else {return}
        
        let myGroup = DispatchGroup()
        var fetchedPostIds = [] as [PostId]
        
        var fetchedSelf: Bool = false
        var fetchedFollowedUsers: Bool = false
        var fetchedFollowedLists: Bool = false
        
    // Fetching Self Post Ids
//        if first100 {
//            myGroup.enter()
//            Database.fetchAllPostIDWithCreatorUIDFirst100(creatoruid: uid) { (postIds) in
//                fetchedPostIds = fetchedPostIds + postIds
//                fetchedSelf = true
//                myGroup.leave()
//                print("Home | fetchAllHomeFeedPostIds | Current User  | First100: \(first100) | Post IDs: ", fetchedPostIds.count)
//            }
//        } else {
//            myGroup.enter()
//            Database.fetchAllPostIDWithCreatorUID(creatoruid: uid) { (postIds) in
//                fetchedPostIds = fetchedPostIds + postIds
//                fetchedSelf = true
//                myGroup.leave()
//                print("Home | fetchAllHomeFeedPostIds | Current User  | First100: \(first100) | Post IDs: ", fetchedPostIds.count)
//            }
//        }
        
        myGroup.enter()
        Database.fetchAllPostIDWithCreatorUID(creatoruid: uid) { (postIds) in
            fetchedPostIds = fetchedPostIds + postIds
            fetchedSelf = true
            myGroup.leave()
            print("Home | fetchAllHomeFeedPostIds | Current User  | First100: \(first100) | Post IDs: ", fetchedPostIds.count)
        }
        
        
    // Fetch User Friends
        myGroup.enter()
        Database.fetchAllFollowingUserPostIDforUser(uid: uid, first100: first100) { (postIds) in
            fetchedPostIds = fetchedPostIds + postIds
            fetchedFollowedUsers = true
            myGroup.leave()
            print("Home | fetchAllHomeFeedPostIds | Following Posts  | First100: \(first100) | Post IDs: ", fetchedPostIds.count)

        }

        
    // Fetch Followed List - Skip followed list for now due to load speed
//        myGroup.enter()
//        Database.fetchAllFollowingListPostIDforUser(uid: uid) { (postIds) in
//            fetchedPostIds = fetchedPostIds + postIds
//            fetchedFollowedLists = true
//            myGroup.leave()
//            print("Home | fetchAllHomeFeedPostIds | Following Lists | Post IDs: ", fetchedPostIds.count)
//        }

        myGroup.notify(queue: .main, execute: {
            self.checkDisplayPostIdForDups(postIds: fetchedPostIds, completion: { (postIds) in
                print("   ~ Database | fetchAllHomeFeedPostIds | First100: \(first100) | Fetched \(fetchedPostIds.count) PostIds | \(uid)")
                completion(postIds)
            })
            
        })
        
        
    }
    
    static func fetchAllFollowingUserPostIDforUser(uid: String, first100: Bool = false, completion: @escaping ([PostId]) -> ()) {
        let myGroup = DispatchGroup()
        var fetchedPostIds = [] as [PostId]
        var followingUserIds = [] as [String]
        
        myGroup.enter()

        Database.fetchFollowingUserUids(uid: uid) { (followingUids) in
            followingUserIds = followingUids
            
            if uid == Auth.auth().currentUser?.uid {
                CurrentUser.followingUids = followingUids
            }
            
            for id in followingUids {
                if first100 {
                    myGroup.enter()
                    Database.fetchAllPostIDWithCreatorUIDFirst100(creatoruid: id, completion: { (postIds) in
//                        print("fetchAllFollowingUserPostIDforUser \(id) - \(postIds.count) - \(first100)")
                        myGroup.leave()
                        fetchedPostIds += postIds
                    })
                } else {
                    myGroup.enter()
                    Database.fetchAllPostIDWithCreatorUID(creatoruid: id, completion: { (postIds) in
//                        print("fetchAllFollowingUserPostIDforUser \(id) - \(postIds.count) - \(first100)")
                        myGroup.leave()
                        fetchedPostIds += postIds
                    })
                }

            }
            myGroup.leave()
        }
        
        myGroup.notify(queue: .main, execute: {
            print("   ~ Database | fetchAllFollowingPostIDforUser | Fetched \(fetchedPostIds.count) PostIds | \(followingUserIds.count) Users | first100 \(first100)")
            completion(fetchedPostIds)
        })
    }
    
    static func fetchAllFollowingListPostIDforUser(uid: String, completion: @escaping ([PostId]) -> ()) {
        let myGroup = DispatchGroup()
        var fetchedPostIds = [] as [PostId]
        var followingListIds = [] as [ListId]
        var tempListIds:[String] = []

        myGroup.enter()
        
        Database.fetchFollowedListIDs(userUid: uid) { (followedListIds) in
            followingListIds = followedListIds
            for list in followedListIds {
                tempListIds.append(list.listId)
            }
            
            if uid == Auth.auth().currentUser?.uid {
                CurrentUser.followedListIdObjects = followedListIds

                CurrentUser.followedListIds = tempListIds
            }
            
            if followedListIds.count > 0 {
                myGroup.enter()
                Database.fetchAllPostIdsForMultLists(listIds: tempListIds, completion: { (postIds) in
                    myGroup.leave()
                    fetchedPostIds += postIds
                })
            }
            
            myGroup.leave()
            
        }
        
        myGroup.notify(queue: .main, execute: {
            print("   ~ Database | fetchAllFollowingPostIDforUser | Fetched \(fetchedPostIds.count) PostIds | \(followingListIds.count) Users")
            completion(fetchedPostIds)
        })
    }
    
    
    
    static func fetchAllPostIDWithCreatorUIDFirst100(creatoruid: String?, completion: @escaping ([PostId]) -> ()) {
        
        guard let creatoruid = creatoruid else {return}
        
        let myGroup = DispatchGroup()
        var fetchedPostIds = [] as [PostId]
          
        let ref = Database.database().reference().child("userposts").child(creatoruid).queryOrdered(byChild: "creationDate").queryLimited(toLast: 100)
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
//        ref.observe(.value) { (snapshot) in

            guard let userposts = snapshot.value as? [String: Any] else {
                completion([])
                return}

            userposts.forEach({ (key,value) in
                myGroup.enter()
//                print("Key \(key), Value: \(value)")
                
                let dictionary = value as? [String: Any]
                let secondsFrom1970 = dictionary?["creationDate"] as? Double ?? 0
                let emoji = dictionary?["emoji"] as? String ?? ""
                
//                let temp_time = Date(timeIntervalSince1970: secondsFrom1970)
//                print("\(creatoruid) | \(key) | \(temp_time)")
            
                let tempID = PostId.init(id: key, creatorUID: creatoruid, sort: nil)
                fetchedPostIds.append(tempID)
                myGroup.leave()
            })
            
            myGroup.notify(queue: .main) {
                if creatoruid == Auth.auth().currentUser?.uid {
//                    print(" ~ FetchingPostIDForUser | Current User | \(fetchedPostIds.count) / \(userposts.count) Posts")
                    CurrentUser.postIds = fetchedPostIds
                    
                } else {
//                    print(" ~ FetchingPostIDForUser | \(creatoruid) | \(fetchedPostIds.count) / \(userposts.count) Posts")
                }
                ref.keepSynced(true)
                completion(fetchedPostIds)
                
                
            }
        })
    }
    
    
    static func fetchAllPostIDWithCreatorUID(creatoruid: String?, completion: @escaping ([PostId]) -> ()) {
        
        guard let creatoruid = creatoruid else {return}
        
        let myGroup = DispatchGroup()
        var fetchedPostIds = [] as [PostId]
        
        let ref = Database.database().reference().child("userposts").child(creatoruid)
        
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
//        ref.observe(.value) { (snapshot) in

            guard let userposts = snapshot.value as? [String: Any] else {
                completion([])
                return}

            userposts.forEach({ (key,value) in
                myGroup.enter()
//                print("Key \(key), Value: \(value)")
                
                let dictionary = value as? [String: Any]
                let secondsFrom1970 = dictionary?["creationDate"] as? Double ?? 0
                let emoji = dictionary?["emoji"] as? String ?? ""
                
//                let temp_time = Date(timeIntervalSince1970: secondsFrom1970)
//                print("\(creatoruid) | \(key) | \(temp_time)")
            
                let tempID = PostId.init(id: key, creatorUID: creatoruid, sort: nil)
                fetchedPostIds.append(tempID)
                myGroup.leave()
            })
            
            myGroup.notify(queue: .main) {
                if creatoruid == Auth.auth().currentUser?.uid {
//                    print(" ~ FetchingPostIDForUser | Current User | \(fetchedPostIds.count) / \(userposts.count) Posts")
                    CurrentUser.postIds = fetchedPostIds
                    
                } else {
//                    print(" ~ FetchingPostIDForUser | \(creatoruid) | \(fetchedPostIds.count) / \(userposts.count) Posts")
                }
                ref.keepSynced(true)
                completion(fetchedPostIds)
            }
        })
    }
    
    
    static func fetchAllPostWithUID(creatoruid: String, filterBlocked: Bool = true, completion: @escaping ([Post]) -> ()) {

        Database.fetchAllPostIDWithCreatorUID(creatoruid: creatoruid) { (postIds) in
            Database.fetchAllPosts(fetchedPostIds: postIds, filterBlocked: filterBlocked) { (posts) in
                print("fetchAllPostWithUID | Success \(posts.count) Posts | uid: \(creatoruid)")
                if creatoruid == Auth.auth().currentUser?.uid {
                    countEmojis(posts: posts) { counts in
                        CurrentUser.userTaggedEmojiCounts = counts
                    }
                    for post in posts {
                        if let postId = post.id {
                            if CurrentUser.posts[postId] == nil {
                                CurrentUser.posts[postId] = post
                            }
                        }
                    }
                }
                
                
                completion(posts)
            }
        }
    }
    
    
//    static func fetchAllPostWithUID(creatoruid: String, completion: @escaping ([Post]) -> ()) {
//
//        let myGroup = DispatchGroup()
//        var fetchedPosts = [] as [Post]
//        Database.fetchUserWithUID(uid: creatoruid) { (user) in
//
//            let ref = Database.database().reference().child("userposts").child((user?.uid)!)
//
//            ref.observeSingleEvent(of: .value, with: {(snapshot) in
//
//                guard let userposts = snapshot.value as? [String: Any] else {return}
//
//                userposts.forEach({ (key,value) in
//
//                    myGroup.enter()
//                    let dictionary = value as? [String: Any]
//                    let secondsFrom1970 = dictionary?["creationDate"] as? Double ?? 0
//                    let creationDate = Date(timeIntervalSince1970: secondsFrom1970)
//                    //                    print("PostId: ", key,"Creation Date: ", creationDate)
//                    //                    print(user.uid, key)
//                    Database.fetchPostWithPostID(postId: key, completion: <#T##(Post?, Error?) -> ()#>)
//                    Database.fetchPostWithUIDAndPostID(creatoruid: (user?.uid)!, postId: key, completion: { (post) in
//
//                        Database.checkPostForSocial(post: post, completion: { (post) in
//                            fetchedPosts.append(post)
//                            fetchedPosts.sort(by: { (p1, p2) -> Bool in
//                                return p1.creationDate.compare(p2.creationDate) == .orderedDescending })
//                            myGroup.leave()
//
//                        })
//                    })
//                })
//
//                myGroup.notify(queue: .main) {
//                    completion(fetchedPosts)
//                }
//
//            })
//            { (err) in print("Failed to fetch user postids", err)}
//        }
//    }
    
    static func fetchAllPostWithGooglePlaceID(googlePlaceId: String, completion: @escaping ([Post], [PostId]) -> ()) {
        
        let myGroup = DispatchGroup()
        var query = Database.database().reference().child("posts").queryOrdered(byChild: "googlePlaceID").queryEqual(toValue: googlePlaceId)
        var fetchedPosts = [] as [Post]
        var fetchedPostIds = [] as [PostId]

        query.observe(.value, with: { (snapshot) in
            
            guard let locationPosts = snapshot.value as? [String: Any] else {return}
            locationPosts.forEach({ (key,value) in
                
                myGroup.enter()
                guard let dictionary = value as? [String: Any] else {return}
                let creatorUID = dictionary["creatorUID"] as? String ?? ""
                
                Database.fetchUserWithUID(uid: creatorUID) { (user) in
                    
                    var post = Post(user: user!, dictionary: dictionary)
                    var postId = PostId.init(id: key, creatorUID: nil, sort: nil)
                    post.id = key

                    fetchedPostIds.append(postId)
                    fetchedPosts.append(post)
                    fetchedPosts.sort(by: { (p1, p2) -> Bool in
                        return p1.creationDate.compare(p2.creationDate) == .orderedDescending })
                    myGroup.leave()
                }
            })
            myGroup.notify(queue: .main) {
                completion(fetchedPosts, fetchedPostIds)
            }
        }) { (err) in
            print("Failed to fetch post for Google Place ID", err)
        }
    }
    
    static func fetchAllPostByCreationDate(fetchLimit: Int, completion: @escaping ([Post], [PostId]) -> ()) {
        
        let myGroup = DispatchGroup()
        var query = Database.database().reference().child("posts").queryOrdered(byChild: "creationDate").queryLimited(toLast: UInt(fetchLimit))
        var fetchedPosts = [] as [Post]
        var fetchedPostIds = [] as [PostId]
        
        query.observe(.value, with: { (snapshot) in
            
            guard let locationPosts = snapshot.value as? [String: Any] else {return}
            locationPosts.forEach({ (key,value) in
                
                myGroup.enter()
                guard let dictionary = value as? [String: Any] else {return}
                let creatorUID = dictionary["creatorUID"] as? String ?? ""
                
                Database.fetchUserWithUID(uid: creatorUID) { (user) in
                    
                    var post = Post(user: user!, dictionary: dictionary)
                    var postId = PostId.init(id: key, creatorUID: nil, sort: nil)
                    post.id = key
                    
                    fetchedPostIds.append(postId)
                    fetchedPosts.append(post)
                    fetchedPosts.sort(by: { (p1, p2) -> Bool in
                        return p1.creationDate.compare(p2.creationDate) == .orderedDescending })
                    myGroup.leave()
                }
            })
            myGroup.notify(queue: .main) {
                completion(fetchedPosts, fetchedPostIds)
            }
        }) { (err) in
            print("Failed to fetch post for Google Place ID", err)
        }
    }
    
    
    static func checkPostWithCurrentUser(post: Post, completion: @escaping (Post) -> ()) {

        guard let postId = post.id else {
            completion(post)
            return
        }
        var tempPost = post

        
        var selectedListIds = [:] as [String:String]
        if let temp = CurrentUser.listedPostIds[postId] {
            for listId in temp {
                if let selectedList = CurrentUser.lists.filter({ (list) -> Bool in
                    list.id == listId
                }).first {
            // - SELECTED AND CREATOR LIST IDS ARE [LISTID: LISTNAME]

                    selectedListIds[listId] = selectedList.name
                }
            }
        }
        
    // CHECK TAGGED LISTS - WILL NEED TO UPDATE FOLLOWING LISTS AND ALL LISTS WHEN FETCHING
        
        tempPost.selectedListId = selectedListIds
        if post.creatorUID == Auth.auth().currentUser?.uid {
            tempPost.creatorListId = tempPost.selectedListId
        }
        
        if tempPost.selectedListId!.count > 0 {
            tempPost.hasPinned = true
//            print("HAS PINNED - \(postId) | \(tempPost.hasPinned)")
        } else {
            tempPost.hasPinned = false
        }
        
    // CHECK MESSAGE
        
        if CurrentUser.inboxThreads.count > 0 {
            for threads in CurrentUser.inboxThreads {
                if threads.postId == postId {
                    tempPost.hasMessaged = true
                    break
                }
            }
        }
        
    // CHECK LIKES
        tempPost.hasLiked = (CurrentUser.likedPostIds[postId] ?? 0) > 0
        if (tempPost.likeCount - (tempPost.hasLiked ? 1 : 0)) > 0 {
            Database.checkPostForVotes(post: tempPost) { tempPost in
                completion(tempPost)
            }
        } else {
            completion(tempPost)
        }
//        completion(tempPost)

        
//        if (tempPost.selectedListId?.count ?? 0) > 0 {
//            print("PINNED \(postId) \(tempPost.hasPinned) \(tempPost.selectedListId?.count)")
//        }
    }
        
    static func fetchPostWithPostID( postId: String, force:Bool? = false, completion: @escaping (Post?, Error?) -> ()) {
        
//        guard let uid = Auth.auth().currentUser?.uid else {return}
        if postId.isEmptyOrWhitespace() {return}
        
//        if CurrentUser.blockedPost[postId] != nil {
//            print("Filtered Out Blocked Post \(postId)")
//            completion(nil, nil)
//        }
        
        var tempPost: Post? = nil

    //  TRIES CACHE FIRST IF NOT FORCE REFRESH
        if !force! {
            if let cachedPost = postCache[postId] {
                if cachedPost != nil && (!cachedPost.reportedFlag || cachedPost.creatorUID == Auth.auth().currentUser?.uid) {
                    tempPost = cachedPost
                }
            } else if let cachedPost = CurrentUser.posts[postId] {
                if cachedPost != nil {
                    tempPost = cachedPost
                }
            }
            
            
            if tempPost != nil {
                guard let tempPost = tempPost else {return}
                var cachePost = tempPost
                // Update Post Distances
                if let tempLoc = CurrentUser.currentLocation {
                    if let _ = cachePost.locationGPS {
                        cachePost.distance = Double((cachePost.locationGPS?.distance(from: tempLoc))!)
                    } else {
                        cachePost.distance = nil
                    }
                }
                
            // Recalculate number of lists from followers in case old/new follower was added
                
                cachePost.followingList.removeAll()
                if CurrentUser.followingUids.count > 0 {
                    for list in cachePost.allList {
                        if CurrentUser.followingUids.contains(list.value) {
                            cachePost.followingList[list.key] = list.value
                        }
                    }
                }
                
            // CHECK THAT SELECTED LIST IS STILL CURRENT USERS - MISSED WHEN USERS LOGOUT AND LOGIN WITH NEW USER
                
            // REFRESH POST LISTS
                cachePost.selectedListId?.removeAll()
                var tempSelectedListIds:[String: String] = [:]
                
                // - SELECTED AND CREATOR LIST IDS ARE [LISTID: LISTNAME]
                for (key,value) in cachePost.allList {
                    if value == Auth.auth().currentUser?.uid {
                        if let selectedList = CurrentUser.lists.filter({ (list) -> Bool in
                            list.id == key
                        }).first {
                            tempSelectedListIds[key] = selectedList.name
                        }
                    }
                }
                cachePost.selectedListId = tempSelectedListIds
                postCache[postId] = cachePost
                if cachePost.creatorUID == CurrentUser.uid {
                    CurrentUser.posts[postId] = cachePost
                }
//                print("fetchPostWithPostID | Cache | \(postId)")
                completion(cachePost, nil)
                return
            }
            
        }
        
        let ref = Database.database().reference().child("posts").child(postId)
        
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            
            guard let dictionary = snapshot.value as? [String: Any] else {
                print("   ~ Database | fetchPostWithPostID | No dictionary for post id: ", postId)
                completion(nil,nil)
                return
            }
            let creatorUID = dictionary["creatorUID"] as? String ?? ""
            if CurrentUser.blockedByUsers[creatorUID] != nil {
                print("Post Creator User Blocked Current User | \(postId) | \(creatorUID)")
                completion(nil, nil)
            }

            if creatorUID == "" {
                print("ERROR CREATOR UID | \(postId)")
                completion(nil, nil)
            } else {
                Database.fetchUserWithUID(uid: creatorUID, completion: { (user) in
                    
                    guard let user = user else {
                        print("   ~ Database | fetchPostWithPostID | No User Found For \(creatorUID) | Post \(postId)")
                        completion(nil, nil)
                        return
                    }
                    var post = Post(user: user, dictionary: dictionary)
                    post.id = postId
                    
                    if let tempLoc = CurrentUser.currentLocation {
                        if let _ = post.locationGPS {
                            post.distance = Double((post.locationGPS?.distance(from: tempLoc))!)
                        } else {
                            post.distance = nil
                        }
                    }
                    
                    if post.creatorUID == CurrentUser.uid {
                        CurrentUser.posts[postId] = post
                    }
                    
                    Database.checkPostWithCurrentUser(post: post) { checkedPost in
                        completion(checkedPost, nil)
                    }

//                    Database.checkPostWithCurrentUser(post: post) { checkedPost in
//                        Database.checkPostForLists(post: checkedPost) { checkedPost in
//                            Database.checkPostForVotes(post: checkedPost) { checkedPost in
//                                Database.checkPostForComments(post: checkedPost) { checkedPost in
//                                    Database.checkPostForMessages(post: checkedPost) { checkedPost in
//                                        Database.checkPostIntegrity(post: checkedPost) { checkedPost in
//                                            completion(checkedPost, nil)
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                    }
                                  
                })
            }
        }) {(err) in
            print("Failed to fetch post for postid:",err)
            completion(nil, err)
        }
    }
    
//    Database.checkPostForVotes(post: tempPost) { (post) in
//        Database.checkPostForLists(post: post, completion: { (post) in
//            Database.checkPostForMessages(post: post, completion: { (post) in
//                Database.checkPostForComments(post: post, completion: { (post) in
//                    Database.checkPostIntegrity(post: post, completion: { (post) in
//                        if let postId = post.id {
//                            postCache[postId] = post
//                            if post.updateFromChecks {
//                                let postDict:[String: String] = ["updatedPostId": postId]
//                                NotificationCenter.default.post(name: MainTabBarController.editUserPost, object: nil, userInfo: postDict)
//                            }
//                        }
//
//                        let end = DispatchTime.now()   // <<<<<<<<<<   end time
//                        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
//                        let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests
//                        print("checkpostForSocial: \(timeInterval) seconds | \(post.id)")
//                        completion(post)
//                    })
//                })
//            })
//        })
//    }
    
//    static func fetchAllReportedPostID(completion: @escaping ([String]?) -> ()) {
//
//        let ref = Database.database().reference().child("report")
//        ref.observeSingleEvent(of: .value, with: {(snapshot) in
//
//            guard let dictionary = snapshot.value as? [String: Any] else {
//                print("   ~ Database | fetchAllReportedPostID | No Reported Posts ")
//                completion(nil)
//                return
//            }
//
//            for p
//
//            let creatorUID = dictionary["creatorUID"] as? String ?? ""
//
//            if creatorUID == "" {
//                print("ERROR CREATOR UID | \(postId)")
//                completion(nil, nil)
//            } else {
//                Database.fetchUserWithUID(uid: creatorUID, completion: { (user) in
//
//                    guard let user = user else {
//                        print("   ~ Database | fetchPostWithPostID | No User Found For \(creatorUID) | Post \(postId)")
//                        completion(nil, nil)
//                        return
//                    }
//                    var post = Post(user: user, dictionary: dictionary)
//                    post.id = postId
//
//                    if let tempLoc = CurrentUser.currentLocation {
//                        if let _ = post.locationGPS {
//                            post.distance = Double((post.locationGPS?.distance(from: tempLoc))!)
//                        } else {
//                            post.distance = nil
//                        }
//                    }
//
//                    checkPostForSocial(post: post, completion: { (post) in
//                        checkPostIntegrity(post: post, completion: { (post) in
//                            postCache[postId] = post
//
//
//                            //                print(post)
//                            if post.creatorUID == CurrentUser.uid {
//                                CurrentUser.posts[postId] = post
//                            }
//                            completion(post, nil)
//                        })
//                    })
//                })
//            }
//        }) {(err) in
//            print("Failed to fetch post for postid:",err)
//            completion(nil, err)
//        }
//
//
//    }
    
    static func fetchAllPostWithLocation(location: CLLocation, distance: Double, completion: @escaping ([Post], [PostId]) -> ()) {
        
        var fetchedPostIds = [] as [PostId]
        var fetchedPosts = [] as [Post]
        
        let myGroup = DispatchGroup()
        let ref = Database.database().reference().child("postlocations")
        let geoFire = GeoFire(firebaseRef: ref)
        let circleQuery = geoFire.query(at: location, withRadius: distance)
        
        myGroup.enter()
        circleQuery.observe(.keyEntered, with: { (key, firebaselocation) in
            //            print(key)
            
            myGroup.enter()
            Database.fetchPostWithPostID(postId: key, completion: { (post, error) in
                //                print(post)
                if let error = error {
                    print(error)
                    myGroup.leave()
                    return
                }
                
                guard let post = post else {
                    myGroup.leave()
                    return}
                var tempPost = post
                var tempPostId = PostId.init(id: key, creatorUID: nil, sort: nil)
                tempPost.distance = tempPost.locationGPS?.distance(from: location)
                //                print(tempPost.distance, ": ", tempPost.caption, " : ", location, " : ", tempPost.locationGPS)
                fetchedPosts.append(tempPost)
                fetchedPostIds.append(tempPostId)
                myGroup.leave()
            })
        })
        
        circleQuery.observeReady({
            myGroup.leave()
        })
        
        myGroup.notify(queue: .main) {
            fetchedPosts.sort(by: { (p1, p2) -> Bool in
                return (p1.distance! < p2.distance!)
            })
            completion(fetchedPosts, fetchedPostIds)
        }
    }
    
    static func fetchAllListWithLocation(location: CLLocation, distance: Double, completion: @escaping ([List], [String]) -> ()) {
        
        var fetchedListIds = [] as [String]
        var fetchedLists = [] as [List]
        
        let myGroup = DispatchGroup()
        let ref = Database.database().reference().child("listlocations")
        let geoFire = GeoFire(firebaseRef: ref)
        let circleQuery = geoFire.query(at: location, withRadius: distance)
        
        myGroup.enter()
        circleQuery.observe(.keyEntered, with: { (key, firebaselocation) in
            //            print(key)
            
            myGroup.enter()
            Database.fetchListforSingleListId(listId: key, completion: { (list) in
                guard let list = list else {return}
                var tempList = list
                tempList.listDistance = tempList.listGPS?.distance(from: location) ?? 0
                fetchedLists.append(list)
                fetchedListIds.append(key)
                myGroup.leave()
            })
        })
        
        circleQuery.observeReady({
            myGroup.leave()
        })
        
        myGroup.notify(queue: .main) {
            fetchedLists.sort(by: { (p1, p2) -> Bool in
                return (p1.listDistance! < p2.listDistance!)
            })
            completion(fetchedLists, fetchedListIds)
        }
    }
    
    
    static func fetchPostIDDetails(postId: String, completion: @escaping (PostId) -> ()) {
        
        var fetchedPostID: PostId? = nil
        
        let ref = Database.database().reference().child("posts").child(postId)
        
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            
            guard let dictionary = snapshot.value as? [String: Any] else {return}
            let creatorUID = dictionary["creatorUID"] as? String ?? ""
//            let secondsFrom1970 = dictionary["creationDate"] as? Double ?? 0
//            let postGPS = dictionary["postLocationGPS"] as? String ?? ""
//            let tagTime = dictionary["tagTime"] as? Double ?? 0
//            let emoji = dictionary["emoji"] as? String ?? ""
            
            
            let tempID = PostId.init(id: postId, creatorUID: creatorUID, sort: nil)
            completion(tempID)
            
        })
    }
    
    
    
    static func fetchAllPostIDWithinLocation(selectedLocation: CLLocation, distance: Double, completion: @escaping ([PostId]) -> ()) {
        
        let myGroup = DispatchGroup()
        var fetchedPostIds = [] as [PostId]
        
        let ref = Database.database().reference().child("postlocations")
        let geoFire = GeoFire(firebaseRef: ref)
        let circleQuery = geoFire.query(at: selectedLocation, withRadius: distance)
        
        myGroup.enter()
        circleQuery.observe(.keyEntered, with: { (key, firebaseLocation) in
            //            print(key)
            
            myGroup.enter()
            
            Database.fetchPostIDDetails(postId: key, completion: { (fetchPostId) in
                var tempPostId = fetchPostId
                tempPostId.sort = firebaseLocation.distance(from: selectedLocation)
                fetchedPostIds.append(tempPostId)
                myGroup.leave()
            })
        })
        
        circleQuery.observeReady({
            myGroup.leave()
        })
        
        myGroup.notify(queue: .main) {
            
            fetchedPostIds.sort(by: { (p1, p2) -> Bool in
                return (p1.sort! < p2.sort!)
            })
            print("Geofire Fetched Posts: \(fetchedPostIds.count)" )
            completion(fetchedPostIds)
        }
    }
    
    static func fetchPostIDBySocialRank(firebaseRank: String, fetchLimit: Int, completion: @escaping ([PostId]?) -> ()) {
        
        let myGroup = DispatchGroup()
        var fetchedPostIds = [] as [PostId]
        guard let firebaseCountVariable = firebaseCountVariable[firebaseRank] else {
            print("Fetch Post Id by Social Rank: ERROR, Invalid Firebase Count for \(firebaseRank)")
            return
        }
        guard let firebaseField = firebaseFieldVariable[firebaseRank] else {
            print("Fetch Post Id by Social Rank: ERROR, Invalid Firebase Field for \(firebaseRank)")
            return
        }
        
        
        print("Query Firebase by \(firebaseRank) : \(firebaseCountVariable)")

        var query = Database.database().reference().child(firebaseField).queryOrdered(byChild: "sort").queryLimited(toLast: UInt(fetchLimit))
        query.observe(.value, with: { (snapshot) in
            guard let postIds = snapshot.value as? [String:Any] else {return}
            
            
            postIds.forEach({ (key,value) in
                
                let details = value as? [String:Any]
                var varCount = details?[firebaseCountVariable] as! Int
                var varSort = details?["sort"] as! Double
                
                var tempPostId = PostId.init(id: key, creatorUID: " ", sort: varSort)
                fetchedPostIds.append(tempPostId)

            })
            
            // Sort Fetched Post Ids
            fetchedPostIds.sort(by: { (p1, p2) -> Bool in
                return (p1.sort! > p2.sort!)
            })
            
            completion(fetchedPostIds)

        }) { (error) in
            print("Fetch Post Id by Social Rank: ERROR, \(error)")
            completion(nil)
        }
    }
    
    static func fetchAllPostIDWithTag(emojiTag: String, completion: @escaping ([PostId]?) -> ()) {
        
        let myGroup = DispatchGroup()
        var fetchedPostIds = [] as [PostId]
        
        let ref = Database.database().reference().child("post_tags").child(emojiTag)

        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            guard let tag = snapshot.value as? [String: Any] else {
                print("Fetch Post for EmojiTag \(emojiTag): Nil Results")
                completion(nil)
                return}
            guard let taggedPosts = tag["posts"] as? [String] else {return}
            
            taggedPosts.forEach({ (key) in
                myGroup.enter()
                let tempID = PostId.init(id: key, creatorUID: nil, sort: nil)
                fetchedPostIds.append(tempID)
                myGroup.leave()
            })
            
            myGroup.notify(queue: .main) {
                completion(fetchedPostIds)
            }
        }){ (error) in
            print(error)
            completion(nil)
        }
    }
    
    
    
    static func fetchAllPosts(fetchedPostIds: [PostId], filterBlocked: Bool = true, completion: @escaping ([Post])-> ()){
        
        let thisGroup = DispatchGroup()
        var fetchedPostsTemp: [Post] = []
        
        
//        print("Fetch All Posts Count ", fetchedPostIds.count)
        
        for postId in fetchedPostIds {
            if filterBlocked && CurrentUser.blockedPosts[postId.id] != nil {
                print("Blocked Post \(postId.id)")
                continue
            }
            thisGroup.enter()
            Database.fetchPostWithPostID(postId: postId.id, completion: { (post, error) in
                if let error = error {
                    print(" ! Fetch Post: ERROR: \(postId)", error)
                }
                
                if let tempPost = post {
                    // Fetch flagged posts for user still
                    if !tempPost.reportedFlag || tempPost.creatorUID == Auth.auth().currentUser?.uid || !filterBlocked {
                        fetchedPostsTemp.append(tempPost)
                    }
                } else {
                    print("No Posts for \(postId)")
                }
                
//                let count = thisGroup.debugDescription.components(separatedBy: ",").filter({$0.contains("count")}).first?.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap{Int($0)}.first
//
//                print(count, postId)
                thisGroup.leave()

                
//                guard let post = post else {
//                    print(" ! Fetch Post: ERROR: No Post for \(postId)", error)
//                    thisGroup.leave()
//                    throw PostError.noPost
////                    return
//                }
//
//                var tempPost = post
//
//                fetchedPostsTemp.append(tempPost)
//                thisGroup.leave()
            })
        }
        
        thisGroup.notify(queue: .main) {
            print("   ~ Database | Fetched All Posts: : \(fetchedPostsTemp.count) Posts | \(fetchedPostIds.count) Post IDs")
            completion(fetchedPostsTemp)
        }
    }
    
    static func fetchAllPosts(postIds: [String], completion: @escaping ([Post])-> ()){
        
        let thisGroup = DispatchGroup()
        var fetchedPostsTemp: [Post] = []
        
        
//        print("Fetch All Posts Count ", fetchedPostIds.count)
        
        for postId in postIds {
            if CurrentUser.blockedPosts[postId] != nil {
                print("Blocked Post \(postId)")
                continue
            }
            thisGroup.enter()
            Database.fetchPostWithPostID(postId: postId, completion: { (post, error) in
                if let error = error {
                    print(" ! Fetch Post: ERROR: \(postId)", error)
                }
                
                if let tempPost = post {
                    // Fetch flagged posts for user still
                    if !tempPost.reportedFlag || tempPost.creatorUID == Auth.auth().currentUser?.uid {
                        fetchedPostsTemp.append(tempPost)
                    }
                } else {
                    print("No Posts for \(postId)")
                }
                
//                let count = thisGroup.debugDescription.components(separatedBy: ",").filter({$0.contains("count")}).first?.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap{Int($0)}.first
//
//                print(count, postId)
                thisGroup.leave()

                
//                guard let post = post else {
//                    print(" ! Fetch Post: ERROR: No Post for \(postId)", error)
//                    thisGroup.leave()
//                    throw PostError.noPost
////                    return
//                }
//
//                var tempPost = post
//
//                fetchedPostsTemp.append(tempPost)
//                thisGroup.leave()
            })
        }
        
        thisGroup.notify(queue: .main) {
            print("   ~ Database | Fetched All Posts: : \(fetchedPostsTemp.count) Posts | \(postIds.count) Post IDs")
            completion(fetchedPostsTemp)
        }
    }
    
// MARK: - CHECK SOCIAL ITEMS

// NEW LIST NOTIFICATIONS - Check for new posts in lists

    static func checkListForNewEvent(list: List, completion: @escaping (List) -> ()){
        
        guard let listId = list.id else {
            print("   ~ Database | checkListForFollowers | ERROR | No List ID")
            completion(list)
            return
        }
        
        if Auth.auth().currentUser == nil {
            completion(list)
            return
        }
        
        
        if list.creatorUID == Auth.auth().currentUser!.uid {
            // NO NEW NOTIFICATIONS IF LIST CREATOR IS USER
            completion(list)
            return
        }
        
        var tempList = list
        let myGroup = DispatchGroup()
        var fetchedEvents: [Event] = []
        
        let ref = Database.database().reference().child("list_event").child(listId).child("creator_event")

        ref.keepSynced(true)
        
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            //            print(snapshot)
            guard let userEvents = snapshot.value as? [String: Any] else {
//                print("checkListForNewEvent | No Notifications | \(list.name) | \(list.id)")
                completion(tempList)
                return}
            
            userEvents.forEach({ (key,value) in
                myGroup.enter()
                
                guard let dictionary = value as? [String: Any] else {
                    myGroup.leave()
                    return}
                
                var tempEvent = Event.init(id: key, dictionary: dictionary)
                
                if let listIndex = CurrentUser.followedListIdObjects.firstIndex(where: {$0.listId == listId}){
                    var temp = CurrentUser.followedListIdObjects[listIndex]
                    if temp.listId != listId {
                        print("updateListInteraction | Update Cache ERROR | \(listId) - \(temp.listId)")
                        return
                    }
                    
                // USER CURRENTLY FOLLOWING LIST. ONLY INCLUDE NEW IF EVENT DATE > LAST LOAD DATE
                    if tempEvent.eventTime > temp.listLastLoadDate ?? Date.distantPast {
                        fetchedEvents.append(tempEvent)
                    }
                    myGroup.leave()
                    
                } else {
                // USER NOT FOLLOWING LIST. ONLY INCLUDE NEW THE PAST WEEK
                    let tempDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                    
                    if tempEvent.eventTime > tempDate {
                        fetchedEvents.append(tempEvent)
                    }
                    myGroup.leave()
                }
            })
            
            myGroup.notify(queue: .main) {
                tempList.newNotifications = fetchedEvents
                completion(tempList)
                for event in fetchedEvents {
                    if !CurrentUser.listEvents.contains(where: {$0.id == event.id}) {
                        CurrentUser.listEvents.append(event)
                    }
                }
//                print("checkListForNewEvent | Fetched \(fetchedEvents.count) Events For \(list.name) | \(list.id)")
            }
        })
    }
        

    // CHECK LIST FOLLOWERS
    
    static func checkListForFollowers(list: List, completion: @escaping (List) -> ()){
        
        guard let listId = list.id else {
            print("   ~ Database | checkListForFollowers | ERROR | No List ID")
            return
        }
        
        var tempList = list
        
        Database.database().reference().child("followedlists").child(listId).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let tempList = snapshot.value as? [String: Any] ?? [:]
            let followerCount = tempList["followerCount"] as? Int ?? 0
            let followers = tempList["follower"] as? [String:Any]? ?? [:]
            
                if followerCount != list.followerCount {
                    self.updateVariableForList(listId: listId, variable: "followerCount", newCount: followerCount)
                    list.followerCount = followerCount ?? 0
                    print("   ~ Database | checkListForFollowers | Update Follower Count For List | \(listId) | \(list.followerCount) to \(followerCount)")
                }
            
            if followers != nil {
                list.followers = followers
            }
            
            if list.followerCount != list.followers?.count {
                print("Firebase | checkListForFollowers | Count Mismatch | \(list.followerCount) | \(list.followers?.count) | \(list.id)")
            }
        
            completion(list)
        }, withCancel: { (err) in
            print("Failed to check follower info for list: \(listId)", err)
            completion(list)
        })
    }
    
    // CRED VOTES
    
    static func checkPostForVotes(post: Post, completion: @escaping (Post) -> ()){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        var tempPost = post
        
        Database.database().reference().child("post_votes").child(post.id!).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let post = snapshot.value as? [String: Any] ?? [:]
            var votes: Dictionary<String, Int>
            votes = post["votes"] as? [String : Int] ?? [:]
            var voteCount = post["voteCount"] as? Int ?? 0
            
            if let curVote = votes[uid] {
                tempPost.hasLiked = curVote == 1
            }
            
            if tempPost.likeCount != voteCount {
                // Calculated Bookmark Count Different from Database
                print("checkPostForVotes - FIX - \(tempPost.likeCount) to \(voteCount) | \(tempPost.id)")
                tempPost.likeCount = voteCount
                tempPost.updateFromChecks = true
                updateSocialCountsForPost(postId: tempPost.id, socialVariable: "voteCount", newCount: voteCount)
            }
            
            var tempAllVote :[String] = []
            for (key,value) in votes {
                if value == 1 {
                    tempAllVote.append(key)
                }
            }
            tempPost.allVote = tempAllVote
            
            // Loops through all current user following ids to check if any of following people cred post
            var tempFollowingVote :[String] = []
            for following in CurrentUser.followingUids {
                // Check for following vote and NOT creator UID
                if (votes[following] == 1 && following != tempPost.creatorUID){
                    tempFollowingVote.append(following)
                }
            }
            tempPost.followingVote = tempFollowingVote
        
            voteCache[tempPost.id!] = voteCount
            completion(tempPost)
        }, withCancel: { (err) in
            print("Failed to fetch vote info for post:", err)
        })
    }

    
    static func checkPostIdsForTotalCredCount(postIds: [String]?, completion: @escaping (Int) -> ()){
        var cumCred = 0
        
        guard let postIds = postIds else {
            print("checkPostIdForVoteCount ERROR: No Post IDs")
            completion(0)
            return}
        
        if postIds.count == 0 {
            print("checkPostIdForVoteCount ERROR: No Post IDs")
            completion(0)
            return}

        let myGroup = DispatchGroup()
        
        myGroup.enter()
        for postId in postIds {
            myGroup.enter()
            if let post = postCache[postId] {
                // Check Post Cache
                cumCred += (post.likeCount + post.listCount + post.messageCount)
                
//                print("Post Cache: PostID: \(postId) | Votes: \(post.voteCount)")
                myGroup.leave()
                
            } else{
                let ref = Database.database().reference().child("posts").child(postId)
                
                ref.observeSingleEvent(of: .value, with: {(snapshot) in
                    
                    guard let dictionary = snapshot.value as? [String: Any] else {
                        print("checkPostIdsForTotalCredCount | No dictionary for post id: ", postId)
                        return
                    }
                    
                    var voteCount = dictionary["voteCount"] as? Int ?? 0
                    var listCount = dictionary["listCount"] as? Int ?? 0
                    var messageCount = dictionary["messageCount"] as? Int ?? 0

                    cumCred += (voteCount + listCount + messageCount)
                    myGroup.leave()

                }) {(err) in
                    print("Failed to fetch post for postid:",err)
                    myGroup.leave()
                }
            }
        }
        myGroup.leave()
        
        myGroup.notify(queue: .main) {
            print("Fetched cred For \(postIds.count) Posts: \(cumCred)")
            completion(cumCred)
        }
    }
    
    // Comments
    
    static func checkPostForComments(post: Post, completion: @escaping (Post) -> ()){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        guard let postid = post.id else {return}
        var tempPost = post
        
        self.fetchCommentsForPostId(postId: postid) { (comments) in
//            if postid == "-Kx2DlBNkfNMVWPuFH1c" {
//                print("-Kx2DlBNkfNMVWPuFH1c | \(comments.count) Comments | \(comments)")
//            }
            
//            let newCount = max(tempPost.commentCount, comments.count)
            let newCount = comments.count

        // WE CHANGE THE CHECK FORMULA TO USE MAX BECAUSE IT KLEPT SWITCHING FROM 4 TO 3 BACK TO 4 DUE TO COMMENT SEQUENCES
            
            if tempPost.commentCount != newCount {
                print("checkPostForComments - FIX - \(tempPost.commentCount) to \(newCount) | \(post.id)")
                tempPost.commentCount = newCount
                tempPost.updateFromChecks = true
                updateSocialCountsForPost(postId: tempPost.id, socialVariable: "commentCount", newCount: newCount)
            }
            
            tempPost.comments = comments
            
            for comment in comments {
                // Add to following comments if comment creator is followed by user
                if CurrentUser.followingUids.contains(comment.userId) {
                    tempPost.followingComments.append(comment)
                }
            }
            
            completion(tempPost)
            }
        }
    
    
    static func fetchCommentsForPostId(postId: String?, completion: @escaping ([Comment]) -> ()){
        guard let postId = postId else {return}
        
        var comments = [Comment]()
        let ref = Database.database().reference().child("comments").child(postId)
        let myGroup = DispatchGroup()

        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            
            let commentCount = snapshot.childrenCount
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([])
                return}

            myGroup.enter()
            
            dictionaries.forEach({ (key,value) in
                myGroup.enter()
                guard let dictionary = value as? [String: Any] else {
                    myGroup.leave()
                    return}
                
                guard let uid = dictionary["uid"] as? String else {
                    myGroup.leave()
                    return}
                
                Database.fetchUserWithUID(uid: uid, completion: { (user) in
                    guard let user = user else {
                        myGroup.leave()
                        return}
                    var comment = Comment(key: key,user: user, dictionary: dictionary)
                    comments.append(comment)
                })
                myGroup.leave()
            })
            
            myGroup.leave()
            myGroup.notify(queue: .main) {
                comments.sort(by: { (p1, p2) -> Bool in
                    return p1.creationDate.compare(p2.creationDate) == .orderedAscending
                })
                completion(comments)
            }
        }){ (err) in
            print("Failed to observe comments: \(postId) ", err)
        }
    }
    
    static func checkPostIdsForVoteCount(postIds: [String]?, completion: @escaping (Int) -> ()){
    
        // USED TO SUM UP CRED FOR POSTS AND LISTS
        
        var cumVotes = 0
        
        guard let postIds = postIds else {
            print("checkPostIdForVoteCount ERROR: No Post IDs")
            completion(0)
            return}
        
        if postIds.count == 0 {
            print("checkPostIdForVoteCount ERROR: No Post IDs")
            completion(0)
            return}
        
        let myGroup = DispatchGroup()

        myGroup.enter()
        for postId in postIds {
            myGroup.enter()
            if let post = postCache[postId] {
                // Check Post Cache
                cumVotes += post.likeCount
//                print("Post Cache: PostID: \(postId) | Votes: \(post.voteCount)")
                myGroup.leave()

            } else{
                Database.database().reference().child("post_votes").child(postId).child("voteCount").observeSingleEvent(of: .value, with: { (snapshot) in
                    let voteCount = snapshot.value as? Int ?? 0
                    cumVotes += voteCount
                    print("Firebase Query PostID: \(postId) | Votes: \(voteCount) | Cum Votes: \(cumVotes)")
                    myGroup.leave()

                }, withCancel: { (err) in
                    print("Failed to fetch vote count for post:", err)
                    cumVotes += 0
                    myGroup.leave()

                })
            }
        }
        myGroup.leave()
        
        myGroup.notify(queue: .main) {
            print("Fetched Votes For \(postIds.count) Posts: \(cumVotes)")
            completion(cumVotes)
        }
    }

    
    static func checkPostForLists(post: Post, completion: @escaping (Post) -> ()){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        guard let postId = post.id else {
            print("Check Post for Lists: ERROR, No Post Ids")
            return}
        var tempPost = post
        let postListRef = Database.database().reference().child("post_lists").child(postId)
        postListRef.keepSynced(true)
        
        postListRef.observeSingleEvent(of: .value, with: { (snapshot) in
        
            // Post object has a list count that is saved, and also a separate entry in post_list that contains all the other lists. We update the listcount saved in the post object if it is different from post_list
            
            let fetch = snapshot.value as? [String: Any] ?? [:]
            
            var lists: Dictionary<String, String>
            lists = fetch["lists"] as? [String : String] ?? [:]
            var listCount = fetch["listCount"] as? Int ?? 0
            
            // CHECK NUMBER OF LISTS IN POST_LISTS
            if lists.count != listCount {
                print("checkPostForLists - FIX - \(listCount) to \(lists.count) | \(post.id)")
                listCount = lists.count
                tempPost.updateFromChecks = true
                updateSocialCountsForPost_Lists(postId: tempPost.id, socialVariable: "listCount", newCount: lists.count)
            }
            
            
            // UPDATE LIST COUNT SAVE IN POST
            if tempPost.listCount != listCount {
                print("checkPostForLists - FIX POST - \(tempPost.listCount) to \(listCount) | \(post.id)")
                tempPost.listCount = listCount
                tempPost.updateFromChecks = true
                updateSocialCountsForPost(postId: tempPost.id, socialVariable: "listCount", newCount: listCount)
            }
            

        // Post objects are saved with the list ids that are linked by the post creator. We show the lists tagged by post creator and the current user.
            
        // We loop through the current user lists to find if the post is in the current user's list
        // If current user is post creator, the current user selected list should be identical to creator list.
        // We update the post object's list if they are different (Creator tags on an additional list later on)
            
        // UPDATE CURRENT USER LISTS
        // CHECKS FOR SELECTED LISTS FOR POST BY GOING THROUGH CURRENT USER LISTS
//            for list in CurrentUser.lists {
//                if list.postIds![postId] != nil {
//                    tempSelectedListIds[list.id!] = list.name
//                }
//            }
            
            var tempSelectedListIds: [String:String] = [:]

        // Filters out List that are currently selected by the current user
            // FIREBASE OUTPUT IS [LISTID ; USERUID]
            for (key,value) in lists {
                if value == uid {
                    if let selectedList = CurrentUser.lists.filter({ (list) -> Bool in
                        list.id == key
                    }).first {
                // - SELECTED AND CREATOR LIST IDS ARE [LISTID: LISTNAME]

                        tempSelectedListIds[key] = selectedList.name
                    }
                }
            }
            
            tempPost.selectedListId = tempSelectedListIds
            if tempPost.creatorListId == nil {
                tempPost.creatorListId = [:]
            }
            
            
        // CURRENT USER IS POST CREATOR
            if post.creatorUID == uid {
                
                if tempPost.selectedListId! != tempPost.creatorListId! {
                    
                    let cacheString = "\(tempPost.id)_UpdateListPost"
                    if processingCache[cacheString] == 1 {
                        print("checkPostForLists | cacheString | \(cacheString)")
                    } else {
                        // Current User is post creator, Update Creator List if Post id different
                        
                        processingCache[cacheString] = 1
                        
                        Database.database().reference().child("posts").child(postId).child("lists").setValue(tempPost.selectedListId!, withCompletionBlock: { (err, ref) in
                            if let err = err {
                                print("   ~ Database | checkPostForLists | Update List in Post Object \(postId): Fail, \(err)")
                                processingCache[cacheString] = 0
                                return
                            }
                            print("   ~ Database | checkPostForLists | Update List in Post Object \(postId): Success | \(tempPost.selectedListId!.count) from \(tempPost.creatorListId!.count)")
                            processingCache[cacheString] = 0
                            
                        })
                    }
                }
                
                tempPost.creatorListId! = tempPost.selectedListId!
            }
            
            if tempPost.selectedListId!.count > 0 {
                tempPost.hasPinned = true
            } else {
                tempPost.hasPinned = false
            }
            
            var tempFollowingList: [String:String] = [:]
            // Check if any of following people added post to list
            for following in CurrentUser.followingUids {

                // Filter for creator uid who is followed and NOT the creator, since you'd know from the top list
                // - ALL LIST AND FOLLOWING LIST IDS ARE [LISTID: LIST CREATOR UID]

                let followingLists = lists.filter({ (key,value) -> Bool in
//                    (value == following && value != tempPost.creatorUID)
                    (value == following)
                })
                for (key,value) in followingLists {
                    tempFollowingList[key] = value
                }
                
            }
            tempPost.followingList = tempFollowingList
            tempPost.allList = lists
            completion(tempPost)
        }, withCancel: { (err) in
            print("Failed to fetch list count for post:", err)
        })
        
    }
    
    static func checkPostIdsForListCount(postIds: [String]?, completion: @escaping (Int) -> ()){
        
        // USED TO SUM UP CRED FOR POSTS AND LISTS

        
        var cumLists = 0
        
        guard let postIds = postIds else {
            print("checkPostIdForListCount ERROR: No Post IDs")
            completion(0)
            return}
        
        if postIds.count == 0 {
            print("checkPostIdForListCount ERROR: No Post IDs")
            completion(0)
            return}
        
        let myGroup = DispatchGroup()
        
        myGroup.enter()
        for postId in postIds {
            myGroup.enter()
            if let post = postCache[postId] {
                // Check Post Cache
                cumLists += post.listCount
//                print("Post Cache: PostID: \(postId) | List: \(post.listCount)")
                myGroup.leave()
                
            } else{
                Database.database().reference().child("post_lists").child(postId).child("listCount").observeSingleEvent(of: .value, with: { (snapshot) in
                    let listCount = snapshot.value as? Int ?? 0
                    cumLists += listCount
                    print("Firebase Query PostID: \(postId) | Lists: \(listCount) | Cum Lists: \(cumLists)")
                    myGroup.leave()
                    
                }, withCancel: { (err) in
                    print("Failed to fetch vote count for post:", err)
                    cumLists += 0
                    myGroup.leave()
                    
                })
            }
        }
        myGroup.leave()
        
        myGroup.notify(queue: .main) {
            print("Fetched Votes For \(postIds.count) Lists: \(cumLists)")
            completion(cumLists)
        }
    }
    
    static func checkPostForMessages(post: Post, completion: @escaping (Post) -> ()){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        guard let postid = post.id else {return}
        var tempPost = post
        
        Database.database().reference().child("post_messages").child(post.id!).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let post = snapshot.value as? [String: Any] ?? [:]
            var messages: Dictionary<String, Int>
            messages = post["threads"] as? [String : Int] ?? [:]
            var messageCount = post["messageCount"] as? Int ?? 0
            
            if CurrentUser.inboxThreads.count > 0 {
                for threads in CurrentUser.inboxThreads {
                    if threads.postId == postid {
                        tempPost.hasMessaged = true
                        break
                    }
                }
            }
            
            if tempPost.messageCount != messageCount {
                // Calculated Bookmark Count Different from Database
                print("checkPostForMessages - FIX - \(tempPost.messageCount) to \(messageCount) | \(tempPost.id)")
                tempPost.messageCount = messageCount
                tempPost.updateFromChecks = true
                updateSocialCountsForPost(postId: tempPost.id, socialVariable: "messageCount", newCount: messageCount)
            }
            
            
            completion(tempPost)
        }, withCancel: { (err) in
            print("Failed to fetch bookmark info for post:", err)
        })
    }
    
    static func checkPostIdsForMessageCount(postIds: [String]?, completion: @escaping (Int) -> ()){
        
        // USED TO SUM UP CRED FOR POSTS AND LISTS

        
        var cumMessages = 0
        
        guard let postIds = postIds else {
            print("checkPostIdForListCount ERROR: No Post IDs")
            completion(0)
            return}
        
        if postIds.count == 0 {
            print("checkPostIdForListCount ERROR: No Post IDs")
            completion(0)
            return}
        
        let myGroup = DispatchGroup()
        
        myGroup.enter()
        for postId in postIds {
            myGroup.enter()
            if let post = postCache[postId] {
                // Check Post Cache
                cumMessages += post.messageCount
//                print("Post Cache: PostID: \(postId) | Messages: \(post.messageCount)")
                myGroup.leave()
                
            } else{
                Database.database().reference().child("post_messages").child(postId).child("messageCount").observeSingleEvent(of: .value, with: { (snapshot) in
                    let messageCount = snapshot.value as? Int ?? 0
                    cumMessages += messageCount
                    print("Firebase Query PostID: \(postId) | Message: \(messageCount) | Cum Message: \(cumMessages)")
                    myGroup.leave()
                    
                }, withCancel: { (err) in
                    print("Failed to fetch vote count for post:", err)
                    cumMessages += 0
                    myGroup.leave()
                    
                })
            }
        }
        myGroup.leave()
        
        myGroup.notify(queue: .main) {
            print("Fetched Votes For \(postIds.count) Messages: \(cumMessages)")
            completion(cumMessages)
        }
    }

        
    static func checkPostForSocial(post: Post, completion: @escaping (Post) -> ()){
        if Auth.auth().currentUser == nil {
            completion(post)
            return
        }
        
        var tempPost = post
        tempPost.updateFromChecks = false
        
        let start = DispatchTime.now() // <<<<<<<<<< Start time
        
        Database.checkPostForVotes(post: tempPost) { (post) in
            Database.checkPostForLists(post: post, completion: { (post) in
                Database.checkPostForMessages(post: post, completion: { (post) in
                    Database.checkPostForComments(post: post, completion: { (post) in
                        Database.checkPostIntegrity(post: post, completion: { (post) in
                            if let postId = post.id {
                                postCache[postId] = post
                                if post.updateFromChecks {
                                    let postDict:[String: String] = ["updatedPostId": postId]
                                    NotificationCenter.default.post(name: MainTabBarController.editUserPost, object: nil, userInfo: postDict)
                                }
                            }
        
                            let end = DispatchTime.now()   // <<<<<<<<<<   end time
                            let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
                            let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests
                            print("checkpostForSocial: \(timeInterval) seconds | \(post.id)")
                            completion(post)
                        })
                    })
                })
            })
        }
    }
    
    static func checkPostIntegrity(post: Post, completion: @escaping (Post) -> ()){
        if Auth.auth().currentUser == nil {
            completion(post)
            return
        }
        
//        Database.checkPostIsLegit(post: post) { (post) in
            Database.checkLocationSummaryID(post: post, completion: { (post) in
                if let postId = post.id {
                    postCache[postId] = post
                }
                completion(post)
            })
//        }
    }
    
    static func checkLocationSummaryID(post: Post, completion: @escaping (Post) -> ()){
        var tempPost = post
        var temp_dic = tempPost.dictionary()
        
        if post.locationSummaryID == "" &&  post.locationAdress.removingWhitespaces() != ""{
                Database.reverseGPSGoogle(GPSLocation: post.locationGPS, completion: { (appleLoc) in
                    if let _ = appleLoc?.locationSummaryID {
                        print("checkLocationSummaryID - FIX - \(tempPost.locationSummaryID) to \(appleLoc?.locationSummaryID) | \(post.id)")
                        tempPost.locationSummaryID = appleLoc?.locationSummaryID
                        temp_dic["locationSummaryID"] = appleLoc?.locationSummaryID
                        tempPost.updateFromChecks = true
                        Database.updatePostwithPostID(postId: tempPost.id, newDictionaryValues: temp_dic)
                    }
                })
        }
        
        completion(tempPost)
    }
    
    
    static func checkPostIsLegit(post: Post, completion: @escaping (Post) -> ()){
        var tempPost = post
        var isLegitCheck: Bool = false
        
        if let _ = tempPost.creatorListId {
            isLegitCheck = (tempPost.creatorListId?.contains(where: { (key,value) -> Bool in
                value == legitListName
            }))!
        }

        if tempPost.isLegit != isLegitCheck {
            print("checkPostIsLegit | \(tempPost.id) | Updating IsLegit to \(isLegitCheck)")
            Database.updatePostforLegit(postId: tempPost.id, isLegit: isLegitCheck)
            tempPost.isLegit = isLegitCheck
        }
        
        completion(tempPost)
        
    }
    
    static func checkCredForPostIds(postIds: [String]?, completion: @escaping (Int) -> ()){
        
        var cumCred = 0
        
        guard let postIds = postIds else{
            print("checkCredForPostIds: Error, No Post Ids")
            completion(cumCred)
            return
        }
        
        if postIds.count == 0 {
            print("checkCredForPostIds: Error, No Post Ids")
            completion(cumCred)
            return
        }
        
        Database.checkPostIdsForListCount(postIds: postIds, completion: { (lists) in
            cumCred += lists
            print("Total Cred for Posts: \(postIds.count) | Cred: \(cumCred)")
            completion(cumCred)
        })
        
        
        
//        Database.checkPostIdsForVoteCount(postIds: postIds) { (votes) in
//            cumCred += votes
//            Database.checkPostIdsForListCount(postIds: postIds, completion: { (lists) in
//                cumCred += lists
//                Database.checkPostIdsForMessageCount(postIds: postIds, completion: { (messages) in
//                    cumCred += messages
//                    print("Total Cred for Posts: \(postIds.count) | Cred: \(cumCred)")
//                    completion(cumCred)
//                })
//            })
//        }
    }
    
    static func checkIfFollowingUser(userId: String, followingUserId: String, completion: @escaping (Bool) -> ()){
                    
        Database.database().reference().child("following").child(userId).child("following").child(followingUserId).observeSingleEvent(of: .value, with: { (snapshot) in
                if let isFollowing = snapshot.value as? Int
                {
                    completion(isFollowing == 1)
                }
                else
                {
                    completion(false)
                }
            }, withCancel: { (err) in
                print("Failed to check if \(userId) following \(followingUserId)", err)
            })
        }
    
    
    // MARK: - UPDATE SOCIAL COUNTS
    static func updateEmojiNameForUser(emojiName: String?, emoji: String?, userUid: String?){
        guard let emoji = emoji else {return}
        guard let userUid = userUid else {return}
        EmojiDictionary[emoji] = emojiName?.lowercased()
        
        let ref = Database.database().reference().child("emojiDic").child(userUid)

        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            var list = currentData.value as? [String : AnyObject] ?? [:]
            list[emoji] = emojiName?.lowercased() as AnyObject?
            // Set value and report transaction success
            currentData.value = list
            print("updateEmojiNameForUser | Success | \(emoji) UPDATED TO TO \(emojiName)")
            NotificationCenter.default.post(name: AppDelegate.NewEmojiDic, object: nil)
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
        
    }
    
    static func updateSocialCountForList(listId: String!, credCount: Int?, emojis: [String]?){
        
        
        if listRefreshRecord[listId] == 1 {
            print(" BUSY | updateListWithPostDelete | \(listId) | updateSocialCountForList | \(credCount) Cred | \(emojis) Emojis")
            return
        } else {
            listRefreshRecord[listId] == 1
        }
        
        let ref = Database.database().reference().child("lists").child(listId)
        
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            
            guard let dictionary = snapshot.value as? [String: Any] else {
                print("No dictionary for list id: ", listId)
                return
            }
            
            var temp_dic = dictionary
            
            if let credCount = credCount {
                temp_dic["totalCred"] = credCount
            }
            
            if let emojis = emojis {
                temp_dic["topEmojis"] = emojis
            }
            
            Database.database().reference().child("lists").child(listId).updateChildValues(temp_dic, withCompletionBlock: { (err, ref) in
                if let err = err {
                    print("Failed to save list social data for :",listId, err)
                    return}
                
                print("  ~ SUCCESS updateSocialCountsForList | \(listId) | \(credCount) Total Cred | \(emojis?.joined()) Emojis")
                listRefreshRecord[listId] == 0

            })
            
            
        }) {(err) in
            print("Failed to fetch post for listId:",err)
            listRefreshRecord[listId] == 0

        }
    }
    
    static func updateRankForList(listId: String?, newRank: [String:Int]?){
        
        guard let newRank = newRank else {
            print("updateRankForList | ERROR | No Ranks")
            return
        }
        
        guard let listId = listId else {
            print("updateRankForList | ERROR | No Ranks")
            return
        }
        
        let ref = Database.database().reference().child("lists").child(listId).child("listRanks")
        ref.updateChildValues(newRank) { (error, ref) in
            if let error = error {
                print("updateRankForList | ERROR | \(error)")
            } else {
                print("updateRankForList | SUCCESS | \(listId) | \(newRank.count) Posts")
            }
        
            if let _ = listCache[listId] {
                var tempList = listCache[listId]
                tempList?.listRanks = newRank
                listCache[listId] = tempList
                print("updateRankForList | SUCCESS | Updated List Cache | \(listId) ")
            }
        }
    }
    
    static func updateVariableForList(listId: String!, variable: String!, newCount: Any){
        
        let ref = Database.database().reference().child("lists").child(listId)

        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            var list = currentData.value as? [String : AnyObject] ?? [:]
            list[variable] = newCount as AnyObject?
            // Set value and report transaction success
            currentData.value = list
            print("updateVariableForList | Success | \(listId) Updated \(variable) TO \(newCount)")
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    
    static func updateSocialCountsForPost(postId: String!, socialVariable: String!, newCount: Int!){
        
        
        let ref = Database.database().reference().child("posts").child(postId)
        
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            
            guard let dictionary = snapshot.value as? [String: Any] else {
                print("updateSocialCountsForPost | No dictionary for post id: ", postId)
                return
            }
            
            var temp_dic = dictionary
            
            temp_dic[socialVariable] = newCount
            Database.database().reference().child("posts").child(postId).updateChildValues(temp_dic, withCompletionBlock: { (err, ref) in
                if let err = err {
                    print("Failed to save user social data for :",postId, err)
                    return}
                
                print("   ~ Database | updateSocialCountsForPost SUCCESS | \(postId) \(socialVariable) to \(newCount)")
            })


        }) {(err) in
            print("Failed to fetch post for postid:",err)
        }
    }
    
    static func updateSocialCountsForPost_Lists(postId: String!, socialVariable: String!, newCount: Int!){
        
        let cacheId = "\(postId)_update\(socialVariable)"
        if processingCache[cacheId] == 1 {
            print("updateSocialCountsForPost_Lists | \(cacheId)")
            return
        }
        
        let values = [socialVariable: newCount] as! [String:Any]
        processingCache[cacheId] = 1
        
        Database.database().reference().child("post_lists").child(postId).updateChildValues(values, withCompletionBlock: { (err, ref) in
            if let err = err {
                print("Failed to save user social data for :",postId, err)
                processingCache[cacheId] = 0
                return}
            processingCache[cacheId] = 0

            print("updateSocialCountsForPost_Lists: SUCCESS | \(postId) \(socialVariable) to \(newCount)")
        })
    }
    
//    static func updateSocialCounts(uid: String!){
//
    // NEEDS UPDATING IF WANT TO USE
    
//        let myGroup = DispatchGroup()
//        let innerLoop = DispatchGroup()
//
//        //Social Data
//        var postCount: Int = 0
//        var followingCount: Int = 0
//        var followerCount: Int = 0
//        var listCount: Int = 0
//        var listedCount: Int = 0
//        var likedCount: Int = 0
//
//        let likeRef = Database.database().reference().child("likes")
//        let listRef = Database.database().reference().child("lists")
//        let followingRef = Database.database().reference().child("following")
//        let followerRef = Database.database().reference().child("follower")
//        let userPostRef = Database.database().reference().child("userposts")
//        let userRef = Database.database().reference().child("users")
//
//        myGroup.enter()
//        fetchAllPostIDWithCreatorUID(creatoruid: uid) { (postIds) in
//            // Fetch All Created Post Ids and loop through to collect social data
//            for postId in postIds {
//
//                innerLoop.enter()
//                // Check for received likes
//                likeRef.child(postId.id).child("likeCount").observeSingleEvent(of: .value, with: { (snapshot) in
//                    var postLikeCount = snapshot.value as? Int ?? 0
//                    likedCount += postLikeCount
////                    print("Current Post \(postId.id), likeCount: \(postLikeCount), CumLikeCount: \(likedCount)")
//                    innerLoop.leave()
//                })
//
//                innerLoop.enter()
//                // Check for received bookmarks
//                listRef.child(postId.id).child("listCount").observeSingleEvent(of: .value, with: { (snapshot) in
//                    var postBookmarkCount = snapshot.value as? Int ?? 0
//                    bookmarkedCount += postBookmarkCount
////                    print("Current Post \(postId.id), bookmarkCount: \(postBookmarkCount), CumBookmarkCount: \(bookmarkedCount)")
//
//                    innerLoop.leave()
//                })
//            }
//            innerLoop.notify(queue: .main) {
//                myGroup.leave()
//            }
//        }
//
//        // Check for following count
//        myGroup.enter()
//        followingRef.child(uid).child("followingCount").observeSingleEvent(of: .value, with: { (snapshot) in
//            var userFollowingCount = snapshot.value as? Int ?? 0
//            followingCount += max(0,userFollowingCount)
//            myGroup.leave()
//
//        })
//
//        // Check for follower count
//        myGroup.enter()
//        followerRef.child(uid).child("followingCount").observeSingleEvent(of: .value, with: { (snapshot) in
//            var userFollowerCount = snapshot.value as? Int ?? 0
//            followerCount += max(0,userFollowerCount)
//            myGroup.leave()
//        })
//
//        // Check for post count
//        myGroup.enter()
//        userPostRef.child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
//            var userPosts = snapshot.value as? [String:Any]
//            var userPostCount = userPosts?.count ?? 0
//            postCount += max(0,userPostCount)
//            myGroup.leave()
//        })
//
//        // Check for bookmarks count
//        myGroup.enter()
//        userRef.child(uid).child("lists").child("bookmarkCount").observeSingleEvent(of: .value, with: { (snapshot) in
//            var userBookmarkCount = snapshot.value as? Int ?? 0
//            bookmarkCount += max(0,userBookmarkCount)
//            myGroup.leave()
//        })
//
//        myGroup.notify(queue: .main) {
//
//
//            let values = ["postCount": postCount, "followingCount": followingCount, "followerCount": followerCount, "listCount": bookmarkCount, "listedCount": bookmarkedCount, "likedCount": likedCount] as [String:Any]
//
//            userRef.child(uid).child("social").updateChildValues(values, withCompletionBlock: { (err, ref) in
//                if let err = err {
//                    print("Failed to save user social data for :",uid, err)
//                    return}
//
//                    print("Successfully save user social data for : \(uid)", values)
//                })
//            }
//    }
    
// Upload/Update Post
    
    static func updatePostwithPostID( post: Post, newDictionaryValues: [String:Any]){
        
        Database.database().reference().child("posts").child(post.id!).updateChildValues(newDictionaryValues) { (err, ref) in
            if let err = err {
                print("Fail to Update Post: ", post.id, err)
                return
            }
            print("Succesfully Updated Post: ", post.id, " with: ", newDictionaryValues)
            
            // Update Post Cache
            var tempPost = Post.init(user: post.user, dictionary: newDictionaryValues)
            tempPost.id = post.id
            postCache[post.id!] = tempPost
            
        }
        
    }
    
    static func updatePostwithPostID( postId: String?, newDictionaryValues: [String:Any]){
        
        guard let postId = postId else {
            print("updatePostwithPostID ERROR | No Post ID")
            return
        }
        
        Database.database().reference().child("posts").child(postId).updateChildValues(newDictionaryValues) { (err, ref) in
            if let err = err {
                print("Fail to Update Post: ", postId, err)
                return
            }
            print("Succesfully Updated Post: ", postId, " with: ", newDictionaryValues)
            
        }
        
    }
    
    static func updateUserPostwithPostID(creatorId: String, postId: String, values: [String:Any]){
        
        Database.database().reference().child("userposts").child(creatorId).child(postId).updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Fail to Update Post: ", postId, err)
                return
            }
            print("Succesfully Updated Post: ", postId, " with: ", values)
            
        }
        
    }
    
    

    
//    static func checkUserPopularImages(uid: String, posts: [Post]){
//        if posts.count == 0 {
//            print("No Posts | Return | \(uid)")
//            return
//        }
//
//        // MOST POPULAR IMAGES
//
//        var imageUrls: [String] = []
//        var imageUrlsArray:[String] = []
//        var sortedPost = posts.sorted(by: { (p1, p2) -> Bool in
//            p1.credCount > p2.credCount
//        })
//        for post in sortedPost {
//            if imageUrls.count < 8 {
//                if post.smallImageUrl != nil {
//                    imageUrls.append("\(post.smallImageUrl),\((post.id)!)")
//                    imageUrlsArray.append(post.smallImageUrl)
//                }
//            }
//        }
//
//        // CHECK IF NEED TO UPLOAD
//        var sameImages = true
//        for url in imageUrlsArray {
//            if !user.popularImageUrls.contains(url) {
//                sameImages = false
//            }
//        }
//
//        if sameImages {
//            print("Same Image Urls | Return | \(uid)")
//            return
//        }
//
//        // UPDATE USER OBJECT
//
//        let ref = Database.database().reference().child("users").child(uid)
//        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
//            var user = currentData.value as? [String : AnyObject] ?? [:]
//
//            user["popularImageUrls"] = imageUrls as AnyObject?
//
//            // Set value and report transaction success
//            currentData.value = user
//            print("Successfully Update User \(uid) | \(imageUrls.count) Image URLs")
//            return TransactionResult.success(withValue: currentData)
//
//        }) { (error, committed, snapshot) in
//            if let error = error {
//                print(error.localizedDescription)
//            }
//        }
//    }
    
    static func updateUserPopularImages(user: User?){
        guard let user = user else {return}
        let uid = user.uid
        Database.fetchAllPostWithUID(creatoruid: uid) { (posts) in
            if posts.count == 0 {
                print("No Posts | Return | \(uid)")
                return
            }
            
            // MOST POPULAR IMAGES
            
            var imageUrls: [String] = []
            var imageUrlsArray:[String] = []
            var sortedPost = posts.sorted(by: { (p1, p2) -> Bool in
                p1.credCount > p2.credCount
            })
            for post in sortedPost {
                if imageUrls.count < 8 {
                    if post.smallImageUrl != nil {
                        imageUrls.append("\(post.smallImageUrl),\((post.id)!)")
                        imageUrlsArray.append(post.smallImageUrl)
                    }
                }
            }
            
            // CHECK IF NEED TO UPLOAD
            var sameImages = true
            for url in imageUrlsArray {
                if !user.popularImageUrls.contains(url) {
                    sameImages = false
                }
            }
            
            if sameImages {
                print("Same Image Urls | Return | \(uid)")
                return
            }
            
            // UPDATE USER OBJECT
            
            let ref = Database.database().reference().child("users").child(uid)
            ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                var user = currentData.value as? [String : AnyObject] ?? [:]
                
                user["popularImageUrls"] = imageUrls as AnyObject?
                
                // Set value and report transaction success
                currentData.value = user
                print("Successfully Update User \(uid) | \(imageUrls.count) Image URLs")
                return TransactionResult.success(withValue: currentData)
                
            }) { (error, committed, snapshot) in
                if let error = error {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    static func AddTagsForPost(post: Post){
        guard let postId = post.id else {
            print("Update Tags For Post: Error, no Post Id")
            return
        }
        
        if post.nonRatingEmoji.count == 0 {
            print("Update Tags For Post: Error, no Emojis for \(postId)")
            return
        }
        
        for emoji in post.nonRatingEmoji {
            Database.updatePostIdForTag(postId: postId, tag: emoji, add: 1)
        }
    }
    
    static func DeleteTagsForPost(post: Post){
        guard let postId = post.id else {
            print("Update Tags For Post: Error, no Post Id")
            return
        }
        
        if post.nonRatingEmoji.count == 0 {
            print("Update Tags For Post: Error, no Emojis for \(postId)")
            return
        }
        
        print("  ~ DeleteTagsForPost | Deleted \(post.nonRatingEmoji.count) Tags")
        for emoji in post.nonRatingEmoji {
            Database.updatePostIdForTag(postId: postId, tag: emoji, add: -1)
        }
    }
    
    static func updatePostIdForTag(postId: String?, tag: String?, add: Int){
        guard let postId = postId else {
            print("Update Tags For Post: Error, no Post Id")
            return}
        
        guard let tag = tag else {
            print("Update Tags For Post: Error, no Tag")
            return}
        
        if !(tag.containsOnlyEmoji) {
            print("Update Tags For Post: Error, not Emoji Tag")
            return}
        
        if !(add == 1 || add == -1) {
            print("Update Tags For Post: Error, not Valid Add Function")
            return}
        
        let tagRef = Database.database().reference().child("post_tags").child(tag)
        tagRef.runTransactionBlock({ (currentData) -> TransactionResult in
            var tags = currentData.value as? [String : AnyObject] ?? [:]
            var posts = tags["posts"] as? [String] ?? []
            var postCount = tags["postCount"] as? Int ?? 0
            
            if add == 1 {
                // Add postid to Tag
                if let index = posts.firstIndex(of: postId) {
                    // Post Id already exist
                    print("Add Post to Tag: Error, PostId already exist")
                    return TransactionResult.abort()
                } else {
                    // Post Id doesn't exist, add postId
                    posts.append(postId)
                    postCount += 1
                }
            }
            
            else if add == -1 {
                // Delete Post Id from Tag
                if let index = posts.firstIndex(of: postId) {
                    posts.remove(at: index)
                    postCount -= 1
                } else {
                    // Post Id doesn't exist, No Delete
                    print("Delete Post from Tag: Error, PostId does not exist")
//                    return TransactionResult.abort()
                }
            }
            
            tags["posts"] = posts as AnyObject?
            tags["postCount"] = max(0,postCount) as AnyObject?
            
            
            currentData.value = tags
            print("SUCCESS - Update Post to Tag | \(postId) to \(tag) : \(add)")
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print("Update Post to Tag: Error: ", postId, tag, add, error.localizedDescription)
            }
        }
    }
    
    static func blockPost(post: Post) {
        guard let postId = post.id else {
            return
        }
        print(" ! BLOCK POST | \(post.id)")
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let createdDate = Date().timeIntervalSince1970
        CurrentUser.blockedPosts[postId] = Date()

//         Create List Id in User
        let userRef = Database.database().reference().child("users").child(uid).child("blockPost")
        let values = [postId: createdDate] as [String:Any]
        userRef.updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Block Posts with User: ERROR: \(postId), User: \(uid)", err)
                return
            }

            userRef.keepSynced(true)
            print("Block Post with User: SUCCESS: \(postId), User: \(uid)")
            
            NotificationCenter.default.post(name: SharePhotoListController.updateFeedNotificationName, object: nil)
            NotificationCenter.default.post(name: SharePhotoListController.updateProfileFeedNotificationName, object: nil)
            NotificationCenter.default.post(name: SharePhotoListController.updateListFeedNotificationName, object: nil)
//                Database.spotChangeSocialCountForUser(creatorUid: uid, socialField: "lists_created", change: 1)
        }
    }
    
    static func respondToReportPost(post: Post, details: String) {
        guard let postId = post.id else {
            return
        }
        print(" ! RESPOND REPORT POST | \(post.id)")
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let createdDate = Date().timeIntervalSince1970
        let det = "\(createdDate),\(details)"

        let reportFlag = Database.database().reference().child("report_post").child(postId)
        reportFlag.runTransactionBlock({ (currentData) -> TransactionResult in
            var temp_post = currentData.value as? [String : AnyObject] ?? [:]
//            var respond: Dictionary<String, String>
//            respond = temp_post["response"] as? [String : String] ?? [:]
//            respond[createdDate] = details
            
            var respond = temp_post["response"] as? [String] ?? []
            respond.append(det)
            
            temp_post["response"] = respond as AnyObject
            currentData.value = temp_post
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(" ! Respond Post Report ERROR | \(postId) | \(error)")
            } else {
                print("  ~ SUCCESS Respond Post Report| \(postId) | \(det)")
            }
        }
    }
    
    static func blockUser(user: User) {
        let blockUid = user.uid
        print(" ! BLOCK USER | \(blockUid)")
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let createdDate = Date().timeIntervalSince1970
        CurrentUser.blockedUsers[blockUid] = Date()
        if let _ = userCache[user.uid] {
            userCache[user.uid]!.isBlockedByCurUser = true
        }
        if let row = allUsersFetched.firstIndex(where: {$0.uid == blockUid}) {
            allUsersFetched[row].isBlockedByCurUser = true
        }
        
//         Update Data in Blocking User
        let userRef = Database.database().reference().child("users").child(uid).child("blockUser")
        let values = [blockUid: createdDate] as [String:Any]
        userRef.updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Block Users ERROR: \(blockUid), User: \(uid)", err)
                return
            }

            userRef.keepSynced(true)
            print("Block User: SUCCESS: \(blockUid), User: \(uid)")
            self.handleFollowing(userUid: blockUid, hideAlert: true, forceUnfollow: true) {
                print("Cur User Force Unfollow \(blockUid) after blocking")
            }
            self.handleManualFollowing(followerUid: blockUid, followedUid: uid, hideAlert: true, forceUnFollow: true) {
                print("\(blockUid) Force Unfollow Cur User after blocking")
            }
            
            NotificationCenter.default.post(name: AppDelegate.UserFollowUpdatedNotificationName, object: nil)
//            NotificationCenter.default.post(name: SharePhotoListController.updateFeedNotificationName, object: nil)
//            NotificationCenter.default.post(name: SharePhotoListController.updateProfileFeedNotificationName, object: nil)
//            NotificationCenter.default.post(name: SharePhotoListController.updateListFeedNotificationName, object: nil)
//                Database.spotChangeSocialCountForUser(creatorUid: uid, socialField: "lists_created", change: 1)
        }
        
//         Update Data in Blocked User
        let userRefb = Database.database().reference().child("users").child(blockUid).child("blockByUser")
        let valuesb = [uid: createdDate] as [String:Any]
        userRefb.updateChildValues(valuesb) { (err, ref) in
            if let err = err {
                print("Block By Users ERROR: \(blockUid), User: \(uid)", err)
                return
            }
            print("Block By User: SUCCESS: \(blockUid), User: \(uid)")
        }
    }
    
    static func unBlockUser(user: User) {
        let blockUid = user.uid
        print(" ! UNBLOCK USER | \(blockUid)")
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let createdDate = Date().timeIntervalSince1970
        
    // UPDATE CACHE
        CurrentUser.blockedUsers[blockUid] = nil
        if let _ = userCache[user.uid] {
            userCache[user.uid]!.isBlockedByCurUser = false
        }
        if let row = allUsersFetched.firstIndex(where: {$0.uid == blockUid}) {
            allUsersFetched[row].isBlockedByCurUser = false
        }

//         Create List Id in User
        let userRef = Database.database().reference().child("users").child(uid).child("blockUser")
        let values = [blockUid: nil] as [String:Any]
        userRef.updateChildValues(values) { (err, ref) in
            if let err = err {
                print("UNBlock Users ERROR: \(blockUid), User: \(uid)", err)
                return
            }

            userRef.keepSynced(true)
            print("UNBlock User: SUCCESS: \(blockUid), User: \(uid)")
            
            NotificationCenter.default.post(name: AppDelegate.UserFollowUpdatedNotificationName, object: nil)
//            NotificationCenter.default.post(name: SharePhotoListController.updateFeedNotificationName, object: nil)
//            NotificationCenter.default.post(name: SharePhotoListController.updateProfileFeedNotificationName, object: nil)
//            NotificationCenter.default.post(name: SharePhotoListController.updateListFeedNotificationName, object: nil)
//                Database.spotChangeSocialCountForUser(creatorUid: uid, socialField: "lists_created", change: 1)
        }
        
//         Update Data in Blocked User
        let userRefb = Database.database().reference().child("users").child(blockUid).child("blockByUser")
        let valuesb = [uid: nil] as [String:Any]
        userRefb.updateChildValues(valuesb) { (err, ref) in
            if let err = err {
                print("UnBlock By Users ERROR: \(blockUid), User: \(uid)", err)
                return
            }
            print("UnBlock By User: SUCCESS: \(blockUid), User: \(uid)")
        }
    }
    
    static func blockMessage(messageThread: MessageThread) {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let blockId = messageThread.threadID
        print(" ! BLOCK Message | \(blockId)")

        let createdDate = Date().timeIntervalSince1970
        CurrentUser.blockedMessages[blockId] = Date()
        
//         Update Data in Blocking User
        let userRef = Database.database().reference().child("users").child(uid).child("blockMessage")
        let values = [blockId: createdDate] as [String:Any]
        userRef.updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Block Message ERROR: \(blockId), User: \(uid)", err)
                return
            }

            userRef.keepSynced(true)
            print("Block Message: SUCCESS: \(blockId), User: \(uid)")

            NotificationCenter.default.post(name: InboxController.newMsgNotificationName, object: nil)
        }
    }
    
    static func unBlockMessage(messageThread: MessageThread) {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let blockId = messageThread.threadID
        print(" ! UNBLOCK Message | \(blockId)")

        let createdDate = Date().timeIntervalSince1970
        CurrentUser.blockedMessages[blockId] = Date()
        
//         Update Data in Blocking User
        let userRef = Database.database().reference().child("users").child(uid).child("blockMessage")
        let values = [blockId: nil] as [String:Any]
        userRef.updateChildValues(values) { (err, ref) in
            if let err = err {
                print("UNBlock Message ERROR: \(blockId), User: \(uid)", err)
                return
            }

            userRef.keepSynced(true)
            print("UNBlock Message: SUCCESS: \(blockId), User: \(uid)")

            NotificationCenter.default.post(name: InboxController.newMsgNotificationName, object: nil)
        }
    }
    
    static func reportUser(user: User, details: String) {
        let reportUid = user.uid
        print(" ! REPORT User | \(reportUid) | \(details)")
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let createdDate = Date().timeIntervalSince1970
        
        let reportFlag = Database.database().reference().child("report_user").child(reportUid)
        reportFlag.runTransactionBlock({ (currentData) -> TransactionResult in
//            guard let curPost = currentData.value as? [String : AnyObject] else {
//                print(" ! reportPost Error: No Post", postId)
//                return TransactionResult.abort()
//            }
            var temp_post = currentData.value as? [String : AnyObject] ?? [:]
            var reports: Dictionary<String, String>
            reports = temp_post["reports"] as? [String : String] ?? [:]
            reports[uid] = "\(createdDate), \(details)"
            temp_post["reports"] = reports as AnyObject
            temp_post["reports_count"] = reports.count as AnyObject

            if reports.count > 0 {
                print("More than 3 reports. Move User to Private")
                self.flagUserToBlock(user: user, block: true)
//                self.moveReportedPost(post: post)
            }

            currentData.value = temp_post
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(" ! reportUser ERROR | \(reportUid) | \(error)")
            } else {
                // Update post Cache
                print("  ~ SUCCESS updateUserforReport| \(reportUid)")
            }
        }
        
        
        
    }
    
    static func flagUserToBlock(user: User, block: Bool) {
        let uid = user.uid
        
        Database.database().reference().child("users/\(uid)/reportedFlag").setValue(block)
        Database.database().reference().child("users/\(uid)/isPrivate").setValue(block)
        self.createNotificationEventForUser(postId: nil, listId: nil, targetUid: uid, action: Social.report, value: 1, locName: nil, listName: nil, commentText: nil)
        
        // Update Post Cache
        var temp = userCache[uid]
        if let _ = temp {
            temp?.reportedFlag = block
            temp?.isPrivate = block
            userCache[uid] = temp
        }

        print("flagUserToBlock SUCCESS \(uid) - \(block)")
    }
    
    static func reportPost(post: Post, details: String) {
        // REPORT POST makes a report count in the post itself. If its more than 3 reports it gets moved to the reportedPost tree and gets deleted in the main Post Tree.
        // Sends a notification to the creator. It was hard to let user access their own posts while blocking the rest
        
        guard let postId = post.id else {
            return
        }
        print(" ! REPORT POST | \(post.id) | \(details)")
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let createdDate = Date().timeIntervalSince1970
        
        let reportFlag = Database.database().reference().child("report_post").child(postId)
        reportFlag.runTransactionBlock({ (currentData) -> TransactionResult in
//            guard let curPost = currentData.value as? [String : AnyObject] else {
//                print(" ! reportPost Error: No Post", postId)
//                return TransactionResult.abort()
//            }
            var temp_post = currentData.value as? [String : AnyObject] ?? [:]
            var reports: Dictionary<String, String>
            reports = temp_post["reports"] as? [String : String] ?? [:]
            reports[uid] = "\(createdDate), \(details)"
            temp_post["reports"] = reports as AnyObject
            temp_post["reports_count"] = reports.count as AnyObject

            if reports.count > 0 {
                print("More than 3 reports. Move and Delete Post")
                self.flagPostToBlock(post: post, block: true)
//                self.moveReportedPost(post: post)
            }

            currentData.value = temp_post
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(" ! reportPost ERROR | \(postId) | \(error)")
            } else {
                // Update post Cache
                print("  ~ SUCCESS updatePostforReport| \(postId)")
            }
        }
        
        
//         Create List Id in User
//        let userRef = Database.database().reference().child("report").child(postId)
//        let values = [uid: createdDate] as [String:Any]
//        userRef.updateChildValues(values) { (err, ref) in
//            if let err = err {
//                print("Report Post By User: ERROR: \(postId), User: \(uid)", err)
//                return
//            }
//
//            userRef.keepSynced(true)
//            print("Report Post By User: SUCCESS: \(postId), User: \(uid)")
////                Database.spotChangeSocialCountForUser(creatorUid: uid, socialField: "lists_created", change: 1)
//        }
        
        // UPDATES REPORT DATA ON POST ID
        
//        let postRef = Database.database().reference().child("posts").child(postId)
//        postRef.runTransactionBlock({ (currentData) -> TransactionResult in
//            guard let curPost = currentData.value as? [String : AnyObject] else {
//                print(" ! reportPost Error: No Post", postId)
//                return TransactionResult.abort()
//            }
//            var temp_post = curPost
//            var reports: Dictionary<String, String>
//            reports = temp_post["reports"] as? [String : String] ?? [:]
//            reports[uid] = "\(createdDate), \(details)"
//            temp_post["reports"] = reports as AnyObject
//            temp_post["reports_count"] = reports.count as AnyObject
//            temp_post["reports_block"] = (reports.count > 0) as AnyObject
//
////            if reports.count > 0 {
////                print("More than 3 reports. Move and Delete Post")
////                self.moveReportedPost(post: post)
////            }
//
//            currentData.value = temp_post
//            return TransactionResult.success(withValue: currentData)
//
//        }) { (error, committed, snapshot) in
//            if let error = error {
//                print(" ! reportPost ERROR | \(postId) | \(error)")
//            } else {
//                // Update post Cache
//
//                print("  ~ SUCCESS updatePostforReport| \(postId)")
//            }
//        }
    }
    
    static func flagPostToBlock(post: Post, block: Bool) {
        guard let postId = post.id else {
            return
        }
        
        Database.database().reference().child("posts/\(postId)/reportedFlag").setValue(block)
        if let postCreatorUid = post.creatorUID {
            self.createNotificationEventForUser(postId: postId, listId: nil, targetUid: postCreatorUid, action: Social.report, value: 1, locName: nil, listName: nil, commentText: nil)
        }
        
        // Update Post Cache
        var temp = postCache[postId]
        if let _ = temp {
            temp?.reportedFlag = block
            postCache[postId] = temp
        }

        print("flagPostToBlock SUCCESS \(postId) - \(block)")
    }
    
    static func moveReportedPost(post: Post) {

        guard let postId = post.id else {
            print("moveReportedPost ERROR | No Post ID | \(post.id)")
            return
        }
        let postCreatorUid = post.creatorUID ?? ""
        let dict = post.dictionary()
        print(" ! moveReportedPost | \(post.id)")
        
        let userRef = Database.database().reference().child("blockedPost").child(postId)
        let values = dict as [String:Any]
        userRef.updateChildValues(values) { (err, ref) in
            if let err = err {
                print("moveReportedPost ERROR: \(postId)", err)
                return
            } else {
//                Database.database().reference().child("posts").child(post.id!).removeValue()
//                self.updateReportedPostForUser(post: post)
                self.createNotificationEventForUser(postId: postId, listId: nil, targetUid: postCreatorUid, action: Social.report, value: 1, locName: nil, listName: nil, commentText: nil)
                print("moveReportedPost SUCCESS: \(postId)")
            }
        }
    }
    
    
//    static func updateReportedPostForUser(post: Post) {
//        guard let postId = post.id else {
//            print("updateReportedPostForUser ERROR | No Post ID | \(post.id)")
//            return
//        }
//        guard let creatorId = post.creatorUID else {
//            print("updateReportedPostForUser ERROR | No User ID | \(post.id) | \(post.creatorUID)")
//            return
//        }
//
//        let createdDate = Date().timeIntervalSince1970
//        //         Create List Id in User
//        let userRef = Database.database().reference().child("user_reported").child(creatorId).child(postId)
//        userRef.updateChildValues(createdDate) { (err, ref) in
//            if let err = err {
//                print("updateReportedPostForUser: ERROR: \(postId), User: \(creatorId)", err)
//                return
//            }
//            print("updateReportedPostForUser: SUCCESS: \(postId), User: \(creatorId)")
//        }
//    }
    
    static func deletePost(post: Post){
        guard let postId = post.id else {
            return
        }
        print(" ! DELETE POST | \(post.id)")
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        Database.database().reference().child("posts").child(post.id!).removeValue()
        Database.database().reference().child("postlocations").child(post.id!).removeValue()
        Database.database().reference().child("userposts").child(post.creatorUID!).child(post.id!).removeValue()
        Database.database().reference().child("comments").child(post.id!).removeValue()

        Database.database().reference().child("post_lists").child(post.id!).removeValue()
        Database.database().reference().child("post_messages").child(post.id!).removeValue()
        Database.database().reference().child("post_votes").child(post.id!).removeValue()
        
        CurrentUser.postIds.removeAll { (postId) -> Bool in
            postId.id == post.id
        }
        
        // Remove emoji tags
        self.DeleteTagsForPost(post: post)
        
        // Remove from cache
        postCache.removeValue(forKey: post.id!)
        Database.spotChangeSocialCountForUser(creatorUid: uid, socialField: .posts_created, change: -1)
        
        // Bookmarked post is deleted when user fetches for post but it isn't there
//        Database.database().reference().child("bookmarks").child(post.creatorUID!).child(post.id!).removeValue()
        
        print("Post Delete @ posts, postlocations, userposts, bookmarks: ", post.id)

        for imageUrl in post.imageUrls {
            if imageUrl != "" {
                var deleteRef = Storage.storage().reference(forURL: imageUrl)
                deleteRef.delete(completion: { (error) in
                    if let error = error {
                        print("post image delete error for ", imageUrl)
                    } else {
                        print("Image Delete Success: ", imageUrl)
                    }
                })
            }
        }
        
        let smallImageUrl = post.smallImageUrl
        if post.smallImageUrl != "" {
            var smallDeleteRef = Storage.storage().reference(forURL: smallImageUrl)
            smallDeleteRef.delete(completion: { (error) in
                if let error = error {
                    print("post image delete error for ", smallImageUrl)
                } else {
                    print("Small Image Delete Success: ", smallImageUrl)
                }
            })
        }

        let postDict:[String: String] = ["updatedPostId": postId]
        NotificationCenter.default.post(name: MainTabBarController.deleteUserPost, object: nil, userInfo: postDict)
        
//        NotificationCenter.default.post(name: SharePhotoListController.updateFeedNotificationName, object: nil)
//        NotificationCenter.default.post(name: SharePhotoListController.updateProfileFeedNotificationName, object: nil)
//        NotificationCenter.default.post(name: SharePhotoListController.updateListFeedNotificationName, object: nil)
//        NotificationCenter.default.post(name: AppDelegate.RefreshAllName, object: nil)

        
        
    }
    
    static func deleteUser(user: User){
        
        print(" ! DELETE User | \(user.uid) | \(user.username)")
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Delete User ERROR. No Auth UID")
            return}
        guard let curUid = CurrentUser.uid else {
            print("Delete User ERROR. No Cur User UID")
            return}
        
        let userId = user.uid

        if uid != user.uid {
            print("Delete User ERROR. Not Auth User \(uid) \(userId)")
            return
        } else if uid != curUid {
            print("Delete User ERROR. Not Cur User \(uid) \(curUid)")
            return
        }

        // DELETE POSTS
        for (id, post) in CurrentUser.posts {
            Database.database().reference().child("posts").child(post.id!).removeValue()
            Database.database().reference().child("postlocations").child(post.id!).removeValue()
            Database.database().reference().child("comments").child(post.id!).removeValue()
            Database.database().reference().child("post_lists").child(post.id!).removeValue()
            Database.database().reference().child("post_messages").child(post.id!).removeValue()
            Database.database().reference().child("post_votes").child(post.id!).removeValue()


            for imageUrl in post.imageUrls {
                if imageUrl != "" {
                    var deleteRef = Storage.storage().reference(forURL: imageUrl)
                    deleteRef.delete(completion: { (error) in
                        if let error = error {
                            print("post image delete error for ", imageUrl)
                        } else {
                            print("Image Delete Success: ", imageUrl)
                        }
                    })
                }
            }
            
            let smallImageUrl = post.smallImageUrl
            if post.smallImageUrl != "" {
                var smallDeleteRef = Storage.storage().reference(forURL: smallImageUrl)
                smallDeleteRef.delete(completion: { (error) in
                    if let error = error {
                        print("post image delete error for ", smallImageUrl)
                    } else {
                        print("Small Image Delete Success: ", smallImageUrl)
                    }
                })
            }
        }
        
        for list in CurrentUser.lists {
            if let tempId = list.id {
                Database.database().reference().child("lists").child(tempId).removeValue()
            }
        }
        
        // DELETE USER PROFILE PICTURE
        var deleteRef = Storage.storage().reference(forURL: user.profileImageUrl)
        deleteRef.delete(completion: { (error) in
            if let error = error {
                print("profile image delete error for ", user.profileImageUrl)
            } else {
                print("Profile Image Delete Success: ", user.profileImageUrl)
            }
        })
        
        Database.database().reference().child("users").child(userId).removeValue()
        Database.database().reference().child("premium").child(userId).removeValue()
        Database.database().reference().child("userposts").child(userId).removeValue()
        Database.database().reference().child("userlists").child(userId).removeValue()
        Database.database().reference().child("userlikes").child(userId).removeValue()
        Database.database().reference().child("inbox").child(userId).removeValue()
        Database.database().reference().child("user_event").child(userId).removeValue()
        Database.database().reference().child("emojiDic").child(userId).removeValue()

        
        // DELETE FIREBASE USER
        let curUser = Auth.auth().currentUser
        curUser?.delete { error in
          if let error = error {
            print("Firebase Delete User ERROR: \(error)")
          } else {
              print("Firebase Delete User Success \(user.uid)")
          }
        }
        
        // DELETE APPLE USER
        if user.appleSignUp {
            removeAppleAccount()
        }
        
        do {
            try Auth.auth().signOut()
            CurrentUser.clear()
        } catch let signOutErr {
            print("Failed to sign out user After Deletion:", signOutErr)
        }
                

        
        print("SUCCESS DELETING USER \(user.username) | \(user.uid)")
    }
    
    static func removeAppleAccount() {
      let token = UserDefaults.standard.string(forKey: "refreshToken")

      if let token = token {
        
      
          let url = URL(string: "https://us-central1-shoutaroundtest-ae721.cloudfunctions.net/revokeToken?refresh_token=\(token)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "https://apple.com")!
                
          let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard data != nil else { return }
          }
          print("removeAppleAccount | \(token)")
          task.resume()
          
      }
    }
          
    
//    static func fetchMessageForUID( userUID: String, completion: @escaping ([Message]) -> ()) {
//        
//        let myGroup = DispatchGroup()
//        var messages = [] as [Message]
//        let ref = Database.database().reference().child("messages").child(userUID)
//        
//        ref.observeSingleEvent(of: .value, with: {(snapshot) in
//            
////            print(snapshot.value)
//            guard let userposts = snapshot.value as? [String:Any]  else {return}
//            
//            userposts.forEach({ (key,value) in
//            myGroup.enter()
//                
//                
//            guard let messageDetails = value as? [String: Any] else {return}
//            guard let senderUserUID = messageDetails["senderUID"] as? String else {return}
//            guard let postID = messageDetails["postUID"] as? String else {return}
//                
//            Database.fetchUserWithUID(uid: senderUserUID, completion: { (senderUser) in
//                
//            Database.fetchPostWithPostID(postId: postID, completion: { (post, error) in
//                
//                if let error = error {
//                  print(error)
//                    return
//                }
//                
//                let tempMessage = Message.init(uid: key, senderUser: senderUser, sendPost: post, dictionary: messageDetails)
//                
//                messages.append(tempMessage)
//                myGroup.leave()
//            })
//            })
//            })
//            
//            myGroup.notify(queue: .main) {
//                messages.sort(by: { (p1, p2) -> Bool in
//                    return p1.creationDate.compare(p2.creationDate) == .orderedDescending
//                })
//                completion(messages)
//            }
//            
//            })
//    }
//    
    static func fetchMessageThreadsForUID( userUID: String, completion: @escaping ([MessageThread]) -> ()) {
        
        let myGroup = DispatchGroup()
        var messageThreadIds = [] as [String]
        var messageThreads = [] as [MessageThread]
        let ref = Database.database().reference().child("inbox").child(userUID)
        
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            
            guard let userposts = snapshot.value as? [String:Any]  else {return}
            
            userposts.forEach({ (key, lastTime) in
                
                myGroup.enter()
                
                self.fetchMessageThread(threadId: key, completion: { (messageThread) in
                    var tempThread = messageThread
                    let lastReadTime = lastTime as? Double ?? 0
                    tempThread.lastCheckDate = Date(timeIntervalSince1970: lastReadTime)
                    messageThreads.append(tempThread)
                    myGroup.leave()
                })
            })
            
            myGroup.notify(queue: .main) {
                messageThreads = messageThreads.sorted { (m1, m2) -> Bool in
                    if m1.isRead != m2.isRead {
                        return (m1.isRead ? 0 : 1) > (m2.isRead ? 0 : 1)
                    } else {
                        return m1.lastMessageDate.compare(m2.lastMessageDate) == .orderedDescending
                    }
                }
                if userUID == Auth.auth().currentUser?.uid {
                    if CurrentUser.inboxThreads.count != messageThreads.count {
                        CurrentUser.inboxThreads = messageThreads
                    }
                }
                completion(messageThreads)
            }
        })
    }
    
    static func fetchMessageThread( threadId: String, completion: @escaping (MessageThread) -> ()) {
        let ref = Database.database().reference().child("messageThreads").child(threadId)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let threadDictionary = snapshot.value as? [String: Any] else {return}
            
            let tempThread = MessageThread.init(threadID: threadId, dictionary: threadDictionary)
            Database.fetchUsersForMessageThread(thread: tempThread) { (thread) in
                completion(thread)
            }
        }) { (error) in
                print("Error fetching message thread: \(threadId)", error)
        }
    }
    
    static func fetchUsersForMessageThread(thread: MessageThread, completion: @escaping (MessageThread) -> ()) {
        var userDic: [String: User] = [:]
        let myGroup = DispatchGroup()
        var tempThread = thread
        let threadUids = tempThread.threadUserUids
        if threadUids.count == 0 {
            completion(tempThread)
        } else {
            for uid in thread.threadUserUids {
                myGroup.enter()
                Database.fetchUserWithUID(uid: uid) { (user) in
                    userDic[uid] = user
                    myGroup.leave()
                }
            }
            
            myGroup.notify(queue: .main) {
                tempThread.userArray = userDic
                completion(tempThread)
            }
        }
    }
    
  // MARK: - CREATE LISTS

    
    // List
    
    static var defaultListCount = 0
    
    static func createDefaultList(uid: String, completion: @escaping ([List], [String]) -> ()){
        // Check for Default Lists
        
        var createdList: [List] = []
        var createdListIds: [String] = []
        
            Database.fetchUserWithUID(uid: uid) { (user) in
                // Fetch User
                
                // Fetch Lists
                Database.fetchListForMultListIds(listUid: user?.listIds, completion: { (fetchedLists) in
                    // Check if has bookmarked List
                    
                    // Indicator to detect if default list has been created
                    if defaultListCount == 0 {
                        defaultListCount += 1
                    } else {
                        return
                    }
                    
                    if !fetchedLists.contains(where: { $0.name == legitListName })
                    {
                            print("Missing Legit List. Create Legit List")
                            var defaultLegitList = emptyLegitList
                            defaultLegitList.id = NSUUID().uuidString
                            Database.createList(uploadList: defaultLegitList) {}
                            createdList.append(defaultLegitList)
                            createdListIds.append(defaultLegitList.id!)
                    }
                    
                    if !fetchedLists.contains(where: { $0.name == bookmarkListName })
                    {
                            print("Missing Bookmark List. Create Bookmark List")
                            var defaultBookmarkList = emptyBookmarkList
                            defaultBookmarkList.id = NSUUID().uuidString
                            Database.createList(uploadList: defaultBookmarkList) {}
                            createdList.append(defaultBookmarkList)
                            createdListIds.append(defaultBookmarkList.id!)
                    }
                    
                    completion(createdList, createdListIds)
                    
                })
            }
            
    }
    
    static func initAddList(){
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Create A New List", message: "Enter New List Name", preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.text = ""
        }
        
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            print("New List Name: \(textField?.text)")
            guard let newListName = textField?.text else {return}
            
            let listId = NSUUID().uuidString
            guard let uid = Auth.auth().currentUser?.uid else {return}
            self.checkListName(listName: newListName) { (listName) in
                
                let newList = List.init(id: listId, name: listName, publicList: 1)
                Database.createList(uploadList: newList) {}
                
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        // 4. Present the alert.
        var topController = UIApplication.shared.keyWindow!.rootViewController as! UIViewController
        
        while ((topController.presentedViewController) != nil) {
            topController = topController.presentedViewController!;
        }
        topController.present(alert, animated:true, completion:nil)
    }
    
    
    
    static func checkListName(listName: String?, completion: @escaping (String) -> ()){
        guard let listName = listName else {
            self.alert(title: "New List Requirement", message: "Please Insert List Name")
            return
        }
        if listName.isEmptyOrWhitespace() {
            self.alert(title: "New List Requirement", message: "Please Insert List Name")
            return
        }
        
        if CurrentUser.lists.contains(where: { (displayList) -> Bool in
            return displayList.name.lowercased() == listName.lowercased()
        }) {
            self.alert(title: "Duplicate List Name", message: "Please Insert Different List Name")
            return
        }
        
        completion(listName)
    }
    
    static func createList(uploadList: List, completion: @escaping () -> ()){
        // Code just updates list object. New list id is assigned before being created.
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let myGroup = DispatchGroup()
        myGroup.enter()

        if uploadList.id == nil {
            print("Create List: ERROR, No List ID")
            return
        }
        
        guard let listId = uploadList.id else {return}
        
        // Update New List in Current User Cache
        CurrentUser.addList(list: uploadList)
        
        // Create List Object
        
        let listRef = Database.database().reference().child("lists").child(listId)
        let createdDate = Date().timeIntervalSince1970
        let listName = uploadList.name
        let publicListInd = uploadList.publicList

        
        var values = ["name": listName, "createdDate": createdDate, "creatorUID": uid, "publicList": publicListInd] as [String:Any]
        
        if let description = uploadList.listDescription
        {
            values["listDescription"] = description
        }
        if let heroImageUrl = uploadList.heroImageUrl
        {
            values["heroImageUrl"] = heroImageUrl
        }
        
        if (uploadList.postIds?.count ?? 0) > 0
        {
            values["posts"] = uploadList.postIds
        }

        if ((uploadList.listImageUrls.count ?? 0) > 0 ) && ((uploadList.listImagePostIds.count ?? 0) > 0)
        {
            var tempSmallImageUrls: [String] = []

            for (index, smallUrl) in uploadList.listImageUrls.enumerated() {
                if index < uploadList.listImagePostIds.count {
                    let postId = uploadList.listImagePostIds[index]
                    var newImageUrl = "\(smallUrl),\(postId)"
                    tempSmallImageUrls.insert(newImageUrl, at: 0)
                }
            }
            values["listImageUrls"] = tempSmallImageUrls as AnyObject?
        }
        
        values["mostRecent"] = createdDate as AnyObject?
        
        if let heroImage = uploadList.heroImage {
            myGroup.enter()

            Database.saveImageToDatabase(uploadImages: [heroImage], smallImage: false) { (bigUrl, smallUrl) in
                values["heroImageUrl"] = bigUrl[0]
                myGroup.leave()
            }
        }
        
        myGroup.leave()

        myGroup.notify(queue: .main, execute: {
            print("CREATING NEW LIST | \(values)")
            
            
            if (uploadList.postIds?.count ?? 0) > 0
            {
                // UPDATE POST FOR LIST
                for (id, date) in uploadList.postIds!
                {
                    Database.updatePostForList(postId: id, postCreatorUid: uid, listId: listId, postCreationDate: createdDate)
                }
            }

            
            listRef.updateChildValues(values) { (err, ref) in
                if let err = err {
                    print("Create List Object: ERROR: \(listId):\(listName)", err)
                    return
                }
                print("Create List Object: Success: \(listId):\(listName)")
                
    //         Create List Id in User
                let userRef = Database.database().reference().child("users").child(uid).child("lists")
                let values = [listId: createdDate] as [String:Any]
                userRef.updateChildValues(values) { (err, ref) in
                    if let err = err {
                        print("Create List ID with User: ERROR: \(listId):\(listName), User: \(uid)", err)
                        return
                    }

                    listRef.keepSynced(true)
                    print("Create List ID with User: SUCCESS: \(listId):\(listName), User: \(uid)")
    //                Database.spotChangeSocialCountForUser(creatorUid: uid, socialField: "lists_created", change: 1)
                }
                
                let userListRef = Database.database().reference().child("userlists").child(uid)
                userListRef.updateChildValues(values) { (err, ref) in
                    if let err = err {
                        print("Create User List ID with User: ERROR: \(listId):\(listName), User: \(uid)", err)
                        return
                    }
                    
                    print("Create User List ID with User: SUCCESS: \(listId):\(listName), User: \(uid)")
                    userListRef.keepSynced(true)
                    Database.spotChangeSocialCountForUser(creatorUid: uid, socialField: .lists_created, change: 1)
                }
                
                let newListId:[String: String] = ["newListID": listId]

                NotificationCenter.default.post(name: TabListViewController.refreshListNotificationName, object: nil, userInfo: newListId)
                completion()
            }
            
            
        })
            
            

        
    }
    
    static func deleteList(uploadList: List){
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        guard let listId = uploadList.id else {
            print("Delete List: ERROR, No List ID")
            return
        }
        
        if defaultListNames.contains(listId) {
            print("Delete Default List Name Error")
            return
        }
        
        // Delete List in Current User Cache
        CurrentUser.removeList(list: uploadList)
        if let deleteIndex = listCache.index(forKey: listId) {
            listCache.remove(at: deleteIndex)
        }
    
        Database.database().reference().child("lists").child(listId).removeValue()
        print("Delete List Oject: Success \(uploadList.name)")
        
        Database.database().reference().child("users").child(uid).child("lists").child(listId).removeValue()
        print("Delete List Oject: Success: \(uploadList.name), User: \(uid)")
        
        Database.database().reference().child("userlists").child(uid).child(listId).removeValue()
        print("Delete List Oject: Success: \(uploadList.name), User: \(uid)")
        
        Database.spotChangeSocialCountForUser(creatorUid: uid, socialField: .lists_created, change: -1)

        let deleteListId:[String: String] = ["deleteListId": listId]

        NotificationCenter.default.post(name: MainTabBarController.deleteList, object: nil, userInfo: deleteListId)
        
        NotificationCenter.default.post(name: TabListViewController.refreshListNotificationName, object: nil)

    }
    
    static func updatePostforLegit(postId: String?, isLegit: Bool?) {
        
        guard let postId = postId else {
            print("updatePostforLegit ERROR | No PostID")
            return}
        
        guard let isLegit = isLegit else {
            print("updatePostforLegit ERROR | No isLegit")
            return}
        
        
        
        let postRef = Database.database().reference().child("posts").child(postId)
        postRef.runTransactionBlock({ (currentData) -> TransactionResult in
            guard let post = currentData.value as? [String : AnyObject] else {
                print(" ! Post Social Update Error: No Post", postId)
                return TransactionResult.abort()
            }
            var temp_post = post
            temp_post["isLegit"] = isLegit as AnyObject
            currentData.value = temp_post
            print("  ~ SUCCESS updatePostforLegit| \(postId) IsLegit: \(isLegit)")
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(" ! updatePostforLegit ERROR | \(postId) IsLegit: \(isLegit) | \(error)")
            }
        }
        
//        let values = ["isLegit": isLegit] as [String:Any]
//
//        Database.database().reference().child("posts").child(postId).updateChildValues(values, withCompletionBlock: { (err, ref) in
//            if let err = err {
//                print("Failed to save user social data for :",postId, err)
//                return}
//
//            print("updatePostforLegit SUCCESS | \(postId) IsLegit: \(isLegit)")
//        })
        
    }
    
    // ADD POST FOR LIST
//    - UPDATE LIST OBJECT FOR NEW POST
//    - UPDATE POST_LISTS DATABASE THAT TRACKS WHAT LIST ARE TAGGED FOR EACH POST
//    - CREATE USER EVENT TO NOTIFY POST CREATOR THAT THEIR POST IS BEING ADDED TO A LIST
    
    static func addPostForList(post: Post, postCreatorUid: String, listId: String?, postCreationDate: Double?, listName: String? = ""){
        // There are 3 places to modify post objects in list
        // 1. Post ID within List Object in List Database
        // 2. List ID within Post_List Object in Post_List Database
        // 3. List ID within Post object in Post Database if post creator == bookmarking user
        
        print("addPostForList | Post ID: \(post.id) | List ID: \(listId) | SmallImageURL: \(post.smallImageUrl)")
        guard let uid = Auth.auth().currentUser?.uid else {return}
        guard let listId = listId else {
            print("Add Post to List: ERROR, No List ID")
            return
        }
        
        guard let postId = post.id else {return}
        
        if listRefreshRecord[listId] == 1 {
            print(" BUSY | updateListWithPostDelete | \(listId) | Adding \(postId)")
            return
        } else {
            listRefreshRecord[listId] == 1
        }
        
        let listAddDate = Date().timeIntervalSince1970
        let listRef = Database.database().reference().child("lists").child(listId)
        let values = [postId: listAddDate] as [String:Any]
        var tempPost = post

        // UPDATE LIST CACHE
        if let list = listCache[listId] {
            Database.updateListWithPostAdd(list: list, post: tempPost)
        } else {
            Database.fetchListforSingleListId(listId: listId) { (list) in
                Database.updateListWithPostAdd(list: list, post: tempPost)
            }
        }
        
        
        // Add Post to List
//        listRef.child("posts").updateChildValues(values) { (err, ref) in
//            if let err = err {
//                print("Failed to save post \(postId) to List \(listId)", err)
//                return
//            }
//            print("Successfully save post \(postId) to List \(listId)")
//            listRef.keepSynced(true)
//
            // Refresh List Statistics - ImageUrls, Most common GPS
            
//            Database.refreshListItems(listId: listId)
//        }
        
        
        // Update Current User List
        CurrentUser.addPostToList(postId: postId, listId: listId)
        
        // Send Notification
        if uid != postCreatorUid {
            self.createNotificationEventForUser(postId: postId, listId: listId, targetUid: postCreatorUid, action: Social.bookmark, value: 1, locName: post.locationName, listName: listName, commentText: nil)
        }
        
        
        // Add to Post Lists
        Database.updatePostForList(postId: postId, postCreatorUid: postCreatorUid, listId: listId, postCreationDate: postCreationDate)
    }
    
    static func updatePostForList(postId: String?, postCreatorUid: String, listId: String?, postCreationDate: Double?) {
        
        guard let postId = postId else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        guard let listId = listId else {return}

        
        let postListRef = Database.database().reference().child("post_lists").child(postId)

        postListRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            
            var post = currentData.value as? [String : AnyObject] ?? [:]
            var lists: Dictionary<String, String>
            lists = post["lists"] as? [String : String] ?? [:]
            var listCount = post["listCount"] as? Int ?? 0
            var postDate = post["creationDate"] as? Double ?? 0
            
            // Add List to Post List with list creator uid
            listCount += 1
            lists[listId] = uid
            
            // Handle/Update Post Creation Date - DOESN'T LOOK LIKE ITS USED
            if let postCreationDate = postCreationDate {
                if postDate != postCreationDate {
                    postDate = postCreationDate
                }
            }
            
            post["listCount"] = listCount as AnyObject?
            post["lists"] = lists as AnyObject?
            post["creationDate"] = postDate as AnyObject?
            
            // Enables firebase sort by count adjusted by recency
            let  uploadTime = Date().timeIntervalSince1970/1000000000000000
            post["sort"] = (Double(listCount) + uploadTime) as AnyObject
            
            // Set value and report transaction success
            currentData.value = post
            print("Post_Lists Add: Success, \(postId) PostID | \(listId) ListID | \(lists[listId]) UID ")
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                
                var listName = (listCache[listId] != nil) ? listCache[listId]?.name : ""
        
            // CREATE LIST EVENT
                Database.createListEvent(listId: listId, listName: listName, listCreatorUid: uid, postId: postId, postCreatorUid: postCreatorUid, action: Social.bookmark, value: 1)

            // NOTIFY ALL USERS FOLLOWING LIST
                Database.fetchListforSingleListId(listId: listId, completion: { (list) in
                    if (list?.followers?.count ?? 0) > 0 {
                        print("addPostForList | Notifying \(list?.followers?.count) List Followers")

                        for (key, value) in (list?.followers)! {
                        Database.createUserFollowingListEvent(listId: listId, listName: listName, listCreatorUid: uid, postId: postId, postCreatorUid: postCreatorUid, receiverUid: key, action: Social.bookmark, value: 1)
                        }
                    }
                })
                
                spotUpdateSocialCountForPost(postId: postId, socialField: "listCount", change: 1)
                if postCreatorUid != "" {
                    spotChangeSocialCountForUser(creatorUid: postCreatorUid, socialField: .lists_received, change: 1)
                }
                
                listRefreshRecord[listId] == 0

//                var post = snapshot?.value as? [String : AnyObject] ?? [:]
//                var votes = post["votes"] as? [String : Int] ?? [:]
//                spotUpdateSocialCount(creatorUid: uid, receiverUid: creatorUid, action: "vote", change: voteChange)
                // Completion after updating Likes
//                completion()
            }
        }


        
        
        
        
    }
    
    
    
    static func DeletePostForList(postId: String?, postCreatorUid: String?, listId: String?, postCreationDate: Double?){
        guard let uid = Auth.auth().currentUser?.uid else {return}
        guard let listId = listId else {
            print("Delete Post in List: ERROR, No List ID")
            return}
        
        guard let postId = postId else {
            print("Delete Post in List: ERROR, No List ID")
            return}
        
        if listRefreshRecord[listId] == 1 {
            print(" BUSY | updateListWithPostDelete | \(listId) | Deleting \(postId)")
            return
        } else {
            listRefreshRecord[listId] == 1
        }
        
        
        // UPDATE LIST CACHE
        if let list = listCache[listId] {
            var tempList = list
            if let index = tempList.postIds?.index(forKey: postId) {
                tempList.postIds?.remove(at: index)
                listCache[listId] = tempList
            }
            Database.updateListWithPostDelete(list: list, postId: postId)
        } else {
            Database.fetchListforSingleListId(listId: listId) { (list) in
                Database.updateListWithPostDelete(list: list, postId: postId)
            }
        }
        
        
//        Database.database().reference().child("lists").child(listId).child("posts").child(postId).removeValue()
        print("    ~ SUCCESS | Database | DeletePostForList | \(postId) from ListId: \(listId)")
        
        // Update Current User List
        CurrentUser.removePostFromList(postId: postId, listId: listId)
        
        // Delete From Post Lists
        let postListRef = Database.database().reference().child("post_lists").child(postId)
        
        postListRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            
            guard let _ = currentData.value as? [String : AnyObject] else {
                print(" ! post_lists Deleted \(postId) | Error: Not in Database")
                return TransactionResult.success(withValue: currentData)
            }
            
            var post = currentData.value as? [String : AnyObject] ?? [:]
            var lists: Dictionary<String, String>
            lists = post["lists"] as? [String : String] ?? [:]
            var listCount = post["listCount"] as? Int ?? 0
            var postDate = post["creationDate"] as? Double ?? 0
            
            // Delete List to Post List
            if let deleteIndex = lists.index(forKey: listId) {
                listCount += -1
                lists.remove(at: deleteIndex)
            } else {
                print("DeletePostForList | ERROR, Can't Find Deleted ListId in Post?")
            }
            
            // Handle/Update Post Creation Date
            if let postCreationDate = postCreationDate {
                if postDate != postCreationDate {
                    postDate = postCreationDate
                }
            }
            
            post["listCount"] = listCount as AnyObject?
            post["lists"] = lists as AnyObject?
            post["creationDate"] = postDate as AnyObject?
            
            // Enables firebase sort by count adjusted by recency
            let  uploadTime = Date().timeIntervalSince1970/1000000000000000
            post["sort"] = (Double(listCount) + uploadTime) as AnyObject
            
            // Set value and report transaction success
            currentData.value = post
            print("DeletePostForList: Success, Post \(postId) | List \(listId) | \(lists[postId])")
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                var listName = (listCache[listId] != nil) ? listCache[listId]?.name : ""
                Database.createListEvent(listId: listId, listName: listName, listCreatorUid: uid, postId: postId, postCreatorUid: postCreatorUid, action: Social.bookmark, value: 0)
                
                
                // Refresh List Aggregate statistics
//                Database.refreshListItems(listId: listId)
                
                
                spotUpdateSocialCountForPost(postId: postId, socialField: "listCount", change: -1)
                if postCreatorUid != "" {
                    spotChangeSocialCountForUser(creatorUid: postCreatorUid, socialField: .lists_received, change: -1)
                }
                listRefreshRecord[listId] == 0

            }
        }
    }
    
    
//    static func sortList(inputList: [List]?, completion: @escaping ([List]) -> ()){
//        guard let inputList = inputList else {
//            print("Sort List: Error, No List")
//            completion([])
//            return
//        }
//        
//        if inputList.count == 0 {
//            print("Sort List: Error, No List")
//            completion([])
//            return
//        }
//        
//        // Sort Display List
//        var sortedList = inputList.sorted(by: { (p1, p2) -> Bool in
//            return p1.creationDate.compare(p2.creationDate) == .orderedAscending
//        })
//
//        var tempList: [List] = []
//        // Find Legit
//        if let temp = sortedList.index(where: {$0.name == legitListName}){
//            tempList.append(sortedList[temp])
//        }
//    
//        // Find Bookmark
//        if let temp = sortedList.index(where: {$0.name == bookmarkListName}){
//            tempList.append(sortedList[temp])
//        }
//        
//        for list in sortedList {
//            if (list.name != legitListName && list.name != bookmarkListName && tempList.index(where: {$0.id == list.id}) == nil ){
//                tempList.append(list)
//            }
//        }
//        
//        completion(tempList)
//    }
    
    static func handleUnfollowList(userUid: String?, followedList: List?, completion: @escaping () -> Void){
        guard let userUid = userUid else {
            print("   ~ Database | UnFollow List Error | No User Uid")
            return
        }
        
        guard let followedList = followedList else {
            print("   ~ Database | UnFollow List Error | No Followed List Object")
            return
        }
        
        guard let listId = followedList.id else {
            print("   ~ Database | UnFollow List Error | No Followed List Id")
            return
        }
        
        let listRef = Database.database().reference().child("followinglists").child(userUid)
        listRef.child(listId).removeValue()
        print("handleUnfollowList | followinglists Removed | \(listId)")
        CurrentUser.followedListIds.removeAll { (curFollowedLists) -> Bool in
            curFollowedLists == listId
        }
        self.createNotificationEventForUser(postId: nil, listId: listId, targetUid: followedList.creatorUID, action: Social.follow, value: 0, locName: nil, listName: followedList.name, commentText: nil)

        listRef.keepSynced(true)
        self.handleFollowedList(userUid: userUid, followedList: followedList, followedValue: -1, completion: {
            NotificationCenter.default.post(name: TabListViewController.newFollowedListNotificationName, object: nil)
            completion()
        })
    }
    
    static func handleFollowingListId(userUid: String?, followedListId: String?, completion: @escaping () -> Void){
        guard let userUid = userUid else {return}
        guard let followedListId = followedListId else {return}
        
        Database.fetchListforSingleListId(listId: followedListId) { (list) in
            guard let list = list else {
                print("handleFollowingListId | ERROR | No List Was Found | \(followedListId)")
                return
            }
            
            Database.handleFollowingList(userUid: userUid, followedList: list, completion: {
                print("   - Success | handleFollowingListId | \(userUid) User | \(followedListId) List ID")
            })
        }

        
    }

    static func handleFollowingList(userUid: String?, followedList: List?, completion: @escaping () -> Void){
        guard let userUid = userUid else {
            print("   ~ Database | Follow List Error | No User Uid")
            return
        }
        
        guard let followedList = followedList else {
            print("   ~ Database | Follow List Error | No Followed List Object")
            return
        }
        
        guard let listId = followedList.id else {
            print("   ~ Database | Follow List Error | No Followed List Id")
            return
        }
        
        let listName = followedList.name
        let listCreatorUid = followedList.creatorUID
        let listCreationDate = followedList.creationDate.timeIntervalSince1970
        
        let followingListRef = Database.database().reference().child("followinglists").child(userUid)
        let followedDate = Date().timeIntervalSince1970
        let values = ["listName": listName, "followDate": followedDate, "listCreatorUID": listCreatorUid, "listCreatedDate": listCreationDate, "lastLoadDate": listCreationDate] as [String:Any]

        followingListRef.child(listId).updateChildValues(values) { (err, ref) in
            if let err = err {
                print("ERROR Created Follow List Object: \(userUid) following \(listName) | \(listId)", err)
                return
            } else {
                print("handleFollowList | followinglists Created | \(listId)")
                
                CurrentUser.followedListIds.append(listId)
                followingListRef.keepSynced(true)
                
                let tempList = ListId.init(id: listId, dictionary: values)
                CurrentUser.followedListIdObjects.append(tempList)
                self.setupUserFollowedListListener(listIds: [tempList])
                
                self.handleFollowedList(userUid: userUid, followedList: followedList, followedValue: 1, completion: {
                    completion()
                    self.createNotificationEventForUser(postId: nil, listId: listId, targetUid: followedList.creatorUID, action: Social.follow, value: 1, locName: nil, listName: followedList.name, commentText: nil)
                    NotificationCenter.default.post(name: TabListViewController.newFollowedListNotificationName, object: nil)

                })
            }
        }
    }

    static func handleFollowedList(userUid: String?, followedList: List?, followedValue: Int?,  completion: @escaping() ->()){
        guard let userUid = userUid else {
            print("   ~ Database | Follow List Error | No User Uid")
            return
        }
        
        guard let followedList = followedList else {
            print("   ~ Database | Follow List Error | No Followed List Object")
            return
        }
        
        guard let listId = followedList.id else {
            print("   ~ Database | Follow List Error | No Followed List Id")
            return
        }
        
        let ref = Database.database().reference().child("followedlists").child(listId)
        
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            var list = currentData.value as? [String : AnyObject] ?? [:]
            var followers: Dictionary<String, Double>
            followers = list["follower"] as? [String : Double] ?? [:]
            var followerCount = list["followerCount"] as? Int ?? 0
            let uploadTime = Date().timeIntervalSince1970

            if followedValue == 1 {
                // User gained a new follower
                if followers[userUid] != nil {
                    print("Add Follower: ERROR, /(followedUid) already has \(userUid) follower")
                } else {
                    followerCount += 1
                    followers[userUid] = uploadTime
                }
            } else {
                // User lost a follower
                if followers[userUid] != nil {
                    if let deleteIndex = followers.index(forKey: userUid){
                        followers.remove(at: deleteIndex)
                        followerCount -= 1
                    } else {
                        print("Follow Error, \(listId) not followed by \(userUid)")
                    }
                } else {
                    print("Follow Error, \(listId) not followed by \(userUid)")
                }
            }
            
            list["follower"] = followers as AnyObject?
            list["followerCount"] = followers.count as AnyObject?
            list["sort"] = (Double(followerCount) + uploadTime/1000000000000000) as AnyObject
            
            Database.updateVariableForList(listId: listId, variable: "followerCount", newCount: followers.count)
            
            // Set value and report transaction success
            currentData.value = list
            print("handleFollowedList | Success | \(listId) Followed By: \(userUid) | \(followerCount) Followed Users")
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                completion()
            }
        }
    }
    
    static func fetchFollowedListsForUser(userUid: String?, completion: @escaping ([List]) -> ()){
        guard let userUid = userUid else {
            print("fetchFollwingListsForUser ERROR | No User Uid")
            return
        }
        
        // Fetch All Lists
        self.fetchFollowedListIDs(userUid: userUid) { (listIds) in
            
            if listIds.count == 0 {
                print("fetchFollwingListsForUser ERROR | No Lists | \(userUid)")
                completion([])
                return
            }
            // OUTPUT is LIST ID : Last Date

            var userListIds: [String] = []
            
            for list in listIds {
                userListIds.append(list.listId)
            }
        
            
            // FETCH LIST OBJECTS
            self.fetchListForMultListIds(listUid: userListIds, completion: { (fetchedList) in
                print("   ~ Database | fetchFollwingListsForUser SUCCESS | \(userUid) | Fetched \(fetchedList.count) Lists")
                completion(fetchedList)
            })
        }
        
    }
    
    
    
    static func fetchFollowedListIDs(userUid: String?, completion: @escaping ([ListId]) -> ()){
        guard let userUid = userUid else {
            print("fetchFollowedListsForUser ERROR | No User Uid")
            return
        }
        
        var tempListIds: [ListId] = []
        
        let ref = Database.database().reference().child("followinglists").child(userUid)
        
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            guard let listDictionary = snapshot.value as? [String: Any] else {
                print("fetchFollowedListsForUser | \(userUid) | No Followed List Objects")
                ref.keepSynced(true)
                completion(tempListIds)
                return}
            
            for (key,value) in listDictionary {
                let tempListId = ListId.init(id: key, dictionary: value as! [String : Any])
                tempListIds.append(tempListId)
            }
            
            print("   ~ Database | fetchFollowedListsForUser SUCCESS | \(userUid) | \(tempListIds.count) / \(listDictionary.count) Followed Lists")
            ref.keepSynced(true)
            completion(tempListIds)
            
        }){ (error) in
            print("fetchListIdsForUser ERROR, \(userUid)", error)
            completion(tempListIds)
        }
    }

    static func fetchAllPostIdsForMultLists(listIds: [String]?, completion: @escaping ([PostId]) -> ()) {
        
        guard let listIds = listIds else {
            print("   ~ Database | fetchAllPostIdsForList ERROR | No List Id")
            return
        }
        
        var fetchedPostIds = [] as [PostId]
        let myGroup = DispatchGroup()

        self.fetchListForMultListIds(listUid: listIds) { (fetched_lists) in
            for list in fetched_lists {
                if let postIdCount = list.postIds?.count {
                    if postIdCount > 0 {
                        for (key,value) in list.postIds! {
                            let tempID = PostId.init(id: key, creatorUID: nil, sort: nil)
                            fetchedPostIds.append(tempID)
                        }
                    }
                }
            }
        
            print("   ~ Database | fetchAllPostIdsForList | \(listIds.count) Followed Lists | \(fetchedPostIds.count) Post Ids")
            completion(fetchedPostIds)
        }
    }
    
    static func fetchAllListsForUser(userUid: String?, followed: Bool = true, completion: @escaping ([List]) -> ()){
        guard let userUid = userUid else {
            print("fetchAllListsForUser ERROR | No User Uid")
            return
        }
        
        // Fetch All Lists
        self.fetchAllListIdsForUser(userUid: userUid, followed: followed) { (listIds) in
            
            guard let listIds = listIds else {
                print("fetchAllListsForUser ERROR | No Lists | \(userUid)")
                completion([])
                return
            }
            
            // FETCH LIST OBJECTS
            self.fetchListForMultListIds(listUid: listIds, completion: { (fetchedList) in
                print("   ~ Database | fetchAllListsForUser SUCCESS | \(userUid) | Fetched \(fetchedList.count) Lists")
                completion(fetchedList)
            })
        }
        
    }
    
    static func fetchCreatedListsForUser(userUid: String?, completion: @escaping ([List]) -> ()){
        guard let userUid = userUid else {
//            print("fetchCreatedListsForUser ERROR | No User Uid")
            return
        }
        
        if userUid == CurrentUser.uid && CurrentUser.lists.count > 0 {
            completion(CurrentUser.lists)
            return
        }
        
        // Fetch All Lists
        self.fetchCreatedListIds(userUid: userUid) { (listIds) in
            
            guard let listIds = listIds else {
//                print("fetchCreatedListsForUser ERROR | No Lists | \(userUid)")
                completion([])
                return
            }
            // OUTPUT is LIST ID : Last Date

            var userListIds: [String] = []
            
            for id in listIds.keys {
                userListIds.append(id)
            }
        
            
            // FETCH LIST OBJECTS
            self.fetchListForMultListIds(listUid: userListIds, completion: { (fetchedList) in
                print("   ~ Database | fetchCreatedListsForUser SUCCESS | \(userUid) | Fetched \(fetchedList.count) Lists")
                completion(fetchedList)
            })
        }
        
    }
    
    static func fetchCreatedListIds(userUid: String?, completion: @escaping ([String: Any]?) -> ()){
        guard let userUid = userUid else {
            print("fetchListIdsForUser ERROR | No User Uid")
            return
        }
        
        // OUTPUT is LIST ID : Last Date
        
        print("   ~ Database | fetchCreatedListIds | \(userUid)")

        let listref = Database.database().reference().child("userlists").child(userUid)

        listref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let listDictionary = snapshot.value as? [String: Any] else {
                print("~ No Lists For User | fetchListIdsForUser | \(userUid)")
                completion(nil)
                return}
            
            listref.keepSynced(true)
            completion(listDictionary)
            print("   ~ Database | fetchCreatedListIds | \(userUid) | SUCCESS | \(listDictionary.count) Lists")

            
        }) { (err) in
            print("fetchListIdsForUser ERROR, \(userUid)", err)
            completion(nil)
        }
        
//        print("fetchListIdsForUser END")

    }
    
    
    
    //        listref.observe(.value) { (snapshot) in
    //            guard let listDictionary = snapshot.value as? [String: Any] else {
    //                completion(nil)
    //                return}
    //
    //            //            print("TEST | \(listDictionary.count)")
    //            completion(listDictionary)
    //
    //        }
    
    //        ref.observeSingleEvent(of: .value, with: { (snapshot) in
    //
    //            guard let listDictionary = snapshot.value as? [String: Any] else {
    //                completion(nil)
    //                return}
    //            print("fetchListIdsForUser SUCCESS | \(userUid) | \(listDictionary.count) Lists")
    //            completion(listDictionary)
    //
    //        }) { (error) in
    //            print("fetchListIdsForUser ERROR, \(userUid)", error)
    //            completion(nil)
    //
    //        }
    
    //        ref.observeSingleEvent(of: .value, with: {(snapshot) in
    //            guard let listDictionary = snapshot.value as? [String: Any] else {
    //                completion(nil)
    //                return}
    //            print("fetchListIdsForUser SUCCESS | \(userUid) | \(listDictionary.count) Lists")
    //            completion(listDictionary)
    //
    //        }){ (error) in
    //            print("fetchListIdsForUser ERROR, \(userUid)", error)
    //            completion(nil)
    //        }
    

    static func fetchALLLists(completion: @escaping ([List]) -> ()) {
        
        var tempLists: [List] = []
        let myGroup = DispatchGroup()
        let ref = Database.database().reference().child("lists")
        var legitCount: Int = 0
        var bookmarkCount: Int = 0
        var noPostCount: Int = 0
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionaries = snapshot.value as? [String: Any] else {return}
            
            dictionaries.forEach({ (key,value) in
                myGroup.enter()

                guard let listDic = value as? [String:Any] else {
                    myGroup.leave()
                    return}
                
            // IGNORE LEGIT/BOOKMARK LISTS
                if let listName = listDic["name"] as? String {
                    if listName == legitListName || listName == bookmarkListName {
                        legitCount += (listName == legitListName) ? 1 : 0
                        bookmarkCount += (listName == bookmarkListName) ? 1 : 0
                        myGroup.leave()
                        return
                    }
                }
                
            // IGNORE LISTS WITH 0 POSTS
                if let postIds = listDic["posts"] as? [String:Any] {
                    if postIds.count == 0 {
                        noPostCount += 1
                        myGroup.leave()
                        return
                    }
                } else {
//                    print("fetchALLLists | No Posts | \(key)")
                    noPostCount += 1
                    myGroup.leave()
                    return
                }
                
                let fetchedList = List.init(id: key, dictionary: listDic)
                tempLists.append(fetchedList)
                myGroup.leave()
                
            })
            
            myGroup.notify(queue: .main) {

                tempLists.sort(by: { (u1, u2) -> Bool in
                    return (u1.postIds?.count ?? 0) > (u2.postIds?.count ?? 0)
                })
                
                print("fetchALLLists | \(tempLists.count) Lists | Total \(dictionaries.count) | Legit \(legitCount) | Bookmark \(bookmarkCount) | No Post \(noPostCount)")
                completion(tempLists)
            }
        })   { (err) in print ("fetchALLLists | Failed to fetch all Lists", err) }
        
    }
    
    static func fetchLegitLists(completion: @escaping ([List]) -> ()) {
        Database.fetchListForMultListIds(listUid: legitListIds) { (lists) in
            completion(lists)
        }
    }
    
//    static func DatabaseLegitLists() -> [List] {
//        Database.fetchListForMultListIds(listUid: legitListIds) { (lists) in
//            return lists
//        }
//    }
    
    
    
    static func fetchAllListIdsForUser(userUid: String?, followed: Bool = true, completion: @escaping ([String]?) -> ()){
        guard let userUid = userUid else {
            print("fetchListIdsForUser ERROR | No User Uid")
            return
        }
        
        let myGroup = DispatchGroup()
        var tempListIds: [String] = []
        var createdListCount = 0, followedListCount = 0
        var createdListIds: [String] = []
        var followedListIds: [String] = []

        myGroup.enter()
        self.fetchCreatedListIds(userUid: userUid) { (createdListIds) in
            if let createdListIds = createdListIds {
                for (key,value) in createdListIds {
                    tempListIds.append(key)
                }
            }
            createdListCount = createdListIds?.count ?? 0
            myGroup.leave()
        }
        
        if followed {
            myGroup.enter()
            self.fetchFollowedListIDs(userUid: userUid) { (followedListIds) in
                for list in followedListIds{
                    tempListIds.append(list.listId)
                }
                followedListCount = followedListIds.count ?? 0
                myGroup.leave()
            }
        }

        myGroup.notify(queue: .main) {
            var dupCheck: [String] = []
            var dupCount = 0
            
            for list in tempListIds {
                if dupCheck.contains(list) {
                    dupCount += 1
                    print("fetchAllListIdsForUser | DUP ListID | \(list)")
                } else {
                    dupCheck.append(list)
                }
            }
            
            print("   ~ Database | fetchAllListIds | \(createdListCount) Created | \(followedListCount) Followed | \(userUid) DUPS: \(dupCount)")
            completion(dupCheck)
        }
    }
    
    
    
    
    static func fetchListForMultListIds(listUid: [String]?, completion: @escaping ([List]) -> ()){
        
        guard let listUid = listUid else {
            print("Fetch Lists: ERROR, No List Ids")
            completion([])
            return
        }
        
        if listUid.count == 0 {
            print("Fetch Lists: ERROR, No List Ids")
            completion([])
        }
        
        print("   ~ Database | Fetching List Objects | \(listUid.count) List Ids")

        
        let myGroup = DispatchGroup()
        var fetchedLists = [] as [List]
        
        listUid.forEach { (key) in
            myGroup.enter()
            self.fetchListforSingleListId(listId: key, completion: { (fetchedList) in
                if let fetchedList = fetchedList {
                    fetchedLists.append(fetchedList)
                }
                myGroup.leave()
            })
        }
        
        myGroup.notify(queue: .main) {
            fetchedLists.sort(by: { (p1, p2) -> Bool in
                return p1.creationDate.compare(p2.creationDate) == .orderedAscending
            })
            completion(fetchedLists)
        }
    }
    
    static func updateTotalCredForList(listId: String?, total_cred: Int?) {
        guard let listId = listId else {
            print("updateTotalCredForList ERROR: No List ID")
            return
        }
        
        guard let total_cred = total_cred else {
            print("updateTotalCredForList ERROR: No Total Cred")
            return
        }
        
        let values = ["totalCred": total_cred] as [String:Any]
        let listRef = Database.database().reference().child("lists").child(listId)
        
        listRef.updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Update List CredCount: ERROR: \(listId) : \(total_cred)", err)
                return
            }
            print("Update List CredCount: SUCCESS: \(listId) : \(total_cred)", err)
        }
    }
    
    static func fetchListforSingleListId(listId: String, completion: @escaping(List?) -> ()){
        
        if let cachedList = listCache[listId] {
            if cachedList != nil {
                var temp = cachedList
                if let location = CurrentUser.currentLocation {
                    temp.listDistance = temp.listGPS?.distance(from: location) ?? 999999
                }
//                print("fetchListforSingleListId | Cache | \(listId)")
                completion(temp)
                return
            }
        }
    
        
        let ref = Database.database().reference().child("lists").child(listId)
        ref.keepSynced(true)
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            guard let listDictionary = snapshot.value as? [String: Any] else {
                completion(nil)
                return}
            
            let fetchedList = List.init(id: listId, dictionary: listDictionary)
            if let location = CurrentUser.currentLocation {
                fetchedList.listDistance = fetchedList.listGPS?.distance(from: location) ?? 999999
            }
            
            // Update For Total Cred
//            if listDictionary["totalCred"] == nil {
//                if (fetchedList.postIds?.count)! > 0 {
//                    var allPostIds = [] as [String]
//                    for (postID,value) in fetchedList.postIds! {
//                        allPostIds.append(postID)}
//
//                    Database.checkCredForPostIds(postIds: allPostIds) { (total_cred) in
//                        fetchedList.totalCred = total_cred
//                        completion(fetchedList)
//
//                        // Update Database
//                        self.updateTotalCredForList(listId: listId, total_cred: total_cred)
//                    }
//                }
//            } else {
//                completion(fetchedList)
//            }
            self.checkListForFollowers(list: fetchedList, completion: { (checkedList) in
                self.checkListForNewEvent(list: checkedList, completion: { (checkedList) in
                    if checkedList != nil
                    {
                        listCache[listId] = checkedList
                    }
                    completion(checkedList)
                })
            })

        }){ (error) in
            print("Fetch List ID: ERROR, \(listId)", error)
            completion(nil)
        }
    }
    
    static func updateListforPost(post: Post?, newList: [String:String]?, prevList:[String:String]?, completion:@escaping (Post?) ->()){
        
        print("   ~ Database | updateListforPost | ")
        
        // Find Deleted List
        let currentList = newList as! [String:String]? ?? [:]
        let previousList = prevList as! [String:String]? ?? [:]
        var deletedList: [String:String] = [:]
        var addedList: [String:String] = [:]
        let postCreationTime = post?.creationDate.timeIntervalSince1970
        
        guard let post = post else {return}
        
        guard let postId = post.id else {
            print("Update List for Post: ERROR, No PostID")
            return
        }
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        guard let creatorUid = post.creatorUID else {return}

        
    // Update Post Object if User is Post Creator
        if uid == post.creatorUID {
            let ref = Database.database().reference().child("posts").child(postId).child("lists")
            ref.updateChildValues(newList!) { (err, ref) in
                if let err = err {
                    print("Error Updating Creator List ID for Post: ",postId)
                } else {
                    print("Success Updating Creator List ID For Post: ",postId)
                }
            }
        }
        
        
        for (listId,listName) in previousList {
            if currentList[listId] == nil {
                deletedList[listId] = listName
            }
        }
        
        
        for (listId,listName) in currentList {
            if previousList[listId] == nil {
                addedList[listId] = listName
            }
        }
        
        print("\(postId) | Adding \(addedList.count) List | Deleting \(deletedList.count) List")
        
        for (list, listname) in deletedList {
            Database.DeletePostForList(postId: post.id, postCreatorUid: (post.creatorUID)!, listId: list, postCreationDate: postCreationTime)
        }
        
        
        for (list, listname) in addedList {
            Database.addPostForList(post: post, postCreatorUid: (post.creatorUID)!, listId: list, postCreationDate: postCreationTime, listName: listname)
        }
        
        var tempPost = post

        // Update All List Object in Post
        for (key,value) in (tempPost.allList) {
            if value == uid {
                tempPost.allList.removeValue(forKey: key)
            }
        }
        
        for (key,value) in currentList {
            tempPost.allList[key] = uid
        }
        
        let newListCount = tempPost.allList.count ?? 0
        tempPost.listCount = newListCount
        tempPost.selectedListId = newList
        tempPost.isLegit = (newList?.values.contains(legitListName))!
        // Update Creator List ID too if current user is creator
        if uid == tempPost.creatorUID {
            tempPost.creatorListId = newList
        }
        // Replace Post Cache
        postCache[postId] = tempPost
        let postDict:[String: String] = ["updatedPostId": postId]
        NotificationCenter.default.post(name: MainTabBarController.editUserPost, object: nil, userInfo: postDict)
        
        completion(tempPost)
        
    }
    
    // MARK: - NOTIFICATIONS
    
    static func saveEventInteraction(event: Event?) {
        guard let event = event else {return}
        guard let eventId = event.id else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        if event.readTime == nil && !event.read {
            print("Save Interaction | \(event.id)")
            let now = Date().timeIntervalSince1970
            let userReceiveRef = Database.database().reference().child("user_event").child(uid)
            
            if event.userFollowedListObject {
                let userReceiveRef = Database.database().reference().child("user_listEvent").child(uid)
            }
            
            var uploadDic: [String:Any] = [:]
            uploadDic["readTime"] = now
            
            userReceiveRef.child(eventId).updateChildValues(uploadDic) { (error, reft) in
                if let error = error {
                    print("   ~ Database | saveEventInteraction | ERROR | \(error)")
                } else {
                    print("   ~ Database | saveEventInteraction | SUCCESS | \(eventId) : \(now) | \(uid)")
                }
            }
            
            // UPDATE CURRENT
            if let index = CurrentUser.events.firstIndex(where: { (cur_event) -> Bool in
                cur_event.id == eventId
            }) {
                var tempEvent = CurrentUser.events[index]
                tempEvent.readTime = Date()
                CurrentUser.events[index] = tempEvent
                NotificationCenter.default.post(name: MainTabBarController.NewNotificationName, object: nil)
            }
            
        } else {
            print("   ~ Database | saveEventInteraction | SUCCESS | Already Saved")
        }
    }
    
    static func saveMessageInteraction(messageThread: MessageThread?) {
        guard let tempMessageThread = messageThread else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        if tempMessageThread.lastCheckDate > tempMessageThread.lastMessageDate {
            print("saveMessageInteraction | IGNORE | User: \(tempMessageThread.lastCheckDate) | Msg: \(tempMessageThread.lastMessageDate)")
            return
        }
        
        tempMessageThread.lastCheckDate = Date()
        tempMessageThread.isRead = true
        
        
        let uploadTime = Date().timeIntervalSince1970
        let ref = Database.database().reference().child("inbox")
        ref.child("\(uid)/\(tempMessageThread.threadID)").setValue(uploadTime)
        print("saveMessageInteraction | \(tempMessageThread.threadID) | \(Date())")


        if let row = CurrentUser.inboxThreads.firstIndex(where: {$0.threadID == tempMessageThread.threadID}) {
            CurrentUser.inboxThreads[row] = tempMessageThread
        } else {
            CurrentUser.inboxThreads.append(tempMessageThread)
        }
//        NotificationCenter.default.post(name: InboxController.newMsgNotificationName, object: nil)

        
    }

    static func saveMessageInteraction(messageUid: String?) {
        guard let messageUid = messageUid else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        let uploadTime = Date().timeIntervalSince1970
        let ref = Database.database().reference().child("inbox")
        ref.child("\(uid)/\(messageUid)").setValue(uploadTime)
        print("saveMessageInteraction | \(messageUid) | \(Date())")
        
        var tempThread = CurrentUser.inboxThreads.first { (thread) -> Bool in
            return thread.threadID == messageUid
        }
        guard let tempMessageThread = tempThread else {return}
        tempMessageThread.lastCheckDate = Date()
        tempMessageThread.isRead = true
        if let row = CurrentUser.inboxThreads.firstIndex(where: {$0.threadID == tempMessageThread.threadID}) {
            CurrentUser.inboxThreads[row] = tempMessageThread
        } else {
            CurrentUser.inboxThreads.append(tempMessageThread)
        }
//        NotificationCenter.default.post(name: InboxController.newMsgNotificationName, object: nil)
    }
    
    
//    static func saveListEventInteraction(event: Event?) {
//        guard let event = event else {return}
//        guard let eventId = event.id else {return}
//        guard let uid = Auth.auth().currentUser?.uid else {return}
//        if event.readTime == nil && !event.read {
//            print("Save Interaction | \(event.id)")
//            let now = Date().timeIntervalSince1970
//            let userReceiveRef = Database.database().reference().child("user_listEvent").child(uid)
//
//
//            var uploadDic: [String:Any] = [:]
//            uploadDic["readTime"] = now
//
//            userReceiveRef.child(eventId).updateChildValues(uploadDic) { (error, reft) in
//                if let error = error {
//                    print("   ~ Database | saveEventInteraction | ERROR | \(error)")
//                } else {
//                    print("   ~ Database | saveEventInteraction | SUCCESS | \(eventId) : \(now) | \(uid)")
//                    NotificationCenter.default.post(name: MainTabBarController.NewNotificationName, object: nil)
//                }
//            }
//
//            // UPDATE CURRENT
//
//            if let index = CurrentUser.listEvents.firstIndex(where: { (cur_event) -> Bool in
//                cur_event.id == eventId
//            }) {
//                var tempEvent = CurrentUser.listEvents[index]
//                tempEvent.readTime = Date()
//                CurrentUser.listEvents[index] = tempEvent
//            }
//
//
//        } else {
//            print("   ~ Database | saveEventInteraction | SUCCESS | Already Saved")
//        }
//    }
    
    static func updateListInteraction(list: List?) {
        guard let list = list else {return}
        if list.creatorUID == Auth.auth().currentUser?.uid {
            print("updateListInteraction | Not updating for list creator | \(list.name) | Creator: \(list.creatorUID)")
            return
        }
        guard let listId = list.id else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let now = Date().timeIntervalSince1970
        let value = ["lastLoadDate":now] as [String:Any]
        
        let listRef = Database.database().reference().child("followinglists").child(uid).child(listId)
        listRef.updateChildValues(value) { (err, ref) in
            if let err = err {
                print("updateListInteraction | ERROR | \(err)")
            } else {
            
                // REFRESH CURRENT USER LIST ID OBJECT CACHE
                if let listIndex = CurrentUser.followedListIdObjects.firstIndex(where: {$0.listId == listId}){
                    var temp = CurrentUser.followedListIdObjects[listIndex]
                    if temp.listId != listId {
                        print("updateListInteraction | Update Cache ERROR | \(listId) - \(temp.listId)")
                        return
                    }
                    temp.listLastLoadDate = Date()
                    CurrentUser.followedListIdObjects[listIndex] = temp

                    print("updateListInteraction | Success with Cache | \(temp.listName) | \(listId) | User: \(uid) | \(now)")

                } else {
                    print("updateListInteraction | Success NO CACHE | \(listId) | User: \(uid) | \(now)")
                }
                
                // UPDATE CURRENT USER
                CurrentUser.listEvents.removeAll(where: {$0.listId == list.id})
                
//                CurrentUser.unreadListEventCount = max(0, CurrentUser.unreadListEventCount - 1)
                NotificationCenter.default.post(name: MainTabBarController.NewNotificationName, object: nil)
                print("Trigger |  updateListInteraction | MainTabBarController.NewNotificationName")

            }
        }
        

    }
    
    
    static func createListEvent(listId: String?, listName: String?, listCreatorUid: String?, postId: String?, postCreatorUid: String?, action: Social?, value: Int? = 0) {
        
        // ALL THIS FUNCTION DOES IS TRACK WHEN LIST IS BEING CREATED AND WHAT POSTS ARE BEING ADDED/DELETED
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        guard let listId = listId else {return}
        guard let action = action else {return}
        if action != .create {
            guard let postCreatorUid = postCreatorUid else {return}
        }
        
        var ref = Database.database().reference().child("list_event").child(listId)

        if action == Social.bookmark {
            guard let postId = postId else {
                print("CreateListEvent | ERROR | Bookmarking without Post | \(listId) \(listName) \(action) \(postCreatorUid)")
                return
            }
        }
        
        var tempListName = listName ?? ""
        var eventId = NSUUID().uuidString
        let eventTime = Date().timeIntervalSince1970
        var value = min(1,value ?? 0)
        var uploadDic: [String:Any] = [:]
        
        switch (action) {
        case .like:
            uploadDic["action"] = "like"
        case .follow:
            uploadDic["action"] = "follow"
        case .bookmark:
            uploadDic["action"] = "bookmark"
        case .comment:
            uploadDic["action"] = "comment"
        case .create:
            uploadDic["action"] = "create"
        default:
            uploadDic["action"] = ""
        }
        
        uploadDic["postId"] = postId
        uploadDic["initUserUid"] = uid
        uploadDic["receiveUserUid"] = postCreatorUid
        uploadDic["listId"] = listId
        uploadDic["listName"] = tempListName
        uploadDic["eventTime"] = eventTime
        uploadDic["value"] = value
        
        
    // LIST CREATOR ADDING POSTS
        if listCreatorUid == uid && action == Social.bookmark {
            ref = ref.child("creator_event")
        }
        
        ref.child(eventId).updateChildValues(uploadDic) { (error, reft) in
            if let error = error {
                print("   ~ Database | CreateListEvent | ERROR | \(error)")
            } else {
                print("   ~ Database | CreateListEvent | SUCCESS | \(postId) : \(listId) | \(listName) : \(action)")
            }
        }
        
        
    // ADDING TO LIST EVENT - Adding Post to List
        if action == Social.bookmark {
            // ADDING TO POST EVENT IF ADDING POST TO LIST
            guard let postId = postId else {
                print("CreateListEvent | ERROR | Bookmarking without Post | \(listId) \(listName) \(action) \(postCreatorUid)")
                return
            }
            let refPost = Database.database().reference().child("post_event").child(postId)
            refPost.child(eventId).updateChildValues(uploadDic) { (error, reft) in
                if let error = error {
                    print("   ~ Database | CreateListEvent | ERROR | \(error)")
                } else {
                    print("   ~ Database | CreateListEvent | SUCCESS | \(postId) : \(listId) | \(listName) : \(action)")
                    print(reft)
                }
            }
        }
        
        var userUploadDic = uploadDic
        
//  ALREADY HANDLED UNDER CREATE POST EVENT
//    // ADDING RECEIVING USER EVENT - FOR POST ADDED TO LIST
//        if postCreatorUid != nil && postCreatorUid != ""{
//            guard let postCreatorUid = postCreatorUid else {return}
//            let userReceiveRef = Database.database().reference().child("user_event").child(postCreatorUid)
//            userReceiveRef.child(eventId).updateChildValues(userUploadDic) { (error, reft) in
//                if let error = error {
//                    print("   ~ Database | userReceiveRef List Event| ERROR | \(error)")
//                } else {
//                    print("   ~ Database | userReceiveRef List Event| SUCCESS | EVENT \(eventId) | \(postId) : \(listId) | \(listName) : \(action)")
//                }
//            }
//        }
//
//
//    // ADDING CREATING USER EVENT
//        if uid != postCreatorUid {
//            let userCreatorRef = Database.database().reference().child("user_event").child(uid)
//            userCreatorRef.child(eventId).updateChildValues(userUploadDic) { (error, reft) in
//                if let error = error {
//                    print("   ~ Database | userCreatorRef List Event| ERROR | \(error)")
//                } else {
//                    print("   ~ Database | userCreatorRef List Event| SUCCESS | EVENT \(eventId) | \(postId) : \(listId) | \(listName) : \(action)")
//                }
//            }
//        } else {
//            print("   ~ Database | userCreatorRef List Event| InitUser == PostCreator")
//        }


    }
    
    static func createUserFollowingListEvent(listId: String?, listName: String?, listCreatorUid: String?, postId: String?, postCreatorUid: String?, receiverUid: String?, action: Social?, value: Int? = 0) {
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        guard let listId = listId else {return}
        guard let postCreatorUid = postCreatorUid else {return}
        guard let receiverUid = receiverUid else {return}

        guard let action = action else {return}
        guard let postId = postId else {
            print("createUserFollowingListEvent | ERROR | Bookmarking without Post | \(listId) \(listName) \(action) \(postCreatorUid)")
            return
        }
        
        var tempListName = listName ?? ""
        var eventId = NSUUID().uuidString
        let eventTime = Date().timeIntervalSince1970
        var value = min(1,value ?? 0)
        var uploadDic: [String:Any] = [:]
        
        switch (action) {
        case .like:
            uploadDic["action"] = "like"
        case .follow:
            uploadDic["action"] = "follow"
        case .bookmark:
            uploadDic["action"] = "bookmark"
        case .comment:
            uploadDic["action"] = "comment"
        case .create:
            uploadDic["action"] = "create"
        default:
            uploadDic["action"] = ""
        }
        
        uploadDic["postId"] = postId
        uploadDic["initUserUid"] = uid
        uploadDic["receiveUserUid"] = postCreatorUid
        uploadDic["listId"] = listId
        uploadDic["listName"] = tempListName
        uploadDic["eventTime"] = eventTime
        uploadDic["value"] = value
    
        
        // ADDING TO LIST EVENT - Adding Post to List
        if action == Social.bookmark {

            // ADDING RECEIVNG USER EVENT
            let userReceiveRef = Database.database().reference().child("user_listEvent").child(receiverUid)
            userReceiveRef.child(eventId).updateChildValues(uploadDic) { (error, reft) in
                if let error = error {
                    print("   ~ Database | userReceiveRef List Event| ERROR | \(error)")
                } else {
                    print("   ~ Database | userReceiveRef List Event| SUCCESS | EVENT \(eventId) | \(postId) : \(listId) | \(listName) : \(action)")
                }
            }
        }
        
    }
        
    static func setupUserFollowingListener(uids: [String]?) {
        guard let uids = uids else {return}

        for uid in uids {
            self.addUserFollowingListener(uid: uid)
        }
    }
    
    static func addUserFollowingListener(uid: String?) {
        guard let uid = uid else {return}
        let modifiedDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!.timeIntervalSince1970
        Database.database().reference().child("userposts").child(uid).queryOrdered(byChild: "creationDate").queryStarting(afterValue: modifiedDate, childKey: "creationDate").observe(DataEventType.childAdded) { (data) in
            guard let dictionary = data.value as? [String: Any] else {
                return}
            let userDataDict:[String: String] = ["uid": uid, "postId": data.key]
            if CurrentUser.blockedPosts[data.key] == nil && CurrentUser.blockedUsers[uid] == nil && CurrentUser.blockedByUsers[uid] == nil {
//                print("User Listener | New User Post | \(uid) \(data.key)")
                NotificationCenter.default.post(name: MainTabBarController.newFollowedUserPost, object: nil, userInfo: userDataDict)
            }
        }
    }
    
    static func removeUserFollowingListener(uids: [String]?) {
        guard let uids = uids else {return}
        guard let curUid = Auth.auth().currentUser?.uid else {return}
        var tempUids = uids
  
        for uid in tempUids {
            Database.database().reference().child("userposts").child(uid).removeAllObservers()
        }
    }
    
    static func setupUserFollowedListListener(listIds: [ListId]?){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        guard let listIds = listIds else {return}
        if listIds.count == 0 {return}
        
        for listId in listIds {
            
            let listUID = listId.listId
            
            let listEventRef = Database.database().reference().child("list_event").child(listUID).child("creator_event")
            listEventRef.observe(DataEventType.childAdded) { (data) in
//                print("LIST EVENT | \(listUID)")

                guard let dictionary = data.value as? [String: Any] else {
                    return}
                var tempEvent = Event.init(id: data.key, dictionary: dictionary)
                if tempEvent.value == 0 {
                    // Don't update if posts are removed from List
//                    print("FollowedListListener | Value was 0  \(listId.listId)")
                    return
                }
                
                if CurrentUser.listEvents.contains(where: {$0.id == tempEvent.id}) {
                    // ALREADY FETCHED EVENT
//                    print("FollowedListListener | Already Fetched Event \(listId.listId)")
                    return
                }
                
                guard let list = CurrentUser.followedListIdObjects.first(where: {$0.listId == listId.listId}) else {
//                    print("FollowedListListener | ERROR | New List Event but User \(uid) not following List \(listId.listId)")
                    return
                }
                
                if tempEvent.eventTime > list.listLastLoadDate ?? Date.distantPast {
//                    print("FollowedListListener | New Followed List Event | \n\(tempEvent)")
                    guard let eventListId = tempEvent.listId else {return}
                    if !CurrentUser.followedListNotifications.contains(eventListId) {
                        CurrentUser.followedListNotifications.append(eventListId)
                    }
                    CurrentUser.listEvents.append(tempEvent)
                    
//                    self.summarizeNotification(event: tempEvent)
                    
                    // CLEAR CACHE TO FORCE RELOAD
                    if let listId = tempEvent.listId {
                        listCache[listId] = nil
//                        print("New Post Notification | Clear Cache For List | \(listId)")
                    }
                    
                    // REFRESHES NOTIFICATION PAGE
                    NotificationCenter.default.post(name: UserEventViewController.refreshNotificationName, object: nil)
                    
                    // REFRESHES TAB NOTIFICATION COUNT
                    NotificationCenter.default.post(name: MainTabBarController.NewNotificationName, object: nil)
//                    print("Trigger |  setupUserFollowedListListener | MainTabBarController.NewNotificationName")

                    // REFRESHES TAB LIST
                    NotificationCenter.default.post(name: TabListViewController.newFollowedListNotificationName, object: nil)
                }

            }
        }
        print("setupListListener | Added \(listIds.count) ")
        
    }
    
    
    static func refreshListItems(listId: String){
        Database.fetchListforSingleListId(listId: listId) { (list) in
            Database.refreshList(list: list)
        }
    }
    
    static func updateListDetails(list: List?, heroImageUrl: String?, heroImageUrlPostId: String?, listName: String?, description: String?, listUrl: String?) {
        guard let list = list else {return}
        guard let listId = list.id else {return}
        
        if heroImageUrl == nil && listName == nil && description == nil {
            print("updateListDetails | All Nils")
            return
        }
        
        if !list.needsUpdating {
            print("updateListDetails | No Need Update | \(list.name) | Needs Updating: \(list.needsUpdating)")
            return
        }
        
        
        let ref = Database.database().reference().child("lists").child(listId)
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            
            var listDic = currentData.value as? [String : AnyObject] ?? [:]
            
            // Image URL
            if heroImageUrl != nil && !((heroImageUrl?.isEmptyOrWhitespace()) ?? true) {
                listDic["heroImageUrl"] = heroImageUrl as AnyObject?
            }
            
            // Image URL Post Id
            if heroImageUrlPostId != nil && !((heroImageUrlPostId?.isEmptyOrWhitespace()) ?? true) {
                listDic["heroImageUrlPostId"] = heroImageUrlPostId as AnyObject?
            }
            
            // List Name
            if listName != nil && !(listName?.isEmptyOrWhitespace() ?? true) {
                listDic["name"] = listName as AnyObject?
            }
            
            // List Description
            if description != nil && !(description?.isEmptyOrWhitespace() ?? true) {
                listDic["listDescription"] = description as AnyObject?
            }
            
            // List Description
            if listUrl != nil && !(listUrl?.isEmptyOrWhitespace() ?? true) {
                listDic["listUrl"] = listUrl as AnyObject?
            }
            
            
            // Set value and report transaction success
            currentData.value = listDic
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            }
            
            if let _ = listCache[listId] {
                var tempList = listCache[listId]
                // Image URL
                if heroImageUrl != nil && !(heroImageUrl?.isEmptyOrWhitespace() ?? true) {
                    tempList?.heroImageUrl = heroImageUrl
                    print("updateListDetails | SUCCESS | Updated \(listId) for List Hero Image | \(heroImageUrl)")
                }
                
                // List Name
                if listName != nil && !(listName?.isEmptyOrWhitespace() ?? true) {
                    tempList?.name = listName ?? ""
                    print("updateListDetails | SUCCESS | Updated \(listId) for List Name | \(listName)")

                }
                
                // List Description
                if description != nil && !(description?.isEmptyOrWhitespace() ?? true) {
                    tempList?.listDescription = description
                    print("updateListDetails | SUCCESS | Updated \(listId) for Description | \(description)")

                }
                
                tempList?.needsUpdating = false
                
                listCache[listId] = tempList
            }
            
            ref.keepSynced(true)
            
            print("   ~ Database |  updateListDetails | \(list.name) \(listId) | Success | URL: \(heroImageUrl) | Name: \(listName) | Desc: \(description)")
            NotificationCenter.default.post(name: TabListViewController.refreshListNotificationName, object: nil)
            
            
        }
        
        
        
    }
    
    
    static func updateListHeroImage(list: List?, imageUrl: String?) {
        guard let list = list else {return}
        guard let imageUrl = imageUrl else {return}
        guard let listId = list.id else {return}
        
        
        let ref = Database.database().reference().child("lists").child(listId)
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            
            var listDic = currentData.value as? [String : AnyObject] ?? [:]
            
            // Image URL
            listDic["heroImageUrl"] = imageUrl as AnyObject?
            
            // Set value and report transaction success
            currentData.value = listDic
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            }
            
            if let _ = listCache[listId] {
                var tempList = listCache[listId]
                tempList?.heroImageUrl = imageUrl
                listCache[listId] = tempList
                print("updateListHeroImage | SUCCESS | Updated Cache for List Hero Image | \(listId) | \(imageUrl)")
            }
            
            ref.keepSynced(true)
            
            print("   ~ Database |  updateListHeroImage | Success | \(list.name) | \(imageUrl)")
            NotificationCenter.default.post(name: TabListViewController.refreshListNotificationName, object: nil)
            
            
        }
        

    }
    
    static func updateListWithPostAdd(list: List?, post: Post?) {
        
        guard let list = list else {return}
        guard let post = post else {return}
        guard let listId = list.id else {return}
        guard let postId = post.id else {return}
        let listAddDate = Date().timeIntervalSince1970
        let values = [postId: listAddDate] as! [String:Any]

        if listRefreshRecord[listId] == 1 {
            print(" BUSY | updateListWithPostDelete | \(list.name) | \(list.id) | Adding \(postId)")
            return
        } else {
            listRefreshRecord[listId] == 1
        }
        
        
        var newCenter: CLLocationCoordinate2D? = nil
        
        if post.locationGPS != nil {
            if !(post.locationGPS?.coordinate.latitude == 0 &&  post.locationGPS?.coordinate.longitude == 0){
                // New coordinate
                if let gps = list.listGPS {
                    let tempLocations = [gps, post.locationGPS]
                    newCenter = Database.centerManyLoc(locations: tempLocations as! [CLLocation])
                } else {
                    newCenter = post.locationGPS?.coordinate
                }
            }
        }
        
        
        // UPDATE LIST OBJECT ANYWAY SINCE MOST RECENT DATE WILL CHANGE
        let ref = Database.database().reference().child("lists").child(listId)
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            
            var listDic = currentData.value as? [String : AnyObject] ?? [:]
            
            
        // Image URL
            var tempImageUrls = listDic["listImageUrls"] as! [String]? ?? []
            var oldCount = tempImageUrls.count

            let newImageUrl = "\(post.smallImageUrl),\((post.id)!)"
            tempImageUrls.insert(newImageUrl, at: 0)
//            print("SmallImageURL Add | \(list.name) - \(listId) | \(oldCount) To \(tempImageUrls.count) Images | \(newImageUrl)")
            listDic["listImageUrls"] = tempImageUrls as AnyObject?

            
        // NEW HERO IMAGE
            if listDic["heroImageUrl"] == nil {
                listDic["heroImageUrl"] = post.imageUrls[0] as AnyObject?
                listDic["heroImageUrlPostId"] = post.id as AnyObject?
                print(" Updated \(list.name) with Hero Image From \(post.id) | Database | updateListWithPostAdd")
            }
            
            
        // POST ID
            var tempPosts = listDic["posts"] as! [String:Any]? ?? [:]
            var oldPostCount = tempPosts.count
            tempPosts[postId] = listAddDate
//            print("SmallImageURL Add | \(list.name) - \(listId) | \(oldPostCount) To \(tempPosts.count) Posts | \(postId)")
            print("updateListWithPost_ADD | \(list.name) - \(listId) | \(oldPostCount) To \(tempPosts.count) Posts | \(oldCount) To \(tempImageUrls.count) Images | \(postId) \n SmallImage - \(newImageUrl)")

            listDic["posts"] = tempPosts as AnyObject?
            
        // DATE
            listDic["mostRecent"] = listAddDate as AnyObject?

            
        // NEW LOCATION
            if newCenter != nil {
                let GPSLatitude = String(format: "%f", newCenter!.latitude)
                let GPSLongitude = String(format: "%f", newCenter!.longitude)
                let uploadGPS = GPSLatitude + "," + GPSLongitude
                listDic["location"] = uploadGPS as AnyObject?
            }


            
            // Set value and report transaction success
            currentData.value = listDic
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            }
            
            let dic = snapshot?.value as! [String: Any]
            // Update Cache
            let tempList = List.init(id: list.id, dictionary: dic)
            // UPDATE LIST CACHE
            listCache[listId] = tempList
            if let i = CurrentUser.lists.firstIndex(where: {$0.id == listId}) {
                CurrentUser.lists[i] = tempList
                CurrentUser.updateCurrentUserListPostIds()
            }
            ref.keepSynced(true)

            print("   ~ Database |  updateListWithPost_ADD | Success | \(tempList.name) - \(tempList.id) | \(tempList.listImageUrls.count) Small Images | \(tempList.postIds?.count) Posts")
            if let listId = list.id {
                let updatedListID:[String: String] = ["updatedListID": listId]
                NotificationCenter.default.post(name: TabListViewController.refreshListNotificationName, object: nil, userInfo: updatedListID)
            }
        }
        
        
        if newCenter != nil {
            print("   ~ Database |  updateListWithPost_ADD | Geofire | Update Location Because New Location Distance is | \(listId) | \(list.name)")
            let geofireRef = Database.database().reference().child("listlocations")
            let geoFire = GeoFire(firebaseRef: geofireRef)
           
            guard let newCenter = newCenter else {return}
            
            let newLoc = CLLocation(latitude: newCenter.latitude, longitude: newCenter.longitude)
            geoFire.setLocation(newLoc, forKey: listId) { (error) in
                if (error != nil) {
                    print("An error occured when saving Location \(newCenter) for List \(listId) : \(error)")
                } else {print("Saved location successfully! for Post \(listId)")}
            }
        }

        
        listRefreshRecord[listId] = 0

        
    }
    
    
    static func updateListWithPostDelete(list: List?, postId: String?) {
        
        guard let list = list else {return}

        guard let listId = list.id else {return}
        guard let postId = postId else {return}
        let listAddDate = Date().timeIntervalSince1970
        let values = [postId: listAddDate] as! [String:Any]
        
        
        var newCenter: CLLocationCoordinate2D? = nil
        
//        if post.locationGPS != nil {
//            if !(post.locationGPS?.coordinate.latitude == 0 &&  post.locationGPS?.coordinate.longitude == 0){
//                // New coordinate
//                if let gps = list.listGPS {
//                    let tempLocations = [gps, post.locationGPS]
//                    newCenter = Database.centerManyLoc(locations: tempLocations as! [CLLocation])
//                } else {
//                    newCenter = post.locationGPS?.coordinate
//                }
//            }
//        }
        if listRefreshRecord[listId] == 1 {
            print(" BUSY | updateListWithPost_DELETE | \(list.name) | \(list.id) | Deleting \(postId)")
            return
        } else {
            listRefreshRecord[listId] == 1
        }

        
        // UPDATE LIST OBJECT ANYWAY SINCE MOST RECENT DATE WILL CHANGE
        let ref = Database.database().reference().child("lists").child(listId)
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            
            var listDic = currentData.value as? [String : AnyObject] ?? [:]
            
            // POST ID DELETE
            var tempPosts = listDic["posts"] as! [String:Any]? ?? [:]
            var oldPostCount = tempPosts.count
            
            if let deleteIndex = tempPosts.index(forKey: postId)  {
                let temp = tempPosts.remove(at: deleteIndex)
            }
            
            listDic["posts"] = tempPosts as AnyObject?
            
            let postIdArray = Array(tempPosts.keys)
            
            // Delete Image URL
            var tempImageUrls = listDic["listImageUrls"] as! [String]? ?? []
            var oldCount = tempImageUrls.count
            
            for (index, url) in tempImageUrls.enumerated() {
                let textArray = url.components(separatedBy: ",")
                if textArray.count > 1 {
                    if textArray[1] == postId {
                        // Delete image URL for postId being deleted
                        if let deleteIndex = tempImageUrls.firstIndex(of: url) {
                            let temp = tempImageUrls.remove(at: deleteIndex)
                        }
                    } else if !postIdArray.contains(textArray[1]) {
                        // Delete image URL if postid is not in postId Array
                        if let deleteIndex = tempImageUrls.firstIndex(of: url) {
                            let temp = tempImageUrls.remove(at: deleteIndex)
                        }
                    }
                }
            }
            
            listDic["listImageUrls"] = tempImageUrls as AnyObject?

            
            print("   ~ updateListWithPost_DELETE | \(list.name) - \(listId) | \(oldPostCount) To \(tempPosts.count) Posts | \(oldCount) To \(tempImageUrls.count) Images | \(postId)")
            
            // DATE
            listDic["mostRecent"] = listAddDate as AnyObject?
            
            // Set value and report transaction success
            currentData.value = listDic
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            }
            
            let dic = snapshot?.value as! [String: Any]
            // Update Cache
            let tempList = List.init(id: list.id, dictionary: dic)
            // UPDATE LIST CACHE
            listCache[listId] = tempList
            
            if let i = CurrentUser.lists.firstIndex(where: {$0.id == listId}) {
                CurrentUser.lists[i] = tempList
                CurrentUser.updateCurrentUserListPostIds()
            }
            
            ref.keepSynced(true)
            
            print("   ~ Database |  updateListWithPostDelete | Success | \(tempList.name) - \(tempList.id) | \(tempList.listImageUrls.count) Small Images | \(tempList.postIds?.count) Posts")
            NotificationCenter.default.post(name: TabListViewController.refreshListNotificationName, object: nil)
        }
        
        listRefreshRecord[listId] = 0
        
        
    }
    
    static func refreshList(list: List?) {
        
        guard let list = list else {return}
        guard let listId = list.id else {return}
        guard let postIds = list.postIds else {return}
        
        var tempPosts: [Post] = []
        let myGroup = DispatchGroup()
        
        if listRefreshRecord[listId] == 1 {
            return
        } else {
            listRefreshRecord[listId] = 1
        }

        print("   ~ Database |  refreshList | \(listId) | \(list.name) | \(postIds.count) | Start")
        
    
        // FETCH POSTS
        for (id, date) in postIds {
            myGroup.enter()
            Database.fetchPostWithPostID(postId: id, completion: { (post, error) in
                if let error = error {
                    print("updateListCode | ERROR | List \(listId) | \(id)")
                    myGroup.leave()
                } else {
                    if let post = post {
                        tempPosts.append(post)
                    }
                    myGroup.leave()
                }
            })
        }
        
        // PROCESS POSTS AFTER FETCHING
        myGroup.notify(queue: .main, execute: {
            print("   ~ Database |  refreshList | \(listId) | \(list.name) | \(postIds.count) | \(tempPosts.count) Fetched Posts")
            
            var allPostLoc: [String] = [] // Location ID
            var allPostIDLoc: [String: String] = [:] // PostID: Location ID
            var allPostIDGPS: [String: CLLocation] = [:] // PostID: LocationGPS
            var tempLocations: [CLLocation] = []
            
            // POST LOCATION AVERAGE
            for post in tempPosts {
                guard let postId = post.id else {return}
                
                if let locId = post.locationSummaryID , let loc = post.locationGPS {
                    allPostLoc.append(locId)
                    allPostIDLoc[postId] = locId
                    allPostIDGPS[postId] = loc
                }
            }
            
            if allPostLoc.count == 0 {
                return
            }
            
            let countedSet = NSCountedSet(array: allPostLoc)
            let mostFrequent = countedSet.max { countedSet.count(for: $0) < countedSet.count(for: $1) } as! String
            
            var mostFrequentPosts = allPostIDLoc.filter({ (key,value) -> Bool in
                return (value == mostFrequent)
            })
            
            // AVERAGE OF ALL GPS COORDINATES OF THE MOST POPULAR LOCATION ID
            
            for (key,value) in mostFrequentPosts {
                if let gps = allPostIDGPS[key] {
                    tempLocations.append(gps)
                }
            }
            
            // MOST POPULAR IMAGES
            
            var imageUrls: [String] = []
            var imageUrlsArray:[String] = []
            
            
            var sortedPostIds = list.postIds?.sorted(by: { (a, b) -> Bool in
                let time1 = a.value as? Double ?? 0
                let time2 = b.value as? Double ?? 0
                return time1 > time2
            })
            print("   ~ Database |  refreshList | Sorted Post Ids: \(sortedPostIds?.count) | \(list.name) \(list.id)")
            
            /*
        // SORT BY RANK IF HAVE RANK
            if list.listRanks.count > 0 {
                let listRanks = list.listRanks
                var sortedIds: [String] = []
                
                for i in 1...8 {
                    if let id = listRanks.key(forValue: i) {
                        sortedIds.append(id)
                    }
                }
                
                // Fill in rest with others

                
                if let sortedPostIds = sortedPostIds {
                    for (id, value) in sortedPostIds {
                        if !sortedIds.contains(id) {
                            sortedIds.append(id)
                        }
                    }
                }
                
                
                
                for id in sortedIds {
                    if imageUrls.count < 8 {
                        let tempPost = tempPosts.filter({ (post) -> Bool in
                            post.id == id
                        })
                        if tempPost.count > 0 {
                            if tempPost[0].smallImageUrl != nil && tempPost[0].smallImageUrl.count > 0 {
                                imageUrls.append("\(tempPost[0].smallImageUrl),\(id)")
                                imageUrlsArray.append(tempPost[0].smallImageUrl)
                            }
                        }
                    }
                }
                
                print("   ~ Database |  refreshList | ImageUrls: RANKED | \(imageUrls.count) Images | \(list.name) : \(listId)")

            } else { */
                
        // SORT BY MOST RECENTLY ADDED TO LIST
                
                if let sortedPostIds = sortedPostIds {
                    for (postId, time) in sortedPostIds {
                        if imageUrls.count < 8 {
                            if let index = tempPosts.firstIndex(where: {$0.id == postId}) {
                                let post = tempPosts[index]
                                if post.smallImageUrl != nil && post.smallImageUrl.count > 0{
                                    imageUrls.append("\(post.smallImageUrl),\((post.id)!)")
                                    imageUrlsArray.append(post.smallImageUrl)
                                } else {
                                    print("\(post.id) missing small image | smallImageURL \(post.smallImageUrl)")
                                    Database.updatePostSmallImages(postId: post.id, completion: { (smallUrl) in
                                        if let smallUrl = smallUrl {
                                            imageUrls.append("\(smallUrl),\((post.id)!)")
                                            imageUrlsArray.append(smallUrl)
                                        }
                                    })
                                }
                            } else {
                                print("   ~ Database |  refreshList ERROR | Can't find \(postId) in \(listId) | \(list.name) | \(postIds.count) | \(tempPosts.count) Fetched Posts")
                            }
                        }
                    }
                }
                print("   ~ Database |  refreshList | ImageUrls: TIME SORT | \(imageUrls.count) Images | \(list.name) : \(listId)")

            //}
            
            
        // POST MOST RECENT DATE
            var mostRecentDate = list.creationDate
            
            for (key,value) in postIds {
                let time = value as! Double ?? 0
                var tempTime = Date(timeIntervalSince1970: time)
                if tempTime > mostRecentDate {
                    mostRecentDate = tempTime
                }
            }
            
        // CHECK IF NEED TO UPLOAD
            var sameImages = true
            for url in imageUrlsArray {
                if !list.listImageUrls.contains(url) {
                    sameImages = false
                }
            }
            
            for url in list.listImageUrls {
                if !imageUrlsArray.contains(url) {
                    sameImages = false
                }
            }
            
            var center = Database.centerManyLoc(locations: tempLocations)
            guard let lat = center?.latitude else {return}
            guard let long = center?.longitude else {return}
            let convertCenter = CLLocation(latitude: lat, longitude: long)

            var sameLocation = true
            let newLocDistance = (list.listGPS?.distance(from: convertCenter) ?? 0)
            if newLocDistance > 100000.0 {
                // ONLY UPDATE GEOFIRE LOCATION IF DISTANCE IS >100KM
                sameLocation = false
            }
            
            var sameTime = true
            if mostRecentDate > list.mostRecentDate {
                sameTime = false
            }
            
            if sameLocation && sameTime && sameImages {
                print("   ~ Database |  refreshList | All Same | Don't Update | \(list.name) \(list.id)")
                return}

            // UPDATE LIST OBJECT ANYWAY SINCE MOST RECENT DATE WILL CHANGE
            let ref = Database.database().reference().child("lists").child(listId)
            ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                
                let uploadTime = mostRecentDate.timeIntervalSince1970
                let GPSLatitude = String(format: "%f", lat)
                let GPSLongitude = String(format: "%f", long)
                let uploadGPS = GPSLatitude + "," + GPSLongitude
                
                
                var list = currentData.value as? [String : AnyObject] ?? [:]
                
                list["location"] = uploadGPS as AnyObject?
                list["mostRecent"] = uploadTime as AnyObject?
                list["listImageUrls"] = imageUrls as AnyObject?
                // Set value and report transaction success
                currentData.value = list
                print("   ~ Database |  refreshList | Success | \(listId) Updated | \(uploadGPS) - \(sameLocation) | \(uploadTime) - \(sameTime) | \(imageUrls.count) - \(sameImages)")
                return TransactionResult.success(withValue: currentData)
                
            }) { (error, committed, snapshot) in
                if let error = error {
                    print(error.localizedDescription)
                }
            }
            
            if !sameLocation {
                print("   ~ Database |  refreshList | Geofire | Update Location Because New Location Distance is \(newLocDistance) | \(listId) | \(list.name)")
                let geofireRef = Database.database().reference().child("listlocations")
                let geoFire = GeoFire(firebaseRef: geofireRef)
                
                geoFire.setLocation(convertCenter, forKey: listId) { (error) in
                    if (error != nil) {
                        print("An error occured when saving Location \(convertCenter) for List \(listId) : \(error)")
                    } else {print("Saved location successfully! for Post \(listId)")}
                }
            }
            
            listRefreshRecord[listId] = 0
            
            // UPDATE LIST CACHE
            if let cachedList = listCache[listId] {
                var tempList = cachedList
                
                var tempImageUrls: [String] = []
                var tempPostIds: [String] = []
                
                for key in imageUrls {
                    let textArray = key.components(separatedBy: ",")
                    if textArray.count > 1 {
                        tempImageUrls.append(textArray[0])
                        tempPostIds.append(textArray[1])
                    }
                }
                
                tempList.listImageUrls = tempImageUrls
                tempList.listImagePostIds = tempPostIds
                tempList.mostRecentDate = mostRecentDate
                tempList.listGPS = convertCenter
                
                listCache[listId] = tempList
                print("   ~ Database |  refreshList | Update List Cache \(listId) | \(list.name) | \(list.listImageUrls.count) Images| FINISH")
                NotificationCenter.default.post(name: TabListViewController.refreshListNotificationName, object: nil)
            }

            print("   ~ Database |  refreshList | \(listId) | \(list.name) | \(list.listImageUrls.count) Images| FINISH")
        })
    }
    
    
    
    static func checkUpdateListDetailsWithPost(listName: String, listId: String, post: Post, completion: @escaping (List?) ->()){
        
        var tempPost = post
        var tempPostDictionary = tempPost.dictionary()
        
        // Check if list exists
        Database.fetchListforSingleListId(listId: listId) { (list) in
            if list == nil {
                print("List \(listId): \(listName) does not exist anymore")
                
                // Update Post Details and Remove List
                if let deleteIndex = tempPost.creatorListId?.index(forKey: listId) {
                    var updatePostListIds = tempPost.creatorListId?.remove(at: deleteIndex)
                    tempPostDictionary["lists"] = updatePostListIds
                    print("Deleting \(listId) list from \(tempPost.id) Post")
                    Database.updatePostwithPostID(post: post, newDictionaryValues: tempPostDictionary)
                }
                completion(nil)
            } else {
                // List Exists
                
                    if list?.name != listName {
                    // Update Post Details if List Name has Changes
                        var tempList = tempPostDictionary["lists"] as! [String:String]
                        tempList[listId] = list?.name
                        tempPostDictionary["lists"] = tempList
                        print("Updating \(listId) list Name from \(listName) to \(list?.name) for Post \(post.id)")
                        Database.updatePostwithPostID(post: post, newDictionaryValues: tempPostDictionary)
                    }
                
                completion(list)
            }
        }
    }
    
    
    

    
    
    
    static func fetchPostFromList(list: List?, completion: @escaping ([Post]?) -> ()){
    
        guard let list = list else {
            print("Fetch Post from List: ERROR, No List")
            completion(nil)
            return
        }
        
        let thisGroup = DispatchGroup()
        var tempPosts: [Post] = []
        
//        var createDefaultRank: Bool = false
//        let listRankCount = list.listRanks.count ?? 0
//        let postCount = list.postIds?.count ?? 0
//
//        if listRankCount == 0 && postCount > 0 {
//            print("fetchPostFromList | Create Default Ranks For \(list.name) | \(list.postIds?.count) Posts")
//            createDefaultRank = true
//        }
        
        var deleteIds:[String] = []

        for (index,postObject) in list.postIds!.enumerated() {
            
            let postId = postObject.key
            let postListDate = postObject.value
            
            if CurrentUser.blockedPosts[postId] != nil {
                print("Blocked Post \(postId) from list \(list.name)")
                continue
            }
            
            thisGroup.enter()
            
            Database.fetchPostWithPostID(postId: postId, completion: { (fetchedPost, error) in
                if let error = error {
                    print("Fetch Post: ERROR, \(postId)", error)
                    return
                }
                
                // Work around to handle if listed post was deleted
                if let fetchedPost = fetchedPost {
                    var tempDate = postListDate as! Double
                    var tempPost = fetchedPost
                    let listDate = Date(timeIntervalSince1970: tempDate)
                    if !list.isRatingList {
                        // IF NON RATING LIST WE USE THE LISTED DATE INSTEAD OF THE POST DATE
                        tempPost.listedDate = listDate
                    }
                    
                    if let tempRank = list.listRanks[(tempPost.id)!] {
                        tempPost.listedRank = tempRank
                    }
                    
//                    if createDefaultRank {
//                        tempPost.listedRank = index + 1
//                    } else {
//                        // List Exist So Listing Posts
//                        if let listedRank = list.listRanks[postId] {
//                            tempPost.listedRank = listedRank
//                        } else {
//                            tempPost.listedRank = (list.listRanks.count ?? 0) + 1
//                        }
//                    }
                    
                    
                    tempPosts.append(tempPost)
                    thisGroup.leave()
                } else {
                    print("Fetch Post: ERROR, \(postId), No Post, Will Delete from \(list.name) | \(list.id)")
                    deleteIds.append(postId)
                    thisGroup.leave()
                }
                
            })
        }
        
        thisGroup.notify(queue: .main) {
            print("   ~ Database | fetchPostFromList \(tempPosts.count) Post for List: \(list.name) \(list.id) | \(deleteIds.count) Missing Posts")
            
            // Initial Sort by Listed Dates
            tempPosts.sort(by: { (p1, p2) -> Bool in
                return p1.listedDate?.compare((p2.listedDate)!) == .orderedDescending
            })
            
            for postId in deleteIds {
                Database.DeletePostForList(postId: postId, postCreatorUid: nil, listId: list.id, postCreationDate: nil)
            }
            completion(tempPosts)
            
        }
    }
    
    // Messages
    static func updateMessageThread(threadKey: String, creatorUid: String, creatorUsername: String, receiveUid: [String: String]?, message: String) {
        
        // Create User Message within Thread
        let threadRef = Database.database().reference().child("messageThreads").child(threadKey)
        let threadMessageRef = threadRef.child("messages").childByAutoId()
        let inboxRef = Database.database().reference().child("inbox")
        let uploadTime = Date().timeIntervalSince1970
        let descTime = Date()
        
        // Create Message in Message Thread
        let values = ["creatorUID": creatorUid, "message": message, "creationDate": uploadTime] as [String:Any]
        
        threadMessageRef.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if let err = err {
                print("Error saving \(creatorUid) message: \(message) : in Thread \(threadKey) at \(descTime)")
                return
            }
            print("Success saving \(creatorUid) message: \(message) : in Thread \(threadKey) at \(descTime)")
        })
        
        // Update Users in Thread and Inbox
        var allUsers: [String: String] = [:]
        if let receiveUid = receiveUid {
            allUsers = receiveUid
            allUsers[creatorUid] = creatorUsername
        } else {
            allUsers[creatorUid] = creatorUsername
        }
        
        threadRef.child("users").updateChildValues(allUsers, withCompletionBlock: { (err, ref) in
            if let err = err {
                print("Error Updating Users \(allUsers) in Thread \(threadKey)")
                return
            }
            print("Success Updating Users \(allUsers) in Thread \(threadKey)")
        })
        
        // Loop Through Users
        var threadUpload = [threadKey:uploadTime]
        for (user, username) in allUsers {
            inboxRef.child(user).updateChildValues(threadUpload, withCompletionBlock: { (err, ref) in
                if let err = err {
                    print("Error Updating Inbox for User \(user), Thread \(threadKey)")
                    return
                }
                print("Success Updating Inbox for User \(user), Thread \(threadKey)")
            })
        }
    }

    static func respondMessageThread(threadKey: String, creatorUid: String, message: String) {
        
        if message.isEmptyOrWhitespace() {
            print("respondMessageThread | ERROR | Blank Response | \(message)")
            return
        }
        
        // Create User Message within Thread
        let threadRef = Database.database().reference().child("messageThreads").child(threadKey)
        let threadMessageRef = threadRef.child("messages").childByAutoId()
        let inboxRef = Database.database().reference().child("inbox")
        let uploadTime = Date().timeIntervalSince1970
        let descTime = Date()
        
        // Create Message in Message Thread
        let values = ["creatorUID": creatorUid, "message": message, "creationDate": uploadTime] as [String:Any]
        
        threadMessageRef.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if let err = err {
                print("Error saving \(creatorUid) message: \(message) : in Thread \(threadKey) at \(descTime)")
                return
            }
            print("Success saving \(creatorUid) message: \(message) : in Thread \(threadKey) at \(descTime)")
        })
    }
    
    static func createMessageForThread(messageThread: MessageThread? , creatorUid: String?, postId: String?, messageText: String?) {
        
        
        guard let messageThread = messageThread else {
            print("createMessageForThread | ERROR | No messageThread")
            return}
        let threadId = messageThread.threadID
        
        guard let creatorUid = creatorUid else {
            print("createMessageForThread | ERROR | No User")
            return}
        
        
        let messageThreadRef = Database.database().reference().child("messageThreads").child(threadId)

        let uploadTime = Date().timeIntervalSince1970
        let messageId = NSUUID().uuidString
        
        var values = ["creationDate": uploadTime, "creatorUID": creatorUid] as [String:Any]
        
        if !(postId ?? "").isEmptyOrWhitespace() {
            values["postId"] = postId
        }

        if !(messageText ?? "").isEmptyOrWhitespace() {
            values["message"] = messageText
        }
                
        messageThreadRef.child("messages").child(messageId).updateChildValues(values, withCompletionBlock: { (err, ref) in
            if let err = err {
                print("Error saving Thread \(threadId) | PostId \(postId) | Text \(messageText) | err")
                return
            } else {
                print("Saved Message \(messageId) To \(threadId) Thread | PostId \(postId) | Text \(messageText)")
                
                if !(postId ?? "").isEmptyOrWhitespace() {
                    self.addMessageToPost(threadId: threadId, postId: postId, creatorUid: creatorUid)
                }
            }
            
            var tempMsg = Message.init(messageID: messageId, dictionary: values)
            tempMsg.user = CurrentUser.user

            let temp = CurrentUser.inboxThreads.first { (thread) -> Bool in
                return thread.threadID == threadId
            }
            
            if temp != nil {
                temp?.messages.append(tempMsg)
                temp?.lastMessageDate = tempMsg.creationDate
            }
            
            self.saveMessageInteraction(messageUid: threadId)
            
            // NOTIFY OTHER USERS
            for uid in messageThread.threadUserUids {
                if uid != creatorUid {
                    let notificationHeader = "\((CurrentUser.username)!) sent a message"
                    var notificationBody = ""

                    if !(postId ?? "").isEmptyOrWhitespace() {
                        notificationBody = "Forwarded a post"
                    } else if !(messageText ?? "").isEmptyOrWhitespace() {
                        notificationBody = messageText ?? ""
                    }
                    
                    self.sendPushNotification(uid: uid, title: notificationHeader, body: notificationBody, action: messageAction)
                }
            }
            
            

                        
            NotificationCenter.default.post(name: MainTabBarController.NewMessageName, object: nil)
            print("TRIGGER | NEW MESSAGE")
        })
    }
    
    static func createMessageThread(users: [String: String], completion: @escaping (MessageThread) -> ()){
        
        // USERS are UID: USERNAME
        
        if users.count == 0 {
            print("createMessageThread | ERROR | No USERS")
            return
        }
        
        let uploadTime = Date().timeIntervalSince1970
        let threadId = NSUUID().uuidString

        let messageThreadRef = Database.database().reference().child("messageThreads").child(threadId)
        let values = ["users": users, "creationDate": uploadTime] as [String:Any]
        
        var userUids: [String] = []
        for (uid, name) in users {
            userUids.append(uid)
        }
                
        messageThreadRef.updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Failed to Save Message Thread to DB", err)
            }
            
            self.addThreadForUser(threadId: threadId, userUids: userUids)
            
            var tempThread = MessageThread.init(threadID: threadId, dictionary: values)
            CurrentUser.inboxThreads.append(tempThread)
            
            completion(tempThread)
        }
    }
    
    
    static func addThreadForUser(threadId: String?, userUids: [String]) {

        // USERS are UID: USERNAME
        
        guard let threadId = threadId else {return}
        if userUids.count == 0 {
            print("addThreadForUser | ERROR | No Users")
            return
        }
        
        let uploadTime = Date().timeIntervalSince1970
        let inboxRef = Database.database().reference().child("inbox")

        for user in userUids {
            let inboxRef = Database.database().reference().child("inbox").child(user)
            var threadUpload = [threadId:uploadTime]
            inboxRef.updateChildValues(threadUpload) { (err, ref) in
                if let err = err {
                    print("addThreadForUser | ERROR | \(err)")
                } else {
                   print("addThreadForUser | Success | Added \(threadId) to \(user)")
                }
            }
        }

    }
    
    
    static func addMessageToPost(threadId: String?, postId: String?, creatorUid: String?) {
        guard let threadId = threadId else {return}
        guard let postId = postId else {return}
        let uploadTime = Date().timeIntervalSince1970

        // Update Post_Messages
        let messageRef = Database.database().reference().child("post_messages").child(postId)
        messageRef.runTransactionBlock({ (currentData) -> TransactionResult in
            
            var post = currentData.value as? [String : AnyObject] ?? [:]
            var count = post["messageCount"] as? Int ?? 0
            var threads = post["threads"] as? [String : Any] ?? [:]
            var postDate = post["creationDate"] as? Double ?? 0
            
            count = max(0, count + 1)
            threads[threadId] = creatorUid
            
            // Update Message Thread Counts
            post["messageCount"] = count as AnyObject?
            post["threads"] = threads as AnyObject?
                        
            // Enables firebase sort by count and recent upload time
            let  sortTime = uploadTime/1000000000000000
            post["sort"] = (Double(count) + sortTime) as AnyObject
            
            currentData.value = post
            print("Update Message Count for post : \(postId) to \(count)")
            return TransactionResult.success(withValue: currentData)
        
        }) { (error, committed, snapshot) in
            if let error = error {
                print("Failed to Update Message Thread Count Error: ", postId, error.localizedDescription)
            }
        }
    }
    
    static func addMessageEmail(creatorUid: String?, sentUsers: [String], postId: String?, messageText: String?) {
        guard let postId = postId else {return}
        guard let creatorUid = creatorUid else {return}
        let uploadTime = Date().timeIntervalSince1970

        let emailId = NSUUID().uuidString

        
    // CREATE EMAIL MESSAGE ITEM

        // Update Post_Messages
        let messageRef = Database.database().reference().child("email_messages").child(creatorUid).child(emailId)
        var values = ["creationDate": uploadTime, "creatorUID": creatorUid, "users": sentUsers] as [String:Any]
        
        if !(postId ?? "").isEmptyOrWhitespace() {
            values["postId"] = postId
        }

        if !(messageText ?? "").isEmptyOrWhitespace() {
            values["message"] = messageText
        }
        
                
        messageRef.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if let err = err {
                print("Error saving email to \(sentUsers) | PostId \(postId) | Text \(messageText) | \(err)")
                return
            } else {
                print("Success saving email \(emailId) to \(sentUsers) | PostId \(postId) | Text \(messageText) | \(err)")

                // ADD EMAIL TO POST MESSAGES
                    let messageThreadRef = Database.database().reference().child("post_messages").child(postId).child("threads")
                    var threadUpload = [emailId:creatorUid]
                    
                    messageThreadRef.updateChildValues(threadUpload) { (err, ref) in
                        if let err = err {
                            print("addMessageEmail | ERROR | \(err)")
                        } else {
                           print("addMessageEmail | Success | Added \(emailId) to \(postId)")
                        }
                    }
            }
        })
    }
    
    
    static func findMessageThread(userUids: [String], messageThreads: [MessageThread] = [], completion: @escaping (MessageThread?) -> ()){

        if userUids.count == 0 {
            print("findMessageThread | ERROR | No USERS")
            return
        }
        var threads: [MessageThread] = []
        var allUids = userUids
        
        if !allUids.contains(Auth.auth().currentUser?.uid ?? "") {
            allUids.append(Auth.auth().currentUser?.uid ?? "")
        }
        
        threads = ((messageThreads.count > 0) ? messageThreads : CurrentUser.inboxThreads).filter { (thread) -> Bool in
//            let tempSearch: [String] = thread.creatorUID.map { String($0) }.sorted()
//            var search = Set(String(thread.creatorUID).sorted())
            
            let tempSearch: [String] = thread.threadUserUids.sorted()
            var tempUids = Set(allUids.sorted())
            
            return Set(tempSearch).isSubset(of: tempUids) && (tempUids.count == tempSearch.count)
        }.sorted { (p1, p2) -> Bool in
            return p1.creationDate.compare(p2.creationDate) == .orderedDescending
        }
        
        
        if threads.count > 1 {
            print("findMessageThread | WARNING | Found more than 1 thread")
            print("   - \(threads.map{$0.threadID}) | \(userUids)")
            let foundThread = threads[0]
            completion(foundThread)
            
        } else if threads.count == 1 {
            let foundThread = threads[0]
            print("findMessageThread | Success | Found \(foundThread.threadID) For \(userUids) | \(foundThread.threadUserUids)")
            completion(foundThread)
        } else {
            print("findMessageThread | Success | Nil | No Thread For \(userUids)")
            completion(nil)
        }
    }
    
    // MARK: - SOCIAL ACTIONS

    // HANDLE LIKE
//        - UPDATE POST_VOTES (TRACK VOTES FOR EACH POST)
//        - CREATE USER_EVENT - NOTIFY USER THAT POST IS LIKED
//        - UPDATE HOW MANY LIKES POST CREATOR USER HAS
//        - UPDATE HOW MANY LIKES IN POST OBJECT (SEPARATE FROM POST_VOTES WHICH IS A SEP DATABASE)
    
    static func handleVote(post: Post!, creatorUid: String!, vote: Int!, completion: @escaping () -> Void){

        guard let postId = post.id else {return}
        let postCreationDate = post.creationDate.timeIntervalSince1970
        guard let uid = Auth.auth().currentUser?.uid else {return}
        guard let creatorUid = post.creatorUID else {return}

        
        if (Auth.auth().currentUser?.isAnonymous)! {
            print("Guest User. Don't Save Vote")
            return
        }
        let ref = Database.database().reference().child("post_votes").child(postId)
        var voteChange = 0 as Int
        var oldVote = 0 as Int
        
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            
            var post = currentData.value as? [String : AnyObject] ?? [:]
            var votes: Dictionary<String, Int>
            votes = post["votes"] as? [String : Int] ?? [:]
            var voteCount = post["voteCount"] as? Int ?? 0
            var postDate = post["creationDate"] as? Double ?? 0
            
            if let curVote = votes[uid] {
                oldVote = curVote
                votes[uid] = vote
                voteChange = vote - oldVote
            } else {
                votes[uid] = vote
                voteChange = vote - oldVote
            }
            
            
        // Handle Change Vote
//            if let curVote = votes[uid] {
//                // Has Current Vote
//                if curVote == vote {
//                    // Deselect Current Vote
//                    votes[uid] = 0
//                    voteChange = -vote
//                } else {
//                    // Override Current Vote
//                    votes[uid] = vote
//                    voteChange = (vote - curVote)
//                }
//            } else {
//                // Make New Vote
//                votes[uid] = vote
//                voteChange = vote
//            }
            
        // Handle Creation Date
            if postDate != postCreationDate {
                postDate = postCreationDate
            }
            
            voteCount += voteChange
            post["voteCount"] = voteCount as AnyObject?
            post["votes"] = votes as AnyObject?
            post["creationDate"] = postDate as AnyObject?
            
            // Enables firebase sort by count adjusted by recency
            let  uploadTime = Date().timeIntervalSince1970/1000000000000000
            post["sort"] = (Double(voteCount) + uploadTime) as AnyObject
            
            // Set value and report transaction success
            currentData.value = post
            print("handleVote | post_votes Updated | \(postId):\(uid):\(votes[uid])")
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                var postValue = snapshot?.value as? [String : AnyObject] ?? [:]
                var votes = postValue["votes"] as? [String : Int] ?? [:]
                
                self.createNotificationEventForUser(postId: postId, listId: nil, targetUid: creatorUid, action: Social.like, value: vote, locName: post.locationName, listName: nil, commentText: nil)

                self.createUserLike(postId: postId, like: vote, userId: uid)
                spotChangeSocialCountForUser(creatorUid: creatorUid, socialField: .votes_received, change: voteChange)
                spotUpdateSocialCountForPost(postId: postId, socialField: "voteCount", change: voteChange)
                // Completion after updating Likes
                completion()
            }
        }
    }
    
    static func createUserLike(postId: String?, like: Int?, userId: String?){
        guard let postId = postId else {return}
        guard let like = like else {return}
        guard let userId = userId else {return}

        var data = [:] as [String:Any]
        var temp = (like == 0) ? 0.0 : Date().timeIntervalSince1970
        data[postId] = temp
        let ref = Database.database().reference().child("userlikes").child(userId)
        ref.updateChildValues(data) { (error, ref) in
            if let error = error {
                print(error)
            } else {
                print("createUserLike | Success | \(userId) : \(postId) : \(like)")
                CurrentUser.likedPostIds[postId] = temp
            }
        }
    }
    
    static func handleLike(post: Post?, completion: @escaping (Post) -> Void){
        guard let post = post else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        var tempPost = post
        if (tempPost.hasLiked) {
            // Unselect Upvote
            tempPost.hasLiked = false
            tempPost.likeCount -= 1
            tempPost.allVote.removeAll(where: {$0 == uid})
            Database.handleVote(post: tempPost, creatorUid: post.creatorUID, vote: 0) {}
            
        } else {
            // Upvote
            tempPost.hasLiked = true
            tempPost.likeCount += 1
            tempPost.allVote.append(uid)
            Database.handleVote(post: tempPost, creatorUid: post.creatorUID, vote: 1) {}
    
        }
        print("handleLike \(tempPost.id) | User Liked: \(tempPost.hasLiked) | \(tempPost.likeCount) Likes")
        if let postId = post.id {
            postCache[postId] = tempPost
        }
        completion(tempPost)
    }
    
    
    static func handleLikeOLD(postId: String!, creatorUid: String!, completion: @escaping () -> Void){
        
        let ref = Database.database().reference().child("likes").child(postId)
        guard let uid = Auth.auth().currentUser?.uid else {return}
        if (Auth.auth().currentUser?.isAnonymous)! {
            print("Guest User. Don't Save Likes")
            return
        }
        
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in

            var post = currentData.value as? [String : AnyObject] ?? [:]
                var likes: Dictionary<String, Int>
                likes = post["likes"] as? [String : Int] ?? [:]
                var likeCount = post["likeCount"] as? Int ?? 0
                if let _ = likes[uid] {
                    // Unstar the post and remove self from stars
                    likeCount -= 1
                    likes.removeValue(forKey: uid)
                } else {
                    // Star the post and add self to stars
                    likeCount += 1
                    likes[uid] = 1
                }
                post["likeCount"] = likeCount as AnyObject?
                post["likes"] = likes as AnyObject?
            
            // Enables firebase sort by count and recent upload time
                let  uploadTime = Date().timeIntervalSince1970/1000000000000000
                post["sort"] = (Double(likeCount) + uploadTime) as AnyObject
                
                // Set value and report transaction success
                currentData.value = post
                print("Successfully Update Like in Likes \(postId):\(uid):\(likes[uid])")
                return TransactionResult.success(withValue: currentData)

        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                var post = snapshot?.value as? [String : AnyObject] ?? [:]
                var likes = post["likes"] as? [String : Int] ?? [:]
                if likes[uid] == 1 {
                    print("   ~ Database | handleLike | \(uid) Liked \(postId)")
                    let text = "\(CurrentUser.username) liked your post"
                    self.sendPushNotification(uid: creatorUid, title: "Legit Notification", body: text, action: "like")
                } else {
                    print("   ~ Database | handleLike | \(uid) UN-Liked \(postId)")
                }
                
                if let _ = likes[uid] {
//                    spotUpdateSocialCount(creatorUid: uid, receiverUid: creatorUid, action: "like", change: 1)
                } else {
//                    spotUpdateSocialCount(creatorUid: uid, receiverUid: creatorUid, action: "like", change: -1)
                }
                // Completion after updating Likes
                completion()
            }
        }
        
    }
    
    static func fetchEventForUID(uid: String?, completion: @escaping ([Event]) -> ()) {
        
        guard let uid = uid else {return}
        
        let myGroup = DispatchGroup()
        var fetchedEvents = [] as [Event]
        
//        if uid == Auth.auth().currentUser?.uid && CurrentUser.events.count > 0 {
//            completion(CurrentUser.events)
//            return
//        }
        
        let ref = Database.database().reference().child("user_event").child(uid)
        
        ref.keepSynced(true)
        
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
//            print(snapshot)
            guard let userEvents = snapshot.value as? [String: Any] else {
                completion([])
                return}
            
            userEvents.forEach({ (key,value) in
                myGroup.enter()
                
                guard let dictionary = value as? [String: Any] else {
                    myGroup.leave()
                    return}
                
                var tempEvent = Event.init(id: key, dictionary: dictionary)
                
            // FILL IN RECEIVER UID HOLES IF FETCHING FROM CURENT USER
                if uid == Auth.auth().currentUser?.uid {
                    if tempEvent.receiverUid == nil {
                        tempEvent.receiverUid = uid
                    }
                }
                
//             ONLY INCLUDE NOTIFICATIONS THAT IS NOT CREATED BY SELF
                if tempEvent.value != 0 {
                    fetchedEvents.append(tempEvent)
                }
                
                
                myGroup.leave()
            })
            
            myGroup.notify(queue: .main) {
                let fileredEvent = Database.filterEvents(events: fetchedEvents, filterSelf: uid == (Auth.auth().currentUser?.uid))

                // FILTERS OUT ALL EVENTS CREATED BY THE SAME USER
                let temp = fileredEvent.filter({ (event) -> Bool in
                    return event.value == 1 && event.creatorUid != uid && !event.read
                })
                var newEventIds:[String] = []
                for x in temp {
                    newEventIds.append((x.id) ?? "")
                }
                let count = temp.count
                let filteredCount = fetchedEvents.count - fileredEvent.count
                completion(fileredEvent)
//                print("   ~ Database | fetchEventForUID | \(uid) | \(fileredEvent.count) Events | \(count) New Notifications | Filtered: \(filteredCount) \n New Events: \(newEventIds)")
            }
        })
    }
    
    static func fetchUserFollowingListEventForUID(uid: String?, completion: @escaping ([Event]) -> ()) {
        
        guard let uid = uid else {return}
        
        let myGroup = DispatchGroup()
        var fetchedEvents = [] as [Event]

        let ref = Database.database().reference().child("user_listEvent").child(uid)
        
        
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            //            print(snapshot)
            guard let userEvents = snapshot.value as? [String: Any] else {
                completion([])
                return}
            
            userEvents.forEach({ (key,value) in
                myGroup.enter()
                
                guard let dictionary = value as? [String: Any] else {
                    myGroup.leave()
                    return}
                
                var tempEvent = Event.init(id: key, dictionary: dictionary)
                
                // FILL IN RECEIVER UID HOLES IF FETCHING FROM CURENT USER
//                if uid == Auth.auth().currentUser?.uid {
//                    if tempEvent.receiverUid == nil {
//                        tempEvent.receiverUid = uid
//                    }
//                }
                tempEvent.userFollowedListObject = true
                fetchedEvents.append(tempEvent)
                myGroup.leave()
            })
            
            myGroup.notify(queue: .main) {
                print("fetchUserListEventForUID | \(uid) : \(fetchedEvents.count) Events")
                ref.keepSynced(true)
                completion(fetchedEvents)
            }
        })
    }
    
    static func createNotificationEventForUser(postId: String? = nil, listId: String? = nil, sourceUid: String? = nil, targetUid: String? = nil, action: Social? = nil, value: Int? = 0, locName: String? = nil, listName: String? = nil, commentText: String? = nil){
        let uid = sourceUid ?? Auth.auth().currentUser?.uid
        guard let uid = uid else {return}

        guard let targetUid = targetUid else {return}
        guard let action = action else {return}

//        let ref = Database.database().reference().child("like_event").child(postId)
        if targetUid == uid {
            print("RETURN User Notifiying Self - createNotificationEventForUser")
            return
        }
        
        var eventId = NSUUID().uuidString
        let eventTime = Date().timeIntervalSince1970
        
        var value = min(1,value ?? 0)
        var uploadDic: [String:Any] = [:]
        var eventAction:String? = nil
        
        var notificationHeader: String = ""
        var notificationBody: String = ""
        
        
        switch (action) {
        case .like:
            eventAction = likeAction
            if postId != nil {
                notificationHeader = "\((CurrentUser.username)!) liked your post"
                if let locName = locName {
                    notificationBody = (locName).capitalizingFirstLetter()
                }
            }
            else if listId != nil {
                notificationHeader = "\((CurrentUser.username)!) liked your list"
                if let listName = listName {
                    notificationBody = (listName).capitalizingFirstLetter()
                }
            }

        case .follow:
            eventAction = followAction
            if listId != nil {
                notificationHeader = "\((CurrentUser.username)!) followed your list"
                if let listName = listName {
                    notificationBody = (listName).capitalizingFirstLetter()
                }
            } else {
                notificationHeader = "\((CurrentUser.username)!) followed you"
            }
        case .bookmark:
            eventAction = bookmarkAction
            notificationHeader = "\((CurrentUser.username)!) bookmarked your post"
            if let listName = listName, let locName = locName {
                notificationBody = "\((locName).capitalizingFirstLetter()) Added To: \((listName).capitalizingFirstLetter())"
            }
        case .comment:
            eventAction = commentAction
            notificationHeader = "\((CurrentUser.username)!) commented on your post"
            if let commentText = commentText {
                notificationBody = (commentText).capitalizingFirstLetter()
            }
        case .commentToo:
            eventAction = commentTooAction
            notificationHeader = "\((CurrentUser.username)!) commented on a post you commented"
            if let commentText = commentText {
                notificationBody = (commentText).capitalizingFirstLetter()
            }
        case .report:
            eventAction = reportAction
            if postId != nil {
                notificationHeader = "A post has been reported"
                if let commentText = commentText {
                    notificationBody = "One of your post will be set to private if flagged more than 3 times."
                }
            } else {
                notificationHeader = "Your profile has been flagged"
                if let commentText = commentText {
                    notificationBody = "Your profile will be set to private if flagged more than 3 times."
                }
            }
            

        default:
            eventAction = nil
        }
        
        uploadDic["action"] = eventAction
        uploadDic["initUserUid"] = uid
        uploadDic["receiveUserUid"] = targetUid
        uploadDic["eventTime"] = eventTime
        uploadDic["value"] = value
        
        if let postId = postId {
            uploadDic["postId"] = postId
        }
        
        if let listId = listId {
            uploadDic["listId"] = listId
        }
        
        if let listName = listName {
            uploadDic["listName"] = listName
        }
        
        if let locName = locName {
            uploadDic["locName"] = locName
        }
        
        if let commentText = commentText {
            uploadDic["commentText"] = commentText
        }
        

        let receiveUserRef = Database.database().reference().child("user_event").child(targetUid)
        let creatorUserRef = Database.database().reference().child("user_event").child(uid)
        
        receiveUserRef.child(eventId).updateChildValues(uploadDic) { (error, reft) in
            if let error = error {
                print("   ~ createNotificationEventForUser | receiveUserRef | ERROR | \(error)")
            } else {
                print("   ~ createNotificationEventForUser | receiveUserRef | SUCCESS | EVENT \(eventId) | \(postId) : \(action)")
            }
            
            // NOTIFY RECEIVER
            if value == 1 {
                self.sendPushNotification(uid: targetUid, title: notificationHeader, body: notificationBody, action: eventAction)
            } else {
                print("Removing - No Notification")
            }
            
        }
        
        if eventAction != commentTooAction {
            // Avoid creating multiple actions by commenter when alerting other people who commented on the post
            return
        }
        
        creatorUserRef.child(eventId).updateChildValues(uploadDic) { (error, reft) in
            if let error = error {
                print("   ~ createNotificationEventForUser | creatorUserRef | ERROR | \(error)")
            } else {
                print("   ~ createNotificationEventForUser | creatorUserRef | SUCCESS | EVENT \(eventId) | \(postId) : \(action)")
            }
        }
    }
    

    
    static func handleBookmark(postId: String!, creatorUid: String!, completion: @escaping () -> Void){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        if (Auth.auth().currentUser?.isAnonymous)! {
            print("Guest User. Don't Save Bookmark")
            return
        }
        let ref = Database.database().reference().child("bookmarks").child(postId)
        
        
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                var post = currentData.value as? [String : AnyObject] ?? [:]
                var bookmarks: Dictionary<String, Int>
                bookmarks = post["bookmarks"] as? [String : Int] ?? [:]
                var bookmarkCount = post["bookmarkCount"] as? Int ?? 0
                if let _ = bookmarks[uid] {
                    // Unstar the post and remove self from stars
                    bookmarkCount -= 1
                    bookmarks.removeValue(forKey: uid)
                    
                } else {
                    // Star the post and add self to stars
                    bookmarkCount += 1
                    bookmarks[uid] = 1
                    
                }
            
                post["bookmarkCount"] = bookmarkCount as AnyObject?
                post["bookmarks"] = bookmarks as AnyObject?

            // Enables firebase sort by count and recent upload time
                let  uploadTime = Date().timeIntervalSince1970/1000000000000000
                post["sort"] = (Double(bookmarkCount) + uploadTime) as AnyObject
            
            
                // Set value and report transaction success
                currentData.value = post
                print("Successfully Update Bookmark for \(postId):\(uid):\(bookmarks[uid])")
                return TransactionResult.success(withValue: currentData)

        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                var post = snapshot?.value as? [String : AnyObject] ?? [:]
                var bookmarks = post["bookmarks"] as? [String : Int] ?? [:]

                if let _ = bookmarks[uid] {
//                    spotUpdateSocialCount(creatorUid: uid, receiverUid: creatorUid, action: "bookmark", change: 1)
                } else {
//                    spotUpdateSocialCount(creatorUid: uid, receiverUid: creatorUid, action: "bookmark", change: -1)
                }
                
                // No Error Handle Bookmarking in User
                handleUserBookmark(postId: postId)
                completion()
            }
        }
    }
    
    static func handleUserBookmark(postId: String!){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let ref = Database.database().reference().child("users").child(uid).child("bookmarks")
        
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            var user = currentData.value as? [String : AnyObject] ?? [:]
            var bookmarkCount = user["bookmarkCount"] as? Int ?? 0
            var bookmarks = user["bookmarks"] as? [String : AnyObject] ?? [:]
            
            if let _ = bookmarks[postId] {
                // Remove Bookmark
                bookmarkCount -= 1
                bookmarks.removeValue(forKey: postId)
            } else {
                // Add Bookmark
                let bookmarkTime = Date().timeIntervalSince1970
                let values = ["bookmarkDate": bookmarkTime] as [String : AnyObject]
                bookmarkCount += 1
                bookmarks[postId] = values as AnyObject
            }
            
            user["bookmarkCount"] = bookmarkCount as AnyObject?
            user["bookmarks"] = bookmarks as AnyObject?
            
            // Set value and report transaction success
            currentData.value = user
            print("Successfully Update Bookmark in User \(uid) for Post: \(postId)")
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
        
    }
    
// FOLLOWING FUNCTION TO SPECIFY BOTH FOLLOWER AND FOLLOWING
    static func handleManualFollowing(followerUid: String?, followedUid: String?, hideAlert: Bool = false, forceFollow: Bool = false, forceUnFollow: Bool = false, completion: @escaping () -> Void){
        
        guard let followerUid = followerUid else {return}
        guard let followedUid = followedUid else {return}
        
        let ref = Database.database().reference().child("following").child(followerUid)
        
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            var user = currentData.value as? [String : AnyObject] ?? [:]
            var following: Dictionary<String, Int>
            following = user["following"] as? [String : Int] ?? [:]
            var followingCount = user["followingCount"] as? Int ?? 0
            if forceFollow {
                if let _ = following[followedUid] {
                    print("Already Following \(followedUid) | Force Follow")
                }
                else {
                    followingCount += 1
                    following[followedUid] = 1
                }
            }
            else if forceUnFollow {
                if let _ = following[followedUid] {
                    if let deleteIndex = following.index(forKey: followedUid) {
                        following.remove(at: deleteIndex)
                        followingCount -= 1
                    }
                }
                else {
                    print("Already Unfollowed \(followedUid) | Force Unfollow")
                }
            }
            else {
                    if let _ = following[followedUid] {
                    // Unfollowed User
                    if let deleteIndex = following.index(forKey: followedUid) {
                        following.remove(at: deleteIndex)
                        followingCount -= 1
                    } else {
                        print("Unfollow: ERROR: \(followerUid) not following \(followedUid)")
                    }
                } else {
                    if following[followedUid] == 1 || following[followedUid] != nil {
                        print("Following: ERROR: \(followerUid) already following \(followedUid)")
                    } else {
                        // Followed User
                        followingCount += 1
                        following[followedUid] = 1
                    }
                }
            }

            user["following"] = following as AnyObject?
            user["followingCount"] = following.count as AnyObject?
            
            // Set value and report transaction success
            currentData.value = user
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                var user = snapshot?.value as? [String : AnyObject] ?? [:]
                var following: Dictionary<String, Int>
                following = user["following"] as? [String : Int] ?? [:]
                
                var followingCount = user["followingCount"] as? Int ?? 0
                var followedValue: Int? = following[followedUid]
                var username = " User"
                
                if let tempUser = userCache[followedUid] {
                    username = tempUser.username
                }
                
                // Update Current User
                // IS FOLLOWING
                if let _ = following[followedUid] {
                    if !hideAlert {
                        SVProgressHUD.showSuccess(withStatus: "You Followed \(username)")
                        SVProgressHUD.dismiss(withDelay: 2)
                    }
                    if followerUid == Auth.auth().currentUser?.uid {
                        CurrentUser.addFollowing(userId: followedUid)
                    }
                    
                    if followedUid == Auth.auth().currentUser?.uid {
                        CurrentUser.addFollower(userId: followedUid)
                    }
                    
                    print("   ~ handleFollowing | \(followerUid) Following \(followedUid) | \(followingCount) Following Users")
                    Database.createNotificationEventForUser(postId: nil, listId: nil, sourceUid: followerUid, targetUid: followedUid, action: Social.follow, value: 1, locName: nil, listName: nil, commentText: nil)
                }
                
                // IS NOT FOLLOWING
                else {
                    if !hideAlert {
                        SVProgressHUD.showSuccess(withStatus: "You Unfollowed \(username)")
                        SVProgressHUD.dismiss(withDelay: 2)
                    }
                    if followerUid == Auth.auth().currentUser?.uid {
                        CurrentUser.removeFollowing(userId: followedUid)
                    }
                    
                    if followedUid == Auth.auth().currentUser?.uid {
                        CurrentUser.removeFollower(userId: followedUid)
                    }
                    
                    print("   ~ handleFollowing | \(followerUid) UNFOLLOW \(followedUid) | \(followingCount) Following Users")
                    Database.createNotificationEventForUser(postId: nil, listId: nil, sourceUid: followerUid, targetUid: followedUid, action: Social.follow, value: 0, locName: nil, listName: nil, commentText: nil)
                }

                
                
                // Update User Object
                self.spotUpdateSocialCountForUserFinal(creatorUid: followerUid, socialField: .followingCount, final: followingCount)
//                NotificationCenter.default.post(name: AppDelegate.UserFollowUpdatedNotificationName, object: nil)

                // Update Follower
                handleFollower(followerUid: followerUid, followedUid: followedUid, followedValue: followedValue){
                    completion()
                }
            }
        }
        
        
        
    }
    
    static func handleFollowingMultipleUids(userUids: [String], hideAlert: Bool = false, forceFollow: Bool = false, completion: @escaping () -> Void){
        
        if userUids.count == 0 {
            print("ERROR | No Users UIDS | handleFollowingMultipleUids")
            return
        }
         let followUser = DispatchGroup()
        
        for uid in userUids {
            followUser.enter()
            self.handleFollowing(userUid: uid, hideAlert: hideAlert, forceFollow: forceFollow) {
                followUser.leave()
            }
        }
        
        followUser.notify(queue: .main) {
            print("SUCCESS Followed \(userUids.count) Users | handleFollowingMultipleUids")
            completion()
        }
    }

    
//    HANDLE FOLLOWING
//    - UPDATE FOLLLOWING DATABASE
//    - CREATE USER EVENT NOTIFYING USER HAS NEW FOLLOWER
//    - UPDATE FOLLOWING COUNT IN CURRENT USER OBJECT
//    - HANDLE FOLLOWER
//        - UPDATE FOLLOWER DATABASE
//        - UPDATE FOLLOWER COUNT IN FOLLOWED USER DATABASE
    
    
    static func handleFollowing(userUid: String!, hideAlert: Bool = false, forceFollow: Bool = false, forceUnfollow: Bool = false, completion: @escaping () -> Void){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let ref = Database.database().reference().child("following").child(uid)

        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            var user = currentData.value as? [String : AnyObject] ?? [:]
            var following: Dictionary<String, Int>
            following = user["following"] as? [String : Int] ?? [:]
            var followingCount = user["followingCount"] as? Int ?? 0

            if let _ = following[userUid] {
                // CHECK IF FOLLOWING USER THEN UNFOLLOW

                if forceFollow {
                    print("Already Following \(userUid) | Force Follow")
                } else {
                    // Unfollow User
                    if let deleteIndex = following.index(forKey: userUid) {
                        following.remove(at: deleteIndex)
                        followingCount -= 1
                    } else {
                        print("Unfollow: ERROR: \(uid) not following \(userUid)")
                    }
                }

            } else {
                // CHECK IF NOT FOLLOWING USER THEN FOLLOW

                if forceUnfollow {
                    print("Already Not Following \(userUid) | Force UnFollow")
                }
                else if following[userUid] == 1 || following[userUid] != nil {
                    print("Following: ERROR: \(uid) already following \(userUid)")
                } else {
                // Follow User
                    followingCount += 1
                    following[userUid] = 1
                }
            }
            user["following"] = following as AnyObject?
            user["followingCount"] = following.count as AnyObject?

            // Set value and report transaction success
            currentData.value = user
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                var user = snapshot?.value as? [String : AnyObject] ?? [:]
                var following: Dictionary<String, Int>
                following = user["following"] as? [String : Int] ?? [:]
                
                var followingCount = user["followingCount"] as? Int ?? 0
                var followedValue: Int? = following[userUid]
                var username = " User"
                                
                if let tempUser = userCache[userUid] {
                    username = tempUser.username
                }
                
                // Update Current User
                if let _ = following[userUid] {
                    if !hideAlert {
                        SVProgressHUD.showSuccess(withStatus: "You Followed \(username)")
                        SVProgressHUD.dismiss(withDelay: 2)
                    }

                    CurrentUser.addFollowing(userId: userUid)
                    print("handleFollowing | Follow Success | \(uid) Following \(userUid!) | \(followingCount) Following Users")
                    Database.createNotificationEventForUser(postId: nil, listId: nil, targetUid: userUid, action: Social.follow, value: 1, locName: nil, listName: nil, commentText: nil)

                } else {
                    if !hideAlert {
                        SVProgressHUD.showSuccess(withStatus: "You Unfollowed \(username)")
                        SVProgressHUD.dismiss(withDelay: 2)
                    }

                    CurrentUser.removeFollowing(userId: userUid)
                    print("handleFollowing | Unfollow Success | \(uid) UNFOLLOW \(userUid!) | \(followingCount) Following Users")
                    Database.createNotificationEventForUser(postId: nil, listId: nil, targetUid: userUid, action: Social.follow, value: 0, locName: nil, listName: nil, commentText: nil)

                }
                let userDataDict:[String: AnyObject] = ["uid": uid as AnyObject, "following": followedValue as AnyObject]
                NotificationCenter.default.post(name: AppDelegate.UserFollowUpdatedNotificationName, object: nil, userInfo: userDataDict)
                
                // Update User Object
                self.spotUpdateSocialCountForUserFinal(creatorUid: uid, socialField: .followingCount, final: followingCount)

                // Update Follower
                handleFollower(followerUid: Auth.auth().currentUser?.uid, followedUid: userUid, followedValue: followedValue){
                    completion()
                }
            }
        }
    }
    
    static func handleFollower(followerUid: String!, followedUid: String!, followedValue: Int?,  completion: @escaping() ->()){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let ref = Database.database().reference().child("follower").child(followedUid)
        
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            var user = currentData.value as? [String : AnyObject] ?? [:]
            var followers: Dictionary<String, Int>
            followers = user["follower"] as? [String : Int] ?? [:]
            var followerCount = user["followerCount"] as? Int ?? 0
            
            if followedValue == 1 {
                // User gained a new follower
                if followers[followerUid] == 1 {
                    print("Add Follower: ERROR, /(followedUid) already has \(followerUid) follower")
                } else {
                    followerCount += 1
                    followers[followerUid] = 1
                }
            } else {
                // User lost a follower
                if followers[followerUid] == 1 {
                    if let deleteIndex = followers.index(forKey: followerUid){
                        followers.remove(at: deleteIndex)
                        followerCount -= 1
                    } else {
                        print("Unfollow Error, \(followedUid) not followed by \(followerUid)")
                    }
                } else {
                    print("Unfollow Error, \(followedUid) not followed by \(followerUid)")
                }
            }

            user["follower"] = followers as AnyObject?
            user["followerCount"] = followers.count as AnyObject?

            // Set value and report transaction success
            currentData.value = user
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                var user = snapshot?.value as? [String : AnyObject] ?? [:]
                var followerCount = user["followerCount"] as? Int ?? 0
                if followedValue == 1 {
                    print("handleFollower | Success Follow | \(followerUid) follow \(followedUid) | \(followerCount) Followed Users")
                } else {
                    print("handleFollower | Success Unfollow | \(followerUid) Unfollow \(followedUid) | \(followerCount) Followed Users")

                }
                // Update User Object
                self.spotUpdateSocialCountForUserFinal(creatorUid: followedUid, socialField: .followerCount, final: followerCount)

               completion()
            }
        }
    }
    
    static func handleUserBadge(userUid: String!, badgeValue: Int!,  change: Int!, completion: @escaping() ->()){
        
        let creatorRef = Database.database().reference().child("users").child(userUid)
        creatorRef.runTransactionBlock({ (currentData) -> TransactionResult in
            guard let post = currentData.value as? [String : AnyObject] else {
                print(" ! handleUserBadge Error: No Post", userUid, badgeValue, change)
                return TransactionResult.abort()
            }
            
            var temp_post = post
            var cur_badges = temp_post["userBadges"] as? [Int] ?? []
            
            if change == 1 && !cur_badges.contains(badgeValue) {
                cur_badges.append(badgeValue)
                print("handleUserBadge | Add \(badgeValue) For \(userUid)")
            } else if change == -1 {
                if let index = cur_badges.firstIndex(of: badgeValue) {
                    cur_badges.remove(at: index)
                    print("handleUserBadge | Remove \(badgeValue) For \(userUid)")
                }
                
            }
                
            temp_post["userBadges"] = cur_badges as AnyObject
            currentData.value = temp_post
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print("   ERROR | handleUserBadge | \(change!) Badge \(badgeValue) for user : \(userUid!) ")
            } else {
                print("   SUCCESS | handleUserBadge | \(change!) Badge \(badgeValue) for user : \(userUid!) ")

            }
        }
        
    }
    
    
    static func spotChangeSocialCountForUser(creatorUid: String?, socialField: UserStats!, change: Int?){
        // Grabbing original number and sending a final number because transactions fire multiple times, so changes would be sent multiple times
        guard let creatorUid = creatorUid else {
            return
        }
        if change == 0 {
            print("No Change", "spotChangeSocialCountForUser", creatorUid, socialField, change)
            return
        }
        let creatorRef = Database.database().reference().child("users").child(creatorUid).child("social")
        creatorRef.observeSingleEvent(of: .value, with: {(snapshot) in
            var curCount: Int = 0
            var newCount: Int = 0

            if let socialDictionary = snapshot.value as? [String: Int] {
                if let _ = socialDictionary[socialField.rawValue]{
                    curCount = socialDictionary[socialField.rawValue]!
                }
            }
            
            newCount = curCount + (change ?? 0)
            self.spotUpdateSocialCountForUserFinal(creatorUid: creatorUid, socialField: socialField, final: newCount)

            
        })
        { (err) in print("spotChangeSocialCountForUser | ERROR | ",creatorUid,socialField,change, err)}
        
    }
    
    static func spotUpdateSocialCountForUserFinal(creatorUid: String!, socialField: UserStats!, final: Int?){
        
        // THIS FUNCTION IS CALLED FOR ALL SOCIAL CHECKS AND UPDATES. WE READ IN WHATS CURRENTLY IN THE DATABASE BUT THEN SET IT BASED ON THIS FORMULA IF CHANGED
        
        // Had issues with spot updating by change as it might get called several times and adding the change multiple times
        // Setting it to a new final number probably an easier way to go
        
        // votes_received
        // followingCount, followersCount
        // posts_created, lists_created
        
//        print("spotUpdateSocialCountForUser | Setting \(creatorUid) \(socialField) TO \(final)")

        
        let values = [socialField.rawValue: final] as! [String:Any]
        
        Database.database().reference().child("users").child(creatorUid).child("social").updateChildValues(values, withCompletionBlock: { (err, ref) in
            if let err = err {
                print("spotUpdateSocialCountForUser ERROR |  \(creatorUid) \(socialField) TO \(final) ", err)
                return}
            
            print("   ~ spotUpdateSocialCountForUser SUCCESS | \(creatorUid) \(socialField) TO \(final)")
        })
        
        if let user = userCache[creatorUid] {
            var tempUser = user
            guard let final = final else {return}
            if socialField == .followingCount {
                tempUser.followingCount = final
            } else if socialField == .followerCount {
                tempUser.followersCount = final
            } else if socialField == .posts_created {
                tempUser.posts_created = final
            } else if socialField == .lists_created {
                tempUser.lists_created = final
            }
            print("   ~ Firebase | spotUpdateSocialCountForUserFinal | User Cache Updated | \(creatorUid!) | \(socialField!) | \(final)")
            userCache[creatorUid] = tempUser
            if creatorUid == CurrentUser.user?.uid {
                CurrentUser.user = tempUser
            }
            NotificationCenter.default.post(name: AppDelegate.NewCurrentUserSocialUpdate, object: nil)
        }
        
        
        
    }
    
    static func spotUpdateSocialCountForPost(postId: String!, socialField: String!, change: Int!){
        
        let postRef = Database.database().reference().child("posts").child(postId)
        postRef.runTransactionBlock({ (currentData) -> TransactionResult in
            guard let post = currentData.value as? [String : AnyObject] else {
                print(" ! Post Social Update Error: No Post", postId, socialField, change)
                return TransactionResult.abort()
            }
            
            var temp_post = post
            var cur_count = temp_post[socialField] as? Int ?? 0
            
            cur_count = max(0,cur_count+change)
            temp_post[socialField] = cur_count as AnyObject
            currentData.value = temp_post
            print("   SUCCESS | spotUpdateSocialCountForPost \(socialField!) for post : \(postId!) by: \(change!), New Count: \(cur_count)")
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(" ! ERROR | spotUpdateSocialCountForPost ", postId, socialField, change, error.localizedDescription)
            } else {

            }
        }
    }
    
    static func checkUserIsFollowed(user: User, completion: @escaping (User) ->()){
        
        var tempUser = user

        guard let uid = Auth.auth().currentUser?.uid else {
            tempUser.isFollowing = false
            completion(tempUser)
            return}
        let followingUid = user.uid
        
        // CHECK IF USER IS BLOCKED
        if CurrentUser.blockedUsers[tempUser.uid] != nil {
            print("CurrentUser is Blocking \(tempUser.uid)")
            tempUser.isBlockedByCurUser = true
            completion(tempUser)
        } else if user.blockedUsers[uid] != nil {
            print("CurrentUser is BLOCKED by \(tempUser.uid)")
            tempUser.isBlockedByUser = true
            completion(tempUser)
        }
        
        else {
        // CHECK IF USER IS FOLLOWED
            if CurrentUser.followingUids.count > 0 {
                
                if CurrentUser.followingUids.contains(user.uid) {
                    tempUser.isFollowing = true
                } else {
                    tempUser.isFollowing = false
                }
                completion(tempUser)
            } else {
                self.fetchFollowingUserUids(uid: uid, completion: { (fetchedIds) in
                    CurrentUser.followingUids = fetchedIds
                    if CurrentUser.followingUids.contains(user.uid) {
                        tempUser.isFollowing = true
                    } else {
                        tempUser.isFollowing = false
                    }
                    completion(tempUser)
                })
            }
        }
    }
    
    static func checkUserSocialStats(user: User, socialField: UserStats, socialCount: Int){
        print("checkUserSocialStats | \(user.uid) | \(socialField)")
        
        if socialField == .posts_created{
            if user.posts_created != socialCount {
                Database.spotUpdateSocialCountForUserFinal(creatorUid: user.uid, socialField: socialField, final: socialCount)
            }
        }
            
        else if socialField == .followingCount{
            if user.followingCount != socialCount {
                Database.spotUpdateSocialCountForUserFinal(creatorUid: user.uid, socialField: socialField, final: socialCount)
            }
        }
            
        else if socialField == .followerCount{
            if user.followersCount != socialCount {
                Database.spotUpdateSocialCountForUserFinal(creatorUid: user.uid, socialField: socialField, final: socialCount)
            }
        }
            
        else if socialField == .lists_created{
            if user.lists_created != socialCount {
                Database.spotUpdateSocialCountForUserFinal(creatorUid: user.uid, socialField: socialField, final: socialCount)
            }
        }
            
        else if socialField == .votes_received{
            if user.votes_received != socialCount {
                Database.spotUpdateSocialCountForUserFinal(creatorUid: user.uid, socialField: socialField, final: socialCount)
            }
        }
    }
    
    
//    static func spotUpdateSocialCountOLD(creatorUid: String!, receiverUid: String?, action: String!, change: Int!){
//
//        guard let receiverUid = receiverUid else {
//            print("No Receiver Uid Error")
//            return}
//
//        let creatorRef = Database.database().reference().child("users").child(creatorUid).child("social")
//        let receiveRef = Database.database().reference().child("users").child(receiverUid).child("social")
//
//        var creatorField: String! = ""
//        var receiveField: String! = ""
//
//        if action == "like"{
//            creatorField = "likeCount"
//            receiveField = "likedCount"
//        } else if action == "bookmark" {
//            creatorField = "bookmarkCount"
//            receiveField = "bookmarkedCount"
//        } else if action == "follow" {
//            creatorField = "followingCount"
//            receiveField = "followerCount"
//        } else if action == "post" {
//            creatorField = "postCount"
//            receiveField = "postCount"
//        } else if action == "vote" {
//            creatorField = "voteCount"
//            receiveField = "votedCount"
//        } else {
//            print("Invalid Social Action")
//            return
//        }
//
//        // Update creator social count - Not Keeping track of producing likes
//
//        if action != "like"{
//            creatorRef.runTransactionBlock({ (currentData) -> TransactionResult in
//            var user = currentData.value as? [String : AnyObject] ?? [:]
//            var count = user[creatorField] as? Int ?? 0
//            count = count + change
//            user[creatorField] = count as AnyObject?
//
//            currentData.value = user
//            print("Update \(creatorField!) for creator : \(creatorUid!) by: \(change!), New Count: \(count)")
//            return TransactionResult.success(withValue: currentData)
//
//            }) { (error, committed, snapshot) in
//                if let error = error {
//                print("Creator Social Update Error: ", creatorUid, error.localizedDescription)
//                }
//            }
//        }
//
//        // Update receiver social count  - Not applicable if post was created
//        if action != "post" {
//            receiveRef.runTransactionBlock({ (currentData) -> TransactionResult in
//                var user = currentData.value as? [String : AnyObject] ?? [:]
//                var count = user[receiveField] as? Int ?? 0
//                count = count + change
//                user[receiveField] = count as AnyObject?
//
//                currentData.value = user
//                print("Update \(receiveField!) for receiver : \(receiverUid) by: \(change!), New Count: \(count)")
//                return TransactionResult.success(withValue: currentData)
//
//            }) { (error, committed, snapshot) in
//                if let error = error {
//                    print("Receiver Social Update Error: ", creatorUid, error.localizedDescription)
//                }
//            }
//        }
//    }
    
    
    // MARK: - FILTER SORT POSTS

    static func sortLocation(inputLocation: [Location]?, sortInput: String? = ListSortDefault, completion: @escaping ([Location]) -> ()){
        
        var tempLoc: [Location] = []
        guard let inputLocation = inputLocation else {
            print("Sort List: ERROR, No List")
            completion([])
            return
        }
        
        if (sortInput == sortAuto || sortInput == sortPost || sortInput == sortTrending) {
            // Auto Sort - Legit and Bookmark First, then number of posts
            // Idea is that the list with the most posts are likely the oldest
            tempLoc = inputLocation.sorted(by: { (p1, p2) -> Bool in
                let p1Count = p1.postIds?.count ?? 0
                let p2Count = p2.postIds?.count ?? 0
                return p1Count >= p2Count
            })
            
        } else if sortInput == sortNew || sortInput == sortRecent{
            // Sort by Most Recent Modified Date - New Lists would have creation date as most recent
            tempLoc = inputLocation.sorted(by: { (p1, p2) -> Bool in
                
                let p1Date = p1.mostRecentDate
                let p2Date = p2.mostRecentDate
                return p1Date.compare(p2Date) == .orderedDescending
                
//                if p1.newNotifications.count != p2.newNotifications.count {
//                    return p1.newNotifications.count > p2.newNotificationsCount
//                } else {
//
//                    let p1Date = max(p1.mostRecentDate, p1.latestNotificationTime)
//                    let p2Date = max(p2.mostRecentDate, p2.latestNotificationTime)
//                    return p1Date.compare(p2Date) == .orderedDescending
//                }
            })
            
            
            
//            tempList = inputList.sorted(by: { (p1, p2) -> Bool in
//                let p1Date = max(p1.mostRecentDate, p1.latestNotificationTime)
//                let p2Date = max(p2.mostRecentDate, p2.latestNotificationTime)
//                return p1Date.compare(p2Date) == .orderedDescending
//            })
        } else if sortInput == sortNearest {
            // Sort by Location - Most Cred likely also has the most posts
            tempLoc = inputLocation.sorted(by: { (p1, p2) -> Bool in
                let p1Count = p1.distance ?? 999999
                let p2Count = p2.distance ?? 999999
                return p1Count <= p2Count
            })
        }
        
        completion(tempLoc)
        
    }
    
    static func sortCities(inputCity: [City]?, sortInput: String? = ListSortDefault, completion: @escaping ([City]) -> ()){
        
        var tempLoc: [City] = []
        guard let inputLocation = inputCity else {
            print("Sort List: ERROR, No List")
            completion([])
            return
        }
        
        if (sortInput == sortAuto || sortInput == sortPost || sortInput == sortTrending) {
            // Auto Sort - Legit and Bookmark First, then number of posts
            // Idea is that the list with the most posts are likely the oldest
            tempLoc = inputLocation.sorted(by: { (p1, p2) -> Bool in
                let p1Count = p1.postIds?.count ?? 0
                let p2Count = p2.postIds?.count ?? 0
                return p1Count >= p2Count
            })
            
        } else if sortInput == sortNew || sortInput == sortRecent{
            // Sort by Most Recent Modified Date - New Lists would have creation date as most recent
            tempLoc = inputLocation.sorted(by: { (p1, p2) -> Bool in
                
                let p1Date = p1.mostRecentDate
                let p2Date = p2.mostRecentDate
                return p1Date.compare(p2Date) == .orderedDescending
                
            })
            
            
        } else if sortInput == sortNearest {
            // Sort by Location - Most Cred likely also has the most posts
            tempLoc = inputLocation.sorted(by: { (p1, p2) -> Bool in
                let p1Count = p1.distance ?? 999999
                let p2Count = p2.distance ?? 999999
                return p1Count <= p2Count
            })
        }
        
        completion(tempLoc)
        
    }
    
    static func sortList(inputList: [List]?, sortInput: String? = ListSortDefault, completion: @escaping ([List]) -> ()){
        
        var tempList: [List] = []
        guard let inputList = inputList else {
            print("Sort List: ERROR, No List")
            completion([])
            return
        }
        
        if (sortInput == sortAuto || sortInput == sortPost) {
            // Auto Sort - Legit and Bookmark First, then number of posts
            // Idea is that the list with the most posts are likely the oldest
            tempList = inputList.sorted(by: { (p1, p2) -> Bool in
                let p1Count = p1.postIds?.count ?? 0
                let p2Count = p2.postIds?.count ?? 0
                return p1Count >= p2Count
            })
            
//            // Check For Legit
//            if let index = inputList.index(where: {$0.name == legitListName}){
//                tempList.append(inputList[index])
//            }
//
//            //Check For Bookmark
//            if let index = inputList.index(where: {$0.name == bookmarkListName}){
//                tempList.append(inputList[index])
//            }
            
            // Add Others
//            for list in inputList {
//                if !tempList.contains(where: {$0.id == list.id}){
//                    tempList.append(list)
//                }
//            }
        } else if sortInput == sortNew || sortInput == sortRecent{
            // Sort by Most Recent Modified Date - New Lists would have creation date as most recent
            tempList = inputList.sorted(by: { (p1, p2) -> Bool in
                
                let p1Date = p1.mostRecentDate
                let p2Date = p2.mostRecentDate
                return p1Date.compare(p2Date) == .orderedDescending
                
//                if p1.newNotifications.count != p2.newNotifications.count {
//                    return p1.newNotifications.count > p2.newNotificationsCount
//                } else {
//                    
//                    let p1Date = max(p1.mostRecentDate, p1.latestNotificationTime)
//                    let p2Date = max(p2.mostRecentDate, p2.latestNotificationTime)
//                    return p1Date.compare(p2Date) == .orderedDescending
//                }
            })
            
            
            
//            tempList = inputList.sorted(by: { (p1, p2) -> Bool in
//                let p1Date = max(p1.mostRecentDate, p1.latestNotificationTime)
//                let p2Date = max(p2.mostRecentDate, p2.latestNotificationTime)
//                return p1Date.compare(p2Date) == .orderedDescending
//            })
        } else if sortInput == sortTrending{
            // Sort by Most Cred - Most Cred likely also has the most posts
            tempList = inputList.sorted(by: { (p1, p2) -> Bool in
                let p1Count = p1.totalCred ?? 0
                let p2Count = p2.totalCred ?? 0
                return p1Count >= p2Count
            })
        } else if sortInput == sortNearest {
            // Check for distance
            var tempCheckedList:[List] = []
            for list in inputList {
                if list.listDistance != nil {
                    tempCheckedList.append(list)
                } else if list.listGPS != nil {
                    if let loc = CurrentUser.currentLocation {
                        list.listDistance = list.listGPS?.distance(from: loc)
                        tempCheckedList.append(list)
                    }
                }
            }
            // Sort by Location - Most Cred likely also has the most posts
            tempList = tempCheckedList.sorted(by: { (p1, p2) -> Bool in
                let p1Count = p1.listDistance ?? 999999
                let p2Count = p2.listDistance ?? 999999
                return p1Count <= p2Count
            })
        }
        
        completion(tempList)
        
    }
    
    static func filterSortPosts(inputPosts: [Post]?, postFilter: Filter, completion: @escaping ([Post]?) -> ()){
            
            // Filter Posts
            Database.filterPostsNew(inputPosts: inputPosts, postFilter: postFilter) { (filteredPosts) in
                // Sort Posts
                Database.sortPosts(inputPosts: filteredPosts, selectedSort: postFilter.filterSort, selectedLocation: postFilter.filterLocation, completion: { (filteredSortedPosts) in
                    completion(filteredSortedPosts)
                    
                })
            }
    }
    
    static func filterPostsNew(inputPosts: [Post]?, postFilter: Filter?, completion: @escaping ([Post]?) -> ()){
        guard let inputPosts = inputPosts else {
            print("Filter Posts: ERROR, No Post")
            completion(nil)
            return
        }
        //        print("Filter Start: \(inputPosts.count) Posts")
        
        
        // Filter For Duplicates
        var tempPosts: [Post] = Array(Set(inputPosts))
//
//        for post in inputPosts {
//            if !tempPosts.contains(where: { (tempPost) -> Bool in
//                tempPost.id == post.id
//            }){
//                tempPosts.append(post)
//            }
//        }
//        let dupCount = inputPosts.count - tempPosts.count
//        if dupCount > 0 {
//            print("   ~ Filter Dup: Removed \(dupCount) Dups")
//        }
        
        
        // Filter Caption
        let filterCaption = postFilter?.filterCaption
        if filterCaption != nil && filterCaption != "" {
            guard let searchedText = filterCaption?.lowercased() else {return}
            
            var preFilterPosts = inputPosts
            
            // Determine Search Terms
            var searchTerms: [String] = [searchedText]
            
            // Split Search Terms into Individual Words
            var splitSearchTerms = searchedText.components(separatedBy: " ")
            if (splitSearchTerms.count) > 1 {
                //Searches Full Combined Term and Individual Terms
                searchTerms += splitSearchTerms
            }
            
        // Translate Emoji into Word
            var emojiToTextTerms: [String] = []
            if searchedText.emojis.count > 0 {
                // Searches for Emoji Characters in Search Text.
                // Looks up whole emoji as the flag emojis get split up JAPAN into J & P
                var searchedEmojis = searchedText.emojis
                searchedEmojis.append(searchedText)
                
                for string in searchedEmojis {
                    if let emojiToText = EmojiDictionary[string] {
                        emojiToTextTerms.append(emojiToText)
                    }
                }
//                searchTerms += searchedText.emojis
            }
            
            if emojiToTextTerms.count > 0 {
                print("Translated Emoji To Search Caption | \(emojiToTextTerms)")
                searchTerms += emojiToTextTerms
            }
            
        // Translate Word into Emoji
            var emojiTerms: [String] = []
            for string in searchTerms {
                if let textToEmoji = ReverseEmojiDictionary[string] {
                    emojiTerms.append(textToEmoji)
                }
            }

            if emojiTerms.count > 0 {
                print("Translated Search Caption To Emoji | \(emojiTerms)")
                searchTerms += emojiTerms
            }
            
            // Clear Search Terms of any blanks
            for term in searchTerms {
                if term.isEmptyOrWhitespace() {
                    let index = searchTerms.firstIndex(of: term)
                    searchTerms.remove(at: index!)
                }
            }
            
            var tempFilterPosts: [Post] = []
            
            for post in preFilterPosts {
                var postEmojis = post.emoji + " " + post.nonRatingEmojiTags.joined(separator: " ")
                var autoTagEmojis = post.autoTagEmoji.joined() + " " + post.autoTagEmojiTags.joined(separator: " ")
                
                var caption: [String] = post.caption.lowercased().words()
                
                var allOtherCaption = postEmojis + " " + autoTagEmojis + " " + post.locationName.lowercased() + " " + post.locationAdress.lowercased() + " " + (post.locationSummaryID ?? "").lowercased()
                // Loops through all search terms until one is found in all caption
                for searchWord in searchTerms {
                    if caption.contains(searchWord) || allOtherCaption.lowercased().contains(searchWord) {
                        tempFilterPosts.append(post)
                        // If it finds a matching word it adds it to tempPost and breaks
                        break
                    }
                }
            }
            print("Filtered Post By Caption: \(searchTerms), Pre: \(tempPosts.count), Post: \(tempFilterPosts.count)")
            tempPosts = tempFilterPosts
        }

    // Filter Specifically for a Google Location (Non-nil google location and range = 0)
        let filterGoogleLocationID = postFilter?.filterGoogleLocationID
        let filterGoogleLocationName = postFilter?.filterLocationName
        let filterRange = postFilter?.filterRange
        let filterLocation = postFilter?.filterLocation
        
        if filterGoogleLocationID != nil && filterRange == nil {
            
            var tempFilterPosts: [Post] = []
            for post in tempPosts {
                var tempPost = post
                if tempPost.locationGooglePlaceID == filterGoogleLocationID {
                    tempFilterPosts.append(tempPost)
                }
            }
            print("Filtered Post By Google Location ID: \(filterGoogleLocationID), Range: \(filterRange), Pre: \(tempPosts.count), Post: \(tempFilterPosts.count)")
            tempPosts = tempFilterPosts
        }
        
        else if filterGoogleLocationName != nil && filterRange == nil && filterGoogleLocationName != CurrentUserLocation {
            
            var tempFilterPosts: [Post] = []
            for post in tempPosts {
                var tempPost = post
                if tempPost.locationName == filterGoogleLocationName {
                    tempFilterPosts.append(tempPost)
                }
            }
            print("Filtered Post By Google Name: \(filterGoogleLocationName), Range: \(filterRange), Pre: \(tempPosts.count), Post: \(tempFilterPosts.count)")
            tempPosts = tempFilterPosts
        }
            
            // Filter for Location and a Range
        else if filterLocation != nil && filterRange != nil && filterRange != globalRangeDefault {
            var tempFilterPosts: [Post] = []
            for post in tempPosts {
                var tempPost = post
                if tempPost.locationGPS != nil {
                    tempPost.distance = Double((tempPost.locationGPS?.distance(from: filterLocation!))!)
                } else {
                    tempPost.distance = 9999999
                }
                
                if tempPost.distance! <= (Double(filterRange!)! * 1000) {
                    tempFilterPosts.append(tempPost)
                }
            }
            print("Filtered Post By Range: \(filterRange) AT \(filterLocation), Pre: \(tempPosts.count), Post: \(tempFilterPosts.count)")
            tempPosts = tempFilterPosts
        }
        
        // Filter for Location ID
        let filterLocationSummaryID = postFilter?.filterLocationSummaryID

        if filterLocationSummaryID != nil {
            var tempFilterPosts: [Post] = []
            for post in tempPosts {
                var tempPost = post
                if tempPost.locationSummaryID == filterLocationSummaryID {
                    tempFilterPosts.append(tempPost)
                }
            }
            print("Filtered Post By Location Summary ID: \(filterLocationSummaryID) , Pre: \(tempPosts.count), Post: \(tempFilterPosts.count)")
            tempPosts = tempFilterPosts
        }
        
        // Filter Rating
        let filterMinRating = postFilter?.filterMinRating
        if filterMinRating != 0 && filterMinRating != nil {
            var tempFilterPosts: [Post] = []
            tempFilterPosts = tempPosts.filter { (post) -> Bool in
                var filterRating:Double = 0
                if post.rating != nil {
                    filterRating = post.rating!
                }
                return filterRating >= filterMinRating!
            }
            print("Filtered Post By Min Rating: \(filterMinRating), Pre: \(tempPosts.count), Post: \(tempFilterPosts.count)")
            tempPosts = tempFilterPosts
        }
        
        // Filter Legit
        let filterLegit = postFilter?.filterLegit

        if filterLegit == true {
            var tempFilterPosts: [Post] = []
            tempFilterPosts = tempPosts.filter { (post) -> Bool in
                return !(post.ratingEmoji?.isEmptyOrWhitespace() ?? true)
            }
            print("Filtered Post By Legit: \(filterLegit), Pre: \(tempPosts.count), Post: \(tempFilterPosts.count)")
            tempPosts = tempFilterPosts
        }
        
        // FILTER TIME
        let filterTime = postFilter?.filterTime
        
        if filterTime! > 0 {
            var tempFilterPosts: [Post] = []
            
            tempFilterPosts = tempPosts.filter { (post) -> Bool in
                return post.creationDate.daysAgo() <= filterTime!
            }
            print("Filtered Post By Time: \(filterTime) , Pre: \(tempPosts.count), Post: \(tempFilterPosts.count)")
            tempPosts = tempFilterPosts
        }
        
        
        // Filter Type - Meal and Cuisine - Type Searches will all be text
        
        if let filterType = postFilter?.filterType {
            var tempFilterPosts: [Post] = []
            tempFilterPosts = tempPosts.filter { (post) -> Bool in
                return post.autoTagEmojiTags.contains(filterType)
            }
            
            if let emoji = ReverseEmojiDictionary[filterType] {
                let tempEmojiSearchPost = tempPosts.filter { (post) -> Bool in
                    return post.nonRatingEmoji.contains(emoji)
                }
                tempFilterPosts += (tempEmojiSearchPost)
                print("Auto-Tag Search | \(tempEmojiSearchPost.count) Results from Emoji Tag | \(filterType) : \(emoji)")
            }
            
            print("Filtered Post By Post Type: \(filterType), Pre: \(tempPosts.count), Post: \(tempFilterPosts.count)")
            tempPosts = tempFilterPosts
        }
        
        
        if (postFilter?.filterTypeArray.count ?? 0) > 0 {
            var tempFilterPosts: [Post] = []
            
            guard let filterTypeArray = postFilter?.filterTypeArray else {return}
            for term in filterTypeArray {
                // So we search emoji tags for also the emoji representation of the types?
                
                let x = term.lowercased()
                
                // Search for text type : lunch, french - could also search caption
                let tempTypeSearchPost = tempPosts.filter { (post) -> Bool in
                    return post.autoTagEmojiTags.contains(x)/* || post.caption.contains(x)*/
                }
                tempFilterPosts += (tempTypeSearchPost)

                // Checks for Non Rating Emoji Tags
                if let emote = EmojiDictionary[x] {
                    let tempEmojiSearchPost = tempPosts.filter { (post) -> Bool in
                        return post.nonRatingEmoji.contains(emote)
                    }
                    tempFilterPosts += (tempEmojiSearchPost)
                }
            }
            
            print("Filtered Post By filterTypeArray: \(postFilter?.filterTypeArray), Pre: \(tempPosts.count), Post: \(Array(Set(tempFilterPosts)).count)")
            // Filters out unique
            tempPosts = Array(Set(tempFilterPosts))
            
        }
        
        
        if ((postFilter?.filterCaptionArray.count) ?? 0) > 0 {
            var tempFilterPosts: [Post] = []
            guard let filterCaptionArray = postFilter?.filterCaptionArray else {
                return
            }
            
            var tempCaptionSearchArray: [String] = []
            for x in filterCaptionArray
            {
                tempCaptionSearchArray.append(x)
                
                // If Emoji, search for text intepretation
                if x.containsOnlyEmoji {
                    if let text = EmojiDictionary[x] {
                        tempCaptionSearchArray.append(text)
                    }
                } else {
                    if let emoji = EmojiDictionary.key(forValue: x) {
                        tempCaptionSearchArray.append(emoji)
                    }
                }
            }
            
            print("Caption Filter Array | Ori: \(filterCaptionArray) | More: \(tempCaptionSearchArray)")
            
            
            for term in tempCaptionSearchArray {
                // So we search emoji tags for also the emoji representation of the types?
                let x = term.lowercased()

                // Search for text type : lunch, french - could also search caption
                let tempTypeSearchPost = tempPosts.filter { (post) -> Bool in
                    let captionTexts = post.caption.lowercased().words()
                    
                    return captionTexts.contains(x) || post.locationName.lowercased().contains(x) || post.nonRatingEmoji.contains(x) || post.autoTagEmoji.contains(x) || post.nonRatingEmojiTags.contains(x) || post.autoTagEmojiTags.contains(x) || post.locationAdress.lowercased().contains(x) || ((post.locationSummaryID ?? "").lowercased() ?? "").contains(x)
                }
                tempFilterPosts += (tempTypeSearchPost)

            }
            
            let oldCount = tempPosts.count
            // Filters out unique
            tempPosts = Array(Set(tempFilterPosts))
            print("Filtered Post By filterCaptionArray: \(postFilter?.filterCaptionArray), Pre: \(oldCount), Post: \(tempPosts.count)")

        }
        
        
        // Filter Max Price
        let filterMaxPrice = postFilter?.filterMaxPrice

        if filterMaxPrice != nil {
            let maxPriceIndex = UploadPostPriceDefault.firstIndex(of: filterMaxPrice!)
            let filterMaxPrice = UploadPostPriceDefault[0...maxPriceIndex!]
            var tempFilterPosts: [Post] = []
            
            tempFilterPosts = tempPosts.filter { (post) -> Bool in
                var filterPrice:String = "0"
                if post.price != nil {
                    filterPrice = post.price!
                }
                return filterMaxPrice.contains(filterPrice)
            }
            print("Filtered Post By Max Price: \(filterMaxPrice), Pre: \(tempPosts.count), Post: \(tempFilterPosts.count)")
            tempPosts = tempFilterPosts
        }
        
        // FILTER LIST
        let filterList = postFilter?.filterList

        if filterList != nil {
            var filterListPostIds: [String] = []
            
            for (key,value) in (filterList?.postIds)! {
                filterListPostIds.append(key)
            }
            
            var tempFilterPosts: [Post] = []
            
            tempFilterPosts = tempPosts.filter { (post) -> Bool in
                return filterListPostIds.contains(post.id!)
            }
            print("Filtered Post By List: \(filterList?.name) | \(filterListPostIds.count) Posts |, Pre: \(tempPosts.count), Post: \(tempFilterPosts.count)")
            tempPosts = tempFilterPosts
        }
        
        // FILTER USER
        let filterUser = postFilter?.filterUser

        if filterUser != nil {
            var tempFilterPosts: [Post] = []
            
            tempFilterPosts = tempPosts.filter { (post) -> Bool in
                return post.creatorUID == filterUser?.uid
            }
            print("Filtered Post By User: \(filterUser?.username) , Pre: \(tempPosts.count), Post: \(tempFilterPosts.count)")
            tempPosts = tempFilterPosts
        }
        
        // FILTER RATING EMOJI
        let filterRatingEmoji = postFilter?.filterRatingEmoji

        if filterRatingEmoji != nil {
            var tempFilterPosts: [Post] = []
            
            tempFilterPosts = tempPosts.filter { (post) -> Bool in
                return post.ratingEmoji == filterRatingEmoji
            }
            print("Filtered Post By Rating Emoji: \(filterRatingEmoji) , Pre: \(tempPosts.count), Post: \(tempFilterPosts.count)")
            tempPosts = tempFilterPosts
        }
        
        
        
        print("   ~ filterPostsNew | Pre: \(inputPosts.count), Post: \(tempPosts.count)")
        completion(tempPosts)
    
    
    
    
    
    
    }
    
    
    static func filterPosts(inputPosts: [Post]?, filterCaption: String?, filterRange: String?, filterLocation: CLLocation?, filterGoogleLocationID: String?, filterMinRating: Double?, filterType: String?, filterMaxPrice: String?, filterLegit: Bool? = false, filterList: List?, filterUser: User?, completion: @escaping ([Post]?) -> ()){
        
        guard let inputPosts = inputPosts else {
            print("Filter Posts: ERROR, No Post")
            completion(nil)
            return
        }
//        print("Filter Start: \(inputPosts.count) Posts")

        
        // Filter For Duplicates
        var tempPosts: [Post] = []

        for post in inputPosts {
            if !tempPosts.contains(where: { (tempPost) -> Bool in
                tempPost.id == post.id
            }){
                tempPosts.append(post)
            }
        }
        let dupCount = inputPosts.count - tempPosts.count
        if dupCount > 0 {
            print("   ~ Filter Dup: Removed \(dupCount) Dups")
        }
    
        
    // Filter Caption
        if filterCaption != nil && filterCaption != "" {
            guard let searchedText = filterCaption?.lowercased() else {return}
            
            var preFilterPosts = inputPosts
            
            // Determine Search Terms
            var searchTerms: [String] = [searchedText]
            
            // Split Search Terms into Individual Words
            var splitSearchTerms = searchedText.components(separatedBy: " ")
            if (splitSearchTerms.count) > 1 {
                //Searches Full Combined Term and Individual Terms
                searchTerms += splitSearchTerms
            }
            
            if searchedText.emojis.count > 0 {
                // Searches for Emoji Characters in Search Text
                searchTerms += searchedText.emojis
            }
            
            // Find Emojis for Search Word and individual words
            var emojiTerms: [String] = []
            for string in searchTerms {
                if let emoji = ReverseEmojiDictionary[string] {
                    emojiTerms.append(emoji)
                }
            }
            if emojiTerms.count > 0 {
                searchTerms += emojiTerms
            }
            
            var tempFilterPosts: [Post] = []
            
            for post in preFilterPosts {
                var postEmojis = post.emoji + " " + post.nonRatingEmojiTags.joined(separator: " ")
                var autoTagEmojis = post.autoTagEmoji.joined() + " " + post.autoTagEmojiTags.joined(separator: " ")
                
                var allCaption = post.caption.lowercased() + " " + postEmojis + " " + autoTagEmojis + " " + post.locationName + " " + post.locationAdress
                // Loops through all search terms until one is found in all caption
                for searchWord in searchTerms {
                    if allCaption.lowercased().contains(searchWord){
                        tempFilterPosts.append(post)
                        // If it finds a matching word it adds it to tempPost and breaks
                        break
                    }
                }
            }
            print("Filtered Post By Caption: \(searchedText), Pre: \(tempPosts.count), Post: \(tempFilterPosts.count)")
            tempPosts = tempFilterPosts
        }
        
        
//        // Filter Caption
//        if filterCaption != nil && filterCaption != "" {
//            guard let searchedText = filterCaption else {return}
//
//            var preFilterPosts = inputPosts
//            var searchTerms = filterCaption?.components(separatedBy: " ")
//
//            tempPosts = tempPosts.filter { (post) -> Bool in
//                let searchedEmoji = ReverseEmojiDictionary[searchedText.lowercased()] ?? ""
//
//                return post.caption.lowercased().contains(searchedText.lowercased())
//                    || post.emoji.contains(searchedText.lowercased())
//                    || post.nonRatingEmojiTags.joined(separator: " ").lowercased().contains(searchedText.lowercased())
//                    || post.nonRatingEmojiTags.joined(separator: " ").lowercased().contains(searchedEmoji)
//                    || post.locationName.lowercased().contains(searchedText.lowercased())
//                    || post.locationAdress.lowercased().contains(searchedText.lowercased())
//            }
//            print("Filtered Post By Caption: \(searchedText): \(tempPosts.count)")
//
//        }
        
        // All Post Distances are updated In Sort Function
        
        // Filter Range
        
        // Filter Specifically for a Google Location (Non-nil google location and range = 0)
        if filterGoogleLocationID != nil && filterRange == nil {
            
            var tempFilterPosts: [Post] = []
            for post in tempPosts {
                var tempPost = post
                if tempPost.locationGooglePlaceID == filterGoogleLocationID {
                    tempFilterPosts.append(tempPost)
                }
            }
            print("Filtered Post By Google Location ID: \(filterGoogleLocationID), Pre: \(tempPosts.count), Post: \(tempFilterPosts.count)")
            tempPosts = tempFilterPosts
        }
        
        // Filter for Location and a Range
        else if filterLocation != nil && filterRange != nil && filterRange != globalRangeDefault {
            var tempFilterPosts: [Post] = []
            for post in tempPosts {
                var tempPost = post
                if tempPost.locationGPS != nil {
                    tempPost.distance = Double((tempPost.locationGPS?.distance(from: filterLocation!))!)
                } else {
                    tempPost.distance = 9999999
                }
                
                if tempPost.distance! <= (Double(filterRange!)! * 1000) {
                    tempFilterPosts.append(tempPost)
                }
            }
            print("Filtered Post By Range: \(filterRange) AT \(filterLocation), Pre: \(tempPosts.count), Post: \(tempFilterPosts.count)")
            tempPosts = tempFilterPosts
        }
        
        
        
        
        
//        if filterLocation != nil && filterRange != nil && filterRange != globalRangeDefault {
//            tempPosts = tempPosts.filter { (post) -> Bool in
//                var filterDistance:Double = 99999999
//                if let distance = Double((post.locationGPS?.distance(from: filterLocation!))!) {
//                    post.distance = distance
//                } else {
//                    post.distance = filterDistance
//                }
////                if post.distance != nil {
////                    filterDistance = post.distance!
////                }
//                return post.distance <= (Double(filterRange!)! * 1000)
//            }
//            print("Filtered Post By Range: \(filterRange) AT \(filterLocation): \(tempPosts.count)")
//        }
        
        // Filter Rating
        if filterMinRating != 0 && filterMinRating != nil {
            var tempFilterPosts: [Post] = []
            tempFilterPosts = tempPosts.filter { (post) -> Bool in
                var filterRating:Double = 0
                if post.rating != nil {
                    filterRating = post.rating!
                }
                return filterRating >= filterMinRating!
            }
            print("Filtered Post By Min Rating: \(filterMinRating), Pre: \(tempPosts.count), Post: \(tempFilterPosts.count)")
            tempPosts = tempFilterPosts
        }
        
        // Filter Legit
        if filterLegit == true {
            var tempFilterPosts: [Post] = []
            tempFilterPosts = tempPosts.filter { (post) -> Bool in
                return post.isLegit
            }
            print("Filtered Post By Legit: \(filterLegit), Pre: \(tempPosts.count), Post: \(tempFilterPosts.count)")
            tempPosts = tempFilterPosts
        }
        
        // Filter Type
        if filterType != nil {
            var tempFilterPosts: [Post] = []
            tempFilterPosts = tempPosts.filter { (post) -> Bool in
                return post.type == filterType
            }
            print("Filtered Post By Post Type: \(filterType), Pre: \(tempPosts.count), Post: \(tempFilterPosts.count)")
            tempPosts = tempFilterPosts
        }
        
        // Filter Max Price
        if filterMaxPrice != nil {
            let maxPriceIndex = UploadPostPriceDefault.firstIndex(of: filterMaxPrice!)
            let filterMaxPrice = UploadPostPriceDefault[0...maxPriceIndex!]
            var tempFilterPosts: [Post] = []

            tempFilterPosts = tempPosts.filter { (post) -> Bool in
                var filterPrice:String = "0"
                if post.price != nil {
                    filterPrice = post.price!
                }
                return filterMaxPrice.contains(filterPrice)
            }
            print("Filtered Post By Max Price: \(filterMaxPrice), Pre: \(tempPosts.count), Post: \(tempFilterPosts.count)")
            tempPosts = tempFilterPosts
        }
        
        // FILTER LIST
        if filterList != nil {
            var filterListPostIds: [String] = []
            
            for (key,value) in (filterList?.postIds)! {
                filterListPostIds.append(key)
            }
            
            var tempFilterPosts: [Post] = []
            
            tempFilterPosts = tempPosts.filter { (post) -> Bool in
                return filterListPostIds.contains(post.id!)
            }
            print("Filtered Post By List: \(filterList?.name) | \(filterListPostIds.count) Posts |, Pre: \(tempPosts.count), Post: \(tempFilterPosts.count)")
            tempPosts = tempFilterPosts
        }
        
        // FILTER USER
        if filterUser != nil {
            var tempFilterPosts: [Post] = []
            
            tempFilterPosts = tempPosts.filter { (post) -> Bool in
                return post.creatorUID == filterUser?.uid
            }
            print("Filtered Post By User: \(filterUser?.username) , Pre: \(tempPosts.count), Post: \(tempFilterPosts.count)")
            tempPosts = tempFilterPosts
        }
        
        
        print("   ~ filterPostsNew | Pre: \(inputPosts.count), Post: \(tempPosts.count)")
        completion(tempPosts)
    }
    
    static func checkLocationForSort(filter: Filter, completion: @escaping () -> ()) {
        if filter.filterSort == sortNearest {
            let timeSinceLastLocation = Date().timeIntervalSince(filter.filterLocationTime)
            if timeSinceLastLocation > 3600 {
                print("Refreshing Location - Too Long:", timeSinceLastLocation)
                LocationSingleton.sharedInstance.determineCurrentLocation()
                return
            }
            
            if filter.filterSort == sortNearest && filter.filterLocation == nil {
                print("Refreshing Location - No Location")
                LocationSingleton.sharedInstance.determineCurrentLocation()
                return
            }
            completion()
        } else {
            completion()
        }
    }

    
    static func sortPosts(inputPosts: [Post]?, selectedSort: String?, selectedLocation: CLLocation?, completion: @escaping ([Post]?) -> ()){
        guard let inputPosts = inputPosts else {
            print("Sort Posts: ERROR, No Post")
            completion(nil)
            return
        }
        
        if selectedSort == defaultNearestSort && selectedLocation == nil {
            print("Sort Posts Error - Sort Nearest With No Location")
            LocationSingleton.sharedInstance.determineCurrentLocation()
            return
        }
        
        var tempPosts = inputPosts
        
        print(" ~ Sort Posts: \(selectedSort!)")
        
        // Recent
        if selectedSort == defaultRecentSort {
            tempPosts.sort(by: { (p1, p2) -> Bool in
                return p1.creationDate.compare(p2.creationDate) == .orderedDescending
            })
            completion(tempPosts)
        }
            
        // Recent Listed Date
        else if selectedSort == sortListed {
            tempPosts.sort(by: { (p1, p2) -> Bool in
                return p1.listedDate!.compare(p2.listedDate!) == .orderedDescending
            })
            completion(tempPosts)
        }
            
            // Nearest
        else if selectedSort == defaultNearestSort {
                // Distances are updated in fetchallposts as they are filtered by distance
            
            var filterLocation: CLLocation? = nil
            
            if selectedLocation != nil {
                filterLocation = selectedLocation
            }
            
            else if selectedLocation == nil {
                print("Sort Nearest: Default Current Location")
                filterLocation = CurrentUser.currentLocation
            }
            
            if filterLocation == nil {
                print("Sort Nearest: ERROR, No Location")
                self.alert(title: "No Location", message: "Legit doesn't have access to your current location. Will default to sorting new.")
                tempPosts.sort(by: { (p1, p2) -> Bool in
                    return p1.creationDate.compare(p2.creationDate) == .orderedDescending
                })
                completion(tempPosts)
                return
            }
            
                //Update Posts for distances
                for (index,post) in tempPosts.enumerated() {
                    var tempPost = post
                    if tempPost.locationGPS == nil || tempPost.locationGPS == CLLocation(latitude: 0, longitude: 0) {
                        print("Sort Nearest: No GPS Location for \(tempPost.id), default Distance")
                        tempPost.distance = 999999999
                    } else {
                        tempPost.distance = Double((tempPost.locationGPS?.distance(from: filterLocation!))!)
                    }
                    tempPosts[index] = tempPost
                }

                tempPosts.sort(by: { (p1, p2) -> Bool in
                    return (p1.distance! < p2.distance!)
                })
                completion(tempPosts)
        }
            
            //Trending
        else if selectedSort == sortTrending {
            tempPosts.sort(by: { (p1, p2) -> Bool in
                return (p1.credCount > p2.credCount)
            })
            completion(tempPosts)
        }
            
            
            // Ratings
        else if selectedSort == LocationSortOptions[1] {
            tempPosts.sort(by: { (p1, p2) -> Bool in
                return (p1.rating! > p2.rating!)
            })
            completion(tempPosts)
        }
            
            // Votes
        else if selectedSort == defaultRankOptions[0] {
            tempPosts.sort(by: { (p1, p2) -> Bool in
                return (p1.likeCount > p2.likeCount)
            })
            completion(tempPosts)
        }
            
            // Bookmarks
        else if selectedSort == defaultRankOptions[1] {
            tempPosts.sort(by: { (p1, p2) -> Bool in
                return (p1.listCount > p2.listCount)
            })
            completion(tempPosts)
        }
            
            // Message
        else if selectedSort == defaultRankOptions[2] {
            tempPosts.sort(by: { (p1, p2) -> Bool in
                return (p1.messageCount > p2.messageCount)
            })
            completion(tempPosts)
        }
            
            // Rank
        else if selectedSort == "Rank" {
            print("Rank Sort")
            tempPosts.sort(by: { (p1, p2) -> Bool in
                return (p1.listedRank ?? 999 < p2.listedRank ?? 999)
            })
            completion(tempPosts)
        }
            
            
            // ERROR - Invalid Sort
        else {
            print("Fetched Post Sort: ERROR, Invalid Sort")
            completion(tempPosts)
        }
        
    }
    
    static func pickOnePostForLocation(posts: [Post], googleLocationID: String?, locationName: String?) -> (Post?) {
        // Priority goes to latest post from current user
        // Then latest or most popular posts from other users
        
        guard let uid = Auth.auth().currentUser?.uid else {return nil}
        if posts.count == 0 {return nil}
        
        var tempPost:[Post] = []
        if let googleLocationID = googleLocationID {
            tempPost = posts.filter { (post) -> Bool in
                return (post.locationGooglePlaceID == googleLocationID)
            }
        } else if let locationName = locationName {
            tempPost = posts.filter { (post) -> Bool in
                return (post.locationName == locationName)
            }
        }

        
    // FILTER FOR POST FROM CURRENT USER
        var selfPost = tempPost.filter({$0.creatorUID == uid})
        
    // RETURN LATEST POST FROM CURRENT USER
        if selfPost.count > 0 {
            selfPost.sort { (p1, p2) -> Bool in
                return p1.creationDate.compare(p2.creationDate) == .orderedDescending
            }
            return selfPost[0]
        }

    // SORT BY CRED FIRST, THEN DATE
        else if tempPost.count > 0{
            tempPost.sort { (p1, p2) -> Bool in
                if p1.credCount == p2.credCount {
                    return p1.creationDate.compare(p2.creationDate) == .orderedDescending
                } else {
                    return p1.credCount > p2.credCount
                }
            }
            return tempPost[0]
        } else {
            return nil
        }
    }
    
    static func sortUsers(inputUsers: [User]?, selectedSort: String?, selectedLocation: CLLocation?, completion: @escaping ([User]?) -> ()){
        guard let inputUsers = inputUsers else {
            print("Sort Users: ERROR, No Post")
            completion(nil)
            return
        }
        
        var tempUsers = inputUsers
        
        print("Sort Users: \(selectedSort!)")
        
        // Recent
        if selectedSort == defaultRecentSort {
            tempUsers.sort(by: { (p1, p2) -> Bool in
                return p1.creationDate.compare(p2.creationDate) == .orderedDescending
            })
            completion(tempUsers)
        }
            
            // Nearest
        else if selectedSort == defaultNearestSort {
            // Distances are updated in fetchallposts as they are filtered by distance
            
            var filterLocation: CLLocation? = nil
            
            if let selectedLocation = selectedLocation {
                print("User Sort Nearest: Provided Location")
                filterLocation = selectedLocation
            } else {
                print("User Sort Nearest: Default Current Location")
                filterLocation = CurrentUser.currentLocation
            }
            
            if filterLocation == nil {
                print("User Posts Error - Sort Nearest With No Location")
                LocationSingleton.sharedInstance.determineCurrentLocation()
                completion(inputUsers)
                return
            }

            
            //Update Posts for distances
            for (index,user) in tempUsers.enumerated() {
                var tempUser = user
                if tempUser.userGPS == nil || tempUser.userGPS == CLLocation(latitude: 0, longitude: 0) {
                    print("Sort Nearest: No GPS Location for \(tempUser.uid), default Distance")
                    tempUser.userDistance = 999999999
                } else {
                    tempUser.userDistance = Double((tempUser.userGPS?.distance(from: filterLocation!))!)
                }
                tempUsers[index] = tempUser
            }
            
            tempUsers.sort(by: { (p1, p2) -> Bool in
                return (p1.userDistance! < p2.userDistance!)
            })
            completion(tempUsers)
        }
            
            //Trending
        else if selectedSort == sortTrending {
            tempUsers.sort(by: { (p1, p2) -> Bool in
                return (p1.total_cred > p2.total_cred)
            })
            completion(tempUsers)
        }
            
            //Trending
        else if selectedSort == sortPost {
            tempUsers.sort(by: { (p1, p2) -> Bool in
                return (p1.posts_created > p2.posts_created)
            })
            completion(tempUsers)
        }
            
            // ERROR - Invalid Sort
        else {
            print("Fetched User Sort: ERROR, Invalid Sort")
            completion(tempUsers)
        }
        
    }
    
    static func checkTop5Emojis(userId: String, emojis: [String]) {
        let creatorRef = Database.database().reference().child("users").child(userId)
        creatorRef.runTransactionBlock({ (currentData) -> TransactionResult in
            var user = currentData.value as? [String : AnyObject] ?? [:]
            var topEmojis = user["topEmojis"] as? [String] ?? []
            
            let dif = emojis.difference(from: topEmojis)
            if dif.count > 0 {
                print("Update Top Emojis for \(userId) | Cur \(emojis) | Database \(topEmojis)")
                user["topEmojis"] = emojis as AnyObject?
                currentData.value = user
                print("Update Top Emojis for \(userId) | \(topEmojis) TO \(emojis)")
                return TransactionResult.success(withValue: currentData)
            } else {
                print("No Difference in Emojis for \(userId) | \(topEmojis) | \(emojis)")
                return TransactionResult.abort()
            }
        }) { (error, committed, snapshot) in
            if let error = error {
                print("Update Top Emoji Error: ", userId, error.localizedDescription)
            }
        }
    }
    
    static func checkTop5EmojisForList(listId: String, emojis: [String]) {
        let creatorRef = Database.database().reference().child("lists").child(listId)
        creatorRef.runTransactionBlock({ (currentData) -> TransactionResult in
            var list = currentData.value as? [String : AnyObject] ?? [:]
            var topEmojis = list["topEmojis"] as? [String] ?? []
            
            let dif = emojis.difference(from: topEmojis)
            if dif.count > 0 {
                print("Update Top Emojis for \(listId) | Cur \(emojis) | Database \(topEmojis)")
                list["topEmojis"] = emojis as AnyObject?
                currentData.value = list
                print("Update Top Emojis for \(listId) | \(topEmojis) TO \(emojis)")
                return TransactionResult.success(withValue: currentData)
            } else {
                print("No Difference in Emojis for \(listId) | \(topEmojis) | \(emojis)")
                return TransactionResult.abort()
            }
        }) { (error, committed, snapshot) in
            if let error = error {
                print("Update Top Emoji Error: ", listId, error.localizedDescription)
            }
        }
    }
    
    
    
     static func translateToEmojiArray(stringInput: String?, completion: @escaping ([String]?) -> ()){
        guard let tempSearchText = stringInput else {
            print("Translate Emoji: ERROR, No String")
            return
        }
        if tempSearchText.isEmptyOrWhitespace(){
            print("Translate Emoji: ERROR, All Blank Spaces")
            return
        }
        
//        var emojiString = tempSearchText.removeDuplicates.emojis ?? []

        var otherString = tempSearchText.emojilessString.components(separatedBy: " ")
        
        // Check other string for single emoji translates
        var emojiTranslateTemp: [String] = []
        var emojiTranslate: [String] = []
        
        for str in otherString {
            if let foundEmoji = ReverseEmojiDictionary[str.lowercased()] {
                emojiTranslateTemp.append(foundEmoji)
            }
        }
        
        // Check other string for 2 word combo emoji translates
        var stringCount = otherString.count ?? 0
        if stringCount > 1 {
            for i in (0...(stringCount-1)-1) {
                let doubleword = otherString[i] + " " + otherString[i+1]
                if let foundEmoji = ReverseEmojiDictionary[doubleword.lowercased()] {
                    emojiTranslateTemp.append(foundEmoji)
                }
            }
        }
        
        // Remove Dups from other string translations
        if emojiTranslateTemp.count > 0 {
            for i in (0...emojiTranslateTemp.count-1){
                if let _ = emojiTranslate.firstIndex(of: emojiTranslateTemp[i]){
                    print("Contains dup emoji \(emojiTranslateTemp[i])")
                } else {
                    emojiTranslate.append(emojiTranslateTemp[i])
                }
            }
        }
        
        var emojiString = Array(Smile.extractEmojis(string: tempSearchText))
        var emojiStringArray: Array<String> = []
        for char in emojiString {
            emojiStringArray.append(String(char))
        }
        
        let finalOutput:Array<String> = emojiStringArray + emojiTranslate
        print("Emoji Translate: \(stringInput) TO: \(finalOutput)")
        completion(finalOutput)
    }
    
    static func guessPostMeal(googleLocationType: [String]?, currentTime: Date, completion: @escaping (EmojiBasic?) -> ()){
        
        let calendar = Calendar.current // or e.g. Calendar(identifier: .persian)
        let hour = calendar.component(.hour, from: currentTime)
        let day = calendar.component(.weekday, from: currentTime)
        var tempPostType: String? = nil
        
        if let googleLocationType = googleLocationType {
            // Guess By Location Type
            if (googleLocationType.contains("restaurant")) {
                // Guess by Timing - For restaurant since most places are bar AND restaurant
//                if (day == 1 || day == 7) && (hour > 8 && hour <= 14) {
//                    // Weekend Brunch
//                    tempPostType = "brunch"
//                } else
                if hour > 5 && hour <= 11 {
                    tempPostType = "breakfast"
                } else if hour > 11 && hour <= 15 {
                    tempPostType = "lunch"
                } else if hour > 15 && hour <= 22 {
                    tempPostType = "dinner"
                } else {
                    // Captures 11PM - 5AM The next day
                    tempPostType = "latenight"
                }
            } else if (googleLocationType.contains("bar")) {
                tempPostType = "drinks"
            } else if (googleLocationType.contains("cafe")) {
                tempPostType = "coffee"
            } else if (googleLocationType.contains("bakery")) {
                tempPostType = "dessert"
            } else if googleLocationType.count != nil && !(googleLocationType.contains("establishment")){
                tempPostType = "other"
            }
        } else {
            // Guess by Timing - No Google Type Location
//            if (day == 1 || day == 7) && (hour > 8 && hour <= 14) {
//                // Weekend Brunch
//                tempPostType = "brunch"
//            } else
            if hour > 5 && hour <= 11 {
                tempPostType = "breakfast"
            } else if hour > 11 && hour <= 15 {
                tempPostType = "lunch"
            } else if hour > 15 && hour <= 22 {
                tempPostType = "dinner"
            } else {
                // Captures 11PM - 5AM The next day
                tempPostType = "latenight"
            }
        }
        
        if tempPostType != nil, let emoji = mealEmojiDictionary.key(forValue: tempPostType!.lowercased()) {
            let mealTagEmoji = EmojiBasic(emoji: emoji, name: tempPostType, count: 0)
                completion(mealTagEmoji)
        } else {
            print("guessPostMeal | ERROR | No Emoji | \(googleLocationType) | \(currentTime) | \(tempPostType)")
            completion(nil)
        }
        
    }
    
    static func reverseGPSApple(GPSLocation: CLLocation?, completion: @escaping (Location?) -> ()){
        guard let GPSLocation = GPSLocation else {
            print("findLocationApple ERROR | No GPS Location")
            completion(nil)
            return
        }
        
        CLGeocoder().reverseGeocodeLocation(GPSLocation, completionHandler: {(placemarks, error)->Void in
            
            if (error != nil) {
                print("Reverse geocoder failed with error" + error!.localizedDescription)
                return
            }
            
            if placemarks!.count > 0 {
                let pm = placemarks![0]
                
                let testLocation = Location.init(locationPlaceMark: pm)
                completion(testLocation)
//                print("Apple Test |", testLocation.locationAdress)
//                print("Apple Test |", testLocation.locationSummaryID)
                
            } else {
                print("Problem with the data received from geocoder")
                completion(nil)
            }
        })

    }
    
//    public var name: String? { get } // eg. Apple Inc.
//    public var thoroughfare: String? { get } // street name, eg. Infinite Loop
//    public var subThoroughfare: String? { get } // eg. 1
//    public var locality: String? { get } // city, eg. Cupertino
//    public var subLocality: String? { get } // neighborhood, common name, eg. Mission District
//    public var administrativeArea: String? { get } // state, eg. CA
//    public var subAdministrativeArea: String? { get } // county, eg. Santa Clara
//    public var postalCode: String? { get } // zip code, eg. 95014
//    public var ISOcountryCode: String? { get } // eg. US
//    public var country: String? { get } // eg. United States
//    public var inlandWater: String? { get } // eg. Lake Tahoe
//    public var ocean: String? { get } // eg. Pacific Ocean
//    public var areasOfInterest: [String]? { get } // eg. Golden Gate Park
    
    static func reverseGPSGoogle(GPSLocation: CLLocation?, completion: @escaping (Location?) -> ()){

        guard let GPSLocation = GPSLocation else {
            print("Google Reverse GPS: ERROR, No GPS Location")
            return
        }
        
        if (GPSLocation.coordinate.latitude == 0) && (GPSLocation.coordinate.longitude == 0){
            print("Google Reverse GPS: ERROR, No GPS Location")
            return
        }
        
        let URL_Search = "https://maps.googleapis.com/maps/api/geocode/json?"
        let API_iOSKey = GoogleAPIKey()
        
        let urlString = "\(URL_Search)latlng=\(GPSLocation.coordinate.latitude),\(GPSLocation.coordinate.longitude)&key=\(API_iOSKey)"
        let url = URL(string: urlString)!
        
        //   https://maps.googleapis.com/maps/api/geocode/json?latlng=34.79,-111.76&key=AIzaSyAzwACZh50Qq1V5YYKpmfN21mZs8dW6210
        
        var temp = [String()]
        var locationGPStemp = [CLLocation()]
        
        
        AF.request(url).responseJSON { (response) -> Void in
            //           print(response)
            if let value  = response.value {
                let json = JSON(value)
                
                if let results = json["results"].array {
                    if results.count > 0 {
                        let test_loc = Location.init(googleLocationJSON: results[0])
                        completion(test_loc)
                    }
                }
            }
        }
    }
    
    
    static func searchNearbyGoogle(GPSLocation: CLLocation?, searchType: String?, completion: @escaping ([Location]?) -> ()){
        
        let defaultSearchType = "restaurant|bakery|cafe|bar|meal_delivery|meal_takeaway"
        var searchLocationType = searchType != nil ? searchType : defaultSearchType
        
        guard let location = GPSLocation else {
            print("searchNearbyGoogle ERROR | No GPS Location")
            completion(nil)
            return
        }
        var tempLocations: [Location] = []
        
        let URL_Search = "https://maps.googleapis.com/maps/api/place/search/json?"
        let API_iOSKey = GoogleAPIKey()
        
        var urlParameters = URLComponents(string: "https://maps.googleapis.com/maps/api/place/search/json?")!
        //        https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=41.973675,-87.667548&radius=1500&type=restaurant|cafe&key=AIzaSyAzwACZh50Qq1V5YYKpmfN21mZs8dW6210

        urlParameters.queryItems = [
            URLQueryItem(name: "location", value: "\(location.coordinate.latitude),\(location.coordinate.longitude)"),
            URLQueryItem(name: "rankby", value: "distance"),
            URLQueryItem(name: "type", value: "\(searchLocationType!)"),
            URLQueryItem(name: "key", value: "\(API_iOSKey)"),
        ]
        
//        print("GOOGLE URL | \(urlParameters.url!)")
        AF.request(urlParameters.url!).responseJSON { (response) -> Void in
            
            if let value  = response.value {
                let json = JSON(value)
                
                if let results = json["results"].array {
                    //                    print(results)
                    
                    let thisGroup = DispatchGroup()
                    for result in results {
                        tempLocations.append(Location.init(googleLocationJSON: result))
                    }
                    print("searchNearbyGoogle | \(location.coordinate) | \(searchLocationType) | \(tempLocations.count) Locations")
                    completion(tempLocations)
                }
            }
        }

    }
    
    static func queryGooglePlaceID(placeId: String?, completion: @escaping (JSON?) -> ()){
        guard let placeId = placeId else {
            completion(nil)
            return
        }
        
        let URL_Search = "https://maps.googleapis.com/maps/api/place/details/json?"
        let API_iOSKey = GoogleAPIKey()
        
        
        //        https://maps.googleapis.com/maps/api/place/details/json?placeid=ChIJbd2OryfY3IARR6800Hij7-Q&key=AIzaSyAzwACZh50Qq1V5YYKpmfN21mZs8dW6210
        
        let urlString = "\(URL_Search)placeid=\(placeId)&key=\(API_iOSKey)"
        let url = URL(string: urlString)!
//        print("Google Places URL: ",urlString)
        
        //        print("Place Cache for postid: ", placeId, placeCache[placeId])
        if let result = locationGoogleJSONCache[placeId] {
            //            print("Using Place Cache for placeId: ", placeId)
            completion(result)
        } else {
            
            AF.request(url).responseJSON { (response) -> Void in
                //                        print("Google Response: ",response)
                if let value  = response.value {
                    let json = JSON(value)
                    let result = json["result"]
                    
                    locationGoogleJSONCache[placeId] = result
                    completion(result)
                }
            }
        }
        
    }
    
    
    func mostFrequent<T: Hashable>(array: [T]) -> (value: T, count: Int)? {
        
        let counts = array.reduce(into: [:]) { $0[$1, default: 0] += 1 }
        
        if let (value, count) = counts.max(by: { $0.1 < $1.1 }) {
            return (value, count)
        }
        
        // array was empty
        return nil
    }
    
    static func centerManyLoc(locations: [CLLocation]) -> (CLLocationCoordinate2D?) {
        if locations.count == 0 {return nil}
        var maxLat = -200.0;
        var maxLong = -200.0;
        var minLat = 10000.0;
        var minLong = 10000.0;
        
        for templocation in locations {
            let location = templocation.coordinate
            
        
            if (location.latitude < minLat) {
                minLat = location.latitude;
            }
            
            if (location.longitude < minLong) {
                minLong = location.longitude;
            }
            
            if (location.latitude > maxLat) {
                maxLat = location.latitude;
            }
            
            if (location.longitude > maxLong) {
                maxLong = location.longitude;
            }
        }
        
        return CLLocationCoordinate2DMake((maxLat+minLat)/2, (maxLong+minLong)/2)
        
    }
    
    static func fetchImage(urlString: String?, completion: @escaping (UIImage?) -> ()){
        guard let urlString = urlString else {
            completion(nil)
            return}
        guard let url = URL(string: urlString) else {
            completion(nil)
            return}
        
        if let image = imageCache[urlString] {
            completion(image)
        } else {
            URLSession.shared.dataTask(with: url) { (data, response, err) in
                if let err = err {
                    print("Failed to fetch post image:", err)
                    completion(nil)
                    return
                }
                
                guard let imageData = data else {
                    completion(nil)
                    return}
                
                let photoImage = UIImage(data: imageData)?.resizeVI(newSize: defaultPhotoResize)
                
                imageCache[url.absoluteString] = photoImage
                
                DispatchQueue.main.async {
                    completion(photoImage)
                }
                
                }.resume()
        }
        

        
    }
    
    static func updatePostSmallImages(postId: String?, completion: @escaping (String?) -> ()){
        print("Fixing Image | \(postId)")
        guard let postId = postId else {return}
        
        Database.fetchPostWithPostID(postId: postId) { (post, error) in
            guard let imageUrls = post?.imageUrls else {return}
            if imageUrls.count > 0 {
                guard let url = URL(string: imageUrls[0]) else {return}
                URLSession.shared.dataTask(with: url) { (data, response, err) in
                    if let err = err {
                        print("Failed to fetch post image:", err)
                        return
                    }
                    guard let imageData = data else {return}
                    let smallPhotoSize = CGSize(width: 50, height: 50)
                    guard let photoImage = UIImage(data: imageData)?.resizeVI(newSize: smallPhotoSize) else {return}
                    let photoArray = [photoImage]
                    
                    guard let image = UIImage(data: imageData) else {return}
                    //                        Database.printImageSizes(image: image)
                    
                    DispatchQueue.main.async {
                        
                        Database.saveImageToDatabase(uploadImages: photoArray, smallImage: false, completion: { (urlArray, smallImageUrl) in
                            let postRef = Database.database().reference().child("posts").child(postId)
                            postRef.runTransactionBlock({ (currentData) -> TransactionResult in
                                guard let post = currentData.value as? [String : AnyObject] else {
                                    print(" ! Post Social Update Error: No Post", postId)
                                    return TransactionResult.abort()
                                }
                                
                                let tempUrl = urlArray[0]
                                var temp_post = post
                                temp_post["smallImageLink"] = tempUrl as AnyObject
                                currentData.value = temp_post
                                print("updatePostSmallImages | SUCCESS | \(postId) smallImageLink: \(tempUrl)")
                                completion(tempUrl)
                                return TransactionResult.success(withValue: currentData)
                                
                            }) { (error, committed, snapshot) in
                                if let error = error {
                                    print("updatePostSmallImages | ERROR | \(postId) | \(error)")
                                }
                            }
                        })
                    }
                    
                    }.resume()
            }
        }
    }
    
    static func getAssetThumbnail(asset: PHAsset) -> UIImage {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        option.resizeMode = .exact
        option.deliveryMode = .highQualityFormat;
        option.isNetworkAccessAllowed = true;
        option.progressHandler = { (progress, error, stop, info) in
            if(progress == 1.0){
                SVProgressHUD.dismiss()
            } else {
                SVProgressHUD.showProgress(Float(progress), status: "Downloading from iCloud")
            }
        }
        var thumbnail = UIImage()
        option.isSynchronous = true
        manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
            thumbnail = result!
        })
        return thumbnail
        
    }
    
    static func processPHAssets(assets: [PHAsset], completion: @escaping ([UIImage]?, CLLocation?, Date?) -> ()){
        
        // use selected order, fullresolution image
        print("Processing \(assets.count) PHAssets")
        
        var assetlocations: [CLLocation?] = []
        var assetTimes:[Date?] = []
        
        var tempImages: [UIImage]? = []
        var tempLocation: CLLocation? = nil
        var tempDate: Date? = nil
        
        for asset in assets {
            tempImages?.append(self.getAssetThumbnail(asset: asset))
            assetlocations.append(asset.location)
            assetTimes.append(asset.creationDate)
            
            var image = self.getAssetThumbnail(asset: asset)
            
            
        }
        
        for location in assetlocations {
            if tempLocation == nil {
                if location != nil {
                    tempLocation = location
                }
            }
        }
        
        for time in assetTimes {
            if tempDate == nil {
                if time != nil {
                    tempDate = time
                }
            }
        }
        
        print("Images: \(tempImages?.count), Locations: \(assetlocations.count), Times: \(assetTimes) ")
        print("Final Location: \(tempLocation), Final Time: \(tempDate)")
        
        completion(tempImages, tempLocation, tempDate)
        
        // print("Selected Photo Time \(self.selectedTime), Location: \(self.selectedPhotoLocation)")
        
    }
    
    
// SUBSCRIPTIONS
    static func createSubscription(transactionId:String?, buyerId: String?, sellerId: String?, price: Double? = 0.0, subPeriod: SubPeriod?, isPremium: Bool = false, completion: @escaping (Subscription?) -> ()){
        guard let transactionId = transactionId else {self.alert(title: "Purchase ERROR", message: "No Transaction ID")
            return}
        guard let buyerId = buyerId else {self.alert(title: "Purchase ERROR", message: "No purchaserId")
            return}
        guard let subPeriod = subPeriod else {self.alert(title: "Purchase ERROR", message: "No SubPeriod")
            return}

        let subRef = Database.database().reference().child("transactions").child(transactionId)
        
        var uploadValues:[String:Any] = [:]
        uploadValues["buyerUID"] = buyerId
        uploadValues["price"] = price

    // DATES
        let buyDate = Date().timeIntervalSince1970
        var dateComponent = DateComponents()
        if subPeriod == .annual {
            dateComponent.year = 1
            uploadValues["subPeriod"] = "annual"
        } else if subPeriod == .monthly{
            dateComponent.month = 1
            uploadValues["subPeriod"] = "monthly"
        }
        
        let expDate = Calendar.current.date(byAdding: dateComponent, to: Date())
        uploadValues["purchaseDate"] = buyDate
        uploadValues["expiryDate"] = expDate?.timeIntervalSince1970


        if isPremium {
            // Legit Premium Subscription
            uploadValues["premiumSub"] = true
            uploadValues["isRenewable"] = expDate
        } else if sellerId != nil {
            // Content Creator Subscription
            uploadValues["sellerId"] = sellerId
        }
        
        // SAVE EDITED POST IN POST DATABASE
        subRef.updateChildValues(uploadValues) { (err, ref) in
            if let err = err {
                print("Transaction: ERROR: \(transactionId)", err)
                return}
            
            print("Transaction SUCCESS: \(transactionId) \(price) \(isPremium) Buyer: \(buyerId) Seller:  \(sellerId) \(price) \(Date()) \(expDate)")
            
            let tempSub = Subscription.init(transactionId: transactionId, dictionary: uploadValues)
            completion(tempSub)
        }
        
    }
    
    // SUBSCRIPTIONS
    static func updateSeller(subscription: Subscription){
        guard let sellerId = subscription.sellerUID else {self.alert(title: "updateSubscribed ERROR", message: "No subscribedId")
            return}
        guard let buyerId = subscription.buyerUID else {self.alert(title: "updateSubscribed ERROR", message: "No purchaserUID")
            return}
        
//        SELLERS
//            > TOTAL REV
//            > TOTAL SUBS
//            > SUBS
//                > ISACTIVE
//                > EXPIRY
//                > TRANSACTIONS

        let subRef = Database.database().reference().child("subscription_sellers").child(sellerId)
            
            subRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                var user = currentData.value as? [String : AnyObject] ?? [:]
                let subDate = subscription.purchaseDate.timeIntervalSince1970
                let subExpiry = subscription.expiryDate.timeIntervalSince1970
                let subPrice = subscription.price
                var newTransaction = false
            // USER SUBS
                var subs = user["subs"] as? [String : AnyObject] ?? [:]
                var userDetails = [:] as [String : AnyObject]

                // TRANSACTIONS
                    var transactions = user["transactions"] as? [String: Double] ?? [:]
                    if transactions[subscription.id] == nil {
                        transactions[subscription.id] = subDate
                        user["transactions"] = transactions as AnyObject
                    }
                
                
                if subs[buyerId] == nil {
                    var transactions: [String: Double] = [:]
                    transactions[subscription.id] = subDate
                    userDetails["transactions"] = transactions as AnyObject
                    userDetails["expiryDate"] = subExpiry as AnyObject
                    userDetails["isActive"] = (subExpiry > Date().timeIntervalSince1970) as AnyObject
                    newTransaction = true
                } else {
                    userDetails = subs[buyerId] as? [String : AnyObject] ?? [:]
                    var transactions = userDetails["transactions"] as? [String: Double] ?? [:]
                    if transactions[subscription.id] == nil {
                        transactions[subscription.id] = subDate
                        userDetails["transactions"] = transactions as AnyObject
                        newTransaction = true
                    }
                    
                    var exp = userDetails["expiryDate"] as? Double ?? 0
                    if subExpiry > exp {
                        userDetails["expiryDate"] = subExpiry as AnyObject
                    }
                    userDetails["isActive"] = (subExpiry > Date().timeIntervalSince1970) as AnyObject
                }
                subs[buyerId] = userDetails as AnyObject
                user["subs"]  = subs as AnyObject
                
                var activeCount = 0
                for sub in subs {
                    let tempSub = sub as? [String : AnyObject] ?? [:]
                    let isActive = tempSub["isActive"] as? Bool ?? false
                    activeCount += isActive ? 1 : 0
                }
                user["activeCount"] = activeCount as AnyObject
                    
                var totalRev = user["totalRev"] as? Double ?? 0.0
                totalRev += newTransaction ? subPrice : 0
                user["totalRev"] = totalRev as AnyObject

                // Set value and report transaction success
                currentData.value = user
                print("Successfully Update Seller \(sellerId) | \(subscription.id)) | \(activeCount) Active Subs | \(totalRev) Total Rev")
                return TransactionResult.success(withValue: currentData)
                
            }) { (error, committed, snapshot) in
                if let error = error {
                    print("FAILURE Update Seller \(sellerId) | \(subscription.id))")
                    print(error.localizedDescription)
                }
            }
        
        }
    
    // SUBSCRIPTIONS
    static func updateBuyerUser(subscription: Subscription?){
            guard let subscription = subscription else {self.alert(title: "updateSubscriber ERROR", message: "No subscription")
                return}
            guard let buyerId = subscription.buyerUID else {self.alert(title: "updateSubscribed ERROR", message: "No purchaserUID")
                return}
            guard let sellerId = subscription.sellerUID else {self.alert(title: "updateSubscribed ERROR", message: "No purchaserUID")
                return}

//        BUYERS
//            > SUB SELLER
//                > ISACTIVE
//                > EXPIRY
//                > TRANSACTIONS
        
        
            let subRef = Database.database().reference().child("subscription_buyers").child(buyerId).child(sellerId)
            subRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                var user = currentData.value as? [String : AnyObject] ?? [:]
                var subDate = subscription.expiryDate.timeIntervalSince1970

            // TRANSACTIONS
                var transactions = user["transactions"] as? [String: Double] ?? [:]
                if transactions[subscription.id] == nil {
                    transactions[subscription.id] = subDate
                    user["transactions"] = transactions as AnyObject
                }
                
            // EXPIRY
                var expiry = user["expiryDate"] as? Double ?? 0
                if subDate > expiry {
                    expiry = subDate
                }
                user["expiryDate"] = expiry as AnyObject

            // IS ACTIVE
                var isActive = user["isActive"] as? Bool ?? false
                isActive = expiry > Date().timeIntervalSince1970
                user["isActive"] = isActive as AnyObject
                
                // Set value and report transaction success
                currentData.value = user
                print("Successfully Update Buyer \(buyerId) | Seller: \(sellerId) | \(subscription.id)) | Active: \(isActive) | Expire \(Date(timeIntervalSince1970: expiry))")
                return TransactionResult.success(withValue: currentData)
                
            }) { (error, committed, snapshot) in
                if let error = error {
                    print("updateBuyerUser FAIL | Buyer: \(buyerId) | Seller: \(sellerId) | Sub: \(subscription.id)")
                    print(error.localizedDescription)
                }
            }
        
        }
    
    
    // PREMIUM SUBSCRIPTIONS
        static func createPremiumSubscription(transactionId:String?, buyerId: String?, price: Double? = 0.0, subPeriod: SubPeriod?, isPremium: Bool = false, completion: @escaping (Subscription?) -> ()){
            guard let transactionId = transactionId else {self.alert(title: "Purchase ERROR", message: "No Transaction ID")
                return}
            guard let buyerId = buyerId else {self.alert(title: "Purchase ERROR", message: "No purchaserId")
                return}
            guard let subPeriod = subPeriod else {self.alert(title: "Purchase ERROR", message: "No SubPeriod")
                return}

            let subRef = Database.database().reference().child("premium_transactions").child(transactionId)
            
            var uploadValues:[String:Any] = [:]
            uploadValues["buyerUID"] = buyerId
            uploadValues["price"] = price

        // DATES
            let buyDate = Date().timeIntervalSince1970
            var dateComponent = DateComponents()
            if subPeriod == .annual {
                dateComponent.year = 1
                uploadValues["subPeriod"] = "annual"
            } else if subPeriod == .monthly{
                dateComponent.month = 1
                uploadValues["subPeriod"] = "monthly"
            }
            
            let expDate = Calendar.current.date(byAdding: dateComponent, to: Date())
            uploadValues["purchaseDate"] = buyDate
            uploadValues["expiryDate"] = expDate?.timeIntervalSince1970


            // Legit Premium Subscription
            uploadValues["premiumSub"] = true
            uploadValues["isRenewable"] = true
            
            // SAVE EDITED POST IN POST DATABASE
            subRef.updateChildValues(uploadValues) { (err, ref) in
                if let err = err {
                    print("Transaction: ERROR: \(transactionId)", err)
                    return}
                
                print("Transaction SUCCESS: \(transactionId) \(price) \(isPremium) Buyer: \(buyerId) \(price) \(Date()) \(expDate)")
                
                let tempSub = Subscription.init(transactionId: transactionId, dictionary: uploadValues)
                completion(tempSub)
            }
            
        }
        
    
    // SUBSCRIPTIONS
    static func premiumUserSignUp(subscription: Subscription?){
        guard let subscription = subscription else {self.alert(title: "updateSubscriber ERROR", message: "No subscription")
            return}
        guard let buyerId = subscription.buyerUID else {self.alert(title: "updateSubscribed ERROR", message: "No purchaserUID")
            return}

    
        if !subscription.premiumSub {
            print("ERROR -  Not Premium Sub ", subscription.id, buyerId, subscription.premiumSub)
            return
        }

//        SUBSCRIPTION
//            > USER
//                > ISACTIVE
//                > EXPIRY
//                > TRANSACTIONS
    
    
        let subRef = Database.database().reference().child("premium").child(buyerId)
        subRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            var user = currentData.value as? [String : AnyObject] ?? [:]
            let subBuyDate = subscription.purchaseDate.timeIntervalSince1970

        // TRANSACTIONS
            var transactions = user["transactions"] as? [String: Double] ?? [:]
            if transactions[subscription.id] == nil {
                transactions[subscription.id] = subBuyDate
                user["transactions"] = transactions as AnyObject
            }
            
            user["purchaseDate"] = subBuyDate as AnyObject
            
            var firstPurchaseDate = user["firstPurchaseDate"] as? Double ?? 0
            if firstPurchaseDate == 0 {
                user["firstPurchaseDate"] = subBuyDate as AnyObject
            }
            
        // EXPIRY
            var expiry = user["expiryDate"] as? Double ?? 0
            var subDate = subscription.expiryDate.timeIntervalSince1970
            if subDate > expiry {
                expiry = subDate
            }
            user["expiryDate"] = expiry as AnyObject

        // IS ACTIVE
            var isActive = user["isActive"] as? Bool ?? false
            user["isActive"] = (subscription.expiryDate > Date()) as AnyObject
             
            var subPeriod = user["subPeriod"] as? String ?? ""
            if subscription.subPeriod == SubPeriod.monthly {
                subPeriod = "monthly"
            } else if subscription.subPeriod == SubPeriod.annual {
                subPeriod = "annual"
            }
            user["subPeriod"] = subPeriod as AnyObject
            
            // Set value and report transaction success
            currentData.value = user
            print("Successfully Update Premium Buy for \(buyerId) | \(subscription.id)) | | Expire \(Date(timeIntervalSince1970: expiry))")
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print("FAIL Premium Buy for \(buyerId) | \(subscription.id))")
                print(error.localizedDescription)
            } else {
                premiumUserDatabaseUpdate(subscription: subscription)
                print("Update Current User Premium Status")
            }
        }
    }
    
    static func premiumUserDatabaseUpdate(subscription: Subscription?){
        guard let subscription = subscription else {self.alert(title: "updateSubscriber ERROR", message: "No subscription")
            return}
        guard let buyerId = subscription.buyerUID else {self.alert(title: "updateSubscribed ERROR", message: "No purchaserUID")
            return}

    
        if !subscription.premiumSub {
            print("ERROR -  Not Premium Sub ", subscription.id, buyerId, subscription.premiumSub)
            return
        }

//        SUBSCRIPTION
//            > USER
//                > premiumActive
//                > premiumStart
//                > premiumExpiry
//                > premiumPeriod
    
    
        let subRef = Database.database().reference().child("users").child(buyerId)
        subRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            var user = currentData.value as? [String : AnyObject] ?? [:]
            let subBuyDate = subscription.purchaseDate.timeIntervalSince1970

        // EXPIRY
            var expiry = user["premiumExpiry"] as? Double ?? 0
            var subDate = subscription.expiryDate.timeIntervalSince1970
            if subDate > expiry {
                expiry = subDate
                user["premiumExpiry"] = expiry as AnyObject
            }
            
            
            var premiumStartDate = user["premiumStart"] as? Double ?? 0
            if premiumStartDate == 0 {
                user["premiumStart"] = subBuyDate as AnyObject
            }
            
        
        // IS ACTIVE
            var isActive = user["isPremium"] as? Bool ?? false
            isActive = expiry > Date().timeIntervalSince1970
            user["isPremium"] = isActive as AnyObject
            
            var subPeriod = user["premiumPeriod"] as? String ?? ""
            if subscription.subPeriod == SubPeriod.monthly {
                subPeriod = "monthly"
            } else if subscription.subPeriod == SubPeriod.annual {
                subPeriod = "annual"
            }
            user["premiumPeriod"] = subPeriod as AnyObject
            
            // Set value and report transaction success
            currentData.value = user
            print("Successfully Update Premium User in User Database for \(buyerId) | \(subscription.id)) | Active: \(isActive) | Expire \(Date(timeIntervalSince1970: expiry))")
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print("FAIL Premium User Database Update for \(buyerId) | \(subscription.id))")
                print(error.localizedDescription)
            } else {
                CurrentUser.isPremium = true
                CurrentUser.premiumPeriod = subscription.subPeriod
                CurrentUser.premiumExpiry = subscription.expiryDate
                if CurrentUser.premiumStart == nil {
                    CurrentUser.premiumStart = subscription.purchaseDate
                }
                NotificationCenter.default.post(name: SubscriptionViewController.newSubNotification, object: nil)
                print("Update Current User Premium Status")
            }
        }
    }
    
    static func updatePremiumUserDatabase(uid: String?, cancel: Bool? = false, activate: Bool? = false, expiryDate: Date? = nil, premSub: SubPeriod? = nil, premFree: Bool? = false, force: Bool = false){
        guard let uid = uid else {
            print("Cancel Premium User Fail - No UID")
            return}
    
        if !force {
            if cancel == false && activate == false && expiryDate == nil && premSub == nil {
                print("No Changes")
                return
            }
        }
        
        let subRef = Database.database().reference().child("users").child(uid)
        subRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            var user = currentData.value as? [String : AnyObject] ?? [:]

            var expiry = user["premiumExpiry"] as? Double ?? 0
            var subDate = Date.init(timeIntervalSince1970: expiry)
            if expiryDate != nil {
                user["premiumExpiry"] = expiryDate?.timeIntervalSince1970 as AnyObject
                print("Force Update Expiry Date \(expiryDate) from \(subDate)")
            }
            
            var subPeriod = user["premiumPeriod"] as? String ?? ""
            if premSub != nil {
                print("Force Update Prem Period \(premSub) from \(subPeriod)")

                if premSub == SubPeriod.monthly {
                    subPeriod = "monthly"
                } else if premSub == SubPeriod.annual {
                    subPeriod = "annual"
                }
                user["premiumPeriod"] = subPeriod as AnyObject
            }
            
        // IS ACTIVE
            if cancel ?? false {
                // FORCE CANCEL
                user["isPremium"] = false as AnyObject
                user["premiumCancel"] = Date().timeIntervalSince1970 as AnyObject
                print("Force Cancel Premium \(uid)")
            }
            else if activate ?? false {
                user["isPremium"] = true as AnyObject
                user["premiumActivate"] = Date().timeIntervalSince1970 as AnyObject
                if premFree ?? false {
                    user["premiumPeriod"] = "annual" as AnyObject
                    user["premiumExpiry"] = 0 as AnyObject
                }
                print("Force Activate Premium \(uid)")
            }
            else {
                // CHECK EXPIRY DATE IF STILL ACTIVE
                let premExp = user["premiumExpiry"] as? Double ?? 0
                if premExp > 0 {
                    var isActive = (Date(timeIntervalSince1970: premExp) > Date())
                    user["isPremium"] = (Date(timeIntervalSince1970: premExp) > Date()) as AnyObject
                    if !isActive {
                        print("Premium Expired \(uid) \(Date(timeIntervalSince1970: premExp))")
                    }
                } else {
                    user["isPremium"] = false as AnyObject
                }
            }
            
            // Set value and report transaction success
            currentData.value = user
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print("FAIL Update Premium User in User Database for \(uid)) | Cancel \(cancel) | Activate \(activate) | expiryDate \(expiryDate)")
                print(error.localizedDescription)
            } else {
                print("Successfully Update Premium User in User Database for \(uid)) | Cancel \(cancel) | Activate \(activate) | expiryDate \(expiryDate)")
                if uid == Auth.auth().currentUser?.uid {
                    if activate ?? false {
                        CurrentUser.user?.isPremium = true
                        CurrentUser.isPremium = true
                    } else if cancel ?? false {
                        CurrentUser.user?.isPremium = false
                        CurrentUser.isPremium = false
                    }
                    
                    if expiryDate != nil {
                        CurrentUser.user?.premiumExpiry = expiryDate
                        CurrentUser.premiumExpiry = expiryDate
                    }
                    
                    if premSub != nil {
                        CurrentUser.user?.premiumPeriod = premSub
                        CurrentUser.premiumPeriod = premSub
                    }
                }
                print("updatePremiumUserDatabase | Final Current User | Premium \(CurrentUser.isPremium) | Expiry \(CurrentUser.premiumExpiry) | SubType \(CurrentUser.premiumPeriod)")
                
            }
        }
        
        let premRef = Database.database().reference().child("premium").child(uid)
        premRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            var user = currentData.value as? [String : AnyObject] ?? [:]
            
            var expiry = user["expiryDate"] as? Double ?? 0
            var subDate = Date.init(timeIntervalSince1970: expiry)
            if expiryDate != nil {
                user["expiryDate"] = expiryDate?.timeIntervalSince1970 as AnyObject
                print("Force Update Expiry Date \(expiryDate) from \(subDate)")
            }
            
            var subPeriod = user["subPeriod"] as? String ?? ""
            if premSub != nil {
                if premSub == SubPeriod.monthly {
                    subPeriod = "monthly"
                } else if premSub == SubPeriod.annual {
                    subPeriod = "annual"
                }
                user["subPeriod"] = subPeriod as AnyObject
            }
            
        // IS ACTIVE
            if cancel ?? false {
                // FORCE CANCEL
                user["isActive"] = false as AnyObject
                user["cancelDate"] = Date().timeIntervalSince1970 as AnyObject
                print("Force Cancel Premium \(uid)")
            }
            else if activate ?? false {
                user["isActive"] = true as AnyObject
                user["activateDate"] = Date().timeIntervalSince1970 as AnyObject
                print("Force Activate Premium \(uid)")
                if premFree ?? false {
                    user["subPeriod"] = "annual" as AnyObject
                    user["expiryDate"] = 0 as AnyObject
                }
            }
            else {
                // CHECK IF STILL ACTIVE
                let premExp = user["expiryDate"] as? Double ?? 0
                if premExp > 0 {
                    var isActive = (Date(timeIntervalSince1970: premExp) > Date())
                    user["isActive"] = (Date(timeIntervalSince1970: premExp) > Date()) as AnyObject
                    if !isActive {
                        print("Premium Expired \(uid) \(Date(timeIntervalSince1970: premExp))")
                    }
                } else {
                    user["isActive"] = false as AnyObject
                }
            }
            
            // Set value and report transaction success
            currentData.value = user
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print("FAIL Update Premium User in Premium Database for \(uid)) | Cancel \(cancel) | Activate \(activate) | expiryDate \(expiryDate)")
                print(error.localizedDescription)
            } else {
//                CurrentUser.isPremium = true
                print("Successfully Update Premium User in Premium Database for \(uid)) | Cancel \(cancel) | Activate \(activate) | expiryDate \(expiryDate)")
            }
        }
        
    }
    
    // SUBSCRIPTIONS
    static func fetchPremiumUser(uid: String?, completion: @escaping (Subscription) -> ()){
        guard let uid = uid else {self.alert(title: "fetchPremiumUser ERROR", message: "No UID")
            return}
        
        
//        PREMIUM
//            > UID
//                > ISACTIVE
//                > FIRSTPURCHASEDATE
//                > PURCHASEDATE
//                > EXPIRY
//                > TRANSACTIONS
    
    
        let subRef = Database.database().reference().child("premium").child(uid)
        subRef.observeSingleEvent(of: .value, with: {(snapshot) in
            var user = snapshot.value as? [String : AnyObject] ?? [:]
            var sub = Subscription.init(transactionId: nil, dictionary: user)
            sub.premiumSub = true
            print("fetchPremiumUser SUCCESS: \(uid) , Active: \(sub.isActive) , \(sub.id)")
            completion(sub)
        })
    }
    
    static func checkPremiumStatus() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        if CurrentUser.isPremiumFree && CurrentUser.isPremium {
            print("Free Premium User \(CurrentUser.username) | checkPremiumStatus")
            return
        }
        Purchases.shared.getCustomerInfo { (info, error) in
        // Check for current Premium Status
            var activate = false
            var cancel = false
            var expiryDate: Date? = nil
            var premSub: SubPeriod? = nil
            var premFree = false

            var isPremActive = info?.entitlements["premium"]?.isActive
            var expDate = info?.entitlements["premium"]?.expirationDate
            var subType = info?.entitlements["premium"]?.productIdentifier

            print("RevenueCat | isPremActive \(isPremActive) | subType \(subType) | expDate \(expDate)")
            
            if isPremActive != CurrentUser.isPremium {
                if CurrentUser.isPremiumFree && CurrentUser.isPremium {
                    print("Free Premium User \(CurrentUser.username) | checkPremiumStatus")
                } else if CurrentUser.isPremiumFree && !CurrentUser.isPremium {
                    activate = true
                    premFree = true
                    print("ACTIVATE Free Premium User \(CurrentUser.username) | checkPremiumStatus")
                }
                else if isPremActive == nil && CurrentUser.isPremium == true {
                    cancel = true
                    print("USER MISSING PREMIUM REV CAT = \(uid) | RevCat \(isPremActive) | Database \(CurrentUser.isPremium)")
                }
                else if isPremActive == false && CurrentUser.isPremium == true {
                    cancel = true
                    print("USER CANCEL PREMIUM REV CAT = \(uid) | RevCat \(isPremActive) | Database \(CurrentUser.isPremium)")
                } else if isPremActive == true && CurrentUser.isPremium == false {
                    activate = true
                    print("USER IS PREMIUM REV CAT BUT NOT IN DATABASE = \(uid) | RevCat \(isPremActive) | Database \(CurrentUser.isPremium)")
                }
            }
            
        // CHECK EXP DATE
            if expDate != nil {
                if CurrentUser.premiumExpiry != expDate {
                    expiryDate = expDate
                }
            }
            
        // CHECK PREM TYPE
            if subType == "legit_premium_annual" && CurrentUser.premiumPeriod != .annual {
                premSub = .annual
                print("Need To Update Sub Type | RevCat \(subType) | Current \(CurrentUser.premiumPeriod)")
            } else if subType == "legit_premium_monthly" && CurrentUser.premiumPeriod != .monthly {
                premSub = .monthly
                print("Need To Update Sub Type | RevCat \(subType) | Current \(CurrentUser.premiumPeriod)")
            }
            
            if cancel || activate || expiryDate != nil || premSub != nil {
                print("checkPremiumStatus | \(CurrentUser.username)) Need Update | Cancel \(cancel) | Activate \(activate) | expiryDate \(expiryDate) | premSub \(premSub)")
                updatePremiumUserDatabase(uid: uid, cancel: cancel, activate: activate, expiryDate: expiryDate, premSub: premSub, premFree: premFree)
            } else {
                print("checkPremiumStatus \(CurrentUser.username)| OK")
            }
        }
    }
    
    static func filterCaptionForEmoji(inputText: String?, completion: @escaping ([String]) -> ()){
        guard let inputText = inputText else {
            completion([])
            return
        }
        
        var outputEmojis:[String] = []
        
        // Split up words
        var tempSingleCaptionWords = inputText.lowercased().components(separatedBy: " ")
        if tempSingleCaptionWords.count == 0 {
            completion([])
            return
        }
        
        // Detect Emojis in String
        if inputText.emojis.count > 0 {
            for emoji in inputText.emojis {
                if emoji != "" && !emoji.isEmptyOrWhitespace() {
                    outputEmojis.append(emoji)
                }
            }
        }
        
        
        // Format Caption Word to only be alpha numeric
        for (index, word) in tempSingleCaptionWords.enumerated() {
            tempSingleCaptionWords[index] = word.alphaNumericOnly()
        }
        
        // Create Double Word Combinations for all words to capture 2 word maps (eg: Pad Thai)
        var tempDoubleCaptionWords: [String] = []
        if tempSingleCaptionWords.count > 1 {
            for i in (1...tempSingleCaptionWords.count-1) {
                let joinedWord = tempSingleCaptionWords[i-1] + " " + tempSingleCaptionWords[i]
                    tempDoubleCaptionWords.append(joinedWord)
            }
        }
        
        var tempAllLookUpWords = tempDoubleCaptionWords + tempSingleCaptionWords

        for word in tempAllLookUpWords {
            // Look up Emoji based on word
            if let tempEmoji = ReverseEmojiDictionary[word] {
                if !outputEmojis.contains(tempEmoji){
                    outputEmojis.append(tempEmoji)
                }
            }

            // Look up Emoji based on word without s at the end
            if word.suffix(1) == "s" {
                if let tempEmoji = ReverseEmojiDictionary[String(word.dropLast())] {
                    if !outputEmojis.contains(tempEmoji){
                        outputEmojis.append(tempEmoji)
                    }
                }
            }
        }
        
        // Clear Blanks
        outputEmojis.removeAll { String in
            return String.isEmptyOrWhitespace()
        }
                
        completion(outputEmojis)
        
        
    }
    
    static func appendEmojis(currentEmojis: [String]?, newEmojis: [String]?) -> [String]{
        var tempEmojis: [String] = []
        var tempCurrentEmojis = currentEmojis ?? []
        var tempNewEmojis = newEmojis ?? []
        
        tempEmojis = tempCurrentEmojis
        
        for emoji in tempNewEmojis {
            if !tempEmojis.contains(emoji){
                tempEmojis.append(emoji)
            }
        }
        
        return tempEmojis
    }
    

    static func saveAPNTokenForUser(userId: String?, token: String?){
        guard let userId = userId else {
            print("ERROR: No userId: saveTokenForUser")
            return}
        guard let token = token else {
            print("ERROR: No userId: saveTokenForUser")
            return}

        print("Updating Token \(token) for \(userId)")
        let dbRef = Database.database().reference().child("users").child(userId).child("APNTokens")

        dbRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            var tokens = currentData.value as? [String : AnyObject] ?? [:]
            var curToken = tokens[token] as! Bool?
            if (curToken == nil || curToken == false)  {
                tokens[token] = true as AnyObject
                currentData.value = tokens
                return TransactionResult.success(withValue: currentData)
            } else {
                print("Token \(token) already exist for \(userId)")
                return TransactionResult.abort()
            }
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("Success: Updated Token \(token) for \(userId)")
                if userId == CurrentUser.uid {
                    CurrentUser.addAPNToken(token: token)
                }
            }
        }
    }
    
    static func deleteAPNTokenForUser(userId: String?, token: String?){
        guard let userId = userId else {
            print("ERROR: No userId: deleteAPNTokenForUser")
            return}
        guard let token = token else {
            print("ERROR: No userId: deleteAPNTokenForUser")
            return}

        print("Delete Token \(token) for \(userId)")
        let dbRef = Database.database().reference().child("users").child(userId).child("APNTokens")

        dbRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            var tokens = currentData.value as? [String : AnyObject] ?? [:]
            var curToken = tokens[token] as! Bool?
            if (curToken == true)  {
                tokens.removeValue(forKey: token)
                currentData.value = tokens
                return TransactionResult.success(withValue: currentData)
            } else {
                print("Token \(token) already deleted for \(userId)")
                return TransactionResult.abort()
            }
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("Success: Deleted Token \(token) for \(userId)")
            }
        }
    }
    
    static func sendPushNotification(uid: String, title: String, body: String, action: String?) {
        print("sendPushNotification \(action) \(uid) \(title)")
        self.fetchUserWithUID(uid: uid) { user in
            guard let user = user else {
                print("NO USER ",uid, " | sendPushNotification")
                return}
            
            self.sendPushNotification(uid:uid, tokens: user.APNTokens, title: title, body: body, action: action)

        }
    }
    
    static func sendPushNotification(uid: String, tokens: [String], title: String, body: String, action: String?) {
        for token in tokens {
            self.sendPushNotification(uid: uid, token: token, title: title, body: body, action: action)
        }
    }
    
    
    static func sendPushNotification(uid: String, token: String, title: String, body: String, action: String?) {
        let urlString = "https://fcm.googleapis.com/fcm/send"
        let url = NSURL(string: urlString)!
        let paramString: [String : Any] = ["to" : token,
                                           "notification" : ["title" : title, "body" : body, "click_action" : action],
                                           "data" : ["user" : "test_id"]
        ]
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=AAAApVhfkaE:APA91bFLVmlhGvFUTjJbOBwz9r_tqSq5o3z2byidiFZM4-Eog7U2tj96MQRQ6sVwX8QNacnwr-Hv_1uX46FmcAMKtCPP-n1ekUIu4qHD3gbUX0bWVIbnfLJ7_p2Pz_iS6eId3Ps_IGec", forHTTPHeaderField: "Authorization")
        let task =  URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in
            do {
                if let jsonData = data {
                    if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                        NSLog("Received data:\n\(jsonDataDict))")
                        if JSON(rawValue: jsonDataDict["success"]!) == 1 {
                            print("Success sendPushNotification \(uid) ; \(token) ; \(title) ; \(body)")
                        } else if JSON(rawValue: jsonDataDict["failure"]!) == 1 {
                            let json = JSON(jsonDataDict["results"])
                            let result = json.array?[0] ?? []
                            if result["error"] == "InvalidRegistration" || result["error"] == "NotRegistered" {
                                print("InvalidRegistration | Remove token \(token) from uid \(uid)")
                                self.deleteAPNTokenForUser(userId: uid, token: token)
                            }
                            print("Failure sendPushNotification \(uid) ; \(token) ; \(title) ; \(body) | \(result["error"])")
                        }
                    }
                }
            } catch let err as NSError {
                print(err.debugDescription)
            }
        }
        task.resume()
    }
    
    static func countryName(from countryCode: String) -> String {
        if let name = (Locale.current as NSLocale).displayName(forKey: .countryCode, value: countryCode) {
            // Country name was found
            return name
        } else {
            // Country name cannot be found
            return countryCode
        }
    }

    
//    static func printImageSizes(image: UIImage){
////            var fullimg: NSData = NSData(data: UIImageJPEGRepresentation(image, 1)!)
//        
//            guard let fullimg = image.jpegData(compressionQuality: 1) else {return}
//            print("Full IMG: ",Double(fullimg.count)/1024.0, image.size)
//        
//            guard let full90 = image.jpegData(compressionQuality: 0.9) else {return}
//            print("90 IMG: ",Double(full90.count)/1024.0)
//
//            guard let full80 = image.jpegData(compressionQuality: 0.8) else {return}
//            print("80 IMG: ",Double(full80.count)/1024.0)
//        
//            guard let full50 = image.jpegData(compressionQuality: 0.5) else {return}
//            print("50 IMG: ",Double(full50.count)/1024.0)
//        
//            guard let full25 = image.jpegData(compressionQuality: 0.25) else {return}
//            print("25 IMG: ",Double(full25.count)/1024.0)
//
//            let PhotoSize100 = CGSize(width: 100, height: 100)
//            guard let viimg100 = image.resizeVI(newSize: PhotoSize100) else {return}
//            guard let img100 = viimg100.jpegData(compressionQuality: 1) else {return}
//            print("VIResize IMG: ",Double(img100.count)/1024.0, viimg100.size)
//
//            let PhotoSize50 = CGSize(width: 50, height: 50)
//            guard let viimg50 = image.resizeVI(newSize: PhotoSize50) else {return}
//            guard let img50 = viimg50.jpegData(compressionQuality: 1) else {return}
//            print("VIResize IMG: ",Double(img50.count)/1024.0, viimg50.size)
//        
//        let PhotoSize1000 = CGSize(width: 1000, height: 1000)
//        guard let viimg1000 = image.resizeVI(newSize: PhotoSize1000) else {return}
//        guard let img1000 = viimg1000.jpegData(compressionQuality: 1) else {return}
//        print("VIResize IMG: ",Double(img1000.count)/1024.0, viimg1000.size)
//        
//        
//        let PhotoSize500 = CGSize(width: 500, height: 500)
//        guard let viimg500 = image.resizeVI(newSize: PhotoSize500) else {return}
//        guard let img500 = viimg500.jpegData(compressionQuality: 1) else {return}
//        print("VIResize IMG: ",Double(img500.count)/1024.0, viimg500.size)
//        
//        guard let oldImg = image.resizeVI(newSize: defaultPhotoResize) else {return}
//        guard let oldImgjpeg = oldImg.jpegData(compressionQuality: 0.9) else {return}
//
//        print("OLD Resize IMG: ",Double(oldImgjpeg.count)/1024.0, oldImg.size)
//        
//        guard let newImg = image.resizeVI(newSize: PhotoSize1000) else {return}
//        guard let newImgjpeg = newImg.jpegData(compressionQuality: 1) else {return}
//
//        print("NEW Resize IMG: ",Double(newImgjpeg.count)/1024.0, newImg.size)
//
//        guard let newImg1 = image.resizeVI(newSize: PhotoSize1000) else {return}
//        guard let newImgjpeg1 = newImg1.jpegData(compressionQuality: 0.9) else {return}
//        
//        print("NEW Resize 90 IMG: ",Double(newImgjpeg1.count)/1024.0, newImg1.size)
//        
////        Full IMG:  6435.611328125 (4032.0, 3024.0)
////        90 IMG:  2697.3115234375
////        80 IMG:  2107.6298828125
////        50 IMG:  1102.7451171875
////        25 IMG:  516.7607421875
////        VIResize IMG:  27.83984375 (133.0, 100.0)
////        VIResize IMG:  9.0771484375 (66.0, 50.0)
////        VIResize IMG:  1431.107421875 (1333.0, 1000.0)
////        VIResize IMG:  423.958984375 (666.0, 500.0)
////        OLD Resize IMG:  149.947265625 (666.0, 500.0)
////        NEW Resize IMG:  1431.107421875 (1333.0, 1000.0)
////        NEW Resize 90 IMG:  490.9814453125 (1333.0, 1000.0)
//        
////            var resizeimg: NSData = NSData(data: UIImageJPEGRepresentation(viimg!, 1)!)
////            print("VIResize IMG: ",Double(resizeimg.length)/1024.0, viimg?.size)
////
////            var resizeimg90: NSData = NSData(data: UIImageJPEGRepresentation(image.resizeVI(newSize: defaultPhotoResize)!, 0.9)!)
////            print("Resize IMG: ",Double(resizeimg90.length)/1024.0)
////
////            var resizeimg80: NSData = NSData(data: UIImageJPEGRepresentation(image.resizeVI(newSize: defaultPhotoResize)!, 0.8)!)
////            print("Resize IMG: ",Double(resizeimg80.length)/1024.0)
////
////            var defimg = image.resizeImageWith(newSize: defaultPhotoResize)
////            var defaultresizeimg: NSData = NSData(data: UIImageJPEGRepresentation(defimg, 1)!)
////            print("Default Resize IMG: ",Double(defaultresizeimg.length)/1024.0, defimg.size)
////
////            var default90resizeimg: NSData = NSData(data: UIImageJPEGRepresentation(defimg, 0.9)!)
////            print("Default Resize IMG: ",Double(default90resizeimg.length)/1024.0, defimg.size)
//    }
    

    
}

//    static func createUserEvent(userId: String?, action: Social?, value: Int? = 0) {
//        guard let uid = Auth.auth().currentUser?.uid else {return}
//        guard let action = action else {return}
//        guard let userId = userId else {return}
//
//        var eventId = NSUUID().uuidString
//        let eventTime = Date().timeIntervalSince1970
//        var value = min(1,value ?? 0)
//        var uploadDic: [String:Any] = [:]
//
//        var notificationHeader: String = ""
//        var notificationBody: String = ""
//        var eventAction:String? = nil
//
//        switch (action) {
//        case .like:
//            eventAction = likeAction
//            notificationHeader = "\((CurrentUser.username)!) liked you"
//        case .follow:
//            eventAction = followAction
//            notificationHeader = "\((CurrentUser.username)!) followed you"
//        case .bookmark:
//            eventAction = bookmarkAction
//            notificationHeader = "\((CurrentUser.username)!) bookmarked you"
//        case .comment:
//            eventAction = commentAction
//            notificationHeader = "\((CurrentUser.username)!) commented you"
//        case .create:
//            eventAction = createAction
//        default:
//            eventAction = nil
//        }
//
//        uploadDic["action"] = eventAction
//        uploadDic["initUserUid"] = uid
//        uploadDic["receiveUserUid"] = userId
//        uploadDic["eventTime"] = eventTime
//        uploadDic["value"] = value
//
//        // ADDING TO LIST EVENT - Follow List
//        var initRef = Database.database().reference().child("user_event").child(uid)
//        var receiveRef = Database.database().reference().child("user_event").child(userId)
//
//        receiveRef.child(eventId).updateChildValues(uploadDic) { (error, reft) in
//            if let error = error {
//                print("   ~ Database | CreateUserEvent Receive | ERROR | \(error)")
//            } else {
//                if value == 1{
//                    self.sendPushNotification(uid: userId, title: notificationHeader, body: notificationBody, action: eventAction)
//                }
//                print("   ~ Database | CreateUserEvent Receive | SUCCESS: \(eventId) | \(uid) : \(action) : \(userId)")
//            }
//        }
//
//        initRef.child(eventId).updateChildValues(uploadDic) { (error, reft) in
//            if let error = error {
//                print("   ~ Database | CreateUserEvent Init | ERROR | \(error)")
//            } else {
//                print("   ~ Database | CreateUserEvent Init | SUCCESS: \(eventId) | \(uid) : \(action) : \(userId)")
//            }
//        }
//
//
//    }
//    static func createPostEvent(postId: String!, targetUid: String?, action: Social?, value: Int? = 0, locName: String? = nil, listName: String? = nil, commentText: String? = nil){
//        guard let uid = Auth.auth().currentUser?.uid else {return}
//        guard let targetUid = targetUid else {return}
//        guard let action = action else {return}
//
////        let ref = Database.database().reference().child("like_event").child(postId)
//        if targetUid == uid {
//            print("RETURN User Notifiying Self - createPostEvent")
//            return
//        }
//
//        var eventId = NSUUID().uuidString
//        let eventTime = Date().timeIntervalSince1970
//
//        var value = min(1,value ?? 0)
//        var uploadDic: [String:Any] = [:]
//        var eventAction:String? = nil
//
//        var notificationHeader: String = ""
//        var notificationBody: String = ""
//
//
//
//
//        switch (action) {
//        case .like:
//            eventAction = likeAction
//            notificationHeader = "\((CurrentUser.username)!) liked your post"
//            if let locName = locName {
//                notificationBody = (locName).capitalizingFirstLetter()
//            }
//        case .follow:
//            eventAction = followAction
//            notificationHeader = "\((CurrentUser.username)!) followed your post"
//        case .bookmark:
//            eventAction = bookmarkAction
//            notificationHeader = "\((CurrentUser.username)!) bookmarked your post"
//            if let listName = listName, let locName = locName {
//                notificationBody = "\((listName).capitalizingFirstLetter()) - \((locName).capitalizingFirstLetter())"
//            }
//        case .comment:
//            eventAction = commentAction
//            notificationHeader = "\((CurrentUser.username)!) commented on your post"
//            if let commentText = commentText {
//                notificationBody = (commentText).capitalizingFirstLetter()
//            }
//        case .commentToo:
//            eventAction = commentTooAction
//            notificationHeader = "\((CurrentUser.username)!) commented on a post you commented"
//            if let commentText = commentText {
//                notificationBody = (commentText).capitalizingFirstLetter()
//            }
//        default:
//            eventAction = nil
//        }
//        uploadDic["action"] = eventAction
//        uploadDic["initUserUid"] = uid
//        uploadDic["receiveUserUid"] = targetUid
//
//        uploadDic["eventTime"] = eventTime
//        uploadDic["value"] = value
//
//
////        ref.child(eventId).updateChildValues(uploadDic) { (error, reft) in
////            if let error = error {
////                print("   ~ Database | CreateLikeEvent | ERROR | \(error)")
////            } else {
////                print("   ~ Database | CreateLikeEvent | SUCCESS | \(postId) : \(action)")
////            }
////        }
//
//        var userUploadDic = uploadDic
//        userUploadDic["postId"] = postId
//
//        let receiveUserRef = Database.database().reference().child("user_event").child(targetUid)
//        let creatorUserRef = Database.database().reference().child("user_event").child(uid)
//
//        receiveUserRef.child(eventId).updateChildValues(userUploadDic) { (error, reft) in
//            if let error = error {
//                print("   ~ Database | receiveUserRef Like Event| ERROR | \(error)")
//            } else {
//                print("   ~ Database | receiveUserRef Like Event| SUCCESS | EVENT \(eventId) | \(postId) : \(action)")
//            }
//
//            // NOTIFY RECEIVER
//            if value == 1 {
//                self.sendPushNotification(uid: targetUid, title: notificationHeader, body: notificationBody, action: eventAction)
//            } else {
//                print("Removing - No Notification")
//            }
//
//        }
//
//        if eventAction != commentTooAction {
//            // Avoid creating multiple actions by commenter when alerting other people who commented on the post
//            return
//        }
//
//        creatorUserRef.child(eventId).updateChildValues(userUploadDic) { (error, reft) in
//            if let error = error {
//                print("   ~ Database | creatorUserRef Like Event| ERROR | \(error)")
//            } else {
//                print("   ~ Database | creatorUserRef Like Event| SUCCESS | EVENT \(eventId) | \(postId) : \(action)")
//            }
//        }
//    }
    
//    static func setupLikeListener(postIds: [PostId]?){
//
//        guard let postIds = postIds else {return}
//        if postIds.count == 0 {return}
//
//        for postId in postIds {
//
//            let listEventRef = Database.database().reference().child("like_event").child(postId.id)
//            listEventRef.observe(DataEventType.childAdded) { (snapshot) in
//                let key = snapshot.key
//                guard let listEvent = snapshot.value as? [String: Any] else {return}
//                print(listEvent)
//            }
//        }
//        print("setupLikeListener | Added \(postIds.count) ")
//
//    }
