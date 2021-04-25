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

class PostByRatingEmojiViewController: UIView, UICollectionViewDelegate, UICollectionViewDataSource, ListPostSummaryGridPhotoCellDelegate, UICollectionViewDelegateFlowLayout {
    
    var userId: String? = nil {
        didSet {
            guard let uid = userId else {return}
            Database.fetchUserWithUID(uid: uid) { (user) in
                guard let user = user else {return}
                self.user = user
            }
        }
    }
    var user: User? = nil {
        didSet {
            guard let user = user else {return}
            self.fetchFilterPosts()
        }
    }
    
    // DROP DOWN SELECTION
    let collectionView: UICollectionView = {
        let layout = UserSummaryFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.layer.borderWidth = 0
        cv.backgroundColor = UIColor.clear
        return cv
    }()
    
    var delegate: ListPostSummaryDelegate?
    var sortListByDate = true {
        didSet {
            self.fetchFilterPosts()
        }
    }

//    lazy var listHeaderLabel: UILabel = {
//        let ul = UILabel()
//        ul.text = "Created Lists"
//        ul.backgroundColor = UIColor.clear
//        ul.font = UIFont(name: "Poppins-Bold", size: 30)
//        ul.textColor = UIColor.ianBlackColor()
//        ul.textAlignment = NSTextAlignment.left
//        ul.numberOfLines = 1
//        ul.backgroundColor = UIColor.clear
//        return ul
//    }()
    
    lazy var listHeaderLabel: UIButton = {
        let button = UIButton(type: .system)
        let img = #imageLiteral(resourceName: "bookmark_filled").resizeImageWith(newSize: CGSize(width: 15, height: 15))
        button.setImage(img.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.setTitleColor(UIColor.darkGray, for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 20)
        button.semanticContentAttribute = .forceRightToLeft
        button.tintColor = UIColor.ianLegitColor()
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.layer.borderWidth = 0
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        button.semanticContentAttribute  = .forceLeftToRight

//        button.addTarget(self, action: #selector(toggleListSort), for: .touchUpInside)
        return button
    }()
    
    lazy var listSortButton: UIButton = {
        let button = UIButton(type: .system)
        let img = #imageLiteral(resourceName: "dropdownXLarge").resizeImageWith(newSize: CGSize(width: 15, height: 15))
        button.setImage(img.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.setTitleColor(UIColor.darkGray, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        button.semanticContentAttribute = .forceRightToLeft
        button.tintColor = UIColor.ianLegitColor()
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.layer.borderWidth = 0
        button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 5, bottom: 3, right: 5)
        button.addTarget(self, action: #selector(toggleListSort), for: .touchUpInside)
        return button
    }()
    
    var selectedRatingEmoji: String? = nil
    
    var ratingEmojiSegment = UISegmentedControl()
    
    func setupRatingEmojiSegment() {
        ratingEmojiSegment = UISegmentedControl(items: extraRatingEmojis)
        if #available(iOS 13.0, *) {
            ratingEmojiSegment.selectedSegmentTintColor = UIColor.ianLegitColor()
        }
        ratingEmojiSegment.addTarget(self, action: #selector(PostByRatingEmojiViewController.selectRatingEmoji), for: .valueChanged)
        ratingEmojiSegment.selectedSegmentIndex = 4
    }

    @objc func selectRatingEmoji(sender: UISegmentedControl) {
        let ratingEmoji = extraRatingEmojis[sender.selectedSegmentIndex]
        self.selectedRatingEmoji = extraRatingEmojis[sender.selectedSegmentIndex]
        self.fetchFilterPosts()
        print("\(ratingEmoji) | selectRatingEmoji")
    }
    

    
    @objc func toggleListSort() {
        self.sortListByDate = !sortListByDate
        self.refreshListSortButton()
    }
    
    func refreshListSortButton() {
        let title = self.sortListByDate ? "Date " : "Distance "
        self.listSortButton.setTitle(title, for: .normal)
        self.listSortButton.sizeToFit()
    }

    
    func updateList() {
//        self.listHeaderLabel.text = self.currentDisplayList?.name
//        self.listHeaderLabel.setTitle(self.currentDisplayList?.name, for: .normal)
//        self.
        self.fetchFilterPosts()
    }
    
    func refreshAll() {
        self.userId = nil
        self.user = nil
        self.displayedPosts = []
        self.sortListByDate = false
        self.ratingEmojiSegment.selectedSegmentIndex = 4
        self.selectedRatingEmoji = extraRatingEmojis[4]
        
    }
    
    var displayedPosts: [Post] = []
    
    var imageHeight: CGFloat = 110
    var headerHeight: CGFloat = 35
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.backgroundGrayColor()

        let cell = UIView()
        addSubview(cell)
        cell.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: imageHeight + headerHeight)
//        cell.backgroundColor = UIColor.yellow
        
// HEADER
        let headerView = UIView()
        addSubview(headerView)
        headerView.anchor(top: cell.topAnchor, left: cell.leftAnchor, bottom: nil, right: cell.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0  , height: headerHeight)
        
        headerView.addSubview(listSortButton)
        listSortButton.anchor(top: nil, left: nil, bottom: nil, right: headerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        listSortButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        refreshListSortButton()
        
        setupRatingEmojiSegment()
        headerView.addSubview(ratingEmojiSegment)
        ratingEmojiSegment.anchor(top: headerView.topAnchor, left: headerView.leftAnchor, bottom: headerView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 3, paddingRight: 0, width: 0, height: 0)
        ratingEmojiSegment.rightAnchor.constraint(lessThanOrEqualTo: listSortButton.leftAnchor).isActive = true
        
//        headerView.addSubview(listHeaderLabel)
//        listHeaderLabel.anchor(top: nil, left: headerView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
//        listHeaderLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
//        listHeaderLabel.rightAnchor.constraint(lessThanOrEqualTo: listSortButton.leftAnchor, constant: 10)
//        listHeaderLabel.isUserInteractionEnabled = true
////        listHeaderLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapName)))
//        listHeaderLabel.addTarget(self, action: #selector(didTapName), for: .touchUpInside)

        
// IMAGE VIEWS
        let imageViewContainer = UIView()
        addSubview(imageViewContainer)
        imageViewContainer.anchor(top: headerView.bottomAnchor, left: cell.leftAnchor, bottom: cell.bottomAnchor, right: cell.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0  , height: imageHeight)

        
        // Register cell classes
        collectionView.register(ListPostSummaryGridPhotoCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = true
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        collectionView.collectionViewLayout = layout
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.layoutIfNeeded()
        
        imageViewContainer.addSubview(collectionView)
        collectionView.anchor(top: imageViewContainer.topAnchor, left: imageViewContainer.leftAnchor, bottom: imageViewContainer.bottomAnchor, right: imageViewContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        self.fetchFilterPosts()
        // Do any additional setup after loading the view.
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    
    func resetViews(){
        if displayedPosts.count > 0 {
            collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .left, animated: false)
            collectionView.reloadData()
        }
    }
    
    
    func fetchFilterPosts() {
        guard let uid = self.user?.uid else {return}
        Database.fetchAllPostWithUID(creatoruid: uid) { (fetchedPosts) in
            var filter = Filter.init()
            filter.filterRatingEmoji = self.selectedRatingEmoji
            filter.filterSort = self.sortListByDate ? defaultRecentSort : defaultNearestSort
            Database.filterPostsNew(inputPosts: fetchedPosts, postFilter: filter) { (filteredPosts) in
                let tempPosts = filteredPosts ?? []
                print("\(self.selectedRatingEmoji) Emoji | Filtered \(tempPosts.count) | Fetched \(fetchedPosts.count)")
                self.displayedPosts = tempPosts
                self.collectionView.reloadData()
            }
        }
    }

//    func fetchPostsForList(){
//        // Load Lists
//        guard let list = self.currentDisplayList else {return}
//
//        Database.fetchPostFromList(list: list) { (posts) in
//            print("fetchPostsForList | \(posts?.count) Posts | \(list.name) - \(list.id)")
//            guard let posts = posts else {
//                self.displayedPosts = []
//                self.collectionView.reloadData()
//                return
//            }
//
//            var tempPosts: [Post] = []
//            if self.sortListByDate {
//                tempPosts = posts.sorted { (p1, p2) -> Bool in
//                    return p1.listedDate?.compare((p2.listedDate)!) == .orderedDescending
//                }
//            } else {
//                tempPosts = posts.sorted { (p1, p2) -> Bool in
//                    return (p1.distance ?? 0) <= (p2.distance ?? 0)
//                }
//            }
//
//
//            self.displayedPosts = tempPosts
//            self.collectionView.reloadData()
//        }
//
//    }

    func didTapPicture(post: Post) {
        self.delegate?.didTapPicture(post: post)
    }
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        print("   ~ ListPostSummary |Displaying \(displayedPosts.count) Lists")
        return displayedPosts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ListPostSummaryGridPhotoCell
        cell.post = self.displayedPosts[indexPath.item]
        cell.delegate = self
        cell.backgroundColor = UIColor.white
//        cell.layer.borderColor = UIColor.lightGray.cgColor
//        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 3
        cell.layer.masksToBounds = true
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let post = self.displayedPosts[indexPath.item]
        self.didTapPicture(post: post)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: imageHeight, height: imageHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 3
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
