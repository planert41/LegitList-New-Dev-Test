//
//  FilterController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/28/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import GooglePlaces
import Cosmos


protocol SearchFilterControllerDelegate: class {
    func filterControllerSelected(filter: Filter?)
}

class SearchFilterController: UIViewController, GMSAutocompleteViewControllerDelegate, MainSearchControllerDelegate, UISearchBarDelegate {
    
    let locationManager = CLLocationManager()
    
    weak var delegate: SearchFilterControllerDelegate?

    
    var searchFilter: Filter? {
        didSet {
            guard let searchFilter = searchFilter else {return}
            
            self.filterCaptionSearchBar.text = searchFilter.filterCaption
            
            if let selectedRange = searchFilter.filterRange {
                self.distanceSegment.selectedSegmentIndex = geoFilterRangeDefault.firstIndex(of: selectedRange)!
            } else {
                self.distanceSegment.selectedSegmentIndex = UISegmentedControl.noSegment
            }
            
            starRating.rating = searchFilter.filterMinRating

            
//            self.filterLegitButton.setImage(((searchFilter?.filterLegit)! ? #imageLiteral(resourceName: "legit_fill") : #imageLiteral(resourceName: "legit_unfill")).withRenderingMode(.alwaysOriginal) , for: .normal)
            self.refreshLegitButton()
            
            if let selectedType = searchFilter.filterType {
                self.typeSegment.selectedSegmentIndex = UploadPostTypeDefault.firstIndex(of: selectedType)!
            } else {
                self.typeSegment.selectedSegmentIndex = UISegmentedControl.noSegment
            }
            
            if let selectedMaxPrice = searchFilter.filterMaxPrice {
                self.priceSegment.selectedSegmentIndex = UploadPostPriceDefault.firstIndex(of: selectedMaxPrice)!
            } else {
                self.priceSegment.selectedSegmentIndex = UISegmentedControl.noSegment
            }
            
            if searchFilter.filterLocation == CurrentUser.currentLocation || searchFilter.filterLocationName == "Current Location"{
                let attributedText = NSMutableAttributedString(string: "Current Location", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.legitColor()]))
                locationNameLabel.attributedText = attributedText
                
                self.currentLocationButton.isHidden = true
            } else {
                self.currentLocationButton.isHidden = false
            }
            
            if let selectedLocationName = searchFilter.filterLocationName {
                locationNameLabel.text = selectedLocationName
            }
            
            if let index = filterSortOptions.firstIndex(of: (searchFilter.filterSort)!){
                self.sortSegment.selectedSegmentIndex = index
            } else {
                self.sortSegment.selectedSegmentIndex = 1
                searchFilter.filterSort = defaultRecentSort
            }
            
        }
    }
  
    // 0 For Default Header Sort Options, 1 for Location Sort Options
    var sortOptionsInd: Int = 0 {
        didSet{
            self.updateForSortOptionsInd()
        }
    }
    var filterSortOptions: [String] = HeaderSortOptions
    let segmentHeight: CGFloat = 35
    
    


    
    lazy var filterCaptionLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Search Posts For"
        ul.font = UIFont.boldSystemFont(ofSize: 14.0)
        return ul
    }()
    
    lazy var filterCaptionSearchBar = UISearchBar()
    
    lazy var filterDistanceLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Distance Within (Mi)"
        ul.font = UIFont.boldSystemFont(ofSize: 14.0)
        return ul
    }()
    
    lazy var locationLabel: UILabel = {
        let ul = UILabel()
        ul.text = "From Location"
        ul.font = UIFont.boldSystemFont(ofSize: 14.0)
        return ul
    }()
    
    let locationNameLabel: UILabel = {
        let tv = LocationLabel()
        tv.font = UIFont.systemFont(ofSize: 14)
        tv.backgroundColor = UIColor(white: 0, alpha: 0.05)
        tv.layer.borderColor = UIColor(white: 0, alpha: 0.15).cgColor
        tv.layer.borderWidth = 0.5
        tv.layer.cornerRadius = 5
        return tv
    }()
    
    
    lazy var filterGroupLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Posts From"
        ul.font = UIFont.boldSystemFont(ofSize: 14.0)
        return ul
    }()
    
    lazy var sortByLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Sort By (First)"
        ul.font = UIFont.boldSystemFont(ofSize: 14.0)
        return ul
    }()
    
    lazy var filterTimeLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Sort By Time"
        ul.font = UIFont.boldSystemFont(ofSize: 14.0)
        return ul
    }()
    
    lazy var filterRatingLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Min Rating"
        ul.font = UIFont.boldSystemFont(ofSize: 14.0)
        return ul
    }()
    
    lazy var filterPriceLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Max Price"
        ul.font = UIFont.boldSystemFont(ofSize: 14.0)
        return ul
    }()
    
    lazy var currentLocationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.black, for: .normal)
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 3
        button.setImage(#imageLiteral(resourceName: "Geofence").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(findCurrentLocation), for: .touchUpInside)
        return button
    }()
    
    var filterButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.orange
        button.setTitle("Filter", for: .normal)
        button.titleLabel?.textAlignment = NSTextAlignment.center
        button.addTarget(self, action: #selector(filterSelected), for: .touchUpInside)
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 0.5
        button.layer.cornerRadius = 3
        
        return button
    }()
    
    var clearFilterButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.legitColor()
        button.setTitle("Clear Filter", for: .normal)
        button.titleLabel?.textAlignment = NSTextAlignment.center
        button.addTarget(self, action: #selector(refreshFilter), for: .touchUpInside)
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 0.5
        button.layer.cornerRadius = 3
        
        return button
    }()
    
    let starRating: CosmosView = {
        let iv = CosmosView()
        iv.settings.fillMode = .half
        iv.settings.totalStars = starRatingCountDefault
        iv.settings.starSize = 40
        iv.settings.filledImage = #imageLiteral(resourceName: "star_rating_filled_mid").withRenderingMode(.alwaysOriginal)
        iv.settings.emptyImage = #imageLiteral(resourceName: "star_rating_unfilled").withRenderingMode(.alwaysOriginal)
        iv.rating = 0
        iv.settings.starMargin = 4
        return iv
    }()
    
//    let filterLegitButton: UIButton = {
//        let btn = UIButton()
//        btn.setImage(#imageLiteral(resourceName: "legit_unfill").withRenderingMode(.alwaysOriginal), for: .normal)
//        btn.alpha = 0.5
//        btn.addTarget(self, action: #selector(handleLegit), for: .touchUpInside)
//        return btn
//    }()
    
    lazy var filterLegitButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "legit_large").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleLegit), for: .touchUpInside)
        button.layer.cornerRadius = button.frame.width/2
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()
    
    
    
    func refreshAll() {

    }
    
    func handleLegit(){
        self.searchFilter?.filterLegit = !(self.searchFilter?.filterLegit)!
        
        filterLegitButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.refreshLegitButton()
                        self?.filterLegitButton.transform = .identity
                        
//                        self?.filterLegitButton.setImage(((self?.searchFilter?.filterLegit)! ? #imageLiteral(resourceName: "legit_fill") : #imageLiteral(resourceName: "legit_unfill")).withRenderingMode(.alwaysOriginal) , for: .normal)
//                        self?.filterLegitButton.alpha = (self?.searchFilter?.filterLegit)! ? 1 : 0.5
                        
            },
                       completion: nil)
        
    }
    
    func refreshLegitButton(){
        if (self.searchFilter?.filterLegit)! {
            self.filterLegitButton.backgroundColor = UIColor.legitColor()
            self.filterLegitButton.layer.borderWidth = 0
            self.filterLegitButton.alpha = 1 }
        else {
            self.filterLegitButton.backgroundColor = UIColor.white
            self.filterLegitButton.layer.borderColor = UIColor(hexColor: "eab543").cgColor
            self.filterLegitButton.layer.borderWidth = 2
            self.filterLegitButton.alpha = 0.75
        }
    }
    
    var distanceSegment:ReselectableSegmentedControl = {
        var segment = ReselectableSegmentedControl(items: geoFilterRangeDefault)
        segment.addTarget(self, action: #selector(handleSelectRange), for: .valueChanged)
        segment.tintColor = UIColor.rgb(red: 223, green: 85, blue: 78)
        segment.selectedSegmentIndex = UISegmentedControl.noSegment
        return segment
    }()
    
    func handleSelectRange(sender: UISegmentedControl) {
        if (geoFilterRangeDefault[sender.selectedSegmentIndex] == self.searchFilter?.filterRange) {
            sender.selectedSegmentIndex =  UISegmentedControl.noSegment
            self.searchFilter?.filterRange = nil
        }
        else {
            self.searchFilter?.filterRange = geoFilterRangeDefault[sender.selectedSegmentIndex]
        }
        print("Selected Range | ",self.searchFilter?.filterRange)
    }
    
    var typeSegment:ReselectableSegmentedControl = {
        var segment = ReselectableSegmentedControl(items: UploadPostTypeDefault)
        segment.addTarget(self, action: #selector(handleSelectType), for: .valueChanged)
        segment.tintColor = UIColor.rgb(red: 223, green: 85, blue: 78)
        segment.selectedSegmentIndex = UISegmentedControl.noSegment
        return segment
    }()
    
    func handleSelectType(sender: UISegmentedControl) {
        if (UploadPostTypeDefault[sender.selectedSegmentIndex] == self.searchFilter?.filterType) {
            sender.selectedSegmentIndex =  UISegmentedControl.noSegment
            self.searchFilter?.filterType = nil
        }
        else {
            self.searchFilter?.filterType = UploadPostTypeDefault[sender.selectedSegmentIndex]
        }
        print("Selected Type | ",self.searchFilter?.filterType)
    }
    
    
    var priceSegment:ReselectableSegmentedControl = {
        var segment = ReselectableSegmentedControl(items: UploadPostPriceDefault)
        segment.addTarget(self, action: #selector(handleSelectPrice), for: .valueChanged)
        segment.tintColor = UIColor.rgb(red: 223, green: 85, blue: 78)
        segment.selectedSegmentIndex = UISegmentedControl.noSegment
        return segment
    }()
    
    func handleSelectPrice(sender: UISegmentedControl) {
        if (UploadPostPriceDefault[sender.selectedSegmentIndex] == self.searchFilter?.filterMaxPrice) {
            sender.selectedSegmentIndex =  UISegmentedControl.noSegment
            self.searchFilter?.filterMaxPrice = nil
        }
        else {
            self.searchFilter?.filterMaxPrice = UploadPostPriceDefault[sender.selectedSegmentIndex]
        }
        print("Selected Max Price | ",self.searchFilter?.filterMaxPrice)
    }
    
    var sortSegment: UISegmentedControl = {
        var segment = UISegmentedControl(items: HeaderSortOptions)
        segment.addTarget(self, action: #selector(handleSelectSort), for: .valueChanged)
        segment.tintColor = UIColor.rgb(red: 223, green: 85, blue: 78)
        segment.selectedSegmentIndex = 0
        return segment
    }()
    
    func handleSelectSort(sender: UISegmentedControl) {
        self.searchFilter?.filterSort = filterSortOptions[sender.selectedSegmentIndex]
        print("Selected Sort | ",self.searchFilter?.filterSort)
    }
    
    func findCurrentLocation() {
        
        self.searchFilter?.filterGoogleLocationID = nil
        self.searchFilter?.filterLocation = nil
        
        LocationSingleton.sharedInstance.determineCurrentLocation()
        let when = DispatchTime.now() + defaultGeoWaitTime // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.searchFilter?.filterLocation = CurrentUser.currentLocation
        }
    }
    
    let selectionMargin: CGFloat = 10
    
    static let updateFeedWithFilterNotificationName = NSNotification.Name(rawValue: "UpdateFeedWithFilter")
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if self.searchFilter?.filterLocation == nil {
            let attributedText = NSMutableAttributedString(string: "Current Location", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.legitColor()]))
            locationNameLabel.attributedText = attributedText
            self.findCurrentLocation()
        }
        
        let scrollview = UIScrollView()
        
        scrollview.frame = view.bounds
        scrollview.backgroundColor = UIColor.white
        scrollview.isScrollEnabled = true
        scrollview.showsVerticalScrollIndicator = true
        scrollview.contentSize = CGSize(width: view.bounds.width, height: view.bounds.height * 1.25)
        view.addSubview(scrollview)
        
//        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "filter").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(filterSelected))
        
        view.backgroundColor = UIColor.white
        self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.white, NSAttributedString.Key.font.rawValue: UIFont(font: .noteworthyBold, size: 20)])

        self.navigationItem.title = "Advanced Filter"

        // 0. Filter Post By Caption
        
        
        filterCaptionSearchBar.delegate = self
        filterCaptionSearchBar.placeholder = "Search Posts For"
        filterCaptionSearchBar.searchBarStyle = .prominent
        filterCaptionSearchBar.barTintColor = UIColor.legitColor()
        
        // Add Border Color to Search Bar
        for s in filterCaptionSearchBar.subviews[0].subviews {
            if s is UITextField {
                
                s.layer.borderWidth = 0.5
                s.layer.borderColor = UIColor.legitColor().cgColor
                s.layer.cornerRadius = 5
            }
        }
        
        scrollview.addSubview(filterCaptionSearchBar)
        filterCaptionSearchBar.anchor(top: scrollview.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: segmentHeight+20)
        
        
        
        // 1. Filter By Location + Distance
        scrollview.addSubview(filterDistanceLabel)
        
        filterDistanceLabel.anchor(top: filterCaptionSearchBar.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: selectionMargin, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 25)
        
        scrollview.addSubview(locationNameLabel)
        scrollview.addSubview(currentLocationButton)
        
        locationNameLabel.isUserInteractionEnabled = true
        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(tapSearchBar))
        locationNameLabel.addGestureRecognizer(TapGesture)
        
        locationNameLabel.anchor(top: filterDistanceLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 2, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: segmentHeight)
        
        currentLocationButton.anchor(top: locationNameLabel.topAnchor, left: nil, bottom: locationNameLabel.bottomAnchor, right: locationNameLabel.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        currentLocationButton.widthAnchor.constraint(equalTo: currentLocationButton.heightAnchor, multiplier: 1).isActive = true
        currentLocationButton.isHidden = true
        
        scrollview.addSubview(distanceSegment)
        distanceSegment.anchor(top: locationNameLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: segmentHeight)
        
        
        // 3. Select Min Rating
        scrollview.addSubview(filterRatingLabel)
        filterRatingLabel.anchor(top: distanceSegment.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: selectionMargin, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 25)
        
        //3.5 Add Legit
        let starRatingView = UIView()
        scrollview.addSubview(starRatingView)
        starRatingView.anchor(top: filterRatingLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
        
        starRatingView.addSubview(starRating)
        starRating.anchor(top: starRatingView.topAnchor, left: nil, bottom: starRatingView.bottomAnchor, right: nil, paddingTop: 2, paddingLeft: 0, paddingBottom: 2, paddingRight: 0, width: 0, height: 0)
        starRating.centerXAnchor.constraint(equalTo: starRatingView.centerXAnchor).isActive = true
        starRating.didFinishTouchingCosmos = starRatingSelectFunction
        
        
//        scrollview.addSubview(filterLegitButton)
//        filterLegitButton.anchor(top: filterRatingLabel.bottomAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 1, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: segmentHeight, height: segmentHeight)
        

        
        
        // 4. Select Price Filter
        scrollview.addSubview(filterPriceLabel)
        scrollview.addSubview(priceSegment)
        
        filterPriceLabel.anchor(top: starRatingView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: selectionMargin, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 25)
        priceSegment.anchor(top: filterPriceLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 1, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: segmentHeight)
        filterPriceLabel.text = "Max Price"
        
        // 5. Select Post Type (Breakfast, Lunch, Dinner, Snack)
        //        scrollview.addSubview(filterTimeLabel)
        scrollview.addSubview(typeSegment)
        //        filterTimeLabel.anchor(top: filterPriceLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: selectionMargin, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 25)
        typeSegment.anchor(top: priceSegment.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: selectionMargin, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: segmentHeight)
        
        // 6. Sort Filter
        //        scrollview.addSubview(sortByLabel)
        scrollview.addSubview(sortSegment)
        
        //        sortByLabel.anchor(top: priceSegment.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: selectionMargin, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 30)
        sortSegment.anchor(top: typeSegment.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: selectionMargin, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: segmentHeight)
        
        // 7. Sort button
        scrollview.addSubview(filterButton)
        filterButton.anchor(top: sortSegment.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 40)
        
        scrollview.addSubview(clearFilterButton)
        clearFilterButton.anchor(top: filterButton.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 40)
        
        let date = Date() // save date, so all components use the same date
        let calendar = Calendar.current // or e.g. Calendar(identifier: .persian)
        let hour = calendar.component(.hour, from: date)
        print(hour)
        
        // Don't Set Type Filter For Now
        
        //        // Morning 6-11, MidDay 11 - 5, Late, 5 - 6
        //        if hour > 5 && hour <= 11 {
        //            self.selectedType = UploadPostTypeDefault[0]
        //            self.typeSegment.selectedSegmentIndex = 0
        //        } else if hour > 11 && hour <= 17 {
        //            self.selectedType = UploadPostTypeDefault[1]
        //            self.typeSegment.selectedSegmentIndex = 1
        //        } else {
        //            self.selectedType = UploadPostTypeDefault[2]
        //            self.typeSegment.selectedSegmentIndex = 2
        //        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" // "a" prints "pm" or "am"
        let hourString = formatter.string(from: Date()) // "12 AM"
        
        let filterTimeAttributedText = NSMutableAttributedString(string: "Sort By Time", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black]))
        
        filterTimeAttributedText.append(NSMutableAttributedString(string: "   ⏰ \(hourString) ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.mainBlue()])))
        filterTimeLabel.attributedText = filterTimeAttributedText
        
    }
    
    
    //    override func viewWillDisappear(_ animated: Bool) {
    //        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
    //    }
    //
    //    override func viewWillAppear(_ animated: Bool) {
    //        navigationController?.navigationBar.barTintColor = UIColor.white
    //    }
    
    func starRatingSelectFunction(rating: Double) {
        print("Selected Rating: \(rating)")

        
        if rating >= 4 {
            starRating.settings.filledImage = #imageLiteral(resourceName: "star_rating_filled_high").withRenderingMode(.alwaysOriginal)
        } else {
            starRating.settings.filledImage = #imageLiteral(resourceName: "star_rating_filled_mid").withRenderingMode(.alwaysOriginal)
        }
        
        // Auto deselect star rating if select < 2 (Nobody filters for at least 1 star)
        
        if rating < 2 {
            self.searchFilter?.filterMinRating = 0
            self.starRating.rating = 0
        } else {
            self.searchFilter?.filterMinRating = rating
        }
        
        print("Selected Rating | \(self.searchFilter?.filterMinRating)")
    }
    
    
    func updateForSortOptionsInd(){
        
        if sortOptionsInd == 1 {
            self.locationNameLabel.isUserInteractionEnabled = false
            filterSortOptions = LocationSortOptions
        } else {
            self.locationNameLabel.isUserInteractionEnabled = true
            filterSortOptions = HeaderSortOptions
        }
        
        for i in 0..<sortSegment.numberOfSegments {
            if sortSegment.titleForSegment(at: i) != filterSortOptions[i] {
                //Update Segment Label
                sortSegment.setTitle(filterSortOptions[i], forSegmentAt: i)
            }
        }
    }
    
    func filterSelected(){
        
        delegate?.filterControllerSelected(filter: self.searchFilter)
        
        print("Filter By | ",self.searchFilter)
        
        // ONLY POP TO ROOTVIEWCONTROLLER FOR FILTER CONTROLLER SINCE THIS IS THE MORE DETAILED FILTER
        
        //        self.navigationController?.popViewController(animated: true)
        self.navigationController?.popToRootViewController(animated: true)
        
    }
    
    func refreshFilter(){
        self.searchFilter?.clearFilter()
//        self.distanceSegment.selectedSegmentIndex = UISegmentedControlNoSegment
//        self.selectedRange = nil
//
//        self.selectedLocation = CurrentUser.currentLocation
//
//        self.selectedMinRating = 0
//        self.starRating.rating = 0
//
//        self.typeSegment.selectedSegmentIndex = UISegmentedControlNoSegment
//        self.selectedType = nil
//
//        self.priceSegment.selectedSegmentIndex = UISegmentedControlNoSegment
//        self.selectedMaxPrice = nil
//
//        self.sortSegment.selectedSegmentIndex = 0
//        self.selectedSort = defaultRecentSort
        self.filterSelected()
        
    }
    
    // Search Bar Delegates
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        self.openSearch()
        return false
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        //        if (searchText.length == 0) {
        //            self.filterCaption = nil
        //            self.refreshPostsForFilter()
        //            searchBar.endEditing(true)
        //        }
    }
    
    func openSearch(){
        
        let postSearch = MainSearchController()
        postSearch.delegate = self
        postSearch.enableScopeOptions = false
        postSearch.searchBar.showsScopeBar = false
        postSearch.multiSelect = true
//        self.navigationController?.present(postSearch, animated: true, completion: {
//
//        })
        self.navigationController?.pushViewController(postSearch, animated: true)
    }
    
    // Home Post Search Delegates
    
    func filterControllerSelected(filter: Filter?) {
        self.searchFilter = filter
    }
    
    // Google Search Location Delegates
    
    
    func tapSearchBar() {
        print("Search Bar Tapped")
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        self.searchFilter?.filterLocation = CLLocation.init(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        self.searchFilter?.filterGoogleLocationID = place.placeID
        self.searchFilter?.filterLocationName = place.name
        var placeType = place.types ?? [""]
        
        // Auto Select Closest Distance (5 KM)
        self.distanceSegment.selectedSegmentIndex = 1
        self.searchFilter?.filterRange = geoFilterRangeDefault[1]
        
        self.sortSegment.selectedSegmentIndex = 0
        self.searchFilter?.filterSort = defaultRecentSort
        
        
        var defaultRange: String? = "5"
        if self.searchFilter?.filterRange == nil {
            self.searchFilter?.filterRange = defaultRange
        }
        
        self.locationNameLabel.text = self.searchFilter?.filterLocationName
        print("Selected Google Location: \(place.name), \(place.placeID), \(self.searchFilter?.filterLocation)")
        dismiss(animated: true, completion: nil)
        
    }
    
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print(error)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
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
