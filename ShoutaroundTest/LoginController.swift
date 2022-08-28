//
//  LoginController.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/27/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import FBSDKLoginKit
import IQKeyboardManagerSwift
import FacebookLogin
import SVProgressHUD
import AuthenticationServices
import CryptoKit
import JWTDecode


protocol LoginControllerDelegate {
    func successLogin()
}

class LoginController: UIViewController, UITextFieldDelegate, LoginButtonDelegate {
    
    var delegate: LoginControllerDelegate?
    
    let logoContainerView: UIView = {
        
        let view = UIView()
        
//        let logoImageView = UIImageView(image: #imageLiteral(resourceName: "Instagram_logo_white"))
//        logoImageView.contentMode = .scaleAspectFill
//
//        view.addSubview(logoImageView)
//        logoImageView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 200, height: 50)
//        logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
//        view.backgroundColor = UIColor.rgb(red: 0, green: 120, blue: 175)

        let imageView = UIImageView()
        imageView.image = #imageLiteral(resourceName: "Legit_Vector").withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor.white
        view.addSubview(imageView)
        imageView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        view.backgroundColor = UIColor.ianLegitColor()

//        let legitListTitle = UILabel()
//        legitListTitle.text = "LegitList"
//        legitListTitle.font = UIFont(name: "Poppins-Bold", size: 50)
//        legitListTitle.textColor = UIColor.white
//        view.addSubview(legitListTitle)
//        legitListTitle.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        legitListTitle.sizeToFit()
//
//        legitListTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        legitListTitle.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
//        view.backgroundColor = UIColor.legitColor()

        return view
        
    }()
    
    let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        
        return tf
        
        
    }()
    
    
    let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        
        return tf
        
    }()
    
    let loginButton: UIButton = {
        
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.backgroundColor = UIColor.ianLegitColor().withAlphaComponent(0.5)
        
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.white, for: .normal)
        
        button.addTarget(self, action: #selector(handleLogIn), for: .touchUpInside)
        
        button.isEnabled = false
        
        return button
    }()
    
    // Add FB Login Button
    
    let fbLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["public_profile", "email", "user_friends"]
        button.layer.cornerRadius = 5
//        for constraint: NSLayoutConstraint in button.constraints {
//            print(constraint)
//            if(constraint.firstAttribute == .height) {
//                button.removeConstraint(constraint)
//            }
//        }
        return button
    }()
    
    @objc func handleLogIn(){
        
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        
        Auth.auth().signIn(withEmail: email, password: password) { (user, err) in
        
        if let err = err {
            print("Failed to sign in with email:", err)
            
            let message = "Failed to sign in with email: " + err.localizedDescription

            let alert = UIAlertController(title: "Sign In Error", message: message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Forgot Password", style: UIAlertAction.Style.cancel, handler: { (action: UIAlertAction!) in
                self.handlePasswordReset()
            }))
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

            self.present(alert, animated: true, completion: nil)
            return
        }
        
        print("Successfully logged back in with user:", user?.user.uid ?? "")
        //    self.alert(message: "Successfully Login")
            self.successfulLogin()

//            Database.fetchCurrentUser {
//                self.successfulLogin()
//            }
        }
        
    }
    
    
    func successfulLogin() {
        SVProgressHUD.show(withStatus: "Logging in")

        self.dismiss(animated: true) {
//            NotificationCenter.default.post(name: AppDelegate.SuccessLoginNotificationName, object: nil)
//            self.delegate?.successLogin()
            self.passwordTextField.resignFirstResponder()
//            SVProgressHUD.dismiss()
        }
        
        guard let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController else { return }

        print("Sucessful Logging in | LoginViewController | New Sign In | Load Current User")
        mainTabBarController.checkForCurrentUser()
        mainTabBarController.selectedIndex = 0

//        if (Auth.auth().currentUser?.isAnonymous)! {
//            mainTabBarController.selectedIndex = 0
//        }
        
//        guard let mainViewController = UIApplication.shared.keyWindow?.rootViewController as? MainViewController else { return }

//        guard let window = UIApplication.shared.keyWindow?.rootViewController as! UINavigationController else {return}
//
//        if let window = UIApplication.shared.keyWindow?.rootViewController as! UINavigationController
//
//        window.pop
        
//        self.navigationController?.popToViewController(mainViewController, animated: true)
//        self.dismiss(animated: true, completion: nil)
//        self.delegate?.successLogin()
            


//        self.navigationController?.popToViewController(MainViewController, animated: true)
//        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func handleTextInputChange(){
        
        let isFormValid = emailTextField.text?.count ?? 0 > 0 && passwordTextField.text?.count ?? 0 > 0
        
        if isFormValid {
            
            loginButton.isEnabled = true
            loginButton.backgroundColor = UIColor.ianLegitColor()
            
//            loginButton.backgroundColor = UIColor.rgb(red: 17, green: 154, blue: 237)
        } else {
            loginButton.isEnabled = false
            loginButton.backgroundColor = UIColor.ianLegitColor().withAlphaComponent(0.2)
//            loginButton.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
            
        }
    }
    
    
    let resetPassword: UIButton = {
        let button = UIButton(type: .system)
        let attributedTitle = NSMutableAttributedString(string: "Forgot Password? ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 16), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.lightGray]))
        
        button.setAttributedTitle(attributedTitle, for: .normal)
        
        button.addTarget(self, action: #selector(handlePasswordReset), for: .touchUpInside)
        return button
    }()
    
    let guestSignIn: UIButton = {
        let button = UIButton(type: .system)
        let attributedTitle = NSMutableAttributedString(string: "Sign In As Guest", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 16), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.gray]))
        
        button.setAttributedTitle(attributedTitle, for: .normal)
        
        button.addTarget(self, action: #selector(handleGuestSignIn), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    
    @objc func handleGuestSignIn(){
        self.dismiss(animated: true, completion: nil)
        return

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
                
                    Database.setupGuestUser(uid: uid) {
                        newUserOnboarding = true
                        newUserRecommend = true
                        self.successfulLogin()
                    }
                }
        }
    
    let forgotPasswordButton: UIButton = {
        let button = UIButton(type: .system)
        let attributedTitle = NSMutableAttributedString(string: "Sign In Without Profile", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 16), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.legitColor()]))
        
        button.setAttributedTitle(attributedTitle, for: .normal)
        
        button.addTarget(self, action: #selector(handleGuestSignIn), for: .touchUpInside)
        return button
    }()
    
    
    @objc func handlePasswordReset(){
        Auth.auth().sendPasswordReset(withEmail: emailTextField.text!) { error in
            
            if let error = error {
                self.alert(title: "Reset Password", message: "Error: \(error.localizedDescription)")
            } else {
                self.alert(title: "Reset Password", message: "Success! Check \(self.emailTextField.text!) for an email! Make sure to check your spam folder as well.")
            }
        }
    }
    
    
    let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        let attributedTitle = NSMutableAttributedString()
        attributedTitle.append(NSAttributedString(string: "Sign Up", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Poppins-Bold", size: 20), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.ianLegitColor()])))
        button.setAttributedTitle(attributedTitle, for: .normal)
     //   button.setTitle("Don't have an account? Sign Up.", for: .normal)
        button.addTarget(self, action: #selector(handleShowSignUp), for: .touchUpInside)
        return button
    }()

    
    
    
    @objc func handleShowSignUp() {
        let signUpController = SignUpController()
//        self.present(signUpController, animated: true, completion: nil)
        navigationController?.pushViewController(signUpController, animated: true)
    }
    
    let legitOnboardingLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.backgroundColor = UIColor.clear
//        label.font = UIFont(font: .avenirBlack, size: 30)
        label.font = UIFont(name: "Poppins-Bold", size: 20)
        label.text = "What Is Legit? 🤔"
        label.textColor = UIColor.ianBlackColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping

        return label
    }()
    
//    @objc func showOnboarding() {
//        print("LoginController showOnboarding")
//        let welcomeView = NewUserOnboardView()
//
//        let testNav = UINavigationController(rootViewController: welcomeView)
//        self.present(testNav, animated: true, completion: nil)
////        NotificationCenter.default.post(name: MainTabBarController.showOnboarding, object: nil)
//    }
    

    
    override var preferredStatusBarStyle: UIStatusBarStyle  {
        
       return.lightContent
        
    }
    
    @available(iOS 13.0, *)
    lazy var appleLogInButton : ASAuthorizationAppleIDButton = {
        let button = ASAuthorizationAppleIDButton()
        button.addTarget(self, action: #selector(handleAppleIdRequest), for: .touchUpInside)
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        return button
    }()
    
    var appleEmail: String?
    var appleUid: String?
    var appleUsername: String?
    var appleCred: ASAuthorizationAppleIDCredential?

    let backButton: UIButton = {
        let button = UIButton(type: .system)
        let attributedTitle = NSMutableAttributedString()
        attributedTitle.append(NSAttributedString(string: "Back", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Poppins-Bold", size: 18), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.lightGray])))
        button.setAttributedTitle(attributedTitle, for: .normal)
     //   button.setTitle("Don't have an account? Sign Up.", for: .normal)
        button.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } 
        
        navigationController?.isNavigationBarHidden = true
//        view.backgroundColor = .white
        view.backgroundColor = UIColor.backgroundGrayColor()

        IQKeyboardManager.shared.enable = true
        
        view.addSubview(logoContainerView)
        logoContainerView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 150)
        
        
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
        
        logoContainerView.isUserInteractionEnabled = true
        logoContainerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
        
        setupInputFields()
        
        setupBottomFields()
        
//        view.addSubview(legitOnboardingLabel)
//        legitOnboardingLabel.anchor(top: dontHaveAccountButton.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 20, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        legitOnboardingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        legitOnboardingLabel.sizeToFit()
//        legitOnboardingLabel.isUserInteractionEnabled = true
//        legitOnboardingLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showOnboarding)))
    
//        view.addSubview(backButton)
//        backButton.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 25, paddingRight: 0, width: 0, height: 50)
//
//        view.addSubview(signUpButton)
//        signUpButton.anchor(top: nil, left: view.leftAnchor, bottom: backButton.topAnchor, right: view.rightAnchor, paddingTop: 3, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
//
//
    }

    override func viewDidDisappear(_ animated: Bool) {
        IQKeyboardManager.shared.enable = false

    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField{
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            self.resignFirstResponder()
            self.handleLogIn()
        } else {
            self.resignFirstResponder()
        }
        return false
    }
    
    
    func handleLinkUser(email: String, credential: AuthCredential){
        let message = "Please Login with \(email) to link your Facebook Account"
        
        let alert = UIAlertController(title: "Sign In", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Please Insert Password"
            textField.isSecureTextEntry = true
        }
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction!) in
            let textField = alert.textFields![0]
            
            guard let password = textField.text else {
                self.alert(title: "Sign In Error", message: "Invalid Password")
                return
            }
            
            Auth.auth().signIn(withEmail: email, password: password, completion: { (user, err) in
                if let err = err {
                    print("Failed to sign in with email:", err)
                    alert.message = "Wrong Password. Please Try Again"
                    self.present(alert, animated: true, completion: nil)
                    return
                } else {
                    print("Successfully logged back in with user:", user?.user.uid ?? "")
                    Auth.auth().currentUser?.link(with: credential, completion: { (user, err) in
                        if let err = err {print("Error Linking Accounts")}
                        
                        print("Success Linking Facebook to Email")
                        self.successfulLogin()
                    })
                }
            })
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
            let loginManager = LoginManager()
            loginManager.logOut()
            
        }))
        
        present(alert, animated: true, completion: nil)
        
    }
    

    func loginButton(_ loginButton: FBLoginButton!, didCompleteWith result: LoginManagerLoginResult!, error: Error!) {
        
        if let error = error {
            self.alert(title: "Facebook Login Error", message: "Error Logging into Facebook")
            print(error.localizedDescription)
            return
        }
        
        else if result.isCancelled {
            print("Cancelled FB Login")
        }
        
        else {
            
            print("LoginController | FB Login Complete")

//            Login Facebook
//            if let _ = FBSDKAccessToken.current() {
//                let fbCredential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
//
//                Auth.auth().signIn(with: fbCredential) { (user, error) in
//
//                    if let error = error {
//                        if error._code == 17012 {
//                            let email = error._userInfo?[AuthErrorUserInfoEmailKey]! as! String
//                            print("User is linked with another account: ", email)
//                            self.handleLinkUser(email: email, credential: fbCredential)
//
//                        } else {
//                            print("Failed to sign in with FB Credentials", error)
//                        }
//                        return}
//
//                    user
//                    guard let userUid = user?.uid else {return}
//                    let ref = Database.database().reference().child("users")
//
//                    ref.observe(DataEventType.value, with: { (snapshot) in
//                        if snapshot.hasChild(userUid) {
//                            print("User Exist")
//                            self.successfulLogin()
//                        } else {
//                            // Create new user in database if current user doesn't exist
//                            print("User doesn't Exist")
//                            self.fbLoginSetupNewUser()
////                            self.fbLoginCreateNewUser()
//                        }
//                    }){ (err) in print("Error Search User", err) }
//
//                }
//            }
        }
    }
    
    
    
    
    //        let image = CustomImageView()
    //        let string = "https://graph.facebook.com/" + FBSDKAccessToken.current() + "/picture?type=square&width=40&height=40"
    //        image.loadImage(urlString: string)
    
    
    //            if let _ = FBSDKAccessToken.current() {
    //                if let currentUser = FBSDKProfile.current() {
    //                    print("current user got: \(currentUser)")
    //                } else {
    //                    print("current user not got")
    //                    FBSDKProfile.loadCurrentProfile(completion: {
    //                        profile, error in
    //                        if let updatedUser = profile {
    //                            print("finally got user: \(updatedUser)")
    //                        } else {
    //                            print("current user still not got")
    //                        }
    //                    })
    //                }
    //            }
    
    


    
    fileprivate func fbLoginSetupNewUser(){

        GraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email , gender"]).start(completionHandler: { (connection, result, error) -> Void in
            
            if let error = error {
                print("Error Fetching FB SDK Graph")
            }
            
            if let data = result as? [String:AnyObject] {
                
                let fbProfileID = data["id"]! as! String
                let pic = data["picture"] as! [String:AnyObject]
                let urlData = data["picture"]?.value(forKey: "data") as! [String : AnyObject]
                let urlString = urlData["url"]! as! String
                let fbProfileFullName = data["name"] as! String
                let fbEmail = data["email"] as! String
                
                let signupUserView = SignUpController()
                signupUserView.emailTextField.text = fbEmail
                signupUserView.usernameTextField.text = "@"+fbProfileFullName.removingWhitespaces()
                signupUserView.FBCredentials = FacebookAuthProvider.credential(withAccessToken: AccessToken.current!.tokenString)
                
                guard let url = URL(string: urlString) else {return}
                URLSession.shared.dataTask(with: url) { (data, response, err) in
                    if let err = err {
                        print("Failed to fetch profile image:", err)
                        return
                    }
                    
                    guard let imageData = data else {return}
                    let photoImage = UIImage(data: imageData)
                    
                    DispatchQueue.main.async {
                        signupUserView.updatePhoto(image: photoImage)
                        self.navigationController?.pushViewController(signupUserView, animated: true)
                    }
                    }.resume()
                
            }
        })
        
        
        
//        FBSDKProfile.loadCurrentProfile { (fbProfile, err) in
//            if let err = err {
//                print("FB SDK Profile Error")
//            }
//
//            print(fbProfile)
//            print(fbProfile?.userID)
//            let fbProfileID = fbProfile?.userID as! String
//            let fbProfileImageURL = "http://graph.facebook.com/\(fbProfileID)/picture?type=large"
//            let fbProfileFullName = fbProfile?.name as! String
//            let fbEmail = Auth.auth().currentUser?.email
//
//            let signupUserView = SignUpController()
//            signupUserView.emailTextField.text = fbEmail
//            signupUserView.usernameTextField.text = "@"+fbProfileFullName.removingWhitespaces()
//
//            guard let url = URL(string: fbProfileImageURL) else {return}
//
//            URLSession.shared.dataTask(with: url) { (data, response, err) in
//                if let err = err {
//                    print("Failed to fetch profile image:", err)
//                    return
//                }
//
//                guard let imageData = data else {return}
//                let photoImage = UIImage(data: imageData)
//
//                DispatchQueue.main.async {
//                    signupUserView.updatePhoto(image: photoImage)
//                    self.navigationController?.pushViewController(signupUserView, animated: true)
//                }
//                }.resume()
//        }
        
    }
    
    
    fileprivate func fbLoginCreateNewUser(){
        
        let currentUser = Profile.current
        let fbProfileID = currentUser?.userID as! String
        let fbProfileImageURL = "http://graph.facebook.com/\(fbProfileID)/picture?type=large"
        let fbProfileFullName = currentUser?.name as! String
        let image = UIImage()
        
        guard let url = URL(string: fbProfileImageURL) else {return}
        
        URLSession.shared.dataTask(with: url) { (data, response, err) in
            if let err = err {
                print("Failed to fetch post image:", err)
                return
            }
            
            guard let imageData = data else {return}
            let fbProfileImage = UIImage(data: imageData)
            
            guard let image = fbProfileImage else {return}
            guard let uploadData = image.jpegData(compressionQuality: 0.3) else {return}
            
            let filename = NSUUID().uuidString
            let profileImgRef = Storage.storage().reference().child("profile_images").child(filename)
            
            profileImgRef.putData(uploadData, metadata: nil, completion: { (metadata,err) in
                
                if let err = err {
                    print("Failed to upload Profile Image", err)
                    return
                }
                
        
                profileImgRef.downloadURL(completion: { (url, error) in
                    if let error = error {
                        print("Error with Upload Picture URL")
                        return
                    }
                
                    guard let profileImageUrl = url?.absoluteString else {return}
                    print("Successfully uploaded profile image:", profileImageUrl )
                    
                    
                    guard let uid = Auth.auth().currentUser?.uid else {return}
                    let dictionaryValues = ["username": fbProfileFullName, "profileImageUrl": profileImageUrl]
                    let values = [uid:dictionaryValues]
                    
                    Database.database().reference().child("users").updateChildValues(values, withCompletionBlock: { (err, ref) in
                        
                        if let err = err {
                            
                            print("Failed to save user info into db:", err)
                            return }
                        
                        print("Successfully saved user info to db")
                        
                        guard let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController else { return }
                        
                        mainTabBarController.setupViewControllers()
                        self.dismiss(animated: true, completion: nil)
                        
                    })
                    
                    
                })

            })
        }.resume()
 
    }
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton!) {
        do {
            try Auth.auth().signOut()
            
            if Auth.auth().currentUser == nil {
                
            } else {
            
            let loginController = LoginController()
            let navController = UINavigationController( rootViewController: loginController)
            self.present(navController, animated: true, completion: nil)
            }
            
        } catch let signOutErr {
            print("Failed to sign out:", signOutErr)
        }
        
    }

    
    fileprivate func setupBottomFields() {
        let stackView = UIStackView(arrangedSubviews: [backButton, signUpButton])
        stackView.axis = .horizontal
        stackView.spacing = 50
        stackView.distribution = .fillEqually
        
        view.addSubview(stackView)
        stackView.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 25, paddingRight: 0, width: 0, height: 50)
    
    }

    
    fileprivate func setupInputFields() {
//        let stackView = UIStackView(arrangedSubviews: [emailTextField, passwordTextField, loginButton, fbLoginButton])
        
        emailTextField.autocapitalizationType = UITextAutocapitalizationType.none
        passwordTextField.autocapitalizationType = UITextAutocapitalizationType.none
        passwordTextField.isSecureTextEntry = true
        
        let fbLogin = FBLoginButton()
        fbLogin.permissions = [ "publicProfile", "email", "userFriends" ]
        loginButton.center = view.center
        
        let stackView = UIStackView(arrangedSubviews: [emailTextField, passwordTextField, loginButton])

//        let stackView = UIStackView(arrangedSubviews: [emailTextField, passwordTextField, loginButton, fbLoginButton])
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        
        view.addSubview(stackView)
        stackView.anchor(top: logoContainerView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 40, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 200)
        
        if #available(iOS 13.0, *) {
            view.addSubview(appleLogInButton)
            appleLogInButton.anchor(top: stackView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 15, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 50)
            appleLogInButton.isUserInteractionEnabled = true
            
            appleLogInButton.addTarget(self, action: #selector(handleAppleIdRequest), for: .touchDown)
        
            view.addSubview(resetPassword)
            resetPassword.anchor(top: appleLogInButton.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        } else {
            view.addSubview(resetPassword)
            resetPassword.anchor(top: stackView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        }
        
        
        view.addSubview(guestSignIn)
        guestSignIn.anchor(top: resetPassword.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 25, paddingRight: 0, width: 0, height: 50)

//
//        view.addSubview(dontHaveAccountButton)
//        dontHaveAccountButton.anchor(top: resetPassword.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 3, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)

        // ADD APPLE SIGN IN
//        appleLoginButton()

        
                
        
//        if #available(iOS 13.0, *) {
//            let authorizationButton = ASAuthorizationAppleIDButton()
//            authorizationButton.cornerRadius = 10
//            view.addSubview(authorizationButton)
//            authorizationButton.anchor(top: dontHaveAccountButton.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 15, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 50)
//            authorizationButton.addTarget(self, action: #selector(handleAppleIdRequest), for: .touchUpInside)
//        }

        
        
        
        
        fbLoginButton.delegate = self
    }
    
    
    @objc func handleAppleIdRequest() {
        print("handleAppleIdRequest")
        if #available(iOS 13.0, *) {
//            let appleIDProvider = ASAuthorizationAppleIDProvider()
//            let request = appleIDProvider.createRequest()
//            request.requestedScopes = [.fullName, .email]
//            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
//            authorizationController.delegate = self
//            authorizationController.performRequests()
            
            let nonce = SharedFunctions.randomNonceString()
            currentNonce = nonce
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = SharedFunctions.sha256(nonce)

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()

        }
    }
    
    
    
}

extension LoginController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    @available(iOS 13, *)
    func addAppleSignIn(){
        view.addSubview(appleLogInButton)
        appleLogInButton.anchor(top: signUpButton.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 15, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 50)
        appleLogInButton.isUserInteractionEnabled = true
        
        appleLogInButton.addTarget(self, action: #selector(handleAppleIdRequest), for: .touchDown)
    }

    
    @objc func testButton() {
        print("TEST BUTTON")
    }
    
    @available(iOS 13, *)
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    func checkAppleIdentity() {
        
    }
    
    @available(iOS 13, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
      if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
        
        // Save authorised user ID for future reference
        UserDefaults.standard.set(appleIDCredential.user, forKey: "appleAuthorizedUserIdKey")

        guard let nonce = currentNonce else {
          fatalError("Invalid state: A login callback was received, but no login request was sent.")
        }
        guard let appleIDToken = appleIDCredential.identityToken else {
          print("Unable to fetch identity token")
          return
        }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
          print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
          return
        }
          
          // Add new code below
          if let authorizationCode = appleIDCredential.authorizationCode,
             let codeString = String(data: authorizationCode, encoding: .utf8) {
              print(codeString)
              let url = URL(string: "https://us-central1-shoutaroundtest-ae721.cloudfunctions.net/getRefreshToken?code=\(codeString)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "https://apple.com")!
                      
              let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                  
                  if let data = data {
                      let refreshToken = String(data: data, encoding: .utf8) ?? ""
                      print("Apple refreshToken: ", refreshToken)
                      // *For security reasons, we recommend iCloud keychain rather than UserDefaults.
                      UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
                      UserDefaults.standard.synchronize()
                  }
              }
                task.resume()
          }

          self.appleCred = appleIDCredential
          self.appleEmail = appleIDCredential.email
          self.appleUsername = appleIDCredential.fullName?.givenName?.removingWhitespaces()
          
          if self.appleEmail == nil || self.appleUsername == nil {
              if let identityTokenData = appleIDCredential.identityToken,
              let identityTokenString = String(data: identityTokenData, encoding: .utf8) {
              print("Identity Token \(identityTokenString)")
                  do {
                     let jwt = try decode(jwt: identityTokenString)
                     let decodedBody = jwt.body as Dictionary<String, Any>
                      if let email = (decodedBody["email"]) as? String {
                          self.appleEmail = email
                      }
                     print(decodedBody)
                     print("Decoded email: "+(decodedBody["email"] as? String ?? "n/a")   )
                  } catch {
                     print("decoding failed")
                  }
              }
          }

          
        
        // Initialize a Firebase credential.
        let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                  idToken: idTokenString,
                                                  rawNonce: nonce)
//        print("ID TOKEN ", idTokenString)
        // Sign in with Firebase.
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if let error = error {
            // Error. If error.code == .MissingOrInvalidNonce, make sure
            // you're sending the SHA256-hashed nonce as a hex string with
            // your request to Apple.
            print(error.localizedDescription)
                self.alert(title: "Apple Sign In Error", message: error.localizedDescription)
            return
          }
          
            guard let newUid = Auth.auth().currentUser?.uid else {return}
            print("Apple Sign In SUCCESS : \(newUid) | \(self.appleEmail) | \(self.appleUsername)")
            self.appleUid = newUid
            self.checkUserUid(uid: newUid)
            
            

            // User is signed in to Firebase with Apple.
          // ...
            // Make a request to set user's display name on Firebase
//            let changeRequest = authResult?.user.createProfileChangeRequest()
//            changeRequest?.displayName = appleIDCredential.fullName?.givenName
//            changeRequest?.commitChanges(completion: { (error) in
//
//                if let error = error {
//                    print(error.localizedDescription)
//                } else {
//                    print("Updated display name: \(Auth.auth().currentUser!.displayName!)")
//                }
//            })
        }
      }
    }
    
    func checkUserUid(uid: String?) {
        // Check if current logged in user uid actually exists in database
        guard let userUid = Auth.auth().currentUser?.uid else {return}
        
        let ref = Database.database().reference().child("users").child(userUid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
          
            guard let userDictionary = snapshot.value as? [String:Any] else {
                print("LoginController | User Doesn't Exist | Create New User")
                self.showAppleSignUp()
                return}
            
            
            let user = User(uid:userUid, dictionary: userDictionary)
            Database.loadCurrentUser(inputUser: user, completion: {
                print("User \(userUid) Exists - Successful Login")
                self.successfulLogin()
            })
        }){ (err) in print("Error Search User", err) }
        
    }
    
    func showAppleSignUp() {
        let signUpController = SignUpController()
        signUpController.appleUid = self.appleUid
        signUpController.appleCredentials = self.appleCred
        signUpController.appleEmail = self.appleEmail
        signUpController.appleUsername = self.appleUsername
        signUpController.emailTextField.text = self.appleEmail
        signUpController.usernameTextField.text = "@" + (self.appleUsername ?? "")
        signUpController.passwordTextField.text = "password"
        signUpController.passwordTextField.isHidden = true
        signUpController.handleTextInputChange()
        print("showAppleSignUp | \(self.appleEmail) | \(self.appleUsername)")
        self.navigationController?.pushViewController(signUpController, animated: true)
    }
    
    
    
    

    @available(iOS 13, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
      // Handle error.
      print("Sign in with Apple errored: \(error)")
    }
    
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
