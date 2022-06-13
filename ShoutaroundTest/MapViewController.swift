//
//  MainViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/25/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
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

class MainViewController: UIViewController, MKMapViewDelegate, EmptyDataSetSource, EmptyDataSetDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, FullPostCellDelegate, SharePhotoListControllerDelegate, MessageControllerDelegate, PostSearchControllerDelegate, MainListViewViewHeaderDelegate, FilterControllerDelegate, ListPhotoCellDelegate, MainListViewControllerDelegate, MainSearchControllerDelegate, SearchFilterControllerDelegate, UserListViewControllerDelegate, UISearchBarDelegate, UIPickerViewDelegate, UIPickerViewDataSource, GridPhotoCellDelegate, TLPhotosPickerViewControllerDelegate, SKPhotoBrowserDelegate, CropViewControllerDelegate, UITextViewDelegate, UIGestureRecognizerDelegate, ListViewControllerDelegate, NewListPhotoCellDelegate, LoginControllerDelegate {
    func deleteList(list: List?) {
        print("MainViewController | DELETE")
    }
    
    
    
    func expandPost(post: Post, newHeight: CGFloat) {
//        collectionHeights[post.id!] = newHeight
//        print("Added New Height | ",collectionHeights)
    }

    
    // POST VARIABLES
    var selectedMapPost: Post? = nil {
        didSet {
            print("  ~ selectedMapPost | \(selectedMapPost?.id)")
        }
    }
    var fetchedPostIds: [PostId] = []
    var fetchedPosts: [Post] = [] {
        didSet{
            self.postCountLabel.text = "\(self.fetchedPosts.count) Posts"
            self.postCountLabel.sizeToFit()
        }
    }
    
    
    // MAP VARIABLES
    
    let mapView = MKMapView()
    var postDisplayed: Bool = false {
        didSet {
            self.postCollectionView.isHidden = !postDisplayed
        }
    }
    
    let mapPinReuseInd = "MapPin"
    let regionRadius: CLLocationDistance = 5000

    var mapPins: [MapPin] = []
    
    
    // THIS IS TO BYPASS SCROLLVIEW CALL FUNCTION WHEN SCROLLTOITEM IS CALLED
    var enableScroll: Bool = true
    
    func showSelectedPost(){
        print("  ~ showSelectedPost | \(self.selectedMapPost?.id)")
        
        self.enableScroll = false
        
        // Show Map first so that it can scroll to top. Scrolling first then displaying map messes it up
        self.showPost()
        //        self.centerMapOnLocation(location: self.selectedMapPost?.locationGPS)
        
//        print("ENABLE: \(self.enableScroll)")
        if let index = self.fetchedPosts.firstIndex(where: { (post) -> Bool in
            return post.id == selectedMapPost?.id
        }) {
            if index <= paginatePostsCount - 1{
                print("   ~ CollectionView Found | \(index) | \(self.selectedMapPost?.id)")
                let indexpath = IndexPath(row:index, section: 0)
                self.postCollectionView.reloadItems(at: [indexpath])
                self.postCollectionView.scrollToItem(at: indexpath, at: .bottom, animated: true)
            } else {
                print("CollectionView Missing | \(self.selectedMapPost?.id) | Create Cell")
                // Move Selected Post to first item to go around pagination
                let index = self.fetchedPosts.firstIndex(where: { (post) -> Bool in
                    return post.id == selectedMapPost?.id
                })
                let tempPost = fetchedPosts[index!]
                fetchedPosts.remove(at: index!)
                fetchedPosts.insert(tempPost, at: 0)
                self.postCollectionView.reloadData()

                // Scroll to Tapped Post
                if self.postCollectionView.numberOfItems(inSection: 0) > 0 {
                    let indexpath = IndexPath(row:0, section: 0)
                    self.postCollectionView.scrollToItem(at: indexpath, at: .bottom, animated: true)
                }

                print("OK")
            }
        } else {
            print("ERROR |Post Not Found | \(self.selectedMapPost?.id)")
            self.postCollectionView.reloadData()
//            let indexpath = IndexPath(row:0, section: 0)
//           self.postCollectionView.scrollToItem(at: indexpath, at: .bottom, animated: true)
        }
        
    }
    
    func showPost(){
        
        self.collapseButton.isHidden = false
        self.expandButton.isHidden = false
        self.postCollectionView.layer.borderWidth = 1
        
        self.postCollectionView.backgroundColor = UIColor.white
        //        self.postCollectionView.collectionViewLayout.invalidateLayout()
        //
        //        if let layout = postCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
        //            layout.scrollDirection = .horizontal
        //        }
        //        self.postCollectionView.isScrollEnabled = true
        
        self.postCollectionView.updateConstraintsIfNeeded()
        self.postCollectionView.layoutIfNeeded()
        
        self.postDisplayed = true

        UIView.animate(withDuration: 0.3) {
            self.postDisplayed = true
            self.postViewHeightConstraint?.isActive = true
            self.fullListViewConstraint?.isActive = false
//            self.hidePostHeightConstraint?.isActive = false
            self.setupButtons()
            self.postCollectionView.reloadData()
            
            self.view.layoutIfNeeded()
            
        }
        
        
//        print("MAP | Show Map Post | \(postViewHeightConstraint?.constant) | \(self.postCollectionView.frame.height)")
    }
    
    
    @objc func showFullMap(){
        
        self.collapseButton.isHidden = true
//        self.expandButton.isHidden = true
        self.expandButton.isHidden = false

        self.postCollectionView.updateConstraintsIfNeeded()
        
        UIView.animate(withDuration: 0.3) {
            self.postDisplayed = false
            self.postViewHeightConstraint?.isActive = false
            self.fullListViewConstraint?.isActive = false
//            self.hidePostHeightConstraint?.isActive = true
            self.setupButtons()
            
            self.view.layoutIfNeeded()
        }
        var mapDisplayed: Bool = true
        
        
        print("Map | EXPAND FULL | \(postViewHeightConstraint?.constant) | \(self.postCollectionView.frame.height)")
    }
    
    @objc func showFullList(){
        
        self.enableScroll = false
        
        self.collapseButton.isHidden = true
        self.expandButton.isHidden = true
        
//        self.showNavBar()
        
//        self.postCollectionView.layer.borderWidth = 0
//        self.postCollectionView.backgroundColor = UIColor.white
//        self.postCollectionView.updateConstraintsIfNeeded()
//        self.postCollectionView.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.3) {
            self.postDisplayed = true
            self.postViewHeightConstraint?.isActive = false
            self.fullListViewConstraint?.isActive = true
//            self.hidePostHeightConstraint?.isActive = false
            self.setupButtons()
            
            self.postCollectionView.layer.borderWidth = 0
            self.postCollectionView.backgroundColor = UIColor.white
            self.postCollectionView.updateConstraintsIfNeeded()
            self.postCollectionView.layoutIfNeeded()
            
            self.postCollectionView.reloadData()
            
            self.view.layoutIfNeeded()
            self.enableScroll = true
            
        }
        print("MAP | HIDE | \(postViewHeightConstraint?.constant) | \(self.postCollectionView.frame.height)")
    }
    
    
    
    
    
    
    @objc func filterLegitPosts(){
        self.mapFilter?.filterLegit = !(self.mapFilter?.filterLegit)!
        self.setupButtons()
        self.refreshPostsForFilter()
        
        self.filterLegitButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.filterLegitButton.transform = .identity
                        
                        //                        self?.filterLegitButton.alpha = (self?.mapFilter?.filterLegit)! ? 1 : 0.5
                        //                        self?.filterLegitButton.backgroundColor = (self?.mapFilter?.filterLegit)! ? UIColor.legitColor() : UIColor(hexColor: "FE5F55")
                        
            },
                       completion: nil)
        
        
    }
    
    
    var pointNow: CGPoint?
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        pointNow = scrollView.contentOffset;
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        guard let pointNow = pointNow else {return}
        
//        let contentYoffset = scrollView.contentOffset.y
//        let contentXoffset = scrollView.contentOffset.x
//        let cellSize = CGSize(width: self.view.frame.width, height: postHeight)
//
//
//        if let layout = postCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
//            if layout.scrollDirection == .horizontal {
//                if (scrollView.contentOffset.x<pointNow.x){
//                    // Swipe Right
//                    postCollectionView.scrollRectToVisible(CGRect(x: contentXoffset + cellSize.width, y: contentYoffset, width: 0, height: 0), animated: true)
//                    postCollectionView.selectItem(at: postCollectionView.indexPathsForVisibleItems.first, animated: true, scrollPosition: .top)
//                } else if (scrollView.contentOffset.x>pointNow.x){
//                    // Swipe Left
//                    postCollectionView.scrollRectToVisible(CGRect(x: contentXoffset - cellSize.width, y: contentYoffset, width: 0, height: 0), animated: true)
//                    postCollectionView.selectItem(at: postCollectionView.indexPathsForVisibleItems.first, animated: true, scrollPosition: .top)
//                }
//            }
//        }
//
//        // Turn off emoji detail
//        for cell in (postCollectionView.visibleCells) {
//            if let tempCell = cell as? ListPhotoCell {
//                tempCell.hideEmojiDetailLabel()
//            }
//        }
//
//        // Turn on expanding list when scrolling
//
//        if (scrollView.contentOffset.y<pointNow.y) {
//            //            print("Scroll Up")
//            if contentYoffset < -60 {
//                if self.enableScroll{
//                    print("Scrolled to Top | Show Map")
//                    self.showSelectedPost()
//                }
//            }
//            //Scroll Down
//        } else if (scrollView.contentOffset.y>pointNow.y) {
//            // Scroll Up at CollectionView. Hide Map and Display all Posts
//            if self.enableScroll{
//                if self.fullListViewConstraint?.isActive == false {
//                    print("Scroll Down | Hide Map")
//                    self.showFullList()
//                }
//            }
//        }
    }
    
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        if self.postViewHeightConstraint?.isActive == true {
//            let currentIndex = Int(self.postCollectionView.contentOffset.x / self.postCollectionView.frame.size.height)
//            print("Selected Post Index | \(currentIndex)")
//            
//            self.selectedMapPost = self.fetchedPosts[currentIndex]
//            
//        }
    }
    
//    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
//        if self.enableScroll == false {
//            self.enableScroll = true
//        }
//
//        if self.postViewHeightConstraint?.isActive == true {
//            let currentIndex = Int(self.postCollectionView.contentOffset.x / self.postCollectionView.frame.size.height)
//            print("Selected Post Index | \(currentIndex)")
//
//            self.selectedMapPost = self.fetchedPosts[currentIndex]
//
//        }
//
//    }
    
    // COLLECTION VIEW
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
    
    let cellId = "cellId"
    let gridCellId = "gridcellId"
    let listHeaderId = "headerId"
    var scrolltoFirst: Bool = false
    
    var hidePostHeightConstraint:NSLayoutConstraint?
    var postViewHeightConstraint:NSLayoutConstraint?
    var fullListViewConstraint:NSLayoutConstraint?
    
    var mapViewHeightConstraint:NSLayoutConstraint?
    
    let hideMapViewHideHeight: CGFloat = UIApplication.shared.statusBarFrame.height
    
    let headerHeight: CGFloat = 40 //40
    let postHeight: CGFloat = 180 //150
    let fullHeight: CGFloat = UIScreen.main.bounds.height - UIApplication.shared.statusBarFrame.height
    
    let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search"
        sb.barTintColor = UIColor.lightGray
        //        sb.layer.borderColor = UIColor.lightGray.cgColor
        //        sb.layer.borderWidth = 1
        return sb
    }()
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        self.openSearch(index: 0)
        return false
    }
    
    // Pagination Variables
    
    var userPostIdFetched = false
    var followingPostIdFetched = false
    var paginatePostsCount: Int = 0
    
    var isFinishedPaging = false {
        didSet{
            if isFinishedPaging == true {
                print("Paging Finish: \(self.isFinishedPaging), \(self.paginatePostsCount) Posts")
            }
        }
    }
    
    static let refreshPostsNotificationName = NSNotification.Name(rawValue: "RefreshPosts")
    static let finishFetchingUserPostIdsNotificationName = NSNotification.Name(rawValue: "FinishFetchingUserPostIds")
    static let finishFetchingFollowingPostIdsNotificationName = NSNotification.Name(rawValue: "FinishFetchingFollowingPostIds")
    static let finishSortingFetchedPostsNotificationName = NSNotification.Name(rawValue: "FinishSortingFetchedPosts")
    static let finishPaginationNotificationName = NSNotification.Name(rawValue: "FinishPagination")
    static let refreshNoLocErrorNotificationName = NSNotification.Name(rawValue: "RefreshNoLocError")
    
    
    // Geo Filter Variables
    
    let geoFilterRange = geoFilterRangeDefault
    //    let geoFilterImage:[UIImage] = geoFilterImageDefault
    
    
    // Filter Variables
    var mapFilter: Filter? {
        didSet{
            setupNavigationItems()
            if mapFilter?.filterLocation == CurrentUser.currentLocation {
                mapFilter?.filterLocationName = "Current Location"
            }
        }
    }
    var isFilterList: Bool = false
    var isFilterUser: Bool = false
    
    // NAVIGATION BUTTONS
    
    let actionBarView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        view.backgroundColor = UIColor.clear

        return view
    }()
    
    lazy var mapDisplayDetailLabel: UILabel = {
        let label = UILabel()
        label.text = "Add"
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.darkLegitColor()
        label.backgroundColor = UIColor.clear
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.textAlignment = NSTextAlignment.center
        label.adjustsFontSizeToFitWidth = true
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.numberOfLines = 0
        return label
    }()
    
    lazy var mapDisplayDetailView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        view.backgroundColor = UIColor.lightSelectedColor()
        return view
    }()
    
    lazy var mapDisplayDetailToggleButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        button.setImage(#imageLiteral(resourceName: "expand_mainview"), for: .normal)
        button.addTarget(self, action: #selector(toggleMainView), for: .touchUpInside)
        return button
    }()
    
    let defaultMapDetail = "Tap Side Buttons To Filter Map By User Or List"
    let filteringMapDetail = "Tap Top Right Button to Refresh Map"
    
    lazy var mapDisplayDetailLabelAdd: PaddedUILabel = {
        let label = PaddedUILabel()
        label.text = "Tap Side Buttons To Filter Map By User Or List"
        label.font = UIFont.italicSystemFont(ofSize: 9)
        label.textColor = UIColor.gray
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.textAlignment = NSTextAlignment.center
        label.adjustsFontSizeToFitWidth = true
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.numberOfLines = 0
        return label
    }()
    
    let addPhotoButtonSize: CGFloat = 50 //40

    
    lazy var addPhotoButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
//        button.layer.cornerRadius = button.frame.width/2
//        button.layer.masksToBounds = true
        return button
    }()
    
    lazy var addPhotoButtonLabel: UILabel = {
        let label = UILabel()
        label.text = "Add"
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.darkGray
        label.textColor = UIColor.darkLegitColor()
//        label.textColor = UIColor.darkSelectedColor()

        label.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        return label
    }()
    
    lazy var userButtonLabel: UILabel = {
        let label = UILabel()
        label.text = "Users"
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.darkGray
        label.textColor = UIColor.darkLegitColor()
//        label.textColor = UIColor.darkSelectedColor()

        label.backgroundColor = UIColor.clear
        label.backgroundColor = UIColor.white.withAlphaComponent(0.5)

        return label
    }()
    
    lazy var listButtonLabel: UILabel = {
        let label = UILabel()
        label.text = "Lists"
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.darkGray
        label.textColor = UIColor.darkLegitColor()
//        label.textColor = UIColor.darkSelectedColor()

        label.backgroundColor = UIColor.clear
        label.backgroundColor = UIColor.white.withAlphaComponent(0.5)

        return label
    }()
    
    lazy var globeButtonLabel: UILabel = {
        let label = UILabel()
        label.text = "Zoom Out"
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.darkGray
        label.textColor = UIColor.darkLegitColor()
        
//        label.textColor = UIColor.darkSelectedColor()

        label.backgroundColor = UIColor.clear
        label.backgroundColor = UIColor.white.withAlphaComponent(0.5)

        return label
    }()
    
    lazy var timeFilterButton: PaddedUILabel = {
        let label = PaddedUILabel()
        label.text = self.mapFilter?.filterSort
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.legitColor()
        label.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(activateSortPicker)))
        return label
    }()
    
    lazy var filterLegitButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "legit").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(filterLegitPosts), for: .touchUpInside)
        button.layer.cornerRadius = button.frame.width/2
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()
    
    lazy var openFilterButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "filter").withRenderingMode(.alwaysOriginal), for: .normal)
        button.setImage(#imageLiteral(resourceName: "slider_color").withRenderingMode(.alwaysOriginal), for: .normal)
        button.setImage(#imageLiteral(resourceName: "slider_gray").withRenderingMode(.alwaysOriginal), for: .normal)

        button.addTarget(self, action: #selector(openFilter), for: .touchUpInside)
        button.layer.cornerRadius = button.frame.width/2
        button.layer.masksToBounds = true
        return button
    }()
    
    
    
    // Set Up Range Picker for Distance Filtering
    
    lazy var dummyTextView: UITextView = {
        let tv = UITextView()
        tv.delegate = self
        return tv
    }()
    
    var tapCancelView: UIView?
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        self.tapCancelView?.isHidden = false
        self.tapCancelView?.removeFromSuperview()
        
        self.tapCancelView = UIView()
        tapCancelView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissPicker)))
        tapCancelView?.backgroundColor = UIColor.clear
        tapCancelView?.isUserInteractionEnabled = true
        view.addSubview(tapCancelView!)
        tapCancelView?.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor , right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        return true
    }
    
    @objc func dismissPicker(){
        self.tapCancelView?.isHidden = true
        self.dummyTextView.resignFirstResponder()
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        self.tapCancelView?.isHidden = true
        return true
    }
    
    var pickerView: UIPickerView = {
        let pv = UIPickerView()
        pv.backgroundColor = .white
        pv.showsSelectionIndicator = true
        return pv
    }()
    
    
    let userButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        button.setImage(#imageLiteral(resourceName: "friendship"), for: .normal)
        button.layer.cornerRadius = button.frame.width/2
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(openUsers), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        button.layer.borderColor = UIColor.gray.cgColor
        button.layer.borderWidth = 1
        return button
    }()
    
    let userLabel: LightPaddedUILabel = {
        let label = LightPaddedUILabel()
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.legitColor()
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        //        label.backgroundColor = UIColor.selectedColor()

        return label
    }()
    
    @objc func toggleMainView(){
        if (self.fullListViewConstraint?.isActive)! {
            self.showFullMap()
        } else {
            self.showFullList()
        }
    }
    
    @objc func openUsers(){
        let transition = CATransition()
        transition.duration = 0.5
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromRight
        transition.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
        view.window!.layer.add(transition, forKey: kCATransition)
        
        let userProfileController = UserListViewController()
        userProfileController.delegate = self
        userProfileController.displayUser = CurrentUser.user
        userProfileController.selectedUser = self.mapFilter?.filterUser
        self.navigationController?.pushViewController(userProfileController, animated: true)
        
        print("USER")
    }
    
    let listButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        button.setImage(#imageLiteral(resourceName: "bookmark_white"), for: .normal)
        button.layer.cornerRadius = button.frame.width/2
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = true
        button.layer.borderColor = UIColor.gray.cgColor
        button.layer.borderWidth = 1
//        button.layer.borderColor = UIColor.init(hex: "f10f3c").cgColor
        return button
    }()
    
    let listLabelView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.darkLegitColor().cgColor
//        view.layer.borderColor = UIColor.init(hex: "f10f3c").cgColor
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()
    
    let listLabel: LightPaddedUILabel = {
        let label = LightPaddedUILabel()
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.textColor = UIColor.darkLegitColor()
//        label.textColor = UIColor.init(hex: "f10f3c")
        label.backgroundColor = UIColor.clear
        label.layer.borderColor = UIColor.init(hexColor: "f10f3c").cgColor
        label.layer.borderWidth = 0
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        return label
    }()
    
    let listDetailLabel: LightPaddedUILabel = {
        let label = LightPaddedUILabel()
        label.font = UIFont.boldSystemFont(ofSize: 11)
        label.textColor = UIColor.legitColor()
        label.textColor = UIColor.darkGray

        label.backgroundColor = UIColor.white
        label.layer.borderColor = UIColor.legitColor().cgColor
        label.layer.borderWidth = 0
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        return label
    }()
    
    @objc func openLists(){
        let transition = CATransition()
        transition.duration = 0.5
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromLeft
        transition.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
        view.window!.layer.add(transition, forKey: kCATransition)
        
        let mainListViewController = MainListViewController()
        mainListViewController.delegate = self
        if self.mapFilter?.filterUser == nil {
            mainListViewController.displayUser = CurrentUser.user
            mainListViewController.enableListManagementView = true
        } else {
            mainListViewController.displayUser = self.mapFilter?.filterUser
        }
        
        mainListViewController.currentDisplayedList = self.mapFilter?.filterList
        
        self.navigationController?.pushViewController(mainListViewController, animated: true)
    }
    
    
    lazy var listToggleButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "list_toggle_button").withRenderingMode(.alwaysOriginal), for: .normal)
        button.setImage(#imageLiteral(resourceName: "toggle_on").withRenderingMode(.alwaysOriginal), for: .normal)

        button.addTarget(self, action: #selector(toggleListView), for: .touchUpInside)
        //        button.layer.backgroundColor = UIColor.white.withAlphaComponent(0.5).cgColor
        //        button.layer.cornerRadius = 30/2
        button.layer.borderColor = UIColor.darkGray.cgColor
        //        button.layer.borderWidth = 1
        button.clipsToBounds = true
        //        button.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        return button
    }()
    
    lazy var listSideButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//        button.setImage((#imageLiteral(resourceName: "list_toggle_button").resizeImageWith(newSize: CGSize(width: 25, height: 25))).withRenderingMode(.alwaysOriginal), for: .normal)
        button.setImage((#imageLiteral(resourceName: "navBackImage").resizeImageWith(newSize: CGSize(width: 15, height: 15))).withRenderingMode(.alwaysTemplate), for: .normal)

        button.tintColor = UIColor.ianLegitColor()
        button.addTarget(self, action: #selector(toggleListView), for: .touchUpInside)
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.layer.borderWidth = 0
        button.clipsToBounds = true
        
        button.layer.cornerRadius = 10
        button.layer.backgroundColor = UIColor.white.cgColor
        button.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        button.setTitle(" BACK ", for: .normal)
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
        button.layer.borderColor = UIColor.ianLegitColor().cgColor
        button.layer.borderWidth = 1

//        button.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
//        button.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
//        button.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        
//        button.setImage(#imageLiteral(resourceName: "list_toggle_button").withRenderingMode(.alwaysOriginal), for: .normal)
//        button.setImage((#imageLiteral(resourceName: "list_navbar").resizeImageWith(newSize: CGSize(width: 45, height: 45))).withRenderingMode(.alwaysOriginal), for: .normal)
        //        button.layer.backgroundColor = UIColor.white.withAlphaComponent(0.5).cgColor
        //        button.layer.cornerRadius = 30/2
        //        button.layer.borderWidth = 1
        //        button.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        return button
    }()
    
    
    let navBarLabelButton: UIButton = {
        let button = UIButton()
//        let title = NSMutableAttributedString(string: "Full View", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12), NSForegroundColorAttributeName: UIColor.darkGray])
//        button.setAttributedTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        button.setTitleColor(UIColor.selectedColor(), for: .normal)
        button.setTitle("Full", for: .normal)
        button.addTarget(self, action: #selector(showFullMap), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()
    
    @objc func toggleListView(){
        
        appDelegateFilter = self.mapFilter
        if self.mapFilter?.filterList != nil {
            appDelegateViewPage = 1
            print("Toggle MapView | List View | \(appDelegateViewPage)")
        } else if self.mapFilter?.filterUser != nil {
            appDelegateViewPage = 2
            print("Toggle MapView | User View | \(appDelegateViewPage)")
        } else {
            appDelegateViewPage = 0
            print("Toggle MapView | Home View | \(appDelegateViewPage)")
        }
        
        NotificationCenter.default.post(name: AppDelegate.SwitchToListNotificationName, object: nil)

        
//        if mapDisplayed{
//            self.showFullList()
//        } else {
//            self.showFullMap()
//        }
    }
    
    var isListView: Bool = true
    
    lazy var formatButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.system)
        button.setImage(self.isListView ? #imageLiteral(resourceName: "list") :#imageLiteral(resourceName: "grid"), for: .normal)
        button.addTarget(self, action: #selector(changeView), for: .touchUpInside)
        //        button.tintColor = UIColor.legitColor()
        button.tintColor = UIColor.lightGray
        button.layer.backgroundColor = UIColor.white.withAlphaComponent(0.5).cgColor
        //        button.layer.cornerRadius = 30/2
        //        button.layer.borderColor = UIColor.lightGray.cgColor
        //        button.layer.borderWidth = 1
        //        button.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        button.clipsToBounds = true
        return button
    }()
    
    @objc func changeView(){
        self.isListView = !self.isListView
        self.postCollectionView.reloadData()
        self.setupNavigationItems()
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
    
    var buttonStackView = UIStackView()
    var altButtonView = UIView()
    
    let refreshButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
//        button.setImage(#imageLiteral(resourceName: "refresh_blue"), for: .normal)
        button.setImage(#imageLiteral(resourceName: "refresh"), for: .normal)

//        button.setImage(#imageLiteral(resourceName: "refresh_white"), for: .normal)
        button.addTarget(self, action: #selector(refreshWithoutMovingMap), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.clear.cgColor
//        button.layer.backgroundColor = UIColor.white.withAlphaComponent(0.75).cgColor
//        button.layer.borderColor = UIColor.legitColor().cgColor
//        button.layer.borderWidth = 1
        button.layer.cornerRadius = 30/2
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()
    
    let globeButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        button.setImage(#imageLiteral(resourceName: "Globe"), for: .normal)
//        button.setImage(#imageLiteral(resourceName: "refresh_white"), for: .normal)
        button.addTarget(self, action: #selector(showGlobe), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.clear.cgColor
//        button.layer.cornerRadius = button.frame.width/2
//        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()

    
    let collapseButton: UIButton = {
        let button = UIButton()
//        button.setImage(#imageLiteral(resourceName: "collapse_mainview"), for: .normal)
        let title = NSMutableAttributedString(string: "Hide", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 12), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white]))
        button.layer.backgroundColor = UIColor.legitColor().withAlphaComponent(0.8).cgColor
        button.layer.cornerRadius = 10
        button.setAttributedTitle(title, for: .normal)
        button.addTarget(self, action: #selector(showFullMap), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()
    
    let collapseButton_fullList: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        button.setImage(#imageLiteral(resourceName: "upvote_selected"), for: .normal)
//        button.setImage((#imageLiteral(resourceName: "google_color").resizeImageWith(newSize: CGSize(width: 25, height: 25))), for: .normal)

        button.addTarget(self, action: #selector(showFullMap), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.translatesAutoresizingMaskIntoConstraints = true
        
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.layer.borderWidth = 0

        button.setTitle(" Hide ", for: .normal)
        button.contentHorizontalAlignment = .left
        
        button.layer.cornerRadius = 10
//        button.layer.backgroundColor = UIColor.gray.withAlphaComponent(0.8).cgColor
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)

//        button.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
//        button.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
//        button.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)

        
        return button
    }()
    
    let expandButton: UIButton = {
        let button = UIButton()

        let title = NSMutableAttributedString(string: " Show List ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 12), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkLegitColor()]))

        button.setAttributedTitle(title, for: .normal)
        button.addTarget(self, action: #selector(showFullList), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.selectedColor().withAlphaComponent(0.8).cgColor
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()
    
    let postCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 10)
        label.textColor = UIColor.darkGray
        label.backgroundColor = UIColor.white.withAlphaComponent(0.75)
        return label
    }()
    
    // MARK: - VIEW

    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Loading Main View Controller")
        self.view.backgroundColor = UIColor.legitColor()
        
        if appDelegateFilter != nil {
            print("MainViewController | Filter Init | Load AppDelegateFilter")
            self.mapFilter = appDelegateFilter
        } else {
            print("MainViewController | Filter Init | No AppDelegateFilter - Self Init")
            self.mapFilter = Filter.init()
        }

        setupNotificationCenters()
        setupNavigationItems()
        setupMap()
        setupCollectionView()
        setupViews()
        setupPicker()
        refreshCurrentUser()
    }
    
    override func viewWillAppear(_ animated: Bool) {

        self.hideView.isHidden = true
        self.setupNavigationItems()
        self.checkAppDelegateFilter()
        
        if CurrentUser.user == nil {
            Database.loadCurrentUser(inputUser: nil) {
                self.fetchAllPostIds()
            }
        }
    }
    
    func checkAppDelegateFilter(){
        if appDelegateFilter != nil {
            self.mapFilter = appDelegateFilter
            self.mapFilter?.filterSort = defaultNearestSort
            print("checkAppDelegateFilter | GPS | \(self.mapFilter?.filterLocation?.coordinate)")
            print("MainViewController | Loaded App Delegate Filter")
            appDelegateFilter = nil
            self.refreshPostsForFilter()
        } else {
            print("MainViewController | NO FILTER")
        }
        
        
        
    }
    
    func refreshCurrentUser(){
        if self.mapFilter?.filterLocation == nil {
            self.mapFilter?.filterLocation = CurrentUser.currentLocation
        }
        self.setupButtons()
        //self.fetchAllPostIds()
    }
    
    
    
    
    
    
    func showNavBar(){
        self.navigationController?.navigationBar.isTranslucent = false
        
        let tempImage = UIImage.init(color: UIColor.legitColor())
        self.navigationController?.navigationBar.setBackgroundImage(tempImage, for: .default)
        self.navigationController?.view.backgroundColor = UIColor.legitColor()
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        // Nav Bar Buttons
        collapseButton_fullList.addTarget(self, action: #selector(showFullMap), for: .touchUpInside)
        let barButton1 = UIBarButtonItem.init(customView: collapseButton_fullList)

        self.navigationItem.leftBarButtonItems = [barButton1]
        self.navigationController?.navigationBar.layoutIfNeeded()
    }
    
    func hideNavBar(){
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.layoutIfNeeded()
        
        // Nav Bar Buttons
        listSideButton.addTarget(self, action: #selector(toggleListView), for: .touchUpInside)
        let barButton1 = UIBarButtonItem.init(customView: listSideButton)
        
        self.navigationItem.leftBarButtonItems = [barButton1]
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.hideView.isHidden = false
        self.navigationController?.navigationBar.isTranslucent = false
        let tempImage = UIImage.init(color: UIColor.legitColor())
        self.navigationController?.navigationBar.setBackgroundImage(tempImage, for: .default)
        self.navigationController?.view.backgroundColor = UIColor.legitColor()
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.barTintColor = UIColor.legitColor()
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
//        self.navigationController?.navigationBar.layoutIfNeeded()
        
        
        //                self.navigationController?.navigationBar.barStyle = UIBarStyle.blackOpaque
        //                let tempImage = UIImage.init(color: UIColor.legitColor())
        //                self.navigationController?.navigationBar.setBackgroundImage(tempImage, for: .default)
        
    }
    
    
    
    func successLogin(){
//        self.view.backgroundColor = UIColor.legitColor()
        SVProgressHUD.show(withStatus: "Logging in")

        self.navigationController?.popToRootViewController(animated: true)

        self.mapFilter = Filter.init()
        self.mapFilter?.filterLocation = CurrentUser.currentLocation
        setupNotificationCenters()
        setupNavigationItems()
        setupMap()
        setupPicker()
        setupCollectionView()
        setupButtons()
        fetchAllPostIds()
        setupViews()
        SVProgressHUD.dismiss()

//        loadCurrentUser()
//        NotificationCenter.default.post(name: AppDelegate.LoadUserListViewNotificationName, object: nil)

    }
    
//    func loadCurrentUser(){
//        if Auth.auth().currentUser == nil {
//            DispatchQueue.main.async {
//                print("Displaying Login Controller")
//                let loginController = LoginController()
//                loginController.delegate = self
//                let navController = UINavigationController(rootViewController: loginController)
//                self.present(navController, animated: true, completion: nil)
//            }
//        } else if !(Auth.auth().currentUser?.isAnonymous)!{
//
//            // Check if current logged in user uid actually exists in database
//            guard let userUid = Auth.auth().currentUser?.uid else {return}
//
//            let ref = Database.database().reference().child("users").child(userUid)
//            ref.observeSingleEvent(of: .value, with: { (snapshot) in
//
//                if snapshot != nil {
//                    print("MainViewController | User Exist")
//                    Database.loadCurrentUser(inputUser: nil) {
//                        print("MainViewController | Fetched Current User | \(CurrentUser.user?.uid) | \(CurrentUser.currentLocation?.coordinate)")
//                        self.mapFilter?.filterLocation = CurrentUser.currentLocation
//                        self.fetchAllPostIds()
//                        self.setupViews()
//                    }
//                } else {
//                    // Create new user in database if current user doesn't exist
//                    print("MainViewController | User Doesn't Exist")
//                    DispatchQueue.main.async {
//                        let loginController = LoginController()
//                        loginController.delegate = self
//                        let navController = UINavigationController(rootViewController: loginController)
//                        self.present(navController, animated: true, completion: nil)
//                    }
//                    return
//                }
//            }){ (err) in print("MainViewController | Error Search User", err) }
//        } else if (Auth.auth().currentUser?.isAnonymous)!{
//            Database.loadCurrentUser(inputUser: nil) {
//                print("MainViewController | Fetching Guest User | \(CurrentUser.user?.uid) | \(CurrentUser.currentLocation?.coordinate)")
//                self.mapFilter?.filterLocation = CurrentUser.currentLocation
//                self.fetchAllPostIds()
//                self.setupViews()
//            }
//        }
//    }
    
    func setupPicker(){
        var toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.backgroundColor = UIColor.lightGray
        
        toolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
        toolBar.sizeToFit()
        
        //            let doneButton = UIBarButtonItem(title: "More Filters", style: UIBarButtonItemStyle.bordered, target: self, action: Selector("donePicker"))
        
        let doneButton = UIBarButtonItem(title: "OK", style: UIBarButtonItem.Style.bordered, target: self, action: Selector("donePicker"))
        
        let selectAttributes = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 16), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, convertFromNSAttributedStringKey(NSAttributedString.Key.backgroundColor): UIColor.black]
        
        doneButton.setTitleTextAttributes(convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 16)]), for: .normal)
        
        let moreFilterButton = UIBarButtonItem(title: "More Filters", style: UIBarButtonItem.Style.bordered, target: self, action: Selector("pickerFilter"))
        //            cancelButton.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.red], for: .normal)
        moreFilterButton.setTitleTextAttributes(convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.red, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 16)]), for: .normal)
        
        let moreFilterButtonAttributes = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 16), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, convertFromNSAttributedStringKey(NSAttributedString.Key.backgroundColor): UIColor.darkLegitColor()]
        
        
        
        var toolbarTitle = UILabel()
        toolbarTitle.text = "Posts From Last"
        toolbarTitle.textAlignment = NSTextAlignment.center
        let toolbarTitleButton = UIBarButtonItem(customView: toolbarTitle)
        
        let space1Button = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let space2Button = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        
        toolBar.setItems([moreFilterButton,space1Button, toolbarTitleButton,space2Button, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        //            pickerView = UIPickerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 150))
        pickerView.delegate = self
        pickerView.dataSource = self
        self.dummyTextView.inputView = pickerView
        self.dummyTextView.inputAccessoryView = toolBar
        self.view.addSubview(dummyTextView)
    }
    
    
    func pickerFilter(){
        let filterTimeText = FilterTimeDefault[pickerView.selectedRow(inComponent: 0)]
        
        self.mapFilter?.filterTime = FilterTimeDefaultDict[filterTimeText]
        print("Filter Time Selected: \(self.mapFilter?.filterTime) | \(filterTimeText)")
        self.openFilter()
    }
    
    func donePicker(){
        //        self.mapFilter?.filterSort = HeaderSortOptions[pickerView.selectedRow(inComponent: 0)]
        //        print("Sort Selected: \(self.mapFilter?.filterSort)")
        //        self.openFilter()
        
        let filterTimeText = FilterTimeDefault[pickerView.selectedRow(inComponent: 0)]
        
        if self.mapFilter?.filterTime != FilterTimeDefaultDict[filterTimeText] {
            self.mapFilter?.filterTime = FilterTimeDefaultDict[filterTimeText]
            self.timeFilterButton.text = filterTimeText
            self.timeFilterButton.sizeToFit()
            self.refreshPostsForFilter()
        }
        dummyTextView.resignFirstResponder()
        
    }
    
    func cancelPicker(){
        dummyTextView.resignFirstResponder()
    }
    
    @objc func activateSortPicker() {
        if let rangeIndex = FilterTimeDefault.firstIndex(of: (self.timeFilterButton.text)!) {
            pickerView.selectRow(rangeIndex, inComponent: 0, animated: false)
        } else {
            pickerView.selectRow(FilterTimeDefault.firstIndex(of: FilterTimeDefault[0])!, inComponent: 0, animated: false)
        }
        dummyTextView.perform(#selector(becomeFirstResponder), with: nil, afterDelay: 0.1)
    }
    
    // UIPicker Delegate
    
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return FilterTimeDefault.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        let options = FilterTimeDefault[row]
        return options
        
        //        if row >= HeaderSortOptions.count {
        //            let moreOptions = "More Filters"
        //            return moreOptions
        //        } else {
        //            let options = HeaderSortOptions[row]
        //            return options
        //        }
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30
    }
    
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // If Select some number
        //        self.selectedRange = selectedRangeOptions[row]
        //        let filterTimeText = FilterTimeDefault[row]
        //
        //        if self.mapFilter?.filterTime != FilterTimeDefaultDict[filterTimeText] {
        //            self.mapFilter?.filterTime = FilterTimeDefaultDict[filterTimeText]
        //            self.timeFilterButton.text = filterTimeText
        //            self.refreshPostsForFilter()
        //        }
        //        dummyTextView.resignFirstResponder()
        
    }
    
    var hideView = UIView()
    let actionBarHeight: CGFloat = 60.0
    
    func setupViews(){
        
        view.addSubview(mapView)
        mapView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        mapViewHeightConstraint = mapView.heightAnchor.constraint(equalToConstant: hideMapViewHideHeight)
        mapViewHeightConstraint?.isActive = false
        if self.mapFilter?.filterLocation != nil {
            self.centerMapOnLocation(location: self.mapFilter?.filterLocation)
        } else {
            self.centerMapOnLocation(location: CurrentUser.currentLocation)
        }
        
        view.addSubview(hideView)
        hideView.anchor(top: mapView.topAnchor, left: mapView.leftAnchor, bottom: mapView.bottomAnchor, right: mapView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        hideView.backgroundColor = UIColor.legitColor()
        hideView.isHidden = true
        
        view.addSubview(postCollectionView)
        postCollectionView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        hidePostHeightConstraint = postCollectionView.heightAnchor.constraint(equalToConstant:0)
        postViewHeightConstraint = postCollectionView.heightAnchor.constraint(equalToConstant:postHeight)
        fullListViewConstraint = postCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        
        view.addSubview(expandButton)
        expandButton.anchor(top: postCollectionView.bottomAnchor, left: nil, bottom: nil, right: postCollectionView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        expandButton.sizeToFit()
        expandButton.isHidden = true
        
//        view.addSubview(collapseButton)
//        collapseButton.anchor(top: postCollectionView.bottomAnchor, left: nil, bottom: nil, right: expandButton.leftAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
//        collapseButton.sizeToFit()
//        collapseButton.isHidden = true
        
        navigationItem.titleView = searchBar
//        navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: openFilterButton)
        refreshButton.addTarget(self, action: #selector(handleRefresh), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: refreshButton)


        let barButton1 = UIBarButtonItem.init(customView: listSideButton)
        self.navigationItem.leftBarButtonItems = [barButton1]
        
        
        searchBar.addSubview(postCountLabel)
        postCountLabel.anchor(top: nil, left: nil, bottom: nil, right: searchBar.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 90, width: 0, height: 0)
        postCountLabel.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor).isActive = true
        postCountLabel.sizeToFit()
        postCountLabel.layer.cornerRadius = postCountLabel.font.pointSize / 2
        postCountLabel.clipsToBounds = true

        
//        self.showPost()
        self.showFullMap()
        
// SETUP ACTION BARS
        
        view.addSubview(actionBarView)
        actionBarView.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 15, paddingRight: 0, width: 0, height: actionBarHeight)

// SETUP LIST BUTTON

        let listDoubleTap = UITapGestureRecognizer(target: self, action: #selector(clearList))
        listDoubleTap.numberOfTapsRequired = 2
        
        let listSingleTap = UITapGestureRecognizer(target: self, action: #selector(openLists))
        listSingleTap.require(toFail: listDoubleTap)
        
        listButton.addGestureRecognizer(listSingleTap)
        listButton.addGestureRecognizer(listDoubleTap)
        
        view.addSubview(listButton)
//        listButton.anchor(top: listView.topAnchor, left: nil, bottom: listView.bottomAnchor, right: listView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 20, width: 0, height: 0)
        listButton.anchor(top: actionBarView.topAnchor, left: nil, bottom: actionBarView.bottomAnchor, right: actionBarView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 20, width: 0, height: 0)

        listButton.widthAnchor.constraint(equalTo: listButton.heightAnchor, multiplier: 1).isActive = true
        listButton.layer.cornerRadius = listButton.frame.height/2
        listButton.clipsToBounds = true
        
        view.addSubview(listLabelView)
        listLabelView.anchor(top: nil, left: nil, bottom: nil, right: listButton.leftAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 4, width: 0, height: 0)
        listLabelView.centerYAnchor.constraint(equalTo: listButton.centerYAnchor).isActive = true

//        listLabelView.leftAnchor.constraint(lessThanOrEqualTo: addPhotoButton.rightAnchor).isActive = true
//        listLabelView.leftAnchor.constraint(greaterThanOrEqualTo: addPhotoButton.rightAnchor).isActive = true

        listLabelView.isHidden = true
        
        listLabelView.addSubview(listLabel)
        listLabel.anchor(top: listLabelView.topAnchor, left: listLabelView.leftAnchor, bottom: nil, right: listLabelView.rightAnchor, paddingTop: 2, paddingLeft: 2, paddingBottom: 0, paddingRight: 2, width: 0, height: 0)
        
        listLabelView.addSubview(listDetailLabel)
        listDetailLabel.anchor(top: listLabel.bottomAnchor, left: listLabelView.leftAnchor, bottom: listLabelView.bottomAnchor, right: listLabelView.rightAnchor, paddingTop: 0, paddingLeft: 2, paddingBottom: 2, paddingRight: 2, width: 0, height: 0)
        
        listLabel.sizeToFit()
        listDetailLabel.sizeToFit()
        
        listLabel.layer.cornerRadius = listLabel.font.pointSize / 2
        listLabel.clipsToBounds = true
        listLabelView.isHidden = true

        let listLabelTap = UITapGestureRecognizer(target: self, action: #selector(toggleMainView))
        listLabelTap.numberOfTapsRequired = 1
        listLabel.addGestureRecognizer(listLabelTap)
        listLabel.isUserInteractionEnabled = true
        
        let listDetailLabelTap = UITapGestureRecognizer(target: self, action: #selector(toggleMainView))
        listDetailLabelTap.numberOfTapsRequired = 1
        listDetailLabel.addGestureRecognizer(listDetailLabelTap)
        listDetailLabel.isUserInteractionEnabled = true
        
        view.addSubview(listButtonLabel)
        listButtonLabel.anchor(top: listButton.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 3, paddingBottom: 3, paddingRight: 0, width: 0, height: 0)
        listButtonLabel.sizeToFit()
        listButtonLabel.centerXAnchor.constraint(equalTo: listButton.centerXAnchor).isActive = true

        
    // USER BUTTON
        let isFilterUser = self.mapFilter?.filterUser != nil
        
//        let userButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))

        
        let userTap = UITapGestureRecognizer(target: self, action: #selector(openUsers))
        let userDoubleTap = UITapGestureRecognizer(target: self, action: #selector(handleRefresh))
        userDoubleTap.numberOfTapsRequired = 2
        userTap.require(toFail: userDoubleTap)
        
        userButton.addGestureRecognizer(userTap)
        userButton.addGestureRecognizer(userDoubleTap)
        
        view.addSubview(userButton)
//        userButton.anchor(top: userView.topAnchor, left: userView.leftAnchor, bottom: userView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 20, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        userButton.anchor(top: actionBarView.topAnchor, left: actionBarView.leftAnchor, bottom: actionBarView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 20, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)

        
//        userButton.centerXAnchor.constraint(equalTo: userView.centerXAnchor).isActive = true
        userButton.widthAnchor.constraint(equalTo: userButton.heightAnchor, multiplier: 1).isActive = true
        userButton.addTarget(self, action: #selector(openUsers), for: .touchUpInside)
        userButton.layer.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        userButton.layer.cornerRadius = userButton.frame.width / 2
        userButton.layer.masksToBounds = true
        userButton.clipsToBounds = true
//        userButton.setImage(#imageLiteral(resourceName: "home_tab_filled"), for: .normal)
        userButton.setImage(#imageLiteral(resourceName: "profile_outline"), for: .normal)
        userButton.setImage(#imageLiteral(resourceName: "friendship"), for: .normal)

        
        view.addSubview(userLabel)
        userLabel.anchor(top: nil, left: nil, bottom: userButton.topAnchor, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        userLabel.centerXAnchor.constraint(equalTo: userButton.centerXAnchor).isActive = true
        userLabel.rightAnchor.constraint(lessThanOrEqualTo: view.rightAnchor).isActive = true
        
        userLabel.layer.cornerRadius = userLabel.font.pointSize / 2
        userLabel.clipsToBounds = true
        userLabel.isHidden = true
        
        let userLabelTap = UITapGestureRecognizer(target: self, action: #selector(toggleMainView))
        userLabelTap.numberOfTapsRequired = 1
        userLabel.addGestureRecognizer(userLabelTap)
        userLabel.isUserInteractionEnabled = true
        
        view.addSubview(userButtonLabel)
        userButtonLabel.anchor(top: userButton.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 3, paddingLeft: 0, paddingBottom: 3, paddingRight: 0, width: 0, height: 0)
        userButtonLabel.sizeToFit()
        userButtonLabel.centerXAnchor.constraint(equalTo: userButton.centerXAnchor).isActive = true
        
        
// CURRENT MAP VIEW DETAIL
//        let mapDisplayDetailView = UIView()
//        view.addSubview(mapDisplayDetailView)
//        mapDisplayDetailView.anchor(top: actionBarView.topAnchor, left: userButton.rightAnchor, bottom: actionBarView.bottomAnchor, right: listButton.leftAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 0, height: 0)
        
        view.addSubview(mapDisplayDetailView)
        mapDisplayDetailView.anchor(top: actionBarView.topAnchor, left: userButton.rightAnchor, bottom: actionBarView.bottomAnchor, right: listButton.leftAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 0, height: 0)

        view.addSubview(mapDisplayDetailToggleButton)
        mapDisplayDetailToggleButton.anchor(top: nil, left: nil, bottom: nil, right: mapDisplayDetailView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 20, height: 20)
        mapDisplayDetailToggleButton.centerYAnchor.constraint(equalTo: mapDisplayDetailView.centerYAnchor).isActive = true
        
        view.addSubview(mapDisplayDetailLabel)
        mapDisplayDetailLabel.anchor(top: mapDisplayDetailView.topAnchor, left: mapDisplayDetailView.leftAnchor, bottom: mapDisplayDetailView.bottomAnchor, right: mapDisplayDetailToggleButton.leftAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)
    
        let mapDetailTap = UITapGestureRecognizer(target: self, action: #selector(toggleMainView))
        mapDetailTap.numberOfTapsRequired = 1
        mapDisplayDetailLabel.addGestureRecognizer(mapDetailTap)
        mapDisplayDetailLabel.isUserInteractionEnabled = true
        

        
        view.addSubview(mapDisplayDetailLabelAdd)
        mapDisplayDetailLabelAdd.anchor(top: mapDisplayDetailView.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        mapDisplayDetailLabelAdd.centerXAnchor.constraint(equalTo: mapDisplayDetailView.centerXAnchor).isActive = true
        mapDisplayDetailLabelAdd.sizeToFit()
        
//        mapDisplayDetailLabel.leftAnchor.constraint(lessThanOrEqualTo: userButton.rightAnchor).isActive = true
//        mapDisplayDetailLabel.rightAnchor.constraint(lessThanOrEqualTo: listButton.leftAnchor).isActive = true
        
        //        let listView = UIView()
        //        let addPhotoView = UIView()
        //        let userView = UIView()
        //        let refreshView = UIView()
        //        let actionBarStackView = UIStackView(arrangedSubviews: [userView,addPhotoView,listView, refreshView])
        //        let actionBarStackView = UIStackView(arrangedSubviews: [addPhotoView,listView, userView,refreshView])
        
        //        let actionBarStackView = UIStackView(arrangedSubviews: [userView, addPhotoView, listView])
        //
        //
        //        actionBarStackView.distribution = .fillEqually
        //
        //        view.addSubview(actionBarStackView)
        //        actionBarStackView.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 15, paddingRight: 0, width: 0, height: actionBarHeight)
        //
        //        view.addSubview(addPhotoButton)
        //        addPhotoButton.anchor(top: nil, left: nil, bottom: actionBarStackView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: addPhotoButtonSize, height: addPhotoButtonSize)
        ////        addPhotoButton.widthAnchor.constraint(equalTo: addPhotoButton.heightAnchor, multiplier: 1).isActive = true
        //        addPhotoButton.centerXAnchor.constraint(equalTo: addPhotoView.centerXAnchor).isActive = true
        ////        addPhotoButton.layer.cornerRadius = addPhotoButton.frame.width/2
        ////        addPhotoButton.layer.masksToBounds = true
        //        addPhotoButton.isUserInteractionEnabled = true
        //        let addPhotoSingleTap = UITapGestureRecognizer(target: self, action: #selector(addPhoto))
        //        addPhotoButton.addGestureRecognizer(addPhotoSingleTap)
        //
        //        view.addSubview(addPhotoButtonLabel)
        //        addPhotoButtonLabel.anchor(top: addPhotoButton.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 3, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        //        addPhotoButtonLabel.sizeToFit()
        //        addPhotoButtonLabel.centerXAnchor.constraint(equalTo: addPhotoButton.centerXAnchor).isActive = true

        
        
        // REFRESH BUTTON
        
//        view.addSubview(refreshButton)
//        refreshButton.anchor(top: refreshView.topAnchor, left: nil, bottom: refreshView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
//        refreshButton.widthAnchor.constraint(equalTo: refreshButton.heightAnchor, multiplier: 1).isActive = true
//        refreshButton.centerXAnchor.constraint(equalTo: refreshView.centerXAnchor).isActive = true
//
//        refreshButton.layer.cornerRadius = refreshButton.frame.height/2
//        refreshButton.clipsToBounds = true
//        refreshButton.layer.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
//
//        let refreshDoubleTap = UITapGestureRecognizer(target: self, action: #selector(handleRefresh))
//        refreshDoubleTap.numberOfTapsRequired = 2
//
//        let refreshTap = UITapGestureRecognizer(target: self, action: #selector(refreshWithoutMovingMap))
//        refreshTap.numberOfTapsRequired = 1
//        refreshTap.require(toFail: refreshDoubleTap)
//        refreshButton.addGestureRecognizer(refreshTap)
//        refreshButton.addGestureRecognizer(refreshDoubleTap)

        
//        view.addSubview(globeButton)
//        globeButton.anchor(top: refreshView.topAnchor, left: nil, bottom: refreshView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
//        globeButton.widthAnchor.constraint(equalTo: globeButton.heightAnchor, multiplier: 1).isActive = true
//        globeButton.centerXAnchor.constraint(equalTo: refreshView.centerXAnchor).isActive = true
//
//        globeButton.layer.cornerRadius = globeButton.frame.height/2
//        globeButton.clipsToBounds = true
//        globeButton.layer.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        
        
//        view.addSubview(globeButtonLabel)
//        globeButtonLabel.anchor(top: nil, left: nil, bottom: globeButton.topAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 3, paddingRight: 0, width: 0, height: 0)
//        globeButtonLabel.sizeToFit()
//        globeButtonLabel.centerXAnchor.constraint(equalTo: globeButton.centerXAnchor).isActive = true

        
//        refreshButton.layer.cornerRadius = 30/2
//        refreshButton.clipsToBounds = true
//
//        view.addSubview(refreshButton)
//        refreshButton.anchor(top: nil, left: nil, bottom: userLabel.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 15, width: 30, height: 30)

    // TRACKING BUTTON
    
        trackingButton = MKUserTrackingButton(mapView: mapView)
        //        button.layer.backgroundColor = UIColor(white: 1, alpha: 0.8).cgColor
        trackingButton.layer.backgroundColor = UIColor.lightGray.withAlphaComponent(0.25).cgColor
        trackingButton.layer.borderColor = UIColor.white.cgColor
        trackingButton.layer.borderColor = UIColor.mainBlue().cgColor

        trackingButton.layer.borderWidth = 1
        trackingButton.layer.cornerRadius = 5
        trackingButton.translatesAutoresizingMaskIntoConstraints = true
        
        view.addSubview(trackingButton)
        trackingButton.anchor(top: nil, left: nil, bottom: userLabel.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 15, width: 30, height: 30)
//        trackingButton.centerXAnchor.constraint(equalTo: refreshButton.centerXAnchor).isActive = true
        trackingButton.isHidden = false
        trackingButton.backgroundColor = UIColor.white.withAlphaComponent(0.75)
        
        
        view.addSubview(globeButton)
        globeButton.anchor(top: nil, left: nil, bottom: trackingButton.topAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 0, height: 0)
//        globeButton.widthAnchor.constraint(equalTo: globeButton.heightAnchor, multiplier: 1).isActive = true
        globeButton.centerXAnchor.constraint(equalTo: trackingButton.centerXAnchor).isActive = true
        
//        globeButton.layer.cornerRadius = globeButton.frame.height/2
//        globeButton.clipsToBounds = true
//        globeButton.layer.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        
        
        
    // LIST HIDE BUTTON
//        view.addSubview(collapseButton_fullList)
//        collapseButton_fullList.anchor(top: nil, left: nil, bottom: refreshButton.topAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 25, height: 25)
//        collapseButton_fullList.centerXAnchor.constraint(equalTo: trackingButton.centerXAnchor).isActive = true
//        collapseButton_fullList.isHidden = true
//        collapseButton_fullList.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
//        collapseButton_fullList.layer.borderColor = UIColor.darkGray.cgColor
//        collapseButton_fullList.layer.borderWidth = 1

        

        

        self.setupButtons()
        
        let tapCancelView = UIView()
        tapCancelView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissPicker)))
        tapCancelView.backgroundColor = UIColor.yellow
        tapCancelView.isUserInteractionEnabled = true
        view.addSubview(tapCancelView)
        tapCancelView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor , right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        tapCancelView.isHidden = true
        
        
        if CurrentUser.currentLocation != nil {
            print("centerMapOnLocation | CurrentUser Has Location")
            self.centerMapOnLocation(location: CurrentUser.currentLocation)
        } else {
            print("centerMapOnLocation | CurrentUser Has No Location")
            LocationSingleton.sharedInstance.determineCurrentLocation()
            let when = DispatchTime.now() + defaultGeoWaitTime // change 2 to desired number of seconds
            DispatchQueue.main.asyncAfter(deadline: when) {
                //Delay for 1 second to find current location
                self.centerMapOnLocation(location: CurrentUser.currentLocation)
            }
        }
        
        

        
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        CurrentUser.currentLocation = userLocation.location
    }
    
    
    
    
    // NOTIFICATION CENTERS
    func setupNotificationCenters(){
        
        // 1.  Checks if Both User and Following Post Ids are colelctved before proceeding
        NotificationCenter.default.addObserver(self, selector: #selector(finishFetchingPostIds), name: MainViewController.finishFetchingUserPostIdsNotificationName, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(finishFetchingPostIds), name: MainViewController.finishFetchingFollowingPostIdsNotificationName, object: nil)
        
        // 2.  Fetches all Posts and Filters/Sorts
        
        // 3. Paginates Post by increasing displayedPostCount after Filtering and Sorting
        NotificationCenter.default.addObserver(self, selector: #selector(refreshMap), name: MainViewController.finishSortingFetchedPostsNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshSearchBar), name: MainViewController.finishSortingFetchedPostsNotificationName, object: nil)

        
        NotificationCenter.default.addObserver(self, selector: #selector(paginatePosts), name: MainViewController.finishSortingFetchedPostsNotificationName, object: nil)
        
        // 4. Checks after pagination Ends
        NotificationCenter.default.addObserver(self, selector: #selector(finishPaginationCheck), name: MainViewController.finishPaginationNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateFeed), name: SharePhotoListController.updateFeedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: MainViewController.refreshPostsNotificationName, object: nil)
        
    }
    
    // NAVIGATION ITEMS
    
    func setupButtons(){
        
    // IS FILTERING IND
        
        let isFilterUser = self.mapFilter?.filterUser != nil
        self.isFilterList = self.mapFilter?.filterList != nil
        
    // MAP DETAIL BUTTONS
        self.mapDisplayDetailLabelAdd.text = (self.mapFilter?.isFiltering)! ? filteringMapDetail : defaultMapDetail
        
    // EXPAND COLLAPSE BUTTON
        if let _ = self.fullListViewConstraint {
            self.mapDisplayDetailToggleButton.setImage((self.fullListViewConstraint?.isActive)! ? #imageLiteral(resourceName: "upvote_selected") : #imageLiteral(resourceName: "downvote_selected"), for: .normal)
        }
        
        //        self.timeFilterButton.text = FilterTimeDefaultDict.key(forValue: (self.mapFilter?.filterTime)!)
        //        self.timeFilterButton.sizeToFit()
        
    // USER BUTTON

//        addPhotoButton.setImage(#imageLiteral(resourceName: "add_new").resizeImageWith(newSize: CGSize(width: addPhotoButtonSize, height: addPhotoButtonSize)), for: .normal)
//        addPhotoButton.setImage(#imageLiteral(resourceName: "add_color_icon").resizeImageWith(newSize: CGSize(width: addPhotoButtonSize, height: addPhotoButtonSize)), for: .normal)

//        addPhotoButton.setImage(#imageLiteral(resourceName: "add_color").resizeImageWith(newSize: CGSize(width: addPhotoButtonSize, height: addPhotoButtonSize)), for: .normal)

//        addPhotoButton.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        
        // MAP DETAIL LABEL - Filter List First because you can be filtering for another user's list, and we want to display list in that scenario
        
        let mapDetailFontSize: CGFloat = 12
        let displayText = NSMutableAttributedString()

        if isFilterList {
            mapDisplayDetailView.backgroundColor = UIColor.lightSelectedColor()
            if let filterListName = (self.mapFilter?.filterList?.name) {
                
                let initString = NSMutableAttributedString(string: "Showing ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkLegitColor(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .helveticaNeueBold, size: mapDetailFontSize)]))
                displayText.append(initString)
                
                let listNameString = NSMutableAttributedString(string: "\(filterListName) \n", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.mainBlue(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .helveticaNeueBold, size: mapDetailFontSize)]))
                displayText.append(listNameString)

                if let postCount = self.mapFilter?.filterList?.postIds!.count {
                    let displayString = NSMutableAttributedString(string: " \(postCount) Posts", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .helveticaNeueBoldItalic, size: mapDetailFontSize)]))
                    displayText.append(displayString)
                }
                
                if let listEmojis = self.mapFilter?.filterList?.topEmojis.prefix(4) {
                    let displayString = NSMutableAttributedString(string: " \(listEmojis.joined())", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.mainBlue(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .helveticaNeueBoldItalic, size: mapDetailFontSize)]))
                    displayText.append(displayString)
                }
            } else {
                print("mapDisplayDetailLabel | Error | Filter List But No List Name")
            }
        }
            
        else if isFilterUser {
            mapDisplayDetailView.backgroundColor = UIColor.lightSelectedColor()
            if let filterUserName = (self.mapFilter?.filterUser?.username) {
                let initString = NSMutableAttributedString(string: "Showing ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkLegitColor(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .helveticaNeueBold, size: mapDetailFontSize)]))
                displayText.append(initString)
                
                let userNameString = NSMutableAttributedString(string: "\(filterUserName) \n", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.mainBlue(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .helveticaNeueBold, size: mapDetailFontSize)]))
                displayText.append(userNameString)
                
                if let postCount = self.mapFilter?.filterUser?.posts_created {
                    let displayString = NSMutableAttributedString(string: " \(postCount) Posts", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .helveticaNeueBoldItalic, size: mapDetailFontSize)]))
                    displayText.append(displayString)
                }
                
                if let listEmojis = self.mapFilter?.filterUser?.lists_created {
                    let displayString = NSMutableAttributedString(string: " \(listEmojis) Lists", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .helveticaNeueBoldItalic, size: mapDetailFontSize)]))
                    displayText.append(displayString)
                }
            } else {
                print("mapDisplayDetailLabel | Error | Filter User But No Username")
            }
        }
        
        else {
            mapDisplayDetailView.backgroundColor = UIColor.legitColor()
            let initString = NSMutableAttributedString(string: "Showing Home Feed", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .helveticaNeueBold, size: mapDetailFontSize + 2)]))
            displayText.append(initString)
        }
        
        
        
        mapDisplayDetailLabel.attributedText = displayText
        mapDisplayDetailLabel.sizeToFit()
        
        if isFilterUser {
            let userProfileImage = CustomImageView()
            userProfileImage.loadImage(urlString: (self.mapFilter?.filterUser?.profileImageUrl)!)
            userProfileImage.contentMode = .scaleAspectFill
            userProfileImage.clipsToBounds = true
            let userButtonWidth = self.userButton.frame.width
            userButton.setImage(userProfileImage.image?.resizeImageWith(newSize: CGSize(width: userButtonWidth, height: userButtonWidth)), for: .normal)
//            userLabel.sizeToFit()
//            userLabel.isHidden = !isFilterUser
//
//            userLabel.text = (self.mapFilter?.filterUser?.username)!
//            userLabel.backgroundColor = UIColor.selectedColor().withAlphaComponent(0.8)
//            userLabel.textColor = UIColor.darkLegitColor()

//            if mapFilter?.filterUser?.uid == Auth.auth().currentUser?.uid {
//                // Current User
//                userButton.layer.borderColor = UIColor.legitColor().cgColor
//            } else {
//                // OTHER USERS
//                userButton.layer.borderColor = UIColor.otherUserColor().cgColor
//            }
            
        } else {

            userLabel.isHidden = self.isFilterList
            userButton.setImage(#imageLiteral(resourceName: "friendship"), for: .normal)
//            userLabel.text = "User Feed"
//            userLabel.backgroundColor = UIColor.legitColor()
//            userLabel.textColor = UIColor.white
//            userLabel.sizeToFit()
            
        }
        
        
    // LIST BUTTON
        listButton.setImage((self.isFilterList ? #imageLiteral(resourceName: "hashtag_fill") : #imageLiteral(resourceName: "hashtag_white")).withRenderingMode(.alwaysOriginal), for: .normal)
        listButton.setImage((self.isFilterList ? #imageLiteral(resourceName: "bookmark_filled") : #imageLiteral(resourceName: "bookmark_white")).withRenderingMode(.alwaysOriginal), for: .normal)
        
//        listButton.backgroundColor = (self.isFilterList ? UIColor(hexColor: "eab543").withAlphaComponent(0.8) : UIColor.lightGray.withAlphaComponent(0.5))
//        
//    
//        listButton.backgroundColor = (self.isFilterList ? UIColor.selectedColor().withAlphaComponent(0.8) : UIColor.lightGray.withAlphaComponent(0.5))
        
        listButton.backgroundColor = (self.isFilterList ? UIColor.legitColor().withAlphaComponent(0.8) : UIColor.lightGray.withAlphaComponent(0.5))
//        listButton.layer.borderWidth = (self.isFilterList ? 1 : 0)

        
//        listButton.layer.borderColor = UIColor.gray.cgColor
//        listButton.layer.borderWidth = self.isFilterList ? 1 : 0
        
        if self.isFilterList {
            guard let _ = self.mapFilter?.filterList else {
                return
            }
//            listLabel.text  = "\(((self.mapFilter?.filterList?.name)!))"
//            listLabel.numberOfLines = 1
//
//            listDetailLabel.numberOfLines = 2
//            var listDetailLabelText: String = "\((self.mapFilter?.filterList?.postIds!.count)!) Posts"
//
//            if (self.mapFilter?.filterList?.topEmojis.count)! > 0 {
//                var emojiText = (self.mapFilter?.filterList?.topEmojis.prefix(3).joined())!
//                listDetailLabelText = listDetailLabelText + "\n" + emojiText
//            }
//            listDetailLabel.text = listDetailLabelText

//            if (self.mapFilter?.filterList?.topEmojis.count)! > 0 {
//                listLabel.numberOfLines = 2
//                var emojiText = (self.mapFilter?.filterList?.topEmojis.prefix(3).joined())!
//                listLabelText = listLabelText + " \(emojiText)"
//            }
//            listLabel.backgroundColor = UIColor.selectedColor().withAlphaComponent(0.8)
        }
        


//        listLabel.text = self.mapFilter?.filterList?.name
//        listLabel.sizeToFit()
//        listLabelView.isHidden = !self.isFilterList
//        listLabel.isHidden = !self.isFilterList
//        listDetailLabel.isHidden = listLabel.isHidden

        
        if self.fullListViewConstraint?.isActive == true {
        // FULL LIST
            self.actionBarView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
            self.actionBarView.backgroundColor = UIColor.clear

            self.trackingButton.isHidden = true
            self.globeButton.isHidden = true
            self.collapseButton.isHidden = true
            self.expandButton.isHidden = true
//            self.collapseButton_fullList.isHidden = false

            self.postCollectionView.layer.borderWidth = 0
            self.postCollectionView.backgroundColor = UIColor.white
            postCollectionView.isPagingEnabled = false
            
            showNavBar()
        } else {
            self.trackingButton.isHidden = false
            self.globeButton.isHidden = false

//            self.collapseButton_fullList.isHidden = true

            if self.postCollectionView.isHidden {
                self.collapseButton.isHidden = true
//                self.expandButton.isHidden = true
                self.expandButton.isHidden = false

            } else {
                self.collapseButton.isHidden = false
                self.expandButton.isHidden = false
            }
            
            
            self.actionBarView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
            self.actionBarView.backgroundColor = UIColor.clear

            self.postCollectionView.layer.borderWidth = 1
            self.postCollectionView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
            postCollectionView.isPagingEnabled = true
            hideNavBar()
        }
    }
    
    fileprivate func setupNavigationItems() {
        
        self.navigationController?.navigationBar.isTranslucent = true
        // REMOVES THE 1PX BOTTOM LINE IN NAV BAR
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        self.setupButtons()
        // SEARCH BAR
        self.refreshSearchBar()
        
    }
    
    @objc func refreshSearchBar(){
        
        if (self.mapFilter?.isFiltering)! {
            let currentFilter = self.mapFilter
            var searchCaption: String = ""
            
            if currentFilter?.filterCaption != nil {
                searchCaption.append("\((currentFilter?.filterCaption)!)")
            }
            
            if currentFilter?.filterLocationName != nil {
                var locationNameText = currentFilter?.filterLocationName
                if locationNameText == "Current Location" || currentFilter?.filterLocation == CurrentUser.currentLocation {
                    // NOTHING. DON'T DISPLAY CURRENT LOCATION
                } else {
                    if searchCaption != "" {
                        searchCaption.append(" & ")
                    }
                    searchCaption.append("\(locationNameText!)")
                }
            }
            
            if currentFilter?.filterLocationSummaryID != nil {
                var locationSummaryText = currentFilter?.filterLocationSummaryID
                
                let cityID = locationSummaryText?.components(separatedBy: ",")[0]
                if searchCaption != "" {
                    searchCaption.append(" & ")
                }
                searchCaption.append("\(cityID!)")
            }
            
            if (currentFilter?.filterLegit)! {
                if searchCaption != "" {
                    searchCaption.append(" & ")
                }
                searchCaption.append("👌")
            }
            
            if currentFilter?.filterMinRating != 0 {
                if searchCaption != "" {
                    searchCaption.append(" & ")
                }
                searchCaption.append("\((currentFilter?.filterMinRating)!) Stars")
            }
            print("MainViewController | Search Bar Display | \(searchCaption)")
            searchBar.text = searchCaption
        } else {
            searchBar.text = nil
        }
        
        
        for s in searchBar.subviews[0].subviews {
            if s is UITextField {
                s.layer.borderWidth = 1
                //                s.layer.borderColor = UIColor.lightGray.cgColor
                s.layer.borderColor = UIColor.legitColor().cgColor
                s.layer.cornerRadius = 15
                s.layer.masksToBounds = true
                s.layer.backgroundColor = UIColor.lightGray.cgColor
            }
        }
        
        //        searchBar.layer.cornerRadius = 15
        //        searchBar.layer.masksToBounds = true
        searchBar.delegate = self
        searchBar.placeholder = searchBarPlaceholderText_Emoji
        if searchBar.text == searchBar.placeholder || searchBar.text == nil || searchBar.text == "" {
            searchBar.alpha = 0.6
        } else {
            searchBar.alpha = 1
        }
        
        searchBar.barTintColor = UIColor.lightGray
        //        searchBar.frame.size.width = 100
        //        navigationItem.titleView = searchBar
        //        self.postCountLabel.bringSubview(toFront: self.searchBar)
        //        self.view.bringSubview(toFront: self.postCountLabel)
    }
    
    //    override var prefersStatusBarHidden: Bool {
    //        return true
    //    }
    
    // REFRESH
    
    func clearPostIds(){
        self.fetchedPostIds.removeAll()
    }
    
    func clearAllPosts(){
        self.fetchedPostIds.removeAll()
        self.fetchedPosts.removeAll()
        self.refreshPagination()
    }
    
    func clearSort(){
        self.mapFilter?.refreshSort()
    }
    
    func clearCaptionSearch(){
        self.mapFilter?.filterCaption = nil
        self.searchBar.text = nil
        self.refreshPostsForFilter()
    }
    
    func clearFilter(){
        self.mapFilter?.clearFilter()
    }
    
    @objc func clearList(){
        self.mapFilter?.filterList = nil
        self.refreshPostsForFilter()
    }
    
    func refreshPagination(){
        self.isFinishedPaging = false
        self.paginatePostsCount = 0
        self.userPostIdFetched = false
        self.followingPostIdFetched = false
    }
    
    func refreshAll(){
        self.clearCaptionSearch()
        self.clearFilter()
        self.clearSort()
        self.clearPostIds()
        self.refreshPagination()
        self.setupNavigationItems()
        self.fetchAllPostIds()
        //        self.postCollectionView.reloadData()
        //        self.collectionView?.reloadData()
    }
    
    func refreshPosts(){
        self.clearAllPosts()
    }
    
    func refreshPostsForFilter(){
        self.setupNavigationItems()
        self.clearAllPosts()
//        self.postCollectionView.reloadData()
        //        self.postCollectionView.layoutIfNeeded()
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
    
    @objc func refreshWithoutMovingMap(){
        self.refreshAll()
        self.postCollectionView.refreshControl?.endRefreshing()
    }
    
    @objc func handleRefresh() {
        self.refreshAll()
        self.postCollectionView.refreshControl?.endRefreshing()
        print("Refresh Home Feed. FetchPostIds: ", self.fetchedPostIds.count, "FetchedPostCount: ", self.fetchedPosts.count, " DisplayedPost: ", self.paginatePostsCount)
        self.centerMapOnLocation(location: CurrentUser.currentLocation)
    }
    
    
    // MAP
    func setupMap(){
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.mapType = MKMapType.standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.register(MapPinMarkerView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.register(ClusterMapPinMarkerView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)

//        mapView.register(MapPinMarkerView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)

        //        mapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(expandMap)))
    }
    
    
    @objc func passToSelectedPost(){
        
        let pictureController = SinglePostView()
        pictureController.post = self.selectedMapPost
        
        navigationController?.pushViewController(pictureController, animated: true)
    }
    
    @objc func refreshMap(){
        print("Refresh Map")
        
        self.addMapPins()
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        let annotation = view.annotation as! MapPin
        
        let postId = annotation.postId
        let post = fetchedPosts.filter { (post) -> Bool in
            post.id == postId
        }
        
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
    
    @objc func showGlobe(){
        guard let location = CurrentUser.currentLocation else {
            return
        }
        
        print("centerMapOnLocation | \(location.coordinate)")
        let coordinateRegion = MKCoordinateRegion.init(center: location.coordinate,
                                                                  latitudinalMeters: regionRadius*1000, longitudinalMeters: regionRadius*1000)
        //        mapView?.region = coordinateRegion
        mapView.setRegion(coordinateRegion, animated: true)
        
        self.showFullMap()
    }
    
    func centerMapOnLocation(location: CLLocation?, radius: CLLocationDistance? = 0, closestLocation: CLLocation? = nil) {
        guard let location = location else {
            print("centerMapOnLocation | NO LOCATION")
            return}
        print("centerMapOnLocation | Input | \(location.coordinate) | Radius \(radius) | Closest \(closestLocation?.coordinate)")
        
        var displayRadius: CLLocationDistance = radius == 0 ? regionRadius : radius!
        var coordinateRegion: MKCoordinateRegion?
        
        if let closestLocation = closestLocation {
            let closestDisplayRadius = location.distance(from: closestLocation)*2
            print("centerMapOnLocation | Distance Cur Location and Closest Post | \(displayRadius/2)")
            if closestDisplayRadius > 500000 {
                coordinateRegion = MKCoordinateRegion.init(center: (closestLocation.coordinate),latitudinalMeters: displayRadius, longitudinalMeters: displayRadius)
//                mapView.setRegion(coordinateRegion!, animated: true)
                print("centerMapOnLocation | First Post Too Far, Default to first post location")
            } else {
                displayRadius = max(displayRadius, closestDisplayRadius)
                coordinateRegion = MKCoordinateRegion.init(center: (location.coordinate),latitudinalMeters: displayRadius, longitudinalMeters: displayRadius)
            }
        } else {
            coordinateRegion = MKCoordinateRegion.init(center: location.coordinate,latitudinalMeters: displayRadius, longitudinalMeters: displayRadius)
        }

        //        mapView?.region = coordinateRegion
        print("centerMapOnLocation | Result | \(location.coordinate) | Radius \(displayRadius)")
        mapView.setRegion(coordinateRegion!, animated: true)
        
    }
    
    func removeMapPins(){
        for annotation in self.mapView.annotations {
            if (!annotation.isKind(of: MKUserLocation.self)){
                self.mapView.removeAnnotation(annotation)
            }
        }
    }
    
    func addMapPins(){
        print("Adding Map Pins")
        self.mapPins = []
        self.removeMapPins()
        
        if self.fetchedPosts.count == 0 {
            print("Adding Map Pins | No Posts")
            return
        }
        
        var closestPost: Post?

        let tempSortPost = self.fetchedPosts.sorted(by: { (p1, p2) -> Bool in
            return (Double(p1.distance ?? 0)) <= (Double(p2.distance  ?? 0))
        })
        if tempSortPost.count > 0 {
            closestPost = tempSortPost[0]
        }
        
        let filterLocation = self.mapFilter?.filterLocation
        
        // Filtering By Location - Map focuses and drops pin at selected location
        if filterLocation != nil && filterLocation != CurrentUser.currentLocation && self.mapFilter?.filterLocationName != "Current Location" {
            let annotation = MKPointAnnotation()
            let centerCoordinate = CLLocationCoordinate2D(latitude: (filterLocation?.coordinate.latitude)!, longitude:(filterLocation?.coordinate.longitude)!)
            annotation.coordinate = centerCoordinate
            annotation.title = self.mapFilter?.filterLocationName
            mapView.addAnnotation(annotation)
            
//            if let firstPostGPS = closestPost?.locationGPS as CLLocation? {
//                self.centerMapOnLocation(location: filterLocation, radius: 0, closestLocation: firstPostGPS)
//            } else {
//                self.centerMapOnLocation(location: filterLocation)
//            }
            
            print("MainViewController | addMapPins | \(filterLocation)")
            self.centerMapOnLocation(location: filterLocation)

        }
        
    // SHOW CLOSEST POST LOC ON MAP
        else if let firstPostGPS = closestPost?.locationGPS as CLLocation? {
            //            self.selectedMapPost = self.fetchedPosts[0]
//            self.centerMapOnLocation(location: firstPostGPS)
            if let distance = filterLocation?.distance(from: firstPostGPS) {
                if Double(distance) >= (regionRadius * 100) {
                    // Too Far, Map to Post Location
                    print("centerMapOnLocation | First Post Too Far | Center On First Post Location")
                    self.centerMapOnLocation(location: firstPostGPS)
                } else {
                    print("centerMapOnLocation | Between First Post and Cur Location")
                    self.centerMapOnLocation(location: filterLocation, radius: 0, closestLocation: firstPostGPS)
                }
            } else {
                print("centerMapOnLocation | No Distance | Center On First Post Location")
                self.centerMapOnLocation(location: firstPostGPS)
            }

        }
        
        for post in self.fetchedPosts {
            if post.locationGPS != nil && post.id != nil {
                self.mapPins.append(MapPin(post: post))
            }
        }
        mapView.addAnnotations(self.mapPins)
        print("Added Map Pins | Fetched \(self.mapPins.count) | Added \(mapView.annotations.count)")
        

        if appDelegatePostID != nil {
            let selectedAnnotation = self.mapView.annotations.first { (annotationPost) -> Bool in
                if let annotation = annotationPost as? MapPin {
                    return annotation.postId == appDelegatePostID
                } else {
                    return false
                }
                }
            
            
            if let selectedAnnotation = selectedAnnotation
                {
                    self.mapView.selectAnnotation(selectedAnnotation, animated: true)
                    print(" ~ AppDelegatePostID - Manually Selected Map Pin  \(appDelegatePostID)")
                    self.centerMapOnLocation(location: mapFilter?.filterLocation, radius: 1500, closestLocation: nil)
                }
            

            
//            let selectedMapPin = self.mapPins.filter { (mapPin) -> Bool in
//                return mapPin.postId == appDelegatePostID
//                }.first
//
//            if let selectedMapPin = selectedMapPin {
//                self.mapView.selectAnnotation(selectedMapPin, animated: true)
//                print(" ~ AppDelegatePostID - Manually Selected Map Pin  \(selectedMapPin.postId)")
//                self.centerMapOnLocation(location: mapFilter?.filterLocation, radius: 1500, closestLocation: nil)
//            }
            
            appDelegatePostID = nil
        }
        else if let selectedPostId = mapFilter?.filterPostId, selectedPostId == self.selectedMapPost?.id {
            // Manual Select Selected Filter Post ID
            
            let selectedMapPin = self.mapPins.filter { (mapPin) -> Bool in
               return mapPin.postId == selectedPostId
            }.first
            
            if let selectedMapPin = selectedMapPin {
                self.mapView.selectAnnotation(selectedMapPin, animated: true)
                print("  ~ MapFilter : Manully Selected Map Pin  \(selectedPostId)")
            }
        }
        

        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView = MKMarkerAnnotationView()
        guard let annotation = annotation as? MKMarkerAnnotationView else {return nil}

        return annotation
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if let markerView = view as? MapPinMarkerView {
            markerView.markerTintColor = UIColor.ianOrangeColor()
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        //        if !self.mapDisplayed {
        //            print("Show Post Map")
        //            self.showPost()
        //        }
        
        print("  ~ SELECTED | \(view.annotation)")
        
        if let annotation = view.annotation as? MapPin {
            print("Map Pin Selected | \(annotation.postId)")
            annotation.title = annotation.locationName
            
            let tempPost = fetchedPosts.first { (post) -> Bool in
                post.id == annotation.postId
            }
            
            if tempPost != nil {
                self.selectedMapPost = tempPost
                self.showSelectedPost()
            }
            
        } else {
            print("ERROR Casting Annotation to MapPin | \(view.annotation)")
        }
        
        if let markerView = view as? MapPinMarkerView {
            
            markerView.markerTintColor = UIColor.red
            markerView.detailCalloutAccessoryView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(passToSelectedPost)))
            markerView.rightCalloutAccessoryView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(passToSelectedPost)))
            markerView.leftCalloutAccessoryView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(passToSelectedPost)))
            markerView.markerTintColor = UIColor.red
            //            markerView.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(passToSelectedPost)))
            //
            //            markerView.inputAccessoryView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(passToSelectedPost)))
            //            markerView.inputView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(passToSelectedPost)))
            //            markerView.plainView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(passToSelectedPost)))
        }
        
        
        
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
//        print(mapView.getCurrentZoom())

    }
    
    // COLLECTIONVIEW
    func setupCollectionView() {
        postCollectionView.backgroundColor = UIColor.white
        postCollectionView.layer.borderColor = UIColor.lightGray.cgColor
        
        // Adding Empty Data Set
        postCollectionView.emptyDataSetSource = self
        postCollectionView.emptyDataSetDelegate = self
        postCollectionView.emptyDataSetView { (emptyview) in
            emptyview.isUserInteractionEnabled = false
        }
        postCollectionView.register(NewListPhotoCell.self, forCellWithReuseIdentifier: cellId)
        postCollectionView.register(GridPhotoCell.self, forCellWithReuseIdentifier: gridCellId)
        postCollectionView.register(MainListViewViewHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: listHeaderId)
        
        let layout = FixedHeadersCollectionViewFlowLayout()
        postCollectionView.collectionViewLayout = layout
        postCollectionView.allowsSelection = true
        postCollectionView.allowsMultipleSelection = false
        postCollectionView.isPagingEnabled = true
        
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
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        //        var height: CGFloat = 50 //headerview = username userprofileimageview
        //        height += view.frame.width  // Picture
        //        height += 40 + 5    // Action Bar
        //        height += 25        // Location View
        //        height += 25 + 5    // Extra Tag Bar
        //        height += 10    // Caption Bar
        //        height += 20    // Date Bar
        //
        //
        //        ////        height += 20    // Social Counts
        //        ////        height += 20    // Caption
        //
        //        return CGSize(width: view.frame.width, height: height)
        
        if isListView {
            return CGSize(width: view.frame.width, height: postHeight)
        } else {
            let width = (view.frame.width - 4) / 3
            return CGSize(width: width, height: width)
        }
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return paginatePostsCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.item == self.paginatePostsCount - 1 && !isFinishedPaging{
            print("CollectionView Paginate")
            paginatePosts()
        }
        
        var displayPost = fetchedPosts[indexPath.item]
        
        if isListView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! NewListPhotoCell
            cell.bookmarkDate = displayPost.creationDate
            cell.post = displayPost
            // Can't Be Selected
            
            // Only show selected in full list view
            if displayPost.id == self.selectedMapPost?.id && (self.fullListViewConstraint?.isActive)! {
                cell.isSelected = true
            } else {
                cell.isSelected = false
            }
            
            cell.backgroundColor = UIColor.white.withAlphaComponent(0.8)
//            cell.backgroundColor = UIColor(white: 0, alpha: 0.1)
//            cell.backgroundColor = UIColor.white.withAlphaComponent(0.5)

            
            if self.mapFilter?.filterLocation != nil && cell.post?.locationGPS != nil {
                cell.post?.distance = Double((cell.post?.locationGPS?.distance(from: (self.mapFilter?.filterLocation!)!))!)
            }
            
            cell.delegate = self
            // Disable Selection to enable any tap to select cell
            cell.allowSelect = false
            
            // Only show cell cancel button when showing post view
            cell.showCancelButton = (self.postViewHeightConstraint?.isActive)!
            cell.currentImage = 1
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: gridCellId, for: indexPath) as! GridPhotoCell
            cell.delegate = self
            cell.post = displayPost
            return cell
        }
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        
        let tempPost = fetchedPosts[indexPath.item]
        self.selectedMapPost = tempPost
        let selectedAnnotation = self.mapView.annotations.first { (annotationPost) -> Bool in
            if let annotation = annotationPost as? MapPin {
                return annotation.postId == tempPost.id
            } else {
                return false
            }
        }
        
        print("CollectionView Selected | \(selectedAnnotation?.title) | \(self.selectedMapPost?.locationName) | \(self.selectedMapPost?.locationGPS?.coordinate)")
//        self.centerMapOnLocation(location: self.selectedMapPost?.locationGPS)
        self.mapView.selectAnnotation(selectedAnnotation!, animated: true)
        self.centerMapOnLocation(location: self.selectedMapPost?.locationGPS, radius: 1500, closestLocation: nil)
        
//        self.showSelectedPost()
        
//        if tempPost.id == self.selectedMapPost?.id || (self.postViewHeightConstraint?.isActive)! {
//            print("Cell Selected | Open PictureController | \(self.selectedMapPost?.id)")
//            self.didTapPicture(post: tempPost)
//        } else {
//            self.mapView.selectAnnotation(selectedAnnotation!, animated: true)
//            self.centerMapOnLocation(location: self.selectedMapPost?.locationGPS)
//        }
        
        
        //        self.postCollectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
        //        self.showPostMap()
        
    }
    
    
    //     HEADER LAYOUT DELEGATE
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: listHeaderId, for: indexPath) as! MainListViewViewHeader

        header.selectedSort = (self.mapFilter?.filterSort)!
        header.isListView = self.isListView
        header.delegate = self
        header.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        return header

    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        var height = headerHeight // Header Sort with 5 Spacing
        //        height += 40 // Search bar View
        if (self.fullListViewConstraint?.isActive)! {
            return CGSize(width: view.frame.width, height: headerHeight)
        } else {
            return CGSize(width: view.frame.width, height: 0)
        }

    }
    
    
    // EMPTY DATA SET DELEGATES
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        // Don't display empty dataset if still loading
        if !SVProgressHUD.isVisible()
        {
            return true
        } else {
            return false
        }
    }
    
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        if (self.mapFilter?.isFiltering)! {
            text = "There's Nothing Here?!"
        } else {
            let number = arc4random_uniform(UInt32(tipDefaults.count))
            text = tipDefaults[Int(number)]
        }
        text = ""
        font = UIFont.boldSystemFont(ofSize: 17.0)
        textColor = UIColor(hexColor: "25282b")
        
        if text == nil {
            return nil
        }
        
        return NSMutableAttributedString(string: text!, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): font, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): textColor]))
        
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        text = nil
        
        font = UIFont(name: "Poppins-Regular", size: 15)
        textColor = UIColor.ianBlackColor()
        
        if (self.mapFilter?.isFiltering)! {
            text = "Nothing Legit Here! 😭"
        } else {
            text = ""
        }
        
        if text == nil {
            return nil
        }
        
        return NSMutableAttributedString(string: text!, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): font, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): textColor]))
        
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
//        return #imageLiteral(resourceName: "amaze").resizeVI(newSize: CGSize(width: view.frame.width/2, height: view.frame.height/2))
         return #imageLiteral(resourceName: "Legit_Vector")
    }
    
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        if (self.mapFilter?.isFiltering)! {
            text = "Tap To Refresh"
        } else {
            text = "Search For Users"
        }
        text = ""
        font = UIFont.boldSystemFont(ofSize: 18.0)
        textColor = UIColor.legitColor()
        
        if text == nil {
            return nil
        }
        
        return NSMutableAttributedString(string: text!, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): font, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): textColor]))
        
    }
    
    
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
        return UIColor.backgroundGrayColor()
        //        80cbc4
        
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {
        if (self.mapFilter?.isFiltering)! {
            //            self.randomSearch()
            self.handleRefresh()
            
        } else {
            self.openSearch(index: 1)
        }
    }
    
    var noCaptionFilterEmojiCounts: [String:Int] = [:]
    var noCaptionFilterLocationCounts: [String:Int] = [:]
    
    func extractCreatorUids(posts: [Post]) -> ([String]){
        var tempIds: [String] = []
        for post in posts {
            if let id = post.creatorUID {
                if !tempIds.contains(id) {
                    tempIds.append(id)
                }
            }
        }
        
        return tempIds
    }
    
    func openSearch(index: Int?){
        
        let postSearch = MainSearchController()
        postSearch.delegate = self
        
        
    // Option Counts for Current Filter

        Database.countEmojis(posts: self.fetchedPosts) { (emojiCounts) in
            postSearch.emojiCounts = emojiCounts
        }
        Database.countCityIds(posts: self.fetchedPosts) { (locationCounts) in
            postSearch.locationCounts = locationCounts
        }
        
        postSearch.defaultEmojiCounts = self.noCaptionFilterEmojiCounts
        postSearch.defaultLocationCounts = self.noCaptionFilterLocationCounts
        
        postSearch.searchFilter = self.mapFilter
        postSearch.setupInitialSelections()
        
        postSearch.postCreatorIds = self.extractCreatorUids(posts: self.fetchedPosts)
        
        self.navigationController?.pushViewController(postSearch, animated: true)
        if index != nil {
            postSearch.selectedScope = index!
            postSearch.searchController.searchBar.selectedScopeButtonIndex = index!
        }
        
    }
    
    //
    //    // Option Counts for Current Filter
    //
    //        Database.countEmojis(posts: self.fetchedPosts) { (emojiCounts) in
    //            postSearch.emojiCounts = emojiCounts
    //        }
    //        Database.countLocationIds(posts: self.fetchedPosts) { (locationCounts) in
    //            postSearch.locationCounts = locationCounts
    //        }
    //
    //    // Option Counts Assuming No Caption/Location Filter - Only if is filtering
    //        if (mapFilter?.isFiltering)!{
    //            var noCaptionLocationFilter = Filter.init()
    //            noCaptionLocationFilter.filterUser = self.mapFilter?.filterUser
    //            noCaptionLocationFilter.filterList = self.mapFilter?.filterList
    //
    //            // Fetches All Posts, Refilters assuming no caption filtered, recount emoji/location
    //            Database.fetchAllPosts(fetchedPostIds: self.fetchedPostIds){fetchedPostsFirebase in
    //                Database.filterPostsNew(inputPosts: fetchedPostsFirebase, postFilter: noCaptionLocationFilter) { (filteredPosts) in
    //                    Database.countEmojis(posts: filteredPosts!) { (emojiCounts) in
    //                        postSearch.defaultEmojiCounts = emojiCounts
    //                    }
    //                    Database.countLocationIds(posts: filteredPosts!) { (locationCounts) in
    //                        postSearch.defaultLocationCounts = locationCounts
    //                    }
    //                }
    //            }
    //        } else {
    //            postSearch.defaultEmojiCounts = postSearch.emojiCounts
    //            postSearch.defaultLocationCounts = postSearch.locationCounts
    //        }

    
    func randomSearch(){
        self.clearFilter()
        self.mapFilter?.filterLocation = CurrentUser.currentLocation
        self.mapFilter?.filterRange = geoFilterRangeDefault[4]
        print("Random Search: ",self.mapFilter?.filterRange)
        self.refreshPostsForFilter()
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapView view: UIView) {
        self.handleRefresh()
    }
    
    //    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
    //        let offset = (self.collectionView?.frame.height)! / 5
    //            return -50
    //    }
    
    func spaceHeight(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return 9
    }
    
    // FETCHING POSTS
    fileprivate func fetchAllPostIds(){
        SVProgressHUD.show(withStatus: "Loading Posts")
        Database.fetchCurrentUserAllPostIds { (postIds) in
            print("   ~ Database | Fetched PostIds | \(postIds.count)")
            self.fetchedPostIds = postIds
            NotificationCenter.default.post(name: MainViewController.finishFetchingUserPostIdsNotificationName, object: nil)
        }
    }
    
    @objc func finishFetchingPostIds(){
        self.fetchAllPosts()
    }
    
    var isFetching = false
    
    func fetchAllPosts(){
        if isFetching {
            print(" ~ BUSY FETCHING POSTS")
        } else {
            isFetching = true
        }
        
        print("MainView | Fetching All Post, Current Location: ", CurrentUser.currentLocation?.coordinate)
        Database.fetchAllPosts(fetchedPostIds: self.fetchedPostIds){fetchedPostsFirebase in

            self.fetchedPosts = fetchedPostsFirebase

            // Remove all post without GPS Location
            for post in self.fetchedPosts {
                if post.locationGPS == nil || (post.locationGPS?.coordinate.latitude == 0 && post.locationGPS?.coordinate.longitude == 0) {
                    if let index = self.fetchedPosts.firstIndex(where: { (curpost) -> Bool in
                        return curpost.id == post.id
                    }){
                        self.fetchedPosts.remove(at: index)
                    }
                }
            }
            
            self.filterSortFetchedPosts()
            
            guard let uid = Auth.auth().currentUser?.uid else {
                print("Count Most Used Emoji: Error, No uid")
                return
            }
            
            if CurrentUser.mostUsedEmojis.count == 0 {
                self.countMostUsedEmojis(posts: fetchedPostsFirebase.filter({ (post) -> Bool in
                    post.creatorUID == uid
                }))
            }
            
            if CurrentUser.mostTaggedLocations.count == 0 {
                self.countMostTaggedPostLocations(posts: self.fetchedPosts)
            }
        }
    }
    
    func countMostUsedEmojis(posts: [Post]) {
        Database.countMostUsedEmojis(posts: posts) { (emojis) in
            
            CurrentUser.mostUsedEmojis = emojis
            print("Updated Current User Most Used Emojis | \(CurrentUser.mostUsedEmojis.count)")

            // Check for Top 5 Emojis
            if emojis.count > 0 {
                let top5Emoji = Array(emojis.prefix(5))
                let dif = top5Emoji.difference(from: (CurrentUser.user?.topEmojis)!)
                
                if dif.count > 0 {
                    Database.checkTop5Emojis(userId: CurrentUser.uid!, emojis: top5Emoji)
                }
            }
            
        }
    }
    
    func countMostTaggedPostLocations(posts: [Post]){
        Database.countCityIds(posts: posts) { (locationCounts) in
            var temp_locations: [String] = []
            for (key,value) in locationCounts {
                temp_locations.append(key)
            }
            CurrentUser.mostTaggedLocations = temp_locations
            print("Updated Current User Most Tagged Locations | \(CurrentUser.mostTaggedLocations.count)")
        }
    }
    
    
    
    func listSelected(list: List?) {
        print("Selected | \(list?.name)")
        self.mapFilter?.filterList = list
        self.mapFilter?.filterCaption = nil
        self.showFullMap()
        self.refreshPostsForFilter()
    }
    
    func userListSelected(user: User?) {
        print("Selected | \(user?.username)")
        self.mapFilter?.filterUser = user
        self.mapFilter?.filterList = nil
        self.refreshPostsForFilter()
    }
    
    
    func filterSortFetchedPosts(){
    
        // Fetches All Posts, Refilters assuming no caption filtered, recount emoji/location
        var noCaptionLocationFilter = Filter.init()
        noCaptionLocationFilter.filterUser = self.mapFilter?.filterUser
        noCaptionLocationFilter.filterList = self.mapFilter?.filterList
        
        Database.filterPostsNew(inputPosts: self.fetchedPosts, postFilter: noCaptionLocationFilter) { (filteredPosts) in
            Database.countEmojis(posts: filteredPosts) { (emojiCounts) in
                self.noCaptionFilterEmojiCounts = emojiCounts
            }
            
            Database.countCityIds(posts: filteredPosts) { (locationCounts) in
                self.noCaptionFilterLocationCounts = locationCounts
            }
        }
        
        
        // Filter Posts
        Database.filterPostsNew(inputPosts: self.fetchedPosts, postFilter: self.mapFilter) { (filteredPosts) in
            // Sort Posts
            
            if self.mapFilter?.filterSort == defaultNearestSort {
                if self.mapFilter?.filterLocation == nil {
                    self.mapFilter?.filterLocation = CurrentUser.currentLocation
                }
                
                if self.mapFilter?.filterLocation == nil {
                    self.alert(title: "Error Sort By Nearest", message: "No Location to sort by nearest. Will sort by date instead")
                    self.mapFilter?.filterSort = defaultRecentSort
                }
            }
            
            Database.sortPosts(inputPosts: filteredPosts, selectedSort: self.mapFilter?.filterSort, selectedLocation: self.mapFilter?.filterLocation, completion: { (filteredPosts) in
                
                self.fetchedPosts = []
                if filteredPosts != nil {
                    self.fetchedPosts = filteredPosts!
                }
                
                if (self.mapFilter?.isFiltering)! {
                    if let filterPostId = self.mapFilter?.filterPostId {
                        self.selectedMapPost = self.fetchedPosts.filter({ (post) -> Bool in
                            post.id == filterPostId
                        }).first
                        self.showPost()
                    }
                    
                    else if self.fetchedPosts.count > 0 {
                        print("Filter Sort | Is Filtering | Auto selected post | \(self.selectedMapPost?.id)")
                        self.selectedMapPost = self.fetchedPosts[0]
                        self.showPost()
                        
//                        if self.mapFilter?.filterSort == defaultNearestSort {
//                            if let closestLocation = self.fetchedPosts[0].locationGPS{
//                                self.centerMapOnLocation(location: self.mapFilter?.filterLocation, closestLocation: closestLocation)
//                            }
//                        }
                        
                    } else if self.fetchedPosts.count == 0 {
                        print("Filter Sort | Is Filtering | No Post")
                        self.showFullMap()
                    }
                }
                
                self.isFetching = false
                print("Filter Sorted Post: \(self.fetchedPosts.count) || Selected | \(self.selectedMapPost?.id) ")
                NotificationCenter.default.post(name: MainViewController.finishSortingFetchedPostsNotificationName, object: nil)

            })
        }
        
        
        //        // Filter Posts
        //        Database.filterPosts(inputPosts: self.fetchedPosts, filterCaption: self.filterCaption, filterRange: self.filterRange, filterLocation: self.filterLocation, filterGoogleLocationID: filterGoogleLocationID, filterMinRating: self.filterMinRating, filterType: self.filterType, filterMaxPrice: self.filterMaxPrice, filterLegit: self.filterLegit, filterList: filterList, filterUser: filterUser) { (filteredPosts) in
        //
        //            // Sort Posts
        //            Database.sortPosts(inputPosts: filteredPosts, selectedSort: self.selectedHeaderSort, selectedLocation: self.filterLocation, completion: { (filteredPosts) in
        //
        //                self.fetchedPosts = []
        //                if filteredPosts != nil {
        //                    self.fetchedPosts = filteredPosts!
        //                }
        //                print("Filter Sorted Post: \(self.fetchedPosts.count)")
        //                NotificationCenter.default.post(name: MainViewController.finishSortingFetchedPostsNotificationName, object: nil)
        //            })
        //        }
    }
    
    func filterControllerSelected(filter: Filter?) {
        self.mapFilter = filter
        self.refreshPostsForFilter()
    }
    
    func filterControllerFinished(selectedCaption: String?, selectedRange: String?, selectedLocation: CLLocation?, selectedLocationName: String?, selectedGooglePlaceId: String?, selectedGooglePlaceType: [String]?, selectedMinRating: Double, selectedType: String?, selectedMaxPrice: String?, selectedSort: String, selectedLegit: Bool){
        
        // Clears all Filters, Puts in new Filters, Refreshes all Post IDS and Posts
        //        self.clearFilter()
        //
        //        self.filterCaption = selectedCaption
        //        self.filterRange = selectedRange
        //        self.filterLocation = selectedLocation
        //        self.filterLocationName = selectedLocationName
        //        self.filterGoogleLocationID = selectedGooglePlaceId
        //
        //        self.filterMinRating = selectedMinRating
        //        self.filterType = selectedType
        //        self.filterMaxPrice = selectedMaxPrice
        //        self.filterLegit = selectedLegit
        //
        //        self.selectedHeaderSort = selectedSort
        //
        //        // Check for filtering
        //        self.checkFilter()
        //        self.refreshPostsForFilter()
    }
    
    func checkFilter(){
        //        if self.filterCaption != nil || (self.filterRange != nil) || (self.filterRange == nil && self.filterGoogleLocationID != nil) || (self.filterMinRating != 0) || (self.filterType != nil) || (self.filterMaxPrice != nil) || (self.filterLegit == true) ||  (self.filterUser != nil) || (self.filterList != nil){
        //            self.isFiltering = true
        //        } else {
        //            self.isFiltering = false
        //        }
    }
    
    // PAGINATION
    
    @objc func paginatePosts(){
        let paginateFetchPostSize = 4
        self.paginatePostsCount = min(self.paginatePostsCount + paginateFetchPostSize, self.fetchedPosts.count)
        print("Map Paginate \(self.paginatePostsCount) : \(self.fetchedPosts.count)")
        NotificationCenter.default.post(name: MainViewController.finishPaginationNotificationName, object: nil)
    }
    
    
    @objc func finishPaginationCheck(){
        self.isFinishedPaging = false
        
        if self.paginatePostsCount == (self.fetchedPosts.count) {
            self.isFinishedPaging = true
            print("Pagination: Finish Paging, Paging: \(self.isFinishedPaging)")
            let when = DispatchTime.now() + 2 // change 2 to desired number of seconds
            DispatchQueue.main.asyncAfter(deadline: when) {
                //Delay for 3 second to dismiss loading button if 0 fetched posts
                SVProgressHUD.dismiss()
            }
        }
        
        if self.fetchedPosts.count == 0 && self.isFinishedPaging == true {
            print("Pagination: No Results, Paging: \(self.isFinishedPaging)")
            
        }
        else if self.fetchedPosts.count == 0 && self.isFinishedPaging != true {
            print("Pagination: No Results, Paging: \(self.isFinishedPaging)")
            self.paginatePosts()
        } else {
            print("Pagination: Success, Post: \(self.fetchedPosts.count)")
            DispatchQueue.main.async(execute: {

                self.postCollectionView.reloadData()
                SVProgressHUD.dismiss()

                // Scrolling for refreshed results
                if self.scrolltoFirst && self.fetchedPosts.count > 1{
                    print("Refresh Control Status: ", self.postCollectionView.refreshControl?.state)
                    self.postCollectionView.refreshControl?.endRefreshing()
                    let indexPath = IndexPath(item: 0, section: 0)
                    self.postCollectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
                    //                    self.collectionView?.setContentOffset(CGPoint(x: 0, y: 0 - self.topLayoutGuide.length), animated: true)
                    print("Scrolled to Top")
                    self.scrolltoFirst = false
                }
            })
        }
    }
    
    // FULL POST CELL DELEGATES
    
    func didTapBookmark(post: Post) {
        let sharePhotoListController = SharePhotoListController()
        sharePhotoListController.uploadPost = post
        sharePhotoListController.isBookmarkingPost = true
        sharePhotoListController.delegate = self
        navigationController?.pushViewController(sharePhotoListController, animated: true)
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
    
    func didTapUserUid(uid: String) {
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = uid
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapListCancel(post: Post) {
        self.showFullMap()
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
    
    func userOptionPost(post: Post) {
        let optionsAlert = UIAlertController(title: "User Options", message: "", preferredStyle: UIAlertController.Style.alert)
        
        optionsAlert.addAction(UIAlertAction(title: "Edit Post", style: .default, handler: { (action: UIAlertAction!) in
            // Allow Editing
            self.editPost(post: post)
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Delete Post", style: .default, handler: { (action: UIAlertAction!) in
            self.deletePost(post: post)
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        present(optionsAlert, animated: true) {
            optionsAlert.view.superview?.isUserInteractionEnabled = true
            optionsAlert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.alertClose(gesture:))))
        }
    }
    
    func editPost(post:Post){
        let editPost = MultSharePhotoController()
        
        // Post Edit Inputs
        editPost.editPostInd = true
        editPost.editPost = post
        
        self.navigationController?.pushViewController(editPost, animated: true)
        
        //        let navController = UINavigationController(rootViewController: editPost)
        //        self.present(navController, animated: false, completion: nil)
    }
    
    
    func deletePost(post:Post){
        
        let deleteAlert = UIAlertController(title: "Delete", message: "Are You Sure? All Data Will Be Lost!", preferredStyle: UIAlertController.Style.alert)
        deleteAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            
            // Remove from Current View
            let index = self.fetchedPosts.firstIndex { (filteredpost) -> Bool in
                filteredpost.id  == post.id
            }
            
            let deleteindexpath = IndexPath(row:index!, section: 0)
            self.fetchedPosts.remove(at: index!)
            print("Remove Fetched Post at \(index)")
            self.paginatePostsCount += -1
            self.postCollectionView.deleteItems(at: [deleteindexpath])
            print("deletePost| Deleted \(post.id) From Current View | \(deleteindexpath)")
            Database.deletePost(post: post)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        present(deleteAlert, animated: true, completion: nil)
        
    }
    
    func displaySelectedEmoji(emoji: String, emojitag: String) {
        
    }
    
    func didTapExtraTag(tagName: String, tagId: String, post: Post) {
        
        // Check to see if its a list, price or something else
        if tagId == "price"{
            // Price Tag Selected
            print("Price Selected")
            self.mapFilter?.filterMaxPrice = tagName
            self.refreshPostsForFilter()
        }
        else if tagId == "creatorLists"{
            // Additional Tags
            let listController  = ListController()
            listController.displayedPost = post
            listController.displayedListNameDictionary = post.creatorListId
            self.navigationController?.pushViewController(listController, animated: true)
        }
        else if tagId == "userLists"{
            // Additional Tags
            let listController  = ListController()
            listController.displayedPost = post
            listController.displayedListNameDictionary = post.selectedListId
            self.navigationController?.pushViewController(listController, animated: true)
        }
        else {
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
    }
    
    func displayPostSocialUsers(post:Post, following: Bool){
        print("Display Vote Users| Following: ",following)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayUser = true
        postSocialController.displayUserFollowing = following
        postSocialController.inputPost = post

        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    func displayPostSocialLists(post:Post, following: Bool){
        print("Display Lists| Following: ",following)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayList = true
        postSocialController.displayFollowing = following
        postSocialController.inputPost = post

        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    
    // HEADER DELEGATES
    
    func didChangeToListView() {
        
    }
    
    func didChangeToPostView() {
        
    }
    
    @objc func openFilter() {
        let filterController = SearchFilterController()
        filterController.delegate = self
        filterController.searchFilter = self.mapFilter
        self.navigationController?.pushViewController(filterController, animated: true)
    }
    
    func headerSortSelected(sort: String) {
        self.enableScroll = false
        self.mapFilter?.filterSort = sort
        self.postCollectionView.reloadData()
        
        if (self.mapFilter?.filterSort == HeaderSortOptions[1] && self.mapFilter?.filterLocation == nil){
            print("Sort by Nearest, No Location, Look up Current Location")
            LocationSingleton.sharedInstance.determineCurrentLocation()
            let when = DispatchTime.now() + defaultGeoWaitTime // change 2 to desired number of seconds
            DispatchQueue.main.asyncAfter(deadline: when) {
                //Delay for 1 second to find current location
                self.mapFilter?.filterLocation = CurrentUser.currentLocation
                self.refreshPostsForFilter()
            }
        } else {
            self.refreshPostsForFilter()
        }
        
        self.enableScroll = true
        print("Filter Sort is ", self.mapFilter?.filterSort)
    }
    
    func deletePostFromList(post: Post) {
    }
    
    func didTapPicture(post: Post) {
        let pictureController = SinglePostView()
        pictureController.post = post
        navigationController?.pushViewController(pictureController, animated: true)
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //////////////////// PHOTOS
    
    // IMAGE PICKER /////////////////
    
    // Final Variables
    var selectedImagesMult: [UIImage]? = []
    var selectedTime: Date? = nil
    var selectedPhotoLocation: CLLocation? = nil
    
    var imagePicker = UIImagePickerController()
    
    var assets = [PHAsset]()
    var selectedAssets = [TLPHAsset]()
    
    func addPhoto(){
        let viewController = CustomPhotoPickerViewController()
        viewController.delegate = self
        viewController.didExceedMaximumNumberOfSelection = { [weak self] (picker) in
            self?.showExceededMaximumAlert(vc: picker)
        }
        var configure = TLPhotosPickerConfigure()
        configure.numberOfColumn = 3
        configure.maxSelectedAssets = 5
        viewController.configure = configure
        viewController.selectedAssets = self.selectedAssets
        
        self.present(viewController, animated: true, completion: nil)
    }
    
    
    func dismissPhotoPicker(withPHAssets: [PHAsset]) {
        // if you want to used phasset.
        
        self.processPHAssets(assets: withPHAssets) { (images, location, date) in
            self.selectedImagesMult = images
            self.selectedPhotoLocation = location
            self.selectedTime = date
        }
    }
    
    func dismissComplete() {
        
        if (self.selectedImagesMult?.count)! > 0 {
            self.passPhotos()
            //            self.openPhotoViewer()
        } else {
            print("No Picture Selected")
            self.alert(title: "Error", message: "No Pictures Selected")
        }
    }
    
    
    
    func photoPickerDidCancel() {
        print("Photo Picking Cancel")
    }
    
    // PHOTO VIEWER MULTIPLE /////////////////
    var editIndex: Int? = nil
    var browser = SKPhotoBrowser()
    
    func openPhotoViewer(){
        var images = [SKPhoto]()
        
        guard let selectedImages = self.selectedImagesMult else {return}
        for image in selectedImages {
            let photo = SKPhoto.photoWithImage(image)// add some UIImage
            images.append(photo)
        }
        
        // 2. create PhotoBrowser Instance, and present from your viewController.
        SKPhotoBrowserOptions.displayCounterLabel = true
        SKPhotoBrowserOptions.displayBackAndForwardButton = true
        SKPhotoBrowserOptions.displayAction = true
        SKPhotoBrowserOptions.actionButtonTitles = ["Edit Photo"]
        SKPhotoBrowserOptions.swapCloseAndDeleteButtons = true
        //        SKPhotoBrowserOptions.enableSingleTapDismiss  = true
        SKPhotoBrowserOptions.bounceAnimation = true
        SKPhotoBrowserOptions.displayDeleteButton = true
        
        browser = SKPhotoBrowser(photos: images)
        browser.delegate = self
        browser.updateCloseButton(#imageLiteral(resourceName: "checkmark_teal").withRenderingMode(.alwaysOriginal), size: CGSize(width: 50, height: 50))
        
        browser.initializePageIndex(0)
        present(browser, animated: true, completion: {})
    }
    
    
    
    // PHOTO VIEWER DELEGATES
    
    func didDismissActionSheetWithButtonIndex(_ buttonIndex: Int, photoIndex: Int) {
        
        // EDIT ACTION BUTTON
        
        self.editIndex = photoIndex
        print("EDIT INDEX | \(self.editIndex) | \(photoIndex)")
        
        let cropViewController = CropViewController(image: self.selectedImagesMult![self.editIndex!])
        cropViewController.delegate = self
        self.presentedViewController?.present(cropViewController, animated: true) {
        }
    }
    
    func didDismissAtPageIndex(_ index: Int) {
        self.passPhotos()
    }
    
    func removePhoto(_ browser: SKPhotoBrowser, index: Int, reload: @escaping (() -> Void)) {
        self.selectedImagesMult!.remove(at: index)
        
        if self.selectedImagesMult?.count == 0 {
            print("No Pictures")
            self.dismiss(animated: true) {
            }
        } else {
            browser.gotoPreviousPage()
            reload()
        }
    }
    
    
    // CROP VIEW CONTROLLER DELEGATE
    
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        
        print("Cropped/Edited Picture |\(self.editIndex)")
        
        guard let _ = self.editIndex else {return}
        self.selectedImagesMult![self.editIndex!] = image
        browser.photos[self.editIndex!] = SKPhoto.photoWithImage(image)
        //        self.browser.photoAtIndex(self.editIndex) = image
        
        self.presentedViewController?.dismiss(animated: true, completion: {
            self.editIndex = nil
            self.browser.reloadData()
        })
        
        //        self.dismiss(animated: true) {
        //            self.editIndex = nil
        //            self.browser.reloadData()
        //        }
    }
    
    func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
        print("Cancel")
        self.presentedViewController?.dismiss(animated: true, completion: {
            //            self.editIndex = nil
            //            self.browser.reloadData()
        })
    }
    
    func passPhotos(){
        print("Final Upload. Pictures: \(self.selectedImagesMult!.count), Location: \(self.selectedPhotoLocation), Time: \(self.selectedTime)")
        
        let multSharePhotoController = MultSharePhotoController()
        multSharePhotoController.selectedImages = self.selectedImagesMult
        multSharePhotoController.selectedImageLocation  = self.selectedPhotoLocation
        multSharePhotoController.selectedImageTime  = self.selectedTime
        let navController = UINavigationController(rootViewController: multSharePhotoController)
        self.present(navController, animated: false, completion: nil)
        self.refreshPhotoVariables()
    }
    
    
    
    func didExceedMaximumNumberOfSelection(picker: TLPhotosPickerViewController) {
        self.showExceededMaximumAlert(vc: picker)
    }
    
    func handleNoCameraPermissions(picker: TLPhotosPickerViewController) {
        let alert = UIAlertController(title: "", message: "No camera permissions granted", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showExceededMaximumAlert(vc: UIViewController) {
        let alert = UIAlertController(title: "", message: "Exceed Maximum Number Of Selection", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        vc.present(alert, animated: true, completion: nil)
    }
    
    func refreshPhotoVariables(){
        self.selectedImagesMult = []
        self.selectedPhotoLocation = nil
        self.selectedTime = nil
    }
    
    func getAssetThumbnail(asset: PHAsset) -> UIImage {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        option.resizeMode = .exact
        option.deliveryMode = .highQualityFormat;
        option.isNetworkAccessAllowed = true;
        option.progressHandler = { (progress, error, stop, info) in
            if(progress == 1.0){
                SVProgressHUD.dismiss()
            } else {
                SVProgressHUD.showProgress(Float(progress), status: "Downloading from iCloud")
            }
        }
        var thumbnail = UIImage()
        option.isSynchronous = true
        manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
            thumbnail = result!
        })
        return thumbnail
        
    }
    
    func processPHAssets(assets: [PHAsset], completion: @escaping ([UIImage]?, CLLocation?, Date?) -> ()){
        
        // use selected order, fullresolution image
        print("Processing \(assets.count) PHAssets")
        
        var assetlocations: [CLLocation?] = []
        var assetTimes:[Date?] = []
        
        var tempImages: [UIImage]? = []
        var tempLocation: CLLocation? = nil
        var tempDate: Date? = nil
        
        for asset in assets {
            tempImages?.append(self.getAssetThumbnail(asset: asset))
            assetlocations.append(asset.location)
            assetTimes.append(asset.creationDate)
            
            var image = self.getAssetThumbnail(asset: asset)
            
        }
        
        for location in assetlocations {
            if tempLocation == nil {
                if location != nil {
                    tempLocation = location
                }
            }
        }
        
        for time in assetTimes {
            if tempDate == nil {
                if time != nil {
                    tempDate = time
                }
            }
        }
        
        print("Images: \(tempImages?.count), Locations: \(assetlocations.count), Times: \(assetTimes) ")
        print("Final Location: \(tempLocation), Final Time: \(tempDate)")
        
        completion(tempImages, tempLocation, tempDate)
        
        // print("Selected Photo Time \(self.selectedTime), Location: \(self.selectedPhotoLocation)")
        
    }
    
    
    
    
    /*
     // MARK: - Navigation
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}

//        let tapCancelView = UIView()
//        tapCancelView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissPicker)))
//        view.addSubview(tapCancelView)
//        tapCancelView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor , right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        tapCancelView.isHidden = true

//        view.addSubview(formatButton)
//        formatButton.anchor(top: trackingButton.topAnchor, left: trackingButton.leftAnchor, bottom: trackingButton.bottomAnchor, right: trackingButton.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        formatButton.isHidden = true

//        view.addSubview(trackingButton)
//        trackingButton.anchor(top: nil, left: nil, bottom: nil, right: actionBarView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 20, width: 30, height: 30)
//        trackingButton.centerYAnchor.constraint(equalTo: actionBarView.centerYAnchor).isActive = true
//        formatButton.isHidden = false
//
//        view.addSubview(formatButton)
//        formatButton.anchor(top: trackingButton.topAnchor, left: trackingButton.leftAnchor, bottom: trackingButton.bottomAnchor, right: trackingButton.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        formatButton.isHidden = true
//        formatButton.layer.cornerRadius = 30/2
//
//        view.addSubview(mapButton)
//        mapButton.anchor(top: nil, left: nil, bottom: nil, right: trackingButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 30, width: 35, height: 35)
//        mapButton.centerYAnchor.constraint(equalTo: actionBarView.centerYAnchor).isActive = true
//        mapButton.layer.cornerRadius = 35/2
//        mapButton.clipsToBounds = true



//        view.addSubview(timeFilterButton)
//        timeFilterButton.anchor(top: nil, left: actionBarView.leftAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
//        timeFilterButton.centerYAnchor.constraint(equalTo: actionBarView.centerYAnchor).isActive = true
//        timeFilterButton.layer.cornerRadius = 10
//        timeFilterButton.clipsToBounds = true
//
//        let middleView = UIView()
//        view.addSubview(middleView)
//        middleView.anchor(top: nil, left: timeFilterButton.rightAnchor, bottom: nil, right: addPhotoButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//
//        view.addSubview(filterLegitButton)
//        filterLegitButton.anchor(top: actionBarView.topAnchor, left: nil, bottom: actionBarView.bottomAnchor, right: nil, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 0, height: 0)
//        filterLegitButton.widthAnchor.constraint(equalTo: filterLegitButton.heightAnchor, multiplier: 1).isActive = true
//
//        //        filterLegitButton.centerYAnchor.constraint(equalTo: actionBarView.centerYAnchor).isActive = true
//        filterLegitButton.centerXAnchor.constraint(equalTo: middleView.centerXAnchor).isActive = true
//        filterLegitButton.layer.cornerRadius = filterLegitButton.frame.width/2
//        filterLegitButton.clipsToBounds = true









//        view.addSubview(listButton)
//        listButton.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 25, paddingLeft: 5, paddingBottom: 0, paddingRight: 15, width: 30, height: 30)
//
//        view.addSubview(userButton)
//        userButton.anchor(top: view.topAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 25, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 30, height: 30)


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
