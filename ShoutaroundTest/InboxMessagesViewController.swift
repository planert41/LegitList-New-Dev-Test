//
//  InboxMessageViewController.swift
//
//
//  Created by Wei Zou Ang on 6/21/20.
//

import UIKit

import MessageUI
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

class InboxMessageViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    let cellId = "cellId"
    let headercellId = "headercellId"

    var messageThreadId: String? = nil {
        didSet {
            self.fetchMessageThread()
        }
    }
    
    var messageThread: MessageThread? = nil {
        didSet {
            guard let messageThread = messageThread else {return}
            self.fetchMessages()
            self.loadDisplayUser()

//            self.setupNavigationItems()
            Database.saveMessageInteraction(messageThread: messageThread)
//            self.fecthPostForMessage()
            
            let userNames = self.messageThread?.threadUsers.filter({ (name) -> Bool in
                return name != CurrentUser.username
            })
            if userNames?.count ?? 0 > 0 {
                let displayUserName = userNames![0]
                self.headerLabel.text = displayUserName
                guard let userId = self.messageThread?.threadUserDic.key(forValue: displayUserName) else {return}
                if let user = messageThread.userArray[userId] {
                    self.displayUser = user
                } else {
                    Database.fetchUserWithUID(uid: userId) { (user) in
                        self.displayUser = user
                        print("InboxMessageController | Loaded User \(self.displayUser?.username)")
                    }
                }
            }
            
        }
    }
    
    var displayPost: Post? {
        didSet {
            self.collectionView.reloadData()
        }
    }

    var messages: [Message] = [] {
        didSet {
            self.collectionView.reloadData()
            scrollToLastMsg()
        }
    }

    func fetchMessageThread() {
        guard let messageThreadId = messageThreadId else {return}
        Database.fetchMessageThread(threadId: messageThreadId) { (messageThreadRead) in
            self.messageThread = messageThreadRead
        }
    }
    
    fileprivate func fetchMessages() {
        guard let messageThread = messageThread else {return}
        let tempMessages = messageThread.messages.sorted { (m1, m2) -> Bool in
            return m1.creationDate.compare(m2.creationDate) == .orderedAscending
        }
        
        self.messages = tempMessages
        print("Inbox | fetchMessages | \(self.messages.count) Messages | \(messageThread.threadID)")
    }
    
    fileprivate func fecthPostForMessage() {
        guard let messageThread = messageThread else {return}
        let postId = messageThread.postId
        if !postId.isEmptyOrWhitespace() {
            Database.fetchPostWithPostID(postId: postId) { (post, error) in
                if let error = error {
                    print("Inbox | fetchPostWithPostID | \(postId) | \(error)")
                } else {
                    self.displayPost = post
                }
            }
        } else {
            print("Inbox | No Post ID for \(messageThread.threadID) | \(postId)")
            collectionView.reloadData()
        }
    }
    
    let messageTextField: UITextView = {
        
        let textView = UITextView()
        textView.text = "Enter Comment"
        textView.returnKeyType = UIReturnKeyType.done
        textView.keyboardType = UIKeyboardType.default
        textView.font = UIFont.systemFont(ofSize: 14)
        return textView
        
    }()
    
    var headerView = UIView()
    let userProfileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 2
        return iv
    }()
    let headerLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Poppins-Bold", size: 12)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.center
        label.lineBreakMode = .byWordWrapping
        label.lineBreakMode = .byClipping
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.baselineAdjustment = .alignCenters
        return label
    }()
    var profileImageSize: CGFloat = 35

    let deleteButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        button.setImage(#imageLiteral(resourceName: "delete"), for: .normal)
        //        button.layer.cornerRadius = button.frame.width/2
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(openDeleteMsg), for: .touchUpInside)
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.borderColor = UIColor.gray.cgColor
        button.layer.borderWidth = 0
        return button
    }()
    
    @objc func openDeleteMsg() {
        
        print("Delete Msg Button Pressed")
        let optionsAlert = UIAlertController(title: "Hide Message?", message: "Hide This Inbox Message?", preferredStyle: UIAlertController.Style.alert)
        
        
        optionsAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
            // Allow Editing
            self.hideCurrentMessage()
        }))

     
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        present(optionsAlert, animated: true) {
            optionsAlert.view.superview?.isUserInteractionEnabled = true
            optionsAlert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.alertClose(gesture:))))
        }
    }
    
    func hideCurrentMessage() {
        guard let thread = messageThread else {return}
        CurrentUser.blockedMessages[thread.threadID] = Date()
        Database.blockMessage(messageThread: thread)
        self.handleBack()
        print("DISMISS - Hide current message \(thread.threadID)")

    }
    
    
    
    var displayUser: User? {
        didSet {
            self.loadDisplayUser()
//            self.setupNavigationItems()
        }
    }
    
    func loadDisplayUser() {
        guard let profileImageUrl = displayUser?.profileImageUrl else {return}
        userProfileImageView.loadImage(urlString: profileImageUrl)
//        print("Load Profile Pic: ", profileImageUrl)
        headerLabel.text = displayUser?.username
    }
    
    func setupHeaderView() {
        // USER PROFILE
            headerView.addSubview(userProfileImageView)
        userProfileImageView.anchor(top: headerView.topAnchor, left: headerView.leftAnchor, bottom: headerView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 3, paddingBottom: 0, paddingRight: 10, width: profileImageSize, height: profileImageSize)
//            userProfileImageView.centerYAnchor.constraint(equalTo: locationView.centerYAnchor).isActive = true
            userProfileImageView.layer.cornerRadius = profileImageSize/2
            userProfileImageView.layer.borderWidth = 0
            userProfileImageView.layer.borderColor = UIColor.white.cgColor
            userProfileImageView.isUserInteractionEnabled = true
            userProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(usernameTap)))

        headerView.addSubview(headerLabel)
        headerLabel.anchor(top: nil, left: userProfileImageView.rightAnchor, bottom: nil, right: headerView.rightAnchor, paddingTop: 0, paddingLeft: 3, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        headerLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        headerLabel.isUserInteractionEnabled = true
        headerLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(usernameTap)))
        
        headerView.isUserInteractionEnabled = true
        headerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(usernameTap)))
    }
    
    @objc func usernameTap() {
        guard let uid = displayUser?.uid else {return}
        self.extTapUserUid(uid: uid, displayBack: true)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        self.view.backgroundColor = UIColor.ianWhiteColor()
        setupHeaderView()
        setupNavigationItems()
        setupCollectionView()
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleBackPressNav))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.view.layoutIfNeeded()
        // Keyboard Setups to Dismiss Keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        self.loadDisplayUser()

//        setupNavigationItems()
//        self.toInput.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.collectionView.collectionViewLayout.collectionViewContentSize.height <= self.collectionView.frame.height * 0.4 {
//                print(self.collectionView.collectionViewLayout.collectionViewContentSize.height, self.collectionView.frame.height, UIScreen.main.bounds.height)
                return
            }
            if self.collectionView.frame.origin.y == 0 && messageTextField.isFirstResponder{
//                print("Show Keyboard Height :", keyboardSize.height)
                var lessShift = self.collectionView.frame.height * 0.8 - self.collectionView.collectionViewLayout.collectionViewContentSize.height < keyboardSize.height
                var shift = keyboardSize.height * (lessShift ? 0.5 : 1)
                self.collectionView.frame.origin.y -= shift
                self.scrollToLastMsg()
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
//        self.collectionView.frame.origin.y = 0
        self.resetCollectionView()
//        if self.collectionView.frame.origin.y != 0 {
//            self.collectionView.frame.origin.y = 0
//        }
    }
    
    
    func resetCollectionView() {
        if self.collectionView.frame.origin.y != 0 {
            self.collectionView.frame.origin.y = 0
        }
    }

    func setupCollectionView() {
//        self.collectionView!.backgroundColor = UIColor.backgroundGrayColor()
        self.collectionView!.backgroundColor = UIColor.ianWhiteColor()
//        collectionView?.backgroundColor = UIColor.rgb(red: 249, green: 249, blue: 249)

        self.collectionView!.alwaysBounceVertical = true
        self.collectionView!.keyboardDismissMode = .interactive
        
        self.collectionView!.register(MessageCell.self, forCellWithReuseIdentifier: cellId)
        self.collectionView!.register(PostHeaderCollectionViewCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headercellId)

        // Comment Input is height of 50
        self.collectionView!.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 200, right: 0)
        self.collectionView!.scrollIndicatorInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: 200, right: 0)
//        self.collectionView.contentSize = CGSize(width: self.view.frame.size.width, height: self.view.frame.size.height - 200)
        self.collectionView!.isUserInteractionEnabled = true
        self.collectionView!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))

        self.collectionView!.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 200).isActive = true
//        scrollToLastMsg()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        self.collectionView!.refreshControl = refreshControl
        self.collectionView!.alwaysBounceVertical = true
    }

    
    @objc func handleRefresh() {
        guard let threadId = self.messageThread?.threadID else {return}
        print("Refresh Thread : \(threadId)")
        Database.fetchMessageThread(threadId: threadId) { (thread) in
            self.messageThread = thread
            self.collectionView.refreshControl?.endRefreshing()
        }
    }
    
    
    func scrollToLastMsg() {
        let section = numberOfSections(in: collectionView) - 1
        let item = collectionView.numberOfItems(inSection: section) - 1
        let lastIndexPath = IndexPath(item: item, section: section)
        collectionView.scrollToItem(at: lastIndexPath, at: .bottom, animated: false)
        print("Inbox | scrollToLastMsg")
    }
    
    // NAV BUTTONS
        lazy var navBackButton: UIButton = {
            let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            let icon = #imageLiteral(resourceName: "back_icon").withRenderingMode(.alwaysTemplate)
            button.setImage(icon, for: .normal)
            button.layer.backgroundColor = UIColor.clear.cgColor
            button.layer.borderColor = UIColor.ianLegitColor().cgColor
            button.layer.borderWidth = 0
            button.layer.cornerRadius = 2
            button.clipsToBounds = true
            button.contentHorizontalAlignment = .center
            button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
            button.tintColor = UIColor.ianBlackColor()
            button.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)
            return button
        }()
    
    
    func setupNavigationItems(){
//        let navLabel = UILabel()
//        let customFont = UIFont(name: "Poppins-Bold", size: 16)
//        var headerText = ""
//
//        let userNames = self.messageThread?.threadUsers.filter({ (name) -> Bool in
//            return name != CurrentUser.username
//        })
//
//        if (userNames?.count ?? 0) > 0 {
//            headerText = userNames?.joined(separator: ", ") as! String
//        } else {
//            headerText = "Message"
//        }
//
//        let headerTitle = NSAttributedString(string:headerText, attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: customFont])
//        navLabel.attributedText = headerTitle
//        self.navigationItem.titleView = navLabel
        


        // Nav Bar Buttons
//        let navShareButton = navShareButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//        navShareButton.addTarget(self, action: #selector(showMessagingOptionsNav), for: .touchUpInside)
//        let barButton1 = UIBarButtonItem.init(customView: navShareButton)
//        self.navigationItem.rightBarButtonItem = barButton1
        

        
        // Nav Back Buttons
//        let navBackButton = navBackButtonTemplate.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//        navBackButton.addTarget(self, action: #selector(handleBackPressNav), for: .touchUpInside)
//        navBackButton.backgroundColor = UIColor.clear
//        navBackButton.layer.backgroundColor = UIColor.clear.cgColor
//        let barButton2 = UIBarButtonItem.init(customView: navBackButton)
//        self.navigationItem.leftBarButtonItem = barButton2
        
        self.loadDisplayUser()
        self.navigationItem.titleView = headerView
        
        navBackButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        let backBarButton = UIBarButtonItem.init(customView: navBackButton)
        self.navigationItem.leftBarButtonItem = backBarButton
        
        let deleteNavButton = UIBarButtonItem.init(customView: deleteButton)
        self.navigationItem.rightBarButtonItem = deleteNavButton

        self.navigationController?.navigationBar.tintColor = UIColor.ianLegitColor()
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationController?.navigationBar.backgroundColor = UIColor.clear
        self.navigationController?.navigationBar.isTranslucent = false

    }


    @objc func handleBackPressNav(){
        self.handleBack()
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        self.messageTextField.resignFirstResponder()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return self.messages.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! MessageCell
        cell.message = self.messages[indexPath.row]
        cell.delegate = self
        cell.backgroundColor = UIColor.rgb(red: 249, green: 249, blue: 249)
        cell.backgroundColor = UIColor.ianWhiteColor()

        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        let dummyCell = MessageCell(frame: frame)
        dummyCell.message = messages[indexPath.item]
        dummyCell.layoutIfNeeded()
        
        let targetSize = CGSize(width: view.frame.width, height: 1000)
        let estimatedSize = dummyCell.systemLayoutSizeFitting(targetSize)
        
        let height = max(40 + 8+8, estimatedSize.height)
        
        return CGSize(width: view.frame.width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    
    
     override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

//            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HomeHeaderId, for: indexPath) as! LegitHomeHeader
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headercellId, for: indexPath) as! PostHeaderCollectionViewCell

        header.post = displayPost
        header.backgroundColor = UIColor.white.withAlphaComponent(0.8)

//        if self.mapFilter.filterLocation != nil && header.post?.locationGPS != nil {
//            header.post?.distance = Double((header.post?.locationGPS?.distance(from: (self.mapFilter.filterLocation!)))!)
//        }
        
        header.delegate = self
        header.currentImage = 1
        header.cellWidth = self.collectionView.frame.width

        return header
    }


   func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        return CGSize(width: view.frame.width, height: 220)
       if section == 0 {
           // Get the view for the first header
           let indexPath = IndexPath(row: 0, section: section)
           let headerView = self.collectionView(collectionView, viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader, at: indexPath)

           // Use this view to calculate the optimal size based on the collection view's width
            if (self.displayPost == nil) {
                return CGSize.zero
            } else {
                return headerView.systemLayoutSizeFitting(CGSize(width: collectionView.frame.width, height: UIView.layoutFittingExpandedSize.height),
                                                             withHorizontalFittingPriority: .required, // Width is fixed
                                                             verticalFittingPriority: .fittingSizeLevel) // Height can be as large as needed
            }

           
       } else {
           return CGSize.zero
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
    

    // MARK: UICollectionViewDelegate

    let messageDefault = "Reply Message"
    
    lazy var newContainerView: UIView = {
            
        let containerView = UIView()
        containerView.backgroundColor = UIColor.clear
        containerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 200)
        
        
        let commentContainer = UIView()
        commentContainer.backgroundColor = UIColor.white
        commentContainer.layer.cornerRadius = 2
        commentContainer.layer.borderColor = UIColor.rgb(red: 221, green: 221, blue: 221).cgColor
        commentContainer.layer.borderColor = UIColor.darkGray.cgColor

        commentContainer.layer.borderWidth = 1
        containerView.addSubview(commentContainer)
        commentContainer.anchor(top: nil, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 20, paddingRight: 10, width: 0, height: 100)

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
        containerView.addSubview(self.messageTextField)
        self.messageTextField.anchor(top: commentContainer.topAnchor, left: commentContainer.leftAnchor, bottom: divider.topAnchor, right: commentContainer.rightAnchor, paddingTop: 10, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        self.messageTextField.delegate = self
        self.automaticallyAdjustsScrollViewInsets = false
        self.resetCaptionTextView()

    //        self.commentTextField.backgroundColor = UIColor.yellow
        
        
        
    //        let lineSeparatorView = UIView()
    //        lineSeparatorView.backgroundColor = UIColor.rgb(red: 230, green: 230, blue: 230)
    //        containerView.addSubview(lineS    eparatorView)
    //        lineSeparatorView.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: nil, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        return containerView
        
    }()
        
    func resetCaptionTextView() {
        self.messageTextField.text = messageDefault
        self.messageTextField.textColor = UIColor.darkGray
    }
    

}


extension InboxMessageViewController: UITextViewDelegate, MessageCellDelegate, PostHeaderCollectionViewCellDelegate {
    func didTapPost(post: Post?) {
        self.extTapPicture(post: post)
    }
    
    
    func showEmojiDetail(emoji: String?) {
        print("InboxMsg | showEmojiDetail | \(emoji)")
    }
    
    func didTapLocation(post: Post) {
        self.extTapLocation(post: post)
    }
    
    func didTapUser(post: Post) {
        self.extTapUser(post: post)
    }
    
    func didTapPicture(post: Post) {
        self.extTapPicture(post: post)
    }
    
    func minimizeCollectionView() {
        print("InboxMsg | minimizeCollectionView")
    }
    
    func togglePost() {
        print("InboxMsg | TOGGLE POST")
    }
    
    
    func didTapCancel(comment: Comment) {
        print("InboxMessageViewController | Tap Cancel")
    }
    

    @objc func handleSubmit() {
        print("submit Message:", messageTextField.text ?? "")
        
        if messageTextField.text == "" {
            self.alert(title: "Message Error", message: "Can't Send a Blank Message")
            return
        }
        
        guard let messageThread = self.messageThread else {return}
        guard let messageText = messageTextField.text else {return}
        if messageText.isEmptyOrWhitespace() {return}
        
        Database.createMessageForThread(messageThread: messageThread, creatorUid: Auth.auth().currentUser!.uid, postId: nil, messageText: messageText)

        
//        Database.respondMessageThread(threadKey: messageThread.threadID, creatorUid: Auth.auth().currentUser!.uid, message: messageText)
        
        // Create Message
        let uploadTime = Date().timeIntervalSince1970
        var messageDic = ["creatorUID":Auth.auth().currentUser!.uid, "message": messageText, "creationDate": uploadTime] as [String : Any]
        let tempMessage = Message(messageID: "temp", dictionary: messageDic)
        self.messages.append(tempMessage)
        self.collectionView.reloadData()
        
        self.messageTextField.text = ""

    }
    

    @objc func handleClear(){
        self.messageTextField.text = nil
    }
    
    @objc func handleCancel(){
        self.messageTextField.resignFirstResponder()
    }
    
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        // Clears Out Default Caption
        if messageTextField.text == messageDefault {
            messageTextField.text = nil
        }
        messageTextField.textColor = UIColor.black
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        self.resetCollectionView()
        textView.resignFirstResponder()
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == messageTextField {
            if textView.text.isEmpty {
                self.resetCaptionTextView()
            }
        }
    }
    
    
}
