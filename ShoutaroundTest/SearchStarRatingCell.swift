//
//  SearchStarRatingCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 2/3/20.
//  Copyright © 2020 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import Cosmos


class SearchStarRatingCell: UITableViewCell {
    
    // Star Rating
    
    var selectPostStarRating: Int = 0 {
        didSet{
            self.starRating.rating = Double(selectPostStarRating)
            if selectPostStarRating > 0 {
                self.starRatingTextLabel.text = "\(selectPostStarRating) Stars"
            } else {
                self.starRatingTextLabel.text = ""
            }
            //            self.starRatingLabel.rating = selectPostStarRating
        }
    }
    
    let starRating: CosmosView = {
        let iv = CosmosView()
        iv.settings.fillMode = .half
        iv.settings.totalStars = starRatingCountDefault
        //        iv.settings.starSize = 30
        iv.settings.starSize = 25
        
        //        iv.settings.filledImage = #imageLiteral(resourceName: "ratingstarfilled").withRenderingMode(.alwaysOriginal)
        //        iv.settings.emptyImage = #imageLiteral(resourceName: "ratingstarunfilled").withRenderingMode(.alwaysOriginal)
        iv.settings.filledImage = #imageLiteral(resourceName: "ian_fullstar").withRenderingMode(.alwaysTemplate)
        iv.settings.emptyImage = #imageLiteral(resourceName: "ian_emptystar").withRenderingMode(.alwaysTemplate)
        iv.rating = 0
        iv.settings.starMargin = 5
        return iv
    }()
    
    let starRatingTextLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.clear
        label.font = UIFont(font: .avenirNextMedium, size: 16)
        return label
    }()
    
    let postCountLabel: UILabel = {
        let label = UILabel()
        label.text = "Posts"
        label.textColor = UIColor.gray
        label.font = UIFont(font: .avenirNextRegular, size: 10)
        label.textAlignment = NSTextAlignment.right
        label.backgroundColor = UIColor.clear
        return label
        
    }()
    
    var postCount: Int = 0 {
        didSet {
            self.setupPostCount()
        }
    }
    
    func setupPostCount(){
        if postCount > 0 {
            self.postCountLabel.text = "\(postCount) POSTS"
            self.postCountLabel.font = UIFont(font: .avenirNextDemiBold, size: 10)
            self.postCountLabel.textColor = UIColor.darkGray
            self.postCountLabel.isHidden = false
        } else {
            self.postCountLabel.isHidden = true
        }

    }
    
    var tempView = UIView()
    
    override var isSelected: Bool {
        didSet {
            self.tempView.backgroundColor = self.isSelected ? UIColor.mainBlue().withAlphaComponent(0.2) : UIColor.white
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.ianLightGrayColor()

        addSubview(tempView)
        tempView.backgroundColor = UIColor.ianLightGrayColor()
        tempView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        tempView.addSubview(starRating)
        tempView.addSubview(starRatingTextLabel)
        tempView.addSubview(postCountLabel)
        
        postCountLabel.anchor(top: nil, left: nil, bottom: nil, right: tempView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        postCountLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        postCountLabel.isHidden = true
        
        starRating.anchor(top: tempView.topAnchor, left: tempView.leftAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 30, paddingBottom: 5, paddingRight: 0, width: 0, height: 40)
//        starRating.centerYAnchor.constraint(equalToSystemSpacingBelow: postCountLabel.centerYAnchor, multiplier: 1).isActive = true
//        starRatingTextLabel.anchor(top: tempView.topAnchor, left: starRating.rightAnchor, bottom: tempView.bottomAnchor, right: postCountLabel.leftAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}
