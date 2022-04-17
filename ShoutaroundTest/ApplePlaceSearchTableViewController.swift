//
//  CitySearchTableViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou on 3/28/22.
//  Copyright © 2022 Wei Zou Ang. All rights reserved.
//

import Foundation
import Combine
import UIKit
import MapKit

protocol AppleSearchDelegate {
    func locationSelected(name: String, loc: CLLocation?)
}

class ApplePlaceSearchTableViewController: UITableViewController, UISearchBarDelegate, MKLocalSearchCompleterDelegate, UISearchResultsUpdating, UISearchControllerDelegate {

    var searchCompleter = MKLocalSearchCompleter()
    var searchResults: [MKLocalSearchCompletion] = []
    let searchController = UISearchController(searchResultsController: nil)
    var searchBar = UISearchBar()
    var cellID = "CellID"
    var delegate: AppleSearchDelegate?
    
    var searchType: SearchType = .all {
        didSet {
            self.setupSearchCompleter()
        }
    }
    
    var inputText: String? = nil {
        didSet {
            if let input = inputText {
                if !(input.isEmptyOrWhitespace() ?? true) {
                    self.searchBar.text = input
                    self.searchCompleter.queryFragment = input
                }
            }
        }
    }

    enum SearchType {
        case all
        case city
        case place
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.searchController.isActive = true
        DispatchQueue.main.async {[weak self] in
            self?.searchController.searchBar.becomeFirstResponder()
         }

//        self.searchController.searchBar.becomeFirstResponder()
//        self.searchBar.becomeFirstResponder()
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
//        setupNavigationItems()
        setupTableView()
        setupSearchController()
        setupSearchCompleter()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    func setupNavigationItems(){
//        self.navigationController?.isNavigationBarHidden = true
//        self.navigationItem.title = "Apple Location Search"
    }
    
    func setupTableView(){
        tableView.backgroundColor = UIColor.white
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        tableView.alwaysBounceVertical = true
//        let adjustForTabbarInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
//        tableView.contentInset = adjustForTabbarInsets
//        tableView.scrollIndicatorInsets = adjustForTabbarInsets

    }
    
    func setupSearchCompleter() {
        searchCompleter = MKLocalSearchCompleter()
        searchCompleter.delegate = self
        searchCompleter.region = MKCoordinateRegion(.world)
        if searchType == .city {
            searchCompleter.resultTypes = MKLocalSearchCompleter.ResultType([.address])
        } else if searchType == .place {
            searchCompleter.resultTypes = MKLocalSearchCompleter.ResultType([.pointOfInterest])
        } else if searchType == .all {
            searchCompleter.resultTypes = MKLocalSearchCompleter.ResultType([.pointOfInterest, .address, .query])
        }
        
        if let input = self.inputText {
            if !(input.isEmptyOrWhitespace() ?? true) {
                self.searchBar.text = input
                self.searchCompleter.queryFragment = input
                print("Input Text Search: \(input)")
            }
        }
        

        
        print("SearchCompleter : \(searchType)")
    }
    
    func setupSearchController(){
        //        navigationController?.navigationBar.barTintColor = UIColor.white
        

        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.delegate = self
        definesPresentationContext = true
        searchBar = searchController.searchBar

        searchBar.backgroundImage = UIImage()
        searchBar.sizeToFit()
        searchBar.delegate = self
        searchBar.searchBarStyle = .prominent
        searchBar.placeholder =  "Search City"
//        searchBar.barTintColor = UIColor.ianLegitColor()
//        searchBar.tintColor = UIColor.ianLegitColor()
        definesPresentationContext = true
//        searchBar.backgroundColor = UIColor.ianLegitColor()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        
//        if let textField = self.searchBar.value(forKey: "searchField") as? UITextField {
//            textField.backgroundColor = UIColor.white
//            //textField.font = myFont
//            //textField.textColor = myTextColor
//            //textField.tintColor = myTintColor
//            // And so on...
//
//            let backgroundView = textField.subviews.first
//            if #available(iOS 11.0, *) { // If `searchController` is in `navigationItem`
//                backgroundView?.backgroundColor = UIColor.white //Or any transparent color that matches with the `navigationBar color`
//                backgroundView?.subviews.forEach({ $0.removeFromSuperview() }) // Fixes an UI bug when searchBar appears or hides when scrolling
//            }
//            backgroundView?.layer.cornerRadius = 10.5
//            backgroundView?.layer.masksToBounds = true
//            //Continue changing more properties...
//        }
        
        self.tableView.tableHeaderView = searchBar
        
        let footerView = UIView()
        footerView.backgroundColor = .clear
        footerView.frame.size.height = 30
        
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont(name: "Poppins-Bold", size: 14)
        label.textColor = UIColor.lightGray
        label.text = "Apple Location Search Results"
        
        footerView.addSubview(label)
        label.anchor(top: footerView.bottomAnchor, left: footerView.leftAnchor, bottom: footerView.bottomAnchor, right: footerView.rightAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 0, height: 25)
        self.tableView.tableFooterView = footerView

        
//        if #available(iOS 11.0, *) {
//            navigationItem.searchController = searchController
//            navigationItem.hidesSearchBarWhenScrolling  = false
//
//        } else {
//            self.tableView.tableHeaderView = searchBar
//        }
        
    }
    
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchBarText = searchController.searchBar.text {
            searchCompleter.queryFragment = searchBarText
//            print("Input \(searchBarText)")
        } else {
            print("Blank | \(searchController.searchBar.text)")
            searchResults = []
            self.tableView.reloadData()
        }
        
        
    }
    
    // This method declares that whenever the text in the searchbar is change to also update
    // the query that the searchCompleter will search based off of
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        searchCompleter.queryFragment = searchText
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.dismiss(animated: true) {
            print("Dismiss Search")
        }
    }
    
    // This method declares gets called whenever the searchCompleter has new search results
    // If you wanted to do any filter of the locations that are displayed on the the table view
    // this would be the place to do it.
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        
        // Can't filter search results by filtering out commas because places like Singapore wouldn't be covered
        // Basically just have to let the user figure it out and they have the choice of Chicago, IL or Andersonville, IL. Up to the user. Too much work to filter out the selections
        searchResults = completer.results
//        searchResults = completer.results.filter({!$0.subtitle.contains(",")})
//        print("Search Results\(searchResults.count) | \(searchController.searchBar.text)")
        
        // Reload the tableview with our new searchResults
        self.tableView.reloadData()
    }
    
    
    // This method is called when there was an error with the searchCompleter
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        //
        print("Error suggesting a location: \(error.localizedDescription)")
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return searchResults.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)

//        if let suggestion = searchResults[indexPath.row] {
//            // Each suggestion is a MKLocalSearchCompletion with a title, subtitle, and ranges describing what part of the title
//            // and subtitle matched the current query string. The ranges can be used to apply helpful highlighting of the text in
//            // the completion suggestion that matches the current query fragment.
//            cell.textLabel?.attributedText = createHighlightedString(text: suggestion.title, rangeValues: suggestion.titleHighlightRanges)
//            cell.detailTextLabel?.attributedText = createHighlightedString(text: suggestion.subtitle, rangeValues: suggestion.subtitleHighlightRanges)
//        }
        
        let suggestion = searchResults[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)

        //Set the content of the cell to our searchResult data
        cell.textLabel?.text = suggestion.title
        cell.detailTextLabel?.text = suggestion.subtitle
        return cell
    }
    
    private func createHighlightedString(text: String, rangeValues: [NSValue]) -> NSAttributedString {
        let attributes = [NSAttributedString.Key.backgroundColor: UIColor(named: "suggestionHighlight")! ]
        let highlightedString = NSMutableAttributedString(string: text)
        
        // Each `NSValue` wraps an `NSRange` that can be used as a style attribute's range with `NSAttributedString`.
        let ranges = rangeValues.map { $0.rangeValue }
        ranges.forEach { (range) in
            highlightedString.addAttributes(attributes, range: range)
        }
        
        return highlightedString
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let result = searchResults[indexPath.row]
        print("Result Title:", result.title)
        print("Result SubTitle:", result.subtitle)
//        print("RESULT :", result)
        let searchRequest = MKLocalSearch.Request(completion: result)
        
        // MKLOCALSEARCH RESULT PLACE FOR MORE INFO
        let search = MKLocalSearch(request: searchRequest)
        search.start { (response, error) in
            guard let coordinate = response?.mapItems[0].placemark.coordinate else {
                return
            }
            
            guard let placemark = response?.mapItems[0].placemark else {
                return
            }
            
            guard let name = response?.mapItems[0].name else {
                return
            }
            print("MapName: ", name)
            print("Coord: ", placemark.coordinate)
            print("Name: ", placemark.name ?? "")
            print("Country: ", placemark.country ?? "")
            print("CountryCode: ", placemark.countryCode ?? "")
            print("Subfare: ", placemark.subThoroughfare ?? "")
            print("Admin: ", placemark.administrativeArea ?? "")
            print("SubAdmin: ", placemark.subAdministrativeArea ?? "")
            print("Locality: ", placemark.locality ?? "")
            print("SubLocality: ", placemark.subLocality ?? "")

            let lat = coordinate.latitude
            let lon = coordinate.longitude
            var testName: String = ""
            
            // EVERY RESULT USUALLY HAS AN ADMIN NAME AND COUNTRY. LOCALITY IS A HIT OR MISS
            
            // IF NO LOCALITY USE PLACEMARK NAME
            if let local = placemark.locality {
                testName = String(local)
            } else if let name = placemark.name {
                testName = String(name)
            }
//            if placemark.locality != nil {
//                testName = placemark.name ?? ""
//            } else {
//                testName = placemark.locality ?? ""
//            }
//            testName = (placemark.name) ? (placemark.locality?.isEmptyOrWhitespace()) : placemark.locality
            
            // SOMETIMES NAME IS THE SAME AS ADMIN AREA, SO WE DON'T WANT DUPS
            if let admin = placemark.administrativeArea {
                if testName != admin {
                    if !testName.isEmptyOrWhitespace() {
                        testName += ", "
                    }
                    testName += "\(String(admin))"
                }
            }
            
            if let countryCode = placemark.countryCode {
                if testName != countryCode {
                    if !testName.isEmptyOrWhitespace() {
                        testName += ", "
                    }
                    testName += "\(String(countryCode))"
                }
            } else if let country = placemark.country {
                if testName != country {
                    if !testName.isEmptyOrWhitespace() {
                        testName += ", "
                    }
                    testName += "\(String(country))"
                }
            }

            


//            if (placemark.locality == nil || placemark.administrativeArea == nil || placemark.country == nil) && result.title != nil {
//                testName = "\(result.title)"
//            } else {
//                testName = "\(String(placemark.locality!)), \(String(placemark.administrativeArea!)), \(String(placemark.country!))"
//                if placemark.name == placemark.administrativeArea {
//                    testName = "TEST: \(String(placemark.name!)), \(String(placemark.country!))"
//                } else {
//                    testName = "TEST: \(String(placemark.name!)), \(String(placemark.administrativeArea!)), \(String(placemark.country!))"
//                }
//            }


            
            let locName = result.title
            var uploadedLocationGPS: String? = nil
//            if placemark.coordinate == nil {
//                uploadedLocationGPS = nil
//            } else {
//                let uploadedLocationGPSLatitude = String(format: "%f", (placemark.coordinate.latitude))
//                let uploadedlocationGPSLongitude = String(format: "%f", (placemark.coordinate.longitude))
//                uploadedLocationGPS = uploadedLocationGPSLatitude + "," + uploadedlocationGPSLongitude
//            }
            
            var uploadedLoc: CLLocation = CLLocation(latitude: placemark.coordinate.latitude, longitude: placemark.coordinate.longitude)
            self.delegate?.locationSelected(name: testName, loc: uploadedLoc)
            
            self.searchController.isActive = false
            self.dismiss(animated: true) {
                print("Dismiss")

            }
//            self.navigationController?.dismiss(animated: true, completion: {
//                print("Dismiss")
//
//            })
        
        }
    }
    
//    func searchNearestCityWithLocation(loc: CLLocation) {
//        guard let loc = loc else {
//            return
//        }
//
//        let request = MKLocalSearch.Request()
//        request.pointOfInterestFilter = . MKLocalSearchCompleter.ResultType([.address])
//        request.region = MKCoordinateRegion(center: loc.coordinate, latitudinalMeters: 100, longitudinalMeters: 100)
//
//
//
//
//    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
