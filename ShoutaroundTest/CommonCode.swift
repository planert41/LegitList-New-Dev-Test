//
//  CommonCode.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 7/20/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import Foundation
/*

let headerTitle = NSAttributedString(string: "Logout", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Regular", size: 14)])

 
 // ADD IMAGE TO ATTRIBUTED STRING
 
         let credButtonString = NSMutableAttributedString(string: "\(credCount) ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.darkGray, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: socialStatsFontSize)]))
         socialStats.append(credButtonString)
 
         let image1Attachment = NSTextAttachment() 
         //                let inputImage = UIImage(named: "cred")!.resizeImageWith(newSize: imageSize)
         let inputImage = #imageLiteral(resourceName: "drool")
         image1Attachment.image = inputImage.alpha(0.5)
 
         image1Attachment.bounds = CGRect(x: 0, y: (socialStatsLabel.font.capHeight - (inputImage.size.height)).rounded() / 2, width: inputImage.size.width, height: inputImage.size.height)
 
         let image1String = NSAttributedString(attachment: image1Attachment)
         socialStats.append(image1String)
 
 
 // TRANSITION SCREENS
 
         let transition = CATransition()
         transition.duration = 0.5
         transition.type = CATransitionType.push
         transition.subtype = CATransitionSubtype.fromRight
         transition.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
         view.window!.layer.add(transition, forKey: kCATransition)
         self.present(testNav, animated: true) {
         print("   Presenting List Option View")
         }
 
 
 */

//        searchTableView.contentSize = CGSize(width: self.view.frame.size.width - 20, height: searchTableView.contentSize.height)



//        self.socialListLabel.attributedText = attributedSocialListString

//        let attributedCreatorString = NSMutableAttributedString()

// CREATOR LIST
//        if let _ = (post.creatorListId) {
//            let creatorListCount = (post.creatorListId?.count)!
//            let creatorUsername = post.user.username
//
//            if creatorListCount > 0 {
//let textViewPlaceholder = NSMutableAttributedString(string: "Describe your new list", attributes: [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.ianGrayColor()])
//
//                attributedSocialListString.append(attributedString)
//            }
//        }

//        var totalUniqueListUsers = post.allList.countUniqueStringValues()
//
//        // Following Users
//        var followingUsers: [String: Int] = post.followingList.stringValueCounts()
//        followingUsers.sorted(by: { $0.value > $1.value })
//
//        // Remove Post Creator ID from following users stats
//        if let creatorIndex = followingUsers.index(forKey: post.creatorUID!) {
//            followingUsers.remove(at: creatorIndex)
//        }
//
//
//        if let mostListFollowingUser1 = followingUsers.first?.key {
//            Database.fetchUserWithUID(uid: mostListFollowingUser1) { (user) in
//                self.updateSocialLabel(listCount: post.listCount, userCount: totalUniqueListUsers, usernames: [(user?.username)!])
//            }
//        } else {
//            self.updateSocialLabel(listCount: post.listCount, userCount: totalUniqueListUsers, usernames: nil)
//        }



//        // Bookmark Counts
//        if post.listCount > 0 {
//            self.socialStatsViewHeight?.constant = 15
//            var followingUserString: String = ""
//            var totalUniqueListUsers = post.allList.countUniqueStringValues()
//            var userString = "\(post.listCount) Pins "
//
//        // Following Users
//            var followingUsers: [String: Int] = post.followingList.stringValueCounts()
//            followingUsers.sorted(by: { $0.value > $1.value })
//
//            // Remove Post Creator ID from following users stats
//            if let creatorIndex = followingUsers.index(forKey: post.creatorUID!) {
//                followingUsers.remove(at: creatorIndex)
//            }
//
//            let totalFollowingLists = post.followingList.count
//            let totalFollowingUsers = followingUsers.count
//
//            if let mostListFollowingUser1 = followingUsers.first?.key {
//                var otherUserCount = 0
//
//                Database.fetchUserWithUID(uid: mostListFollowingUser1) { (user) in
//                    self.updateSocialLabel(listCount: post.listCount, userCount: post.allList.countUniqueStringValues(), usernames: [(user?.username)!])
//
//
////                    if let mostListFollowingUsername = user?.username {
////                        otherUserCount = totalUniqueListUsers - 1
////                        userString += "by \(mostListFollowingUsername) & \(otherUserCount) Others"
////                    } else {
////                        otherUserCount = totalUniqueListUsers
////                        userString += "by \(otherUserCount) Users"
////                    }
////
////                    if otherUserCount == 1 && userString.lowercased().last == "s"{
////                        // Drop Last S if usercount == 1
////                        userString.dropLast()
////                    }
////                    self.socialStatsLabel.text = userString
////                    self.socialStatsLabel.sizeToFit()
//
//                }
//            }
//            else {
//                // No List from Following User
//                userString += "by \(totalUniqueListUsers) Users"
//                // Drop Last S if usercount == 1
//                if totalUniqueListUsers == 1 && userString.lowercased().last == "s"{
//                    userString.dropLast()
//                }
//                self.socialStatsLabel.text = userString
//                self.socialStatsLabel.sizeToFit()
//            }
//        } else {
//            self.socialStatsViewHeight?.constant = 0
//            self.socialStatsLabel.text = ""
//        }
//

// Update Bookmarks
//        bookmarkCountLabel.text = (post.listCount != 0) ? String(post.listCount) : ""
//        bookmarkCountLabel.sizeToFit()

//        let attributedListText = NSMutableAttributedString()

//        if post.listCount > 0 {
//
//            let imageSize = CGSize(width: 20, height: 20)
//            let bookmarkImage = NSTextAttachment()
//            let bookmarkIcon = #imageLiteral(resourceName: "pin_gray_fill").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
//            bookmarkImage.bounds = CGRect(x: 0, y: (bookmarkCountLabel.font.capHeight - bookmarkIcon.size.height).rounded() / 2, width: bookmarkIcon.size.width, height: bookmarkIcon.size.height)
//            bookmarkImage.image = bookmarkIcon
//
//            let bookmarkImageString = NSAttributedString(attachment: bookmarkImage)
//            attributedListText.append(bookmarkImageString)
//
//            let attributedString = NSMutableAttributedString(string: " " + String(post.listCount), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 15), NSForegroundColorAttributeName: UIColor.darkGray])
//            attributedListText.append(attributedString)
//        }

//        bookmarkCountLabel.attributedText = attributedListText
//        bookmarkCountLabel.sizeToFit()

//        bookmarkButton.setImage((!post.hasPinned ? #imageLiteral(resourceName: "pin_filled") : #imageLiteral(resourceName: "pin_white_fill")).withRenderingMode(.alwaysOriginal), for: .normal)
//        bookmarkButton.setImage((!post.hasPinned ? #imageLiteral(resourceName: "pin_white_fill") : UIImage()).withRenderingMode(.alwaysOriginal), for: .normal)
//        bookmarkButton.setImage((!post.hasPinned ? #imageLiteral(resourceName: "bookmark_white_fill") : UIImage()).withRenderingMode(.alwaysOriginal), for: .normal)


//        if (post.listCount) > 0 {
//            bookmarkButtonString =  bookmarkButtonString + " " + String(post.listCount)
//        }
//        bookmarkButton.setTitleColor((!post.hasPinned ? UIColor.init(hex: "f1c40f") : UIColor.white), for: .normal)
//        bookmarkButton.setTitleColor((!post.hasPinned ? UIColor.pinterestRedColor() : UIColor.white), for: .normal)

//        bookmarkButton.setTitleColor((!post.hasPinned ? UIColor.white : UIColor.darkLegitColor()), for: .normal)


//    func pinch(sender:UIPinchGestureRecognizer) {
//        if sender.state == .began {
//            let currentScale = self.photoImageView.frame.size.width / self.photoImageView.bounds.size.width
//            let newScale = currentScale*sender.scale
//            if newScale > 1 {
//                self.isZooming = true
//            }
//        } else if sender.state == .changed {
//            guard let view = sender.view else {return}
//            let pinchCenter = CGPoint(x: sender.location(in: view).x - view.bounds.midX,
//                                      y: sender.location(in: view).y - view.bounds.midY)
//            let transform = view.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y)
//                .scaledBy(x: sender.scale, y: sender.scale)
//                .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
//            let currentScale = self.photoImageView.frame.size.width / self.photoImageView.bounds.size.width
//            var newScale = currentScale*sender.scale
//
//            if newScale < 1 {
//                newScale = 1
//                let transform = CGAffineTransform(scaleX: newScale, y: newScale)
//                self.photoImageView.transform = transform
//                sender.scale = 1
//            }else {
//                view.transform = transform
//                sender.scale = 1
//            }
//        } else if sender.state == .ended || sender.state == .failed || sender.state == .cancelled {
//            guard let center = self.originalImageCenter else {return}
//            UIView.animate(withDuration: 0.3, animations: {
//                self.photoImageView.transform = CGAffineTransform.identity
//                self.photoImageView.center = center
//                //                self.superview?.bringSubview(toFront: self.photoImageView)
//            }, completion: { _ in
//                self.isZooming = false
//            })
//        }
//    }





//    func swipe(sender:UISwipeGestureRecognizer) {
//
//        guard let imageUrls = self.post?.imageUrls else {return}
//
//        switch sender.direction {
//        case UISwipeGestureRecognizerDirection.left:
//            if currentImage == (self.post?.imageCount)! - 1 {
//                currentImage = 0
//
//            }else{
//                currentImage += 1
//            }
//            photoImageView.loadImage(urlString: imageUrls[currentImage])
//
//        case UISwipeGestureRecognizerDirection.right:
//            if currentImage == 0 {
//                currentImage = (self.post?.imageCount)! - 1
//            }else{
//                currentImage -= 1
//            }
//            photoImageView.loadImage(urlString: imageUrls[currentImage])
//        default:
//            break
//        }
//
//    }
        
//        headerView.addSubview(emojiLabel)
//        emojiLabel.text = ">>"
//        emojiLabel.anchor(top: nil, left: emojiCollectionView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 0, height: 0)
//        emojiLabel.centerYAnchor.constraint(equalTo: emojiCollectionView.centerYAnchor).isActive = true
//        emojiLabel.sizeToFit()
//        emojiLabel.textColor = UIColor.ianBlackColor()
//        emojiLabel.alpha = 1
//
//
//        UIView.animate(withDuration: 2, delay: 0, options: [.repeat,.autoreverse], animations: {
//            self.emojiLabel.alpha = 0.0
//            let gradientMaskLayer:CAGradientLayer = CAGradientLayer()
//            gradientMaskLayer.frame = self.emojiLabel.bounds
//            gradientMaskLayer.colors = [UIColor.clear.cgColor, UIColor.red.cgColor, UIColor.red.cgColor, UIColor.clear.cgColor ]
//            gradientMaskLayer.startPoint = CGPoint(x: 0.0, y: 0)
//            gradientMaskLayer.endPoint = CGPoint(x: 1, y: 1)
//            self.emojiLabel.layer.mask = gradientMaskLayer
//        }, completion: nil)
//


//        UIView.animate(withDuration: 2, delay: 0, options: [.repeat,.autoreverse], animations: {
//            self.emojiLabel.alpha = 0.0
//            let gradientMaskLayer:CAGradientLayer = CAGradientLayer()
//            gradientMaskLayer.frame = self.emojiLabel.bounds
//            gradientMaskLayer.colors = [UIColor.clear.cgColor, UIColor.red.cgColor, UIColor.red.cgColor, UIColor.clear.cgColor ]
//            gradientMaskLayer.startPoint = CGPoint(x: 0.0, y: 0)
//            gradientMaskLayer.endPoint = CGPoint(x: 1, y: 1)
//            self.emojiLabel.layer.mask = gradientMaskLayer
//        }, completion: nil)
        

        /*
        headerView.addSubview(navNotificationButton)
        navNotificationButton.anchor(top: nil, left: nil, bottom: nil, right: headerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 20, width: 20, height: 20)
        navNotificationButton.centerYAnchor.constraint(equalTo: sortSegmentControl.centerYAnchor).isActive = true
        navNotificationButton.addTarget(self, action: #selector(didTapNotification), for: .touchUpInside)
        
        headerView.addSubview(navNotificationLabel)
        navNotificationLabel.anchor(top: nil, left: nil, bottom: nil, right: navNotificationButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 4, width: 0, height: 0)
        navNotificationLabel.centerYAnchor.constraint(equalTo: sortSegmentControl.centerYAnchor).isActive = true
        navNotificationLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapNotification)))
        setupNavNotification()
        
        sortSegmentControl.rightAnchor.constraint(lessThanOrEqualTo: navNotificationLabel.leftAnchor, constant: 5).isActive = true
        */
        


// KEYBOARD
// KEYBOARD TAPS TO EXIT INPUT

//https://stackoverflow.com/questions/46420488/iphonex-and-iphone-8-keyboard-height-are-different/46423340#46423340

//self.keyboardTap = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
//NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
//NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

//    @objc func keyboardWillShow(notification: NSNotification) {
//        if (self.isViewLoaded && (self.view.window != nil)) {
//            print("keyboardWillShow | Add Tap Gesture | SingleUserProfileViewController")
//            self.view.addGestureRecognizer(self.keyboardTap)
//
//            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
//
//                var bottomInset: CGFloat = 0.0
//                if #available(iOS 11.0, *) {
//                    bottomInset = CGFloat(view.safeAreaInsets.bottom)
//                }
//
//
//                self.view.frame.origin.y = self.topbarHeight - keyboardSize.height + bottomInset
//                print(self.view.frame.origin.y, self.topbarHeight, keyboardSize.height, bottomInset)
////                self.view.frame.origin.y = min(self.view.frame.origin.y, -keyboardSize.height)
//
//            }
//        }
//
////        if type(of: self.view.window?.rootViewController?.view) is SingleUserProfileViewController {
////            print("keyboardWillShow | Add Tap Gesture | SingleUserProfileViewController")
////            self.view.addGestureRecognizer(self.keyboardTap)
////        }
//    }
//
//    @objc func keyboardWillHide(notification: NSNotification){
////        if type(of: self.view.window?.rootViewController?.view) is SingleUserProfileViewController {
////            print("keyboardWillHide | Remove Tap Gesture | SingleUserProfileViewController")
////            self.view.removeGestureRecognizer(self.keyboardTap)
////        }
//
//        if (self.isViewLoaded && (self.view.window != nil)) {
//            print("keyboardWillHide | Remove Tap Gesture | SingleUserProfileViewController")
//            self.view.removeGestureRecognizer(self.keyboardTap)
//
//
//            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
////                self.view.frame.origin.y += keyboardSize.height
//                self.view.frame.origin.y = self.topbarHeight
//                print(self.view.frame.origin.y, self.topbarHeight, keyboardSize.height)
//
////                if let defaultHeight = bottomSearchBarYHeight {
////                    bottomSearchBar.frame.origin.y = defaultHeight
////                }
//
//            }
//
//        }
//    }
