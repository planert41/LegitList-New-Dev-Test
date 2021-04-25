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


class NewUserWelcomeView: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, BounceSelectCellDelegate {

    
    
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
    "😘 Emojis - Tag your posts with Emojis, so that they are searchable by food 🌯, cuisine 🇲🇾, taste 🌶 or even diets 🕍. Express how 🔥 the food is beyond just 5 stars"
    ]
    var selectedMethod = 0 {
        didSet{
            displayMethod()
        }
    }
    
    let methodDisplay: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.layer.masksToBounds = true
        //        label.font = UIFont(name: "Poppins-Regular", size: 18)
        label.textColor = UIColor.ianLegitColor()
        label.backgroundColor = UIColor.clear
        label.font = UIFont(name: "Poppins-Bold", size: 17)
        label.text = "We do things a little differently. Here's how:"
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
        
        button.addTarget(self, action: #selector(addList), for: .touchUpInside)
        return button
    } ()
    
    
    func addList(){
        let listView = UserWelcome2View()
        self.navigationController?.pushViewController(listView, animated: true)
//        self.navigationController?.present(listView, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
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
        addListButton.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 40, paddingBottom: 30, paddingRight: 40, width: 0, height: 50)
        addListButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        addListButton.sizeToFit()
        
//        setupNavigationItems()
        self.view.addSubview(welcomeLabel)
        welcomeLabel.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        welcomeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        welcomeLabel.sizeToFit()
        
        self.view.addSubview(missionLabel)
        missionLabel.anchor(top: welcomeLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        missionLabel.sizeToFit()

    // TOP TEXT
        
        self.view.addSubview(believeHeader1)
        believeHeader1.anchor(top: missionLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 20, paddingBottom: 10, paddingRight: 20, width: 0, height: 0)
        believeHeader1.sizeToFit()

        
        self.view.addSubview(believeTextView)
        believeTextView.anchor(top: believeHeader1.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 20, paddingRight: 20, width: 0, height: 0)
        believeTextView.sizeToFit()

        if UIScreen.main.bounds.height > 750 {
            self.believeTextView.font = UIFont(font: .avenirNextMedium, size: 17)
        } else {
            self.believeTextView.font = UIFont(font: .avenirNextMedium, size: 15)
        }
        
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
