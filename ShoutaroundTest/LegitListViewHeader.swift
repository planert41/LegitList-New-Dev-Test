//
//  LegitListViewHeader.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/22/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit

import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth

protocol LegitListViewHeaderDelegate {
    func handleFollowingList()
    func headerSortSelected(sort: String)
    func didChangeToGridView()
    func didChangeToListView()
    func filterContentForSearchText(_ searchText: String)
    func handleRefresh()
    func handleFilter()
    func showSearchView()
    func hideSearchView()
    func filterSelected(filter: Filter)
    func goToUser(userId: String?)
    
    func toggleMapFunction()
    func displayListFollowingUsers(list: List, following: Bool)
    func didTapListSetting()
    func didTapAddTag(addTag: String)

}

class LegitListViewHeader: UICollectionViewCell {
    var delegate: LegitListViewHeaderDelegate?

    var currentDisplayList: List? = nil {
        didSet{
            print(" ListHeader | DISPLAYING | \(currentDisplayList?.name) | \(currentDisplayList?.id) | \(currentDisplayList?.postIds?.count) Posts |List_ViewController")
            
            //            print("currentDisplayList | \(currentDisplayList?.name) | \(currentDisplayList?.id) | \(currentDisplayList?.postIds?.count)")
            // CLEAR SEARCH BAR
            self.clearCaptionSearch()
            self.updateListLabels()
            self.setupListFollowButton()
            self.fetchUser()
            
            if currentDisplayList?.heroImage != nil {
                self.heroBackgroundImageView.image = currentDisplayList?.heroImage
            } else if let url = currentDisplayList?.heroImageUrl {
                if url != "" {
                    self.heroBackgroundImageView.loadImage(urlString: url)
                }
            }
            
            listOptionButton.isHidden = !(currentDisplayList?.creatorUID != Auth.auth().currentUser?.uid)

            
            // Setup AddTag Options
//            addTagOptions = []

        }
    }
    
    var heroImageUrl: String? {
        didSet {
            if let url = heroImageUrl {
                if url != "" {
                    self.heroBackgroundImageView.loadImage(urlString: url)
                }
            }
        }
    }
    
    func fetchUser() {
        if let userId = self.currentDisplayList?.creatorUID {
            Database.fetchUserWithUID(uid: userId) { (user) in
                self.displayUser = user
            }
        }
    }
    
    var displayUser: User? = nil {
        didSet {
            if let url = self.displayUser?.profileImageUrl {
                self.userProfileImageView.loadImage(urlString: url)
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
    
    var viewFilter: Filter = Filter.init(defaultSort: defaultRecentSort){
            didSet {
    //            self.refreshNavSort()
                self.refreshSegmentValues()
                if viewFilter.isFiltering
                {
                    if let captionSearch = viewFilter.filterCaption {
                        var displaySearch = captionSearch
                        if displaySearch.isSingleEmoji {
                            // ADD EMOJI TRANSLATION
                            if let emojiTranslate = EmojiDictionary[displaySearch] {
                                displaySearch += " \(emojiTranslate.capitalizingFirstLetter())"
                            }
                        }
                        
                        fullSearchBar.text = displaySearch
                    } else if viewFilter.filterLocationName != nil {
                        fullSearchBar.text = viewFilter.filterLocationName
                    } else if let googleID = viewFilter.filterGoogleLocationID {
                        if let locationName = locationGoogleIdDictionary.key(forValue: googleID) {
                            fullSearchBar.text = locationName
                        } else {
                            fullSearchBar.text = googleID
                        }
                        
                    } else if viewFilter.filterLocationSummaryID != nil {
                        fullSearchBar.text = viewFilter.filterLocationSummaryID
                    } else {
                        fullSearchBar.text = ""
                    }
                    self.showHalfSearchBar()
                } else {
                    self.hideFullSearchBar()
                }
            }
        }
    var isFilteringText: String? = nil {
        didSet {
            if let filterText = isFilteringText{
                self.fullSearchBar.text = filterText
                print(" LV_Header | isFilteringText | \(filterText)")
            }
        }
    }
    
        func clearCaptionSearch(){
            self.isFilteringText = nil
        }
    
    var navSearchButtonFull: UIButton = TemplateObjects.NavSearchButton()

    
    let fullSearchBarView = UIView()
    var fullSearchBar = UISearchBar()
    
    var fullSearchBarWidth: NSLayoutConstraint?
    var halfSearchBarWidth: NSLayoutConstraint?
    lazy var fullSearchBarCancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.tintColor = UIColor.ianBlackColor()
        button.addTarget(self, action: #selector(tapCancelButton), for: .touchUpInside)
        return button
    }()
    
    @objc func tapCancelButton(){
        if halfSearchBarWidth!.isActive && (self.viewFilter.isFiltering ?? false) {
            self.delegate?.handleRefresh()
        } else {
            hideFullSearchBar()
        }
    }
    
    
// LIST HEADER VIEW
    
    let listHeaderView = UIView()
    
    let userProfileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        iv.layer.borderColor = UIColor.darkLegitColor().cgColor
        iv.layer.borderWidth = 0
        iv.layer.cornerRadius = 30/2
        iv.layer.masksToBounds = true
        return iv
    }()
    
    let listNameIcon: UIButton = {
        let button = UIButton()
        let listIcon = #imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate)
        button.setImage(listIcon, for: .normal)
        button.backgroundColor = UIColor.clear
        button.isUserInteractionEnabled = false
        button.tintColor = UIColor.ianBlackColor()
        return button
    }()
    
    let listNameLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(name: "Poppins-Bold", size: 20)
        label.textColor = UIColor.ianBlackColor()
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.clear
        label.adjustsFontSizeToFitWidth = true
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.numberOfLines = 2
        return label
    }()
    
    let listFollowerCountLabel: UILabel = {
        let label = UILabel()
        label.text = "No List Description"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.rgb(red: 48, green: 48, blue: 48)
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.clear
        label.adjustsFontSizeToFitWidth = false
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        return label
    }()
    
    let listPostCountLabel: UILabel = {
        let label = UILabel()
        label.text = "No List Description"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.rgb(red: 48, green: 48, blue: 48)
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.clear
        label.adjustsFontSizeToFitWidth = false
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
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
        button.addTarget(self, action: #selector(didTapFollowEditButton), for: .touchUpInside)
        return button
    }()
    
    @objc func handleFollowingList(){
        self.delegate?.handleFollowingList()
    }
    
    
    // ACTION BAR
    let actionBarView = UIView()
    
    var navSearchButton: UIButton = TemplateObjects.NavSearchButton()

    
    let listShareButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.clear
        let shareIcon = #imageLiteral(resourceName: "IanShareImage").withRenderingMode(.alwaysTemplate)
        button.setImage(shareIcon, for: .normal)
        button.setTitleColor( UIColor.ianBlackColor(), for: .normal)
        button.setTitle("  Share", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.tintColor = UIColor.ianBlackColor()
        button.isUserInteractionEnabled = true
        button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
        button.addTarget(self, action: #selector(listShareButtonPressed), for: .touchUpInside)
        return button
    }()
    
    @objc func listShareButtonPressed(){
        
    }
    
    let listOptionButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.clear
        let icon = #imageLiteral(resourceName: "settings_gear").withRenderingMode(.alwaysTemplate)
        button.setImage(icon, for: .normal)
        button.setTitleColor( UIColor.ianBlackColor(), for: .normal)
        button.setTitle("  Options", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.tintColor = UIColor.ianBlackColor()
        button.isUserInteractionEnabled = true
        button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
        button.addTarget(self, action: #selector(listOptionButtonPressed), for: .touchUpInside)
        return button
    }()
    
    @objc func listOptionButtonPressed(){
        
    }
    
    let listMapButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.clear
        let icon = #imageLiteral(resourceName: "map_nav").withRenderingMode(.alwaysTemplate)
        button.setImage(icon, for: .normal)
        button.setTitleColor( UIColor.ianBlackColor(), for: .normal)
        button.setTitle(" Map", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.tintColor = UIColor.ianBlackColor()
        button.isUserInteractionEnabled = true
        button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
        return button
    }()
    
//    var listMapButton: UIButton = TemplateObjects.NavBarMapButton()

    
// SORT VIEW
    let sortView = UIView()
    var sortSegmentControl = UISegmentedControl()
    var sortDictionary: [String: String] = [
        sortNearest: "📍 NEARBY",
        sortNew: "⏰ LATEST",
        sortTrending: "🔥 TRENDING"
    ]
    
    lazy var formatButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage((postFormatInd == 0 ? #imageLiteral(resourceName: "grid_button") : #imageLiteral(resourceName: "postview")).withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.ianBlackColor()
        button.addTarget(self, action: #selector(toggleView), for: .touchUpInside)
        return button
    }()
    
    var postFormatInd: Int = 0 {
        didSet{
            setupFormatButton()
            print(" postFormatInd | \(postFormatInd) | ListHeader")
        }
    }
    
    func setupFormatButton(){
        let image = (self.postFormatInd == 0) ? #imageLiteral(resourceName: "grid_button").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "card_format").withRenderingMode(.alwaysOriginal)
        self.formatButton.setImage(image, for: .normal)
        
        let text = (self.postFormatInd == 0) ? " Grid View ": " Card View"
        self.formatButton.setTitle(text, for: .normal)
    }
    
    
    // 0 Grid View
    // 1 List View
    // 2 Full View
    
    @objc func toggleView(){
        // 0 = Grid
        // 1 = List
        
        if (postFormatInd == 0) {
            self.didChangeToListView()
        } else if (postFormatInd == 1) {
            self.didChangeToGridView()
        }
    }
    
        func didChangeToListView(){
            print("ListViewController | Change to List View")
            self.delegate?.didChangeToListView()
            self.postFormatInd = 1
    //        self.imageCollectionView.reloadData()
            
            //        self.isListView = true
            //        collectionView.reloadData()
        }
        
        func didChangeToGridView() {
            print("ListViewController | Change to Grid View")
            self.delegate?.didChangeToGridView()
            self.postFormatInd = 0
    //        self.imageCollectionView.reloadData()
        }

    
// EMOJI
    
    var displayedEmojis: [String] = [] {
        didSet {
            print("LegitHomeHeader | \(displayedEmojis.count) Emojis")
            self.emojiCollectionView.reloadData()
        }
    }
    
    var listDefaultEmojis = mealEmojisSelect
    let addTagId = "addTagId"
    
    let emojiCollectionView: UICollectionView = {
        let uploadEmojiList = UICollectionViewFlowLayout()
        uploadEmojiList.estimatedItemSize = CGSize(width: 30, height: 30)
        uploadEmojiList.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        uploadEmojiList.scrollDirection = .horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadEmojiList)
        cv.layer.borderWidth = 0
        cv.backgroundColor = UIColor.white
        return cv
    }()
    
    // MARK: - INIT

    
    override init(frame: CGRect) {
        super.init(frame:frame)
        print("    Init LOAD | List Header")

        backgroundColor = UIColor.ianWhiteColor()
        
        addSubview(heroBackgroundImageView)
        heroBackgroundImageView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 180)
        
        addSubview(listHeaderView)
        listHeaderView.anchor(top: nil, left: heroBackgroundImageView.leftAnchor, bottom: heroBackgroundImageView.bottomAnchor, right: heroBackgroundImageView.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 40, paddingRight: 8, width: 0, height: 75)
        listHeaderView.backgroundColor = UIColor.ianWhiteColor()
        
        listHeaderView.layer.applySketchShadow(color: UIColor(red: 0, green: 0, blue: 0, alpha: 1), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
        
    // LIST NAME HEADER
        let listNameContainer = UIView()
        addSubview(listNameContainer)
        listNameContainer.anchor(top: listHeaderView.topAnchor, left: listHeaderView.leftAnchor, bottom: nil, right: listHeaderView.rightAnchor, paddingTop: 12, paddingLeft: 24, paddingBottom: 0, paddingRight: 24, width: 0, height: 35)
        
        
        listNameContainer.addSubview(listNameIcon)
        listNameIcon.anchor(top: nil, left: listNameContainer.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        listNameIcon.centerYAnchor.constraint(equalTo: listNameContainer.centerYAnchor).isActive = true
        
        listNameContainer.addSubview(userProfileImageView)
        userProfileImageView.anchor(top: nil, left: nil, bottom: nil, right: listNameContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 30, height: 30)
        userProfileImageView.centerYAnchor.constraint(equalTo: listNameContainer.centerYAnchor).isActive = true
        userProfileImageView.isUserInteractionEnabled = true
        userProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapUser)))

        listNameContainer.addSubview(listNameLabel)
        listNameLabel.anchor(top: nil, left: listNameIcon.rightAnchor, bottom: nil, right: userProfileImageView.leftAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        listNameLabel.centerYAnchor.constraint(equalTo: listNameContainer.centerYAnchor).isActive = true
        listNameLabel.topAnchor.constraint(lessThanOrEqualTo: listNameContainer.topAnchor).isActive = true
        listNameLabel.bottomAnchor.constraint(lessThanOrEqualTo: listNameContainer.bottomAnchor).isActive = true

    // LIST SOCIAL DETAILS
        let listSocialContainer = UIView()
        addSubview(listSocialContainer)
        listSocialContainer.anchor(top: listNameContainer.bottomAnchor, left: listNameContainer.leftAnchor, bottom: listHeaderView.bottomAnchor, right: listNameContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 12, paddingRight: 0, width: 0, height: 0)

        
        listSocialContainer.addSubview(listFollowerCountLabel)
        listFollowerCountLabel.anchor(top: listSocialContainer.topAnchor, left: listSocialContainer.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        listFollowerCountLabel.sizeToFit()
        
        listSocialContainer.addSubview(listPostCountLabel)
        listPostCountLabel.anchor(top: listSocialContainer.topAnchor, left: listSocialContainer.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 100, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
//        listPostCountLabel.rightAnchor.constraint(lessThanOrEqualTo: listFollowButton.leftAnchor).isActive = true
        listPostCountLabel.sizeToFit()
        
        
//        listSocialContainer.addSubview(listOptionButton)
//        listOptionButton.anchor(top: nil, left: nil, bottom: nil, right: listSocialContainer.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 90, height: 30)
//        listOptionButton.centerYAnchor.constraint(equalTo: listSocialContainer.centerYAnchor).isActive = true
//        listOptionButton.addTarget(self, action: #selector(didTapOptionButton), for: .touchUpInside)
//        listOptionButton.isHidden = true
        
        
    // ACTION BAR
        addSubview(actionBarView)
        actionBarView.backgroundColor = UIColor.ianWhiteColor()
        actionBarView.anchor(top: heroBackgroundImageView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 60)
        
        actionBarView.addSubview(navSearchButton)
        navSearchButton.anchor(top: nil, left: actionBarView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 30, height: 30)
        navSearchButton.centerYAnchor.constraint(equalTo: actionBarView.centerYAnchor).isActive = true
        navSearchButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapSearchButton)))
    
        
        actionBarView.addSubview(listFollowButton)
        listFollowButton.anchor(top: nil, left: nil, bottom: nil, right: actionBarView.rightAnchor, paddingTop: 4, paddingLeft: 8, paddingBottom: 4, paddingRight: 15, width: 90, height: 30)
        listFollowButton.centerYAnchor.constraint(equalTo: actionBarView.centerYAnchor).isActive = true

        listFollowButton.sizeToFit()

        actionBarView.addSubview(listMapButton)
        listMapButton.anchor(top: nil, left: nil, bottom: nil, right: listFollowButton.leftAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 10, width: 70, height: 30)
        listMapButton.centerYAnchor.constraint(equalTo: actionBarView.centerYAnchor).isActive = true
        listMapButton.addTarget(self, action: #selector(didTapMapButton), for: .touchUpInside)
        
        
        setupEmojiCollectionView()
        actionBarView.addSubview(emojiCollectionView)
        emojiCollectionView.anchor(top: nil, left: navSearchButton.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 1, paddingRight: 15, width: 160, height: 30)
        emojiCollectionView.rightAnchor.constraint(lessThanOrEqualTo: listMapButton.leftAnchor, constant: -10).isActive = true
        emojiCollectionView.centerYAnchor.constraint(equalTo: actionBarView.centerYAnchor).isActive = true
        // LOADS IN DEFAULT EMOJIS
        emojiCollectionView.reloadData()
        
//        actionBarView.addSubview(listShareButton)
//        listShareButton.anchor(top: nil, left: navSearchButton.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 75, height: 30)
//        listShareButton.centerYAnchor.constraint(equalTo: actionBarView.centerYAnchor).isActive = true

        
        

                
        
        
        
// SEARCH BAR VIEW
        
        actionBarView.addSubview(fullSearchBarView)
        fullSearchBarView.anchor(top: navSearchButton.topAnchor, left: navSearchButton.leftAnchor, bottom: navSearchButton.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        fullSearchBarWidth = fullSearchBarView.rightAnchor.constraint(equalTo: actionBarView.rightAnchor, constant: -15)
        halfSearchBarWidth = fullSearchBarView.rightAnchor.constraint(equalTo: listFollowButton.leftAnchor, constant: -10)
        halfSearchBarWidth?.isActive = true
        fullSearchBarView.layer.borderColor = UIColor.ianBlackColor().cgColor
        fullSearchBarView.layer.borderWidth = 1
        fullSearchBarView.backgroundColor = UIColor.white
        
        
        fullSearchBarView.addSubview(fullSearchBarCancelButton)
        fullSearchBarCancelButton.anchor(top: nil, left: nil, bottom: nil, right: fullSearchBarView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 20, height: 20)
        fullSearchBarCancelButton.centerYAnchor.constraint(equalTo: fullSearchBarView.centerYAnchor).isActive = true
        
        setupSearchBar()

        
        fullSearchBarView.addSubview(fullSearchBar)
        fullSearchBar.anchor(top: fullSearchBarView.topAnchor, left: fullSearchBarView.leftAnchor, bottom: fullSearchBarView.bottomAnchor, right: fullSearchBarCancelButton.leftAnchor, paddingTop: 3, paddingLeft: 10, paddingBottom: 3, paddingRight: 5, width: 0, height: 0)
        
        
        fullSearchBarView.addSubview(navSearchButtonFull)
        navSearchButtonFull.layer.borderWidth = 0
        navSearchButtonFull.anchor(top: fullSearchBarView.topAnchor, left: fullSearchBarView.leftAnchor, bottom: fullSearchBarView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 30, height: 30)
        
        
        fullSearchBarView.alpha = 0
        
        
        let bottomDiv = UIView()
        addSubview(bottomDiv)
        bottomDiv.anchor(top: actionBarView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 2)
        bottomDiv.backgroundColor = UIColor.rgb(red: 221, green: 221, blue: 221)
        
        
        
        
// SORT VIEW
        addSubview(sortView)
        sortView.anchor(top: bottomDiv.topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        
        setupFormatButton()
        sortView.addSubview(formatButton)
        formatButton.anchor(top: nil, left: nil, bottom: nil, right: sortView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: 0, height: 30)
        formatButton.centerYAnchor.constraint(equalTo: sortView.centerYAnchor).isActive = true
        formatButton.sizeToFit()
        
        setupSegmentControl()
        addSubview(sortSegmentControl)
        sortSegmentControl.anchor(top: nil, left: sortView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        sortSegmentControl.rightAnchor.constraint(lessThanOrEqualTo: formatButton.leftAnchor).isActive = true
        sortSegmentControl.centerYAnchor.constraint(equalTo: sortView.centerYAnchor).isActive = true

        // Do any additional setup after loading the view.
    }
    
    @objc func didTapFollowEditButton(){
        if self.listFollowButton.titleLabel?.text == "Options"
        {
            self.didTapOptionButton()
        }
        else
        {
            self.delegate?.handleFollowingList()
        }
    }
    
    @objc func didTapUser(){
        guard let userId = displayUser?.uid else {return}
        self.delegate?.goToUser(userId: userId)
    }

    
    func didTapOptionButton(){
        if currentDisplayList?.creatorUID != Auth.auth().currentUser?.uid {
            return
        } else {
            self.delegate?.didTapListSetting()
        }
    }
    
    func updateListLabels(){
        self.listNameLabel.text = self.currentDisplayList?.name
                
        if let followerCount = (self.currentDisplayList?.followerCount) {
            listFollowerCountLabel.text = "\(followerCount) Followers"
        }
        
        if let postCount = self.currentDisplayList?.postIds?.count {
            listPostCountLabel.text = "\(postCount) Posts"
        }
        
    }
    
    func setupListFollowButton() {
        
        guard let listId = self.currentDisplayList?.id else {return}
        
        if (currentDisplayList?.creatorUID == Auth.auth().currentUser?.uid)
        {
            listFollowButton.setTitle("Options", for: .normal)
            listFollowButton.setTitleColor(UIColor.ianBlackColor(), for: .normal)
            listFollowButton.layer.borderColor = UIColor.ianBlackColor().cgColor
            listFollowButton.layer.borderWidth = 1
            let icon = #imageLiteral(resourceName: "settings_gear").withRenderingMode(.alwaysTemplate)
            listFollowButton.imageView?.contentMode = .scaleAspectFill
            listFollowButton.setImage(icon, for: .normal)
            listFollowButton.backgroundColor = UIColor.white
            listFollowButton.tintColor = UIColor.ianBlackColor()
            listFollowButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)

        }
        else if CurrentUser.followedListIds.contains(listId){
            listFollowButton.setTitle("Following", for: .normal)
            listFollowButton.setTitleColor(UIColor.ianLegitColor(), for: .normal)
            listFollowButton.layer.borderColor = UIColor.ianLegitColor().cgColor
            listFollowButton.backgroundColor = UIColor.white
            listFollowButton.setImage(UIImage(), for: .normal)
            listFollowButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        } else {
            listFollowButton.setTitle("Follow", for: .normal)
            listFollowButton.backgroundColor = UIColor.ianLegitColor()
            listFollowButton.setTitleColor(UIColor.white, for: .normal)
            listFollowButton.layer.borderColor = UIColor.white.cgColor
            listFollowButton.setImage(UIImage(), for: .normal)
            listFollowButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        }
    }
    
    @objc func didTapMapButton() {
        self.delegate?.toggleMapFunction()
    }
    
    @objc func showListFollowingUser() {
        guard let list = self.currentDisplayList else {return}
        self.delegate?.displayListFollowingUsers(list: list, following: true)
    }
    
    
    @objc func didTapSearchButton() {
        if self.fullSearchBarView.alpha == 0 {
            self.showFullSearchBar()
        } else {
            self.hideFullSearchBar()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension LegitListViewHeader: UISearchBarDelegate {
    
    func setupSegmentControl() {
        sortSegmentControl = UISegmentedControl(items: HeaderSortOptions)
        sortSegmentControl.addTarget(self, action: #selector(selectSort), for: .valueChanged)
        sortSegmentControl.backgroundColor = UIColor.clear

        if #available(iOS 13.0, *) {
            sortSegmentControl.selectedSegmentTintColor = UIColor.ianBlackColor()
        }

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        sortSegmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianGrayColor(), NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
        sortSegmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)
        
        if let curIndex = HeaderSortOptions.firstIndex(of: (self.viewFilter.filterSort!))
        {
            sortSegmentControl.selectedSegmentIndex = curIndex
            self.refreshSegmentValues()
        }
    }

    @objc func selectSort(sender: UISegmentedControl) {
        var newSort = HeaderSortOptions[sender.selectedSegmentIndex]
        print(" LegitHomeHeader | toggleSort | \(newSort)")
        self.viewFilter.filterSort = newSort
        let newTitle = sortDictionary[newSort]
        self.refreshSegmentValues()
//        self.sortSegmentControl.setTitle(newTitle, forSegmentAt: sender.selectedSegmentIndex)
        self.delegate?.headerSortSelected(sort: newSort)
    }

func refreshSegmentValues() {
    for (index, sortOptions) in HeaderSortOptions.enumerated()
    {
        if sortOptions == self.viewFilter.filterSort
        {
            let newTitle = sortDictionary[sortOptions]
            self.sortSegmentControl.setTitle(newTitle, forSegmentAt: index)
        } else {
            self.sortSegmentControl.setTitle(sortOptions, forSegmentAt: index)
        }
    }
}
 
    
    // MARK: - Search Bar Delegates

    
        func setupSearchBar() {
    //        setup.searchBarStyle = .prominent
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
//            UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(attributes, for: .normal)
            
            
            let searchImage = #imageLiteral(resourceName: "search_selected").withRenderingMode(.alwaysTemplate)
            fullSearchBar.setImage(UIImage(), for: .search, state: .normal)
            
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
                    
                    //                s.layer.cornerRadius = 25/2
                    //                s.layer.borderWidth = 1
                    //                s.layer.borderColor = UIColor.gray.cgColor
                }
            }

        }
        
        
        func showHalfSearchBar() {

            
            UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.transitionCrossDissolve, animations:
                {
                    self.fullSearchBarWidth?.isActive = false
                    self.halfSearchBarWidth?.isActive = true
                    self.fullSearchBarView.updateConstraints()
                    self.fullSearchBarView.alpha = 1
            }
                , completion: { (finished: Bool) in
            })
        }
    
    
    func showFullSearchBar(){


        UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.transitionCrossDissolve, animations:
                {
                    self.fullSearchBarWidth?.isActive = true
                    self.halfSearchBarWidth?.isActive = false
                    self.fullSearchBarView.updateConstraints()
                    self.fullSearchBarView.alpha = 1
            }
                , completion: { (finished: Bool) in
            })
        
        self.fullSearchBar.becomeFirstResponder()
        self.delegate?.showSearchView()
    }
    
    func hideFullSearchBar() {
        
        UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.transitionCrossDissolve, animations:
            {
                if (self.viewFilter.isFiltering ?? false) {
                    // SHOW HALF SEARCH BAR
                    self.fullSearchBarWidth?.isActive = false
                    self.halfSearchBarWidth?.isActive = true
                    self.fullSearchBarView.alpha = 1
                } else {
                    self.fullSearchBarView.alpha = 0
                }
        }
            , completion: { (finished: Bool) in
        })
        self.fullSearchBar.resignFirstResponder()
        self.fullSearchBarView.updateConstraints()
        self.delegate?.hideSearchView()

    }
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.hideFullSearchBar()
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.delegate?.filterContentForSearchText(searchText)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.showFullSearchBar()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let text = searchBar.text ?? ""
        self.delegate?.filterContentForSearchText(text)
        self.handleFilter()

    }
    
    func handleFilter(){
        self.viewFilter.filterCaption = fullSearchBar.text ?? ""
        self.delegate?.filterSelected(filter: self.viewFilter)
    }
    
}

extension LegitListViewHeader: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func setupEmojiCollectionView(){
        emojiCollectionView.backgroundColor = UIColor.clear
        emojiCollectionView.register(HomeFilterBarCell.self, forCellWithReuseIdentifier: addTagId)
        emojiCollectionView.delegate = self
        emojiCollectionView.dataSource = self
        emojiCollectionView.showsHorizontalScrollIndicator = false
        emojiCollectionView.isScrollEnabled = true
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displayedEmojis.count == 0 ? listDefaultEmojis.count : displayedEmojis.count

    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: addTagId, for: indexPath) as! HomeFilterBarCell

        let option = (displayedEmojis.count == 0) ? listDefaultEmojis[indexPath.item].lowercased() : displayedEmojis[indexPath.item].lowercased()
        var isSelected = self.viewFilter.filterCaption?.contains(option) ?? false
        cell.uploadLocations.text = option
        cell.backgroundColor = isSelected ? UIColor.ianOrangeColor() : UIColor.clear
        return cell
    }
    
    
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    //        let emoji = displayedEmojis[indexPath.item].lowercased()
            let emoji = (displayedEmojis.count == 0) ? listDefaultEmojis[indexPath.item].lowercased() : displayedEmojis[indexPath.item].lowercased()
            print("\(emoji) SELECTED")

            self.delegate?.didTapAddTag(addTag: emoji)
        }
    
}
