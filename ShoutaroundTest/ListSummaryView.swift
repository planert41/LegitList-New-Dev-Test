//
//  UserSummaryCollectionViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/1/20.
//  Copyright © 2020 Wei Zou Ang. All rights reserved.
//

import UIKit

import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

private let reuseIdentifier = "Cell"

class ListSummaryView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, ListSummaryCellDelegate, UICollectionViewDelegateFlowLayout {

    var delegate: ListSummaryDelegate?
    var cellImageHeight: CGFloat = 120
    var cellDetailsHeight: CGFloat = 40
    var headerHeight: CGFloat = 30

    // DROP DOWN SELECTION
    let collectionView: UICollectionView = {
        let layout = UserSummaryFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.layer.borderWidth = 0
        cv.backgroundColor = UIColor.clear
        return cv
    }()
    
    var userId: String? = nil {
        didSet {
            guard let uid = userId else {return}
            if user?.uid != userId {
                Database.fetchUserWithUID(uid: uid) { (user) in
                    guard let user = user else {return}
                    self.user = user
                }
            }
        }
    }
    var user: User? = nil {
        didSet {
            guard let user = user else {return}
            if userId != user.uid {
                userId = user.uid
            }
            self.fetchUserLists()
            self.refreshHeaderLabels()
        }
    }
    var userLists: [List] = []
    
    var postId: String? = nil {
        didSet {
            guard let uid = postId else {return}
            if post?.id != uid {
                Database.fetchPostWithPostID(postId: uid) { (post, err) in
                    guard let post = post else {return}
                    self.post = post
                }
            }
        }
    }
    
    var post: Post? = nil {
        didSet {
            guard let post = post else {return}
            if postId != post.id {
                postId = post.id
            }
            
            print("ListSummaryView: \(post.id) | All \(post.allList.count) | Created \(post.creatorListId?.count) | Selected \(post.selectedListId?.count)")
            self.fetchListForPost()
            self.refreshHeaderLabels()
        }
    }
    
    
    
    // LISTS
    var postCreatorListIds: [String] = []
    var postCreatorListNames: [String] = []
    
    var postCurrentUserListIds: [String] = []
    var postCurrentUserListNames: [String] = []

// IF SHOWUSER FALSE - ONLY SHOW "CREATED LISTs" / "FOLLOWED LISTS"
    var showUser: Bool = false {
        didSet {
            self.refreshHeaderLabels()
        }
    }
    var displayFollowedList: Bool = false {
           didSet {
               self.refreshHeaderLabels()
           }
       }
    
// SORT LIST BY POST COUNT OR DATE
    var sortListByDate = true {
        didSet {
            self.fetchUserLists()
            self.refreshHeaderLabels()
        }
    }

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
    var hideProfileImageLayout: NSLayoutConstraint?
    var showProfileImageLayout: NSLayoutConstraint?

    lazy var listHeaderLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Created Lists"
        ul.font = UIFont(name: "Poppins-Bold", size: 20)
        ul.textColor = UIColor.ianBlackColor()
        ul.textAlignment = NSTextAlignment.left
        ul.numberOfLines = 1
        ul.backgroundColor = UIColor.clear
        return ul
    }()
    
    lazy var listSortButton: UIButton = {
        let button = UIButton(type: .system)
//        let img = #imageLiteral(resourceName: "dropdownXLarge").resizeImageWith(newSize: CGSize(width: 15, height: 15))
        let img = #imageLiteral(resourceName: "sort_descending_new")

        button.setImage(img.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.setTitleColor(UIColor.darkGray, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        button.tintColor = UIColor.ianLegitColor()
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.layer.borderWidth = 0
        button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 5, bottom: 3, right: 5)
        button.addTarget(self, action: #selector(toggleListSort), for: .touchUpInside)
        button.titleLabel?.textAlignment = .left
        button.semanticContentAttribute = .forceRightToLeft
        return button
    }()
    
    @objc func toggleListSort() {
        self.sortListByDate = !sortListByDate
        self.refreshListSortButton()
    }
    
    func refreshListSortButton() {
        let title = self.sortListByDate ? " Date " : " Posts "
        self.listSortButton.setTitle(title, for: .normal)
        self.listSortButton.sizeToFit()
    }

    func refreshHeaderLabels() {
        if showUser && self.user != nil {
            // LOAD USER
            guard let user = user else {return}
            let url = user.profileImageUrl
            profileImageView.loadImage(urlString: url)
            listHeaderLabel.text = user.username
            showProfileImage()
        } else if self.user != nil {
            let listCount = (self.userLists.count > 0) ? "\(String(self.userLists.count))" : ""

            if user?.uid == Auth.auth().currentUser?.uid {
//                listHeaderLabel.text = displayFollowedList ? "My Followed Lists \(listCount)" : "My Created Lists \(listCount)"
                listHeaderLabel.text = displayFollowedList ? "\(listCount) Followed Lists " : "\(listCount) Created Lists "

            } else {
//                listHeaderLabel.text = displayFollowedList ? "User Followed Lists \(listCount)" : "User Created Lists \(listCount)"
                listHeaderLabel.text = displayFollowedList ? "\(listCount) Followed Lists " : "\(listCount) Created Lists "
            }
            hideProfileImage()
        } else if self.post != nil {
            listHeaderLabel.text = "\(self.userLists.count) Tagged List"
            hideProfileImage()
        }
    }
    
    func showProfileImage() {
        showProfileImageLayout?.isActive = true
        hideProfileImageLayout?.isActive = false
        profileImageView.isHidden = false
    }
    
    func hideProfileImage() {
        showProfileImageLayout?.isActive = false
        hideProfileImageLayout?.isActive = true
        profileImageView.isHidden = true
    }
    

    func refreshAll() {
        self.userId = nil
        self.user = nil
        self.post = nil
        self.userLists = []
        self.showUser = false
        self.sortListByDate = false
        self.displayFollowedList = false
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let cell = UIView()
        addSubview(cell)
        cell.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: cellImageHeight + cellDetailsHeight + headerHeight + 5)
//        cell.backgroundColor = UIColor.yellow
        
        let headerView = UIView()
        addSubview(headerView)
        headerView.anchor(top: cell.topAnchor, left: cell.leftAnchor, bottom: nil, right: cell.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0  , height: headerHeight)
        
        headerView.addSubview(listSortButton)
        listSortButton.anchor(top: nil, left: nil, bottom: nil, right: headerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 0, height: 20)
        listSortButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        refreshListSortButton()
        
        headerView.addSubview(profileImageView)
        profileImageView.anchor(top: headerView.topAnchor, left: headerView.leftAnchor, bottom: headerView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 15, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)
        profileImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        profileImageViewWidth = profileImageView.widthAnchor.constraint(equalToConstant: 40)
        profileImageViewWidth?.isActive = true
        
        profileImageView.layer.cornerRadius = (headerHeight - 10)/2
        profileImageView.layer.masksToBounds = true
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapProfilePic)))

        
        headerView.addSubview(listHeaderLabel)
        listHeaderLabel.anchor(top: headerView.topAnchor, left: profileImageView.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
//        listHeaderLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        listHeaderLabel.rightAnchor.constraint(lessThanOrEqualTo: listSortButton.leftAnchor, constant: 5).isActive = true
        
        showProfileImageLayout = listHeaderLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 5)
        hideProfileImageLayout = listHeaderLabel.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 15)
        refreshHeaderLabels()
        
//        let bottomDiv = UIView()
//        bottomDiv.backgroundColor = UIColor.rgb(red: 221, green: 221, blue: 221)
//        addSubview(bottomDiv)
//        bottomDiv.anchor(top: headerView.bottomAnchor, left: cell.leftAnchor, bottom: nil, right: cell.rightAnchor, paddingTop: (divHeight/2) - 1, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 2)
        
        let imageViewContainer = UIView()
        addSubview(imageViewContainer)
        imageViewContainer.anchor(top: headerView.bottomAnchor, left: cell.leftAnchor, bottom: cell.bottomAnchor, right: cell.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0  , height: cellImageHeight + cellDetailsHeight + 5)

        
        // Register cell classes
        collectionView.register(ListSummaryCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = true
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 15, bottom: 5, right: 0)
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        collectionView.collectionViewLayout = layout
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.layoutIfNeeded()
        
        imageViewContainer.addSubview(collectionView)
        collectionView.anchor(top: imageViewContainer.topAnchor, left: imageViewContainer.leftAnchor, bottom: imageViewContainer.bottomAnchor, right: imageViewContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        self.fetchUserLists()
        // Do any additional setup after loading the view.
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    
    func resetViews(){
        collectionView.reloadData()
        if userLists.count > 0 {
            collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .left, animated: false)
        }
    }
    
    

    func didTapList(list: List?) {
        self.delegate?.didTapList(list: list)
    }
    

    func fetchUserLists(){
        // Load Lists
        guard let uid = userId else {return}
        
        if !displayFollowedList {
            Database.fetchCreatedListsForUser(userUid: uid) { (lists) in
                print(" ListSummaryCollectionViewController | \(lists.count) Lists | Created | \(self.user?.username) | \(uid) |")

                var tempLists: [List] = []

                if !self.sortListByDate {
                    // SORT BY POST COUNT
                    tempLists = lists.sorted { (l1, l2) -> Bool in
                        return (l1.postIds?.count ?? 0) > (l2.postIds?.count ?? 0)
                    }
                } else {
                    // SORT BY DATE
                    tempLists = lists.sorted { (l1, l2) -> Bool in
                        return l1.latestNotificationTime > l2.latestNotificationTime
                    }
                }

                self.userLists = tempLists
                print("fetchUserLists | Fetched \(tempLists.count) Lists")
                self.refreshHeaderLabels()
                self.collectionView.reloadData()
            }

        } else {
            Database.fetchFollowedListsForUser(userUid: uid) { (lists) in
                print("ListSummaryCollectionViewController | \(lists.count) Lists | Followed | \(self.user?.username) | \(uid) ")

                var tempLists: [List] = []

                if !self.sortListByDate {
                    // SORT BY POST COUNT
                    tempLists = lists.sorted { (l1, l2) -> Bool in
                        return (l1.postIds?.count ?? 0) > (l2.postIds?.count ?? 0)
                    }
                } else {
                    // SORT BY DATE
                    tempLists = lists.sorted { (l1, l2) -> Bool in
                        return l1.latestNotificationTime > l2.latestNotificationTime
                    }
                }

                self.userLists = tempLists
                self.refreshHeaderLabels()
                print("fetchFollowedLists | Fetched \(tempLists.count) Followed Lists")
                self.collectionView.reloadData()
            }
        }
    }
    
    func fetchListForPost(){
        
        postCreatorListIds = []
        postCreatorListNames = []
        postCurrentUserListIds = []
        postCurrentUserListNames = []
        
        // CREATOR TAGGED LISTS
        if self.post?.creatorListId != nil {
            for (key,value) in (self.post?.creatorListId)! {
                self.postCreatorListIds.append(key)
                self.postCreatorListNames.append(value)
            }
        }
        
        // CURRENT USER TAGGED LISTS
        if self.post?.selectedListId != nil && (self.post?.creatorUID != Auth.auth().currentUser?.uid) {
            for (key,value) in (self.post?.selectedListId)! {
                self.postCurrentUserListIds.append(key)
                self.postCurrentUserListNames.append(value)
            }
        }
        
        let tempListIds = self.postCreatorListIds + self.postCurrentUserListIds
        
        let allListIds = Array(Set(tempListIds))

            
        Database.fetchListForMultListIds(listUid: allListIds) { (lists) in
            print("ListSummaryView | \(lists.count) List Fetched For | \(self.post?.id) | \(allListIds)")
            self.userLists = lists
            self.refreshHeaderLabels()
            self.collectionView.reloadData()
        }
        
        
        
        
    }
    
    
    func didTapProfilePic() {
        guard let user = self.user else {return}
        self.delegate?.didTapUser(user: user)
    }
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        print("Displaying \(userLists.count) Lists | ListSummaryView")
        return userLists.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ListSummaryCell
        cell.list = self.userLists[indexPath.item]
        cell.isSelected = false
        cell.delegate = self
        
//        cell.layer.borderColor = CurrentUser.listIds.contains(self.userLists[indexPath.item].id ?? "") ? UIColor.ianLegitColor().cgColor : UIColor.gray.cgColor
        cell.layer.borderColor = UIColor.darkGray.cgColor
        cell.layer.borderWidth = 1
        cell.layer.applySketchShadow()

        cell.backgroundColor = UIColor.white
        
        cell.layer.shadowColor = UIColor.lightGray.cgColor
        cell.layer.shadowOffset = CGSize(width: 2.0, height: 1.0)
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 0.5
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: 14).cgPath
        cell.layer.cornerRadius = 10
        cell.layer.masksToBounds = true
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let list = self.userLists[indexPath.item]
        self.didTapList(list: list)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        //return CGSize(width: 100, height: 140)
        return CGSize(width: cellImageHeight, height: cellImageHeight + cellDetailsHeight)

    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
