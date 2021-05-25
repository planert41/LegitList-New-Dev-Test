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

protocol NewListViewControllerHeaderDelegate {
    func deleteList(list:List?)
    func didTapUser(user: User)
    func handleFollowingList()
    func didTapListSetting()
    func didTapEditList()
    func didChangeToGridView()
    func didChangeToListView()
//    func didTapAddTagSearch(string: String)
    func displayPostSocialUsers(post: Post, following: Bool)
    func displayPostSocialLists(post: Post, following: Bool)
    func displayListFollowingUsers(list: List, following: Bool)
    func headerSortSelected(sort: String)
    func openFilter()
    func toggleMapFunction()
    func didTapAddTag(addTag: String)
    func searchListForText(text: String?)
}

class NewListViewControllerHeader: UICollectionViewCell, EmojiButtonArrayDelegate, UIGestureRecognizerDelegate, UISearchBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource, HomeDropDownViewDelegate, UploadEmojiCellDelegate {

    var tabBarDisplayNavigationBar: Bool = false
    var delegate: NewListViewControllerHeaderDelegate?
    
    
    var currentDisplayList: List? = nil {
        didSet{
            print(" ListHeader | DISPLAYING | \(currentDisplayList?.name) | \(currentDisplayList?.id) | \(currentDisplayList?.postIds?.count) Posts |List_ViewController")
            
            //            print("currentDisplayList | \(currentDisplayList?.name) | \(currentDisplayList?.id) | \(currentDisplayList?.postIds?.count)")
            // CLEAR SEARCH BAR
            self.clearCaptionSearch()
            self.updateListLabels()
            self.setupListFollowButton()
            self.setupActionButtons()
            self.setupListSettingButton()
            
            if currentDisplayList?.heroImage != nil {
                self.heroBackgroundImageView.image = currentDisplayList?.heroImage
            } else if let url = currentDisplayList?.heroImageUrl {
                if url != "" {
                    self.heroBackgroundImageView.loadImage(urlString: url)
                }
            }
            
            // Setup AddTag Options
            addTagOptions = []

        }
    }

    
    
    func refreshAddTagOptions(){
        addTagOptions = []
        guard let list = currentDisplayList else {return}
        let tempTagCounts = list.tagCounts.sorted { (p1, p2) -> Bool in
            return p1.value > p2.value
        }
        
        for (tag, count) in tempTagCounts {
            addTagOptions.append(tag)
        }
        
        addTagCollectionView.reloadData()
        
    }
    
    // Used to fetch lists
    var displayUser: User? = nil {
        didSet{
            print("NewListCollectionViewHeader | Current display user: \(displayUser?.username) | \(displayUser?.uid)")
            self.setupUser()
        }
    }
    
    func setupUser(){
        guard let displayUser = displayUser else {return}
        print("    Loading User For ListHeader | \(String(displayUser.username)) ")

        usernameLabel.text = displayUser.username
        usernameLabel.sizeToFit()
        usernameLabel.adjustsFontSizeToFitWidth = true
        usernameLabel.sizeToFit()

        
        let profileImageUrl = displayUser.profileImageUrl
        print("    Loading User Profile Image | \(profileImageUrl) ")

        userProfileImageView.loadImage(urlString: profileImageUrl)

        if let imageWidth = userProfileImageWidthConstraint {
            imageWidth.constant = (displayUser.uid == Auth.auth().currentUser?.uid) ? 0 : 35
            imageWidth.isActive = true
        }
        
    }
    
    @objc func usernameTap(){
        guard let displayUser = displayUser else {return}
        self.delegate?.didTapUser(user: displayUser)
    }
    
    let postCountLabel: UILabel = {
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
    

// COLLECTIONVIEW FOR ADD TAGS
    
    let addTagCollectionView: UICollectionView = {
        let uploadLocationTagList = UploadLocationTagList()
        
        uploadLocationTagList.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadLocationTagList)
        cv.layer.borderWidth = 0
        cv.backgroundColor = UIColor.clear
        return cv
    }()
    
    let addTagId = "addTagId"
    
    func setupAddTagCollectionView(){
        addTagCollectionView.backgroundColor = UIColor.backgroundGrayColor()
        addTagCollectionView.register(HomeFilterBarCell.self, forCellWithReuseIdentifier: addTagId)
        addTagCollectionView.delegate = self
        addTagCollectionView.dataSource = self
        addTagCollectionView.showsHorizontalScrollIndicator = false
    }
    
    
    var addTagOptions: [String] = []
    var displayedAddTagOptions: [String] = []

    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return listDisplayEmojis.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emojiCellID, for: indexPath) as! UploadEmojiCell
        let displayEmoji = self.listDisplayEmojis[indexPath.item]
        let isFiltered = isFilteringText?.contains(displayEmoji) ?? false
        cell.uploadEmojis.text = displayEmoji
        cell.uploadEmojis.font = cell.uploadEmojis.font.withSize(25)
        cell.layer.borderWidth = 0
        cell.delegate = self
        //Highlight only if emoji is tagged, dont care about caption
        //        cell.backgroundColor = isFiltered ? UIColor.selectedColor() : UIColor.clear
        cell.backgroundColor = isFiltered ? UIColor.ianLegitColor() : UIColor.clear
        
        cell.layer.borderColor = UIColor.white.cgColor
        cell.isSelected = isFiltered
        cell.sizeToFit()
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = indexPath.row
        let emoji = self.listDisplayEmojis[indexPath.row]
        
        self.delegate?.didTapAddTag(addTag: emoji)
    }
    
    
    func didTapRatingEmoji(emoji: String) {
        
    }
    
    func didTapNonRatingEmoji(emoji: String) {
        self.delegate?.didTapAddTag(addTag: emoji)

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
            
            // UPDATE LIST DESCRIPTION
            if self.currentDisplayList?.listDescription?.isEmptyOrWhitespace() ?? true {
                let blankDesc = NSMutableAttributedString(string: "No List Description", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.lightGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .avenirNextItalic, size: 14)]))
                self.listSummaryLabel.attributedText = blankDesc
            } else {
                self.listSummaryLabel.text = self.currentDisplayList?.listDescription
            }

            let listDetailString = NSMutableAttributedString()
            
            
            // UPDATE FOLLOWER COUNT
            if let followerCount = (self.currentDisplayList?.followerCount) {
                let followerCountText = NSMutableAttributedString()
                let followerCountString = NSMutableAttributedString(string: "\(followerCount) Followers  ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Poppins-Regular", size: 14)]))
                followerCountText.append(followerCountString)
                
                self.followerCountLabel.attributedText = followerCountText
            }
            
            // UPDATE POST COUNT
            if let postCount = (self.currentDisplayList?.postIds?.count) {
                if postCount > 0 {
                    
                    let postCountText = NSMutableAttributedString()
                    let postCountString = NSMutableAttributedString(string: "\(postCount) Posts  ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font):  UIFont(name: "Poppins-Bold", size: 14)]))
                    postCountText.append(postCountString)
                    listDetailString.append(postCountText)
                }
            }
            
            
            // UPDATE AVERAGE RATING
//            if self.noFilterAverageRating > 0.0 {
//                let ratingText = String(format: "%.2f", self.noFilterAverageRating)
//                let postCountText = NSMutableAttributedString()
//                let postCountString = NSMutableAttributedString(string: "Avg Rating: \(ratingText)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.legitColor(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: inputFontSize)]))
//                postCountText.append(postCountString)
//                listDetailString.append(postCountText)
//            }
            
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
            
        }
    }

    
    
    
    
    //DISPLAY VARIABLES
    var fetchedPosts: [Post] = [] {
        didSet{
            
//            if !(self.viewFilter?.isFiltering)!{
//                Database.countMostUsedEmojis(posts: self.fetchedPosts) { (emojis) in
//                    self.listDisplayEmojis = emojis
//                    //                print("Most Displayed Emojis: \(emojis)")
//                }
//            }
        }
    }
    
    var displayedPosts: [Post] = []
    
    var listDisplayEmojis: [String] = [] {
        didSet{
            print("    \(listDisplayEmojis.count) Displayed Emojis | NewListHeader")
            self.emojiCollectionView.reloadData()
            self.refreshEmojiArray()
        }
    }
    
    
    func refreshEmojiArray(){
        //        print("REFRESH EMOJI ARRAYS")
        
        
        if self.listDisplayEmojis.count > 0 {
            emojiArray.emojiLabels = self.listDisplayEmojis
            emojiArray.setEmojiButtons()
            emojiArray.sizeToFit()
            
            for button in emojiArray.emojiButtonArray {
                button.backgroundColor = UIColor.clear
                if let emojiText = button.titleLabel?.text {
                    if self.viewFilter?.filterCaption?.contains(emojiText) ?? false{
                        button.backgroundColor = UIColor.mainBlue()
                    }
                }
            }
        } else {
            emojiArray.emojiLabels = []
        }
        
        print("UPDATED EMOJI ARRAY: \(emojiArray.emojiLabels)")
        
    }
    
    var emojiArray = EmojiButtonArray(emojis: [], frame: CGRect(x: 0, y: 0, width: 0, height: 15))
    
    
    func didTapEmoji(index: Int?, emoji: String) {
        guard let index = index else {
            print("No Index For emoji \(emoji)")
            return
        }
        
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
    

    // List Social Label
    let listSocialLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    
    // Emoji description
    
    let emojiDetailLabel: UILabel = {
        let label = UILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.white
        label.layer.cornerRadius = 30/2
        label.layer.borderWidth = 0.25
        label.layer.borderColor = UIColor.ianLegitColor().cgColor
        label.layer.masksToBounds = true
        return label
        
    }()
    
    func setupEmojiDetailLabel(){
        addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top: nil, left: nil, bottom: listDetailView.topAnchor, right: listDetailView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 3, paddingRight: 0, width: 0, height: 25)
        emojiDetailLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
        //        emojiDetailLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        emojiDetailLabel.isHidden = true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        emojiDetailLabel.isHidden = true
    }
    
    

    
    // LIST CREATOR USER INFO
    
    let userProfileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        iv.layer.borderColor = UIColor.darkLegitColor().cgColor
        iv.layer.borderWidth = 0
        return iv
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Poppins-Bold", size: 12)
        label.textColor = UIColor.ianBlackColor()
        label.textAlignment = NSTextAlignment.left
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
        self.setupActionButtons()
    }
    
    @objc func handleFollowingList(){
        self.delegate?.handleFollowingList()
    }
    
    
    // SORT SEGMENT VIEW
    
    
    
    var headerSortSegment = UISegmentedControl()
    let buttonBar = UIView()
    var buttonBarPosition: NSLayoutConstraint?
    
//    var selectedSort: String = defaultRankSort {
//        didSet{
//            if self.selectedSort == defaultRecentSort {
//                self.selectedSort = defaultRankSort
//                return
//            }
//
////            self.underlineSegment(segment: sortOptions.index(of: selectedSort)!)
//            headerSortSegment.selectedSegmentIndex = sortOptions.index(of: selectedSort)!
//        }
//    }
//
//    var sortOptions: [String] = listHeaderSortOptions
    
    
    lazy var listSortButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(showSortDropDown), for: .touchUpInside)
        //        button.layer.backgroundColor = UIColor.darkLegitColor().withAlphaComponent(0.8).cgColor
        //        button.layer.backgroundColor = UIColor.lightSelectedColor().cgColor
        button.layer.backgroundColor = UIColor.ianLegitColor().cgColor
        button.tintColor = UIColor.white
        
        //        button.setTitleColor(UIColor(hexColor: "f10f3c"), for: .normal)
        //        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 13)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.selectedColor().cgColor
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        
        //        let iconImage = #imageLiteral(resourceName: "downvote_selected").withRenderingMode(.alwaysTemplate)
        //        button.setImage(iconImage, for: .normal)
        
        return button
    }()
    
    let sortDropDownHeaderText = "Sort List By"
    let sortDetails = ["Most recent posts", "Arranged by user", "Closest to your current location"]
    var sortOptions: [String] = [sortRank, sortNew, sortNearest]
    var selectedSort: String = sortRank {
        didSet{
//            self.displaySort(sort: selectedSort)
            self.underlineSegment(segment: sortOptions.firstIndex(of: selectedSort)!)

//            self.delegate?.headerSortSelected(sort: selectedSort)
            //            self.listSortButton.setTitle(selectedSort + "  ", for: .normal)
        }
    }
    
    
    var dropdownSortView = HomeDropDownView()
    @objc func showSortDropDown(){
        
        //        dropdownView.viewFilter = viewFilter
        
        dropdownSortView.dropDownTrueCenter = true
        dropdownSortView.cellHeaders = sortOptions
        dropdownSortView.cellDetails = sortDetails
        dropdownSortView.selectedVar = self.selectedSort
        
        dropdownSortView.setupTitleLabelCustom(string: sortDropDownHeaderText)
        dropdownSortView.delegate = self
        dropdownSortView.show()
    }
    
    func dropDownSelected(string: String) {
        if sortOptions.contains(string) {
//            self.selectedSort = string
            self.delegate?.headerSortSelected(sort: string)
            print(" List Sort Drop Down Selected | \(string)")
        }
    }
    
    func displaySort(sort: String?) {
        guard let sort = sort else {return}
        
        var attributedTitle = NSMutableAttributedString()
        
        let sortTitle = NSAttributedString(string: sort + "  ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 13)])
        attributedTitle.append(sortTitle)
        
        //        let iconImage = (self.selectedSort == sortNew) ? #imageLiteral(resourceName: "downvote_selected").withRenderingMode(.alwaysTemplate) : #imageLiteral(resourceName: "upvote_selected").withRenderingMode(.alwaysTemplate)
        let iconImage = #imageLiteral(resourceName: "downvote_selected").withRenderingMode(.alwaysTemplate)
        let legitIcon = iconImage
        //        guard let legitIcon = iconImage.resizeVI(newSize: CGSize(width: 12, height: 12)) else {return}
        let legitImage = NSTextAttachment()
        legitImage.bounds = CGRect(x: 0, y: ((listSortButton.titleLabel?.font.capHeight)! - legitIcon.size.height - 6).rounded() / 2, width: legitIcon.size.width, height: legitIcon.size.height)
        legitImage.image = legitIcon
        let legitImageString = NSAttributedString(attachment: legitImage)
        attributedTitle.append(legitImageString)
        
        self.listSortButton.tintColor = UIColor.white
        self.listSortButton.setAttributedTitle(attributedTitle, for: .normal)
        
    }
    
    
    
    
    
    func setupSegment(){

        headerSortSegment = UISegmentedControl(items: sortOptions)
        headerSortSegment.selectedSegmentIndex = sortOptions.firstIndex(of: self.selectedSort)!
        headerSortSegment.addTarget(self, action: #selector(selectSort), for: .valueChanged)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        headerSortSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
        headerSortSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)

        headerSortSegment.backgroundColor = .white
        headerSortSegment.tintColor = .white
    }

    func underlineSegment(segment: Int? = 0){

        print(" underlineSegment | \(segment) | ListHeader")
        let segmentWidth = (self.frame.width - 50) / CGFloat(sortOptions.count)
        let tempX = self.buttonBar.frame.origin.x
        UIView.animate(withDuration: 0.3) {
            self.buttonBar.frame.origin.x = segmentWidth * CGFloat(segment ?? 0)
            self.buttonBarPosition?.constant = segmentWidth * CGFloat(segment ?? 0)
            self.buttonBarPosition?.isActive = true
        }

        //        print("UnderlineSegment | Segment \(segment!) | Pre ",tempX, " | Post ", self.buttonBar.frame.origin.x)

    }

    @objc func selectSort(sender: UISegmentedControl) {
        self.selectedSort = sortOptions[sender.selectedSegmentIndex]
        let when = DispatchTime.now() + 0.5 // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            //Delay for 1 second for animation
            self.delegate?.headerSortSelected(sort: self.selectedSort)
        }
        print("Selected Sort is ",self.selectedSort)
    }
    
    // GRID/LIST BUTTONS
    
    var postFormatInd: Int = 0 {
        didSet{
            print(" postFormatInd | \(postFormatInd) | ListHeader")
            setupFormatButton()
        }
    }
    // 0 Grid View
    // 1 List View
    // 2 Full View
    
    lazy var formatButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage((postFormatInd == 0 ? #imageLiteral(resourceName: "grid_button") : #imageLiteral(resourceName: "postview")).withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.ianLegitColor()
        button.addTarget(self, action: #selector(toggleView), for: .touchUpInside)
        return button
    }()
    
    @objc func toggleView(){
        // 0 = Grid
        // 1 = List
        
        if (postFormatInd == 0) {
            self.didChangeToListView()
        } else if (postFormatInd == 1) {
            self.didChangeToGridView()
        }
    }
    
    lazy var gridButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "grid_button").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = (postFormatInd == 0) ? UIColor.ianLegitColor() : UIColor.lightGray
        button.addTarget(self, action: #selector(didChangeToGridView), for: .touchUpInside)
        return button
    }()
    
    lazy var listButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "postview").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = (postFormatInd == 1) ? UIColor.ianLegitColor() : UIColor.lightGray
        button.addTarget(self, action: #selector(didChangeToListView), for: .touchUpInside)
        return button
    }()
    
    func setupFormatButton(){
        gridButton.tintColor = (postFormatInd == 0) ? UIColor.ianLegitColor() : UIColor.lightGray
        listButton.tintColor = (postFormatInd == 1) ? UIColor.ianLegitColor() : UIColor.lightGray
    }
    
    // FILTER SEARCH VARIABLES
    
    lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "search_tab_fill").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(openFilter), for: .touchUpInside)
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.ianOrangeColor().cgColor
        button.clipsToBounds = true
        return button
    }()
    
    var viewFilter: Filter? = Filter.init(defaultSort: defaultRankSort) {
        didSet {
//            if (self.viewFilter?.isFiltering)! {
//                let currentFilter = self.viewFilter
//                var searchTerm: String = ""
//
//                if currentFilter?.filterCaption != nil {
//                    searchTerm.append("\((currentFilter?.filterCaption)!) | ")
//                }
//
//                if currentFilter?.filterLocationName != nil {
//                    var locationNameText = currentFilter?.filterLocationName
//                    if locationNameText == "Current Location" || currentFilter?.filterLocation == CurrentUser.currentLocation {
//                        locationNameText = "Here"
//                    }
//                    searchTerm.append("\(locationNameText!) | ")
//                }
//
//                if (currentFilter?.filterLegit)! {
//                    searchTerm.append("Legit | ")
//                }
//
//                if currentFilter?.filterMinRating != 0 {
//                    searchTerm.append("\((currentFilter?.filterMinRating)!) Stars | ")
//                }
//                self.isFilteringText = searchTerm
//
//            } else {
//                self.isFilteringText = nil
//            }
            
            if viewFilter?.filterSort == defaultRecentSort {
                viewFilter?.filterSort = viewFilter?.filterSort
            }
            
            self.selectedSort = viewFilter?.filterSort ?? defaultRankSort
            //        self.refreshPostsForFilter()
        }
    }
    
    var isFilteringText: String? = nil {
        didSet {
            if let filterText = isFilteringText{
                self.searchBar.text = filterText
                print(" LV_Header | isFilteringText | \(filterText)")
            }
        }
    }
    
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
    
    let listDetailView = UIView()
    var listDetailViewHeight: NSLayoutConstraint?

    
    let listDetailDivider = UIView()
    
    let listSummaryLabel: UILabel = {
        let label = UILabel()
        label.text = "No List Description"
        label.font = UIFont(name: "Poppins-Regular", size: 14)
        label.textColor = UIColor.rgb(red: 85, green: 85, blue: 85)
        //        label.textColor = UIColor.init(hexColor: "F1C40F")
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.clear
        label.adjustsFontSizeToFitWidth = false
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        return label
    }()
    
    let listURLLabel: UILabel = {
        let label = UILabel()
        label.text = "URL"
        label.font = UIFont(font: .helveticaNeueItalic, size: 12)
        label.textColor = UIColor.mainBlue()
        //        label.textColor = UIColor.init(hexColor: "F1C40F")
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 1
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        return label
    }()
    
    
    let followerCountLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.clear
        label.isUserInteractionEnabled = true
        return label
    }()
    
    
    // HERO IMAGE BACKGROUND
    
    var heroImageUrl: String? {
        didSet {
            if let url = heroImageUrl {
                if url != "" {
                    self.heroBackgroundImageView.loadImage(urlString: url)
                }
            }
        }
    }
    
    
    let heroBackgroundImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.borderColor = UIColor.darkLegitColor().cgColor
        iv.layer.borderWidth = 1
        return iv
    }()
    
    
    let listNameLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(name: "Poppins-Bold", size: 50)
        label.textColor = UIColor.white
        //        label.textColor = UIColor.init(hexColor: "F1C40F")
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.clear
        label.adjustsFontSizeToFitWidth = true
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.numberOfLines = 2
        return label
    }()
    
    let listSettingButton: UIButton = {
        let button = UIButton()
        button.tintColor = UIColor.white
        button.backgroundColor = UIColor.clear
        button.setTitleColor( UIColor.white, for: .normal)
        //        button.setTitle("  LIST", for: .normal)
        //        button.font = UIFont(name: "Poppins-Bold", size: 16)
        button.isUserInteractionEnabled = false
        //        button.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(listSettingButtonPressed)))
        button.addTarget(self, action: #selector(listSettingButtonPressed), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
        button.layer.cornerRadius = 2
        button.layer.masksToBounds = true
        return button
        
    }()
    
    @objc func listSettingButtonPressed(){
        
        if currentDisplayList?.creatorUID != Auth.auth().currentUser?.uid {
            return
        } else {
            self.delegate?.didTapListSetting()
        }
    }
    
    
    
    let listShareButton: UIButton = {
        let button = UIButton()
        button.tintColor = UIColor.white
        button.backgroundColor = UIColor.clear
        button.setTitleColor( UIColor.white, for: .normal)
        
        //        button.setTitle("  LIST", for: .normal)
        //        button.font = UIFont(name: "Poppins-Bold", size: 16)
        button.isUserInteractionEnabled = false
        //        button.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(listShareButtonPressed)))
        
        button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
        button.addTarget(self, action: #selector(listShareButtonPressed), for: .touchUpInside)
        return button
    }()
    
    @objc func listShareButtonPressed(){
        
    }
    
    let listFollowEditButton: UIButton = {
        let button = UIButton()
        button.tintColor = UIColor.white
        button.backgroundColor = UIColor.clear
        button.setTitleColor(UIColor.white, for: .normal)
        
        //        button.textColor = UIColor.white
        //        button.setTitle("  LIST", for: .normal)
        //        button.font = UIFont(name: "Poppins-Bold", size: 16)
        button.isUserInteractionEnabled = true
        //        button.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(listEditButtonPressed)))
        button.contentMode = .scaleAspectFit

        button.addTarget(self, action: #selector(listEditButtonPressed), for: .touchUpInside)
        return button
    }()
    
    @objc func listEditButtonPressed(){
        if listFollowEditButton.tag == 0 {
            // EDIT LIST
            self.delegate?.didTapEditList()
        } else {
            self.handleFollowingList()
        }
    }

    var userProfileImageWidthConstraint: NSLayoutConstraint? = nil

    var listDetailViewHeightConst: CGFloat = 180

    override init(frame: CGRect) {
        super.init(frame:frame)
        backgroundColor = UIColor.white
        print("    Init LOAD | List Header")
        addSubview(heroBackgroundImageView)
        heroBackgroundImageView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 285)
        
        
        // SETUP LIST DETAIL VIEW
        addSubview(listDetailView)
        listDetailView.backgroundColor = UIColor.white
        listDetailView.anchor(top: heroBackgroundImageView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: -20, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        listDetailView.layer.borderColor = UIColor.lightGray.cgColor
        listDetailView.layer.borderWidth = 0.5
        listDetailView.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.15, x: 0, y: 0, blur: 3, spread: 0)
        listDetailViewHeight = listDetailView.heightAnchor.constraint(equalToConstant: 150)
        listDetailViewHeight?.isActive = true
        
        
        let userProfileView = UIView()
        addSubview(userProfileView)
        userProfileView.anchor(top: listDetailView.topAnchor, left: listDetailView.leftAnchor, bottom: nil, right: listDetailView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 55)
        
        
        addSubview(userProfileImageView)
        userProfileImageView.anchor(top: nil, left: userProfileView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 5, paddingRight: 0, width: 40, height: 40)
        userProfileImageView.centerYAnchor.constraint(equalTo: userProfileView.centerYAnchor).isActive = true
        userProfileImageView.layer.cornerRadius = 35/2
        userProfileImageView.layer.masksToBounds = true
//        userProfileImageWidthConstraint = userProfileImageView.widthAnchor.constraint(equalToConstant: 35)
        userProfileImageWidthConstraint?.isActive = true
        userProfileImageView.isUserInteractionEnabled = true
        userProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapUserImage)))
        
        
        let followContainer = UIView()
        addSubview(followContainer)
        followContainer.anchor(top: userProfileImageView.topAnchor, left: nil, bottom: userProfileView.bottomAnchor, right: userProfileView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        
        addSubview(listFollowEditButton)
        listFollowEditButton.anchor(top: followContainer.topAnchor, left: nil, bottom: nil, right: followContainer.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        listFollowEditButton.sizeToFit()

//        addSubview(emojiArray)
//        listFollowEditButton.anchor(top: followContainer.topAnchor, left: followContainer.leftAnchor, bottom: nil, right: followContainer.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//
//        emojiArray.alignment = .left
//        emojiArray.emojiFontSize = 15
//        emojiArray.delegate = self
//        //        emojiArray.backgroundColor = UIColor.yellow
//        refreshEmojiArray()
        
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: nil, left: userProfileImageView.rightAnchor, bottom: nil, right: followContainer.leftAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        usernameLabel.centerYAnchor.constraint(equalTo: userProfileImageView.centerYAnchor).isActive = true
        usernameLabel.isUserInteractionEnabled = true
        let usernameTapGesture = UITapGestureRecognizer(target: self, action: #selector(usernameTap))
        usernameLabel.addGestureRecognizer(usernameTapGesture)
        usernameLabel.sizeToFit()

        
        let listAdditionalView = UIView()
        addSubview(listAdditionalView)
        listAdditionalView.anchor(top: userProfileView.bottomAnchor, left: listDetailView.leftAnchor, bottom: listDetailView.bottomAnchor, right: listDetailView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        
        addSubview(listDetailDivider)
        listDetailDivider.backgroundColor = UIColor.lightGray
        listDetailDivider.anchor(top: nil, left: listAdditionalView.leftAnchor, bottom: nil, right: listAdditionalView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        listDetailDivider.centerYAnchor.constraint(equalTo: listAdditionalView.centerYAnchor).isActive = true

        let listCaptionContainer = UIView()
        addSubview(listCaptionContainer)
        listCaptionContainer.anchor(top: listAdditionalView.topAnchor, left: listAdditionalView.leftAnchor, bottom: listDetailDivider.topAnchor, right: listAdditionalView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        addSubview(listSummaryLabel)
        listSummaryLabel.anchor(top: listCaptionContainer.topAnchor, left: listCaptionContainer.leftAnchor, bottom: listCaptionContainer.bottomAnchor, right: listCaptionContainer.rightAnchor, paddingTop: 5, paddingLeft: 15, paddingBottom: 5, paddingRight: 15, width: 0, height: 0)
        listSummaryLabel.isUserInteractionEnabled = true
        listSummaryLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapDescLabel)))
        
        
        let listActionBar = UIView()
        addSubview(listActionBar)
        listActionBar.anchor(top: listDetailDivider.bottomAnchor, left: listDetailView.leftAnchor, bottom: listDetailView.bottomAnchor, right: listDetailView.rightAnchor, paddingTop: 5, paddingLeft: 15, paddingBottom: 5, paddingRight: 15, width: 0, height: 0)


//        addSubview(listShareButton)
//        listShareButton.anchor(top: listActionBar.topAnchor, left: nil, bottom: listActionBar.bottomAnchor, right: tempNavBarButton.leftAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
//        listShareButton.sizeToFit()
        
        
        addSubview(postCountLabel)
        postCountLabel.anchor(top: nil, left: listActionBar.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        postCountLabel.centerYAnchor.constraint(equalTo: listActionBar.centerYAnchor).isActive = true

        addSubview(followerCountLabel)
        followerCountLabel.anchor(top: nil, left: postCountLabel.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 2, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        followerCountLabel.centerYAnchor.constraint(equalTo: listActionBar.centerYAnchor).isActive = true

        followerCountLabel.isUserInteractionEnabled = true
        followerCountLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapFollowerCount)))

        // Nav Bar Buttons
        let tempNavBarButton = NavBarMapButton.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        tempNavBarButton.tintColor = UIColor.ianLegitColor()
        tempNavBarButton.layer.borderWidth = 1
        tempNavBarButton.layer.borderColor = UIColor.ianLegitColor().cgColor
        tempNavBarButton.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        tempNavBarButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        tempNavBarButton.addTarget(self, action: #selector(toggleMapFunction), for: .touchUpInside)
        
        addSubview(tempNavBarButton)
        tempNavBarButton.anchor(top: listActionBar.topAnchor, left: nil, bottom: listActionBar.bottomAnchor, right: listActionBar.rightAnchor, paddingTop: 3, paddingLeft: 5, paddingBottom: 3, paddingRight: 0, width: 0, height: 0)
//        tempNavBarButton.centerYAnchor.constraint(equalTo: listActionBar.centerYAnchor).isActive = true

        tempNavBarButton.sizeToFit()
        
        // SETUP LIST NAME
        
        addSubview(listNameLabel)
        listNameLabel.anchor(top: nil, left: listDetailView.leftAnchor, bottom: listDetailView.topAnchor, right: listDetailView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 0, height: 0)
        listNameLabel.heightAnchor.constraint(lessThanOrEqualToConstant: 120).isActive = true
        
        addSubview(listSettingButton)
        listSettingButton.anchor(top: nil, left: listDetailView.leftAnchor, bottom: listNameLabel.topAnchor, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 5, paddingRight: 0, width: 0, height: 25)
        //        listSettingButton.centerYAnchor.constraint(equalTo: userProfileImageView.centerYAnchor).isActive = true
        listSettingButton.sizeToFit()
        setupListSettingButton()

        
        
        // LIST SEARCH OPTIONS
        let listSearchView = UIView()
        addSubview(listSearchView)
        
        listSearchView.anchor(top: listDetailView.bottomAnchor, left: listDetailView.leftAnchor, bottom: nil, right: listDetailView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 35)
        

        let screenWidth = UIScreen.main.bounds.width * 0.5

        setupEmojiCollectionView()
        addSubview(emojiCollectionView)
        emojiCollectionView.anchor(top: listSearchView.topAnchor, left: nil, bottom: listSearchView.bottomAnchor, right: listSearchView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: screenWidth, height: 0)
        
        
        setupSearchBar()
        addSubview(searchBar)
        searchBar.anchor(top: listSearchView.topAnchor, left: listSearchView.leftAnchor, bottom: listSearchView.bottomAnchor, right: emojiCollectionView.leftAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 2, paddingRight: 5, width: 0, height: 0)
        
        
        
    // ADDITIONAL LIST OPTIONS
        let segmentView = UIView()
        addSubview(segmentView)
        segmentView.anchor(top: listSearchView.bottomAnchor, left: listDetailView.leftAnchor, bottom: nil, right: listDetailView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)

        
//        addSubview(listSortButton)
//        listSortButton.anchor(top: nil, left: listFormatView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
//        listSortButton.centerYAnchor.constraint(equalTo: listFormatView.centerYAnchor).isActive = true
//
//        addSubview(listButton)
//        listButton.anchor(top: nil, left: listSortButton.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 20, width: 30, height: 30)
//        listButton.centerYAnchor.constraint(equalTo: listFormatView.centerYAnchor).isActive = true
//
//        addSubview(gridButton)
//        gridButton.anchor(top: nil, left: listButton.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 30, height: 30)
//        gridButton.centerYAnchor.constraint(equalTo: listFormatView.centerYAnchor).isActive = true

        
        // SEGMENT VIEW

        addSubview(formatButton)
        formatButton.anchor(top: segmentView.topAnchor, left: nil, bottom: segmentView.bottomAnchor, right: segmentView.rightAnchor, paddingTop: 1, paddingLeft: 3, paddingBottom: 1, paddingRight: 3, width: 35, height: 35)
//        formatButton.widthAnchor.constraint(equalTo: formatButton.heightAnchor, multiplier: 1).isActive = true
        //        formatButton.layer.cornerRadius = formatButton.frame.width/2
        formatButton.layer.masksToBounds = true
        
        setupSegment()
        
        addSubview(headerSortSegment)
        headerSortSegment.anchor(top: segmentView.topAnchor, left: segmentView.leftAnchor, bottom: segmentView.bottomAnchor, right: formatButton.leftAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 3, paddingRight: 5, width: 0, height: 0)
        
        
        let segmentWidth = (self.frame.width - 50 - 10 - 20) / CGFloat(headerSortSegment.numberOfSegments)
        buttonBar.backgroundColor = UIColor.ianLegitColor()
        
        addSubview(buttonBar)
        buttonBar.anchor(top: nil, left: nil, bottom: headerSortSegment.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: segmentWidth, height: 5)
        buttonBar.leftAnchor.constraint(lessThanOrEqualTo: headerSortSegment.leftAnchor).isActive = true
        buttonBar.rightAnchor.constraint(lessThanOrEqualTo: headerSortSegment.rightAnchor).isActive = true
        buttonBarPosition = buttonBar.leftAnchor.constraint(equalTo: headerSortSegment.leftAnchor, constant: 0)
        self.underlineSegment(segment: sortOptions.firstIndex(of: selectedSort)!)


        



        
//        setupAddTagCollectionView()
//        addSubview(addTagCollectionView)
//        addTagCollectionView.anchor(top: listFormatView.topAnchor, left: listSortButton.rightAnchor, bottom: listFormatView.bottomAnchor, right: gridButton.leftAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)

        
        
        
//        addSubview(filterButton)
//        filterButton.anchor(top: nil, left: nil, bottom: nil, right: gridButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 30, height: 30)
//        filterButton.centerYAnchor.constraint(equalTo: listSortView.centerYAnchor).isActive = true

//        setupSegment()
//        addSubview(headerSortSegment)
//        headerSortSegment.anchor(top: listSortView.topAnchor, left: listSortView.leftAnchor, bottom: listSortView.bottomAnchor, right: searchBar.leftAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
//
//
//        let segmentWidth = (self.frame.width - 50 - 100) / CGFloat(sortOptions.count)
//        buttonBar.backgroundColor = UIColor.ianLegitColor()
//
//        addSubview(buttonBar)
//        buttonBar.anchor(top: headerSortSegment.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: segmentWidth, height: 5)
//        buttonBar.leftAnchor.constraint(lessThanOrEqualTo: headerSortSegment.leftAnchor).isActive = true
//        buttonBar.rightAnchor.constraint(lessThanOrEqualTo: headerSortSegment.rightAnchor).isActive = true
//        buttonBarPosition = buttonBar.leftAnchor.constraint(equalTo: headerSortSegment.leftAnchor, constant: 0)
//        print("    Success LOAD | List Header")
        
        print("    FINISH Init LOAD | List Header")


    }
    
// EMOJI COLLECTION VIEW
    
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
    
    
    
    @objc func toggleMapFunction(){
        self.delegate?.toggleMapFunction()
    }
    
    @objc func tapDescLabel(){
        if currentDisplayList?.creatorUID == Auth.auth().currentUser?.uid {
            self.listSettingButtonPressed()
        } else {
            return
        }
    }
    
    @objc func didTapUserImage(){
        guard let user = self.displayUser else {return}
        self.delegate?.didTapUser(user: user)
    }
    
    @objc func didTapFollowerCount(){
        guard let list = self.currentDisplayList else {return}
        self.delegate?.displayListFollowingUsers(list: list, following: true)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupListSettingButton() {
        
        var listString = NSMutableAttributedString()
        
        if currentDisplayList?.creatorUID == Auth.auth().currentUser?.uid {
            // CURRENT USER - ENABLE SETTINGS
            let listSettingTitle = NSAttributedString(string: "  Options", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 12)])
            listString.append(listSettingTitle)
            
            let inputImage = #imageLiteral(resourceName: "settings_white").resizeImageWith(newSize: CGSize(width: 15, height: 15)).withRenderingMode(.alwaysTemplate)
//            let inputImage = #imageLiteral(resourceName: "settings_white").withRenderingMode(.alwaysTemplate).resizeImageWith(newSize: <#T##CGSize#>)

            listSettingButton.setImage(inputImage, for: .normal)
            
            listSettingButton.tintColor = UIColor.white
            listSettingButton.backgroundColor = UIColor.ianLegitColor()
            listSettingButton.setAttributedTitle(listString, for: .normal)
            listSettingButton.isUserInteractionEnabled = true
            listSettingButton.addTarget(self, action: #selector(listSettingButtonPressed), for: .touchUpInside)

        }
        else
        {
            // CURRENT USER - ENABLE SETTINGS
            
            let listSettingTitle = NSAttributedString(string: "  List", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 16)])
            listString.append(listSettingTitle)
            
            let inputImage = #imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate)
            listSettingButton.setImage(inputImage, for: .normal)
            
            listSettingButton.tintColor = UIColor.white
            listSettingButton.backgroundColor = UIColor.clear
            listSettingButton.setAttributedTitle(listString, for: .normal)
            listSettingButton.isUserInteractionEnabled = false
        }
        
    }
    
    func setupActionButtons(){
        
        // LIST SHARE BUTTON
        var shareButtonColor = UIColor.lightGray
        var shareButtonString = NSMutableAttributedString()
        let inputImage = #imageLiteral(resourceName: "IanShareImage").withRenderingMode(.alwaysTemplate)
        listShareButton.setImage(inputImage, for: .normal)
        let shareTitle = NSAttributedString(string: "  SHARE", attributes: [NSAttributedString.Key.foregroundColor: shareButtonColor, NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 12)])
        shareButtonString.append(shareTitle)
        
        listShareButton.tintColor = shareButtonColor
        //        listShareButton.textColor = shareButtonColor
        //        listShareButton.setTitleColor(shareButtonColor, for: .normal)
        
        listShareButton.backgroundColor = UIColor.clear
        //        listShareButton.seta = shareButtonString
        listShareButton.setAttributedTitle(shareButtonString, for: .normal)
        listShareButton.isUserInteractionEnabled = true
        
        
        var listString = NSMutableAttributedString()
        
        if currentDisplayList?.creatorUID == Auth.auth().currentUser?.uid {
            
            let inputImage = #imageLiteral(resourceName: "settings_white").resizeImageWith(newSize: CGSize(width: 20, height: 20)).withRenderingMode(.alwaysTemplate)
            listFollowEditButton.setImage(inputImage, for: .normal)
            let listSettingTitle = NSAttributedString(string: " EDIT LIST", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 14)])
            listString.append(listSettingTitle)
            listFollowEditButton.tintColor = UIColor.lightGray
            //            listFollowEditButton.setTitleColor(UIColor.lightGray, for: .normal)
            
            listFollowEditButton.backgroundColor = UIColor.clear
            listFollowEditButton.setAttributedTitle(listString, for: .normal)
            //            listFollowEditButton.setAttributedTitle(listString, for: .normal)
            listFollowEditButton.isUserInteractionEnabled = true
            listFollowEditButton.tag = 0
        }
        else
        {
            let isFollowing = CurrentUser.followedLists.contains(where: {$0.id == currentDisplayList?.id})
            let followEditColor = isFollowing ? UIColor.ianLegitColor() : UIColor.ianGrayColor()
            let followEditText = isFollowing ? "  FOLLOWING" : "  FOLLOW"
            
            // NOT CURRENT USER - GOLLOW
            let image1Attachment = NSTextAttachment()
            let inputImage = !isFollowing ? #imageLiteral(resourceName: "photo_upload_plus"): #imageLiteral(resourceName: "photo_upload_check")
            let tempImage = inputImage.resizeImageWith(newSize: CGSize(width: 20, height: 20)).withRenderingMode(.alwaysOriginal)
            
            listFollowEditButton.setImage(inputImage, for: .normal)

            let listSettingTitle = NSAttributedString(string: followEditText, attributes: [NSAttributedString.Key.foregroundColor: followEditColor, NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 14)])
            listString.append(listSettingTitle)
            listFollowEditButton.tintColor = followEditColor
            //            listFollowEditButton.textColor = followEditColor
            listFollowEditButton.setTitleColor(followEditColor, for: .normal)
            
            listFollowEditButton.backgroundColor = isFollowing ? UIColor.clear : UIColor.clear
            listFollowEditButton.setAttributedTitle(listString, for: .normal)
            listFollowEditButton.isUserInteractionEnabled = true
            listFollowEditButton.tag = 1
        }
    }
    
    
    func setupSearchBar(){
        searchBar.layer.cornerRadius = 25/2
        searchBar.clipsToBounds = true
        searchBar.searchBarStyle = .minimal
        searchBar.barTintColor = UIColor.white
        //        defaultSearchBar.backgroundImage = UIImage()
        searchBar.layer.borderWidth = 0
        searchBar.placeholder = "Search"
        searchBar.delegate = self
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        if (searchText.count == 0) {
//            self.viewFilter?.filterCaption = nil
//            self.isFilteringText = nil
//            self.searchBar.endEditing(true)
////            self.refreshPostsForFilter()
//        } else {
//            filterContentForSearchText(searchBar.text!)
//        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.endEditing(true)
    }
    
    @objc func filterContentForSearchText(_ searchText: String) {
        // Filter List Table View
        if searchText.count > 0 {
            self.delegate?.searchListForText(text: searchText)
//            self.viewFilter?.filterCaption = searchText
            self.isFilteringText = searchText
        } else {
            self.delegate?.searchListForText(text: nil)
//            self.viewFilter?.filterCaption = nil
            self.isFilteringText = nil
        }
//        self.filterSortFetchedPosts()
        
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        self.delegate?.openFilter()
        return false
    }
    

    @objc func listFollowerTapped(){
        guard let list = self.currentDisplayList else {
            return
        }
        self.displayListFollowingUsers(list: list, following: false)
    }
    
    
    

    
//    func manageList(){
//        //        let sharePhotoListController = ManageListViewController()
//        //        navigationController?.pushViewController(sharePhotoListController, animated: true)
//
//        let tabListController = TabListViewController()
//        tabListController.enableAddListNavButton = false
//        tabListController.inputUserId = Auth.auth().currentUser?.uid
//        navigationController?.pushViewController(tabListController, animated: true)
//
//    }
//
//    func userSelected(){
//        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
//        userProfileController.displayUserId = displayUser?.uid
//        navigationController?.pushViewController(userProfileController, animated: true)
//    }
    
    
    var noCaptionFilterEmojiCounts: [String:Int] = [:]
    var noCaptionFilterLocationCounts: [String:Int] = [:]
    var noFilterAverageRating: Double = 0.0
    
    
    // Refresh Functions
    
    @objc func refreshAll() {
//        self.handleRefresh()
    }
    

    func clearAllPost(){
        self.fetchedPosts = []
        self.displayedPosts = []
    }
    
    
    func clearFilter(){
        self.viewFilter?.clearFilter()
        self.showFilterView()
    }
    
    
    // Search Delegates
    
    func clearCaptionSearch(){
        self.isFilteringText = nil
//        self.viewFilter?.filterCaption = nil
//        self.refreshPostsForFilter()
    }
    
    func filterCaptionSelected(searchedText: String?){
        print("Filter Caption Selected: \(searchedText)")
        self.viewFilter?.filterCaption = searchedText
        self.isFilteringText = searchedText
//        self.refreshPostsForFilter()
    }
    
    //    func userSelected(uid: String?){
    //
    //    }
    
    //    func locationSelected(googlePlaceId: String?, googlePlaceName: String?, googlePlaceLocation: CLLocation?, googlePlaceType: [String]?){
    //
    //    }
    
    
    
    
    

    
    
    
    
    
    
    // List Header Delegate
    @objc func didChangeToListView(){
        print("ListViewController | Change to List View")
        self.delegate?.didChangeToListView()
        self.postFormatInd = 1
//        self.imageCollectionView.reloadData()
        
        //        self.isListView = true
        //        collectionView.reloadData()
    }
    
    @objc func didChangeToGridView() {
        print("ListViewController | Change to Grid View")
        self.delegate?.didChangeToGridView()
        self.postFormatInd = 0
//        self.imageCollectionView.reloadData()
    }
    
    
    func didChangeToPostView() {
        //        self.isListView = false
        //        collectionView.reloadData()
    }
    
    
    func changePostFormat(formatInd: Int) {
        self.postFormatInd = formatInd
//        self.imageCollectionView.reloadData()
    }
    
    
    
    
    @objc func openFilter(){
        self.delegate?.openFilter()
//        let filterController = SearchFilterController()
//        filterController.delegate = self
//        filterController.searchFilter = self.viewFilter
//        self.navigationController?.pushViewController(filterController, animated: true)
    }
    
    // Search Delegates
    func filterControllerSelected(filter: Filter?) {
//        self.viewFilter = filter
//        self.searchBar.text = filter?.filterCaption
//        self.refreshPostsForFilter()
    }
    

    
    

    
    
    func displaySelectedEmoji(emoji: String, emojitag: String) {
        
        var emojiPostCount = String(self.noCaptionFilterEmojiCounts[emoji] ?? 0)
        
        emojiDetailLabel.text = "   " + emoji + " " + emojitag + " - \(emojiPostCount) Posts   "
        emojiDetailLabel.sizeToFit()
        emojiDetailLabel.isHidden = false
    }

    
    func displayPostSocialUsers(post: Post, following: Bool) {
        print("Display Vote Users| Following: ",following)
        self.delegate?.displayPostSocialUsers(post: post, following: following)
    }
    
    func displayPostSocialLists(post: Post, following: Bool) {
        print("Display Lists| Following: ",following)
        self.delegate?.displayPostSocialLists(post: post, following: following)
    }
    
    func displayListFollowingUsers(list: List, following: Bool) {
        print("Display Users| Following: ",list.id)
        self.delegate?.displayListFollowingUsers(list: list, following: following)
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
