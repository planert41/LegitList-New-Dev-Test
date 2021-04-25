//
//  UploadEmojiCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/13/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit


class ListDisplayCell: UICollectionViewCell {
    
    var displayListInput: [String:String]? {
        didSet{
            if (displayListInput?.count)! > 0 {
                for (key,value) in displayListInput! {
                    self.displayListId = key
                    self.displayListName = value
                }
            }
        }
    }
    
    var displayListName: String? {
        didSet {
            setupListName()
        }
    }
    
    var otherUser: Bool = false {
        didSet {
            setupListName()
        }
    }
    
//    let cellBackgroundColor = UIColor(hexColor: "FE5F55").withAlphaComponent(0.75).cgColor
    
    let cellBackgroundColor = UIColor.otherUserColor().withAlphaComponent(0.5).cgColor    
    let cellLegitColor = UIColor.legitColor().withAlphaComponent(0.6).cgColor
    var textColor: UIColor = UIColor.ianBlackColor()
    
    func setupListName(){
        
        guard let _ = self.displayListName else {return}
        let attributedListText = NSMutableAttributedString()
        
        let attributedSpace = NSMutableAttributedString(string: " " )
        attributedListText.append(attributedSpace)
//        layer.backgroundColor = self.otherUser ? UIColor.darkLegitColor().withAlphaComponent(0.8).cgColor : UIColor.darkSelectedColor().withAlphaComponent(0.8).cgColor
        

//        layer.backgroundColor = self.otherUser ? UIColor.ianLegitColor().cgColor : UIColor.lightRedColor().cgColor
//        layer.borderColor = self.otherUser ? UIColor.darkLegitColor().cgColor : UIColor.darkLegitColor().cgColor
//        layer.borderWidth = 1
//        textColor = self.otherUser ? UIColor.white : UIColor.darkLegitColor()
//        textColor = UIColor.ianBlackColor()
        textColor = UIColor.ianLegitColor()
        textColor = UIColor.darkGray

        layer.backgroundColor = UIColor.white.cgColor
        layer.borderColor = UIColor.rgb(red: 221, green: 221, blue: 221).cgColor
        layer.borderWidth = 1

        let imageSize = CGSize(width: displayFont, height: displayFont)
        
        if displayListName == legitListName {
            let likeImage = NSTextAttachment()
            let likeIcon = #imageLiteral(resourceName: "legit_large").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
            likeImage.bounds = CGRect(x: 0, y: (displayList.font.capHeight - likeIcon.size.height).rounded() / 2, width: likeIcon.size.width, height: likeIcon.size.height)
            likeImage.image = likeIcon

            let likeImageString = NSAttributedString(attachment: likeImage)
            attributedListText.append(likeImageString)
            
//            layer.backgroundColor = self.otherUser ? UIColor.legitColor().withAlphaComponent(0.8).cgColor : UIColor(hexColor: "f10f3c").withAlphaComponent(0.8).cgColor
//            textColor = UIColor.pinterestRedColor()
//            textColor = UIColor.white



        } else if displayListName == bookmarkListName {
            let bookmarkImage = NSTextAttachment()
            let bookmarkIcon = #imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
            bookmarkImage.bounds = CGRect(x: 0, y: (displayList.font.capHeight - bookmarkIcon.size.height).rounded() / 2, width: bookmarkIcon.size.width, height: bookmarkIcon.size.height)
            bookmarkImage.image = bookmarkIcon
            
            let bookmarkImageString = NSAttributedString(attachment: bookmarkImage)
            attributedListText.append(bookmarkImageString)

        } else {
            let bookmarkImage = NSTextAttachment()
            let bookmarkIcon = #imageLiteral(resourceName: "listsHash_vector").withRenderingMode(.alwaysTemplate)
//            let bookmarkIcon = #imageLiteral(resourceName: "listsHash").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
            bookmarkImage.bounds = CGRect(x: 0, y: (displayList.font.capHeight - bookmarkIcon.size.height).rounded() / 2, width: bookmarkIcon.size.width, height: bookmarkIcon.size.height)
            bookmarkImage.image = bookmarkIcon
            
            let bookmarkImageString = NSAttributedString(attachment: bookmarkImage)
            attributedListText.append(bookmarkImageString)
        }
        
        let attributedString = NSMutableAttributedString(string: " " + self.displayListName!, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: displayFont), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): textColor]))
        attributedListText.append(attributedString)
        
        attributedListText.addAttribute(
            NSAttributedString.Key.foregroundColor,
            value: UIColor.ianLegitColor(),
            range: NSMakeRange(0, 2))
        
        self.displayList.attributedText = attributedListText
        self.displayList.tintColor = UIColor.ianLegitColor()
        self.displayList.sizeToFit()
    }
    
    var displayListId: String?
    var displayTag: Int?
    
    let displayList: LightPaddedUILabel = {
        let iv = LightPaddedUILabel()
        return iv
    }()
    
    var displayFont: CGFloat = 13 {
        didSet{
            displayList.font = UIFont.boldSystemFont(ofSize: self.displayFont)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        addSubview(displayList)
        displayList.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 3, paddingLeft: 5, paddingBottom: 3, paddingRight: 5, width: 0, height: 0)
        displayList.textAlignment = NSTextAlignment.center
        displayList.center = self.center
        displayList.backgroundColor = .clear
        displayList.font = UIFont.boldSystemFont(ofSize: self.displayFont)
        displayList.textColor = UIColor.white
        
        layer.borderWidth = 1
        layer.borderColor = UIColor.rgb(red: 221, green: 221, blue: 221).cgColor
        layer.backgroundColor = UIColor.white.cgColor
//        layer.backgroundColor = UIColor(hexColor: "FE5F55").withAlphaComponent(0.75).cgColor

        layer.cornerRadius = 15
        layer.masksToBounds = true
        
        
    }
    
//    override func prepareForReuse() {
//        layer.backgroundColor = UIColor(hexColor: "FE5F55").withAlphaComponent(0.75).cgColor
//    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init coder error")
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
