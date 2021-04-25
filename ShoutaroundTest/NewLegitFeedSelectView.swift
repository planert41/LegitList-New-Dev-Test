//
//  NewLegitFeedSelectView.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 12/30/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit


class NewLegitFeedSelectView: UIView {

    var delegate: LegitNavHeaderDelegate?
        
      lazy var navFeedTypeLabel: UILabel = {
          let ul = UILabel()
          ul.isUserInteractionEnabled = true
          ul.numberOfLines = 0
          ul.textAlignment = NSTextAlignment.left
          ul.font = UIFont(name: "Poppins-Bold", size: 25)
          ul.textColor = UIColor.ianBlackColor()
          return ul
      }()
      
      lazy var navFeedTypeButton: UIButton = {
          let button = UIButton(type: .system)
          let img = #imageLiteral(resourceName: "dropdownXLarge")
          button.setImage(img.withRenderingMode(.alwaysTemplate), for: .normal)
          button.imageView?.contentMode = .scaleAspectFill
          button.tintColor = UIColor.gray
          button.addTarget(self, action: #selector(toggleNavFeedType), for: .touchUpInside)
          return button
      }()
      
    let notificationButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "alert").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.darkGray
        button.setTitle("", for: .normal)
        button.addTarget(self, action: #selector(openNotifications), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.borderColor = UIColor.gray.cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 30/2
        button.titleLabel?.textColor = UIColor.ianLegitColor()
        return button
    }()
    
    @objc func openNotifications(){
        self.delegate?.didTapNotification()
    }
    
    let notificationLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 15, y: -5, width: 15, height: 15))
        label.layer.borderColor = UIColor.clear.cgColor
        label.layer.borderWidth = 0
        label.layer.cornerRadius = label.bounds.size.height / 2
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = UIFont(name: "Poppins-Bold", size: 10)
        label.textColor = .white
        label.backgroundColor = UIColor.ianLegitColor()
        label.text = "80"
        return label
    }()
    
    
    @objc func toggleNavFeedType(){
        self.delegate?.toggleFeedType()
    }
    
    
// DROP DOWN SELECTION
    let dropdownCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.layer.borderWidth = 0
        cv.backgroundColor = UIColor.white
        return cv
    }()
    

    
    let searchUserView = UserSearchViewController()
    var showUserSearchConstraint:NSLayoutConstraint?
    var hideUserSearchConstraint:NSLayoutConstraint?
    let listCellId = "listCellId"
    
// USER SELECTION HEADER
    lazy var userHeaderLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Following"
        ul.font = UIFont(name: "Poppins-Bold", size: 30)
        ul.textColor = UIColor.ianBlackColor()
        ul.textAlignment = NSTextAlignment.left
        ul.numberOfLines = 1
        ul.backgroundColor = UIColor.white
        return ul
    }()
    
    lazy var userSubLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Following"
        ul.font = UIFont.boldSystemFont(ofSize: 14)
        ul.textColor = UIColor.ianBlackColor()
        ul.textAlignment = NSTextAlignment.left
        ul.numberOfLines = 1
        ul.backgroundColor = UIColor.white
        return ul
    }()
    
// USER SELECTION
    var userSearchBar = UISearchBar()
    let userSummary = UserSummaryCollectionViewController()

    
// LIST SELECTION HEADER
    lazy var listHeaderLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Created Lists"
        ul.font = UIFont(name: "Poppins-Bold", size: 30)
        ul.textColor = UIColor.ianBlackColor()
        ul.textAlignment = NSTextAlignment.left
        ul.numberOfLines = 1
        ul.backgroundColor = UIColor.white
        return ul
    }()
    
    lazy var listHeaderButton: UIButton = {
        let button = UIButton(type: .system)
        let img = #imageLiteral(resourceName: "slider_gray")
        button.setImage(img.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.setTitleColor(UIColor.darkGray, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        button.semanticContentAttribute = .forceRightToLeft
        button.tintColor = UIColor.ianLegitColor()
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.layer.borderWidth = 0
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        button.addTarget(self, action: #selector(toggleFollowedList), for: .touchUpInside)
        return button
    }()
    
    var displayFollowedList: Bool = false

    
    let listSummary = ListSummaryCollectionViewController()
    
    lazy var listSortButton: UIButton = {
        let button = UIButton(type: .system)
        let img = #imageLiteral(resourceName: "dropdownXLarge").resizeImageWith(newSize: CGSize(width: 15, height: 15))
        button.setImage(img.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.setTitleColor(UIColor.darkGray, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        button.semanticContentAttribute = .forceRightToLeft
        button.tintColor = UIColor.ianLegitColor()
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.layer.borderWidth = 0
        button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 5, bottom: 3, right: 5)
        button.addTarget(self, action: #selector(toggleListSort), for: .touchUpInside)
        return button
    }()
    
    var sortListByPostCount = true {
        didSet {
            listSummary.sortListByPostCount = sortListByPostCount
        }
    }
    
    @objc func toggleListSort() {
        self.sortListByPostCount = !sortListByPostCount
        self.refreshListSortButton()
    }
    
    func refreshListSortButton() {
        let title = self.sortListByPostCount ? "Sort By Post " : "Sort By Date "
        self.listSortButton.setTitle(title, for: .normal)
        self.listSortButton.sizeToFit()
    }
    

    var keyboardTap = UITapGestureRecognizer()

        let profileImageView: CustomImageView = {
            let iv = CustomImageView()
            iv.backgroundColor = .white
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
    //        iv.layer.cornerRadius = 50/2
    //        iv.layer.masksToBounds = true
            return iv
        }()
        var profileImageViewWidth: NSLayoutConstraint?
    
    let headerLabelView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.init(red: 34, green: 34, blue: 34, alpha: 0.4)

    // DUPLICATE TOP HEADER
        let headerView = UIView()
        addSubview(headerView)
        headerView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 10, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 40 + UIApplication.shared.statusBarFrame.height - 10)
        // 10 is collectionview top inset
//        headerView.backgroundColor = UIColor.legitColor()

        headerLabelView.addSubview(profileImageView)
        profileImageView.anchor(top: headerLabelView.topAnchor, left: headerLabelView.leftAnchor, bottom: headerLabelView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
        profileImageViewWidth = profileImageView.widthAnchor.constraint(equalToConstant: 40)
        profileImageViewWidth?.isActive = true
        
        profileImageView.layer.cornerRadius = 40/2
        profileImageView.layer.masksToBounds = true
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapProfilePic)))


        
        headerLabelView.addSubview(notificationButton)
        notificationButton.anchor(top: nil, left: nil, bottom: nil, right: headerLabelView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        notificationButton.centerYAnchor.constraint(equalTo: headerLabelView.centerYAnchor).isActive = true
        notificationButton.isHidden = true
        refreshNotifications()
        
        headerLabelView.addSubview(navFeedTypeLabel)
        navFeedTypeLabel.anchor(top: headerLabelView.topAnchor, left: profileImageView.rightAnchor, bottom: headerLabelView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        navFeedTypeLabel.isUserInteractionEnabled = true
        navFeedTypeLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleNavFeedType)))
        self.refresNavFeedTypeLabel()
        
        headerLabelView.addSubview(navFeedTypeButton)
        navFeedTypeButton.anchor(top: nil, left: navFeedTypeLabel.rightAnchor, bottom: nil, right: headerLabelView.rightAnchor, paddingTop: 0, paddingLeft: 4, paddingBottom: 0, paddingRight: 5, width: 25, height: 25)
        navFeedTypeButton.centerYAnchor.constraint(equalTo: headerLabelView.centerYAnchor).isActive = true
        navFeedTypeButton.rightAnchor.constraint(lessThanOrEqualTo: notificationButton.leftAnchor, constant: 10).isActive = true
        
    
        
        headerView.addSubview(headerLabelView)
        headerLabelView.anchor(top: nil, left: headerView.leftAnchor, bottom: headerView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
//        headerLabelView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor).isActive = true
        headerLabelView.widthAnchor.constraint(lessThanOrEqualToConstant: UIScreen.main.applicationFrame.size.width - 10).isActive = true

//        headerLabelView.backgroundColor = UIColor.lightLegitColor()

        
        
    // SHOW OPTIONS
        let navFeedTypeDiv = UIView()
        navFeedTypeDiv.backgroundColor = UIColor.ianBlackColor()
        addSubview(navFeedTypeDiv)
        navFeedTypeDiv.anchor(top: headerView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 4, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 4)
        
        setupDropDownCollectionView()
        addSubview(dropdownCollectionView)
        dropdownCollectionView.anchor(top: navFeedTypeDiv.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 180)
        dropdownCollectionView.reloadData()

        let addView = UIView()
        addSubview(addView)
//        addView.backgroundColor = UIColor.yellow
        addView.anchor(top: dropdownCollectionView.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    // USERS

        addSubview(userHeaderLabel)
        userHeaderLabel.anchor(top: addView.topAnchor, left: addView.leftAnchor, bottom: nil, right: nil, paddingTop: 20, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)

        self.setupSearchBar()
        addSubview(userSearchBar)
//        userSearchBar.anchor(top: nil, left: nil, bottom: nil, right: addView.rightAnchor, paddingTop: 15, paddingLeft: 10, paddingBottom: 0, paddingRight: 15, width: 120, height: 30)
        userSearchBar.centerYAnchor.constraint(equalTo: userHeaderLabel.centerYAnchor).isActive = true
        userSearchBar.anchor(top: nil, left: nil, bottom: nil, right: addView.rightAnchor, paddingTop: 3, paddingLeft: -10, paddingBottom: 0, paddingRight: 15, width: 150, height: 30)

        userSearchBar.sizeToFit()
        
        addSubview(userSummary.view)
        userSummary.delegate = self
        userSummary.view.anchor(top: userHeaderLabel.bottomAnchor, left: addView.leftAnchor, bottom: nil, right: addView.rightAnchor, paddingTop: 2, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 90)
        userSummary.view.backgroundColor = UIColor.clear
        userSummary.fetchFollowingUsers()
        
                


        
        
    // LISTS
        addSubview(listHeaderLabel)
        listHeaderLabel.anchor(top: userSummary.view.bottomAnchor, left: addView.leftAnchor, bottom: nil, right: nil, paddingTop: 30, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        listHeaderLabel.isUserInteractionEnabled = true
        listHeaderLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleFollowedList)))
        
        addSubview(listHeaderButton)
        listHeaderButton.anchor(top: nil, left: listHeaderLabel.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 20, height: 20)
        listHeaderButton.centerYAnchor.constraint(equalTo: listHeaderLabel.centerYAnchor).isActive = true
        listHeaderButton.isUserInteractionEnabled = true
        listHeaderButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleFollowedList)))

        addSubview(listSortButton)
        listSortButton.anchor(top: nil, left: nil, bottom: nil, right: addView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        listSortButton.centerYAnchor.constraint(equalTo: listHeaderLabel.centerYAnchor).isActive = true
        refreshListSortButton()
        
        listHeaderLabel.rightAnchor.constraint(lessThanOrEqualTo: listSortButton.leftAnchor).isActive = true
        
        addSubview(listSummary.view)
        listSummary.delegate = self
        listSummary.view.anchor(top: listHeaderLabel.bottomAnchor, left: addView.leftAnchor, bottom: nil, right: addView.rightAnchor, paddingTop: 5, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 140)
        listSummary.currentUserUid = CurrentUser.uid
        listSummary.showAddListButton = false

        
        self.keyboardTap = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    @objc func refreshCollectionViews() {
        userSummary.collectionView.reloadData()
        listSummary.collectionView.reloadData()
    }
        
    @objc func toggleFollowedList() {
        self.displayFollowedList = !self.displayFollowedList
        listHeaderLabel.text = self.displayFollowedList ? "Following List" : "Created List"
        self.listSummary.displayFollowedList = self.displayFollowedList
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if type(of: self.window?.rootViewController?.view) is NewLegitFeedSelectView {
            print("keyboardWillShow. Adding Keyboard Tap Gesture")
            self.addGestureRecognizer(self.keyboardTap)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification){
        if type(of: self.window?.rootViewController?.view) is NewLegitFeedSelectView {
            print("keyboardWillHide. Removing Keyboard Tap Gesture")
            self.removeGestureRecognizer(self.keyboardTap)
        }
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
//        userSearchBar.resignFirstResponder()
        self.endEditing(true)
    }
    
    @objc func resetViews() {
        self.userSearchBar.text = nil
        self.userSummary.resetViews()
        self.listSummary.resetViews()
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    func refreshNotifications() {
        if CurrentUser.unreadEventCount > 0 {
            notificationLabel.text = String(CurrentUser.unreadEventCount)
            notificationButton.addSubview(notificationLabel)
            notificationLabel.isHidden = false
        } else {
//                    notificationButton.setTitle("", for: .normal)
            notificationLabel.text = ""
            notificationLabel.isHidden = true
        }
    }
    
    var fetchUser: User? = nil {
        didSet {
            self.userSummary.currentFilterUser = fetchUser
        }
    }
    var fetchList: List? = nil {
        didSet {
            self.listSummary.currentFilterList = fetchList
        }
    }

    var fetchTypeInd: String = HomeFetchDefault {
        didSet{
            self.refresNavFeedTypeLabel()
        }
    }
    
    
    func refresNavFeedTypeLabel(){
        if self.fetchTypeInd == HomeFetchOptions[2] && self.fetchUser != nil
        {
            self.navFeedTypeLabel.text = self.fetchUser?.username
            if let url = self.fetchUser?.profileImageUrl {
                self.profileImageView.loadImage(urlString: url)
                profileImageViewWidth?.constant = 40
            }
        }
        else if self.fetchTypeInd == HomeFetchOptions[3] && self.fetchList != nil {
            self.navFeedTypeLabel.text = self.fetchList?.name
            if let url = self.fetchList?.heroImageUrl {
                self.profileImageView.loadImage(urlString: url)
                profileImageViewWidth?.constant = 40
            }
        }
        else {
            self.navFeedTypeLabel.text = self.fetchTypeInd
            profileImageViewWidth?.constant = 0
        }
        self.navFeedTypeLabel.sizeToFit()
    }
    
    @objc func didTapProfilePic(){
        if self.fetchTypeInd == HomeFetchOptions[2] && self.fetchUser != nil
        {
            if let userUid = self.fetchUser?.uid {
                print("goToUser | \(userUid)")
                self.delegate?.goToUser(uid: userUid)
            }
        }
        else if self.fetchTypeInd == HomeFetchOptions[3] && self.fetchList != nil {
            if let listId = self.fetchList?.id {
                print("goToList | \(listId)")
                self.delegate?.goToList(listId: listId)
            }
        }
        else {
            self.navFeedTypeLabel.text = self.fetchTypeInd
            profileImageViewWidth?.constant = 0
        }
        self.navFeedTypeLabel.sizeToFit()
    }

    
}

extension NewLegitFeedSelectView: UISearchBarDelegate {
        func setupSearchBar() {
    //        setup.searchBarStyle = .prominent
            userSearchBar.searchBarStyle = .minimal

            userSearchBar.isTranslucent = false
            userSearchBar.tintColor = UIColor.ianBlackColor()
            userSearchBar.placeholder = "Search Users"
            userSearchBar.delegate = self
            userSearchBar.showsCancelButton = false
            userSearchBar.sizeToFit()
            userSearchBar.clipsToBounds = true
            userSearchBar.backgroundImage = UIImage()
            userSearchBar.backgroundColor = UIColor.yellow
            userSearchBar.isUserInteractionEnabled = true
            userSearchBar.layer.borderWidth = 1
            userSearchBar.layer.borderColor = UIColor.black.cgColor
//            userSearchBar.returnKeyType = .done
            userSearchBar.enablesReturnKeyAutomatically = true

            // CANCEL BUTTON
            let attributes = [
                NSAttributedString.Key.foregroundColor : UIColor.ianLegitColor(),
                NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 12)
            ]
    //        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(attributes, for: .normal)
            
            
            let searchImage = #imageLiteral(resourceName: "search_selected").withRenderingMode(.alwaysTemplate)
            userSearchBar.setImage(UIImage(), for: .search, state: .normal)
            
    //        let cancelImage = #imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysTemplate)
    //        fullSearchBar.setImage(cancelImage, for: .clear, state: .normal)

            userSearchBar.layer.borderWidth = 0
            userSearchBar.layer.borderColor = UIColor.ianBlackColor().cgColor
        
            let textFieldInsideSearchBar = userSearchBar.value(forKey: "searchField") as? UITextField
            textFieldInsideSearchBar?.textColor = UIColor.ianBlackColor()
            textFieldInsideSearchBar?.font = UIFont.systemFont(ofSize: 12)
            
            // REMOVE SEARCH BAR ICON
    //        let searchTextField:UITextField = fullSearchBar.subviews[0].subviews.last as! UITextField
    //        searchTextField.leftView = nil
            
            
            for s in userSearchBar.subviews[0].subviews {
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
    

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("Search Button Clicked | userSearchBar")
        self.endEditing(true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("Cancel Button Clicked | userSearchBar")
        self.endEditing(true)
    }
    
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.userSummary.filterContentForSearchText(searchBar.text)
//        self.showSearch()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.userSummary.filterContentForSearchText(searchBar.text)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.userSummary.filterContentForSearchText(searchBar.text)
//        self.hideSearch()
    }
}

extension NewLegitFeedSelectView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UserSearchViewControllerDelegate, UserSummaryDelegate, ListSummaryDelegate {
    func doShowListView() {
        
    }
    
    func doHideListView() {
        
    }
    
    func didTapAddList() {
    }
    

    
    func setupDropDownCollectionView(){
        dropdownCollectionView.register(LegitFeedTypeCell.self, forCellWithReuseIdentifier: listCellId)
        dropdownCollectionView.backgroundColor = UIColor.clear
//        dropdownCollectionView.backgroundColor = UIColor.yellow
        dropdownCollectionView.delegate = self
        dropdownCollectionView.dataSource = self
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = CGSize(width: self.frame.width, height: 90)
        layout.scrollDirection = .vertical
        dropdownCollectionView.collectionViewLayout = layout
        dropdownCollectionView.layoutIfNeeded()
        
    }
    

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        var isSelected = (fetchTypeInd == HomeFetchOptions[indexPath.row])
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: listCellId, for: indexPath) as! LegitFeedTypeCell
        cell.mainText = HomeFetchOptions[indexPath.row]
        
        if indexPath.row == 2 {
            cell.subText = "\((CurrentUser.username)!) Posts"
        } else {
            cell.subText = HomeFetchDetails[indexPath.row]
        }

        cell.mainLabel.alpha = isSelected ? 0.2 : 1
        cell.subLabel.alpha = isSelected ? 0.2 : 1
        
//        cell.labelView.layer.cornerRadius = 10
//        cell.labelView.layer.masksToBounds = true
//        cell.labelView.layer.borderWidth = 1
//        cell.labelView.layer.borderColor = UIColor.gray.cgColor

//        cell.mainLabel.textColor = isSelected ? UIColor.mainBlue() : UIColor.ianBlackColor()
//        cell.subLabel.textColor = isSelected ? UIColor.mainBlue() : UIColor.ianBlackColor()

        
        print(" \(indexPath.row) | \(cell.mainText) | \(cell.subText)")
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.frame.width, height: 90)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.feedTypeSelected(type: HomeFetchOptions[indexPath.row])
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    
    func feedTypeSelected(type: String) {
        self.delegate?.feedTypeSelected(type: type)
        self.endEditing(true)

    }
        
    
    func showSearchResults() {
        self.hideUserSearchConstraint?.isActive = false
        self.showUserSearchConstraint?.isActive = true
        self.searchUserView.showUserSearch = true

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveLinear, animations: {

            self.layoutIfNeeded()
        }) { (finished) in
            // SHOW RESULTS AFTER MOVE
            print("showSearchResults")
        }

    }
        
    func hideSearchResults() {
        self.showUserSearchConstraint?.isActive = false
        self.hideUserSearchConstraint?.isActive = true
        self.searchUserView.showUserSearch = false
        // HIDE RESULTS BEFORE MOVE

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveLinear, animations: {

            self.layoutIfNeeded()
        }) { (finished) in
            print("hideSearchResults")

        }
    }
    
    func userFeedSelected(user: User){
        self.delegate?.userFeedSelected(user: user)
        self.endEditing(true)

    }
    
    func didTapUser(user: User?) {
        guard let user = user else {return}
        self.delegate?.userFeedSelected(user: user)
        self.endEditing(true)

    }
    
    func didTapList(list: List?) {
        guard let list = list else {return}
        self.delegate?.userFeedSelected(list: list)
        self.endEditing(true)

    }
    
}
