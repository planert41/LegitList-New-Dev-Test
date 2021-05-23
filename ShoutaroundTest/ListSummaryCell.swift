//
//  ListSummaryCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/1/20.
//  Copyright © 2020 Wei Zou Ang. All rights reserved.
//

import UIKit

protocol ListSummaryCellDelegate {
    func didTapList(list: List?)
    func didTapAddNewList()
}


class ListSummaryCell: UICollectionViewCell {
    
    var listCellHeight: CGFloat = 140
    var listCellWidth: CGFloat = 100
    
    var delegate: ListSummaryCellDelegate?
    
    var list: List? {
        didSet {
            self.loadList()
        }
    }

    
    let listHeaderImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .white
        let img = #imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate)
        iv.backgroundImage.image = img
        iv.backgroundImage.isHidden = false
        iv.tintColor = UIColor.gray
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
//        iv.layer.cornerRadius = 50/2
//        iv.layer.masksToBounds = true
        return iv
    }()

    
    let listNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont(name: "Poppins-Bold", size: 14)
//        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = NSTextAlignment.center
        //        label.numberOfLines = 0
        return label
    }()
    
    let listDetailLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.systemFont(ofSize: 10)
        label.adjustsFontSizeToFitWidth = false
        label.textAlignment = NSTextAlignment.center
        label.textColor = UIColor.darkGray
        //        label.numberOfLines = 0
        return label
    }()
    
    func loadList() {
        guard let list = self.list else {
            return
        }
        
    // LIST HEADER IMG
        if let listImg = list.heroImageUrl {
            self.listHeaderImageView.loadImage(urlString: listImg)
            self.listHeaderImageView.backgroundImage.isHidden = true
            self.listHeaderImageView.backgroundColor = UIColor.white

        } else if (list.listImageUrls.count ?? 0) > 0 {
            for (x, imgUrl) in (list.listImageUrls ?? []).enumerated() {
                if !imgUrl.isEmptyOrWhitespace() {
                    self.listHeaderImageView.loadImage(urlString: imgUrl)
                    self.listHeaderImageView.backgroundImage.isHidden = true
                    self.listHeaderImageView.backgroundColor = UIColor.white
//                    print("\(list.name) | No Header Image | Using listImageURL | \(x) | \(imgUrl)")
                    break
                }
            }
        } else {
            self.listHeaderImageView.cancelImageRequestOperation()
            self.listHeaderImageView.image = nil
            let img = #imageLiteral(resourceName: "list_color_icon")
            self.listHeaderImageView.backgroundImage.image = img
            self.listHeaderImageView.backgroundImage.isHidden = false
            self.listHeaderImageView.backgroundColor = UIColor.backgroundGrayColor()
//            self.listHeaderImageView.image = img
//            self.listHeaderImageView.isListBackground = true
        }
        
    // LIST NAME
        
        let listNameFont = UIFont(name: "Poppins-Bold", size: 14)
        let listNameColor = (list.name == bookmarkListName) ? UIColor.weiBookmarkColor() : UIColor.black
        
        var listNameAtt = NSMutableAttributedString(string: list.name, attributes: [NSAttributedString.Key.foregroundColor: listNameColor, NSAttributedString.Key.font: listNameFont])
        
        if (list.name == bookmarkListName) {
            let image1Attachment = NSTextAttachment()
            //                let inputImage = UIImage(named: "cred")!.resizeImageWith(newSize: imageSize)
            let inputImage = #imageLiteral(resourceName: "bookmark_filled")
            image1Attachment.image = inputImage
            image1Attachment.bounds = CGRect(x: 0, y: (listNameLabel.font.capHeight - (inputImage.size.height)).rounded() / 2, width: inputImage.size.width, height: inputImage.size.height)
            let image1String = NSAttributedString(attachment: image1Attachment)
            listNameAtt.append(image1String)
            
        }
        self.listNameLabel.attributedText = listNameAtt
        self.listNameLabel.sizeToFit()
        
        self.listNameLabel.text = list.name
        self.listNameLabel.textColor = (list.name == bookmarkListName) ? UIColor.weiBookmarkColor() : UIColor.black
        
    // LIST DETAILS
        var postCount = list.postIds?.count ?? 0
        var newPostCount = list.newNotificationsCount ?? 0
        var emoji = list.topEmojis.joined()

        var listDetails = (postCount > 0) ? "\(postCount) Posts" : "No Posts Yet"
        var listDetailsFont = (postCount > 0) ? UIFont.systemFont(ofSize: 10) : UIFont.boldSystemFont(ofSize: 9)
        var attributedPostCount = NSMutableAttributedString(string: "\(postCount) Posts", attributes: [
        .font: listDetailsFont,
        .foregroundColor: UIColor.darkGray
        ])
        
        var attributedNewPostCount = NSMutableAttributedString(string: "  \(newPostCount) NEW", attributes: [
        .font: UIFont(font: .helveticaNeueBold, size: 10),
        .foregroundColor: UIColor.red
        ])

        if newPostCount > 0 {
            attributedPostCount.append(attributedNewPostCount)
        }
        
        self.listDetailLabel.attributedText = attributedPostCount
//        self.listDetailLabel.text = listDetails
        self.listDetailLabel.sizeToFit()

    }
    
    override var isSelected: Bool {
        didSet {
            self.cellView.backgroundColor = self.isSelected ? UIColor.ianLegitColor().withAlphaComponent(0.6) : UIColor.clear
            self.layer.borderColor = self.isSelected ? UIColor.ianLegitColor().cgColor : UIColor.gray.cgColor
//            self.listNameLabel.textColor = self.isSelected ? UIColor.white : UIColor.ianBlackColor()
//            self.listDetailLabel.textColor = self.isSelected ? UIColor.white : UIColor.darkGray
//            self.cellView.backgroundColor = self.isSelected ? UIColor.ianLegitColor() : UIColor.clear
//            self.layer.borderColor = self.isSelected ? UIColor.ianLegitColor().cgColor : UIColor.gray.cgColor

        }
    }
    
//    var listSelected: Bool = false {
//        didSet {
//            self.cellView.backgroundColor = self.listSelected ? UIColor.ianLegitColor().withAlphaComponent(0.6) : UIColor.clear
//            self.layer.borderColor = self.listSelected ? UIColor.ianLegitColor().cgColor : UIColor.gray.cgColor
//        }
//    }
    
    let cellView = UIView()
    
    var addNewListView = UIView()
    let addNewListLabel: UILabel = {
        let label = UILabel()
        label.text = "Create\nNew List"
        label.font = UIFont(name: "Poppins-Bold", size: 13)
//        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = NSTextAlignment.center
        label.textColor = UIColor.white
        label.numberOfLines = 2
        return label
    }()
    
    let addNewListImageButton: UIButton = {
        let button = UIButton()
        let listIcon = #imageLiteral(resourceName: "add_color").withRenderingMode(.alwaysOriginal)
        button.setImage(listIcon, for: .normal)
        button.contentMode = .scaleAspectFit
        button.setTitleColor(UIColor.ianWhiteColor(), for: .normal)
        button.tintColor = UIColor.gray
        button.backgroundColor = UIColor.clear
        button.isUserInteractionEnabled = true
        button.tintColor = UIColor.ianBlackColor()
        return button
    }()
    
    
    var addNewListViewShow = false {
        didSet {
            setupAddNewListView()
        }
    }
    
    func setupAddNewListView() {
        addNewListView.isHidden = !addNewListViewShow
        if addNewListViewShow{
            listHeaderImageView.image = UIImage()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.layer.cornerRadius = 5
        self.layer.masksToBounds = true
        self.clipsToBounds = true
        self.layer.borderColor = UIColor.lightGray.cgColor
        self.layer.borderWidth = 1
        self.layer.applySketchShadow()
        
        addSubview(cellView)
        cellView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: listCellWidth, height: listCellHeight)

        
        cellView.isUserInteractionEnabled = true
        cellView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapList)))

        addSubview(listHeaderImageView)
//        listHeaderImageView.isListBackground = true
        listHeaderImageView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        listHeaderImageView.heightAnchor.constraint(equalTo: listHeaderImageView.widthAnchor, multiplier: 1, constant: 0).isActive = true
        listHeaderImageView.centerXAnchor.constraint(equalTo: cellView.centerXAnchor).isActive = true
        listHeaderImageView.isUserInteractionEnabled = true
        listHeaderImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapList)))
        
        listHeaderImageView.layer.borderColor = UIColor.lightGray.cgColor
        listHeaderImageView.layer.borderWidth = 1
        listHeaderImageView.layer.cornerRadius = 5
        listHeaderImageView.layer.masksToBounds = true

        addSubview(listNameLabel)
        listNameLabel.anchor(top: listHeaderImageView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 2, paddingBottom: 0, paddingRight: 2, width: 0, height: 0)
        listNameLabel.isUserInteractionEnabled = true
        listNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapList)))
        
        addSubview(listDetailLabel)
        listDetailLabel.anchor(top: listNameLabel.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 3, paddingRight: 0, width: 0, height: 10)
        listDetailLabel.isUserInteractionEnabled = true
        listDetailLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapList)))
        
        addSubview(addNewListView)
        addNewListView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        addNewListView.backgroundColor = UIColor.mainBlue()
        addNewListView.isUserInteractionEnabled = true
        addNewListView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapAddNewList)))
        
        addNewListView.addSubview(addNewListLabel)
        addNewListLabel.anchor(top: nil, left: leftAnchor, bottom: addNewListView.bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 0, height: 0)
        
        addNewListView.addSubview(addNewListImageButton)
        addNewListImageButton.anchor(top: topAnchor, left: nil, bottom: addNewListLabel.topAnchor, right: nil, paddingTop: 15, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 50, height: 50)
        addNewListImageButton.centerXAnchor.constraint(equalTo: addNewListView.centerXAnchor).isActive = true
        addNewListView.isHidden = true
        
        
    }
    
    @objc func tapAddNewList() {
        self.delegate?.didTapAddNewList()
    }
    
    
    @objc func tapList() {
        guard let list = list else {return}
        self.delegate?.didTapList(list: list)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        listHeaderImageView.cancelImageRequestOperation()
        self.listNameLabel.text = ""
        self.listDetailLabel.text = ""
        addNewListViewShow = false
        self.isSelected = false
    }
    
    
    
}
