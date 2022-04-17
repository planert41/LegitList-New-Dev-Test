//
//  EmojiSummaryCV.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 5/27/20.
//  Copyright © 2020 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

protocol EmojiSummaryCVDelegate {
    func didTapEmoji(emoji: String)
}


class EmojiSummaryCV: UIView{
    
    let addTagId = "addTagId"
    let filterTagId = "filterTagId"
    let refreshTagId = "refreshTagId"
    
    var delegate: EmojiSummaryCVDelegate?
    
    var viewFilter: Filter = Filter.init(defaultSort: defaultRecentSort){
        didSet {
            if oldValue.filterSummary() != self.viewFilter.filterSummary() {
                print("EmojiSummaryCV | ViewFilter Updated | \(self.viewFilter.filterSort) | CUR: \(self.viewFilter.searchTerms)")
                self.sortEmojis()
//                self.emojiCollectionView.reloadData()
            }
        }
    }
    
    var displayUser: User? {
        didSet {
            self.displayUserBadges = displayUser?.userBadges ?? []
            self.displayCity = displayUser?.userCity ?? nil
        }
    }
    var displayUserBadges: [Int] = []
    var showBadges: Bool = false

    var displayedEmojis: [String] = [] {
        didSet {
            if oldValue != self.displayedEmojis{
                print("EmojiSummaryCV | \(displayUser?.username) | Displayed Emojis: \(self.displayedEmojis.count)")
                self.refreshEmojiCollectionView()
            }
        }
    }
    
    var displayedEmojisCounts: [String:Int] = [:] {
        didSet {
            self.sortEmojis()
//            let temp = self.displayedEmojisCounts.sorted(by: {$0.value > $1.value})
//            var tempArray: [String] = []
//            for (key, value) in temp {
//                if value > 0 {
//                    tempArray.append(key)
//                }
//            }
////            print("EmojiSummaryCV | \(displayUser?.username) | Loaded displayedEmojisCounts : \(displayedEmojisCounts.count) | \(displayedEmojisCounts)")
//            self.displayedEmojis = tempArray

        }
    }
    
    var displayCity: String?
    var showCity: Bool = false

    func sortEmojis() {
//        let temp = self.displayedEmojisCounts.sorted(by: {$0.value > $1.value})
        
        let temp = self.displayedEmojisCounts.sorted { (p1, p2) -> Bool in
            let p1Filter = self.viewFilter.filterCaptionArray.contains(p1.key) ? 1 : 0
            let p2Filter = self.viewFilter.filterCaptionArray.contains(p2.key) ? 1 : 0
            if p1Filter == p2Filter {
                return p1.value > p2.value
            } else {
                return p1Filter > p2Filter
            }
        }

        var tempArray: [String] = []
        for (key, value) in temp {
            if value > 0 {
                tempArray.append(key)
            }
        }
        
        self.displayedEmojis = tempArray
        self.emojiCollectionView.reloadData()

        
    }
     
    let emojiCollectionView: UICollectionView = {
        let uploadEmojiList = UICollectionViewFlowLayout()
//        uploadEmojiList.estimatedItemSize = CGSize(width: 120, height: 35)
        uploadEmojiList.estimatedItemSize = CGSize(width: 60, height: 35)

        uploadEmojiList.sectionInset = UIEdgeInsets(top: 2, left: 5, bottom: 2, right: 5)
        uploadEmojiList.scrollDirection = .horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadEmojiList)
        cv.layer.borderWidth = 0
        cv.backgroundColor = UIColor.white
        return cv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        addSubview(emojiCollectionView)
        emojiCollectionView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 10, width: 0, height: 40)
        setupEmojiCollectionView()
        
        
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func refreshEmojiCollectionView() {
        if self.emojiCollectionView.numberOfItems(inSection: 0) > 0 {
            self.emojiCollectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .left, animated: false)
        }
        self.emojiCollectionView.reloadData()
    }
    
    
    
    
}

extension EmojiSummaryCV: UICollectionViewDelegate, UICollectionViewDataSource, SelectedFilterBarCellDelegate {
    func didTapCell(tag: String) {
        print("didTapCell ", tag)
        self.delegate?.didTapEmoji(emoji: tag)
    }
    
    func didRemoveTag(tag: String) {
        self.delegate?.didTapEmoji(emoji: tag)
    }
    
    func didRemoveLocationFilter(location: String) {
    }
    
    func didRemoveRatingFilter(rating: String) {
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        var cellCount = displayedEmojis.count
    
        if showBadges {
            cellCount += (displayUserBadges.count ?? 0)
        }
        
        if showCity {
            cellCount += (displayCity != nil ? 1 : 0)
        }
//        else {
//            cellCount = displayedEmojis.count
//        }
//        print("EmojiSummaryCV | \(cellCount) Cells")
        return cellCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let filterCell = collectionView.dequeueReusableCell(withReuseIdentifier: filterTagId, for: indexPath) as! SelectedFilterBarCell
        filterCell.showCancel = false
        filterCell.delegate = self

        var cityCount = (showCity && displayCity != nil) ? 1 : 0
        var badgeCount = showBadges ? displayUserBadges.count : 0
        
        if indexPath.row <= cityCount - 1 {
            // USER BADGE
                let cityAttString = NSMutableAttributedString()
                
                let cityLabelFont = UIFont(name: "Poppins-Bold", size: 13)
                let cityLabelColor = UIColor.darkGray
                
                let cityText = displayCity
                let attributedLabel = NSMutableAttributedString(string: " \(cityText!)", attributes: [NSAttributedString.Key.foregroundColor: cityLabelColor, NSAttributedString.Key.font: cityLabelFont])
                
                cityAttString.append(attributedLabel)
                filterCell.uploadLocations.attributedText = cityAttString
                filterCell.layer.borderWidth = 0
                filterCell.uploadLocations.sizeToFit()
        }
        
        else if indexPath.row <= badgeCount + cityCount - 1 {
            // USER BADGE
                let userBadgeInt = displayUserBadges[indexPath.row - cityCount]
            
                let badgeAttString = NSMutableAttributedString()
                
                let badgeLabelFont = UIFont(name: "Poppins-Bold", size: 12)
                let badgeLabelColor = UIColor.ianLegitColor()
                
                let image1Attachment = NSTextAttachment()
                let inputImage = UserBadgesImageRef[userBadgeInt]
                image1Attachment.image = inputImage.alpha(1)
                image1Attachment.bounds = CGRect(x: 0, y: (filterCell.uploadLocations.font.capHeight - (inputImage.size.height)).rounded() / 2, width: inputImage.size.width, height: inputImage.size.height)

                let image1String = NSAttributedString(attachment: image1Attachment)
                badgeAttString.append(image1String)
                
                let badgeText = UserBadgesRef[userBadgeInt]
                let attributedLabel = NSMutableAttributedString(string: " \(badgeText)", attributes: [NSAttributedString.Key.foregroundColor: badgeLabelColor, NSAttributedString.Key.font: badgeLabelFont])
                
                badgeAttString.append(attributedLabel)
                filterCell.uploadLocations.attributedText = badgeAttString
                filterCell.layer.borderWidth = 0
                filterCell.uploadLocations.sizeToFit()
        } else {
         // EMOJI CELLS
                var tempEmoji = displayedEmojis[indexPath.row - badgeCount - cityCount]
                var displayTerm = tempEmoji.capitalizingFirstLetter()
                var tempWord = ""
                
                if let text = EmojiDictionary[displayTerm] {
                    tempWord = text
                    displayTerm += " \(tempWord.capitalizingFirstLetter())"
                }
                
                let attributedString = NSMutableAttributedString(string: displayTerm, attributes: [NSAttributedString.Key.font: UIFont(name: "Poppins-Regular", size: 12), NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor()])

            
                if let count = displayedEmojisCounts[tempEmoji]{
                    if count > 0 {
                        let tempAttString = NSMutableAttributedString(string: "  \(count)", attributes: [NSAttributedString.Key.font: UIFont(font: .arialBoldMT, size: 14), NSAttributedString.Key.foregroundColor: UIColor.legitColor()])
                        attributedString.append(tempAttString)
                    }
                }
                filterCell.searchTerm = tempEmoji
                filterCell.searchTermType = SearchCaption
                filterCell.searchTermCount = displayedEmojisCounts[tempEmoji] ?? 0
                if self.viewFilter.searchTerms.contains(tempEmoji) {
                    filterCell.isFiltering = self.viewFilter.searchTerms.contains(tempEmoji)
                    print("EMOJI CV - FILTERING ",tempEmoji)
                }
//                filterCell.backgroundColor = filterCell.isFiltering ? UIColor.mainBlue().withAlphaComponent(0.6) : UIColor.ianWhiteColor()
                filterCell.uploadLocations.attributedText = attributedString
                filterCell.uploadLocations.sizeToFit()
                filterCell.layer.borderColor =  UIColor.lightGray.cgColor
                filterCell.layer.borderWidth = 1
        }
        
        
        return filterCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var badgeCount = showBadges ? displayUserBadges.count : 0

        if indexPath.row > badgeCount - 1 {
            let emoji = displayedEmojis[indexPath.row - badgeCount].lowercased()
            self.delegate?.didTapEmoji(emoji: emoji)
        }
        
        

    }
    
    
}

