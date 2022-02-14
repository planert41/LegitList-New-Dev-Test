//
//  PostSearchController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/15/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
//
//  HomePostSearch.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/17/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import GooglePlaces
import SVProgressHUD


class LegitTeamView : UITableViewController {


    
    let UserCellId = "UserCellId"
    let ListCellId = "ListCellId"
    
    var teamUIDs = [UID_wei, UID_mayn, UID_zm, UID_magnus, UID_ernie]
    var teamUsers: [User] = []

    
    func fetchUserInfo() {
        SVProgressHUD.show(withStatus: "Fetching Users")

        self.teamUsers = []
        let myGroup = DispatchGroup()

        for uid in teamUIDs {
            myGroup.enter()
            Database.fetchUserWithUID(uid: uid) { (user) in
                if let user = user {
                    self.teamUsers.append(user)
                }
                myGroup.leave()
            }
        }
        
        myGroup.notify(queue: .main) {
            print("Legit Team - Fetched \(self.teamUsers.count) Users")
            SVProgressHUD.dismiss()
            self.tableView.reloadData()
        }
    }
    
    
    
    
    lazy var navBackButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 16)
//        button.setImage(#imageLiteral(resourceName: "dropdownXLarge").withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.tintColor = UIColor.lightGray
        return button
    }()
    
    // MARK: - VIEW DID LOAD
    
    let thankYouLabel: UILabel = {
        let label = UILabel()
        label.layer.borderColor = UIColor.clear.cgColor
        label.layer.borderWidth = 0
        label.backgroundColor = .white
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = UIFont(name: "Poppins-Bold", size: 25)
        label.textColor = .ianLegitColor()
        label.text = "Thank You For Your Support!"
//        label.isUserInteractionEnabled = true
//        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openNotifications)))
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        setupTableView()
        setupNavigationItems()
        fetchUserInfo()
        
        view.addSubview(thankYouLabel)
        thankYouLabel.anchor(top: nil, left: nil, bottom: bottomLayoutGuide.topAnchor, right: nil, paddingTop: 0, paddingLeft: 40, paddingBottom: 200, paddingRight: 40, width: 0, height: 0)
        thankYouLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

    }
    
        
    override func viewWillDisappear(_ animated: Bool) {
        //      Remove Searchbar scope during transition
//        self.searchBar.isHidden = true
        //        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.setupNavigationItems()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //      Show Searchbar scope during transition
        self.setupNavigationItems()
        self.tableView.reloadData()
        
        
    }
    
 
    
    @objc func handleBackPressNav(){
        self.handleDismiss()
    }
    

    func setupNavigationItems(){
        
    // Header

        
//        self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.ianLegitColor(), NSAttributedString.Key.font.rawValue: UIFont(name: "Poppins-Bold", size: 18)])
        var titleString = "Legit Team"

        let navLabel = UILabel()
        let customFont = UIFont(name: "Poppins-Bold", size: 18)
        let headerTitle = NSAttributedString(string:titleString, attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianWhiteColor(), NSAttributedString.Key.font: customFont])
        navLabel.attributedText = headerTitle
        self.navigationItem.titleView = navLabel
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.isTranslucent = false
        
        let navColor = UIColor.ianLegitColor()
        
        self.navigationController?.navigationBar.barTintColor = navColor
        let tempImage = UIImage.init(color: UIColor.ianLegitColor())
        navigationController?.navigationBar.setBackgroundImage(tempImage, for: .default)
        self.navigationController?.navigationBar.tintColor = UIColor.ianLegitColor()
        self.navigationController?.view.backgroundColor = UIColor.ianLegitColor()
        self.navigationController?.navigationBar.backgroundColor = navColor
        self.navigationController?.navigationBar.layer.shadowColor = navColor.cgColor
        self.navigationController?.navigationBar.layoutIfNeeded()


    // Nav Back Buttons
        
        navBackButton.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        navBackButton.setTitle("Back", for: .normal)
        let barButton2 = UIBarButtonItem.init(customView: navBackButton)
        self.navigationItem.leftBarButtonItem = barButton2
    }
    
}


extension LegitTeamView {
    
    func setupTableView(){
        tableView.backgroundColor = UIColor.white
        tableView.register(UserAndListCell.self, forCellReuseIdentifier: UserCellId)
        //        tableView.register(TestListCell.self, forCellReuseIdentifier: ListCellId)
        tableView.register(NewListCell.self, forCellReuseIdentifier: ListCellId)
        tableView.estimatedRowHeight = 200
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.alwaysBounceVertical = true
        tableView.separatorStyle = .none

        let adjustForTabbarInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
        tableView.contentInset = adjustForTabbarInsets
        tableView.scrollIndicatorInsets = adjustForTabbarInsets

    }
    

    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return teamUsers.count
    }
    
//    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 70 + 90 + 10
//    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        

        let cell = tableView.dequeueReusableCell(withIdentifier: UserCellId, for: indexPath) as! UserAndListCell
        cell.user = teamUsers[indexPath.item]
        cell.followButton.isHidden = Auth.auth().currentUser == nil
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var user = teamUsers[indexPath.item]
        self.userSelected(user: user)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func userSelected(user: User?) {
        guard let user = user else {return}
        print("USER SELECTED \(user.username)")
        self.extTapUser(userId: user.uid)
//        self.delegate?.userSelected(user: user)
//        self.dismiss(animated: true) {
//            print("UserListSearchView | User Selected | User: \(user.username)")
//        }
    }

    @objc func handleDismiss() {
        print("UserListSearchView | Dismiss")
        self.dismiss(animated: true) {
            print("Team View Dismiss")
        }
//        self.navigationController?.popViewController(animated: true)
    }
    
}
