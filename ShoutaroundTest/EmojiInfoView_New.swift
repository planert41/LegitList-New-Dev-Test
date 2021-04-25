//
//  NewUserWelcomeView.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 6/28/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

import DropDown
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage


class EmojiInfoView: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, DiscoverListViewDelegate, UploadEmojiCellDelegate {
    
    
    let headerLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = UIFont(name: "Poppins-Bold", size: 30)
        label.backgroundColor = UIColor.clear
        label.text = "Emojis"
        label.textColor = UIColor.ianLegitColor()
        return label
    }()
    
    let subHeaderLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.backgroundColor = UIColor.clear
        //        label.font = UIFont(name: "Poppins-Regular", size: 26)
        label.font = UIFont(font: .avenirNextDemiBold, size: 22)
        
        label.text = "Emojis are used to visually describe a post or show the most popular food tagged by a user or list. There are 2 types of Emojis:"
        
        
//        You can also see the most popular emoji tagged for users and lists. Just tap them!"
//        label.text = """
//        LegitList uses 2 different emoji types.
//        One to express how you feel.
//        One to describe what it is.
//        """
        label.textColor = UIColor.ianBlackColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    let ratingEmojiLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.backgroundColor = UIColor.clear
        //        label.font = UIFont(name: "Poppins-Regular", size: 26)
        label.font = UIFont(name: "Poppins-Bold", size: 20)
        
        //        label.text = "Recommended by you & your friends anywhere you are"
        label.text = "Rating Emojis"
        
        label.textColor = UIColor.ianBlackColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    let extraRatingButtonLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.backgroundColor = UIColor.clear
        label.font = UIFont(font: .avenirNextBold, size: 20)
        label.text = ""
        label.textColor = UIColor.ianLegitColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
//    let extraRatingButton: UIButton = {
//        let btn = UIButton()
//        //        btn.setImage(#imageLiteral(resourceName: "info.png").withRenderingMode(.alwaysTemplate), for: .normal)
//        btn.tintColor = UIColor.ianLegitColor()
//        btn.titleLabel?.font = UIFont(font: .avenirNextBold, size: 25)
//        btn.titleLabel?.textColor = UIColor.ianLegitColor()
//        btn.titleLabel?.textAlignment = NSTextAlignment.center
//        btn.setTitleColor(UIColor.ianLegitColor(), for: .normal)
//        //        btn.addTarget(self, action: #selector(showExtraRating), for: .touchUpInside)
//        btn.layer.masksToBounds = true
//        btn.layer.borderColor = UIColor.ianLegitColor().cgColor
//        btn.layer.borderWidth = 0
//        btn.backgroundColor = UIColor.white
//        btn.layer.cornerRadius = 3
//        btn.layer.masksToBounds = true
//        btn.tag = 2
//        //        btn.addTarget(self, action: #selector(openInfo(sender:)), for: .touchUpInside)
//
//        return btn
//    }()
    
    let extraRatingButton: PaddedUILabel = {
        let label = PaddedUILabel()
        label.text = "Emojis"
        label.font = UIFont(font: .avenirNextBold, size: 20)
        label.textColor = UIColor.ianLegitColor()
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.white
        label.layer.cornerRadius = 20/2
        label.layer.borderWidth = 0
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.masksToBounds = true
        return label
    }()
    
    
    let ratingEmojiDetail: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.backgroundColor = UIColor.clear
        //        label.font = UIFont(name: "Poppins-Regular", size: 26)
        label.font = UIFont(name: "Poppins-Regular", size: 16)
        
        //        label.text = "Recommended by you & your friends anywhere you are"
        label.text = "Set of 7 emojis used to rate food. Rating Emojis are displayed with a white circle background."
        
        label.textColor = UIColor.ianBlackColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    
    var extraRatingEmojiCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.tag = 9
        cv.layer.borderWidth = 0
        cv.allowsMultipleSelection = false
        cv.backgroundColor = UIColor.lightSelectedColor()
        return cv
    }()
    
    let nonRatingEmojiTitle: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.backgroundColor = UIColor.clear
        //        label.font = UIFont(name: "Poppins-Regular", size: 26)
        label.font = UIFont(name: "Poppins-Bold", size: 20)
        
        //        label.text = "Recommended by you & your friends anywhere you are"
        label.text = "Emoji Tags"
        
        label.textColor = UIColor.ianBlackColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    
    
    let nonRatingEmojiDetail: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.backgroundColor = UIColor.clear
        //        label.font = UIFont(name: "Poppins-Regular", size: 26)
        label.font = UIFont(name: "Poppins-Regular", size: 16)
        
        label.text = "Posts can be tagged with any emoji on your keyboard. Emoji tags are displayed without a background."
        //        label.text = """
        //        Posts can be tagged with any unicode emoji to index by:
        //        /n Food - 🍔 🥗 🍝 🍣 🥙 🌮 🍩 🥐
        //        /n Meal - 🍳 🍱 🍽 ☕️ 🍺 🍮
        //        /n Cuisine - 🇺🇸 🇯🇵 🇲🇽 🇮🇹 🇨🇳
        //        /n Ingredients - 🐮 🐷 🐔 🐟 🦞 🥦 🌶 🧀
        //        /n Diet - ⛪️ 🕍 🕌 ☸️ ❌🍖 ❌🌽 ❌🥜 ❌🥛
        //        """
        
        label.textColor = UIColor.ianBlackColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    let searchEmojiButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "icons8-book-64").withRenderingMode(.alwaysOriginal), for: .normal)
        button.setTitle("Open Emoji Dictionary", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        button.tag = 3
        button.layer.borderColor = UIColor.init(hexColor: "fdcb6e").cgColor
        button.layer.borderWidth = 0
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        button.addTarget(self, action: #selector(openEmojiSearch), for: .touchUpInside)
        return button
    } ()
    
    
    func openEmojiSearch(){
        let emojiSearch = EmojiSearchTableViewController()
        self.navigationController?.pushViewController(emojiSearch, animated: true)
    }
    
    
    let nonRatingEmojiLabel: PaddedUILabel = {
        let label = PaddedUILabel()
        label.text = "Emojis"
        label.font = UIFont(font: .avenirNextBold, size: 20)
        label.textColor = UIColor.white
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.ianLegitColor()
        label.layer.cornerRadius = 20/2
        label.layer.borderWidth = 1
        label.layer.borderColor = UIColor.ianLegitColor().cgColor
        label.layer.masksToBounds = true
        return label
    }()
    
    
    var headerSortSegment = UISegmentedControl()
    var selectedSegment: Int = 0 {
        didSet {
            self.refreshDisplayEmojis()
        }
    }
    var segmentOptions = ["Meals","Food","Cuisine","Ingredient","Diet"]
    var buttonBarPosition: NSLayoutConstraint?
    let buttonBar = UIView()
    
    var nonRatingEmojiCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 5
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
//        layout.estimatedItemSize = CGSize(width: 45, height: 45)
        layout.invalidateLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)

//        let uploadLocationTagList = FilterEmojiLayout()
//        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadLocationTagList)
        cv.tag = 9
        cv.layer.borderWidth = 0
        cv.allowsMultipleSelection = false
        cv.backgroundColor = UIColor.lightSelectedColor()
        return cv
    }()
    
    var displayEmojis: [String] = []
    
    
    func goToList(list: List?, filter: String?) {
        
        guard let list = list else {return}
        let listViewController = ListViewController()
        listViewController.currentDisplayList = list
        listViewController.viewFilter?.filterCaption = filter
        listViewController.refreshPostsForFilter()
        print("DiscoverController | goToList | \(list.name) | \(filter) | \(list.id)")
        self.navigationController?.pushViewController(listViewController, animated: true)
    }
    
    func goToPost(postId: String, ref_listId: String?, ref_userId: String?) {
        
        Database.fetchPostWithPostID(postId: postId) { (post, error) in
            if let error = error {
                print("TabListViewController | goToPost \(error)")
            } else {
                guard let post = post else {
                    self.alert(title: "Sorry", message: "Post Does Not Exist Anymore 😭")
                    if let listId = ref_listId {
                        print("TabListViewController | No More Post. Refreshing List to Update | ",listId)
                        Database.refreshListItems(listId: listId)
                    }
                    return
                }
                let pictureController = SinglePostView()
                pictureController.post = post
                self.navigationController?.pushViewController(pictureController, animated: true)
            }
        }
    }
    
    func displayListFollowingUsers(list: List, following: Bool) {
        print("Display Users| Following: ",list.id)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayUser = true
        postSocialController.displayUserFollowing = false
        postSocialController.inputList = list
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    func showUserLists() {
        //        self.displayPostSocialLists(post: self.post!, following: false)
    }
    
    func displayPostSocialLists(post:Post, following: Bool){
        print("Display Lists| Following: \(following) | Post: \(post.id)")
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayList = true
        postSocialController.displayFollowing = following
        postSocialController.inputPost = post
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    func didTapExtraTag(tagName: String, tagId: String, post: Post) {
        
        // Check to see if its a list, price or something else
        if tagId == "price"{
            // Price Tag Selected
            print("Price Selected")
            // No Display
        }
        else if tagId == "creatorLists"{
            // Additional Tags
            let listController  = ListController()
            listController.displayedPost = post
            listController.displayedListNameDictionary = post.creatorListId
            self.navigationController?.pushViewController(listController, animated: true)
        }
        else if tagId == "userLists"{
            // Additional Tags
            let listController  = ListController()
            listController.displayedPost = post
            listController.displayedListNameDictionary = post.selectedListId
            self.navigationController?.pushViewController(listController, animated: true)
        }
        else {
            // List Tag Selected
            Database.checkUpdateListDetailsWithPost(listName: tagName, listId: tagId, post: post, completion: { (fetchedList) in
                if fetchedList == nil {
                    // List Does not Exist
                    self.alert(title: "List Error", message: "List Does Not Exist Anymore")
                } else {
                    let listViewController = ListViewController()
                    listViewController.currentDisplayList = fetchedList
                    self.navigationController?.pushViewController(listViewController, animated: true)
                }
            })
        }
    }
    
    func refreshAll() {
        print("Refresh All")
        
    }
    
    
    let addListButton: UIButton = {
        let button = UIButton()
        //        button.setTitle("Next", for: .normal)
        button.setTitle("Back", for: .normal)
        
        button.titleLabel?.textColor = UIColor.white
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.ianLegitColor()
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.legitColor().cgColor
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        button.layer.cornerRadius = 10
        button.titleLabel?.textAlignment = NSTextAlignment.center
        
        button.addTarget(self, action: #selector(exitView), for: .touchUpInside)
        return button
    } ()
    
    func exitView(){
        self.dismiss(animated: true, completion: nil)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }

    
    override func viewDidDisappear(_ animated: Bool) {
    }
    
    let displayedListView = DiscoverListView()
    var displayedList: List? = nil {
        didSet {
            guard let displayedList = displayedList else {return}
            
            print("SinglePostView | Loading Displayed List | \(displayedList.name)")
            //            displayedListHeight?.constant = (displayedList == nil) ? 0 : 185
            //            self.displayedListView.isHidden = displayedList == nil
            self.displayedListView.list = displayedList
            self.displayedListView.refUser = CurrentUser.user
            self.displayedListView.showLargeFollowerCount = true
            
            var samplePost = Post.init(user: User.init(uid: "", dictionary: [:]), dictionary: [:])
            var sampleLists: [String:String] = [:]
            sampleLists["A3EFD19E-7C97-4A9B-8A87-AAF64E4D0017"] = "Breakfast/Brunch"
            sampleLists["CDA1B22A-AFD7-4084-BB9F-7FA6091211F3"] = "NOLA"
            sampleLists["63EEC95F-6149-4A30-A038-260D45142922"] = "🍔 Burger Joints"
            samplePost.creatorListId = sampleLists
            self.displayedListView.post = samplePost
            
            
            //            self.setupDisplayedListView()
        }
    }
    
    @objc func handleBackPressNav(){
        //        guard let post = self.selectedPost else {return}
        self.handleBack()
    }
    
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor.backgroundGrayColor()
        self.navigationController?.isNavigationBarHidden = true
        
//        self.view.isUserInteractionEnabled = true
//        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleBackPressNav))
//        swipeLeft.direction = .left
//        self.view.addGestureRecognizer(swipeLeft)
//
//        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleBackPressNav))
//        swipeRight.direction = .right
//        self.view.addGestureRecognizer(swipeRight)
        
        
        self.view.addSubview(addListButton)
        addListButton.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 15, paddingRight: 40, width: 0, height: 40)
        addListButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        addListButton.sizeToFit()
        
        let topGap = UIScreen.main.bounds.height > 750 ? 25 : 25
        let topMargin = UIScreen.main.bounds.height > 750 ? 15 : 15
        let headerFontSize = UIScreen.main.bounds.height > 750 ? 30 : 25
        let detailFontSize = UIScreen.main.bounds.height > 750 ? 16 : 14
        let subHeaderSize = UIScreen.main.bounds.height > 750 ? 18 : 16

        
        self.view.addSubview(headerLabel)
        headerLabel.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        //        hungryLabel.centerXAnchor.constraint(equalTo: self.foodEmojiLabel.centerXAnchor).isActive = true
        //        hungryLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        headerLabel.font = UIFont(name: "Poppins-Bold", size: CGFloat(headerFontSize))
        headerLabel.sizeToFit()
        
        
        self.view.addSubview(subHeaderLabel)
        subHeaderLabel.anchor(top: headerLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        subHeaderLabel.font = UIFont(font: .avenirNextDemiBold, size: CGFloat(subHeaderSize))
        subHeaderLabel.sizeToFit()
        subHeaderLabel.alpha = 1
        
        self.view.addSubview(ratingEmojiLabel)
        ratingEmojiLabel.anchor(top: subHeaderLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: CGFloat(topGap), paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        ratingEmojiLabel.sizeToFit()
        
        
        self.view.addSubview(extraRatingButton)
        extraRatingButton.anchor(top: nil, left: ratingEmojiLabel.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        extraRatingButton.centerYAnchor.constraint(equalTo: ratingEmojiLabel.centerYAnchor).isActive = true
        extraRatingButton.rightAnchor.constraint(lessThanOrEqualTo: view.rightAnchor, constant: 10)
        extraRatingButton.sizeToFit()
//        extraRatingButton.layer.cornerRadius = extraRatingButton.frame.width / 2
        extraRatingButton.layer.masksToBounds = true
        extraRatingButton.isHidden = true
        
//        self.view.addSubview(extraRatingButtonLabel)
//        extraRatingButtonLabel.anchor(top: nil, left: extraRatingButton.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 4, width: 0, height: 0)
//        extraRatingButtonLabel.centerYAnchor.constraint(equalTo: ratingEmojiLabel.centerYAnchor).isActive = true
//        extraRatingButtonLabel.rightAnchor.constraint(lessThanOrEqualTo: view.rightAnchor, constant: 10)
//        extraRatingButtonLabel.backgroundColor = UIColor.yellow
//        extraRatingButtonLabel.sizeToFit()

//
//        self.view.addSubview(extraRatingButtonLabel)
//        extraRatingButtonLabel.anchor(top: nil, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 4, width: 0, height: 0)
//        extraRatingButtonLabel.centerYAnchor.constraint(equalTo: ratingEmojiLabel.centerYAnchor).isActive = true
        
        
        self.view.addSubview(ratingEmojiDetail)
        ratingEmojiDetail.anchor(top: ratingEmojiLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        ratingEmojiDetail.sizeToFit()
        ratingEmojiDetail.font = UIFont(name: "Poppins-Regular", size: CGFloat(detailFontSize))


        self.view.addSubview(extraRatingEmojiCollectionView)
        extraRatingEmojiCollectionView.anchor(top: ratingEmojiDetail.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 15, paddingBottom: 0, paddingRight: 10, width: 350, height: 40)
        extraRatingEmojiCollectionView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        extraRatingEmojiCollectionView.sizeToFit()

        
        self.view.addSubview(nonRatingEmojiTitle)
        nonRatingEmojiTitle.anchor(top: extraRatingEmojiCollectionView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: CGFloat(topGap), paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        nonRatingEmojiTitle.sizeToFit()
        
        self.view.addSubview(nonRatingEmojiLabel)
        nonRatingEmojiLabel.anchor(top: nil, left: nonRatingEmojiTitle.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
//        nonRatingButton.leftAnchor.constraint(lessThanOrEqualTo: nonRatingEmojiLabel.rightAnchor, constant: 10).isActive = true
        nonRatingEmojiLabel.centerYAnchor.constraint(equalTo: nonRatingEmojiTitle.centerYAnchor).isActive = true
        nonRatingEmojiLabel.sizeToFit()
        nonRatingEmojiLabel.isHidden = true
        
        
        self.view.addSubview(nonRatingEmojiDetail)
        nonRatingEmojiDetail.anchor(top: nonRatingEmojiLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        nonRatingEmojiDetail.font = UIFont(name: "Poppins-Regular", size: CGFloat(detailFontSize))

        nonRatingEmojiDetail.sizeToFit()
        
        let segmentView = UIView()
        self.view.addSubview(segmentView)
        segmentView.anchor(top: nonRatingEmojiDetail.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)

        setupSegments()
        self.view.addSubview(headerSortSegment)
        headerSortSegment.anchor(top: segmentView.topAnchor, left: segmentView.leftAnchor, bottom: segmentView.bottomAnchor, right: segmentView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        let segmentWidth = (self.view.frame.width - 30 - 40) / 5
        print("Segment Width \(segmentWidth)")
        self.view.addSubview(buttonBar)
        buttonBar.backgroundColor = UIColor.ianLegitColor()
        buttonBar.anchor(top: nil, left: nil, bottom: segmentView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: segmentWidth, height: 5)


        buttonBar.leftAnchor.constraint(lessThanOrEqualTo: headerSortSegment.leftAnchor).isActive = true
        buttonBar.rightAnchor.constraint(lessThanOrEqualTo: headerSortSegment.rightAnchor).isActive = true
        buttonBarPosition = buttonBar.leftAnchor.constraint(equalTo: headerSortSegment.leftAnchor, constant: 5)
        buttonBarPosition?.isActive = true
        
        
        let emojiContainerHeight: Int = (Int(EmojiSize.width) + 2) * 2 + 10 + 5 + 20
        // Emoji Container View - One Line
        nonRatingEmojiCollectionView.backgroundColor = UIColor.clear
        view.addSubview(nonRatingEmojiCollectionView)
        nonRatingEmojiCollectionView.anchor(top: segmentView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: CGFloat(emojiContainerHeight))
        self.refreshDisplayEmojis()

        setupCollectionView()


    }
    
    let testemojiCellID = "testemojiCellID"
    let emojiCellID = "emojiCellID"
    
    func setupCollectionView(){
        extraRatingEmojiCollectionView.backgroundColor = UIColor.clear
        extraRatingEmojiCollectionView.register(UploadEmojiCell.self, forCellWithReuseIdentifier: testemojiCellID)
        
        extraRatingEmojiCollectionView.delegate = self
        extraRatingEmojiCollectionView.dataSource = self
        extraRatingEmojiCollectionView.allowsMultipleSelection = false
        extraRatingEmojiCollectionView.showsHorizontalScrollIndicator = false
        extraRatingEmojiCollectionView.isPagingEnabled = true
        extraRatingEmojiCollectionView.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
        extraRatingEmojiCollectionView.isScrollEnabled = false
        
        var layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        layout.itemSize = CGSize(width: 40, height: 40)
        layout.minimumInteritemSpacing = 5
        extraRatingEmojiCollectionView.collectionViewLayout = layout
        self.ratingEmojiTag = extraRatingEmojis[0]

        
        nonRatingEmojiCollectionView.backgroundColor = UIColor.clear
        nonRatingEmojiCollectionView.register(UploadEmojiCell.self, forCellWithReuseIdentifier: emojiCellID)
        nonRatingEmojiCollectionView.delegate = self
        nonRatingEmojiCollectionView.dataSource = self
        nonRatingEmojiCollectionView.allowsMultipleSelection = false
        nonRatingEmojiCollectionView.showsHorizontalScrollIndicator = false
        self.nonRatingEmojiTag = mealEmojisSelect[0]
    }
    
    func setupSegments(){
        headerSortSegment = UISegmentedControl(items: segmentOptions)
        headerSortSegment.selectedSegmentIndex = self.selectedSegment
        headerSortSegment.addTarget(self, action: #selector(selectSort), for: .valueChanged)
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        headerSortSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
        headerSortSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)
        headerSortSegment.backgroundColor = .white
        headerSortSegment.tintColor = .white
        headerSortSegment.layer.applySketchShadow()
    }
    
    @objc func selectSort(sender: UISegmentedControl) {
        print("Segment Selected | \(sender.selectedSegmentIndex)")
        self.selectedSegment = sender.selectedSegmentIndex
        self.underlineSegment(segment: sender.selectedSegmentIndex)
    }
    
    func underlineSegment(segment: Int? = 0){
        print("Underline Segment | \(segment)")
        let segmentWidth = (self.view.frame.width - 40) / CGFloat(self.headerSortSegment.numberOfSegments)
        let tempX = self.buttonBar.frame.origin.x
        UIView.animate(withDuration: 0.3) {
            //            self.buttonBarPosition?.isActive = false
            // Origin code lets bar slide
            self.buttonBar.frame.origin.x = segmentWidth * CGFloat(segment ?? 0) + 10 + 10
            self.buttonBarPosition?.constant = segmentWidth * CGFloat(segment ?? 0) + 10 + 10
            self.buttonBarPosition?.isActive = true
        }
    }
    
    func refreshDisplayEmojis() {
        if selectedSegment == 0 {
            // MEALS
            self.displayEmojis = mealEmojisSelect
        }
        else if selectedSegment == 1 {
            // FOOD
            self.displayEmojis = SET_FoodEmojis
        } else if selectedSegment == 2 {
            // Cuisine
            self.displayEmojis = SET_FlagEmojis
        } else if selectedSegment == 3 {
            // RAW
            self.displayEmojis = SET_RawEmojis + SET_VegEmojis
        } else if selectedSegment == 4 {
            // DIET
            self.displayEmojis = dietEmojiSelect
        }
        self.nonRatingEmojiCollectionView.reloadData()
        
    }
    
    let locationCellID = "locationCellID"

    func setupNavigationItems(){
        let customFont = UIFont(name: "Poppins-Bold", size: 18)
        var attributedHeaderTitle = NSMutableAttributedString()
        
        let headerTitle = NSAttributedString(string: "WELCOME", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: customFont])
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        if collectionView == extraRatingEmojiCollectionView {
            return extraRatingEmojis.count
        } else if collectionView == nonRatingEmojiCollectionView {
            return displayEmojis.count
            //            return 0
        } else {
            return 0
        }

    }
    
    var ratingEmojiTag: String = "" {
        didSet {
            if self.ratingEmojiTag == "" {
                self.extraRatingButton.text = ""
                self.extraRatingButton.isHidden = true
            } else {
                self.extraRatingButton.isHidden = false

//                let display = (extraRatingEmojisDic[self.ratingEmojiTag] ?? "").uppercased() + " " + self.ratingEmojiTag
//                self.extraRatingButtonLabel.text = (extraRatingEmojisDic[self.ratingEmojiTag] ?? "").uppercased()
                self.extraRatingButton.text = self.ratingEmojiTag + " " + (extraRatingEmojisDic[self.ratingEmojiTag] ?? "").uppercased()
                self.extraRatingButton.sizeToFit()

                self.extraRatingButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                UIView.animate(withDuration: 1.0,
                               delay: 0,
                               usingSpringWithDamping: 0.2,
                               initialSpringVelocity: 5.0,
                               options: .allowUserInteraction,
                               animations: { [weak self] in
                                self?.extraRatingButton.transform = .identity
                                self?.extraRatingButton.layoutIfNeeded()
                                
                    },
                               completion: nil)
                
            }
        }
    }
    
    var nonRatingEmojiTag: String = "" {
        didSet {
            if self.nonRatingEmojiTag == "" {
                self.nonRatingEmojiLabel.backgroundColor = UIColor.clear
                self.nonRatingEmojiLabel.text = ""
                self.nonRatingEmojiLabel.isHidden = true
            } else {
                var translation = (EmojiDictionary[self.nonRatingEmojiTag] ?? "").uppercased()
                if self.selectedSegment == 0 {
                     translation = (mealEmojiDictionary[self.nonRatingEmojiTag] ?? "").uppercased()
                }
                
                var display = self.nonRatingEmojiTag + " " + translation

                self.nonRatingEmojiLabel.text = display
                self.nonRatingEmojiLabel.sizeToFit()
                self.nonRatingEmojiLabel.isHidden = false
                
                self.nonRatingEmojiLabel.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                UIView.animate(withDuration: 1.0,
                               delay: 0,
                               usingSpringWithDamping: 0.2,
                               initialSpringVelocity: 5.0,
                               options: .allowUserInteraction,
                               animations: { [weak self] in
                                self?.nonRatingEmojiLabel.transform = .identity
                                self?.nonRatingEmojiLabel.layoutIfNeeded()
                                
                    },
                               completion: nil)
                

            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == extraRatingEmojiCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: testemojiCellID, for: indexPath) as! UploadEmojiCell
            cell.uploadEmojis.text = extraRatingEmojis[indexPath.item]
            cell.backgroundColor = UIColor.white
            let isSelected = self.ratingEmojiTag == (cell.uploadEmojis.text!)
            cell.layer.borderColor = isSelected ? UIColor.ianLegitColor().cgColor : UIColor.clear.cgColor
            cell.isRatingEmoji = true
            cell.selectedBackgroundColor = UIColor.white
            cell.selectedBorderColor = UIColor.clear.cgColor
            cell.layer.cornerRadius = cell.frame.width / 2
            cell.isSelected = isSelected
            cell.delegate = self
            cell.sizeToFit()
            
            return cell
        } else if collectionView == nonRatingEmojiCollectionView {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emojiCellID, for: indexPath) as! UploadEmojiCell
            cell.uploadEmojis.text = self.displayEmojis[indexPath.item]
            cell.uploadEmojis.font = cell.uploadEmojis.font.withSize((cell.uploadEmojis.text?.containsOnlyEmoji)! ? EmojiSize.width * 0.8 : 10)
            var containsEmoji = (self.nonRatingEmojiTag.contains(cell.uploadEmojis.text!))
            cell.isRatingEmoji = false
            
            //Highlight only if emoji is tagged, dont care about caption
            cell.backgroundColor = UIColor.white
            cell.layer.borderColor = containsEmoji ? UIColor.ianLegitColor().cgColor : UIColor.rgb(red: 221, green: 221, blue: 221).cgColor
            cell.layer.borderWidth = containsEmoji ? 2 : 1
            cell.delegate = self
            cell.isSelected = self.nonRatingEmojiTag.contains(cell.uploadEmojis.text!)
            cell.sizeToFit()
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: testemojiCellID, for: indexPath) as! UploadEmojiCell
            return cell
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == extraRatingEmojiCollectionView {
            let cell = collectionView.cellForItem(at: indexPath) as! UploadEmojiCell
            let pressedEmoji = cell.uploadEmojis.text!
            cell.isRatingEmoji = true
            
            if pressedEmoji == self.ratingEmojiTag {
                return
            }
            
            
            print("Rating Emoji Cell Selected", pressedEmoji)
            self.didTapRatingEmoji(emoji: pressedEmoji)
            collectionView.reloadData()
        } else if collectionView == nonRatingEmojiCollectionView {
            let cell = collectionView.cellForItem(at: indexPath) as! UploadEmojiCell
            let pressedEmoji = cell.uploadEmojis.text!
            cell.isRatingEmoji = false
            
            if pressedEmoji == self.nonRatingEmojiTag {
                return
            }
            
            print("Non Rating Emoji Cell Selected", pressedEmoji)
            self.didTapNonRatingEmoji(emoji: pressedEmoji)
            collectionView.reloadData()
        }
    }
    
    func didTapNonRatingEmoji(emoji: String) {
        print("Non Rating Emoji Cell Selected", emoji)
        let prevEmoji = self.nonRatingEmojiTag
        self.nonRatingEmojiTag = emoji
        // DESELECT CURRENT TAG
        if let index = displayEmojis.firstIndex(of: prevEmoji) {
            if prevEmoji == self.nonRatingEmojiTag {
                return
            }
            let indexpath = IndexPath(item: index, section: 0)
            self.nonRatingEmojiCollectionView.reloadItems(at: [indexpath])
        }
    }
    
    func didTapRatingEmoji(emoji:String){
        print("Rating Emoji Cell Selected", emoji)
        let prevEmoji = self.ratingEmojiTag
        if prevEmoji == emoji {
            return
        }
        self.ratingEmojiTag = emoji
        
        // DESELECT CURRENT TAG
        if let index = extraRatingEmojis.firstIndex(of: prevEmoji) {
            if prevEmoji == self.ratingEmojiTag {
                return
            }
            let indexpath = IndexPath(item: index, section: 0)
            self.extraRatingEmojiCollectionView.reloadItems(at: [indexpath])
        }
    }
    
}
