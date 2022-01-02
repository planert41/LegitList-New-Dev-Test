//
//  LegitMapViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/1/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit

import mailgun
import GeoFire
import CoreGraphics
import CoreLocation
import EmptyDataSet_Swift
import UIFontComplete
import SVProgressHUD
import MapKit
import BSImagePicker
import TLPhotoPicker
import Photos
import CropViewController
import SKPhotoBrowser
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth

class NewTabMapViewController: UIViewController {

    // MARK: - MAP

    let mapView = MKMapView()
    var postDisplayed: Bool = false {
        didSet {
//            self.postCollectionView.isHidden = !postDisplayed
        }
    }
    
    let mapPinReuseInd = "MapPin"
    let regionRadius: CLLocationDistance = 5000
    
    var mapPins: [MapPin] = []
    // THIS IS TO BYPASS SCROLLVIEW CALL FUNCTION WHEN SCROLLTOITEM IS CALLED
    var enableScroll: Bool = true
    
    // MARK: - SEARCH
    var mapFilter: Filter = Filter.init(defaultSort: defaultNearestSort){
        didSet{
            print("TabMapView | mapFilter | \(mapFilter.filterCaptionArray) | \(mapFilter.filterUser?.username) | \(mapFilter.filterSort)")
            
            if self.mapFilter.filterSort != defaultNearestSort {
                print("TabMapView | default map filter to nearest")
                self.mapFilter.filterSort = defaultNearestSort
            }
            
            mapFilter.filterLocationName = (mapFilter.filterLocation == CurrentUser.currentLocation) ? CurrentUserLocation : mapFilter.filterLocationName
            self.updateSearchTerms()
            self.topSearchBar.viewFilter = self.mapFilter
            setupNavigationItems()
            
            if let user = mapFilter.filterUser {
                filteredUser = user
            } else if let list = mapFilter.filterList {
                filteredList = list
            }
            else
            {
                filteredUser = nil
                filteredList = nil
            }
        }
    }
    var newFilterSelected: Bool = false

    func updateSearchTerms() {
        searchTerms = Array(Set(self.mapFilter.searchTerms))
    }
    
    let search = LegitSearchViewControllerNew()
    
    var noFilterTagCounts: PostTagCounts = PostTagCounts.init()
    var currentPostTagCounts: PostTagCounts = PostTagCounts.init()
    var currentPostRatingCounts = RatingCountArray
    var noCaptionFilterTagCounts: [String:Int] = [:]
    var currentPostsFilterTagCounts: [String:Int] = [:]
    var first50EmojiCounts: [String:Int] = [:] {
        didSet {
            self.topSearchBar.displayedEmojisCounts = first50EmojiCounts
        }
    }
    var searchTerms: [String] = []

    let userListSearchView = DualUserListSearchView()

    let topSearchBar = UserSearchBar()
    
    var plainViewTap = UITapGestureRecognizer(target: self, action: #selector(passToSelectedPost))
    var rightCallOutViewTap = UITapGestureRecognizer(target: self, action: #selector(passToSelectedPost))
    var leftCallOutViewTap = UITapGestureRecognizer(target: self, action: #selector(passToSelectedPost))
    var mainCallOutViewTap = UITapGestureRecognizer(target: self, action: #selector(passToSelectedPost))

    
    func checkAppDelegateFilter(){

        if appDelegateFilter != nil {
            
            print("checkAppDelegateFilter | \(self.mapFilter.filterCaptionArray) | \(appDelegateFilter!.filterUser?.username)")
            
            var transferFilter = appDelegateFilter!
            transferFilter.filterSort = defaultNearestSort
            self.mapFilter = transferFilter
            print("checkAppDelegateFilter | Reload App Delegate Filter | Refresh Map")
            appDelegateFilter = nil
            self.refreshPostsForFilter()
            
            
            
            // CANT SEEM TO GET THIS TO WORK. MAP FILTER SOMEHOW EQUALS TRANSFERFILTER
//            if self.mapFilter.filterSummary() == transferFilter.filterSummary()
//            {
//                print("checkAppDelegateFilter | Same Filter | No Refresh")
//            }
//            else {
//                self.mapFilter = transferFilter
//                self.mapFilter.filterSort = defaultNearestSort
//                print("checkAppDelegateFilter | Reload App Delegate Filter | Refresh Map")
//                appDelegateFilter = nil
//                self.refreshPostsForFilter()
//            }
        } else {
            print("checkAppDelegateFilter | No App Delegate Filter")
        }
        

    }
    
    
    var morePostButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "expand").withRenderingMode(.alwaysOriginal), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.tintColor = UIColor.ianBlackColor()
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//        button.addTarget(self, action: #selector(tapCancelButton), for: .touchUpInside)
        return button
    }()
    
    lazy var morePostLabel: UILabel = {
        let ul = UILabel()
        ul.isUserInteractionEnabled = true
        ul.text = ">>>"
        ul.numberOfLines = 0
        ul.textAlignment = NSTextAlignment.right
        ul.font = UIFont(name: "Poppins-Bold", size: 13)
        ul.textColor = UIColor.darkGray
        return ul
    }()
    
    lazy var hideLabel: UILabel = {
        let ul = UILabel()
        ul.isUserInteractionEnabled = true
        ul.text = "Hide Info"
        ul.numberOfLines = 0
        ul.textAlignment = NSTextAlignment.right
        ul.font = UIFont(name: "Poppins-Bold", size: 14)
        ul.textColor = UIColor.mainBlue()
        return ul
    }()

    // MARK: - NAVIGATION

    var navHomeButton: UIButton = TemplateObjects.NavBarHomeButton()
    var navSearchButton: UIButton = TemplateObjects.NavSearchButton()
    var navSearchButtonFull: UIButton = TemplateObjects.NavSearchButton()

//    var navCancelButton: UIButton = TemplateObjects.NavCancelButton()


    // MARK: - NAVIGATION - SEARCH BAR

    let fullSearchBarView = UIView()
    var fullSearchBar = UISearchBar()
    lazy var fullSearchBarCancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.tintColor = UIColor.ianBlackColor()
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.addTarget(self, action: #selector(tapCancelButton), for: .touchUpInside)
        return button
    }()
    
    
    @objc func tapCancelButton() {
        self.handleRefresh()
    }

    
    @objc func toggleListView(){
        
        appDelegateFilter = self.mapFilter
        if self.mapFilter.filterList != nil {
            appDelegateViewPage = 1
            print("Toggle MapView | List View | \(appDelegateViewPage)")
        } else if self.mapFilter.filterUser != nil {
            appDelegateViewPage = 2
            print("Toggle MapView | User View | \(appDelegateViewPage)")
        } else {
            appDelegateViewPage = 0
            print("Toggle MapView | Home View | \(appDelegateViewPage)")
        }
        
        NotificationCenter.default.post(name: AppDelegate.SwitchToListNotificationName, object: nil)
        
    }
    
    var keyboardTap = UITapGestureRecognizer()
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if (self.isViewLoaded && (self.view.window != nil)) {
            print("keyboardWillShow | Add Tap Gesture | SingleUserProfileViewController")
            self.view.addGestureRecognizer(self.keyboardTap)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification){
        if (self.isViewLoaded && (self.view.window != nil)) {
            print("keyboardWillHide | Remove Tap Gesture | SingleUserProfileViewController")
            self.view.removeGestureRecognizer(self.keyboardTap)
        }
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
//        userSearchBar.resignFirstResponder()
        print("dismissKeyboard | SingleUserProfileViewController")
        self.view.endEditing(true)
    }
        
    
    
    // MARK: - COLLECTIONVIEW - EMOJIS
    
    
    let addTagId = "addTagId"
    let filterTagId = "filterTagId"
    let refreshTagId = "refreshTagId"

    var displayedEmojis: [String] = [] {
        didSet {
            print("LegitHomeHeader | \(displayedEmojis.count) Emojis")
        }
    }
    
    var listDefaultEmojis = mealEmojisSelect
    
    
    // MARK: - COLLECTIONVIEW - POSTS
    lazy var postCollectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = .white
        cv.layer.borderColor = UIColor.darkLegitColor().cgColor
        return cv
    }()
    
    let postCollectionViewFlowLayout = UICollectionViewFlowLayout()
    
    let cellId = "cellId"
    let gridCellId = "gridcellId"
    let listHeaderId = "headerId"
    var scrolltoFirst: Bool = false
    
    let postContainer = UIView()
    var postContainerHeightConstraint:NSLayoutConstraint?
//    var postHalfHeight = 100
    var postHalfHeight = 75
    var postFullHeight = 350
    var isPostFullView: Bool = false {
        didSet {
//            self.refreshPostCollectionView()
            self.togglePostHeight()
        }
    }

    var pageControl : UIPageControl = UIPageControl()

    let emojiDetailLabel: LightPaddedUILabel = {
        let label = LightPaddedUILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 25)
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.rgb(red: 255, green: 242, blue: 230)
        label.layer.cornerRadius = 30/2
        label.layer.borderWidth = 0.25
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.masksToBounds = true
        return label
    }()
    
    /*
    var hidePostHeightConstraint:NSLayoutConstraint?
    var postViewHeightConstraint:NSLayoutConstraint?
    var fullListViewConstraint:NSLayoutConstraint?
    
    var mapViewHeightConstraint:NSLayoutConstraint?
    
    let hideMapViewHideHeight: CGFloat = UIApplication.shared.statusBarFrame.height
    
    let headerHeight: CGFloat = 40 //40
    let postHeight: CGFloat = 180 //150
    let fullHeight: CGFloat = UIScreen.main.bounds.height - UIApplication.shared.statusBarFrame.height
    */
    
    let navView = UIView()
    let navSearchView = UIView()

    let refreshButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "refresh_blue"), for: .normal)
//        button.setImage(#imageLiteral(resourceName: "refresh_white"), for: .normal)
        button.addTarget(self, action: #selector(handleRefresh), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()
    
    lazy var expandListButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "listFormat").withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.tintColor = UIColor.white
        button.backgroundColor = UIColor.ianBlackColor()
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.addTarget(self, action: #selector(expandList), for: .touchUpInside)
        return button
    }()

    @objc func expandList(){
        print("Expand List")
    }
    
    lazy var trackingButton: MKUserTrackingButton = {
        let button = MKUserTrackingButton()
        //        button.layer.backgroundColor = UIColor(white: 1, alpha: 0.8).cgColor
        button.layer.backgroundColor = UIColor.lightGray.withAlphaComponent(0.25).cgColor
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 5
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()
    
    lazy var zoomOutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "listFormat").withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.tintColor = UIColor.white
        button.backgroundColor = UIColor.ianBlackColor()
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.addTarget(self, action: #selector(expandList), for: .touchUpInside)
        return button
    }()
    
    let globeButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "Globe"), for: .normal)
//        button.setImage(#imageLiteral(resourceName: "zoom_out").withRenderingMode(.alwaysTemplate), for: .normal)
        button.addTarget(self, action: #selector(showGlobe), for: .touchUpInside)
        
//        button.addTarget(self, action: #selector(testFunc), for: .touchUpInside)
        button.tintColor = UIColor.mainBlue()
        button.tintColor = UIColor.darkGray
        button.layer.backgroundColor = UIColor.clear.cgColor
//        button.layer.cornerRadius = button.frame.width/2
//        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()
    
    func testFunc() {
        self.postCollectionView.scrollToNextItem()
    }
    
    var filteredUser: User? {
        didSet {
            print("NewTabMapView | filteredUser Loaded| \(filteredUser?.username)")
            guard let filteredUser = filteredUser else {
//                filterUserButton.setImage(#imageLiteral(resourceName: "profile_unselected"), for: .normal)
//                filterUserLabel.text = ""
                self.clearUserButton()
                return}
            
            filteredList = nil
            updateUserButtonImage()

//            filterUserLabel.text = filteredUser.username.capitalizingFirstLetter()
//
//            let temp = CustomImageView()
//            temp.loadImage(urlString: filteredUser.profileImageUrl)
//            filterUserButton.setImage(temp.image, for: .normal)
//            filterUserButton.alpha = (filterUserLabel.text == "") ? 0.8 : 1

        }
    }
    
    var filteredList: List? {
        didSet {
            print("NewTabMapView | filteredList Loaded | \(filteredList?.name)")
            guard let filteredList = filteredList else {
//                filterUserButton.setImage(#imageLiteral(resourceName: "profile_unselected"), for: .normal)
//                filterUserLabel.text = ""
                self.clearUserButton()
                return}
            
            filteredUser = nil
            updateUserButtonImage()
            
//            filterUserLabel.text = filteredList.name.capitalizingFirstLetter()
            
//            if let header = filteredList.heroImageUrl {
//                let temp = CustomImageView()
//                temp.loadImage(urlString: header)
//                filterUserButton.setImage(temp.image, for: .normal)
//                print("NewTabMapView | filteredList Loaded Header Image | \(header)")
//            } else if filteredList.listImageUrls.count > 0 {
//                for (x, imgUrl) in (filteredList.listImageUrls ?? []).enumerated() {
//                    if !imgUrl.isEmptyOrWhitespace() {
//                        let firstImage = imgUrl
//                        let temp = CustomImageView()
//                        temp.loadImage(urlString: firstImage)
//                        filterUserButton.setImage(temp.image, for: .normal)
//                        print("NewTabMapView | filteredList | No Header Image | Loaded First Image | \(x) | \(firstImage)")
//                        break
//                    }
//                }
//            }
//
//            filterUserButton.alpha = (filterUserLabel.text == "") ? 0.8 : 1
        }
    }
    
    func updateDetailLabel() {
        if let filteredUser = self.filteredUser {
            detailLabel.text = "\(self.mapFilter.filterLegit ? "Top " : "" )Posts from \(filteredUser.username.capitalizingFirstLetter())"
            detailLabel.sizeToFit()
            detailLabel.isHidden = false
        } else if let filteredList = self.filteredList {
            detailLabel.text = "\(self.mapFilter.filterLegit ? "Top " : "" )Posts in \(filteredList.name.capitalizingFirstLetter())"
            detailLabel.sizeToFit()
            detailLabel.isHidden = false
        } else if self.mapFilter.filterLegit {
            detailLabel.text = "Filtering Top Posts"
            detailLabel.sizeToFit()
            detailLabel.isHidden = false
        }
        else {
            detailLabel.isHidden = true
        }
        
        detailLabel.textColor = self.mapFilter.filterLegit ? UIColor.customRedColor() : UIColor.gray
    }
    
    
    func updateUserButtonImage(){
        filterUserButton.layer.borderWidth = 1
        let temp = CustomImageView()
        if let filteredUser = self.filteredUser {
            temp.loadImage(urlString: filteredUser.profileImageUrl)
            filterUserButton.setImage(temp.image, for: .normal)
            
            filterUserLabel.text = filteredUser.username.capitalizingFirstLetter()
            filterUserButton.alpha = (filterUserLabel.text == "") ? buttonSemiAlpha : 1
            print("NewTabMapView | updateUserButtonImage | filteredUser Loaded| \(filteredUser.username)")
        }
        
        else if let filteredList = self.filteredList {
            if let header = filteredList.heroImageUrl {
                temp.loadImage(urlString: header)
                filterUserButton.setImage(temp.image, for: .normal)
                print("NewTabMapView | updateUserButtonImage | filteredList | Header Image | \(header)")
            }
            else if filteredList.listImageUrls.count > 0 {
                for (x, imgUrl) in (filteredList.listImageUrls ?? []).enumerated() {
                    if !imgUrl.isEmptyOrWhitespace() {
                        let firstImage = imgUrl
                        temp.loadImage(urlString: firstImage)
                        filterUserButton.setImage(temp.image, for: .normal)
                        print("NewTabMapView | updateUserButtonImage | filteredList | No Header Image | Loaded First Image | \(x) | \(firstImage)")
                        break
                    }
                }
            }
            
            filterUserLabel.text = filteredList.name.capitalizingFirstLetter()
            filterUserButton.alpha = (filterUserLabel.text == "") ? buttonSemiAlpha : 1
        }
        
        else {
            // NO FILTERED USER OR LIST. DISPLAY CURRENT USER IMAGE
            clearUserButton()
        }
        updateFilterLegitButton()
        updateDetailLabel()
    }
    
    func clearUserButton() {
//        let temp = CustomImageView()
//        let userImageURL = CurrentUser.profileImageUrl
//        temp.loadImage(urlString: userImageURL)
//        filterUserButton.setImage(temp.image, for: .normal)
        if filteredUser == nil && filteredList == nil {
//            let defaultImage = #imageLiteral(resourceName: "Globe").withRenderingMode(.alwaysOriginal)
            let defaultImage = #imageLiteral(resourceName: "filter").withRenderingMode(.alwaysOriginal)
//            let defaultImage = #imageLiteral(resourceName: "filter").withRenderingMode(.alwaysOriginal)
//            let homeIcon = #imageLiteral(resourceName: "home").withRenderingMode(.alwaysTemplate)
            let homeIcon = #imageLiteral(resourceName: "home_tab_filled").withRenderingMode(.alwaysOriginal)

            filterUserButton.setImage(homeIcon, for: .normal)
            
            filterUserLabel.text = ""
            filterUserButton.alpha = (filterUserLabel.text == "") ? buttonSemiAlpha : 1
            filterUserButton.layer.borderWidth = 0
        } else {
            updateUserButtonImage()
        }
        updateFilterLegitButton()
    }
    
    func resetButtons() {
//        filterUserButton.setImage(#imageLiteral(resourceName: "profile_unselected"), for: .normal)
//        filterUserLabel.text = ""
//        filterUserButton.alpha = (filterUserLabel.text == "") ? 0.8 : 1
//
//        filterListButton.setImage(#imageLiteral(resourceName: "bookmark_unfilled"), for: .normal)
//        filterListLabel.text = ""
//        filterListButton.alpha = (filterListLabel.text == "") ? 0.8 : 1

        clearUserButton()

        filterSuggestionButton.setTitle(suggestedEmoji, for: .normal)
        filterSuggestionLabel.text = ""
        
        updateFilterLegitButton()
        
        updateFilterSuggestedButtons()
        
    }
    
    let filterUserButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "profile_unselected"), for: .normal)
        button.addTarget(self, action: #selector(openUserListFilter), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.white.cgColor
        button.layer.cornerRadius = button.frame.width/2
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor.gray.cgColor
        button.layer.borderWidth = 1
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()
    
    let buttonSemiAlpha = 0.8
    
    lazy var filterUserLabel: UILabel = {
        let ul = UILabel()
        ul.isUserInteractionEnabled = true
        ul.numberOfLines = 0
        ul.textAlignment = NSTextAlignment.right
        ul.font = UIFont(name: "Poppins-Bold", size: 15)
//        ul.textColor = UIColor.ianBlackColor()
        ul.textColor = UIColor.ianBlackColor()
        return ul
    }()
    
    

    
    let filterListButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "bookmark_unfilled"), for: .normal)
        button.addTarget(self, action: #selector(openListFilter), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.white.cgColor
        button.layer.cornerRadius = button.frame.width/2
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 1
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()
    
    let filterLegitButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "legit_icon"), for: .normal)
        button.addTarget(self, action: #selector(filterLegitPosts), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.white.cgColor
        button.layer.cornerRadius = button.frame.width/2
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 0
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()
    
    func updateFilterLegitButton() {
        filterLegitButton.backgroundColor = self.mapFilter.filterLegit ? UIColor.lightSelectedColor() : UIColor.ianWhiteColor()
        filterLegitButton.alpha = self.mapFilter.filterLegit ? 1 : buttonSemiAlpha

    }
    
    @objc func filterLegitPosts() {
        self.mapFilter.filterLegit = !self.mapFilter.filterLegit
        print("NewTabMapView | filterLegitPosts - \(self.mapFilter.filterLegit)")
        self.updateFilterLegitButton()
        self.updateDetailLabel()
        self.refreshPostsForFilter()
    }
    
    
    lazy var filterListLabel: UILabel = {
        let ul = UILabel()
        ul.isUserInteractionEnabled = true
        ul.numberOfLines = 0
        ul.textAlignment = NSTextAlignment.right
        ul.font = UIFont(name: "Poppins-Bold", size: 15)
        ul.textColor = UIColor.ianBlackColor()
        return ul
    }()
    
    var suggestedEmoji = "☕️" {
        didSet {
            self.updateFilterSuggestedButtons()
        }
    }
    var suggestedEmojiName = "Coffee"
    var suggestedEmoji2 = "☕️"  {
           didSet {
               self.updateFilterSuggestedButtons()
           }
       }
    var suggestedEmojiName2 = "☕️"

    let filterSuggestionButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//        button.setImage(#imageLiteral(resourceName: "ribbon"), for: .normal)
        button.setTitle("", for: .normal)
        button.addTarget(self, action: #selector(filterSuggestedEmoji1), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.white.cgColor
        button.layer.cornerRadius = button.frame.width/2
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor.gray.cgColor
        button.layer.borderWidth = 1
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()

    lazy var filterSuggestionLabel: UILabel = {
        let ul = UILabel()
        ul.isUserInteractionEnabled = true
        ul.numberOfLines = 0
        ul.textAlignment = NSTextAlignment.right
        ul.font = UIFont(name: "Poppins-Bold", size: 15)
        ul.textColor = UIColor.ianBlackColor()
        return ul
    }()
    
    let filterSuggestionButton2: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//        button.setImage(#imageLiteral(resourceName: "ribbon"), for: .normal)
        button.setTitle("", for: .normal)
        button.addTarget(self, action: #selector(filterSuggestedEmoji2), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.white.cgColor
        button.layer.cornerRadius = button.frame.width/2
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor.gray.cgColor
        button.layer.borderWidth = 1
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()

    lazy var filterSuggestionLabel2: UILabel = {
        let ul = UILabel()
        ul.isUserInteractionEnabled = true
        ul.numberOfLines = 0
        ul.textAlignment = NSTextAlignment.right
        ul.font = UIFont(name: "Poppins-Bold", size: 15)
        ul.textColor = UIColor.ianBlackColor()
        return ul
    }()
    
    
    lazy var detailLabel: PaddedUILabel = {
        let ul = PaddedUILabel()
        ul.isUserInteractionEnabled = false
        ul.numberOfLines = 0
        ul.textAlignment = NSTextAlignment.center
        ul.font = UIFont(name: "Poppins-Bold", size: 12)
        ul.textColor = UIColor.darkGray
        ul.backgroundColor = UIColor.lightSelectedColor()
        ul.alpha = 0.9
        ul.layer.cornerRadius = 10
        ul.clipsToBounds = true
        return ul
    }()
    
        
    // BOTTOM EMOJI BAR
    var bottomEmojiBar = BottomEmojiBar()
    var bottomEmojiBarHide: NSLayoutConstraint?
    var bottomEmojiBarHeight: CGFloat = 50
    
    fileprivate func setupNavigationItems() {
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.isNavigationBarHidden = true
        
        self.navigationController?.navigationBar.isTranslucent = true
        // REMOVES THE 1PX BOTTOM LINE IN NAV BAR
        self.navigationController?.navigationBar.shadowImage = UIImage()
        

 
//        self.setupButtons()
        // SEARCH BAR
//        self.refreshSearchBar()
        
    }
    


    
    func showClearNavBar(){
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.layoutIfNeeded()
        
        
    }

    var timer =  Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } 
        
        if appDelegateFilter != nil {
            print("MainViewController | Filter Init | Load AppDelegateFilter")
            self.checkAppDelegateFilter()
//            self.mapFilter = appDelegateFilter!
        } else {
            print("MainViewController | Filter Init | No AppDelegateFilter - Self Init")
//            self.mapFilter = Filter.init()
        }

        setupNotificationCenters()
        setupNavigationItems()
        
    // ADD MAP VIEW
        setupMap()
        view.addSubview(mapView)
        mapView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        self.centerMapOnLocation(location: (self.mapFilter.filterLocation != nil) ? self.mapFilter.filterLocation : CurrentUser.currentLocation)
        

    // POST COLLECTION VIEW
        view.addSubview(postContainer)
//        postContainer.anchor(top: nil, left: expandListButton.rightAnchor, bottom: expandListButton.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        postContainer.anchor(top: nil, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 0, height: 0)
        postContainerHeightConstraint = postContainer.heightAnchor.constraint(equalToConstant: 0)
        postContainerHeightConstraint?.isActive = true
        postContainer.backgroundColor = UIColor.lightBackgroundGrayColor()
        postContainer.layer.applySketchShadow(color: UIColor(red: 0, green: 0, blue: 0, alpha: 1), alpha: 0.5, x: 0, y: 3, blur: 4, spread: 0)
        
        view.addSubview(hideLabel)
        hideLabel.anchor(top: nil, left: postContainer.leftAnchor, bottom: postContainer.topAnchor, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        hideLabel.isHidden = true
        hideLabel.isUserInteractionEnabled = true
        hideLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(togglePost)))

       setupPostCollectionView()
       postContainer.addSubview(postCollectionView)
       postCollectionView.anchor(top: postContainer.topAnchor, left: postContainer.leftAnchor, bottom: nil, right: postContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: CGFloat(self.postFullHeight))
       
        
        view.addSubview(morePostLabel)
        morePostLabel.anchor(top: nil, left: nil, bottom: postContainer.topAnchor, right: postContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        morePostLabel.sizeToFit()
//        timer = Timer(timeInterval: 1.0, target: self, selector: "blinkMoreButton", userInfo: nil, repeats: true)
        timer = Timer(timeInterval: 1.0, target: self, selector: "blinkMoreButton", userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: RunLoop.Mode.common)

        
    //CURRENT USER LOCATION BUTTON
        view.addSubview(trackingButton)
        trackingButton.anchor(top: nil, left: nil, bottom: morePostLabel.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 20, width: 35, height: 35)
        trackingButton.isHidden = false
        trackingButton.backgroundColor = UIColor.white.withAlphaComponent(0.75)
    

    // ZOOM OUT WORLD BUTTON
        view.addSubview(globeButton)
        globeButton.anchor(top: nil, left: nil, bottom: trackingButton.topAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 20, width: 40, height: 40)
        globeButton.centerXAnchor.constraint(equalTo: trackingButton.centerXAnchor).isActive = true

        
// FILTER LEGIT BUTTON
        view.addSubview(filterLegitButton)
        filterLegitButton.anchor(top: nil, left: nil, bottom: globeButton.topAnchor, right: nil, paddingTop: 12, paddingLeft: 0, paddingBottom: 10, paddingRight: 20, width: 40, height: 40)
        filterLegitButton.centerXAnchor.constraint(equalTo: trackingButton.centerXAnchor).isActive = true
        filterLegitButton.layer.cornerRadius = 40/2
        updateFilterLegitButton()
        
    
        
        
//    // FILTER USER BUTTON
        view.addSubview(filterUserButton)
        filterUserButton.anchor(top: nil, left: nil, bottom: filterLegitButton.topAnchor, right: nil, paddingTop: 12, paddingLeft: 0, paddingBottom: 10, paddingRight: 20, width: 40, height: 40)
        filterUserButton.centerXAnchor.constraint(equalTo: trackingButton.centerXAnchor).isActive = true
        filterUserButton.layer.cornerRadius = 40/2
        userListSearchView.inputUser = CurrentUser.user
        userListSearchView.delegate = self
        clearUserButton()

//        view.addSubview(filterUserLabel)
//        filterUserLabel.anchor(top: nil, left: nil, bottom: nil, right: filterUserButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 2, width: 0, height: 0)
//        filterUserLabel.centerYAnchor.constraint(equalTo: filterUserButton.centerYAnchor).isActive = true
        

    // REFRESH BUTTON
        view.addSubview(refreshButton)
        refreshButton.anchor(top: nil, left: nil, bottom: filterUserButton.topAnchor, right: nil, paddingTop: 15, paddingLeft: 0, paddingBottom: 10, paddingRight: 20, width: 40, height: 40)
        refreshButton.centerXAnchor.constraint(equalTo: trackingButton.centerXAnchor).isActive = true
        refreshButton.layer.cornerRadius = 40/2
        refreshButton.setTitle("", for: .normal)
        refreshButton.layer.borderWidth = 1
        refreshButton.layer.borderColor = UIColor.mainBlue().cgColor
        refreshButton.backgroundColor = UIColor.white
        refreshButton.layer.masksToBounds = true
        refreshButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleRefresh)))
        refreshButton.isHidden = !self.mapFilter.isFiltering

        
            
    
        
        

    // MARK: - BOTTOM NAV BARS
//            view.addSubview(expandListButton)
//            expandListButton.anchor(top: nil, left: nil, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 15, paddingRight: 20, width: 30, height: 30)



                
        
        
//           view.addSubview(emojiDetailLabel)
//           emojiDetailLabel.anchor(top: nil, left: nil, bottom: postContainer.topAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 3, paddingRight: 0, width: 0, height: 0)
//           emojiDetailLabel.centerXAnchor.constraint(equalTo: postContainer.centerXAnchor).isActive = true
//           self.hideEmojiDetailLabel()


// MARK: - TOP NAV BARS

    // TOP SEARCH BAR
        view.addSubview(topSearchBar)
        topSearchBar.delegate = self
        topSearchBar.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        topSearchBar.searchBarView.backgroundColor = UIColor.clear
        topSearchBar.navSearchButton.backgroundColor = UIColor.backgroundGrayColor()
        topSearchBar.navEmojiButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        topSearchBar.navEmojiButton.setTitleColor(UIColor.darkGray, for: .normal)
        topSearchBar.fullSearchBar.tintColor = UIColor.white.withAlphaComponent(0.9)
        topSearchBar.fullSearchBar.barTintColor = UIColor.white.withAlphaComponent(0.9)
        topSearchBar.filteringLabel.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        topSearchBar.fullSearchBar.searchBarStyle = .minimal
        topSearchBar.showEmoji = true
        topSearchBar.navGridToggleButton.isHidden = true
        topSearchBar.navGridButtonWidth?.constant = 0
        topSearchBar.layoutIfNeeded()


        setupFilterSuggestedButtons()
        resetButtons()
        
        
    // DETAIL LABEL
        view.addSubview(detailLabel)
        detailLabel.anchor(top: topSearchBar.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 4, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 0, height: 0)
        detailLabel.centerXAnchor.constraint(equalTo: postContainer.centerXAnchor).isActive = true
        detailLabel.isHidden = true

        

//        // FILTER USER BUTTON
//            view.addSubview(filterUserButton)
//            filterUserButton.anchor(top: nil, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 12, paddingLeft: 0, paddingBottom: 0, paddingRight: 20, width: 40, height: 40)
//            filterUserButton.centerYAnchor.constraint(equalTo: topSearchBar.centerYAnchor).isActive = true
//        topSearchBar.rightAnchor.constraint(equalTo: filterUserButton.leftAnchor).isActive = true
////            filterUserButton.anchor(top: nil, left: nil, bottom: globeButton.topAnchor, right: nil, paddingTop: 12, paddingLeft: 0, paddingBottom: 10, paddingRight: 20, width: 40, height: 40)
////            filterUserButton.centerXAnchor.constraint(equalTo: trackingButton.centerXAnchor).isActive = true
//            filterUserButton.layer.cornerRadius = 40/2
//            userListSearchView.inputUser = CurrentUser.user
//            userListSearchView.delegate = self
//            clearUserButton()
//
//            view.addSubview(filterUserLabel)
//        filterUserLabel.anchor(top: filterUserButton.bottomAnchor, left: nil, bottom: nil, right: filterUserButton.rightAnchor, paddingTop: 3, paddingLeft: 0, paddingBottom: 0, paddingRight: 2, width: 0, height: 0)
////            filterUserLabel.centerYAnchor.constraint(equalTo: filterUserButton.centerYAnchor).isActive = true
            


        
        
        
        // SEARCH BUTTON
    //        view.addSubview(navSearchButton)
    //        navSearchButton.anchor(top: topLayoutGuide.bottomAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 20, width: 40, height: 40)
    //        navSearchButton.layer.cornerRadius = 40/2
    //        navSearchButton.setTitle("", for: .normal)
    //        navSearchButton.layer.borderWidth = 1
    ////        navSearchButton.layer.borderColor = UIColor.ianBlackColor().cgColor
    //        navSearchButton.layer.borderColor = UIColor.darkGray.cgColor
    //
    //        navSearchButton.backgroundColor = UIColor.white
    //        navSearchButton.layer.masksToBounds = true
    //        navSearchButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapSearchButton)))
            
            
        // BOTTOM EMOJI BAR
    //        let emojiContainer = UIView()
    //        self.view.addSubview(emojiContainer)
    //        emojiContainer.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: navSearchButton.leftAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 5, paddingRight: 15, width: 0, height: 0)
    //        emojiContainer.layer.applySketchShadow(color: UIColor(red: 0, green: 0, blue: 0, alpha: 1), alpha: 0.5, x: 0, y: 2, blur: 4, spread: 0)
    //        bottomEmojiBarHide = emojiContainer.heightAnchor.constraint(equalToConstant: 0)
    //        bottomEmojiBarHide?.isActive = true
    //
    //        emojiContainer.addSubview(bottomEmojiBar)
    //        bottomEmojiBar.anchor(top: emojiContainer.topAnchor, left: emojiContainer.leftAnchor, bottom: emojiContainer.bottomAnchor, right: emojiContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
    //        bottomEmojiBar.delegate = self
    //        bottomEmojiBar.layer.cornerRadius = 5
    //        bottomEmojiBar.layer.masksToBounds = true
    //        bottomEmojiBar.layer.borderColor = UIColor.lightGray.cgColor
    //        bottomEmojiBar.layer.borderWidth = 1
    //        // Hide Emoji Bar
    //        bottomEmojiBar.navSearchButtonEqualWidth?.constant = 0
    //        bottomEmojiBar.layoutIfNeeded()



    //    // FILTER LIST BUTTON
    //        view.addSubview(filterSuggestionButton)
    //        filterSuggestionButton.anchor(top: topSearchBar.bottomAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 12, paddingLeft: 0, paddingBottom: 0, paddingRight: 20, width: 40, height: 40)
    //        filterSuggestionButton.layer.cornerRadius = 40/2
    //        filterSuggestionButton.setTitle(suggestedEmoji, for: .normal)
    //        view.addSubview(filterSuggestionLabel)
    //        filterSuggestionLabel.anchor(top: nil, left: nil, bottom: nil, right: filterSuggestionButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 2, width: 0, height: 0)
    //        filterSuggestionLabel.centerYAnchor.constraint(equalTo: filterSuggestionButton.centerYAnchor).isActive = true
    //
    //    // FILTER LIST BUTTON
    //        view.addSubview(filterSuggestionButton2)
    //        filterSuggestionButton2.anchor(top: filterSuggestionButton.bottomAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 12, paddingLeft: 0, paddingBottom: 0, paddingRight: 20, width: 40, height: 40)
    //        filterSuggestionButton2.layer.cornerRadius = 40/2
    //        filterSuggestionButton2.setTitle(suggestedEmoji, for: .normal)
    //        view.addSubview(filterSuggestionLabel2)
    //        filterSuggestionLabel2.anchor(top: nil, left: nil, bottom: nil, right: filterSuggestionButton2.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 2, width: 0, height: 0)
    //        filterSuggestionLabel2.centerYAnchor.constraint(equalTo: filterSuggestionButton2.centerYAnchor).isActive = true
    //
        
        
    }
    
    
    func setupPageControl(){
        self.pageControl.numberOfPages = (self.fetchedPosts.count) ?? 3
        self.pageControl.currentPage = 0
        self.pageControl.tintColor = UIColor.lightGray
        self.pageControl.pageIndicatorTintColor = UIColor.lightGray
        self.pageControl.currentPageIndicatorTintColor = UIColor.ianLegitColor()
//        self.pageControl.isHidden = (self.pageControl.numberOfPages == 0)
        //        self.pageControl.backgroundColor = UIColor.rgb(red: 68, green: 68, blue: 68)
    }

    var blinkStatus = true
    @objc func blinkMoreButton(){
        if blinkStatus == false {
            UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut, animations: {
                self.morePostLabel.alpha = 0.1
                self.blinkStatus = true
            }, completion: nil)

        } else {
            UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut, animations: {
                self.morePostLabel.alpha = 0.8
                self.blinkStatus = false
            }, completion: nil)

        }
    }
    
    
    func setupNotificationCenters(){
        
        // FUNCTIONS FOR NEW POSTS
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateFeed), name: SharePhotoListController.updateFeedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(locationDenied), name: AppDelegate.LocationDeniedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(locationUpdated), name: AppDelegate.LocationUpdatedNotificationName, object: nil)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.setupNavigationItems()
        self.updateUserButtonImage()
//        self.checkAppDelegateFilter()
        if CurrentUser.user == nil {
            Database.loadCurrentUser(inputUser: nil) {
                self.fetchAllPostIds()
            }
        } else if self.fetchedPostIds.count == 0 {
            self.fetchAllPostIds()
        }
        
        // KEYBOARD TAPS TO EXIT INPUT
        self.keyboardTap = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - POST FETCHING AND HANDLING
    
    // POST VARIABLES
    var selectedMapPost: Post? = nil {
        didSet {
//            print("  ~ selectedMapPost | \(selectedMapPost?.id) | \(selectedMapPost?.locationName)")
//            self.showSelectedPost()
        }
    }
    var fetchedPostIds: [PostId] = []
    var fetchedPosts: [Post] = []
    var filteredPosts: [Post] = []

    
    var isFetching = false

    var noCaptionFilterEmojiCounts: [String:Int] = [:]
    var noCaptionFilterPlaceCounts: [String:Int] = [:]
    var noCaptionFilterCityCounts: [String:Int] = [:]
    
    
    // FETCHING POSTS
    func fetchAllPostIds(){
        SVProgressHUD.show(withStatus: "Loading Posts")
        Database.fetchCurrentUserAllPostIds { (postIds) in
            /*
            if self.fetchedPostIds.count == postIds.count && self.fetchedPostIds.contains(postIds[0]){
                return
            } else {
                print("   ~ Database | Fetched PostIds | \(postIds.count)")
                self.fetchedPostIds = postIds
                self.fetchAllPosts()
            }
            */
            
            print("   ~ Database | Fetched PostIds | \(postIds.count)")
            self.fetchedPostIds = postIds
            self.fetchAllPosts()
            
//            NotificationCenter.default.post(name: MainViewController.finishFetchingUserPostIdsNotificationName, object: nil)
        }
    }

    
    @objc func finishFetchingPostIds(){
        self.fetchAllPosts()
    }
    
    func fetchAllPosts(){
        if isFetching {
            print(" ~ BUSY FETCHING POSTS")
        } else {
            isFetching = true
        }
        
        print("MainView | Fetching All Post, Current Location: ", CurrentUser.currentLocation?.coordinate)
        Database.fetchAllPosts(fetchedPostIds: self.fetchedPostIds){fetchedPostsFirebase in
            self.fetchedPosts = fetchedPostsFirebase
            print("NewTabMapView | fetchAllPosts | \(self.fetchedPosts.count) Posts | \(self.fetchedPostIds.count) Post Ids")
            self.filterSortFetchedPosts()
        }
    }
    

    
    
    func updateNoFilterCounts(){
        
        Database.summarizePostTags(posts: self.fetchedPosts) { (tagCounts) in
            self.currentPostTagCounts = tagCounts
            self.currentPostsFilterTagCounts = tagCounts.allCounts
            if !self.mapFilter.isFiltering {
                self.noCaptionFilterTagCounts = tagCounts.allCounts
                self.noFilterTagCounts = tagCounts
            }
        }
        
        Database.summarizeRatings(posts: self.fetchedPosts) { (ratingCounts) in
            self.currentPostRatingCounts = ratingCounts
        }
        
        let first100 = Array(self.fetchedPosts.prefix(100))
    
        Database.countEmojis(posts: first100, onlyEmojis: true) { (emojiCounts) in
            self.first50EmojiCounts = emojiCounts
//            self.initSearchSelections()
            print("   HomeView | NoFilter Emoji Count | \(emojiCounts.count)")
        }
    }

    
    @objc func locationUpdated() {
        if self.isPresented  {
            if self.mapFilter.filterSort == sortNearest {
                self.mapFilter.filterLocation = CurrentUser.currentLocation
                print("NewTabMapView Location UPDATED | \(CurrentUser.currentLocation)")
                self.filterSortFetchedPosts()
            }
        }
    }
    
    @objc func locationDenied() {
        if self.isPresented {
            self.missingLocAlert()
            self.mapFilter.filterSort = sortNew
            self.filterSortFetchedPosts()
            print("NewTabMapView Location Denied Function")
        }
    }

    
    func filterSortFetchedPosts(){
        
        updateNoFilterCounts()
        
        Database.checkLocationForSort(filter: self.mapFilter) {
            // Filter Posts
            Database.filterPostsNew(inputPosts: self.fetchedPosts, postFilter: self.mapFilter) { (filteredPosts) in
                            
                // NEED TO DO FILTERING SINGLE POST BEFORE SORTING
                // Sort Posts
                Database.sortPosts(inputPosts: self.additionalMapFilter(posts: filteredPosts) ?? [], selectedSort: self.mapFilter.filterSort, selectedLocation: self.mapFilter.filterLocation, completion: { (filteredPosts) in
                
                // FILTER POSTS FOR ONE POST PER LOCATION TO AVOID CLUSTERING
                    self.fetchedPosts = filteredPosts ?? []
                    print("   ~ Database | \(filteredPosts!.count ?? 0) Posts | After Sort/Filter")

                    if (self.mapFilter.isFiltering) {
                        // IF SELECTED SPECIFIC POST ID
                        if let filterPostId = self.mapFilter.filterPostId {
                            self.selectedMapPost = self.fetchedPosts.filter({ (post) -> Bool in
                                post.id == filterPostId
                            }).first
                            self.showSelectedPost()
                            print("Filter Sort | Is Filtering | Specific post | \(self.selectedMapPost?.id)")
                        }
                            
                        else if self.fetchedPosts.count > 0 {
                            print("Filter Sort | Is Filtering | Auto selected post | \(self.selectedMapPost?.id)")
                            self.selectedMapPost = self.fetchedPosts[0]
                            
                        } else if self.fetchedPosts.count == 0 {
                            print("Filter Sort | Is Filtering | No Post")
                            self.hidePost()
                        }
                    }
                    
                    self.isFetching = false
                    self.refreshButton.isHidden = !self.mapFilter.isFiltering
                    self.refreshMap()
                    self.refreshBottomEmojiBar()
                    self.refreshPostCollectionView()
                    self.topSearchBar.filteredPostCount = self.fetchedPosts.count
                    self.topSearchBar.viewFilter = self.mapFilter

                    print("NewMapViewController | Filter Sorted Post: \(self.fetchedPosts.count) | Selected | \(self.selectedMapPost?.id) ")

                    
                    if self.isRefreshing {
                        if CurrentUser.currentLocation == nil {
                            self.showGlobe()
                        } else {
                            self.centerMapOnLocation(location: CurrentUser.currentLocation)
                        }
                        self.isRefreshing = false
                        print(" Go to Current Location | Refreshing")
                    }
                })
            }
        }
    }
    
    
    func additionalMapFilter(posts: [Post]?)  -> ([Post]?){
        // EXCLUDE POSTS WITHOUT GPS
        guard let posts = posts else {
            return nil
        }
        
        var tempPosts = posts.filter { (post) -> Bool in
            return !(post.locationGPS == nil || (post.locationGPS?.coordinate.latitude == 0 && post.locationGPS?.coordinate.longitude == 0))
        }
        
        print("  additionalMapFilter | \(tempPosts.count) Filtered Posts | Removed \(posts.count - tempPosts.count) Posts w/o GPS | \(posts.count) Post Inputs")

        
    // Separate each posts into array by google loc Id to make single post filtering easier later
        var noLocationIDPosts = tempPosts.filter({return $0.locationGooglePlaceID == ""})
        var haveLocationIDPosts = tempPosts.filter({return $0.locationGooglePlaceID != ""})
        
        var tempLocationPosts:[Post] = []
        var tempLocationNamePosts:[Post] = []
        
        
    // POSTS WITH GOOGLE LOCATION ID
        var googleLocPostDic:[String:[Post]] = [:]
        for post in haveLocationIDPosts {
            let googleLocId = post.locationGooglePlaceID ?? ""
            if googleLocId != "" {
                if let _ = googleLocPostDic[googleLocId] {
                    googleLocPostDic[googleLocId]?.append(post)
                    print("   ~ Dup GoogleLoc | \(post.locationName) : \(post.locationGooglePlaceID) : \(post.id) Post ID")
                } else {
                    googleLocPostDic[googleLocId] = [post]
                }
            }
        }
        
    // PICK ONE POST FOR EACH LOCATION
        for (key,posts) in googleLocPostDic {
            if let pickedPost = Database.pickOnePostForLocation(posts: posts, googleLocationID: key, locationName: nil) {
                tempLocationPosts.append(pickedPost)
            }
        }
        print("   ~ With Google Locations | \(tempLocationPosts.count) Posts | \(googleLocPostDic.count) Google Location IDs | \(haveLocationIDPosts.count) Input Posts")
    
        
    // Posts without Google Location ID but with adresses etc
        var locNamePostDic:[String:[Post]] = [:]
        for post in noLocationIDPosts {
            let locName = post.locationName ?? ""
            if locName != "" {
                if let _ = locNamePostDic[locName] {
                    locNamePostDic[locName]?.append(post)
                } else {
                    locNamePostDic[locName] = [post]
                }
            }
        }
//        print("\(locNamePostDic.count) Total NON-Google Locations | \(noLocationIDPosts.count) Post")

        for (key,posts) in locNamePostDic {
            if let pickedPost = Database.pickOnePostForLocation(posts: posts, googleLocationID: nil, locationName: key) {
                tempLocationNamePosts.append(pickedPost)
            }
        }
        
        print("   ~ NO Google Locations | \(tempLocationNamePosts.count) Posts | \(locNamePostDic.count) Google Location IDs | \(noLocationIDPosts.count) Input Posts")
        
        
        print("  additionalMapFilter | \((tempLocationNamePosts + tempLocationPosts).count) Posts| \(tempLocationNamePosts.count) NoLocID | \(tempLocationPosts.count) Google LocID Posts | \(googleLocPostDic.count) Google LocID | Removed \(posts.count - tempPosts.count) Posts w/o GPS | \(posts.count) Post Inputs")
        return(tempLocationNamePosts + tempLocationPosts)

    }
    
    func refreshPostCollectionView(){

        self.postCollectionViewFlowLayout.estimatedItemSize = CGSize(width: self.postCollectionView.frame.width, height: CGFloat(self.postFullHeight))
        self.postCollectionView.collectionViewLayout = self.postCollectionViewFlowLayout
        self.view.layoutIfNeeded()
//        self.postContainerHeightConstraint?.constant = CGFloat(10 + (self.isPostFullView ? self.postFullHeight : self.postHalfHeight))
        
        
        UIView.animate(withDuration: 1,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .curveEaseIn,
                       animations: { [weak self] in
                        var height = CGFloat(10 + ((self?.isPostFullView ?? false) ? self?.postFullHeight ?? 0 : self?.postHalfHeight ?? 0))
                        self?.postContainerHeightConstraint?.constant = height
            },
                       completion: nil)

        self.postCollectionView.reloadData()
        SVProgressHUD.dismiss()
        print("NewLegitMapViewController | refreshPostCollectionView | Complete")
        
    }
    
    func togglePostHeight(){
        self.postContainerHeightConstraint?.constant = CGFloat(10 + (self.isPostFullView ? self.postFullHeight : self.postHalfHeight))
        self.hideLabel.isHidden = !self.isPostFullView
        self.hideLabel.isUserInteractionEnabled = !self.hideLabel.isHidden
//        self.postCollectionViewFlowLayout.estimatedItemSize = CGSize(width: self.postCollectionView.frame.width, height: CGFloat(self.isPostFullView ? self.postFullHeight : self.postHalfHeight))
//        self.postCollectionView.collectionViewLayout = self.postCollectionViewFlowLayout
        self.showSelectedPost()
    }
    
    func showSelectedPost() {
        guard let selectedPostId = self.selectedMapPost?.id else {return}
        if let index = self.fetchedPosts.firstIndex(where: { (post) -> Bool in
            return post.id == selectedPostId
        }) {
            
            let currentIndex = Int(self.postCollectionView.contentOffset.x / self.postCollectionView.frame.size.width)
            if index != currentIndex {
                print("Need to Scroll Post to Selected Index | selected \(index) | current \(currentIndex)")
                
                if self.postCollectionView.numberOfItems(inSection: 0) >= index {
                    let indexpath = IndexPath(row:index, section: 0)
//                    self.postCollectionView.reloadItems(at: [indexpath])
//                    self.postCollectionView.reloadData()
//                    self.postCollectionView.layoutIfNeeded()
                    
                    let xoffset = CGFloat(index) * self.postCollectionView.frame.size.width
                    
                    self.postCollectionView.moveToFrame(contentOffset: xoffset)
//                    self.postCollectionView.scrollToItem(at: indexpath, at: .centeredHorizontally, animated: true)
                    print("  ~ showSelectedPost | Scroll to Post | \(indexpath) | \(self.selectedMapPost?.id)")
                } else {
                    print("  ~ showSelectedPost | No Post Yet. Need to reload | \(index) | \(self.postCollectionView.numberOfItems(inSection: 0)) | \(self.selectedMapPost?.id)")
                    self.postCollectionView.reloadData()
                }

            } else {
             //   print("  ~ showSelectedPost  Already Scrolled to Selected Index")
            }
        } else {
            // CAN'T FIND SELECTED POST ID IN FETCHED POST
            Database.fetchPostWithPostID(postId: selectedPostId) { (post, error) in
                if let post = post {
                    self.fetchedPosts.append(post)
                    self.postCollectionView.reloadData()
                    print("  ~ showSelectedPost | Post Not Fetched - Reloaded Post CV | \(selectedPostId)")
                    self.showSelectedPost()
                } else {
                    print("  ~ showSelectedPost | ERROR Can't Find Post - Reloaded Post CV | \(selectedPostId)")
                }
            }
        }
    }
    
    
    func showSelectedPostOnMap() {
        let selectedPostId = self.selectedMapPost?.id ?? ""
        let postLocationName = self.selectedMapPost?.locationName ?? ""
        let postLocationGoogleId = self.selectedMapPost?.locationGooglePlaceID ?? ""

        var selectedAnnotation: MKAnnotation?
        
    // PICK ANNOTATION BY GOOGLE ID FIRST
        if postLocationGoogleId != ""
        {
//            print(self.mapView.annotations.count)
             selectedAnnotation = self.mapView.annotations.first { (annotationPost) -> Bool in
                if let annotation = annotationPost as? MapPin {
                    return annotation.locationGoogleId == postLocationGoogleId
                } else {
                    if annotationPost.title != "My Location" {
                        print("showSelectedPostOnMap | No googleLocId annotation For \(annotationPost.title) | \(annotationPost.subtitle) | \(annotationPost.coordinate)")
                    }
                    return false
                }
            }
            
            if selectedAnnotation == nil {
                var tempPost = self.fetchedPosts.first { (post) -> Bool in
                    return post.locationGooglePlaceID == postLocationGoogleId
                }
                if let tempPost = tempPost {
                    var temp = MapPin(post: tempPost)
                    self.mapView.addAnnotation(temp)
                    selectedAnnotation = temp
                    print("Adding Missing Annotation | \(temp.locationName) | \(temp.postId)")
                }
            }

        }
            
    // PICK ANNOTATION BY LOCATION NAME

        else if postLocationName != ""
        {
             selectedAnnotation = self.mapView.annotations.first { (annotationPost) -> Bool in
                if let annotation = annotationPost as? MapPin {
                    return annotation.locationName == postLocationName
                } else {
                    if annotationPost.title != "My Location" {
                        print("showSelectedPostOnMap | No postLocationName annotation For \(annotationPost.title) | \(annotationPost.subtitle) | \(annotationPost.coordinate)")
                    }
                    return false
                }
            }
        }
    // PICK ANNOTATION BY POST ID

            else if selectedPostId != ""
            {
                 selectedAnnotation = self.mapView.annotations.first { (annotationPost) -> Bool in
                    if let annotation = annotationPost as? MapPin {
                        return annotation.postId == selectedPostId
                    } else {
                        if annotationPost.title != "My Location" {
                            print("showSelectedPostOnMap | No selectedPostId annotation For \(annotationPost.title) | \(annotationPost.subtitle) | \(annotationPost.coordinate)")
                        }
                        return false
                    }
                }
            }

        
        print("selectedAnnotation: ", selectedAnnotation?.title, selectedAnnotation?.subtitle, selectedAnnotation?.coordinate)
        if let selectedAnnotation = selectedAnnotation
        {
            if self.isRefreshing {
                self.centerMapOnLocation(location: CurrentUser.currentLocation)
                self.isRefreshing = false
                print("showSelectedPostOnMap | Refreshing")
            } else {
                self.mapView.deselectAnnotation(selectedAnnotation, animated: true)
                self.mapView.selectAnnotation(selectedAnnotation, animated: true)
                let tempLoc = CLLocation(latitude: selectedAnnotation.coordinate.latitude, longitude: selectedAnnotation.coordinate.longitude)
                self.centerMapOnLocation(location: tempLoc, radius: 5000, closestLocation: nil)
                print("Show Selected Post | \(selectedAnnotation.title) | \(selectedPostId)")
            }

        } else {
            self.centerMapOnLocation(location: CurrentUser.currentLocation)
            print("showSelectedPostOnMap | Cur Loc | Failed to Find Annotation | \(selectedPostId)")
        }
    }
    
    
    func showPostSummary(){
        
    }
    
    
    func showPostFull(){
        
    }
    
    func showListFull(){
        
    }
    
    func hidePost(){
        
    }
    
    // MARK: - REFRESH FUNCTIONS

    func clearAllPosts(){
        self.fetchedPostIds.removeAll()
        self.fetchedPosts.removeAll()
  }
    
    func clearSort(){
        self.mapFilter.filterSort = defaultNearestSort
//        self.mapFilter.refreshSort()
    }
    
    func clearCaptionSearch(){
        self.mapFilter.filterCaption = nil
        self.fullSearchBar.text = nil
//        self.refreshPostsForFilter()
    }
    
    func clearFilter(){
        self.mapFilter.clearFilter(sort: defaultNearestSort)
        self.mapFilter.filterSort = defaultNearestSort
        self.mapFilter.filterLocation = CurrentUser.currentLocation
        self.filteredUser = nil
        self.filteredList = nil
    }

    func refreshAll(){
        self.isRefreshing = true
        self.clearCaptionSearch()
        self.clearFilter()
        self.clearSort()
        self.clearAllPosts()
        self.setupNavigationItems()
        self.fetchAllPostIds()
        self.refreshSearchBar()
        self.resetButtons()
        self.updateDetailLabel()
        //        self.postCollectionView.reloadData()
        //        self.collectionView?.reloadData()
    }
    
    func refreshPosts(){
        self.clearAllPosts()
    }
    
    func refreshPostsForFilter(){
        self.setupNavigationItems()
        self.clearAllPosts()
        self.refreshSearchBar()
        self.scrolltoFirst = true
        self.fetchAllPostIds()
        
    }

    
    @objc func handleUpdateFeed() {
        
        // Check for new post that was edited or uploaded
        if newPost != nil && newPostId != nil {#imageLiteral(resourceName: "icons8-hash-30.png")
            self.fetchedPosts.insert(newPost!, at: 0)
            self.fetchedPostIds.insert(newPostId!, at: 0)
            
            self.postCollectionView.reloadData()
            if self.postCollectionView.numberOfItems(inSection: 0) != 0 {
                let indexPath = IndexPath(item: 0, section: 0)
                self.postCollectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
            }
            print("Pull in new post")
            
        } else {
            self.handleRefresh()
        }
    }
    
    func refreshWithoutMovingMap(){
        self.refreshAll()
        self.postCollectionView.refreshControl?.endRefreshing()
    }
    
    var isRefreshing: Bool = false
    
    @objc func handleRefresh() {
        self.refreshAll()
        self.postCollectionView.refreshControl?.endRefreshing()
        print("Refresh Home Feed. FetchPostIds: ", self.fetchedPostIds.count, "FetchedPostCount: ", self.fetchedPosts.count)
        self.centerMapOnLocation(location: CurrentUser.currentLocation)
    }
    

    
}

// MARK: - MAP

extension NewTabMapViewController : MKMapViewDelegate {

    
    @objc func showGlobe(){

        var location: CLLocation?
        
        UIView.animate(withDuration: 2, delay: 0, options: UIView.AnimationOptions.curveLinear, animations: {
            self.detailLabel.text = "Zooming Out"
            self.detailLabel.sizeToFit()
            self.detailLabel.isHidden = false

        }, completion: { (finished: Bool) in
            self.updateDetailLabel()
        })
        
        if CurrentUser.currentLocation == nil {
            location = defaultLocation
            print("showGlobe | No Current User Location | Default Location")
        } else {
            location = CurrentUser.currentLocation
            print("showGlobe | Current User Location | CurrentUser.currentLocation")
        }
        
        guard let location = location else {return}
        
        let coordinateRegion = MKCoordinateRegion.init(center: location.coordinate,
                                                                  latitudinalMeters: regionRadius*1000, longitudinalMeters: regionRadius*1000)
        mapView.setRegion(coordinateRegion, animated: true)


        
    }

    
    
    func setupMap(){
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.mapType = MKMapType.standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.register(MapPinMarkerView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
//        mapView.register(ClusterMapPinMarkerView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        
        mapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapMap)))
        
        
        trackingButton = MKUserTrackingButton(mapView: mapView)
        //        button.layer.backgroundColor = UIColor(white: 1, alpha: 0.8).cgColor
        trackingButton.layer.backgroundColor = UIColor.lightGray.withAlphaComponent(0.25).cgColor
        trackingButton.layer.borderColor = UIColor.white.cgColor
        trackingButton.layer.borderColor = UIColor.mainBlue().cgColor
        
        trackingButton.layer.borderWidth = 1
        trackingButton.layer.cornerRadius = 5
        trackingButton.translatesAutoresizingMaskIntoConstraints = true
    }
    
    @objc func didTapMap(){
        self.minimizeCollectionView()
//        if self.isPostFullView {
//            print("Tap Map | Minimize Post View ")
//            self.isPostFullView = false
//        }
    }
    
    @objc func minimizeCollectionView(){
        if self.isPostFullView {
            print("Minimize Post View | hideMinimizeCollectionView")
            self.isPostFullView = false
        }
    }
    
    @objc func refreshMap(){
        print("  ~ Refresh Map | NewLegitMapViewController")
        self.addMapPins()
    }

    func removeMapPins(){
        print("  ~  Remove All Map Pins ")

        for annotation in self.mapView.annotations {
            // REMOVE ALL ANNOTATION BESIDES USER CURRENT LOCATION
            if (!annotation.isKind(of: MKUserLocation.self)){
                self.mapView.removeAnnotation(annotation)
            }
        }
    }
    
    func addMapPins(){
        print("  ~  Adding Map Pins  ")
        SVProgressHUD.show(withStatus: "Refreshing Map Pins")
        
        self.mapPins = []
        self.removeMapPins()
        
        if self.fetchedPosts.count == 0 {
            print("NewLegitMapViewController | No Posts | Adding 0 Map Pins")
            return
        }
        
    // ADD MAP PINS
        for post in self.fetchedPosts {
            if post.locationGPS != nil && post.id != nil {
                var temp = MapPin(post: post)
                temp.alwaysShow = (self.filteredUser != nil || self.filteredList != nil)
                self.mapPins.append(temp)
            }
        }
        mapView.addAnnotations(self.mapPins)
        print("  ~ addMapPins : Added \(mapView.annotations.count) Pins | \(self.mapPins.count) Posts ")
        
        
    // MAPVIEW FOCUS
        
        let tempSortPost = self.fetchedPosts.sorted(by: { (p1, p2) -> Bool in
            return (Double(p1.distance ?? 9999)) <= (Double(p2.distance  ?? 9999))
        })
        
        let closestPost = (tempSortPost.count > 0) ? tempSortPost[0] : nil
        let filterLocation = self.mapFilter.filterLocation ?? nil
        
        // SELECTED POST ID
        var selectedPostId: String? = nil
        selectedPostId = (appDelegatePostID != nil) ? appDelegatePostID : selectedPostId
        selectedPostId = (mapFilter.filterPostId != nil) ? mapFilter.filterPostId : selectedPostId
        selectedPostId = (self.selectedMapPost?.id != nil) ? self.selectedMapPost?.id : selectedPostId
        
        
    // POST WAS SELECTED - ZOOM TO SELECTED POST LOCATION
        if selectedPostId != nil {
            let selectedAnnotation = self.mapView.annotations.first { (annotationPost) -> Bool in
                if let annotation = annotationPost as? MapPin {
                    return annotation.postId == selectedPostId
                } else {
                    return false
                }
            }

            
            if let selectedAnnotation = selectedAnnotation
            {

                self.mapView.selectAnnotation(selectedAnnotation, animated: true)
                let tempLoc = CLLocation(latitude: selectedAnnotation.coordinate.latitude, longitude: selectedAnnotation.coordinate.longitude)
                let distance = tempLoc.distance(from: CurrentUser.currentLocation ?? tempLoc)


                if self.newFilterSelected && distance > (regionRadius * 2) {
//                    self.centerMapOnLocation(location: tempLoc, radius: distance * 2.2, closestLocation: nil)
                    self.centerMapOnLocation(location: tempLoc, radius: min(regionRadius * 50, distance * 2.2), closestLocation: nil)

                    self.newFilterSelected = false
                    print("  ~ addMapPins | Too Far | Zoom Out | Selected \(selectedAnnotation.title) : \(selectedPostId) | \(distance)")

                } else {
                    self.centerMapOnLocation(location: tempLoc, radius: 5000, closestLocation: nil)
                    print("  ~ addMapPins | Selected: \(selectedAnnotation.title) | \(selectedPostId)")

                }

            } else {
                print(" Going to Cur Loc, Failed to Selected Post - \(selectedPostId)")
                self.centerMapOnLocation(location: CurrentUser.currentLocation)
            }
            
            appDelegatePostID = nil
        }
        
        
        
    // USER SEARCHED FOR SPECIFIC LOCATION - ZOOM TO LOCATION
        else if filterLocation != nil && self.mapFilter.filterLocationName != CurrentUserLocation
        {
            let annotation = MKPointAnnotation()
            let centerCoordinate = CLLocationCoordinate2D(latitude: (filterLocation?.coordinate.latitude)!, longitude:(filterLocation?.coordinate.longitude)!)
            annotation.coordinate = centerCoordinate
            annotation.title = self.mapFilter.filterLocationName
            mapView.addAnnotation(annotation)
            print("  ~ addMapPins | Center @ CurFilterLoc | \(filterLocation)")
            self.centerMapOnLocation(location: filterLocation)
        }
           
    // POSTS ARE TOO FAR FROM USER - ZOOM TO SHOW CENTER OF ALL POSTS
        else if (closestPost?.distance ?? 0) >= (regionRadius * 100) {
            var locations = [] as [CLLocation]
            for post in tempSortPost {
                if let loc = post.locationGPS {
                    locations.append(loc)
                }
            }
            
            mapView.setRegion(SharedFunctions.mapCenterForCoordinates(listCoords: locations), animated: true)
            print("Nearest Post Too Far | Show Center For All Posts")
        }
        
    // SHOW CLOSEST POST
        else if let nearestLoc = closestPost?.locationGPS {
            self.centerMapOnLocation(location: nearestLoc)
        }
            
    // SHOW CURRENT USER LOCATION
        else {
            self.centerMapOnLocation(location: CurrentUser.currentLocation)
        }
        
        SVProgressHUD.dismiss()
    print("FINISH | ADD MAP PIN")

    }
    
    
    

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        let annotation = view.annotation as! MapPin
        
        let postId = annotation.postId
        let post = fetchedPosts.filter { (post) -> Bool in
            post.id == postId
        }
        print("TAPPED ANNOT VIEW | Show Single Post | \(postId)")
        
        let pictureController = SinglePostView()
        pictureController.post = post.first
        
        navigationController?.pushViewController(pictureController, animated: true)
        
        //        if control == view.rightCalloutAccessoryView  || control == view.detailCalloutAccessoryView{
        //            let postId = annotation.postId
        //            let post = fetchedPosts.filter { (post) -> Bool in
        //                post.id == postId
        //            }
        //
        //            let pictureController = PictureController(collectionViewLayout: UICollectionViewFlowLayout())
        //            pictureController.selectedPost = post.first
        //
        //            navigationController?.pushViewController(pictureController, animated: true)
        //        }
        
    }
    
    @objc func zoomOut() {
        
        guard let location = CurrentUser.currentLocation else {
            return
        }
        
        let curLat = mapView.region.span.latitudeDelta
        let curLong = mapView.region.span.longitudeDelta
        let center = mapView.region.center
        
        let coordinateRegion = MKCoordinateRegion.init(center: center,latitudinalMeters: curLat * 3, longitudinalMeters: curLong * 3)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    
    func showFullMap() {
        // Reset to Full Map. Minimize Post Collection View
        
        
    }
    
    
//    @objc func showGlobe(){
//        guard let location = CurrentUser.currentLocation else {
//            return
//        }
//
//        print("centerMapOnLocation | \(location.coordinate)")
//        let coordinateRegion = MKCoordinateRegion.init(center: location.coordinate,
//                                                       latitudinalMeters: regionRadius*1000, longitudinalMeters: regionRadius*1000)
//        //        mapView?.region = coordinateRegion
//        mapView.setRegion(coordinateRegion, animated: true)
//
//        self.showFullMap()
//    }
    
    func centerMapOnLocation(location: CLLocation?, radius: CLLocationDistance? = 0, closestLocation: CLLocation? = nil) {
        guard let location = location else {
            print("centerMapOnLocation | NO LOCATION")
            return}
        print("  ~ centerMapOnLocation | Input | \(location.coordinate.latitude) , \(location.coordinate.longitude) | Radius \(radius) | Closest \(closestLocation?.coordinate)")
        
        var displayRadius: CLLocationDistance = radius == 0 ? regionRadius : radius!
        var coordinateRegion: MKCoordinateRegion?
        
        if let closestLocation = closestLocation {
            let closestDisplayRadius = location.distance(from: closestLocation)*2
            print("  ~ centerMapOnLocation | Distance Cur Location and Closest Post | \(displayRadius/2)")
            if closestDisplayRadius > 500000 {
                coordinateRegion = MKCoordinateRegion.init(center: (closestLocation.coordinate),latitudinalMeters: displayRadius, longitudinalMeters: displayRadius)
                //                mapView.setRegion(coordinateRegion!, animated: true)
                print("  ~ centerMapOnLocation | First Post Too Far, Default to first post location")
            } else {
                displayRadius = max(displayRadius, closestDisplayRadius)
                coordinateRegion = MKCoordinateRegion.init(center: (location.coordinate),latitudinalMeters: displayRadius, longitudinalMeters: displayRadius)
            }
        } else {
            coordinateRegion = MKCoordinateRegion.init(center: location.coordinate,latitudinalMeters: displayRadius, longitudinalMeters: displayRadius)
//            print("centerMapOnLocation | ", coordinateRegion!)
        }
        
        guard let finalCoordinateRegion = coordinateRegion else {
            print("  ~ ERROR | NO MAP COORDINATE | centerMapOnLocation")
            return}
        //        mapView?.region = coordinateRegion
        mapView.setRegion(finalCoordinateRegion, animated: true)
        print("  ~ centerMapOnLocation | Result | \(finalCoordinateRegion.center.latitude) , \(finalCoordinateRegion.center.longitude) | Radius \(displayRadius)")
        
    }
    

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        var annotationView = MKMarkerAnnotationView()
//        guard let annotation = annotation as? MKMarkerAnnotationView else {return nil}
//
//        return annotation
        
        if annotation.title == "My Location" {
            guard let annotation = annotation as? MKMarkerAnnotationView else {return nil}
            return annotation
        } else {
            var annotationView = MapPinMarkerView()
            annotationView.annotation = annotation
            return annotationView
        }
        
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if let markerView = view as? MapPinMarkerView {
            markerView.markerTintColor = markerView.defaultPinColor
            
            markerView.markerTintColor = UIColor.ianLegitColor()
            markerView.detailCalloutAccessoryView?.removeGestureRecognizer(mainCallOutViewTap)
            markerView.rightCalloutAccessoryView?.removeGestureRecognizer(rightCallOutViewTap)
            markerView.leftCalloutAccessoryView?.removeGestureRecognizer(leftCallOutViewTap)
            markerView.plainView.removeGestureRecognizer(plainViewTap)
            print("DESELCT Markerview", markerView.glyphText, "| MarkerView | \(markerView.isSelected)")
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
//        print("  ~ MAPVIEW SELECTED | \(view.annotation)")
        
        if let annotation = view.annotation as? MapPin {
            annotation.title = annotation.locationName
            
            let tempPost = fetchedPosts.first { (post) -> Bool in
                post.id == annotation.postId
            }
            
            if tempPost != nil {
                self.selectedMapPost = tempPost
                self.showSelectedPost()
            }
            print("Map Pin Selected | \(annotation.postId) | \(annotation.locationName) | \(annotation.alwaysShow) Show | Has Post \(tempPost?.id) : \(tempPost?.locationName)")
            
        } else {
            print("ERROR Casting Annotation to MapPin | \(view.annotation)")
        }
        
        // ADDITIONAL TINT COLOR FOR SELECTED MAP PIN
        if let markerView = view as? MapPinMarkerView {
                
            markerView.markerTintColor = UIColor.ianLegitColor()
            markerView.detailCalloutAccessoryView?.addGestureRecognizer(mainCallOutViewTap)
            markerView.rightCalloutAccessoryView?.addGestureRecognizer(rightCallOutViewTap)
            markerView.leftCalloutAccessoryView?.addGestureRecognizer(leftCallOutViewTap)
//            markerView.plainView.backgroundColor = UIColor.yellow
            markerView.plainView.addGestureRecognizer(plainViewTap)
            markerView.markerTintColor = UIColor.ianLegitColor()
            print(markerView.glyphText, "| MarkerView | \(markerView.isSelected)")
            //            markerView.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(passToSelectedPost)))
            //
            //            markerView.inputAccessoryView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(passToSelectedPost)))
            //            markerView.inputView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(passToSelectedPost)))
            //            markerView.plainView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(passToSelectedPost)))
        } else {
            print("mapView | didSelect | Can't find marker view | \(self.selectedMapPost?.id)")
        }
        
        
        
    }
    
    
    @objc func passToSelectedPost(){
        print("passToSelectedPost")
        guard let post = self.selectedMapPost else {return}
        self.extTapPicture(post: post)
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
//        self.hideMinimizeCollectionView()
        //        print(mapView.getCurrentZoom())
        
    }

    
    




}


extension NewTabMapViewController : UICollectionViewDelegate, UICollectionViewDataSource, LegitMapPostCollectionViewCellDelegate, UICollectionViewDelegateFlowLayout {

    
    func setupPostCollectionView(){
        postCollectionView.backgroundColor = UIColor.white
        postCollectionView.layer.borderColor = UIColor.lightGray.cgColor
        
        postCollectionView.register(LegitMapPostCollectionViewCell.self, forCellWithReuseIdentifier: cellId)
        postCollectionView.register(GridPhotoCell.self, forCellWithReuseIdentifier: gridCellId)
//        postCollectionView.register(MainListViewViewHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: listHeaderId)


//        let layout = UICollectionViewFlowLayout()
//        layout.scrollDirection = .horizontal
//
////        layout.estimatedItemSize = CGSize(width: 350, height: 250)
//        layout.estimatedItemSize = CGSize(width: self.postCollectionView.frame.width, height: CGFloat(postFullHeight))
//
        postCollectionViewFlowLayout.scrollDirection = .horizontal
        postCollectionViewFlowLayout.estimatedItemSize = CGSize(width: self.postCollectionView.frame.width, height: CGFloat(postFullHeight))
        postCollectionViewFlowLayout.minimumInteritemSpacing = 1
        postCollectionViewFlowLayout.minimumLineSpacing = 0
        postCollectionView.collectionViewLayout = postCollectionViewFlowLayout
        postCollectionView.allowsSelection = true
        postCollectionView.allowsMultipleSelection = false
        postCollectionView.isPagingEnabled = true
        postCollectionView.showsHorizontalScrollIndicator = false
        postCollectionView.isScrollEnabled = true
        postCollectionView.semanticContentAttribute = .forceLeftToRight
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        //        postCollectionView.refreshControl = refreshControl
        //        postCollectionView.alwaysBounceVertical = true
        postCollectionView.keyboardDismissMode = .onDrag
        
        //        postCollectionView.register(MainViewHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: listHeaderId)
        
        //        layout.minimumLineSpacing = 1
        //        layout.sectionInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        //        postCollectionView.collectionViewLayout = layout
        //        postCollectionView.collectionViewLayout = ListViewControllerHeaderFlowLayout()
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        print("NewMapViewController | CollectionView \(fetchedPosts.count) Posts")
        return fetchedPosts.count

    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var displayPost = fetchedPosts[indexPath.item]

        if self.mapFilter.filterLocation != nil && displayPost.locationGPS != nil {
            displayPost.distance = Double((displayPost.locationGPS?.distance(from: (self.mapFilter.filterLocation!)))!)
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! LegitMapPostCollectionViewCell
        cell.post = displayPost
        cell.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        cell.showMinimzeButton = self.isPostFullView
        cell.delegate = self
        cell.currentImage = 1
        cell.cellWidth = self.postCollectionView.frame.width
        return cell

    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        var displayPost = fetchedPosts[indexPath.item]
//        self.didTapPost(post: displayPost)
        self.isPostFullView = !self.isPostFullView
        print("TAP POST")

    }
    
    func didTapPost(post: Post?) {
        guard let post = post else {return}
        
        let pictureController = NewSinglePostView()
        pictureController.post = post
        let picView = UINavigationController(rootViewController: pictureController)
        navigationController?.pushViewController(pictureController, animated: true)
    }
    
    func filterCaptionPost(searchText: String) {
        print("filterCaptionPost | ", searchText)
        let tempAddTag = searchText.lowercased()
        
        guard let filterCaption = self.mapFilter.filterCaption?.lowercased() else {
            self.mapFilter.filterCaption = tempAddTag
            self.refreshPostsForFilter()
            return
        }
        
        if filterCaption.contains(tempAddTag) {
            self.mapFilter.filterCaption = filterCaption.replacingOccurrences(of: tempAddTag, with: "")
        } else {
            if self.mapFilter.filterCaption == nil {
                self.mapFilter.filterCaption = tempAddTag
            } else {
                self.mapFilter.filterCaption = filterCaption + tempAddTag
            }
        }
        
        self.refreshPostsForFilter()
    }
 
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == postCollectionView
        {
            let currentIndex = Int(self.postCollectionView.contentOffset.x / self.postCollectionView.frame.size.width)
            self.selectedMapPost = self.fetchedPosts[currentIndex]
            print("  ~ Show Post on Map |  \(self.selectedMapPost?.locationName) | scrollViewDidEndDecelerating")
            self.showSelectedPostOnMap()
        }
    }
    
    
    
}

// MARK: - SEARCH BAR


extension NewTabMapViewController : UISearchBarDelegate {
    
    func setupSearchBar() {
//        fullSearchBar.searchBarStyle = .prominent
        fullSearchBar.searchBarStyle = .minimal

        fullSearchBar.isTranslucent = false
        fullSearchBar.tintColor = UIColor.ianBlackColor()
        fullSearchBar.placeholder = "Search food, locations, categories"
        fullSearchBar.delegate = self
        fullSearchBar.showsCancelButton = false
        fullSearchBar.sizeToFit()
        fullSearchBar.clipsToBounds = true
        fullSearchBar.backgroundImage = UIImage()
        fullSearchBar.backgroundColor = UIColor.white
        
        // CANCEL BUTTON
        let attributes = [
            NSAttributedString.Key.foregroundColor : UIColor.ianLegitColor(),
            NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 13)
        ]
//        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(attributes, for: .normal)
        
        
        let searchImage = #imageLiteral(resourceName: "search_selected").withRenderingMode(.alwaysTemplate)
        fullSearchBar.setImage(UIImage(), for: .search, state: .normal)
        
        //        let cancelImage = #imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysTemplate)
        //        fullSearchBar.setImage(cancelImage, for: .clear, state: .normal)
        
        fullSearchBar.layer.borderWidth = 0
        fullSearchBar.layer.borderColor = UIColor.ianBlackColor().cgColor
        
        let textFieldInsideSearchBar = fullSearchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = UIColor.ianBlackColor()
        textFieldInsideSearchBar?.font = UIFont.systemFont(ofSize: 14)
        textFieldInsideSearchBar?.layer.backgroundColor = UIColor.white.cgColor
        // REMOVE SEARCH BAR ICON
        //        let searchTextField:UITextField = fullSearchBar.subviews[0].subviews.last as! UITextField
        //        searchTextField.leftView = nil
        
        
        for s in fullSearchBar.subviews[0].subviews {
            if s is UITextField {
                s.backgroundColor = UIColor.clear
                s.layer.backgroundColor = UIColor.clear.cgColor
                s.backgroundColor = UIColor.white
                s.layer.backgroundColor = UIColor.white.cgColor

                if let backgroundview = s.subviews.first {
                    
                    // Background color
                    //                    backgroundview.backgroundColor = UIColor.white
                    backgroundview.clipsToBounds = true
                    backgroundview.layer.backgroundColor = UIColor.clear.cgColor
                    backgroundview.layer.backgroundColor = UIColor.white.cgColor

                    // Rounded corner
                    //                    backgroundview.layer.cornerRadius = 30/2
                    //                    backgroundview.layer.masksToBounds = true
                    //                    backgroundview.clipsToBounds = true
                }

            }
        }
        
    }
    
    func showFullSearchBar(){
        
        UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.transitionCrossDissolve, animations:
            {
                self.fullSearchBarView.alpha = 1
        }
            , completion: { (finished: Bool) in
        })
        
//        self.fullSearchBar.becomeFirstResponder()
        self.fullSearchBar.becomeFirstResponder()
        self.showSearchTableView()
    }
    
    func hideFullSearchBar() {
        
        UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.transitionCrossDissolve, animations:
            {
                if self.mapFilter.isFiltering {
                    self.fullSearchBarView.alpha = 1
                } else {
                    self.fullSearchBarView.alpha = 0
                }
        }
            , completion: { (finished: Bool) in
        })
        self.fullSearchBar.resignFirstResponder()
        self.hideSearchTableView()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.hideFullSearchBar()
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        self.delegate?.filterContentForSearchText(searchText)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.showFullSearchBar()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text?.lowercased() else {
            self.refreshAll()
            print("Search Bar Empty | Refresh")
            return
        }
        
        self.filterCaptionPost(searchText: text)
    }
    
    
    func showSearchTableView() {
        
    }
    
    func hideSearchTableView() {
        
    }
    
    func refreshSearchBar() {
        /*
        if mapFilter.isFiltering
        {
            if let captionSearch = mapFilter.filterCaption {
                var displaySearch = captionSearch
                if displaySearch.isSingleEmoji {
                    // ADD EMOJI TRANSLATION
                    if let emojiTranslate = EmojiDictionary[displaySearch] {
                        displaySearch += " \(emojiTranslate.capitalizingFirstLetter())"
                    }
                }
                
                fullSearchBar.text = displaySearch
            } else if mapFilter.filterLocationName != nil {
                fullSearchBar.text = mapFilter.filterLocationName
            } else if let googleID = mapFilter.filterGoogleLocationID {
                if let locationName = locationGoogleIdDictionary.key(forValue: googleID) {
                    fullSearchBar.text = locationName
                } else {
                    fullSearchBar.text = googleID
                }
                
            } else if mapFilter.filterLocationSummaryID != nil {
                fullSearchBar.text = mapFilter.filterLocationSummaryID
            } else {
                fullSearchBar.text = ""
            }
            self.showFullSearchBar()
        }
        else
        {
            self.hideFullSearchBar()
        }*/
    }
    
    

    
    
}

extension NewTabMapViewController: UserListSearchViewDelegate {
    
        
    func didTapSearchButton() {
        print("Tap Search | \(self.currentPostsFilterTagCounts.count) Tags | \(self.mapFilter.searchTerms)")
        search.delegate = self
        search.inputViewFilter = self.mapFilter
//        search.noCaptionFilterTagCounts = self.noCaptionFilterTagCounts
//        search.currentPostsFilterTagCounts = self.currentPostsFilterTagCounts
        search.noFilterTagCounts = self.noFilterTagCounts
        search.currentPostTagCounts = self.currentPostTagCounts
        search.currentRatingCounts = self.currentPostRatingCounts
        search.searchBar.text = ""

        let testNav = UINavigationController(rootViewController: search)
        
//        let transition = CATransition()
//        transition.duration = 0.5
//        transition.type = CATransitionType.push
//        transition.subtype = CATransitionSubtype.fromBottom
//        transition.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
//        view.window!.layer.add(transition, forKey: kCATransition)
        self.present(testNav, animated: true) {
            print("   Presenting List Option View")
        }
    }
    
    @objc func openUserListFilter() {
        userListSearchView.selectedUser = self.filteredUser
        userListSearchView.selectedList = self.filteredList
        userListSearchView.delegate = self
        let tempNav = UINavigationController(rootViewController: userListSearchView)
        self.present(tempNav, animated: true) {
            print("  Presenting User Filter | openUserFilter")
        }
        
        
    }
    
    func openUserFilter() {
        let temp = UserListSearchView()
        temp.inputUser = CurrentUser.user
        temp.selectedUser = self.filteredUser
        temp.selectedList = nil
        temp.searchUser = true
        temp.delegate = self
        let tempNav = UINavigationController(rootViewController: temp)
        self.present(tempNav, animated: true) {
            print("  Presenting User Filter | openUserFilter")
        }
    }
    
    @objc func openListFilter() {
        let temp = UserListSearchView()
        temp.inputUser = CurrentUser.user
        temp.selectedUser = nil
        temp.selectedList = self.filteredList
        temp.searchList = true
        temp.delegate = self
        let tempNav = UINavigationController(rootViewController: temp)
        self.present(tempNav, animated: true) {
            print("  Presenting List Filter | openListFilter")
        }
    }
    
    func setupFilterSuggestedButtons() {
        let date = Date()
        Database.guessPostMeal(googleLocationType: nil, currentTime: date) { (emoji) in
            self.suggestedEmoji = emoji?.emoji ?? ""
            self.suggestedEmojiName = emoji?.name ?? ""
                        
            self.suggestedEmoji2 = "☕️"
            self.suggestedEmojiName2 = "Coffee"
            
            self.updateFilterSuggestedButtons()
            print("NewTabMapView | Set Suggested Emojis | \(self.suggestedEmoji2) | \(self.suggestedEmojiName2)")
        }


        
    }
    
    func updateFilterSuggestedButtons() {
        self.filterSuggestionButton.setTitle(self.suggestedEmoji, for: .normal)
        let isFilteringEmoji1 = self.mapFilter.searchTerms.contains(self.suggestedEmoji)
        self.filterSuggestionButton.alpha = (isFilteringEmoji1) ? 1 : 0.6
        self.filterSuggestionButton.backgroundColor = (isFilteringEmoji1) ? UIColor.ianLegitColor() : UIColor.white
        self.filterSuggestionLabel.text = (isFilteringEmoji1) ? self.suggestedEmojiName.capitalizingFirstLetter() : ""
        
        
        self.filterSuggestionButton2.setTitle(self.suggestedEmoji2, for: .normal)
        let isFilteringEmoji2 = self.mapFilter.searchTerms.contains(self.suggestedEmoji2)
        self.filterSuggestionButton2.alpha = (isFilteringEmoji2) ? 1 : 0.6
        self.filterSuggestionButton2.backgroundColor = (isFilteringEmoji2) ? UIColor.ianLegitColor() : UIColor.white
        self.filterSuggestionLabel2.text = (isFilteringEmoji2) ? self.suggestedEmojiName2.capitalizingFirstLetter() : ""
    }
    
    
    @objc func filterSuggestedEmoji1() {
        if self.mapFilter.searchTerms.contains(self.suggestedEmoji) {
            self.mapFilter.filterCaptionArray.removeAll { (string) -> Bool in
                return string == self.suggestedEmoji
            }
        } else {
            self.mapFilter.filterCaptionArray.append(self.suggestedEmoji)
        }
        refreshPostsForFilter()
        updateFilterSuggestedButtons()
    }

    @objc func filterSuggestedEmoji2() {
        if self.mapFilter.searchTerms.contains(self.suggestedEmoji2) {
            self.mapFilter.filterCaptionArray.removeAll { (string) -> Bool in
                return string == self.suggestedEmoji2
            }
        } else {
            self.mapFilter.filterCaptionArray.append(self.suggestedEmoji2)
        }
        refreshPostsForFilter()
        updateFilterSuggestedButtons()
    }
    
    
    
    
    func userSelected(user: User?) {
        print("NewTabMapView | userSelected | \(user?.username)")
        guard let user = user else {return}
        self.mapFilter.clearFilter()
        self.mapFilter.filterUser = user
        self.newFilterSelected = true
        self.refreshPostsForFilter()
        
        self.resetButtons()
        self.filteredUser = user
    }
    
    func listSelected(list: List?) {
        print("NewTabMapView | listSelected | \(list?.name)")
        guard let list = list else {return}
        self.mapFilter.clearFilter()
        self.mapFilter.filterList = list
        self.newFilterSelected = true
        self.refreshPostsForFilter()
        
        self.resetButtons()
        self.filteredList = list
    }

    
    func showSearchList(){
        let temp = UserListSearchView()
        
    }
    
    
    
}
 

// MARK: - COLLECTIONVIEW CELL DELEGATES


extension NewTabMapViewController : NewListPhotoCellDelegate, MessageControllerDelegate, SharePhotoListControllerDelegate, ListViewControllerDelegate, LegitSearchViewControllerDelegate, RefreshFilterBarCellDelegate, SelectedFilterBarCellDelegate, BottomEmojiBarDelegate, UserSearchBarDelegate {
    
    func didTapEmojiBackButton() {
        
    }
    
    func didTapEmojiButton() {
        
    }
    
    
    func didTapGridButton() {
        
    }
    
    
    func filterContentForSearchText(searchText: String) {
        
    }
    
    func didActivateSearchBar() {
        self.didTapSearchButton()
    }
    
    func didTapCell(tag: String) {
        print("didTapCell ", tag)
    }

    
    func refreshBottomEmojiBar() {
        bottomEmojiBar.viewFilter = self.mapFilter
        bottomEmojiBar.filteredPostCount = self.fetchedPosts.count
        let sorted = self.first50EmojiCounts.sorted(by: {$0.value > $1.value})
        var topEmojis: [String] = []
        for (index,value) in sorted {
            if index.isSingleEmoji /*&& topEmojis.count < 4*/ {
                topEmojis.append(index)
            }
        }
        bottomEmojiBar.displayedEmojis = topEmojis
        let showBottomEmojiBar = (self.mapFilter.searchTerms.count > 0)
        bottomEmojiBarHide?.constant = showBottomEmojiBar ? bottomEmojiBarHeight : 0
    }
    
    
    func didTapAddTag(addTag: String) {
        // ONLY EMOJIS BECAUSE CAN ONLY ADD EMOJI TAGS FROM HEADER
        let tempAddTag = addTag.lowercased()
        var tempArray = self.mapFilter.filterCaptionArray
        if self.mapFilter.filterSort != defaultNearestSort {
            self.mapFilter.filterSort = defaultNearestSort
        }
        
        if tempArray.count == 0 {
            tempArray.append(tempAddTag)
            print("\(tempAddTag) | Add To Search | \(tempArray)")
        } else if tempArray.contains(tempAddTag) {
            let oldCount = tempArray.count
            tempArray.removeAll { (text) -> Bool in
                text == tempAddTag
            }
            let dif = tempArray.count - oldCount
            print("\(tempAddTag) Exists | Remove \(dif) from Search | \(tempArray)")
        } else {
            tempArray.append(tempAddTag)
            print("\(tempAddTag) | Add To Search | \(tempArray)")
        }
        
        self.mapFilter.filterCaptionArray = tempArray
        self.refreshPostsForFilter()
        
        }
    
    func didRemoveTag(tag: String) {
        if tag == self.mapFilter.filterLocationSummaryID {
            self.mapFilter.filterLocationSummaryID = nil
            print("Remove Search | \(tag) | City | \(self.mapFilter.filterLocationSummaryID)")
        } else if tag == self.mapFilter.filterLocationName {
            self.mapFilter.filterLocationName = nil
            self.mapFilter.filterGoogleLocationID = nil
            print("Remove Search | \(tag) | Location | \(self.mapFilter.filterLocationName)")

        } else if self.mapFilter.filterCaptionArray.count > 0 {
            
            var tempArray = self.mapFilter.filterCaptionArray.map {$0.lowercased()}
            let tagText = tag.lowercased()
            if tempArray.contains(tagText) {
                let oldCount = tempArray.count
                tempArray.removeAll { (text) -> Bool in
                    text == tagText
                }
                print("didRemoveTag | Remove \(tagText) from Search | \(tempArray)")
            }
            self.mapFilter.filterCaptionArray = tempArray
        }

        self.refreshPostsForFilter()
    }
    
    func didRemoveLocationFilter(location: String) {
        if self.mapFilter.filterLocationName?.lowercased() == location.lowercased() {
            self.mapFilter.filterLocationName = nil
        } else if self.mapFilter.filterLocationSummaryID?.lowercased() == location.lowercased() {
            self.mapFilter.filterLocationSummaryID = nil
        }
        self.refreshPostsForFilter()
    }
    
    func didRemoveRatingFilter(rating: String) {
        if extraRatingEmojis.contains(rating) {
            self.mapFilter.filterRatingEmoji = nil
        } else if rating.contains("⭐️") {
            self.mapFilter.filterMinRating = 0
        }
        self.refreshPostsForFilter()
    }
    
    
    func filterControllerSelected(filter: Filter?) {
        print("LegitMapView | Received Filter | \(filter)")
        guard let filter = filter else {return}
        self.mapFilter = filter
        self.refreshPostsForFilter()
    }
    
//    func listSelected(list: List?) {
//        print("Selected | \(list?.name)")
//        self.mapFilter.filterList = list
//        self.mapFilter.filterCaption = nil
//        self.showFullMap()
//        self.refreshPostsForFilter()
//    }
    
    func deleteList(list: List?) {
        print("MainViewController | DELETE")

    }
    
    func didTapComment(post: Post) {
        let commentsController = CommentsController(collectionViewLayout: UICollectionViewFlowLayout())
        commentsController.post = post
        navigationController?.pushViewController(commentsController, animated: true)
    }
    
    func didTapUser(post: Post) {
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = post.user.uid
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapLocation(post: Post) {
        let locationController = LocationController()
        locationController.selectedPost = post
        navigationController?.pushViewController(locationController, animated: true)
    }
    
    func didTapMessage(post: Post) {
        let messageController = MessageController()
        messageController.post = post
        messageController.delegate = self
        navigationController?.pushViewController(messageController, animated: true)
    }
    
    func refreshPost(post: Post) {
        let index = fetchedPosts.firstIndex { (filteredpost) -> Bool in
            filteredpost.id  == post.id
        }
        print("Refreshing Post @ \(index) for post \(post.id)")
        let filteredindexpath = IndexPath(row:index!, section: 0)
        
        self.fetchedPosts[index!] = post
        self.postCollectionView.reloadItems(at: [filteredindexpath])
        
        // Update Cache
        postCache.removeValue(forKey: post.id!)
        postCache[post.id!] = post
    }
    
    func didTapBookmark(post: Post) {
        let sharePhotoListController = SharePhotoListController()
        sharePhotoListController.uploadPost = post
        sharePhotoListController.isBookmarkingPost = true
        sharePhotoListController.delegate = self
        navigationController?.pushViewController(sharePhotoListController, animated: true)
    }
    
    func deletePostFromList(post: Post) {
        
    }
    
    func didTapPicture(post: Post) {
        self.didTapPost(post: post)
//        let pictureController = SinglePostView()
//        pictureController.post = post
//        navigationController?.pushViewController(pictureController, animated: true)
    }
    
    
    func didTapExtraTag(tagName: String, tagId: String, post: Post) {
        // Tap tagged list
        // Check Current User List
        if let listIndex = CurrentUser.lists.firstIndex(where: { (currentList) -> Bool in
            currentList.id == tagId
        }) {
            let listViewController = ListViewController()
            listViewController.delegate = self
            listViewController.imageCollectionView.collectionViewLayout = HomeSortFilterHeaderFlowLayout()
            listViewController.currentDisplayList = CurrentUser.lists[listIndex]
            self.navigationController?.pushViewController(listViewController, animated: true)
        }
            
        else {
            // List Tag Selected
            Database.checkUpdateListDetailsWithPost(listName: tagName, listId: tagId, post: post, completion: { (fetchedList) in
                if fetchedList == nil {
                    // List Does not Exist
                    self.alert(title: "List Error", message: "List Does Not Exist Anymore")
                } else {
                    let listViewController = ListViewController()
                    listViewController.imageCollectionView.collectionViewLayout = HomeSortFilterHeaderFlowLayout()
                    listViewController.currentDisplayList = fetchedList
                    listViewController.delegate = self
                    self.navigationController?.pushViewController(listViewController, animated: true)
                }
            })
        }
    }
    
    func didTapListCancel(post: Post) {
        
    }
    
    
    func showEmojiDetail(emoji: String?) {
        guard let emoji = emoji else {
            print("showEmojiDetail | No Emoji")
            return
        }
        
        var emojiDetail = ""

        if let _ = EmojiDictionary[emoji] {
            emojiDetail = EmojiDictionary[emoji]!
        } else {
            print("No Dictionary Value | \(emojiDetail) | \(emoji)")
            emojiDetail = ""
        }
        
        
        var captionDelay = 3
        emojiDetailLabel.text = "\(emoji)  \(emojiDetail)"
        emojiDetailLabel.alpha = 1
        emojiDetailLabel.adjustsFontSizeToFitWidth = true
        //        emojiDetailLabel.sizeToFit()
        
        UIView.animate(withDuration: 0.5, delay: TimeInterval(captionDelay), options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.hideEmojiDetailLabel()
        }, completion: { (finished: Bool) in
        })
    
    }
    
    func hideEmojiDetailLabel(){
        self.emojiDetailLabel.alpha = 0
    }

    @objc func togglePost() {
        self.isPostFullView = !self.isPostFullView
        print("TOGGLE POST")
    }

}
