//
//  SortFilterHeader.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 12/28/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import DropDown

protocol TabListHeaderDelegate {
    func openSearch(index: Int?)
    func clearCaptionSearch()
    func didTapEmoji(index: Int?, emoji: String)
    func displaySort(sort: String?)
    func showDropDown()
    //    func didChangeToPostView()
    //    func didChangeToGridView()
    //    //    func didSignOut()
    //    //    func activateSearchBar()
    //    func openFilter()
    //    func headerSortSelected(sort: String)
    //    func openMap()
}

class TabListHeader: UICollectionViewCell, UISearchBarDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, EmojiButtonArrayDelegate {
    
    
    let emojiCollectionView: UICollectionView = {
        let uploadEmojiList = UICollectionViewFlowLayout()
        uploadEmojiList.estimatedItemSize = CGSize(width: 30, height: 30)
        uploadEmojiList.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadEmojiList)
        cv.layer.borderWidth = 0
        cv.backgroundColor = UIColor.white
        return cv
    }()
    
    var delegate: TabListHeaderDelegate?
    
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
                self.searchBar.text?.removeAll()
                return}
            self.searchBar.text = selectedCaption
        }
    }
    
    
    
    var sortOptions: [String] = ListSortOptions
    var selectedSort: String = ListSortDefault {
        didSet{
            self.delegate?.displaySort(sort: selectedSort)
            //            self.listSortButton.setTitle(selectedSort + "  ", for: .normal)
        }
    }
    
    
    lazy var listSortButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(showDropDown), for: .touchUpInside)
        //        button.layer.backgroundColor = UIColor.darkLegitColor().withAlphaComponent(0.8).cgColor
        //        button.layer.backgroundColor = UIColor.lightSelectedColor().cgColor
        button.layer.backgroundColor = UIColor.white.cgColor
        
        //        button.setTitleColor(UIColor(hexColor: "f10f3c"), for: .normal)
        //        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 13)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.ianLegitColor().cgColor
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        return button
    }()
    
    var headerSortSegment = UISegmentedControl()

    var isFiltering: Bool = false {
        didSet{
            filterButton.backgroundColor = isFiltering ? UIColor.legitColor() : UIColor.clear
            filterButton.setImage((isFiltering ? #imageLiteral(resourceName: "search_unselected")  : #imageLiteral(resourceName: "search_selected")).withRenderingMode(.alwaysOriginal), for: .normal)
        }
    }
    
    lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "search_selected").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(openFilter), for: .touchUpInside)
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.clipsToBounds = true
        return button
    }()
    
    @objc func openFilter(){
        //        self.delegate?.openFilter()
    }
    
    
    func didTapEmoji(index: Int?, emoji: String) {
        guard let index = index else {
            print("No Index For emoji \(emoji)")
            return
        }
        self.delegate?.didTapEmoji(index: index, emoji: emoji)
        
    }
    
    var dropDownMenu = DropDown()
    func setupDropDown(){
        dropDownMenu.anchorView = listSortButton
        dropDownMenu.dismissMode = .automatic
        dropDownMenu.textColor = UIColor.ianLegitColor()
        dropDownMenu.textFont = UIFont(name: "Poppins-Bold", size: 17)!
        dropDownMenu.backgroundColor = UIColor.white
        //        dropDownMenu.selectionBackgroundColor = UIColor.ianLegitColor().withAlphaComponent(0.75)
        dropDownMenu.selectionBackgroundColor = UIColor.ianOrangeColor().withAlphaComponent(0.75)
        
        dropDownMenu.cellHeight = 50
        dropDownMenu.cornerRadius = 5
        dropDownMenu.shadowColor = UIColor.gray
        
        
        //        dropDownMenu.selectRow(0)
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        //        self.updateDropDownCount()
        
        dropDownMenu.dataSource = ListSortOptions
        dropDownMenu.selectionAction = { [unowned self] (index: Int, item: String) in
            print("Selected item: \(item) at index: \(index)")
            self.selectedSort = self.dropDownMenu.dataSource[index]
            //            self.listSortButton.setTitle(self.selectedSort, for: .normal)
            self.dropDownMenu.hide()
            
        }
        
        if let index = self.dropDownMenu.dataSource.firstIndex(of: self.selectedSort) {
            print("DropDown Menu Preselect \(index) \(self.dropDownMenu.dataSource[index])")
            dropDownMenu.selectRow(index)
        }
    }
    var createdListCount: Int = 0
    var followingListCount: Int = 0
    
    @objc func showDropDown(){
        if self.dropDownMenu.isHidden{
            self.dropDownMenu.show()
        } else {
            self.dropDownMenu.hide()
        }
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
        return displayedEmojis.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emojiCellID, for: indexPath) as! UploadEmojiCell
        let displayEmoji = self.displayedEmojis[indexPath.item]
        let isFiltered = selectedCaption?.contains(displayEmoji) ?? false
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let index = indexPath.row
        let emoji = self.displayedEmojis[indexPath.row]
        
        self.delegate?.didTapEmoji(index: indexPath.row, emoji: self.displayedEmojis[indexPath.row])
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
    var searchBar = UISearchBar()
    
    var emojiArray = EmojiButtonArray(emojis: [], frame: CGRect(x: 0, y: 0, width: 0, height: 20))
    
    var displayedEmojis: [String] = [] {
        didSet {
            print("HomtSearchBarHeader | \(displayedEmojis.count) Emojis")
            self.emojiCollectionView.reloadData()
            //            print("emojiCollectionView | \(self.emojiCollectionView.numberOfItems(inSection: 0))")
            //            emojiArray.emojiLabels = self.displayedEmojis
            //            emojiArray.setEmojiButtons()
            //            emojiArray.sizeToFit()
        }
    }
    
    
    lazy var infoButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        button.layer.backgroundColor = UIColor.white.cgColor
        button.setImage(#imageLiteral(resourceName: "info"), for: .normal)
        button.tintColor = UIColor.darkGray
        button.layer.cornerRadius = 25/2
        button.clipsToBounds = true
        button.titleLabel?.textColor = UIColor.ianLegitColor()
        button.titleLabel?.font = UIFont(font: .avenirNextBold, size: 12)
        button.contentHorizontalAlignment = .center
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        self.backgroundColor  = UIColor.rgb(red: 249, green: 249, blue: 249)
        // Add Search Bar
        //        searchBarView.backgroundColor = UIColor.legitColor()
        searchBarView.backgroundColor = UIColor.rgb(red: 249, green: 249, blue: 249)
        
        addSubview(searchBarView)
        searchBarView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 60)
        searchBarView.layer.applySketchShadow()
        
        addSubview(listSortButton)
        listSortButton.anchor(top: searchBarView.topAnchor, left: nil, bottom: searchBarView.bottomAnchor, right: searchBarView.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 10, width: 0, height: 30)
        listSortButton.setTitle(self.selectedSort, for: .normal)
        listSortButton.sizeToFit()
        
        
        //        addSubview(infoButton)
        //        infoButton.anchor(top: nil, left: nil, bottom: nil, right: searchBarView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        //        infoButton.centerYAnchor.constraint(equalTo: searchBarView.centerYAnchor).isActive = true
        
        //        emojiArray.alignment = .right
        //        emojiArray.delegate = self
        //        addSubview(emojiArray)
        //        emojiArray.anchor(top: nil, left: nil, bottom: nil, right: searchBarView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 0, height: 20)
        //        emojiArray.centerYAnchor.constraint(equalTo: searchBarView.centerYAnchor).isActive = true
        //        emojiArray.backgroundColor = UIColor.yellow
        
        
        
        setupSearchBar()
        searchBarView.addSubview(searchBar)
        searchBar.anchor(top: nil, left: searchBarView.leftAnchor, bottom: nil, right: listSortButton.leftAnchor, paddingTop: 15, paddingLeft: 10, paddingBottom: 25, paddingRight: 10, width: 0, height: 30)
        //        defaultSearchBar.centerYAnchor.constraint(equalTo: searchBarView.centerYAnchor).isActive = true
        
        setupEmojiCollectionView()
        addSubview(emojiCollectionView)
        emojiCollectionView.anchor(top: searchBarView.topAnchor, left: searchBar.rightAnchor, bottom: searchBarView.bottomAnchor, right: searchBarView.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 120, height: 0)
        emojiCollectionView.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor).isActive = true
        searchBar.rightAnchor.constraint(equalTo: emojiCollectionView.leftAnchor).isActive = true
        
        
        
        // ADD MAP BUTTON
        //        addSubview(mapButton)
        //        mapButton.anchor(top: searchBarView.bottomAnchor, left: nil, bottom: bottomAnchor, right: rightAnchor, paddingTop: 3, paddingLeft: 0, paddingBottom: 2, paddingRight: 20, width: 0, height: 0)
        //        mapButton.widthAnchor.constraint(equalTo: mapButton.heightAnchor, multiplier: 1).isActive = true
        
        //  Add Sort Options
        //        headerSortSegment = UISegmentedControl(items: sortOptions)
        //        headerSortSegment.selectedSegmentIndex = sortOptions.index(of: self.selectedSort)!
        //        headerSortSegment.addTarget(self, action: #selector(selectSort), for: .valueChanged)
        //        headerSortSegment.tintColor = UIColor(hexColor: "107896")
        //        headerSortSegment.tintColor = UIColor.legitColor()
        //        headerSortSegment.backgroundColor = UIColor.white
        //        headerSortSegment.layer.cornerRadius = 0
        //        headerSortSegment.layer.borderColor = UIColor.legitColor().cgColor
        //        headerSortSegment.layer.borderWidth = 1
        //        headerSortSegment.layer.masksToBounds = true
        
        
        //        addSubview(headerSortSegment)
        //        headerSortSegment.anchor(top: searchBarView.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 3, paddingLeft: 20, paddingBottom: 2, paddingRight: 20, width: 0, height: 0)
        
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
    
    let searchBarPlaceholder = "Search List"
    
    func setupSearchBar(){
        searchBar.delegate = self
        searchBar.tintColor = UIColor.ianLegitColor()
        searchBar.isTranslucent = true
        searchBar.searchBarStyle = .prominent
        searchBar.barTintColor = UIColor.backgroundGrayColor()
        searchBar.layer.borderWidth = 1
        searchBar.layer.borderColor = UIColor.backgroundGrayColor().cgColor
        
        searchBar.layer.masksToBounds = true
        searchBar.clipsToBounds = true
        
        
        var iconImage = #imageLiteral(resourceName: "search_tab_fill").withRenderingMode(.alwaysTemplate)
        searchBar.setImage(iconImage, for: .search, state: .normal)
        searchBar.setSerchTextcolor(color: UIColor.ianLegitColor())
        var searchTextField: UITextField? = searchBar.value(forKey: "searchField") as? UITextField
        if searchTextField!.responds(to: #selector(getter: UITextField.attributedPlaceholder)) {
            let attributeDict = [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor()]
            searchTextField!.attributedPlaceholder = NSAttributedString(string: searchBarPlaceholder, attributes: attributeDict)
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
                s.layer.backgroundColor = UIColor.clear.cgColor
                s.backgroundColor = UIColor.white
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
    
    // Set Up Range Picker for Distance Filtering
    
    lazy var dummyTextView: UITextView = {
        let tv = UITextView()
        return tv
    }()
    
    var pickerView: UIPickerView = {
        let pv = UIPickerView()
        pv.backgroundColor = .white
        pv.showsSelectionIndicator = true
        return pv
    }()
    
    func setupSortPicker() {
        var toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        
        toolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Select Sort", style: UIBarButtonItem.Style.bordered, target: self, action: Selector("donePicker"))
        doneButton.setTitleTextAttributes(convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.legitColor()]), for: .normal)
        
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.bordered, target: self, action: Selector("cancelPicker"))
        cancelButton.setTitleTextAttributes(convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.red]), for: .normal)
        
        var toolbarTitle = UILabel()
        //        toolbarTitle.text = "Select Range"
        toolbarTitle.textAlignment = NSTextAlignment.center
        let toolbarTitleButton = UIBarButtonItem(customView: toolbarTitle)
        
        let space1Button = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let space2Button = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        
        toolBar.setItems([cancelButton,space1Button, toolbarTitleButton,space2Button, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        
        pickerView.delegate = self
        pickerView.dataSource = self
        self.dummyTextView.inputView = pickerView
        self.dummyTextView.inputAccessoryView = toolBar
        self.addSubview(dummyTextView)
        self.listSortButton.setTitle(self.selectedSort + "🔽", for: .normal)
    }
    
    // UIPicker Delegate Functions
    
    func activateSort() {
        let rangeIndex = sortOptions.firstIndex(of: self.selectedSort)
        pickerView.selectRow(rangeIndex!, inComponent: 0, animated: false)
        dummyTextView.perform(#selector(becomeFirstResponder), with: nil, afterDelay: 0.1)
    }
    
    func donePicker(){
        self.selectedSort = sortOptions[pickerView.selectedRow(inComponent: 0)]
        print("Sort Selected: \(self.selectedSort)")
        dummyTextView.resignFirstResponder()
        //        delegate?.headerSortSelected(sort: self.selectedSort)
    }
    
    func cancelPicker(){
        dummyTextView.resignFirstResponder()
    }
    
    
    // UIPicker DataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
        
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return sortOptions.count
    }
    
    // UIPicker Delegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        var options = sortOptions[row]
        return options
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectedSort = sortOptions[pickerView.selectedRow(inComponent: 0)]
        print("Sort Selected: \(self.selectedSort)")
        dummyTextView.resignFirstResponder()
        //        delegate?.headerSortSelected(sort: self.selectedSort)
        // If Select some number
        //        self.selectedRange = selectedRangeOptions[row]
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
