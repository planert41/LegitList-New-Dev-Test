//
//  Extensions.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/24/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import CoreLocation

import Accelerate
import simd
import MapKit
import MessageUI
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import FBSDKLoginKit
import SKPhotoBrowser
import SwiftyJSON


extension UIApplication {
    var statusBarView: UIView? {
        if responds(to: Selector("statusBar")) {
            return value(forKey: "statusBar") as? UIView
        }
        return nil
    }
    
}

extension UICollectionView {
   func reloadItemsNoHeader(inSection section:Int) {
      reloadItems(at: (0..<numberOfItems(inSection: section)).map {
         IndexPath(item: $0, section: section)
      })
   }
    

    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .black
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = .center;
        messageLabel.font = UIFont(name: "TrebuchetMS", size: 15)
        messageLabel.sizeToFit()

        self.backgroundView = messageLabel;
    }

    func restore() {
        self.backgroundView = nil
    }
}

extension UIColor {
    
    static func rgb(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: 1)
    }
        
    static func mainBlue() -> UIColor {
        return UIColor.rgb(red: 17, green: 154, blue: 237)
    }
    
    static func otherUserColor() -> UIColor {
        return UIColor(hexColor: "fe5f55")
    }
    
    static func pinterestRedColor() -> UIColor {
        return UIColor(hexColor: "e60023")
    }
    
    static func ianLegitColor() -> UIColor {
        return UIColor.rgb(red: 247, green: 104, blue: 98)
        // NEW TEST FROM MARIA
        return UIColor.rgb(red: 255, green: 204, blue: 0)


    }
    
    static func weiBookmarkColor() -> UIColor {
        return UIColor(hexColor: "de1738")
    }
    
    static func oldIanLegitColor() -> UIColor {
        
        // CORAL ISH
        return UIColor.rgb(red: 232, green: 82, blue: 176)

        //return UIColor.rgb(red: 208, green: 108, blue: 140)
    }
    
    static func ianOrangeColor() -> UIColor {
        return UIColor.rgb(red: 255, green: 209, blue: 102)
    }
    
    static func ianBlueColor() -> UIColor {
        return UIColor.rgb(red: 35, green: 123, blue: 159)
    }
    
    static func ianBlackColor() -> UIColor {
        return UIColor.rgb(red: 22, green: 22, blue: 22)
    }
    
    static func ianMiddleGrayColor() -> UIColor {
        return UIColor.rgb(red: 85, green: 85, blue: 85)
    }
    
    static func ianWhiteColor() -> UIColor {
        return UIColor.rgb(red: 249, green: 249, blue: 249)
    }
    
    static func ianGrayColor() -> UIColor {
        return UIColor.rgb(red: 136, green: 136, blue: 136)
    }
    
    static func ianLightGrayColor() -> UIColor {
        return UIColor.rgb(red: 221, green: 221, blue: 221)
    }
    
    static func backgroundGrayColor() -> UIColor {
        return UIColor.rgb(red: 230, green: 230, blue: 230)
    }
    
    static func lightBackgroundGrayColor() -> UIColor {
        return UIColor.rgb(red: 249, green: 249, blue: 249)
    }
    
    static func legitColor() -> UIColor {
        //        return UIColor(hexColor: "107896")
        
        
        
        //        return UIColor(hexColor: "0ab0ba")
        
        //        return UIColor(hexColor: "007c91")
        
        //        return UIColor(hexColor: "006978")
        
        //PANTONE 16-1546
        return UIColor(hexColor: "ff6f61")
        
        
    }
    
    static func backgroundLegitColor() -> UIColor {
        return UIColor(hexColor: "ff9d94")
    }
    
    
    static func oldLegitColor() -> UIColor {
        return UIColor(hexColor: "006978")
    }

    
    static func tBlueColor() -> UIColor {
        // TEAL
        return UIColor(hexColor: "0abab5")
    }
    
    static func lightLegitColor() -> UIColor {
        return UIColor(hexColor: "21bbe7")
    }
    
    static func lightSelectedColor() -> UIColor {
        return UIColor(hexColor: "f6db6c")
    }
    
    static func selectedColor() -> UIColor {
        return UIColor(hexColor: "f1c40f")
    }
    
    static func darkSelectedColor() -> UIColor {
        return UIColor(hexColor: "c29d0b")
        return UIColor(hexColor: "aa8a0a")
    }
    
    static func customRedColor() -> UIColor {
        return UIColor(hexColor: "f6736c")

        return UIColor(hexColor: "f10f3c")
    }
    
    static func lightRedColor() -> UIColor {
        return UIColor(hexColor: "f9a19c")
        return UIColor(hexColor: "f78a84")

    }

    static func darkLegitColor() -> UIColor {
        return UIColor(hexColor: "06272d")
        //        return UIColor(hexColor: "007c91")
        
        //        return UIColor(hexColor: "006978")
        
    }
    
    
    static func bookmarkColor() -> UIColor {
        return UIColor(hexColor: "9a0007")
        //        return UIColor(hexColor: "007c91")
        
        //        return UIColor(hexColor: "006978")
        
    }
    
    static func credColor() -> UIColor {
        //        return UIColor(hexColor: "0aa4d1")
        return UIColor(hexColor: "ff9900")
    }
    
    
    static func primaryColor() -> UIColor {
//        return UIColor(hexColor: "0aa4d1")
        return UIColor(hexColor: "00acc1")
    }
    
    static func lightColor() -> UIColor {
        //        return UIColor(hexColor: "0aa4d1")
        return UIColor(hexColor: "5ddef4")
    }
    
    
    static func privateColor() -> UIColor {
        //        return UIColor(hexColor: "0aa4d1")
        return UIColor(hexColor: "ff6659")
    }
    
    
    

    
    
    
    
    static func barColor() -> UIColor {
        return UIColor(hexColor: "0a4a5c")
    }
    
    static func legitListNameColor() -> UIColor {
        return UIColor.init(hexColor: "F1C40F")
    }
    
    static func bookmarkListNameColor() -> UIColor {
        return UIColor.init(hexColor: "ff704d")
    }
    
    static func privateListNameColor() -> UIColor {
        return UIColor.init(hexColor: "ff6659")
    }
    
    convenience init(hexColor: String) {
        var red: UInt32 = 0, green: UInt32 = 0, blue: UInt32 = 0
        
        let hex = hexColor as NSString
        Scanner(string: hex.substring(with: NSRange(location: 0, length: 2))).scanHexInt32(&red)
        Scanner(string: hex.substring(with: NSRange(location: 2, length: 2))).scanHexInt32(&green)
        Scanner(string: hex.substring(with: NSRange(location: 4, length: 2))).scanHexInt32(&blue)
        
        self.init(red: CGFloat(red)/255.0, green: CGFloat(green)/255.0, blue: CGFloat(blue)/255.0, alpha: 1.0)
    }
    
    /// Converts this `UIColor` instance to a 1x1 `UIImage` instance and returns it.
    ///
    /// - Returns: `self` as a 1x1 `UIImage`.
    func as1ptImage() -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        setFill()
        UIGraphicsGetCurrentContext()?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
    
}

extension UIView{
    
    func anchor(top: NSLayoutYAxisAnchor?, left:NSLayoutXAxisAnchor?, bottom:NSLayoutYAxisAnchor?, right:NSLayoutXAxisAnchor?,  paddingTop: CGFloat, paddingLeft: CGFloat, paddingBottom: CGFloat, paddingRight:CGFloat , width: CGFloat, height: CGFloat) {
        
        translatesAutoresizingMaskIntoConstraints = false
        
        
        if let top = top {
            
            self.topAnchor.constraint(equalTo: top, constant: paddingTop).isActive = true
            
        }
        
        if let left = left {
            
            self.leftAnchor.constraint(equalTo: left, constant: paddingLeft).isActive = true
            
        }
        
        if let bottom = bottom {
            
            self.bottomAnchor.constraint(equalTo: bottom, constant: -paddingBottom).isActive = true
            
        }
        
        
        if let right = right {
            
            self.rightAnchor.constraint(equalTo: right, constant: -paddingRight).isActive = true
            
        }
        
        if width != 0 {
            widthAnchor.constraint(equalToConstant: width).isActive = true
            
        }
        
        if height != 0 {
            heightAnchor.constraint(equalToConstant: height).isActive = true
            
        }
    }
    
}

extension Date {
    func timeAgoDisplay() -> String {
        let secondsAgo = Int(Date().timeIntervalSince(self))
        
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day
        let month = 4 * week
        
        let quotient: Int
        let unit: String
        if secondsAgo < minute {
            quotient = secondsAgo
            unit = "second"
        } else if secondsAgo < hour {
            quotient = secondsAgo / minute
            unit = "min"
        } else if secondsAgo < day {
            quotient = secondsAgo / hour
            unit = "hour"
        } else if secondsAgo < week {
            quotient = secondsAgo / day
            unit = "day"
        } else if secondsAgo < month {
            quotient = secondsAgo / week
            unit = "week"
        } else {
            quotient = secondsAgo / month
            unit = "month"
        }
        
        return "\(quotient) \(unit)\(quotient == 1 ? "" : "s") ago"
        
    }
    
    func daysAgo() -> Int {
        let secondsAgo = Int(Date().timeIntervalSince(self))
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let daysAgo =  Int(ceil(Double(secondsAgo/day)))
        
        return daysAgo

    }
    
}

extension Dictionary {
    mutating func merge(dict: [Key: Value]){
        for (k, v) in dict {
            updateValue(v, forKey: k)
        }
    }
    
    static func += (left: inout [Key: Value], right: [Key: Value]) {
        for (key, value) in right {
            left[key] = value
        }
    }
    
}

extension Dictionary where Value: Equatable {
    func key(forValue value: Value) -> Key? {
        return first { $0.1 == value }?.0
    }
    
    func countUniqueStringValues() -> Int{
        var countDic: [String: Int] = [:]
        for (key,value) in self {
            let tempValue = value as! String
            countDic[tempValue] = countDic[tempValue, default: 0] + 1
            }
        return countDic.count ?? 0
    }
    
    func uniqueStringValues() -> Int{
        var uniqueValues: [String] = []
        for (key,value) in self {
            let temp_value = value as! String
            if !uniqueValues.contains(temp_value){
                uniqueValues.append(temp_value)
            }
        }
        return uniqueValues.count
    }
    
    func stringValueCounts() -> [String:Int]{
        var uniqueValueCounts: [String:Int] = [:]
        for (key,value) in self {
            let temp_value = value as! String
            if let _ = uniqueValueCounts[temp_value] {
                uniqueValueCounts[temp_value]! += 1
            } else {
                uniqueValueCounts[temp_value] = 1
            }
        }
        return uniqueValueCounts
    }
    
}

extension StringProtocol where Self: RangeReplaceableCollection {
    var removingAllWhitespaces: Self {
        filter(\.isWhitespace.negated)
    }
    
    mutating func removeAllWhitespaces() {
        removeAll(where: \.isWhitespace)
    }
    
    var words: [SubSequence] {
        split(whereSeparator: \.isLetter.negated)
    }
}


extension Bool {
    var negated: Bool { !self }
}


extension String {
    
    func alphaNumericOnly() -> String {
        let unsafeChars = CharacterSet.alphanumerics.inverted  // Remove the .inverted to get the opposite result.
        let cleanChars  = self.components(separatedBy: unsafeChars).joined(separator: "")
        return cleanChars
    }
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + self.lowercased().dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
        
    
    func isEmptyOrWhitespace() -> Bool {
        
        if(self.isEmpty) {
            return true
        }
        
        return (self.trimmingCharacters(in: .whitespaces).isEmpty)
    }    
    
    func formatName() -> String {
        var words = self.lowercased().components(separatedBy: " ")
        var formattedWords: [String] = []
        for word in words {
            formattedWords.append(word.capitalizingFirstLetter())
        }
        
        return formattedWords.joined(separator: " ")
        
    }
    
    
    /**
     Truncates the string to the specified length number of characters and appends an optional trailing string if longer.
     
     - Parameter length: A `String`.
     - Parameter trailing: A `String` that will be appended after the truncation.
     
     - Returns: A `String` object.
     */
    
    func words() -> [String]{
        return components(separatedBy: " ")
    }
    
    func truncate(length: Int, trailing: String = "…") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        } else {
            return self
        }
    }
    
    func cutoff(length: Int) -> String {
        if self.count > length {
            return String(self.prefix(length))
        } else {
            return self
        }
    }
    
    func removingWhitespaces() -> String {
        return components(separatedBy: .whitespaces).joined()
    }
    
    var removeDuplicates: String {
        var set = Set<Character>()
        return String(filter{ set.insert($0).inserted })
    }
    
    func indicesOf(string: String) -> [Int] {
        var indices = [Int]()
        var searchStartIndex = self.startIndex

        while searchStartIndex < self.endIndex,
            let range = self.range(of: string, range: searchStartIndex..<self.endIndex),
            !range.isEmpty
        {
            let index = distance(from: self.startIndex, to: range.lowerBound)
            indices.append(index)
            searchStartIndex = range.upperBound
        }

        return indices
    }
    
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
//    subscript (r: Range<Int>) -> String {
//        let start = index(startIndex, offsetBy: r.lowerBound)
//        let end = index(startIndex, offsetBy: r.upperBound)
//        return self[Range(start ..< end)]
//    }    
    

}

extension Int {
    func format(f: String) -> String {
        return String(format: "%\(f)d", self)
    }
}

extension Double {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
    
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}


extension CALayer {
    func applySketchShadow(
        color: UIColor = .black,
        alpha: Float = 0.05,
        x: CGFloat = 0,
        y: CGFloat = 1,
        blur: CGFloat = 4,
        spread: CGFloat = 0)
    {
        shadowColor = color.cgColor
        shadowOpacity = alpha
        shadowOffset = CGSize(width: x, height: y)
        shadowRadius = blur / 2.0
        if spread == 0 {
            shadowPath = nil
        } else {
            let dx = -spread
            let rect = bounds.insetBy(dx: dx, dy: dx)
            shadowPath = UIBezierPath(rect: rect).cgPath
        }
    }
}

extension UICollectionView {
    func reloadItems(inSection section:Int) {
        reloadItems(at: (0..<numberOfItems(inSection: section)).map {
            IndexPath(item: $0, section: section)
        })
    }
    
    func scrollToNextItem() {
        let contentOffset = CGFloat(floor(self.contentOffset.x + self.bounds.size.width))
        self.moveToFrame(contentOffset: contentOffset)
    }

    func scrollToPreviousItem() {
        let contentOffset = CGFloat(floor(self.contentOffset.x - self.bounds.size.width))
        self.moveToFrame(contentOffset: contentOffset)
    }

    func moveToFrame(contentOffset : CGFloat) {
        self.setContentOffset(CGPoint(x: contentOffset, y: self.contentOffset.y), animated: true)
    }
}

extension UICollectionViewController {
    
    func fetchCurrentUser() {
        
        // uid using userID if exist, if not, uses current user, if not uses blank
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        //        guard let uid = Auth.auth().currentUser?.uid else {return}
        
//        1. Pull User Information (Profile Img, Name, status, ListIds, social stats)
//        2. Pull Lists
//        3. Pull Social Stat Details (Voted Post Ids, Following, Followers)
        
        Database.fetchUserWithUID(uid: uid) { (user) in
            guard let user = user else {return}
            CurrentUser.uid = uid
            CurrentUser.username = user.username
            CurrentUser.profileImageUrl = user.profileImageUrl
            print(CurrentUser())
            
        }
    }
    
    
}

extension UIViewController {

    var isModal: Bool {
        if let index = navigationController?.viewControllers.firstIndex(of: self), index > 0 {
            return false
        } else if presentingViewController != nil {
            return true
        } else if navigationController?.presentingViewController?.presentedViewController == navigationController {
            return true
        } else if tabBarController?.presentingViewController is UITabBarController {
            return true
        } else {
            return false
        }
    }
    
    var isPresented: Bool {
        return self.isViewLoaded && self.view.window != nil
    }
    
    var topbarHeight: CGFloat {
        return UIApplication.shared.statusBarFrame.size.height +
            (self.navigationController?.navigationBar.frame.height ?? 0.0)
    }
    
    func extOpenSubscriptions() {
        let note = SubscriptionViewController()
//        note.displayUser = self.displayUser
//        note.isPremiumSub = true
//        note.displayUser = CurrentUser.user
        self.present(note, animated: true) {
            print("Show Subscription")
        }
    }
    
    func extOpenNotifications() {
        let note = UserEventViewController()
        self.navigationController?.pushViewController(note, animated: true)
    }
    
    
    func extCreateNewPhoto(){
        if Auth.auth().currentUser?.isAnonymous ?? true {
            let alert = UIAlertController(title: "Guest Profile", message: "Please Sign Up To Upload Photo", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            alert.addAction(UIAlertAction(title: "Sign Up", style: UIAlertAction.Style.cancel, handler: { (action: UIAlertAction!) in
                NotificationCenter.default.post(name: MainTabBarController.showLoginScreen, object: nil)
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            if !CurrentUser.isPremium && CurrentUser.postIds.count >= premiumPostLimit {
                let alert = UIAlertController(title: "New Post Limit", message: "Please Subscribe to Legit Premium to upload more than \(premiumPostLimit) posts.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Subscribe", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction!) in
                    self.extOpenSubscriptions()
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                NotificationCenter.default.post(name: MainTabBarController.OpenAddNewPhoto, object: nil)
            }
        }
    }
    
    func extTapPicture(post: Post?) {
//        let pictureController = SinglePostView()
        guard let post = post else {return}
        let pictureController = NewSinglePostView()
        pictureController.post = post
        pictureController.setupNavigationItems()
        navigationController?.pushViewController(pictureController, animated: true)
    }
    
    func extTapPictureComment(post: Post?) {
//        let pictureController = SinglePostView()
        guard let post = post else {return}
        let pictureController = NewSinglePostView()
        pictureController.post = post
        pictureController.handleComment()
        navigationController?.pushViewController(pictureController, animated: true)
    }
    
    func extTapPostId(postId: String?) {
//        let pictureController = SinglePostView()
        guard let postId = postId else {return}
        Database.fetchPostWithPostID(postId: postId) { (post, error) in
            if let error = error {
                print("extTapPostId ERROR | ",error)
            } else {
                self.extTapPicture(post: post)
            }
        }
    }

    
    func extTapComment(post: Post) {
        let commentsController = CommentsController(collectionViewLayout: UICollectionViewFlowLayout())
        commentsController.post = post
        navigationController?.pushViewController(commentsController, animated: true)
    }
    
    func extTapList(list: List) {
        let listViewController = SingleListViewController()

        listViewController.currentDisplayList = list
        listViewController.refreshPostsForFilter()

        print("extTapList | \(list.name)| \(list.id) | \(list.newNotificationsCount) Notification Count")
        if list.newNotificationsCount > 0 {
            list.clearAllNotifications()
            Database.updateListInteraction(list: list)
        }
        self.navigationController?.pushViewController(listViewController, animated: true)
    }
    
    func extTapListId(listId: String?) {
        guard let listId = listId else {return}
        
        Database.fetchListforSingleListId(listId: listId) { (list) in
            guard let list = list else {return}
            self.extTapList(list: list)
        }
    }
    
    func extCreateNewListSimple() {
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Create A New List", message: "Enter New List Name", preferredStyle: .alert)

        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.text = ""
        }

        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            print("New List Name: \(textField?.text)")
            guard let newListName = textField?.text else {return}

            let listId = NSUUID().uuidString
            guard let uid = Auth.auth().currentUser?.uid else {return}
            Database.checkListName(listName: newListName) { (listName) in

                let newList = List.init(id: listId, name: listName, publicList: 1)
                if !(Auth.auth().currentUser?.isAnonymous)! {
                    Database.createList(uploadList: newList){}

                } else {
                    // Update New List in Current User Cache
                    print("Guest User Creating List")
                    CurrentUser.addList(list: newList)
                }
            }
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))

        
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "Advanced", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            print("New List Name: \(textField?.text)")
            guard let newListName = textField?.text else {return}
            guard let uid = Auth.auth().currentUser?.uid else {return}
            Database.checkListName(listName: newListName) { (listName) in
                let next = NewListDescCardController()
                next.comingFromAlert = true
                var curList = List.init(id: NSUUID().uuidString, name: listName, publicList: 1)
                next.curList = curList
                let navController = UINavigationController(rootViewController: next)
                  let transition:CATransition = CATransition()
                    transition.duration = 0.5
                transition.subtype = CATransitionSubtype.fromBottom
                self.navigationController!.view.layer.add(transition, forKey: kCATransition)
                self.present(navController, animated: true, completion: nil)            }
        }))
        
        let subAlert = UIAlertController(title: "New List Limit", message: "Please Subscribe to Legit Premium to create more than \(premiumListLimit) lists.", preferredStyle: UIAlertController.Style.alert)
        subAlert.addAction(UIAlertAction(title: "Subscribe", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction!) in
            self.extOpenSubscriptions()
        }))
        subAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))

        // 4. Present the alert.
        if !CurrentUser.isPremium && CurrentUser.listIds.count >= premiumListLimit {
            self.present(subAlert, animated: true, completion: nil)
        } else {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func extCreateNewList() {
        if !CurrentUser.isPremium && CurrentUser.listIds.count >= premiumListLimit {
            let alert = UIAlertController(title: "New List Limit", message: "Please Subscribe to Legit Premium to create more than \(premiumListLimit) lists.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Subscribe", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction!) in
                self.extOpenSubscriptions()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            let createNewListView = CreateNewListCardController()
            let navController = UINavigationController(rootViewController: createNewListView)
              let transition:CATransition = CATransition()
                transition.duration = 0.5
    //        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
    //        transition.type = CATransitionType.push
            transition.subtype = CATransitionSubtype.fromBottom
                self.navigationController!.view.layer.add(transition, forKey: kCATransition)
            self.present(navController, animated: true, completion: nil)
        }
    }

    func extTapUser(post: Post) {
//        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
//        userProfileController.displayUserId = post.user.uid
//        navigationController?.pushViewController(userProfileController, animated: true)
        
        let userProfileController = SingleUserProfileViewController()
        userProfileController.displayUserId = post.user.uid
        userProfileController.displayBack = true
        navigationController?.pushViewController(userProfileController, animated: true)
        
    }
    
    func extTapUser(userId: String) {
        let userProfileController = SingleUserProfileViewController()
        userProfileController.displayUserId = userId
        userProfileController.displayBack = true
        navigationController?.pushViewController(userProfileController, animated: true)
//
//        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
//        userProfileController.displayUserId = userId
//        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func extTapUserUid(uid: String, displayBack: Bool = false) {
//        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
//        userProfileController.displayUserId = uid
//        navigationController?.pushViewController(userProfileController, animated: true)
        
        let userProfileController = SingleUserProfileViewController()
        userProfileController.displayUserId = uid
        userProfileController.displayBack = displayBack
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func extShowUsersForPost(post: Post, following: Bool) {
        print("Display Vote Users| Following: ",following)
//        let postSocialController = PostSocialDisplayTableViewController()
//        postSocialController.displayUser = true
//        postSocialController.displayUserFollowing = following
//        postSocialController.inputPost = post
//        navigationController?.pushViewController(postSocialController, animated: true)
        
        let postSocialController = DisplayOnlyUsersSearchView()
        postSocialController.displayListOfUsers = true
        postSocialController.inputPost = post
        postSocialController.selectedScope = (post.followingVote.count > 0) ? 0 : 1
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    func extShowListsForPost(post: Post, following: Bool) {
        print("Display Lists| Following: ",following)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayList = true
        postSocialController.displayFollowing = (post.followingList.count > 0)
        postSocialController.inputPost = post
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    func extShowUsersFollowingList(list: List, following: Bool) {
        print("Display Users| Following: ",list.id)
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayUser = true
        postSocialController.displayUserFollowing = false
        postSocialController.inputList = list
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    func extTapLocation(post: Post) {
//        let locationController = LocationController()
//        locationController.selectedPost = post
        if let id = post.locationGooglePlaceID {
            Database.fetchLocationWithLocID(locId: id) { (location) in
                if location == nil {
                    Database.saveLocationToFirebase(post: post)
                    print("No Location - Creating New Location for \(post.locationName)")
                    var tempLoc = Location.init(post: post)
                    self.extTapLocation(location: tempLoc)
                } else {
                    self.extTapLocation(location: location!)
                }
            }
        } else {
            print("No Google ID: Creating temp loc from post \(post.id)")
            var tempLoc = Location.init(post: post)
            self.extTapLocation(location: tempLoc)
        }
        
        
        
    
//        let locationController = NewLocationController(collectionViewLayout: HomeSortFilterHeaderFlowLayout())
//
//        locationController.locationGPS = post.locationGPS
//        locationController.googlePlaceId = post.locationGooglePlaceID ?? ""
//        locationController.fetchPostForPostLocation()
//
//        navigationController?.pushViewController(locationController, animated: true)
    }
    
    func extTapLocation(googlePlaceId: String) {
        Database.fetchLocationWithLocID(locId: googlePlaceId) { (location) in
            if location == nil {
                print("ERROR - No Location For \(googlePlaceId)")
//                Database.saveLocationToFirebase(post: post)
//                print("No Location - Creating New Location for \(post.locationName)")
//                var tempLoc = Location.init(post: post)
//                self.extTapLocation(location: tempLoc)
            } else {
                self.extTapLocation(location: location!)
            }
        }
        
//
//        let locationController = NewLocationController(collectionViewLayout: HomeSortFilterHeaderFlowLayout())
//        locationController.googlePlaceId = googlePlaceId
//        locationController.fetchPostForPostLocation()
//        print("extTapLocation \(googlePlaceId)")
//        navigationController?.pushViewController(locationController, animated: true)
    }
    
    func extTapLocation(location: Location) {
        let locationController = NewLocationController(collectionViewLayout: HomeSortFilterHeaderFlowLayout())
//        locationController.locationGPS = location.locationGPS
//        locationController.googlePlaceId = location.locationGoogleID
        locationController.location = location
        locationController.fetchPostForPostLocation()
        print("extTapLocation location \(location.locationName)")
        navigationController?.pushViewController(locationController, animated: true)
    }
    
    func extTapMessage(post: Post, users: [User] = [], messageThread: MessageThread? = nil) {
        let messageController = MessageController()
        messageController.post = post
        messageController.respondUser = users
        messageController.respondMessage = messageThread
        navigationController?.pushViewController(messageController, animated: true)
    }
    
    func extOpenMessage(message: MessageThread?, reload: Bool = false) {
        guard let message = message else {return}
        let threadMessageController = InboxMessageViewController(collectionViewLayout: UICollectionViewFlowLayout())
        
        // Loading in Thread ID Refetches the whole thing. Loading in only the messagethread doesn't refresh
        if reload {
            threadMessageController.messageThreadId = message.threadID
        } else {
            threadMessageController.messageThread = message
        }
        navigationController?.pushViewController(threadMessageController, animated: true)
    }
    
    func extEditPost(post:Post){
        let editPost = MultSharePhotoController()
        // Post Edit Inputs
        editPost.editPostInd = true
        editPost.editPost = post
        self.navigationController?.pushViewController(editPost, animated: true)
    }
    
    func extShowImage(inputImages: [UIImage]?) {
        // FUNCTION IS BROKE FOR NOW
        return
        var images = [SKPhoto]()
        
        guard let selectedImages = inputImages else {return}
        for image in selectedImages {
            let photo = SKPhoto.photoWithImage(image)// add some UIImage
            images.append(photo)
        }
        
        // 2. create PhotoBrowser Instance, and present from your viewController.
        SKPhotoBrowserOptions.displayCounterLabel = true
        SKPhotoBrowserOptions.displayBackAndForwardButton = true
        SKPhotoBrowserOptions.displayAction = true
        SKPhotoBrowserOptions.actionButtonTitles = ["Edit Photo"]
        SKPhotoBrowserOptions.swapCloseAndDeleteButtons = true
        //        SKPhotoBrowserOptions.enableSingleTapDismiss  = true
        SKPhotoBrowserOptions.bounceAnimation = true
        SKPhotoBrowserOptions.displayDeleteButton = true
        
        let browser = SKPhotoBrowser(photos: images)
//        browser.delegate = self
        browser.updateCloseButton(#imageLiteral(resourceName: "checkmark_teal").withRenderingMode(.alwaysOriginal), size: CGSize(width: 50, height: 50))
        
        browser.initializePageIndex(0)
        present(browser, animated: true, completion: {})
    }
    
    func extShowGoogleRating(rating: Double?, location: String?) {
//        guard let rating = rating else {return}
//        guard let location = location
        self.alert(title: "Google Rating", message: "\(location ?? "") Google Rating Is \(rating ?? 0)")

        
    }
    
    @objc func extActivateBrowser(website: String?){
        guard let website = website else {return}
        guard let url = URL(string: website) else {return}
        print("activateBrowser | \(url)")
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    @objc func extActivatePhone(phoneNumber: String?){
        print("Tapped Phone Icon \(phoneNumber)")

        guard let phoneNumber = phoneNumber else {return}
        guard let url = URL(string: "tel://\(phoneNumber)") else {return}
        
        if (UIApplication.shared.canOpenURL(url)) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                // Fallback on earlier versions
                UIApplication.shared.openURL(url as URL)

            }
        }
        
//        if #available(iOS 10.0, *) {
////            UIApplication.shared.open(url)
//            UIApplication.shared.open(url, options: [:], completionHandler: nil)
//            //UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
//        } else {
//            UIApplication.shared.openURL(url)
//        }
    }
    
    func extActivateAppleMap(post: Post?) {
        guard let post = post else {return}
        print("activateAppleMap | \(post.locationName) | \(post.locationAdress) | \(post.locationGPS)")
        guard let location = post.locationGPS else {return}
        
        let latitude: CLLocationDegrees = location.coordinate.latitude
        let longitude: CLLocationDegrees = location.coordinate.longitude

        let regionDistance:CLLocationDistance = 10000
        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        let regionSpan = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        var locationNameString: String!
        locationNameString = post.locationName
        mapItem.name = locationNameString
        mapItem.openInMaps(launchOptions: options)
    }
    
    func extActivateAppleMap(loc: Location?) {
        print("activateAppleMap | \(loc?.locationName)")
        guard let location = loc else {return}
        guard let coord = location.locationGPS else {return}

        let latitude: CLLocationDegrees = coord.coordinate.latitude
        let longitude: CLLocationDegrees = coord.coordinate.longitude

        let regionDistance:CLLocationDistance = 10000
        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        let regionSpan = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        var locationNameString: String!
        locationNameString = location.locationName
        mapItem.name = locationNameString
        mapItem.openInMaps(launchOptions: options)
    }
    
    
    func toggleMapView(){
        NotificationCenter.default.post(name: AppDelegate.SwitchToMapNotificationName, object: nil)
    }
    
    
    func alert(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func missingLocAlert() {
        let alert = UIAlertController(title: "Can't Sort By Nearest", message: "Missing current user location to sort posts by nearest. Please enable location access in settings.", preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in

            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }

            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)") // Prints true
                })
            }
        }
        
        let cancelAction = UIAlertAction(title: "OK", style: .cancel) { (_) -> Void in
        }
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)

        self.present(alert, animated: true) {
            print("DISPLAY Missing Location alert")
        }
    }
    
    @objc func alertClose(gesture: UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @objc func handleBack(){
        if let m = self.navigationController {
            self.navigationController?.popViewController(animated: true)
        } else if let m = self.presentingViewController {
            self.dismiss(animated: true) {
            }
        }
    }
    
    @objc func handleTransitionBack(){
        print("Handle Transition Back")
        self.navigationController?.popViewController(animated: true)
    }
    
    func showMessagingOptions(post: Post?){
        guard let post = post else {return}

        let optionsAlert = UIAlertController(title: "Share this post via email or IMessage. LegitList is not required to receive posts.", message: "", preferredStyle: UIAlertController.Style.alert)
        
        optionsAlert.addAction(UIAlertAction(title: "iMessage", style: .default, handler: { (action: UIAlertAction!) in
            // Allow Editing
            self.handleIMessage(post: post)
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Email", style: .default, handler: { (action: UIAlertAction!) in
            self.handleMessage(post: post)
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        present(optionsAlert, animated: true) {
            optionsAlert.view.superview?.isUserInteractionEnabled = true
            optionsAlert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.alertClose(gesture:))))
        }
        
    }
    
    func handleIMessage(post: Post?){
        guard let post = post else {return}
        if MFMessageComposeViewController.canSendText() == true {
            let recipients:[String] = []
            let messageController = MFMessageComposeViewController()
            guard let coord = post.locationGPS?.coordinate else {return}
            let url = "http://maps.apple.com/maps?saddr=\(coord.latitude),\(coord.longitude)"
            let convoString = post.locationName + " " + post.emoji + "\n" + post.locationAdress + " \n" + post.caption
            //+ "\n" + "- @\(post.user.username)"
            
            messageController.messageComposeDelegate = self as! MFMessageComposeViewControllerDelegate
            messageController.recipients = []
            messageController.body = convoString
            
            let sentImageUrl = post.imageUrls[0] ?? ""
            if let image = imageCache[sentImageUrl] {
                let png = image.pngData()
                messageController.addAttachmentData(png!, typeIdentifier: "public.png", filename: "image.png")
            }
            
            self.present(messageController, animated: true, completion: nil)
            print("IMessage")
        } else {
            self.alert(title: "ERROR", message: "Text Not Supported")
        }
    }
    
    func handleMessage(post: Post?){
        guard let post = post else {return}
//        let messageController = MessageController()
//        messageController.post = post
//        if let m = self.navigationController {
//            self.navigationController?.pushViewController(messageController, animated: true)
//        }
        
        let controller = SelectUserMessageController()
        controller.displayUserId = Auth.auth().currentUser?.uid
        controller.sendingPost = post
        if let m = self.navigationController {
            self.navigationController?.pushViewController(controller, animated: true)
        }
        
    }
    
    func extSignOutUser(){
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { (_) in
            
            do {
                if Auth.auth().currentUser?.isAnonymous == true {
                    let user = Auth.auth().currentUser
                    user?.delete { error in
                        if let error = error {
                            print("Error Deleting Guest User")
                        } else {
                            print("Guest User Deleted")
                        }
                    }
                }
                
                
                try Auth.auth().signOut()
                CurrentUser.clear()
                
                // Check provider ID to verify that the user has signed in with Apple
                if
                    let providerId = Auth.auth().currentUser?.providerData.first?.providerID,
                    providerId == "apple.com" {
                    // Clear saved user ID
                    UserDefaults.standard.set(nil, forKey: "appleAuthorizedUserIdKey")
                }
                
                
                let manager = LoginManager()
                try manager.logOut()
                self.extShowLogin()
                
            } catch let signOutErr {
                print("Failed to sign out:", signOutErr)
            }

        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func extDeleteUser(user: User){
        let username = user.username as! String
        let optionsAlert = UIAlertController(title: "Delete Account", message: "All the data for \(username) will be deleted from our databases.", preferredStyle: UIAlertController.Style.alert)
        
        optionsAlert.addAction(UIAlertAction(title: "Delete \(username)", style: .default, handler: { (action: UIAlertAction!) in
            self.extShowLogin()
            Database.deleteUser(user: user)
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        present(optionsAlert, animated: true) {
            optionsAlert.view.superview?.isUserInteractionEnabled = true
            optionsAlert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.alertClose(gesture:))))
        }
    }
    
    func extShowLogin() {
        let openAppController = OpenAppViewController()
        let navController = UINavigationController( rootViewController: openAppController)
        navController.isModalInPresentation = true
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    @objc func extShowNewUserOnboarding() {
        print("showOnboarding | \(newUserOnboarding)")
        if !newUserOnboarding {return}
        let welcomeView = NewUserOnboardView()
        let testNav = UINavigationController(rootViewController: welcomeView)
        self.present(testNav, animated: true, completion: nil)
        newUserOnboarding = false
//        NotificationCenter.default.post(name: MainTabBarController.showOnboarding, object: nil)
    }
    
    func extShowSignUp() {
        let signUpController = SignUpController()
        let loginController = LoginController()
        let navController = UINavigationController(rootViewController: loginController)
        navController.pushViewController(signUpController, animated: false)
        self.present(navController, animated: true, completion: nil)
    }
    
    func extShowNewUserFollowing() {
        print("extShowNewUserFollowing | \(newUserRecommend)")
        if !newUserRecommend {return}
        let followingController = NewUserOnboardViewFollowing()
        let navController = UINavigationController(rootViewController: followingController)
        self.present(navController, animated: true, completion: nil)
        newUserRecommend = false
    }
    
    func extShowUserLikesForPost(inputPost: Post?, displayFollowing: Bool = true) {
        print("ext Show Users Liking Post | \(inputPost?.id) | \(displayFollowing)")
        
        guard let inputPost = inputPost else {return}
        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.inputPost = inputPost

        postSocialController.displayUser = true
        postSocialController.displayUserFollowing = displayFollowing
        postSocialController.scopeBarOptions = FollowingSortOptions
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    func extShowUserListsForPost(inputPost: Post?, displayFollowing: Bool = true) {
        print("ext Show Users Listed Post | \(inputPost?.id) | \(displayFollowing)")

        let postSocialController = PostSocialDisplayTableViewController()
        postSocialController.displayList = true
        postSocialController.inputPost = inputPost
        postSocialController.displayFollowing = displayFollowing
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    func extShowUserFollowers(inputUser: User?) {
        guard let inputUser = inputUser else {return}
        print("Ext Show Follower User| ",inputUser.uid)
        //let postSocialControllert = PostSocialDisplayTableViewController()
//        postSocialController.displayUser = true
//        postSocialController.displayUserFollowing = false
//        postSocialController.inputUser = inputUser
//        postSocialController.scopeBarOptions = FollowingSortOptions
        
        let postSocialController = DisplayOnlyUsersSearchView()
        postSocialController.displayListOfUsers = true
        postSocialController.inputUser = inputUser
        postSocialController.selectedScope = 1
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    
    func extShowUserFollowing(inputUser: User?) {
        guard let inputUser = inputUser else {return}
        print("Ext Show Following User| ",inputUser.uid)
//        let postSocialController = PostSocialDisplayTableViewController()
//        postSocialController.displayUser = true
//        postSocialController.displayUserFollowing = true
//        postSocialController.inputUser = inputUser
//        postSocialController.scopeBarOptions = FollowingSortOptions
        
        let postSocialController = DisplayOnlyUsersSearchView()
        postSocialController.displayListOfUsers = true
        postSocialController.inputUser = inputUser
        postSocialController.selectedScope = 0
        navigationController?.pushViewController(postSocialController, animated: true)
    }
    
    func extShowUserLists(inputUser: User?) {
        guard let inputUser = inputUser else {return}
//        let tabListController = NewTabListViewController()
//        tabListController.displayUser = inputUser
//        tabListController.displayBack = true
        
        let listViewNew = ListViewControllerNew()
        listViewNew.inputUser = inputUser
        listViewNew.fetchLists()
        self.navigationController?.pushViewController(listViewNew, animated: true)

//        let postSocialController = DisplayOnlyUsersSearchView()
//        postSocialController.displayListsByUser = true
//        postSocialController.inputUser = inputUser
//        postSocialController.selectedScope = 0
//        self.navigationController?.pushViewController(postSocialController, animated: true)
    }
    
        func extDisplayExtraRatingInfo(){
//            extraRatingEmojiLabel.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            
            UIView.animate(withDuration: 1.0,
                           delay: 0,
                           usingSpringWithDamping: 0.2,
                           initialSpringVelocity: 6.0,
                           options: .allowUserInteraction,
                           animations: { [weak self] in
//                            self?.extraRatingEmojiLabel.transform = .identity
                },
                           completion: nil
            )
            
            self.alert(title: "Ratings Emojis", message: """
    Rating Emojis help you describe your experience beyond just star ratings
    🥇 : Best
    💯 : 100%
    🔥 : Fire
    👌 : Legit
    😍 : Awesome
    😡 : Angry
    💩 : Poop
    """)
        }
    
    func extShowLocationHours(hours: [JSON]?){
            print("LocationController | locationHoursIconTapped")

            let presentedViewController = LocationHoursViewController()
            presentedViewController.hours = hours
            presentedViewController.setupViews()
            presentedViewController.providesPresentationContextTransitionStyle = true
            presentedViewController.definesPresentationContext = true
            presentedViewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            presentedViewController.modalTransitionStyle = .crossDissolve
            presentedViewController.view.backgroundColor = UIColor.clear

            //presentedViewController.view.backgroundColor = UIColor.init(white: 0.4, alpha: 0.8)
            self.present(presentedViewController, animated: true, completion: nil)
            
        }
    
    func extOpenLegitTerms() {
        guard let url = URL(string: "https://pages.flycricket.io/legit/terms.html") else { return }
        UIApplication.shared.open(url)
    }
    
    func extOpenLegitPrivacy() {
        guard let url = URL(string: "https://pages.flycricket.io/legit/privacy.html") else { return }
        UIApplication.shared.open(url)
    }
    
    func extOpenLegitEULA() {
        guard let url = URL(string: "https://www.legitapp.co/post/legit-eula") else { return }
        UIApplication.shared.open(url)
    }
        
    

    
    // BLOCK AND REPORTING
    
    func extBlockPost(post:Post){
        
        let blockAlert = UIAlertController(title: "Block Post", message: "Block Post and never see it again?", preferredStyle: UIAlertController.Style.alert)
        blockAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            // Remove from Current View
            self.dismiss(animated: true, completion: nil)
            self.navigationController?.popToRootViewController(animated: true)
            Database.blockPost(post: post)
        }))
        
        blockAlert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        present(blockAlert, animated: true, completion: nil)
    }
    
    func extReportPost(post:Post){
        
        let reportAlert = UIAlertController(title: "Report Post", message: "Report Post to the team? Post will be blocked if reported more than 5 times.", preferredStyle: UIAlertController.Style.alert)
        reportAlert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Please enter more details"
        }
        
        reportAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            // Remove from Current View
            self.dismiss(animated: true, completion: nil)
            self.navigationController?.popToRootViewController(animated: true)
            let details = reportAlert.textFields![0].text ?? ""

            Database.reportPost(post: post, details: details)
        }))
        
        reportAlert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        present(reportAlert, animated: true, completion: nil)
    }
    
    func extBlockAndReportPost(post:Post){
        
        let blockAlert = UIAlertController(title: "Block And Report Post", message: "Block and Report Post and never see it again?", preferredStyle: UIAlertController.Style.alert)
        blockAlert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Please enter more details"
        }
        blockAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            // Remove from Current View
            self.dismiss(animated: true, completion: nil)
            self.navigationController?.popToRootViewController(animated: true)
            let details = blockAlert.textFields![0].text ?? ""

            Database.reportPost(post: post, details: details)
            Database.blockPost(post: post)
        }))
        
        blockAlert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        present(blockAlert, animated: true, completion: nil)
    }
    
    func extBlockUser(user:User){
        
        let name = user.username ?? ""
        let isBlocked = user.isBlockedByCurUser ?? false
        
        var titleText = isBlocked ? "Blocked User" : "Block User"
        var bodyText = isBlocked ? "Unblock User \(name)?" : "Block User \(name) and never see them again?"
        
        let blockAlert = UIAlertController(title: titleText, message: bodyText, preferredStyle: UIAlertController.Style.alert)
        
        blockAlert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        blockAlert.addAction(UIAlertAction(title: isBlocked ? "Unblock" : "Block", style: .default, handler: { (action: UIAlertAction!) in
            // Remove from Current View

            if isBlocked {
                Database.unBlockUser(user: user)
            } else {
                self.dismiss(animated: true, completion: nil)
                self.navigationController?.popToRootViewController(animated: true)
                Database.blockUser(user: user)
            }
        }))

        let gotBlockedAlert = UIAlertController(title: "Blocked User", message: "You have been blocked by the user", preferredStyle: UIAlertController.Style.alert)
        
        gotBlockedAlert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        if user.isBlockedByUser {
            present(gotBlockedAlert, animated: true, completion: nil)
        } else {
            present(blockAlert, animated: true, completion: nil)
        }
        
    }
    
    func extReportUser(user:User){
        
        let reportAlert = UIAlertController(title: "Report User", message: "Report User to the team? User will be set to private if reported more than 5 times.", preferredStyle: UIAlertController.Style.alert)
        reportAlert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Please enter more details"
        }
        
        
        reportAlert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        reportAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            // Remove from Current View
            self.dismiss(animated: true, completion: nil)
            self.navigationController?.popToRootViewController(animated: true)
            let details = reportAlert.textFields![0].text ?? ""

            Database.reportUser(user: user, details: details)
        }))

        present(reportAlert, animated: true, completion: nil)
    }
//    
//    func extUserSettings(user: User?){
//       guard let uid = Auth.auth().currentUser?.uid else {return}
//        guard let user = user else {return}
//        
//        if uid != user.uid {
//           return
//       }
//       
//       let optionsAlert = UIAlertController(title: "User Options", message: "", preferredStyle: UIAlertController.Style.alert)
//       
//       optionsAlert.addAction(UIAlertAction(title: "Change Profile Picture", style: .default, handler: { (action: UIAlertAction!) in
//           // Allow Editing
//           self.editUser()
//       }))
//       
//       optionsAlert.addAction(UIAlertAction(title: "Edit User", style: .default, handler: { (action: UIAlertAction!) in
//           // Allow Editing
//           self.editUser()
//       }))
//       
//       optionsAlert.addAction(UIAlertAction(title: "Sign Out", style: .default, handler: { (action: UIAlertAction!) in
//           self.didSignOut()
//       }))
//       
//       optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
//           print("Handle Cancel Logic here")
//       }))
//       
//       present(optionsAlert, animated: true) {
//           optionsAlert.view.superview?.isUserInteractionEnabled = true
//           optionsAlert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.alertClose(gesture:))))
//       }
//
//   }
//    
//    func extEditUser(user: User?){
//        guard let user = user else {return}
//        let editUserView = SignUpController()
//        editUserView.delegate = self
//        editUserView.editUserInd = true
//        editUserView.editUser = self.displayUser
//        editUserView.cancelButton.isHidden = false
////        navigationController?.pushViewController(editUserView, animated: true)
//        self.present(editUserView, animated: true, completion: nil)
//    }
    
    
    
    
//    func expiringAlert(title: String,)
    
}

class NavBarMapButton: UIButton {
    
    var isColor = false {
        didSet {
            self.setImage((isColor ? #imageLiteral(resourceName: "google_color") : #imageLiteral(resourceName: "map") ).withRenderingMode(.alwaysTemplate), for: .normal)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
//        self.setImage((#imageLiteral(resourceName: "google_color").resizeImageWith(newSize: CGSize(width: 25, height: 25))).withRenderingMode(.alwaysOriginal), for: .normal)
//        self.setImage((#imageLiteral(resourceName: "map").resizeImageWith(newSize: CGSize(width: 30, height: 30))).withRenderingMode(.alwaysOriginal), for: .normal)
    
        self.setImage(#imageLiteral(resourceName: "map").withRenderingMode(.alwaysTemplate), for: .normal)
        self.tintColor = UIColor.ianBlackColor()
//        self.layer.backgroundColor = UIColor.white.cgColor
        self.layer.cornerRadius = 0
        self.setTitleColor(UIColor.ianBlackColor(), for: .normal)
        self.titleLabel?.font = UIFont(font: .avenirNextBold, size: 12)
        self.setTitle(" Map ", for: .normal)
        self.contentHorizontalAlignment = .left
        self.contentEdgeInsets = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
        
        self.layer.borderColor = self.titleLabel?.textColor.cgColor
        self.layer.borderWidth = 0
        self.clipsToBounds = true
        //        button.layer.backgroundColor = UIColor.selectedColor().withAlphaComponent(0.8).cgColor
//        self.layer.backgroundColor = UIColor.lightGray.cgColor
//        self.layer.backgroundColor = UIColor.clear.cgColor
        
//        self.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
//        self.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
//        self.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class NavButtonTemplate: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.backgroundColor = UIColor.clear.cgColor
        self.layer.borderColor = UIColor.ianLegitColor().cgColor
        self.layer.borderWidth = 0
        self.layer.cornerRadius = 2
        self.clipsToBounds = true
        self.contentHorizontalAlignment = .center
        self.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        self.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 14)
        self.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        self.setTitle("BUTTON", for: .normal)
        
//        let navShareTitle = NSAttributedString(string: "SHARE", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 10)])
//        self.setAttributedTitle(navShareTitle, for: .normal)
        
        self.tintColor = UIColor.ianLegitColor()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class navShareButtonTemplate: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.backgroundColor = UIColor.white.cgColor
        self.layer.borderColor = UIColor.ianLegitColor().cgColor
        self.layer.borderWidth = 0
        self.layer.cornerRadius = 2
        self.clipsToBounds = true
        self.contentHorizontalAlignment = .center
        self.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
        let navShareTitle = NSAttributedString(string: " SHARE ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 12)])
        self.setAttributedTitle(navShareTitle, for: .normal)
        self.setImage((#imageLiteral(resourceName: "navShareImage").resizeImageWith(newSize: CGSize(width: 10, height: 10))).withRenderingMode(.alwaysTemplate), for: .normal)
        
        self.tintColor = UIColor.legitColor()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class navBackButtonTemplate: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.backgroundColor = UIColor.clear.cgColor
        self.layer.borderColor = UIColor.gray.cgColor
        self.layer.borderWidth = 0
        self.layer.cornerRadius = 5
        self.clipsToBounds = true
        self.contentHorizontalAlignment = .center
        self.contentEdgeInsets = UIEdgeInsets(top: 2, left: 5, bottom: 2, right: 5)
        
        let navShareTitle = NSAttributedString(string: " BACK ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 12)])
        self.setAttributedTitle(navShareTitle, for: .normal)
        let icon = #imageLiteral(resourceName: "back_icon").withRenderingMode(.alwaysTemplate)

        self.setImage(icon, for: .normal)
        self.tintColor = UIColor.ianBlackColor()

//        self.setImage((#imageLiteral(resourceName: "navBackImage").resizeImageWith(newSize: CGSize(width: 15, height: 15))).withRenderingMode(.alwaysTemplate), for: .normal)
//        self.tintColor = UIColor.ianLegitColor()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class navButtonTemplate: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.backgroundColor = UIColor.white.cgColor
        self.layer.borderColor = UIColor.ianLegitColor().cgColor
        self.layer.borderWidth = 0
        self.layer.cornerRadius = 2
        self.clipsToBounds = true
        self.contentHorizontalAlignment = .center
        self.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
        let navShareTitle = NSAttributedString(string: " Next ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 12)])
        self.setAttributedTitle(navShareTitle, for: .normal)
//        self.setImage((#imageLiteral(resourceName: "navBackImage").resizeImageWith(newSize: CGSize(width: 10, height: 10))).withRenderingMode(.alwaysTemplate), for: .normal)
        
        self.tintColor = UIColor.ianLegitColor()
        
        self.titleLabel?.font =  UIFont(name: "Poppins-Bold", size: 12)
        self.titleLabel?.textColor = UIColor.ianLegitColor()
        
//        let navShareTitle = NSAttributedString(string: " BACK ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 12)])
//        self.setAttributedTitle(navShareTitle, for: .normal)
//        self.setImage((#imageLiteral(resourceName: "navBackImage").resizeImageWith(newSize: CGSize(width: 10, height: 10))).withRenderingMode(.alwaysTemplate), for: .normal)
//
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class currentUserProfileImageView: CustomImageView {
    init(imageUrl: String?) {
        super.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        guard let imageUrl = imageUrl else {return}
        self.loadImage(urlString: imageUrl)
        self.layer.cornerRadius = 30/2
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 1
        self.clipsToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class NavUserProfileButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setImage((#imageLiteral(resourceName: "empty_profile").resizeImageWith(newSize: CGSize(width: 35, height: 35))).withRenderingMode(.alwaysOriginal), for: .normal)
        self.layer.cornerRadius = 35/2
        self.setTitleColor(UIColor.white, for: .normal)
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 1
        self.clipsToBounds = true
    }
    
    func setProfileImage(imageUrl: String?) -> () {
        guard let imageUrl = imageUrl else {return}
        
        if let cachedImage = imageCache[imageUrl] {
            self.setImage((cachedImage.resizeImageWith(newSize: CGSize(width: 35, height: 35))).withRenderingMode(.alwaysOriginal), for: .normal)

//            self.setImage(cachedImage, for: .normal)
            return
        }
        
        guard let url = URL(string: imageUrl) else {return}
        
        URLSession.shared.dataTask(with: url) { (data, response, err) in
            if let err = err {
                print("Failed to fetch post image:", err)
                return
            }
            
            guard let imageData = data else {
                return}
            
            guard let tempImage = UIImage(data: imageData) else {return}
            
//            let photoImage = UIImage(data: imageData)?.resizeVI(newSize: defaultPhotoResize)
            
            imageCache[url.absoluteString] = tempImage
            
            DispatchQueue.main.async {
                self.setImage((tempImage.resizeImageWith(newSize: CGSize(width: 35, height: 35))).withRenderingMode(.alwaysOriginal), for: .normal)

//                self.setImage(photoImage, for: .normal)
            }
            
            }.resume()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class DynamicHeightCollectionView: UICollectionView {
    override func layoutSubviews() {
        super.layoutSubviews()
        if !bounds.size.equalTo(self.intrinsicContentSize){
            self.invalidateIntrinsicContentSize()
        }
    }
    override var intrinsicContentSize: CGSize {
        return contentSize
    }
}

class PaddedTextField: UITextField {
    
    let padding = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 15);
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
}

class PaddedUILabel: UILabel {
    
    var textInsets = UIEdgeInsets.init(top: 5, left: 15, bottom: 5, right: 15) {
        didSet { invalidateIntrinsicContentSize() }
    }
    
    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insetRect = bounds.inset(by: textInsets)
        let textRect = super.textRect(forBounds: insetRect, limitedToNumberOfLines: numberOfLines)
        let invertedInsets = UIEdgeInsets(top: -textInsets.top,
                                          left: -textInsets.left,
                                          bottom: -textInsets.bottom,
                                          right: -textInsets.right)
        return textRect.inset(by: invertedInsets)
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }
    
//    override func drawText(in rect: CGRect) {
//        let insets = UIEdgeInsets.init(top: 0, left: 15, bottom: 0, right: 15)
//        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
//    }
    
    func heightForView(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()
        
        return label.frame.height
    }
}

class LightPaddedUILabel: UILabel {
    
    var textInsets = UIEdgeInsets.init(top: 1, left: 5, bottom: 1, right: 5) {
        didSet { invalidateIntrinsicContentSize() }
    }
    
    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insetRect = bounds.inset(by: textInsets)
        let textRect = super.textRect(forBounds: insetRect, limitedToNumberOfLines: numberOfLines)
        let invertedInsets = UIEdgeInsets(top: -textInsets.top,
                                          left: -textInsets.left,
                                          bottom: -textInsets.bottom,
                                          right: -textInsets.right)
        return textRect.inset(by: invertedInsets)
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }
    
    //    override func drawText(in rect: CGRect) {
    //        let insets = UIEdgeInsets.init(top: 0, left: 15, bottom: 0, right: 15)
    //        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    //    }
    
    func heightForView(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()
        
        return label.frame.height
    }
}

class CirclePaddedUILabel: UILabel {
    
    var textInsets = UIEdgeInsets.init(top: 3, left: 3, bottom: 3, right: 3) {
        didSet { invalidateIntrinsicContentSize() }
    }
    
    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insetRect = bounds.inset(by: textInsets)
        let textRect = super.textRect(forBounds: insetRect, limitedToNumberOfLines: numberOfLines)
        let invertedInsets = UIEdgeInsets(top: -textInsets.top,
                                          left: -textInsets.left,
                                          bottom: -textInsets.bottom,
                                          right: -textInsets.right)
        return textRect.inset(by: invertedInsets)
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }
    
    //    override func drawText(in rect: CGRect) {
    //        let insets = UIEdgeInsets.init(top: 0, left: 15, bottom: 0, right: 15)
    //        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    //    }
    
    func heightForView(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()
        
        return label.frame.height
    }
}


class RightButtonPaddedUILabel: UILabel {
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets.init(top: 0, left: 15, bottom: 0, right: 20)
        super.drawText(in: rect.inset(by: insets))
    }
    
    func heightForView(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 2
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()
        
        return label.frame.height
    }
}

extension UIImage{

    func imageWithColor(color: UIColor) -> UIImage {
        let rect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 1, height: 1), false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
    

    func resizeImageWith(newSize: CGSize) -> UIImage {
        
        let horizontalRatio = newSize.width / size.width
        let verticalRatio = newSize.height / size.height
        
        let ratio = max(horizontalRatio, verticalRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1)
        draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: newSize))
        
        UIColor.clear.setFill()
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    func resizeVI(newSize:CGSize) -> UIImage? {
        let cgImage = self.cgImage!
        
        var format = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 32, colorSpace: nil,
                                          bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue),
                                          version: 0, decode: nil, renderingIntent: CGColorRenderingIntent.defaultIntent)
        var sourceBuffer = vImage_Buffer()
        defer {
            sourceBuffer.data.deallocate()
//            dealloc(Int(sourceBuffer.height) * Int(sourceBuffer.height) * 4)
        }
        
        var error = vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, cgImage, numericCast(kvImageNoFlags))
        guard error == kvImageNoError else { return nil }
        
        // create a destination buffer
        let horizontalRatio = newSize.width / size.width
        let verticalRatio = newSize.height / size.height
        
        let ratio = max(horizontalRatio, verticalRatio)
        
        let scale = self.scale
        let destWidth = Int(size.width * ratio)
        let destHeight = Int(size.height * ratio)
        let bytesPerPixel = self.cgImage!.bitsPerPixel / 8
        let destBytesPerRow = destWidth * bytesPerPixel
        let destData = UnsafeMutablePointer<UInt8>.allocate(capacity: destHeight * destBytesPerRow)
        defer {
//            destData.deallocate(capacity: destHeight * destBytesPerRow)
            destData.deallocate()

        }
        var destBuffer = vImage_Buffer(data: destData, height: vImagePixelCount(destHeight), width: vImagePixelCount(destWidth), rowBytes: destBytesPerRow)
        
        // scale the image
        error = vImageScale_ARGB8888(&sourceBuffer, &destBuffer, nil, numericCast(kvImageHighQualityResampling))
        guard error == kvImageNoError else { return nil }
        
        // create a CGImage from vImage_Buffer
        let destCGImage = vImageCreateCGImageFromBuffer(&destBuffer, &format, nil, nil, numericCast(kvImageNoFlags), &error)?.takeRetainedValue()
        guard error == kvImageNoError else { return nil }
        
        // create a UIImage
//        let horizontalRatio = newSize.width / size.width
//        let verticalRatio = newSize.height / size.height
//
//        let ratio = max(horizontalRatio, verticalRatio)
        

        let resizedImage = destCGImage.flatMap { UIImage(cgImage: $0, scale: 0, orientation: self.imageOrientation) }
        return resizedImage
    }
    
    
        func alpha(_ value:CGFloat) -> UIImage {
            UIGraphicsBeginImageContextWithOptions(size, false, scale)
            draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage!
        }
    
    func colorImage(with color: UIColor) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        UIGraphicsBeginImageContext(self.size)
        let contextRef = UIGraphicsGetCurrentContext()

        contextRef?.translateBy(x: 0, y: self.size.height)
        contextRef?.scaleBy(x: 1.0, y: -1.0)
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)

        contextRef?.setBlendMode(CGBlendMode.normal)
        contextRef?.draw(cgImage, in: rect)
        contextRef?.setBlendMode(CGBlendMode.sourceIn)
        color.setFill()
        contextRef?.fill(rect)

        let coloredImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return coloredImage
    }
    
}


extension Array where Element: Hashable {
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }

}


extension UIScrollView {
    var currentPage: Int {
        return Int((self.contentOffset.x + (0.5*self.frame.size.width))/self.frame.width)+1
    }
}

extension MKMapView {
    
    // function returns current zoom level of the map
    
    func getCurrentZoom() -> Double {
        
        var angleCamera = self.camera.heading
        if angleCamera > 270 {
            angleCamera = 360 - angleCamera
        } else if angleCamera > 90 {
            angleCamera = fabs(angleCamera - 180)
        }
        
        let angleRad = M_PI * angleCamera / 180
        
        let width = Double(self.frame.size.width)
        let height = Double(self.frame.size.height)
        
        let offset : Double = 20 // offset of Windows (StatusBar)
        let spanStraight = width * self.region.span.longitudeDelta / (width * cos(angleRad) + (height - offset) * sin(angleRad))
        return log2(360 * ((width / 256) / spanStraight)) + 1;
    }
    
}

extension UISegmentedControl{
    func removeBorder(){
        let backgroundImage = UIImage.getColoredRectImageWith(color: UIColor.white.cgColor, andSize: self.bounds.size)
        self.setBackgroundImage(backgroundImage, for: .normal, barMetrics: .default)
        self.setBackgroundImage(backgroundImage, for: .selected, barMetrics: .default)
        self.setBackgroundImage(backgroundImage, for: .highlighted, barMetrics: .default)
        
        let deviderImage = UIImage.getColoredRectImageWith(color: UIColor.white.cgColor, andSize: CGSize(width: 1.0, height: self.bounds.size.height))
        self.setDividerImage(deviderImage, forLeftSegmentState: .selected, rightSegmentState: .normal, barMetrics: .default)
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .normal)
        self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: 14), NSAttributedString.Key.paragraphStyle: paragraph], for: .selected)
    }
    
    func addUnderlineForSelectedSegment(){
        removeBorder()
        let underlineWidth: CGFloat = self.bounds.width / CGFloat(self.numberOfSegments)
        let underlineHeight: CGFloat = 3.0
        let underlineXPosition = CGFloat(selectedSegmentIndex * Int(underlineWidth))
        let underLineYPosition = self.bounds.size.height - 1.0
        let underlineFrame = CGRect(x: underlineXPosition, y: underLineYPosition, width: underlineWidth, height: underlineHeight)
        let underline = UIView(frame: underlineFrame)
        underline.backgroundColor = UIColor.ianLegitColor()
        underline.tag = 1
        self.addSubview(underline)
    }
    
    func changeUnderlinePosition(){
        guard let underline = self.viewWithTag(1) else {return}
        let underlineFinalXPosition = (self.bounds.width / CGFloat(self.numberOfSegments)) * CGFloat(selectedSegmentIndex)
        UIView.animate(withDuration: 0.1, animations: {
            underline.frame.origin.x = underlineFinalXPosition
        })
    }
}

extension UIImage{
    
    class func getColoredRectImageWith(color: CGColor, andSize size: CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let graphicsContext = UIGraphicsGetCurrentContext()
        graphicsContext?.setFillColor(color)
        let rectangle = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        graphicsContext?.fill(rectangle)
        let rectangleImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rectangleImage!
    }
}

extension UISearchBar {
    public func setSerchTextcolor(color: UIColor) {
        let clrChange = subviews.flatMap { $0.subviews }
        guard let sc = (clrChange.filter { $0 is UITextField }).first as? UITextField else { return }
        sc.textColor = color
        sc.layer.borderColor = color.cgColor
        sc.layer.borderWidth = 0
        sc.layer.cornerRadius = 10
        sc.layer.masksToBounds = true
    }
    
    func getTextField() -> UITextField? { return value(forKey: "searchField") as? UITextField }
    func setTextFieldBackground(color: UIColor) {
        guard let textField = getTextField() else { return }
        switch searchBarStyle {
        case .minimal:
            textField.layer.backgroundColor = color.cgColor
            textField.layer.cornerRadius = 10
            textField.clipsToBounds = true
            if let backgroundview = textField.subviews.first {
                // Rounded corner
                backgroundview.layer.cornerRadius = 10;
                backgroundview.clipsToBounds = true;
            }
        case .prominent, .default: textField.backgroundColor = color
        @unknown default: break
        }
    }
}

extension UINavigationController {
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return topViewController?.preferredStatusBarStyle ?? .default
    }
}

extension UITableView {

    func setBottomInset(to value: CGFloat) {
        let edgeInset = UIEdgeInsets(top: 0, left: 0, bottom: value, right: 0)

        self.contentInset = edgeInset
        self.scrollIndicatorInsets = edgeInset
    }
}

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}

extension CLLocationCoordinate2D {
  func middleLocationWith(location:CLLocationCoordinate2D) -> CLLocationCoordinate2D {

   let lon1 = longitude * M_PI / 180
   let lon2 = location.longitude * M_PI / 180
   let lat1 = latitude * M_PI / 180
   let lat2 = location.latitude * M_PI / 180
   let dLon = lon2 - lon1
   let x = cos(lat2) * cos(dLon)
   let y = cos(lat2) * sin(dLon)

   let lat3 = atan2( sin(lat1) + sin(lat2), sqrt((cos(lat1) + x) * (cos(lat1) + x) + y * y) )
   let lon3 = lon1 + atan2(y, cos(lat1) + x)

   let center:CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat3 * 180 / M_PI, lon3 * 180 / M_PI)
   return center
  }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
