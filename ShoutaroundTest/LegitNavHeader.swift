//
//  LegitTestView.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/16/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit
import Foundation
import EmptyDataSet_Swift
import Kingfisher
import SVProgressHUD
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth

import CoreLocation

private let reuseIdentifier = "Cell"

protocol LegitNavHeaderDelegate {
    func headerSortSelected(sort: String)
    func toggleFeedType()
    func didTapNotification()
    func feedTypeSelected(type: String)
    func userFeedSelected(user: User)
    func userFeedSelected(list: List)
    func goToUser(uid: String?)
    func goToList(listId: String?)

}


class LegitNavHeader: UIView {

    var delegate: LegitNavHeaderDelegate?
    
    var sortDictionary: [String: String] = [
        sortNearest: "📍 NEARBY",
        sortNew: "⏰ LATEST",
        sortTrending: "🔥 TRENDING"
    ]
    var sortSegmentControl = UISegmentedControl()

    var viewFilter: Filter = Filter.init(defaultSort: defaultRecentSort) {
        didSet {
//            self.refreshNavSort()
            self.refreshSegmentValues()
        }
    }
    
    var fetchTypeInd: String = HomeFetchDefault {
        didSet{
            self.refresNavFeedTypeLabel()
        }
    }
    
    var fetchUser: User? = nil

    
    func refresNavFeedTypeLabel(){
        if self.fetchTypeInd == HomeFetchOptions[3] && self.fetchUser != nil
        {
            self.navFeedTypeLabel.text = self.fetchUser?.username
        } else {
            self.navFeedTypeLabel.text = self.fetchTypeInd
        }
    }
    
    lazy var navSortLabel: UILabel = {
        let ul = UILabel()
        ul.isUserInteractionEnabled = true
        ul.numberOfLines = 0
        ul.textAlignment = NSTextAlignment.left
        return ul
    }()
    
    lazy var navFeedTypeLabel: UILabel = {
        let ul = UILabel()
        ul.isUserInteractionEnabled = true
        ul.numberOfLines = 0
        ul.textAlignment = NSTextAlignment.left
        ul.font = UIFont(name: "Poppins-Bold", size: 38)
        ul.textColor = UIColor.ianBlackColor()
        return ul
    }()
    
    lazy var navFeedTypeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "dropdownXLarge").withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.tintColor = UIColor.ianBlackColor()
        button.addTarget(self, action: #selector(toggleNavFeedType), for: .touchUpInside)
        return button
    }()
    
    
    @objc func toggleNavFeedType(){
        self.delegate?.toggleFeedType()
    }
    
    lazy var navNotificationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "alert").withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.tintColor = UIColor.ianBlackColor()
        button.addTarget(self, action: #selector(toggleNavFeedType), for: .touchUpInside)
        return button
    }()
    
    lazy var navNotificationLabel: UILabel = {
        let ul = UILabel()
        ul.isUserInteractionEnabled = true
        ul.font = UIFont.boldSystemFont(ofSize: 14)
        ul.numberOfLines = 1
        ul.textAlignment = NSTextAlignment.center
        ul.backgroundColor = UIColor.backgroundGrayColor()
        ul.layer.cornerRadius = 1
        ul.layer.masksToBounds = true
        return ul
    }()
    

    
    
//    var navSearchButton: UIButton = TemplateObjects.NavSearchButton()
//    var navGridButton: UIButton = TemplateObjects.NavGridButton()
//    var navMapButton: UIButton = TemplateObjects.NavBarMapButton()
//
//    var isGridView = false {
//        didSet {
//            var image = isGridView ? #imageLiteral(resourceName: "grid") : #imageLiteral(resourceName: "listFormat")
//            self.navGridButton.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
//            self.navGridButton.setTitle(isGridView ? "GRID" : "LIST", for: .normal)
//        }
//    }
//
//    var displayedEmojis: [String] = [] {
//        didSet {
//            print("LegitHomeHeader | \(displayedEmojis.count) Emojis")
//            self.emojiCollectionView.reloadData()
//        }
//    }
//
    let dropdownCollectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        cv.layer.borderWidth = 0
        cv.backgroundColor = UIColor.white
        return cv
    }()
//
    
    let searchUserView = UserSearchViewController()
    var showUserSearchConstraint:NSLayoutConstraint?
    var hideUserSearchConstraint:NSLayoutConstraint?

    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
//        self.backgroundColor = UIColor.init(red: 34, green: 34, blue: 34, alpha: 0.2)
        self.backgroundColor = UIColor.clear
        
        let backView = UIView()
        addSubview(backView)
        backView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        backView.alpha = 0.4
        backView.backgroundColor = UIColor.init(red: 34, green: 34, blue: 34, alpha: 0.4)
        backView.isUserInteractionEnabled = true
        backView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleNavFeedType)))

//        self.backgroundColor = UIColor.white

        let headerView = UIView()
        addSubview(headerView)
        headerView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30 + UIApplication.shared.statusBarFrame.height + 20)
        headerView.backgroundColor = UIColor.white
        headerView.alpha = 1
        
        
        setupSegmentControl()
        headerView.addSubview(sortSegmentControl)
        sortSegmentControl.anchor(top: nil, left: headerView.leftAnchor, bottom: headerView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        sortSegmentControl.isUserInteractionEnabled = false
        
//        headerView.addSubview(navSortLabel)
//        navSortLabel.anchor(top: nil, left: headerView.leftAnchor, bottom: headerView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
//        navSortLabel.isUserInteractionEnabled = true
//        navSortLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleSort)))
        
        headerView.addSubview(navNotificationButton)
        navNotificationButton.anchor(top: nil, left: nil, bottom: nil, right: headerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 20, width: 20, height: 20)
        navNotificationButton.centerYAnchor.constraint(equalTo: sortSegmentControl.centerYAnchor).isActive = true
//        navNotificationButton.addTarget(self, action: #selector(didTapNotification), for: .touchUpInside)
        
        headerView.addSubview(navNotificationLabel)
        navNotificationLabel.anchor(top: nil, left: nil, bottom: nil, right: navNotificationButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 4, width: 0, height: 0)
        navNotificationLabel.centerYAnchor.constraint(equalTo: sortSegmentControl.centerYAnchor).isActive = true
//        navNotificationLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapNotification)))
        setupNavNotification()
        
        // 110 + Feed Type
        let navFeedTypeView = UIView()
        addSubview(navFeedTypeView)
        navFeedTypeView.anchor(top: headerView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 60)
        navFeedTypeView.isUserInteractionEnabled = true
        navFeedTypeView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleNavFeedType)))
        
        navFeedTypeView.addSubview(navFeedTypeButton)
        navFeedTypeButton.anchor(top: nil, left: nil, bottom: nil, right: navFeedTypeView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 20, width: 30, height: 30)
        navFeedTypeButton.centerYAnchor.constraint(equalTo: navFeedTypeView.centerYAnchor).isActive = true
        navFeedTypeButton.addTarget(self, action: #selector(toggleNavFeedType), for: .touchUpInside)

        
        navFeedTypeView.addSubview(navFeedTypeLabel)
        navFeedTypeLabel.anchor(top: nil, left: navFeedTypeView.leftAnchor, bottom: nil, right: navFeedTypeButton.leftAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 8, paddingRight: 10, width: 0, height: 0)
        navFeedTypeLabel.centerYAnchor.constraint(equalTo: navFeedTypeView.centerYAnchor).isActive = true
        navFeedTypeLabel.isUserInteractionEnabled = true
        navFeedTypeLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleNavFeedType)))
        
        self.refresNavFeedTypeLabel()
        
        // 120 + BottomDiv
        let navFeedTypeDiv = UIView()
        navFeedTypeDiv.backgroundColor = UIColor.ianBlackColor()
        addSubview(navFeedTypeDiv)
        navFeedTypeDiv.anchor(top: navFeedTypeView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 4, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 6)
        
        setupDropDownCollectionView()
        addSubview(dropdownCollectionView)
        dropdownCollectionView.anchor(top: navFeedTypeDiv.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 180)
        dropdownCollectionView.reloadData()
        
        addSubview(searchUserView.view)
        searchUserView.delegate = self
        searchUserView.view.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        hideUserSearchConstraint = searchUserView.view.topAnchor.constraint(equalTo: dropdownCollectionView.bottomAnchor)
        showUserSearchConstraint = searchUserView.view.topAnchor.constraint(equalTo: topAnchor, constant: 30)
        hideUserSearchConstraint?.isActive = true
        dropdownCollectionView.delegate = self
        

        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes

        // Do any additional setup after loading the view.
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let listCellId = "listCellId"
    
    func setupDropDownCollectionView(){
        dropdownCollectionView.register(LegitFeedTypeCell.self, forCellWithReuseIdentifier: listCellId)
        dropdownCollectionView.backgroundColor = UIColor.clear
//        dropdownCollectionView.backgroundColor = UIColor.yellow
        dropdownCollectionView.delegate = self
        dropdownCollectionView.dataSource = self
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = CGSize(width: self.frame.width, height: 90)
        dropdownCollectionView.collectionViewLayout = layout
        
    }
    
    func setupNavNotification(){
        let unread = CurrentUser.unreadEventCount
        navNotificationLabel.text = String(unread)
        navNotificationLabel.sizeToFit()
        navNotificationLabel.isHidden = (unread == 0)
    }
    
    func didTapNotification(){
        self.delegate?.didTapNotification()
    }

    func toggleSort(){
        self.delegate?.toggleFeedType()
    }
    
//    func refreshNavSort(){
//        let sort = self.viewFilter.filterSort ?? defaultRecentSort
//        let sortString = sortDictionary[sort] ?? ""
//
//        var attributedHeaderTitle = NSMutableAttributedString(string: sortString, attributes: [
//            .font: UIFont.systemFont(ofSize: 14.0, weight: .bold),
//            .foregroundColor: UIColor.ianLegitColor()
//            ])
//
//        attributedHeaderTitle.append(NSMutableAttributedString(string: " IN", attributes: [
//            .font: UIFont.systemFont(ofSize: 14.0, weight: .bold),
//            .foregroundColor: UIColor.ianBlackColor()
//            ]))
//
//        if self.navSortLabel.attributedText != attributedHeaderTitle {
//            UIView.transition(with: navSortLabel,
//                              duration: 0.5,
//                              options: [.transitionFlipFromBottom],
//                              animations: {
//
//                                self.navSortLabel.attributedText = attributedHeaderTitle
//                                self.navSortLabel.sizeToFit()
//
//            },
//                              completion: nil)
//        }
//
//
//    }
    
    func feedTypeSelected(type: String) {
        self.delegate?.feedTypeSelected(type: type)
    }



}

extension LegitNavHeader: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        var isSelected = (fetchTypeInd == HomeFetchOptions[indexPath.row])
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: listCellId, for: indexPath) as! LegitFeedTypeCell
        cell.mainText = HomeFetchOptions[indexPath.row]
        
        if indexPath.row == 2 {
            cell.subText = "\((CurrentUser.username)!) Posts"
        } else {
            cell.subText = HomeFetchDetails[indexPath.row]
        }

        

        cell.mainLabel.alpha = isSelected ? 0.2 : 1
        cell.subLabel.alpha = isSelected ? 0.2 : 1

//        cell.mainLabel.textColor = isSelected ? UIColor.mainBlue() : UIColor.ianBlackColor()
//        cell.subLabel.textColor = isSelected ? UIColor.mainBlue() : UIColor.ianBlackColor()

        
        print(" \(indexPath.row) | \(cell.mainText) | \(cell.subText)")
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.frame.width, height: 90)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.feedTypeSelected(type: HomeFetchOptions[indexPath.row])
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    
    
}

extension LegitNavHeader {
        func setupSegmentControl() {
            sortSegmentControl = UISegmentedControl(items: HeaderSortOptions)
//            sortSegmentControl.addTarget(self, action: #selector(selectSort), for: .valueChanged)
    //        sortSegmentControl.setBackgroundImage(UIImage(), for: .normal, barMetrics: .default)
    //        sortSegmentControl.setBackgroundImage(UIImage(color: UIColor.white), for: .normal, barMetrics: .default)
            sortSegmentControl.backgroundColor = UIColor.white

            if #available(iOS 13.0, *) {
                sortSegmentControl.selectedSegmentTintColor = UIColor.ianBlackColor()
            }

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            
            sortSegmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianGrayColor(), NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
            sortSegmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)
            self.refreshSegmentValues()


        }
    func refreshSegmentValues() {
        if let curIndex = HeaderSortOptions.firstIndex(of: self.viewFilter.filterSort!)
        {
            sortSegmentControl.selectedSegmentIndex = curIndex
        }
        
        for (index, sortOptions) in HeaderSortOptions.enumerated()
        {
            if sortOptions == self.viewFilter.filterSort
            {
                let newTitle = sortDictionary[sortOptions]
                self.sortSegmentControl.setTitle(newTitle, forSegmentAt: index)
            } else {
                self.sortSegmentControl.setTitle(sortOptions, forSegmentAt: index)

            }
        }
    }
    
    
}

extension LegitNavHeader: UserSearchViewControllerDelegate {
    func showSearchResults() {
        self.hideUserSearchConstraint?.isActive = false
        self.showUserSearchConstraint?.isActive = true
        self.searchUserView.showUserSearch = true

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveLinear, animations: {

            self.layoutIfNeeded()
        }) { (finished) in
            // SHOW RESULTS AFTER MOVE
            print("showSearchResults")
        }

    }
        
    func hideSearchResults() {
        self.showUserSearchConstraint?.isActive = false
        self.hideUserSearchConstraint?.isActive = true
        self.searchUserView.showUserSearch = false
        // HIDE RESULTS BEFORE MOVE

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveLinear, animations: {

            self.layoutIfNeeded()
        }) { (finished) in
            print("hideSearchResults")

        }
    }
    
    func userFeedSelected(user: User){
        self.delegate?.userFeedSelected(user: user)
    }
    
}
    

