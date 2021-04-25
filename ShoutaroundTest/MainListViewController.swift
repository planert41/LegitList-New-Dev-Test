//
//  UserListViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/6/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import UIKit

import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

protocol MainListViewControllerDelegate {
    func listSelected(list: List?)
}

class MainListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate, MainUserProfileViewDelegate {

    var delegate: MainListViewControllerDelegate?
    
// USER PROFILE
    var enableListManagementView: Bool = false

    var displayUser: User? = nil {
        didSet{
            if let _ = displayUser {
                print("MainListView User |\(displayUser?.username)")
                self.userProfileView.user = self.displayUser
                self.fetchCurrentUserLists()
            }
        }
    }
    
    
    func fetchCurrentUserLists(){
        self.displayList = []
        if let _ = self.displayUser {
            Database.fetchListForMultListIds(listUid: self.displayUser?.listIds) { (lists) in
                print("MainListView User |\(self.displayUser?.username) | Fetched \(lists.count) Lists")
                self.displayList = lists
                self.sortLists()
                self.listTableView.reloadData()
            }
        } else {
            self.listTableView.reloadData()
        }
    }
    
    func sortLists(){
        if self.displayList.count == 0 {
            return
        }
        
        // Sort List by Post Counts
        self.displayList.sort { (l1, l2) -> Bool in
            (l1.postIds?.count)! >= (l2.postIds?.count)!
        }
        
        // Move Bookmark To Front
        if let bookmarkIndex = self.displayList.firstIndex(where: { (list) -> Bool in
            list.name == bookmarkListName
        }){
            let tempList = self.displayList.remove(at: bookmarkIndex)
            self.displayList.insert(tempList, at: 0)
        }
        
        // Move Legit To Front
        if let legitIndex = self.displayList.firstIndex(where: { (list) -> Bool in
            list.name == legitListName
        }){
            let tempList = self.displayList.remove(at: legitIndex)
            self.displayList.insert(tempList, at: 0)
        }
        
        
    }
    
    var currentDisplayedList: List? = nil
    var displayList: [List] = []
    var filteredDisplayList: [List] = []
    let listCellId = "ListCellId"
    var tableEdit: Bool = false

    
    
    lazy var listTableView : UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        tv.estimatedRowHeight = 100
        tv.allowsMultipleSelection = false
        return tv
    }()

    
    let searchController = UISearchController(searchResultsController: nil)
    var searchBar = UISearchBar()

    var isFiltering: Bool = false {
        didSet{
            self.listTableView.reloadData()
        }
    }
    
// USER PROFILE ITEMS

    lazy var userProfileView : MainUserProfileView = {
        let view = MainUserProfileView()
        view.delegate = self
        return view
    }()
    
// EMOJI DETAIL LABEL
    
    let emojiDetailLabel: PaddedUILabel = {
        let label = PaddedUILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 25)
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.rgb(red: 255, green: 242, blue: 230)
        label.layer.cornerRadius = 30/2
        label.layer.borderWidth = 0.25
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.masksToBounds = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationItems()
        setupViews()
        setupSearchController()
        setupTableView()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.setupNavigationItems()
    }
    
    
    func setupNavigationItems(){
        
        self.navigationController?.view.backgroundColor = UIColor.legitColor()
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.white, NSAttributedString.Key.font.rawValue: UIFont(font: .noteworthyBold, size: 20)])
        self.navigationItem.title = "Filter For List"
        self.navigationController?.navigationBar.layoutIfNeeded()
        
        
        // Switch Button positions if not from tab view.
        if enableListManagementView {
            let listButton = UIBarButtonItem(image: #imageLiteral(resourceName: "slider_white").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(manageList))
            navigationItem.rightBarButtonItem = listButton
        }
//
//        self.navigationController?.navigationBar.isTranslucent = false
//        let tempImage = UIImage.init(color: UIColor.legitColor())
//        self.navigationController?.navigationBar.setBackgroundImage(tempImage, for: .default)

    }
    
    func manageList(){
        let sharePhotoListController = ManageListViewController()
        navigationController?.pushViewController(sharePhotoListController, animated: true)
    }
    
    func setupViews(){
    // USER PROFILE VIEW
        view.addSubview(userProfileView)
        userProfileView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 100)
    
    // TABLEVIEW
        view.addSubview(listTableView)
        listTableView.anchor(top: userProfileView.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        view.addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top:topLayoutGuide.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        emojiDetailLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        emojiDetailLabel.alpha = 0
        
    }

    
    func loadUserView(){
        self.userProfileView.user = self.displayUser

    }
    
    func setupTableView(){
        
        listTableView.register(NewListCell.self, forCellReuseIdentifier: listCellId)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshList), for: .valueChanged)
        listTableView.refreshControl = refreshControl
        listTableView.alwaysBounceVertical = true
        listTableView.keyboardDismissMode = .onDrag
    }
    
    func refreshList(){
        
    }
    
    func setupSearchController(){
        self.extendedLayoutIncludesOpaqueBars = true

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        
        searchBar = searchController.searchBar
        
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
                s.layer.cornerRadius = 10
                s.clipsToBounds = true
                s.layer.backgroundColor = UIColor.white.cgColor
            }
        }
        
        self.listTableView.tableHeaderView = searchBar
        searchBar.backgroundColor = UIColor.legitColor()
        searchBar.barTintColor = UIColor.legitColor()
        
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
        // Filter List Table View
            
            filteredDisplayList = displayList.filter({ (list) -> Bool in
                return list.name.lowercased().contains(searchText.lowercased()) || list.topEmojis.contains(searchText.lowercased())
            })
            filteredDisplayList.sort { (p1, p2) -> Bool in
                ((p1.name.hasPrefix(searchText.lowercased())) ? 0 : 1) < ((p2.name.hasPrefix(searchText.lowercased())) ? 0 : 1)
            }
    
        self.listTableView.reloadData()
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering{
            return filteredDisplayList.count
        } else {
            return displayList.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: listCellId, for: indexPath) as! NewListCell
        
        var list = displayList[indexPath.row]
        if isFiltering{
            list = filteredDisplayList[indexPath.row]
        } else {
            list = displayList[indexPath.row]
        }
        
        cell.list = list
        
        if list.id == self.currentDisplayedList?.id {
            cell.isSelected = true
        } else {
            cell.isSelected = false
        }
        
//        // select/deselect the cell
//        if displayList[indexPath.row].isSelected {
//            if !cell.isSelected {
//                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
//            }
//        } else {
//            if cell.isSelected {
//                tableView.deselectRow(at: indexPath, animated: false)
//            }
//        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var selectedList: List?
        
        if isFiltering {
            selectedList = filteredDisplayList[indexPath.row]
        } else {
            selectedList = displayList[indexPath.row]
        }
        
        if self.currentDisplayedList?.id == selectedList?.id {
            print("Deselect | \(selectedList?.name)")
            self.delegate?.listSelected(list: nil)
        } else {
            print("Selected | \(selectedList?.name)")
            self.delegate?.listSelected(list: selectedList!)
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        var selectedList: List?
        
        print("Deselected | \(selectedList?.name)")
        self.delegate?.listSelected(list: nil)
        self.navigationController?.popViewController(animated: true)
    }
    
    func didTapUserUid(uid: String) {
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = uid
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapUserView() {
    }
    
    func didTapEmoji(index: Int, emoji: String) {
        
        
        guard let  displayEmojiTag = EmojiDictionary[emoji] else {return}
        //        self.delegate?.displaySelectedEmoji(emoji: displayEmoji, emojitag: displayEmojiTag)

        print("Selected Emoji | \(index) | \(emoji) | \(displayEmojiTag)")

        var captionDelay = 3
        emojiDetailLabel.text = "\(emoji)  \(displayEmojiTag)"
        emojiDetailLabel.alpha = 1
        emojiDetailLabel.sizeToFit()

        UIView.animate(withDuration: 0.5, delay: TimeInterval(captionDelay), options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.emojiDetailLabel.alpha = 0
        }, completion: { (finished: Bool) in
        })
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
