//
//  DropDownTableViewCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 8/10/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import UIKit
import DropDown

class DropDownTableViewCell: DropDownCell {

    @IBOutlet weak var listNameLabel: UILabel!
    @IBOutlet weak var postCountLabel: UILabel!
    @IBOutlet weak var credCountLabel: UILabel!
    @IBOutlet weak var listIndButton: UIButton!
    
    var list: List?
    
        /*{
        didSet{
            //Setup Post Ind
            var listIndImage: UIImage? = nil
            var listNameColor = UIColor.white
            if self.list?.name == legitListName {
                listIndImage = #imageLiteral(resourceName: "legit_large")
                listNameColor = UIColor.legitListNameColor()
            } else if self.list?.name == bookmarkListName {
                listIndImage = #imageLiteral(resourceName: "bookmark_filled")
                listNameColor = UIColor.bookmarkListNameColor()
            } else if self.list?.publicList == 0 {
                // PRIVATE
                listIndImage = #imageLiteral(resourceName: "private")
                listNameColor = UIColor.privateListNameColor()
            } else {
                listIndImage = nil
                listNameColor = UIColor.darkLegitColor()
            }
            
            if listIndImage == nil {
                self.listIndButton.setImage(nil, for: .normal)
            } else {
                self.listIndButton.setImage(listIndImage?.withRenderingMode(.alwaysOriginal), for: .normal)
            }
            
            // Setup List Name
            let listName = self.list != nil ? list?.name : "Manage Lists"
            let listNameText = NSMutableAttributedString(string: listName!, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): listNameColor, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .helveticaNeueBold, size: 18)]))
            listNameLabel.attributedText = listNameText
            listNameLabel.sizeToFit()
            
            // UPDATE POST COUNT
            if let postCount = (self.list?.postIds?.count) {
                if postCount > 0 {
                    let postCountText = NSMutableAttributedString()
                    
                    let postCountString = NSMutableAttributedString(string: "\(postCount) Posts", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkLegitColor(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
                    postCountText.append(postCountString)
                    
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
                    
                    
                    let imageSize = CGSize(width: 15, height: 15)
                    let bookmarkImage = NSTextAttachment()
                    let bookmarkIcon = #imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
                    bookmarkImage.bounds = CGRect(x: 0, y: (credCountLabel.font.capHeight - bookmarkIcon.size.height).rounded() / 2, width: bookmarkIcon.size.width, height: bookmarkIcon.size.height)
                    bookmarkImage.image = bookmarkIcon
                    
                    let image1String = NSAttributedString(attachment: bookmarkImage)
                    credButtonText.append(image1String)
                    
                    let credButtonString = NSMutableAttributedString(string: " \(credCount) ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
                    credButtonText.append(credButtonString)
                    
//                    let image1Attachment = NSTextAttachment()
//                    image1Attachment.image = UIImage(named: "cred")
//                    image1Attachment.image = #imageLiteral(resourceName: "bookmark_filled")
//


                    self.credCountLabel.attributedText = credButtonText
                } else {
                    self.credCountLabel.attributedText = nil
                }
                self.credCountLabel.sizeToFit()
            }
        }
    }*/
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor.white

        
        postCountLabel.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        postCountLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        postCountLabel.sizeToFit()
        postCountLabel.font = UIFont(name: "Poppins-Bold", size: 35)!
        postCountLabel.textColor = UIColor.ianLegitColor()
        postCountLabel.textAlignment = NSTextAlignment.right
        
        listNameLabel.anchor(top: nil, left: leftAnchor, bottom: nil, right: postCountLabel.leftAnchor, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        listNameLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        listNameLabel.sizeToFit()
        listNameLabel.font = UIFont(name: "Poppins-Bold", size: 38)!
        
//        postCountLabel.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 15, width: 0, height: 0)
//        postCountLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
//        postCountLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
//        postCountLabel.textAlignment = NSTextAlignment.right
//
//        credCountLabel.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
//        credCountLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
//        credCountLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
//        credCountLabel.sizeToFit()
//        credCountLabel.textAlignment = NSTextAlignment.left
//
//        listNameLabel.anchor(top: nil, left: credCountLabel.rightAnchor, bottom: nil, right: postCountLabel.leftAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
//        listNameLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
////        listNameLabel.rightAnchor.constraint(lessThanOrEqualTo: credCountLabel.leftAnchor, constant: 30).isActive = true
//        listNameLabel.sizeToFit()
//
//        listIndButton.anchor(top: topAnchor, left: listNameLabel.rightAnchor, bottom: bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 20, width: 0, height: 0)
//
//        let bottomDivider = UIView()
//        addSubview(bottomDivider)
//        bottomDivider.backgroundColor = UIColor.gray
//        bottomDivider.anchor(top: bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
//
        
        
        
        
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
//        self.backgroundColor  = selected ? UIColor.legitColor().withAlphaComponent(0.8) : UIColor.white
        self.backgroundColor  = UIColor.white

//        self.backgroundColor = selected ? UIColor.init(hex: "1395b9") : UIColor.legitColor().withAlphaComponent(0.75)
//        self.backgroundColor = selected ? UIColor.init(hex: "1395b9") : UIColor.init(hex: "33bbff")

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        list = nil
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
