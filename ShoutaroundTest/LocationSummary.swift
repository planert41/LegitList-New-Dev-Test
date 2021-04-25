//
//  LocationSummary.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/28/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import SwiftyJSON
import GooglePlaces
import Alamofire

class LocationSummary: UIViewController, MKMapViewDelegate {

    // MARK: - POST INPUTS

    var selectedPost: Post? {
        didSet {
            selectedLocation = selectedPost?.locationGPS
            selectedName = selectedPost?.locationName
            selectedAdress = selectedPost?.locationAdress
            self.googlePlaceId = selectedPost?.locationGooglePlaceID

        }
    }
    
    
    var selectedLocation: CLLocation? {
        didSet {
            self.centerMapOnLocation(location: selectedLocation)
        }
    }
    
    var selectedLong: Double? = 0
    var selectedLat: Double? = 0
    
    var selectedAdress: String?
    var selectedName: String? {
        didSet {
            if selectedName != nil {
                var nameString = selectedName!
            }
        }}
    
    var googlePlaceId: String? = nil {
        didSet{
            guard let placeId = googlePlaceId else {return}
            self.queryGooglePlaces(placeId: placeId)
            // Google Place ID Exists
        }
    }
    var placeGoogleMapUrl: String?

    
    // MARK: - DISPLAY OBJECTS

    
    let mapView = MKMapView()
    let mapPinReuseInd = "MapPin"
    let regionRadius: CLLocationDistance = 1000
    
    let mapButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "map").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.ianWhiteColor()
        button.backgroundColor = UIColor.ianBlackColor()
        button.addTarget(self, action: #selector(activateMap), for: .touchUpInside)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
//        button.addTarget(self, action: #selector(activatePhone), for: .touchUpInside)
        return button
    }()

    lazy var locationAdressLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = UIColor.ianGrayColor()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.isUserInteractionEnabled = true
        label.numberOfLines = 0
        label.textAlignment = NSTextAlignment.left
        return label
    }()
    
    let locationHoursLabel: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "checkmark_teal").withRenderingMode(.alwaysOriginal), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
//        button.addTarget(self, action: #selector(activatePhone), for: .touchUpInside)
        return button
    }()
    
    let locationPhoneLabel: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "phone").withRenderingMode(.alwaysOriginal), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
//        button.addTarget(self, action: #selector(activatePhone), for: .touchUpInside)
        return button
    }()
    
        let locationWebsiteLabel: UIButton = {
            let button = UIButton()
            button.setImage(#imageLiteral(resourceName: "website").withRenderingMode(.alwaysOriginal), for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
    //        button.addTarget(self, action: #selector(activatePhone), for: .touchUpInside)
            return button
        }()
    
    
    // MARK: - VIEW DID LOAD

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ianWhiteColor()
        
        setupMap()
        self.view.addSubview(mapView)
        mapView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 200)
        mapView.isScrollEnabled = false
        
        self.view.addSubview(mapButton)
        mapButton.anchor(top: mapView.topAnchor, left: nil, bottom: nil, right: mapView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 30, height: 30)
        
        let detailView = UIView()
        detailView.anchor(top: mapView.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 120)
        
// ADRESS
        let adressView = UIView()
        detailView.addSubview(adressView)
        adressView.anchor(top: detailView.topAnchor, left: detailView.leftAnchor, bottom: nil, right: detailView.rightAnchor, paddingTop: 12, paddingLeft: 12, paddingBottom: 0, paddingRight: 12, width: 0, height: 20)

        adressView.addSubview(locationAdressLabel)
        locationAdressLabel.anchor(top: adressView.topAnchor, left: adressView.leftAnchor, bottom: adressView.bottomAnchor, right: adressView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        locationAdressLabel.isUserInteractionEnabled = true
        locationAdressLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(activateMap)))

        
// OPEN TIME
        let locationHour = UIView()
        detailView.addSubview(locationHour)
        locationHour.anchor(top: adressView.bottomAnchor, left: adressView.leftAnchor, bottom: nil, right: adressView.rightAnchor, paddingTop: 15, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 25)
        
        locationHour.addSubview(locationHoursLabel)
        locationHoursLabel.anchor(top: locationHour.topAnchor, left: locationHour.leftAnchor, bottom: locationHour.bottomAnchor, right: locationHour.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        locationWebsiteLabel.addTarget(self, action: #selector(locationHoursIconTapped), for: .touchUpInside)

// LOCATION PHONE
        let locationPhone = UIView()
        detailView.addSubview(locationPhone)
        locationPhone.anchor(top: adressView.bottomAnchor, left: adressView.leftAnchor, bottom: nil, right: adressView.rightAnchor, paddingTop: 15, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 25)
        
        locationPhone.addSubview(locationWebsiteLabel)
        locationWebsiteLabel.anchor(top: locationPhone.topAnchor, left: nil, bottom: locationPhone.bottomAnchor, right: locationPhone.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        locationWebsiteLabel.widthAnchor.constraint(equalTo: locationWebsiteLabel.heightAnchor).isActive = true
        locationWebsiteLabel.addTarget(self, action: #selector(activateBrowser), for: .touchUpInside)

        locationPhone.addSubview(locationPhoneLabel)
        locationPhoneLabel.anchor(top: locationPhone.topAnchor, left: locationPhone.leftAnchor, bottom: locationPhone.bottomAnchor, right: locationWebsiteLabel.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        locationPhoneLabel.addTarget(self, action: #selector(activatePhone), for: .touchUpInside)

        
    }
    
    
    // MARK: - BUTTON DELEGATE FUNCTIONS
    
        // Location Detail Functions
        func locationHoursIconTapped(){
            print("LocationController | locationHoursIconTapped")

    //        var timeString = "" as String
    //        for time in self.placeOpeningHours! {
    //            timeString = timeString + time.string! + "\n"
    //        }
    //        self.alert(title: "Opening Hours", message: timeString)
            
                let presentedViewController = LocationHoursViewController()
                presentedViewController.hours = self.placeOpeningHours
                presentedViewController.setupViews()
                presentedViewController.providesPresentationContextTransitionStyle = true
                presentedViewController.definesPresentationContext = true
                presentedViewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                presentedViewController.modalTransitionStyle = .crossDissolve

                //presentedViewController.view.backgroundColor = UIColor.init(white: 0.4, alpha: 0.8)
                self.present(presentedViewController, animated: true, completion: nil)
            
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
            print("activateBrowser | \(url)")
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
        
        func activateURLBrowser(){
            guard let url = URL(string: self.placeGoogleMapUrl!) else {return}
            print("activateBrowser | \(url)")
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }

    // MARK: - MAP FUNCTIONS
    
    // MAP
    func setupMap(){
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.mapType = MKMapType.standard
        mapView.isZoomEnabled = false
        mapView.isScrollEnabled = false
        mapView.register(MapPinMarkerView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.register(ClusterMapPinMarkerView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
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
            
            if self.mapView.annotations.count == 0 {
                let annotation = MKPointAnnotation()
                let centerCoordinate = CLLocationCoordinate2D(latitude: (location.coordinate.latitude), longitude:(location.coordinate.longitude))
                annotation.coordinate = centerCoordinate
                annotation.title = self.selectedName
                mapView.addAnnotation(annotation)
                print("LocationController | Add Map Pin | \(self.selectedName)")
            } else {
                for annotation in self.mapView.annotations {
                    if annotation.title == self.selectedName {
                        self.mapView.selectAnnotation(annotation, animated: true)
                        print("LocationController | Select Map Pin | \(self.selectedName)")
                    }
                }
            }
    }
    
    
   /* func mapView(_ mapView: GMSMapView, didTap overlay: GMSOverlay) {
        mapView.delegate = self
        print("Map Tapped")
        self.activateMap()
    }*/
    
    // Google Place Variables
    var placeName: String?
    var placeOpeningHours: [JSON]?
    var placePhoneNo: String? {
        didSet {
            if (self.placePhoneNo == "") {
                self.locationPhoneLabel.setTitle("No Location Phone", for: .normal)
            } else {
                self.locationPhoneLabel.setTitle("\(self.placePhoneNo!)", for: .normal)
            }
        }
    }
    var placeWebsite: String?
    var placeGoogleRating: Double?
    var placeOpenNow: Bool? = nil {
        didSet {
            if placeOpenNow == nil {
                locationHoursLabel.setImage(UIImage(), for: .normal)
                locationHoursLabel.setTitle("", for: .normal)
                locationHoursLabel.sizeToFit()
            } else {
                
                guard let placeOpenNow = placeOpenNow else {return}
                
                let hoursImage = placeOpenNow ? #imageLiteral(resourceName: "checkmark_teal").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "close_icon").withRenderingMode(.alwaysOriginal)
                locationHoursLabel.setImage(hoursImage, for: .normal)

                var text = (self.placeOpenNow! ? "" : " CLOSED ")
            }
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
                                
                if self.placeOpeningHours! != [] {
                    
                    // Determine if Open
    //                var placeOpeningPeriods: [JSON]?
                    guard let placeOpeningPeriods = result["opening_hours"]["periods"].arrayValue as [JSON]? else {return}
                                        
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
                    
                    let openAttributedText = NSMutableAttributedString()
                    
                    if let open = self.placeOpenNow {
                        var displayHourText = ""
                        displayHourText.append(open ? "OPEN " : "CLOSE")
                        
                        let todayHoursSplit = todayHours.components(separatedBy: ",")
                        
                        for (index,time) in todayHoursSplit.enumerated() {
                            print("TODAY HOURS | \(time) | \(index)")
                            displayHourText.append(time)
                        }
                        
                        self.locationHoursLabel.setTitle(displayHourText, for: .normal)
                        self.locationHoursLabel.sizeToFit()
                    }
                    
                    else {
                        self.locationHoursLabel.setTitle("No Location Hours", for: .normal)
                    }
                    
                } else {
                    // No Opening Hours from Google
                    self.locationHoursLabel.setTitle("No Location Hours", for: .normal)
                    self.placeOpenNow = nil
                }
                
                
        
                self.placePhoneNo = result["formatted_phone_number"].string ?? ""

                

                self.placeWebsite = result["website"].string ?? ""
                self.locationWebsiteLabel.isHidden = self.placeWebsite == ""
                self.placeGoogleRating = result["rating"].double ?? 0
                
                    
                self.placeGoogleMapUrl = result["url"].string!
                
                self.selectedLong = result["geometry"]["location"]["lng"].double ?? 0
                self.selectedLat = result["geometry"]["location"]["lat"].double ?? 0
                self.selectedLocation = CLLocation(latitude: self.selectedLat!, longitude: self.selectedLong!)
                self.selectedAdress = result["formatted_address"].string ?? ""
                
                
                self.locationAdressLabel.text = self.selectedAdress
                self.locationAdressLabel.sizeToFit()
                
                if (self.placePhoneNo == "") {
                    self.locationPhoneLabel.setTitle("No Location Phone", for: .normal)
                } else {
                    self.locationPhoneLabel.setTitle("\(self.placePhoneNo!)", for: .normal)
                }
                
            } else {
                print("Failed to extract Google Place Details")
            }
        }
    
    
    

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
