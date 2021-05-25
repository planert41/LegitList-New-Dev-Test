//
//  SortFilterHeader.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 12/28/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit

import FirebaseAuth
import FirebaseDatabase

protocol NewUserProfileHeaderDelegate {
    func didChangeToPostView()
    func didChangeToGridView()
    //    func didSignOut()
    //    func activateSearchBar()
    func openSearch(index: Int?)
    func filterCaptionSelected(searchedText: String?)
    func clearCaptionSearch()
    func openFilter()
    func headerSortSelected(sort: String)
    func userSettings()
//    func openMap()
    
    func selectUserFollowers()
    func selectUserFollowing()
    func selectUserLists()
    func didSignOut()
    func editUser()
    func openSearch(index: Int)
    func didTapEmoji(index: Int?, emoji: String)
    func tapProfileImage(image: UIImage?)
    func toggleMapFunction()
}

class NewUserProfileHeader: UICollectionViewCell, UISearchBarDelegate, UIPickerViewDelegate, UIPickerViewDataSource, EmojiButtonArrayDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UploadEmojiCellDelegate {

    

    var delegate: NewUserProfileHeaderDelegate?
    
    
    // USER
    var user: User? {
        didSet{
            guard let profileImageUrl = user?.profileImageUrl else {return}
            profileImageView.loadImage(urlString: profileImageUrl)
            usernameLabel.text = user?.username
            setupEditFollowButton()
            setupSocialLabels()
            setupEmojiArray()
        }
    }
    
    var displayedEmojis: [String] = [] {
        didSet {
            print("NewUserProfileHeader | \(displayedEmojis.count) Emojis")
            self.emojiCollectionView.reloadData()
        }
    }

    
    // 0 For Default Header Sort Options, 1 for Location Sort Options
    var sortOptionsInd: Int = 0 {
        didSet{
            if sortOptionsInd == 0 {
                sortOptions = HeaderSortOptions
            } else if sortOptionsInd == 1 {
                sortOptions = LocationSortOptions
            } else {
                sortOptions = HeaderSortOptions
            }
        }
    }
    
    var selectedCaption: String? = nil {
        didSet{
            if !defaultSearchBar.isFirstResponder {
                guard let selectedCaption = selectedCaption else {
                    self.defaultSearchBar.text?.removeAll()
                    return}
                self.defaultSearchBar.text = selectedCaption
            }

        }
    }
    
    
    var sortOptions: [String] = HeaderSortOptions {
        didSet{
            self.updateSegments()
        }
    }
    
    
    lazy var sortButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(activateSort), for: .touchUpInside)
        //        button.layer.backgroundColor = UIColor.darkLegitColor().withAlphaComponent(0.8).cgColor
        button.layer.backgroundColor = UIColor.lightSelectedColor().cgColor
        
        //        button.setTitleColor(UIColor(hexColor: "f10f3c"), for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitleColor(UIColor.darkLegitColor(), for: .normal)
        
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.darkLegitColor().cgColor
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        return button
    }()
    
    var headerSortSegment = UISegmentedControl()
    
    var selectedSort: String = defaultRecentSort {
        didSet{
            self.underlineSegment(segment: sortOptions.firstIndex(of: selectedSort)!)
            headerSortSegment.selectedSegmentIndex = sortOptions.firstIndex(of: selectedSort)!
        }
    }
    var isFiltering: Bool = false {
        didSet{
            searchButton.backgroundColor = isFiltering ? UIColor.mainBlue() : UIColor.white
        }
    }
    
    lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "search_selected").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(openFilter), for: .touchUpInside)
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.clipsToBounds = true
        return button
    }()
    
    @objc func openFilter(){
        self.delegate?.openFilter()
    }
    
    lazy var searchButton: UIButton = {
        let button = UIButton(type: .system)
        let image = #imageLiteral(resourceName: "search_selected")
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(openSearch), for: .touchUpInside)
        button.tintColor = UIColor.legitColor()
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.layer.cornerRadius = 30/2
        button.clipsToBounds = true
        return button
    }()
    
    @objc func openSearch(){
        if let _ = self.delegate {
            self.delegate!.openSearch(index: 0)
        }
    }
    
    lazy var mapButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "googlemap_color").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(openMap), for: .touchUpInside)
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.clipsToBounds = true
        return button
    }()
    
    @objc func openMap(){
//        self.delegate?.openMap()
    }
    
    // Grid/List View Button
    var isGridView = true {
        didSet{
            formatButton.setImage(!self.isGridView ? #imageLiteral(resourceName: "grid") :#imageLiteral(resourceName: "postview"), for: .normal)
        }
    }
    
    lazy var formatButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(!self.isGridView ? #imageLiteral(resourceName: "postview") :#imageLiteral(resourceName: "grid"), for: .normal)
        button.addTarget(self, action: #selector(changeView), for: .touchUpInside)
        button.tintColor = UIColor.ianLegitColor()
        return button
    }()
    
    @objc func changeView(){
        if isGridView{
            self.isGridView = false
            delegate?.didChangeToPostView()
        } else {
            self.isGridView = true
            delegate?.didChangeToGridView()
        }
    }
    
// PROFILE VIEW
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        return iv
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "username"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    let followingLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let followersLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let listLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let postsLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        return label
    }()
    
    var profileCountStackView = UIStackView()

    
    lazy var editProfileFollowButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Options", for: .normal)
        button.titleLabel?.font =  UIFont(name: "Poppins-Bold", size: 12)
        button.titleLabel?.textColor = UIColor.white
        button.layer.borderColor = UIColor.ianLegitColor().cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 5
        button.backgroundColor = UIColor.white
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.addTarget(self, action: #selector(handleEditProfileOrFollow), for: .touchUpInside)
        return button
    }()
    
    var emojiArray = EmojiButtonArray(emojis: [], frame: CGRect(x: 0, y: 0, width: 0, height: 30))
    let emojiDetailLabel: PaddedUILabel = {
        let label = PaddedUILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.rgb(red: 255, green: 242, blue: 230)
        label.layer.cornerRadius = 20/2
        label.layer.borderWidth = 0.25
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.masksToBounds = true
        return label
    }()
    
    var profileView = UIView()
    var segmentView = UIView()
    var defaultSearchBarView = UIView()
    var defaultSearchBar = UISearchBar()
    
    let buttonBar = UIView()
    var buttonBarPosition: NSLayoutConstraint?

    
    let emojiCollectionView: UICollectionView = {
        let uploadEmojiList = UICollectionViewFlowLayout()
        uploadEmojiList.estimatedItemSize = CGSize(width: 30, height: 30)
        uploadEmojiList.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadEmojiList)
        cv.layer.borderWidth = 0
        cv.backgroundColor = UIColor.white
        return cv
    }()
    
    

    
    override init(frame: CGRect) {
        super.init(frame:frame)
        backgroundColor = UIColor.white
        
// SEARCH BAR VIEW
        // SEGMENT VIEW
        
        segmentView.backgroundColor = UIColor.white
        addSubview(segmentView)
        segmentView.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
        addSubview(formatButton)
        formatButton.anchor(top: segmentView.topAnchor, left: nil, bottom: segmentView.bottomAnchor, right: segmentView.rightAnchor, paddingTop: 1, paddingLeft: 3, paddingBottom: 1, paddingRight: 3, width: 0, height: 0)
        formatButton.widthAnchor.constraint(equalTo: formatButton.heightAnchor, multiplier: 1).isActive = true
        //        formatButton.layer.cornerRadius = formatButton.frame.width/2
        formatButton.layer.masksToBounds = true
        
        setupSegment()
        
        addSubview(headerSortSegment)
        headerSortSegment.anchor(top: segmentView.topAnchor, left: segmentView.leftAnchor, bottom: segmentView.bottomAnchor, right: formatButton.leftAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 3, paddingRight: 5, width: 0, height: 0)
        
        
        let segmentWidth = (self.frame.width - 50 - 10) / CGFloat(headerSortSegment.numberOfSegments)
        buttonBar.backgroundColor = UIColor.ianLegitColor()
        
        addSubview(buttonBar)
        buttonBar.anchor(top: nil, left: nil, bottom: headerSortSegment.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: segmentWidth, height: 5)
        buttonBar.leftAnchor.constraint(lessThanOrEqualTo: headerSortSegment.leftAnchor).isActive = true
        buttonBar.rightAnchor.constraint(lessThanOrEqualTo: headerSortSegment.rightAnchor).isActive = true
        buttonBarPosition = buttonBar.leftAnchor.constraint(equalTo: headerSortSegment.leftAnchor, constant: 0)
        self.underlineSegment(segment: sortOptions.firstIndex(of: self.selectedSort)!)
        
// SEARCH BAR VIEW
        addSubview(defaultSearchBarView)
        defaultSearchBarView.backgroundColor = UIColor.white
        defaultSearchBarView.anchor(top: nil, left: leftAnchor, bottom: segmentView.topAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)

        
        let screenWidth = UIScreen.main.bounds.width * 0.6

        setupEmojiCollectionView()
        addSubview(emojiCollectionView)
        emojiCollectionView.anchor(top: defaultSearchBarView.topAnchor, left: nil, bottom: defaultSearchBarView.bottomAnchor, right: defaultSearchBarView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: screenWidth, height: 0)
        
        
        setupSearchBar()
        addSubview(defaultSearchBar)
        defaultSearchBar.anchor(top: defaultSearchBarView.topAnchor, left: defaultSearchBarView.leftAnchor, bottom: defaultSearchBarView.bottomAnchor, right: emojiCollectionView.leftAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        

        
        
// PROFILE VIEW
        addSubview(profileView)
        profileView.anchor(top: topAnchor, left: leftAnchor, bottom: defaultSearchBarView.topAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        profileView.addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 80, height: 80)
        profileImageView.layer.cornerRadius = 80/2
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapProfileImage)))
        
        profileView.addSubview(usernameLabel)
        usernameLabel.anchor(top: profileImageView.bottomAnchor, left: profileImageView.leftAnchor, bottom: nil, right: profileImageView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 15)
        usernameLabel.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor).isActive = true
        usernameLabel.adjustsFontSizeToFitWidth = true
        
        let addProfileView = UIView()
        profileView.addSubview(addProfileView)
        addProfileView.anchor(top: nil, left: profileImageView.rightAnchor, bottom: profileView.bottomAnchor, right: profileView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)

//        profileView.addSubview(emojiArray)
//        emojiArray.anchor(top: addProfileView.topAnchor, left: addProfileView.leftAnchor, bottom: addProfileView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 20, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)
//        emojiArray.delegate = self
//        emojiArray.alignment = .left
//        emojiArray.backgroundColor = UIColor.clear

        // Edit Profile Button
        profileView.addSubview(editProfileFollowButton)
        editProfileFollowButton.anchor(top: addProfileView.topAnchor, left: nil, bottom: addProfileView.bottomAnchor, right: addProfileView.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 0, height: 0)
        
        
        let profileCountView = UIView()
        addSubview(profileCountView)
        profileCountView.anchor(top: profileImageView.topAnchor, left: profileImageView.rightAnchor, bottom: addProfileView.topAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        
        profileCountStackView = UIStackView(arrangedSubviews: [postsLabel, listLabel, followersLabel, followingLabel])
        profileCountStackView.distribution = .fillEqually
        profileCountStackView.axis = .horizontal
        addSubview(profileCountStackView)
        profileCountStackView.anchor(top: nil, left: profileCountView.leftAnchor, bottom: nil, right: profileCountView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        profileCountStackView.centerYAnchor.constraint(equalTo: profileCountView.centerYAnchor).isActive = true
        
        
        addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top: nil, left: profileCountView.leftAnchor, bottom: profileImageView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        emojiDetailLabel.sizeToFit()
        self.hideEmojiDetailLabel()

        
    }
    
        let emojiCellID = "emojiCellID"
    
    @objc func tapProfileImage(){
        guard let image = profileImageView.image else {
            print("UserProfileHeader | tapProfileImage | No Image")
            return}
        self.delegate?.tapProfileImage(image: image)
    }
    
    func setupEmojiCollectionView(){
        let uploadEmojiList = ListDisplayFlowLayoutCopy()
        //        uploadEmojiList.estimatedItemSize = CGSize(width: 30, height: 30)
        //        uploadEmojiList.sectionInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        //        uploadEmojiList.scrollDirection = .horizontal
        //        uploadEmojiList.scrollDirection = .horizontal
        
        emojiCollectionView.collectionViewLayout = uploadEmojiList
        emojiCollectionView.backgroundColor = UIColor.white
        emojiCollectionView.register(UploadEmojiCell.self, forCellWithReuseIdentifier: emojiCellID)
        emojiCollectionView.delegate = self
        emojiCollectionView.dataSource = self
        emojiCollectionView.allowsMultipleSelection = false
        emojiCollectionView.showsHorizontalScrollIndicator = false
        emojiCollectionView.backgroundColor = UIColor.clear
        emojiCollectionView.isScrollEnabled = true
    }
    
    func setupSegment(){
        
        headerSortSegment = UISegmentedControl(items: sortOptions)
        headerSortSegment.selectedSegmentIndex = sortOptions.firstIndex(of: self.selectedSort)!
        headerSortSegment.addTarget(self, action: #selector(selectSort), for: .valueChanged)
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        headerSortSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
        headerSortSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)
        
        headerSortSegment.backgroundColor = .white
        headerSortSegment.tintColor = .white
    }
    
    func underlineSegment(segment: Int? = 0){
        
        let segmentWidth = (self.frame.width - 50) / CGFloat(self.headerSortSegment.numberOfSegments)
        let tempX = self.buttonBar.frame.origin.x
        UIView.animate(withDuration: 0.3) {
            self.buttonBar.frame.origin.x = segmentWidth * CGFloat(segment ?? 0)
            self.buttonBarPosition?.constant = segmentWidth * CGFloat(segment ?? 0)
            self.buttonBarPosition?.isActive = true
        }
        
        //        print("UnderlineSegment | Segment \(segment!) | Pre ",tempX, " | Post ", self.buttonBar.frame.origin.x)
        
    }
    
    func userSettings(){
        guard let uid = Auth.auth().currentUser?.uid else {return}
        self.delegate?.userSettings()
    }

    
    func setupEmojiArray(){
        if let displayEmojis = self.user?.topEmojis{
            emojiArray.emojiLabels = Array(displayEmojis.prefix(3))
            //            emojiArrayHideConstraint?.isActive = false
        } else {
            emojiArray.emojiLabels = []
            //            emojiArrayHideConstraint?.isActive = true
        }
        emojiArray.setEmojiButtons()
        emojiArray.sizeToFit()
    }
    
    func hideEmojiDetailLabel(){
        self.emojiDetailLabel.alpha = 0
    }
    
    func didTapEmoji(index: Int?, emoji: String) {
        guard let index = index else {
            print("No Index For emoji \(emoji)")
            return
        }
        
        let displayEmoji = emoji
        var displayTag = displayEmoji
        
        print("Selected Emoji \(emoji) : \(index)")
        if displayTag == displayEmoji {
            if let _ = EmojiDictionary[displayEmoji] {
                displayTag = EmojiDictionary[displayEmoji]!
            } else {
                print("No Dictionary Value | \(displayTag)")
                displayTag = ""
            }
        }
        
        var captionDelay = 2
        emojiDetailLabel.text = "\(displayEmoji)  \(displayTag)"
        emojiDetailLabel.alpha = 1
        emojiDetailLabel.adjustsFontSizeToFitWidth = true
        //        emojiDetailLabel.sizeToFit()
        
        UIView.animate(withDuration: 0.5, delay: TimeInterval(captionDelay), options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.emojiDetailLabel.alpha = 0
        }, completion: { (finished: Bool) in
        })
    }
    
    func doubleTapEmoji(index: Int?, emoji: String) {
        print("NewUserProfileHeader | Double Tap | \(emoji)")
        
        let emojiDic = EmojiDictionary[emoji] ?? ""
        let emojiInput = "\(emoji) \(emojiDic)"
        
        if self.selectedCaption == emojiInput {
            self.delegate?.clearCaptionSearch()
        } else {
            self.delegate?.filterCaptionSelected(searchedText: emojiInput)
        }
    }
    
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displayedEmojis.count

    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emojiCellID, for: indexPath) as! UploadEmojiCell
        let displayEmoji = self.displayedEmojis[indexPath.item]
        let isFiltered = selectedCaption?.contains(displayEmoji) ?? false
        cell.uploadEmojis.text = displayEmoji
        cell.uploadEmojis.font = cell.uploadEmojis.font.withSize(25)
        cell.layer.borderWidth = 0
        cell.delegate = self
        //Highlight only if emoji is tagged, dont care about caption
        //        cell.backgroundColor = isFiltered ? UIColor.selectedColor() : UIColor.clear
        cell.backgroundColor = isFiltered ? UIColor.ianLegitColor() : UIColor.clear
        
        cell.layer.borderColor = UIColor.white.cgColor
        cell.isSelected = isFiltered
        cell.sizeToFit()
        return cell
    }
    

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = indexPath.row
        let emoji = self.displayedEmojis[indexPath.row]
        
        self.delegate?.didTapEmoji(index: indexPath.row, emoji: self.displayedEmojis[indexPath.row])
    }
    
    func didTapRatingEmoji(emoji: String) {
        self.delegate?.didTapEmoji(index: self.displayedEmojis.firstIndex(of: emoji), emoji: emoji)
    }
    
    func didTapNonRatingEmoji(emoji: String) {
        self.delegate?.didTapEmoji(index: self.displayedEmojis.firstIndex(of: emoji), emoji: emoji)
    }
    
    
    @objc func updateSegments(){
        for i in 0..<headerSortSegment.numberOfSegments {
            if headerSortSegment.titleForSegment(at: i) != sortOptions[i] {
                //Update Segment Label
                headerSortSegment.setTitle(sortOptions[i], forSegmentAt: i)
            }
        }
    }
    
    @objc func selectSort(sender: UISegmentedControl) {
        self.selectedSort = sortOptions[sender.selectedSegmentIndex]
        let when = DispatchTime.now() + 0.5 // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            //Delay for 1 second for animation
            self.delegate?.headerSortSelected(sort: self.selectedSort)
        }
        print("Selected Sort is ",self.selectedSort)
    }
    
    func setupSearchBar(){
        defaultSearchBar.layer.cornerRadius = 1
        defaultSearchBar.layer.masksToBounds = true
        defaultSearchBar.clipsToBounds = true
        //        defaultSearchBar.searchBarStyle = .prominent
        defaultSearchBar.searchBarStyle = .minimal
        
        defaultSearchBar.barTintColor = UIColor.legitColor()
        defaultSearchBar.tintColor = UIColor.white
        //        defaultSearchBar.backgroundImage = UIImage()
        defaultSearchBar.layer.borderWidth = 0
        defaultSearchBar.layer.borderColor = UIColor.darkGray.cgColor
        defaultSearchBar.placeholder = "Search"
        defaultSearchBar.delegate = self
        //        defaultSearchBar.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        
        let textFieldInsideSearchBar = defaultSearchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = UIColor.darkLegitColor()
        
        for s in defaultSearchBar.subviews[0].subviews {
            if s is UITextField {
//                s.backgroundColor = UIColor.white
                
                if let backgroundview = s.subviews.first {
                    
                // Background color
                    backgroundview.backgroundColor = UIColor.white
            
                // Rounded corner
                    backgroundview.layer.cornerRadius = 30/2
                    backgroundview.layer.masksToBounds = true
                    backgroundview.clipsToBounds = true
                }
                
//                s.layer.cornerRadius = 25/2
//                s.layer.borderWidth = 1
//                s.layer.borderColor = UIColor.gray.cgColor
            }
        }
    }
//
//    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
//        self.delegate?.openSearch(index: 0)
//        return false
//    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText.count == 0) {
            searchBar.endEditing(true)
            self.selectedCaption = nil
            self.delegate?.clearCaptionSearch()
        } else {
            self.delegate?.filterCaptionSelected(searchedText: searchBar.text)
            self.defaultSearchBar.becomeFirstResponder()
        }
    }
    
    
    //    func setupSearchBar(){
    //        searchBar.layer.cornerRadius = 25/2
    //        searchBar.clipsToBounds = true
    //        searchBar.searchBarStyle = .prominent
    //        searchBar.barTintColor = UIColor.white
    //        //        defaultSearchBar.backgroundImage = UIImage()
    //        searchBar.layer.borderWidth = 0
    //        searchBar.placeholder = "Search Lists"
    //        searchBar.delegate = self
    //    }
    //
    //    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    //        if (searchText.count == 0) {
    //            self.isFiltering = false
    //        } else {
    //            self.delegate?.filterCaptionSelected(searchedText: searchBar.text)
    //        }
    //    }
    
    
// SOCIAL LABELS
    
    func setupSocialLabels(){
        let postCount = user?.posts_created ?? 0
        let followingCount = user?.followingCount ?? 0
        let followerCount = user?.followersCount ?? 0
        let listCount = user?.lists_created ?? 0
        let voteCount = user?.votes_received ?? 0
        
        
        let socialLabelColor = UIColor.ianLegitColor()
        let socialMetricColor = UIColor.ianBlackColor()
        
        let socialMetricFont = UIFont(name: "Poppins-Bold", size: 20)
        let socialLabelFont = UIFont(font: .avenirHeavy, size: 15)
        
        let voteLabelSize = 12 as CGFloat
        let socialLabelSize = 15 as CGFloat
        
        let countFontSize = 15 as CGFloat
        let unitFontSize = 12 as CGFloat
        
        // Followers Label
        
        var attributedMetric = NSMutableAttributedString(string: "\(String(followerCount))", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): socialMetricFont, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): socialMetricColor]))
        
        var attributedLabel = NSMutableAttributedString(string: "\n followers", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): socialLabelFont, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): socialLabelColor]))
        
        
        attributedMetric.append(attributedLabel)
        self.followersLabel.attributedText = attributedMetric
        self.followersLabel.sizeToFit()
        self.followersLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectFollowers)))
        self.followersLabel.isUserInteractionEnabled = true
        
        
        // Following Label
        
        attributedMetric = NSMutableAttributedString(string: "\(String(followingCount))", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): socialMetricFont, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): socialMetricColor]))
        attributedLabel = NSMutableAttributedString(string: "\n following", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): socialLabelFont, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): socialLabelColor]))
        
        attributedMetric.append(attributedLabel)
        self.followingLabel.attributedText = attributedMetric
        self.followingLabel.sizeToFit()
        self.followingLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectFollowing)))
        self.followingLabel.isUserInteractionEnabled = true
        
        
        // List Count Label
        attributedMetric = NSMutableAttributedString(string: "\(String(listCount))", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): socialMetricFont, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): socialMetricColor]))
        attributedLabel = NSMutableAttributedString(string: "\n lists", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): socialLabelFont, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): socialLabelColor]))
        
        attributedMetric.append(attributedLabel)
        self.listLabel.attributedText = attributedMetric
        self.listLabel.sizeToFit()
        self.listLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectLists)))
        self.listLabel.isUserInteractionEnabled = true
        
        
        // Post Count Label
        attributedMetric = NSMutableAttributedString(string: "\(String(postCount))", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): socialMetricFont, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): socialMetricColor]))
        attributedLabel = NSMutableAttributedString(string: "\n posts", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): socialLabelFont, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): socialLabelColor]))
        
        attributedMetric.append(attributedLabel)
        self.postsLabel.attributedText = attributedMetric
        self.postsLabel.sizeToFit()
        
        
    }
    
    @objc func selectFollowers(){
        print("User Profile: Select Follower")
        self.delegate?.selectUserFollowers()
    }
    
    @objc func selectFollowing(){
        print("User Profile: Select Following")
        self.delegate?.selectUserFollowing()
    }
    
    @objc func selectLists(){
        print("User Profile: Select Lists")
        self.delegate?.selectUserLists()
    }
    
// FOLLOW BUTTON
    
    
    fileprivate func setupEditFollowButton() {
        guard let currentLoggedInUserID = Auth.auth().currentUser?.uid else {return}
        guard let userId = user?.uid else {return}
        
        if currentLoggedInUserID == userId {
            self.setupFollowStyle()
//            //                Edit Profile
//            self.editProfileFollowButton.setTitle("Options", for: .normal)
//            self.editProfileFollowButton.backgroundColor = UIColor.mainBlue()
//            self.editProfileFollowButton.titleLabel?.textColor = UIColor.white
//            self.editProfileFollowButton.layer.borderColor = UIColor.white.cgColor
        }else {
            
            // check if following
            Database.database().reference().child("following").child(currentLoggedInUserID).child(userId).observeSingleEvent(of: .value, with: { (snapshot) in
                
                if let isFollowing = snapshot.value as? Int, isFollowing == 1 {
                    
                    self.editProfileFollowButton.setTitle("Following", for: .normal)
                    self.editProfileFollowButton.backgroundColor = UIColor.white
                    
                } else{
                    self.setupFollowStyle()
                    
                }
                
            }, withCancel: { (err) in
                
                print("Failed to check if following", err)
                
            })
            
        }
    }
    
    @objc func handleEditProfileOrFollow() {
        
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else {return}
        guard let userId = user?.uid else {return}
        if (currentLoggedInUserId == userId && self.editProfileFollowButton.titleLabel?.text == "Options"){
            self.delegate?.userSettings()
        } else if self.editProfileFollowButton.titleLabel?.text == "Following" || self.editProfileFollowButton.titleLabel?.text == "Follow" {
            Database.handleFollowing(userUid: userId) { }
            self.user?.isFollowing = !(self.user?.isFollowing)!
            self.user?.followersCount += (self.user?.isFollowing)! ? 1 : -1
            self.setupFollowStyle()
        }
    }

    fileprivate func setupFollowStyle(){
        
        if Auth.auth().currentUser?.uid == user?.uid {
            // Edit Profile
            self.editProfileFollowButton.setTitle("Options", for: .normal)
            self.editProfileFollowButton.setTitleColor(UIColor.white, for: .normal)
            self.editProfileFollowButton.backgroundColor = UIColor.mainBlue()
            self.editProfileFollowButton.layer.borderColor = UIColor.white.cgColor
        }
        
        else if (user?.isFollowing)!
        {
            self.editProfileFollowButton.setTitle("Following", for: .normal)
            self.editProfileFollowButton.setTitleColor(UIColor.ianLegitColor(), for: .normal)
            self.editProfileFollowButton.layer.borderColor = UIColor.ianLegitColor().cgColor
            self.editProfileFollowButton.backgroundColor = UIColor.white
            self.setupSocialLabels()
        }
        else
        {
            self.editProfileFollowButton.setTitle("Follow", for: .normal)
            self.editProfileFollowButton.backgroundColor = UIColor.ianLegitColor()
            self.editProfileFollowButton.setTitleColor(UIColor.white, for: .normal)
            self.editProfileFollowButton.layer.borderColor = UIColor.white.cgColor
            self.setupSocialLabels()
        }
     
    }
    
    // Set Up Range Picker for Distance Filtering
    
    lazy var dummyTextView: UITextView = {
        let tv = UITextView()
        return tv
    }()
    
    var pickerView: UIPickerView = {
        let pv = UIPickerView()
        pv.backgroundColor = .white
        pv.showsSelectionIndicator = true
        return pv
    }()
    
    func setupSortPicker() {
        var toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        
        toolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Select Sort", style: UIBarButtonItem.Style.bordered, target: self, action: Selector("donePicker"))
        doneButton.setTitleTextAttributes(convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.legitColor()]), for: .normal)
        
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.bordered, target: self, action: Selector("cancelPicker"))
        cancelButton.setTitleTextAttributes(convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.red]), for: .normal)
        
        var toolbarTitle = UILabel()
        //        toolbarTitle.text = "Select Range"
        toolbarTitle.textAlignment = NSTextAlignment.center
        let toolbarTitleButton = UIBarButtonItem(customView: toolbarTitle)
        
        let space1Button = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let space2Button = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        
        toolBar.setItems([cancelButton,space1Button, toolbarTitleButton,space2Button, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        
        pickerView.delegate = self
        pickerView.dataSource = self
        self.dummyTextView.inputView = pickerView
        self.dummyTextView.inputAccessoryView = toolBar
        self.addSubview(dummyTextView)
        self.sortButton.setTitle(self.selectedSort + "🔽", for: .normal)
    }
    
    // UIPicker Delegate Functions
    
    @objc func activateSort() {
        let rangeIndex = sortOptions.firstIndex(of: self.selectedSort)
        pickerView.selectRow(rangeIndex!, inComponent: 0, animated: false)
        dummyTextView.perform(#selector(becomeFirstResponder), with: nil, afterDelay: 0.1)
    }
    
    func donePicker(){
        self.selectedSort = sortOptions[pickerView.selectedRow(inComponent: 0)]
        print("Sort Selected: \(self.selectedSort)")
        dummyTextView.resignFirstResponder()
        delegate?.headerSortSelected(sort: self.selectedSort)
    }
    
    func cancelPicker(){
        dummyTextView.resignFirstResponder()
    }
    
    
    // UIPicker DataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
        
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return sortOptions.count
    }
    
    // UIPicker Delegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        var options = sortOptions[row]
        return options
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectedSort = sortOptions[pickerView.selectedRow(inComponent: 0)]
        print("Sort Selected: \(self.selectedSort)")
        dummyTextView.resignFirstResponder()
        delegate?.headerSortSelected(sort: self.selectedSort)
        // If Select some number
        //        self.selectedRange = selectedRangeOptions[row]
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
