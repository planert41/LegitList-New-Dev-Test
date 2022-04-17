//
//  OpenAppViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou on 1/8/22.
//  Copyright © 2022 Wei Zou Ang. All rights reserved.
//

import UIKit

class OpenAppViewController: UIViewController, UIScrollViewDelegate {

//    var backgroundImageView: UIImageView = {
//        let imageView = UIImageView(frame: .zero)
//        imageView.image = #imageLiteral(resourceName: "FullMap").withRenderingMode(.alwaysOriginal)
//        imageView.contentMode = .scaleAspectFit
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        return imageView
//    }()
    
    let backgroundImageView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.backgroundColor = .white
        return scroll
    }()
//
    let loginButton: UIButton = {
        
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.backgroundColor = UIColor.ianLegitColor()
        button.layer.cornerRadius = 15
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.setTitleColor(.white, for: .normal)
        button.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)

//        button.addTarget(self, action: #selector(handleLogIn), for: .touchUpInside)
        button.isEnabled = true
        return button
    }()
    
    let signUpButton: UIButton = {
        
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.backgroundColor = UIColor.ianWhiteColor()
        button.layer.cornerRadius = 15
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.setTitleColor(.legitColor(), for: .normal)
        button.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)

//        button.addTarget(self, action: #selector(handleLogIn), for: .touchUpInside)
        button.isEnabled = true
        return button
    }()
    
    let findOutMoreButton: UIButton = {
        
        let button = UIButton(type: .system)
        button.setTitle("Find Out More", for: .normal)
        button.backgroundColor = UIColor.clear
        button.layer.cornerRadius = 15
        button.titleLabel?.font = UIFont(font: .avenirNextDemiBold, size: 13)
        button.setTitleColor(.lightGray, for: .normal)
        button.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
//        button.addTarget(self, action: #selector(handleLogIn), for: .touchUpInside)
        button.isEnabled = true
        return button
    }()
    
    var LegitImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.image = #imageLiteral(resourceName: "Legit_Vector").withRenderingMode(.alwaysOriginal)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let LegitDetailsLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = UIFont(font: .avenirNextDemiBold, size: 20)
        label.backgroundColor = UIColor.clear
        label.text = "The Friend-Sourcing App For Legit Food"
        label.textColor = UIColor.ianBlackColor()
        label.numberOfLines = 0
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
    Discover great food from your friends
    """
//    Find 🍔 You ♥️ From Your 🙋‍♂️🙋‍♀️

    let LegitSubImageLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = UIFont(name: "Poppins-Regular", size: 11)
        label.backgroundColor = UIColor.clear
        label.text = "Find 🍔 You ♥️ From Your 🙋‍♂️🙋‍♀️"
        label.textColor = UIColor.darkGray
        label.numberOfLines = 0
        return label
    }()
    
    
//    """
//    Find 🍔 You ♥️ From Your 🙋‍♂️🙋‍♀️//
//    Tap to learn more
//    """
    
    let infoView = UIView()

    var pageControl : UIPageControl = UIPageControl()
    
    let fullIMapImg: UIImage = #imageLiteral(resourceName: "FullMap")
    let fullIFeedImg: UIImage  = #imageLiteral(resourceName: "FullFeed")
    let fullIListImg: UIImage  = #imageLiteral(resourceName: "FullList")
    let fullIEmojiImg: UIImage  = #imageLiteral(resourceName: "FullEmoji")
    let fullIPostImg: UIImage  = #imageLiteral(resourceName: "FullPost")
    let fullIProfileImg: UIImage  = #imageLiteral(resourceName: "FullProfile")

    var backgroundImgs:[UIImage] = []
    
    var moveTimer: TimeInterval = 8
    var moveInd: Bool = true
    var imgTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.modalPresentationStyle = .fullScreen
//        self.isModalInPresentation = true
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.isNavigationBarHidden = true
        
        view.backgroundColor = UIColor.backgroundGrayColor()
        
        view.addSubview(backgroundImageView)
        backgroundImageView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        backgroundImageView.anchor(top: topLayoutGuide.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        backgroundImageView.alpha = 0.8
        backgroundImageView.isPagingEnabled = true
        backgroundImageView.delegate = self
        
        setupBackgroundImageView()
        
        view.addSubview(infoView)
        infoView.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        infoView.backgroundColor = UIColor.backgroundGrayColor()

        infoView.addSubview(findOutMoreButton)
        findOutMoreButton.anchor(top: nil, left: infoView.leftAnchor, bottom: infoView.bottomAnchor, right: infoView.rightAnchor, paddingTop: 0, paddingLeft: 50, paddingBottom: 30, paddingRight: 50, width: 0, height: 0)
        findOutMoreButton.sizeToFit()
        findOutMoreButton.addTarget(self, action: #selector(extShowOnboarding), for: .touchUpInside)
//        findOutMoreButton.isHidden = true
        
        infoView.addSubview(signUpButton)
        signUpButton.anchor(top: nil, left: infoView.leftAnchor, bottom: infoView.bottomAnchor, right: infoView.rightAnchor, paddingTop: 0, paddingLeft: 50, paddingBottom: 70, paddingRight: 50, width: 0, height: 50)
        signUpButton.addTarget(self, action: #selector(tapSignup), for: .touchUpInside)
        
        infoView.addSubview(loginButton)
        loginButton.anchor(top: nil, left: infoView.leftAnchor, bottom: signUpButton.topAnchor, right: infoView.rightAnchor, paddingTop: 0, paddingLeft: 50, paddingBottom: 8, paddingRight: 50, width: 0, height: 50)
        loginButton.addTarget(self, action: #selector(tapLogin), for: .touchUpInside)

        infoView.addSubview(infoTextView)
        infoTextView.anchor(top: nil, left: infoView.leftAnchor, bottom: loginButton.topAnchor, right: infoView.rightAnchor, paddingTop: 0, paddingLeft: 30, paddingBottom: 25, paddingRight: 30, width: 0, height: 0)
        infoTextView.text = infoText
        infoTextView.font = UIFont(font: .avenirNextRegular, size: 17)
        infoTextView.isUserInteractionEnabled = true
        infoTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(extShowOnboarding)))
//        infoTextView.font = UIFont(name: "Poppins-SemiBold", size: 18)
        
        infoTextView.textColor = UIColor.darkGray
        infoTextView.sizeToFit()
        
//        infoView.addSubview(LegitSubImageLabel)
//        LegitSubImageLabel.anchor(top: nil, left: infoView.leftAnchor, bottom: infoTextView.topAnchor, right: infoView.rightAnchor, paddingTop: 0, paddingLeft: 30, paddingBottom: 10, paddingRight: 30, width: 0, height: 0)
//        LegitSubImageLabel.sizeToFit()
//        LegitSubImageLabel.isHidden = true

        infoView.addSubview(LegitImageView)
        LegitImageView.anchor(top: nil, left: nil, bottom: infoTextView.topAnchor, right: nil, paddingTop: 30, paddingLeft: 25, paddingBottom: 15, paddingRight: 25, width: 0, height: 45)
        LegitImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        LegitImageView.isUserInteractionEnabled = true
        LegitImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(extShowOnboarding)))

        
        view.addSubview(pageControl)
        setupPageControl()
        pageControl.anchor(top: infoView.topAnchor, left: infoView.leftAnchor, bottom: LegitImageView.topAnchor, right: infoView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 20)
        pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        pageControl.backgroundColor = UIColor.yellow
        startTimer()


        // Do any additional setup after loading the view.
    }
    
    func startTimer() {
        imgTimer?.invalidate()
        imgTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(moveToNextImage), userInfo: nil, repeats: true)
    }
    
    @objc func moveToNextImage() {
        self.currentImage += 1
        if self.currentImage >= backgroundImgs.count {
            self.currentImage = 0
        }
        
        let xPosition = self.backgroundImageView.frame.width * CGFloat(self.currentImage)
        self.backgroundImageView.scrollRectToVisible(CGRect(x:xPosition, y:0, width:self.backgroundImageView.frame.width, height:self.backgroundImageView.frame.height), animated: true)
//        print("MOVE ", self.currentImage, xPosition, xPosition)

    }
    
    @objc func resetMovetimer() {
        self.moveInd = true
    }
    
    
    var currentImage = 0 {
        didSet {
            setupPageControl()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.currentImage = scrollView.currentPage - 1
        startTimer()
//        self.moveInd = false
//        Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(resetMovetimer), userInfo: nil, repeats: true)

    }
    
    func setupPageControl(){
        let imageCount = self.backgroundImgs.count
        self.pageControl.numberOfPages = imageCount
        self.pageControl.currentPage = self.currentImage
        self.pageControl.tintColor = UIColor.red
        self.pageControl.pageIndicatorTintColor = UIColor.lightGray
        self.pageControl.currentPageIndicatorTintColor = UIColor.ianLegitColor()
        self.pageControl.sizeToFit()
    }
    
    
    func setupBackgroundImageView() {

        self.backgroundImgs = [self.fullIMapImg, self.fullIFeedImg, self.fullIPostImg, self.fullIProfileImg, self.fullIListImg]
        var imgCount = backgroundImgs.count
        backgroundImageView.contentSize.width = backgroundImageView.frame.width * CGFloat((imgCount))

        
        
        
        for i in 0 ..< (self.backgroundImgs.count) {

            let imageView = UIImageView()
            imageView.image = backgroundImgs[i].withRenderingMode(.alwaysOriginal)
            imageView.contentMode = .scaleAspectFit
            imageView.clipsToBounds = true
            imageView.isUserInteractionEnabled = true
            imageView.contentMode = .top
            
//            imageView.translatesAutoresizingMaskIntoConstraints = false

            let xPosition = self.backgroundImageView.frame.width * CGFloat(i)
            imageView.frame = CGRect(x: xPosition, y: 0, width: backgroundImageView.frame.width, height: backgroundImageView.frame.height)
            backgroundImageView.addSubview(imageView)
//            print("adding Subview \(i), \(xPosition) | \(backgroundImageView.frame.width) | \(backgroundImageView.contentSize.width)")

        }
        

//        let imageView = UIImageView()
//        imageView.image = backgroundImgs[0].withRenderingMode(.alwaysOriginal)
//        imageView.contentMode = .scaleAspectFill
//        imageView.clipsToBounds = true
//        imageView.isUserInteractionEnabled = true
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//
//        let xPosition = self.backgroundImageView.frame.width * CGFloat(0)
//        imageView.frame = CGRect(x: 0, y: 0, width: backgroundImageView.frame.width, height: backgroundImageView.frame.height)
//        backgroundImageView.contentSize.width = backgroundImageView.frame.width * CGFloat((imgCount))
//        backgroundImageView.addSubview(imageView)
//        print("adding Subview \(0), \(0) | \(imageView.frame) \(backgroundImageView.frame.width, backgroundImageView.frame.height)")
//
//        let imageView1 = UIImageView()
//        imageView1.image = backgroundImgs[1].withRenderingMode(.alwaysOriginal)
//        imageView1.contentMode = .scaleAspectFill
//        imageView1.clipsToBounds = true
//        imageView1.isUserInteractionEnabled = true
//        imageView1.translatesAutoresizingMaskIntoConstraints = false
//
//        let xPosition1 = self.backgroundImageView.frame.width * CGFloat(4)
//        imageView1.frame = CGRect(x: xPosition1, y: 0, width: backgroundImageView.frame.width, height: backgroundImageView.frame.height)
//        backgroundImageView.contentSize.width = backgroundImageView.frame.width * CGFloat((imgCount))
//        backgroundImageView.addSubview(imageView1)
//        print("adding Subview \(1), \(xPosition1) | \(imageView1.frame) \(backgroundImageView.frame.width, backgroundImageView.frame.height)")

        view.bringSubviewToFront(infoView)

    }

    
    
    @objc func tapLogin() {
        let login = LoginController()
        self.navigationController?.pushViewController(login, animated: true)
        
//        self.extShowLogin()
    }
    
    @objc func tapSignup() {
        let signUp = SignUpController()
        self.navigationController?.pushViewController(signUp, animated: true)
//        self.extShowSignUp()()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
