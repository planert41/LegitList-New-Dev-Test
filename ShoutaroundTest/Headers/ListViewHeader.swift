//
//  SortFilterHeader.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 12/28/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit

protocol ListViewHeaderDelegate {
//    func didChangeToPostView()
//    func didChangeToGridView()
    func changePostFormat(formatInd: Int)
    //    func didSignOut()
    //    func activateSearchBar()
    func openSearch(index: Int?)
    func clearCaptionSearch()
    func openFilter()
    func headerSortSelected(sort: String)
//    func openMap()
}

class ListViewHeader: UICollectionViewCell, UISearchBarDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var delegate: ListViewHeaderDelegate?
    
    // 0 For Default Header Sort Options, 1 for Location Sort Options
    var sortOptionsInd: Int = 0 {
        didSet{
            if sortOptionsInd == 0 {
                sortOptions = ViewListSortOptions
            } else if sortOptionsInd == 1 {
                sortOptions = ViewListSortOptions
            } else {
                sortOptions = ViewListSortOptions
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
    
    
    var sortOptions: [String] = ViewListSortOptions {
        didSet{
            self.updateSegments()
        }
    }
    
    
    lazy var sortButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(activateSort), for: .touchUpInside)
        //        button.layer.backgroundColor = UIColor.darkLegitColor().withAlphaComponent(0.8).cgColor
        button.layer.backgroundColor = UIColor.lightSelectedColor().cgColor
        
        //        button.setTitleColor(UIColor(hexColor: "f10f3c"), for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitleColor(UIColor.darkLegitColor(), for: .normal)
        
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.darkLegitColor().cgColor
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        return button
    }()
    
    var headerSortSegment = UISegmentedControl()
    var selectedSort: String = defaultRecentSort {
        didSet{
            self.sortButton.setTitle(self.selectedSort + " 🔽", for: .normal)
        }
    }
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
    
    func openFilter(){
        self.delegate?.openFilter()
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
    

    var postFormatInd: Int = 0 {
        didSet {
            self.updateFormatButton()
        }
    }
    
    @objc func togglePostFormat(){
        if self.postFormatInd == 2 {
            self.postFormatInd = 0
        } else {
            self.postFormatInd += 1
        }
        self.updateFormatButton()
        self.delegate?.changePostFormat(formatInd: postFormatInd)

    }
    
    func updateFormatButton(){
        switch self.postFormatInd {
        case 0:
            // Grid View
            self.formatButton.setImage(#imageLiteral(resourceName: "grid"), for: .normal)
        case 1:
            // List View
            self.formatButton.setImage(#imageLiteral(resourceName: "list"), for: .normal)
        case 2:
            // Full Post View
            self.formatButton.setImage(#imageLiteral(resourceName: "postview"), for: .normal)
        default:
            self.formatButton.setImage(#imageLiteral(resourceName: "postview"), for: .normal)
        }
    }
    
    lazy var formatButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "postview"), for: .normal)
        button.addTarget(self, action: #selector(togglePostFormat), for: .touchUpInside)
        button.tintColor = UIColor.legitColor()
        return button
    }()
    
    
    // Grid/List View Button
    //    var isGridView = true {
    //        didSet{
    //            formatButton.setImage(!self.isGridView ? #imageLiteral(resourceName: "grid") :#imageLiteral(resourceName: "postview"), for: .normal)
    //        }
    //    }
    //
    
//    func changeView(){
//        if isGridView{
//            self.isGridView = false
//            delegate?.didChangeToPostView()
//        } else {
//            self.isGridView = true
//            delegate?.didChangeToGridView()
//        }
//    }
    
    
    var searchBarView = UIView()
    var defaultSearchBar = UISearchBar()
    
    var customBackgroundColor: UIColor? = nil {
        didSet {
            self.searchBarView.backgroundColor = customBackgroundColor ?? UIColor.white
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        // Add Search Bar
        //        searchBarView.backgroundColor = UIColor.legitColor()

        searchBarView.backgroundColor = customBackgroundColor ?? UIColor.white

        addSubview(searchBarView)
        searchBarView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
        addSubview(formatButton)
        formatButton.anchor(top: searchBarView.topAnchor, left: nil, bottom: searchBarView.bottomAnchor, right: searchBarView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)
        
        addSubview(sortButton)
        sortButton.anchor(top: searchBarView.topAnchor, left: nil, bottom: searchBarView.bottomAnchor, right: formatButton.leftAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)
        setupSortPicker()
        
        //        searchBarHeight = searchBarView.heightAnchor.constraint(equalToConstant: 40)
        //        searchBarHeight?.isActive = true
        
        setupSearchBar()
        searchBarView.addSubview(defaultSearchBar)
        defaultSearchBar.anchor(top: searchBarView.topAnchor, left: searchBarView.leftAnchor, bottom: searchBarView.bottomAnchor, right: sortButton.leftAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)
        
        
        
        
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
    
    func updateSegments(){
        for i in 0..<headerSortSegment.numberOfSegments {
            if headerSortSegment.titleForSegment(at: i) != sortOptions[i] {
                //Update Segment Label
                headerSortSegment.setTitle(sortOptions[i], forSegmentAt: i)
            }
        }
    }
    
    func selectSort(sender: UISegmentedControl) {
        
        self.selectedSort = sortOptions[sender.selectedSegmentIndex]
        delegate?.headerSortSelected(sort: self.selectedSort)
        print("Selected Sort is ",self.selectedSort)
    }
    
    func setupSearchBar(){
        defaultSearchBar.layer.cornerRadius = 30/2
        defaultSearchBar.layer.masksToBounds = true
        //        defaultSearchBar.clipsToBounds = true
        //        defaultSearchBar.searchBarStyle = .prominent
        defaultSearchBar.searchBarStyle = .minimal
        
        defaultSearchBar.barTintColor = UIColor.legitColor()
        defaultSearchBar.tintColor = UIColor.white
        //        defaultSearchBar.backgroundImage = UIImage()
        defaultSearchBar.layer.borderWidth = 0
        defaultSearchBar.layer.borderColor = UIColor.darkGray.cgColor
        defaultSearchBar.placeholder = "Food, Users, Location"
        defaultSearchBar.delegate = self
        //        defaultSearchBar.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        
        let textFieldInsideSearchBar = defaultSearchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = UIColor.darkLegitColor()
        
        for s in defaultSearchBar.subviews[0].subviews {
            if s is UITextField {
                s.backgroundColor = UIColor.clear
                
                if let backgroundview = s.subviews.first {
                    
                    //                    // Background color
                    //                    backgroundview.backgroundColor = UIColor.clear
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
        self.delegate?.openSearch(index: 0)
        return false
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText.count == 0) {
            searchBar.endEditing(true)
            self.selectedCaption = nil
            self.delegate?.clearCaptionSearch()
        }
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
        self.sortButton.setTitle(self.selectedSort + "🔽", for: .normal)
    }
    
    // UIPicker Delegate Functions
    
    @objc func activateSort() {
        let rangeIndex = sortOptions.firstIndex(of: self.selectedSort)
        pickerView.selectRow(rangeIndex!, inComponent: 0, animated: false)
        dummyTextView.perform(#selector(becomeFirstResponder), with: nil, afterDelay: 0.1)
    }
    
    @objc func donePicker(){
        self.selectedSort = sortOptions[pickerView.selectedRow(inComponent: 0)]
        print("Sort Selected: \(self.selectedSort)")
        dummyTextView.resignFirstResponder()
        delegate?.headerSortSelected(sort: self.selectedSort)
    }
    
    @objc func cancelPicker(){
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
        delegate?.headerSortSelected(sort: self.selectedSort)
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
