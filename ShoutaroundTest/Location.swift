//
//  Location.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 11/10/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftyJSON
import GooglePlaces

class City {
    var cityName: String? = nil
    var postIds: [String]? = []
    var postCount: Int = 0
    var distance: Double? = nil
    var mostRecentDate: Date = Date(timeIntervalSince1970: 0)
    var locationGPS: CLLocation? = nil
    var emojis: [String: Int]? = [:]
    var locationCount: Int = 0
    var locationIds: [String]? = []


    init(locationId: String, dictionary: [String: Any]) {
        self.cityName = locationId as? String ?? ""
        let locationGPSText = dictionary["locationGPS"] as? String ?? ""
        let locationGPSTextArray = locationGPSText.components(separatedBy: ",")
        
        if locationGPSTextArray.count < 2 {
            self.locationGPS = nil
            self.distance = nil
        } else {
        self.locationGPS = CLLocation(latitude: Double(locationGPSTextArray[0])!, longitude: Double(locationGPSTextArray[1])!)
        
            if CurrentUser.currentLocation != nil {
                self.distance = Double((self.locationGPS?.distance(from: CurrentUser.currentLocation!))!)
            }
        }
        
        let secondsFrom1970 = dictionary["mostRecentDate"] as? Double ?? 0
        self.mostRecentDate = Date(timeIntervalSince1970: secondsFrom1970)

        let postIdArray = dictionary["postIds"] as? [String: Double] ?? [:]
        self.postIds = Array(postIdArray.keys)
        self.postCount = dictionary["postCount"] as? Int ?? 0
        
        let locationIdArray = dictionary["locationIds"] as? [String: Double] ?? [:]
        self.locationIds = Array(locationIdArray.keys)
        self.locationCount = dictionary["locationCount"] as? Int ?? 0
        
        self.emojis = dictionary["emojis"] as? [String: Int] ?? [:]
    }
    
}


class Location {
    var locationGPS: CLLocation? = nil
    var locationAdress: String? = nil

    var locationName: String? = nil
    var locationCity: String? = nil
    var locationState: String? = nil
    var locationCountry: String? = nil
    var locationPostalCode: String? = nil
    var locationSummaryID: String? = nil
    
    var locationGoogleID: String? = nil
    var locationGoogleTypes: [String]? = []
    var postIds: [String]? = []
    var distance: Double? = nil
    var imageUrl: String? = nil
    var emojis: [String: Int]? = [:]
    var ratingEmojis: [String: Int]? = [:]
    var mostRecentDate: Date = Date(timeIntervalSince1970: 0)
    var starRating: Double = 0.0
    var googleJson: JSON? = nil

    
    init(post: Post?) {
        guard let post = post else {
            print("ERROR - Location Init without post")
            return
        }
        self.locationName = post.locationName
        self.locationAdress = post.locationAdress
        self.locationSummaryID = post.locationSummaryID
        self.imageUrl = post.imageUrls[0]
        self.locationGPS = post.locationGPS
        self.locationGoogleID = post.locationGooglePlaceID

        for emoji in post.nonRatingEmoji {
            self.emojis![emoji] = 1
        }
        
        if let ratingEmoji = post.ratingEmoji {
            self.ratingEmojis![post.ratingEmoji ?? ""] = 1
        }
        self.starRating = Double(post.rating ?? 0)
        self.postIds?.append(post.id!)
        self.mostRecentDate = post.creationDate
        if CurrentUser.currentLocation != nil {
            self.distance = Double((self.locationGPS?.distance(from: CurrentUser.currentLocation!))!)
        }
    }
    
    init(locationId: String, dictionary: [String: Any]) {

        self.locationGoogleID = locationId
        self.locationName = dictionary["locationName"] as? String ?? ""
        self.locationAdress = dictionary["locationAdress"] as? String ?? ""
        self.locationSummaryID = dictionary["locationCity"] as? String ?? ""
        self.imageUrl = dictionary["imageUrl"] as? String ?? ""
        self.emojis = dictionary["emojis"] as? [String: Int] ?? [:]
        self.ratingEmojis = dictionary["ratingEmojis"] as? [String: Int] ?? [:]
        self.starRating = dictionary["rating"] as? Double ?? 0.0
        self.googleJson = JSON(dictionary["googleJson"]) as? JSON? ?? nil

        let locationGPSText = dictionary["locationGPS"] as? String ?? ""
        let locationGPSTextArray = locationGPSText.components(separatedBy: ",")
        
        if locationGPSTextArray.count < 2 {
            self.locationGPS = nil
            self.distance = nil
        } else {
        self.locationGPS = CLLocation(latitude: Double(locationGPSTextArray[0])!, longitude: Double(locationGPSTextArray[1])!)
        
            if CurrentUser.currentLocation != nil {
                self.distance = Double((self.locationGPS?.distance(from: CurrentUser.currentLocation!))!)
            }
        }
        
        let secondsFrom1970 = dictionary["mostRecentDate"] as? Double ?? 0
        self.mostRecentDate = Date(timeIntervalSince1970: secondsFrom1970)

        let postIdArray = dictionary["postIds"] as? [String: Double] ?? [:]
        self.postIds = Array(postIdArray.keys)

    }
    
    init(coordinates: CLLocation? = nil, locationName: String? = nil, locationAdress: String? = nil){
        self.locationGPS = coordinates
        self.locationName = locationName
        self.locationAdress = locationAdress
    }
    
    init(locationPlaceMark: CLPlacemark?) {
        guard let pm = locationPlaceMark else {
            print("Location Init | Error | No Apple Placemark")
            return
        }
        
        self.locationGPS = pm.location
        self.locationName = pm.name ?? ""
        
        if let _ = pm.locality {
            self.locationCity = pm.locality
        } else if let _ = pm.subAdministrativeArea {
            self.locationCity = pm.subAdministrativeArea
        } else {
            self.locationCity = ""
        }
        
        self.locationState = pm.administrativeArea ?? ""
        self.locationCountry = pm.country ?? ""
        self.locationPostalCode = pm.postalCode ?? ""
        
        var adressString = self.locationName
        adressString = adressString! + ", " + self.locationCity!
        adressString = adressString! + ", " + self.locationState! + " " + self.locationPostalCode!
        adressString = adressString! + ", " + self.locationCountry!
        
        self.locationAdress = adressString
        if let _ = pm.isoCountryCode {
            self.locationSummaryID = self.locationCity! + ", " + self.locationState! + ", " + pm.isoCountryCode!
        } else {
            self.locationSummaryID = nil
        }
    
    }
    
    init(googleLocationJSON: JSON?) {
        guard let result = googleLocationJSON else {
            print("No Location JSON | ERROR")
            return
        }
        
        guard let postLatitude = result["geometry"]["location"]["lat"].double else {return}
        guard let postLongitude = result["geometry"]["location"]["lng"].double else {return}
        let locationGPStempcreate = CLLocation(latitude: postLatitude, longitude: postLongitude)
        
        self.locationGPS = locationGPStempcreate
        self.locationName = result["name"].string
        
        if let _ = result["formatted_address"].string{
            self.locationAdress = result["formatted_address"].string
        } else if let _ = result["vicinity"].string {
            self.locationAdress = result["vicinity"].string
        }
                
        if let placeType = result["types"].arrayObject as? [String] {
            self.locationGoogleTypes = placeType
        }
        
        self.locationGoogleID = result["place_id"].string
        
        // City. Looks for city name in locality first, then the other admin levels
        
        for subJson in result["address_components"].arrayValue where (subJson["types"][0].string?.contains("locality"))! {
            self.locationCity = subJson["long_name"].string
        }
        if self.locationCity == nil {
            for subJson in result["address_components"].arrayValue where (subJson["types"][0].string?.contains("administrative_area_level_2"))! {
                self.locationCity = subJson["long_name"].string
            }
        }
        if self.locationCity == nil {
            for subJson in result["address_components"].arrayValue where (subJson["types"][0].string?.contains("administrative_area_level_3"))! {
                self.locationCity = subJson["long_name"].string
            }
        }
        if self.locationCity == nil {
            self.locationCity = ""
        }
        
        
        for subJson in result["address_components"].arrayValue where (subJson["types"][0].string?.contains("administrative_area_level_1"))! {
            self.locationState = subJson["short_name"].string
        }

        
        for subJson in result["address_components"].arrayValue where (subJson["types"][0].string?.contains("country"))! {
            self.locationCountry = subJson["long_name"].string
            
            let city = self.locationCity ?? ""
            let state = self.locationState ?? ""

            self.locationSummaryID = city + ", " + state + ", " + subJson["short_name"].string!
        }
        
        for subJson in result["address_components"].arrayValue where (subJson["types"][0].string?.contains("postal_code"))! {
            self.locationPostalCode = subJson["long_name"].string
        }
        
    }
    
    
    init(gmsPlace: GMSPlace?) {
        guard let place = gmsPlace else {
            print("No Location GMSPlace | ERROR")
            return
        }
        
        let tempLocation = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        
        self.locationGPS = tempLocation
        self.locationName = place.name
        
        self.locationAdress = place.formattedAddress
        self.locationGoogleTypes = place.types
        self.locationGoogleID = place.placeID
    }
    
    
    
}
