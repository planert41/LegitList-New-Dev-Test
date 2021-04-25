////
////  MapViewController.swift
////  ShoutaroundTest
////
////  Created by Wei Zou Ang on 1/29/18.
////  Copyright © 2018 Wei Zou Ang. All rights reserved.
////
//
//import Foundation
//import UIKit
//import GoogleMaps
//
//import GeoFire
//import GooglePlaces
//import Alamofire
//import SwiftyJSON
//
//
//class MapViewPaginateController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, GMSMapViewDelegate, ListPhotoCellDelegate, GridPhotoCellDelegate, ListHeaderDelegate, FilterControllerDelegate, UINavigationControllerDelegate {
//    func didTapBookmark(post: Post) {
//        
//    }
//    
//    
//    var paginatePostsCount: Int = 0
//    var isFinishedPaging = false {
//        didSet{
//            if isFinishedPaging == true {
//                print("Paging Finish: \(self.isFinishedPaging), \(self.paginatePostsCount) Posts")
//            }
//        }
//    }
//    static let finishMapPaginationNotificationName = NSNotification.Name(rawValue: "FinishMapPagination")
//
//    
//    var scrolltoFirst: Bool = false
//    var fetchedPostIds: [PostId] = [] {
//        didSet{
//            self.fetchAllPosts()
//        }
//    }
//    var fetchedPosts: [Post] = []
//    
//    var selectedLocation: CLLocation? = nil
//    var selectedPostID: String? = nil {
//        didSet{
//            //            print("Selected Post ID: \(self.selectedPostID)")
//            guard let _ = selectedPostID else {
//                print("No Selected Post ID")
//                return
//            }
//            
//            // Color Marker on Map
//            // remove color from currently selected marker
//            if let currentMarker = self.map?.selectedMarker {
//                currentMarker.icon = GMSMarker.markerImage(with: nil)
//            }
//            
//            // select new marker and make green
//            if let newMarker = self.allMarkers.first(where: { (mark) -> Bool in
//                self.selectedPostID! == (mark.userData ?? "") as! String
//            }){
//                self.map?.selectedMarker = newMarker
//                newMarker.icon = GMSMarker.markerImage(with: UIColor.legitColor())
//            }
//            
//            // Map Goes to Selected Location
//            if let selectedPost = self.fetchedPosts.first(where: { (post) -> Bool in
//                post.id == selectedPostID
//            }) {
//                print("Post Selected. goToMap \(selectedPost.locationName) : \(selectedPost.locationGPS)")
//                self.goToMap(location: selectedPost.locationGPS)
//            } else {
//                print("Can't Find Marker for \(selectedPostID)")
//            }
//            
//            
//        }
//    }
//    
//    // Map Displays
//    var placesClient: GMSPlacesClient!
//    var marker = GMSMarker()
//    var allMarkers = [GMSMarker()]
//    var map: GMSMapView?
//    let cameraZoom = 13 as Float
//    let mapBackgroundView = UIView()
//    var initLocation: CLLocation?
//    
//    // CollectionView
//    let listCellId = "bookmarkCellId"
//    let gridCellId = "gridCellId"
//    let listHeaderId = "listHeaderId"
//    
//    lazy var collectionView : UICollectionView = {
//        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: FixedHeadersCollectionViewFlowLayout())
//        cv.translatesAutoresizingMaskIntoConstraints = false
//        cv.delegate = self
//        cv.dataSource = self
//        cv.backgroundColor = .white
//        return cv
//    }()
//    var collectionViewHeight:NSLayoutConstraint?
//    var expandCollectionView: Bool = false {
//        didSet{
//            self.updateCollectionViewHeight()
//        }
//    }
//    var isListView: Bool = true
//    
//    func updateCollectionViewHeight(){
//        if expandCollectionView && self.collectionViewHeight?.constant != 400{
//            UIView.animate(withDuration: 0, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
//                self.collectionViewHeight?.constant = 400
//                self.collectionView.layoutIfNeeded()
//            })
//            
//            //            collectionViewHeight?.constant = 400
//        } else if !expandCollectionView && self.collectionViewHeight?.constant == 400  {
//            UIView.animate(withDuration: 0, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
//                self.collectionViewHeight?.constant = 160
//                self.collectionView.layoutIfNeeded()
//            })
//            //            collectionViewHeight?.constant = 160
//        }
//    }
//    
//    // Filtering Variables
//    
//    var isFiltering: Bool = false
//    var filterCaption: String? = nil
//    var filterRange: String? = nil
//    var filterLocation: CLLocation? = CurrentUser.currentLocation
//    var filterLocationName: String? = nil
//    var filterGoogleLocationID: String? = nil
//    var filterMinRating: Double = 0
//    var filterType: String? = nil
//    var filterMaxPrice: String? = nil
//    var filterLegit: Bool = false
//    
//    // Header Sort Variables
//    // Default Sort is Nearest Place
//    var selectedHeaderSort:String? = defaultNearestSort
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        self.view.backgroundColor = UIColor.white
//        print("INIT MAP VIEW")
//        setupNavigationItems()
//        navigationController?.delegate = self
//        NotificationCenter.default.addObserver(self, selector: #selector(finishPaginationCheck), name: MapViewPaginateController.finishMapPaginationNotificationName, object: nil)
//
//        
//        
//        view.addSubview(mapBackgroundView)
//        mapBackgroundView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        mapBackgroundView.heightAnchor.constraint(equalTo: mapBackgroundView.widthAnchor).isActive = true
//        
//        let bottomDivider = UIView()
//        view.addSubview(bottomDivider)
//        bottomDivider.backgroundColor = UIColor.legitColor()
//        bottomDivider.anchor(top: mapBackgroundView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
//        
//        //        if CurrentUser.currentLocation == nil {
//        //            print("Map View, No Current User Location, Fetching Location")
//        //            LocationSingleton.sharedInstance.determineCurrentLocation()
//        //            let when = DispatchTime.now() + defaultGeoWaitTime // change 2 to desired number of seconds
//        //            DispatchQueue.main.asyncAfter(deadline: when) {
//        //                //Delay for 1 second to find current location
//        //                self.filterLocation = CurrentUser.currentLocation
//        //                self.setupMapView()
//        //            }
//        //        } else {
//        //            self.setupMapView()
//        //        }
//        
//        setupCollectionView()
//        view.addSubview(collectionView)
//        collectionView.anchor(top: mapBackgroundView.bottomAnchor, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        collectionViewHeight = collectionView.heightAnchor.constraint(equalToConstant: 160)
//        collectionViewHeight?.isActive = true
//        self.scrolltoFirst = false
//        
//    }
//    
//    
//    
//    func setupNavigationItems(){
////        navigationItem.title = currentDisplayList?.name
//    }
//    
//    
//    func setupMapView(){
//        self.clearMap()
//        print("Setting Up Map")
//        
//        if self.initLocation != nil {
//            let initcam = GMSCameraPosition.camera(withLatitude: (initLocation?.coordinate.latitude)!, longitude: (initLocation?.coordinate.longitude)!, zoom: cameraZoom)
//            map = GMSMapView.map(withFrame: CGRect.zero, camera: initcam)
//        } else {
//            map = GMSMapView(frame: CGRect.zero)
//        }
//        map?.mapType = .normal
//        map?.isMyLocationEnabled = true
//        map?.delegate = self
//        map?.settings.myLocationButton = true
//        //        map?.settings.zoomGestures = true
//        //        map?.settings.scrollGestures = true
//        map?.settings.setAllGesturesEnabled(true)
//        //        print("Map Init: Location: \(camera)")
//        
//        if CurrentUser.currentLocation != nil {
//            self.goToMap(location: CurrentUser.currentLocation)
//        } else {
//            LocationSingleton.sharedInstance.determineCurrentLocation()
//            let when = DispatchTime.now() + defaultGeoWaitTime // change 2 to desired number of seconds
//            DispatchQueue.main.asyncAfter(deadline: when) {
//                //Delay for 1 second to find current location
//                self.filterLocation = CurrentUser.currentLocation
//                self.goToMap(location: CurrentUser.currentLocation)
//            }
//        }
//        
//        self.view.addSubview(map!)
//        map?.anchor(top: mapBackgroundView.topAnchor, left: mapBackgroundView.leftAnchor, bottom: mapBackgroundView.bottomAnchor, right: mapBackgroundView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        
//    }
//    
//    
//    
//    
//    func setupCollectionView(){
//        collectionView.register(ListPhotoCell.self, forCellWithReuseIdentifier: listCellId)
//        collectionView.register(GridPhotoCell.self, forCellWithReuseIdentifier: gridCellId)
//        collectionView.register(ListViewHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: listHeaderId)
//        
//        collectionView.backgroundColor = .white
//        collectionView.allowsMultipleSelection = false
//        
//        let refreshControl = UIRefreshControl()
//        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
//        collectionView.refreshControl = refreshControl
//        collectionView.alwaysBounceVertical = true
//        collectionView.keyboardDismissMode = .onDrag
//    }
//    
//    var initview = 0
//    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        if self.initview == 0 && self.collectionView.visibleCells.count > 0 {
//            self.scrollToPost(postId: self.selectedPostID)
//            self.initview = 1
//            print("Layout subview scroll")
//        }
//    }
//    
//    
//    func fetchAllPosts(){
//        print("Fetching All Post, Current User Location: ", CurrentUser.currentLocation?.coordinate)
//        Database.fetchAllPosts(fetchedPostIds: self.fetchedPostIds){fetchedPostsFirebase in
//            self.fetchedPosts = fetchedPostsFirebase
//            print("fetchAllPosts SUCCESS | \(self.fetchedPosts.count) Posts")
//            // Update Post Distances
//            self.updatePostDistances(refLocation: self.filterLocation, completion: {
//                self.filterSortFetchedPosts()
//            })
//            guard let uid = Auth.auth().currentUser?.uid else {
//                print("Count Most Used Emoji: Error, No uid")
//                return
//            }
//            
//        }
//    }
//    
//    func updatePostDistances(refLocation: CLLocation?, completion:() -> ()){
//        if let refLocation = refLocation {
//            let count = fetchedPosts.count
//            for i in 0 ..< count {
//                var tempPost = fetchedPosts[i]
//                if let _ = tempPost.locationGPS {
//                    tempPost.distance = Double((tempPost.locationGPS?.distance(from: refLocation))!)
//                } else {
//                    tempPost.distance = nil
//                }
//                fetchedPosts[i] = tempPost
//            }
//            print("Complete Update Post Distances")
//            completion()
//        } else {
//            print("No Filter Location")
//            completion()
//        }
//    }
//    
//    
//    func filterSortFetchedPosts(){
//        
//        self.checkFilter()
//        // Filter Posts
//        Database.filterPosts(inputPosts: self.fetchedPosts, filterCaption: self.filterCaption, filterRange: self.filterRange, filterLocation: self.filterLocation, filterGoogleLocationID: filterGoogleLocationID, filterMinRating: self.filterMinRating, filterType: self.filterType, filterMaxPrice: self.filterMaxPrice, filterLegit: self.filterLegit, filterList: nil, filterUser: nil) { (filteredPosts) in
//            
//            // Sort Recent Post By Listed Date
//            var listSort: String = "Listed"
//            if self.selectedHeaderSort == defaultRecentSort {
//                listSort = "Listed"
//            } else {
//                listSort = self.selectedHeaderSort!
//            }
//            
//            Database.sortPosts(inputPosts: filteredPosts, selectedSort: listSort, selectedLocation: self.filterLocation, completion: { (filteredPosts) in
//                
//                self.fetchedPosts = []
//                if filteredPosts != nil {
//                    self.fetchedPosts = filteredPosts!
//                }
//                print("Finish Filter and Sorting Post")
//                
////                self.selectedPostID = self.selectedPostID == nil ? self.fetchedPosts[0].id : self.selectedPostID
//                
////                print("Post Sort - Selected Nearest Post: \(self.fetchedPosts[0].locationName)")
//                
//                self.addMarkers()
//                self.paginatePosts()
//                self.collectionView.reloadData()
//                
//            })
//        }
//    }
//    
//    func refreshPagination(){
//        self.isFinishedPaging = false
//        self.paginatePostsCount = 0
//    }
//    
//    func refreshPostsForFilter(){
//        self.checkFilter()
//        self.clearAllPost()
//        self.scrolltoFirst = true
//        self.selectedPostID = nil
//        self.fetchAllPosts()
//    }
//    
//    func handleRefresh(){
//        print("Refresh List")
//        self.clearAllPost()
//        self.clearFilter()
//        self.refreshPagination()
//        self.fetchAllPosts()
//        self.selectedPostID = nil
//        self.collectionView.refreshControl?.endRefreshing()
//    }
//    
//    func clearAllPost(){
//        self.fetchedPosts = []
//    }
//
//    
//    func checkFilter(){
//        if self.filterCaption != nil || (self.filterRange != nil) || (self.filterMinRating != 0) || (self.filterType != nil) || (self.filterMaxPrice != nil) || (self.filterLegit != false){
//            self.isFiltering = true
//        } else {
//            self.isFiltering = false
//        }
//    }
//    
//    func clearFilter(){
//        self.filterLocation = nil
//        self.filterLocationName = nil
//        self.filterRange = nil
//        self.filterGoogleLocationID = nil
//        self.filterMinRating = 0
//        self.filterType = nil
//        self.filterMaxPrice = nil
//        self.selectedHeaderSort = defaultRecentSort
//        self.isFiltering = false
//        self.filterCaption = nil
//        self.filterLegit = false
//    }
//    
//    func clearMarkers(){
//        for mark in self.allMarkers {
//            mark.map = nil
//        }
//        self.allMarkers.removeAll()
//    }
//    
//    func clearMap(){
//        map?.clear()
//        map?.stopRendering()
//        map?.removeFromSuperview()
//        map?.delegate = nil
//        map = nil
//        clearMarkers()
//    }
//    
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        // Helps with Memory usage for Map View
//        clearMap()
//    }
//    
//    override func viewWillAppear(_ animated: Bool) {
//        if map == nil {
//            self.setupMapView()
//            self.addMarkers()
//        }
//        
//    }
//    
//    // Collection View Expand Shrink
//    
//    //    func mapView(_ mapView: GMSMapView, didTap overlay: GMSOverlay) {
//    //        // Shrink Collection View
//    //        self.expandCollectionView = false
//    //    }
//    
//    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
//        // Shrink Collection View
//        if self.expandCollectionView != false {
//            self.expandCollectionView = false
//        }
//    }
//    
//    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
//        self.expandCollectionView = false
//    }
//    
//    var pointNow: CGPoint?
//    
//    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
//        pointNow = scrollView.contentOffset;
//    }
//    
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        guard let pointNow = pointNow else {return}
//        
//        if (scrollView.contentOffset.y<pointNow.y) {
//            //Scroll Down
//        } else if (scrollView.contentOffset.y>pointNow.y) {
//            // Scroll Up
//            self.expandCollectionView = true
//        }
//    }
//    
//    // Map Functions
//    func addMarkers() {
//        
//        self.clearMarkers()
//        print("Add Markers To Map: \(self.fetchedPosts.count) ")
//        
//        for post in self.fetchedPosts {
//            
//            let postUID: String = post.id!
//            let postLocation: CLLocation = post.locationGPS!
//            
//            let marker = GMSMarker()
//            //            print("Marker Coordinate: \(postLocation)")
//            marker.position = CLLocationCoordinate2D(latitude: postLocation.coordinate.latitude, longitude: postLocation.coordinate.longitude)
//            marker.userData = postUID
//            marker.title = post.locationName
//            marker.snippet = post.nonRatingEmoji.joined()
//            marker.isTappable = true
//            marker.map = self.map
//            marker.tracksViewChanges = false
//            marker.isDraggable = false
//            self.allMarkers.append(marker)
//            
//            if post.id == self.selectedPostID {
//                self.map?.selectedMarker = marker
//                marker.icon = GMSMarker.markerImage(with: UIColor.legitColor())
//                print("Add Markers - Selected Marker as \(post.id) \(post.locationGPS)")
//                
//                if let selectedPost = self.fetchedPosts.first(where: { (post) -> Bool in
//                    post.id == selectedPostID }) {
//                    print("Add Markers - Going to \(selectedPost.locationName) : \(selectedPost.locationGPS)")
//                    self.goToMap(location: selectedPost.locationGPS)}
//                else {
//                    print("Add Markers - Can't Find Location")
//                }
//            }
//        }
//    }
//    
//    func goToMap(location: CLLocation?){
//        guard let location = location else{
//            print("Go To Map View: ERROR, No Location")
//            return
//        }
//        
//        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: cameraZoom)
//        //        print("Camera: \(camera)")
//        let moveUpdate = GMSCameraUpdate.setCamera(camera)
//        self.map?.moveCamera(moveUpdate)
//        
//    }
//    
//    
//    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
//        
//        //        self.selectedPostID = marker.userData as! String
//        if let index = self.fetchedPosts.index(where: { (post) -> Bool in
//            return post.id == marker.userData as! String
//        }){
//            
//            if index > self.paginatePostsCount {
//                // Load posts until index
////                self.paginatePostsCount == index
////                self.collectionView.reloadData()
////                let indexpath = IndexPath(row:index, section: 0)
////                self.collectionView(self.collectionView, didSelectItemAt: indexpath)
//            } else {
//                // Scroll to Tapped Post
//                let indexpath = IndexPath(row:index, section: 0)
//                self.collectionView(self.collectionView, didSelectItemAt: indexpath)
//            }
//        }
//        return true
//    }
//    
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        
//        if isListView {
//            return CGSize(width: view.frame.width, height: 120)
//        } else {
//            let width = (view.frame.width - 2) / 3
//            return CGSize(width: width, height: width)
//        }
//        
//    }
//    
//    
//    func paginatePosts(){
//        //Pagination only limits the number of pictures that are loaded. All posts are already pre-loaded
//        let paginateFetchPostSize = 4
//        
//        self.paginatePostsCount = min(self.paginatePostsCount + paginateFetchPostSize, self.fetchedPosts.count)
//        print("Home Paginate \(self.paginatePostsCount) : \(self.fetchedPosts.count)")
//        
//        NotificationCenter.default.post(name: MapViewPaginateController.finishMapPaginationNotificationName, object: nil)
//    }
//    
//    // Pagination
//    
//    func finishPaginationCheck(){
//        self.isFinishedPaging = false
//        
//        if self.paginatePostsCount == (self.fetchedPosts.count) {
//            self.isFinishedPaging = true
//            print("Pagination: Finish Paging, Paging: \(self.isFinishedPaging)")
//            
//        }
//        
//        if self.fetchedPosts.count == 0 && self.isFinishedPaging == true {
//            print("Pagination: No Results, Paging: \(self.isFinishedPaging)")
//            
//        }
//        else if self.fetchedPosts.count == 0 && self.isFinishedPaging != true {
//            print("Pagination: No Results, Paging: \(self.isFinishedPaging)")
//            
//            self.paginatePosts()
//        } else {
//            print("Pagination: Success, Post: \(self.fetchedPosts.count)")
//            DispatchQueue.main.async(execute: { self.collectionView.reloadData()
//                
//                
//                // Scrolling for refreshed results
//                if self.scrolltoFirst && self.fetchedPosts.count > 1{
//                    print("Refresh Control Status: ", self.collectionView.refreshControl?.state)
//                    self.collectionView.refreshControl?.endRefreshing()
//                    let indexPath = IndexPath(item: 0, section: 0)
//                    self.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
//                    //                    self.collectionView?.setContentOffset(CGPoint(x: 0, y: 0 - self.topLayoutGuide.length), animated: true)
//                    print("Scrolled to Top")
//                    self.scrolltoFirst = false
//                    
//                }
//                
//            })
//        }
//    }
//    
//    
//    
//    
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        
//        return paginatePostsCount
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        
//        if indexPath.item == self.paginatePostsCount - 1 && !isFinishedPaging{
//            print("CollectionView Paginate")
//            paginatePosts()
//        }
//        
//        var displayPost = fetchedPosts[indexPath.item]
//        
//        if isListView {
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: listCellId, for: indexPath) as! ListPhotoCell
//            cell.delegate = self
//            cell.bookmarkDate = displayPost.creationDate
//            cell.post = displayPost
//            
//            if displayPost.id == self.selectedPostID {
//                cell.isSelected = true
//            } else {
//                cell.isSelected = false
//            }
//            return cell
//        } else {
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: gridCellId, for: indexPath) as! GridPhotoCell
//            cell.delegate = self
//            cell.post = displayPost
//            if displayPost.id == self.selectedPostID {
//                cell.isSelected = true
//            } else {
//                cell.isSelected = false
//            }
//            return cell
//        }
//    }
//    
//    
//    func scrollToPost(postId: String?){
//        guard let postId = postId else {
//            print("Scroll To Item: ERROR, no post Id")
//            return
//        }
//        
//        if collectionView.numberOfItems(inSection: 0) == 0 {
//            print("Scroll To Item: ERROR, no collectionview post")
//            return
//        }
//        
//        let index = fetchedPosts.index { (fetchedPost) -> Bool in
//            fetchedPost.id == postId
//        }
//        
//        guard let _ = index else {
//            print("Scroll To Item: ERROR, no fetched post index")
//            return
//        }
//        
//        let indexpath = IndexPath(row:index!, section: 0)
//        guard let layout = self.collectionView.collectionViewLayout.layoutAttributesForItem(at: indexpath) else {
//            self.collectionView.scrollToItem(at: indexpath, at: .top, animated: true)
//            return
//        }
//        let offset = CGPoint(x: 0, y: layout.frame.minY - 40)
//        self.collectionView.bounds.origin = offset
//        
//        let tempPost = fetchedPosts.first { (post) -> Bool in
//            post.id == postId
//        }
//        
//        
//        print("Scrolled to: ", tempPost?.locationName, tempPost?.id, indexpath, offset)
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        
//        let post = self.fetchedPosts[indexPath.row]
//        if self.selectedPostID == post.id {
//            let pictureController = PictureController()
//            pictureController.post = post
//            navigationController?.pushViewController(pictureController, animated: true)
//        } else {
//            
//            print("Location Selected \(post.locationName)")
//            self.selectedPostID = post.id
//            self.navigationItem.title = post.locationName
//            self.scrollToPost(postId: self.selectedPostID)
//            self.collectionView.reloadData()
//            self.expandCollectionView = false
//        }
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
//        return 1
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
//        if isListView {
//            return 1
//        } else {
//            return 0
//        }
//    }
//    
//    // SORT FILTER HEADER
//    
//    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: listHeaderId, for: indexPath) as! ListViewHeader
//        header.isFiltering = self.isFiltering
//        header.isListView = self.isListView
//        header.selectedCaption  = self.filterCaption
//        header.enableSearchBar = false
//        header.selectedSort = self.selectedHeaderSort!
//        header.delegate = self
//        return header
//        
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        var height = 30 + 5 + 5 // Header Sort with 5 Spacing
//        height += 40 // Search bar View
//        return CGSize(width: view.frame.width, height: 30 + 5 + 5)
//    }
//    
//    // Filter Controller Delegate
//    func filterControllerFinished(selectedCaption: String?, selectedRange: String?, selectedLocation: CLLocation?, selectedLocationName: String?, selectedGooglePlaceId: String?, selectedGooglePlaceType: [String]?, selectedMinRating: Double, selectedType: String?, selectedMaxPrice: String?, selectedSort: String, selectedLegit: Bool) {
//        // Clears all Filters, Puts in new Filters, Refreshes all Post IDS and Posts
//        
//        self.clearFilter()
//        
//        self.filterCaption = selectedCaption
//        self.filterRange = selectedRange
//        self.filterLocation = selectedLocation
//        self.filterLocationName = selectedLocationName
//        
//        self.filterMinRating = selectedMinRating
//        self.filterType = selectedType
//        self.filterMaxPrice = selectedMaxPrice
//        
//        self.filterLegit = selectedLegit
//        
//        self.selectedHeaderSort = selectedSort
//        
//        // Check for filtering
//        self.checkFilter()
//        
//        // Refresh Everything
//        self.refreshPostsForFilter()
//    }
//    
//    // Header Delegates
//    func didChangeToListView() {
//        self.isListView = true
//        self.expandCollectionView = true
//        collectionView.reloadData()
//    }
//    
//    func didChangeToPostView() {
//        self.isListView = false
//        self.expandCollectionView = true
//        collectionView.reloadData()
//    }
//    
//    func openFilter() {
//        let filterController = FilterController()
//        filterController.delegate = self
//        
//        filterController.selectedRange = self.filterRange
//        filterController.selectedMinRating = self.filterMinRating
//        filterController.selectedMaxPrice = self.filterMaxPrice
//        filterController.selectedType = self.filterType
//        filterController.selectedLegit = self.filterLegit
//        
//        filterController.selectedSort = self.selectedHeaderSort!
//        
//        self.navigationController?.pushViewController(filterController, animated: true)
//    }
//    
//    func clearCaptionSearch() {
//        
//    }
//    
//    func openSearch(index: Int?) {
//        
//    }
//    
//    func headerSortSelected(sort: String) {
//        self.selectedHeaderSort = sort
//        self.collectionView.reloadData()
//        
//        if (self.selectedHeaderSort == HeaderSortOptions[1] && self.filterLocation == nil){
//            print("Sort by Nearest, No Location, Look up Current Location")
//            LocationSingleton.sharedInstance.determineCurrentLocation()
//            let when = DispatchTime.now() + defaultGeoWaitTime // change 2 to desired number of seconds
//            DispatchQueue.main.asyncAfter(deadline: when) {
//                //Delay for 1 second to find current location
//                self.filterLocation = CurrentUser.currentLocation
//                self.refreshPostsForFilter()
//            }
//        } else {
//            self.refreshPostsForFilter()
//        }
//        
//        print("Filter Sort is ", self.selectedHeaderSort)
//    }
//    
//    
//    // List Photo Cell Delegates
//    
//    func didTapUser(post: Post) {
//        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
//        userProfileController.displayUserId = post.user.uid
//        
//        navigationController?.pushViewController(userProfileController, animated: true)
//    }
//    
//    func didTapLocation(post: Post) {
//        //        if let index = fetchedPosts.index(where: { (tempPost) -> Bool in
//        //            tempPost.id == post.id
//        //        }){
//        //            let indexpath = IndexPath(row:index, section: 0)
//        //            self.collectionView.selectItem(at: indexpath, animated: true, scrollPosition: UICollectionViewScrollPosition.centeredVertically)
//        //        }
//        let locationController = LocationController()
//        locationController.selectedPost = post
//        navigationController?.pushViewController(locationController, animated: true)
//    }
//    
//    func didTapMessage(post: Post) {
//        let messageController = MessageController()
//        messageController.post = post
//        
//        navigationController?.pushViewController(messageController, animated: true)
//    }
//    
//    func refreshPost(post: Post) {
//        let index = fetchedPosts.index { (fetchedPost) -> Bool in
//            fetchedPost.id == post.id
//        }
//        let indexpath = IndexPath(row:index!, section: 0)
//        
//        self.fetchedPosts[index!] = post
//        self.collectionView.reloadItems(at: [indexpath])
//        
//        // Update Cache
//        let postId = post.id
//        postCache[postId!] = post
//    }
//    
//    func deletePostFromList(post: Post) {
//        let deleteAlert = UIAlertController(title: "Delete", message: "Delete Post?", preferredStyle: UIAlertControllerStyle.alert)
//        
//        deleteAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
//            // Remove from Current View
//            let index = self.fetchedPosts.index { (filteredpost) -> Bool in
//                filteredpost.id  == post.id
//            }
//            
//            let deleteindexpath = IndexPath(row:index!, section: 0)
//            self.fetchedPosts.remove(at: index!)
//            self.collectionView.deleteItems(at: [deleteindexpath])
//            Database.deletePost(post: post)
//        }))
//        
//        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
//            print("Handle Cancel Logic here")
//        }))
//        
//        guard let uid = Auth.auth().currentUser?.uid else {return}
//        if post.creatorUID == uid{
//            // Only Allow Deletion if current user is list creator
//            present(deleteAlert, animated: true, completion: nil)
//        }
//    }
//    
//    func didTapPicture(post: Post) {
//        if let temp = fetchedPosts.index(where: { (fp) -> Bool in
//            fp.id == post.id
//        }){
//            self.collectionView(self.collectionView, didSelectItemAt: IndexPath(item: temp, section: 0))
//        }
//    }
//    
//    
//    func didTapExtraTag(tagName: String, tagId: String, post: Post) {
//        print("Not Allowed from Map View")
//    }
//    
//    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
//        print("test")
//    }
//    
//    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
//        print("test")
//    }
//    
//}
//
//
//
