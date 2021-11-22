//
//  BottomSortBar.swift
//  ShoutaroundTest
//
//  Created by Wei Zou on 11/6/21.
//  Copyright © 2021 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

protocol BottomSortBarDelegate {
    func headerSortSelected(sort: String)
    func didTapGridButton()
    func toggleMapFunction()
}


class BottomSortBar: UIView{

    var sortSegmentControl: UISegmentedControl = TemplateObjects.createPostSortButton()
    var segmentWidth_selected: CGFloat = 90.0
    var segmentWidth_unselected: CGFloat = 70.0
    var defaultWidth: CGFloat  = 828.0
    var scalar: CGFloat = 1.0
    var delegate: BottomSortBarDelegate?
    
    
    lazy var navMapButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
//        let icon = #imageLiteral(resourceName: "google_color").withRenderingMode(.alwaysOriginal)
//        let icon = #imageLiteral(resourceName: "location_color").withRenderingMode(.alwaysOriginal)
        let icon = #imageLiteral(resourceName: "map").withRenderingMode(.alwaysTemplate)

        button.setTitle(" Map", for: .normal)
        button.setImage(icon, for: .normal)
        button.layer.borderColor = UIColor.customRedColor().cgColor
        button.layer.borderWidth = 2
        button.layer.cornerRadius = 20/2
        button.layer.masksToBounds = true
        button.clipsToBounds = true
        button.contentHorizontalAlignment = .center
        button.backgroundColor = UIColor.ianWhiteColor()
//        button.backgroundColor = UIColor.whi
//        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        button.tintColor = UIColor.customRedColor()
        button.titleLabel?.font =  UIFont(font: .avenirNextBold, size: 14)
        button.setTitleColor(UIColor.customRedColor(), for: .normal)
        button.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12)
        button.imageView?.contentMode = .scaleAspectFit

        return button
    }()
    
    lazy var sortButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
//        let icon = #imageLiteral(resourceName: "google_color").withRenderingMode(.alwaysOriginal)
//        let icon = #imageLiteral(resourceName: "location_color").withRenderingMode(.alwaysOriginal)
        let icon = #imageLiteral(resourceName: "sort_arrow_new").withRenderingMode(.alwaysTemplate)
        button.setImage(icon, for: .normal)
        button.setTitle("Sort ", for: .normal)
        button.titleLabel?.font =  UIFont(name: "Poppins-Bold", size: 14)
        button.setTitleColor(UIColor.darkGray, for: .normal)
        button.tintColor = UIColor.darkGray
        button.contentHorizontalAlignment = .center
        button.backgroundColor = UIColor.clear
        button.imageView?.contentMode = .scaleAspectFit
        button.semanticContentAttribute = .forceRightToLeft
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.scalar = min(1, UIScreen.main.nativeBounds.width / defaultWidth)

        let barView = UIView()
        addSubview(barView)
        barView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        barView.backgroundColor = UIColor.backgroundGrayColor()
        
        let div = UIView()
        addSubview(div)
        div.backgroundColor = UIColor.lightGray
        div.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)

        barView.addSubview(sortButton)
        sortButton.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        sortButton.sizeToFit()
        sortButton.centerYAnchor.constraint(equalTo: barView.centerYAnchor).isActive = true

        setupSegmentControl()
        barView.addSubview(sortSegmentControl)
        sortSegmentControl.anchor(top: nil, left: sortButton.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        sortSegmentControl.centerYAnchor.constraint(equalTo: barView.centerYAnchor).isActive = true

        barView.addSubview(navMapButton)
        navMapButton.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 80 * scalar, height: 40)
        navMapButton.sizeToFit()
        navMapButton.centerYAnchor.constraint(equalTo: barView.centerYAnchor).isActive = true
        navMapButton.addTarget(self, action: #selector(toggleMapFunction), for: .touchUpInside)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func toggleMapFunction() {
        self.delegate?.toggleMapFunction()
    }
    
    func setupSegmentControl() {
        sortSegmentControl = UISegmentedControl(items: HeaderSortOptions)
        sortSegmentControl.selectedSegmentIndex = 0
        sortSegmentControl.addTarget(self, action: #selector(segmentSelected), for: .valueChanged)
        sortSegmentControl.backgroundColor = UIColor.white
        sortSegmentControl.tintColor = UIColor.oldLegitColor()
        sortSegmentControl.layer.borderWidth = 1
        sortSegmentControl.layer.borderColor = UIColor.lightGray.cgColor
        if #available(iOS 13.0, *) {
            sortSegmentControl.selectedSegmentTintColor = UIColor.mainBlue()
        }
        
        sortSegmentControl.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 14), NSAttributedString.Key.foregroundColor: UIColor.gray], for: .normal)
        sortSegmentControl.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 13), NSAttributedString.Key.foregroundColor: UIColor.ianWhiteColor()], for: .selected)
    }
    
    func selectSort(sort: String) {
        if let index = HeaderSortOptions.index(of: sort) {
            self.sortSegmentControl.selectedSegmentIndex = index
            self.refreshSegment()
        } else {
            print("Bottom Sort Segment Doesn't have option for \(sort)")
        }
    }
 
    @objc func segmentSelected(sender: UISegmentedControl) {
        print("SortSegmentSelected: \(HeaderSortOptions[sender.selectedSegmentIndex])")
        let sort = HeaderSortOptions[sender.selectedSegmentIndex]
        self.refreshSegment()
        self.delegate?.headerSortSelected(sort: sort)
    }
    
    func refreshSegment() {
        for (index, sortOptions) in HeaderSortOptions.enumerated()
        {
            var isSelected = (index == self.sortSegmentControl.selectedSegmentIndex)
            var selectedText = bottomSelectedSortDic[sortOptions]
            var unselectedText = sortOptions

            var displayFilter = (isSelected) ? selectedText : unselectedText
            self.sortSegmentControl.setTitle(displayFilter, forSegmentAt: index)
            self.sortSegmentControl.setWidth((isSelected) ? (segmentWidth_selected * scalar) : (segmentWidth_unselected * scalar), forSegmentAt: index)
        }
    }
    
    
}
