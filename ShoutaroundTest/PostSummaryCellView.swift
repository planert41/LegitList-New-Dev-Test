//
//  PostSummaryCellView.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 6/29/20.
//  Copyright © 2020 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import Cosmos


protocol PostSummaryCellViewDelegate {
    func didTapPost(post: Post?)
}

class PostSummaryCellView: UIView {
    
    var post: Post? {
        didSet {
            guard let post = post else {return}
             if (post.images) != nil {
                 photoImageView.image = post.images![0]
             } else {
                 photoImageView.loadImage(urlString: (post.imageUrls.first)!)
             }
            
            // User Profile Image View
            let profileImageUrl = post.user.profileImageUrl
            userProfileImageView.loadImage(urlString: profileImageUrl)
            
            emojiArray.emojiLabels = []
            if let displayEmojis = self.post?.nonRatingEmoji{
                if displayEmojis.count > 0 {
                    emojiArray.emojiLabels = [displayEmojis[0]]
                }
            }

            //        print("UPDATED EMOJI ARRAY: \(emojiArray.emojiLabels)")
            emojiArray.setEmojiButtons()
            emojiArray.sizeToFit()
            
            // Location Name
            var locationNameDisplay: String? = ""
            let postLocationName = post.locationName
            // If no location  name and showing GPS, show the adress instead
            if postLocationName.hasPrefix("GPS"){
                locationNameDisplay?.append((post.locationAdress))
            } else {
                locationNameDisplay?.append(postLocationName.formatName())
            }
            
            if let ratingEmoji = self.post?.ratingEmoji {
                if extraRatingEmojis.contains(ratingEmoji) {
                    locationNameDisplay?.append(" \(ratingEmoji)")
                }
            }
            
            locationNameLabel.text = locationNameDisplay
            locationNameLabel.adjustsFontSizeToFitWidth = true
            locationNameLabel.sizeToFit()
         
            // Star Rating
            if (post.rating)! > 0 {
                starRating.rating = (post.rating)!
                starRating.isHidden = false
            } else{
                starRating.isHidden = true
            }
            
            // Caption
            captionLabel.text = post.caption.capitalizingFirstLetter()
            captionLabel.sizeToFit()
            
        }
    }
    
    var delegate: PostSummaryCellViewDelegate?
    
    let userProfileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        return iv
    }()
    
    let userProfileImageHeight: CGFloat = 25

    
    
    let photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .white
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        return iv
    }()
    
    let locationNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.font = UIFont(font: .verdanaBold, size: 14)
//        label.font = UIFont(font: .optimaBold, size: 14)

        label.numberOfLines = 1
        label.minimumScaleFactor = 0.5
        label.textColor = UIColor.ianBlackColor()
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.sizeToFit()
//        label.frame = CGRect(x: 0, y: 0, width: 100, height: 20)
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    let captionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.numberOfLines = 0
        //        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        //        label.sizeToFit()
        return label
    }()
    
    var emojiArray = EmojiButtonArray(emojis: [], frame: CGRect(x: 0, y: 0, width: 0, height: 15))

    let starRating: CosmosView = {
        let iv = CosmosView()
        iv.settings.fillMode = .half
        iv.settings.totalStars = 5
        //        iv.settings.starSize = 30
        iv.settings.starSize = 15
        iv.settings.updateOnTouch = false
        
        iv.settings.filledImage = #imageLiteral(resourceName: "ian_fullstar").withRenderingMode(.alwaysTemplate)
        iv.settings.emptyImage = #imageLiteral(resourceName: "ian_emptystar").withRenderingMode(.alwaysTemplate)
        iv.rating = 0
        iv.settings.starMargin = 1
        return iv
    }()
    
    let cellView = UIView()
    
    var tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapPost))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.ianWhiteColor()
        layer.cornerRadius = 5
        clipsToBounds = true
        layer.borderColor = UIColor.darkGray.cgColor
        layer.borderWidth = 1
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapPost)))

    // ADD POST IMAGE
        addSubview(photoImageView)
        photoImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        photoImageView.widthAnchor.constraint(equalTo: photoImageView.heightAnchor, multiplier: 1).isActive = true
        photoImageView.layer.cornerRadius = 5
        photoImageView.layer.masksToBounds = true
        photoImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapPost)))

//    // Add User Profile Image
        addSubview(userProfileImageView)
//        userProfileImageView.anchor(top: photoImageView.topAnchor, left: photoImageView.leftAnchor, bottom: nil, right: nil, paddingTop: -8, paddingLeft: -8, paddingBottom: 0, paddingRight: 10, width: userProfileImageHeight, height: userProfileImageHeight)
        userProfileImageView.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 8, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: userProfileImageHeight, height: userProfileImageHeight)
        userProfileImageView.layer.cornerRadius = userProfileImageHeight/2
        userProfileImageView.clipsToBounds = true
        userProfileImageView.layer.borderWidth = 0.25
        userProfileImageView.layer.borderColor = UIColor.legitColor().cgColor
        
        
        
        addSubview(locationNameLabel)
        locationNameLabel.anchor(top: topAnchor, left: photoImageView.rightAnchor, bottom: nil, right: userProfileImageView.leftAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 20)
        locationNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapPost)))
        locationNameLabel.sizeToFit()
        
        let ratingView = UIView()
        addSubview(ratingView)
        ratingView.anchor(top: locationNameLabel.bottomAnchor, left: locationNameLabel.leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 15)
        ratingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapPost)))

        ratingView.addSubview(starRating)
        starRating.anchor(top: ratingView.topAnchor, left: ratingView.leftAnchor, bottom: ratingView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        starRating.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapPost)))

        // ADD EMOJIS
        ratingView.addSubview(emojiArray)
        emojiArray.anchor(top: ratingView.topAnchor, left: starRating.rightAnchor, bottom: ratingView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 15)
//        emojiArray.delegate = self
        emojiArray.alignment = .left
            

        
        // CAPTION
        addSubview(captionLabel)
        captionLabel.anchor(top: ratingView.bottomAnchor, left: ratingView.leftAnchor, bottom: bottomAnchor, right: ratingView.rightAnchor, paddingTop: 3, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
//        captionLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: 3).isActive = true
//        captionLabel.topAnchor.constraint(lessThanOrEqualTo: ratingView.bottomAnchor).isActive = true
        captionLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapPost)))

//        let tapView = UIView()
//        addSubview(tapView)
//        tapView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        tapView.backgroundColor = UIColor.clear
//        tapView.isUserInteractionEnabled = true
//        tapView.addGestureRecognizer(tapGesture)
        
    }
    
    @objc func didTapPost() {
        guard let post = post else {return}
        self.delegate?.didTapPost(post: post)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
    
    
    
}
