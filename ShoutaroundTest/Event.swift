//
//  List.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/5/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import CoreLocation


enum Social: String {
    case like
    case follow
    case bookmark
    case comment
    case commentToo
    case create
    case report
}

enum userListDisplay: String {
    case userFollowers
    case userLiked
}

enum UserStats: String {
    case posts_created = "posts_created"
    case followingCount = "followingCount"
    case followerCount = "followerCount"
    case lists_created = "lists_created"
    case votes_received = "votes_received"
    case lists_received = "lists_received"
}

enum Object {
    case list
    case post
    case user
    case comment
}

enum EventAction {
    case followUser
    case followList
    case likePost
    case commentPost
    case commentTooPost
    case addPostToList
    case reportPost
    case reportUser
}

class Event {
    var id: String?
    var postId: String?
    var eventTime: Date = Date()
    var listId: String?
    var listName: String?
    var locName: String?
    var commentText: String?
    var creatorUid: String?
    var receiverUid: String?
    var readTime: Date? {
        didSet {
            self.read = readTime != nil
        }
    }
    var read: Bool = false
    var action: Social?
    var value: Int?
    var eventType = Object.post
    var userFollowedListObject = false
    var isUserFollow = false
    var eventAction: EventAction? = nil
    var dupKey: String = ""
    
    init(id: String?, dictionary: [String: Any]){
        self.id = id ?? ""
        self.listName = dictionary["listName"] as? String
        self.locName = dictionary["locName"] as? String
        self.commentText = dictionary["commentText"] as? String
        
        if let eventTimetemp = dictionary["eventTime"] as? Double {
            self.eventTime = Date(timeIntervalSince1970: eventTimetemp)
        }
        self.listId = dictionary["listId"] as? String? ?? nil
        self.creatorUid = dictionary["initUserUid"] as? String
        self.receiverUid = dictionary["receiveUserUid"] as? String

        self.postId = dictionary["postId"] as? String
        self.value = dictionary["value"] as? Int ?? 0
        
        let actionString = dictionary["action"] as? String ?? ""
        guard let actionEnum = Social(rawValue: actionString) else {
            print("Event | Can't Find Action | \(id) | \(dictionary["action"])")
            return
        }
        self.action = actionEnum
//        print("ActionString | \(actionString) TO \(self.action)")
        
        if let readTimetemp = dictionary["readTime"] as? Double {
            self.readTime = Date(timeIntervalSince1970: readTimetemp)
            self.read = true
        }
        
    // ASSUME ALL EVENT AMDE BY USER IS READ
        if self.creatorUid == Auth.auth().currentUser?.uid {
            self.read = true
        }
        
    // BOOKMARKING = ADDING POST TO LIST
        if self.action == Social.bookmark {
            self.eventType = Object.post
        }
        
    // COMMENTING = ADDING COMMENT TO POST
        else if self.action == Social.comment {
            self.eventType = Object.comment
        }
        
    // LIKE, FOLLOW, CREATE - WHICHEVER OBJECT HAS NON NIL ID IS THE OBJECT WE ARE ACTIONING TOWARDS
        else {
            if self.listId != nil {
                self.eventType = Object.list
            } else if self.postId != nil {
                self.eventType = Object.post
            } else if self.receiverUid != nil {
                self.eventType = Object.user
            }
        }
        
    // CHECK TO SEE IF ITS A USER FOLLOW
        if self.postId == nil && self.listId == nil && self.action == Social.follow && self.receiverUid != nil {
            self.eventAction = .followUser
            self.isUserFollow = true
        } else if self.action == Social.like && self.postId != nil {
            self.eventAction = .likePost
        } else if self.action == Social.follow && self.listId != nil {
            self.eventAction = .followList
        } else if self.action == Social.bookmark && self.listId != nil && self.postId != nil{
            self.eventAction = .addPostToList
        } else if self.action == Social.comment && self.postId != nil{
            self.eventAction = .commentPost
        } else if self.action == Social.commentToo && self.postId != nil{
            self.eventAction = .commentTooPost
        } else if self.action == Social.report && self.postId != nil{
            self.eventAction = .reportPost
        } else if self.action == Social.report && self.receiverUid != nil{
            self.eventAction = .reportUser
        }
        
        else
        {
            self.isUserFollow = false
        }
        
        var uidKey: String = creatorUid ?? ""
        uidKey += receiverUid ?? ""
        var tempKey = action?.rawValue ?? "" + String(value ?? 0)
        tempKey += (postId ?? "") + (listId ?? "") + uidKey
        self.dupKey = tempKey
        
    }
    
    
    
}

