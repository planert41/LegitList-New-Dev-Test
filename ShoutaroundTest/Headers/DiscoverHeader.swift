//
//  RankViewHeader.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/19/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

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
import CoreLocation
import DropDown

protocol DiscoverHeaderDelegate {
//    func didChangeToListView()
//    func didChangeToGridView()
    
    func headerSortSelected(sort: String)
    func discoverTypeSelected(type: String)
    func openSearch(index: Int?)
    
    //    func rangeSelected(range: String)
    //    func locationSelected()
    
}


class DiscoverHeader: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    var delegate: DiscoverHeaderDelegate?
    
// DISCOVER TYPE
    var discoverTypeSegment = UISegmentedControl()
    var typeOptions: [String] = DiscoverOptions
    var discoverType: String = DiscoverDefault

// SORT
    var selectedSort: String = defaultRecentSort {
        didSet{
            self.sortButton.setTitle(selectedSort, for: .normal)
        }
    }
    
    lazy var sortButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(showDropDown), for: .touchUpInside)
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
    
    
    var dropDownMenu = DropDown()
    func setupDropDown(){
        dropDownMenu.anchorView = sortButton
        dropDownMenu.dismissMode = .automatic
        dropDownMenu.textColor = UIColor.darkLegitColor()
        dropDownMenu.textFont = UIFont.systemFont(ofSize: 15)
        dropDownMenu.backgroundColor = UIColor.white
        dropDownMenu.selectionBackgroundColor = UIColor.legitColor().withAlphaComponent(0.5)
        dropDownMenu.cellHeight = 50
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        dropDownMenu.dataSource = HomeFetchOptions
        dropDownMenu.selectionAction = { [unowned self] (index: Int, item: String) in
            print("Selected item: \(item) at index: \(index)")
            self.selectedSort = item
            self.dropDownMenu.hide()
        }
        
        if let index = self.dropDownMenu.dataSource.firstIndex(of: self.selectedSort) {
            print("DropDown Menu Preselect \(index) \(self.dropDownMenu.dataSource[index])")
            dropDownMenu.selectRow(index)
        }
    }
    
    @objc func showDropDown(){
        if self.dropDownMenu.isHidden{
            self.dropDownMenu.show()
        } else {
            self.dropDownMenu.hide()
        }
    }
    
    var isFiltering: Bool = false {
        didSet {
            if isFiltering {
                searchButton.backgroundColor = UIColor.mainBlue()
            } else {
                searchButton.backgroundColor = UIColor.white
            }
        }
    }
    
    lazy var searchButton: UIButton = {
        let button = UIButton(type: .system)
        let image = #imageLiteral(resourceName: "search_selected")
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(openSearch), for: .touchUpInside)
        button.tintColor = UIColor.legitColor()
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.layer.cornerRadius = 30/2
        button.clipsToBounds = true
        return button
    }()
    
    
    func openSearch(){
        if let _ = self.delegate {
            self.delegate!.openSearch(index: 0)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        
        // Setup Filter View
        
        addSubview(sortButton)
        sortButton.anchor(top: topAnchor, left: nil, bottom: bottomAnchor, right: rightAnchor, paddingTop: 1, paddingLeft: 1, paddingBottom: 1, paddingRight: 3, width: 0, height: 0)
        sortButton.layer.masksToBounds = true
        
        discoverTypeSegment = UISegmentedControl(items: typeOptions)
        discoverTypeSegment.selectedSegmentIndex = typeOptions.firstIndex(of: self.discoverType)!
        discoverTypeSegment.addTarget(self, action: #selector(selectType), for: .valueChanged)
        discoverTypeSegment.tintColor = UIColor.legitColor()
        
        addSubview(discoverTypeSegment)
        discoverTypeSegment.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: sortButton.leftAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        setupDropDown()
        
        addSubview(dropDownMenu)
        dropDownMenu.anchor(top: sortButton.bottomAnchor, left: nil, bottom: nil, right: sortButton.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    }
    
    // Sort Setup
    
    func updateSegments(){
        for i in 0..<discoverTypeSegment.numberOfSegments {
            if discoverTypeSegment.titleForSegment(at: i) != typeOptions[i] {
                //Update Segment Label
                discoverTypeSegment.setTitle(typeOptions[i], forSegmentAt: i)
            }
        }
    }
    
    @objc func selectType(sender: UISegmentedControl) {
        
        self.discoverType = typeOptions[sender.selectedSegmentIndex]
        print("DiscoverHeader | Type Selected | \(self.discoverType)")
        self.delegate?.discoverTypeSelected(type: self.discoverType)
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
