//
//  SubscriptionViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 5/1/21.
//  Copyright © 2021 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import Purchases
import StoreKit
import FirebaseAuth
import FirebaseDatabase

class SubscriptionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SubscriptionCellDelegate {


    var displayUserID: String?
    var displayUser: User? {
        didSet {
            setupUser()
        }
    }
    
    func setupUser() {
        let user = self.displayUser
        guard let profileImageUrl = self.displayUser?.profileImageUrl else {return}
        profileImageView.loadImage(urlString: profileImageUrl)
        self.usernameLabel.text = self.displayUser?.username
        setupUserStats()
    }
    
    func setupUserStats() {
        let user = self.displayUser

        let postCount = user?.posts_created ?? 0
        let followingCount = user?.followingCount ?? 0
        let followerCount = user?.followersCount ?? 0
        let listCount = user?.lists_created ?? 0
        let voteCount = user?.votes_received ?? 0
        
        let socialLabelColor = UIColor.gray
        let socialMetricColor = UIColor.ianBlackColor()
        
        let socialMetricFont = UIFont(font: .arialRoundedMTBold, size: 20)
        let socialLabelFont = UIFont(font: .avenirMedium, size: 16)
        
        
        // Post Count Label
        var attributedMetric = NSMutableAttributedString(string: "\(String(postCount))", attributes: [NSAttributedString.Key.foregroundColor: socialMetricColor, NSAttributedString.Key.font: socialMetricFont])

        var attributedLabel = NSMutableAttributedString(string: "\n Posts", attributes: [NSAttributedString.Key.foregroundColor: socialLabelColor, NSAttributedString.Key.font: socialLabelFont])
        
        attributedMetric.append(attributedLabel)
        self.postsLabel.attributedText = attributedMetric
        self.postsLabel.sizeToFit()
        
        // List Count Label
        attributedMetric = NSMutableAttributedString(string: "\(String(listCount))", attributes: [NSAttributedString.Key.foregroundColor: socialMetricColor, NSAttributedString.Key.font: socialMetricFont])

        attributedLabel = NSMutableAttributedString(string: "\n Lists", attributes: [NSAttributedString.Key.foregroundColor: socialLabelColor, NSAttributedString.Key.font: socialLabelFont])
        attributedMetric.append(attributedLabel)
        self.listLabel.attributedText = attributedMetric
        self.listLabel.sizeToFit()
        
        // Followers Label
        attributedMetric = NSMutableAttributedString(string: "\(String(followerCount))", attributes: [NSAttributedString.Key.foregroundColor: socialMetricColor, NSAttributedString.Key.font: socialMetricFont])

        attributedLabel = NSMutableAttributedString(string: "\n Followers", attributes: [NSAttributedString.Key.foregroundColor: socialLabelColor, NSAttributedString.Key.font: socialLabelFont])
        attributedMetric.append(attributedLabel)
        self.followersLabel.attributedText = attributedMetric
        self.followersLabel.sizeToFit()
        
    }
    
    
    
    var userSubscriptions: [Subscription] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    var premiumSubscription: Subscription? = nil {
        didSet {
            self.isPremiumSub = premiumSubscription != nil
            self.tableView.reloadData()
        }
    }
    var isPremiumSub = false {
        didSet {
            self.tableView.reloadData()
        }
    }

    let navHeaderLabel: UILabel = {
        let label = UILabel()
        label.layer.borderColor = UIColor.clear.cgColor
        label.layer.borderWidth = 0
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = UIFont(name: "Poppins-Bold", size: 20)
        label.textColor = .black
        label.text = "Subscriptions"
//        label.isUserInteractionEnabled = true
//        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openNotifications)))
        return label
    }()
    
    let navBackButton = navBackButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))

    
    var headerView = UIView()
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "username"
        label.font = UIFont(name: "Poppins-Regular", size: 15)
        label.textColor = UIColor.ianBlackColor()
        label.textAlignment = NSTextAlignment.left
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
    
    var profileCountStackView = UIStackView()
    
    let subCellID = "SubCellID"
    
    lazy var tableView : UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        tv.estimatedRowHeight = 100
        tv.allowsMultipleSelection = false
        return tv
    }()

    
    func fetchUserPurchase() {
        
//        let annualSubProductID = "legit_premium_annual"
//        let monthlySubProductID = "legit_premium_monthly"
//        let indSubProductID = "creator_sub_credit"
//        let indSub1_ID = "creator_sub_1"
//        let indSub2_ID = "creator_sub_2"
//        let indSub5_ID = "creator_sub_5"
//        let indSub10_ID = "creator_sub_10"
        
        Purchases.shared.purchaserInfo { (info, error) in
            if info?.entitlements["premium"]?.isActive == true {
                self.isPremiumSub = true
            } else {
                self.isPremiumSub = false
            }
            
            var subIds = info?.allPurchasedProductIdentifiers ?? []
            if subIds.contains(annualSubProductID) {
                
            }
            
            
            
        }
    }
    
    let subButton: UIButton = {
        let button = UIButton()
//        let listIcon = #imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate)
//        button.setImage(listIcon, for: .normal)
        button.backgroundColor = UIColor.ianLegitColor()
        button.setTitle("Active Fan Subscription", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont(font: .avenirNextDemiBold, size: 16)
        button.isUserInteractionEnabled = false
        button.tintColor = UIColor.gray
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 5, bottom: 4, right: 5)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white

        let navView = UIView()
        navView.backgroundColor = UIColor.backgroundGrayColor()
        self.view.addSubview(navView)
        navView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 60)
        
//        let bottomDiv = UIView()
//        self.view.addSubview(bottomDiv)
//        bottomDiv.anchor(top: navView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
//        bottomDiv.backgroundColor = UIColor.lightGray

        
        self.view.addSubview(navHeaderLabel)
        navHeaderLabel.anchor(top: view.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 20, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        navHeaderLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true

        self.view.addSubview(navBackButton)
        navBackButton.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        navBackButton.centerYAnchor.constraint(equalTo: self.navHeaderLabel.centerYAnchor).isActive = true
        navBackButton.addTarget(self, action: #selector(didTapDismiss), for: .touchUpInside)
        

        self.view.addSubview(headerView)
        headerView.anchor(top: navView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 100)
        
        headerView.addSubview(profileImageView)
        profileImageView.anchor(top: headerView.topAnchor, left: headerView.leftAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 0, width: 70, height: 70)
        profileImageView.layer.cornerRadius = 70/2
        profileImageView.layer.masksToBounds = true
        profileImageView.layer.borderWidth = 0.5
        profileImageView.layer.borderColor = UIColor.lightGray.cgColor
        profileImageView.clipsToBounds = true
        
    
//        let postsView = UIView()
//        postsView.addSubview(postsLabel)
//        postsLabel.center = postsView.center
//        postsLabel.leftAnchor.constraint(lessThanOrEqualTo: postsView.leftAnchor).isActive = true
//        postsLabel.bottomAnchor.constraint(equalTo: postsView.bottomAnchor).isActive = true
//        postsLabel.topAnchor.constraint(equalTo: postsView.topAnchor).isActive = true
//
//        let listsView = UIView()
//        listsView.addSubview(listLabel)
//        listLabel.center = listsView.center
//        listLabel.bottomAnchor.constraint(equalTo: listsView.bottomAnchor).isActive = true
//        listLabel.topAnchor.constraint(equalTo: listsView.topAnchor).isActive = true
//
//        let followersView = UIView()
//        followersView.addSubview(followersLabel)
//        followersLabel.center = followersView.center
//        followersLabel.bottomAnchor.constraint(equalTo: followersView.bottomAnchor).isActive = true
//        followersLabel.topAnchor.constraint(equalTo: followersView.topAnchor).isActive = true

//        profileCountStackView = UIStackView(arrangedSubviews: [postsView, listsView, followersView])
        profileCountStackView = UIStackView(arrangedSubviews: [postsLabel, listLabel, followersLabel])
    
        profileCountStackView.distribution = .fillEqually
        profileCountStackView.axis = .horizontal
//        profileCountStackView.backgroundColor = UIColor.yellow
        headerView.addSubview(profileCountStackView)
        profileCountStackView.anchor(top: profileImageView.topAnchor, left: profileImageView.rightAnchor, bottom: nil, right: headerView.rightAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 20, paddingRight: 0, width: 0, height: 0)
//        profileCountStackView.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
//        postsLabel.leftAnchor.constraint(equalTo: usernameLabel.leftAnchor).isActive = true
//        usernameLabel.bottomAnchor.constraint(equalTo: postsLabel.topAnchor, constant: 20).isActive = true

        
        headerView.addSubview(usernameLabel)
        usernameLabel.anchor(top: profileImageView.bottomAnchor, left: profileImageView.leftAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 0, height: 0)
        
        headerView.addSubview(subButton)
        subButton.anchor(top: nil, left: nil, bottom: nil, right: headerView.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 40, width: 0, height: 35)
        subButton.centerYAnchor.constraint(equalTo: usernameLabel.centerYAnchor).isActive = true
        subButton.addTarget(self, action: #selector(activateSub), for: .touchUpInside)
        usernameLabel.rightAnchor.constraint(lessThanOrEqualTo: subButton.leftAnchor).isActive = true
        
        
//        usernameLabel.leftAnchor.constraint(equalTo: postsLabel.leftAnchor).isActive = true

        setupTableView()
        self.view.addSubview(tableView)
        tableView.anchor(top: headerView.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 20, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        let tableDiv = UIView()
        self.view.addSubview(tableDiv)
        tableDiv.anchor(top: nil, left: view.leftAnchor, bottom: tableView.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        tableDiv.backgroundColor = UIColor.lightGray
        self.checkCurrentStatus()
        // Do any additional setup after loading the view.
    }
    
    @objc func activateSub() {
        self.alert(title: "Subscription", message: "Activate Sub")
    }

    func checkCurrentStatus() {
        print("checkCurrentStatus")
        Purchases.shared.purchaserInfo { (info, error) in
            // Check the info parameter for active entitlements

            var currentSubs = info?.activeSubscriptions
            var subIds = info?.allPurchasedProductIdentifiers ?? []
            var expiry = info?.latestExpirationDate
            var start = info?.originalPurchaseDate
            var request = info?.requestDate
            var entit = info?.entitlements


//            var temp = ""
//            for line in description ?? [] {
//                temp += line
//            }
            
            var displayText = "Current Sub \(currentSubs)"
            displayText += "\n \(subIds)"
            displayText += "\n \(expiry)"
            displayText += "\n \(start)"
            displayText += "\n \(entit)"

            var description = info?.description.replacingOccurrences(of: "{(\n)}", with: "").replacingOccurrences(of: "{\n}", with: "")
//            print(description)
//            displayText += "\n \(String(description ?? ""))"

            print(displayText)
//            self.currentSubTextView.text = displayText
//            self.currentSubTextView.sizeToFit()
            
        }
    }
    
//    Current Sub Optional(Set([]))
//     ["creator_sub_credit", "legit_premium_annual", "legit_premium_monthly"]
//     Optional(2021-05-02 09:12:16 +0000)
//     Optional(2013-08-01 07:00:00 +0000)
//     Optional(<RCEntitlementInfos: self.all={
//        premium = "<RCEntitlementInfo: identifier=premium,\nisActive=0,\nwillRenew=0,\nperiodType=0,\nlatestPurchaseDate=2021-05-02 08:12:16 +0000,\noriginalPurchaseDate=2021-05-02 05:04:35 +0000,\nexpirationDate=2021-05-02 09:12:16 +0000,\nstore=0,\nproductIdentifier=legit_premium_annual,\nisSandbox=1,\nunsubscribeDetectedAt=2021-05-02 09:14:39 +0000,\nbillingIssueDetectedAt=(null),\nownershipType=0,\n>";
//    }, self.active={
//    }>)
    
    @objc func didTapDismiss() {
        self.dismiss(animated: true) {
            print("DISMISSED")
        }
    }
    
    @objc func refreshAll() {
        
    }
    
    func setupTableView(){
        tableView.register(SubscriptionCell.self, forCellReuseIdentifier: subCellID)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshAll), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.alwaysBounceVertical = true
        tableView.keyboardDismissMode = .onDrag
        tableView.allowsSelection = false
        tableView.delegate = self

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: subCellID, for: indexPath) as! SubscriptionCell
        cell.delegate = self
        cell.contentView.isUserInteractionEnabled = false

        let currentDate = Date()
        var dateComponent = DateComponents()
        dateComponent.year = 1
        let futureDate = Calendar.current.date(byAdding: dateComponent, to: currentDate)
        if indexPath.row == 0 {
            cell.premiumCell = true
            cell.isPremiumAnnualSub = true
            cell.expiryDate = futureDate
        } else if indexPath.row == 1 {
            cell.isPremiumMonthlySub = true
            cell.premiumCell = true
            cell.expiryDate = futureDate
        } else if indexPath.row == 2 {
            cell.premiumCell = true
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80

    }
    
    
    func extTapUserUid(uid: String) {
        
    }
    
    func didTapPremiumSub() {
        self.openPremiumSub()
    }
    
    func openPremiumSub() {
        var prem = PremiumSubViewController()
        self.present(prem, animated: true) {
            print("Present Premium Sub")
        }
    }
    
    func userPremiumSub(){
        
        let optionsAlert = UIAlertController(title: "Premium Subscription", message: "Subscribe to unlock Premium Featues", preferredStyle: UIAlertController.Style.alert)
        
        optionsAlert.addAction(UIAlertAction(title: "Annual Sub for $4.49/Year", style: .default, handler: { (action: UIAlertAction!) in
            // Allow Editing
            print("Annual Sub")
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Monthly Sub for $0.49/Month", style: .default, handler: { (action: UIAlertAction!) in
            // Allow Editing
            print("Month Sub")
        }))

        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        present(optionsAlert, animated: true) {
            optionsAlert.view.superview?.isUserInteractionEnabled = true
            optionsAlert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.alertClose(gesture:))))
        }
    }

    
    
}
