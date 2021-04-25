//
//  MainUserProfileView.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/6/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

protocol MainUserProfileViewDelegate {
    func didTapEmoji(index: Int, emoji: String)
    func didTapUserUid(uid:String)
    func didTapUserView()

}

class MainUserProfileView: UIView, EmojiButtonArrayDelegate {
    func doubleTapEmoji(index: Int?, emoji: String) {
        
    }
    
    var delegate: MainUserProfileViewDelegate?
    
    var user: User? = nil{
        didSet {
            print("MainUserProfileView | \(user?.username)")
            self.updateUser()
        }
    }
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.adjustsFontSizeToFitWidth = true
        //        label.numberOfLines = 0
        return label
    }()
 
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .white
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
//        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        return iv
    }()
    
    let socialStatsLabel: UILabel = {
        let label = UILabel()
        label.text = "SocialStats"
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 0
        return label
    }()
    
    
    let emojiLabel: UILabel = {
        let label = UILabel()
        label.text = "Emoji"
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()
    
    let emojiDetailLabel: PaddedUILabel = {
        let label = PaddedUILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 25)
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.rgb(red: 255, green: 242, blue: 230)
        label.layer.cornerRadius = 30/2
        label.layer.borderWidth = 0.25
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.masksToBounds = true
        return label
    }()
    
    var emojiArray = EmojiButtonArray(emojis: [], frame: CGRect(x: 0, y: 0, width: 0, height: 25))

    
    lazy var followButton: UIButton = {
        let button = UIButton()
        button.setTitle("Follow", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.backgroundColor = UIColor.mainBlue()
        button.addTarget(self, action: #selector(handleFollow), for: .touchUpInside)
        return button
        
    }()
    
    func updateUser(){
        if let _ = user {
            print("MainUserProfileView Updating | \(user?.username)")
            setupUsernameLabel()
            setupSocialStatsLabel()
            setupEmojis()
            setupFollowButton()
        } else {
            print("No User")
        }
    }
    
    func setupUsernameLabel() {
        self.profileImageView.loadImage(urlString: (self.user?.profileImageUrl)!)
        
        let usernameLabelText = NSMutableAttributedString()
        
        let usernameString = NSMutableAttributedString(string: "\((self.user?.username)!) ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 15)]))
        usernameLabelText.append(usernameString)
        
        
        if let credCount = self.user?.total_cred {
            if credCount > 0 {
                let credButtonString = NSMutableAttributedString(string: "  \(credCount) ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 13)]))
                usernameLabelText.append(credButtonString)
                
                let image1Attachment = NSTextAttachment()
//                let inputImage = UIImage(named: "cred")!
                let inputImage = #imageLiteral(resourceName: "drool")

                image1Attachment.image = inputImage
                
                image1Attachment.bounds = CGRect(x: 0, y: (usernameLabel.font.capHeight - (inputImage.size.height)).rounded() / 2, width: inputImage.size.width, height: inputImage.size.height)
                
                let image1String = NSAttributedString(attachment: image1Attachment)
                usernameLabelText.append(image1String)
            }
        }
        
        self.usernameLabel.attributedText = usernameLabelText
        self.usernameLabel.sizeToFit()
        
    }
    
    func setupEmojis(){
        if (user?.topEmojis.count)!>0{
            emojiArray.emojiLabels = (user?.topEmojis)!
        } else {
            emojiArray.emojiLabels = []
        }
        emojiArray.setEmojiButtons()
        emojiArray.sizeToFit()
    }
    
    func didTapEmoji(index: Int?, emoji: String) {
        guard let index = index else {
            print("No Index For emoji \(emoji)")
            return
        }
        
        self.delegate?.didTapEmoji(index: index, emoji: emoji)
        
        
//        guard let  displayEmojiTag = EmojiDictionary[emoji] else {return}
//        //        self.delegate?.displaySelectedEmoji(emoji: displayEmoji, emojitag: displayEmojiTag)
//
//        print("Selected Emoji | \(index) | \(emoji) | \(displayEmojiTag)")
//
//        var captionDelay = 3
//        emojiDetailLabel.text = "\(emoji)  \(displayEmojiTag)"
//        emojiDetailLabel.alpha = 1
//        emojiDetailLabel.sizeToFit()
//
//        UIView.animate(withDuration: 0.5, delay: TimeInterval(captionDelay), options: UIViewAnimationOptions.curveEaseOut, animations: {
//            self.emojiDetailLabel.alpha = 0
//        }, completion: { (finished: Bool) in
//        })
    }
    
    func setupSocialStatsLabel() {
        let socialStats = NSMutableAttributedString()
        
        if let listCount = self.user?.lists_created {
            if listCount > 0 {
                let credCountString = NSMutableAttributedString(string: "\(listCount) Lists ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 14)]))
                socialStats.append(credCountString)
            }
        }

        
        if let postCount = self.user?.posts_created {
            if postCount > 0 {
                let postCountString = NSMutableAttributedString(string: "\(postCount) Posts ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 14)]))
                socialStats.append(postCountString)
            }
        }
        
        
        if let fanCount = self.user?.followersCount {
            if fanCount > 0 {
                let fanCountString = NSMutableAttributedString(string: "\(fanCount) Fans ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 14)]))
                socialStats.append(fanCountString)
            }
        }
        
        socialStatsLabel.attributedText = socialStats
        socialStatsLabel.sizeToFit()
    }
    
    func setupFollowButton(){
        
        if user?.uid == Auth.auth().currentUser?.uid {
            self.followButton.isHidden = true
//            self.followButton.isHidden = false

        } else {
            self.followButton.isHidden = false
        }
        
        
        if (user?.isFollowing)!{
            self.followButton.setTitle("Unfollow", for: .normal)
            self.followButton.backgroundColor = UIColor.orange
        } else {
            self.followButton.setTitle("Follow", for: .normal)
            self.followButton.backgroundColor = UIColor.mainBlue()
            
        }
    }
    
    func handleFollow(){
        
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else {return}
        guard let userId = user?.uid else {return}
        if currentLoggedInUserId == userId {return}
        
        Database.handleFollowing(userUid: userId) { }
        
        self.user?.isFollowing = !(self.user?.isFollowing)!
        self.setupFollowButton()
        
    }
    
    
    func tapUserView(){
        self.delegate?.didTapUserView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        let cellView = UIView()
        addSubview(cellView)
        cellView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 100)
        cellView.backgroundColor = UIColor.white
        cellView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapUserView)))
        
        
        backgroundColor = UIColor.white
        
        addSubview(profileImageView)
        profileImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 80, height: 80)
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        profileImageView.layer.cornerRadius = 80/2
        
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(usernameTap)))
        
        addSubview(followButton)
        followButton.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 20, paddingLeft: 0, paddingBottom: 20, paddingRight: 5, width: 80, height: 40)
        followButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: profileImageView.topAnchor, left: profileImageView.rightAnchor, bottom: nil, right: followButton.leftAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 25)
        usernameLabel.isUserInteractionEnabled = true
        usernameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(usernameTap)))
        
        //
        //        addSubview(emojiLabel)
        //        emojiLabel.anchor(top: usernameLabel.bottomAnchor, left: profileImageView.rightAnchor, bottom: nil, right: followButton.leftAnchor, paddingTop: 1, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        
        addSubview(socialStatsLabel)
        socialStatsLabel.anchor(top: usernameLabel.bottomAnchor, left: profileImageView.rightAnchor, bottom: nil, right: followButton.leftAnchor, paddingTop: 2, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 25)
        
        addSubview(emojiArray)
        emojiArray.anchor(top: socialStatsLabel.bottomAnchor, left: profileImageView.rightAnchor, bottom: nil, right: nil, paddingTop: 3, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 25)
        emojiArray.rightAnchor.constraint(lessThanOrEqualTo: followButton.leftAnchor).isActive = true
        emojiArray.delegate = self
        
        addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top:topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        emojiDetailLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        emojiDetailLabel.alpha = 0

        
        
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        addSubview(separatorView)
        separatorView.anchor(top: cellView.bottomAnchor, left: usernameLabel.leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        // Do any additional setup after loading the view.
    }
    
    func usernameTap(){
        guard let uid = user?.uid else {return}
        self.delegate?.didTapUserUid(uid: uid)
    }
    

    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
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
