//
//  OtherLocationPostCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/22/20.
//  Copyright © 2020 Wei Zou Ang. All rights reserved.
//


import UIKit

protocol LocationOtherPostCellDelegate {
    func didTapPost(post: Post?)
}


class LocationOtherPostCell: UICollectionViewCell {
    
    var listCellHeight: CGFloat = 140
    var listCellWidth: CGFloat = 100
    
    var delegate: LocationOtherPostCellDelegate?
    
    
    var post: Post? {
        didSet {
            self.loadPost()
        }
    }
    
    
    let listHeaderImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .gray
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
//        iv.layer.cornerRadius = 50/2
//        iv.layer.masksToBounds = true
        return iv
    }()
    
    let userProfileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        return iv
    }()
    
    let locationRatingLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont(name: "Poppins-Bold", size: 14)
//        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = NSTextAlignment.right
        //        label.numberOfLines = 0
        return label
    }()
    
    let listDetailLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.systemFont(ofSize: 10)
        label.adjustsFontSizeToFitWidth = false
        label.textAlignment = NSTextAlignment.center
        label.textColor = UIColor.darkGray
        //        label.numberOfLines = 0
        return label
    }()
    
    func clearCell() {
        self.listHeaderImageView.image = nil
        self.locationRatingLabel.text = ""
        self.userProfileImageView.image = nil
    }
    
    func loadPost() {
        guard let post = self.post else {
            clearCell()
            return
        }
        
    // LIST HEADER IMG
        if post.imageUrls.count > 0 {
            let url = post.imageUrls[0]
            self.listHeaderImageView.loadImage(urlString: url)
        }
        else if post.imageUrl != "" {
            self.listHeaderImageView.loadImage(urlString: post.imageUrl)
        }
        else {
            self.listHeaderImageView.cancelImageRequestOperation()
            self.listHeaderImageView.image = nil
        }

        
    // POST RATING
        var ratingText = ""
        if let ratingEmoji = self.post?.ratingEmoji {
            ratingText = "\(ratingEmoji)  "
        }
        
        if let rating = self.post?.rating {
            if rating > 0 {
                ratingText += "\(String(rating))"
            }
        }
        self.locationRatingLabel.text = ratingText
        self.locationRatingLabel.sizeToFit()
        
        let userUrl = post.user.profileImageUrl
        if userUrl != "" {
            self.userProfileImageView.loadImage(urlString: userUrl)
        } else {
            self.userProfileImageView.image = nil

        }
        
    }
    
    override var isSelected: Bool {
        didSet {
//            self.listNameLabel.textColor = self.isSelected ? UIColor.white : UIColor.ianBlackColor()
//            self.listDetailLabel.textColor = self.isSelected ? UIColor.white : UIColor.darkGray
//            self.cellView.backgroundColor = self.isSelected ? UIColor.ianLegitColor() : UIColor.clear
//            self.layer.borderColor = self.isSelected ? UIColor.ianLegitColor().cgColor : UIColor.gray.cgColor

        }
    }
    
    let cellView = UIView()
    let detailView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.layer.cornerRadius = 5
        self.layer.masksToBounds = true
        self.clipsToBounds = true
        self.layer.borderColor = UIColor.gray.cgColor
        self.layer.borderWidth = 1
        self.layer.applySketchShadow()
        
        addSubview(cellView)
        cellView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: listCellWidth, height: listCellHeight)

        cellView.isUserInteractionEnabled = true
        cellView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapPost)))

        cellView.addSubview(listHeaderImageView)
//        listHeaderImageView.isListBackground = true
        listHeaderImageView.anchor(top: cellView.topAnchor, left: cellView.leftAnchor, bottom: nil, right: cellView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: listCellWidth, height: listCellWidth)
//        listHeaderImageView.heightAnchor.constraint(equalTo: listHeaderImageView.widthAnchor, multiplier: 1, constant: 0).isActive = true
//        listHeaderImageView.centerXAnchor.constraint(equalTo: cellView.centerXAnchor).isActive = true
        listHeaderImageView.isUserInteractionEnabled = true
        listHeaderImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapPost)))
        
        cellView.addSubview(detailView)
        detailView.anchor(top: listHeaderImageView.bottomAnchor, left: cellView.leftAnchor, bottom: cellView.bottomAnchor, right: cellView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: listCellHeight - listCellWidth)
        
        detailView.addSubview(userProfileImageView)
        userProfileImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 2, paddingBottom: 0, paddingRight: 0, width: 30, height: 30)
        userProfileImageView.centerYAnchor.constraint(equalTo: detailView.centerYAnchor).isActive = true
        userProfileImageView.layer.cornerRadius = 30/2
        userProfileImageView.layer.masksToBounds = true
        userProfileImageView.layer.borderColor = UIColor.white.cgColor
        userProfileImageView.layer.borderWidth = 0.5
        
        detailView.addSubview(locationRatingLabel)
        locationRatingLabel.anchor(top: nil, left: userProfileImageView.rightAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 2, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        locationRatingLabel.centerYAnchor.constraint(equalTo: detailView.centerYAnchor).isActive = true
        locationRatingLabel.isUserInteractionEnabled = true
        locationRatingLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapPost)))

        
    }
    

    func tapPost() {
        guard let post = post else {return}
        self.delegate?.didTapPost(post: post)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        listHeaderImageView.cancelImageRequestOperation()
        userProfileImageView.cancelImageRequestOperation()
        self.clearCell()
    }
    
    
    
}
