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


protocol UploadPhotoListControllerMoreDelegate {
    func refreshPost(post:Post)
}


class UploadPhotoListControllerMore: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, ListPhotoCellDelegate, SKPhotoBrowserDelegate, NewListPhotoCellDelegate, UISearchBarDelegate, UITextViewDelegate, UploadPhotoFooterDelegate, AutoTagTableViewControllerDelegate, AddTagSearchControllerDelegate, SharePhotoListControllerDelegate, UIGestureRecognizerDelegate, UploadEmojiCellDelegate, EmojiSearchTableViewControllerDelegate, ListSummaryDelegate {

    

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
            
            // EMOJIS
            self.nonRatingEmojiTags = uploadPost?.nonRatingEmoji ?? []
            self.nonRatingEmojiTagsDict = uploadPost?.nonRatingEmojiTags ?? []
            
            // ADDITIONAL TAGS
            self.selectedAddTags = uploadPost?.autoTagEmojiTags ?? []
//            setupAdditionalTags()
            
            self.selectedListIds = []
            for (list, name) in self.uploadPost?.selectedListId ?? [:] {
                self.selectedListIds.append(list)
                self.selectedListIdTimes[list] = Date()
            }
            
            // Refreshes Current User Lists
            collectionView.reloadData()
            self.noLocationInd = (uploadPost?.locationGPS == nil)
            
            self.bookmarkView.uploadPost = uploadPost
            self.bookmarkView.isBookmarkingPost = true
            
            self.urlLink = uploadPost?.urlLink
            
            
        }
    }
    
        
    func refreshLinkButton() {
        if (self.urlLink == nil) || (self.urlLink?.isEmptyOrWhitespace() ?? true) {
            addLinkInput.text = ""
            addLinkInput.textColor = UIColor.gray
            addLinkInput.alpha = 0.8
        } else {
            addLinkInput.text = "\(String(self.urlLink?.cutoff(length: 50) ?? ""))"
            addLinkInput.textColor = UIColor.mainBlue()
            addLinkInput.alpha = 1

        }
        addLinkButton.sizeToFit()
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
        var caption = uploadPost?.caption
        if caption == captionDefaultString {caption = nil}
        
        // SELECTED LIST
        var listIds: [String:String]? = [:]
        
//        let taggedLists = bookmarkView.fetchedList.filter { return $0.isSelected }
//        if taggedLists != nil {
//            // Add list id to post dictionary for display
//            for list in taggedLists {
//                listIds![list.id!] = list.name
//            }
//        }
        
        if self.selectedListIds.count > 0 {
            for id in self.selectedListIds {
                let name = CurrentUser.lists.first { (list) -> Bool in
                    return list.id == id
                }?.name
                listIds![id] = name
            }
        }
        
        print("Tagged \(self.selectedListIds.count) Lists To Post")
        listIds?.forEach { print("\($0): \($1)") }
        
        let imageURLS = uploadPost?.imageUrls ?? []
        let smallImageURLS = uploadPost?.smallImageUrl ?? nil

        var urlLinkInput = self.addLinkInput.text

    // ONLY UPDATE IF IS POST CREATOR USER
        
        if uploadPost?.user.uid == Auth.auth().currentUser?.uid && !isBookmarkingPost {
            uploadPostDictionary["price"] = [price]
            uploadPostDictionary["nonratingEmoji"] = self.nonRatingEmojiTags ?? nil
            uploadPostDictionary["nonratingEmojiTags"] = self.nonRatingEmojiTagsDict ?? nil
            uploadPostDictionary["autoTagEmojis"] = autoTagEmojis
            uploadPostDictionary["autoTagEmojisDict"] = autoTagEmojisDict
            uploadPostDictionary["caption"] = caption
            uploadPostDictionary["lists"] = listIds
            uploadPostDictionary["listCount"] = self.selectedList.count
            uploadPostDictionary["smallImageLink"] = smallImageURLS
            uploadPostDictionary["imageUrls"] = imageURLS
            uploadPostDictionary["urlLink"] = urlLinkInput

        }

    }
    
    
    
    var bookmarkList: List = emptyBookmarkList
    var legitList: List = emptyLegitList
    var fetchedList: [List] = []
    var displayList: [List] = []
    var selectedList: [List] = []
    var userListNameDic: [String:String] = [:]
    /*
    {
        return fetchedList.filter { return $0.isSelected }
    }*/
    
    var selectedListIds: [String] = [] {
        didSet {
            self.refreshTagListButton()
        }
    }
    
    var selectedListIdTimes: [String: Date] = [:]
    
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
    
    
    lazy var tagListHeader: UILabel = {
        let ul = UILabel()
        ul.text = "Lists"
        ul.font = UIFont(name: "Poppins-Regular", size: 15)
        ul.textColor = UIColor.darkGray
        return ul
    }()
    
    lazy var expandListLabel: UILabel = {
        let ul = UILabel()
        ul.text = "See All Lists"
        ul.font = UIFont(name: "Poppins-Regular", size: 12)
        ul.textColor = UIColor.gray
        return ul
    }()
    
    
    var tagListCollectionView: UICollectionView = {
        let uploadLocationTagList = UploadLocationTagList()
        uploadLocationTagList.scrollDirection = UICollectionView.ScrollDirection.horizontal
//        uploadLocationTagList.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        uploadLocationTagList.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        var cv = UICollectionView(frame: .zero, collectionViewLayout: uploadLocationTagList)
        return cv
    }()
    
    let tagListButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        button.setImage(#imageLiteral(resourceName: "add_list").withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTitle(" Tag To List", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(didTapTagList), for: .touchUpInside)
        button.tintColor = UIColor.ianWhiteColor()
//        button.backgroundColor = UIColor.mainBlue().withAlphaComponent(0.8)
        button.backgroundColor = UIColor.ianLegitColor().withAlphaComponent(0.8)
        return button
    } ()
    
    var taggedListView = ListSummaryView()

    
    @objc func didTapTagList() {
        let sharePhotoListController = SharePhotoListController()
        sharePhotoListController.noUpload = true
        sharePhotoListController.isBookmarkingPost = true
        sharePhotoListController.delegate = self
        sharePhotoListController.uploadPost = uploadPost
        sharePhotoListController.selectedListIds = self.selectedListIds
        navigationController?.pushViewController(sharePhotoListController, animated: true)
    }
    
    
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
        let listCount = selectedList.count
        let headerString = (listCount == 0) ? "ADD TO LIST" : "ADDED TO \(listCount) LIST"
        addListHeaderText.setTitle(headerString, for: .normal)
    }
    
    var toggleListHeight:NSLayoutConstraint?
    var listHeight:NSLayoutConstraint?
    var addTagHeight:NSLayoutConstraint?
    var listFullScreen: NSLayoutConstraint?
    
    
    let addNewListButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "add_list").withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTitle(" New List", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(initAddList), for: .touchUpInside)
        button.tintColor = UIColor.ianWhiteColor()
        button.backgroundColor = UIColor.mainBlue()
        
        button.tintColor = UIColor.mainBlue()
        button.layer.borderColor = UIColor.mainBlue().cgColor
        button.layer.borderWidth = 1
        button.setTitleColor(UIColor.mainBlue(), for: .normal)
        button.backgroundColor = UIColor.ianWhiteColor()
        return button
    }()
    
    @objc func initAddList(){
        self.extCreateNewListSimple()
        
//        //1. Create the alert controller.
//        let alert = UIAlertController(title: "Create A New List", message: "Enter New List Name", preferredStyle: .alert)
//
//        //2. Add the text field. You can configure it however you need.
//        alert.addTextField { (textField) in
//            textField.text = ""
//        }
//
//        // 3. Grab the value from the text field, and print it when the user clicks OK.
//        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
//            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
//            print("New List Name: \(textField?.text)")
//            guard let newListName = textField?.text else {return}
//
//            let listId = NSUUID().uuidString
//            guard let uid = Auth.auth().currentUser?.uid else {return}
//            self.checkListName(listName: newListName) { (listName) in
//
//                self.addListTextField.resignFirstResponder()
//                let newList = List.init(id: listId, name: listName, publicList: 1)
//                self.createList(newList: newList)
//
//            }
//        }))
//
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
//            print("Handle Cancel Logic here")
//        }))
//
//        // 4. Present the alert.
//        self.present(alert, animated: true, completion: nil)
        
        
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
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
//        self.setupNavigationItems()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.setupNavigationItems()
        
        self.keyboardTap = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
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
        self.setupNavigationItems()

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
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == addLinkInput {
            return true
        } else {
            if textField.text == "" {
                self.typeInEmoji()
//                self.openEmojiInfo()
                return false
            }
            else if self.selectedEmojiTagArray.contains(textField) {
                self.tappedEmojiLabel(emoji: textField.text)
                return false
            } else {
                return true
            }
        }
    }
    
    
    @objc func typeInEmoji(){
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Tag Emoji", message: """
    Tag your post with up to 3 Emojis.
    Posts will then be searchable by Emoji.
    First emoji will displayed on map.
    """, preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.text = ""
            textField.placeholder = "Insert Emoji"
        }
        
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "Tag", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            let emojiText = textField?.text?.emojis[0] ?? ""
            
            if emojiText != "" {
                print("Tag \(emojiText)")
                if let emojiName = EmojiDictionary[emojiText] {
                    self.addRemoveEmojiTags(emojiInput: emojiText, emojiInputTag: emojiName)
                } else {
                    self.suggestEmojiDic(emoji: emojiText)
                }
            } else {
                print("No Emojis Found in \(emojiText) | \(textField?.text)")
                self.alert(title: "Emoji Name Error", message: "No Emojis Inserted")
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
    func openEmojiInfo(){
            self.alert(title: "Emoji Tagging", message: """
    Tag your post with up to 3 Emojis.
    Posts will then be searchable by Emoji.
    First emoji will displayed on map.
    """)
        
    }
    
    
    func tappedEmojiLabel(emoji:String?){
        
        var tempEmojiText: String = ""
        var tempEmojiTitle: String = "Emoji Options"
        
        if let _ = emoji {
            tempEmojiText = emoji!
            
            if let tempEmojiDic = EmojiDictionary[tempEmojiText] {
                tempEmojiTitle = "\(tempEmojiText) \(tempEmojiDic)"
            }
        }
        
        let optionsAlert = UIAlertController(title: tempEmojiTitle, message: "", preferredStyle: UIAlertController.Style.alert)
        
        
        optionsAlert.addAction(UIAlertAction(title: "Untag \(tempEmojiText)", style: .default, handler: { (action: UIAlertAction!) in
            //            self.emojiTagUntag(emojiInput: emoji, emojiInputTag: nil)
            self.addRemoveEmojiTags(emojiInput: emoji, emojiInputTag: nil)
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Untag All Emojis", style: .default, handler: { (action: UIAlertAction!) in
            //            self.emojiTagUntag(emojiInput: nil, emojiInputTag: nil)
            self.addRemoveEmojiTags(emojiInput: nil, emojiInputTag: nil)
            
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        present(optionsAlert, animated: true) {
            optionsAlert.view.superview?.isUserInteractionEnabled = true
            optionsAlert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.alertClose(gesture:))))
        }
        
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        addListTextField.resignFirstResponder()
        addLinkInput.resignFirstResponder()
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

    @objc func keyboardWillShow(notification: NSNotification) {
        print("keyboardWillShow. Adding Keyboard Tap Gesture")
        self.view.addGestureRecognizer(self.keyboardTap)
    }
    
    @objc func keyboardWillHide(notification: NSNotification){
        print("keyboardWillHide. Removing Keyboard Tap Gesture")
        self.view.removeGestureRecognizer(self.keyboardTap)
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        searchBar.resignFirstResponder()
    }
    
    var keyboardTap = UITapGestureRecognizer()

    
    
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

        self.navigationController?.navigationBar.isTranslucent = false
        let tempImage = UIImage.init(color: UIColor.legitColor())
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        
        self.navigationController?.view.backgroundColor = UIColor.ianLegitColor().withAlphaComponent(0.8)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        self.navigationController?.navigationBar.barTintColor = UIColor.ianLegitColor()
        self.navigationController?.navigationBar.tintColor = UIColor.ianLegitColor()
        
        self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.white, NSAttributedString.Key.font.rawValue: UIFont(name: "Poppins-Bold", size: 18)])
        self.navigationController?.navigationBar.layoutIfNeeded()
        self.setNeedsStatusBarAppearanceUpdate()

        
        // Nav Back Buttons
        let navBackButton = navBackButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        navBackButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        navBackButton.setTitleColor(UIColor.white, for: .normal)
        navBackButton.tintColor = UIColor.white
        navBackButton.backgroundColor = UIColor.clear
        let navShareTitle = NSAttributedString(string: " BACK ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 12)])
        navBackButton.setAttributedTitle(navShareTitle, for: .normal)
        let barButton2 = UIBarButtonItem.init(customView: navBackButton)
        self.navigationItem.leftBarButtonItem = barButton2
        
        
        // EDIT POST
        if self.isEditingPost
        {
            // Nav Edit Button
            let navEditButton = NavButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            navEditButton.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
            navEditButton.setTitle("Edit Post", for: .normal)
            navEditButton.setTitleColor(UIColor.white, for: .normal)
            navEditButton.backgroundColor = UIColor.clear
            let barButton2 = UIBarButtonItem.init(customView: navEditButton)
            self.navigationItem.rightBarButtonItem = barButton2
//            navigationItem.title = "Edit Post"
            
            let customFont = UIFont(name: "Poppins-Bold", size: 18)
            let headerTitle = NSAttributedString(string: "", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: customFont])
            let navLabel = UILabel()
            navLabel.attributedText = headerTitle
            navigationItem.titleView = navLabel
            
            

        }
            
            // ADDING POST TO LIST
        else if self.isBookmarkingPost
        {
            var displayString = ""
            
            var newSelectedListCount = self.selectedList.count ?? 0
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
            let headerTitle = NSAttributedString(string: "", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: customFont])
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
            navShareButton.setTitleColor(UIColor.white, for: .normal)
            let barButton2 = UIBarButtonItem.init(customView: navShareButton)
            self.navigationItem.rightBarButtonItem = barButton2
            navigationItem.title = "New Post"

        }
    }
    
    
    let buttonBar = UIView()
    var buttonBarPosition: NSLayoutConstraint?

    lazy var selectPostPriceHeader: UILabel = {
        let ul = UILabel()
        ul.text = "Meal Price"
        ul.font = UIFont(name: "Poppins-Regular", size: 15)
        ul.textColor = UIColor.darkGray
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
        ul.text = "Categories"
        ul.font = UIFont(name: "Poppins-Regular", size: 15)
        ul.textColor = UIColor.darkGray
        return ul
    }()
    
    var additionalTagCollectionView: UICollectionView = {
        let uploadLocationTagList = UploadLocationTagList()
        uploadLocationTagList.scrollDirection = UICollectionView.ScrollDirection.horizontal
        uploadLocationTagList.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
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
    
    @objc func openAddTagSearch() {
        let autoTag = AddTagSearchController()
        autoTag.delegate = self
        autoTag.selectedScope = 0
        autoTag.selectedTags = self.selectedAddTags
        
        self.navigationController?.pushViewController(autoTag, animated: true)
    }
    
    @objc func openAutoTag(sender : UIButton){
        let autoTag = AddTagSearchController()
        autoTag.delegate = self
        autoTag.selectedScope = 0
        autoTag.selectedTags = self.selectedAddTags
        
        self.navigationController?.pushViewController(autoTag, animated: true)
    }
    
    func additionalTagSelected(tags: [String]){
        print("Selected Tags: \(tags) | UploadPhotoListController")
        var autoTagEmojis: [String] = []
        var autoTagEmojisDict: [String] = []
        
        for tag in tags {
            if tag.isSingleEmoji {
                autoTagEmojis.append(tag)
                autoTagEmojisDict.append((EmojiDictionary[tag] ?? "").capitalizingFirstLetter())
            } else {
                autoTagEmojis.append((ReverseEmojiDictionary[tag] ?? ""))
                autoTagEmojisDict.append(tag)
            }
        }
        
        
        self.uploadPost?.autoTagEmoji = autoTagEmojis
        self.uploadPost?.autoTagEmojiTags = autoTagEmojisDict
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
    lazy var bookmarkHeader: UILabel = {
        let ul = UILabel()
        ul.text = "Tag List"
//        ul.font = UIFont(font: .avenirNextMedium, size: 18)
        ul.font = UIFont(name: "Poppins-Bold", size: 20)
        
        ul.textColor = UIColor.ianLegitColor()
        return ul
    }()
    
    let bookmarkButton: UIButton = {
        let button = UIButton()
        
        var iconImage = #imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal)
        button.setImage(iconImage, for: .normal)
        button.tintColor = UIColor.ianLegitColor()
//        button.addTarget(self, action: #selector(openAutoTag(sender:)), for: .touchUpInside)
        button.tag = 0
        return button
    } ()
    
    @objc func didTapBookmarkButton(){
        
    }
    
    lazy var addLinkHeader: UILabel = {
        let ul = UILabel()
        ul.text = "Add Link To Post"
        ul.font = UIFont(name: "Poppins-Regular", size: 15)
        ul.textColor = UIColor.darkGray
        return ul
    }()
    
// EMOJI RATINGS
    
    var nonRatingEmojiTags: [String] = [] {
        didSet{
            //            self.updateEmojiTextView()
            //            self.selectedEmojiTag.text = self.nonRatingEmojiTags.first
            //            self.suggestedEmojiCollectionView.reloadData()
            
        }
    }
    var nonRatingEmojiTagsDict:[String] = []
    
    let emojiRatingHeaderLabel: UILabel = {
        let tv = UILabel()
        tv.font = UIFont(name: "Poppins-Regular", size: 15)
        tv.textColor = UIColor.darkGray
        tv.text = "Emoji Tags"
        tv.backgroundColor = UIColor.clear
        tv.textAlignment = NSTextAlignment.left
        return tv
    }()
    
    var selectedEmojiTagArray: [UITextField] = []
    let selectedEmojiTag = UITextField()
    let selectedEmojiTag2 = UITextField()
    let selectedEmojiTag3 = UITextField()
    let imageDetailHeight: CGFloat = 30

    
    func updateEmojiTextView(){
        for view in selectedEmojiTagArray {
            view.text = ""
            view.alpha = 0.5
        }
        
        for (index, emoji) in nonRatingEmojiTags.enumerated() {
            if index >= 3 {return}
            selectedEmojiTagArray[index].text = emoji
            selectedEmojiTagArray[index].alpha = 1
        }
        //        self.suggestedEmojiCollectionView.reloadData()
        
    }
    
    var emojiOptionsView = UIView()

    let filterEmojiCollectionView: UICollectionView = {
        let uploadLocationTagList = FilterEmojiLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadLocationTagList)
        //        cv.layer.borderWidth = 1
        //        cv.layer.borderColor = UIColor.legitColor().cgColor
        
        return cv
    }()
    
    let suggestedEmojiCollectionView: UICollectionView = {
        let uploadEmojiList = UploadEmojiList()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadEmojiList)
        cv.tag = 10
        cv.layer.borderWidth = 0
        cv.backgroundColor = UIColor.clear
        return cv
    }()
    
    let emojiFilterCellID = "emojiFilterCellID"
    let emojiCellID = "emojiCellID"
    let EmojiContainerView = UIView()

//    var selectedEmojiFilterOptions = ["Recent", "Smiley", "Food", "Drink", "Snack", "Meat", "Veg",  "Flag"]
    var selectedEmojiFilterOptions = FilterEmojiTypes
    var selectedEmojiFilter: String? = nil {
        didSet {
            self.filterEmojiSelections()
        }
    }
    
    var emojiTagSelection: [String] = allFoodEmojis

    var captionEmojis:[String] = [] {
        didSet{
//            self.filterEmojiSelections()
        }
    }
    var locationMostUsedEmojis:[String] = [] {
        didSet{
//            self.filterEmojiSelections()
        }
    }
    var reviewSuggestedEmojis: [String] = [] {
        didSet{
//            self.filterEmojiSelections()
        }
    }
    
    var mealTagEmojis: [EmojiBasic] = [] {
        didSet{
//            self.filterEmojiSelections()
        }
    }
    
    let emojiDetailLabel: LightPaddedUILabel = {
        let label = LightPaddedUILabel()
        label.text = "Emoji Dictionary"
        label.font = UIFont(font: .avenirNextDemiBold, size: 16)
        label.textColor = UIColor.white
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.ianLegitColor()
        label.layer.borderWidth = 1
        label.layer.borderColor = UIColor.ianLegitColor().cgColor
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        return label
    }()
    
    let searchEmojiButton: UIButton = {
        let button = UIButton(type: .system)
                button.setImage(#imageLiteral(resourceName: "search_blank").withRenderingMode(.alwaysOriginal), for: .normal)

        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        button.tag = 3
        button.layer.borderColor = UIColor.init(hexColor: "fdcb6e").cgColor
        button.layer.borderWidth = 0
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        button.addTarget(self, action: #selector(openEmojiSearch), for: .touchUpInside)
        return button
    } ()
    
    
    @objc func openEmojiSearch(){
        let emojiSearch = EmojiSearchTableViewController()
        emojiSearch.delegate = self
        emojiSearch.selectedEmojis = self.nonRatingEmojiTags
        if (searchBar.text?.count) ?? 0 > 0 {
            emojiSearch.searchBar.text = searchBar.text
            print("Passing \(emojiSearch.searchBar.text) to searchBar | \(searchBar.text)")

        }
        
        self.navigationController?.pushViewController(emojiSearch, animated: true)
    }
    
    func setEmojiTags(emojiInput: [String]?) {
        nonRatingEmojiTags = []
        nonRatingEmojiTagsDict = []
        
        guard let emojiInput = emojiInput else {return}
        
        for emoji in emojiInput {
            let emoji_dic = EmojiDictionary[emoji] ?? ""
            nonRatingEmojiTags.append(emoji)
            nonRatingEmojiTagsDict.append(emoji_dic)
        }
        self.updateEmojiTextView()
        self.suggestedEmojiCollectionView.reloadData()
    }
    
    let emojiDescLabel: UILabel = {
        let tv = UILabel()
        tv.font = UIFont(name: "Poppins-Regular", size: 9)
        tv.textColor = UIColor.gray
//        tv.text = "Tag post with emojis to group by food type and easy search by emoji"
        tv.text = "Tag emojis to group and search posts by food type or emojis"
        tv.text = "Use emoji tags to group post by food type for emoji search"
        tv.text = "Tag post by food type or emojis to find this post by emoji later"

//        tv.text = "Tag post with emojis to group by food type and search by emoji later"
        tv.backgroundColor = UIColor.clear
        tv.textAlignment = NSTextAlignment.left
        return tv
    }()
    
    let emojiInfoButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        button.setTitle("❓", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 10)
//        button.setImage(#imageLiteral(resourceName: "info").withRenderingMode(.alwaysOriginal), for: .normal)

        button.addTarget(self, action: #selector(didTapEmojiInfo), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.backgroundColor = UIColor.white.withAlphaComponent(0.75).cgColor
        button.layer.borderColor = UIColor.red.cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 20/2
        button.translatesAutoresizingMaskIntoConstraints = true
        
        return button
    }()
    
    @objc func didTapEmojiInfo() {
        print("Did Tap Info")
        self.alert(title: "Emoji Tags", message: "Tag your post with emojis to group post by food and search for posts by food emojis later")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.lightBackgroundGrayColor()
//        NotificationCenter.default.addObserver(self, selector: #selector(updateSelectedLists), name: TabListViewController.refreshListNotificationName, object: nil)
        
        // Set for the Post up top
        self.automaticallyAdjustsScrollViewInsets = false

        self.setupNavigationItems()
        
        
// EMOJI
        


       let emojiHeaderView = UIView()
        view.addSubview(emojiHeaderView)
        emojiHeaderView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 35)
        
        view.addSubview(emojiRatingHeaderLabel)
        emojiRatingHeaderLabel.anchor(top: nil, left: emojiHeaderView.leftAnchor, bottom: emojiHeaderView.bottomAnchor, right: nil, paddingTop: 10, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 80, height: imageDetailHeight)
//        emojiRatingHeaderLabel.centerYAnchor.constraint(equalTo: emojiHeaderView.centerYAnchor).isActive = true
        emojiRatingHeaderLabel.sizeToFit()
//        emojiRatingHeaderLabel.isHidden = true

        // TAGGED EMOJIS
        selectedEmojiTagArray = [selectedEmojiTag, selectedEmojiTag2, selectedEmojiTag3]
        for (index, emojiField) in selectedEmojiTagArray.enumerated() {
            emojiField.backgroundColor = UIColor.init(white: 0, alpha: 0.05)
            emojiField.layer.borderColor = UIColor.ianLegitColor().cgColor
            emojiField.textAlignment = NSTextAlignment.center
            emojiField.layer.borderWidth = 1
            emojiField.alpha = 1
            emojiField.tag = index
        }
        
        
        let emojiStackView = UIStackView(arrangedSubviews: selectedEmojiTagArray)
        emojiStackView.distribution = .fillEqually
        emojiStackView.spacing = 3
        
        for view in emojiStackView.arrangedSubviews {
            let emoji = view as! UITextField
            emoji.widthAnchor.constraint(greaterThanOrEqualTo: emoji.heightAnchor, multiplier: 1).isActive = true
            emoji.layer.cornerRadius = CGFloat(imageDetailHeight / 2)
            emoji.clipsToBounds = true
            emoji.delegate = self
        }
        
        self.updateEmojiTextView()

        view.addSubview(emojiStackView)
        emojiStackView.anchor(top: nil, left: nil, bottom: nil, right: emojiHeaderView.rightAnchor, paddingTop: 5, paddingLeft: 25, paddingBottom: 0, paddingRight: 5, width: 0, height: imageDetailHeight)
        emojiStackView.centerYAnchor.constraint(equalTo: emojiHeaderView.centerYAnchor).isActive = true
        
//        view.addSubview(emojiInfoButton)
//        emojiInfoButton.anchor(top: nil, left: emojiStackView.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 10, width: 15, height: 15
//        emojiInfoButton.centerYAnchor.constraint(equalTo: emojiHeaderView.centerYAnchor).isActive = true
//        emojiInfoButton.layer.cornerRadius = 15 / 2
//        emojiInfoButton.layer.masksToBounds = true
//        emojiInfoButton.layer.borderWidth = 1
//        emojiInfoButton.layer.borderColor = UIColor.red.cgColor

        // Add Emoji Detail Label (Caption When Emoji is Selected)
        view.addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        emojiDetailLabel.alpha = 0
        emojiDetailLabel.centerXAnchor.constraint(equalTo: emojiHeaderView.centerXAnchor).isActive = true
        emojiDetailLabel.centerYAnchor.constraint(equalTo: emojiHeaderView.centerYAnchor).isActive = true
//        emojiDetailLabel.rightAnchor.constraint(lessThanOrEqualTo: view.rightAnchor, constant: 5).isActive = true
//        emojiDetailLabel.leftAnchor.constraint(lessThanOrEqualTo: emojiRatingHeaderLabel.rightAnchor, constant: 5).isActive = true


        
        view.addSubview(emojiDescLabel)
        emojiDescLabel.anchor(top: emojiHeaderView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        emojiDescLabel.sizeToFit()

        
        
        
        
        let searchBarContainer = UIView()
        searchBarContainer.backgroundColor = UIColor.white
        view.addSubview(searchBarContainer)
        searchBarContainer.anchor(top: emojiDescLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

    
        view.addSubview(searchEmojiButton)
        searchEmojiButton.anchor(top: nil, left: nil, bottom: nil, right: searchBarContainer.rightAnchor, paddingTop: 3, paddingLeft: 5, paddingBottom: 0, paddingRight: 10, width: 40, height: 25)
        searchEmojiButton.centerYAnchor.constraint(equalTo: searchBarContainer.centerYAnchor).isActive = true
//        searchBar.rightAnchor.constraint(equalTo: se  archEmojiButton.leftAnchor, constant: 10).isActive = true
//        searchEmojiButton.layer.cornerRadius = 6
        searchEmojiButton.layer.masksToBounds = true
        
        
        view.addSubview(searchBar)
        searchBar.anchor(top: searchBarContainer.topAnchor, left: searchBarContainer.leftAnchor, bottom: searchBarContainer.bottomAnchor, right: searchEmojiButton.leftAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 2, paddingRight: 2, width: 0, height: 0)
        setupSearchBar()
        
        
        
        // Emoji Container View - One Line
        EmojiContainerView.backgroundColor = UIColor.clear
        view.addSubview(EmojiContainerView)
        let emojiContainerHeight: Int = (Int(EmojiSize.width) + 2) * 2 + 10 + 5
        
        EmojiContainerView.anchor(top: searchBarContainer.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: CGFloat(emojiContainerHeight))
        
        // Suggested Emoji Input View
        self.setupEmojiCollectionView()
        view.addSubview(suggestedEmojiCollectionView)
        suggestedEmojiCollectionView.anchor(top: EmojiContainerView.topAnchor, left: EmojiContainerView.leftAnchor, bottom: EmojiContainerView.bottomAnchor, right: EmojiContainerView.rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        suggestedEmojiCollectionView.backgroundColor = UIColor.white
        suggestedEmojiCollectionView.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        suggestedEmojiCollectionView.layer.borderWidth = 0.5

//        let imageBottomDiv = UIView()
//        view.addSubview(imageBottomDiv)
//        imageBottomDiv.anchor(top: filterEmojiCollectionView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
//        imageBottomDiv.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        
        
        
        view.addSubview(emojiOptionsView)
        emojiOptionsView.anchor(top: EmojiContainerView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
        
    
        // Add Places Collection View
        view.addSubview(filterEmojiCollectionView)
        filterEmojiCollectionView.anchor(top: emojiOptionsView.topAnchor, left: view.leftAnchor, bottom: emojiOptionsView.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        filterEmojiCollectionView.backgroundColor = UIColor.clear
        filterEmojiCollectionView.register(EmojiFilterCell.self, forCellWithReuseIdentifier: emojiFilterCellID)
        filterEmojiCollectionView.delegate = self
        filterEmojiCollectionView.dataSource = self
        filterEmojiCollectionView.showsHorizontalScrollIndicator = false

        
        
        
        
        
        
// ADD LINK
        view.addSubview(addLinkHeader)
        addLinkHeader.anchor(top: emojiOptionsView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        
        view.addSubview(addLinkView)
        addLinkView.anchor(top: addLinkHeader.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 4, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 40)
        
        addLinkView.addSubview(addLinkButton)
        addLinkButton.anchor(top: nil, left: addLinkView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 30, height: 30)
        addLinkButton.centerYAnchor.constraint(equalTo: addLinkView.centerYAnchor).isActive = true
        
        addLinkView.addSubview(addLinkInput)
        addLinkInput.anchor(top: addLinkView.topAnchor, left: addLinkButton.rightAnchor, bottom: addLinkView.bottomAnchor, right: addLinkView.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        addLinkInput.delegate = self
        
        
                
// PRICE SEGMENT
        view.addSubview(selectPostPriceHeader)
        selectPostPriceHeader.anchor(top: addLinkView.bottomAnchor, left: addLinkView.leftAnchor, bottom: nil, right: nil, paddingTop: 20, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        selectPostPriceHeader.sizeToFit()
        
        view.addSubview(postPriceSegment)
        postPriceSegment.anchor(top: selectPostPriceHeader.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 4, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 30)
        
        addFooter()

// ADDITIONAL TAGS
//        view.addSubview(additionalTagHeader)
//        additionalTagHeader.anchor(top: postPriceSegment.bottomAnchor, left: postPriceSegment.leftAnchor, bottom: nil, right: nil, paddingTop: 30, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 100, height: 0)
//        additionalTagHeader.sizeToFit()
//        additionalTagHeader.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openAddTagSearch)))
//        additionalTagHeader.isUserInteractionEnabled = true
//
//        view.addSubview(additionalTagCollectionView)
//        additionalTagCollectionView.anchor(top: nil, left: additionalTagHeader.rightAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 15, width: 0, height: 30)
//        additionalTagCollectionView.centerYAnchor.constraint(equalTo: additionalTagHeader.centerYAnchor).isActive = true
//        setupAdditionalTags()
        
        
// TAG LIST
        
//        view.addSubview(tagListHeader)
//        tagListHeader.anchor(top: postPriceSegment.bottomAnchor, left: postPriceSegment.leftAnchor, bottom: nil, right: nil, paddingTop: 30, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 100, height: 0)
//        tagListHeader.sizeToFit()
//        tagListHeader.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapTagList)))
//        tagListHeader.isUserInteractionEnabled = true
//        tagListHeader.isHidden = true
//
//        view.addSubview(tagListButton)
//        tagListButton.anchor(top: postPriceSegment.bottomAnchor, left: postPriceSegment.leftAnchor, bottom: nil, right: nil, paddingTop: 30, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
//        tagListButton.centerYAnchor.constraint(equalTo: (tagListHeader).centerYAnchor).isActive = true
//
//        tagListButton.layer.cornerRadius = 5
//        tagListButton.layer.masksToBounds = true
//        tagListButton.sizeToFit()

        
//        setupTagListCollectionView()
//        view.addSubview(tagListCollectionView)
//        tagListCollectionView.anchor(top: tagListHeader.bottomAnchor, left: tagListHeader.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 4, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 0, height: 35)
////        tagListCollectionView.centerYAnchor.constraint(equalTo: (tagListHeader).centerYAnchor).isActive = true
//        tagListCollectionView.isHidden = true

        
        setupTaggedList()
        view.addSubview(taggedListView)
        taggedListView.anchor(top: postPriceSegment.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 25, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        taggedListView.backgroundColor = UIColor.clear
        taggedListView.listHeaderLabel.isHidden = true
        
        view.addSubview(tagListButton)
        tagListButton.anchor(top: taggedListView.topAnchor, left: taggedListView.leftAnchor, bottom: nil, right: nil, paddingTop: -5, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
        tagListButton.layer.cornerRadius = 5
        tagListButton.layer.masksToBounds = true
        tagListButton.sizeToFit()
        
        view.addSubview(addNewListButton)
        addNewListButton.anchor(top: taggedListView.bottomAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 30, paddingBottom: 0, paddingRight: 10, width: 0, height: 30)
//        addNewListButton.centerYAnchor.constraint(equalTo: tagListButton.centerYAnchor).isActive = true

        
        view.addSubview(expandListLabel)
        expandListLabel.anchor(top: taggedListView.bottomAnchor, left: tagListButton.leftAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 30)
//        expandListLabel.centerYAnchor.constraint(equalTo: addNewListButton.centerYAnchor).isActive = true
        expandListLabel.isUserInteractionEnabled = true
        expandListLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapTagList)))
        //        view.addSubview(bookmarkHeader)
        //        bookmarkHeader.anchor(top: additionalTagCollectionView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        //        refreshBookmarkHeader()
//
//        bookmarkView.delegate = self
//        bookmarkView.nextButton.isHidden = true
//        view.addSubview(bookmarkView.view)
//        bookmarkView.view.layer.cornerRadius = 5
//        bookmarkView.view.layer.masksToBounds = true
//        bookmarkView.view.anchor(top: bookmarkHeader.bottomAnchor, left: view.leftAnchor, bottom: footerView.topAnchor, right: view.rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 10, paddingRight: 5, width: 0, height: 0)
//        refreshBookmarkHeader()

    }
    
    func setupTaggedList() {
        taggedListView.refreshAll()
        taggedListView.delegate = self
        // Default Sort List By Date
        taggedListView.sortListByDate = true
        taggedListView.enableSelection = true
        taggedListView.sortSelectedListFirst = true
        taggedListView.listHeaderLabel.font = UIFont(name: "Poppins-Bold", size: 20)
        taggedListView.listHeaderLabel.font = UIFont(name: "Poppins-Regular", size: 20)
        taggedListView.listHeaderLabel.font = UIFont(font: .avenirNextBold, size: 18)
        taggedListView.userId = CurrentUser.uid
        taggedListView.selectedListIds = self.selectedListIds
        taggedListView.selectedListIdTimes = self.selectedListIdTimes
        taggedListView.showAddListButton = false
        taggedListView.fetchUserLists()
        print("setupTaggedList | Creator List \(taggedListView.post?.creatorListId?.count) | User Tag Lists \(taggedListView.post?.selectedListId?.count)")
    }
    
    func reloadAddTag(){

        print("Reload \(self.selectedAddTags.count) Add Tags")
        additionalTagCollectionView.collectionViewLayout.invalidateLayout()
        additionalTagCollectionView.reloadData()
        additionalTagCollectionView.sizeToFit()
        
//        self.view.layoutIfNeeded()

        
//        let height = additionalTagCollectionView.collectionViewLayout.collectionViewContentSize.height
//        let width = additionalTagCollectionView.collectionViewLayout.collectionViewContentSize.width
////        let calcHeight = ceil(CGdisplayedAddTags.count / 3) * 30
////        additionalTagCollectionView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width - 15 - 15, height: height)
//
//        self.addTagHeight?.constant = height
        //print("AddtagHeight H: \(height) , W: \(width) | \(displayedAddTags.count)")
    }
    
    let autoTagDetailId = "AutoTagDetail"
    
    let addLinkView = UIView()
    
    var urlLink: String? = nil {
        didSet {
            self.refreshLinkButton()
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
    
    lazy var addLinkInput: PaddedTextField = {
        let tf = PaddedTextField()
        tf.font = UIFont.systemFont(ofSize: 14.0)
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.lightGray.cgColor
        tf.backgroundColor = UIColor.white
        tf.placeholder = "Add Link To Post"
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.layer.cornerRadius = 10
        tf.layer.masksToBounds = true
        tf.textColor = UIColor.mainBlue()
        tf.delegate = self
        return tf
    }()
    
    
    var displayedAddTags: [String] = []
    var selectedAddTags: [String] = [] {
        didSet {
            print("Categories Loaded: \(selectedAddTags)")
            self.reloadAddTag()
//            self.additionalTagCollectionView.reloadData()
        }
    }
    var defaultMeals = ["breakfast","brunch","lunch","dinner","latenight","other","dessert", "drinks","coffee"]


    let listTagId = "listTagId"
    
    func setupTagListCollectionView() {
        tagListCollectionView.register(TagListBarCell.self, forCellWithReuseIdentifier: listTagId)
        tagListCollectionView.delegate = self
        tagListCollectionView.dataSource = self
        tagListCollectionView.allowsMultipleSelection = false
        tagListCollectionView.showsHorizontalScrollIndicator = false
        tagListCollectionView.backgroundColor = UIColor.clear
        tagListCollectionView.isScrollEnabled = true
        tagListCollectionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapTagList)))
        tagListCollectionView.isUserInteractionEnabled = true
//        tagListCollectionView.backgroundColor = UIColor.yellow
        tagListCollectionView.reloadData()
    }
    
    
    func setupAdditionalTags(){
        
        additionalTagCollectionView.register(HomeFilterBarCell.self, forCellWithReuseIdentifier: autoTagDetailId)
        additionalTagCollectionView.delegate = self
        additionalTagCollectionView.dataSource = self
        additionalTagCollectionView.allowsMultipleSelection = false
        additionalTagCollectionView.showsHorizontalScrollIndicator = false
        additionalTagCollectionView.backgroundColor = UIColor.clear
        additionalTagCollectionView.isScrollEnabled = true
        displayedAddTags = selectedAddTags
        additionalTagCollectionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openAddTagSearch)))
        additionalTagCollectionView.isUserInteractionEnabled = true
//        additionalTagCollectionView.backgroundColor = UIColor.yellow
        
        for meal in defaultMeals {
            if !displayedAddTags.contains(meal) {
                displayedAddTags.append(meal)
            }
        }
        self.reloadAddTag()
        
    }
    
    let footerView = UploadPhotoFooter()
    
    
    func addFooter(){
        
        
        footerView.selectedStep = 2
        footerView.delegate = self
        let footerHeight = (UIScreen.main.bounds.height > 750 && !(self.isBookmarkingPost)) ? 50 : 0
        self.view.addSubview(footerView)
        footerView.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 0, height: CGFloat(50))

        
//        if UIScreen.main.bounds.height > 750 && !(self.isBookmarkingPost){
//            footerView.selectedStep = 2
//            footerView.delegate = self
//            self.view.addSubview(footerView)
//            footerView.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 0, height: 50)
//        }
        
//        if !self.footerView.isDescendant(of: self.view) {
//            scrollview.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 20).isActive = true
//        } else {
//            scrollview.bottomAnchor.constraint(equalTo: footerView.topAnchor, constant: 20).isActive = true
//        }

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
    
    
    
    func setupEmojiCollectionView(){
        suggestedEmojiCollectionView.backgroundColor = UIColor.clear
        suggestedEmojiCollectionView.register(UploadEmojiCell.self, forCellWithReuseIdentifier: emojiCellID)
        suggestedEmojiCollectionView.delegate = self
        suggestedEmojiCollectionView.dataSource = self
        suggestedEmojiCollectionView.allowsMultipleSelection = false
        suggestedEmojiCollectionView.showsHorizontalScrollIndicator = false
        
//        let emojiRef = UILongPressGestureRecognizer(target: self, action: #selector(MultSharePhotoController.handleLongPress(_:)))
//        emojiRef.minimumPressDuration = 0.5
//        emojiRef.delegate = self
//        suggestedEmojiCollectionView.addGestureRecognizer(emojiRef)
//        
//        
//        let emojiDoubleTap = UITapGestureRecognizer(target: self, action: #selector(MultSharePhotoController.handleDoubleTap(_:)))
//        emojiDoubleTap.numberOfTapsRequired = 2
//        emojiDoubleTap.delegate = self
//        suggestedEmojiCollectionView.addGestureRecognizer(emojiDoubleTap)
        
    }
    
    var defaultEmojis:[String] = []
    func setDefaultEmojis() {
        defaultEmojis = self.nonRatingEmojiTags
        // 1a. Caption Emojis
        defaultEmojis = self.appendEmojis(currentEmojis: defaultEmojis, newEmojis: captionEmojis)
        
        // 1b. Location Most Used Emojis
        defaultEmojis = self.appendEmojis(currentEmojis: defaultEmojis, newEmojis: self.locationMostUsedEmojis)
        
        // 1c. Most Used Emojis
        defaultEmojis = self.appendEmojis(currentEmojis: defaultEmojis, newEmojis: Array(CurrentUser.mostUsedEmojis.prefix(20)))
        
        // 1d. Default Emojis - Meal Emojis
        if mealTagEmojis.count > 0 {
            if mealTagEmojis.contains(where: { (emoji) -> Bool in
                return emoji.name == "breakfast" || emoji.name == "brunch"
            }) {defaultEmojis = self.appendEmojis(currentEmojis: defaultEmojis, newEmojis: breakfastFoodEmojis)}
            
            if mealTagEmojis.contains(where: { (emoji) -> Bool in
                return emoji.name == "lunch"
            }) {defaultEmojis = self.appendEmojis(currentEmojis: defaultEmojis, newEmojis: lunchFoodEmojis)}
            
            if mealTagEmojis.contains(where: { (emoji) -> Bool in
                return emoji.name == "dinner" || emoji.name == "latenight"
            }) {defaultEmojis = self.appendEmojis(currentEmojis: defaultEmojis, newEmojis: dinnerFoodEmojis)}
            
            if mealTagEmojis.contains(where: { (emoji) -> Bool in
                return emoji.name == "dessert" || emoji.name == "coffee"
            }) {defaultEmojis = self.appendEmojis(currentEmojis: defaultEmojis, newEmojis: snackEmojis)}
            
            if mealTagEmojis.contains(where: { (emoji) -> Bool in
                return emoji.name == "drinks"
            }) {defaultEmojis = self.appendEmojis(currentEmojis: defaultEmojis, newEmojis: allDrinkEmojis)}
        }
        
        
        //1e. Food Emojis
        defaultEmojis = self.appendEmojis(currentEmojis: defaultEmojis, newEmojis: SET_AllEmojis)
        
        self.filterEmojiSelections()
    }
    
    
    func filterEmojiSelections(){
        var tempEmojis: [String] = []
        self.emojiIndex.removeAll()

        if self.selectedEmojiFilter == nil || self.selectedEmojiFilter == "Recommended"{
            // AUTO - Show Caption Suggested, then User Recent, then all
            tempEmojis = self.nonRatingEmojiTags
            
            // 1b. Location Most Used Emojis
            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: defaultEmojis)
            
        } else if self.selectedEmojiFilter == recentEmoji {
//            tempEmojis.append(self.selectedEmojiFilter ?? "")
            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: CurrentUser.mostUsedEmojis)
//            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: allFoodEmojis)

        } else if self.selectedEmojiFilter == foodEmoji {
            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: SET_FoodEmojis)
        } else if self.selectedEmojiFilter == drinkEmoji {
            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: SET_DrinkEmojis)
        } else if self.selectedEmojiFilter == snackEmoji {
            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: SET_SnackEmojis)
        } else if self.selectedEmojiFilter == meatEmoji {
            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: SET_RawEmojis)
        } else if self.selectedEmojiFilter == vegEmoji {
            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: SET_VegEmojis)
        } else if self.selectedEmojiFilter == smileyEmoji {
            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: SET_SmileyEmojis)
        } else if self.selectedEmojiFilter == flagEmoji {
            Database.sortEmojisWithCounts(inputEmojis: SET_FlagEmojis, emojiCounts: CurrentUser.userTaggedEmojiCounts, completion: { emojis in
                SET_FlagEmojis = emojis
                tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: SET_FlagEmojis)
            })
        }  else if self.selectedEmojiFilter == otherEmoji {
            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: SET_OtherEmojis)
        }
        
        
        if self.selectedEmojiFilter == "Recent" || self.selectedEmojiFilter == "Recommended" {
            if let captionEmojis = self.uploadPost?.caption.removingWhitespaces().emojis {
                let tempCaptionEmojis = Array(Set(captionEmojis)).filter({ $0 != "️"})
                tempEmojis = (tempCaptionEmojis + tempEmojis)
                print("\(tempCaptionEmojis) : \(tempCaptionEmojis.count) Emojis from Caption")
            }
        }
        
        if let searchText = searchBar.text {
            if !searchText.isEmptyOrWhitespace() {
                tempEmojis = tempEmojis.filter({ (emoji) -> Bool in
                    return (EmojiDictionary[emoji]?.contains(searchText.lowercased()) ?? false)
                })
                let searchTextEmojis = Array(Set(searchText.emojis)).filter({ $0 != "️"})
                tempEmojis = searchTextEmojis + tempEmojis
                print("Filter Emojis by \(searchBar.text) : \(tempEmojis.count) Emojis | Found \(searchTextEmojis) in SearchBar")
            }
        }
        
        for emoji in self.nonRatingEmojiTags {
            if let index = tempEmojis.index(of: emoji) {
                var temp = tempEmojis.remove(at: index)
                tempEmojis.insert(temp, at: 0)
            }
        }
        
        self.emojiTagSelection = tempEmojis.filter({ $0.count > 0})
        self.suggestedEmojiCollectionView.reloadData()
        self.filterEmojiCollectionView.collectionViewLayout.invalidateLayout()
        self.filterEmojiCollectionView.reloadData()

    }
    
    func appendEmojis(currentEmojis: [String]?, newEmojis: [String]?) -> [String]{
        var tempEmojis: [String] = []
        var tempCurrentEmojis = currentEmojis ?? []
        var tempNewEmojis = newEmojis ?? []

        tempEmojis = tempCurrentEmojis
        
        for emoji in tempNewEmojis {
            if !tempEmojis.contains(emoji){
                tempEmojis.append(emoji)
            }
        }
        
        return tempEmojis
    }
    
    var emojiIndex:[String:Int] = [:]
//
//
//    func refreshEmojiTagSelections(){
//        var tempEmojis :[String] = []
//        self.emojiIndex.removeAll()
//
//        if (self.locationMostUsedEmojis.count) == 0 {
//            // NO LOCATION EMOJIS
//            print("refreshEmojiTagSelections | No Location Emojis | Hide Location Emoji Button")
////            self.showlocationMostUsedEmojiInd = false
////            self.locationMostUsedEmojiButton.isHidden = true
//        } else {
//            // HAS LOCATION EMOJIS - SHOW LOCATION EMOJI BUTTON
////            self.locationMostUsedEmojiButton.isHidden = false
//        }
//        self.view.updateConstraintsIfNeeded()
//
//        // 1a. Caption Emojis
//        tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: captionEmojis)
//
//        emojiIndex["caption"] = tempEmojis.count ?? 0
//        emojiIndex["mostused"] = tempEmojis.count ?? 0
//
//            // Default Emojis - Meal Emojis
//            if mealTagEmojis.count > 0 {
//                if mealTagEmojis.contains(where: { (emoji) -> Bool in
//                    return emoji.name == "breakfast" || emoji.name == "brunch"
//                }) {tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: breakfastFoodEmojis)}
//
//                if mealTagEmojis.contains(where: { (emoji) -> Bool in
//                    return emoji.name == "lunch"
//                }) {tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: lunchFoodEmojis)}
//
//                if mealTagEmojis.contains(where: { (emoji) -> Bool in
//                    return emoji.name == "dinner" || emoji.name == "latenight"
//                }) {tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: dinnerFoodEmojis)}
//
//                if mealTagEmojis.contains(where: { (emoji) -> Bool in
//                    return emoji.name == "dessert" || emoji.name == "coffee"
//                }) {tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: snackEmojis)}
//
////                if mealTagEmojis.contains(where: { (emoji) -> Bool in
////                    return emoji.name == "drinks"
////                }) {tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: allFoodEmojis + allDrinkEmojis)}
//            }
//
//        emojiIndex["food"] = tempEmojis.count ?? 0
//
//
//            //3. Drinks
//            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: allDrinkEmojis)
//
//        emojiIndex["drinks"] = tempEmojis.count ?? 0
//
//
//            //4. Default Emojis
//            tempEmojis = self.appendEmojis(currentEmojis: tempEmojis, newEmojis: allDefaultEmojis)
//
//        self.emojiTagSelection = tempEmojis
//        self.suggestedEmojiCollectionView.reloadData()
//    }

    
    @objc func handleDoubleTap(_ gestureReconizer: UITapGestureRecognizer) {
        
        let p = gestureReconizer.location(in: self.view)
        
        
        let point = self.suggestedEmojiCollectionView.convert(p, from:self.view)
        let indexPath = self.suggestedEmojiCollectionView.indexPathForItem(at: point)
        
        if let index = indexPath  {
            let cell = self.suggestedEmojiCollectionView.cellForItem(at: index) as! UploadEmojiCell
            guard let selectedEmoji = cell.uploadEmojis.text else {return}
            print("Double Tap Emoji: ", selectedEmoji   )
            self.addRemoveEmojiTags(emojiInput: selectedEmoji, emojiInputTag: EmojiDictionary[selectedEmoji] ?? "")
            
            // do stuff with your cell, for example print the indexPath
        } else {
            print("Could not find index path")
        }
    }
    
    func handleTripleTap(_ gestureReconizer: UITapGestureRecognizer) {
        
        let p = gestureReconizer.location(in: self.view)
        let point = self.suggestedEmojiCollectionView.convert(p, from:self.view)
        let indexPath = self.suggestedEmojiCollectionView.indexPathForItem(at: point)
        
        print(indexPath)
        
        if let index = indexPath  {
            
            let cell = self.suggestedEmojiCollectionView.cellForItem(at: index) as! UploadEmojiCell
            guard let selectedEmoji = cell.uploadEmojis.text else {return}
            print("Double Tap Emoji: ", selectedEmoji   )
            
            
            //                print(cell.uploadEmojis.text)
            
            self.addRemoveEmojiTags(emojiInput: selectedEmoji, emojiInputTag: EmojiDictionary[selectedEmoji] ?? "")
            // do stuff with your cell, for example print the indexPath
            
        } else {
            print("Could not find index path")
        }
    }
    
    func handleLongPress(_ gestureReconizer: UILongPressGestureRecognizer) {
        
        let p = gestureReconizer.location(in: self.view)
        let subViews = self.view.subviews
        if gestureReconizer.state != UIGestureRecognizer.State.recognized {
            
            let point = self.suggestedEmojiCollectionView.convert(p, from:self.view)
            let indexPath = self.suggestedEmojiCollectionView.indexPathForItem(at: point)
            
            if let index = indexPath  {
                let cell = self.suggestedEmojiCollectionView.cellForItem(at: index) as! UploadEmojiCell
                print(cell.uploadEmojis.text)
                guard let selectedEmoji = cell.uploadEmojis.text else {
                    print("Handle Long Press: ERROR, No Emoji")
                    return}
                
                // Clear Emojis if long press and contains emoji
                
                if nonRatingEmojiTags.contains(selectedEmoji){
                    self.addRemoveEmojiTags(emojiInput: selectedEmoji, emojiInputTag: EmojiDictionary[selectedEmoji] ?? "")
                }
                
                // Display Emoji Detail Label
                if let emojiTagLookup = ReverseEmojiDictionary.key(forValue: selectedEmoji) {
                    emojiDetailLabel.text = selectedEmoji + " " + emojiTagLookup.capitalizingFirstLetter()
                    emojiDetailLabel.sizeToFit()
                    emojiDetailLabel.alpha = 1
                }
            } else {
                print("Could not find index path")
            }
        }
            
        else if gestureReconizer.state != UIGestureRecognizer.State.changed {
            
            let point = self.suggestedEmojiCollectionView.convert(p, from:self.view)
            let indexPath = self.suggestedEmojiCollectionView.indexPathForItem(at: point)
            
            if let index = indexPath  {
                // Removes label subview when released
                emojiDetailLabel.alpha = 0
                
                let cell = self.suggestedEmojiCollectionView.cellForItem(at: index) as! UploadEmojiCell
            } else {
                print("Could not find index path")
            }
            return
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
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
        searchBar.searchBarStyle = .default
        searchBar.barTintColor = UIColor.white
        searchBar.layer.borderWidth = 1
        searchBar.layer.borderColor = UIColor.lightBackgroundGrayColor().cgColor
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
            let attributeDict = [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
            searchTextField!.attributedPlaceholder = NSAttributedString(string: "Search Emoji", attributes: attributeDict)
        }
        
        let textFieldInsideUISearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.textColor = UIColor.ianLegitColor()
        textFieldInsideUISearchBar?.font = UIFont.systemFont(ofSize: 12)
        
        
        for s in searchBar.subviews[0].subviews {
            if s is UITextField {
                s.layer.borderWidth = 0.5
                s.layer.borderColor = UIColor.gray.cgColor
                s.layer.cornerRadius = 5
                s.clipsToBounds = true
//                s.layer.backgroundColor = UIColor.lightBackgroundGrayColor().cgColor
//                s.backgroundColor = UIColor.lightBackgroundGrayColor()
                s.layer.backgroundColor = UIColor.white.cgColor
                s.backgroundColor = UIColor.white
            }
        }
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.filterEmojiSelections()
//
//        if (searchText.count == 0) {
//            self.isFiltering = false
//        } else {
//            self.filterEmojiSelections()
//        }
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
        
        self.userListNameDic = [:]
        for list in CurrentUser.lists {
            self.userListNameDic[list.id!] = list.name
        }
        
        
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
//            filterContentForSearchText(searchBar.text!)
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
            
            Database.saveLocationToFirebase(post: self.uploadPost)
            
            SVProgressHUD.dismiss()
            
            self.dismiss(animated: true, completion: {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                self.currentUploadingPostCheck = nil
                print("savePostToDatabase | Complete | Share Button ENABLED")
                NotificationCenter.default.post(name: SharePhotoListController.updateFeedNotificationName, object: nil)
                NotificationCenter.default.post(name: SharePhotoListController.updateProfileFeedNotificationName, object: nil)
                NotificationCenter.default.post(name: SharePhotoListController.updateListFeedNotificationName, object: nil)
                NotificationCenter.default.post(name: TabListViewController.refreshListNotificationName, object: nil)
                
            })
        }
    }
    
    func handleEditPost(){
        print("Selected List: \(self.selectedList)")
        var listIds: [String:String]? = [:]
        if self.selectedListIds.count > 0 {
            for id in self.selectedListIds {
                let name = CurrentUser.lists.first { (list) -> Bool in
                    return list.id == id
                }?.name
                listIds![id] = name
            }
        }
        
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
        
        
        
        
        Database.editPostToDatabase(imageUrls: imageUrls, postId: postId, uploadDictionary: uploadPostDictionary, uploadLocation: uploadPostLocation, prevPost: preEditPost) {
            
            
//            self.dismiss(animated: true, completion: {
//                self.navigationItem.rightBarButtonItem?.isEnabled = true
//                NotificationCenter.default.post(name: SharePhotoListController.updateFeedNotificationName, object: nil)
//                NotificationCenter.default.post(name: SharePhotoListController.updateProfileFeedNotificationName, object: nil)
//                NotificationCenter.default.post(name: SharePhotoListController.updateListFeedNotificationName, object: nil)
//                NotificationCenter.default.post(name: NewSinglePostView.editSinglePostNotification, object: nil)
//                //            NotificationCenter.default.post(name: SharePhotoListController.updateFeedNotificationName, object: nil)
//            })
        }
        
        
        // Update Post Cache
        var tempPost = self.uploadPost
        tempPost?.selectedListId = listIds
        tempPost?.creatorListId = listIds
        
        if (tempPost?.selectedListId?.count)! > 0 {
            tempPost?.hasPinned = true
        }
        
        postCache[(self.uploadPost?.id)!] = tempPost
        self.delegate?.refreshPost(post: tempPost!)
        SVProgressHUD.dismiss()
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        self.delegate?.refreshPost(post: tempPost!)
        NotificationCenter.default.post(name: SharePhotoListController.updateFeedNotificationName, object: nil)
        NotificationCenter.default.post(name: SharePhotoListController.updateProfileFeedNotificationName, object: nil)
//            NotificationCenter.default.post(name: SharePhotoListController.updateListFeedNotificationName, object: nil)
        let editPostId:[String: String] = ["editPostId": postId]
        NotificationCenter.default.post(name: NewSinglePostView.editSinglePostNotification, object: nil, userInfo: editPostId)
        //            NotificationCenter.default.post(name: SharePhotoListController.updateFeedNotificationName, object: nil)
        
        self.dismiss(animated: true, completion: {

        })
        
        
        
    }
    
    @objc func handleAddPostToList(){
        
        navigationItem.rightBarButtonItem?.isEnabled = false
        SVProgressHUD.show(withStatus: "Adding To List")
        
        if (Auth.auth().currentUser?.isAnonymous)!{
            print("Guest User Adding Post to List")
            let listAddDate = Date().timeIntervalSince1970
            for list in self.selectedList {
                // Update Current User List
                if let listIndex = CurrentUser.lists.firstIndex(where: { (currentList) -> Bool in
                    currentList.id == list.id
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
            for list in self.selectedList {
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
        for list in self.selectedList {
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
        if collectionView == additionalTagCollectionView {
//            return displayedAddTags.count
            print("additionalTagCollectionView \(selectedAddTags.count)")
            return selectedAddTags.count
        } else if collectionView == suggestedEmojiCollectionView {
            return emojiTagSelection.count
        } else if collectionView == filterEmojiCollectionView {
            return self.selectedEmojiFilterOptions.count
        } else if collectionView == tagListCollectionView {
            return self.selectedList.count
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == additionalTagCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: autoTagDetailId, for: indexPath) as! HomeFilterBarCell
            let option = selectedAddTags[indexPath.row].lowercased()
            
            
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
            cell.uploadLocations.font = isSelected ? UIFont(font: .avenirNextDemiBold, size: 15) : UIFont(font: .avenirNextRegular, size: 15)
            cell.uploadLocations.sizeToFit()
            cell.sizeToFit()
            
            //            cell.uploadLocations.font = isSelected ? UIFont(name: "Poppins-Bold", size: 13) : UIFont(name: "Poppins-Regular", size: 13)
            cell.layer.borderColor = isSelected ? UIColor.clear.cgColor : UIColor.lightGray.cgColor
            cell.backgroundColor = isSelected ? UIColor.ianOrangeColor() : UIColor.backgroundGrayColor()
            return cell
        }
        // SUGGESTED EMOJI  CELLS
        else if collectionView == suggestedEmojiCollectionView {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emojiCellID, for: indexPath) as! UploadEmojiCell
            cell.uploadEmojis.text = self.emojiTagSelection[indexPath.item]
//            cell.uploadEmojis.font = cell.uploadEmojis.font.withSize((cell.uploadEmojis.text?.containsOnlyEmoji)! ? EmojiSize.width * 0.8 : 10)
            var containsEmoji = (self.nonRatingEmojiTags.contains(cell.uploadEmojis.text!))
            cell.isRatingEmoji = false
            
            
            //Highlight only if emoji is tagged, dont care about caption
            cell.layer.borderColor = containsEmoji ? UIColor.ianLegitColor().cgColor : UIColor.rgb(red: 221, green: 221, blue: 221).cgColor
            cell.layer.borderWidth = containsEmoji ? 2 : 1
            cell.delegate = self
            var isSelected = self.nonRatingEmojiTags.contains(cell.uploadEmojis.text!)
            cell.isSelected = self.nonRatingEmojiTags.contains(cell.uploadEmojis.text!)
            cell.sizeToFit()            
            var noDic = EmojiDictionary[self.emojiTagSelection[indexPath.item]] == nil
            if noDic{
                cell.backgroundColor = noDic ? UIColor.ianLightGrayColor().withAlphaComponent(0.6) : UIColor.white
            }


            return cell
            
        }   else if collectionView == filterEmojiCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emojiFilterCellID, for: indexPath) as! EmojiFilterCell
            var isEmojiFilter = (self.selectedEmojiFilter == selectedEmojiFilterOptions[indexPath.row])
            
            cell.uploadLocations.text = selectedEmojiFilterOptions[indexPath.row]
            cell.backgroundColor = isEmojiFilter ? UIColor.legitColor() : UIColor.clear
            cell.uploadLocations.textColor = isEmojiFilter ? UIColor.white : UIColor.mainBlue()
//            cell.uploadLocations.font = UIFont(font: .avenirNextDemiBold, size: 13)
            cell.uploadLocations.font = isEmojiFilter ? UIFont(font: .avenirNextBold, size: 13) : UIFont(font: .avenirNextBold, size: 13)
            cell.bottomDiv.isHidden = true
            cell.uploadLocations.sizeToFit()
            cell.sizeToFit()
            return cell
        }
        else if collectionView == tagListCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: listTagId, for: indexPath) as! TagListBarCell

            let listId = self.selectedList[indexPath.row].id
            
//            let listnameLabelText = NSMutableAttributedString()
//
//            let image1Attachment = NSTextAttachment()
//            let inputImage = #imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate)
//            image1Attachment.image = inputImage.alpha(1)
//            image1Attachment.bounds = CGRect(x: 0, y: (cell.uploadLocations.font.capHeight - (inputImage.size.height)).rounded() / 2, width: inputImage.size.width, height: inputImage.size.height)
//
//            let image1String = NSAttributedString(attachment: image1Attachment)
//            listnameLabelText.append(image1String)
//
//            var listName = "N/A"
//            if let tempListName = self.userListNameDic[listId!] {
//                listName = tempListName
//            } else {
//                print("ERROR NO LIST FOR \(listId)")
//            }
//
//            let listnameString = NSMutableAttributedString(string: " \((listName))", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 14)])
//            listnameLabelText.append(listnameString)

            if let listName = self.userListNameDic[listId!] {
                cell.uploadLocations.text = listName
            } else {
                cell.uploadLocations.text = "N/A"
            }
            
            cell.uploadLocations.textColor = UIColor.white
            cell.uploadLocations.font = UIFont(font: .avenirNextDemiBold, size: 12)
            cell.backgroundColor = UIColor.mainBlue()
            cell.uploadLocations.sizeToFit()
            cell.sizeToFit()

            //            cell.uploadLocations.font = isSelected ? UIFont(name: "Poppins-Bold", size: 13) : UIFont(name: "Poppins-Regular", size: 13)
            cell.layer.borderColor = UIColor.ianLegitColor().cgColor
            cell.layer.borderWidth = 0
//            cell.backgroundColor = UIColor.white

            return cell
        }
        
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emojiFilterCellID, for: indexPath) as! EmojiFilterCell
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == additionalTagCollectionView {
            self.openAutoTag(sender : self.searchAddTagButton)
//            let option = displayedAddTags[indexPath.item].lowercased()
//            if self.selectedAddTags.contains(option) {
//                if let index = self.selectedAddTags.firstIndex(of: option) {
//                    self.selectedAddTags.remove(at: index)
//                }
//            } else {
//                self.selectedAddTags.append(option)
//            }
//            print("selectedAddTags | \(selectedAddTags)")
//            self.setupAdditionalTags()
        } else if collectionView == filterEmojiCollectionView {
            let cell = collectionView.cellForItem(at: indexPath) as! EmojiFilterCell

            guard let filter = cell.uploadLocations.text else {
                return
            }
            
            if self.selectedEmojiFilter == filter {
                self.selectedEmojiFilter = nil
            } else {
                self.selectedEmojiFilter = filter
            }
            print("filterEmojiCollectionView | SelectedEmojiFilter | \(self.selectedEmojiFilter)")
            
            self.filterEmojiSelections()
            
        } else if collectionView == suggestedEmojiCollectionView{
//            let cell = collectionView.cellForItem(at: indexPath) as! UploadEmojiCell
//            let pressedEmoji = cell.uploadEmojis.text!
//            print("Emoji Cell Selected", pressedEmoji)
//
//            if self.nonRatingEmojiTags.contains(pressedEmoji) == false
//            {   // Emoji not in caption or tag
//
//                // Show Emoji Detail
//                if let emojiTagLookup = ReverseEmojiDictionary.key(forValue: pressedEmoji) {
//                    emojiDetailLabel.text = pressedEmoji + " " + emojiTagLookup
//                    self.fadeViewInThenOut(view: emojiDetailLabel, delay: 1)
//                }
//
//                self.addRemoveEmojiTags(emojiInput: pressedEmoji, emojiInputTag: ReverseEmojiDictionary.key(forValue: pressedEmoji) ?? "")
//
//            } else if self.nonRatingEmojiTags.contains(pressedEmoji) == true {
//                // Emoji is Tagged, Remove emoji from captions and selected emoji
//                self.addRemoveEmojiTags(emojiInput: pressedEmoji, emojiInputTag: ReverseEmojiDictionary.key(forValue: pressedEmoji) ?? "")
//            }
        }
        else if collectionView == tagListCollectionView {
            self.didTapTagList()
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        if collectionView == suggestedEmojiCollectionView{
            let cell = collectionView.cellForItem(at: indexPath) as! UploadEmojiCell
            let pressedEmoji = cell.uploadEmojis.text!
            print("Emoji Cell Deselected", pressedEmoji)
            
            self.addRemoveEmojiTags(emojiInput: pressedEmoji, emojiInputTag: ReverseEmojiDictionary.key(forValue: pressedEmoji) ?? "")
            
        }
        // Deselect Doesn't work for emojis since scells are constantly being reloaded and hence selection is restarted
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
            
            var newSelectedListCount = self.selectedList.count ?? 0
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
                print("Selected Lists | \(self.selectedList.count) | \(displayList[indexPath.row].id) | \(displayList[indexPath.row].isSelected)")
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
        print("Received \(post.selectedListId?.count ?? 0) List from Tag List View : UploadPhotoControllerMore")

        // REFRESH FROM TAGGING LIST
        if (post.selectedListId?.count ?? 0) > 0 {
            self.tagListButton.setTitle(" Tagging \(post.selectedListId?.count ?? 0) List", for: .normal)
            self.tagListHeader.text = "Tagging \(post.selectedListId?.count ?? 0) List"
            self.uploadPost?.selectedListId = post.selectedListId ?? [:]
        } else {
            self.tagListButton.setTitle(" Tag Post To List", for: .normal)
            self.tagListHeader.text = "Tagging \(post.selectedListId?.count ?? 0) List"
            self.uploadPost?.selectedListId = [:]
        }
        self.updateSelectedLists()

//        refreshBookmarkHeader()
    }
    
    func refreshTagListButton() {
        if self.selectedListIds.count > 0 {
            self.tagListButton.setTitle(" Tagged \(self.selectedListIds.count ?? 0) List", for: .normal)
        } else {
            self.tagListButton.setTitle(" Tag Post To List", for: .normal)
        }
    }
    
    func updateSelectedLists() {
        self.selectedList = []
        self.selectedListIds = []
        for (id, date) in (self.uploadPost?.selectedListId ?? [:]) {
            let templist = CurrentUser.lists.filter { (list) -> Bool in
                return list.id == id
            }
            if templist.count > 0 {
                var curList = templist[0]
                self.selectedList.append(curList)
                self.selectedListIds.append(curList.id ?? "")
            }
        }
        self.taggedListView.selectedListIds = self.selectedListIds
        self.taggedListView.selectedListIdTimes = self.selectedListIdTimes
        self.taggedListView.fetchUserLists()
        
//        self.tagListCollectionView.isHidden = self.selectedList.count == 0
//        self.tagListHeader.isHidden = self.tagListCollectionView.isHidden
//        self.tagListButton.isHidden = !self.tagListCollectionView.isHidden
//        self.tagListCollectionView.reloadData()
        
//        if self.selectedList.count == 0 {
//            self.tagListButton.setTitle(" Tag To List", for: .normal)
//        } else {
//            self.tagListButton.setTitle(" Tagged \(self.selectedList.count ?? 0) List", for: .normal)
//        }
    }
    
    func refreshBookmarkHeader() {
        let listCount = self.bookmarkView.selectedList?.count
        self.bookmarkHeader.text = (listCount == 0) ? "Tag List" : "Tag \(listCount!) Lists"
        self.bookmarkHeader.sizeToFit()
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
    
    
    
    func didTapRatingEmoji(emoji: String) {
        
    }
    
    func didTapNonRatingEmoji(emoji: String) {
        print("Non Rating Emoji Cell Selected", emoji)
        
        var tempEmoji = emoji
        if let replace = AdjustEmojiDictionary[tempEmoji] {
            tempEmoji = replace
        }
        
        var noDic = EmojiDictionary[tempEmoji] == nil
        if noDic && self.nonRatingEmojiTags.contains(tempEmoji) == false {
            suggestEmojiDic(emoji: tempEmoji)
            return
        }

        
        if self.nonRatingEmojiTags.contains(tempEmoji) == false {
            if let emojiTagLookup = EmojiDictionary[tempEmoji] {
                self.displayEmojiDetailLabel(emoji: tempEmoji, name: emojiTagLookup)
            } else {
                print("No Emoji Detail Text For:", tempEmoji)
            }
        }
        self.addRemoveEmojiTags(emojiInput: tempEmoji, emojiInputTag: EmojiDictionary[tempEmoji] ?? "")
    }
    
    func displayEmojiDetailLabel(emoji: String?, name: String?) {
        emojiDetailLabel.text = (emoji ?? "") + " " + (name ?? "").capitalizingFirstLetter()
        emojiDetailLabel.sizeToFit()
        emojiDetailLabel.alpha = 1
        self.fadeViewInThenOut(view: emojiDetailLabel, delay: 1)
    }
    
// LET USERS ADD THEIR OWN NAMES TO EMOJIS. COULD LET PEOPLE RENAME THEIR EMOJIS?
    
    @objc func suggestEmojiDic(emoji: String){
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Add Emoji Name", message: "\(emoji) emoji has no name yet. Would you like to add one to your personal Emoji Dictionary?", preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.text = ""
            textField.placeholder = "Insert New Emoji Name"
        }
        
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "Add Name", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            print("New Emoji Definion for \(emoji) : \(textField?.text)")
            if textField?.text?.isEmptyOrWhitespace() ?? true{
                self.alert(title: "Emoji Name Error", message: "Please insert a new name for \(emoji) emoji")
            }
            guard let newEmojiName = textField?.text else {return}
            Database.updateEmojiNameForUser(emojiName: newEmojiName, emoji: emoji, userUid: CurrentUser.uid)
            self.addRemoveEmojiTags(emojiInput: emoji, emojiInputTag: newEmojiName)
            SVProgressHUD.showSuccess(withStatus: "Added '\(newEmojiName)' to \(emoji)")
            SVProgressHUD.dismiss(withDelay: 1)
        }))
        
        alert.addAction(UIAlertAction(title: "No, Tag Anyway", style: .default, handler: { (action: UIAlertAction!) in
            self.addRemoveEmojiTags(emojiInput: emoji, emojiInputTag: "")
            print("No, Tag Anyway")
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
        
        
    }
    
    
    
    func fadeViewInThenOut(view : UIView, delay: TimeInterval) {
        
        let animationDuration = 0.25
        
        // Fade in the view
        UIView.animate(withDuration: animationDuration, animations: { () -> Void in
            view.alpha = 1
        }) { (Bool) -> Void in
            
            // After the animation completes, fade out the view after a delay
            
            UIView.animate(withDuration: animationDuration, delay: delay, options: .curveEaseInOut, animations: { () -> Void in
                view.alpha = 0
            },
                           completion: nil)
        }
    }
    
    func addRemoveEmojiTags(emojiInput: String?, emojiInputTag: String?){
        
        var tempEmojiInput: String? = emojiInput
        var tempEmojiInputTag: String? = emojiInputTag
        
        if emojiInput?.containsOnlyEmoji == false {
            print("EmojiTagUntag: Error, Emoji Input not emoji | \(emojiInput)")
            return
        }
        
        // Fill Blank Emoji Tag
        if emojiInput != nil && emojiInputTag ==  nil  {
            if let tempTag = EmojiDictionary[emojiInput!] {
                tempEmojiInputTag = tempTag
                print("Found Emoji Dict for \(emojiInput) | Tag = \(tempEmojiInputTag)")
            } else {
                tempEmojiInputTag = emojiInput
                print("NO Emoji Dict for \(emojiInput) | Tag = \(tempEmojiInputTag)")
            }
        }
        
        // Fill Blank Emoji
        if emojiInput == nil && emojiInputTag !=  nil  {
            if let tempEmoji = EmojiDictionary.key(forValue: emojiInputTag!) {
                print("Found Emoji for \(emojiInputTag) | Emoji = \(tempEmoji)")
                tempEmojiInput = tempEmoji
            } else {
                print("NO Emoji for \(emojiInputTag) | ERROR")
                tempEmojiInput = nil
            }
        }
        
        if emojiInput == nil && emojiInputTag == nil {
            print("No Emoji Inputs |emojiInput \(emojiInput) |emojiInputTag \(emojiInputTag) | CLEAR ALL")
            self.nonRatingEmojiTags = []
            self.nonRatingEmojiTagsDict = []
            self.updateEmojiTextView()
            self.suggestedEmojiCollectionView.reloadData()
            return
        }
        
        guard let _ = tempEmojiInput else {
            print("EmojiTagUntag: Error, No Emoji: ", tempEmojiInput)
            return
        }
        
        guard let _ = tempEmojiInputTag else {
            print("EmojiTagUntag: Error, No Emoji Tag: ", tempEmojiInputTag)
            return
        }
        
        
        if let index = nonRatingEmojiTags.firstIndex(of: tempEmojiInput!){
            nonRatingEmojiTags.remove(at: index)
            nonRatingEmojiTagsDict.remove(at: index)
            emojiDetailLabel.alpha = 0
            self.suggestedEmojiCollectionView.reloadData()
            print("Removing \(tempEmojiInput!) \(tempEmojiInputTag!)) | addRemoveEmojiTags")
            
        } else {
            if nonRatingEmojiTags.count >= 3 {
                print("Replacing Last Emoji | \(tempEmojiInput!) \(tempEmojiInputTag!)) | 3 Emojis | addRemoveEmojiTags ")
                self.alert(title: "Too Many Emojis", message: "Each post is limited to 3 emoji tags. Please unselect one or more emojis before adding a new one.")
                self.suggestedEmojiCollectionView.reloadData()
                return
//                nonRatingEmojiTags[nonRatingEmojiTags.count - 1] = tempEmojiInput!
//                nonRatingEmojiTagsDict[nonRatingEmojiTagsDict.count - 1] = tempEmojiInputTag!
            } else {
                print("Adding \(tempEmojiInput!) \(tempEmojiInputTag!)) | \(nonRatingEmojiTags.count) Emojis | addRemoveEmojiTags")
                nonRatingEmojiTags.append(tempEmojiInput!)
                nonRatingEmojiTagsDict.append(tempEmojiInputTag!)
            }
            
            
            //            nonRatingEmojiTags = [tempEmojiInput] as! [String]
            //            nonRatingEmojiTagsDict = [tempEmojiInputTag] as! [String]
        }
        self.updateEmojiTextView()
//        self.suggestedEmojiCollectionView.reloadData()
    }
    

    
    func didTapListCancel(post:Post) {
        
    }
    
    
    func didTapComment(post: Post) {
        // Disable Comment From Here
    }
    
    func didTapBookmark(post: Post) {
        // Disable Bookmark from here
    }
    
    
    func didTapList(list: List?) {
        guard let list = list else {return}
        guard let listId = list.id else {return}
        if !self.selectedListIds.contains(listId) {
            self.selectedListIds.append(listId)
            self.selectedList.append(list)
            self.selectedListIdTimes[listId] = Date()
        } else {
            self.selectedListIds.removeAll { $0 == listId }
            self.selectedList.removeAll { (list) -> Bool in
                return list.id == listId
            }
            self.selectedListIdTimes.removeValue(forKey: listId)
        }
//        self.taggedListView.selectedListIds = self.selectedListIds
//        self.taggedListView.selectedListIdTimes = self.selectedListIdTimes
//        self.taggedListView.fetchUserLists()
    }
    
    func didTapUser(user: User?) {
    }
    
    func didTapAddList() {
        self.extCreateNewList()
    }
    
    func doShowListView() {
        
    }
    
    func doHideListView() {
        
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
