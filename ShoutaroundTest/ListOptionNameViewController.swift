//
//  ListOptionNameViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 7/22/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit
import SVProgressHUD

protocol ListOptionNameViewControllerDelegate {
    //    func listSelected(list: List?)
    //func changeListName(name: String?)
    //func changeListUrl(url: String?)

}


class ListOptionTextboxInputViewController: UIViewController {

    
    var inputList: List? = nil
    
    var inputType = InputType.listName {
        didSet {
            if inputType == .listName {
                listOptionHeader.text = "List Name"
                listNameInput.placeholder = " Add List Name"
            } else if inputType == .listUrl {
                listOptionHeader.text = "List Url"
                listNameInput.placeholder = " Add List Url"
            }
        }
    }
    var emojiFontSize: CGFloat? = nil
    
    enum InputType {
        case listName
        case listUrl
    }
    
    
    
    let listOptionHeader: UILabel = {
        let label = UILabel()
        label.text = "List Name"
        label.textAlignment = NSTextAlignment.left
        label.font = UIFont(name: "Poppins-Bold", size: 12)
        label.textColor = UIColor.ianBlackColor()
        return label
    }()
    
    let listNameInput: PaddedTextField = {
        let tf = PaddedTextField()
        tf.placeholder = "Add List Name"
        tf.font = UIFont(font: .avenirNextRegular, size: 14)
        tf.backgroundColor = UIColor.white
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.ianLightGrayColor().cgColor
        return tf
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationItems()
        self.view.backgroundColor = UIColor.lightBackgroundGrayColor()
        
        let inputView = UIView()
        inputView.layer.borderColor = UIColor.ianLightGrayColor().cgColor
        inputView.layer.borderWidth = 1
        inputView.backgroundColor = UIColor.white
        inputView.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.15, x: 0, y: 0, blur: 3, spread: 0)
        
        view.addSubview(inputView)
        inputView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 30, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 100)
        
        view.addSubview(listOptionHeader)
        listOptionHeader.anchor(top: inputView.topAnchor, left: inputView.leftAnchor, bottom: nil, right: nil, paddingTop: 20, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        listOptionHeader.sizeToFit()
        
        view.addSubview(listNameInput)
        listNameInput.anchor(top: listOptionHeader.bottomAnchor, left: listOptionHeader.leftAnchor, bottom: nil, right: inputView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 0, height: 30)
        listNameInput.sizeToFit()
        listNameInput.becomeFirstResponder()

        // Do any additional setup after loading the view.
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
        let closeTitle = NSAttributedString(string: "SAVE", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 12)])
        closeButton.setAttributedTitle(closeTitle, for: .normal)
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        
        let closeNavButton = UIBarButtonItem.init(customView: closeButton)
        self.navigationItem.rightBarButtonItem = closeNavButton
        
        let navBackButton = UIButton()
        navBackButton.addTarget(self, action: #selector(handleBackPressNav), for: .touchUpInside)
        navBackButton.setImage((#imageLiteral(resourceName: "navBackImage").resizeImageWith(newSize: CGSize(width: 15, height: 15))).withRenderingMode(.alwaysTemplate), for: .normal)
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
    
    func didTapClose(){
        if self.listNameInput.text == nil || (self.listNameInput.text?.isEmptyOrWhitespace() ?? true) {
            if inputType == .listName {
                self.alert(title: "List Name Error", message: "Please Insert A List Name")
                return
            }
        }
        
        if inputType == .listName {
            if inputList?.name != self.listNameInput.text {
                self.saveListName()
            }
        } else if inputType == .listUrl {
            if inputList?.listUrl != self.listNameInput.text {
                self.saveListUrl()
            }
        }
        
        self.handleBack()
    }
    
    func saveListName(){
        guard let inputList = inputList else {return}
        guard let listId = inputList.id else {return}
        guard let listName = listNameInput.text else {return}
        
        if listName.isEmptyOrWhitespace() {
            self.alert(title: "List Name Error", message: "Please insert a list name")
        } else if listName == inputList.name {
            print(" No Change | saveListName | Same List Name \(listName) | \(inputList.name)")
        }
        else
        {
            var tempList = self.inputList
            tempList?.needsUpdating = true
            tempList?.name = listName
            listCache[listId] = tempList
            SVProgressHUD.showSuccess(withStatus: "Updated List Name To \(listName)")
            print("Updated List Name To \(listName)")
            NotificationCenter.default.post(name: ListViewController.refreshListViewNotificationName, object: nil)
        }
    }
    
    func saveListUrl(){
        guard let inputList = inputList else {return}
        guard let listId = inputList.id else {return}
        guard let listName = listNameInput.text else {return}
        
        if listName == inputList.listUrl {
            print(" No Change | saveListUrl | Same List Url \(listName) | \(inputList.listUrl)")
        }
        else
        {
            var tempList = self.inputList
            tempList?.needsUpdating = true
            tempList?.listUrl = listName
            listCache[listId] = tempList
            SVProgressHUD.showSuccess(withStatus: "Updated List Url To \(listName)")
            print("Updated List Url To \(listName)")
            NotificationCenter.default.post(name: ListViewController.refreshListViewNotificationName, object: nil)
        }
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
