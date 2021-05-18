//
//  SharePhotoListController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 12/23/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

import CoreLocation
import SKPhotoBrowser
import SVProgressHUD
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

var newPost: Post? = nil
var newPostId: PostId? = nil


protocol SharePhotoListControllerDelegate {
    func refreshPost(post:Post)
}


class SharePhotoListController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, ListPhotoCellDelegate, SKPhotoBrowserDelegate, NewListPhotoCellDelegate, UISearchBarDelegate {
    
    func didTapListCancel(post:Post) {
        
    }
    
    
    func didTapComment(post: Post) {
        // Disable Comment From Here
    }
    
    func didTapBookmark(post: Post) {
        // Disable Bookmark from here
    }
    

    // 3 Modes: Add Post, Edit Post, Bookmarking Post (Not creator UID)
    
    var delegate: SharePhotoListControllerDelegate?

    var isFiltering: Bool = false {
        didSet{
            self.tableView.reloadData()
        }
    }

    var isEditingPost: Bool = false
    var preEditPost: Post? = nil
    var preExistingList: [String:String]? = [:]
    
    func checkLists(){
        var currentSelectedListIds: [String] = []
        guard let selectedListIds = uploadPost?.selectedListId else {return}
        for (key,value) in selectedListIds {
            if !currentSelectedListIds.contains(key) {
                currentSelectedListIds.append(key)
            }
        }
        
        
        for (key,value) in preExistingList! {
            if !currentSelectedListIds.contains(key) {
                currentSelectedListIds.append(key)
            }
        }
        
        for list in self.displayList {
            list.isSelected = currentSelectedListIds.contains(list.id!)
        }
        
        self.selectedListIds = currentSelectedListIds
        self.tableView.reloadData()
    }
    
    var isBookmarkingPost: Bool = false {
        didSet {
            self.viewListMode = false
            self.setupNavigationItems()
        }
    }
    
    var uploadPostDictionary: [String: Any] = [:]
    var uploadPostLocation: CLLocation? = nil
    var uploadPost: Post? = nil {
        didSet{
            self.uploadPostDictionary = (self.uploadPost?.dictionary()) ?? [:]
            self.checkLists()
            
            self.preExistingList = uploadPost?.selectedListId
            if (self.preExistingList?.count ?? 0) > 0 {
                self.selectedListIds = Array(self.preExistingList!.keys)
            } else {
                self.selectedListIds = []
            }
            print("\(self.preExistingList?.count) Selected Lists Loaded For Post")
            self.setupLists()
            
            if uploadPost?.creatorUID == Auth.auth().currentUser?.uid {
                self.preEditPost = uploadPost
            }
            
            // Refreshes Current User Lists
            collectionView.reloadData()
            self.noLocationInd = (uploadPost?.locationGPS == nil)
        }
    }
    
    var uploadUser: User? {
        didSet {
            print("Loading \(uploadUser?.username ?? "") | SharePhotoListController | ViewListMode: \(self.viewListMode)")
            self.setupListsForUser()
        }
    }
    var noUpload = false
    
    
    var bookmarkList: List = emptyBookmarkList
    var legitList: List = emptyLegitList
    var fetchedList: [List] = []
    var displayList: [List] = []
    var selectedList: [List]? {
        return fetchedList.filter { return self.selectedListIds.contains($0.id!)}
    }
    
    func clearAllInfo() {
        self.fetchedList = []
        self.displayList = []
        self.selectedListIds = []
        self.uploadUser = nil
        self.uploadPost = nil
    }
    
    var selectedListIds: [String] = []
    var selectedListCount: Int = 0
    var noLocationInd: Bool = true
    
    let postCellId = "PostCellId"
    let listCellId = "ListCellId"
    let mainTabListCellId = "mainTabListCellId"

    lazy var collectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
//        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = true
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = .white
    
        return cv
    }()
    
    var searchBar = UISearchBar()
    
    let addListView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    lazy var addListTextField: PaddedTextField = {
        let tf = PaddedTextField()
        tf.font = UIFont.systemFont(ofSize: 14.0)
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.gray.cgColor
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.layer.cornerRadius = 10
        tf.layer.masksToBounds = true
        tf.placeholder = "Eg: Chicago, Ramen"
        tf.delegate = self
        return tf
    }()
    
    let addListButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        button.setImage(#imageLiteral(resourceName: "add_list").withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTitle(" New List", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        button.tintColor = UIColor.ianWhiteColor()
        button.backgroundColor = UIColor.mainBlue()
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(initAddList), for: .touchUpInside)
        return button
    } ()
    
    var addListButtonWidth: NSLayoutConstraint?
    
    var viewListMode = false {
        didSet {
            self.setAddListButtonWidth()
            self.setupNextButton()
//            self.nextButton.isHidden = (viewListMode && self.uploadUser?.uid != CurrentUser.uid)
//                .isHidden = (viewListMode && self.uploadUser?.uid != CurrentUser.uid)
            self.setupNavigationItems()
        }
    }
    
    func setAddListButtonWidth() {
        self.addListButtonWidth?.constant = (viewListMode || (self.uploadUser != nil && self.uploadUser?.uid != CurrentUser.uid)) ? 0 : 120
        self.addListButtonWidth?.isActive = true
    }
    
    let nextButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        button.setImage(#imageLiteral(resourceName: "listsHash").withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTitle(" Tag List ", for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 15)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
        button.tintColor = UIColor.ianWhiteColor()
        button.backgroundColor = UIColor.ianLegitColor()
        return button
    }()
    
    
//    func addList(){
//        let listId = NSUUID().uuidString
//        guard let uid = Auth.auth().currentUser?.uid else {return}
//        self.addListTextField.resignFirstResponder()
//        checkListName(listName: addListTextField.text) { (listName) in
//
//            let optionsAlert = UIAlertController(title: "Create New List", message: "", preferredStyle: UIAlertController.Style.alert)
//
//            optionsAlert.addAction(UIAlertAction(title: "Public", style: .default, handler: { (action: UIAlertAction!) in
//                // Create Public List
//                let newList = List.init(id: listId, name: listName, publicList: 1)
//                self.createList(newList: newList)
//                self.addListTextField.resignFirstResponder()
//
//            }))
//
//            optionsAlert.addAction(UIAlertAction(title: "Private", style: .default, handler: { (action: UIAlertAction!) in
//                // Create Private List
//                let newList = List.init(id: listId, name: listName, publicList: 0)
//                self.createList(newList: newList)
//                self.addListTextField.resignFirstResponder()
//
//            }))
//
//            optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
//                print("Handle Cancel Logic here")
//            }))
//
//            self.present(optionsAlert, animated: true, completion: {
//            })
//        }
//    }
    
    @objc func initAddList(){
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Create A New List", message: "Enter New List Name", preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.text = ""
        }
        
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            print("New List Name: \(textField?.text)")
            guard let newListName = textField?.text else {return}
            
            let listId = NSUUID().uuidString
            guard let uid = Auth.auth().currentUser?.uid else {return}
            self.checkListName(listName: newListName) { (listName) in
                
                self.addListTextField.resignFirstResponder()
                let newList = List.init(id: listId, name: listName, publicList: 1)
                self.createList(newList: newList)
                
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        let subAlert = UIAlertController(title: "New List Limit", message: "Please Subscribe to Legit Premium to create more than \(premiumListLimit) lists.", preferredStyle: UIAlertController.Style.alert)
        subAlert.addAction(UIAlertAction(title: "Subscribe", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction!) in
            self.extOpenSubscriptions()
        }))
        subAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        
        // 4. Present the alert.
        if !CurrentUser.isPremium && CurrentUser.listIds.count >= premiumListLimit {
            self.present(subAlert, animated: true, completion: nil)
        } else {
            self.present(alert, animated: true, completion: nil)
        }
    
    
//        let optionsAlert = UIAlertController(title: "Create New List", message: "", preferredStyle: UIAlertController.Style.alert)
//
//        optionsAlert.addAction(UIAlertAction(title: "Public", style: .default, handler: { (action: UIAlertAction!) in
//            // Create Public List
//            let newList = List.init(id: listId, name: listName, publicList: 1)
//            self.createList(newList: newList)
//        }))
//
//        optionsAlert.addAction(UIAlertAction(title: "Private", style: .default, handler: { (action: UIAlertAction!) in
//            // Create Private List
//            let newList = List.init(id: listId, name: listName, publicList: 0)
//            self.createList(newList: newList)
//        }))
//
//        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
//            print("Handle Cancel Logic here")
//        }))
//        self.present(optionsAlert, animated: true, completion: {
//            self.addListTextField.resignFirstResponder()
//        })
    
    }
    
    func createList(newList: List){
        // Create New List in Database
        print("Current Auth: ", Auth.auth().currentUser?.isAnonymous)
        if !(Auth.auth().currentUser?.isAnonymous)! {
            Database.createList(uploadList: newList){}

        } else {
            // Update New List in Current User Cache
            print("Guest User Creating List")
            CurrentUser.addList(list: newList)
        }
        self.fetchedList.insert(newList, at: 0)
//        self.fetchedList.insert(newList, at: 1)
        self.setupLists()
//        self.displayList.insert(newList, at: 1)

        self.tableView.reloadData()
        self.addListTextField.text?.removeAll()
    }
    
    
    var listSortSegment = UISegmentedControl()
    var sortOptions: [String] = ListSortOptions
    var selectedSort: String = ListSortDefault {
        didSet{
            listSortSegment.selectedSegmentIndex = sortOptions.firstIndex(of: selectedSort)!
            if self.viewListMode && self.uploadUser != nil {
                self.setupListsForUser()
            } else {
                self.setupLists()
            }
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
//        self.setupNavigationItems()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.setupNavigationItems()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
//        print("Disappear")
    }
    
    func checkListName(listName: String?, completion: @escaping (String) -> ()){
        guard let listName = listName else {
            self.alert(title: "New List Requirement", message: "Please Insert List Name")
            return
        }
        if listName.isEmptyOrWhitespace() {
            self.alert(title: "New List Requirement", message: "Please Insert List Name")
            return
        }
        
        if displayList.contains(where: { (displayList) -> Bool in
            return displayList.name.lowercased() == listName.lowercased()
        }) {
            self.alert(title: "Duplicate List Name", message: "Please Insert Different List Name")
            return
        }
        
        if fetchedList.contains(where: { (displayList) -> Bool in
            return displayList.name.lowercased() == listName.lowercased()
        }) {
            self.alert(title: "Duplicate List Name", message: "Please Insert Different List Name")
            return
        }
        
        completion(listName)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        addListTextField.resignFirstResponder()
//        self.addList()
        return true
    }
    
    lazy var tableView : UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        tv.estimatedRowHeight = 80
        tv.allowsMultipleSelection = true
        return tv
    }()
    
    static let updateFeedNotificationName = NSNotification.Name(rawValue: "UpdateFeed")
    static let updateProfileFeedNotificationName = NSNotification.Name(rawValue: "UpdateProfileFeed")
    static let updateListFeedNotificationName = NSNotification.Name(rawValue: "UpdateListFeed")
    static let createdNewPostNotificationName = NSNotification.Name(rawValue: "Create New Post")

    var showSummaryPost: Bool = false
    
    @objc func handleNext(){
        guard let post = uploadPost else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        if self.noUpload {
            var tempPost = post
            var tempNewList: [String:String] = [:]
            for listId in self.selectedListIds {
                if let listName = self.fetchedList.first(where: { (list) -> Bool in
                    list.id == listId
                })?.name {
                    tempNewList[listId] = listName
                }
            }
            tempPost.selectedListId = tempNewList
            self.delegate?.refreshPost(post: tempPost)
            self.navigationController?.popViewController(animated: true)
        } else {
            if self.isEditingPost {
                self.handleEditPost()
            } else if self.isBookmarkingPost {
                self.handleAddPostToList()
            } else {
                self.handleShareNewPost()
            }
        }
    }
    
    
    func setupNavigationItems(){
        // Setup Navigation
//        print("SharePhotoList | Setup Navigation Items")
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.barTintColor = UIColor.ianLegitColor()
        self.navigationController?.navigationBar.tintColor = UIColor.ianLegitColor()
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.layoutIfNeeded()

//        let navTextColor = self.viewListMode ? UIColor.white : UIColor.ianLegitColor()
        let navTextColor = UIColor.white

        navigationController?.view.backgroundColor = UIColor.ianLegitColor()
        navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.font.rawValue: UIFont(name: "Poppins-Bold", size: 18), NSAttributedString.Key.foregroundColor.rawValue: navTextColor])
        navigationItem.title = "Tag List"

        self.addListButton.isHidden = (viewListMode && self.uploadUser?.uid != CurrentUser.uid)
        
        // Nav Back Buttons
        let navBackButton = navBackButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        navBackButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        navBackButton.setTitleColor(navTextColor, for: .normal)
        navBackButton.tintColor = navTextColor
        navBackButton.backgroundColor = UIColor.clear
        let navShareTitle = NSAttributedString(string: " BACK ", attributes: [NSAttributedString.Key.foregroundColor: navTextColor, NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 12)])
        navBackButton.setAttributedTitle(navShareTitle, for: .normal)
        
        let barButton2 = UIBarButtonItem.init(customView: navBackButton)
        self.navigationItem.leftBarButtonItem = barButton2
        
        let navDefaultButton = NavButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        navDefaultButton.setTitleColor(navTextColor, for: .normal)
        navDefaultButton.tintColor = navTextColor
        navDefaultButton.backgroundColor = UIColor.clear
        
    // VIEW MODE
        if self.viewListMode {
            self.navigationItem.rightBarButtonItem = nil
            navigationItem.title = "View Lists"
            let navUserButton = navDefaultButton
            navUserButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
            
            let usernameTitle = NSMutableAttributedString()
            usernameTitle.append(NSAttributedString(string:"\(self.uploadUser?.username ?? "")", attributes: [NSAttributedString.Key.foregroundColor: navTextColor, NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 15)]))
            navUserButton.backgroundColor = UIColor.clear
            navUserButton.setAttributedTitle(usernameTitle, for: .normal)
//            navUserButton.setTitle("\(self.uploadUser?.username ?? "")", for: .normal)
//            navUserButton.setTitleColor(UIColor.darkGray, for: .normal)
            let barButton2 = UIBarButtonItem.init(customView: navUserButton)
            self.navigationItem.rightBarButtonItem = barButton2
        }
        
        
    // EDIT POST
        else if self.isEditingPost
        {
            // Nav Edit Button
            let navEditButton = navDefaultButton
            navEditButton.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
            let navEditTitle = NSAttributedString(string: " Edit Post ", attributes: [NSAttributedString.Key.foregroundColor: navTextColor, NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 12)])
            navEditButton.setAttributedTitle(navEditTitle, for: .normal)
            
//            navEditButton.setTitle("Edit Post", for: .normal)
            let barButton2 = UIBarButtonItem.init(customView: navEditButton)
            self.navigationItem.rightBarButtonItem = barButton2
        }
        
    // ADDING POST TO LIST
        else if self.isBookmarkingPost
        {
            
            var displayString = ""
            
            var newSelectedListCount = self.selectedListIds.count ?? 0
//            for list in self.displayList {
//                newSelectedListCount += list.isSelected ? 1 : 0
//            }
            var previousListCount = self.preExistingList?.count ?? 0
            var listChange = newSelectedListCount - previousListCount
            
            if listChange > 0 {
                displayString += "Tag \(listChange) Lists"
            } else if listChange < 0 {
                displayString += "Untag \(-listChange) Lists"
            } else {
                displayString += "Tag List"
            }

            navigationItem.title = displayString

            // Nav Tag Button
            let navTagButton = navDefaultButton
            navTagButton.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
            navTagButton.setTitle("Next", for: .normal)

            let navNextTitle = NSAttributedString(string: "Next", attributes: [NSAttributedString.Key.foregroundColor: navTextColor, NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 12)])
            navTagButton.setAttributedTitle(navNextTitle, for: .normal)


            let barButton2 = UIBarButtonItem.init(customView: navTagButton)
            self.navigationItem.rightBarButtonItem = barButton2
        }
        
    // NEW POST
        
        else {
            // Nav Share Button
            let navShareButton = navDefaultButton
            navShareButton.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
            navShareButton.setTitle("Share Post", for: .normal)
            let barButton2 = UIBarButtonItem.init(customView: navShareButton)
            self.navigationItem.rightBarButtonItem = barButton2
            
            
            
//            let navBarButton = UIButton()
//            let displayAttributed = NSAttributedString(string: "Share", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 15), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.selectedColor()]))
////            navBarButton.layer.cornerRadius = 15
////            navBarButton.layer.masksToBounds = true
////            navBarButton.backgroundColor = UIColor.customRedColor()
//            navBarButton.setAttributedTitle(displayAttributed, for: .normal)
//            navBarButton.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
//            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: navBarButton)
            
//            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(handleShareNewPost))
        }
    }
    
    
    let buttonBar = UIView()
    var buttonBarPosition: NSLayoutConstraint?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        // Set for the Post up top
        self.automaticallyAdjustsScrollViewInsets = false

        self.setupNavigationItems()
        
        // Setup CollectionView for Post
        collectionView.register(NewListPhotoCell.self, forCellWithReuseIdentifier: postCellId)
        view.addSubview(collectionView)
//        collectionView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 1, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 180)
        collectionView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 1, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

        if self.showSummaryPost {
            collectionView.heightAnchor.constraint(equalToConstant: 180).isActive = true
        } else{
            collectionView.heightAnchor.constraint(equalToConstant: 0).isActive = true
        }
        collectionView.isScrollEnabled = false
        
        view.addSubview(addListView)
        addListView.anchor(top: collectionView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 1, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        addListView.backgroundColor = UIColor.white
        
        
        view.addSubview(addListButton)
        addListButton.anchor(top: nil, left: nil, bottom: nil, right: addListView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 30)
        addListButton.centerYAnchor.constraint(equalTo: addListView.centerYAnchor).isActive = true
        addListButtonWidth = addListButton.widthAnchor.constraint(equalToConstant: 120)
        addListButtonWidth?.isActive = true
        setAddListButtonWidth()
        
        setupSearchBar()
        view.addSubview(searchBar)
        searchBar.anchor(top: addListView.topAnchor, left: addListView.leftAnchor, bottom: addListView.bottomAnchor, right: addListButton.leftAnchor, paddingTop: 2, paddingLeft: 10, paddingBottom: 2, paddingRight: 0, width: 0, height: 0)
//        searchBar.centerYAnchor.constraint(equalTo: addListView.centerYAnchor).isActive = true
//
//        view.addSubview(addListTextField)
//        addListTextField.anchor(top: nil, left: addListView.leftAnchor, bottom: nil, right: addListButton.leftAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 5, width: 0, height: 30)
//        addListTextField.centerYAnchor.constraint(equalTo: addListView.centerYAnchor).isActive = true
//        addListTextField.placeholder = "New List Name"
//        addListTextField.backgroundColor = UIColor.white

        let sortSegmentView = UIView()
        sortSegmentView.backgroundColor = UIColor.white
        view.addSubview(sortSegmentView)
        sortSegmentView.anchor(top: addListView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        setupListSortSegment()
        
        view.addSubview(listSortSegment)
        listSortSegment.anchor(top: sortSegmentView.topAnchor, left: view.leftAnchor, bottom: sortSegmentView.bottomAnchor, right: view.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)
//        listSortSegment.centerYAnchor.constraint(equalTo: sortSegmentView.centerYAnchor).isActive = true
        
        buttonBar.backgroundColor = UIColor.ianLegitColor()
        
        let segmentWidth = (self.view.frame.width - 30) / 3
        
//        view.addSubview(buttonBar)
//        buttonBar.anchor(top: nil, left: nil, bottom: listSortSegment.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: segmentWidth, height: 5)
//        buttonBar.leftAnchor.constraint(lessThanOrEqualTo: listSortSegment.leftAnchor).isActive = true
//        buttonBar.rightAnchor.constraint(lessThanOrEqualTo: listSortSegment.rightAnchor).isActive = true
//        buttonBarPosition = buttonBar.leftAnchor.constraint(equalTo: listSortSegment.leftAnchor, constant: 5)
//        buttonBarPosition?.isActive = true
        
        listSortSegment.selectedSegmentIndex = sortOptions.firstIndex(of: selectedSort)!
//        self.underlineSegment(segment: sortOptions.firstIndex(of: selectedSort)!)

        
        tableView.register(TestListCell.self, forCellReuseIdentifier: listCellId)
        tableView.register(MainTabListCell.self, forCellReuseIdentifier: mainTabListCellId)
        tableView.allowsSelection = true
        tableView.allowsMultipleSelection = true

        view.addSubview(tableView)
        tableView.anchor(top: sortSegmentView.bottomAnchor, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshList), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.alwaysBounceVertical = true
        tableView.keyboardDismissMode = .onDrag
        
        setupLists()
        
        view.addSubview(nextButton)
        nextButton.anchor(top: nil, left: nil, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 35, paddingRight: 15, width: 0, height: 40)
        nextButton.sizeToFit()
        nextButton.layer.cornerRadius = 5
        nextButton.layer.masksToBounds = true
        nextButton.layer.borderWidth = 1
        nextButton.layer.borderColor = nextButton.tintColor.cgColor
        setupNextButton()
        self.selectedListCount = 0

        
    }
    
    func setupNextButton() {

     var newSelectedListCount = self.selectedListIds.count ?? 0
     var previousListCount = self.preExistingList?.count ?? 0
     var listChange = newSelectedListCount - previousListCount
        
        self.nextButton.backgroundColor = (listChange > 0) ? UIColor.mainBlue() : ((listChange < 0) ? UIColor.ianLegitColor() : UIColor.gray)
        self.nextButton.setTitleColor((listChange > 0) ? UIColor.white : UIColor.white, for: .normal)
        self.nextButton.tintColor = (listChange > 0) ? UIColor.white : UIColor.white

        var nextString = (listChange > 0) ? "  Tag \(listChange) Lists" : (listChange < 0 ? "  UnTag \(-listChange) Lists" : "  Tag List")
        self.nextButton.setTitle(nextString, for: .normal)
        self.nextButton.sizeToFit()
        self.nextButton.layer.borderColor = nextButton.tintColor.cgColor
        
        self.nextButton.isHidden = (viewListMode && self.uploadUser?.uid != CurrentUser.uid)

    }
    
    func setupSearchBar(){
        searchBar.delegate = self
        searchBar.tintColor = UIColor.ianLegitColor()
        searchBar.isTranslucent = false
        searchBar.searchBarStyle = .prominent
        searchBar.barTintColor = UIColor.white
        searchBar.layer.borderWidth = 1
        searchBar.layer.borderColor = UIColor.white.cgColor
        searchBar.backgroundColor = UIColor.white
        searchBar.backgroundImage = UIImage()
        definesPresentationContext = false
        
        searchBar.layer.masksToBounds = true
        searchBar.clipsToBounds = true
        
        var iconImage = #imageLiteral(resourceName: "search_tab_fill").withRenderingMode(.alwaysTemplate)
        searchBar.setImage(iconImage, for: .search, state: .normal)
        searchBar.setSerchTextcolor(color: UIColor.ianLegitColor())
        var searchTextField: UITextField? = searchBar.value(forKey: "searchField") as? UITextField
        if searchTextField!.responds(to: #selector(getter: UITextField.attributedPlaceholder)) {
            let attributeDict = [NSAttributedString.Key.foregroundColor: UIColor.gray]
            searchTextField!.attributedPlaceholder = NSAttributedString(string: "Search List", attributes: attributeDict)
        }
        
        let textFieldInsideUISearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.textColor = UIColor.ianLegitColor()
        //        textFieldInsideUISearchBar?.font = textFieldInsideUISearchBar?.font?.withSize(12)
        
        
        for s in searchBar.subviews[0].subviews {
            if s is UITextField {
                s.layer.borderWidth = 0.5
                s.layer.borderColor = UIColor.gray.cgColor
                s.layer.cornerRadius = 5
                s.clipsToBounds = true
                s.layer.backgroundColor = UIColor.white.cgColor
                s.backgroundColor = UIColor.white
            }
        }
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText.count == 0) {
            self.isFiltering = false
        } else {
            filterContentForSearchText(searchBar.text!)
        }
    }
    
    @objc func filterContentForSearchText(_ searchText: String) {
        // Filter List Table View
        self.isFiltering = searchText.count != 0
        
        displayList = fetchedList.filter({ (list) -> Bool in
            return list.name.lowercased().contains(searchText.lowercased()) || list.topEmojis.contains(searchText.lowercased())
        })
        displayList.sort { (p1, p2) -> Bool in
            ((p1.name.hasPrefix(searchText.lowercased())) ? 0 : 1) < ((p2.name.hasPrefix(searchText.lowercased())) ? 0 : 1)
        }
        self.tableView.reloadData()
    }

    func setupListSortSegment(){
        //  Add Sort Options
        listSortSegment = UISegmentedControl(items: sortOptions)
//        self.underlineSegment(segment: listSortSegment.selectedSegmentIndex)
        listSortSegment.addTarget(self, action: #selector(selectSort), for: .valueChanged)
        //        headerSortSegment.tintColor = UIColor(hexColor: "107896")
        listSortSegment.tintColor = UIColor.white
        listSortSegment.backgroundColor = UIColor.white
        listSortSegment.selectedSegmentTintColor = UIColor.ianLegitColor()

        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        listSortSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: 16), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
        listSortSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(font: .avenirNextBold, size: 16), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)
    }
    
//    func underlineSegment(segment: Int? = 0){
//
//        let segmentWidth = (self.view.frame.width - 30) / CGFloat(self.listSortSegment.numberOfSegments)
//        let tempX = self.buttonBar.frame.origin.x
//        UIView.animate(withDuration: 0.3) {
//            //            self.buttonBarPosition?.isActive = false
//            self.buttonBar.frame.origin.x = segmentWidth * CGFloat(segment ?? 0) + 5
//            self.buttonBarPosition?.constant = segmentWidth * CGFloat(segment ?? 0) + 5
//            self.buttonBarPosition?.isActive = true
//        }
//    }
    
    @objc func selectSort(sender: UISegmentedControl) {
        
        self.selectedSort = sortOptions[sender.selectedSegmentIndex]
        //        delegate?.headerSortSelected(sort: self.selectedSort)
        if tableView.visibleCells.count > 0 {
            let topIndex = IndexPath(row: 0, section: 0)
            tableView.scrollToRow(at: topIndex, at: .top, animated: true)
        }

        print("Selected Sort is ",self.selectedSort)
        
//        self.underlineSegment(segment: sender.selectedSegmentIndex)
    }
    
    @objc func refreshList(){
        self.selectedListIds = Array(self.preExistingList!.keys)
        self.setupLists()
//        self.tableView.reloadData()
        self.tableView.refreshControl?.endRefreshing()
    }
    
    func setupListsForUser() {
        guard let user = self.uploadUser else {return}
        self.fetchedList = []
        self.displayList = []
        
        Database.fetchCreatedListsForUser(userUid: user.uid) { (lists) in
            Database.sortList(inputList: lists, sortInput: self.selectedSort) { (sortedLists) in
                self.fetchedList = sortedLists
                if self.isFiltering && self.searchBar.text != nil{
                    self.filterContentForSearchText(self.searchBar.text!)
                } else {
                    self.displayList = self.fetchedList
                    print("Fetched \(sortedLists.count) For \(user.username) - SharePhotoListController")
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    
    func setupLists(){
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        self.fetchedList = []
        self.displayList = []

        Database.sortList(inputList: CurrentUser.lists, sortInput: self.selectedSort, completion: { (sortedList) in

            
            self.fetchedList = sortedList

            // If user is post creator, dont display bookmark, if not post creator, don't display legit
            if let deleteIndex = self.fetchedList.firstIndex(where: { (list) -> Bool in
                list.name == ((self.uploadPost?.creatorUID != uid) ? legitListName : bookmarkListName)
            }){
                self.fetchedList.remove(at: deleteIndex)
            }
            
            self.tableView.reloadData()
            }
        )
        
  
        // Unselect All List
        for list in self.fetchedList {
            list.isSelected = false
        }

        
        // Highlight Selected List if In Editing Post
        if self.isEditingPost || self.isBookmarkingPost {
//            if self.preExistingList?.count != 0 && self.preExistingList != nil {
                
            // RESELECT LISTS
//                for (listId, listName) in (self.preExistingList)!{
//                    if let index = fetchedList.firstIndex(where: { (list) -> Bool in
//                        return list.id == listId
//                    }) {
//                        fetchedList[index].isSelected = true
//                    }
//                }
//
//                for listId in self.selectedListIds {
//                    if let index = fetchedList.firstIndex(where: { (list) -> Bool in
//                        return list.id == listId
//                    }) {
//                        fetchedList[index].isSelected = true
//                    }
//                }
            
            for list in fetchedList {
                list.isSelected = self.selectedListIds.contains(list.id!)
            }
            
            fetchedList.sort { (l1, l2) -> Bool in
                var l1exist = self.preExistingList![l1.id!] != nil ? 1 : 0
                var l2exist = self.preExistingList![l2.id!] != nil ? 1 : 0
                return l1exist > l2exist
            }
                
            // SORT LISTS BY SELECTED
                var tempList: [List] = []
                for list in fetchedList {
                    if list.isSelected {
                        tempList.insert(list, at: 0)
                    } else {
                        tempList.append(list)
                    }
                }
                fetchedList = tempList
//            }
        }
        
        self.setupNavigationItems()
        
        
        if isFiltering && searchBar.text != nil{
            filterContentForSearchText(searchBar.text!)
        } else {
            self.displayList = self.fetchedList
            self.tableView.reloadData()
        }
        
    }
    
    
    var currentUploadingPostCheck: String?
    
    @objc func handleShareNewPost(){
        navigationItem.rightBarButtonItem?.isEnabled = false
        print("handleShareNewPost | Share Button DISABLED")
        
        if self.currentUploadingPostCheck == uploadPost?.caption {
            print("handleShareNewPost | Potential Double Upload | \(self.currentUploadingPostCheck)")
            return
        } else {
            self.currentUploadingPostCheck = uploadPost?.caption
        }
        
//        print("Selected List: \(self.selectedList)")
        if self.selectedListIds.count > 0 {
            // Add list id to post dictionary for display
            var listIds: [String:String]? = [:]
            
            for listId in self.selectedListIds {
                if let listName = self.fetchedList.first(where: { (list) -> Bool in
                    list.id == listId
                })?.name {
                    listIds![listName] = listName
                    if listName == legitListName {
                        uploadPostDictionary["isLegit"] = true
                    }
                }
//                listIds?.append(list.id!)
            }
            
            
            uploadPostDictionary["lists"] = listIds
            uploadPostDictionary["listCount"] = self.selectedListIds.count
        }
        
        SVProgressHUD.show(withStatus: "Sharing Post")

        Database.savePostToDatabase(uploadImages: uploadPost?.images, uploadDictionary: uploadPostDictionary, uploadLocation: uploadPostLocation, lists: self.selectedList){
            
            SVProgressHUD.dismiss()
            
            self.dismiss(animated: true, completion: {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                self.currentUploadingPostCheck = nil
                print("handleShareNewPost | Share Button ENABLED")
            })
            NotificationCenter.default.post(name: SharePhotoListController.updateFeedNotificationName, object: nil)
            NotificationCenter.default.post(name: SharePhotoListController.updateProfileFeedNotificationName, object: nil)
            NotificationCenter.default.post(name: SharePhotoListController.updateListFeedNotificationName, object: nil)
        }
    }
    
    func handleEditPost(){
        print("Selected List: \(self.selectedList)")
        var listIds: [String:String]? = [:]

        navigationItem.rightBarButtonItem?.isEnabled = false
        SVProgressHUD.show(withStatus: "Editing Post")

        if self.selectedListIds.count > 0 {
            // Add list id to post dictionary for display
            
            for listId in self.selectedListIds {
                if let listName = self.fetchedList.first(where: { (list) -> Bool in
                    list.id == listId
                })?.name {
                    listIds![listId] = listName
                    if listName == legitListName {
                        uploadPostDictionary["isLegit"] = true
                    }
                }
            }
                        
            uploadPostDictionary["lists"] = listIds
        }
        
        guard let postId = uploadPost?.id else {
            print("Edit Post: ERROR, No Post ID")
            return
        }
        
        guard let imageUrls = uploadPost?.imageUrls else {
            print("Edit Post: ERROR, No Image URL")
            return
        }
        
        Database.editPostToDatabase(imageUrls: imageUrls, postId: postId, uploadDictionary: uploadPostDictionary, uploadLocation: uploadPostLocation, prevPost: preEditPost) {
            
            // Update Post Cache
            var tempPost = self.uploadPost
            tempPost?.selectedListId = listIds
            tempPost?.creatorListId = listIds
            
            if (tempPost?.selectedListId?.count)! > 0 {
                tempPost?.hasPinned = true
            }

            postCache[(self.uploadPost?.id)!] = tempPost
            SVProgressHUD.dismiss()

            self.navigationController?.popToRootViewController(animated: true)
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            self.delegate?.refreshPost(post: tempPost!)
            NotificationCenter.default.post(name: SharePhotoListController.updateFeedNotificationName, object: nil)
            NotificationCenter.default.post(name: SharePhotoListController.updateProfileFeedNotificationName, object: nil)
            NotificationCenter.default.post(name: SharePhotoListController.updateListFeedNotificationName, object: nil)
            NotificationCenter.default.post(name: NewSinglePostView.editSinglePostNotification, object: nil)
//            NotificationCenter.default.post(name: SharePhotoListController.updateFeedNotificationName, object: nil)
            
        }
    }
    
    @objc func handleAddPostToList(){
        
        navigationItem.rightBarButtonItem?.isEnabled = false
        SVProgressHUD.show(withStatus: "Adding To List")

        if (Auth.auth().currentUser?.isAnonymous)!{
            print("Guest User Adding Post to List")
            let listAddDate = Date().timeIntervalSince1970
            for listId in self.selectedListIds {
            // Update Current User List
                if let listIndex = CurrentUser.lists.firstIndex(where: { (currentList) -> Bool in
                    currentList.id == listId
                }) {
                    if CurrentUser.lists[listIndex].postIds![(self.uploadPost?.id)!] == nil {
                        CurrentUser.lists[listIndex].postIds![(self.uploadPost?.id)!] = listAddDate
                    }
                }
            }
            
            // Update Post Cache
            self.finishUpdatingPost(post: self.uploadPost!)
        }
        
        else {
            guard let uid = Auth.auth().currentUser?.uid else {return}
            if (Auth.auth().currentUser?.isAnonymous)! {
                print("handleAddPostToList | Guest User Error")
                return
            }
            
            //  User Tagging Post to List
            var tempNewList: [String:String] = [:]
            for listId in self.selectedListIds {
                if let listName = self.fetchedList.first(where: { (list) -> Bool in
                    list.id == listId
                })?.name {
                    tempNewList[listId] = listName
                }
            }
            
//            uploadPost?.isLegit = tempNewList.values.contains(legitListName)
            if noUpload {
                uploadPost?.selectedListId = tempNewList
                guard let uploadPost = uploadPost else {return}
                self.delegate?.refreshPost(post: uploadPost)
                self.navigationController?.popViewController(animated: true)
            } else {
                Database.updateListforPost(post: uploadPost, newList: tempNewList, prevList: preExistingList) { (newPost) in
                    guard let newPost = newPost else {return}
                    self.delegate?.refreshPost(post: newPost)
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    SVProgressHUD.dismiss()
                    self.navigationController?.popViewController(animated: true)
                    NotificationCenter.default.post(name: SharePhotoListController.updateListFeedNotificationName, object: nil)
    //                NotificationCenter.default.post(name: SharePhotoListController.updateFeedNotificationName, object: nil)
                }
            }
        }
    }
    
    func finishUpdatingPost(post: Post){
        var tempNewList: [String:String] = [:]
        for listId in self.selectedListIds {
            if let listName = self.fetchedList.first(where: { (list) -> Bool in
                list.id == listId
            })?.name {
                tempNewList[listId] = listName
            }
        }
        
        var tempPost = post
        tempPost.selectedListId = tempNewList
        postCache[(post.id)!] = tempPost
        self.delegate?.refreshPost(post: tempPost)
        
        NotificationCenter.default.post(name: SharePhotoListController.updateListFeedNotificationName, object: nil)
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        self.navigationController?.popViewController(animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: postCellId, for: indexPath) as! NewListPhotoCell
        
        cell.bookmarkDate = uploadPost?.creationDate
        cell.post = uploadPost
        cell.delegate = self
        cell.currentImage = 1

        // Can't Be Selected
        cell.isSelected = false
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return CGSize(width: view.frame.width, height: 180)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        print("SharePhotoListController \(displayList.count + 1) List Cells")
        return displayList.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: listCellId, for: indexPath) as! TestListCell
        cell.selectionStyle = self.viewListMode ? .none : .default

    // LAST ITEM
        if indexPath.row == displayList.count {
            cell.refUser = CurrentUser.user
            cell.listnameLabel.text = "Add List"
            
            var newSelectedListCount = self.selectedListIds.count ?? 0
            var previousListCount = self.preExistingList?.count ?? 0
            var listChange = newSelectedListCount - previousListCount
            
            if self.viewListMode {
                let displayAttributed = NSAttributedString(string: "\(displayList.count) Total Lists", attributes: [NSAttributedString.Key.foregroundColor: UIColor.oldLegitColor(), NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 16)])
                cell.listnameLabel.attributedText = displayAttributed
                cell.listCountLabel.text = ""
                cell.socialStatsLabel.text = ""
                cell.isSelected = false
            }
            
            else if displayList.count == 0 {
                let displayAttributed = NSAttributedString(string: "Tap to Create A List One!", attributes: [NSAttributedString.Key.foregroundColor: UIColor.oldLegitColor(), NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 16)])

                cell.listnameLabel.attributedText = displayAttributed
                cell.listCountLabel.text = ""
                cell.socialStatsLabel.text = ""
                cell.isSelected = false

            } else {
                let displayAttributed = NSAttributedString(string: "Adding Post To \(listChange) Lists", attributes: [NSAttributedString.Key.foregroundColor: UIColor.oldLegitColor(), NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 16)])
                cell.listnameLabel.attributedText = displayAttributed
                cell.listCountLabel.text = ""
                cell.socialStatsLabel.text = ""
                cell.isSelected = false

            }
            cell.profileImageView.isHidden = true
        } else {
//            cell.refUser = CurrentUser.user
//            let temp_list = displayList[indexPath.row]
    //        temp_list.isSelected = (self.uploadPost?.selectedListId)![temp_list.id!] != nil
    //        temp_list.isSelected = (self.selectedList?.contains(where: { (list) -> Bool in
    //            list.id == temp_list.id
    //        }))! ?? false

//            cell.list = temp_list
//            cell.isSelected = temp_list.isSelected
//            cell.accessoryType = cell.isSelected ? UITableViewCell.AccessoryType.checkmark : UITableViewCell.AccessoryType.none
            
//            let cell = tableView.dequeueReusableCell(withIdentifier: newCellId, for: indexPath) as! UserAndListCell
            let listCell = tableView.dequeueReusableCell(withIdentifier: mainTabListCellId, for: indexPath) as! MainTabListCell
            let currentList = displayList[indexPath.row]
            listCell.list = currentList
            
            listCell.cellHeight?.constant = 70
            let bgColorView = UIView()
            bgColorView.backgroundColor = UIColor.mainBlue().withAlphaComponent(0.4)
            listCell.selectedBackgroundView = bgColorView
//            listCell.setSelected(currentList.isSelected, animated: true)
//            listCell.isSelected = selectedList?.contains(where: { (list) -> Bool in
//                list.id == currentList.id
//            }) ?? false
            
//            print("\(indexPath.item) \(listCell.isSelected) \(currentList.name) \(listCell.cellView.backgroundColor)")
            
//            cell.isSelected = currentList.isSelected
//            tableView.selectRow(at: IndexPath(row: indexPath.row, section: 0), animated: false, scrollPosition: UITableView.ScrollPosition.none)
//            cell.accessoryType = cell.isSelected ? UITableViewCell.AccessoryType.checkmark : UITableViewCell.AccessoryType.none


            return listCell

        }
        
        
        return cell
    }
    
    func confirmLegitListSelection(){
        let message = "Legit Posts MUST be in Your LegitList. Untagging posts from LegitList will un-legit your post. (Your Rating will remain the same)"
        let alert = UIAlertController(title: "LegitList", message: message, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "UnLegit", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction!) in
            if let legitRow = self.fetchedList.firstIndex(where: { (list) -> Bool in
                list.name == legitListName
            }){
                self.fetchedList[legitRow].isSelected = false
                self.uploadPost?.isLegit = false
                print("UnLegit Post")
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: { (action: UIAlertAction!) in
            if let legitRow = self.fetchedList.firstIndex(where: { (list) -> Bool in
                list.name == legitListName
            }){
                let indexPath = IndexPath(row: legitRow, section: 0)
                self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: UITableView.ScrollPosition.none)
                self.fetchedList[legitRow].isSelected = true
                self.uploadPost?.isLegit = true
                print("Keep Legit Post")
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row >= displayList.count {return}
//        print("TEST", indexPath.row, displayList.count)
        
        let currentList = displayList[indexPath.row]
        if self.selectedListIds.contains(currentList.id!) {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }
//        cell.setSelected(self.selectedListIds.contains(currentList.id!), animated: true)
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.viewListMode {
            let selectedListTemp = displayList[indexPath.row]
            let selectedDisplayListId = displayList[indexPath.row].id
            self.extTapList(list: selectedListTemp)
        }
        
        else if noLocationInd {
            
            self.alert(title: "Unable to Add Post to List", message: "Post must have location to be added to Lists. Current Location: \(self.uploadPost?.locationGPS)")
            self.tableView.deselectRow(at: indexPath, animated: false)
        
        } else {
            
            if indexPath.row == displayList.count {
                // LAST ROW
                if self.viewListMode {
                    print("viewListMode")
                }
                else if displayList.count == 0 {
                    // CREATE LIST
                    self.initAddList()
                } else {
                    // TAG LIST
                    self.handleNext()
                }
            } else {
                let selectedListTemp = displayList[indexPath.row]
                let selectedDisplayListId = displayList[indexPath.row].id
                
            // UPDATE FETCHED LIST
                if let selectedIndex = self.fetchedList.firstIndex(where: {$0.id == selectedDisplayListId}) {
                    fetchedList[selectedIndex].isSelected = !fetchedList[selectedIndex].isSelected
                }
//                print("TableView Selected :", indexPath.row, tableView.cellForRow(at: indexPath)?.isSelected)
                
            // UPDATE DISPLAY LIST
                if !self.selectedListIds.contains(selectedListTemp.id!) {
                    self.selectedListIds.append(selectedListTemp.id!)
                    print("\(self.selectedListIds.count) Selected List: Added \(selectedListTemp.name)")
                }
                self.selectedListCount = self.selectedListIds.count ?? 0
                
//                print("Selected Lists | \(self.selectedList) | \(displayList[indexPath.row].id) | \(displayList[indexPath.row].isSelected) | \(self.selectedListCount) Lists Tag")
                self.setupNextButton()
                self.setupNavigationItems()
                
//                self.tableView.reloadRows(at: [indexPath], with: .none)
//                self.delegate?.refreshPost(post: uploadPost!)
            }
            

 

//            let containListId = self.selectedList?.contains(where: {$0.id == selectedDisplayListId}) ?? false
            
            
//            self.selectedList?.append(displayList[indexPath.row])

            
//            tableView.cellForRow(at: indexPath)?.accessoryType = UITableViewCellAccessoryType.checkmark
//            if let selectedIndex = self.selectedList?.index(where: { (list) -> Bool in
//                list.id == selectedListId
//            }){
//                if
//            }
//
//            if displayList[indexPath.row].isSelected {
//                self.selectedli
//            }
        
        }
        


    }
    
//    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
//        if displayList[indexPath.row].name == legitListName && (self.uploadPost?.isLegit)!{
//            let message = "Legit Posts MUST be in Your LegitList. Untagging posts from LegitList will un-legit your post. (Your Rating will remain the same)"
//            let alert = UIAlertController(title: "LegitList", message: message, preferredStyle: UIAlertControllerStyle.alert)
//            alert.addAction(UIAlertAction(title: "UnLegit", style: UIAlertActionStyle.cancel, handler: { (action: UIAlertAction!) in
//                if let legitRow = self.displayList.index(where: { (list) -> Bool in
//                    list.name == legitListName
//                }){
//                    self.displayList[legitRow].isSelected = false
//                    self.uploadPost?.isLegit = false
//                    self.collectionView.reloadData()
//                }
//            }))
//            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
//            self.present(alert, animated: true, completion: nil)
//            return false
//        } else{
//            return true
//        }
//    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if displayList[indexPath.row].name == legitListName {
            self.confirmLegitListSelection()
        } else {
            displayList[indexPath.row].isSelected = false
        }
//        tableView.cellForRow(at: indexPath)?.accessoryType = UITableViewCellAccessoryType.none
//        self.tableView.reloadRows(at: [indexPath], with: .none)
        
        // UPDATE DISPLAY LIST
            if self.selectedListIds.contains(displayList[indexPath.row].id!) {
                self.selectedListIds.removeAll { (id) -> Bool in
                    id == displayList[indexPath.row].id
                }
                print("\(self.selectedListIds.count) Selected List: Removed \(displayList[indexPath.row].name)")
            }
        
        self.setupNextButton()
        self.setupNavigationItems()
        print("TableView DE-selected :", indexPath.row)

    }
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 50
//    }


    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            // Check For Default List
            if (defaultListNames.contains(where: { (listNames) -> Bool in
                listNames == self.displayList[indexPath.row].name})){
                self.alert(title: "Delete List Error", message: "Cannot Delete Default List: \(self.displayList[indexPath.row].name)")
                return
            }
            var list = self.displayList[indexPath.row]

            self.displayList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)

            // Delete List in Database
            Database.deleteList(uploadList: list)

        }

        let edit = UITableViewRowAction(style: .default, title: "Edit") { (action, indexPath) in
            var list = self.displayList[indexPath.row]
            var orig_listname = self.displayList[indexPath.row].name
            
            // Check For Default List
            if (defaultListNames.contains(where: { (listNames) -> Bool in
                listNames == self.displayList[indexPath.row].name})){
                self.alert(title: "Edit List Error", message: "Cannot Edit Default List: \(self.displayList[indexPath.row].name)")
                return
            }

            print("I want to change: \(self.displayList[indexPath.row])")

            //1. Create the alert controller.
            let alert = UIAlertController(title: "Edit List", message: "Enter a New Name", preferredStyle: .alert)

            //2. Add the text field. You can configure it however you need.
            alert.addTextField { (textField) in
                textField.text = self.displayList[indexPath.row].name
            }

            // 3. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
                print("Text field: \(textField?.text)")
                
                if (textField?.text)! != orig_listname {
                    self.checkListName(listName: (textField?.text)!, completion: { (listName) in
                        list.name = listName
                    })
                } else {
                    print("List Name No Change")
                }
                
                // 4. Change Privacy Settings
                let optionsAlert = UIAlertController(title: "Edit List", message: "Edit Privacy Setting", preferredStyle: UIAlertController.Style.alert)
            
                optionsAlert.addAction(UIAlertAction(title: "Public", style: .default, handler: { (action: UIAlertAction!) in
                    list.publicList = 1
                    self.handleUpdateList(list: list)
                }))
                
            
                optionsAlert.addAction(UIAlertAction(title: "Private", style: .default, handler: { (action: UIAlertAction!) in
                    list.publicList = 0
                    self.handleUpdateList(list: list)

                }))
            
                optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                    print("Handle Cancel Logic here")
                }))
            
                self.present(optionsAlert, animated: true, completion: {
                })
                
            }))

            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
        }

        edit.backgroundColor = UIColor.lightGray
        return [delete, edit]

    }
    
    func handleUpdateList(list: List){
        if let index = self.displayList.firstIndex(where: { (tempList) -> Bool in
            tempList.id == list.id!
        }){
            print("Replacing Current List in Display")
            self.displayList[index] = list
        }
        self.tableView.reloadData()
        Database.createList(uploadList: list){}
        CurrentUser.addList(list: list)
    }
    
    
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        self.tableView.reloadData()
    }
    
    
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
       
        return UITableViewCell.EditingStyle.none
//
//        // Prevents Full Swipe Delete
//        if tableView.isEditing{
//            return .delete
//        }
//
//        return .none
    }
    
    // Top List Photo Cell Delegates
    // Only used for tapping on picture to expand
    
    func didTapUser(post: Post) {
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = post.user.uid
        
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapLocation(post: Post) {
        
    }
    
    func didTapMessage(post: Post) {
        
    }
    
    func refreshPost(post: Post) {
        
    }
    
    func deletePostFromList(post: Post) {
        
    }
    
    func didTapPicture(post: Post) {
        if self.isBookmarkingPost {
            let pictureController = SinglePostView()
            pictureController.post = post
            navigationController?.pushViewController(pictureController, animated: true)
        } else {
            expandImage()
        }
    }
    
    func expandImage(){
        var images = [SKPhoto]()
        
        guard let selectedImages = uploadPost?.images else {return}
        for image in selectedImages {
            let photo = SKPhoto.photoWithImage(image)// add some UIImage
            images.append(photo)
        }
        
        // 2. create PhotoBrowser Instance, and present from your viewController.
        SKPhotoBrowserOptions.displayDeleteButton = false
        let browser = SKPhotoBrowser(photos: images)
        browser.delegate = self
        browser.initializePageIndex(0)
        present(browser, animated: true, completion: {})
    }
    
    func didTapExtraTag(tagName: String, tagId: String, post: Post) {
        
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
