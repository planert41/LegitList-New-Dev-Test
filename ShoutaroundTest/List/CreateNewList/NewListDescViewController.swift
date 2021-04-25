//
//  CreateNewListViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/15/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit

class NewListDescCardController: UIViewController {

    // MARK: - Template Inputs
    
    var curList: List? = nil {
        didSet {
            guard let curList = curList else {return}
            let desc = curList.listDescription ?? ""
            if desc.isEmptyOrWhitespace()
            {
                self.listDescTextView.attributedText = textViewPlaceholder
            } else {
                self.listDescTextView.text = desc
            }
        }
    }
    
    let topMargin: CGFloat = 24
    let topMarginBackgroundColor = UIColor.clear
    let headerTitle = "What is it about?"

    let nextButton = TemplateObjects.newListNextButton()
    let exitCardButton = TemplateObjects.newListExitButton()
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
        label.font = UIFont(name: "Poppins-Bold", size: 30)
        label.textColor = .ianBlackColor()
        return label
    }()
    

    
    let textViewPlaceholder = NSMutableAttributedString(string: "Describe your new list", attributes: [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.ianGrayColor()])

    
    let listDescTextView: UITextView = {
        let tv = UITextView()
        tv.isScrollEnabled = true
        tv.textContainerInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        tv.layer.borderColor = UIColor.lightGray.cgColor
        tv.layer.borderWidth = 1
        tv.textContainer.lineBreakMode = .byTruncatingTail
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.font = UIFont.boldSystemFont(ofSize: 14)
        tv.textColor = UIColor.legitColor()
        tv.isEditable = true
        tv.attributedText = NSMutableAttributedString(string: "Describe your new list", attributes: [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.ianGrayColor()])
        return tv
    }()
    
    
    let listNameTextFieldUnderline: UIView = {
        let tf = UIView()
        tf.backgroundColor = UIColor.ianBlackColor()
        return tf
    }()

    let listDescCount: UILabel = {
        let label = UILabel()
        label.layer.borderColor = UIColor.clear.cgColor
        label.textAlignment = .left
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = .ianBlackColor()
        label.text = "1500"
        return label
    }()
    

    override func viewDidAppear(_ animated: Bool) {
//        setupNavigationItems()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupNavigationItems()
        self.listDescTextView.becomeFirstResponder()
        guard let temp = tempListCreated else {return}
        self.curList = temp
    }
    
    func setupNavigationItems(){
        self.navigationController?.isNavigationBarHidden = true
    }
    
    // MARK: - VIEWDIDLOAD

    
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
        
        cardContainer.addSubview(listDescTextView)
        listDescTextView.anchor(top: headerLabel.bottomAnchor, left: cardContainer.leftAnchor, bottom: nil, right: cardContainer.rightAnchor, paddingTop: 12, paddingLeft: 24, paddingBottom: 0, paddingRight: 24, width: 0, height: 160)
        listDescTextView.delegate = self
        
        cardContainer.addSubview(listDescCount)
        listDescCount.anchor(top: nil, left: nil, bottom: listDescTextView.bottomAnchor, right: listDescTextView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 10, width: 0, height: 0)
        
        cardContainer.addSubview(listNameTextFieldUnderline)
        listNameTextFieldUnderline.anchor(top: listDescTextView.bottomAnchor, left: listDescTextView.leftAnchor, bottom: nil, right: listDescTextView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 8)
        
        cardContainer.addSubview(nextButton)
        nextButton.anchor(top: listNameTextFieldUnderline.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 24, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 60, height: 55)
        nextButton.centerXAnchor.constraint(equalTo: listDescTextView.centerXAnchor).isActive = true
        nextButton.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
        nextButton.isSelected = true
        
        
        cardContainer.addSubview(backButton)
        backButton.anchor(top: nil, left: nil, bottom: nil, right: nextButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        backButton.centerYAnchor.constraint(equalTo: nextButton.centerYAnchor).isActive = true
        backButton.sizeToFit()
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        
        // Do any additional setup after loading the view.
    }
    
    // MARK: - BUTTONS FUNCTIONS

    
    @objc func didTapBack() {
//        let createNewListView = CreateNewListCardController()
//        if let list = self.curList {
//            createNewListView.curList = list
//        }

        self.navigationController?.popViewController(animated: true)

        
//          let transition:CATransition = CATransition()
//            transition.duration = 0.5
//        transition.subtype = CATransitionSubtype.fromRight
//            self.navigationController!.view.layer.add(transition, forKey: kCATransition)
//        self.navigationController?.pushViewController(createNewListView, animated: true)
    }
    
    
    @objc func didTapNext() {
        let listDesc = listDescTextView.text ?? ""
        if listDesc.isEmptyOrWhitespace() || listDescTextView.attributedText == textViewPlaceholder {
            self.checkEmptyDesc()
        } else {
            self.handleNext()
        }
    }
    
    @objc func checkEmptyDesc() {
        let message = "New List Has No Description. Tell People What It's About."
        let alert = UIAlertController(title: "Create New List", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction!) in
            self.handleNext()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("checkEmptyDesc |  Cancel")
            return
        }))
        self.present(alert, animated: true) {
        }
    }
    
    @objc func handleNext() {
        let createNewListView = NewListCoverImageCardController()
        let listDesc = listDescTextView.text ?? ""
        
        if listDesc.isEmptyOrWhitespace() || listDescTextView.attributedText == textViewPlaceholder {
            self.curList?.listDescription = nil
        } else {
            self.curList?.listDescription = ((listDesc.isEmptyOrWhitespace()) ? nil : listDesc)!
        }
        
        tempListCreated = self.curList
        createNewListView.curList = self.curList

//          let transition:CATransition = CATransition()
//            transition.duration = 0.5
//    //        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
//    //        transition.type = CATransitionType.push
//        transition.subtype = CATransitionSubtype.fromLeft
//            self.navigationController!.view.layer.add(transition, forKey: kCATransition)
        self.navigationController?.pushViewController(createNewListView, animated: true)
        
    }
    
    @objc func exitCard() {
        self.dismiss(animated: true) {
            print("exitCard")
            tempListCreated = nil
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

// MARK: - TEXTVIEW

extension NewListDescCardController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.ianGrayColor() {
            textView.text = nil
            textView.font = UIFont.systemFont(ofSize: 14)
            textView.textColor = UIColor.ianBlackColor()
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.attributedText = textViewPlaceholder
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.attributedText == textViewPlaceholder {
            self.listDescCount.text = "1500"
        } else {
            self.listDescCount.text = "\(1500 - textView.text.count)"
        }
        
        
    }
    
}
