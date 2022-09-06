//
//  UserSummaryCollectionViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/1/20.
//  Copyright © 2020 Wei Zou Ang. All rights reserved.
//

import UIKit

import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

private let reuseIdentifier = "Cell"

protocol UserSummaryDelegate {
    func didTapUser(user: User?)
}

class UserSummaryCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UserSummaryCellDelegate, UICollectionViewDelegateFlowLayout {

    // DROP DOWN SELECTION
    let collectionView: UICollectionView = {
        let layout = UserSummaryFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.layer.borderWidth = 0
        cv.backgroundColor = UIColor.clear
        return cv
    }()
    
    var followingUsers: [User] = []
    var filteredUsers = [User]()
    var currentFilterUser: User? = nil {
        didSet {
            self.fetchFollowingUsers()
        }
    }
    var isFiltering = false

    var delegate: UserSummaryDelegate?
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        print("ViewDidAppear | fetchFollowingUsers")
        self.fetchFollowingUsers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        collectionView.register(UserSummaryCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        collectionView.collectionViewLayout = layout
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.layoutIfNeeded()
        
        view.addSubview(collectionView)
        collectionView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        self.fetchFollowingUsers()

        // Do any additional setup after loading the view.
    }

    func resetViews(){
        if followingUsers.count > 0 {
            collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .left, animated: false)
            collectionView.reloadData()
        }
    }
    
    func refreshUsers() {
        self.currentFilterUser = nil
        collectionView.reloadData()
    }
    
    func fetchFollowingUsers(){
        // Load Users
        Database.fetchFollowingUsers(uid: CurrentUser.uid) { (fetchedUsers) in
            print("UserSummaryCollectionViewController | Fetched \(fetchedUsers.count) Following Users")
            var sortedUsers = fetchedUsers.sorted(by: { $0.posts_created > $1.posts_created })
            
            // Insert Self (if not guest)
            if !(Auth.auth().currentUser?.isAnonymous)!, let user = CurrentUser.user {
                sortedUsers.insert(user, at: 0)
            }
            
            if let currentIndex = sortedUsers.firstIndex(where: {$0.uid == self.currentFilterUser?.uid}) {
                let selected = sortedUsers.remove(at: currentIndex)
                sortedUsers.insert(selected, at: 0)
            }
            
            // Remove Ian
            if let currentIndex = sortedUsers.firstIndex(where: {$0.uid == "viidE2ruGtgwWtFdO386t4jBtfM2"}) {
                let deleted = sortedUsers.remove(at: currentIndex)
            }
            
            
            
            self.followingUsers = sortedUsers
            self.collectionView.reloadData()
        }
    }
    
    func filterContentForSearchText(_ searchText: String?) {
        
        guard let searchText = searchText else {
            self.isFiltering = false
            return
        }
            
        self.isFiltering = true
        
        let searchCaption = searchText.emojilessString.lowercased()

        if searchCaption.removingWhitespaces() == "" {
            filteredUsers = followingUsers
            self.collectionView.reloadData()
            return

        } else {
            filteredUsers = followingUsers.filter({ (user) -> Bool in
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
        collectionView.reloadData()
        print("FilterContentResults | \(searchText) | \(filteredUsers.count) Filtered Users | \(followingUsers.count) Users")
    
    }

    func didTapUser(user: User?) {
        guard let user = user else {return}
        self.delegate?.didTapUser(user: user)
    }
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        var curCount = self.isFiltering ? filteredUsers.count : followingUsers.count
        print("UserSummaryCollectionViewController | \(curCount) Load Users : Filtering \(self.isFiltering)")
        return curCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! UserSummaryCell
        cell.user = self.isFiltering ? self.filteredUsers[indexPath.item] : self.followingUsers[indexPath.item]
        cell.delegate = self
        cell.backgroundColor = UIColor.white
        cell.isSelected = cell.user?.uid == currentFilterUser?.uid
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let user = self.followingUsers[indexPath.item]
        self.didTapUser(user: user)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return CGSize(width: 60, height: 80)
        return CGSize(width: 80, height: 90)

    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
