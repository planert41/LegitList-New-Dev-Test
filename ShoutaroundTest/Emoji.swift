//
//  Emoji.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/16/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

struct EmojiSize {
    
    static var width = 40 as CGFloat

}


struct PostTagCounts {
    var ratingEmojiCounts: [String: Int]
    var captionCounts: [String: Int]
    var autotagCounts: [String:Int]
    var locationCounts: [String: Int]
    var cityCounts: [String: Int]
    var allCounts: [String:Int]

    init(ratingEmojiCounts: [String:Int] = [:], captionCounts: [String:Int] = [:], autotagCounts: [String:Int] = [:], locationCounts: [String:Int] = [:], cityCounts: [String:Int] = [:]) {
        self.ratingEmojiCounts = ratingEmojiCounts
        self.captionCounts = captionCounts
        self.autotagCounts = autotagCounts
        self.locationCounts = locationCounts
        self.cityCounts = cityCounts
        
        var tempAllCounts = captionCounts
        tempAllCounts += ratingEmojiCounts
        tempAllCounts += autotagCounts
        tempAllCounts += locationCounts
        tempAllCounts += cityCounts
        
        self.allCounts = tempAllCounts
    }
}


struct SearchTerm {
    var searchText: String?
    var searchType: String?
    var searchCount: Int = 0


    init(searchText: String? = "", searchType: String? = "", searchCount: Int? = 0) {
        self.searchText = searchText
        self.searchType = searchType
        self.searchCount = searchCount ?? 0
    }
}
