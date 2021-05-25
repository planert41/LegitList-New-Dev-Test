//
//  SharePhotoController.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/28/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit

import CoreLocation
import GeoFire
import GoogleMaps
import SwiftyJSON
import SwiftLocation
import Alamofire
import GooglePlaces
import Cosmos
import SKPhotoBrowser
import CLImageEditor
import CropViewController
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

enum emojiFilterTypes: String {
    case auto
    case recent
    case food
    case drink
    case snack
    case raw
    case veg
    case flag
    case other
}


class MultSharePhotoController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate,UICollectionViewDataSource, UITextViewDelegate, UIGestureRecognizerDelegate, GMSAutocompleteViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, SKPhotoBrowserDelegate, AutoTagTableViewControllerDelegate, CLImageEditorDelegate, CropViewControllerDelegate, UITextFieldDelegate, UIScrollViewDelegate, EmojiSearchTableViewControllerDelegate {

    static let updateFeedNotificationName = NSNotification.Name(rawValue: "UpdateFeed")

    
// Setup Default Variables
    
    let currentDateTime = Date()
    let locationManager = CLLocationManager()
    let emojiCollectionViewRows: Int = 4
    let DefaultEmojiLabelSize = 25 as CGFloat
    let nonRatingEmojiLimit = 5
    
    let locationCellID = "locationCellID"
    let emojiCellID = "emojiCellID"
    let testemojiCellID = "testemojiCellID"
    let emojiFilterCellID = "emojiFilterCellID"

//    let captionDefault = "Was it Legit👌? \n\nAdd Emoji tags. Create a list."

    let captionDefault = "What did you eat? \nHow good was it?"
    let emojiDefault = "👌🇺🇸🥓🍔🍟"
    var blankGPSName: String = defaultEmptyGPSName
    var selectedEmojiFilterOptions = ["Recent", "Food", "Drink", "Snack", "Raw", "Veg", "Smiley", "Flag"]
    var selectedEmojiFilter: String? = nil {
        didSet {
            filterEmojiButton.setImage((self.selectedEmojiFilter != nil ? #imageLiteral(resourceName: "filterclear") : #imageLiteral(resourceName: "filter")).withRenderingMode(.alwaysOriginal), for: .normal)
            self.filterEmojiSelections()
        }
    }
    
    // Location Adress is setup as default image location name
    
// Information from image
    var selectedImages: [UIImage]? {
        didSet{
            guard let selectedImages = selectedImages else {
                self.alert(title: "Error", message: "No Photos Selected")
                self.dismiss(animated: true, completion: nil)
                return}
            
            self.imageView.image = selectedImages[0]
            self.updateScrollImages()
            self.setupImageCountLabel()
            
            if selectedImages.count > 1 {
                self.photoCountImage.isHidden = false
//                self.photoCountLabel.text = String(selectedImages.count)
//                self.photoCountLabel.sizeToFit()
                self.photoCountLabel.isHidden = false
            } else {
                self.photoCountLabel.isHidden = true
                self.photoCountImage.isHidden = true
            }
        }
    }
    
    var selectedImageLocation:CLLocation?{
        didSet{
            // Finds Adress and Restaurants near image GPS
            if selectedImageLocation != nil && (selectedImageLocation?.coordinate.latitude != 0) && (selectedImageLocation?.coordinate.longitude != 0){
                Database.reverseGPSApple(GPSLocation: selectedImageLocation) { (location) in
                    self.selectedImageLocationItem = location
                    self.selectedPostLocationItem = location
                }
            }
        }
    }
    
    var selectedImageLocationItem: Location? = nil

    
    var nearbyGoogleLocations: [Location] = [] {
        didSet {
            self.placesCollectionView.reloadData()
        }
    }
    
    var selectedImageTime: Date? {
        didSet{
            if selectedImageTime == nil {
                self.selectTime = currentDateTime
                print("No Image Time, Defaulting to Current Upload Time: \(currentDateTime)")
            } else {
                self.selectTime = selectedImageTime!
                print("Setting Post Time to Selected Image Creation Time: \(selectedImageTime)")
            }
        }
    }

    
// Editing Post Information
    
    var editPostInd: Bool = false
    var editPost: Post? = nil {
        didSet{
            // Upload Name Adress that matches inputs
            guard let uid = Auth.auth().currentUser?.uid else {return}
            
//            self.editPostImageUrl = editPost?.imageUrl
            self.editPostImageUrls = (editPost?.imageUrls)!
            
            // Post Location Details
            self.selectPostLocation = editPost?.locationGPS
            self.googleLocationSearch(GPSLocation: self.selectPostLocation)
            self.selectPostLocationName = editPost?.locationName
            self.selectPostLocationAdress = editPost?.locationAdress
            self.selectPostlocationSummaryID = editPost?.locationSummaryID
            self.selectPostGooglePlaceID = editPost?.locationGooglePlaceID
            
            // Caption
            if editPost?.caption == "" {
                self.captionTextView.text = captionDefault
            } else {
                self.captionTextView.text = editPost?.caption
            }
            
            // Rating
            self.selectPostStarRating = editPost?.rating ?? 0
            
            // Legit
//            self.isLegit = editPost?.isLegit ?? false
            
            // Lists
            self.postList = editPost?.creatorListId
            
            // Emojis
            self.nonRatingEmojiTags = (editPost?.nonRatingEmoji)!
            self.nonRatingEmojiTagsDict = (editPost?.nonRatingEmojiTags)!
            
            let uploadTime = Date().timeIntervalSince1970
            
            self.selectPostPrice = editPost?.price
            if self.selectPostPrice != nil {
                self.postPriceSegment.selectedSegmentIndex = UploadPostPriceDefault.firstIndex(of: selectPostPrice!)!
            }
            
            self.mealTagEmojis = []
            self.cuisineTagEmojis = []
            self.dietTagEmojis = []
            
            if (editPost?.autoTagEmoji.count)! > 0 {

                for tag in (editPost?.autoTagEmoji)! {
                    if mealEmojisSelect.contains(tag) {
                        self.mealTagEmojis.append(EmojiBasic(emoji: tag, name: mealEmojiDictionary[tag], count: 0))
                    }
                    
                    else if cuisineEmojiSelect.contains(tag) {
                        self.cuisineTagEmojis.append(EmojiBasic(emoji: tag, name: cuisineEmojiDictionary[tag], count: 0))
                    }
                    
                    else if dietEmojiSelect.contains(tag) {
                        self.dietTagEmojis.append(EmojiBasic(emoji: tag, name: dietEmojiDictionary[tag], count: 0))
                    }
                }
                
                self.updateAllAutoTags()
                print("EditPost | \(editPost?.id) | AutoTagEmojis \(editPost?.autoTagEmoji) | \(self.allAutoTagEmojis.count) Loaded")
            }
        }
    }
    
    var editPostImageUrls: [String] = [] {
        didSet{
            // Load image URL for editing. New posts will not have imageUrl
            if editPostImageUrls.count > 0 {
                self.imageView.loadImage(urlString: editPostImageUrls.first!)
                
                var tempImages: [UIImage] = []
                var tempImageView = CustomImageView()
                let myGroup = DispatchGroup()

                for url in editPostImageUrls {
                    tempImageView.loadImage(urlString: url)
                    myGroup.enter()
                    if let image = tempImageView.image {
                        tempImages.append(image)
                        myGroup.leave()
                    } else {
                        Database.fetchImage(urlString: url) { (image) in
                            if image != nil {
                                tempImages.append(image!)
                            }
                            myGroup.leave()
                        }
                    }
                }

                myGroup.notify(queue: .main) {
                    print("Selected Images")
                    self.selectedImages = tempImages
                }
                
                self.selectedImages = tempImages
                print("Selected Images | \(self.selectedImages?.count)")

                
            }
        }
    }
    
    var editPostId: String? = nil
    
// Selected Post Location Info
    
    var selectedPostLocationItem: Location? = nil {
        didSet {
            
            print("Selected Location | \(selectedPostLocationItem?.locationName)")
            print("Selected Location | \(selectedPostLocationItem?.locationAdress)")
            print("Selected Location | \(selectedPostLocationItem?.locationSummaryID)")

            if selectedPostLocationItem == nil {
                self.clearSelectPostLocation()
            } else {
                self.updateLocation(location: selectedPostLocationItem)
            }
            
            // If Selected Location does not have Summary ID (City ID)
            if selectedPostLocationItem != nil && selectedPostLocationItem?.locationSummaryID == nil{
                Database.reverseGPSApple(GPSLocation: selectedPostLocationItem?.locationGPS) { (temp_location) in
                    self.selectedPostLocationItem?.locationSummaryID = temp_location?.locationSummaryID
                    print("selectedPostLocationItem | Auto-Fill Location Summary ID | ", self.selectedPostLocationItem?.locationSummaryID)
                }
            }
        }
    }
    
    // Google Look Up Adress of current coordinates
//    var imageLocationGoogleAdress: String?
    
    // Google Place ID
    var selectPostGooglePlaceID: String? = nil {
        didSet{
            /*
             When a google place ID is selected:
             1) Queries Google for reviews and extracts them into array of words
             2) Identify emojis based on word array, assigns auto-tag cuisine emoji and review suggested emojis
             3) After review suggested emojis are created, extracts other emojis tagged at google location
             4) Creates a suggested emoji list and refreshes emoji collectionview
             
             Otherwise, suggested emojis is set as current user's most used emojis
             
            */
            guard let selectPostGooglePlaceID = selectPostGooglePlaceID else {return}
            if selectPostGooglePlaceID != ""{
                self.downloadRestaurantDetails(googlePlaceID: selectPostGooglePlaceID)
            }
        }
    }
    var selectPostGoogleLocationType: [String]? = nil
    
    var selectPostLocation: CLLocation? = nil
    var selectPostLocationName:String? {
        didSet {
            locationNameLabel.text = selectPostLocationName
        }
    }
    var selectPostlocationSummaryID: String?
    var selectPostLocationAdress:String? {
        didSet {
            if selectPostLocationName != selectPostLocationAdress && selectPostLocationAdress != nil {
                locationAdressLabel.text = selectPostLocationAdress
                locationAdressLabelHeightConstraint?.isActive = false
            }
            
            else if selectPostLocationName == selectPostLocationAdress && selectPostLocationAdress != nil {
                // Adress is location name. Split by road and city
                let fulladress = selectPostLocationAdress
                if let firstComma = fulladress?.indicesOf(string: ",")[0] {
                    let name = fulladress?.prefix(firstComma)
                    let city = fulladress?.suffix((fulladress?.count)! - firstComma - 2)
                    
                    locationNameLabel.text = String(name!)
                    locationAdressLabel.text = String(city!)
                    locationAdressLabelHeightConstraint?.isActive = false
                } else {
                    locationNameLabel.text = selectPostLocationAdress
                    locationAdressLabelHeightConstraint?.isActive = true
                }
            }
            else {
                locationAdressLabel.text = ""
                locationAdressLabelHeightConstraint?.isActive = true
            }
//            locationAdressLabel.sizeToFit()
        }
    }
    
    func clearSelectPostLocation(){
        self.selectPostLocation = nil
        self.selectPostLocationName = self.blankGPSName
        self.selectPostLocationAdress = nil
        self.selectPostlocationSummaryID = nil
        self.selectPostGooglePlaceID = nil
        self.selectPostGoogleLocationType = []
        self.locationMostUsedEmojis = []
        self.cuisineTagEmojis = []
        self.lookupLocationMostUsedEmojis()
        
        self.locationCancelButton.isHidden = true
        self.addLocationButton.isHidden = true
        self.findCurrentLocationButton.isHidden = false
    }
    
    let addLocationButton: UIButton = {
        let btn = UIButton()
//        btn.setImage(#imageLiteral(resourceName: "plus_unselected").withRenderingMode(.alwaysOriginal), for: .normal)
        btn.layer.cornerRadius = CGFloat(20 / 2)
        btn.clipsToBounds = true
        btn.backgroundColor = UIColor.legitColor().withAlphaComponent(0.8)
        btn.layer.borderColor = UIColor.selectedColor().cgColor
        btn.layer.borderWidth = 0
        btn.setTitle("+Name", for: .normal)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 10)

//        btn.setTitleColor(UIColor.legitColor(), for: .normal)
        let attributedString = NSMutableAttributedString(string: "+NEW", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .avenirNextDemiBold, size: 10)]))
        btn.setAttributedTitle(attributedString, for: .normal)
        
        btn.addTarget(self, action: #selector(openAddLocationNameInput), for: .touchUpInside)
        return btn
    }()
    
// Legit Rating
    

    
    let extraRatingButton: UIButton = {
        let btn = UIButton()
//        btn.setImage(#imageLiteral(resourceName: "legit").withRenderingMode(.alwaysOriginal), for: .normal)
//        btn.setTitle("👌", for: .normal)
        btn.setImage(#imageLiteral(resourceName: "legit_large"), for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 30)
//        btn.backgroundColor = UIColor.mainBlue().withAlphaComponent(0.2)
        btn.alpha = 0.25
        btn.addTarget(self, action: #selector(showExtraRating), for: .touchUpInside)
        btn.layer.masksToBounds = true
//        btn.contentVerticalAlignment = UIControlContentVerticalAlignment.center
//        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignment.center
        btn.layer.borderColor = UIColor.ianLegitColor().cgColor
        btn.layer.borderWidth = 1

        return btn
    }()
    
    @objc func showExtraRating(){
        
        if self.extraRatingEmojiCollectionView.isHidden {
            // Fade in the view
            print("Show Extra Rating Emoji Collection View")
            self.showExtraRatingCollectionView()
            self.extraRatingEmojiCollectionView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            UIView.animate(withDuration: 1.0,
                           delay: 0,
                           usingSpringWithDamping: 0.2,
                           initialSpringVelocity: 6.0,
                           options: .allowUserInteraction,
                           animations: { [weak self] in
                            self?.extraRatingEmojiCollectionView.transform = .identity
                            self?.extraRatingEmojiCollectionView.layoutIfNeeded()
                            
                },
                           completion: nil)
        } else {
            self.hideExtraRatingCollectionView()
        }

    }
    
    @objc func clearExtraRating(){
        self.ratingEmojiTag = ""
    }
    
    
    var ratingEmojiTag: String = "" {
        didSet {
            if self.ratingEmojiTag == "" {
                //                self?.extraRatingButton.setTitle(👌, for: .normal)
                //                self?.extraRatingButton.alpha = 1
                
                //                self.extraRatingButton.setTitle("👌", for: .normal)
//                self.extraRatingButton.backgroundColor = UIColor.mainBlue().withAlphaComponent(0.2)
//                self.extraRatingButton.layer.borderWidth = 1
                self.extraRatingButton.backgroundColor = UIColor.clear
                self.extraRatingButton.alpha = 0.25
                self.extraRatingButton.setTitle(nil, for: .normal)
                self.extraRatingButton.setImage(#imageLiteral(resourceName: "legit_large"), for: .normal)
                
            } else {
                self.extraRatingButton.backgroundColor = UIColor.selectedColor().withAlphaComponent(0.8)
                self.extraRatingButton.alpha = 1
                self.extraRatingButton.layer.borderWidth = 1
                self.extraRatingButton.setTitle(self.ratingEmojiTag, for: .normal)
                self.extraRatingButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                UIView.animate(withDuration: 1.0,
                               delay: 0,
                               usingSpringWithDamping: 0.2,
                               initialSpringVelocity: 6.0,
                               options: .allowUserInteraction,
                               animations: { [weak self] in
                                self?.extraRatingButton.setImage(UIImage(), for: .normal)
                                self?.extraRatingButton.transform = .identity
                                self?.extraRatingButton.layoutIfNeeded()
                                
                    },
                               completion: nil)
                
            }
        }
    }

    
    
// Star Rating
    
    var selectPostStarRating: Double = 0 {
        didSet{
            self.starRating.rating = selectPostStarRating
            self.starRatingLabel.rating = selectPostStarRating
//            self.starRatingLabel.rating = selectPostStarRating
        }
    }
    
    let starRating: CosmosView = {
        let iv = CosmosView()
        iv.settings.fillMode = .half
        iv.settings.totalStars = starRatingCountDefault
//        iv.settings.starSize = 30
        iv.settings.starSize = 40

//        iv.settings.filledImage = #imageLiteral(resourceName: "ratingstarfilled").withRenderingMode(.alwaysOriginal)
//        iv.settings.emptyImage = #imageLiteral(resourceName: "ratingstarunfilled").withRenderingMode(.alwaysOriginal)
        iv.settings.filledImage = #imageLiteral(resourceName: "star_rating_filled_mid").withRenderingMode(.alwaysOriginal)
        iv.settings.emptyImage = #imageLiteral(resourceName: "star_rating_unfilled").withRenderingMode(.alwaysOriginal)
        iv.rating = 0
        iv.settings.starMargin = 3
        return iv
    }()
    
    var starRatingLabel = RatingLabelNew(ratingScore: 0, frame: CGRect.zero)

    func starRatingSelectFunction(rating: Double) {
        print("Selected Rating: \(rating)")
        if rating >= 4 {
            starRating.settings.filledImage = #imageLiteral(resourceName: "star_rating_filled_high").withRenderingMode(.alwaysOriginal)
        } else {
            starRating.settings.filledImage = #imageLiteral(resourceName: "star_rating_filled_mid").withRenderingMode(.alwaysOriginal)
        }
        
        self.selectPostStarRating = rating
    }
    
    func cancelStarRating(){
        self.selectPostStarRating = 0
//        self.starRatingLabel.rating = 0
    }
    
// Post Type Variable
    var selectTime: Date = Date() {
        didSet{
            self.guessPostType()
        }
    }
    
    func guessPostType(){
        // Select Time should default to current upload time if no image time
        
        Database.guessPostMeal(googleLocationType: self.selectPostGoogleLocationType, currentTime: self.selectTime) { (guessEmoji) in
            
            guard let emoji = guessEmoji else {
                return
            }
            
            print("guessPostType | \(emoji)")
            self.mealTagEmojis = [emoji]
        }
    }
    


// Tag Selection
    
    let emojiHeaderLabel: UILabel = {
        let tv = UILabel()
        tv.font = UIFont(font: .avenirNextDemiBold, size: 18)
        tv.textColor = UIColor.legitColor()
        tv.text = "Tag Your Food"
        tv.backgroundColor = UIColor.clear
        tv.textAlignment = NSTextAlignment.left
        return tv
    }()
    
// USER MOST USED EMOJI
    
    var showUserMostUsedEmojiInd: Bool = false
    let userMostUsedEmojiButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("🙋‍♂️", for: .normal)
        let attributedString = NSMutableAttributedString(string: "🙋‍♂️ User Suggested", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.legitColor(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .helveticaNeueBold, size: 10)]))
        button.setAttributedTitle(attributedString, for: .normal)
        button.backgroundColor = UIColor.lightGray
        button.layer.cornerRadius = 6
        button.layer.masksToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.addTarget(self, action: #selector(showUserMostUsedEmojis), for: .touchUpInside)
        return button
    }()
    
// LOCATION SUGGESTED EMOJI
    
    var showlocationMostUsedEmojiInd: Bool = false
    let locationMostUsedEmojiButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("🏠", for: .normal)
        let attributedString = NSMutableAttributedString(string: "🏠 Location Suggested", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.legitColor(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .helveticaNeueBold, size: 10)]))
        button.setAttributedTitle(attributedString, for: .normal)
        button.backgroundColor = UIColor.lightGray
        button.layer.cornerRadius = 6
        button.layer.masksToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.addTarget(self, action: #selector(showLocationSuggestedEmojis), for: .touchUpInside)
        return button
    }()

    
    let emojiInfoButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "info.png"), for: .normal)
        button.tintColor = UIColor.lightGray
        button.tag = 0
        button.addTarget(self, action: #selector(openInfo(sender:)), for: .touchUpInside)
        return button
    }()
    
    let extraRatingInfoButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "info.png"), for: .normal)
        button.tintColor = UIColor.lightGray
        button.tag = 2
        button.addTarget(self, action: #selector(openInfo(sender:)), for: .touchUpInside)
        return button
    }()
    
    let selectedEmojiTag: UITextField = {
        let tv = UITextField()
        tv.attributedPlaceholder = NSMutableAttributedString(string: "", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .avenirNextDemiBold, size: 20), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.red]))
        tv.backgroundColor = UIColor.legitColor()
        tv.backgroundColor = UIColor.init(hexColor: "ffa34d")
        tv.backgroundColor = UIColor.init(hexColor: "f1c40f")
        tv.backgroundColor = UIColor.selectedColor().withAlphaComponent(0.8)

        tv.textAlignment = NSTextAlignment.center
        tv.layer.borderColor = UIColor.init(hexColor: "fcc250").cgColor
        tv.layer.borderColor = UIColor.init(hexColor: "f1c40f").cgColor

        tv.layer.borderWidth = 4
        tv.alpha = 0.5
        tv.tag = 0
        return tv
    }()
    
    let selectedEmojiTag2: UITextField = {
        let tv = UITextField()
//        tv.attributedPlaceholder = NSMutableAttributedString(string: "🍟", attributes: [NSFontAttributeName: UIFont(font: .noteworthyBold, size: 20), NSForegroundColorAttributeName: UIColor.red])
        //        tv.backgroundColor = UIColor.legitColor().withAlphaComponent(0.5)
        tv.alpha = 0.5
        tv.textAlignment = NSTextAlignment.center
        tv.layer.borderColor = UIColor.init(hexColor: "fdcb6e").cgColor
        
        tv.backgroundColor = UIColor.init(hexColor: "ffe5cc")
        tv.layer.borderColor = UIColor.init(hexColor: "fcc250").cgColor
        tv.layer.borderWidth = 1

        tv.tag = 1

        return tv
    }()
    
    let selectedEmojiTag3: UITextField = {
        let tv = UITextField()
//        tv.attributedPlaceholder = NSMutableAttributedString(string: "🍕", attributes: [NSFontAttributeName: UIFont(font: .noteworthyBold, size: 20), NSForegroundColorAttributeName: UIColor.red])
        //        tv.backgroundColor = UIColor.legitColor().withAlphaComponent(0.5)
        tv.alpha = 0.5
        tv.textAlignment = NSTextAlignment.center
        
        tv.backgroundColor = UIColor.init(hexColor: "ffe5cc")
        tv.layer.borderColor = UIColor.init(hexColor: "fcc250").cgColor
        tv.layer.borderWidth = 1

//        tv.backgroundColor = UIColor.white
//        tv.layer.borderColor = UIColor.init(hexColor: "ffb266").cgColor
//        tv.layer.borderWidth = 1

        tv.tag = 2

        return tv
    }()
    
    var selectedEmojiTagArray: [UITextField] = []
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField.text == "" {
            self.openInfo(sender: self.emojiInfoButton)
            return false
        }
        else if self.selectedEmojiTagArray.contains(textField) {
            self.tappedEmojiLabel(emoji: textField.text)
            return false
        } else {
            return true
        }
    }
    
    
    func tappedEmojiLabel(emoji:String?){
        
        var tempEmojiText: String = ""
        var tempEmojiTitle: String = "Emoji Options"
        
        if let _ = emoji {
            tempEmojiText = emoji!
            
            if let tempEmojiDic = EmojiDictionary[tempEmojiText] {
                tempEmojiTitle = "\(tempEmojiText) \(tempEmojiDic)"
            }
        }
        
        let optionsAlert = UIAlertController(title: tempEmojiTitle, message: "", preferredStyle: UIAlertController.Style.alert)
        
        
        optionsAlert.addAction(UIAlertAction(title: "Untag \(tempEmojiText)", style: .default, handler: { (action: UIAlertAction!) in
//            self.emojiTagUntag(emojiInput: emoji, emojiInputTag: nil)
            self.addRemoveEmojiTags(emojiInput: emoji, emojiInputTag: nil)
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Untag All Emojis", style: .default, handler: { (action: UIAlertAction!) in
//            self.emojiTagUntag(emojiInput: nil, emojiInputTag: nil)
            self.addRemoveEmojiTags(emojiInput: nil, emojiInputTag: nil)

        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        present(optionsAlert, animated: true) {
            optionsAlert.view.superview?.isUserInteractionEnabled = true
            optionsAlert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.alertClose(gesture:))))
        }
        
    }
    
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var result = true
        
        if textField == selectedEmojiTag {
            let maxLength = 1
            let char = string.cString(using: String.Encoding.utf8)!
            let isBackSpace = strcmp(char, "\\b")
            
            if string.containsOnlyEmoji {
                self.addRemoveEmojiTags(emojiInput: string, emojiInputTag: nil)
                return false
            } else if isBackSpace == -92 {
                self.addRemoveEmojiTags(emojiInput: nil, emojiInputTag: nil)
                return true
            }  else {
                return false
            }
        }
        
        return true
    }
    

    var emojiTagSelection: [String] = allFoodEmojis
    
    
// Auto-Tag Variables
    
    let autoTagDetailId = "AutoTagDetail"
//    let autoTagSelectColor = UIColor.init(hexColor: "cc701a")
    let autoTagSelectColor = UIColor.legitColor()

    var allAutoTagEmojis: [EmojiBasic] = []

    func updateAllAutoTags(){
        print("AllAutoTag | \(self.allAutoTagEmojis)")
        self.allAutoTagEmojis = self.mealTagEmojis + self.cuisineTagEmojis + self.dietTagEmojis

        if self.mealTagEmojis.count > 0 {
            self.mealTagButton.setTitleColor(autoTagSelectColor, for: .normal)
            self.mealTagButton.alpha = 1
            self.cancelMealTagButton.isHidden = false
        } else {
            self.mealTagButton.setTitleColor(UIColor.lightGray, for: .normal)
            self.mealTagButton.alpha = 0.75
            self.cancelMealTagButton.isHidden = true
        }
        
        if self.cuisineTagEmojis.count > 0 {
            self.cuisineTagButton.setTitleColor(autoTagSelectColor, for: .normal)
            self.cuisineTagButton.alpha = 1
            self.cancelCuisineTagButton.isHidden = false
        } else {
            self.cuisineTagButton.setTitleColor(UIColor.lightGray, for: .normal)
            self.cuisineTagButton.alpha = 0.75
            self.cancelCuisineTagButton.isHidden = true
        }
        
        if self.dietTagEmojis.count > 0 {
            self.dietTagButton.setTitleColor(autoTagSelectColor, for: .normal)
            self.dietTagButton.alpha = 1
            self.cancelDietTagButton.isHidden = false
        } else {
            self.dietTagButton.setTitleColor(UIColor.lightGray, for: .normal)
            self.dietTagButton.alpha = 0.75
            self.cancelDietTagButton.isHidden = true
        }
        
        self.mealTypeCollectionView.reloadData()
        self.cuisineTypeCollectionView.reloadData()
        self.dietTypeCollectionView.reloadData()
        
        self.refreshEmojiTagSelections()
    }
    
    
    @objc func clearAutoTagEmojis(){
        mealTagEmojis = []
        cuisineTagEmojis = []
        dietTagEmojis = []
    }
    
    let autoTagLabel: UILabel = {
        let tv = UILabel()
        tv.font = UIFont(font: .avenirNextDemiBold, size: 18)
        tv.textColor = UIColor.legitColor()
        tv.text = "Additional Tags"
        tv.backgroundColor = UIColor.clear
        tv.textAlignment = NSTextAlignment.left
        return tv
    }()
    
    let autoTagInfoButton: UIButton = {
        let button = UIButton(type: .system)
//        button.setImage(#imageLiteral(resourceName: "info.png").withRenderingMode(.alwaysOriginal), for: .normal)
        button.setImage(#imageLiteral(resourceName: "info.png"), for: .normal)
        button.tag = 1
        button.addTarget(self, action: #selector(openInfo(sender:)), for: .touchUpInside)
        return button
    }()
    
    var autoTagCollectionViews: [UICollectionView] = []
    
    // Post Price Variable
    
    let priceTagButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Price", for: .normal)
        button.titleLabel?.font = UIFont(font: .avenirNextDemiBold, size: 15)
        button.setTitleColor(UIColor.legitColor(), for: .normal)
        //        button.addTarget(self, action: #selector(openAutoTag(sender:)), for: .touchUpInside)
        button.tag = 0
        button.alpha = 0.5
        button.backgroundColor = UIColor.clear
        return button
    } ()
    
    var selectedPostPriceIndex: Int? = nil
    var selectPostPrice: String? = nil
    
    var postPriceSegment: ReselectableSegmentedControl = {
        var segment = ReselectableSegmentedControl(items: UploadPostPriceDefault)
        segment.addTarget(self, action: #selector(handleSelectPostPrice), for: .valueChanged)
        segment.tintColor = UIColor.rgb(red: 223, green: 85, blue: 78)
        segment.tintColor = UIColor.lightGray.withAlphaComponent(0.75)
        segment.selectedSegmentIndex = UISegmentedControl.noSegment
        return segment
    }()
    
    @objc func handleSelectPostPrice(sender: UISegmentedControl) {
        if (sender.selectedSegmentIndex == self.selectedPostPriceIndex) {
            sender.selectedSegmentIndex =  UISegmentedControl.noSegment
            self.selectPostPrice = nil
        }
        else {
            self.selectPostPrice = UploadPostPriceDefault[sender.selectedSegmentIndex]
        }
        print("Selected Time is ",self.selectPostPrice)
    }
    
    
    
// Meals (Breakfast, Lunch, Dinner)
    
    var mealTagEmojis: [EmojiBasic] = [] {
        didSet{
            self.updateAllAutoTags()
        }
    }
    
    let mealTagButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Type", for: .normal)
        button.titleLabel?.font = UIFont(font: .avenirNextDemiBold, size: 15)
        button.addTarget(self, action: #selector(openAutoTag(sender:)), for: .touchUpInside)
        button.tag = 0
        button.alpha = 0.5
        button.backgroundColor = UIColor.clear
        button.setTitleColor(UIColor.lightGray, for: .normal)
        return button
    } ()
    
    let cancelMealTagButton: UIButton = {
        let button = UIButton(type: .system)
        button.tag = 0
        button.setImage(#imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(cancelAutoTag(sender:)), for: .touchUpInside)
        return button
    }()
    
    let mealTypeCollectionView: UICollectionView = {
        let uploadLocationTagList = UploadLocationTagList()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadLocationTagList)
        return cv
    }()
    

// Cuisine (American, Chinese, Japanese)
    
    var cuisineTagEmojis: [EmojiBasic] = [] {
        didSet{
            print("cuisineTagEmojis | ",cuisineTagEmojis)
            self.updateAllAutoTags()
        }
    }
    
    let cuisineTagButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cuisine", for: .normal)
        button.titleLabel?.font = UIFont(font: .avenirNextDemiBold, size: 15)
        button.addTarget(self, action: #selector(openAutoTag(sender:)), for: .touchUpInside)
        button.tag = 1
        button.alpha = 0.5
        button.backgroundColor = UIColor.clear
        button.setTitleColor(UIColor.lightGray, for: .normal)
        return button
    } ()
    
    let cancelCuisineTagButton: UIButton = {
        let button = UIButton(type: .system)
        button.tag = 1
        button.setImage(#imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(cancelAutoTag(sender:)), for: .touchUpInside)
        return button
    }()
    
    let cuisineTypeCollectionView: UICollectionView = {
        let uploadLocationTagList = UploadLocationTagList()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadLocationTagList)
        return cv
    }()
    
    // Diet Restrictions (Halal, Vegetarian)
    
    var dietTagEmojis: [EmojiBasic] = [] {
        didSet{
            self.updateAllAutoTags()
        }
    }
    
    let dietTagButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Diet", for: .normal)
        button.titleLabel?.font = UIFont(font: .avenirNextDemiBold, size: 15)
        button.addTarget(self, action: #selector(openAutoTag(sender:)), for: .touchUpInside)
        button.tag = 2
        button.alpha = 0.5
        button.backgroundColor = UIColor.clear
        button.setTitleColor(UIColor.lightGray, for: .normal)
        return button
    } ()
    
    let cancelDietTagButton: UIButton = {
        let button = UIButton(type: .system)
        button.tag = 2
        button.setImage(#imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(cancelAutoTag(sender:)), for: .touchUpInside)
        return button
    }()
    
    let dietTypeCollectionView: UICollectionView = {
        let uploadLocationTagList = UploadLocationTagList()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadLocationTagList)
        return cv
    }()


    @objc func openInfo(sender : UIButton){
        print("Open Info | \(sender.tag)")
        if sender.tag == 0 {
            // Emoji Info
            self.alert(title: "Emoji Tagging", message: """
Tag your post with up to 3 Emojis.
Posts will then be searchable by Emoji.
First emoji will displayed on map.
""")
        }
        
        else if sender.tag == 1 {
            // Additional Tags Info
            self.alert(title: "Additional Tags", message:"""
                Tag up to 3 Emojis to enable searching your posts by Emoji. Click on 🔍 to access the emoji dictionary.

                You can also tag your posts by
                1) Price - $5, $$$
                2) Meal type - Breakfast🍳, Coffee☕️
                3) Cuisine - Mexican🇲🇽, Japanese🇯🇵
                4) Diet - Vegetarian ❌🍖, 🕌 halal
                """)
        } else if sender.tag == 2 {
            // Extra Rating Emoji Info
            self.alert(title: "Location Rating", message: """
Choose to tag one of the following to describe the location
💩 : Poop
👌 : Legit
🔥 : Fire
💯 : 100%
🥇 : Best
""")
        }
    }
    
    @objc func openAutoTag(sender : UIButton){
        let autoTag = AutoTagTableViewController()
        autoTag.delegate = self
        autoTag.selectedScope = sender.tag
        
        autoTag.selectedMealTagEmojis = self.mealTagEmojis
        autoTag.selectedCuisineTagEmojis = self.cuisineTagEmojis
        autoTag.selectedDietTagEmojis = self.dietTagEmojis
        if self.nonRatingEmojiTags.count > 0 {
            autoTag.selectedEmoji = [EmojiBasic(emoji: self.nonRatingEmojiTags[0], name: self.nonRatingEmojiTagsDict[0], count: 0)]
        }
        
        self.navigationController?.pushViewController(autoTag, animated: true)
    }
    
    @objc func cancelAutoTag(sender : UIButton){
        if sender.tag == 0 {
            self.mealTagEmojis.removeAll()
        } else if sender.tag == 1 {
            self.cuisineTagEmojis.removeAll()
        } else if sender.tag == 2 {
            self.dietTagEmojis.removeAll()
        }
    }

    
    func autoTagSelected(scope: Int, tag_selected: [String]?) {
        guard let tag_selected = tag_selected else {return}
        var tempEmoji = [] as [EmojiBasic]
        var allAutoTagDict: [String:String] = [:]
        
        allAutoTagDict =  mealEmojiDictionary.merging(cuisineEmojiDictionary, uniquingKeysWith: { (current, _) -> String in current })
        allAutoTagDict =  allAutoTagDict.merging(dietEmojiDictionary, uniquingKeysWith: { (current, _) -> String in current })
        
        if scope != 3 {
            for tag in tag_selected {
                tempEmoji.append(EmojiBasic(emoji: allAutoTagDict.key(forValue: tag)!, name: tag, count: 0))
            }
        }
        
        switch scope {

        case 0:
            self.mealTagEmojis = tempEmoji
        case 1:
            self.cuisineTagEmojis = tempEmoji
        case 2:
            self.dietTagEmojis = tempEmoji
        case 3:
            let tag = tag_selected[0]
            if tag_selected.count > 1 {
                print("More than 1 Emoji Tag Returned \(tag_selected)")
            }
            
            if tag_selected.count > 0 {
                if let emoji = EmojiDictionary.key(forValue: tag) {
                    self.nonRatingEmojiTagsDict = [tag]
                    self.nonRatingEmojiTags = [emoji]
                    print("Auto Tag Emoji | \(emoji) \(tag)")

                } else {
                    print("ERROR | Emoji Dictionary Invalid for \(tag)")
                }
            } else {
                self.nonRatingEmojiTagsDict = []
                self.nonRatingEmojiTags = []
            }
            
        default:
            print("Error: Invalid Scope")
        }
    }

    
    var allTypeAutoTag: [[String]?]?

    
// List Variable
    var postList:[String:String]? = nil
    
// Emoji Variables
    
    
    var nonRatingEmojiTags: [String] = [] {
        didSet{
//            self.updateEmojiTextView()
//            self.selectedEmojiTag.text = self.nonRatingEmojiTags.first
//            self.suggestedEmojiCollectionView.reloadData()

        }
    }
    var nonRatingEmojiTagsDict:[String] = []


    
    var googleImage: UIImageView = {
        let img = UIImageView()
        img.image = #imageLiteral(resourceName: "google_tag").withRenderingMode(.alwaysOriginal)
        img.contentMode = .scaleAspectFit
        img.alpha = 0.5
        return img
    }()

    
    var keyboardTap = UITapGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationItems()
        setupEmojiAutoComplete()
        setupImageAndInputViews()
        self.lookupLocationMostUsedEmojis()
        
        view.backgroundColor = UIColor.white


        
//        self.view.addGestureRecognizer(dismissKeyboardGesture)

        //        self.captionTextView.becomeFirstResponder()
    
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        print("keyboardWillShow. Adding Keyboard Tap Gesture")
        self.view.addGestureRecognizer(self.keyboardTap)
    }
    
    @objc func keyboardWillHide(notification: NSNotification){
        print("keyboardWillHide. Removing Keyboard Tap Gesture")
        self.view.removeGestureRecognizer(self.keyboardTap)
    }
    
    
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        captionTextView.resignFirstResponder()
    }
    
    func addGoogleAttribution(){
        self.view.addSubview(googleImage)
        googleImage.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 15)
//        googleImage.center = self.view.center
        googleImage.backgroundColor = UIColor.clear
    }
    
    fileprivate func setupImageAndInputViews() {
        setupImageCaption()
        setupLocationView()
        setupStarRating()
        setupAdditionalTags()
        addGoogleAttribution()
    }
    
    
    
    func setupNavigationItems(){
        
//        self.navigationController?.navigationBar.barStyle = UIBarStyle.blackOpaque

        self.navigationController?.navigationBar.isTranslucent = false
        let tempImage = UIImage.init(color: UIColor.legitColor())
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        
        self.navigationController?.view.backgroundColor = UIColor.white
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationController?.navigationBar.tintColor = UIColor.ianLegitColor()
        
        self.navigationItem.title = "Create Post"
        self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.ianLegitColor(), NSAttributedString.Key.font.rawValue: UIFont(name: "Poppins-Bold", size: 18)])
        self.navigationController?.navigationBar.layoutIfNeeded()

        
    // Nav Next Button
        let navEditButton = NavButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        navEditButton.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
        navEditButton.setTitle(self.editPostInd ? "Edit Post" : "Next", for: .normal)
        let barButton1 = UIBarButtonItem.init(customView: navEditButton)
        self.navigationItem.rightBarButtonItem = barButton1

    // Nav Back Buttons
        let navBackButton = navBackButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        navBackButton.addTarget(self, action: #selector(handleBackNav), for: .touchUpInside)
        let barButton2 = UIBarButtonItem.init(customView: navBackButton)
         navigationItem.leftBarButtonItem = barButton2
        
        
//        if self.editPostInd {
//            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(handleNext))
//        } else {
//            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(handleNext))
//        }
        
//        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(handleBack))
    }
    
    @objc func handleBackNav(){
        self.dismiss(animated: true) {
        }
    }
    
    func showNavBarTest(){
        self.navigationController?.navigationBar.isTranslucent = false
        
        let tempImage = UIImage.init(color: UIColor.legitColor())
        self.navigationController?.navigationBar.setBackgroundImage(tempImage, for: .default)
        self.navigationController?.view.backgroundColor = UIColor.legitColor()
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.layoutIfNeeded()
    }
    

    let headerTagContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    
    let nonRatingEmojiLabel: UILabel = {
        let tv = UILabel()
        tv.backgroundColor = UIColor.clear
        tv.layer.cornerRadius = 5
        tv.font = UIFont.boldSystemFont(ofSize: 25)
        return tv
    }()

    
    func emojiTagClicked(sender: UIButton) {
        guard let _ = sender.titleLabel?.text else {return}
        
        let alert = UIAlertController(title: "\((sender.titleLabel?.text)!) \((EmojiDictionary[(sender.titleLabel?.text)!]) ?? "")"   ,message: "",preferredStyle: .alert)
        let delete = UIAlertAction(title: "Delete", style: .default, handler: { (action) -> Void in
            self.nonRatingEmojiTags.remove(at: sender.tag)
            self.nonRatingEmojiTagsDict.remove(at: sender.tag)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .destructive, handler: { (action) -> Void in })
    
        alert.addAction(delete)
        alert.addAction(cancel)
        
        if sender.titleLabel?.text != "" {
            present(alert, animated: true, completion: nil)
        }
    }
    
    
    let imageContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    let imageDetailHeight: CGFloat = 30
    let imageContrainerHeight: CGFloat = 100 //140
    
    func setupImageCaption(){
    // Photo and Caption Container View
        view.addSubview(imageContainerView)
        imageContainerView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: imageContrainerHeight)
//        imageContainerView.backgroundColor = UIColor.legitColor().withAlphaComponent(0.25)
//        imageContainerView.layer.borderColor = UIColor.gray.cgColor
//        imageContainerView.layer.borderWidth = 1

    // IMAGE
        view.addSubview(imageScrollView)
        imageScrollView.frame = CGRect(x: 0, y: 0, width: imageContrainerHeight-10, height: imageContrainerHeight-10)
        imageScrollView.anchor(top: imageContainerView.topAnchor, left: imageContainerView.leftAnchor, bottom: imageContainerView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        imageScrollView.widthAnchor.constraint(equalTo: imageScrollView.heightAnchor, multiplier: 1).isActive = true
        imageScrollView.isUserInteractionEnabled = true
        imageScrollView.isPagingEnabled = true
        imageScrollView.delegate = self
        imageScrollView.backgroundColor = UIColor.white

        let photoTapGesture = UITapGestureRecognizer(target: self, action: #selector(expandImage))
        self.imageScrollView.addGestureRecognizer(photoTapGesture)
        
    // IMAGE COUNT
        view.addSubview(photoCountLabel)
        photoCountLabel.anchor(top: nil, left: imageScrollView.leftAnchor, bottom: imageContainerView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        photoCountLabel.sizeToFit()
        
    // IMAGE DETAIL
//        let imageDetailView = UIView()
//        view.addSubview(imageDetailView)
//        imageDetailView.anchor(top: nil, left: imageScrollView.rightAnchor, bottom: imageContainerView.bottomAnchor, right: imageContainerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: imageDetailHeight)


//        emojiStackView.centerYAnchor.constraint(equalTo: imageDetailView.centerYAnchor).isActive = true

        
//        
//    // RATING
//        starRatingLabel = RatingLabelNew.init(ratingScore: 0, frame: CGRect(x: 0, y: 0, width: imageDetailHeight-10, height: imageDetailHeight-10))
//        view.addSubview(starRatingLabel)
//        starRatingLabel.anchor(top: nil, left: nil, bottom: nil, right: imageDetailView.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
//        
//        starRatingLabel.widthAnchor.constraint(equalTo: starRatingLabel.heightAnchor).isActive = true
//        starRatingLabel.centerYAnchor.constraint(equalTo: emojiStackView.centerYAnchor).isActive = true
//        starRatingLabel.isUserInteractionEnabled = true
//        starRatingLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(clearRating)))
//        
//        
//    // LEGIT LABEL
//        setupLegitLabel()
//        view.addSubview(isLegitLabel)
//        isLegitLabel.anchor(top: nil, left: nil, bottom: nil, right: starRatingLabel.leftAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)
//        isLegitLabel.sizeToFit()
//        isLegitLabel.isHidden = true
//        isLegitLabel.centerYAnchor.constraint(equalTo: emojiStackView.centerYAnchor).isActive = true

        
    // CAPTION
        view.addSubview(captionTextView)
        captionTextView.anchor(top: imageContainerView.topAnchor, left: imageScrollView.rightAnchor, bottom: imageContainerView.bottomAnchor, right: imageContainerView.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 30, paddingRight: 5, width: 0, height: 0)
        // Bottom Padding for image Count
        captionTextView.delegate = self
        captionTextView.backgroundColor = UIColor.clear
        captionTextView.showsVerticalScrollIndicator = false

        
        let emojiHeaderView = UIView()
        view.addSubview(emojiHeaderView)
        emojiHeaderView.anchor(top: nil, left: captionTextView.leftAnchor, bottom: imageContainerView.bottomAnchor, right: view.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 35)
        
        if self.editPostInd && self.editPost?.caption != "" {
            captionTextView.text = editPost?.caption
        } else {
            resetCaptionTextView()
        }
        
        
        // TAGGED EMOJIS
        selectedEmojiTagArray = [selectedEmojiTag, selectedEmojiTag2, selectedEmojiTag3]
        let emojiStackView = UIStackView(arrangedSubviews: selectedEmojiTagArray)
        emojiStackView.distribution = .fillEqually
        emojiStackView.spacing = 3
        
        for view in emojiStackView.arrangedSubviews {
            let emoji = view as! UITextField
            emoji.widthAnchor.constraint(greaterThanOrEqualTo: emoji.heightAnchor, multiplier: 1).isActive = true
            emoji.layer.cornerRadius = CGFloat(imageDetailHeight / 2)
            emoji.clipsToBounds = true
            emoji.delegate = self
        }
        
        self.updateEmojiTextView()

        
        view.addSubview(emojiStackView)
        emojiStackView.anchor(top: emojiHeaderView.topAnchor, left: nil, bottom: emojiHeaderView.bottomAnchor, right: emojiHeaderView.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        emojiStackView.centerYAnchor.constraint(equalTo: emojiHeaderView.centerYAnchor).isActive = true

        
        // Add Emoji Detail Label (Caption When Emoji is Selected)
        view.addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top: nil, left: imageScrollView.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 3, width: 0, height: 0)
        emojiDetailLabel.alpha = 0
        emojiDetailLabel.centerYAnchor.constraint(equalTo: emojiStackView.centerYAnchor).isActive = true
        emojiDetailLabel.rightAnchor.constraint(lessThanOrEqualTo: emojiStackView.leftAnchor, constant: 5).isActive = true
        
        
    }
    
    @objc func clearRating(){
        self.selectPostStarRating = 0
    }
    
    
    func updateScrollImages() {
        
        //        guard let _ = post?.imageUrls else {return}
        
        imageScrollView.contentSize = CGSize(width: imageScrollView.frame.width * CGFloat((self.selectedImages?.count)!), height: imageScrollView.frame.height)

        print("updateScrollImages ScrollView | H \(imageScrollView.frame.height) | W \(imageScrollView.frame.width)")
        print("updateScrollImages ScrollView Content | H \(imageScrollView.contentSize.height) | W \(imageScrollView.contentSize.width)")

        imageView.frame = CGRect(x: 0, y: 0, width: self.imageScrollView.frame.width, height: self.imageScrollView.frame.width)

        imageScrollView.addSubview(imageView)
        imageView.tag = 0
        imageScrollView.isScrollEnabled = true
        
        for i in 1 ..< (self.selectedImages?.count)! {
            
            let addImageView = CustomImageView()
            addImageView.image = self.selectedImages?[i]
            addImageView.backgroundColor = .white
            addImageView.contentMode = .scaleAspectFill
            addImageView.clipsToBounds = true
            addImageView.isUserInteractionEnabled = true
            
            let xPosition = self.imageScrollView.frame.width * CGFloat(i)
            addImageView.frame = CGRect(x: xPosition, y: 0, width: imageScrollView.frame.width, height: imageScrollView.frame.height)
            
            imageScrollView.addSubview(addImageView)
            print("Scroll Photos |",i, addImageView.frame)
            
        }
        //        photoImageScrollView.reloadInputViews()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.currentImage = scrollView.currentPage
    }

    var originalImageCenter:CGPoint?
    var isZooming = false
    var currentImage = 1 {
        didSet {
            setupImageCountLabel()
        }
    }
    var imageCount = 0

    func setupImageCountLabel(){
        imageCount = (self.selectedImages?.count)!
        
        if imageCount == 1 {
            photoCountLabel.isHidden = true
        } else {
            photoCountLabel.isHidden = false
        }
        
        if imageCount > 1 {
            self.photoCountLabel.text = "\(currentImage)\\\(imageCount)"
        } else {
            self.photoCountLabel.text = ""
        }
        print(self.photoCountLabel.text)
        self.photoCountLabel.sizeToFit()
        self.captionTextView.updateConstraintsIfNeeded()
    }
    
    var browser = SKPhotoBrowser()

    
    @objc func expandImage(){
        var images = [SKPhoto]()
        
        guard let selectedImages = selectedImages else {return}
        for image in selectedImages {
            let photo = SKPhoto.photoWithImage(image)// add some UIImage
            images.append(photo)
        }
        
        // 2. create PhotoBrowser Instance, and present from your viewController.
        SKPhotoBrowserOptions.displayCounterLabel = true
        SKPhotoBrowserOptions.displayBackAndForwardButton = true
        SKPhotoBrowserOptions.displayAction = true
        SKPhotoBrowserOptions.actionButtonTitles = ["Edit Photo"]
        SKPhotoBrowserOptions.swapCloseAndDeleteButtons = false
        //        SKPhotoBrowserOptions.enableSingleTapDismiss  = true
        SKPhotoBrowserOptions.bounceAnimation = true
        SKPhotoBrowserOptions.displayDeleteButton = true
        
        browser = SKPhotoBrowser(photos: images)
        browser.delegate = self
//        browser.updateCloseButton(#imageLiteral(resourceName: "checkmark_teal").withRenderingMode(.alwaysOriginal), size: CGSize(width: 50, height: 50))
        
        browser.initializePageIndex(0)
        present(browser, animated: true, completion: {})
        
    }

    
    func didDismissActionSheetWithButtonIndex(_ buttonIndex: Int, photoIndex: Int) {
        self.editIndex = photoIndex
        print("EDIT INDEX | \(self.editIndex) | \(photoIndex)")
        
        let cropViewController = CropViewController(image: self.selectedImages![self.editIndex!])
        cropViewController.delegate = self
        self.presentedViewController?.present(cropViewController, animated: true) {
        }

    }
    
    
    // CROP VIEW CONTROLLER DELEGATE
    
    var editIndex: Int? = nil
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        
        print("Cropped/Edited Picture |\(self.editIndex)")
        
        guard let _ = self.editIndex else {return}
        self.selectedImages![self.editIndex!] = image
        browser.photos[self.editIndex!] = SKPhoto.photoWithImage(image)
        //        self.browser.photoAtIndex(self.editIndex) = image
        
        
        self.presentedViewController?.dismiss(animated: true, completion: {
            self.editIndex = nil
            self.browser.reloadData()
        })
        

    }
    
    func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
        print("Cancel")
        self.presentedViewController?.dismiss(animated: true, completion: {
            //            self.editIndex = nil
            //            self.browser.reloadData()
        })
    }
    
    func removePhoto(_ browser: SKPhotoBrowser, index: Int, reload: @escaping (() -> Void)) {
        self.selectedImages?.remove(at: index)
        
        if editPostInd {
            self.editPostImageUrls.remove(at: index)
        }
        
        if self.selectedImages?.count == 0 {
            print("No Pictures")
            self.dismiss(animated: true) {
            }
        } else {
            reload()
        }
    }
    
    let LocationContainerView: UIView = {
        // Location Container View
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    let locationNameIcon: UIButton = {
        let button = UIButton()
        button.setTitle("🏠", for: .normal)
        button.addTarget(self, action: #selector(showLocationOptions), for: .touchUpInside)
        return button
    }()
    
    let locationNameLabelBox = UIView()
    
    lazy var filterEmojiButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage((self.selectedEmojiFilter != nil ? #imageLiteral(resourceName: "filterclear") : #imageLiteral(resourceName: "filter")).withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(clearEmojiFilter), for: .touchUpInside)
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.clipsToBounds = true
        return button
    }()
    
    @objc func clearEmojiFilter(){
        self.selectedEmojiFilter = nil
    }
    
    func setupLocationView(){

//
//        // Add Emoji Header
//        emojiHeaderView.addSubview(emojiHeaderLabel)
//        emojiHeaderLabel.anchor(top: emojiHeaderView.topAnchor, left: emojiHeaderView.leftAnchor, bottom: emojiHeaderView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 15, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
//        emojiHeaderLabel.sizeToFit()
//
//
//
//
        // Emoji Container View - One Line
        EmojiContainerView.backgroundColor = UIColor.white
        view.addSubview(EmojiContainerView)
        let emojiContainerHeight: Int = (Int(EmojiSize.width) + 2) * 2 + 10
        
        EmojiContainerView.anchor(top: imageContainerView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: CGFloat(emojiContainerHeight))
        
        // Suggested Emoji Input View
        self.setupEmojiCollectionView()
        view.addSubview(suggestedEmojiCollectionView)
        suggestedEmojiCollectionView.anchor(top: EmojiContainerView.topAnchor, left: EmojiContainerView.leftAnchor, bottom: EmojiContainerView.bottomAnchor, right: EmojiContainerView.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        
        
        view.addSubview(emojiOptionsView)
        emojiOptionsView.anchor(top: EmojiContainerView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
        
        view.addSubview(searchEmojiButton)
        searchEmojiButton.anchor(top: nil, left: nil, bottom: nil, right: emojiOptionsView.rightAnchor, paddingTop: 3, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 25)
        searchEmojiButton.centerYAnchor.constraint(equalTo: emojiOptionsView.centerYAnchor).isActive = true
        searchEmojiButton.layer.cornerRadius = 6
        searchEmojiButton.layer.masksToBounds = true
        searchEmojiButton.backgroundColor = UIColor.lightSelectedColor()
        searchEmojiButton.backgroundColor = UIColor.pinterestRedColor().withAlphaComponent(0.5)
        
        view.addSubview(filterEmojiButton)
        filterEmojiButton.anchor(top: emojiOptionsView.topAnchor, left: view.leftAnchor, bottom: emojiOptionsView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        filterEmojiButton.widthAnchor.constraint(equalTo: filterEmojiButton.heightAnchor, multiplier: 1).isActive = true
    
        // Add Places Collection View
        view.addSubview(filterEmojiCollectionView)
        filterEmojiCollectionView.anchor(top: emojiOptionsView.topAnchor, left: filterEmojiButton.rightAnchor, bottom: emojiOptionsView.bottomAnchor, right: searchEmojiButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        filterEmojiCollectionView.backgroundColor = UIColor.white
        filterEmojiCollectionView.register(EmojiFilterCell.self, forCellWithReuseIdentifier: emojiFilterCellID)
        filterEmojiCollectionView.delegate = self
        filterEmojiCollectionView.dataSource = self
        filterEmojiCollectionView.showsHorizontalScrollIndicator = false
        
        //        searchEmojiButton.layer.borderColor = UIColor.init(hexColor: "fdcb6e").cgColor
        //        searchEmojiButton.layer.borderColor = UIColor.darkGray.cgColor
        //        searchEmojiButton.layer.borderWidth = 1
        
        
        // Suggested Emoji Buttons
//        view.addSubview(userMostUsedEmojiButton)
//        userMostUsedEmojiButton.anchor(top: nil, left: nil, bottom: nil, right: searchEmojiButton.leftAnchor, paddingTop: 3, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
//        userMostUsedEmojiButton.centerYAnchor.constraint(equalTo: emojiOptionsView.centerYAnchor).isActive = true
//        userMostUsedEmojiButton.sizeToFit()
//        userMostUsedEmojiButton.alpha = 0.5
//
//        view.addSubview(locationMostUsedEmojiButton)
//        locationMostUsedEmojiButton.anchor(top: nil, left: nil, bottom: nil, right: userMostUsedEmojiButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 3, width: 0, height: 0)
//        locationMostUsedEmojiButton.centerYAnchor.constraint(equalTo: emojiOptionsView.centerYAnchor).isActive = true
//        locationMostUsedEmojiButton.sizeToFit()
//        locationMostUsedEmojiButton.isHidden = true
        
        view.addSubview(LocationContainerView)
        LocationContainerView.anchor(top: emojiOptionsView.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        LocationContainerView.layer.borderColor = UIColor.gray.cgColor
//        LocationContainerView.layer.borderWidth = 1
    
        
        let locationNameView = UIView()
        view.addSubview(locationNameView)
        locationNameView.anchor(top: LocationContainerView.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 45)
        locationNameView.layer.borderColor = UIColor.lightGray.cgColor
        locationNameView.layer.borderWidth = 1
        
        let locationNameDivider = UIView()
        locationNameDivider.backgroundColor = UIColor.lightGray
        view.addSubview(locationNameDivider)
        locationNameDivider.anchor(top: locationNameView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
        
        view.addSubview(emojiInfoButton)
        emojiInfoButton.anchor(top: nil, left: nil, bottom: nil, right: locationNameView.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5 , width: 20, height: 20)
        emojiInfoButton.centerYAnchor.constraint(equalTo: locationNameView.centerYAnchor).isActive = true
        
        locationNameView.addSubview(locationNameLabelBox)
        locationNameLabelBox.anchor(top: nil, left: locationNameView.leftAnchor, bottom: nil, right: emojiInfoButton.leftAnchor, paddingTop: 3, paddingLeft: 0, paddingBottom: 3, paddingRight: 0, width: 0, height: 0)
        locationNameLabelBox.centerYAnchor.constraint(equalTo: locationNameView.centerYAnchor).isActive = true
        
        locationNameLabelBox.addSubview(locationCancelButton)
        locationCancelButton.anchor(top: locationNameView.topAnchor, left: locationNameView.leftAnchor, bottom: locationNameView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        locationCancelButton.centerYAnchor.constraint(equalTo: locationNameView.centerYAnchor).isActive = true
        locationCancelButton.widthAnchor.constraint(equalTo: locationCancelButton.heightAnchor, multiplier: 1).isActive = true
        
        
        locationNameLabelBox.addSubview(findCurrentLocationButton)
        findCurrentLocationButton.anchor(top: locationNameView.topAnchor, left: locationNameView.leftAnchor, bottom: locationNameView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        findCurrentLocationButton.centerYAnchor.constraint(equalTo: locationNameView.centerYAnchor).isActive = true
        findCurrentLocationButton.widthAnchor.constraint(equalTo: findCurrentLocationButton.heightAnchor, multiplier: 1).isActive = true
        
        
        locationNameLabelBox.addSubview(locationAdressLabel)
        locationAdressLabel.anchor(top: nil, left: locationCancelButton.rightAnchor, bottom: locationNameLabelBox.bottomAnchor, right: locationNameLabelBox.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        locationAdressLabelHeightConstraint = locationAdressLabel.heightAnchor.constraint(equalToConstant: 0)
        locationAdressLabelHeightConstraint?.isActive = true
//        locationAdressLabel.rightAnchor.constraint(lessThanOrEqualTo: locationNameLabelBox.rightAnchor).isActive = true
        
        locationNameLabelBox.addSubview(locationNameLabel)
        locationNameLabel.anchor(top: locationNameLabelBox.topAnchor, left: locationCancelButton.rightAnchor, bottom: locationAdressLabel.topAnchor, right: locationNameLabelBox.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
//        locationNameLabel.rightAnchor.constraint(lessThanOrEqualTo: locationNameLabelBox.rightAnchor).isActive = true

        
        //        locationNameView.addSubview(locationNameIcon)
        //        locationNameIcon.anchor(top: locationNameView.topAnchor, left: locationNameView.leftAnchor, bottom: locationNameView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        //        locationNameIcon.widthAnchor.constraint(equalTo: locationNameIcon.heightAnchor, multiplier: 1).isActive = true
        
        // Search Location Button
        //        locationNameView.addSubview(searchLocationButton)
        //        searchLocationButton.anchor(top: nil, left: nil, bottom: nil, right: locationNameView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 30, height: 30)
        //        searchLocationButton.centerYAnchor.constraint(equalTo: locationNameView.centerYAnchor).isActive = true
        //        searchLocationButton.layer.cornerRadius = 30/2
        //        searchLocationButton.layer.masksToBounds = true
        //        searchLocationButton.layer.borderColor = UIColor.init(hexColor: "fdcb6e").cgColor
        //        searchLocationButton.layer.borderWidth = 1
        //
        //        searchLocationButton.layer.borderColor = UIColor.legitColor().cgColor
        //        searchLocationButton.tintColor = UIColor.legitColor()

        
//        locationNameView.addSubview(locationNameLabel)
//        locationNameLabel.anchor(top: locationNameView.topAnchor, left: locationNameIcon.rightAnchor, bottom: locationNameView.bottomAnchor, right: locationNameView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        locationNameLabel.isUserInteractionEnabled = true
        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(showLocationOptions))
        locationNameLabel.addGestureRecognizer(TapGesture)
    
        if locationNameLabel.text == blankGPSName {
            self.locationCancelButton.isHidden = true
            self.findCurrentLocationButton.isHidden = false
            self.addLocationButton.isHidden = true
        } else {
            self.locationCancelButton.isHidden = false
            self.findCurrentLocationButton.isHidden = true
            self.addLocationButton.isHidden = false

        }
        
        let suggestLocationView = UIView()
        view.addSubview(suggestLocationView)
        suggestLocationView.anchor(top: locationNameView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
//        addLocationButton.widthAnchor.constraint(equalTo: addLocationButton.heightAnchor, multiplier: 1).isActive = true

        // Add Places Collection View
        view.addSubview(placesCollectionView)
        placesCollectionView.anchor(top: suggestLocationView.topAnchor, left: suggestLocationView.leftAnchor, bottom: suggestLocationView.bottomAnchor, right: suggestLocationView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        placesCollectionView.backgroundColor = UIColor.white
        placesCollectionView.register(UploadLocationCell.self, forCellWithReuseIdentifier: locationCellID)
        placesCollectionView.delegate = self
        placesCollectionView.dataSource = self
        
        let bottomView = UIView()
        view.addSubview(bottomView)
        bottomView.anchor(top: suggestLocationView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
        bottomView.backgroundColor = UIColor.lightGray
        
        
        // RATING VIEW
        view.addSubview(ratingView)
        ratingView.anchor(top: suggestLocationView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        ratingView.layer.borderColor = UIColor.lightGray.cgColor
        ratingView.layer.borderWidth = 0
        //        ratingView.backgroundColor = UIColor.blue
        
        let starRatingView = UIView()
        view.addSubview(starRatingView)
        starRatingView.anchor(top: ratingView.topAnchor, left: ratingView.leftAnchor, bottom: ratingView.bottomAnchor, right: ratingView.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        
        let starRatingViewDoubleTap = UITapGestureRecognizer(target: self, action: #selector(clearRating))
        starRatingViewDoubleTap.numberOfTapsRequired = 2
        starRatingViewDoubleTap.delegate = self
        starRatingView.addGestureRecognizer(starRatingViewDoubleTap)
        starRatingView.isUserInteractionEnabled = true
        
        view.addSubview(starRating)
        starRating.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 40, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        starRating.centerXAnchor.constraint(equalTo: starRatingView.centerXAnchor).isActive = true
        starRating.centerYAnchor.constraint(equalTo: starRatingView.centerYAnchor).isActive = true
        starRating.didFinishTouchingCosmos = starRatingSelectFunction
        starRating.sizeToFit()
        
        view.addSubview(extraRatingButton)
        extraRatingButton.anchor(top: ratingView.topAnchor, left: nil, bottom: ratingView.bottomAnchor, right: ratingView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)
        extraRatingButton.widthAnchor.constraint(equalTo: extraRatingButton.heightAnchor, multiplier: 1).isActive = true
        extraRatingButton.layer.cornerRadius = 20
        extraRatingButton.layer.masksToBounds = true

        view.addSubview(extraRatingInfoButton)
        extraRatingInfoButton.anchor(top: nil, left: ratingView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 10, width: 20, height: 20)
        extraRatingInfoButton.centerYAnchor.constraint(equalTo: ratingView.centerYAnchor).isActive = true
        extraRatingInfoButton.isHidden = true
        
        let extraRatingViewDoubleTap = UITapGestureRecognizer(target: self, action: #selector(clearExtraRating))
        extraRatingViewDoubleTap.numberOfTapsRequired = 2
        extraRatingViewDoubleTap.delegate = self
        extraRatingButton.addGestureRecognizer(extraRatingViewDoubleTap)
        
        view.addSubview(extraRatingEmojiCollectionView)
        extraRatingEmojiCollectionView.anchor(top: ratingView.topAnchor, left: extraRatingInfoButton.rightAnchor, bottom: ratingView.bottomAnchor, right: extraRatingButton.leftAnchor, paddingTop: 3, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        //        extraRatingEmojiCollectionView.centerYAnchor.constraint(equalTo: locationNameView.centerYAnchor)
        extraRatingEmojiCollectionView.isHidden = true
        
        
        // Emoji Auto Complete For Caption
        view.addSubview(emojiAutoComplete)
        emojiAutoComplete.anchor(top: imageContainerView.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        emojiAutoComplete.isHidden = true
    }

    let EmojiContainerView = UIView()

    
    func setupEmojiCollectionView(){
        suggestedEmojiCollectionView.backgroundColor = UIColor.white
        suggestedEmojiCollectionView.register(UploadEmojiCell.self, forCellWithReuseIdentifier: emojiCellID)
        suggestedEmojiCollectionView.delegate = self
        suggestedEmojiCollectionView.dataSource = self
        suggestedEmojiCollectionView.allowsMultipleSelection = false
        suggestedEmojiCollectionView.showsHorizontalScrollIndicator = false
        
        let emojiRef = UILongPressGestureRecognizer(target: self, action: #selector(MultSharePhotoController.handleLongPress(_:)))
        emojiRef.minimumPressDuration = 0.5
        emojiRef.delegate = self
        suggestedEmojiCollectionView.addGestureRecognizer(emojiRef)
        
        
        let emojiDoubleTap = UITapGestureRecognizer(target: self, action: #selector(MultSharePhotoController.handleDoubleTap(_:)))
        emojiDoubleTap.numberOfTapsRequired = 2
        emojiDoubleTap.delegate = self
        suggestedEmojiCollectionView.addGestureRecognizer(emojiDoubleTap)
        
        extraRatingEmojiCollectionView.backgroundColor = UIColor.white
        extraRatingEmojiCollectionView.register(UploadEmojiCell.self, forCellWithReuseIdentifier: testemojiCellID)
        
        extraRatingEmojiCollectionView.delegate = self
        extraRatingEmojiCollectionView.dataSource = self
        extraRatingEmojiCollectionView.allowsMultipleSelection = false
        extraRatingEmojiCollectionView.showsHorizontalScrollIndicator = false
        extraRatingEmojiCollectionView.isPagingEnabled = true
        extraRatingEmojiCollectionView.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
        
        var layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        layout.itemSize = CGSize(width: 40, height: 40)
        layout.minimumInteritemSpacing = 2
//        layout.offse
        extraRatingEmojiCollectionView.collectionViewLayout = layout
        
        
//
//        extraRatingEmojiCollectionView.isScrollEnabled = true
        
        
    }
    
    
    var emojiOptionsView = UIView()
    let ratingView = UIView()

    func setupStarRating(){
        

    }
    
    func setupAutoTagSegments(){
        
        autoTagCollectionViews = [mealTypeCollectionView,cuisineTypeCollectionView,dietTypeCollectionView]
        
        for segment in autoTagCollectionViews {
            segment.register(AutoTagDetailCell.self, forCellWithReuseIdentifier: autoTagDetailId)
            segment.delegate = self
            segment.dataSource = self
            segment.allowsMultipleSelection = false
            segment.showsHorizontalScrollIndicator = false
            segment.backgroundColor = UIColor.clear
        }
       
    }
    
    func setupAdditionalTags(){

    // AUTO TAGS
        
        self.setupAutoTagSegments()
        let autoTagView = UIView()
        view.addSubview(autoTagView)
        autoTagView.anchor(top: ratingView.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
       autoTagView.backgroundColor = UIColor.white

        view.addSubview(autoTagLabel)
        autoTagLabel.anchor(top: autoTagView.topAnchor, left: autoTagView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
        autoTagLabel.sizeToFit()
        autoTagLabel.isUserInteractionEnabled = true
        
        let autoTagDoubleTap = UITapGestureRecognizer(target: self, action: #selector(clearAutoTagEmojis))
        autoTagDoubleTap.numberOfTapsRequired = 2
        autoTagDoubleTap.delegate = self
        autoTagLabel.addGestureRecognizer(autoTagDoubleTap)
        
        view.addSubview(autoTagInfoButton)
        autoTagInfoButton.anchor(top: nil, left: autoTagLabel.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 20, height: 20)
        autoTagInfoButton.centerYAnchor.constraint(equalTo: autoTagLabel.centerYAnchor).isActive = true
        autoTagInfoButton.isHidden = true
        
        // Add Post Price Segment
        view.addSubview(postPriceSegment)
        postPriceSegment.anchor(top: autoTagLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 30)
        
        let mealTagView = UIView()
        view.addSubview(mealTagView)
        mealTagView.anchor(top: postPriceSegment.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
        
        view.addSubview(mealTagButton)
        mealTagButton.anchor(top: nil, left: mealTagView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        mealTagButton.centerYAnchor.constraint(equalTo: mealTagView.centerYAnchor).isActive = true
        
        view.addSubview(cancelMealTagButton)
        cancelMealTagButton.anchor(top: nil, left: nil, bottom: nil, right: mealTagView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        cancelMealTagButton.centerYAnchor.constraint(equalTo: mealTagView.centerYAnchor).isActive = true
        cancelMealTagButton.isHidden = !(self.mealTagEmojis.count > 0)
    

        view.addSubview(mealTypeCollectionView)
        mealTypeCollectionView.anchor(top: mealTagView.topAnchor, left: mealTagView.leftAnchor, bottom: mealTagView.bottomAnchor, right: cancelMealTagButton.leftAnchor, paddingTop: 0, paddingLeft: 60, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        
        let cuisineTagView = UIView()
        view.addSubview(cuisineTagView)
        cuisineTagView.anchor(top: mealTagView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
        
        view.addSubview(cuisineTagButton)
        cuisineTagButton.anchor(top: nil, left: cuisineTagView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        cuisineTagButton.centerYAnchor.constraint(equalTo: cuisineTagView.centerYAnchor).isActive = true
        
        view.addSubview(cancelCuisineTagButton)
        cancelCuisineTagButton.anchor(top: nil, left: nil, bottom: nil, right: cuisineTagView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        cancelCuisineTagButton.centerYAnchor.constraint(equalTo: cuisineTagView.centerYAnchor).isActive = true
        cancelCuisineTagButton.isHidden = !(self.cuisineTagEmojis.count > 0)


        
        view.addSubview(cuisineTypeCollectionView)
        cuisineTypeCollectionView.anchor(top: cuisineTagView.topAnchor, left: cuisineTagView.leftAnchor, bottom: cuisineTagView.bottomAnchor, right: cancelCuisineTagButton.leftAnchor, paddingTop: 0, paddingLeft: 60, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        
        let dietTagView = UIView()
        view.addSubview(dietTagView)
        dietTagView.anchor(top: cuisineTagView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
        
        view.addSubview(dietTagButton)
        dietTagButton.anchor(top: nil, left: dietTagView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        dietTagButton.centerYAnchor.constraint(equalTo: dietTagView.centerYAnchor).isActive = true
        
        view.addSubview(cancelDietTagButton)
        cancelDietTagButton.anchor(top: nil, left: nil, bottom: nil, right: dietTagView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        cancelDietTagButton.centerYAnchor.constraint(equalTo: dietTagView.centerYAnchor).isActive = true
        cancelDietTagButton.isHidden = !(self.dietTagEmojis.count > 0)


        
        view.addSubview(dietTypeCollectionView)
        dietTypeCollectionView.anchor(top: dietTagView.topAnchor, left: dietTagView.leftAnchor, bottom: dietTagView.bottomAnchor, right: cancelDietTagButton.leftAnchor, paddingTop: 0, paddingLeft: 60, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        
        
        
    }
    
//    func handleBack() {
//        self.navigationController?.popToRootViewController(animated: true)
//
//        self.dismiss(animated: true) {
//        }
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Invalidate Layout so that after location search it will not crash
        print("View will appear")
        self.placesCollectionView.collectionViewLayout.invalidateLayout()
        self.filterEmojiCollectionView.collectionViewLayout.invalidateLayout()
        self.updateScrollImages()
        self.keyboardTap = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.setupNavigationItems()
     //   self.guessPostType()

    }
    
    let imageScrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.backgroundColor = .white
        scroll.isScrollEnabled = true
        scroll.isPagingEnabled = true
        return scroll
    }()
    
    let imageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .red
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    let photoCountImage:UIButton = {
        let bt = UIButton()
        bt.setImage(#imageLiteral(resourceName: "multiple_photos").withRenderingMode(.alwaysOriginal), for: .normal)
        return bt
    }()

    
    let photoCountLabel: UILabel = {
        let label = UILabel()
        label.alpha = 1
        label.textColor = UIColor.white
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textAlignment = NSTextAlignment.center
//        label.layer.cornerRadius = 5
//        label.layer.masksToBounds = true
//        label.backgroundColor = UIColor.yellow
        return label
    }()
    
    
    let captionTextView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 14)
        tv.autocorrectionType = .yes
        tv.keyboardType = UIKeyboardType.default
        return tv
    }()
    
    func setselectEmojis(nonRateEmoji: String?){
        if nonRateEmoji == nil {
            // Clear NonRating Emoji
            self.nonRatingEmojiTags = []
            self.nonRatingEmojiTagsDict = []
        }
//        self.EmojiCollectionView.reloadData()
    }
    
    func cancelNonRatingEmoji(){
        self.setselectEmojis(nonRateEmoji: nil)
    }
    
    let emojiDetailLabel: LightPaddedUILabel = {
        let label = LightPaddedUILabel()
        label.text = "Emoji Dictionary"
        label.font = UIFont(font: .avenirNextDemiBold, size: 16)
        label.textColor = UIColor.white
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.ianLegitColor()
        label.layer.borderWidth = 1
        label.layer.borderColor = UIColor.ianLegitColor().cgColor
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        return label
    }()
    
    func cancelCaption(){
        captionTextView.text = nil
        self.setselectEmojis(nonRateEmoji: nil)
    }
    

    
    let locationNameLabel: UILabel = {
        let tv = RightButtonPaddedUILabel()
        tv.font = UIFont.boldSystemFont(ofSize: 15)
        tv.backgroundColor = UIColor.white
        //        tv.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tv.layer.borderWidth = 0
        tv.layer.borderColor = UIColor.lightGray.cgColor
//        tv.layer.borderColor = UIColor.rgb(red: 204, green: 238, blue: 255).cgColor
        //        tv.layer.cornerRadius = 5
        tv.isUserInteractionEnabled = true
        tv.text = "No Location"
        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(showLocationOptions))
        tv.addGestureRecognizer(TapGesture)
        return tv
    }()
    
    let locationAdressLabel: UILabel = {
        let tv = RightButtonPaddedUILabel()
        tv.font = UIFont.systemFont(ofSize: 11)
        tv.textColor = UIColor.lightGray
        tv.backgroundColor = UIColor.white
        tv.isUserInteractionEnabled = true
        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(showLocationOptions))
        tv.addGestureRecognizer(TapGesture)
        return tv
    }()

    let searchLocationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "search_tab_fill").withRenderingMode(.alwaysOriginal), for: .normal)
        button.setImage(#imageLiteral(resourceName: "search_tab_fill"), for: .normal)

        button.tintColor = UIColor.legitColor()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.clear
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        button.layer.borderColor = UIColor.init(hexColor: "fdcb6e").cgColor
        button.layer.borderWidth = 1
        button.addTarget(self, action: #selector(tapSearchBar), for: .touchUpInside)
        return button
    } ()
    
    var locationAdressLabelHeightConstraint:NSLayoutConstraint?


    @objc func showLocationOptions(){
        let optionsAlert = UIAlertController(title: "Location Tag", message: "", preferredStyle: UIAlertController.Style.alert)
        
        
        optionsAlert.addAction(UIAlertAction(title: "Search Google", style: .default, handler: { (action: UIAlertAction!) in
            //            self.emojiTagUntag(emojiInput: emoji, emojiInputTag: nil)
            self.tapSearchBar()
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Add Location Name", style: .default, handler: { (action: UIAlertAction!) in
            //            self.emojiTagUntag(emojiInput: nil, emojiInputTag: nil)
            if self.locationNameLabel.text == defaultEmptyGPSName {
                self.alert(title: "Add Location Error", message: "Unable to Add New Name Without New Location")
            } else {
                self.openAddLocationNameInput()
            }
            
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        present(optionsAlert, animated: true) {
            optionsAlert.view.superview?.isUserInteractionEnabled = true
            optionsAlert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.alertClose(gesture:))))
        }
    }
    
    
    @objc func tapSearchBar() {
        print("Search Bar Tapped")
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
//        self.navigationController?.navigationItem.title = "Search Google Location"
//        self.navigationController?.pushViewController(autocompleteController, animated: true)
//        self.navigationController?.navigationItem.title = "Search Google Location"

        present(autocompleteController, animated: true, completion: nil)
    }
    
    func refreshGoogleResults(){
        self.nearbyGoogleLocations = []
//        self.googlePlaceNames.removeAll()
//        self.googlePlaceIDs.removeAll()
//        self.googlePlaceAdresses.removeAll()
//        self.googlePlaceLocations.removeAll()
        self.placesCollectionView.reloadData()
        self.placesCollectionView.collectionViewLayout.invalidateLayout()
    }
    
    let locationCancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysOriginal), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.clear
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(cancelLocation), for: .touchUpInside)
        return button
    } ()
    
    let findCurrentLocationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "Geofence").withRenderingMode(.alwaysOriginal), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.clear
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(determineCurrentLocation), for: .touchUpInside)
        return button
    } ()
    
    @objc func cancelLocation(){
        // If Google Location Selected, Unselect and change to default image location
        if self.selectedPostLocationItem?.locationGoogleID != nil {
            self.selectedPostLocationItem = self.selectedImageLocationItem
        }
        
        // If Image Location Selected, Clears Location
        else if self.selectedPostLocationItem?.locationName == self.selectedImageLocationItem?.locationName {
            self.selectedPostLocationItem = nil
        } else {
            self.selectedPostLocationItem = nil
        }
//        selectPostLocation = nil
        // Refresh places collectionview to unselect selected place
        self.placesCollectionView.reloadData()
    }
    
    let placesCollectionView: UICollectionView = {
        let uploadLocationTagList = UploadLocationTagList()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadLocationTagList)
//        cv.layer.borderWidth = 1
//        cv.layer.borderColor = UIColor.legitColor().cgColor
        
        return cv
    }()
    
    let suggestedEmojiCollectionView: UICollectionView = {
        let uploadEmojiList = UploadEmojiList()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadEmojiList)
        cv.tag = 10
        cv.layer.borderWidth = 0
        cv.backgroundColor = UIColor(white: 0, alpha: 0.03)
        return cv
    }()
    
    let filterEmojiCollectionView: UICollectionView = {
        let uploadLocationTagList = FilterEmojiLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadLocationTagList)
        //        cv.layer.borderWidth = 1
        //        cv.layer.borderColor = UIColor.legitColor().cgColor
        
        return cv
    }()
    
    var extraRatingEmojiCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.tag = 9
        cv.layer.borderWidth = 0
        cv.backgroundColor = UIColor.lightSelectedColor()
        return cv
    }()
    
    let searchEmojiButton: UIButton = {
        let button = UIButton(type: .system)
//        button.setImage(#imageLiteral(resourceName: "search_tab_fill").withRenderingMode(.alwaysOriginal), for: .normal)
        button.setTitle("🧐Emoji Search", for: .normal)
        button.setTitleColor(UIColor.darkSelectedColor(), for: .normal)
        
        let attributedString = NSMutableAttributedString(string: "🔎 Search", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .helveticaNeueBold, size: 12)]))
        button.setAttributedTitle(attributedString, for: .normal)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        button.tag = 3
        button.layer.borderColor = UIColor.init(hexColor: "fdcb6e").cgColor
        button.layer.borderWidth = 0
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        button.addTarget(self, action: #selector(openEmojiSearch), for: .touchUpInside)
        return button
    } ()
    
    
    @objc func openEmojiSearch(){
        let emojiSearch = EmojiSearchTableViewController()
        emojiSearch.delegate = self
        emojiSearch.selectedEmojis = self.nonRatingEmojiTags
        
        self.navigationController?.pushViewController(emojiSearch, animated: true)
    }

    // Google Search Location Delegates
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        print("Google Results Place: ", place)
        self.refreshGoogleResults()
        let tempLocation = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        self.selectedPostLocationItem = Location.init(gmsPlace: place)
//        self.updateLocation(location: Location.init(gmsPlace: place))
//        self.didUpdate(locationGPS: tempLocation, locationAdress: place.formattedAddress, locationName: place.name, locationGooglePlaceID: place.placeID, locationGooglePlaceType: place.types)

        //        self.reloadInputViews()
        dismiss(animated: true, completion: nil)
        
    }
    
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print(error)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func updateLocation(location: Location?) {
        if location == nil || (location?.locationGPS?.coordinate.latitude == 0 && location?.locationGPS?.coordinate.longitude == 0) {
            // No Location, Clear All
            self.locationCancelButton.isHidden = true
            self.addLocationButton.isHidden = true
            self.findCurrentLocationButton.isHidden = false
            self.clearSelectPostLocation()
        } else {
            self.locationCancelButton.isHidden = false
            self.addLocationButton.isHidden = false
            self.findCurrentLocationButton.isHidden = true
            
            self.selectPostLocation = location?.locationGPS
            self.selectPostLocationName = location?.locationName
            self.selectPostLocationAdress = location?.locationAdress
            self.selectPostlocationSummaryID = location?.locationSummaryID

            self.selectPostGooglePlaceID = location?.locationGoogleID
            self.selectPostGoogleLocationType = location?.locationGoogleTypes
            self.googleLocationSearch(GPSLocation: self.selectPostLocation)
            
            if selectedPostLocationItem != nil && selectedPostLocationItem?.locationSummaryID == nil{
                Database.reverseGPSApple(GPSLocation: selectedPostLocationItem?.locationGPS) { (temp_location) in
                    self.selectPostlocationSummaryID = temp_location?.locationSummaryID
                    print("selectedPostLocationItem | Auto-Fill Location Summary ID | ", self.selectedPostLocationItem?.locationSummaryID)
                }
            }
        }
    }
    
    
//    func didUpdate(locationGPS: CLLocation?, locationAdress: String?, locationName: String?, locationGooglePlaceID: String?, locationGooglePlaceType: [String]?) {
////        self.selectPostLocation = CLLocation.init(latitude: lat!, longitude: long!)
//        self.selectPostLocation = locationGPS
//        self.selectPostGooglePlaceID = locationGooglePlaceID
//        self.selectPostLocationName = locationName
//        self.selectPostLocationAdress = locationAdress
//        self.selectPostGoogleLocationType = locationGooglePlaceType
//        self.googleLocationSearch(GPSLocation: locationGPS)
////        self.placesCollectionView.reloadData()
//    }
    
//    func didUpdate(lat: Double?, long: Double?, locationAdress: String?, locationName: String?, locationGooglePlaceID: String?, locationGooglePlaceType: [String]?) {
//        self.selectPostLocation = CLLocation.init(latitude: lat!, longitude: long!)
//        self.selectPostGooglePlaceID = locationGooglePlaceID
//        self.selectPostLocationName = locationName
//        self.selectPostLocationAdress = locationAdress
//        self.selectGoogleLocationType = locationGooglePlaceType
//        self.googleReverseGPS(GPSLocation: selectPostLocation!)
//        self.googleLocationSearch(GPSLocation: selectPostLocation!)
//        self.guessPostType()
//
//    }
//
    func tagCaptionToEmoji(captionText: String){
        
        if captionText.count == 0 {
            return
        }
        
        var tempCaptionText =  captionText.lowercased()
        
        // Add Space to last tempCaption for searching
        var tempNonRatingEmojiTags = self.nonRatingEmojiTagsDict
        var tempNonRatingEmojis = self.nonRatingEmojiTags
        
        if (tempNonRatingEmojiTags != nil)  && (tempNonRatingEmojis != nil) {
            // Loop through current Emoji Tags, check if tags exist
            
            if tempNonRatingEmojiTags.count != tempNonRatingEmojis.count {
                print("Tag Caption To Emoji: ERROR: Emoji Count Not Equal To Tag Count")
            }
            
            for tag in tempNonRatingEmojiTags {
                
                var searchTag: String = ""
                if tag.isSingleEmoji{
                    searchTag = tag
                } else {
                    // Avoid finding parts of tag in another word
                    searchTag = tag + " "
                }
                
                if let range = tempCaptionText.lowercased().range(of: (searchTag)) {
                    // Emoji Tag still exit in caption remove string from caption text
                    // Using replace subrange to only remove first instance, using X to replace to prevent later search mismatch
                    tempCaptionText.replaceSubrange(range, with: " X ")
                } else {
                    
                    // Can't find Emoji Tag in Caption
                    guard let removeIndex = nonRatingEmojiTagsDict.firstIndex(of: tag) else {
                        print("Can't find delete index for: ", tag)
                        return
                    }
                    
                    // Emoji Tag does not exist anymore, Untag emojis and tags
                    addRemoveEmojiTags(emojiInput: tempNonRatingEmojis[removeIndex], emojiInputTag: tempNonRatingEmojiTags[removeIndex])
                    
                }
            }
        }
//        print(tempCaptionText)
        
        // Check for Complex Tags - Replaced with Auto Complete emoji input
        var tempCaptionWords = tempCaptionText.components(separatedBy: " ")
        if tempCaptionWords.count == 0 {
            return
        }
        
        // Checks forward last 3 words as user types in textbox
        for i in (1...3).reversed() {
            // Check if last n (3 to 1) words match complex dictionary
            
            let captionCheckArray = tempCaptionWords.suffix(i)
            var captionCheckText = captionCheckArray.joined(separator: " ").emojilessString
            print("Caption Check Text: ", captionCheckText)
            
            let emojiLookupResult = ReverseEmojiDictionary[captionCheckText]
            print(emojiLookupResult)
            if emojiLookupResult != nil {
                // If there is a emoji match for words
                if self.nonRatingEmojiTagsDict.firstIndex(of: captionCheckText) == nil {
                    // Check to see if caption tag already exist in current tags. If so ignore (double type)
                    addRemoveEmojiTags(emojiInput: emojiLookupResult, emojiInputTag: captionCheckText)
                    break
                }
            }
        }
    }
    
    
    func textViewDidChange(_ textView: UITextView) {
        var tempCaptionWords = textView.text.components(separatedBy: " ")
        if tempCaptionWords.last == "" {
            tempCaptionWords = Array(tempCaptionWords.dropLast())
        }
        
        if textView.text.count > 0 {
            var lastWord = tempCaptionWords[tempCaptionWords.endIndex - 1]
            self.filterContentForSearchText(inputString: lastWord)
        } else {
            self.emojiAutoComplete.isHidden = true
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        // Detects Emoji being typed and detects price
        
        let char = text.cString(using: String.Encoding.utf8)!
        let isBackSpace = strcmp(char, "\\b")
        
        if text == "\n"  // Recognizes enter key in keyboard
        {
            textView.resignFirstResponder()
            return false
        }
        
        if text.isSingleEmoji == true {
            // Emoji was typed
            if textView.text.contains(text){
                //Ignore if caption text already has emoji, allows multiple emoji caption
            } else {
                self.addRemoveEmojiTags(emojiInput: text, emojiInputTag: text)
            }
        }
            
        else if (text == " ") {
            let nsString = textView.text as NSString?
//            let newString = nsString?.replacingCharacters(in: range, with: text)
            let arr = nsString?.components(separatedBy: " ")
            print(arr?.last)
            self.detectPrice(string: arr?.last)
            self.filterCaptionForEmojis(inputString: textView.text)
        }
            
//        else if (text == " ") || (isBackSpace == -92){
//
//        }

        return true
        
    }

    
    
    func detectPrice(string: String?){
        guard let string = string else {return}
        if string.first != "$" {return}
        
        var price = string.replacingOccurrences(of: "$", with: "").removingWhitespaces()
        if let price = Double(price) {
            var priceSegment: Int? = nil
            
            if price <= 5 {
                priceSegment = 0
            } else if price <= 10 {
                priceSegment = 1
            } else if price <= 20 {
                priceSegment = 2
            } else if price <= 35 {
                priceSegment = 3
            } else if price <= 50 {
                priceSegment = 4
            } else if price > 50 {
                priceSegment = 5
            }
            
            if let priceSegment = priceSegment {
                self.postPriceSegment.selectedSegmentIndex = priceSegment
                self.postPriceSegment.tintColor = UIColor.legitColor()
                self.selectPostPrice = UploadPostPriceDefault[priceSegment]
                print("Auto Price Segment Select: \(priceSegment) From \(string)")
            }
        }
        
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        // Clears Out Default Caption
        if textView.text == captionDefault {
            textView.text = nil
        }
        textView.textColor = UIColor.black
        
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == captionTextView {
            
            if textView.text.isEmpty {
                self.resetCaptionTextView()
            }
            
            // Hide AutoComplete
            self.emojiAutoComplete.isHidden = true
            self.filteredEmojis.removeAll()
        }
    }
    
    
    func resetCaptionTextView() {
        self.captionTextView.text = captionDefault
        self.captionTextView.textColor = UIColor.lightGray
    }
    
    // EmojiAutoComplete
    var emojiAutoComplete: UITableView!
    let EmojiAutoCompleteCellId = "EmojiAutoCompleteCellId"
    var filteredEmojis:[EmojiBasic] = []
    var isAutocomplete: Bool = false
    
    func setupEmojiAutoComplete() {
        
        // Emoji Autocomplete View
        emojiAutoComplete = UITableView()
        emojiAutoComplete.register(SearchResultsCell.self, forCellReuseIdentifier: EmojiAutoCompleteCellId)
        emojiAutoComplete.delegate = self
        emojiAutoComplete.dataSource = self
        emojiAutoComplete.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
        emojiAutoComplete.backgroundColor = UIColor.white
        
        self.refreshEmojiTagSelections()
        
    }
    
    func appendEmojis(currentEmojis: [String]?, newEmojis: [String]?) -> [String]{
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
    
    
    
    @objc func showUserMostUsedEmojis(){
        self.showUserMostUsedEmojiInd = !self.showUserMostUsedEmojiInd
        userMostUsedEmojiButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.userMostUsedEmojiButton.transform = .identity
                        self?.userMostUsedEmojiButton.alpha = (self?.showUserMostUsedEmojiInd)! ? 1 : 0.5
                        self?.userMostUsedEmojiButton.transform = .identity
            },
                       completion: nil)
        
        
        self.refreshEmojiTagSelections()
    }
    
    @objc func showLocationSuggestedEmojis(){
        self.showlocationMostUsedEmojiInd = !self.showlocationMostUsedEmojiInd
        locationMostUsedEmojiButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.locationMostUsedEmojiButton.transform = .identity
                        self?.locationMostUsedEmojiButton.alpha = (self?.showlocationMostUsedEmojiInd)! ? 1 : 0.5
                        self?.locationMostUsedEmojiButton.transform = .identity
            },
                       completion: nil)
        
        self.refreshEmojiTagSelections()
    }
    
    func showDefaultSuggestedEmojis(){
        self.showlocationMostUsedEmojiInd = false
        self.showUserMostUsedEmojiInd = false
        self.refreshEmojiTagSelections()
    }
    
    
    var emojiIndex:[String:Int] = [:]
    
    func filterEmojiSelections(){
        var tempEmojis :[String] = []
        self.emojiIndex.removeAll()
        
        if self.selectedEmojiFilter == nil {
            // AUTO - Show Caption Suggested, then User Recent, then all
            
            // 1a. Caption Emojis
            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: captionEmojis)
        
            // 1b. Location Most Used Emojis
            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: self.locationMostUsedEmojis)

            // 1c. Most Used Emojis
            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: Array(CurrentUser.mostUsedEmojis.prefix(10)))
            
            // 1d. Default Emojis - Meal Emojis
            if mealTagEmojis.count > 0 {
                if mealTagEmojis.contains(where: { (emoji) -> Bool in
                    return emoji.name == "breakfast" || emoji.name == "brunch"
                }) {tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: breakfastFoodEmojis)}
                
                if mealTagEmojis.contains(where: { (emoji) -> Bool in
                    return emoji.name == "lunch"
                }) {tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: lunchFoodEmojis)}
                
                if mealTagEmojis.contains(where: { (emoji) -> Bool in
                    return emoji.name == "dinner" || emoji.name == "latenight"
                }) {tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: dinnerFoodEmojis)}
                
                if mealTagEmojis.contains(where: { (emoji) -> Bool in
                    return emoji.name == "dessert" || emoji.name == "coffee"
                }) {tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: snackEmojis)}
                
                if mealTagEmojis.contains(where: { (emoji) -> Bool in
                    return emoji.name == "drinks"
                }) {tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: allDrinkEmojis)}
            }
            
            
            //1e. Default Emojis
            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: allDefaultEmojis)
            
        } else if self.selectedEmojiFilter == "Recent" {
            tempEmojis.append(self.selectedEmojiFilter ?? "")
            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: CurrentUser.mostUsedEmojis)
        } else if self.selectedEmojiFilter == "Food" {
            tempEmojis.append(self.selectedEmojiFilter ?? "")
            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: SET_FoodEmojis)
        } else if self.selectedEmojiFilter == "Drink" {
            tempEmojis.append(self.selectedEmojiFilter ?? "")
            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: SET_DrinkEmojis)
        } else if self.selectedEmojiFilter == "Snack" {
            tempEmojis.append(self.selectedEmojiFilter ?? "")
            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: SET_SnackEmojis)
        } else if self.selectedEmojiFilter == "Raw" {
            tempEmojis.append(self.selectedEmojiFilter ?? "")
            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: SET_RawEmojis)
        } else if self.selectedEmojiFilter == "Veg" {
            tempEmojis.append(self.selectedEmojiFilter ?? "")
            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: SET_VegEmojis)
        } else if self.selectedEmojiFilter == "Smiley" {
            tempEmojis.append(self.selectedEmojiFilter ?? "")
            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: SET_SmileyEmojis)
        } else if self.selectedEmojiFilter == "Flag" {
            tempEmojis.append(self.selectedEmojiFilter ?? "")
            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: SET_FlagEmojis)
        }
        
        self.emojiTagSelection = tempEmojis
        self.suggestedEmojiCollectionView.reloadData()
        self.filterEmojiCollectionView.collectionViewLayout.invalidateLayout()
        self.filterEmojiCollectionView.reloadData()

        self.extraRatingEmojiCollectionView.reloadData()
        
    }
    
    
    func refreshEmojiTagSelections(){
        var tempEmojis :[String] = []
        self.emojiIndex.removeAll()
        
        self.userMostUsedEmojiButton.alpha = self.showUserMostUsedEmojiInd ? 1 : 0.5
        self.userMostUsedEmojiButton.backgroundColor = self.showUserMostUsedEmojiInd ? UIColor.selectedColor() : UIColor.lightGray.withAlphaComponent(0.5)
        
        self.locationMostUsedEmojiButton.alpha = self.showlocationMostUsedEmojiInd ? 1 : 0.5
        self.locationMostUsedEmojiButton.backgroundColor = self.showlocationMostUsedEmojiInd ? UIColor.selectedColor() : UIColor.lightGray.withAlphaComponent(0.5)
        
        if (self.locationMostUsedEmojis.count) == 0 {
            // NO LOCATION EMOJIS
            print("refreshEmojiTagSelections | No Location Emojis | Hide Location Emoji Button")
            self.showlocationMostUsedEmojiInd = false
            self.locationMostUsedEmojiButton.isHidden = true
        } else {
            // HAS LOCATION EMOJIS - SHOW LOCATION EMOJI BUTTON
            self.locationMostUsedEmojiButton.isHidden = false
        }
        self.view.updateConstraintsIfNeeded()
        
        // 1a. Caption Emojis
        tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: captionEmojis)
        
        emojiIndex["caption"] = tempEmojis.count ?? 0
        
        // 1b. Location Most Used Emojis
            if self.showlocationMostUsedEmojiInd {
                tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: self.locationMostUsedEmojis)
            }
            
        // 1c. User Top 10 Most Used Emojis
            if self.showUserMostUsedEmojiInd{
                tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: Array(CurrentUser.mostUsedEmojis.prefix(10)))
            }
        
        emojiIndex["mostused"] = tempEmojis.count ?? 0

            // Default Emojis - Meal Emojis
            if mealTagEmojis.count > 0 {
                if mealTagEmojis.contains(where: { (emoji) -> Bool in
                    return emoji.name == "breakfast" || emoji.name == "brunch"
                }) {tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: breakfastFoodEmojis)}
                
                if mealTagEmojis.contains(where: { (emoji) -> Bool in
                    return emoji.name == "lunch"
                }) {tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: lunchFoodEmojis)}
                
                if mealTagEmojis.contains(where: { (emoji) -> Bool in
                    return emoji.name == "dinner" || emoji.name == "latenight"
                }) {tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: dinnerFoodEmojis)}
                
                if mealTagEmojis.contains(where: { (emoji) -> Bool in
                    return emoji.name == "dessert" || emoji.name == "coffee"
                }) {tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: snackEmojis)}
                
//                if mealTagEmojis.contains(where: { (emoji) -> Bool in
//                    return emoji.name == "drinks"
//                }) {tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: allFoodEmojis + allDrinkEmojis)}
            }

        emojiIndex["food"] = tempEmojis.count ?? 0

        
            //3. Drinks
            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: allDrinkEmojis)
        
        emojiIndex["drinks"] = tempEmojis.count ?? 0

        
            //4. Default Emojis
            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: allDefaultEmojis)
        
        self.emojiTagSelection = tempEmojis
        self.suggestedEmojiCollectionView.reloadData()
        self.extraRatingEmojiCollectionView.reloadData()
    }
    
    

    func filterCaptionForEmojis(inputString: String) {
        var tempEmojis:[String] = []
        var tempSingleCaptionWords = inputString.lowercased().components(separatedBy: " ")
        if tempSingleCaptionWords.count == 0 {
            return
        }
        
        // Detect Emojis in String
        if inputString.emojis.count > 0 {
            for emoji in inputString.emojis {
                if emoji != "" {
                    tempEmojis.append(emoji)
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
        
        
        // WE use the many to one mapping to detect appropriate emojis (eg: sushi, sashimi, etc) but then the tagged emoji will only correspond to one definition
        
        for word in tempAllLookUpWords {
            // Look up Emoji based on word
            if let tempEmoji = ReverseEmojiDictionary[word] {
                if !tempEmojis.contains(tempEmoji){
                    tempEmojis.append(tempEmoji)
                }
            }

            // Look up Emoji based on word without s at the end
            if word.suffix(1) == "s" {
                if let tempEmoji = ReverseEmojiDictionary[String(word.dropLast())] {
                    if !tempEmojis.contains(tempEmoji){
                        tempEmojis.append(tempEmoji)
                    }
                }
            }


            // Find Auto Tags
            for (index, dic) in allAutoTagDictionary.enumerated() {
                if let matchEmoji = dic.key(forValue: word) {
                    let tempEmoji = EmojiBasic(emoji: matchEmoji, name: word, count: 0)
                    if !allAutoTagEmojis.contains(where: { (emoji) -> Bool in
                        emoji.name == tempEmoji.name
                    }){
                        print("Adding Auto Tag | \(tempEmoji)")
                        // Not in Auto tag. Adding to Auto Tag
                        if index == 0 {
                            self.mealTagEmojis.append(tempEmoji)
                        } else if index == 1 {
                            self.cuisineTagEmojis.append(tempEmoji)
                        } else if index == 2 {
                            self.dietTagEmojis.append(tempEmoji)
                        }
                    }
                }
            }
        }
//
        self.captionEmojis = tempEmojis
    }
    
    
    func filterContentForSearchText(inputString: String) {
        filteredEmojis = allEmojis.filter({( emoji : EmojiBasic) -> Bool in
            return emoji.emoji.lowercased().contains(inputString.lowercased()) || (emoji.name?.contains(inputString.lowercased()))!
        })

        
        // Show only if filtered emojis not 0
        if filteredEmojis.count > 0 {
            self.emojiAutoComplete.isHidden = false
        } else {
            self.emojiAutoComplete.isHidden = true
        }
        
        // Sort results based on prefix
        filteredEmojis.sort { (p1, p2) -> Bool in
            ((p1.name?.hasPrefix(inputString.lowercased()))! ? 0 : 1) < ((p2.name?.hasPrefix(inputString.lowercased()))! ? 0 : 1)
        }
        
        self.emojiAutoComplete.reloadData()
    }
    
    // Tableview delegate functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredEmojis.count

    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
            let cell = tableView.dequeueReusableCell(withIdentifier: EmojiAutoCompleteCellId, for: indexPath) as! SearchResultsCell
            cell.emoji = filteredEmojis[indexPath.row]
            return cell

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var emojiSelected = filteredEmojis[indexPath.row]
        var selectedWord = emojiSelected.name
        var selectedEmoji = emojiSelected.emoji
        var tempEmojiWords = selectedWord?.components(separatedBy: " ")
        var tempCaptionWords = self.captionTextView.text.lowercased().components(separatedBy: " ")
        var lastWord = tempCaptionWords[tempCaptionWords.endIndex - 1]
        var addedString : String?
        
        var originalCaptionWords = self.captionTextView.text.components(separatedBy: " ")
        if originalCaptionWords.last == "" {
            originalCaptionWords = Array(originalCaptionWords.dropLast())
        }
        
        if tempCaptionWords.count < 2 {
            // Capitalize string
            addedString = emojiSelected.name?.capitalized
        } else {
            addedString = " " + emojiSelected.name!
        }
        
        if tempEmojiWords?.count == 1 || tempCaptionWords.count < 2 {
            // Only one emoji caption or only one word currently in caption, so just substitute last word
            
            self.captionTextView.text = originalCaptionWords.dropLast().joined(separator: " ") + (addedString)! + " "
            
        } else if tempEmojiWords?.count == 2 {
            // 2 words, so will have to check if previous word should be taken out
            let secondLastWord = tempCaptionWords[tempCaptionWords.endIndex - 2]
            if secondLastWord == tempEmojiWords?[0] {
                // 2nd last word matches first word of 2 word emoji tag, so drop 2nd last word
                if tempCaptionWords.count == 2 {
                    addedString = emojiSelected.name?.capitalized
                }
                self.captionTextView.text = originalCaptionWords.dropLast(2).joined(separator: " ") + (addedString)! + " "
            }
            else {
                self.captionTextView.text = originalCaptionWords.dropLast().joined(separator: " ") + (addedString)! + " "
            }
        }
        self.isAutocomplete = false
        self.emojiAutoComplete.isHidden = true
        
        // Only Tag Untag from auto-complete if current emoji tag does not contain the emoji
        if !self.nonRatingEmojiTags.contains(emojiSelected.emoji){
            self.addRemoveEmojiTags(emojiInput: emojiSelected.emoji, emojiInputTag: emojiSelected.name!)
        }
    }
    
    func setEmojiTags(emojiInput: [String]?) {
        nonRatingEmojiTags = []
        nonRatingEmojiTagsDict = []
        
        guard let emojiInput = emojiInput else {return}
        
        for emoji in emojiInput {
            let emoji_dic = EmojiDictionary[emoji] ?? ""
            nonRatingEmojiTags.append(emoji)
            nonRatingEmojiTagsDict.append(emoji_dic)
        }
        self.updateEmojiTextView()
        self.suggestedEmojiCollectionView.reloadData()
    }
    
    
    func addRemoveEmojiTags(emojiInput: String?, emojiInputTag: String?){
        
        var tempEmojiInput: String? = emojiInput
        var tempEmojiInputTag: String? = emojiInputTag
        
        if emojiInput?.containsOnlyEmoji == false {
            print("EmojiTagUntag: Error, Emoji Input not emoji | \(emojiInput)")
            return
        }
        
        // Fill Blank Emoji Tag
        if emojiInput != nil && emojiInputTag ==  nil  {
            if let tempTag = EmojiDictionary[emojiInput!] {
                tempEmojiInputTag = tempTag
                print("Found Emoji Dict for \(emojiInput) | Tag = \(tempEmojiInputTag)")
            } else {
                tempEmojiInputTag = emojiInput
                print("NO Emoji Dict for \(emojiInput) | Tag = \(tempEmojiInputTag)")
            }
        }
        
        // Fill Blank Emoji
        if emojiInput == nil && emojiInputTag !=  nil  {
            if let tempEmoji = EmojiDictionary.key(forValue: emojiInputTag!) {
                print("Found Emoji for \(emojiInputTag) | Emoji = \(tempEmoji)")
                tempEmojiInput = tempEmoji
            } else {
                print("NO Emoji for \(emojiInputTag) | ERROR")
                tempEmojiInput = nil
            }
        }
        
        if emojiInput == nil && emojiInputTag == nil {
            print("No Emoji Inputs |emojiInput \(emojiInput) |emojiInputTag \(emojiInputTag) | CLEAR ALL")
            self.nonRatingEmojiTags = []
            self.nonRatingEmojiTagsDict = []
            self.updateEmojiTextView()
            self.suggestedEmojiCollectionView.reloadData()
            return
        }
        
        guard let _ = tempEmojiInput else {
            print("EmojiTagUntag: Error, No Emoji: ", tempEmojiInput)
            return
        }
        
        guard let _ = tempEmojiInputTag else {
            print("EmojiTagUntag: Error, No Emoji Tag: ", tempEmojiInputTag)
            return
        }
        
        
        if let index = nonRatingEmojiTags.firstIndex(of: tempEmojiInput!){
            nonRatingEmojiTags.remove(at: index)
            nonRatingEmojiTagsDict.remove(at: index)
            print("addRemoveEmojiTags | Removing \(tempEmojiInput!) \(tempEmojiInputTag!))")

        } else {
            if nonRatingEmojiTags.count >= 3 {
                print("addRemoveEmojiTags | 3 Emojis | Replacing Last Emoji | \(tempEmojiInput!) \(tempEmojiInputTag!))")
                nonRatingEmojiTags[nonRatingEmojiTags.count - 1] = tempEmojiInput!
                nonRatingEmojiTagsDict[nonRatingEmojiTagsDict.count - 1] = tempEmojiInputTag!
            } else {
                print("addRemoveEmojiTags | \(nonRatingEmojiTags.count) Emojis | Add Emoji | \(tempEmojiInput!) \(tempEmojiInputTag!))")
                nonRatingEmojiTags.append(tempEmojiInput!)
                nonRatingEmojiTagsDict.append(tempEmojiInputTag!)
            }

            
//            nonRatingEmojiTags = [tempEmojiInput] as! [String]
//            nonRatingEmojiTagsDict = [tempEmojiInputTag] as! [String]
        }
        self.updateEmojiTextView()
        self.suggestedEmojiCollectionView.reloadData()
    }
    
    func updateEmojiTextView(){
        for view in selectedEmojiTagArray {
            view.text = ""
            view.alpha = 0.5
        }
        
        for (index, emoji) in nonRatingEmojiTags.enumerated() {
            if index >= 3 {return}
            selectedEmojiTagArray[index].text = emoji
            selectedEmojiTagArray[index].alpha = 1
        }
//        self.suggestedEmojiCollectionView.reloadData()

    }
    
    
    
    @objc func handleDoubleTap(_ gestureReconizer: UITapGestureRecognizer) {
        
        let p = gestureReconizer.location(in: self.view)
        
        
        let point = self.suggestedEmojiCollectionView.convert(p, from:self.view)
        let indexPath = self.suggestedEmojiCollectionView.indexPathForItem(at: point)
        
        if let index = indexPath  {
            let cell = self.suggestedEmojiCollectionView.cellForItem(at: index) as! UploadEmojiCell
            guard let selectedEmoji = cell.uploadEmojis.text else {return}
            print("Double Tap Emoji: ", selectedEmoji   )
            self.addRemoveEmojiTags(emojiInput: selectedEmoji, emojiInputTag: EmojiDictionary[selectedEmoji] ?? "")

            // do stuff with your cell, for example print the indexPath
        } else {
            print("Could not find index path")
        }
    }
    
    func handleTripleTap(_ gestureReconizer: UITapGestureRecognizer) {
        
        let p = gestureReconizer.location(in: self.view)
        let point = self.suggestedEmojiCollectionView.convert(p, from:self.view)
        let indexPath = self.suggestedEmojiCollectionView.indexPathForItem(at: point)
        
        print(indexPath)
        
        if let index = indexPath  {
            
            let cell = self.suggestedEmojiCollectionView.cellForItem(at: index) as! UploadEmojiCell
            guard let selectedEmoji = cell.uploadEmojis.text else {return}
            print("Double Tap Emoji: ", selectedEmoji   )
            
            
            //                print(cell.uploadEmojis.text)
            
            self.addRemoveEmojiTags(emojiInput: selectedEmoji, emojiInputTag: EmojiDictionary[selectedEmoji] ?? "")
            // do stuff with your cell, for example print th@objc e indexPath
            
        } else {
            print("Could not find index path")
        }
    }
    
    @objc func handleLongPress(_ gestureReconizer: UILongPressGestureRecognizer) {
        
        let p = gestureReconizer.location(in: self.view)
        let subViews = self.view.subviews
        if gestureReconizer.state != UIGestureRecognizer.State.recognized {
            
            let point = self.suggestedEmojiCollectionView.convert(p, from:self.view)
            let indexPath = self.suggestedEmojiCollectionView.indexPathForItem(at: point)
            
            if let index = indexPath  {
                let cell = self.suggestedEmojiCollectionView.cellForItem(at: index) as! UploadEmojiCell
                print(cell.uploadEmojis.text)
                guard let selectedEmoji = cell.uploadEmojis.text else {
                    print("Handle Long Press: ERROR, No Emoji")
                    return}
                
                // Clear Emojis if long press and contains emoji
                
                if nonRatingEmojiTags.contains(selectedEmoji){
                    self.addRemoveEmojiTags(emojiInput: selectedEmoji, emojiInputTag: EmojiDictionary[selectedEmoji] ?? "")
                }
                
                // Display Emoji Detail Label
                if let emojiTagLookup = ReverseEmojiDictionary.key(forValue: selectedEmoji) {
                    emojiDetailLabel.text = selectedEmoji + " " + emojiTagLookup.capitalizingFirstLetter()
                    emojiDetailLabel.alpha = 1
                }
            } else {
                print("Could not find index path")
            }
        }
            
        else if gestureReconizer.state != UIGestureRecognizer.State.changed {
            
            let point = self.suggestedEmojiCollectionView.convert(p, from:self.view)
            let indexPath = self.suggestedEmojiCollectionView.indexPathForItem(at: point)
            
            if let index = indexPath  {
                // Removes label subview when released
                emojiDetailLabel.alpha = 0
                
                let cell = self.suggestedEmojiCollectionView.cellForItem(at: index) as! UploadEmojiCell
            } else {
                print("Could not find index path")
            }
            return
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == placesCollectionView {
            return nearbyGoogleLocations.count
            print("Nearby Google Locations | \(nearbyGoogleLocations.count)")

//            return googlePlaceNames.count
            
        }
            
        else if collectionView == suggestedEmojiCollectionView {
            return self.emojiTagSelection.count}
        
        else if collectionView == extraRatingEmojiCollectionView {
            print("Extra Rating | \(extraRatingEmojis.count)")
            return extraRatingEmojis.count
        }
        
        if collectionView == mealTypeCollectionView
        {
            print("Meal | \(self.mealTagEmojis.count)")
            return self.mealTagEmojis.count
        }
        else if collectionView == cuisineTypeCollectionView
        {
            print("Cuisine | \(self.mealTagEmojis.count)")
            return self.cuisineTagEmojis.count
        }
        else if collectionView == dietTypeCollectionView
        {
            print("Diet | \(self.mealTagEmojis.count)")
            return self.dietTagEmojis.count
        }
        else if collectionView == filterEmojiCollectionView
        {
            print("Filter Emoji Options | \(self.selectedEmojiFilterOptions.count)")
            return self.selectedEmojiFilterOptions.count
        }

        else {return 0}
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
    // SUGGESTED LOCATION NAME CELLS
        if collectionView == placesCollectionView {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: locationCellID, for: indexPath) as! UploadLocationCell
                        cell.uploadLocations.text = nearbyGoogleLocations[indexPath.item].locationName?.truncate(length: 20)
            cell.backgroundColor = self.selectPostGooglePlaceID == nearbyGoogleLocations[indexPath.item].locationGoogleID ? UIColor.legitColor() : UIColor.white
            cell.uploadLocations.textColor = self.selectPostGooglePlaceID == nearbyGoogleLocations[indexPath.item].locationGoogleID ? UIColor.white : UIColor.black
            return cell
        }
        
    // SUGGESTED EMOJI  CELLS
        if collectionView == suggestedEmojiCollectionView {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emojiCellID, for: indexPath) as! UploadEmojiCell
            cell.uploadEmojis.text = self.emojiTagSelection[indexPath.item]
            cell.uploadEmojis.font = cell.uploadEmojis.font.withSize((cell.uploadEmojis.text?.containsOnlyEmoji)! ? EmojiSize.width * 0.8 : 10)
            
            //Highlight only if emoji is tagged, dont care about caption
            cell.backgroundColor = (self.nonRatingEmojiTags.contains(cell.uploadEmojis.text!)) ? UIColor.selectedColor() : UIColor.white
            cell.layer.borderColor = (self.nonRatingEmojiTags.contains(cell.uploadEmojis.text!)) ? UIColor.selectedColor().cgColor : UIColor.lightGray.cgColor
            
            // HANDLE COLORS
//            let row = indexPath.row
//            if row < emojiIndex["mostused"] ?? 0 {
//                cell.layer.borderColor = UIColor.red.cgColor
//            } else if row < emojiIndex["caption"] ?? 0 {
//                cell.layer.borderColor = UIColor.blue.cgColor
//            } else if row < emojiIndex["food"] ?? 0 {
//                cell.layer.borderColor = UIColor.green.cgColor
//            } else if row < emojiIndex["drinks"] ?? 0  {
//                cell.layer.borderColor = UIColor.selectedColor().cgColor
//            } else {
//                cell.layer.borderColor = UIColor.black.cgColor
//            }
            
            cell.isSelected = self.nonRatingEmojiTags.contains(cell.uploadEmojis.text!)
            cell.sizeToFit()
            return cell
            
        }
        
        else if collectionView == extraRatingEmojiCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: testemojiCellID, for: indexPath) as! UploadEmojiCell
            cell.uploadEmojis.text = extraRatingEmojis[indexPath.item]
            cell.backgroundColor = (self.ratingEmojiTag == (cell.uploadEmojis.text!)) ? UIColor.selectedColor().withAlphaComponent(0.8) : UIColor.clear
            cell.layer.borderColor = (self.ratingEmojiTag == (cell.uploadEmojis.text!)) ? UIColor.selectedColor().cgColor : UIColor.clear.cgColor
            cell.isSelected = self.ratingEmojiTag == (cell.uploadEmojis.text!)
            cell.sizeToFit()

            return cell
        }
            
        else if collectionView == filterEmojiCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emojiFilterCellID, for: indexPath) as! EmojiFilterCell
            var isEmojiFilter = (self.selectedEmojiFilter == selectedEmojiFilterOptions[indexPath.row])
            
            cell.uploadLocations.text = selectedEmojiFilterOptions[indexPath.row]
            cell.backgroundColor = isEmojiFilter ? UIColor.legitColor() : UIColor.white
            cell.uploadLocations.textColor = isEmojiFilter ? UIColor.darkLegitColor() : UIColor.mainBlue()
            cell.uploadLocations.font = isEmojiFilter ? UIFont.boldSystemFont(ofSize: 12) : UIFont.systemFont(ofSize: 12)
            cell.uploadLocations.sizeToFit()
            cell.sizeToFit()
            return cell
        }
            
//        if collectionView == autoTagDetails {
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: autoTagDetailId, for: indexPath) as! AutoTagDetailCell
//            cell.emoji = allAutoTagEmojis[indexPath.item]
//
//            if mealTypeAutoTag.contains((cell.emoji?.name)!) {
//                cell.tag = 0
//            } else if cuisineAutoTag.contains((cell.emoji?.name)!) {
//                cell.tag = 1
//            } else if dietAutoTag.contains((cell.emoji?.name)!) {
//            cell.tag = 2
//            } else {
//                cell.tag = 9
//            }
//
//            cell.emojiTextLabel.adjustsFontSizeToFitWidth = true
//
//            return cell
//        }
        
        else if collectionView == mealTypeCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: autoTagDetailId, for: indexPath) as! AutoTagDetailCell
            cell.emoji = self.mealTagEmojis[indexPath.row]
            cell.tag = 0
            cell.emojiTextLabel.adjustsFontSizeToFitWidth = true
            return cell
        }
        
        else if collectionView == cuisineTypeCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: autoTagDetailId, for: indexPath) as! AutoTagDetailCell
            cell.emoji = self.cuisineTagEmojis[indexPath.row]
            cell.tag = 1
            cell.emojiTextLabel.adjustsFontSizeToFitWidth = true
            return cell
        }
        
        else if collectionView == dietTypeCollectionView  {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: autoTagDetailId, for: indexPath) as! AutoTagDetailCell
            cell.emoji = self.dietTagEmojis[indexPath.row]
            cell.tag = 2
            cell.emojiTextLabel.adjustsFontSizeToFitWidth = true
            return cell
        }
        
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emojiCellID, for: indexPath) as! UploadEmojiCell
            cell.uploadEmojis.text = EmoticonArray[0][(indexPath as IndexPath).row]
            return cell
        }
    }
    
    //        if collectionView == EmojiCollectionView {
    //            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emojiCellID, for: indexPath) as! UploadEmojiCell
    //
    //            let columns = collectionView.numberOfItems(inSection: indexPath.section) / emojiCollectionViewRows
    //            let i = indexPath.item / emojiCollectionViewRows
    //            let j = indexPath.item % emojiCollectionViewRows
    //            let newIndex = j*columns+i
    //
    //
    //            cell.uploadEmojis.text = EmoticonArray[(indexPath as IndexPath).section][newIndex]
    //
    //            if (self.selectEmojis.contains(cell.uploadEmojis.text!)/*||self.captionTextView.text.contains(cell.uploadEmojis.text!)*/){
    //                //Highlight only if emoji is tagged, dont care about caption
    //
    //                cell.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
    //            } else {
    //                cell.backgroundColor = UIColor.white
    //            }
    //            return cell
    //        }
    //

    
    func fadeViewInThenOut(view : UIView, delay: TimeInterval) {
        
        let animationDuration = 0.25
        
        // Fade in the view
        UIView.animate(withDuration: animationDuration, animations: { () -> Void in
            view.alpha = 1
        }) { (Bool) -> Void in
            
            // After the animation completes, fade out the view after a delay
            
            UIView.animate(withDuration: animationDuration, delay: delay, options: .curveEaseInOut, animations: { () -> Void in
                view.alpha = 0
            },
                           completion: nil)
        }
    }
    
    func hideExtraRatingCollectionView(){
        self.extraRatingEmojiCollectionView.reloadData()
        self.extraRatingEmojiCollectionView.isHidden = true
        self.extraRatingInfoButton.isHidden = true
        self.locationNameLabelBox.isHidden = false
    }
    
    func showExtraRatingCollectionView(){
        self.extraRatingEmojiCollectionView.reloadData()
        self.extraRatingEmojiCollectionView.isHidden = false
        self.extraRatingInfoButton.isHidden = false
        self.locationNameLabelBox.isHidden = true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        
        if collectionView == suggestedEmojiCollectionView{
            let cell = collectionView.cellForItem(at: indexPath) as! UploadEmojiCell
            let pressedEmoji = cell.uploadEmojis.text!
            print("Emoji Cell Selected", pressedEmoji)

            if self.nonRatingEmojiTags.contains(pressedEmoji) == false
            {   // Emoji not in caption or tag

                // Show Emoji Detail
                if let emojiTagLookup = ReverseEmojiDictionary.key(forValue: pressedEmoji) {
                    emojiDetailLabel.text = pressedEmoji + " " + emojiTagLookup
                    self.fadeViewInThenOut(view: emojiDetailLabel, delay: 1)
                }
                
                self.addRemoveEmojiTags(emojiInput: pressedEmoji, emojiInputTag: ReverseEmojiDictionary.key(forValue: pressedEmoji) ?? "")

            } else if self.nonRatingEmojiTags.contains(pressedEmoji) == true {
                // Emoji is Tagged, Remove emoji from captions and selected emoji
                self.addRemoveEmojiTags(emojiInput: pressedEmoji, emojiInputTag: ReverseEmojiDictionary.key(forValue: pressedEmoji) ?? "")
            }
        }
            
        else if collectionView == extraRatingEmojiCollectionView{
            let cell = collectionView.cellForItem(at: indexPath) as! UploadEmojiCell
            let pressedEmoji = cell.uploadEmojis.text!
            print("Emoji Cell Selected", pressedEmoji)
            
            if self.ratingEmojiTag == pressedEmoji {
                self.ratingEmojiTag = ""
            } else {
                self.ratingEmojiTag = pressedEmoji
            }
            
            self.hideExtraRatingCollectionView()
            
        }

        else if collectionView == placesCollectionView {
            if indexPath.item >= self.nearbyGoogleLocations.count {
                return
            }
            
            // Unselects Location and defaults to image location
            if self.selectedPostLocationItem?.locationGoogleID == self.nearbyGoogleLocations[indexPath.item].locationGoogleID {
                self.selectedPostLocationItem = self.selectedImageLocationItem
                self.locationMostUsedEmojis.removeAll()
                self.showlocationMostUsedEmojiInd = false
            } else {
                self.selectedPostLocationItem = self.nearbyGoogleLocations[indexPath.item]
            }
            
//            if indexPath.item >= self.googlePlaceIDs.count {
//                return
//            }
//
//            // Unselects Location
//            if self.selectPostGooglePlaceID == self.googlePlaceIDs[indexPath.item] {
//                self.didUpdate(locationGPS: self.selectedImageLocation, locationAdress: self.imageLocationGoogleAdress, locationName: self.imageLocationGoogleAdress, locationGooglePlaceID: nil, locationGooglePlaceType: nil)
//
//            } else {
//            // Select Google Location
//                self.didUpdate(locationGPS: self.googlePlaceLocations[indexPath.item], locationAdress: self.googlePlaceAdresses[indexPath.item], locationName: self.googlePlaceNames[indexPath.item], locationGooglePlaceID: self.googlePlaceIDs[indexPath.item], locationGooglePlaceType: self.googlePlaceTypes[indexPath.item])
//                    collectionView.scrollToItem(at: IndexPath(row: 0, section: 0),at: .top,animated: true)
//            }
        } else if collectionView == filterEmojiCollectionView {
            let cell = collectionView.cellForItem(at: indexPath) as! EmojiFilterCell

            guard let filter = cell.uploadLocations.text else {
                return
            }
            
            if self.selectedEmojiFilter == filter {
                self.selectedEmojiFilter = nil
            } else {
                self.selectedEmojiFilter = filter
            }
            print("filterEmojiCollectionView | SelectedEmojiFilter | \(self.selectedEmojiFilter)")
            
            self.filterEmojiSelections()
            
        }
        
        else if autoTagCollectionViews.contains(collectionView)  {
         
            let cell = collectionView.cellForItem(at: indexPath) as! AutoTagDetailCell
            
            let autoTag = AutoTagTableViewController()
            autoTag.delegate = self
            autoTag.selectedScope = cell.tag
            
            autoTag.selectedMealTagEmojis = self.mealTagEmojis
            autoTag.selectedCuisineTagEmojis = self.cuisineTagEmojis
            autoTag.selectedDietTagEmojis = self.dietTagEmojis
            
            self.navigationController?.pushViewController(autoTag, animated: true)
            
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {

        if collectionView == suggestedEmojiCollectionView{
            let cell = collectionView.cellForItem(at: indexPath) as! UploadEmojiCell
            let pressedEmoji = cell.uploadEmojis.text!
            print("Emoji Cell Deselected", pressedEmoji)
            
            self.addRemoveEmojiTags(emojiInput: pressedEmoji, emojiInputTag: ReverseEmojiDictionary.key(forValue: pressedEmoji) ?? "")

        }
        // Deselect Doesn't work for emojis since scells are constantly being reloaded and hence selection is restarted
    }
    
    @objc func handleNext(){
        
        guard let postImages = selectedImages else {
            self.alert(title: "Upload Post Requirement", message: "Please Insert Picture")
            return}
        
        if self.selectedPostLocationItem == nil {
            self.presentLocationCheck()
        } else {
            self.finishToListTags()
        }
    
    }
    

    func presentLocationCheck(){
        let optionsAlert = UIAlertController(title: "New Post Alert", message: "You don't have a location tagged to this post. Would you like to continue posting without a location?", preferredStyle: UIAlertController.Style.alert)
        
        optionsAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
            // Allow Editing
            self.finishToListTags()
            
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Google Search Location", style: .default, handler: { (action: UIAlertAction!) in
            // Allow Editing
            self.tapSearchBar()

        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        present(optionsAlert, animated: true, completion: nil)
    }
    
    
    func finishToListTags(){
        guard let postImages = selectedImages else {
            self.alert(title: "Upload Post Requirement", message: "Please Insert Picture")
            return}
        
        // Upload Name Adress that matches inputs
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        // Post Location Details
        var postLocationName = self.selectPostLocationName ?? nil
        if postLocationName == blankGPSName {postLocationName = nil}
        let postLocationAdress = self.selectPostLocationAdress ?? nil
        let postLocationSummaryID = self.selectPostlocationSummaryID ?? nil
        let googlePlaceID = selectPostGooglePlaceID ?? nil
        
        
        var uploadedLocationGPSLatitude: String?
        var uploadedlocationGPSLongitude: String?
        var uploadedLocationGPS: String?
        
        var uploadedImageLocationGPSLatitude: String?
        var uploadedImageLocationGPSLongitude: String?
        var uploadedImageLocationGPS: String?
        
        if selectPostLocation == nil {
            uploadedLocationGPSLatitude = "0"
            uploadedlocationGPSLongitude = "0"
            uploadedLocationGPS = nil
        } else {
            uploadedLocationGPSLatitude = String(format: "%f", (selectPostLocation?.coordinate.latitude)!)
            uploadedlocationGPSLongitude = String(format: "%f", (selectPostLocation?.coordinate.longitude)!)
            uploadedLocationGPS = uploadedLocationGPSLatitude! + "," + uploadedlocationGPSLongitude!
        }
        
        if selectedImageLocation == nil {
            uploadedImageLocationGPS = nil
        } else {
            uploadedImageLocationGPSLatitude = String(format: "%f", (selectedImageLocation?.coordinate.latitude)!)
            uploadedImageLocationGPSLongitude = String(format: "%f", (selectedImageLocation?.coordinate.longitude)!)
            uploadedImageLocationGPS = uploadedLocationGPSLatitude! + "," + uploadedlocationGPSLongitude!
        }
        
        // Caption
        var caption = captionTextView.text
        if caption == captionDefault {caption = nil}
        
        // rating
        let rating = self.selectPostStarRating ?? 0
        
        // legit
        //            let legitInd = self.isLegit ?? false
        
        // Emojis
        let nonratingEmojiUpload = self.nonRatingEmojiTags ?? nil
        let nonratingEmojiTagsUpload = self.nonRatingEmojiTagsDict ?? nil
        
        let uploadTime = Date().timeIntervalSince1970
        let price = self.selectPostPrice ?? nil
        
        // Rating Emojis
        let ratingEmoji = self.ratingEmojiTag == "" ? nil : self.ratingEmojiTag
        
        // AutoTag Emojis
        var autoTagEmojis: [String] = []
        var autoTagEmojisDict: [String] = []
        
        for emoji in self.allAutoTagEmojis {
            autoTagEmojis.append(emoji.emoji)
            autoTagEmojisDict.append(emoji.name!)
        }
        
        // Previous List for Editing
        var listId = nil as [String:String]?
        if self.editPostInd {
            listId = editPost?.creatorListId
        }
        
        let values = ["caption": caption,"rating": rating, "ratingEmoji": ratingEmoji, "nonratingEmoji": nonratingEmojiUpload, "nonratingEmojiTags": nonratingEmojiTagsUpload, "autoTagEmojis": autoTagEmojis, "autoTagEmojisDict": autoTagEmojisDict, "imageWidth": postImages.first?.size.width, "imageHeight": postImages.first?.size.height, "creationDate": uploadTime, "googlePlaceID": googlePlaceID, "locationName": postLocationName, "locationAdress": postLocationAdress, "postLocationGPS": uploadedLocationGPS, "locationSummaryID": postLocationSummaryID, "imageLocationGPS": uploadedImageLocationGPS, "creatorUID": uid, "price": price, "lists": listId] as [String:Any]
        
        print("Uploaded Post Dictionary: \(values)")
        
        // Upload Post to List Controller
        
        var uploadPost = Post.init(user: CurrentUser.user!, dictionary: values)
        print("Reverse Post Dictionary: \(uploadPost.dictionary())")
        uploadPost.images = postImages
        uploadPost.imageCount = postImages.count
        
        
        if self.editPostInd {
            // Use Current Image URL and post id
            uploadPost.imageUrls = (editPost?.imageUrls)!
            uploadPost.imageCount = ((editPost?.imageUrls)?.count)!
            uploadPost.id = editPost?.id
        } else {
            uploadPost.id = NSUUID().uuidString
        }
        
        let sharePhotoListController = SharePhotoListController()
        sharePhotoListController.uploadPost = uploadPost
        sharePhotoListController.isEditingPost = self.editPostInd
        sharePhotoListController.preEditPost = self.editPost
        
        //        sharePhotoListController.uploadPostDictionary = values
        sharePhotoListController.uploadPostLocation = self.selectPostLocation
        
        
        navigationController?.pushViewController(sharePhotoListController, animated: true)
    }
    
  
    
    fileprivate func uploadnewPostCache(uid: String?, postid: String?, dictionary: [String:Any]?){
        guard let uid = uid else {return}
        guard let dictionary = dictionary else {return}
        
        if uid == CurrentUser.uid{
            newPost = Post.init(user: CurrentUser.user!, dictionary: dictionary)
            newPost?.id = postid
//            print("New Post Temp Uploaded: ",newPost)
            
            //Update Cache
            postCache.removeValue(forKey: postid!)
            postCache[postid!] = newPost
            
        } else {
            print("Error creating temp new post")
        }
    }
    

//    // LOCATION MANAGER DELEGATE METHODS

    @objc func determineCurrentLocation(){

        LocationSingleton.sharedInstance.determineCurrentLocation()
        refreshGoogleResults()
        
        let when = DispatchTime.now() + defaultGeoWaitTime // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            //Delay for 1 second to find current location
            if CurrentUser.currentLocation == nil {
                print("Determine Current Location: FAIL, No Current User Location")
            } else {
//                self.updateLocation(location: CurrentUser.currentLocation)
//                self.selectPostLocation = CurrentUser.currentLocation
//                self.googleReverseGPS(GPSLocation: self.selectPostLocation)
                self.appleCurrentLocation(GPSLocation: CurrentUser.currentLocation!)
                self.googleLocationSearch(GPSLocation: self.selectPostLocation)
            }
        }
    }
    
    
    // APPLE PLACES QUERY
    
    func appleCurrentLocation(GPSLocation: CLLocation) {
        // Reverse GPS to get place adress
        
        // var location:CLLocation = CLLocation(latitude: postlatitude, longitude: postlongitude)
        
        CLGeocoder().reverseGeocodeLocation(GPSLocation, completionHandler: {(placemarks, error)->Void in
            
            if (error != nil) {
                print("Reverse geocoder failed with error" + error!.localizedDescription)
                return
            }
            
            if placemarks!.count > 0 {
                let pm = placemarks![0]
                
                let tempLocation = Location.init(locationPlaceMark: pm)
                self.updateLocation(location: tempLocation)
//                print("Test Loc Adress: ",testLocation.locationAdress)
//                print("Test Loc Summary ID: ",testLocation.locationSummaryID)

//                print("Apple Test |", testLocation.locationAdress)
//                print("Apple Test |", testLocation.locationSummaryID)
                
//                print("APPLE PLACEMARKS, ")
//                print(pm.name)
//                print(pm.isoCountryCode)
//                print(pm.country)
//                print(pm.postalCode)
//                print(pm.administrativeArea)
//                print(pm.subAdministrativeArea)
//                print(pm.locality)
//                print(pm.thoroughfare)
//                print(pm.subThoroughfare)
//                print(pm.region)
//                print(pm.timeZone)


//                self.displayLocationInfo(pm)
            } else {
                print("Problem with the data received from geocoder")
            }
        })
    
    
        let center = CLLocationCoordinate2D(latitude: GPSLocation.coordinate.latitude, longitude: GPSLocation.coordinate.longitude)

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "Restaurants"
        request.region = MKCoordinateRegion.init(center: center, latitudinalMeters: 5000, longitudinalMeters: 5000)
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else {
                print("There was an error searching for: \(request.naturalLanguageQuery) error: \(error)")
                return
            }
            
            for item in response.mapItems {
//                print(item)
//                print(item.placemark.title)
//                print(item.placemark.subtitle)

                // Display the received items
            }
        }
    
    
    
    
    }
    
    func displayLocationInfo(_ placemark: CLPlacemark?) {
        if let containsPlacemark = placemark {
            //stop updating location to save battery life
            //locationManager.stopUpdatingLocation()
            
            
            let subThoroughfare = (containsPlacemark.subThoroughfare != nil) ? containsPlacemark.subThoroughfare : ""
            let thoroughfare = (containsPlacemark.thoroughfare != nil) ? containsPlacemark.thoroughfare : ""
            let locality = (containsPlacemark.locality != nil) ? containsPlacemark.locality : ""
            let state = (containsPlacemark.administrativeArea != nil) ? containsPlacemark.administrativeArea : ""
            let postalCode = (containsPlacemark.postalCode != nil) ? containsPlacemark.postalCode : ""
            
            self.selectPostLocationAdress = subThoroughfare! + " " + thoroughfare! + ", " + locality! + ", " + state! + " " + postalCode!
            
        }
        
    }
    
    // ADD LOCATION
    @objc func openAddLocationNameInput(){
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Add Location", message: "Enter New Location Name", preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.placeholder = "Enter Restaurant Name"
            textField.becomeFirstResponder()
        }
        
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            self.addLocationName(name: textField?.text)
            print("Adding Location Name \(textField?.text)")
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak alert] (_) in
            print("Cancel New Location Name Alert")
        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    func addLocationName(name: String?) {
        
        guard let name = name else {
            self.alert(title: "Error", message: "Error No New Location Name for \(self.selectPostLocationAdress)")
            return
        }
        
        if name.count == 0 {
            self.alert(title: "Error", message: "Error. No New Location Name for \(self.selectPostLocationAdress)")
            return
        }
        
        if self.selectPostLocationAdress == nil {
            self.alert(title: "Error", message: "Error. No Adress for \(name). Please search for your adress by clicking on the 🏠 icon.")
            return
        }


        self.selectPostLocationName = name
        
        if self.selectPostGooglePlaceID != nil {
            if self.selectPostGooglePlaceID?.suffix(4) != "_mod" {
                self.selectPostGooglePlaceID = self.selectPostGooglePlaceID! + "_mod"
            }
        }
        
    }
    
    // GOOGLE PLACES QUERY
    
    func googleReverseGPS(GPSLocation: CLLocation?){
        
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
//                                     print("Google Map Results ",results)
                    self.selectPostGooglePlaceID = results[0]["place_id"].string
//                    let tempLocality = results[0]["formatted_address"].string
                    
                    self.selectPostLocationName = results[0]["formatted_address"].string
                    self.selectPostLocationAdress = results[0]["formatted_address"].string
                    
                    let test_loc = Location.init(googleLocationJSON: results[0])
                    print("Google Test |", test_loc.locationAdress)
                    print("Google Test |", test_loc.locationSummaryID)

                }
            }
        }
    }
    
    
    func googleLocationSearch(GPSLocation: CLLocation?){
        
        guard let GPSLocation = GPSLocation else {
            print("Google Place Query: ERROR, No GPS Location")
            return
        }
        
        if (GPSLocation.coordinate.latitude == 0) && (GPSLocation.coordinate.longitude == 0){
            print("Google Place Query: ERROR, No GPS Location")
            return
        }
        
//        let dataProvider = GoogleDataProvider()
        let searchRadius: Double = 100
        var searchedTypes = ["restaurant","bakery","cafe",]
        var searchTerm = "restaurant|bakery|cafe|bar|night_club|meal_takeaway|meal_delivery"
//        var searchTerm = "restaurant|bakery|cafe"

//        searchNearbyRestaurants(GPSLocation, searchRadius: searchRadius, searchType: searchTerm)
        
        Database.searchNearbyGoogle(GPSLocation: GPSLocation, searchType: searchTerm) { (nearbyLocations) in
            if let nearbyLocations = nearbyLocations {
                self.nearbyGoogleLocations = nearbyLocations
            } else {
                self.nearbyGoogleLocations = []
            }
        }
    }
    

    var googleReviewString: String = ""
    
    func downloadRestaurantDetails(googlePlaceID: String?){
        
        guard let googlePlaceID = googlePlaceID else {
            print("Google Search Restaurant Details Error: No Google Place ID")
            return
        }
        
        let API_iOSKey = GoogleAPIKey()
        let urlString = "https://maps.googleapis.com/maps/api/place/details/json?placeid=\(googlePlaceID)&key=\(API_iOSKey)"
        print(urlString)
        
        let url = URL(string: urlString)!        
        AF.request(url).responseJSON { (response) -> Void in
//            print(response)
        
            if let value  = response.value {
                let json = JSON(value)
                let result = json["result"]
                self.extractReviews(fetchedResults: result, completion: { (reviews_string) in
                    self.googleReviewString = reviews_string.joined(separator: " ")
                    self.parseReview(inputString: reviews_string)
                })
            }
        }
    }
    
    func extractReviews(fetchedResults: JSON, completion:([String]) -> ()){
        var googleReviewString: String = ""
        
        let result = fetchedResults
        // Read in all the reviews
        let reviews = result["reviews"]
        
        for (key, value) in reviews {
            googleReviewString += value["text"].string!
        }
        completion(googleReviewString.lowercased().words())
    }
    
    
    
    func parseReview(inputString: [String]?){
        guard let inputString = inputString else {
            print("Review Parse Error: No String")
            return}
        
        self.reviewSuggestedEmojis = []
        
    // Auto-Tag Cuisine based on review
        var cuisineCounts: [String: Int] = [:]
        
        // Loops Through all cuisines in review
        for emoji in cuisineEmojis {
            let count = inputString.filter{$0 == emoji.name!}.count
            if count > 0 {
                cuisineCounts[emoji.name!] = count
            }
        }
        
        cuisineCounts.sorted(by: { $0.value > $1.value })
        
        var tempCuisineTagEmojis: [EmojiBasic] = []
        for (key,value) in cuisineCounts {
            if let emoji = EmojiDictionary.key(forValue: key) {
                let guessCuisineEmoji = EmojiBasic(emoji: emoji, name: key, count: 0)
                
                // Tag Up to Top 2 Cuisines
                if tempCuisineTagEmojis.count < 2 {
                    tempCuisineTagEmojis.append(guessCuisineEmoji)
                    self.reviewSuggestedEmojis.append(emoji)
                }
            }
        }
        
        print("extractReviews | Auto-Tag Cuisine | \(tempCuisineTagEmojis)")
        if tempCuisineTagEmojis.count > 0 {
            self.cuisineTagEmojis = tempCuisineTagEmojis
        }

        // Greatest Cuisine Tag
        
//        let greatestCuisine = cuisineCounts.max { a, b in a.value < b.value }
//        if let guessCuisine = greatestCuisine?.key {
//            if let emoji = EmojiDictionary.key(forValue: guessCuisine) {
//                let guessCuisineEmoji = Emoji(emoji: emoji, name: guessCuisine, count: 0)
//                self.cuisineTagEmojis = [guessCuisineEmoji]
//                print("Max Cuisine \(greatestCuisine) | Cuisine Auto Tag \(guessCuisineEmoji)")
//            }
//        }
        

        
    // Suggest Emojis based on reviews
        var suggestedEmojiCounts: [String: Int] = [:]

        // 1. Loops Through Emoji Caption Lookup to find suggested emojis
        for (key, value) in ReverseEmojiDictionary {
            let count = inputString.filter{$0 == key}.count
            if count > 0 {
                if let _ = suggestedEmojiCounts[value] {
                    // In order to handle many to one emoji translation relationship, we add emojis if they already exist
                    suggestedEmojiCounts[value]! += count
                } else {
                    suggestedEmojiCounts[value] = count
                }
            }
        }
        
        // 2. Sorts Through Suggested Emojis
        suggestedEmojiCounts.sorted(by: { $0.value > $1.value })
        
        // 3. Filter Emojis for only default food emojis - To avoid random emojis that don't make sense
        for (key,value) in suggestedEmojiCounts {
            if allDefaultEmojis.contains(key) {
                self.reviewSuggestedEmojis.append(key)
            }
        }
        
        print("Review Suggested Emojis: \(self.reviewSuggestedEmojis)")
        self.lookupLocationMostUsedEmojis()
    }
    
    var captionEmojis:[String] = [] {
        didSet{
            self.refreshEmojiTagSelections()
        }
    }
    var locationMostUsedEmojis:[String] = [] {
        didSet{
            if locationMostUsedEmojis.count > 0 {
                self.locationMostUsedEmojiButton.isHidden = false
                self.showlocationMostUsedEmojiInd = true
            } else {
                self.locationMostUsedEmojiButton.isHidden = true
                self.showlocationMostUsedEmojiInd = false
            }
            self.refreshEmojiTagSelections()
        }
    }
    var reviewSuggestedEmojis: [String] = [] {
        didSet{
//            if reviewSuggestedEmojis.count > 0 {
//                self.emojiTagSelectionOptionInd = 2
//            }
//            self.refreshEmojiTagSelections()
        }
    }

    func lookupLocationMostUsedEmojis(){
        
        self.locationMostUsedEmojis = []
        
        if self.selectPostGooglePlaceID == "" || self.selectPostGooglePlaceID == nil {
            return
        } else if let googleLocationID = self.selectPostGooglePlaceID {
            
            // Contain Google Place ID, search for most frequent emoji tags based on location ID
            Database.extractPostLocationEmojis(googleLocationID: googleLocationID) { (emojiOutput) in
                if let emojiOutput = emojiOutput {
                    self.locationMostUsedEmojis += emojiOutput
                }
                
                if self.reviewSuggestedEmojis.count > 0 {
                    self.locationMostUsedEmojis = self.appendEmojis(currentEmojis: self.locationMostUsedEmojis, newEmojis: self.reviewSuggestedEmojis)
                }
                
                print("Final Google Place Suggested Emojis: \(self.locationMostUsedEmojis)")
                
                // Activate Location
//                self.emojiTagSelectionOptionInd = 2
//                self.refreshEmojiTagSelections()
                
            }
        }
        
//        else {
//
//            // Remove Location Suggested Segment
//
//            if self.tagSelectionSegment.titleForSegment(at: 0) == LocationSuggestUploadTagSelection{
//                self.tagSelectionSegment.removeSegment(at: 0)
//                if self.tagSelectionSegment.selectedSegmentIndex > 0 {
//                    self.tagSelectionSegment.selectedSegmentIndex += -1
//                } else {
//                    self.tagSelectionSegment.selectedSegmentIndex = 0
//                }
//            }
//            self.suggestedEmojiCollectionView.reloadData()
//        }
        
    }
    
}
    
    

//fileprivate func saveEditedPost(postId: String, imageUrls: [String]){
//    // Edit Post
//
//    guard let postImages = selectedImages else {return}
//    var caption = captionTextView.text
//    if caption == captionDefault {caption = nil}
//    let googlePlaceID = selectPostGooglePlaceID ?? nil
//
//    // Upload Name Adress that matches inputs
//    guard let postLocationName = self.selectPostLocationName else {return}
//    if postLocationName == self.blankGPSName {return}
//    guard let postLocationAdress = self.selectPostLocationAdress else {return}
//    guard let uid = Auth.auth().currentUser?.uid else {return}
//
//
//    let nonratingEmojiUpload = self.nonRatingEmojiTags ?? nil
//    let nonratingEmojiTagsUpload = self.nonRatingEmojiTagsDict ?? nil
//
//    // AutoTag Emojis
//    // AutoTag Emojis
//    var autoTagEmojis: [String] = []
//    var autoTagEmojisDict: [String] = []
//
//    for emoji in self.allAutoTagEmojis {
//        autoTagEmojis.append(emoji.emoji)
//        autoTagEmojisDict.append(emoji.name!)
//    }
//
//    var uploadedLocationGPSLatitude: String?
//    var uploadedlocationGPSLongitude: String?
//    var uploadedLocationGPS: String?
//
//    if selectPostLocation == nil {
//        uploadedLocationGPS = nil
//    } else {
//        uploadedLocationGPSLatitude = String(format: "%f", (selectPostLocation?.coordinate.latitude)!)
//        uploadedlocationGPSLongitude = String(format: "%f", (selectPostLocation?.coordinate.longitude)!)
//        uploadedLocationGPS = uploadedLocationGPSLatitude! + "," + uploadedlocationGPSLongitude!
//    }
//
//    let userPostRef = Database.database().reference().child("posts").child(postId)
//    let uploadTime = Date().timeIntervalSince1970
//    let tagTime = self.selectTime.timeIntervalSince1970
//
//    let values = ["imageUrls": imageUrls, "caption": caption,"isLegit": self.isLegit, "imageWidth": postImages.first?.size.width, "imageHeight": postImages.first?.size.height, "creationDate": uploadTime, "googlePlaceID": googlePlaceID, "locationName": postLocationName, "locationAdress": postLocationAdress, "postLocationGPS": uploadedLocationGPS, "creatorUID": uid, "tagTime": tagTime, "nonratingEmoji": nonratingEmojiUpload, "nonratingEmojiTags": nonratingEmojiTagsUpload, "autoTagEmojis": autoTagEmojis, "autoTagEmojisDict": autoTagEmojisDict, "editDate": uploadTime, "lists": self.postList] as [String:Any]
//
//    userPostRef.updateChildValues(values) { (err, ref) in
//        if let err = err {
//            self.navigationItem.rightBarButtonItem?.isEnabled = true
//            print("Failed to save edited post to DB", err)
//            return
//        }
//
//        print("Successfully save edited post to DB")
//
//        // Put new post into Cache
//        // Now Done in Firebase Code during upload
//        //            self.uploadnewPostCache(uid: uid,postid: postId, dictionary: values)
//
//
//        // SAVE USER AND POSTID
//
//        let userPostRef = Database.database().reference().child("userposts").child(uid).child(postId)
//        let values = ["creationDate": uploadTime, "tagTime": tagTime, "emoji": nonratingEmojiUpload] as [String:Any]
//
//        userPostRef.updateChildValues(values) { (err, ref) in
//            if let err = err {
//                print("Failed to save edited post to user", err)
//                return
//            }
//            print("Successfully save edited post to user")
//        }
//
//
//        // SAVE GEOFIRE LOCATION DATA
//
//        let geofireRef = Database.database().reference().child("postlocations")
//        //            guard let geoFire = GeoFire(firebaseRef: geofireRef) else {return}
//        //            let geofirekeytest = uid+","+postref
//
//        let geoFire = GeoFire(firebaseRef: geofireRef)
//
//        geoFire.setLocation(self.selectPostLocation!, forKey: postId) { (error) in
//            if (error != nil) {
//                print("An error occured: \(error)")
//            } else {
//                print("Saved location successfully!")
//            }
//        }
//        self.dismiss(animated: true, completion: nil)
//        NotificationCenter.default.post(name: SharePhotoController.updateFeedNotificationName, object: nil)
//    }
//}


//    override var prefersStatusBarHidden: Bool {
//        return true
//    }


//var googlePlaceNames = [String]()
//var googlePlaceIDs = [String]()
//var googlePlaceAdresses = [String]()
//var googlePlaceLocations = [CLLocation]()
//var googlePlaceTypes = [[String]]()

//    func searchNearbyRestaurants(_ lat: CLLocation, searchRadius:Double, searchType: String ) {
//        let URL_Search = "https://maps.googleapis.com/maps/api/place/search/json?"
//        let API_iOSKey = GoogleAPIKey()
//
//
//        var urlParameters = URLComponents(string: "https://maps.googleapis.com/maps/api/place/search/json?")!
//
//        urlParameters.queryItems = [
//            URLQueryItem(name: "location", value: "\(lat.coordinate.latitude),\(lat.coordinate.longitude)"),
//            URLQueryItem(name: "rankby", value: "distance"),
//            URLQueryItem(name: "type", value: "\(searchType)"),
//            URLQueryItem(name: "key", value: "\(API_iOSKey)"),
//        ]
//
//        //print("URL: \(urlParameters.url!)")
//
//        //   https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=-33.8670,151.1957&radius=500&types=food&name=cruise&key=YOUR_API_KEY
//
//        // https://maps.googleapis.com/maps/api/place/search/json?location=34.0636555,-118.297521666667&rankby=distance&type=restaurant&key=AIzaSyAzwACZh50Qq1V5YYKpmfN21mZs8dW6210
//
////        let urlString = "\(URL_Search)location=\(lat.coordinate.latitude),\(lat.coordinate.longitude)&rankby=distance&type=\(searchType)&key=\(API_iOSKey)"
////
////        var url = URL(string: urlString)!
//
//        self.googlePlaceNames.removeAll()
//        self.googlePlaceIDs.removeAll()
//        self.googlePlaceAdresses.removeAll()
//        self.googlePlaceLocations.removeAll()
//        self.googlePlaceTypes.removeAll()
//
//        Alamofire.request(urlParameters.url!).responseJSON { (response) -> Void in
//
////                        print(response)
//
//            if let value  = response.result.value {
//                let json = JSON(value)
//
//                if let results = json["results"].array {
////                    print(results)
//
//                    let thisGroup = DispatchGroup()
//                        for result in results {
//                            if result["place_id"].string != nil {
//                                guard let placeID = result["place_id"].string else {return}
//                                guard let name = result["name"].string else {return}
//                                guard let locationAdress = result["vicinity"].string else {return}
//                                guard let postLatitude = result["geometry"]["location"]["lat"].double else {return}
//                                guard let postLongitude = result["geometry"]["location"]["lng"].double else {return}
//                                guard let placeType = result["types"].arrayObject as? [String] else {return}
//
//                                let locationGPStempcreate = CLLocation(latitude: postLatitude, longitude: postLongitude)
//
//                                // Filter for results with more detail
//                                let check = result["opening_hours"]
//                                if check != nil {
//                                    self.googlePlaceNames.append(name)
//                                    self.googlePlaceIDs.append(placeID)
//                                    self.googlePlaceAdresses.append(locationAdress)
//                                    self.googlePlaceLocations.append(locationGPStempcreate)
//                                    self.googlePlaceTypes.append(placeType)
//                                    self.placesCollectionView.reloadData()
//                                }
//                            }
//                        }
//                }
//            }
//        }
//    }
//
//}





//            if let adressDictionaryValue = adressDictionary["FormattedAddressLines"] as! NSArray as? [String] {
//
//                var adress = adressDictionaryValue as NSArray as! [String]



//                Optional([AnyHashable("Street"): 3465 W 6th St,
//                   AnyHashable("Country"): United States,
//                   AnyHashable("State"): CA, AnyHashable("PostCodeExtension"): 2567, AnyHashable("ZIP"): 90020, AnyHashable("SubThoroughfare"): 3465, AnyHashable("Name"): 3465 W 6th St, AnyHashable("Thoroughfare"): W 6th St, AnyHashable("SubAdministrativeArea"): Los Angeles, AnyHashable("FormattedAddressLines"): <__NSArrayM 0x60800024ced0>(
//                    3465 W 6th St,
//                    Los Angeles, CA  90020,
//                    United States
//                )

//            SelectedLocationName = containsPlacemark.name
//            SelectedLocationAdress = nil
//
//            updateGPS()
//
// self.PlaceName.text = containsPlacemark.name

//            Optional([AnyHashable("Street"): 90 Bell Rock Plz, AnyHashable("ZIP"): 86351, AnyHashable("Country"): United States, AnyHashable("SubThoroughfare"): 90, AnyHashable("State"): AZ, AnyHashable("Name"): Coconino National Forest, AnyHashable("SubAdministrativeArea"): Yavapai, AnyHashable("Thoroughfare"): Bell Rock Plz, AnyHashable("FormattedAddressLines"): <__NSArrayM 0x608000241440>(
//                Coconino National Forest,
//                90 Bell Rock Plz,
//                Sedona, AZ  86351,
//                United States
//                )
//                , AnyHashable("City"): Sedona, AnyHashable("CountryCode"): US, AnyHashable("PostCodeExtension"): 9040])


/*
 print(locality)
 print(GPS)
 print(containsPlacemark.areasOfInterest)
 print(containsPlacemark.name)
 print(containsPlacemark.thoroughfare)
 print(containsPlacemark.subThoroughfare)
 
 
 public var name: String? { get } // eg. Apple Inc.
 public var thoroughfare: String? { get } // street name, eg. Infinite Loop
 public var subThoroughfare: String? { get } // eg. 1
 public var locality: String? { get } // city, eg. Cupertino
 public var subLocality: String? { get } // neighborhood, common name, eg. Mission District
 public var administrativeArea: String? { get } // state, eg. CA
 public var subAdministrativeArea: String? { get } // county, eg. Santa Clara
 public var postalCode: String? { get } // zip code, eg. 95014
 public var ISOcountryCode: String? { get } // eg. US
 public var country: String? { get } // eg. United States
 public var inlandWater: String? { get } // eg. Lake Tahoe
 public var ocean: String? { get } // eg. Pacific Ocean
 public var areasOfInterest: [String]? { get } // eg. Golden Gate Park
 */




// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
