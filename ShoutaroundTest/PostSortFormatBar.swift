//
//  EmojiSummaryCV.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 5/27/20.
//  Copyright © 2020 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

protocol PostSortFormatBarDelegate {
    func headerSortSelected(sort: String)
    func didTapGridButton()
    func toggleMapFunction()
}


class PostSortFormatBar: UIView{
    
    var delegate: PostSortFormatBarDelegate?
    
    var sortSegmentControl: UISegmentedControl = TemplateObjects.createPostSortButton()
    var segmentWidth_selected: CGFloat = 110.0
    var segmentWidth_unselected: CGFloat = 80.0
    var defaultWidth: CGFloat  = 828.0
    var scalar: CGFloat = 1.0

    
    
    var navGridToggleButton: UIButton = TemplateObjects.gridFormatButton()
    var isGridView = false {
        didSet {
            var image = isGridView ? #imageLiteral(resourceName: "grid") : #imageLiteral(resourceName: "listFormat")
            self.navGridToggleButton.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
            self.navGridToggleButton.setTitle(isGridView ? "Grid " : "List ", for: .normal)
        }
        
    }
    var barView = UIView()
    
//    let navMapButton = NavBarMapButton.init(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    // NAV BUTTONS
    lazy var navMapButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
//        let icon = #imageLiteral(resourceName: "google_color").withRenderingMode(.alwaysOriginal)
//        let icon = #imageLiteral(resourceName: "location_color").withRenderingMode(.alwaysOriginal)
        let icon = #imageLiteral(resourceName: "map").withRenderingMode(.alwaysTemplate)

        button.setTitle(" Map", for: .normal)
        button.setImage(icon, for: .normal)
        button.layer.borderColor = UIColor.ianLegitColor().cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 30/2
        button.layer.masksToBounds = true
        button.clipsToBounds = true
        button.contentHorizontalAlignment = .center
        button.backgroundColor = UIColor.ianWhiteColor()
        button.backgroundColor = UIColor.lightBackgroundGrayColor()
//        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        button.tintColor = UIColor.ianLegitColor()
        button.titleLabel?.font =  UIFont(font: .avenirNextBold, size: 14)
        button.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        button.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12)
        button.imageView?.contentMode = .scaleAspectFit

        return button
    }()
    var navMapButtonWidth: NSLayoutConstraint?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.scalar = min(1, UIScreen.main.nativeBounds.width / defaultWidth)
        print(" ~ PostSortFormatBar Scalar", self.scalar, UIScreen.main.nativeBounds.width, defaultWidth)
        

        addSubview(barView)
        barView.backgroundColor = UIColor.clear
        barView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 50)

        

        setupSegmentControl()
        
        sortSegmentControl.layer.borderWidth = 1
        barView.addSubview(sortSegmentControl)
        sortSegmentControl.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 10, width: 0, height: 40)
        sortSegmentControl.centerYAnchor.constraint(equalTo: barView.centerYAnchor).isActive = true
//        sortSegmentControl.rightAnchor.constraint(lessThanOrEqualTo: navMapButton.leftAnchor, constant: 15).isActive = true

//        sortSegmentControl.centerXAnchor.constraint(equalTo: barView.centerXAnchor).isActive = true
        self.refreshSort(sender: sortSegmentControl)
        
                
        barView.addSubview(navMapButton)
        navMapButton.addTarget(self, action: #selector(toggleMapFunction), for: .touchUpInside)
        navMapButton.anchor(top: nil, left: sortSegmentControl.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 25, width: 0, height: 40)
        navMapButtonWidth = navMapButton.widthAnchor.constraint(equalToConstant: 90)
        navMapButtonWidth?.isActive = true
        navMapButton.centerYAnchor.constraint(equalTo: barView.centerYAnchor).isActive = true
//        navMapButton.centerYAnchor.constraint(equalTo: barView.centerYAnchor).isActive = true
//        navMapButton.isHidden = true
        //        navMapButton.alpha = 0.8
        navMapButton.rightAnchor.constraint(lessThanOrEqualTo: barView.rightAnchor, constant: 20).isActive = true


        

        
        addSubview(navGridToggleButton)
//        navGridToggleButton.tintColor = UIColor.gray
        navGridToggleButton.tintColor = UIColor.darkGray

        navGridToggleButton.setTitleColor(UIColor.darkGray, for: .normal)
        navGridToggleButton.titleLabel?.font =  UIFont(font: .avenirNextBold, size: 15)

        navGridToggleButton.backgroundColor = UIColor.white
        
        navGridToggleButton.anchor(top: nil, left: nil, bottom: nil, right: barView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 0, height: 35)
        navGridToggleButton.centerYAnchor.constraint(equalTo: sortSegmentControl.centerYAnchor).isActive = true
        navGridToggleButton.isUserInteractionEnabled = true
        navGridToggleButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapGridButton)))
        navGridToggleButton.semanticContentAttribute  = .forceLeftToRight
        navGridToggleButton.layer.cornerRadius = 5
        navGridToggleButton.layer.masksToBounds = true
        navGridToggleButton.layer.borderColor = navGridToggleButton.tintColor.cgColor
        navGridToggleButton.layer.borderWidth = 1
        navGridToggleButton.isHidden = true
        
        
        navGridToggleButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        navGridToggleButton.setTitle("Grid ", for: .normal)
        isGridView = true
        
        self.refreshSort(sender: sortSegmentControl)

        
        


        
        
    }
    
    @objc func toggleMapFunction() {
        self.delegate?.toggleMapFunction()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func setupSegmentControl() {
        TemplateObjects.postSortDelegate = self
        sortSegmentControl.selectedSegmentIndex = 0
        sortSegmentControl.addTarget(self, action: #selector(selectPostSort), for: .valueChanged)
        if #available(iOS 13.0, *) {
            sortSegmentControl.selectedSegmentTintColor = UIColor.mainBlue()
            sortSegmentControl.layer.borderColor = UIColor.lightGray.cgColor
//            sortSegmentControl.layer.borderColor = sortSegmentControl.selectedSegmentTintColor?.cgColor
            sortSegmentControl.tintColor = UIColor.white
        }
        else {
            sortSegmentControl.layer.borderColor = UIColor.lightGray.cgColor
        }
        
        
        
    }
    
    @objc func selectPostSort(sender: UISegmentedControl) {
        let selectedSort = HeaderSortOptions[sender.selectedSegmentIndex]
        print("NewLegitHomeHeader | \(selectedSort) | selectPostSort")

        self.refreshSort(sender: sender)
        self.delegate?.headerSortSelected(sort: selectedSort)
    }
    
    @objc func refreshSort(sender: UISegmentedControl) {
        let selectedSort = HeaderSortOptions[sender.selectedSegmentIndex]
        let newTitle = headerSortDictionary[selectedSort]
        

        for (index, sortOptions) in HeaderSortOptions.enumerated()
        {
            var isSelected = (index == sender.selectedSegmentIndex)
//            var displayFilter = (isSelected) ? newTitle : sortOptions
            var displayFilter = (isSelected) ? "Sort \(sortOptions)" : sortOptions
            sender.setTitle(displayFilter, forSegmentAt: index)
//            sender.setWidth((isSelected) ? 100 : 70, forSegmentAt: index)
            sender.setWidth((isSelected) ? (segmentWidth_selected * scalar) : (segmentWidth_unselected * scalar), forSegmentAt: index)

        }

    }
    
}

extension PostSortFormatBar: PostSortFormatBarDelegate, postSortSegmentControlDelegate {
    func headerSortSelected(sort: String) {
        self.delegate?.headerSortSelected(sort: sort)
    }
    
    @objc func didTapGridButton() {
        self.delegate?.didTapGridButton()
    }
    
    
}
