//
//  EmojiSummaryCV.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 5/27/20.
//  Copyright © 2020 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import CoreLocation

protocol LocationOptionsBarDelegate {
//    func headerSortSelected(sort: String)
//    func didTapGridButton()
//    func toggleMapFunction()
    func extActivatePhone(phoneNumber: String?)
    func extActivateAppleMap(loc: Location?)
    func extActivateBrowser(website: String?)
}


class LocationOptionsBar: UIView{
    
    var delegate: LocationOptionsBarDelegate?
    var location: Location?
    var locationJSON: JSON? {
        didSet {
            guard let locationJSON = locationJSON else {
                refreshOptionsBar()
                return}
            self.extractPlaceDetails(fetchedResults: locationJSON)
        }
    }
    
    var placePhoneNo: String?
    var placeWebsite: String?
    var placeLocationGPS: CLLocation?
    
    let phoneContainerView = UIView()
    let websiteContainerView = UIView()
    let mapContainerView = UIView()
    let actionBarContainer = UIView()
    
    let locationWebsiteButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "discover").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(activateBrowser), for: .touchUpInside)
        button.titleLabel?.textColor = UIColor.ianLegitColor()
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 14)
        return button
    }()
    
    let locationPhoneButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "phone").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(activatePhone), for: .touchUpInside)
        button.titleLabel?.textColor = UIColor.ianLegitColor()
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 14)
        return button
    }()
    
    let locationMapButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "map").withRenderingMode(.alwaysTemplate), for: .normal)
        button.addTarget(self, action: #selector(activateAppleMapFunction), for: .touchUpInside)
        button.titleLabel?.textColor = UIColor.ianLegitColor()
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 14)
        button.setTitle(" Direction", for: .normal)
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
    
    @objc func activateAppleMapFunction(){
        guard let loc = location else {return}
        self.delegate?.extActivateAppleMap(loc: loc)
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        
//        let borderColor = UIColor.rgb(red: 221, green: 221, blue: 221).cgColor
        
        let borderColor = UIColor.legitColor().cgColor

        let locationStackView = UIStackView(arrangedSubviews: [phoneContainerView, websiteContainerView,mapContainerView])
        addSubview(locationStackView)
        locationStackView.spacing = 0
        locationStackView.backgroundColor = UIColor.backgroundGrayColor()
        locationStackView.distribution = .fillEqually
        locationStackView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 15, paddingBottom: 5, paddingRight: 15, width: 0, height: 40)
        locationStackView.layer.cornerRadius = 10
        locationStackView.clipsToBounds = true
        locationStackView.layer.masksToBounds = true
        locationStackView.layer.borderWidth = 2
        locationStackView.layer.borderColor = UIColor.legitColor().cgColor

        phoneContainerView.addSubview(locationPhoneButton)
        locationPhoneButton.anchor(top: phoneContainerView.topAnchor, left: phoneContainerView.leftAnchor, bottom: phoneContainerView.bottomAnchor, right: phoneContainerView.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        websiteContainerView.addSubview(locationWebsiteButton)
        locationWebsiteButton.anchor(top: websiteContainerView.topAnchor, left: websiteContainerView.leftAnchor, bottom: websiteContainerView.bottomAnchor, right: websiteContainerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        mapContainerView.addSubview(locationMapButton)
        locationMapButton.anchor(top: mapContainerView.topAnchor, left: mapContainerView.leftAnchor, bottom: mapContainerView.bottomAnchor, right: mapContainerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        
        
        phoneContainerView.layer.borderColor = borderColor
        phoneContainerView.layer.borderWidth = 1
        
        websiteContainerView.layer.borderColor = borderColor
        websiteContainerView.layer.borderWidth = 1
        
        mapContainerView.layer.borderColor = borderColor
        mapContainerView.layer.borderWidth = 1
        
        
    }
    
    func refreshOptionsBar() {
        let invalidBackgroundColor = UIColor.lightGray
        let validBackgroundColor = UIColor.ianWhiteColor()
        let buttonFont = UIFont(name: "Poppins-Bold", size: 11)

        var missingPhone = self.placePhoneNo == "" || self.placePhoneNo == nil
        var phoneLabelText = missingPhone ? "Phone" : (self.placePhoneNo ?? "n/a")
        
        var invalidFontColor = UIColor.darkGray
        var validFontColor = UIColor.ianLegitColor()
         
        locationPhoneButton.isUserInteractionEnabled = !missingPhone
        locationPhoneButton.setImage(#imageLiteral(resourceName: "fill1803Fill1804").withRenderingMode(.alwaysTemplate), for: .normal)
        phoneContainerView.backgroundColor = (missingPhone) ? invalidBackgroundColor : validBackgroundColor
        locationPhoneButton.backgroundColor = (missingPhone) ? invalidBackgroundColor : validBackgroundColor
        locationPhoneButton.tintColor = (missingPhone) ? invalidFontColor : validFontColor
        
        let tempPhoneString = NSMutableAttributedString(string: "  " + phoneLabelText, attributes: [NSAttributedString.Key.font: buttonFont, NSAttributedString.Key.foregroundColor: self.locationPhoneButton.tintColor])
        locationPhoneButton.setAttributedTitle(tempPhoneString, for: .normal)
        locationPhoneButton.sizeToFit()


        
        var missingWebsite = self.placeWebsite == ""
        var websiteLabelText = "Website"
        locationWebsiteButton.setImage(#imageLiteral(resourceName: "fill2901Fill2902").withRenderingMode(.alwaysTemplate), for: .normal)
        locationWebsiteButton.tintColor = (missingWebsite) ? invalidFontColor : validFontColor
        locationWebsiteButton.backgroundColor = (missingWebsite) ? invalidBackgroundColor : validBackgroundColor
        websiteContainerView.backgroundColor = (missingWebsite) ? invalidBackgroundColor : validBackgroundColor
        
        let tempWebsiteString = NSMutableAttributedString(string: " \(websiteLabelText)", attributes: [NSAttributedString.Key.font: buttonFont, NSAttributedString.Key.foregroundColor:self.locationWebsiteButton.tintColor ])
        locationWebsiteButton.setAttributedTitle(tempWebsiteString, for: .normal)
        locationWebsiteButton.sizeToFit()
        
        
//        var missingGPS = (self.placeLocationGPS == nil) || (self.placeLocationGPS?.coordinate.latitude == 0 && self.placeLocationGPS?.coordinate.longitude == 0)
        var missingGPS = (self.location?.locationGPS == nil) || (self.location?.locationGPS!.coordinate.latitude == 0 && self.location?.locationGPS!.coordinate.longitude == 0)
        var mapLabelText = "Directions"

//        locationMapButton.setImage(#imageLiteral(resourceName: "google_color").withRenderingMode(.alwaysOriginal), for: .normal)
        locationMapButton.isUserInteractionEnabled = !missingGPS
        locationMapButton.backgroundColor = missingGPS ? invalidBackgroundColor : validBackgroundColor
        mapContainerView.backgroundColor = missingGPS ? invalidBackgroundColor : validBackgroundColor
        locationMapButton.tintColor = (missingGPS) ? invalidFontColor : validFontColor
        if missingGPS {
            locationMapButton.setImage(#imageLiteral(resourceName: "google_color").withRenderingMode(.alwaysTemplate), for: .normal)
        } else {
            locationMapButton.setImage(#imageLiteral(resourceName: "google_color").withRenderingMode(.alwaysOriginal), for: .normal)
        }

        let tempMapString = NSMutableAttributedString(string: " \(mapLabelText)", attributes: [NSAttributedString.Key.font: buttonFont, NSAttributedString.Key.foregroundColor:self.locationMapButton.tintColor ])
        locationMapButton.setAttributedTitle(tempMapString, for: .normal)
        locationMapButton.sizeToFit()

        
    }
    
    
    func extractPlaceDetails(fetchedResults: JSON){
        
        let result = fetchedResults
        //                print("Fetched Results: ",result)
        if result["place_id"].string != nil {
            


            self.placePhoneNo = result["formatted_phone_number"].string ?? ""

            self.placeWebsite = result["website"].string ?? ""

            
            let selectedLong = result["geometry"]["location"]["lng"].double ?? 0
            let selectedLat = result["geometry"]["location"]["lat"].double ?? 0
            
            if selectedLong != 0.0 && selectedLat != 0.0 {
                self.placeLocationGPS = CLLocation(latitude: selectedLat, longitude: selectedLong)
            }
            
        } else {
            print("Failed to extract Google Place Details")
        }
        
        self.refreshOptionsBar()
        
    }
    
    
    @objc func toggleMapFunction() {
//        self.delegate?.toggleMapFunction()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

