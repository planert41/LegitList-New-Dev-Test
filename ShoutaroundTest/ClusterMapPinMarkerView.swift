//
//  MapPinView.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/16/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import MapKit
import UIKit


class ClusterMapPinMarkerView: MKMarkerAnnotationView {
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        collisionMode = .circle
        centerOffset = CGPoint(x: 0, y: -10) // Offset center point to animate better with marker annotations
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    override var annotation: MKAnnotation?
//        {
//        willSet
//        {
//            if let cluster = newValue as? MKClusterAnnotation {
//                image = #imageLiteral(resourceName: "legit")
//            } else {
//                // set image for non cluster
//            }
//        }
//    }
    
    var locationGoogleId: String = ""
    
    
    override func prepareForDisplay() {
        super.prepareForDisplay()
        
        displayPriority = .defaultHigh
        markerTintColor = UIColor.legitColor()
        markerTintColor = UIColor.clear


        if let cluster = annotation as? MKClusterAnnotation {
            let totalPosts = cluster.memberAnnotations.count
            
            var tempAllEmojis: [String] = []
            var tempAllEmojiCounts: [String:Int] = [:]
            
            var tempLocationNames: [String: Int] = [:]
            var tempLocationNamesEmojis: [String:String] = [:]
            
            // Find most popular Emoji
            for annotation in cluster.memberAnnotations {
                guard let mapPin = annotation as? MapPin else { return }
                if (mapPin.postEmojisArray?.count ?? 0) > 0 {
                    guard let postEmojisArray = mapPin.postEmojisArray else {return}
                    tempAllEmojis += postEmojisArray
                }
            }
//            tempAllEmojis.forEach { tempAllEmojiCounts[$0, default: 0] += 1 }
//            tempAllEmojiCounts.sorted(by: { $0.value > $1.value })
//            glyphText = tempAllEmojiCounts.first?.key
            
            markerTintColor = UIColor.legitColor()
            glyphText = String(totalPosts)
            
//            // Find most referenced Google Location ID
//            for annotation in cluster.memberAnnotations {
//                guard let mapPin = annotation as? MapPin else { return }
//                if mapPin.locationName != nil && mapPin.postEmojis != nil && mapPin.isLegit{
//                    tempLocationNames[mapPin.locationName!, default: 0] += 1
//                    tempLocationNamesEmojis[mapPin.locationName!, default: ""] += mapPin.postEmojis!
//                }
//            }
//
//            tempLocationNames.sorted(by: { $0.value > $1.value })
//
//            // Display most popular Emoji from most popular location
//            if let finalLocationName = tempLocationNames.first?.key {
//                var finalLocationEmojis = tempLocationNamesEmojis[finalLocationName]
//                tempAllEmojis += (Array(finalLocationEmojis!)).map { String($0) }
//                tempAllEmojis.forEach { tempAllEmojiCounts[$0, default: 0] += 1 }
//                tempAllEmojiCounts.sorted(by: { $0.value > $1.value })
//                glyphText = tempAllEmojiCounts.first?.key
//
//            } else {
//                markerTintColor = UIColor.legitColor()
//                glyphText = String(totalPosts)
//            }
            
            
//            if totalPosts > 2 {
//                glyphText = String(totalPosts)
//            }

            
//            for annotation in cluster.memberAnnotations {
//                guard let mapPin = annotation as? MapPin else { return }
//                if mapPin.postEmojis != nil && mapPin.isLegit{
//                    tempAllEmojis += (Array(mapPin.postEmojis!)).map { String($0) }
//                }
//            }
//
//            tempAllEmojis.forEach { tempAllEmojiCounts[$0, default: 0] += 1 }
//            tempAllEmojiCounts.sorted(by: { $0.value > $1.value })
//
//            var tempDisplayEmoji: [String] = []
//            for (key,value) in tempAllEmojiCounts {
//                if tempDisplayEmoji.count < 2 {
//                    tempDisplayEmoji.append(key)
//                }
//            }
            
//            print("Display Cluster Emoji | \(tempDisplayEmoji.joined())")
//            glyphText = String(tempDisplayEmoji.joined())
            
//            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 40.0, height: 40.0))
//            let count = cluster.memberAnnotations.count
//            image = renderer.image { _ in
//                UIColor.purple.setFill()
//                UIBezierPath(ovalIn: CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)).fill()
//                
//
//                let attributes = [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 20.0)]
//                let text = "\(count)"
//                let size = text.size(attributes: attributes)
//                let rect = CGRect(x: 20 - size.width / 2, y: 20 - size.height / 2, width: size.width, height: size.height)
//                text.draw(in: rect, withAttributes: attributes)
//            }
            
//            glyphText = String(totalPosts)
            
        }
        
    }
//
//    override var annotation: MKAnnotation? {
//        willSet {
//            guard let mapPin = newValue as? MapPin else { return }
//            canShowCallout = true
//            calloutOffset = CGPoint(x: -5, y: 5)
//
//            let postButton = UIButton(frame: CGRect(origin: CGPoint.zero,
//                                                    size: CGSize(width: 30, height: 30)))
//            postButton.addSubview(RatingLabel.init(ratingScore: mapPin.rating!, frame: CGRect(x: 0, y: 0, width: 30, height: 30)))
//            //            postButton.setBackgroundImage(#imageLiteral(resourceName: "post_icon"), for: .normal)
//
//            rightCalloutAccessoryView = postButton
//            self.setupSocialLabel(mapPin: mapPin)
//
//            if (mapPin.isLegit && mapPin.locationName?.range(of: "GPS: ") == nil){
//                self.titleVisibility = .visible
//                self.displayPriority = .required
//            } else {
//                self.titleVisibility = .hidden
//                self.displayPriority = .defaultLow
//            }
//
//            glyphImage = nil
//            glyphText = mapPin.emojiPin
//            if mapPin.emojiPin?.count == 0 || mapPin.emojiPin == nil{
//                self.titleVisibility = .hidden
//                self.displayPriority = .defaultLow
//                if let cuisineEmoji = mapPin.cuisineEmoji {
//                    glyphText = cuisineEmoji
//                } else {
//                    glyphText = "📍"
//                }
//            }
//
//
//
//            if isSelected {
//                markerTintColor = UIColor.legitColor()
//            } else {
//                markerTintColor = UIColor.clear
//            }
//
//            collisionMode = .circle
//
//        }
//    }
//
    
    
    func setupSocialLabel(mapPin: MapPin?) {
        guard let mapPin = mapPin else {
            return
        }
        
        let detailLabel = UILabel()
        detailLabel.numberOfLines = 0
        
        // Setup Social Counts
        var attributedSocialText = NSMutableAttributedString()
        let socialCountFontSize: CGFloat = 14.0
        let imageSize = CGSize(width: socialCountFontSize+5, height: socialCountFontSize+5)
        
        // Legit
        if (mapPin.isLegit) {
            let legitIcon = #imageLiteral(resourceName: "legit").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
            let legitImage = NSTextAttachment()
            legitImage.bounds = CGRect(x: 0, y: (detailLabel.font.capHeight - legitIcon.size.height).rounded() / 2, width: legitIcon.size.width, height: legitIcon.size.height)
            
            legitImage.image = legitIcon
            let legitImageString = NSAttributedString(attachment: legitImage)
            attributedSocialText.append(legitImageString)
        }
        
        
        // Votes
        if (mapPin.likeCount) > 0 {
            
            let voteCountString = String(describing: mapPin.likeCount)
            let attributedText = NSMutableAttributedString(string: "  \(voteCountString)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: socialCountFontSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black]))
            attributedSocialText.append(attributedText)
            let voteImage = NSTextAttachment()
            let voteIcon = #imageLiteral(resourceName: "drool").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
            
            voteImage.bounds = CGRect(x: 0, y: (detailLabel.font.capHeight - voteIcon.size.height).rounded() / 2, width: voteIcon.size.width, height: voteIcon.size.height)
            
            voteImage.image = voteIcon
            let voteImageString = NSAttributedString(attachment: voteImage)
            attributedSocialText.append(voteImageString)
        }
        
        // Bookmarks
        if (mapPin.listCount) > 0 {
            let listCountString = String(describing: mapPin.listCount)
            let attributedText = NSMutableAttributedString(string: "  \(listCountString)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: socialCountFontSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black]))
            attributedSocialText.append(attributedText)
            
            let listImage = NSTextAttachment()
            let listIcon = #imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
            listImage.bounds = CGRect(x: 0, y: (detailLabel.font.capHeight - listIcon.size.height).rounded() / 2, width: listIcon.size.width, height: listIcon.size.height)
            
            listImage.image = listIcon
            let listImageString = NSAttributedString(attachment: listImage)
            attributedSocialText.append(listImageString)
        }
        
        detailLabel.attributedText = attributedSocialText
        detailLabel.isUserInteractionEnabled = true
        
        detailCalloutAccessoryView = detailLabel
    }
    
    
    override func prepareForReuse() {
        glyphImage = nil
        glyphText = nil
        markerTintColor = UIColor.clear
        //        markerTintColor = UIColor.red
        
        glyphTintColor = nil
        
    }
    
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
