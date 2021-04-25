//
//  TagPhotoToListView.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/12/20.
//  Copyright © 2020 Wei Zou Ang. All rights reserved.
//

import UIKit


class TagPhotoToListView: UIViewController {

    
    let cancelButton: UIButton = {
        let button = UIButton()
        var iconImage = #imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysTemplate)
        button.setImage(iconImage, for: .normal)
        button.tintColor = UIColor.ianBlackColor()
        button.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        button.tag = 0
        return button
    } ()
    
    let nextButton: UIButton = {
        let button = UIButton()
        var iconImage = #imageLiteral(resourceName: "photo_upload_check").withRenderingMode(.alwaysOriginal)
        button.setImage(iconImage, for: .normal)
        button.tintColor = UIColor.ianBlackColor()
        button.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
        button.tag = 0
        return button
    } ()
    
    @objc func handleNext(){
//        self.updatePostDic()
//
//        if self.isEditingPost {
//            self.handleEditPost()
//        } else if self.isBookmarkingPost {
//            self.handleAddPostToList()
//        } else {
//            self.handleShareNewPost()
//        }
    }
    
    let addListButton: UIButton = {
        let button = UIButton()
        var iconImage = #imageLiteral(resourceName: "add_color").withRenderingMode(.alwaysOriginal)
        button.setImage(iconImage, for: .normal)
        button.setTitle("CREATE LIST", for: .normal)
        button.setTitleColor(UIColor.ianLegitColor(), for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 12)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        button.backgroundColor = UIColor.white
        button.layer.borderWidth = 1
        button.titleLabel?.textAlignment = NSTextAlignment.left
        button.layer.borderColor = UIColor.rgb(red: 221, green: 221, blue: 221).cgColor
//        button.addTarget(self, action: #selector(initAddList), for: .touchUpInside)
        return button
    } ()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.backgroundGrayColor()

        setupNavigationItems()


        // Do any additional setup after loading the view.
    }
    

    func setupNavigationItems() {
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationController?.navigationBar.tintColor = UIColor.ianLegitColor()
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.setNeedsStatusBarAppearanceUpdate()
        
        navigationController?.view.backgroundColor = UIColor.white
        //            let attributedString = NSMutableAttributedString(string: " " + String(post.listCount), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 15), NSForegroundColorAttributeName: UIColor.darkGray])

        
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 25), NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor()]
        navigationController?.navigationBar.layoutIfNeeded()
        navigationController?.title = "Tag To List"
        
        let leftButton = UIBarButtonItem.init(customView: cancelButton)
        self.navigationItem.leftBarButtonItem = leftButton
        
        let rightButton = UIBarButtonItem.init(customView: nextButton)
        self.navigationItem.rightBarButtonItem = rightButton
    }
    
}
