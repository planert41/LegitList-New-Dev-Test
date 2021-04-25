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


class EmojiInfoView_OLD: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, BounceSelectCellDelegate, DiscoverListViewDelegate, UploadEmojiCellDelegate {
    

    func didSelect(tag: Int?) {
        
    }
    
    
    

    
    @objc func hideLabels(){
        //        self.hungryLabel.alpha = 0
        //        self.howDoIFindLabel.alpha = 0
        //        self.friendsLabel.alpha = 0
        //        self.whatIfLabel.alpha = 0
        self.whatIfAnswerLabel1.alpha = 0
        self.whatIfAnswerLabel2.alpha = 0
        self.whatIfAnswerLabel3.alpha = 0
        self.whatIfAnswerLabel4.alpha = 0
        
    }
    
    @objc func animateLabels(){
        
        let durationOfAnimationInSecond = 2.0
        
        UIView.transition(with: self.whatIfAnswerLabel1, duration: durationOfAnimationInSecond, options: .transitionCurlUp, animations: {
            self.whatIfAnswerLabel1.alpha = 1
        }, completion: { (finished: Bool) -> () in
            UIView.transition(with: self.whatIfAnswerLabel2, duration: durationOfAnimationInSecond, options: .transitionCurlUp, animations: {
                self.whatIfAnswerLabel2.alpha = 1
            }, completion: { (finished: Bool) -> () in
                UIView.transition(with: self.whatIfAnswerLabel3, duration: durationOfAnimationInSecond, options: .transitionCurlUp, animations: {
                    self.whatIfAnswerLabel3.alpha = 1
                }, completion: { (finished: Bool) -> () in
                    UIView.transition(with: self.whatIfAnswerLabel4, duration: durationOfAnimationInSecond, options: .transitionCurlUp, animations: {
                        self.whatIfAnswerLabel4.alpha = 1
                    }, completion: { (finished: Bool) -> () in
                    })
                })
            })
        })
        
        
    }
    
    
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
    
    
    
    let weAskedLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.layer.masksToBounds = true
        //        label.font = UIFont(name: "Poppins-Regular", size: 18)
        //        label.textColor = UIColor.ianLegitColor()
        label.backgroundColor = UIColor.clear
        
        label.font = UIFont(font: .avenirBlack, size: 28)
        label.text = "How can I find the BEST"
        label.textColor = UIColor.ianBlueColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    
    
    /*
     I'm Hungy
     
     How can I find a legit food?
     
     What if you could see
     
     all the food your friends have tried around you
     
     or a shared feed of everyone's favourite places
     
     What if my food pictures are actually legit verified food recommendations?
     
     */
    
    
    let hungryLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.backgroundColor = UIColor.clear
        //        label.font = UIFont(font: .avenirBlack, size: 30)
        label.font = UIFont(name: "Poppins-Bold", size: 30)
        
        label.text = "EMOJIS"
        label.textColor = UIColor.ianLegitColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    let friendsLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.backgroundColor = UIColor.clear
        //        label.font = UIFont(name: "Poppins-Regular", size: 26)
        label.font = UIFont(font: .avenirNextDemiBold, size: 22)
        
        //        label.text = "Recommended by you & your friends anywhere you are"
        label.text = "2 emoji types are used to describe how you feel and what the post contains"
        
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
    
    let extraRatingButton: UIButton = {
        let btn = UIButton()
//        btn.setImage(#imageLiteral(resourceName: "info.png").withRenderingMode(.alwaysTemplate), for: .normal)
        btn.tintColor = UIColor.ianLegitColor()
        btn.titleLabel?.font = UIFont(font: .avenirNextBold, size: 20)
        btn.titleLabel?.textColor = UIColor.ianLegitColor()
        btn.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        //        btn.addTarget(self, action: #selector(showExtraRating), for: .touchUpInside)
        btn.layer.masksToBounds = true
        btn.layer.borderColor = UIColor.ianLegitColor().cgColor
        btn.layer.borderWidth = 0
        btn.backgroundColor = UIColor.white
        btn.layer.cornerRadius = 3
        btn.layer.masksToBounds = true
        btn.tag = 2
//        btn.addTarget(self, action: #selector(openInfo(sender:)), for: .touchUpInside)
        
        return btn
    }()
    
    let ratingEmojiDetail: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.backgroundColor = UIColor.clear
        //        label.font = UIFont(name: "Poppins-Regular", size: 26)
        label.font = UIFont(name: "Poppins-Regular", size: 16)
        
        //        label.text = "Recommended by you & your friends anywhere you are"
        label.text = "Pre-selected set of emojis used to rate food beyond 5 stars"
        
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
    
    
    let nonRatingEmojiLabel: UILabel = {
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
        
        label.text = "Any unicode emoji from your keyboard can be used to tag your post"
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
    
    let nonRatingButton: UIButton = {
        let btn = UIButton()
        //        btn.setImage(#imageLiteral(resourceName: "info.png").withRenderingMode(.alwaysTemplate), for: .normal)
        btn.tintColor = UIColor.ianLegitColor()
        btn.titleLabel?.font = UIFont(font: .avenirNextBold, size: 20)
        btn.titleLabel?.textColor = UIColor.ianLegitColor()
        btn.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        //        btn.addTarget(self, action: #selector(showExtraRating), for: .touchUpInside)
        btn.layer.masksToBounds = true
        btn.layer.borderColor = UIColor.ianLegitColor().cgColor
        btn.layer.borderWidth = 0
        btn.backgroundColor = UIColor.white
        btn.layer.cornerRadius = 3
        btn.layer.masksToBounds = true
        btn.tag = 2
        //        btn.addTarget(self, action: #selector(openInfo(sender:)), for: .touchUpInside)
        return btn
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
    
    let missionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = UIFont(name: "Poppins-Bold", size: 18)
        //        label.textColor = UIColor.ianOrangeColor()
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.text = """
        🍔 Food - We focus on the food 🍕🌮🍜, not the restaurant
        /n 👌 Curation - Create a communal food 🧠 by following people you trust
        /n 📌 Geo-Lists - We organize your photos into geo-tagged lists that are mappable 🗺, searchable 🔍, and easy to share with friends 🙋‍♂️🙋‍♀️
        /n 📍 Location - Sort your feed by nearest distance to find the closest legit 👌 thing to eat
        /n 😍 Emojis - Tag your posts with Emojis, so that they are searchable by food 🌯, cuisine 🇲🇾, taste 🌶 or even diets 🕍. Express how 🔥 the food is beyond just 5 stars
        """
        label.textColor = UIColor.ianBlueColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    
    let friendsLabel2: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.backgroundColor = UIColor.clear
        label.font = UIFont(font: .avenirNextDemiBold, size: 22)
        //        label.text = "Recommended by you & your friends anywhere you are"
        label.text = "Create and curate lists of your favorite experiences to share with friends and family"
        label.textColor = UIColor.ianBlackColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    let friendsLabel3: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.backgroundColor = UIColor.clear
        label.font = UIFont(font: .avenirNextDemiBold, size: 22)
        //        label.text = "Recommended by you & your friends anywhere you are"
        label.text = "Express yourself with emojis! Tag and search your posts by food 🍔, cuisine 🇺🇸, taste 🌶 or diet ❌🍖"
        label.textColor = UIColor.ianBlackColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    let foodEmojiLabel: LightPaddedUILabel = {
        let label = LightPaddedUILabel()
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = UIFont(name: "Poppins-Bold", size: 35)
        //        label.textColor = UIColor.ianLegitColor()
        label.backgroundColor = UIColor.clear
        
        //        label.font = UIFont(font: .avenirBlack, size: 35)
        label.text = "🥞 Pancake"
        label.textColor = UIColor.ianLegitColor()
        //        label.backgroundColor = UIColor.ianLegitColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        //        label.layer.cornerRadius = 3
        //        label.layer.masksToBounds = true
        return label
    }()
    
    
    
    
    let tasteLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.backgroundColor = UIColor.clear
        label.font = UIFont(font: .avenirBlack, size: 28)
        label.text = "Personalized to fit your unique personal taste"
        label.textColor = UIColor.ianBlackColor()
        return label
    }()
    
    let howDoIFindLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.backgroundColor = UIColor.clear
        label.font = UIFont(font: .avenirBlack, size: 28)
        label.text = "How do I find the best ones nearby?"
        label.textColor = UIColor.ianBlueColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    
    
    
    let whatIfLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.backgroundColor = UIColor.clear
        label.font = UIFont(font: .avenirBlack, size: 28)
        label.text = "What if you could"
        label.textColor = UIColor.ianBlackColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    let whatIfAnswerLabel1: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.backgroundColor = UIColor.clear
        label.font = UIFont(name: "Poppins-Regular", size: 23)
        //        label.text = "Journal your foodie adventure with your food photos"
        //        label.text = "Use your food photos to journal your adventure"
        //        label.text = "Friend-source food that fit your unique taste"
        label.text = "Journal your foodie and travel adventures with photos"
        
        //        label.text = "Share a curated feed & social food diary with friends and family 🙋‍♂️🙋‍♀️"
        label.textColor = UIColor.ianLegitColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    let whatIfAnswerLabel2: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.backgroundColor = UIColor.clear
        label.font = UIFont(name: "Poppins-Regular", size: 23)
        //        label.text = "Create a social food diary with your own food photos"
        //        label.text = "Share your best experiences with your friends and family"
        //        label.text = "Share a c best experiences with your friends and family"
        //        label.text = "Journal your foodie and travel adventures with your photos"
        label.text = "Curate your best experiences with lists and share them with friends and family"
        
        //        label.text = "Friend-source food that fit your unique personal taste"
        label.textColor = UIColor.ianLegitColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    let whatIfAnswerLabel3: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.backgroundColor = UIColor.clear
        label.font = UIFont(name: "Poppins-Regular", size: 23)
        //        label.text = "Create a social food diary and share it"
        //        label.text = "Curate lists of your best experiences and share them with friends and family"
        //        label.text = "Friend-source food that fit your unique taste"
        label.text = "Always find the best recommendations near you from people you trust"
        
        //        label.text = "Friend-source food that fit your unique taste"
        //        label.text = "See all the food photos your friends have taken nearby on a map"
        label.textColor = UIColor.ianLegitColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    let whatIfAnswerLabel4: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.backgroundColor = UIColor.clear
        label.font = UIFont(name: "Poppins-Regular", size: 23)
        //        label.text = "Create a social food diary and share it"
        label.text = "Friend-source food that fit your unique taste"
        
        //        label.text = "See all the food photos your friends have taken nearby on a map"
        label.textColor = UIColor.ianLegitColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    let weAskedLabel2: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.layer.masksToBounds = true
        //        label.font = UIFont(name: "Poppins-Regular", size: 18)
        //        label.textColor = UIColor.ianLegitColor()
        label.backgroundColor = UIColor.clear
        
        label.font = UIFont(font: .avenirBlack, size: 28)
        label.text = "my friends recommend near me?"
        label.textColor = UIColor.ianBlueColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    var timer = Timer()
    
    let answerLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.layer.masksToBounds = true
        //        label.font = UIFont(name: "Poppins-Regular", size: 18)
        //        label.textColor = UIColor.ianLegitColor()
        label.backgroundColor = UIColor.clear
        
        label.font = UIFont(font: .avenirBlack, size: 28)
        label.text = "How do I remember all the restaurants I tried on my last ✈️ trip?"
        label.textColor = UIColor.ianBlueColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    let answerLabel3: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.layer.masksToBounds = true
        //        label.font = UIFont(name: "Poppins-Regular", size: 18)
        //        label.textColor = UIColor.ianLegitColor()
        label.backgroundColor = UIColor.clear
        
        label.font = UIFont(font: .avenirBlack, size: 28)
        label.text = "What if I had a curated list of my top restaurants? And share them with friends?"
        label.textColor = UIColor.ianBlueColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    let legitLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.layer.masksToBounds = true
        //        label.font = UIFont(name: "Poppins-Regular", size: 18)
        //        label.textColor = UIColor.ianLegitColor()
        label.backgroundColor = UIColor.clear
        label.font = UIFont(name: "Poppins-Bold", size: 30)
        label.text = "Welcome To LegitList 🥳 "
        label.textColor = UIColor.ianLegitColor()
        label.numberOfLines = 1
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    
    let methodDisplay: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.layer.masksToBounds = true
        //        label.font = UIFont(name: "Poppins-Regular", size: 18)
        label.textColor = UIColor.ianLegitColor()
        label.backgroundColor = UIColor.clear
        label.font = UIFont(name: "Poppins-Bold", size: 28)
        label.text = "LegitList Was Our Answer"
        label.textColor = UIColor.ianBlueColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    
    let believeHeader2: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.layer.masksToBounds = true
        //        label.font = UIFont(name: "Poppins-Regular", size: 18)
        label.textColor = UIColor.ianLegitColor()
        label.backgroundColor = UIColor.clear
        label.font = UIFont(font: .avenirNextBold, size: 18)
        label.text = "Here's what we do a little differently:"
        label.textColor = UIColor.ianLegitColor()
        return label
    }()
    
    
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
        
        button.addTarget(self, action: #selector(addList), for: .touchUpInside)
        return button
    } ()
    
    
    func addList(){
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
//        animateLabels()
    }

    
    override func viewDidDisappear(_ animated: Bool) {
//        self.hideLabels()
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
    
    
    
    
    var headerSortSegment = UISegmentedControl()
    var selectedSegment: Int = 0 {
        didSet {
            self.refreshDisplayEmojis()
        }
    }
    var segmentOptions = ["Food","Cuisine","Ingredient","Diet"]
    var buttonBarPosition: NSLayoutConstraint?
    let buttonBar = UIView()
    
    var nonRatingEmojiCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.tag = 9
        cv.layer.borderWidth = 0
        cv.allowsMultipleSelection = false
        cv.backgroundColor = UIColor.lightSelectedColor()
        return cv
    }()
    
    var displayEmojis: [String] = []
    
    override func viewDidLoad() {
        
//        let commentStackView = UIStackView(arrangedSubviews: [commentLabel1, commentLabel2, commentLabel3])
//        commentStackView.distribution = .equalSpacing
//        commentStackView.axis = .vertical
        
        self.view.backgroundColor = UIColor.backgroundGrayColor()
        self.navigationController?.isNavigationBarHidden = true
        
        self.view.isUserInteractionEnabled = true
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(addList))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        self.view.addSubview(addListButton)
        addListButton.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 30, paddingRight: 40, width: 0, height: 30)
        addListButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        addListButton.sizeToFit()
        
        let topMargin = UIScreen.main.bounds.height > 750 ? 25 : 15
        let topGap = UIScreen.main.bounds.height > 750 ? 30 : 25
        let headerFontSize = UIScreen.main.bounds.height > 750 ? 30 : 25
        let detailFontSize = UIScreen.main.bounds.height > 750 ? 22 : 20
        
        
        self.view.addSubview(hungryLabel)
        hungryLabel.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        //        hungryLabel.centerXAnchor.constraint(equalTo: self.foodEmojiLabel.centerXAnchor).isActive = true
        //        hungryLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        hungryLabel.alpha = 1
        hungryLabel.font = UIFont(name: "Poppins-Bold", size: CGFloat(headerFontSize))
        hungryLabel.sizeToFit()
        
        
        self.view.addSubview(friendsLabel)
        friendsLabel.anchor(top: hungryLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 15, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        friendsLabel.font = UIFont(font: .avenirNextDemiBold, size: CGFloat(detailFontSize))
        friendsLabel.sizeToFit()
        friendsLabel.alpha = 1
        
        self.view.addSubview(ratingEmojiLabel)
        ratingEmojiLabel.anchor(top: friendsLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: CGFloat(topMargin), paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        ratingEmojiLabel.sizeToFit()

        self.view.addSubview(extraRatingButton)
        extraRatingButton.anchor(top: nil, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: CGFloat(topMargin), paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        extraRatingButton.leftAnchor.constraint(lessThanOrEqualTo: ratingEmojiLabel.rightAnchor, constant: 10).isActive = true
        extraRatingButton.centerYAnchor.constraint(equalTo: ratingEmojiLabel.centerYAnchor).isActive = true
        extraRatingButton.sizeToFit()
        
        self.view.addSubview(ratingEmojiDetail)
        ratingEmojiDetail.anchor(top: ratingEmojiLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: CGFloat(topMargin), paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        ratingEmojiDetail.sizeToFit()
        
        self.view.addSubview(extraRatingEmojiCollectionView)
        extraRatingEmojiCollectionView.anchor(top: ratingEmojiDetail.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 15, paddingBottom: 0, paddingRight: 10, width: 350, height: 40)
        extraRatingEmojiCollectionView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        extraRatingEmojiCollectionView.sizeToFit()
        setupCollectionView()
        
        self.view.addSubview(nonRatingEmojiLabel)
        nonRatingEmojiLabel.anchor(top: extraRatingEmojiCollectionView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: CGFloat(topMargin), paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        nonRatingEmojiLabel.sizeToFit()
        
        self.view.addSubview(nonRatingButton)
        nonRatingButton.anchor(top: nil, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: CGFloat(topMargin), paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        nonRatingButton.leftAnchor.constraint(lessThanOrEqualTo: nonRatingEmojiLabel.rightAnchor, constant: 10).isActive = true
        nonRatingButton.centerYAnchor.constraint(equalTo: nonRatingEmojiLabel.centerYAnchor).isActive = true
        nonRatingButton.sizeToFit()
        
        
        self.view.addSubview(nonRatingEmojiDetail)
        nonRatingEmojiDetail.anchor(top: nonRatingEmojiLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: CGFloat(topMargin), paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        nonRatingEmojiDetail.sizeToFit()
        
        self.view.addSubview(headerSortSegment)
        headerSortSegment.anchor(top: nonRatingEmojiDetail.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 40)
        setupSegments()

        buttonBar.backgroundColor = UIColor.ianLegitColor()
        self.view.addSubview(buttonBar)
        let segmentWidth = (self.view.frame.width - 30 - 40) / 4
        buttonBar.anchor(top: headerSortSegment.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: segmentWidth, height: 5)
        buttonBar.leftAnchor.constraint(lessThanOrEqualTo: headerSortSegment.leftAnchor).isActive = true
        buttonBar.rightAnchor.constraint(lessThanOrEqualTo: headerSortSegment.rightAnchor).isActive = true
        buttonBarPosition = buttonBar.leftAnchor.constraint(equalTo: headerSortSegment.leftAnchor, constant: 5)
        buttonBarPosition?.isActive = true
        
        
        let emojiContainerHeight: Int = (Int(EmojiSize.width) + 2) * 2 + 10 + 5
        // Emoji Container View - One Line
        nonRatingEmojiCollectionView.backgroundColor = UIColor.clear
        view.addSubview(nonRatingEmojiCollectionView)
        nonRatingEmojiCollectionView.anchor(top: headerSortSegment.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: CGFloat(emojiContainerHeight))
        self.setupEmojiCollectionView()
        self.refreshDisplayEmojis()
        
        
        self.view.addSubview(searchEmojiButton)
        searchEmojiButton.anchor(top: nonRatingEmojiCollectionView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: CGFloat(topMargin), paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        searchEmojiButton.sizeToFit()

        
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
        self.selectedSegment = sender.selectedSegmentIndex
        self.underlineSegment(segment: sender.selectedSegmentIndex)
    }
    
    func underlineSegment(segment: Int? = 0){
        
        let segmentWidth = (self.view.frame.width - 40) / CGFloat(self.headerSortSegment.numberOfSegments)
        let tempX = self.buttonBar.frame.origin.x
        UIView.animate(withDuration: 0.3) {
            //            self.buttonBarPosition?.isActive = false
            // Origin code lets bar slide
            self.buttonBar.frame.origin.x = segmentWidth * CGFloat(segment ?? 0) + 10
            self.buttonBarPosition?.constant = segmentWidth * CGFloat(segment ?? 0) + 10
            self.buttonBarPosition?.isActive = true
        }
    }
    
    func refreshDisplayEmojis() {
        if selectedSegment == 0 {
            // FOOD
            self.displayEmojis = SET_FoodEmojis
        } else if selectedSegment == 1 {
            // Cuisine
            self.displayEmojis = SET_FlagEmojis
        } else if selectedSegment == 2 {
            // RAW
            self.displayEmojis = SET_RawEmojis + SET_VegEmojis
        } else if selectedSegment == 3 {
            // DIET
            self.displayEmojis = dietEmojiSelect
        }
        self.nonRatingEmojiCollectionView.reloadData()
        
    }
    
    let emojiCellID = "emojiCellID"
    
    func setupEmojiCollectionView(){
        nonRatingEmojiCollectionView.backgroundColor = UIColor.clear
        nonRatingEmojiCollectionView.register(UploadEmojiCell.self, forCellWithReuseIdentifier: emojiCellID)
        nonRatingEmojiCollectionView.delegate = self
        nonRatingEmojiCollectionView.dataSource = self
        nonRatingEmojiCollectionView.allowsMultipleSelection = false
        nonRatingEmojiCollectionView.showsHorizontalScrollIndicator = false
    }
    
    
    
    func setupSampleList() {
        
        let sampleListId = "CBD367A0-4B4B-480F-BEDE-3A85476ECCC1" // MaynEats
        
        
        /*
         
         Optional("Breakfast/Brunch") - Optional("A3EFD19E-7C97-4A9B-8A87-AAF64E4D0017")
         Optional("NOLA") - Optional("CDA1B22A-AFD7-4084-BB9F-7FA6091211F3")
         Optional("🍔 Burger Joints") - Optional("63EEC95F-6149-4A30-A038-260D45142922")
         */
        
        Database.fetchListforSingleListId(listId: sampleListId) { (list) in
            self.displayedList = list
            print("NewUserOnboarding | Loaded \(list?.name) | \(list?.id)")
        }
        
    }
    
    let testemojiCellID = "locationCellID"
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
        //        layout.offse
        extraRatingEmojiCollectionView.collectionViewLayout = layout
        
    }
    
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
                self.extraRatingButton.backgroundColor = UIColor.clear
                self.extraRatingButton.setTitle(nil, for: .normal)
                self.extraRatingButton.setImage(UIImage(), for: .normal)
                self.extraRatingButton.tintColor = UIColor.ianLegitColor()
                
            } else {
                
                let display = (extraRatingEmojisDic[self.ratingEmojiTag] ?? "").uppercased() + " " + self.ratingEmojiTag
                self.extraRatingButton.setTitle(display, for: .normal)
                self.extraRatingButton.setImage(UIImage(), for: .normal)
                self.extraRatingButton.setTitleColor(UIColor.ianLegitColor(), for: .normal)
                self.extraRatingButton.titleLabel?.font = UIFont(font: .avenirNextBold, size: 25)
                self.extraRatingButton.sizeToFit()
            }
        }
    }
    
    var nonRatingEmojiTag: String = "" {
        didSet {
            if self.ratingEmojiTag == "" {
                self.nonRatingButton.backgroundColor = UIColor.clear
                self.nonRatingButton.setTitle(nil, for: .normal)
                self.nonRatingButton.setImage(UIImage(), for: .normal)
                self.nonRatingButton.tintColor = UIColor.ianLegitColor()
                
            } else {
                
                let display = (extraRatingEmojisDic[self.nonRatingEmojiTag] ?? "").uppercased() + " " + self.nonRatingEmojiTag
                self.nonRatingButton.setTitle(display, for: .normal)
                self.nonRatingButton.setImage(UIImage(), for: .normal)
                self.nonRatingButton.setTitleColor(UIColor.ianLegitColor(), for: .normal)
                self.nonRatingButton.titleLabel?.font = UIFont(font: .avenirNextBold, size: 25)
                self.nonRatingButton.sizeToFit()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == extraRatingEmojiCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: testemojiCellID, for: indexPath) as! UploadEmojiCell
            cell.uploadEmojis.text = extraRatingEmojis[indexPath.item]
            cell.backgroundColor = UIColor.white
            let isSelected = self.ratingEmojiTag == (cell.uploadEmojis.text!)
            cell.isSelected = isSelected
            cell.layer.borderColor = isSelected ? UIColor.ianLegitColor().cgColor : UIColor.clear.cgColor
            cell.isRatingEmoji = true
            cell.selectedBackgroundColor = UIColor.white
            cell.selectedBorderColor = UIColor.clear.cgColor
            cell.delegate = self
            cell.layer.cornerRadius = cell.frame.width / 2
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
            
            print("Rating Emoji Cell Selected", pressedEmoji)
            self.didTapRatingEmoji(emoji: pressedEmoji)
            collectionView.reloadData()
        } else if collectionView == nonRatingEmojiCollectionView {
            let cell = collectionView.cellForItem(at: indexPath) as! UploadEmojiCell
            let pressedEmoji = cell.uploadEmojis.text!
            cell.isRatingEmoji = false
            
            print("Rating Emoji Cell Selected", pressedEmoji)
            self.didTapRatingEmoji(emoji: pressedEmoji)
            collectionView.reloadData()
            
            
        }
    }
    
    func didTapNonRatingEmoji(emoji: String) {
        print("Non Rating Emoji Cell Selected", emoji)
        self.nonRatingEmojiTag = emoji
    }
    
    func didTapRatingEmoji(emoji:String){
        print("Rating Emoji Cell Selected", emoji)
        self.ratingEmojiTag = emoji
    }
    
    
}
