//
//  SharedFunctions.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 7/21/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import MapKit
import UserNotifications
import CryptoKit

class SharedFunctions {
    
    static func openGoogleMaps(lat: Double?, long: Double?){
        guard let lat = lat else {
            return
        }
        
        guard let long = long else {
            return
        }
        
        if (UIApplication.shared.canOpenURL(NSURL(string:"comgooglemaps://")! as URL)) {
            UIApplication.shared.openURL(NSURL(string:
                "comgooglemaps://?saddr=&daddr=\(lat),\(long)&directionsmode=driving")! as URL)
        } else if (UIApplication.shared.canOpenURL(NSURL(string:"https://www.google.com/maps/search/?api=1&query=\(lat),\(long)")! as URL)) {
            UIApplication.shared.openURL(NSURL(string:
                "https://www.google.com/maps/search/?api=1&query=\(lat),\(long)&directionsmode=driving")! as URL)
        } else {
            NSLog("Can't use comgooglemaps://");
        }
    }
    
    
    
    static func formatDate(inputDate: Date?, completion:@escaping (String?) ->()) {
        let formatter = DateFormatter()
        let calendar = NSCalendar.current
        var postDateString: String?
        
        guard let inputDate = inputDate else {
            print("Date Format Error: Empty Date")
            completion(nil)
            return
        }
        
    // SHOW YEARS IF >1 YEAR AGO
        let yearsAgo = calendar.dateComponents([.year], from: inputDate, to: Date())
        if (yearsAgo.year)! > 0 {
            formatter.dateFormat = "MMM d yy, h:mm a"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }
        
        let daysAgo =  calendar.dateComponents([.day], from: inputDate, to: Date())
    // If Post Date < 7 days ago, show < 7 days, else show date
        if (daysAgo.day)! <= 7 {
            postDateString = inputDate.timeAgoDisplay()
        } else {
            let dateDisplay = formatter.string(from: inputDate)
            postDateString = dateDisplay
        }
        
        completion(postDateString)
    }
    
    static func formatDistance(inputDistance: Double?, inputType: String? = "MI", expand: Bool = false, icons: Bool = false) ->(String?){
        
        // Default Post Distance is in Meters
        
        // ICON - Shows the emojis
        // EXPAND - Actually Shows Large Distances instead of hiding them
        
        guard let inputDistance = inputDistance else {
//            print("Distance Format Error: Empty Distance")
            return nil
        }
        
        // Convert Distance to Miles or Kilometers
        var initDistance = Measurement.init(value: inputDistance, unit: UnitLength.meters)
        var conversionUnit: UnitLength = (inputType == "KM") ? UnitLength.kilometers : UnitLength.miles
        initDistance.convert(to: conversionUnit)
        var distanceString: String?
        
        let n = NumberFormatter()
        n.maximumFractionDigits = 0
        n.minimumIntegerDigits = 1
        
        let m = MeasurementFormatter()
        m.numberFormatter = n
        
        
        if initDistance.value >= 500 {
            distanceString = icons ? "✈️" : ""
            
            if expand {
                distanceString! += m.string(from: initDistance)
            }
            
        } else if initDistance.value >= 50 {
            distanceString = icons ? "🚗" : "" 
            if expand {
                distanceString! += m.string(from: initDistance)
            }
            
        } else if initDistance.value >= 10 {
            distanceString = m.string(from: initDistance)
        } else {
            let n = NumberFormatter()
            n.maximumFractionDigits = 1
            n.minimumIntegerDigits = 1
            m.numberFormatter = n
            distanceString = m.string(from: initDistance)
        }
        return distanceString
    }
    
    
    //        /** Degrees to Radian **/
    static func degreeToRadian(angle:CLLocationDegrees) -> CGFloat {
        return (  (CGFloat(angle)) / 180.0 * CGFloat(M_PI)  )
    }
    
    //        /** Radians to Degrees **/
    static func radianToDegree(radian:CGFloat) -> CLLocationDegrees {
        return CLLocationDegrees(  radian * CGFloat(180.0 / M_PI)  )
    }
    
    static func middlePointOfListMarkers(listCoords: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
        
        var x = 0.0 as CGFloat
        var y = 0.0 as CGFloat
        var z = 0.0 as CGFloat
        
        for coordinate in listCoords{
            var lat:CGFloat = degreeToRadian(angle: coordinate.latitude)
            var lon:CGFloat = degreeToRadian(angle: coordinate.longitude)
            x = x + cos(lat) * cos(lon)
            y = y + cos(lat) * sin(lon)
            z = z + sin(lat)
        }
        
        x = x/CGFloat(listCoords.count)
        y = y/CGFloat(listCoords.count)
        z = z/CGFloat(listCoords.count)
        
        var resultLon: CGFloat = atan2(y, x)
        var resultHyp: CGFloat = sqrt(x*x+y*y)
        var resultLat:CGFloat = atan2(z, resultHyp)
        
        var newLat = radianToDegree(radian: resultLat)
        var newLon = radianToDegree(radian: resultLon)
        var result:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: newLat, longitude: newLon)
        
        return result
        
    }
    
    static func mapCenterForCoordinates(listCoords: [CLLocation]) -> MKCoordinateRegion {
        var maxLat = -200.0
        var maxLong = -200.0
        var minLat = Double.infinity
        var minLong = Double.infinity
        
        for post in listCoords {
            let location = post.coordinate
            if (location.latitude < minLat) {
                minLat = location.latitude;
            }
            
            if (location.longitude < minLong) {
                minLong = location.longitude;
            }
            
            if (location.latitude > maxLat) {
                maxLat = location.latitude;
            }
            
            if (location.longitude > maxLong) {
                maxLong = location.longitude;
            }
        }
        
        let center = CLLocationCoordinate2D(latitude: (maxLat + minLat)/2, longitude: (maxLong + minLong)/2)
        let mapFrame = MKCoordinateRegion(center: center, latitudinalMeters: maxLat - minLat, longitudinalMeters: maxLong - minLong)
        return mapFrame
    }

    
    
    static func openGoogleMaps(lat: Double?, long: Double?, completion:@escaping (Bool) ->()){
        
        guard let lat = lat else {
            print("Open Google Maps Error: Invalid Latitude")
            completion(false)
            return
        }
        
        guard let long = long else {
            print("Open Google Maps Error: Invalid Longitude")
            completion(false)
            return
        }
        
        
        if (UIApplication.shared.canOpenURL(NSURL(string:"comgooglemaps://")! as URL)) {
        // Google Map App Exist
            let urlString = "comgooglemaps://?saddr=&daddr=\(lat),\(long)&directionsmode=driving"
            UIApplication.shared.open(URL(string:urlString)!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            completion(true)
            
        }
        else if (UIApplication.shared.canOpenURL(NSURL(string:"https://www.google.com/maps/")! as URL)) {
        // Use Google Map Web Browser
            let urlString = "https://www.google.com/maps/search/?api=1&query=\(lat),\(long)&directionsmode=driving"
            UIApplication.shared.openURL(NSURL(string:urlString)! as URL)
            completion(true)
        }
        else {
        // Fails
            NSLog("Can't use comgooglemaps://")
            completion(false)
        }
    }
    
    static func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                print("Settings opened: \(success)") // Prints true
            })
        }
    }
    
    static func checkNotificationAccess() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            let status = settings.authorizationStatus
            if status != .authorized && status != .provisional {
                print("Requesting Notification Authorization | \(status)")
                NotificationCenter.default.post(name: AppDelegate.NotificationAccessRequest, object: nil)
            } else {
                SharedFunctions.getNotificationSettings()
            }
        }
    }
    
    static func getNotificationSettings() {
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        print("Notification settings: \(settings)")
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
        }
      }
    }
    
    static func registerForPushNotifications() {
        UNUserNotificationCenter.current()
          .requestAuthorization(
            options: [.alert, .sound, .badge, .provisional]) { [self] granted, _ in
            print("Permission granted: \(granted)")
            guard granted else { return }
            self.getNotificationSettings()
          }
    }
    
    
    
    @available(iOS 13, *)
    static func sha256(_ input: String) -> String {
          let inputData = Data(input.utf8)
          let hashedData = SHA256.hash(data: inputData)
          let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
          }.joined()

          return hashString
    }
    

    static func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      let charset: Array<Character> =
          Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
      var result = ""
      var remainingLength = length

      while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
          var random: UInt8 = 0
          let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
          if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
          }
          return random
        }

        randoms.forEach { random in
          if remainingLength == 0 {
            return
          }

          if random < charset.count {
            result.append(charset[Int(random)])
            remainingLength -= 1
          }
        }
      }

      return result
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
