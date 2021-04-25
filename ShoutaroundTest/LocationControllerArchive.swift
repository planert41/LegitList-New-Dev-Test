//
//  LocationController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/11/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps

import GeoFire
import GooglePlaces
import Alamofire
import SwiftyJSON
import EmptyDataSet_Swift
import MapKit

import Cosmos
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth



class ArchiveLocationController: UIViewController, UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, GMSMapViewDelegate, GridPhotoCellDelegate, EmptyDataSetSource, EmptyDataSetDelegate, LastLocationPhotoCellDelegate, MainSearchControllerDelegate, MKMapViewDelegate, FullPostCellDelegate, EmojiButtonArrayDelegate, TestGridPhotoCellDelegate, SharePhotoListControllerDelegate  {
    func doubleTapEmoji(index: Int?, emoji: String) {
        
    }
    
    
    func didTapListCancel(post: Post) {
        
    }
    
    
    let mapView = MKMapView()
    let mapPinReuseInd = "MapPin"
    let regionRadius: CLLocationDistance = 1000
    
    
    let locationCellId = "locationCellID"
    let photoHeaderId = "photoHeaderId"
    let photoCellId = "photoCellId"
    let fullPhotoCellId = "fullPhotoCellId"
    
    let lastPhotoCellId = "lastPhotoCellId"
    
    var allPosts = [Post]()
    var friendPosts = [Post]()
    var otherPosts = [Post]()
    
    var pictureControllerDisplayedPostId: String? = nil
    
    var isFilteringFriends: Bool = true
    
    var friendFilterSegment = UISegmentedControl()
    
    
    var postNearby: [String: CLLocation] = [:]
    
    // INPUT FROM DELEGATE
    var selectedPost: Post?{
        didSet{
            //            locationNameLabel.text = selectedPost?.locationName
            //            locationDistanceLabel.text = selectedPost?.locationAdress
            //            self.refreshMap(long: selectedLong!, lat: selectedLat!)
            
            selectedLocation = selectedPost?.locationGPS
            selectedName = selectedPost?.locationName
            selectedAdress = selectedPost?.locationAdress
            // NEED TO GET AVERAGE RATING
            //            starRating.rating = selectedPost?.rating ?? 0
            self.centerMapOnLocation(location: selectedLocation)
            self.googlePlaceId = selectedPost?.locationGooglePlaceID
            self.checkHasRestaurantLocation()
        }
    }
    var showSelectedPostPicture: Bool = true
    
    
    // MAIN INPUT
    var googlePlaceId: String? = nil {
        didSet{
            self.checkHasRestaurantLocation()
            // Google Place ID Exists
        }
    }
    
    var hasRestaurantLocation: Bool = false
    
    var selectedLocation: CLLocation? {
        didSet{
            if selectedLocation?.coordinate.latitude == 0 && selectedLocation?.coordinate.longitude == 0 {
                selectedLat = CurrentUser.currentLocation?.coordinate.latitude ?? 0
                selectedLong = CurrentUser.currentLocation?.coordinate.longitude ?? 0
                print("Selected Post Location: Nil, Using Current User Position: \(self.selectedLat), \(self.selectedLong)")
            } else {
                selectedLat = selectedLocation?.coordinate.latitude ?? 0
                selectedLong = selectedLocation?.coordinate.longitude ?? 0
            }
            self.checkHasRestaurantLocation()
        }
    }
    
    var selectedLong: Double? = 0
    var selectedLat: Double? = 0
    var selectedName: String? {
        didSet {
            if selectedName != nil {
                self.locationNameLabel.text = selectedName!
            }}}
    var selectedAdress: String?
    
    // Filter Variables
    var viewFilter: Filter? = Filter.init(defaultSort: defaultRecentSort) {
        didSet{
            //            setupNavigationItems()
        }
    }
    
    
    
    lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.delegate = self
        view.backgroundColor = UIColor.white
        return view
    }()
    
    lazy var tempView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    lazy var placeDetailsView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
        view.layer.borderColor = UIColor.gray.cgColor
        view.layer.borderWidth = 1
        return view
    }()
    
    
    // Expand Button
    lazy var expandButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage((self.isFullView ? #imageLiteral(resourceName: "expand_mainview") : #imageLiteral(resourceName: "collapse_mainview")).withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(togglePhotoView), for: .touchUpInside)
        button.tintColor = UIColor.legitColor()
        return button
    }()
    
    var isFullView = false
    var fullPhotoCollectionView:NSLayoutConstraint?
    var halfPhotoCollectionView:NSLayoutConstraint?
    
    func togglePhotoView(){
        UIView.animate(withDuration: 0.3) {
            self.isFullView = !self.isFullView
            self.fullPhotoCollectionView?.isActive = self.isFullView
            self.halfPhotoCollectionView?.isActive = !self.isFullView
            self.placeDetailsView.isHidden = self.isFullView
            self.expandButton.setImage((self.isFullView ? #imageLiteral(resourceName: "expand_mainview") : #imageLiteral(resourceName: "collapse_mainview")).withRenderingMode(.alwaysOriginal), for: .normal)
            self.view.updateConstraintsIfNeeded()
            self.view.layoutIfNeeded()
        }
    }
    
    // Grid/List View Button
    var isGridView = true {
        didSet{
            formatButton.setImage(!self.isGridView ? #imageLiteral(resourceName: "grid") :#imageLiteral(resourceName: "postview"), for: .normal)
        }
    }
    
    lazy var formatButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(self.isGridView ? #imageLiteral(resourceName: "grid") :#imageLiteral(resourceName: "postview"), for: .normal)
        button.addTarget(self, action: #selector(changeView), for: .touchUpInside)
        button.tintColor = UIColor.legitColor()
        return button
    }()
    
    func changeView(){
        if isGridView{
            self.isGridView = false
            if !self.isFullView {
                self.togglePhotoView()
            }
        } else {
            self.isGridView = true
            if self.isFullView {
                self.togglePhotoView()
            }
        }
        self.photoCollectionView.reloadData()
    }
    
    
    
    func mapView(_ mapView: GMSMapView, didTap overlay: GMSOverlay) {
        mapView.delegate = self
        print("Tapped")
        self.activateMap()
    }
    
    func checkHasRestaurantLocation(){
        self.hasRestaurantLocation = true
        
        guard let googlePlaceId = googlePlaceId else {
            self.hasRestaurantLocation = false
            return
        }
        
        if googlePlaceId == "" {
            self.hasRestaurantLocation = false
        }
        
        if selectedAdress != nil && selectedName != nil {
            // If User uses Google to input adress, it will produce a GooglePlaceID, but won't be a location
            if (selectedName?.count)! > 1 && (selectedAdress?.count)! > 1 && selectedName == selectedAdress {
                self.hasRestaurantLocation = false
            }
        }
        
        //        print("Restaurant Location Check: \(self.hasRestaurantLocation) : \(googlePlaceId)")
    }
    
    
    
    // Location Detail Items
    
    let locationDetailRowHeight: CGFloat = 30
    
    // Google Place Variables
    var placeName: String?
    var placeOpeningHours: [JSON]?
    var placePhoneNo: String?
    var placeWebsite: String?
    var placeGoogleRating: Double?
    var placeOpenNow: Bool? = nil {
        didSet {
            if placeOpenNow == nil {
                locationHoursIcon.setImage(#imageLiteral(resourceName: "time_icon").withRenderingMode(.alwaysOriginal), for: .normal)
            } else {
                locationHoursIcon.setImage((self.placeOpenNow! ? #imageLiteral(resourceName: "open_icon") : #imageLiteral(resourceName: "close_icon")).withRenderingMode(.alwaysOriginal), for: .normal)
            }
        }
    }
    var placeGoogleMapUrl: String?
    var placeDetailStackview = UIStackView()
    
    // Location Name
    let locationNameView = UIView()
    lazy var locationNameLabel = PaddedUILabel()
    
    let locationNameIcon: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "home").withRenderingMode(.alwaysOriginal), for: .normal)
        return button
    }()
    
    // Location Adress
    let locationAdressView = UIView()
    lazy var locationAdressLabel = PaddedUILabel()
    let locationAdressIcon: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "google_color").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(activateMap), for: .touchUpInside)
        return button
    }()
    
    // Location Hours
    let locationHoursView = UIView()
    lazy var locationHoursLabel: LightPaddedUILabel = {
        let label = LightPaddedUILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.backgroundColor = UIColor(white: 1, alpha: 0.75)
        label.layer.borderWidth = 0.5
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        label.isUserInteractionEnabled = true
        return label
    }()
    
    
    
    let locationHoursIcon: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "close_icon").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(locationHoursIconTapped), for: .touchUpInside)
        return button
    }()
    
    // Location Phone
    let locationPhoneView = UIView()
    lazy var locationPhoneLabel: PaddedUILabel = {
        let label = PaddedUILabel()
        label.backgroundColor = UIColor.selectedColor().withAlphaComponent(0.6)
        label.font = UIFont.systemFont(ofSize: 10)
        label.layer.borderWidth = 0.5
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let locationPhoneIcon: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "phone").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(activatePhone), for: .touchUpInside)
        return button
    }()
    
    // Location Website
    let locationWebsiteView = UIView()
    lazy var locationWebsiteLabel = PaddedUILabel()
    
    let locationWebsiteIcon: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "website").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(activateBrowser), for: .touchUpInside)
        return button
    }()
    
    func updateWebsitePhoneIcon() {
        guard let website = self.placeWebsite else {
            return
        }
        if let website = self.placeWebsite {
            if website.lowercased().range(of: "facebook.com") != nil {
                print("Location Website: Contain Facebook Page")
                self.locationWebsiteIcon.setImage(#imageLiteral(resourceName: "facebook_icon").withRenderingMode(.alwaysOriginal), for: .normal)
            } else {
                self.locationWebsiteIcon.setImage(#imageLiteral(resourceName: "website").withRenderingMode(.alwaysOriginal), for: .normal)
            }
        }
        
        //        if let phoneNumber = self.placePhoneNo {
        //            self.locationPhoneIcon.isHidden = true
        //        } else {
        //            self.locationPhoneIcon.isHidden = true
        //        }
        
    }
    
    
    
    // Location Places Collection View
    lazy var placesCollectionView : UICollectionView = {
        let uploadLocationTagList = UploadLocationTagList()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadLocationTagList)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = UIColor(white: 0, alpha: 0.03)
        return cv
    }()
    
    // Location Detail Functions
    func locationHoursIconTapped(){
        var timeString = "" as String
        for time in self.placeOpeningHours! {
            timeString = timeString + time.string! + "\n"
        }
        self.alert(title: "Opening Hours", message: timeString)
    }
    
    func activateMap() {
        SharedFunctions.openGoogleMaps(lat: selectedLat, long: selectedLong)
        
        //        if (UIApplication.shared.canOpenURL(NSURL(string:"https://www.google.com/maps/search/?api=1&query=\(selectedLat!),\(selectedLong!)")! as URL)) {
        //            UIApplication.shared.openURL(NSURL(string:
        //                "https://www.google.com/maps/search/?api=1&query=\(selectedLat!),\(selectedLong!)")! as URL)
        //        } else {
        //            NSLog("Can't use comgooglemaps://");
        //        }
    }
    
    func activatePhone(){
        print("Tapped Phone Icon")
        guard let url = URL(string: "tel://\(self.placePhoneNo!)") else {return}
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    func activateBrowser(){
        guard let url = URL(string: self.placeWebsite!) else {return}
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    
    
    
    // Collection View Title
    
    lazy var collectionViewTitleLabel: PaddedUILabel = {
        let ul = PaddedUILabel()
        ul.text = "Photos From Location:"
        ul.font = UIFont.boldSystemFont(ofSize: 15)
        return ul
    }()
    
    lazy var noIdLabel: PaddedUILabel = {
        let ul = PaddedUILabel()
        ul.text = "Restaurants Around Location"
        ul.font = UIFont.boldSystemFont(ofSize: 15)
        return ul
    }()
    
    lazy var photoCollectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = UIColor(white: 0, alpha: 0.03)
        cv.isScrollEnabled = false
        //        cv.emptyDataSetSource = self
        //        cv.emptyDataSetDelegate = self
        
        return cv
    }()
    
    
    func didTapPicture(post: Post) {
        let pictureController = SinglePostView()
        pictureController.post = post
        navigationController?.pushViewController(pictureController, animated: true)
    }
    
    
    
    
    func updateAdressLabel() {
        
        guard let selectedLocation = self.selectedLocation else {return}
        guard let currentUserLocation = CurrentUser.currentLocation else {return}
        guard let selectedAdress = self.selectedAdress else {return}
        
        var distance = Double((selectedLocation.distance(from: currentUserLocation)))
        
        // Convert to M to KM
        let locationDistance = distance/1000
        let distanceformat = ".2"
        let adressString = (selectedAdress).truncate(length: 30)
        
        if locationDistance < 1000 {
            var attributedString = NSMutableAttributedString(string: " \(adressString)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 12),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black]))
            attributedString.append(NSMutableAttributedString(string: " (\(locationDistance.format(f: distanceformat)) KM)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 12),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.mainBlue()])))
            self.locationAdressLabel.attributedText = attributedString
        }
    }
    
    
    let photoView = UIView()
    var placeDetailsViewHasLocationHeight:NSLayoutConstraint?
    var placeDetailsViewNoLocationHeight:NSLayoutConstraint?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.rgb(red: 249, green: 249, blue: 249)
        
        setupNavigationItems()
        setupInitFilter()
        setupMap()
        if CurrentUser.currentLocation == nil {
            LocationSingleton.sharedInstance.determineCurrentLocation()
        }
        
        
        view.addSubview(mapView)
        mapView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 200)
        
        
        // Place Details View
        view.addSubview(placeDetailsView)
        placeDetailsView.anchor(top: mapView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        placeDetailsViewHasLocationHeight = placeDetailsView.heightAnchor.constraint(equalToConstant: (4 * (locationDetailRowHeight + 2 + 2) + 6))
        placeDetailsViewNoLocationHeight = placeDetailsView.heightAnchor.constraint(equalToConstant: (3 * (locationDetailRowHeight + 2 + 2) + 6))
        placeDetailsViewHasLocationHeight?.isActive = true
        
        let bottomDividerView = UIView()
        bottomDividerView.backgroundColor = UIColor.white
        view.addSubview(bottomDividerView)
        bottomDividerView.anchor(top: placeDetailsView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        // Photo CollectionView
        
        view.addSubview(photoView)
        photoView.anchor(top: placeDetailsView.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        halfPhotoCollectionView = photoView.topAnchor.constraint(equalTo: placeDetailsView.bottomAnchor)
        fullPhotoCollectionView = photoView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor)
        halfPhotoCollectionView?.isActive = true
        
        let photoHeaderView = UIView()
        view.addSubview(photoHeaderView)
        photoHeaderView.anchor(top: photoView.topAnchor, left: photoView.leftAnchor, bottom: nil, right: photoView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        photoHeaderView.backgroundColor = UIColor.white
        
        
        view.addSubview(expandButton)
        expandButton.anchor(top: nil, left: nil, bottom: nil, right: photoHeaderView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 30, height: 30)
        expandButton.centerYAnchor.constraint(equalTo: photoHeaderView.centerYAnchor).isActive = true
        
        view.addSubview(formatButton)
        formatButton.anchor(top: nil, left: nil, bottom: nil, right: expandButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 30, height: 30)
        formatButton.centerYAnchor.constraint(equalTo: photoHeaderView.centerYAnchor).isActive = true
        
        setupFriendFilterSegment()
        view.addSubview(friendFilterSegment)
        friendFilterSegment.anchor(top: nil, left: photoHeaderView.leftAnchor, bottom: nil, right: formatButton.leftAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)
        friendFilterSegment.centerYAnchor.constraint(equalTo: photoHeaderView.centerYAnchor).isActive = true
        
        
        view.addSubview(photoCollectionView)
        photoCollectionView.anchor(top: photoHeaderView.bottomAnchor, left: photoView.leftAnchor, bottom: photoView.bottomAnchor, right: photoView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        //        photoCollectionView.register(GridPhotoCell.self, forCellWithReuseIdentifier: photoCellId)
        photoCollectionView.register(TestGridPhotoCell.self, forCellWithReuseIdentifier: photoCellId)
        
        photoCollectionView.register(FullPostCell.self, forCellWithReuseIdentifier: fullPhotoCellId)
        photoCollectionView.register(LastLocationPhotoCell.self, forCellWithReuseIdentifier: lastPhotoCellId)
        photoCollectionView.backgroundColor = UIColor.white
        
        self.clearFilter()
        
        
        
        // Created a temp uiview and pinned all labels/map/pics onto temp uiview
        // Created scrollview and pinned temp uiview on top of scroll view
        // Added ScrollView onto view
        
        //        scrollView.frame = view.bounds
        //        scrollView.backgroundColor = UIColor.white
        //        scrollView.isScrollEnabled = true
        //        scrollView.showsVerticalScrollIndicator = true
        //        scrollView.contentSize = CGSize(width: view.bounds.width, height: view.bounds.height * 2)
        //        self.view.addSubview(scrollView)
        //
        //        scrollView.addSubview(tempView)
        //        tempView.anchor(top: scrollView.topAnchor, left: view.leftAnchor, bottom: scrollView.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        //
        
        //
        //    // CollectionView Title Header
        //        tempView.addSubview(collectionViewTitleLabel)
        //        collectionViewTitleLabel.anchor(top: placeDetailsView.bottomAnchor, left: tempView.leftAnchor, bottom: nil, right: tempView.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 20)
        
        
        
    }
    
    let friendFilterOptions = ["Friends", "Others"]
    
    func setupFriendFilterSegment(){
        friendFilterSegment = UISegmentedControl(items: friendFilterOptions)
        friendFilterSegment.tintColor = UIColor.legitColor()
        friendFilterSegment.backgroundColor = UIColor.white
        friendFilterSegment.addTarget(self, action: #selector(selectFriendSort), for: .valueChanged)
        friendFilterSegment.selectedSegmentIndex = self.isFilteringFriends ? 0 : 1
    }
    
    func selectFriendSort(sender: UISegmentedControl) {
        print("Selected Friend Filter | ",sender.selectedSegmentIndex)
        self.isFilteringFriends = (sender.selectedSegmentIndex == 0)
        self.updateScopeBarCount()
        self.photoCollectionView.reloadData()
    }
    
    func updateScopeBarCount(){
        var temp_scope = friendFilterOptions
        
        if self.friendPosts.count > 0 {
            temp_scope[0] = friendFilterOptions[0] + " \(self.friendPosts.count)"
            friendFilterSegment.setTitle(temp_scope[0], forSegmentAt: 0)
        } else {
            friendFilterSegment.setTitle(friendFilterOptions[0], forSegmentAt: 0)
        }
        
        if self.otherPosts.count > 0 {
            temp_scope[1] = friendFilterOptions[1] + " \(self.otherPosts.count)"
            friendFilterSegment.setTitle(temp_scope[1], forSegmentAt: 1)
        } else {
            friendFilterSegment.setTitle(friendFilterOptions[1], forSegmentAt: 1)
        }
        
        //        friendFilterSegment = UISegmentedControl(items: temp_scope)
        //        friendFilterSegment.tintColor = UIColor.legitColor()
        //        friendFilterSegment.backgroundColor = UIColor.white
        //        friendFilterSegment.addTarget(self, action: #selector(selectFriendSort), for: .valueChanged)
        //        friendFilterSegment.selectedSegmentIndex = self.isFilteringFriends ? 0 : 1
    }
    
    
    
    func centerMapOnLocation(location: CLLocation?, radius: CLLocationDistance? = 0, closestLocation: CLLocation? = nil) {
        guard let location = location else {
            print("centerMapOnLocation | NO LOCATION")
            return}
        
        var displayRadius: CLLocationDistance = radius == 0 ? regionRadius : radius!
        
        
        //        if let closestLocation = closestLocation {
        //            displayRadius = location.distance(from: closestLocation)*2
        //            displayRadius = max(displayRadius, regionRadius)
        //        }
        
        
        let coordinateRegion = MKCoordinateRegion.init(center: location.coordinate,
                                                       latitudinalMeters: displayRadius, longitudinalMeters: displayRadius)
        //        mapView?.region = coordinateRegion
        print("centerMapOnLocation | \(location.coordinate) | Radius \(displayRadius)")
        mapView.setRegion(coordinateRegion, animated: true)
        
        let annotation = MKPointAnnotation()
        let centerCoordinate = CLLocationCoordinate2D(latitude: (location.coordinate.latitude), longitude:(location.coordinate.longitude))
        annotation.coordinate = centerCoordinate
        annotation.title = self.selectedName
        mapView.addAnnotation(annotation)
    }
    
    // MAP
    func setupMap(){
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.mapType = MKMapType.standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.register(MapPinMarkerView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.register(ClusterMapPinMarkerView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        if hasRestaurantLocation{
            print("Google Location: \(self.googlePlaceId)")
            setupPlaceDetailStackview()
            self.populatePlaceDetails(placeId: googlePlaceId)
            self.fetchPostForPostLocation(placeId: googlePlaceId!)
        } else {
            print("Google Location: No Location: (\(self.selectedLat), \(self.selectedLong))")
            setupNoLocationView()
            // Google Search For Nearby Restaurants
            self.googleLocationSearch(GPSLocation: CLLocation(latitude: self.selectedLat!, longitude: self.selectedLong!))
            // Search For All Posts within Location
            self.fetchPostWithLocation(location: CLLocation(latitude: self.selectedLat!, longitude: self.selectedLong!))
        }
    }
    
    func openSearch(index: Int?){
        
        let postSearch = MainSearchController()
        postSearch.delegate = self
        
        // Option Counts for Current Filter
        
        Database.countEmojis(posts: isFilteringFriends ? self.friendPosts : self.otherPosts) { (emojiCounts) in
            postSearch.emojiCounts = emojiCounts
            postSearch.defaultEmojiCounts = emojiCounts
            
        }
        Database.countCityIds(posts: isFilteringFriends ? self.friendPosts : self.otherPosts) { (locationCounts) in
            postSearch.locationCounts = locationCounts
            postSearch.defaultLocationCounts = locationCounts
        }
        
        postSearch.searchFilter = self.viewFilter
        postSearch.setupInitialSelections()
        
        self.navigationController?.pushViewController(postSearch, animated: true)
        if index != nil {
            postSearch.selectedScope = index!
            postSearch.searchController.searchBar.selectedScopeButtonIndex = index!
        }
        
    }
    
    
    
    
    func clearCaptionSearch() {
        self.viewFilter?.filterCaption = nil
        self.refreshAll()
    }
    
    func clearAllPosts(){
        self.allPosts.removeAll()
        self.friendPosts.removeAll()
        self.otherPosts.removeAll()
        self.allPostEmojiCounts.removeAll()
        self.friendPostemojiCounts.removeAll()
        self.emojiArray.emojiLabels = []
    }
    
    func refreshAll(){
        self.clearAllPosts()
        
        if hasRestaurantLocation{
            self.fetchPostForPostLocation(placeId: googlePlaceId!)
        } else {
            self.fetchPostWithLocation(location: CLLocation(latitude: self.selectedLat!, longitude: self.selectedLong!))
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
    func setupNoLocationView(){
        
        self.placeDetailsViewHasLocationHeight?.isActive = false
        self.placeDetailsViewNoLocationHeight?.isActive = true
        
        setupLocationLabels(containerview: locationNameView, icon: locationNameIcon, label: locationNameLabel)
        
        //        placeDetailsView.addSubview(locationNameView)
        //        locationNameView.anchor(top: placeDetailsView.topAnchor, left: placeDetailsView.leftAnchor, bottom: nil, right: placeDetailsView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: locationDetailRowHeight)
        
        locationNameLabel.text = self.selectedName ?? ""
        locationNameLabel.isUserInteractionEnabled = true
        locationNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayFullLocationName)))
        
        // Add Suggested Places CollectionView
        
        placesCollectionView.delegate = self
        placesCollectionView.dataSource = self
        placesCollectionView.showsHorizontalScrollIndicator = false
        
        //        placeDetailsView.addSubview(placesCollectionView)
        //        placesCollectionView.anchor(top: locationNameView.bottomAnchor, left: placeDetailsView.leftAnchor, bottom: nil, right: placeDetailsView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: locationDetailRowHeight)
        
        placesCollectionView.backgroundColor = UIColor.legitColor().withAlphaComponent(0.8)
        placesCollectionView.register(UploadLocationCell.self, forCellWithReuseIdentifier: locationCellId)
        
        // Dummy Header, Won't get shown
        placesCollectionView.register(FriendFilterHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: photoHeaderId)
        
        
        // Add Map
        // MOST USED EMOJIS
        
        let locationEmojiDetails = UIView()
        
        locationEmojiDetails.addSubview(emojiLabel)
        emojiLabel.anchor(top: nil, left: locationEmojiDetails.leftAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        emojiLabel.centerYAnchor.constraint(equalTo: locationEmojiDetails.centerYAnchor).isActive = true
        emojiLabel.text = "Popular Emojis Nearby"
        emojiLabel.textColor = UIColor.darkLegitColor()
        
        locationEmojiDetails.addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top: emojiLabel.topAnchor, left: emojiLabel.leftAnchor, bottom: emojiLabel.bottomAnchor, right: emojiLabel.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        emojiDetailLabel.alpha = 0
        
        self.emojiArray = EmojiButtonArray(emojis: [], frame: CGRect(x: 0, y: 0, width: 0, height: locationDetailRowHeight-5))
        emojiArray.alignment = .left
        emojiArray.delegate = self
        
        locationEmojiDetails.addSubview(emojiArray)
        emojiArray.anchor(top: locationEmojiDetails.topAnchor, left: emojiLabel.rightAnchor, bottom: locationEmojiDetails.bottomAnchor, right: locationEmojiDetails.rightAnchor, paddingTop: 3, paddingLeft: 20, paddingBottom: 3, paddingRight: 15, width: 0, height: 0)
        emojiArray.sizeToFit()
        
        locationNameView.backgroundColor = UIColor.legitColor().withAlphaComponent(0.8)
        locationEmojiDetails.backgroundColor = UIColor.clear
        
        
        placeDetailStackview = UIStackView(arrangedSubviews: [locationNameView, placesCollectionView, locationEmojiDetails])
        placeDetailStackview.distribution = .fillEqually
        placeDetailStackview.axis = .vertical
        
        placeDetailsView.addSubview(placeDetailStackview)
        placeDetailStackview.anchor(top: placeDetailsView.topAnchor, left: placeDetailsView.leftAnchor, bottom: placeDetailsView.bottomAnchor, right: placeDetailsView.rightAnchor, paddingTop: 3, paddingLeft: 0, paddingBottom: 3, paddingRight: 0, width: 0, height: 0)
        
        
    }
    
    func displayFullLocationName(){
        self.alert(title: "Full Location Name", message: self.locationNameLabel.text!)
    }
    
    
    var emojiArray = EmojiButtonArray(emojis: [], frame: CGRect(x: 0, y: 0, width: 0, height: 25))
    var allPostEmojiCounts:[String:Int] = [:]
    var friendPostemojiCounts:[String:Int] = [:]
    
    lazy var emojiLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Popular Emojis"
        ul.font = UIFont.boldSystemFont(ofSize: 15)
        return ul
    }()
    
    lazy var otherPictureLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Popular Emojis"
        ul.font = UIFont.boldSystemFont(ofSize: 15)
        return ul
    }()
    
    let starRating: CosmosView = {
        let iv = CosmosView()
        iv.settings.fillMode = .half
        iv.settings.totalStars = 5
        //        iv.settings.starSize = 30
        iv.settings.starSize = 20
        iv.settings.updateOnTouch = false
        iv.settings.filledImage = #imageLiteral(resourceName: "star_rating_filled_mid").withRenderingMode(.alwaysOriginal)
        iv.settings.emptyImage = #imageLiteral(resourceName: "star_rating_unfilled").withRenderingMode(.alwaysOriginal)
        iv.rating = 0
        iv.settings.starMargin = 1
        return iv
    }()
    
    let emojiDetailLabel: PaddedUILabel = {
        let label = PaddedUILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.rgb(red: 255, green: 242, blue: 230)
        label.layer.cornerRadius = 30/2
        label.layer.borderWidth = 0.25
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.masksToBounds = true
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    
    func didTapEmoji(index: Int?, emoji: String) {
        guard let index = index else {
            print("No Index For emoji \(emoji)")
            return
        }
        
        print("Selected Emoji \(emoji) : \(index)")
        
        var captionDelay = 3
        let emojiTag = EmojiDictionary[emoji] ?? ""
        emojiDetailLabel.text = "\(emoji)  \(emojiTag)"
        emojiDetailLabel.alpha = 1
        emojiDetailLabel.sizeToFit()
        
        UIView.animate(withDuration: 0.5, delay: TimeInterval(captionDelay), options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.emojiDetailLabel.alpha = 0
        }, completion: { (finished: Bool) in
        })
        
    }
    
    func setupPlaceDetailStackview(){
        
        self.placeDetailsViewHasLocationHeight?.isActive = true
        self.placeDetailsViewNoLocationHeight?.isActive = false
        
        setupLocationLabels(containerview: locationNameView, icon: locationNameIcon, label: locationNameLabel)
        //        setupLocationLabels(containerview: locationWebsiteView, icon: locationWebsiteIcon, label: locationWebsiteLabel)
        setupLocationLabels(containerview: locationAdressView, icon: locationAdressIcon, label: locationAdressLabel)
        
        //        setupLocationLabels(containerview: locationHoursView, icon: locationHoursIcon, label: locationHoursLabel)
        //        setupLocationLabels(containerview: locationPhoneView, icon: locationPhoneIcon, label: locationPhoneLabel)
        
        // SETUP TIME AND PHONE NUMBER
        
        let locationExtraDetails = UIView()
        let locationExtraDetailStackview = UIStackView(arrangedSubviews: [locationHoursLabel, locationPhoneLabel])
        locationExtraDetailStackview.spacing = 3
        locationExtraDetailStackview.distribution = .equalSpacing
        
        //        locationExtraDetails.addSubview(locationExtraDetailStackview)
        //        locationExtraDetailStackview.anchor(top: locationExtraDetails.topAnchor, left: locationExtraDetails.leftAnchor, bottom: locationExtraDetails.bottomAnchor, right: locationExtraDetails.rightAnchor, paddingTop: 3, paddingLeft: 15, paddingBottom: 3, paddingRight: 15, width: 0, height: 0)
        
        locationExtraDetails.addSubview(locationHoursLabel)
        locationHoursLabel.anchor(top: locationExtraDetails.topAnchor, left: locationExtraDetails.leftAnchor, bottom: locationExtraDetails.bottomAnchor, right: nil, paddingTop: 3, paddingLeft: 15, paddingBottom: 3, paddingRight: 15, width: 0, height: 0)
        locationHoursLabel.widthAnchor.constraint(lessThanOrEqualToConstant: self.view.frame.width/2).isActive = true
        
        locationExtraDetails.addSubview(locationPhoneLabel)
        locationPhoneLabel.anchor(top: locationExtraDetails.topAnchor, left: locationHoursLabel.rightAnchor, bottom: locationExtraDetails.bottomAnchor, right: nil, paddingTop: 3, paddingLeft: 15, paddingBottom: 3, paddingRight: 15, width: 0, height: 0)
        
        
        
        
        // MOST USED EMOJIS
        
        let locationEmojiDetails = UIView()
        
        locationEmojiDetails.addSubview(emojiLabel)
        emojiLabel.anchor(top: nil, left: locationEmojiDetails.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        emojiLabel.centerYAnchor.constraint(equalTo: locationEmojiDetails.centerYAnchor).isActive = true
        emojiLabel.text = "Popular Tagged Emojis"
        emojiLabel.textColor = UIColor.darkLegitColor()
        
        
        
        locationEmojiDetails.addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top: emojiLabel.topAnchor, left: emojiLabel.leftAnchor, bottom: emojiLabel.bottomAnchor, right: emojiLabel.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        emojiDetailLabel.alpha = 0
        
        self.emojiArray = EmojiButtonArray(emojis: [], frame: CGRect(x: 0, y: 0, width: 0, height: locationDetailRowHeight-5))
        emojiArray.alignment = .left
        emojiArray.delegate = self
        
        locationEmojiDetails.addSubview(emojiArray)
        emojiArray.anchor(top: locationEmojiDetails.topAnchor, left: emojiLabel.rightAnchor, bottom: locationEmojiDetails.bottomAnchor, right: locationEmojiDetails.rightAnchor, paddingTop: 3, paddingLeft: 20, paddingBottom: 3, paddingRight: 15, width: 0, height: 0)
        emojiArray.sizeToFit()
        
        // STAR RATING VIEW
        let starRatingDetails = UIView()
        
        starRatingDetails.addSubview(otherPictureLabel)
        otherPictureLabel.anchor(top: nil, left: starRatingDetails.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        otherPictureLabel.centerYAnchor.constraint(equalTo: starRatingDetails.centerYAnchor).isActive = true
        otherPictureLabel.text = "Other Pictures"
        otherPictureLabel.textColor = UIColor.darkLegitColor()
        otherPictureLabel.sizeToFit()
        
        starRatingDetails.addSubview(starRating)
        starRating.anchor(top: starRatingDetails.topAnchor, left: otherPictureLabel.rightAnchor, bottom: starRatingDetails.bottomAnchor, right: starRatingDetails.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        starRating.rating = 0
        
        
        // Add Gesture Recognizers
        locationAdressLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action:  #selector(activateMap)))
        locationHoursLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action:  #selector(locationHoursIconTapped)))
        locationWebsiteLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action:  #selector(activateBrowser)))
        locationPhoneLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action:  #selector(activatePhone)))
        
        
        
        //        placeDetailStackview = UIStackView(arrangedSubviews: [locationNameView, locationAdressView, locationHoursView, locationPhoneView])
        //        placeDetailStackview = UIStackView(arrangedSubviews: [locationNameView, locationAdressView, locationExtraDetails, locationEmojiDetails])
        placeDetailStackview = UIStackView(arrangedSubviews: [locationNameView, locationAdressView, locationExtraDetails, starRatingDetails])
        
        
        starRatingDetails
        placeDetailStackview.distribution = .fillEqually
        placeDetailStackview.axis = .vertical
        
        placeDetailsView.addSubview(placeDetailStackview)
        placeDetailStackview.anchor(top: placeDetailsView.topAnchor, left: placeDetailsView.leftAnchor, bottom: placeDetailsView.bottomAnchor, right: placeDetailsView.rightAnchor, paddingTop: 3, paddingLeft: 0, paddingBottom: 3, paddingRight: 0, width: 0, height: 0)
        
        locationNameLabel.addSubview(locationWebsiteIcon)
        locationWebsiteIcon.anchor(top: locationNameLabel.topAnchor, left: nil, bottom: locationNameLabel.bottomAnchor, right: locationNameLabel.rightAnchor, paddingTop: 1, paddingLeft: 0, paddingBottom: 1, paddingRight: 3, width: 0, height: 0)
        locationWebsiteIcon.widthAnchor.constraint(equalTo: locationWebsiteIcon.heightAnchor, multiplier: 1).isActive = true
        
        
        //        tempView.addSubview(locationPhoneIcon)
        //        locationPhoneIcon.anchor(top: locationWebsiteLabel.topAnchor, left: nil, bottom: locationWebsiteLabel.bottomAnchor, right: locationWebsiteLabel.rightAnchor, paddingTop: 3, paddingLeft: 0, paddingBottom: 3, paddingRight: 5, width: 0, height: 0)
        //        locationPhoneIcon.widthAnchor.constraint(equalTo: locationWebsiteIcon.heightAnchor, multiplier: 1).isActive = true
        //        locationPhoneIcon.isHidden = true
        
    }
    
    
    func setupNavigationItems(){
        
        let tapGestureMsg = UITapGestureRecognizer(target: self, action: #selector(didTapNavMessage))
        tapGestureMsg.numberOfTapsRequired = 1
        
        var rangeImageButton = UIImageView(frame: CGRect(x: 0, y: 0, width: 15, height: 15))
        rangeImageButton.image = #imageLiteral(resourceName: "message_fill").withRenderingMode(.alwaysOriginal)
        rangeImageButton.contentMode = .scaleAspectFit
        rangeImageButton.sizeToFit()
        rangeImageButton.backgroundColor = UIColor.clear
        rangeImageButton.addGestureRecognizer(tapGestureMsg)
        
        let rangeBarButton = UIBarButtonItem.init(customView: rangeImageButton)
        navigationItem.rightBarButtonItem = rangeBarButton
    }
    
    
    var noIdView = UIView()
    
    
    
    func setupLocationLabels(containerview: UIView, icon: UIButton, label: UILabel){
        containerview.addSubview(icon)
        containerview.addSubview(label)
        containerview.backgroundColor = UIColor.clear
        
        //Icon Height Anchor determines row height
        icon.anchor(top: containerview.topAnchor, left: containerview.leftAnchor, bottom: containerview.bottomAnchor, right: nil, paddingTop: 2, paddingLeft: 15, paddingBottom: 2, paddingRight: 5, width: locationDetailRowHeight, height: locationDetailRowHeight)
        //        icon.widthAnchor.constraint(equalTo: locationNameIcon.heightAnchor, multiplier: 1)
        
        label.anchor(top: containerview.topAnchor, left: icon.rightAnchor, bottom: containerview.bottomAnchor, right: containerview.rightAnchor, paddingTop: 2, paddingLeft: 10, paddingBottom: 2, paddingRight: 15, width: 0, height: 0)
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 12)
        label.backgroundColor = UIColor(white: 1, alpha: 0.75)
        label.layer.borderWidth = 0.5
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        label.isUserInteractionEnabled = true
    }
    
    
    func searchNearby(){
        let locationController = LocationController()
        locationController.selectedLocation = self.selectedLocation
        locationController.selectedName = self.selectedAdress
        
        navigationController?.pushViewController(locationController, animated: true)
    }
    
    
    
    func didTapNavMessage() {
        let messageController = MessageController()
        if selectedPost == nil {
            // Show first found post if no selected post
            if allPosts.count == 0 {
                self.alert(title: "Message Error", message: "No Available Post to Send")
            } else {
                messageController.post = allPosts[0]
            }
        } else {
            messageController.post = selectedPost
        }
        
        navigationController?.pushViewController(messageController, animated: true)
        
    }
    
    
    
    func fetchPostForPostLocation(placeId:String){
        
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
        
        let rangeString: String? = self.viewFilter?.filterRange ?? "0.025"
        var filterRange = 500.0
        
        if let temp = self.viewFilter?.filterRange {
            filterRange = Double(temp)! * 1000
        }
        
        print("No Google Place ID. Searching Posts by Location: ", location)
        Database.fetchAllPostWithLocation(location: location, distance: filterRange) { (fetchedPosts, fetchedPostIds) in
            print("Fetched Post with Location: \(location) : \(fetchedPosts.count) Posts")
            self.allPosts = fetchedPosts
            self.averageRating(posts: self.allPosts)
            self.filterSortFetchedPosts()
        }
        
    }
    
    func fetchPostWithGooglePlaceID(googlePlaceID: String){
        print("Searching Posts by Google Place ID: ", googlePlaceID)
        Database.fetchAllPostWithGooglePlaceID(googlePlaceId: googlePlaceID) { (fetchedPosts, fetchedPostIds) in
            print("Fetching Post with googlePlaceId: \(googlePlaceID) : \(fetchedPosts.count) Posts")
            self.allPosts = fetchedPosts
            self.averageRating(posts: self.allPosts)
            self.filterSortFetchedPosts()
        }
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
        
        self.starRating.rating = (totalRatingCount > 0) ? (totalRating/Double(totalRatingCount)) : 0
    }
    
    func filterSortFetchedPosts(){
        
        // Filter Posts
        // Not Filtering for Location and Range/Distances
        Database.filterPostsNew(inputPosts: self.allPosts, postFilter: self.viewFilter) { (filteredPosts) in
            Database.sortPosts(inputPosts: filteredPosts, selectedSort: self.viewFilter?.filterSort, selectedLocation: self.viewFilter?.filterLocation, completion: { (filteredPosts) in
                self.allPosts = []
                if filteredPosts != nil {
                    self.allPosts = filteredPosts!
                    
                    // Take out current post image
                    if !self.showSelectedPostPicture {
                        var oldCount = self.allPosts.count
                        self.allPosts = self.allPosts.filter({ (post) -> Bool in
                            return post.id != self.selectedPost?.id
                        })
                        print("LocationController | showSelectedPostPicture | \(self.showSelectedPostPicture) | \(oldCount - self.allPosts.count) Post Filtered")
                    }
                    
                    self.separatePosts()
                }
                print("  ~ Finish Filter and Sorting Post")
                self.photoCollectionView.reloadData()
            })
        }
        
    }
    
    func separatePosts(){
        self.friendPosts = self.allPosts.filter({ (post) -> Bool in
            return CurrentUser.followingUids.contains(post.creatorUID!) || (post.creatorUID == Auth.auth().currentUser?.uid)
        })
        self.otherPosts = self.allPosts.filter({ (post) -> Bool in
            return !CurrentUser.followingUids.contains(post.creatorUID!) && !(post.creatorUID == Auth.auth().currentUser?.uid)
        })
        self.updateScopeBarCount()
        
        Database.countEmojis(posts: self.allPosts) { (emoji_counts) in
            self.allPostEmojiCounts = emoji_counts
        }
        
        Database.countEmojis(posts: self.friendPosts) { (emoji_counts) in
            self.friendPostemojiCounts = emoji_counts
        }
        self.updateEmojiArray()
    }
    
    func updateEmojiArray(){
        let displayEmojisArray = self.isFilteringFriends ? self.friendPostemojiCounts : self.allPostEmojiCounts
        
        var displayEmojis: [String] = []
        for (key,value) in displayEmojisArray {
            if displayEmojis.count < 6 {
                if key.containsOnlyEmoji {
                    displayEmojis.append(key)
                } else {
                    // Not Emoji. Is Auto-tag String
                    if let temp = mealEmojiDictionary.key(forValue: key) {
                        displayEmojis.append(temp)
                    } else if let temp = cuisineEmojiDictionary.key(forValue: key) {
                        displayEmojis.append(temp)
                    } else if let temp = dietEmojiDictionary.key(forValue: key) {
                        displayEmojis.append(temp)
                    }
                }
            }
        }
        emojiArray.emojiLabels = displayEmojis
        emojiArray.setEmojiButtons()
        emojiArray.sizeToFit()
    }
    
    
    
    func filterPostByLocation(location: CLLocation){
        
        let ref = Database.database().reference().child("postlocations")
        let geoFire = GeoFire(firebaseRef: ref)
        
        var geoFilteredPosts = [Post]()
        self.postNearby.removeAll()
        
        print("Current User Location Used for Post Filtering", location)
        let circleQuery = geoFire.query(at: location, withRadius: 5)
        circleQuery.observe(.keyEntered, with: { (key, location) in
            
            guard let postId: String = key else {return}
            guard let postLocation: CLLocation = location else {return}
            
            self.postNearby[key] = postLocation
            
        })
        
        circleQuery.observeReady({
            
            self.addMarkers()
            
        })
        
    }
    
    func addMarkers() {
        var mapPins: [MapPin] = []
        for post in self.allPosts {
            if post.locationGPS != nil && post.id != nil {
                mapPins.append(MapPin(post: post))
            }
        }
        mapView.addAnnotations(mapPins)
        print("Added Map Pins | Fetched \(mapPins.count) | Added \(mapView.annotations.count)")
        
    }
    
    
    
    // Search Delegate And Methods
    
    func filterControllerSelected(filter: Filter?) {
        self.viewFilter = filter
        self.refreshAll()
    }
    
    func setupInitFilter(){
        self.viewFilter = Filter.init(defaultSort: defaultRecentSort)
        if let location = selectedPost?.locationGPS {
            self.viewFilter?.filterLocation = location
        }
        
        if let googleID = selectedPost?.locationGooglePlaceID {
            self.viewFilter?.filterGoogleLocationID = googleID
        }
        
        self.viewFilter?.filterRange = nil
    }
    
    func clearFilter(){
        self.viewFilter?.clearFilter()
        self.setupInitFilter()
    }
    
    
    
    
    // Collection View Delegates
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView == placesCollectionView{
            
            let locationController = LocationController()
            print(googlePlaceIDs[indexPath.row])
            locationController.googlePlaceId = googlePlaceIDs[indexPath.item]
            locationController.selectedName = googlePlaceNames[indexPath.item]
            navigationController?.pushViewController(locationController, animated: true)
            
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == photoCollectionView {
            return 1
        }
        else if collectionView == placesCollectionView {
            return 5
        } else {return 1}
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        
        if collectionView == photoCollectionView {
            return 1
        }
        else if collectionView == placesCollectionView {
            return 5
        } else {return 1}
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == photoCollectionView {
            if isGridView {
                //                let width = (view.frame.width - 2) / 3
                let width = (view.frame.width - 2) / 2
                
                return CGSize(width: width, height: width)
            } else {
                var height: CGFloat = 40 + 8 + 8 //username userprofileimageview
                height += view.frame.width
                height += 50
                height += 60
                height += 10
                
                return CGSize(width: view.frame.width, height: height)
            }
        } else {return CGSize(width: 10, height: 10)}
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == photoCollectionView {
            if self.isFilteringFriends {
                return friendPosts.count
            } else {
                return otherPosts.count
            }
        }
            
        else if collectionView == placesCollectionView {
            return googlePlaceNames.count
        } else{
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == photoCollectionView {
            var displayPost = (isFilteringFriends ? friendPosts[indexPath.row] : otherPosts[indexPath.row])
            
            if isGridView {
                //                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoCellId, for: indexPath) as! GridPhotoCell
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoCellId, for: indexPath) as! TestGridPhotoCell
                
                cell.showDistance = false
                cell.post = displayPost
                cell.delegate = self
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: fullPhotoCellId, for: indexPath) as! FullPostCell
                cell.post = displayPost
                cell.delegate = self
                return cell
            }
            
            
            //            if indexPath.row == (isFilteringFriends ? friendPosts.count : allPosts.count) {
            //                // Add Last Photo Cell to enable search nearby
            //                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: lastPhotoCellId, for: indexPath) as! LastLocationPhotoCell
            //                cell.delegate = self
            //                return cell
            //            } else {
            //                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoCellId, for: indexPath) as! GridPhotoCell
            //                cell.delegate = self
            //                cell.post = (isFilteringFriends ? friendPosts[indexPath.row] : allPosts[indexPath.row])
            //                return cell
            //            }
            
        } else if collectionView == placesCollectionView{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: locationCellId, for: indexPath) as! UploadLocationCell
            cell.uploadLocations.font = UIFont.systemFont(ofSize: 13)
            cell.uploadLocations.text = googlePlaceNames[indexPath.item]
            //            cell.backgroundColor = UIColor(white: 0, alpha: 0.03)
            cell.backgroundColor = UIColor.white
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoCellId, for: indexPath) as! GridPhotoCell
            cell.delegate = self
            cell.post = allPosts[indexPath.item]
            return cell
        }
        
    }
    
    // Full Photo Cell Delegate
    
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
    
    func didTapUserUid(uid: String) {
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = uid
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapLocation(post: Post) {
        let locationController = LocationController()
        locationController.selectedPost = post
        
        navigationController?.pushViewController(locationController, animated: true)
    }
    
    func didTapMessage(post: Post) {
        let messageController = MessageController()
        messageController.post = post
        
        navigationController?.pushViewController(messageController, animated: true)
    }
    
    func refreshPost(post: Post) {
        
    }
    
    func userOptionPost(post: Post) {
        
    }
    
    
    func displaySelectedEmoji(emoji: String, emojitag: String) {
        print("Display Selected Emoji \(emoji) \(emojitag)")
    }
    
    func didTapExtraTag(tagName: String, tagId: String, post: Post) {
        
        // Check to see if its a list, price or something else
        if tagId == "price"{
            // Price Tag Selected
            print("Price Selected")
            self.viewFilter?.filterMaxPrice = tagName
            //            self.refreshPostsForFilter()
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
                    
                    
//                    let listViewController = ListViewController()
//                    listViewController.collectionView.collectionViewLayout = HomeSortFilterHeaderFlowLayout()
//                    listViewController.currentDisplayList = fetchedList
//                    self.navigationController?.pushViewController(listViewController, animated: true)
                }
            })
        }
    }
    
    func displayPostSocialUsers(post: Post, following: Bool) {
        print("Display Vote Users| Following: ",following)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayUser = true
        postSocialController.displayUserFollowing = following
        postSocialController.inputPost = post
        
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    func displayPostSocialLists(post: Post, following: Bool) {
        print("Display Lists| Following: ",following)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayList = true
        postSocialController.displayFollowing = following
        postSocialController.inputPost = post
        
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    
    // EMPTY DATA SET DELEGATES
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        if (viewFilter?.isFiltering)! {
            text = "There's Nothing Here?!"
        } else {
            let number = arc4random_uniform(UInt32(tipDefaults.count))
            text = tipDefaults[Int(number)]
        }
        
        font = UIFont.boldSystemFont(ofSize: 17.0)
        textColor = UIColor(hexColor: "25282b")
        
        if text == nil {
            return nil
        }
        
        return NSMutableAttributedString(string: text!, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): font, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): textColor]))
        
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        //        if isFiltering {
        //            text = nil
        //        } else {
        //            text = nil
        //        }
        
        //        let number = arc4random_uniform(UInt32(tipDefaults.count))
        //        text = tipDefaults[Int(number)]
        text = nil
        
        font = UIFont.boldSystemFont(ofSize: 13.0)
        textColor = UIColor(hexColor: "7b8994")
        
        if text == nil {
            return nil
        }
        
        return NSMutableAttributedString(string: text!, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): font, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): textColor]))
        
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return -100
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return #imageLiteral(resourceName: "amaze").resizeVI(newSize: CGSize(width: view.frame.width/2, height: view.frame.height/2))
    }
    
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        text = "Search Nearby"
        
        font = UIFont.boldSystemFont(ofSize: 14.0)
        textColor = UIColor(hexColor: "00aeef")
        
        if text == nil {
            return nil
        }
        
        return NSMutableAttributedString(string: text!, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): font, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): textColor]))
        
    }
    
    //    func buttonBackgroundImage(forEmptyDataSet scrollView: UIScrollView, for state: UIControlState) -> UIImage? {
    //
    //        var capInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    //        var rectInsets = UIEdgeInsets.zero
    //
    //        capInsets = UIEdgeInsets(top: 25, left: 25, bottom: 25, right: 25)
    //        rectInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    //
    //        let image = #imageLiteral(resourceName: "emptydatasetbutton")
    //        return image.resizableImage(withCapInsets: capInsets, resizingMode: .stretch).withAlignmentRectInsets(rectInsets)
    //    }
    
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
        return UIColor(hexColor: "ffffff")
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {
        
        searchNearby()
        
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapView view: UIView) {
    }
    
    //    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
    //        let offset = (self.collectionView?.frame.height)! / 5
    //            return -50
    //    }
    
    func spaceHeight(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return 0
    }
    
    
    // Google Location Search Functions
    
    func populatePlaceDetails(placeId: String?){
        guard let placeId = placeId else {
            print("Google Place Id is nil")
            return
        }
        
        let URL_Search = "https://maps.googleapis.com/maps/api/place/details/json?"
        let API_iOSKey = GoogleAPIKey()
        
        
        //        https://maps.googleapis.com/maps/api/place/details/json?placeid=ChIJbd2OryfY3IARR6800Hij7-Q&key=AIzaSyAzwACZh50Qq1V5YYKpmfN21mZs8dW6210
        
        let urlString = "\(URL_Search)placeid=\(placeId)&key=\(API_iOSKey)"
        let url = URL(string: urlString)!
        //        print("Google Places URL: ",urlString)
        
        //        print("Place Cache for postid: ", placeId, placeCache[placeId])
        if let result = locationGoogleJSONCache[placeId] {
            //            print("Using Place Cache for placeId: ", placeId)
            self.extractPlaceDetails(fetchedResults: result)
        } else {
            
            AF.request(url).responseJSON { (response) -> Void in
                //                        print("Google Response: ",response)
                if let value  = response.value {
                    let json = JSON(value)
                    let result = json["result"]
                    
                    locationGoogleJSONCache[placeId] = result
                    self.extractPlaceDetails(fetchedResults: result)
                }
            }
        }
    }
    
    func extractPlaceDetails(fetchedResults: JSON){
        
        let result = fetchedResults
        //                print("Fetched Results: ",result)
        if result["place_id"].string != nil {
            
            self.placeName = result["name"].string ?? ""
            //            print("place Name: ", self.placeName)
            self.locationNameLabel.text = self.placeName
            
            self.selectedName = self.placeName
            self.navigationItem.title = self.placeName
            
            self.placeOpeningHours = result["opening_hours"]["weekday_text"].arrayValue
            //                                    print("placeOpeningHours: ", self.placeOpeningHours)
            
            let today = Date()
            let myCalendar = Calendar(identifier: .gregorian)
            let weekDay = myCalendar.component(.weekday, from: today)
            
            var todayIndex: Int
            
            // Apple starts with Sunday at 1 to sat at 7. Google starts Sunday at 0 ends at 6
            if weekDay == 1 {
                todayIndex = 0
            } else {
                todayIndex = weekDay - 1
            }
            
            //            print("placeOpenNow: ", self.placeOpenNow)
            
            if self.placeOpeningHours! != [] {
                
                
                // Determine if Open
                //                var placeOpeningPeriods: [JSON]?
                guard let placeOpeningPeriods = result["opening_hours"]["periods"].arrayValue as [JSON]? else {return}
                
                //                print(placeOpeningPeriods)
                
                var day: Int?
                var openHourString: String?
                var closeHourString: String?
                
                for day_entry in placeOpeningPeriods {
                    day = day_entry["close"]["day"].int
                    if day == todayIndex {
                        openHourString = day_entry["open"]["time"].string
                        closeHourString = day_entry["close"]["time"].string
                        break
                    }
                }
                
                //                let openHourString = placeOpeningPeriods[hourIndex!]["open"]["time"].string
                //                let closeHourString = placeOpeningPeriods[hourIndex!]["close"]["time"].string
                //                let day = placeOpeningPeriods[hourIndex!]["close"]["day"].int
                
                
                if day == todayIndex {
                    let inFormatter = DateFormatter()
                    inFormatter.locale = NSLocale.current
                    inFormatter.dateFormat = "HHmm"
                    
                    let openHour = NSCalendar.current.component(.hour, from: inFormatter.date(from: openHourString!)!)
                    let closeHour = NSCalendar.current.component(.hour, from: inFormatter.date(from: closeHourString!)!)
                    
                    let nowHour = NSCalendar.current.component(.hour, from: Date())
                    
                    if nowHour >= openHour && nowHour < closeHour {
                        // The store is open
                        self.placeOpenNow = true
                    } else {
                        self.placeOpenNow = false
                    }
                } else {
                    print("Place Open: ERROR, Wrong Day, Default to Close")
                    self.placeOpenNow = false
                }
                
                
                self.locationHoursLabel.isHidden = (self.placeOpenNow == nil)
                
                
                // Set Opening Hour Label
                var googDayIndex: Int?
                if todayIndex == 0 {
                    googDayIndex = 6
                } else {
                    googDayIndex = todayIndex-1
                }
                
                let todayHours = String(describing: (self.placeOpeningHours?[googDayIndex!])!)
                var textColor = UIColor.init(hexColor: "028090")
                if let open = self.placeOpenNow {
                    if open {
                        //                        textColor = UIColor.init(hexColor: "028090")
                        textColor = UIColor.darkLegitColor()
                    } else {
                        textColor = UIColor.init(hexColor: "E71D36")
                        textColor = UIColor.white
                    }
                    self.locationHoursLabel.backgroundColor = (self.placeOpenNow! ? UIColor.init(hexColor: "14bd54") : UIColor.init(hexColor: "a61224")).withAlphaComponent(0.5)
                    
                }
                
                let openAttributedText = NSMutableAttributedString()
                
                let imageSize = CGSize(width: locationDetailRowHeight, height: locationDetailRowHeight)
                let openImage = NSTextAttachment()
                let openIcon = (self.placeOpenNow! ? #imageLiteral(resourceName: "open_icon") : #imageLiteral(resourceName: "close_icon")).withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
                openImage.bounds = CGRect(x: 0, y: (self.locationHoursLabel.font.capHeight - openIcon.size.height).rounded() / 2, width: openIcon.size.width, height: openIcon.size.height)
                openImage.image = openIcon
                let openImageString = NSAttributedString(attachment: openImage)
                openAttributedText.append(openImageString)
                
                var attributedText = NSMutableAttributedString(string: "  " + todayHours, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 10),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): textColor]))
                openAttributedText.append(attributedText)
                
                self.locationHoursLabel.attributedText = openAttributedText
                
            } else {
                // No Opening Hours from Google
                self.locationHoursLabel.text = ""
                self.placeOpenNow = nil
            }
            
            self.placePhoneNo = result["formatted_phone_number"].string ?? ""
            self.locationPhoneLabel.isHidden = (self.placePhoneNo == "")
            //            print("placePhoneNo: ", self.placePhoneNo)
            self.locationPhoneLabel.text = "☎️ \(self.placePhoneNo!)"
            self.locationPhoneLabel.sizeToFit()
            self.locationPhoneLabel.isUserInteractionEnabled = true
            self.locationPhoneLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action:  #selector(activatePhone)))
            
            
            self.placeWebsite = result["website"].string ?? ""
            //            print("placeWebsite: ", self.placeWebsite)
            self.locationWebsiteLabel.text = self.placeWebsite
            
            self.placeGoogleRating = result["rating"].double ?? 0
            //            print("placeGoogleRating: ", self.placeGoogleRating)
            
            self.placeGoogleMapUrl = result["url"].string!
            
            self.selectedLong = result["geometry"]["location"]["lng"].double ?? 0
            self.selectedLat = result["geometry"]["location"]["lat"].double ?? 0
            self.selectedLocation = CLLocation(latitude: self.selectedLat!, longitude: self.selectedLong!)
            
            self.selectedAdress = result["formatted_address"].string ?? ""
            self.locationAdressLabel.text = self.selectedAdress
            
            self.updateWebsitePhoneIcon()
            
        } else {
            print("Failed to extract Google Place Details")
        }
    }
    
    
    
    func googleLocationSearch(GPSLocation: CLLocation){
        
        //        let dataProvider = GoogleDataProvider()
        let searchRadius: Double = 100
        var searchedTypes = ["restaurant"]
        var searchTerm = "restaurant"
        
        downloadRestaurantDetails(GPSLocation, searchRadius: searchRadius, searchType: searchTerm)
        
    }
    
    var googlePlaceNames = [String?]()
    var googlePlaceIDs = [String]()
    var googlePlaceAdresses = [String]()
    var googlePlaceLocations = [CLLocation]()
    
    func downloadRestaurantDetails(_ lat: CLLocation, searchRadius:Double, searchType: String ) {
        let URL_Search = "https://maps.googleapis.com/maps/api/place/search/json?"
        let API_iOSKey = GoogleAPIKey()
        
        var urlParameters = URLComponents(string: "https://maps.googleapis.com/maps/api/place/search/json?")!
        
        urlParameters.queryItems = [
            URLQueryItem(name: "location", value: "\(lat.coordinate.latitude),\(lat.coordinate.longitude)"),
            URLQueryItem(name: "rankby", value: "distance"),
            URLQueryItem(name: "type", value: "\(searchType)"),
            URLQueryItem(name: "key", value: "\(API_iOSKey)"),
        ]
        
        //        let urlString = "\(URL_Search)location=\(lat.coordinate.latitude),\(lat.coordinate.longitude)&rankby=distance&type=\(searchType)&key=\(API_iOSKey)"
        //        let url = URL(string: urlString)!
        //
        //        print("Restaurant Google Download URL: \(urlString)")
        
        //   https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=-33.8670,151.1957&radius=500&types=food&name=cruise&key=YOUR_API_KEY
        
        // https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=41.9542116666667,-87.7055883333333&radius=100.0&rankby=distance&type=restaurant&key=AIzaSyAzwACZh50Qq1V5YYKpmfN21mZs8dW6210
        
        self.googlePlaceNames.removeAll()
        self.googlePlaceIDs.removeAll()
        self.googlePlaceAdresses.removeAll()
        self.googlePlaceLocations.removeAll()
        
        AF.request(urlParameters).responseJSON { (response) -> Void in
            
            //         print(response)
            
            if let value  = response.value {
                let json = JSON(value)
                
                if let results = json["results"].array {
                    print("Found Google Places Results: \(results.count)")
                    for result in results {
                        //                        print("Fetched Google Place Names Results: ",result)
                        if result["place_id"].string != nil {
                            guard let placeID = result["place_id"].string else {return}
                            guard let name = result["name"].string else {return}
                            guard let locationAdress = result["vicinity"].string else {return}
                            guard let postLatitude = result["geometry"]["location"]["lat"].double else {return}
                            guard let postLongitude = result["geometry"]["location"]["lng"].double else {return}
                            
                            // Checks to make sure its not a blank result
                            
                            let locationGPStempcreate = CLLocation(latitude: postLatitude, longitude: postLongitude)
                            
                            let check = result["opening_hours"]
                            if check != nil  {
                                self.googlePlaceNames.append(name)
                                self.googlePlaceIDs.append(placeID)
                                self.googlePlaceAdresses.append(locationAdress)
                                self.googlePlaceLocations.append(locationGPStempcreate)
                                self.placesCollectionView.reloadData()
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    
    
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
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
