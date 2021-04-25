//
//  UserProfilePhotoCell.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/29/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit

protocol ListPostSummaryGridPhotoCellDelegate {
    func didTapPicture(post:Post)
    
}

class ListPostSummaryGridPhotoCell: UICollectionViewCell, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    
    var delegate: ListPostSummaryGridPhotoCellDelegate?
    var post: Post? {
        didSet {
//            guard let imageUrl = post?.imageUrl else {
//                photoImageView.backgroundImage.isHidden = false
//                return}
            photoImageView.loadImage(urlString: (post?.imageUrls.first))
            setupAttributedSocialCount()
        }
    }

    
    let photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .lightBackgroundGrayColor()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
//        iv.backgroundImage.isHidden = false
        return iv
    }()

    
    var labelFontSize = 15 as CGFloat
    

    let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textColor = UIColor.darkGray
        label.backgroundColor = UIColor.clear
        label.textAlignment = .left
        return label
    }()
    
    let ratingLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textColor = UIColor.darkGray
        label.backgroundColor = UIColor.clear
        label.textAlignment = .right
        return label
    }()
    
    
    let distanceLabel: LightPaddedUILabel = {
        let label = LightPaddedUILabel()
        label.font = UIFont.boldSystemFont(ofSize: 10)
        label.textColor = UIColor.mainBlue()
        label.textAlignment = NSTextAlignment.left
        label.layer.cornerRadius = 1
        label.layer.borderWidth = 0
        label.layer.masksToBounds = true
        label.backgroundColor = UIColor.white.withAlphaComponent(0.75)
//        label.backgroundColor = UIColor.clear

        label.layer.cornerRadius = 5
        label.layer.borderWidth = 0
        label.layer.masksToBounds = true
        
//        label.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        return label
    }()
    
    var showDistance: Bool = false {
        didSet {
            refreshDistanceLabel()
        }
    }
    
    let ratingEmojiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textColor = UIColor.darkGray
        label.backgroundColor = UIColor.clear
        label.textAlignment = .left
        return label
    }()
    
    let locationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Poppins-Bold", size: 12)
        label.font = UIFont(font: .avenirNextMedium, size: 12)
        
        label.textColor = UIColor.darkGray
        label.backgroundColor = UIColor.clear
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 0
        return label
    }()
    
    

    var showDetails: Bool = true {
        didSet{
            hideDetailLayout?.isActive = !showDetails
            ratingContainer.isHidden = !showDetails
            locationView.isHidden = !showDetails
        }
    }

    var hideDetailLayout: NSLayoutConstraint?
    let detailView = UIView()
    let ratingContainer = UIView()
    let locationView = UIView()

    var starRatingLabel = RatingLabel(ratingScore: 0, frame: CGRect.zero)

    override init(frame: CGRect) {
        super.init(frame:frame)
        self.backgroundColor = UIColor.ianWhiteColor()
        
        addSubview(photoImageView)
        photoImageView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        photoImageView.heightAnchor.constraint(equalTo: photoImageView.widthAnchor, multiplier: 1.25).isActive = true
        
        hideDetailLayout = photoImageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        photoImageView.layer.cornerRadius = 5
        photoImageView.layer.masksToBounds = true
        
        /*
         // RATING AND EMOJI AND DISTANCE
         addSubview(ratingContainer)
         ratingContainer.anchor(top: photoImageView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 2, paddingRight: 0, width: 0, height: 30)
         
         
         ratingContainer.addSubview(ratingEmojiLabel)
         ratingEmojiLabel.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 2, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
         ratingEmojiLabel.centerYAnchor.constraint(equalTo: ratingContainer.centerYAnchor).isActive = true

         
         
         ratingContainer.addSubview(emojiLabel)
         emojiLabel.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
         emojiLabel.centerYAnchor.constraint(equalTo: ratingContainer.centerYAnchor).isActive = true
         
        
        

        addSubview(distanceLabel)
        distanceLabel.anchor(top: photoImageView.topAnchor, left: nil, bottom: nil, right: photoImageView.rightAnchor, paddingTop: 5, paddingLeft: 8, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        distanceLabel.isHidden = true
        */
        
//        addSubview(detailView)
//        detailView.anchor(top: photoImageView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)

   // LOCATION NAME
    
        
        addSubview(locationView)
        locationView.anchor(top: photoImageView.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)

        
//        locationView.addSubview(ratingLabel)
//        ratingLabel.anchor(top: nil, left: nil, bottom: nil, right: locationView.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 5, width: 25, height: 25)
//        ratingLabel.centerYAnchor.constraint(equalTo: locationView.centerYAnchor).isActive = true
//        ratingLabel.isHidden = false
        
        locationView.addSubview(locationLabel)
        locationLabel.anchor(top: locationView.topAnchor, left: locationView.leftAnchor, bottom: locationView.bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
//        locationLabel.centerYAnchor.constraint(equalTo: locationView.centerYAnchor).isActive = true
        

   
        
 
    }

    func setupAttributedSocialCount(){
        
        
        // RATING EMOJI
        ratingEmojiLabel.font = UIFont.systemFont(ofSize: labelFontSize)
        ratingEmojiLabel.text = post?.ratingEmoji ?? ""
        ratingEmojiLabel.text = ""
        ratingEmojiLabel.sizeToFit()

        // LOCATION NAME
        var locationName = ((post?.locationName == "") ? (post?.locationSummaryID ?? "") : post?.locationName) ?? ""
//        if let ratingEmoji = post?.ratingEmoji {
//            locationName += " \(ratingEmoji)"
//        }
        locationLabel.text = locationName
        locationLabel.sizeToFit()
        
        let imageSize = CGSize(width: labelFontSize, height: labelFontSize)
        
        
        
        // EMOJIS - LITTLE SMALLER?
        emojiLabel.font = UIFont.systemFont(ofSize: labelFontSize - 1)
        var emojiText = ""
        
        let attributedEmojiString = NSMutableAttributedString(string: "", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: labelFontSize), NSAttributedString.Key.foregroundColor: UIColor.darkGray])

//
//        if let ratingEmoji = post?.ratingEmoji {
//            attributedEmojiString.append(NSMutableAttributedString(string: ratingEmoji, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: labelFontSize), NSAttributedString.Key.foregroundColor: UIColor.darkGray]))
//        }
//
        var emojiString = (post?.emoji ?? "")
        emojiString += "  \(post?.ratingEmoji ?? "")"
        attributedEmojiString.append(NSMutableAttributedString(string: emojiString, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: labelFontSize - 1), NSAttributedString.Key.foregroundColor: UIColor.darkGray]))

        emojiLabel.attributedText = attributedEmojiString
        
        
        // RATING
        let ratingFontSize: CGFloat = 12
        
        
        let attributedString = NSMutableAttributedString(string: "", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: ratingFontSize), NSAttributedString.Key.foregroundColor: UIColor.darkGray])


        let postRating = min(post?.rating ?? 0, 5)
        starRatingLabel.rating = postRating
        starRatingLabel.isHidden = (postRating == 0)
        let ratingStringColor =  postRating <= 2 ? UIColor.lightGray : (postRating > 4 ? UIColor.ianLegitColor() : UIColor.darkGray)

        if postRating > 0 {
            let ratingString = postRating > 0 ? "\(String(postRating)) " : ""
            let ratingFont = UIFont(font: .arialRoundedMTBold, size: ratingFontSize)
            // UIFont(font: .arialRoundedMTBold, size: labelFontSize)
            // UIFont(name: "Poppins-Bold", size: labelFontSize)
            
            let attributedRating = NSMutableAttributedString(string: ratingString, attributes: [NSAttributedString.Key.font: ratingFont, NSAttributedString.Key.foregroundColor: ratingStringColor])
            attributedString.append(attributedRating)

            
            let ratingImage = postRating <= 2 ? #imageLiteral(resourceName: "cred_unfilled") : (postRating >= 4 ? #imageLiteral(resourceName: "full_star_red") : #imageLiteral(resourceName: "cred"))
            let starImage = NSTextAttachment()
            starImage.image = ratingImage.withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
            let starImageString = NSAttributedString(attachment: starImage)
            //attributedString.append(starImageString)
        }
        
    // Set RATING LABEL
        ratingLabel.isHidden = (postRating == 0)
        ratingLabel.layer.cornerRadius = 25/2
        ratingLabel.layer.masksToBounds = true
        ratingLabel.layer.borderColor = ratingStringColor.cgColor
//        ratingLabel.backgroundColor = ratingStringColor.withAlphaComponent(0.3)
        ratingLabel.layer.borderWidth = 0
        ratingLabel.textAlignment = .center

        ratingLabel.attributedText = attributedString
        ratingLabel.sizeToFit()
        
        
    // SET DISTANCE
        refreshDistanceLabel()
    }
    
    func refreshDistanceLabel(){
        distanceLabel.isHidden = !showDistance
//        ratingLabel.isHidden = showDistance
        distanceLabel.text = SharedFunctions.formatDistance(inputDistance: post?.distance)
        distanceLabel.sizeToFit()
    }
    
    func handlePictureTap() {
        guard let post = post else {return}
        print("Tap Picture")
        delegate?.didTapPicture(post: post)
    }
    
//    func handleLongPress(_ gestureReconizer: UILongPressGestureRecognizer) {
//
//        let animationDuration = 0.25
//
//        if socialHide {
//            if gestureReconizer.state != UIGestureRecognizer.State.recognized {
//                // Fade in Social Counts when held
//                UIView.animate(withDuration: animationDuration, animations: { () -> Void in
//                    self.socialCount.alpha = 1
//                }) { (Bool) -> Void in
//                }
//            }
//            else if gestureReconizer.state != UIGestureRecognizer.State.changed {
//                // Fade Out Social Counts when released
//                UIView.animate(withDuration: animationDuration, animations: { () -> Void in
//                self.socialCount.alpha = 0
//                }) { (Bool) -> Void in
//                }
//            }
//        }
//    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        //Flickering is caused by reused cell having previous photo or loading prior image request
        photoImageView.image = nil
        photoImageView.cancelImageRequestOperation()
        showDetails = true
        post = nil
        
    }
    
    
    
}
