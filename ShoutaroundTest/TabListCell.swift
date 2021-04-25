//
//  UserCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 11/15/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

import SVProgressHUD
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

protocol TabListCellDelegate {
    func goToList(list:List?, filter:String?)
//    func goToPost(postId: String, ref_listId: String?, ref_userId: String?)
//    func displayListFollowingUsers(list: List, following: Bool)
//    func refreshAll()
//    func goToUser(userId: String?)
}

class TabListCell: UITableViewCell {
    
    
    var delegate: TabListCellDelegate?

    var list: List?{
        didSet {
            
            guard let list = list else {
                return
            }
            
            setupBackgroundImage()
            setupListDetailLabels()
            fetchListUser()

        }
    }
    
    var listUser: User? {
        didSet {
            guard let profileImageUrl = listUser?.profileImageUrl else {return}
            self.setupProfileImage()
        }
    }
    
    let backgroundImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor.lightBackgroundGrayColor()
        return iv
    }()
    
    // MARK: - SETUP

    
    func setupBackgroundImage(){
        if let image = self.list?.heroImage {
            self.backgroundImageView.image = image
        } else if let url = self.list?.heroImageUrl {
            self.backgroundImageView.loadImage(urlString: url)
        } else if let url = self.list?.listImageUrls[0] {
            self.backgroundImageView.loadImage(urlString: url)
        } else {
            self.backgroundImageView.image = #imageLiteral(resourceName: "Legit_Vector")
            self.backgroundImageView.backgroundColor = UIColor.lightGray
        }
    }
    
    func fetchListUser(){
        guard let creatorUid = self.list?.creatorUID else {return}
        Database.fetchUserWithUID(uid: creatorUid) { (user) in
            self.listUser = user
        }
    }
    
    func setupListDetailLabels() {
        
        // List Name
        let listName = "   " + (self.list?.name ?? "")
        self.listNameButton.setTitle(listName, for: .normal)
        
        // List Social
        
        var listSocialString = ""
        
        let followerCount = self.list?.followerCount ?? 0
        listSocialString += "\(followerCount) Followers   "
        
        let postCount = self.list?.postIds?.count ?? 0
        listSocialString += "\(postCount) Posts"
        
        self.listSocialLabel.text = listSocialString

        
    }
    
    func setupProfileImage(){

            if self.list?.creatorUID == Auth.auth().currentUser?.uid
            {
                self.userProfileImageView.isHidden = true
            }
            else if let profileImageUrl = listUser?.profileImageUrl
            {
                userProfileImageView.loadImage(urlString: profileImageUrl)
                self.userProfileImageView.isHidden = false
            } else
            {
                self.userProfileImageView.isHidden = true
            }

        }
        

    
    let listDetailView = UIView()
    
    let userProfileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        return iv
    }()
    
    // MARK: - LIST BUTTONS
    
    // LIST NAME BUTTON
    lazy var listNameButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("", for: .normal)
        button.setImage(#imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTitleColor(UIColor.ianBlackColor(), for: .normal)
        button.titleLabel?.font =  UIFont(name: "Poppins-Bold", size: 15)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        button.tintColor = UIColor.ianBlackColor()
        button.addTarget(self, action: #selector(didTapListName), for: .touchUpInside)
        return button
    }()

    
    lazy var shareListButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Share", for: .normal)
        button.setImage(#imageLiteral(resourceName: "share").withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTitleColor(UIColor.ianBlackColor(), for: .normal)
        button.titleLabel?.font =  UIFont.systemFont(ofSize: 14)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        button.addTarget(self, action: #selector(didTapShare), for: .touchUpInside)
        button.tintColor = UIColor.ianBlackColor()
        return button
    }()

    let listSocialLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.textColor = UIColor.darkGray
        label.font = UIFont.systemFont(ofSize: 14)
        label.adjustsFontSizeToFitWidth = true
        //        label.numberOfLines = 0
        return label
    }()
    
    
    // MARK: - INIT

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = UIColor.clear
        
        let cellView = UIView()
        addSubview(cellView)
        cellView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 8, paddingLeft: 8, paddingBottom: 8, paddingRight: 8, width: 0, height: 230)
        cellView.backgroundColor = UIColor.white
        cellView.layer.applySketchShadow(color: UIColor.init(red: 0, green: 0, blue: 0, alpha: 1), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
        
        addSubview(backgroundImageView)
        backgroundImageView.anchor(top: cellView.topAnchor, left: cellView.leftAnchor, bottom: nil, right: cellView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 160)
        backgroundImageView.image = UIImage()
        backgroundImageView.layer.cornerRadius = 2
        backgroundImageView.layer.masksToBounds = true
        backgroundImageView.isUserInteractionEnabled = true
        backgroundImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapPicture)))
    
        addSubview(listDetailView)
        listDetailView.anchor(top: backgroundImageView.bottomAnchor, left: cellView.leftAnchor, bottom: cellView.bottomAnchor, right: cellView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        listDetailView.backgroundColor = UIColor.ianWhiteColor()
        
        listDetailView.addSubview(shareListButton)
        shareListButton.anchor(top: listDetailView.topAnchor, left: nil, bottom: nil, right: listDetailView.rightAnchor, paddingTop: 15, paddingLeft: 0, paddingBottom: 0, paddingRight: 25, width: 100, height: 0)
        shareListButton.sizeToFit()
        
        listDetailView.addSubview(listNameButton)
        listNameButton.anchor(top: listDetailView.topAnchor, left: listDetailView.leftAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 15, paddingBottom: 0, paddingRight: 10, width: 0, height: 30)
        listNameButton.rightAnchor.constraint(lessThanOrEqualTo: shareListButton.leftAnchor, constant: 10).isActive = true
//        listNameButton.backgroundColor = UIColor.mainBlue()
        
        listDetailView.addSubview(listSocialLabel)
        listSocialLabel.anchor(top: listNameButton.bottomAnchor, left: listNameButton.leftAnchor, bottom: nil, right: shareListButton.leftAnchor, paddingTop: 8, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        addSubview(userProfileImageView)
        userProfileImageView.anchor(top: backgroundImageView.topAnchor, left: nil, bottom: nil, right: backgroundImageView.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 30, height: 30)
        
        userProfileImageView.layer.cornerRadius = 30/2
        userProfileImageView.layer.masksToBounds = true
        userProfileImageView.isUserInteractionEnabled = true
        userProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapProfileImage)))
        userProfileImageView.layer.borderColor = UIColor.white.cgColor
        userProfileImageView.layer.borderWidth = 2
        userProfileImageView.isHidden = true
        
    }
    
    // MARK: - FUNCTIONS

    @objc func didTapPicture() {
        print("Tap Picture")
        self.goToList()
    }
    
    @objc func didTapListName() {
        print("Tap List Name")
        self.goToList()
    }
    
    @objc func didTapProfileImage(){
        print("Tap Profile Image")
        self.goToList()
    }

    @objc func didTapShare(){
        print("Tap Share")
    }
    
    @objc func goToList() {
        guard let list = list else {return}
        self.delegate?.goToList(list:list, filter:nil)
    }
    

    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    
    override func prepareForReuse() {
        super.prepareForReuse()

        self.userProfileImageView.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        self.userProfileImageView.isHidden = true
        self.listSocialLabel.text = ""
        self.listNameButton.setTitle(nil, for: .normal)
        
        let subViews = self.subviews
        
        // Reused cells removes extra pictures and shrinks back contentsize width. It gets expanded and added back later if >1 pic
        
        for subview in subViews{
            if let img = subview as? CustomImageView {
                img.image = nil
                img.cancelImageRequestOperation()
                if img.tag != 0 {
                    img.removeFromSuperview()
                }
            }
        }
        
    }
    
}
