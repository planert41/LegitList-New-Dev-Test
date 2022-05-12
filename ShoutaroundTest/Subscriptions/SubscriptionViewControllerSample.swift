//
//  SubscriptionViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 5/1/21.
//  Copyright © 2021 Wei Zou Ang. All rights reserved.
//

import UIKit
import RevenueCat
import StoreKit

enum RegisteredPurchase: String {

    case purchase1
    case purchase2
    case nonConsumablePurchase
    case consumablePurchase
    case nonRenewingPurchase
    case autoRenewableWeekly
    case autoRenewableMonthly
    case autoRenewableYearly
    case premium
}

class SubscriptionViewControllerSample: UIViewController {

    let appSecret = "542df682436548809b409452229c75c1"
    let appBundleId = "Shoutaround.ShoutaroundTest"

    let purchaseSuffix = RegisteredPurchase.premium

    let currentSubLabel: UILabel = {
        let label = UILabel()
        label.layer.borderColor = UIColor.clear.cgColor
        label.layer.borderWidth = 0
        label.layer.cornerRadius = label.bounds.size.height / 2
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = UIFont(name: "Poppins-Bold", size: 12)
        label.textColor = .white
        label.backgroundColor = UIColor.ianLegitColor()
        label.text = "Current Subscription"
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let currentSubTextView: UITextView = {
        let tv = UITextView()
        tv.isScrollEnabled = false
        tv.textContainer.maximumNumberOfLines = 0
        tv.textContainerInset = UIEdgeInsets.zero
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.isEditable = false
//        tv.textContainer.lineBreakMode = .byTruncatingTail
        tv.backgroundColor = UIColor.clear
        tv.font = UIFont(name: "Poppins-Bold", size: 10)
        tv.textAlignment = .center
        tv.isScrollEnabled = false
        return tv
    }()
    
    
    lazy var infoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Info", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(getInfoButton), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 0
        button.backgroundColor = .green
        return button
    }()
    
    lazy var annualSubButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Annual Sub", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(getAnnualSubButton), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 0
        button.backgroundColor = .yellow
        return button
    }()
    
    lazy var monthlySubButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Monthly Sub", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(getMonthlySubButton), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 0
        button.backgroundColor = .green
        return button
    }()
    
    lazy var individualSubButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Individual Sub", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(getIndividualSubButton), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 0
        button.backgroundColor = .yellow
        return button
    }()
    
    
    lazy var verifyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Verify", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(getVerifyButton), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 0
        return button
    }()

    
    lazy var CancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Dismiss", for: .normal)
        button.setTitleColor(.mainBlue(), for: .normal)
        button.addTarget(self, action: #selector(exit), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        return button
    }()
    
    
    @objc func exit() {
        self.dismiss(animated: true) {
            print("DISMISSED")
        }
    }
    
    var currentSub = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ianLegitColor()
        
        self.view.addSubview(currentSubTextView)
        currentSubTextView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        currentSubTextView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        
        let actionStackView = UIStackView(arrangedSubviews: [infoButton, annualSubButton, monthlySubButton, individualSubButton])
        actionStackView.spacing = 5
        actionStackView.distribution = .fillEqually
        actionStackView.axis = .vertical
        actionStackView.alignment = .center

        
        
        self.view.addSubview(actionStackView)
        actionStackView.anchor(top: currentSubTextView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 30, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 200)
        actionStackView.layer.applySketchShadow()
        actionStackView.backgroundColor = UIColor.white
        
        self.view.addSubview(CancelButton)
        CancelButton.anchor(top: actionStackView.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 50, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 100, height: 45)
        CancelButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true

        
        self.checkCurrentStatus()
        // Do any additional setup after loading the view.
    }
    
    func checkCurrentStatus() {
        print("checkCurrentStatus")
        Purchases.shared.getCustomerInfo { (info, error) in
            // Check the info parameter for active entitlements
            if info?.entitlements["premium"]?.isActive == true {
                
                // Unlock all access for the user
                self.currentSub = true
            } else {
                self.currentSub = false
            }
            
            var currentSubs = info?.activeSubscriptions
            var subIds = info?.allPurchasedProductIdentifiers ?? []
            var expiry = info?.latestExpirationDate
            var start = info?.originalPurchaseDate
            var request = info?.requestDate
            var entit = info?.entitlements


//            var temp = ""
//            for line in description ?? [] {
//                temp += line
//            }
            
            var displayText = "Current Sub \(self.currentSub)"
            displayText += "\n \(subIds)"
            displayText += "\n \(expiry)"
            displayText += "\n \(start)"
            displayText += "\n \(entit)"

            var description = info?.description.replacingOccurrences(of: "{(\n)}", with: "").replacingOccurrences(of: "{\n}", with: "")
//            print(description)
//            displayText += "\n \(String(description ?? ""))"

//            print(displayText)
            self.currentSubTextView.text = displayText
            self.currentSubTextView.sizeToFit()
            
        }
    }
    
    
    
    @objc func getInfoButton() {
        checkCurrentStatus()
    }
    
    @objc func getAnnualSubButton() {
        PurchaseService.purchase(productId: annualSubProductID) {(transaction) in
            print("SUCCESS ANNUAL SUB")
            // Upon successful purchase, set the all access flag
            self.currentSub = true
            self.checkCurrentStatus()
            if let transaction = transaction {
                self.alert(title: "Transaction", message: "\(transaction.transactionIdentifier) \n\(transaction.purchaseDate)")
            }
        }
    }
    
    @objc func getMonthlySubButton() {
        PurchaseService.purchase(productId: monthlySubProductID) {(transaction) in
            print("SUCCESS MONTHLY SUB")
            // Upon successful purchase, set the all access flag
            self.currentSub = true
            self.checkCurrentStatus()
            if let transaction = transaction {
                self.alert(title: "Transaction", message: "\(transaction.transactionIdentifier) \n\(transaction.purchaseDate)")
            }
        }
    }
    
    @objc func getIndividualSubButton() {
        PurchaseService.purchase(productId: indSubProductID) {(transaction) in
            print("SUCCESS MONTHLY SUB")
            // Upon successful purchase, set the all access flag
            self.currentSub = true
            self.checkCurrentStatus()
            if let transaction = transaction {
                self.alert(title: "Transaction", message: "\(transaction.transactionIdentifier) \n\(transaction.purchaseDate)")
            }
        }
    }
    
    
    @objc func getVerifyButton() {
    
    }
    
//
//    func querySub(){
//
//        let URL_Search = "https://api.revenuecat.com/v1/subscribers/app_user_id"
//        let API_iOSKey = GoogleAPIKey()
//
//
//        //        https://maps.googleapis.com/maps/api/place/details/json?placeid=ChIJbd2OryfY3IARR6800Hij7-Q&key=AIzaSyAzwACZh50Qq1V5YYKpmfN21mZs8dW6210
//
//        let urlString = "\(URL_Search)placeid=\(placeId)&key=\(API_iOSKey)"
//        let url = URL(string: urlString)!
////        print("Google Places URL: ",urlString)
//
//        //        print("Place Cache for postid: ", placeId, placeCache[placeId])
//        if let result = locationGoogleJSONCache[placeId] {
//            //            print("Using Place Cache for placeId: ", placeId)
//            self.extractPlaceDetails(fetchedResults: result)
//        } else {
//
//            AF.request(url).responseJSON { (response) -> Void in
//                //                        print("Google Response: ",response)
//                if let value  = response.value {
//                    let json = JSON(value)
//                    let result = json["result"]
//
//                    locationGoogleJSONCache[placeId] = result
//                    self.extractPlaceDetails(fetchedResults: result)
//                }
//            }
//        }
//    }
//
//    func extractPlaceDetails(fetchedResults: JSON){
//
//        let result = fetchedResults
//        //                print("Fetched Results: ",result)
//        if result["place_id"].string != nil {
//
//            self.placeName = result["name"].string ?? ""
//            //            print("place Name: ", self.placeName)
////            self.locationNameLabel.text = self.placeName
//
//            self.selectedName = self.placeName
////            self.navigationItem.title = self.placeName
//
//            self.placeOpeningHours = result["opening_hours"]["weekday_text"].arrayValue
////                                    print("placeOpeningHours: ", self.placeOpeningHours)
//
//            let today = Date()
//            let myCalendar = Calendar(identifier: .gregorian)
//            let weekDay = myCalendar.component(.weekday, from: today)
//
//            var todayIndex: Int
//
//            // Apple starts with Sunday at 1 to sat at 7. Google starts Sunday at 0 ends at 6
//            if weekDay == 1 {
//                todayIndex = 0
//            } else {
//                todayIndex = weekDay - 1
//            }
//
//            //            print("placeOpenNow: ", self.placeOpenNow)
//
//            if self.placeOpeningHours! != [] {
//
//
//                // Determine if Open
////                var placeOpeningPeriods: [JSON]?
//                guard let placeOpeningPeriods = result["opening_hours"]["periods"].arrayValue as [JSON]? else {return}
//
////                print(placeOpeningPeriods)
//
//                var day: Int?
//                var openHourString: String?
//                var closeHourString: String?
//
//                for day_entry in placeOpeningPeriods {
//                    day = day_entry["close"]["day"].int
//                    if day == todayIndex {
//                        openHourString = day_entry["open"]["time"].string
//                        closeHourString = day_entry["close"]["time"].string
//                        break
//                    }
//                }
//
////                let openHourString = placeOpeningPeriods[hourIndex!]["open"]["time"].string
////                let closeHourString = placeOpeningPeriods[hourIndex!]["close"]["time"].string
////                let day = placeOpeningPeriods[hourIndex!]["close"]["day"].int
//
//
//                if day == todayIndex {
//                    let inFormatter = DateFormatter()
//                    inFormatter.locale = NSLocale.current
//                    inFormatter.dateFormat = "HHmm"
//
//                    let openHour = NSCalendar.current.component(.hour, from: inFormatter.date(from: openHourString!)!)
//                    let closeHour = NSCalendar.current.component(.hour, from: inFormatter.date(from: closeHourString!)!)
//
//                    let nowHour = NSCalendar.current.component(.hour, from: Date())
//
//                    if nowHour >= openHour && nowHour < closeHour {
//                        // The store is open
//                        self.placeOpenNow = true
//                    } else {
//                        self.placeOpenNow = false
//                    }
//                } else {
//                    print("Place Open: ERROR, Wrong Day, Default to Close")
//                    self.placeOpenNow = false
//                }
//
//
//                self.locationHoursLabel.isHidden = (self.placeOpenNow == nil)
//                self.locationHoursIcon.isHidden = (self.placeOpenNow == nil)
//
//                // Set Opening Hour Label
//                var googDayIndex: Int?
//                if todayIndex == 0 {
//                    googDayIndex = 6
//                } else {
//                    googDayIndex = todayIndex-1
//                }
//
//                let todayHours = String(describing: (self.placeOpeningHours?[googDayIndex!])!)
//                var textColor = UIColor.init(hexColor: "028090")
//
//                let openAttributedText = NSMutableAttributedString()
//
//                if let open = self.placeOpenNow {
//                    textColor = open ? UIColor.mainBlue() : UIColor.red
//
//                    let todayHoursSplit = todayHours.components(separatedBy: ",")
//
//                    for (index,time) in todayHoursSplit.enumerated() {
////                            print("\(time)")
//                        var attributedTime = NSMutableAttributedString()
//                        if index != 0 {
//                            var tempSpacing = NSMutableAttributedString(string: "\n   ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Poppins-Light", size: 14),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.rgb(red: 68, green: 68, blue: 68)]))
//                            attributedTime.append(tempSpacing)
//                        }
//
//                        var tempAttributedTime = NSMutableAttributedString(string: time, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Poppins-Light", size: 14),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.rgb(red: 68, green: 68, blue: 68)]))
//                        attributedTime.append(tempAttributedTime)
//                        openAttributedText.append(attributedTime)
//                    }
//
//                    self.locationHoursLabel.attributedText = openAttributedText
//                    print(self.locationHoursLabel.text)
//                    self.locationHoursLabel.sizeToFit()
//                } else {
//                    self.locationHoursLabel.isHidden = (self.placeOpenNow == nil)
//                    self.locationHoursIcon.isHidden = (self.placeOpenNow == nil)
//
//                }
//
//            } else {
//                // No Opening Hours from Google
//                self.locationHoursLabel.text = ""
//                self.placeOpenNow = nil
//            }
//
//
//            let invalidBackgroundColor = UIColor.lightGray
//            let validBackgroundColor = UIColor.ianWhiteColor()
//
//
//    // LOCATION PHONE
//            self.placePhoneNo = result["formatted_phone_number"].string ?? "N/A"
//            self.locationPhoneButton.setImage(#imageLiteral(resourceName: "fill1803Fill1804").withRenderingMode(.alwaysTemplate), for: .normal)
//            self.locationPhoneButton.setTitle(self.placePhoneNo!, for: .normal)
//            self.locationPhoneButton.tintColor = (self.placePhoneNo == "N/A") ? UIColor.gray : UIColor.legitColor()
//
//            let tempPhoneString = NSMutableAttributedString(string: "  " + self.placePhoneNo!, attributes: [NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 12), NSAttributedString.Key.foregroundColor: self.locationPhoneButton.tintColor])
//            self.locationPhoneButton.setAttributedTitle(tempPhoneString, for: .normal)
//
//            self.locationPhoneButton.isUserInteractionEnabled = !(self.placePhoneNo == "N/A")
//            self.locationPhoneButton.backgroundColor = (self.placePhoneNo == "N/A") ? invalidBackgroundColor : validBackgroundColor
//            self.phoneContainerView.backgroundColor = (self.placePhoneNo == "N/A") ? invalidBackgroundColor : validBackgroundColor
//
//
//    // LOCATION WEBSITE
//            self.placeWebsite = result["website"].string ?? ""
//            self.locationPhoneButton.isUserInteractionEnabled = !(self.placeWebsite == "")
//            self.locationWebsiteButton.setImage(#imageLiteral(resourceName: "fill2901Fill2902").withRenderingMode(.alwaysTemplate), for: .normal)
//            self.locationWebsiteButton.tintColor = (self.placeWebsite == "") ? UIColor.gray : UIColor.legitColor()
//            let tempWebsiteString = NSMutableAttributedString(string: " Website", attributes: [NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 12), NSAttributedString.Key.foregroundColor:self.locationWebsiteButton.tintColor ])
//            self.locationWebsiteButton.setAttributedTitle(tempWebsiteString, for: .normal)
//            self.locationWebsiteButton.backgroundColor = (self.placeWebsite == "") ? invalidBackgroundColor : validBackgroundColor
//            self.websiteContainerView.backgroundColor = (self.placeWebsite == "") ? invalidBackgroundColor : validBackgroundColor
//
////                self.websiteContainerView.setAttributedTitle(tempWebsiteString, for: .normal)
//
//
//    // LOCATION MAP
//            self.selectedAdress = result["formatted_address"].string ?? ""
//            self.locationMapButton.tintColor = (self.selectedAdress == "") ? UIColor.gray : UIColor.legitColor()
//
//            let tempMapString = NSMutableAttributedString(string: " Map", attributes: [NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 12), NSAttributedString.Key.foregroundColor:self.locationMapButton.tintColor])
//            self.locationMapButton.setAttributedTitle(tempMapString, for: .normal)
//            self.locationMapButton.isUserInteractionEnabled = !(self.placePhoneNo == "N/A")
//            self.locationMapButton.backgroundColor = (self.selectedAdress == "") ? invalidBackgroundColor : validBackgroundColor
//            self.mapContainerView.backgroundColor = (self.selectedAdress == "") ? invalidBackgroundColor : validBackgroundColor
//
//
//
//            self.placeGoogleRating = result["rating"].double ?? 0
//            updateGoogleRatingLabel()
//
//
//            //            print("placeGoogleRating: ", self.placeGoogleRating)
//
//            self.placeGoogleMapUrl = result["url"].string!
//
//            self.selectedLong = result["geometry"]["location"]["lng"].double ?? 0
//            self.selectedLat = result["geometry"]["location"]["lat"].double ?? 0
//            self.selectedLocation = CLLocation(latitude: self.selectedLat!, longitude: self.selectedLong!)
//
//            self.selectedAdress = result["formatted_address"].string ?? ""
//            self.locationAdressLabel.text = self.selectedAdress
//
//
//
//
//        } else {
//            print("Failed to extract Google Place Details")
//        }
//    }


    
    

}
