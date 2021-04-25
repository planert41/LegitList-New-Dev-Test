//
//  Filter.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/7/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import CoreLocation

class Filter {
    var filterCaption: String? = nil {
        didSet {
            filterCaption = (filterCaption?.removingWhitespaces() == "") ? nil : filterCaption
            self.checkIsFiltering()
        }
    }
    
    var filterCaptionArray: [String] = [] {
        didSet {
            self.checkIsFiltering()
        }
    }
    
    var filterRange: String? = nil {
        didSet {
            self.checkIsFiltering()
        }
    }
    var filterLocation: CLLocation? = nil {
        didSet {
            self.filterLocationTime = Date()
            self.checkIsFiltering()
        }
    }
    
    var filterLocationTime: Date = Date()
    
    var filterLocationName: String? = nil {
        didSet {
            self.checkGoogleLocationId()
            self.checkIsFiltering()
        }
    }
    var filterLocationSummaryID: String? = nil {
        didSet {
            self.checkIsFiltering()
        }
    }
    var filterGoogleLocationID: String? = nil {
        didSet {
            self.checkIsFiltering()
        }
    }
    var filterMinRating: Double = 0 {
        didSet {
            self.checkIsFiltering()
        }
    }
    var filterRatingEmoji: String? = nil {
        didSet {
            self.checkIsFiltering()
        }
    }
    var filterType: String? = nil {
        didSet {
            self.checkIsFiltering()
        }
    }
    
    var filterTypeArray: [String] = [] {
        didSet {
            self.checkIsFiltering()
        }
    }
    
    
    var filterMaxPrice: String? = nil {
        didSet {
            self.checkIsFiltering()
        }
    }
    var filterLegit: Bool = false {
        didSet {
            self.checkIsFiltering()
        }
    }
    var filterUser: User? = nil {
        didSet {
            self.checkIsFiltering()
        }
    }
    var filterList: List? = nil {
        didSet {
            self.checkIsFiltering()
        }
    }
    
    var filterTime: Int? = 0 {
        didSet {
            self.checkIsFiltering()
        }
    }
    
    var filterPostId: String? = nil {
        didSet {
            self.checkIsFiltering()
        }
    }
    
    var searchTermArray: [SearchTerm] = []
    var searchTerms:[String] = []
    var searchTermsType:[String] = []
    var searchTermsTypeDic:[String:String] = [:]

    var isFiltering: Bool = false

    var filterSort: String? = defaultRecentSort
    var defaultSort = defaultRecentSort
    
    func filterSummary() -> (String) {
        var summary = ""
        summary += "| \(filterCaption ?? "")"
        summary += "| \(filterCaptionArray.joined() ?? "")"
        summary += "| \(filterLocationName ?? "")"
        summary += "| \(filterLocationSummaryID ?? "")"
        summary += "| \(filterGoogleLocationID ?? "")"
        summary += "| \(filterUser?.username ?? "")"
        summary += "| \(filterList?.name ?? "")"
        summary += "| \(filterPostId ?? "")"
        summary += "| \(filterSort ?? "")"
        return summary
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Filter.init(filterCaption: filterCaption, filterRange: filterRange, filterLocation: filterLocation, filterLocationName: filterLocationName, filterLocationSummaryID: filterLocationSummaryID, filterGoogleLocationID: filterGoogleLocationID, filterMinRating: filterMinRating, filterType: filterType, filterMaxPrice: filterMaxPrice, filterLegit: filterLegit, filterUser: filterUser, filterList: filterList, filterSort: filterSort, filterTime: filterTime, filterRatingEmoji: filterRatingEmoji, filterCaptionArray: filterCaptionArray)
        return copy
    }
    
    init(filterCaption: String? = nil, filterRange: String? = nil, filterLocation: CLLocation? = nil, filterLocationName: String? = nil, filterLocationSummaryID: String? = nil, filterGoogleLocationID: String? = nil, filterMinRating: Double = 0, filterType: String? = nil, filterMaxPrice: String? = nil, filterLegit: Bool = false, filterUser: User? = nil, filterList: List? = nil, filterSort: String? = defaultRecentSort, filterTime: Int? = 0, filterRatingEmoji: String? = nil, filterCaptionArray: [String]? = []) {
        
        self.filterCaption = filterCaption
        self.filterRange = filterRange
        self.filterLocation = filterLocation
        self.filterLocationName = filterLocationName
        self.filterLocationSummaryID = filterLocationSummaryID
        self.filterGoogleLocationID = filterGoogleLocationID
        self.filterMinRating = filterMinRating
        self.filterType = filterType
        self.filterMaxPrice = filterMaxPrice
        self.filterLegit = filterLegit
        self.filterUser = filterUser
        self.filterList = filterList
        self.filterSort = filterSort
        self.defaultSort = filterSort!
        self.filterTime = filterTime
        self.filterRatingEmoji = filterRatingEmoji
        self.filterCaptionArray = filterCaptionArray ?? []

        self.checkIsFiltering()
    }
    
    
    init(defaultSort: String? = defaultRecentSort) {
        self.defaultSort = defaultSort!
        self.filterSort = defaultSort
        self.checkIsFiltering()
    }
    
    func clearFilter(sort: String? = nil){
        self.filterCaption = nil
        self.filterRange = nil
        self.filterLocation = CurrentUser.currentLocation
        self.filterLocationName = nil
        self.filterLocationSummaryID = nil
        self.filterGoogleLocationID = nil
        self.filterMinRating = 0
        self.filterType = nil
        self.filterMaxPrice = nil
        self.filterLegit = false
        self.filterUser = nil
        self.filterList = nil
        self.filterTime = 0
        self.filterPostId = nil
        self.filterRatingEmoji = nil
        self.isFiltering = false
        self.filterCaptionArray = []
        self.filterTypeArray = []
        if sort != nil {
            self.filterSort = sort
        }
//        self.filterSort = self.defaultSort
    }
    
    func clearFilterLocation(){
        self.filterRange = nil
        self.filterLocation = nil
        self.filterLocationName = nil
        self.filterLocationSummaryID = nil
        self.filterGoogleLocationID = nil
    }
    
    func refreshSort(sort: String? = nil){
        if let sort = sort {
            self.filterSort = sort
        } else {
            self.filterSort = self.defaultSort
        }
    }
    
    func checkIsFiltering(){
        if (self.filterCaption != nil && self.filterCaption?.removingWhitespaces() != "") || (self.filterRange != nil) || (self.filterRange == nil && self.filterGoogleLocationID != nil) || (self.filterMinRating != 0) || (self.filterType != nil) || (self.filterMaxPrice != nil) || (self.filterLegit == true) ||  (self.filterUser != nil) || (self.filterList != nil) || (self.filterTime! > 0) || (self.filterLocationSummaryID != nil) || self.filterPostId != nil || self.filterCaptionArray.count > 0 || self.filterTypeArray.count > 0 || self.filterRatingEmoji != nil
        
        {
            self.isFiltering = true
        } else {
            self.isFiltering = false
        }
        self.refreshSearchTerms()
    }
    
    func refreshSearchTerms(){
        self.searchTerms = []
        self.searchTermsType = []
        self.searchTermsTypeDic = [:]
        
        
        // CAPTION
        if self.filterCaptionArray.count > 0 {
            for x in self.filterCaptionArray {
                searchTerms.append(x)
                searchTermsType.append(SearchCaption)
                searchTermsTypeDic[x] = SearchCaption
            }
        }
        
        // Type
        if self.filterTypeArray.count > 0 {
            for x in self.filterTypeArray {
                searchTerms.append(x)
                searchTermsType.append(SearchType)
                searchTermsTypeDic[x] = SearchType
            }
        }
        
        // Rating
        if self.filterRatingEmoji != nil {
            guard let rating = self.filterRatingEmoji else {return}
            searchTerms.append(rating)
            searchTermsType.append(SearchRating)
            searchTermsTypeDic[rating] = SearchRating
        }

        
        if self.filterMinRating > 0 {
            let searchTermText = "\(self.filterMinRating) ⭐️"
            searchTerms.append(searchTermText)
            searchTermsType.append(SearchRating)
            searchTermsTypeDic[searchTermText] = SearchRating
        }
        
        //RESTAURANT
        if let location = self.filterLocationName {
            searchTerms.append(location)
            searchTermsType.append(SearchPlace)

        } else if let id = self.filterGoogleLocationID {
            if let name = locationGoogleIdDictionary.key(forValue: id) {
                searchTerms.append(name)
                searchTermsType.append(SearchPlace)

            }
        }
        
        
        // CITY
        if let location = self.filterLocationSummaryID {
            searchTerms.append(location)
            searchTermsType.append(SearchCity)
        }
        
//        searchTerms = Array(Set(searchTerms))
    }
    
    func checkGoogleLocationId() {
        guard let locationName = self.filterLocationName else {
            self.filterGoogleLocationID = nil
            return
        }
        if let id = locationGoogleIdDictionary[locationName] {
            self.filterGoogleLocationID = id
        } else if self.filterLocationName == nil {
            self.filterGoogleLocationID = nil
        }
    }
    
}
        
        // Assume that different search terms are separated by space
        
        /*
        // CAPTION
        if let _ = self.filterCaption {
            var tempFilterCaption = self.filterCaption ?? ""
            var tempCaptionWords = self.filterCaption?.components(separatedBy: " ") ?? []
            
        // DETECT COUNTRY FLAGS
            for x in cuisineEmojiSelect {
                if tempCaptionWords.contains(x) {
                    searchTerms.append(x)
                    searchTermsType.append(SearchCaption)
                    searchTermsTypeDic[x] = SearchCaption
                    if let index = tempCaptionWords.index(of: x) {
                        tempCaptionWords.remove(at: index)
                    }
                }
            }
            
            if searchTerms.count > 0 {
                print("Found \(searchTerms.count) Flags | \(searchTerms) | Rem: \(tempCaptionWords)")
            }
        
        // DETECT ALL EMOJIS
            for word in tempCaptionWords {
                if word.containsOnlyEmoji {
                    searchTerms.append(word)
                    searchTermsType.append(SearchCaption)
                    searchTermsTypeDic[word] = SearchCaption
                    if let index = tempCaptionWords.index(of: word) {
                        tempCaptionWords.remove(at: index)
                    }
                }
            }
            
        // WORDS
            for word in tempCaptionWords {
                    let x = word.alphaNumericOnly().removingWhitespaces()
                    searchTerms.append(x)
                    searchTermsType.append(SearchCaption)
                    searchTermsTypeDic[x] = SearchCaption
                    if let index = tempCaptionWords.index(of: x) {
                        tempCaptionWords.remove(at: index)
                    }
            }
        }
        
        */
            
            /*
        // DETECT OTHER EMOJIS
            for emoji in tempFilterCaption.emojis {
                if !emoji.isEmptyOrWhitespace() && emoji != "️" {
                    print(emoji)
                    searchTerms.append(emoji)
                    searchTermsType.append(SearchCaption)

                }
            }
            if !tempFilterCaption.isEmptyOrWhitespace() && tempFilterCaption != tempFilterCaption.emojis.joined() {
                searchTerms.append(tempFilterCaption)
                searchTermsType.append(SearchCaption)

            }
            
        // OTHER WORDS
            let text = tempFilterCaption.alphaNumericOnly().removingWhitespaces()
            if text.count > 0 {
                searchTerms.append(text)
                searchTermsType.append(SearchCaption)

            }
        }
 */
        
        // TYPE (NEED WORK, WHAT IF IT WAS LUNCH + CHINESE
//        if let filterAutoTag = self.filterType {
//            searchTerms.append(filterAutoTag)
//            searchTermsType.append(SearchType)
//
//        }
