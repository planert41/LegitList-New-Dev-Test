//
//  LocationRequestViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou on 10/24/21.
//  Copyright © 2021 Wei Zou Ang. All rights reserved.
//

import UIKit
import SVProgressHUD

class LocationRequestViewController: UIViewController {

    
    var infoImageView: UIImageView = {
        let img = UIImageView()
        img.image = #imageLiteral(resourceName: "location_map_screenshot").withRenderingMode(.alwaysOriginal)
        img.contentMode = .scaleAspectFit
        img.alpha = 1
        return img
    }()
    
//    var headerLabel = UILabel()
//    var infoTextView = UILabel()
//    var nextButton = UIButton()
//    var cancelButton = UIButton()
    
    let headerLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.backgroundColor = UIColor.clear
//        label.font = UIFont(font: .avenirBlack, size: 30)
        label.font = UIFont(name: "Poppins-Bold", size: 30)
        label.text = "Your Location Data"
        label.textColor = UIColor.ianBlackColor()
        label.numberOfLines = 1
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    let infoTextView: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.backgroundColor = UIColor.clear
//        label.font = UIFont(font: .avenirBlack, size: 30)
        label.font = UIFont(name: "Poppins-Bold", size: 30)
        label.textColor = UIColor.ianBlackColor()
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()

//    let infoTextView: UITextView = {
//        let tv = UITextView()
//        tv.isScrollEnabled = false
//        tv.textContainer.maximumNumberOfLines = 0
//        tv.textContainerInset = UIEdgeInsets.zero
//        tv.textContainer.lineBreakMode = .byTruncatingTail
//        tv.translatesAutoresizingMaskIntoConstraints = false
//        tv.textAlignment = .center
//        tv.isEditable = false
//        tv.textColor = UIColor.ianBlackColor()
//        tv.backgroundColor = UIColor.clear
//        return tv
//    }()
    
    let nextButton: UIButton = {
        let button = UIButton()

        button.titleLabel?.textColor = UIColor.white
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.ianLegitColor()
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.legitColor().cgColor
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        button.layer.cornerRadius = 10
        button.titleLabel?.textAlignment = NSTextAlignment.center
        button.setTitle("Allow", for: .normal)

        button.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
        return button
    } ()
    
    let cancelButton: UIButton = {
        let button = UIButton()

        button.titleLabel?.textColor = UIColor.darkGray
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.imageView?.contentMode = .scaleAspectFill
        button.backgroundColor = UIColor.clear
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.clear.cgColor
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        button.layer.cornerRadius = 10
        button.titleLabel?.textAlignment = NSTextAlignment.center
        button.setTitle("Not Now", for: .normal)

        button.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        return button
    } ()
    
    @objc func handleNext() {
        self.dismiss(animated: true) {
            LocationSingleton.sharedInstance.requestLocationAuth()
        }
    }
    
    @objc func handleCancel() {
        self.dismiss(animated: true) {
            NotificationCenter.default.post(name: AppDelegate.LocationDeniedNotificationName, object: nil)
            print("Dismiss Asking For Location")
        }
    }
    
    let sidePadding: CGFloat = 20.0

    func setupLabels() {
        headerLabel.font = UIFont(name: "Poppins-Bold", size: 30)
        headerLabel.text = "Location Data"
        headerLabel.textColor = UIColor.ianBlackColor()
        
        infoTextView.text = """
        Legit only uses your current location to sort posts closest to you on your feed and map.
            
        We respect the data privacy of our users.
        """
        infoTextView.font = UIFont(name: "Poppins-Regular", size: 15)
        infoTextView.textColor = UIColor.ianBlackColor()

        nextButton.setTitleColor(UIColor.white, for: .normal)
        nextButton.backgroundColor = UIColor.mainBlue()
        cancelButton.setTitleColor(UIColor.darkGray, for: .normal)

    }

    override func viewWillAppear(_ animated: Bool) {
        SVProgressHUD.dismiss()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        setupLabels()
        view.backgroundColor = UIColor.backgroundLegitColor()
        
        view.addSubview(infoImageView)
        infoImageView.anchor(top: view.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 50, paddingLeft: sidePadding, paddingBottom: 0, paddingRight: sidePadding, width: 220, height: 220)
        infoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        infoImageView.layer.cornerRadius = CGFloat(20)
        infoImageView.clipsToBounds = true
        infoImageView.layer.applySketchShadow(color: UIColor.rgb(red: 0, green: 0, blue: 0), alpha: 0.1, x: 0, y: 0, blur: 10, spread: 0)

        
        view.addSubview(headerLabel)
        headerLabel.anchor(top: infoImageView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: sidePadding, paddingBottom: 0, paddingRight: sidePadding, width: 0, height: 0)
//        headerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        headerLabel.sizeToFit()

        
        view.addSubview(infoTextView)
        infoTextView.anchor(top: headerLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: sidePadding, paddingBottom: 0, paddingRight: sidePadding, width: 0, height: 0)
        infoTextView.backgroundColor = UIColor.clear
//        infoTextView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        infoTextView.sizeToFit()
        
        view.addSubview(nextButton)
        nextButton.anchor(top: infoTextView.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 20, paddingLeft: sidePadding, paddingBottom: 30, paddingRight: sidePadding, width: 200, height: 50)
        nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        nextButton.sizeToFit()
        
//        view.addSubview(cancelButton)
//        cancelButton.anchor(top: nextButton.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 10, paddingLeft: sidePadding, paddingBottom: 30, paddingRight: sidePadding, width: 200, height: 50)
//        cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        cancelButton.sizeToFit()
        // Do any additional setup after loading the view.
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
