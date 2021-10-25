//
//  MessageController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/24/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import mailgun
import Messages
import MessageUI
import CoreImage
import CoreLocation
import SVProgressHUD

protocol MessageControllerDelegate {
    func refreshPost(post:Post)
}

class MessageController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UITextViewDelegate , UITableViewDelegate, UITableViewDataSource, MFMessageComposeViewControllerDelegate, PostSummaryCellViewDelegate{
    
    func didTapPost(post: Post?) {
        self.extTapPicture(post: post)
    }
    
    
    
    func sendMessage(_ sender: Any) {
        let messageVC = MFMessageComposeViewController()
        
        messageVC.body = "Enter a message";
        messageVC.recipients = ["Enter tel-nr"]
        messageVC.messageComposeDelegate = self
        
        self.present(messageVC, animated: true, completion: nil)
    }
    
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch (result) {
        case .cancelled:
            print("Message was cancelled")
            dismiss(animated: true, completion: nil)
        case .failed:
            print("Message failed")
            dismiss(animated: true, completion: nil)
        case .sent:
            print("Message was sent")
            dismiss(animated: true, completion: nil)
        default:
            break
        }
    }
    
    
    var delegate: MessageControllerDelegate?
    let bookmarkCellId = "bookmarkCellId2"
    let postDisplayHeight = 150 as CGFloat
    
    var post: Post? {
        didSet {
            self.refreshHeader()
        }
    }
    
    func refreshHeader() {
        let showPost = post != nil
        showHeaderPostHeight?.isActive = showPost
        hideHeaderPostHeight?.isActive = !showPost
        
//        if showPost {
//            print("MessageController | Refresh Header | Show Post \(post?.id)")
//        } else {
//            print("MessageController | Refresh Header | No Post")
//        }
//
//        collectionView.collectionViewLayout.invalidateLayout()
//        collectionView.reloadData()
//        collectionView.sizeToFit()
        
        postView.post = post
        
        self.view.layoutIfNeeded()
    }
    
    var activeField: UITextField?
    
    lazy var collectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.collectionViewLayout.invalidateLayout()
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
//        cv.layer.borderWidth = 0.5
//        cv.layer.borderColor = UIColor.black.cgColor
        return cv
    }()
    
    var showHeaderPostHeight: NSLayoutConstraint?
    var hideHeaderPostHeight: NSLayoutConstraint?

    lazy var fromRow: UIView = {
        let uv = UIView()
        uv.layer.borderWidth = 1
        uv.layer.borderColor = UIColor.init(red:222/255.0, green:225/255.0, blue:227/255.0, alpha: 1.0).cgColor
        return uv
    }()
    
    lazy var fromLabel: UILabel = {
        let ul = UILabel()
        ul.text = "From: "
        ul.font = UIFont.boldSystemFont(ofSize: 16.0)
        return ul
    }()
    
    lazy var fromInput: PaddedTextField = {
        let tf = PaddedTextField()
        tf.font = UIFont.systemFont(ofSize: 14.0)
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.gray.cgColor
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.layer.cornerRadius = 10
        tf.layer.masksToBounds = true
        tf.delegate = self
        return tf
    }()
    
    lazy var toRow: UIView = {
        let uv = UIView()
        
        uv.layer.borderWidth = 0
        uv.layer.borderColor = UIColor.init(red:222/255.0, green:225/255.0, blue:227/255.0, alpha: 1.0).cgColor
        return uv
    }()
    
    lazy var toLabel: UILabel = {
        let ul = UILabel()
        ul.text = "To: "
        ul.font = UIFont.boldSystemFont(ofSize: 16.0)
        return ul
    }()
    
    lazy var toInput: PaddedTextField = {
        let tf = PaddedTextField()
        tf.font = UIFont.systemFont(ofSize: 14.0)
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.gray.cgColor
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.layer.cornerRadius = 10
        tf.layer.masksToBounds = true
        tf.delegate = self
//        
//        let indentView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 20))
//        tf.leftView = indentView
//        tf.leftViewMode = .always
//
//        tf.inlineMode = true
//        tf.startFilteringAfter = "@"
//        tf.startSuggestingInmediately = true
//        tf.filterStrings(["gmail.com", "yahoo.com", "yahoo.com.ar"])
        
        return tf
    }()
    
    lazy var messageLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Message: "
        ul.font = UIFont.boldSystemFont(ofSize: 16.0)
        return ul
    }()
    
    lazy var messageInput: UITextView = {
        let tf = UITextView()
        tf.font = UIFont.systemFont(ofSize: 14.0)
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.gray.cgColor
        tf.layer.cornerRadius = 10
        return tf
    }()
    
    // EmojiAutoComplete
    var userAutoComplete: UITableView!
    let UserAutoCompleteCellId = "UserAutoCompleteCellId"
    var followingUsers:[User] = []
    var filteredUsers:[User] = []
    var isAutocomplete: Bool = false
    
    var sentUsers: [String: String] = [:]
    
    var respondMessage: MessageThread? = nil{
        didSet {
            guard let respondMessage = respondMessage else {return}
            var toText = ""
            for username in respondMessage.threadUsers {
                if username != CurrentUser.username {
                    toText += (toText == "" ) ? "\(username)" : ", \(username)"
                }
            }
            self.toInput.text = toText
        }
    }
    
    var respondUser: [User] = []{
        didSet {
            var toText = ""
            for user in respondUser {
                toText += (toText == "" ) ? "\(user.username)" : ", \(user.username)"
            }
            self.toInput.text = toText
        }
    }
    
    // POST
    var postContainer = UIView()
    var postView = PostSummaryCellView()
//    let postDisplayHeight: CGFloat = 90
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        view.backgroundColor  = .white
        self.automaticallyAdjustsScrollViewInsets  = false
        
//        collectionView.backgroundColor = .white
//        collectionView.register(ListPhotoCell.self, forCellWithReuseIdentifier: bookmarkCellId)
//
//        view.addSubview(collectionView)
//        collectionView.anchor(top: topLayoutGuide.bottomAnchor , left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        showHeaderPostHeight = collectionView.heightAnchor.constraint(equalToConstant: postDisplayHeight)
//        hideHeaderPostHeight = collectionView.heightAnchor.constraint(equalToConstant: 0)
//
        view.addSubview(postContainer)
        postContainer.anchor(top: topLayoutGuide.bottomAnchor , left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        showHeaderPostHeight = postContainer.heightAnchor.constraint(equalToConstant: postDisplayHeight)
        hideHeaderPostHeight = postContainer.heightAnchor.constraint(equalToConstant: 0)
        
        postContainer.addSubview(postView)
        postView.anchor(top: postContainer.topAnchor, left: postContainer.leftAnchor, bottom: postContainer.bottomAnchor, right: postContainer.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        postView.delegate = self
        postView.layer.borderColor = UIColor.lightGray.cgColor
        
        
        refreshHeader()
        
//        view.addSubview(fromRow)
//        view.addSubview(fromLabel)
//        view.addSubview(fromInput)

        view.addSubview(toRow)
        view.addSubview(toLabel)
        view.addSubview(toInput)
        
        view.addSubview(messageLabel)
        view.addSubview(messageInput)
        
        toRow.anchor(top: postContainer.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 2, paddingLeft: 2, paddingBottom: 0, paddingRight: 2, width: 0, height: 50)
        
        toLabel.anchor(top: toRow.topAnchor, left: toRow.leftAnchor, bottom: toRow.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 0, width: 60, height: 0)
        
        toInput.anchor(top: toRow.topAnchor, left: toLabel.rightAnchor, bottom: toRow.bottomAnchor, right: toRow.rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        
        
//        fromRow.anchor(top: toRow.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 2, paddingLeft: 2, paddingBottom: 0, paddingRight: 2, width: 0, height: 50)
//
//        fromLabel.anchor(top: fromRow.topAnchor, left: fromRow.leftAnchor, bottom: fromRow.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 0, width: 60, height: 0)
//
//        fromInput.anchor(top: fromRow.topAnchor, left: fromLabel.rightAnchor, bottom: fromRow.bottomAnchor, right: fromRow.rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
//
        
        messageLabel.anchor(top: toRow.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 30)
        
        messageInput.anchor(top: messageLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 150)
        
        print(CurrentUser.username)
        fromInput.text = CurrentUser.username
        
        fromInput.tag = 0
        toInput.tag = 1
        messageInput.tag = 2
        
        fromInput.delegate = self
        toInput.delegate = self
        messageInput.delegate = self
        
        toInput.placeholder = "@username, user@gmail.com"
        toInput.addTarget(self, action: #selector(textFieldDidChange(_:)), for: UIControl.Event.editingChanged)

        
        fromRow.isUserInteractionEnabled = true
        fromRow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
        toRow.isUserInteractionEnabled = true
        toRow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
        messageLabel.isUserInteractionEnabled = true
        messageLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        swipeUp.direction = .up
        self.view.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
        
        
        
        setupNavigationButtons()
        
        // User Auto Complete
        
        setupUserAutoComplete()
        view.addSubview(userAutoComplete)
        userAutoComplete.anchor(top: toRow.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        userAutoComplete.isHidden = true
        
        fetchFollowingUsers()
        
        if post != nil {
            var msgText = "Check out the food here!"
            if self.respondUser.count == 0 {
                // Dont show from user if its email
                msgText += "\nFrom \((CurrentUser.username)!)! "
            }
            messageInput.text = msgText
//            messageInput.text = "Check out the food here! \nFrom \((CurrentUser.username)!)! "
        } else if post == nil {
            messageInput.text = ""
        }
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        // Keyboard Setups to Dismiss Keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
//        self.toInput.becomeFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.toInput.becomeFirstResponder()
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)

    }
    
    
    fileprivate func setupNavigationButtons() {
        let navLabel = UILabel()
        let customFont = UIFont(name: "Poppins-Bold", size: 18)
        let headerTitle = NSAttributedString(string:"", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: customFont])
        navLabel.attributedText = headerTitle
        self.navigationItem.titleView = navLabel
        
        // Nav Bar Buttons
        let navShareButton = navShareButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        let navMsgTitle = NSAttributedString(string: " Message ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 12)])
        navShareButton.setAttributedTitle(navMsgTitle, for: .normal)
        let shareIcon = #imageLiteral(resourceName: "message_fill").withRenderingMode(.alwaysTemplate)
        navShareButton.setImage(shareIcon, for: .normal)
        navShareButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        navShareButton.backgroundColor = UIColor.clear
        navShareButton.setTitleColor(UIColor.ianBlackColor(), for: .normal)
        let barButton1 = UIBarButtonItem.init(customView: navShareButton)
        self.navigationItem.rightBarButtonItem = barButton1
        
        // Nav Back Buttons
        let navBackButton = navBackButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        navBackButton.addTarget(self, action: #selector(handleBackPressNav), for: .touchUpInside)
        navBackButton.backgroundColor = UIColor.clear
        navBackButton.setTitleColor(UIColor.ianBlackColor(), for: .normal)
        let backIcon = #imageLiteral(resourceName: "back_icon").withRenderingMode(.alwaysTemplate)
        navBackButton.setImage(backIcon, for: .normal)

        let barButton2 = UIBarButtonItem.init(customView: navBackButton)
        self.navigationItem.leftBarButtonItem = barButton2
        
        self.navigationController?.navigationBar.tintColor = UIColor.ianLegitColor()
        
        
        
//        navigationItem.title = "Message"
//        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .plain, target: self, action: #selector(handleSend))
    }

    @objc func handleBackPressNav(){
//        guard let post = self.post else {return}
        self.handleBack()
    }
    
    // Keyboard Adjustments
    
    var adjusted: Bool = false
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @objc func keyboardWillShow(_ notification: NSNotification) {
//        if !self.adjusted {
//            self.view.frame.origin.y -= postDisplayHeight
//            self.adjusted = true
//        }
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification) {
//        if self.adjusted {
//            self.view.frame.origin.y += postDisplayHeight
//            self.adjusted = false
//        }
        self.userAutoComplete.isHidden = true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField){
        if textField == toInput {
            guard let tempCaptionWords = textField.text?.components(separatedBy: " ") else {return}
            var lastWord = tempCaptionWords[tempCaptionWords.endIndex - 1]
            self.filterUsersForText(inputString: lastWord)
        }
    }

    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        if textField == toInput {
//            guard let tempCaptionWords = textField.text?.components(separatedBy: " ") else {return true}
//            var lastWord = tempCaptionWords[tempCaptionWords.endIndex - 1]
//            self.filterUsersForText(inputString: lastWord)
//        }
        return true
    }
    
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
        textField.keyboardType = UIKeyboardType.twitter
//
//        var adjustment = textField.convert(textField.frame.origin, to: self.view).y - (self.navigationController?.navigationBar.frame.height)!
//        self.view.frame.origin.y +=  adjustment
//
//        print("Adjustment is \(adjustment)")
        return true
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Try to find next responder
        
        if textField == fromInput {
            toInput.becomeFirstResponder()
        } else if textField == toInput {
            // This calls the autocomplete function for searchtextfield. Just a workaround. Doesn't work wiht multiple @s
//            toInput.textFieldDidEndEditingOnExit()
            self.checkToText(inputString: self.toInput.text, completion: { (fetchedSentUsers) in
                self.sentUsers = fetchedSentUsers
            })
            messageInput.becomeFirstResponder()
            self.userAutoComplete.isHidden = true
            
        } else {
            textField.resignFirstResponder()
        }

        // Do not add a line break
        return false
    }
    
// User Autocomplete Functions
    
    func setupUserAutoComplete(){
        
        // User Autocomplete View
        userAutoComplete = UITableView()
        userAutoComplete.register(UserAndListCell.self, forCellReuseIdentifier: UserAutoCompleteCellId)
        userAutoComplete.delegate = self
        userAutoComplete.dataSource = self
        userAutoComplete.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
        userAutoComplete.backgroundColor = UIColor.white
        userAutoComplete.estimatedRowHeight = 100
    }
    
    func fetchFollowingUsers() {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        if CurrentUser.followingUids.count == 0 {
            Database.fetchFollowingUserUids(uid: uid) { (fetchedFollowingUsers) in
                CurrentUser.followingUids = fetchedFollowingUsers
                self.FirebaseFetchUsers()
            }
        } else {
            self.FirebaseFetchUsers()
        }
    }
    
    func FirebaseFetchUsers(){
        for uid in CurrentUser.followingUids {
            Database.fetchUserWithUID(uid: uid, completion: { (user) in
                guard let user = user else {return}

                    self.followingUsers.append(user)
            })
        }
    }
    
    func filterUsersForText(inputString: String){
        filteredUsers = followingUsers.filter({( user : User) -> Bool in
            return user.username.lowercased().contains(inputString.lowercased())
        })
        
        // Show only if filtered users not 0
        if filteredUsers.count > 0 {
            self.userAutoComplete.isHidden = false
        } else {
            self.userAutoComplete.isHidden = true
        }
        
        // Sort results based on prefix
        filteredUsers.sort { (p1, p2) -> Bool in
            ((p1.username.hasPrefix(inputString)) ? 0 : 1) < ((p2.username.hasPrefix(inputString)) ? 0 : 1)
        }
        self.userAutoComplete.reloadData()
    }
    
    
    // Tableview delegate functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UserAutoCompleteCellId, for: indexPath) as! UserAndListCell
        cell.user = filteredUsers[indexPath.row]
        cell.followButton.isHidden = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var userSelected = filteredUsers[indexPath.row]
        var selectedUsername = userSelected.username
        var addedString : String?
        addedString = selectedUsername
        
        guard var tempCaptionWords = self.toInput.text?.lowercased().components(separatedBy: " ") else {
            self.toInput.text = (addedString)! + ", "
            return
        }
        
        var lastWord = tempCaptionWords[tempCaptionWords.endIndex - 1]
//        self.toInput.text = tempCaptionWords.dropLast().joined(separator: " ") + (addedString)! + ", "
        // Only 1 receiver
        self.toInput.text = addedString
        self.userAutoComplete.isHidden = true

    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    
// CollectionView Delegate Functions
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            
        if let post = self.post {
            return CGSize(width: view.frame.width, height: postDisplayHeight)
        } else {
            return CGSize(width: view.frame.width, height: 0)
        }
        
        }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let post = self.post {
            return 1
        } else {
            return 0
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        

            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: bookmarkCellId, for: indexPath) as! ListPhotoCell
            cell.post = post
            return cell
     
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func handleSendToUsers(sentUsers: [String: String]){
        // Split Sent Users to email/uids
        var receiveUserUid: [String: String] = [:]
        var receiveUserEmail: [String: String] = [:]
        
        for (key,value) in sentUsers {
            if key.isValidEmail && value == "email" {
                receiveUserEmail[key] = value
            } else {
                receiveUserUid[key] = value
            }
        }
                
        // Send Emails
        if receiveUserEmail.count > 0 {
            print("Trying to send emails for emails: \(receiveUserEmail)")
            for (key,value) in receiveUserEmail {
                self.handleSendEmail(email: key)
            }
        }
        
        // Send Messages
        if receiveUserUid.count > 0 {
            print("Trying to send msgs: \(receiveUserUid.count) | \(receiveUserUid)")
            self.handleSendMessage(sentUsers: receiveUserUid)
        }

        print("Sent Msg | \(receiveUserUid.count) Users | \(receiveUserEmail.count) Emails")
        SVProgressHUD.showSuccess(withStatus: "Message Sent")
        SVProgressHUD.dismiss(withDelay: 1)
//        self.navigationController?.popViewController(animated: true)
        self.navigationController?.popToRootViewController(animated: true)
//        self.dismiss(animated: true) {
//        }
    }
        
        

    
    func handleSendMessage(sentUsers: [String: String]){
        
        guard let toText = toInput.text else {return}
        guard let creatorUID = Auth.auth().currentUser?.uid else {return}
        guard let creatorUsername = CurrentUser.username else {return}
        let postId = self.post?.id
        guard let message = self.messageInput.text else {return}

        var allUsers = sentUsers
        if allUsers[creatorUID] == nil {
            allUsers[creatorUID] = creatorUsername
        }
        
        
        var tempUids = allUsers.map {String($0.key)}
        if tempUids.count <= 1 {
            print("handleSendMessage | ERROR | No Users | \(tempUids)")
            return
        }
        
        
        // FIND THREAD FIRST
        Database.findMessageThread(userUids: tempUids.sorted()) { (thread) in
            if thread == nil {
                // NO FOUND THREAD. CREATE NEW THREAD
                Database.createMessageThread(users: allUsers) { (newThread) in
                    let newThreadId = newThread.threadID
                    Database.createMessageForThread(messageThread: newThread, creatorUid: creatorUID, postId: postId, messageText: message)
                }
            } else {
                // FOUND THREAD. CREATE NEW MSG
                guard let foundThreadId = thread?.threadID else {return}
                Database.createMessageForThread(messageThread: thread, creatorUid: creatorUID, postId: postId, messageText: message)
            }
        }
    }
    
    func handleSendTest(sentUsers: [String: String]){
        
        guard let toText = toInput.text else {return}
        guard let creatorUID = Auth.auth().currentUser?.uid else {return}
        guard let creatorUsername = CurrentUser.username else {return}
        let postId = self.post?.id
        guard let message = self.messageInput.text else {return}
        let postCreationDate = self.post?.creationDate.timeIntervalSince1970
        let uploadTime = Date().timeIntervalSince1970
        let descTime = Date()

        var receiveUserUid: [String: String] = [:]
        var receiveUserEmail: [String: String] = [:]
        
        //Disable Message Button to avoid dup presses
        navigationItem.rightBarButtonItem?.isEnabled = false
        

            // Split Sent Users to email/uids
            for (key,value) in sentUsers {
                if key.isValidEmail {
                    receiveUserEmail[key] = value
                } else {
                    receiveUserUid[key] = value
                }
            }
            
            print("Sent Targets Emails: \(receiveUserEmail), Uids: \(receiveUserUid)")
        
        // Save and create Message Thread
        
            let messageThreadRef = Database.database().reference().child("messageThreads").childByAutoId()
            let values = ["postUID": postId, "creatorUID": creatorUID, "creatorUsername": creatorUsername, "sentMessage": message, "creationDate": uploadTime, "sentTo": toText] as [String:Any]
        
            messageThreadRef.updateChildValues(values, withCompletionBlock: { (err, ref) in
                
                if let err = err {
                    print("Failed to Save Message to DB", err)
                }
                
                // Success Creating Message Thread
                guard let threadKey = messageThreadRef.key else {
                    print("No Message Thread Key Error | ", messageThreadRef.key)
                    return
                    
                }

//                var threadKey = messageThreadRef.key
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                
                print("Successfully Created Message Thread \(threadKey) in Database")

                if let postId = self.post?.id {
                    // Update Post_Messages
                    let messageRef = Database.database().reference().child("post_messages").child(postId)
                    messageRef.runTransactionBlock({ (currentData) -> TransactionResult in
                        
                        var post = currentData.value as? [String : AnyObject] ?? [:]
                        var count = post["messageCount"] as? Int ?? 0
                        var threads = post["threads"] as? [String : Any] ?? [:]
                        var postDate = post["creationDate"] as? Double ?? 0
                        
                        count = max(0, count + 1)
                        threads[threadKey] = creatorUID
                        
                        // Update Message Thread Counts
                        post["messageCount"] = count as AnyObject?
                        post["threads"] = threads as AnyObject?
                        
                        // Handle/Update Post Creation Date
                        if let postCreationDate = postCreationDate {
                            if postDate != postCreationDate {
                                postDate = postCreationDate
                            }
                        }
                        
                        // Enables firebase sort by count and recent upload time
                        let  sortTime = uploadTime/1000000000000000
                        post["sort"] = (Double(count) + sortTime) as AnyObject
                        
                        currentData.value = post
                        print("Update Message Count for post : \(postId) to \(count)")
                        return TransactionResult.success(withValue: currentData)
                    
                    }) { (error, committed, snapshot) in
                        if let error = error {
                            print("Failed to Update Message Thread Count Error: ", postId, error.localizedDescription)
                        }
                    }
                }
    
                // Send Emails
                if receiveUserEmail.count > 0 {
                    print("Trying to send emails for emails: \(receiveUserEmail)")
                    Database.addMessageEmail(creatorUid: creatorUID, sentUsers: receiveUserEmail.map{$0.key}, postId: postId, messageText: message)
                    for (key,value) in receiveUserEmail {
                        self.handleSendEmail(email: key)
                    }
                }

                // Send User Message
                if receiveUserUid.count > 0 {
                    print("Trying to send messages for user uids: \(receiveUserUid)")
                    Database.updateMessageThread(threadKey: threadKey, creatorUid: creatorUID, creatorUsername: creatorUsername, receiveUid: receiveUserUid, message: message)
                }
                
                self.post?.hasMessaged = true
                self.post?.messageCount += 1
                self.delegate?.refreshPost(post: self.post!)
                
//                self.navigationController?.popViewController(animated: true)
                self.navigationController?.popToRootViewController(animated: true)

            })
        
    }
    
    func checkToText(inputString: String?, completion: @escaping ([String:String]) -> ()){
        guard let inputString = inputString else {return}
        let toArray = inputString.components(separatedBy: ",")
        let checkGroup = DispatchGroup()
        var sentArray: [String: String] = [:]
        
        print("Checking To Field for Array: \(toArray)")
        
        checkGroup.enter()
        for text in toArray {
            
            // Remove white spaces and lower case everything
            var tempText = text
            print("Searching for: \(tempText)")
            
            tempText = tempText.removingWhitespaces()
//            tempText = tempText.lowercased()
            
            // Check is blank
            if tempText.isEmptyOrWhitespace(){
                print("Empty Space So Ignore")
                continue
            } else {
                checkGroup.enter()
            }
            
            // Check if email
            if tempText.isValidEmail {
                sentArray[tempText] = "email"
                print("Email Found for \(tempText)")
                checkGroup.leave()

            } else {
                // Check if is a user
                Database.fetchUserWithUsername(username: tempText, completion: { (fetchedUser, error) in
                    var user: User?
                    var userId: String!
                    
                    if let error = error {
                        print("Error finding user for \(tempText): \(error)")
                        self.alert(title: "Error Message Receipient", message: "No user or email was found for \(tempText)")
                        return
                    }
                    
                    if let user = fetchedUser {
                        userId = user.uid
                        print("User Found for \(tempText): \(userId!)")
                        sentArray[userId!] = tempText
                        checkGroup.leave()
                    }
                    
                    else {
                        print("No user was found for \(tempText)")
                        self.alert(title: "Error Message Receipient", message: "No user or email was found for \(tempText)")
                        return
                    }
                })
            }
        }
        checkGroup.leave()
        
        checkGroup.notify(queue: .main) {
            print("Final Sent Array: \(sentArray)")
            completion(sentArray)
        }
    }
    
    
    let activeConversation = MSConversation()
    let messageComposer = MFMessageComposeViewController()

    func handleIMessage(){
        
//        if (messageComposer.canSendText()) {
//            // Obtain a configured MFMessageComposeViewController
//            let messageComposeVC = messageComposer.configuredMessageComposeViewController()
//
//            // Present the configured MFMessageComposeViewController instance
//            // Note that the dismissal of the VC will be handled by the messageComposer instance,
//            // since it implements the appropriate delegate call-back
//            self.present(messageComposeVC, animated: true, completion: nil)
//        } else {
//            // Let the user know if his/her device isn't able to send text messages
//            let errorAlert = UIAlertView(title: "Cannot Send Text Message", message: "Your device is not able to send text messages.", delegate: self, cancelButtonTitle: "OK")
//            errorAlert.show()
//        }
        if MFMessageComposeViewController.canSendText() == true {
            let recipients:[String] = ["1500"]
            let messageController = MFMessageComposeViewController()
            messageController.messageComposeDelegate = self
            
            guard let post = post else {return}
            guard let coord = post.locationGPS?.coordinate else {return}
            let url = "http://maps.apple.com/maps?saddr=\(coord.latitude),\(coord.longitude)"
            let convoString = post.emoji + " " + post.locationName + "\n " + post.locationAdress + "\n"
            
            messageController.messageComposeDelegate  = self
            messageController.recipients = recipients
            messageController.body = convoString
            messageController.addAttachmentURL(URL(string: url)!, withAlternateFilename: "Map")
            
            let sentImageUrl = self.post?.imageUrls[0] ?? ""
            if let image = imageCache[sentImageUrl] {
                let png = image.pngData()
                messageController.addAttachmentData(png!, typeIdentifier: "public.png", filename: "image.png")
                //            layout.image = image
            }
//            let url = URL(fileURLWithPath: sentImageUrl)
//
//            messageController.addAttachmentURL(url, withAlternateFilename: "Test")
            messageController.addAttachmentURL(self.locationVCardURLFromCoordinate(coordinate: CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude))! as URL, withAlternateFilename: "vCard.loc.vcf")

                messageController.addAttachmentURL(URL(string: url)!, withAlternateFilename: nil)
            
            
            self.present(messageController, animated: true, completion: nil)
            print("IMessage")
        } else {
            self.alert(title: "ERROR", message: "Text Not Supported")
        }

        
        
//        let session = MSSession()
//        let message = MSMessage(session: session)
//        let conversation = self.activeConversation
//        let components = URLComponents()
//
//        let layout = MSMessageTemplateLayout()
//
//
//
//        message.layout = layout
//        message.url = URL(fileURLWithPath: sentImageUrl)
//
//        conversation.insert(message) { (error) in
//            if let error = error {
//                print(error)
//            }
//        }
//
//        guard let post = post else {return}
//
//
//
//
//            + " \n " + post.locationAdress + "\n" + post.user.username + " " + post.caption +  "\n" + "Message From " + fromInput.text! + "\n" + messageInput.text

//        conversation.insertText(convoString) { (error) in
//            if let error = error {
//                print(error)
//            }
//        }
//
        //conversation.insert(message, completionHandler: nil)
        //conversation.insertText("We are at:\n" + addressLabel, completionHandler: nil)
        
//        conversation.send(message, completionHandler: nil)
//        conversation.sendText("We are at:\n" + addressLabel, completionHandler: nil)
    }
    
    
    func locationVCardURLFromCoordinate(coordinate: CLLocationCoordinate2D) -> NSURL?
    {
        guard let cachesPathString = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
            print("Error: couldn't find the caches directory.")
            return nil
        }
        
        guard CLLocationCoordinate2DIsValid(coordinate) else {
            print("Error: the supplied coordinate, \(coordinate), is not valid.")
            return nil
        }
        
        let vCardString = [
            "BEGIN:VCARD",
            "VERSION:3.0",
            "N:;Shared Location;;;",
            "FN:Shared Location",
            "item1.URL;type=pref:http://maps.apple.com/?ll=\(coordinate.latitude),\(coordinate.longitude)",
            "item1.X-ABLabel:map url",
            "END:VCARD"
            ].joined(separator: "/n")
        
        let vCardFilePath = (cachesPathString as NSString).appendingPathComponent("vCard.loc.vcf")
        
        do {
            try vCardString.write(toFile: vCardFilePath, atomically: true, encoding: String.Encoding.utf8)
        }
        catch let error {
            print("Error, \(error), saving vCard: \(vCardString) to file path: \(vCardFilePath).")
        }
        
        return NSURL(fileURLWithPath: vCardFilePath)
    }
    

    @objc func handleSend() {

        self.checkToText(inputString: toInput.text) { (users) in
            // CHECK FUNCTION SPITS OUT:
            //  UID: "USER" OR
            //  EMAIL_ADRESS : "EMAIL"
            
            var internalUsers = users.filter { (key, value) -> Bool in
                value != "email"
            }
            
            
            if internalUsers.count > 1 {
                // CURRENTLY ONLY CAN HANDLE ONE USER MESSAGE
                self.onlySendToFirstInternalUser(users: users)
            } else {
                self.handleSendToUsers(sentUsers: users)
            }
//            self.handleIMessage()
//            self.handleSendTest(sentUsers: users)
        }
    }
    
    func onlySendToFirstInternalUser(users: [String:String]){
        var legitUsers = users.filter { (key, value) -> Bool in
            value != "email"
        }
        
        guard let firstUser = legitUsers.first else {
            self.alert(title: "ERROR", message: "Missing Receipient User")
            return}
        let username = firstUser.value
        let userId = firstUser.key

        var tempUsers = users.filter { (key, value) -> Bool in
            value == "email"
        }
        tempUsers[username] = userId
        
        let message = "Messages Can Only be send to one user. Send Message to \(username)"
        let alert = UIAlertController(title: "Message Confirmation", message: message, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Send to \(username)", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction!) in
            self.handleSendToUsers(sentUsers: tempUsers)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: { (action: UIAlertAction!) in

        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    func handleSendMessageToUser(userId: String) {
        
        guard let toText = toInput.text else {return}
        Database.fetchUserWithUsername(username: toText) { (user, error) in
        
            
            guard let senderUID = Auth.auth().currentUser?.uid else {return}
            guard let postId = self.post?.id else {return}
            guard let message = self.messageInput.text else {return}
            guard let user = user else {return}
            let uploadTime = Date().timeIntervalSince1970
            let receiverUID = user.uid
            
            let databaseRef = Database.database().reference().child("messages").child(receiverUID)
            let userMessageRef = databaseRef.childByAutoId()
            
            let values = ["postId": postId, "creatorUID": senderUID, "message": message, "creationDate": uploadTime] as [String:Any]
            userMessageRef.updateChildValues(values) { (err, ref) in
                if let err = err {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    print("Failed to save message to DB", err)
                    return
                }
                
                print("Successfully save message to DB")
                SVProgressHUD.showSuccess(withStatus: "Message Sent to \(toText)")
                SVProgressHUD.dismiss(withDelay: 1)
                self.navigationController?.popToRootViewController(animated: true)

            }
        }
    }
    
    
    
    func handleSendEmail(email: String!){
            
            view.endEditing(true)
            
            guard let post = self.post else {return}
    
            let mailgun = Mailgun.client(withDomain: "shoutaround.com", apiKey: "key-2562988360d4f7f8a1fcc6f3647b446a")
    
            var fromLabel: String?
            
            if fromInput.text == nil {
                fromLabel = "<user@shoutaround.com>"
            } else {
                
                var trimmedusername = CurrentUser.username!.replacingOccurrences(of: " ", with: "")
                    trimmedusername = trimmedusername.replacingOccurrences(of: "@", with: "")
                
                fromLabel = fromInput.text!.replacingOccurrences(of: "@", with: "") + "<" + trimmedusername + "@shoutaround.com>"
            }
            
            var toLabel: String?
            
            if isValidEmail(testStr: email) {
                toLabel = "<" + email + ">"
            } else {
                print("Not Email")
                return
            }
                
        
            let message = MGMessage(from:fromLabel,
                                    to:toLabel,
                                    subject:"Shoutaround Message",
                                    body:(""))!
    
            let sentImageUrl = post.imageUrls[0]
            let postImage = CustomImageView()
            postImage.loadImage(urlString: sentImageUrl)
    
        
            //        message.add(postImage.image, withName: "image01", type: .JPEGFileType, inline: true)
            message.html = "<html><p><img src=" + sentImageUrl + " width = \"25%\" height = \"25%\"/></p><p>" + post.emoji + "</p><p>" + post.locationName + "</p><p>" + post.locationAdress + "</p><p>" + post.user.username + "</p><p>" + post.caption +  "</p><p>" + "Message From " + fromInput.text! + "</p><p>" + messageInput.text + "</p></html>"
  
            // someImage: UIImage
            // type can be either .JPEGFileType or .PNGFileType
            // message.add(postImage.image, withName: "image01", type:.PNGFileType)
    
    
            mailgun?.send(message, success: { (success) in
                print("success sending email to \(email)")
                SVProgressHUD.showSuccess(withStatus: "Message Sent to \(email)")
                SVProgressHUD.dismiss(withDelay: 1)
                self.navigationController?.popViewController(animated: true)
                
            }, failure: { (error) in
                print(error)
            })
    
    }
        
    
    func isValidEmail(testStr:String) -> Bool {
        // print("validate calendar: \(testStr)")
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    
}
