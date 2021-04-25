//
//  NewListCollectionView.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 7/20/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

import CoreLocation
import EmptyDataSet_Swift
import DropDown
import CoreGraphics
import SVProgressHUD
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import SKPhotoBrowser

//protocol NewListCollectionViewDelegate {
//    func listSelected(list: List?)
//    func deleteList(list:List?)
//}


class ListOptionPhotoPicker: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate, TestGridPhotoCellDelegate, TestGridPhotoCellDelegateObjc {


    let gridCellId = "gridCellId"
    let listCellId = "listCellId"
    let listHeaderId = "listHeaderId"
    
    
    // INPUT - SOURCE
    var inputDisplayListId: String? = nil {
        didSet {
            guard let inputDisplayListId = inputDisplayListId else {
                print("Error No Input List ID")
                return
            }
            
            if self.currentDisplayList?.id != self.inputDisplayListId{
                print("Current Display List Not Match inputDisplayListID. Fetching List: \(self.inputDisplayListId)")
                Database.fetchListforSingleListId(listId: inputDisplayListId) { (fetchedList) in
                    self.currentDisplayList = fetchedList
                }
            }
        }
    }
    
    // INPUT - SOURCE
    var currentDisplayList: List? = nil {
        didSet{
            print(" ListOptionPhotoPicker | DISPLAYING | \(currentDisplayList?.name) | \(currentDisplayList?.id) | \(currentDisplayList?.postIds?.count) Posts |List_ViewController")
            guard let currentDisplayList = currentDisplayList else {return}
            
            
            if !(currentDisplayList.heroImageUrl?.isEmptyOrWhitespace())! ?? true {
                if let heroUrl = currentDisplayList.heroImageUrl {
                    self.selectedUrl = heroUrl
                }
            }
        }
    }
    
    var currentDisplayUserID: String? = nil {
        didSet {
            print(" ListOptionPhotoPicker | DISPLAYING ALL USER PICTURES | \(currentDisplayUserID)")
            guard let currentDisplayUserID = currentDisplayUserID else {return}


        }
    }
    
    func fetchPostsForUser() {
    
        SVProgressHUD.show(withStatus: "Fetching Your Photos")
        
        guard let currentDisplayUserID = currentDisplayUserID else {
            print("Fetch User for List: ERROR, No currentDisplayUserID")
            return
        }
    
        if isFetchingPost {
            print("  ~ BUSY | fetchPostsForList | \(currentDisplayUserID) | Fetching: \(isFetchingPost)")
            return
        } else {
            isFetchingPost = true
        }
    
        Database.fetchAllPostWithUID(creatoruid: currentDisplayUserID) { (fetchedPosts) in
            print(" SUCCESS | Fetch All User Post for List |, \(currentDisplayUserID):\(self.currentDisplayList?.name), Count: \(fetchedPosts.count) Posts")
            
            self.fetchedPosts = fetchedPosts ?? []
            self.filterSortFetchedPosts()
            self.isFetchingPost = false
            SVProgressHUD.dismiss()
            
        }
    
    }
    
    
    var isFetchingPost = false
    
    func fetchPostsForList(){
        guard let displayListId = currentDisplayList?.id else {
            print("Fetch Post for List: ERROR, No List or ListId")
            return
        }
        
        if isFetchingPost {
            print("  ~ BUSY | fetchPostsForList | \(displayListId) | Fetching: \(isFetchingPost)")
            return
        } else {
            isFetchingPost = true
        }
        
        
        Database.fetchPostFromList(list: self.currentDisplayList, completion: { (fetchedPosts) in
            print(" SUCCESS | Fetch Post for List |, \(displayListId):\(self.currentDisplayList?.name), Count: \(fetchedPosts?.count) Posts")
            
            self.fetchedPosts = fetchedPosts ?? []
            self.filterSortFetchedPosts()
            self.isFetchingPost = false
            
        })
    }
    

    //DISPLAY VARIABLES
    var fetchedUrls: [String] = []
    var selectedUrl: String? = nil
    
    var fetchedPosts: [Post] = []
    
    let saveRankButton = UIButton()
    
    // CollectionView Setup
    
    var isListView: Bool = true
    
    var postFormatInd: Int = 0
    // 0 Grid View
    // 1 List View
    // 2 Full View
    
    enum postFormat {
        case full
        case list
        case grid
    }
    
    //    var currentPostFormat = postFormat.grid
    
    lazy var imageCollectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: HomeSortFilterHeaderFlowLayout())
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = .white
        return cv
    }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("  START |  NewListCollectionView | ViewdidLoad")
        self.edgesForExtendedLayout = UIRectEdge.top
        setupNavigationItems()

        imageCollectionView.register(TestGridPhotoCell.self, forCellWithReuseIdentifier: gridCellId)
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        imageCollectionView.refreshControl = refreshControl
        imageCollectionView.bounces = true
        imageCollectionView.alwaysBounceVertical = true
        imageCollectionView.keyboardDismissMode = .onDrag
        imageCollectionView.isUserInteractionEnabled = true
        imageCollectionView.delegate = self



        self.view.addSubview(imageCollectionView)
        imageCollectionView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: ListViewController.refreshListViewNotificationName, object: nil)
        print("  END |  NewListCollectionView | ViewdidLoad")
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        imageCollectionView.collectionViewLayout.invalidateLayout()
        imageCollectionView.layoutIfNeeded()
        setupNavigationItems()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        imageCollectionView.collectionViewLayout.invalidateLayout()
        imageCollectionView.layoutIfNeeded()
        setupNavigationItems()
    }
    
    
    @objc func handleBackPressNav(){
        //        guard let post = self.selectedPost else {return}
        self.handleBack()
    }
    

    
    
    fileprivate func setupNavigationItems() {
        
        navigationController?.navigationBar.barTintColor = UIColor.white
        let rectPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 5))
        UIColor.white.setFill()
        rectPath.fill()
        let finalImg = UIGraphicsGetImageFromCurrentImageContext()
        navigationController?.navigationBar.shadowImage = finalImg
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        
        // REMOVES THE 1PX BOTTOM LINE IN NAV BAR
        navigationController?.navigationBar.shadowImage = UIImage()
        
        
        let headerTitle = NSAttributedString(string: "List Options", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 17)])
        
        var headerActionView = UIButton()
        headerActionView.setAttributedTitle(headerTitle, for: .normal)
        headerActionView.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        headerActionView.sizeToFit()
        
        //        headerActionView.layoutIfNeeded()
        navigationItem.titleView = headerActionView
        
        // Nav Bar Buttons
        let closeButton = UIButton()
        let closeTitle = NSAttributedString(string: "SELECT", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 12)])
        closeButton.setAttributedTitle(closeTitle, for: .normal)
        closeButton.addTarget(self, action: #selector(didTapSelect), for: .touchUpInside)
        
        let closeNavButton = UIBarButtonItem.init(customView: closeButton)
        self.navigationItem.rightBarButtonItem = closeNavButton
        
        let navBackButton = UIButton()
        navBackButton.addTarget(self, action: #selector(handleBackPressNav), for: .touchUpInside)
        navBackButton.setImage((#imageLiteral(resourceName: "navBackImage").resizeImageWith(newSize: CGSize(width: 10, height: 10))).withRenderingMode(.alwaysTemplate), for: .normal)
        navBackButton.tintColor = UIColor.ianLegitColor()
        let navBackTitle = NSAttributedString(string: " BACK ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 10)])
        navBackButton.setAttributedTitle(navBackTitle, for: .normal)
        navBackButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        navBackButton.sizeToFit()
        let backNavButton = UIBarButtonItem.init(customView: navBackButton)
        self.navigationItem.leftBarButtonItem = backNavButton
        
    }
    
    func didTapSelect(){
        guard let image = self.selectedUrl else {return}
        guard let listId = self.currentDisplayList?.id else {return}
        var tempList = self.currentDisplayList
        
        var imageUrlPostId: String?
        for post in self.fetchedPosts {
            if post.imageUrls.contains(image)
            {
                imageUrlPostId = post.id
            }
        }
        
        
        if image == tempList?.heroImageUrl {
            print(" Same Hero Image URL | No Update | \(tempList?.name) | \(tempList?.heroImageUrl)")
            self.navigationController?.popToRootViewController(animated: true)
        } else {
            tempList?.heroImageUrl = image
            tempList?.heroImageUrlPostId = imageUrlPostId
            tempList?.needsUpdating = true
            listCache[listId] = tempList
            SVProgressHUD.showSuccess(withStatus: "Updated List Photo")
            NotificationCenter.default.post(name: ListViewController.refreshListViewNotificationName, object: nil)
            self.navigationController?.popToRootViewController(animated: true)
            print("Updated List Hero Photo For \(self.currentDisplayList?.name)")
        }
    }
    
    func filterSortFetchedPosts(){
        

        Database.sortPosts(inputPosts: self.fetchedPosts, selectedSort: defaultRecentSort, selectedLocation: nil, completion: { (sortedPosts) in
            
            guard let sortedPosts = sortedPosts else {return}
            
            for post in sortedPosts {
                for url in post.imageUrls {
                    self.fetchedUrls.append(url)
                }
            }
            
            SVProgressHUD.dismiss()

            if self.imageCollectionView.isDescendant(of: self.view) {
                self.imageCollectionView.reloadData()
            }
            
        })
    }
    
    // Refresh Functions
    
    @objc func refreshAll() {
        self.handleRefresh()
    }
    
    @objc func handleRefresh(){
        print("ListViewController | Refresh List | \(self.currentDisplayList?.name)")
        self.refreshList()
        self.clearAllPost()
        //        self.collectionView.reloadData()
        self.fetchPostsForList()
        self.imageCollectionView.refreshControl?.endRefreshing()
    }
    
    func refreshList(){
        
        guard let listId = self.currentDisplayList?.id else {return}
        
        Database.fetchListforSingleListId(listId: listId) { (fetchedList) in
            self.currentDisplayList = fetchedList
        }
        
    }
    
    
    
    
    func clearAllPost(){
        self.fetchedPosts = []
    }
    

    @objc func refreshPostsForFilter(){
        self.clearAllPost()
        self.fetchPostsForList()
        self.imageCollectionView.refreshControl?.endRefreshing()
    }
    


    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if self.postFormatInd == 1 {
            // LIST VIEW
            return CGSize(width: view.frame.width, height: 180)
        } else if self.postFormatInd == 0 {
            // GRID VIEW
            let width = (view.frame.width - 2 - 30) / 2
            return CGSize(width: width, height: width)
        } else {
            return CGSize(width: view.frame.width, height: view.frame.width)
        }
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedUrls.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        var displayUrl = fetchedUrls[indexPath.item]
        var isSelected = displayUrl == self.selectedUrl
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: gridCellId, for: indexPath) as! TestGridPhotoCell
        cell.photoImageView.loadImage(urlString: displayUrl)
        cell.layer.cornerRadius = 1
        cell.layer.masksToBounds = true
        cell.delegate = self
        cell.delegateObjc = self
        cell.isUserInteractionEnabled = true
        cell.layer.borderColor = isSelected ? UIColor.ianLegitColor().cgColor : UIColor.clear.cgColor
        cell.layer.borderWidth = 5
        cell.showCheckMark = isSelected
        cell.userProfileImageView.isHidden = true
        cell.tag = indexPath.item
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        var prevUrl: String = ""
        var displayUrl = self.fetchedUrls[indexPath.item]
        
        if displayUrl != self.selectedUrl {
            self.selectedUrl = displayUrl
        } else if self.selectedUrl == displayUrl {
            self.selectedUrl = ""
        } else {
            self.selectedUrl = displayUrl
        }

        // REFRESH CELLS
        
        self.imageCollectionView.reloadItems(at: [indexPath])
        if let prevIndex = self.fetchedUrls.firstIndex(of: prevUrl) {
            let prevIP = NSIndexPath(row: prevIndex, section: 0) as IndexPath
            self.imageCollectionView.reloadItems(at: [prevIP])
        }
        
    }
    
    func didTapCell(int: Int) {
        
        var prevUrl: String? = self.selectedUrl
        
        var displayUrl = self.fetchedUrls[int]
        if displayUrl != self.selectedUrl {
            self.selectedUrl = displayUrl
        } else if self.selectedUrl == displayUrl {
            self.selectedUrl = ""
        } else {
            self.selectedUrl = displayUrl
        }
        print("Selected URL | \(int) | \(self.selectedUrl)")
        
        // REFRESH CELLS
        let indexPath = NSIndexPath(row: int, section: 0) as IndexPath
        self.imageCollectionView.reloadItems(at: [indexPath])
       
        guard let tempUrl = prevUrl else {return}
        if let prevIndex = self.fetchedUrls.firstIndex(of: tempUrl) {
            let prevIP = NSIndexPath(row: prevIndex, section: 0) as IndexPath
            self.imageCollectionView.reloadItems(at: [prevIP])
        }
    }
    
    
    func didTapPicture(post: Post) {
        print("Tap Picture")
    }
    
    func didTapListCancel(post: Post) {
        print("Tap Picture Cancel")
    }

    func didTapUser(post: Post) {
        self.extTapUser(post: post)
    }
    
    
    
}
