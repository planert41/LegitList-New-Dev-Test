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


class NewUserOnboardView: UIViewController {

    
    @objc func animateLabels(){
        
        let durationOfAnimationInSecond = 1.0
        
        UIView.transition(with: LegitLogo, duration: durationOfAnimationInSecond, options: .transitionCrossDissolve, animations: {
            self.LegitLogo.alpha = 1
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
    

    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
//        animateLabels()
    }


    override func viewDidDisappear(_ animated: Bool) {
    }
    
    
    var LegitLogo = UIImageView(image: #imageLiteral(resourceName: "legitLaunch").withRenderingMode(.alwaysOriginal))

    let LegitLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.backgroundColor = UIColor.clear
//        label.font = UIFont(font: .avenirBlack, size: 30)
        label.font = UIFont(name: "Poppins-Bold", size: 30)
        label.text = "Hello!"
        label.textColor = UIColor.ianLegitColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping

        
        return label
    }()
    
    let headerLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.backgroundColor = UIColor.clear
//        label.font = UIFont(font: .avenirBlack, size: 30)
        label.font = UIFont(name: "Poppins-Bold", size: 40)

        label.text = "Find 🍔 You ♥️ From Your 🙋‍♂️🙋‍♀️"
        label.textColor = UIColor.ianLegitColor()
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
    
    let infoText =
    """
    We are foodies who love exploring new places through food.
        
    Whenever we travel, the first thing we would do is ask our friends and foodie network for recommendations.
        
    But the text messages, shared docs and pinned maps would quickly get messy.

    So we build Legit to help us journal, share and discover our favorite foods.
    """
    
    let oldinfoText =
    """
    Your phone is a treasure trove of info on the food you have tried and loved.

    Legit creates a Social Food Journal with your food photos 📷 to:

    📌  Remember favorite places & dishes
    📋  Curate personal lists
    📫  Share food recommendations
    🔍  Find legit food from friends
    🙋‍♂️🙋‍♀️  Meet foodies with similar taste
    
        Crowdsource the internet to eat like a tourist, but ask your friends to eat like a local 🙋‍♂️🙋‍♀️


    """

//    No more endlessly scrolling through your photos to find a specific food picture
//    No more forgetting the name of that awesome restaurant from 3 years ago
//    Remember all the food you tried on your last trip and share your recommendations
    
        
    let nextButton: UIButton = {
        let button = UIButton()
        button.setTitle("Next", for: .normal)
//        button.setTitle("Welcome To Legit  🥳", for: .normal)

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
    
            
    @objc func handleNext(){
//        let listView = UserWelcome2View()
        let listView = NewUserOnboardView1()
        self.navigationController?.pushViewController(listView, animated: true)
        //        self.navigationController?.present(listView, animated: true, completion: nil)
    }
    
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
    
    
    @objc func handleBackButton(){
        self.dismiss(animated: true) {
            print("handleBack")
        }
    }
    
    var pageControl : UIPageControl = UIPageControl()
    func setupPageControl(){
        self.pageControl.numberOfPages = 6
        self.pageControl.currentPage = 0
        self.pageControl.tintColor = UIColor.lightGray
        self.pageControl.pageIndicatorTintColor = UIColor.lightGray
        self.pageControl.currentPageIndicatorTintColor = UIColor.ianLegitColor()
        //        self.pageControl.backgroundColor = UIColor.rgb(red: 68, green: 68, blue: 68)
    }
    
    override func viewDidLoad() {
        
        let marginScale = CGFloat(UIScreen.main.bounds.height > 750 ? 1 : 0.8)
        let topMargin = UIScreen.main.bounds.height > 750 ? 25 : 18
        let topGap = UIScreen.main.bounds.height > 750 ? 30 : 25
        let headerFontSize = UIScreen.main.bounds.height > 750 ? 30 : 25
        let detailFontSize = UIScreen.main.bounds.height > 750 ? 22 : 20
        
        
        self.view.backgroundColor = UIColor.backgroundGrayColor()
        self.navigationController?.isNavigationBarHidden = true
        
        self.view.isUserInteractionEnabled = true
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleNext))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleNext))
        self.view.addGestureRecognizer(tapGesture)
        
        view.addSubview(pageControl)
        pageControl.anchor(top: nil, left: nil, bottom: view.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 30 * marginScale, paddingRight: 0, width: 0, height: 0)
        pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        setupPageControl()
        
        let buttonWidth = UIScreen.main.bounds.width * 0.6

        
        view.addSubview(nextButton)
        nextButton.anchor(top: nil, left: nil, bottom: pageControl.topAnchor, right: nil, paddingTop: 0, paddingLeft: 50 * marginScale, paddingBottom: 5 * marginScale, paddingRight: 30 * marginScale, width: 200, height: 50 * marginScale)
        nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        nextButton.sizeToFit()
        
        view.addSubview(backButton)
        backButton.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 30 * marginScale, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        backButton.centerYAnchor.constraint(equalTo: nextButton.centerYAnchor).isActive = true
        backButton.sizeToFit()
        
//        self.view.addSubview(nextButton)
//        nextButton.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 20 * marginScale, paddingBottom: 50 * marginScale, paddingRight: 40 * marginScale, width: 0, height: 50 * marginScale)
//        nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        nextButton.sizeToFit()
        
        

//        view.addSubview(headerLabel)
//        headerLabel.anchor(top: topLayoutGuide.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        headerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        view.addSubview(LegitLogo)
        LegitLogo.contentMode = .scaleAspectFit
        LegitLogo.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 50 * marginScale, paddingLeft: 20 * marginScale, paddingBottom: 0, paddingRight: 20 * marginScale, width: 0, height: 0)
        LegitLogo.alpha = 0

        
        
        view.addSubview(LegitLabel)
        LegitLabel.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 50 * marginScale, paddingLeft: 20 * marginScale, paddingBottom: 40 * marginScale, paddingRight: 20 * marginScale, width: 0, height: 0)
        LegitLabel.sizeToFit()
        
        
        view.addSubview(infoTextView)
        infoTextView.anchor(top: LegitLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 30 * marginScale, paddingLeft: 15 * marginScale, paddingBottom: 20 * marginScale, paddingRight: 15 * marginScale, width: 0, height: 0)
//        infoTextView.bottomAnchor.constraint(lessThanOrEqualTo: nextButton.topAnchor, constant: 10).isActive = true
        infoTextView.text = infoText
        infoTextView.font = UIFont(font: .avenirNextDemiBold, size: 20 * marginScale)
        infoTextView.font = UIFont(name: "Poppins-Regular", size: 20 * marginScale)
        infoTextView.font = UIFont(font: .avenirMedium, size: 20 * marginScale)

        infoTextView.textColor = UIColor.ianBlackColor()
        infoTextView.sizeToFit()
        

        self.view.bringSubviewToFront(nextButton)


//        var swipeView = UIView()
//        swipeView.backgroundColor = UIColor.clear
//        swipeView.isUserInteractionEnabled = true
//        let swipeNext = UISwipeGestureRecognizer(target: self, action: #selector(handleNext))
//        swipeNext.direction = .left
//        swipeView.addGestureRecognizer(swipeNext)
//        view.addSubview(swipeView)
//        swipeView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nextButton.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        
        
    }
    
}
