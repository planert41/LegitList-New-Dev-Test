//
//  ListView.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/7/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
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

protocol ListViewControllerDelegate {
    func listSelected(list: List?)
    func deleteList(list:List?)
}

class ListViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ListPhotoCellDelegate, SortFilterHeaderDelegate, EmptyDataSetSource, EmptyDataSetDelegate, GridPhotoCellDelegate, EmojiButtonArrayDelegate, UIGestureRecognizerDelegate, MainSearchControllerDelegate, SearchFilterControllerDelegate, NewListPhotoCellDelegate, FullPictureCellDelegate, ListViewHeaderDelegate, TestGridPhotoCellDelegate, SharePhotoListControllerDelegate, UICollectionViewDragDelegate, UICollectionViewDropDelegate, NewHeaderDelegate, UISearchBarDelegate {
    func didTapLike(post: Post) {
        
    }
    

    static let refreshListViewNotificationName = NSNotification.Name(rawValue: "RefreshListView")

    let bookmarkCellId = "bookmarkCellId"
    let fullCellId = "fullCellId"
    let gridCellId = "gridCellId"
    let listHeaderId = "listHeaderId"
//    var tabViewInd: Bool = false
    
    var tabBarDisplayNavigationBar: Bool = false
    var delegate: ListViewControllerDelegate?
    
    override func viewWillAppear(_ animated: Bool) {
//        SVProgressHUD.show(withStatus: "Loading Posts")
        navigationController?.isNavigationBarHidden = false
        imageCollectionView.collectionViewLayout.invalidateLayout()
        imageCollectionView.layoutIfNeeded()
        animate()
    }
    
    private func animate(){
        guard let coordinator = self.transitionCoordinator else {
            return
        }
        
        coordinator.animate(alongsideTransition: {
            [weak self] context in
            self?.setupNavigationItems()
            }, completion: nil)
    }

    
    
    // INPUT
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
    
//    var tempRank:[String:Int] = [:]
    
//    func checkRankForList(list: List?, completion: @escaping (List) -> ()) {
//
//        guard let tempList = list else {
//            print("checkRankForList | No List")
//            return
//        }
//
//        guard let postIds = tempList.postIds else {
//            print("checkRankForList | No Posts | \(tempList.id)")
//            completion(tempList)
//            return
//        }
//
//        if (postIds.count) > 0 && tempList.listRanks.count == 0 {
//            var tempRank: [String: Int] = [:]
//            for (index, x) in postIds.enumerated() {
//                tempRank[x.key] = index + 1
//            }
//            self.currentDisplayList?.listRanks = tempRank
//            print("ListViewController | checkRankForList | No List Default | \(tempList.postIds?.count) Posts | \(tempList.name)")
//        }
//
//        completion(tempList)
//
//    }
    
    var currentDisplayList: List? = nil {
        didSet{
            print(" DISPLAYING | \(currentDisplayList?.name) | \(currentDisplayList?.id) | \(currentDisplayList?.postIds?.count) Posts |List_ViewController")

//            print("currentDisplayList | \(currentDisplayList?.name) | \(currentDisplayList?.id) | \(currentDisplayList?.postIds?.count)")
            // CLEAR SEARCH BAR
            self.clearCaptionSearch()
            self.updateListLabels()
            self.setupListFollowButton()

            fetchPostsForList()
            if displayUser?.uid != currentDisplayList?.creatorUID{
                print("Fetching \(currentDisplayList?.creatorUID) for List \(currentDisplayList?.name): \(currentDisplayList?.id)")
                fetchUserForList()
            }
            
            // Set Drop Down Menu
            if let index = displayedLists?.firstIndex(where: { (temp_list) -> Bool in
                temp_list.id == currentDisplayList?.id
            }){
                dropDownMenu.selectRow(at: index)
            }
            
            self.tempRank = currentDisplayList?.listRanks
//            print("currentDisplayList | Set Temp Rank | \(self.tempRank?.count)")
            
        }
    }
        
    // Used to fetch lists
    var displayUser: User? = nil {
        didSet{
            print("Current display user: \(displayUser?.username) | \(displayUser?.uid)")
            self.setupUser()
        }
    }
    
    func setupUser(){
        guard let displayUser = displayUser else {return}
        usernameLabel.text = displayUser.username
        usernameLabel.sizeToFit()
        usernameLabel.adjustsFontSizeToFitWidth = true
        usernameLabel.sizeToFit()
        
        usernameLabel.isUserInteractionEnabled = true
        let usernameTapGesture = UITapGestureRecognizer(target: self, action: #selector(usernameTap))
        usernameLabel.addGestureRecognizer(usernameTapGesture)
        
        let profileImageUrl = displayUser.profileImageUrl
        userProfileImageView.loadImage(urlString: profileImageUrl)
    }
    
    @objc func usernameTap(){
        guard let displayUser = displayUser else {return}
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = displayUser.uid
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    var displayedLists: [List]? = [] {
        didSet{
            guard let uid = Auth.auth().currentUser?.uid else {return}
            guard var displayedLists = self.displayedLists else {
                // If Displayed list is null, set to default
                self.displayedLists = [emptyLegitList,emptyBookmarkList]
                self.displayedListNames = [legitListName, bookmarkListName]
                return
            }
            
//            print("Loaded Displayed List | \(self.displayedLists)")
//            
//            print("DisplayUser: \(displayUser?.uid) | uid: \(uid)")
            
            if displayUser?.uid != uid {
                // Exclude Private list if not current user
                if let filteredList = self.displayedLists?.filter({ (list) -> Bool in
                    return list.publicList == 1
                }){
                    print("Filtering Private Lists: \((self.displayedLists?.count)! - filteredList.count) Lists")
                    self.displayedLists = filteredList
                } else {
                    self.displayedLists = []
                }
            }
            
            // Populate Displayed List Names
            var tempListNames: [String] = []
            for list in self.displayedLists! {
                    // Add List Name and List Count
//                    var listName = "\(list.name) (\((list.postIds?.count)!))"

                    tempListNames.append(list.name)
            }
            displayedListNames = tempListNames
            print("Final Display Names: ", displayedListNames)
            self.imageCollectionView.reloadData()
            
        }
    }

    
    var displayedListNames: [String] = [legitListName, bookmarkListName] {
        didSet{
            setupDropDown()
            setupNavigationItems()
        }
    }

//    var menuView: BTNavigationDropdownMenu!
    var dropDownMenu = DropDown()

    var displayListView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.selectedColor().withAlphaComponent(0.5)
        view.backgroundColor = UIColor.white

        return view
    }()
    
    let postCountLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.clear
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let followerCountLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.clear
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let listEmojiLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.clear
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let listNameLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(font: .helveticaNeueBold, size: 20)
        label.textColor = UIColor.legitColor()
//        label.textColor = UIColor.init(hexColor: "F1C40F")
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.clear
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 1
        
        return label
    }()
    
    let saveRankButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "rank_arrow").resizeImageWith(newSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal), for: .normal)
        button.backgroundColor = UIColor.mainBlue()
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitle("Save", for: .normal)
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 3, bottom: 3, right: 5)

        button.addTarget(self, action: #selector(savePostRankForList), for: .touchUpInside)
        button.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        button.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        button.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        return button

    }()
    
    func setupRankView(){

        if  self.viewFilter?.filterSort == "Rank" {
//            rankButton.isHidden = false
            
        // SETUP DEFAULT LIST
            let listPostCount = self.currentDisplayList?.postIds?.count ?? 0
            let listRankCount = self.currentDisplayList?.listRanks.count ?? 0
            
            if listRankCount == 0 && listPostCount > 0 {
                // NOT LIST OWNER - NO RANKS
                if self.currentDisplayList?.creatorUID != Auth.auth().currentUser?.uid {
                    print("ListViewController | setupRankView | Not List Owner")
                    self.alert(title: "No Rank", message: "User Has No Ranks")
                    self.headerSortSelected(sort: ListSortDefault)
                    return
                }
                
                    // LIST OWNER - CREATE DEFAULT RANK
                else {
                        print("setupRankView | Setup Default Rank By Rating For \(self.currentDisplayList?.name)")
                        let sortedPost = self.fetchedPosts.sorted { (p1, p2) -> Bool in
                            return (p1.rating! > p2.rating!)
                        }
                    
                        var tempRank: [String:Int] = [:]
                        for (index, list) in sortedPost.enumerated() {
                            if let listId = list.id {
                                tempRank[listId] = index + 1
                            }
                        }
                        self.tempRank = tempRank
                    }
                }
            
            // SHOW SAVE RANK BUTTON BECAUSE LIST HAS NO RANKS
            self.saveRankButton.isHidden = !(listRankCount == 0)
            
            // RERANK LIST
//                self.viewFilter?.clearFilter()
                self.viewFilter?.filterSort = "Rank"
                self.refreshPostsForFilter()
        }   else {
            saveRankButton.isHidden = true
        }
    }
    
    var tempRank:[String:Int]? = [:]
    
    func rerankPostForList(){
        print("rerankPostForList")
        
        // ONLY RERANK IF THERE IS THE SAME AMOUNT OF POSTS - SO NO FILTERED
        guard let filter = self.viewFilter else {
            print("rerankPostForList | No Filter")
            return
        }
        
        if self.fetchedPosts.count == self.currentDisplayList?.postIds?.count && !(self.viewFilter?.isFiltering)!{
            var tempRank: [String:Int] = [:]
            for (index, postObject) in self.fetchedPosts.enumerated() {
                var tempPost = postObject
                tempRank[(postObject.id)!] = index + 1
            }
            self.tempRank = tempRank
            if self.tempRank != self.currentDisplayList?.listRanks {
                self.saveRankButton.isHidden = false
            } else {
                self.saveRankButton.isHidden = true
            }
            self.imageCollectionView.reloadData()
            self.imageCollectionView.reloadItems(at: imageCollectionView.indexPathsForVisibleItems)
            
        }
    }
    
    @objc func savePostRankForList(){
        guard let currentList = self.currentDisplayList else {
            print("ListViewController | savePostRankForList | ERROR | No List")
            return
        }
        if !(self.viewFilter?.isFiltering)! {
            var tempRank: [String:Int] = [:]
            for (index, object) in self.fetchedPosts.enumerated() {
                tempRank[(object.id)!] = index + 1
            }
        // SAVE RANKS IF DIFFERENT RANK FROM SAVED LIST OR DIFFERENT COUNT
            if (tempRank != self.currentDisplayList?.listRanks) || (self.currentDisplayList?.listRanks.count != tempRank.count){
                print("ListViewController | savePostRankForList")
                Database.updateRankForList(listId: currentList.id, newRank: tempRank)
                SVProgressHUD.showSuccess(withStatus: "New Rankings Saved")
                SVProgressHUD.dismiss(withDelay: 1)
                self.tempRank = tempRank
                self.saveRankButton.isHidden = true
            } else {
                print("ListViewController | savePostRankForList | Same Ranking")
                self.saveRankButton.isHidden = true
            }
            
        } else {
            print("ListViewController | savePostRankForList | IsFiltering Is \(self.viewFilter?.isFiltering)")
            self.alert(title: "Saving List Error", message: "List ranks cannot be saved while list is being filtered")
        }
    }
    
    
    let listOptionsButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "gear").withRenderingMode(.alwaysOriginal), for: .normal)
        button.tintColor = UIColor.legitColor()
        button.backgroundColor = UIColor.clear
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(userOptionList), for: .touchUpInside)
        return button
    }()
    
    @objc func userOptionList(){
        
        let optionsAlert = UIAlertController(title: "User Options", message: "", preferredStyle: UIAlertController.Style.alert)
        
        optionsAlert.addAction(UIAlertAction(title: "Rename List", style: .default, handler: { (action: UIAlertAction!) in
            self.initRenameList()
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Delete List", style: .default, handler: { (action: UIAlertAction!) in
            // Delete List in Database
            guard let list = self.currentDisplayList else {return}
            self.deleteList(list: list)
        }))
//
//        optionsAlert.addAction(UIAlertAction(title: "Delete List", style: .default, handler: { (action: UIAlertAction!) in
//            // Allow Editing
//            self.editList()
//        }))
        
        
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        present(optionsAlert, animated: true) {
            optionsAlert.view.superview?.isUserInteractionEnabled = true
            optionsAlert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.alertClose(gesture:))))
        }
    }
    
    func deleteList(list:List){
        
        let deleteAlert = UIAlertController(title: "Delete", message: "Are You Sure? All Data Will Be Lost!", preferredStyle: UIAlertController.Style.alert)
        deleteAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            
            Database.deleteList(uploadList: list)
            self.delegate?.deleteList(list: list)
            self.navigationController?.popViewController(animated: true)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        present(deleteAlert, animated: true, completion: nil)
    }
    
    @objc func initRenameList(){
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Rename List", message: "Enter New List Name", preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.text = ""
        }
        
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            print("New List Name: \(textField?.text)")
            
            let listId = NSUUID().uuidString
            guard let uid = Auth.auth().currentUser?.uid else {return}
            self.checkListName(listName: textField?.text) { (listName) in
                self.renameList(listName: listName)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    func renameList(listName: String) {
        self.currentDisplayList?.name = listName
        guard let listId = self.currentDisplayList?.id else {return}
        listCache[listId] = self.currentDisplayList
        Database.updateVariableForList(listId: listId, variable: "name", newCount: listName)
        self.imageCollectionView.reloadData()
        self.updateListLabels()
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
        
        if CurrentUser.lists.contains(where: { (displayList) -> Bool in
            return displayList.name.lowercased() == listName.lowercased()
        }) {
            self.alert(title: "Duplicate List Name", message: "Please Insert Different List Name")
            return
        }
        
        completion(listName)
    }
    
    
    let listIndButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "private"), for: .normal)
        button.addTarget(self, action: #selector(updateListInd), for: .touchUpInside)
        return button
    }()
    
    @objc func updateListInd(){
        if self.currentDisplayList?.name == legitListName || self.currentDisplayList?.name == bookmarkListName {
            print("Modify LegitList or Bookmark List. Return")
            return
        }
        
        if self.currentDisplayList?.publicList == 0 {
            // Enable change to public
            
            let optionsAlert = UIAlertController(title: "Privacy", message: "Change List to Public or Private", preferredStyle: UIAlertController.Style.alert)
            
            optionsAlert.addAction(UIAlertAction(title: "Public", style: .default, handler: { (action: UIAlertAction!) in
                // Create Public List
                self.currentDisplayList?.publicList == 1
                self.handleUpdateListPrivacy(list: self.currentDisplayList!)
            }))
            
            optionsAlert.addAction(UIAlertAction(title: "Private", style: .default, handler: { (action: UIAlertAction!) in
                // Create Private List
                self.currentDisplayList?.publicList == 0
                self.handleUpdateListPrivacy(list: self.currentDisplayList!)
            }))
            
            optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                print("Handle Cancel Logic here")
            }))
            
            self.present(optionsAlert, animated: true, completion: {
            })
        }
    }
    
    func handleUpdateListPrivacy(list: List){
        if let index = self.displayedLists?.firstIndex(where: { (tempList) -> Bool in
            tempList.id == list.id!
        }){
            print("Replacing Current List in Display")
            self.displayedLists![index] = list
        }
        Database.createList(uploadList: list){}
        CurrentUser.addList(list: list)
    }
    
    let listPrivacyLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(font: .noteworthyBold, size: 20)
        label.textColor = UIColor.black
        
        //        label.textColor = UIColor.init(hexColor: "F1C40F")
        label.textAlignment = NSTextAlignment.right
        label.backgroundColor = UIColor.clear
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    var listDisplayEmojis: [String] = [] {
        didSet{
            self.emojiCollectionView.reloadData()
            self.refreshEmojiArray()
        }
    }
    
    
    
    
    func refreshEmojiArray(){
//        print("REFRESH EMOJI ARRAYS")
        

        if self.listDisplayEmojis.count > 0 {
//            print("UPDATED EMOJI ARRAY: \(emojiArray.emojiLabels)")
            emojiArray.emojiLabels = self.listDisplayEmojis
            emojiArray.setEmojiButtons()
            
            for button in emojiArray.emojiButtonArray {
                button.backgroundColor = UIColor.clear
                if let emojiText = button.titleLabel?.text {
                    if self.viewFilter?.filterCaption?.contains(emojiText) ?? false{
                        button.backgroundColor = UIColor.mainBlue()
                    }
                }
            }
        }
        

//        print("REFRESH EMOJI ARRAYS - setEmojiButtons")
//        if self.listDisplayEmojis.count == 0 {
//            self.emojiArray.isHidden = true
//        } else {
//            self.emojiArray.isHidden = false
//        }
    }
    
    var emojiArray = EmojiButtonArray(emojis: [], frame: CGRect(x: 0, y: 0, width: 0, height: 20))
    
    func didTapEmoji(index: Int?, emoji: String) {
        guard let index = index else {
            print("No Index For emoji \(emoji)")
            return
        }
        
        print("Selected Emoji \(emoji) : \(index)")
        if self.viewFilter?.filterCaption == emoji {
            print("Unselecting \(emoji) | Refresh Filter Search")
            self.viewFilter?.filterCaption = nil
            self.searchBar.text = ""
        } else {
            print("Selecting \(emoji) | Filter Posts For \(emoji)")
            self.viewFilter?.filterCaption = emoji
            self.searchBar.text = emoji
        }
        
        // Refresh Everything
        self.refreshPostsForFilter()
        
        
        //        self.delegate?.displaySelectedEmoji(emoji: displayEmoji, emojitag: displayEmojiTag)
        
        print("Selected Emoji \(emoji) : \(index)")
        
        let displayEmojiTag = EmojiDictionary[emoji] ?? emoji
        var captionDelay = 3
        self.displaySelectedEmoji(emoji: emoji, emojitag: displayEmojiTag)
        
        UIView.animate(withDuration: 0.5, delay: TimeInterval(captionDelay), options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.emojiDetailLabel.alpha = 0
        }, completion: { (finished: Bool) in
            self.emojiDetailLabel.alpha = 1
            self.emojiDetailLabel.isHidden = true
        })
        
    }
    
    func doubleTapEmoji(index: Int?, emoji: String) {
            
    }
    
    func updateListLabels(){

        
        var listLabelAttributedText = NSMutableAttributedString()
        let inputFontSize: CGFloat = 15
        
        let listNameTextAttributes = [
            NSAttributedString.Key.strokeColor : UIColor.legitColor(),
            NSAttributedString.Key.foregroundColor : UIColor.darkLegitColor(),
            NSAttributedString.Key.strokeWidth : -2.0,
            NSAttributedString.Key.font : UIFont(font: .helveticaNeueBold, size: 20)
            ] as [NSAttributedString.Key : Any]
        
        listLabelAttributedText.append(NSAttributedString(string: (self.currentDisplayList?.name ?? "") + "  ", attributes: listNameTextAttributes))

        
        self.currentDisplayList?.updateVoteCount{
            self.postCountLabel.attributedText = nil
            self.followerCountLabel.attributedText = nil
            
        // UPDATE LIST NAME
            
            self.listNameLabel.text = self.currentDisplayList?.name
            self.listNameLabel.sizeToFit()
            
            
            
            let listDetailString = NSMutableAttributedString()
            
            
        // UPDATE FOLLOWER COUNT
            if let followerCount = (self.currentDisplayList?.followerCount) {
                    let followerCountText = NSMutableAttributedString()
                    let followerCountString = NSMutableAttributedString(string: "\(followerCount) Followers  ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.legitColor(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: inputFontSize)]))
                    followerCountText.append(followerCountString)
                    self.followerCountLabel.attributedText = followerCountText
            }
            
        // UPDATE POST COUNT
            if let postCount = (self.currentDisplayList?.postIds?.count) {
                if postCount > 0 {
                    
                    let postCountText = NSMutableAttributedString()
                    let postCountString = NSMutableAttributedString(string: "\(postCount) Posts  ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.legitColor(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: inputFontSize)]))
                    postCountText.append(postCountString)
                    listDetailString.append(postCountText)
                }
            }

            
        // UPDATE CRED COUNT
//            if let credCount = (self.currentDisplayList?.totalCred) {
//                if credCount > 0 {
//                    let credButtonText = NSMutableAttributedString()
//
//                    let image1Attachment = NSTextAttachment()
////                    let inputImage = #imageLiteral(resourceName: "drool")
//                    let inputImage = #imageLiteral(resourceName: "bookmark_filled")
//
//                    image1Attachment.bounds = CGRect(x: 0, y: (self.postCountLabel.font.capHeight - (inputImage.size.height)).rounded() / 2, width: inputImage.size.width, height: inputImage.size.height)
//                    image1Attachment.image = inputImage
//
//                    image1Attachment.image = inputImage
//                    let image1String = NSAttributedString(attachment: image1Attachment)
//                    credButtonText.append(image1String)
//
//                    let credButtonString = NSMutableAttributedString(string: " \(credCount)  ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.legitColor(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: inputFontSize)]))
//                    credButtonText.append(credButtonString)
//                    listDetailString.append(credButtonText)
//                }
//            }
            
            // UPDATE AVERAGE RATING
            if self.noFilterAverageRating > 0.0 {
                let ratingText = String(format: "%.2f", self.noFilterAverageRating)
                let postCountText = NSMutableAttributedString()
                let postCountString = NSMutableAttributedString(string: "Avg Rating: \(ratingText)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.legitColor(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: inputFontSize)]))
                postCountText.append(postCountString)
                listDetailString.append(postCountText)
            }
            
            self.postCountLabel.attributedText = listDetailString


        
        // UPDATE PRIVACY IND
            var listIndImage = UIImage()
            var titleColor = UIColor()
            if self.currentDisplayList?.name == legitListName {
                listIndImage = #imageLiteral(resourceName: "legit_large")
                titleColor = UIColor.legitListNameColor()
            } else if self.currentDisplayList?.name == bookmarkListName {
                listIndImage = #imageLiteral(resourceName: "bookmark_filled")
                titleColor = UIColor.bookmarkListNameColor()

            } else if self.currentDisplayList?.publicList == 0 {
                // PRIVATE
                listIndImage = #imageLiteral(resourceName: "private")
                titleColor = UIColor.privateListNameColor()

            } else {
                listIndImage = UIImage()
                titleColor = UIColor.legitColor()
            }
            
//            self.listIndButton.setImage(listIndImage, for: .normal)
        
        // UPDATE NAVIGATION ITEM
            let titleText = NSMutableAttributedString()

            let titleName = NSAttributedString(string: (self.currentDisplayList?.name)!, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): titleColor, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .helveticaNeueBold, size: 20)]))
            titleText.append(titleName)
            
            if listIndImage != UIImage() {
                let image1Attachment = NSTextAttachment()
                image1Attachment.image = listIndImage
                image1Attachment.bounds = CGRect(x: 0, y: ((self.navigationTitleButton.titleLabel?.font.capHeight)! - (listIndImage.size.height)).rounded() / 2, width: listIndImage.size.width, height: listIndImage.size.height)
                let image1String = NSAttributedString(attachment: image1Attachment)
                titleText.append(image1String)
            }

//            self.navigationTitleButton.setAttributedTitle(titleText, for: .normal)
//            self.navigationTitleButton.sizeToFit()
//            self.navigationItem.titleView = self.navigationTitleButton
            
            
            
        // UPDATE EMOJIS
//            self.refreshEmojiArray()
            
            self.listNameLabel.attributedText = listLabelAttributedText
            
//            print("Update Labels: \(self.currentDisplayList?.postIds?.count) Posts ; \(self.currentDisplayList?.totalCred) Cred, Ind Image: \(listIndImage)")
        }
    }
    
    lazy var navigationTitleButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(showDropDown), for: .touchUpInside)
        button.backgroundColor = UIColor.clear
//        button.titleLabel?.adjustsFontSizeToFitWidth = true
        return button
    }()
    
    lazy var listActionView : UIButton = {
        let button = UIButton(type: .system)
//        button.setTitle(self.currentDisplayList?.name, for: .normal)
        button.addTarget(self, action: #selector(showDropDown), for: .touchUpInside)
        button.backgroundColor = UIColor.clear
        return button
    }()
    
    
    
    func updateListButton(){
        
        self.currentDisplayList?.updateVoteCount{
            self.updateListLabels()
        }
        var listString = "\((self.currentDisplayList?.name)!)   \((self.currentDisplayList?.postIds?.count)!) Posts    \((self.currentDisplayList?.totalCred)!) Cred"
        
        let listButtonText = NSAttributedString(string: listString, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.init(hexColor: "F1C40F"), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .noteworthyBold, size: 20)]))
        self.listActionView.setAttributedTitle(listButtonText, for: .normal)
        
    }
    
    @objc func showDropDown(){
        if self.dropDownMenu.isHidden{
            self.dropDownMenu.show()
        } else {
            self.dropDownMenu.hide()
        }
    }

    
    //DISPLAY VARIABLES
    var fetchedPosts: [Post] = [] {
        didSet{

            if !(self.viewFilter?.isFiltering)!{
            Database.countMostUsedEmojis(posts: self.fetchedPosts) { (emojis) in
                self.listDisplayEmojis = emojis
//                print("Most Displayed Emojis: \(emojis)")
                }
            }
        }
    }
    
    var displayedPosts: [Post] = []
    
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
    
    var selectedPostID: String?
    var selectedPostIDLoc: CLLocation?
    // Emoji description
    
    let emojiDetailLabel: UILabel = {
        let label = UILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.rgb(red: 255, green: 242, blue: 230)
        label.layer.cornerRadius = 30/2
        label.layer.borderWidth = 0.25
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.masksToBounds = true
        return label
        
    }()
    
    func setupEmojiDetailLabel(){
        view.addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top: postCountLabel.topAnchor, left: searchBar.leftAnchor, bottom: searchBar.topAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 25)
        emojiDetailLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
//        emojiDetailLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        emojiDetailLabel.isHidden = true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        emojiDetailLabel.isHidden = true
    }
    
    func checkToSaveRank(){
        
        var tempRank: [String:Int] = [:]
        for (index, object) in self.fetchedPosts.enumerated() {
            tempRank[(object.id)!] = index + 1
        }

        let optionsAlert = UIAlertController(title: "List Ranks", message: "Do you want to save your new rankings?", preferredStyle: UIAlertController.Style.alert)
        
        optionsAlert.addAction(UIAlertAction(title: "Save Rank", style: .default, handler: { (action: UIAlertAction!) in
            // Allow Editing
            self.savePostRankForList()
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
        }))
    
        if self.currentDisplayList?.listRanks != tempRank {
            present(optionsAlert, animated: true, completion: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
//        if !self.saveRankButton.isHidden {
//            self.checkToSaveRank()
//        }
        
        imageCollectionView.collectionViewLayout.invalidateLayout()
        imageCollectionView.layoutIfNeeded()
//        menuView.hide()
//        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont(font: .noteworthyBold, size: 20)]
    }
    
    override func willMove(toParent parent: UIViewController?) { // tricky part in iOS 10
        self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.white, NSAttributedString.Key.font.rawValue: UIFont(font: .helveticaNeueBold, size: 20)])
        super.willMove(toParent: parent)
    }
    
// LIST CREATOR USER INFO
    
    let userProfileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        iv.layer.borderColor = UIColor.darkLegitColor().cgColor
        iv.layer.borderWidth = 1
        return iv
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(font: .appleSDGothicNeoBold, size: 18)
        label.textColor = UIColor.legitColor()
        label.textAlignment = NSTextAlignment.right
        return label
    }()
    
    
// FOLLOW UNFOLLOW BUTTON
    lazy var listFollowButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Follow List", for: .normal)
        button.titleLabel?.font =  UIFont(name: "Poppins-Bold", size: 12)
        button.layer.borderColor = UIColor.ianLegitColor().cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 5
        button.backgroundColor = UIColor.white
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.addTarget(self, action: #selector(handleFollowingList), for: .touchUpInside)
        return button
    }()
    
    func setupListFollowButton() {
        
        guard let listId = self.currentDisplayList?.id else {return}
        self.listFollowButton.isHidden = self.currentDisplayList?.creatorUID == Auth.auth().currentUser?.uid
        self.listOptionsButton.isHidden = !self.listFollowButton.isHidden
        if !self.listFollowButton.isHidden || (self.viewFilter?.isFiltering)! {
            self.saveRankButton.isHidden = true
        }
        
        if CurrentUser.followedListIds.contains(listId){
            listFollowButton.setTitle("Following", for: .normal)
            listFollowButton.setTitleColor(UIColor.ianLegitColor(), for: .normal)
            listFollowButton.layer.borderColor = UIColor.ianLegitColor().cgColor
            listFollowButton.backgroundColor = UIColor.white
        } else {
            listFollowButton.setTitle("Follow", for: .normal)
            listFollowButton.backgroundColor = UIColor.ianLegitColor()
            listFollowButton.setTitleColor(UIColor.white, for: .normal)
            listFollowButton.layer.borderColor = UIColor.white.cgColor        }
    }
    
    @objc func handleFollowingList(){
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        guard let followingList = self.currentDisplayList else {
            print("List | handleFollowingList ERROR | No List to Follow")
            return
        }
        
        guard let followingListId = followingList.id else {
            print("List | handleFollowingList ERROR | No List ID")
            return
        }
        
        if CurrentUser.followedListIds.contains(followingListId) {
            Database.handleUnfollowList(userUid: uid, followedList: followingList) {
//                self.setupListFollowButton()
                self.alert(title: "", message: "\((self.currentDisplayList?.name)!) List UnFollowed")
            }
        } else {
            Database.handleFollowingList(userUid: uid, followedList: followingList) {
//                self.setupListFollowButton()
                self.alert(title: "", message: "\((self.currentDisplayList?.name)!) List Followed")
            }
        }
    }

    
// Filtering Variables
    
    var viewFilter: Filter? = Filter.init() {
        didSet {
            if (self.viewFilter?.isFiltering)! {
                let currentFilter = self.viewFilter
                var searchTerm: String = ""
                
                if currentFilter?.filterCaption != nil {
                    searchTerm.append("\((currentFilter?.filterCaption)!) | ")
                }
                
                if currentFilter?.filterLocationName != nil {
                    var locationNameText = currentFilter?.filterLocationName
                    if locationNameText == "Current Location" || currentFilter?.filterLocation == CurrentUser.currentLocation {
                        locationNameText = "Here"
                    }
                    searchTerm.append("\(locationNameText!) | ")
                }
                
                if (currentFilter?.filterLegit)! {
                    searchTerm.append("Legit | ")
                }
                
                if currentFilter?.filterMinRating != 0 {
                    searchTerm.append("\((currentFilter?.filterMinRating)!) Stars | ")
                }
                self.isFilteringText = searchTerm
            } else {
                self.isFilteringText = nil
            }
//        self.refreshPostsForFilter()
        }
    }
    
    var isFilteringText: String? = nil
   
    func showFilterView(){
        
        var searchTerm: String = ""
        
        guard let currentFilter = self.viewFilter else {return}
        
        if (currentFilter.isFiltering) {
            if currentFilter.filterCaption != nil {
                searchTerm.append("\((currentFilter.filterCaption)) | ")
            }
            
            if currentFilter.filterLocationName != nil {
                var locationNameText = currentFilter.filterLocationName
                if locationNameText == "Current Location" || currentFilter.filterLocation == CurrentUser.currentLocation {
                    locationNameText = "Here"
                }
                searchTerm.append("\(locationNameText!) | ")
            }
            
            if currentFilter.filterLocationSummaryID != nil {
                var locationNameText = currentFilter.filterLocationSummaryID
                searchTerm.append("\(locationNameText!) | ")
            }
            
            if (currentFilter.filterLegit) {
                searchTerm.append("Legit | ")
            }
            
            if currentFilter.filterMinRating != 0 {
                searchTerm.append("\((currentFilter.filterMinRating)) Stars | ")
            }
        }
        
        self.filteringDetailLabel.text = "Filtering : " + searchTerm
        self.filteringDetailLabel.sizeToFit()
        self.filterDetailView.isHidden = !(currentFilter.isFiltering)
    }
    
    
    let filterDetailView: UIView = {
        let tv = UIView()
        tv.backgroundColor = UIColor.white
        tv.layer.cornerRadius = 5
        tv.layer.masksToBounds = true
        tv.layer.borderWidth = 1
        tv.layer.borderColor = UIColor.legitColor().cgColor
        return tv
    }()
    
    
    let filteringDetailLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textAlignment = NSTextAlignment.center
        //        label.backgroundColor = UIColor.rgb(red: 255, green: 242, blue: 230)
        label.textColor = UIColor.legitColor()
        label.numberOfLines = 0
        //        label.layer.borderColor = UIColor.black.cgColor
        //        label.layer.masksToBounds = true
        return label
    }()
    
    lazy var cancelFilterButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        button.setImage(#imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysOriginal), for: .normal)
        button.backgroundColor = UIColor.clear
        button.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        return button
    }()
    
    @objc func didTapCancel(){
        self.refreshAll()
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
        
        // LOAD IN TEMP RANK
        let tempList = self.currentDisplayList
        if let tempRank = self.tempRank{
            tempList?.listRanks = self.tempRank!
        }
        
            Database.fetchPostFromList(list: tempList, completion: { (fetchedPosts) in
                print(" SUCCESS | Fetch Post for List |, \(displayListId):\(self.currentDisplayList?.name), Count: \(fetchedPosts?.count) Posts")
                
                
            // READ IN RANKS FROM LIST
                var tempPosts: [Post] = []
                if let tempRank = self.tempRank {
                    for post in fetchedPosts ?? [] {
                        var tempPost = post
                            tempPost.listedRank = tempRank[post.id!]
                            tempPosts.append(post)
                    }
                    self.fetchedPosts = tempPosts
                }
                
                
                Database.countMostUsedEmojis(posts: self.fetchedPosts, completion: { (mostUsedEmojis) in
                    let tempEmojis = Array(mostUsedEmojis.prefix(4))
                    
                    var updateEmoji = false
                    
                    for emoji in tempEmojis {
                        if !(self.currentDisplayList?.topEmojis.contains(emoji))! {
                            updateEmoji = true
                        }
                    }
                    
                    if updateEmoji && self.currentDisplayList?.topEmojis != tempEmojis {
                        print("ListViewController | Fetched Posts For List | Emoji Check | Updating Emojis | \(self.currentDisplayList?.id) : \(tempEmojis)")
                        Database.updateSocialCountForList(listId: self.currentDisplayList?.id, credCount: nil, emojis: tempEmojis)
                        self.currentDisplayList?.topEmojis = tempEmojis
                        listCache[(self.currentDisplayList?.id)!] = self.currentDisplayList
                        
//                        if CurrentUser.listIds.contains((self.currentDisplayList?.id)!){
//                            NotificationCenter.default.post(name: TabListViewController.refreshListNotificationName, object: nil)
//                        }
                        
                    }
                    
                })
                
                self.filterSortFetchedPosts()
                self.isFetchingPost = false

            })
    }
    
    func fetchUserForList(){
        guard let currentDisplayList = self.currentDisplayList else {
            print("Fetch User For List: Error, No Display List")
            return
        }
        
        Database.fetchUserWithUID(uid: (currentDisplayList.creatorUID)!) { (fetchedUser) in
            self.displayUser = fetchedUser
            self.fetchListsForUser()
        }
    }
    
    func fetchListsForUser(){
        guard let displayListIds = self.displayUser?.listIds else {
            print("Fetch Lists for User: Error, No List Ids, Default List, \(self.displayUser?.uid)")
            self.displayedLists = [emptyLegitList, emptyBookmarkList]
            return
        }
        
        if CurrentUser.isGuest && (self.displayUser?.uid)! == CurrentUser.uid {
            print("Fetching Guest User Lists")
            self.displayedLists = CurrentUser.lists
            return
        }
                
        Database.fetchListForMultListIds(listUid: displayListIds) { (fetchedLists) in
            if fetchedLists.count == 0 {
                print("Fetch List Error, No Lists, Displaying Default Empty Lists")
                self.displayedLists = [emptyLegitList, emptyBookmarkList]
            } else {
                Database.sortList(inputList: fetchedLists, completion: { (sortedList) in
                    self.displayedLists = sortedList
                })
            }
            
            print("Fetched Lists: \(self.displayedLists?.count) Lists for \(self.displayUser?.uid)")
//            NotificationCenter.default.post(name: ListViewController.refreshListViewNotificationName, object: nil)
        }
    }
    
    var searchBar = UISearchBar()
    var searchBarView = UIView()

    let emojiCollectionView: UICollectionView = {
        let uploadEmojiList = UICollectionViewFlowLayout()
        uploadEmojiList.estimatedItemSize = CGSize(width: 30, height: 30)
        uploadEmojiList.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadEmojiList)
        cv.layer.borderWidth = 0
        cv.backgroundColor = UIColor.white
        return cv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white


//        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateList), name: SharePhotoListController.updateListFeedNotificationName, object: nil)

    // Set Up List Display Row
        let listDisplayLength = self.view.frame.width/4
        
        view.addSubview(displayListView)
//        displayListView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
        displayListView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 100)

    // HEADER VIEW
        let headerView = UIView()
        displayListView.addSubview(headerView)
        headerView.anchor(top: displayListView.topAnchor, left: displayListView.leftAnchor, bottom: nil, right: displayListView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        headerView.backgroundColor = UIColor.white
//        headerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showDropDown)))
//        headerView.backgroundColor =  UIColor.init(white: 0, alpha: 0.1)

        headerView.addSubview(userProfileImageView)
        userProfileImageView.anchor(top: headerView.topAnchor, left: headerView.leftAnchor, bottom: headerView.bottomAnchor, right: nil, paddingTop: 3, paddingLeft: 5, paddingBottom: 3, paddingRight: 10, width: 45, height: 45)
        userProfileImageView.layer.cornerRadius = 45/2
        userProfileImageView.layer.masksToBounds = true
        userProfileImageView.clipsToBounds = true
        userProfileImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        userProfileImageView.isUserInteractionEnabled = true
        userProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(usernameTap)))
        
        
        let listNameView = UIView()
        headerView.addSubview(listNameView)
        listNameView.anchor(top: headerView.topAnchor, left: userProfileImageView.rightAnchor, bottom: headerView.bottomAnchor, right: headerView.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        listNameView.centerYAnchor.constraint(equalTo: userProfileImageView.centerYAnchor).isActive = true
        listNameView.isUserInteractionEnabled = true
        listNameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showDropDown)))
//        listNameView.backgroundColor = UIColor.yellow
        
        listNameView.addSubview(listNameLabel)
        listNameLabel.anchor(top: listNameView.topAnchor, left: listNameView.leftAnchor, bottom: nil, right: listNameView.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 25)
        listNameLabel.isUserInteractionEnabled = false
        
        headerView.addSubview(listFollowButton)
        listFollowButton.anchor(top: listNameLabel.bottomAnchor, left: nil, bottom: nil, right: headerView.rightAnchor, paddingTop: 3, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 100, height: 30)
//        listFollowButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        
        headerView.addSubview(listOptionsButton)
        listOptionsButton.anchor(top: listNameLabel.bottomAnchor, left: nil, bottom: nil, right: headerView.rightAnchor, paddingTop: 3, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 30, height: 30)
//        listOptionsButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        
        
        headerView.addSubview(saveRankButton)
        saveRankButton.anchor(top: listNameLabel.bottomAnchor, left: nil, bottom: nil, right: listOptionsButton.leftAnchor, paddingTop: 3, paddingLeft: 0, paddingBottom: 3, paddingRight: 5, width: 0, height: 0)
//        saveRankButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        saveRankButton.isHidden = true
        
        self.setupListFollowButton()
        
        
        
        listNameView.addSubview(followerCountLabel)
        followerCountLabel.anchor(top: listNameLabel.bottomAnchor, left: listNameLabel.leftAnchor, bottom: userProfileImageView.bottomAnchor, right: listFollowButton.leftAnchor, paddingTop: 3, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        let followerCountLabelTapGesture = UITapGestureRecognizer(target: self, action: #selector(listFollowerTapped))
        followerCountLabel.addGestureRecognizer(followerCountLabelTapGesture)


//        let bottomdiv = UIView()
//        view.addSubview(bottomdiv)
//        bottomdiv.anchor(top: headerView.bottomAnchor, left: headerView.leftAnchor, bottom: nil, right: headerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
//        bottomdiv.backgroundColor = UIColor.lightGray
        
        
    // SUB HEADER VIEW

        view.addSubview(listActionView)
        listActionView.anchor(top: headerView.bottomAnchor, left: displayListView.leftAnchor, bottom: nil, right: displayListView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        listActionView.backgroundColor =  UIColor.yellow
//        listActionView.backgroundColor =  UIColor.init(white: 0, alpha: 0.1)

//        view.addSubview(listFollowButton)
//        listFollowButton.anchor(top: listActionView.topAnchor, left: nil, bottom: listActionView.bottomAnchor, right: listActionView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 10, width: 180, height: 0)

        
        view.addSubview(postCountLabel)
        postCountLabel.anchor(top: nil, left: listActionView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 30)
        postCountLabel.centerYAnchor.constraint(equalTo: listActionView.centerYAnchor).isActive = true
        postCountLabel.isUserInteractionEnabled = false
        
        
//        view.addSubview(emojiArray)
//        emojiArray.anchor(top: nil, left: listActionView.leftAnchor, bottom: nil, right: listFollowButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 30)
//        emojiArray.centerYAnchor.constraint(equalTo: listActionView.centerYAnchor).isActive = true
//        emojiArray.delegate = self
//        emojiArray.alignment = .left
//        emojiArray.sizeToFit()
        
//        view.addSubview(credCountLabel)
//        credCountLabel.anchor(top: nil, left: postCountLabel.rightAnchor, bottom: displayListButton.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 20, width: 0, height: 0)
//        credCountLabel.centerYAnchor.constraint(equalTo: displayListButton.centerYAnchor).isActive = true
        
        setupSearchBar()
        view.addSubview(searchBarView)
        searchBarView.anchor(top: listActionView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
//        setupEmojiCollectionView()
//        view.addSubview(emojiCollectionView)
//        emojiCollectionView.anchor(top: searchBarView.topAnchor, left: nil, bottom: searchBarView.bottomAnchor, right: searchBarView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 120, height: 0)
        
        view.addSubview(emojiArray)
        emojiArray.anchor(top: nil, left: nil, bottom: nil, right: searchBarView.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 10, width: 0, height: 20)
        emojiArray.centerYAnchor.constraint(equalTo: searchBarView.centerYAnchor).isActive = true
        emojiArray.delegate = self
        emojiArray.alignment = .right
        emojiArray.sizeToFit()
        
        view.addSubview(searchBar)
        searchBar.anchor(top: searchBarView.topAnchor, left: searchBarView.leftAnchor, bottom: searchBarView.bottomAnchor, right: emojiArray.leftAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)


        setupCollectionView()
        view.addSubview(imageCollectionView)
        imageCollectionView.anchor(top: searchBarView.bottomAnchor, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        setupDropDown()
        view.addSubview(dropDownMenu)
//        dropDownMenu.anchor(top: listActionView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 200)
        dropDownMenu.anchor(top: listActionView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 200)

        
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: ListViewController.refreshListViewNotificationName, object: nil)
        
        setupEmojiDetailLabel()
        
        
        //        view.addSubview(emojiArray)
        //        emojiArray.anchor(top: displayListView.topAnchor, left: displayListView.leftAnchor, bottom: displayListView.bottomAnchor, right: nil, paddingTop: 10, paddingLeft: 20, paddingBottom: 10, paddingRight: 0, width: 0, height: 0)
        //        emojiArray.rightAnchor.constraint(lessThanOrEqualTo: postCountLabel.leftAnchor).isActive = true
        //        emojiArray.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        //        self.refreshEmojiArray()
        //        emojiArray.delegate = self
        
        //        view.addSubview(listIndButton)
        //        listIndButton.anchor(top: displayListView.topAnchor, left: emojiArray.rightAnchor, bottom: displayListView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 20, width: 0, height: 0)
        
        setupFilterDetailView()
        
        
    }

    
    
    let emojiCellID = "emojiCellID"
    
    func setupEmojiCollectionView(){
        let uploadEmojiList = ListDisplayFlowLayoutCopy()
        //        uploadEmojiList.estimatedItemSize = CGSize(width: 30, height: 30)
        //        uploadEmojiList.sectionInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        //        uploadEmojiList.scrollDirection = .horizontal
        //        uploadEmojiList.scrollDirection = .horizontal
        
        emojiCollectionView.collectionViewLayout = uploadEmojiList
        emojiCollectionView.backgroundColor = UIColor.white
        emojiCollectionView.register(UploadEmojiCell.self, forCellWithReuseIdentifier: emojiCellID)
        emojiCollectionView.delegate = self
        emojiCollectionView.dataSource = self
        emojiCollectionView.allowsMultipleSelection = false
        emojiCollectionView.showsHorizontalScrollIndicator = false
        emojiCollectionView.backgroundColor = UIColor.clear
        emojiCollectionView.isScrollEnabled = true
    }
    
    
    func setupSearchBar(){
        searchBar.layer.cornerRadius = 25/2
        searchBar.clipsToBounds = true
        searchBar.searchBarStyle = .minimal
        searchBar.barTintColor = UIColor.white
        //        defaultSearchBar.backgroundImage = UIImage()
        searchBar.layer.borderWidth = 0
        searchBar.placeholder = "Search Lists"
        searchBar.delegate = self
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText.count == 0) {
            self.viewFilter?.filterCaption = nil
            self.searchBar.endEditing(true)
            self.refreshPostsForFilter()
        } else {
            filterContentForSearchText(searchBar.text!)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.endEditing(true)
    }
    
    @objc func filterContentForSearchText(_ searchText: String) {
        // Filter List Table View
        if searchText.count > 0 {
            self.viewFilter?.filterCaption = searchText
        } else {
            self.viewFilter?.filterCaption = nil
        }
        self.filterSortFetchedPosts()

    }
    
    
    func setupFilterDetailView(){
        view.addSubview(filterDetailView)
        filterDetailView.anchor(top: nil, left: nil, bottom: bottomLayoutGuide.topAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 3, paddingRight: 0, width: 0, height: 0)
        filterDetailView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        filterDetailView.widthAnchor.constraint(lessThanOrEqualToConstant: self.view.frame.width - 20).isActive = true

        filterDetailView.addSubview(cancelFilterButton)
        cancelFilterButton.anchor(top: nil, left: nil, bottom: nil, right: filterDetailView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        cancelFilterButton.centerYAnchor.constraint(equalTo: filterDetailView.centerYAnchor).isActive = true
        
        filterDetailView.addSubview(filteringDetailLabel)
        filteringDetailLabel.anchor(top: filterDetailView.topAnchor, left: filterDetailView.leftAnchor, bottom: filterDetailView.bottomAnchor, right: cancelFilterButton.leftAnchor, paddingTop: 3, paddingLeft: 5, paddingBottom: 3, paddingRight: 0, width: 0, height: 0)
        
        filterDetailView.isHidden = true
    }
    
    @objc func listFollowerTapped(){
        guard let list = self.currentDisplayList else {
            return
        }
        self.displayListFollowingUsers(list: list, following: false)
    }
    
    func setupDropDown(){
        print("ListViewController | setupDropDown")
//        dropDownMenu.anchorView = collectionView
        dropDownMenu.anchorView = listActionView
        dropDownMenu.dismissMode = .automatic
        dropDownMenu.textColor = UIColor.white
        dropDownMenu.textFont = UIFont.systemFont(ofSize: 15)
        dropDownMenu.backgroundColor = UIColor.white
//        dropDownMenu.selectionBackgroundColor = UIColor.legitColor().withAlphaComponent(0.5)
        dropDownMenu.cellHeight = 50
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        var manageListString = "Manage Lists"
        var menuOptions = self.displayedListNames
        if self.currentDisplayList?.creatorUID == uid {
            menuOptions.append(manageListString)
        }
        
        dropDownMenu.dataSource = menuOptions
//        print("Menu Options: ", menuOptions)
        
        dropDownMenu.cellNib = UINib(nibName: "DropDownTableViewCell", bundle: nil)
        dropDownMenu.customCellConfiguration = { (index: Index, item: String, cell: DropDownCell) -> Void in
            guard let cell = cell as? DropDownTableViewCell else { return }
            
            if let curList = self.displayedLists?.first(where: { (templist) -> Bool in
                templist.name == item
            }){
                cell.list = curList
            } else {
                cell.list = nil
            }
        }
        
        
        dropDownMenu.selectionAction = { [unowned self] (index: Int, item: String) in
            print("Selected item: \(item) at index: \(index)")
            if item == manageListString {
                print("Selected Manage Lists")
//                self.menuView.shouldChangeTitleText = false
                self.manageList()
            } else {
//                self.menuView.shouldChangeTitleText = true
                self.currentDisplayList = self.displayedLists![index]
            }
            self.dropDownMenu.hide()
        }
        
        if let i = self.displayedLists?.firstIndex(where: { (list) -> Bool in
            list.id == self.currentDisplayList?.id
        }){
            print("DropDown Menu Preselect \(i) \(self.displayedLists?[i].name)")
            dropDownMenu.selectRow(i)
        }
    }
    


    @objc func handleBackPressNav(){
        //        guard let post = self.selectedPost else {return}
        self.handleBack()
    }
    
    
    func setupNavigationItems(){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        navigationController?.navigationBar.barTintColor = UIColor.white

        var menuOptions = self.displayedListNames
//        print("Menu Options: ", menuOptions)

        var manageListString = "Manage Lists"
        if self.currentDisplayList?.creatorUID == uid {
            menuOptions.append(manageListString)
        }
        
        // REMOVES THE 1PX BOTTOM LINE IN NAV BAR
        navigationController?.navigationBar.shadowImage = UIImage()
        

        self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.ianLegitColor(), NSAttributedString.Key.font.rawValue: UIFont(name: "Poppins-Bold", size: 18)])
        navigationItem.title = "List"
        
        // Nav Bar Buttons
        let tempNavBarButton = NavBarMapButton.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        tempNavBarButton.addTarget(self, action: #selector(toggleMapFunction), for: .touchUpInside)
        let barButton1 = UIBarButtonItem.init(customView: tempNavBarButton)
        
        self.navigationItem.rightBarButtonItems = [barButton1]
        
        // Nav Back Buttons
        let navBackButton = navBackButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        navBackButton.addTarget(self, action: #selector(handleBackPressNav), for: .touchUpInside)
        let barButton2 = UIBarButtonItem.init(customView: navBackButton)
        self.navigationItem.leftBarButtonItem = barButton2
        
        // Switch Button positions if not from tab view.
//        if tabBarDisplayNavigationBar {
//
//            // Special Tab Nav Bar View - Map Toggle on the left, List MGMT on the right
//            let listButton = UIBarButtonItem(image: #imageLiteral(resourceName: "slider_white").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(manageList))
//            navigationItem.rightBarButtonItem = listButton
//
//            let listToggleButton = UIButton(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
//            listToggleButton.addTarget(self, action: #selector(toggleMapFunction), for: .touchUpInside)
//            listToggleButton.setImage((#imageLiteral(resourceName: "map_navbar").resizeImageWith(newSize: CGSize(width: 30, height: 30))).withRenderingMode(.alwaysOriginal), for: .normal)
//            let barButton2 = UIBarButtonItem.init(customView: listToggleButton)
//
//            self.navigationItem.leftBarButtonItems = [barButton2]
//
//        } else {
//
//            // Default List View - Back button on the left, map button on the right
//            navigationItem.rightBarButtonItem = UIBarButtonItem(image: (#imageLiteral(resourceName: "google_color")).withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(toggleMapFunction))
//        }
        
        
//        let legitListTitle = UILabel()
//        legitListTitle.text = "LegitList"
//        //        legitListTitle.font = UIFont(name: "TitilliumWeb-SemiBold", size: 20)
////        legitListTitle.font = UIFont(font: .noteworthyBold, size: 20)
//        legitListTitle.font = UIFont(font: .helveticaNeueBold, size: 20)
//
//        legitListTitle.textColor = UIColor.ianLegitColor()
//        legitListTitle.textAlignment = NSTextAlignment.center
//        navigationItem.titleView  = legitListTitle
        //        self.navigationItem.titleView = navigationTitleButton

        
        
        // Setup List Drop Down Bar
        //        self.navigationController?.navigationBar.isTranslucent = true
        //        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.init(hexColor: "F1C40F"), NSFontAttributeName: UIFont(font: .noteworthyBold, size: 20)]
        //        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont(font: .noteworthyBold, size: 20)]

        
        
//        menuView = BTNavigationDropdownMenu(navigationController: self.navigationController, containerView: self.navigationController!.view, title: (self.currentDisplayList?.name)!, items: menuOptions)
//        menuView.navigationBarTitleFont = UIFont(font: .noteworthyBold, size: 20)
//
//        menuView.cellHeight = 50
//        menuView.cellBackgroundColor = self.navigationController?.navigationBar.barTintColor
//        menuView.cellSelectionColor = UIColor(red: 0.0/255.0, green:160.0/255.0, blue:195.0/255.0, alpha: 1.0)
//        menuView.shouldKeepSelectedCellColor = true
//        menuView.cellTextLabelColor = UIColor.white
//        menuView.cellTextLabelFont = UIFont(font: .noteworthyBold, size: 18)
//        menuView.cellTextLabelAlignment = .left // .Center // .Right // .Left
//        menuView.arrowPadding = 15
//        menuView.animationDuration = 0.5
//        menuView.maskBackgroundColor = UIColor.black
//        menuView.maskBackgroundOpacity = 0.3
//
//
//        menuView.didSelectItemAtIndexHandler = {(indexPath: Int) -> Void in
//            print("Did select item at index: \(indexPath)")
//            if menuOptions[indexPath] == manageListString {
//                print("Selected Manage Lists")
//                self.menuView.shouldChangeTitleText = false
//                self.manageList()
//            } else {
//                self.menuView.shouldChangeTitleText = true
//                self.currentDisplayList = self.displayedLists![indexPath]
//            }
//        }
        
//        self.navigationItem.titleView = menuView
        
    // Setup Map Button (Right Bar)
//        let mapImage = #imageLiteral(resourceName: "googlemap").resizeImageWith(newSize: CGSize(width: 30, height: 30))
//
//        let mapButton = UIBarButtonItem(image: #imageLiteral(resourceName: "googlemap").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(openMap))
//        navigationItem.rightBarButtonItem = mapButton
        

        
        // Setup User Profile Button (Left Bar)
//        let userImage = CustomImageView()
//        userImage.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
//        userImage.contentMode = .scaleAspectFill
//        userImage.clipsToBounds = true
//        userImage.loadImage(urlString: (displayUser?.profileImageUrl)!)
//
//        let newImage = userImage.image?.resizeImageWith(newSize: CGSize(width: userImage.frame.width, height: userImage.frame.width))
//        userImage.image = newImage
//        userImage.isUserInteractionEnabled = true
//        userImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(userSelected)))
//        userImage.layer.cornerRadius = userImage.frame.width/2
//
//        let userProfileButton = UIBarButtonItem(customView: userImage)
//
//        if navigationItem.leftBarButtonItems?.count == 0 {
//            navigationItem.leftBarButtonItem = userProfileButton
//        } else {
//            navigationItem.leftBarButtonItems?.append(userProfileButton)
//        }
        

        
        
        
    }
    
    @objc func toggleMapFunction(){
        //        appDelegateFilter = self.viewFilter
        if appDelegateMapViewInd {
            // List Opened while on Map View
            self.delegate?.listSelected(list: currentDisplayList)
            self.navigationController?.popToRootViewController(animated: true)
        } else {
            // List from Tab on Instagram View
            var tempFilter = Filter.init()
            tempFilter.filterList = currentDisplayList
            if let listGPS = currentDisplayList?.listGPS {
                tempFilter.filterLocation = listGPS
            }
            print("ListViewController | toggleMapFunction | GPS | \(tempFilter.filterLocation)")

            appDelegateFilter = tempFilter
//            self.navigationController?.popToRootViewController(animated: false)
            self.toggleMapView()
        }
    }
    
//    func openMap(){
//        print("Open Map for \(self.currentDisplayList?.name)")
//        let mapView = GoogleMapViewController()
//        mapView.initview = 0
//        mapView.selectedPostID = self.selectedPostID
//        mapView.initLocation = self.selectedPostIDLoc
//        mapView.setupMapView()
//        mapView.currentDisplayList = self.currentDisplayList
//        navigationController?.pushViewController(mapView, animated: true)
//    }
    
    func manageList(){
//        let sharePhotoListController = ManageListViewController()
//        navigationController?.pushViewController(sharePhotoListController, animated: true)
        
        let tabListController = TabListViewController()
        tabListController.enableAddListNavButton = false
        tabListController.inputUserId = Auth.auth().currentUser?.uid
        navigationController?.pushViewController(tabListController, animated: true)

    }
    
    func userSelected(){
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = displayUser?.uid
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func setupCollectionView(){
        imageCollectionView.register(NewListPhotoCell.self, forCellWithReuseIdentifier: bookmarkCellId)
        imageCollectionView.register(TestGridPhotoCell.self, forCellWithReuseIdentifier: gridCellId)
        imageCollectionView.register(FullPictureCell.self, forCellWithReuseIdentifier: fullCellId)

//        collectionView.register(ListViewHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: listHeaderId)
        imageCollectionView.register(NewHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: listHeaderId)


        imageCollectionView.backgroundColor = .white
        imageCollectionView.translatesAutoresizingMaskIntoConstraints = true
        
        let layout: UICollectionViewFlowLayout = HomeSortFilterHeaderFlowLayout()
        imageCollectionView.collectionViewLayout = layout
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        imageCollectionView.refreshControl = refreshControl
        imageCollectionView.bounces = true
        imageCollectionView.alwaysBounceVertical = true
        imageCollectionView.keyboardDismissMode = .onDrag
        
        // Adding Empty Data Set
        imageCollectionView.emptyDataSetSource = self
        imageCollectionView.emptyDataSetDelegate = self
        imageCollectionView.emptyDataSetView { (emptyview) in
            emptyview.isUserInteractionEnabled = false
        }
        // Drag and Drop Functions
        imageCollectionView.dragInteractionEnabled = true
        imageCollectionView.dragDelegate = self
        imageCollectionView.dropDelegate = self
        imageCollectionView.reorderingCadence = .fast
    }
    
    
    var noCaptionFilterEmojiCounts: [String:Int] = [:]
    var noCaptionFilterLocationCounts: [String:Int] = [:]
    var noFilterAverageRating: Double = 0.0
    
    func filterSortFetchedPosts(){
        
        var noCaptionLocationFilter = Filter.init()
        noCaptionLocationFilter.filterUser = self.viewFilter?.filterUser
        noCaptionLocationFilter.filterList = self.viewFilter?.filterList
        
        // Fetches All Posts, Refilters assuming no caption filtered, recount emoji/location
        if self.noCaptionFilterEmojiCounts.count == 0 {
            Database.countEmojis(posts: self.fetchedPosts) { (emojiCounts) in
                self.noCaptionFilterEmojiCounts = emojiCounts
                print("ListViewController | noCaptionFilterEmojiCounts | \(self.noCaptionFilterEmojiCounts.count)")
            }
        }
        
        if self.noCaptionFilterLocationCounts.count == 0 {
            Database.countCityIds(posts: self.fetchedPosts) { (locationCounts) in
                self.noCaptionFilterLocationCounts = locationCounts
                print("ListViewController | noCaptionFilterLocationCounts | \(self.noCaptionFilterLocationCounts.count)")
            }
        }
        
        self.noFilterAverageRating = Database.averageRating(posts: self.fetchedPosts)
        
        // Sort Recent Post By Listed Date
        var listSort: String = "Listed"
        if self.viewFilter?.filterSort == defaultRecentSort {
            listSort = "Listed"
        } else {
            listSort = (self.viewFilter?.filterSort)!
        }
        
        Database.sortPosts(inputPosts: self.fetchedPosts, selectedSort: listSort, selectedLocation: self.viewFilter?.filterLocation, completion: { (sortedPosts) in
            self.fetchedPosts = sortedPosts ?? []
            
            Database.filterPostsNew(inputPosts: self.fetchedPosts, postFilter: self.viewFilter) { (filteredPosts) in
                self.selectedPostID = nil
                self.selectedPostIDLoc = nil
                self.displayedPosts = filteredPosts ?? []
                print("  ~ FINISH | Filter and Sorting Post | \(filteredPosts?.count) Posts | \(self.currentDisplayList?.name) - \(self.currentDisplayList?.id)")
                SVProgressHUD.dismiss()

                if self.imageCollectionView.isDescendant(of: self.view) {
                    self.imageCollectionView.reloadData()
                } 
            }
        })
    }
    
    // Refresh Functions
    
    @objc func refreshAll() {
        self.handleRefresh()
    }
    
    @objc func handleRefresh(){
        print("ListViewController | Refresh List | \(self.currentDisplayList?.name)")
        self.clearAllPost()
        self.clearFilter()
//        self.collectionView.reloadData()
        self.fetchPostsForList()
        self.showFilterView()
        self.imageCollectionView.refreshControl?.endRefreshing()
    }
    
    
    func clearAllPost(){
        self.fetchedPosts = []
        self.displayedPosts = []
    }
    
    
    func clearFilter(){
        self.viewFilter?.clearFilter()
        self.showFilterView()
    }
    
    @objc func refreshPostsForFilter(){
        self.clearAllPost()
        self.setupListFollowButton()
//        self.collectionView.reloadData()
        self.fetchPostsForList()
        self.showFilterView()
        self.imageCollectionView.refreshControl?.endRefreshing()
    }
    
    @objc func handleUpdateList() {
        print("ListViewController | handleUpdateList | SharePhotoListController.updateListFeedNotificationName")
        // Update All List
        self.displayedLists = CurrentUser.lists
    
        
        // Update Currently Displayed List
        if let listIndex = CurrentUser.lists.firstIndex(where: { (currentList) -> Bool in
            currentList.id == self.currentDisplayList?.id
        }) {
            self.currentDisplayList = CurrentUser.lists[listIndex]
        }
    }
    

    // Search Delegates
    
    func clearCaptionSearch(){
        self.viewFilter?.filterCaption = nil
        self.refreshPostsForFilter()
    }
    
    func filterCaptionSelected(searchedText: String?){
        print("Filter Caption Selected: \(searchedText)")
        self.viewFilter?.filterCaption = searchedText
        self.refreshPostsForFilter()
    }
    
//    func userSelected(uid: String?){
//
//    }
    
//    func locationSelected(googlePlaceId: String?, googlePlaceName: String?, googlePlaceLocation: CLLocation?, googlePlaceType: [String]?){
//
//    }
    
    

    

    func headerSortSelected(sort: String) {
        self.viewFilter?.filterSort = sort
//        self.collectionView.reloadData()
        
        self.setupRankView()

        if (self.viewFilter?.filterSort == HeaderSortOptions[1] && self.viewFilter?.filterLocation == nil){
            print("Sort by Nearest, No Location, Look up Current Location")
            LocationSingleton.sharedInstance.determineCurrentLocation()
            let when = DispatchTime.now() + defaultGeoWaitTime // change 2 to desired number of seconds
            DispatchQueue.main.asyncAfter(deadline: when) {
                //Delay for 1 second to find current location
                self.viewFilter?.filterLocation = CurrentUser.currentLocation
                self.refreshPostsForFilter()
            }
        }  else  {
            self.refreshPostsForFilter()
        }
        
        print("Filter Sort is ", self.viewFilter?.filterSort)
    }
    
    
    
    

    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if self.postFormatInd == 2 {
            var height: CGFloat = 35 //headerview = username userprofileimageview
            height += view.frame.width  // Picture
            height += 50    // Action Bar + List Count
            height += 25    // Date Bar
            return CGSize(width: view.frame.width, height: height)
        } else if self.postFormatInd == 1 {
            return CGSize(width: view.frame.width, height: 180)
        } else if self.postFormatInd == 0 {
            let width = (view.frame.width - 2) / 2
            return CGSize(width: width, height: width)
        } else {
            return CGSize(width: view.frame.width, height: view.frame.width)
        }
        
//        if isListView {
//            return CGSize(width: view.frame.width, height: 180)
//        } else {
//            let width = (view.frame.width - 2) / 3
//            return CGSize(width: width, height: width)
//        }
    }
    
    
     func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == emojiCollectionView {
            return listDisplayEmojis.count
        } else {
            return (self.viewFilter?.isFiltering)! ? displayedPosts.count : fetchedPosts.count
        }
    }
    
     func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == emojiCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emojiCellID, for: indexPath) as! UploadEmojiCell
            let displayEmoji = self.listDisplayEmojis[indexPath.item]
            let isFiltered = (self.viewFilter?.filterCaption)?.contains(displayEmoji) ?? false
            cell.uploadEmojis.text = displayEmoji
            cell.uploadEmojis.font = cell.uploadEmojis.font.withSize(25)
            cell.layer.borderWidth = 0
            
            //Highlight only if emoji is tagged, dont care about caption
            //        cell.backgroundColor = isFiltered ? UIColor.selectedColor() : UIColor.clear
            cell.backgroundColor = isFiltered ? UIColor.ianLegitColor() : UIColor.clear
            
            cell.layer.borderColor = UIColor.white.cgColor
            cell.isSelected = isFiltered
            cell.sizeToFit()
            return cell
            
        }
        
        else
        {
            var displayPost = (self.viewFilter?.isFiltering)! ? displayedPosts[indexPath.item] : fetchedPosts[indexPath.item]
            
            if let tempRank = self.tempRank {
                displayPost.listedRank = tempRank[(displayPost.id)!]
            }
            
            if self.postFormatInd == 2 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: fullCellId, for: indexPath) as! FullPictureCell
                cell.post = displayPost
                
                if self.viewFilter?.filterLocation != nil && cell.post?.locationGPS != nil {
                    cell.post?.distance = Double((cell.post?.locationGPS?.distance(from: (self.viewFilter?.filterLocation!)!))!)
                }
                
                cell.currentImage = 1
                cell.delegate = self
                return cell
            }
                
            else if self.postFormatInd == 1 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: bookmarkCellId, for: indexPath) as! NewListPhotoCell
                cell.delegate = self
                cell.bookmarkDate = displayPost.listedDate
                cell.showRank = self.viewFilter?.filterSort == "Rank"
                cell.post = displayPost
                
                
                if self.currentDisplayList?.creatorUID == Auth.auth().currentUser?.uid {
                    //                cell.allowDelete = true
                    cell.showCancelButton = true
                } else {
                    //                cell.allowDelete = false
                    cell.showCancelButton = false
                }
                return cell
            }
                
            else if self.postFormatInd == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: gridCellId, for: indexPath) as! TestGridPhotoCell
                cell.delegate = self
                cell.showDistance = self.viewFilter?.filterSort == defaultNearestSort
                cell.post = displayPost
                cell.enableCancel = self.currentDisplayList?.creatorUID == Auth.auth().currentUser?.uid
                
                return cell
            }
                
            else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: gridCellId, for: indexPath) as! GridPhotoCell
                cell.delegate = self
                cell.post = displayPost
                return cell
            }
        }
    }
    
     func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == emojiCollectionView {
            let emoji = listDisplayEmojis[indexPath.item]
            self.didTapEmoji(index: 0, emoji: emoji)
        }
        else
        {
            let post = fetchedPosts[indexPath.item]
            
            if post.id == self.selectedPostID {
                let pictureController = SinglePostView()
                pictureController.post = post
                navigationController?.pushViewController(pictureController, animated: true)
            } else {
                self.selectedPostID = post.id
                self.selectedPostIDLoc = post.locationGPS
            }
        }
        //print(displayedPosts[indexPath.item])
    }
    
    // SORT FILTER HEADER
    
     func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: listHeaderId, for: indexPath) as! NewHeader
        header.isFiltering = (self.viewFilter?.isFiltering)!
        header.selectedSort = (self.viewFilter?.filterSort)!
        header.isPostView = (self.postFormatInd == 1)
        header.delegate = self
//        header.customBackgroundColor =  UIColor.init(white: 0, alpha: 0.2)

        return header
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        var height = 30 + 5 + 5 // Header Sort with 5 Spacing
        height += 40 // Search bar View
        return CGSize(width: view.frame.width, height: 50)
    }
    

    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let item = self.fetchedPosts[indexPath.row].id
        let itemProvider = NSItemProvider(object: item as! NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            // Get last index path of table view.
            let section = collectionView.numberOfSections - 1
            let row = collectionView.numberOfItems(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }
        
        switch coordinator.proposal.operation
        {
        case .move:
            self.reorderItems(coordinator: coordinator, destinationIndexPath:destinationIndexPath, collectionView: collectionView)
            break
        case .cancel:
            return
        default:
            return
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if self.viewFilter?.filterSort == "Rank" {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        } else {
            return UICollectionViewDropProposal(operation: .cancel, intent: .unspecified)
        }

    }

    private func reorderItems(coordinator: UICollectionViewDropCoordinator, destinationIndexPath: IndexPath, collectionView: UICollectionView)
    {
        let items = coordinator.items
        if items.count == 1, let item = items.first, let sourceIndexPath = item.sourceIndexPath
        {
            var dIndexPath = destinationIndexPath
            if dIndexPath.row >= collectionView.numberOfItems(inSection: 0)
            {
                dIndexPath.row = collectionView.numberOfItems(inSection: 0) - 1
            }
            collectionView.performBatchUpdates({
                
                let tempPost = fetchedPosts.first(where: { (post) -> Bool in
                    post.id == item.dragItem.localObject as! String
                })
                self.fetchedPosts.remove(at: sourceIndexPath.row)
                self.fetchedPosts.insert(tempPost as! Post, at: dIndexPath.row)
                
                print("ListViewController | reorderItems | Moving \(sourceIndexPath.row) to \(dIndexPath.row)")
                
                collectionView.deleteItems(at: [sourceIndexPath])
                collectionView.insertItems(at: [dIndexPath])
                
                if self.viewFilter?.filterSort == "Rank" {
                    if self.currentDisplayList?.creatorUID == Auth.auth().currentUser?.uid {
                        do {
                            try self.rerankPostForList()
                        } catch {
                            print(error)
                        }
                    }
                }
            })
            
            coordinator.drop(items.first!.dragItem, toItemAt: dIndexPath)
            
        }
    }
    

    
    // Empty Data Set Delegates
    
    // EMPTY DATA SET DELEGATES
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        if (self.viewFilter?.isFiltering)! {
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
        
        //        if isFiltering {
        //            text = nil
        //        } else {
        //            text = nil
        //        }
        
        //        let number = arc4random_uniform(UInt32(tipDefaults.count))
        //        text = tipDefaults[Int(number)]
        text = nil
        
        font = UIFont(name: "Poppins-Regular", size: 15)
        textColor = UIColor.ianBlackColor()
        
        if (viewFilter?.isFiltering)! {
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
        return #imageLiteral(resourceName: "Legit_Vector")
    }
    
    
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        if (self.viewFilter?.isFiltering)! {
            text = "Try Searching For Something Else"
        } else {
            text = "Start Adding Posts to Your Lists!"
        }
        text = ""
        font = UIFont.boldSystemFont(ofSize: 14.0)
        textColor = UIColor(hexColor: "00aeef")
        
        if text == nil {
            return nil
        }
        
        return NSMutableAttributedString(string: text!, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): font, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): textColor]))
        
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
//
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
        return UIColor.backgroundGrayColor()
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {
        if (self.viewFilter?.isFiltering)! {
             self.openFilter()
        } else {
            // Returns To Home Tab
            self.tabBarController?.selectedIndex = 0
        }
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapView view: UIView) {
        self.handleRefresh()
    }
    
//    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
//        let offset = (self.collectionView.frame.height) / 5
//        return -50
//    }
    
    func spaceHeight(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return 9
    }
    
    
    
    
    
    // List Header Delegate
    func didChangeToListView(){
        print("ListViewController | Change to Grid View")
        self.postFormatInd = 1
        self.imageCollectionView.reloadData()

//        self.isListView = true
//        collectionView.reloadData()
    }
    
    func didChangeToGridView() {
        print("ListViewController | Change to Grid View")
        self.postFormatInd = 0
        self.imageCollectionView.reloadData()
    }
    
    
    func didChangeToPostView() {
//        self.isListView = false
//        collectionView.reloadData()
    }
    
    
    func changePostFormat(formatInd: Int) {
        self.postFormatInd = formatInd
        self.imageCollectionView.reloadData()
    }
    

    
    
    func openFilter(){
        let filterController = SearchFilterController()
        filterController.delegate = self
        filterController.searchFilter = self.viewFilter
        self.navigationController?.pushViewController(filterController, animated: true)
    }
    
    // Search Delegates
    func filterControllerSelected(filter: Filter?) {
        self.viewFilter = filter
        self.searchBar.text = filter?.filterCaption
        self.refreshPostsForFilter()
    }
    
    func openSearch(index: Int?){
        
        let postSearch = MainSearchController()
        postSearch.delegate = self
        postSearch.searchFilter = self.viewFilter
        postSearch.searchController.searchBar.text = self.viewFilter?.filterCaption
        
        // Option Counts for Current Filter
        Database.countEmojis(posts: self.fetchedPosts) { (emojiCounts) in
            postSearch.emojiCounts = emojiCounts
        }
        Database.countCityIds(posts: self.fetchedPosts) { (locationCounts) in
            postSearch.locationCounts = locationCounts
        }
        
        postSearch.defaultEmojiCounts = self.noCaptionFilterEmojiCounts
        postSearch.defaultLocationCounts = self.noCaptionFilterLocationCounts
        
        postSearch.searchFilter = self.viewFilter
        postSearch.setupInitialSelections()
        
        
        self.navigationController?.pushViewController(postSearch, animated: true)
        postSearch.selectedScope = index!
        postSearch.searchController.searchBar.selectedScopeButtonIndex = index!

        
    }
    

    // HOME POST CELL DELEGATE METHODS
    
    func didTapBookmark(post: Post) {
        
        let sharePhotoListController = SharePhotoListController()
        sharePhotoListController.uploadPost = post
        sharePhotoListController.isBookmarkingPost = true
        sharePhotoListController.delegate = self
        navigationController?.pushViewController(sharePhotoListController, animated: true)
    }
    
    
    func didTapPicture(post: Post) {
        
        let pictureController = SinglePostView()
        pictureController.post = post

        navigationController?.pushViewController(pictureController, animated: true)
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
    
    func didTapExtraTag(tagName: String, tagId: String, post: Post) {
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        // Check to see if its a list, price or something else
        if tagId == "price"{
            // Price Tag Selected
            print("Price Selected")
            self.viewFilter?.filterMaxPrice = tagName
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
            // List Tag Selected
            Database.checkUpdateListDetailsWithPost(listName: tagName, listId: tagId, post: post, completion: { (fetchedList) in
                if fetchedList == nil {
                    // List Does not Exist
                    self.alert(title: "List Display Error", message: "List Does Not Exist Anymore")
                } else {
                    if fetchedList?.publicList == 0 && fetchedList?.creatorUID != uid {
                        self.alert(title: "List Display Error", message: "List Is Private")
                    } else {
                        let listViewController = ListViewController()
                        listViewController.currentDisplayList = fetchedList
                        self.navigationController?.pushViewController(listViewController, animated: true)
                    }
                }
            })
        }
    }
    
    func refreshPost(post: Post) {
        let index = fetchedPosts.firstIndex { (fetchedPost) -> Bool in
            fetchedPost.id == post.id
        }
        
        // Update Cache
        
        let postId = post.id
        postCache[postId!] = post
        
        //        self.collectionView?.reloadItems(at: [filteredindexpath])
    }
    
    func didTapMessage(post: Post) {
        
        let messageController = MessageController()
        messageController.post = post
        
        navigationController?.pushViewController(messageController, animated: true)
        
    }
    
    
    func didTapListCancel(post:Post) {
        self.deletePostFromList(post: post)
    }
    
    
    func userOptionPost(post:Post){
        
        let optionsAlert = UIAlertController(title: "User Options", message: "", preferredStyle: UIAlertController.Style.alert)
        
        optionsAlert.addAction(UIAlertAction(title: "Edit Post", style: .default, handler: { (action: UIAlertAction!) in
            // Allow Editing
            self.editPost(post: post)
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Delete Post", style: .default, handler: { (action: UIAlertAction!) in
            self.deletePost(post: post)
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        present(optionsAlert, animated: true, completion: nil)
    }
    
    func editPost(post:Post){
//        let editPost = SharePhotoController()
//        
//        // Post Edit Inputs
//        editPost.editPostInd = true
//        editPost.editPostImageUrl = post.imageUrl
//        editPost.editPostId = post.id
//        
//        // Post Details
//        editPost.selectPostGooglePlaceID = post.locationGooglePlaceID
//        editPost.selectedImageLocation = post.locationGPS
//        editPost.selectPostLocation = post.locationGPS
//        editPost.selectPostLocationName = post.locationName
//        editPost.selectPostLocationAdress = post.locationAdress
//        editPost.selectTime = post.tagTime
//        editPost.nonRatingEmoji = post.nonRatingEmoji
//        editPost.nonRatingEmojiTags = post.nonRatingEmojiTags
//        editPost.captionTextView.text = post.caption
//        
//        let navController = UINavigationController(rootViewController: editPost)
//        self.present(navController, animated: false, completion: nil)
        
        let editPost = MultSharePhotoController()
        // Post Edit Inputs
        editPost.editPostInd = true
        editPost.editPost = post
        
        self.navigationController?.pushViewController(editPost, animated: true)
    }
    
    
    func deletePost(post:Post){
        
        let deleteAlert = UIAlertController(title: "Delete", message: "All data will be lost.", preferredStyle: UIAlertController.Style.alert)
        deleteAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            
            // Remove from Current View
            let index = self.fetchedPosts.firstIndex { (filteredpost) -> Bool in
                filteredpost.id  == post.id
            }
            
            let filteredindexpath = IndexPath(row:index!, section: 0)
            self.fetchedPosts.remove(at: index!)
            self.imageCollectionView.deleteItems(at: [filteredindexpath])
            Database.deletePost(post: post)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        present(deleteAlert, animated: true, completion: nil)
        
    }
    
    func deletePostFromList(post: Post) {
        
        let deleteAlert = UIAlertController(title: "Delete", message: "Remove Post From List?", preferredStyle: UIAlertController.Style.alert)
        
        deleteAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                // Remove from Current View
                let index = self.fetchedPosts.firstIndex { (filteredpost) -> Bool in
                    filteredpost.id  == post.id
                }
            
                let deleteindexpath = IndexPath(row:index!, section: 0)
                self.fetchedPosts.remove(at: index!)
                let listdeleteindex = self.currentDisplayList?.postIds?.index(forKey: post.id!)
                self.currentDisplayList?.postIds?.remove(at: listdeleteindex!)
                self.imageCollectionView.deleteItems(at: [deleteindexpath])
                Database.DeletePostForList(postId: post.id, postCreatorUid: (post.creatorUID)!, listId: self.currentDisplayList?.id, postCreationDate: nil)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        if self.currentDisplayList?.creatorUID == uid{
            // Only Allow Deletion if current user is list creator
            present(deleteAlert, animated: true, completion: nil)
        }
    }
    
    func displaySelectedEmoji(emoji: String, emojitag: String) {
        
        var emojiPostCount = String(self.noCaptionFilterEmojiCounts[emoji] ?? 0)
        
        emojiDetailLabel.text = "   " + emoji + " " + emojitag + " - \(emojiPostCount) Posts   "
        emojiDetailLabel.sizeToFit()
        emojiDetailLabel.isHidden = false
    }
    
    
    
    func didTapUserUid(uid: String) {
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = uid
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func displayPostSocialUsers(post: Post, following: Bool) {
        print("Display Vote Users| Following: ",following)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayUser = true
        postSocialController.displayUserFollowing = following
        postSocialController.inputPost = post
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    func displayPostSocialLists(post: Post, following: Bool) {
        print("Display Lists| Following: ",following)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayList = true
        postSocialController.displayFollowing = (post.followingList.count > 0)
        postSocialController.inputPost = post
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    func displayListFollowingUsers(list: List, following: Bool) {
        print("Display Users| Following: ",list.id)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayUser = true
        postSocialController.displayUserFollowing = false
        postSocialController.inputList = list
        navigationController?.pushViewController(postSocialController, animated: true)
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
