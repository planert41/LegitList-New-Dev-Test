//
//  ListOptionsTableViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 7/22/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit

import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth
import SVProgressHUD

protocol ListOptionsTableViewControllerDelegate {
    func didDeleteList(listId: String?)
}

class ListOptionsTableViewController: UITableViewController {

    var delegate: ListOptionsTableViewControllerDelegate?
    var inputList: List? = nil {
        didSet {
            guard let inputList = inputList else {return}
            self.listName = inputList.name
            self.listDescription = inputList.listDescription ?? ""
            self.listUrl = inputList.listUrl ?? ""
            self.refreshTableView()
        }
    }
    var listOptionHeaders = ["List Name", "Description", "Header Image", "List Url", "Delete List"]
    var listOptionDetailsDefault = ["Add List Name", "Add Description", "Add Header Photo", "Add a URL", "Tap to Delete List"]
    var listOptionDetails: [String] = []

    var listName: String = ""
    var listDescription: String = ""
    var headerImageString = "Select From List Or Library"
    var listUrl: String = ""
    var listDelete: String = "Delete List"

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.lightBackgroundGrayColor()
        setupNavigationItems()
        setupTableView()
        tableView.reloadData()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        NotificationCenter.default.addObserver(self, selector: #selector(refreshList), name: ListViewController.refreshListViewNotificationName, object: nil)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleBackPressNav))
        swipeRight.direction = .right
        self.tableView.addGestureRecognizer(swipeRight)
        
    }
    
    @objc func refreshList(){
        guard let listId = inputList?.id else {return}
        Database.fetchListforSingleListId(listId: listId) { (list) in
            guard let list = list else {
                print("ListOptionTableView | refreshList ERROR | No List Found | \(listId)")
                return}
            self.inputList = list
        }
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
        if inputList!.needsUpdating {
            let optionsAlert = UIAlertController(title: "List Options", message: "All your changes will be discarded if you continue.", preferredStyle: UIAlertController.Style.alert)
            
            optionsAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                // Allow Editing
                self.dismiss(animated: true)
            }))
            
            optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            }))
            
            present(optionsAlert, animated: true, completion: nil)
            
            
        } else {
            self.dismiss(animated: true)
        }
//        self.handleBack()
    }
    
    func refreshTableView(){
        listOptionDetails = [listName, listDescription, headerImageString, listUrl, listDelete] as! [String]
        tableView.reloadData()
    }
    
    var optionCellId = "Option Cell"
    
    func setupTableView(){
        
        tableView.register(ListOptionTableViewCell.self, forCellReuseIdentifier: optionCellId)
        
    }
    
    @objc func didTapClose(){
        Database.updateListDetails(list: inputList, heroImageUrl: inputList?.heroImageUrl, heroImageUrlPostId: inputList?.heroImageUrlPostId, listName: inputList?.name, description: inputList?.listDescription, listUrl: inputList?.listUrl)
        
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 5
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: optionCellId, for: indexPath) as! ListOptionTableViewCell

        cell.optionHeader = listOptionHeaders[indexPath.row]
        cell.optionDetail = (listOptionDetails[indexPath.row] == "") ? listOptionDetailsDefault[indexPath.row] : listOptionDetails[indexPath.row]
        
        
    // Header Image
        if indexPath.row == 2 {
            if let url = self.inputList?.heroImageUrl {
                cell.heroImageView.loadImage(urlString: url)
                cell.heroImageView.isHidden = false
                if self.inputList?.postIds?[inputList?.heroImageUrlPostId ?? ""] != nil {
                    cell.optionDetail = "Selected From List"
                } else if inputList?.heroImageUrlPostId != "" {
                    cell.optionDetail = "Selected From Library"
                } else {
                    cell.optionDetail = "Selected From Other Images"
                }
            } else {
                cell.heroImageView.isHidden = true
            }
            
        }
        
        else if indexPath.row == 4 {
            cell.optionHeader = "Delete List"
            cell.optionDetail = ""
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        print("Selected \(indexPath.row) | List \(self.inputList?.name)")
        if indexPath.row == 0 {
            let nextScreen = ListOptionTextboxInputViewController()
            nextScreen.inputList = self.inputList
            nextScreen.listNameInput.text = self.listName
            nextScreen.inputType = .listName
            self.navigationController?.pushViewController(nextScreen, animated: true)
        } else if indexPath.row == 1 {
            let nextScreen = ListOptionDescViewController()
            nextScreen.inputList = self.inputList
            nextScreen.descInput.text = self.listDescription
            self.navigationController?.pushViewController(nextScreen, animated: true)
        } else if indexPath.row == 2 {
            print("New Pic")
            let nextScreen = ListOptionsPhotoTableViewController()
            nextScreen.inputList = self.inputList
            self.navigationController?.pushViewController(nextScreen, animated: true)
        } else if indexPath.row == 3 {
            print("New List URL")
            let nextScreen = ListOptionTextboxInputViewController()
            nextScreen.inputList = self.inputList
            nextScreen.listNameInput.text = self.listUrl
            nextScreen.inputType = .listUrl
            self.navigationController?.pushViewController(nextScreen, animated: true)
        }   else if indexPath.row == 4 {
            self.userOptionDeleteList()
        }
        
    }
    func userOptionDeleteList(){
        
        let optionsAlert = UIAlertController(title: "Delete List", message: "Are you sure you want to delete your beloved \(inputList?.name) list?", preferredStyle: UIAlertController.Style.alert)

        
        optionsAlert.addAction(UIAlertAction(title: "Yes Kill IT!", style: .default, handler: { (action: UIAlertAction!) in
            // Delete List in Database
            guard let list = self.inputList else {return}
            // Delete List in Database
            SVProgressHUD.show(withStatus: "Deleting \(self.inputList?.name) List")
            Database.deleteList(uploadList: list)
            self.delegate?.didDeleteList(listId: list.id)
//            self.navigationController?.popToRootViewController(animated: true)
            self.dismiss(animated: true) {
                SVProgressHUD.dismiss()
            }
            
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        present(optionsAlert, animated: true) {
            optionsAlert.view.superview?.isUserInteractionEnabled = true
            optionsAlert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.alertClose(gesture:))))
        }
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
