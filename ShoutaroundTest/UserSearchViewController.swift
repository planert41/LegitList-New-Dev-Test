//
//  UserSearchViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/21/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth


protocol UserSearchViewControllerDelegate: class {
    func showSearchResults()
    func hideSearchResults()
    func userFeedSelected(user: User)
}

class UserSearchViewController: UIViewController {

    var delegate: UserSearchViewControllerDelegate?
    
    // SEARCH REC TABLE VIEW
    lazy var searchTableView : UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        tv.estimatedRowHeight = 100
        tv.allowsMultipleSelection = false
        return tv
    }()
    
    // Pagination Variables
    let HomeFullCellId = "HomeFullCellId"
    let HomeGridCellId = "HomeGridCellId"
    let HomeHeaderId = "HomeHeaderId"
    
    
    let EmojiCellId = "EmojiCellId"
    let UserCellId = "UserCellId"
    let LocationCellId = "LocationCellId"
    let ListCellId = "ListCellId"
    
    var fullSearchBar = UISearchBar()
    var isFiltering = false
    var showUserSearch = false {
        didSet {
            self.searchTableView.isHidden = !showUserSearch
        }
    }

    lazy var subLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Search For Other Users"
        ul.font = UIFont.boldSystemFont(ofSize: 14)
        ul.textColor = UIColor.ianBlackColor()
        ul.textAlignment = NSTextAlignment.left
        ul.numberOfLines = 1
        ul.backgroundColor = UIColor.white
        return ul
    }()
    
    let labelView = UIView()
    var allUsers = [User]()
    var filteredUsers = [User]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        view.backgroundColor = UIColor.mainBlue()
        view.backgroundColor = UIColor.white
        
        let containerView = UIView()
        view.addSubview(containerView)
        containerView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: self.view.frame.width, height: 90)
        
        self.setupSearchBar()
        labelView.addSubview(fullSearchBar)
        fullSearchBar.anchor(top: labelView.topAnchor, left: labelView.leftAnchor, bottom: nil, right: labelView.rightAnchor, paddingTop: 0, paddingLeft: -8, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        fullSearchBar.sizeToFit()
        
        labelView.addSubview(subLabel)
        subLabel.anchor(top: fullSearchBar.bottomAnchor, left: labelView.leftAnchor, bottom: labelView.bottomAnchor, right: nil, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        subLabel.rightAnchor.constraint(lessThanOrEqualTo: labelView.rightAnchor)

        subLabel.sizeToFit()
        
        view.addSubview(labelView)
        labelView.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        labelView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        
        self.setupTableView()
        view.addSubview(searchTableView)
        searchTableView.anchor(top: containerView.bottomAnchor, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        searchTableView.isHidden = true
        self.fetchAllUsers()
        
        // Do any additional setup after loading the view.
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

extension UserSearchViewController: UITableViewDataSource, UITableViewDelegate {
    
    func setupTableView(){
        searchTableView.register(SearchResultsCell.self, forCellReuseIdentifier: EmojiCellId)
        searchTableView.register(UserAndListCell.self, forCellReuseIdentifier: UserCellId)
        searchTableView.register(LocationCell.self, forCellReuseIdentifier: LocationCellId)
        searchTableView.register(NewListCell.self, forCellReuseIdentifier: ListCellId)
        self.searchTableView.contentSize = CGSize(width: self.searchTableView.frame.size.width - 40, height: self.searchTableView.contentSize.height)
        searchTableView.backgroundColor = UIColor.white
        searchTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//        searchTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        searchTableView.rowHeight = UITableView.automaticDimension
        searchTableView.estimatedRowHeight = 160
        searchTableView.separatorStyle = .none

    }
    
    func fetchAllUsers(){
        // Load Users
        Database.fetchALLUsers(includeSelf: true) { (fetchedUsers) in
            self.allUsers = fetchedUsers
            var tempResults: [User] = []

            // REMOVE DUPS
            for x in fetchedUsers {
                if !tempResults.contains(where: { (user) -> Bool in
                    return user.uid == x.uid
                }){
                    if x.posts_created > 0 {
                        tempResults.append(x)
                    }
                }
            }
            
            
            self.allUsers = tempResults.sorted(by: { (p1, p2) -> Bool in
                p1.posts_created > p2.posts_created
            })
            
            self.filteredUsers = self.allUsers
            print("UserSearchView | Fetched All Users | \(self.allUsers.count) All Users | \(self.filteredUsers.count) Filtered Users")
            self.searchTableView.reloadData()
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.isFiltering ? filteredUsers.count : allUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: EmojiCellId, for: indexPath) as! SearchResultsCell
//        cell.frame.width = tableView.frame.width - 20

        let displayUser = isFiltering ? filteredUsers[indexPath.item] : allUsers[indexPath.item]
        cell.user = displayUser
        cell.isSelected = false
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let displayUser = isFiltering ? filteredUsers[indexPath.item] : allUsers[indexPath.item]
        self.delegate?.userFeedSelected(user: displayUser)
        self.fullSearchBar.resignFirstResponder()
        
    }
    
    
    
    
    
    
}


extension UserSearchViewController: UISearchBarDelegate {
    func setupSearchBar() {
//        setup.searchBarStyle = .prominent
        fullSearchBar.searchBarStyle = .minimal

        fullSearchBar.isTranslucent = false
        fullSearchBar.tintColor = UIColor.ianBlackColor()
        fullSearchBar.placeholder = "Search User"
        fullSearchBar.delegate = self
        fullSearchBar.showsCancelButton = false
        fullSearchBar.sizeToFit()
        fullSearchBar.clipsToBounds = true
        fullSearchBar.backgroundImage = UIImage()
        fullSearchBar.backgroundColor = UIColor.yellow
        fullSearchBar.isUserInteractionEnabled = true
        fullSearchBar.layer.borderWidth = 1
        fullSearchBar.layer.borderColor = UIColor.black.cgColor

        // CANCEL BUTTON
        let attributes = [
            NSAttributedString.Key.foregroundColor : UIColor.ianLegitColor(),
            NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 30)
        ]
//        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(attributes, for: .normal)
        
        
        let searchImage = #imageLiteral(resourceName: "search_selected").withRenderingMode(.alwaysTemplate)
        fullSearchBar.setImage(UIImage(), for: .search, state: .normal)
        
//        let cancelImage = #imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysTemplate)
//        fullSearchBar.setImage(cancelImage, for: .clear, state: .normal)

        fullSearchBar.layer.borderWidth = 0
        fullSearchBar.layer.borderColor = UIColor.ianBlackColor().cgColor
    
        let textFieldInsideSearchBar = fullSearchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = UIColor.ianBlackColor()
        textFieldInsideSearchBar?.font = UIFont.systemFont(ofSize: 30)
        
        // REMOVE SEARCH BAR ICON
//        let searchTextField:UITextField = fullSearchBar.subviews[0].subviews.last as! UITextField
//        searchTextField.leftView = nil
        
        
        for s in fullSearchBar.subviews[0].subviews {
            if s is UITextField {
                s.backgroundColor = UIColor.clear
                s.layer.backgroundColor = UIColor.clear.cgColor
                if let backgroundview = s.subviews.first {
                    
                    // Background color
//                    backgroundview.backgroundColor = UIColor.white
                    backgroundview.clipsToBounds = true
                    backgroundview.layer.backgroundColor = UIColor.clear.cgColor
                    
                    // Rounded corner
//                    backgroundview.layer.cornerRadius = 30/2
//                    backgroundview.layer.masksToBounds = true
//                    backgroundview.clipsToBounds = true
                }
                
                //                s.layer.cornerRadius = 25/2
                //                s.layer.borderWidth = 1
                //                s.layer.borderColor = UIColor.gray.cgColor
            }
        }

    }
    
//    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
//        self.showSearch()
//        return true
//    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.showSearch()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.hideSearch()
    }
    
//    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
//        self.hideSearch()
//        return true
//    }
    
    func showSearch(){
        self.delegate?.showSearchResults()
//        self.showUserSearch = true
        self.fullSearchBar.showsCancelButton = true
//        if !self.fullSearchBar.isFirstResponder {
//            print("UserSearchView | SearchBar | Become First Responder")
//            self.fullSearchBar.becomeFirstResponder()
//        }
    }
    
    func hideSearch() {
        self.delegate?.hideSearchResults()
//         self.showUserSearch = false
        self.fullSearchBar.showsCancelButton = false
        self.fullSearchBar.resignFirstResponder()
//        if self.fullSearchBar.isFirstResponder {
//            print("UserSearchView | SearchBar | Resign First Responder")
//            self.fullSearchBar.resignFirstResponder()
//        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.hideSearch()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if (searchBar.text?.isEmpty)! {
            // Displays Default Search Results even if search bar is empty
            self.isFiltering = false
//            searchController.searchResultsController?.view.isHidden = false
        } else {
            self.isFiltering = true
            filterContentForSearchText(searchBar.text!)
        }
        self.searchTableView.reloadData()
        
        
    }
    
    func filterContentForSearchText(_ searchText: String) {
        let searchCaption = searchText.emojilessString.lowercased()

        
        if searchCaption.removingWhitespaces() == "" {
            filteredUsers = allUsers
            self.searchTableView.reloadData()
            return

        } else {
            filteredUsers = allUsers.filter({ (user) -> Bool in
                return user.username.lowercased().contains(searchCaption.lowercased())
            })
        }
        

        filteredUsers.sort { (p1, p2) -> Bool in
            let p1Ind = ((p1.username.hasPrefix(searchCaption.lowercased())) ? 0 : 1)
            let p2Ind = ((p2.username.hasPrefix(searchCaption.lowercased())) ? 0 : 1)
            if p1Ind != p2Ind {
                return p1Ind < p2Ind
            } else {
                return p1.posts_created > p2.posts_created
            }
        }
        
        // REMOVE DUPS
        var tempResults: [User] = []
        
        for x in filteredUsers {
            if !tempResults.contains(where: { (user) -> Bool in
                return user.uid == x.uid
            }){
                tempResults.append(x)
            }
        }
        filteredUsers = tempResults
        print("FilterContentResults | \(searchText) | \(filteredUsers.count) Filtered Users | \(allUsers.count) Users")
    
    }
    
}
