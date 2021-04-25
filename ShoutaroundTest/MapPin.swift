//
//  MapPin.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/16/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import MapKit

class MapPin: NSObject, MKAnnotation {
    var title: String?
    let locationName: String?
    let locationGoogleId: String?
    var emojiPin: String? = nil
    var cuisineEmoji: String? = nil
    let coordinate: CLLocationCoordinate2D
    let rating: Double?
    let postId: String
    var isLegit: Bool = false
    let postCaption: String?
    let postEmojis: String?
    let postEmojisArray: [String]?
    let postRatingEmoji: String?
    var likeCount: Int = 0
    var listCount: Int = 0
    var alwaysShow: Bool = false
    
//    init(postId: String, title: String, locationName: String, emoji: String, rating: Double, isLegit: Bool, coordinate: CLLocationCoordinate2D) {
//        self.postId = postId
//        self.title = title
//        self.locationName = locationName
//        if !emoji.isEmptyOrWhitespace(){
//            self.emojiPin = emoji[0]
//        }
//        self.isLegit = isLegit
//        self.rating = rating
//        self.coordinate = coordinate
//        super.init()
//    }
    
    init(post: Post){
        self.postId = post.id!
        self.locationName = post.locationName
        self.locationGoogleId = post.locationGooglePlaceID
        if !post.emoji.isEmptyOrWhitespace(){
//            self.emojiPin = post.emoji[0]
            self.emojiPin = post.nonRatingEmoji[0]

        } else {
            self.emojiPin = ""
        }
        self.rating = post.rating
        self.isLegit = post.isLegit
        self.coordinate = (post.locationGPS?.coordinate)!
        self.postCaption = post.caption
        self.postEmojis = post.emoji
        self.postEmojisArray = post.nonRatingEmoji
        self.postRatingEmoji = post.ratingEmoji
        self.likeCount = post.likeCount
        self.listCount = post.listCount
        
        var locationNameSplit = post.locationName.split(separator: " ")
        var displayTitle: String = ""
        
        for word in locationNameSplit {
            if displayTitle.count < 10 {
                displayTitle += " \(word)"
            }
        }
//        self.title = displayTitle

        self.title = post.locationName.truncate(length: 30)
        
        self.cuisineEmoji = post.autoTagEmoji.first { (emoji) -> Bool in
            return cuisineEmojiSelect.contains(emoji)
        }
        self.alwaysShow = false
        
        // Only show location name if legit
//        if (self.isLegit && post.locationName.range(of: "GPS: ") == nil){
//            self.title = post.locationName
//        } else {
//            self.title = nil
//        }

        
        super.init()
        
    }
    
//    let detailLabel = UILabel()
//    detailLabel.numberOfLines = 0
//    detailLabel.font = detailLabel.font.withSize(12)
//    detailLabel.text = artwork.subtitle
//    detailCalloutAccessoryView = detailLabel
    
//    var subtitle: String? {
//        var socialCount: String?
//        return postCaption
//    }
    
    // pinTintColor for disciplines: Sculpture, Plaque, Mural, Monument, other

    
    // Annotation right callout accessory opens this mapItem in Maps app
//    func mapItem() -> MKMapItem {
//        let addressDict = [CNPostalAddressStreetKey: subtitle!]
//        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: addressDict)
//        let mapItem = MKMapItem(placemark: placemark)
//        mapItem.name = title
//        return mapItem
//    }
    
    
    
    
}
