//
//  BottomEmojiBar.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 12/29/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit
import FirebaseAuth

protocol BottomActionBarDelegate {
    func handleComment()
    func handleLike()
    func handleTagList()
    func alert(title: String, message: String)
}

class BottomActionBar: UIView {
 
    var delegate: BottomActionBarDelegate?
    
    var post: Post? {
        didSet {
            self.updateLikeCount = post?.likeCount ?? 0
            self.updateListCount = post?.listCount ?? 0
            self.updateCommentCount = post?.commentCount ?? 0
            updateButtons()
        }
    }
    
    var updateCommentCount: Int = 0 {
        didSet {
            self.updateButtons()
        }
    }
    var updateListCount: Int = 0 {
        didSet {
            self.updateButtons()
        }
    }
    var updateLikeCount: Int = 0 {
        didSet {
            self.updateButtons()
        }
    }

    
    lazy var likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(handleLike), for: .touchUpInside)
        return button
    }()
    
    lazy var commentButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(handleComment), for: .touchUpInside)
        return button
    }()

    
    lazy var bookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(handleBookmark), for: .touchUpInside)
        return button
    }()
    
    let likeButtonLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(name: "Poppins-Bold", size: 12)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.center
        label.isUserInteractionEnabled = true
        return label
    }()
    
    
    lazy var commentButtonLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(name: "Poppins-Bold", size: 12)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.center
        label.isUserInteractionEnabled = true
        return label
    }()
    
    lazy var bookmarkButtonLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(name: "Poppins-Bold", size: 12)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.center
        label.isUserInteractionEnabled = true
        return label
    }()
    

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        
        let likeView = UIView()
        likeView.layer.borderColor = UIColor.rgb(red: 221, green: 221, blue: 221).cgColor
        likeView.layer.borderWidth = 0
        likeView.backgroundColor = UIColor.white

        let commentView = UIView()
        commentView.layer.borderColor = UIColor.rgb(red: 221, green: 221, blue: 221).cgColor
        commentView.layer.borderWidth = 0
        commentView.backgroundColor = UIColor.white

        let bookmarkView = UIView()
        bookmarkView.layer.borderColor = UIColor.rgb(red: 221, green: 221, blue: 221).cgColor
        bookmarkView.layer.borderWidth = 0
        bookmarkView.backgroundColor = UIColor.white

        let actionStackView = UIStackView(arrangedSubviews: [likeView, commentView,bookmarkView])
        actionStackView.spacing = 5
        actionStackView.distribution = .fillEqually

        addSubview(actionStackView)
        actionStackView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 45)
        actionStackView.layer.applySketchShadow()
        actionStackView.backgroundColor = UIColor.white
        
        let likeContainer = UIView()
        let commentContainer = UIView()
        let listContainer = UIView()
        
    // LIKE BUTTON
        
        likeContainer.addSubview(likeButton)
        likeButton.anchor(top: likeContainer.topAnchor, left: likeContainer.leftAnchor, bottom: likeContainer.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        likeButton.addTarget(self, action: #selector(handleLike), for: .touchUpInside)
        
        likeContainer.addSubview(likeButtonLabel)
        likeButtonLabel.anchor(top: likeContainer.topAnchor, left: likeButton.rightAnchor, bottom: likeContainer.bottomAnchor, right: likeContainer.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        likeButtonLabel.centerYAnchor.constraint(equalTo: likeContainer.centerYAnchor).isActive = true
        likeButtonLabel.sizeToFit()
        likeButtonLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleLike)))
        
        addSubview(likeContainer)
        likeContainer.anchor(top: likeView.topAnchor, left: nil, bottom: likeView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        likeButtonLabel.leftAnchor.constraint(equalTo: likeView.centerXAnchor).isActive = true
        likeContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleLike)))
        
        
    // COMMENT BUTTON
        commentContainer.addSubview(commentButton)
        commentButton.anchor(top: commentContainer.topAnchor, left: commentContainer.leftAnchor, bottom: commentContainer.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        commentButton.widthAnchor.constraint(equalTo: commentButton.heightAnchor, multiplier: 1).isActive = true
        commentButton.centerYAnchor.constraint(equalTo: commentContainer.centerYAnchor).isActive = true
        
        commentContainer.addSubview(commentButtonLabel)
        commentButtonLabel.anchor(top: commentContainer.topAnchor, left: commentButton.rightAnchor, bottom: commentContainer.bottomAnchor, right: commentContainer.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        commentButtonLabel.centerYAnchor.constraint(equalTo: commentButton.centerYAnchor).isActive = true
        commentButtonLabel.sizeToFit()
        commentButtonLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleComment)))
        
        addSubview(commentContainer)
        commentContainer.anchor(top: commentView.topAnchor, left: nil, bottom: commentView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        commentContainer.centerXAnchor.constraint(equalTo: commentView.centerXAnchor).isActive = true
        commentContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleComment)))
        
    // TAG BUTTON
        listContainer.addSubview(bookmarkButton)
        bookmarkButton.anchor(top: listContainer.topAnchor, left: listContainer.leftAnchor, bottom: listContainer.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        bookmarkButton.widthAnchor.constraint(equalTo: bookmarkButton.heightAnchor, multiplier: 1).isActive = true
        bookmarkButton.layer.cornerRadius = bookmarkButton.bounds.size.width/2
        
        
        listContainer.addSubview(bookmarkButtonLabel)
        bookmarkButtonLabel.anchor(top: listContainer.topAnchor, left: bookmarkButton.rightAnchor, bottom: listContainer.bottomAnchor, right: listContainer.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        bookmarkButtonLabel.centerYAnchor.constraint(equalTo: bookmarkButton.centerYAnchor).isActive = true
        
        bookmarkButtonLabel.sizeToFit()
        bookmarkButtonLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleBookmark)))
        
        addSubview(listContainer)
        listContainer.anchor(top: bookmarkView.topAnchor, left: nil, bottom: bookmarkView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        bookmarkButtonLabel.leftAnchor.constraint(equalTo: bookmarkView.centerXAnchor).isActive = true
        listContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleBookmark)))
        
        
        let topDiv = UIView()
        addSubview(topDiv)
        topDiv.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
        topDiv.backgroundColor = UIColor.rgb(red: 221, green: 221, blue: 221)
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    }
    

extension BottomActionBar {
    
    @objc func handleLike(){
        if Auth.auth().currentUser == nil {
            self.delegate?.alert(title: "Invalid Action", message: "Please Sign In")
            return
        }
        
        if (self.post?.hasLiked)! {
            // Unselect Upvote
            self.post?.hasLiked = false
            self.post?.likeCount -= 1
        } else {
            // Upvote
            self.post?.hasLiked = true
            self.post?.likeCount += 1
        }
        
        
        var likeImage = (self.post?.hasLiked)! ? #imageLiteral(resourceName: "like_filled") : #imageLiteral(resourceName: "like_unfilled")
        self.likeButton.setImage(likeImage.withRenderingMode(.alwaysOriginal), for: .normal)
        self.likeButtonLabel.textColor = (self.post?.hasLiked)! ? UIColor.ianLegitColor() : UIColor.darkGray
        self.likeButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)

        self.layoutIfNeeded()
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.likeButton.transform = .identity
                        self?.likeButton.layoutIfNeeded()
                        
            },
                       completion: nil)
        
        
        self.delegate?.handleLike()
    }

    @objc func handleComment(){
        if Auth.auth().currentUser == nil {
            self.delegate?.alert(title: "Invalid Action", message: "Please Sign In")
            return
        }

        self.delegate?.handleComment()
    }

    @objc func handleBookmark(){
        if Auth.auth().currentUser == nil {
            self.delegate?.alert(title: "Invalid Action", message: "Please Sign In")
            return
        }

        self.delegate?.handleTagList()
    }
    

    func updateButtons(){
        guard let post = post else {return}

        var likeImage = (post.hasLiked) ? #imageLiteral(resourceName: "like_filled") : #imageLiteral(resourceName: "like_unfilled")
        self.likeButton.setImage(likeImage.withRenderingMode(.alwaysOriginal), for: .normal)
        self.likeButtonLabel.text = self.updateLikeCount != 0 ? String(self.updateLikeCount) + "  LEGIT" : " LEGIT"
        self.likeButtonLabel.sizeToFit()

//        let listIcon = #imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate)
        let listIcon = post.hasPinned ? #imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate)
        
        bookmarkButton.setImage(listIcon, for: .normal)
        bookmarkButton.tintColor = post.hasPinned ? UIColor.ianLegitColor() : UIColor.lightGray
        let listAddedString = post.hasPinned ? "LIST TAGGED" : "TAG LIST"
        self.bookmarkButtonLabel.text = self.updateListCount != 0 ? String(self.updateListCount) + "  LISTS" : listAddedString
        self.bookmarkButtonLabel.sizeToFit()
        
        commentButton.setImage(#imageLiteral(resourceName: "comment_icon_ian").withRenderingMode(.alwaysOriginal), for: .normal)
        self.commentButtonLabel.text = self.updateCommentCount != 0 ? String(self.updateCommentCount) + "  COMMENT" : " COMMENT"
        self.commentButtonLabel.sizeToFit()
    }
    
    
}




