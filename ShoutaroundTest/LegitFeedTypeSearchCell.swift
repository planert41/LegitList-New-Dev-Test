//
//  LegitFeedTypeCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/16/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit

protocol LegitFeedTypeSearchCellDelegate {
    func didActivateUserSearchBar()
}

class LegitFeedTypeSearchCell: UICollectionViewCell, UISearchBarDelegate {
    lazy var mainLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Top 250"
        ul.font = UIFont(name: "Poppins-Bold", size: 30)
        ul.textColor = UIColor.ianBlackColor()
        ul.textAlignment = NSTextAlignment.left
        ul.numberOfLines = 1
        ul.backgroundColor = UIColor.white
        return ul
    }()
    
    lazy var subLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Top 250"
        ul.font = UIFont.boldSystemFont(ofSize: 14)
        ul.textColor = UIColor.ianBlackColor()
        ul.textAlignment = NSTextAlignment.left
        ul.numberOfLines = 1
        ul.backgroundColor = UIColor.white
        return ul
    }()
    
    var delegate : LegitFeedTypeSearchCellDelegate?
    
//    var mainText: String = "" {
//        didSet {
////            self.updateLabels()
////            self.mainLabel.text = mainText
////            self.mainLabel.sizeToFit()
//        }
//    }
//
//    var subText: String = "" {
//        didSet {
////            self.updateLabels()
////            self.subLabel.text = mainText
////            self.subLabel.sizeToFit()
//        }
//    }
    
    func updateLabels(){
//        self.mainLabel.text = mainText
        self.subLabel.text = "Search For Users"
        self.labelView.sizeToFit()
    }
    
    let labelView = UIView()
    var fullSearchBar = UISearchBar()

    
    func setupSearchBar() {
//        setup.searchBarStyle = .prominent
        fullSearchBar.searchBarStyle = .minimal

        fullSearchBar.isTranslucent = false
        fullSearchBar.tintColor = UIColor.ianBlackColor()
        fullSearchBar.placeholder = "Search food, locations, categories"
        fullSearchBar.delegate = self
        fullSearchBar.showsCancelButton = false
        fullSearchBar.sizeToFit()
        fullSearchBar.clipsToBounds = true
        fullSearchBar.backgroundImage = UIImage()
        fullSearchBar.backgroundColor = UIColor.white

        // CANCEL BUTTON
        let attributes = [
            NSAttributedString.Key.foregroundColor : UIColor.ianLegitColor(),
            NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 30)
        ]
//        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(attributes, for: .normal)
        
        
        let searchImage = #imageLiteral(resourceName: "search_selected").withRenderingMode(.alwaysTemplate)
        fullSearchBar.setImage(UIImage(), for: .search, state: .normal)
        
//        let cancelImage = #imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysTemplate)
//        fullSearchBar.setImage(cancelImage, for: .clear, state: .normal)

        fullSearchBar.layer.borderWidth = 0
        fullSearchBar.layer.borderColor = UIColor.ianBlackColor().cgColor
    
        let textFieldInsideSearchBar = fullSearchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = UIColor.ianBlackColor()
        textFieldInsideSearchBar?.font = UIFont.systemFont(ofSize: 30)
        
        // REMOVE SEARCH BAR ICON
//        let searchTextField:UITextField = fullSearchBar.subviews[0].subviews.last as! UITextField
//        searchTextField.leftView = nil
        
        
        for s in fullSearchBar.subviews[0].subviews {
            if s is UITextField {
                s.backgroundColor = UIColor.clear
                s.layer.backgroundColor = UIColor.clear.cgColor
                if let backgroundview = s.subviews.first {
                    
                    // Background color
//                    backgroundview.backgroundColor = UIColor.white
                    backgroundview.clipsToBounds = true
                    backgroundview.layer.backgroundColor = UIColor.clear.cgColor
                    
                    // Rounded corner
//                    backgroundview.layer.cornerRadius = 30/2
//                    backgroundview.layer.masksToBounds = true
//                    backgroundview.clipsToBounds = true
                }
                
                //                s.layer.cornerRadius = 25/2
                //                s.layer.borderWidth = 1
                //                s.layer.borderColor = UIColor.gray.cgColor
            }
        }

    }
    
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        self.backgroundColor = UIColor.white
        
        let containerView = UIView()
        addSubview(containerView)
        containerView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: self.frame.width, height: 90)
        
        labelView.addSubview(fullSearchBar)
        fullSearchBar.anchor(top: labelView.topAnchor, left: labelView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        fullSearchBar.rightAnchor.constraint(lessThanOrEqualTo: labelView.rightAnchor)
        fullSearchBar.sizeToFit()
        
        labelView.addSubview(subLabel)
        subLabel.anchor(top: fullSearchBar.bottomAnchor, left: labelView.leftAnchor, bottom: labelView.bottomAnchor, right: nil, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        subLabel.rightAnchor.constraint(lessThanOrEqualTo: labelView.rightAnchor)

        subLabel.sizeToFit()
        
        addSubview(labelView)
        labelView.anchor(top: nil, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        labelView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
//        labelView.rightAnchor.constraint(lessThanOrEqualTo: containerView.rightAnchor, constant: 20).isActive = true
        self.updateLabels()

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
    
}


