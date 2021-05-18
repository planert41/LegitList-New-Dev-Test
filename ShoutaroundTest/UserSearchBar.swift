//
//  BottomSearchBar.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 5/28/20.
//  Copyright © 2020 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit


protocol UserSearchBarDelegate {
    func filterContentForSearchText(searchText: String)
    func didTapSearchButton()
    func didTapAddTag(addTag: String)
    func didRemoveTag(tag: String)
    func didRemoveLocationFilter(location: String)
    func didRemoveRatingFilter(rating: String)
    func didTapCell(tag: String)
    func handleRefresh()
    func didActivateSearchBar()
    func didTapGridButton()
    func didTapEmojiButton()
    func didTapEmojiBackButton()
}


class UserSearchBar: UIView, UISearchBarDelegate {
    
    
    var fullSearchBar = UISearchBar()
    var navSearchButton: UIButton = TemplateObjects.NavSearchButton()
    var delegate: UserSearchBarDelegate?
    
// SEARCH TERMS
    
    let addTagId = "addTagId"
    let filterTagId = "filterTagId"
    let emojiTitleTagId = "refreshTagId"
    var searchTerms: [String] = []
    var searchTermsType: [String] = []

    var filteredPostCount = 0 {
        didSet {
            updateFilteringLabel()
        }
    }
    var viewFilter: Filter = Filter.init(defaultSort: defaultRecentSort) {
        didSet {
//            if viewFilter.isFiltering {
//                self.showingEmojiBar = false
//            }
            
            if viewFilter.searchTerms.count > 0 {
                self.showingEmojiBar = true
            } else {
                self.showingEmojiBar = false
            }
            
            self.navSearchButton.setTitle((viewFilter.isFiltering || showingEmojiBar) ? "" : " Filter", for: .normal)
            updateFilteringLabel()
            updateSearchTerms()
            toggleBarView()
        }
    }
    
    let refreshButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "refresh_blue"), for: .normal)
//        button.setImage(#imageLiteral(resourceName: "refresh_white"), for: .normal)
        button.addTarget(self, action: #selector(handleRefresh), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()
    
    
    let filteringLabel: LightPaddedUILabel = {
        let label = LightPaddedUILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 11)
        label.textColor = UIColor.ianBlackColor()
//        label.textColor = UIColor.ianLegitColor()
        label.textAlignment = NSTextAlignment.center
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 2
        return label
    }()
    

    
    var filteredEmojis: [String] = [] {
        didSet {
//            print("Bottom Emoji Bar | \(displayedEmojis.count) Emojis")
            self.refreshEmojiCollectionView()
        }
    }
    
    var listDefaultEmojis = mealEmojisSelect
    
        
    var navEmojiButton: UIButton = TemplateObjects.NavSearchButton()
    var isDisplayingTopEmojis: Bool = false
    var displayedEmojis: [String] = [] {
        didSet {
//            print("UserSearchBar | Displayed Emojis: \(self.displayedEmojis.count)")
            self.refreshEmojiCollectionView()
            self.updateEmojiButton()
        }
    }
    
    var displayedEmojisCounts: [String:Int] = [:] {
        didSet {
            let temp = self.displayedEmojisCounts.sorted(by: {$0.value > $1.value})
            var tempArray: [String] = []
            for (key, value) in temp {
                if value > 0 {
                    tempArray.append(key)
                }
            }
//            print("EmojiSummaryCV | \(displayUser?.username) | Loaded displayedEmojisCounts : \(displayedEmojisCounts.count) | \(displayedEmojisCounts)")
            self.displayedEmojis = tempArray

        }
    }
    
    
    
    let emojiCollectionView: UICollectionView = {
        let uploadEmojiList = UICollectionViewFlowLayout()
//        uploadEmojiList.estimatedItemSize = CGSize(width: 120, height: 35)
        uploadEmojiList.estimatedItemSize = CGSize(width: 60, height: 35)

        uploadEmojiList.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        uploadEmojiList.scrollDirection = .horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadEmojiList)
        cv.layer.borderWidth = 0
        cv.backgroundColor = UIColor.white
        return cv
    }()
    let tapEmojiCollectionView = UITapGestureRecognizer(target: self, action: #selector(didTapSearchButton))
    var filteringView = UIView()
    let searchBarView = UIView()
    var showingEmojiBar = false {
        didSet {
            self.toggleBarView()
        }
    }
    
    
    var navGridToggleButton: UIButton = TemplateObjects.gridFormatButton()
    var isGridView = false {
        didSet {
            var image = isGridView ? #imageLiteral(resourceName: "grid") : #imageLiteral(resourceName: "listFormat")
            self.navGridToggleButton.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
            self.navGridToggleButton.setTitle(isGridView ? "Grid " : "List ", for: .normal)
        }
        
    }
    var navGridButtonWidth: NSLayoutConstraint?
    
    var showEmoji: Bool = false {
        didSet {
            if self.showEmoji {
                navEmojiButton.isHidden = false
//                navGridToggleButton.isHidden = true
            } else {
                navEmojiButton.isHidden = true
//                navGridToggleButton.isHidden = false
            }
//            fullSearchBar.rightAnchor.constraint(equalTo: navGridToggleButton.leftAnchor, constant: 5).isActive = !navGridToggleButton.isHidden
//            fullSearchBar.rightAnchor.constraint(equalTo: navEmojiButton.leftAnchor, constant: 5).isActive = !navEmojiButton.isHidden
        }
    }
    
    
    // NAV BUTTONS
    lazy var navBackButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        let icon = #imageLiteral(resourceName: "back_icon").withRenderingMode(.alwaysTemplate)
        button.setImage(icon, for: .normal)
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.borderColor = UIColor.ianLegitColor().cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 2
        button.clipsToBounds = true
        button.contentHorizontalAlignment = .center
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        button.tintColor = UIColor.ianBlackColor()
        button.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
        return button
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        searchBarView.backgroundColor = UIColor.ianWhiteColor()
        addSubview(searchBarView)
        searchBarView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
//        searchBarView.addSubview(navEmojiButton)
//        navEmojiButton.anchor(top: searchBarView.topAnchor, left: nil, bottom: searchBarView.bottomAnchor, right: searchBarView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 15, width: 0, height: 0)
//        navEmojiButton.addTarget(self, action: #selector(didTapNavEmoji), for: .touchUpInside)
//        navEmojiButton.layer.cornerRadius = 5
//        navEmojiButton.layer.masksToBounds = true
//        navEmojiButton.tintColor = UIColor.gray
//        navEmojiButton.layer.borderColor = UIColor.gray.cgColor
//        navEmojiButton.setTitleColor(UIColor.gray, for: .normal)
//        navEmojiButton.backgroundColor = UIColor.clear
//        navEmojiButton.layer.borderWidth = 0
//        navEmojiButton.isHidden = true
//        updateEmojiButton()
        
        addSubview(navGridToggleButton)
        navGridToggleButton.anchor(top: nil, left: nil, bottom: nil, right: searchBarView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 15, width: 0, height: 35)
        navGridButtonWidth = navGridToggleButton.widthAnchor.constraint(equalToConstant: 60)
        navGridButtonWidth?.isActive = true
        navGridToggleButton.centerYAnchor.constraint(equalTo: searchBarView.centerYAnchor).isActive = true
//        navGridToggleButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        setupnavGridToggleButton()
        
        
//        searchBarView.addSubview(filteringLabel)
//        filteringLabel.anchor(top: searchBarView.topAnchor, left: searchBarView.leftAnchor, bottom: searchBarView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        filteringLabel.textAlignment = .left
//        filteringLabel.layer.cornerRadius = 5
//        filteringLabel.layer.masksToBounds = true
//        filteringLabel.backgroundColor = UIColor.clear
        
        setupSearchBar()
        searchBarView.addSubview(fullSearchBar)
        fullSearchBar.anchor(top: searchBarView.topAnchor, left: searchBarView.leftAnchor, bottom: searchBarView.bottomAnchor, right: navGridToggleButton.leftAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
//        fullSearchBar.rightAnchor.constraint(equalTo: navGridToggleButton.leftAnchor, constant: 5).isActive = true
//        fullSearchBar.rightAnchor.constraint(equalTo: navEmojiButton.leftAnchor, constant: 5).isActive = false

        addSubview(filteringView)
        filteringView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: navGridToggleButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        
//        filteringView.addSubview(navSearchButton)
//        navSearchButton.anchor(top: filteringView.topAnchor, left: nil, bottom: filteringView.bottomAnchor, right: filteringView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 15, width: 0, height: 0)
//        navSearchButton.addTarget(self, action: #selector(didTapSearch), for: .touchUpInside)
//        navSearchButton.setTitle(showingEmojiBar ? "" : " Filter", for: .normal)
//        navSearchButton.layer.cornerRadius = 5
//        navSearchButton.layer.masksToBounds = true
//        navSearchButton.tintColor = UIColor.gray
//        navSearchButton.layer.borderColor = UIColor.gray.cgColor
//        navSearchButton.setTitleColor(UIColor.gray, for: .normal)
//        navSearchButton.backgroundColor = UIColor.clear
//        navSearchButton.layer.borderWidth = 0
//        navSearchButton.isHidden = true
        
        filteringView.addSubview(refreshButton)
        refreshButton.anchor(top: filteringView.topAnchor, left: nil, bottom: filteringView.bottomAnchor, right: filteringView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 15, width: 0, height: 0)
        refreshButton.isHidden = true
        
        
        filteringView.addSubview(navBackButton)
        navBackButton.anchor(top: filteringView.topAnchor, left: nil, bottom: filteringView.bottomAnchor, right: filteringView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 15, width: 0, height: 0)
        navBackButton.addTarget(self, action: #selector(didTapEmojiBackButton), for: .touchUpInside)
        
        
//        filteringView.addSubview(filteringLabel)
//        filteringLabel.anchor(top: filteringView.topAnchor, left: filteringView.leftAnchor, bottom: filteringView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        filteringLabel.textAlignment = .left
        
        filteringView.addSubview(emojiCollectionView)
        emojiCollectionView.anchor(top: filteringView.topAnchor, left: filteringView.leftAnchor, bottom: filteringView.bottomAnchor, right: navBackButton.leftAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 40)

//        emojiCollectionView.anchor(top: filteringView.topAnchor, left: filteringLabel.rightAnchor, bottom: filteringView.bottomAnchor, right: navSearchButton.leftAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 40)
        filteringView.isHidden = true
        setupEmojiCollectionView()
        
    }
    
    
    func setupnavGridToggleButton() {
        navGridToggleButton.tintColor = UIColor.ianBlackColor()
        navGridToggleButton.setTitleColor(UIColor.ianBlackColor(), for: .normal)
        navGridToggleButton.titleLabel?.font =  UIFont(font: .avenirNextBold, size: 12)
        navGridToggleButton.backgroundColor = UIColor.white
        navGridToggleButton.isUserInteractionEnabled = true
        navGridToggleButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleView)))
        navGridToggleButton.semanticContentAttribute  = .forceLeftToRight
        navGridToggleButton.layer.cornerRadius = 5
        navGridToggleButton.layer.masksToBounds = true
        navGridToggleButton.layer.borderColor = navGridToggleButton.tintColor.cgColor
        navGridToggleButton.layer.borderWidth = 0
        navGridToggleButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
        navGridToggleButton.backgroundColor = UIColor.clear
    }
    
    @objc func toggleView(){
        if !isGridView {
            self.delegate?.didTapGridButton()
        } else if isGridView {
            self.delegate?.didTapGridButton()
        }
    }
    
    func updateEmojiButton() {
        var emojiButtonText = "🍕"
        if self.displayedEmojis.count > 0 {
            if !self.displayedEmojis[0].isEmptyOrWhitespace() {
                emojiButtonText = self.displayedEmojis[0]
            }
        }

        emojiButtonText += " Emojis"
        navEmojiButton.setTitle(emojiButtonText, for: .normal)
        navEmojiButton.setImage(UIImage(), for: .normal)
    }
    
    func didTapEmojiBackButton(){
        self.delegate?.didTapEmojiBackButton()
        self.hideEmojiBar()
    }
    
    @objc func toggleBarView() {
    // Keep Emoji Bar if Not Filtering

        if showingEmojiBar || self.viewFilter.filterCaptionArray.count > 0 {
            self.showEmojiBar()
        } else {
            self.hideEmojiBar()
        }
    }
    

    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func setupSearchBar() {
//        setup.searchBarStyle = .prominent
        fullSearchBar.searchBarStyle = .default
        fullSearchBar.delegate = self

        fullSearchBar.isTranslucent = true
        fullSearchBar.tintColor = UIColor.ianBlackColor()
        fullSearchBar.tintColor = UIColor.ianWhiteColor()

        fullSearchBar.placeholder = "Filter Posts By Food, Location or Type"
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
        
        
        let filterImage = #imageLiteral(resourceName: "filter_alt").withRenderingMode(.alwaysTemplate)
        fullSearchBar.setImage(filterImage, for: .search, state: .normal)
        
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
    
    @objc func didTapSearch(){
        print("didTapSearch")
        self.delegate?.didTapSearchButton()
    }
    
    @objc func didTapSearchButton(){
        print("didTapSearchButton")
        self.delegate?.didTapSearchButton()
    }

    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.delegate?.filterContentForSearchText(searchText: searchText)
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        self.delegate?.didActivateSearchBar()
        return false
    }
    
    
}

extension UserSearchBar: UICollectionViewDelegate, UICollectionViewDataSource {
 
    
    func setupEmojiCollectionView(){
        emojiCollectionView.backgroundColor = UIColor.clear
        emojiCollectionView.register(HomeFilterBarCell.self, forCellWithReuseIdentifier: addTagId)
        emojiCollectionView.register(SelectedFilterBarCell.self, forCellWithReuseIdentifier: filterTagId)
        emojiCollectionView.register(EmojiBarTitleCell.self, forCellWithReuseIdentifier: emojiTitleTagId)

        emojiCollectionView.delegate = self
        emojiCollectionView.dataSource = self
        emojiCollectionView.showsHorizontalScrollIndicator = false
        emojiCollectionView.isScrollEnabled = true
        emojiCollectionView.isUserInteractionEnabled = true
//        emojiCollectionView.addGestureRecognizer(tapEmojiCollectionView)
        refreshEmojiCollectionView()
    }
    

    func updateSearchTerms() {
        searchTerms = self.viewFilter.searchTerms
        searchTermsType = self.viewFilter.searchTermsType
//        searchTerms = Array(Set(self.viewFilter.searchTerms))
//        print("Bottom Emoji Bar | Selected Filters | \(searchTerms)")
        refreshEmojiCollectionView()
    }
    
    
    @objc func didTapNavEmoji(){
        self.delegate?.didTapEmojiButton()
        showingEmojiBar = true
        refreshEmojiCollectionView()
        navSearchButton.setTitle("", for: .normal)
        navSearchButton.sizeToFit()
    }
    
    func showEmojiBar() {
        searchBarView.isHidden = true
        filteringView.isHidden = false
        navSearchButton.isHidden = !self.viewFilter.isFiltering
        refreshButton.isHidden = !self.viewFilter.isFiltering
        navBackButton.isHidden = self.viewFilter.isFiltering
    }
    
    func hideEmojiBar() {
        searchBarView.isHidden = false
        filteringView.isHidden = true
        navSearchButton.isHidden = !self.viewFilter.isFiltering
        refreshButton.isHidden = !self.viewFilter.isFiltering
        navBackButton.isHidden = self.viewFilter.isFiltering
    }

    
    func updateFilteringLabel() {
        
        var displayText: String = ""

//        if self.viewFilter.isFiltering {
//            displayText = "\(filteredPostCount) \nPosts"
//        } else {
//            displayText = "Top\nEmojis"

//            if self.viewFilter.filterSort == sortNew {
//                displayText = "Recent \nFilter Tags"
//            } else if self.viewFilter.filterSort == sortNearest {
//                displayText = "Nearest \nFilter Tags"
//            } else if self.viewFilter.filterSort == sortTrending {
//                displayText = "Trending \nFilter Tags"
//            } else {
//                displayText = "Top\nFilter Tags"
//            }
//        }
        
        
        displayText = "\(filteredPostCount)\nPosts"

        
        filteringLabel.text = displayText
       // print("filteringLabel :" , displayText)
        filteringLabel.sizeToFit()
    }
    
//    func updateSearchButton() {
//        let search = UITapGestureRecognizer(target: self, action: #selector(didTapSearchButton))
//        navSearchButton.setTitle(self.viewFilter.isFiltering ? "" : " Search", for: .normal)
//        navSearchButtonEqualWidth?.isActive = self.viewFilter.isFiltering
//        navSearchButton.setTitleColor(UIColor.ianBlackColor(), for: .normal)
//        navSearchButton.setImage(#imageLiteral(resourceName: "search_selected").withRenderingMode(.alwaysTemplate), for: .normal)
//        navSearchButton.tintColor = UIColor.ianBlackColor()
//        navSearchButton.layer.borderColor = UIColor.ianBlackColor().cgColor
//        navSearchButton.addGestureRecognizer(search)
//        navSearchButton.sizeToFit()
//    }
    
    func refreshEmojiCollectionView() {
        
        navSearchButton.setTitle(showingEmojiBar ? "" : " Filter", for: .normal)
        navSearchButton.sizeToFit()
        
        if self.viewFilter.isFiltering {
            self.emojiCollectionView.addGestureRecognizer(tapEmojiCollectionView)
        } else {
            self.emojiCollectionView.removeGestureRecognizer(tapEmojiCollectionView)
        }
        self.emojiCollectionView.reloadData()
        self.emojiCollectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .left, animated: false)
        self.emojiCollectionView.sizeToFit()
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        print("UserSearchBar | EmojiCV | \(searchTerms.count)")
        if self.viewFilter.isFiltering {
            return searchTerms.count + 1
        } else {
            return displayedEmojis.count + 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let refreshCell = collectionView.dequeueReusableCell(withReuseIdentifier: refreshTagId, for: indexPath) as! RefreshFilterBarCell
        var isSelected = false
        
        if indexPath.item == 0 {
            let refreshCell = collectionView.dequeueReusableCell(withReuseIdentifier: emojiTitleTagId, for: indexPath) as! EmojiBarTitleCell
            
            var displayText = ""
        
            if self.viewFilter.isFiltering {
                displayText = "\(filteredPostCount) \nPosts"
            } else if self.viewFilter.filterSort == sortNew {
                displayText = "Newest\nEmojis"
            } else if self.viewFilter.filterSort == sortNearest {
                displayText = "Nearest\nEmojis"
            } else if self.viewFilter.filterSort == sortTrending {
                displayText = "Trending\nEmojis"
            } else {
                displayText = "Top\nEmojis"
            }
            
            
            
            refreshCell.emojiTitle.text = displayText
            refreshCell.emojiTitle.sizeToFit()
            refreshCell.backgroundColor = .clear
            refreshCell.emojiTitle.backgroundColor = .clear
            refreshCell.sizeToFit()
            refreshCell.layoutIfNeeded()
            refreshCell.delegate = self
            refreshCell.showSearchButton = true
            return refreshCell
        }
        else
        {
            let filterCell = collectionView.dequeueReusableCell(withReuseIdentifier: filterTagId, for: indexPath) as! SelectedFilterBarCell
            filterCell.delegate = self
            filterCell.isUserInteractionEnabled = true
            filterCell.layer.borderColor = UIColor.lightGray.cgColor
            filterCell.layer.borderWidth = 1
            filterCell.searchTermType = nil

            if self.viewFilter.isFiltering {
        // DISPLAY FILTERED CELLS
                filterCell.searchTerm = searchTerms[indexPath.item - 1].capitalizingFirstLetter()
                filterCell.searchTermType = searchTermsType[indexPath.item - 1]
                filterCell.uploadLocations.sizeToFit()
                filterCell.layoutIfNeeded()
                filterCell.showCancel = true
                return filterCell

            } else {
        // DISPLAY TOP EMOJIS
                var tempEmoji = displayedEmojis[indexPath.row - 1]
                var displayTerm = tempEmoji.capitalizingFirstLetter()
                
                if let text = EmojiDictionary[displayTerm] {
                    displayTerm += " \(text.capitalizingFirstLetter())"
                }
                
                let attributedString = NSMutableAttributedString(string: displayTerm, attributes: [NSAttributedString.Key.font: UIFont(name: "Poppins-Regular", size: 12), NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor()])

            
                if let count = displayedEmojisCounts[tempEmoji]{
                    if count > 0 {
                        let tempAttString = NSMutableAttributedString(string: "  \(count)", attributes: [NSAttributedString.Key.font: UIFont(font: .arialBoldMT, size: 14), NSAttributedString.Key.foregroundColor: UIColor.legitColor()])
                        attributedString.append(tempAttString)
                    }
                }
                filterCell.searchTerm = tempEmoji
                filterCell.searchTermType = SearchCaption
//                filterCell.searchTermCount = displayedEmojisCounts[tempEmoji] ?? 0
                filterCell.searchTermCount = 0
                filterCell.isFiltering = self.viewFilter.searchTerms.contains(tempEmoji)
                filterCell.showCancel = false
                filterCell.uploadLocations.sizeToFit()
                return filterCell
            }
        }
 
    }
    
    
}


extension UserSearchBar: RefreshFilterBarCellDelegate, SelectedFilterBarCellDelegate, EmojiBarTitleCellDelegate {
    func didRemoveTag(tag: String) {
//        self.delegate?.didRemoveTag(tag: tag)

        if self.viewFilter.searchTerms.contains(tag) {
            self.delegate?.didRemoveTag(tag: tag)
        } else {
            self.delegate?.didTapAddTag(addTag: tag)
        }
    }
    
    func didRemoveLocationFilter(location: String) {
        self.delegate?.didRemoveLocationFilter(location: location)
    }
    
    func didRemoveRatingFilter(rating: String) {
        self.delegate?.didRemoveRatingFilter(rating: rating)
    }
    
    func didTapCell(tag: String) {
//        self.delegate?.didTapAddTag(addTag: tag)
        self.didTapSearch()
    }
    
    func didTapEmojiBarTitleCell() {
        self.didTapSearch()
    }

    
    func handleRefresh() {
        self.delegate?.handleRefresh()
//        self.delegate.handlere
    }
    


}
