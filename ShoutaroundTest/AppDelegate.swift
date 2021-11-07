import UIKit

import CoreData
import FBSDKCoreKit
import GooglePlaces
import GoogleMaps
import DropDown
import SVProgressHUD
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import FirebaseCore
import UserNotifications
import FirebaseMessaging
import FirebaseAnalytics
import Purchases

// OLD PHOTO
// "https://firebasestorage.googleapis.com/v0/b/shoutaroundtest-ae721.appspot.com/o/profile_images%2FF3A38E61-1537-4499-AC26-C074CD9059B8?alt=media&token=0e228917-d385-474f-9625-c1f4e32ecea8"

var appDelegateFilter: Filter? = nil {
    didSet {
        print("AppDelegate Filter | IsFiltering | \(appDelegateFilter?.isFiltering) | \(appDelegateFilter?.filterCaptionArray)")
    }
}

var appDelegatePostID: String? = nil {
    didSet {
        print("AppDelegate Selected Post ID | IsFiltering | \(appDelegatePostID)")
    }
}

//var selectedMapPinLocation: Filter? = nil {
//    didSet {
//        print("AppDelegate Filter | IsFiltering | \(appDelegateFilter?.isFiltering)")
//    }
//}
var appDelegateViewPage: Int = 0
var appDelegateMapViewInd: Bool = false
var newUser: Bool = false

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate{
    
    var window: UIWindow?
    var mapWindow: UIWindow?
    
    let googlePlacesApiKey = GoogleAPIKey()
    
    
    static let SwitchToMapNotificationName = NSNotification.Name(rawValue: "SwitchToMapView")
    static let SwitchToListNotificationName = NSNotification.Name(rawValue: "SwitchToListView")
    static let LoadUserListViewNotificationName = NSNotification.Name(rawValue: "LoadUserListView")
    static let SuccessLoginNotificationName = NSNotification.Name(rawValue: "SuccessLogin")
    static let RefreshAllName = NSNotification.Name(rawValue: "RefreshAll")
    static let NewEmojiDic = NSNotification.Name(rawValue: "NewEmojiDic")
    static let ShowCityNotificationName = NSNotification.Name(rawValue: "ShowCity")
    static let refreshPostNotificationName = NSNotification.Name(rawValue: "Refresh Post")
    static let RequestLocationNotificationName = NSNotification.Name(rawValue: "Request Location")
    static let LocationUpdatedNotificationName = NSNotification.Name(rawValue: "Location Updated")
    static let LocationDeniedNotificationName = NSNotification.Name(rawValue: "Location Denied")

    
//    let LocationAuthview = LocationRequestViewController()

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let version : Any! = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        let build : Any! = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")

        print("Version: \(version!) Build: \(build!)")
//        print("\(Bundle.main.) (\(Bundle.main.bundleID))")

        
        FirebaseApp.configure()
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        Database.setLoggingEnabled(true)
        Database.database().isPersistenceEnabled = true
//        setupEventListeners()
        
        GMSPlacesClient.provideAPIKey(googlePlacesApiKey)
        GMSServices.provideAPIKey(googlePlacesApiKey)
        
        UNUserNotificationCenter.current().requestAuthorization(options: .badge) { (granted, error) in
            if error != nil {
                // success!
            }
        }
        
//        do {
//            try Auth.auth().signOut()
//        }
//
//        catch let signOutErr {
//            print("Failed to sign out guest user:", signOutErr)
//        }
        
        registerForPushNotifications()

        
        // Logout Annonymous
        if let _ = Auth.auth().currentUser {
            if (Auth.auth().currentUser?.isAnonymous)! {
                print("Sign Out Guest User")
                do {
                    let user = Auth.auth().currentUser
                
                    user?.delete { error in
                        if let error = error {
                            print("Error Deleting Guest User")
                        } else {
                            print("Guest User Deleted")
                        }
                    }
                    
                    try Auth.auth().signOut()
                    CurrentUser.isGuest = false
                    
                } catch let signOutErr {
                    print("Failed to sign out guest user:", signOutErr)
                }
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(toggleMapView), name: AppDelegate.SwitchToMapNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(toggleListView), name: AppDelegate.SwitchToListNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadUserForListView), name: AppDelegate.LoadUserListViewNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(compileEmojis), name: AppDelegate.NewEmojiDic, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showCity), name: AppDelegate.ShowCityNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAppIconBadge), name: UserEventViewController.refreshNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAppIconBadge), name: InboxController.newMsgNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAppIconBadge), name: MainTabBarController.NewNotificationName, object: nil)

        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")


//        NotificationCenter.default.addObserver(self, selector: #selector(toggleListView), name: AppDelegate.SuccessLoginNotificationName, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(successLoginView), name: AppDelegate.SuccessLoginNotificationName, object: nil)

        
        let tabBarController = MainTabBarController()
        window = UIWindow()
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()
        
//        Database.sendPushNotification(token: "3523424234", title: "test", body: "test")
        
//        let mainViewController = MainViewController()
//        let navController = UINavigationController(rootViewController: mainViewController)
//        mapWindow = UIWindow()
//        mapWindow?.rootViewController = navController

        
        //        let subviews = (navController.navigationBar.subviews as [UIView])
        //        for subview: UIView in subviews {
        //            subview.layer.removeAllAnimations()
        //        }
        
        //        window?.rootViewController = MainViewController()
        DropDown.startListeningToKeyboard()
        
        // Setup SVProgressHUD
        SVProgressHUD.setImageViewSize(CGSize(width: 50, height: 50))
        SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.gradient)
        
        //        Auth.auth().addStateDidChangeListener { auth, user in
        //            if let user = user {
        //                print("Currently Logged in as ", user)
        //
        //                try! Auth.auth().signOut()
        //            } else {
        //                // No User is signed in. Show user the login screen
        //                print("No Active User ")
        //            }
        //        }
        
        // Setup Emojis
        
        
//        UINavigationBar.appearance().tintColor = UIColor.legitColor()
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
//        self.readUserEmojiDic()
        self.EmojiSetup()

        //        Database.fetchUserWithUsername(username: "xinahui") { (user, error) in
        //            print("User : \(user)")
        //            print("Error : \(error)")
        //        }
        
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
          options: authOptions) { _, _ in }
        application.registerForRemoteNotifications()

        Messaging.messaging().delegate = self
        
        setupRevenueCat()
        return true
    }
    
//    @objc func requestLocation() {
//        if LocationSingleton.sharedInstance.locationManager?.authorizationStatus == .denied || !CLLocationManager.locationServicesEnabled() {
//            let alert = UIAlertController(title: "Need Authorization", message: "Legit needs your location to find food posts nearest to you on your feed and map. Please enable location services on your settings.", preferredStyle: .alert)
//            
//            let settingsAction = UIAlertAction(title: "OK", style: .default) { (_) -> Void in
//
//                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
//                    return
//                }
//
//                if UIApplication.shared.canOpenURL(settingsUrl) {
//                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
//                        print("Settings opened: \(success)") // Prints true
//                    })
//                }
//            }
//            alert.addAction(settingsAction)
//            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//            
//            if let tabBarController = self.window?.rootViewController as? UITabBarController {
//                tabBarController.present(alert, animated: true) {
//                    print("DISPLAY requestLocation settings alert")
//                }
//            }
//            
//        } else if !LocationAuthview.isBeingPresented {
//            if  let tabBarController = self.window?.rootViewController as? UITabBarController,
//                let navController = tabBarController.selectedViewController as? UINavigationController {
//                tabBarController.present(LocationAuthview, animated: true) {
//                    print("DISPLAY requestLocation")
//                }
//            }
//        } else {
//            print("requestLocation already being displayed")
//        }
//        
//    }
//    
    
    func setupRevenueCat() {
        Purchases.debugLogsEnabled = true
        Purchases.configure(withAPIKey: "VTQZpUjVgCeIIesuEAJAVVXUXBbPuRCF")
    }
    
    func getNotificationSettings() {
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        print("Notification settings: \(settings)")
        guard settings.authorizationStatus == .authorized else { return }
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
        }
      }
    }
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current()
          .requestAuthorization(
            options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            print("Permission granted: \(granted)")
            guard granted else { return }
            self?.getNotificationSettings()
          }
    }
    
    @objc func refreshAppIconBadge() {
        var notifications = CurrentUser.unreadEventCount ?? 0
        var messages = CurrentUser.unreadMessageCount ?? 0
        
        UIApplication.shared.applicationIconBadgeNumber = messages + notifications

    }
    
    
    
    func EmojiSetup() {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let ref = Database.database().reference().child("emojiDic").child(uid)
        ref.observeSingleEvent(of: .value, with: {(snapshot) in

        guard let dictionary = snapshot.value as? [String: String] else {
            self.compileEmojis()
            return}
            
            userEmojiDictionary = dictionary
            print("Read \(dictionary.count) User-Defined Emojis for \(uid)")
            self.compileEmojis()
        }) { (err) in print("Failed to fetch user emojis:", err) }
    }
    
    
    @objc func successLoginView(){
    }
    
    func setupEventListeners(){
        guard let creatoruid = Auth.auth().currentUser?.uid else {return}
        print("AppDelegate | setupEventListeners | \(creatoruid)")

        let ref = Database.database().reference().child("user_event").child(creatoruid)
        ref.observe(DataEventType.childAdded) { (data) in
            
            SVProgressHUD.showSuccess(withStatus: "New Social Interaction \n \(data)")
       
            guard let dictionary = data.value as? [String: Any] else {
                return}
            var tempEvent = Event.init(id: data.key, dictionary: dictionary)
        
            if !CurrentUser.events.contains(where: { (event) -> Bool in
                return event.id == tempEvent.id
            }) {
                // NEW EVENT
                Database.fetchEventForUID(uid: creatoruid) { (events) in
                    CurrentUser.events = events
                }
                NotificationCenter.default.post(name: UserEventViewController.refreshNotificationName, object: nil)
                print("New Event | \n\(tempEvent)")
            }
        }
    }
    
    func setupInboxListeners(){
        guard let creatoruid = Auth.auth().currentUser?.uid else {return}
        print("AppDelegate | setupInboxListeners | \(creatoruid)")

        let inboxRef = Database.database().reference().child("inbox").child(creatoruid)
        inboxRef.observe(DataEventType.childAdded) { (data) in
            Database.fetchMessageThreadsForUID(userUID: creatoruid) { (threads) in
                CurrentUser.inboxThreads = threads
//                NotificationCenter.default.post(name: InboxController.newMsgNotificationName, object: nil)
                print("INBOX - New Thread For \(creatoruid)")
            }
        }
        
        
        Database.fetchMessageThreadsForUID(userUID: creatoruid) { (messageThreads) in
            for thread in messageThreads {
                let threadId = thread.threadID
                let ref = Database.database().reference().child("messageThreads").child(threadId)

                ref.observe(DataEventType.childChanged) { (data) in
                    
                    guard let threadDictionary = data.value as? [String: Any] else {return}
                    
                    var tempThread = MessageThread.init(threadID: threadId, dictionary: threadDictionary)
                    
                    var tempInboxThreads: [MessageThread] = CurrentUser.inboxThreads
                    tempInboxThreads.removeAll { (thread) -> Bool in
                        thread.threadID == tempThread.threadID
                    }
                    
                    tempInboxThreads.append(tempThread)
                    CurrentUser.inboxThreads = tempInboxThreads
//                    NotificationCenter.default.post(name: InboxController.newMsgNotificationName, object: nil)
                    print("INBOX - New Message For Thread \(threadId)")
                }
            }
        }
    }
    
    @objc func loadUserForListView(){
        print("Load User For List View")
        let tabBarController = MainTabBarController()
        window = UIWindow()
        window?.rootViewController = tabBarController
    }
    
    
    @objc func toggleMapView(){
        
        guard let window = self.window else {
            return
        }
        
        if let tab = self.window!.rootViewController as! MainTabBarController? {
            let nav = tab.viewControllers?[1] as! UINavigationController
                do {
    //                let mapView = nav.viewControllers.first as! MainViewController
//                    print(nav.viewC   ontrollers)
                    let mapView = nav.viewControllers.first as! NewTabMapViewController
                    print("Toggle Map View | App \(appDelegateFilter?.filterCaptionArray) | Map \(mapView.mapFilter.filterCaptionArray)")
 
                    
                    mapView.checkAppDelegateFilter()
                    tab.selectedIndex = 1
                    tab.selectedTabBarIndex = 1


                } catch let error {
                    print(error.localizedDescription)
                }

        }
//
////    // IF STILL ON LIST VIEW
//
//        if self.mapWindow?.rootViewController == nil {
//            print("MapWindow is Blank | Load MapWindow")
////            let mainViewController = MainViewController()
////            mainViewController.mapFilter = appDelegateFilter
////            mainViewController.mapFilter?.filterSort = defaultNearestSort
//
//            let mainViewController = LegitMapViewController()
//            let navController = UINavigationController(rootViewController: mainViewController)
//            mapWindow = UIWindow()
//            mapWindow?.rootViewController = navController
////            mapWindow?.rootViewController = mainViewController
//            self.mapWindow?.makeKeyAndVisible()
//
//            appDelegateMapViewInd = true
//        } else {
//            print("MapWindow Exist | Toggle to MapWindow")
//            let nav = self.mapWindow?.rootViewController as! UINavigationController
//            do {
////                let mapView = nav.viewControllers.first as! MainViewController
//                let mapView = nav.viewControllers.first as! LegitMapViewController
//
//                mapView.checkAppDelegateFilter()
//            } catch let error {
//                print(error.localizedDescription)
//            }
//            self.mapWindow?.makeKeyAndVisible()
//        }

        
        
// OLD
        
//        else if self.mapWindow?.rootViewController?.navigationController?.presentedViewController is MainViewController {
//
//            let vc = self.mapWindow?.rootViewController?.navigationController?.presentedViewController as! MainViewController
//            vc.mapFilter = appDelegateFilter
//            vc.mapFilter?.filterSort = defaultNearestSort
//
//            vc.refreshPostsForFilter()
//            self.mapWindow?.makeKeyAndVisible()
//            appDelegateMapViewInd = true
//        }
//
//        else {
//            print("Toggle Map View: ERROR: Already on Map View")
//            print(self.mapWindow?.rootViewController)
//            let vc = self.mapWindow?.rootViewController
//            print(vc?.presentedViewController)
//            print(self.mapWindow?.rootViewController)
//            print(self.mapWindow?.rootViewController?.navigationController)
//            print(self.mapWindow?.rootViewController?.navigationController?.viewControllers)
//            print(self.mapWindow?.rootViewController?.presentedViewController)
//
//            return
//        }
    
//
//        if (self.window?.isKeyWindow)! {
//
//            // OPEN MAP VIEW
//            //                    let tab_vc = tab.selectedViewController as! UINavigationController
//            //                    let vc = tab_vc.visibleViewController as! HomeController
//
//            if self.mapWindow?.rootViewController == nil {
//                print("MapWindow is Blank | Load MapWindow")
//                let mainViewController = MainViewController()
//                mainViewController.mapFilter = appDelegateFilter
//                mainViewController.mapFilter?.filterSort = defaultNearestSort
//
//                let navController = UINavigationController(rootViewController: mainViewController)
//                mapWindow = UIWindow()
//                mapWindow?.rootViewController = navController
//                self.mapWindow?.makeKeyAndVisible()
//
////                if let vc = self.mapWindow?.currentViewController() as! MainViewController? {
////                    vc.mapFilter = appDelegateFilter
////                    vc.mapFilter?.filterSort = defaultNearestSort
////                    vc.refreshPostsForFilter()
////                }
//
//                appDelegateMapViewInd = true
//            }
//
////            else if let vc = self.mapWindow?.currentViewController() as! MainViewController? {
//
////            else if let vc = self.mapWindow?.rootViewController as! UINavigationController {
//
//            else if self.mapWindow?.rootViewController?.navigationController != nil {
//
//                let vc = self.mapWindow?.rootViewController?.navigationController?.viewControllers[0] as! MainViewController
//
//                vc.mapFilter = appDelegateFilter
//                vc.mapFilter?.filterSort = defaultNearestSort
//
//                vc.refreshPostsForFilter()
//                self.mapWindow?.makeKeyAndVisible()
//                appDelegateMapViewInd = true
//            }
//
//        } else {
//            print("Toggle Map View: ERROR: Already on Map View")
//            return
//        }
    }
    
    @objc func showCity(){
        if let tab = self.window!.rootViewController as! MainTabBarController? {
            tab.selectedTabBarIndex = 0
            if appDelegateViewPage == 0 {
                // HOME PAGE
                tab.selectedTabBarIndex = 0
                tab.selectedIndex = 0

//                    let vc = tab.selectedViewController as! HomeController

                let tab_vc = tab.selectedViewController as! UINavigationController
                let vc = tab_vc.visibleViewController as! LegitHomeView
                
                vc.viewFilter = appDelegateFilter ?? vc.viewFilter
                vc.viewFilter.defaultSort = defaultRecentSort
                vc.refreshPostsForSearch()
            }
        }
    }
    
    @objc func toggleListView(){
        
        print("Toggle List View")
        
        // If we use instagram view as main view, we dont need to read filters from the map to the list
        guard let mapWindow = self.mapWindow else {
            return
        }
        
        if (self.mapWindow?.isKeyWindow)! {
            print("Toggle to List View")
            self.window?.makeKeyAndVisible()
            appDelegateMapViewInd = false
        }
        
        if (self.window?.isKeyWindow)! {

            // OPEN INSTAGRAM VIEW
            if let tab = self.window!.rootViewController as! MainTabBarController? {

                if appDelegateViewPage == 0 {
                    // HOME PAGE
                    tab.selectedTabBarIndex = 0
                    tab.selectedIndex = 0

//                    let vc = tab.selectedViewController as! HomeController

                    let tab_vc = tab.selectedViewController as! UINavigationController
                    let vc = tab_vc.visibleViewController as! LegitHomeView

                    if (appDelegateFilter?.isFiltering)! || (vc.viewFilter.isFiltering) {
                        // Doesn't refresh if no filters
                        print("App Delegate Filter - Refresh List View")
//                        vc.viewFilter = appDelegateFilter ?? vc.viewFilter
//                        vc.viewFilter.defaultSort = defaultRecentSort
//                        vc.refreshPostsForSearch()
                    } else {
                        // Default to Recent Sort if not filtering
                        print("Refresh List Filter - Map View Has No Filter")
                        if vc.viewFilter.isFiltering && !(appDelegateFilter?.isFiltering)! {
                            vc.viewFilter.clearFilter()
                            vc.refreshPostsForSearch()
                        }
//                        vc.viewFilter.defaultSort = defaultRecentSort
//                        vc.refreshPostsForSearch()
                    }

                }
                
                /*else if appDelegateViewPage == 1 {
                    // LIST VIEW
                    tab.selectedIndex = 3
                    let tab_vc = tab.selectedViewController as! UINavigationController
                    let vc = tab_vc.visibleViewController as! ListViewController
                    vc.currentDisplayList = appDelegateFilter?.filterList
                    vc.viewFilter = appDelegateFilter

                } else if appDelegateViewPage == 2 {
                    // USER PROFILE
                    tab.selectedIndex = 4
                    let tab_vc = tab.selectedViewController as! UINavigationController
                    let vc = tab_vc.visibleViewController as! UserProfileController
                    vc.displayUserId = appDelegateFilter?.filterUser?.uid
                    vc.viewFilter = appDelegateFilter
                }*/
                self.window!.makeKeyAndVisible()
                appDelegateMapViewInd = false
            }

        } else {
            print("Toggle List View: ERROR: Already on List View")
            return
        }
    }
    
    /*
    func switchViews(){
        if (self.window?.isKeyWindow)! {
            
            // OPEN INSTAGRAM VIEW
            if let tab = self.listWindow?.rootViewController as! MainTabBarController? {
                if appDelegateViewPage == 0 {
                    // HOME PAGE
                    tab.selectedTabBarIndex = 0
                    tab.selectedIndex = 0
                    let tab_vc = tab.selectedViewController as! UINavigationController
                    let vc = tab_vc.visibleViewController as! HomeController
                    vc.viewFilter = appDelegateFilter
                    vc.refreshPostsForFilter()
                    
                    //                    if let tab_vc = tab.tabBarController?.selectedViewController as! UINavigationController? {
                    //                        let vc = tab_vc.viewControllers[0] as! HomeController
                    //                        vc.viewFilter = appDelegateFilter
                    //                    }
                    
                } else if appDelegateViewPage == 1 {
                    // LIST VIEW
                    tab.selectedIndex = 3
                    let tab_vc = tab.selectedViewController as! UINavigationController
                    let vc = tab_vc.visibleViewController as! ListViewController
                    vc.currentDisplayList = appDelegateFilter?.filterList
                    vc.viewFilter = appDelegateFilter
                    
                    
                    //                    if let tab_vc = tab.tabBarController?.selectedViewController as! UINavigationController? {
                    //                        let vc = tab_vc.viewControllers[3] as! ListViewController
                    //                        vc.currentDisplayList = appDelegateFilter?.filterList
                    //                    }
                } else if appDelegateViewPage == 2 {
                    tab.selectedIndex = 4
                    let tab_vc = tab.selectedViewController as! UINavigationController
                    let vc = tab_vc.visibleViewController as! UserProfileController
                    vc.displayUserId = appDelegateFilter?.filterUser?.uid
                    vc.viewFilter = appDelegateFilter
                    
                    
                    //                    if let tab_vc = tab.tabBarController?.selectedViewController as! UINavigationController? {
                    //                        let vc = tab_vc.viewControllers[4] as! UserProfileController
                    //                        vc.displayUser = appDelegateFilter?.filterUser
                    //                    }
                }
                self.listWindow?.makeKeyAndVisible()
                
            }
            
        } else {
            
            // OPEN MAP VIEW
            if let vc = self.window?.viewController() as! MainViewController? {
                vc.mapFilter = appDelegateFilter
            }
            self.window?.makeKeyAndVisible()
            
        }
    }*/
    
    @objc func compileEmojis(){
        
        for dic in emojiDictionarySets{
            EmojiDictionary = EmojiDictionary.merging(dic) { (current, _) in current }
        }
        
        cuisineEmojiSelect = Array(FlagEmojiDictionary.keys)

        
        for emoji in defaultEmojiSelection {
            let tempEmoji = EmojiBasic(emoji: emoji, name: EmojiDictionary[emoji], count: 0)
            defaultEmojis.append(tempEmoji)
        }
        
        let autotagEmojiSet = [mealEmojiDictionary, FlagEmojiDictionary, DietEmojiDictionary]
        
//        for (x, y) in mealEmojiDictionary {
//            mealEmojis.append(EmojiBasic(emoji: x, name: y, count: 0))
//        }

        allFoodEmojis = Array(FoodEmojiDictionary.keys)
        allDrinkEmojis = Array(DrinksEmojiDictionary.keys)
        IngEmojiDictionary = MeatEmojiDictionary
        IngEmojiDictionary.merge(VegEmojiDictionary) {(current,_) in current}
        allIngredientEmojis = Array(IngEmojiDictionary.keys)
        allDefaultEmojis = allFoodEmojis + allDrinkEmojis + allIngredientEmojis
        
        
        SET_FoodEmojis = Database.appendEmojis(currentEmojis: SET_FoodEmojis, newEmojis: Array(FoodEmojiDictionary.keys))
        SET_AllEmojis += SET_FoodEmojis
        SET_SnackEmojis = Database.appendEmojis(currentEmojis: SET_SnackEmojis, newEmojis: Array(SnacksEmojiDictionary.keys))
        SET_AllEmojis += SET_SnackEmojis
        SET_DrinkEmojis = Database.appendEmojis(currentEmojis: SET_DrinkEmojis, newEmojis: Array(DrinksEmojiDictionary.keys))
        SET_AllEmojis += SET_DrinkEmojis

        SET_RawEmojis = Database.appendEmojis(currentEmojis: SET_RawEmojis, newEmojis: Array(MeatEmojiDictionary.keys))
        SET_AllEmojis += SET_RawEmojis

        SET_VegEmojis = Database.appendEmojis(currentEmojis: SET_VegEmojis, newEmojis: Array(VegEmojiDictionary.keys))
        SET_AllEmojis += SET_VegEmojis

        SET_FlagEmojis = Database.appendEmojis(currentEmojis: SET_FlagEmojis, newEmojis: Array(FlagEmojiDictionary.keys))
        SET_AllEmojis += SET_FlagEmojis

        SET_SmileyEmojis = Database.appendEmojis(currentEmojis: SET_SmileyEmojis, newEmojis: Array(SmileyEmojiDictionary.keys))
        SET_AllEmojis += SET_SmileyEmojis

        SET_OtherEmojis = Database.appendEmojis(currentEmojis: SET_OtherEmojis, newEmojis: Array(OtherEmojiDictionary.keys))
        SET_AllEmojis += SET_OtherEmojis

        
        for meal in mealEmojisSelect {
            mealEmojis.append(EmojiBasic(emoji: meal, name: mealEmojiDictionary[meal], count: 0))
        }
        
        for country in SET_FlagEmojis {
            cuisineEmojis.append(EmojiBasic(emoji: country, name: FlagEmojiDictionary[country], count: 0))
        }
//
//        for (x, y) in FlagEmojiDictionary {
//            cuisineEmojis.append(EmojiBasic(emoji: x, name: y, count: 0))
//        }
        
        for x in dietEmojiSelect {
            dietEmojis.append(EmojiBasic(emoji: x, name: DietEmojiDictionary[x], count: 0))
        }
        
        for (x, y) in extraRatingEmojisDic {
             allRatingEmojis.append(EmojiBasic(emoji: x, name: y, count: 0))
         }
        
        autoTagEmojiSelect = mealEmojisSelect
        autoTagEmojiSelect += dietEmojiSelect
        autoTagEmojiSelect += SET_FlagEmojis


//        // Adds all first default emojis first
//        for emoji in allDefaultEmojis {
//            var emoji_dic = EmojiDictionary[emoji] ?? ""
//            let tempEmoji = Emoji(emoji: emoji, name: emoji_dic, count: 0)
//            allSearchEmojis.append(tempEmoji)
//        }
//
//        // Starts With All Search Emojis
//        for emoji in EmojiDictionaryEmojis {
//            if !allSearchEmojis.contains(where: { (emoji_lookup) -> Bool in
//                return emoji_lookup.emoji == emoji.emoji
//            }) {//                allSearchEmojis.append(emoji)
//            }
//        }
        
        // All Search Emojis is All Food + Drink + Ingredient Emojis
        allSearchEmojis = defaultEmojis + cuisineEmojis + mealEmojis + dietEmojis
        allMealTypeEmojis = mealEmojis + dietEmojis + cuisineEmojis
        allMealTypeOptions = allMealTypeEmojis.map { $0.name! }
        
        
        // POPULATE ALL EMOJIS
        EmojiDictionaryEmojis = []
        allEmojis = []
        allNonCuisineEmojis = []
        
        // ADD USER EMOJI DIC to EMOJI DIC
        for (emoji, name) in userEmojiDictionary {
            EmojiDictionary[emoji] = name
        }
        
        // Create All Emoji Dictionary Emojis
        for x in SET_AllEmojis {
            if let name = EmojiDictionary[x] {
                EmojiDictionaryEmojis.append(EmojiBasic(emoji: x, name: name, count: 0))
            }
        }
//        for (x, y) in EmojiDictionary {
//            EmojiDictionaryEmojis.append(EmojiBasic(emoji: x, name: y, count: 0))
//        }
        
        
    // SETUP REVERSE EMOJI DICTIONARY
        ReverseEmojiDictionary = [:]
        // ADD EVERYTHING IN EMOJI DICTIONARY
        for pair in EmojiDictionary { ReverseEmojiDictionary[pair.value] = pair.key }
        
        // ADD REVERSE EMOJI DUPS
        ReverseEmojiDictionary = ReverseEmojiDictionary.merging(ReverseEmojiDictionaryDups, uniquingKeysWith: { (first, _) in first })
        
        
        for (name,emoji) in ReverseEmojiDictionary {
            let tempEmoji = EmojiBasic(emoji: emoji, name: name, count: 0)

            if !EmojiDictionaryEmojis.contains(where: { (emoji_lookup) -> Bool in
                return emoji_lookup.emoji == tempEmoji.emoji
            }) {
                EmojiDictionaryEmojis.append(tempEmoji)
            }
        }
        
        allEmojis = EmojiDictionaryEmojis
        let cuisineExclude = cuisineEmojiSelect
        allNonCuisineEmojis = allEmojis.filter({ (emoji) -> Bool in
            return !cuisineExclude.contains(emoji.emoji)
        })
        
    }
    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }

    
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let handled = ApplicationDelegate.shared.application(app, open: url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as! String?, annotation: options[UIApplication.OpenURLOptionsKey.annotation])
        
        return handled
        
        //            return FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
    }
    
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "InstagramFirebase")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
}


extension AppDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler:
    @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    process(notification)
    completionHandler([[.banner, .sound]])
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
//    print(userInfo)
    guard let aps = userInfo["aps"] as? [String: Any] else { return }
    let action = aps["category"] as? String
//    print(action)
    if notificationActions.contains(action ?? "") {
        // OPEN NOTIFICATION
        print("Open Notification from Alert")
        if  let tabBarController = self.window?.rootViewController as? UITabBarController,
            let navController = tabBarController.selectedViewController as? UINavigationController {
            let note = UserEventViewController()
            navController.pushViewController(note, animated: true)
        }
    } else if action == messageAction {
        // OPEN INBOX
        print("Open Inbox from Alert")
        if  let tabBarController = self.window?.rootViewController as? UITabBarController,
            let navController = tabBarController.selectedViewController as? UINavigationController {
            let inboxController = InboxController(collectionViewLayout: UICollectionViewFlowLayout())
            navController.pushViewController(inboxController, animated: true)
        }
    }
    
    
    process(response.notification)
    completionHandler()
  }

  func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    if let refreshedToken = Messaging.messaging().fcmToken {
        print("APN token: \(refreshedToken)")
        CurrentUser.curAPNToken = refreshedToken
        Database.saveAPNTokenForUser(userId: Auth.auth().currentUser?.uid, token: refreshedToken)
    }
    
//    var token = FIRInstanceID.instanceID().token()
//    print("OTHER token: \(token)")
  }

  private func process(_ notification: UNNotification) {
    let userInfo = notification.request.content.userInfo
    UIApplication.shared.applicationIconBadgeNumber = 0
    if let newsTitle = userInfo["newsTitle"] as? String,
      let newsBody = userInfo["newsBody"] as? String {
//      let newsItem = NewsItem(title: newsTitle, body: newsBody, date: Date())
//      NewsModel.shared.add([newsItem])
      Analytics.logEvent("NEWS_ITEM_PROCESSED", parameters: nil)
    }
    Messaging.messaging().appDidReceiveMessage(userInfo)
    Analytics.logEvent("NOTIFICATION_PROCESSED", parameters: nil)
  }
}

extension AppDelegate: MessagingDelegate {
  func messaging(
    _ messaging: Messaging,
    didReceiveRegistrationToken fcmToken: String?
  ) {
    let tokenDict = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: tokenDict)
  }
}

