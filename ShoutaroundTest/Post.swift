//
//  Post.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/29/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import SwiftyJSON

//struct PostId {
//
//    var id: String
//    var creatorUID: String?
//    var creationDate: Date?
//    var distance: Double? = 99999999
//    var postGPS: String? = nil
//    var emoji: String?
//
//    //Social
//    var hasLiked: Bool = false
//    var hasBookmarked: Bool = false
//    var hasMessaged: Bool = false
//    var likeCount: Int = 0
//    var listCount:Int = 0
//    var messageCount:Int = 0
//    var voteCount:Int = 0
//    var hasVoted:Int = 0
//
//    var sort: Double?
//
//    init(id: String, creatorUID: String, fetchedDate: Double, distance: Double?, postGPS: String?, postEmoji: String?) {
//
//        self.id = id
//        self.creatorUID = creatorUID
//        self.creationDate = Date(timeIntervalSince1970: fetchedDate)
//        self.postGPS = postGPS
//        self.emoji = postEmoji
//
//    }
//}

struct PostId: Hashable, Equatable {
    
    var id: String
    var creatorUID: String?
    var sort: Double?
    var hashValue: Int { get { return id.hashValue } }

    init(id: String, creatorUID: String?, sort: Double?) {
        
        self.id = id
        self.creatorUID = creatorUID ?? nil
        self.sort = sort ?? 0
        
    }
}

func ==(left:PostId, right:PostId) -> Bool {
    return (left.id == right.id) && (left.creatorUID == right.creatorUID)
}


enum postType {
    case breakfast
    case brunch
    case lunch
    case dinner
    case dessert
    case coffee
    case drinks
    case latenight
    case poi
}

func ==(left:Post, right:Post) -> Bool {
    return (left.id == right.id) && (left.creationDate == right.creationDate)
}


struct Post: Hashable, Equatable  {
    
    var id: String?

    var image: UIImage?
    var imageUrl: String
    
    var images: [UIImage]?
    var imageUrls: [String]
    var imageCount: Int = 0
    var smallImageUrl: String
    
    let user: User
    let caption: String
    let creationSecondsFrom1970: Double
    let creationDate: Date
    var locationGPS: CLLocation?
    var imageGPS: CLLocation?

    var locationName: String
    var locationAdress: String
    var locationSummaryID: String?
    var locationGooglePlaceID: String?
    var locationGoogleJSON: JSON?
    var distance: Double? = nil
    let tagTime: Date
    var urlLink: String?
    var hashValue: Int { get { return id.hashValue } }


    var creatorUID: String?
    var creatorListId: [String:String]? = [:]{
        didSet{
            self.updateListCount()
        }
    }
    
    var updateFromChecks: Bool = false

    
    // LIST ID : LIST NAME
    var selectedListId: [String:String]? = [:] {
        didSet {
            if ((self.selectedListId?.count) ?? 0) > 0 {
                self.hasPinned = true
                if let bookmarkListID = CurrentUser.bookmarkListId {
                    if self.selectedListId![CurrentUser.bookmarkListId!] != nil {
                        self.hasBookmarked = true
                    }
                }
            } else {
                self.hasPinned = false
            }
            self.updateListCount()
        }
    }
    var listedDate: Date? = nil
    var listedRank: Int? = nil

    var emoji: String
    var nonRatingEmoji: [String]
    var nonRatingEmojiTags: [String]
    var ratingEmoji: String?
    
    var autoTagEmoji: [String]
    var autoTagEmojiTags: [String]
    
    var allEmojis: [String] = []

    
    var rating: Double?
    var price: String?
    var type: String?
    
    //Social Stats
//    var hasLiked: Bool = false
//    var likeCount: Int = 0

    var hasPinned: Bool = false
    var hasBookmarked: Bool = false
    var hasLiked: Bool = false
    var hasMessaged: Bool = false
    
    var listCount:Int = 0 {
        didSet{
            updateCred()
        }
    }
    var messageCount:Int = 0 {
        didSet{
            updateCred()
        }
    }
    
    var likeCount:Int = 0 {
        didSet{
            updateCred()
        }
    }
    
    var credCount: Int = 0
    
    var isLegitRead: Bool = false
    var isLegit: Bool = false
    var commentCount: Int = 0
    var comments: [Comment] = [] {
        didSet{
//            self.commentCount = comments.count
        }
    }
    
    // followingVote = followingUserID
    var followingVote: [String] = []
    var allVote: [String] = []

    
    // followingList = listID: CreatorUID
    var followingList: [String: String] = [:]
    var allList: [String: String] = [:]


    var followingComments :[Comment] = []
    
    var reportedFlag: Bool = false
    
    
    
    init(user: User, dictionary: [String: Any]) {
        
        
        self.user = user
        
        // ?? "" gives default value
        self.imageUrl = dictionary["imageUrl"] as? String ?? ""
        self.imageUrls = dictionary["imageUrls"] as? [String] ?? []
        
        let tempImageLink50 = dictionary["ImageLink50"] as? String ?? ""
        let tempSmallImage = dictionary["smallImageLink"] as? String ?? ""
        
        if tempImageLink50 != "" {
            self.smallImageUrl = tempImageLink50
        } else {
            self.smallImageUrl = tempSmallImage
        }
        
//        self.smallImageUrl = dictionary["ImageLink50"] as? String ?? ""
        if (self.images != nil) {
            self.imageCount = (self.images?.count)!
        } else {
            self.imageCount = self.imageUrls.count as? Int ?? 0
        }
        
        "https://firebasestorage.googleapis.com/v0/b/shoutaroundtest-ae721.appspot.com/o/posts%2FF65ADD17-BF71-4A0E-B1BB-6C7DB8406E4A?alt=media&token=9edf5641-463c-49bb-956f-64478b409c33"
        
        "https://firebasestorage.googleapis.com/v0/b/shoutaroundtest-ae721.appspot.com/o/posts%2FF65ADD17-BF71-4A0E-B1BB-6C7DB8406E4A?alt=media&token=aef5c712-d63f-4c9a-b3ca-ba9d13f20a06"
        
        self.caption = dictionary["caption"] as? String ?? ""
        
        self.rating = dictionary["rating"] as? Double ?? 0
        self.nonRatingEmoji = dictionary["nonratingEmoji"] as? [String] ?? []
        self.nonRatingEmojiTags = dictionary["nonratingEmojiTags"] as? [String] ?? []
        self.ratingEmoji = dictionary["ratingEmoji"] as? String ?? nil
        
        // CHANGE THE BEST RATING EMOJI
//        if self.ratingEmoji == "🥇" {
//            self.ratingEmoji = "🏆"
//        }
        
        // ADJUST All emojis like chicken dup emoji
        var tempEmoji:[String] = []
        for emoji in self.nonRatingEmoji {
            if let replace = AdjustEmojiDictionary[emoji] {
                tempEmoji.append(replace)
            } else {
                tempEmoji.append(emoji)
            }
        }
        self.nonRatingEmoji = tempEmoji
        
        
        self.emoji = (self.nonRatingEmoji.joined())
        
        self.autoTagEmoji = dictionary["autoTagEmojis"] as? [String] ?? []
        self.autoTagEmojiTags = dictionary["autoTagEmojisDict"] as? [String] ?? []
        
        self.allEmojis = []
        if let rate = self.ratingEmoji {
            self.allEmojis.append(rate)
        }
        
        if self.nonRatingEmoji.count > 0 {
            self.allEmojis += self.nonRatingEmoji
        }
        
        if self.autoTagEmoji.count > 0 {
            self.allEmojis += self.autoTagEmoji
        }
        
        self.allEmojis = Array(Set(self.allEmojis))
                
        
        self.creationSecondsFrom1970 = dictionary["tagTime"] as? Double ?? 0
        self.tagTime = Date(timeIntervalSince1970: self.creationSecondsFrom1970)
        
        let secondsFrom1970 = dictionary["creationDate"] as? Double ?? 0
        self.creationDate = Date(timeIntervalSince1970: secondsFrom1970)
        self.locationName = dictionary["locationName"] as? String ?? ""
        self.locationAdress = dictionary["locationAdress"] as? String ?? ""
        self.locationGooglePlaceID = dictionary["googlePlaceID"] as? String ?? ""
        self.locationSummaryID = (dictionary["locationSummaryID"] as? String ?? "").replacingOccurrences(of: ".", with: "")
//        self.locationSummaryID = (self.locationSummaryID ?? "").replacingOccurrences(of: ".", with: "")
        self.urlLink = dictionary["urlLink"] as? String ?? ""
        self.creatorUID = dictionary["creatorUID"] as? String ?? ""
        
        self.creatorListId = dictionary["lists"] as? [String:String]? ?? [:]
        
//        Post is Legit if rated as legit or included in LegitList
        self.isLegit = dictionary["isLegit"] as? Bool ?? false
//        if self.creatorListId?.count == 0 {
//            self.isLegit = false
//        } else {
//            self.isLegit = (self.creatorListId?.contains(where: { (key,value) -> Bool in
//                value == legitListName
//            }))!
//        }
        
        
        if self.creatorUID == Auth.auth().currentUser?.uid {
            self.selectedListId = self.creatorListId
        }
        
        self.listCount = dictionary["listCount"] as? Int ?? 0
        self.messageCount = dictionary["messageCount"] as? Int ?? 0
        self.likeCount = dictionary["voteCount"] as? Int ?? 0
        self.commentCount = dictionary["commentCount"] as? Int ?? 0
        self.credCount = self.listCount + self.messageCount + self.likeCount
        
        self.price = dictionary["price"] as? String ?? nil
        self.type = dictionary["type"] as? String ?? nil
        
        let locationGPSText = dictionary["postLocationGPS"] as? String ?? ""
        let locationGPSTextArray = locationGPSText.components(separatedBy: ",")
        
        if locationGPSTextArray.count < 2 {
            self.locationGPS = nil
            self.distance = nil
        } else {
        self.locationGPS = CLLocation(latitude: Double(locationGPSTextArray[0])!, longitude: Double(locationGPSTextArray[1])!)
        
            if CurrentUser.currentLocation != nil {
                self.distance = Double((self.locationGPS?.distance(from: CurrentUser.currentLocation!))!)
            }
        }
    
        let imageGPSText = dictionary["imageLocationGPS"] as? String ?? ""
        let imageGPSTextArray = imageGPSText.components(separatedBy: ",")
        
        if imageGPSTextArray.count == 1 {
            self.imageGPS = nil
        } else {
            self.imageGPS = CLLocation(latitude: Double(imageGPSTextArray[0])!, longitude: Double(imageGPSTextArray[1])!)
        }
        
        self.reportedFlag = dictionary["reportedFlag"] as? Bool ?? false
    
    }
    
    func dictionary() -> [String:Any]{
        var createdTime = self.creationDate.timeIntervalSince1970
        
        var uploadedLocationGPSLatitude: String?
        var uploadedlocationGPSLongitude: String?
        var uploadedLocationGPS: String?
        
        if self.locationGPS == nil {
            uploadedLocationGPS = nil
        } else {
            uploadedLocationGPSLatitude = String(format: "%f", (self.locationGPS!.coordinate.latitude))
            uploadedlocationGPSLongitude = String(format: "%f", (self.locationGPS!.coordinate.longitude))
            uploadedLocationGPS = uploadedLocationGPSLatitude! + "," + uploadedlocationGPSLongitude!
        }
        
        var uploadedImageLocationGPSLatitude: String?
        var uploadedImageLocationGPSLongitude: String?
        var uploadedImageLocationGPS: String?

        if self.imageGPS == nil {
            uploadedImageLocationGPS = nil
        } else {
            uploadedImageLocationGPSLatitude = String(format: "%f", (self.imageGPS!.coordinate.latitude))
            uploadedImageLocationGPSLongitude = String(format: "%f", (self.imageGPS!.coordinate.longitude))
            uploadedImageLocationGPS = uploadedImageLocationGPSLatitude! + "," + uploadedImageLocationGPSLongitude!
        }
        
        let values = ["caption": self.caption,"rating": self.rating, "ratingEmoji": self.ratingEmoji, "nonratingEmoji": self.nonRatingEmoji, "nonratingEmojiTags": self.nonRatingEmojiTags, "autoTagEmojis": self.autoTagEmoji, "autoTagEmojisDict": self.autoTagEmojiTags, "creationDate": createdTime, "googlePlaceID": self.locationGooglePlaceID, "locationName": self.locationName, "locationAdress": self.locationAdress, "locationSummaryID": self.locationSummaryID, "postLocationGPS": uploadedLocationGPS, "imageLocationGPS": uploadedImageLocationGPS, "creatorUID": self.creatorUID, "price": self.price, "type": self.type, "lists": self.creatorListId, "isLegit": self.isLegit, "smallImageLink": self.smallImageUrl, "imageUrls": self.imageUrls, "urlLink": self.urlLink, "reportedFlag": self.reportedFlag] as [String:Any]
        
        return values
    }
    
    mutating func updateCred(){
        credCount = listCount + messageCount + likeCount
    }
    
    mutating func updateListCount(){
//        listCount = (creatorListId?.count) ?? 0 + (selectedListId?.count)!
    }
    
    mutating func clearRefresh(){
        imageCount = 0
        locationName = ""
        locationAdress = ""
        creatorListId?.removeAll()
        selectedListId?.removeAll()
        listedDate = nil
        listedRank = nil
        nonRatingEmoji.removeAll()
        nonRatingEmojiTags.removeAll()
        rating = 0
        price = ""
        hasLiked = false
        hasPinned = false
        hasMessaged = false
        hasBookmarked = false
        listCount = 0
        messageCount = 0
        likeCount = 0
        credCount = 0
        isLegit = false
    }
    
}

