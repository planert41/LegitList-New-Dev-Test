//
//  UserCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 11/15/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage


class TagPhotoToListCell: UITableViewCell, EmojiButtonArrayDelegate {
    func doubleTapEmoji(index: Int?, emoji: String) {
        
    }
    
    var delegate: UploadPhotoToListCellDelegate?

    var list: List?{
        didSet {
            
            if let displayEmojis = self.list?.topEmojis{
                emojiArray.emojiLabels = Array(displayEmojis.prefix(3))
            } else {
                emojiArray.emojiLabels = []
            }
            emojiArray.setEmojiButtons()
            emojiArray.sizeToFit()
            
            fetchListUser()
            setupListName()
            
            setupSocialStatsLabel()
            setupLastDateLabel()
        }
    }
    
    var refUser: User? = nil
    var listTag: Int? = nil
    
    func setupLastDateLabel(){
        
        guard let lastDate = list?.mostRecentDate else {
            lastDateLabel.isHidden = true
            return
        }
        
        let formatter = DateFormatter()
        let calendar = NSCalendar.current
        
        let yearsAgo = calendar.dateComponents([.year], from: lastDate, to: Date())
        if (yearsAgo.year)! > 0 {
            formatter.dateFormat = "MMM d yy"
            formatter.dateFormat = "MM/dd/yy"
        } else {
            formatter.dateFormat = "MMM d"
            formatter.dateFormat = "MM/dd"
            
        }
        let dateDisplay = formatter.string(from: lastDate)
        
        let displayText = NSMutableAttributedString()
        //
        //        let lastModText = NSAttributedString(string: "Last Mod: ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.italicSystemFont(ofSize: 10),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.gray]))
        //        displayText.append(lastModText)
        
        let dateLabel = NSAttributedString(string: "\(dateDisplay)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.italicSystemFont(ofSize: 11),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.gray]))
        displayText.append(dateLabel)
        
        
        self.lastDateLabel.attributedText = displayText
        self.lastDateLabel.sizeToFit()
        self.lastDateLabel.isHidden = false
        
    }
    
    
    var listUser: User? {
        didSet {
            guard let profileImageUrl = listUser?.profileImageUrl else {return}
            if self.listUser?.uid != refUser?.uid {
                profileImageView.loadImage(urlString: profileImageUrl)
                listIndLabel.setImage(profileImageView.image, for: .normal)
            }
            //            profileImageView.loadImage(urlString: profileImageUrl)
            usernameLabel.text = listUser?.username
            self.setupListName()
        }
    }
    
    func setupListName(){
        
    // LIST HEADER IMG
        if  (list?.name)! == bookmarkListName {
            listIndLabel.setImage(#imageLiteral(resourceName: "bookmark_filled"), for: .normal)
        } else if let listImg = list?.heroImageUrl {
            self.postImageView.loadImage(urlString: listImg)
        } else if (list?.listImageUrls.count ?? 0) > 0 {
            for (x, imgUrl) in (list?.listImageUrls ?? []).enumerated() {
                if !imgUrl.isEmptyOrWhitespace() {
                    self.postImageView.loadImage(urlString: imgUrl)
                    print("\(list?.name) | No Header Image | Using listImageURL | \(x) | \(imgUrl)")
                    break
                }
            }
        } else {
            self.postImageView.cancelImageRequestOperation()
            self.postImageView.image = nil
            self.postImageView.isListBackground = true
        }
        
        listIndLabel.isHidden = (list?.name)! != bookmarkListName
        postImageView.isHidden = !listIndLabel.isHidden
        
        listnameLabel.text = (list?.name) ?? ""
        listnameLabel.sizeToFit()
        
    }
    
    
    func loadListProfileImage(){
        var earliestPost = ""
        var earliestPostDate = 0.0
        
        
        for (key,value) in (self.list?.postIds)! {
            let value = value as! Double
            if earliestPostDate == 0.0 {
                earliestPost = key
                earliestPostDate = value
            } else if value < earliestPostDate {
                earliestPost = key
                earliestPostDate = value
            }
        }
        
        if earliestPost != "" {
            Database.fetchPostWithPostID(postId: earliestPost) { (post, err) in
                if let err = err {
                    print("Error Fetching \(earliestPost) for List Picture")
                }
                if let imageURL = post?.imageUrls.first {
                    self.profileImageView.loadImage(urlString: (imageURL))
                } else {
                    self.profileImageView.image = #imageLiteral(resourceName: "blank_gray")
                }
            }
        } else {
            self.profileImageView.image = #imageLiteral(resourceName: "blank_gray")
            
        }
    }
    
    
    func fetchListUser(){
        guard let creatorUid = self.list?.creatorUID else {return}
        Database.fetchUserWithUID(uid: creatorUid) { (user) in
            self.listUser = user
        }
    }
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .white
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    let postImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .white
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.textColor = UIColor.darkGray
        label.font = UIFont.systemFont(ofSize: 14)
        label.adjustsFontSizeToFitWidth = true
        //        label.numberOfLines = 0
        return label
    }()
    
    let listnameLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont(name: "Poppins-Bold", size: 18)
        label.adjustsFontSizeToFitWidth = true
        //        label.numberOfLines = 0
        return label
    }()
    
    let lastDateLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.italicSystemFont(ofSize: 11)
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = NSTextAlignment.right
        label.textColor = UIColor.gray
        //        label.numberOfLines = 0
        return label
    }()
    
    let socialStatsLabel: UILabel = {
        let label = UILabel()
        label.text = "SocialStats"
        label.font = UIFont(name: "Poppins-Regular", size: 10)
        label.numberOfLines = 0
        label.backgroundColor = UIColor.clear
        return label
    }()
    
    
    let emojiLabel: UILabel = {
        let label = UILabel()
        label.text = "Emoji"
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()
    
    let postCountLabel: UILabel = {
        let label = UILabel()
        label.text = "Emoji"
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textAlignment = NSTextAlignment.right
        return label
    }()
    
    
    
    var emojiArray = EmojiButtonArray(emojis: [], frame: CGRect(x: 0, y: 0, width: 0, height: 20))
    
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
    
    let socialStatsFontSize:CGFloat = 14.0
    
    func setupSocialStatsLabel() {
        
        if let postCount = self.list?.postIds?.count {
            socialStatsLabel.text = postCount > 0 ? "\(postCount) Posts" : ""
        } else {
            socialStatsLabel.text = ""
        }
        socialStatsLabel.sizeToFit()

        
        
        let postStats = NSMutableAttributedString()
        if let postCount = self.list?.postIds?.count {
            if postCount > 0 {
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineSpacing = 50
                
                
                let countString = NSMutableAttributedString(string: String(postCount), attributes: [NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 20), NSAttributedString.Key.foregroundColor: isSelected ? UIColor.ianBlueColor() : UIColor.black])

                postStats.append(countString)
                
                let postCountString = NSMutableAttributedString(string: "\n" + "Post", attributes: [NSAttributedString.Key.font: UIFont(font: .avenirHeavy, size: 14), NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor()])
                
                postStats.append(postCountString)
            }
        }
        
        postCountLabel.attributedText = postStats
        postCountLabel.sizeToFit()
        
    }
    
    
    override var isSelected: Bool {
        didSet {
            
            let image = isSelected ? #imageLiteral(resourceName: "photo_upload_check") : #imageLiteral(resourceName: "photo_upload_plus")
            self.listIndLabel.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
            self.listnameLabel.textColor = isSelected ? UIColor.ianBlueColor() : UIColor.black
//            self.socialStatsLabel.textColor = isSelected ? UIColor.ianBlueColor() : UIColor.black
            self.backgroundColor = isSelected ? UIColor.ianOrangeColor().withAlphaComponent(0.2) : UIColor.white
//            self.backgroundColor = self.isSelected ? UIColor.mainBlue().withAlphaComponent(0.2) : UIColor.white
            setupSocialStatsLabel()
        }
    }
    
    let listIndLabel: UIButton = {
        let label = UIButton()
        return label
    }()
    
    
    var showCancel = false {
        didSet {
            if showCancel {
                self.cancelButton.isHidden = false
                self.listIndLabel.alpha = 0
            } else {
                self.cancelButton.isHidden = true
                self.listIndLabel.alpha = 1
            }
        }
    }
    
    lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(tapCancel), for: .touchUpInside)
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.clipsToBounds = true
        return button
    }()
    
    @objc func tapCancel(){
        guard let tag = self.listTag else {
            print("Cancel ERROR | No List Tag | Create New List View")
            return
        }
        self.delegate?.didTapCancel(tag: self.listTag)
    }

    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let cellView = UIView()
        addSubview(cellView)
        cellView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 60)
        cellView.layer.borderWidth = 0.5
        cellView.layer.borderColor = UIColor.rgb(red: 221, green: 221, blue: 221).cgColor

        addSubview(postImageView)
        postImageView.layer.cornerRadius = 5
        postImageView.layer.masksToBounds = true
        addSubview(postImageView)
        postImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 50, height: 50)
        postImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        
        addSubview(listIndLabel)
        listIndLabel.anchor(top: postImageView.topAnchor, left: postImageView.leftAnchor, bottom: postImageView.bottomAnchor, right: postImageView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        listIndLabel.isHidden = true
        
        
        let listNameContainer = UIView()
        addSubview(listNameContainer)
        listNameContainer.anchor(top: nil, left: postImageView.rightAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        listNameContainer.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        addSubview(postCountLabel)
        postCountLabel.anchor(top: listNameContainer.topAnchor, left: nil, bottom: listNameContainer.bottomAnchor, right: listNameContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        addSubview(listnameLabel)
        listnameLabel.anchor(top: nil, left: listNameContainer.leftAnchor, bottom: nil, right: postCountLabel.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
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
        
        var captionDelay = 3
        emojiDetailLabel.text = "\(displayEmoji)  \(displayTag)"
        emojiDetailLabel.alpha = 1
        emojiDetailLabel.adjustsFontSizeToFitWidth = true
        //        emojiDetailLabel.sizeToFit()
        
        UIView.animate(withDuration: 0.5, delay: TimeInterval(captionDelay), options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.emojiDetailLabel.alpha = 0
        }, completion: { (finished: Bool) in
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        //        self.profileImageView.image = UIImage()
        self.listIndLabel.setImage(#imageLiteral(resourceName: "photo_upload_plus").withRenderingMode(.alwaysOriginal), for: .normal)
        self.showCancel = false
        
        self.listnameLabel.text = ""
        self.socialStatsLabel.text = ""
        self.listUser = nil
        self.lastDateLabel.text = ""
        
        
        let subViews = self.subviews
        
        // Reused cells removes extra pictures and shrinks back contentsize width. It gets expanded and added back later if >1 pic
        
        for subview in subViews{
            if let img = subview as? CustomImageView {
                img.image = nil
                img.cancelImageRequestOperation()
                if img.tag != 0 {
                    img.removeFromSuperview()
                }
            }
        }
        
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
