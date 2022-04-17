////
//  UploadLocationCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/5/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit


class HomeFilterBarCell: UICollectionViewCell {
        
    let uploadLocations: UILabel = {
        
        let iv = UILabel()
        iv.backgroundColor = .clear
        iv.numberOfLines = 1
        iv.font = UIFont(name: "Poppins-Bold", size: 20)
        iv.lineBreakMode = .byWordWrapping
        return iv
        
    }()


    override init(frame: CGRect) {
        super.init(frame:frame)
        
        backgroundColor = .white
//        backgroundColor = .mainBlue()

        addSubview(uploadLocations)
        uploadLocations.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        layer.borderWidth = 0
        layer.borderColor = UIColor.black.cgColor
        layer.cornerRadius = 5
        layer.masksToBounds = true
        
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init coder error")
    }
    
}

class TagListBarCell: UICollectionViewCell {
        
    let uploadLocations: UILabel = {
        
        let iv = UILabel()
        iv.backgroundColor = .clear
        iv.numberOfLines = 1
        iv.font = UIFont(name: "Poppins-Bold", size: 20)
        iv.lineBreakMode = .byWordWrapping
        return iv
        
    }()
    
    let listNameIcon: UIButton = {
        let button = UIButton()
        let listIcon = #imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate)
        button.setImage(listIcon, for: .normal)
        button.backgroundColor = UIColor.clear
        button.isUserInteractionEnabled = false
        button.tintColor = UIColor.ianBlackColor()
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame:frame)
        
        backgroundColor = .white
//        backgroundColor = .mainBlue()
        
        addSubview(listNameIcon)
        listNameIcon.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        listNameIcon.widthAnchor.constraint(equalTo: listNameIcon.heightAnchor).isActive = true
        tintColor = UIColor.ianLegitColor()
        
        addSubview(uploadLocations)
        uploadLocations.anchor(top: topAnchor, left: listNameIcon.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 10, width: 0, height: 0)
        layer.borderWidth = 0
        layer.borderColor = UIColor.black.cgColor
        layer.cornerRadius = 5
        layer.masksToBounds = true
        
        
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init coder error")
    }
    
}

protocol SelectedFilterBarCellDelegate {
    func didRemoveTag(tag: String)
    func didRemoveLocationFilter(location: String)
    func didRemoveRatingFilter(rating: String)
    func didTapCell(tag: String)

}


class SelectedFilterBarCell: UICollectionViewCell {
    
    var delegate: SelectedFilterBarCellDelegate?
    
    let uploadLocations: UILabel = {
        
        let iv = UILabel()
        iv.backgroundColor = .clear
        iv.numberOfLines = 1
        iv.font = UIFont(name: "Poppins-Regular", size: 12)
        iv.lineBreakMode = .byWordWrapping
        return iv
        
    }()
    
    let cancelButton: UIButton = {
        let iv = UIButton()
        iv.setImage(#imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysOriginal), for: .normal)
        return iv
        
    }()
    
    var searchTerm: String? = nil {
        didSet {
            updateCellLabel()
        }
    }
    
    var searchTermType: String? = nil {
        didSet {
            updateCellLabel()
        }
    }
    
    var searchTermCount: Int? = 0 {
        didSet {
            updateCellLabel()
        }
    }
    
    var isFiltering: Bool = false {
        didSet {
            updateCellLabel()
        }
    }

    
    func updateCellLabel(){
        
        var displayTerm = searchTerm ?? ""
        var displayColor = UIColor.ianBlackColor()
        if searchTermType == SearchCaption
        {
            displayColor = UIColor.ianBlackColor()
            if let text = EmojiDictionary[displayTerm] {
                displayTerm += " \(text.capitalizingFirstLetter())"
            }
        }
        else if searchTermType == SearchType
        {
            displayColor = UIColor.ianBlackColor()
        }
        else if searchTermType == SearchRating
        {
            displayColor = UIColor.ianLegitColor()
            if let text = extraRatingEmojisDic[displayTerm] {
                displayTerm += " \(text.capitalizingFirstLetter())"
            }
        }
        else if searchTermType == SearchPlace || searchTermType == SearchCity
        {
            displayColor = .ianWhiteColor()
        }
        else if searchTermType == SearchFilterLegit {
            displayTerm = "Top Posts"
            displayColor = .customRedColor()
        }

//        uploadLocations.text = displayTerm
        
        uploadLocations.textColor = displayColor // isFiltering ? UIColor.white : displayColor
        
        if searchTermType == SearchFilterLegit {
            self.backgroundColor = UIColor.selectedColor().withAlphaComponent(0.6)
        }
        else if (searchTermType == SearchPlace || searchTermType == SearchCity) {
            self.backgroundColor = UIColor.mainBlue().withAlphaComponent(0.6)
        } else if self.isFiltering {
            self.backgroundColor = UIColor.lightLegitColor().withAlphaComponent(0.6)
        } else {
            self.backgroundColor = UIColor.white
        }
            
            
//        self.backgroundColor = (searchTermType == SearchPlace || searchTermType == SearchCity) ? UIColor.mainBlue() : UIColor.white

        uploadLocations.font =  displayTerm.containsOnlyEmoji ? UIFont(name: "Poppins-Bold", size: 12) : UIFont(name: "Poppins-Regular", size: 12)
        
        let attributedString = NSMutableAttributedString(string: displayTerm, attributes: [NSAttributedString.Key.font: uploadLocations.font, NSAttributedString.Key.foregroundColor: uploadLocations.textColor])

    
        if (searchTermCount ?? 0) > 0 {
            let tempAttString = NSMutableAttributedString(string: "  \(searchTermCount!)", attributes: [NSAttributedString.Key.font: UIFont(font: .arialBoldMT, size: 14), NSAttributedString.Key.foregroundColor: UIColor.legitColor()])
            attributedString.append(tempAttString)
        }
        
        
        uploadLocations.attributedText = attributedString
        
        
        uploadLocations.sizeToFit()
        self.layer.borderColor = uploadLocations.textColor.cgColor
        
    }
    
    var hideCancelWidthConstraint: NSLayoutConstraint? = nil
    var showCancelWidthConstraint: NSLayoutConstraint? = nil

//    var cancelRightConstraint: NSLayoutConstraint? = nil

    var showCancel: Bool = true {
        didSet {
            self.handleShowCancel()
        }
    }
    
    func handleShowCancel(){
        hideCancelWidthConstraint?.isActive = !showCancel
        showCancelWidthConstraint?.isActive = showCancel
    }
    
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        backgroundColor = .white
        let cancelButtonWidth = 12.0
        addSubview(cancelButton)
        cancelButton.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 5, width: 0, height: 0)
        cancelButton.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 1).isActive = true
        cancelButton.isUserInteractionEnabled = true
        cancelButton.addTarget(self, action: #selector(didTapCancelButton), for: .touchUpInside)
        cancelButton.widthAnchor.constraint(equalTo: cancelButton.heightAnchor, multiplier: 1).isActive = true
        
//        cancelRightConstraint = cancelButton.rightAnchor.constraint(equalTo: rightAnchor, constant: 0)
//        cancelRightConstraint?.isActive = true
        hideCancelWidthConstraint = cancelButton.widthAnchor.constraint(equalToConstant: 0)
        showCancelWidthConstraint = cancelButton.widthAnchor.constraint(equalToConstant: CGFloat(cancelButtonWidth))
        self.handleShowCancel()

        
//        cancelWidthConstraint?.isActive = true

        addSubview(uploadLocations)
        uploadLocations.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: cancelButton.leftAnchor, paddingTop: 2, paddingLeft: 5, paddingBottom: 2, paddingRight: 5, width: 0, height: 25)
        uploadLocations.isUserInteractionEnabled = true
        uploadLocations.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapCellButton)))
        
        
        layer.borderWidth = 1
//        layer.borderColor = UIColor.lightGray.cgColor
        layer.borderColor = uploadLocations.textColor.cgColor
        layer.cornerRadius = 5
        layer.masksToBounds = true
        
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapCellButton)))
        
    }
    
    @objc func didTapCellButton(){
        self.didTapCell()
    }
    
    @objc func didTapCancelButton(){
        if searchTermType == SearchCaption {
            self.removeTag()
        } else if searchTermType == SearchType {
            self.removeTag()
        } else if searchTermType == SearchRating {
            self.removeRating()
        } else if searchTermType == SearchPlace || searchTermType == SearchCity {
            self.removeLocation()
        } else {
            self.didTapCell()
        }
        print("HomeFilterBarCell | Tap Cancel | \(remove)")
    }
    
    @objc func removeTag(){
        guard let remove = self.searchTerm else {return}
        print("HomeFilterBarCell | Remove Tag | \(remove)")
        self.delegate?.didRemoveTag(tag: remove)
    }
    
    @objc func removeLocation(){
        guard let remove = self.searchTerm else {return}
        print("HomeFilterBarCell | Remove Location | \(remove)")
        self.delegate?.didRemoveLocationFilter(location: remove)
    }
    
    @objc func removeRating(){
        guard let remove = self.searchTerm else {return}
        print("HomeFilterBarCell | Remove Rating | \(remove)")
        self.delegate?.didRemoveRatingFilter(rating: remove)
    }
    
    @objc func didTapCell(){
        guard let remove = self.searchTerm else {return}
        self.delegate?.didTapCell(tag: remove)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init coder error")
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()

        searchTerm = nil
        searchTermType = nil
        searchTermCount = 0
        isFiltering = false
        uploadLocations.text = ""
        layer.borderColor =  UIColor.lightGray.cgColor
        layer.borderWidth = 1
    }
    
}

protocol RefreshFilterBarCellDelegate {
    func handleRefresh()
    func didTapSearchButton()
}


class RefreshFilterBarCell: UICollectionViewCell {
    
    var delegate: RefreshFilterBarCellDelegate?
    
    let uploadLocations: UILabel = {
        
        let iv = UILabel()
        iv.backgroundColor = .clear
        iv.numberOfLines = 2
        iv.font = UIFont(name: "Poppins-Bold", size: 20)
        iv.lineBreakMode = .byWordWrapping
        iv.textAlignment = NSTextAlignment.center
        return iv
        
    }()
    
    let refreshButton: UIButton = {
        let iv = UIButton()
//        iv.setImage(#imageLiteral(resourceName: "refresh").withRenderingMode(.alwaysOriginal), for: .normal)
//        iv.setTitle("Search/nTerms", for: .normal)
        iv.titleLabel?.font = UIFont.boldSystemFont(ofSize: 10)
        iv.titleLabel?.numberOfLines = 2
        iv.titleLabel?.lineBreakMode = .byWordWrapping
        iv.setTitleColor(UIColor.ianBlackColor(), for: .normal)
        return iv

    }()
    
//    var cancelWidthConstraint: NSLayoutConstraint? = nil
//    var cancelRightConstraint: NSLayoutConstraint? = nil

//    var showCancel: Bool = false {
//        didSet {
//            self.handleShowCancel()
//        }
//    }
    
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        backgroundColor = .white
        addSubview(refreshButton)
        refreshButton.anchor(top: topAnchor, left: nil, bottom: bottomAnchor, right: rightAnchor, paddingTop: 10, paddingLeft: 5, paddingBottom: 10, paddingRight: 5, width: 0, height: 0)
//        refreshButton.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        refreshButton.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 1).isActive = true
        refreshButton.isUserInteractionEnabled = true
        refreshButton.addTarget(self, action: #selector(didTapIcon), for: .touchUpInside)
//        cancelButton.widthAnchor.constraint(equalTo: cancelButton.heightAnchor, multiplier: 1).isActive = true
        
//        cancelRightConstraint = cancelButton.rightAnchor.constraint(equalTo: rightAnchor, constant: 0)
//        cancelRightConstraint?.isActive = true
//        cancelWidthConstraint = cancelButton.widthAnchor.constraint(equalToConstant: 0)
//        cancelWidthConstraint?.isActive = true
//        self.handleShowCancel()

        addSubview(uploadLocations)
        uploadLocations.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: refreshButton.leftAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 35)
        layer.borderWidth = 0
        layer.borderColor = UIColor.lightGray.cgColor
        layer.cornerRadius = 5
        layer.masksToBounds = true
        uploadLocations.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapSearchButton)))
        
    }
    
    @objc func didTapIcon(){
        print("Tap Icon")
        self.delegate?.handleRefresh()

    }
    
    @objc func didTapSearchButton(){
        print("Tap Search")
        self.delegate?.handleRefresh()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init coder error")
    }

    
}

protocol EmojiBarTitleCellDelegate {
    func didTapEmojiBarTitleCell()
}


class EmojiBarTitleCell: UICollectionViewCell {
        
    let emojiTitle: UILabel = {
        
        let iv = UILabel()
        iv.backgroundColor = .clear
        iv.numberOfLines = 2
        iv.textColor = UIColor.ianBlackColor()
        iv.font = UIFont.boldSystemFont(ofSize: 10)
        iv.lineBreakMode = .byWordWrapping
        iv.textAlignment = NSTextAlignment.center
        return iv
        
    }()
    
    var delegate: EmojiBarTitleCellDelegate?
    var navSearchButton: UIButton = TemplateObjects.NavSearchButton()
    var hideSearchButton: NSLayoutConstraint?
    var showSearchButton: Bool  = false{
        didSet {
            self.toggleSearchButton()
        }
    }
    
    func toggleSearchButton() {
        hideSearchButton?.constant = self.showSearchButton ? 30 : 0
        hideSearchButton?.isActive = true
    }
    
    @objc func didTapCell() {
        self.delegate?.didTapEmojiBarTitleCell()
    }
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        backgroundColor = .clear
        
        addSubview(navSearchButton)
        navSearchButton.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 30)
        navSearchButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        navSearchButton.layer.borderWidth = 0
        hideSearchButton = navSearchButton.widthAnchor.constraint(equalToConstant: 0)
        self.toggleSearchButton()
        navSearchButton.addTarget(self, action: #selector(didTapCell), for: .touchUpInside)

        addSubview(emojiTitle)
        emojiTitle.anchor(top: topAnchor, left: navSearchButton.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 35)
        emojiTitle.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapCell)))
        layer.borderWidth = 0
        layer.borderColor = UIColor.lightGray.cgColor
        layer.cornerRadius = 5
        layer.masksToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init coder error")
    }

    
}
