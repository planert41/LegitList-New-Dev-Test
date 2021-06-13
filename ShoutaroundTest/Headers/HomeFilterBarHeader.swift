//
//  SortFilterHeader.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 12/28/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit


protocol HomeFilterBarHeaderDelegate {
    func openSearch(index: Int?)
    func clearCaptionSearch()
    func refreshAll()
    func didTapEmoji(index: Int?, emoji: String)
    func didTapAddTag(addTag: String)
    func didTapInfo()
    func showSearchBar()
    func hideSearchBar()

    // Can tap either post type string (breakfast, lunch dinner) or most popular emojis

    //    func didChangeToPostView()
    //    func didChangeToGridView()
    //    //    func didSignOut()
    //    //    func activateSearchBar()
    //    func openFilter()
    //    func headerSortSelected(sort: String)
    //    func openMap()
}

class HomeFilterBarHeader: UICollectionViewCell, UISearchBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource, EmojiButtonArrayDelegate {
    
    
    let emojiCollectionView: UICollectionView = {
        let uploadEmojiList = UICollectionViewFlowLayout()
        uploadEmojiList.estimatedItemSize = CGSize(width: 30, height: 30)
        uploadEmojiList.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadEmojiList)
        cv.layer.borderWidth = 0
        cv.backgroundColor = UIColor.white
        return cv
    }()
    
    let addTagCollectionView: UICollectionView = {
        let uploadLocationTagList = UploadLocationTagList()
        
        uploadLocationTagList.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadLocationTagList)
        cv.layer.borderWidth = 0
        cv.backgroundColor = UIColor.clear
        return cv
    }()
    
    var delegate: HomeFilterBarHeaderDelegate?
    
    // 0 For Default Header Sort Options, 1 for Location Sort Options
    var sortOptionsInd: Int = 0 {
        didSet{
            if sortOptionsInd == 0 {
                sortOptions = HeaderSortOptions
            } else if sortOptionsInd == 1 {
                sortOptions = LocationSortOptions
            } else {
                sortOptions = HeaderSortOptions
            }
        }
    }
    
    var selectedCaption: String? = nil {
        didSet{
            guard let selectedCaption = selectedCaption else {
                self.defaultSearchBar.text?.removeAll()
                return}
            self.defaultSearchBar.text = selectedCaption
        }
    }
    
    var selectedPostType: String? = nil {
        didSet {
            self.addTagCollectionView.reloadData()
            guard let selectedPostType = selectedPostType else {return}
//            if let index = self.addTagOptions.index(of: selectedPostType) {
//                let indexPath = IndexPath(item: index, section: 0)
//                self.addTagCollectionView.scrollToItem(at: indexPath, at: .left, animated: true)
//            }
        }
    }
    
    var sortOptions: [String] = HeaderSortOptions {
        didSet{
            self.updateSegments()
        }
    }
    
    
    
    var headerSortSegment = UISegmentedControl()
    var selectedSort: String = defaultRecentSort {
        didSet{
        }
    }
    var isFiltering: Bool = false {
        didSet{
            filterButton.backgroundColor = isFiltering ? UIColor.legitColor() : UIColor.white
            filterButton.setImage((isFiltering ? #imageLiteral(resourceName: "search_unselected")  : #imageLiteral(resourceName: "search_selected")).withRenderingMode(.alwaysOriginal), for: .normal)
        }
    }
    
    lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "search_tab_fill").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(openFilter), for: .touchUpInside)
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.ianOrangeColor().cgColor
        button.clipsToBounds = true
        return button
    }()
    
    @objc func openFilter(){
//        self.showSearchBar = !self.showSearchBar
        self.delegate?.showSearchBar()
//        self.delegate?.openSearch(index: 0)
    }
    
    lazy var refreshButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysOriginal), for: .normal)
//        button.setImage(#imageLiteral(resourceName: "refresh").withRenderingMode(.alwaysOriginal), for: .normal)

        button.addTarget(self, action: #selector(refreshTags), for: .touchUpInside)
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.clipsToBounds = true
        return button
    }()
    
    @objc func refreshTags(){
        self.didHideSearchBar()
        self.delegate?.refreshAll()
    }
    
    func didTapEmoji(index: Int?, emoji: String) {
        guard let index = index else {
            print("No Index For emoji \(emoji)")
            return
        }
        self.delegate?.didTapEmoji(index: index, emoji: emoji)
        
    }
    
    
    func doubleTapEmoji(index: Int?, emoji: String) {
        
    }
    //    lazy var mapButton: UIButton = {
    //        let button = UIButton(type: .system)
    //        button.setImage(#imageLiteral(resourceName: "googlemap_color").withRenderingMode(.alwaysOriginal), for: .normal)
    //        button.addTarget(self, action: #selector(openMap), for: .touchUpInside)
    //        button.layer.borderWidth = 0
    //        button.layer.borderColor = UIColor.darkGray.cgColor
    //        button.clipsToBounds = true
    //        return button
    //    }()
    //
    //    func openMap(){
    //        self.delegate?.openMap()
    //    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == emojiCollectionView {
            return displayedEmojis.count
        } else if collectionView == addTagCollectionView {
            return addTagOptions.count
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
// EMOJI CELLS
        /*if collectionView == addTagCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emojiCellID, for: indexPath) as! UploadEmojiCell
            //let displayEmoji = self.displayedEmojis[indexPath.item]
            //let isFiltered = selectedCaption?.contains(displayEmoji) ?? false
            let option = addTagOptions[indexPath.item].lowercased()
            let isFiltered = self.displayedTags.contains(option)

            var displayText = ""
            if option.isSingleEmoji {
                displayText = option// + " \((EmojiDictionary[option] ?? "").capitalizingFirstLetter())"
            } else {
                displayText = (ReverseEmojiDictionary[option] ?? "") //+ " \(option.capitalizingFirstLetter())"
            }
            
            
            cell.uploadEmojis.text = displayText
            cell.uploadEmojis.font = cell.uploadEmojis.font.withSize(25)
            cell.layer.borderWidth = 0
            
            //Highlight only if emoji is tagged, dont care about caption
            //        cell.backgroundColor = isFiltered ? UIColor.selectedColor() : UIColor.clear
            cell.backgroundColor = isFiltered ? UIColor.ianLegitColor() : UIColor.clear
            
            cell.layer.borderColor = UIColor.white.cgColor
            cell.isSelected = isFiltered
            cell.sizeToFit()
            return cell
        }*/
        
         if collectionView == addTagCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: addTagId, for: indexPath) as! HomeFilterBarCell
            let option = addTagOptions[indexPath.item].lowercased()
            
            
            // Only Emojis and Post type are tagged. Anything else is a caption search
            
            var displayText = ""
            /*if option.isSingleEmoji {
                displayText = option + " \((EmojiDictionary[option] ?? "").capitalizingFirstLetter())"
            } else {
            }*/
            
            var isSelected: Bool = self.displayedTags.contains(option)

            
            if option.isSingleEmoji {
                displayText = option + (isSelected ? " \((EmojiDictionary[option] ?? "").capitalizingFirstLetter())" : "")
            } else {
                if ReverseEmojiDictionary[option] == nil {
                    displayText = option.capitalizingFirstLetter()
                } else {
                    displayText = (ReverseEmojiDictionary[option] ?? "") + (isSelected ? " \(option.capitalizingFirstLetter())" : "")
                }
            }
            
            
            cell.uploadLocations.text = displayText
            cell.uploadLocations.textColor = isSelected ? UIColor.ianBlackColor() : (defaultMeals.contains(option) ? UIColor.oldLegitColor() : UIColor.gray )
//            cell.uploadLocations.textColor = isSelected ? UIColor.ianBlackColor() : UIColor.lightGray

            cell.uploadLocations.font = isSelected ? UIFont(font: .avenirNextDemiBold, size: 20) : UIFont(font: .avenirNextRegular, size: 25)
            
//            cell.uploadLocations.font = isSelected ? UIFont(name: "Poppins-Bold", size: 13) : UIFont(name: "Poppins-Regular", size: 13)
            cell.layer.borderColor = isSelected ? UIColor.clear.cgColor : (defaultMeals.contains(option) ? UIColor.oldLegitColor().cgColor : UIColor.gray.cgColor )
//            cell.backgroundColor = isSelected ? UIColor.ianOrangeColor() : UIColor.backgroundGrayColor()
            cell.backgroundColor = isSelected ? UIColor.ianOrangeColor() : UIColor.clear

//            cell.layer.borderWidth = isSelected ? 0 : (defaultMeals.contains(option) ? 0.8 : 0.5)
            cell.layer.borderWidth = 0

            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: addTagId, for: indexPath) as! HomeFilterBarCell
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == emojiCollectionView {
            let index = indexPath.row
            let emoji = self.displayedEmojis[indexPath.row]
            self.delegate?.didTapEmoji(index: indexPath.row, emoji: self.displayedEmojis[indexPath.row])
        }
        else if collectionView == addTagCollectionView {
            let option = addTagOptions[indexPath.item].lowercased()
            self.delegate?.didTapAddTag(addTag: option)
        }
        
    }
    
    
    
    // Grid/List View Button
    var isGridView = true {
        didSet{
            formatButton.setImage(!self.isGridView ? #imageLiteral(resourceName: "grid") :#imageLiteral(resourceName: "postview"), for: .normal)
        }
    }
    
    lazy var formatButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(!self.isGridView ? #imageLiteral(resourceName: "postview") :#imageLiteral(resourceName: "grid"), for: .normal)
        button.addTarget(self, action: #selector(changeView), for: .touchUpInside)
        button.tintColor = UIColor.legitColor()
        return button
    }()
    
    @objc func changeView(){
        //        if isGridView{
        //            self.isGridView = false
        //            delegate?.didChangeToPostView()
        //        } else {
        //            self.isGridView = true
        //            delegate?.didChangeToGridView()
        //        }
    }
    
    
    var searchBarView = UIView()
    var defaultSearchBar = UISearchBar()
    
    var emojiArray = EmojiButtonArray(emojis: [], frame: CGRect(x: 0, y: 0, width: 0, height: 20))
    
    var displayedEmojis: [String] = [] {
        didSet {
            print("HomeFilterSearchBarHeader | \(displayedEmojis.count) Emojis")
            self.emojiCollectionView.reloadData()
            //            print("emojiCollectionView | \(self.emojiCollectionView.numberOfItems(inSection: 0))")
            //            emojiArray.emojiLabels = self.displayedEmojis
            //            emojiArray.setEmojiButtons()
            //            emojiArray.sizeToFit()
        }
    }
    
    
    lazy var infoButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.setImage(#imageLiteral(resourceName: "about_logo"), for: .normal)
        button.tintColor = UIColor.darkGray
        button.layer.cornerRadius = 25/2
        button.clipsToBounds = true
        button.titleLabel?.textColor = UIColor.ianLegitColor()
        button.titleLabel?.font = UIFont(font: .avenirNextBold, size: 12)
        button.contentHorizontalAlignment = .center
        button.addTarget(self, action: #selector(tapInfo), for: .touchUpInside)
        return button
    }()
    
    @objc func tapInfo(){
        self.delegate?.didTapInfo()
    }
    
    var hideRefreshButton:NSLayoutConstraint?

    
    override init(frame: CGRect) {
        super.init(frame:frame)
        //        self.backgroundColor  = UIColor.rgb(red: 249, green: 249, blue: 249)
        self.backgroundColor  = UIColor.backgroundGrayColor()
        
        
        // Add Search Bar
        //        searchBarView.backgroundColor = UIColor.legitColor()
        //        searchBarView.backgroundColor = UIColor.rgb(red: 249, green: 249, blue: 249)
        searchBarView.backgroundColor = UIColor.backgroundGrayColor()
        
        addSubview(searchBarView)
        searchBarView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 60)
        searchBarView.layer.applySketchShadow()
        

        addSubview(filterButton)
        filterButton.anchor(top: nil, left: nil, bottom: nil, right: searchBarView.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 10, width: 30, height: 30)
        filterButton.centerYAnchor.constraint(equalTo: searchBarView.centerYAnchor).isActive = true
        filterButton.layer.cornerRadius = 30 / 2
        filterButton.layer.masksToBounds = true
        filterButton.backgroundColor = UIColor.white

        
        addSubview(infoButton)
        infoButton.anchor(top: nil, left: nil, bottom: nil, right: filterButton.leftAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 30, height: 30)
        infoButton.centerYAnchor.constraint(equalTo: searchBarView.centerYAnchor).isActive = true
        infoButton.tintColor = UIColor.selectedColor()
        
        addSubview(refreshButton)
        refreshButton.anchor(top: nil, left: searchBarView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 10, width: 30, height: 30)
        refreshButton.centerYAnchor.constraint(equalTo: searchBarView.centerYAnchor).isActive = true
        
        hideRefreshButton = refreshButton.widthAnchor.constraint(equalToConstant: 0)
        
//        addSubview(filterButton)
//        filterButton.anchor(top: nil, left: refreshButton.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 10, width: 30, height: 30)

//        setupEmojiCollectionView()
//        addSubview(emojiCollectionView)
//        emojiCollectionView.anchor(top: searchBarView.topAnchor, left: nil, bottom: searchBarView.bottomAnchor, right: searchBarView.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 5, paddingRight: 5, width: 80, height: 0)
//        emojiCollectionView.centerYAnchor.constraint(equalTo: searchBarView.centerYAnchor).isActive = true

        setupAddTagCollectionView()
        addSubview(addTagCollectionView)
        addTagCollectionView.anchor(top: searchBarView.topAnchor, left: refreshButton.rightAnchor, bottom: searchBarView.bottomAnchor, right: infoButton.leftAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        addTagCollectionView.centerYAnchor.constraint(equalTo: searchBarView.centerYAnchor).isActive = true
        
        self.refreshFilterBar()
        
        addSubview(defaultSearchBar)
        defaultSearchBar.anchor(top: searchBarView.topAnchor, left: searchBarView.leftAnchor, bottom: searchBarView.bottomAnchor, right: refreshButton.leftAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        defaultSearchBar.isHidden = true
        
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

    }
    
    func keyboardWillHide(_ notification: NSNotification) {
//        self.showSearchBar = false
    }
    
    var showSearchBar: Bool = false {
        didSet {
            if self.defaultSearchBar.isHidden == !showSearchBar {
                return
            }
            
            if showSearchBar {
                self.didShowSearchBar()
            } else {
                self.didHideSearchBar()
            }
        }
    }
    
    func didShowSearchBar(){
        UIView.animate(withDuration: 0.5, delay: TimeInterval(0), options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.defaultSearchBar.isHidden = false
            self.hideRefreshButton?.isActive = false
            self.delegate?.showSearchBar()
        }, completion: { (finished: Bool) in
            self.defaultSearchBar.becomeFirstResponder()
        })
    }
    
    func didHideSearchBar(){
        self.defaultSearchBar.isHidden = true
        self.delegate?.hideSearchBar()
    }
    
    let emojiCellID = "emojiCellID"
    
    var defaultMeals = ["breakfast","lunch","dinner","latenight","other","dessert", "drinks","coffee"]
//    var defaultDrinks = ["coffee", "dessert", "drinks"]
//    var defaultAddTagOptions = ["coffee", "dessert", "drinks","breakfast","brunch","lunch","dinner","latenight","other"]
    var addTagOptions: [String] = []
    
    var addTagId = "addTagID"
    
    var selectedTagCount = 0
    var displayedTags:[String] = []

    
    func refreshFilterBar(){
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        
        var tempAddTagOptions:[String] = []
//        if let index = addTagOptions.index(of: "breakfast") {
//            let element = addTagOptions.remove(at: index)
//            tempAddTagOptions.insert(element, at: 0)
//        }
        var currentRec = ""
        
        if 4 <= hour && hour < 11 {
            currentRec = "breakfast"
            // Move Breakfast To Front
        } else if 11 <= hour && hour < 16 {
            currentRec = "lunch"
        } else if 16 <= hour && hour < 22 {
            currentRec = "dinner"
        } else if 16 <= hour && hour < 22 {
            currentRec = "latenight"
        }
        
        // MOVE Rec to End
        if let index = defaultMeals.firstIndex(of: currentRec) {
            let element = defaultMeals.remove(at: index)
            defaultMeals.insert(element, at: defaultMeals.count - 1)
        }
        
        // ADD SELECTED
        
        // Display Selected Tags First
        displayedTags = []
        
        if self.selectedPostType != nil {
            displayedTags.append(self.selectedPostType!)
        }
        
        if self.selectedCaption != nil {
            var caption = self.selectedCaption ?? ""
            let captionNoEmojis = caption.emojilessString
            if captionNoEmojis.removingWhitespaces() != "" {
                displayedTags.append(captionNoEmojis)
            }
            
            // CHECK FOR FLAGS FIRST
            for (emoji, emojiText) in FlagEmojiDictionary {
                if caption.contains(emoji) {
                    displayedTags.append(emoji)
                    caption = caption.replacingOccurrences(of: emoji, with: "")
                }
            }
            
            let captionEmojis = caption.emojis
            if captionEmojis[0] != "" {
                displayedTags += captionEmojis
            }
        }
        
        var tempDisplayEmojis =  displayedEmojis

        for tag in defaultMeals {
            let mealEmoji = (ReverseEmojiDictionary[tag] ?? "")
            if let index = tempDisplayEmojis.firstIndex(of: mealEmoji) {
                let element = tempDisplayEmojis.remove(at: index)
            }
        }
        
    // REMOVE SELECTED FROM OTHER EMOJIS
        
        for tag in displayedTags {
            if let index = defaultMeals.firstIndex(of: tag) {
                let element = defaultMeals.remove(at: index)
            }
        
            if let index = tempDisplayEmojis.firstIndex(of: tag) {
                let element = tempDisplayEmojis.remove(at: index)
            }
        }
        
        // REMOVE ALL SELECTED TAGS FROM OTHERS
//        for tag in displayedTags {
//            tempAddTagOptions.removeAll { (string) -> Bool in
//                string == tag
//            }
//        }
        
        
    // DEFAULT MEALS + SELECTED EMOJIS + DISPLAY EMOJIS
        tempAddTagOptions = defaultMeals + displayedTags + tempDisplayEmojis
        hideRefreshButton?.isActive = !(displayedTags.count > 0)
        self.addTagOptions = tempAddTagOptions

        
        if displayedTags.count > 0 {
            // Scroll To Selected
            if let index = tempAddTagOptions.firstIndex(of: displayedTags[0]) {
                let indexPath = IndexPath(item: index, section: 0)
                self.addTagCollectionView.scrollToItem(at: indexPath, at: .left, animated: true)
                self.addTagCollectionView.reloadData()
            }
        } else {
            //  Scroll To Coffee
            if let index = tempAddTagOptions.firstIndex(of: currentRec) {
                let indexPath = IndexPath(item: index, section: 0)
                self.addTagCollectionView.scrollToItem(at: indexPath, at: .left, animated: true)
                self.addTagCollectionView.reloadData()
            }
        }
    }
    
    func setupAddTagCollectionView(){
        addTagCollectionView.backgroundColor = UIColor.backgroundGrayColor()
        addTagCollectionView.register(HomeFilterBarCell.self, forCellWithReuseIdentifier: addTagId)
        addTagCollectionView.register(UploadEmojiCell.self, forCellWithReuseIdentifier: emojiCellID)

        addTagCollectionView.delegate = self
        addTagCollectionView.dataSource = self
        addTagCollectionView.showsHorizontalScrollIndicator = false
    }
    
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
    
    func updateSegments(){
        for i in 0..<headerSortSegment.numberOfSegments {
            if headerSortSegment.titleForSegment(at: i) != sortOptions[i] {
                //Update Segment Label
                headerSortSegment.setTitle(sortOptions[i], forSegmentAt: i)
            }
        }
    }
    
    func selectSort(sender: UISegmentedControl) {
        
        //        self.selectedSort = sortOptions[sender.selectedSegmentIndex]
        //        delegate?.headerSortSelected(sort: self.selectedSort)
        //        print("Selected Sort is ",self.selectedSort)
    }
    
    func setupSearchBar(){
        defaultSearchBar.layer.cornerRadius = 5
        defaultSearchBar.layer.masksToBounds = true
        defaultSearchBar.clipsToBounds = true
        //        defaultSearchBar.searchBarStyle = .prominent
        defaultSearchBar.searchBarStyle = .prominent
        
        defaultSearchBar.barTintColor = UIColor.white
        defaultSearchBar.tintColor = UIColor.white
        //        defaultSearchBar.backgroundImage = UIImage()
        defaultSearchBar.layer.borderWidth = 1
        defaultSearchBar.layer.borderColor = UIColor.lightGray.cgColor
        defaultSearchBar.placeholder = "Tap to Search Posts"
        defaultSearchBar.delegate = self
        //        defaultSearchBar.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        //        defaultSearchBar.showsCancelButton = true
        
        
        let textFieldInsideSearchBar = defaultSearchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = UIColor.darkLegitColor()
        textFieldInsideSearchBar?.font = UIFont(font: .avenirNextItalic, size: 14)
        
        for s in defaultSearchBar.subviews[0].subviews {
            if s is UITextField {
                s.backgroundColor = UIColor.white
                
                if let backgroundview = s.subviews.first {
                    
                    //                    // Background color
                    //                                        backgroundview.backgroundColor = UIColor.clear
                    //
                    //                    // Rounded corner
                    //                    backgroundview.layer.cornerRadius = 15;
                    //                    backgroundview.clipsToBounds = true;
                }
                
                //                s.layer.cornerRadius = 25/2
                //                s.layer.borderWidth = 1
                //                s.layer.borderColor = UIColor.gray.cgColor
            }
        }
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        if self.selectedCaption != nil && searchBar.text == "" {
            self.selectedCaption = nil
            return false
        } else {
            self.delegate?.openSearch(index: 0)
            return false
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText.count == 0) {
            searchBar.endEditing(true)
            self.delegate?.clearCaptionSearch()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("Cancel Button")
    }

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
