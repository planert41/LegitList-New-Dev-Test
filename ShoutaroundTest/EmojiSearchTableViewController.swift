//
//  EmojiSearchTableViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 11/27/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import FirebaseDatabase
import SVProgressHUD
//
//  AutoTagTableViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 6/10/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import UIKit

protocol EmojiSearchTableViewControllerDelegate {
    func setEmojiTags(emojiInput: [String]?)
}


class EmojiSearchTableViewController: UITableViewController,UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {
    
    let EmojiCellId = "EmojiCellId"
    var delegate: EmojiSearchTableViewControllerDelegate?
    
    
    var selectedScope = 0 {
        didSet{
            self.setupEmojiDictionaries()
        }
    }
    
    var searchTerm: String? = nil
    
    let searchController = UISearchController(searchResultsController: nil)
    var searchBar = UISearchBar()
    
    var isFiltering: Bool = false {
        didSet{
            self.tableView.reloadData()
        }
    }
    
    // Auto-Tag Emojis
    var selectedEmojis: [String] = [] {
        didSet {
            self.refreshNavigationTitle()
        }
    }

//    var searchEmojiScope = ["All" , "Ing", "Feel", "Flags", "More" ]
    var searchEmojiScope = ["All" , "🐮 Ingr", "🇺🇸 Flags", "😋 Feels", "🏠 Other" ]

    var displayedEmojis: [Emoji] = []
    var filteredEmojis: [Emoji] = []
    var searchCaptionEmojis: [Emoji] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        
        tableView.backgroundColor = UIColor.white
        tableView.register(AutoTagCell.self, forCellReuseIdentifier: EmojiCellId)
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 140
        
        setupSearchController()
        setupEmojiDictionaries()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //        if selectedEmojiTag.count > 0 {
        //            if let currentIndex = EmojiDictionaryEmojis.index(where: { (emoji) -> Bool in
        //                return emoji.emoji == selectedEmojiTag[0].emoji
        //            }) {
        //                EmojiDictionaryEmojis.remove(at: currentIndex)
        //                EmojiDictionaryEmojis.insert(selectedEmojiTag[0], at: 0)
        //            }
        //        }
        tableView.scrollToNearestSelectedRow(at: .top, animated: true)
        setupNavigationItems()
        self.setupSearchController()
        self.searchController.searchBar.becomeFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.searchController.searchBar.becomeFirstResponder()
        self.navigationController?.isNavigationBarHidden = false

        if (self.navigationItem.searchController?.searchBar.canBecomeFirstResponder)! {
            self.navigationItem.searchController?.searchBar.becomeFirstResponder()
        }
        //        self.searchController.searchBar.becomeFirstResponder()
    }
    
    
    func setupEmojiDictionaries(){
        
        switch self.selectedScope {
        case 0:
            // All Emojis
            self.displayedEmojis = allEmojis
        case 1:
            // Ingredients
            self.displayedEmojis = allEmojis.filter({ (emoji_ref) -> Bool in
                allIngredientEmojis.contains(emoji_ref.emoji)
            })
        case 2:
            // Flag
            self.displayedEmojis = allEmojis.filter({ (emoji_ref) -> Bool in
                cuisineEmojiSelect.contains(emoji_ref.emoji)
            })
        case 3:
            // Smiley
            self.displayedEmojis = allEmojis.filter({ (emoji_ref) -> Bool in
                smileyEmojis.contains(emoji_ref.emoji)
            })
        case 4:
            // Other
            self.displayedEmojis = allEmojis.filter({ (emoji_ref) -> Bool in
                otherEmojis.contains(emoji_ref.emoji)
            })
        default:
            print("Nothing Happens")
        }
        
        
        // Move Selected Emoji To Front
        for emoji in self.selectedEmojis {
            if let index = self.displayedEmojis.firstIndex(where: { (emoji_ref) -> Bool in
                emoji_ref.emoji == emoji
            }) {
                let tempEmoji = self.displayedEmojis.remove(at: index)
                self.displayedEmojis.insert(tempEmoji, at: 0)
            }
        }
        
    }
    
    func setupNavigationItems() {
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.isTranslucent = false
        let tempImage = UIImage.init(color: UIColor.legitColor())
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        
        navigationController?.view.backgroundColor = UIColor.ianLegitColor()
        navigationController?.navigationBar.shadowImage = UIImage()
        
        navigationController?.navigationBar.barTintColor = UIColor.ianLegitColor()
        navigationController?.navigationBar.tintColor = UIColor.ianLegitColor()
        navigationController?.navigationBar.layoutIfNeeded()
        navigationItem.title = "Emojis - \(self.selectedEmojis.joined(separator: " ")) "
        
        // Nav Back Buttons
        let navBackButton = navBackButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        navBackButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        navBackButton.setTitleColor(UIColor.white, for: .normal)
        navBackButton.tintColor = UIColor.white
        navBackButton.backgroundColor = UIColor.clear
        let navShareTitle = NSAttributedString(string: " BACK ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 12)])
        navBackButton.setAttributedTitle(navShareTitle, for: .normal)
        let barButton2 = UIBarButtonItem.init(customView: navBackButton)
        self.navigationItem.leftBarButtonItem = barButton2
        
        
        let navNextButton = NavButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        navNextButton.addTarget(self, action: #selector(autoTagSelected), for: .touchUpInside)
        navNextButton.setTitle("Next", for: .normal)
        navNextButton.setTitleColor(UIColor.white, for: .normal)
        let nextBarButton = UIBarButtonItem.init(customView: navNextButton)
        self.navigationItem.rightBarButtonItem = nextBarButton
                
        self.setNeedsStatusBarAppearanceUpdate()

    }
    
    func setupSearchController(){
        //        navigationController?.navigationBar.barTintColor = UIColor.white

        setupNavigationItems()

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.searchBarStyle = .default
        searchController.searchBar.setBackgroundImage(UIImage(color: UIColor.legitColor()), for: UIBarPosition(rawValue: 0)!, barMetrics:.default)
        
        searchBar = searchController.searchBar
        searchBar.scopeButtonTitles = searchEmojiScope
        searchBar.showsScopeBar = true
        
        searchBar.delegate = self
        searchBar.tintColor = UIColor.ianLegitColor()
        searchBar.isTranslucent = false
        searchBar.barTintColor = UIColor.ianLegitColor()
        searchBar.layer.borderWidth = 0
        searchBar.layer.borderColor = UIColor.lightBackgroundGrayColor().cgColor
        searchBar.backgroundColor = UIColor.ianLegitColor()
        searchBar.backgroundImage = UIImage()
        definesPresentationContext = false
        
        searchBar.layer.masksToBounds = true
        searchBar.clipsToBounds = true
        
        var iconImage = #imageLiteral(resourceName: "search_tab_fill").withRenderingMode(.alwaysTemplate)
        searchBar.setImage(iconImage, for: .search, state: .normal)
        searchBar.setSerchTextcolor(color: UIColor.ianLegitColor())
        var searchTextField: UITextField? = searchBar.value(forKey: "searchField") as? UITextField
        if searchTextField!.responds(to: #selector(getter: UITextField.attributedPlaceholder)) {
            let attributeDict = [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
            searchTextField!.attributedPlaceholder = NSAttributedString(string: "Search Emoji", attributes: attributeDict)
            searchTextField!.backgroundColor = UIColor.white
        }
        
        let textFieldInsideUISearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.textColor = UIColor.ianLegitColor()
        textFieldInsideUISearchBar?.font = UIFont.systemFont(ofSize: 12)
        textFieldInsideUISearchBar?.backgroundColor = UIColor.white
        
        
        for s in searchBar.subviews[0].subviews {
            if s is UITextField {
                s.layer.borderWidth = 0.5
                s.layer.borderColor = UIColor.gray.cgColor
                s.layer.cornerRadius = 5
                s.clipsToBounds = true
//                s.layer.backgroundColor = UIColor.lightBackgroundGrayColor().cgColor
//                s.backgroundColor = UIColor.lightBackgroundGrayColor()
                s.layer.backgroundColor = UIColor.white.cgColor
                s.backgroundColor = UIColor.white
            }
        }
        
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            self.searchController.searchBar.becomeFirstResponder()
        } else {
            self.tableView.tableHeaderView = searchBar
            searchBar.becomeFirstResponder()
        }
        
        

    }
    
    func refreshNavigationTitle(){
        navigationItem.title = "Emojis - \(self.selectedEmojis.joined(separator: " ")) "
    }
    
    override func handleBack() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func autoTagSelected(){
        self.delegate?.setEmojiTags(emojiInput: self.selectedEmojis)
        print("Selected Emojis | \(self.selectedEmojis)")

        self.navigationController?.popViewController(animated: true)
        
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        print("Selected Scope is: ", selectedScope)
        self.selectedScope = selectedScope
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        if self.isFiltering && self.searchBar.text != nil {
            filterContentForSearchText(self.searchBar.text!)
        }
        
        self.tableView.reloadData()
    }
    
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        if (searchBar.text?.isEmpty)! {
            // Displays Default Search Results even if search bar is empty
            self.isFiltering = false
            searchController.searchResultsController?.view.isHidden = false
        }
        
        if let searchText = searchBar.text {
            if !searchText.isEmptyOrWhitespace() {
                var searchCaptionEmojiText = Array(Set(searchText.emojis))
                self.searchCaptionEmojis = []
                for emoji in searchCaptionEmojiText {
                    self.searchCaptionEmojis.append(Emoji(emoji: emoji, name: EmojiDictionary[emoji] ?? ""))
                }
                print("Detected \(self.searchCaptionEmojis.count) Emojis in SearchBox | \(searchCaptionEmojiText)")
            }
        }
        
        
        self.isFiltering = searchController.isActive && !(searchBar.text?.isEmpty)!
        
        if self.isFiltering {
            filterContentForSearchText(searchBar.text!)
        }
    }
    
    func filterContentForSearchText(_ searchText: String) {
        var tempEmojis = displayedEmojis
        for emoji in searchCaptionEmojis {
            if !tempEmojis.contains { (tempEmoji) -> Bool in
                return tempEmoji.emoji == emoji.emoji
            } {
                tempEmojis.append(emoji)
            }
        }

        var searchCaptionEmojiText = searchText.emojis
        filteredEmojis = tempEmojis.filter({( emoji : Emoji) -> Bool in
                                            return emoji.emoji.lowercased().contains(searchText.lowercased()) || (emoji.name?.contains(searchText.lowercased()))! || searchCaptionEmojiText.contains(emoji.emoji) })
        filteredEmojis.sort { (p1, p2) -> Bool in
            ((p1.name?.hasPrefix(searchText.lowercased()))! ? 0 : 1) < ((p2.name?.hasPrefix(searchText.lowercased()))! ? 0 : 1)
        }
        
    
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if isFiltering {
            return filteredEmojis.count
        }   else {
            return displayedEmojis.count
        }

    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: EmojiCellId, for: indexPath) as! AutoTagCell
        var cellEmoji: Emoji? = nil
        
        if isFiltering{
            cellEmoji = filteredEmojis[indexPath.row]
        } else {
            cellEmoji = displayedEmojis[indexPath.row]
        }
        cell.emoji = cellEmoji
        cell.isSelected = self.selectedEmojis.contains((cell.emoji?.emoji)!)
        

//        if ((cellEmoji?.emoji ?? "") != "" && ((cellEmoji?.name ?? "").isEmptyOrWhitespace())) {
//            let emptyEmojiName = NSAttributedString(string: "N/A : Tap to Add Emoji Name", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.font: UIFont(font: .avenirNextMediumItalic, size: 12)])
//            cell.emojiTextLabel.attributedText = emptyEmojiName
//        }
        
        return cell
    }
    
    @objc func suggestEmojiDic(emoji: String){
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Emoji Name Missing", message: "\(emoji) emoji has no name yet. Would you like to add one to your personal Emoji Dictionary?", preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.text = ""
            textField.placeholder = "Insert New Emoji Name"
        }
        
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "Add Name", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            print("New Emoji Definion for \(emoji) : \(textField?.text)")
            if textField?.text?.isEmptyOrWhitespace() ?? true{
                self.alert(title: "Emoji Name Error", message: "Please insert a new name for \(emoji) emoji")
            }
            guard let newEmojiName = textField?.text else {return}
            Database.updateEmojiNameForUser(emojiName: newEmojiName, emoji: emoji, userUid: CurrentUser.uid)
            self.tagUntagEmoji(taggedEmoji: emoji)
            SVProgressHUD.showSuccess(withStatus: "Added '\(newEmojiName)' to \(emoji)")
            SVProgressHUD.dismiss(withDelay: 1)
        }))
        
        alert.addAction(UIAlertAction(title: "Just Tag Without Name", style: .cancel, handler: { (action: UIAlertAction!) in
            self.tagUntagEmoji(taggedEmoji: emoji)
            print("Handle Cancel Logic here")
        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
        
        
    }
    
    
    func tagUntagEmoji(taggedEmoji: String?){
        guard let taggedEmoji = taggedEmoji else {
            return
        }
        
        if self.selectedEmojis.contains(taggedEmoji) {
            if let index = self.selectedEmojis.firstIndex(of: taggedEmoji) {
                self.selectedEmojis.remove(at: index)
                print("Untag Emoji | \(taggedEmoji) | Selected \(self.selectedEmojis)")
            }
        } else {
            if self.selectedEmojis.count >= 3 {
                let oldEmoji = self.selectedEmojis[2]
                self.selectedEmojis[2] = taggedEmoji
                
//                if let index = self.displayedEmojis
                
                print("Tag Emoji | Replace \(oldEmoji) with \(taggedEmoji) | Selected \(self.selectedEmojis)")
            } else {
                self.selectedEmojis.append(taggedEmoji)
                print("Tag Emoji | \(taggedEmoji) | Selected \(self.selectedEmojis)")
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let currentCell = tableView.cellForRow(at: indexPath) as! AutoTagCell
        //        tableView.cellForRow(at: indexPath)?.isSelected = true
        let taggedEmoji = (currentCell.emoji?.emoji)!
        
        if (((currentCell.emoji?.name ?? "").isEmptyOrWhitespace())) {
            self.suggestEmojiDic(emoji: taggedEmoji)
        } else {
            self.tagUntagEmoji(taggedEmoji: taggedEmoji)
        }
        
//        if self.selectedEmojis.contains(taggedEmoji) {
//            if let index = self.selectedEmojis.index(of: taggedEmoji) {
//                self.selectedEmojis.remove(at: index)
//                print("Untag Emoji | \(taggedEmoji) | Selected \(self.selectedEmojis)")
//            }
//        } else {
//            self.selectedEmojis.append(taggedEmoji)
//            print("Tag Emoji | \(taggedEmoji) | Selected \(self.selectedEmojis)")
//        }
        
        tableView.reloadData()
//        tableView.reloadRows(at: [indexPath], with: .none)

    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let currentCell = tableView.cellForRow(at: indexPath) as! AutoTagCell
        //        tableView.cellForRow(at: indexPath)?.isSelected = false
        

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //      Remove Searchbar scope during transition
        self.searchBar.isHidden = true
        //        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
    }
    
    
    
}
