//
//  CommonSettings.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/20/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

// Location Name to Google Location ID
var locationGoogleIdDictionary:[String:String] = [:]

var GridCellEmojiHeight: CGFloat = 35
var GridCellImageHeightMult: CGFloat = 1 //1.25

var DefaultListNonRepeat = 0

var geoFilterRangeDefault:[String] = ["1", "3", "5", "25", "50", "100"]

var rankRangeDefaultOptions :[String] = ["Global","1", "3", "5", "25", "50", "100"]
var globalRangeDefault: String = "Global"
var defaultGeoWaitTime: Double = 0.5

var defaultPhotoResize = CGSize(width: 500, height: 500)
var defaultEmptyGPSName: String = "No Location"

var legitString: String = "👌"
var legitListName: String = "Legit"
var bookmarkListName: String = "Bookmarks"
var emptyBookmarkList = List.init(id: nil, name: "Bookmarks", publicList: 0)
var emptyLegitList = List.init(id: nil, name: "Legit", publicList: 1)
var defaultListNames:[String] = ["Bookmarks", "Legit"]

var starRatingCountDefault = 5

//var appBackgroundColor = UIColor.init(hex: "4DB6AC")
var appBackgroundColor = UIColor.white


// USER DEFAULTS
let weizouID = "2G76XbYQS8Z7bojJRrImqpuJ7pz2"
let meimeiID = "nWc6VAl9fUdIx0Yf05yQFdwGd5y2"
let maynardID = "srHzEjoRYKcKGqAgiyG4E660amQ2"
let magnusID = "B6div2WhzSObg7XGJRFkKBFEQiC3"
let legitID = "EbSrCmEl9ROpi6YZkTdO5aWlKKI2"

// Upload Defaults

var UploadTagSelection:[String] = ["🙋‍♂️ User", "😋 Smiley", "🍔 Eats", "☕️ Drinks", "🍩 Snacks", "🐮 Meat","🌱 Veg", "Other"]

var UploadTagSelectionRef:[String:[String]] = ["🙋‍♂️ User":CurrentUser.mostUsedEmojis, "😋 Smiley":smileyEmojis, "🍔 Eats":eatsEmojis, "☕️ Drinks":drinksEmojis, "🍩 Snacks":snacksEmojis, "🐮 Meat":meatEmojis,"🌱 Veg":vegEmojis, "Other":otherEmojis ]
var LocationSuggestUploadTagSelection: String = "🏠 Auto"


var UploadPostTypeEmojis:[String] = ["🍳","🥞","🍱","🍽","🍮","☕️","🍻","🌙","📍"]
var UploadPostTypeString:[String] = ["breakfast", "brunch", "lunch", "dinner", "dessert", "coffee", "drinks", "latenight", "other"]

var UploadPostCuisineEmojis:[String] = ["🇺🇸","🇲🇽","🇬🇷","🇹🇷","🇫🇷","🇮🇹","🇩🇪","🇪🇸","🇨🇳","🇯🇵","🇰🇷","🇮🇳","🇻🇳","🇵🇭","🇹🇭","🇲🇾","🇵🇹","🇨🇦","🇬🇧","🇮🇷","🇮🇪","🇸🇪","🇦🇷","🇧🇷","🇵🇪","🇨🇴","🇨🇺","🇪🇹","🇯🇲","🇳🇱","🇸🇳","🇷🇺"]

var UploadFoodRestrictEmoji:[String] = ["⛪️","🕍","🕌","☸️","❌🍖","❌🌽","❌🥜","❌🥛"]


var UploadPostTypeDefault:[String] = ["Brunch", "Lunch", "Dinner", "Late", "Coffee"]
var UploadPostPriceDefault:[String] = ["$5", "$10", "$20", "$35", "$50", "$$$"]


var CurrentUserLocation = "Current Location"

var emailMessage = "Email"
var iMessage = "iMessage"

var sortAuto = "Most Post"
var sortPost = "Posts"
var sortNew = "New"
var sortRecent = "Recent"
var sortTrending = "Trending"
var sortNearest = "Near"
var sortRank = "User"
var sortRating = "Rating"

var listAll = "All"
var listFollowed = "Followed Lists"
var listCreated = "My Lists"
var listLegit = "Legit Lists"
let legitListIds = ["A9A639A3-2C72-4003-B6D8-C3753E82D1AE"]

//var listTypeOptions:[String] = [listAll, listCreated, listFollowed]
//var listTypeDefault = listAll
var listTypeOptions:[String] = [listCreated, listFollowed, listLegit]
var listTypeDefault = listCreated
var listHeaderSortOptions:[String] = [sortRank, sortNearest]

// Home Post Format
var postGrid = "Grid"
var postList = "Grid"

var PostFormatOptions:[String] = [postGrid, postList]

// Home Header Sort Defaults
var HeaderSortOptions:[String] = [sortNew, sortNearest]
//var HeaderSortOptions:[String] = [sortNew, sortNearest, sortTrending]
//
let HeaderSortDefault:String = HeaderSortOptions[0]

var headerSortDictionary: [String: String] = [
    sortNearest: "📍 NEAREST",
    sortNew: "🛎 NEWEST",
    sortTrending: "🔥 TRENDING"
]

var ItemSortOptions:[String] = [sortPost, sortNew, sortNearest]
let ItemSortDefault:String = ItemSortOptions[0]


// Home Header Sort Defaults
var ViewListSortOptions:[String] = [sortNew, sortNearest, sortRank]
let ViewListSortDefault:String = HeaderSortOptions[0]

// List Header Sort Defaults
var ListSortOptions:[String] = [sortRecent, sortPost, sortTrending]
let ListSortDefault:String = ListSortOptions[0]

// Home Header Fetch Defaults
var HomeFetchOptions:[String] = ["Home Feed", "Community", "User", "List"]
//var HomeFetchDetails:[String] = ["Followed profiles & lists", "Everyone on LEGIT", "All YOUR posts", "Other Users"]
var HomeFetchDetails:[String] = ["Posts From People & Lists You Follow", "Posts From Everyone in The Community", "All YOUR posts", "Other Users"]

let HomeFetchDefault:String = HomeFetchOptions[0]

// SUBSCRIPTION
let annualSubProductID = "legit_premium_annual"
let monthlySubProductID = "legit_premium_monthly"
let indSubProductID = "creator_sub_credit"
let indSub1_ID = "creator_sub_1"
let indSub2_ID = "creator_sub_2"
let indSub5_ID = "creator_sub_5"
let indSub10_ID = "creator_sub_10"


// Home Search Bar Sort
var SearchBarOptions:[String] = [SearchAll, SearchEmojis, SearchPlace,SearchCity]

let SearchBarOptionsDefault:String = SearchBarOptions[0]
var SearchAll = "All"
var SearchEmojis = "Emoji"
var SearchFood = "Food"
var SearchType = "Type"
var SearchUser = "User"
var SearchPlace = "Rest"
var SearchCity = "City"
var SearchCaption = "Caption"
var SearchRating = "Rating"

var LegitSearchBarOptions:[String] = [SearchFoodImage, SearchCuisineImage, SearchRestaurantImage, SearchCityImage, SearchRatingImage]
let SearchAllImage = "🔍"
let SearchFoodImage = "🍔"
let SearchCuisineImage = "🍽"
let SearchRestaurantImage = "🏠"
let SearchCityImage = "🏙"
let SearchRatingImage = "⭐️"

let RatingCountArray: [Int: Int] =
[
    5: 0,
    4: 0,
    3: 0,
    2: 0,
    1: 0
]

let SearchSegmentLookup = [
    "🔍":"All",
    "🍔":"All Emojis",
    "🍽":"Cuisine",
    "🏠":"Places",
//    "🏙":"City",
    "⭐️":"Rating",
    "🙋‍♂️":"Users",
    "📋":"Lists",
    "🏙":"Cities",
    "🍜":"Posts"
]

let SearchBarTypeIndex: [String: Int] =
[
    SearchEmojis:0,
    SearchPlace: 1,
    SearchCity: 2,
    "": 999

]


var SearchEmojisIndex = 0
var SearchUserIndex = 1
var SearchLocationIndex = 2

// Location Header Sort - 
var LocationSortOptions:[String] = [sortNew, sortRating, sortTrending]

// Discover Header Sort -
var DiscoverList = "Lists"
var DiscoverUser = "Users"
var DiscoverPost = "Posts"
var DiscoverPlaces = "Places"
var DiscoverCities = "Cities"

var DiscoverOptions:[String] = [DiscoverList, DiscoverUser]
var DiscoverDefault:String = DiscoverList

var TabSearchOptions:[String] = [DiscoverUser, DiscoverList, DiscoverPlaces, DiscoverCities]
var TabSearchDefault:String = ListYours

// LIST OPTIONS
var ListYours = "Yours"
var ListFollowing = "Following"
var ListAll = "All Lists"
var ListOptions:[String] = [ListYours, ListFollowing, ListAll]
var ListDefault:String = ListYours

var DiscoverSortOptions:[String] = [sortPost, sortNew, sortNearest, sortTrending]
var DiscoverSortDefault = sortPost

var DualUserListSearchOptions:[String] = ["Users","Lists"]

// Friend Sort Options
var FriendSortOptions:[String] = ["Following","Followers"]
let FriendSortDefault:String = FriendSortOptions[0]

// List Sort Options
var ListSearchOptions:[String] = ["Created","Following"]
let ListSearchDefault:String = ListSearchOptions[0]

// User Search Options
var UserSearchOptions:[String] = ["Friends","Others"]
let UserSearchDefault:String = UserSearchOptions[0]

// Friend Sort Options
var FollowingSortOptions:[String] = ["Following", "Follower"]


// Rank Defaults
var defaultRankOptions = ["Votes", "Lists", "Messages", "New"]
var defaultRank = defaultRecentSort


// Filter Defaults

var FilterRatingDefault:[Int] = [1,2,3,4,5,6,7]
var FilterSortTimeDefault:[String] = ["Breakfast", "Lunch", "Dinner", "All"]
var FilterSortTimeStart:[Double] = [6,12,18,0]
var FilterSortTimeEnd:[Double] = [12,18,23,23]
var FilterSortDefault:[String] = [sortNearest, "Oldest", sortNew]
var FilterTimeDefault:[String] = ["Week", "Month", "6 Months", "Year", "All"]
var FilterTimeDefaultDict:[String:Int] = ["Week":7, "Month":30, "6 Months":180, "Year":360, "All":0]



let defaultRange = geoFilterRangeDefault[geoFilterRangeDefault.endIndex - 1]
let defaultGroup = "All"
let defaultRecentSort = sortNew
let defaultNearestSort = sortNearest
let defaultRankSort = sortRank

let defaultTime =  FilterSortTimeDefault[FilterSortTimeDefault.endIndex - 1]


// Default Texts
let blankUserDesc = "Tap To Add User Description"
let ListDescPlaceHolder = "Tap To Add List Description"

// GRID LIST POST FORMAT
let gridFormat: Int = 0
let postFormat: Int = 1
let fullFormat: Int = 2

// Search Bar Defaults

var searchBarPlaceholderText = "Search...."
//var searchBarPlaceholderText_Emoji = "Search 🍔 🇺🇸"
var searchBarPlaceholderText_Emoji = "Search... Try 🍤 "

var searchBarPlaceholderText_Location = "Current Location"

var searchScopeButtons = ["Food","Cuisine","Users","Places"]

// Tip Defaults
var tipDefaults = ["Search Posts by Food 🍔 Cuisine 🇺🇸 Or Meal 🍳","Click on the Legit Tag to See a User's LegitList","Posts are Auto-Tagged by Meal, Cuisine, and Diet Restrictions"]



var firebaseCountVariable:[String:String] = ["likes":"likeCount", "Messages":"messageCount", "Lists": "listCount", "Votes": "voteCount"]
var firebaseFieldVariable:[String:String] = [ "Votes": "post_votes", "Messages":"post_messages", "Lists": "post_lists", ]


// BADGES
var UserBadgesRef:[String] = ["First 100"]
let First100Image = #imageLiteral(resourceName: "redstar")
var UserBadgesImageRef:[UIImage] = [First100Image]

// SIGN UP DEFAULTS
let defaultProfileImageUrl = "https://firebasestorage.googleapis.com/v0/b/shoutaroundtest-ae721.appspot.com/o/profile_images%2FE38DD1E9-5B00-4736-B560-771D7BF785E1?alt=media&token=b580ec6b-a096-459d-aab7-6a8b07c45a46"

// FORMAT STANDARDS
var HeaderFontSizeDefault = UIFont.systemFont(ofSize: 16)

struct RatingColors {
    static func ratingColor (rating: Double?) -> UIColor {
        
        guard let rating = rating else {
            return UIColor.white
        }
        
        if rating == 0 {
            return UIColor.white    }
        else if rating <= Double(1) {
            return UIColor.rgb(red: 227, green: 27, blue: 35)   }
        else if rating <= Double(2) {
            return UIColor.rgb(red: 227, green: 27, blue: 35).withAlphaComponent(0.55)  }
        else if rating <= Double(3) {
            return UIColor.rgb(red: 255, green: 173, blue: 0).withAlphaComponent(0.55)  }
        else if rating <= Double(4) {
            return UIColor.rgb(red: 255, green: 173, blue: 0)   }
        else if rating <= Double(5) {
            return UIColor.rgb(red: 252, green: 227, blue: 0).withAlphaComponent(0.55)  }
        else if rating <= Double(6) {
            return UIColor.rgb(red: 252, green: 227, blue: 0)   }
        else if rating <= Double(7) {
            return UIColor.rgb(red: 91, green: 197, blue: 51)    }
        else {
            return UIColor.clear
        }
    }
}


struct Common {

}
