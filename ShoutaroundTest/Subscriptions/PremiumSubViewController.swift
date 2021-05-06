//
//  PremiumSubViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 5/4/21.
//  Copyright © 2021 Wei Zou Ang. All rights reserved.
//

import UIKit

class PremiumSubViewController: UIViewController {

    let legitImage: UIImageView = {
        let img = UIImageView()
        img.image = #imageLiteral(resourceName: "Legit_Vector").withRenderingMode(.alwaysOriginal)
        img.contentMode = .scaleAspectFit
        return img
    }()
    
    
    let subText: String =
        """
        Subscribe to Legit Premium for unlimited posts and lists!

        Legit is a personal labor of love to help foodies curate, find and share legit food recommendations.

        Your subscription will go towards paying for our hosting costs and supporting our team to grow our community.
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
        button.backgroundColor = UIColor.backgroundGrayColor()
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
    
    let AnnualSubButton: UIButton = {
        let button = UIButton()
//        let listIcon = #imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate)
//        button.setImage(listIcon, for: .normal)
        button.backgroundColor = UIColor.backgroundGrayColor()
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ianWhiteColor()
        view.addSubview(legitImage)
        legitImage.anchor(top: view.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 200, height: 200)
        legitImage.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        view.addSubview(subTextView)
        subTextView.anchor(top: legitImage.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 0)
        subTextView.text = subText
        subTextView.sizeToFit()
        
        let subButtonView = UIView()
        view.addSubview(subButtonView)
        subButtonView.anchor(top: subTextView.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 35, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        subButtonView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        view.addSubview(monthlySubButton)
        monthlySubButton.anchor(top: subButtonView.topAnchor, left: subButtonView.leftAnchor, bottom: subButtonView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 150, height: 200)
        monthlySubButton.addTarget(self, action: #selector(didTapMonthlySub), for: .touchUpInside)
        monthlySubButton.isUserInteractionEnabled = true

        view.addSubview(AnnualSubButton)
        AnnualSubButton.anchor(top: subButtonView.topAnchor, left: monthlySubButton.rightAnchor, bottom: subButtonView.bottomAnchor, right: subButtonView.rightAnchor, paddingTop: 0, paddingLeft: 40, paddingBottom: 0, paddingRight: 0, width: 150, height: 200)
        AnnualSubButton.addTarget(self, action: #selector(didTapAnnualSub), for: .touchUpInside)
        AnnualSubButton.isUserInteractionEnabled = true
        
        
        let typeColor = UIColor.ianBlackColor()
        let typeFont = UIFont(font: .arialRoundedMTBold, size: 20)
        let priceColor = UIColor.gray
        let priceFont = UIFont(font: .avenirMedium, size: 16)
        
        // Post Count Label
        var attributedMetric = NSMutableAttributedString(string: "Monthly\nSubscription", attributes: [NSAttributedString.Key.foregroundColor: typeColor, NSAttributedString.Key.font: typeFont])

        var attributedLabel = NSMutableAttributedString(string: "\n$0.49 / Month", attributes: [NSAttributedString.Key.foregroundColor: priceColor, NSAttributedString.Key.font: priceFont])
        
        attributedMetric.append(attributedLabel)
        self.monthlySubButton.setAttributedTitle(attributedMetric, for: .normal)
        self.monthlySubButton.contentHorizontalAlignment = .center
        
        
        // Post Count Label
        attributedMetric = NSMutableAttributedString(string: "Annual\nSubscription", attributes: [NSAttributedString.Key.foregroundColor: typeColor, NSAttributedString.Key.font: typeFont])

        attributedLabel = NSMutableAttributedString(string: "\n$4.49 / Year", attributes: [NSAttributedString.Key.foregroundColor: priceColor, NSAttributedString.Key.font: priceFont])
        
        attributedMetric.append(attributedLabel)
        self.AnnualSubButton.setAttributedTitle(attributedMetric, for: .normal)
        self.AnnualSubButton.contentHorizontalAlignment = .center
        // Do any additional setup after loading the view.
    }
    
    @objc func didTapMonthlySub() {
        self.alert(title: "Monthly Sub", message: "Success")
    }
    
    @objc func didTapAnnualSub() {
        self.alert(title: "Annual Sub", message: "Success")
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
