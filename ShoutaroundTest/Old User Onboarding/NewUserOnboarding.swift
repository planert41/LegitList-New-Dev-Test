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


class NewUserOnboardingView: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, BounceSelectCellDelegate, DiscoverListViewDelegate {

    
    
    let welcomeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = UIFont(name: "Poppins-Bold", size: 30)
        label.backgroundColor = UIColor.clear
        label.text = "Welcome To LegitList"
        label.textColor = UIColor.ianLegitColor()
        return label
    }()
    
    let missionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = UIFont(name: "Poppins-Bold", size: 18)
        //        label.textColor = UIColor.ianOrangeColor()
        label.backgroundColor = UIColor.clear
        label.text = "Our Mission Is To Help You Find Legit Food Wherever You Are. Verified By You And The People You Trust"
        label.textColor = UIColor.ianBlueColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    let believeHeader1: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.layer.masksToBounds = true
        //        label.font = UIFont(name: "Poppins-Regular", size: 18)
        label.textColor = UIColor.ianLegitColor()
        label.backgroundColor = UIColor.clear
        label.font = UIFont(font: .avenirNextBold, size: 19)
        label.text = "We believe that"
        label.textColor = UIColor.ianLegitColor()
        return label
    }()
    
    let believeTextView: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.layer.masksToBounds = true
        //        label.font = UIFont(name: "Poppins-Regular", size: 18)
        label.textColor = UIColor.ianLegitColor()
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = UIFont(font: .avenirNextMedium, size: 17)
        label.text = """
        \n● A food picture is worth a thousand reviews
        \n● Everyone has a unique taste for food. The food pictures they take reflect that unique taste
        \n● The food photos on your phone are a secret treasure trove of legit food recommendations verified by you
        \n● Your friends know your taste better than any elite reviewer
        \n● Food pictures you can see but can never eat are pointless
        """
        label.textColor = UIColor.ianBlackColor()
        return label
    }()
    
    let methodCollectionView: UICollectionView = {
        let uploadLocationTagList = UploadLocationTagList()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadLocationTagList)
        //        cv.layer.borderWidth = 1
        //        cv.layer.borderColor = UIColor.legitColor().cgColor
        return cv
    }()
    
    let methodOptions: [String] = ["🍔 Food", "👌 Curation", "📌 Geo-Lists", "📍 Location", "😘 Emojis"]
    let methodDetails: [String] = [
        "🍔 Food - We focus on the food 🍕🌮🍜, not the restaurant",
        "👌 Curation - Create a communal food 🧠 by following people you trust",
        "📌 Geo-Lists - We organize your photos into geo-tagged lists that are mappable 🗺, searchable 🔍, and easy to share with friends 🙋‍♂️🙋‍♀️",
        "📍 Location - Sort your feed by nearest distance to find the closest legit 👌 thing to eat",
        "😘 Emojis - Tag your posts with Emojis, so that they are searchable by food 🌯 cuisine 🇲🇾 taste 🌶 or even diets 🕍. Express how 🔥 the food is beyond just 5 stars"
        
        
    ]
    var selectedMethod = 0 {
        didSet{
            displayMethod()
        }
    }
    
    let foodList = ["🥞", "🍔", "🍣", "🍕", "🍝", "🍜"]

    @objc func updateCounting(){
        foodTagInt += 1
        if foodTagInt == foodList.count {
            foodTagInt = 0
        }
        
//        let animationDuration = 2
//        let animationDelay = 2
        let durationOfAnimationInSecond = 1.0
        
        UIView.transition(with: self.foodEmojiLabel, duration: durationOfAnimationInSecond, options: .transitionFlipFromBottom, animations: {
            let emoji = self.foodList[self.foodTagInt]
            guard let emojiText = EmojiDictionary[emoji]?.capitalizingFirstLetter() else {
                self.foodEmojiLabel.text = emoji
                return
            }
            self.foodEmojiLabel.text = emoji + " \(emojiText)"
//            self.foodEmojiLabel.sizeToFit()
        }, completion: nil)
        
        
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
    
    
    var foodTagInt = 0
    
    func fadeViewInThenOut(view : UIView, delay: TimeInterval) {
        
        let animationDuration = 0.25
        
        // Fade in the view
        UIView.animate(withDuration: animationDuration, animations: { () -> Void in
            view.alpha = 1
        }) { (Bool) -> Void in
            
            // After the animation completes, fade out the view after a delay
            
            UIView.animate(withDuration: animationDuration, delay: delay, options: .transitionCurlUp, animations: { () -> Void in
                view.alpha = 0
            },
                                       completion: nil)
     
        }
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

        label.text = "Journal your adventures!"
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
        label.text = "You have a gold mine of legit restaurant recommendations in your food photos"
        
        label.textColor = UIColor.ianBlackColor()
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
//        label.text = "Collect and curate lists of your favorite experiences to share with friends and family"
        label.text = "Use emojis to tag and search posts by food 🍔 cuisine 🇺🇸 taste 🌶 or diet ❌🍖 Express yourself! 😍"

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
        label.text = "Collect and curate lists of your favorite places. Share your lists with friends and family"
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
        button.setTitle("Welcome To LegitList", for: .normal)

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
    
    
    @objc func addList(){
//        let listView = UserWelcome2View()
        let listView = NewUserOnboardingView2()
        self.navigationController?.pushViewController(listView, animated: true)
        //        self.navigationController?.present(listView, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        animateLabels()
    }
    func scheduledTimerWithTimeInterval(){
        // Scheduling timer to Call the function "updateCounting" with the interval of 1 seconds
        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.updateCounting), userInfo: nil, repeats: true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        self.hideLabels()
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
    
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor.backgroundGrayColor()
        self.navigationController?.isNavigationBarHidden = true
        
        self.view.isUserInteractionEnabled = true
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(addList))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        setupCollectionView()
        
        self.view.addSubview(addListButton)
        addListButton.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 30, paddingRight: 40, width: 0, height: 50)
        addListButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        addListButton.sizeToFit()
        
        let topMargin = UIScreen.main.bounds.height > 750 ? 25 : 18
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
        friendsLabel.anchor(top: hungryLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: CGFloat(topGap), paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        friendsLabel.font = UIFont(font: .avenirNextDemiBold, size: CGFloat(detailFontSize))
        friendsLabel.sizeToFit()
        friendsLabel.alpha = 1
        
        
        
        
        self.view.addSubview(friendsLabel2)
        friendsLabel2.anchor(top: friendsLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: CGFloat(topMargin), paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        friendsLabel2.font = UIFont(font: .avenirNextDemiBold, size: CGFloat(detailFontSize))
        friendsLabel2.sizeToFit()
        friendsLabel2.alpha = 1
        
        self.view.addSubview(friendsLabel3)
        friendsLabel3.anchor(top: friendsLabel2.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: CGFloat(topMargin), paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        friendsLabel3.font = UIFont(font: .avenirNextDemiBold, size: CGFloat(detailFontSize))
        friendsLabel3.sizeToFit()
        friendsLabel3.alpha = 1
        
        self.view.addSubview(displayedListView)
        displayedListView.anchor(top: friendsLabel3.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 15, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 185)
        displayedListView.delegate = self
        displayedListView.backgroundColor = UIColor.white
        
        setupSampleList()
        
        
//        self.view.addSubview(foodEmojiLabel)
//        foodEmojiLabel.anchor(top: hungryLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 35)
//        foodEmojiLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
////        foodEmojiLabel.centerYAnchor.constraint(equalTo: hungryLabel.centerYAnchor).isActive = true
//        foodEmojiLabel.sizeToFit()
        
//        self.view.addSubview(hungryLabel)
//        hungryLabel.anchor(top: topLayoutGuide.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 30, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        hungryLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        hungryLabel.alpha = 0
//        
//        //        setupNavigationItems()
//        self.view.addSubview(foodEmojiLabel)
//        foodEmojiLabel.anchor(top: hungryLabel.bottomAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 30, paddingLeft: 20, paddingBottom: 0, paddingRight: 30, width: 40, height: 40)
//


        
//        self.view.addSubview(tasteLabel)
//        tasteLabel.anchor(top: friendsLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
//        tasteLabel.sizeToFit()
//        tasteLabel.alpha = 0

//        self.view.addSubview(whatIfAnswerLabel1)
//        whatIfAnswerLabel1.anchor(top: friendsLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 40, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
//        whatIfAnswerLabel1.sizeToFit()
//        whatIfAnswerLabel1.alpha = 0
//
//        self.view.addSubview(whatIfAnswerLabel2)
//        whatIfAnswerLabel2.anchor(top: whatIfAnswerLabel1.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 30, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
//        whatIfAnswerLabel2.sizeToFit()
//        whatIfAnswerLabel2.alpha = 0
//

        
//        self.view.addSubview(whatIfAnswerLabel3)
//        whatIfAnswerLabel3.anchor(top: whatIfAnswerLabel2.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 30, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
//        whatIfAnswerLabel3.sizeToFit()
//        whatIfAnswerLabel3.alpha = 0
//
//        self.view.addSubview(whatIfAnswerLabel4)
//        whatIfAnswerLabel4.anchor(top: whatIfAnswerLabel3.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 30, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
//        whatIfAnswerLabel4.sizeToFit()
//        whatIfAnswerLabel4.alpha = 0

//        scheduledTimerWithTimeInterval()

        
        // TOP TEXT
        
//        let tempView = UIView()
//        self.view.addSubview(tempView)
//        tempView.anchor(top: answerLabel.bottomAnchor, left: view.leftAnchor, bottom: addListButton.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

//        self.view.addSubview(legitLabel)
//        legitLabel.anchor(top: whatIfAnswerLabel2.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 30, paddingLeft: 5, paddingBottom: 40, paddingRight: 5, width: 0, height: 0)
////        legitLabel.centerYAnchor.constraint(lessThanOrEqualTo: tempView.centerYAnchor, constant: 10).isActive = true
//        legitLabel.sizeToFit()
//        legitLabel.topAnchor.constraint(lessThanOrEqualTo: answerLabel.bottomAnchor, constant: 20).isActive = true
        
//        self.view.addSubview(believeTextView)
//        believeTextView.anchor(top: believeHeader1.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 20, paddingRight: 20, width: 0, height: 0)
//        believeTextView.sizeToFit()
//
//        if UIScreen.main.bounds.height > 750 {
//            self.believeTextView.font = UIFont(font: .avenirNextMedium, size: 17)
//        } else {
//            self.believeTextView.font = UIFont(font: .avenirNextMedium, size: 15)
//        }
//
        // BOTTOM TEXT
        
        //        self.view.addSubview(believeHeader2)
        //        believeHeader2.anchor(top: believeTextView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 20, paddingBottom: 20, paddingRight: 20, width: 0, height: 40)
        //        believeHeader2.sizeToFit()
        //
        //        self.view.addSubview(methodCollectionView)
        //        methodCollectionView.anchor(top: believeHeader2.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 60)
        //
        //        self.view.addSubview(methodDisplay)
        //        methodDisplay.anchor(top: methodCollectionView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 15, paddingLeft: 20, paddingBottom: 20, paddingRight: 20, width: 0, height: 0)
        //        methodDisplay.bottomAnchor.constraint(lessThanOrEqualTo: addListButton.topAnchor).isActive = true
        //        methodDisplay.sizeToFit()
        //        displayMethod()
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
    
    let locationCellID = "locationCellID"
    func setupCollectionView(){
        methodCollectionView.backgroundColor = UIColor.clear
        methodCollectionView.register(BounceSelectCell.self, forCellWithReuseIdentifier: locationCellID)
        methodCollectionView.delegate = self
        methodCollectionView.dataSource = self
        methodCollectionView.isScrollEnabled = false
        methodCollectionView.allowsMultipleSelection = false
    }
    
    func setupNavigationItems(){
        let customFont = UIFont(name: "Poppins-Bold", size: 18)
        var attributedHeaderTitle = NSMutableAttributedString()
        
        let headerTitle = NSAttributedString(string: "WELCOME", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: customFont])
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return methodOptions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: locationCellID, for: indexPath) as! BounceSelectCell
        cell.cellTag = indexPath.item
        cell.uploadLocations.text = methodOptions[indexPath.item]
        cell.backgroundColor = self.selectedMethod == indexPath.item ? UIColor.legitColor() : UIColor.white
        cell.uploadLocations.textColor = self.selectedMethod == indexPath.item ? UIColor.white : UIColor.black
        cell.delegate = self
        return cell
    }
    
    func didSelect(tag: Int?) {
        guard let tag = tag else {
            return
        }
        print("BounceSelectCell | \(tag)")
        self.selectedMethod = tag
    }
    
    
    func displayMethod(){
        self.methodCollectionView.reloadData()
        methodDisplay.text = methodDetails[selectedMethod]
        methodDisplay.sizeToFit()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedMethod = indexPath.item
    }
    
    
}
