//
//  ListOptionsTableViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 7/22/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit
import TLPhotoPicker
import Photos

import SVProgressHUD
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth

class ListOptionsPhotoTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TLPhotosPickerViewControllerDelegate {
    
    var inputList: List? = nil {
        didSet {
            print(" ListOptionsPhotoTableViewController | Loaded List \(inputList?.name)")
            self.refreshTableView()

        }
    }


    lazy var tableView : UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        tv.estimatedRowHeight = 70
        tv.allowsMultipleSelection = false
        return tv
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let headerView = UIView.init(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        headerView.backgroundColor = UIColor.lightBackgroundGrayColor()
        self.view.addSubview(headerView)
        headerView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)

        
        let headerLabel = UILabel()
        headerLabel.font = UIFont(name: "Poppins-Bold", size: 12)
        headerLabel.text = "Header Image"
        self.view.addSubview(headerLabel)
        headerLabel.anchor(top: nil, left: headerView.leftAnchor, bottom: headerView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 10, paddingRight: 0, width: 0, height: 0)
        headerLabel.sizeToFit()
        
        self.view.addSubview(tableView)
        tableView.anchor(top: headerView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 210)
        
        self.view.backgroundColor = UIColor.backgroundGrayColor()
        setupNavigationItems()
        setupTableView()
        tableView.reloadData()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    fileprivate func setupNavigationItems() {
        
        navigationController?.navigationBar.barTintColor = UIColor.white
        let rectPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 5))
        UIColor.white.setFill()
        rectPath.fill()
        let finalImg = UIGraphicsGetImageFromCurrentImageContext()
        navigationController?.navigationBar.shadowImage = finalImg
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        
        // REMOVES THE 1PX BOTTOM LINE IN NAV BAR
        navigationController?.navigationBar.shadowImage = UIImage()
        
        
        let headerTitle = NSAttributedString(string: "List Options", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 17)])
        
        var headerActionView = UIButton()
        headerActionView.setAttributedTitle(headerTitle, for: .normal)
        headerActionView.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        headerActionView.sizeToFit()
        
        //        headerActionView.layoutIfNeeded()
        navigationItem.titleView = headerActionView
        
        // Nav Bar Buttons
        let closeButton = UIButton()
        let closeTitle = NSAttributedString(string: "CLOSE", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 12)])
        closeButton.setAttributedTitle(closeTitle, for: .normal)
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        
        let closeNavButton = UIBarButtonItem.init(customView: closeButton)
        self.navigationItem.rightBarButtonItem = closeNavButton
        
        let navBackButton = UIButton()
        navBackButton.addTarget(self, action: #selector(handleBackPressNav), for: .touchUpInside)
        navBackButton.setImage((#imageLiteral(resourceName: "navBackImage").resizeImageWith(newSize: CGSize(width: 10, height: 10))).withRenderingMode(.alwaysTemplate), for: .normal)
        navBackButton.tintColor = UIColor.ianLegitColor()
        let navBackTitle = NSAttributedString(string: " BACK ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 10)])
        navBackButton.setAttributedTitle(navBackTitle, for: .normal)
        navBackButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        navBackButton.sizeToFit()
        let backNavButton = UIBarButtonItem.init(customView: navBackButton)
        self.navigationItem.leftBarButtonItem = backNavButton
        
    }
    
    @objc func handleBackPressNav(){
        self.handleBack()
    }
    
    func refreshTableView(){
        tableView.reloadData()
    }
    
    var optionCellId = "Option Cell"
    
    func setupTableView(){
        
        tableView.register(ListOptionTableViewCell.self, forCellReuseIdentifier: optionCellId)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.layer.borderColor = UIColor.ianLightGrayColor().cgColor
        tableView.layer.borderWidth = 1
        tableView.isScrollEnabled = false

        
    }
    
    @objc func didTapClose(){
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 3
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: optionCellId, for: indexPath) as! ListOptionTableViewCell
        cell.optionHeader = ""
        cell.listOptionDetailCenter?.isActive = true
        if indexPath.row == 0
        {
            if let postCount = self.inputList!.postIds?.count {
                var listCount = (postCount > 0) ? "(\(postCount) Posts)" : ""
                cell.optionDetail = "Select From List Images \(listCount)"
            } else {
                cell.optionDetail = "Select From List Images"
            }
        }
        else if indexPath.row == 1
        {
            cell.optionDetail = "Select From All Your Images"
        }
        else if indexPath.row == 2
        {
            cell.optionDetail = "Select from Library"
        }
        else
        {
            cell.optionDetail = ""
        }
        cell.isSelected = false
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        print("Selected \(indexPath.row) | List \(self.inputList?.name)")
        if indexPath.row == 0 {
            let nextScreen = ListOptionPhotoPicker()
            nextScreen.currentDisplayList = self.inputList
            nextScreen.fetchPostsForList()
            self.navigationController?.pushViewController(nextScreen, animated: true)
        } else if indexPath.row == 1 {
            let nextScreen = ListOptionPhotoPicker()
            nextScreen.currentDisplayList = self.inputList
            nextScreen.currentDisplayUserID = Auth.auth().currentUser?.uid
            nextScreen.fetchPostsForUser()
            self.navigationController?.pushViewController(nextScreen, animated: true)
        } else if indexPath.row == 2 {
            self.presentMultImagePicker()
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    var selectedAssets = [TLPHAsset]()

    
    func presentMultImagePicker(){
        print("MainTabBarController | Open Multi Image Picker")
        SVProgressHUD.show(withStatus: "Loading Photo Roll")
        let viewController = CustomPhotoPickerViewController()
        viewController.delegate = self
//        viewController.didExceedMaximumNumberOfSelection = { [weak self] (picker) in
//            self!.showExceededMaximumAlert(vc: picker)
//        }
        var configure = TLPhotosPickerConfigure()
        configure.numberOfColumn = 3
        configure.maxSelectedAssets = 1
        configure.singleSelectedMode = true
        viewController.configure = configure
        viewController.selectedAssets = self.selectedAssets
        
        self.present(viewController, animated: true, completion: {
            SVProgressHUD.dismiss()
        })
    }
    
    func showExceededMaximumAlert(vc: UIViewController) {
        let alert = UIAlertController(title: "", message: "Exceed Maximum Number Of Selection", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        vc.present(alert, animated: true, completion: nil)
    }

    var selectedImage: UIImage? = nil
    
    func dismissPhotoPicker(withPHAssets: [PHAsset]) {
        // if you want to used phasset.
        print("MainTabBarController | Dismiss Photo Picker | Process PHAssets")
        Database.processPHAssets(assets: withPHAssets) { (images, location, date) in
            if images?.count == 0 {
                if let image = images?[0]{
                    self.selectedImage = image
                    self.updateListWithPhoto()
                }
            }
        }
    }
    
    func updateListWithPhoto(){
        guard let image = self.selectedImage else {return}
        guard let listId = self.inputList?.id else {return}
        var tempList = self.inputList
        
        Database.saveImageToDatabase(uploadImages: [image]) { (bigUrl, smallUrl) in
            let url = bigUrl[0]
            if url == nil || url.isEmptyOrWhitespace() {
                print(" Not Saving Image | NO Hero Image Url | \(self.inputList?.name)")
                return
            }
            tempList?.heroImage = image
            tempList?.heroImageUrl = url
            tempList?.needsUpdating = true
            listCache[listId] = tempList
            print(" Updated List Hero With Photo Roll | \(tempList?.name) | \(tempList?.heroImageUrl)")
            SVProgressHUD.showSuccess(withStatus: "Updated List Photo")
            NotificationCenter.default.post(name: ListViewController.refreshListViewNotificationName, object: nil)
            self.handleBack()
        }

    }
    
    
    
    
    
    
}
