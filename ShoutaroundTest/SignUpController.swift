//
//  ViewController.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/23/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import FBSDKLoginKit
import IQKeyboardManagerSwift
import SVProgressHUD
import GooglePlaces
import AuthenticationServices


protocol SignUpControllerDelegate {
    func successSignUp()
}

class SignUpController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate, AppleSearchDelegate {

    var FBCredentials: AuthCredential?
    var delegate: SignUpControllerDelegate?
    var newUserAutoFollow: Bool = false
    var allowDefaultPhoto: Bool = false
    var testUserSignUp: Bool = false
    
    var editUserInd: Bool = false {
        didSet{
            if editUserInd {
                self.cancelButton.isHidden = false
                self.signUpButton.isHidden = false
            } else {
                self.cancelButton.isHidden = true
                self.signUpButton.isHidden = false
            }

//            photoTopPadding.constant = self.editUserInd ? 60 : 40
        }
    }
    
    var defaultPassword = "XXXXXX"
    var editUser: User? {
        didSet{
            if editUserInd {
                let user = Auth.auth().currentUser
                if let user = user {
                    self.emailTextField.text = user.email
                    self.usernameTextField.text = editUser?.username
                    
                    // Disable Password
                    self.passwordTextField.text = defaultPassword
                    self.confirmPasswordTextField.text = defaultPassword
//                    self.passwordTextField.isEnabled = false
                    self.confirmPasswordTextField.isEnabled = false
                    self.userCityTextField.text = editUser?.userCity

                    
                    // Load Edit User Photo
                    loadCurrentUserPhoto()
                }
            }
        }
    }
    
    @objc func loadCurrentUserPhoto() {
        // Load Edit User Photo
        if let imageUrl = editUser?.profileImageUrl {
            if let cache = imageCache[imageUrl] {
                self.updatePhoto(image: cache)
                self.originalImageData = cache.pngData()
                self.originalImage = cache
                self.updateImage = false
            }
            else
            {
                let profileImageView = CustomImageView()
                profileImageView.loadImage(urlString: imageUrl)
                self.updatePhoto(image: profileImageView.image)
                self.originalImageData = profileImageView.image?.pngData()
                self.originalImage = profileImageView.image
                self.updateImage = false
            }
        } else {
            self.originalImageData = nil
            self.originalImage = nil
        }
    }
    
    
    var originalImage: UIImage?
    var originalImageData: Data?
    
//    let cancelButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setImage(#imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysOriginal), for: .normal)
//        button.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
//        return button
//    }()
    
    let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.clear
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitleColor(.red, for: .normal)
        button.setTitle("Cancel", for: .normal)
        button.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        //        button.isEnabled = false
        return button
    }()
    
    @objc func handleCancel() {
        self.dismiss(animated: true, completion: nil)
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        if editUserInd{
//            self.view.frame.origin.y += 20
//        }
//    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        if editUserInd{
//            self.view.frame.origin.y += 40
//        }
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        if editUserInd{
//            self.view.frame.origin.y += 40
//        }
//    }

    
    let plusPhotoButton: UIButton = {
        
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "plus_photo").withRenderingMode(.alwaysOriginal), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handlePlusPhoto), for: .touchUpInside)
        button.backgroundColor = UIColor.white
        button.layer.borderColor = UIColor.ianLegitColor().cgColor

        return button
        
    } ()
    
    let photoDisplayHeight = 150 as CGFloat
    
    lazy var photoCancelButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        button.setImage(#imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysOriginal), for: .normal)
        button.backgroundColor = UIColor.clear
        button.addTarget(self, action: #selector(loadCurrentUserPhoto), for: .touchUpInside)
        return button
    }()

    
    @objc func handlePlusPhoto(){
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            print("Image Picker Complete | Showing Edited Image")
            self.updatePhoto(image: editedImage)
//            plusPhotoButton.setImage(editedImage.withRenderingMode(.alwaysOriginal), for: .normal)
            
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            print("Image Picker Complete | Showing Original Image")
            self.updatePhoto(image: originalImage)
//            plusPhotoButton.setImage(originalImage.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        
        self.handleTextInputChange()
        
        picker.dismiss(animated: true, completion: nil)
        
//        dismiss(animated: true, completion: nil)
        
    }
    
    
    
    let emailTextField: PaddedTextField = {
        let tf = PaddedTextField()
        tf.placeholder = "Email"
//        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.boldSystemFont(ofSize: 15)
        tf.backgroundColor = UIColor.white
        tf.layer.borderColor = UIColor.ianLegitColor().cgColor
        tf.layer.borderWidth = 0

        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        
        return tf
    }()
        
    @objc func handleTextInputChange(){

        var isFormValid: Bool = false
        
        if self.editUserInd {
            self.checkUpdate()
            isFormValid = updateUsername||updateImage||updateEmail||updateCity
        } else {
            isFormValid = emailTextField.text?.count ?? 0 > 0 && usernameTextField.text?.count ?? 0 > 0 && userCityTextField.text?.count ?? 0 > 0 && (appleUid != nil ? true : passwordTextField.text?.count ?? 0 > 0)
        
            if passwordTextField.text != confirmPasswordTextField.text {
                confirmPasswordTextField.backgroundColor = UIColor.red
            } else {
                confirmPasswordTextField.backgroundColor = UIColor(white: 0, alpha: 0.03)
            }
            
            if isFormValid {
                signUpButton.isEnabled = true
                signUpButton.backgroundColor = UIColor.ianBlueColor()

    //            signUpButton.backgroundColor = UIColor.rgb(red: 17, green: 154, blue: 237)
            } else {
                signUpButton.isEnabled = false
                signUpButton.backgroundColor = UIColor.ianBlueColor().withAlphaComponent(0.2)
    //            signUpButton.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
            }
            print("handleTextInputChange: \(isFormValid)")
        
        }
    }
    
    
    let usernameTextField: PaddedTextField = {
        let tf = PaddedTextField()
        tf.placeholder = "Username"
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.backgroundColor = UIColor.white

        tf.borderStyle = .roundedRect
        tf.font = UIFont.boldSystemFont(ofSize: 15)
        tf.layer.borderColor = UIColor.ianLegitColor().cgColor
        tf.layer.borderWidth = 0

        
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        
        return tf
        
    }()
    
    let passwordTextField: PaddedTextField = {
        let tf = PaddedTextField()
        tf.placeholder = "Password"
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.boldSystemFont(ofSize: 15)
        tf.isSecureTextEntry = true
        tf.backgroundColor = UIColor.white
        tf.layer.borderColor = UIColor.ianLegitColor().cgColor
        tf.layer.borderWidth = 0
        
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
        
    }()
    
    let confirmPasswordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Confirm Password"
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.isSecureTextEntry = true
        tf.backgroundColor = UIColor.white

        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
        
    }()
    
    let statusTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Status/About You"
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        
        return tf
        
    }()
    
    let userCityTextField: PaddedTextField = {
        let tf = PaddedTextField()
        tf.placeholder = "Current City"
//        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.boldSystemFont(ofSize: 15)
        tf.backgroundColor = UIColor.white
        tf.layer.borderColor = UIColor.ianLegitColor().cgColor
        tf.layer.borderWidth = 0
        
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        
        return tf
    }()
    
    var tempUserCityLoc: CLLocation?
    
    func presentSearchCity() {
        // APPLE CITY SEARCH
        let autocompleteController = ApplePlaceSearchTableViewController()
        autocompleteController.delegate = self
        if let input = self.userCityTextField.text {
            if !(input.isEmptyOrWhitespace() ?? true) {
                autocompleteController.inputText = input
            }
        }


//        // GOOGLE CITY SEARCH
//        let autocompleteController = GMSAutocompleteViewController()
//        autocompleteController.delegate = self
//        
//        let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt(GMSPlaceField.name.rawValue) |
//          UInt(GMSPlaceField.placeID.rawValue))
//        autocompleteController.placeFields = fields
//
//        // Specify a filter.
//        let filter = GMSAutocompleteFilter()
//        filter.type = .city
//        autocompleteController.autocompleteFilter = filter

//        // Display the autocomplete view controller.
//        let temp = UINavigationController(rootViewController: autocompleteController)
        self.userCityTextField.resignFirstResponder()
        autocompleteController.searchType = .city
        present(autocompleteController, animated: true, completion: nil)

//        self.navigationController?.pushViewController(autocompleteController, animated: true)
    }
    
    func locationSelected(name: String, loc: CLLocation?) {
        self.tempUserCityLoc = loc
        self.userCityTextField.text = name
        self.handleTextInputChange()
        
        var userCity = self.userCityTextField.text
        var userCityLoc = self.tempUserCityLoc

        var cityLatitude: String?
        var cityLongitude: String?
        var cityGPS: String?
        
        if userCityLoc == nil {
            cityGPS = nil
        } else {
            cityLatitude = String(format: "%f", (userCityLoc!.coordinate.latitude))
            cityLongitude = String(format: "%f", (userCityLoc!.coordinate.longitude))
            cityGPS = cityLatitude! + "," + cityLongitude!
        }
    
        let dictionaryValues = ["userLocation": cityGPS, "userCity": userCity] as [String : Any]
        print("locationSelected : ", userCity, cityGPS)
    }
    
    
    let updatePasswordButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.legitColor()
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.white, for: .normal)
        button.setTitle("Update Password", for: .normal)
        button.addTarget(self, action: #selector(updatePasswordInput), for: .touchUpInside)
//        button.isEnabled = false
        return button
    }()

    
    let signUpButton: UIButton = {
        
        let button = UIButton(type: .system)
//        button.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
        button.backgroundColor = UIColor.ianLegitColor()

        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.white, for: .normal)
        button.setTitle("Sign Up", for: .normal)
//        button.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    
    let alreadyHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        
        
//        let attributedTitle = NSMutableAttributedString(string: "Already have an account? ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 14), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.lightGray]))
//
//        attributedTitle.append(NSAttributedString(string: "Sign In", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.rgb(red: 17, green: 154, blue: 237)])))
        
        let attributedTitle = NSMutableAttributedString(string: "Back To Sign In", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Poppins-Bold", size: 20), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.ianLegitColor()]))
        
        
        button.setAttributedTitle(attributedTitle, for: .normal)
        
        button.addTarget(self, action: #selector(signIn), for: .touchUpInside)
        return button
    }()
    
    @objc func signIn() {
        let login = LoginController()
        self.navigationController?.pushViewController(login, animated: true)
    }
    
    var updateImage: Bool = false {
        didSet {
            self.photoCancelButton.isHidden = !updateImage
        }
    }
    var updateEmail: Bool = false
    var updateUsername: Bool = false
    var updateCity: Bool = false
    var updatePassword: Bool = false

    
    func checkUpdate(){
        if !self.editUserInd {
            return
        }
        // Check if Image is the same
        if let newImageData = plusPhotoButton.currentImage!.pngData() {
            if newImageData == originalImageData {
                updateImage = false
            } else {
                updateImage = true
            }
        }
        plusPhotoButton.layer.borderColor = updateImage ? UIColor.ianLegitColor().cgColor : UIColor.black.cgColor
        
        // Check if Email is the same
        if let newEmail = emailTextField.text {
            if newEmail == Auth.auth().currentUser?.email {
                updateEmail = false
            } else {
                updateEmail = true
            }
        }
        emailTextField.layer.borderWidth = updateEmail ? 2 : 0

        
        // Check if Username is the same
        var newUsername = self.usernameTextField.text
        newUsername = newUsername?.replacingOccurrences(of: " ", with: "")
        if newUsername?.first != "@" {
            newUsername = "@" + newUsername!
        }
        
        if let newUsername = newUsername {
            if newUsername == editUser?.username {
                updateUsername = false
            } else {
                updateUsername = true
            }
        }
        usernameTextField.layer.borderWidth = updateUsername ? 2 : 0
        
        var newPassword = self.passwordTextField.text
        if newPassword != defaultPassword {
            if !(newPassword?.isEmptyOrWhitespace() ?? true) {
                updatePassword = true
            }
        }
        passwordTextField.layer.borderWidth = updatePassword ? 2 : 0

        
        var newCity = self.userCityTextField.text
        if let newCity = newCity {
            if newCity == editUser?.userCity {
                updateCity = false
            } else {
                updateCity = true
            }
        }
        userCityTextField.layer.borderWidth = updateCity ? 2 : 0

        var isFormValid = updateUsername||updateImage||updateEmail||updateCity
        
        if isFormValid {
            signUpButton.isEnabled = true
            signUpButton.backgroundColor = UIColor.ianBlueColor()

//            signUpButton.backgroundColor = UIColor.rgb(red: 17, green: 154, blue: 237)
        } else {
            signUpButton.isEnabled = false
            signUpButton.backgroundColor = UIColor.ianBlueColor().withAlphaComponent(0.2)
//            signUpButton.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
        }
        
        print("CHECKED EDITS | updateImage \(updateImage) | updateEmail \(updateEmail) | updateUsername \(updateUsername) | updateUserCity \(updateCity)")
    }
    
    
    @objc func confirmEdit() {
        
        self.signUpButton.isEnabled = false
        self.checkUpdate()
        
        let fieldAttribute = [NSAttributedString.Key.font: UIFont(name: "Poppins-Regular", size: 12), NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        let changeAttribute = [NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 13), NSAttributedString.Key.foregroundColor: UIColor.black]

        let myString = NSMutableAttributedString(string: "", attributes: fieldAttribute)

        
        var updateString: String = ""
        if updateImage {
            updateString += "New Image Update \n"
            myString.append(NSMutableAttributedString(string: "New Image Update \n", attributes: fieldAttribute))
        }
        
        if updateEmail{
            if let newEmail = emailTextField.text {
                updateString += "New Email Update to \(newEmail) \n"
                myString.append(NSMutableAttributedString(string: "New Email Update to \n", attributes: fieldAttribute))
                myString.append(NSMutableAttributedString(string: "\(newEmail) \n", attributes: changeAttribute))
            }
        }
        
        var newUsername = self.usernameTextField.text
        newUsername = newUsername?.replacingOccurrences(of: " ", with: "")
        if newUsername?.first != "@" {
            newUsername = "@" + newUsername!
        }
        
        if updateUsername{
            myString.append(NSMutableAttributedString(string: "New Username Update to \n", attributes: fieldAttribute))
            myString.append(NSMutableAttributedString(string: "\(newUsername) \n", attributes: changeAttribute))
            updateString += "New Username Update to \(newUsername!) \n"
        }
        
        var newPassword = self.passwordTextField.text
        
        if updatePassword{
            updateString += "New Password Update to \(newPassword!) \n"
            myString.append(NSMutableAttributedString(string: "New Password Update to \n", attributes: fieldAttribute))
            myString.append(NSMutableAttributedString(string: "\(newPassword) \n", attributes: changeAttribute))
        }
        
        if updateCity{
            var newCity = String(describing: self.userCityTextField.text!)
            updateString += "New User City Update to \(newCity) \n"
            myString.append(NSMutableAttributedString(string: "New User City Update to \n", attributes: fieldAttribute))
            myString.append(NSMutableAttributedString(string: "\(newCity) \n", attributes: changeAttribute))
        }
        
        
        if !updateImage && !updateEmail && !updateUsername && !updateCity {
            updateString = "No Profile Changes"
            myString.append(NSMutableAttributedString(string: "No Profile Changes \n", attributes: changeAttribute))
        }
        
        let editAlert = UIAlertController(title: "Edit User", message: updateString, preferredStyle: UIAlertController.Style.alert)
        editAlert.setValue(myString, forKey: "attributedMessage")
        editAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            self.handleEditUser()
        }))
        
        editAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        present(editAlert, animated: true, completion: nil)
        self.signUpButton.isEnabled = true

    }
    
    @objc func handleEditUser(){
        print("handleEditUser")
        SVProgressHUD.show(withStatus: "Editing User")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Update Username Error: No UID")
            let message = "Update Username Error: No UID |"
            return
        }
        
        let editGroup = DispatchGroup()
        var updateValue:[String:Any] = [:]

        if self.updateEmail {
            editGroup.enter()
            Auth.auth().currentUser?.updateEmail(to: self.emailTextField.text!, completion: { (error) in
                if let error = error {
                    print("Firebase Update Current User Email: Error", error)
                    let message = "Failed to update email into Database |" + error.localizedDescription
                    let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction!) in
                        self.signUpButton.isEnabled = true
                    }))
                    self.present(alert, animated: true, completion: nil)
                    editGroup.leave()
                } else {
                    print("Edit User Email | SUCCESS | \(Auth.auth().currentUser?.email)")
                    editGroup.leave()
                }
            })
        }
        
        if self.updatePassword {
            self.updatePasswordConfirm(newPassword: passwordTextField.text)
        }
        
        if self.updateImage {
            
            guard let image = self.plusPhotoButton.imageView?.image else {return}
            guard let uploadData = image.jpegData(compressionQuality: 0.3) else {return}
            
            editGroup.enter()
            let filename = NSUUID().uuidString
            var storageRef = Storage.storage().reference().child("profile_images").child(filename)
            storageRef.putData(uploadData, metadata: nil, completion: { (metadata,err) in
                
                if let err = err {
                    print("Failed to upload Profile Image", err)
                    let message = "Failed to upload Profile Image |" + err.localizedDescription
                    let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction!) in
                        self.signUpButton.isEnabled = true
                    }))
                    self.present(alert, animated: true, completion: nil)
                    editGroup.leave()
                    return
                }
                
//                print("metaData | \(metadata)")
                
//                "https://firebasestorage.googleapis.com/v0/b/shoutaroundtest-ae721.appspot.com/o/profile_images%2FF3A38E61-1537-4499-AC26-C074CD9059B8?alt=media&token=0e228917-d385-474f-9625-c1f4e32ecea8"
                
                storageRef.downloadURL(completion: { (url, error) in
                    if let error = error {
                        print("Download Image URL Error")
                        return
                    }
                    
                    guard let profileImageUrl = url?.absoluteString else {
                        print("Download Image URL Error")
                        return
                    }
                    
                    print("Upload profile image to Firebase | SUCCESS | ", profileImageUrl )
                    
                    guard let uid = Auth.auth().currentUser?.uid else {
                        print("Update User Profile Image Error: No UID")
                        return}
                    let dictionaryValues = ["profileImageUrl": profileImageUrl]
                    
                    Database.database().reference().child("users").child(uid).updateChildValues(dictionaryValues) { (err, ref) in
                        if let err = err {
                            print("Fail to Update User Profile Image: ", profileImageUrl, err)
                            let message = "Failed to upload Profile Image |" + err.localizedDescription
                            let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertController.Style.alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction!) in
                                self.signUpButton.isEnabled = true
                            }))
                            self.present(alert, animated: true, completion: nil)
                            editGroup.leave()
                            return
                        }
                        else {
                            //                                self.alert(title: "Edit User", message: "Profile Image Change Success")
                            editGroup.leave()
                            print("Edit User Profile Image | SUCCESS | ", profileImageUrl)
                        }
                    }
                    
                })
                
            })
        }
        
                
        if self.updateUsername  {
            editGroup.enter()

            // USERNAME
            var newUsername = self.usernameTextField.text
            newUsername = newUsername?.replacingOccurrences(of: " ", with: "")
            if newUsername?.first != "@" {
                newUsername = "@" + newUsername!
            }
                        
            Database.checkUsernameAvailable(username: newUsername) { (available) in
                if available {
                    updateValue["username"] = newUsername
                    editGroup.leave()
                } else {
                    print("User Update: New Username, \(newUsername!) already taken")
                    self.alert(title: "Update Error", message: "\(newUsername!) already taken")
                    self.signUpButton.isEnabled = true
                    return
                }
            }
        }
        
        if self.updateCity {
            editGroup.enter()
            // USER CITY
            var userCity = (self.userCityTextField.text)!
            var userCityLoc = self.tempUserCityLoc

            var cityLatitude: String?
            var cityLongitude: String?
            var cityGPS: String?
            
            if userCityLoc == nil {
                cityGPS = nil
            } else {
                cityLatitude = String(format: "%f", (userCityLoc!.coordinate.latitude))
                cityLongitude = String(format: "%f", (userCityLoc!.coordinate.longitude))
                cityGPS = cityLatitude! + "," + cityLongitude!
            }
            updateValue["userLocation"] = cityGPS
            updateValue["userCity"] = userCity
            editGroup.leave()
        }
        

        
        editGroup.notify(queue: .main) {
            print("Finish Updating User | updateImage \(self.updateImage) | updateEmail \(self.updateEmail) | updateUsername \(self.updateUsername) | \(updateValue)")
            
            guard let uid = Auth.auth().currentUser?.uid else {return}
            
            if self.updateUsername || self.updateCity {
                // UPDATE DATABASE
                Database.database().reference().child("users").child(uid).updateChildValues(updateValue) { (err, ref) in
                    if let err = err {
                        print("Fail to Update User: ", updateValue, err)
                        let message = "Fail to Update User |" + err.localizedDescription
                        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction!) in
                            self.signUpButton.isEnabled = true
                        }))
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                    else {
                        self.editComplete()
                        print("Edit User City | SUCCESS | ", updateValue)
                    }
                }
            } else {
                self.editComplete()
            }
        }
        
    }
    
    func editComplete() {
        guard let uid = Auth.auth().currentUser?.uid else {return}

        Database.fetchUserWithUID(uid: uid, forceUpdate: true, completion: { (user) in
            Database.loadCurrentUser(inputUser: user, completion: {
//                    self.delegate?.successSignUp()
//                    self.navigationController?.popToRootViewController(animated: true)
                SVProgressHUD.dismiss()
                self.dismiss(animated: true, completion: {
                    self.passwordTextField.resignFirstResponder()
                    self.delegate?.successSignUp()
                    print("Edit User | Updated Current User with new user info")
                })
            })
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
//        SVProgressHUD.dismiss()
    }
    
    @objc func updatePasswordInput(){
        let passwordAlert = UIAlertController(title: "Update Password", message: "", preferredStyle: UIAlertController.Style.alert)
        passwordAlert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter New Password"
            textField.isSecureTextEntry = true
        }
        
        passwordAlert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Confirm New Password"
            textField.isSecureTextEntry = true
        }
        
        let saveAction = UIAlertAction(title: "Update", style: .default, handler: { alert -> Void in
            let newPassword = passwordAlert.textFields![0] as UITextField
            let confirmNewPassword = passwordAlert.textFields![1] as UITextField
            
            self.checkPassword(password: newPassword.text)

            if newPassword.text == confirmNewPassword.text {
                self.passwordTextField.text = newPassword.text
                self.checkUpdate()
//                Auth.auth().currentUser?.updatePassword(to: newPassword.text!, completion: { (error) in
//                    if let error = error {
//                        print("Update New Password Error:", error)
//                    } else {
//                        print("Update New Password Successfully")
//                        self.alert(title: "Update Password", message: "Success!")
//                    }
//                })
                
            } else {
                self.alert(title: "Update Password", message: "Passwords Don't Match")
            }
        
            print("password: \(newPassword.text), confirm: \(confirmNewPassword.text)")
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { (action : UIAlertAction!) -> Void in })

        passwordAlert.addAction(saveAction)
        passwordAlert.addAction(cancelAction)
        
        self.present(passwordAlert, animated: true, completion: nil)
    }
    
    func updatePasswordConfirm(newPassword: String?) {
        guard let newPassword = newPassword else {
            self.alert(title: "Password Update Error", message: "Blank Password")
            return
        }
        self.checkPassword(password: newPassword)
        Auth.auth().currentUser?.updatePassword(to: newPassword, completion: { (error) in
            if let error = error {
                print("Update New Password Error:", error)
            } else {
                print("Update New Password Successfully")
                self.alert(title: "Update Password", message: "Success!")
            }
        })

    }
    
    func checkPassword(password: String?){
        guard let password = password else {
            print("Check Password Error: No Password")
            self.alert(title: "Password Error", message: "No Password")
            self.signUpButton.isEnabled = true

            return
        }
        
        if password.count < 6 {
            print("Check Password Error: < 6 Letters")
            self.alert(title: "Password Error", message: "Password has to be at least 6 letters")
            self.signUpButton.isEnabled = true

            return
        }
    }
    
    
    func goToAddList(){
        
//        DispatchQueue.main.async {
//            let signUpController = SignUpController()
//            let loginController = LoginController()
//            let navController = UINavigationController(rootViewController: loginController)
//            navController.pushViewController(signUpController, animated: false)
//            self.present(navController, animated: true, completion: nil)
//        }
        
//        let transition = CATransition()
//        transition.duration = 0.5
//        transition.type = CATransitionType.push
//        transition.subtype = CATransitionSubtype.fromLeft
//        transition.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
//        view.window!.layer.add(transition, forKey: kCATransition)
        

        
        Auth.auth().signInAnonymously { (authResult, err) in
            if let err = err {
                self.alert(title: "Sign In Error", message: "Guest Sign In Error: \(err)")
                print("Guest Sign In Error: ", err)
                return
            }
            
            // Create Guest User and Guest Legit/Bookmark List
            guard let uid = authResult?.user.uid else {
                print("Guest Sign In No UID Error")
                return
            }
            print("Successful Guest Sign In: \(uid)")
            newUserOnboarding = true
            newUserRecommend = true
//            self.showOnboarding()

            
//            let listView = SignUpNewListController()
//            self.navigationController?.pushViewController(listView, animated: true)
        
        }
        


//        self.present(listView, animated: true, completion: nil)
        
    }
    
//    @objc func showOnboarding() {
//        let welcomeView = NewUserOnboardingView()
//        let testNav = UINavigationController(rootViewController: welcomeView)
//        self.present(testNav, animated: true, completion: nil)
//    }
    
    
    
    
    @objc func handleSignUp() {

        self.dismissKeyboard()
        if self.testUserSignUp {
            self.signInTestNewUser()
            return
        }
        
        // Disable button
        self.signUpButton.isEnabled = false
        
        guard let email = emailTextField.text, email.count > 6 else {
                self.alert(title: "Error", message: "Email Needs to be more than 6 letters")
                self.signUpButton.isEnabled = true
            return}
        guard let password = passwordTextField.text, password.count > 0 else {
                self.alert(title: "Error", message: "Password Needs to be more than 1 letter")
                self.signUpButton.isEnabled = true
            return}
        guard let city = userCityTextField.text, city.count > 0 else {
                self.alert(title: "Error", message: "Please include a city")
                self.signUpButton.isEnabled = true
            return}
        
        if !allowDefaultPhoto && plusPhotoButton.currentImage == #imageLiteral(resourceName: "plus_photo").withRenderingMode(.alwaysOriginal) {
            self.alert(title: "Error", message: "Please Upload Profile Picture")
            self.signUpButton.isEnabled = true
            return
        }

//        guard let confirmpassword = confirmPasswordTextField.text, password.count > 0 else {
//                self.alert(title: "Error", message: "Password Needs to be more than 1 letter")
//                self.signUpButton.isEnabled = true
//            return}
        
        self.checkPassword(password: password)
        
        var usernameTemp = usernameTextField.text
        usernameTemp = usernameTemp?.replacingOccurrences(of: " ", with: "")
        if usernameTemp?.first != "@" {
            usernameTemp = "@" + usernameTemp!
        }
        guard let username = usernameTemp, username.count > 1 else {return}
        guard let status = statusTextField.text else {return}
        
                
//        if email.contains("test") {
//            self.testSignUp()
//            return
//        }
                
        let SignUpAlert = UIAlertController(title: "Terms And Conditions", message:
                                            """
                                            You agree to Legit's Terms and Conditions, Privacy Policy and EULA if you sign up as a new user.
                                            Thanks for keeping Legit a happy space.
                                            """, preferredStyle: .alert)
        

        SignUpAlert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (action: UIAlertAction!) in
            self.signUpButton.isEnabled = true
            print("Handle Cancel Logic here")
        }))
        
        SignUpAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
            // Allow Editing
            self.finalizeSignup()
        }))

        
        present(SignUpAlert, animated: true) {

        }
    }
    
    func finalizeSignup() {
        if self.appleUid?.count ?? 0 > 0 {
            guard let appleUid = appleUid else {
                print("SIGN UP ERROR - NO APPLE UID")
                return}
            self.processUser(userID: appleUid, appleSignUp: self.isAppleSignUp)
        } else {
            guard let email = emailTextField.text, email.count > 6 else {
                    self.alert(title: "Error", message: "Email Needs to be more than 6 letters")
                    self.signUpButton.isEnabled = true
                return}
            guard let password = passwordTextField.text, password.count > 0 else {
                    self.alert(title: "Error", message: "Password Needs to be more than 1 letter")
                    self.signUpButton.isEnabled = true
                return}
            SVProgressHUD.show(withStatus: "Creating User")

            
            Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            
                if let err = error {
                    self.failCreateUserAlert(msg: err.localizedDescription)
                    print("Failed to create user:", err)
                    return
                }
                
                Auth.auth().signIn(withEmail: email, password: password) { (user, err) in
                
                    if let err = err {
                        print("Failed to sign in new user email:", user , err)
                    }
                
                print("Successfully sign in new user:", email ?? "")
                }
                
                print("FirebaseAuth | Successfully created user: ", user?.user.uid ?? "")
                self.processUser(userID: user?.user.uid, appleSignUp: self.isAppleSignUp)
            }
        }
    }
    
    func failCreateUserAlert(msg: String?){
        let message = "Error Message : \(msg)"
        let alert = UIAlertController(title: "Fail To Create User", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction!) in
            self.signUpButton.isEnabled = true
        }))
        
        self.present(alert, animated: true, completion: nil)
        SVProgressHUD.dismiss()
    }
    
    func testSignUp(){
        
        Auth.auth().signIn(withEmail: "planert41@gmail.com", password: "qqqqqq") { (user, err) in
            
            if let err = err {
                print("Failed to sign in with email:", err)
                
                let message = "Failed to sign in with email: " + err.localizedDescription
                
                let alert = UIAlertController(title: "Sign In Error", message: message, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Forgot Password", style: UIAlertAction.Style.cancel, handler: { (action: UIAlertAction!) in
//                    self.handlePasswordReset()
                }))
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            print("Successfully logged back in with user:", user?.user.uid ?? "")
            //    self.alert(message: "Successfully Login")
            Database.loadCurrentUser(inputUser: nil) {
                self.signUpComplete()
            }
        }
    }
    
    
    func processUser(userID: String?, appleSignUp: Bool? = false){
        print("Creating User Firebase | INIT | \(userID)")
        
        guard let userID = userID else {
            print("Creating User Firebase | ERROR | No UserID Object")
            return}
        var usernameTemp = usernameTextField.text
        usernameTemp = usernameTemp?.replacingOccurrences(of: " ", with: "")
        if usernameTemp?.first != "@" {
            usernameTemp = "@" + usernameTemp!
        }
        guard let username = usernameTemp, username.count > 1 else {return}
//        guard let status = statusTextField.text else {return}
        guard let image = self.plusPhotoButton.imageView?.image else {return}
        guard let uploadData = image.jpegData(compressionQuality: 0.5) else {return}
        
        let filename = NSUUID().uuidString
        
        SVProgressHUD.show(withStatus: "Creating User")

        if self.updateImage {
            let storageRef = Storage.storage().reference().child("profile_images").child(filename)
            storageRef.putData(uploadData, metadata: nil, completion: { (metadata,err) in
                
                if let err = err {
                    print("Failed to upload Profile Image:", err)
                    self.alert(title: "Create User Error", message: "Failed to upload Profile Image")
                    self.signUpButton.isEnabled = true
                    return
                }
                
                storageRef.downloadURL(completion: { (url, error) in
                    if let error = error {
                        print("URL Download ERROR", error)
                        return
                    }
                    guard let profileImageUrl = url?.absoluteString else {return}
                    print("Uploaded New Profile Image For User: \(userID) | URL: \(profileImageUrl)")
                    self.createUserWithProfileImageUrl(userID: userID, url: profileImageUrl, appleSignUp: appleSignUp)
                })
            })
        } else {
            print("Default Image Profile Image For User: \(userID) | URL: \(defaultProfileImageUrl)")
            self.createUserWithProfileImageUrl(userID: userID, url: defaultProfileImageUrl, appleSignUp: appleSignUp)
        }
    }
        
        
//    // 1. Uploading Profile Image
//        storageRef.putData(uploadData, metadata: nil, completion: { (metadata,err) in
//
//            if let err = err {
//                print("Failed to upload Profile Image:", err)
//                self.alert(title: "Create User Error", message: "Failed to upload Profile Image")
//                self.signUpButton.isEnabled = true
//                return
//            }
//
//            storageRef.downloadURL(completion: { (url, error) in
//                if let error = error {
//                    print("URL Download ERROR", error)
//                    return
//                }
//
//
//                guard let profileImageUrl = url?.absoluteString else {return}
//                print("Successfully uploaded profile image:", profileImageUrl )
//
//
//                let userCreatedDate = Date().timeIntervalSince1970
//
//
//                let uid = userID
//                let dictionaryValues = ["username": username, "profileImageUrl": profileImageUrl, "creationDate": userCreatedDate] as [String : Any]
//                let values = [uid:dictionaryValues]
//
//                // 2 UPLOAD IMAGE TO CACHE
//                imageCache[profileImageUrl] = image
//
//                // 2. Creating User Object
//
//                Database.database().reference().child("users").updateChildValues(values, withCompletionBlock: { (err, ref) in
//
//                    if let err = err {
//                        print("Failed to save user info into db:", err)
//
//                        self.alert(title: "Create User Error", message: "Failed to create database user object")
//                        self.signUpButton.isEnabled = true
//                        return
//                    }
//
//
//                    //                    guard let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController else { return }
//                    //
//                    //                    mainTabBarController.setupViewControllers()
//
//                    print("Successfully saved user info to db")
//
//                    // Auto Follow Users
//                    Database.handleFollowing(userUid: "2G76XbYQS8Z7bojJRrImqpuJ7pz2", completion: {
//                        print(" New User Follow | Success Following Wei Zou")
//                    })
//                    Database.handleFollowing(userUid: "nWc6VAl9fUdIx0Yf05yQFdwGd5y2", completion: {
//                        print(" New User Follow | Success Following Zian Mei")
//                    })
//                    Database.handleFollowing(userUid: "srHzEjoRYKcKGqAgiyG4E660amQ2", completion: {
//                        print(" New User Follow | Success Following Maynard")
//                    })
//                    Database.handleFollowing(userUid: "KUtV2mzGYDY2hPkXFiU2YC8KDoL2", completion: {
//                        print(" New User Follow | Success Following Maria")
//                    })
//                    Database.handleFollowing(followerUid: "2G76XbYQS8Z7bojJRrImqpuJ7pz2", followingUid: userID, completion: {
//                        print(" New User Follow | Wei Zou Now Following \(username)")
//                    })
//
//                    // CBD367A0-4B4B-480F-BEDE-3A85476ECCC1 - MaynEats
//                    // 10A3773F-3950-4510-8329-FB86C572282E - Malaysia
//                    // A3EFD19E-7C97-4A9B-8A87-AAF64E4D0017 - Breakfast/Brunch
//                    // 4C202E90-AC03-4BD5-98F9-AE9C1C37E842 - Denver
//
//                    Database.handleFollowingListId(userUid: userID, followedListId: "CBD367A0-4B4B-480F-BEDE-3A85476ECCC1", completion: {
//                        print(" New User Follow | Success Following Mayneats")
//                    })
//
//                    Database.handleFollowingListId(userUid: userID, followedListId: "A3EFD19E-7C97-4A9B-8A87-AAF64E4D0017", completion: {
//                        print(" New User Follow | Success Following Breakfast/Brunch")
//                    })
//
//                    Database.handleFollowingListId(userUid: userID, followedListId: "4C202E90-AC03-4BD5-98F9-AE9C1C37E842", completion: {
//                        print(" New User Follow | Success Following Denver")
//                    })
//
//                    Database.handleFollowingListId(userUid: userID, followedListId: "10A3773F-3950-4510-8329-FB86C572282E", completion: {
//                        print(" New User Follow | Success Following Malaysia")
//                    })
//
//                    self.signUpButton.isEnabled = true
//
//
//                    // 2A. Creating Test User Object
//                    self.loadTestUserObject(uid: uid, dictionary: dictionaryValues, completion: {
//                        self.signUpComplete()
//                    })
//
//
//                    // Link FB Credential
//                    if let FBCredentials = self.FBCredentials {
//                        Auth.auth().currentUser?.link(with: FBCredentials, completion: { (user, err) in
//                            if let err = err {
//                                print("Error Linking Accounts ", err)
//                            } else {
//                                print("Success Linking Facebook to Email")
//                            }
//                        })
//                    } else {
//                        print("No FB Credentials To Link")
//                    }
//                })
//
//            })
//        })
//    }
    
    
    func createUserWithProfileImageUrl(userID: String, url: String, appleSignUp: Bool? = false) {
            // 2. Creating User Object
            print("createUserWithProfileImageUrl: \(userID) | \(url) | Apple: \(appleSignUp)")

            var usernameTemp = usernameTextField.text
            usernameTemp = usernameTemp?.replacingOccurrences(of: " ", with: "")
            if usernameTemp?.first != "@" {
                usernameTemp = "@" + usernameTemp!
            }
            guard let username = usernameTemp, username.count > 1 else {return}
            let userCreatedDate = Date().timeIntervalSince1970

            var userCity = self.userCityTextField.text
            var userCityLoc = self.tempUserCityLoc

            var cityLatitude: String?
            var cityLongitude: String?
            var cityGPS: String?
            
            if userCityLoc == nil {
                cityGPS = nil
            } else {
                cityLatitude = String(format: "%f", (userCityLoc!.coordinate.latitude))
                cityLongitude = String(format: "%f", (userCityLoc!.coordinate.longitude))
                cityGPS = cityLatitude! + "," + cityLongitude!
            }
        
            let uid = userID
        var dictionaryValues = ["username": username, "profileImageUrl": url, "creationDate": userCreatedDate, "userLocation": cityGPS, "userCity": userCity] as [String : Any]
        if appleSignUp ?? false {
            dictionaryValues["appleSignUp"] = appleSignUp
        }
            let values = [uid:dictionaryValues]
        
            Database.database().reference().child("users").updateChildValues(values, withCompletionBlock: { (err, ref) in
                
                if let err = err {
                    print("Failed to save user info into db:", err)
                    
                    self.alert(title: "Create User Error", message: "Failed to create database user object")
                    self.signUpButton.isEnabled = true
                    return
                }

                
                print("Successfully saved user info to db")
                
                // Auto Follow Users
                if self.newUserAutoFollow {
                    let newFollowUids = [weizouID, meimeiID, maynardID, magnusID, UID_ernie]

                    Database.handleFollowingMultipleUids(userUids: newFollowUids, hideAlert: true, forceFollow: true) {
                        print("SUCCESS New User Followed Starting Users")
                    }
                }
                

                Database.handleManualFollowing(followerUid: weizouID, followedUid: userID, hideAlert: true, completion: {
                    print(" New User Follow | Wei Zou Now Following \(username)")})
                Database.sendPushNotification(uid: weizouID, title: "\(username) - Following You - New User", body: "New User", action: followAction)

                Database.handleManualFollowing(followerUid: maynardID, followedUid: userID, hideAlert: true, completion: {
                    print(" New User Follow | Maynard Now Following \(username)")})
                Database.sendPushNotification(uid: maynardID, title: "\(username) - Following You - New User", body: "New User", action: followAction)
                
//                Database.handleFollowing(followerUid: legitID, followingUid: userID, hideAlert: true, completion: {
//                    print(" New User Follow | Wei Zou Now Following \(username)")})

                
                self.signUpButton.isEnabled = true
                
                
                // 2A. Creating Test User Object
                self.loadTestUserObject(uid: uid, dictionary: dictionaryValues, completion: {
                    print("Loaded Temp New User | loadTestUserObject")
                    self.signUpComplete()
                })
                
                
                // Link FB Credential
                if let FBCredentials = self.FBCredentials {
                    Auth.auth().currentUser?.link(with: FBCredentials, completion: { (user, err) in
                        if let err = err {
                            print("Error Linking Accounts ", err)
                        } else {
                            print("Success Linking Facebook to Email")
                        }
                    })
                } else {
//                    print("No FB Credentials To Link")
                }
            })
            
    }
    
    func signInTestNewUser() {
        let testEmail = "test111@gmail.com"
        let testPassword = "111111"
        let testUsername = "test111"

        Auth.auth().signIn(withEmail: testEmail, password: testPassword) { (user, err) in
        
            if let err = err {
                print("Failed to sign in test user email:", user , err)
            }
            guard let uid = user?.user.uid else {return}
        
        print("Successfully sign in test user:", testEmail ?? "")
            let dictionaryValues = ["username": testUsername, "profileImageUrl": defaultProfileImageUrl, "creationDate": Date().timeIntervalSince1970] as [String : Any]
            let values = [uid:dictionaryValues]
            self.loadTestUserObject(uid: uid, dictionary: dictionaryValues, completion: {
                print("Loaded Temp TEST User | TEST USER")
                self.signUpComplete()
            })
        }
    }
    
    // Auto Follow Users

    func loadTestUserObject(uid: String?, dictionary: [String:Any]?,  completion: @escaping() ->()){
        guard let uid = uid else {
            print("createTestUserObject ERROR| No UID")
            return}
        
        let tempDictionary = dictionary ?? [:]
        var testUser = User.init(uid: uid, dictionary: tempDictionary)
        CurrentUser.user = testUser
        userCache[uid] = testUser
        if newUserAutoFollow {
            CurrentUser.followingUids = [weizouID, meimeiID, maynardID, legitID]
        }
        LocationSingleton.sharedInstance.determineCurrentLocation()
        completion()
//        Database.createDefaultList(uid: uid, completion: { (defaultList, defaultListId) in
//            CurrentUser.lists = defaultList
//            CurrentUser.listIds = defaultListId
//            CurrentUser.user?.listIds = defaultListId
//            print(" loadTestUserObject | Default Lists | \(CurrentUser.user?.username) created \(CurrentUser.lists.count) lists")
//            completion()
//        })
    }
    
    @objc func signUpComplete(){
        newUserOnboarding = true
        newUserRecommend = true
//        self.dismiss(animated: true, completion: nil)
//        SVProgressHUD.dismiss()

        self.dismiss(animated: true) {
            print("signUpComplete | Dismiss")
            guard let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController else { return }
            print("Sucessful Sign Up | New Sign In | Load Current User | \(Auth.auth().currentUser?.uid)")
            mainTabBarController.checkForCurrentUser()
            mainTabBarController.selectedIndex = 4
            self.navigationController?.navigationBar.layoutIfNeeded()
        }
        

        
//        if newUser {
//            self.showOnboarding()
//        }

//        if (Auth.auth().currentUser?.isAnonymous)! {
//            mainTabBarController.selectedIndex = 0
//        }
        
        
//        NotificationCenter.default.post(name: AppDelegate.SuccessLoginNotificationName, object: nil)

        
        //                    guard let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController else { return }
        //
        //                    mainTabBarController.setupViewControllers()
    }
    
    var appleUid: String? {
        didSet {
            if (appleUid?.count ?? 0) > 0 {
                self.signUpButton.isEnabled = true
                self.signUpButton.backgroundColor = UIColor.ianBlueColor()
                print("SignupController | Appld UID: \(appleUid)")
                self.isAppleSignUp = true
            } else {
                self.isAppleSignUp = false
            }
        }
    }
    
    var isAppleSignUp: Bool = false {
        didSet {
            self.setupInputFields()
        }
    }
    
    var appleCredentials: ASAuthorizationAppleIDCredential?
    var appleEmail: String? {
        didSet {
            if let _ = appleEmail {
                self.emailTextField.text = self.appleEmail
                self.formatInputFields()
            }
        }
    }
    
    var appleUsername: String?{
        didSet {
            if let _ = appleUsername {
                self.usernameTextField.text = "@" + (self.appleUsername ?? "")
                self.formatInputFields()
            }
        }
    }
    
    let appleSignUpDetails: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.backgroundColor = UIColor.clear
        label.font = UIFont(font: .avenirBlack, size: 30)
//        label.font = UIFont(name: "Poppins-Regular", size: 14)
        label.text = "User Fields populated with Apple ID info. Please insert a user photo and current city. "
        label.textColor = UIColor.darkGray
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.textAlignment = .center
        return label
    }()
    
    func enableAppleSignUpMode() {
        if isAppleSignUp {
            self.emailTextField.isEnabled = false
            self.usernameTextField.isEnabled = false
            self.passwordTextField.isEnabled = false
//            print("SignupController | Appld UID: \(appleUid)")
            setupInputFields()
            self.signUpButton.isEnabled = true
            self.signUpButton.backgroundColor = UIColor.ianBlueColor()
        }
    }
    
    func presentAppleSignUpDetail() {
        var missingEmail = "Missing Apple ID Email: Please populate email adress"
        var missingUsername = "Missing Apple ID Username: Please populate username"
        if self.appleEmail != nil && self.appleUsername != nil {
            var status = """
            New User details are populated with your Apple ID data. Add a user photo and location to continue
            """

            SVProgressHUD.showSuccess(withStatus: status)
            SVProgressHUD.dismiss(withDelay: 1.5)
        } else if self.appleEmail == nil || self.appleUsername == nil {
            var status = """
            New User details are populated with your Apple ID data. Add a user photo and location to continue.
            \((self.appleEmail == nil) ? missingEmail : "")
            \((self.appleUsername == nil) ? missingUsername : "")
            """
            
            let editAlert = UIAlertController(title: "New Apple User", message: status, preferredStyle: UIAlertController.Style.alert)
            editAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
            }))
            self.present(editAlert, animated: true)
            
        }

//        self.alert(title: "Apple ID Sign Up", message: "New User details are populated with your Apple ID data. Add a user photo and location to continue")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if isAppleSignUp {
            self.presentAppleSignUpDetail()
        }
//        if (appleUid?.count ?? 0) > 0 {
//            self.signUpButton.isEnabled = true
//            self.signUpButton.backgroundColor = UIColor.ianBlueColor()
//            print("viewWillAppear | SignupController | Appld UID: \(appleUid)")
//        }
    }
    
    let legitTermsLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.backgroundColor = UIColor.clear
//        label.font = UIFont(font: .avenirBlack, size: 30)
        label.font = UIFont(name: "Poppins-Regular", size: 14)
        label.text = "Terms & Conditions"
        label.textColor = UIColor.mainBlue()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.textAlignment = .center
        return label
    }()
    
    let legitPrivacyLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.backgroundColor = UIColor.clear
//        label.font = UIFont(font: .avenirBlack, size: 30)
        label.font = UIFont(name: "Poppins-Regular", size: 14)
        label.text = "Privacy Policy"
        label.textColor = UIColor.mainBlue()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.textAlignment = .center
        return label
    }()
    
    let legitEULALabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.backgroundColor = UIColor.clear
//        label.font = UIFont(font: .avenirBlack, size: 30)
        label.font = UIFont(name: "Poppins-Regular", size: 14)
        label.text = "End User License And Agreement"
        label.textColor = UIColor.mainBlue()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.textAlignment = .center
        return label
    }()
    
    @objc func tapLegitTerms() {
        self.extOpenLegitTerms()
    }
    
    @objc func tapLegitPrivacy() {
        self.extOpenLegitPrivacy()
    }
    
    @objc func tapLegitEULA() {
        self.extOpenLegitEULA()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        IQKeyboardManager.shared.enable = true
//        IQKeyboardManager.sharedManager().enable = true
        if self.editUserInd{
            navigationController?.isNavigationBarHidden = false
        } else {
            navigationController?.isNavigationBarHidden = true
        }
        
        // Keyboard Setups to Dismiss Keyboard
//        if UIScreen.main.bounds.height <= 750 {
//            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
//            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
//        }

        
        view.backgroundColor = .white
        view.backgroundColor = .backgroundGrayColor()

        view.addSubview(plusPhotoButton)
        
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
        
        plusPhotoButton.anchor(top: view.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: self.editUserInd ? 70 : 40, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: photoDisplayHeight, height: photoDisplayHeight)

        plusPhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        plusPhotoButton.layer.cornerRadius = photoDisplayHeight/2
        plusPhotoButton.layer.masksToBounds = true

        view.addSubview(photoCancelButton)
        photoCancelButton.anchor(top: nil, left: plusPhotoButton.rightAnchor, bottom: plusPhotoButton.topAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 20, height: 20)
        photoCancelButton.isHidden = true
//
//        if self.editUserInd {
//            if let imageUrl = editUser?.profileImageUrl {
//                self.updatePhoto(image: imageCache[imageUrl])
//            }
//        }
//
        setupInputFields()
        
        view.addSubview(legitTermsLabel)
        legitTermsLabel.anchor(top: stackView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        legitTermsLabel.sizeToFit()
        legitTermsLabel.isUserInteractionEnabled = true
        legitTermsLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapLegitTerms)))
        
        view.addSubview(legitPrivacyLabel)
        legitPrivacyLabel.anchor(top: legitTermsLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 3, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        legitPrivacyLabel.sizeToFit()
        legitPrivacyLabel.isUserInteractionEnabled = true
        legitPrivacyLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapLegitPrivacy)))
        
        view.addSubview(legitEULALabel)
        legitEULALabel.anchor(top: legitPrivacyLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 3, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        legitEULALabel.sizeToFit()
        legitEULALabel.isUserInteractionEnabled = true
        legitEULALabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapLegitEULA)))
        
        setupBottomFields()
        
//        view.addSubview(alreadyHaveAccountButton)
//        alreadyHaveAccountButton.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
////        alreadyHaveAccountButton.backgroundColor = UIColor.yellow

        

//        
//        if (appleUid?.count ?? 0) > 0 {
//            self.signUpButton.isEnabled = true
//            self.signUpButton.backgroundColor = UIColor.ianBlueColor()
//            print("ViewDidLoad | Appld UID: \(appleUid)")
//        } else {
//            signUpButton.isEnabled = false
//            signUpButton.backgroundColor = UIColor.ianBlueColor().withAlphaComponent(0.2)
//        }
        

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(signIn))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)


    }
    
    let signInButton: UIButton = {
        let button = UIButton(type: .system)
        let attributedTitle = NSMutableAttributedString()
        attributedTitle.append(NSAttributedString(string: "Sign In", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Poppins-Bold", size: 20), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.ianLegitColor()])))
        button.setAttributedTitle(attributedTitle, for: .normal)
     //   button.setTitle("Don't have an account? Sign Up.", for: .normal)
        button.addTarget(self, action: #selector(signIn), for: .touchUpInside)
        return button
    }()
    
    let confirmButton: UIButton = {
        let button = UIButton(type: .system)
        let attributedTitle = NSMutableAttributedString()
        attributedTitle.append(NSAttributedString(string: "Confirm", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Poppins-Bold", size: 20), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.ianLegitColor()])))
        button.setAttributedTitle(attributedTitle, for: .normal)
     //   button.setTitle("Don't have an account? Sign Up.", for: .normal)
        button.addTarget(self, action: #selector(confirmEdit), for: .touchUpInside)
        return button
    }()

    
    let backButton: UIButton = {
        let button = UIButton(type: .system)
        let attributedTitle = NSMutableAttributedString()
        attributedTitle.append(NSAttributedString(string: "Back", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Poppins-Bold", size: 18), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.lightGray])))
        button.setAttributedTitle(attributedTitle, for: .normal)
     //   button.setTitle("Don't have an account? Sign Up.", for: .normal)
        button.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        return button
    }()
    
    fileprivate func setupBottomFields() {
        var stackView = UIStackView()
        if self.editUserInd {
            stackView = UIStackView(arrangedSubviews: [backButton, confirmButton])
        } else {
            stackView = UIStackView(arrangedSubviews: [backButton, signInButton])
        }
        
        stackView.axis = .horizontal
        stackView.spacing = 50
        stackView.distribution = .fillEqually
        
        view.addSubview(stackView)
        stackView.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 25, paddingRight: 0, width: 0, height: 50)
    
    }
    
    @objc func updatePhoto(image: UIImage?){
        print("updatePhoto | Received Image")
        guard let image = image else {
            print("Update Image Error : No Image")
            return
        }
        
        plusPhotoButton.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
//        print(plusPhotoButton.frame.width)
        plusPhotoButton.layer.cornerRadius = photoDisplayHeight/2
        plusPhotoButton.layer.masksToBounds = true
        plusPhotoButton.layer.borderColor = UIColor.black.cgColor
        plusPhotoButton.layer.borderWidth = 3
        
        if image.pngData() != self.originalImageData {
            self.updateImage = true
        }
        // Checks for photo change during edit
        
    }

    
    override func viewDidDisappear(_ animated: Bool) {
        IQKeyboardManager.shared.enable = false

//        IQKeyboardManager.sharedManager().enable = false
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    var adjusted: Bool = false

    @objc func keyboardWillShow(_ notification: NSNotification) {
        if !self.adjusted {
            self.view.frame.origin.y -= (photoDisplayHeight + 40)
            self.adjusted = true
        }
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification) {
        if self.adjusted {
            self.view.frame.origin.y += (photoDisplayHeight + 40)
            self.adjusted = false
        }
    }
    
    var stackView = UIStackView()

    
    func formatInputFields() {
        emailTextField.delegate = self
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        userCityTextField.delegate = self
        confirmPasswordTextField.delegate = self
        
        emailTextField.autocapitalizationType = UITextAutocapitalizationType.none
        usernameTextField.autocapitalizationType = UITextAutocapitalizationType.none
        passwordTextField.autocapitalizationType = UITextAutocapitalizationType.none
        userCityTextField.autocapitalizationType = UITextAutocapitalizationType.none
        confirmPasswordTextField.autocapitalizationType = UITextAutocapitalizationType.none
        
        if self.editUserInd {
            signUpButton.setTitle("Confirm User Edits", for: .normal)
            signUpButton.addTarget(self, action: #selector(confirmEdit), for: .touchUpInside)
            self.alreadyHaveAccountButton.isHidden = true
        } else if self.isAppleSignUp {
            signUpButton.setTitle("Continue", for: .normal)
            signUpButton.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
            self.alreadyHaveAccountButton.isHidden = false
            self.emailTextField.isEnabled = self.appleEmail == nil
            self.usernameTextField.isEnabled = self.appleUsername == nil
            self.passwordTextField.isEnabled = false
            print("SignupController | Appld UID: \(appleUid) | \(self.appleEmail) | \(self.appleUsername)")
        }
        else {
            signUpButton.setTitle("Sign Up", for: .normal)
            signUpButton.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
            self.alreadyHaveAccountButton.isHidden = false
        }
        self.signUpButton.isEnabled = testUserSignUp
        self.emailTextField.backgroundColor = (isAppleSignUp && self.appleEmail != nil) ? UIColor.clear : UIColor.white
        self.passwordTextField.backgroundColor = isAppleSignUp ? UIColor.clear : UIColor.white
        self.usernameTextField.backgroundColor = (isAppleSignUp && self.appleUsername != nil) ? UIColor.clear : UIColor.white
        
        self.handleTextInputChange()
    }
    
    fileprivate func setupInputFields()
    {
//        if self.editUserInd {
//            stackView = UIStackView(arrangedSubviews: [emailTextField, usernameTextField, updatePasswordButton, userCityTextField, signUpButton, cancelButton])
//        } else {
////            stackView = UIStackView(arrangedSubviews: [emailTextField, usernameTextField, passwordTextField, confirmPasswordTextField, signUpButton])
//            stackView = UIStackView(arrangedSubviews: [emailTextField, usernameTextField, passwordTextField, userCityTextField, signUpButton])
//        }
        self.formatInputFields()
        
        stackView = UIStackView(arrangedSubviews: [emailTextField, usernameTextField, passwordTextField, userCityTextField, signUpButton])

        
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.spacing = 10
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            

            stackView.heightAnchor.constraint(equalToConstant: (CGFloat(50 * stackView.subviews.count)))
            ])

        stackView.anchor(top: plusPhotoButton.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: (CGFloat(50 * stackView.subviews.count)))
        
//        view.addSubview(cancelButton)
//        cancelButton.anchor(top: stackView.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 15, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 30, height: 30)
//        cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        cancelButton.isHidden = true
//
        
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == usernameTextField {
            // Insert Default @ beginning
            if textField.text == "" {
                textField.text = "@"
            }
        } else {
            // Check for blank @
            if usernameTextField.text?.replacingOccurrences(of: " ", with: "") == "@" {
                usernameTextField.text = ""
            }
            if textField == userCityTextField {
                self.presentSearchCity()
            }
            
            if textField == passwordTextField && self.editUserInd {
                self.updatePasswordInput()
            }
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField{
            usernameTextField.becomeFirstResponder()
            
        } else if textField == usernameTextField {
            if self.editUserInd && usernameTextField.text == editUser?.username {
                textField.resignFirstResponder()
                passwordTextField.becomeFirstResponder()
            } else {
                Database.checkUsernameAvailable(username: usernameTextField.text) { (available) in
                    if !available{
                        self.alert(title: "Sign Up Error", message: "Username \(self.usernameTextField.text!) already exists!")
                    }
                }
                textField.resignFirstResponder()
                passwordTextField.becomeFirstResponder()
            }
            
        } else if textField == passwordTextField {
            textField.resignFirstResponder()
            userCityTextField.becomeFirstResponder()
//            confirmPasswordTextField.becomeFirstResponder()
            
        } else if textField == userCityTextField {
            self.handleSignUp()
        }
            
            /*else if textField == confirmPasswordTextField {
            
            if confirmPasswordTextField.text != passwordTextField.text {
                self.alert(title: "Sign Up Error", message: "Confirm Password Does Not Match Password")
            } else {
                textField.resignFirstResponder()
                self.handleSignUp()
            }
            
        } */ else {
            textField.resignFirstResponder()
        }
        return false
    }



}



// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
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

extension SignUpController: GMSAutocompleteViewControllerDelegate {
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
      print("Place name: \(place.name)")
      print("Place ID: \(place.placeID)")
      print("Place attributions: \(place.attributions)")
      dismiss(animated: true, completion: nil)
    }

    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
      // TODO: handle the error.
      print("Error: ", error.localizedDescription)
    }

    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
      dismiss(animated: true, completion: nil)
    }

    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
      UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
      UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

                
//                Database.handleFollowing(userUid: "2G76XbYQS8Z7bojJRrImqpuJ7pz2", completion: {
//                    print(" New User Follow | Success Following Wei Zou")})
//                Database.handleFollowing(userUid: "nWc6VAl9fUdIx0Yf05yQFdwGd5y2", completion: {
//                    print(" New User Follow | Success Following Zian Mei")})
//                Database.handleFollowing(userUid: "srHzEjoRYKcKGqAgiyG4E660amQ2", completion: {
//                    print(" New User Follow | Success Following Maynard")})
//                Database.handleFollowing(userUid: "VeG6VZOAvmcJ08AnBRTtO8JkSP12", completion: {
//                    print(" New User Follow | Success Following Ernie")})
////                Database.handleFollowing(userUid: "KUtV2mzGYDY2hPkXFiU2YC8KDoL2", completion: {
////                    print(" New User Follow | Success Following Maria")})
//                Database.handleFollowing(userUid: "B6div2WhzSObg7XGJRFkKBFEQiC3", completion: {
//                    print(" New User Follow | Success Following Magnus")})
//                Database.handleFollowing(followerUid: "2G76XbYQS8Z7bojJRrImqpuJ7pz2", followingUid: userID, completion: {
//                    print(" New User Follow | Wei Zou Now Following \(username)")})
                
                
                
                // CBD367A0-4B4B-480F-BEDE-3A85476ECCC1 - MaynEats
                // 10A3773F-3950-4510-8329-FB86C572282E - Malaysia
                // A3EFD19E-7C97-4A9B-8A87-AAF64E4D0017 - Breakfast/Brunch
                // 4C202E90-AC03-4BD5-98F9-AE9C1C37E842 - Denver
                
                
//                Database.handleFollowingListId(userUid: userID, followedListId: "CBD367A0-4B4B-480F-BEDE-3A85476ECCC1", completion: {
//                    print(" New User Follow | Success Following Mayneats")})
//
//                Database.handleFollowingListId(userUid: userID, followedListId: "A3EFD19E-7C97-4A9B-8A87-AAF64E4D0017", completion: {
//                    print(" New User Follow | Success Following Breakfast/Brunch")})
//
//                Database.handleFollowingListId(userUid: userID, followedListId: "4C202E90-AC03-4BD5-98F9-AE9C1C37E842", completion: {
//                    print(" New User Follow | Success Following Denver")})
//
//                Database.handleFollowingListId(userUid: userID, followedListId: "10A3773F-3950-4510-8329-FB86C572282E", completion: {
//                    print(" New User Follow | Success Following Malaysia")})
