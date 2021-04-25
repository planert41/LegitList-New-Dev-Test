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


class UserWelcome2View: UIViewController {
    
    let welcomeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = UIFont(name: "Poppins-Bold", size: 25)
        label.backgroundColor = UIColor.clear
        label.text = "Here's How We Do Things A Little Differently:"
        label.textColor = UIColor.ianLegitColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping

        return label
    }()
    
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
    
    let believeTextView: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.layer.masksToBounds = true
        //        label.font = UIFont(name: "Poppins-Regular", size: 18)
        label.textColor = UIColor.ianLegitColor()
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = UIFont(name: "Poppins-Bold", size: 17)
        label.text = """
        \n ● 🍔 Food - We focus on the food 🍕🌮🍜, not the restaurant
        \n ● 👌 Curation - Create a communal food 🧠 by following people you trust
        \n ● 📌 Geo-Lists - We organize your photos into geo-tagged lists that are mappable 🗺, searchable 🔍, and easy to share with friends 🙋‍♂️🙋‍♀️
        \n ● 📍 Location - Sort your feed by nearest distance to find the closest legit 👌 thing to eat
        \n ● 😍 Emojis - Tag your posts with Emojis, so that they are searchable by food 🌯, cuisine 🇲🇾, taste 🌶 or even diets 🕍. Express how 🔥 the food is beyond just 5 stars

        """
        label.textColor = UIColor.ianBlueColor()
        return label
    }()
    
    
    let addListButton: UIButton = {
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
        button.titleLabel?.textAlignment = NSTextAlignment.left
        
        button.addTarget(self, action: #selector(addList), for: .touchUpInside)
        return button
    } ()
    
    
    func addList(){
        let listView = NewUserWelcomeFollowViewController()
        self.navigationController?.pushViewController(listView, animated: true)
        //        self.navigationController?.present(listView, animated: true, completion: nil)
    }
    
    
    
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor.backgroundGrayColor()
        self.navigationController?.isNavigationBarHidden = true
        
        self.view.addSubview(addListButton)
        addListButton.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 40, paddingBottom: 30, paddingRight: 40, width: 0, height: 50)
        addListButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        addListButton.sizeToFit()
        
        
        //        setupNavigationItems()
        self.view.addSubview(welcomeLabel)
        welcomeLabel.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        //        welcomeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        welcomeLabel.sizeToFit()
        
        self.view.addSubview(believeTextView)
        believeTextView.anchor(top: welcomeLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        believeTextView.bottomAnchor.constraint(lessThanOrEqualTo: addListButton.topAnchor).isActive = true
        missionLabel.sizeToFit()
        
        believeTextView.isUserInteractionEnabled = true
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleBackPressNav))
        swipeRight.direction = .right
        self.believeTextView.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(addList))
        swipeLeft.direction = .left
        self.believeTextView.addGestureRecognizer(swipeLeft)
        
        setupText()
        
    }
    
    @objc func handleBackPressNav(){
        //        guard let post = self.selectedPost else {return}
        self.handleBack()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
    
    func setupText(){
        var displayString = NSMutableAttributedString()
        displayString.append(setupDetail(header: "Food", details: "It's ALL about the food instead of the restaurant. As long as the food tastes amazing, terrible service be damned!"))
        displayString.append(setupDetail(header: "\nLists", details: "Organize your photos by location, food type or travel experience. Make a list of your favorite 🍣 🍜 places from your Tokyo trip or 🍕 🌭 joints in Chicago"))
        displayString.append(setupDetail(header: "\nLocation ", details: "Every posts is tagged with a GPS location 📍. Sort your feed by nearest distance or display a list on a map by clicking on the button "))
            let imageSize = CGSize(width: 20, height: 20)
            let bookmarkImage = NSTextAttachment()

            let bookmarkIcon = #imageLiteral(resourceName: "map").withRenderingMode(.alwaysTemplate).resizeImageWith(newSize: imageSize)
            bookmarkImage.bounds = CGRect(x: 0, y: (believeTextView.font.capHeight - bookmarkIcon.size.height).rounded() / 2, width: bookmarkIcon.size.width, height: bookmarkIcon.size.height)
            bookmarkImage.image = bookmarkIcon

            let bookmarkImageString = NSAttributedString(attachment: bookmarkImage)
            displayString.append(bookmarkImageString)
        
        displayString.append(setupDetail(header: "\nEmojis 🌯 🇲🇾 🌶 ❌🍖", details: "Tag your posts with emojis by food, cuisine, taste and even diets. Express how 🔥 or 💩 the food was beyond 5 stars"))
//        displayString.append(setupDetail(header: "\n Curation", details: "Create a communal food 🧠 by following people you trust"))
        believeTextView.tintColor = UIColor.ianLegitColor()
        believeTextView.attributedText = displayString
        believeTextView.sizeToFit()

    }
    
    func setupDetail(header: String?, details: String?) -> NSMutableAttributedString {
        var headerText = header ?? ""
        var headerFont = UIFont(name: "Poppins-Bold", size: 18)
        var headerFontColor = UIColor.ianLegitColor()
        
        var detailText = details ?? ""
        var detailFont = UIFont(name: "Poppins-Regular", size: 16)
        var detailFontColor = UIColor.ianBlackColor()

        if UIScreen.main.bounds.height > 750 {
            headerFont = UIFont(name: "Poppins-Bold", size: 18)
            detailFont = UIFont(name: "Poppins-Regular", size: 16)
        } else {
            headerFont = UIFont(name: "Poppins-Bold", size: 17)
            detailFont = UIFont(name: "Poppins-Regular", size: 15)
        }
        
        
        
    
        let headerString = NSMutableAttributedString(string: "\n" + headerText, attributes: [NSAttributedString.Key.font: headerFont, NSAttributedString.Key.foregroundColor: headerFontColor])
        let detailString = NSMutableAttributedString(string: "\n" + detailText, attributes: [NSAttributedString.Key.font: detailFont, NSAttributedString.Key.foregroundColor: detailFontColor])

        let outputString = NSMutableAttributedString()
        outputString.append(headerString)
        outputString.append(detailString)
        
        return outputString

    }
    
    
    
}
