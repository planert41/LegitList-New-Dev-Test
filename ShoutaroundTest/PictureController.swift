//
//  PictureController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/19/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import mailgun
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth
import Cosmos
import GeoFire
import CoreGraphics
import CoreLocation
import DropDown
import MessageUI

protocol PictureControllerDelegate {
    func listSelected(list: List?)
    func refreshPost(post: Post?)
}

class PictureController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, FullPostCellDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate, EmojiButtonArrayDelegate, SharePhotoListControllerDelegate, MFMessageComposeViewControllerDelegate{


    var delegate: PictureControllerDelegate?
    var cellId = "cellId"
    
    var popView = UIView()
    var enableDelete: Bool = false
    var isZooming = false
    var currentImage = 1 {
        didSet {
            setupImageCountLabel()
        }
    }
    var imageCount = 0
    
    // Settings
    var postCaptionTextSize = 15
    
    var post: Post? {
        didSet {
            
            guard let imageUrls = post?.imageUrls else {
                print("Read Post, No Image URLs Error")
                return}
            
            setupImageCountLabel()
            setupPicturesScroll()
            if post?.images != nil {
                photoImageView.image = post?.images![0]
            } else {
                photoImageView.loadImage(urlString: imageUrls.first!)
            }
            
            setupUser()
            setupPageControl()
            fillInCaptionBubble()
            setupActionButtons()
            setupListViews()
            setupEmojis()
            refreshListCollectionView()
            setupRatingLegitIcon()
            setupAttributedLocationName()
            setupPostDetails()
            setupAttributedSocialCount()
            self.scrollview.contentSize = scrollview.intrinsicContentSize
            


            print("Picture Controller | Showing \(post?.id)")
            print("ScrollView Size | Content \(self.scrollview.contentSize) | Intrinsic \(scrollview.intrinsicContentSize)")

        }
    }
    

    func setupUser(){
        usernameLabel.text = post?.user.username
        usernameLabel.sizeToFit()
        usernameLabel.adjustsFontSizeToFitWidth = true
        
        usernameLabel.isUserInteractionEnabled = true
        let usernameTapGesture = UITapGestureRecognizer(target: self, action: #selector(usernameTap))
        usernameLabel.addGestureRecognizer(usernameTapGesture)
        
        guard let profileImageUrl = post?.user.profileImageUrl else {return}
        userProfileImageView.loadImage(urlString: profileImageUrl)
    }
    
    func refreshListCollectionView(){
        
        
        // CURRENT USER SELECTED - ONLY IF CREATOR IS NOT CURRENT USER
        
        self.postCurrentUserListIds = []
        self.postCurrentUserListNames = []
        self.currentUserListLabel.text = ""

    // POST CREATOR LIST IDS
        
        self.postCreatorListIds = []
        self.postCreatorListNames = []
        
    // OTHER USER IS POST CREATOR AND TAGGED POST TO A LIST. IF POST CREATOR IS CURRENT USER, IT GOES TO SELECTEDLISTID
        if self.post?.creatorListId != nil && self.post?.creatorUID != Auth.auth().currentUser?.uid  {
//            self.creatorUserListLabel.text = (self.post?.user.username)! + " Lists"
            
            for (key,value) in (self.post?.creatorListId)! {
                if value == legitListName{
                    self.postCreatorListIds.append(key)
                    self.postCreatorListNames.append(value)
                }
            }
            
            for (key,value) in (self.post?.creatorListId)! {
                if value == bookmarkListName{
                    self.postCreatorListIds.append(key)
                    self.postCreatorListNames.append(value)
                }
            }
            
            for (key,value) in (self.post?.creatorListId)! {
                if value != legitListName && value != bookmarkListName{
                    self.postCreatorListIds.append(key)
                    self.postCreatorListNames.append(value)
                }
            }
        }
        
    // CURRENT USER TAGGED LISTS
        if self.post?.selectedListId != nil {

            for (key,value) in (self.post?.selectedListId)! {
                if value == legitListName{
                    self.postCurrentUserListIds.append(key)
                    self.postCurrentUserListNames.append(value)
                }
            }
            
            for (key,value) in (self.post?.selectedListId)! {
                if value == bookmarkListName{
                    self.postCurrentUserListIds.append(key)
                    self.postCurrentUserListNames.append(value)
                }
            }
            
            for (key,value) in (self.post?.selectedListId)! {
                if value != legitListName && value != bookmarkListName && value != nil{
                    self.postCurrentUserListIds.append(key)
                    self.postCurrentUserListNames.append(value)
                }
            }
        }
        
    // HIDE LIST COLLECTIONVIEW IF NO LISTS
        self.listView.isHidden = (self.postCreatorListNames.count == 0 && self.postCurrentUserListNames.count == 0)
        
    // UPDATE LIST COLLECTIONVIEW LABELS
        
        var postCreatorListCountString = self.postCreatorListIds.count == 0 ? "" : String(self.postCreatorListIds.count)
        
        self.creatorUserListLabel.text = "\(postCreatorListCountString) Post Creator Lists"
        self.creatorUserListLabel.sizeToFit()
        self.creatorUserListLabel.textColor = UIColor.legitColor()
        self.creatorUserListLabel.isHidden = self.post?.creatorUID == Auth.auth().currentUser?.uid
        
        self.currentUserListLabel.text = CurrentUser.username! + " Lists"
        self.currentUserListLabel.textColor = UIColor.darkLegitColor()
        self.currentUserListLabel.sizeToFit()
        
        if self.postCurrentUserListNames.count > 0 {
            self.listCount.text = String(self.postCurrentUserListNames.count) + (self.postCurrentUserListNames.count > 1 ? " Lists" : " List")
        } else {
            self.listCount.text = "Add List"
        }

        self.view.updateConstraintsIfNeeded()
        self.view.layoutIfNeeded()
        self.creatorListCollectionView.reloadData()
        self.userListCollectionView.reloadData()
        
    }
    
    func setupImageCountLabel(){
        imageCount = (self.post?.imageCount)!
        
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
        photoCountLabel.reloadInputViews()
    }
    
    @objc func usernameTap() {
        print("Tap username label", post?.user.username ?? "")
        guard let post = post else {return}
        self.didTapUser(post: post)
    }
    
    @objc func locationTap() {
        print("Post Information: ", post)
        
        print("Tap location label", post?.locationName ?? "")
        guard let post = post else {return}
        self.didTapLocation(post: post)
    }
    
    func doubleTapEmoji(index: Int?, emoji: String) {
        
    }
    
    
    func expandPost(post: Post, newHeight: CGFloat) {
        //        collectionHeights[post.id!] = newHeight
        //        print("Added New Height | ",collectionHeights)
    }
    

    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var contentRect = CGRect.zero
        for view: UIView in scrollview.subviews {
            contentRect = contentRect.union(view.frame)
        }
        contentRect.size.width = self.view.frame.width
        contentRect.size.height = contentRect.size.height
        scrollview.contentSize = contentRect.size
        
        //        print("ScrollView ",scrollview.contentSize)
        //        print("PhotoImageView ", photoImageScrollView.contentSize)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        //        let tempImage = UIImage.init(color: UIColor.legitColor())
        //        self.navigationController?.navigationBar.setBackgroundImage(tempImage, for: .default)
        //        self.navigationController?.navigationBar.tintColor = UIColor.white
        //        self.view.layoutIfNeeded()
        //        self.navigationController?.navigationBar.layoutIfNeeded()
    }
    
    
    lazy var testMapButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage((#imageLiteral(resourceName: "google_color").resizeImageWith(newSize: CGSize(width: 25, height: 25))).withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(locationTap), for: .touchUpInside)
        
        button.layer.cornerRadius = 10
        button.setTitleColor(UIColor.selectedColor(), for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        button.setTitle(" Map ", for: .normal)
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
        
        button.layer.borderColor = button.titleLabel?.textColor.cgColor
        button.layer.borderWidth = 1
        button.clipsToBounds = true
        button.layer.backgroundColor = UIColor.lightGray.withAlphaComponent(0.8).cgColor
        
        button.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        button.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        button.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        return button
    }()
    
    lazy var navBarButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        //        let button = UIButton()
        //        button.setImage((#imageLiteral(resourceName: "map_navbar").resizeImageWith(newSize: CGSize(width: 25, height: 25))).withRenderingMode(.alwaysOriginal), for: .normal)
        button.setImage((#imageLiteral(resourceName: "message_fill").resizeImageWith(newSize: CGSize(width: 25, height: 25))).withRenderingMode(.alwaysOriginal), for: .normal)
        
        button.addTarget(self, action: #selector(showDropDown), for: .touchUpInside)
        
        button.layer.cornerRadius = 10
        button.setTitleColor(UIColor.selectedColor(), for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        button.setTitle(" Share ", for: .normal)
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
        
        button.layer.borderColor = button.titleLabel?.textColor.cgColor
        button.layer.borderWidth = 1
        button.clipsToBounds = true
        //        button.layer.backgroundColor = UIColor.selectedColor().withAlphaComponent(0.8).cgColor
        button.layer.backgroundColor = UIColor.lightGray.withAlphaComponent(0.8).cgColor
        button.layer.backgroundColor = UIColor.clear.cgColor

        button.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        button.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        button.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        return button
    }()
    
    func toggleMapFunction(){
        if let location = self.post?.locationGPS {
            let tempFilter = Filter.init()
            tempFilter.filterLocation = self.post?.locationGPS
            tempFilter.filterPostId = self.post?.id
            appDelegateFilter = tempFilter
            self.toggleMapView()
        } else {
            self.alert(title: "Map Error", message: "Post Has No Location!")
        }

    }
    
    @objc func activateMap() {
        if let location = self.post?.locationGPS {
            SharedFunctions.openGoogleMaps(lat: location.coordinate.latitude, long: location.coordinate.longitude)
        } else {
            self.alert(title: "Map Error", message: "Post Has No Location!")
        }
    }

    
    var bookmarkLabelConstraint: NSLayoutConstraint? = nil
    var displayNames: [String] = []
    var displayNamesUid: [String:String] = [:]
    
    let socialViewHeight = 15 as CGFloat
    
    fileprivate func updateVoteTextView(){
        let attributedVoteText = NSMutableAttributedString()
        
        if self.displayNames.count > 0 {
            let attributedVoteText = NSMutableAttributedString(string: "from ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray]))
            
            attributedVoteText.append(NSAttributedString(string: self.displayNames.joined(separator: ", "), attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 15), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.legitColor()])))
            
            self.voteStatsTextView.attributedText = attributedVoteText
            //            print(attributedVoteText)
            self.voteStatsTextView.reloadInputViews()
        } else {
            self.voteStatsTextView.attributedText = NSMutableAttributedString()
        }
        
        //        print(self.voteStatsTextView.attributedText)
        self.voteStatsTextView.reloadInputViews()
        self.voteStatsTextView.sizeToFit()
        
    }
    
    func updateSocialLabel(listCount: Int?, userCount: Int?, usernames: [String]?) {
        let listCount = listCount ?? 0
        let userCount = userCount ?? 0
        let usernames = usernames ?? []
        var otherUserCount = userCount
        
        var userString = ""
        
        if listCount > 0 {
            self.listAddedHideHeight?.isActive = false
        } else {
            self.listAddedHideHeight?.isActive = true
            return
        }
        
        if listCount == 1 {
            userString = "\(listCount) List by"
        } else if listCount > 1 {
            userString = "\(listCount) Lists by"
        }
        
        if (usernames.count) > 0 {
            for (index, username) in usernames.enumerated() {
                if index == 0 {
                    userString.append(" \(username)")
                } else {
                    userString.append(", \(username)")
                }
            }
            
            otherUserCount = userCount - usernames.count
            if otherUserCount == 1 {
                userString.append(" & 1 User")
            } else if otherUserCount > 1 {
                userString.append(" & \(otherUserCount) Users")
            } else {
                // No other users
            }
        } else {
            // NO LISTS FROM FOLLOWING USERS
            if otherUserCount == 1 {
                userString.append(" 1 User")
            } else if otherUserCount > 1 {
                userString.append(" \(otherUserCount) Users")
            } else {
                // No other users
            }
        }
        
        self.listAddedStatsLabel.text = userString
        self.listAddedStatsLabel.sizeToFit()
        
        
    }
    
    
    fileprivate func setupAttributedSocialCount(){
        
        guard let post = self.post else {return}
        displayNames = []
        displayNamesUid = [:]

        // Bookmark Counts
        
        var totalUniqueListUsers = post.allList.countUniqueStringValues()
        
        // Following Users
        var followingUsers: [String: Int] = post.followingList.stringValueCounts()
        followingUsers.sorted(by: { $0.value > $1.value })
        
        // Remove Post Creator ID from following users stats
        if let creatorIndex = followingUsers.index(forKey: post.creatorUID!) {
            followingUsers.remove(at: creatorIndex)
        }
        
        
        if let mostListFollowingUser1 = followingUsers.first?.key {
            Database.fetchUserWithUID(uid: mostListFollowingUser1) { (user) in
                self.updateSocialLabel(listCount: post.listCount, userCount: totalUniqueListUsers, usernames: [(user?.username)!])
            }
        } else {
            self.updateSocialLabel(listCount: post.listCount, userCount: totalUniqueListUsers, usernames: nil)
        }
        
        // ACTION BUTTON COUNTS
        
        // Button Counts

        self.likeCount.text = post.likeCount != 0 ? String(post.likeCount) : ""
        self.likeCount.text?.append(" Likes")
        
        self.commentCount.text = post.commentCount != 0 ? String(post.commentCount) : ""
        self.commentCount.text?.append(" Comments")

        self.messageCount.text = post.messageCount > 0 ? String( post.messageCount) : ""
        self.messageCount.text?.append(" Messages")

        if self.postCurrentUserListIds.count > 0 {
            self.listCount.text = String(self.postCurrentUserListNames.count) + (self.postCurrentUserListNames.count > 1 ? " Lists" : " List")
        } else {
            self.listCount.text = "Add List"
        }
        
//        self.listCount.text?.append(" List")

        
        // Resizes bookmark label to fit new count
        bookmarkLabelConstraint?.constant = self.listCount.frame.size.width
        //        self.layoutIfNeeded()
        
        
        
        
        
        
        
        // Follower Vote Count
        //        let followingVoteText = NSMutableAttributedString()
        //
        //        if post.followingVote.count > 0 {
        //            let voteString = NSMutableAttributedString(string: String(post.followingVote.count) + " Cred", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
        //            followingVoteText.append(voteString)
        //        }
        //
        //        followVoteStatsLabel.attributedText = followingVoteText
        
        //        let followingListText = NSMutableAttributedString()
        //
        //        if post.followingList.count > 0 {
        //            if post.followingVote.count > 0 {
        //                let andString = NSMutableAttributedString(string: "& ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 14)]))
        //                followingListText.append(andString)
        //            }
        //
        //            let followString = NSMutableAttributedString(string: String(post.followingList.count) + " Lists", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
        //            followingListText.append(followString)
        //        }
        //
        //        followListStatsLabel.attributedText = followingListText
        
        // Additional Following User Display
        
        //        var followingUserIds: [String] = []
        //        if post.followingList.count > 0 {
        //            for (listId, userId) in post.followingList {
        //                if !followingUserIds.contains(userId){
        //                    followingUserIds.append(userId)
        //                }
        //            }
        //        }
        //
        //        if post.followingVote.count > 0 {
        //            for userId in post.followingVote{
        //                if !followingUserIds.contains(userId){
        //                    followingUserIds.append(userId)
        //                }
        //            }
        //        }
        //
        //        for userId in followingUserIds {
        //            if displayNames.count < 3 {
        //                Database.fetchUserWithUID(uid: userId) { (user) in
        //                    var displayName = (user?.username)!.replacingOccurrences(of: "@", with: "")
        //                    self.displayNames.append(displayName)
        //                    self.displayNamesUid[displayName] = (user?.uid)!
        //                    self.updateVoteTextView()
        //                }
        //            }
        //        }
        
        
    }
    
    fileprivate func setupPostDetails(){
        
        guard let post = self.post else {return}
        
        // Setup Post Date
        let formatter = DateFormatter()
        let calendar = NSCalendar.current
        
        let yearsAgo = calendar.dateComponents([.year], from: post.creationDate, to: Date())
        if (yearsAgo.year)! > 0 {
            formatter.dateFormat = "MMM d yy, h:mm a"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }
        
        let daysAgo =  calendar.dateComponents([.day], from: post.creationDate, to: Date())
        var postDateString: String?
        
        // If Post Date < 7 days ago, show < 7 days, else show date
        if (daysAgo.day)! <= 7 {
            postDateString = post.creationDate.timeAgoDisplay()
        } else {
            let dateDisplay = formatter.string(from: post.creationDate)
            postDateString = dateDisplay
        }
        
        let attributedText = NSAttributedString(string: postDateString!, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 12),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.lightGray]))
        
        self.postDateLabel.attributedText = attributedText
        self.postDateLabel.sizeToFit()
        
        locationDistanceLabel.text = SharedFunctions.formatDistance(inputDistance: post.distance)
        locationDistanceLabel.adjustsFontSizeToFitWidth = true
        locationDistanceLabel.sizeToFit()
        
        // Set Up Caption
        
        captionTextView.textContainer.maximumNumberOfLines = 0
        
        let attributedTextCaption = NSMutableAttributedString(string: post.user.username, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))


        attributedTextCaption.append(NSAttributedString(string: " \(post.caption)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 14)])))
        
        attributedTextCaption.append(NSAttributedString(string: "\n\n", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 4)])))
        
        self.captionTextView.attributedText = attributedTextCaption
        self.captionTextView.sizeToFit()
    }
    
    fileprivate func setupAttributedLocationName(){
        
        guard let post = self.post else {return}
        
        var displayLocationName: String = ""
        
        var shortDisplayLocationName: String = ""
        var locationCountry: String = ""
        var locationState: String = ""
        var locationCity: String = ""
        var locationAdress: String = ""
        
        self.locationCityLabel.text = ""

        if post.locationGPS == nil {
            displayLocationName = ""
        }
        else if post.locationGooglePlaceID! == "" && post.locationName == post.locationAdress {
            // Not Google Tagged Location, Display by City, State
            // User might tag location name without locationGooglePlaceID
            displayLocationName = self.displayLocationAdress(adressString: self.post?.locationAdress)
            
        } else {
            // Google Tagged Location. Display Google Location Name
            displayLocationName = post.locationName
            if let tempCity = self.post?.locationSummaryID{
                
                var displayCityString = ""
                // Display City Location with Restaurant Tag
                var tempCityArray = tempCity.components(separatedBy: ",")
                tempCityArray = tempCityArray.reversed()
                
                for text in tempCityArray {
                    if text != " US" && (displayCityString.count + text.count) < 25 {
                        if displayCityString == "" {
                            displayCityString = text
                        } else {
                            displayCityString = text + "," + displayCityString
                        }
                    }
                }
                
                self.locationCityLabel.text = displayCityString
                
//                if tempCity.suffix(4) == ", US" {
//                    let endIndex = tempCity.index(tempCity.endIndex, offsetBy: -4)
//                    let truncated = tempCity.substring(to: endIndex)
//                    self.locationCityLabel.text = truncated
//                } else {
//                    self.locationCityLabel.text = tempCity
//                }
            }
        }
        
        if self.locationCityLabel.text != "" {
            self.locationCityViewHeight?.constant = 14
        } else {
            self.locationCityViewHeight?.constant = 0
        }
        
        self.locationCityLabel.sizeToFit()
        
        if let ratingEmoji = self.post?.ratingEmoji {
            if extraRatingEmojis.contains(ratingEmoji) {
                displayLocationName.append(" \(ratingEmoji)")
            }
        }
        
        let attributedTextCaption = NSMutableAttributedString(string: displayLocationName, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.legitColor(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .avenirNextDemiBold, size: 18)]))
        
        
        let paragraphStyle = NSMutableParagraphStyle()
        
        // *** set LineSpacing property in points ***
        paragraphStyle.lineSpacing = 0 // Whatever line spacing you want in points
        
        // *** Apply attribute to string ***
        attributedTextCaption.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedTextCaption.length))
        
        // *** Set Attributed String to your label ***
        self.locationNameLabel.attributedText = attributedTextCaption
        
//        if let cityId = post.locationGooglePlaceID {
        
        
        
        self.locationNameLabel.sizeToFit()
    }
    
    func displayLocationAdress(adressString: String?) -> String {
        guard let adressString = adressString else {
            print("PictureController | DisplayLocationAdress Error | No Location Adress")
            return ""}
        
        var displayLocationName: String = ""
        
        var shortDisplayLocationName: String = ""
        var locationCountry: String = ""
        var locationState: String = ""
        var locationCity: String = ""
        var locationAdress: String = ""
        
        let locationNameTextArray = adressString.components(separatedBy: ",")
        let locationNameReverse = Array(locationNameTextArray.reversed())
        
        locationCountry = locationNameReverse[0]
        
        if locationNameReverse.count > 1 {
            locationState = locationNameReverse[1]
        }
        if locationNameReverse.count > 2 {
            locationCity = locationNameReverse[2]
        }
        
        if locationNameReverse.count > 3 {
            locationAdress = locationNameReverse[3]
        }
        
        if !(locationCity.isEmptyOrWhitespace()) && !(locationCountry.isEmptyOrWhitespace()){
            shortDisplayLocationName = locationCity + "," + locationCountry
        } else {
            shortDisplayLocationName = locationCity + locationCountry
        }
        
        // Last 3 items are City, State, Country
        return shortDisplayLocationName
    }
    
    //  PHOTOS
    
    let userProfileImageView: CustomImageView = {
        
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 2
        return iv
        
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(font: .appleSDGothicNeoBold, size: 15)
        label.textColor = UIColor.white
        label.textColor = UIColor.legitColor()

        label.textAlignment = NSTextAlignment.right
        return label
    }()
    
    let photoImageScrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.backgroundColor = .white
        return scroll
    }()
    
    let photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .white
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        
        return iv
        
    }()
    
    let photoCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textColor = UIColor.darkGray
        label.backgroundColor = UIColor.white
        label.layer.cornerRadius = 5
        label.layer.borderWidth = 0
        label.layer.masksToBounds = true
        label.alpha = 0.5
        return label
    }()
    
    let photoCountDisplay = UIStackView()
    let photoCountView = UIView()
    
    // STAR RATING
    
    var starRatingLabel = RatingLabel(ratingScore: 0, frame: CGRect.zero)
    var starRatingHide: NSLayoutConstraint?
    
    
    let starRating: CosmosView = {
        let iv = CosmosView()
        iv.settings.fillMode = .half
        iv.settings.totalStars = 5
        //        iv.settings.starSize = 30
        iv.settings.starSize = 25
        iv.settings.updateOnTouch = false
        iv.settings.filledImage = #imageLiteral(resourceName: "star_rating_filled_mid").withRenderingMode(.alwaysOriginal)
        iv.settings.emptyImage = #imageLiteral(resourceName: "star_rating_unfilled").withRenderingMode(.alwaysOriginal)
        iv.rating = 0
        iv.settings.starMargin = 1
        return iv
    }()

    func openLegitList(){
        print("Open Legit List")
        if let legitIndex = self.postCreatorListNames.firstIndex(of: legitListName){
            var selectedListName = self.postCreatorListNames[legitIndex]
            var selectedListId = self.postCreatorListIds[legitIndex]
            self.didTapExtraTag(tagName: selectedListName, tagId: selectedListId, post: post!)
        }
    }
    
    let extraRatingLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.alpha = 1
        return label
    }()
    
    //    BOOKMARK ICON

    
    @objc func openBookmark(){
        print("Open Bookmark List")
        if let bookmarkId = self.post?.selectedListId?.key(forValue: bookmarkListName){
            self.didTapExtraTag(tagName: bookmarkListName, tagId: bookmarkId, post: post!)
        } else if let bookmarkListIndex = CurrentUser.lists.firstIndex(where: { (list) -> Bool in
            list.name == bookmarkListName
        }) {
            self.didTapExtraTag(tagName: bookmarkListName, tagId: CurrentUser.lists[bookmarkListIndex].id!, post: post!)
        } else {
            print("Can't Find User Bookmark List: ", CurrentUser.uid)
        }
    }
    
    
    //  LOCATION
    
    let locationView: UIView = {
        let uv = UIView()
        let locationTapGesture = UITapGestureRecognizer(target: self, action: #selector(locationTap))
        uv.addGestureRecognizer(locationTapGesture)
        uv.isUserInteractionEnabled = true
        uv.backgroundColor = UIColor.clear
        return uv
    }()
    
    let locationDistanceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.mainBlue()
        label.textAlignment = NSTextAlignment.right
        return label
    }()
    
    let locationNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.left
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()
    
    let locationCityLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.italicSystemFont(ofSize: 12)
        label.textColor = UIColor.lightGray
        label.textAlignment = NSTextAlignment.right
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    var locationCityViewHeight: NSLayoutConstraint? = nil

    
    // Price
    
    let priceLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.init(hexColor: "4caf50")
        label.textColor = UIColor.init(hexColor: "ffc107")
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textAlignment = NSTextAlignment.center
        label.lineBreakMode = .byCharWrapping
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        
        return label
    }()
    
    
    
    
    //  EMOJIS
    
    var emojiArray = EmojiButtonArray(emojis: [], frame: CGRect(x: 0, y: 0, width: 0, height: 25))
    
    
    let emojiDetailLabel: PaddedUILabel = {
        let label = PaddedUILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 25)
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.rgb(red: 255, green: 242, blue: 230)
        label.layer.cornerRadius = 30/2
        label.layer.borderWidth = 0.25
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.masksToBounds = true
        return label
    }()
    
    
    
    // Emoji description


    func didTapEmoji(index: Int?, emoji: String) {
        guard let index = index else {
            print("No Index For emoji \(emoji)")
            return
        }
        guard let displayEmoji = self.post?.nonRatingEmoji[index] else {return}
        guard let  displayEmojiTag = self.post?.nonRatingEmojiTags[index] else {return}
        //        self.delegate?.displaySelectedEmoji(emoji: displayEmoji, emojitag: displayEmojiTag)
        
        print("Selected Emoji \(index) | \(displayEmoji) | \(displayEmojiTag)")
        
        var captionDelay = 3
        emojiDetailLabel.text = "\(displayEmoji)  \(displayEmojiTag)"
        emojiDetailLabel.alpha = 1
        emojiDetailLabel.sizeToFit()
        
        UIView.animate(withDuration: 0.5, delay: TimeInterval(captionDelay), options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.hideEmojiDetailLabel()
        }, completion: { (finished: Bool) in
        })
    }
    
    func hideEmojiDetailLabel(){
        self.emojiDetailLabel.alpha = 0
    }
    
    func setupEmojis(){
        
        if let price = self.post?.price {
            priceLabel.text = "\(price) "
            priceLabel.sizeToFit()
        } else {
            priceLabel.text = ""
            priceLabel.sizeToFit()
        }
        
        
        //        print("REFRESH EMOJI ARRAYS")
        if let displayEmojis = self.post?.nonRatingEmoji{
            emojiArray.emojiLabels = displayEmojis
        } else {
            emojiArray.emojiLabels = []
        }
        //        print("UPDATED EMOJI ARRAY: \(emojiArray.emojiLabels)")
        emojiArray.setEmojiButtons()
        emojiArray.sizeToFit()
        //        print("REFRESH EMOJI ARRAYS - setEmojiButtons")
        
        self.extraRatingLabel.text = self.post?.ratingEmoji ?? ""
        self.extraRatingLabel.sizeToFit()
        
    }
    
    // CAPTION
    
    let captionTextView: UITextView = {
        let tv = UITextView()
        tv.isScrollEnabled = false
        tv.textContainer.maximumNumberOfLines = 0
        tv.textContainerInset = UIEdgeInsets.zero
        tv.textContainer.lineBreakMode = .byTruncatingTail
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.isEditable = false
        return tv
    }()
    
    func expandTextView(){
        guard let post = self.post else {return}
        captionViewHeightConstraint?.isActive = false
        captionTextView.textContainer.maximumNumberOfLines = 0
        
        // Set Up Caption
        
        let attributedTextCaption = NSMutableAttributedString(string: post.user.username, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
        
        attributedTextCaption.append(NSAttributedString(string: " \(post.caption)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 14)])))
        
        //        attributedTextCaption.append(NSAttributedString(string: "\n\n", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 4)]))
        
        self.captionTextView.attributedText = attributedTextCaption
        self.captionTextView.sizeToFit()
        
        
        
        //        self.delegate?.expandPost(post: post, newHeight: self.captionTextView.frame.height - captionViewHeight)
        //        print(self.captionTextView.frame.height, self.captionTextView.intrinsicContentSize)
        
    }
    
    @objc func HandleTap(sender: UITapGestureRecognizer) {
        
        let myTextView = sender.view as! UITextView //sender is TextView
        let layoutManager = myTextView.layoutManager //Set layout manager
        
        // location of tap in myTextView coordinates
        
        var location = sender.location(in: myTextView)
        
        if let tapPosition = captionTextView.closestPosition(to: location) {
            if let textRange = captionTextView.tokenizer.rangeEnclosingPosition(tapPosition , with: .word, inDirection: convertToUITextDirection(1)) {
                let tappedWord = captionTextView.text(in: textRange)
                print("Word: \(tappedWord)" ?? "")
                if tappedWord == post?.user.username.replacingOccurrences(of: "@", with: "") {
                    self.didTapUser(post: self.post!)
                } else {
                    //                    self.expandTextView()
                    self.handleComment()
                    //                    self.delegate?.didTapComment(post: self.post!)
                }
            }
        }
        
        //        To Detect if textview is truncated
        //        if textView.contentSize.height > textView.bounds.height
        
        
    }
    
    func word(atPosition: CGPoint) -> String? {
        if let tapPosition = captionTextView.closestPosition(to: atPosition) {
            if let textRange = captionTextView.tokenizer.rangeEnclosingPosition(tapPosition , with: .word, inDirection: convertToUITextDirection(1)) {
                let tappedWord = captionTextView.text(in: textRange)
                print("Word: \(tappedWord)" ?? "")
                return tappedWord
            }
            return nil
        }
        return nil
    }
    
    var captionView: UIView = {
        let view = UIView()
        //        view.layer.backgroundColor = UIColor.lightGray.cgColor.copy(alpha: 0.5)
        view.layer.backgroundColor = UIColor.white.cgColor.copy(alpha: 0.5)
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    var captionViewHeightConstraint: NSLayoutConstraint? = nil
    var showListCollectionViewConstraint: NSLayoutConstraint? = nil
    var hideListCollectionViewConstraint: NSLayoutConstraint? = nil
    
    var hideUserListCollectionViewConstraint: NSLayoutConstraint? = nil
    
    var hideLocationDistanceConstraint: NSLayoutConstraint? = nil

    
    var captionDisplayed: Bool = false
    
    let captionBubble: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 30)
        label.textAlignment = NSTextAlignment.center
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    
    //        DATE
    
    let postDateLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.lightGray
        label.numberOfLines = 0
        return label
    }()
    
    //    OPTIONS
    
    lazy var optionsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("•••", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(handleOptions), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        return button
    }()
    
    
    @objc func handleOptions() {
        guard let post = post else {return}
        print("Options Button Pressed")
        self.userOptionPost(post: post)
    }
    
    
    // LISTS
    var creatorListIds: [String] = []
    var postCreatorListIds: [String] = []
    var postCreatorListNames: [String] = []
    
    var postCurrentUserListIds: [String] = []
    var postCurrentUserListNames: [String] = []
    
    
    lazy var creatorListCollectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = .white
        return cv
    }()
    
    lazy var userListCollectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = .white
        return cv
    }()

    
    func setupRatingLegitIcon(){
        
        if (self.post?.rating)! != 0 {
            //            starRatingLabel.rating = (self.post?.rating)!
            //            self.starRatingLabelWidth?.constant = self.starRatingSize
            //            self.starRatingLabelWidth?.isActive = false
            
            self.starRating.rating = (self.post?.rating)!
            if starRating.rating >= 4 {
                starRating.settings.filledImage = #imageLiteral(resourceName: "star_rating_filled_high").withRenderingMode(.alwaysOriginal)
                starRating.settings.filledImage = #imageLiteral(resourceName: "rating_filled_high_test").withRenderingMode(.alwaysOriginal)

            } else {
                starRating.settings.filledImage = #imageLiteral(resourceName: "star_rating_filled_mid").withRenderingMode(.alwaysOriginal)
                starRating.settings.filledImage = #imageLiteral(resourceName: "rating_filled_mid_test").withRenderingMode(.alwaysOriginal)
            }
            
            self.starRatingHide?.isActive = false
            self.starRating.isHidden = false
//            self.starRating.sizeToFit()
            
            //            self.starRatingDisplay?.isActive = true
            //            self.starRatingLabel.sizeToFit()
        } else {
            //            self.starRatingLabelWidth?.constant = 0
            self.starRatingHide?.isActive = true
            self.starRating.isHidden = true
//            self.starRating.sizeToFit()
            
            //            self.starRatingDisplay?.isActive = false
            
        }
        
    }
    
    @objc func captionBubbleTap(){
        
//        print(post)
        
        if captionDisplayed {
            print("PictureController | Picture Tapped | Hide Caption")

            self.hideCaptionBubble()
            captionDisplayed = false
            captionView.layer.removeAllAnimations()
            captionBubble.layer.removeAllAnimations()
            testMapButton.layer.removeAllAnimations()
        } else {
            print("PictureController | Picture Tapped | Show Caption")
            
            self.showCaptionBubble()

            captionDisplayed = true
//            captionView.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: captionBubble.intrinsicContentSize)
            let captionViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(locationTap))
            captionView.isUserInteractionEnabled = true
            captionView.addGestureRecognizer(captionViewTapGesture)
            
//            let captionTapGesture = UITapGestureRecognizer(target: self, action: #selector(locationTap))
//            captionBubble.isUserInteractionEnabled = false
//            captionBubble.addGestureRecognizer(captionTapGesture)


            // Makes Captions Disappear fast if there is no caption
            
            var captionDelay = 0.0 as Double
            
            if (captionBubble.attributedText?.length)! > 1 && (captionBubble.text != "No Caption") {
                captionDelay = 3
            } else {
                captionDelay = 1
            }
            
            // User Interaction now allowed when object is being animated. So we delay it before reanimating it away
            let when = DispatchTime.now() + captionDelay // change 2 to desired number of seconds
            DispatchQueue.main.asyncAfter(deadline: when) {
                UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
                    self.hideCaptionBubble()
                    
                }, completion: { (finished: Bool) in
                    self.captionDisplayed = false
                })
            }
        }
    }
    
    func hideCaptionBubble(){
        self.captionView.alpha = 0
        self.captionBubble.alpha = 0
//        self.testMapButton.alpha = 0
    }
    
    func showCaptionBubble(){
        self.captionView.alpha = 1
        self.captionBubble.alpha = 1
//        self.testMapButton.alpha = 1
//        self.testMapButton.isUserInteractionEnabled = true

    }
    
    func fadeViewInThenOut(inputView : UIView, delay: TimeInterval) {
        
        inputView.alpha = 1
        inputView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        let animationDuration = 0.0
        
        // Fade in the view
        UIView.animate(withDuration: animationDuration,delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak inputView] in
                        
                        inputView?.transform = .identity
                        
        }) { (Bool) -> Void in
            
            // After the animation completes, fade out the view after a delay
            
            UIView.animate(withDuration: animationDuration, delay: delay, options: .curveEaseInOut, animations: { () -> Void in
                inputView.alpha = 0
            },
                           completion: nil)
        }
    }
    
    
    
    var locationViewHeight: CGFloat = 30
    var captionViewHeight: CGFloat = 45

    var profileImageSize: CGFloat = 50 - 10
    var starRatingSize: CGFloat = 50 - 10 - 10 - 5
    
    var headerHeight: CGFloat = 45 //40

    let scrollview: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = UIColor.white
        sv.isScrollEnabled = true
        sv.showsVerticalScrollIndicator = false
        return sv
    }()
    
    func setupNavigationItems(){
        // Nav Bar Buttons
//        let barButton1 = UIBarButtonItem.init(customView: sendMessageButton)
//        
//        self.navigationItem.rightBarButtonItems = [barButton1]
        
        let legitListTitle = UILabel()
        legitListTitle.text = "Post"
        //        legitListTitle.font = UIFont(name: "TitilliumWeb-SemiBold", size: 20)
        legitListTitle.font = UIFont(font: .noteworthyBold, size: 20)
        legitListTitle.textColor = UIColor.white
        legitListTitle.textAlignment = NSTextAlignment.center
        navigationItem.titleView  = legitListTitle
        
        navBarButton.addTarget(self, action: #selector(showDropDown), for: .touchUpInside)
        let barButton1 = UIBarButtonItem.init(customView: navBarButton)
        self.navigationItem.rightBarButtonItems = [barButton1]
        

        
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // INITT
        view.backgroundColor = UIColor.white
        setupNavigationItems()
        
        
        scrollview.frame = view.bounds
        scrollview.contentSize = CGSize(width: view.bounds.width, height: view.bounds.height)
        view.addSubview(scrollview)
        scrollview.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        scrollview.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

        
// HEADER VIEW
        let headerView = UIView()
        scrollview.addSubview(headerView)
        headerView.anchor(top: scrollview.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        headerView.heightAnchor.constraint(greaterThanOrEqualToConstant: headerHeight).isActive = true
        
    // Add Location Name
        headerView.addSubview(locationNameLabel)
        locationNameLabel.anchor(top: headerView.topAnchor, left: headerView.leftAnchor, bottom: headerView.bottomAnchor, right: nil, paddingTop: 3, paddingLeft: 10, paddingBottom: 3, paddingRight: 10, width: 0, height: 0)
        locationNameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: self.view.frame.width * 2 / 3).isActive = true
        
        locationNameLabel.sizeToFit()
        locationNameLabel.isUserInteractionEnabled = true
        locationNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(locationTap)))

        let locationDetails = UIView()
        locationDetails.addSubview(locationDistanceLabel)
        locationDistanceLabel.anchor(top: locationDetails.topAnchor, left: locationDetails.leftAnchor, bottom: nil, right: locationDetails.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        locationDistanceLabel.isUserInteractionEnabled = true
        locationDistanceLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(activateMap)))
        
        locationDetails.addSubview(locationCityLabel)
        locationCityLabel.anchor(top: locationDistanceLabel.bottomAnchor, left: locationDetails.leftAnchor, bottom: locationDetails.bottomAnchor, right: locationDetails.rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        locationCityLabel.sizeToFit()
        
        headerView.addSubview(locationDetails)
        locationDetails.anchor(top: nil, left: nil, bottom: nil, right: headerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        locationDetails.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        
        
        view.addSubview(dropDownMenu)
        dropDownMenu.anchor(top: scrollview.topAnchor, left: nil, bottom: nil, right: scrollview.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

    // Add Location Distance
//        headerView.addSubview(locationDistanceLabel)
//        locationDistanceLabel.anchor(top: headerView.topAnchor, left: locationNameLabel.rightAnchor, bottom: nil, right: headerView.rightAnchor, paddingTop: 5, paddingLeft: 2, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)
//        locationDistanceLabel.sizeToFit()
//        locationDistanceLabel.isUserInteractionEnabled = true
//        locationDistanceLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(activateMap)))
//
//        // Add Location City
//        headerView.addSubview(locationCityLabel)
//        locationCityLabel.anchor(top: locationDistanceLabel.bottomAnchor, left: locationNameLabel.rightAnchor, bottom: nil, right: headerView.rightAnchor, paddingTop: 2, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
//        locationCityLabel.bottomAnchor.constraint(lessThanOrEqualTo: headerView.bottomAnchor).isActive = true
//        locationCityLabel.sizeToFit()
        
// IMAGE SCROLL VIEW
        scrollview.addSubview(photoImageScrollView)
        photoImageScrollView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.width)
        photoImageScrollView.anchor(top: headerView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        photoImageScrollView.heightAnchor.constraint(equalTo: photoImageScrollView.widthAnchor, multiplier: 1).isActive = true
        photoImageScrollView.isPagingEnabled = true
        photoImageScrollView.delegate = self
        
        setupPhotoImageScrollView()
        
        
// USER PROFILE AND STAR RATING

        //        userProfileImageView.anchor(top: nil, left: nil, bottom: nil, right: headerView.rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: profileImageSize, height: profileImageSize)
        
        scrollview.addSubview(userProfileImageView)
        userProfileImageView.anchor(top: photoImageScrollView.topAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 15, paddingRight: 10, width: profileImageSize, height: profileImageSize)

        userProfileImageView.layer.cornerRadius = profileImageSize/2
        userProfileImageView.layer.borderWidth = 2
        userProfileImageView.layer.borderColor = UIColor.white.cgColor
        
        userProfileImageView.isUserInteractionEnabled = true
        userProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(usernameTap)))
//        userProfileImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        
        scrollview.addSubview(usernameLabel)
        usernameLabel.anchor(top: nil, left: nil, bottom: nil, right: userProfileImageView.leftAnchor, paddingTop: 2, paddingLeft: 3, paddingBottom: 2, paddingRight: 3, width: 0, height: 0)
        usernameLabel.centerYAnchor.constraint(equalTo: userProfileImageView.centerYAnchor).isActive = true
        usernameLabel.sizeToFit()
        
        scrollview.addSubview(starRating)
        starRating.anchor(top: nil, left: photoImageScrollView.leftAnchor, bottom: photoImageScrollView.bottomAnchor, right: nil, paddingTop: 10, paddingLeft: 5, paddingBottom: 10, paddingRight: 10, width: 0, height: 0)
        starRating.sizeToFit()
        starRatingHide = starRating.widthAnchor.constraint(equalToConstant: 0)
        
//        scrollview.addSubview(extraRatingLabel)
//        extraRatingLabel.anchor(top: nil, left: starRating.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 2, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        extraRatingLabel.sizeToFit()
        
        
//        let usernameView = UIView()
//        scrollview.addSubview(usernameView)
//        usernameView.anchor(top: nil, left: nil, bottom: nil, right: userProfileImageView.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
//        usernameView.centerYAnchor.constraint(equalTo: userProfileImageView.centerYAnchor).isActive = true
//
//        scrollview.addSubview(usernameLabel)
//        usernameLabel.anchor(top: usernameView.topAnchor, left: nil, bottom: nil, right: usernameView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
////        usernameLabel.centerYAnchor.constraint(equalTo: userProfileImageView.centerYAnchor).isActive = true
//        usernameLabel.leftAnchor.constraint(lessThanOrEqualTo: usernameView.leftAnchor).isActive = true
//        usernameLabel.sizeToFit()
//
//        // Add Location City
//        scrollview.addSubview(locationCityLabel)
//        locationCityLabel.anchor(top: usernameLabel.bottomAnchor, left: nil, bottom: usernameView.bottomAnchor, right: usernameView.rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        locationCityLabel.leftAnchor.constraint(lessThanOrEqualTo: usernameView.leftAnchor).isActive = true
//        locationCityLabel.sizeToFit()
        
//        starRating.anchor(top: nil, left: headerView.leftAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)
//        starRating.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true


 
        // Photo Image View and Complex User Interactions
        
        // Need to set the frame as scroll view frame width goes to 0 when new cell after the first cell is being made for some reason.

        
//        // Username Profile Picture
//        scrollview.addSubview(userProfileImageView)
//
//        userProfileImageView.anchor(top: photoImageScrollView.topAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: profileImageSize, height: profileImageSize)
//        userProfileImageView.layer.cornerRadius = profileImageSize/2
//        userProfileImageView.layer.borderWidth = 2
//        userProfileImageView.layer.borderColor = UIColor.white.cgColor
//
//        userProfileImageView.isUserInteractionEnabled = true
//        userProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(usernameTap)))
//
        setupCaptionBubble()
        setupEmojiDetails()
        setupListCollectionView()
        setupPostLocationView()
        setupPostCaptions()
        
        setupLocationView()
        setupDropDown()

//        dropDownMenu.anchor(top: topLayoutGuide.bottomAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)


        
        
    }
    
    func setupPhotoImageScrollView(){
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(photoDoubleTapped))
        doubleTap.numberOfTapsRequired = 2
        photoImageScrollView.addGestureRecognizer(doubleTap)
        photoImageScrollView.isUserInteractionEnabled = true
        
        //        let captionTapGesture = UITapGestureRecognizer(target: self, action: #selector(displayCaptionBubble))
        let photoTapGesture = UITapGestureRecognizer(target: self, action: #selector(captionBubbleTap))
        photoImageScrollView.addGestureRecognizer(photoTapGesture)
        photoTapGesture.require(toFail: doubleTap)
        
        photoImageScrollView.contentSize.width = photoImageScrollView.frame.width
        
        photoImageView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.width)
        photoImageScrollView.addSubview(photoImageView)
        photoImageView.tag = 0
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.pinch(sender:)))
        pinch.delegate = self
        //        self.photoImageView.addGestureRecognizer(pinch)
        self.photoImageScrollView.addGestureRecognizer(pinch)
        
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.pan(sender:)))
        pan.delegate = self
        //        self.photoImageView.addGestureRecognizer(pan)
        self.photoImageScrollView.addGestureRecognizer(pan)
        
        
        // Add Photo Count Label
        
//        scrollview.addSubview(photoCountLabel)
//        photoCountLabel.anchor(top: nil, left: view.leftAnchor, bottom: photoImageScrollView.bottomAnchor, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 5, width: 0, height: 0)
//        photoCountLabel.sizeToFit()
        

        scrollview.addSubview(pageControl)
        pageControl.anchor(top: nil, left: nil, bottom: photoImageScrollView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 100, height: 5)
        pageControl.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        setupPageControl()
        
        
    }
    
    var pageControl : UIPageControl = UIPageControl()

    
    func setupPageControl(){
        self.pageControl.numberOfPages = (self.post?.imageCount)!
        self.pageControl.currentPage = 0
        self.pageControl.tintColor = UIColor.red
        self.pageControl.pageIndicatorTintColor = UIColor.white
        self.pageControl.currentPageIndicatorTintColor = UIColor.mainBlue()
        self.pageControl.isHidden = self.pageControl.numberOfPages == 1
    }
    
    func testprint(){
        print("test")
    }
    
    
    
    func setupListCollectionView(){
        creatorListCollectionView.register(ListDisplayCell.self, forCellWithReuseIdentifier: cellId)
        let layout = ListDisplayFlowLayout()
        creatorListCollectionView.collectionViewLayout = layout
        creatorListCollectionView.backgroundColor = UIColor.clear
        creatorListCollectionView.isScrollEnabled = true
        creatorListCollectionView.showsHorizontalScrollIndicator = false
//        creatorListCollectionView.semanticContentAttribute = UISemanticContentAttribute.forceRightToLeft

        userListCollectionView.register(ListDisplayCell.self, forCellWithReuseIdentifier: cellId)
        let layout1 = ListDisplayFlowLayout()
        userListCollectionView.collectionViewLayout = layout1
        userListCollectionView.backgroundColor = UIColor.clear
        userListCollectionView.isScrollEnabled = true
        userListCollectionView.showsHorizontalScrollIndicator = false
        userListCollectionView.semanticContentAttribute = UISemanticContentAttribute.forceRightToLeft
        
    }
    
    func setupEmojiDetails(){
        emojiArray.alignment = .right
        emojiArray.delegate = self
        scrollview.addSubview(emojiArray)
        emojiArray.anchor(top: nil, left: nil, bottom: photoImageScrollView.bottomAnchor, right: photoImageScrollView.rightAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 0, height: 25)
        
        scrollview.addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top: nil, left: nil, bottom: emojiArray.topAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        emojiDetailLabel.sizeToFit()
        emojiDetailLabel.centerXAnchor.constraint(equalTo: photoImageScrollView.centerXAnchor).isActive = true
//        emojiDetailLabel.centerYAnchor.constraint(equalTo: photoImageScrollView.centerYAnchor).isActive = true

//        emojiDetailLabel.centerYAnchor.constraint(equalTo: photoImageScrollView.centerYAnchor).isActive = true

        emojiDetailLabel.alpha = 0
        
        
    }
    
    func setupPostLocationView(){
//        scrollview.addSubview(locationView)
//        locationView.anchor(top: photoImageScrollView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//
//
//        // Add Location Distance
//        scrollview.addSubview(locationDistanceLabel)
//        locationDistanceLabel.anchor(top: locationView.topAnchor, left: nil, bottom: nil, right: locationView.rightAnchor, paddingTop: 5, paddingLeft: 2, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
//        locationDistanceLabel.sizeToFit()
//        locationDistanceLabel.isUserInteractionEnabled = true
//        locationDistanceLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(activateMap)))
//
//        // Add Location Name
//        locationView.addSubview(locationNameLabel)
//        locationNameLabel.anchor(top: locationView.topAnchor, left: locationView.leftAnchor, bottom: locationView.bottomAnchor, right: nil, paddingTop: 3, paddingLeft: 10, paddingBottom: 3, paddingRight: 10, width: 0, height: 0)
//        locationNameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: self.view.frame.width * 2 / 3)
//
//        locationNameLabel.sizeToFit()
//        locationNameLabel.isUserInteractionEnabled = true
//        locationNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(locationTap)))

//        locationCityLabel.bottomAnchor.constraint(lessThanOrEqualTo: locationView.bottomAnchor).isActive = true
        
        //locationCityViewHeight = locationCityLabel.heightAnchor.constraint(equalToConstant: 0)
//        locationCityViewHeight?.isActive = true
        
//        locationView.addSubview(emojiDetailLabel)
//        emojiDetailLabel.anchor(top: nil, left: nil, bottom: locationView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 100, height: 100)
//        emojiDetailLabel.sizeToFit()
//        emojiDetailLabel.centerXAnchor.constraint(equalTo: photoImageScrollView.centerXAnchor).isActive = true
//        //        emojiDetailLabel.centerYAnchor.constraint(equalTo: photoImageScrollView.centerYAnchor).isActive = true
//
//        emojiDetailLabel.alpha = 1
        

    }
    
    let listView = UIView()
    let listViewBackgroundColor = UIColor.lightSelectedColor()
    var listAddedHideHeight: NSLayoutConstraint?

    func setupPostCaptions(){
        
        // Action Bar
        scrollview.addSubview(actionBar)
        actionBar.anchor(top: photoImageScrollView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 35)
        setupActionButtons()

        scrollview.addSubview(listAddedStatsLabel)
        listAddedStatsLabel.anchor(top: actionBar.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 2, paddingLeft: 10, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        listAddedHideHeight = listAddedStatsLabel.heightAnchor.constraint(equalToConstant: 0)
        listAddedStatsLabel.isUserInteractionEnabled = true
        listAddedStatsLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayAllLists)))
        
        
        
    // CAPTION
        scrollview.addSubview(captionTextView)
        captionTextView.anchor(top: listAddedStatsLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 4, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        captionTextView.backgroundColor = UIColor.clear
        captionTextView.sizeToFit()
        captionTextView.isUserInteractionEnabled = true
        
        let textViewTap = UITapGestureRecognizer(target: self, action: #selector(self.HandleTap(sender:)))
        textViewTap.delegate = self
        captionTextView.addGestureRecognizer(textViewTap)
        
        

        scrollview.addSubview(postDateLabel)
        postDateLabel.anchor(top: captionTextView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 0, width: 0, height: 15)
        postDateLabel.sizeToFit()
        
        scrollview.addSubview(optionsButton)
        optionsButton.anchor(top: postDateLabel.topAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 40, height: 15)
        //        optionsButton.widthAnchor.constraint(equalTo: optionsButton.heightAnchor).isActive = true
        optionsButton.centerYAnchor.constraint(equalTo: postDateLabel.centerYAnchor).isActive = true
        optionsButton.isHidden = true
        
        setupListViews()
        
        

    }
    
    let locationViewController = LocationController()

    
    func setupLocationView(){
        locationViewController.showSelectedPostPicture = false
        locationViewController.selectedPost = self.post
        self.addChild(locationViewController)
        scrollview.addSubview(locationViewController.view)
        locationViewController.view.anchor(top: postDateLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: view.frame.height)
        locationViewController.scrollView.isScrollEnabled = false

        
    }
    
    var creatorUserListLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:10)
        label.textColor = UIColor.lightLegitColor()
        label.textAlignment = NSTextAlignment.left
//        label.isUserInteractionEnabled = true
//        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayFollowLists)))
        return label
    }()

    var currentUserListLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:10)
        label.textColor = UIColor.lightRedColor()
        label.textAlignment = NSTextAlignment.right
        //        label.isUserInteractionEnabled = true
        //        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayFollowLists)))
        return label
    }()
    func setupListViews(){
    // LIST COLLECTION VIEW
    
        scrollview.addSubview(listView)
        listView.anchor(top: nil, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        listView.backgroundColor = listViewBackgroundColor

        listView.addSubview(creatorUserListLabel)
        creatorUserListLabel.anchor(top: nil, left: listView.leftAnchor, bottom: listView.bottomAnchor, right: nil, paddingTop: 1, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        listView.addSubview(creatorListCollectionView)
        creatorListCollectionView.anchor(top: listView.topAnchor, left: listView.leftAnchor, bottom: creatorUserListLabel.topAnchor, right: listView.rightAnchor, paddingTop: 1, paddingLeft: 5, paddingBottom: 1, paddingRight: 5, width: 0, height: locationViewHeight)
        
        listView.addSubview(currentUserListLabel)
        currentUserListLabel.anchor(top: nil, left: creatorUserListLabel.rightAnchor, bottom: listView.bottomAnchor, right: listView.rightAnchor, paddingTop: 1, paddingLeft: 5, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        
        listView.addSubview(userListCollectionView)
        userListCollectionView.anchor(top: listView.topAnchor, left: view.centerXAnchor, bottom: currentUserListLabel.topAnchor, right: listView.rightAnchor, paddingTop: 1, paddingLeft: 5, paddingBottom: 1, paddingRight: 5, width: 0, height: locationViewHeight)
        
        
        
        //        // LIST SOCIAL COUNT
        //        listView.addSubview(socialListsLabel)
        //        socialListsLabel.anchor(top: nil, left: listView.leftAnchor, bottom: nil, right: view.centerXAnchor, paddingTop: 3, paddingLeft: 10, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        //        socialListsLabel.centerYAnchor.constraint(equalTo: listView.centerYAnchor).isActive = true
        //        socialListsLabel.widthAnchor.constraint(lessThanOrEqualToConstant: self.view.frame.width/2).isActive = true
        //        socialStatsViewHeightHide = socialListsLabel.heightAnchor.constraint(equalToConstant: 0)
        //        socialStatsViewHeightHide?.isActive = true
        //        socialListsLabel.sizeToFit()
        //        socialListsLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayAllLists)))
        
        
//        creatorListCollectionView.anchor(top: nil, left: listView.leftAnchor, bottom: nil, right: view.centerXAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 3, paddingRight: 5, width: 0, height: locationViewHeight)
//        creatorListCollectionView.centerYAnchor.constraint(equalTo: listView.centerYAnchor).isActive = true
        //        showListCollectionViewConstraint = creatorListCollectionView.heightAnchor.constraint(equalToConstant: locationViewHeight)
        //        hideListCollectionViewConstraint = creatorListCollectionView.heightAnchor.constraint(equalToConstant: 0)
        //        showListCollectionViewConstraint?.isActive = true
    


    }
    
    func fillInCaptionBubble(){
        guard let post = self.post else {return}
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        let attributedString = NSMutableAttributedString(string: "", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 30)]))
        
        // Add Location Name
        var attributedCaption = NSMutableAttributedString(string: "\(post.locationName)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .noteworthyBold, size: 20), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkLegitColor()]))
        attributedString.append(attributedCaption)
        
        
        // Add Location Adress
        attributedCaption = NSMutableAttributedString(string: "\n\(post.locationAdress)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 18), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black]))
        attributedString.append(attributedCaption)
        
        for (index,tag) in post.autoTagEmojiTags.enumerated() {
            attributedCaption = NSMutableAttributedString(string: "\n\(post.autoTagEmoji[index]) \(post.autoTagEmojiTags[index].capitalizingFirstLetter())", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 15), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray]))
            attributedString.append(attributedCaption)
        }
        
        if post.price != nil {
            attributedCaption = NSMutableAttributedString(string: "\n\(post.price!)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 18), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.rgb(red: 0, green: 128, blue: 0)]))
            attributedString.append(attributedCaption)

        }
        

        captionBubble.attributedText = attributedString
        captionBubble.numberOfLines = 0
        captionBubble.sizeToFit()
        
    }
    
    func setupCaptionBubble(){
        
//        scrollview.addSubview(captionView)
//        photoImageScrollView.anchor(top: photoImageScrollView.topAnchor, left: photoImageScrollView.leftAnchor, bottom: nil, right: photoImageScrollView.rightAnchor, paddingTop: 30, paddingLeft: 50, paddingBottom: 0, paddingRight: 50, width: 0, height: 0)


        scrollview.addSubview(captionView)
        captionView.anchor(top: photoImageScrollView.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 30, paddingLeft: 50, paddingBottom: 0, paddingRight: 50, width: 0, height: 0)
        captionView.bottomAnchor.constraint(lessThanOrEqualTo: photoImageScrollView.bottomAnchor).isActive = true

        scrollview.addSubview(captionBubble)
        captionBubble.anchor(top: captionView.topAnchor, left: captionView.leftAnchor, bottom: captionView.bottomAnchor, right: captionView.rightAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 0, height: 0)
        captionBubble.contentMode = .center

//        scrollview.addSubview(testMapButton)
//        testMapButton.anchor(top: captionBubble.bottomAnchor, left: nil, bottom: captionView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        testMapButton.centerXAnchor.constraint(equalTo: captionView.centerXAnchor).isActive = true
        
        // Hide initial caption bubbles
        hideCaptionBubble()
//        testMapButton.alpha = 1
        
    }
    
    
    
    func setupPicturesScroll() {
        
        //        guard let _ = post?.imageUrls else {return}
        
        photoImageScrollView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.width)
        photoImageScrollView.contentSize.width = photoImageScrollView.frame.width * CGFloat((post?.imageCount)!)
//        print("setupPicturesScroll | PhotoImageView ", photoImageScrollView.contentSize)

        for i in 1 ..< (post?.imageCount)! {
            
            let imageView = CustomImageView()
            if post?.imageUrls[i] == nil && post?.images != nil {
                imageView.image = post?.images![i]
            } else {
                imageView.loadImage(urlString: (post?.imageUrls[i])!)
            }
            imageView.backgroundColor = .white
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.isUserInteractionEnabled = true
            
            let xPosition = self.photoImageScrollView.frame.width * CGFloat(i)
            imageView.frame = CGRect(x: xPosition, y: 0, width: photoImageScrollView.frame.width, height: photoImageScrollView.frame.height)
            
            photoImageScrollView.addSubview(imageView)
            
        }
        //        photoImageScrollView.reloadInputViews()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.currentImage = scrollView.currentPage
        self.pageControl.currentPage = self.currentImage - 1
        print(self.currentImage, self.pageControl.currentPage)

    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.hideEmojiDetailLabel()
    }
    
    
    
    // Following Creds
    var socialStatsView: UIView = {
        let view = UIView()
        return view
    }()
    var socialStatsViewHeightHide: NSLayoutConstraint? = nil
    
    
    let voteStatsTextView: UITextView = {
        let tv = UITextView()
        tv.isScrollEnabled = false
        tv.textContainer.maximumNumberOfLines = 2
        tv.textContainerInset = UIEdgeInsets.zero
        tv.textContainer.lineBreakMode = .byTruncatingTail
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.font = UIFont.boldSystemFont(ofSize: 15)
        tv.textColor = UIColor.legitColor()
        tv.isEditable = false
        return tv
    }()
    
    func HandleVoteStatsTap(sender: UITapGestureRecognizer) {
        
        let myTextView = sender.view as! UITextView //sender is TextView
        let layoutManager = myTextView.layoutManager //Set layout manager
        
        // location of tap in myTextView coordinates
        
        var location = sender.location(in: myTextView)
        
        if let tapPosition = myTextView.closestPosition(to: location) {
            if let textRange = myTextView.tokenizer.rangeEnclosingPosition(tapPosition , with: .word, inDirection: convertToUITextDirection(1)) {
                let tappedWord = myTextView.text(in: textRange)?.replacingOccurrences(of: ",", with: "")
                print("Word: \(tappedWord)" ?? "")
                if displayNamesUid[tappedWord!] != nil {
                    self.didTapUserUid(uid: displayNamesUid[tappedWord!]!)
                } else {
                    //                    self.delegate?.displayPostSocialUsers(post: self.post!, following: true)
                }
            }
        }
    }
    
    
    var listAddedStatsLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.systemFont(ofSize:12)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.left
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayFollowLists)))
        return label
    }()
    
    var followVoteStatsLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:14)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.left
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayFollowingVotes)))
        return label
    }()
    
    @objc func displayFollowLists(){
        self.displayPostSocialLists(post: self.post!, following: true)
    }
    
    @objc func displayFollowingVotes(){
        self.displayPostSocialUsers(post: self.post!, following: true)
    }
    
    @objc func displayAllLists(){
        let displayFollowing = (self.post!.followingList.count > 0)
        self.displayPostSocialLists(post: self.post!, following: displayFollowing)
    }
    
    func displayAllVotes(){
        self.displayPostSocialUsers(post: self.post!, following: true)
    }
    
    // Action Buttons
    
    var actionBar: UIView = {
        let view = UIView()
        //        view.backgroundColor = UIColor.white
        return view
    }()
    
    lazy var likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "like_unselected").withRenderingMode(.alwaysOriginal), for: .normal)
        button.setImage(#imageLiteral(resourceName: "drool").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleLike), for: .touchUpInside)
        return button
    }()
    
    lazy var likeButtonLabel: UILabel = {
        let label = UILabel()
        label.text = "Like"
        label.font = UIFont.boldSystemFont(ofSize:10)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.center
        label.isUserInteractionEnabled = true
        return label
    }()
    
    lazy var commentButtonLabel: UILabel = {
        let label = UILabel()
        label.text = "Comment"
        label.font = UIFont.boldSystemFont(ofSize:10)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.center
        label.isUserInteractionEnabled = true
        return label
    }()
    
    lazy var bookmarkButtonLabel: UILabel = {
        let label = UILabel()
        label.text = "List"
        label.font = UIFont.boldSystemFont(ofSize:10)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.center
        label.isUserInteractionEnabled = true
        return label
    }()
    
    lazy var socialListsLabel: UILabel = {
        let label = UILabel()
        label.text = "List"
        label.font = UIFont.boldSystemFont(ofSize:13)
        label.textColor = UIColor.darkLegitColor()
        label.textAlignment = NSTextAlignment.left
        label.isUserInteractionEnabled = true
        label.backgroundColor = UIColor.clear
        return label
    }()

    
    @objc func handleLike() {
        //      delegate?.didLike(for: self)
        
        guard let postId = self.post?.id else {return}
        guard let creatorId = self.post?.creatorUID else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        // Animates before database function is complete
        
        if (self.post?.hasLiked)! {
            // Unselect Upvote
            self.post?.hasLiked = false
            self.post?.likeCount -= 1
            Database.handleVote(post: post, creatorUid: creatorId, vote: 0) {}
            
        } else {
            // Upvote
            self.post?.hasLiked = true
            self.post?.likeCount += 1
            Database.handleVote(post: post, creatorUid: creatorId, vote: 1) {}
            
        }
        self.setupAttributedSocialCount()
        self.delegate?.refreshPost(post: self.post!)
        
        self.likeButton.setImage(#imageLiteral(resourceName: "drool").alpha((post?.hasLiked)! ? 1 : 0.5).withRenderingMode(.alwaysOriginal), for: .normal)
        self.likeButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.likeButton.transform = .identity
                        self?.likeButton.layoutIfNeeded()
                        
            },
                       completion: nil)
        
        
        if (self.post?.hasLiked)! {
            var origin: CGPoint = self.photoImageScrollView.center;
            popView = UIView(frame: CGRect(x: origin.x, y: origin.y, width: 100, height: 100))
            popView = UIImageView(image: #imageLiteral(resourceName: "drool").resizeImageWith(newSize: CGSize(width: 100, height: 100)).withRenderingMode(.alwaysOriginal))
            popView.contentMode = .scaleToFill
            popView.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
            popView.frame.origin.x = origin.x
            popView.frame.origin.y = origin.y * 0.5
            
            photoImageView.addSubview(popView)
            
            UIView.animate(withDuration: 1,
                           delay: 0,
                           usingSpringWithDamping: 0.2,
                           initialSpringVelocity: 6.0,
                           options: .allowUserInteraction,
                           animations: { [weak self] in
                            self?.popView.transform = .identity
            }) { (done) in
                self.popView.removeFromSuperview()
                self.popView.alpha = 0
            }
            
            let when = DispatchTime.now() + 2
            DispatchQueue.main.asyncAfter(deadline: when) {
                self.popView.alpha = 0
            }
        }
    }

    
    // Bookmark
    
    lazy var bookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleBookmark), for: .touchUpInside)
        button.layer.cornerRadius = button.bounds.size.width/2
        button.layer.masksToBounds = true
        button.clipsToBounds = true
        return button
        
    }()
    
    @objc func handleBookmark() {
        guard let post = post else {return}
        self.didTapBookmark(post: post)
        
    }
    
    // Comments
    
    lazy var commentButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(handleComment), for: .touchUpInside)
        return button
        
    }()
    
    @objc func handleComment() {
        guard let post = post else {return}
        self.didTapComment(post: post)
    }
    
    // Dropdown
    
    var dropDownMenu = DropDown()
    func setupDropDown(){
        dropDownMenu.anchorView = sendMessageButton
        dropDownMenu.dismissMode = .automatic
        dropDownMenu.textColor = UIColor.darkLegitColor()
        dropDownMenu.textFont = UIFont.systemFont(ofSize: 15)
        dropDownMenu.backgroundColor = UIColor.white
        dropDownMenu.selectionBackgroundColor = UIColor.legitColor().withAlphaComponent(0.5)
        dropDownMenu.cellHeight = 50
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        var messageArray = [iMessage, emailMessage]
        
        dropDownMenu.dataSource = messageArray
        dropDownMenu.selectionAction = { [unowned self] (index: Int, item: String) in
            print("Selected item: \(item) at index: \(index)")
            self.handleShare(format: item)
            self.dropDownMenu.hide()
        }
        
//        if let index = self.dropDownMenu.dataSource.firstIndex(of: self.selectedSort) {
//            print("DropDown Menu Preselect \(index) \(self.dropDownMenu.dataSource[index])")
//            dropDownMenu.selectRow(index)
//        }
    }
    
    @objc func showDropDown(){
        let optionsAlert = UIAlertController(title: "Share this post via email or IMessage. LegitList is not required to receive posts.", message: "", preferredStyle: UIAlertController.Style.alert)

        optionsAlert.addAction(UIAlertAction(title: "iMessage", style: .default, handler: { (action: UIAlertAction!) in
            // Allow Editing
            self.handleIMessage()
        }))

        optionsAlert.addAction(UIAlertAction(title: "Email", style: .default, handler: { (action: UIAlertAction!) in
            self.handleMessage()
        }))

        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))

        present(optionsAlert, animated: true) {
            optionsAlert.view.superview?.isUserInteractionEnabled = true
            optionsAlert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.alertClose(gesture:))))
        }
        
        
        
//        if self.dropDownMenu.isHidden{
//            self.dropDownMenu.show()
//        } else {
//            self.dropDownMenu.hide()
//        }
    }
    
    
    func handleShare(format: String) {
        if format ==  emailMessage {
            self.handleMessage()
        } else if format == iMessage {
            self.handleIMessage()
        }
    }
    
    func handleIMessage(){
        if MFMessageComposeViewController.canSendText() == true {
            let recipients:[String] = []
            let messageController = MFMessageComposeViewController()
            guard let post = post else {return}
            guard let coord = post.locationGPS?.coordinate else {return}
            let url = "http://maps.apple.com/maps?saddr=\(coord.latitude),\(coord.longitude)"
            let convoString = post.locationName + " " + post.emoji + "\n" + post.locationAdress + " \n" + post.caption
                //+ "\n" + "- @\(post.user.username)"
            
            messageController.messageComposeDelegate = self
            messageController.recipients = []
            messageController.body = convoString
            
            let sentImageUrl = self.post?.imageUrls[0] ?? ""
            if let image = imageCache[sentImageUrl] {
                let png = image.pngData()
                messageController.addAttachmentData(png!, typeIdentifier: "public.png", filename: "image.png")
            }
            
            
//                String(format: "http://maps.google.com/?saddr=%1.6f,%1.6f", arguments: [coord.latitude, coord.longitude])

//            let urlAttached = messageController.addAttachmentURL(URL(string: url)!, withAlternateFilename: nil)
//            print(urlAttached)
            

            
            
            
            
            //            let url = URL(fileURLWithPath: sentImageUrl)
            //
            //            messageController.addAttachmentURL(url, withAlternateFilename: "Test")
//            messageController.addAttachmentURL(self.locationVCardURLFromCoordinate(coordinate: CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude))! as URL, withAlternateFilename: "vCard.loc.vcf")
            

            
            self.present(messageController, animated: true, completion: nil)
            print("IMessage")
        } else {
            self.alert(title: "ERROR", message: "Text Not Supported")
        }

    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch (result) {
        case .cancelled:
            print("Message was cancelled")
            dismiss(animated: true, completion: nil)
        case .failed:
            print("Message failed")
            dismiss(animated: true, completion: nil)
        case .sent:
            print("Message was sent")
            dismiss(animated: true, completion: nil)
        default:
            break
        }
    }
    
    // Send Message
    
    lazy var sendMessageButton: UIButton = {
        let button = UIButton(type: .system)
        //        button.setImage(#imageLiteral(resourceName: "message").withRenderingMode(.alwaysOriginal), for: .normal)
        button.setImage(#imageLiteral(resourceName: "send_plane").withRenderingMode(.alwaysOriginal), for: .normal)
        
        button.addTarget(self, action: #selector(showDropDown), for: .touchUpInside)
        return button
        
    }()
    
    func handleMessage(){
        guard let post = post else {return}
        self.didTapMessage(post: post)
    }
    
    
    let postCountColor = UIColor.darkGray
    
    let listCount: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:14)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.right
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let messageCount: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:14)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.left
        return label
    }()
    
    let commentCount: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:14)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.left
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let likeCount: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:14)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.center
        label.isUserInteractionEnabled = true
        return label
    }()
    
    
    fileprivate func setupActionButtons() {
        
        guard let post = post else {return}
        
        let voteView = UIView()
        //        voteView.backgroundColor = UIColor.blue
        
        let commentView = UIView()
        //        commentView.backgroundColor = UIColor.yellow
        
        let bookmarkView = UIView()
        //        bookmarkView.backgroundColor = UIColor.blue
        
        let messageView = UIView()
        //        messageView.backgroundColor = UIColor.yellow
        
        let likeContainer = UIView()
        let commentContainer = UIView()
        let listContainer = UIView()
        let messageContainer = UIView()
        let actionStackView = UIStackView(arrangedSubviews: [voteView, commentView,bookmarkView])
        actionStackView.distribution = .fillEqually
        
        scrollview.addSubview(actionStackView)
        
        
        actionStackView.anchor(top: actionBar.topAnchor, left: view.leftAnchor, bottom: actionBar.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
        
        // Cred
        likeContainer.addSubview(likeButton)
        likeContainer.addSubview(likeButtonLabel)
        likeContainer.addSubview(likeCount)
        //        credView.backgroundColor = UIColor.init(hex: "009688")
        
        //        credView.backgroundColor = UIColor.init(hex: "#26A69A")
        voteView.backgroundColor = UIColor.clear
        
        likeButton.anchor(top: likeContainer.topAnchor, left: likeContainer.leftAnchor, bottom: likeContainer.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        likeButton.widthAnchor.constraint(equalTo: likeButton.heightAnchor, multiplier: 1).isActive = true
//        likeButtonLabel.anchor(top: likeButton.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 1, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        likeButtonLabel.centerXAnchor.constraint(equalTo: likeButton.centerXAnchor).isActive = true
//        likeButtonLabel.sizeToFit()

        
        likeCount.anchor(top: likeContainer.topAnchor, left: likeButton.rightAnchor, bottom: likeContainer.bottomAnchor, right: likeContainer.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        likeCount.centerYAnchor.constraint(equalTo: likeButton.centerYAnchor).isActive = true
        likeCount.sizeToFit()
        likeCount.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleLike)))
        
        
        scrollview.addSubview(likeContainer)
        likeContainer.anchor(top: voteView.topAnchor, left: nil, bottom: voteView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        likeContainer.centerXAnchor.constraint(equalTo: voteView.centerXAnchor).isActive = true
        
        // Comments
        
        commentContainer.addSubview(commentButton)
        commentContainer.addSubview(commentCount)
        commentContainer.addSubview(commentButtonLabel)

        commentView.backgroundColor = UIColor.clear
        
        commentButton.anchor(top: commentContainer.topAnchor, left: commentContainer.leftAnchor, bottom: commentContainer.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        commentButton.widthAnchor.constraint(equalTo: commentButton.heightAnchor, multiplier: 1).isActive = true
        
//        commentButtonLabel.anchor(top: commentButton.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 1, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        commentButtonLabel.centerXAnchor.constraint(equalTo: commentButton.centerXAnchor).isActive = true
//        commentButtonLabel.sizeToFit()
        
        commentCount.anchor(top: commentContainer.topAnchor, left: commentButton.rightAnchor, bottom: commentContainer.bottomAnchor, right: commentContainer.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        commentCount.centerYAnchor.constraint(equalTo: commentButton.centerYAnchor).isActive = true
        commentCount.sizeToFit()
        commentCount.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleComment)))
        
        scrollview.addSubview(commentContainer)
        commentContainer.anchor(top: commentView.topAnchor, left: nil, bottom: commentView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        commentContainer.centerXAnchor.constraint(equalTo: commentView.centerXAnchor).isActive = true
        
        // Bookmarks
        
        listContainer.addSubview(bookmarkButton)
        listContainer.addSubview(listCount)
        
        bookmarkView.backgroundColor = UIColor.clear
        
        bookmarkButton.anchor(top: listContainer.topAnchor, left: listContainer.leftAnchor, bottom: listContainer.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        bookmarkButton.widthAnchor.constraint(equalTo: bookmarkButton.heightAnchor, multiplier: 1).isActive = true
        bookmarkButton.layer.cornerRadius = bookmarkButton.bounds.size.width/2
//        bookmarkButtonLabel.anchor(top: bookmarkButton.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 1, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        bookmarkButtonLabel.centerXAnchor.constraint(equalTo: bookmarkButton.centerXAnchor).isActive = true
//        bookmarkButtonLabel.sizeToFit()
        


        listCount.anchor(top: listContainer.topAnchor, left: bookmarkButton.rightAnchor, bottom: listContainer.bottomAnchor, right: listContainer.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        listCount.centerYAnchor.constraint(equalTo: bookmarkButton.centerYAnchor).isActive = true
        
        listCount.sizeToFit()
        listCount.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleBookmark)))
        
//        followingListsLabel.anchor(top: listCount.bottomAnchor, left: bookmarkButton.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        followingListsLabel.sizeToFit()
        
//        followingListsLabel.anchor(top: listContainer.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        followingListsLabel.centerXAnchor.constraint(equalTo: listContainer.centerXAnchor).isActive = true
        
        
        scrollview.addSubview(listContainer)
        listContainer.anchor(top: bookmarkView.topAnchor, left: nil, bottom: bookmarkView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        listContainer.centerXAnchor.constraint(equalTo: bookmarkView.centerXAnchor).isActive = true
        
        
        // Message
        
//        messageContainer.addSubview(sendMessageButton)
//        messageContainer.addSubview(messageCount)
//
//        sendMessageButton.anchor(top: messageContainer.topAnchor, left: messageContainer.leftAnchor, bottom: messageContainer.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        sendMessageButton.widthAnchor.constraint(equalTo: sendMessageButton.heightAnchor, multiplier: 1).isActive = true
//
//        messageCount.anchor(top: messageContainer.topAnchor, left: sendMessageButton.rightAnchor, bottom: messageContainer.bottomAnchor, right: messageContainer.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 20, height: 20)
//        messageCount.centerYAnchor.constraint(equalTo: sendMessageButton.centerYAnchor).isActive = true
//
//        messageCount.text = "10"
//        messageCount.sizeToFit()
//
//        scrollview.addSubview(messageContainer)
//        messageContainer.anchor(top: messageView.topAnchor, left: nil, bottom: messageView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
//        messageContainer.centerXAnchor.constraint(equalTo: messageView.centerXAnchor).isActive = true
        
        // Format Action Buttons
        
        //        voteButton.setImage(post?.hasVoted == 1 ? #imageLiteral(resourceName: "cred_filled").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "cred_unfilled").withRenderingMode(.alwaysOriginal), for: .normal)
        
        likeButton.setImage(#imageLiteral(resourceName: "drool").alpha((post.hasLiked) ? 1 : 0.5).withRenderingMode(.alwaysOriginal), for: .normal)
        
        bookmarkButton.setImage(post.hasPinned ? #imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "bookmark_unfilled").withRenderingMode(.alwaysOriginal), for: .normal)
        
//        if (post.hasBookmarked) {
//            bookmarkButton.setImage(#imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal), for: .normal)
//        }
        
        commentButton.setImage(#imageLiteral(resourceName: "comment_gray").withRenderingMode(.alwaysOriginal), for: .normal)
        
        sendMessageButton.setImage(#imageLiteral(resourceName: "send_plane").withRenderingMode(.alwaysOriginal), for: .normal)

        
        //        listButton.backgroundColor = post?.hasBookmarked == true ? UIColor.white : UIColor.clear
        
        //        upVoteButton.setImage(post?.hasVoted == 1 ? #imageLiteral(resourceName: "upvote_selected").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "upvote").withRenderingMode(.alwaysOriginal), for: .normal)
        //
        //        downVoteButton.setImage(post?.hasVoted == -1 ? #imageLiteral(resourceName: "downvote_selected").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "downvote").withRenderingMode(.alwaysOriginal), for: .normal)
        //
        //        sendMessageButton.setImage(post?.hasMessaged == true ? #imageLiteral(resourceName: "message_fill").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "message_unfill").withRenderingMode(.alwaysOriginal), for: .normal)
        
        if post.creatorUID == Auth.auth().currentUser?.uid {
            optionsButton.isHidden = false
        } else {
            optionsButton.isHidden = true
        }
        
        // Dividers
        //
        //        let dividerColor = UIColor.lightGray
        //
        //        let div1 = UIView()
        //        div1.backgroundColor = dividerColor
        //        addSubview(div1)
        //        div1.anchor(top: actionStackView.topAnchor, left: commentView.leftAnchor, bottom: actionStackView.bottomAnchor, right: nil, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 1, height: 0)
        //        div1.heightAnchor.constraint(equalTo: actionStackView.heightAnchor, multiplier: 0.4).isActive = true
        //
        //        let div2 = UIView()
        //        div2.backgroundColor = dividerColor
        //        addSubview(div2)
        //        div2.anchor(top: actionStackView.topAnchor, left: bookmarkView.leftAnchor, bottom: actionStackView.bottomAnchor, right: nil, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 1, height: 0)
        //        div2.heightAnchor.constraint(equalTo: actionStackView.heightAnchor, multiplier: 0.4).isActive = true
        //
        //
        //        let div3 = UIView()
        //        div3.backgroundColor = dividerColor
        //        addSubview(div3)
        //        div3.anchor(top: actionStackView.topAnchor, left: messageView.leftAnchor, bottom: actionStackView.bottomAnchor, right: nil, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 1, height: 0)
        //        div3.heightAnchor.constraint(equalTo: actionStackView.heightAnchor, multiplier: 0.4).isActive = true
        //
        //
        
        //        for i in 1 ..< (actionStackView.arrangedSubviews.count - 1){
        //            let div = UIView()
        //            div.widthAnchor.constraint(equalToConstant: 1).isActive = true
        //            div.backgroundColor = .black
        //            addSubview(div)
        //            div.heightAnchor.constraint(equalTo: actionStackView.heightAnchor, multiplier: 0.4).isActive = true
        //            div.centerXAnchor.constraint(equalTo: actionStackView.arrangedSubviews[i].leftAnchor).isActive = true
        //            div.centerYAnchor.constraint(equalTo: actionStackView.centerYAnchor).isActive = true
        //        }
        
        
        
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    var originalImageCenter:CGPoint?
    
    @objc func pan(sender: UIPanGestureRecognizer) {
        if self.isZooming && sender.state == .began {
            self.originalImageCenter = sender.view?.center
        } else if self.isZooming && sender.state == .changed {
            let translation = sender.translation(in: self.view)
            if let view = sender.view {
                view.center = CGPoint(x:view.center.x + translation.x,
                                      y:view.center.y + translation.y)
            }
            sender.setTranslation(CGPoint.zero, in: self.photoImageScrollView.superview)
        }
    }
    
    @objc func pinch(sender:UIPinchGestureRecognizer) {
        
        if sender.state == .began {
            let currentScale = self.photoImageScrollView.frame.size.height / self.photoImageScrollView.bounds.size.height
            let newScale = currentScale*sender.scale
            self.view.bringSubviewToFront(self.photoImageScrollView)
            
            
            if newScale > 1 {
                self.isZooming = true
            }
            
        } else if sender.state == .changed {
            guard let view = sender.view else {return}
            let pinchCenter = CGPoint(x: sender.location(in: view).x - view.bounds.midX,
                                      y: sender.location(in: view).y - view.bounds.midY)
            let transform = view.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y)
                .scaledBy(x: sender.scale, y: sender.scale)
                .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
            
            let currentScale = self.photoImageScrollView.frame.size.height / self.photoImageScrollView.bounds.size.height
            var newScale = currentScale*sender.scale
            
            if newScale < 1 {
                newScale = 1
                let transform = CGAffineTransform(scaleX: newScale, y: newScale)
                self.photoImageScrollView.transform = transform
                sender.scale = 1
            }else {
                view.transform = transform
                sender.scale = 1
            }
            
        } else if sender.state == .ended || sender.state == .failed || sender.state == .cancelled {
            print("End Scaling")
            UIView.animate(withDuration: 0.3, animations: {
                self.photoImageScrollView.transform = CGAffineTransform.identity
                if let center = self.originalImageCenter {
                    self.photoImageScrollView.center = center
                }
            }, completion: { _ in
                self.isZooming = false
                self.view.bringSubviewToFront(self.captionView)
                self.view.bringSubviewToFront(self.photoCountLabel)
            })
        }
    }
    
    //    func pinch(sender:UIPinchGestureRecognizer) {
    //        if sender.state == .began {
    //            let currentScale = self.photoImageView.frame.size.width / self.photoImageView.bounds.size.width
    //            let newScale = currentScale*sender.scale
    //            if newScale > 1 {
    //                self.isZooming = true
    //            }
    //        } else if sender.state == .changed {
    //            guard let view = sender.view else {return}
    //            let pinchCenter = CGPoint(x: sender.location(in: view).x - view.bounds.midX,
    //                                      y: sender.location(in: view).y - view.bounds.midY)
    //            let transform = view.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y)
    //                .scaledBy(x: sender.scale, y: sender.scale)
    //                .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
    //            let currentScale = self.photoImageView.frame.size.width / self.photoImageView.bounds.size.width
    //            var newScale = currentScale*sender.scale
    //
    //            if newScale < 1 {
    //                newScale = 1
    //                let transform = CGAffineTransform(scaleX: newScale, y: newScale)
    //                self.photoImageView.transform = transform
    //                sender.scale = 1
    //            }else {
    //                view.transform = transform
    //                sender.scale = 1
    //            }
    //        } else if sender.state == .ended || sender.state == .failed || sender.state == .cancelled {
    //            guard let center = self.originalImageCenter else {return}
    //            UIView.animate(withDuration: 0.3, animations: {
    //                self.photoImageView.transform = CGAffineTransform.identity
    //                self.photoImageView.center = center
    //                //                self.superview?.bringSubview(toFront: self.photoImageView)
    //            }, completion: { _ in
    //                self.isZooming = false
    //            })
    //        }
    //    }
    
    
    
    
    
    //    func swipe(sender:UISwipeGestureRecognizer) {
    //
    //        guard let imageUrls = self.post?.imageUrls else {return}
    //
    //        switch sender.direction {
    //        case UISwipeGestureRecognizerDirection.left:
    //            if currentImage == (self.post?.imageCount)! - 1 {
    //                currentImage = 0
    //
    //            }else{
    //                currentImage += 1
    //            }
    //            photoImageView.loadImage(urlString: imageUrls[currentImage])
    //
    //        case UISwipeGestureRecognizerDirection.right:
    //            if currentImage == 0 {
    //                currentImage = (self.post?.imageCount)! - 1
    //            }else{
    //                currentImage -= 1
    //            }
    //            photoImageView.loadImage(urlString: imageUrls[currentImage])
    //        default:
    //            break
    //        }
    //
    //    }
    
    
    @objc func photoDoubleTapped(){
        print("Double Tap")
        self.handleLike()
        
        // Double Tap For Upvote - If Already Upvoted will change vote to 0. Upvote code handles it
        
        //        self.locationTap()
        
        
        //        self.handleLike()
        //        var origin: CGPoint = self.photoImageView.center;
        //        popView = UIView(frame: CGRect(x: origin.x, y: origin.y, width: 200, height: 200))
        //        popView = UIImageView(image: #imageLiteral(resourceName: "heart"))
        //        popView.contentMode = .scaleToFill
        //        popView.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
        //        popView.frame.origin.x = origin.x
        //        popView.frame.origin.y = origin.y * (1/3)
        //
        //        photoImageView.addSubview(popView)
        //
        //            UIView.animate(withDuration: 1.5,
        //                       delay: 0,
        //                       usingSpringWithDamping: 0.2,
        //                       initialSpringVelocity: 6.0,
        //                       options: .allowUserInteraction,
        //                       animations: { [weak self] in
        //                        self?.popView.transform = .identity
        //                }) { (done) in
        //                    self.popView.alpha = 0
        //                }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //        if self.post?.creatorListId != nil {
        //            return (self.post?.creatorListId?.count)!
        //        } else {return 0}
        if collectionView == creatorListCollectionView {
            return self.postCreatorListNames.count
        } else if collectionView == userListCollectionView {
            return self.postCurrentUserListNames.count
        } else {
            return 0
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ListDisplayCell
        
        var displayListName: String?
        var displayListId: String?
        
        if collectionView == creatorListCollectionView {
            displayListName = self.postCreatorListNames[indexPath.row]
            displayListId = self.postCreatorListIds[indexPath.row]
            cell.otherUser = !(self.post?.creatorUID == Auth.auth().currentUser?.uid)
            
        } else if collectionView == userListCollectionView {
            displayListName = self.postCurrentUserListNames[indexPath.row]
            displayListId = self.postCurrentUserListIds[indexPath.row]
            cell.otherUser = false
        }
        
        
        if self.post?.creatorUID == Auth.auth().currentUser?.uid {
            // Current User is Creator
            cell.otherUser = false
        } else if let creatorListIds = self.post?.creatorListId {
            // Current User is not Creator
            if creatorListIds[displayListId!] != nil {
                //Is Non-Current User Creator ID
                cell.otherUser = true
            } else {
                //Is Non-Current User Selected ID
                cell.otherUser = false
            }
        } else {
            cell.otherUser = false
        }
        
        cell.displayListName = displayListName
        cell.displayListId = displayListId
        cell.displayFont = 13
        
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == creatorListCollectionView {
            let displayListName = self.postCreatorListNames[indexPath.row]
            let displayListId = self.postCreatorListIds[indexPath.row]
            self.didTapExtraTag(tagName: displayListName, tagId: displayListId, post: self.post!)
            
        } else if collectionView == userListCollectionView {
            let displayListName = self.postCurrentUserListNames[indexPath.row]
            let displayListId = self.postCurrentUserListIds[indexPath.row]
            self.didTapExtraTag(tagName: displayListName, tagId: displayListId, post: self.post!)
        }
        
        
    }
    

    // HOME POST CELL DELEGATE METHODS
    
    func didTapUserUid(uid: String) {
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = uid
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func displayPostSocialUsers(post:Post, following: Bool){
        print("Display Vote Users| Following: ",following)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayUser = true
        postSocialController.displayUserFollowing = following
        postSocialController.inputPost = post
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    func displayPostSocialLists(post:Post, following: Bool){
        print("Display Lists| Following: ",following)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayList = true
        postSocialController.displayFollowing = following
        postSocialController.inputPost = post
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    func didTapBookmark(post: Post) {
        
        let sharePhotoListController = SharePhotoListController()
        sharePhotoListController.uploadPost = post
        sharePhotoListController.isBookmarkingPost = true
        sharePhotoListController.delegate = self
        navigationController?.pushViewController(sharePhotoListController, animated: true)
    }
    
    func didTapComment(post: Post) {
        
        let commentsController = CommentsController(collectionViewLayout: UICollectionViewFlowLayout())
        commentsController.post = post
        
        navigationController?.pushViewController(commentsController, animated: true)
    }
    
    func didTapUser(post: Post) {
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = post.user.uid
        
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapLocation(post: Post) {
        let locationController = LocationController()
        locationController.selectedPost = post
        navigationController?.pushViewController(locationController, animated: true)
    }
    
    func didTapExtraTag(tagName: String, tagId: String, post: Post) {
        
        // Check to see if its a list, price or something else
        if tagId == "price"{
            // Price Tag Selected
            print("Price Selected")
            // No Display
        }
        else if tagId == "creatorLists"{
            // Additional Tags
            let listController  = ListController()
            listController.displayedPost = post
            listController.displayedListNameDictionary = post.creatorListId
            self.navigationController?.pushViewController(listController, animated: true)
        }
        else if tagId == "userLists"{
            // Additional Tags
            let listController  = ListController()
            listController.displayedPost = post
            listController.displayedListNameDictionary = post.selectedListId
            self.navigationController?.pushViewController(listController, animated: true)
        }
        else {
            // List Tag Selected
            Database.checkUpdateListDetailsWithPost(listName: tagName, listId: tagId, post: post, completion: { (fetchedList) in
                if fetchedList == nil {
                    // List Does not Exist
                    self.alert(title: "List Error", message: "List Does Not Exist Anymore")
                } else {
                    let listViewController = ListViewController()
                    listViewController.currentDisplayList = fetchedList
                    self.navigationController?.pushViewController(listViewController, animated: true)
                }
            })
        }
    }
    
    func refreshPost(post: Post) {
        
        self.post = post
        postCache.removeValue(forKey: post.id!)
        postCache[post.id!] = post
//        self.collectionView?.reloadData()
    }
    
    
    func didTapMessage(post: Post) {
        
        let messageController = MessageController()
        messageController.post = post
        
        navigationController?.pushViewController(messageController, animated: true)
    }
    
    
    
    internal func didTapNavMessage() {
        
        let messageController = MessageController()
        messageController.post = post
        
        self.navigationController?.pushViewController(messageController, animated: true)
    }
    
    func userOptionPost(post:Post){
        
        let optionsAlert = UIAlertController(title: "User Options", message: "", preferredStyle: UIAlertController.Style.alert)
        
        optionsAlert.addAction(UIAlertAction(title: "Edit Post", style: .default, handler: { (action: UIAlertAction!) in
            // Allow Editing
            self.editPost(post: post)
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Delete Post", style: .default, handler: { (action: UIAlertAction!) in
            self.deletePost(post: post)
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        present(optionsAlert, animated: true, completion: nil)
    }
    
    func editPost(post:Post){
        let editPost = MultSharePhotoController()
        // Post Edit Inputs
        editPost.editPostInd = true
        editPost.editPost = post
        
        self.navigationController?.pushViewController(editPost, animated: true)
    }
    
    
    func deletePost(post:Post){
        
        let deleteAlert = UIAlertController(title: "Delete", message: "All data will be lost.", preferredStyle: UIAlertController.Style.alert)
        deleteAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            // Remove from Current View
            self.dismiss(animated: true, completion: nil)
            self.navigationController?.popToRootViewController(animated: true)
            Database.deletePost(post: post)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        present(deleteAlert, animated: true, completion: nil)
        
    }

    
    func displaySelectedEmoji(emoji: String, emojitag: String) {
        emojiDetailLabel.text = emoji + " " + emojitag
        emojiDetailLabel.isHidden = false
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

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUITextDirection(_ input: Int) -> UITextDirection {
	return UITextDirection(rawValue: input)
}


//    // LOCATION
//        scrollview.addSubview(locationView)
//        locationView.anchor(top: actionBar.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//
//
//        // Add Location Distance
//        scrollview.addSubview(locationDistanceLabel)
//        locationDistanceLabel.anchor(top: locationView.topAnchor, left: nil, bottom: nil, right: locationView.rightAnchor, paddingTop: 5, paddingLeft: 2, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
//        locationDistanceLabel.sizeToFit()
//        locationDistanceLabel.isUserInteractionEnabled = true
//        locationDistanceLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(activateMap)))
//
//        // Add Location Name
//        locationView.addSubview(locationNameLabel)
//        locationNameLabel.anchor(top: locationView.topAnchor, left: locationView.leftAnchor, bottom: locationView.bottomAnchor, right: nil, paddingTop: 3, paddingLeft: 10, paddingBottom: 3, paddingRight: 10, width: 0, height: 0)
//        locationNameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: self.view.frame.width * 2 / 3)
//
//        locationNameLabel.sizeToFit()
//        locationNameLabel.isUserInteractionEnabled = true
//        locationNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(locationTap)))

