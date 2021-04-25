//
//  UploadListCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 12/24/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
//import SwiftIcons

class UploadListCell: UITableViewCell {

    var isLegit: Bool = false
    var isBookmark: Bool = false
    var isPublic: Bool = true
    var isListManage: Bool = false
    var selectedColor: UIColor = UIColor(hexColor: "FF9F1C")
//    var selectedColor: UIColor = UIColor(hex: "FFE066")

    
    
    var list: List? {
        didSet{
//            self.listNameLabel.text = "\((list?.name)!) (\((list?.postIds?.count)!))"
            
            if self.list?.name == legitListName{
                self.isLegit = true
            } else {
                self.isLegit = false
            }
            
            if self.list?.name == bookmarkListName{
                self.isBookmark = true
            } else {
                self.isBookmark = false
            }
            
            if self.list?.publicList == 1{
                self.isPublic = true
            } else {
                self.isPublic = false
            }
        
            let attributedText = NSMutableAttributedString(string: (list?.name)!, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
            self.listNameLabel.attributedText = attributedText
            
            
            if (list?.postIds?.count)! > 0 {
                var textColor: UIColor = UIColor.legitColor()
                if self.isPublic {
                    textColor = UIColor.legitColor()
                } else {
                    textColor = UIColor(hexColor: "FF1654")
                }
                
                let attributedCount = NSMutableAttributedString(string: " \((list?.postIds?.count)!)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(font: .noteworthyBold, size: 15), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): textColor]))
                listPostCountLabel.attributedText = attributedCount
            }
        
        
        
        
        }
    }
    
    let listNameLabel: UILabel = {
        let label = UILabel()
        label.text = "List Name"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    let listPostCountLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        addSubview(listPostCountLabel)
        listPostCountLabel.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 30, height: 0)
        
        addSubview(listNameLabel)
        listNameLabel.anchor(top: topAnchor, left: listPostCountLabel.rightAnchor, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        listNameLabel.sizeToFit()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        listPostCountLabel.attributedText = nil
        listNameLabel.attributedText = nil
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        selectionStyle = .none

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        if isListManage {
            if isLegit {
                var imageView : UIImageView
                imageView  = UIImageView(frame:CGRect(x: 0, y: 0, width: 20, height: 20))
                imageView.image = #imageLiteral(resourceName: "legit")
                imageView.backgroundColor = UIColor.legitColor()
                imageView.layer.cornerRadius = 20/2
                imageView.layer.masksToBounds = true
                accessoryView = imageView
            }
                
            else if isBookmark {
                var imageView : UIImageView
                imageView  = UIImageView(frame:CGRect(x: 0, y: 0, width: 20, height: 20))
                imageView.image = #imageLiteral(resourceName: "bookmark_filled")
                accessoryView = imageView
            }
            else if !isPublic {
                var imageView : UIImageView
                imageView  = UIImageView(frame:CGRect(x: 0, y: 0, width: 20, height: 20))
                imageView.image = #imageLiteral(resourceName: "private")
                accessoryView = imageView
            }
            else {
                var imageView : UIImageView
                imageView  = UIImageView(frame:CGRect(x: 0, y: 0, width: 20, height: 20))
                imageView.image =  nil
                accessoryView = imageView
            }
            backgroundColor = UIColor.white
        }
        else {
        // update UI
            if isLegit {
                var imageView : UIImageView
                imageView  = UIImageView(frame:CGRect(x: 0, y: 0, width: 20, height: 20))
                imageView.image = selected ? #imageLiteral(resourceName: "legit") : #imageLiteral(resourceName: "legit")
//                imageView.image = selected ? #imageLiteral(resourceName: "bookmark_selected") : #imageLiteral(resourceName: "bookmark_unselected")
                accessoryView = imageView
            }
            
            else if isBookmark {
                var imageView : UIImageView
                imageView  = UIImageView(frame:CGRect(x: 0, y: 0, width: 20, height: 20))
                imageView.image = selected ? #imageLiteral(resourceName: "bookmark_filled") : #imageLiteral(resourceName: "bookmark_filled")
                accessoryView = imageView
            }
            else if !isPublic {
                var imageView : UIImageView
                imageView  = UIImageView(frame:CGRect(x: 0, y: 0, width: 20, height: 20))
                imageView.image = selected ? #imageLiteral(resourceName: "private") : #imageLiteral(resourceName: "private_unfilled")
                accessoryView = imageView
            }
                
            else {
                var imageView : UIImageView
                imageView  = UIImageView(frame:CGRect(x: 0, y: 0, width: 20, height: 20))
                imageView.image = selected ? #imageLiteral(resourceName: "bookmark_filled") : nil
                accessoryView = imageView
            }
            
            backgroundColor = selected ? selectedColor.withAlphaComponent(0.5) : UIColor.white
        }
    
        imageView?.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                       self?.imageView?.transform = .identity
                        
            },
                       completion: nil)
        
    
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
