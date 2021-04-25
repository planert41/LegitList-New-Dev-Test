//
//  SortFilterHeader.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 12/28/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit

protocol SortFilterHeaderDelegate {
//    func didChangeToListView()
//    func didChangeToGridView()
//    func didSignOut()
//    func activateSearchBar()
    func openSearch(index: Int?)
    func clearCaptionSearch()
    func openFilter()
    func headerSortSelected(sort: String)
//    func openMap()
}

class SortFilterHeader: UICollectionViewCell, UISearchBarDelegate {
    
    var delegate: SortFilterHeaderDelegate?

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
    
    
    var sortOptions: [String] = HeaderSortOptions {
        didSet{
            self.updateSegments()
        }
    }
    
    
    var headerSortSegment = UISegmentedControl()
    var selectedSort: String = defaultRecentSort {
        didSet{
            headerSortSegment.selectedSegmentIndex = sortOptions.firstIndex(of: selectedSort)!
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
//    
    
    var searchBarView = UIView()
    var defaultSearchBar = UISearchBar()
    
    override init(frame: CGRect) {
        super.init(frame:frame)
     
        backgroundColor = UIColor.white
        
    // Add Search Bar
        searchBarView.backgroundColor = UIColor.legitColor()
        addSubview(searchBarView)
        searchBarView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
//        searchBarHeight = searchBarView.heightAnchor.constraint(equalToConstant: 40)
//        searchBarHeight?.isActive = true
        
        setupSearchBar()
        searchBarView.addSubview(defaultSearchBar)
        defaultSearchBar.anchor(top: searchBarView.topAnchor, left: searchBarView.leftAnchor, bottom: searchBarView.bottomAnchor, right: searchBarView.rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        
        
    // ADD MAP BUTTON
//        addSubview(mapButton)
//        mapButton.anchor(top: searchBarView.bottomAnchor, left: nil, bottom: bottomAnchor, right: rightAnchor, paddingTop: 3, paddingLeft: 0, paddingBottom: 2, paddingRight: 20, width: 0, height: 0)
//        mapButton.widthAnchor.constraint(equalTo: mapButton.heightAnchor, multiplier: 1).isActive = true
        
    //  Add Sort Options
        headerSortSegment = UISegmentedControl(items: sortOptions)
        headerSortSegment.selectedSegmentIndex = sortOptions.firstIndex(of: self.selectedSort)!
        headerSortSegment.addTarget(self, action: #selector(selectSort), for: .valueChanged)
//        headerSortSegment.tintColor = UIColor(hexColor: "107896")
        headerSortSegment.tintColor = UIColor.legitColor()
        headerSortSegment.backgroundColor = UIColor.white
//        headerSortSegment.layer.cornerRadius = 0
//        headerSortSegment.layer.borderColor = UIColor.legitColor().cgColor
//        headerSortSegment.layer.borderWidth = 1
//        headerSortSegment.layer.masksToBounds = true
        
        
        addSubview(headerSortSegment)
        headerSortSegment.anchor(top: searchBarView.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 3, paddingLeft: 20, paddingBottom: 2, paddingRight: 20, width: 0, height: 0)
        
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
        defaultSearchBar.layer.cornerRadius = 25/2
        defaultSearchBar.clipsToBounds = true
        defaultSearchBar.searchBarStyle = .prominent
        defaultSearchBar.barTintColor = UIColor.white
        //        defaultSearchBar.backgroundImage = UIImage()
        defaultSearchBar.layer.borderWidth = 0
        defaultSearchBar.placeholder = "Search Posts For"
        defaultSearchBar.delegate = self
        
        for s in defaultSearchBar.subviews[0].subviews {
            if s is UITextField {
                //                    s.layer.cornerRadius = 25/2
                //                    s.layer.borderWidth = 0.5
                //                    s.layer.borderColor = UIColor.legitColor().cgColor
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
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}
