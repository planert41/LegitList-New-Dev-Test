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

protocol SelectEmojiTableViewDelegate {
    func statusEmojiSelected(emoji: String?)
}



class SelectEmojiTableView : UITableViewController, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate{


    let EmojiCellId = "EmojiCellId"
    var emojiChoices = UserStatusEmojis

    var inputUser: User? {
        didSet{
            setupEmojis()
        }
    }
    
    var delegate: SelectEmojiTableViewDelegate?


    var searchTerm: String? = nil
    var isFiltering: Bool = false {
        didSet{
            // Reloads tableview when stops filtering
            self.tableView.reloadData()
        }
    }
    
    var selectedScope = 0 {
        didSet{
            self.searchBar.selectedScopeButtonIndex = self.selectedScope
            self.tableView.reloadData()
        }
    }
    
    var selectedUser: User?
    var selectedList: List?
    
    var allEmojis = [Emoji]()
    var filteredEmojis = [Emoji]()

    
    let searchController = UISearchController(searchResultsController: nil)
    var searchBar = UISearchBar()
    
    
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        setupTableView()
        setupEmojis()
        setupNavigationItems()
        setupSearchController()

        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(increaseScope))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleBackPressNav))
        swipeRight.direction = .right
        self.tableView.addGestureRecognizer(swipeRight)
        
    }
    
    func setupEmojis(){
        self.allEmojis = []
        
        for choice in emojiChoices {
            var text = EmojiDictionary[choice] ?? ""
            var temp = Emoji(emoji: choice, name: text)
            self.allEmojis.append(temp)
        }
        
        self.filteredEmojis = self.allEmojis
        self.tableView.reloadData()
    }
    
        
    override func viewWillDisappear(_ animated: Bool) {
        //      Remove Searchbar scope during transition
        self.searchBar.isHidden = true
        //        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //      Show Searchbar scope during transition
        self.setupNavigationItems()
        self.searchBar.isHidden = false
        self.searchBar.selectedScopeButtonIndex = self.selectedScope
        self.tableView.reloadData()
        
        DispatchQueue.main.async {
            if let textField = self.searchBar.value(forKey: "searchField") as? UITextField {
                textField.backgroundColor = UIColor.white
                //textField.font = myFont
                //textField.textColor = myTextColor
                //textField.tintColor = myTintColor
                // And so on...

                let backgroundView = textField.subviews.first
                if #available(iOS 11.0, *) { // If `searchController` is in `navigationItem`
                    backgroundView?.backgroundColor = UIColor.white //Or any transparent color that matches with the `navigationBar color`
                    backgroundView?.subviews.forEach({ $0.removeFromSuperview() }) // Fixes an UI bug when searchBar appears or hides when scrolling
                }
                backgroundView?.layer.cornerRadius = 10.5
                backgroundView?.layer.masksToBounds = true
                //Continue changing more properties...
            }
//            self.searchController.searchBar.becomeFirstResponder()
        }
        //        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
        
        
    }
    
    /*
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            if let textField = self.searchBar.value(forKey: "searchField") as? UITextField {
                textField.backgroundColor = UIColor.white
                //textField.font = myFont
                //textField.textColor = myTextColor
                //textField.tintColor = myTintColor
                // And so on...

                let backgroundView = textField.subviews.first
                if #available(iOS 11.0, *) { // If `searchController` is in `navigationItem`
                    backgroundView?.backgroundColor = UIColor.white //Or any transparent color that matches with the `navigationBar color`
                    backgroundView?.subviews.forEach({ $0.removeFromSuperview() }) // Fixes an UI bug when searchBar appears or hides when scrolling
                }
                backgroundView?.layer.cornerRadius = 10.5
                backgroundView?.layer.masksToBounds = true
                //Continue changing more properties...
            }
//            self.searchController.searchBar.becomeFirstResponder()
        }
    }
        
    */
    
    @objc func handleBackPressNav(){
        self.handleDismiss()
    }
    

    func setupNavigationItems(){
        
    // Header

        
//        self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.ianLegitColor(), NSAttributedString.Key.font.rawValue: UIFont(name: "Poppins-Bold", size: 18)])
        var titleString = "Select User Status Emoji"

        let navLabel = UILabel()
        let customFont = UIFont(name: "Poppins-Bold", size: 18)
        let headerTitle = NSAttributedString(string:titleString, attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianWhiteColor(), NSAttributedString.Key.font: customFont])
        navLabel.attributedText = headerTitle
        self.navigationItem.titleView = navLabel
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.isTranslucent = false
        
        let navColor = UIColor.ianLegitColor()
        
        self.navigationController?.navigationBar.barTintColor = navColor
        self.navigationController?.navigationBar.tintColor = UIColor.ianLegitColor()
        self.navigationController?.navigationBar.backgroundColor = navColor
        self.navigationController?.view.backgroundColor = navColor

        self.navigationController?.navigationBar.layoutIfNeeded()


    // Nav Back Buttons
        
        navBackButton.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        navBackButton.setTitle("Back", for: .normal)
        let barButton2 = UIBarButtonItem.init(customView: navBackButton)
        self.navigationItem.leftBarButtonItem = barButton2
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
    
    var followingCount: Int = 0
    var otherCount: Int = 0

    
    
    // MARK: - SEARCH BAR

    
    func setupSearchController(){
        //        navigationController?.navigationBar.barTintColor = UIColor.white
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchBar = searchController.searchBar

        searchBar.backgroundImage = UIImage()
        searchBar.showsScopeBar = false
        searchBar.sizeToFit()
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder =  searchBarPlaceholderText
        searchBar.barTintColor = UIColor.ianLegitColor()
        searchBar.tintColor = UIColor.ianLegitColor()
        
        searchBar.barTintColor = UIColor.backgroundGrayColor()
        searchBar.tintColor = UIColor.backgroundGrayColor()
        searchBar.backgroundColor = UIColor.backgroundGrayColor()

        definesPresentationContext = true
        searchBar.backgroundColor = UIColor.ianLegitColor()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
//        searchBar.scopeBarBackgroundImage = UIImage.imageWithColor(color: UIColor.blue)

        for subview in searchBar.subviews {
            if subview is UISegmentedControl {
                subview.tintColor = UIColor.mainBlue()
            }
        }
        
        searchBar.setScopeBarButtonTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)
        searchBar.setScopeBarButtonTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianWhiteColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
        
        if let textField = self.searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = UIColor.white
            //textField.font = myFont
            //textField.textColor = myTextColor
            //textField.tintColor = myTintColor
            // And so on...

            let backgroundView = textField.subviews.first
            if #available(iOS 11.0, *) { // If `searchController` is in `navigationItem`
                backgroundView?.backgroundColor = UIColor.white //Or any transparent color that matches with the `navigationBar color`
                backgroundView?.subviews.forEach({ $0.removeFromSuperview() }) // Fixes an UI bug when searchBar appears or hides when scrolling
            }
            backgroundView?.layer.cornerRadius = 10.5
            backgroundView?.layer.masksToBounds = true
            //Continue changing more properties...
        }
        
        
        
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling  = false
            
        } else {
            self.tableView.tableHeaderView = searchBar
        }
        
    }
    
    
    
    func filterContentForSearchText(_ searchText: String) {
        
        filteredEmojis = self.allEmojis.filter { (emoji) -> Bool in
            return (emoji.name?.lowercased() ?? "").contains(searchText.lowercased()) ||  (emoji.emoji ?? "").contains(searchText.lowercased())
        }
        
        self.tableView.reloadData()
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
            if self.selectedScope == 0 || self.selectedScope == 1 {
                filterContentForSearchText(searchBar.text!)
            }
        }
    }
    
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        self.searchBar.sizeToFit()
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        self.searchBar.sizeToFit()
        return true
    }

    

    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchBar.text?.isEmpty)! {
            self.searchTerm = nil
            self.isFiltering = false
        } else {
            self.isFiltering = true
            self.searchTerm = searchText
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        if !(searchBar.text?.isEmptyOrWhitespace())! {
//            self.filterCaptionSelected(searchedText: searchBar.text)
//        } else {
//            self.filterCaptionSelected(searchedText: nil)
//        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//        if !(searchBar.text?.isEmptyOrWhitespace())! {
//            self.filterCaptionSelected(searchedText: searchBar.text)
//        } else {
//            self.filterCaptionSelected(searchedText: nil)
//        }
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        print("Selected Scope is: ", selectedScope)
        self.selectedScope = selectedScope
        self.tableView.reloadData()
    }

    
}


extension SelectEmojiTableView {
    
    func setupTableView(){
        tableView.backgroundColor = UIColor.white
        tableView.register(SearchResultsCell.self, forCellReuseIdentifier: EmojiCellId)

        tableView.estimatedRowHeight = 160
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.alwaysBounceVertical = true
        let adjustForTabbarInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
        tableView.contentInset = adjustForTabbarInsets
        tableView.scrollIndicatorInsets = adjustForTabbarInsets

    }
    

    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      
        return emojiChoices.count + 1

    }
    
//    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 70 + 90 + 10
//    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: EmojiCellId, for: indexPath) as! SearchResultsCell
        if indexPath.row == 0 {
            cell.isSelected = false
            cell.emoji = nil
            cell.emojiTextLabel.text = "None"
        } else {
            let displayTerm = isFiltering ? self.filteredEmojis[indexPath.row - 1] : self.allEmojis[indexPath.row - 1]
            cell.emoji = displayTerm
            cell.isSelected = self.selectedUser?.emojiStatus == displayTerm.emoji
        }
        
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                
        let displayTerm = indexPath.row == 0 ? nil : (isFiltering ? self.filteredEmojis[indexPath.row - 1] : self.allEmojis[indexPath.row - 1])
        
        self.emojiSelected(emoji: displayTerm)
        
    }
    
    func emojiSelected(emoji: Emoji?) {
//        guard let emoji = emoji else {return}navi
        self.navigationController?.popViewController(animated: true)
        self.delegate?.statusEmojiSelected(emoji: emoji?.emoji)
        print("emojiSelected | emoji: \(emoji?.emoji)")

    }
    func handleDismiss() {
        print("emojiSelected | Dismiss")
        self.navigationController?.popViewController(animated: true)
    }
    
}
