//
//  LegitHomeHeader.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/15/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit


class LegitHomeHeader: UICollectionViewCell {

//    var sortSegmentControl = UISegmentedControl()
    

    
    var delegate: LegitHomeHeaderDelegate?
    
    var viewFilter: Filter = Filter.init(defaultSort: defaultRecentSort) {
        didSet {
//            self.refreshNavSort()
            self.refreshSegmentValues()
            self.updateSearchTerms()
            self.emojiCollectionView.allowsSelection = !viewFilter.isFiltering
            self.updateSearchButton()

        }
    }
    
    
    
    var searchTerms: [String] = []
    func updateSearchTerms() {
//        searchTerms = []
//        // CAPTION
//        if let _ = self.viewFilter.filterCaption {
//            var tempFilterCaption = self.viewFilter.filterCaption ?? ""
//            // Check for Countries First
//            for x in cuisineEmojiSelect {
//                if tempFilterCaption.contains(x) {
//                    searchTerms.append(x)
//                    tempFilterCaption = tempFilterCaption.replacingOccurrences(of: x, with: "")
//                }
//            }
//
//            if searchTerms.count > 0 {
//                print("Found \(searchTerms.count) Flags | \(searchTerms) | Rem: \(tempFilterCaption)")
//            }
//
//
//            print(tempFilterCaption.emojis)
//            for emoji in tempFilterCaption.emojis {
//                if !emoji.isEmptyOrWhitespace() && emoji != "️" {
//                    print(emoji)
//                    searchTerms.append(emoji)
//                }
//            }
//            if !tempFilterCaption.isEmptyOrWhitespace() && tempFilterCaption != tempFilterCaption.emojis.joined() {
//                searchTerms.append(tempFilterCaption)
//            }
//        }
//
//        // TYPE (NEED WORK, WHAT IF IT WAS LUNCH + CHINESE
//        if let filterAutoTag = self.viewFilter.filterType {
//            searchTerms.append(filterAutoTag)
//        }
//
//        //RESTAURANT
//        if let location = self.viewFilter.filterLocationName {
//            searchTerms.append(location)
//        } else if let id = self.viewFilter.filterGoogleLocationID {
//            if let name = locationGoogleIdDictionary.key(forValue: id) {
//                searchTerms.append(name)
//            }
//        }
//
//
//        // CITY
//        if let location = self.viewFilter.filterLocationSummaryID {
//            searchTerms.append(location)
//        }
        
        searchTerms = Array(Set(self.viewFilter.searchTerms))
        
        print("Header Selected Filters | \(searchTerms)")
        self.emojiCollectionView.reloadData()
        
    }
    
    var fetchTypeInd: String = HomeFetchDefault {
        didSet{
            self.refresNavFeedTypeLabel()
        }
    }
    
    var fetchUser: User? = nil
    
    func refresNavFeedTypeLabel(){
        if self.fetchTypeInd == HomeFetchOptions[3] && self.fetchUser != nil
        {
            self.navFeedTypeLabel.text = self.fetchUser?.username
        } else {
            self.navFeedTypeLabel.text = self.fetchTypeInd
        }
        self.navFeedTypeLabel.sizeToFit()
    }

    lazy var navSortLabel: UILabel = {
        let ul = UILabel()
        ul.isUserInteractionEnabled = true
        ul.numberOfLines = 0
        ul.textAlignment = NSTextAlignment.left
        return ul
    }()
    
    lazy var navFeedTypeLabel: UILabel = {
        let ul = UILabel()
        ul.isUserInteractionEnabled = true
        ul.numberOfLines = 0
        ul.textAlignment = NSTextAlignment.left
        ul.font = UIFont(name: "Poppins-Bold", size: 38)
        ul.textColor = UIColor.ianBlackColor()
        return ul
    }()
    
    lazy var navFeedTypeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "dropdownXLarge").withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.tintColor = UIColor.ianBlackColor()
        button.addTarget(self, action: #selector(toggleNavFeedType), for: .touchUpInside)
        return button
    }()
    
    
    @objc func toggleNavFeedType(){
        self.delegate?.toggleFeedType()
    }
    
    lazy var navNotificationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "alert").withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.tintColor = UIColor.ianBlackColor()
        button.addTarget(self, action: #selector(didTapNotification), for: .touchUpInside)
        return button
    }()
    
    lazy var navNotificationLabel: UILabel = {
        let ul = UILabel()
        ul.isUserInteractionEnabled = true
        ul.font = UIFont.boldSystemFont(ofSize: 14)
        ul.numberOfLines = 1
        ul.textAlignment = NSTextAlignment.center
        ul.backgroundColor = UIColor.backgroundGrayColor()
        ul.layer.cornerRadius = 1
        ul.layer.masksToBounds = true
        return ul
    }()
    
    
    
    var navSearchButton: UIButton = TemplateObjects.NavSearchButton()
    var navGridButton: UIButton = TemplateObjects.NavGridButton()
    var navGridToggleButton: UIButton = TemplateObjects.gridFormatButton()

//    var navMapButton: UIButton = TemplateObjects.NavBarMapButton()

    
    lazy var navMapButton: UIButton = {
        let ul = UIButton.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        ul.setImage(#imageLiteral(resourceName: "map_nav_1"), for: .normal)
        ul.imageView?.contentMode = .scaleAspectFill
        ul.isUserInteractionEnabled = true
        ul.layer.cornerRadius = 1
        ul.layer.masksToBounds = true
        return ul
    }()
    
    var navSearchButtonFull: UIButton = TemplateObjects.NavSearchButton()
    var formatOptions = ["grid", "list"]

    var sortSegmentControl: UISegmentedControl = TemplateObjects.createPostSortButton()
    var formatSegmentControl: UISegmentedControl = TemplateObjects.createGridListButton()
    

    
    var isGridView = false {
        didSet {
            var image = isGridView ? #imageLiteral(resourceName: "grid") : #imageLiteral(resourceName: "listFormat")
        self.navGridButton.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
        self.navGridButton.setTitle(isGridView ? "GRID" : "LIST", for: .normal)
        self.navGridToggleButton.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
        }
        
    }
    
    var displayedEmojis: [String] = [] {
        didSet {
            print("LegitHomeHeader | \(displayedEmojis.count) Emojis")
//            self.emojiCollectionView.reloadData()
            self.refreshEmojiCollectionView()
        }
    }
    
    var listDefaultEmojis = mealEmojisSelect
    
    let emojiCollectionView: UICollectionView = {
        let uploadEmojiList = UICollectionViewFlowLayout()
        uploadEmojiList.estimatedItemSize = CGSize(width: 120, height: 35)
        uploadEmojiList.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        uploadEmojiList.scrollDirection = .horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadEmojiList)
        cv.layer.borderWidth = 0
        cv.backgroundColor = UIColor.white
        return cv
    }()
    
    lazy var emojiLabel: UILabel = {
        let ul = UILabel()
        ul.isUserInteractionEnabled = false
        ul.font = UIFont(name: "Poppins-Bold", size: 14)
        ul.numberOfLines = 1
        ul.textAlignment = NSTextAlignment.left
        ul.backgroundColor = UIColor.clear
        ul.textColor = UIColor.ianBlackColor()
        ul.layer.cornerRadius = 1
        ul.layer.masksToBounds = true
        return ul
    }()
    
    let fullSearchBarView = UIView()
    var fullSearchBar = UISearchBar()
    lazy var fullSearchBarCancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.tintColor = UIColor.ianBlackColor()
        button.addTarget(self, action: #selector(tapCancelButton), for: .touchUpInside)
        return button
    }()
    
    @objc func tapCancelButton(){
        if halfSearchBarWidth!.isActive && self.viewFilter.isFiltering {
            self.delegate?.handleRefresh()
        } else {
            hideFullSearchBar()
        }
    }
    
    var fullSearchBarWidth: NSLayoutConstraint?
    var halfSearchBarWidth: NSLayoutConstraint?
    
    
    
//    let halfSearchBarView = UIView()
//    var halfSearchBar = UITextField()
//    lazy var halfSearchBarCancelButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setImage(#imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysTemplate), for: .normal)
//        button.imageView?.contentMode = .scaleAspectFill
//        button.tintColor = UIColor.ianBlackColor()
//        button.addTarget(self, action: #selector(cancelSearch), for: .touchUpInside)
//        return button
//    }()
//
//    func cancelSearch() {
//        self.delegate?.handleRefresh()
//    }
    
    // MARK: - INIT

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        
    // 50 - HeaderView
        
                
        let headerView = UIView()
        addSubview(headerView)
        headerView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 10, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 40 + UIApplication.shared.statusBarFrame.height)
        
        headerView.backgroundColor = UIColor.clear
        
        setupSegmentControl()
        headerView.addSubview(sortSegmentControl)
        sortSegmentControl.anchor(top: nil, left: headerView.leftAnchor, bottom: headerView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
//        sortSegmentControl.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor).isActive = true
        
        
        
        navMapButton.setTitle("Map", for: .normal)
        navMapButton.setTitleColor(UIColor.ianBlackColor(), for: .normal)
        navMapButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        headerView.addSubview(navMapButton)
        navMapButton.anchor(top: nil, left: nil, bottom: headerView.bottomAnchor, right: headerView.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 5, paddingRight: 0, width: 70, height: 30)
//        navMapButton.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor).isActive = true
        navMapButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapMapButton)))
        navMapButton.semanticContentAttribute  = .forceRightToLeft
        navMapButton.layer.borderWidth = 1
        navMapButton.layer.cornerRadius = 5
        navMapButton.layer.masksToBounds = true

        

        
        
        

//        



        
    // 110 + Feed Type
        let navFeedTypeView = UIView()
        addSubview(navFeedTypeView)
        navFeedTypeView.anchor(top: headerView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 60)
        navFeedTypeView.isUserInteractionEnabled = true
        navFeedTypeView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleNavFeedType)))


//        setupFormatSegmentControl()
//        navFeedTypeView.addSubview(formatSegmentControl)
//        formatSegmentControl.anchor(top: nil, left: nil, bottom: nil, right: navFeedTypeView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 20, width: 0, height: 0)
//        formatSegmentControl.centerYAnchor.constraint(equalTo: navFeedTypeView.centerYAnchor).isActive = true
//
    //
        
        navFeedTypeView.addSubview(navFeedTypeButton)
        navFeedTypeButton.anchor(top: nil, left: nil, bottom: nil, right: navFeedTypeView.rightAnchor, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 20, width: 30, height: 30)
        navFeedTypeButton.rightAnchor.constraint(lessThanOrEqualTo: navFeedTypeView.rightAnchor).isActive = true
        navFeedTypeButton.centerYAnchor.constraint(equalTo: navFeedTypeView.centerYAnchor).isActive = true
        navFeedTypeButton.addTarget(self, action: #selector(toggleNavFeedType), for: .touchUpInside)
        navFeedTypeButton.isHidden = false
        
        
        navFeedTypeView.addSubview(navFeedTypeLabel)
        navFeedTypeLabel.anchor(top: nil, left: navFeedTypeView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 8, paddingRight: 0, width: 0, height: 0)
        navFeedTypeLabel.centerYAnchor.constraint(equalTo: navFeedTypeView.centerYAnchor).isActive = true
        navFeedTypeLabel.isUserInteractionEnabled = true
        navFeedTypeLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleNavFeedType)))
        navFeedTypeLabel.centerXAnchor.constraint(equalTo: navFeedTypeView.centerXAnchor).isActive = true
//        navFeedTypeLabel.rightAnchor.constraint(lessThanOrEqualTo:  navFeedTypeButton.leftAnchor).isActive = true


        self.refresNavFeedTypeLabel()
        
    // 120 + BottomDiv
        let navFeedTypeDiv = UIView()
        navFeedTypeDiv.backgroundColor = UIColor.ianBlackColor()
        addSubview(navFeedTypeDiv)
        navFeedTypeDiv.anchor(top: navFeedTypeView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 4, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 6)
        
    // 30 - Sort View
//        let sortView = UIView()
//        addSubview(sortView)
//        sortView.anchor(top: headerView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 40)

//        sortSegmentControl.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true


        
    // 180 + Bottom View
        
        let bottomView = UIView()
        addSubview(bottomView)
        bottomView.anchor(top: navFeedTypeDiv.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 15, paddingLeft: 15, paddingBottom: 10, paddingRight: 15, width: 0, height: 40)
        
        // SETUP BUTTONS

        
        bottomView.addSubview(navGridToggleButton)
        navGridToggleButton.anchor(top: nil, left: nil, bottom: nil, right: bottomView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 30, height: 30)
        navGridToggleButton.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor).isActive = true
        navGridToggleButton.isUserInteractionEnabled = true
        navGridToggleButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapGridButton)))
        
        navSearchButton.setTitle(" Search", for: .normal)
        navSearchButton.layer.cornerRadius = 5
        navSearchButton.layer.borderWidth = 1
        navSearchButton.clipsToBounds = true
        navSearchButton.tintColor = UIColor.ianMiddleGrayColor()
        navSearchButton.titleLabel?.textColor = UIColor.ianMiddleGrayColor()
        navSearchButton.layer.borderColor = UIColor.ianMiddleGrayColor().cgColor
        navSearchButton.setTitleColor(UIColor.ianMiddleGrayColor(), for: .normal)
        self.updateSearchButton()

        bottomView.addSubview(navSearchButton)
        navSearchButton.anchor(top: nil, left: nil, bottom: nil, right: navGridToggleButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 10, width: 0, height: 30)
    //        navSearchButton.leftAnchor.constraint(lessThanOrEqualTo: sortSegmentControl.rightAnchor).isActive = true
        navSearchButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapSearchButton)))
//        navSearchButton.semanticContentAttribute  = .forceRightToLeft
        navSearchButton.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor).isActive = true
        
        
        setupEmojiCollectionView()
        bottomView.addSubview(emojiCollectionView)
//        emojiCollectionView.anchor(top: nil, left: bottomView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 10, width: 35 + 180 + 30, height: 35)
        emojiCollectionView.anchor(top: nil, left: bottomView.leftAnchor, bottom: nil, right: navSearchButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 10, width: 0, height: 35)

        emojiCollectionView.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor).isActive = true
//        emojiCollectionView.rightAnchor.constraint(lessThanOrEqualTo: formatSegmentControl.leftAnchor).isActive = true
        // LOADS IN DEFAULT EMOJIS
//        emojiCollectionView.reloadData()
        self.refreshEmojiCollectionView()
            



        
        
    }
    
    func setupNavNotification(){
        let unread = CurrentUser.unreadEventCount
        navNotificationLabel.text = String(unread)
        navNotificationLabel.sizeToFit()
        navNotificationLabel.isHidden = (unread == 0)
    }
    
    @objc func didTapNotification(){
        self.delegate?.didTapNotification()
    }
    
    func updateSearchButton() {
        let search = UITapGestureRecognizer(target: self, action: #selector(didTapSearchButton))

        navSearchButton.setTitle(self.viewFilter.isFiltering ? "" : " Search", for: .normal)
        navSearchButton.setTitleColor(UIColor.ianBlackColor(), for: .normal)
        navSearchButton.setImage(#imageLiteral(resourceName: "search_selected").withRenderingMode(.alwaysTemplate), for: .normal)
        navSearchButton.tintColor = UIColor.ianBlackColor()
        navSearchButton.layer.borderColor = UIColor.ianBlackColor().cgColor
        navSearchButton.addGestureRecognizer(search)
        navSearchButton.sizeToFit()

        
/*
        let cancel = UITapGestureRecognizer(target: self, action: #selector(didTapCancelButton))
        
        if self.viewFilter.isFiltering {
            navSearchButton.setTitle(" Clear", for: .normal)
            navSearchButton.setTitleColor(UIColor.red, for: .normal)
            navSearchButton.setImage(#imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysTemplate), for: .normal)
            navSearchButton.tintColor = UIColor.red
            navSearchButton.layer.borderColor = UIColor.red.cgColor
            navSearchButton.removeGestureRecognizer(search)
            navSearchButton.addGestureRecognizer(cancel)
        } else {
            navSearchButton.setTitle(" Search", for: .normal)
            navSearchButton.setTitleColor(UIColor.ianBlackColor(), for: .normal)
            navSearchButton.setImage(#imageLiteral(resourceName: "search_selected").withRenderingMode(.alwaysTemplate), for: .normal)
            navSearchButton.tintColor = UIColor.ianBlackColor()
            navSearchButton.layer.borderColor = UIColor.ianBlackColor().cgColor
            navSearchButton.addGestureRecognizer(search)
            navSearchButton.removeGestureRecognizer(cancel)
        }
        navSearchButton.sizeToFit()
 */
    }
    
    @objc func didTapSearchButton(){
        self.delegate?.didTapSearchButton()

//        if self.fullSearchBarView.alpha == 0 {
//            self.showFullSearchBar()
//        } else {
//            self.hideFullSearchBar()
//        }
//        if self.viewFilter.isFiltering {
//            self.delegate?.didTapSearchButton()
//        } else {
//            self.delegate?.handleRefresh()
//        }
    }
    
    @objc func didTapCancelButton(){
        self.delegate?.handleRefresh()
    }
    
    @objc func didTapMapButton(){
        self.delegate?.didTapMapButton()
    }
    
    @objc func didTapGridButton(){
        self.delegate?.didTapGridButton()
    }
    
    let addTagId = "addTagId"
    let filterTagId = "filterTagId"
    let refreshTagId = "refreshTagId"

    // MARK: - EMOJI COLLECTION VIEW

    
    func setupEmojiCollectionView(){
        emojiCollectionView.backgroundColor = UIColor.clear
        emojiCollectionView.register(HomeFilterBarCell.self, forCellWithReuseIdentifier: addTagId)
        emojiCollectionView.register(SelectedFilterBarCell.self, forCellWithReuseIdentifier: filterTagId)
        emojiCollectionView.register(RefreshFilterBarCell.self, forCellWithReuseIdentifier: refreshTagId)

        emojiCollectionView.delegate = self
        emojiCollectionView.dataSource = self
        emojiCollectionView.showsHorizontalScrollIndicator = false
        emojiCollectionView.isScrollEnabled = true
    }

    func refreshEmojiCollectionView() {
//        if self.viewFilter.filterSort == sortNew {
//            emojiLabel.text = "50 Recent:"
//        } else if self.viewFilter.filterSort == sortNearest {
//            emojiLabel.text = "50 Nearest:"
//        } else if self.viewFilter.filterSort == sortTrending {
//            emojiLabel.text = "50 Trendiest:"
//        }
//        emojiLabel.text = "Top 50 "

        self.emojiCollectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .left, animated: false)
        self.emojiCollectionView.reloadData()
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

// MARK: - COLLECTION VIEW DELEGATES

extension LegitHomeHeader : UICollectionViewDelegate, UICollectionViewDataSource, SelectedFilterBarCellDelegate, RefreshFilterBarCellDelegate {
    func didTapCell(tag: String) {
        print("LegitHomeHeader | didTapCell \(tag)")
    }
    
    func didRemoveLocationFilter(location: String) {
        print("LegitHomeHeader | didRemoveLocationFilter \(location)")
    }
    
    func didRemoveRatingFilter(rating: String) {
        print("LegitHomeHeader | didRemoveRatingFilter \(rating)")
    }
    
    func handleRefresh() {
        self.delegate?.handleRefresh()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if self.viewFilter.isFiltering {
            print("SearchTerms \(searchTerms.count) | \(searchTerms)")
            return searchTerms.count + 1
            
        } else {
        //  SHOW DEFAULT EMOJIS IF NO EMOJIS FROM FEED - TO WORK AROUND BLANK INITIAL VIEW WHEN LOADING
            return (displayedEmojis.count == 0 ? listDefaultEmojis.count : displayedEmojis.count) + 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: addTagId, for: indexPath) as! HomeFilterBarCell
        var isSelected = false

    // FILTER SELECTED
        if self.viewFilter.isFiltering {
            if indexPath.item == 0 {
            let refreshCell = collectionView.dequeueReusableCell(withReuseIdentifier: refreshTagId, for: indexPath) as! RefreshFilterBarCell
                refreshCell.delegate = self
                var displayText = "Search Terms"
                refreshCell.uploadLocations.text = displayText
                refreshCell.uploadLocations.font =  UIFont.boldSystemFont(ofSize: 10)
                refreshCell.uploadLocations.textColor = UIColor.ianBlackColor()
                refreshCell.uploadLocations.sizeToFit()
                refreshCell.backgroundColor = isSelected ? UIColor.ianOrangeColor() : UIColor.clear
                refreshCell.layoutIfNeeded()

                return refreshCell

            } else {
                    let filterCell = collectionView.dequeueReusableCell(withReuseIdentifier: filterTagId, for: indexPath) as! SelectedFilterBarCell
        //            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: addTagId, for: indexPath) as! HomeFilterBarCell
                    var displayTerm = searchTerms[indexPath.item - 1]
                    var isEmoji = displayTerm.containsOnlyEmoji
                
                    filterCell.searchTerm = displayTerm

                    if let text = EmojiDictionary[displayTerm] {
                        displayTerm += " \(text.capitalizingFirstLetter())"
                    }
                

                    filterCell.uploadLocations.text = displayTerm.capitalizingFirstLetter()
                    filterCell.uploadLocations.sizeToFit()
                    print("Filter Cell | \(filterCell.uploadLocations.text) | \(indexPath.item - 1)")

                
                
                filterCell.uploadLocations.font =  isEmoji ? UIFont(name: "Poppins-Bold", size: 12) : UIFont(name: "Poppins-Regular", size: 12)
                    filterCell.uploadLocations.textColor = UIColor.ianBlackColor()
                filterCell.layer.borderColor = filterCell.uploadLocations.textColor.cgColor

                    filterCell.uploadLocations.sizeToFit()
                    filterCell.delegate = self
        //            filterCell.backgroundColor = UIColor.mainBlue()
                    filterCell.isUserInteractionEnabled = true
                    filterCell.layoutIfNeeded()
                    return filterCell

            }
        }
    // NO FILTER SELECTED
        else {
            if indexPath.item == 0 {
            
                var displayText = "Top\nEmojis"
                
                if self.viewFilter.filterSort == sortNew {
                    displayText = "Recent\nEmojis"
                } else if self.viewFilter.filterSort == sortNearest {
                    displayText = "Nearest\nEmojis"
                } else if self.viewFilter.filterSort == sortTrending {
                    displayText = "Trending\nEmojis"
                }

                cell.uploadLocations.text = displayText
                cell.uploadLocations.font =  UIFont.boldSystemFont(ofSize: 12)
                cell.uploadLocations.textColor = UIColor.ianGrayColor()
                cell.uploadLocations.sizeToFit()
                cell.backgroundColor = isSelected ? UIColor.ianOrangeColor() : UIColor.clear
                return cell

            } else {
                let option = (displayedEmojis.count == 0) ? listDefaultEmojis[indexPath.item - 1].lowercased() : displayedEmojis[indexPath.item - 1].lowercased()
                var isSelected = self.viewFilter.filterCaption?.contains(option) ?? false
                cell.uploadLocations.text = option
                cell.uploadLocations.font =  UIFont(name: "Poppins-Bold", size: 20)
                cell.uploadLocations.textColor = UIColor.ianBlackColor()

                cell.uploadLocations.sizeToFit()
                cell.backgroundColor = isSelected ? UIColor.ianOrangeColor() : UIColor.clear
                return cell

            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let emoji = displayedEmojis[indexPath.item].lowercased()
        
        if self.viewFilter.isFiltering {
            print("Open search From Emoji CV")
            self.delegate?.didTapSearchButton()
//            return
            /*
            if indexPath.row == 0 {
                self.delegate?.handleRefresh()
                print("CollectionView | Refres All Filter")
            } else {
                let removeTag = searchTerms[indexPath.row - 1]
                print("CollectionView | Remove Filter Selected")
                self.didRemoveTag(tag: removeTag)
            }
             */

        }
        
        else if indexPath.row == 0 {
            return
        } else {
            let emoji = (displayedEmojis.count == 0) ? listDefaultEmojis[indexPath.row - 1].lowercased() : displayedEmojis[indexPath.row - 1].lowercased()
            print("\(emoji) SELECTED")

            self.delegate?.didTapAddTag(addTag: emoji)
        }
    }
    
    func didRemoveTag(tag: String) {
        self.delegate?.didRemoveTag(tag: tag)
    }

    
}


// MARK: - SEARCHBAR DELEGATES

extension LegitHomeHeader: UISearchBarDelegate {
    
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
//        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(attributes, for: .normal)
        
        
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
                if self.viewFilter.isFiltering {
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
        self.delegate?.didTapAddTag(addTag: text)
//        self.delegate?.filterContentForSearchText(text)
        self.delegate?.handleFilter()

    }
    
    
}

// MARK: - SEGMENT CONTROL DELEGATES


extension LegitHomeHeader: postViewFormatSegmentControlDelegate, postSortSegmentControlDelegate {
   
   
   func postFormatSelected(format: String) {
       if format == postGrid && !isGridView {
           self.delegate?.didTapGridButton()
       } else if format == postList && isGridView {
           self.delegate?.didTapGridButton()
       }
   }
   
   func headerSortSelected(sort: String) {
       self.delegate?.headerSortSelected(sort: sort)
   }
   
    func setupSegmentControl() {
        TemplateObjects.postSortDelegate = self
        sortSegmentControl.selectedSegmentIndex = 0
    }

    
    func refreshSegmentValues() {
        
        if let sort = self.viewFilter.filterSort {
            if let index = HeaderSortOptions.firstIndex(of: sort) {
                self.sortSegmentControl.selectedSegmentIndex = index
            } else {
                self.sortSegmentControl.selectedSegmentIndex = 0
            }
        }
        
    }
    
    @objc func toggleSort() {
        let currentSort = self.viewFilter.filterSort ?? defaultRecentSort
        var newIndex = (HeaderSortOptions.firstIndex(of: currentSort) ?? 0) + 1
        newIndex = (newIndex >= HeaderSortOptions.count) ? 0 : newIndex
        var newSort = HeaderSortOptions[newIndex]
        print(" LegitHomeHeader | toggleSort | \(newSort)")
        self.viewFilter.filterSort = newSort
//        self.refreshNavSort()
        self.delegate?.headerSortSelected(sort: newSort)
    }
    
    func setupFormatSegmentControl() {
//        formatSegmentControl = TemplateObjects.PostFormatSegmentControl()
        TemplateObjects.postFormatDelegate = self
//        formatSegmentControl.addTarget(self, action: #selector(selectFormat), for: .valueChanged)
        
        
        formatSegmentControl.selectedSegmentIndex = 0
        
    }
    
    @objc func selectFormat(sender: UISegmentedControl) {
        
        if (sender.selectedSegmentIndex == 0) && !self.isGridView {
            self.delegate?.didTapGridButton()
        } else if (sender.selectedSegmentIndex == 1) && self.isGridView {
            self.delegate?.didTapGridButton()
        }
        
    }

        
    

    

}


//        navMapButton.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor).isActive = true



//
//
//        bottomView.addSubview(navSearchButton)
//        navSearchButton.anchor(top: nil, left: bottomView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 30, height: 30)
//        navSearchButton.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor).isActive = true
//        navSearchButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapSearchButton)))
//

//        bottomView.addSubview(navGridButton)
//        navGridButton.anchor(top: nil, left: nil, bottom: nil, right: navMapButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: 70, height: 30)
//        navGridButton.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor).isActive = true
//        navGridButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapGridButton)))
//
//
//        setupEmojiCollectionView()
//        bottomView.addSubview(emojiCollectionView)
//        emojiCollectionView.anchor(top: nil, left: navSearchButton.rightAnchor, bottom: nil, right: navGridButton.leftAnchor, paddingTop: 0, paddingLeft: 15, paddingBottom: 1, paddingRight: 15, width: 0, height: 30)
//        emojiCollectionView.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor).isActive = true
//        // LOADS IN DEFAULT EMOJIS
//        emojiCollectionView.reloadData()
//
//
//// FULL SEARCH BAR VIEW
//
//        bottomView.addSubview(fullSearchBarView)
//        fullSearchBarView.anchor(top: navSearchButton.topAnchor, left: navSearchButton.leftAnchor, bottom: navSearchButton.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//
//        fullSearchBarWidth = fullSearchBarView.rightAnchor.constraint(equalTo: navMapButton.rightAnchor, constant: 0)
//        halfSearchBarWidth = fullSearchBarView.rightAnchor.constraint(equalTo: emojiCollectionView.rightAnchor, constant: 0)
//        halfSearchBarWidth?.isActive = true
////        fullSearchBarWidth?.isActive = true
//
//        fullSearchBarView.layer.borderColor = UIColor.ianBlackColor().cgColor
//        fullSearchBarView.layer.borderWidth = 1
//        fullSearchBarView.backgroundColor = UIColor.white
//
//        fullSearchBarView.addSubview(fullSearchBarCancelButton)
//        fullSearchBarCancelButton.anchor(top: nil, left: nil, bottom: nil, right: fullSearchBarView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 20, height: 20)
//        fullSearchBarCancelButton.centerYAnchor.constraint(equalTo: fullSearchBarView.centerYAnchor).isActive = true
//
//
//        setupSearchBar()
//
//        fullSearchBarView.addSubview(fullSearchBar)
//        fullSearchBar.anchor(top: fullSearchBarView.topAnchor, left: fullSearchBarView.leftAnchor, bottom: fullSearchBarView.bottomAnchor, right: fullSearchBarCancelButton.leftAnchor, paddingTop: 3, paddingLeft: 10, paddingBottom: 3, paddingRight: 5, width: 0, height: 0)
//
//
//        fullSearchBarView.addSubview(navSearchButtonFull)
//        navSearchButtonFull.layer.borderWidth = 0
//        navSearchButtonFull.anchor(top: fullSearchBarView.topAnchor, left: fullSearchBarView.leftAnchor, bottom: fullSearchBarView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 30, height: 30)
//
//
//        fullSearchBarView.alpha = 0

// HALF SEARCH BAR VIEW
        
//        bottomView.addSubview(halfSearchBarView)
//        halfSearchBarView.anchor(top: navSearchButton.topAnchor, left: navSearchButton.leftAnchor, bottom: navSearchButton.bottomAnchor, right: navGridButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
//        halfSearchBarView.layer.borderColor = UIColor.ianBlackColor().cgColor
//        halfSearchBarView.layer.borderWidth = 1
//        halfSearchBarView.backgroundColor = UIColor.white

//    func refreshNavSort(){
//        let sort = self.viewFilter.filterSort ?? defaultRecentSort
//        let sortString = sortDictionary[sort] ?? ""
//
//        var attributedHeaderTitle = NSMutableAttributedString(string: sortString, attributes: [
//            .font: UIFont.systemFont(ofSize: 14.0, weight: .bold),
//            .foregroundColor: UIColor.ianLegitColor()
//        ])
//
//        attributedHeaderTitle.append(NSMutableAttributedString(string: " IN", attributes: [
//            .font: UIFont.systemFont(ofSize: 14.0, weight: .bold),
//            .foregroundColor: UIColor.ianBlackColor()
//            ]))
//
//
//        if attributedHeaderTitle != self.navSortLabel.attributedText {
//            UIView.transition(with: navSortLabel,
//                              duration: 0.5,
//                              options: [.transitionFlipFromBottom],
//                              animations: {
//
//                                self.navSortLabel.attributedText = attributedHeaderTitle
//                                self.navSortLabel.sizeToFit()
//
//            },
//                              completion: nil)
//        }
//
//    }
//
           /*
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
*/
