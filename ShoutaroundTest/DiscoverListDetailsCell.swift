//
//  UserProfilePhotoCell.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/29/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import Cosmos
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

protocol DiscoverListDetailsCellDelegate {
    func listDetailTapped()
}

class DiscoverListDetailsCell: UICollectionViewCell, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    
    var delegate: DiscoverListDetailsCellDelegate?
    
    let listNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Poppins-Bold", size: 24)
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.textColor = UIColor.black
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let listDetailsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Poppins-Bold", size: 12)
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.textColor = UIColor.black
        label.isUserInteractionEnabled = true
        return label
    }()
    
    var inputList: List? {
        didSet {
            self.setupListDetails()
        }
    }
    
    var listDetailsIcon = UIButton()
    
    func setupListDetails(){
        guard let list = inputList else {
            listNameLabel.text = ""
            listDetailsLabel.text = ""
            return}
        
        listNameLabel.text = list.name
        listNameLabel.sizeToFit()

        let listDetailString = NSMutableAttributedString()
//        listDetailString.append(NSAttributedString(string: " "))

    // LIST IMAGE
//        let image1Attachment = NSTextAttachment()
//        let inputImage = #imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate)
//        image1Attachment.image = inputImage
//        image1Attachment.bounds = CGRect(x: 0, y: (listDetailsLabel.font.capHeight - (inputImage.size.height) - 6).rounded() / 2, width: inputImage.size.width, height: inputImage.size.height)
//        let image1String = NSAttributedString(attachment: image1Attachment)
//        listDetailString.append(image1String)
        
        
        let newPostCount = list.newNotificationsCount ?? 0
        if newPostCount > 0 {
            let newPostCountString = NSAttributedString(string: " \(newPostCount) NEW  ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextBold, size: 12)])
            listDetailString.append(newPostCountString)
        }
        
        listDetailsIcon.tintColor = newPostCount > 0 ? UIColor.ianLegitColor() : UIColor.black

        
        let postCount = list.postIds?.count ?? 0
        let postCountString = NSAttributedString(string: " \(postCount) Posts", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Regular", size: 12)])
        listDetailString.append(postCountString)
        
        let followerCount = list.followerCount ?? 0
        let followerCountString = NSAttributedString(string: "   \(followerCount) Followers", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextMedium, size: 12)])
        listDetailString.append(followerCountString)        

        listDetailsLabel.attributedText = listDetailString
        listDetailsLabel.sizeToFit()
        
    }
    

    override init(frame: CGRect) {
        super.init(frame:frame)
        self.backgroundColor = UIColor.white
        self.layer.borderColor = UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0.2).cgColor
        self.layer.borderWidth = 1
        self.layer.cornerRadius = 2
        self.layer.masksToBounds = true
        self.layer.applySketchShadow()
        
        let cellView = UIView()
        addSubview(cellView)
        cellView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 230, height: 75)
        cellView.backgroundColor = UIColor.white
        
        addSubview(listNameLabel)
        listNameLabel.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 10, paddingLeft: 15, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        listNameLabel.isUserInteractionEnabled = true
        listNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(labelTapped)))
//        self.bringSubviewToFront(listNameLabel)
        
        let detailView = UIView()
        addSubview(detailView)
        detailView.anchor(top: listNameLabel.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

        let inputImage = #imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate)
        listDetailsIcon.setImage(inputImage, for: .normal)
        listDetailsIcon.tintColor = UIColor.black
        listDetailsIcon.imageView?.contentMode = .scaleAspectFit
        addSubview(listDetailsIcon)
        listDetailsIcon.anchor(top: nil, left: listNameLabel.leftAnchor, bottom: detailView.bottomAnchor, right: nil, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 15, height: 15)
//        listDetailsIcon.centerYAnchor.constraint(equalTo: detailView.centerYAnchor).isActive = true

        addSubview(listDetailsLabel)
        listDetailsLabel.anchor(top: nil, left: listDetailsIcon.rightAnchor, bottom: detailView.bottomAnchor, right: listNameLabel.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 0, height: 0)
//        listDetailsLabel.centerYAnchor.constraint(equalTo: detailView.centerYAnchor).isActive = true

//        listDetailsLabel.anchor(top: listNameLabel.bottomAnchor, left: listNameLabel.leftAnchor, bottom: bottomAnchor, right: listNameLabel.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 0, height: 0)
//        listDetailsLabel.centerYAnchor.constraint(equalTo: detailView.centerYAnchor).isActive = true
        listDetailsLabel.isUserInteractionEnabled = true
        listDetailsLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(labelTapped)))

    }
    
    @objc func labelTapped(){
        print("GridPhotoOnlyCell | Label Tapped")
        self.delegate?.listDetailTapped()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.inputList = nil
        self.setupListDetails()
        
    }
}

