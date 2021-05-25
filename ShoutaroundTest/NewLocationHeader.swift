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
import SVProgressHUD

protocol NewLocationHeaderDelegate {
    func didTapLocationHours(hours: [JSON]?)
    func didTapAddTag(addTag: String)
    func didTapSearchButton()
    func didChangeToGridView()
    func didChangeToPostView()
    func didTapFilterFriends(filteringFriends: Bool)
    func extShowGoogleRating(rating: Double?, location: String?)

    //    func listSelected(list: List?)
//    func resizeContainer(size: CGFloat)
//    func resizeContainerRow(row: Int)

}


class NewLocationHeader: UICollectionViewCell, EmojiSummaryCVDelegate, MKMapViewDelegate, UserSearchBarDelegate {
    var delegate: NewLocationHeaderDelegate?

    var location: Location? {
        didSet {
            guard let loc = location?.locationGPS else {
                print("ERROR - No Location GPS - \(location?.locationName)")
                return
            }
            self.selectedLocation = loc
            self.selectedLat = loc.coordinate.latitude ?? 0
            self.selectedLong = loc.coordinate.longitude ?? 0
            
            self.googlePlaceId = self.location?.locationGoogleID

            self.selectedName = location?.locationName
            self.selectedAdress = location?.locationAdress
            self.googlePlaceJSON = location?.googleJson

            self.refreshHeaderLabels()
//            self.extractRestaurantInfo()
        }
    }
    
    
    var selectedLong: Double? = 0
    var selectedLat: Double? = 0
    var selectedLocation: CLLocation? {
        didSet {
//            self.resetLocation()
//            self.centerMapOnLocation(location: selectedLocation)
        }
    }
    
    var selectedAdress: String?
    var selectedName: String? {
        didSet {
            if selectedName != nil {
                var nameString = selectedName!
            }
        }}


    
    // Google Place Variables
    var hasRestaurantLocation: Bool = false

    var googlePlaceId: String? = nil {
        didSet{
            guard let placeId = googlePlaceId else {return}
            if self.location == nil || location?.locationGoogleID != placeId{
                Database.fetchLocationWithLocID(locId: placeId) { (tempLoc) in
                    self.location = tempLoc
                }
            }
//            self.queryGooglePlaces(placeId: placeId)
            // Google Place ID Exists
        }
    }
    
    var googlePlaceJSON: JSON? = nil {
        didSet {
            guard let googlePlaceJSON = googlePlaceJSON else {return}
            self.refreshHeaderLabels()
        }
    }

    
    var placeName: String?
    var placeOpeningHours: [JSON]?
    var placeOpeningSchedule: [JSON]?
    var placePhoneNo: String?
    var placeWebsite: String?
    var placeGoogleRating: Double?
    var placeOpenNow: Bool? = nil {
        didSet {
            if placeOpenNow == nil {
                locationHoursIcon.setTitle("", for: .normal)
                locationHoursIcon.sizeToFit()
            } else {
                let openImage = #imageLiteral(resourceName: "open_icon").withRenderingMode(.alwaysOriginal)
                locationHoursIcon.setImage(self.placeOpenNow! ? openImage : UIImage(), for: .normal)
                var text = (self.placeOpenNow! ? "" : " CLOSED ")
                let headerTitle = NSAttributedString(string: text, attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(font: .avenirNextBold, size: 16)])
                locationHoursIcon.setAttributedTitle(headerTitle, for: .normal)
                locationHoursIcon.sizeToFit()
            }
        }
    }
    var placeGoogleMapUrl: String?
    var placeDetailStackview = UIStackView()
    
    let locationNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Poppins-Bold", size: 25)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.left
        label.lineBreakMode = .byWordWrapping
        label.lineBreakMode = .byClipping
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.baselineAdjustment = .alignCenters
        return label
    }()
    
    var locationRating: Double = 0.0
    let starRating: CosmosView = {
        let iv = CosmosView()
        iv.settings.fillMode = .half
        iv.settings.totalStars = 5
        //        iv.settings.starSize = 30
        iv.settings.starSize = 25
        iv.settings.updateOnTouch = false
//        iv.settings.filledImage = #imageLiteral(resourceName: "star_rating_filled_mid").withRenderingMode(.alwaysOriginal)
//        iv.settings.emptyImage = #imageLiteral(resourceName: "star_rating_unfilled").withRenderingMode(.alwaysOriginal)
        iv.settings.filledImage = #imageLiteral(resourceName: "new_star").withRenderingMode(.alwaysTemplate)
        iv.settings.emptyImage = #imageLiteral(resourceName: "new_star_gray").withRenderingMode(.alwaysTemplate)
//        iv.settings.emptyImage = #imageLiteral(resourceName: "new_star_black").withRenderingMode(.alwaysTemplate)
        iv.rating = 0
        iv.settings.starMargin = 1
        return iv
    }()
    
    let googleRatingButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
        button.setImage(#imageLiteral(resourceName: "googleIcon"), for: .normal)
        button.contentMode = .scaleAspectFit
        button.setTitleColor(UIColor.black, for: .normal)
        button.titleLabel?.font = UIFont(font: .avenirNextDemiBold, size: 13)
//        button.addTarget(self, action: #selector(resetLocation), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.translatesAutoresizingMaskIntoConstraints = true
        button.semanticContentAttribute  = .forceLeftToRight
        button.addTarget(self, action: #selector(didTapGoogleRatingButton), for: .touchUpInside)
        return button
    }()
    
    @objc func didTapGoogleRatingButton() {
        print("didTapGoogleRatingButton")
        self.delegate?.extShowGoogleRating(rating: self.placeGoogleRating, location: self.selectedName)
//        self.delegate?.didTapGoogleRatingButton()
//        SVProgressHUD.
//        self.alert(title: "Google Rating", message: "\(self.selectedName) Google Rating Is \(tempText)")
    }
    
    
    let locationHoursView = UIView()
    
    lazy var locationHoursLabel: LightPaddedUILabel = {
        let label = LightPaddedUILabel()
        label.isUserInteractionEnabled = true
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    let locationHoursIcon: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.ianLegitColor()
        button.addTarget(self, action: #selector(locationHoursIconTapped), for: .touchUpInside)
        return button
    }()
    
    let locationHoursHeight: CGFloat = 20.0
    var locationHoursHeightConstraint: NSLayoutConstraint?
    
    var noLocHoursConstraint: NSLayoutConstraint?
    var showLocHoursConstraint: NSLayoutConstraint?

    
    @objc func locationHoursIconTapped() {
        self.delegate?.didTapLocationHours(hours : self.placeOpeningHours)
    }
    
    // LOCATION ADRESS
        lazy var locationAdressLabel: UILabel = {
            let label = UILabel()
            label.text = ""
            label.font = UIFont(font: .avenirNextMedium, size: 14)
            label.backgroundColor = UIColor.clear
            label.isUserInteractionEnabled = true
            label.textColor = UIColor.darkGray
            label.numberOfLines = 2
            return label
        }()
        
        let locationDistanceLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.boldSystemFont(ofSize: 12)
            label.textColor = UIColor.mainBlue()
            label.textAlignment = NSTextAlignment.right
            return label
        }()
    
    // EMOJIS
    
    let emojiSummary = EmojiSummaryCV()

    var emojiCounts:[String: Int] = [:] {
        didSet {
//            self.emojiSummary.displayedEmojisCounts = self.emojiCounts
        }
    }
    
    func didTapEmoji(emoji: String) {
        self.delegate?.didTapAddTag(addTag: emoji)
    }
    
    
    // MAP
    
    let mapView = MKMapView()
    let mapPinReuseInd = "MapPin"
    let regionRadius: CLLocationDistance = 1000
    
    let locationButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "Geofence"), for: .normal)
        button.addTarget(self, action: #selector(resetLocation), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()

    
    lazy var trackingButton: MKUserTrackingButton = {
        let button = MKUserTrackingButton()
        //        button.layer.backgroundColor = UIColor(white: 1, alpha: 0.8).cgColor
        button.layer.backgroundColor = UIColor.lightGray.withAlphaComponent(0.25).cgColor
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 5
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()
    
    lazy var postHeaderLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Posts"
        ul.font = UIFont(name: "Poppins-Bold", size: 25)
        ul.textColor = UIColor.ianBlackColor()
        ul.textAlignment = NSTextAlignment.left
        ul.numberOfLines = 1
        ul.backgroundColor = UIColor.clear
        return ul
    }()
    
    var postCount: Int = 0 {
        didSet {
            self.searchBar.filteredPostCount = self.postCount
        }
    }
    var postFormatInd: Int = gridFormat {
        didSet {
            searchBar.isGridView = postFormatInd == gridFormat
        }
    }
    let searchBar = UserSearchBar()
    var viewFilter: Filter = Filter.init(defaultSort: defaultRecentSort){
        didSet {
            self.searchBar.viewFilter = viewFilter
        }
    }
    
    var isFilteringFriends: Bool = true {
        didSet {
            self.searchSegment.selectedSegmentIndex = isFilteringFriends ? 0 : 1
        }
    }
//    let searchOptions = UserSearchOptions
    var searchSegment: UISegmentedControl = {
        var segment = UISegmentedControl(items: UserSearchOptions)
        return segment
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        
    // LOCATION NAME
        addSubview(locationNameLabel)
        locationNameLabel.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 35)
        locationNameLabel.sizeToFit()
        
        addSubview(starRating)
        starRating.anchor(top: locationNameLabel.bottomAnchor, left: locationNameLabel.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 30)
//        starRating.centerYAnchor.constraint(equalTo: detailView.centerYAnchor).isActive = true
        
        addSubview(googleRatingButton)
        googleRatingButton.anchor(top: nil, left: starRating.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 50, height: 20)
        googleRatingButton.centerYAnchor.constraint(equalTo: starRating.centerYAnchor).isActive = true
        googleRatingButton.isHidden = true
        googleRatingButton.isUserInteractionEnabled = false

        
    // LOCATION HOURS
        addSubview(locationHoursView)
        locationHoursView.anchor(top: starRating.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 20)
        locationHoursHeightConstraint = locationHoursView.heightAnchor.constraint(equalToConstant: locationHoursHeight)
        
        
        locationHoursView.addSubview(locationHoursIcon)
        locationHoursIcon.anchor(top: nil, left: locationNameLabel.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        locationHoursIcon.centerYAnchor.constraint(equalTo: locationHoursView.centerYAnchor).isActive = true
        locationHoursIcon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(locationHoursIconTapped)))

        
        locationHoursView.addSubview(locationHoursLabel)
        locationHoursLabel.anchor(top: nil, left: nil, bottom: nil, right: locationHoursView.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        locationHoursLabel.centerYAnchor.constraint(equalTo: locationHoursIcon.centerYAnchor).isActive = true
        locationHoursLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(locationHoursIconTapped)))
        noLocHoursConstraint = locationHoursLabel.leftAnchor.constraint(equalTo: locationNameLabel.leftAnchor)
        showLocHoursConstraint = locationHoursLabel.leftAnchor.constraint(equalTo: locationHoursIcon.rightAnchor, constant: 5)
        
        noLocHoursConstraint?.isActive = true
        
    // MAP VIEW
        addSubview(mapView)
        mapView.anchor(top: locationHoursView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 200)
        mapView.isScrollEnabled = false

        setupMap()

        addSubview(locationDistanceLabel)
        locationDistanceLabel.anchor(top: nil, left: nil, bottom: mapView.bottomAnchor, right: mapView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        locationDistanceLabel.backgroundColor = UIColor.ianWhiteColor().withAlphaComponent(0.9)
        locationDistanceLabel.layer.cornerRadius = 5
        locationDistanceLabel.layer.masksToBounds = true
//        locationDistanceLabel.centerYAnchor.constraint(equalTo: adressContainer.centerYAnchor).isActive = true
        locationDistanceLabel.sizeToFit()
        
        
    // LOCATION ADRESS
        let adressContainer = UIView()
        addSubview(adressContainer)
        adressContainer.anchor(top: mapView.bottomAnchor, left: locationHoursView.leftAnchor, bottom: nil, right: locationHoursView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)

//        addSubview(locationDistanceLabel)
//        locationDistanceLabel.anchor(top: nil, left: nil, bottom: nil, right: adressContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 5, width: 0, height: 0)
//        locationDistanceLabel.centerYAnchor.constraint(equalTo: adressContainer.centerYAnchor).isActive = true
//        locationDistanceLabel.sizeToFit()


        addSubview(locationButton)
        locationButton.anchor(top: nil, left: adressContainer.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 10, paddingRight: 5, width: 25, height: 25)
        locationButton.centerYAnchor.constraint(equalTo: adressContainer.centerYAnchor).isActive = true
        locationButton.backgroundColor = UIColor.clear
        
        
        addSubview(locationAdressLabel)
        locationAdressLabel.anchor(top: adressContainer.topAnchor, left: locationButton.rightAnchor, bottom: adressContainer.bottomAnchor, right: locationHoursView.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        locationAdressLabel.isUserInteractionEnabled = true
        locationAdressLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(resetLocation)))
        
        
        
    // EMOJI
        let emojiView = UIView()
        addSubview(emojiView)
        emojiView.anchor(top: adressContainer.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        emojiView.backgroundColor = UIColor.clear

        emojiView.addSubview(emojiSummary)
        emojiSummary.anchor(top: emojiView.topAnchor, left: emojiView.leftAnchor, bottom: emojiView.bottomAnchor, right: emojiView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        emojiSummary.backgroundColor = UIColor.clear
        emojiSummary.centerYAnchor.constraint(equalTo: emojiView.centerYAnchor).isActive = true
        emojiSummary.showBadges = false
        emojiSummary.delegate = self
        
        
            // POST VIEW
        let postContainerView = UIView()
        postContainerView.backgroundColor = UIColor.backgroundGrayColor()
        addSubview(postContainerView)
        postContainerView.anchor(top: emojiView.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

    // POST HEADER COUNT
        let postCountHeaderView = UIView()
        addSubview(postCountHeaderView)
        postCountHeaderView.anchor(top: postContainerView.topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        postCountHeaderView.backgroundColor = UIColor.backgroundGrayColor()
        
        setupTypeSegment()
        postCountHeaderView.addSubview(searchSegment)
        searchSegment.anchor(top: postCountHeaderView.topAnchor, left: nil, bottom: postCountHeaderView.bottomAnchor, right: postCountHeaderView.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 10, width: 150, height: 0)
        
        
        postCountHeaderView.addSubview(postHeaderLabel)
        postHeaderLabel.anchor(top: postCountHeaderView.topAnchor, left: postCountHeaderView.leftAnchor, bottom: postCountHeaderView.bottomAnchor, right: searchSegment.leftAnchor, paddingTop: 4, paddingLeft: 15, paddingBottom: 4, paddingRight: 15, width: 0, height: 0)
//        postHeaderLabel.centerYAnchor.constraint(equalTo: postCountHeaderView.centerYAnchor).isActive = true
        postHeaderLabel.sizeToFit()
    
    // SEARCH BAR
        let optionsView = UIView()
        addSubview(optionsView)
        optionsView.anchor(top: postCountHeaderView.bottomAnchor, left: leftAnchor, bottom: postContainerView.bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        optionsView.backgroundColor = UIColor.backgroundGrayColor()
        optionsView.addSubview(searchBar)
        searchBar.delegate = self
        searchBar.searchBarView.backgroundColor = UIColor.clear
        searchBar.alpha = 0.9
        searchBar.showEmoji = true
        searchBar.anchor(top: optionsView.topAnchor, left: optionsView.leftAnchor, bottom: optionsView.bottomAnchor, right: optionsView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        searchBar.navSearchButton.tintColor = UIColor.darkGray
        
    
    }
    
    
    func setupTypeSegment(){
        searchSegment.selectedSegmentIndex = self.isFilteringFriends ? 0 : 1
        searchSegment.selectedSegmentTintColor = UIColor.ianLegitColor()
        searchSegment.addTarget(self, action: #selector(selectFetchType), for: .valueChanged)
        searchSegment.backgroundColor = .white
        searchSegment.tintColor = .white
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        searchSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
        searchSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(font: .avenirNextBold, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)
//        fetchTypeSegment.setTitleTextAttributes([NSAttributedString.Key.font: HeaderFontSizeDefault], for: .normal)
    }
    
    @objc func selectFetchType(sender: UISegmentedControl) {
        self.isFilteringFriends = (sender.selectedSegmentIndex == 0)
        print("\(self.isFilteringFriends) : Filtering Friends | NewLocationHeader | Type Selected")
        self.delegate?.didTapFilterFriends(filteringFriends: self.isFilteringFriends)
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
    
    
    @objc func resetLocation(){
        guard let location = selectedLocation else {
            return
        }
        
        self.centerMapOnLocation(location: location)
    }
    
    func centerMapOnLocation(location: CLLocation?, radius: CLLocationDistance? = 0, closestLocation: CLLocation? = nil) {
        guard let location = location else {
            print("NO LOCATION | LocationHeader | centerMapOnLocation |")
            return}

        var hasLoc = self.mapView.annotations.contains { (annotation) -> Bool in
            return annotation.title == self.selectedName
        }
        
        if mapView.centerCoordinate.latitude == location.coordinate.latitude && mapView.centerCoordinate.longitude == location.coordinate.longitude && hasLoc {
            print("Map Already Loaded For \(location.coordinate)")
            return
        }
        
        var displayRadius: CLLocationDistance = radius == 0 ? regionRadius : radius!
        
        let coordinateRegion = MKCoordinateRegion.init(center: location.coordinate,
                                                                  latitudinalMeters: displayRadius, longitudinalMeters: displayRadius)
        //        mapView?.region = coordinateRegion

//        mapView.removeAnnotations(mapView.annotations)


                
        if !hasLoc {
            let annotation = MKPointAnnotation()
            let centerCoordinate = CLLocationCoordinate2D(latitude: (location.coordinate.latitude), longitude:(location.coordinate.longitude))
            annotation.coordinate = centerCoordinate
            annotation.title = self.selectedName
            mapView.addAnnotation(annotation)
//            print("LocationHeader | Add Map Pin | \(self.selectedName)")
        }
        
//        if self.mapView.annotations.count == 0 {
//            let annotation = MKPointAnnotation()
//            let centerCoordinate = CLLocationCoordinate2D(latitude: (location.coordinate.latitude), longitude:(location.coordinate.longitude))
//            annotation.coordinate = centerCoordinate
//            annotation.title = self.selectedName
//            mapView.addAnnotation(annotation)
//            print("LocationHeader | Add Map Pin | \(self.selectedName)")
//        }
//        else {
//            for annotation in self.mapView.annotations {
//                if annotation.title == self.selectedName {
//                    self.mapView.selectAnnotation(annotation, animated: true)
//                    print("LocationHeader | Select Map Pin | \(self.selectedName)")
//                }
//            }
//        }
        
        for annotation in self.mapView.annotations {
            if annotation.title == self.selectedName {
                self.mapView.selectAnnotation(annotation, animated: true)
//                print("LocationHeader | Select Map Pin | \(self.selectedName)")
            }
        }
        
//        print("centerMapOnLocation | \(location.coordinate) | Radius \(displayRadius) : LocationHeader")
        mapView.setRegion(coordinateRegion, animated: true)

    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if let annotation = view.annotation as? MapPin {
            print("Map Pin Selected | \(annotation.title) | \(annotation.postId) ")
        } else {
            print("ERROR Casting Annotation to MapPin | \(view.annotation)")
        }
        
        if let markerView = view as? MapPinMarkerView {
//            print("Map Pin Marker View Selected | \(markerView.annotation?.title)")
            markerView.markerTintColor = UIColor.red
        }
    }
    
    
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func refreshLocationDetails() {
        self.hasRestaurantLocation = false
        self.googlePlaceId = nil
        self.placeName = nil
        self.placeOpeningHours = nil
        self.placeOpeningSchedule = nil
        self.placePhoneNo = nil
        self.placeWebsite = nil
        self.placeGoogleRating = nil
        self.placeOpenNow = nil
        self.placeGoogleMapUrl = nil
    }
    
    
    func extractRestaurantInfo() {
        if let googleId = location?.locationGoogleID {
            if !googleId.isEmptyOrWhitespace() {
                hasRestaurantLocation = true
//                self.queryGooglePlaces(placeId: googleId)
            } else {
                hasRestaurantLocation = false
            }
        } else {
            hasRestaurantLocation = false
        }
    }
    
    
    func queryGooglePlaces(placeId: String?){
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
            self.selectedName = self.placeName
            self.placeOpeningHours = result["opening_hours"]["weekday_text"].arrayValue
            self.placeOpeningSchedule = result["opening_hours"]["periods"].arrayValue
            self.placePhoneNo = result["formatted_phone_number"].string ?? ""
            self.placeWebsite = result["website"].string ?? ""
            self.placeGoogleRating = result["rating"].double ?? 0
            
                
            self.placeGoogleMapUrl = result["url"].string!
            
            self.selectedLong = result["geometry"]["location"]["lng"].double ?? 0
            self.selectedLat = result["geometry"]["location"]["lat"].double ?? 0
            self.selectedLocation = CLLocation(latitude: self.selectedLat!, longitude: self.selectedLong!)
            self.selectedAdress = result["formatted_address"].string ?? ""

            
            self.locationAdressLabel.text = self.selectedAdress
            self.locationAdressLabel.sizeToFit()
            
            self.locationDistanceLabel.text = SharedFunctions.formatDistance(inputDistance: location?.distance)
            self.locationDistanceLabel.sizeToFit()
            
            self.refreshPlaceDetailLabels()
            
//            if (self.placePhoneNo == "") {
//                self.locationPhoneLabel.setTitle("No Location Phone", for: .normal)
//            } else {
//                self.locationPhoneLabel.setTitle("\(self.placePhoneNo!)", for: .normal)
//            }
            
        } else {
            print("Failed to extract Google Place Details")
        }
    }
    
    func refreshHeaderLabels() {
        if self.googlePlaceJSON?.count == 0 || self.googlePlaceJSON == nil {
            self.refreshPlaceDetailLabelsWithLocationOnly()
        } else {
            self.refreshPlaceDetailWithJSON()
        }
    }
    
    func refreshPlaceDetailWithJSON() {
        guard let json  =  self.googlePlaceJSON else {
            print("ERROR - No JSON : refreshPlaceDetailWithJSON")
            return
        }
        self.extractPlaceDetails(fetchedResults: json)
    }
    
    func refreshPlaceDetailLabels() {
        guard let googlePlaceJSON = self.googlePlaceJSON else {
            self.refreshPlaceDetailLabelsWithLocationOnly()
            return}
        guard let location = self.location else {return}
        locationNameLabel.text = self.selectedName
        
        setupPlaceOpenHours()
        
    // STAR RATING
        if (location.starRating != 0) {
            self.starRating.rating = location.starRating
            starRating.tintColor = starRating.rating >= 4 ? UIColor.ianLegitColor() : UIColor.selectedColor()
            self.starRating.isHidden = false
        } else {
            self.starRating.isHidden = true
        }
        
        let googleRating = self.placeGoogleRating ?? 0.0
        let fontColor = (googleRating >= 4) ? UIColor.red : UIColor.darkGray
        googleRatingButton.setTitleColor(fontColor, for: .normal)
        googleRatingButton.setTitle(" \(String(googleRating))", for: .normal)
        googleRatingButton.isHidden = (googleRating == 0.0)
        googleRatingButton.isUserInteractionEnabled = !googleRatingButton.isHidden
        googleRatingButton.sizeToFit()
        
        
    // EMOJIS
        self.emojiSummary.displayedEmojisCounts = self.emojiCounts

    // MAP
        self.resetLocation()
        
    // ADRESS
        self.locationAdressLabel.text = self.selectedAdress ?? "No Location Adress"
        
    // DISTANCE
        
        self.locationDistanceLabel.text = SharedFunctions.formatDistance(inputDistance: location.distance)
        self.locationDistanceLabel.sizeToFit()
        
    // POST COUNT
        self.postHeaderLabel.text = "\(self.postCount) \(UserSearchOptions[self.searchSegment.selectedSegmentIndex]) Posts"

//        if selectedAdress != nil && selectedName != nil {
//            // If User uses Google to input adress, it will produce a GooglePlaceID, but won't be a location
//            if (selectedName?.count)! > 1 && (selectedAdress?.count)! > 1 && selectedName == selectedAdress {
//                self.hasRestaurantLocation = false
//                guard let selectedLocation = self.selectedLocation else {return}
//                if let lat = selectedLocation.coordinate.latitude, let long = selectedLocation.coordinate.latitude {
//                    let gpsString = "\(String(lat)) , \(String(long))"
////                    self.locationNameLabel.text = selectedPost?.locationAdress
//                } else {
////                    self.locationNameLabel.text = selectedPost?.locationName
//                }
//                self.locationAdressLabel.text = self.selectedAdress
//            }
//        }
    }
    
    func refreshPlaceDetailLabelsWithLocationOnly() {
        guard let location = self.location else {
            print("ERROR - No Location : refreshPlaceDetailLabelsWithLocationOnly")
            return}
        locationNameLabel.text = location.locationName
        
        setupPlaceOpenHours()
        
    // STAR RATING
        if (self.locationRating != 0) {
            self.starRating.rating = location.starRating
            starRating.tintColor = starRating.rating >= 4 ? UIColor.ianLegitColor() : UIColor.selectedColor()
            self.starRating.isHidden = false
        } else {
            self.starRating.isHidden = true
        }
        
        let googleRating = self.placeGoogleRating ?? 0.0
        let fontColor = (googleRating >= 4) ? UIColor.red : UIColor.darkGray
        googleRatingButton.setTitleColor(fontColor, for: .normal)
        googleRatingButton.setTitle(" \(googleRating)", for: .normal)
        googleRatingButton.isHidden = (googleRating == 0.0)
        googleRatingButton.isUserInteractionEnabled = !googleRatingButton.isHidden
        googleRatingButton.sizeToFit()
        
        
    // EMOJIS
        self.emojiSummary.displayedEmojisCounts = self.emojiCounts

    // MAP
        self.resetLocation()
        
    // ADRESS
        self.locationAdressLabel.text = self.location?.locationAdress ?? "No Location Adress"
        
        
    // DISTANCE
        self.locationDistanceLabel.text = SharedFunctions.formatDistance(inputDistance: location.distance)
        self.locationDistanceLabel.sizeToFit()
        
    // POST COUNT
        self.postHeaderLabel.text = "\(self.postCount) Posts"

//        if selectedAdress != nil && selectedName != nil {
//            // If User uses Google to input adress, it will produce a GooglePlaceID, but won't be a location
//            if (selectedName?.count)! > 1 && (selectedAdress?.count)! > 1 && selectedName == selectedAdress {
//                self.hasRestaurantLocation = false
//                guard let selectedLocation = self.selectedLocation else {return}
//                if let lat = selectedLocation.coordinate.latitude, let long = selectedLocation.coordinate.latitude {
//                    let gpsString = "\(String(lat)) , \(String(long))"
////                    self.locationNameLabel.text = selectedPost?.locationAdress
//                } else {
////                    self.locationNameLabel.text = selectedPost?.locationName
//                }
//                self.locationAdressLabel.text = self.selectedAdress
//            }
//        }
    }

    func setupPlaceOpenHours() {
        
        if self.placeOpeningSchedule == nil {
            self.locationHoursHeightConstraint?.constant = 0
            self.hideLocationHours()
            return
        } else {
            self.locationHoursHeightConstraint?.constant = locationHoursHeight
        }
        
        
    // OPENING HOURS
        let today = Date()
        let myCalendar = Calendar(identifier: .gregorian)
        let weekDay = myCalendar.component(.weekday, from: today)
        
        var todayIndex: Int
        
        // Apple starts with Sunday at 1 to sat at 7. Google starts Sunday at 0 ends at 6
        todayIndex = (weekDay == 1) ? 0 : weekDay - 1
                        
        if self.placeOpeningHours! != [] {
            
        // Determine if Open
            guard let placeOpeningPeriods = self.placeOpeningSchedule as [JSON]? else {
                print("No Opening Period For Location \(self.location?.locationName)")
                return}
        
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
            
            
        // SET LOCATION HOUR LABEL
            
            // Set Opening Hour Label
            var googDayIndex: Int? = (todayIndex == 0) ? 6 : todayIndex - 1
            let todayHours = String(describing: (self.placeOpeningHours?[googDayIndex!])!)
//            var textColor = UIColor.init(hexColor: "028090")
            var textColor = UIColor.rgb(red: 68, green: 68, blue: 68)
            
            let openAttributedText = NSMutableAttributedString()
            
            if let open = self.placeOpenNow {
                textColor = open ? UIColor.mainBlue() : UIColor.red
            
                let todayHoursSplit = todayHours.components(separatedBy: ",")
                
                for (index,time) in todayHoursSplit.enumerated() {
//                            print("\(time)")
                    var attributedTime = NSMutableAttributedString()
                    if index != 0 {
                        var tempSpacing = NSMutableAttributedString(string: "\n   ", attributes: [NSAttributedString.Key.font: UIFont(name: "Poppins-Light", size: 14), NSAttributedString.Key.foregroundColor: textColor])
                        attributedTime.append(tempSpacing)
                    }
                    
                    var tempAttributedTime = NSMutableAttributedString(string: time, attributes: [NSAttributedString.Key.font: UIFont(name: "Poppins-Light", size: 14), NSAttributedString.Key.foregroundColor: textColor])
                    attributedTime.append(tempAttributedTime)
                    openAttributedText.append(attributedTime)
                }

                locationHoursLabel.attributedText = openAttributedText
                showLocHoursConstraint?.isActive = true
                noLocHoursConstraint?.isActive = false
                locationHoursLabel.sizeToFit()
                
                let openImage = #imageLiteral(resourceName: "open_icon").withRenderingMode(.alwaysOriginal)
                locationHoursIcon.setImage(self.placeOpenNow! ? openImage : UIImage(), for: .normal)
                var text = (self.placeOpenNow! ? "" : " CLOSED ")
                let headerTitle = NSAttributedString(string: text, attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(font: .avenirNextBold, size: 16)])
                locationHoursIcon.isHidden = false
                locationHoursIcon.setAttributedTitle(headerTitle, for: .normal)
                locationHoursIcon.sizeToFit()
                
                
            } else {
                self.hideLocationHours()
            }
            
        } else {
            // No Opening Hours from Google
//            self.locationHoursLabel.setTitle("No Location Hours", for: .normal)
            self.hideLocationHours()
            self.placeOpenNow = nil
        }
        
    }
    
    func hideLocationHours() {
        self.locationHoursLabel.text = "No Location Hours"
        locationHoursIcon.setTitle("", for: .normal)
        locationHoursIcon.sizeToFit()
        locationHoursIcon.isHidden = true
        showLocHoursConstraint?.isActive = false
        noLocHoursConstraint?.isActive = true
    }
    
    func filterContentForSearchText(searchText: String) {
        
    }
    
    func didTapSearchButton() {
        self.delegate?.didTapSearchButton()
    }
    
    func didTapAddTag(addTag: String) {
        self.delegate?.didTapAddTag(addTag: addTag)
    }
    
    func didRemoveTag(tag: String) {
        self.delegate?.didTapAddTag(addTag: tag)
    }
    
    func didRemoveLocationFilter(location: String) {
        
    }
    
    func didRemoveRatingFilter(rating: String) {
        
    }
    
    func didTapCell(tag: String) {
        
    }
    
    func handleRefresh() {
        
    }
    
    func didActivateSearchBar() {
        self.delegate?.didTapSearchButton()
    }
    
    func didTapGridButton() {
        self.toggleView()
    }
    
    func toggleView(){
        // 0 = Grid
        // 1 = List
        
        if (postFormatInd == 0) {
            self.didChangeToListView()
        } else if (postFormatInd == 1) {
            self.didChangeToGridView()
        }
    }
    
    func didChangeToListView(){
        print("Header ListViewController | Change to List View")
        self.delegate?.didChangeToPostView()
        self.postFormatInd = 1
    }
    
    func didChangeToGridView() {
        print("Header ListViewController | Change to Grid View")
        self.delegate?.didChangeToGridView()
        self.postFormatInd = 0
    }
    
    func didTapEmojiButton() {
        
    }
    
    func didTapEmojiBackButton() {
        
    }
    
    
    
}
