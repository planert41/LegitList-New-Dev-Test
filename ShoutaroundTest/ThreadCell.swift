//
//  ThreadCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 11/27/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

protocol ThreadCellDelegate {
    func refreshPost(post:Post)
    func didTapPicture(post:Post)
}

class ThreadCell: UICollectionViewCell {

    var delegate: ThreadCellDelegate?
    
    
    var messageThread: MessageThread? {
        didSet{
            
            // Set Posts
            Database.fetchPostWithPostID(postId: (messageThread?.postId)!) { (post, error) in
                if let error = error {
                    print("Error Fetching Message Thread Post \(self.messageThread?.threadID)")
                }
            self.post = post
            }
            
//            print(self.messageThread)
//             Set Latest Message as Displayed Message
            self.fetchLatestMessage(messageThread: self.messageThread)
            
            // Set Thread Users
            
            if let userList = messageThread?.threadUsers.joined(separator: ",") {
                let userAttributedText = NSAttributedString(string: "Re: " + userList, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.italicSystemFont(ofSize: 10),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.gray]))
                self.usersLabel.attributedText = userAttributedText
            }
            
            var threadUsers = messageThread?.threadUserUids.filter({ (uid) -> Bool in
                return uid != CurrentUser.uid
            })
            guard let displayUserUid = (threadUsers?.count ?? 0) > 0 ? threadUsers![0] : CurrentUser.uid else {return}

        // REFRESH DISPLAYED USER
            refreshUser()
            Database.fetchUserWithUID(uid: displayUserUid) { (user) in
                if let username = self.messageThread?.threadUserDic[displayUserUid] {
                    self.usernameLabel.text = username.capitalizingFirstLetter()
                }
                self.user = user
            }
            
        }
    }
    
    func refreshUser() {
        self.userProfileImageView.image = UIImage()
        self.usernameLabel.text = ""
    }
    
    var post: Post? {
        didSet{
            guard let imageUrl = post?.imageUrl else {return}
            photoImageView.loadImage(urlString: imageUrl)
            postEmojiLabel.text = post?.emoji
            
            bookmarkButton.setImage(post?.hasPinned == true ? #imageLiteral(resourceName: "hashtag_fill").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "hashtag_unfill").withRenderingMode(.alwaysOriginal), for: .normal)
            
        }
    }
    
    var displayedMessage: Message? {
        didSet{
            guard let displayedMessage = displayedMessage else {return}
//            Database.fetchUserWithUID(uid: displayedMessage.senderUID) { (user) in
//                self.user = user
//            }
            
//            print("Displayed Msg: \(displayedMessage)")
            
            let formatter = DateFormatter()
//            formatter.dateFormat = "MMM d YYYY, h:mm a"
            formatter.dateFormat = "MMM d YYYY"
            let timeAgoDisplay = formatter.string(from: displayedMessage.creationDate)
            self.messageDate.text = timeAgoDisplay
            self.messageDate.sizeToFit()
            self.messageTextView.text = self.displayedMessage?.message
            self.messageTextView.sizeToFit()
        }
    }
    
    var user: User? = nil {
        didSet{
            guard let profileImageUrl = self.user?.profileImageUrl else {return}
            self.userProfileImageView.loadImage(urlString: profileImageUrl)
            self.usernameLabel.text = self.user?.username
            self.usernameLabel.sizeToFit()
        }
    }
    
    let photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .white
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    var photoImageWidthConstraint: NSLayoutConstraint?
    var photoImageWidth = 40.0

    let messageView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    let userProfileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        return iv
    }()
    
    var usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.boldSystemFont(ofSize: 10)
        label.sizeToFit()
        return label
    }()
    
    var messageDate: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.textAlignment = NSTextAlignment.right
        label.font = UIFont.boldSystemFont(ofSize: 9)
        label.textColor = UIColor.lightGray
        label.sizeToFit()
        return label
    }()
    
    var messageTextView: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 0
        label.sizeToFit()
        return label
    }()
    
    var usersLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.boldSystemFont(ofSize: 10)
        label.sizeToFit()
        return label
    }()
    
    let postActionView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    var postEmojiLabel: UILabel = {
        let label = UILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.white
        return label
    }()
    
    lazy var bookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "bookmark_unselected").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleBookmark), for: .touchUpInside)
        return button
        
    }()
    
    @objc func handleBookmark() {
        
        //    delegate?.didBookmark(for: self)
        
        guard let postId = self.post?.id else {return}
        guard let creatorId = self.post?.creatorUID else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        Database.handleBookmark(postId: postId, creatorUid: creatorId){
        }
        
        // Animates before database function is complete
        
        if (self.post?.hasPinned)! {
            self.post?.listCount -= 1
        } else {
            self.post?.listCount += 1
        }
        self.post?.hasPinned = !(self.post?.hasPinned)!
        self.delegate?.refreshPost(post: self.post!)
        
        bookmarkButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.bookmarkButton.transform = .identity
            },
                       completion: nil)

        
    }
    
    
    func fetchLatestMessage(messageThread: MessageThread!){
    
        guard let messageDictionaries = messageThread.messageDictionaries else {return}
        var messages: [Message] = []
        
        for (key,value) in messageDictionaries {
            let tempDictionary = value as! [String:Any]
            let tempMessage = Message.init(messageID: key, dictionary: tempDictionary)
            messages.append(tempMessage)
        }
    
        messages.sort { (p1, p2) -> Bool in
            return p1.creationDate.compare(p2.creationDate) == .orderedDescending
        }
        
        self.displayedMessage = messages[0]
    }

    
    override init(frame: CGRect) {
        super.init(frame:frame)
     
    // USER PROFILE PIC
        addSubview(userProfileImageView)
        userProfileImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 10, paddingLeft: 20, paddingBottom: 10, paddingRight: 0, width: 50, height: 50)
        userProfileImageView.widthAnchor.constraint(equalTo: userProfileImageView.heightAnchor, multiplier: 1).isActive = true
        userProfileImageView.layer.cornerRadius = 50/2
        userProfileImageView.clipsToBounds = true
        
    // Add Photo
        addSubview(photoImageView)
        photoImageView.anchor(top: userProfileImageView.topAnchor, left: nil, bottom: userProfileImageView.bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        photoImageWidthConstraint = photoImageView.widthAnchor.constraint(equalToConstant: 0)
        photoImageWidthConstraint?.isActive = true
        
    // Add Message View
        addSubview(messageView)
        messageView.anchor(top: topAnchor, left: userProfileImageView.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 10, paddingLeft: 20, paddingBottom: 10, paddingRight: 10, width: 0, height: 0)
        
        
        messageView.addSubview(usernameLabel)
        usernameLabel.anchor(top: messageView.topAnchor, left: messageView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)

        
        messageView.addSubview(messageDate)
        messageDate.anchor(top: messageView.topAnchor, left: nil, bottom: nil, right: messageView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        messageDate.centerYAnchor.constraint(equalTo: usernameLabel.centerYAnchor).isActive = true
        usernameLabel.rightAnchor.constraint(lessThanOrEqualTo: messageDate.leftAnchor,constant: 5).isActive = true

        messageView.addSubview(messageTextView)
        messageTextView.anchor(top: usernameLabel.bottomAnchor, left: messageView.leftAnchor, bottom: messageView.bottomAnchor, right: messageView.rightAnchor, paddingTop: 3, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        messageTextView.sizeToFit()
//        messageTextView.backgroundColor = UIColor.blue
    
    
        let senderBottomDividerView = UIView()
        senderBottomDividerView.backgroundColor = UIColor.lightGray
        addSubview(senderBottomDividerView)
        senderBottomDividerView.anchor(top: bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        let topBottomDividerView = UIView()
        topBottomDividerView.backgroundColor = UIColor.lightGray
        addSubview(topBottomDividerView)
        topBottomDividerView.anchor(top: nil, left: leftAnchor, bottom: topAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)

//
//    // Add Post Emoji and Bookmark Button
//        addSubview(postActionView)
//        postActionView.anchor(top: nil, left: photoImageView.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
//        addSubview(bookmarkButton)
//        bookmarkButton.anchor(top: postActionView.topAnchor, left: nil, bottom: postActionView.bottomAnchor, right: postActionView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 20, height: 20)
//
//        addSubview(postEmojiLabel)
//        postEmojiLabel.anchor(top: postActionView.topAnchor, left: photoImageView.rightAnchor, bottom: postActionView.bottomAnchor, right: bookmarkButton.leftAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
//
//
//
//        addSubview(usersLabel)
//        usersLabel.anchor(top: nil, left: messageView.leftAnchor, bottom: messageView.bottomAnchor, right: messageView.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 10)
//
        

    

        

        
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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


class MessageThreadTableViewCell: UITableViewCell {

    
        var delegate: ThreadCellDelegate?
        
        
        var messageThread: MessageThread? {
            didSet{
                
                // Set Posts
                Database.fetchPostWithPostID(postId: (messageThread?.postId)!) { (post, error) in
                    if let error = error {
                        print("Error Fetching Message Thread Post \(self.messageThread?.threadID)")
                    }
                self.post = post
                }
                
    //            print(self.messageThread)
    //             Set Latest Message as Displayed Message
                self.fetchLatestMessage(messageThread: self.messageThread)
                
                // Set Thread Users
                
                if let userList = messageThread?.threadUsers.joined(separator: ",") {
                    let userAttributedText = NSAttributedString(string: "Re: " + userList, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.italicSystemFont(ofSize: 10),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.gray]))
                    self.usersLabel.attributedText = userAttributedText
                }
                
                var threadUsers = messageThread?.threadUserUids.filter({ (uid) -> Bool in
                    return uid != CurrentUser.uid
                })
                guard let displayUserUid = (threadUsers?.count ?? 0) > 0 ? threadUsers![0] : CurrentUser.uid else {return}

            // REFRESH DISPLAYED USER
                refreshUser()
                Database.fetchUserWithUID(uid: displayUserUid) { (user) in
                    if let username = self.messageThread?.threadUserDic[displayUserUid] {
                        self.usernameLabel.text = username.capitalizingFirstLetter()
                    }
                    
                    self.user = user
                }
                
                
            }
        }
        
        var post: Post? {
            didSet{
                guard let imageUrl = post?.imageUrl else {return}
                photoImageView.loadImage(urlString: imageUrl)
                postEmojiLabel.text = post?.emoji
                
                bookmarkButton.setImage(post?.hasPinned == true ? #imageLiteral(resourceName: "hashtag_fill").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "hashtag_unfill").withRenderingMode(.alwaysOriginal), for: .normal)
                
            }
        }
        
        var displayedMessage: Message? {
            didSet{
                guard let displayedMessage = displayedMessage else {return}
//                Database.fetchUserWithUID(uid: displayedMessage.senderUID) { (user) in
//                    self.user = user
//                }
                
//                print("Displayed Msg: \(displayedMessage)")
                
                let formatter = DateFormatter()
    //            formatter.dateFormat = "MMM d YYYY, h:mm a"
                formatter.dateFormat = "MMM d YYYY"
                let timeAgoDisplay = formatter.string(from: displayedMessage.creationDate)
                self.messageDate.text = timeAgoDisplay
                self.messageDate.sizeToFit()
                self.messageTextView.text = self.displayedMessage?.message
                self.messageTextView.sizeToFit()
            }
        }
        
        var user: User? = nil {
            didSet{
                guard let profileImageUrl = self.user?.profileImageUrl else {return}
                self.userProfileImageView.loadImage(urlString: profileImageUrl)
                self.usernameLabel.text = self.user?.username
                self.usernameLabel.sizeToFit()
            }
        }
    
        func refreshUser() {
            self.userProfileImageView.image = UIImage()
            self.usernameLabel.text = ""
        }
        
        let photoImageView: CustomImageView = {
            let iv = CustomImageView()
            iv.backgroundColor = .white
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            return iv
            
        }()
        
        let messageView: UIView = {
            let view = UIView()
            view.backgroundColor = UIColor.white
            return view
        }()
        
        let userProfileImageView: CustomImageView = {
            let iv = CustomImageView()
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
            return iv
        }()
        
        var usernameLabel: UILabel = {
            let label = UILabel()
            label.text = "Username"
            label.font = UIFont.boldSystemFont(ofSize: 15)
            label.sizeToFit()
            return label
        }()
        
        var messageDate: UILabel = {
            let label = UILabel()
            label.text = "Username"
            label.textAlignment = NSTextAlignment.right
            label.font = UIFont.boldSystemFont(ofSize: 9)
            label.textColor = UIColor.lightGray
            label.sizeToFit()
            return label
        }()
        
        var messageTextView: UILabel = {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 10)
            label.numberOfLines = 0
            label.sizeToFit()
            return label
        }()
        
        var usersLabel: UILabel = {
            let label = UILabel()
            label.text = "Username"
            label.font = UIFont.boldSystemFont(ofSize: 10)
            label.sizeToFit()
            return label
        }()
        
        let postActionView: UIView = {
            let view = UIView()
            view.backgroundColor = UIColor.white
            return view
        }()
        
        var postEmojiLabel: UILabel = {
            let label = UILabel()
            label.text = "Emojis"
            label.font = UIFont.boldSystemFont(ofSize: 14)
            label.textAlignment = NSTextAlignment.left
            label.backgroundColor = UIColor.white
            return label
        }()
        
        lazy var bookmarkButton: UIButton = {
            let button = UIButton(type: .system)
            button.setImage(#imageLiteral(resourceName: "bookmark_unselected").withRenderingMode(.alwaysOriginal), for: .normal)
            button.addTarget(self, action: #selector(handleBookmark), for: .touchUpInside)
            return button
            
        }()
        
    @objc func handleBookmark() {
            
            //    delegate?.didBookmark(for: self)
            
            guard let postId = self.post?.id else {return}
            guard let creatorId = self.post?.creatorUID else {return}
            guard let uid = Auth.auth().currentUser?.uid else {return}
            
            Database.handleBookmark(postId: postId, creatorUid: creatorId){
            }
            
            // Animates before database function is complete
            
            if (self.post?.hasPinned)! {
                self.post?.listCount -= 1
            } else {
                self.post?.listCount += 1
            }
            self.post?.hasPinned = !(self.post?.hasPinned)!
            self.delegate?.refreshPost(post: self.post!)
            
            bookmarkButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            
            UIView.animate(withDuration: 1.0,
                           delay: 0,
                           usingSpringWithDamping: 0.2,
                           initialSpringVelocity: 6.0,
                           options: .allowUserInteraction,
                           animations: { [weak self] in
                            self?.bookmarkButton.transform = .identity
                },
                           completion: nil)

            
        }
        
        
        func fetchLatestMessage(messageThread: MessageThread!){
        
            guard let messageDictionaries = messageThread.messageDictionaries else {return}
            var messages: [Message] = []
            
            for (key,value) in messageDictionaries {
                let tempDictionary = value as! [String:Any]
                let tempMessage = Message.init(messageID: key, dictionary: tempDictionary)
                messages.append(tempMessage)
            }
        
            messages.sorted { (p1, p2) -> Bool in
                return p1.creationDate.compare(p2.creationDate) == .orderedDescending
            }
            
            if messages.count > 0 {
                self.displayedMessage = messages[0]
            } else {
                self.displayedMessage = nil
            }
        }

        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
         
        // Add Photo
            addSubview(photoImageView)
            photoImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            photoImageView.widthAnchor.constraint(equalTo: photoImageView.heightAnchor, multiplier: 1).isActive = true
            
        // Add Post Emoji and Bookmark Button
            addSubview(postActionView)
            postActionView.anchor(top: nil, left: photoImageView.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
            addSubview(bookmarkButton)
            bookmarkButton.anchor(top: postActionView.topAnchor, left: nil, bottom: postActionView.bottomAnchor, right: postActionView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 20, height: 20)
            
            addSubview(postEmojiLabel)
            postEmojiLabel.anchor(top: postActionView.topAnchor, left: photoImageView.rightAnchor, bottom: postActionView.bottomAnchor, right: bookmarkButton.leftAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
            
        // Add Message View
            addSubview(messageView)
            messageView.anchor(top: topAnchor, left: photoImageView.rightAnchor, bottom: postActionView.topAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            
            addSubview(messageDate)
            messageDate.anchor(top: messageView.topAnchor, left: nil, bottom: nil, right: messageView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 6, width: 100, height: 10)
            
            addSubview(usersLabel)
            usersLabel.anchor(top: nil, left: messageView.leftAnchor, bottom: messageView.bottomAnchor, right: messageView.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 10)
            
            addSubview(userProfileImageView)
            userProfileImageView.anchor(top: messageView.topAnchor, left: messageView.leftAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 0, width: 30, height: 30)
            userProfileImageView.widthAnchor.constraint(equalTo: userProfileImageView.heightAnchor, multiplier: 1).isActive = true
            userProfileImageView.layer.cornerRadius = 25/2
            userProfileImageView.clipsToBounds = true
            
            addSubview(usernameLabel)
            usernameLabel.anchor(top: userProfileImageView.topAnchor, left: userProfileImageView.rightAnchor, bottom: nil, right: messageDate.leftAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
            usernameLabel.heightAnchor.constraint(equalTo: userProfileImageView.heightAnchor, multiplier: 0.5).isActive = true
    //        usernameLabel.backgroundColor = UIColor.yellow

        
            addSubview(messageTextView)
            messageTextView.anchor(top: usernameLabel.bottomAnchor, left: userProfileImageView.rightAnchor, bottom: nil, right: messageView.rightAnchor, paddingTop: 2, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
            messageTextView.sizeToFit()
    //        messageTextView.backgroundColor = UIColor.blue
            
            let senderBottomDividerView = UIView()
            senderBottomDividerView.backgroundColor = UIColor.lightGray
            addSubview(senderBottomDividerView)
            senderBottomDividerView.anchor(top: postActionView.bottomAnchor, left: photoImageView.rightAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
            
            
            
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        
    
}

