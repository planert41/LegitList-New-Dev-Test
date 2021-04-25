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


class RatingEmojiPostViewController: UIView, UICollectionViewDelegate, UICollectionViewDataSource, ListPostSummaryGridPhotoCellDelegate, UICollectionViewDelegateFlowLayout {

    
    var currentDisplayListId: String? = nil {
        didSet {
            guard let listId = currentDisplayListId else {return}
            Database.fetchListforSingleListId(listId: listId) { (list) in
                guard let list = list else {return}
                self.currentDisplayList = list
            }
        }
    }
    var currentDisplayList: List? = nil {
        didSet {
            self.updateList()
        }
    }
    
    var currentUserId: String? = nil {
        didSet {
            guard let uid = currentUserId else {return}
            Database.fetchUserWithUID(uid: uid, completion: { (user) in
                guard let user = user else {return}
                self.currentUser = user
            })
        }
    }
    
    var currentUser: User? = nil {
        didSet {
            self.fetchPostsForUser()
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
            self.fetchPostsForList()
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
        button.titleLabel?.font = UIFont(font: .avenirNextBold, size: 20)
        button.semanticContentAttribute = .forceRightToLeft
        button.tintColor = UIColor.ianLegitColor()
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.layer.borderWidth = 0
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        button.semanticContentAttribute  = .forceRightToLeft

//        button.addTarget(self, action: #selector(toggleListSort), for: .touchUpInside)
        return button
    }()
    
    lazy var listSortButton: UIButton = {
        let button = UIButton(type: .system)
        let img = #imageLiteral(resourceName: "sort_descending_new")
//        let img = #imageLiteral(resourceName: "dropdownXLarge").resizeImageWith(newSize: CGSize(width: 15, height: 15))
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
    
    @objc func toggleListSort() {
        self.sortListByDate = !sortListByDate
        self.refreshListSortButton()
    }
    
    func refreshListSortButton() {
        let title = self.sortListByDate ? "Date " : "Distance "
        self.listSortButton.setTitle(title, for: .normal)
        self.listSortButton.sizeToFit()
        self.listSortButton.isHidden = !self.showHeader
    }

    
    func updateList() {
//        self.listHeaderLabel.text = self.currentDisplayList?.name
        self.listHeaderLabel.setTitle(self.currentDisplayList?.name, for: .normal)
        self.fetchPostsForList()
    }
    
    var displayedPosts: [Post] = []
    var filteredPosts: [Post] = []

    var imageHeight: CGFloat = 140 + 20 {
        didSet {
            self.updateConstraints()
            self.layoutIfNeeded()
        }
    }
    
    var imageDetailHeight: CGFloat = 30 {
        didSet {
            self.updateConstraints()
            self.layoutIfNeeded()
        }
    }
    
    var headerHeight: CGFloat = 35 {
        didSet {
            self.updateConstraints()
            self.layoutIfNeeded()
        }
    }
    
    var showDetails = true {
        didSet {
            self.updateConstraints()
            self.layoutIfNeeded()
        }
    }
    
    var showHeader: Bool = true {
        didSet {
            self.headerView.isHidden = !self.showHeader
            self.listSortButton.isHidden = !self.showHeader
            self.listHeaderLabel.isHidden = !self.showHeader

            self.setNeedsDisplay()
            self.reloadInputViews()
        }
    }
    
    let headerView = UIView()

        
    var filterSegment = UISegmentedControl()
    var selectedFilterSegmentIndex: Int = 0
    var selectedFilterRatingEmoji: String? = nil

    func setupfilterSegment() {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attributes = [
            NSAttributedString.Key.foregroundColor : UIColor.white,
            NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 13),
            NSAttributedString.Key.paragraphStyle: paragraph
        ]
        
        let selectedAttributes = [
            NSAttributedString.Key.foregroundColor : UIColor.ianWhiteColor(),
            NSAttributedString.Key.font : UIFont(font: .avenirNextBold, size: 13),
            NSAttributedString.Key.paragraphStyle: paragraph
        ]
        
        let unSelectedAttributes = [
            NSAttributedString.Key.foregroundColor : UIColor.ianBlackColor(),
            NSAttributedString.Key.font : UIFont(font: .avenirNextBold, size: 12),
            NSAttributedString.Key.paragraphStyle: paragraph
        ]
        
        filterSegment.setTitleTextAttributes(unSelectedAttributes, for: .normal)
        filterSegment.setTitleTextAttributes(selectedAttributes, for: .selected)
        filterSegment.apportionsSegmentWidthsByContent = true
        filterSegment.tintColor = UIColor.ianWhiteColor()
        filterSegment = UISegmentedControl(items: extraRatingEmojis)
        filterSegment.backgroundColor = UIColor.clear
        filterSegment.addTarget(self, action:
            #selector(searchSegmentChange), for: .valueChanged)

//        searchSegment.setTitleTextAttributes(attributes, for: .normal)
        if #available(iOS 13.0, *) {
            filterSegment.selectedSegmentTintColor = UIColor.ianLegitColor()
        }
        self.selectedFilterSegmentIndex = 0
        filterSegment.selectedSegmentIndex = 0
    }
    
    @objc func searchSegmentChange(sender: UISegmentedControl) {
        // Change Selected Segment First
        let searchType = String(LegitSearchBarOptions[self.selectedFilterSegmentIndex] ?? "")
        let searchTypeText = String(SearchSegmentLookup[searchType] ?? "")
        
        sender.setWidth(120, forSegmentAt: sender.selectedSegmentIndex)
        sender.setTitle("\(searchType) \(searchTypeText)", forSegmentAt: sender.selectedSegmentIndex)

        self.selectedFilterSegmentIndex = sender.selectedSegmentIndex
        self.selectedFilterRatingEmoji = extraRatingEmojis[self.selectedFilterSegmentIndex]
        self.collectionView.reloadData()
        print("Search Segment | \(searchTypeText) , \(searchType) | \(sender.selectedSegmentIndex)")
    }
    
    let cell = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ianWhiteColor()
        let detailHeight = showDetails ? imageDetailHeight : 0
        
        addSubview(cell)
        cell.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: imageHeight + (showHeader ? 0  : headerHeight) + detailHeight)
        cell.backgroundColor = UIColor.ianWhiteColor()
        cell.layer.applySketchShadow()
//        cell.backgroundColor = UIColor.yellow
        
// HEADER - BOOKMARK LABEL + SORT BUTTON
        addSubview(headerView)
        headerView.anchor(top: cell.topAnchor, left: cell.leftAnchor, bottom: nil, right: cell.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0  , height: showHeader ? 0 : headerHeight)
        headerView.isHidden = !showHeader
        
        headerView.addSubview(listSortButton)
        listSortButton.anchor(top: nil, left: nil, bottom: nil, right: headerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        listSortButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        refreshListSortButton()
        listSortButton.isHidden = !showHeader

        headerView.addSubview(listHeaderLabel)
        listHeaderLabel.anchor(top: nil, left: headerView.leftAnchor, bottom: headerView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
//        listHeaderLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        listHeaderLabel.rightAnchor.constraint(lessThanOrEqualTo: listSortButton.leftAnchor, constant: 10)
        listHeaderLabel.isUserInteractionEnabled = true
//        listHeaderLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapName)))
        listHeaderLabel.addTarget(self, action: #selector(didTapName), for: .touchUpInside)
        listHeaderLabel.isHidden = !self.showHeader
        
// IMAGES - COLLECTION VIEW
        let imageViewContainer = UIView()
        addSubview(imageViewContainer)
        imageViewContainer.anchor(top: headerView.bottomAnchor, left: cell.leftAnchor, bottom: cell.bottomAnchor, right: cell.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0  , height: imageHeight + detailHeight + 10)
        imageViewContainer.backgroundColor = UIColor.clear
//        imageViewContainer.backgroundColor = UIColor.clear

        
        // Register cell classes
        collectionView.register(ListPostSummaryGridPhotoCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = true
        collectionView.contentInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 0)
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        collectionView.collectionViewLayout = layout
        collectionView.showsHorizontalScrollIndicator = false
//        collectionView.backgroundColor = UIColor.pinterestRedColor().withAlphaComponent(0.5)
        collectionView.backgroundColor = UIColor.lightBackgroundGrayColor()

        collectionView.layoutIfNeeded()
        
        imageViewContainer.addSubview(collectionView)
        collectionView.anchor(top: imageViewContainer.topAnchor, left: imageViewContainer.leftAnchor, bottom: imageViewContainer.bottomAnchor, right: imageViewContainer.rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 2, paddingRight: 0, width: 0, height: 0)
//        collectionView.anchor(top: imageViewContainer.topAnchor, left: imageViewContainer.leftAnchor, bottom: imageViewContainer.bottomAnchor, right: imageViewContainer.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)

        self.fetchPostsForList()
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
    
    @objc func didTapName() {
        guard let list = self.currentDisplayList else {return}
        self.delegate?.didTapList(list: list)
    }

    func fetchPostsForUser() {
        guard let uid = self.currentUser?.uid else {return}
        Database.fetchAllPostWithUID(creatoruid: uid) { (posts) in
            print("fetchPostsForUser | \(posts.count) Posts | \(self.currentUser?.username) - \(uid)")
            
            var tempPosts: [Post] = []
            if self.sortListByDate {
                tempPosts = posts.sorted { (p1, p2) -> Bool in
                    return p1.listedDate?.compare((p2.listedDate)!) == .orderedDescending
                }
            } else {
                tempPosts = posts.sorted { (p1, p2) -> Bool in
                    return (p1.distance ?? 0) <= (p2.distance ?? 0)
                }
            }
            
            
            self.displayedPosts = tempPosts
            self.collectionView.reloadData()
        }
    }
    
    func filterPostByRatingEmoji() {
        guard let ratingEmoji = self.selectedFilterRatingEmoji else {return}
        if extraRatingEmojis.contains(ratingEmoji) {
            let filter = Filter.init()
            filter.filterRatingEmoji = ratingEmoji
            Database.filterPostsNew(inputPosts: self.displayedPosts, postFilter: filter) { (filteredPosts) in
                guard let filteredPosts = filteredPosts else {
                    self.displayedPosts = []
                    self.collectionView.reloadData()
                    return
                }
                
                
                var tempPosts: [Post] = filteredPosts
                
                if self.sortListByDate {
                    tempPosts = filteredPosts.sorted { (p1, p2) -> Bool in
                        return p1.listedDate?.compare((p2.listedDate)!) == .orderedDescending
                    }
                } else {
                    tempPosts = filteredPosts.sorted { (p1, p2) -> Bool in
                        return (p1.distance ?? 0) <= (p2.distance ?? 0)
                    }
                }
                self.displayedPosts = tempPosts
                self.collectionView.reloadData()
            }
        }
    }
    
    
    func fetchPostsForList(){
        // Load Lists
        guard let list = self.currentDisplayList else {return}
        
        Database.fetchPostFromList(list: list) { (posts) in
            print("fetchPostsForList | \(posts?.count) Posts | \(list.name) - \(list.id)")
            guard let posts = posts else {
                self.displayedPosts = []
                self.collectionView.reloadData()
                return
            }
            
            var tempPosts: [Post] = []
            if self.sortListByDate {
                tempPosts = posts.sorted { (p1, p2) -> Bool in
                    return p1.listedDate?.compare((p2.listedDate)!) == .orderedDescending
                }
            } else {
                tempPosts = posts.sorted { (p1, p2) -> Bool in
                    return (p1.distance ?? 0) <= (p2.distance ?? 0)
                }
            }
            
            
            self.displayedPosts = tempPosts
            self.collectionView.reloadData()
        }

    }

    func didTapPicture(post: Post) {
        self.delegate?.didTapPicture(post: post)
    }
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        print("   ~ BookmarkListPostView | Displaying \(displayedPosts.count) Lists")
        return displayedPosts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ListPostSummaryGridPhotoCell
        cell.post = self.displayedPosts[indexPath.item]
        cell.delegate = self
        cell.backgroundColor = UIColor.ianWhiteColor()
        cell.showDetails = true
//        cell.layer.borderColor = UIColor.pinterestRedColor().cgColor
//        cell.layer.borderColor = UIColor.pinterestRedColor().withAlphaComponent(0.5).cgColor
        cell.layer.borderColor = UIColor.gray.cgColor
        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 5
        cell.layer.masksToBounds = true
        cell.layer.applySketchShadow()
        cell.showDistance = !sortListByDate
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let post = self.displayedPosts[indexPath.item]
        self.didTapPicture(post: post)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let detailHeight = showDetails ? imageDetailHeight : 0
        return CGSize(width: imageHeight, height: imageHeight + detailHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5
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
