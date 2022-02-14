//
//  SingleListViewHeader.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/22/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth


protocol SingleListViewHeaderDelegate {
    func handleFollowingList()
    func headerSortSelected(sort: String)
    func didChangeToGridView()
    func didChangeToListView()
    func handleFilter()
    func showSearchView()
    func hideSearchView()
    func filterSelected(filter: Filter)
    func goToUser(userId: String?)
    
    func toggleMapFunction()
    func displayListFollowingUsers(list: List, following: Bool)
    func didTapListSetting()
    func didTapListDesc()
    func extShowImage(inputImages: [UIImage]?)

    func filterContentForSearchText(_ searchText: String)
    func didTapSearchButton()
    func didTapAddTag(addTag: String)
    func didRemoveTag(tag: String)
    func didRemoveLocationFilter(location: String)
    func didRemoveRatingFilter(rating: String)
    func didTapCell(tag: String)
    func handleRefresh()
    func didActivateSearchBar()
    func extCreateNewList()
    func editListDesc()
    func confirmListDesc(text: String?)
    func didTapFilterLegit()
}

class SingleListViewHeader: UICollectionViewCell {
    var delegate: SingleListViewHeaderDelegate?

    var currentDisplayList: List? = nil {
        didSet{
            print(" ListHeader | DISPLAYING | \(currentDisplayList?.name) | \(currentDisplayList?.id) | \(currentDisplayList?.postIds?.count) Posts | \(self.currentSort) - \(self.sortSegmentControl.selectedSegmentIndex) |List_ViewController")
            
            //            print("currentDisplayList | \(currentDisplayList?.name) | \(currentDisplayList?.id) | \(currentDisplayList?.postIds?.count)")
            // CLEAR SEARCH BAR
            self.updateListLabels()
            self.isFollowingList = CurrentUser.followedListIds.contains((currentDisplayList?.id)!)
            self.fetchUser()
            
            if currentDisplayList?.heroImage != nil {
                self.heroBackgroundImageView.image = currentDisplayList?.heroImage
                self.heroBackgroundImageButton.isHidden = true
            } else if let url = currentDisplayList?.heroImageUrl {
                if url != "" {
                    self.heroBackgroundImageView.loadImage(urlString: url)
                    self.heroBackgroundImageButton.isHidden = true
                }
            } else {
                self.heroBackgroundImageButton.isHidden = false
            }
            
            
            if self.currentDisplayList?.isRatingList ?? false {
                self.listNameIcon.setImage(UIImage(), for: .normal)
                self.listNameIcon.isHidden = true
            } else {
                let inputImage = self.currentDisplayList?.creatorUID == CurrentUser.uid ? #imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate)
                self.listNameIcon.setImage(inputImage, for: .normal)
                self.listNameIcon.isHidden = false
            }

            
            
            listOptionButton.isHidden = (currentDisplayList?.creatorUID != Auth.auth().currentUser?.uid)
            refreshListDesc()
//            print(" HEADER | isFilteringText | \(self.isFilteringText)")

            // Setup AddTag Options
//            addTagOptions = []

        }
    }
    
    var isFollowingList = false {
        didSet {
            self.setupListFollowButton()
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
            if self.displayUser?.uid != userId {
                Database.fetchUserWithUID(uid: userId) { (user) in
                    self.displayUser = user
                }
            }
        }
    }
    
    var displayUser: User? = nil {
        didSet {
            if let url = self.displayUser?.profileImageUrl {
                if self.userProfileImageView.lastURLToLoadImage != url {
                    self.userProfileImageView.loadImage(urlString: url)
                }
            }
            self.userNameLabel.text = self.displayUser?.username ?? ""
        }
    }
    
    let heroBackgroundImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.borderColor = UIColor.darkLegitColor().cgColor
        iv.layer.borderWidth = 0
        iv.backgroundColor = UIColor.lightGray
        return iv
    }()
    
    let heroBackgroundImageButton: UIButton = {
        let button = UIButton()
        let listIcon = #imageLiteral(resourceName: "add_color").withRenderingMode(.alwaysOriginal)
        button.setImage(listIcon, for: .normal)
        button.contentMode = .scaleAspectFit
        button.setTitleColor(UIColor.ianWhiteColor(), for: .normal)
        button.tintColor = UIColor.gray
        button.backgroundColor = UIColor.clear
        button.setTitle(" Tap To add Image", for: .normal)
        button.isUserInteractionEnabled = true
        button.tintColor = UIColor.ianBlackColor()
        return button
    }()
    
//    let heroBackgroundImageLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Tap To Add Image"
//        label.font = UIFont(font: .avenirNextDemiBold, size: 12)
//        label.textColor = UIColor.ianBlackColor()
//        label.textAlignment = NSTextAlignment.center
//        label.backgroundColor = UIColor.clear
//        label.adjustsFontSizeToFitWidth = true
//        label.lineBreakMode = NSLineBreakMode.byWordWrapping
//        label.numberOfLines = 1
//        return label
//    }()
    
    var viewFilter: Filter = Filter.init(defaultSort: defaultRecentSort){
            didSet {
                print("SingleListHeader | ViewFilter Updated | Refresh Segment | \(self.viewFilter.filterSort) | CUR: \(self.currentSort) , \(self.sortSegmentControl.selectedSegmentIndex)")
                self.refreshButton.isHidden = !viewFilter.isFiltering
                self.updateListLabels()
            }
    }
    
    var currentSort: String = defaultRecentSort {
        didSet {
            print("CUR SORT | \(self.currentSort)")
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
    
    
    var fullSearchBar = UISearchBar()
    var navSearchButton: UIButton = TemplateObjects.NavSearchButton()

    
    
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
    
    let userNameLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(name: "Poppins-Bold", size: 13)
//        label.font = UIFont(font: .avenirNextDemiBold, size: 13)
        label.textColor = UIColor.ianBlackColor()
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.clear
        label.adjustsFontSizeToFitWidth = true
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.numberOfLines = 2
        return label
    }()
    
    let listNameIcon: UIButton = {
        let button = UIButton()
        let listIcon = #imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate)
        button.setImage(listIcon, for: .normal)
        button.backgroundColor = UIColor.clear
        button.isUserInteractionEnabled = false
        button.tintColor = UIColor.ianLegitColor()
        return button
    }()
    
    let listNameLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(name: "Poppins-Bold", size: 24)
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
//        label.font = UIFont.systemFont(ofSize: 14)
        label.font = UIFont(font: .avenirNextMedium, size: 14)
        label.textColor = UIColor.gray
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
//        label.font = UIFont.systemFont(ofSize: 14)
        label.font = UIFont(name: "Poppins-Bold", size: 25)
        label.textColor = UIColor.ianBlackColor()
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.clear
        label.adjustsFontSizeToFitWidth = false
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        return label
    }()
    
    
    let listDescLabel: UILabel = {
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
        
    // FOLLOW UNFOLLOW BUTTON
    lazy var listFollowButton: UIButton = {
        let button = UIButton(type: .system)
//        button.setTitle("Follow List", for: .normal)
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
        print("List Option Pressed")
    }
    
//    let navMapButton = NavBarMapButton.init()
    lazy var navMapButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
//        let icon = #imageLiteral(resourceName: "google_color").withRenderingMode(.alwaysOriginal)
//        let icon = #imageLiteral(resourceName: "location_color").withRenderingMode(.alwaysOriginal)
        let icon = #imageLiteral(resourceName: "map").withRenderingMode(.alwaysTemplate)

        button.setTitle(" Map List", for: .normal)
        button.setImage(icon, for: .normal)
        button.layer.borderColor = UIColor.ianLegitColor().cgColor
        button.layer.borderWidth = 1
        button.clipsToBounds = true
        button.contentHorizontalAlignment = .center
        button.backgroundColor = UIColor.clear // UIColor.ianWhiteColor()
//        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        button.tintColor = UIColor.ianLegitColor()
        button.titleLabel?.font =  UIFont(font: .avenirNextBold, size: 10)
        button.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        button.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12)
        button.imageView?.contentMode = .scaleAspectFit

        return button
    }()
    
//    var listMapButton: UIButton = TemplateObjects.NavBarMapButton()

    
// SORT VIEW
    let optionsView = UIView()
    var sortSegmentControl: UISegmentedControl = UISegmentedControl(items: HeaderSortOptions)

    var navGridToggleButton: UIButton = TemplateObjects.gridFormatButton()

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
    var postFormatInd: Int = 0 {
        didSet{
            setupFormatButton()
            print(" postFormatInd | \(postFormatInd) | ListHeader")
        }
    }
    
    func setupFormatButton(){
        isGridView = (postFormatInd == 0)
        var image = (isGridView) ? #imageLiteral(resourceName: "grid") : #imageLiteral(resourceName: "listFormat")
        self.navGridToggleButton.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
        self.navGridToggleButton.setTitle(isGridView ? "Grid " : "List ", for: .normal)
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
            self.delegate?.didChangeToListView()
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

    
    // MARK: - INIT

    let searchBar = UserSearchBar()

    let listDescTextView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 12)
        tv.textContainer.maximumNumberOfLines = 4
        tv.textContainer.lineBreakMode = .byTruncatingTail
        tv.isScrollEnabled = false
        tv.isEditable = true
        return tv
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
    
    
    var displayPostCount: Int = 0 {
        didSet {
            self.updateListLabels()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        print("    Init LOAD | List Header")

        setupListFollowButton()
        
        backgroundColor = UIColor.backgroundGrayColor()
        
        addSubview(heroBackgroundImageView)
        heroBackgroundImageView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 100)
        heroBackgroundImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapHeroBackgroundImage)))
        heroBackgroundImageView.isUserInteractionEnabled = true
        heroBackgroundImageView.backgroundColor = UIColor.backgroundGrayColor()
        
        addSubview(heroBackgroundImageButton)
        heroBackgroundImageButton.anchor(top: nil, left: nil, bottom: heroBackgroundImageView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 30, paddingRight: 0, width: 0, height: 0)
        heroBackgroundImageButton.sizeToFit()
//        heroBackgroundImageButton.centerYAnchor.constraint(equalTo: heroBackgroundImageView.centerYAnchor).isActive = true
        heroBackgroundImageButton.centerXAnchor.constraint(equalTo: heroBackgroundImageView.centerXAnchor).isActive = true
        heroBackgroundImageButton.addTarget(self, action: #selector(didTapHeroBackgroundButton), for: .touchUpInside)
        heroBackgroundImageButton.isUserInteractionEnabled = true
        heroBackgroundImageButton.isHidden = true
        
        
    // LIST HEADER
        addSubview(listHeaderView)
        listHeaderView.anchor(top: heroBackgroundImageView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0) // 40 + 40 + 30
        listHeaderView.backgroundColor = UIColor.ianWhiteColor()
        
        listHeaderView.layer.applySketchShadow(color: UIColor(red: 0, green: 0, blue: 0, alpha: 1), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
        
    // LIST NAME HEADER - 40
        let listNameContainer = UIView()
        addSubview(listNameContainer)
        listNameContainer.anchor(top: listHeaderView.topAnchor, left: listHeaderView.leftAnchor, bottom: nil, right: listHeaderView.rightAnchor, paddingTop: 5, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 35)
    
        listNameContainer.addSubview(listNameIcon)
        listNameIcon.anchor(top: nil, left: listNameContainer.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        listNameIcon.centerYAnchor.constraint(equalTo: listNameContainer.centerYAnchor).isActive = true
        
//        listNameContainer.addSubview(listFollowButton)
//        listFollowButton.anchor(top: nil, left: nil, bottom: nil, right: listNameContainer.rightAnchor, paddingTop: 4, paddingLeft: 8, paddingBottom: 4, paddingRight: 0, width: 90, height: 30)
//        listFollowButton.centerYAnchor.constraint(equalTo: listNameContainer.centerYAnchor).isActive = true
//        listFollowButton.sizeToFit()
        
        listNameContainer.addSubview(listNameLabel)
        listNameLabel.anchor(top: nil, left: listNameIcon.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        listNameLabel.centerYAnchor.constraint(equalTo: listNameContainer.centerYAnchor).isActive = true
        listNameLabel.topAnchor.constraint(lessThanOrEqualTo: listNameContainer.topAnchor).isActive = true
        listNameLabel.bottomAnchor.constraint(lessThanOrEqualTo: listNameContainer.bottomAnchor).isActive = true
        listNameLabel.sizeToFit()

//        listNameContainer.addSubview(navMapButton)
//        navMapButton.tintColor = UIColor.darkGray
//        navMapButton.setTitleColor(UIColor.ianBlackColor(), for: .normal)
////        navMapButton.setTitle(" Map ", for: .normal)
////        navMapButton.semanticContentAttribute  = .forceRightToLeft
//        navMapButton.anchor(top: nil, left: listNameLabel.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 15, width: 100, height: 30)
//        navMapButton.centerYAnchor.constraint(equalTo: listNameContainer.centerYAnchor).isActive = true
//
//        navMapButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapMapButton)))
//        navMapButton.setTitle("", for: .normal)
//        navMapButton.sizeToFit()
//        navMapButton.isHidden = true
        
//        addSubview(listFollowerCountLabel)
//        listFollowerCountLabel.anchor(top: listNameContainer.bottomAnchor, left: listNameContainer.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 25, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
////        listFollowerCountLabel.centerYAnchor.constraint(equalTo: listSocialContainer.centerYAnchor).isActive = true
//        listFollowerCountLabel.sizeToFit()
        
        
    // LIST SOCIAL DETAILS - 40
        let listSocialContainer = UIView()
        addSubview(listSocialContainer)
        listSocialContainer.anchor(top: listNameContainer.bottomAnchor, left: listNameContainer.leftAnchor, bottom: nil, right: listNameContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)


        
        listSocialContainer.addSubview(userProfileImageView)
        userProfileImageView.anchor(top: nil, left: listSocialContainer.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 30, height: 30)
        userProfileImageView.centerYAnchor.constraint(equalTo: listSocialContainer.centerYAnchor).isActive = true
        userProfileImageView.isUserInteractionEnabled = true
        userProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapUser)))
        
        listSocialContainer.addSubview(userNameLabel)
        userNameLabel.anchor(top: nil, left: userProfileImageView.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        userNameLabel.centerYAnchor.constraint(equalTo: userProfileImageView.centerYAnchor).isActive = true
        userNameLabel.isUserInteractionEnabled = true
        userNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapUser)))
        
        
//        listSocialContainer.addSubview(listPostCountLabel)
//        listPostCountLabel.anchor(top: nil, left: userProfileImageView.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
//        listPostCountLabel.centerYAnchor.constraint(equalTo: listSocialContainer.centerYAnchor).isActive = true
//        listPostCountLabel.sizeToFit()
//
//
//        listSocialContainer.addSubview(listFollowerCountLabel)
//        listFollowerCountLabel.anchor(top: nil, left: listPostCountLabel.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
//        listFollowerCountLabel.centerYAnchor.constraint(equalTo: listSocialContainer.centerYAnchor).isActive = true
//        listFollowerCountLabel.sizeToFit()
        
        listSocialContainer.addSubview(listFollowButton)
        listFollowButton.anchor(top: nil, left: nil, bottom: nil, right: listSocialContainer.rightAnchor, paddingTop: 4, paddingLeft: 8, paddingBottom: 4, paddingRight: 0, width: 150, height: 30)
        listFollowButton.centerYAnchor.constraint(equalTo: listSocialContainer.centerYAnchor).isActive = true
        listFollowButton.sizeToFit()
//        listFollowButton.leftAnchor.constraint(lessThanOrEqualTo: listFollowerCountLabel.rightAnchor, constant: 10).isActive = true
        
        
            
//        listSocialContainer.addSubview(listOptionButton)
//        listOptionButton.anchor(top: nil, left: nil, bottom: nil, right: listSocialContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 90, height: 30)
//        listOptionButton.centerYAnchor.constraint(equalTo: listSocialContainer.centerYAnchor).isActive = true
//        listOptionButton.addTarget(self, action: #selector(didTapOptionButton), for: .touchUpInside)
//        listOptionButton.isHidden = true
        
// LIST DESC - 30
        
        addSubview(listDescTextView)
        listDescTextView.delegate = self
        listDescTextView.anchor(top: listSocialContainer.bottomAnchor, left: listNameContainer.leftAnchor, bottom: listHeaderView.bottomAnchor, right: listNameContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        listDescTextView.backgroundColor = UIColor.clear
        refreshListDesc()
        
//        let listDescView = UIView()
//        addSubview(listDescView)
//        listDescView.anchor(top: listSocialContainer.bottomAnchor, left: listNameContainer.leftAnchor, bottom: listHeaderView.bottomAnchor, right: listNameContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 30)
//
//        listDescView.addSubview(listDescLabel)
//        listDescLabel.anchor(top: listDescView.topAnchor, left: listDescLabel.leftAnchor, bottom: listDescLabel.bottomAnchor, right: listDescLabel.rightAnchor, paddingTop: 4, paddingLeft: 0, paddingBottom: 4, paddingRight: 0, width: 0, height: 0)
//
//        listDescLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapListDesc)))
        
        
// BOTTOM DIV
        
        let bottomDiv = UIView()
        addSubview(bottomDiv)
        bottomDiv.anchor(top: listDescTextView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 2)
        bottomDiv.backgroundColor = UIColor.rgb(red: 221, green: 221, blue: 221)
            
    // POST HEADER COUNT
        let postCountHeaderView = UIView()
        addSubview(postCountHeaderView)
        postCountHeaderView.anchor(top: bottomDiv.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
        postCountHeaderView.backgroundColor = UIColor.backgroundGrayColor()
        
        postCountHeaderView.addSubview(listPostCountLabel)
        listPostCountLabel.anchor(top: postCountHeaderView.topAnchor, left: postCountHeaderView.leftAnchor, bottom: postCountHeaderView.bottomAnchor, right: nil, paddingTop: 4, paddingLeft: 15, paddingBottom: 4, paddingRight: 15, width: 0, height: 0)
//        postHeaderLabel.centerYAnchor.constraint(equalTo: postCountHeaderView.centerYAnchor).isActive = true
        listPostCountLabel.sizeToFit()
        
        postCountHeaderView.addSubview(refreshButton)
        refreshButton.anchor(top: nil, left: listPostCountLabel.rightAnchor, bottom: nil, right: nil, paddingTop: 4, paddingLeft: 10, paddingBottom: 4, paddingRight: 15, width: 25, height: 25)
        refreshButton.isHidden = true

        postCountHeaderView.addSubview(navMapButton)
        navMapButton.anchor(top: nil, left: nil, bottom: nil, right: postCountHeaderView.rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 10, paddingRight: 10, width: 100, height: 30)
        navMapButton.centerYAnchor.constraint(equalTo: postCountHeaderView.centerYAnchor).isActive = true
        navMapButton.layer.cornerRadius = 30/2
        navMapButton.layer.masksToBounds = true
        navMapButton.addTarget(self, action: #selector(didTapMapButton), for: .touchUpInside)
        navMapButton.alpha = 0.8
        navMapButton.isHidden = true
            
        
    // ACTION BAR
        addSubview(actionBarView)
        actionBarView.backgroundColor = UIColor.backgroundGrayColor()
        actionBarView.anchor(top: postCountHeaderView.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
        actionBarView.addSubview(searchBar)
        searchBar.searchBarView.backgroundColor = UIColor.clear
        searchBar.alpha = 0.9
        searchBar.anchor(top: actionBarView.topAnchor, left: actionBarView.leftAnchor, bottom: actionBarView.bottomAnchor, right: actionBarView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        searchBar.navSearchButton.tintColor = UIColor.darkGray
        searchBar.delegate = self

//
//
//        actionBarView.addSubview(navSearchButton)
//        navSearchButton.anchor(top: actionBarView.topAnchor, left: nil, bottom: actionBarView.bottomAnchor, right: actionBarView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 15, width: 0, height: 0)
//        navSearchButton.addTarget(self, action: #selector(didTapSearch), for: .touchUpInside)
//        navSearchButton.setTitle(" Search", for: .normal)
//        navSearchButton.layer.cornerRadius = 5
//        navSearchButton.layer.masksToBounds = true
//        navSearchButton.tintColor = UIColor.gray
//        navSearchButton.layer.borderColor = UIColor.gray.cgColor
//        navSearchButton.setTitleColor(UIColor.gray, for: .normal)
//        navSearchButton.backgroundColor = UIColor.clear
//        navSearchButton.layer.borderWidth = 0
//
//
//
//        setupSearchBar()
//        actionBarView.addSubview(fullSearchBar)
//        fullSearchBar.anchor(top: actionBarView.topAnchor, left: actionBarView.leftAnchor, bottom: actionBarView.bottomAnchor, right: navSearchButton.leftAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
//
//
//
//// SORT VIEW
//        addSubview(optionsView)
//        optionsView.anchor(top: actionBarView.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 40)
//
//        setupSegmentControl()
//        optionsView.addSubview(sortSegmentControl)
//        sortSegmentControl.anchor(top: nil, left: optionsView.leftAnchor, bottom: optionsView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
//
//
//        optionsView.addSubview(navMapButton)
//        navMapButton.tintColor = UIColor.ianBlackColor()
//        navMapButton.setTitle(" Map ", for: .normal)
////        navMapButton.semanticContentAttribute  = .forceRightToLeft
//        navMapButton.anchor(top: nil, left: nil, bottom: nil, right: optionsView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
//        navMapButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapMapButton)))
//        navMapButton.centerYAnchor.constraint(equalTo: optionsView.centerYAnchor).isActive = true
////        navMapButton.rightAnchor.constraint(lessThanOrEqualTo: navGridToggleButton.leftAnchor, constant: 10).isActive = true
//
//        setupnavGridToggleButton()
//        optionsView.addSubview(navGridToggleButton)
//        navGridToggleButton.anchor(top: nil, left: sortSegmentControl.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
//        navGridToggleButton.rightAnchor.constraint(lessThanOrEqualTo: navMapButton.leftAnchor).isActive = true
//        navGridToggleButton.centerYAnchor.constraint(equalTo: optionsView.centerYAnchor).isActive = true
//        navGridToggleButton.backgroundColor = UIColor.white

        
    }
    
    @objc func didTapSearch(){
        self.delegate?.didTapSearchButton()
    }
    
    @objc func didTapHeroBackgroundImage() {
        print("didTapHeroBackgroundImage")
        guard let image = self.heroBackgroundImageView.image else {return}
        self.delegate?.extShowImage(inputImages: [image])
    }
    
    @objc func didTapHeroBackgroundButton(){
        print("didTapHeroBackgroundButton")
        self.delegate?.didTapListSetting()
    }

    func didTapListDesc() {
        self.delegate?.didTapListDesc()
    }

   @objc func didTapFollowEditButton(){
        if self.listFollowButton.titleLabel?.text == "Options"
        {
            self.didTapOptionButton()
        }
        else
        {
            self.isFollowingList = !self.isFollowingList
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
                


        let listPostCountHeader = NSMutableAttributedString()


        
        if let postCount = self.currentDisplayList?.postIds?.count {
            var postCountColor = self.viewFilter.filterLegit ? UIColor.customRedColor() : UIColor.ianBlackColor()
            var postCountText = self.viewFilter.filterLegit ? "Top \(String(self.displayPostCount)) Posts" : "\(String(postCount)) Posts"
            listPostCountHeader.append(NSAttributedString(string:postCountText, attributes: [NSAttributedString.Key.foregroundColor: postCountColor, NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 25)]))
//            listPostCountLabel.text = "\(postCount) Posts"
        }
        

        var followerText = ""
        if let followerCount = (self.currentDisplayList?.followerCount) {
            if followerCount > 0 {
                followerText = "     \(followerCount) Followers"
            }
        }
        
        listPostCountHeader.append(NSAttributedString(string:followerText, attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray, NSAttributedString.Key.font: UIFont(name: "Poppins-Regular", size: 12)]))

        listPostCountLabel.attributedText = listPostCountHeader
//        listFollowerCountLabel.text = followerText
        
    }
    
    func setupListFollowButton() {
        
        guard let listId = self.currentDisplayList?.id else {return}
        
        listFollowButton.isHidden = Auth.auth().currentUser == nil

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
        else if self.isFollowingList{
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
        
        listFollowButton.isHidden = (currentDisplayList?.isRatingList ?? false)
    }

    @objc func showListFollowingUser() {
        guard let list = self.currentDisplayList else {return}
        self.delegate?.displayListFollowingUsers(list: list, following: true)
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

extension SingleListViewHeader: UISearchBarDelegate, postSortSegmentControlDelegate, postViewFormatSegmentControlDelegate, UserSearchBarDelegate, UITextViewDelegate {
    
    func didTapEmojiBackButton() {
        
    }
    
    func didTapEmojiButton() {
        
    }
    
    func didTapFilterLegit() {
        self.delegate?.didTapFilterLegit()
    }
    
    
    func didTapGridButton() {
        self.toggleView()
    }
    
    
    func filterContentForSearchText(searchText: String) {
        self.delegate?.filterContentForSearchText(searchText)
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
    
    
    @objc func didTapMapButton() {
        self.delegate?.toggleMapFunction()
    }
    
    
    
    func setupnavGridToggleButton() {
        navGridToggleButton.tintColor = UIColor.ianBlackColor()
        navGridToggleButton.setTitleColor(UIColor.ianBlackColor(), for: .normal)
        navGridToggleButton.titleLabel?.font =  UIFont(font: .avenirNextBold, size: 13)
        navGridToggleButton.backgroundColor = UIColor.clear
        navGridToggleButton.isUserInteractionEnabled = true
        navGridToggleButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleView)))
        navGridToggleButton.semanticContentAttribute  = .forceLeftToRight
        navGridToggleButton.layer.cornerRadius = 5
        navGridToggleButton.layer.masksToBounds = true
        navGridToggleButton.layer.borderColor = navGridToggleButton.tintColor.cgColor
        navGridToggleButton.layer.borderWidth = 1
        navGridToggleButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    }
    
    func headerSortSelected(sort: String) {
        self.delegate?.headerSortSelected(sort: sort)
    }
    
    func postFormatSelected(format: String) {
        if format == postGrid && !isGridView {
            self.delegate?.didChangeToGridView()
        } else if format == postList && isGridView {
            self.delegate?.didChangeToListView()
        }
    }
    
    
    func setupSegmentControl() {
//        TemplateObjects.postSortDelegate = self
        sortSegmentControl.backgroundColor = UIColor.white
        sortSegmentControl.tintColor = UIColor.oldLegitColor()
        if #available(iOS 13.0, *) {
            sortSegmentControl.selectedSegmentTintColor = UIColor.ianBlackColor()
        }
        sortSegmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor()], for: .normal)
        sortSegmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianWhiteColor()], for: .selected)
        sortSegmentControl.selectedSegmentIndex = 0
        sortSegmentControl.addTarget(self, action: #selector(SingleListViewHeader.selectPostSort), for: .valueChanged)
        self.reloadSegmentControl()
    }
    
    @objc func selectPostSort(sender: UISegmentedControl) {
        let selectedSort = HeaderSortOptions[sender.selectedSegmentIndex]
        print("SingleListViewHeader | \(selectedSort) | selectPostSort | \(sender.selectedSegmentIndex)")
        self.currentSort = selectedSort
        self.reloadSegmentControl()
        self.headerSortSelected(sort: selectedSort)
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
    
 
    func refreshListDesc() {
//        if self.currentDisplayList?.listDescription == nil && (self.currentDisplayList?.creatorUID == Auth.auth().currentUser?.uid) {
//            let text = NSMutableAttributedString(string: "Tap To Add List Description", attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray, NSAttributedString.Key.font: UIFont(font: .avenirNextMediumItalic, size: 13)])
//            self.listDescLabel.attributedText = text
//            self.listDescLabel.isUserInteractionEnabled = true
//        } else {
//            self.listDescLabel.text = (self.currentDisplayList?.listDescription ?? "")
//            self.listDescLabel.isUserInteractionEnabled = false
//        }
        
        if (currentDisplayList?.isRatingList ?? false) {
            self.listDescTextView.text = "All your posts tagged with \((currentDisplayList?.id)!)"
            self.listDescTextView.textColor = UIColor.black
        }
        else if Auth.auth().currentUser?.uid == currentDisplayList?.creatorUID && (currentDisplayList?.listDescription == "" || currentDisplayList?.listDescription == nil) {
            self.listDescTextView.text = ListDescPlaceHolder
            self.listDescTextView.textColor = UIColor.lightGray
        } else {
            if (currentDisplayList?.listDescription == "" || currentDisplayList?.listDescription == nil) {
                self.listDescTextView.text = "No List Description"
            } else {
                self.listDescTextView.text = self.currentDisplayList?.listDescription
            }
            print("refreshListDesc: ", self.currentDisplayList?.listDescription)
            self.listDescTextView.textColor = UIColor.black
        }
        self.listDescTextView.sizeToFit()
        
        
    }

    
    
    // MARK: - Search Bar Delegates

    
        func setupSearchBar() {
    //        setup.searchBarStyle = .prominent
            fullSearchBar.searchBarStyle = .default
            fullSearchBar.delegate = self

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
            fullSearchBar.setImage(searchImage, for: .search, state: .normal)
            
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
//        self.handleFilter()
        self.filterContentForSearchText(searchText: searchText)
//        self.fullSearchBar.becomeFirstResponder()
//        self.isFilteringText = searchText
        print("textDidChange | ",self.fullSearchBar.text)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        print("isFilteringText | \(self.isFilteringText)")
//        self.fullSearchBar.text =  self.isFilteringText
//        self.showFullSearchBar()
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
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if Auth.auth().currentUser?.uid == currentDisplayList?.creatorUID {
            self.delegate?.editListDesc()
        }
        
        return false
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView == listDescTextView {
            if listDescTextView.text == ListDescPlaceHolder {
                listDescTextView.text = nil
            }
            listDescTextView.font =  UIFont.systemFont(ofSize: 12)
            listDescTextView.textColor = UIColor.ianBlackColor()
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if currentDisplayList?.listDescription == "" && textView.text.count == 0 {
            print("User Info TextView Blank")
        } else {
            self.delegate?.confirmListDesc(text: textView.text)
        }
    }
    
    
}

