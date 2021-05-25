//
//  CommentsController.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 9/2/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit

import MessageUI
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

protocol CommentsControllerDelegate {
    func refreshComments(comments:[Comment])
}

class CommentsController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, CommentCellDelegate, UITextViewDelegate {
    func didTapPost(post: Post?) {
        self.extTapPicture(post: post)
    }
    
    

    var post: Post?
    var delegate: CommentsControllerDelegate?
    let cellId = "cellId"
    
    let commentDefault = "Enter Comment"

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        setupNavigationItems()

        self.view.backgroundColor = UIColor.white
        collectionView?.backgroundColor = UIColor.backgroundGrayColor()
//        collectionView?.backgroundColor = UIColor.rgb(red: 249, green: 249, blue: 249)

        collectionView?.alwaysBounceVertical = true
        collectionView?.keyboardDismissMode = .interactive
        
        // Comment Input is height of 50
        collectionView?.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: -50, right: 0)
        collectionView?.scrollIndicatorInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: -50, right: 0)
        
        collectionView?.register(CommentCell.self, forCellWithReuseIdentifier: cellId)
        
        collectionView?.isUserInteractionEnabled = true
        collectionView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleBackPressNav))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        
        fetchComments()
    }
    
    func setupNavigationItems(){
        let navLabel = UILabel()
        let customFont = UIFont(name: "Poppins-Bold", size: 18)
        let headerTitle = NSAttributedString(string:"Comments", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: customFont])
        navLabel.attributedText = headerTitle
        self.navigationItem.titleView = navLabel
        
        // Nav Bar Buttons
//        let navShareButton = navShareButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//        navShareButton.addTarget(self, action: #selector(showMessagingOptionsNav), for: .touchUpInside)
//        let barButton1 = UIBarButtonItem.init(customView: navShareButton)
//        self.navigationItem.rightBarButtonItem = barButton1
        
        // Nav Back Buttons
        let navBackButton = navBackButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        navBackButton.addTarget(self, action: #selector(handleBackPressNav), for: .touchUpInside)
        navBackButton.backgroundColor = UIColor.clear
        let barButton2 = UIBarButtonItem.init(customView: navBackButton)
        self.navigationItem.leftBarButtonItem = barButton2
        self.navigationController?.navigationBar.tintColor = UIColor.ianLegitColor()
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationController?.navigationBar.backgroundColor = UIColor.clear
        self.navigationController?.navigationBar.isTranslucent = false

    }
    
    
    
    @objc func showMessagingOptionsNav(){
        guard let post = self.post else {return}
        self.showMessagingOptions(post: post)
    }
    
    @objc func handleBackPressNav(){
        guard let post = self.post else {return}
        self.handleBack()
    }
    

    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        self.commentTextField.resignFirstResponder()
    }
    
    var comments = [Comment]()
    
    func didTapCancel(comment: Comment) {
        print("Delete Comment from \(comment.user.username) | \(comment.text)")
        if let removeIndex = self.comments.firstIndex(where: { (comments) -> Bool in
            comments.commentId == comment.commentId
        }){
            self.comments.remove(at: removeIndex)
            self.collectionView.reloadData()
            
            // REMOVE First Comment which is the caption
            var tempComments = self.comments
            tempComments.remove(at: 0)
            self.delegate?.refreshComments(comments: tempComments)
            
            self.deleteComment(comment: comment)
        }
    
    }
    
    fileprivate func fetchComments() {
        
        // Insert Caption as First Comment
        var captionComment = Comment(key: "postCaption", user: (post?.user)!, dictionary: [:])
        captionComment.text = (post?.caption)!
        captionComment.creationDate = post?.creationDate ?? Date()
        self.comments = []
        self.comments.append(captionComment)

        guard let postId = self.post?.id else {return}

        Database.fetchCommentsForPostId(postId: postId) { (commentsFirebase) in
            self.comments += commentsFirebase
            self.collectionView?.reloadData()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return comments.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! CommentCell
        cell.comment = self.comments[indexPath.row]
        cell.delegate = self
        cell.backgroundColor = UIColor.rgb(red: 249, green: 249, blue: 249)
        cell.backgroundColor = UIColor.backgroundGrayColor()

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        let dummyCell = CommentCell(frame: frame)
        dummyCell.comment = comments[indexPath.item]
        dummyCell.layoutIfNeeded()
        
        let targetSize = CGSize(width: view.frame.width, height: 1000)
        let estimatedSize = dummyCell.systemLayoutSizeFitting(targetSize)
        
        let height = max(40 + 8+8, estimatedSize.height)
        
        return CGSize(width: view.frame.width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.commentTextField.becomeFirstResponder()
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.backgroundColor = UIColor.clear
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        tabBarController?.tabBar.isHidden = false
    }
    
//    lazy var containerView: UIView = {
//
//        let containerView = UIView()
//        containerView.backgroundColor = UIColor.white
//        containerView.frame = CGRect(x: 0, y: 0, width: 100, height: 50)
//
//        let submitButton = UIButton(type: .system)
//        submitButton.setTitle("Submit", for: .normal)
//        submitButton.setTitleColor(.black, for: .normal)
//        submitButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
//        submitButton.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
//
//
//        containerView.addSubview(submitButton)
//        submitButton.anchor(top: containerView.topAnchor, left: nil, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 12, width: 50, height: 0)
//
//
//        containerView.addSubview(self.commentTextField)
//        self.commentTextField.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: submitButton.leftAnchor, paddingTop: 0, paddingLeft: 12, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        self.commentTextField.delegate = self
//
//        let lineSeparatorView = UIView()
//        lineSeparatorView.backgroundColor = UIColor.rgb(red: 230, green: 230, blue: 230)
//        containerView.addSubview(lineSeparatorView)
//        lineSeparatorView.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: nil, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
//
//        return containerView
//
//    }()
    
    lazy var newContainerView: UIView = {
        
        let containerView = UIView()
        containerView.backgroundColor = UIColor.clear
        containerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 170)
        
        
        let commentContainer = UIView()
        commentContainer.backgroundColor = UIColor.white
        commentContainer.layer.cornerRadius = 2
        commentContainer.layer.borderColor = UIColor.rgb(red: 221, green: 221, blue: 221).cgColor
        commentContainer.layer.borderWidth = 1
        containerView.addSubview(commentContainer)
        commentContainer.anchor(top: nil, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 20, paddingRight: 10, width: 0, height: 150)

    // BOTTOM DETAIL
        
        let detailView = UIView()
        detailView.backgroundColor = UIColor.clear
        containerView.addSubview(detailView)
        detailView.anchor(top: nil, left: commentContainer.leftAnchor, bottom: commentContainer.bottomAnchor, right: commentContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)


        let submitButton = UIButton(type: .system)
        submitButton.setTitle("SUBMIT", for: .normal)
        submitButton.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        submitButton.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 12)
        submitButton.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
        
        containerView.addSubview(submitButton)
        submitButton.anchor(top: nil, left: nil, bottom: nil, right: detailView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        submitButton.centerYAnchor.constraint(equalTo: detailView.centerYAnchor).isActive = true
        
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("CANCEL", for: .normal)
        cancelButton.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        cancelButton.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 12)
        cancelButton.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        
        containerView.addSubview(cancelButton)
        cancelButton.anchor(top: nil, left: nil, bottom: nil, right: submitButton.leftAnchor, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        cancelButton.centerYAnchor.constraint(equalTo: detailView.centerYAnchor).isActive = true
        
        let clearButton = UIButton(type: .system)
        clearButton.setTitle("CLEAR", for: .normal)
        clearButton.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        clearButton.titleLabel?.font = UIFont(name: "Poppins-Medium", size: 11)
        clearButton.addTarget(self, action: #selector(handleClear), for: .touchUpInside)
        
        containerView.addSubview(clearButton)
        clearButton.anchor(top: nil, left: detailView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        clearButton.centerYAnchor.constraint(equalTo: detailView.centerYAnchor).isActive = true
        
// DIVIDER
        let divider = UIView()
        divider.backgroundColor = UIColor.rgb(red: 221, green: 221, blue: 221)
        containerView.addSubview(divider)
        divider.anchor(top: nil, left: commentContainer.leftAnchor, bottom: detailView.topAnchor, right: commentContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
        
// COMMENT TEXT FIELD
        containerView.addSubview(self.commentTextField)
        self.commentTextField.anchor(top: commentContainer.topAnchor, left: commentContainer.leftAnchor, bottom: divider.topAnchor, right: commentContainer.rightAnchor, paddingTop: 10, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        self.commentTextField.delegate = self
        self.automaticallyAdjustsScrollViewInsets = false
        self.resetCaptionTextView()

//        self.commentTextField.backgroundColor = UIColor.yellow
        
        
        
//        let lineSeparatorView = UIView()
//        lineSeparatorView.backgroundColor = UIColor.rgb(red: 230, green: 230, blue: 230)
//        containerView.addSubview(lineS    eparatorView)
//        lineSeparatorView.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: nil, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        return containerView
        
    }()
    
    @objc func handleClear(){
        self.commentTextField.text = nil
    }
    
    @objc func handleCancel(){
        self.commentTextField.resignFirstResponder()
    }
    
//    let commentTextField: UITextField = {
//
//        let textField = UITextField()
//        textField.placeholder = "Enter Comment"
//        textField.returnKeyType = UIReturnKeyType.done
//        textField.keyboardType = UIKeyboardType.default
//        return textField
//
//    }()
    
    
    let commentTextField: UITextView = {
        
        let textView = UITextView()
        textView.text = "Enter Comment"
        textView.returnKeyType = UIReturnKeyType.done
        textView.keyboardType = UIKeyboardType.default
        textView.font = UIFont.systemFont(ofSize: 14)
        return textView
        
    }()
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        // Clears Out Default Caption
        if textView.text == commentDefault {
            textView.text = nil
        }
        textView.textColor = UIColor.black
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        textView.resignFirstResponder()
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == commentTextField {
            if textView.text.isEmpty {
                self.resetCaptionTextView()
            }
        }
    }
    
    func resetCaptionTextView() {
        self.commentTextField.text = commentDefault
        self.commentTextField.textColor = UIColor.lightGray
    }
    
    
    func deleteComment(comment: Comment?) {
        guard let comment = comment else {
            print("Delete Comment ERROR | No Comment ID")
            return
        }
        
        if comment.user.uid != Auth.auth().currentUser?.uid  {
            print("Delete Comment ERROR | Not Comment Creator")
            return
        }
        
        let commentId = comment.commentId
        let postId = self.post?.id ?? ""
        print("CommentsController | deleteComment | Deleted | \(commentId) from \(comment.user.username) | \(comment.text) | \(postId)")
        Database.database().reference().child("comments").child(postId).child(commentId).removeValue()
    }
    
    
    @objc func handleSubmit() {
        print("submit comment:", commentTextField.text ?? "")

        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        if (Auth.auth().currentUser?.isAnonymous)! {
            
            let message = "Please Sign Up to Comment"
            let alert = UIAlertController(title: "Guest Profile", message: message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            alert.addAction(UIAlertAction(title: "Sign Up", style: UIAlertAction.Style.cancel, handler: { (action: UIAlertAction!) in
                
                DispatchQueue.main.async {
                    let signUpController = SignUpController()
                    let navController = UINavigationController(rootViewController: signUpController)
                    self.present(navController, animated: true, completion: nil)
                }
            }))
            
            self.present(alert, animated: true, completion: nil)
            print("Guest User. Don't Save Likes")
            return
        }
        let postId = self.post?.id ?? ""
        let values = ["text": commentTextField.text ?? "", "creationDate": Date().timeIntervalSince1970, "uid": uid] as [String:Any]
        
        commentTextField.text?.removeAll()
        let commentID = NSUUID().uuidString
        var newComment = Comment.init(key: commentID, user: (CurrentUser.user ?? nil)!, dictionary: values)
        self.comments.append(newComment)
        var tempComments = self.comments
        tempComments.remove(at: 0)
        self.delegate?.refreshComments(comments: tempComments)

//        self.delegate?.refreshComments(comments: [tempComments.removeLast()])
        self.collectionView.reloadData()
        self.commentTextField.resignFirstResponder()
        
        // SCROLL TO BOTTOM
        let item = collectionView.numberOfItems(inSection: 0) - 1
        let lastIndexPath = IndexPath(item: item, section: 0)
        collectionView.scrollToItem(at: lastIndexPath, at: .bottom, animated: true)
        
        
        Database.database().reference().child("comments").child(postId).child(commentID).updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Failed to insert comment:", err)
                return
            }
                Database.createPostEvent(postId: postId, creatorUid: uid, action: Social.comment, value: 1)
                print("Successfully saved comment:")
        }
        
    }
    
    
    override var inputAccessoryView: UIView?{
        get {
            return newContainerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
}
