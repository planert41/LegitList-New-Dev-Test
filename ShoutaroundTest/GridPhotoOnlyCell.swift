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

protocol GridPhotoOnlyCellDelegate {
//    func didTapPicture(post:Post?)
    func goToPost(postId: String?)
    func gridPhotoLabelTapped()
}

class GridPhotoOnlyCell: UICollectionViewCell, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    
    var delegate: GridPhotoOnlyCellDelegate?
    var imageUrl: String? {
        didSet {
            guard let imageUrl = imageUrl else {return}
            photoImageView.loadImage(urlString: imageUrl)
        }
    }
    var postIdLink: String?
    
    let photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .white
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        
        return iv
    }()
    
    let label: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 2
        label.layer.cornerRadius = 10/2
        label.clipsToBounds = true
        label.backgroundColor = UIColor.white
        label.layer.borderColor = UIColor.white.cgColor
        label.layer.borderWidth = 0
        label.textColor = UIColor.legitColor()
        label.isUserInteractionEnabled = true
        return label
    }()
    
    var highlightCell: Bool = false {
        didSet {
            self.topDiv.isHidden = !highlightCell
            
//            let outerView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
//            self.clipsToBounds = false
//            self.layer.shadowColor = highlightCell ? UIColor.red.cgColor : UIColor.clear.cgColor
//            self.layer.shadowOpacity = 1
//            self.layer.shadowOffset = CGSize.zero
//            self.layer.shadowRadius = 15
//            self.layer.shadowOffset = CGSize(width: 5.0, height: -5.0)

//            self.layer.shadowPath = UIBezierPath(roundedRect: self.frame, cornerRadius: 2).cgPath
        }
    }
    
    
    var topDiv = UIView()
    
    var optionalNewCount: Int? = nil {
        didSet {
            self.showOptionalCount()
        }
    }
    var optionalHeight = 0 as CGFloat
    var optionalView = UIView()
    var showOptionalView:NSLayoutConstraint?
    
    let optionalLabel: LightPaddedUILabel = {
        let label = LightPaddedUILabel()
        label.font = UIFont(font: .avenirNextBold, size: 10)
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.ianLegitColor()
        label.numberOfLines = 1
        label.layer.cornerRadius = 3
        label.clipsToBounds = true
        label.layer.borderColor = UIColor.white.cgColor
        label.layer.borderWidth = 0
        label.textColor = UIColor.white
        label.isUserInteractionEnabled = true
        return label
    }()
    
    
    func showOptionalCount(){
        guard let count = optionalNewCount else {
            optionalLabel.text = ""
            optionalLabel.isHidden = true
            return
        }
        
        if count > 0{
            showOptionalView?.constant = optionalHeight
            optionalLabel.text = String(count) + " NEW"
            optionalLabel.sizeToFit()
            optionalLabel.isHidden = false
        } else {
            optionalLabel.isHidden = true
        }
    }
    
    func showBottomBuffer(){
        showOptionalView?.constant = optionalHeight
    }
    
    func hideBottomBuffer(){
        showOptionalView?.constant = 0
    }

    override init(frame: CGRect) {
        super.init(frame:frame)
        self.backgroundColor = UIColor.clear
        
        addSubview(optionalView)
        optionalView.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        showOptionalView = optionalView.heightAnchor.constraint(equalToConstant: 0)
        showOptionalView?.isActive = true
        
        addSubview(optionalLabel)
        optionalLabel.anchor(top: optionalView.topAnchor, left: leftAnchor, bottom: optionalView.bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        // Photo Image
        addSubview(photoImageView)
        photoImageView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.width)
        photoImageView.anchor(top: topAnchor, left: leftAnchor, bottom: optionalView.topAnchor, right: rightAnchor, paddingTop: 1, paddingLeft: 1, paddingBottom: 1, paddingRight: 1, width: self.frame.width, height: self.frame.width)
        photoImageView.layer.cornerRadius = 3
        photoImageView.clipsToBounds = true
        photoImageView.alpha = 1

//        photoImageView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
        
        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(handlePictureTap))
        photoImageView.addGestureRecognizer(TapGesture)
        photoImageView.isUserInteractionEnabled = true
        
        addSubview(label)
//        label.anchor(top: nil, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)
        label.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)

        label.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        label.sizeToFit()

        label.alpha = 0
        
        let labelTap = UITapGestureRecognizer(target: self, action: #selector(labelTapped))
        label.addGestureRecognizer(labelTap)
        
        addSubview(topDiv)
        topDiv.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 2)
        topDiv.backgroundColor = UIColor.selectedColor()
        topDiv.isHidden = true
    }
    
    @objc func labelTapped(){
        print("GridPhotoOnlyCell | Label Tapped")
        if label.text?.contains("Follow") ?? false {
            self.delegate?.gridPhotoLabelTapped()
        }
    }
    
    func showLabel(string: String?) {
        guard let string = string else {return}
        label.text = string
        label.alpha = 1
        photoImageView.image = UIImage()
        photoImageView.backgroundColor = UIColor.white
        self.backgroundColor = UIColor.white
    }
    
    
    @objc func handlePictureTap() {
//        guard let post = post else {return}
        print("Tap Picture")
        delegate?.goToPost(postId: postIdLink ?? nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        //Flickering is caused by reused cell having previous photo or loading prior image request
        photoImageView.image = nil
        photoImageView.cancelImageRequestOperation()
        photoImageView.alpha = 1
        photoImageView.backgroundColor = UIColor.white
        label.alpha = 0
        highlightCell = false
        self.backgroundColor = UIColor.clear
        self.hideBottomBuffer()
        self.optionalNewCount = 0
        optionalLabel.isHidden = true

        
    }
}

