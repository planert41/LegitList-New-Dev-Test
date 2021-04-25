//
//  CreateNewListViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/15/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit
import TLPhotoPicker
import SVProgressHUD
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth
import Photos

class NewListCoverImageCardController: UIViewController {

    // MARK: - Template Inputs
                                                                                                                                                                 
    var curList: List? = nil {
        didSet {
            guard let curList = curList else {return}
            refreshListDetails()
        }
    }
    
    let topMargin: CGFloat = 24
    let topMarginBackgroundColor = UIColor.clear
    let headerTitle = "Cover Image"

    let nextButton = TemplateObjects.newListNextButton()
    let exitCardButton = TemplateObjects.newListExitButton()
    let skipButton = TemplateObjects.newListSkipButton()
    let backButton = TemplateObjects.newListBackButton()

    
    let cardContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.ianWhiteColor()
        v.clipsToBounds = true
        v.layer.cornerRadius = 10
        v.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]        //        label.numberOfLines = 0
        return v
    }()
    

    let headerLabel: UILabel = {
        let label = UILabel()
        label.layer.borderColor = UIColor.clear.cgColor
        label.textAlignment = .left
        label.font = UIFont(name: "Poppins-Bold", size: 20)
        label.textColor = .lightGray
        return label
    }()
    
    var selectedAssets = [TLPHAsset]()
    var imageSelected: UIImage? = nil {
        didSet {
            let hasImage = (self.imageSelected != nil)
            self.listCoverImageViewButton.isHidden = hasImage
            self.cancelListCoverImageButton.isHidden = !hasImage
            self.listCoverImageView.image = self.imageSelected
            self.listDetailView.isHidden = !hasImage
            self.selectOtherImageHeight?.constant = hasImage ? 30 : 0
            self.selectOtherImageButton.isHidden = !hasImage
            self.nextButton.isSelected = hasImage
            refreshListDetails()
        }
    }

    
    
    
    let textViewPlaceholder = NSMutableAttributedString(string: "Describe your new list", attributes: [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.ianGrayColor()])

    
    let listCoverImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = nil
        iv.backgroundColor = UIColor.mainBlue()
        iv.layer.borderColor = UIColor.lightGray.cgColor
        iv.layer.borderWidth = 1
//        iv.backgroundImage = UIImageView(image: #imageLiteral(resourceName: "camera_default").withRenderingMode(.alwaysTemplate))
        iv.tintColor = UIColor.gray
        iv.isUserInteractionEnabled = true
        
        return iv
    }()
    
    
    // MARK: - LIST DETAILS
    let listDetailView = UIView()
    
    let userProfileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        return iv
    }()
    
    lazy var listNameButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("", for: .normal)
        button.setImage(#imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTitleColor(UIColor.ianBlackColor(), for: .normal)
        button.titleLabel?.font =  UIFont(name: "Poppins-Bold", size: 20)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        button.tintColor = UIColor.ianBlackColor()
        button.isUserInteractionEnabled = false
        return button
    }()
    
    func refreshListDetails() {
        if let curProflieImageURL = CurrentUser.user?.profileImageUrl {
            self.userProfileImageView.loadImage(urlString: curProflieImageURL)
        }
        
        self.listNameButton.setTitle("   " + (self.curList?.name ?? ""), for: .normal)
        self.listDetailView.isHidden = self.imageSelected == nil
    }
        
    // LIST NAME BUTTON
    lazy var listCoverImageViewButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("   SELECT IMAGE", for: .normal)
        let image = #imageLiteral(resourceName: "camera_default").withRenderingMode(.alwaysOriginal)
        button.setImage(image, for: .normal)
//        button.setImage(#imageLiteral(resourceName: "camera_default").withRenderingMode(.alwaysTemplate), for: .normal)
        button.titleLabel?.font =  UIFont.boldSystemFont(ofSize: 14)
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        button.tintColor = UIColor.ianBlackColor()
        button.addTarget(self, action: #selector(didTapSelectImage), for: .touchUpInside)

        button.backgroundColor = UIColor.clear
        button.layer.borderColor = UIColor.ianGrayColor().cgColor
        button.layer.borderWidth = 1

        return button
    }()
    
    @objc func didTapSelectImage() {
        presentMultImagePicker()
    }
    
    lazy var selectOtherImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("   SELECT OTHER IMAGE", for: .normal)
        let image = #imageLiteral(resourceName: "camera_default").withRenderingMode(.alwaysOriginal)
        button.setImage(image, for: .normal)
//        button.setImage(#imageLiteral(resourceName: "camera_default").withRenderingMode(.alwaysTemplate), for: .normal)
        button.titleLabel?.font =  UIFont.boldSystemFont(ofSize: 14)
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        button.tintColor = UIColor.ianBlackColor()
        button.addTarget(self, action: #selector(didTapSelectImage), for: .touchUpInside)

        button.backgroundColor = UIColor.clear
        button.layer.borderColor = UIColor.ianGrayColor().cgColor
        button.layer.borderWidth = 0
        button.addTarget(self, action: #selector(didTapSelectImage), for: .touchUpInside)

        return button
    }()
    

    
    var selectOtherImageHeight: NSLayoutConstraint?
    
    
    lazy var cancelListCoverImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("", for: .normal)
        button.setImage(#imageLiteral(resourceName: "cancel_red_fill").withRenderingMode(.alwaysOriginal), for: .normal)
        button.setTitleColor(UIColor.ianBlackColor(), for: .normal)
        button.titleLabel?.font =  UIFont.boldSystemFont(ofSize: 14)
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        button.tintColor = UIColor.ianBlackColor()
        button.addTarget(self, action: #selector(didTapCancelImage), for: .touchUpInside)
        button.backgroundColor = UIColor.clear
        return button
    }()
    
    @objc func didTapCancelImage() {
        self.imageSelected = nil
//        self.listCoverImageView.image = nil
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupNavigationItems()
        guard let temp = tempListCreated else {return}
        self.curList = temp
    }
    
    func setupNavigationItems(){
        self.navigationController?.isNavigationBarHidden = true
    }
    
    // MARK: - VIEWDIDLOAD
    
        
    let createNewListView = NewListInitPostPhotoViewController()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationItems()
        
        let backgroundView = UIView()
//        backgroundView.backgroundColor = UIColor.init(red: 34, green: 34, blue: 34, alpha: 1)
//        backgroundView.alpha = 0.2
        backgroundView.backgroundColor = topMarginBackgroundColor

        view.addSubview(backgroundView)
        backgroundView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
                
        view.addSubview(cardContainer)
        cardContainer.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: topMargin, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        cardContainer.backgroundColor = UIColor.ianWhiteColor()
        
        cardContainer.addSubview(exitCardButton)
        exitCardButton.anchor(top: cardContainer.topAnchor, left: nil, bottom: nil, right: cardContainer.rightAnchor, paddingTop: 24, paddingLeft: 0, paddingBottom: 0, paddingRight: 24, width: 28, height: 28)
        exitCardButton.addTarget(self, action: #selector(exitCard), for: .touchUpInside)
        
        
        cardContainer.addSubview(headerLabel)
        headerLabel.anchor(top: cardContainer.topAnchor, left: cardContainer.leftAnchor, bottom: nil, right: nil, paddingTop: 24, paddingLeft: 24, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        headerLabel.text = headerTitle
        headerLabel.sizeToFit()
        
        cardContainer.addSubview(listCoverImageView)
        listCoverImageView.anchor(top: headerLabel.bottomAnchor, left: cardContainer.leftAnchor, bottom: nil, right: cardContainer.rightAnchor, paddingTop: 12, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 170)
        listCoverImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapSelectImage)))
        
        cardContainer.addSubview(listCoverImageViewButton)
        listCoverImageViewButton.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 150, height: 30)
        listCoverImageViewButton.centerYAnchor.constraint(equalTo: listCoverImageView.centerYAnchor).isActive = true
        listCoverImageViewButton.centerXAnchor.constraint(equalTo: listCoverImageView.centerXAnchor).isActive = true
        listCoverImageViewButton.sizeToFit()

//        cardContainer.addSubview(listDetailView)
//        listDetailView.anchor(top: nil, left: listCoverImageView.leftAnchor, bottom: nil, right: listCoverImageView.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 50)
//        listDetailView.backgroundColor = UIColor.ianWhiteColor()
//        listDetailView.centerYAnchor.constraint(equalTo: listCoverImageView.centerYAnchor).isActive = true
//        
//        listDetailView.addSubview(userProfileImageView)
//        userProfileImageView.anchor(top: nil, left: nil, bottom: nil, right: listDetailView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 16, width: 30, height: 30)
//        userProfileImageView.layer.cornerRadius = 30/2
//        userProfileImageView.layer.masksToBounds = true
//        userProfileImageView.centerYAnchor.constraint(equalTo: listDetailView.centerYAnchor).isActive = true
//        
//        listDetailView.addSubview(listNameButton)
//        listNameButton.anchor(top: nil, left: listDetailView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 16, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
//        listNameButton.rightAnchor.constraint(lessThanOrEqualTo: userProfileImageView.leftAnchor).isActive = true
//        listNameButton.centerYAnchor.constraint(equalTo: listDetailView.centerYAnchor).isActive = true
//        listNameButton.heightAnchor.constraint(lessThanOrEqualToConstant: 45).isActive = true

        refreshListDetails()


        
        
        cardContainer.addSubview(selectOtherImageButton)
        selectOtherImageButton.anchor(top: listCoverImageView.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 8, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        selectOtherImageButton.centerXAnchor.constraint(equalTo: listCoverImageView.centerXAnchor).isActive = true
        selectOtherImageButton.addTarget(self, action: #selector(didTapSelectImage), for: .touchUpInside)
        selectOtherImageHeight = selectOtherImageButton.heightAnchor.constraint(equalToConstant: 0)
        selectOtherImageHeight?.isActive = true
        selectOtherImageButton.isHidden = true

        cardContainer.addSubview(cancelListCoverImageButton)
        cancelListCoverImageButton.anchor(top: selectOtherImageButton.topAnchor, left: nil, bottom: nil, right: cardContainer.rightAnchor, paddingTop: 0, paddingLeft: 16, paddingBottom: 0, paddingRight: 16, width: 30, height: 30)
        cancelListCoverImageButton.isHidden = true
        
        cardContainer.addSubview(nextButton)
        nextButton.anchor(top: (selectOtherImageButton).bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 24, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 60, height: 55)
        nextButton.centerXAnchor.constraint(equalTo: (listCoverImageView).centerXAnchor).isActive = true
        nextButton.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
        nextButton.isSelected = true
        
        cardContainer.addSubview(backButton)
        backButton.anchor(top: nil, left: nil, bottom: nil, right: nextButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        backButton.centerYAnchor.constraint(equalTo: nextButton.centerYAnchor).isActive = true
        backButton.sizeToFit()
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        
        cardContainer.addSubview(skipButton)
        skipButton.anchor(top: nil, left: nextButton.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        skipButton.centerYAnchor.constraint(equalTo: nextButton.centerYAnchor).isActive = true
        skipButton.sizeToFit()
        skipButton.addTarget(self, action: #selector(handleSkip), for: .touchUpInside)
        
        // Do any additional setup after loading the view.
        

        createNewListView.currentDisplayUserID = Auth.auth().currentUser?.uid
        createNewListView.fetchPostsForUser()
    }
    
    // MARK: - BUTTONS FUNCTIONS

    
    @objc func didTapBack() {
        self.navigationController?.popViewController(animated: true)

//        let createNewListView = NewListDescCardController()
//        if let list = self.curList {
//            createNewListView.curList = list
//        }
//
//          let transition:CATransition = CATransition()
//            transition.duration = 0.5
//        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
//        transition.type = CATransitionType.push
//        transition.subtype = CATransitionSubtype.fromRight
//            self.navigationController!.view.layer.add(transition, forKey: kCATransition)
//        self.navigationController?.pushViewController(createNewListView, animated: true)
    }

    @objc func handleNext() {
        
        self.curList?.heroImage = self.imageSelected
        tempListCreated = self.curList
        createNewListView.curList = self.curList
        
        if self.imageSelected == nil {
            print("Next | NO HERO IMAGE")
        } else {
            print("Next | HERO IMAGE ADDED")
        }
//        let createNewListView = NewListInitPostViewController()
//        createNewListView.curList = self.curList
        self.navigationController?.pushViewController(createNewListView, animated: true)

        
    }
    
    @objc func exitCard() {
        self.dismiss(animated: true) {
            print("exitCard")
            tempListCreated = nil
        }
    }
    
    @objc func handleSkip() {
        print("SKIP")
        tempListCreated = self.curList
//        createNewListView.curList = self.curList
        self.navigationController?.pushViewController(createNewListView, animated: true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: - PHOTO PICKING

extension NewListCoverImageCardController : TLPhotosPickerViewControllerDelegate {
        func presentMultImagePicker(){
            print("NewListCoverImageView | Open Multi Image Picker")
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

        
        func dismissPhotoPicker(withPHAssets: [PHAsset]) {
            // if you want to used phasset.
            print("MainTabBarController | Dismiss Photo Picker | Process PHAssets")
            Database.processPHAssets(assets: withPHAssets) { (images, location, date) in
                if (images?.count ?? 0) > 0 {
                    if let image = images?[0]{
                        self.imageSelected = image
//                        self.updateListWithPhoto()
                    }
                }
            }
        }
        
        func updateListWithPhoto(){
            guard let image = self.imageSelected else {return}
            guard let listId = self.curList?.id else {return}
            var tempList = self.curList
            
            self.listCoverImageView.image = image
            
//            Database.saveImageToDatabase(uploadImages: [image]) { (bigUrl, smallUrl) in
//                let url = bigUrl[0]
//                if url == nil || url.isEmptyOrWhitespace() {
//                    print(" Not Saving Image | NO Hero Image Url | \(self.inputList?.name)")
//                    return
//                }
//                tempList?.heroImage = image
//                tempList?.heroImageUrl = url
//                tempList?.needsUpdating = true
//                listCache[listId] = tempList
//                print(" Updated List Hero With Photo Roll | \(tempList?.name) | \(tempList?.heroImageUrl)")
//                SVProgressHUD.showSuccess(withStatus: "Updated List Photo")
//                NotificationCenter.default.post(name: ListViewController.refreshListViewNotificationName, object: nil)
//                self.handleBack()
//            }

        }
        
}


