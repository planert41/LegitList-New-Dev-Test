//
//  InboxController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/19/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

class InboxController: UICollectionViewController,UICollectionViewDelegateFlowLayout, ThreadCellDelegate {
    
    static let newMsgNotificationName = NSNotification.Name(rawValue: "NewInboxMessage")

    
    var messages = [Message](){
        didSet{
            self.updateCounts()
        }
    }
    
    var messageThreads = [MessageThread](){
        didSet{
            self.updateCounts()
        }
    }
    
    
    let inboxCellId = "inboxCellId"
    let threadCellId = "threadCellId"

    var noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = "No Messages"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = UIColor.black
        label.isHidden = true
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
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
        
        
        lazy var navShareButton: UIButton = {
            let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
    //        let icon = #imageLiteral(resourceName: "share").withRenderingMode(.alwaysTemplate)
            let icon = #imageLiteral(resourceName: "editPencil").withRenderingMode(.alwaysTemplate)

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
            button.titleLabel?.font = UIFont.systemFont(ofSize: 8)
            return button
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()


        setupNavigationItems()
        collectionView?.register(ThreadCell.self, forCellWithReuseIdentifier: threadCellId)
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        collectionView.alwaysBounceVertical = true

        fetchMessageThreads()
        collectionView?.backgroundColor = UIColor.white
        view.addSubview(noResultsLabel)
        noResultsLabel.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 50)
        noResultsLabel.isHidden = true
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: InboxController.newMsgNotificationName, object: nil)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchMessageThreads()
    }
    
    @objc func handleRefresh() {
        self.fetchMessageThreads()
    }
    
    func setupNavigationItems() {
        let tempImage = UIImage.init(color: UIColor.backgroundGrayColor())
        navigationController?.navigationBar.setBackgroundImage(tempImage, for: .default)
        navigationController?.view.backgroundColor = UIColor.backgroundGrayColor()
        navigationController?.isNavigationBarHidden = false
        
        navigationController?.navigationBar.barTintColor = UIColor.ianWhiteColor()
        navigationController?.navigationBar.tintColor = UIColor.ianLegitColor()
        navigationController?.navigationBar.isTranslucent = false

        // REMOVES THE 1PX BOTTOM LINE IN NAV BAR
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
        
        self.navigationController?.navigationBar.layer.shadowColor = UIColor.gray.cgColor
        self.navigationController?.navigationBar.layer.shadowOffset = CGSize(width: 0.0, height: 1)
        self.navigationController?.navigationBar.layer.shadowRadius = 1.0
        self.navigationController?.navigationBar.layer.shadowOpacity = 0.5
        self.navigationController?.navigationBar.layer.masksToBounds = false
        
        let customFont = UIFont(name: "Poppins-Bold", size: 16)
        var unreadMessageCount = messageThreads.filter { (thread) -> Bool in
            return !thread.isRead
        }.count
        let headerText =  "Inbox" + ((unreadMessageCount > 0) ? " (\(String(unreadMessageCount)))" : "")
        let headerTitle = NSAttributedString(string:headerText, attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: customFont])
        let navLabel = UILabel()
        navLabel.attributedText = headerTitle
        self.navigationItem.titleView = navLabel
        
//        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "NEW", style: .plain, target: self, action: #selector(newMessgae))

        navShareButton.addTarget(self, action: #selector(newMessgae), for: .touchUpInside)
        let newBarButton = UIBarButtonItem.init(customView: navShareButton)
        self.navigationItem.rightBarButtonItem = newBarButton
        
        
        navBackButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        let backBarButton = UIBarButtonItem.init(customView: navBackButton)
        self.navigationItem.leftBarButtonItem = backBarButton

    }
    
    @objc func newMessgae() {
        let controller = SelectUserMessageController()
        controller.displayUserId = Auth.auth().currentUser?.uid
        controller.sendingPost = nil
        if let m = self.navigationController {
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    func updateCounts(){
        navigationItem.title = "Inbox ( " + String(messageThreads.count) + " )"
        if messageThreads.count == 0 {
            noResultsLabel.isHidden = false
        } else {
            noResultsLabel.isHidden = true
        }
        
        self.setupNavigationItems()
    }
    
    func toBookmarks(){
        tabBarController?.selectedIndex = 3
    }

    func fetchMessageThreads(){
        guard let currentUserUID = Auth.auth().currentUser?.uid else {return}
        
        Database.fetchMessageThreadsForUID(userUID: currentUserUID) { (messageThreads) in
            self.messageThreads = messageThreads
            self.collectionView.refreshControl?.endRefreshing()
            self.collectionView?.reloadData()
        }
    }
    
    // THREAD CELL DELEGATE METHODS
    
    func didTapPicture(post: Post) {
        
        let pictureController = SinglePostView()
        pictureController.post = post
        navigationController?.pushViewController(pictureController, animated: true)
    }
    
    
    func refreshPost(post: Post) {
        // Update Cache
        postCache.removeValue(forKey: post.id!)
        postCache[post.id!] = post
    }
    

    
    func didTapMessage(post: Post) {
        
        let messageController = MessageController()
        messageController.post = post
        navigationController?.pushViewController(messageController, animated: true)
        
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var displayMessage = messageThreads[indexPath.item]
        messageThreads[indexPath.item].isRead = true
        self.extOpenMessage(message: self.messageThreads[indexPath.item], reload: true)
//
//        if let collectionView = self.collectionView {
//            let cell = collectionView.cellForItem(at: indexPath) as? ThreadCell
//            let threadMessageController = ThreadMessageController(collectionViewLayout: UICollectionViewFlowLayout())
//            threadMessageController.messageThread = messageThreads[indexPath.item]
//            threadMessageController.post = cell?.post
//            navigationController?.pushViewController(threadMessageController, animated: true)
//        }
    }
        

    
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messageThreads.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var displayMessage = messageThreads[indexPath.item]
        
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: threadCellId, for: indexPath) as! ThreadCell
//            cell.delegate = self
            cell.messageThread = displayMessage
            cell.backgroundColor = displayMessage.isRead ? UIColor.white : UIColor.mainBlue().withAlphaComponent(0.5)
            cell.delegate = self
//            print("Displayed Message Thread", displayMessage)
        
            return cell

        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

            return CGSize(width: view.frame.width, height: 70)

    }
    
    
}
