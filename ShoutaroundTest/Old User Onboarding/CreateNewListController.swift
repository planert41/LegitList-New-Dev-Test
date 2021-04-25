//
//  ManageListController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/28/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

import DropDown
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import SVProgressHUD

class CreateNewListController: UIViewController, UITextFieldDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDataSource, UITableViewDelegate, DiscoverListCellNewDelegate, UploadPhotoToListCellDelegate {


    
    var createdList: [List] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    var sampleLists: [List] = []
    

    let suggestListNames = ["Bookmark", "Top 20", "Favorites", "Legit", "Travel", "Ramen", "Burgers", "Pizza"]
    
//    let introString = "LegitList is about using lists to curate your best experiences and recommendations. Make your own personal list 🥳"
    let introString = "Create Lists by Location, Food, Meal or Experience to Organize Your Food Photos"

    
    
    let infoLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = UIFont(name: "Poppins-Bold", size: 25)
        label.textColor = .white
        label.backgroundColor = UIColor.clear
        label.text = "Create A List"
        label.textColor = UIColor.ianLegitColor()
        label.numberOfLines = 0
        return label
    }()
    
    let infoDetail: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = UIFont(name: "Poppins-Regular", size: 18)
        label.textColor = .white
        label.backgroundColor = UIColor.clear
        label.text = "Based on Location, Food, Meal or Travel"
        label.textColor = UIColor.ianLegitColor()
        label.numberOfLines = 0
        return label
    }()
    
    lazy var addListTextField: PaddedTextField = {
        let tf = PaddedTextField()
        tf.font = UIFont.systemFont(ofSize: 14.0)
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.gray.cgColor
        tf.backgroundColor = UIColor(white: 1, alpha: 0.03)
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.layer.cornerRadius = 10
        tf.layer.masksToBounds = true
        tf.placeholder = "New List Name Here"
        tf.delegate = self
        return tf
    }()
    
    let addListButton: UIButton = {
        let button = UIButton()
        button.setTitle("Create List", for: .normal)
        button.titleLabel?.textColor = UIColor.white
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        
        //        button.setImage(#imageLiteral(resourceName: "add").withRenderingMode(.alwaysOriginal), for: .normal)
        //        button.imageView?.contentMode = .scaleAspectFit
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.ianLegitColor()
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.legitColor().cgColor
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        button.layer.cornerRadius = 10
        
        button.addTarget(self, action: #selector(addList), for: .touchUpInside)
        return button
    } ()
    
    @objc func addList(){
        guard let listName = addListTextField.text else {
            self.alert(title: "List Name Error", message: "Empty List Name")
            return
        }
        
        if listName.removingWhitespaces().count == 0 {
            self.alert(title: "List Name Error", message: "Empty List Name")
        }
        
        if self.createdList.contains(where: { (list) -> Bool in
            return list.name == listName
        })  {
            self.alert(title: "List Name Error", message: "Duplicate List Name")
        }
        
        
        
        let message = "Create a new list called \(listName)?"
        let alert = UIAlertController(title: "New List", message: message, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction!) in
            let listId = NSUUID().uuidString
            let tempList = List.init(id: listId, name: listName, publicList: 1)

            self.createdList.append(tempList)
            self.addListTextField.text = nil
            self.addListTextField.resignFirstResponder()
            self.selectedListType = self.listOptions[0]
            Database.createList(uploadList: tempList){}
            self.refreshAll()
        }))
            
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: { (action: UIAlertAction!) in
            
            print("Canceled | Create a new list called \(listName)")
        }))
        
        self.checkListName(listName: listName) { (listName) in
            
            self.present(alert, animated: true, completion: nil)
            
        }

        
        

        
//        self.createdList.append(listName)
//        addListTextField.text = nil
//        self.refreshAll()
//        self.tableView.reloadData()
    }
    
    func checkListName(listName: String?, completion: @escaping (String) -> ()){
        guard let listName = listName else {
            self.alert(title: "New List Requirement", message: "Please Insert List Name")
            return
        }
        if listName.isEmptyOrWhitespace() {
            self.alert(title: "New List Requirement", message: "Please Insert List Name")
            return
        }
        
        if createdList.contains(where: { (displayList) -> Bool in
            return displayList.name.lowercased() == listName.lowercased()
        }) {
            self.alert(title: "Duplicate List Name", message: "Please Insert Different List Name")
            return
        }
        
        completion(listName)
    }
    
    let addListView = UIView()
    let locationCellID = "locationCellID"
    let listNameCollectionView: UICollectionView = {
        let uploadLocationTagList = UploadLocationTagList()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadLocationTagList)
        return cv
    }()
    
    var userListHeight:NSLayoutConstraint?
    var fullListHeight:NSLayoutConstraint?

    lazy var tableView : UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        tv.estimatedRowHeight = 100
        tv.allowsMultipleSelection = false
        return tv
    }()
    
    var listOptions = ["Your Lists", "Sample Lists"]
    var listTypeSegment = UISegmentedControl()
    var selectedListType: String = "Your Lists" {
        didSet {
            listTypeSegment.selectedSegmentIndex = listOptions.firstIndex(of: selectedListType)!
            self.refreshAll()
        }
    }
    let buttonBar = UIView()
    var buttonBarPosition: NSLayoutConstraint?
    let listCellId = "listCellId"
    let uploadListCellId = "uploadListCellId"

    let cancelButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//        button.setImage(#imageLiteral(resourceName: "alert").withRenderingMode(.alwaysTemplate), for: .normal)
        //        button.layer.cornerRadius = button.frame.width/2
        button.tintColor = UIColor.ianLegitColor()
        //        button.layer.masksToBounds = true
        button.setTitle("Done", for: .normal)
        button.addTarget(self, action: #selector(handleLeave), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.borderColor = UIColor.gray.cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 30/2
        button.titleLabel?.textColor = UIColor.darkLegitColor()
        //        button.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        //        button.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        //        button.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        return button
    }()
    
    @objc func handleLeave(){
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
    
    let doneButton: UIButton = {
        let button = UIButton()
        button.setTitle("Done", for: .normal)
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
        
        button.addTarget(self, action: #selector(handleLeave), for: .touchUpInside)
        return button
    } ()
    
    
    
    fileprivate func setupNavigationItems() {
        navigationController?.isNavigationBarHidden = true
        
        navigationController?.navigationBar.barTintColor = UIColor.white
        navigationController?.navigationBar.tintColor = UIColor.ianLegitColor()

        let rectPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 5))
        UIColor.white.setFill()
        rectPath.fill()
        let finalImg = UIGraphicsGetImageFromCurrentImageContext()
        navigationController?.navigationBar.shadowImage = finalImg
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        
//         REMOVES THE 1PX BOTTOM LINE IN NAV BAR
        navigationController?.navigationBar.shadowImage = UIImage()
//        navigationItem.title = "NEW LIST"
        
        let headerTitle = NSAttributedString(string: "Add New List", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 18)])
        
        var attributedHeaderTitle = NSMutableAttributedString()
        attributedHeaderTitle.append(headerTitle)
        let navLabel = UILabel()
        navLabel.attributedText = attributedHeaderTitle
        navigationItem.titleView = navLabel
        
        let navBackButton = navBackButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        navBackButton.addTarget(self, action: #selector(handleBackPressNav), for: .touchUpInside)
        let barButton2 = UIBarButtonItem.init(customView: navBackButton)
        self.navigationItem.leftBarButtonItem = barButton2


        let navDoneButton = NavButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        navDoneButton.addTarget(self, action: #selector(handleLeave), for: .touchUpInside)
        let barButton1 = UIBarButtonItem.init(customView: navDoneButton)
        self.navigationItem.rightBarButtonItem = barButton1

        self.navigationController?.navigationBar.setNeedsLayout()
        self.navigationController?.navigationBar.layoutIfNeeded()
        self.navigationController?.navigationBar.setNeedsDisplay()
        
    }

    func createList(newList: List){
        // Create New List in Database
        Database.createList(uploadList: newList){}
    }
    
    
    
    @objc func handleBackPressNav(){
        //        guard let post = self.selectedPost else {return}
        self.handleBack()
    }
    
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor.backgroundGrayColor()
//        self.navigationController?.isNavigationBarHidden = false

        setupNavigationItems()
        
        self.view.addSubview(doneButton)
        doneButton.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 40, paddingBottom: 10, paddingRight: 40, width: 0, height: 50)
        doneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        doneButton.sizeToFit()
        
        view.addSubview(infoLabel)
        infoLabel.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
//        infoLabel.text = introString
        infoLabel.sizeToFit()
        
        view.addSubview(infoDetail)
        infoDetail.anchor(top: infoLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        //        infoLabel.text = introString
        infoLabel.sizeToFit()
    
    // ADD LIST VIEW
        view.addSubview(addListView)
        addListView.anchor(top: infoDetail.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 40)
        
        view.addSubview(addListButton)
        addListButton.anchor(top: nil, left: nil, bottom: nil, right: addListView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 80, height: 30)
        addListButton.centerYAnchor.constraint(equalTo: addListView.centerYAnchor).isActive = true

        
        view.addSubview(addListTextField)
        addListTextField.anchor(top: nil, left: addListView.leftAnchor, bottom: nil, right: addListButton.leftAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 5, width: 0, height: 30)
        addListTextField.centerYAnchor.constraint(equalTo: addListView.centerYAnchor).isActive = true
        addListTextField.placeholder = "New List Name Here"
        addListTextField.backgroundColor = UIColor.white
        
    // Add Places Collection View
        view.addSubview(listNameCollectionView)
        listNameCollectionView.anchor(top: addListView.bottomAnchor, left: addListView.leftAnchor, bottom: nil, right: addListView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        listNameCollectionView.bottomAnchor.constraint(lessThanOrEqualTo: doneButton.topAnchor, constant: 10)
        listNameCollectionView.backgroundColor = UIColor.clear
        listNameCollectionView.register(UploadLocationCell.self, forCellWithReuseIdentifier: locationCellID)
        listNameCollectionView.delegate = self
        listNameCollectionView.dataSource = self
        listNameCollectionView.showsHorizontalScrollIndicator = false
        
        
    // SORT SEGMENT
        
        let sortSegmentView = UIView()
        sortSegmentView.backgroundColor = UIColor.white
        view.addSubview(sortSegmentView)
//        sortSegmentView.anchor(top: listNameCollectionView.bottomAnchor, left: addListView.leftAnchor, bottom: nil, right: addListView.rightAnchor, paddingTop: 20, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 45)
        sortSegmentView.anchor(top: listNameCollectionView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 45)

        setupListTypeSegment()
        
        view.addSubview(listTypeSegment)
        listTypeSegment.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 40)
        listTypeSegment.centerYAnchor.constraint(equalTo: sortSegmentView.centerYAnchor).isActive = true
        listTypeSegment.backgroundColor = .white
        listTypeSegment.tintColor = .white
        listTypeSegment.layer.applySketchShadow()
        
        buttonBar.backgroundColor = UIColor.ianLegitColor()
        
        let segmentWidth = (self.view.frame.width - 30) / 2
        
        view.addSubview(buttonBar)
        buttonBar.anchor(top: nil, left: nil, bottom: listTypeSegment.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: segmentWidth, height: 5)
        buttonBar.leftAnchor.constraint(lessThanOrEqualTo: listTypeSegment.leftAnchor).isActive = true
        buttonBar.rightAnchor.constraint(lessThanOrEqualTo: listTypeSegment.rightAnchor).isActive = true
        buttonBarPosition = buttonBar.leftAnchor.constraint(equalTo: listTypeSegment.leftAnchor, constant: 5)
        buttonBarPosition?.isActive = true
        
        
        tableView.register(DiscoverListCellNew.self, forCellReuseIdentifier: listCellId)
        tableView.register(UploadPhotoToListCell.self, forCellReuseIdentifier: uploadListCellId)
        
        view.addSubview(tableView)
        tableView.anchor(top: sortSegmentView.bottomAnchor, left: view.leftAnchor, bottom: doneButton.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 0, height: 0)
        
//        userListHeight = tableView.heightAnchor.constraint(equalToConstant: 0)
//        fullListHeight = tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 20)
//        userListHeight?.isActive = true
//        fullListHeight?.isActive = false
        
//        tableView.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: 20).isActive = true
        
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshAll), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.alwaysBounceVertical = true
        tableView.keyboardDismissMode = .onDrag
        tableView.backgroundColor = UIColor.white
        
        
        self.fetchLists()
        self.selectedListType == listOptions[0]

    }
    
    func fetchLists() {
        Database.fetchALLLists { (allLists) in
            // Fetches All List that are not Legit/Bookmark and >0 Posts
            Database.sortList(inputList: allLists, sortInput: sortAuto, completion: { (lists) in
                self.sampleLists = lists
                print("SignUpNewListController | Fetch Lists | \(self.sampleLists.count)")
                self.tableView.reloadData()
            })
        }
    }
    
    func refreshAll(){
//        if self.selectedListType == listOptions[0]
//        {
//            userListHeight?.constant = CGFloat(self.createdList.count) * 60
//            userListHeight?.isActive = true
//            fullListHeight?.isActive = false
//        } else {
//            userListHeight?.isActive = false
//            fullListHeight?.isActive = true
//        }
        fullListHeight?.isActive = true

        self.tableView.reloadData()
        self.tableView.refreshControl?.endRefreshing()

    }
    
    func didTapCancel(tag: Int?) {
        guard let tag = tag else {return}
        let listName = createdList[tag]
        let message = "Confirm Delete \(listName)?"
        let alert = UIAlertController(title: "Delete List", message: message, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction!) in
            
            let oldList = self.createdList[tag]
            self.createdList.remove(at: tag)
            SVProgressHUD.showSuccess(withStatus: "Success Deleting \(oldList.name)")
            Database.deleteList(uploadList: oldList)
            self.refreshAll()
            NotificationCenter.default.post(name: TabListViewController.refreshListNotificationName, object: nil)
            
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: { (action: UIAlertAction!) in
            
            print("Canceled | Delete list called \(listName)")
        }))
        self.present(alert, animated: true, completion: nil)
        
        
    }
    
    
    
    func setupListTypeSegment(){
        //  Add Sort Options
        listTypeSegment = UISegmentedControl(items: listOptions)
        listTypeSegment.selectedSegmentIndex = listOptions.firstIndex(of: self.selectedListType)!
        listTypeSegment.addTarget(self, action: #selector(selectType), for: .valueChanged)
        //        headerSortSegment.tintColor = UIColor(hexColor: "107896")
        listTypeSegment.tintColor = UIColor.white
        listTypeSegment.backgroundColor = UIColor.white
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        listTypeSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: 16), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
        listTypeSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 16), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)
    }
    
    @objc func selectType(sender: UISegmentedControl) {
        self.selectedListType = listOptions[sender.selectedSegmentIndex]
        self.underlineSegment(segment: sender.selectedSegmentIndex)
//        self.refreshAll()
//        self.setupNavigationItems()
        
        //        delegate?.headerSortSelected(sort: self.selectedSort)
        print("Selected Type is ",self.selectedListType)
    }
    
    func underlineSegment(segment: Int? = 0){
        
        let segmentWidth = (self.view.frame.width - 30) / CGFloat(self.listTypeSegment.numberOfSegments)
        let tempX = self.buttonBar.frame.origin.x
        UIView.animate(withDuration: 0.3) {
            //            self.buttonBarPosition?.isActive = false
            self.buttonBar.frame.origin.x = segmentWidth * CGFloat(segment ?? 0) + 5
            self.buttonBarPosition?.constant = segmentWidth * CGFloat(segment ?? 0) + 5
            self.buttonBarPosition?.isActive = true
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return suggestListNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: locationCellID, for: indexPath) as! UploadLocationCell
        cell.uploadLocations.text = suggestListNames[indexPath.row]
        cell.backgroundColor = UIColor.white
        cell.uploadLocations.textColor = UIColor.black
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let name = suggestListNames[indexPath.row]
        self.addListTextField.text = name
        self.addList()
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if selectedListType == listOptions[0] {
            return self.createdList.count
        } else if selectedListType == listOptions[1] {
            return self.sampleLists.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if selectedListType == listOptions[0]
        {
            let list = self.createdList[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: uploadListCellId, for: indexPath) as! UploadPhotoToListCell
            cell.list = list
//            cell.listnameLabel.text = listName
            cell.selectionStyle = .none
            cell.listTag = indexPath.row
            cell.isUserInteractionEnabled = true
            cell.delegate = self
            cell.showCancel = true
            return cell
        }
            
        else if selectedListType == listOptions[1]
        {
            
            let testUser = User.init(uid: "TEST", dictionary: [:])
            let cell = tableView.dequeueReusableCell(withIdentifier: listCellId, for: indexPath) as! DiscoverListCellNew
            var currentList = sampleLists[indexPath.row]
            cell.list = currentList
            cell.isSelected = false
            cell.enableSelection = false
            cell.backgroundColor = UIColor.white
            cell.delegate = self
            cell.refUser = testUser
            cell.selectionStyle = .none
            cell.listFollowButton.isHidden = true
            cell.followerCountLabel.isHidden = true
            cell.largeFollowerCountLabel.isHidden = false
            cell.hideProfileImage = false
            cell.isUserInteractionEnabled = true

            return cell
        }
        else
        {
            let list = self.createdList[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: listCellId, for: indexPath) as! UploadPhotoToListCell
            cell.list = list
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if selectedListType == listOptions[1]
        {
            let selectedList = sampleLists[indexPath.row]
            self.goToList(list: selectedList, filter: nil)
            tableView.deselectRow(at: indexPath, animated: false)
        }

    }
    
    func goToList(list: List?, filter: String?) {
        guard let list = list else {return}
        let listViewController = ListViewController()
        listViewController.currentDisplayList = list
        listViewController.viewFilter?.filterCaption = filter
        listViewController.refreshPostsForFilter()
        print(" DISPLAYING | \(list.name) | \(list.id) | \(list.postIds?.count) Posts | \(filter) | SingUpNewList_ViewController")
//        self.present(listViewController, animated: true, completion: nil)
        self.navigationController?.pushViewController(listViewController, animated: true)
    }
    
    func goToPost(postId: String, ref_listId: String?, ref_userId: String?) {
        Database.fetchPostWithPostID(postId: postId) { (post, error) in
            if let error = error {
                print("TabListViewController | goToPost \(error)")
            } else {
                guard let post = post else {
                    self.alert(title: "Sorry", message: "Post Does Not Exist Anymore 😭")
                    if let listId = ref_listId {
                        print("TabListViewController | No More Post. Refreshing List to Update | ",listId)
                        Database.refreshListItems(listId: listId)
                    }
                    return
                }
                let pictureController = SinglePostView()
                pictureController.post = post
                self.navigationController?.pushViewController(pictureController, animated: true)
            }
        }
    }
    
    func displayListFollowingUsers(list: List, following: Bool) {
        print("Display Users| Following: ",list.id)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayUser = true
        postSocialController.displayUserFollowing = false
        postSocialController.inputList = list
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    func goToUser(userId: String?) {
        guard let userId = userId else {return}
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = userId
        self.navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    
    
    
}
