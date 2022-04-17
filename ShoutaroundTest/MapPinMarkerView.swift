//
//  MapPinView.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/16/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import MapKit


class MapPinMarkerView: MKMarkerAnnotationView {
    
    
    var defaultPinColor = UIColor.ianBlackColor()
    var defaultSelectedPinColor = UIColor.ianLegitColor()
    var defaultLegitPinColor = UIColor.lightSelectedColor()
//    var testColor = UIColor.lightSelectedColor()
    
    override var annotation: MKAnnotation? {
        willSet {
            guard let mapPin = newValue as? MapPin else { return }
            canShowCallout = true
            calloutOffset = CGPoint(x: -5, y: 5)
            
        // SET PIN EMOJI - SHOWS FIRST EMOJI OR THE CUISINE EMOJI IF NOT FOOD EMOJI
            glyphImage = nil
            glyphText = mapPin.emojiPin
            if mapPin.emojiPin?.count == 0 || mapPin.emojiPin == nil{
                self.titleVisibility = .hidden
                self.displayPriority = .defaultLow
                if let cuisineEmoji = mapPin.cuisineEmoji {
                    glyphText = cuisineEmoji
                } else {
                    glyphText = "🍴"
                }
            }

            if isSelected {
                markerTintColor = defaultSelectedPinColor
                self.titleVisibility = .visible
                self.displayPriority = .required
            }
            else
            {
                if (mapPin.postRatingEmoji?.count ?? 0) > 0 {
                    markerTintColor = defaultLegitPinColor
                } else {
                    markerTintColor = defaultPinColor
                }
            }
            
            
            
            
            let postButton = UIButton(frame: CGRect(origin: CGPoint.zero,
                                                    size: CGSize(width: 30, height: 30)))
            
            if let ratingEmoji = mapPin.postRatingEmoji {
                postButton.setTitle(ratingEmoji, for: .normal)
            } else {
                postButton.addSubview(RatingLabel.init(ratingScore: mapPin.rating!, frame: CGRect(x: 0, y: 0, width: 30, height: 30)))
            }
            
            rightCalloutAccessoryView = postButton
           
        // CLUSTER SIMILAR RESTAURANT POSTS TOGETHER
            let locID = (mapPin.locationGoogleId == "") ? mapPin.locationName : mapPin.locationGoogleId
            clusteringIdentifier = String(describing: locID)

            
            self.setupSocialLabel(mapPin: mapPin)
            
        // ALWAYS SHOW ALL PINS IF FILTERING USER OR LIST
            if mapPin.alwaysShow {
                self.titleVisibility = .adaptive
                self.displayPriority = .required
            }
            else if (mapPin.isLegit && mapPin.locationName?.range(of: "GPS: ") == nil)
            {
                self.titleVisibility = .visible
//                self.displayPriority = .required
                self.displayPriority = .defaultHigh
//                clusteringIdentifier = String(describing: ClusterMapPinMarkerView.self)

            }
            else {
                self.titleVisibility = .hidden
                self.displayPriority = .defaultLow
//                clusteringIdentifier = "legitPosts"
            }

            
//            self.titleVisibility = .visible
//            self.displayPriority = .required
            
        }
    }
    
    override var isSelected: Bool {
        didSet {
//            markerTintColor = self.isSelected ? UIColor.red : UIColor.white
        }
    }
    
    
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


        /*
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
        }*/
        

        // SHOW EMOJIS
        if let emojis = mapPin.postEmojis
        {
            let emojiTitle = NSAttributedString(string: emojis, attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: socialCountFontSize)])
            attributedSocialText.append(emojiTitle)
        }
        
        
        
        // Bookmarks
        /*if (mapPin.listCount) > 0 {
            let listCountString = String(describing: mapPin.listCount)
            let attributedText = NSAttributedString(string: " \(listCountString) ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: socialCountFontSize)])
            
            attributedSocialText.append(attributedText)
            
            let listImage = NSTextAttachment()
            //            let listIcon = #imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate).resizeImageWith(newSize: imageSize)
            let listIcon = #imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate)
            
            listImage.bounds = CGRect(x: 0, y: (detailLabel.font.capHeight - listIcon.size.height).rounded() / 2, width: listIcon.size.width, height: listIcon.size.height)
            
            listImage.image = listIcon
            let listImageString = NSAttributedString(attachment: listImage)
            attributedSocialText.append(listImageString)
            self.tintColor = UIColor.ianLegitColor()
        }*/
        
        
        
        detailLabel.isUserInteractionEnabled = true
        detailLabel.tintColor = UIColor.ianLegitColor()
        detailLabel.attributedText = attributedSocialText
        
        detailCalloutAccessoryView = detailLabel
    }
    
    
    override func prepareForReuse() {
        glyphImage = nil
        glyphText = nil
        markerTintColor = UIColor.clear
        isSelected = false
        glyphTintColor = nil

    }
    
}
