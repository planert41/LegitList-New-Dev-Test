//
//  AutoTagTableViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 6/10/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import UIKit

protocol AutoTagTableViewControllerDelegate {
    func autoTagSelected(scope: Int, tag_selected: [String]?)
}


class AutoTagTableViewController: UITableViewController,UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {

    let EmojiCellId = "EmojiCellId"
    var delegate: AutoTagTableViewControllerDelegate?

    var selectedTags: [String] = [] {
        didSet{
            
            var tempMealTags:[String] = []
            var tempCuisineTags:[String] = []
            var tempDietTags:[String] = []
            
            for tag in selectedTags {
                if let _ = mealEmojiDictionary.key(forValue: tag) {
                    tempMealTags.append(tag)
                } else if let _ = cuisineEmojiDictionary.key(forValue: tag) {
                    tempCuisineTags.append(tag)
                } else if let _ = dietEmojiDictionary.key(forValue: tag) {
                    tempDietTags.append(tag)
                }
            }
            
            self.selectedMealTypeAutoTag = tempMealTags
            self.selectedCuisineAutoTag = tempCuisineTags
            self.selectedDietAutoTag = tempDietTags

        }
    }
    
    var selectedMealTypeAutoTag: [String] = []
    var selectedCuisineAutoTag: [String] = []
    var selectedDietAutoTag: [String] = []

    
    
    var selectedMealTagEmojis: [Emoji] = [] {
        didSet {
            selectedMealTypeAutoTag = []
            for emoji in selectedMealTagEmojis {
                selectedMealTypeAutoTag.append(emoji.name!)
            }
            self.tableView.reloadData()
        }
    }
    
    var selectedCuisineTagEmojis: [Emoji] = [] {
        didSet {
            selectedCuisineAutoTag = []
            for emoji in selectedCuisineTagEmojis {
                selectedCuisineAutoTag.append(emoji.name!)
            }
            self.tableView.reloadData()

        }
    }
    
    var selectedDietTagEmojis: [Emoji] = []{
        didSet {
            selectedDietAutoTag = []
            for emoji in selectedDietTagEmojis {
                selectedDietAutoTag.append(emoji.name!)
            }
//            self.tableView.reloadData()

        }
    }
    
    var selectedEmoji: [Emoji] = []{
        didSet {
            // Move Emoji to Top
            if selectedEmoji.count > 0 {
                if let currentIndex = EmojiDictionaryEmojis.firstIndex(where: { (emoji) -> Bool in
                    return emoji.emoji == selectedEmoji[0].emoji
                }) {
                    EmojiDictionaryEmojis.remove(at: currentIndex)
                    EmojiDictionaryEmojis.insert(selectedEmoji[0], at: 0)
                }
            }
        
            self.tableView.reloadData()
        }
    }
    
    
//    0: Meal Type/ Time
//    1: Cuisine by Country
//    2: Dietary Restrictions
    
    var selectedScope = 0 {
        didSet{
//            if selectedScope == 0 {
//                self.tableView.allowsMultipleSelection = false
//            } else {
//                self.tableView.allowsMultipleSelection = false
//            }
//            self.tableView.reloadData()
        }
    }
    
    var searchTerm: String? = nil
    var enableScopeOptions: Bool = false

    let searchController = UISearchController(searchResultsController: nil)
    var searchBar = UISearchBar()
    
    var isFiltering: Bool = false {
        didSet{
            self.tableView.reloadData()
        }
    }
    
    // Auto-Tag Emojis
    var autoTagFields: [String] = ["Meal","Cuisine","Diets","Emojis"]
    
    var filteredMealTypeEmojis: [Emoji] = []
    
    var filteredCuisineEmojis: [Emoji] = []

    var filteredFoodRestrictEmojis: [Emoji] = []
    
    var filteredEmojiDictionary: [Emoji] = []

    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white
        
        tableView.backgroundColor = UIColor.white
        tableView.register(AutoTagCell.self, forCellReuseIdentifier: EmojiCellId)
//        if self.selectedScope == 0 {
//            tableView.allowsMultipleSelection = false
//        } else {
//            tableView.allowsMultipleSelection = false
//        }
        
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if (self.navigationItem.searchController?.searchBar.canBecomeFirstResponder)! {
            self.navigationItem.searchController?.searchBar.becomeFirstResponder()
        }
//        self.searchController.searchBar.becomeFirstResponder()
    }
    
    
    func setupEmojiDictionaries(){
//        // Set Up Auto-Tag Meal Type Emojis
//        for emoji in UploadPostTypeEmojis {
//            let tempEmoji = Emoji(emoji: emoji, name: mealEmojiDictionary[emoji])
//            mealTypeEmojis.append(tempEmoji)
//        }
//
//        // Set Up Auto-Tag Meal Cuisine Emojis
//        for emoji in UploadPostCuisineEmojis {
//            let tempEmoji = Emoji(emoji: emoji, name: EmojiDictionary[emoji])
//            cuisineEmojis.append(tempEmoji)
//        }
//
//        // Set Up Auto-Tag Meal Cuisine Emojis
//        for emoji in UploadFoodRestrictEmoji {
//            let tempEmoji = Emoji(emoji: emoji, name: EmojiDictionary[emoji])
//            foodRestrictEmojis.append(tempEmoji)
//        }
    }
    
    func setupSearchController(){
        //        navigationController?.navigationBar.barTintColor = UIColor.white
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        
        searchBar = searchController.searchBar
        
        if self.enableScopeOptions {
            searchBar.scopeButtonTitles = ["Meal","Cuisine","Diets"]
            searchBar.showsScopeBar = self.enableScopeOptions
        }
        
        searchBar.sizeToFit()
        searchBar.delegate = self
        searchBar.placeholder =  searchBarPlaceholderText
        //        searchBar.barTintColor = UIColor.white
        searchBar.tintColor = UIColor.white
        //        searchBar.backgroundColor = UIColor.legitColor()
        definesPresentationContext = true
        
        for s in searchBar.subviews[0].subviews {
            if s is UITextField {
                s.layer.borderWidth = 0.5
                s.layer.borderColor = UIColor.gray.cgColor
                //                s.layer.cornerRadius = 10
                s.layer.backgroundColor = UIColor.white.cgColor
            }
        }
    
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling  = false
            navigationItem.title = autoTagFields[self.selectedScope]
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(autoTagSelected))
        } else {
            self.tableView.tableHeaderView = searchBar
            searchBar.backgroundColor = UIColor.legitColor()
            searchBar.barTintColor = UIColor.legitColor()
            navigationItem.title = autoTagFields[self.selectedScope]
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(autoTagSelected))
        }
        
    }
    
    func autoTagSelected(){
        
        switch self.selectedScope {
        case 0:
            // Only one meal type selected
            self.delegate?.autoTagSelected(scope: self.selectedScope, tag_selected: self.selectedMealTypeAutoTag)
        case 1:
            self.delegate?.autoTagSelected(scope: self.selectedScope, tag_selected: self.selectedCuisineAutoTag)
        case 2:
            self.delegate?.autoTagSelected(scope: self.selectedScope, tag_selected: self.selectedDietAutoTag)
        case 3:
            if self.selectedEmoji.count > 0 {
                self.delegate?.autoTagSelected(scope: self.selectedScope, tag_selected: [self.selectedEmoji[0].name!])
            } else {
                self.delegate?.autoTagSelected(scope: self.selectedScope, tag_selected: nil)
            }
        default:
            print("Nothing Happens")
        }
        self.navigationController?.popViewController(animated: true)

        
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        print("Selected Scope is: ", selectedScope)
        self.selectedScope = selectedScope
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        if self.isFiltering && self.searchTerm != nil {
            filterContentForSearchText(self.searchTerm!)
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
        
        self.isFiltering = searchController.isActive && !(searchBar.text?.isEmpty)!
        
        if self.isFiltering {
            filterContentForSearchText(searchBar.text!)
        }
    }
    
    func filterContentForSearchText(_ searchText: String) {
        // Filter for Emojis and Users
        
        switch self.selectedScope {
        case 0:
            filteredMealTypeEmojis = mealEmojis.filter({( emoji : Emoji) -> Bool in
                return emoji.emoji.lowercased().contains(searchText.lowercased()) || (emoji.name?.contains(searchText.lowercased()))! })
            filteredMealTypeEmojis.sort { (p1, p2) -> Bool in
                ((p1.name?.hasPrefix(searchText.lowercased()))! ? 0 : 1) < ((p2.name?.hasPrefix(searchText.lowercased()))! ? 0 : 1)
            }
        case 1:
            filteredCuisineEmojis = cuisineEmojis.filter({( emoji : Emoji) -> Bool in
                return emoji.emoji.lowercased().contains(searchText.lowercased()) || (emoji.name?.contains(searchText.lowercased()))! })
            filteredCuisineEmojis.sort { (p1, p2) -> Bool in
                ((p1.name?.hasPrefix(searchText.lowercased()))! ? 0 : 1) < ((p2.name?.hasPrefix(searchText.lowercased()))! ? 0 : 1)
            }
        case 2:
            filteredFoodRestrictEmojis = dietEmojis.filter({( emoji : Emoji) -> Bool in
                return emoji.emoji.lowercased().contains(searchText.lowercased()) || (emoji.name?.contains(searchText.lowercased()))! })
            filteredFoodRestrictEmojis.sort { (p1, p2) -> Bool in
                ((p1.name?.hasPrefix(searchText.lowercased()))! ? 0 : 1) < ((p2.name?.hasPrefix(searchText.lowercased()))! ? 0 : 1)
            }
        case 3:
            filteredEmojiDictionary = EmojiDictionaryEmojis.filter({( emoji : Emoji) -> Bool in
                return emoji.emoji.lowercased().contains(searchText.lowercased()) || (emoji.name?.contains(searchText.lowercased()))! })
            filteredEmojiDictionary.sort { (p1, p2) -> Bool in
                ((p1.name?.hasPrefix(searchText.lowercased()))! ? 0 : 1) < ((p2.name?.hasPrefix(searchText.lowercased()))! ? 0 : 1)
            }
            
        default:
            print("Error: Invalid Scope")
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
        // #warning Incomplete implementation, return the number of rows
        // Meal Type
        if self.selectedScope == 0 {
            if isFiltering {
                return filteredMealTypeEmojis.count
            }   else {
                return mealEmojis.count
            }
        }
            
            // Cuisine
        else if self.selectedScope == 1 {
            if isFiltering {
                return filteredCuisineEmojis.count
            } else {
                return cuisineEmojis.count
            }
        }
        
            // Diet Restriction
        else if self.selectedScope == 2 {
            if isFiltering {
                return filteredFoodRestrictEmojis.count
            } else {
                return dietEmojis.count
            }
        }
            
            // Emoji Dictionary
        else if self.selectedScope == 3 {
            if isFiltering {
                return filteredEmojiDictionary.count
            } else {
                return EmojiDictionaryEmojis.count
            }
        }
            
        else {
            return 0
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: EmojiCellId, for: indexPath) as! AutoTagCell

        switch self.selectedScope {
        case 0:
            if isFiltering{
                cell.emoji = filteredMealTypeEmojis[indexPath.row]
            } else {
                cell.emoji = mealEmojis[indexPath.row]
            }
                cell.isSelected = selectedMealTypeAutoTag.contains((cell.emoji?.name)!)
        case 1:
            if isFiltering{
                cell.emoji = filteredCuisineEmojis[indexPath.row]
            } else {
                cell.emoji = cuisineEmojis[indexPath.row]
            }
            cell.isSelected = selectedCuisineAutoTag.contains((cell.emoji?.name)!)

        case 2:
            if isFiltering{
                cell.emoji = filteredFoodRestrictEmojis[indexPath.row]
            } else {
                cell.emoji = dietEmojis[indexPath.row]
            }
            cell.isSelected = selectedDietAutoTag.contains((cell.emoji?.name)!)

        case 3:
            
            if isFiltering{
                cell.emoji = filteredEmojiDictionary[indexPath.row]
            } else {
                cell.emoji = EmojiDictionaryEmojis[indexPath.row]
            }
            cell.isSelected = selectedEmoji.contains(where: { (emoji) -> Bool in
                return emoji.name == (cell.emoji?.name)!
            })
            
            
        default:
            cell.emoji = nil
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let currentCell = tableView.cellForRow(at: indexPath) as! AutoTagCell
//        tableView.cellForRow(at: indexPath)?.isSelected = true
        
        switch self.selectedScope {
        case 0:
            // Only one meal type selected
            
            if self.selectedMealTypeAutoTag.contains((currentCell.emoji?.name)!) {
                currentCell.isSelected = false
                self.selectedMealTypeAutoTag = self.selectedMealTypeAutoTag.filter{$0 != currentCell.emoji?.name}
            }   else {
                self.selectedMealTypeAutoTag.append((currentCell.emoji?.name)!)

            }
            tableView.reloadData()

        case 1:
            if !self.selectedCuisineAutoTag.contains((currentCell.emoji?.name)!){
                self.selectedCuisineAutoTag.append((currentCell.emoji?.name)!)
            } else {
                currentCell.isSelected = false
                self.selectedCuisineAutoTag = self.selectedCuisineAutoTag.filter{$0 != currentCell.emoji?.name}
            }
            tableView.reloadRows(at: [indexPath], with: .none)

        case 2:
            if !self.selectedDietAutoTag.contains((currentCell.emoji?.name)!){
            self.selectedDietAutoTag.append((currentCell.emoji?.name)!)
            } else {
                currentCell.isSelected = false
                self.selectedDietAutoTag = self.selectedDietAutoTag.filter{$0 != currentCell.emoji?.name}
            }
            tableView.reloadRows(at: [indexPath], with: .none)
            
        case 3:
            if !selectedEmoji.contains(where: { (emoji) -> Bool in
                return emoji.name == (currentCell.emoji?.name)!
            }){
                self.selectedEmoji = [currentCell.emoji!]
            } else {
                currentCell.isSelected = false
                self.selectedEmoji = []
            }
            tableView.reloadRows(at: [indexPath], with: .none)

        default:
            print("Nothing Happens")
        }
//        print(currentCell.isSelected)
//        let selectView = UIView()
//        selectView.backgroundColor = UIColor.legitColor()
//        currentCell.selectedBackgroundView = selectView
//        tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let currentCell = tableView.cellForRow(at: indexPath) as! AutoTagCell
//        tableView.cellForRow(at: indexPath)?.isSelected = false

        var currentTag = [] as [String]
        
        switch self.selectedScope {
        case 0:
            self.selectedMealTypeAutoTag = self.selectedMealTypeAutoTag.filter{$0 != currentCell.emoji?.name}
            self.autoTagSelected()
            tableView.reloadData()
        case 1:
            self.selectedCuisineAutoTag = self.selectedCuisineAutoTag.filter{$0 != currentCell.emoji?.name}
            tableView.reloadRows(at: [indexPath], with: .none)

        case 2:
            self.selectedDietAutoTag = self.selectedDietAutoTag.filter{$0 != currentCell.emoji?.name}
            tableView.reloadRows(at: [indexPath], with: .none)

        case 3:
            self.selectedEmoji = []
            tableView.reloadRows(at: [indexPath], with: .none)
            
        default:
            print("Nothing Happens")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //      Remove Searchbar scope during transition
        self.searchBar.isHidden = true
        //        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
    }
    


}
