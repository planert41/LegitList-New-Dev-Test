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

protocol EventCellDelegate {
    func didTapUsername(user:User?)
    func didTapListname(listId: String?)
    func showPost(post: Post?)
    func showPostComments(post: Post?)
    func saveInteraction(event: Event?)
}


class EventCell: UITableViewCell {
    
    var delegate: EventCellDelegate?

    var currentUserEvent = true {
        didSet {
            self.setupReadColor()
        }
    }
    var event: Event? {
        didSet {
            guard let event = event else {return}
            self.eventType = event.eventType
            self.fetchUsers()
            self.fetchPost()
            self.setupEventText()
            self.read = event.read
            self.postImageView.isHidden = self.eventType == Object.user


//            if self.eventType == Event.PostView.like {
//                self.fetchPost()
//            } else {
//                setupEventText()
//            }
        }
    }
    
    var eventType: Object?
    var read: Bool = false {
        didSet {
            self.setupReadColor()
        }
    }
    
    func setupReadColor(){
        if currentUserEvent{
            self.backgroundColor = self.read ? UIColor.clear : UIColor.mainBlue().withAlphaComponent(0.3)
        } else {
            // NOT CURRENT USER NOTIFICATION, SO NO INTERACTION
            self.backgroundColor = UIColor.clear
        }
    }
    
    func fetchUsers(){
        if let userid = self.event?.creatorUid {
            Database.fetchUserWithUID(uid: userid) { (user) in
                self.initEventUser = user
                self.setupEventText()
//                print("EventCell | Fetched initEventUser | \((user?.username)!)")
            }
        }
        
        if let receiveUserId = self.event?.receiverUid {
            Database.fetchUserWithUID(uid: receiveUserId) { (user) in
                self.receiveEventUser = user
                self.setupEventText()
//                print("EventCell | Fetched receiveEventUser | \((user?.username)!)")
            }
        }
        
    }
    
    func fetchPost(){
        guard let postId = self.event?.postId else {return}
//        print(self.event?.postId)
//        let postId = (self.event?.postId)!
        Database.fetchPostWithPostID(postId: postId) { (post, error) in
            guard let post = post else {
                print("EventCell | No Post in Database | \(postId) | Event: \(self.event?.id)")
                return
            }
            self.post = post
//            print("EventCell | Fetched Post | \(postId) | Event: \(self.event?.id)")
        }
        
    }
    
    var post: Post?{
        didSet {
            setupEventText()
            setupPostImage()
        }
    }
    
    func setupPostImage() {
//        print("Event Cell | Setup Post Image | \(self.post?.id) | \(self.post?.smallImageUrl)")

        if let smallUrl = self.post?.smallImageUrl {
            if !smallUrl.isEmptyOrWhitespace() {
                self.postImageView.loadImage(urlString: smallUrl)
                return
            }
//            print("Event Cell | Small Image | \(smallUrl)| \(self.post?.id) | Event: \(self.event?.id)")
        }
        if let url = self.post?.imageUrls[0] {
            self.postImageView.loadImage(urlString: url)
            print("Event Cell | No Small Image URL, Load Full Image | \(self.post?.id)")
            return
        } else {
            print("Event Cell | No Image URLS | \(self.post?.id)")
        }

    }
    
    var initEventUser: User?{
        didSet {
            setupUserProfileImage()
            setupEventText()
        }
    }
    
    var receiveEventUser: User?{
        didSet {
//            setupUserProfileImage()
            setupEventText()
        }
    }
    
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .white
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.clearBackground = true
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
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.adjustsFontSizeToFitWidth = true
        //        label.numberOfLines = 0
        return label
    }()
    
    
    let eventTextView: UITextView = {
        let tv = UITextView()
        tv.isScrollEnabled = false
        tv.textContainer.maximumNumberOfLines = 0
        tv.textContainerInset = UIEdgeInsets.zero
        tv.textContainer.lineBreakMode = .byTruncatingTail
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.isEditable = false
        tv.backgroundColor = UIColor.clear
        return tv
    }()
    
    func setupEventText(){
        guard let uid = Auth.auth().currentUser?.uid else {return}
        guard let user = self.initEventUser else {return}
//        guard let post = self.post else {return}
        guard let action = self.event?.action else {return}
        guard let event = self.event else {return}
        eventTextView.textContainer.maximumNumberOfLines = 0
        let attributedText = NSMutableAttributedString()
        
    // INIT USERNAME
        
        var usernameString = (user.uid == uid) ? "You" : user.username
        
        let userName = NSMutableAttributedString(string: usernameString + " ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black]))
        attributedText.append(userName)
        
    // ACTION - LIST OR LIKE
        var actionString = ""
        var noListName = event.listName?.isEmptyOrWhitespace() ?? true
        
        if event.eventAction == .followUser {
            actionString = "followed you"
        } else if event.eventAction == .likePost {
            actionString = "liked your post "
        } else if event.eventAction == .commentPost {
            actionString = "commented on your post "
        } else if event.eventAction == .commentTooPost {
            actionString = "commented on a post you commented"
        } else if event.eventAction == .addPostToList {
            actionString = "bookmarked your post to \(noListName ? "a list" : "")"
        } else if event.eventAction == .followList {
            actionString = "followed \(noListName ? "your list" : "")"
        }
        

        let actionMString = NSMutableAttributedString(string: actionString, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 13)]))
        attributedText.append(actionMString)
        
        // ADD LIST NAME IF AVAILABLE
        if (event.eventAction == .addPostToList || event.eventAction == .followList) {
            if let listName = event.listName {
                let listNameText = NSMutableAttributedString(string: listName, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black]))
                attributedText.append(listNameText)
            }
        }
        
        
    // ACTION DATE
        let formatter = DateFormatter()
        let calendar = NSCalendar.current
        
        let eventDate = event.eventTime ?? Date()
        
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
        
        let dateString = NSAttributedString(string: " \n " + postDateString!, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 12),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.lightGray]))
        attributedText.append(dateString)
        
        self.eventTextView.attributedText = attributedText
        
        if event.eventAction == .reportPost {
            let reportString = NSMutableAttributedString(string: "One of your post has been reported more than 3 times and set to private", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 13)]))
            self.eventTextView.attributedText = reportString
        }
        self.eventTextView.sizeToFit()
        

//        // RECEIVER
//
//        var receiverString = ""
//        if let receiveUser = receiveEventUser {
//            receiverString = (receiveUser.uid == uid ? "your" : receiveUser.username) + " "
//        }
//
//        let receiverName = NSMutableAttributedString(string: receiverString, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 13),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): (receiveEventUser?.isFollowing ?? false) ? UIColor.mainBlue() : UIColor.black]))
//        attributedText.append(receiverName)
//
//
//        // ITEM
//        var itemString = ""
//        switch event.eventType {
//        case .list:
//            // Grid View
//            itemString = "list"
//        case .post:
//            // List View
//            itemString = "post"
//        case .user:
//            // Full Post View
//            itemString = "user"
//        default:
//            itemString = ""
//        }
//
//        itemString += action == Social.bookmark ? " to " : ""
//
//        if itemString != "" {
//            let objectName = NSMutableAttributedString(string: itemString + " ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 13),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black]))
//            attributedText.append(objectName)
//        }
//
//
//        if action == Social.bookmark {
//            let listnameString = (event.listName ?? "a list")
//
//            let listName = NSMutableAttributedString(string: listnameString, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.legitColor()]))
//            attributedText.append(listName)
//        }
//
//
////        print(event.action, event.eventType, attributedText.string)
//
//
//
//
//        if event.eventAction == .followUser {
//            let receiveUser = receiveEventUser
//            var followUserString: String = usernameString + " followed " + ((receiveUser?.uid == Auth.auth().currentUser?.uid) ? "you" : receiverString)
//            let attributedText = NSMutableAttributedString(string: followUserString, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14),convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black]))
//            attributedText.append(dateString)
//            self.eventTextView.attributedText = attributedText
//            self.eventTextView.sizeToFit()
//        } else {
//            self.eventTextView.attributedText = attributedText
//            self.eventTextView.sizeToFit()
//        }

        
        
    }

    
    func setupUserProfileImage() {
        if self.event?.eventAction == .reportPost {
            let icon = #imageLiteral(resourceName: "legit_check").withRenderingMode(.alwaysOriginal)
            if let url = CurrentUser.profileImageUrl {
                self.profileImageView.loadImage(urlString: url)
            } else {
                self.profileImageView.image = icon
            }
        }
        else if let image = self.initEventUser?.profileImageUrl {
            self.profileImageView.loadImage(urlString: (self.initEventUser?.profileImageUrl)!)
        }
    }
    
//    override var isSelected: Bool {
//        didSet {
//            self.backgroundColor = self.isSelected ? UIColor.mainBlue().withAlphaComponent(0.2) : UIColor.white
//        }
//    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let cellView = UIView()
        addSubview(cellView)
        cellView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 70)
        
        cellView.addSubview(profileImageView)
        profileImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 50, height: 50)
        profileImageView.centerYAnchor.constraint(equalTo: cellView.centerYAnchor).isActive = true
        profileImageView.layer.cornerRadius = 50/2
        profileImageView.clipsToBounds = true
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(userProfileTapped)))
        
        cellView.addSubview(postImageView)
        postImageView.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 50, height: 50)
        postImageView.centerYAnchor.constraint(equalTo: cellView.centerYAnchor).isActive = true
        postImageView.isUserInteractionEnabled = true
        postImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(postTapped)))
        postImageView.layer.cornerRadius = 3
        postImageView.clipsToBounds = true

        cellView.addSubview(eventTextView)
        eventTextView.anchor(top: profileImageView.topAnchor, left: profileImageView.rightAnchor, bottom: cellView.bottomAnchor, right: postImageView.leftAnchor, paddingTop: 2, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        eventTextView.isUserInteractionEnabled = true
//        eventTextView.backgroundColor = UIColor.yellow
        
        let textViewTap = UITapGestureRecognizer(target: self, action: #selector(self.HandleTap(sender:)))
        textViewTap.delegate = self
        eventTextView.addGestureRecognizer(textViewTap)
        
        let separatorView = UIView()
//        separatorView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        separatorView.backgroundColor = UIColor.clear

        addSubview(separatorView)
        separatorView.anchor(top: cellView.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        setupEventText()
        setupReadColor()

    }
    
    @objc func testTap(){
        print("testTap")
    }
    
    func saveInteraction(){
        print("EventCell | Interaction | Event ID: \(self.event?.id)")
        if !self.currentUserEvent {
            return
        }
        self.read = true
        self.delegate?.saveInteraction(event: self.event)
    }
    
    
    @objc func userProfileTapped(){
        print("userProfileTapped")
        saveInteraction()
        self.delegate?.didTapUsername(user: self.initEventUser)
    }

    @objc func postTapped(){
        print("postTapped")
        saveInteraction()
        self.delegate?.showPost(post: self.post)
    }
    

    @objc func HandleTap(sender: UITapGestureRecognizer) {
        print("HandleTap")
        saveInteraction()
        let myTextView = sender.view as! UITextView //sender is TextView
        let layoutManager = myTextView.layoutManager //Set layout manager
        
        // location of tap in myTextView coordinates
        
        var location = sender.location(in: myTextView)
        
        if let tapPosition = eventTextView.closestPosition(to: location) {
            if let textRange = eventTextView.tokenizer.rangeEnclosingPosition(tapPosition , with: .word, inDirection: convertToUITextDirection(1)) {
                let tappedWord = eventTextView.text(in: textRange)
                print("Tapped Word: \(tappedWord)" ?? "")
                if self.event?.action == Social.follow {
                    if let uid = event?.creatorUid {
                        self.delegate?.didTapUsername(user: self.initEventUser)
                    }
                }
                else if tappedWord == self.initEventUser?.username.replacingOccurrences(of: "@", with: "") {
                    self.delegate?.didTapUsername(user: self.initEventUser)
                } else if tappedWord == self.event?.listName {
                    self.delegate?.didTapListname(listId: self.event?.listId)
                }  else if self.event?.action == Social.bookmark {
                    self.delegate?.didTapListname(listId: self.event?.listId)
                } else if (self.event?.action == Social.comment || self.event?.action == Social.commentToo) {
                    self.delegate?.showPostComments(post: self.post)
                }
                else {
                    self.delegate?.showPost(post: self.post)
                }
            }
        }
        
        //        To Detect if textview is truncated
        //        if textView.contentSize.height > textView.bounds.height
        
        
    }
    
    func tapPost() {
        print("tapPost")
        if self.event?.eventAction == .followUser {
            self.delegate?.didTapUsername(user: self.initEventUser)
        }
        else if self.event?.eventAction == .addPostToList {
            self.delegate?.didTapListname(listId: self.event?.listId)
        }
        
        else {
            self.delegate?.showPost(post: self.post)
        }
        
    }
    
    
    func word(atPosition: CGPoint) -> String? {
        if let tapPosition = eventTextView.closestPosition(to: atPosition) {
            if let textRange = eventTextView.tokenizer.rangeEnclosingPosition(tapPosition , with: .word, inDirection: convertToUITextDirection(1)) {
                let tappedWord = eventTextView.text(in: textRange)
                print("Word: \(tappedWord)" ?? "")
                return tappedWord
            }
            return nil
        }
        return nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.read = false
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

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUITextDirection(_ input: Int) -> UITextDirection {
    return UITextDirection(rawValue: input)
}
