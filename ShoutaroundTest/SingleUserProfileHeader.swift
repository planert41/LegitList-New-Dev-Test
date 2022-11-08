//
//  SingleUserProfileHeader.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/14/20.
//  Copyright © 2020 Wei Zou Ang. All rights reserved.
//

import UIKit

import FirebaseAuth
import FirebaseDatabase

protocol SingleUserProfileHeaderDelegate {
    func didChangeToPostView()
    func didChangeToGridView()
    func headerSortSelected(sort: String)
    func userSettings()
    func selectUserFollowers()
    func selectUserFollowing()
    func selectUserLists()
    func didSignOut()
    func editUser()
    func tapProfileImage(image: UIImage?)
    func toggleMapFunction()
    func didTapUserStatus()
    func didTapUserEmojiStatus()
    func didTapList(list: List?)
    func didUpdateUserInfo(info: String?)
    func editUserInfo()
    
    func filterCaptionSelected(searchedText: String?)
    func didTapSearchButton()
    func didTapAddTag(addTag: String)
    func didRemoveTag(tag: String)
    func didRemoveLocationFilter(location: String)
    func didRemoveRatingFilter(rating: String)
    func didTapCell(tag: String)
    func handleRefresh()
    func didActivateSearchBar()
    func didTapCreateNewList()
    
    func displayAllLists()
    func didTapFilterLegit()
    
    func openInbox()
    func messageUser()
    func extBlockUser(user:User)
    func extCreateNewPhoto()

}

class SingleUserProfileHeader: UICollectionViewCell {

    var delegate: SingleUserProfileHeaderDelegate?

    // USER
    var user: User? {
        didSet{
            self.loadUser()
        }
    }
    
    func loadUser() {
        guard let profileImageUrl = user?.profileImageUrl else {return}
        profileImageView.loadImage(urlString: profileImageUrl)
//            checkUserFollowing()
        setupActionButtons()
        setupSocialLabels()
        setupUserStatus()
        setupUserInfo()
        if self.listSummary.currentUserUid != user?.uid && !(user?.isBlocked ?? false) {
            self.listSummary.currentUserUid = user?.uid
        }
        refreshListView()
        self.addNewListButton.isHidden = !(user?.uid == Auth.auth().currentUser?.uid)
        self.emojiSummary.displayUser = user
        
//        var defaultTitle = "Your Most Popular Emoji Tags. But No Emojis in Your Posts Yet."
        var defaultTitle = "Start Posting To Track Your Most Popular Emoji Tags!"

        if user?.uid != Auth.auth().currentUser?.uid {
            defaultTitle = "No Emoji Tags Yet"
        }
        noEmojiSummaryButton.setTitle(defaultTitle, for: .normal)
        noEmojiSummaryButton.sizeToFit()
    }


    var viewFilter: Filter = Filter.init(defaultSort: defaultRecentSort){
        didSet {
            self.emojiSummary.viewFilter = viewFilter
            self.searchBar.isFilteringLegit = viewFilter.filterLegit
            self.setupSocialLabels()
            print("SingleProfileHeader | ViewFilter Updated | Refresh Segment | \(self.viewFilter.filterSort) | CUR: \(self.sortSegmentControl.selectedSegmentIndex)")
//            self.refreshButton.isHidden = !viewFilter.isFiltering
//            guard let sort = self.viewFilter.filterSort else {return}
//            self.currentSort = sort
//            self.refreshSort(sender: self.sortSegmentControl)
//            self.refreshSegmentValues()
        }
    }
    
    
//    // 0 For Default Header Sort Options, 1 for Location Sort Options
//    var sortOptionsInd: Int = 0 {
//        didSet{
//            if sortOptionsInd == 0 {
//                sortOptions = HeaderSortOptions
//            } else if sortOptionsInd == 1 {
//                sortOptions = LocationSortOptions
//            } else {
//                sortOptions = HeaderSortOptions
//            }
//        }
//    }
//
    var sortOptions: [String] = HeaderSortOptions {
        didSet{
//            self.updateSegments()
        }
    }
    
    // PROFILE VIEW
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "username"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    let followingLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let userBadgeLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .left
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let followersLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let listLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let postsLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let locationLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        label.font = UIFont(name: "Poppins-Bold", size: 13)
        label.textAlignment = .left
        label.textColor = UIColor.gray
        label.text = ""
        return label
    }()
        
    var profileCountStackView = UIStackView()

    

    lazy var editProfileFollowButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("", for: .normal)
        button.titleLabel?.font =  UIFont(name: "Poppins-Bold", size: 12)
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 5
        button.backgroundColor = UIColor.white
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.addTarget(self, action: #selector(handleEditProfileOrFollow), for: .touchUpInside)
        return button
    }()
    
    lazy var messageInboxButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("", for: .normal)
        button.titleLabel?.font =  UIFont(name: "Poppins-Bold", size: 12)
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 5
        button.backgroundColor = UIColor.white
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.addTarget(self, action: #selector(handleMessageOrInbox), for: .touchUpInside)
        return button
    }()
    
    let inboxCountLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 15, height: 15))
        label.layer.borderColor = UIColor.clear.cgColor
        label.layer.borderWidth = 0
        label.layer.cornerRadius = label.bounds.size.height / 2
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = UIFont(name: "Poppins-Bold", size: 10)
        label.textColor = .white
        label.backgroundColor = UIColor.clear
//        label.text = "80"
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleMessageOrInbox)))
        return label
    }()
    
    let userInfoTextView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 12)
        tv.textContainer.maximumNumberOfLines = 8
        tv.textContainer.lineBreakMode = .byTruncatingTail
        tv.isScrollEnabled = false
        tv.isEditable = true
        return tv
    }()
    
    let userStatusLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(font: .avenirNextDemiBold, size: 13)
        label.textColor = UIColor.ianBlackColor()
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.clear
        label.adjustsFontSizeToFitWidth = true
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.numberOfLines = 2
        return label
    }()
    
    lazy var userStatusButton: UIButton = {
        let button = UIButton(type: .system)
//        var image = #imageLiteral(resourceName: "shoutaround")
//        button.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 25)
        button.titleLabel?.textAlignment = .center
        button.setTitle("😐", for: .normal)
        button.alpha = 0.6
        button.addTarget(self, action: #selector(didTapUserStatusButton), for: .touchUpInside)
        return button
    }()

    @objc func didTapUserStatusButton(){
        self.delegate?.didTapUserEmojiStatus()
    }
    
    let userStatusTextView = UITextView()
    var userStatusPlaceholder = "Tap To Add User Description"
    
        
    var fullSearchBar = UISearchBar()
    var sortSegmentControl: UISegmentedControl = UISegmentedControl(items: HeaderSortOptions)
    var navGridToggleButton: UIButton = TemplateObjects.gridFormatButton()
    var navSearchButton: UIButton = TemplateObjects.NavSearchButton()
    
    lazy var navMapButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
//        let icon = #imageLiteral(resourceName: "google_color").withRenderingMode(.alwaysOriginal)
//        let icon = #imageLiteral(resourceName: "location_color").withRenderingMode(.alwaysOriginal)
        let icon = #imageLiteral(resourceName: "map").withRenderingMode(.alwaysTemplate)

        button.setTitle(" Map Posts", for: .normal)
        button.setImage(icon, for: .normal)
        button.layer.borderColor = UIColor.ianLegitColor().cgColor
        button.layer.borderWidth = 1
        button.clipsToBounds = true
        button.contentHorizontalAlignment = .center
        button.backgroundColor = UIColor.clear //UIColor.ianWhiteColor()
//        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        button.tintColor = UIColor.ianLegitColor()
        button.titleLabel?.font =  UIFont(font: .avenirNextBold, size: 10)
        button.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        button.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12)
        button.imageView?.contentMode = .scaleAspectFit

        return button
    }()
    
    
    let refreshButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "refresh_blue"), for: .normal)
//        button.setImage(#imageLiteral(resourceName: "refresh_white"), for: .normal)
        button.addTarget(self, action: #selector(handleRefresh), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()
    
    
    var isGridView = true {
        didSet {
            if isGridView && postFormatInd != 0 {
                postFormatInd = 0
            } else if !isGridView && postFormatInd == 0 {
                postFormatInd = 1
            }
            searchBar.isGridView = self.isGridView
        }
    }
    var postFormatInd: Int = gridFormat {
        didSet{
            setupFormatButton()
            print(" postFormatInd | \(postFormatInd) | ListHeader")
        }
    }
    
    
    func setupFormatButton(){
        isGridView = (postFormatInd == 0)
        var image = (isGridView) ? #imageLiteral(resourceName: "grid") : #imageLiteral(resourceName: "listFormat")
        self.navGridToggleButton.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
//        self.navGridToggleButton.setTitle(isGridView ? "Grid " : "List ", for: .normal)
    }

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
        print("Header ListViewController | Change to List View")
        self.delegate?.didChangeToPostView()
        self.postFormatInd = 1
//        self.imageCollectionView.reloadData()
        
        //        self.isListView = true
        //        collectionView.reloadData()
    }
    
    func didChangeToGridView() {
        print("Header ListViewController | Change to Grid View")
        self.delegate?.didChangeToGridView()
        self.postFormatInd = 0
//        self.imageCollectionView.reloadData()
    }
    

    var hideListView: NSLayoutConstraint?
    var showListView: NSLayoutConstraint?
    var fullListViewSummaryHeight = 140.0
    var keyboardTap = UITapGestureRecognizer()

// USER LISTS
    
    let listSummary = ListSummaryCollectionViewController()

    lazy var listHeaderLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Created Lists"
        ul.font = UIFont(name: "Poppins-Bold", size: 25)
        ul.textColor = UIColor.ianBlackColor()
        ul.textAlignment = NSTextAlignment.left
        ul.numberOfLines = 1
        ul.backgroundColor = UIColor.white
        return ul
    }()
    
    lazy var postHeaderLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Created Lists"
        ul.font = UIFont(name: "Poppins-Bold", size: 25)
        ul.textColor = UIColor.ianBlackColor()
        ul.textAlignment = NSTextAlignment.left
        ul.numberOfLines = 1
        ul.backgroundColor = UIColor.clear
        return ul
    }()
    
    let addNewListButton: UIButton = {
        let button = UIButton()
        button.setTitle("New List", for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Regular", size: 12)!
        button.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        button.setImage(#imageLiteral(resourceName: "add_list").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.ianLegitColor()
        button.imageView?.contentMode = .scaleAspectFit
//        button.addTarget(self, action: #selector(initAddList), for: .touchUpInside)
        button.addTarget(self, action: #selector(displayAllLists), for: .touchUpInside)
        button.semanticContentAttribute = .forceLeftToRight
        return button
    }()
    
    
    @objc func initAddList(){
        self.delegate?.didTapCreateNewList()
    }
    
    lazy var sortListButton: UIButton = {
        let button = UIButton(type: .system)
//        var image = #imageLiteral(resourceName: "sort_bar_new")
        var image = #imageLiteral(resourceName: "sort_arrow_new")
        button.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.darkGray
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 10)
        button.setTitleColor(UIColor.darkGray, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.semanticContentAttribute = .forceRightToLeft

        button.addTarget(self, action: #selector(didSortList), for: .touchUpInside)
        return button
    }()
    
    func refreshSortListButton() {
        var sortText = listSummary.sortListByPostCount ? "Posts " : "Recent "
        self.sortListButton.setTitle(sortText, for: .normal)
    }
    
    @objc func didSortList() {
        listSummary.sortListByPostCount = !listSummary.sortListByPostCount
        listSummary.showBookmarkFirst = false //!listSummary.sortListByPostCount
        self.refreshSortListButton()
    }
    
    let emojiSummary = EmojiSummaryCV()
    var userEmojiCounts:[String: Int] = [:] {
        didSet {
            if userEmojiCounts.count == 0 {
                self.noEmojiSummaryButton.isHidden = false
                self.bringSubviewToFront(self.noEmojiSummaryButton)
            } else {
                self.noEmojiSummaryButton.isHidden = true
                self.bringSubviewToFront(self.emojiSummary)
            }
            self.emojiSummary.displayedEmojisCounts = self.userEmojiCounts
        }
    }
    
    let noEmojiSummaryButton: UIButton = {
        let button = UIButton()
        button.setTitle("", for: .normal)
        button.titleLabel?.font = UIFont.italicSystemFont(ofSize: 12)
        button.setTitleColor(UIColor.darkGray, for: .normal)
//        button.imageView?.contentMode = .scaleAspectFit
//        button.addTarget(self, action: #selector(initAddList), for: .touchUpInside)
        button.addTarget(self, action: #selector(noEmojiSummaryButtonTapped), for: .touchUpInside)
//        button.semanticContentAttribute = .forceLeftToRight
        button.titleLabel?.textAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
//        button.backgroundColor  = .yellow
        return button
    }()
    
    @objc func noEmojiSummaryButtonTapped() {
        print(noEmojiSummaryButtonTapped)
        self.delegate?.extCreateNewPhoto()
    }
    
    var displayPostCount: Int = 0 {
        didSet {
            self.setupSocialLabels()
        }
    }
    
    // SEARCH BAR
    
    let searchBar = UserSearchBar()

    
    override init(frame: CGRect) {
        super.init(frame:frame)
        backgroundColor = UIColor.white

        let profileView = UIView()
        addSubview(profileView)
        profileView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 100)
        
//     PROFILE IMAGE
        profileView.addSubview(profileImageView)
        profileImageView.anchor(top: nil, left: profileView.leftAnchor, bottom: profileView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 0, width: 90, height: 90)
        profileImageView.centerYAnchor.constraint(equalTo: profileView.centerYAnchor).isActive = true
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapUserImage)))
        profileImageView.layer.cornerRadius = 90/2
        profileImageView.layer.masksToBounds = true
        profileImageView.layer.borderColor = UIColor.backgroundGrayColor().cgColor
        profileImageView.layer.borderWidth = 1

   
    // PROFILE COUNTS
        let profileCountView = UIView()
        addSubview(profileCountView)
        profileCountView.anchor(top: profileView.topAnchor, left: profileImageView.rightAnchor, bottom: profileView.bottomAnchor, right: profileView.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
//        profileCountView.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
//
//        profileCountStackView = UIStackView(arrangedSubviews: [postsLabel, listLabel, followingLabel, followersLabel])
        profileCountStackView = UIStackView(arrangedSubviews: [postsLabel, followersLabel, followingLabel])
        profileCountStackView.distribution = .fillEqually
        profileCountStackView.axis = .horizontal
        addSubview(profileCountStackView)
        profileCountStackView.anchor(top: profileCountView.topAnchor, left: profileCountView.leftAnchor, bottom: profileCountView.bottomAnchor, right: profileCountView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        profileCountStackView.centerYAnchor.constraint(equalTo: profileCountView.centerYAnchor).isActive = true
//        profileCountStackView.topAnchor.constraint(lessThanOrEqualTo: editProfileFollowButton.bottomAnchor, constant: 10).isActive = true

    // EMOJI
        let emojiView = UIView()
        addSubview(emojiView)
        emojiView.anchor(top: profileView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        emojiView.backgroundColor = UIColor.clear

        emojiView.addSubview(emojiSummary)
        emojiSummary.anchor(top: emojiView.topAnchor, left: emojiView.leftAnchor, bottom: emojiView.bottomAnchor, right: emojiView.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        emojiSummary.backgroundColor = UIColor.clear
        emojiSummary.centerYAnchor.constraint(equalTo: emojiView.centerYAnchor).isActive = true
        emojiSummary.showBadges = true
//        emojiSummary.showCity = true
        emojiSummary.delegate = self
        
        addSubview(noEmojiSummaryButton)
        noEmojiSummaryButton.anchor(top: emojiView.topAnchor, left: emojiView.leftAnchor, bottom: emojiView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        noEmojiSummaryButton.rightAnchor.constraint(lessThanOrEqualTo: emojiView.rightAnchor).isActive = true
        noEmojiSummaryButton.isHidden = true

        
        
    // USER PROFILE INFO
        addSubview(userInfoTextView)
        userInfoTextView.delegate = self
        userInfoTextView.anchor(top: emojiView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
    
        
     // PROFILE LOCATION
         addSubview(locationLabel)
        locationLabel.anchor(top: userInfoTextView.bottomAnchor, left: userInfoTextView.leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 4, paddingLeft: 4, paddingBottom: 4, paddingRight: 10, width: 0, height: 20)
         locationLabel.sizeToFit()
         locationLabel.backgroundColor = UIColor.clear

                
    // FOLLOW EDIT BUTTON
        let actionView = UIView()
        addSubview(actionView)
        actionView.anchor(top: locationLabel.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)

        let actionStackView = UIStackView(arrangedSubviews: [editProfileFollowButton, messageInboxButton])
        actionStackView.distribution = .fillEqually
        actionStackView.axis = .horizontal
        actionStackView.spacing = 10
        actionView.addSubview(actionStackView)
        actionStackView.anchor(top: actionView.topAnchor, left: actionView.leftAnchor, bottom: nil, right: actionView.rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 30)
        actionStackView.layer.applySketchShadow()
        actionStackView.backgroundColor = UIColor.clear
        
        messageInboxButton.addSubview(inboxCountLabel)
        inboxCountLabel.anchor(top: nil, left: nil, bottom: nil, right: messageInboxButton.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 50, width: 15, height: 15)
        inboxCountLabel.centerYAnchor.constraint(equalTo: messageInboxButton.centerYAnchor).isActive = true

        setupActionButtons()
//        actionView.addSubview(editProfileFollowButton)
//        editProfileFollowButton.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 200, height: 30)
//        editProfileFollowButton.anchor(top: nil, left: actionView.leftAnchor, bottom: nil, right: actionView.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 0, height: 30)

//        editProfileFollowButton.centerXAnchor.constraint(equalTo: actionView.centerXAnchor).isActive = true
//        editProfileFollowButton.centerYAnchor.constraint(equalTo: actionView.centerYAnchor).isActive = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(setupActionButtons), name: InboxController.newMsgNotificationName, object: nil)

        
        
// LIST VIEW
        let listView = UIView()
        addSubview(listView)
        listView.anchor(top: actionView.bottomAnchor, left: profileView.leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 0, height: 0)
        
        listView.addSubview(listHeaderLabel)
        listHeaderLabel.anchor(top: listView.topAnchor, left: listView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 20)
        listHeaderLabel.isUserInteractionEnabled = true
        listHeaderLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayAllLists)))
        
        listView.addSubview(sortListButton)
        sortListButton.anchor(top: nil, left: nil, bottom: nil, right: listView.rightAnchor, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        sortListButton.centerYAnchor.constraint(equalTo: listHeaderLabel.centerYAnchor).isActive = true
        sortListButton.isUserInteractionEnabled = true
        refreshSortListButton()

//        listView.addSubview(addNewListButton)
//        addNewListButton.anchor(top: nil, left: listHeaderLabel.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 18)
//        addNewListButton.centerYAnchor.constraint(equalTo: listHeaderLabel.centerYAnchor).isActive = true
//        addNewListButton.isUserInteractionEnabled = true
//        addNewListButton.addTarget(self, action: #selector(initAddList), for: .touchUpInside)

        
        
        addSubview(listSummary.view)
        listSummary.delegate = self
        listSummary.view.anchor(top: listHeaderLabel.bottomAnchor, left: listView.leftAnchor, bottom: listView.bottomAnchor, right: listView.rightAnchor, paddingTop: 8, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        hideListView = listSummary.view.heightAnchor.constraint(equalToConstant: 0)
        showListView = listSummary.view.heightAnchor.constraint(equalToConstant: CGFloat(fullListViewSummaryHeight))
        hideListView?.isActive = true
        listSummary.displayFollowedList = false
        listSummary.showBookmarkFirst = false
        

//        postHeaderLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: 10).isActive = true

//        statusView.layer.applySketchShadow(color: UIColor(red: 0, green: 0, blue: 0, alpha: 1), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)

        
        // KEYBOARD TAPS TO EXIT INPUT
//        self.keyboardTap = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

                
// BOTTOM DIV
        
        let bottomDiv = UIView()
        addSubview(bottomDiv)
        bottomDiv.anchor(top: listSummary.view.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 2)
//        bottomDiv.backgroundColor = UIColor.rgb(red: 221, green: 221, blue: 221)
        bottomDiv.backgroundColor = UIColor.rgb(red: 221, green: 221, blue: 221)

        bottomDiv.layer.applySketchShadow(color: UIColor(red: 0, green: 0, blue: 0, alpha: 1), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
        
        let bottomView = UIView()
        bottomView.backgroundColor = UIColor.backgroundGrayColor()
        addSubview(bottomView)
        bottomView.anchor(top: bottomDiv.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

        
        
    // POST HEADER COUNT
        let postCountHeaderView = UIView()
        addSubview(postCountHeaderView)
        postCountHeaderView.anchor(top: bottomView.topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
        postCountHeaderView.backgroundColor = UIColor.backgroundGrayColor()
        
        postCountHeaderView.addSubview(postHeaderLabel)
        postHeaderLabel.anchor(top: postCountHeaderView.topAnchor, left: postCountHeaderView.leftAnchor, bottom: postCountHeaderView.bottomAnchor, right: nil, paddingTop: 4, paddingLeft: 15, paddingBottom: 4, paddingRight: 15, width: 0, height: 0)
//        postHeaderLabel.centerYAnchor.constraint(equalTo: postCountHeaderView.centerYAnchor).isActive = true
        postHeaderLabel.sizeToFit()
        
        postCountHeaderView.addSubview(refreshButton)
        refreshButton.anchor(top: nil, left: postHeaderLabel.rightAnchor, bottom: nil, right: nil, paddingTop: 4, paddingLeft: 10, paddingBottom: 4, paddingRight: 15, width: 25, height: 25)
        refreshButton.isHidden = true

        postCountHeaderView.addSubview(navMapButton)
        navMapButton.anchor(top: nil, left: nil, bottom: nil, right: postCountHeaderView.rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 10, paddingRight: 10, width: 100, height: 30)
        navMapButton.centerYAnchor.constraint(equalTo: postCountHeaderView.centerYAnchor).isActive = true
        navMapButton.layer.cornerRadius = 30/2
        navMapButton.layer.masksToBounds = true
        navMapButton.addTarget(self, action: #selector(didTapMapButton), for: .touchUpInside)
        navMapButton.isHidden = true
        
        
//        postCountHeaderView.addSubview(navMapButton)
//        navMapButton.tintColor = UIColor.darkGray
//        navMapButton.setTitleColor(UIColor.ianBlackColor(), for: .normal)
////        navMapButton.setTitle(" Map ", for: .normal)
////        navMapButton.semanticContentAttribute  = .forceRightToLeft
//        navMapButton.anchor(top: nil, left: nil, bottom: nil, right: postCountHeaderView.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 15, width: 30, height: 30)
//        navMapButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapMapButton)))
//        navMapButton.centerYAnchor.constraint(equalTo: postCountHeaderView.centerYAnchor).isActive = true
//        navMapButton.setTitle("", for: .normal)
//        navMapButton.sizeToFit()
//        navMapButton.isHidden = false

//        setupnavGridToggleButton()
//        postCountHeaderView.addSubview(navGridToggleButton)
//        navGridToggleButton.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 0, height: 30)
//        navGridToggleButton.centerYAnchor.constraint(equalTo: postCountHeaderView.centerYAnchor).isActive = true
//        navGridToggleButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
    // SEARCH BAR
        let optionsView = UIView()
        addSubview(optionsView)
        optionsView.anchor(top: postCountHeaderView.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        optionsView.backgroundColor = UIColor.backgroundGrayColor()
        optionsView.addSubview(searchBar)
        searchBar.delegate = self
        searchBar.searchBarView.backgroundColor = UIColor.clear
        searchBar.alpha = 0.9
        searchBar.showEmoji = true
        searchBar.anchor(top: optionsView.topAnchor, left: optionsView.leftAnchor, bottom: optionsView.bottomAnchor, right: optionsView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        searchBar.navSearchButton.tintColor = UIColor.darkGray
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(newListEventRefresh), name:TabListViewController.refreshListNotificationName, object: nil)
        
    // USER STATUS
//        let statusView = UIView()
//        addSubview(statusView)
//        statusView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 10, width: 0, height: 60)
//        statusView.layer.cornerRadius = 5
//        statusView.layer.masksToBounds = true
//        statusView.backgroundColor = UIColor.clear
//        statusView.layer.applySketchShadow(color: UIColor(red: 0, green: 0, blue: 0, alpha: 1), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
//
//        statusView.addSubview(userStatusButton)
//        userStatusButton.anchor(top: nil, left: statusView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 30, height: 30)
//        userStatusButton.centerYAnchor.constraint(equalTo: statusView.centerYAnchor).isActive = true
//
//        setupUserStatus()
//        statusView.addSubview(userStatusTextView)
//        userStatusTextView.anchor(top: nil, left: userStatusButton.rightAnchor, bottom: nil, right: statusView.rightAnchor, paddingTop: 2, paddingLeft: 5, paddingBottom: 2, paddingRight: 0, width: 0, height: 0)
//        userStatusTextView.centerYAnchor.constraint(equalTo: userStatusButton.centerYAnchor).isActive = true
//        userStatusTextView.topAnchor.constraint(lessThanOrEqualTo: statusView.topAnchor, constant: 3).isActive = true
//        userStatusTextView.bottomAnchor.constraint(lessThanOrEqualTo: statusView.bottomAnchor, constant: 3).isActive = true


        
    // EMOJI
//        let emojiView = UIView()
//        addSubview(emojiView)
//        emojiView.anchor(top: nil, left: profileImageView.rightAnchor, bottom: profileView.bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
//        emojiView.backgroundColor = UIColor.clear
//
//        emojiView.addSubview(emojiSummary)
//        emojiSummary.anchor(top: emojiView.topAnchor, left: emojiView.leftAnchor, bottom: emojiView.bottomAnchor, right: emojiView.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
//        emojiSummary.backgroundColor = UIColor.clear
//        emojiSummary.centerYAnchor.constraint(equalTo: emojiView.centerYAnchor).isActive = true
//        emojiSummary.showBadges = true
//        emojiSummary.delegate = self
                    
        
    // USER NAME
//        let usernameView = UIView()
//        addSubview(usernameView)
//        usernameView.anchor(top: profileView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 25)
//
//        addSubview(usernameLabel)
//        usernameLabel.anchor(top: nil, left: profileImageView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        usernameLabel.centerYAnchor.constraint(equalTo: usernameView.centerYAnchor).isActive = true
//        usernameLabel.leftAnchor.constraint(lessThanOrEqualTo: leftAnchor, constant: 5).isActive = true
        
    
 
        
    // OPTIONS
//        let optionsView = UIView()
//        addSubview(optionsView)
//        optionsView.anchor(top: postCountHeaderView.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 40)
//        optionsView.backgroundColor = UIColor.backgroundGrayColor()
//
//        setupSegmentControl()
//        optionsView.addSubview(sortSegmentControl)
//        sortSegmentControl.anchor(top: nil, left: optionsView.leftAnchor, bottom: optionsView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
//

    }
    
    
    @objc func refreshListView() {
        var doShowListView = ((self.user?.listIds.count ?? 0 > 0))
        if doShowListView {
            self.doShowListView()
        } else {
            self.doHideListView()
        }
    }
    
    @objc func doShowListView() {
        self.hideListView?.isActive = false
        self.showListView?.isActive = true
    }
    
    @objc func doHideListView() {
        self.hideListView?.isActive = true
        self.showListView?.isActive = false
    }
    
    @objc func displayAllLists() {
        self.delegate?.displayAllLists()
    }

    @objc func newListEventRefresh(){
        // SORT BY RECENT
        self.loadUser()
        listSummary.sortListByPostCount = false
        listSummary.showBookmarkFirst = false
        self.refreshSortListButton()
    }
    
    
    @objc func didTapSearch(){
        self.delegate?.didTapSearchButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func checkUserFollowing() {
        // CHECK
        guard let userId = self.user?.uid else {return}
            if (user?.isFollowing)! && !CurrentUser.followingUids.contains(userId) {
                print("UserCheck | \(userId) | User Is Followed But Not In CurrentUser Following UID")
                self.user?.isFollowing = false
            } else if !(user?.isFollowing)! && CurrentUser.followingUids.contains(userId) {
                print("UserCheck | \(userId) | User NOT Followed But In CurrentUser Following UID")
                self.user?.isFollowing = true
            }
            
    }
    
    
    @objc fileprivate func setupActionButtons() {
        guard let currentLoggedInUserID = Auth.auth().currentUser?.uid else {return}
        guard let userId = user?.uid else {return}
        
        self.setupFollowStyle()

//        if currentLoggedInUserID == userId {
//            self.setupFollowStyle()
//        }else {
//            Database.checkIfFollowingUser(userId: currentLoggedInUserID, followingUserId: userId) { (following) in
//                print("\(currentLoggedInUserID) | \(userId) | Following: \(self.user?.isFollowing)")
//                if self.user?.isFollowing != following {
//                    self.user?.isFollowing = following
//                }
//                self.setupFollowStyle()
//            }
//        }
    }
    
    @objc func handleMessageOrInbox() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else {return}
        guard let userId = user?.uid else {return}
        
        if (currentLoggedInUserId == userId){
            self.delegate?.openInbox()
        } else {
            self.delegate?.messageUser()
        }
        
    }
    
    @objc func handleEditProfileOrFollow() {
        
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else {return}
        guard let userId = user?.uid else {return}
        
        
        if (currentLoggedInUserId == userId && self.editProfileFollowButton.titleLabel?.text == "Options"){
            self.delegate?.userSettings()
        } else if self.user?.isBlocked ?? false {
            if let user = user {
                self.delegate?.extBlockUser(user: user)
            }
        } else if self.editProfileFollowButton.titleLabel?.text == "Following" || self.editProfileFollowButton.titleLabel?.text == "Follow" {
            Database.handleFollowing(userUid: userId) { }
            guard let user = self.user else {return}
            var tempUser = user
            tempUser.isFollowing = !(tempUser.isFollowing)!
            tempUser.followersCount += (tempUser.isFollowing)! ? 1 : -1
            self.user = tempUser
            self.setupFollowStyle()
        }
    }
}

extension SingleUserProfileHeader: UITextViewDelegate, UITextFieldDelegate {
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if Auth.auth().currentUser?.uid == user?.uid {
            self.delegate?.editUserInfo()
        }
        
        return false
    }
    
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let existingLines = textView.text.components(separatedBy: CharacterSet.newlines)
        let newLines = text.components(separatedBy: CharacterSet.newlines)
        let linesAfterChange = existingLines.count + newLines.count - 1
        return linesAfterChange <= textView.textContainer.maximumNumberOfLines
    }
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text == userStatusPlaceholder {
            textField.text = nil
        }
        userStatusTextView.font =  UIFont(font: .avenirNextRegular, size: 12)
        userStatusTextView.font =  UIFont.systemFont(ofSize: 12)
        userStatusTextView.textColor = UIColor.ianBlackColor()
    }
    
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        textField.resignFirstResponder()
//        self.doneUserStatus()
//        return false
//    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if user?.description == "" && textView.text.count == 0 {
            print("User Info TextView Blank")
        } else {
            self.delegate?.didUpdateUserInfo(info: textView.text)
        }

    }

    
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView == userInfoTextView {
            if userInfoTextView.text == blankUserDesc {
                userInfoTextView.text = nil
            }
            userInfoTextView.font =  UIFont.systemFont(ofSize: 12)
            userInfoTextView.textColor = UIColor.ianBlackColor()
        }


    }
    
    func setupUserInfo() {

        usernameLabel.text = user?.username
        usernameLabel.sizeToFit()
        
        if Auth.auth().currentUser?.uid == user?.uid && user?.description == "" {
            self.userInfoTextView.text = blankUserDesc
            self.userInfoTextView.textColor = UIColor.lightGray
        } else {
            self.userInfoTextView.text = user?.description
            self.userInfoTextView.textColor = UIColor.black
        }
        self.userInfoTextView.sizeToFit()
        
        locationLabel.text = ""
        if let city = user?.userCity {
            if !(city.isEmptyOrWhitespace() ?? true) {
                locationLabel.text = user?.userCity
            }
        }
        locationLabel.sizeToFit()
        
        
    }
    
    func saveUserInfo() {
        guard let desc = userInfoTextView.text else {return}
        if (desc != blankUserDesc) && (desc != user?.description) {
            Database.updateUserDescription(userUid: CurrentUser.uid, description: desc)
        }
    }
    
}


extension SingleUserProfileHeader: UISearchBarDelegate, ListSummaryDelegate, EmojiSummaryCVDelegate, UserSearchBarDelegate {
    func didTapAddList() {
        print("didTapAddList")
        self.delegate?.didTapCreateNewList()
    }
    
    
    @objc func didTapMapButton() {
        self.delegate?.toggleMapFunction()
    }
    
    func didTapFilterLegit() {
        self.delegate?.didTapFilterLegit()
    }
    
    
    func didTapEmojiBackButton() {
        
    }
    
    func didTapEmojiButton() {
        
    }
    
    
    func didTapGridButton() {
        self.toggleView()
    }
    
    func filterContentForSearchText(searchText: String) {
        self.delegate?.filterCaptionSelected(searchedText: searchText)
    }
    
    func didTapSearchButton() {
        self.delegate?.didTapSearchButton()
    }
    
    func didTapAddTag(addTag: String) {
        self.delegate?.didTapAddTag(addTag: addTag)
    }
    
    func didRemoveTag(tag: String) {
        self.delegate?.didRemoveTag(tag: tag)
    }
    
    func didRemoveLocationFilter(location: String) {
        self.delegate?.didRemoveLocationFilter(location: location)
    }
    
    func didRemoveRatingFilter(rating: String) {
        self.delegate?.didRemoveRatingFilter(rating: rating)
    }
    
    func didTapCell(tag: String) {
        self.delegate?.didTapCell(tag: tag)
    }
    
    @objc func handleRefresh() {
        self.delegate?.handleRefresh()
    }
    
    func didActivateSearchBar() {
        self.delegate?.didActivateSearchBar()
    }
    
    
    func didTapEmoji(emoji: String) {
        self.delegate?.didTapAddTag(addTag: emoji)
    }
    
    func didTapList(list: List?) {
        self.delegate?.didTapList(list: list)
    }
    
    func didTapUser(user: User?) {
        
    }
    

    
    
    func setupUserStatus() {
        if (self.user?.status == nil || self.user?.status == "") && (self.user?.uid == Auth.auth().currentUser?.uid) {
            let text = NSMutableAttributedString(string: userStatusPlaceholder, attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray, NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBoldItalic, size: 12)])
            self.userStatusLabel.attributedText = text
            self.userStatusLabel.isUserInteractionEnabled = true
            
            self.userStatusTextView.attributedText = text
            
        } else {
            self.userStatusLabel.text = (self.user?.status ?? "")
            self.userStatusTextView.text = (self.user?.status ?? "")
            self.userStatusLabel.isUserInteractionEnabled = false
        }
        
        userStatusTextView.delegate = self
        userStatusTextView.textAlignment = .left
        userStatusTextView.isUserInteractionEnabled = (self.user?.uid == Auth.auth().currentUser?.uid)
        userStatusTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapUserStatus)))
        userStatusTextView.addCancelDoneOnKeyboardWithTarget(self, cancelAction: #selector(cancelUserStatus), doneAction: #selector(doneUserStatus), shouldShowPlaceholder: true)
        
        userStatusTextView.isEditable = (self.user?.uid == Auth.auth().currentUser?.uid)
        userStatusTextView.textContainer.maximumNumberOfLines = 2
        userStatusTextView.isScrollEnabled = false
        userStatusTextView.backgroundColor = UIColor.white
        userStatusTextView.textContainer.lineBreakMode = .byWordWrapping
        userStatusTextView.layer.cornerRadius = 5
        userStatusTextView.layer.masksToBounds = true
        userStatusTextView.backgroundColor = UIColor.clear
        
        if self.user?.emojiStatus == nil ||  self.user?.emojiStatus == "" {
            userStatusButton.setTitle("😐", for: .normal)
            userStatusButton.alpha = 0.6
            userStatusButton.sizeToFit()

        } else {
            userStatusButton.setTitle(self.user?.emojiStatus, for: .normal)
            userStatusButton.alpha = 1
            userStatusButton.sizeToFit()
        }
        
    }

//    func sizeOfString (string: String, constrainedToWidth width: Double, font: UIFont) -> CGSize {
//        return (string as NSString).boundingRectWithSize(CGSize(width: width, height: DBL_MAX),
//            options: NSStringDrawingOptions.UsesLineFragmentOrigin,
//            attributes: [NSFontAttributeName: font],
//            context: nil).size
//    }
//
//    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
//        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
//        var textWidth = textView.frame.inset(by: textView.textContainerInset).width
//        textWidth -= 2.0 * textView.textContainer.lineFragmentPadding;
//
//        let boundingRect = sizeOfString(newText, constrainedToWidth: Double(textWidth), font: textView.font!)
//        let numberOfLines = boundingRect.height / textView.font!.lineHeight;
//
//        return numberOfLines <= 2;
//    }
    
    @objc func cancelUserStatus(){
        print("cancelUserStatus | \(userStatusTextView.text)")
        self.userStatusTextView.resignFirstResponder()
        setupUserStatus()
    }
    
    @objc func doneUserStatus(){
        print("doneUserStatus | \(userStatusTextView.text)")
        self.updateUserStatus(newStatus: userStatusTextView.text)
        self.userStatusTextView.resignFirstResponder()
    }
    
    @objc func didTapUserStatus(){
        self.delegate?.didTapUserStatus()
//        userStatusTextView.becomeFirstResponder()
    }
    
    func updateUserStatus(newStatus: String?) {
        print("updateUserStatus | \(userStatusTextView.text)")
        guard let userUid = user?.uid else {return}
        if self.user?.status == userStatusTextView.text {return}
        self.user?.status = userStatusTextView.text
        Database.updateUserStatus(userUid: userUid, status: newStatus)
        
        setupUserStatus()
    }

//
//    @objc func keyboardWillShow(notification: NSNotification) {
//        if type(of: self.window?.rootViewController?.view) is SingleUserProfileViewController {
//            print("keyboardWillShow. Adding Keyboard Tap Gesture")
//            self.addGestureRecognizer(self.keyboardTap)
//        }
//    }
//
//    @objc func keyboardWillHide(notification: NSNotification){
//        if type(of: self.window?.rootViewController?.view) is SingleUserProfileViewController {
//            print("keyboardWillHide. Removing Keyboard Tap Gesture")
//            self.removeGestureRecognizer(self.keyboardTap)
//        }
//    }
//
//
//    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
////        userSearchBar.resignFirstResponder()
//        self.endEditing(true)
//    }

    func setupSearchBar() {
//        setup.searchBarStyle = .prominent
        fullSearchBar.searchBarStyle = .default
        fullSearchBar.isTranslucent = true
        fullSearchBar.tintColor = UIColor.ianBlackColor()
        fullSearchBar.placeholder = "Search food, locations, categories"
        fullSearchBar.delegate = self
        fullSearchBar.showsCancelButton = false
        fullSearchBar.sizeToFit()
        fullSearchBar.clipsToBounds = true
        fullSearchBar.backgroundImage = UIImage()
        fullSearchBar.backgroundColor = UIColor.clear

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
                    backgroundview.clipsToBounds = true
                    backgroundview.layer.backgroundColor = UIColor.clear.cgColor
                }
            }
        }

    }
    
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            self.delegate?.filterCaptionSelected(searchedText: searchText)
            print("textDidChange | ",searchText)
        }
        
        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            print("isFilteringText | \(searchBar.text)")
        }
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            let text = searchBar.text ?? ""
    //        self.delegate?.filterContentForSearchText(text)
            self.handleFilter()
            searchBar.resignFirstResponder()

        }
        
        func handleFilter(){
            if let searchText = fullSearchBar.text {
                if !searchText.isEmptyOrWhitespace() {
                    self.delegate?.didTapAddTag(addTag: searchText)
                    fullSearchBar.text = nil
                }
            }
        }
    
    
    
}





    


extension SingleUserProfileHeader {
    
    func setupnavGridToggleButton() {
        navGridToggleButton.tintColor = UIColor.gray
        navGridToggleButton.setTitleColor(UIColor.ianBlackColor(), for: .normal)
        navGridToggleButton.titleLabel?.font =  UIFont(font: .avenirNextBold, size: 12)
        navGridToggleButton.backgroundColor = UIColor.white
        navGridToggleButton.isUserInteractionEnabled = true
        navGridToggleButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleView)))
        navGridToggleButton.semanticContentAttribute  = .forceLeftToRight
        navGridToggleButton.layer.cornerRadius = 15
        navGridToggleButton.layer.masksToBounds = true
        navGridToggleButton.layer.borderColor = navGridToggleButton.tintColor.cgColor
        navGridToggleButton.layer.borderWidth = 0
        navGridToggleButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
        navGridToggleButton.backgroundColor = UIColor.clear
    }

    func setupSegmentControl(){
        
        sortSegmentControl.backgroundColor = UIColor.white
        sortSegmentControl.tintColor = UIColor.oldLegitColor()
        if #available(iOS 13.0, *) {
            sortSegmentControl.selectedSegmentTintColor = UIColor.mainBlue()
            sortSegmentControl.layer.borderColor = sortSegmentControl.selectedSegmentTintColor?.cgColor
//            sortSegmentControl.selectedSegmentTintColor = UIColor.ianBlackColor()
        }
        sortSegmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor()], for: .normal)
        sortSegmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianWhiteColor()], for: .selected)
        sortSegmentControl.selectedSegmentIndex = 0
        sortSegmentControl.addTarget(self, action: #selector(SingleUserProfileHeader.selectPostSort), for: .valueChanged)
        reloadSegmentControl()
    }
    
    @objc func selectPostSort(sender: UISegmentedControl) {
        let selectedSort = HeaderSortOptions[sender.selectedSegmentIndex]
        print("SingleUserViewHeader | selectPostSort | \(selectedSort) | \(sender.selectedSegmentIndex)")
        self.reloadSegmentControl()
        self.headerSortSelected()
    }
    
    func headerSortSelected(){
        let selectedSort = HeaderSortOptions[self.sortSegmentControl.selectedSegmentIndex]
        print("headerSortSelected | \(selectedSort)")
        self.delegate?.headerSortSelected(sort: selectedSort)

    }
    
    func reloadSegmentControl(){
        let selectedSort = HeaderSortOptions[self.sortSegmentControl.selectedSegmentIndex]
        let newTitle = headerSortDictionary[selectedSort]
        
        print("reloadSegmentControl | \(selectedSort) | CUR: \(self.sortSegmentControl.selectedSegmentIndex)")
//        self.sortSegmentControl.selectedSegmentIndex = selectedIndex

        for (index, sortOptions) in HeaderSortOptions.enumerated()
        {
            var isSelected = (index == self.sortSegmentControl.selectedSegmentIndex)
            var displayFilter = (isSelected) ? newTitle : sortOptions
            self.sortSegmentControl.setTitle(displayFilter, forSegmentAt: index)
            self.sortSegmentControl.setWidth((isSelected) ? 100 : 70, forSegmentAt: index)
        }
    }


    @objc func didTapUserImage(){
        self.delegate?.tapProfileImage(image: profileImageView.image)
    }

    
    
    fileprivate func setupFollowStyle(){
        
//        print("setupFollowStyle | Following: \(self.user?.isFollowing)")
        if Auth.auth().currentUser?.uid == user?.uid {
            // Edit Profile
            editProfileFollowButton.setTitle("Options", for: .normal)
            editProfileFollowButton.setTitleColor(UIColor.white, for: .normal)
            editProfileFollowButton.backgroundColor = UIColor.mainBlue()
            editProfileFollowButton.layer.borderColor = UIColor.clear.cgColor
            
            var unreadMessage = CurrentUser.unreadMessageCount > 0
            var msgColor = unreadMessage ? UIColor.ianLegitColor() : UIColor.ianBlackColor()
            var msgText = unreadMessage ? "Inbox (\(CurrentUser.unreadMessageCount))" : "Inbox"

            messageInboxButton.setTitle("Inbox", for: .normal)
            messageInboxButton.setTitleColor(msgColor, for: .normal)
            messageInboxButton.backgroundColor = UIColor.ianWhiteColor()
            messageInboxButton.layer.borderColor = msgColor.cgColor
            

            
            if CurrentUser.unreadMessageCount > 0 {
                inboxCountLabel.text = String(CurrentUser.unreadMessageCount)
                inboxCountLabel.tintColor = UIColor.ianLegitColor()
                inboxCountLabel.backgroundColor = UIColor.ianLegitColor()
                inboxCountLabel.isHidden = false
            } else {
                inboxCountLabel.isHidden = true
            }
            
        } else {
            if user?.isBlocked ?? false {
                editProfileFollowButton.setTitle("Blocked", for: .normal)
                editProfileFollowButton.setTitleColor(UIColor.ianWhiteColor(), for: .normal)
                editProfileFollowButton.layer.borderColor = UIColor.red.cgColor
                editProfileFollowButton.backgroundColor = UIColor.red
            } else {
                let followInd = user?.isFollowing ?? false
                editProfileFollowButton.setTitle(followInd ? "Following" : "Follow", for: .normal)
                editProfileFollowButton.setTitleColor(UIColor.ianWhiteColor(), for: .normal)
                editProfileFollowButton.layer.borderColor = (followInd ? UIColor.ianLegitColor() : UIColor.mainBlue()).cgColor
                editProfileFollowButton.backgroundColor = followInd ? UIColor.ianLegitColor() : UIColor.mainBlue()
            }

            messageInboxButton.setTitle("Message", for: .normal)
            messageInboxButton.setTitleColor(UIColor.ianBlackColor(), for: .normal)
            messageInboxButton.backgroundColor = UIColor.ianWhiteColor()
            messageInboxButton.layer.borderColor = UIColor.ianBlackColor().cgColor
            inboxCountLabel.isHidden = true

            self.setupSocialLabels()
        }
        
//        else if (user?.isFollowing)!
//        {
//            self.editProfileFollowButton.setTitle("Following", for: .normal)
//            self.editProfileFollowButton.setTitleColor(UIColor.ianWhiteColor(), for: .normal)
//            self.editProfileFollowButton.layer.borderColor = UIColor.ianLegitColor().cgColor
//            self.editProfileFollowButton.backgroundColor = UIColor.ianLegitColor()
//            self.setupSocialLabels()
//        }
//        else
//        {
////            self.editProfileFollowButton.setTitle("Follow", for: .normal)
////            self.editProfileFollowButton.backgroundColor = UIColor.ianLegitColor()
////            self.editProfileFollowButton.setTitleColor(UIColor.white, for: .normal)
////            self.editProfileFollowButton.layer.borderColor = UIColor.clear.cgColor
////            self.setupSocialLabels()
//
//            self.editProfileFollowButton.setTitle("Follow", for: .normal)
//            self.editProfileFollowButton.setTitleColor(UIColor.ianWhiteColor(), for: .normal)
//            self.editProfileFollowButton.layer.borderColor = UIColor.mainBlue().cgColor
//            self.editProfileFollowButton.backgroundColor = UIColor.mainBlue()
//            self.setupSocialLabels()
//        }
     
    }
    
    // SOCIAL LABELS
    
    func setupSocialLabels(){
        let postCount = user?.posts_created ?? 0
        let followingCount = user?.followingCount ?? 0
        let followerCount = user?.followersCount ?? 0
        let listCount = user?.lists_created ?? 0
        let voteCount = user?.votes_received ?? 0
        
        
        let socialLabelColor = UIColor.gray
        let socialMetricColor = UIColor.ianBlackColor()
        
        let socialMetricFont = UIFont(font: .arialRoundedMTBold, size: 20)
        let socialLabelFont = UIFont(font: .avenirMedium, size: 16)
        
        // Followers Label
        
        var attributedMetric = NSMutableAttributedString(string: "\(String(followerCount))", attributes: [NSAttributedString.Key.foregroundColor: socialMetricColor, NSAttributedString.Key.font: socialMetricFont])

        var attributedLabel = NSMutableAttributedString(string: "\n Followers", attributes: [NSAttributedString.Key.foregroundColor: socialLabelColor, NSAttributedString.Key.font: socialLabelFont])

        
        attributedMetric.append(attributedLabel)
        self.followersLabel.attributedText = attributedMetric
        self.followersLabel.sizeToFit()
        self.followersLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectFollowers)))
        self.followersLabel.isUserInteractionEnabled = true
        
        
        // Following Label
        
        attributedMetric = NSMutableAttributedString(string: "\(String(followingCount))", attributes: [NSAttributedString.Key.foregroundColor: socialMetricColor, NSAttributedString.Key.font: socialMetricFont])

        attributedLabel = NSMutableAttributedString(string: "\n Following", attributes: [NSAttributedString.Key.foregroundColor: socialLabelColor, NSAttributedString.Key.font: socialLabelFont])

        
        attributedMetric.append(attributedLabel)
        self.followingLabel.attributedText = attributedMetric
        self.followingLabel.sizeToFit()
        self.followingLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectFollowing)))
        self.followingLabel.isUserInteractionEnabled = true
        
        
        // List Count Label
        attributedMetric = NSMutableAttributedString(string: "\(String(listCount)) Lists", attributes: [NSAttributedString.Key.foregroundColor: socialMetricColor, NSAttributedString.Key.font: socialMetricFont])
        attributedLabel = NSMutableAttributedString(string: "\n Lists", attributes: [NSAttributedString.Key.foregroundColor: socialLabelColor, NSAttributedString.Key.font: socialLabelFont])
        attributedMetric.append(attributedLabel)
        self.listLabel.attributedText = attributedMetric
        self.listLabel.sizeToFit()
        self.listLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectLists)))
        self.listLabel.isUserInteractionEnabled = true
        
        let listCountHeader = NSMutableAttributedString()

        listCountHeader.append(NSAttributedString(string:"See All \(String(listCount)) Lists", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 25)]))

//        listCountHeader.append(NSAttributedString(string:"    See All Lists", attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray, NSAttributedString.Key.font: UIFont(name: "Poppins-Regular", size: 12)]))
        self.listHeaderLabel.attributedText = listCountHeader
//        self.listHeaderLabel.text = "\(String(listCount)) Lists"
        self.listHeaderLabel.sizeToFit()
        
        
        // Post Count Label
        attributedMetric = NSMutableAttributedString(string: "\(String(postCount))", attributes: [NSAttributedString.Key.foregroundColor: socialMetricColor, NSAttributedString.Key.font: socialMetricFont])

        attributedLabel = NSMutableAttributedString(string: "\n Posts", attributes: [NSAttributedString.Key.foregroundColor: socialLabelColor, NSAttributedString.Key.font: socialLabelFont])
        
        attributedMetric.append(attributedLabel)
        self.postsLabel.attributedText = attributedMetric
        self.postsLabel.sizeToFit()
        self.postHeaderLabel.text = self.viewFilter.filterLegit ? "Top \(String(self.displayPostCount)) Posts" : "\(String(postCount)) Posts"
        self.postHeaderLabel.textColor = self.viewFilter.filterLegit ? UIColor.customRedColor() : UIColor.ianBlackColor()

        UIColor.customRedColor()
        self.postHeaderLabel.sizeToFit()

        
        // USER BADGE
        
        let badgeAttString = NSMutableAttributedString()
        
        let badgeLabelFont = UIFont(name: "Poppins-Bold", size: 12)
        let badgeLabelColor = UIColor.ianLegitColor()
        
        let image1Attachment = NSTextAttachment()
        //                let inputImage = UIImage(named: "cred")!.resizeImageWith(newSize: imageSize)
        let inputImage = #imageLiteral(resourceName: "redstar")
        image1Attachment.image = inputImage.alpha(1)
        image1Attachment.bounds = CGRect(x: 0, y: (userBadgeLabel.font.capHeight - (inputImage.size.height)).rounded() / 2, width: inputImage.size.width, height: inputImage.size.height)

        let image1String = NSAttributedString(attachment: image1Attachment)
        badgeAttString.append(image1String)
        
        attributedLabel = NSMutableAttributedString(string: " Top 100 ", attributes: [NSAttributedString.Key.foregroundColor: badgeLabelColor, NSAttributedString.Key.font: badgeLabelFont])
        
        badgeAttString.append(attributedLabel)
        userBadgeLabel.attributedText = badgeAttString
        userBadgeLabel.sizeToFit()
        
    }
    
    @objc func selectFollowers(){
        print("User Profile: Select Follower")
        self.delegate?.selectUserFollowers()
    }
    
    @objc func selectFollowing(){
        print("User Profile: Select Following")
        self.delegate?.selectUserFollowing()
    }
    
    @objc func selectLists(){
        print("User Profile: Select Lists")
        self.delegate?.selectUserLists()
    }
    
    
}
