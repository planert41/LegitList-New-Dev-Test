
//
//  CommentCell.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 9/3/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//
import UIKit

import MessageUI
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

protocol CommentCellDelegate {
    func didTapCancel(comment:Comment)
}

class CommentCell: UICollectionViewCell {
    
    var message: Message? {
        didSet {
            guard let message = message else {return}
            
            Database.fetchUserWithUID(uid: message.senderUID) { (user) in
                guard let user = user else {return}
            
            let attributedText = NSMutableAttributedString(string: user.username, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
            
            attributedText.append(NSAttributedString(string: " " + message.message, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 14)])))
            
                self.textView.attributedText = attributedText
            
                self.profileImageView.loadImage(urlString: user.profileImageUrl)
            
    // Disable comment delete if comment creator is not current user, or comment is Post Caption
            self.cancelButton.isHidden = true
                self.setupDateLabel()
        
    
            }
        }
    }
    
    func setupDateLabel() {

        var rawDate: Date? = nil
        if let message = self.message {
            rawDate = message.creationDate ?? Date()
        } else if let comment = self.comment {
            rawDate = comment.creationDate ?? Date()
        }
        
        guard let eventDate = rawDate else {
            dateLabel.isHidden = true
            dateLabelHeight?.constant = 0
            return
        }
        
        
        dateLabel.isHidden = false
        dateLabelHeight?.constant = 12
        dateLabelHeight?.isActive = true

        let formatter = DateFormatter()
        let calendar = NSCalendar.current
        
        
        let yearsAgo = calendar.dateComponents([.year], from: eventDate, to: Date())
        if (yearsAgo.year)! > 0 {
            formatter.dateFormat = "MMM d yy, h:mm a"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }
        
        let daysAgo =  calendar.dateComponents([.day], from: eventDate, to: Date())
        var postDateString: String?
        
        // If Post Date < 7 days ago, show < 7 days, else show date
        if (daysAgo.day)! <= 7 {
            postDateString = eventDate.timeAgoDisplay()
        } else {
            let dateDisplay = formatter.string(from: eventDate)
            postDateString = dateDisplay
        }
        
        let dateString = NSAttributedString(string: postDateString!, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 12),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.lightGray]))
        dateLabel.attributedText = dateString
        
    }
    
    var senderUser: User? = nil {
        didSet {
            
        }
    }
    
    
    var comment: Comment? {
        didSet {
            
            guard let comment = comment else {return}
//            guard let profileImageUrl = comment.user.profileImageUrl else {return}
//            guard let username = comment.user.username else {return}
            
            
            let attributedText = NSMutableAttributedString(string: comment.user.username, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
            
            attributedText.append(NSAttributedString(string: " " + comment.text, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 14)])))
            
            textView.attributedText = attributedText
            
            profileImageView.loadImage(urlString: comment.user.profileImageUrl)
            
    // Disable comment delete if comment creator is not current user, or comment is Post Caption
            self.cancelButton.isHidden = (self.comment?.user.uid != Auth.auth().currentUser?.uid || self.comment?.commentId == "postCaption")
            self.setupDateLabel()

        }
    }
    
    let textView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.isScrollEnabled = false
        textView.backgroundColor = UIColor.clear
//        label.numberOfLines = 0
//        label.backgroundColor = .white
        return textView
    }()
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        return iv
    }()
    
    lazy var cancelButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        button.setImage(#imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysOriginal), for: .normal)
        button.backgroundColor = UIColor.clear
        button.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        return button
    }()
    
    @objc func didTapCancel(){
        guard let inputComment = comment else {
            return
        }
        self.delegate?.didTapCancel(comment: inputComment)
    }
    
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.lightGray
        label.font = UIFont.systemFont(ofSize: 10)
        label.textAlignment = NSTextAlignment.right
        return label
        
    }()
    
    var dateLabelHeight: NSLayoutConstraint?
    
    var delegate: CommentCellDelegate?
    
    // POST
    var postView = UIView()
    var postViewHeight: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(postView)
//        postView
        
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 8, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
        profileImageView.layer.cornerRadius = 40/2

        addSubview(cancelButton)
        cancelButton.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 15, height: 15)
//        cancelButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        addSubview(textView)
        textView.anchor(top: topAnchor, left: profileImageView.rightAnchor, bottom: nil, right: cancelButton.leftAnchor, paddingTop: 4, paddingLeft: 4, paddingBottom: 4, paddingRight: 4, width: 0, height: 0)
        
        addSubview(dateLabel)
        dateLabel.anchor(top: textView.bottomAnchor, left: nil, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 2, paddingBottom: 4, paddingRight: 10, width: 0, height: 0)
        dateLabel.isHidden = true
        dateLabelHeight = dateLabel.heightAnchor.constraint(equalToConstant: 12)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.message = nil
        self.comment = nil
        self.setupDateLabel()

    // Reused cells removes extra pictures and shrinks back contentsize width. It gets expanded and added back later if >1 pic
        let subViews = self.subviews
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
