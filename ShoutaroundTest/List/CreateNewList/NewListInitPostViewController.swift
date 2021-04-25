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


class NewListInitPostPhotoViewController: UIViewController, UIGestureRecognizerDelegate {


    let gridCellId = "gridCellId"
    
    // MARK: - Template Inputs
    
    var curList: List? = nil {
        didSet {
            guard let curList = curList else {return}
            self.headerLabel.text = curList.name
        }
    }
    
    let topMargin: CGFloat = 24
    let topMarginBackgroundColor = UIColor.clear
    let headerTitle = ""
    let subHeaderTitle = "Select from your posts below to add to this list"

    let nextButton = TemplateObjects.newListNextButton()
    let exitCardButton = TemplateObjects.newListExitButton()
//    let skipButton = TemplateObjects.newListSkipButton()
    let backButton = TemplateObjects.newListBackButton()

    
    lazy var skipButton: UIButton = {
        let button = UIButton(type: .system)
        
        button.setImage(#imageLiteral(resourceName: "skipImage").withRenderingMode(.alwaysOriginal), for: .normal)

        
        button.setTitle("  SKIP", for: .normal)
        button.setTitleColor(UIColor.ianGrayColor(), for: .normal)
        button.titleLabel?.font =  UIFont.boldSystemFont(ofSize: 15)
        button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
        button.tintColor = UIColor.ianGrayColor()
        button.isUserInteractionEnabled = true
        button.layer.borderColor = UIColor.ianGrayColor().cgColor
        button.layer.borderWidth = 1
        return button
    }()
    
    let cardContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.ianWhiteColor()
        v.clipsToBounds = true
        v.layer.cornerRadius = 10
        v.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]        //        label.numberOfLines = 0
        return v
    }()
    

    let headerLabel: UILabel = {
        let label = UILabel()
        label.layer.borderColor = UIColor.clear.cgColor
        label.textAlignment = .left
        label.font = UIFont(name: "Poppins-Bold", size: 30)
        label.textColor = .ianBlackColor()
        return label
    }()
    
    let subHeaderLabel: UILabel = {
        let label = UILabel()
        label.layer.borderColor = UIColor.clear.cgColor
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .ianGrayColor()
        return label
    }()

    var fullSearchBar = UISearchBar()

        
    var currentDisplayUserID: String? = nil {
        didSet {
            print(" ListOptionPhotoPicker | DISPLAYING ALL USER PICTURES | \(currentDisplayUserID)")
            guard let currentDisplayUserID = currentDisplayUserID else {return}
        }
    }

    
    
    var isFetchingPost = false
    var isFiltering = false

    //DISPLAY VARIABLES

    var fetchedPosts: [Post] = []
    var filteredPosts: [Post] = []
    var selectedPostIds: [String] = []
    {
        didSet
        {
            let title = (selectedPostIds.count > 0) ? String(selectedPostIds.count) : ""
            nextButton.setTitle("", for: .normal)

        }
    }

    // Pagination Variables
    var paginatePostsCount: Int = 0
    var isFinishedPaging = false {
        didSet{
            if isFinishedPaging == true {
            }
        }
    }
    
    // CollectionView Setup

    lazy var imageCollectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: HomeSortFilterHeaderFlowLayout())
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = .white
        return cv
    }()
    
    
    // MARK: - VIEWDIDLOAD

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationItems()

        let backgroundView = UIView()
        backgroundView.backgroundColor = topMarginBackgroundColor

        view.addSubview(backgroundView)
        backgroundView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

        view.addSubview(cardContainer)
        cardContainer.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: topMargin, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        cardContainer.backgroundColor = UIColor.ianWhiteColor()
        
        cardContainer.addSubview(exitCardButton)
        exitCardButton.anchor(top: cardContainer.topAnchor, left: nil, bottom: nil, right: cardContainer.rightAnchor, paddingTop: 24, paddingLeft: 0, paddingBottom: 0, paddingRight: 24, width: 28, height: 28)
        exitCardButton.addTarget(self, action: #selector(exitCard), for: .touchUpInside)

        cardContainer.addSubview(headerLabel)
        headerLabel.anchor(top: cardContainer.topAnchor, left: cardContainer.leftAnchor, bottom: nil, right: exitCardButton.leftAnchor, paddingTop: 24, paddingLeft: 24, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        headerLabel.text = self.curList?.name ?? "NO LIST NAME"
        headerLabel.sizeToFit()
        
        cardContainer.addSubview(subHeaderLabel)
        subHeaderLabel.anchor(top: headerLabel.bottomAnchor, left: cardContainer.leftAnchor, bottom: nil, right: exitCardButton.rightAnchor, paddingTop: 5, paddingLeft: 24, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        subHeaderLabel.text = subHeaderTitle
        subHeaderLabel.sizeToFit()
        
        let actionBar = UIView()
        cardContainer.addSubview(actionBar)
        actionBar.anchor(top: subHeaderLabel.bottomAnchor, left: cardContainer.leftAnchor, bottom: nil, right: cardContainer.rightAnchor, paddingTop: 10, paddingLeft: 24, paddingBottom: 0, paddingRight: 24, width: 0, height: 36)
        
        actionBar.addSubview(skipButton)
        skipButton.anchor(top: nil, left: nil, bottom: nil, right: actionBar.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        skipButton.centerYAnchor.constraint(equalTo: actionBar.centerYAnchor).isActive = true
        skipButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSkip)))

        setupSearchBar()
        cardContainer.addSubview(fullSearchBar)
        fullSearchBar.anchor(top: actionBar.topAnchor, left: actionBar.leftAnchor, bottom: actionBar.bottomAnchor, right: skipButton.leftAnchor, paddingTop: 3, paddingLeft: -8, paddingBottom: 3, paddingRight: 5, width: 0, height: 0)
        
    
        
        
        let collectionViewContainer = UIView()
        cardContainer.addSubview(collectionViewContainer)
        collectionViewContainer.anchor(top: actionBar.bottomAnchor, left: cardContainer.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: cardContainer.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

        setupCollectionView()

        collectionViewContainer.addSubview(imageCollectionView)
        imageCollectionView.anchor(top: collectionViewContainer.topAnchor, left: collectionViewContainer.leftAnchor, bottom: collectionViewContainer.bottomAnchor, right: collectionViewContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: ListViewController.refreshListViewNotificationName, object: nil)
        print("  END |  NewListCollectionView | ViewdidLoad")
        
        let nextButtonContainer = UIView()
        cardContainer.addSubview(nextButtonContainer)
        nextButtonContainer.anchor(top: nil, left: nil, bottom: cardContainer.bottomAnchor, right: cardContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 48, paddingRight: 24, width: 0, height: 0)
        nextButtonContainer.backgroundColor = UIColor.ianWhiteColor()
        
        nextButtonContainer.addSubview(nextButton)
        nextButton.anchor(top: nextButtonContainer.topAnchor, left: nextButtonContainer.leftAnchor, bottom: nextButtonContainer.bottomAnchor, right: nextButtonContainer.rightAnchor, paddingTop: 8, paddingLeft: 8, paddingBottom: 8, paddingRight: 8, width: 0, height: 0)
        nextButton.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
        nextButton.sizeToFit()
        nextButton.setTitle("", for: .normal)
        
        collectionViewContainer.addSubview(backButton)
        backButton.anchor(top: nil, left: cardContainer.leftAnchor, bottom: collectionViewContainer.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 24, paddingBottom: 24, paddingRight: 0, width: 0, height: 0)
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        backButton.backgroundColor = UIColor.ianWhiteColor()
        backButton.layer.borderColor = UIColor.ianBlackColor().cgColor
        backButton.layer.borderWidth = 1
        backButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        imageCollectionView.collectionViewLayout.invalidateLayout()
        imageCollectionView.layoutIfNeeded()
        setupNavigationItems()
        guard let temp = tempListCreated else {return}
        self.curList = temp
        
        if isFetchingPost {
            SVProgressHUD.show(withStatus: "Fetching Your Photos")
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
//        imageCollectionView.collectionViewLayout.invalidateLayout()
//        imageCollectionView.layoutIfNeeded()
//        setupNavigationItems()
    }
    


        // MARK: - BUTTONS FUNCTIONS

        
        @objc func didTapBack() {
            self.navigationController?.popViewController(animated: true)

        }

        @objc func handleNext() {
            print("NEXT")
            guard let list = self.curList else {return}

            SVProgressHUD.show(withStatus: "Creating \((self.curList?.name)!)")
            self.createNewList()


        }
    
    @objc func createNewList(){
        addPostsToList()
        guard let list = self.curList else {return}
        Database.createList(uploadList: list) {
            self.dismiss(animated: true) {
                print("CREATE NEW LIST COMPLETE | LIST VIEW DISMISSED")
                tempListCreated =  nil
                SVProgressHUD.dismiss()
            }
        }
    }
        
        @objc func exitCard() {
            self.dismiss(animated: true) {
                print("exitCard")
                tempListCreated = nil
            }
        }
        
        @objc func handleSkip() {
            print("SKIP")
            tempListCreated = self.curList
            self.createNewList()
    //        createNewListView.curList = self.curList
//            self.navigationController?.pushViewController(createNewListView, animated: true)
        }
    

    func addPostsToList(){
        let createdDate = Date().timeIntervalSince1970
        var tempListIds: [String: Any] = [:]
        var tempListImageUrls: [String] = []
        var tempListImagePostIds: [String] = []

        for postId in selectedPostIds {
            tempListIds[postId] = createdDate
            if let tempPost = self.fetchedPosts.first(where: { (post) -> Bool in
                post.id == postId
            }) {
                tempListImageUrls.append(tempPost.imageUrls[0])
                tempListImagePostIds.append(postId)
            }
        }
        
        self.curList?.listImageUrls = tempListImageUrls
        self.curList?.listImagePostIds = tempListImagePostIds
        self.curList?.postIds = tempListIds
        
        print("addPostsToList | Added to New List | \(selectedPostIds.count) Posts , \(self.curList?.listImageUrls.count) URLs, \(self.curList?.listImagePostIds.count) PostIds | New List: \(self.curList?.name) : \(self.curList?.id)")
        
    }

    
    
    fileprivate func setupNavigationItems() {
        
        self.navigationController?.isNavigationBarHidden = true
        
    }
    
    func didTapSelect(){

    }
    
    // MARK: - FETCHING POST
        
        func fetchPostsForUser() {
        
    //        SVProgressHUD.show(withStatus: "Fetching Your Photos")
            
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
                print(" SUCCESS | Fetch All User Post for List |, \(currentDisplayUserID), Count: \(fetchedPosts.count) Posts")
                
                Database.sortPosts(inputPosts: fetchedPosts, selectedSort: defaultRecentSort, selectedLocation: nil, completion: { (sortedPosts) in
                    
                    self.fetchedPosts = sortedPosts ?? []
                    self.filterSortFetchedPosts()
                    self.isFetchingPost = false
                    SVProgressHUD.dismiss()

                })
                

                
            }
        
        }
    
    func filterSortFetchedPosts(){
        
        let tempFilter = Filter.init(defaultSort: defaultRecentSort)
        let searchTerm = fullSearchBar.text ?? ""
        
        
        if searchTerm.alphaNumericOnly().count > 0 {
            tempFilter.filterCaption = searchTerm
        } else {
            tempFilter.filterCaption = nil
        }
        
        // FILTERING POST AND NOT SORTING TO SAVE EFFICIENCY
        
        Database.filterPostsNew(inputPosts: self.fetchedPosts, postFilter: tempFilter) { (filteredPosts) in
                
                self.filteredPosts = filteredPosts ?? []
                
                print("Filter Sort Post: Success: Fetched: \(self.fetchedPosts.count) | Filtered: \(self.filteredPosts.count)")
                self.paginatePosts()
                SVProgressHUD.dismiss()

        }
                
    }
    
        func paginatePosts(){
            
            let paginateFetchPostSize = 9
            
            let maxPost = (isFiltering ? filteredPosts.count : fetchedPosts.count)
            
            self.paginatePostsCount = min(self.paginatePostsCount + paginateFetchPostSize, maxPost)
            
            if self.paginatePostsCount == maxPost {
                self.isFinishedPaging = true
            } else {
                self.isFinishedPaging = false
            }
            
            print("Home Paginate \(self.paginatePostsCount) : \(maxPost) | Filtering \(self.isFiltering), Finished Paging: \(self.isFinishedPaging)")
            
            // NEED TO RELOAD ON MAIN THREAD OR WILL CRASH COLLECTIONVIEW
            DispatchQueue.main.async(execute: { self.imageCollectionView.reloadData() })
    //        DispatchQueue.main.async(execute: { self.collectionView?.reloadSections(IndexSet(integer: 0)) })

            
        }
    
    
    
    // MARK: - REFRESH FUNCTIONS

    @objc func refreshAll() {
        self.handleRefresh()
    }
    
    @objc func handleRefresh(){
        print("ListViewController | Refresh List ")
        self.clearAllPost()
        self.refreshPagination()
        self.fullSearchBar.text = nil
        self.filterSortFetchedPosts()
        self.imageCollectionView.reloadData()
        self.imageCollectionView.refreshControl?.endRefreshing()
    }
    

    func clearAllPost(){
        self.fetchedPosts = []
        self.filteredPosts = []
    }
    

    @objc func refreshPostsForFilter(){
        self.filteredPosts = []
        self.filterSortFetchedPosts()
        self.imageCollectionView.refreshControl?.endRefreshing()
    }
    
    func refreshPagination(){
        self.isFinishedPaging = false
        self.paginatePostsCount = 0
    }


    
}

// MARK: - COLLECTION VIEW DELEGATES


extension NewListInitPostPhotoViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func setupCollectionView() {
        imageCollectionView.register(TestGridPhotoCell.self, forCellWithReuseIdentifier: gridCellId)
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        imageCollectionView.refreshControl = refreshControl
        imageCollectionView.bounces = true
        imageCollectionView.alwaysBounceVertical = true
        imageCollectionView.keyboardDismissMode = .onDrag
        imageCollectionView.isUserInteractionEnabled = true
        imageCollectionView.delegate = self
        
        imageCollectionView.emptyDataSetSource = self
        imageCollectionView.emptyDataSetDelegate = self
        imageCollectionView.emptyDataSetView { (emptyview) in
            emptyview.isUserInteractionEnabled = true
        }
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
        
        let width = (view.frame.width - 2 - 30) / 2
        return CGSize(width: width, height: width)
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return isFiltering ? filteredPosts.count : fetchedPosts.count
        
        return self.paginatePostsCount
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.item == self.paginatePostsCount - 1 && !isFinishedPaging{
            print("CollectionView Paginate")
            paginatePosts()
        }
        
        var displayPost = isFiltering ? filteredPosts[indexPath.item] : fetchedPosts[indexPath.item]
        var isSelected = selectedPostIds.contains(displayPost.id ?? "")
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: gridCellId, for: indexPath) as! TestGridPhotoCell
        cell.post = displayPost
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
        
        var displayPost = isFiltering ? filteredPosts[indexPath.item] : fetchedPosts[indexPath.item]
        guard let postId = displayPost.id else {return}

        self.postIdSelected(postId: postId)
        
//        if let index = selectedPostIds.index(of: postId) {
//            self.selectedPostIds.remove(at: index)
//        } else {
//            self.selectedPostIds.append(postId)
//        }
//
//        // REFRESH CELLS
//
//        self.imageCollectionView.reloadItems(at: [indexPath])
        
    }
    
    func postIdSelected(postId: String?) {
        guard let postId = postId else {return}
        
        if let index = selectedPostIds.firstIndex(of: postId) {
            self.selectedPostIds.remove(at: index)
        } else {
            self.selectedPostIds.append(postId)
        }
        
        if isFiltering {
            if let filteredIndex = self.filteredPosts.firstIndex(where: { (post) -> Bool in
                post.id == postId
            }) {
                let indexPath = IndexPath(row: filteredIndex, section: 0)
                self.imageCollectionView.reloadItems(at: [indexPath])
            }
        } else {
            if let filteredIndex = self.fetchedPosts.firstIndex(where: { (post) -> Bool in
                post.id == postId
            }) {
                let indexPath = IndexPath(row: filteredIndex, section: 0)
                self.imageCollectionView.reloadItems(at: [indexPath])
            }
        }
        
        nextButton.isSelected = selectedPostIds.count > 0
        
    }
    
}



extension NewListInitPostPhotoViewController: EmptyDataSetSource, EmptyDataSetDelegate {

    // EMPTY DATA SET DELEGATES

    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        if self.isFiltering {
            text = "SORRY!"
        } else {
            text = ""
            //            let number = arc4random_uniform(UInt32(tipDefaults.count))
            //            text = tipDefaults[Int(number)]
        }
        
        font = UIFont(name: "Poppins-Bold", size: 40)
        //        textColor = UIColor(hexColor: "25282b")
        textColor = UIColor.ianBlackColor()
        
        
        if text == nil {
            return nil
        }
        
        let descTitle = NSAttributedString(string: text!, attributes: [NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.font: font])

        return descTitle
        
    }

    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        font = UIFont.systemFont(ofSize: 14)
        textColor = UIColor.rgb(red: 43, green: 43, blue: 43)
        
        if self.isFiltering {
            text = "Nothing Legit Here! 😭"
        } else {
            text = ""
        }
        
        if text == nil {
            return nil
        }
        
        let descTitle = NSAttributedString(string: text!, attributes: [NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.font: font])

        return descTitle
        
    }

    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        //        return #imageLiteral(resourceName: "amaze").resizeVI(newSize: CGSize(width: view.frame.width/2, height: view.frame.height/2))
        var image: UIImage?
        if self.isFiltering {
            image = #imageLiteral(resourceName: "noResults_pic")
        } else {
            image = #imageLiteral(resourceName: "Legit_Vector")
        }
        
        return image
        
    }
    
    func buttonImage(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> UIImage? {
        var image: UIImage?
        if self.isFiltering {
            image = #imageLiteral(resourceName: "noResults_pic")
        } else {
            image = #imageLiteral(resourceName: "Legit_Vector")
        }
        
        return nil
    }


    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        if self.isFiltering {
            text = "Search For Something Else"
        } else {
            text = "Click to Discover New Things"
        }
        text = ""
        font = UIFont(name: "Poppins-Bold", size: 14)
        textColor = UIColor.ianBlueColor()
        
        
        font = UIFont.systemFont(ofSize: 14)
        textColor = UIColor.rgb(red: 43, green: 43, blue: 43)
        
        if self.isFiltering {
            text = "Nothing Legit Here! 😭"
        } else {
            text = ""
        }
        
        if text == nil {
            return nil
        }
        
        
        let descTitle = NSAttributedString(string: text!, attributes: [NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.font: font])
        
        return nil

        
    }
    
    func emptyDataSetShouldAllowTouch(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return true
    }

    //    func buttonBackgroundImage(forEmptyDataSet scrollView: UIScrollView, for state: UIControlState) -> UIImage? {
    //
    //        var capInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    //        var rectInsets = UIEdgeInsets.zero
    //
    //        capInsets = UIEdgeInsets(top: 25, left: 25, bottom: 25, right: 25)
    //        rectInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    //
    //        let image = #imageLiteral(resourceName: "emptydatasetbutton")
    //        return image.resizableImage(withCapInsets: capInsets, resizingMode: .stretch).withAlignmentRectInsets(rectInsets)
    //    }

    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
        //        return UIColor.rgb(red: 249, green: 249, blue: 249)
        return UIColor.backgroundGrayColor()
    }

    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {
        self.handleRefresh()

//        if viewFilter.isFiltering {
////            self.openFilter()
//        } else {
//            // Returns To Home Tab
//            self.tabBarController?.selectedIndex = 1
//        }
    }

    func emptyDataSet(_ scrollView: UIScrollView, didTapView view: UIView) {
        self.handleRefresh()
    }

        func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
            let offset = (self.imageCollectionView.frame.height) / 5
            return 40
        }

    func spaceHeight(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return 9
    }
}


extension NewListInitPostPhotoViewController : TestGridPhotoCellDelegate, TestGridPhotoCellDelegateObjc  {
    func didTapPicture(post: Post) {
        guard let postId = post.id else {return}
        self.postIdSelected(postId: postId)

    }
    
    func didTapListCancel(post: Post) {
        
    }
    
    func didTapCell(int: Int) {
        
    }


    func didTapUser(post: Post) {
        self.extTapUser(post: post)
    }
    
}



extension NewListInitPostPhotoViewController: UISearchBarDelegate {

    
        func setupSearchBar() {
            fullSearchBar.searchBarStyle = .prominent
//            fullSearchBar.searchBarStyle = .minimal

            fullSearchBar.isTranslucent = false
            fullSearchBar.tintColor = UIColor.ianBlackColor()
            fullSearchBar.placeholder = "Search for posts"
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
//            UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(attributes, for: .normal)
            
            
//            let searchImage = #imageLiteral(resourceName: "search_selected").withRenderingMode(.alwaysTemplate)
//            fullSearchBar.setImage(UIImage(), for: .search, state: .normal)
            
    //        let cancelImage = #imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysTemplate)
    //        fullSearchBar.setImage(cancelImage, for: .clear, state: .normal)

            fullSearchBar.layer.borderWidth = 0
            fullSearchBar.layer.borderColor = UIColor.ianBlackColor().cgColor
        
            let textFieldInsideSearchBar = fullSearchBar.value(forKey: "searchField") as? UITextField
            textFieldInsideSearchBar?.textColor = UIColor.ianBlackColor()
            textFieldInsideSearchBar?.font = UIFont.systemFont(ofSize: 14)
            
            // REMOVE SEARCH BAR ICON
    //        let searchTextField:UITextField = fullSearchBar.subviews[0].subviews.last as! UITextField
    //        searchTextField.leftView = nil
            
            
            for s in fullSearchBar.subviews[0].subviews {
                if s is UITextField {
                    s.backgroundColor = UIColor.clear
                    s.layer.backgroundColor = UIColor.clear.cgColor
                    if let backgroundview = s.subviews.first {
                        
                        // Background color
    //                    backgroundview.backgroundColor = UIColor.white
                        backgroundview.clipsToBounds = true
                        backgroundview.layer.backgroundColor = UIColor.clear.cgColor
                        
                        // Rounded corner
    //                    backgroundview.layer.cornerRadius = 30/2
    //                    backgroundview.layer.masksToBounds = true
    //                    backgroundview.clipsToBounds = true
                    }
                }
            }

        }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        self.isFiltering = (searchText.alphaNumericOnly().count > 0)
        
        self.refreshPostsForFilter()
        
    }
    
    
}
