//
//  MainTabBarController.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/26/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit

import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth
import Photos
import CoreLocation
import TLPhotoPicker
import BSImagePicker
import SVProgressHUD
import GeoFire
import FirebaseDatabase
import FirebaseAuth
import UserNotifications

class TabBar: UITabBar {
    private var cachedSafeAreaInsets = UIEdgeInsets.zero
    
    override var safeAreaInsets: UIEdgeInsets {
        let insets = super.safeAreaInsets
        
        if insets.bottom < bounds.height {
            cachedSafeAreaInsets = insets
        }
        
        return cachedSafeAreaInsets
    }
}

class MainTabBarController: UITabBarController, UITabBarControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, TLPhotosPickerViewControllerDelegate, LoginControllerDelegate {
    

    static let NewNotificationName = NSNotification.Name(rawValue: "NewUnread")
    static let NewListNotificationName = NSNotification.Name(rawValue: "NewUnreadList")
    static let GoToHome = NSNotification.Name(rawValue: "GoToHome")
    static let tapHomeTabBarButtonNotificationName = NSNotification.Name(rawValue: "TapHomeBarButton")
    static let CurrentUserListLoaded = NSNotification.Name(rawValue: "CurrentUserListLoaded")
    static let OpenAddNewPhoto = NSNotification.Name(rawValue: "OpenAddNewPhoto")
    static let NewMessageName = NSNotification.Name(rawValue: "NewMessageName")
    static let showLoginScreen = NSNotification.Name(rawValue: "showLoginScreen")
    static let showOnboarding = NSNotification.Name(rawValue: "showOnboarding")
    static let newLocationUpdate = NSNotification.Name(rawValue: "locationUpdate")
    static let newUserPost = NSNotification.Name(rawValue: "newUserPost")
    static let newFollowedUserPost = NSNotification.Name(rawValue: "newFollowedUserPost")
    static let deleteList = NSNotification.Name(rawValue: "deleteList")
    static let deleteUserPost = NSNotification.Name(rawValue: "deleteUserPost")
    static let editUserPost = NSNotification.Name(rawValue: "editUserPost")
    static let showNearbyUsers = NSNotification.Name(rawValue: "showNearbyUsers")

    
    var imagePicker = UIImagePickerController()
    var selectedImage: UIImage? = nil

    var assets = [PHAsset]()
    var selectedAssets = [TLPHAsset]()
    var selectedTabBarIndex: Int? = nil

    // Final Variables
    var selectedImagesMult: [UIImage]? = []
    var selectedTime: Date? = nil
    var selectedPhotoLocation: CLLocation? = nil
    
    let LocationAuthview = LocationRequestViewController()
    
    func refreshPhotoVariables(){
        self.selectedImagesMult = []
        self.selectedPhotoLocation = nil
        self.selectedTime = nil
//        self.tabBarController?.selectedIndex == 0
    }
    

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let index = viewControllers?.firstIndex(of: viewController) else {
            print("Invalid Tab Bar Index")
            return
        }
        
        
        if index == 0 && index == self.selectedTabBarIndex {
            print("Double Click Home Tab Bar, Refreshing")
            NotificationCenter.default.post(name: MainTabBarController.tapHomeTabBarButtonNotificationName, object: nil)
            // Reselected Home Controller refresh
        }

        if index == 1 && index == self.selectedTabBarIndex {
            print("Double Click Home Tab Bar, Refreshing")
//            NotificationCenter.default.post(name: ExploreController.searchRefreshNotificationName, object: nil)
            // Reselected Search Controller refresh
        }
        
        if index == 3 {
            guard let uid = Auth.auth().currentUser?.uid else {return}
            print("List View Selected")
            let navController = viewController as! UINavigationController
//            let listView = navController.viewControllers[0] as! TabListViewController
//            listView.navigationController?.isNavigationBarHidden = true
//            listView.enableAddListNavButton = true
//            if listView.displayList.count == 0 {
//                listView.inputUserId = uid
//            }
            
//            let listView = navController.viewControllers[0] as! NewTabListViewController
//            listView.updateListObjects()
            
             let listView = navController.viewControllers[0] as! ListViewControllerNew
            listView.tableView.reloadData()
            
            
        }
        
        if index == 4 {
            let userNavController = viewController as! UINavigationController
//            let userView = userNavController.viewControllers[0] as! UserProfileController
//
//            if userView.displayUserId == nil {
//                print("User Profile Controller | No User UID | Default to Current User PostIds | \(CurrentUser.postIds.count)")
//                userView.fetchedPostIds = CurrentUser.postIds
//                userView.displayUserId = Auth.auth().currentUser?.uid
//                userView.enableSignOut = true
//                userView.displayBack = false
//            }
            
//            if let userView = userNavController.viewControllers[0] as! SingleUserProfileViewController
////            print("User Profile Controller | No User UID | Default to Current User PostIds | \(CurrentUser.postIds.count)")
////            userView.displayUserId = Auth.auth().currentUser?.uid
////            userView.displayBack = false
//            if userView.displayUser == nil {
//                print("User Profile Controller | No User UID | Default to Current User PostIds | \(CurrentUser.postIds.count)")
//                userView.displayUserId = Auth.auth().currentUser?.uid
//                userView.displayBack = false
//            }

        }
        
        selectedTabBarIndex = index
        print("---Tab Bar Selected----\(self.selectedTabBarIndex)")
        
        if firebaseUpdate {
            updateFirebaseData()
        }
    }
    

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        let index = viewControllers?.firstIndex(of: viewController)
        
        guard let curUser = Auth.auth().currentUser else {
            self.extShowLogin()
            return false
        }
        
        if (Auth.auth().currentUser?.isAnonymous)! && (index == 4 || index == 3){
            print("Guest User")
            var message = ""
            if index == 4 {
                message = "Please Sign Up To Access Your Profile"
            } else if index == 3 {
                message = "Please Sign Up To Upload Photo"
            }
            
            let alert = UIAlertController(title: "Guest Profile", message: message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            alert.addAction(UIAlertAction(title: "Sign Up", style: UIAlertAction.Style.cancel, handler: { (action: UIAlertAction!) in
                
                DispatchQueue.main.async {
                    let signUpController = SignUpController()
                    let loginController = LoginController()
                    let navController = UINavigationController(rootViewController: loginController)
                    navController.pushViewController(signUpController, animated: false)
                    self.present(navController, animated: true, completion: nil)
                }
            }))
            
            self.present(alert, animated: true, completion: nil)
            return false
        }
        
       /*
        if index == 2 {
            presentMultImagePicker()
            return false
        }
        */

        
        return true
    }
    
// PHOTO SELECTION
    
    @objc func presentMultImagePicker(){
        print("MainTabBarController | Open Multi Image Picker")
        let viewController = CustomPhotoPickerViewController()
        viewController.delegate = self
        viewController.didExceedMaximumNumberOfSelection = { [weak self] (picker) in
        self?.showExceededMaximumAlert(vc: picker)
        }
        var configure = TLPhotosPickerConfigure()
        configure.numberOfColumn = 3
        configure.maxSelectedAssets = 5
        configure.allowedVideo = false
        configure.allowedVideoRecording = false
        configure.usedPrefetch = true
        configure.autoPlay = false
        viewController.configure = configure
        viewController.selectedAssets = self.selectedAssets
        
        self.present(viewController, animated: true, completion: nil)
    }
    
    
    func processPHAssets(assets: [PHAsset], completion: @escaping ([UIImage]?, CLLocation?, Date?) -> ()){

        // use selected order, fullresolution image
        print("Processing \(assets.count) PHAssets")
        
        var assetlocations: [CLLocation?] = []
        var assetTimes:[Date?] = []
        
        var tempImages: [UIImage]? = []
        var tempLocation: CLLocation? = nil
        var tempDate: Date? = nil
        
        for asset in assets {
            tempImages?.append(self.getAssetThumbnail(asset: asset))
            assetlocations.append(asset.location)
            assetTimes.append(asset.creationDate)
            
            var image = self.getAssetThumbnail(asset: asset)

            
        }
        
        for location in assetlocations {
            if tempLocation == nil {
                if location != nil {
                    tempLocation = location
                }
            }
        }
        
        for time in assetTimes {
            if tempDate == nil {
                if time != nil {
                    tempDate = time
                }
            }
        }
    
        print("Images: \(tempImages?.count), Locations: \(assetlocations.count), Times: \(assetTimes) ")
        print("Final Location: \(tempLocation), Final Time: \(tempDate)")
        
        completion(tempImages, tempLocation, tempDate)

        // print("Selected Photo Time \(self.selectedTime), Location: \(self.selectedPhotoLocation)")
        
    }
    
    func getAssetThumbnail(asset: PHAsset) -> UIImage {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        option.resizeMode = .exact
        option.deliveryMode = .highQualityFormat;
        option.isNetworkAccessAllowed = true;
        option.progressHandler = { (progress, error, stop, info) in
            if(progress == 1.0){
                SVProgressHUD.dismiss()
            } else {
                SVProgressHUD.showProgress(Float(progress), status: "Downloading from iCloud")
            }
        }
        var thumbnail = UIImage()
        option.isSynchronous = true
        manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
            if let result = result {
                thumbnail = result
            }
        })
        return thumbnail
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tabBar.invalidateIntrinsicContentSize()
    }
    
    private var cachedSafeAreaInsets = UIEdgeInsets.zero
    
    @available(iOS 13.0, *)
    private func setTabBarItemColors(_ itemAppearance: UITabBarItemAppearance) {
        itemAppearance.normal.iconColor = UIColor.ianMiddleGrayColor()
        itemAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.ianMiddleGrayColor()]
        
        itemAppearance.selected.iconColor = UIColor.ianLegitColor()
        itemAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor()]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.delegate = self
        self.tabBar.barTintColor = UIColor.white
//        self.togglePremiumActivate()
        
        // REMOVE TRANSLUCENT TAB BAR INTRODUCED IN IOS15
        
        if #available(iOS 13.0, *) {
            let tabBarAppearance: UITabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithDefaultBackground()
            tabBarAppearance.backgroundColor = UIColor.white
            tabBarAppearance.selectionIndicatorTintColor = UIColor.ianLegitColor()
            setTabBarItemColors(tabBarAppearance.stackedLayoutAppearance)
            setTabBarItemColors(tabBarAppearance.inlineLayoutAppearance)
            setTabBarItemColors(tabBarAppearance.compactInlineLayoutAppearance)
            UITabBar.appearance().standardAppearance = tabBarAppearance

            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
        }
        
        
        let tabWidth = tabBar.frame.size.width
        let tabHeight = tabBar.frame.size.height
//        print("TAB BAR HEIGHT |",tabHeight)
        let imgSize = CGSize(width: tabBar.frame.size.width / 5,
                             height: tabBar.frame.size.height)
        UIGraphicsBeginImageContextWithOptions(imgSize, false, 0)
        let p = UIBezierPath(rect: CGRect(x: 0, y: 0, width: imgSize.width,
                                          height: imgSize.height))
        let margin = 2.0 as CGFloat
        let widthMargin = 6.0 as CGFloat
//        let circlePath = UIBezierPath(arcCenter: CGPoint.init(x: imgSize.width/2, y: imgSize.height/2), radius: tabBar.frame.size.height/2, startAngle: CGFloat(0), endAngle:CGFloat(M_PI * 2), clockwise: true)

//        let rectPath = UIBezierPath(roundedRect: CGRect(x: 0 + margin + widthMargin, y: 0 + margin, width: (tabWidth)/5 - 2 * (margin + widthMargin) , height: tabHeight - 2 * margin), cornerRadius: 5)

        let rectPath = UIBezierPath(rect: CGRect(x: 5, y: 0 + tabHeight , width: tabWidth - 10, height: 3))
//        let rectPath = UIBezierPath(rect: CGRect(x: 5, y: 30, width: tabWidth - 10, height: 3))
        UIColor.ianLegitColor().setFill()
        rectPath.fill()
        let finalImg = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.tabBar.selectionIndicatorImage = finalImg
        
        self.tabBar.unselectedItemTintColor = UIColor.ianMiddleGrayColor()
        self.tabBar.selectedImageTintColor = UIColor.ianLegitColor()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateUnreadNotifications), name: MainTabBarController.NewNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUnreadMessage), name: InboxController.newMsgNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(goToHome), name: MainTabBarController.GoToHome, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(presentMultImagePicker), name: MainTabBarController.OpenAddNewPhoto, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(presentLogin), name: MainTabBarController.showLoginScreen, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(extShowNewUserOnboarding), name: MainTabBarController.showOnboarding, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(requestLocation), name: AppDelegate.RequestLocationNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(requestNotification), name: AppDelegate.NotificationAccessRequest, object: nil)
        
        
//        NotificationCenter.default.addObserver(self, selector: #selector(updateUnreadNotifications), name: MainTabBarController.NewListNotificationName, object: nil)

        
//        NotificationCenter.default.addObserver(self, selector: #selector(setupViewControllers), name: AppDelegate.SuccessLoginNotificationName, object: nil)

        
//        self.tabBar.tintColor = UIColor.white
//        self.tabBar.backgroundColor = UIColor.white
//        self.loadCurrentUser()
        
//        for family: String in UIFont.familyNames
//        {
//            print(family)
//            for names: String in UIFont.fontNames(forFamilyName: family)
//            {
//                print("== \(names)")
//            }
//        }
        
//        print("FONT BLASTER | LOADED FONTS : ")
        FontBlaster.blast() { (fonts) in
//            print(fonts) // fonts is an array of Strings containing font names
        }

    }
    

    
    @objc func requestNotification(){
        let alert = UIAlertController(title: "Notification Access", message: "Legit needs permission to send you notifications when users like your posts or follow you", preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Allow", style: .default) { (_) -> Void in
            let center = UNUserNotificationCenter.current()
            center.getNotificationSettings { settings in
                let status = settings.authorizationStatus
                if status == .denied {
                    print("requestNotification - Status Denied so Open Settings")
                    SharedFunctions.openSettings()
                } else {
                    print("requestNotification - Requesting Notification")
                    SharedFunctions.registerForPushNotifications()
                }

            }
        }
        
        let cancelAction = UIAlertAction(title: "Not Now", style: .destructive) { (_) -> Void in
            print("Notification Denied")
        }
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)

        DispatchQueue.main.async {
            self.present(alert, animated: true) {
                print("DISPLAY requestNotification settings alert")
            }
        }

    }
    
    
    @objc func goToHome(){
        self.selectedTabBarIndex = 0
    }
    
    func checkForCurrentUser(){
        print("MainTabBar | CHECK CURRENT USER")
        if Auth.auth().currentUser == nil {
            DispatchQueue.main.async {
                self.presentLogin()
                return
            }
        }

    // NEW USER - NEW CURRENT USER ALREADY LOADED IN SIGN UP
        else if newUserOnboarding  {
            self.extShowNewUserOnboarding()
            successLogin()
        }
        
    // GUEST USER
        else if (Auth.auth().currentUser?.isAnonymous)!{
            guard let uid = Auth.auth().currentUser?.uid else {
                print("MainTabBar | Guest User ERROR | No UID")
                return
            }
            print("MainTabBar | Guest User | Setting Up ViewControllers")
            Database.setupGuestUser(uid: uid) {
                self.successLogin()
            }
        }

// NOT GUEST USER
        else if !(Auth.auth().currentUser?.isAnonymous)!{
            
            // Check if current logged in user uid actually exists in database
            guard let userUid = Auth.auth().currentUser?.uid else {return}
            
            let ref = Database.database().reference().child("users").child(userUid)
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
              
                guard let userDictionary = snapshot.value as? [String:Any] else {
                    print("MainTabBar | User Doesn't Exist | \(userUid)")
                    self.presentLogin()
                    return}
                
                let user = User(uid:userUid, dictionary: userDictionary)
                Database.loadCurrentUser(inputUser: user, completion: {
                    self.successLogin()
                })
            }){ (err) in print("Error Search User", err) }
        }

    }
    
//    @objc func showOnboarding(){
////        let welcomeView = NewUserOnboardingView()
//        print("MainTabBar showOnboarding")
//
//        let welcomeView = NewUserOnboardView()
//
//        let testNav = UINavigationController(rootViewController: welcomeView)
//        self.present(testNav, animated: true, completion: nil)
//        //        self.navigationController?.pushViewController(listView, animated: true)
//        
//    }
    
    @objc func presentLogin(){
        print("MainTabBar | No User | Display Login")
//        let loginController = LoginController()
//        loginController.delegate = self
        let loginController = OpenAppViewController()

        let navController = UINavigationController(rootViewController: loginController)
        navController.isModalInPresentation = true
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    func successLogin(){
        print("MainTabBar | Success Login | Setting Up View Controllers | \(Auth.auth().currentUser?.uid) | \(CurrentUser.username)")
        self.setupViewControllers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if CurrentUser.user == nil || viewControllers?.count != 5 {
            print("MainTabBarController | ViewWillAppear | Missing Current User | Load Current User")
            self.checkForCurrentUser()
            // DEFAULT SHOW PROFILE PAGE FOR NEW USER
            self.selectedIndex = 4
        }

//        else if CurrentUser.user?.uid != Auth.auth().currentUser?.uid {
//            print("MainTabBarController | ViewWillAppear | Current User Not Matching Current Auth User | New Login | Load User")
//            self.checkForCurrentUser()
//        }
    }
    
  
    @objc func setupViewControllers() {
        
        if newUserTest {
            newUserOnboarding = true
            newUserRecommend = true
        }
        
        // ONLY REQUIRES CURRENT USER UID LOADED
        
// 1. HOME
//        let homeController  = HomeController(collectionViewLayout: HomeSortFilterHeaderFlowLayout())
//        let homeNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "home_tab_unfill").withRenderingMode(.alwaysOriginal), selectedImage: #imageLiteral(resourceName: "home_tab_filled").withRenderingMode(.alwaysOriginal), title: "Home",rootViewController: homeController)

        let homeIcon = #imageLiteral(resourceName: "home").withRenderingMode(.alwaysTemplate)
//        let homeIconSelected = #imageLiteral(resourceName: "home").withRenderingMode(.alwaysOriginal)

//        let testHomeNavController = templateNavController(unselectedImage: homeIcon, selectedImage: homeIcon, title: "Home", rootViewController: TestHomeController())
        
//        let layouttest = StickyHeadersCollectionViewFlowLayout()
//        let userProfileControllerTest = UserProfileController(collectionViewLayout: layouttest)
//        let legitHomeView = LegitTestView()
        let layoutHome = ListViewControllerHeaderFlowLayout()
        let legitHomeView = LegitHomeView(collectionViewLayout: layoutHome)
        
        let testHomeNavController = templateNavController(unselectedImage: homeIcon, selectedImage: homeIcon, title: "Home", rootViewController: legitHomeView)

        
      
// 2. EXPLORE
//        let searchNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "globe_empty").withRenderingMode(.alwaysOriginal), selectedImage: #imageLiteral(resourceName: "globe_filled").withRenderingMode(.alwaysOriginal), title: "Explore", rootViewController: ExploreController(collectionViewLayout: HomeSortFilterHeaderFlowLayout()))
        
        let discoverController = TabSearchViewController()
        discoverController.fetchAllItems()
        let discoverIcon = #imageLiteral(resourceName: "discover").withRenderingMode(.alwaysTemplate)

        let discoverNavController = templateNavController(unselectedImage: discoverIcon, selectedImage: discoverIcon, title: "Discover", rootViewController: discoverController)

// 3. MAP BUTTON
        let mapImage = #imageLiteral(resourceName: "map").withRenderingMode(.alwaysTemplate)
//        let mapImage = #imageLiteral(resourceName: "location_color").withRenderingMode(.alwaysOriginal)

        let mapView = NewTabMapViewController()
//        mapView.fetchAllPostIds()
        let mapNavController = templateNavController(unselectedImage: mapImage, selectedImage: mapImage, title: "Map", rootViewController: mapView)

        
// 4. USER PROFILE
        
        let newUserProfile = SingleUserProfileViewController()
        newUserProfile.displayUserId =  Auth.auth().currentUser?.uid
        newUserProfile.showNewPostButton = true
        newUserProfile.displaySubscription = true
        newUserProfile.imageCollectionView.reloadData()
        let userProfileNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "profile_tab_unfilled").withRenderingMode(.alwaysTemplate), selectedImage: #imageLiteral(resourceName: "profile_tab_filled"), title: "Profile", rootViewController: newUserProfile)

        
// 5. USER NOTIFICATIONS
//        let userNotifications = TabNotificationViewController()
//        userNotifications.displayUserId = Auth.auth().currentUser?.uid
        let notificationIcon = #imageLiteral(resourceName: "alert").withRenderingMode(.alwaysTemplate)
        let listIcon = #imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate)

//
//        let userNotificationsNavController = templateNavController(unselectedImage: notificationIcon, selectedImage: notificationIcon, title: "Activity", rootViewController: userNotifications)
        
        let listViewNew = ListViewControllerNew()
        listViewNew.inputUid = Auth.auth().currentUser?.uid
        listViewNew.displayBack = false
//        listViewNew.fetchLists()
//        listViewNew.fetchallItems()
//        let discoverIconNew = #imageLiteral(resourceName: "listsHash").withRenderingMode(.alwaysTemplate)

        let userListNavController = templateNavController(unselectedImage: listIcon, selectedImage: listIcon, title: "Lists", rootViewController: listViewNew)


// FINAL TAB BAR
//        viewControllers = [testHomeNavController, discoverNavController, plusNavController, tabListNavController, userProfileNavController]
//        viewControllers = [testHomeNavController, discoverNavController, mapNavController, userNotificationsNavController, userProfileNavController]
        viewControllers = [testHomeNavController, mapNavController, discoverNavController, userListNavController, userProfileNavController]

        guard let items = tabBar.items else {return}
        
        for item in items {
            item.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -5)
        }

        
        updateUnreadNotifications()

        
        
//        let legit_img = #imageLiteral(resourceName: "legit").resizeImageWith(newSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysTemplate)
//        var legit_blank = UIImageView.init(image: legit_img)
//        legit_blank.tintColor = UIColor.white
       // viewControllers = [navController, UIViewController()]
    }
    

    // 3. ADD PHOTO
    //        let resizedImage = #imageLiteral(resourceName: "post").resizeImageWith(newSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
    //        let postImage = #imageLiteral(resourceName: "post").withRenderingMode(.alwaysTemplate)
    //        let plusNavController = templateNavController(unselectedImage: postImage, selectedImage: postImage, title: "Post")

    // 4. LIST TAB
    //        let tabListController = TabListViewController()
    //        tabListController.enableAddListNavButton = true
    //        tabListController.showNavBar = false
    //        var inputUserId: String?
    //        if (Auth.auth().currentUser?.isAnonymous) ?? false {
    //            print("TabListViewController | fetchListIds | Guest User | Defaulting to WZ")
    //            inputUserId = "2G76XbYQS8Z7bojJRrImqpuJ7pz2"
    //        } else {
    //            inputUserId = Auth.auth().currentUser?.uid
    //        }
    //        tabListController.inputUserId = inputUserId
    //
    //
    //        let newTabListController = NewTabListViewController()
    //        newTabListController.displayUserId = Auth.auth().currentUser?.uid
            
    //        let tabListNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "bookmark_white").withRenderingMode(.alwaysOriginal), selectedImage: #imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal), rootViewController: tabListController)
            
    //        let listIcon = #imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate)
    //        let tabListNavController = templateNavController(unselectedImage: listIcon, selectedImage: listIcon,  title: "Lists", rootViewController: newTabListController)
    //
    //        let layout = StickyHeadersCollectionViewFlowLayout()
    //        let userProfileController = UserProfileController(collectionViewLayout: layout)
    //        let userProfileNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "profile_tab_unfilled").withRenderingMode(.alwaysTemplate), selectedImage: #imageLiteral(resourceName: "profile_tab_filled"), title: "Profile", rootViewController: userProfileController)
    
    
    fileprivate func templateNavController(unselectedImage: UIImage, selectedImage: UIImage, title: String, rootViewController: UIViewController = UIViewController()) -> UINavigationController
    {
    
    let viewController = rootViewController
    let navController = UINavigationController(rootViewController: viewController)
        navController.tabBarItem.image = unselectedImage
        navController.tabBarItem.selectedImage = selectedImage
        navController.navigationBar.tintColor = UIColor.ianMiddleGrayColor()
        navController.navigationBar.barTintColor = UIColor.white
        navController.tabBarItem.title = title
        
        let navFont = UIFont(font: .avenirRoman, size: 11)
        
        let selectedColor = UIColor.ianLegitColor()

        

        let unselectedColor = UIColor.ianGrayColor()
        //        legitListTitle.font = UIFont(name: "TitilliumWeb-SemiBold", size: 20)
        
        navController.tabBarItem.setTitleTextAttributes(convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): unselectedColor, convertFromNSAttributedStringKey(NSAttributedString.Key.font): navFont]), for: .normal)
        
        navController.tabBarItem.setTitleTextAttributes(convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): selectedColor, convertFromNSAttributedStringKey(NSAttributedString.Key.font): navFont]), for: .selected)
        
    return navController
    }

    
    @objc func updateUnreadNotifications(){
        let unreadNotification = CurrentUser.unreadEventCount
        let unreadMsg = CurrentUser.unreadMessageCount

        let newListUpdates = CurrentUser.followedListNotifications.count
//        print("updateUnreadNotifications \(unread)")
        
        guard let items = tabBar.items else {return}
        if items.count < 5 {return}
        
        var total = unreadNotification + unreadMsg
        
        // LIST NOTIFICATIONS
        items[4].badgeValue = (total > 0) ? String(total) : nil
        
        if CurrentUser.unreadEventCount > 0 || CurrentUser.unreadMessageCount > 0 {
            print("MainTabBar | updateUnreadNotifications | New: \(total) | Events: \(CurrentUser.unreadEventCount) | Inbox \(CurrentUser.unreadMessageCount)")
        }

        
        // USER NOTIFICATIONS
       // items[0].badgeValue = unread > 0 ? String(unread) : nil

    }

    @objc func updateUnreadMessage(){
        let unread = CurrentUser.unreadMessageCount
        let newListUpdates = CurrentUser.followedListNotifications.count
//        print("updateUnreadNotifications \(unread)")
        let unreadNotification = CurrentUser.unreadEventCount
        let unreadMsg = CurrentUser.unreadMessageCount
        var total = unreadNotification + unreadMsg

        guard let items = tabBar.items else {return}
        if items.count < 5 {return}
        
        // LIST NOTIFICATIONS
        items[4].badgeValue = total > 0 ? String(total) : nil
        
        print("MainTabBar | updateUnreadNotifications | New: \(total) | Events: \(CurrentUser.unreadEventCount) | Inbox \(CurrentUser.unreadMessageCount)")

        
        // USER NOTIFICATIONS
       // items[0].badgeValue = unread > 0 ? String(unread) : nil

    }
    
    func dismissPhotoPicker(withPHAssets: [PHAsset]) {
        // if you want to used phasset.
        print("MainTabBarController | Dismiss Photo Picker | Process PHAssets")
        self.processPHAssets(assets: withPHAssets) { (images, location, date) in
            self.selectedImagesMult = images
            self.selectedPhotoLocation = location
            self.selectedTime = date
//            if let image = images?[0]{
//                Database.printImageSizes(image: image)
//            }
        }
    }
    
    func photoPickerDidCancel() {
        // cancel
    }
    
    func dismissComplete() {
        print("MainTabBarController | Dismiss Photo Picker | Complete")

        if (self.selectedImagesMult?.count)! > 0 {

            print("Final Upload. Pictures: \(self.selectedImagesMult!.count), Location: \(self.selectedPhotoLocation), Time: \(self.selectedTime)")

            let multSharePhotoController = UploadPhotoController()
            multSharePhotoController.selectedImages = self.selectedImagesMult
            multSharePhotoController.selectedImageLocation  = self.selectedPhotoLocation
            multSharePhotoController.selectedImageTime  = self.selectedTime
            let navController = UINavigationController(rootViewController: multSharePhotoController)
            self.present(navController, animated: false, completion: nil)
            self.refreshPhotoVariables()
        
        } else {
           print("No Picture Selected")
//            self.alert(title: "Error", message: "No Pictures Selected")
        }
        
    }
    
    func didExceedMaximumNumberOfSelection(picker: TLPhotosPickerViewController) {
        self.showExceededMaximumAlert(vc: picker)
    }
    
    func handleNoCameraPermissions(picker: TLPhotosPickerViewController) {
        let alert = UIAlertController(title: "", message: "No camera permissions granted", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showExceededMaximumAlert(vc: UIViewController) {
        let alert = UIAlertController(title: "", message: "Exceed Maximum Number Of Selection", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        vc.present(alert, animated: true, completion: nil)
    }
    
    
    func getAsyncCopyTemporaryFile() {
        if let asset = self.selectedAssets.first {
            asset.tempCopyMediaFile(progressBlock: { (progress) in
                print(progress)
            }, completionBlock: { (url, mimeType) in
                print(mimeType)
            })
        }
    }
    
    func getFirstSelectedImage() {
        if let asset = self.selectedAssets.first {
            
            if asset.type == .video {
                asset.videoSize(completion: { [weak self] (size) in
                    print("video file size\(size)")
                })
                return
            }
            if let image = asset.fullResolutionImage {
                print(image)
                print("local storage image")
                //                self.imageView.image = image
            }else {
                print("Can't get image at local storage, try download image")
                asset.cloudImageDownload(progressBlock: { [weak self] (progress) in
                    DispatchQueue.main.async {
                        print("download \(100*progress)%")
                        print(progress)
                    }
                    }, completionBlock: { [weak self] (image) in
                        if let image = image {
                            //use image
                            DispatchQueue.main.async {
                                print("complete download")
                                //                                self?.imageView.image = image
                            }
                        }
                })
            }
        }
    }
    
// UPDATE FIREBASE DATA
    
    var firebaseUpdate: Bool = false
    
    func updateFirebaseData(){
        let firebaseAlert = UIAlertController(title: "Firebase Update", message: "Do you want to update Firebase Data?", preferredStyle: UIAlertController.Style.alert)
        
        firebaseAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            self.checkUserPosts()
//            self.changeRatingEmoji()
//            self.revertBlockedPost()
//            self.addLocationTest()
//            self.avgGPSTest()
//            self.duplicateImages()
//            self.addBadgeForUsers()
//            self.updateListCode()
//            self.updateUserCode()
//            self.cleanUserDatabase()
//            self.fixImages()
//            self.fixFollowers()
//            self.deleteUsers()
            
        }))
        
        firebaseAlert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        self.present(firebaseAlert, animated: true)
    }
    
    func addBadgeForUsers() {
        
        Database.handleUserBadge(userUid: "2G76XbYQS8Z7bojJRrImqpuJ7pz2", badgeValue: 0, change: 1) {
        }
        
        Database.handleUserBadge(userUid: "nWc6VAl9fUdIx0Yf05yQFdwGd5y2", badgeValue: 0, change: 1) {
        }
        
        Database.handleUserBadge(userUid: "srHzEjoRYKcKGqAgiyG4E660amQ2", badgeValue: 0, change: 1) {
        }
        
        Database.handleUserBadge(userUid: "KUtV2mzGYDY2hPkXFiU2YC8KDoL2", badgeValue: 0, change: 1) {
        }
        
        Database.handleUserBadge(userUid: "B6div2WhzSObg7XGJRFkKBFEQiC3", badgeValue: 0, change: 1) {
        }
        
        Database.handleUserBadge(userUid: "bWRsX8940oQ0oBhSBVog4rACoFF2", badgeValue: 0, change: 1) {
        }
        
        Database.handleUserBadge(userUid: "VeG6VZOAvmcJ08AnBRTtO8JkSP12", badgeValue: 0, change: 1) {
        }
        
        
        
        
    }
    
    func avgGPSTest() {
        Database.fetchAllHomeFeedPostIds(uid: Auth.auth().currentUser?.uid) { (postIds) in
            var tempPostIds = Array(postIds.prefix(5))
            
            Database.fetchAllPosts(fetchedPostIds: tempPostIds) { (posts) in
                var tempGPS: CLLocation? = nil
                var count: Int = 0
                for post in posts {
//                    tempGPS = Database.averageGPS(<#T##self: Database##Database#>)
                    tempGPS = Database.averageGPS(curGPS: tempGPS, avgCount: count, newGPS: post.locationGPS)
                    count += 1
                }
                
            }
        }
    }
    
    func revertBlockedPost() {
        let blockRef = Database.database().reference().child("blockedPost")
        let postRef = Database.database().reference().child("posts")

        blockRef.queryOrderedByKey().observe(.value) { snapshot in

            guard let blockedPosts = snapshot.value as? [String:Any]  else {return}

            for (postId, postJson) in blockedPosts {
                print(postId)
                print(postJson)
                postRef.child(postId).setValue(postJson)
            }
        }
        
//        let rootRef = Firebase(url:"https://your-Firebase.firebaseio.com")
//        let groceryRef = ref.child("groceryLists").childByAutoId()
//
//        groceryRef.queryOrdered(byChild: "completed").queryEnding(atValue: true)
//                .observe(.childAdded) { (snapshot) in
//                    let historyNode = rootRef.child(snapshot.key)
//                    thisHistoryNode.setValue(snapshot.value)
//
//                    //get a reference to the data we just read and remove it
//                    let nodeToRemove = nodeToRemove.child(snapshot.key)
//                    nodeToRemove.removeValue();
//            }
    }
    
    func checkUserPosts() {
        Database.fetchALLUsers { users in
            for user in users {
                Database.fetchAllPostWithUID(creatoruid: user.uid, filterBlocked: false) { posts in
                    Database.checkUserSocialStats(user: user, socialField: .posts_created, socialCount: posts.count)
                }
            }
        }
    }
    
    func changeRatingEmoji() {
        

        print("changeRatingEmoji")
        Database.fetchAllHomeFeedPostIds(uid: Auth.auth().currentUser?.uid) { (postIds) in
            Database.fetchAllPosts(fetchedPostIds: postIds) { (posts) in
                print("changeRatingEmoji \(posts.count) Posts")
                var count = 0
                let oldEmoji = "🏆"
                let newEmoji = "🥇"
                for post in posts {
                    if post.ratingEmoji == oldEmoji {
                        guard let postId = post.id else {return}
                        Database.database().reference().child("posts").child(postId).child("ratingEmoji").setValue(newEmoji, withCompletionBlock: { (err, ref) in
                            if let err = err {
                                print("   ~ Database | changeRatingEmoji | Update List in Post Object \(postId): Fail, \(err)")
                                return
                            }
                            count += 1
                            print("   ~ Database | changeRatingEmoji | Update List in Post Object \(postId): Success | \(postId)")
                            
                        })
                    }
                }
                
                print("changeRatingEmoji - Finish - \(count) Posts | Change \(oldEmoji) to \(newEmoji)")
            }
        }
    }

    func addLocationTest() {
        
        
//        let postId = ["4838020A-08AD-4963-AF77-404AAD34D0B5"]
//        let postIds = ["-Kx_NJ-z0x1cDbe0lqW_", "090063BF-658E-47C7-AEEB-9734D3AEC0AC", "FC2DD00E-220F-4EB5-9AEC-DEEAFA6B9EAC"]
//        for id in postId {
//            Database.fetchPostWithPostID(postId: id) { (post, err) in
//                guard let post = post else {return}
//                var tempPost = post
//                print(post.locationGooglePlaceID, "LocID")
//                Database.fetchLocationWithLocID(locId: post.locationGooglePlaceID) { (location) in
////                    print("Location", location?.googleJson)
//                    print("Location", location?.googleJson?["opening_hours"]["weekday_text"].arrayValue)
//                }
////
////                Database.queryGooglePlaceID(placeId: post.locationGooglePlaceID) { (json) in
////                    if let json = json {
////                        tempPost.locationGoogleJSON = json
////                        Database.saveLocationToFirebase(post: tempPost)
////                    }
////                }
//
//
////                Database.saveCityToFirebase(post: post)
//            }
//        }

        
        
        
        print("addLocationTest")
        Database.fetchAllHomeFeedPostIds(uid: Auth.auth().currentUser?.uid) { (postIds) in
            Database.fetchAllPosts(fetchedPostIds: postIds) { (posts) in
                print("addLocationTest \(posts.count) Posts")
                Database.fetchAllLocations { (locations) in
                    print("addLocationTest \(locations.count) Locations")
                    for post in posts {
                        guard let postId = post.id else {return}

                        if !(post.locationGooglePlaceID?.isEmptyOrWhitespace() ?? true) {
                            let location = locations.filter({ (loc) -> Bool in
                                loc.locationGoogleID == post.locationGooglePlaceID
                            })
                            if location.count > 0 {
                                let tempLoc = location[0]
                                if (tempLoc.postIds?.contains(postId) ?? false) {
                                    // SKIP
                                } else {
                                    // LOCATION NO POST ID YET
                                    Database.saveLocationToFirebase(post: post)
                                }
                            } else {
                                // LOCATION NOT FOUND IN DB YET
                                Database.saveLocationToFirebase(post: post)
                            }
                        }
                    }
                    print("END addLocationTest")
                }
            }
        }
        
//                        Database.fetchAllLocations { (locations) in
//                            print("addLocationTest \(locations.count) Locations")
//                            for post in posts {
//                                guard let postId = post.id else {return}
//
//                                if !(post.locationGooglePlaceID?.isEmptyOrWhitespace() ?? true) {
//                                    let location = locations.filter({ (loc) -> Bool in
//                                        loc.locationGoogleID == post.locationGooglePlaceID
//                                    })
//                                    if location.count > 0 {
//                                        let tempLoc = location[0]
//                                        if (tempLoc.postIds?.contains(postId) ?? false) {
//                                            // SKIP
//                                        } else {
//                                            // LOCATION NO POST ID YET
//                                            Database.saveLocationToFirebase(post: post)
//                                        }
//                                    } else {
//                                        // LOCATION NOT FOUND IN DB YET
//                                        Database.saveLocationToFirebase(post: post)
//                                    }
//                                }
//                            }
//                            print("END addLocationTest")
//                        }
        
    }
    
    func deleteUsers(){
        let userDelete: [String] = ["KqKtfWoL8lPYFu8yIm9JCXY8v7y2","VnvQF3gLQ5XDpPVLzrSh1Kx78Q33","Zficctm0abWkP4zsn2w21gcE67m1","xNSTqI1t39QPjxAhoCjAIXN6tQt1", "HQ8OlhJvLFZbchu0NDOG0An2Dhq1"]
        
        for userId in userDelete {
            
            Database.fetchUserWithUID(uid: userId) { (user) in
                if let url = user?.profileImageUrl {
                    var deleteRef = Storage.storage().reference(forURL: url)
                    deleteRef.delete(completion: { (error) in
                        if let error = error {
                            print("post image delete error for ", userId, "|" ,url)
                        } else {
                            print("Profile Image Delete Success | ", userId, "|" ,url)
                        }
                    })
                    
                }
                
                Database.database().reference().child("users").child(userId).removeValue()
                print("User Deleted Success | ", userId)
            }
        }
    }
    
    func togglePremiumActivate() {
        let subRef = Database.database().reference()
        var uploadValues:[String:Any] = [:]
        uploadValues["activatePremium"] = false
        
        subRef.updateChildValues(uploadValues) { (err, ref) in
            if let err = err {
                print("togglePremiumActivate: ERROR: ", err)
                return}
            print("togglePremiumActivate")
            
        }
    }
    
    func updateUserLocation(user:User?) {
        guard let user = user else {return}
        let uid = user.uid
        
        Database.fetchAllPostWithUID(creatoruid: user.uid) { (posts) in
            if posts.count == 0 {
                return
            }
            
            var allPostLoc: [String] = [] // Location ID
            var allPostIDLoc: [String: String] = [:] // PostID: Location ID
            var allPostIDGPS: [String: CLLocation] = [:] // PostID: LocationGPS
            var tempLocations: [CLLocation] = []
            
            // POST LOCATION AVERAGE
            for post in posts {
                guard let postId = post.id else {return}
                
                if let locId = post.locationSummaryID , let loc = post.locationGPS {
                    allPostLoc.append(locId)
                    allPostIDLoc[postId] = locId
                    allPostIDGPS[postId] = loc
                }
            }
            
            let countedSet = NSCountedSet(array: allPostLoc)
            let mostFrequent = countedSet.max { countedSet.count(for: $0) < countedSet.count(for: $1) } as! String
            
            var mostFrequentPosts = allPostIDLoc.filter({ (key,value) -> Bool in
                return (value == mostFrequent)
            })
            
            
            for (key,value) in mostFrequentPosts {
                if let gps = allPostIDGPS[key] {
                    tempLocations.append(gps)
                }
            }
            
         // UPDATE FIREBASE
            var uploadGPS: String?
            var center = Database.centerManyLoc(locations: tempLocations)
            guard let lat = center?.latitude else {return}
            guard let long = center?.longitude else {return}
            let GPSLatitude = String(format: "%f", lat)
            let GPSLongitude = String(format: "%f", long)
            uploadGPS = GPSLatitude + "," + GPSLongitude
            
            
            let ref = Database.database().reference().child("users").child(user.uid)
            ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                var user = currentData.value as? [String : AnyObject] ?? [:]
                
                user["userLocation"] = uploadGPS as AnyObject?
                
                // Set value and report transaction success
                currentData.value = user
                print("Successfully Update User Location \(uid) | \(uploadGPS)")
                return TransactionResult.success(withValue: currentData)
                
            }) { (error, committed, snapshot) in
                if let error = error {
                    print(error.localizedDescription)
                }
            }
            
        }
    }
    
    func updateUserPopularImages(user: User?){
        guard let user = user else {return}
        let uid = user.uid
        Database.fetchAllPostWithUID(creatoruid: uid) { (posts) in
            if posts.count == 0 {
                print("No Posts | Return | \(uid)")
                return
            }

        // MOST POPULAR IMAGES
            
            var imageUrls: [String] = []
            var imageUrlsArray:[String] = []
            var sortedPost = posts.sorted(by: { (p1, p2) -> Bool in
                p1.creationDate.compare(p2.creationDate) == .orderedDescending
//                p1.credCount > p2.credCount
            })
            for post in sortedPost {
                if imageUrls.count < 8 {
                    if post.smallImageUrl != nil && post.smallImageUrl.count > 0{
                        imageUrls.append("\(post.smallImageUrl),\((post.id)!)")
                        imageUrlsArray.append(post.smallImageUrl)
                    } else {
                        print("\(post.id) missing small image | smallImageURL \(post.smallImageUrl)")
                        Database.updatePostSmallImages(postId: post.id, completion: { (smallUrl) in
                            if let smallUrl = smallUrl {
                                imageUrls.append("\(smallUrl),\((post.id)!)")
                                imageUrlsArray.append(smallUrl)
                            }
                        })
                    }
                }
            }
            
            
        // CHECK IF NEED TO UPLOAD
            var sameImages = true
            for url in imageUrlsArray {
                if !user.popularImageUrls.contains(url) {
                    sameImages = false
                }
            }
            
            if sameImages {
                print("Same Image Urls | Return | \(uid)")
                return
            }
            
            // UPDATE USER OBJECT
            
            let ref = Database.database().reference().child("users").child(uid)
            ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                var user = currentData.value as? [String : AnyObject] ?? [:]
                
                user["popularImageUrls"] = imageUrls as AnyObject?
                
                // Set value and report transaction success
                currentData.value = user
                print("Successfully Update User \(uid) | \(imageUrls.count) Image URLs")
                return TransactionResult.success(withValue: currentData)
                
            }) { (error, committed, snapshot) in
                if let error = error {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func fixFollowers(){
        print("FIXING FOLLOWERS")
        
        var followers: [String: [String]] = [:]
        
        
        let ref = Database.database().reference().child("following")
        ref.observeSingleEvent(of: .value) { (snapshot) in
            guard let allFollowing = snapshot.value as? [String:Any] else {return}

            print("fixFollowers | allFollowing | Fetched \(allFollowing.count) Records")
            for (initUid, dictionary) in allFollowing {
                
                guard let followinguid = initUid as? String else {return}
                let myGroup = DispatchGroup()

                guard let tempDictionary = dictionary as? [String: Any] else {return}
                guard let followedUsers = tempDictionary["following"] as? [String: Any] else {return}

                for (key,value) in followedUsers {

                    myGroup.enter()
                    let ind = value as? Int
                    if ind == 1 {
                        if followers[key] == nil
                        {
                            // CREATE NEW FOLLOWER ARRAY
                            followers[key] = [initUid]
                            myGroup.leave()
                        }
                        else
                        {
                            // APPEND NEW FOLLOWER ARRAY
                            var temp = followers[key]
                            temp?.append(initUid)
                            followers[key] = temp
                            myGroup.leave()
                        }
                    } else {
                        print("NONE")
                        myGroup.leave()
                    }
                }
            
            myGroup.notify(queue: .main, execute: {
                for (key,value) in followers {
                    
                    var followedDic: [String:Int] = [:]
                    for uid in value {
                        followedDic[uid] = 1
                    }
                    var followCount = followedDic.count ?? 0
                    var uploadDic: [String: Any] = [:]
                    uploadDic["followerCount"] = followCount
                    uploadDic["follower"] = followedDic
                    
                    Database.database().reference().child("follower").child(key).updateChildValues(uploadDic, withCompletionBlock: { (error, ref) in
                        if let error = error {
                            print("fixFollowers | ERROR | \(key) | \(error)")
                        } else {
                            print("fixFollowers | SUCCESS | \(key) | \(followCount) Followers")
                        }
                        
                        if followCount > 0 {
                            Database.spotUpdateSocialCountForUserFinal(creatorUid: key, socialField: .followerCount, final: followCount)
                        }
                    })
                }
                
            }
    
        )}
        }
        
        
        
    }
    
    
    func fixImages(){
        print("FIXING IMAGES")
        let ref = Database.database().reference().child("posts")
        ref.observeSingleEvent(of: .value) { (snapshot) in
            guard let dataSnapshot = snapshot.value as? [String: Any] else {return}
            
            
            for (key,value) in dataSnapshot {
                
                let postId = key
                var dic = value as! [String:Any]
                let secondsFrom1970 = dic["creationDate"] as? Double ?? 0

                if secondsFrom1970 < 1553383140.024374 {
                    continue
                }

                let smallImageUrls = dic["smallImageLink"] as? String ?? ""
                if smallImageUrls == "" {
                    continue
                }

                guard let url = URL(string: smallImageUrls) else {continue}
                URLSession.shared.dataTask(with: url) { (data, response, err) in

                    let dataSize = data?.count ?? 0
                    if (data?.count)! < 500 {
                        print("Fix Image | \(key) | \(dataSize) bytes")
                        self.fixSmallImages(postId: key, data: dic)
                    }
                }.resume()
            }
        }
    }
    
    func fixSmallImages(postId: String, data: [String: Any]){
        print("Fixing Image | \(postId)")

        let dic = data
        let imageUrls = dic["imageUrls"] as? [String] ?? []
        if imageUrls.count > 0 {
            guard let url = URL(string: imageUrls[0]) else {return}
            URLSession.shared.dataTask(with: url) { (data, response, err) in
                if let err = err {
                    print("Failed to fetch post image:", err)
                    return
                }
                guard let imageData = data else {return}
                let smallPhotoSize = CGSize(width: 50, height: 50)
                guard let photoImage = UIImage(data: imageData)?.resizeVI(newSize: smallPhotoSize) else {return}
                let photoArray = [photoImage]
                
                guard let image = UIImage(data: imageData) else {return}
                //                        Database.printImageSizes(image: image)
                
                DispatchQueue.main.async {
                    
                    Database.saveImageToDatabase(uploadImages: photoArray, smallImage: false, completion: { (urlArray, smallImageUrl) in
                        let postRef = Database.database().reference().child("posts").child(postId)
                        postRef.runTransactionBlock({ (currentData) -> TransactionResult in
                            guard let post = currentData.value as? [String : AnyObject] else {
                                print(" ! Post Social Update Error: No Post", postId)
                                return TransactionResult.abort()
                            }
                            
                            let tempUrl = urlArray[0]
                            var temp_post = post
                            temp_post["smallImageLink"] = tempUrl as AnyObject
                            currentData.value = temp_post
                            print("  ~ SUCCESS updatePost | \(postId) smallImageLink: \(tempUrl)")
                            return TransactionResult.success(withValue: currentData)
                            
                        }) { (error, committed, snapshot) in
                            if let error = error {
                                print(" ! updatePost ERROR | \(postId) | \(error)")
                            }
                        }
                    })
                }
                
                }.resume()
        }
    }
    
    func duplicateImages(){
        let ref = Database.database().reference().child("posts")
        ref.observeSingleEvent(of: .value) { (snapshot) in
            guard let dataSnapshot = snapshot.value as? [String: Any] else {return}
            
            
            for (key,value) in dataSnapshot {
                
//                if key != "D12C89CF-00CB-4F2E-B14D-B9CEA3963BDE"{
//                    continue
//                } else {
//                    print("Found D12C89CF-00CB-4F2E-B14D-B9CEA3963BDE")
//                }
                
                let postId = key
                var dic = value as! [String:Any]
                
                if dic["ImageLink50"] != nil {
                    continue
                }
                
                let imageUrls = dic["imageUrls"] as? [String] ?? []
                if imageUrls.count > 0 {
                    guard let url = URL(string: imageUrls[0]) else {return}
                    URLSession.shared.dataTask(with: url, completionHandler: { (data, response, err) in
                        if let err = err {
                            print("Failed to fetch post image:", err)
                            return
                        }
                        guard let imageData = data else {return}
                        let smallPhotoSize = CGSize(width: 50, height: 50)
                        guard let photoImage = UIImage(data: imageData)?.resizeVI(newSize: smallPhotoSize) else {return}
                        let photoArray = [photoImage]
                        
                        guard let image = UIImage(data: imageData) else {return}
//                        Database.printImageSizes(image: image)
                        
                            DispatchQueue.main.async {

                                Database.saveImageToDatabase(uploadImages: photoArray, smallImage: false, completion: { (urlArray, smallImageUrl) in
                                    let postRef = Database.database().reference().child("posts").child(postId)
                                    postRef.runTransactionBlock({ (currentData) -> TransactionResult in
                                        guard let post = currentData.value as? [String : AnyObject] else {
                                            print(" ! Post Social Update Error: No Post", postId)
                                            return TransactionResult.abort()
                                        }

                                        let tempUrl = urlArray[0]
                                        var temp_post = post
                                        temp_post["ImageLink50"] = tempUrl as AnyObject
                                        currentData.value = temp_post
                                        print("  ~ SUCCESS updatePost | \(postId) smallImageLink: \(tempUrl)")
                                        return TransactionResult.success(withValue: currentData)

                                    }) { (error, committed, snapshot) in
                                        if let error = error {
                                            print(" ! updatePost ERROR | \(postId) | \(error)")
                                        }
                                    }
                                })
                            }
                        
                        
                        
                    }).resume()
                }
            }
        }
    }

    
    func cleanUserDatabase(){
        Database.fetchALLUsers { (users) in
            for user in users {
                if user.username == "" && user.profileImageUrl == "" {
                    print("DELETE | \(user.uid)")
                    Database.database().reference().child("users").child(user.uid).removeValue()
                    Database.database().reference().child("userlists").child(user.uid).removeValue()
                    Database.database().reference().child("userposts").child(user.uid).removeValue()
                    for list in user.listIds {
                        Database.database().reference().child("lists").child(list).removeValue()
                        
                    }

                }
            }
        }
    }
    
    func updateUserCode(){
        var userCount = 0

        Database.fetchALLUsers(includeSelf: true, completion: { (users) in
            for user in users {
//                if user.uid != "2G76XbYQS8Z7bojJRrImqpuJ7pz2" {
//                    continue
//                }
//                self.updateUserLocation(user: user)
                self.updateUserPopularImages(user: user)
                userCount += 1
            }
            print("updateUserCode | TOTAL | \(userCount) Users")
        })
    }
    
    func updateListCode(){
        let ref = Database.database().reference().child("lists")
        var listCount = 0
        
//        686B6CBB-14E3-4834-A87B-46C1478DC665
        
        var updateList: [String] = []
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dataSnapshot = snapshot.value as? [String: Any] else {return}
            dataSnapshot.forEach({ (key,value) in
                
                guard let listId = key as? String else {return}
                guard let listDictionary = value as? [String: Any] else {return}
                var tempList = List.init(id: listId, dictionary: listDictionary)
                
                if tempList.postIds?.count ?? 0 > 0  {
                    if updateList.count > 0 && !updateList.contains(tempList.id!) {
                        return
                    }
                    self.updateListHeroPic(list: tempList)
//                    Database.refreshList(list: tempList)
//                    self.modifyList(list: tempList)
                    listCount += 1
                }
            })
            
            print("updateListCode | TOTAL | \(listCount) Lists")
            
        }) { (error) in
            print("updateListCode | ERROR |",error)
        }
    }
    
    func updateListHeroPic(list: List?) {
        guard let list = list else {return}
        guard let listId = list.id else {return}
        guard let postIds = list.postIds else {return}
        if postIds.count == 0 {
            return
        }
        
        if (list.heroImageUrl == nil || list.heroImageUrl == "" ){
            // SET FIRST POST AS HERO IMAGE
            // FETCH POSTS

            
            Database.fetchPostFromList(list: list) { (posts) in
                if posts?.count == 0 {
                    print("updateHeroImageForList | RETURN | \(listId) NO POSTS | \(postIds)")
                    return
                }
                
                Database.sortPosts(inputPosts: posts, selectedSort: defaultRecentSort, selectedLocation: nil, completion: { (filteredPost) in
                    guard let filteredPost = filteredPost else {
                        return
                    }
                    
                    let post = filteredPost[0]
                    // Update Database
                    let ref = Database.database().reference().child("lists").child(listId)
                    
                    ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                        var list = currentData.value as? [String : AnyObject] ?? [:]
                        
                        list["heroImageUrl"] = post.imageUrls[0] as AnyObject?
                        list["heroImageUrlPostId"] = post.id as AnyObject?
                        // Set value and report transaction success
                        currentData.value = list
                        print("updateHeroImageForList | Success | \(listId) Updated | \(post.id) | \(post.imageUrls[0])")
                        return TransactionResult.success(withValue: currentData)
                        
                    }) { (error, committed, snapshot) in
                        if let error = error {
                            print(error.localizedDescription)
                        }
                    }
                })
            }
            
        }

        
        
    }
    
    func modifyList(list: List?) {
        
        guard let list = list else {return}
        guard let listId = list.id else {return}
        guard let postIds = list.postIds else {return}
        
        var tempPosts: [Post] = []
        let myGroup = DispatchGroup()
        
        print("modifyList | \(listId) | \(list.name) | \(postIds.count) | Start")
        
    // FETCH POSTS
        for (id, date) in postIds {
            myGroup.enter()
            Database.fetchPostWithPostID(postId: id, completion: { (post, error) in
                if let error = error {
                    print("updateListCode | ERROR | List \(listId) | \(id)")
                    myGroup.leave()
                    
                } else {
                    if let post = post {
                        tempPosts.append(post)
                    }
                    myGroup.leave()
                }
            })
        }
        
    // PROCESS POSTS AFTER FETCHING
        myGroup.notify(queue: .main, execute: {
            print("modifyList | \(listId) | \(list.name) | \(postIds.count) | \(tempPosts.count) Fetched Posts")

            var allPostLoc: [String] = [] // Location ID
            var allPostIDLoc: [String: String] = [:] // PostID: Location ID
            var allPostIDGPS: [String: CLLocation] = [:] // PostID: LocationGPS
            var tempLocations: [CLLocation] = []
            
            
    // POST LOCATION AVERAGE
            for post in tempPosts {
                guard let postId = post.id else {return}
                
                if let locId = post.locationSummaryID , let loc = post.locationGPS {
                    allPostLoc.append(locId)
                    allPostIDLoc[postId] = locId
                    allPostIDGPS[postId] = loc
                }
            }
            
            let countedSet = NSCountedSet(array: allPostLoc)
            let mostFrequent = countedSet.max { countedSet.count(for: $0) < countedSet.count(for: $1) } as! String
            
            var mostFrequentPosts = allPostIDLoc.filter({ (key,value) -> Bool in
                return (value == mostFrequent)
            })
            
            
            for (key,value) in mostFrequentPosts {
                if let gps = allPostIDGPS[key] {
                    tempLocations.append(gps)
                }
            }
            
    // MOST POPULAR IMAGES
            
            var imageUrls: [String] = []
            var imageUrlsArray:[String] = []

            
            if list.listRanks.count > 0 {
                let listRanks = list.listRanks
                var sortedIds: [String] = []
                
                for i in 1...8 {
                    if let id = listRanks.key(forValue: i) {
                        sortedIds.append(id)
                    }
                }
                
                for id in sortedIds {
                    if imageUrls.count < 8 {
                        let tempPost = tempPosts.filter({ (post) -> Bool in
                            post.id == id
                        })
                        if tempPost[0].smallImageUrl != nil {
                            imageUrls.append("\(tempPost[0].smallImageUrl),\(id)")
                            imageUrlsArray.append(tempPost[0].smallImageUrl)
                        }
                    }
                }
                
            } else {
                var sortedPost = tempPosts.sorted(by: { (p1, p2) -> Bool in
                    p1.credCount > p2.credCount
                })
                
                for post in sortedPost {
                    if imageUrls.count < 8 {
                        if post.smallImageUrl != nil {
                            imageUrls.append("\(post.smallImageUrl),\((post.id)!)")
                            imageUrlsArray.append(post.smallImageUrl)
                        }
                    }
                }
            }
            

            
    // POST MOST RECENT DATE
            var mostRecentDate = list.creationDate

            for (key,value) in postIds {
                let time = value as! Double ?? 0
                var tempTime = Date(timeIntervalSince1970: time)
                if tempTime > mostRecentDate {
                    mostRecentDate = tempTime
                }
            }
            
            // Update Most Recent
            let uploadTime = mostRecentDate.timeIntervalSince1970
            
            // Update Location
            var uploadGPS: String?
            var center = Database.centerManyLoc(locations: tempLocations)
            
            // CHECK IF NEED TO UPLOAD
            var sameImages = true
            for url in imageUrlsArray {
                if !list.listImageUrls.contains(url) {
                    sameImages = false
                }
            }
            
            guard let lat = center?.latitude else {return}
            guard let long = center?.longitude else {return}
            
            var sameLocation = true
            if (list.listGPS?.distance(from: CLLocation(latitude: lat, longitude: long)) ?? 0) > 100000.0 {
                // ONLY UPDATE GEOFIRE LOCATION IF DISTANCE IS >100KM
                sameLocation = false
            }
            

                let GPSLatitude = String(format: "%f", lat)
                let GPSLongitude = String(format: "%f", long)
                uploadGPS = GPSLatitude + "," + GPSLongitude
            
            // UPDATE LIST OBJECT ANYWAY SINCE MOST RECENT DATE WILL CHANGE
                
                let ref = Database.database().reference().child("lists").child(listId)
                
                ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                    var list = currentData.value as? [String : AnyObject] ?? [:]
                    
                    list["location"] = uploadGPS as AnyObject?
                    list["mostRecent"] = uploadTime as AnyObject?
                    list["listImageUrls"] = imageUrls as AnyObject?
                    // Set value and report transaction success
                    currentData.value = list
                    print("   ~ Database | updateVariableForList | Success | \(listId) Updated | \(uploadGPS) | \(uploadTime)")
                    return TransactionResult.success(withValue: currentData)
                    
                }) { (error, committed, snapshot) in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                }
                
                let convertCenter = CLLocation(latitude: lat, longitude: long)


                let geofireRef = Database.database().reference().child("listlocations")
                let geoFire = GeoFire(firebaseRef: geofireRef)

                geoFire.setLocation(convertCenter, forKey: listId) { (error) in
                    if (error != nil) {
                        print("An error occured when saving Location \(convertCenter) for List \(listId) : \(error)")
                    } else {
                        print("Saved location successfully! for Post \(listId)")
                    }
                }

            print("modifyList | \(listId) | \(list.name) | FINISH")

        })
    }
    
    
    func updateFirebaseCode(){
        
        let ref = Database.database().reference().child("users")
        let userListRef = Database.database().reference().child("userlists")

        
        // CREATE A USER-LISTID TABLE
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionaries = snapshot.value as? [String: Any] else {return}
            
            dictionaries.forEach({ (key,value) in
                
                guard let userUid = key as? String else {return}
                guard let userDictionary = value as? [String: Any] else {return}
                
                let listIds = userDictionary["lists"] as? [String:Any]? ?? [:]
                
                if (listIds?.count ?? 0) > 0 {
                    userListRef.child(userUid).updateChildValues(listIds!, withCompletionBlock: { (error, ref) in
                        if let error = error {
                            print("Create User List Object Error | \(userUid) | \(error)")
                        } else {
                            print("Create User List Object Success | \(userUid) | \(listIds!.count) lists")
                        }
                    })
                }
            })
        })   { (err) in print ("Failed to fetch users for search", err) }
    }
    
    
// LOCATION AUTH FUNCTIONS
    
    @objc func requestLocation() {
        if LocationSingleton.sharedInstance.locationManager?.authorizationStatus == .denied || !CLLocationManager.locationServicesEnabled() {
            let alert = UIAlertController(title: "Location Access", message: "Legit needs your current location to sort food posts nearest to you. Please enable location services on your settings.", preferredStyle: .alert)
            
            let settingsAction = UIAlertAction(title: "Allow", style: .default) { (_) -> Void in

                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }

                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        print("Settings opened: \(success)") // Prints true
                    })
                }
            }
            
            let cancelAction = UIAlertAction(title: "Not Now", style: .destructive) { (_) -> Void in
                NotificationCenter.default.post(name: AppDelegate.LocationDeniedNotificationName, object: nil)
                print("Location Denied")
            }
            alert.addAction(settingsAction)
            alert.addAction(cancelAction)

            self.present(alert, animated: true) {
                print("DISPLAY requestLocation settings alert")
            }
            
        } else if !LocationAuthview.isBeingPresented {
            self.present(LocationAuthview, animated: true) {
                print("DISPLAY requestLocation")
            }
        } else {
            print("requestLocation already being displayed")
        }
        
    }
        
        
//        let ref = Database.database().reference().child("posts")
//
//        ref.observeSingleEvent(of: .value, with: {(snapshot) in
//            guard let userposts = snapshot.value as? [String:Any]  else {return}
//            print("key count: \(userposts.keys.count)")
//
////            let posts = userposts.filter({ (key,value) -> Bool in
////                return key == "-KwMlCbHvy9FO6eEDwEs"
////            })
//
//            userposts.forEach({ (key,value) in
//
//            guard let value = value as? [String: Any] else {return}
//            var temp_dic = value
//
//            let old_rating = temp_dic["rating"] as? Double ?? 0
//            var new_rating = 0.0
//                if old_rating > 0 {
//                    new_rating =  (old_rating / 9) * 5.0
//                    new_rating = ceil(new_rating/0.5)*0.5
//                }
//
//            temp_dic["rating"] = new_rating
//
//            let nonRatingEmoji = temp_dic["nonratingEmoji"] as? [String] ?? []
//            var ratingEmoji = nil as String?
//
//                for emoji in nonRatingEmoji {
//                    if extraRatingEmojis.contains(emoji) && ratingEmoji == nil {
//                        ratingEmoji = emoji
//                        temp_dic["ratingEmoji"] = ratingEmoji
//                    }
//                }
//
//        Database.updatePostwithPostID(postId: key, newDictionaryValues: temp_dic)
//            })
//        })
//    }

        
        
        
        
        
        
        
        
        //            var allLists: [List] = []
        //
        //            // IMPORT ALL LISTS
        //            let listRef = Database.database().reference().child("lists")
        //            listRef.observeSingleEvent(of: .value, with: {(snapshot) in
        //                guard let lists = snapshot.value as? [String: Any] else {
        //                    return}
        //
        //                lists.forEach({ (key,value) in
        //                    let dictionary = value as! [String:Any]
        //                    var fetchedList = List.init(id: key, dictionary: dictionary)
        //
        //                    Database.fetchPostFromList(list: fetchedList, completion: { (posts) in
        //
        //                   //Update Total Emojis
        //                        Database.countMostUsedEmojis(posts: posts!, completion: { (emojis) in
        //                            if emojis.count > 0 {
        //                                let topEmojis = Array(emojis.prefix(5))
        //                                Database.checkTop5EmojisForList(listId: key, emojis: topEmojis)
        //                            }
        //                        })
        //
        //
        //                    //Update Total Cred
        //                        var total_cred = 0
        //                        for post in posts! {
        //                            total_cred += post.credCount
        //                        }
        //                        Database.updateTotalCredForList(listId: key, total_cred: total_cred)
        //
        //                    })
        //
        //                })
        //                print("Loaded All Lists: \(allLists.count)")
        //
        //            }){ (error) in
        //                print("Fetch List : ERROR: ", error)
        //            }
        //
        
        // IMPORT ALL LISTS
        //            let userRef = Database.database().reference().child("users")
        //            userRef.observeSingleEvent(of: .value, with: {(snapshot) in
        //                guard let lists = snapshot.value as? [String: Any] else {
        //                    return}
        //
        //                lists.forEach({ (key,value) in
        //                    guard let userDictionary = value as? [String:Any] else {return}
        //                    let user = User(uid:key, dictionary: userDictionary)
        //
        //                    Database.fetchAllPostWithUID(creatoruid: key, completion: { (posts) in
        //                        Database.countMostUsedEmojis(posts: posts, completion: { (emojis) in
        //                            let topEmoji = Array(emojis.prefix(upTo: 5))
        //                            Database.checkTop5Emojis(userId: key, emojis: topEmoji)
        //                        })
        //                    })
        //                })
        //
        //            }){ (error) in
        //                print("Fetch Users : ERROR: ", error)
        //            }
        
        
        
        
        //            var allLists: [List] = []
        //
        //            // IMPORT ALL LISTS
        //            let listRef = Database.database().reference().child("lists")
        //            listRef.observeSingleEvent(of: .value, with: {(snapshot) in
        //                guard let lists = snapshot.value as? [String: Any] else {
        //                    return}
        //
        //                lists.forEach({ (key,value) in
        //                    let dictionary = value as! [String:Any]
        //                    let fetchedList = List.init(id: key, dictionary: dictionary)
        //                    allLists.append(fetchedList)
        //                })
        //                print("Loaded All Lists: \(allLists.count)")
        //
        //            }){ (error) in
        //                print("Fetch List : ERROR: ", error)
        //            }
        //
        //
        //            // UPDATE LISTS ID to be listID:UserID instead of listID:date
        //
        //            let ref = Database.database().reference().child("post_lists")
        //            ref.observeSingleEvent(of: .value, with: { (snapshot) in
        //                print("Start Post_Lists Query")
        //
        //                guard let postLists = snapshot.value as? [String:Any] else {return}
        //
        //                var tempPostLists = postLists
        //                tempPostLists.forEach({ (key,value) in
        //
        //                    let postId = key
        //                    var tempLists: Dictionary<String, String> = [:]
        //
        //                    guard let listDetails = value as? [String: Any] else {return}
        //                    guard let lists = listDetails["lists"] as? [String:Any] else {return}
        //                    lists.forEach({ (key, value) in
        //                        if let listPost = allLists.first(where: { (list) -> Bool in
        //                            list.id == key
        //                        }){
        //                            tempLists[key] = listPost.creatorUID
        //                        }
        //                    })
        //
        //                    ref.child(postId).child("lists").updateChildValues(tempLists) { (err, ref) in
        //                        if let err = err {
        //                            print("Update List CredCount: ERROR: \(postId)", err)
        //                            return
        //                        }
        //                        print("Update List CredCount: SUCCESS: \(postId) ")
        //                    }
        //
        //                })
        //            })
        //
        //
        
        
        //            let ref = Database.database().reference().child("posts")
        //
        //            ref.observeSingleEvent(of: .value, with: {(snapshot) in
        //
        //
        //
        //                guard let userposts = snapshot.value as? [String:Any]  else {return}
        //                print("key count: \(userposts.keys.count)")
        //
        //
        //                userposts.forEach({ (key,value) in
        //
        //                    guard let messageDetails = value as? [String: Any] else {return}
        ////                    guard let selectedEmojis = messageDetails["emoji"] as? String else {return}
        ////                    guard let creationDate = messageDetails["creationDate"] as? Double else {return}
        //
        //                    var fetchedTagDate = messageDetails["tagTime"] as? Double
        //                    var fetchedRatingEmoji = messageDetails["ratingEmoji"] as? String
        //                    var fetchedNonratingEmoji = messageDetails["nonRatingEmoji"] as? [String]
        //                    var fetchedNonratingEmojiTags = messageDetails["nonRatingEmojiTags"] as? [String]
        //                    var creatorUid = messageDetails["creatorUID"] as? String
        //
        ////                    let tempEmojis = String(selectedEmojis.prefix(1))
        ////                    var selectedEmojisSplit = selectedEmojis.map { String($0) }
        //
        //                    var newRatingEmoji: String? = nil
        //                    var newNonratingEmoji: [String]? = nil
        //                    var newNonratingEmojiTags: [String]? = nil
        //                    var newTagTime: Double? = nil
        //
        
        // Split Emojis
        
        //                    print("Fetched Rating Emoji: ",fetchedRatingEmoji)
        //                    print("Fetched NonRating Emoji: ",fetchedNonratingEmoji)
        //                    print("Selected Emoji splits: ", selectedEmojisSplit)
        //
        //                    if (fetchedRatingEmoji == nil || fetchedRatingEmoji == "" || fetchedNonratingEmoji == nil) && selectedEmojisSplit != [] {
        //                        // Replace Rating emoji with First of NR emoji if its rating emoji
        //
        //                        if String(selectedEmojisSplit[0]).containsRatingEmoji {
        //                            print("First Emoji Char: ",tempEmojis)
        //                            newRatingEmoji = String(selectedEmojisSplit[0])
        //                            newNonratingEmoji = Array(selectedEmojisSplit.dropFirst(1))
        //                            newNonratingEmojiTags = Array(selectedEmojisSplit.dropFirst(1))
        //
        //                        } else {
        //                            newRatingEmoji = fetchedRatingEmoji
        //                            newNonratingEmoji = selectedEmojisSplit
        //                            newNonratingEmojiTags = selectedEmojisSplit
        //                        }
        //                    } else {
        //                        newRatingEmoji = fetchedRatingEmoji
        //                        newNonratingEmoji = fetchedNonratingEmoji
        //                        newNonratingEmojiTags = fetchedNonratingEmojiTags
        //                    }
        //
        //                    print("New R Emoji: ", newRatingEmoji, " New NR Emoji: ", newNonratingEmoji, " New NR Emoji Tags: ", newNonratingEmojiTags)
        //
        //                    if fetchedTagDate == nil {
        //                        newTagTime = creationDate
        //                        print("Update New Tag Time with: ", creationDate)
        //                    } else {
        //                        newTagTime = fetchedTagDate!
        //                    }
        //
        //                    let values = ["ratingEmoji": newRatingEmoji, "nonratingEmoji": newNonratingEmoji, "nonratingEmojiTags": newNonratingEmojiTags, "tagTime": newTagTime] as [String: Any]
        //
        //
        //                    print("Updating PostId: ",key," Values: ", values)
        //                    //                    Database.updatePostwithPostID(post: key, newDictionaryValues: values)
        //
        //                    var saveNewRatingEmoji = newRatingEmoji ?? ""
        //                    var saveNewNonratingEmoji = newNonratingEmoji?.joined() ?? ""
        //
        //                    let emojiString = String(saveNewRatingEmoji + saveNewNonratingEmoji)
        //
        
        
        // Update User Posts
        //                    let userPostValues = ["tagTime": newTagTime, "emoji": emojiString] as [String: Any]
        
        
        //                    let userPostValues = ["imageUrls": currentImageUrls] as [String: Any]
        //                    Database.updateUserPostwithPostID(creatorId: creatorUid!, postId: key, values: userPostValues)
        
        // Skip post if it does not have imageUrl and only have imageUrls
        //                    guard let currentImageUrl = messageDetails["imageUrl"] as? String else {return}
        //
        //                    var currentImageUrlsInput: [String] = []
        //                    currentImageUrlsInput.append(currentImageUrl)
        //
        //
        //                        let newDictionaryValues = ["imageUrls": currentImageUrlsInput] as [String: Any]
        //                        Database.database().reference().child("posts").child(key).updateChildValues(newDictionaryValues) { (err, ref) in
        //                            if let err = err {
        //                                print("Fail to Update Post: ", key, err)
        //                                return
        //                            }
        //                            print("Succesfully Updated Post: ", key, " with: ", newDictionaryValues)
        //                        }
        //
        //
        //                })
        //            })
    
    
    //            var fullimg: NSData = NSData(data: UIImageJPEGRepresentation(image, 1)!)
    //            print("Full IMG: ",Double(fullimg.length)/1024.0, image.size)
    
    //            var img90: NSData = NSData(data: UIImageJPEGRepresentation(image, 0.9)!)
    //            print("90 IMG: ",Double(img90.length)/1024.0)
    //
    //            var img80: NSData = NSData(data: UIImageJPEGRepresentation(image, 0.8)!)
    //            print("80 IMG: ",Double(img80.length)/1024.0)
    
    //            var viimg = image.resizeVI(newSize: defaultPhotoResize)
    //            var resizeimg: NSData = NSData(data: UIImageJPEGRepresentation(viimg!, 1)!)
    //            print("VIResize IMG: ",Double(resizeimg.length)/1024.0, viimg?.size)
    //
    //            var resizeimg90: NSData = NSData(data: UIImageJPEGRepresentation(image.resizeVI(newSize: defaultPhotoResize)!, 0.9)!)
    //            print("Resize IMG: ",Double(resizeimg90.length)/1024.0)
    //
    //            var resizeimg80: NSData = NSData(data: UIImageJPEGRepresentation(image.resizeVI(newSize: defaultPhotoResize)!, 0.8)!)
    //            print("Resize IMG: ",Double(resizeimg80.length)/1024.0)
    //
    //            var defimg = image.resizeImageWith(newSize: defaultPhotoResize)
    //            var defaultresizeimg: NSData = NSData(data: UIImageJPEGRepresentation(defimg, 1)!)
    //            print("Default Resize IMG: ",Double(defaultresizeimg.length)/1024.0, defimg.size)
    //
    //            var default90resizeimg: NSData = NSData(data: UIImageJPEGRepresentation(defimg, 0.9)!)
    //            print("Default Resize IMG: ",Double(default90resizeimg.length)/1024.0, defimg.size)
    

    
    
    
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
