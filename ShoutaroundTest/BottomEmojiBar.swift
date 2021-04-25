//
//  BottomEmojiBar.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 12/29/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit

protocol BottomEmojiBarDelegate {
    func didTapSearchButton()
    func didTapAddTag(addTag: String)
    func didRemoveTag(tag: String)
    func didRemoveLocationFilter(location: String)
    func didRemoveRatingFilter(rating: String)
    func didTapCell(tag: String)

    func handleRefresh()
}

class BottomEmojiBar: UIView {
 
    var delegate: BottomEmojiBarDelegate?
    var navSearchButton: UIButton = TemplateObjects.NavSearchButton()
    var searchTerms: [String] = []
    var searchTermsType: [String] = []

    var filteredPostCount = 0
    var viewFilter: Filter = Filter.init(defaultSort: defaultRecentSort) {
        didSet {
            self.updateSearchTerms()
            self.updateSearchButton()
        }
    }
    

    let tapEmojiCollectionView = UITapGestureRecognizer(target: self, action: #selector(didTapSearchButton))
    
    let emojiCollectionView: UICollectionView = {
        let uploadEmojiList = UICollectionViewFlowLayout()
//        uploadEmojiList.estimatedItemSize = CGSize(width: 120, height: 35)
        uploadEmojiList.estimatedItemSize = CGSize(width: 60, height: 35)

        uploadEmojiList.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        uploadEmojiList.scrollDirection = .horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadEmojiList)
        cv.layer.borderWidth = 0
        cv.backgroundColor = UIColor.white
        return cv
    }()
    
    var displayedEmojis: [String] = [] {
        didSet {
//            print("Bottom Emoji Bar | \(displayedEmojis.count) Emojis")
            self.refreshEmojiCollectionView()
        }
    }
    
    var listDefaultEmojis = mealEmojisSelect
    
    let addTagId = "addTagId"
    let filterTagId = "filterTagId"
    let refreshTagId = "refreshTagId"

    var navSearchButtonEqualWidth: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        
        addSubview(navSearchButton)
        navSearchButton.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 30)
        navSearchButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        navSearchButton.layer.cornerRadius = 5
        navSearchButton.layer.masksToBounds = true
        navSearchButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
//        navSearchButtonEqualWidth = navSearchButton.widthAnchor.constraint(equalTo: navSearchButton.heightAnchor, multiplier: 1)
        navSearchButtonEqualWidth = navSearchButton.widthAnchor.constraint(equalToConstant: 30)
        navSearchButtonEqualWidth?.isActive = true
        updateSearchButton()
        
        addSubview(emojiCollectionView)
        emojiCollectionView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: navSearchButton.leftAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 10, width: 0, height: 40)
        setupEmojiCollectionView()
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func didTapSearchButton() {
        print("Tap Search Button | BottomEmojiBar")
        self.delegate?.didTapSearchButton()
    }

    func updateSearchTerms() {
        searchTerms = self.viewFilter.searchTerms
        searchTermsType = self.viewFilter.searchTermsType
//        searchTerms = Array(Set(self.viewFilter.searchTerms))
//        print("Bottom Emoji Bar | Selected Filters | \(searchTerms)")
        if self.viewFilter.isFiltering {
            self.emojiCollectionView.addGestureRecognizer(tapEmojiCollectionView)
        } else {
            self.emojiCollectionView.removeGestureRecognizer(tapEmojiCollectionView)
        }
        self.emojiCollectionView.reloadData()
    }
    
    func updateSearchButton() {
        let search = UITapGestureRecognizer(target: self, action: #selector(didTapSearchButton))
        navSearchButton.setTitle(self.viewFilter.isFiltering ? "" : " Search", for: .normal)
        navSearchButtonEqualWidth?.isActive = self.viewFilter.isFiltering
        navSearchButton.setTitleColor(UIColor.ianBlackColor(), for: .normal)
        navSearchButton.setImage(#imageLiteral(resourceName: "search_selected").withRenderingMode(.alwaysTemplate), for: .normal)
        navSearchButton.tintColor = UIColor.ianBlackColor()
        navSearchButton.layer.borderColor = UIColor.ianBlackColor().cgColor
        navSearchButton.addGestureRecognizer(search)
        navSearchButton.sizeToFit()
    }
    
    
    
}

extension BottomEmojiBar: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func refreshEmojiCollectionView() {
        if self.viewFilter.isFiltering {
            self.emojiCollectionView.addGestureRecognizer(tapEmojiCollectionView)
        } else {
            self.emojiCollectionView.removeGestureRecognizer(tapEmojiCollectionView)
        }
        self.emojiCollectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .left, animated: false)
        self.emojiCollectionView.reloadData()
    }
    
    func setupEmojiCollectionView(){
        emojiCollectionView.backgroundColor = UIColor.clear
        emojiCollectionView.register(HomeFilterBarCell.self, forCellWithReuseIdentifier: addTagId)
        emojiCollectionView.register(SelectedFilterBarCell.self, forCellWithReuseIdentifier: filterTagId)
        emojiCollectionView.register(RefreshFilterBarCell.self, forCellWithReuseIdentifier: refreshTagId)

        emojiCollectionView.delegate = self
        emojiCollectionView.dataSource = self
        emojiCollectionView.showsHorizontalScrollIndicator = false
        emojiCollectionView.isScrollEnabled = true
        
//        emojiCollectionView.addGestureRecognizer(tapEmojiCollectionView)
        refreshEmojiCollectionView()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.viewFilter.isFiltering {
            //print("SearchTerms \(searchTerms.count) | \(searchTerms)")
            return searchTerms.count + 1
            
        } else {
        //  SHOW DEFAULT EMOJIS IF NO EMOJIS FROM FEED - TO WORK AROUND BLANK INITIAL VIEW WHEN LOADING
            return (displayedEmojis.count == 0 ? listDefaultEmojis.count : displayedEmojis.count) + 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: addTagId, for: indexPath) as! HomeFilterBarCell
        var isSelected = false

    // FILTER SELECTED
        if self.viewFilter.isFiltering {
            if indexPath.item == 0 {
            let refreshCell = collectionView.dequeueReusableCell(withReuseIdentifier: refreshTagId, for: indexPath) as! RefreshFilterBarCell
                refreshCell.delegate = self
//                var displayText = "Search Terms"
                var displayText = "\(filteredPostCount) \nPosts"

                refreshCell.uploadLocations.text = displayText
                refreshCell.uploadLocations.font =  UIFont.boldSystemFont(ofSize: 10)
                refreshCell.uploadLocations.textColor = UIColor.ianBlackColor()
                refreshCell.uploadLocations.sizeToFit()
                refreshCell.backgroundColor = isSelected ? UIColor.ianOrangeColor() : UIColor.clear
                refreshCell.backgroundColor = UIColor.ianOrangeColor()
                refreshCell.sizeToFit()
                refreshCell.layoutIfNeeded()

                return refreshCell

            } else {
                    let filterCell = collectionView.dequeueReusableCell(withReuseIdentifier: filterTagId, for: indexPath) as! SelectedFilterBarCell
        //            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: addTagId, for: indexPath) as! HomeFilterBarCell
                    var displayTerm = searchTerms[indexPath.item - 1].capitalizingFirstLetter()
                    var displayTermType = searchTermsType[indexPath.item - 1]
                    
                    var isEmoji = displayTerm.containsOnlyEmoji
                    var searchTextColor = UIColor.ianBlackColor()
                
                    filterCell.searchTerm = displayTerm
                    filterCell.searchTermType = displayTermType

                if displayTermType == SearchCaption{
                    searchTextColor = UIColor.ianBlackColor()
                    if let text = EmojiDictionary[displayTerm] {
                        displayTerm += " \(text.capitalizingFirstLetter())"
                    }
                } else if displayTermType == SearchRating{
                    searchTextColor = UIColor.ianLegitColor()
                    if let text = extraRatingEmojisDic[displayTerm] {
                        displayTerm += " \(text.capitalizingFirstLetter())"
                    }
                } else if (displayTermType == SearchPlace || displayTermType == SearchCity) {
                    searchTextColor = UIColor.mainBlue()
                }
                

                    filterCell.uploadLocations.text = displayTerm
                    filterCell.uploadLocations.sizeToFit()
                    //print("Filter Cell | \(filterCell.uploadLocations.text) | \(indexPath.item - 1)")

                
                
                
                
                filterCell.uploadLocations.font =  isEmoji ? UIFont(name: "Poppins-Bold", size: 12) : UIFont(name: "Poppins-Regular", size: 12)
                    filterCell.uploadLocations.textColor = searchTextColor
                filterCell.layer.borderColor = filterCell.uploadLocations.textColor.cgColor
                filterCell.layer.borderColor = UIColor.lightGray.cgColor

                    filterCell.uploadLocations.sizeToFit()
                    filterCell.delegate = self
        //            filterCell.backgroundColor = UIColor.mainBlue()
                    filterCell.isUserInteractionEnabled = true
                    filterCell.layoutIfNeeded()
                    return filterCell

            }
        }
    // NO FILTER SELECTED
        else {
            if indexPath.item == 0 {
            
                var displayText = "Top\nFilter Tags"
                
                if self.viewFilter.filterSort == sortNew {
                    displayText = "Recent \nFilter Tags"
                } else if self.viewFilter.filterSort == sortNearest {
                    displayText = "Nearest \nFilter Tags"
                } else if self.viewFilter.filterSort == sortTrending {
                    displayText = "Trending \nFilter Tags"
                }

                cell.uploadLocations.text = displayText
                cell.uploadLocations.font =  UIFont.boldSystemFont(ofSize: 10)
                cell.uploadLocations.textColor = UIColor.ianGrayColor()
                cell.uploadLocations.sizeToFit()
                cell.backgroundColor = isSelected ? UIColor.ianOrangeColor() : UIColor.clear
                return cell

            } else {
                let option = (displayedEmojis.count == 0) ? listDefaultEmojis[indexPath.item - 1].lowercased() : displayedEmojis[indexPath.item - 1].lowercased()
                var isSelected = self.viewFilter.filterCaption?.contains(option) ?? false
                cell.uploadLocations.text = option
                cell.uploadLocations.font =  UIFont(name: "Poppins-Bold", size: 20)
                cell.uploadLocations.textColor = UIColor.ianBlackColor()

                cell.uploadLocations.sizeToFit()
                cell.backgroundColor = isSelected ? UIColor.ianOrangeColor() : UIColor.clear
                return cell

            }
        }
    }
    
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    //        let emoji = displayedEmojis[indexPath.item].lowercased()
            
            if self.viewFilter.isFiltering {
                print("Open search From Emoji CV")
                self.delegate?.didTapSearchButton()

            }
            
            else if indexPath.row == 0 {
                return
            } else {
                let emoji = (displayedEmojis.count == 0) ? listDefaultEmojis[indexPath.row - 1].lowercased() : displayedEmojis[indexPath.row - 1].lowercased()
                print("\(emoji) SELECTED | CV didSelect")

                self.delegate?.didTapAddTag(addTag: emoji)
            }
        }
        
    
}

extension BottomEmojiBar: RefreshFilterBarCellDelegate, SelectedFilterBarCellDelegate {
    
    func didTapCell(tag: String) {
        print("BottomEmojiBar didTapCell :", tag)
        self.delegate?.didTapCell(tag: tag)
    }

    func didRemoveLocationFilter(location: String) {
        self.delegate?.didRemoveLocationFilter(location: location)
    }
    
    func didRemoveRatingFilter(rating: String) {
        self.delegate?.didRemoveRatingFilter(rating: rating)
    }
    
    func handleRefresh() {
        self.delegate?.handleRefresh()
    }
    
    func didRemoveTag(tag: String) {
        self.delegate?.didRemoveTag(tag: tag)
    }
    



}
