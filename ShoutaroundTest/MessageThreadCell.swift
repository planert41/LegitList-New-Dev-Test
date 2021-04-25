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


protocol MessageThreadCellDelegate {
    func didTapUsername(user:User?)
    func didTapListname(listId: String?)
    func showPost(post: Post?)
    func saveInteraction(event: Event?)
    func extOpenMessage(message: MessageThread?, reload: Bool)
    func saveMessageRead(messageThread: MessageThread)
}

class MessageThreadCell: UITableViewCell {
    
    var delegate: MessageThreadCellDelegate?

    var messageThread: MessageThread? {
        didSet{
            guard let messageThread = messageThread else {return}
            
            // Set Posts
            self.fetchPost()
            self.read = messageThread.isRead

            loadUserPic()
            loadUserNames()
//             Set Latest Message as Displayed Message
            self.fetchLatestMessage(messageThread: self.messageThread)
        }
    }
    

    
    var displayedMessage: Message? {
        didSet{
            guard let displayedMessage = displayedMessage else {
                self.eventTextView.text = ""
                return}
//            print("Displayed Msg: \(displayedMessage)")
            setupMessageText()
            setupDisplayPost()
        }
    }
    
    func setupDisplayPost() {
        if let postId = self.displayedMessage?.postId {
            Database.fetchPostWithPostID(postId: postId) { (post, err) in
                if let err = err {
                    print("setupDisplayPost | ERROR | \(err)")
                } else {
                    self.post = post
                }
            }
        }
    }
    
    var displayUserUid: String? = nil {
        didSet {
//            guard let displayUserUid = displayUserUid else {return}
//            Database.fetchUserWithUID(uid: displayUserUid) { (user) in
////                print("MessageThreadCell | Fetched User: \(displayUserUid) | \(self.messageThread?.threadID) Msg Thread")
//                self.displayUser = user
//            }
            
        }
    }

    var displayUser: User? = nil {
        didSet{
//            print("MessageThreadCell | DisplayUser | \(displayUser?.username) | \(displayUser?.uid) ")
            loadUser()
        }
    }
    
    func loadUser() {
        guard let displayUser = displayUser else {return}
        let profileImageUrl = displayUser.profileImageUrl
        self.profileImageView.loadImage(urlString: profileImageUrl)
//        print("MessageThreadCell | LoadImage | \(profileImageUrl)")
//        self.usernameLabel.text = self.displayUser?.username
//        self.usernameLabel.sizeToFit()
    }
    
    
    func fetchLatestMessage(messageThread: MessageThread?){
    
        guard let messageThread = messageThread else{return}
        guard let messageDictionaries = messageThread.messageDictionaries else {return}
        var messages: [Message] = []
        
        
//        for (key,value) in messageDictionaries {
//            let tempDictionary = value as! [String:Any]
//            let tempMessage = Message.init(messageID: key, dictionary: tempDictionary)
//            messages.append(tempMessage)
//        }
        
    
        messages = messageThread.messages.sorted { (p1, p2) -> Bool in
            return p1.creationDate.compare(p2.creationDate) == .orderedDescending
        }
        
        
        if messages.count > 0 {
            self.displayedMessage = messages[0]
        } else {
            self.displayedMessage = nil
        }
//        print("fetchLatestMessage | \(messageThread.threadID) Thread | \(self.displayedMessage?.message) | \(messages.count) Messages ")

    }

    
    var read: Bool = false {
        didSet {
            self.setupReadColor()
        }
    }
    
    func setupReadColor(){
        self.backgroundColor = self.read ? UIColor.clear : UIColor.mainBlue().withAlphaComponent(0.3)
    }
    
    
    func fetchPost(){
        guard let postId = self.messageThread?.postId else {
//            print("MessageThreadCell | No Post in Thread | \(self.messageThread?.postId) | MessageThread: \(self.messageThread?.threadID)")
            post = nil
            return}
        if postId == "" {
//            print("MessageThreadCell | No Post in Thread | \(self.messageThread?.postId) | MessageThread: \(self.messageThread?.threadID)")
            post = nil
            return
        }
        print("MessageThreadCell | Fetching \(postId) For \(self.messageThread?.threadID) Msg Thread ")
        Database.fetchPostWithPostID(postId: postId) { (post, error) in
            guard let post = post else {
                print("MessageThreadCell | No Post in Database | \(postId) | MessageThread: \(self.messageThread?.threadID)")
                return
            }
            self.post = post
//            print("EventCell | Fetched Post | \(postId) | Event: \(self.event?.id)")
        }
        
    }
    
    var post: Post?{
        didSet {
            setupPostImage()
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
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.adjustsFontSizeToFitWidth = true
        //        label.numberOfLines = 0
        return label
    }()
    
    let dateLabel: UILabel = {
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
        tv.textContainer.maximumNumberOfLines = 2
        tv.textContainerInset = UIEdgeInsets.zero
        tv.textContainer.lineBreakMode = .byTruncatingTail
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.isEditable = false
        tv.backgroundColor = UIColor.clear
        return tv
    }()
    
    func setupMessageText(){
        guard let displayedMessage = self.displayedMessage else {return}
        let attributedText = NSMutableAttributedString()
        
        let messageText = displayedMessage.message.cutoff(length: 100)
        
    // Message
        let textViewMessage = NSMutableAttributedString(string: messageText, attributes: [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 12), NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor()])
        attributedText.append(textViewMessage)
        
        self.eventTextView.attributedText = attributedText

    // ACTION DATE
        let formatter = DateFormatter()
        let calendar = NSCalendar.current
        
        let eventDate = displayedMessage.creationDate ?? Date()
        
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
        
        let dateString = NSMutableAttributedString(string: postDateString!, attributes: [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 11), NSAttributedString.Key.foregroundColor: UIColor.lightGray])

        self.dateLabel.attributedText = dateString
        self.dateLabel.sizeToFit()
        
    }

    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let cellView = UIView()
        addSubview(cellView)
        cellView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 80)
        
        addSubview(profileImageView)
        profileImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 60, height: 60)
        profileImageView.centerYAnchor.constraint(equalTo: cellView.centerYAnchor).isActive = true
        profileImageView.layer.cornerRadius = 60/2
        profileImageView.clipsToBounds = true
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(userProfileTapped)))
        
        addSubview(postImageView)
        postImageView.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 60, height: 60)
        postImageView.centerYAnchor.constraint(equalTo: cellView.centerYAnchor).isActive = true
        postImageView.isUserInteractionEnabled = true
        postImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(postTapped)))
        postImageView.layer.cornerRadius = 3
        postImageView.clipsToBounds = true
        postImageView.isHidden = true

        addSubview(usernameLabel)
        usernameLabel.anchor(top: profileImageView.topAnchor, left: profileImageView.rightAnchor, bottom: nil, right: postImageView.leftAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        
        
        addSubview(dateLabel)
        dateLabel.anchor(top: nil, left: usernameLabel.leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 3, paddingBottom: 5, paddingRight: 0, width: 0, height: 13)
        dateLabel.sizeToFit()
        
        addSubview(eventTextView)
        eventTextView.anchor(top: usernameLabel.bottomAnchor, left: profileImageView.rightAnchor, bottom: dateLabel.topAnchor, right: postImageView.leftAnchor, paddingTop: 2, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        eventTextView.isUserInteractionEnabled = true
        eventTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapMessage)))
        
//        eventTextView.backgroundColor = UIColor.yellow
        
        
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor(white: 0, alpha: 0.5)
//        separatorView.backgroundColor = UIColor.clear

        addSubview(separatorView)
        separatorView.anchor(top: cellView.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        setupReadColor()
        setupMessageText()
        loadUser()
    }
    
        
    func setupPostImage() {
//        print("Event Cell | Setup Post Image | \(self.post?.id) | \(self.post?.smallImageUrl)")

        if let smallUrl = self.post?.smallImageUrl {
            self.postImageView.loadImage(urlString: smallUrl)
            self.postImageView.isHidden = false
//            print("Event Cell | Small Image | \(smallUrl)| \(self.post?.id) | Event: \(self.event?.id)")
//            print("Event Cell | Small Image | \(self.post?.id) | \(smallUrl)")
        } else if let url = self.post?.imageUrls[0] {
            self.postImageView.loadImage(urlString: url)
            self.postImageView.isHidden = false
//            print("Event Cell | No Small Image URL, Load Full Image | \(self.post?.id) | \(url)")
        } else {
            self.postImageView.isHidden = true
//            print("Event Cell | No Image URLS | \(self.post?.id)")
        }

    }

    func loadUserPic() {
        // Determine User
        var tempDisplayUid: String? = nil
        guard let messageThread = self.messageThread else {return}

    // ONLY 1 USER - COULD BE SELF
        if messageThread.threadUserUids.count == 1 {
            tempDisplayUid = messageThread.threadUserUids[0]
        }
    // SHOW FIRST USER PIC
        else {
            for uid in messageThread.threadUserUids {
                if uid != CurrentUser.uid && tempDisplayUid == nil{
                    tempDisplayUid = uid
                    break
                }
            }
        }
        
        if let tempDisplayUid = tempDisplayUid {
            if messageThread.userArray[tempDisplayUid] != nil {
                self.displayUser = messageThread.userArray[tempDisplayUid]
            } else {
                Database.fetchUserWithUID(uid: tempDisplayUid) { (user) in
                    self.displayUser = user
                }
            }
        }
    }
        
        func loadUserNames() {
        // LOAD USERNAME TEXT
            guard let messageThread = self.messageThread else {return}
            var usernameText = ""
            if messageThread.threadUsers.count == 1 {
                usernameText = messageThread.threadUsers[0] as! String
            } else {
                for username in messageThread.threadUsers {
                    if username != CurrentUser.username {
                        if usernameText == "" {
                            usernameText = username ?? ""
                        } else {
                            usernameText += ", \(username)"
                        }
                    }
                }
            }

            print("Display Username: usernameText | \(messageThread.threadUsers)")
            self.usernameLabel.text = usernameText
            self.usernameLabel.sizeToFit()
        }

    
    
    
    @objc func didTapMessage() {
        guard let messageThread = self.messageThread else {return}
        self.saveInteraction()
        self.delegate?.extOpenMessage(message: messageThread, reload: true)

    }
    
    func saveInteraction(){
        guard let messageThread = self.messageThread else {return}
        print("EventCell | Interaction | Event ID: \(self.messageThread?.threadID)")
        self.read = true
        self.delegate?.saveMessageRead(messageThread: messageThread)
//        self.read = true
//        self.delegate?.saveInteraction(event: self.event)
    }
    
    
    @objc func userProfileTapped(){
        saveInteraction()
        self.delegate?.didTapUsername(user: self.displayUser)
    }

    @objc func postTapped(){
        saveInteraction()
        self.delegate?.showPost(post: self.post)
    }
    
    


    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.read = false
    // Reused cells removes extra pictures and shrinks back contentsize width. It gets expanded and added back later if >1 pic
//        let subViews = self.subviews
//        for subview in subViews{
//            if let img = subview as? CustomImageView {
//                img.image = nil
//                img.cancelImageRequestOperation()
//                if img.tag != 0 {
//                    img.removeFromSuperview()
//                }
//            }
//        }
    }

}

