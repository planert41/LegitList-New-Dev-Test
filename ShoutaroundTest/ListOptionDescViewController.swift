//
//  ListOptionNameViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 7/22/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit
import SVProgressHUD

class ListOptionDescViewController: UIViewController {
    
    
    var inputList: List? = nil
    
    let listOptionHeader: UILabel = {
        let label = UILabel()
        label.text = "Description"
        label.textAlignment = NSTextAlignment.left
        label.font = UIFont(name: "Poppins-Bold", size: 12)
        label.textColor = UIColor.ianBlackColor()
        return label
    }()
    
    let descInput: UITextView = {
        let tf = UITextView()
        tf.font = UIFont(font: .avenirNextRegular, size: 14)
        tf.backgroundColor = UIColor.white
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.ianLightGrayColor().cgColor
        return tf
    }()
    
    let clearButton: UIButton = {
        let button = UIButton()
        let headerTitle = NSAttributedString(string: "CLEAR ALL", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 12)])
        button.setAttributedTitle(headerTitle, for: .normal)
        button.addTarget(self, action: #selector(didTapClear), for: .touchUpInside)
        return button
        
    }()
    
    @objc func didTapClear(){
        self.descInput.text = ""
    }
    
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
        inputView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        view.addSubview(listOptionHeader)
        listOptionHeader.anchor(top: inputView.topAnchor, left: inputView.leftAnchor, bottom: nil, right: nil, paddingTop: 20, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        listOptionHeader.sizeToFit()
        
        view.addSubview(clearButton)
        clearButton.anchor(top: nil, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        clearButton.centerYAnchor.constraint(equalTo: listOptionHeader.centerYAnchor).isActive = true
        
        view.addSubview(descInput)
        descInput.anchor(top: listOptionHeader.bottomAnchor, left: listOptionHeader.leftAnchor, bottom: inputView.bottomAnchor, right: inputView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 40, paddingRight: 15, width: 0, height: 150)
        descInput.sizeToFit()
        descInput.becomeFirstResponder()
        
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
//        self.saveListDesc()
        self.handleBack()
    }
    
    @objc func didTapClose(){
        self.saveListDesc()
        self.handleBack()
    }
    
    func saveListDesc(){
        guard let inputList = inputList else {return}
        guard let listId = inputList.id else {return}
        guard let listDesc = descInput.text else {return}
        
        if listDesc.isEmptyOrWhitespace() {
            emptyListDesc()
        } else {
            updateListDesc()
        }
        
    }
    
    func emptyListDesc(){
        let optionsAlert = UIAlertController(title: "List Desciption", message: "Your list will not have a description", preferredStyle: UIAlertController.Style.alert)
        
        optionsAlert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { (action: UIAlertAction!) in
            // Allow Editing
            self.updateListDesc()
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
            return
        }))
        
        self.present(optionsAlert, animated: true, completion: nil)
    }
    
    func updateListDesc(){
        guard let inputList = inputList else {return}
        guard let listId = inputList.id else {return}
        guard let listDesc = descInput.text else {return}
        var tempList = self.inputList
        if tempList?.listDescription == listDesc {
            print(" No Update | Same Description | \(tempList?.name) | \(tempList?.listDescription)")
        } else {
            tempList?.listDescription = listDesc
            tempList?.needsUpdating = true
            listCache[listId] = tempList
            SVProgressHUD.showSuccess(withStatus: "Updated List Description To \(listDesc)")
            NotificationCenter.default.post(name: ListViewController.refreshListViewNotificationName, object: nil)
            print("Updated List Description To \(listDesc)")
        }
        self.handleBack()

        
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
