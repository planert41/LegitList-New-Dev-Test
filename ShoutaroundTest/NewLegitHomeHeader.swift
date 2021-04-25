//
//  NewLegitHomeHeader.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 12/29/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit


protocol LegitHomeHeaderDelegate {
    func headerSortSelected(sort: String)
    func toggleFeedType()
    func didTapAddTag(addTag: String)
    func didRemoveTag(tag: String)
    func didTapGridButton()
    func didTapMapButton()
    func didTapSearchButton()
    func didTapNotification()
    func showSearchView()
    func hideSearchView()
    func filterContentForSearchText(_ searchText: String)
    func handleRefresh()
    func handleFilter()
    func openNotifications()
    func goToUser(uid: String?)
    func goToList(listId: String?)
    
}



class NewLegitHomeHeader: UICollectionViewCell {
    
    var delegate: LegitHomeHeaderDelegate?

    
    var sortSegmentControl: UISegmentedControl = TemplateObjects.createPostSortButton()

    var formatSegmentControl: UISegmentedControl = TemplateObjects.createGridListButton()
    var formatOptions = ["grid", "list"]

    var navGridToggleButton: UIButton = TemplateObjects.gridFormatButton()
    var isGridView = false {
        didSet {
            var image = isGridView ? #imageLiteral(resourceName: "grid") : #imageLiteral(resourceName: "listFormat")
            self.navGridToggleButton.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
//            self.navGridToggleButton.setTitle(isGridView ? "Grid " : "List ", for: .normal)
            self.topSearchBar.isGridView = self.isGridView
        }
        
    }
    
    lazy var navFeedTypeLabel: UILabel = {
        let ul = UILabel()
        ul.isUserInteractionEnabled = true
        ul.numberOfLines = 1
        ul.adjustsFontSizeToFitWidth = true
        ul.textAlignment = NSTextAlignment.left
        ul.font = UIFont(name: "Poppins-Bold", size: 25)
        ul.textColor = UIColor.ianBlackColor()
        return ul
    }()
    
    lazy var navFeedTypeButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        button.setImage(#imageLiteral(resourceName: "dropdownXLarge").withRenderingMode(.alwaysTemplate), for: .normal)
//        button.setImage(#imageLiteral(resourceName: "iconDropdown").withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.tintColor = UIColor.gray
        button.addTarget(self, action: #selector(toggleNavFeedType), for: .touchUpInside)
        return button
    }()
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .white
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
//        iv.layer.cornerRadius = 50/2
//        iv.layer.masksToBounds = true
        return iv
    }()
    var profileImageViewWidth: NSLayoutConstraint?
    
    
    
    var navSearchButton: UIButton = TemplateObjects.NavSearchButton()
    
    var viewFilter: Filter = Filter.init(defaultSort: defaultRecentSort) {
        didSet {
//            self.refreshNavSort()
            self.refreshSegmentValues()
            self.refreshSearchButton()
            self.refreshNotifications()
        }
    }
    
//    let navMapButton = NavBarMapButton.init()
    lazy var navMapButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
//        let icon = #imageLiteral(resourceName: "google_color").withRenderingMode(.alwaysOriginal)
//        let icon = #imageLiteral(resourceName: "location_color").withRenderingMode(.alwaysOriginal)
        let icon = #imageLiteral(resourceName: "map").withRenderingMode(.alwaysTemplate)

//        let icon = #imageLiteral(resourceName: "google_color").withRenderingMode(.alwaysOriginal)

//        button.setTitle(" Map", for: .normal)
        button.setImage(icon, for: .normal)
//        button.layer.borderColor = UIColor.ianLegitColor().cgColor
        button.layer.borderWidth = 0
        button.clipsToBounds = true
        button.contentHorizontalAlignment = .center
//        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        button.tintColor = UIColor.gray
        button.titleLabel?.font =  UIFont(font: .avenirNextBold, size: 13)
        button.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        button.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
//        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.imageView?.contentMode = .scaleAspectFit

        return button
    }()
//    lazy var navMapButton: UIButton = {
//        let ul = UIButton.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//        ul.setImage(#imageLiteral(resourceName: "map_nav_1"), for: .normal)
//        ul.imageView?.contentMode = .scaleAspectFill
//        ul.isUserInteractionEnabled = true
//        ul.layer.cornerRadius = 1
//        ul.layer.masksToBounds = true
//        return ul
//    }()
    
    var fetchUser: User? = nil
    var fetchList: List? = nil

    var fetchTypeInd: String = HomeFetchDefault {
        didSet{
            self.refresNavFeedTypeLabel()
        }
    }
    
    func refresNavFeedTypeLabel(){
        if self.fetchTypeInd == HomeFetchOptions[2] && self.fetchUser != nil
        {
            self.navFeedTypeLabel.text = self.fetchUser?.username
            if let url = self.fetchUser?.profileImageUrl {
                self.profileImageView.loadImage(urlString: url)
                profileImageViewWidth?.constant = 40
            }
        }
        else if self.fetchTypeInd == HomeFetchOptions[3] && self.fetchList != nil {
            self.navFeedTypeLabel.text = self.fetchList?.name
            if let url = self.fetchList?.heroImageUrl {
                self.profileImageView.loadImage(urlString: url)
                profileImageViewWidth?.constant = 40
            }
        }
        else {
            self.navFeedTypeLabel.text = self.fetchTypeInd
            profileImageViewWidth?.constant = 0
        }
        self.navFeedTypeLabel.sizeToFit()
        
        self.navFeedTypeButton.tintColor = self.fetchTypeInd == HomeFetchOptions[0] ? UIColor.lightGray : UIColor.ianLegitColor()
    }
    

    let notificationButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        button.setImage(#imageLiteral(resourceName: "alert").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.darkGray
        //        button.layer.cornerRadius = button.frame.width/2
//        button.layer.masksToBounds = true
        button.setTitle("", for: .normal)
        button.addTarget(self, action: #selector(openNotifications), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.borderColor = UIColor.gray.cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 40/2
        button.titleLabel?.textColor = UIColor.ianLegitColor()
//        button.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
//        button.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
//        button.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        return button
    }()
    
    let notificationLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 25, y: 0, width: 15, height: 15))
        label.layer.borderColor = UIColor.clear.cgColor
        label.layer.borderWidth = 0
        label.layer.cornerRadius = label.bounds.size.height / 2
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = UIFont(name: "Poppins-Bold", size: 10)
        label.textColor = .white
        label.backgroundColor = UIColor.ianLegitColor()
        label.text = "80"
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openNotifications)))
        return label
    }()
        
    @objc func refreshNotifications() {
        if CurrentUser.unreadEventCount > 0 {
            notificationLabel.text = String(CurrentUser.unreadEventCount)
            notificationButton.addSubview(notificationLabel)
            notificationButton.tintColor = UIColor.ianLegitColor()
            notificationLabel.isHidden = false
        } else {
//                    notificationButton.setTitle("", for: .normal)
            notificationLabel.text = ""
            notificationLabel.isHidden = true
            notificationButton.tintColor = UIColor.darkGray
        }
    }
    
    @objc func openNotifications(){
        self.delegate?.openNotifications()
    }
    
    @objc func didTapProfilePic(){
        if self.fetchTypeInd == HomeFetchOptions[2] && self.fetchUser != nil
        {
            if let userUid = self.fetchUser?.uid {
                print("goToUser | \(userUid)")
                self.delegate?.goToUser(uid: userUid)
            }
        }
        else if self.fetchTypeInd == HomeFetchOptions[3] && self.fetchList != nil {
            if let listId = self.fetchList?.id {
                print("goToList | \(listId)")
                self.delegate?.goToList(listId: listId)
            }
        }
        else {
            self.navFeedTypeLabel.text = self.fetchTypeInd
            profileImageViewWidth?.constant = 0
        }
        self.navFeedTypeLabel.sizeToFit()
    }
    
    let headerView = UIView()

    let topSearchBar = UserSearchBar()
    
    var navEmojiButton: UIButton = TemplateObjects.NavSearchButton()
    let navEmojiButtonView = UIView()
    let emojiSearchBar = UserSearchBar()
    let headerLabelView = UIView()

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.backgroundGrayColor()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshNotifications), name: UserEventViewController.refreshNotificationName, object: nil)

        addSubview(headerView)
        headerView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 10, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 40 + UIApplication.shared.statusBarFrame.height)
        headerView.backgroundColor = UIColor.white
        headerView.isUserInteractionEnabled = true
        headerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleNavFeedType)))

//        let profilePicView = UIView()
                
        headerView.addSubview(notificationButton)
        notificationButton.anchor(top: nil, left: nil, bottom: nil, right: headerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 40, height: 40)

        refreshNotifications()

        NotificationCenter.default.addObserver(self, selector: #selector(refreshNotifications), name: MainTabBarController.NewNotificationName, object: nil)

//        headerView.addSubview(navMapButton)
//        navMapButton.anchor(top: nil, left: nil, bottom: nil, right: headerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 40, height: 40)
//        navMapButton.semanticContentAttribute = .forceRightToLeft
//        headerLabelView.leftAnchor.constraint(lessThanOrEqualTo: navMapButton.rightAnchor).isActive = true

        
        headerLabelView.addSubview(profileImageView)
        profileImageView.anchor(top: headerLabelView.topAnchor, left: headerLabelView.leftAnchor, bottom: headerLabelView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
        profileImageViewWidth = profileImageView.widthAnchor.constraint(equalToConstant: 40)
        profileImageViewWidth?.isActive = true
        
        profileImageView.layer.cornerRadius = 40/2
        profileImageView.layer.masksToBounds = true
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapProfilePic)))

        
        headerLabelView.addSubview(navFeedTypeLabel)
        navFeedTypeLabel.anchor(top: headerLabelView.topAnchor, left: profileImageView.rightAnchor, bottom: headerLabelView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        navFeedTypeLabel.isUserInteractionEnabled = true
        navFeedTypeLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleNavFeedType)))
//        navFeedTypeLabel.backgroundColor = UIColor.white
        self.refresNavFeedTypeLabel()
        

        headerLabelView.addSubview(navFeedTypeButton)
        navFeedTypeButton.anchor(top: nil, left: navFeedTypeLabel.rightAnchor, bottom: nil, right: headerLabelView.rightAnchor, paddingTop: 0, paddingLeft: 4, paddingBottom: 0, paddingRight: 5, width: 25, height: 25)
        navFeedTypeButton.centerYAnchor.constraint(equalTo: headerLabelView.centerYAnchor).isActive = true
//        navFeedTypeButton.backgroundColor = UIColor.white

        
        headerView.addSubview(headerLabelView)
        headerLabelView.anchor(top: nil, left: headerView.leftAnchor, bottom: headerView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
//        headerLabelView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor).isActive = true
//        headerLabelView.leftAnchor.constraint(lessThanOrEqualTo: headerView.leftAnchor).isActive = true
//        headerLabelView.rightAnchor.constraint(lessThanOrEqualTo: headerView.rightAnchor).isActive = true
//        headerLabelView.backgroundColor = UIColor.white
        headerLabelView.widthAnchor.constraint(lessThanOrEqualToConstant: UIScreen.main.applicationFrame.size.width - 50).isActive = true
//        headerLabelView.layer.cornerRadius = 5
//        headerLabelView.layer.masksToBounds = true
//        headerLabelView.backgroundColor = UIColor.ianWhiteColor()
        
//        headerLabelView.leftAnchor.constraint(lessThanOrEqualTo: notificationButton.rightAnchor).isActive = true
        notificationButton.centerYAnchor.constraint(equalTo: headerLabelView.centerYAnchor).isActive = true
//        navMapButton.centerYAnchor.constraint(equalTo: headerLabelView.centerYAnchor).isActive = true

        

        
        
//        headerLabelView.addSubview(emojiSearchBar)
//        emojiSearchBar.anchor(top: nil, left: profileImageView.rightAnchor, bottom: headerView.bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
////        emojiSearchBar.centerYAnchor.constraint(equalTo: headerLabelView.centerYAnchor).isActive = true
//
//        emojiSearchBar.delegate = self
//        emojiSearchBar.showEmoji = true

//        headerLabelView.addSubview(navGridToggleButton)
//        navGridToggleButton.anchor(top: nil, left: nil, bottom: nil, right: headerLabelView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
//        navGridToggleButton.centerYAnchor.constraint(equalTo: headerLabelView.centerYAnchor).isActive = true
//        navGridToggleButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
//        setupnavGridToggleButton()
        
//        headerLabelView.addSubview(navEmojiButtonView)
//        navEmojiButtonView.anchor(top: nil, left: nil, bottom: nil, right: headerLabelView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 35, height: 35)
//        navEmojiButtonView.centerYAnchor.constraint(equalTo: headerLabelView.centerYAnchor).isActive = true
//        navEmojiButtonView.layer.cornerRadius = 35/2
//        navEmojiButtonView.layer.masksToBounds = true
//        navEmojiButtonView.backgroundColor = UIColor.ianWhiteColor()
//        navEmojiButtonView.layer.borderWidth = 0
//        navEmojiButton.layer.borderColor = UIColor.gray.cgColor

//        headerLabelView.addSubview(navEmojiButton)
//        navEmojiButton.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 30, height: 30)
//        navEmojiButton.centerYAnchor.constraint(equalTo: navEmojiButtonView.centerYAnchor).isActive = true
//        navEmojiButton.centerXAnchor.constraint(equalTo: navEmojiButtonView.centerXAnchor).isActive = true
//
//        navEmojiButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
////        navEmojiButton.centerYAnchor.constraint(equalTo: headerLabelView.centerYAnchor).isActive = true
//        navEmojiButton.addTarget(self, action: #selector(didTapNavEmoji), for: .touchUpInside)
//        navEmojiButton.layer.cornerRadius = 30/2
//        navEmojiButton.layer.masksToBounds = true
//        navEmojiButton.tintColor = UIColor.gray
//        navEmojiButton.layer.borderColor = UIColor.gray.cgColor
//        navEmojiButton.setTitleColor(UIColor.gray, for: .normal)
//        navEmojiButton.backgroundColor = UIColor.clear
//        navEmojiButton.layer.borderWidth = 0
//        navEmojiButton.titleLabel?.adjustsFontSizeToFitWidth = true
//        navEmojiButton.isHidden = false
//        navEmojiButton.setImage(UIImage(), for: .normal)
//        scheduledTimerWithTimeInterval()
//        updateEmojiButton()

//        navEmojiButtonView.isHidden = true
//        navEmojiButton.isHidden = true


        
        
//        headerLabelView.addSubview(navMapButton)
//        navMapButton.anchor(top: nil, left: navFeedTypeLabel.rightAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 0, width: 25, height: 25)
//        navMapButton.centerYAnchor.constraint(equalTo: headerLabelView.centerYAnchor).isActive = true
////        navMapButton.addTarget(self, action: #selector(didTapMapButton), for: .touchUpInside)
//        navMapButton.addTarget(self, action: #selector(didTapMapButton), for: .touchUpInside)
////        navMapButton.leftAnchor.constraint(lessThanOrEqualTo: sortSegmentControl.rightAnchor, constant: 15).isActive = true
////        navMapButton.layer.cornerRadius = 50/2
////        navMapButton.layer.cornerRadius = 30/2
////        navMapButton.layer.masksToBounds = true
////        navMapButton.backgroundColor = UIColor.backgroundGrayColor()
////        navMapButton.alpha = 0.8
//        navMapButton.tintColor = UIColor.darkGray
//        navMapButton.layer.borderColor = navMapButton.tintColor.cgColor
//        navMapButton.backgroundColor = UIColor.clear
//        navMapButton.layer.borderWidth = 0
//        navMapButton.isHidden = true
        
        
        
        
//        headerLabelView.addSubview(navFeedTypeButton)
//        navFeedTypeButton.anchor(top: nil, left: navFeedTypeLabel.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 25, height: 25)
//        navFeedTypeButton.centerYAnchor.constraint(equalTo: headerLabelView.centerYAnchor).isActive = true
////        navFeedTypeButton.rightAnchor.constraint(lessThanOrEqualTo: navMapButton.leftAnchor, constant: 10).isActive = true
//        navFeedTypeButton.rightAnchor.constraint(lessThanOrEqualTo: navMapButton.leftAnchor, constant: 10).isActive = true


                
        
        
//        headerLabelView.backgroundColor = UIColor.lightLegitColor()
        

        
//        headerLabelView.addSubview(navSearchButton)
//        navSearchButton.setTitle("", for: .normal)
//        navSearchButton.anchor(top: nil, left: nil, bottom: nil, right: headerLabelView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 35, height: 35)
//        navSearchButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapSearchButton)))
//        navSearchButton.centerYAnchor.constraint(equalTo: headerLabelView.centerYAnchor).isActive = true
//        navSearchButton.semanticContentAttribute  = .forceLeftToRight
//        navSearchButton.layer.borderWidth = 0
//        navSearchButton.backgroundColor = UIColor.white
//        navSearchButton.layer.cornerRadius = 35/2
//        navSearchButton.layer.masksToBounds = true

//        headerLabelView.addSubview(notificationButton)
//        notificationButton.anchor(top: nil, left: nil, bottom: nil, right: headerLabelView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
//        notificationButton.centerYAnchor.constraint(equalTo: headerLabelView.centerYAnchor).isActive = true
//        refreshNotifications()
        
        

//        headerLabelView.addSubview(navMapButton)
//        navMapButton.tintColor = UIColor.ianBlackColor()
//        navMapButton.setTitle(" Map ", for: .normal)
////        navMapButton.setTitleColor(UIColor.darkGray, for: .normal)
//        navMapButton.setTitleColor(UIColor.ianBlackColor(), for: .normal)
//        navMapButton.centerYAnchor.constraint(equalTo: headerLabelView.centerYAnchor).isActive = true
//        navMapButton.semanticContentAttribute  = .forceLeftToRight
//        navMapButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//        navMapButton.anchor(top: nil, left: nil, bottom: nil, right: headerLabelView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        navMapButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapMapButton)))
//        navMapButton.backgroundColor = UIColor.clear
//        navMapButton.layer.cornerRadius = 5
//        navMapButton.layer.masksToBounds = true
        
//        headerLabelView.addSubview(navGridToggleButton)
//        navGridToggleButton.anchor(top: nil, left: nil, bottom: nil, right: headerLabelView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
//        navGridToggleButton.centerYAnchor.constraint(equalTo: headerLabelView.centerYAnchor).isActive = true
//        navGridToggleButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
//        setupnavGridToggleButton()
        
//        headerLabelView.addSubview(navEmojiButton)
//        navEmojiButton.anchor(top: nil, left: nil, bottom: nil, right: headerLabelView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
//        navEmojiButton.addTarget(self, action: #selector(didTapNavEmoji), for: .touchUpInside)
//        navEmojiButton.layer.cornerRadius = 5
//        navEmojiButton.layer.masksToBounds = true
//        navEmojiButton.tintColor = UIColor.gray
//        navEmojiButton.layer.borderColor = UIColor.gray.cgColor
//        navEmojiButton.setTitleColor(UIColor.gray, for: .normal)
//        navEmojiButton.backgroundColor = UIColor.clear
//        navEmojiButton.layer.borderWidth = 0
//        navEmojiButton.alpha = 0.6
//        navEmojiButton.isHidden = false
//        updateEmojiButton()




        
        let optionsView = UIView()
        addSubview(optionsView)
        optionsView.anchor(top: headerView.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
        optionsView.addSubview(topSearchBar)
        topSearchBar.searchBarView.backgroundColor = UIColor.clear
        topSearchBar.alpha = 0.9
        topSearchBar.anchor(top: optionsView.topAnchor, left: optionsView.leftAnchor, bottom: optionsView.bottomAnchor, right: optionsView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        topSearchBar.navSearchButton.tintColor = UIColor.darkGray
        topSearchBar.isGridView = self.isGridView
        topSearchBar.showEmoji = true
        topSearchBar.delegate = self
        

//        setupSegmentControl()
//        optionsView.addSubview(sortSegmentControl)
//        sortSegmentControl.anchor(top: nil, left: optionsView.leftAnchor, bottom: optionsView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
//
//
//        optionsView.addSubview(navMapButton)
//        navMapButton.tintColor = UIColor.ianBlackColor()
//        navMapButton.setTitle(" Map ", for: .normal)
//        navMapButton.setTitleColor(UIColor.ianBlackColor(), for: .normal)
//
//        navMapButton.semanticContentAttribute  = .forceLeftToRight
//        navMapButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//        navMapButton.anchor(top: nil, left: nil, bottom: nil, right: optionsView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        navMapButton.centerYAnchor.constraint(equalTo: optionsView.centerYAnchor).isActive = true
//        navMapButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapMapButton)))
//        navMapButton.backgroundColor = UIColor.clear
//        navMapButton.layer.cornerRadius = 5
//        navMapButton.layer.masksToBounds = true


//        optionsView.addSubview(navMapButton)
//        navMapButton.tintColor = UIColor.darkGray
//        navMapButton.setTitle(" Map", for: .normal)
////        navMapButton.semanticContentAttribute  = .forceRightToLeft
//        navMapButton.anchor(top: nil, left: nil, bottom: nil, right: optionsView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
//        navMapButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapMapButton)))
//        navMapButton.centerYAnchor.constraint(equalTo: optionsView.centerYAnchor).isActive = true
//        navMapButton.rightAnchor.constraint(lessThanOrEqualTo: navGridToggleButton.leftAnchor, constant: 10).isActive = true
        
//        optionsView.addSubview(navGridToggleButton)
//        navGridToggleButton.tintColor = UIColor.ianBlackColor()
//        navGridToggleButton.setTitleColor(UIColor.ianBlackColor(), for: .normal)
//        navGridToggleButton.titleLabel?.font =  UIFont(font: .avenirNextBold, size: 13)
//
//        navGridToggleButton.backgroundColor = UIColor.white
//
//        navGridToggleButton.anchor(top: nil, left: sortSegmentControl.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
//        navGridToggleButton.rightAnchor.constraint(lessThanOrEqualTo: navMapButton.leftAnchor).isActive = true
//        navGridToggleButton.centerYAnchor.constraint(equalTo: optionsView.centerYAnchor).isActive = true
//        navGridToggleButton.isUserInteractionEnabled = true
//        navGridToggleButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapGridButton)))
//        navGridToggleButton.semanticContentAttribute  = .forceLeftToRight
//        navGridToggleButton.layer.cornerRadius = 5
//        navGridToggleButton.layer.masksToBounds = true
//        navGridToggleButton.layer.borderColor = navGridToggleButton.tintColor.cgColor
//        navGridToggleButton.layer.borderWidth = 1
//
//        navGridToggleButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
        
//        optionsView.addSubview(navSearchButton)
//        navSearchButton.anchor(top: nil, left: nil, bottom: nil, right: navGridToggleButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 10, width: 30, height: 30)
//    //        navSearchButton.leftAnchor.constraint(lessThanOrEqualTo: sortSegmentControl.rightAnchor).isActive = true
//        navSearchButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapSearchButton)))
////        navSearchButton.semanticContentAttribute  = .forceRightToLeft
//        navSearchButton.centerYAnchor.constraint(equalTo: optionsView.centerYAnchor).isActive = true
//        self.refreshSearchButton()

        

        



        
//        optionsView.addSubview(navGridToggleButton)
//        navGridToggleButton.anchor(top: nil, left: sortSegmentControl.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 10, width: 30, height: 30)
//        navGridToggleButton.centerYAnchor.constraint(equalTo: optionsView.centerYAnchor).isActive = true
//        navGridToggleButton.rightAnchor.constraint(lessThanOrEqualTo: navMapButton.leftAnchor, constant: 10).isActive = true
//        navGridToggleButton.isUserInteractionEnabled = true
//        navGridToggleButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapGridButton)))
        
//        sortSegmentControl.rightAnchor.constraint(lessThanOrEqualTo: navSearchButton)
//        sortSegmentControl.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor).isActive = true
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var timer = Timer()

    func scheduledTimerWithTimeInterval(){
        // Scheduling timer to Call the function "updateCounting" with the interval of 1 seconds
        timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.updateCounting), userInfo: nil, repeats: true)
    }
    
    var foodTagInt = 0

    
    @objc func updateCounting(){
        
        if self.displayedEmojis.count == 0 {
            self.navEmojiButton.setTitle("", for: .normal)
            return
        }
        
        foodTagInt += 1
        if foodTagInt >= displayedEmojis.count {
            foodTagInt = 0
        }

        let durationOfAnimationInSecond = 1.0
        
//        var emoji = self.displayedEmojis[self.foodTagInt]
//        if let emojiText = EmojiDictionary[emoji]?.capitalizingFirstLetter() {
//            emoji += " \(emojiText)"
//        } else {
//            self.updateCounting()
//            return
//        }
        
        
        UIView.transition(with: self.navEmojiButton, duration: durationOfAnimationInSecond, options: .transitionFlipFromBottom, animations: {
            if self.displayedEmojis.count > 0 {
                self.navEmojiButton.setTitle(self.displayedEmojis[self.foodTagInt], for: .normal)
            } else {
                self.navEmojiButton.setTitle("", for: .normal)
            }
            
            self.navEmojiButton.sizeToFit()
            
//            let emoji = self.displayedEmojis[self.foodTagInt]
//            guard let emojiText = EmojiDictionary[emoji]?.capitalizingFirstLetter() else {
//                self.navEmojiButton.text = emoji
//                return
//            }
//            self.foodEmojiLabel.text = emoji + " \(emojiText)"
            //            self.foodEmojiLabel.sizeToFit()
        }, completion: nil)
        
        
    }
    
    var displayedEmojisCounts: [String:Int] = [:] {
        didSet {
            let temp = self.displayedEmojisCounts.sorted(by: {$0.value > $1.value})
            var tempArray: [String] = []
            for (key, value) in temp {
                if value > 0 {
                    tempArray.append(key)
                }
            }
//            print("EmojiSummaryCV | \(displayUser?.username) | Loaded displayedEmojisCounts : \(displayedEmojisCounts.count) | \(displayedEmojisCounts)")
            self.displayedEmojis = tempArray

        }
    }
    
    var displayedEmojis: [String] = [] {
        didSet {
            updateCounting()
            print("UserSearchBar | Displayed Emojis: \(self.displayedEmojis.count)")
//            self.scheduledTimerWithTimeInterval()

//            self.refreshEmojiCollectionView()
//            self.updateEmojiButton()
        }
    }
    
    func updateEmojiButton() {
        var emojiButtonText = "🍕"
//        if self.displayedEmojis.count > 0 {
//            if !self.displayedEmojis[0].isEmptyOrWhitespace() {
//                emojiButtonText = self.displayedEmojis[0]
//            }
//        }

        emojiButtonText += " Emojis"
        navEmojiButton.setTitle(emojiButtonText, for: .normal)
        navEmojiButton.setImage(UIImage(), for: .normal)
    }
    
    @objc func didTapNavEmoji(){
//        showingEmojiBar = true
//        refreshEmojiCollectionView()
        self.topSearchBar.showingEmojiBar = true

//        navSearchButton.setTitle("", for: .normal)
//        navSearchButton.sizeToFit()
    }
    
    
}

extension NewLegitHomeHeader: postSortSegmentControlDelegate, postViewFormatSegmentControlDelegate, UserSearchBarDelegate {
    func didTapEmojiBackButton() {
//        self.navFeedTypeLabel.isHidden = false
//        self.navFeedTypeButton.isHidden = false
//        self.bringSubviewToFront(self.headerLabelView)
    }
    
    func didTapEmojiButton() {
//        self.navFeedTypeLabel.isHidden = true
//        self.navFeedTypeButton.isHidden = true
//        self.bringSubviewToFront(self.emojiSearchBar)
    }
    
    
    func didActivateSearchBar() {
        self.delegate?.didTapSearchButton()
    }
    
    func filterContentForSearchText(searchText: String) {
        self.delegate?.filterContentForSearchText(searchText)
    }
    
    func didTapAddTag(addTag: String) {
        self.delegate?.didTapAddTag(addTag: addTag)
    }
    
    func didRemoveTag(tag: String) {
        self.delegate?.didRemoveTag(tag: tag)
    }
    
    func didRemoveLocationFilter(location: String) {
        
    }
    
    func didRemoveRatingFilter(rating: String) {
        
    }
    
    func didTapCell(tag: String) {
            
    }
    
    func handleRefresh() {
        self.delegate?.handleRefresh()
    }
    

    @objc func didTapMapButton(){
        self.delegate?.didTapMapButton()
    }
    
    func refreshSearchButton() {
        self.navSearchButton.backgroundColor = self.viewFilter.isFiltering ? UIColor.ianLegitColor() : UIColor.clear
        self.navSearchButton.tintColor = self.viewFilter.isFiltering ? UIColor.ianWhiteColor() : UIColor.ianBlackColor()
        self.navSearchButton.layer.borderColor = self.viewFilter.isFiltering ? UIColor.ianWhiteColor().cgColor : UIColor.ianBlackColor().cgColor
    }
    
    @objc func didTapSearchButton() {
        self.delegate?.didTapSearchButton()
    }
    
    @objc func toggleNavFeedType() {
        self.delegate?.toggleFeedType()
    }
    
    @objc func didTapGridButton(){
        self.delegate?.didTapGridButton()
    }
    
    
    
    func setupSegmentControl() {
        TemplateObjects.postSortDelegate = self
        sortSegmentControl.selectedSegmentIndex = 0
        sortSegmentControl.addTarget(self, action: #selector(selectPostSort), for: .valueChanged)
    }
    
    @objc func selectPostSort(sender: UISegmentedControl) {
        let selectedSort = HeaderSortOptions[sender.selectedSegmentIndex]
        print("NewLegitHomeHeader | \(selectedSort) | selectPostSort")

        self.refreshSort(sender: sender)
        self.delegate?.headerSortSelected(sort: selectedSort)
    }
    
    @objc func refreshSort(sender: UISegmentedControl) {
        let selectedSort = HeaderSortOptions[sender.selectedSegmentIndex]
        let newTitle = headerSortDictionary[selectedSort]
        

        for (index, sortOptions) in HeaderSortOptions.enumerated()
        {
            var isSelected = (index == sender.selectedSegmentIndex)
            var displayFilter = (isSelected) ? newTitle : sortOptions
            sender.setTitle(displayFilter, forSegmentAt: index)
            sender.setWidth((isSelected) ? 100 : 70, forSegmentAt: index)
        }

    }
    
    func headerSortSelected(sort: String) {
        self.delegate?.headerSortSelected(sort: sort)
    }
    
    func postFormatSelected(format: String) {
        if format == postGrid && !isGridView {
            self.delegate?.didTapGridButton()
        } else if format == postList && isGridView {
            self.delegate?.didTapGridButton()
        }
    }
    
    func refreshSegmentValues() {
        
        if let sort = self.viewFilter.filterSort {
            if let index = HeaderSortOptions.firstIndex(of: sort) {
                self.sortSegmentControl.selectedSegmentIndex = index
            } else {
                self.sortSegmentControl.selectedSegmentIndex = 0
            }
        }
        
    }
    
    func setupnavGridToggleButton() {
        navGridToggleButton.tintColor = UIColor.gray
        navGridToggleButton.setTitleColor(UIColor.ianBlackColor(), for: .normal)
        navGridToggleButton.titleLabel?.font =  UIFont(font: .avenirNextBold, size: 12)
        navGridToggleButton.backgroundColor = UIColor.white
        navGridToggleButton.isUserInteractionEnabled = true
        navGridToggleButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleView)))
        navGridToggleButton.semanticContentAttribute  = .forceLeftToRight
        navGridToggleButton.layer.cornerRadius = 15
        navGridToggleButton.layer.masksToBounds = true
        navGridToggleButton.layer.borderColor = navGridToggleButton.tintColor.cgColor
        navGridToggleButton.layer.borderWidth = 0
        navGridToggleButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
        navGridToggleButton.backgroundColor = UIColor.clear
        
        var image = isGridView ? #imageLiteral(resourceName: "grid") : #imageLiteral(resourceName: "listFormat")
        navGridToggleButton.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
//        navGridToggleButton.isHidden = true
        
    }
    
    @objc func toggleView(){
        if !isGridView {
            self.delegate?.didTapGridButton()
        } else if isGridView {
            self.delegate?.didTapGridButton()
        }
    }
    
}
