//
//  DropDownCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 8/10/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//
import UIKit
import DropDown

class DropDownListCell: DropDownCell {
    
    
    var isManageList: Bool? = false {
        didSet {
//            if isManageList! && list == nil{
//                let listNameText = NSMutableAttributedString(string: "Manage Lists", attributes: [NSForegroundColorAttributeName: UIColor.black, NSFontAttributeName: UIFont(font: .noteworthyBold, size: 20)])
//                listNameLabel.attributedText = listNameText
//                listNameLabel.sizeToFit()
//            }
        }
    }
    
    var listName: String? {
        didSet{
            // Setup List Name
            var listNameColor = UIColor.black

            if self.list?.name == legitListName {
                listNameColor = UIColor.init(hexColor: "F1C40F")
            } else if self.list?.name == bookmarkListName {
                listNameColor = UIColor.red
            } else if self.list?.publicList == 0 {
                // PRIVATE
                listNameColor = UIColor.init(hexColor: "F1C40F")
            } else {
                listNameColor = UIColor.black
            }
            let listNameText = NSMutableAttributedString(string: "\(listName)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): listNameColor, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .noteworthyBold, size: 20)]))
            listNameLabel.attributedText = listNameText
            listNameLabel.sizeToFit()
        }
    }
    
    var list: List? {
        didSet{
            //Setup Post Ind
            var listIndImage = UIImage()
            var listNameColor = UIColor.white
            if self.list?.name == legitListName {
                listIndImage = #imageLiteral(resourceName: "legit_large")
                listNameColor = UIColor.black
            } else if self.list?.name == bookmarkListName {
                listIndImage = #imageLiteral(resourceName: "bookmark_filled")
                listNameColor = UIColor.red
            } else if self.list?.publicList == 0 {
                // PRIVATE
                listIndImage = #imageLiteral(resourceName: "private")
                listNameColor = UIColor.init(hexColor: "F1C40F")
            } else {
                listIndImage = UIImage()
                listNameColor = UIColor.white
            }
            
            self.listIndButton.setImage(listIndImage, for: .normal)
            
            
            // Setup List Name
            let listNameText = NSMutableAttributedString(string: "\(list?.name)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): listNameColor, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .noteworthyBold, size: 20)]))
            listNameLabel.attributedText = listNameText
            listNameLabel.sizeToFit()
            
            // UPDATE POST COUNT
            if let postCount = (self.list?.postIds?.count) {
                if postCount > 0 {
                    let postCountText = NSMutableAttributedString()
                    
                    let postCountString = NSMutableAttributedString(string: "  \(postCount)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 15)]))
                    postCountText.append(postCountString)
                    
                    let image1Attachment = NSTextAttachment()
                    image1Attachment.image = UIImage(named: "dining")
                    let image1String = NSAttributedString(attachment: image1Attachment)
                    postCountText.append(image1String)

                    
                    self.postCountLabel.attributedText = postCountText
                }
            } else {
                self.postCountLabel.attributedText = nil
            }
            self.postCountLabel.sizeToFit()
            
            // UPDATE CRED COUNT
            if let credCount = (list?.totalCred) {
                if credCount > 0 {
                    let credButtonText = NSMutableAttributedString()
                    
                    let credButtonString = NSMutableAttributedString(string: "  \(credCount)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 15)]))
                    credButtonText.append(credButtonString)
                    
                    let image1Attachment = NSTextAttachment()
                    image1Attachment.image = UIImage(named: "cred")
                    image1Attachment.image = #imageLiteral(resourceName: "drool")
                    let image1String = NSAttributedString(attachment: image1Attachment)
                    credButtonText.append(image1String)
                    
                    self.credCountLabel.attributedText = credButtonText
                } else {
                    self.credCountLabel.attributedText = nil
                }
                self.credCountLabel.sizeToFit()
            }
        }
    }
    
    lazy var listNameLabel: UILabel! = {
        let label = UILabel()
        label.text = "List Name"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    lazy var postCountLabel: UILabel! = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.clear
        label.isUserInteractionEnabled = true
        return label
    }()
    
    lazy var credCountLabel: UILabel! = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.clear
        label.isUserInteractionEnabled = true
        return label
    }()
    
    lazy var listIndButton: UIButton! = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "private"), for: .normal)
        return button
    }()
    
    
    override func awakeFromNib() {
        selectionStyle = .none
        self.backgroundColor = UIColor.legitColor()

        addSubview(postCountLabel)
        postCountLabel.anchor(top: topAnchor, left: nil, bottom: bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 15, width: 0, height: 0)
        
        addSubview(credCountLabel)
        credCountLabel.anchor(top: topAnchor, left: nil, bottom: bottomAnchor, right: postCountLabel.leftAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 20, width: 0, height: 0)
        
        addSubview(listNameLabel)
        listNameLabel.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        listNameLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        listNameLabel.rightAnchor.constraint(lessThanOrEqualTo: credCountLabel.leftAnchor, constant: -30)
        listNameLabel.sizeToFit()
        
        addSubview(listIndButton)
        listIndButton.anchor(top: topAnchor, left: listNameLabel.rightAnchor, bottom: bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 20, width: 0, height: 0)
        
    }
    
//    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//
//        selectionStyle = .none
//        self.backgroundColor = UIColor.legitColor()
//
//        addSubview(listIndButton)
//        listIndButton.anchor(top: topAnchor, left: nil, bottom: bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 20, width: 0, height: 0)
//
//        addSubview(postCountLabel)
//        postCountLabel.anchor(top: topAnchor, left: nil, bottom: bottomAnchor, right: listIndButton.leftAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 20, width: 0, height: 0)
//
//        addSubview(credCountLabel)
//        credCountLabel.anchor(top: topAnchor, left: nil, bottom: bottomAnchor, right: postCountLabel.leftAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 20, width: 0, height: 0)
//
//        addSubview(listNameLabel)
//        listNameLabel.anchor(top: nil, left: leftAnchor, bottom: nil, right: credCountLabel.leftAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
//        listNameLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
//        listNameLabel.sizeToFit()
//
//    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.backgroundColor = selected ? UIColor.lightGray : UIColor.legitColor()

    }
    
//
//    required init(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        list = nil
        isManageList = false
        postCountLabel.attributedText = nil
        credCountLabel.attributedText = nil
        listNameLabel.attributedText = nil
        listIndButton.setImage(UIImage(), for: .normal)
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
