//
//  User.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/30/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import CoreLocation
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

struct User {
    let username: String
    let profileImageUrl: String
    let uid : String
    // Keep empty set so that arrays can be easily appended instead of handling null
    var listIds: [String] = []
    var userBadges: [Int] = []
    var isFollowing: Bool? = false
    var status: String?
    var emojiStatus: String?
    var description: String?

    //Social Data
    var posts_created: Int = 0
    var followingCount: Int = 0
    var followersCount: Int = 0
    var votes_received: Int = 0
    var lists_created: Int = 0
    var total_cred: Int = 0
    
    var creationDate: Date = Date()
    var lastModDate: Date = Date()

    var popularImageUrls: [String] = []
    var popularImagePostIds: [String] = []
    
    var topEmojis: [String] = []
    var userDistance: Double? = nil
    
    var userCity: String? = nil
    var userGPS: CLLocation?

    
    var premiumStart: Date?
    var premiumExpiry: Date?
    var premiumCancel: Date?
    var premiumPeriod: SubPeriod?
    var isPremium: Bool = false
    var isPremiumFree: Bool = false
    var APNTokens: [String] = []
    var mostUsedEmojis: [String] = []
    var mostUsedCities: [String] = []
    var blockedPosts: [String: Date] = [:]
    var blockedUsers: [String: Date] = [:]
    var blockedByUsers: [String: Date] = [:]
    var blockedMessages: [String: Date] = [:]
    var reportedFlag: Bool = false
    var isPrivate: Bool = false
    var isBlocked: Bool = false
    var isBlockedByUser: Bool = false {
        didSet {
            self.isBlocked = isBlockedByUser || isBlockedByCurUser
        }
    }
    var isBlockedByCurUser: Bool = false {
        didSet {
            self.isBlocked = isBlockedByUser || isBlockedByCurUser
        }
    }
    var appleSignUp: Bool = false

    
    init(uid: String, dictionary: [String:Any]) {
        self.username = dictionary["username"] as? String ?? ""
        self.profileImageUrl = dictionary["profileImageUrl"] as? String ?? ""
        self.uid = uid
        self.description = dictionary["description"] as? String ?? ""
        self.status = dictionary["status"] as? String ?? ""
        self.emojiStatus = dictionary["emojiStatus"] as? String ?? ""
        self.topEmojis = dictionary["topEmojis"] as? [String] ?? []
        self.userBadges = dictionary["userBadges"] as? [Int] ?? []
        let tagSecondsFrom1970 = dictionary["creationDate"] as? Double ?? 0
        self.creationDate = Date(timeIntervalSince1970: tagSecondsFrom1970)
        self.appleSignUp = dictionary["appleSignUp"] as? Bool ?? false

        let tagSecondsFrom1971 = dictionary["lastModeDate"] as? Double ?? 0
        self.lastModDate = Date(timeIntervalSince1970: tagSecondsFrom1971)
        
        //lists
        let lists = dictionary["lists"] as? [String:Any] ?? [:]
        for (listId, values) in lists {
            self.listIds.append(listId)
        }
        
        let blockPosts = dictionary["blockPost"] as? [String:Any] ?? [:]
        for (postid, blockDate) in blockPosts {
            if let blockDate = blockDate as? Double {
                self.blockedPosts[postid] = Date(timeIntervalSince1970: blockDate)
            }
        }
        
        let blockUsers = dictionary["blockUser"] as? [String:Any] ?? [:]
        for (blockuid, blockDate) in blockUsers {
            if let blockDate = blockDate as? Double {
                self.blockedUsers[blockuid] = Date(timeIntervalSince1970: blockDate)
            }
        }
        
        let blockByUsers = dictionary["blockByUser"] as? [String:Any] ?? [:]
        for (blockuid, blockDate) in blockByUsers {
            if let blockDate = blockDate as? Double {
                self.blockedByUsers[blockuid] = Date(timeIntervalSince1970: blockDate)
            }
        }
        
        let blockMessages = dictionary["blockMessage"] as? [String:Any] ?? [:]
        for (blockuid, blockDate) in blockMessages {
            if let blockDate = blockDate as? Double {
                self.blockedMessages[blockuid] = Date(timeIntervalSince1970: blockDate)
            }
        }
        
        let social = dictionary["social"] as? [String:Int] ?? [:]
        self.posts_created = social["posts_created"] as? Int ?? 0
        self.followingCount = social["followingCount"] as? Int ?? 0
        self.followersCount = social["followerCount"] as? Int ?? 0
        self.votes_received = social["votes_received"] as? Int ?? 0
        self.lists_created = social["lists_created"] as? Int ?? 0
        self.total_cred = self.votes_received + self.posts_created + self.lists_created
        self.userCity = dictionary["userCity"] as? String ?? ""
        let userGPSText = dictionary["userLocation"] as? String ?? ""
        let userGPSTextArray = userGPSText.components(separatedBy: ",")
        if userGPSTextArray.count == 1 {
            self.userGPS = nil
        } else {
            self.userGPS = CLLocation(latitude: Double(userGPSTextArray[0])!, longitude: Double(userGPSTextArray[1])!)
            
            if let location = CurrentUser.currentLocation {
                self.userDistance = self.userGPS?.distance(from: location)
            }
        }
        
        
        let tempImageUrls = dictionary["popularImageUrls"] as? [String] ?? []
        for i in tempImageUrls {
            let textArray = i.components(separatedBy: ",")
            if textArray.count > 1 {
                self.popularImageUrls.append(textArray[0])
                self.popularImagePostIds.append(textArray[1])
            }
        }
        
        if let location = CurrentUser.currentLocation {
            
        }
        
        let tokens = (dictionary["APNTokens"] as? [String: Bool] ?? [:]).filter { key, value in
            return value == true
        }
        self.APNTokens = Array(tokens.keys)
        
        self.reportedFlag = dictionary["reportedFlag"] as? Bool ?? false
        self.isPrivate = dictionary["isPrivate"] as? Bool ?? false

        
    // PREMIUM
        self.isPremium = dictionary["isPremium"] as? Bool ?? false
        self.isPremiumFree = dictionary["isPremiumFree"] as? Bool ?? false
        if !premiumActivated {
            self.isPremiumFree = true
            self.isPremium = true
        }
        
        if UID_team.contains(uid) {
            self.isPremiumFree = true
            self.isPremium = true
        }
        
        let premCancel = dictionary["premiumCancel"] as? Double ?? 0
        if premCancel > 0 {
            self.premiumCancel = Date(timeIntervalSince1970: premCancel)
        }
        
        var tempLength = dictionary["premiumPeriod"] as? String ?? ""
        if tempLength == "annual" {
            self.premiumPeriod = SubPeriod.annual
        } else if tempLength == "monthly" {
            self.premiumPeriod = SubPeriod.monthly
        } else {
            self.premiumPeriod = nil
        }
        
        let premStart = dictionary["premiumStart"] as? Double ?? 0
        if premStart > 0 {
            self.premiumStart = Date(timeIntervalSince1970: premStart)
        }
        
        let premExp = dictionary["premiumExpiry"] as? Double ?? 0
        if premExp >= 0 {
            self.premiumExpiry = Date(timeIntervalSince1970: premExp)
            if Date() > self.premiumExpiry! && self.isPremium && !self.isPremiumFree{
                self.isPremium = false
                if uid == Auth.auth().currentUser?.uid {
                    print("PREMIUM USER EXPIRED")
                    Database.updatePremiumUserDatabase(uid: uid, cancel: false, activate: false, expiryDate: nil, premSub: nil, force: true)
                }
            }
        }
    }
    
}

struct CurrentUser {

    // From User Database
    static var username: String?
    static var profileImageUrl: String?
    static var uid : String?
    static var status: String?
    static var isGuest: Bool = false
    static var premiumStart: Date?
    static var premiumExpiry: Date?
    static var premiumCancel: Date?
    static var premiumPeriod: SubPeriod?
    static var isPremium: Bool = false {
        didSet {
            print("Current User IsPremium: \(isPremium)")
        }
    }
    static var isPremiumFree: Bool = false
    static var appleSignUp: Bool = false


    static var distanceFormatter: MeasurementFormatter {
        let format = MeasurementFormatter()
        format.unitStyle = .short
        format.numberFormatter.usesSignificantDigits = true
        format.numberFormatter.maximumSignificantDigits = 2
        format.numberFormatter.maximumFractionDigits = 2

        return format
    }
    
    static var events:[Event] = [] {
        didSet {
            
            self.unreadEventCount = self.events.filter({ (event) -> Bool in
                return !event.read && event.creatorUid != Auth.auth().currentUser?.uid && event.value == 1
            }).count
        }
    }
    static var unreadEventCount = 0 {
        didSet {
//            print("CURRENT_USER | UnreadEventCount Changed: \(unreadEventCount) | EventCount: \(self.events.count)")
            if self.unreadEventCount != oldValue {
                print("TRIGGER | CURRENT USER | EVENTS")
                NotificationCenter.default.post(name: MainTabBarController.NewNotificationName, object: nil)
                NotificationCenter.default.post(name: UserProfileController.RefreshNotificationName, object: nil)
            }
        }
    }
    
    static var unreadMessageCount = 0 {
        didSet {
            if self.unreadEventCount != oldValue {
                NotificationCenter.default.post(name: InboxController.newMsgNotificationName, object: nil)
            }
//            print("CURRENT_USER | UnreadEventCount Changed: \(unreadEventCount) | EventCount: \(self.events.count)")
//            NotificationCenter.default.post(name: MainTabBarController.NewNotificationName, object: nil)
//            NotificationCenter.default.post(name: UserProfileController.RefreshNotificationName, object: nil)
        }
    }
    
    static var listEvents:[Event] = []
    static var followedListNotifications: [String] = []

    // From Other Database Sources
    static var currentLocation: CLLocation? {
        didSet{distanceFormatter.locale = NSLocale.current}}
    static var currentLocationTime: Date?
    static var followingUids: [String] = []
    static var followingUsers: [User] = []

    static var followerUids: [String] = []
    static var groupUids: [String] = []
    
    
    static var listIds: [String] = []
    static var lists: [List] = [] {
        didSet {
            updateCurrentUserListPostIds()
        }
    }
    
    static func updateCurrentUserListPostIds() {
        listedPostIds.removeAll()
        for list in lists {
            if list.name == legitListName {
                self.legitListId = list.id
            } else if list.name == bookmarkListName {
                self.bookmarkListId = list.id
            }
            
            
            
            for (key, value) in (list.postIds ?? [:]) {
                let listPostId = key
                if let listId = list.id {
                    if let _ = listedPostIds[listPostId] {
                        var temp = listedPostIds[listPostId]
                        if !(temp?.contains(listId) ?? false) {
                                temp?.append(listId)
                                listedPostIds[listPostId] = temp
                            }
                    } else {
                        listedPostIds[listPostId] = [(listId)]
                    }
                }
            }
        }
        print("updateCurrentUserListPostIds | \(listedPostIds.count)")
    }
    
    // PostID - [ListID]
    static var listedPostIds: [String: [String]] = [:]
    
    static var followedLists: [List] = []
    static var followedListIds: [String] = []
    static var followedListIdObjects: [ListId] = []

    
    //static var currentLocation: CLLocation? = CLLocation(latitude: 41.9735039, longitude: -87.66775139999999)
    static var legitListId: String? = nil
    static var bookmarkListId: String? = nil
    
    
    static var mostUsedEmojis: [String] = [] {
        didSet {
            NotificationCenter.default.post(name: ListViewControllerNew.CurrentUserLoadedNotificationName, object: nil)
        }
    }
    static var mostUsedCities: [String] = [] {
        didSet {
            NotificationCenter.default.post(name: ListViewControllerNew.CurrentUserLoadedNotificationName, object: nil)
        }
    }
    static var mostTaggedLocations: [String] = []
    
    static var userTaggedEmojiCounts: [String: Int] = [:] {
        didSet {
            Database.sortEmojisWithCounts(inputEmojis: allEmojis, emojiCounts: userTaggedEmojiCounts) { sortedEmojis in
                allEmojis = sortedEmojis
                }
            }
    }
    static var userTaggedPlaceCounts: [String: Int] = [:]
    static var userTaggedCityCounts: [String: Int] = [:]

    
    static var postIds: [PostId] = [] {
        didSet {
//            Database.setupListListener(postIds: postIds)
        }
    }
    static var posts: [String:Post] = [:]
    
    static var blockedPosts:[String: Date] = [:]
    static var blockedUsers:[String: Date] = [:]
    static var blockedByUsers:[String: Date] = [:]
    static var blockedMessages:[String: Date] = [:] {
        didSet {
            self.refreshInbox()
        }
    }
    
    static var likedPostIds:[String: Double] = [:]

    // Inbox
    static var inboxThreads: [MessageThread] = [] {
        didSet{
            self.refreshInbox()
        }
    }
    
    static func refreshInbox() {
        self.unreadMessageCount = inboxThreads.filter({ (thread) -> Bool in
            return !thread.isRead && CurrentUser.blockedMessages[thread.threadID] == nil
        }).count
        print("refreshInbox | UNREAD MESSAGE COUNT: \(self.unreadMessageCount)")
    }
    
    
    static var APNTokens: [String] = []
    static var curAPNToken: String?
    
    static var user: User? {
        didSet{
            if user != nil{
                self.username = user?.username
                self.uid = user?.uid
                self.profileImageUrl = user?.profileImageUrl
                self.listIds = (user?.listIds)!
                self.isPremium = (user?.isPremium ?? false)
                self.isPremiumFree = (user?.isPremiumFree ?? false)
                self.premiumExpiry = user?.premiumExpiry
                self.premiumStart = user?.premiumStart
                self.premiumCancel = user?.premiumCancel
                self.premiumPeriod = user?.premiumPeriod
                self.APNTokens = user?.APNTokens ?? []
                self.blockedPosts = user?.blockedPosts ?? [:]
                self.blockedUsers = user?.blockedUsers ?? [:]
                self.blockedByUsers = user?.blockedByUsers ?? [:]
                self.blockedMessages = user?.blockedMessages ?? [:]
                self.appleSignUp = user?.appleSignUp ?? false
                self.checkAPNToken()
            } else {
                self.username = nil
                self.uid = nil
                self.profileImageUrl = nil
                self.listIds = []
                self.isPremium = false
                self.isPremiumFree = false
                self.premiumExpiry = nil
                self.premiumStart = nil
                self.premiumCancel = nil
                self.premiumPeriod = nil
                self.blockedPosts = [:]
                self.blockedUsers = [:]
                self.blockedByUsers = [:]
                self.blockedMessages = [:]
                self.appleSignUp = false
            }
        }
    }
    
    static func checkAPNToken() {
        if let curToken = self.curAPNToken {
            if !self.APNTokens.contains(curToken) {
                Database.saveAPNTokenForUser(userId: Auth.auth().currentUser?.uid, token: curToken)
            }
        }
    }
    
    static func addAPNToken(token: String) {
        print("Current User | Added APNToken | \(token)")
        self.curAPNToken = token
        if !self.APNTokens.contains(token) {
            self.APNTokens.append(token)
        }
    }
    
    static func clear(){
        Database.removeUserFollowingListener(uids: self.followingUids)
        self.user = nil
        self.followingUids = []
        self.followerUids = []
        self.listIds = []
        self.lists = []
        self.legitListId = nil
        self.bookmarkListId = nil
        self.mostUsedEmojis = []
        self.postIds = []
        self.posts = [:]
    }
    
    
    static func addFollowing(userId: String?) {
        print("Current User | Added Following | \(userId)")
        guard let userId = userId else {return}
        self.followingUids.append(userId)
        
        if let user = userCache[userId] {
            var tempUser = user
            tempUser.isFollowing = true
            userCache[userId] = tempUser
            CurrentUser.followingUsers.append(tempUser)
        } else {
            Database.fetchUserWithUID(uid: userId) { (fetchedUser) in
                guard let fetchedUser = fetchedUser else {return}
                CurrentUser.followingUsers.append(fetchedUser)
            }
        }
        Database.addUserFollowingListener(uid: userId)
    }
    
    static func removeFollowing(userId: String?) {
        print("Current User | Unfollowed | \(userId)")
        guard let userId = userId else {return}
        if let removeIndex = self.followingUids.firstIndex(of: userId){
            self.followingUids.remove(at: removeIndex)
        }
        
        let tempUsers = CurrentUser.followingUsers.filter { (user) -> Bool in
            return !(user.uid == userId)
        }
        
        CurrentUser.followingUsers = tempUsers
        
        
        if let user = userCache[userId] {
            var tempUser = user
            tempUser.isFollowing = false
            userCache[userId] = tempUser
        }
        Database.database().reference().child("userposts").child(userId).removeAllObservers()
        
    }
    
    static func addFollower(userId: String?) {
        print("Current User | Added Follower | \(userId)")
        guard let userId = userId else {return}
        self.followerUids.append(userId)
    }
    
    static func removeFollower(userId: String?) {
        print("Current User | Removed Follower | \(userId)")
        guard let userId = userId else {return}
        if let removeIndex = self.followerUids.firstIndex(of: userId){
            self.followerUids.remove(at: removeIndex)
        }
    }
    
    static func addList(list: List){
        guard let listId = list.id else {
            print("CurrentUser Add List: ERROR: No List ID")
            return
        }
        if self.listIds.contains(listId) {
            
            print("Current User Contains Current List. Delete Old List, insert new one \(list)")
            if let index = self.lists.firstIndex(where: { (temp_list) -> Bool in
                temp_list.id == listId
            }){
                self.lists.remove(at: index)
                self.lists.append(list)
            }
        } else {
            self.listIds.append(listId)
            self.lists.append(list)
        }
    }
    
    static func addPostToList(postId: String?, listId: String?){
        guard let postId = postId else {
            print("Add Post To List: ERROR, No Post ID")
            return
        }
        
        guard let listId = listId else {
            print("Add Post To List: ERROR, No List ID")
            return
        }
        
        guard let listIndex = self.lists.firstIndex(where: { (list) -> Bool in
            list.id == listId
        }) else {
            print("Add Post To List: ERROR, Can't Find List \(listId) in Current User ListIDs")
            return
        }
        
        var tempList = self.lists[listIndex]
        let createdDate = Date().timeIntervalSince1970

        
        tempList.postIds![postId] = createdDate
        
        // Replace Current User List with updated Post Ids
        self.lists[listIndex] = tempList
        print("SUCCESS : Add Post To List, Added Post: \(postId) to List: \(listId)")

    }
    
    
    static func removeList(list: List){
        guard let listId = list.id else {
            print("CurrentUser Remove List: ERROR: No List ID")
            return
        }
        self.lists.remove(at: (self.lists.firstIndex(where:{$0.id == listId}))!)
        self.listIds.remove(at: (self.listIds.firstIndex(where:{$0 == listId}))!)
    }
    
    static func removePostFromList(postId: String?, listId: String?){
        guard let postId = postId else {
            print("removePostFromList | CURRENT USER| ERROR, No Post ID")
            return
        }
        
        guard let listId = listId else {
            print("removePostFromList | CURRENT USER| ERROR, No List ID")
            return
        }
        
        guard let listIndex = self.lists.firstIndex(where: { (list) -> Bool in
            list.id == listId
        }) else {
            print("removePostFromList | CURRENT USER| ERROR, Can't Find List \(listId) in Current User ListIDs")
            return
        }
        
        if let postIndex = self.lists[listIndex].postIds?.index(forKey: postId){
            self.lists[listIndex].postIds?.remove(at: postIndex)
            print("removePostFromList | CURRENT USER| SUCCESS, Removed Post: \(postId) to List: \(listId)")
        }
        
        
        
    }
    
    
    
    
    
    static func printProperties(){
        let currentUserProperties = Mirror(reflecting: self)
        let properties = currentUserProperties.children
        
        for property in properties {
            print("\(property.label!) = \(property.value)")
        }
    }

    
}
