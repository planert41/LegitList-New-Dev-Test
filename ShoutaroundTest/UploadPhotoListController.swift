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


protocol UploadPhotoListControllerDelegate {
    func refreshPost(post:Post)
}


class UploadPhotoListController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, ListPhotoCellDelegate, SKPhotoBrowserDelegate, NewListPhotoCellDelegate, UISearchBarDelegate, UITextViewDelegate, UploadPhotoFooterDelegate, AutoTagTableViewControllerDelegate, AddTagSearchControllerDelegate {

    
    func didTapListCancel(post:Post) {
        
    }
    
    
    func didTapComment(post: Post) {
        // Disable Comment From Here
    }
    
    func didTapBookmark(post: Post) {
        // Disable Bookmark from here
    }
    
    
    // 3 Modes: Add Post, Edit Post, Bookmarking Post (Not creator UID)
    
    var delegate: UploadPhotoListControllerDelegate?
    
    var isFiltering: Bool = false {
        didSet{
            self.tableView.reloadData()
        }
    }
    
    var isEditingPost: Bool = false {
        didSet{
            setupNavigationItems()
        }
    }
    var preEditPost: Post? = nil
    var preExistingList: [String:String]? = [:]
    
    func checkLists(){
        var currentSelectedListIds: [String] = []
        for (key,value) in preExistingList! {
            currentSelectedListIds.append(key)
        }
        
        for list in self.displayList {
            list.isSelected = currentSelectedListIds.contains(list.id!)
        }
        self.tableView.reloadData()
    }
    
    var isBookmarkingPost: Bool = false {
        didSet{
            setupBookmarkingView()
        }
    }
    
    var uploadPostDictionary: [String: Any] = [:]
    var uploadPostLocation: CLLocation? = nil
    var uploadPost: Post? = nil {
        didSet{
            self.uploadPostDictionary = (self.uploadPost?.dictionary())!
            
            
            self.preExistingList = uploadPost?.selectedListId
            self.setupLists()
            
            if uploadPost?.creatorUID == Auth.auth().currentUser?.uid {
                self.preEditPost = uploadPost
            }
            
            self.selectedImages = uploadPost?.images
            self.selectedImageUrls = uploadPost?.imageUrls
            self.updateScrollImages()
            self.selectedAddTags = uploadPost?.autoTagEmojiTags ?? []
            
            // PRICE
            self.selectPostPrice = uploadPost?.price
            
            // ADDITIONAL TAGS
            self.selectedAddTags = uploadPost?.autoTagEmojiTags ?? []
            setupAdditionalTags()
            
            self.selectedListIds = []
            for (list, date) in self.uploadPost?.selectedListId ?? [:] {
                self.selectedListIds.append(list)
            }
            
            // Refreshes Current User Lists
            collectionView.reloadData()
            self.noLocationInd = (uploadPost?.locationGPS == nil)
            
            self.bookmarkView.uploadPost = uploadPost
            self.bookmarkView.isBookmarkingPost = true
            
            
        }
    }
    
    
    
    func setupBookmarkingView(){
        print("setupBookmarkingView | UploadPhotoListController")
        self.listFullScreen?.isActive = self.isBookmarkingPost
        self.footerView.isHidden = self.isBookmarkingPost
        self.toggleListHeight?.isActive = !self.isBookmarkingPost
        self.listHeight?.constant = self.view.bounds.height - 400
        self.scrollview.isScrollEnabled = !self.isBookmarkingPost
        self.captionTextView.isEditable = !self.isBookmarkingPost
        self.closeListButton.isHidden = self.isBookmarkingPost
        
        self.captionTextView.backgroundColor = isBookmarkingPost ? UIColor.clear : UIColor.white
        self.captionTextView.layer.borderWidth = isBookmarkingPost ? 0  : 1
        
        setupNavigationItems()
    }
    
    
    
    func updatePostDic(){
    
    // PRICE
        let price = self.selectPostPrice ?? nil
        
    // AutoTag Emojis
        var autoTagEmojis: [String] = []
        var autoTagEmojisDict: [String] = []
        
        for tag in self.selectedAddTags {
            if tag.isSingleEmoji {
                autoTagEmojis.append(tag)
                autoTagEmojisDict.append((EmojiDictionary[tag] ?? "").capitalizingFirstLetter())
            } else {
                autoTagEmojis.append((ReverseEmojiDictionary[tag] ?? ""))
                autoTagEmojisDict.append(tag)
            }
        }
        
    // CAPTION
        var caption = captionTextView.text
        if caption == captionDefaultString {caption = nil}
        
        // SELECTED LIST
        var listIds: [String:String]? = [:]

        if self.selectedList != nil {
            // Add list id to post dictionary for display
            for list in self.selectedList! {
                listIds![list.id!] = list.name
            }
        }
        
        let imageURLS = uploadPost?.imageUrls ?? []
        let smallImageURLS = uploadPost?.smallImageUrl ?? nil

        
    // ONLY UPDATE IF IS POST CREATOR USER
        
        if uploadPost?.user.uid == Auth.auth().currentUser?.uid && !isBookmarkingPost {
            uploadPostDictionary["price"] = [price]
            uploadPostDictionary["autoTagEmojis"] = autoTagEmojis
            uploadPostDictionary["autoTagEmojisDict"] = autoTagEmojisDict
            uploadPostDictionary["caption"] = caption
            uploadPostDictionary["lists"] = listIds
            uploadPostDictionary["listCount"] = self.selectedList!.count
            uploadPostDictionary["smallImageLink"] = smallImageURLS
            uploadPostDictionary["imageUrls"] = imageURLS

        }




        
    }
    
    
    
    var bookmarkList: List = emptyBookmarkList
    var legitList: List = emptyLegitList
    var fetchedList: [List] = []
    var displayList: [List] = []
    var selectedList: [List]? {
        return fetchedList.filter { return $0.isSelected }
    }
    
    var selectedListIds: [String] = []
    var noLocationInd: Bool = true
    
    let postCellId = "PostCellId"
    let listCellId = "ListCellId"
    
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
        view.backgroundColor = UIColor.clear
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
        let button = UIButton()
        button.setTitle("MAKE A NEW LIST", for: .normal)
        button.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 12)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        button.backgroundColor = UIColor.white
        button.layer.borderWidth = 1
        button.titleLabel?.textAlignment = NSTextAlignment.left
        button.layer.borderColor = UIColor.rgb(red: 221, green: 221, blue: 221).cgColor
        button.addTarget(self, action: #selector(initAddList), for: .touchUpInside)
        return button
    } ()
    
    let closeListButton: UIButton = {
        let button = UIButton()
        button.setTitle("CLOSE", for: .normal)
        button.setImage(#imageLiteral(resourceName: "upvote_selected").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.ianLegitColor()
        button.setTitleColor(UIColor.ianBlackColor(), for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 12)
        button.titleLabel?.textAlignment = NSTextAlignment.left
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        button.backgroundColor = UIColor.rgb(red: 249, green: 249, blue: 249)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.rgb(red: 221, green: 221, blue: 221).cgColor
        button.addTarget(self, action: #selector(toggleList), for: .touchUpInside)
        return button
    } ()
    
    let addListHeader: UIView = {
        let view = UIView()
        view.layer.borderColor = UIColor.ianLegitColor().cgColor
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 1
        view.backgroundColor = UIColor.white
        view.isUserInteractionEnabled = true
        return view
    }()

    let addListHeaderText: UIButton = {
        let button = UIButton()
        button.setTitle("", for: .normal)
        button.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 12)
        button.isUserInteractionEnabled = true
        return button
    }()
    
    let addListHeaderIcon: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "downvote_selected").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.ianLegitColor()
        button.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 12)
        button.isUserInteractionEnabled = true
        return button
    }()
    
    
    var isListShowing = true
    
    @objc func toggleList(){
        if self.isBookmarkingPost {return}
        if isListShowing {
            hideList()
        } else {
            showList()
        }
        addListHeaderIcon.setImage((isListShowing ? #imageLiteral(resourceName: "upvote_selected") :  #imageLiteral(resourceName: "downvote_selected")).withRenderingMode(.alwaysTemplate), for: .normal)
        
    }
    
    func showList(){
        self.setupListText()
        scrollview.isScrollEnabled = true
        isListShowing = true

        UIView.animate(withDuration: 0.8) {
            self.listHeight?.constant = CGFloat(min(self.displayList.count,5) * 60)
            self.listHeight?.isActive = true
            self.toggleListHeight?.constant = CGFloat(min(self.displayList.count,5) * 60) + 40 + 40
            self.toggleListHeight?.isActive = true
        }

        print("Show List | UploadPhotoListController | \(self.toggleListHeight?.constant)")

//        view.layoutIfNeeded()
    }
    
    func hideList(){
        print("Hide List | UploadPhotoListController ")

        scrollview.setContentOffset(CGPoint.zero, animated: true)
        scrollview.isScrollEnabled = false
        isListShowing = false

        UIView.animate(withDuration: 0.8) {
            self.toggleListHeight?.constant = 0
        }
    }
    
    func setupListText(){
        guard let listCount = selectedList?.count else {
            addListHeaderText.setTitle("ADD TO LIST", for: .normal)
            return}
        
        let headerString = (listCount == 0) ? "ADD TO LIST" : "ADDED TO \(listCount) LIST"
        addListHeaderText.setTitle(headerString, for: .normal)
    }
    
    var toggleListHeight:NSLayoutConstraint?
    var listHeight:NSLayoutConstraint?
    var addTagHeight:NSLayoutConstraint?
    var listFullScreen: NSLayoutConstraint?
    
    
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
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
        
        
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
            self.setupLists()
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        self.addListTextField.resignFirstResponder()
        

        //        print("Disappear")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var contentRect = CGRect.zero
        for view: UIView in scrollview.subviews {
            contentRect = contentRect.union(view.frame)
        }
        contentRect.size.width = self.view.frame.width
        contentRect.size.height = contentRect.size.height + 30
        scrollview.contentSize = contentRect.size

//        print("UploadPhotoListController | viewDidLayoutSubviews | ScrollView Size ",scrollview.contentSize)
        //        print("PhotoImageView ", photoImageScrollView.contentSize)

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
        tv.estimatedRowHeight = 70
        tv.allowsMultipleSelection = true
        return tv
    }()
    
    static let updateFeedNotificationName = NSNotification.Name(rawValue: "UpdateFeed")
    static let updateProfileFeedNotificationName = NSNotification.Name(rawValue: "UpdateProfileFeed")
    static let updateListFeedNotificationName = NSNotification.Name(rawValue: "UpdateListFeed")
    static let createdNewPostNotificationName = NSNotification.Name(rawValue: "Create New Post")
    
    var showSummaryPost: Bool = false
    
    @objc func handleNext(){
        self.updatePostDic()
        
        if self.isEditingPost {
            self.handleEditPost()
        } else if self.isBookmarkingPost {
            self.handleAddPostToList()
        } else {
            self.handleShareNewPost()
        }
    }
    
    
    func setupNavigationItems(){
        // Setup Navigation
        //        print("SharePhotoList | Setup Navigation Items")
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationController?.navigationBar.tintColor = UIColor.ianLegitColor()
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)

        navigationController?.navigationBar.barTintColor = UIColor.white
        let rectPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 5))
        UIColor.white.setFill()
        rectPath.fill()
        let finalImg = UIGraphicsGetImageFromCurrentImageContext()
        navigationController?.navigationBar.shadowImage = finalImg
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.view.backgroundColor = UIColor.white

        self.setNeedsStatusBarAppearanceUpdate()

        navigationController?.view.backgroundColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.font.rawValue: UIFont(name: "Poppins-Bold", size: 18), NSAttributedString.Key.foregroundColor.rawValue: UIColor.ianLegitColor()])
        navigationController?.navigationBar.layoutIfNeeded()

        // Nav Back Buttons
        let navBackButton = navBackButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        navBackButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        navBackButton.setTitleColor(UIColor.ianBlackColor(), for: .normal)
        navBackButton.backgroundColor = UIColor.clear
        let barButton2 = UIBarButtonItem.init(customView: navBackButton)
        self.navigationItem.leftBarButtonItem = barButton2
        
        
        // EDIT POST
        if self.isEditingPost
        {
            // Nav Edit Button
            let navEditButton = NavButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            navEditButton.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
            navEditButton.setTitle("Edit Post", for: .normal)
            navEditButton.setTitleColor(UIColor.ianBlackColor(), for: .normal)
            navEditButton.backgroundColor = UIColor.clear
            let barButton2 = UIBarButtonItem.init(customView: navEditButton)
            self.navigationItem.rightBarButtonItem = barButton2
//            navigationItem.title = "Edit Post"
            
            let customFont = UIFont(name: "Poppins-Bold", size: 18)
            let headerTitle = NSAttributedString(string: "", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: customFont])
            let navLabel = UILabel()
            navLabel.attributedText = headerTitle
            navigationItem.titleView = navLabel
            
            

        }
            
            // ADDING POST TO LIST
        else if self.isBookmarkingPost
        {
            var displayString = ""
            
            var newSelectedListCount = self.selectedList?.count ?? 0
            //            for list in self.displayList {
            //                newSelectedListCount += list.isSelected ? 1 : 0
            //            }
            var previousListCount = self.preExistingList?.count ?? 0
            var listChange = newSelectedListCount - previousListCount
            
            if listChange > 0 {
                displayString += "Add To \(listChange) Lists"
            } else if listChange < 0 {
                displayString += "Untag \(-listChange) Lists"
            } else {
                displayString += "Add To List"
            }
            
            
            // Nav Tag Button
            let navTagButton = NavButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            navTagButton.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
            navTagButton.setTitle(displayString, for: .normal)
            navTagButton.backgroundColor = UIColor.clear
            let barButton2 = UIBarButtonItem.init(customView: navTagButton)
            self.navigationItem.rightBarButtonItem = barButton2
            
            let customFont = UIFont(name: "Poppins-Bold", size: 18)
            let headerTitle = NSAttributedString(string: "", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: customFont])
            let navLabel = UILabel()
            navLabel.attributedText = headerTitle
            navigationItem.titleView = navLabel
            
//            navigationItem.title = "Bookmarking Post"

        }
            
            // NEW POST
            
        else {
            // Nav Share Button
            let navShareButton = NavButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            navShareButton.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
            navShareButton.setTitle("Share Post", for: .normal)
            let barButton2 = UIBarButtonItem.init(customView: navShareButton)
            self.navigationItem.rightBarButtonItem = barButton2
            navigationItem.title = "Create Post"

        }
    }
    
    
    let buttonBar = UIView()
    var buttonBarPosition: NSLayoutConstraint?

    lazy var selectPostPriceHeader: UILabel = {
        let ul = UILabel()
        ul.text = "Meal Price (Per Person)"
        ul.font = UIFont(font: .avenirNextMedium, size: 14)
        ul.textColor = UIColor.ianBlackColor()
        return ul
    }()
    var selectedPostPriceIndex: Int? = nil
    var selectPostPrice: String? = nil {
        didSet {
            if let selectPostPrice = selectPostPrice {
                guard let index = UploadPostPriceDefault.firstIndex(of: selectPostPrice) else {return}
                self.selectedPostPriceIndex = index
                self.postPriceSegment.selectedSegmentIndex = index
            } else {
                self.selectedPostPriceIndex = nil
            }
        }
    }
    
    var postPriceSegment: ReselectableSegmentedControl = {
        var segment = ReselectableSegmentedControl(items: UploadPostPriceDefault)

        segment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextBold, size: 14)], for: .normal)
        segment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextBold, size: 14)], for: .selected)
        segment.addTarget(self, action: #selector(handleSelectPostPrice), for: .valueChanged)
        segment.tintColor = UIColor.ianLegitColor()
        segment.selectedSegmentIndex = UISegmentedControl.noSegment
        return segment
    }()
    
    @objc func handleSelectPostPrice(sender: UISegmentedControl) {
        if (sender.selectedSegmentIndex == self.selectedPostPriceIndex) {
            sender.selectedSegmentIndex =  UISegmentedControl.noSegment
            self.selectPostPrice = nil
        }
        else {
            self.selectPostPrice = UploadPostPriceDefault[sender.selectedSegmentIndex]
        }
        print("Selected Time is ",self.selectPostPrice)
    }
    
    
    lazy var additionalTagHeader: UILabel = {
        let ul = UILabel()
        ul.text = "Additional Tags"
        ul.font = UIFont(font: .avenirNextMedium, size: 14)
        ul.textColor = UIColor.ianBlackColor()
        return ul
    }()
    
    var additionalTagCollectionView: UICollectionView = {
        let uploadLocationTagList = UploadLocationTagList()
        uploadLocationTagList.scrollDirection = UICollectionView.ScrollDirection.vertical
        uploadLocationTagList.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        var cv = UICollectionView(frame: .zero, collectionViewLayout: uploadLocationTagList)
        return cv
    }()
    
    let searchAddTagButton: UIButton = {
        let button = UIButton()
        
        var iconImage = #imageLiteral(resourceName: "search_tab_fill").withRenderingMode(.alwaysTemplate)
        button.setImage(iconImage, for: .normal)
        button.tintColor = UIColor.ianLegitColor()
        button.addTarget(self, action: #selector(openAutoTag(sender:)), for: .touchUpInside)
        button.tag = 0
        return button
    } ()
    
    @objc func openAutoTag(sender : UIButton){
        let autoTag = AddTagSearchController()
        autoTag.delegate = self
        autoTag.selectedScope = 0
        autoTag.selectedTags = self.selectedAddTags
        
        self.navigationController?.pushViewController(autoTag, animated: true)
    }
    
    func additionalTagSelected(tags: [String]){
        print("UploadPhotoListController | Selected Tags: \(tags)")
        self.selectedAddTags = tags
        self.setupAdditionalTags()
//        self.reloadAddTag()

    }
    
    func autoTagSelected(scope: Int, tag_selected: [String]?) {
        self.selectedAddTags = tag_selected ?? []
        self.reloadAddTag()
    }
    
    
    
    let scrollview: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = UIColor.rgb(red: 249, green: 249, blue: 249)
        sv.isScrollEnabled = true
        sv.showsVerticalScrollIndicator = false
        return sv
    }()
    

    let bookmarkView = SharePhotoListController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.rgb(red: 249, green: 249, blue: 249)

        
        // Set for the Post up top
        self.automaticallyAdjustsScrollViewInsets = false

        self.setupNavigationItems()
        setupImageCaption()
        
        
        scrollview.frame = view.frame
        scrollview.contentSize = CGSize(width: view.bounds.width, height: min(800, view.bounds.height))
        scrollview.isScrollEnabled = true
        
        view.addSubview(scrollview)
        scrollview.anchor(top: imageContainerView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        scrollview.backgroundColor = UIColor.yellow
        // THIS CODE MAKES SCROLLVIEW GO ALL THE WAY TO THE TOP
//        scrollview.contentInsetAdjustmentBehavior = .never
        
        scrollview.addSubview(addListHeader)
        addListHeader.anchor(top: scrollview.topAnchor, left: imageScrollView.leftAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 180, height: 35)
        addListHeader.isUserInteractionEnabled = true
        addListHeader.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleList)))

        scrollview.addSubview(addListHeaderText)
        addListHeaderText.anchor(top: nil, left: addListHeader.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        addListHeaderText.centerYAnchor.constraint(equalTo: addListHeader.centerYAnchor).isActive = true
        addListHeaderText.isUserInteractionEnabled = true
        addListHeaderText.addTarget(self, action: #selector(toggleList), for: .touchUpInside)

        scrollview.addSubview(addListHeaderIcon)
        addListHeaderIcon.anchor(top: nil, left: nil, bottom: nil, right: addListHeader.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 15, height: 15)
        addListHeaderIcon.centerYAnchor.constraint(equalTo: addListHeader.centerYAnchor).isActive = true
        addListHeaderIcon.isUserInteractionEnabled = true
        addListHeaderIcon.addTarget(self, action: #selector(toggleList), for: .touchUpInside)

// LIST TABLE
        scrollview.addSubview(addListView)
        addListView.anchor(top: addListHeader.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        listFullScreen = addListView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor, constant: 0)
        
        addListView.layer.applySketchShadow()
        addListView.layer.cornerRadius = 5
        addListView.layer.masksToBounds = true
        toggleListHeight = addListView.heightAnchor.constraint(equalToConstant: 0)
        toggleListHeight?.isActive = true
        
        
        addListView.addSubview(closeListButton)
        closeListButton.anchor(top: nil, left: addListView.leftAnchor, bottom: addListView.bottomAnchor, right: addListView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
        
        addListView.addSubview(addListButton)
        addListButton.anchor(top: nil, left: addListView.leftAnchor, bottom: nil, right: addListView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)

        
        addListView.addSubview(tableView)
        tableView.register(UploadPhotoToListCell.self, forCellReuseIdentifier: listCellId)
        tableView.anchor(top: addListView.topAnchor, left: addListView.leftAnchor, bottom: addListButton.topAnchor, right: addListView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        listHeight = tableView.heightAnchor.constraint(equalToConstant: 0)
        listHeight?.isActive = true
//        setupLists()
        showList()
        

        
// PRICE SEGMENT
        scrollview.addSubview(selectPostPriceHeader)
        selectPostPriceHeader.anchor(top: addListView.bottomAnchor, left: imageScrollView.leftAnchor, bottom: nil, right: nil, paddingTop: 25, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        selectPostPriceHeader.sizeToFit()
        
        scrollview.addSubview(postPriceSegment)
        postPriceSegment.anchor(top: selectPostPriceHeader.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 4, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 30)
        
        
// ADDITIONAL TAGS
        scrollview.addSubview(additionalTagHeader)
        additionalTagHeader.anchor(top: postPriceSegment.bottomAnchor, left: postPriceSegment.leftAnchor, bottom: nil, right: nil, paddingTop: 30, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        additionalTagHeader.sizeToFit()
        
        scrollview.addSubview(searchAddTagButton)
        searchAddTagButton.anchor(top: nil, left: additionalTagHeader.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 25, height: 25)
        searchAddTagButton.centerYAnchor.constraint(equalTo: additionalTagHeader.centerYAnchor).isActive = true
        
        
        scrollview.addSubview(additionalTagCollectionView)
        let width = self.view.frame.width - 15 - 15
        additionalTagCollectionView.anchor(top: additionalTagHeader.bottomAnchor, left: postPriceSegment.leftAnchor, bottom: nil, right: postPriceSegment.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: width, height: 0)
        additionalTagCollectionView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
        addTagHeight = additionalTagCollectionView.heightAnchor.constraint(equalToConstant: 70)
        addTagHeight!.priority = UILayoutPriority.init(rawValue: 999)
        addTagHeight!.isActive = true

        addFooter()
    
//        additionalTagCollectionView.bottomAnchor.constraint(equalTo: scrollview.bottomAnchor).isActive = true

        
//        let addTagBottomAnchor = additionalTagCollectionView.bottomAnchor.constraint(equalTo: scrollview.bottomAnchor, constant: 0)
//        addTagBottomAnchor.priority = UILayoutPriority.init(rawValue: 999)
//        addTagBottomAnchor.isActive = true


        setupAdditionalTags()


    }
    
    func reloadAddTag(){

        additionalTagCollectionView.collectionViewLayout.invalidateLayout()
        additionalTagCollectionView.reloadData()
        additionalTagCollectionView.sizeToFit()
        
        self.view.layoutIfNeeded()

        
        let height = additionalTagCollectionView.collectionViewLayout.collectionViewContentSize.height
        let width = additionalTagCollectionView.collectionViewLayout.collectionViewContentSize.width
//        let calcHeight = ceil(CGdisplayedAddTags.count / 3) * 30
//        additionalTagCollectionView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width - 15 - 15, height: height)
        
        self.addTagHeight?.constant = height
        //print("AddtagHeight H: \(height) , W: \(width) | \(displayedAddTags.count)")
    }
    
    let autoTagDetailId = "AutoTagDetail"
    
    let addLinkView = UIView()
    
    var urlLink: String? = nil {
        didSet {
        }
    }
    
    let addLinkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("", for: .normal)
        button.titleLabel?.font = UIFont(font: .avenirNextDemiBold, size: 12)
        button.setTitleColor(UIColor.darkGray, for: .normal)
        button.setImage(#imageLiteral(resourceName: "link_filled").withRenderingMode(.alwaysOriginal), for: .normal)
        //        button.addTarget(self, action: #selector(openAutoTag(sender:)), for: .touchUpInside)
        button.tag = 0
        button.alpha = 0.8
        button.backgroundColor = UIColor.clear
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 0
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        return button
    } ()
    
    lazy var linkInput: PaddedTextField = {
        let tf = PaddedTextField()
        tf.font = UIFont.systemFont(ofSize: 14.0)
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.gray.cgColor
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.placeholder = "Add Link To Post"
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.layer.cornerRadius = 10
        tf.layer.masksToBounds = true
        tf.delegate = self
        return tf
    }()
    
    
    var displayedAddTags: [String] = []
    var selectedAddTags: [String] = []
    var defaultMeals = ["breakfast","brunch","lunch","dinner","latenight","other","dessert", "drinks","coffee"]

    
    func setupAdditionalTags(){
        
        additionalTagCollectionView.register(HomeFilterBarCell.self, forCellWithReuseIdentifier: autoTagDetailId)
        additionalTagCollectionView.delegate = self
        additionalTagCollectionView.dataSource = self
        additionalTagCollectionView.allowsMultipleSelection = false
        additionalTagCollectionView.showsHorizontalScrollIndicator = false
        additionalTagCollectionView.backgroundColor = UIColor.clear
        additionalTagCollectionView.isScrollEnabled = false
        displayedAddTags = selectedAddTags
        
        
        for meal in defaultMeals {
            if !displayedAddTags.contains(meal) {
                displayedAddTags.append(meal)
            }
        }
        self.reloadAddTag()
        
    }
    
    let footerView = UploadPhotoFooter()
    
    
    func addFooter(){
        
        if UIScreen.main.bounds.height > 750 && !(self.isBookmarkingPost){
            footerView.selectedStep = 2
            footerView.delegate = self
            self.view.addSubview(footerView)
            footerView.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 0, height: 50)
        }
        
        if !self.footerView.isDescendant(of: self.view) {
            scrollview.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 20).isActive = true
        } else {
            scrollview.bottomAnchor.constraint(equalTo: footerView.topAnchor, constant: 20).isActive = true
        }

    }
    
    
    // POST IMAGE CAPTION
    let imageContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    let imageContainerHeight: CGFloat = 140
    var pageControl : UIPageControl = UIPageControl()
    
    let imageScrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.backgroundColor = .white
        scroll.isScrollEnabled = true
        scroll.isPagingEnabled = true
        return scroll
    }()
    
    let imageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .red
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    // Information from image
    var selectedImages: [UIImage]? {
        didSet{
            guard let selectedImages = selectedImages else {
                self.alert(title: "Error", message: "No Photos Selected")
                self.dismiss(animated: true, completion: nil)
                return}
            print("Upload Post | Loaded Images| \(selectedImages.count) Images")
//            self.imageView.image = selectedImages[0]
//            self.updateScrollImages()
        }
    }
    
    var selectedImageUrls: [String]? {
        didSet{
            guard let selectedImageUrls = selectedImageUrls else {return}
            print("Upload Post | Loaded Images URLS| \(selectedImageUrls.count) URLs")

//            print("Upload Post | Loaded Image URLs| \(selectedImageUrls.count) Images")
//            self.imageView.loadImage(urlString: selectedImageUrls.first!)

//            guard let selectedImageUrls = selectedImageUrls else {
//                self.alert(title: "Error", message: "No Photos Selected")
//                self.dismiss(animated: true, completion: nil)
//                return}
//            print("Upload Post | Loaded Images| \(selectedImages.count) Images")
//            self.imageView.image = selectedImages[0]
//            self.updateScrollImages()
        }
    }
    
    
    func updateScrollImages() {
        
        //        guard let _ = post?.imageUrls else {return}
        
//        guard let _ = self.selectedImages else {return}
        let imageCount = max(self.selectedImages?.count ?? 0, self.selectedImageUrls?.count ?? 0)

        imageScrollView.contentSize = CGSize(width: imageScrollView.frame.width * CGFloat(imageCount), height: imageScrollView.frame.height)
        
//        print("updateScrollImages ScrollView | \(imageCount) | H \(imageScrollView.frame.height) | W \(imageScrollView.frame.width)")
//        print("updateScrollImages ScrollView Content | \(imageCount) | H \(imageScrollView.contentSize.height) | W \(imageScrollView.contentSize.width)")
//
        imageView.frame = CGRect(x: 0, y: 0, width: self.imageScrollView.frame.width, height: self.imageScrollView.frame.width)
        
        imageScrollView.addSubview(imageView)
        imageView.tag = 0
        imageScrollView.isScrollEnabled = true
        
        
        if let image = self.selectedImages?[0] {
           self.imageView.image = image
            print("ImageScrollView | Loaded \(self.selectedImages?.count) Images")
        } else if let imageUrl = self.selectedImageUrls?[0]{
            self.imageView.loadImage(urlString: imageUrl)
            print("ImageScrollView | Loaded \(self.selectedImages?.count) URLs")
        }
        
        if imageCount > 1 {
            for i in 1 ..< (imageCount) {
                
                let addImageView = CustomImageView()
                
                if let image = self.selectedImages?[i] {
                    addImageView.image = image
                } else if let imageUrl = self.selectedImageUrls?[i]{
                    addImageView.loadImage(urlString: imageUrl)
                }
                addImageView.backgroundColor = .white
                addImageView.contentMode = .scaleAspectFill
                addImageView.clipsToBounds = true
                addImageView.isUserInteractionEnabled = true
                
                let xPosition = self.imageScrollView.frame.width * CGFloat(i)
                addImageView.frame = CGRect(x: xPosition, y: 0, width: imageScrollView.frame.width, height: imageScrollView.frame.height)
                
                imageScrollView.addSubview(addImageView)
                print("Scroll Photos |",i, addImageView.frame)
                
            }
        }

        imageScrollView.reloadInputViews()
    }
    
    
    var currentImage = 1
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == imageScrollView {
            self.currentImage = scrollView.currentPage
            self.pageControl.currentPage = self.currentImage - 1
            print(self.currentImage, self.pageControl.currentPage)
        }
    }
    
    
    let captionTextView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont(font: .avenirNextRegular, size: 12)
        tv.autocorrectionType = .yes
        tv.keyboardType = UIKeyboardType.default
        return tv
    }()
    
    let captionDefaultString = "What did you eat? \nHow good was it?"
    let captionDefault  = NSMutableAttributedString(string: "What did you eat? \nHow good was it?", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.gray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .avenirNextBoldItalic, size: 12)]))
    
    func setupImageCaption(){
        // Photo and Caption Container View
        view.addSubview(imageContainerView)
        imageContainerView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: imageContainerHeight)
        imageContainerView.backgroundColor = UIColor.lightBackgroundGrayColor()
        //        imageContainerView.layer.borderColor = UIColor.gray.cgColor
        //        imageContainerView.layer.borderWidth = 1
        
        // IMAGE
        view.addSubview(imageScrollView)
        imageScrollView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        imageScrollView.anchor(top: imageContainerView.topAnchor, left: imageContainerView.leftAnchor, bottom: imageContainerView.bottomAnchor, right: nil, paddingTop: 15, paddingLeft: 15, paddingBottom: 15, paddingRight: 0, width: 100, height: 100)
        imageScrollView.showsHorizontalScrollIndicator = false
        imageScrollView.widthAnchor.constraint(equalTo: imageScrollView.heightAnchor, multiplier: 1).isActive = true
        imageScrollView.isUserInteractionEnabled = true
        imageScrollView.isPagingEnabled = true
        imageScrollView.delegate = self
        imageScrollView.backgroundColor = UIColor.white
        
        let photoTapGesture = UITapGestureRecognizer(target: self, action: #selector(expandImage))
        self.imageScrollView.addGestureRecognizer(photoTapGesture)
        self.updateScrollImages()
        
        // CAPTION
        view.addSubview(captionTextView)
        captionTextView.anchor(top: imageScrollView.topAnchor, left: imageScrollView.rightAnchor, bottom: imageScrollView.bottomAnchor, right: imageContainerView.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        // Bottom Padding for image Count
        captionTextView.delegate = self
        captionTextView.backgroundColor = isBookmarkingPost ? UIColor.clear : UIColor.white
        captionTextView.layer.borderWidth = isBookmarkingPost ? 0  : 1
        captionTextView.showsVerticalScrollIndicator = false
        captionTextView.layer.borderColor = UIColor.rgb(red: 221, green: 221, blue: 221).cgColor
        captionTextView.layer.cornerRadius = 3
        
        if self.uploadPost?.caption != "" {
            captionTextView.text = self.uploadPost?.caption
        }   else {
            resetCaptionTextView()
        }

        
        // IMAGE COUNT
        setupPageControl()
        view.addSubview(pageControl)
        pageControl.anchor(top: imageContainerView.topAnchor, left: imageScrollView.leftAnchor, bottom: imageScrollView.topAnchor, right: imageScrollView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 0, height: 10)
        
        
    }
    
    func setupPageControl(){
        guard let imageCount = self.uploadPost?.images?.count else {return}
        self.pageControl.numberOfPages = imageCount
        self.pageControl.currentPage = 0
        self.pageControl.tintColor = UIColor.red
        self.pageControl.pageIndicatorTintColor = UIColor.darkGray
        self.pageControl.currentPageIndicatorTintColor = UIColor.ianLegitColor()
        self.pageControl.isHidden = imageCount == 1
        
        //        self.pageControl.backgroundColor = UIColor.rgb(red: 68, green: 68, blue: 68)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        // Clears Out Default Caption
        if textView.text == captionDefaultString {
            textView.text = nil
        }
        textView.textColor = UIColor.black
        textView.font = UIFont(font: .avenirNextRegular, size: 12)
        
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        // Detects Emoji being typed and detects price
        
        let char = text.cString(using: String.Encoding.utf8)!
        let isBackSpace = strcmp(char, "\\b")
        
        if text == "\n"  // Recognizes enter key in keyboard
        {
            //            textView.resignFirstResponder()
            //            return true
        }
        
//        if text.isSingleEmoji == true {
//            // Emoji was typed
//            if textView.text.contains(text){
//                //Ignore if caption text already has emoji, allows multiple emoji caption
//            } else {
//                self.addRemoveEmojiTags(emojiInput: text, emojiInputTag: text)
//            }
//        }
            
        else if (text == " ") {
            let nsString = textView.text as NSString?
            //            let newString = nsString?.replacingCharacters(in: range, with: text)
            let arr = nsString?.components(separatedBy: " ")
            print(arr?.last)
            self.detectPrice(string: arr?.last)
//            self.filterCaptionForEmojis(inputString: textView.text)
        }
        
        //        else if (text == " ") || (isBackSpace == -92){
        //
        //        }
        
        return true
        
    }
    
    func resetCaptionTextView() {
        self.captionTextView.attributedText = captionDefault
        self.captionTextView.textColor = UIColor.lightGray
    }
    
    func detectPrice(string: String?){
        guard let string = string else {return}
        if string.first != "$" {return}
        
        var price = string.replacingOccurrences(of: "$", with: "").removingWhitespaces()
        if let price = Double(price) {
            var priceSegment: Int? = nil
            
            if price <= 5 {
                priceSegment = 0
            } else if price <= 10 {
                priceSegment = 1
            } else if price <= 20 {
                priceSegment = 2
            } else if price <= 35 {
                priceSegment = 3
            } else if price <= 50 {
                priceSegment = 4
            } else if price > 50 {
                priceSegment = 5
            }
            
            if let priceSegment = priceSegment {
                self.postPriceSegment.selectedSegmentIndex = priceSegment
                self.postPriceSegment.tintColor = UIColor.legitColor()
                if priceSegment < UploadPostPriceDefault.count {
                    self.selectPostPrice = UploadPostPriceDefault[priceSegment]
                }
                print("Auto Price Segment Select: \(priceSegment) From \(string)")
            }
        }
        
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
            let attributeDict = [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor()]
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
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        listSortSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: 16), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
        listSortSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 16), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)
    }
    
    func underlineSegment(segment: Int? = 0){
        
        let segmentWidth = (self.view.frame.width - 30) / CGFloat(self.listSortSegment.numberOfSegments)
        let tempX = self.buttonBar.frame.origin.x
        UIView.animate(withDuration: 0.3) {
            //            self.buttonBarPosition?.isActive = false
            self.buttonBar.frame.origin.x = segmentWidth * CGFloat(segment ?? 0) + 5
            self.buttonBarPosition?.constant = segmentWidth * CGFloat(segment ?? 0) + 5
            self.buttonBarPosition?.isActive = true
        }
    }
    
    @objc func selectSort(sender: UISegmentedControl) {
        
        self.selectedSort = sortOptions[sender.selectedSegmentIndex]
        //        delegate?.headerSortSelected(sort: self.selectedSort)
        print("Selected Sort is ",self.selectedSort)
        self.underlineSegment(segment: sender.selectedSegmentIndex)
    }
    
    func refreshList(){
        self.tableView.reloadData()
        self.tableView.refreshControl?.endRefreshing()
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
        
        var selectedCount: Int = 0

        // Highlight Selected List if In Editing Post
        if self.preExistingList?.count != 0 && self.preExistingList != nil {
            
            // RESELECT LISTS
            for (listId, listName) in (self.preExistingList)!{
                if let index = fetchedList.firstIndex(where: { (list) -> Bool in
                    return list.id == listId
                }) {
                    fetchedList[index].isSelected = true
                }
            }
            
            // SORT LISTS BY SELECTED
            var tempList: [List] = []
            for list in fetchedList {
                if list.isSelected {
                    tempList.insert(list, at: 0)
                    selectedCount += 1
                } else {
                    tempList.append(list)
                }
            }
            fetchedList = tempList
        }
        
        
        self.setupNavigationItems()
        
        
        if isFiltering && searchBar.text != nil{
            filterContentForSearchText(searchBar.text!)
        } else {
            self.displayList = self.fetchedList
            self.tableView.reloadData()
        }
        
        print("Setup Lists | Fetched \(self.fetchedList.count) List | \(selectedCount) Selected | \(self.displayList.count) Displayed")
        self.showList()
        
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
        

        SVProgressHUD.show(withStatus: "Sharing Post")
        print("NEW POST FINAL | POST DICTIONARY: \n\(uploadPostDictionary)")
        
        Database.savePostToDatabase(uploadImages: uploadPost?.images, uploadDictionary: uploadPostDictionary, uploadLocation: uploadPostLocation, lists: self.selectedList){
            
            SVProgressHUD.dismiss()
            
            self.dismiss(animated: true, completion: {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                self.currentUploadingPostCheck = nil
                print("savePostToDatabase | Complete | Share Button ENABLED")
//                NotificationCenter.default.post(name: SharePhotoListController.updateFeedNotificationName, object: nil)
//                NotificationCenter.default.post(name: SharePhotoListController.updateProfileFeedNotificationName, object: nil)
//                NotificationCenter.default.post(name: SharePhotoListController.updateListFeedNotificationName, object: nil)
//                NotificationCenter.default.post(name: TabListViewController.refreshListNotificationName, object: nil)
                
            })
        }
    }
    
    func handleEditPost(){
        print("Selected List: \(self.selectedList)")
        var listIds: [String:String]? = [:]
        
        navigationItem.rightBarButtonItem?.isEnabled = false
        SVProgressHUD.show(withStatus: "Editing Post")

        
        guard let postId = uploadPost?.id else {
            print("Edit Post: ERROR, No Post ID")
            return
        }
        
        guard let imageUrls = uploadPost?.imageUrls else {
            print("Edit Post: ERROR, No Image URL")
            return
        }
        
        print("EDIT POST | \(uploadPostDictionary)")
        Database.editPostToDatabase(imageUrls: imageUrls, postId: postId, uploadDictionary: uploadPostDictionary, uploadLocation: uploadPostLocation, prevPost: preEditPost) {(editPost) in
            
            // Update Post Cache
//            var tempPost = self.uploadPost
//            tempPost?.selectedListId = listIds
//            tempPost?.creatorListId = listIds
//
//            if (tempPost?.selectedListId?.count)! > 0 {
//                tempPost?.hasPinned = true
//            }
//
//            postCache[(self.uploadPost?.id)!] = tempPost
            SVProgressHUD.dismiss()
            
            self.navigationController?.popToRootViewController(animated: true)
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            self.delegate?.refreshPost(post: editPost)
            
//            NotificationCenter.default.post(name: SharePhotoListController.updateFeedNotificationName, object: nil)
//            NotificationCenter.default.post(name: SharePhotoListController.updateProfileFeedNotificationName, object: nil)
//            NotificationCenter.default.post(name: SharePhotoListController.updateListFeedNotificationName, object: nil)
            //            NotificationCenter.default.post(name: SharePhotoListController.updateFeedNotificationName, object: nil)
            
        }
    }
    
    @objc func handleAddPostToList(){
        
        navigationItem.rightBarButtonItem?.isEnabled = false
        SVProgressHUD.show(withStatus: "Adding To List")
        
        if (Auth.auth().currentUser?.isAnonymous)!{
            print("Guest User Adding Post to List")
            let listAddDate = Date().timeIntervalSince1970
            for list in self.selectedList! {
                // Update Current User List
                if let listIndex = CurrentUser.lists.firstIndex(where: { (currentList) -> Bool in
                    currentList.id == list.id
                }) {
                    if CurrentUser.lists[listIndex].postIds![(self.uploadPost?.id)!] == nil {
                        CurrentUser.lists[listIndex].postIds![(self.uploadPost?.id)!] = listAddDate
                    }
                    CurrentUser.lists[listIndex].latestNotificationTime = Date()
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
            for list in self.selectedList! {
                tempNewList[list.id!] = list.name
            }
            
            //            uploadPost?.isLegit = tempNewList.values.contains(legitListName)
            
            Database.updateListforPost(post: uploadPost, newList: tempNewList, prevList: preExistingList) { (newPost) in
                guard let newPost = newPost else {return}
                self.delegate?.refreshPost(post: newPost)
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                SVProgressHUD.dismiss()
                self.navigationController?.popViewController(animated: true)
//                NotificationCenter.default.post(name: SharePhotoListController.updateListFeedNotificationName, object: nil)
                //                NotificationCenter.default.post(name: SharePhotoListController.updateFeedNotificationName, object: nil)
            }
        }
    }
    
    func finishUpdatingPost(post: Post){
        var tempNewList: [String:String] = [:]
        for list in self.selectedList! {
            tempNewList[list.id!] = list.name
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
        return displayedAddTags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: autoTagDetailId, for: indexPath) as! HomeFilterBarCell
        let option = displayedAddTags[indexPath.item].lowercased()
        
        
        // Only Emojis and Post type are tagged. Anything else is a caption search
        
        var displayText = ""
        if option.isSingleEmoji {
            displayText = option + " \((EmojiDictionary[option] ?? "").capitalizingFirstLetter())"
        } else {
            displayText = (ReverseEmojiDictionary[option] ?? "") + " \(option.capitalizingFirstLetter())"
        }
        
        var isSelected: Bool = self.selectedAddTags.contains(option)
        
        cell.uploadLocations.text = displayText
        cell.uploadLocations.textColor = isSelected ? UIColor.ianBlackColor() : UIColor.darkGray
        cell.uploadLocations.font = isSelected ? UIFont(font: .avenirNextDemiBold, size: 13) : UIFont(font: .avenirNextRegular, size: 12)
        
        //            cell.uploadLocations.font = isSelected ? UIFont(name: "Poppins-Bold", size: 13) : UIFont(name: "Poppins-Regular", size: 13)
        cell.layer.borderColor = isSelected ? UIColor.clear.cgColor : UIColor.lightGray.cgColor
        cell.backgroundColor = isSelected ? UIColor.ianOrangeColor() : UIColor.backgroundGrayColor()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let option = displayedAddTags[indexPath.item].lowercased()
        if self.selectedAddTags.contains(option) {
            if let index = self.selectedAddTags.firstIndex(of: option) {
                self.selectedAddTags.remove(at: index)
            }
        } else {
            self.selectedAddTags.append(option)
        }
        print("selectedAddTags | \(selectedAddTags)")
        self.setupAdditionalTags()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: listCellId, for: indexPath) as! UploadPhotoToListCell
        
        // LAST ITEM
        if indexPath.row == displayList.count {
            cell.refUser = CurrentUser.user
            cell.listnameLabel.text = "Add List"
            
            var newSelectedListCount = self.selectedList?.count ?? 0
            var previousListCount = self.preExistingList?.count ?? 0
            var listChange = newSelectedListCount - previousListCount
            
            if displayList.count == 0 {
                let displayAttributed = NSAttributedString(string: "You Have 0 Lists. Tap to Create One!", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.italicSystemFont(ofSize: 16), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.oldLegitColor()]))
                cell.listnameLabel.attributedText = displayAttributed
                
            } else {
                let displayAttributed = NSAttributedString(string: "Tap To Add Post To \(listChange) Lists", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.italicSystemFont(ofSize: 16), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.oldLegitColor()]))
                cell.listnameLabel.attributedText = displayAttributed
                
            }
        } else {
            cell.refUser = CurrentUser.user
            let temp_list = displayList[indexPath.row]
            //        temp_list.isSelected = (self.uploadPost?.selectedListId)![temp_list.id!] != nil
            //        temp_list.isSelected = (self.selectedList?.contains(where: { (list) -> Bool in
            //            list.id == temp_list.id
            //        }))! ?? false
            
            cell.list = temp_list
            cell.isSelected = temp_list.isSelected
//            cell.accessoryType = cell.isSelected ? UITableViewCell.AccessoryType.checkmark : UITableViewCell.AccessoryType.none
            
        }
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        
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
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if noLocationInd {
            
            self.alert(title: "Unable to Add Post to List", message: "Post must have location to be added to Lists. Current Location: \(self.uploadPost?.locationGPS)")
            self.tableView.deselectRow(at: indexPath, animated: false)
            
        } else {
            
            if indexPath.row == displayList.count {
                // LAST ROW
                if displayList.count == 0 {
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
                
                // UPDATE DISPLAY LIST
                print("Selected Lists | \(self.selectedList?.count) | \(displayList[indexPath.row].id) | \(displayList[indexPath.row].isSelected)")
                self.setupNavigationItems()
                self.tableView.reloadRows(at: [indexPath], with: .none)
            }
            
        }
        
        self.setupListText()

    }

    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if displayList[indexPath.row].name == legitListName {
            self.confirmLegitListSelection()
        } else {
            displayList[indexPath.row].isSelected = false
        }
        //        tableView.cellForRow(at: indexPath)?.accessoryType = UITableViewCellAccessoryType.none
        self.tableView.reloadRows(at: [indexPath], with: .none)
        
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
    
    @objc func expandImage(){
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
