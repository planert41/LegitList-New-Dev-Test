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

protocol MainListViewViewHeaderDelegate {
    func changeView()
    func headerSortSelected(sort: String)
}


class MainListViewViewHeader: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    var delegate: MainListViewViewHeaderDelegate?
    
    // Filter Post Variables
//    var headerFilter: Filter? {
//        didSet {
//            if headerFilter?.filterSort != nil {
//                if let selectedIndex = HeaderSortOptions.index(of: (headerFilter?.filterSort)!) {
//                    self.headerSortSegment.selectedSegmentIndex = selectedIndex
//                }
//            }
//        }
//    }
    
    
    // Sorting Variables
    // 0 For Default Header Sort Options, 1 for Location Sort Options
    var headerSortSegment = UISegmentedControl()
    
    var sortOptions: [String] = HeaderSortOptions {
        didSet{
            self.updateSegments()
        }
    }
    
    var selectedSort: String = defaultNearestSort {
        didSet{
            headerSortSegment.selectedSegmentIndex = sortOptions.firstIndex(of: selectedSort)!
        }
    }
    
    
 
    // Grid/List View Button
    var isListView = false {
        didSet{
            formatButton.setImage(self.isListView ? #imageLiteral(resourceName: "list"):#imageLiteral(resourceName: "grid"), for: .normal)
        }
    }
    
    lazy var formatButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(changeView), for: .touchUpInside)
        button.tintColor = UIColor.legitColor()
        return button
    }()

    func changeView(){
        self.delegate?.changeView()
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        
        // Setup Filter View
        
//        addSubview(formatButton)
//        formatButton.anchor(top: topAnchor, left: nil, bottom: bottomAnchor, right: rightAnchor, paddingTop: 1, paddingLeft: 1, paddingBottom: 1, paddingRight: 3, width: 0, height: 0)
//        formatButton.widthAnchor.constraint(equalTo: formatButton.heightAnchor, multiplier: 1).isActive = true
//        formatButton.layer.cornerRadius = self.frame.height/2
//        formatButton.layer.masksToBounds = true
//        formatButton.backgroundColor = UIColor.white.withAlphaComponent(0.5)
//
        headerSortSegment = UISegmentedControl(items: sortOptions)
        headerSortSegment.selectedSegmentIndex = sortOptions.firstIndex(of: self.selectedSort)!
        headerSortSegment.addTarget(self, action: #selector(selectSort), for: .valueChanged)
        headerSortSegment.tintColor = UIColor.legitColor()
        headerSortSegment.backgroundColor = UIColor.white
        
        addSubview(headerSortSegment)
//        headerSortSegment.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: formatButton.leftAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        
        headerSortSegment.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)

        
    }
    
    // Sort Setup
    
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
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}


