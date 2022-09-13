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
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth
import SVProgressHUD


class NewUserOnboardViewFollowing: UIViewController {

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
            self.allUsers = self.teamUsers.sorted(by: { u1, u2 in
                return u1.posts_created > u2.posts_created
            })
            self.filteredUsers = self.teamUsers
            self.tableView.reloadData()
        }
    }
    
    
    
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
        self.dismiss(animated: true) {
//            NotificationCenter.default.post(name: MainTabBarController.showNearbyUsers, object: nil)
        }//        let listView = UserWelcome2View()
//        let listView = NewUserOnboardView4()
//        self.navigationController?.pushViewController(listView, animated: true)
        //        self.navigationController?.present(listView, animated: true, completion: nil)
    }
    
    @objc func discoverNearbyUsers(){
        self.dismiss(animated: true) {
            NotificationCenter.default.post(name: MainTabBarController.showNearbyUsers, object: nil)

        }//        let listView = UserWelcome2View()
//        let listView = NewUserOnboardView4()
//        self.navigationController?.pushViewController(listView, animated: true)
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
        img.image = #imageLiteral(resourceName: "Example_list").withRenderingMode(.alwaysOriginal)
        img.contentMode = .scaleAspectFit
        img.alpha = 1
        return img
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
    To start off, we recommend new Legit users follow the Legit team for content based in Chicago, Austin, Denver and Kuala Lumpur.
    """

//    No more endlessly scrolling through your photos to find a specific food picture
//    No more forgetting the name of that awesome restaurant from 3 years ago
//    Remember all the food you tried on your last trip and share your recommendations
//    Tap into the secret treasure trove of good food on your phone and share them with your friends.

        
    let nextButton: UIButton = {
        let button = UIButton()
        button.setTitle("Welcome!", for: .normal)

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
    
    let discoverUserButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.textColor = UIColor.white
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.setTitle("Discover Users Nearby", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.ianLegitColor()
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.ianLegitColor().cgColor
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        button.layer.cornerRadius = 10
        button.titleLabel?.textAlignment = NSTextAlignment.center
        
        button.addTarget(self, action: #selector(discoverNearbyUsers), for: .touchUpInside)
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
        
        button.addTarget(self, action: #selector(handleTransitionBack), for: .touchUpInside)
        return button
    } ()
    
    
    @objc func handleBackButton(){

        let transition = CATransition()
        transition.duration = 0.5
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromLeft
        transition.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
        view.window!.layer.add(transition, forKey: kCATransition)
        let welcomeView = NewUserOnboardView3()
        self.navigationController?.pushViewController(welcomeView, animated: true)
        print("handleBack")

    }
    
    var LegitImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.image = #imageLiteral(resourceName: "Legit_Vector").withRenderingMode(.alwaysOriginal)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    lazy var tableView : UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        tv.estimatedRowHeight = 100
        tv.allowsMultipleSelection = false
        return tv
    }()
    
    var searchBar = UISearchBar()
    

    
    var sortSegmentControl: UISegmentedControl = UISegmentedControl(items: ItemSortOptions)
    var segmentWidth_selected: CGFloat = 110.0
    var segmentWidth_unselected: CGFloat = 80.0
    var defaultWidth: CGFloat  = 828.0
    var scalar: CGFloat = 1.0
    
    let headerLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.backgroundColor = UIColor.clear
//        label.font = UIFont(font: .avenirBlack, size: 30)
        label.font = UIFont(name: "Poppins-Bold", size: 30)
        label.text = "Welcome!"
        label.textColor = UIColor.ianLegitColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping

        return label
    }()
    
    var selectedSort: String = DiscoverSortDefault {
        didSet{
            self.sortItems()
        }
    }
    
    var isFiltering: Bool = false {
        didSet{
            self.tableView.reloadData()
        }
    }

    
    var newCellId = "newCellId"

    var allUsers: [User] = []
    var filteredUsers: [User] = []
    
    override func viewDidLoad() {
        self.fetchUserInfo()
        
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
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleBack))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleNext))
        self.view.addGestureRecognizer(tapGesture)
        
//        view.addSubview(nextButton)
//        nextButton.anchor(top: nil, left: nil, bottom: view.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 50 * marginScale, paddingBottom: 50 * marginScale, paddingRight: 50 * marginScale, width: 250, height: 50 * marginScale)
//        nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        nextButton.sizeToFit()
        
        view.addSubview(discoverUserButton)
//        discoverUserButton.anchor(top: nil, left: nil, bottom: nextButton.topAnchor, right: nil, paddingTop: 0, paddingLeft: 50 * marginScale, paddingBottom: 10, paddingRight: 50 * marginScale, width: 250, height: 50 * marginScale)
        discoverUserButton.anchor(top: nil, left: nil, bottom: view.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 50 * marginScale, paddingBottom: 50 * marginScale, paddingRight: 50 * marginScale, width: 250, height: 50 * marginScale)
        discoverUserButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        discoverUserButton.sizeToFit()
        
        
//        view.addSubview(backButton)
//        backButton.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 30 * marginScale, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        backButton.centerYAnchor.constraint(equalTo: nextButton.centerYAnchor).isActive = true
//        backButton.sizeToFit()
//        backButton.isHidden = true

        
        view.addSubview(headerLabel)
        headerLabel.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 50, paddingLeft: 25, paddingBottom: 15, paddingRight: 25, width: 0, height: 60)
        headerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
                
        
        view.addSubview(infoTextView)
        infoTextView.anchor(top: headerLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 30 * marginScale, paddingLeft: sideMargin, paddingBottom: 20 * marginScale, paddingRight: sideMargin, width: 0, height: 0)
//        infoTextView.bottomAnchor.constraint(lessThanOrEqualTo: nextButton.topAnchor, constant: 10).isActive = true
        infoTextView.text = infoText
        infoTextView.font = UIFont(font: .avenirNextBold, size: 20 * marginScale)
        infoTextView.textColor = UIColor.darkGray
        infoTextView.sizeToFit()
        
//        view.addSubview(searchBar)
//        searchBar.anchor(top: (infoTextView).bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 15 * marginScale, paddingLeft: sideMargin, paddingBottom: 20 * marginScale, paddingRight: sideMargin, width: 0, height: 35)
//        setupSearchBar()
        
        view.addSubview(tableView)
        tableView.anchor(top: (infoTextView).bottomAnchor, left: view.leftAnchor, bottom: discoverUserButton.topAnchor, right: view.rightAnchor, paddingTop: 15 * marginScale, paddingLeft: sideMargin, paddingBottom: 20 * marginScale, paddingRight: sideMargin, width: 0, height: 0)
        setupTableView()
        
        setupSegmentControl()
        view.addSubview(sortSegmentControl)
        sortSegmentControl.anchor(top: nil, left: nil, bottom: tableView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 10, width: 0, height: 40)
        sortSegmentControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        sortSegmentControl.alpha = 0.9
        sortSegmentControl.isHidden = true

//        sortSegmentControl.rightAnchor.constraint(lessThanOrEqualTo: navMapButton.leftAnchor, constant: 15).isActive = true

//        sortSegmentControl.centerXAnchor.constraint(equalTo: barView.centerXAnchor).isActive = true
        self.refreshSort(sender: sortSegmentControl)


        self.view.bringSubviewToFront(nextButton)
        
    }
    
    func setupSegmentControl() {
        sortSegmentControl = UISegmentedControl(items: ItemSortOptions)
        sortSegmentControl.selectedSegmentIndex = 0
        sortSegmentControl.addTarget(self, action: #selector(selectItemSort), for: .valueChanged)
        sortSegmentControl.backgroundColor = UIColor.white
        sortSegmentControl.tintColor = UIColor.oldLegitColor()
        sortSegmentControl.layer.borderWidth = 1
        if #available(iOS 13.0, *) {
            sortSegmentControl.selectedSegmentTintColor = UIColor.mainBlue()
        }
        
        sortSegmentControl.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 14), NSAttributedString.Key.foregroundColor: UIColor.gray], for: .normal)
        sortSegmentControl.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 13), NSAttributedString.Key.foregroundColor: UIColor.ianWhiteColor()], for: .selected)
    }
    
    @objc func selectItemSort(sender: UISegmentedControl) {
        let selectedSort = ItemSortOptions[sender.selectedSegmentIndex]
        print("DiscoverItemHeader | \(selectedSort) | selectItemSort")

        self.refreshSort(sender: sender)
        self.selectedSort = selectedSort
    }
    
    @objc func refreshSort(sender: UISegmentedControl) {
        let selectedSort = ItemSortOptions[sender.selectedSegmentIndex]
        
        for (index, sortOptions) in ItemSortOptions.enumerated()
        {
            var isSelected = (index == sender.selectedSegmentIndex)
            var displayFilter = (isSelected) ? "Sort \(sortOptions)" : sortOptions
            sender.setTitle(displayFilter, forSegmentAt: index)
            sender.setWidth((isSelected) ? 90 : 60, forSegmentAt: index)
        }
    }
    
    func setupTableView(){
        tableView.register(SearchResultsCell.self, forCellReuseIdentifier: searchResultCellId)
        tableView.register(UserAndListCell.self, forCellReuseIdentifier: newCellId)

//        let refreshControl = UIRefreshControl()
//        refreshControl.addTarget(self, action: #selector(refreshAll), for: .valueChanged)
//        tableView.refreshControl = refreshControl
        tableView.alwaysBounceVertical = true
        tableView.keyboardDismissMode = .onDrag
        tableView.allowsSelection = false
        tableView.delegate = self

    }
    
    let listCellId = "ListCellId"
    let userCellId = "UserCellId"
    let searchResultCellId = "searchResultCellId"
    
    func setupSearchBar() {
        searchBar.sizeToFit()
        searchBar.delegate = self
//        searchBar.showsCancelButton = false
        
        searchBar.barTintColor = UIColor.white
        searchBar.tintColor = UIColor.ianLegitColor()
        searchBar.backgroundColor = UIColor.clear
        searchBar.backgroundImage = UIImage()
        searchBar.layer.borderWidth = 0
        definesPresentationContext = false
        
        searchBar.layer.cornerRadius = 5
        searchBar.layer.masksToBounds = true
        searchBar.clipsToBounds = true
        searchBar.searchBarStyle = .default
//        searchBar.searchBarStyle = .prominent
        searchBar.isTranslucent = false
        
//        searchBar.layer.borderWidth = 1
//        searchBar.layer.borderColor = UIColor.lightGray.cgColor
        searchBar.placeholder = "Search Users"
        //        defaultSearchBar.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        //        defaultSearchBar.showsCancelButton = true
        

        var iconImage = #imageLiteral(resourceName: "search_tab_fill").withRenderingMode(.alwaysTemplate)
        searchBar.setImage(iconImage, for: .search, state: .normal)
        searchBar.setSerchTextcolor(color: UIColor.ianLegitColor())
        var searchTextField: UITextField? = searchBar.value(forKey: "searchField") as? UITextField
        if searchTextField!.responds(to: #selector(getter: UITextField.attributedPlaceholder)) {
            let attributeDict = [NSAttributedString.Key.foregroundColor: UIColor.gray]
            let searchPlaceHolder = "Search Users"
            searchTextField!.attributedPlaceholder = NSAttributedString(string: searchPlaceHolder, attributes: attributeDict)
        }
        
        let textFieldInsideUISearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.textColor = UIColor.ianLegitColor()
        //        textFieldInsideUISearchBar?.font = textFieldInsideUISearchBar?.font?.withSize(12)

        
        for s in searchBar.subviews[0].subviews {
            if s is UITextField {
                s.layer.borderWidth = 0.5
                s.layer.borderColor = UIColor.gray.cgColor
                s.layer.cornerRadius = 5
                s.clipsToBounds = true
                s.layer.backgroundColor = UIColor.clear.cgColor
                s.backgroundColor = UIColor.white
            }
        }
        
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

extension NewUserOnboardViewFollowing: UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UserAndListCellDelegate {
    
    func fetchAllItems() {
        if allUsersFetched.count == 0  {
            SVProgressHUD.show(withStatus: "Fetching Users")
            Database.fetchALLUsers { (users) in
                self.allUsers = users
                self.filteredUsers = users
                self.filterUsers()
                print("Fetched \(self.allUsers.count) Users | Fetch All Items - TabSearchViewController")
            }
        } else {
            self.allUsers = allUsersFetched
            self.filteredUsers = allUsersFetched
            self.filterUsers()
        }
    }

    
    func sortItems() {
        Database.sortUsers(inputUsers: self.isFiltering ? self.filteredUsers : self.allUsers, selectedSort: self.selectedSort, selectedLocation: nil) { (sortedUsers) in
            if self.isFiltering {
                self.filteredUsers = sortedUsers ?? []
            } else {
                self.allUsers = sortedUsers ?? []
            }
            self.tableView.refreshControl?.endRefreshing()
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(0, self.isFiltering ? self.filteredUsers.count : self.allUsers.count)
    }
    
    //    var TabSearchOptions:[String] = [DiscoverUser, DiscoverList, DiscoverPlaces, DiscoverCities]

//    tableView.register(SearchResultsCell.self, forCellReuseIdentifier: searchResultCellId)
//    tableView.register(UserAndListCell.self, forCellReuseIdentifier: newCellId)
    
//    func returnEmptyCell() -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: searchResultCellId, for: IndexPath(row: 0, section: 0)) as! SearchResultsCell
//        cell.emojiTextLabel.textAlignment = .center
//        cell.locationName = "No Results Available"
//        cell.selectionStyle = .none
//        cell.postCountLabel.isHidden = true
//        return cell
//    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        SVProgressHUD.dismiss()
        let cell = tableView.dequeueReusableCell(withIdentifier: newCellId, for: indexPath) as! UserAndListCell
        cell.cellType = DiscoverUser
        cell.delegate = self
        cell.contentView.isUserInteractionEnabled = false
        
        let currentUser = isFiltering ? filteredUsers[indexPath.row] : allUsers[indexPath.row]
        cell.user = currentUser
        cell.selectionStyle = .none
        cell.cellHeight?.constant = 80
        return cell

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let currentUser = isFiltering ? filteredUsers[indexPath.row] : allUsers[indexPath.row]
        self.extTapUser(userId: currentUser.uid)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
////        return 300
//        if self.fetchType == DiscoverList {
//            return 200
//        } else if self.fetchType == DiscoverUser {
//            return 70 + 90
//        } else {
//            return 0
//        }
        
        return 80

    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText.count == 0) {
            self.isFiltering = false
            self.tableView.reloadData()
        } else {
            filterContentForSearchText(searchBar.text!)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        let searchText = searchBar.text ?? ""
        if (searchText.count == 0) {
            self.isFiltering = false
            self.tableView.reloadData()
        } else {
            filterContentForSearchText(searchBar.text!)
        }
    }
    
    @objc func filterContentForSearchText(_ searchText: String) {
        self.isFiltering = searchText.count != 0
        self.filterUsers()

    }
    
    func filterUsers() {
        guard let searchText = searchBar.text else {
            self.isFiltering = false
            self.filteredUsers = self.allUsers
            self.sortItems()
            return
        }
        
        self.isFiltering = searchText.count != 0
        
        let searchTerms = searchText.lowercased().components(separatedBy: " ")
        
        self.filteredUsers = allUsers.filter({ (user) -> Bool in
            var emojiTranslateArray: [String] = []
            var emojiFilter = false

            return user.username.lowercased().contains(searchText.lowercased())
        })
        
        filteredUsers.sort { (p1, p2) -> Bool in
            ((p1.username.hasPrefix(searchText.lowercased())) ? 0 : 1) < ((p2.username.hasPrefix(searchText.lowercased())) ? 0 : 1)
        }
        self.sortItems()
    }

    
    func goToLocation(location: Location?) {
        
    }
    
    func showCity(city: City) {
        
    }
    
}
