//
//  LegitSearchViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 12/1/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit
import Foundation
import EmptyDataSet_Swift
import Kingfisher
import SVProgressHUD
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth

import CoreLocation
import EmptyDataSet_Swift

//protocol LegitSearchViewControllerNewDelegate {
//    func filterControllerSelected(filter: Filter?)
//    func refreshAll()
//}


class LegitSearchViewControllerNew: UIViewController {

    
    var delegate: LegitSearchViewControllerDelegate?
    // MARK: - SEARCH

    let searchController = UISearchController(searchResultsController: nil)
    var searchBar = UISearchBar()
//    var searchSegment = UISegmentedControl()
    
    var selectedSearchSegmentIndex: Int? = nil
    var searchSegment: ReselectableSegmentedControl = {
        var segment = ReselectableSegmentedControl(items: LegitSearchBarOptions)
//        segment.addTarget(self, action: #selector(handleSearchCategory), for: .valueChanged)
//        segment.selectedSegmentIndex = UISegmentedControl.noSegment
        return segment
    }()
    
    @objc func handleSearchCategory(sender: UISegmentedControl) {
        if (sender.selectedSegmentIndex == self.selectedSearchSegmentIndex) {
            sender.selectedSegmentIndex =  UISegmentedControl.noSegment
            self.selectedSearchSegmentIndex = nil
        }
        else {
            self.selectedSearchSegmentIndex = sender.selectedSegmentIndex
        }
        self.tableView.reloadData()
        print("Selected Search Category is ",self.selectedSearchSegmentIndex)
    }
    
    
    
    var inputViewFilter: Filter? {
        didSet {
            guard let inputViewFilter = inputViewFilter else {return}
            print("\(inputViewFilter.searchTerms) : Input View Filter for SearchController")
            self.searchViewFilter = inputViewFilter.copy() as! Filter
        }
    }
    
    var searchViewFilter: Filter = Filter.init(defaultSort: defaultRecentSort) {
        didSet {
//            self.selectedPlace = self.viewFilter.filterLocationName
//            self.selectedCity = self.viewFilter.filterLocationSummaryID
//            self.searchText = self.viewFilter.filterCaption
            self.searchTerms = self.searchViewFilter.searchTerms
            self.refreshSearchTerm()
        }
    }
    
    let selectedSegmentWidth: CGFloat = 100
    let unselectedSegmentWidth: CGFloat = 70
    
    
    lazy var tableView : UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        //        tv.estimatedRowHeight = 100
        tv.allowsMultipleSelection = false
//        tv.contentInset = UIEdgeInsets(top: 20, left: 40, bottom: 20, right: 40)
        return tv
    }()
    

    var searchFiltering = false
    var searchText: String?
    var searchTerms: [String] = []
    var searchTermsType: [String] = []

    let searchTermid = "SearchTerm"
    let addTagId = "addTagId"
    let searchRatingId = "SearchRating"

    
    let searchTermCollectionView: UICollectionView = {
        let uploadEmojiList = UICollectionViewFlowLayout()
        uploadEmojiList.estimatedItemSize = CGSize(width: 120, height: 35)
        uploadEmojiList.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        uploadEmojiList.scrollDirection = .horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadEmojiList)
        cv.layer.borderWidth = 0
        cv.backgroundColor = UIColor.white
        return cv
    }()
    
    let headerHeightConstant: CGFloat = 120
    let searchTermsHeightConstant: CGFloat = 45
    var searchTermsHeight: NSLayoutConstraint?
    var headerHeight: NSLayoutConstraint?

    var singleSearch: Bool = true {
        didSet {
            setupSingleSearchButton()
            refreshSearchTerm()
        }
    }
    
    let singleSearchButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.font = UIFont(name: "Poppins-Regular", size: 10)
//        button.setImage(#imageLiteral(resourceName: "info").withRenderingMode(.alwaysOriginal), for: .normal)
        button.setTitle("Mult\nFilter", for: .normal)
        button.addTarget(self, action: #selector(toggleSingleSearch), for: .touchUpInside)
//        button.setTitleColor(UIColor.darkGray, for: .normal)
        button.layer.backgroundColor = UIColor.ianWhiteColor().cgColor
//        button.layer.backgroundColor = UIColor.ianBlackColor().cgColor
        button.setTitleColor(UIColor.ianWhiteColor(), for: .normal)

//        button.layer.backgroundColor = UIColor.white.withAlphaComponent(0.75).cgColor
        button.layer.borderColor = button.titleColor(for: .normal)?.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 10/2
        button.translatesAutoresizingMaskIntoConstraints = true
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        return button
    }()
    
    @objc func toggleSingleSearch(){
        self.singleSearch = !self.singleSearch
//        setupNavigationItem()
        print("Toggle Single Search | \(self.singleSearch)")

        self.setupSingleSearchButton()
    }
    
    func setupSingleSearchButton(){
//        let title = self.singleSearch ? "Select Mult" : "Many"
//        singleSearchButton.setTitle(title, for: .normal)
        singleSearchButton.layer.backgroundColor = self.singleSearch ? UIColor.backgroundGrayColor().cgColor : UIColor.mainBlue().cgColor
        singleSearchButton.setTitleColor(self.singleSearch ? UIColor.gray : UIColor.white, for: .normal)
        singleSearchButton.layer.borderColor = singleSearchButton.titleColor(for: .normal)?.cgColor
        singleSearchButton.titleLabel?.font = self.singleSearch ? UIFont.systemFont(ofSize: 9) : UIFont.boldSystemFont(ofSize: 10)
        singleSearchButton.sizeToFit()
    }
    
    let infoButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//        button.setTitle("❓", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        button.setImage(#imageLiteral(resourceName: "info").withRenderingMode(.alwaysOriginal), for: .normal)

        button.addTarget(self, action: #selector(didTapInfo), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.clear.cgColor
//        button.layer.backgroundColor = UIColor.white.withAlphaComponent(0.75).cgColor
        button.layer.borderColor = UIColor.red.cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 30/2
        button.translatesAutoresizingMaskIntoConstraints = true
        return button
    }()
    
    let navSearchButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 13)
//        button.setImage(#imageLiteral(resourceName: "info").withRenderingMode(.alwaysOriginal), for: .normal)
        button.setTitle("Search", for: .normal)
        button.addTarget(self, action: #selector(didTapNavSearch), for: .touchUpInside)
        button.setTitleColor(UIColor.ianWhiteColor(), for: .normal)
        button.layer.backgroundColor = UIColor.ianLegitColor().cgColor
//        button.layer.backgroundColor = UIColor.white.withAlphaComponent(0.75).cgColor
        button.layer.borderColor = button.titleColor(for: .normal)?.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 10/2
        button.translatesAutoresizingMaskIntoConstraints = true
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        return button
    }()
    
    @objc func didTapNavSearch(){
        print("didTapNavSearch")
        self.handleFilter()
    }
    
    let navRefreshButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 15)
        button.setImage(#imageLiteral(resourceName: "refresh_gray").withRenderingMode(.alwaysTemplate), for: .normal)
//        button.setTitle("Search", for: .normal)
        button.addTarget(self, action: #selector(didTapNavRefresh), for: .touchUpInside)
        button.setTitleColor(UIColor.darkGray, for: .normal)
        button.setTitleColor(UIColor.mainBlue(), for: .normal)
        button.layer.backgroundColor = UIColor.clear.cgColor
//        button.layer.backgroundColor = UIColor.white.withAlphaComponent(0.75).cgColor
        button.layer.borderColor = button.titleColor(for: .normal)?.cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 10/2
        button.translatesAutoresizingMaskIntoConstraints = true
        button.semanticContentAttribute = .forceLeftToRight
//        button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 10, bottom: 3, right: 10)
        return button
    }()
    
    @objc func didTapNavRefresh(){
        print("didTapNavRefresh")
        self.handleRefresh()
    }
    
    let navCancelButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(#imageLiteral(resourceName: "cancel_shadow").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.ianWhiteColor().cgColor
//        button.layer.backgroundColor = UIColor.white.withAlphaComponent(0.75).cgColor
        button.layer.borderColor = UIColor.red.cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 30/2
        button.translatesAutoresizingMaskIntoConstraints = true
        button.layer.masksToBounds = true
        return button
    }()
    
//    let multSelectButton: UIButton = {
//        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//        button.setImage(#imageLiteral(resourceName: "cancel_shadow").withRenderingMode(.alwaysOriginal), for: .normal)
//        button.addTarget(self, action: #selector(didTapMultSelect), for: .touchUpInside)
//        button.layer.backgroundColor = UIColor.ianWhiteColor().cgColor
//        button.setTitle("Select\nMult", for: .normal)
//        button.titleLabel?.font = UIFont.systemFont(ofSize: 8)
//        button.setTitleColor(UIColor.darkGray, for: .normal)
////        button.layer.backgroundColor = UIColor.white.withAlphaComponent(0.75).cgColor
//        button.layer.borderColor = UIColor.red.cgColor
//        button.layer.borderWidth = 0
//        button.layer.cornerRadius = 10
//        button.translatesAutoresizingMaskIntoConstraints = true
//        button.layer.masksToBounds = true
//        return button
//    }()
//
//    func didTapMultSelect() {
//        self.singleSearch = !self.singleSearch
//    }
//
//    func setupMultSelect() {
//        self.multSelectButton.backgroundColor = self.singleSearch ? UIColor.lightBackgroundGrayColor() : UIColor.mainBlue()
//        var fontColor = self.singleSearch ? UIColor.darkGray : UIColor.white
//    }
    
    
    
    // SEARCH SELECTIONS
        var first50EmojiCounts: [String:Int] = [:]
        var noFilterTagCounts: PostTagCounts = PostTagCounts.init()
        var currentPostTagCounts: PostTagCounts = PostTagCounts.init()
        var currentRatingCounts = RatingCountArray
        var currentStarRatingSequence:[Int] = [5,4,3,2,1]

//        var noCaptionFilterEmojiCounts: [String:Int] = [:]
//        var noCaptionFilterPlaceCounts: [String:Int] = [:]
//        var noCaptionFilterCityCounts: [String:Int] = [:]


    
    // DEFAULT EMOJI AND LOCATION FROM FEED
//        var defaultEmojiCounts:[String:Int] = [:]
//        var defaultPlaceCounts:[String:Int] = [:]
//        var defaultCityCounts:[String:Int] = [:]

    // SEARCH TEMPS
        var displayEmojis:[Emoji] = []
        var filteredEmojis:[Emoji] = []
        
        var displayCuisines:[Emoji] = []
        var filteredCuisines:[Emoji] = []
    
        var displayRatingEmojis:[Emoji] = []
    
        var displayPlaces: [String] = []
        var filteredPlaces: [String] = []
//        var selectedPlace: String? = nil
        var singleSelection = true
        
        var displayCity: [String] = []
        var filteredCity: [String] = []
//        var selectedCity: String? = nil
    
        var allSearchItems: [[String]] = []
        var filteredAllSearchItems: [[String]] = []
        var displyedAllSearchItems: [[String]] = []
        var defaultAllTerms: [[String]] = []

    let EmojiCellId = "Emoji"
    let UserCellId = "User"
    let LocationCellId = "Location"
    let ListCellId = "List"
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.setupNavigationItem()
        self.initSearchEmojis()
//        self.setupSearch()
        self.searchSegment.selectedSegmentIndex = UISegmentedControl.noSegment
        self.selectedSearchSegmentIndex = nil
        self.refreshSegmentValues()
        
        NotificationCenter.default.addObserver(self, selector: #selector(LegitSearchViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LegitSearchViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.searchBar.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.searchBar.resignFirstResponder()
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        if let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height {
            print("Notification: Keyboard will show")
            tableView.setBottomInset(to: keyboardHeight)
        }
    }

    @objc func keyboardWillHide(notification: Notification) {
//        print("Notification: Keyboard will hide")
        tableView.setBottomInset(to: 0.0)
    }
    
    
    func refreshSearchTerm() {
//        self.viewFilter.filterLocationName = self.selectedPlace
//        self.viewFilter.filterLocationSummaryID = self.selectedCity
//        self.viewFilter.filterCaption = self.searchText
        self.searchTerms = self.searchViewFilter.searchTerms
        self.searchTermsType = self.searchViewFilter.searchTermsType

        let searchTitle = (self.searchTerms.count > 0 ? (" " + String(self.searchTerms.count)) : "")
        self.navRefreshButton.setTitle(searchTitle, for: .normal)
        self.navRefreshButton.sizeToFit()
        
        let showSearchTerms = self.searchTerms.count > 0
        searchTermsHeight?.constant = showSearchTerms ? searchTermsHeightConstant : 0
//        searchTermCollectionView.isHidden = !showSearchTerms
//        navSearchButton.isHidden = !showSearchTerms
//        navRefreshButton.isHidden = !showSearchTerms
        self.searchTermView.isHidden = !showSearchTerms

        self.searchTermCollectionView.reloadData()
        self.tableView.reloadData()
        self.view.layoutIfNeeded()
    }
    
    
    func setupSearchTerm(){
        
    }
    
    let searchTermView = UIView()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = false
        setupNavigationItem()
        self.initSearchEmojis()

        let searchView = UIView()
        view.addSubview(searchView)
        searchView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        headerHeight = searchView.heightAnchor.constraint(equalToConstant: headerHeightConstant + searchTermsHeightConstant)
//        headerHeight?.isActive = true
        searchView.backgroundColor = UIColor.backgroundGrayColor()
        
        searchView.addSubview(searchTermView)
        searchTermView.backgroundColor = UIColor.ianLegitColor().withAlphaComponent(0.5)
        searchTermView.anchor(top: searchView.topAnchor, left: searchView.leftAnchor, bottom: nil, right: searchView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        searchTermsHeight = searchTermView.heightAnchor.constraint(equalToConstant: searchTermsHeightConstant)
        searchTermsHeight?.isActive = true
//        searchTermView.layer.applySketchShadow(color: UIColor(red: 0, green: 0, blue: 0, alpha: 0.5), alpha: 0.5, x: 0, y: 2, blur: 4, spread: 0)


        searchTermView.addSubview(navSearchButton)
        navSearchButton.anchor(top: nil, left: nil, bottom: nil, right: searchTermView.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)
        navSearchButton.centerYAnchor.constraint(equalTo: searchTermView.centerYAnchor).isActive = true
        navSearchButton.sizeToFit()
        
        
        searchTermView.addSubview(navRefreshButton)
        navRefreshButton.anchor(top: nil, left: searchTermView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 2, width: 0, height: 30)
        navRefreshButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 30).isActive = true
        navRefreshButton.centerYAnchor.constraint(equalTo: searchTermView.centerYAnchor).isActive = true
        
        
        setupCollectionView()
        searchTermView.addSubview(searchTermCollectionView)
        searchTermCollectionView.anchor(top: searchTermView.topAnchor, left: navRefreshButton.rightAnchor, bottom: searchTermView.bottomAnchor, right: navSearchButton.leftAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)

        
        let bottomDiv = UIView()
        bottomDiv.backgroundColor = UIColor.ianLightGrayColor()
        searchTermView.addSubview(bottomDiv)
        bottomDiv.anchor(top: nil, left: searchTermView.leftAnchor, bottom: searchTermView.bottomAnchor, right: searchTermView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
        
        let searchBarView = UIView()
        searchView.addSubview(searchBarView)
        searchBarView.anchor(top: searchTermView.bottomAnchor, left: searchView.leftAnchor, bottom: nil, right: searchView.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)

        searchBarView.addSubview(singleSearchButton)
        singleSearchButton.anchor(top: nil, left: searchBarView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 60, height: 35)
        setupSingleSearchButton()
        
        setupSearch()
        searchBarView.addSubview(searchBar)
        searchBar.anchor(top: searchBarView.topAnchor, left: singleSearchButton.rightAnchor, bottom: searchBarView.bottomAnchor, right: searchBarView.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        singleSearchButton.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor).isActive = true

        
        let searchSegmentView = UIView()
        searchView.addSubview(searchSegmentView)
        searchSegmentView.anchor(top: searchBarView.bottomAnchor, left: searchView.leftAnchor, bottom: nil, right: searchView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)


//        setupSingleSearchButton()
//        searchSegmentView.addSubview(singleSearchButton)
//        singleSearchButton.anchor(top: nil, left: nil, bottom: nil, right: searchSegmentView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 60, height: 30)
//        singleSearchButton.centerYAnchor.constraint(equalToSystemSpacingBelow: searchSegmentView.centerYAnchor, multiplier: 1).isActive = true

        searchSegmentView.addSubview(searchSegment)
        searchSegment.anchor(top: nil, left: searchSegmentView.leftAnchor, bottom: nil, right: searchSegmentView.rightAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 40)
        searchSegment.centerYAnchor.constraint(equalToSystemSpacingBelow: searchSegmentView.centerYAnchor, multiplier: 1).isActive = true
//        searchSegment.centerXAnchor.constraint(equalTo: searchSegmentView.centerXAnchor).isActive = true
        searchSegmentView.layer.applySketchShadow(color: UIColor(red: 0, green: 0, blue: 0, alpha: 0.5), alpha: 0.5, x: 0, y: 2, blur: 4, spread: 0)

        refreshSearchTerm()

//
//        let bottomDiv2 = UIView()
//        bottomDiv2.backgroundColor = UIColor.ianLightGrayColor()
//        searchSegmentView.addSubview(bottomDiv2)
//        bottomDiv2.anchor(top: nil, left: searchSegmentView.leftAnchor, bottom: searchSegmentView.bottomAnchor, right: searchSegmentView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
        
        setupTableView()
        view.addSubview(tableView)
        tableView.anchor(top: searchSegmentView.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

        
        
        
//        tableView.anchor(top: searchView.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        let div = UIView()
        view.addSubview(div)
        div.anchor(top: nil, left: view.leftAnchor, bottom: searchView.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 1, paddingRight: 10, width: 0, height: 1)
        div.backgroundColor = UIColor.ianLightGrayColor()
        
        
        print("Search View Did Load")
        // Do any additional setup after loading the view.
    }
    
    func setupNavigationItem(){

        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.barTintColor = UIColor.backgroundGrayColor()
        navigationController?.navigationBar.tintColor = UIColor.backgroundGrayColor()
        navigationController?.view.backgroundColor = UIColor.backgroundGrayColor()
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.layoutIfNeeded()
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.isNavigationBarHidden = true
        
//        navigationController?.navigationBar.barTintColor = UIColor.backgroundGrayColor()
//        navigationController?.navigationBar.isTranslucent = true
//        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        
        
        let customFont = UIFont(name: "Poppins-Bold", size: 18)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: customFont]
        self.navigationItem.title = "Search"
//        self.navigationController?.navigationBar.backgroundColor = UIColor.backgroundGrayColor()
//
//        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(didTapCancel))
//        navigationItem.rightBarButtonItem = cancelButton
//
//        infoButton.addTarget(self, action: #selector(didTapInfo), for: .touchUpInside)
//        navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: infoButton)
//
        
//        setupSingleSearchButton()
//        singleSearchButton.addTarget(self, action: #selector(toggleSingleSearch), for: .touchUpInside)
//        navigationItem.titleView = singleSearchButton
        
        
//        navCancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
//        navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: navCancelButton)
//
//
//        navSearchButton.addTarget(self, action: #selector(didTapNavSearch), for: .touchUpInside)
//        navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: navSearchButton)
        
        
    }
    
    func dismissView(){
        self.searchBar.resignFirstResponder()
        if let m = self.navigationController {
            self.dismiss(animated: true) {
            }
        } else {
            self.view.alpha = 0
        }
    }
    
    func presentView(){
        self.searchBar.becomeFirstResponder()
        self.view.alpha = 1
    }
    
    @objc func didTapCancel() {
        dismissView()
    }
    
    @objc func didTapInfo() {
        print("Did Tap Info")
        self.alert(title: "Information", message: "To Add Emoji Search Information")

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

extension LegitSearchViewControllerNew: UISearchBarDelegate {

    func setupSearch() {
        print("Setup Search Segment | LegitSearchViewController")
    // SEARCH SEGMENT CONTROL
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attributes = [
            NSAttributedString.Key.foregroundColor : UIColor.white,
            NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 13),
            NSAttributedString.Key.paragraphStyle: paragraph
        ]
        
        let selectedAttributes = [
            NSAttributedString.Key.foregroundColor : UIColor.ianWhiteColor(),
            NSAttributedString.Key.font : UIFont(font: .avenirNextBold, size: 13),
            NSAttributedString.Key.paragraphStyle: paragraph
        ]
        
        let unSelectedAttributes = [
            NSAttributedString.Key.foregroundColor : UIColor.ianBlackColor(),
            NSAttributedString.Key.font : UIFont(font: .avenirNextBold, size: 12),
            NSAttributedString.Key.paragraphStyle: paragraph
        ]
        
        searchSegment.setTitleTextAttributes(unSelectedAttributes, for: .normal)
        searchSegment.setTitleTextAttributes(selectedAttributes, for: .selected)
        searchSegment.apportionsSegmentWidthsByContent = true
        searchSegment.tintColor = UIColor.ianWhiteColor()
        searchSegment.backgroundColor = UIColor.clear
        searchSegment.addTarget(self, action: #selector(handleSearchCategory), for: .valueChanged)
        searchSegment.selectedSegmentIndex = UISegmentedControl.noSegment
        
        
//        searchSegment.setTitleTextAttributes(attributes, for: .normal)
        if #available(iOS 13.0, *) {
            searchSegment.selectedSegmentTintColor = UIColor.ianLegitColor()
        }
        self.selectedSearchSegmentIndex = nil
        searchSegment.selectedSegmentIndex = UISegmentedControl.noSegment
        self.refreshSegmentValues()

    // SEARCH BAR
        searchBar.placeholder =  "Food, Cuisine, Restaurant Or City"
        searchBar.showsCancelButton = true
        searchBar.delegate = self
        searchBar.backgroundImage = UIImage()
        searchBar.barTintColor = UIColor.clear
        searchBar.isTranslucent = true
        searchBar.tintColor = UIColor.clear
        searchBar.backgroundColor = UIColor.clear
        searchBar.searchBarStyle = .default
        searchBar.layer.borderWidth = 0
        searchBar.layer.cornerRadius = 5
        searchBar.layer.masksToBounds = true
        
        // CANCEL BUTTON
        let cancelAttributes = [
            NSAttributedString.Key.foregroundColor : UIColor.ianBlackColor(),
            NSAttributedString.Key.font : UIFont(name: "Poppins-Regular", size: 12)
        ]
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(cancelAttributes, for: .normal)
        
        let textFieldInsideUISearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.textColor = UIColor.ianBlackColor()
//        textFieldInsideUISearchBar?.backgroundColor = UIColor.ianWhiteColor()

        //        textFieldInsideUISearchBar?.font = textFieldInsideUISearchBar?.font?.withSize(12)
        
        
        for s in searchBar.subviews[0].subviews {
            if s is UITextField {
                s.layer.borderWidth = 0
                s.layer.borderColor = UIColor.gray.cgColor
                s.layer.cornerRadius = 5
                s.clipsToBounds = true
                s.layer.backgroundColor = UIColor.white.cgColor
            }
        }

    }
    

    

    func refreshSegmentValues() {

        UILabel.appearance(whenContainedInInstancesOf: [UISegmentedControl.self]).numberOfLines = 2
        for (index, sortOptions) in LegitSearchBarOptions.enumerated()
        {
            
            var isSelected = (index == self.selectedSearchSegmentIndex)

//            let searchType = String(LegitSearchBarOptions[self.selectedSearchSegmentIndex] ?? "")
//            let searchText = String(SearchSegmentLookup[searchType] ?? "")
//
//            var displayFilter = (isSelected) ? "\(searchType) \(searchText)" : sortOptions
            
            var searchType = String(LegitSearchBarOptions[index] ?? "")
            var searchTypeText = String(SearchSegmentLookup[searchType] ?? "")
            if searchTypeText == "Rest" && isSelected {
                searchTypeText = "Restaurant"
            }
            var displayFilter = "\(searchType) \n \(searchTypeText)"

            if index == 2 && self.searchViewFilter.filterLocationName != nil {
                displayFilter = displayFilter + "❗️"
            } else if index == 3 && self.searchViewFilter.filterLocationSummaryID != nil {
                displayFilter = displayFilter + "❗️"
            }
            searchSegment.setTitle(displayFilter, forSegmentAt: index)
//            searchSegment.setWidth((isSelected) ? selectedSegmentWidth : unselectedSegmentWidth, forSegmentAt: index)
//            (searchSegment.subviews[index] as! UIView).tintColor = isSelected ? UIColor.ianLegitColor() : UIColor.ianWhiteColor()

        }
        searchSegment.apportionsSegmentWidthsByContent = true

    }
    

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.filterContentForSearchText(searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("Search Tapped | \(searchBar.text)")
        if !(searchBar.text?.isEmptyOrWhitespace())! {
            if let text = searchBar.text {
                self.searchViewFilter.filterCaptionArray.append(text)
            }
        }
//        self.searchText = searchBar.text
        self.handleFilter()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if let filter = self.inputViewFilter {
            self.searchViewFilter = self.inputViewFilter!
        }
        print("Cancel Tapped | Dismiss Search View| \(self.searchViewFilter.searchTerms), \(self.inputViewFilter?.searchTerms)")
        dismissView()
    }
    
    func filterContentForSearchText(_ searchText: String) {

        let searchCaption = searchText.emojilessString.lowercased()
        let searchCaptionArray = searchText.emojilessString.lowercased().components(separatedBy: " ")
        let searchCaptionEmojis = searchText.emojis
        var lastWord = searchCaptionArray[searchCaptionArray.endIndex - 1]
        
        
        self.searchText = searchText
        
        if searchCaption.removingWhitespaces() == "" {
            // No Search, Restore Defaults
            self.restoreDefaultSearch()
            self.searchFiltering = false
            return
        }
        
        self.searchFiltering = true
        
        if self.selectedSearchSegmentIndex == nil {
            filteredAllSearchItems = allSearchItems.filter({ (string) -> Bool in
                return string[0].lowercased().contains(searchCaption.lowercased())
            })
            filteredAllSearchItems = Array(Set(filteredAllSearchItems))
            filteredAllSearchItems.sort { (p1, p2) -> Bool in
                let p1Ind = ((p1[0].hasPrefix(searchCaption.lowercased())) ? 0 : 1)
                let p2Ind = ((p2[0].hasPrefix(searchCaption.lowercased())) ? 0 : 1)
                if p1Ind != p2Ind {
                    return p1Ind < p2Ind
                } else {
                    return p1.count > p2.count
                }
            }
        } else {
            let selectedSegment = LegitSearchBarOptions[self.selectedSearchSegmentIndex!]
            if selectedSegment == SearchFoodImage
            {
                filteredEmojis = displayEmojis.filter({( emoji : Emoji) -> Bool in
                    return searchCaptionArray.contains(emoji.name!) || searchCaptionEmojis.contains(emoji.emoji) || (emoji.name?.contains(lastWord))!})
                filteredEmojis = Array(Set(filteredEmojis))
                filteredEmojis.sort { (p1, p2) -> Bool in
                    let p1Ind = ((p1.name?.hasPrefix(lastWord.lowercased()))! ? 0 : 1)
                    let p2Ind = ((p2.name?.hasPrefix(lastWord.lowercased()))! ? 0 : 1)
                    if p1Ind != p2Ind {
                        return p1Ind < p2Ind
                    } else {
                        return p1.count > p2.count
                    }
                }
                print("\(searchText) | \(selectedSegment) | Filtered \(filteredEmojis.count) | All \(displayEmojis.count)")
            }
            else if selectedSegment == SearchCuisineImage
            {
                filteredCuisines = displayCuisines.filter({( emoji : Emoji) -> Bool in
                    return searchCaptionArray.contains(emoji.name!) || searchCaptionEmojis.contains(emoji.emoji) || (emoji.name?.contains(lastWord))!})
                filteredCuisines = Array(Set(filteredCuisines))
                filteredCuisines.sort { (p1, p2) -> Bool in
                    let p1Ind = ((p1.name?.hasPrefix(lastWord.lowercased()))! ? 0 : 1)
                    let p2Ind = ((p2.name?.hasPrefix(lastWord.lowercased()))! ? 0 : 1)
                    if p1Ind != p2Ind {
                        return p1Ind < p2Ind
                    } else {
                        return p1.count > p2.count
                    }
                }
                print("\(searchText) | \(selectedSegment) | Filtered \(filteredCuisines.count) | All \(displayCuisines.count)")

            }
            else if selectedSegment == SearchRestaurantImage
            {
                filteredPlaces = displayPlaces.filter({ (string) -> Bool in
                    return string.lowercased().contains(searchCaption.lowercased())
                })
                filteredPlaces = Array(Set(filteredPlaces))
                filteredPlaces.sort { (p1, p2) -> Bool in
                    let p1Ind = ((p1.hasPrefix(searchCaption.lowercased())) ? 0 : 1)
                    let p2Ind = ((p2.hasPrefix(searchCaption.lowercased())) ? 0 : 1)
                    if p1Ind != p2Ind {
                        return p1Ind < p2Ind
                    } else {
                        return p1.count > p2.count
                    }
                }
                print("\(searchText) | \(selectedSegment) | Filtered \(filteredPlaces.count) | All \(displayPlaces.count)")

            }
            else if selectedSegment == SearchCityImage
            {
                filteredCity = displayCity.filter({ (string) -> Bool in
                    return string.lowercased().contains(searchCaption.lowercased())
                })
                filteredCity = Array(Set(filteredCity))
                filteredCity.sort { (p1, p2) -> Bool in
                    let p1Ind = ((p1.hasPrefix(searchCaption.lowercased())) ? 0 : 1)
                    let p2Ind = ((p2.hasPrefix(searchCaption.lowercased())) ? 0 : 1)
                    if p1Ind != p2Ind {
                        return p1Ind < p2Ind
                    } else {
                        return p1.count > p2.count
                    }
                }
                print("\(searchText) | \(selectedSegment) | Filtered \(filteredCity.count) | All \(displayCity.count)")

            }
        }

        self.tableView.reloadData()
        
    }
    
    func restoreDefaultSearch() {
        self.searchBar.text = ""
        self.filteredEmojis = self.displayEmojis
        self.filteredCuisines = self.displayCuisines
        self.filteredPlaces = self.displayPlaces
        self.filteredCity = self.displayCity
        self.tableView.reloadData()

    }
    
    
}

extension LegitSearchViewControllerNew: UICollectionViewDelegate, UICollectionViewDataSource, SelectedFilterBarCellDelegate {



    func setupCollectionView(){
        searchTermCollectionView.backgroundColor = UIColor.clear
        searchTermCollectionView.register(SelectedFilterBarCell.self, forCellWithReuseIdentifier: searchTermid)
        searchTermCollectionView.register(HomeFilterBarCell.self, forCellWithReuseIdentifier: addTagId)

        searchTermCollectionView.delegate = self
        searchTermCollectionView.dataSource = self
        searchTermCollectionView.showsHorizontalScrollIndicator = false
        searchTermCollectionView.isScrollEnabled = true
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = (self.searchTerms.count ?? 0)
        //print("\(count) | \(self.searchTerms.count) | \(self.searchTerms)")
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let filterCell = collectionView.dequeueReusableCell(withReuseIdentifier: searchTermid, for: indexPath) as! SelectedFilterBarCell
        let searchTerms = Array(self.searchTerms.reversed())
        let searchTermsType = Array(self.searchTermsType.reversed())
        var displayTerm = searchTerms[indexPath.item]
        var displayTermType = searchTermsType[indexPath.item]

        var isEmoji = displayTerm.containsOnlyEmoji
        
        filterCell.searchTerm = isEmoji ? displayTerm : displayTerm.capitalizingFirstLetter()
        filterCell.searchTermType = displayTermType
        if let text = EmojiDictionary[displayTerm] {
            displayTerm += " \(text.capitalizingFirstLetter())"
        }
    
        filterCell.uploadLocations.text = displayTerm
        filterCell.uploadLocations.sizeToFit()
//            print("Filter Cell | \(filterCell.uploadLocations.text) | \(indexPath.item)")
    
        filterCell.uploadLocations.font =  isEmoji ? UIFont(name: "Poppins-Bold", size: 12) : UIFont(name: "Poppins-Regular", size: 12)
            filterCell.uploadLocations.textColor = UIColor.ianBlackColor()
        filterCell.layer.borderColor = filterCell.uploadLocations.textColor.cgColor

        filterCell.uploadLocations.sizeToFit()
        filterCell.delegate = self
//            filterCell.backgroundColor = UIColor.mainBlue()
        filterCell.isUserInteractionEnabled = true
        filterCell.layoutIfNeeded()
        return filterCell
        
//        if indexPath.item == 0 {
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: addTagId, for: indexPath) as! HomeFilterBarCell
//
//            var displayText = "Searching"
//            if self.searchTerms.count > 0 {
//                displayText = "\(self.searchTerms.count) Searching"
//            }
//            cell.uploadLocations.text = displayText
//            cell.uploadLocations.font =  UIFont.boldSystemFont(ofSize: 12)
//            cell.uploadLocations.textColor = UIColor.ianGrayColor()
//            cell.uploadLocations.sizeToFit()
//            cell.backgroundColor = UIColor.clear
//            return cell
//        }
        
    }
    
    func didTapCell(tag: String) {
        print("LegitSearchViewController | didTapCel | ",tag)
        self.didRemoveTag(tag: tag)
    }
    
    
    
    
    func didRemoveTag(tag: String) {
        if tag.containsOnlyEmoji {
            let tempEmoji = Emoji(emoji: tag, name: "")
            self.addEmojiToSearchTerm(inputEmoji: tempEmoji)
        } else if let deleteIndex = self.searchTerms.firstIndex(of: tag) {
            self.searchTerms.remove(at: deleteIndex)
            self.searchText = self.searchText!.replacingOccurrences(of: tag, with: "")
            self.refreshSearchTerm()
        }
//
//
//
//        if tag == self.viewFilter.filterLocationSummaryID {
//            self.viewFilter.filterLocationSummaryID = nil
//            print("Remove Search | \(tag) | City | \(self.viewFilter.filterLocationSummaryID)")
//        } else if tag == self.viewFilter.filterLocationName {
//            self.viewFilter.filterLocationName = nil
//            self.viewFilter.filterGoogleLocationID = nil
//            print("Remove Search | \(tag) | Location | \(self.viewFilter.filterLocationName) : \(self.viewFilter.filterGoogleLocationID)")
//
//        } else if let filterCaption = self.searchText {
//            if let deleteIndex = self.searchTerms.firstIndex(of: tag) {
//                self.searchTerms.remove(at: deleteIndex)
//                self.searchText = self.searchText!.replacingOccurrences(of: tag, with: "")
//            }
////
////
////            if filterCaption == tag {
////                self.viewFilter.filterCaption = nil
////            } else if filterCaption.contains(tag) {
////                self.viewFilter.filterCaption = filterCaption.replacingOccurrences(of: tag, with: "")
////            }
//        }
//        self.refreshSearchTerm()

        print("didRemoveTag | Remove Search | \(tag) | Caption | \(self.searchViewFilter.filterCaption) | LegitSearchViewController")
    }
    
    func didRemoveLocationFilter(location: String) {
        if self.searchViewFilter.filterLocationName?.lowercased() == location.lowercased() {
            self.searchViewFilter.filterLocationName = nil
        } else if self.searchViewFilter.filterLocationSummaryID?.lowercased() == location.lowercased() {
            self.searchViewFilter.filterLocationSummaryID = nil
        }
        self.refreshSearchTerm()
    }
    
    func didRemoveRatingFilter(rating: String) {
        if extraRatingEmojis.contains(rating) {
            self.searchViewFilter.filterRatingEmoji = nil
        } else if rating.contains("⭐️") {
            self.searchViewFilter.filterMinRating = 0
        }
        self.refreshSearchTerm()
    }
    


    
}

extension LegitSearchViewControllerNew: UITableViewDataSource, UITableViewDelegate, EmptyDataSetSource, EmptyDataSetDelegate {
   
    func initSearchEmojis() {
        
    // SET DEFAULT EMOJI COUNTS TO NO CAPTION FILTER EMOJI COUNTS FROM POSTS
        var curEmojiCounts = self.currentPostTagCounts.captionCounts
        var curPlaceCounts = self.currentPostTagCounts.locationCounts
        var curCityCounts = self.currentPostTagCounts.cityCounts
       
        var defaultCounts = self.noFilterTagCounts.allCounts
        var tempAllTerms: [[String]] = []
        var tempDisplayAllTerms: [[String]] = []
        
    // FOOD EMOJIS
        // Filter Emoji Counts to exclude auto tags and country tags
        let foodEmojiCount = curEmojiCounts.filter { (key,value) -> Bool in
            return (key.containsOnlyEmoji && !cuisineEmojiSelect.contains(key))
        }
        
        Database.sortEmojisWithCounts(inputEmojis: allEmojis, emojiCounts: curEmojiCounts, defaultCounts: defaultCounts, dictionaryMatch: false, sort: true) { (foodEmojis) in
            var tempEmojis = foodEmojis
            
            for x in self.searchViewFilter.searchTerms {
                if let index = tempEmojis.firstIndex(where: { (emoji) -> Bool in
                    return (emoji.emoji == x) || (emoji.name == x)
                }) {
                    let temp = tempEmojis.remove(at: index)
                    tempEmojis.insert(temp, at: 0)
                }
            }
            
            self.displayEmojis = tempEmojis
            self.filteredEmojis = tempEmojis
            tempAllTerms += tempEmojis.map({[$0.emoji, SearchEmojis]})
            
            if tempEmojis.count > 0 {
                tempDisplayAllTerms += Array(tempEmojis.prefix(upTo: 30)).map({[$0.emoji, SearchEmojis]})
            }

        }
                
        
  
        
    // MEAL + CUISINE
    // AUTO TAG VALUES FOR CUISINE AND MEAL TYPE ARE STRINGS NOT EMOJIS IN COUNT
    // Dictionary MAtch to match up flag words with emojis
        Database.sortEmojisWithCounts(inputEmojis: allMealTypeEmojis, emojiCounts: curEmojiCounts, defaultCounts: defaultCounts, dictionaryMatch: true, sort: true) { (userEmojis) in
            
            var sortedEmojis = userEmojis
                        
            for x in self.searchViewFilter.searchTerms {
                if let index = sortedEmojis.firstIndex(where: { (emoji) -> Bool in
                    return (emoji.emoji == x) || (emoji.name == x)
                }) {
                    let temp = sortedEmojis.remove(at: index)
                    sortedEmojis.insert(temp, at: 0)
                }
            }
            
            if !self.searchViewFilter.isFiltering {
                // RANK FOR MEAL EMOJIS FIRST
                for x in mealEmojisSelect.reversed() {
                    if (curEmojiCounts[x] ?? 0) > 0 {
                        if let index = sortedEmojis.firstIndex(where: { (emoji) -> Bool in
                            return (emoji.emoji == x) || (emoji.name == x)
                        }) {
                            let temp = sortedEmojis.remove(at: index)
                            sortedEmojis.insert(temp, at: 0)
                        }
                    }
                }
            }

            
            
            self.displayCuisines = sortedEmojis
            self.filteredCuisines = sortedEmojis
        }
        
    // RATINGS
        Database.sortEmojisWithCounts(inputEmojis: allRatingEmojis, emojiCounts: curEmojiCounts, defaultCounts: defaultCounts, dictionaryMatch: true, sort: true) { (ratingEmojis) in
            
            var sortedEmojis = ratingEmojis
                        
            for x in self.searchViewFilter.searchTerms {
                if let index = sortedEmojis.firstIndex(where: { (emoji) -> Bool in
                    return (emoji.emoji == x) || (emoji.name == x)
                }) {
                    let temp = sortedEmojis.remove(at: index)
                    sortedEmojis.insert(temp, at: 0)
                }
            }
            
            self.displayRatingEmojis = sortedEmojis
        }
        
        
    // PLACES
        var tempPlace: [String] = []
        let tempPlaceCounts = curPlaceCounts.sorted { (val1, val2) -> Bool in
            return val1.value > val2.value
        }
        for (y,value) in tempPlaceCounts {
            tempPlace.append(y)
        }
        
        for x in self.searchViewFilter.searchTerms {
            if let index = tempPlace.firstIndex(of: x) {
                let temp = tempPlace.remove(at: index)
                tempPlace.insert(temp, at: 0)
            }
        }
        
        self.displayPlaces = tempPlace
        self.filteredPlaces = tempPlace
        
        tempAllTerms += tempPlace.map({[$0, SearchPlace]})
        if tempPlace.count > 0 {
            tempDisplayAllTerms += Array(tempPlace.prefix(upTo: min(tempPlace.count, 20))).map({[$0, SearchPlace]})
        }

        
    // CITY
        var tempLocation: [String] = []
        let tempCounts = curCityCounts.sorted { (val1, val2) -> Bool in
            return val1.value > val2.value
        }
        for (y,value) in tempCounts {
            tempLocation.append(y)
        }
        
        for x in self.searchViewFilter.searchTerms {
            if let index = tempLocation.firstIndex(of: x) {
                let temp = tempLocation.remove(at: index)
                tempLocation.insert(temp, at: 0)
            }
        }
        
        self.displayCity = tempLocation
        self.filteredCity = tempLocation
        
        tempAllTerms += tempLocation.map({[$0, SearchCity]})
        if tempLocation.count > 0 {
            tempDisplayAllTerms += Array(tempLocation.prefix(upTo: min(tempLocation.count, 10))).map({[$0, SearchCity]})
        }
        
        self.allSearchItems = tempAllTerms
        self.filteredAllSearchItems = tempAllTerms
        self.displyedAllSearchItems = tempDisplayAllTerms
        self.defaultAllTerms = tempDisplayAllTerms
        
        print("initSearchEmojis: \(tempAllTerms.count) All Items | \(allEmojis.count) Emojis | \(tempPlace.count) Places | \(tempLocation.count) Cities")
        
        self.tableView.reloadData()
        
    }
    

    


    func setupTableView() {
        tableView.register(SearchResultsCell.self, forCellReuseIdentifier: EmojiCellId)
        tableView.register(UserAndListCell.self, forCellReuseIdentifier: UserCellId)
        tableView.register(LocationCell.self, forCellReuseIdentifier: LocationCellId)
        tableView.register(NewListCell.self, forCellReuseIdentifier: ListCellId)
        tableView.register(SearchStarRatingCell.self, forCellReuseIdentifier: searchRatingId)

        tableView.backgroundColor = UIColor.white
        tableView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 160
        tableView.separatorStyle = .singleLine
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.emptyDataSetView { (emptyview) in
            emptyview.isUserInteractionEnabled = false
        }
        
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let isFiltering = self.searchFiltering
        if self.selectedSearchSegmentIndex == nil {
            return isFiltering ? filteredAllSearchItems.count : displyedAllSearchItems.count
        }
        
        else {
            let selectedSegment = LegitSearchBarOptions[self.selectedSearchSegmentIndex ?? 0]
            // FOOD
            if selectedSegment == SearchFoodImage {
                return isFiltering ? filteredEmojis.count : displayEmojis.count
            }
                // CUISINE
            else if selectedSegment == SearchCuisineImage {
                return isFiltering ? filteredCuisines.count : displayCuisines.count
            }
                
                // Restaurants
            else if selectedSegment == SearchRestaurantImage {
                return isFiltering ? filteredPlaces.count : displayPlaces.count
            }
                
                // Cities
            else if selectedSegment == SearchCityImage {
                return isFiltering ? filteredCity.count : displayCity.count
            }
                
                // Rating
            else if selectedSegment == SearchRatingImage {
                return (displayRatingEmojis.count + currentRatingCounts.count)
            }
                
            else {
                return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let isFiltering = self.searchFiltering
        let cell = tableView.dequeueReusableCell(withIdentifier: EmojiCellId, for: indexPath) as! SearchResultsCell

        if self.selectedSearchSegmentIndex == nil {
            let tempTerm = isFiltering ? self.filteredAllSearchItems[indexPath.row] : self.displyedAllSearchItems[indexPath.row]
            let termString = tempTerm[0]
            let termType = tempTerm[1]
            var termCount = self.currentPostTagCounts.allCounts[termString] ?? 0
            var termCountDefault = self.noFilterTagCounts.allCounts[termString] ?? 0
            
            if termType == SearchEmojis {
                var tempEmoji = Emoji(emoji: termString, name: EmojiDictionary[termString])
                cell.emoji = tempEmoji
            } else {
                cell.locationName = termString
            }

            cell.postCount = termCount
            cell.defaultPostCount = termCountDefault
            cell.isSelected = self.searchViewFilter.searchTerms.contains(termString)
        } else {
            
            let selectedSegment = LegitSearchBarOptions[self.selectedSearchSegmentIndex!]

            if selectedSegment == SearchFoodImage {
                let displayTerm = isFiltering ? self.filteredEmojis[indexPath.row] : self.displayEmojis[indexPath.row]
                cell.emoji = displayTerm
                cell.postCount = self.currentPostTagCounts.allCounts[displayTerm.emoji] ?? 0 + (self.currentPostTagCounts.allCounts[displayTerm.name!] ?? 0)
                cell.defaultPostCount = self.noFilterTagCounts.allCounts[displayTerm.emoji] ?? 0 + (self.noFilterTagCounts.allCounts[displayTerm.name!] ?? 0)
    //            cell.isSelected = (self.searchText?.contains(displayTerm.emoji) ?? false) || (self.searchText?.contains(displayTerm.name ?? "     ") ?? false)
                cell.isSelected = self.searchViewFilter.searchTerms.contains(displayTerm.emoji) || self.searchViewFilter.searchTerms.contains(displayTerm.name!)
    //            cell.tempView.backgroundColor = cell.isSelected ? UIColor.mainBlue().withAlphaComponent(0.2) : UIColor.white

            }
            
            else if selectedSegment == SearchCuisineImage {
                let displayTerm = isFiltering ? self.filteredCuisines[indexPath.row] : self.displayCuisines[indexPath.row]
                cell.emoji = displayTerm
                cell.postCount = self.currentPostTagCounts.allCounts[displayTerm.emoji] ?? 0 + (self.currentPostTagCounts.allCounts[displayTerm.name!] ?? 0)
                cell.defaultPostCount = self.noFilterTagCounts.allCounts[displayTerm.emoji] ?? 0 + (self.noFilterTagCounts.allCounts[displayTerm.name!] ?? 0)
                
                cell.isSelected = self.searchViewFilter.searchTerms.contains(displayTerm.emoji) || self.searchViewFilter.searchTerms.contains(displayTerm.name!)
                cell.tempView.backgroundColor = UploadPostTypeEmojis.contains(displayTerm.emoji) ? UIColor.gray : UIColor.ianLightGrayColor()
                print(UploadPostTypeEmojis.contains(displayTerm.emoji), displayTerm)

    //            cell.isSelected = (self.searchText?.contains(displayTerm.emoji) ?? false) || (self.searchText?.contains(displayTerm.name ?? "     ") ?? false)
    //            cell.tempView.backgroundColor = cell.isSelected ? UIColor.mainBlue().withAlphaComponent(0.2) : UIColor.white

            }
                
            else if selectedSegment == SearchRestaurantImage {
                let curLabel = isFiltering ? filteredPlaces[indexPath.row] : displayPlaces[indexPath.row]
                cell.locationName = curLabel
                cell.postCount = self.currentPostTagCounts.allCounts[curLabel] ?? 0
                cell.defaultPostCount = self.noFilterTagCounts.allCounts[curLabel] ?? 0
                cell.isSelected = (curLabel == self.searchViewFilter.filterLocationName)

    //            cell.isSelected = (curLabel == self.viewFilter.filterLocationName)
    //            cell.tempView.backgroundColor = cell.isSelected ? UIColor.mainBlue().withAlphaComponent(0.2) : UIColor.white

            }
            
            else if selectedSegment == SearchCityImage {
                let curLabel = isFiltering ? filteredCity[indexPath.row] : displayCity[indexPath.row]
                cell.locationName = curLabel
                cell.postCount = self.currentPostTagCounts.allCounts[curLabel] ?? 0
                cell.defaultPostCount = self.noFilterTagCounts.allCounts[curLabel] ?? 0
                cell.isSelected = (curLabel == self.searchViewFilter.filterLocationSummaryID)

    //            cell.isSelected = (curLabel == self.viewFilter.filterLocationSummaryID)
    //            cell.tempView.backgroundColor = cell.isSelected ? UIColor.mainBlue().withAlphaComponent(0.2) : UIColor.white

            }
                
            else if selectedSegment == SearchRatingImage {
            // RATING EMOJIS
                if indexPath.row < self.displayRatingEmojis.count {
                    let cell = tableView.dequeueReusableCell(withIdentifier: EmojiCellId, for: indexPath) as! SearchResultsCell
                    let displayTerm = self.displayRatingEmojis[indexPath.row]
                    cell.emoji = displayTerm
                    cell.postCount = self.currentPostTagCounts.allCounts[displayTerm.emoji] ?? 0 + (self.currentPostTagCounts.allCounts[displayTerm.name!] ?? 0)
                    cell.defaultPostCount = self.noFilterTagCounts.allCounts[displayTerm.emoji] ?? 0 + (self.noFilterTagCounts.allCounts[displayTerm.name!] ?? 0)
                    cell.isSelected = self.searchViewFilter.searchTerms.contains(displayTerm.emoji) || self.searchViewFilter.searchTerms.contains(displayTerm.name!)
                    return cell
                }
                
            // STAR RATING
                else if indexPath.row < self.displayRatingEmojis.count + self.currentRatingCounts.count {
                    let cell = tableView.dequeueReusableCell(withIdentifier: searchRatingId, for: indexPath) as! SearchStarRatingCell
                    let curIndex = indexPath.row - self.displayRatingEmojis.count
                    var currentStarRating = self.currentStarRatingSequence[curIndex]
                    cell.selectPostStarRating = currentStarRating
                    cell.postCount = self.currentRatingCounts[self.currentStarRatingSequence[curIndex]] ?? 0
                    cell.isSelected = self.searchViewFilter.searchTerms.contains("\(currentStarRating) ⭐️")
                    return cell
                }
            }
        }
        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.cellForRow(at: indexPath)?.backgroundColor = UIColor.mainBlue().withAlphaComponent(0.2)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: EmojiCellId, for: indexPath) as! SearchResultsCell
        
//        cell.isSelected = !cell.isSelected
//        cell.backgroundColor = cell.isSelected ? UIColor.mainBlue().withAlphaComponent(0.2) : UIColor.white
        let isFiltering = self.searchFiltering
        
        if self.selectedSearchSegmentIndex == nil {
            let tempTerm = isFiltering ? self.filteredAllSearchItems[indexPath.row] : self.displyedAllSearchItems[indexPath.row]
            let searchTerm = tempTerm[0]
            let searchType = tempTerm[1]
            
            if searchType == SearchEmojis {
                var tempEmoji = Emoji(emoji: searchTerm, name: EmojiDictionary[searchTerm])
                if self.singleSearch {
                    self.singleSearchEmojiTerm(inputEmoji: tempEmoji)
                } else {
                    self.addEmojiToSearchTerm(inputEmoji: tempEmoji)
                }
            } else if searchType == SearchPlace {
                self.searchViewFilter.filterLocationName = searchTerm
                self.refreshSearchTerm()

                if self.singleSearch {
                    self.handleFilter()
                }
            } else if searchType == SearchCity {
                self.searchViewFilter.filterLocationSummaryID = searchTerm
                self.refreshSearchTerm()

                if self.singleSearch {
                    self.handleFilter()
                }
            }
        } else {
            let searchType = LegitSearchBarOptions[self.selectedSearchSegmentIndex!]
            
            if searchType == SearchFoodImage {
                let displayTerm = isFiltering ? self.filteredEmojis[indexPath.row] : self.displayEmojis[indexPath.row]
                let displayEmoji = displayTerm.emoji
                
                if self.singleSearch {
                    self.singleSearchEmojiTerm(inputEmoji: displayTerm)
                } else {
                    self.addEmojiToSearchTerm(inputEmoji: displayTerm)
                }
            }
            else if searchType == SearchCuisineImage {
                let displayTerm = isFiltering ? self.filteredCuisines[indexPath.row] : self.displayCuisines[indexPath.row]
                let typeName = displayTerm.name ?? ""
                
                if self.singleSearch {
                    self.singleSearchEmojiTerm(inputEmoji: displayTerm)
                } else {
                    self.addToSearchType(term: typeName)
    //                self.addEmojiToSearchTerm(inputEmoji: displayTerm)
                }

            }
                
            else if searchType == SearchRestaurantImage {
                let curLabel = isFiltering ? filteredPlaces[indexPath.row] : displayPlaces[indexPath.row]
                self.searchViewFilter.filterLocationName = curLabel
                self.refreshSearchTerm()

                if self.singleSearch {
                    self.handleFilter()
                }

            }
                
            else if searchType == SearchCityImage {
                let curLabel = isFiltering ? filteredCity[indexPath.row] : displayCity[indexPath.row]
                self.searchViewFilter.filterLocationSummaryID = curLabel
                self.refreshSearchTerm()
                if self.singleSearch {
                    self.handleFilter()
                }

            }
            
            else if searchType == SearchRatingImage {

                if indexPath.row < self.displayRatingEmojis.count {
                // RATING EMOJI
                    let displayTerm = self.displayRatingEmojis[indexPath.row]
                    let typeName = displayTerm.name ?? ""
                    let typeEmoji = displayTerm.emoji ?? ""
                    self.searchViewFilter.filterRatingEmoji = typeEmoji
                    self.handleFilter()
                } else if indexPath.row < self.displayRatingEmojis.count + self.currentRatingCounts.count {
                    let curIndex = indexPath.row - self.displayRatingEmojis.count
                    let selectedRating = self.currentStarRatingSequence[curIndex]
                    self.searchViewFilter.filterMinRating = Double(selectedRating)
                    self.handleFilter()
                }
    //            if self.singleSearch {
    //                self.viewFilter.filterRatingEmoji = typeEmoji
    ////                self.searchText = displayEmoji
    //                self.handleFilter()
    //            } else {
    //                self.addToSearchType(term: typeName)
    ////                self.addEmojiToSearchTerm(inputEmoji: displayTerm)
    //            }

            }
        }
   
        self.searchBar.text?.alphaNumericOnly()
        let temp = [indexPath]
        tableView.reloadRows(at: temp, with: .automatic)

    }
    
    func addToSearch(text: String?) {
        guard let text = text else {return}
        
        
        if allMealTypeOptions.contains(text) {
            // THIS IS A POSSIBLE CATEGORY, SO WE WIDER SEARCH CATEGORIES INSTEAD OF CAPTION
            self.addToSearchType(term: text)
        } else {
//            self.addEmojiToSearchTerm(inputEmoji: <#T##Emoji?#>)
        }
        
    }
    
    
    func addToSearchType(term: String?) {
        guard let term = term else {
            return
        }
        
        var tempArray = self.searchViewFilter.filterTypeArray
        
        if tempArray.count == 0 {
            tempArray.append(term)
        } else if tempArray.contains(term) {
            let oldCount = tempArray.count
            tempArray.removeAll { (text) -> Bool in
                text == term
            }
            let dif = tempArray.count - oldCount
            print("\(term) Exists | Remove \(dif) from Type | \(tempArray)")
        } else {
            tempArray.append(term)
            print("\(term) | Add To Type | \(tempArray)")
        }
    
    // CLEAN UP
        self.searchViewFilter.filterTypeArray = tempArray
        self.searchBar.text = ""
        self.restoreDefaultSearch()
        self.refreshSearchTerm()
        print("addToSearchType \(term) | \(self.searchTerms) | NOW: \(self.searchViewFilter.filterTypeArray)")
    
    }
    
    func addToSearchRating(term: String?) {
        guard let term = term else {
            return
        }
        
        if self.searchViewFilter.filterRatingEmoji == term {
            self.searchViewFilter.filterRatingEmoji = nil
        } else {
            self.searchViewFilter.filterRatingEmoji = term
        }
    
    // CLEAN UP
        self.searchBar.text = ""
        self.restoreDefaultSearch()
        self.refreshSearchTerm()
        print("addToSearchType \(term) | \(self.searchTerms) | NOW: \(self.searchViewFilter.filterTypeArray)")
    
    }
    
    func singleSearchEmojiTerm(inputEmoji: Emoji?) {
        guard let emoji = inputEmoji?.emoji else {return}
        var tempArray = self.searchViewFilter.filterCaptionArray
        
        if tempArray.contains(emoji) {
            tempArray.removeAll { (text) -> Bool in
                text == emoji
            }
        } else {
            tempArray = [emoji]
        }

        self.searchViewFilter.filterCaptionArray = tempArray
        self.handleFilter()
        print("singleSearchEmojiTerm \(emoji)")
    }
    
    func addEmojiToSearchTerm(inputEmoji: Emoji?) {
        guard let emoji = inputEmoji?.emoji else {return}
        var oldSearch = self.searchViewFilter.filterCaptionArray
        /*
        guard let oriSearch = self.searchText else {
            self.searchText = emoji
            self.refreshSearchTerm()
            return
        }
        var tempSearch = oriSearch
        
    // EMOJI ALREADY EXIST. REMOVE
        if oriSearch.contains(emoji) {
            tempSearch = oriSearch.replacingOccurrences(of: emoji, with: "")
            self.searchText = tempSearch
            print("\(emoji) | Removed from Search | \(self.searchTerms)")
        }
        
    // NEW EMOJI SEARCH
        else {
            tempSearch += " \(emoji)"
            self.searchText = tempSearch
        }
        */
        
        var tempArray = self.searchViewFilter.filterCaptionArray
        
        if tempArray.count == 0 {
            tempArray.append(emoji)
        } else if tempArray.contains(emoji) {
            let oldCount = tempArray.count
            tempArray.removeAll { (text) -> Bool in
                text == emoji
            }
            let dif = tempArray.count - oldCount
            print("\(emoji) Exists | Remove \(dif) from Search | \(tempArray)")
        } else {
            tempArray.append(emoji)
            print("\(emoji) | Add To Search | \(tempArray)")
        }
                
    
    // CLEAN UP
        self.searchViewFilter.filterCaptionArray = tempArray
        self.restoreDefaultSearch()
        self.refreshSearchTerm()
        print("addEmojiToSearchTerm \(emoji) | NEW: \(self.searchTerms) | OLD: \(oldSearch)")
    }
    
    func handleFilter(){
        
//        self.viewFilter.clearFilter()
//        self.viewFilter.filterCaption = self.searchText
//
//        if let loc = selectedPlace {
//            if let _ = self.noCaptionFilterPlaceCounts[loc] {
//                if let googleId = locationGoogleIdDictionary[loc] {
//                    self.viewFilter.filterGoogleLocationID = googleId
//                    print("Filter by GoogleLocationID | \(googleId)")
//                } else {
//                    self.viewFilter.filterLocationName = loc
//                    print("Filter by Location Name , No Google ID | \(loc)")
//                }
//            }
//        }
//
//        self.viewFilter.filterLocationSummaryID = self.selectedCity
        print("Filtering For \(self.searchViewFilter.searchTerms)")
        self.delegate?.filterControllerSelected(filter: self.searchViewFilter)
        dismissView()
    }
    
    func handleRefresh() {
        self.clearSearch()
        self.tableView.reloadData()
        self.refreshSearchTerm()
    }
    
    func clearSearch() {
//        self.selectedPlace = nil
//        self.selectedCity = nil
        self.searchText = nil
        self.searchTerms = []
        self.searchViewFilter.clearFilter()
        self.refreshSearchTerm()
    }

    
    
        // EMPTY DATA SET DELEGATES
        
        func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
            
            var text: String?
            var font: UIFont?
            var textColor: UIColor?
            
            if searchViewFilter.isFiltering {
                text = "Couldn't Find Anything Legit"
            } else {
                text = ""
    //            let number = arc4random_uniform(UInt32(tipDefaults.count))
    //            text = tipDefaults[Int(number)]
            }
            
            text = ""
            font = UIFont.boldSystemFont(ofSize: 17.0)
    //        textColor = UIColor(hexColor: "25282b")
            textColor = UIColor.ianBlackColor()

            
            if text == nil {
                return nil
            }
            
            return NSMutableAttributedString(string: text!, attributes: [NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.font: font])
            
        }
        
        func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
            
            var text: String?
            var font: UIFont?
            var textColor: UIColor?
            
            font = UIFont(name: "Poppins-Regular", size: 15)
            textColor = UIColor.ianBlackColor()
            
            if searchViewFilter.isFiltering {
                text = "Nothing Legit Here! 😭"
            } else {
                text = ""
            }
            
            if text == nil {
                return nil
            }
            
            return NSMutableAttributedString(string: text!, attributes: [NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.font: font])
            
        }
        
        func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
    //        return #imageLiteral(resourceName: "amaze").resizeVI(newSize: CGSize(width: view.frame.width/2, height: view.frame.height/2))
            return #imageLiteral(resourceName: "Legit_Vector")

        }
        
        
        func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {
            
            var text: String?
            var font: UIFont?
            var textColor: UIColor?
            
            if searchViewFilter.isFiltering {
                text = "Search For Something Else"
            } else {
                text = "Click to Discover New Things"
            }
            text = ""
            font = UIFont(name: "Poppins-Bold", size: 14)
            textColor = UIColor.ianBlueColor()
            
            if text == nil {
                return nil
            }
            
            return NSMutableAttributedString(string: text!, attributes: [NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.font: font])
            

        }
        
        //    func buttonBackgroundImage(forEmptyDataSet scrollView: UIScrollView, for state: UIControlState) -> UIImage? {
        //
        //        var capInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        //        var rectInsets = UIEdgeInsets.zero
        //
        //        capInsets = UIEdgeInsets(top: 25, left: 25, bottom: 25, right: 25)
        //        rectInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        //
        //        let image = #imageLiteral(resourceName: "emptydatasetbutton")
        //        return image.resizableImage(withCapInsets: capInsets, resizingMode: .stretch).withAlignmentRectInsets(rectInsets)
        //    }
        
        func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
    //        return UIColor.rgb(red: 249, green: 249, blue: 249)
            return UIColor.backgroundGrayColor()
        }
        
        func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {
            if searchViewFilter.isFiltering {
//                self.openFilter()
            } else {
                // Returns To Home Tab
                self.tabBarController?.selectedIndex = 1
            }
        }
        
        func emptyDataSet(_ scrollView: UIScrollView, didTapView view: UIView) {
            self.handleRefresh()
        }
        
        //    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        //        let offset = (self.collectionView.frame.height) / 5
        //        return -50
        //    }
        
        func spaceHeight(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
            return 9
        }
        
        
    
    
}
