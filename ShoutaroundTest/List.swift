//
//  List.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/5/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

import CoreLocation
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

struct ListId {
    
    var listId: String
    var listCreatorUID: String?
    var listCreatedDate: Date?
    var listFollowedDate: Date?
    var listLastLoadDate: Date?
    var listName: String?
    
    init(id: String, dictionary: [String: Any]) {

        self.listId = id
        self.listCreatorUID = dictionary["listCreatorUID"] as? String ?? ""
        self.listName = dictionary["listName"] as? String ?? ""

        var secondsFrom1970 = dictionary["listCreatedDate"] as? Double ?? 0
        self.listCreatedDate = Date(timeIntervalSince1970: secondsFrom1970)
        if secondsFrom1970 > 0 {
            self.listCreatedDate = Date(timeIntervalSince1970: secondsFrom1970)
        }
        
        secondsFrom1970 = dictionary["followDate"] as? Double ?? 0
        if secondsFrom1970 > 0 {
            self.listFollowedDate = Date(timeIntervalSince1970: secondsFrom1970)
        }

        secondsFrom1970 = dictionary["lastLoadDate"] as? Double ?? 0
        if secondsFrom1970 > 0 {
            self.listLastLoadDate = Date(timeIntervalSince1970: secondsFrom1970)
        }

    }
}


class List {
    var id: String? = nil
    var name: String
    var creationDate: Date = Date()
    var postIds: [String:Any]? = [:] {
        // Post IDs : Date Bookmarked
        didSet{
            if (postIds?.count)! > 0 {
                self.updateVoteCount {
                }
            }
        }
    }
    var isSelected: Bool = false
    var creatorUID: String?
    var publicList: Int = 1
    // Total Cred calculates how many list ids
    var totalCred: Int = 0
    var topEmojis: [String] = []
    var mostRecentDate: Date = Date.distantPast
    // Defaults To public
    var listRanks: [String:Int] = [:]
    var followerCount: Int = 0
    var followers: [String:Any]? = [:]

    // listImageUrls are for the small post images for scrolling
    var listImageUrls: [String] = []
    var listImagePostIds: [String] = []
    var heroImageUrl: String?
    var heroImageUrlPostId: String?
    var heroImage: UIImage?
    var listDescription: String?
    var needsUpdating: Bool = false
    var listUrl: String?
    
    var tagCounts: [String: Int] = [:]
    var locationCounts: [String: Int] = [:]

    
    var listGPS: CLLocation?
    var listDistance: Double? = nil
    var newNotificationsCount: Int = 0
    var newNotifications: [Event] = [] {
        didSet {
            self.updateNotifications()
        }
    }
    var latestNotificationTime: Date = Date.distantPast
    
    func updateNotifications(){
        self.newNotificationsCount = newNotifications.count ?? 0
        if self.newNotificationsCount == 0 {
            self.latestNotificationTime = self.mostRecentDate
            return}
        // Sort Notifications by date
        if self.newNotificationsCount > 1 {
    // USE LATEST NOTIFICATION TIME
            var dateArray: [Date] = []
            for note in self.newNotifications {
                dateArray.append(note.eventTime)
            }
            self.latestNotificationTime = (dateArray.max())!
        } else {
    // ONLY ONE NOTIFICATION
            self.latestNotificationTime = self.newNotifications[0].eventTime
        }
    }
    
    func clearAllNotifications(){
        CurrentUser.followedListNotifications.removeAll(where: {$0 == self.id})
        self.newNotifications = []
        self.newNotificationsCount = 0
    }
    
    init(id: String?, name: String, publicList: Int){
        self.id = id
        self.name = name
        self.creationDate = Date()
        self.creatorUID = Auth.auth().currentUser?.uid
        self.publicList = publicList
        self.checkMostRecentDate()
    }
    
    init(id: String?, dictionary: [String: Any]){
        self.id = id
        self.name = dictionary["name"] as? String ?? ""
        let fetchedDate = dictionary["createdDate"] as? Double ?? 0
        self.creationDate = Date(timeIntervalSince1970: fetchedDate)
        self.postIds = dictionary["posts"] as? [String:Any] ?? [:]
        self.creatorUID = dictionary["creatorUID"] as? String ?? ""
        self.publicList = dictionary["publicList"] as? Int ?? 1
        self.totalCred = dictionary["totalCred"] as? Int ?? 0
        self.topEmojis = dictionary["topEmojis"] as? [String] ?? []
        self.listRanks = dictionary["listRanks"] as? [String:Int] ?? [:]
        self.followerCount = dictionary["followerCount"] as? Int ?? 0
        self.heroImageUrl = dictionary["heroImageUrl"] as? String
        self.heroImageUrlPostId = dictionary["heroImageUrlPostId"] as? String
        self.listUrl = dictionary["listUrl"] as? String

        
        let tempListImageUrls = dictionary["listImageUrls"] as? [String] ?? []
        for i in tempListImageUrls {
            let textArray = i.components(separatedBy: ",")
            if textArray.count > 1 {
                self.listImageUrls.append(textArray[0])
                self.listImagePostIds.append(textArray[1])
            }
        }
        
        self.listDescription = dictionary["listDescription"] as? String ?? ""
        
        let tagSecondsFrom1970 = dictionary["mostRecent"] as? Double ?? 0
        self.mostRecentDate = Date(timeIntervalSince1970: tagSecondsFrom1970)
        self.latestNotificationTime = self.mostRecentDate

        let imageGPSText = dictionary["location"] as? String ?? ""
        let imageGPSTextArray = imageGPSText.components(separatedBy: ",")
        if imageGPSTextArray.count == 1 {
            self.listGPS = nil
        } else {
            self.listGPS = CLLocation(latitude: Double(imageGPSTextArray[0])!, longitude: Double(imageGPSTextArray[1])!)
            
            if let location = CurrentUser.currentLocation {
                self.listDistance = self.listGPS?.distance(from: location)
            }
        }
        
        
        self.checkMostRecentDate()

    }
    
    func checkMostRecentDate(){
        var tempRecentDate = self.creationDate
        
        if let postIds = self.postIds {
            for (key,value) in postIds {
                var tempValue = value as? TimeInterval ?? 0
                let tempDate = Date(timeIntervalSince1970: tempValue)
                if tempDate > tempRecentDate {
                    tempRecentDate = tempDate
                }
            }
            
            if tempRecentDate > self.mostRecentDate {
                self.mostRecentDate = tempRecentDate
                self.latestNotificationTime = self.mostRecentDate
            }
        }
        
    }
    
    func updateVoteCount(completion: @escaping () -> ()){
        if (self.postIds?.count)! > 0 {
            var allPostIds = [] as [String]
            for (postID,value) in self.postIds! {
                allPostIds.append(postID)}
            
            completion()

//            Database.checkCredForPostIds(postIds: allPostIds) { (total_cred) in
//                if self.totalCred != total_cred {
//                    Database.updateSocialCountForList(listId: self.id, credCount: total_cred, emojis: nil)
//                    self.totalCred = total_cred
//
//                    // Update Cache
//                    listCache[self.id!] = self
//                    if CurrentUser.listIds.contains(self.id!){
//                        NotificationCenter.default.post(name: TabListViewController.newListNotificationName, object: nil)
//                    }
//
//                }
//                completion()
//            }
            
        } else {
            completion()
        }
    }
    
    
    
}

