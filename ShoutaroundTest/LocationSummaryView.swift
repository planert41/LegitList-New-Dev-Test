//
//  LocationSummaryView.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/21/20.
//  Copyright © 2020 Wei Zou Ang. All rights reserved.
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

protocol LocationSummaryViewDelegate {
    func toggleMapFunction()
    func didTapLocationHours(hours: [JSON]?)
    func didTapPost(post: Post?)
    func activateAppleMap(post: Post?)
    func didTapLocation()
    func alert(title: String, message: String)

}



class LocationSummaryView: UIView {

    var delegate :LocationSummaryViewDelegate?

    
    // INPUT FROM DELEGATE
    var selectedPost: Post?{
        didSet{
            selectedLocation = selectedPost?.locationGPS
            selectedName = selectedPost?.locationName
            selectedAdress = selectedPost?.locationAdress
            // NEED TO GET AVERAGE RATING
//            starRating.rating = selectedPost?.rating ?? 0
            self.centerMapOnLocation(location: selectedLocation)
            self.googlePlaceId = selectedPost?.locationGooglePlaceID
            self.checkHasRestaurantLocation()
            self.updateLocationDistanceLabel()
        }
    }
    
    var isEmptyCell = false
    var showSelectedPostPicture: Bool = true
    var isFetchingPost = false
    
    // MAIN INPUT
    var googlePlaceId: String? = nil {
        didSet{
//            self.checkHasRestaurantLocation()
            // Google Place ID Exists
        }
    }
    
    let mapView = MKMapView()
    let mapPinReuseInd = "MapPin"
    let regionRadius: CLLocationDistance = 7500

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
    
    
    let locationButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "Geofence"), for: .normal)
        button.addTarget(self, action: #selector(showLocation), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()
    
    // Map Button
    lazy var mapButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        let mapImage = #imageLiteral(resourceName: "map").withRenderingMode(.alwaysTemplate)
        button.setImage(mapImage, for: .normal)
        button.tintColor = UIColor.ianLegitColor()
        button.addTarget(self, action: #selector(toggleMapFunction), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.white.withAlphaComponent(0.8).cgColor
        button.layer.cornerRadius = 10 / 2
        button.clipsToBounds = true
        return button
    }()
    
    // Map Button
    lazy var curLocButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        let mapImage = #imageLiteral(resourceName: "gpsmarker").withRenderingMode(.alwaysOriginal)
        button.setImage(mapImage, for: .normal)
//        button.tintColor = UIColor.ianLegitColor()
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(activateCurrentLocation), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.cornerRadius = 10 / 2
        button.clipsToBounds = true
        return button
    }()
    
    // MARK: - SELECTED OBJECTS

    
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
//            self.checkHasRestaurantLocation()
        }
    }
    
    var selectedLong: Double? = 0
    var selectedLat: Double? = 0
    var selectedName: String? {
        didSet {
            locationNameLabel.numberOfLines = (selectedName == selectedAdress) ? 1 : 0
            locationNameLabel.text = selectedName
            locationNameLabel.sizeToFit()
        }
    }
    var selectedAdress: String?
    
    // Filter Variables
    var viewFilter: Filter? = Filter.init(defaultSort: defaultRecentSort) {
        didSet{
//            setupNavigationItems()
        }
    }
    
    @objc func showLocation(){
        guard let location = selectedLocation else {
            return
        }
        
        self.centerMapOnLocation(location: location)
    }
    

    // Location Detail Items
    
    let locationDetailRowHeight: CGFloat = 30
    
    // Google Place Variables
    var hasRestaurantLocation: Bool = false

    var placeName: String?
    var placeOpeningHours: [JSON]?
    var placePhoneNo: String?
    var placeWebsite: String?
    var placeGoogleRating: Double?
    var placeOpenNow: Bool? = nil {
        didSet {
            if placeOpenNow == nil {
                locationHoursIcon.setTitle("", for: .normal)
                locationHoursIcon.sizeToFit()
                locationHoursIcon.isHidden = true
            } else {
                let openImage = #imageLiteral(resourceName: "open_icon").withRenderingMode(.alwaysOriginal)
                locationHoursIcon.setImage(self.placeOpenNow! ? openImage : UIImage(), for: .normal)
                var text = (self.placeOpenNow! ? "" : " CLOSED ")
                let headerTitle = NSAttributedString(string: text, attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(font: .avenirNextBold, size: 16)])
                locationHoursIcon.isHidden = false
                locationHoursIcon.setAttributedTitle(headerTitle, for: .normal)
                locationHoursIcon.sizeToFit()
            }
        }
    }
    var placeGoogleMapUrl: String?
    var placeDetailStackview = UIStackView()
    
    
    
    @objc func toggleMapFunction(){
        guard let post = selectedPost else {return}
        self.delegate?.toggleMapFunction()
//        self.delegate?.activateAppleMap(post: post)
    }
    
    @objc func activateAppleMapFunction(){
        guard let post = selectedPost else {return}
        self.delegate?.activateAppleMap(post: post)
    }
    
    var placeDetailViewHeight:NSLayoutConstraint?
    var hideLocationHours:NSLayoutConstraint?
    var hideActionBar: NSLayoutConstraint?

    
    lazy var locationNameLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(name: "Poppins-Bold", size: 26)
        label.backgroundColor = UIColor.clear
        label.isUserInteractionEnabled = true
        label.numberOfLines = 0
        return label
    }()
    
// LOCATION ADRESS
    lazy var locationAdressLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(font: .avenirNextDemiBold, size: 14)
        label.backgroundColor = UIColor.clear
        label.isUserInteractionEnabled = true
        label.numberOfLines = 0
        return label
    }()
    
    let locationDistanceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.mainBlue()
        label.textAlignment = NSTextAlignment.right
        return label
    }()
    
    
// LOCATION HOURS

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
    
    @objc func locationHoursIconTapped() {
        self.delegate?.didTapLocationHours(hours : self.placeOpeningHours)
    }
    
    let locationWebsiteButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "discover").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(activateBrowser), for: .touchUpInside)
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 14)
        return button
    }()
    
    let locationPhoneButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "phone").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(activatePhone), for: .touchUpInside)
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 14)
        return button
    }()
    
    let locationMapButton: UIButton = {
        let button = UIButton()
        let img = #imageLiteral(resourceName: "map_icon").withRenderingMode(.alwaysTemplate).resizeImageWith(newSize: CGSize(width: 30, height: 30))
        button.setImage(img, for: .normal)
        button.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(activateAppleMapFunction), for: .touchUpInside)
        button.titleLabel?.textColor = UIColor.ianLegitColor()
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 14)
        button.setTitle(" MAP", for: .normal)
        return button
    }()
    
    @objc func activatePhone(){
        print("Tapped Phone Icon \(self.placePhoneNo)")
        guard let url = URL(string: "tel://\(self.placePhoneNo!)") else {return}
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url)
            //UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    @objc func activateBrowser(){
        guard let url = URL(string: self.placeWebsite!) else {return}
        print("activateBrowser | \(url)")
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
// FILTER
    var friendFilterSegment = UISegmentedControl()
    let friendFilterOptions = ["Your Friends", "Community"]
    var isFilteringFriends: Bool = true
    
    var allPosts = [Post]()
    var friendPosts = [Post]()
    var otherPosts = [Post]()
    
    // COLLECTION VIEW PHOTOS
    let photoHeader = UILabel()
    let locationCellId = "locationCellId"
    let emptyCellId = "emptyCellId"

    lazy var photoCollectionView : UICollectionView = {
        let uploadLocationTagList = UploadLocationTagList()
        uploadLocationTagList.sectionInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadLocationTagList)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = UIColor(white: 0, alpha: 0.03)
        return cv
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
    
    // GOOGLE ITEMS
    
    
    var googlePlaceNames = [String?]()
    var googlePlaceIDs = [String]()
    var googlePlaceAdresses = [String]()
    var googlePlaceLocations = [CLLocation]()
    
    lazy var locationGoogleRatingLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Poppins-Bold", size: 14)
        label.layer.borderWidth = 0
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        label.isUserInteractionEnabled = true
        label.textColor = UIColor.ianLegitColor()
        return label
    }()
    
    
    let phoneContainerView = UIView()
    let websiteContainerView = UIView()
    let mapContainerView = UIView()
    let actionBarContainer = UIView()
    let placeDetailsView = UIView()

    
    // MARK: - INIT

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.rgb(red: 241, green: 241, blue: 241)
        self.backgroundColor = UIColor.ianWhiteColor()

            
    // LOCATION NAME
        addSubview(locationNameLabel)
        locationNameLabel.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        locationNameLabel.sizeToFit()
        locationNameLabel.isUserInteractionEnabled = true
        locationNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapLocation)))

            
// Place Details View
        addSubview(placeDetailsView)
        placeDetailsView.anchor(top: locationNameLabel.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        placeDetailsView.backgroundColor = UIColor.ianWhiteColor()
        placeDetailViewHeight = placeDetailsView.heightAnchor.constraint(greaterThanOrEqualToConstant: 55)
        placeDetailViewHeight?.isActive = true
        setupLocationDetails()
        
            
            
    // SECOND LINE - ACTION BAR
        addSubview(actionBarContainer)
        actionBarContainer.anchor(top: placeDetailsView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight:0, width: 0, height: 40)
        setupActionBar()


        
        
    // MAP VIEW
//        setupMap()
        mapView.isZoomEnabled = true
        mapView.showsUserLocation = true
        addSubview(mapView)
        mapView.anchor(top: actionBarContainer.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 200)
        mapView.isScrollEnabled = false

        let topDivider = UIView()
        addSubview(topDivider)
        topDivider.anchor(top: mapView.topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 3)
        topDivider.backgroundColor = UIColor.ianLegitColor()
        
        let bottomDivider = UIView()
        addSubview(bottomDivider)
        bottomDivider.anchor(top: mapView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 3)
        bottomDivider.backgroundColor = UIColor.ianLegitColor()
                
//        addSubview(trackingButton)
//        trackingButton.anchor(top: nil, left: nil, bottom: mapView.bottomAnchor, right: mapView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 15, width: 30, height: 30)
//        trackingButton.backgroundColor = UIColor.white.withAlphaComponent(0.75)
//        trackingButton.isHidden = false

//        addSubview(locationButton)
//        locationButton.anchor(top: nil, left: nil, bottom: mapView.bottomAnchor, right: mapView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 15, width: 30, height: 30)
//        locationButton.backgroundColor = UIColor.clear

//        addSubview(mapButton)
//        mapButton.anchor(top: nil, left: nil, bottom: mapView.bottomAnchor, right: mapView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 15, width: 30, height: 30)
//        mapButton.layer.cornerRadius = 30 / 2
//        mapButton.clipsToBounds = true
//        mapButton.backgroundColor = UIColor.white

        addSubview(curLocButton)
        curLocButton.anchor(top: nil, left: nil, bottom: mapView.bottomAnchor, right: mapView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 15, width: 30, height: 30)
        
    // OTHER PHOTOS
        
        let photoView = UIView()
        addSubview(photoView)
        photoView.anchor(top: mapView.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        addSubview(photoHeader)
        photoHeader.anchor(top: photoView.topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        photoHeader.font = UIFont(name: "Poppins-Bold", size: 18)
        photoHeader.font = UIFont(font: .avenirNextBold, size: 18)

        
        photoHeader.textColor = UIColor.black
        photoHeader.text = "More Posts"
        photoHeader.sizeToFit()
        
        addSubview(starRating)
        starRating.anchor(top: nil, left: nil, bottom: nil, right: photoView.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        starRating.centerYAnchor.constraint(equalTo: photoHeader.centerYAnchor).isActive = true
        
        setupFriendFilterSegment()
        addSubview(friendFilterSegment)
        friendFilterSegment.anchor(top: photoHeader.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 10, width: 0, height: 30)

        setupCollectionView()
        addSubview(photoCollectionView)
        photoCollectionView.anchor(top: friendFilterSegment.bottomAnchor, left: leftAnchor, bottom: photoView.bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 250)
        
        
    }
    
    
    @objc func didTapLocation(){
        self.delegate?.didTapLocation()
    }
    
    let actionBarColor = UIColor.black

    func setupActionBar() {
            hideActionBar = actionBarContainer.heightAnchor.constraint(equalToConstant: 0)
            
    //        let locationStackView = UIStackView(arrangedSubviews: [locationPhoneButton, locationWebsiteButton,locationMapButton])
            let locationStackView = UIStackView(arrangedSubviews: [phoneContainerView, websiteContainerView,mapContainerView])

            locationStackView.spacing = 0
            locationStackView.distribution = .fillEqually
            actionBarContainer.addSubview(locationStackView)
            locationStackView.anchor(top: actionBarContainer.topAnchor, left: actionBarContainer.leftAnchor, bottom: actionBarContainer.bottomAnchor, right: actionBarContainer.rightAnchor, paddingTop: 0, paddingLeft: 2, paddingBottom: 0, paddingRight: 2, width: 0, height: 0)
            
            locationStackView.layer.borderColor = actionBarColor.cgColor
            locationStackView.layer.borderWidth = 1
            locationStackView.layer.cornerRadius = 5
            locationStackView.layer.masksToBounds = true
            locationStackView.clipsToBounds = true

//            let borderColor = UIColor.rgb(red: 221, green: 221, blue: 221).cgColor
            let borderColor = actionBarColor.withAlphaComponent(0.5).cgColor

            phoneContainerView.layer.borderColor = borderColor
            phoneContainerView.layer.borderWidth = 1
            
            websiteContainerView.layer.borderColor = borderColor
            websiteContainerView.layer.borderWidth = 1
            
            mapContainerView.layer.borderColor = borderColor
            mapContainerView.layer.borderWidth = 1
            
            phoneContainerView.addSubview(locationPhoneButton)
            locationPhoneButton.anchor(top: phoneContainerView.topAnchor, left: phoneContainerView.leftAnchor, bottom: phoneContainerView.bottomAnchor, right: phoneContainerView.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            
            websiteContainerView.addSubview(locationWebsiteButton)
            locationWebsiteButton.anchor(top: websiteContainerView.topAnchor, left: websiteContainerView.leftAnchor, bottom: websiteContainerView.bottomAnchor, right: websiteContainerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            
            mapContainerView.addSubview(locationMapButton)
            locationMapButton.anchor(top: mapContainerView.topAnchor, left: mapContainerView.leftAnchor, bottom: mapContainerView.bottomAnchor, right: mapContainerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
            
    //        let actionBarTopDivider = UIView()
    //        actionBarContainer.addSubview(actionBarTopDivider)
    //        actionBarTopDivider.anchor(top: actionBarContainer.topAnchor, left: actionBarContainer.leftAnchor, bottom: nil, right: actionBarContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
    //        actionBarTopDivider.backgroundColor = UIColor.rgb(red: 221, green: 221, blue: 221)
    //
    //        let actionBarMidDivider = UIView()
    //        actionBarContainer.addSubview(actionBarMidDivider)
    //        actionBarMidDivider.anchor(top: actionBarContainer.topAnchor, left: actionBarContainer.centerXAnchor, bottom: actionBarContainer.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 1, height: 0)
    //        actionBarMidDivider.backgroundColor = UIColor.rgb(red: 221, green: 221, blue: 221)
    //
    //        let actionBarBottomDivider = UIView()
    //        actionBarContainer.addSubview(actionBarBottomDivider)
    //        actionBarBottomDivider.anchor(top: nil, left: actionBarContainer.leftAnchor, bottom: actionBarContainer.bottomAnchor, right: actionBarContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
    //        actionBarBottomDivider.backgroundColor = UIColor.rgb(red: 221, green: 221, blue: 221)
    //
    //        actionBarContainer.addSubview(locationPhoneButton)
    //        locationPhoneButton.anchor(top: actionBarContainer.topAnchor, left: actionBarContainer.leftAnchor, bottom: actionBarContainer.bottomAnchor, right: actionBarContainer.centerXAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 0, height: 0)
    //
    //        actionBarContainer.addSubview(locationWebsiteButton)
    //        locationWebsiteButton.anchor(top: actionBarContainer.topAnchor, left: actionBarContainer.centerXAnchor, bottom: actionBarContainer.bottomAnchor, right: actionBarContainer.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 0, height: 0)
    //
                
                
    }
    
    func setupLocationDetails() {

        // FIRST LINE - DISTANCE LABEL
            placeDetailsView.addSubview(locationDistanceLabel)
            locationDistanceLabel.anchor(top: nil, left: nil, bottom: placeDetailsView.bottomAnchor, right: placeDetailsView.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 10, width: 0, height: 0)
            
        // PLACE ADRESS
            placeDetailsView.addSubview(locationAdressLabel)
            locationAdressLabel.anchor(top: nil, left: placeDetailsView.leftAnchor, bottom: placeDetailsView.bottomAnchor, right: locationDistanceLabel.leftAnchor, paddingTop: 10, paddingLeft: 15, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
            
        // SECOND LINE - LOCATION HOURS
            placeDetailsView.addSubview(locationHoursView)
            locationHoursView.anchor(top: placeDetailsView.topAnchor, left: placeDetailsView.leftAnchor, bottom: locationAdressLabel.topAnchor, right: placeDetailsView.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
            hideLocationHours = locationHoursView.heightAnchor.constraint(equalToConstant: 0)

            locationHoursView.addSubview(locationHoursIcon)
            locationHoursIcon.anchor(top: nil, left: locationHoursView.leftAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            locationHoursIcon.centerYAnchor.constraint(equalTo: locationHoursView.centerYAnchor).isActive = true
            
            locationHoursView.addSubview(locationHoursLabel)
            locationHoursLabel.anchor(top: nil, left: locationHoursIcon.rightAnchor, bottom: nil, right: locationHoursView.rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)
            locationHoursLabel.centerYAnchor.constraint(equalTo: locationHoursIcon.centerYAnchor).isActive = true
            locationHoursLabel.topAnchor.constraint(lessThanOrEqualToSystemSpacingBelow: locationHoursView.topAnchor, multiplier: 1).isActive = true
            locationHoursLabel.bottomAnchor.constraint(lessThanOrEqualToSystemSpacingBelow: locationHoursView.bottomAnchor, multiplier: 1).isActive = true

            locationHoursLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(locationHoursIconTapped)))
    }
    
    
    
    
    func updateLocationDetails(){
        // HAS RESTAURAT
        if hasRestaurantLocation{
            print("\(self.googlePlaceId) | Google Location Exist| updateLocationDetails")
            self.populatePlaceDetails(placeId: googlePlaceId)
            self.fetchPostForPostLocation(placeId: googlePlaceId!)
            self.formatDetailView()
            
        } else {
            print("(\(self.selectedLat), \(self.selectedLong)) | No Google Location| updateLocationDetails")
            self.formatDetailView()
//            setupNoLocationView()
            
        // Google Search For Nearby Restaurants
//            self.googleLocationSearch(GPSLocation: CLLocation(latitude: self.selectedLat!, longitude: self.selectedLong!))
        // Search For All Posts within Location
            self.fetchPostWithLocation(location: CLLocation(latitude: self.selectedLat!, longitude: self.selectedLong!))
        }
    }
    
    
    func viewWillAppear(_ animated: Bool) {
        
        print("viewWillAppear")
        

        
    }
    
    
    
    
    
    func formatDetailView(){

        print("formatDetailView | hasRestaurantLocation | \(hasRestaurantLocation) ", hasRestaurantLocation ? "Show Location Hours and Phone" : "Show Suggested Locations")
//        self.hideLocationHours?.isActive = !hasRestaurantLocation
        self.locationHoursView.isHidden = !hasRestaurantLocation
        self.hideActionBar?.isActive = !hasRestaurantLocation
        placeDetailViewHeight?.constant = !hasRestaurantLocation ? 80 : 80

    }

    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

extension LocationSummaryView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, LocationOtherPostCellDelegate, TestGridPhotoCellDelegate {
   
    
    func fetchPostForPostLocation(placeId:String){
        
        self.clearAllPosts()
        
        if placeId != "" {
            self.fetchPostWithGooglePlaceID(googlePlaceID: placeId)
        } else if (self.selectedLat != 0 &&  self.selectedLong != 0) {
            self.fetchPostWithLocation(location: CLLocation(latitude: self.selectedLat!, longitude: self.selectedLong!))
        } else {
            print("Error Fetching Post based on this location")
//            self.alert(title: "Error", message: "Error Fetching Post based on this location")
        }
        
        
    }
    
    func fetchPostWithLocation(location: CLLocation){
        
        var filterRange = 500.0
        
        print("No Google Place ID. Searching Posts by Location: ", location)
        if isFetchingPost {
            print("     Pause Fetching | fetchPostWithLocation | \(isFetchingPost) IsFetching")
            return
        }
        isFetchingPost = true
        Database.fetchAllPostWithLocation(location: location, distance: filterRange) { (fetchedPosts, fetchedPostIds) in
            print("Fetched Post with Location: \(location) : \(fetchedPosts.count) Posts")
            self.allPosts = fetchedPosts
//            self.averageRating(posts: self.allPosts)
            self.filterSortFetchedPosts()
            self.isFetchingPost = false
        }

    }
    
    func fetchPostWithGooglePlaceID(googlePlaceID: String){
        print("Searching Posts by Google Place ID: ", googlePlaceID)
        if isFetchingPost {
            print("     Pause Fetching | fetchPostWithGooglePlaceID | \(isFetchingPost) IsFetching")
            return
        }
        isFetchingPost = true
        Database.fetchAllPostWithGooglePlaceID(googlePlaceId: googlePlaceID) { (fetchedPosts, fetchedPostIds) in
            print("Fetching Post with googlePlaceId: \(googlePlaceID) : \(fetchedPosts.count) Posts")
            self.allPosts = fetchedPosts
//            self.averageRating(posts: self.allPosts)
            self.filterSortFetchedPosts()
            self.isFetchingPost = false
        }
    }
    
    func clearAllPosts(){
        self.allPosts.removeAll()
        self.friendPosts.removeAll()
        self.otherPosts.removeAll()
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
        self.starRating.isHidden = (totalRatingCount == 0 || self.starRating.isHidden)

    }
    
    func filterSortFetchedPosts(){
        
        // Filter Posts
        // Not Filtering for Location and Range/Distances
        Database.filterPostsNew(inputPosts: self.allPosts, postFilter: self.viewFilter) { (filteredPosts) in
            Database.sortPosts(inputPosts: filteredPosts, selectedSort: self.viewFilter?.filterSort, selectedLocation: self.viewFilter?.filterLocation, completion: { (filteredPosts) in
                self.allPosts = []
                if let filteredPosts = filteredPosts {
                    self.allPosts = filteredPosts
                }
                
                // Take out current post image
                if !self.showSelectedPostPicture {
                    var oldCount = self.allPosts.count
                    self.allPosts = self.allPosts.filter({ (post) -> Bool in
                        return post.id != self.selectedPost?.id
                    })
                    print("Remove Selected Post Pic | \(self.selectedPost?.locationName) | \(self.showSelectedPostPicture) | \(oldCount - self.allPosts.count) Post Filtered | LocationSummaryView")
                }
                
                self.separatePosts()
                print("  ~ Finish Filter and Sorting Post | \(self.isEmptyCell) Empty | \(self.allPosts.count) All| \(self.friendPosts.count) Friend | \(self.otherPosts.count) Other")
                self.photoCollectionView.reloadData()
                self.photoCollectionView.layoutIfNeeded()

            })
        }
        
    }
    
    func checkEmptyCell() {
        if self.isFilteringFriends {
            isEmptyCell = self.friendPosts.count == 0
            self.averageRating(posts: self.friendPosts)
        } else {
            isEmptyCell = self.otherPosts.count == 0
            self.averageRating(posts: self.otherPosts)
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
        
        self.checkEmptyCell()
        
//        Database.countEmojis(posts: self.allPosts) { (emoji_counts) in
//            self.allPostEmojiCounts = emoji_counts
//        }
//
//        Database.countEmojis(posts: self.friendPosts) { (emoji_counts) in
//            self.friendPostemojiCounts = emoji_counts
//        }
//        self.updateEmojiArray()
    }
    
    
    
    
    func setupCollectionView(){

        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 5
        layout.scrollDirection = .horizontal
//        layout.estimatedItemSize = CGSize(width: 100, height: 140)
        photoCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        photoCollectionView.backgroundColor = UIColor.legitColor().withAlphaComponent(0.8)
        photoCollectionView.backgroundColor = UIColor.clear
        photoCollectionView.backgroundColor = UIColor.ianWhiteColor()
//        photoCollectionView.register(LocationOtherPostCell.self, forCellWithReuseIdentifier: locationCellId)
        photoCollectionView.register(TestHomePhotoCell.self, forCellWithReuseIdentifier: locationCellId)
        photoCollectionView.register(EmptyPhotoGridCell.self, forCellWithReuseIdentifier: emptyCellId)
        photoCollectionView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        photoCollectionView.showsHorizontalScrollIndicator = false
        photoCollectionView.isScrollEnabled = true
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isEmptyCell {
            print("Location Other Post | \(isEmptyCell) Empty")
            return 1
        }
        else if self.isFilteringFriends
        {
            print("Location Other Post | Friends | \(friendPosts.count)")
            return friendPosts.count
        }
        else {
            print("Location Other Post | Others | \(otherPosts.count)")
            return otherPosts.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var displayPost: Post? = nil


        if isEmptyCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emptyCellId, for: indexPath) as! EmptyPhotoGridCell
//            print("Empty Cell - \(isEmptyCell) | cellForItemAt | LocationSummaryView")
            return cell
        } else {
            
            if indexPath.row >= (isFilteringFriends ? friendPosts.count : otherPosts.count) {
                displayPost = nil
                print("NO POST | ")
            } else {
                displayPost = (isFilteringFriends ? friendPosts[indexPath.row] : otherPosts[indexPath.row])
            }
            
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: locationCellId, for: indexPath) as! LocationOtherPostCell
//            cell.post = displayPost
//            cell.backgroundColor = UIColor.ianWhiteColor()
//            cell.delegate = self
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: locationCellId, for: indexPath) as! TestHomePhotoCell
            cell.delegate = self
            cell.showDistance = false
            cell.loadFirstPicOnly = true
            cell.post = displayPost
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
        }

    }
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if isEmptyCell {
            return CGSize(width: self.frame.width, height: 140)

        } else {
//            return CGSize(width: 100, height: 140)
            let width = (self.frame.width - 30 - 15) / 2

            let height = (width + 40)
            return CGSize(width: width, height: height)
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    
    func didTapPost(post: Post?) {
        self.delegate?.didTapPost(post: post)
    }
    
    func didTapPicture(post:Post) {
        self.delegate?.didTapPost(post: post)
    }
    
    func didTapListCancel(post:Post) {
        
    }
    
    func didTapUser(post: Post) {
        self.delegate?.didTapPost(post: post)
    }

    
    
    func setupFriendFilterSegment(){
        friendFilterSegment = UISegmentedControl(items: friendFilterOptions)
        friendFilterSegment.addTarget(self, action: #selector(selectFriendSort), for: .valueChanged)
        friendFilterSegment.selectedSegmentIndex = self.isFilteringFriends ? 0 : 1
        friendFilterSegment.isUserInteractionEnabled = true
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        friendFilterSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
        friendFilterSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)
        
        friendFilterSegment.backgroundColor = .white
        friendFilterSegment.tintColor = .ianLightGrayColor()
    }
    
    @objc func selectFriendSort(sender: UISegmentedControl) {
        self.isFilteringFriends = (sender.selectedSegmentIndex == 0)
        self.checkEmptyCell()
        self.updateScopeBarCount()
        self.photoCollectionView.reloadData()
        self.photoCollectionView.layoutIfNeeded()
        print("Selected Friend Filter | \(self.isFilteringFriends) - Friends Only Filter ")

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
        
//        self.photoHeader.text = (self.otherPosts.count + self.friendPosts.count == 0) ? "" : "More Posts"
    }
        

    
    
}

extension LocationSummaryView: MKMapViewDelegate, GMSMapViewDelegate {
    
    func centerMapOnLocation(location: CLLocation?, radius: CLLocationDistance? = 0, closestLocation: CLLocation? = nil) {
        guard let location = location else {
            print("centerMapOnLocation | NO LOCATION")
            return}
        
        var displayRadius: CLLocationDistance = radius == 0 ? regionRadius : radius!
        
        let coordinateRegion = MKCoordinateRegion.init(center: location.coordinate,
                                                                  latitudinalMeters: displayRadius, longitudinalMeters: displayRadius)
        //        mapView?.region = coordinateRegion
        print("centerMapOnLocation | \(location.coordinate) | Radius \(displayRadius)")
        mapView.setRegion(coordinateRegion, animated: true)
                
        let annotations = mapView.annotations.filter({ !($0 is MKUserLocation) })
        print("PRE COUNT ", self.mapView.annotations.count)

        mapView.removeAnnotations(annotations)
        
        print("COUNT ", self.mapView.annotations.count)
        
        let annotation = MKPointAnnotation()
        let centerCoordinate = CLLocationCoordinate2D(latitude: (location.coordinate.latitude), longitude:(location.coordinate.longitude))
        annotation.coordinate = centerCoordinate
        annotation.title = self.selectedName
        mapView.addAnnotation(annotation)
        print("LocationSummaryView | Add Map Pin | \(self.selectedName)")
        if annotation.title == self.selectedName {
            self.mapView.selectAnnotation(annotation, animated: true)
            print("LocationSummaryView | Select Map Pin | \(self.selectedName)")
        }
        
//        if self.mapView.annotations.count == 0 {
//            let annotation = MKPointAnnotation()
//            let centerCoordinate = CLLocationCoordinate2D(latitude: (location.coordinate.latitude), longitude:(location.coordinate.longitude))
//            annotation.coordinate = centerCoordinate
//            annotation.title = self.selectedName
//            mapView.addAnnotation(annotation)
//            print("LocationSummaryView | Add Map Pin | \(self.selectedName)")
//        } else {
//            for annotation in self.mapView.annotations {
//                if annotation.title == self.selectedName {
//                    self.mapView.selectAnnotation(annotation, animated: true)
//                    print("LocationSummaryView | Select Map Pin | \(self.selectedName)")
//                }
//            }
//        }

    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if let annotation = view.annotation as? MapPin {
            print("Map Pin Selected | \(annotation.title) | \(annotation.postId) ")
        } else {
            print("ERROR Casting Annotation to MapPin | \(view.annotation)")
        }
        
        if let markerView = view as? MapPinMarkerView {
            print("Map Pin Marker View Selected | \(markerView.annotation?.title) ")
            markerView.markerTintColor = UIColor.red
        }
    }
    
    
    func mapView(_ mapView: GMSMapView, didTap overlay: GMSOverlay) {
        mapView.delegate = self
        print("Tapped")
        self.activateMap()
    }

    func activateMap() {
        SharedFunctions.openGoogleMaps(lat: selectedLat, long: selectedLong)
    }
    
    @objc func activateCurrentLocation() {
        if let cur = CurrentUser.currentLocation {
            let distanceInMeters = selectedLocation!.distance(from: cur) // result is in meters
            let center = cur.coordinate.middleLocationWith(location: (selectedLocation?.coordinate)!)
                        
            var radius = max(regionRadius, distanceInMeters) + 1000
            
            let coordinateRegion = MKCoordinateRegion.init(center: center, latitudinalMeters: radius, longitudinalMeters: radius)
            //        mapView?.region = coordinateRegion
            print("activateCurrentLocation | centerMapOnLocation | \(center) | Radius \(radius)")
            mapView.setRegion(coordinateRegion, animated: true)
            
//            self.centerMapOnLocation(location: CLLocation(latitude: center.latitude, longitude: center.longitude), radius: distanceInMeters)
        } else {
            self.delegate?.alert(title: "No Location", message: "Missing current user location for map ")
        }
    }
    
    
//    func geographicMidpoint(betweenCoordinates coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
//
//        guard coordinates.count > 1 else {
//            return coordinates.first ?? // return the only coordinate
//                CLLocationCoordinate2D(latitude: 0, longitude: 0) // return null island if no coordinates were given
//        }
//
//        var x = Double(0)
//        var y = Double(0)
//        var z = Double(0)
//
//        for coordinate in coordinates {
//            let lat = coordinate.latitude.toRadians()
//            let lon = coordinate.longitude.toRadians()
//            x += cos(lat) * cos(lon)
//            y += cos(lat) * sin(lon)
//            z += sin(lat)
//        }
//
//        x /= Double(coordinates.count)
//        y /= Double(coordinates.count)
//        z /= Double(coordinates.count)
//
//        let lon = atan2(y, x)
//        let hyp = sqrt(x * x + y * y)
//        let lat = atan2(z, hyp)
//
//        return CLLocationCoordinate2D(latitude: lat.toDegrees(), longitude: lon.toDegrees())
//    }
    
    // MAP
    func setupMap(){
//        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.mapType = MKMapType.standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = false
//        mapView.register(MapPinMarkerView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
//        mapView.register(ClusterMapPinMarkerView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        
//        trackingButton = MKUserTrackingButton(mapView: mapView)
//        //        button.layer.backgroundColor = UIColor(white: 1, alpha: 0.8).cgColor
//        trackingButton.layer.backgroundColor = UIColor.lightGray.withAlphaComponent(0.25).cgColor
//        trackingButton.layer.borderColor = UIColor.white.cgColor
//        trackingButton.layer.borderColor = UIColor.mainBlue().cgColor
//
//        trackingButton.layer.borderWidth = 1
//        trackingButton.layer.cornerRadius = 5
//        trackingButton.translatesAutoresizingMaskIntoConstraints = true
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
                if let lat = selectedPost?.locationGPS?.coordinate.latitude, let long = selectedPost?.locationGPS?.coordinate.latitude {
                    let gpsString = "\(String(lat)) , \(String(long))"
//                    self.locationNameLabel.text = selectedPost?.locationAdress
                } else {
//                    self.locationNameLabel.text = selectedPost?.locationName
                }
                self.locationAdressLabel.text = selectedPost?.locationAdress
            }
        }
        
        updateLocationDetails()
        
//        print("Restaurant Location Check: \(self.hasRestaurantLocation) : \(googlePlaceId)")
    }
    
    func updateLocationDistanceLabel(){
        locationDistanceLabel.text = ""

        guard let selectedLocation = self.selectedLocation else {return}
        guard let currentUserLocation = CurrentUser.currentLocation else {return}
        guard let selectedAdress = self.selectedAdress else {return}
        let distance = Double((selectedLocation.distance(from: currentUserLocation)))
        
        locationDistanceLabel.text = SharedFunctions.formatDistance(inputDistance: distance, expand: true, icons: true)
        locationDistanceLabel.adjustsFontSizeToFitWidth = true
        locationDistanceLabel.sizeToFit()
    }
    



}

extension LocationSummaryView {
    // GOOGLE LOCATION FUNCTIONS

        
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
    //            self.locationNameLabel.text = self.placeName
                
                self.selectedName = self.placeName
    //            self.navigationItem.title = self.placeName
                
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
                    self.locationHoursIcon.isHidden = (self.placeOpenNow == nil)

                    // Set Opening Hour Label
                    var googDayIndex: Int?
                    if todayIndex == 0 {
                        googDayIndex = 6
                    } else {
                        googDayIndex = todayIndex-1
                    }
                    
                    let todayHours = String(describing: (self.placeOpeningHours?[googDayIndex!])!)
                    var textColor = UIColor.init(hexColor: "028090")
                    
                    let openAttributedText = NSMutableAttributedString()
                    
                    if let open = self.placeOpenNow {
                        textColor = open ? UIColor.mainBlue() : UIColor.red
                    
                        let todayHoursSplit = todayHours.components(separatedBy: ",")
                        
                        for (index,time) in todayHoursSplit.enumerated() {
    //                            print("\(time)")
                            var attributedTime = NSMutableAttributedString()
                            if index != 0 {
                                var tempSpacing = NSMutableAttributedString(string: "\n   ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Poppins-Light", size: 14),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.rgb(red: 68, green: 68, blue: 68)]))
                                attributedTime.append(tempSpacing)
                            }
                            
                            var tempAttributedTime = NSMutableAttributedString(string: time, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Poppins-Light", size: 14),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.rgb(red: 68, green: 68, blue: 68)]))
                            attributedTime.append(tempAttributedTime)
                            openAttributedText.append(attributedTime)
                        }

                        self.locationHoursLabel.attributedText = openAttributedText
                        print(self.locationHoursLabel.text)
                        self.locationHoursLabel.sizeToFit()
                    } else {
                        self.locationHoursLabel.isHidden = (self.placeOpenNow == nil)
                        self.locationHoursIcon.isHidden = (self.placeOpenNow == nil)

                    }
                    
                } else {
                    // No Opening Hours from Google
                    self.locationHoursLabel.text = ""
                    self.placeOpenNow = nil
                }
                
                
                let invalidBackgroundColor = UIColor.lightGray
                let validBackgroundColor = UIColor.lightBackgroundGrayColor()

                
        // LOCATION PHONE
                self.placePhoneNo = result["formatted_phone_number"].string ?? "N/A"
                self.locationPhoneButton.setImage(#imageLiteral(resourceName: "fill1803Fill1804").withRenderingMode(.alwaysTemplate), for: .normal)
                self.locationPhoneButton.setTitle(self.placePhoneNo!, for: .normal)
                self.locationPhoneButton.tintColor = (self.placePhoneNo == "N/A") ? UIColor.gray : actionBarColor
                
                let tempPhoneString = NSMutableAttributedString(string: "  " + self.placePhoneNo!, attributes: [NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 12), NSAttributedString.Key.foregroundColor: self.locationPhoneButton.tintColor])
                self.locationPhoneButton.setAttributedTitle(tempPhoneString, for: .normal)

                self.locationPhoneButton.isUserInteractionEnabled = !(self.placePhoneNo == "N/A")
                self.locationPhoneButton.backgroundColor = (self.placePhoneNo == "N/A") ? invalidBackgroundColor : validBackgroundColor
                self.phoneContainerView.backgroundColor = (self.placePhoneNo == "N/A") ? invalidBackgroundColor : validBackgroundColor


        // LOCATION WEBSITE
                self.placeWebsite = result["website"].string ?? ""
                self.locationPhoneButton.isUserInteractionEnabled = !(self.placeWebsite == "")
                self.locationWebsiteButton.setImage(#imageLiteral(resourceName: "fill2901Fill2902").withRenderingMode(.alwaysTemplate), for: .normal)
                self.locationWebsiteButton.tintColor = (self.placeWebsite == "") ? UIColor.gray : actionBarColor
                let tempWebsiteString = NSMutableAttributedString(string: " Website", attributes: [NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 12), NSAttributedString.Key.foregroundColor:self.locationWebsiteButton.tintColor ])
                self.locationWebsiteButton.setAttributedTitle(tempWebsiteString, for: .normal)
                self.locationWebsiteButton.backgroundColor = (self.placeWebsite == "") ? invalidBackgroundColor : validBackgroundColor
                self.websiteContainerView.backgroundColor = (self.placeWebsite == "") ? invalidBackgroundColor : validBackgroundColor

//                self.websiteContainerView.setAttributedTitle(tempWebsiteString, for: .normal)


        // LOCATION MAP
                self.selectedAdress = result["formatted_address"].string ?? ""
                self.locationMapButton.tintColor = (self.selectedAdress == "") ? UIColor.gray : actionBarColor

                let tempMapString = NSMutableAttributedString(string: " Directions", attributes: [NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 12), NSAttributedString.Key.foregroundColor:self.locationMapButton.tintColor])
                self.locationMapButton.setAttributedTitle(tempMapString, for: .normal)
                self.locationMapButton.isUserInteractionEnabled = !(self.placePhoneNo == "N/A")
                self.locationMapButton.backgroundColor = (self.selectedAdress == "") ? invalidBackgroundColor : validBackgroundColor
                self.mapContainerView.backgroundColor = (self.selectedAdress == "") ? invalidBackgroundColor : validBackgroundColor


                
                self.placeGoogleRating = result["rating"].double ?? 0
                updateGoogleRatingLabel()
                
                
                //            print("placeGoogleRating: ", self.placeGoogleRating)
                
                self.placeGoogleMapUrl = result["url"].string!
                
                self.selectedLong = result["geometry"]["location"]["lng"].double ?? 0
                self.selectedLat = result["geometry"]["location"]["lat"].double ?? 0
                self.selectedLocation = CLLocation(latitude: self.selectedLat!, longitude: self.selectedLong!)
                
                self.selectedAdress = result["formatted_address"].string ?? ""
                self.locationAdressLabel.text = self.selectedAdress
                


                
            } else {
                print("Failed to extract Google Place Details")
            }
        }
    

        
        
        
        func updateGoogleRatingLabel(){
            if (self.placeGoogleRating ?? 0.0) > 0.0 {
                let ratingAttributedString = NSMutableAttributedString()
                
                let tempString = NSMutableAttributedString(string: "Google: " + String(self.placeGoogleRating ?? 0) + " ", attributes: [NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 14), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
                ratingAttributedString.append(tempString)
                
                let imageSize = CGSize(width: 20, height: 20)
                let bookmarkImage = NSTextAttachment()
                let bookmarkIcon = #imageLiteral(resourceName: "bookmark_selected").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
                bookmarkImage.bounds = CGRect(x: 0, y: (locationGoogleRatingLabel.font.capHeight - bookmarkIcon.size.height).rounded() / 2, width: bookmarkIcon.size.width, height: bookmarkIcon.size.height)
                bookmarkImage.image = bookmarkIcon

                let bookmarkImageString = NSAttributedString(attachment: bookmarkImage)
                ratingAttributedString.append(bookmarkImageString)

                locationGoogleRatingLabel.attributedText = ratingAttributedString
                locationGoogleRatingLabel.sizeToFit()
            } else {
                locationGoogleRatingLabel.text = ""
                locationGoogleRatingLabel.sizeToFit()
            }

        }
        
        func googleLocationSearch(GPSLocation: CLLocation){
            
            //        let dataProvider = GoogleDataProvider()
            let searchRadius: Double = 100
            var searchedTypes = ["restaurant"]
            var searchTerm = "restaurant"
            
            downloadRestaurantDetails(GPSLocation, searchRadius: searchRadius, searchType: searchTerm)
            
        }
        
    

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
                                    self.photoCollectionView.reloadData()
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
