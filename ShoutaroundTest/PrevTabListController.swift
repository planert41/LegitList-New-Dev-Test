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


class PrevTabListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UISearchBarDelegate, DiscoverListCellNewDelegate, ListViewControllerDelegate, NewListCollectionViewDelegate {
    
    
    
    
    static let newListNotificationName = NSNotification.Name(rawValue: "NewListEvent")
    static let refreshListNotificationName = NSNotification.Name(rawValue: "RefreshList")
    
    var inputUserId: String? {
        didSet{
            self.setupLists()
            self.inputUser = nil
            if let userId = inputUserId {
                Database.fetchUserWithUID(uid: userId) { (user) in
                    self.inputUser = user
                }
            }
        }
    }
    
    var inputUser: User?
    
    var enableAddListNavButton: Bool = false {
        didSet {
            self.setupNavigationItems()
        }
    }
    
    var allUserList: [List] = []
    var displayList: [List] = []
    var filteredDisplayList: [List] = []
    
    var isFiltering: Bool = false {
        didSet{
            self.tableView.reloadData()
        }
    }
    
    let listCellId = "ListCellId"
    var tableEdit: Bool = false
    
    let addListView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    lazy var addListTextField: PaddedTextField = {
        let tf = PaddedTextField()
        tf.font = UIFont.systemFont(ofSize: 14.0)
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.legitColor().cgColor
        tf.backgroundColor = UIColor(white: 1, alpha: 0.03)
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.layer.cornerRadius = 10
        tf.layer.masksToBounds = true
        tf.placeholder = "Eg: Chicago, Ramen"
        tf.delegate = self
        return tf
    }()
    
    let addListButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add New List", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        
        //        button.setImage(#imageLiteral(resourceName: "add").withRenderingMode(.alwaysOriginal), for: .normal)
        //        button.imageView?.contentMode = .scaleAspectFit
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.lightSelectedColor()
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.darkLegitColor().cgColor
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        button.layer.cornerRadius = 10
        button.titleLabel?.textColor = UIColor.darkLegitColor()
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.tintColor = UIColor.darkLegitColor()
        button.addTarget(self, action: #selector(initAddList), for: .touchUpInside)
        return button
    } ()
    
    let addListNavButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        //        button.setImage(#imageLiteral(resourceName: "add_white_thick").withRenderingMode(.alwaysTemplate)), for: .normal)
        button.backgroundColor = UIColor.clear
        button.tintColor = UIColor.ianLegitColor()
        button.titleLabel?.font = UIFont(font: .avenirNextBold, size: 12)
        button.setTitle("New List", for: .normal)
        //        button.setTitleColor(UIColor.white, for: .normal)
        //        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        //        button.layer.borderColor = UIColor.lightSelectedColor().cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.addTarget(self, action: #selector(initAddList), for: .touchUpInside)
        return button
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
    
    var listTypeSegment = UISegmentedControl()
    var selectedListType: String = listTypeDefault {
        didSet {
            listTypeSegment.selectedSegmentIndex = listTypeOptions.firstIndex(of: selectedListType)!
            self.refreshAll()
        }
    }
    
    lazy var listSortButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(showDropDown), for: .touchUpInside)
        //        button.layer.backgroundColor = UIColor.darkLegitColor().withAlphaComponent(0.8).cgColor
        //        button.layer.backgroundColor = UIColor.lightSelectedColor().cgColor
        button.layer.backgroundColor = UIColor.white.cgColor
        
        //        button.setTitleColor(UIColor(hexColor: "f10f3c"), for: .normal)
        //        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 13)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.ianLegitColor().cgColor
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        return button
    }()
    
    var sortOptions: [String] = ListSortOptions
    var selectedSort: String = ListSortDefault {
        didSet{
            self.displaySort(sort: selectedSort)
            //            self.listSortButton.setTitle(selectedSort + "  ", for: .normal)
        }
    }
    
    func displaySort(sort: String?) {
        guard let sort = sort else {return}
        var attributedTitle = NSMutableAttributedString()
        
        let sortTitle = NSAttributedString(string: sort + "  ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 13)])
        attributedTitle.append(sortTitle)
        
        guard let legitIcon = #imageLiteral(resourceName: "iconDropdown").withRenderingMode(.alwaysOriginal).resizeVI(newSize: CGSize(width: 12, height: 12)) else {return}
        let legitImage = NSTextAttachment()
        legitImage.bounds = CGRect(x: 0, y: ((listSortButton.titleLabel?.font.capHeight)! - legitIcon.size.height).rounded() / 2, width: legitIcon.size.width, height: legitIcon.size.height)
        legitImage.image = legitIcon
        let legitImageString = NSAttributedString(attachment: legitImage)
        attributedTitle.append(legitImageString)
        self.listSortButton.setAttributedTitle(attributedTitle, for: .normal)
        
        
        
    }
    
    
    
    var dropDownMenu = DropDown()
    func setupDropDown(){
        dropDownMenu.anchorView = listSortButton
        dropDownMenu.dismissMode = .automatic
        dropDownMenu.textColor = UIColor.ianLegitColor()
        dropDownMenu.textFont = UIFont(name: "Poppins-Bold", size: 17)!
        dropDownMenu.backgroundColor = UIColor.white
        //        dropDownMenu.selectionBackgroundColor = UIColor.ianLegitColor().withAlphaComponent(0.75)
        dropDownMenu.selectionBackgroundColor = UIColor.ianOrangeColor().withAlphaComponent(0.75)
        
        dropDownMenu.cellHeight = 50
        dropDownMenu.cornerRadius = 5
        dropDownMenu.shadowColor = UIColor.gray
        dropDownMenu.layer.applySketchShadow(
            color: UIColor.rgb(red: 0, green: 0, blue: 0),
            alpha: 0.5,
            x: 0,
            y: 2,
            blur: 10,
            spread: 0)
        
        //        dropDownMenu.selectRow(0)
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        //        self.updateDropDownCount()
        
        dropDownMenu.dataSource = ListSortOptions
        dropDownMenu.selectionAction = { [unowned self] (index: Int, item: String) in
            print("Selected item: \(item) at index: \(index)")
            self.selectedSort = self.dropDownMenu.dataSource[index]
            //            self.listSortButton.setTitle(self.selectedSort, for: .normal)
            self.sortLists()
            self.dropDownMenu.hide()
            
        }
        
        if let index = self.dropDownMenu.dataSource.firstIndex(of: self.selectedSort) {
            print("DropDown Menu Preselect \(index) \(self.dropDownMenu.dataSource[index])")
            dropDownMenu.selectRow(index)
        }
    }
    var createdListCount: Int = 0
    var followingListCount: Int = 0
    
    @objc func showDropDown(){
        if self.dropDownMenu.isHidden{
            self.dropDownMenu.show()
        } else {
            self.dropDownMenu.hide()
        }
    }
    
    func updateDropDownCount(){
        var tempOptions: [String] = []
        var totalLists = self.createdListCount + self.followingListCount ?? 0
        
        for (index, temp) in listTypeOptions.enumerated() {
            if index == 0 {
                var inputString = temp + (self.createdListCount > 0 ? " : \(self.createdListCount)" : "")
                tempOptions.append(inputString)
            } else if index == 2 {
                var inputString = temp + (self.followingListCount > 0 ? " : \(self.followingListCount)" : "")
                tempOptions.append(inputString)
            }
        }
        var selectedIndex = dropDownMenu.dataSource.firstIndex(of: self.selectedListType) ?? 0
        
        dropDownMenu.dataSource = tempOptions
        if tempOptions[selectedIndex] != self.listSortButton.titleLabel?.text {
            self.listSortButton.setTitle(tempOptions[selectedIndex], for: .normal)
        }
        
    }
    
    
    let buttonBar = UIView()
    var buttonBarPosition: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationItems()
        
//        NotificationCenter.default.addObserver(self, selector: #selector(newListEventRefresh), name: TabListViewController.newListNotificationName, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(refreshAll), name: TabListViewController.refreshListNotificationName, object: nil)
//        //        NotificationCenter.default.addObserver(self, selector: #selector(refreshAll), name: SharePhotoListController.updateListFeedNotificationName, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(refreshAll), name: ListViewController.refreshListViewNotificationName, object: nil)
//        
//        
        
        let sortSegmentView = UIView()
        sortSegmentView.backgroundColor = UIColor.white
        view.addSubview(sortSegmentView)
        sortSegmentView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 45)
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
        
        
        view.addSubview(addListView)
        addListView.anchor(top: sortSegmentView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        addListView.backgroundColor = UIColor.backgroundGrayColor()
        
        //        view.addSubview(addListButton)
        //        addListButton.anchor(top: nil, left: nil, bottom: nil, right: addListView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 80, height: 30)
        //        addListButton.centerYAnchor.constraint(equalTo: addListView.centerYAnchor).isActive = true
        
        view.addSubview(listSortButton)
        listSortButton.anchor(top: addListView.topAnchor, left: nil, bottom: addListView.bottomAnchor, right: addListView.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 10, width: 0, height: 30)
        listSortButton.setTitle(self.selectedSort, for: .normal)
        listSortButton.sizeToFit()
        self.displaySort(sort: self.selectedSort)
        
        view.addSubview(searchBar)
        searchBar.anchor(top: addListView.topAnchor, left: addListView.leftAnchor, bottom: addListView.bottomAnchor, right: listSortButton.leftAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 0, height: 0)
        
        setupSearchBar()
        
        
        tableView.register(DiscoverListCellNew.self, forCellReuseIdentifier: listCellId)
        
        view.addSubview(tableView)
        tableView.anchor(top: addListView.bottomAnchor, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshAll), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.alwaysBounceVertical = true
        tableView.keyboardDismissMode = .onDrag
        tableView.backgroundColor = UIColor.backgroundGrayColor()
        
        
        view.addSubview(dropDownMenu)
        dropDownMenu.anchor(top: addListView.bottomAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        self.setupDropDown()
        
        
        //        setupLists()
        
        
        //        view.addSubview(addListTextField)
        //        addListTextField.anchor(top: nil, left: addListView.leftAnchor, bottom: nil, right: addListButton.leftAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 5, width: 0, height: 30)
        //        addListTextField.centerYAnchor.constraint(equalTo: addListView.centerYAnchor).isActive = true
        //        addListTextField.placeholder = "ex: Chicago, Ramen, Travel"
        //        addListTextField.backgroundColor = UIColor.white
        
        //        tableView.register(TestListCell.self, forCellReuseIdentifier: listCellId)
        //        tableView.register(UploadListCell.self, forCellReuseIdentifier: listCellId)
        
    }
    
    
    func setupListTypeSegment(){
        //  Add Sort Options
        listTypeSegment = UISegmentedControl(items: listTypeOptions)
        listTypeSegment.selectedSegmentIndex = listTypeOptions.firstIndex(of: self.selectedListType)!
        listTypeSegment.addTarget(self, action: #selector(selectType), for: .valueChanged)
        //        headerSortSegment.tintColor = UIColor(hexColor: "107896")
        listTypeSegment.tintColor = UIColor.white
        listTypeSegment.backgroundColor = UIColor.white
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        listTypeSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: 16), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
        listTypeSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 16), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)
    }
    
    func refreshListTypeSegmentCount(){
        var tempOptions = listTypeOptions
        let newListEvents = CurrentUser.listEvents.count ?? 0
        
        tempOptions[0] = (self.inputUserId == Auth.auth().currentUser?.uid) ? "My Lists" : "Created"
        
        //        if self.createdListCount > 0 {
        //            tempOptions[1] = tempOptions[1] + ": \(String(self.createdListCount))"
        //        }
        //
        //        if self.followingListCount > 0 {
        //            tempOptions[2] = listTypeOptions[2] + ": \(String(self.followingListCount))"
        //        }
        //
        if newListEvents > 0 {
            tempOptions[1] = tempOptions[1]  + " (\(newListEvents))"
        }
        //
        //        if listTypeSegment.numberOfSegments > 2 {
        //            listTypeSegment.setTitle(tempOptions[1] , forSegmentAt: 1)
        //            listTypeSegment.setTitle(tempOptions[2] , forSegmentAt: 2)
        //        }
        
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
    
    @objc func selectType(sender: UISegmentedControl) {
        self.selectedListType = listTypeOptions[sender.selectedSegmentIndex]
        self.underlineSegment(segment: sender.selectedSegmentIndex)
        self.refreshAll()
        self.setupNavigationItems()
        
        //        delegate?.headerSortSelected(sort: self.selectedSort)
        print("Selected Type is ",self.selectedListType)
    }
    
    func setupNavigationItems(){
        //        navigationItem.title = "Manage Lists"
        
        self.navigationController?.view.backgroundColor = UIColor.white
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationController?.navigationBar.tintColor = UIColor.ianLegitColor()
        self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.ianLegitColor(), NSAttributedString.Key.font.rawValue: UIFont(name: "Poppins-Bold", size: 18)])
        self.navigationController?.navigationBar.layoutIfNeeded()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        
        // NAVIGATION TITLE
        var listCount = ""
        if self.listTypeSegment.selectedSegmentIndex == 0 {
            listCount = String(self.createdListCount + self.followingListCount)
        } else if self.listTypeSegment.selectedSegmentIndex == 1 {
            listCount = String(self.createdListCount)
        } else if self.listTypeSegment.selectedSegmentIndex == 2 {
            listCount = String(self.followingListCount)
        }
        
        if (listCount == "" || listCount == "0") {
            self.navigationItem.title = "Lists"
        } else {
            self.navigationItem.title = "\(listCount) Lists"
        }
        
        if self.tableView.isEditing {
            self.navigationItem.title = "Delete Lists"
        }
        
        let tempNavUserProfileBarButton = NavUserProfileButton.init(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        tempNavUserProfileBarButton.setProfileImage(imageUrl: CurrentUser.user?.profileImageUrl)
        tempNavUserProfileBarButton.addTarget(self, action: #selector(didTapUser), for: .touchUpInside)
        let barButton2 = UIBarButtonItem.init(customView: tempNavUserProfileBarButton)
        navigationItem.rightBarButtonItem = barButton2
        
        // MUST LEAVE LEFT BAR FOR BACK BUTTON IF NOT TABLISTVIEW
        if self.enableAddListNavButton && (self.inputUserId == Auth.auth().currentUser?.uid || (Auth.auth().currentUser?.isAnonymous ?? false)){
            addListNavButton.addTarget(self, action: #selector(initAddList), for: .touchUpInside)
            
            let title = NSMutableAttributedString()
            let navTitle = NSAttributedString(string: "+ ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextBold, size: 20)])
            title.append(navTitle)
            
            let navString = NSAttributedString(string: "NEW LIST", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextBold, size: 10)])
            title.append(navString)
            
            addListNavButton.setAttributedTitle(title, for: .normal)
            let barButton1 = UIBarButtonItem.init(customView: addListNavButton)
            navigationItem.leftBarButtonItem = barButton1
        } else {
            // Nav Back Buttons
            let navBackButton = navBackButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            navBackButton.addTarget(self, action: #selector(handleBackPressNav), for: .touchUpInside)
            let barButton2 = UIBarButtonItem.init(customView: navBackButton)
            self.navigationItem.leftBarButtonItem = barButton2
        }
        
    }
    
    @objc func handleBackPressNav(){
        //        guard let post = self.selectedPost else {return}
        self.handleBack()
    }
    
    
    @objc func didTapUser(){
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = self.inputUserId
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    
    let userProfileRightBarButton: CustomImageView = {
        
        let iv = CustomImageView()
        iv.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 30/2
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 2
        return iv
        
    }()
    
    func userOptionList(){
        
        let optionsAlert = UIAlertController(title: "User Options", message: "", preferredStyle: UIAlertController.Style.alert)
        
        optionsAlert.addAction(UIAlertAction(title: "Create New List", style: .default, handler: { (action: UIAlertAction!) in
            self.initAddList()
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Delete List", style: .default, handler: { (action: UIAlertAction!) in
            // Allow Editing
            self.editList()
        }))
        
        
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
            self.tableView.setEditing(false, animated: true)
        }))
        
        present(optionsAlert, animated: true) {
            optionsAlert.view.superview?.isUserInteractionEnabled = true
            optionsAlert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.alertClose(gesture:))))
        }
        
    }
    
    func doneEditing(){
        self.tableView.setEditing(false, animated: true)
        self.tableView.reloadData()
    }
    
    let searchBarPlaceholder = "Search List"
    
    
    func setupSearchBar(){
        searchBar.delegate = self
        searchBar.isTranslucent = true
        searchBar.searchBarStyle = .prominent
        searchBar.barTintColor = UIColor.white
        searchBar.tintColor = UIColor.white
        searchBar.layer.borderWidth = 1
        searchBar.layer.borderColor = UIColor.lightGray.cgColor
        searchBar.layer.cornerRadius = 5
        
        definesPresentationContext = false
        
        searchBar.layer.masksToBounds = true
        searchBar.clipsToBounds = true
        
        //        var iconImage = #imageLiteral(resourceName: "search_tab_fill").withRenderingMode(.alwaysTemplate)
        //        searchBar.setImage(iconImage, for: .search, state: .normal)
        searchBar.setSerchTextcolor(color: UIColor.ianLegitColor())
        var searchTextField: UITextField? = searchBar.value(forKey: "searchField") as? UITextField
        if searchTextField!.responds(to: #selector(getter: UITextField.attributedPlaceholder)) {
            let attributeDict = [NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont(font: .avenirNextItalic, size: 14)]
            searchTextField!.attributedPlaceholder = NSAttributedString(string: searchBarPlaceholder, attributes: attributeDict)
        }
        
        let textFieldInsideUISearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.textColor = UIColor.ianLegitColor()
        //        textFieldInsideUISearchBar?.font = textFieldInsideUISearchBar?.font?.withSize(12)
        
        
        for s in searchBar.subviews[0].subviews {
            if s is UITextField {
                //                s.layer.borderWidth = 0.5
                //                s.layer.borderColor = UIColor.gray.cgColor
                //                s.layer.cornerRadius = 5
                //                s.layer.masksToBounds = true
                s.layer.backgroundColor = UIColor.clear.cgColor
                s.backgroundColor = UIColor.white
            }
        }
        
    }
    
    //    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
    //        if searchBar.text == searchBarPlaceholder {
    //            self.searchBar.text = nil
    //        }
    //        return true
    //    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText.count == 0) {
            self.isFiltering = false
        } else {
            filterContentForSearchText(searchBar.text!)
        }
    }
    
    @objc func filterContentForSearchText(_ searchText: String) {
        // Filter List Table View
        self.isFiltering = searchText.count != 0
        let searchTerms = searchText.lowercased().components(separatedBy: " ")
        
        filteredDisplayList = displayList.filter({ (list) -> Bool in
            var emojiTranslateArray: [String] = []
            var emojiFilter = false
            for term in searchTerms {
                for text in list.topEmojis {
                    if let word = EmojiDictionary[text] {
                        if word.contains(term){
                            emojiFilter = true
                        }
                    }
                }
                
                if list.name.lowercased().contains(term) || list.topEmojis.contains(term) {
                    emojiFilter = true
                }
            }
            
            return list.name.lowercased().contains(searchText.lowercased()) || list.topEmojis.contains(searchText.lowercased()) || emojiFilter
        })
        filteredDisplayList.sort { (p1, p2) -> Bool in
            ((p1.name.hasPrefix(searchText.lowercased())) ? 0 : 1) < ((p2.name.hasPrefix(searchText.lowercased())) ? 0 : 1)
        }
        self.tableView.reloadData()
    }
    
    
    @objc func editList(){
        if !self.tableEdit{
            self.tableView.setEditing(true, animated: true)
            print("Table Editing")
        } else {
            self.tableView.setEditing(false, animated: true)
            print("Table Not Editing")
        }
        self.tableEdit = !self.tableEdit
        setupNavigationItems()
    }
    
    @objc func newListEventRefresh(){
        self.refreshListTypeSegmentCount()
        if self.isViewLoaded && self.view.window != nil {
            //Currently Active. Don't Refresh
            print("TabListViewController | newListEventRefresh | Being Viewed, Don't Refresh")
            
        } else {
            print("TabListViewController | newListEventRefresh")
            self.refreshAll()
        }
    }
    
    var isRefreshing = false
    @objc func refreshAll(){
        print("TabListViewController | Refresh All")
        
        if isRefreshing {
            print(" *** BUSY | TabList Refreshing")
            return
        }
        
        guard let uid = self.inputUserId else {return}
        // Fetching Current User Refetches all the lists for user and pulls from updated list cache
        
        if uid == Auth.auth().currentUser?.uid {
            Database.updateCurrentUserList(uid: uid) {
                self.setupLists()
            }
        } else {
            self.setupLists()
        }
        
        
        //        Database.loadCurrentUser(inputUser: nil) {
        //            self.setupLists()
        //        }
    }
    
    
    
    @objc func refreshList(){
        self.inputUserId = Auth.auth().currentUser?.uid
        self.tableView.reloadData()
        self.tableView.refreshControl?.endRefreshing()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //        collectionView.collectionViewLayout.invalidateLayout()
        //        collectionView.layoutIfNeeded()
        self.navigationController?.isNavigationBarHidden = false
        self.setupNavigationItems()
        self.refreshListTypeSegmentCount()
        //        self.setupLists()
    }
    
    func filterList(inputList: [List]) -> [List] {
        guard let uid = inputUserId else {return []}
        if self.selectedListType.contains(listAll) {
            return inputList
        } else if self.selectedListType.contains(listFollowed) {
            return inputList.filter({ (list) -> Bool in
                list.creatorUID != uid
            })
        } else if self.selectedListType.contains(listCreated) {
            return inputList.filter({ (list) -> Bool in
                list.creatorUID == uid
            })
        } else {
            return []
        }
    }
    
    func sortLists(){
        Database.sortList(inputList: self.displayList, sortInput: self.selectedSort, completion: { (sortedList) in
            self.displayList = self.filterList(inputList: sortedList)
            self.filterContentForSearchText(self.searchBar.text!)
            self.tableView.refreshControl?.endRefreshing()
            self.tableView.reloadData()
        })
    }
    
    func setupLists(){
        //        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        //        var inputUserId: String?
        //
        //        if (Auth.auth().currentUser?.isAnonymous)! {
        //            print("TabListViewController | fetchListIds | Guest User | Defaulting to WZ")
        //            inputUserId = "2G76XbYQS8Z7bojJRrImqpuJ7pz2"
        //        } else {
        //            inputUserId = self.inputUserId
        //        }
        
        guard let inputUserId = self.inputUserId else {
            print("TabListViewController | setupLists | No User ID | \(self.inputUserId)")
            return
        }
        
        print("TabList | Setting Up List For \(inputUserId)")
        Database.fetchAllListsForUser(userUid: inputUserId) { (fetchedLists) in
            
            var tempList = fetchedLists
            self.createdListCount = 0
            self.followingListCount = 0
            
            for list in tempList {
                if list.creatorUID == inputUserId {
                    self.createdListCount += 1
                } else {
                    self.followingListCount += 1
                }
            }
            
            let newNotificationCount = tempList.filter({ (list) -> Bool in
                return list.newNotificationsCount > 0
            }).count ?? 0
            
            
            //            self.updateDropDownCount()
            //            print("FetchedLists | Created \(self.createdListCount) | Following: \(self.followingListCount)")
            
            self.displayList = tempList ?? []
            self.tableView.refreshControl?.endRefreshing()
            self.sortLists()
            print("TabListViewController | setupLists | \(self.displayList.count) Lists | \(newNotificationCount) New List Notifications")
            self.isRefreshing = false
            self.refreshListTypeSegmentCount()
        }
        
        //
        //        if self.inputUserId == uid {
        //            // Displaying Current User List
        //            Database.loadCurrentUser(inputUser: nil) {
        //            // Fetching Current User fetches all lists
        //                self.displayLists(lists: CurrentUser.lists)
        //            }
        //        } else {
        //            Database.fetchUserWithUID(uid: inputUserId) { (user) in
        //                guard let user = user else {
        //                    print("TabListViewController | Setup List Error | No User Fetched | \(inputUserId)")
        //                    return
        //                }
        //
        //                Database.fetchListForMultListIds(listUid: user.listIds, completion: { (fetchedLists) in
        //                    self.displayLists(lists: fetchedLists)
        //                })
        //            }
        //        }
    }
    
    
    func deleteList(list:List?) {
        guard let list = list else {return}
        guard let listId = list.id else {return}
        
        print("TabListViewController | Deleting List \(list.id) from view")
        if let deleteIndex = self.displayList.firstIndex(where: {$0.id == listId}) {
            self.displayList.remove(at: deleteIndex)
        }
        
        if let deleteIndex = self.filteredDisplayList.firstIndex(where: {$0.id == listId}) {
            self.filteredDisplayList.remove(at: deleteIndex)
        }
        
        self.tableView.reloadData()
        
    }
    
    func listSelected(list: List?) {
        self.goToList(list: list, filter: nil)
    }
    
    func goToList(list: List?, filter: String?) {
        guard let list = list else {return}
        //        let listViewController = ListViewController()
        //        let listViewController = NewListViewController()
        let listViewController = NewListCollectionView()
        
        listViewController.currentDisplayList = list
        listViewController.viewFilter?.filterCaption = filter
        listViewController.refreshPostsForFilter()
        listViewController.delegate = self
        print(" TabListViewController | DISPLAYING | \(list.name) | \(list.id) | \(list.postIds?.count) Posts | \(filter) | List_ViewController")
        
        //        self.present(listViewController, animated: true, completion: nil)
        self.navigationController?.pushViewController(listViewController, animated: true)
        if list.newNotificationsCount > 0 {
            self.saveListInteraction(list: list)
        }
        
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
                        //                        Database.refreshListItems(listId: listId)
                    }
                    return
                }
                let pictureController = SinglePostView()
                pictureController.post = post
                self.navigationController?.pushViewController(pictureController, animated: true)
            }
        }
    }
    
    
    func goToUser(userId: String?) {
        guard let userId = userId else {return}
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.displayUserId = userId
        self.navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func displayListFollowingUsers(list: List, following: Bool) {
        print("Display Users| Following: ",list.id)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayUser = true
        postSocialController.displayUserFollowing = false
        postSocialController.inputList = list
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    
    func displayLists(lists: [List]?){
        
        print("TabList | Displaying \(lists?.count) Lists")
        
        //        if let lists = lists {
        //            self.displayList = lists
        //            self.tableView.reloadData()
        //        }
        
        
        guard let lists = lists else {
            self.displayList = []
            self.tableView.reloadData()
            print("TabListViewController | Error | No Lists To Display")
            return
        }
        
        Database.sortList(inputList: lists, sortInput: self.selectedSort, completion: { (sortedList) in
            self.displayList = sortedList
            self.tableView.reloadData()
        }
        )
    }
    
    func sortList(inputList: [List]?, sortInput: String? = ListSortDefault, completion: @escaping ([List]) -> ()){
        
        var tempList: [List] = []
        guard let inputList = inputList else {
            print("Sort List: ERROR, No List")
            completion([])
            return
        }
        
        if sortInput == ListSortOptions[0] {
            // Auto Sort - Legit and Bookmark First, then number of posts
            // Idea is that the list with the most posts are likely the oldest
            inputList.sorted(by: { (p1, p2) -> Bool in
                let p1Count = p1.postIds?.count ?? 0
                let p2Count = p2.postIds?.count ?? 0
                return p1Count >= p2Count
            })
            
            // Check For Legit
            if let index = inputList.firstIndex(where: {$0.name == legitListName}){
                tempList.append(inputList[index])
            }
            
            //Check For Bookmark
            if let index = inputList.firstIndex(where: {$0.name == bookmarkListName}){
                tempList.append(inputList[index])
            }
            
            // Add Others
            for list in inputList {
                if !tempList.contains(where: {$0.id == list.id}){
                    tempList.append(list)
                }
            }
        } else if sortInput == ListSortOptions[1]{
            // Sort by Most Recent Modified Date - New Lists would have creation date as most recent
            tempList = inputList.sorted(by: { (p1, p2) -> Bool in
                return p1.mostRecentDate.compare(p2.mostRecentDate) == .orderedDescending
            })
        } else if sortInput == ListSortOptions[2]{
            // Sort by Most Cred - Most Cred likely also has the most posts
            tempList = inputList.sorted(by: { (p1, p2) -> Bool in
                let p1Count = p1.totalCred ?? 0
                let p2Count = p2.totalCred ?? 0
                return p1Count >= p2Count
            })
        }
        
        completion(tempList)
        
    }
    
    @objc func initAddList(){
        if (Auth.auth().currentUser?.isAnonymous)! {
            print("Guest User")
            var message = "Please Sign Up To Create Your Own List"
            
            let alert = UIAlertController(title: "Guest Profile", message: message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            alert.addAction(UIAlertAction(title: "Sign Up", style: UIAlertAction.Style.cancel, handler: { (action: UIAlertAction!) in
                
                DispatchQueue.main.async {
                    let signUpController = SignUpController()
                    let loginController = LoginController()
                    let navController = UINavigationController(rootViewController: loginController)
                    navController.pushViewController(signUpController, animated: false)
                    self.present(navController, animated: true, completion: nil)
                }
            }))
            
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        let newList = CreateNewListController()
        let tempLists = CurrentUser.lists.filter { (list) -> Bool in
            return list.creatorUID == Auth.auth().currentUser?.uid
        }
        print("Passing \(tempLists.count) Lists From \(CurrentUser.username)")
        newList.createdList = tempLists
        let testNav = UINavigationController(rootViewController: newList)
        
        self.present(testNav, animated: true, completion: nil)
    }
    
    
    @objc func initAddListOld(){
        if (Auth.auth().currentUser?.isAnonymous)! {
            print("Guest User")
            var message = "Please Sign Up To Create Your Own List"
            
            let alert = UIAlertController(title: "Guest Profile", message: message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            alert.addAction(UIAlertAction(title: "Sign Up", style: UIAlertAction.Style.cancel, handler: { (action: UIAlertAction!) in
                
                DispatchQueue.main.async {
                    let signUpController = SignUpController()
                    let loginController = LoginController()
                    let navController = UINavigationController(rootViewController: loginController)
                    navController.pushViewController(signUpController, animated: false)
                    self.present(navController, animated: true, completion: nil)
                }
            }))
            
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Create A New List", message: "Enter New List Name", preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.text = ""
        }
        
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            print("New List Name: \(textField?.text)")
            
            let listId = NSUUID().uuidString
            guard let uid = Auth.auth().currentUser?.uid else {return}
            self.checkListName(listName: textField?.text) { (listName) in
                
                let newList = List.init(id: listId, name: listName, publicList: 1)
                self.createList(newList: newList)
                
                //                let optionsAlert = UIAlertController(title: "Create New List", message: "", preferredStyle: UIAlertController.Style.alert)
                //
                //                optionsAlert.addAction(UIAlertAction(title: "Public", style: .default, handler: { (action: UIAlertAction!) in
                //                    // Create Public List
                //                    let newList = List.init(id: listId, name: listName, publicList: 1)
                //                    self.createList(newList: newList)
                //                }))
                //
                //                optionsAlert.addAction(UIAlertAction(title: "Private", style: .default, handler: { (action: UIAlertAction!) in
                //                    // Create Private List
                //                    let newList = List.init(id: listId, name: listName, publicList: 0)
                //                    self.createList(newList: newList)
                //                }))
                //
                //                optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                //                    print("Handle Cancel Logic here")
                //                }))
                //                self.present(optionsAlert, animated: true, completion: {
                //                    self.addListTextField.resignFirstResponder()
                //                })
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func addList(){
        let listId = NSUUID().uuidString
        guard let uid = Auth.auth().currentUser?.uid else {return}
        checkListName(listName: addListTextField.text) { (listName) in
            
            let optionsAlert = UIAlertController(title: "Create New List", message: "", preferredStyle: UIAlertController.Style.alert)
            
            optionsAlert.addAction(UIAlertAction(title: "Public", style: .default, handler: { (action: UIAlertAction!) in
                // Create Public List
                let newList = List.init(id: listId, name: listName, publicList: 1)
                self.createList(newList: newList)
            }))
            
            optionsAlert.addAction(UIAlertAction(title: "Private", style: .default, handler: { (action: UIAlertAction!) in
                // Create Private List
                let newList = List.init(id: listId, name: listName, publicList: 0)
                self.createList(newList: newList)
            }))
            
            optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                print("Handle Cancel Logic here")
            }))
            self.present(optionsAlert, animated: true, completion: {
                self.addListTextField.resignFirstResponder()
            })
        }
    }
    
    func createList(newList: List){
        // Create New List in Database
        Database.createList(uploadList: newList){}
        
        self.displayList.insert(newList, at: 0)
        self.tableView.reloadData()
        self.addListTextField.text?.removeAll()
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
        
        if displayList.contains(where: { (displayList) -> Bool in
            return displayList.name.lowercased() == listName.lowercased()
        }) {
            self.alert(title: "Duplicate List Name", message: "Please Insert Different List Name")
            return
        }
        
        completion(listName)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        addListTextField.resignFirstResponder()
        self.addList()
        return true
    }
    
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isFiltering ? filteredDisplayList.count : displayList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: listCellId, for: indexPath) as! DiscoverListCellNew
        var currentList = isFiltering ? filteredDisplayList[indexPath.row] : displayList[indexPath.row]
        cell.list = currentList
        cell.isSelected = false
        cell.enableSelection = false
        cell.hideProfileImage = true
        cell.backgroundColor = UIColor.white
        cell.delegate = self
        cell.refUser = CurrentUser.user
        cell.selectionStyle = .none
        return cell
        
        
        //        let cell = tableView.dequeueReusableCell(withIdentifier: listCellId, for: indexPath) as! DiscoverListCell
        //        let currentList = isFiltering ? filteredDisplayList[indexPath.row] : displayList[indexPath.row]
        //
        //        cell.refUser = CurrentUser.user
        //        cell.list = currentList
        //        cell.isSelected = false
        //        cell.backgroundColor = UIColor.white
        //        cell.isListManage = true
        
        
        // select/deselect the cell
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
        let selectedList = self.isFiltering ? filteredDisplayList[indexPath.row] : displayList[indexPath.row]
        self.searchBar.resignFirstResponder()
        self.listSelected(list: selectedList)
    }
    
    func saveListInteraction(list: List?) {
        guard let list = list else {return}
        if list.newNotifications.count == 0 {
            return
        }
        list.clearAllNotifications()
        Database.updateListInteraction(list: list)
        
        self.setupLists()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        //        displayList[indexPath.row].isSelected = false
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70 + 90
    }
    
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        // Prevents Full Swipe Delete
        if tableView.isEditing{
            return .delete
        }
        return .none
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        //        print("Trigger")
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            // Check For Default List
            if (defaultListNames.contains(where: { (listNames) -> Bool in
                listNames == self.displayList[indexPath.row].name})){
                self.alert(title: "Delete List Error", message: "Cannot Delete Default List: \(self.displayList[indexPath.row].name)")
                return
            }
            var list = self.displayList[indexPath.row]
            
            self.displayList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            // Delete List in Database
            Database.deleteList(uploadList: list)
            
        }
        
        let edit = UITableViewRowAction(style: .default, title: "Edit") { (action, indexPath) in
            // Check For Default List
            if (defaultListNames.contains(where: { (listNames) -> Bool in
                listNames == self.displayList[indexPath.row].name})){
                self.alert(title: "Edit List Error", message: "Cannot Edit Default List: \(self.displayList[indexPath.row].name)")
                return
            }
            
            print("I want to change: \(self.displayList[indexPath.row])")
            
            
            //1. Create the alert controller.
            let alert = UIAlertController(title: "Change List Name", message: "Enter a New Name", preferredStyle: .alert)
            
            //2. Add the text field. You can configure it however you need.
            alert.addTextField { (textField) in
                textField.text = self.displayList[indexPath.row].name
            }
            
            // 3. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
                print("Text field: \(textField?.text)")
                
                // Change List Name
                self.checkListName(listName: textField?.text, completion: { (listName) in
                    self.displayList[indexPath.row].name = listName
                    self.tableView.reloadData()
                    
                    var list = self.displayList[indexPath.row]
                    
                    // Replace Database List
                    Database.createList(uploadList: list){}
                    
                    // Update Current User
                    if let listIndex = CurrentUser.lists.firstIndex(where: { (currentList) -> Bool in
                        currentList.id == list.id
                    }) {
                        CurrentUser.lists[listIndex].name = listName
                    }
                })
            }))
            
            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
            
            
        }
        
        edit.backgroundColor = UIColor.lightGray
        return [delete, edit]
        
    }
    
    
    
    
    
    
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input = input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
