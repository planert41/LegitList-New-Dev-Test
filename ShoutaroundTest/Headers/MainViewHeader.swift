//
//  ListViewHeader.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/7/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

protocol MainViewHeaderDelegate {
    func didChangeToListView()
    func didChangeToPostView()
    func openFilter()
    func clearCaptionSearch()
    func openSearch(index: Int?)
    func headerSortSelected(sort: String)
    
    func showFullMap()
    func showFullList()
    func filterLegitPosts()
}


class MainViewHeader: UICollectionViewCell, UIGestureRecognizerDelegate, UISearchBarDelegate {
    
    var delegate: MainViewHeaderDelegate?
    var headerSortSegment = UISegmentedControl()
    var selectedSort: String = defaultNearestSort {
        didSet{
            if let index = HeaderSortOptions.firstIndex(of: self.selectedSort){
                if headerSortSegment.selectedSegmentIndex != index {
                    headerSortSegment.selectedSegmentIndex = index
                }
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
    
    var searchBarView = UIView()
    var defaultSearchBar = UISearchBar()
    var enableSearchBar: Bool = true {
        didSet{
            // Hide Search Bar if not enabled
            if self.enableSearchBar{
                searchBarHeight?.constant = 40
                self.searchBarView.isHidden = false
                //                searchBarView.backgroundColor = UIColor.legitColor()
            } else {
                searchBarHeight?.constant = 0
                self.searchBarView.isHidden = true
                //                searchBarView.backgroundColor = UIColor.white
                self.defaultSearchBar.removeFromSuperview()
            }
        }
    }
    var searchBarHeight: NSLayoutConstraint?
    
    // Grid/List View Button
    var postView = PostView.list
    enum PostView {
        case list
        case grid
        case full
    }
    
    
    var isListView = true {
        didSet{
            formatButton.setImage(self.isListView ? #imageLiteral(resourceName: "postview") :#imageLiteral(resourceName: "list"), for: .normal)
        }
    }
    
    lazy var formatButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.system)
        button.setImage(self.isListView ? #imageLiteral(resourceName: "postview") :#imageLiteral(resourceName: "list"), for: .normal)
        button.addTarget(self, action: #selector(changeView), for: .touchUpInside)
        button.tintColor = UIColor.white
        return button
    }()
    
    @objc func changeView(){
        if isListView{
            self.isListView = false
            delegate?.didChangeToPostView()
        } else {
            self.isListView = true
            delegate?.didChangeToListView()
        }
    }
    
    // Map Button
    var mapDisplayed = true {
        didSet{
            mapButton.backgroundColor = self.mapDisplayed ? UIColor.init(hexColor: "e67e22") : UIColor.clear
            mapButton.setImage(self.mapDisplayed ? #imageLiteral(resourceName: "map_selected") :#imageLiteral(resourceName: "map_unselected"), for: .normal)

        }
    }
    
    lazy var mapButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(#imageLiteral(resourceName: "map_unselected").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(adjustMap), for: .touchUpInside)
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.clipsToBounds = true
        return button
    }()
    
    @objc func adjustMap(){
        if mapDisplayed{
            self.mapDisplayed = false
            delegate?.showFullList()
        } else {
            self.mapDisplayed = true
            delegate?.showFullMap()
        }
    }
    
    // Filter Legit Button
    var isFilteringLegit: Bool = false {
        didSet{
            filterLegitButton.backgroundColor = isFiltering ? UIColor.legitColor() : UIColor.white
            filterLegitButton.alpha = isFiltering ? 1 : 0.6
            if !isFiltering {
                isFilteringText = nil
            }
        }
    }
    
    lazy var filterLegitButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(#imageLiteral(resourceName: "legit_large").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(filterLegit), for: .touchUpInside)
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.clipsToBounds = true
        button.layer.backgroundColor = UIColor.white.cgColor
        button.tintColor = UIColor.darkGray
        return button
    }()
    
    @objc func filterLegit(){
        self.delegate?.filterLegitPosts()
    }
    
    // Filter Button
    
    var isFiltering: Bool = false {
        didSet{
            filterButton.setImage(self.isFiltering ? #imageLiteral(resourceName: "search_tab_fill"):#imageLiteral(resourceName: "slider"), for: .normal)
            if !isFiltering {
                isFilteringText = nil
            }
        }
    }
    
    var isFilteringText: String? = nil {
        didSet{
            if (isFilteringText != nil) && isFiltering {
                defaultSearchBar.text = isFilteringText
            } else {
                defaultSearchBar.text?.removeAll()
            }
        }
    }
    
    lazy var filterButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(#imageLiteral(resourceName: "slider").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(openFilter), for: .touchUpInside)
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.clipsToBounds = true
        button.tintColor = UIColor.white
        return button
    }()
    
    @objc func openFilter(){
        self.delegate?.openFilter()
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        
        searchBarView.backgroundColor = UIColor.legitColor()
        addSubview(searchBarView)
        searchBarView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        searchBarHeight = searchBarView.heightAnchor.constraint(equalToConstant: 40)
        searchBarHeight?.isActive = true
        
        addSubview(formatButton)
        formatButton.anchor(top: searchBarView.topAnchor, left: nil, bottom: searchBarView.bottomAnchor, right: searchBarView.rightAnchor, paddingTop: 1, paddingLeft: 1, paddingBottom: 1, paddingRight: 3, width: 0, height: 0)
        formatButton.widthAnchor.constraint(equalTo: formatButton.heightAnchor, multiplier: 1).isActive = true
        //        formatButton.layer.cornerRadius = formatButton.frame.width/2
        formatButton.layer.masksToBounds = true
        
        headerSortSegment = UISegmentedControl(items: HeaderSortOptions)
        headerSortSegment.selectedSegmentIndex = HeaderSortOptions.firstIndex(of: self.selectedSort)!
        headerSortSegment.addTarget(self, action: #selector(selectSort), for: .valueChanged)
        headerSortSegment.tintColor = UIColor.legitColor()
        
        
        addSubview(filterButton)
        filterButton.anchor(top: searchBarView.topAnchor, left: nil, bottom: searchBarView.bottomAnchor, right: formatButton.leftAnchor, paddingTop: 1, paddingLeft: 1, paddingBottom: 1, paddingRight: 3, width: 0, height: 0)
        filterButton.widthAnchor.constraint(equalTo: filterButton.heightAnchor, multiplier: 1).isActive = true
        filterButton.layer.cornerRadius = filterButton.frame.width/2
        filterButton.layer.masksToBounds = true
        

        setupSearchBar()
        searchBarView.addSubview(defaultSearchBar)
        defaultSearchBar.anchor(top: searchBarView.topAnchor, left: searchBarView.leftAnchor, bottom: searchBarView.bottomAnchor, right: filterButton.leftAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: (searchBarHeight?.constant)! * 0.75)
        
        
        //        defaultSearchBar.centerYAnchor.constraint(equalTo: searchBarView.centerYAnchor).isActive = true
//
//        addSubview(mapButton)
//        mapButton.anchor(top: searchBarView.bottomAnchor, left: nil, bottom: bottomAnchor, right: rightAnchor, paddingTop: 1, paddingLeft: 1, paddingBottom: 1, paddingRight: 3, width: 0, height: 0)
//        mapButton.widthAnchor.constraint(equalTo: mapButton.heightAnchor, multiplier: 1).isActive = true
//        mapButton.layer.cornerRadius = 20
//        mapButton.layer.masksToBounds = true
//
//
//
//        addSubview(headerSortSegment)
//        headerSortSegment.anchor(top: searchBarView.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: formatButton.leftAnchor, paddingTop: 5, paddingLeft: 3, paddingBottom: 5, paddingRight: 1, width: 0, height: 0)
        //
        //        let bottomDivider = UIView()
        //        bottomDivider.backgroundColor = UIColor.legitColor()
        //        addSubview(bottomDivider)
        //        bottomDivider.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
        
        
        
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
    
    @objc func selectSort(sender: UISegmentedControl) {
        self.selectedSort = HeaderSortOptions[sender.selectedSegmentIndex]
        delegate?.headerSortSelected(sort: self.selectedSort)
        print("Selected Sort is ",self.selectedSort)
    }
    
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}
