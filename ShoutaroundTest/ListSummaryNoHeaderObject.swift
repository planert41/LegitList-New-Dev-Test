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

protocol ListSummaryDelegate {
    func didTapList(list: List?)
    func didTapUser(user: User?)
    func didTapAddList()
    func doShowListView()
    func doHideListView()
}

class ListSummaryCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, ListSummaryCellDelegate, UICollectionViewDelegateFlowLayout {

    // DROP DOWN SELECTION
    let collectionView: UICollectionView = {
        let layout = UserSummaryFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.layer.borderWidth = 0
        cv.backgroundColor = UIColor.clear
        return cv
    }()
    
    var delegate: ListSummaryDelegate?
    var sortListByPostCount = true {
        didSet {
            self.sortLists()
        }
    }
    
    var currentUserUid: String? = nil {
        didSet {
            if oldValue != self.currentUserUid {
                self.fetchUserLists()
                self.showAddListButton = currentUserUid == Auth.auth().currentUser?.uid
            }
        }
    }

    var userLists: [List] = [] {
        didSet {
        }
    }
    var currentFilterList: List? = nil {
        didSet {
            self.sortLists()
        }
    }
    
    var displayFollowedList: Bool = false {
        didSet {
            self.sortLists()
        }
    }

    var showBookmarkFirst = true
    var showAddListButton = false {
        didSet {
            self.collectionView.reloadData()
        }
    }
    var forceShow = false
    
    
    override func viewDidAppear(_ animated: Bool) {
        if userLists.count == 0 {
            print("ViewDidAppear | No Lists |fetchUserLists")
            self.fetchUserLists()
        }
    }
    
    func scrollToHeader(){
        if self.collectionView.numberOfItems(inSection: 0) > 0 {
            let indexPath = IndexPath(item: 0, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
        }
//        print("SCROLL TO TOP")
    }

    @objc func newListCreated() {
        self.sortListByPostCount = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(newListCreated), name: TabListViewController.refreshListNotificationName, object: nil)

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        collectionView.register(ListSummaryCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        collectionView.collectionViewLayout = layout
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.layoutIfNeeded()
        
        view.addSubview(collectionView)
        collectionView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        self.fetchUserLists()
        // Do any additional setup after loading the view.
    }
    
    
    func resetViews(){
        if userLists.count > 0 {
            collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .left, animated: false)
            collectionView.reloadData()
        }
    }
    

    func sortLists() {
        var tempLists = self.userLists
        if self.sortListByPostCount {
            // SORT BY POST COUNT
            tempLists = self.userLists.sorted { (l1, l2) -> Bool in
                return (l1.postIds?.count ?? 0) > (l2.postIds?.count ?? 0)
            }
        } else {
            // SORT BY DATE
            tempLists = self.userLists.sorted { (l1, l2) -> Bool in
                return l1.latestNotificationTime > l2.latestNotificationTime
            }
        }
        
        if self.showBookmarkFirst {
        
            if let bookmarkId = tempLists.firstIndex(where: { (list) -> Bool in
                list.name == bookmarkListName
            }) {
                var bookmark = tempLists.remove(at: bookmarkId)
                tempLists.insert(bookmark, at: 0)
            }
        }


        if let currentIndex = tempLists.firstIndex(where: {$0.id == self.currentFilterList?.id}) {
            let selected = tempLists.remove(at: currentIndex)
            tempLists.insert(selected, at: 0)
        }

        self.userLists = tempLists
//                print("ListSummaryCollectionViewController | Fetched \(lists.count) Created Lists | Loaded \(self.userLists.count) | \(self.currentUserUid) ")
        self.collectionView.reloadData()
    }
    
    func fetchUserLists(){
        // Load Lists
        guard let currentUid = self.currentUserUid else {return}
        
        self.userLists = []
        if !displayFollowedList {
            Database.fetchCreatedListsForUser(userUid: currentUid) { (lists) in
                if lists.count == 0 {
                    self.delegate?.doHideListView()
                } else {
                    self.delegate?.doShowListView()
                }
                self.userLists = lists
                self.sortLists()
            }

        } else {
            Database.fetchFollowedListsForUser(userUid: currentUid) { (lists) in
                if lists.count == 0 {
                    self.delegate?.doHideListView()
                } else {
                    self.delegate?.doShowListView()
                }
                self.userLists = lists
                self.sortLists()
            }
        }
        
        self.scrollToHeader()

    }
    
    func didTapList(list: List?) {
        guard let list = list else {return}
        self.delegate?.didTapList(list: list)
    }
    
    func didTapAddNewList() {
        self.delegate?.didTapAddList()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        print("Displaying \(userLists.count) Lists | ListSummaryCollectionViewController || \(currentUserUid)")
        return showAddListButton ? userLists.count + 1 : userLists.count
//        return userLists.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ListSummaryCell

        if indexPath.row == userLists.count && showAddListButton {
            cell.addNewListViewShow = true
            return cell
        }
        
        cell.list = self.userLists[indexPath.item]
        cell.isSelected = self.currentFilterList?.id == cell.list?.id
        cell.addNewListViewShow = false
        cell.delegate = self
        let isFilterList = cell.list?.id == self.currentFilterList?.id
        cell.backgroundColor = isFilterList ? UIColor.ianLegitColor().withAlphaComponent(0.6) : UIColor.white
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == userLists.count && showAddListButton {
            self.delegate?.didTapAddList()
        } else {
            let list = self.userLists[indexPath.item]
            self.didTapList(list: list)
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 140)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
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
