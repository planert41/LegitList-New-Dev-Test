//
//  PremiumSubViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 5/4/21.
//  Copyright © 2021 Wei Zou Ang. All rights reserved.
//

import UIKit
import RevenueCat
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import SVProgressHUD

class PremiumSubViewController: UIViewController {

    let legitImage: UIImageView = {
        let img = UIImageView()
        img.image = #imageLiteral(resourceName: "Legit_Vector").withRenderingMode(.alwaysOriginal)
        img.contentMode = .scaleAspectFit
        return img
    }()
    
    
    let subText: String =
        """
        Legit is a personal labor of love to help foodies connect, curate, and share legit food recommendations.

        Your subscription goes towards supporting our small passionate team to keep fighting for the foodie community, and pay for our hosting & technology costs.

        Legit Premium will unlock unlimited posts and lists.
        """
    
    let subTextView: UITextView = {
        let tv = UITextView()
        tv.isScrollEnabled = false
        tv.textContainer.maximumNumberOfLines = 0
        tv.textContainerInset = UIEdgeInsets.zero
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.isEditable = false
//        tv.textContainer.lineBreakMode = .byTruncatingTail
        tv.backgroundColor = UIColor.clear
        tv.font = UIFont(name: "Poppins-Bold", size: 15)
        tv.textAlignment = .center
        tv.isScrollEnabled = false
        return tv
    }()
    
    let monthlySubButton: UIButton = {
        let button = UIButton()
//        let listIcon = #imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate)
//        button.setImage(listIcon, for: .normal)
        button.backgroundColor = UIColor.ianWhiteColor()
        button.setTitle("Active Fan Subscription", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont(font: .avenirNextDemiBold, size: 16)
        button.isUserInteractionEnabled = false
        button.tintColor = UIColor.gray
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.gray.cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10)
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.numberOfLines = 0
        return button
    }()
    
    let AnnualSubButton: UIButton = {
        let button = UIButton()
//        let listIcon = #imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate)
//        button.setImage(listIcon, for: .normal)
        button.backgroundColor = UIColor.ianWhiteColor()
        button.setTitle("Active Fan Subscription", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont(font: .avenirNextDemiBold, size: 16)
        button.isUserInteractionEnabled = false
        button.tintColor = UIColor.gray
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10)
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.numberOfLines = 0
        return button
    }()
    
    let mostPopularLabel: UILabel = {
        let label = UILabel()
        label.layer.borderColor = UIColor.clear.cgColor
        label.layer.borderWidth = 0
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = UIFont(name: "Poppins-Bold", size: 14)
        label.textColor = .mainBlue()
        label.text = "Most Popular! Save 25%"
//        label.isUserInteractionEnabled = true
//        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openNotifications)))
        return label
    }()
    
    let meetTheTeamLabel: UILabel = {
        let label = UILabel()
        label.layer.borderColor = UIColor.clear.cgColor
        label.layer.borderWidth = 0
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = UIFont(name: "Poppins-Bold", size: 17)
        label.textColor = .ianLegitColor()
        label.text = "Meet The Legit Team Here!"
//        label.isUserInteractionEnabled = true
//        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openNotifications)))
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        view.backgroundColor = UIColor.lightBackgroundGrayColor()
        view.addSubview(legitImage)
        legitImage.anchor(top: view.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 200, height: 120)
        legitImage.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        
        view.addSubview(subTextView)
        subTextView.anchor(top: legitImage.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 0)
        subTextView.text = subText
        subTextView.sizeToFit()
        
        
        view.addSubview(meetTheTeamLabel)
        meetTheTeamLabel.anchor(top: subTextView.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        meetTheTeamLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        meetTheTeamLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapMeetTheTeam)))
        meetTheTeamLabel.isUserInteractionEnabled = true
        
        
        let subButtonView = UIView()
        view.addSubview(subButtonView)
        subButtonView.anchor(top: meetTheTeamLabel.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 35, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        subButtonView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        view.addSubview(monthlySubButton)
        monthlySubButton.anchor(top: subButtonView.topAnchor, left: subButtonView.leftAnchor, bottom: subButtonView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 150, height: 200)
        monthlySubButton.addTarget(self, action: #selector(didTapMonthlySub), for: .touchUpInside)
        monthlySubButton.isUserInteractionEnabled = true

        view.addSubview(AnnualSubButton)
        AnnualSubButton.anchor(top: subButtonView.topAnchor, left: monthlySubButton.rightAnchor, bottom: subButtonView.bottomAnchor, right: subButtonView.rightAnchor, paddingTop: 0, paddingLeft: 40, paddingBottom: 0, paddingRight: 0, width: 150, height: 200)
        AnnualSubButton.addTarget(self, action: #selector(didTapAnnualSub), for: .touchUpInside)
        AnnualSubButton.isUserInteractionEnabled = true
        
        view.addSubview(mostPopularLabel)
        mostPopularLabel.anchor(top: AnnualSubButton.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 3, paddingLeft: 40, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        mostPopularLabel.centerXAnchor.constraint(equalTo: AnnualSubButton.centerXAnchor).isActive = true
        mostPopularLabel.sizeToFit()
        
        let typeColor = UIColor.ianBlackColor()
        let typeFont = UIFont(font: .arialRoundedMTBold, size: 18)
        let priceColor = UIColor.darkGray
        let priceFont = UIFont(font: .avenirNextBold, size: 16)
        
        let selectedPriceFont = UIFont(font: .avenirNextBold, size: 20)
        let selectedPriceColor = UIColor.ianLegitColor()

        // Post Count Label
        var attributedMetric = NSMutableAttributedString(string: "Monthly\nSubscription", attributes: [NSAttributedString.Key.foregroundColor: typeColor, NSAttributedString.Key.font: typeFont])

        var attributedLabel = NSMutableAttributedString(string: "\n$ 0.99 / Month", attributes: [NSAttributedString.Key.foregroundColor: priceColor, NSAttributedString.Key.font: priceFont])
        
        attributedMetric.append(attributedLabel)
        self.monthlySubButton.setAttributedTitle(attributedMetric, for: .normal)
        self.monthlySubButton.contentHorizontalAlignment = .center
        
        
        // Post Count Label
        attributedMetric = NSMutableAttributedString(string: "Annual\nSubscription", attributes: [NSAttributedString.Key.foregroundColor: selectedPriceColor, NSAttributedString.Key.font: selectedPriceFont])

        attributedLabel = NSMutableAttributedString(string: "\n$ 9.99 / Year", attributes: [NSAttributedString.Key.foregroundColor: selectedPriceColor, NSAttributedString.Key.font: priceFont])
        
        attributedMetric.append(attributedLabel)
        self.AnnualSubButton.layer.borderWidth = 3
        self.AnnualSubButton.layer.borderColor = UIColor.ianLegitColor().cgColor
        self.AnnualSubButton.setAttributedTitle(attributedMetric, for: .normal)
        self.AnnualSubButton.contentHorizontalAlignment = .center
        // Do any additional setup after loading the view.
    }
    
    
    @objc func didTapMeetTheTeam() {
        print("Meet The Team")
        let postSocialController = LegitTeamView()
        let nav = UINavigationController(rootViewController: postSocialController)
        self.present(nav, animated: true) {
        }
    }
    
    
    
    @objc func didTapMonthlySub() {
        self.handleMonthlySub()
    }
    
    @objc func didTapAnnualSub() {
        self.handleAnnualSub()
    }
    
    // CREATE A TRANSACTION ENTRY UNDER 'PREMIUM TRANSACTIONS'
    // THEN CREATE A PREMIUM USER ACCOUNT UNDER 'PREMIUM'
    
    var processing = false {
        didSet {
            if !processing {
                SVProgressHUD.dismiss()
            }
        }
    }
    
    func showProcessing() {
        self.processing = true
        SVProgressHUD.show(withStatus: "Processing Purchase")
        SVProgressHUD.dismiss(withDelay: 90) {
            if self.processing {
                SVProgressHUD.show(withStatus: "Sorry Still Processing Purchase")
            }
        }
    }
    
    
    func handleMonthlySub() {
        self.showProcessing()
        PurchaseService.purchase(productId: monthlySubProductID) { (transaction) in
            if let transaction = transaction {
                var purchaseDate = (transaction.purchaseDate ?? Date())!
                var transID = transaction.transactionIdentifier
                if transID == "0" || (transID.isEmptyOrWhitespace() ?? true) {
                    transID = NSUUID().uuidString
                    print("Random UUID : \(transID) - \(transaction.transactionIdentifier)")
                }
                Database.createPremiumSubscription(transactionId: transID, buyerId: Auth.auth().currentUser?.uid, subPeriod: .monthly) { (tempSub) in
                    Database.premiumUserSignUp(subscription: tempSub)
                    self.dismiss(animated: true) {
                        self.processing = false
                        print("Monthly User Subscription Complete | TransID: \(transID)")
//                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
            }
        }
    }
    
    func handleAnnualSub() {
        self.showProcessing()
        PurchaseService.purchase(productId: annualSubProductID) { (transaction) in
            if let transaction = transaction {
                var purchaseDate = (transaction.purchaseDate ?? Date())!
                var transID = transaction.transactionIdentifier
                Database.createPremiumSubscription(transactionId: transID, buyerId: Auth.auth().currentUser?.uid, subPeriod: .annual) { (tempSub) in
                    Database.premiumUserSignUp(subscription: tempSub)
                    self.dismiss(animated: true) {
                        self.processing = false
                        print("Annual User Subscription Complete | TransID : \(transID)")
//                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
            }
        }
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
