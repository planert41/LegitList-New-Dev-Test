//
//  PictureController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/19/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import mailgun

import Cosmos
import GeoFire
import CoreGraphics
import CoreLocation
import DropDown
import MessageUI
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import AudioToolbox


class SinglePostView: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, FullPostCellDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate, EmojiButtonArrayDelegate, SharePhotoListControllerDelegate, MFMessageComposeViewControllerDelegate, CommentsControllerDelegate, DiscoverListViewDelegate, LocationControllerViewDelegate, UploadPhotoListControllerDelegate{
    

    var delegate: SinglePostViewDelegate?
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
            
            var creatorName = ""
            if let cache = userCache[post?.creatorUID ?? ""] {
                creatorName = cache.username
            } else {
                creatorName = post?.creatorUID ?? ""
            }
            
            print(" ~~~ SINGLEPOSTVIEW | LOAD POST | ID: \((post?.id)!) | LOC: \((post?.locationName)!) | USER: \(creatorName)")
            
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
            setupEmojis()
            refreshListCollectionView()
            setupRatingLegitIcon()
            setupAttributedLocationName()
            setupPostDetails()
            setupComments()
            setupAttributedSocialCount()
            self.scrollview.contentSize = scrollview.intrinsicContentSize
            self.displayedListView.post = post
            print("Picture Controller | Showing \(post?.id)")
//            print("ScrollView Size | Content \(self.scrollview.contentSize) | Intrinsic \(scrollview.intrinsicContentSize)")
            
        }
    }
    
    let viewCommentLabel: PaddedUILabel = {
        let label = PaddedUILabel()
        label.layer.backgroundColor = UIColor.rgb(red: 249, green: 249, blue: 249).cgColor
        label.layer.cornerRadius = 2
        label.layer.borderColor = UIColor.lightGray.cgColor
        label.layer.borderWidth = 1
        label.layer.masksToBounds = true
        label.textColor = UIColor.ianLegitColor()
        label.font = UIFont(name: "Poppins-Bold", size: 12)
        label.textAlignment = NSTextAlignment.center
        label.text = "VIEW COMMENTS"
        label.isUserInteractionEnabled = true
        return label
    }()
    
    
    
    func setupComments(){
        guard let postId = self.post?.id else {return}

        Database.fetchCommentsForPostId(postId: postId) { (commentsFirebase) in
            print("SinglePostView | setupComments | \(commentsFirebase.count) Comments")
            self.comments = []
            self.comments += commentsFirebase
            self.refreshCommentStackView()
        }
    }
    
    func refreshCommentStackView(){
        let commentArray = [commentLabel1, commentLabel2, commentLabel3]
    // CLEAR ALL COMMENTS
        for label in commentArray {
            label.text = ""
            label.numberOfLines = 3
//            label.sizeToFit()
        }
        
        // SORT COMMENTS
        self.comments.sort(by: { (p1, p2) -> Bool in
            return p1.creationDate.compare(p2.creationDate) == .orderedAscending
        })
        
        // UPDATE COMMENT COUNT
        if self.post?.commentCount != self.comments.count {
            self.post?.commentCount = self.comments.count
            guard let post = self.post else {return}
            postCache[post.id!] = post
        }
//        self.commentCount.text = self.comments.count != 0 ? String(self.comments.count) + "  COMMENT" : " COMMENT"
//        self.commentCount.sizeToFit()
    
    // Fill with Comments
        for (index,label) in commentArray.enumerated() {
            if index < self.comments.count {
                
                let comment = self.comments[index]
                let username = comment.user.username
                let commentText = comment.text
                
                let attributedText = NSMutableAttributedString(string: username, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Poppins-Bold", size: 12)]))

                attributedText.append(NSAttributedString(string: " \(commentText)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Poppins-Regular", size: 12)])))
                
                label.attributedText = attributedText
                label.sizeToFit()
//                label.backgroundColor = UIColor.yellow
//                print("COMMENT \(index) | \(attributedText)")

            }
        }
        self.commentStackView.sizeToFit()
        
        if self.comments.count > 0 {
            var commentCount = max(0, self.comments.count - 3)
            var commentString = "VIEW \((commentCount == 0) ? "" : (String(commentCount) + " "))OTHER COMMENTS"
            self.viewCommentLabel.text = commentString
            hideCommentView?.isActive = false

        } else {
            self.viewCommentLabel.text = "+ COMMENT"
            hideCommentView?.isActive = true
        }
        self.viewCommentLabel.sizeToFit()
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
        
    // CLEAR CURRENT OBJECTS
        self.postCurrentUserListIds = []
        self.postCurrentUserListNames = []
        self.postCreatorListIds = []
        self.postCreatorListNames = []
    
    // CREATOR TAGGED LISTS
        if self.post?.creatorListId != nil {
            for (key,value) in (self.post?.creatorListId)! {
                    self.postCreatorListIds.append(key)
                    self.postCreatorListNames.append(value)
            }
        }
        
    // CURRENT USER TAGGED LISTS
        if self.post?.selectedListId != nil {
            for (key,value) in (self.post?.selectedListId)! {
                    self.postCurrentUserListIds.append(key)
                    self.postCurrentUserListNames.append(value)
            }
        }
        
    // FETCH DISPLAYED LIST
        if self.postCreatorListIds.count > 0 {
            let displayedListId = self.postCreatorListIds[0]
            Database.fetchListforSingleListId(listId: displayedListId, completion: { (list) in
                guard let list = list else {return}
                self.displayedList = list
            })
        } else if self.postCurrentUserListIds.count > 0 {
            let displayedListId = self.postCurrentUserListIds[0]
            Database.fetchListforSingleListId(listId: displayedListId, completion: { (list) in
                guard let list = list else {return}
                self.displayedList = list
            })
        } else {
            self.displayedList = nil
        }
        
        
        // HIDE LIST COLLECTIONVIEW IF NO LISTS
        self.displayedListContainer.isHidden = (self.postCreatorListNames.count == 0 && self.postCurrentUserListNames.count == 0)
        self.bottomLine.isHidden = (self.postCreatorListNames.count == 0 && self.postCurrentUserListNames.count == 0)
        self.moreWhiteSpace.isHidden = (self.postCreatorListNames.count == 0 && self.postCurrentUserListNames.count == 0)

        
        var tagCount: String = (self.postCreatorListNames.count < 4) ? "" : (String(self.postCreatorListNames.count - 3) + " ")
        self.userTaggedListCountLabel.isHidden = tagCount == ""
        self.userTaggedListCountLabel.text = "+ \(tagCount) LISTS"
        
        print("SinglePostView | refreshListCollectionView | \(self.postCreatorListNames.count) Lists")
        self.creatorListCollectionView.reloadData()
//        self.view.updateConstraintsIfNeeded()
//        self.view.layoutIfNeeded()
        
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
        self.extTapUser(post: post)
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


    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
        setupNavigationItems()
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
        
//        print("SinglePostView | viewDidLayoutSubviews | ScrollView Size ",scrollview.contentSize)
        //        print("PhotoImageView ", photoImageScrollView.contentSize)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        //        let tempImage = UIImage.init(color: UIColor.legitColor())
        //        self.navigationController?.navigationBar.setBackgroundImage(tempImage, for: .default)
        //        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.isNavigationBarHidden = false
        setupNavigationItems()

    }
    
    
    lazy var testMapButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage((#imageLiteral(resourceName: "google_color").resizeImageWith(newSize: CGSize(width: 25, height: 25))).withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(locationTap), for: .touchUpInside)
        
        button.layer.cornerRadius = 10
        button.setTitleColor(UIColor.selectedColor(), for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
//        button.setTitle(" Map ", for: .normal)
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
    
    lazy var navButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.layer.backgroundColor = UIColor.white.cgColor
        button.layer.cornerRadius = 2
        button.clipsToBounds = true
        button.titleLabel?.textColor = UIColor.ianLegitColor()
        button.tintColor = UIColor.ianLegitColor()
        button.titleLabel?.font = UIFont(font: .avenirNextBold, size: 12)
        button.contentHorizontalAlignment = .center
        button.contentEdgeInsets = UIEdgeInsets(top: 1, left: 2, bottom: 1, right: 2)
        return button
    }()
    
    lazy var navShareButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 30))
        button.layer.backgroundColor = UIColor.white.cgColor
//        button.layer.borderColor = UIColor.ianLegitColor().cgColor
        button.layer.borderColor = UIColor.legitColor().cgColor
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 2
        button.clipsToBounds = true
        button.contentHorizontalAlignment = .center
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        return button
    }()
    
//    lazy var navBackButton: UIButton = {
//        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//        button.layer.backgroundColor = UIColor.white.cgColor
//        button.layer.borderColor = UIColor.ianLegitColor().cgColor
//        button.layer.borderWidth = 0
//        button.layer.cornerRadius = 2
//        button.clipsToBounds = true
//        button.contentHorizontalAlignment = .center
//        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
//        return button
//    }()
    
//    func handleBack(){
//        self.navigationController?.popViewController(animated: true)
//    }
    
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
        
        let attributedSocialText = NSMutableAttributedString()

        if listCount > 0 {
            self.listAddedHideHeight?.isActive = false
        } else {
            self.listAddedHideHeight?.isActive = true
            return
        }
        
        // Will have only max of 2 names (YOU + Top Username)
        for (index, username) in usernames.enumerated() {
            var usernameString = username.capitalizingFirstLetter()
            if index == 0 {
                userString = usernameString
            } else {
                userString += ", \(usernameString)"
            }
        }
        
        if userCount > 0 {
            userString += " and \(userCount) friends"
        }
        
        let attributedUserText = NSAttributedString(string: userString, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 13),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.ianLegitColor()]))
        
        attributedSocialText.append(attributedUserText)
        
        
        let actionString = " bookmarked in \(listCount) lists"
        let attributedActionText = NSAttributedString(string: actionString, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 12),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray]))
        attributedSocialText.append(attributedActionText)
        
//        userString = userString.capitalizingFirstLetter()
        self.listAddedStatsLabel.attributedText = attributedSocialText
//        self.listAddedStatsLabel.text = userString
        self.listAddedStatsLabel.sizeToFit()
    }
    
    
    fileprivate func setupAttributedSocialCount(){
        
        guard let post = self.post else {return}
        displayNames = []
        displayNamesUid = [:]
        
        // Bookmark Counts
        
//        var totalUniqueListUsers = post.allList.countUniqueStringValues()
//        var totalUniqueListedByFollowers = post.followingList.countUniqueStringValues()

        // Following Users - Summarizes User Counts
        var followingUsers: [String: Int] = post.followingList.stringValueCounts()
        followingUsers.sorted(by: { $0.value > $1.value })
        
        // Remove Post Creator ID from following stats
        if let creatorIndex = followingUsers.index(forKey: post.creatorUID!) {
            followingUsers.remove(at: creatorIndex)
        }
        
        var tempFollowingLists = post.followingList.filter { (key, value) -> Bool in
            return value != post.creatorUID
        }
        var listByFollowersCount = tempFollowingLists.count + (post.selectedListId?.count ?? 0)
        var userString: [String] = []
        var otherUserCount = followingUsers.count ?? 0
        
        if self.post?.hasPinned ?? false {
            userString.append("You")
        }
        
        if followingUsers.count > 0 {
            let mostListFollowingUser1 = followingUsers.first?.key
            Database.fetchUserWithUID(uid: mostListFollowingUser1!) { (user) in
                
                if let username = user?.username {
                    userString.append(username)
                    otherUserCount += -1
                }
                self.updateSocialLabel(listCount: listByFollowersCount, userCount: otherUserCount, usernames: userString)
            }
        } else {
            self.updateSocialLabel(listCount: listByFollowersCount, userCount: otherUserCount, usernames: userString)
        }
        
        
        // ACTION BUTTON COUNTS
        
        // Button Counts
        
//        self.likeCount.text = post.likeCount != 0 ? String(post.likeCount) : ""
//        self.likeCount.sizeToFit()
//        self.likeButtonLabel.text = "LEGIT"

        self.likeButtonLabel.text = post.likeCount != 0 ? String(post.likeCount) + "  LEGIT" : " LEGIT"
//        self.likeCount.text?.append(" LEGIT")
        
// COMMENTS ARE UPDATED SEPARATELY
    
//        self.commentCount.text = post.commentCount != 0 ? String(post.commentCount) : ""
//        self.commentCount.text?.append(" Comments")
        self.commentCount.text = post.commentCount != 0 ? String(post.commentCount) + "  COMMENT" : " COMMENT"
        self.commentCount.sizeToFit()
        
        self.messageCount.text = post.messageCount > 0 ? String( post.messageCount) : ""
        self.messageCount.text?.append(" Messages")
        
        
//        self.bookmarkButtonLabel.text = "BOOKMARK"
//        self.listCount.text = (self.post?.allList.count ?? 0) > 0 ? String(self.post?.allList.count ?? 0) : ""
        let listAddedString = post.hasPinned ? "LIST TAGGED" : "TAG LIST"
        self.bookmarkButtonLabel.text = post.allList.count != 0 ? String(post.allList.count) + "  LISTS" : listAddedString
        self.listCount.sizeToFit()
        
        //        self.listCount.text?.append(" List")
        
        
        // Resizes bookmark label to fit new count
        bookmarkLabelConstraint?.constant = self.listCount.frame.size.width
        //        self.layoutIfNeeded()
        
    
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
        
        if let _ = postDateString {
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
                
                postDateString! += ", " + displayCityString
            }
            
            let attributedText = NSAttributedString(string: postDateString!, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 12),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.lightGray]))
            
            
            self.postDateLabel.attributedText = attributedText
            self.postDateLabel.sizeToFit()
        }

        
        locationDistanceLabel.text = SharedFunctions.formatDistance(inputDistance: post.distance)
//        locationDistanceLabel.adjustsFontSizeToFitWidth = true
        locationDistanceLabel.sizeToFit()
        
        // Set Up Caption
        
//        captionTextView.textContainer.maximumNumberOfLines = 0
        let captionFont = UIFont(name: "Poppins-Regular", size: 12)

//        let attributedTextCaption = NSMutableAttributedString(string: post.user.username, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
        
        
//        let attributedTextCaption.append(NSAttributedString(string: "\(post.caption)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 14)])))
        
        let attributedTextCaption = NSMutableAttributedString(string: "\(post.caption)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): captionFont]))

        
//        attributedTextCaption.append(NSAttributedString(string: "\n\n", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): captionFont])))
        
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
        
//        if let ratingEmoji = self.post?.ratingEmoji {
//            if extraRatingEmojis.contains(ratingEmoji) {
//                displayLocationName.append(" \(ratingEmoji)")
//            }
//        }
        
        let attributedTextCaption = NSMutableAttributedString(string: displayLocationName, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .avenirNextDemiBold, size: 18)]))
        
        
        let paragraphStyle = NSMutableParagraphStyle()
        
        // *** set LineSpacing property in points ***
        paragraphStyle.lineSpacing = 0 // Whatever line spacing you want in points
        
        // *** Apply attribute to string ***
        attributedTextCaption.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedTextCaption.length))
        
        // *** Set Attributed String to your label ***
//        self.locationNameLabel.attributedText = attributedTextCaption
        self.locationNameLabel.text = displayLocationName
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
        
        label.font = UIFont(name: "Poppins-Bold", size: 12)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.left
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
//        iv.settings.filledImage = #imageLiteral(resourceName: "star_rating_filled_mid").withRenderingMode(.alwaysOriginal)
//        iv.settings.emptyImage = #imageLiteral(resourceName: "star_rating_unfilled").withRenderingMode(.alwaysOriginal)
        iv.settings.filledImage = #imageLiteral(resourceName: "ian_fullstar").withRenderingMode(.alwaysTemplate)
        iv.settings.emptyImage = #imageLiteral(resourceName: "ian_emptystar").withRenderingMode(.alwaysTemplate)
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
    
    let ratingEmojiLabel: UILabel = {
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
        label.textColor = UIColor.ianBlueColor()
        label.textAlignment = NSTextAlignment.right
        return label
    }()
    
    let locationNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Poppins-Regular", size: 20)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.left
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.baselineAdjustment = .alignCenters
        return label
    }()
    
    let locationCityLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(font: .avenirNextRegular, size: 16)
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
        
        self.ratingEmojiLabel.text = self.post?.ratingEmoji ?? ""
        self.ratingEmojiLabel.sizeToFit()
        
    }
    
    // CAPTION
    
//    let captionTextView: UITextView = {
//        let tv = UITextView()
//        tv.isScrollEnabled = false
//        tv.textContainer.maximumNumberOfLines = 0
//        tv.textContainerInset = UIEdgeInsets.zero
//        tv.textContainer.lineBreakMode = .byTruncatingTail
//        tv.translatesAutoresizingMaskIntoConstraints = false
//        tv.isEditable = false
//        return tv
//    }()
    
    
    
    let captionTextView: UILabel = {
        let tv = UILabel()
        tv.numberOfLines = 0
//        tv.isScrollEnabled = false
//        tv.textContainer.maximumNumberOfLines = 0
//        tv.textContainerInset = UIEdgeInsets.zero
//        tv.textContainer.lineBreakMode = .byTruncatingTail
//        tv.translatesAutoresizingMaskIntoConstraints = false
//        tv.isEditable = false
        return tv
    }()
    
    func expandTextView(){
        guard let post = self.post else {return}
        captionViewHeightConstraint?.isActive = false
//        captionTextView.textContainer.maximumNumberOfLines = 0
        let captionFont = UIFont(name: "Poppins-Bold", size: 14)
        
        // Set Up Caption
        
        let attributedTextCaption = NSMutableAttributedString(string: post.user.username, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): captionFont]))
        
        attributedTextCaption.append(NSAttributedString(string: " \(post.caption)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): captionFont])))
        
        //        attributedTextCaption.append(NSAttributedString(string: "\n\n", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 4)]))
        
        self.captionTextView.attributedText = attributedTextCaption
        self.captionTextView.sizeToFit()
        
        
        
        //        self.delegate?.expandPost(post: post, newHeight: self.captionTextView.frame.height - captionViewHeight)
        //        print(self.captionTextView.frame.height, self.captionTextView.intrinsicContentSize)
        
    }
    
//    @objc func HandleTap(sender: UITapGestureRecognizer) {
//
//        let myTextView = sender.view as! UITextView //sender is TextView
//        let layoutManager = myTextView.layoutManager //Set layout manager
//
//        // location of tap in myTextView coordinates
//
//        var location = sender.location(in: myTextView)
//
//        if let tapPosition = captionTextView.closestPosition(to: location) {
//            if let textRange = captionTextView.tokenizer.rangeEnclosingPosition(tapPosition , with: .word, inDirection: convertToUITextDirection(1)) {
//                let tappedWord = captionTextView.text(in: textRange)
//                print("Word: \(tappedWord)" ?? "")
//                if tappedWord == post?.user.username.replacingOccurrences(of: "@", with: "") {
//                    self.didTapUser(post: self.post!)
//                } else {
//                    //                    self.expandTextView()
//                    self.handleComment()
//                    //                    self.delegate?.didTapComment(post: self.post!)
//                }
//            }
//        }
    
        //        To Detect if textview is truncated
        //        if textView.contentSize.height > textView.bounds.height
        
        
//    }
//
//    func word(atPosition: CGPoint) -> String? {
//        if let tapPosition = captionTextView.closestPosition(to: atPosition) {
//            if let textRange = captionTextView.tokenizer.rangeEnclosingPosition(tapPosition , with: .word, inDirection: convertToUITextDirection(1)) {
//                let tappedWord = captionTextView.text(in: textRange)
//                print("Word: \(tappedWord)" ?? "")
//                return tappedWord
//            }
//            return nil
//        }
//        return nil
//    }
    
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
    
    
    //  DATE
    
    let postDateLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.lightGray
        label.numberOfLines = 0
        return label
    }()
    
    //   OPTIONS
    
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
    
    // COMMENTS
    var comments = [Comment]()
    
    lazy var commentSummaryView = UIView()
    
    var commentLabel1 = PaddedUILabel()
    var commentLabel2 = PaddedUILabel()
    var commentLabel3 = PaddedUILabel()

    func refreshComments(comments: [Comment]) {
        print("SinglePostView | Refreshing Comments | \(comments.count) Comments")
        self.comments = comments
        self.refreshCommentStackView()
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
        cv.translatesAutoresizingMaskIntoConstraints = true
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = .white
        return cv
    }()
    
    let userTaggedListCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Poppins-Bold", size: 12)
        label.textColor = UIColor.ianLegitColor()
        label.textAlignment = NSTextAlignment.left
        return label
    }()
    
    func setupRatingLegitIcon(){
        
        if (self.post?.rating)! != 0 {
            self.starRating.rating = (self.post?.rating)!
            starRating.tintColor = starRating.rating >= 4 ? UIColor.ianLegitColor() : UIColor.selectedColor()
            self.starRatingHide?.isActive = false
            self.starRating.isHidden = false

        } else {
            self.starRatingHide?.isActive = true
            self.starRating.isHidden = true
        }
        
        var display = ""
        if let ratingEmoji = self.post?.ratingEmoji {
            display = ratingEmoji + " " + (extraRatingEmojisDic[ratingEmoji] ?? "").uppercased()
        }
        
        extraRatingEmojiLabel.text = display
        extraRatingEmojiLabel.font = UIFont(font: .avenirNextBold, size: 16)
        extraRatingEmojiLabel.textColor = UIColor.ianLegitColor()
        extraRatingEmojiLabel.isHidden = display == ""
        
    }
    
    func goToList(list: List?, filter: String?) {
        guard let list = list else {return}
        let listViewController = ListViewController()
        listViewController.currentDisplayList = list
        listViewController.viewFilter?.filterCaption = filter
        listViewController.refreshPostsForFilter()
        print("DiscoverController | goToList | \(list.name) | \(filter) | \(list.id)")
        self.navigationController?.pushViewController(listViewController, animated: true)
    }
    
    func goToPost(postId: String) {
        Database.fetchPostWithPostID(postId: postId) { (post, error) in
            if let error = error {
                print("goToPost \(error)")
            } else {
                let pictureController = SinglePostView()
                pictureController.post = post
                self.navigationController?.pushViewController(pictureController, animated: true)
            }
        }
    }
    
    func goToPost(postId: String, ref_listId: String?, ref_userId: String?) {
        
        Database.fetchPostWithPostID(postId: postId) { (post, error) in
            if let error = error {
                print("TabListViewController | goToPost \(error)")
            } else {
                guard let post = post else {
                    self.alert(title: "Sorry", message: "Post Does Not Exist Anymore 😭")
                    if let listId = ref_listId {
                        print("TabListViewController | No More Post. Refreshing List to Update | ",listId)
                        Database.refreshListItems(listId: listId)
                    }
                    return
                }
                let pictureController = SinglePostView()
                pictureController.post = post
                self.navigationController?.pushViewController(pictureController, animated: true)
            }
        }
    }
    
    
    func displayListFollowingUsers(list: List, following: Bool) {
        print("Display Users| Following: ",list.id)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayUser = true
        postSocialController.displayUserFollowing = false
        postSocialController.inputList = list
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    func showUserLists() {
        self.displayPostSocialLists(post: self.post!, following: false)
    }
    
    func refreshAll() {
        print("Refresh All")
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
    
    lazy var navBackButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        let icon = #imageLiteral(resourceName: "back_icon").withRenderingMode(.alwaysTemplate)

        button.setImage(icon, for: .normal)
        button.layer.backgroundColor = UIColor.white.cgColor
        button.layer.borderColor = UIColor.ianLegitColor().cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 2
        button.clipsToBounds = true
        button.contentHorizontalAlignment = .center
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        button.tintColor = UIColor.ianBlackColor()
        button.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
        return button
    }()
    
    func setupNavigationItems(){

        self.setNeedsStatusBarAppearanceUpdate()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.barTintColor = UIColor.clear
        self.navigationController?.navigationBar.tintColor = UIColor.clear
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()

        navShareButton.addTarget(self, action: #selector(showMessagingOptionsNav), for: .touchUpInside)
        let navShareTitle = NSAttributedString(string: " SHARE", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)])
        navShareButton.setAttributedTitle(navShareTitle, for: .normal)
//        navShareButton.setImage((#imageLiteral(resourceName: "message_fill").resizeImageWith(newSize: CGSize(width: 20, height: 20))).withRenderingMode(.alwaysTemplate), for: .normal)
        navShareButton.setImage(#imageLiteral(resourceName: "IanShareImage").withRenderingMode(.alwaysTemplate), for: .normal)

        navShareButton.tintColor = UIColor.ianBlackColor()
        navShareButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        navShareButton.sizeToFit()
        
        navBackButton.addTarget(self, action: #selector(handleBackPressNav), for: .touchUpInside)
//        navBackButton.setImage((#imageLiteral(resourceName: "navBackImage").resizeImageWith(newSize: CGSize(width: 15, height: 15))).withRenderingMode(.alwaysTemplate), for: .normal)
//        navBackButton.tintColor = UIColor.ianLegitColor()
//        let navBackTitle = NSAttributedString(string: " BACK ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 10)])
//        navBackButton.setAttributedTitle(navBackTitle, for: .normal)
//        navBackButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
//        navBackButton.sizeToFit()

        let barButton1 = UIBarButtonItem.init(customView: navShareButton)
        let barButton2 = UIBarButtonItem.init(customView: navBackButton)

        self.navigationItem.rightBarButtonItem = barButton1
        self.navigationItem.leftBarButtonItem = barButton2
    }
    
    let moreWhiteSpace = UIView()
    let bottomLine = UIView()
    let moreWhiteSpace2 = UIView()
    let bottomLine2 = UIView()
    
    var LocationChildContainer = UIView()
    
    var extraRatingEmojiLabel: LightPaddedUILabel = {
        let label = LightPaddedUILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:10)
        label.textColor = UIColor.lightLegitColor()
        label.textAlignment = NSTextAlignment.right
        label.isUserInteractionEnabled = true
        label.backgroundColor = UIColor.clear
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayExtraRatingInfo)))
        return label
    }()
    
    @objc func displayExtraRatingInfo(){
        extraRatingEmojiLabel.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.extraRatingEmojiLabel.transform = .identity
            },
                       completion: nil
        )
        
        self.alert(title: "Ratings Emojis", message: """
Rating Emojis help you describe your experience beyond just star ratings
🥇 : Best
💯 : 100%
🔥 : Fire
👌 : Legit
😍 : Awesome
😡 : Angry
💩 : Poop
""")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.view.layoutIfNeeded()
//        self.navigationController?.navigationBar.layoutIfNeeded()
        
        // INITT
        view.backgroundColor = UIColor.clear
        setupNavigationItems()
        
        scrollview.frame = view.frame
//        scrollview.contentSize = CGSize(width: view.frame.width, height: view.frame.height + 400)
        scrollview.contentSize = CGSize(width: view.frame.width, height: view.frame.height)
        view.addSubview(scrollview)
        scrollview.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
    // THIS CODE MAKES SCROLLVIEW GO ALL THE WAY TO THE TOP
        scrollview.contentInsetAdjustmentBehavior = .never
        scrollview.backgroundColor = UIColor.backgroundGrayColor()
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleBackPressNav))
        swipeRight.direction = .right
        self.scrollview.addGestureRecognizer(swipeRight)
        
        // IMAGE SCROLL VIEW
        scrollview.addSubview(photoImageScrollView)
        photoImageScrollView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.width)
        photoImageScrollView.anchor(top: scrollview.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        photoImageScrollView.heightAnchor.constraint(equalTo: photoImageScrollView.widthAnchor, multiplier: 1).isActive = true
        photoImageScrollView.isPagingEnabled = true
        photoImageScrollView.delegate = self
        setupPhotoImageScrollView()
    
        
    // IMAGE COUNT
        scrollview.addSubview(pageControl)
        pageControl.anchor(top: nil, left: nil, bottom: photoImageScrollView.bottomAnchor, right: view.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 100, height: 5)
        setupPageControl()
        
// ACTION BAR
        scrollview.addSubview(actionBar)
        actionBar.anchor(top: photoImageScrollView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        actionBar.backgroundColor = UIColor.white

        setupActionButtons()
        
        let whiteSpace = UIView()
        whiteSpace.backgroundColor = UIColor.rgb(red: 241, green: 241, blue: 241)
        scrollview.addSubview(whiteSpace)
        whiteSpace.anchor(top: actionBar.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 5)
//        whiteSpace.layer.applySketchShadow()

        
        scrollview.addSubview(listAddedStatsLabel)
        listAddedStatsLabel.anchor(top: whiteSpace.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 2, paddingLeft: 10, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        listAddedHideHeight = listAddedStatsLabel.heightAnchor.constraint(equalToConstant: 0)
        listAddedStatsLabel.isUserInteractionEnabled = true
        listAddedStatsLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayAllLists)))
        

        
// LOCATION NAME VIEW
        let locationView = UIView()
        scrollview.addSubview(locationView)
        locationView.anchor(top: listAddedStatsLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 50)
        
        // USER PROFILE
        scrollview.addSubview(userProfileImageView)
        userProfileImageView.anchor(top: nil, left: locationView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: profileImageSize, height: profileImageSize)
        userProfileImageView.centerYAnchor.constraint(equalTo: locationView.centerYAnchor).isActive = true
        userProfileImageView.layer.cornerRadius = profileImageSize/2
        userProfileImageView.layer.borderWidth = 2
        userProfileImageView.layer.borderColor = UIColor.white.cgColor
        
        userProfileImageView.isUserInteractionEnabled = true
        userProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(usernameTap)))
        


        
//    // RESTAURANT CITY
//        locationView.addSubview(locationCityLabel)
//        locationCityLabel.anchor(top: locationView.topAnchor, left: nil, bottom: locationView.bottomAnchor, right: locationView.rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
//        locationNameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: self.view.frame.width * 1 / 3).isActive = true
//        locationCityLabel.sizeToFit()
        
        
        // RESTAURANT NAME
        scrollview.addSubview(locationNameLabel)
        locationNameLabel.anchor(top: locationView.topAnchor, left: userProfileImageView.rightAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 2, paddingLeft: 10, paddingBottom: 2, paddingRight: 10, width: 0, height: 0)
//        locationNameLabel.rightAnchor.constraint(lessThanOrEqualTo: locationCityLabel.leftAnchor).isActive = true
        locationNameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: self.view.frame.width * 4 / 5).isActive = true
//        locationNameLabel.backgroundColor = UIColor.yellow
        locationNameLabel.sizeToFit()
        locationNameLabel.isUserInteractionEnabled = true
        locationNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(locationTap)))
        locationNameLabel.backgroundColor = UIColor.clear
        
        // USER NAME
        scrollview.addSubview(usernameLabel)
//        usernameLabel.anchor(top: nil, left: userProfileImageView.rightAnchor, bottom: locationView.bottomAnchor, right: nil, paddingTop: 3, paddingLeft: 10, paddingBottom: 1, paddingRight: 3, width: 0, height: 0)

        usernameLabel.anchor(top: locationNameLabel.bottomAnchor, left: userProfileImageView.rightAnchor, bottom: locationView.bottomAnchor, right: nil, paddingTop: 3, paddingLeft: 10, paddingBottom: 3, paddingRight: 3, width: 0, height: 0)
//        usernameLabel.rightAnchor.constraint(lessThanOrEqualTo: starRating.leftAnchor)
        usernameLabel.sizeToFit()

        // EMOJI ARRAY
        emojiArray.alignment = .right
        emojiArray.delegate = self
        scrollview.addSubview(emojiArray)
        //        emojiArray.anchor(top: nil, left: nil, bottom: nil, right: userProfileView.rightAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 0, height: 25)
        emojiArray.anchor(top: nil, left: nil, bottom: nil, right: locationView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 26)
        emojiArray.centerYAnchor.constraint(equalTo: usernameLabel.centerYAnchor).isActive = true

        
// USER PROFILE VIEW
        let userProfileView = UIView()
        scrollview.addSubview(userProfileView)
        userProfileView.anchor(top: locationView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 40)
//        userProfileView.backgroundColor = UIColor.yellow
        
    // USER NAME
//        scrollview.addSubview(usernameLabel)
//        usernameLabel.anchor(top: nil, left: userProfileView.leftAnchor, bottom: nil, right: nil, paddingTop: 2, paddingLeft: 10, paddingBottom: 2, paddingRight: 3, width: 0, height: 0)
//        usernameLabel.centerYAnchor.constraint(equalTo: userProfileView.centerYAnchor).isActive = true
//        usernameLabel.sizeToFit()
        

//        emojiArray.centerYAnchor.constraint(equalTo: userProfileView.centerYAnchor).isActive = true
        
    // RESTAURANT RATING
        scrollview.addSubview(starRating)
        starRating.anchor(top: userProfileView.topAnchor, left: userProfileView.leftAnchor, bottom: userProfileView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 10, paddingBottom: 10, paddingRight: 20, width: 0, height: 0)
        starRating.sizeToFit()
        starRatingHide = starRating.widthAnchor.constraint(equalToConstant: 0)
        
        scrollview.addSubview(extraRatingEmojiLabel)
        extraRatingEmojiLabel.anchor(top: nil, left: starRating.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        extraRatingEmojiLabel.centerYAnchor.constraint(equalTo: starRating.centerYAnchor).isActive = true
        extraRatingEmojiLabel.isUserInteractionEnabled = true
        extraRatingEmojiLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayExtraRatingInfo)))
        extraRatingEmojiLabel.isHidden = true
        
        
    // EMOJI DETAIL
        scrollview.addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top: nil, left: nil, bottom: photoImageScrollView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        emojiDetailLabel.sizeToFit()
        emojiDetailLabel.centerXAnchor.constraint(equalTo: photoImageScrollView.centerXAnchor).isActive = true
        emojiDetailLabel.alpha = 0
        
    // CAPTION
        scrollview.addSubview(captionTextView)
        captionTextView.anchor(top: userProfileView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 4, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        captionTextView.backgroundColor = UIColor.clear
        captionTextView.sizeToFit()
        captionTextView.isUserInteractionEnabled = true
//        captionTextView.backgroundColor = UIColor.yellow
        
//        let textViewTap = UITapGestureRecognizer(target: self, action: #selector(self.HandleTap(sender:)))
        let textViewTap = UITapGestureRecognizer(target: self, action: #selector(handleComment))

        textViewTap.delegate = self
        captionTextView.addGestureRecognizer(textViewTap)
        
        scrollview.addSubview(postDateLabel)
        postDateLabel.anchor(top: captionTextView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 0, width: 0, height: 15)
        postDateLabel.sizeToFit()
        
        
        
        // LOCATION DISTANCE
        scrollview.addSubview(locationDistanceLabel)
        locationDistanceLabel.anchor(top: nil, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 15)
        locationDistanceLabel.centerYAnchor.constraint(equalTo: postDateLabel.centerYAnchor).isActive = true
        locationDistanceLabel.isUserInteractionEnabled = true
        locationDistanceLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(activateMap)))
        
        scrollview.addSubview(optionsButton)
        optionsButton.anchor(top: postDateLabel.topAnchor, left: nil, bottom: nil, right: locationDistanceLabel.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 40, height: 15)
        //        optionsButton.widthAnchor.constraint(equalTo: optionsButton.heightAnchor).isActive = true
        optionsButton.centerYAnchor.constraint(equalTo: postDateLabel.centerYAnchor).isActive = true
        optionsButton.isHidden = true



        
// COMMENT VIEW
        
        let commentStackView = UIStackView(arrangedSubviews: [commentLabel1, commentLabel2, commentLabel3])
        commentStackView.distribution = .equalSpacing
        commentStackView.axis = .vertical
        scrollview.addSubview(commentStackView)
        commentStackView.anchor(top: postDateLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: view.frame.width - 20, height: 0)
//        commentStackView.layer.borderWidth = 3
//        commentStackView.layer.borderColor = UIColor.yellow.cgColor
//        commentStackView.backgroundColor = UIColor.white

        scrollview.addSubview(viewCommentLabel)
        viewCommentLabel.anchor(top: commentStackView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 3, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 35)
        viewCommentLabel.sizeToFit()
        viewCommentLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleComment)))
        hideCommentView = commentStackView.heightAnchor.constraint(equalToConstant: 15)
        self.refreshCommentStackView()

        moreWhiteSpace.backgroundColor = UIColor.rgb(red: 241, green: 241, blue: 241)
        scrollview.addSubview(moreWhiteSpace)
        moreWhiteSpace.anchor(top: viewCommentLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        
        
        bottomLine.backgroundColor = UIColor.ianLegitColor()
        scrollview.addSubview(bottomLine)
        bottomLine.anchor(top: nil, left: view.leftAnchor, bottom: moreWhiteSpace.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 3)
        
// LIST VIEW
        scrollview.addSubview(displayedListContainer)
        displayedListContainer.anchor(top: bottomLine.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        listView.backgroundColor = UIColor.rgb(red: 249, green: 249, blue: 249)
        displayedListHeight = displayedListContainer.heightAnchor.constraint(equalToConstant: 0)
        displayedListHeight?.isActive = true

        moreWhiteSpace2.backgroundColor = UIColor.clear
        scrollview.addSubview(moreWhiteSpace2)
        moreWhiteSpace2.anchor(top: displayedListContainer.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)

        
        
        bottomLine2.backgroundColor = UIColor.ianLegitColor()
        scrollview.addSubview(bottomLine2)
        bottomLine2.anchor(top: nil, left: view.leftAnchor, bottom: moreWhiteSpace2.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 3)
        
//        scrollview.addSubview(LocationChildContainer)
//        LocationChildContainer.anchor(top: bottomLine2.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        locationContainerHeight = LocationChildContainer.heightAnchor.constraint(equalToConstant: self.view.frame.height)
//        locationContainerHeight?.isActive = true

        // LOCATION VIEW
        locationViewController.showSelectedPostPicture = false
        locationViewController.selectedPost = self.post
        self.addChild(locationViewController)
        locationViewController.delegate = self
        scrollview.addSubview(locationViewController.view)
        locationViewController.view.anchor(top: bottomLine2.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        locationViewController.view.sizeToFit()
        locationViewController.scrollView.isScrollEnabled = false
        locationContainerHeight = locationViewController.view.heightAnchor.constraint(equalToConstant: self.view.frame.height)
        locationContainerHeight?.isActive = true
        
        setupCaptionBubble()

        let endWhiteSpace = UIView()
        endWhiteSpace.backgroundColor = UIColor.backgroundGrayColor()
        scrollview.addSubview(endWhiteSpace)
        endWhiteSpace.anchor(top: locationViewController.view.bottomAnchor, left: view.leftAnchor, bottom: scrollview.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
        
        
        //// RATING VIEW
        //        let ratingView = UIView()
        //        scrollview.addSubview(ratingView)
        //        ratingView.anchor(top: locationView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
        
        //        // RESTAURANT RATING
        //        scrollview.addSubview(starRating)
        //        starRating.anchor(top: nil, left: ratingView.leftAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 5, paddingBottom: 10, paddingRight: 10, width: 0, height: 0)
        //        starRating.centerYAnchor.constraint(equalTo: ratingView.centerYAnchor).isActive = true
        //        starRating.sizeToFit()
        //        starRatingHide = starRating.widthAnchor.constraint(equalToConstant: 0)
        //
        //        scrollview.addSubview(ratingEmojiLabel)
        //        ratingEmojiLabel.anchor(top: nil, left: starRating.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        //        ratingEmojiLabel.centerYAnchor.constraint(equalTo: ratingView.centerYAnchor).isActive = true
        //        ratingEmojiLabel.sizeToFit()
        //
        //        // USER PROFILE
        //        scrollview.addSubview(userProfileImageView)
        //        userProfileImageView.anchor(top: nil, left: ratingEmojiLabel.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: profileImageSize, height: profileImageSize)
        //        userProfileImageView.centerYAnchor.constraint(equalTo: ratingView.centerYAnchor).isActive = true
        //        userProfileImageView.layer.cornerRadius = profileImageSize/2
        //        userProfileImageView.layer.borderWidth = 2
        //        userProfileImageView.layer.borderColor = UIColor.white.cgColor
        //
        //        userProfileImageView.isUserInteractionEnabled = true
        //        userProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(usernameTap)))
        
//        let userListView = UIView()
//        scrollview.addSubview(userListView)
//        userListView.anchor(top: displayedListView.bottomAnchor, left: listView.leftAnchor, bottom: listView.bottomAnchor, right: listView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 0, height: 0)
////        userListView.backgroundColor = UIColor.rgb(red: 249, green: 249, blue: 249)
////        userListView.backgroundColor = UIColor.yellow
//
//
//        scrollview.addSubview(userTaggedListCountLabel)
//        userTaggedListCountLabel.anchor(top: nil, left: nil, bottom: nil, right: userListView.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
//        userTaggedListCountLabel.centerYAnchor.constraint(equalTo: userListView.centerYAnchor).isActive = true
//        userTaggedListCountLabel.sizeToFit()
//
//        setupListCollectionView()
//
//        scrollview.addSubview(creatorListCollectionView)
//        creatorListCollectionView.anchor(top: userListView.topAnchor, left: userListView.leftAnchor, bottom: userListView.bottomAnchor, right: userTaggedListCountLabel.leftAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
////        creatorListCollectionView.rightAnchor.constraint(lessThanOrEqualTo: userTaggedListCountLabel.leftAnchor).isActive = true
////        creatorListCollectionView.sizeToFit()
//        creatorListCollectionView.backgroundColor = UIColor.rgb(red: 249, green: 249, blue: 249)
//
//        DispatchQueue.main.async {
//            self.creatorListCollectionView.collectionViewLayout.invalidateLayout()
//        }

        
        
        // TEST
//        let testView = UIView()
//        testView.backgroundColor = UIColor.blue
//        scrollview.addSubview(testView)
//        testView.anchor(top: viewCommentLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 500)
        


        
        //        dropDownMenu.anchor(top: topLayoutGuide.bottomAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

    }
    
    func resizeContainer(size: CGFloat) {
//        print("resizeContainer | \(size)")
        locationContainerHeight?.constant = size
        self.view.layoutIfNeeded()
    }
    
    func resizeContainerRow(row: Int) {
        var size = self.view.bounds.height/2
        var cellHeight = self.view.frame.width / 2
        size += (row > 0) ? (70 + (CGFloat(row) * cellHeight)) : 0
        
        locationContainerHeight?.constant = size
//        print("resizeContainer | \(size) | \(row) Rows")

        self.view.layoutIfNeeded()
    }
    
    
    func setupDisplayedListView(){
        displayedListContainer.addSubview(displayedListView)
        displayedListView.anchor(top: displayedListContainer.topAnchor, left: displayedListContainer.leftAnchor, bottom: displayedListContainer.bottomAnchor, right: displayedListContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        displayedListView.delegate = self
        displayedListView.backgroundColor = UIColor.white
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
        
    }
    
    var pageControl : UIPageControl = UIPageControl()
    
    
    func setupPageControl(){
        self.pageControl.numberOfPages = (self.post?.imageCount)!
        self.pageControl.currentPage = 0
        self.pageControl.tintColor = UIColor.red
        self.pageControl.pageIndicatorTintColor = UIColor.white
        self.pageControl.currentPageIndicatorTintColor = UIColor.ianLegitColor()
        self.pageControl.isHidden = self.pageControl.numberOfPages == 1
//        self.pageControl.backgroundColor = UIColor.rgb(red: 68, green: 68, blue: 68)
    }
    
    func testprint(){
        print("test")
    }
    
    
    
    func setupListCollectionView(){
//        let layout = UICollectionViewFlowLayout()
//        layout.minimumInteritemSpacing = 5
//        layout.estimatedItemSize = CGSize(width: 20, height: 20)
//        layout.sectionInset = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)

        let layout = ListDisplayFlowLayoutCopy()
        creatorListCollectionView.collectionViewLayout = layout
        creatorListCollectionView.backgroundColor = UIColor.clear
        creatorListCollectionView.isScrollEnabled = true
        creatorListCollectionView.showsHorizontalScrollIndicator = false
        creatorListCollectionView.register(ListDisplayCell.self, forCellWithReuseIdentifier: cellId)

        //        creatorListCollectionView.semanticContentAttribute = UISemanticContentAttribute.forceRightToLeft
        
    }
    
    
    let displayedListContainer = UIView()
    let displayedListView = DiscoverListView()
    var displayedList: List? = nil {
        didSet {
            guard let displayedList = displayedList else {return}

            print("SinglePostView | Loading Displayed List | \(displayedList.name)")
            displayedListHeight?.constant = (displayedList == nil) ? 0 : 190
//            self.displayedListView.isHidden = displayedList == nil
            self.displayedListView.list = displayedList
            self.displayedListView.refUser = CurrentUser.user
            self.setupDisplayedListView()
        }
    }
    var displayedListHeight: NSLayoutConstraint?
    var locationContainerHeight: NSLayoutConstraint?

    
    let listViewBackgroundColor = UIColor.lightSelectedColor()
    var listAddedHideHeight: NSLayoutConstraint?
    
    
    let locationViewController = LocationController()
//    let locationViewController = ArchiveLocationController()

    
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
        
        scrollview.addSubview(captionView)
        captionView.anchor(top: nil, left: view.leftAnchor, bottom: photoImageScrollView.bottomAnchor, right: view.rightAnchor, paddingTop: 30, paddingLeft: 50, paddingBottom: 40, paddingRight: 50, width: 0, height: 0)
        captionView.bottomAnchor.constraint(lessThanOrEqualTo: photoImageScrollView.bottomAnchor).isActive = true
        
        scrollview.addSubview(captionBubble)
        captionBubble.anchor(top: captionView.topAnchor, left: captionView.leftAnchor, bottom: captionView.bottomAnchor, right: captionView.rightAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 0, height: 0)
        captionBubble.contentMode = .center
    
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
    var hideCommentView: NSLayoutConstraint? = nil

    
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
        label.font = UIFont.boldSystemFont(ofSize:12)
        label.textColor = UIColor.ianLegitColor()
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
//        self.displayPostSocialLists(post: self.post!, following: displayFollowing)
        self.displayPostSocialLists(post: self.post!, following: false)

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
    
    let likeButtonLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(name: "Poppins-Bold", size: 12)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.center
        label.isUserInteractionEnabled = true
        return label
    }()
    
    
    lazy var commentButtonLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(name: "Poppins-Bold", size: 12)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.center
        label.isUserInteractionEnabled = true
        return label
    }()
    
    lazy var bookmarkButtonLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(name: "Poppins-Bold", size: 12)
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
    
//    override open func sizeThatFits(_ size: CGSize) -> CGSize {
//        super.sizeThatFits(size)
//        guard let window = UIApplication.shared.keyWindow else {
//            return super.sizeThatFits(size)
//        }
//        var sizeThatFits = super.sizeThatFits(size)
//        sizeThatFits.height = window.safeAreaInsets.bottom + 40
    //        return sizeT@objc hatFits
//    }
    
    
    @objc func handleLike() {
        //      delegate?.didLike(for: self)
        
        guard let postId = self.post?.id else {return}
        guard let creatorId = self.post?.creatorUID else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        // Animates before database function is complete
        
        Database.handleLike(post: self.post) { post in
            self.post = post
            self.setupAttributedSocialCount()
            self.delegate?.refreshPost(post: self.post!)
            
            var likeImage = (self.post?.hasLiked)! ? #imageLiteral(resourceName: "like_filled") : #imageLiteral(resourceName: "like_unfilled")
            self.likeButton.setImage(likeImage.withRenderingMode(.alwaysOriginal), for: .normal)
            self.likeButtonLabel.textColor = (self.post?.hasLiked)! ? UIColor.ianLegitColor() : UIColor.darkGray
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
    //            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                AudioServicesPlaySystemSound(1520)
                var origin: CGPoint = self.photoImageScrollView.center;
                self.popView = UIView(frame: CGRect(x: origin.x, y: origin.y, width: 100, height: 100))
    //            popView = UIImageView(image: #imageLiteral(resourceName: "like_filled").resizeImageWith(newSize: CGSize(width: 100, height: 100)).withRenderingMode(.alwaysOriginal))
                self.popView = UIImageView(image: #imageLiteral(resourceName: "like_filled_vector").withRenderingMode(.alwaysOriginal))


                self.popView.contentMode = .scaleToFill
                self.popView.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
                self.popView.frame.origin.x = origin.x
                self.popView.frame.origin.y = origin.y * 0.5
                
                self.photoImageView.addSubview(self.popView)
                self.popView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 100, height: 100)
                self.popView.centerXAnchor.constraint(equalTo: self.photoImageScrollView.centerXAnchor).isActive = true
                self.popView.centerYAnchor.constraint(equalTo: self.photoImageScrollView.centerYAnchor, constant: 0).isActive = true
                self.popView.isHidden = false

    //            popView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 100, height: 100)
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
                    self.popView.isHidden = true
                }
                
                let when = DispatchTime.now() + 2
                DispatchQueue.main.asyncAfter(deadline: when) {
                    self.popView.removeFromSuperview()
                    self.popView.alpha = 0
                    self.popView.isHidden = true
                }
            }
        }
        
    }
    
    
    // Bookmark
    let listIcon = #imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate)
    
    lazy var bookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(listIcon, for: .normal)
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
    
    
//    @objc func showMessagingOptions(){
//        let optionsAlert = UIAlertController(title: "Share Options", message: "", preferredStyle: UIAlertController.Style.alert)
//
//        optionsAlert.addAction(UIAlertAction(title: "iMessage", style: .default, handler: { (action: UIAlertAction!) in
//            // Allow Editing
//            self.handleIMessage()
//        }))
//
//        optionsAlert.addAction(UIAlertAction(title: "Email", style: .default, handler: { (action: UIAlertAction!) in
//            self.handleMessage()
//        }))
//
//        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
//            print("Handle Cancel Logic here")
//        }))
//
//        present(optionsAlert, animated: true) {
//            optionsAlert.view.superview?.isUserInteractionEnabled = true
//            optionsAlert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.alertClose(gesture:))))
//        }
//
//    }
//
//
//    func handleShare(format: String) {
//        if format ==  emailMessage {
//            self.handleMessage()
//        } else if format == iMessage {
//            self.handleIMessage()
//        }
//    }
//
//    func handleIMessage(){
//        if MFMessageComposeViewController.canSendText() == true {
//            let recipients:[String] = []
//            let messageController = MFMessageComposeViewController()
//            guard let post = post else {return}
//            guard let coord = post.locationGPS?.coordinate else {return}
//            let url = "http://maps.apple.com/maps?saddr=\(coord.latitude),\(coord.longitude)"
//            let convoString = post.locationName + " " + post.emoji + "\n" + post.locationAdress + " \n" + post.caption
//            //+ "\n" + "- @\(post.user.username)"
//
//            messageController.messageComposeDelegate = self
//            messageController.recipients = []
//            messageController.body = convoString
//
//            let sentImageUrl = self.post?.imageUrls[0] ?? ""
//            if let image = imageCache[sentImageUrl] {
//                let png = image.pngData()
//                messageController.addAttachmentData(png!, typeIdentifier: "public.png", filename: "image.png")
//            }
//
//
//            //                String(format: "http://maps.google.com/?saddr=%1.6f,%1.6f", arguments: [coord.latitude, coord.longitude])
//
//            //            let urlAttached = messageController.addAttachmentURL(URL(string: url)!, withAlternateFilename: nil)
//            //            print(urlAttached)
//
//
//
//
//
//
//            //            let url = URL(fileURLWithPath: sentImageUrl)
//            //
//            //            messageController.addAttachmentURL(url, withAlternateFilename: "Test")
//            //            messageController.addAttachmentURL(self.locationVCardURLFromCoordinate(coordinate: CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude))! as URL, withAlternateFilename: "vCard.loc.vcf")
//
//
//
//            self.present(messageController, animated: true, completion: nil)
//            print("IMessage")
//        } else {
//            self.alert(title: "ERROR", message: "Text Not Supported")
//        }
//
//    }
//
//    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
//        switch (result) {
//        case .cancelled:
//            print("Message was cancelled")
//            dismiss(animated: true, completion: nil)
//        case .failed:
//            print("Message failed")
//            dismiss(animated: true, completion: nil)
//        case .sent:
//            print("Message was sent")
//            dismiss(animated: true, completion: nil)
//        default:
//            break
//        }
//    }
    
    // Send Message
    
    lazy var sendMessageButton: UIButton = {
        let button = UIButton(type: .system)
        //        button.setImage(#imageLiteral(resourceName: "message").withRenderingMode(.alwaysOriginal), for: .normal)
        button.setImage(#imageLiteral(resourceName: "send_plane").withRenderingMode(.alwaysOriginal), for: .normal)
        
        button.addTarget(self, action: #selector(showMessagingOptionsNav), for: .touchUpInside)
        return button
        
    }()
    
    @objc func showMessagingOptionsNav(){
        guard let post = self.post else {return}
        self.showMessagingOptions(post: post)
    }
    
    @objc func handleBackPressNav(){
        guard let post = self.post else {return}
        self.handleBack()
    }
    
    func handleMessage(){
        guard let post = post else {return}
        self.didTapMessage(post: post)
    }
    
    
    let postCountColor = UIColor.darkGray
    
    let listCount: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(name: "Poppins-Bold", size: 12)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.right
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let messageCount: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(name: "Poppins-Bold", size: 12)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.left
        return label
    }()
    
    let commentCount: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(name: "Poppins-Bold", size: 12)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.left
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let likeCount: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(name: "Poppins-Bold", size: 12)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.center
        label.isUserInteractionEnabled = true
        return label
    }()
    
    
    let commentStackView = UIStackView()
    
    fileprivate func setupActionButtons() {
        
        guard let post = post else {return}
        
        let voteView = UIView()
        voteView.backgroundColor = UIColor.white
        
        let commentView = UIView()
        commentView.backgroundColor = UIColor.white
        
        let bookmarkView = UIView()
        bookmarkView.backgroundColor = UIColor.white
        
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
        actionStackView.backgroundColor = UIColor.white
        
        // Cred
        likeContainer.addSubview(likeButton)
        likeContainer.addSubview(likeButtonLabel)
//        likeContainer.addSubview(likeCount)
        //        credView.backgroundColor = UIColor.init(hex: "009688")
        
        //        credView.backgroundColor = UIColor.init(hex: "#26A69A")
        voteView.backgroundColor = UIColor.clear
        
//        likeCount.anchor(top: nil, left: likeContainer.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        likeCount.centerYAnchor.constraint(equalTo: likeContainer.centerYAnchor).isActive = true
        
        likeButton.anchor(top: likeContainer.topAnchor, left: likeContainer.leftAnchor, bottom: likeContainer.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        likeButton.widthAnchor.constraint(equalTo: likeButton.heightAnchor, multiplier: 1).isActive = true
//        likeButton.centerYAnchor.constraint(equalTo: likeCount.centerYAnchor).isActive = true

        //        likeButtonLabel.anchor(top: likeButton.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 1, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        //        likeButtonLabel.centerXAnchor.constraint(equalTo: likeButton.centerXAnchor).isActive = true
        //        likeButtonLabel.sizeToFit()
        
        
        likeButtonLabel.anchor(top: likeContainer.topAnchor, left: likeButton.rightAnchor, bottom: likeContainer.bottomAnchor, right: likeContainer.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        likeButtonLabel.centerYAnchor.constraint(equalTo: likeButton.centerYAnchor).isActive = true
        likeButtonLabel.sizeToFit()
        likeButtonLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleLike)))
        
        
        scrollview.addSubview(likeContainer)
        likeContainer.anchor(top: voteView.topAnchor, left: nil, bottom: voteView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        likeButtonLabel.leftAnchor.constraint(equalTo: voteView.centerXAnchor).isActive = true
//        likeContainer.centerXAnchor.constraint(equalTo: voteView.centerXAnchor).isActive = true
        likeContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleLike)))
        // Comments
        
        commentContainer.addSubview(commentButton)
        commentContainer.addSubview(commentCount)
        commentContainer.addSubview(commentButtonLabel)
        
        commentView.backgroundColor = UIColor.clear
        
        commentButton.anchor(top: commentContainer.topAnchor, left: commentContainer.leftAnchor, bottom: commentContainer.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        commentButton.widthAnchor.constraint(equalTo: commentButton.heightAnchor, multiplier: 1).isActive = true
        commentButton.centerYAnchor.constraint(equalTo: commentContainer.centerYAnchor).isActive = true

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
        commentContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleComment)))

        // Bookmarks
        
        listContainer.addSubview(bookmarkButton)
        listContainer.addSubview(listCount)
        listContainer.addSubview(bookmarkButtonLabel)
        
        bookmarkView.backgroundColor = UIColor.clear
        
        listCount.anchor(top: nil, left: listContainer.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        listCount.centerYAnchor.constraint(equalTo: listContainer.centerYAnchor).isActive = true
        
        bookmarkButton.anchor(top: listContainer.topAnchor, left: listCount.rightAnchor, bottom: listContainer.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        bookmarkButton.widthAnchor.constraint(equalTo: bookmarkButton.heightAnchor, multiplier: 1).isActive = true
        bookmarkButton.layer.cornerRadius = bookmarkButton.bounds.size.width/2
        //        bookmarkButtonLabel.anchor(top: bookmarkButton.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 1, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        //        bookmarkButtonLabel.centerXAnchor.constraint(equalTo: bookmarkButton.centerXAnchor).isActive = true
        //        bookmarkButtonLabel.sizeToFit()
        
        
        
        bookmarkButtonLabel.anchor(top: listContainer.topAnchor, left: bookmarkButton.rightAnchor, bottom: listContainer.bottomAnchor, right: listContainer.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        bookmarkButtonLabel.centerYAnchor.constraint(equalTo: bookmarkButton.centerYAnchor).isActive = true
        
        bookmarkButtonLabel.sizeToFit()
        bookmarkButtonLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleBookmark)))
        
        //        followingListsLabel.anchor(top: listCount.bottomAnchor, left: bookmarkButton.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        //        followingListsLabel.sizeToFit()
        
        //        followingListsLabel.anchor(top: listContainer.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        //        followingListsLabel.centerXAnchor.constraint(equalTo: listContainer.centerXAnchor).isActive = true
        
        
        scrollview.addSubview(listContainer)
        listContainer.anchor(top: bookmarkView.topAnchor, left: nil, bottom: bookmarkView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        bookmarkButtonLabel.leftAnchor.constraint(equalTo: bookmarkView.centerXAnchor).isActive = true
//        listContainer.centerXAnchor.constraint(equalTo: bookmarkView.centerXAnchor).isActive = true
        listContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleBookmark)))

        
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
        
        var likeImage = (post.hasLiked) ? #imageLiteral(resourceName: "like_filled") : #imageLiteral(resourceName: "like_unfilled")
        self.likeButton.setImage(likeImage.withRenderingMode(.alwaysOriginal), for: .normal)
        
//        bookmarkButton.setImage(post.hasPinned ? #imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "bookmark_unfilled").withRenderingMode(.alwaysOriginal), for: .normal)
//        bookmarkButton.setImage(post.hasPinned ? #imageLiteral(resourceName: "list_tab_fill").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "hashtag_unfill").withRenderingMode(.alwaysOriginal), for: .normal)
        bookmarkButton.tintColor = post.hasPinned ? UIColor.ianLegitColor() : UIColor.lightGray
        
        //        if (post.hasBookmarked) {
        //            bookmarkButton.setImage(#imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal), for: .normal)
        //        }
        
        commentButton.setImage(#imageLiteral(resourceName: "comment_icon_ian").withRenderingMode(.alwaysOriginal), for: .normal)
        
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

        if collectionView == creatorListCollectionView {
            return self.postCreatorListNames.count
        } else {
            return 0
        }

//        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ListDisplayCell
        
        var displayListName: String?
        var displayListId: String?
        
        if collectionView == creatorListCollectionView {
            displayListName = self.postCreatorListNames[indexPath.row]
            displayListId = self.postCreatorListIds[indexPath.row]
            cell.otherUser = !(self.post?.creatorUID == Auth.auth().currentUser?.uid)
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
//        self.creatorListCollectionView.sizeToFit()
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == creatorListCollectionView {
            let displayListName = self.postCreatorListNames[indexPath.row]
            let displayListId = self.postCreatorListIds[indexPath.row]
            self.didTapExtraTag(tagName: displayListName, tagId: displayListId, post: self.post!)
        }
    }
    
    
    // HOME POST CELL DELEGATE METHODS
    
    func didTapUserUid(uid: String) {
        self.extTapUserUid(uid: uid, displayBack: true)
//        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
//        userProfileController.displayUserId = uid
//        navigationController?.pushViewController(userProfileController, animated: true)
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
        print("Display Lists| Following: \(following) | Post: \(post.id)")
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayList = true
        postSocialController.displayFollowing = following
        postSocialController.inputPost = post
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    func didTapBookmark(post: Post) {
        
        let sharePhotoListController = UploadPhotoListController()
        sharePhotoListController.uploadPost = post
        sharePhotoListController.isBookmarkingPost = true
        sharePhotoListController.delegate = self
        
//        self.present(sharePhotoListController, animated: true, completion: nil)

        
        navigationController?.pushViewController(sharePhotoListController, animated: true)
    }
    
    func didTapComment(post: Post) {
        
        let commentsController = CommentsController(collectionViewLayout: UICollectionViewFlowLayout())
        commentsController.post = post
        commentsController.delegate = self
        
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
                    let listViewController = LegitListViewController()
                    listViewController.currentDisplayList = fetchedList
                    listViewController.refreshPostsForFilter()
                    
//                    let listViewController = ListViewController()
//                    listViewController.currentDisplayList = fetchedList
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
        let editPost = UploadPhotoController()
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
