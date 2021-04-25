//
//  ListOptionTableViewCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 7/22/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit
import Foundation

class ListOptionTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    let listOptionHeader: UILabel = {
        let label = UILabel()
        label.text = "Location Names"
        label.textAlignment = NSTextAlignment.left
        label.font = UIFont(name: "Poppins-Bold", size: 12)
        label.textColor = UIColor.ianBlackColor()
        return label
    }()
    
    let listOptionDetails: UILabel = {
        let label = UILabel()
        label.text = "Posts"
        label.textColor = UIColor.ianBlackColor()
        label.font = UIFont(font: .avenirNextRegular, size: 14)
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 1
        return label
        
    }()
    
    var optionHeader: String = "" {
        didSet {
            listOptionHeader.text = optionHeader
            listOptionHeader.sizeToFit()
        }
    }
    
    var optionDetail: String = "" {
        didSet {
            listOptionDetails.text = optionDetail
            listOptionDetails.sizeToFit()
        }
    }
    
    let heroImageView: CustomImageView = {
        
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 2
        return iv
        
    }()
    
    var arrowImage = UIImageView()
    
    var listOptionDetailCenter: NSLayoutConstraint?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        

        arrowImage.image = #imageLiteral(resourceName: "rightArrow")
        addSubview(arrowImage)
        arrowImage.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 10, height: 20)
        arrowImage.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        addSubview(heroImageView)
        heroImageView.anchor(top: topAnchor, left: nil, bottom: bottomAnchor, right: arrowImage.leftAnchor, paddingTop: 5, paddingLeft: 3, paddingBottom: 5, paddingRight: 50, width: 0, height: 0)
        heroImageView.widthAnchor.constraint(equalTo: heroImageView.heightAnchor, multiplier: 1).isActive = true
        heroImageView.isHidden = true
        
        let optionView = UIView()
        addSubview(optionView)
        optionView.anchor(top: nil, left: leftAnchor, bottom: nil, right: arrowImage.leftAnchor, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        optionView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        addSubview(listOptionHeader)
        listOptionHeader.anchor(top: optionView.topAnchor, left: optionView.leftAnchor, bottom: nil, right: optionView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        addSubview(listOptionDetails)
        listOptionDetails.anchor(top: listOptionHeader.bottomAnchor, left: optionView.leftAnchor, bottom: optionView.bottomAnchor, right: optionView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        listOptionDetailCenter = listOptionDetails.centerYAnchor.constraint(equalTo: optionView.centerYAnchor)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
