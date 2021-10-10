//
//  CreateNewListViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/15/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

var tempListCreated: List?

class CreateNewListCardController: UIViewController {

    // MARK: - Template Inputs

    var curList = List.init(id: NSUUID().uuidString, name: "", publicList: 1) {
        didSet {
            let name = curList.name
            self.listNameTextField.text = name.isEmptyOrWhitespace() ? nil : name
            let textCount: Int = (self.listNameTextField.text?.count ?? 0)
            self.listNameCount.text = "\(55 - textCount)"
            
        }
    }
    
    let topMargin: CGFloat = 24
    let topMarginBackgroundColor = UIColor.clear
    let headerTitle = "Name your List"
    
    let nextButton = TemplateObjects.newListNextButton()
    let exitCardButton = TemplateObjects.newListExitButton()
    
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
        label.text = "Name your List"
        return label
    }()
    
    // MARK: - BUTTONS FUNCTIONS


    @objc func handleNext() {
        let next = NewListDescCardController()
        let listName = listNameTextField.text ?? ""
        
        Database.checkListName(listName: listName) { listName in
            if listName.isEmptyOrWhitespace() {
                self.alert(title: "Create New List Error", message: "New List Needs a Name! 🤦‍♂️")
            } else {
                self.curList.name = listName
                tempListCreated = self.curList
                next.curList = self.curList
                self.navigationController?.pushViewController(next, animated: true)
            }
        }
    }
    
    let justCreateListLabel: UILabel = {
        let label = UILabel()
        label.layer.borderColor = UIColor.clear.cgColor
        label.textAlignment = .left
        label.font = UIFont(font: .avenirNextMedium, size: 16)
//        label.font = UIFont(name: "Poppins-Bold", size: 15)
        label.textColor = .mainBlue()
        label.text = "Create New List. Skip The Rest"
        return label
    }()
    
    
    @objc func skipAllCreeateNewList(){
        let listName = listNameTextField.text ?? ""
        
        Database.checkListName(listName: listName) { listName in
            if listName.isEmptyOrWhitespace() {
                self.alert(title: "Create New List Error", message: "New List Needs a Name! 🤦‍♂️")
            } else {
                self.curList.name = listName
                SVProgressHUD.show(withStatus: "Creating \(self.curList.name) List")
                Database.createList(uploadList: self.curList) {
                    self.dismiss(animated: true) {
                        print("CREATE NEW LIST COMPLETE | LIST VIEW DISMISSED")
                        tempListCreated =  nil
                        SVProgressHUD.dismiss()
                    }
                }
            }
        }

    }
    
    
    
    @objc func exitCard() {
        self.dismiss(animated: true) {
            print("exitCard")
            tempListCreated = nil
        }
    }
    
    let listNameTextField: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.backgroundColor = UIColor.clear
        tf.layer.borderColor = UIColor.lightGray.cgColor
        tf.layer.borderWidth = 1
        tf.autocorrectionType = .no
        return tf
    }()
    
    let listNameTextFieldUnderline: UIView = {
        let tf = UIView()
        tf.backgroundColor = UIColor.ianBlackColor()
        return tf
    }()

    let listNameCount: UILabel = {
        let label = UILabel()
        label.layer.borderColor = UIColor.clear.cgColor
        label.textAlignment = .left
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = .ianBlackColor()
        label.text = "55"
        return label
    }()

    override func viewDidAppear(_ animated: Bool) {
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupNavigationItems()
        self.listNameTextField.becomeFirstResponder()
        guard let temp = tempListCreated else {return}
        self.curList = temp
    }
    
    func setupNavigationItems(){
        self.navigationController?.isNavigationBarHidden = true
    }
    
    // MARK: - VIEWDIDLOAD

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("CreateNewList | INIT NEW LIST | \(self.curList.id)")
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
        headerLabel.sizeToFit()
        
        cardContainer.addSubview(listNameTextField)
        listNameTextField.anchor(top: headerLabel.bottomAnchor, left: headerLabel.leftAnchor, bottom: nil, right: exitCardButton.rightAnchor, paddingTop: 12, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        listNameTextField.delegate = self
        
        cardContainer.addSubview(listNameCount)
        listNameCount.anchor(top: nil, left: nil, bottom: nil, right: listNameTextField.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        listNameCount.centerYAnchor.constraint(equalTo: listNameTextField.centerYAnchor).isActive = true
        
        cardContainer.addSubview(listNameTextFieldUnderline)
        listNameTextFieldUnderline.anchor(top: listNameTextField.bottomAnchor, left: listNameTextField.leftAnchor, bottom: nil, right: listNameTextField.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 8)
        
        cardContainer.addSubview(nextButton)
        nextButton.anchor(top: listNameTextFieldUnderline.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 24, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0/*60*/, height: 55)
        nextButton.centerXAnchor.constraint(equalTo: listNameTextField.centerXAnchor).isActive = true
        nextButton.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
        nextButton.setTitle("  List Description", for: .normal)
        nextButton.sizeToFit()
        // Do any additional setup after loading the view.
        
        cardContainer.addSubview(justCreateListLabel)
        justCreateListLabel.anchor(top: nextButton.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 25, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        justCreateListLabel.centerXAnchor.constraint(equalTo: listNameTextField.centerXAnchor).isActive = true
        justCreateListLabel.isUserInteractionEnabled = true 
        justCreateListLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(skipAllCreeateNewList)))
                
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

// MARK: - TEXTFIELD

extension CreateNewListCardController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let char = string.cString(using: String.Encoding.utf8)!
        let isBackSpace = strcmp(char, "\\b")
        let textCount = (textField.text?.count ?? 0) + ((isBackSpace == -92) ? -1 : 1)
        listNameCount.text = "\(55 - textCount)"
        self.nextButton.isSelected = (textCount > 0)
        return true

        
    }
}
