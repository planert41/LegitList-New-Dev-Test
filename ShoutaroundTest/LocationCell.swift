//
//  EmojiCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/17/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

class LocationCell: UITableViewCell {
    
    var locationName: String? {
        didSet{
            locationTextLabel.text = locationName?.truncate(length: 30)
//            self.formatLocationNames()
        }
    }
    
    func formatLocationNames(){
        var city: String = ""
        var state: String = ""
        var country: String = ""
        
        var tempLocation = locationName?.components(separatedBy: ",")
        if let _ = tempLocation?[0]{
            city = (tempLocation?[0].formatName())!
        }
        
        for (index, value) in (tempLocation?.enumerated())! {
            if index == 0 {
                city = value.formatName() + ", "
            } else if index == 1 {
                state = (value.count) > 3 ? value.formatName() : value.uppercased() + ", "
            } else if index == 2 {
                country = (value.count) > 3 ? value.formatName() : value.uppercased()
            }
        }
        
//        if let _ = tempLocation?[1]{
//            state = (tempLocation?[1])!
//            state = (state.count) > 3 ? state.formatName() : state.uppercased()
//        }
//
//        if let _ = tempLocation?[2]{
//            country = (tempLocation?[2])!
//            country = (country.count) > 3 ? country.formatName() : country.uppercased()
//        }
        
        let finalLocName: [String] = [city,state,country]
        self.locationName = finalLocName.joined()
        locationTextLabel.text = locationName
        
    }
    
    var postCount: Int = 0 {
        didSet {
            if postCount > 0 {
                self.postCountLabel.text = "\(postCount) posts"
                self.postCountLabel.isHidden = false
                self.locationTextLabel.textColor = UIColor.darkLegitColor()
            } else {
                self.postCountLabel.text = "\(postCount) posts"
                self.postCountLabel.isHidden = true
                self.locationTextLabel.textColor = UIColor.gray
            }
        }
    }
    
    
    let locationTextLabel: UILabel = {
        let label = UILabel()
        label.text = "Location Names"
        label.textAlignment = NSTextAlignment.left
        label.font = UIFont(font: .avenirNextMedium, size: 16)
        label.textColor = UIColor.darkLegitColor()
        return label
    }()
    
    let postCountLabel: UILabel = {
        let label = UILabel()
        label.text = "Posts"
        label.textColor = UIColor.darkGray
        label.font = UIFont(font: .avenirNextRegular, size: 10)
        label.textAlignment = NSTextAlignment.right
        label.backgroundColor = UIColor.clear
        return label
        
    }()
    
    override var isSelected: Bool {
        didSet {
            self.backgroundColor = self.isSelected ? UIColor.mainBlue().withAlphaComponent(0.2) : UIColor.white
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(locationTextLabel)
        addSubview(postCountLabel)
        
        postCountLabel.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 40)
        postCountLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        postCountLabel.isHidden = true
        
        locationTextLabel.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: postCountLabel.leftAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 40)

        
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        postCountLabel.isHidden = true
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    
}
