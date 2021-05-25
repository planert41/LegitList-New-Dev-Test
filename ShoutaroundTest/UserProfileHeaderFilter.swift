//
//  ListViewHeader.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/7/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

protocol UserProfileHeaderFilterDelegate {
    func didChangeToGridView()
    func didChangeToPostView()
    func openFilter()
    func clearCaptionSearch()
    func openSearch(index: Int?)
    func headerSortSelected(sort: String)
    func didSignOut()
    
    func selectUserFollowers()
    func selectUserFollowing()
    func selectUserLists()
    
    func editUser()
}


class UserProfileHeaderFilter: UICollectionViewCell, UISearchBarDelegate, UIGestureRecognizerDelegate {
    
    var delegate: UserProfileHeaderFilterDelegate?
    var headerSortSegment = UISegmentedControl()
    var selectedSort: String = defaultRecentSort {
        didSet{
            if let index = HeaderSortOptions.firstIndex(of: self.selectedSort){
                if headerSortSegment.selectedSegmentIndex != index {
                    headerSortSegment.selectedSegmentIndex = index
                }
            }
        }
    }
    var selectedCaption: String? = nil {
        didSet{
            guard let selectedCaption = selectedCaption else {
                self.defaultSearchBar.text?.removeAll()
                return}
            self.defaultSearchBar.text = selectedCaption
        }
    }
    
    var searchBarView = UIView()
    var defaultSearchBar = UISearchBar()
    var enableSearchBar: Bool = true {
        didSet{
            // Hide Search Bar if not enabled
            if self.enableSearchBar{
                searchBarHeight?.constant = 40
                self.searchBarView.isHidden = false
                //                searchBarView.backgroundColor = UIColor.legitColor()
            } else {
                searchBarHeight?.constant = 0
                self.searchBarView.isHidden = true
                //                searchBarView.backgroundColor = UIColor.white
                self.defaultSearchBar.removeFromSuperview()
            }
        }
    }
    var searchBarHeight: NSLayoutConstraint?
    
    // Grid/List View Button
    var isGridView = true {
        didSet{
            formatButton.setImage(!self.isGridView ? #imageLiteral(resourceName: "grid") :#imageLiteral(resourceName: "postview"), for: .normal)
        }
    }
    
    lazy var formatButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(!self.isGridView ? #imageLiteral(resourceName: "grid") :#imageLiteral(resourceName: "postview"), for: .normal)
        button.addTarget(self, action: #selector(changeView), for: .touchUpInside)
        button.tintColor = UIColor.legitColor()
        return button
    }()
    
    @objc func changeView(){
        if isGridView{
            self.isGridView = false
            delegate?.didChangeToPostView()
        } else {
            self.isGridView = true
            delegate?.didChangeToGridView()
        }
    }
    
    
    // Filter Button
    
    var isFiltering: Bool = false {
        didSet{
            filterButton.backgroundColor = isFiltering ? UIColor.legitColor() : UIColor.clear
        
            if !isFiltering{
                self.isFilteringText = nil
            }
        }
    }
    
    var isFilteringText: String? = nil {
        didSet{
            if (isFilteringText != nil) && isFiltering {
                defaultSearchBar.text = isFilteringText
            } else {
                defaultSearchBar.text?.removeAll()
            }
        }
    }
    
    lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "filter").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(openFilter), for: .touchUpInside)
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.clipsToBounds = true
        return button
    }()
    
    @objc func openFilter(){
        self.delegate?.openFilter()
    }
    
    // Filter Header View
    let filterHeaderView = UIView()
    
    // Profile Views
    let profileView = UIView()
    
    
    var user: User? {
        didSet{
            guard let profileImageUrl = user?.profileImageUrl else {return}
            profileImageView.loadImage(urlString: profileImageUrl)
            usernameLabel.text = user?.username
//            statusText.text = user?.status
//
//            if user?.uid == Auth.auth().currentUser?.uid {
//                statusText.isEnabled = true
//            } else {
//                statusText.isEnabled = true
//            }
            setupEditFollowButton()
            setupSocialLabels()
        }
    }
    
    lazy var editProfileFollowButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Edit Profile", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 3
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.addTarget(self, action: #selector(handleEditProfileOrFollow), for: .touchUpInside)
        return button
    }()
    
    fileprivate func setupEditFollowButton() {
        guard let currentLoggedInUserID = Auth.auth().currentUser?.uid else {return}
        guard let userId = user?.uid else {return}
        
        if currentLoggedInUserID == userId {
            
            //                Edit Profile
            self.editProfileFollowButton.setTitle("Edit Profile", for: .normal)
        }else {
            
            // check if following
            Database.database().reference().child("following").child(currentLoggedInUserID).child(userId).observeSingleEvent(of: .value, with: { (snapshot) in
                
                if let isFollowing = snapshot.value as? Int, isFollowing == 1 {
                    
                    self.editProfileFollowButton.setTitle("Unfollow", for: .normal)
                    
                } else{
                    self.setupFollowStyle()
                    
                }
                
            }, withCancel: { (err) in
                
                print("Failed to check if following", err)
                
            })
            
        }
    }
    
    @objc func handleEditProfileOrFollow() {
        
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else {return}
        guard let userId = user?.uid else {return}
        if (currentLoggedInUserId == userId && self.editProfileFollowButton.titleLabel?.text == "Edit Profile"){
            self.delegate?.editUser()
        } else {
            Database.handleFollowing(userUid: userId) { }
            self.user?.isFollowing = !(self.user?.isFollowing)!
            self.setupFollowStyle()
        }
    }
    
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        return iv
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "username"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    fileprivate func setupFollowStyle(){
        
        if (user?.isFollowing)!{
            self.editProfileFollowButton.setTitle("Following", for: .normal)
            self.editProfileFollowButton.backgroundColor = UIColor.white
            self.editProfileFollowButton.titleLabel?.textColor = UIColor.ianLegitColor()
            self.editProfileFollowButton.layer.borderColor = UIColor.ianLegitColor().cgColor
        } else {
            self.editProfileFollowButton.setTitle("Follow", for: .normal)
            self.editProfileFollowButton.backgroundColor = UIColor.ianLegitColor()
            self.editProfileFollowButton.titleLabel?.textColor = UIColor.white
            self.editProfileFollowButton.layer.borderColor = UIColor.white.cgColor
        }

    }
    
    let socialLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let followingLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let followersLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let listLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let postsLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        return label
    }()
    
    var followStackView = UIStackView()
    var listPostStackView = UIStackView()
    var profileCountStackView = UIStackView()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white

        
//  Filter Header View
        addSubview(filterHeaderView)
        filterHeaderView.backgroundColor = UIColor.white
        filterHeaderView.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 80)
        
        // Search Bar View
        filterHeaderView.addSubview(searchBarView)
        searchBarView.anchor(top: filterHeaderView.topAnchor, left: filterHeaderView.leftAnchor, bottom: nil, right: filterHeaderView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        searchBarHeight = searchBarView.heightAnchor.constraint(equalToConstant: 40)
        searchBarHeight?.isActive = true
        searchBarView.backgroundColor = UIColor.legitColor().withAlphaComponent(0.75)
        
        setupSearchBar()
        searchBarView.addSubview(defaultSearchBar)
        defaultSearchBar.anchor(top: searchBarView.topAnchor, left: searchBarView.leftAnchor, bottom: searchBarView.bottomAnchor, right: searchBarView.rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: (searchBarHeight?.constant)! * 0.75)
        
        
        //        defaultSearchBar.centerYAnchor.constraint(equalTo: searchBarView.centerYAnchor).isActive = true
        
        filterHeaderView.addSubview(filterButton)
        filterButton.anchor(top: searchBarView.bottomAnchor, left: nil, bottom: bottomAnchor, right: rightAnchor, paddingTop: 1, paddingLeft: 1, paddingBottom: 1, paddingRight: 3, width: 0, height: 0)
        filterButton.widthAnchor.constraint(equalTo: filterButton.heightAnchor, multiplier: 1).isActive = true
        //        filterButton.layer.cornerRadius = filterButton.frame.width/2
        filterButton.layer.masksToBounds = true
        
        filterHeaderView.addSubview(formatButton)
        formatButton.anchor(top: searchBarView.bottomAnchor, left: nil, bottom: filterHeaderView.bottomAnchor, right: filterButton.leftAnchor, paddingTop: 1, paddingLeft: 1, paddingBottom: 1, paddingRight: 3, width: 0, height: 0)
        formatButton.widthAnchor.constraint(equalTo: formatButton.heightAnchor, multiplier: 1).isActive = true
        //        formatButton.layer.cornerRadius = formatButton.frame.width/2
        formatButton.layer.masksToBounds = true
        
        headerSortSegment = UISegmentedControl(items: HeaderSortOptions)
        headerSortSegment.selectedSegmentIndex = HeaderSortOptions.firstIndex(of: self.selectedSort)!
        headerSortSegment.addTarget(self, action: #selector(selectSort), for: .valueChanged)
        headerSortSegment.tintColor = UIColor.legitColor()
        
        filterHeaderView.addSubview(headerSortSegment)
        headerSortSegment.anchor(top: searchBarView.bottomAnchor, left: filterHeaderView.leftAnchor, bottom: filterHeaderView.bottomAnchor, right: formatButton.leftAnchor, paddingTop: 5, paddingLeft: 3, paddingBottom: 5, paddingRight: 1, width: 0, height: 0)

        
//  Profile View
        addSubview(profileView)
        profileView.backgroundColor = UIColor.white
        profileView.anchor(top: topAnchor, left: leftAnchor, bottom: filterHeaderView.topAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        profileView.addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 80, height: 80)
        profileImageView.layer.cornerRadius = 80/2
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        
        profileView.addSubview(usernameLabel)
        usernameLabel.anchor(top: profileImageView.bottomAnchor, left: profileImageView.leftAnchor, bottom: nil, right: profileImageView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 15)
        usernameLabel.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor).isActive = true
        usernameLabel.adjustsFontSizeToFitWidth = true
        
//        profileView.addSubview(socialLabel)
//        socialLabel.anchor(top: usernameLabel.bottomAnchor, left: profileImageView.leftAnchor, bottom: nil, right: profileImageView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 15)
//        socialLabel.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor).isActive = true


        let profileCountView = UIView()
        addSubview(profileCountView)
        profileCountView.anchor(top: profileImageView.topAnchor, left: profileImageView.rightAnchor, bottom: profileImageView.centerYAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        
        profileCountStackView = UIStackView(arrangedSubviews: [postsLabel, listLabel, followersLabel, followingLabel])
        profileCountStackView.distribution = .fillEqually
        profileCountStackView.axis = .horizontal
        addSubview(profileCountStackView)
        profileCountStackView.anchor(top: nil, left: profileCountView.leftAnchor, bottom: nil, right: profileCountView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        profileCountStackView.centerYAnchor.constraint(equalTo: profileCountView.centerYAnchor).isActive = true
        
        // Edit Profile Button
        profileView.addSubview(editProfileFollowButton)
        editProfileFollowButton.anchor(top: profileCountView.bottomAnchor, left: profileImageView.rightAnchor, bottom: profileImageView.bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 20, paddingBottom: 5, paddingRight: 20, width: 0, height: 0)
        
        
    // Follow StackView
//        let followView = UIView()
//        let listView = UIView()
//
//        var verticalStackView = UIStackView(arrangedSubviews: [followView,listView])
//        verticalStackView.distribution = .fillEqually
//        verticalStackView.axis = .vertical
//        addSubview(verticalStackView)
//        verticalStackView.anchor(top: profileImageView.topAnchor, left: profileImageView.rightAnchor, bottom: profileImageView.bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
//
//        followStackView = UIStackView(arrangedSubviews: [followersLabel,followingLabel])
//        followStackView.distribution = .fillEqually
//        followStackView.axis = .horizontal
//
//        addSubview(followStackView)
//        followStackView.anchor(top: nil, left: followView.leftAnchor, bottom: nil, right: followView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        followStackView.centerYAnchor.constraint(equalTo: followView.centerYAnchor).isActive = true
//
//    // List Post StackView
//        listPostStackView = UIStackView(arrangedSubviews: [listLabel,postsLabel])
//        listPostStackView.distribution = .fillEqually
//        listPostStackView.axis = .horizontal
//        addSubview(listPostStackView)
//        listPostStackView.anchor(top: nil, left: listView.leftAnchor, bottom: nil, right: listView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        listPostStackView.centerYAnchor.constraint(equalTo: listView.centerYAnchor).isActive = true
//
//
//    // Edit Profile Button
//        profileView.addSubview(editProfileFollowButton)
//        editProfileFollowButton.anchor(top: listView.bottomAnchor, left: usernameLabel.rightAnchor, bottom: nil, right: listPostStackView.rightAnchor, paddingTop: 5, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 30)
        
    }
    
    func setupSocialLabels(){
        let postCount = user?.posts_created ?? 0
        let followingCount = user?.followingCount ?? 0
        let followerCount = user?.followersCount ?? 0
        let listCount = user?.lists_created ?? 0
        let voteCount = user?.votes_received ?? 0
        
        
        let socialLabelColor = UIColor.gray
        let socialMetricColor = UIColor.legitColor()
        
        let voteLabelSize = 12 as CGFloat
        let socialLabelSize = 15 as CGFloat
        
        let countFontSize = 15 as CGFloat
        let unitFontSize = 12 as CGFloat
        
    // Social Vote Counts
        if voteCount > 0 {
            
            var attributedString = NSMutableAttributedString(string: "\(String(voteCount))  ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: voteLabelSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): socialLabelColor]))
            let voteImage = NSTextAttachment()
            voteImage.image = #imageLiteral(resourceName: "pin_filled").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: CGSize(width: voteLabelSize, height: voteLabelSize))
            let voteImageString = NSAttributedString(attachment: voteImage)
            attributedString.append(voteImageString)
            self.socialLabel.attributedText = attributedString
        }
        
    // Followers Label
        
        var attributedMetric = NSMutableAttributedString(string: "\(String(followerCount))", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: countFontSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): socialMetricColor]))
        var attributedLabel = NSMutableAttributedString(string: "\n followers", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: unitFontSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): socialLabelColor]))

        
        attributedMetric.append(attributedLabel)
        self.followersLabel.attributedText = attributedMetric
        self.followersLabel.sizeToFit()
        self.followersLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectFollowers)))
        self.followersLabel.isUserInteractionEnabled = true

        
    // Following Label

        attributedMetric = NSMutableAttributedString(string: "\(String(followingCount))", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: countFontSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): socialMetricColor]))
        attributedLabel = NSMutableAttributedString(string: "\n following", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: unitFontSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): socialLabelColor]))
        
        attributedMetric.append(attributedLabel)
        self.followingLabel.attributedText = attributedMetric
        self.followingLabel.sizeToFit()
        self.followingLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectFollowing)))
        self.followingLabel.isUserInteractionEnabled = true

        
    // List Count Label
        attributedMetric = NSMutableAttributedString(string: "\(String(listCount))", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: countFontSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): socialMetricColor]))
        attributedLabel = NSMutableAttributedString(string: "\n lists", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: unitFontSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): socialLabelColor]))
        
        attributedMetric.append(attributedLabel)
        self.listLabel.attributedText = attributedMetric
        self.listLabel.sizeToFit()
        self.listLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectLists)))
        self.listLabel.isUserInteractionEnabled = true

    
    // Post Count Label
        attributedMetric = NSMutableAttributedString(string: "\(String(postCount))", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: countFontSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): socialMetricColor]))
        attributedLabel = NSMutableAttributedString(string: "\n posts", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: unitFontSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): socialLabelColor]))
    
        attributedMetric.append(attributedLabel)
        self.postsLabel.attributedText = attributedMetric
        self.postsLabel.sizeToFit()
        
    
    }
    
    @objc func selectFollowers(){
        print("User Profile: Select Follower")
        self.delegate?.selectUserFollowers()
    }
    
    @objc func selectFollowing(){
        print("User Profile: Select Following")
        self.delegate?.selectUserFollowing()
    }
    
    @objc func selectLists(){
        print("User Profile: Select Lists")
        self.delegate?.selectUserLists()
    }
    
    
    func setupSearchBar(){
        defaultSearchBar.layer.cornerRadius = 25/2
        defaultSearchBar.clipsToBounds = true
        defaultSearchBar.searchBarStyle = .prominent
        defaultSearchBar.barTintColor = UIColor.white
        //        defaultSearchBar.backgroundImage = UIImage()
        defaultSearchBar.layer.borderWidth = 0
        defaultSearchBar.placeholder = "Search Posts For"
        defaultSearchBar.delegate = self
        
        for s in defaultSearchBar.subviews[0].subviews {
            if s is UITextField {
                //                    s.layer.cornerRadius = 25/2
                //                    s.layer.borderWidth = 0.5
                //                    s.layer.borderColor = UIColor.legitColor().cgColor
            }
        }
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        self.delegate?.openSearch(index: 0)
        return false
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText.count == 0) {
            searchBar.endEditing(true)
            self.selectedCaption = nil
            self.delegate?.clearCaptionSearch()
        }
    }
    
    @objc func selectSort(sender: UISegmentedControl) {
        self.selectedSort = HeaderSortOptions[sender.selectedSegmentIndex]
        delegate?.headerSortSelected(sort: self.selectedSort)
        print("Selected Sort is ",self.selectedSort)
    }
    
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
