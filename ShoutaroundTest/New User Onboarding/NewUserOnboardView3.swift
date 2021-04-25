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


class NewUserOnboardView3: UIViewController {

    
    @objc func animateLabels(){
        
        let durationOfAnimationInSecond = 1.0
        
        UIView.transition(with: infoImageView, duration: durationOfAnimationInSecond, options: .transitionCrossDissolve, animations: {
            self.infoImageView.alpha = 1
        }) { (finished) in
            
        }
        
    }
    
    
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
    
    
    var timer = Timer()
    
    
    @objc func handleNext(){
//        let listView = UserWelcome2View()
        let listView = NewUserOnboardView4()
        self.navigationController?.pushViewController(listView, animated: true)
        //        self.navigationController?.present(listView, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
//        animateLabels()
    }


    override func viewDidDisappear(_ animated: Bool) {
    }
    
    
    
    var infoImageView: UIImageView = {
        let img = UIImageView()
        img.image = #imageLiteral(resourceName: "Example_map").withRenderingMode(.alwaysOriginal)
        img.contentMode = .scaleAspectFit
        img.alpha = 1
        return img
    }()
    
    let headerLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.backgroundColor = UIColor.clear
//        label.font = UIFont(font: .avenirBlack, size: 30)
        label.font = UIFont(name: "Poppins-Bold", size: 30)
        label.text = "Food Map"
        label.textColor = UIColor.ianBlackColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping

        return label
    }()

    
    let infoTextView: UITextView = {
        let tv = UITextView()
        tv.isScrollEnabled = false
        tv.textContainer.maximumNumberOfLines = 0
        tv.textContainerInset = UIEdgeInsets.zero
        tv.textContainer.lineBreakMode = .byTruncatingTail
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.textAlignment = .center
        tv.isEditable = false
        tv.backgroundColor = UIColor.clear
        return tv
    }()
    
    let headerText = "Tag By Emoji"
    
    let infoText =
    """
    See a map of all your food photos

    Filter your map by emoji, food, user or lists
    to find Legit food around you
    """

//    No more endlessly scrolling through your photos to find a specific food picture
//    No more forgetting the name of that awesome restaurant from 3 years ago
//    Remember all the food you tried on your last trip and share your recommendations
    
        
    let nextButton: UIButton = {
        let button = UIButton()
        button.setTitle("Next", for: .normal)

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
        
        button.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
        return button
    } ()

    
    let hungryLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.backgroundColor = UIColor.clear
        //        label.font = UIFont(font: .avenirBlack, size: 30)
        label.font = UIFont(name: "Poppins-Bold", size: 25)
        
        label.text = "Tag Posts By "
        label.textColor = UIColor.ianLegitColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    let foodEmojiLabel: LightPaddedUILabel = {
        let label = LightPaddedUILabel()
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = UIFont(name: "Poppins-Bold", size: 25)
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
    
    
    var pageControl : UIPageControl = UIPageControl()
    
    let backButton: UIButton = {
        let button = UIButton()
        button.setTitle("Back", for: .normal)
        button.titleLabel?.textColor = UIColor.darkGray
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.clear
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.legitColor().cgColor
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        button.layer.cornerRadius = 10
        button.titleLabel?.textAlignment = NSTextAlignment.left
        button.setTitleColor(UIColor.darkGray, for: .normal)
        
        button.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
        return button
    } ()
    
    
    func handleBackButton(){

        let transition = CATransition()
        transition.duration = 0.5
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromLeft
        transition.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
        view.window!.layer.add(transition, forKey: kCATransition)
        let welcomeView = NewUserOnboardView2()
        self.navigationController?.pushViewController(welcomeView, animated: true)
        print("handleBack")

    }
    
    
    override func viewDidLoad() {
        
        let marginScale = CGFloat(UIScreen.main.bounds.height > 750 ? 1 : 0.8)
        let topMargin = CGFloat(UIScreen.main.bounds.height > 750 ? 30 : 25)
        let sideMargin = CGFloat(UIScreen.main.bounds.height > 750 ? 15 : 10)

        let topGap = UIScreen.main.bounds.height > 750 ? 30 : 25
//        let headerFontSize = UIScreen.main.bounds.height > 750 ? 30 : 25
        let headerFontSize =  25

        let detailFontSize = UIScreen.main.bounds.height > 750 ? 22 : 20
        
        
        self.view.backgroundColor = UIColor.backgroundGrayColor()
//        self.view.backgroundColor = UIColor.white
        self.navigationController?.isNavigationBarHidden = true
        
        self.view.isUserInteractionEnabled = true
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleNext))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleNext))
        self.view.addGestureRecognizer(tapGesture)

                
        view.addSubview(pageControl)
        pageControl.anchor(top: nil, left: nil, bottom: view.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 20 * marginScale, paddingRight: 0, width: 0, height: 0)
        pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        setupPageControl()
        
        view.addSubview(nextButton)
        nextButton.anchor(top: nil, left: nil, bottom: pageControl.topAnchor, right: nil, paddingTop: 0, paddingLeft: 50 * marginScale, paddingBottom: 5 * marginScale, paddingRight: 50 * marginScale, width: 200, height: 50 * marginScale)
        nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        nextButton.sizeToFit()
        
        view.addSubview(backButton)
        backButton.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 30 * marginScale, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        backButton.centerYAnchor.constraint(equalTo: nextButton.centerYAnchor).isActive = true
        backButton.sizeToFit()

        view.addSubview(infoImageView)
//        infoImageView.heightAnchor.constraint(equalTo: infoImageView.widthAnchor, multiplier: 1.2).isActive = true
        infoImageView.contentMode = .scaleAspectFit
        infoImageView.autoresizingMask = .flexibleHeight
        infoImageView.layer.cornerRadius = 10
        infoImageView.layer.borderColor = UIColor.lightGray.cgColor
        infoImageView.layer.borderWidth = 1
        infoImageView.backgroundColor = UIColor.white
        infoImageView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: topMargin, paddingLeft: 50, paddingBottom: 0, paddingRight: 50, width: 0, height: 0)
        infoImageView.layer.applySketchShadow()

        infoImageView.heightAnchor.constraint(equalTo: infoImageView.widthAnchor, multiplier: 1.5).isActive = true
        infoImageView.sizeToFit()

        
        view.addSubview(headerLabel)
        headerLabel.anchor(top: infoImageView.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 25, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        headerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        
        view.addSubview(infoTextView)
        infoTextView.anchor(top: headerLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10 * marginScale, paddingLeft: sideMargin, paddingBottom: 20 * marginScale, paddingRight: sideMargin, width: 0, height: 0)
//        infoTextView.bottomAnchor.constraint(lessThanOrEqualTo: nextButton.topAnchor, constant: 10).isActive = true
        infoTextView.text = infoText
        infoTextView.font = UIFont(font: .avenirNextRegular, size: 16 * marginScale)
        infoTextView.textColor = UIColor.darkGray
        infoTextView.sizeToFit()
        
        self.view.bringSubviewToFront(nextButton)

                        
//        self.view.addSubview(foodEmojiLabel)
//        foodEmojiLabel.anchor(top: infoTextView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        foodEmojiLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        foodEmojiLabel.font = UIFont(name: "Poppins-Bold", size: CGFloat(20))
////        foodEmojiLabel.textColor = UIColor.darkGray
////        foodEmojiLabel.sizeToFit()
//        scheduledTimerWithTimeInterval()
        
//        var swipeView = UIView()
//        swipeView.backgroundColor = UIColor.clear
//        swipeView.isUserInteractionEnabled = true
//        let swipeNext = UISwipeGestureRecognizer(target: self, action: #selector(handleNext))
//        swipeNext.direction = .left
//        swipeView.addGestureRecognizer(swipeNext)
//        view.addSubview(swipeView)
//        swipeView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nextButton.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//

        
        
    }
    
    func setupPageControl(){
        self.pageControl.numberOfPages = 6
        self.pageControl.currentPage = 3
        self.pageControl.tintColor = UIColor.lightGray
        self.pageControl.pageIndicatorTintColor = UIColor.lightGray
        self.pageControl.currentPageIndicatorTintColor = UIColor.ianLegitColor()
        //        self.pageControl.backgroundColor = UIColor.rgb(red: 68, green: 68, blue: 68)
    }
    
    
    func scheduledTimerWithTimeInterval(){
        // Scheduling timer to Call the function "updateCounting" with the interval of 1 seconds
        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.updateCounting), userInfo: nil, repeats: true)
    }
    
    let foodList = ["🍔", "🐮","🍳", "🇺🇸", "👌", "🔥", "❌🍖","🍝","🍣", "🍕","🍜","🇯🇵"]
    var foodTagInt = 0

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
            self.foodEmojiLabel.text = emoji + "  \(emojiText)"
//            self.foodEmojiLabel.text = "\(emojiText)" + emoji
            //            self.foodEmojiLabel.sizeToFit()
        }, completion: nil)
        
        
    }
    
}
