//
//  NewLocationController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 12/3/20.
//  Copyright © 2020 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

import FBSDKLoginKit
import CoreLocation
import EmptyDataSet_Swift
import CoreGraphics
import SVProgressHUD
import FirebaseAuth
import FirebaseDatabase
import SKPhotoBrowser
import SwiftyJSON


private let reuseIdentifier = "Cell"

class NewLocationController: UICollectionViewController, UICollectionViewDelegateFlowLayout, LocationOptionsBarDelegate {

    
    var location: Location? {
        didSet {
            guard let coord = location?.locationGPS?.coordinate else {
                print("ERROR - No Location GPS - \(location?.locationName)")
                return
            }
            selectedLat = coord.latitude ?? 0
            selectedLong = coord.longitude ?? 0
            
            if let id = location?.locationGoogleID {
                if self.googlePlaceId == nil {
                    self.googlePlaceId = id
                }
                                
                if location?.googleJson?.count == 0 && self.googlePlaceId != nil {
                    Database.updateJsonForLocation(locId: id) { (json) in
                        print("Updating JSON for Location \(self.location?.locationName)")
                        self.location?.googleJson = json
                        self.googlePlaceJSON = json
                    }
                }
            }
            optionsBar.location = self.location
            optionsBar.locationJSON = self.location?.googleJson
//            collectionView.reloadData()
        }
    }
    
    var locationGPS: CLLocation? {
        didSet {
            guard let coord = locationGPS?.coordinate else {return}
            selectedLat = coord.latitude ?? 0
            selectedLong = coord.longitude ?? 0
        }
    }
    

    var googlePlaceId: String? = nil {
        didSet{
            if googlePlaceId != "" {
                if self.location == nil {
                    Database.fetchLocationWithLocID(locId: googlePlaceId ?? "") { (loc) in
                        print("FETCHED \(loc?.locationName) - \(self.googlePlaceId)")
                        self.location = loc
                    }
                }

                
//                Database.queryGooglePlaceID(placeId: googlePlaceId) { (json) in
//                    self.googlePlaceJSON = json
//                    if self.selectedLat == 0.0 && self.selectedLong == 0.0 {
//                        if let json = json {
//                            self.selectedLong = json["geometry"]["location"]["lng"].double ?? 0
//                            self.selectedLat = json["geometry"]["location"]["lat"].double ?? 0
//                        }
//                    }
//                }
            }
        }
    }
    
    var googlePlaceJSON: JSON? = nil {
        didSet {
            optionsBar.locationJSON = self.googlePlaceJSON

//            guard let googlePlaceJSON = googlePlaceJSON else {return}
//            self.collectionView.reloadData()
        }
    }
    var hasRestaurantLocation: Bool = false

    
    var selectedLong: Double? = 0
    var selectedLat: Double? = 0
    var selectedName: String?
    var selectedAdress: String?
    
    var locationRating: Double = 0.0
    
    // Filter Variables
    var viewFilter: Filter = Filter.init(defaultSort: defaultRecentSort) {
        didSet{
//            setupNavigationItems()
        }
    }
    
    let locationCellId = "locationCellID"
    let headerId = "headerId"
    let photoCellId = "photoCellId"
    let fullPhotoCellId = "fullPhotoCellId"
    let gridPhotoCellId = "gridPhotoCellId"
    let emptyCellId = "emptyCellId"
    
    var postFormatInd: Int = gridFormat {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    var allPosts: [Post] = []
    var friendPosts: [Post] = []
    var otherPosts: [Post] = []
    var displayedPosts: [Post] = []
    var filteredPosts: [Post] = []

    var allPostEmojiCounts:[String:Int] = [:]
    var friendPostemojiCounts:[String:Int] = [:]
    
    var isFilteringFriends: Bool = true
    var isFiltering: Bool = true

    
    let navBackButton = navBackButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
    let navMapButton = NavBarMapButton.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))

    var first100EmojiCounts: [String:Int] = [:]
    var noFilterTagCounts: PostTagCounts = PostTagCounts.init()
    var currentPostTagCounts: PostTagCounts = PostTagCounts.init()
    var currentPostRatingCounts = RatingCountArray
    let searchViewController = LegitSearchViewControllerNew()
    var tempSearchBarText: String? = nil
    
    let optionsBar = LocationOptionsBar()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(newLocationUpdate), name: MainTabBarController.newLocationUpdate, object: nil)

        
        setupNavigationItems()
        setupCollectionView()

        
        self.view.addSubview(optionsBar)
        optionsBar.anchor(top: nil, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 50)
        optionsBar.delegate = self
        optionsBar.location = self.location
        optionsBar.locationJSON = self.googlePlaceJSON
        
        
        self.view.addSubview(searchViewController.view)
//        searchViewController.view.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        searchViewController.view.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        searchViewController.view.alpha = 0
        setupSearchView()

        // Register cell classes
//        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }
    
    func newLocationUpdate() {
        print("New Location Update")
        guard let id = location?.locationGoogleID else {
            print("ERROR - No ID : newLocationUpdate")
            return
        }
        Database.fetchLocationWithLocID(locId: location?.locationGoogleID) { (location) in
            guard let location = location else {
                print("ERROR - No Location For \(id) : newLocationUpdate")
                return
            }
            self.location = location
        }
    }
    
    
    func setupSearchView() {
        searchViewController.delegate = self
        searchViewController.viewFilter = self.viewFilter
        searchViewController.noFilterTagCounts = self.noFilterTagCounts
        searchViewController.currentPostTagCounts = self.currentPostTagCounts
        searchViewController.currentRatingCounts = self.currentPostRatingCounts
        searchViewController.searchBar.text = ""
    }
    
    func setupNavigationItems() {
        let tempImage = UIImage.init(color: UIColor.backgroundGrayColor())
        navigationController?.navigationBar.setBackgroundImage(tempImage, for: .default)
        navigationController?.view.backgroundColor = UIColor.backgroundGrayColor()
        navigationController?.isNavigationBarHidden = false
        
        navigationController?.navigationBar.barTintColor = UIColor.ianWhiteColor()
        navigationController?.navigationBar.tintColor = UIColor.ianLegitColor()
        navigationController?.navigationBar.isTranslucent = false

        // REMOVES THE 1PX BOTTOM LINE IN NAV BAR
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
        
        self.navigationController?.navigationBar.layer.shadowColor = UIColor.gray.cgColor
        self.navigationController?.navigationBar.layer.shadowOffset = CGSize(width: 0.0, height: 1)
        self.navigationController?.navigationBar.layer.shadowRadius = 1.0
        self.navigationController?.navigationBar.layer.shadowOpacity = 0.5
        self.navigationController?.navigationBar.layer.masksToBounds = false
        
        // Nav Back Button
        navBackButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        let backButton = UIBarButtonItem.init(customView: navBackButton)
        self.navigationItem.leftBarButtonItem = backButton
        
        // Nav Map Button
        navMapButton.tintColor = UIColor.ianBlackColor()
        navMapButton.setTitleColor(UIColor.ianBlackColor(), for: .normal)
        navMapButton.setTitle(" Map ", for: .normal)
        navMapButton.addTarget(self, action: #selector(toggleMapFunction), for: .touchUpInside)
        let mapButton = UIBarButtonItem.init(customView: navMapButton)
        self.navigationItem.rightBarButtonItem = mapButton

    }
    
    func setupCollectionView() {
        let layout = HomeSortFilterHeaderFlowLayout()
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 5
        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.backgroundGrayColor()
        collectionView.register(NewLocationHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerId)
        collectionView.register(FullPictureCell.self, forCellWithReuseIdentifier: fullPhotoCellId)
        collectionView.register(EmptyCell.self, forCellWithReuseIdentifier: emptyCellId)
        collectionView.register(TestHomePhotoCell.self, forCellWithReuseIdentifier: gridPhotoCellId)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .onDrag
    }
    
    func handleRefresh() {
        self.clearAllPosts()
        self.fetchPostForPostLocation()
    }
    
    @objc func toggleMapFunction(){
        var tempFilter = self.viewFilter ?? Filter.init()
        tempFilter.filterLocation = self.location?.locationGPS
        appDelegateFilter = tempFilter
        self.toggleMapView()
    }
    
    
    func fetchPostForPostLocation(){
//        guard let location = self.location else {return}
        let placeId = self.googlePlaceId ?? ""
        self.clearAllPosts()
        
        if placeId != "" {
            self.fetchPostWithGooglePlaceID(googlePlaceID: placeId)
        } else if (self.selectedLat != 0 &&  self.selectedLong != 0) {
            self.fetchPostWithLocation(location: CLLocation(latitude: self.selectedLat!, longitude: self.selectedLong!))
        } else {
            self.alert(title: "Error", message: "Error Fetching Post based on this location")
        }
    }
    
    func fetchPostWithLocation(location: CLLocation){
        
        let rangeString: String? = self.viewFilter.filterRange ?? "0.025"
        var filterRange = 500.0
        
        if let temp = self.viewFilter.filterRange {
            filterRange = Double(temp)! * 1000
        }
        
        print("No Google Place ID. Searching Posts by Location: ", location)
        Database.fetchAllPostWithLocation(location: location, distance: filterRange) { (fetchedPosts, fetchedPostIds) in
            print("Fetched Post with Location: \(location) : \(fetchedPosts.count) Posts")
            self.allPosts = fetchedPosts
            self.averageRating(posts: self.allPosts)
            self.separatePosts()
        }

    }
    
    func fetchPostWithGooglePlaceID(googlePlaceID: String){
        print("Searching Posts by Google Place ID: ", googlePlaceID)
        Database.fetchAllPostWithGooglePlaceID(googlePlaceId: googlePlaceID) { (fetchedPosts, fetchedPostIds) in
            print("Fetching Post with googlePlaceId: \(googlePlaceID) : \(fetchedPosts.count) Posts")
            self.allPosts = fetchedPosts
            self.averageRating(posts: self.allPosts)
            self.separatePosts()
        }
    }
    
    func clearAllPosts(){
        self.allPosts.removeAll()
        self.friendPosts.removeAll()
        self.otherPosts.removeAll()
        self.allPostEmojiCounts.removeAll()
        self.friendPostemojiCounts.removeAll()
//        self.emojiArray.emojiLabels = []
    }
    
    func averageRating(posts: [Post]){
        var totalRating = 0.0
        var totalRatingCount = 0
        for post in posts {
            if (post.rating ?? 0) > 0.0 {
                totalRating += post.rating ?? 0
                totalRatingCount += 1
            }
        }
        self.locationRating = (totalRatingCount > 0) ? (totalRating/Double(totalRatingCount)) : 0
        self.location?.starRating = self.locationRating
    }
    
    
    func separatePosts(){
        self.friendPosts = self.allPosts.filter({ (post) -> Bool in
            return CurrentUser.followingUids.contains(post.creatorUID!) || (post.creatorUID == Auth.auth().currentUser?.uid)
        })
        self.otherPosts = self.allPosts.filter({ (post) -> Bool in
            return !CurrentUser.followingUids.contains(post.creatorUID!) && !(post.creatorUID == Auth.auth().currentUser?.uid)
        })
        
        Database.countEmojis(posts: self.allPosts, onlyEmojis: true) { (emoji_counts) in
            self.allPostEmojiCounts = emoji_counts
        }
        
        Database.countEmojis(posts: self.friendPosts, onlyEmojis: true) { (emoji_counts) in
            self.friendPostemojiCounts = emoji_counts
        }
        self.filterSortFetchedPosts()
    }
    
    func filterSortFetchedPosts(){
        
        // Filter Posts
        
        self.displayedPosts = isFilteringFriends ? self.friendPosts : self.otherPosts
        self.updateNoFilterCounts()

        // Not Filtering for Location and Range/Distances
        Database.filterPostsNew(inputPosts: self.displayedPosts, postFilter: self.viewFilter) { (filteredPosts) in
            Database.sortPosts(inputPosts: filteredPosts, selectedSort: self.viewFilter.filterSort, selectedLocation: self.viewFilter.filterLocation, completion: { (filteredPosts) in
                self.filteredPosts = filteredPosts ?? []
                print("  ~ Finish Filter and Sorting Post")
                self.collectionView.reloadData()
                self.collectionView.layoutIfNeeded()
            })
        }
        
    }
    
    func updateNoFilterCounts(){
        Database.summarizePostTags(posts: self.displayedPosts) { (tagCounts) in
            self.currentPostTagCounts = tagCounts
            if !self.viewFilter.isFiltering && !self.isFiltering {
                self.noFilterTagCounts = tagCounts
            }
//            print("   SingleUserProfileViewController | NoFilter Emoji Count | \(tagCounts) | \(self.displayedPosts.count) Posts")
//            self.refreshBottomEmojiBar()
        }
        
        let first100 = Array(self.displayedPosts.prefix(100))
        Database.countEmojis(posts: first100, onlyEmojis: true) { (emojiCounts) in
            self.first100EmojiCounts = emojiCounts
            print("   SingleUserProfileViewController | First 50 Emoji Count | \(emojiCounts.count) | \(first100.count) Posts")
//            self.refreshEmojiBar()
        }
        
        Database.summarizeRatings(posts: self.displayedPosts) { (ratingCounts) in
            self.currentPostRatingCounts = ratingCounts
        }
    }


    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    var showEmpty = false
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        self.showEmpty = (self.filteredPosts.count == 0 && self.isFiltering)
//        print("\(max(1, self.isFiltering ? self.filteredPosts.count : self.displayedPosts.count)) CELLS")
        return max(1, self.isFiltering ? self.filteredPosts.count : self.displayedPosts.count)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if (self.isFiltering ? self.filteredPosts.count : self.displayedPosts.count) == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emptyCellId, for: indexPath) as! EmptyCell
            cell.delegate = self
            return cell
        } else if self.postFormatInd == 0 {
            let tempPost = (self.isFiltering ? self.filteredPosts[indexPath.item] : self.displayedPosts[indexPath.item])

            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: gridPhotoCellId, for: indexPath) as! TestHomePhotoCell
            cell.delegate = self
            cell.showDistance = false
            cell.post = tempPost
            cell.enableCancel = false
            cell.showUserProfileImage = true
            cell.layer.cornerRadius = 1
            cell.layer.masksToBounds = true
            cell.layer.backgroundColor = UIColor.clear.cgColor
            cell.layer.shadowColor = UIColor.lightGray.cgColor
            cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            cell.layer.shadowRadius = 2.0
            cell.layer.shadowOpacity = 0.5
            cell.layer.masksToBounds = false
            cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: 14).cgPath
            return cell
        } else if self.postFormatInd == 1 {
            let tempPost = (self.isFiltering ? self.filteredPosts[indexPath.item] : self.displayedPosts[indexPath.item])
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: fullPhotoCellId, for: indexPath) as! FullPictureCell
            cell.post = tempPost
            cell.enableDelete = false
            cell.showDistance = false
            cell.delegate = self
            cell.currentImage = 1
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
            return cell

        }
    
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerId, for: indexPath) as! NewLocationHeader
        
        
        if indexPath.section == 0 {
//            header.location = self.location
            header.selectedLat = self.selectedLat
            header.selectedLong = self.selectedLong
            
            header.postFormatInd = self.postFormatInd
            header.isFilteringFriends = self.isFilteringFriends
            header.emojiCounts = self.allPostEmojiCounts
            header.postCount = self.isFiltering ? self.filteredPosts.count : self.displayedPosts.count
            header.locationRating = self.locationRating
            header.viewFilter = self.viewFilter

            header.location = self.location
            if self.location?.googleJson?.count == 0 && self.googlePlaceJSON != nil {
                header.googlePlaceJSON = self.googlePlaceJSON
            }
            
            header.refreshHeaderLabels()
            
            header.delegate = self

            // Labels get updated with JSON is put in
//            header.googlePlaceJSON = self.googlePlaceJSON


        }
        
        header.isHidden = !(indexPath.section == 0)
        
        
        return header
        
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        return CGSize(width: view.frame.width, height: 220)
        if section == 0 {
            // Get the view for the first header
            let indexPath = IndexPath(row: 0, section: section)
            let headerView = self.collectionView(collectionView, viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader, at: indexPath)

            // Use this view to calculate the optimal size based on the collection view's width
            return headerView.systemLayoutSizeFitting(CGSize(width: collectionView.frame.width, height: UIView.layoutFittingExpandedSize.height),
                                                      withHorizontalFittingPriority: .required, // Width is fixed
                                                      verticalFittingPriority: .fittingSizeLevel) // Height can be as large as needed
            
        } else {
            return CGSize.zero
        }

    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 15
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 15
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 15, bottom: 40, right: 15)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
            if self.showEmpty && self.isFiltering
            {
                return CGSize(width: view.frame.width, height: view.frame.width)
            }
            else if self.postFormatInd == 1 {
                var height: CGFloat = 35 //headerview = username userprofileimageview
                height += view.frame.width  // Picture
                height += 160
                height += 30
                height += 30 // Emoji Array + Star Rating
                //            height += 25    // Date Bar
                return CGSize(width: view.frame.width - 16, height: height)
            } else if self.postFormatInd == 0 {
                // GRID VIEW
//                let width = (view.frame.width - 2 - 30) / 2
//
//                return CGSize(width: width, height: width)
                
                let width = (view.frame.width - 30 - 15) / 2

                let height = (GridCellImageHeightMult * width + GridCellEmojiHeight)
                return CGSize(width: width, height: height)
                
            } else {
                return CGSize(width: view.frame.width, height: view.frame.width)
            }


    }
    
    

}

extension NewLocationController: EmptyCellDelegate, TestGridPhotoCellDelegate, FullPictureCellDelegate, SharePhotoListControllerDelegate, NewLocationHeaderDelegate, LegitSearchViewControllerDelegate  {
    func filterControllerSelected(filter: Filter?) {
        print("NewLocationController | Received Filter | \(filter?.searchTerms)")
        guard let filter = filter else {return}
        self.viewFilter = filter
        self.filterSortFetchedPosts()
    }
    
    func refreshAll() {
        self.handleRefresh()
    }
    

    
    func didTapLocationHours(hours: [JSON]?){
        print("LocationController | locationHoursIconTapped")

            let presentedViewController = LocationHoursViewController()
            presentedViewController.hours = hours
            presentedViewController.setupViews()
            presentedViewController.providesPresentationContextTransitionStyle = true
            presentedViewController.definesPresentationContext = true
            presentedViewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            presentedViewController.modalTransitionStyle = .crossDissolve
            presentedViewController.view.backgroundColor = UIColor.clear
            presentedViewController.view.layer.cornerRadius = 5
            presentedViewController.view.layer.masksToBounds = true
            presentedViewController.view.layer.borderColor = UIColor.lightGray.cgColor
            presentedViewController.view.layer.borderWidth = 1
            presentedViewController.view.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)


            //presentedViewController.view.backgroundColor = UIColor.init(white: 0.4, alpha: 0.8)
            self.present(presentedViewController, animated: true, completion: nil)
    }
    
    func didTapAddTag(addTag: String) {
        let tempAddTag = addTag.lowercased()
        var tempArray = self.viewFilter.filterCaptionArray
        
        if tempArray.count == 0 {
            tempArray.append(tempAddTag)
            print("\(tempAddTag) | Add To Search | \(tempArray)")
        } else if tempArray.contains(tempAddTag) {
            let oldCount = tempArray.count
            tempArray.removeAll { (text) -> Bool in
                text == tempAddTag
            }
            let dif = tempArray.count - oldCount
            print("\(tempAddTag) Exists | Remove \(dif) from Search | \(tempArray)")
        } else {
            tempArray.append(tempAddTag)
            print("\(tempAddTag) | Add To Search | \(tempArray)")
        }
        
        self.viewFilter.filterCaptionArray = tempArray
        self.filterSortFetchedPosts()
    }
    
    func didTapEmptyCell() {
        
    }
    
    func didTapPicture(post: Post) {
        self.extTapPicture(post: post)
    }
    
    func didTapListCancel(post: Post) {
        print("Function: \(#function), line: \(#line)")
    }
    
    func didTapUser(post: Post) {
        print("Function: \(#function), line: \(#line)")
        self.extTapUser(post: post)
    }
    
    func didTapBookmark(post: Post) {
        print("Function: \(#function), line: \(#line)")
        let sharePhotoListController = SharePhotoListController()
        sharePhotoListController.uploadPost = post
        sharePhotoListController.isBookmarkingPost = true
        sharePhotoListController.delegate = self
        navigationController?.pushViewController(sharePhotoListController, animated: true)
    }
    
    func didTapLike(post: Post) {
        print("Function: \(#function), line: \(#line)")
    }
    
    func didTapComment(post: Post) {
        print("Function: \(#function), line: \(#line)")
        self.extTapComment(post: post)
    }
    
    func didTapUserUid(uid: String) {
        print("Function: \(#function), line: \(#line)")
        self.extTapUser(userId: uid)
    }
    
    func didTapLocation(post: Post) {
        print("Function: \(#function), line: \(#line)")
        self.extTapLocation(post: post)
    }
    
    func didTapMessage(post: Post) {
        print("Function: \(#function), line: \(#line)")
        self.extTapMessage(post: post)
    }
    
    func refreshPost(post: Post) {
        print("Function: \(#function), line: \(#line)")
        if let displayIndex = allPosts.firstIndex(where: { (fetchedPost) -> Bool in
            fetchedPost.id == post.id })
        {
            allPosts[displayIndex] = post
            self.separatePosts()
        }
        
        // Update Cache
        let postId = post.id
        postCache[postId!] = post
    }
    
    func userOptionPost(post: Post) {
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
    
    func didTapExtraTag(tagName: String, tagId: String, post: Post) {
        print("Function: \(#function), line: \(#line)")
        guard let uid = Auth.auth().currentUser?.uid else {return}
        // List Tag Selected
        Database.checkUpdateListDetailsWithPost(listName: tagName, listId: tagId, post: post, completion: { (fetchedList) in
            guard let fetchedList = fetchedList else {
                self.alert(title: "List Display Error", message: "List Does Not Exist Anymore")
                return
            }
            
            if fetchedList.publicList == 0 && fetchedList.creatorUID != uid {
                self.alert(title: "List Display Error", message: "List Is Private")
            } else {
                self.extTapList(list: fetchedList)
            }
        })
    }
    
    func displayPostSocialUsers(post: Post, following: Bool) {
        self.extShowUserLikesForPost(inputPost: post, displayFollowing: following)
    }
    
    func displayPostSocialLists(post: Post, following: Bool) {
        self.extShowListsForPost(post: post, following: following)
    }
    
    func editPost(post:Post){
        let editPost = MultSharePhotoController()
        
        // Post Edit Inputs
        editPost.editPostInd = true
        editPost.editPost = post
        
        let navController = UINavigationController(rootViewController: editPost)
        self.present(navController, animated: false, completion: nil)
    }
    
    
    func deletePost(post:Post){
        
        let deleteAlert = UIAlertController(title: "Delete", message: "All data will be lost.", preferredStyle: UIAlertController.Style.alert)
        deleteAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            
            // Remove from Current View
            let index = self.allPosts.firstIndex { (filteredpost) -> Bool in
                filteredpost.id  == post.id
            }
            
            let filteredindexpath = IndexPath(row:index!, section: 0)
            self.allPosts.remove(at: index!)
            self.separatePosts()
            Database.deletePost(post: post)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        present(deleteAlert, animated: true, completion: nil)
        
    }
    
    func didChangeToPostView() {
        self.postFormatInd = postFormat
    }
    
    func didChangeToGridView() {
        self.postFormatInd = gridFormat
    }
    
    func didTapSearchButton() {
        print("Tap Search | \(self.displayedPosts.count) Tags | \(self.viewFilter.searchTerms)")
        searchViewController.delegate = self
        searchViewController.viewFilter = self.viewFilter

        searchViewController.noFilterTagCounts = self.noFilterTagCounts
        searchViewController.currentPostTagCounts = self.currentPostTagCounts
        searchViewController.currentRatingCounts = self.currentPostRatingCounts
        searchViewController.searchBar.text = ""
        
        searchViewController.viewWillAppear(true)

        UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.transitionCrossDissolve, animations:
            {
                self.searchViewController.presentView()
        }
            , completion: { (finished: Bool) in
        })
    }
    
    func didTapFilterFriends(filteringFriends: Bool) {
        self.isFilteringFriends = filteringFriends
        self.filterSortFetchedPosts()
    }

//    func didTapGoogleRatingButton() {
////        SVProgressHUD.
//        self.alert(title: "Google Rating", message: "\(self.selectedName) Google Rating Is \(tempText)")
//    }
    
}
