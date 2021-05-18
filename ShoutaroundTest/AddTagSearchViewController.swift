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

import GooglePlaces
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase

protocol AddTagSearchControllerDelegate {
    func additionalTagSelected(tags: [String])
}


class AddTagSearchController : UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {
    
    

    var delegate: AddTagSearchControllerDelegate?

    
    var selectedScope = 0 {
        didSet{
            self.tableView.reloadData()
        }
    }
    var isFiltering: Bool = false {
        didSet{
            self.tableView.reloadData()
        }
    }
    var enableScopeOptions: Bool = true
    lazy var tableView : UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        //        tv.estimatedRowHeight = 100
        tv.allowsMultipleSelection = false
        //        tv.contentInset = UIEdgeInsets(top: 20, left: 40, bottom: 20, right: 40)
        return tv
    }()
    
    var searchScopeButtons = ["All","Meal","Cuisine","Diet"]
    
    var selectedTags: [String] = [] {
        didSet {
            refreshTags()
        }
    }
    
    var mealTag:[EmojiBasic] = mealEmojis
    var cuisineTag:[EmojiBasic] = cuisineEmojis
    var dietTag:[EmojiBasic] = dietEmojis
    var allTag:[EmojiBasic] = mealEmojis + cuisineEmojis + dietEmojis

    
    var filteredTag:[EmojiBasic] = []
    
    func initTags(){
        mealTag = mealEmojis
        cuisineTag = cuisineEmojis
        dietTag = dietEmojis
        allTag = mealEmojis + cuisineEmojis + dietEmojis
        
        for tag in selectedTags.reversed() {
            if let index = allTag.firstIndex(where: {$0.name == tag}) {
                let temp = allTag.remove(at: index)
                allTag.insert(temp, at: 0)
            }
            
            if let index = mealTag.firstIndex(where: {$0.name == tag}) {
                let temp = mealTag.remove(at: index)
                mealTag.insert(temp, at: 0)
            }
            
            if let index = cuisineTag.firstIndex(where: {$0.name == tag}) {
                let temp = cuisineTag.remove(at: index)
                cuisineTag.insert(temp, at: 0)
            }
            
            if let index = dietTag.firstIndex(where: {$0.name == tag}) {
                let temp = dietTag.remove(at: index)
                dietTag.insert(temp, at: 0)
            }
        }

    }
    
    
    func refreshTags(){

        self.setupNavigationItems()
        self.tableView.reloadData()
    }
    
    let EmojiCellId = "EmojiCellId"
    
    let searchController = UISearchController(searchResultsController: nil)
    var searchBar = UISearchBar()
    
    
    var headerSortSegment = UISegmentedControl()
    var buttonBarPosition: NSLayoutConstraint?
    let buttonBar = UIView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        print("MainSearchController | LOAD")
        view.backgroundColor = UIColor.rgb(red: 241, green: 241, blue: 241)
        //        setupSearchController()
        setupSearchBar()
        setupNavigationItems()
        setupSegments()
        setupTableView()
        
        let searchBarView = UIView()
        searchBarView.backgroundColor = UIColor.white
        view.addSubview(searchBarView)
        searchBarView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        
        view.addSubview(searchBar)
        searchBar.anchor(top: searchBarView.topAnchor, left: searchBarView.leftAnchor, bottom: searchBarView.bottomAnchor, right: searchBarView.rightAnchor, paddingTop: 5, paddingLeft: 25, paddingBottom: 5, paddingRight: 25, width: 0, height: 0)
        
        let headerView = UIView()
        headerView.backgroundColor = UIColor.white
        view.addSubview(headerView)
        headerView.anchor(top: searchBarView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
        view.addSubview(headerSortSegment)
        headerSortSegment.anchor(top: headerView.topAnchor, left: headerView.leftAnchor, bottom: nil, right: headerView.rightAnchor, paddingTop: -1, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        
        let segmentWidth = (self.view.frame.width - 30 - 40) / 4
        
        //        let segmentWidth = self.headerSortSegment.frame.width / searchScopeButtons.count
        buttonBar.backgroundColor = UIColor.ianLegitColor()
        view.addSubview(buttonBar)
        buttonBar.anchor(top: headerSortSegment.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: segmentWidth, height: 5)
        buttonBar.leftAnchor.constraint(lessThanOrEqualTo: headerSortSegment.leftAnchor).isActive = true
        buttonBar.rightAnchor.constraint(lessThanOrEqualTo: headerSortSegment.rightAnchor).isActive = true
        buttonBarPosition = buttonBar.leftAnchor.constraint(equalTo: headerSortSegment.leftAnchor, constant: 5)
        buttonBarPosition?.isActive = true
        
        
        view.addSubview(tableView)
        tableView.anchor(top: headerSortSegment.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 20, paddingLeft: 30, paddingBottom: 0, paddingRight: 30, width: 0, height: 0)
        
        
    
    }
    
    func setupTableView(){
        
        tableView.backgroundColor = UIColor.rgb(red: 249, green: 249, blue: 249)
        tableView.register(SearchResultsCell.self, forCellReuseIdentifier: EmojiCellId)
        //        tableView.contentInset = UIEdgeInsets(top: 20, left: 40, bottom: 0, right: 40)
        
        tableView.allowsMultipleSelection = true
        // Google Locations are only loaded when Locations are selected

        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 160
        //        tableView.estimatedRowHeight = 200
        initTags()
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(increaseScope))
        swipeLeft.direction = .left
        self.tableView.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(decreaseScope))
        swipeRight.direction = .right
        self.tableView.addGestureRecognizer(swipeRight)
    }
    
    func setupSegments(){
        headerSortSegment = UISegmentedControl(items: searchScopeButtons)
        headerSortSegment.selectedSegmentIndex = self.selectedScope
        headerSortSegment.addTarget(self, action: #selector(selectSort), for: .valueChanged)
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        headerSortSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
        headerSortSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)
        
        headerSortSegment.backgroundColor = .white
        headerSortSegment.tintColor = .white
        
        // This needs to be false since we are using auto layout constraints
        //        headerSortSegment.translatesAutoresizingMaskIntoConstraints = false
        //        buttonBar.translatesAutoresizingMaskIntoConstraints = false
        //        headerSortSegment.apportionsSegmentWidthsByContent = true
    }
    
    func underlineSegment(segment: Int? = 0){
        
        let segmentWidth = (self.view.frame.width - 40) / CGFloat(self.headerSortSegment.numberOfSegments)
        let tempX = self.buttonBar.frame.origin.x
        UIView.animate(withDuration: 0.3) {
            //            self.buttonBarPosition?.isActive = false
            // Origin code lets bar slide
            self.buttonBar.frame.origin.x = segmentWidth * CGFloat(segment ?? 0) + 10
            self.buttonBarPosition?.constant = segmentWidth * CGFloat(segment ?? 0) + 10
            self.buttonBarPosition?.isActive = true
        }
    }
    
    @objc func selectSort(sender: UISegmentedControl) {
        self.selectedScope = sender.selectedSegmentIndex
        self.underlineSegment(segment: self.selectedScope)
        self.initTags()
        self.tableView.reloadData()
        print("Selected Scope is: ", self.searchScopeButtons[self.selectedScope], self.selectedScope)

    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        self.isFiltering = !(searchBar.text?.isEmpty)!
        filterContentForSearchText(searchBar.text!)
        
    }
    
    
    func setupNavigationItems(){
        
//        navigationController?.navigationBar.barTintColor = UIColor.white
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        // REMOVES THE 1PX BOTTOM LINE IN NAV BAR
        navigationController?.navigationBar.shadowImage = UIImage()
        
        let customFont = UIFont(name: "Poppins-Bold", size: 18)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: customFont]
        
        let count = (self.selectedTags.count == 0) ? "" : "\(self.selectedTags.count) "
        
        var selectedEmojis: [String] = []
        for x in self.selectedTags {
            if let emoji = ReverseEmojiDictionary[x] {
                selectedEmojis.append(emoji)
            }
        }
        
        self.navigationItem.title = (self.selectedTags.count == 0) ? "Categories" : "Categories \(selectedEmojis.joined())"

        //        self.navigationController?.navigationBar.layoutIfNeeded()
        
        // Nav Back Buttons
        let navBackButton = navBackButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        navBackButton.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
        navBackButton.setTitleColor(UIColor.white, for: .normal)
        navBackButton.tintColor = UIColor.white
        let navShareTitle = NSAttributedString(string: " BACK ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 12)])
        navBackButton.setAttributedTitle(navShareTitle, for: .normal)
        let barButton2 = UIBarButtonItem.init(customView: navBackButton)
        self.navigationItem.leftBarButtonItem = barButton2

        
        let navDoneButton = navButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        navDoneButton.setTitleColor(UIColor.white, for: .normal)
        navDoneButton.setTitle("Tag", for: .normal)
        navDoneButton.addTarget(self, action: #selector(handleDone), for: .touchUpInside)
        let barButtonDone = UIBarButtonItem.init(customView: navDoneButton)
        self.navigationItem.rightBarButtonItem = barButtonDone
        
    }
    
    
    func increaseScope(){
        self.changeScope(change: 1)
    }
    
    func decreaseScope(){
        self.changeScope(change: -1)
    }
    
    func changeScope(change: Int){
        self.selectedScope = min(max(0, self.selectedScope + change),(searchBar.scopeButtonTitles?.count)! - 1)
        self.searchBar.selectedScopeButtonIndex = self.selectedScope
    }
    
    func setupSearchBar(){
        searchBar.sizeToFit()
        searchBar.delegate = self
        searchBar.placeholder =  "Search Tags"
        searchBar.showsCancelButton = false
        searchController.searchBar.showsCancelButton = false
        
        searchBar.barTintColor = UIColor.white
        searchBar.tintColor = UIColor.white
        searchBar.backgroundColor = UIColor.white
        searchBar.searchBarStyle = .minimal
        searchBar.layer.borderWidth = 0
        definesPresentationContext = false
        
        let textFieldInsideUISearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.textColor = UIColor.ianLegitColor()
        //        textFieldInsideUISearchBar?.font = textFieldInsideUISearchBar?.font?.withSize(12)
        
        
        for s in searchBar.subviews[0].subviews {
            if s is UITextField {
                s.layer.borderWidth = 0.5
                s.layer.borderColor = UIColor.gray.cgColor
                s.layer.cornerRadius = 5
                s.clipsToBounds = true
                s.layer.backgroundColor = UIColor.white.cgColor
            }
        }
        
    }
    
    
    func setupSearchController(){
        //        navigationController?.navigationBar.barTintColor = UIColor.white
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchBar = searchController.searchBar
        
        searchBar.sizeToFit()
        searchBar.delegate = self
        searchBar.placeholder =  "Search Tags"
        searchBar.showsCancelButton = false
        searchController.searchBar.showsCancelButton = false
        
        searchBar.barTintColor = UIColor.white
        searchBar.tintColor = UIColor.white
        searchBar.backgroundColor = UIColor.white
        definesPresentationContext = true
        
        let textFieldInsideUISearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.textColor = UIColor.legitColor()
        //        textFieldInsideUISearchBar?.font = textFieldInsideUISearchBar?.font?.withSize(12)
        
        
        for s in searchBar.subviews[0].subviews {
            if s is UITextField {
                s.layer.borderWidth = 0.5
                s.layer.borderColor = UIColor.gray.cgColor
                s.layer.cornerRadius = 5
                s.clipsToBounds = true
                s.layer.backgroundColor = UIColor.white.cgColor
                
            }
        }
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling  = false
        
        
        //        if #available(iOS 11.0, *) {
        //            navigationItem.searchController = searchController
        //            navigationItem.hidesSearchBarWhenScrolling  = false
        //            navigationItem.titleView = searchController.searchBar
        //        } else {
        //            self.tableView.tableHeaderView = searchBar
        //            searchBar.backgroundColor = UIColor.legitColor()
        //            searchBar.barTintColor = UIColor.legitColor()
        //        }
        
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // Emojis
        if self.selectedScope == 0 {
            return isFiltering ? filteredTag.count : allTag.count
        }
        
        else if self.selectedScope == 1 {
            return isFiltering ? filteredTag.count : mealEmojis.count
        }
            
            // Users
        else if self.selectedScope == 2 {
            return isFiltering ? filteredTag.count : cuisineEmojis.count
        }
            
            // Locations
        else if self.selectedScope == 3 {
            return isFiltering ? filteredTag.count + 1 : dietEmojis.count
        }

            // Google Locations - Data source changes to Google AutoComplete
        else {
            return 0
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 5
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Emojis
        var displayEmoji: EmojiBasic?
        if self.selectedScope == 0 {
            displayEmoji = isFiltering ? filteredTag[indexPath.section] : allTag[indexPath.section]
        } else if self.selectedScope == 1 {
            displayEmoji = isFiltering ? filteredTag[indexPath.section] : mealTag[indexPath.section]
        } else if self.selectedScope == 2 {
            displayEmoji = isFiltering ? filteredTag[indexPath.section] : cuisineTag[indexPath.section]
        } else if self.selectedScope == 3 {
            displayEmoji = isFiltering ? filteredTag[indexPath.section] : dietTag[indexPath.section]
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: EmojiCellId, for: indexPath) as! SearchResultsCell
        cell.emoji = displayEmoji
        if let name = displayEmoji?.name {
            cell.isSelected = self.selectedTags.contains(name)
        } else {
            cell.isSelected = false
        }
        cell.selectionStyle = UITableViewCell.SelectionStyle.none

        return cell
        
    }
    
    @objc func handleBackButton(){
        print("Back Button Tapped | AddTagSearchViewController")
        self.delegate?.additionalTagSelected(tags: self.selectedTags)
        self.navigationController?.popViewController(animated: true)
        
        //        self.navigationController?.popToRootViewController(animated: true)
        
    }
    
    @objc func handleDone(){
        self.delegate?.additionalTagSelected(tags: self.selectedTags)
        self.navigationController?.popViewController(animated: true)

    }

    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var displayEmoji: EmojiBasic?
        if self.selectedScope == 0 {
            displayEmoji = isFiltering ? filteredTag[indexPath.section] : allTag[indexPath.section]
        } else if self.selectedScope == 1 {
            displayEmoji = isFiltering ? filteredTag[indexPath.section] : mealTag[indexPath.section]
        } else if self.selectedScope == 2 {
            displayEmoji = isFiltering ? filteredTag[indexPath.section] : cuisineTag[indexPath.section]
        } else if self.selectedScope == 3 {
            displayEmoji = isFiltering ? filteredTag[indexPath.section] : dietTag[indexPath.section]
        }
        
        guard let name = displayEmoji?.name else {return}
        
        if let index = self.selectedTags.firstIndex(of: name) {
            let temp = self.selectedTags.remove(at: index)
        } else {
            self.selectedTags.append(name)
        }
        
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        // Updates Search Results as searchbar is populated
        let searchBar = searchController.searchBar
        if (searchBar.text?.isEmpty)! {
            // Displays Default Search Results even if search bar is empty
            self.isFiltering = false
            searchController.searchResultsController?.view.isHidden = false
        }
        
        self.isFiltering = searchController.isActive && !(searchBar.text?.isEmpty)!
        
        if self.isFiltering {
            filterContentForSearchText(searchBar.text!)
        }
    }
    
    func filterContentForSearchText(_ searchText: String) {
        
        var tempEmoji: [EmojiBasic] = []
        var refEmoji: [EmojiBasic] = []
        
        if self.selectedScope == 0 {
            refEmoji = self.allTag
        } else if self.selectedScope == 1 {
            refEmoji = self.mealTag
        } else if self.selectedScope == 2 {
            refEmoji = self.cuisineTag
        } else if self.selectedScope == 3 {
            refEmoji = self.dietTag
        }
        
        // Filter for Emojis and Users
        
        let searchCaption = searchText.emojilessString
        let searchCaptionArray = searchText.emojilessString.lowercased().components(separatedBy: " ")
        
        var lastWord = searchCaptionArray[searchCaptionArray.endIndex - 1]
        //        print("searchCaptionArray | \(searchCaptionArray) | lastWord | \(lastWord)")
        
        //     cell.isSelected = (self.captionFiltered != nil) ? (self.captionFiltered?.contains((cell.emoji?.emoji)!))! : false
        
        // Filter Food
            if lastWord.isEmptyOrWhitespace() {
                tempEmoji = refEmoji
            } else {
                // If contains text, filter emojis for remaining word
                tempEmoji = refEmoji.filter({( emoji : EmojiBasic) -> Bool in
                    return searchCaptionArray.contains(emoji.name!) || (emoji.name?.contains(lastWord))!})
            }
        
        self.filteredTag = tempEmoji
        self.tableView.reloadData()
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        self.searchBar.isHidden = true
        //        if self.selectedScope != 3 && self.searchBar.text == "" {
        //            print("MainSearchView | WillDisappear | Blank Search Bar : Auto-Refresh All")
        //            self.delegate?.refreshAll()
        //        }
        
        //      Remove Searchbar scope during transition
        //        self.searchBar.isHidden = true
        //        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //      Show Searchbar scope during transition
        //        self.searchBar.isHidden = false
        self.setupNavigationItems()
//        self.searchBar.becomeFirstResponder()
        //        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            //            self.searchController.searchBar.becomeFirstResponder()
        }
    }
    
    
    
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input = input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
    return input.rawValue
}
