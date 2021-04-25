//
//  LocationManager.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/8/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import SVProgressHUD

class LocationSingleton: NSObject,CLLocationManagerDelegate {

    var locationManager: CLLocationManager?
    
    static let sharedInstance:LocationSingleton = {
        let instance = LocationSingleton()
        return instance
    }()
    
    override init() {
        super.init()
        
        self.locationManager = CLLocationManager()
        guard let locationManager = self.locationManager else {
            return
        }
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.distanceFilter = 0.1

        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
        }
        if #available(iOS 9.0, *) {
            //            locationManagers.allowsBackgroundLocationUpdates = true
        } else {
            // Fallback on earlier versions
        }

    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        
        if userLocation != nil {
            print("Location Manager | LOCATION FOUND | \(userLocation.coordinate)")

//            print("Location Manager: Update Location: SUCCESS: ", userLocation)
            CurrentUser.currentLocation = userLocation
            CurrentUser.currentLocationTime = Date()
            manager.stopUpdatingLocation()
            let when = DispatchTime.now() + 1 // change 2 to desired number of seconds
            DispatchQueue.main.asyncAfter(deadline: when) {
                //Delay for 1 second to dismiss loading button after finding location
//                SVProgressHUD.dismiss()
            }
        } else {
            print("Location Manager: Update Location: ERROR, No Location")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager: Update Location: ERROR, No Location")
    }
    
    func determineCurrentLocation(){
        
        print("Location Manager | FINDING LOCATION")
        
        guard let locationManager = locationManager else{
            print("Location Manager: Update Location: ERROR, No Location Manager")
            return
        }
        
        CurrentUser.currentLocation = nil
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
//            SVProgressHUD.show(withStatus: "Finding Your Location")

        }
    }


    
    
    
}
