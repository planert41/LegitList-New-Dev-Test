//
//  UserSummaryCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/1/20.
//  Copyright © 2020 Wei Zou Ang. All rights reserved.
//

import UIKit

protocol UserSummaryCellDelegate {
    func didTapUser(user: User?)
}


class UserSummaryCell: UICollectionViewCell {
    
    var userCellHeight: CGFloat = 90 //80
    var userCellWidth: CGFloat = 80 // 70
    
    var delegate: UserSummaryCellDelegate?
    var user: User? {
        didSet {
            self.loadUser()
        }
    }
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .white
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 60/2
        iv.layer.masksToBounds = true
        return iv
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.adjustsFontSizeToFitWidth = false
        label.textAlignment = NSTextAlignment.center
        //        label.numberOfLines = 0
        return label
    }()
        
    let userPostCountLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.systemFont(ofSize: 11)
        label.textColor = UIColor.darkGray
        label.adjustsFontSizeToFitWidth = false
        label.textAlignment = NSTextAlignment.center
        //        label.numberOfLines = 0
        return label
    }()
        
    
    func loadUser() {
        guard let user = user else {return}
        self.profileImageView.loadImage(urlString: (self.user?.profileImageUrl)!)
        
        self.usernameLabel.text = self.user?.username
        self.usernameLabel.sizeToFit()
        
        var postCount = self.user?.posts_created ?? 0
        var emoji = self.user?.topEmojis.prefix(3).joined()
        self.userPostCountLabel.text = (postCount > 0) ? "\(postCount) Posts" : ""
//        self.userPostCountLabel.text = "\(emoji!)"
        self.userPostCountLabel.sizeToFit()
    }
    
    override var isSelected: Bool {
        didSet {
            self.profileImageView.layer.borderColor = self.isSelected ? UIColor.ianLegitColor().cgColor : UIColor.clear.cgColor
            self.profileImageView.layer.borderWidth = self.isSelected ? 2 : 0
            self.usernameLabel.textColor = self.isSelected ? UIColor.white : UIColor.ianBlackColor()
            self.userPostCountLabel.textColor = self.isSelected ? UIColor.white : UIColor.darkGray
            self.cellView.backgroundColor = self.isSelected ? UIColor.ianLegitColor() : UIColor.clear
            self.layer.borderColor = self.isSelected ? UIColor.ianLegitColor().cgColor : UIColor.clear.cgColor
            self.layer.borderWidth = self.isSelected ? 0 : 0

        }
    }
    
    let cellView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        self.clipsToBounds = true

        
        addSubview(cellView)
        cellView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: userCellWidth, height: userCellHeight)
        
        addSubview(profileImageView)
        profileImageView.anchor(top: cellView.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 3, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 50+10, height: 50+10)
        
        profileImageView.centerXAnchor.constraint(equalTo: cellView.centerXAnchor).isActive = true
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapUser)))
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: profileImageView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 3, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 10)
        usernameLabel.isUserInteractionEnabled = true
        usernameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapUser)))
        
        addSubview(userPostCountLabel)
        userPostCountLabel.anchor(top: usernameLabel.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 3, paddingRight: 0, width: 0, height: 10)
        
        
    }
    
    
    @objc func tapUser() {
        guard let user = user else {return}
        self.delegate?.didTapUser(user: user)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        profileImageView.cancelImageRequestOperation()
        self.usernameLabel.text = ""

    }
    
    
    
}
