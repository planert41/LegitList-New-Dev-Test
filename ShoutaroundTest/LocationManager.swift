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
import SwiftLocation

class LocationSingleton: NSObject,CLLocationManagerDelegate {

    var locationManager: CLLocationManager?
    var authStatus: CLAuthorizationStatus = .notDetermined
    
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
//            locationManager.requestWhenInUseAuthorization()
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
                NotificationCenter.default.post(name: AppDelegate.LocationUpdatedNotificationName, object: nil)
            }
        } else {
            print("Location Manager: Update Location: ERROR, No Location")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager: Update Location: ERROR, No Location")
    }
    
    func requestLocationAuth() {
        locationManager?.requestWhenInUseAuthorization()
    }
    
    func goToSettings() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }
    
    func displayLocationAuth() {
        NotificationCenter.default.post(name: AppDelegate.RequestLocationNotificationName, object: nil)
    }
    
    func determineCurrentLocation(){
        guard let locationManager = locationManager else{
            print("Location Manager: Update Location: ERROR, No Location Manager")
            return
        }
        CurrentUser.currentLocation = nil
        let locationAuthApproved = (locationManager.authorizationStatus == .authorizedAlways || locationManager.authorizationStatus == .authorizedWhenInUse)
        
        print("Location Manager | FINDING LOCATION || \(locationManager.authorizationStatus)")
        
        if CLLocationManager.locationServicesEnabled() && locationAuthApproved {
            locationManager.startUpdatingLocation()
//            SVProgressHUD.show(withStatus: "Finding Your Location")
        } else {
            self.displayLocationAuth()
//            print("Requesting User Location")
//            locationManager.requestWhenInUseAuthorization()
        }
//

//
//        locationManager.requestWhenInUseAuthorization()
//        if SwiftLocation.authorizationStatus != CLAuthorizationStatus.authorizedAlways && SwiftLocation.authorizationStatus != CLAuthorizationStatus.authorizedWhenInUse {
//            SwiftLocation.requestAuthorization(.onlyInUse) { newStatus in
//                print("New status \(newStatus.description)")
//            }
//            return
//        }
//
//        if CLLocationManager.locationServicesEnabled() {
//            locationManager.startUpdatingLocation()
////            SVProgressHUD.show(withStatus: "Finding Your Location")
//        } else {
//            print("Requesting User Location")
//            locationManager.requestWhenInUseAuthorization()
//        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            print("notDetermined")
            self.displayLocationAuth()
        case .denied:
            NotificationCenter.default.post(name: AppDelegate.LocationDeniedNotificationName, object: nil)
            print("Location Manager Auth Denied")
        default:
            self.determineCurrentLocation()
        }
    }


    
    
    
}
