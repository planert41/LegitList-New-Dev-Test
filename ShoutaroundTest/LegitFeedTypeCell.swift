//
//  LegitFeedTypeCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/16/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit

class LegitFeedTypeCell: UICollectionViewCell {
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
    
    var mainText: String = "" {
        didSet {
            self.updateLabels()
//            self.mainLabel.text = mainText
//            self.mainLabel.sizeToFit()
        }
    }
    
    var subText: String = "" {
        didSet {
            self.updateLabels()
//            self.subLabel.text = mainText
//            self.subLabel.sizeToFit()
        }
    }
    
    func updateLabels(){
        self.mainLabel.text = mainText
        self.subLabel.text = subText
        self.labelView.sizeToFit()
    }
    
    let labelView = UIView()

    
    override init(frame: CGRect) {
        super.init(frame:frame)
        self.backgroundColor = UIColor.white
        
        let containerView = UIView()
        addSubview(containerView)
        containerView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: self.frame.width, height: 90)
        
        labelView.addSubview(mainLabel)
        mainLabel.anchor(top: labelView.topAnchor, left: labelView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        mainLabel.rightAnchor.constraint(lessThanOrEqualTo: labelView.rightAnchor)
        mainLabel.sizeToFit()
        
        labelView.addSubview(subLabel)
        subLabel.anchor(top: mainLabel.bottomAnchor, left: labelView.leftAnchor, bottom: labelView.bottomAnchor, right: nil, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        subLabel.rightAnchor.constraint(lessThanOrEqualTo: labelView.rightAnchor)

        subLabel.sizeToFit()
        
        addSubview(labelView)
        labelView.anchor(top: nil, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        labelView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
//        labelView.rightAnchor.constraint(lessThanOrEqualTo: containerView.rightAnchor, constant: 20).isActive = true
        self.updateLabels()

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
    
}
