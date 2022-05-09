//
//  SingleUserProfileHeader.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/14/20.
//  Copyright © 2020 Wei Zou Ang. All rights reserved.
//

import UIKit

import FirebaseAuth
import FirebaseDatabase


protocol EmptyCellDelegate {
    func handleRefresh()
    func didTapEmptyCell()
}



class EmptyCell: UICollectionViewCell {

    var delegate : EmptyCellDelegate?
    
    var isFiltering: Bool = false {
        didSet {
            self.refreshLabels()
        }
    }
        
    func refreshLabels(){
        self.imageLabel.text = isFiltering ? "No Results Found" : "No Posts Yet"
        self.imageSubLabel.text = isFiltering ? "Tap To Refresh Search" : "Add A Photo Or Follow A Friend"
        self.imageIcon.isHidden = !isFiltering
        self.defaultIcon.isHidden = !self.imageIcon.isHidden
//        var tempImage = isFiltering ? #imageLiteral(resourceName: "noResults_pic") : #imageLiteral(resourceName: "Legit_Vector")
//        self.imageIcon.setImage(tempImage.withRenderingMode(.alwaysOriginal), for: .normal)
//        self.imageIcon.sizeToFit()
        
    }
    
    let imageIcon: UIButton = {
        let button = UIButton()
        let listIcon = #imageLiteral(resourceName: "noResults_pic").withRenderingMode(.alwaysOriginal)
        button.setImage(listIcon, for: .normal)
        button.backgroundColor = UIColor.clear
        button.isUserInteractionEnabled = false
        button.tintColor = UIColor.ianBlackColor()
        button.contentMode = .scaleAspectFill
        return button
    }()
    
    let defaultIcon: UIButton = {
        let button = UIButton()
        let listIcon = #imageLiteral(resourceName: "Legit_Vector").withRenderingMode(.alwaysOriginal)
        button.setImage(listIcon, for: .normal)
        button.backgroundColor = UIColor.clear
        button.isUserInteractionEnabled = false
        button.tintColor = UIColor.ianBlackColor()
        button.contentMode = .scaleAspectFill
        return button
    }()
    
    
    let imageLabel: UILabel = {
        let label = UILabel()
        label.text = "No Results Found"
        label.font = UIFont(name: "Poppins-Bold", size: 25)
        label.textColor = UIColor.ianBlackColor()
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.clear
        label.adjustsFontSizeToFitWidth = true
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.numberOfLines = 2
        return label
    }()
    
    let imageSubLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap To Refresh Search"
        label.font = UIFont(name: "Poppins-Regular", size: 18)
        label.textColor = UIColor.ianBlackColor()
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.clear
        label.adjustsFontSizeToFitWidth = true
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.numberOfLines = 2
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame:frame)
        backgroundColor = UIColor.white
        
        let cellView = UIView()
        addSubview(cellView)
        cellView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        cellView.backgroundColor = UIColor.backgroundGrayColor()

        cellView.addSubview(imageIcon)
        imageIcon.anchor(top: topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 50, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 100, height: 100)
        imageIcon.centerXAnchor.constraint(equalTo: cellView.centerXAnchor).isActive = true

        imageIcon.center = cellView.center
        imageIcon.addTarget(self, action: #selector(didTap), for: .touchUpInside)
        imageIcon.isUserInteractionEnabled = true
        imageIcon.isHidden = true
        
        cellView.addSubview(defaultIcon)
        defaultIcon.anchor(top: topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 50, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 150, height: 100)
        defaultIcon.centerXAnchor.constraint(equalTo: cellView.centerXAnchor).isActive = true

        defaultIcon.center = cellView.center
        defaultIcon.addTarget(self, action: #selector(didTap), for: .touchUpInside)
        defaultIcon.isUserInteractionEnabled = true
        defaultIcon.isHidden = false

        cellView.addSubview(imageLabel)
        imageLabel.anchor(top: imageIcon.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        imageLabel.sizeToFit()
        imageLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
        imageLabel.isUserInteractionEnabled = true
        
        cellView.addSubview(imageSubLabel)
        imageSubLabel.anchor(top: imageLabel.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        imageSubLabel.sizeToFit()
        imageSubLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
        imageSubLabel.isUserInteractionEnabled = true
        
    }
    
    @objc func didTap() {
        self.delegate?.didTapEmptyCell()
//        if isFiltering {
//            self.delegate?.handleRefresh()
//        } else {
//            NotificationCenter.default.post(name: MainTabBarController.OpenAddNewPhoto, object: nil)
//        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    


}




class EmptyPhotoGridCell: UICollectionViewCell {
    
    var listCellHeight: CGFloat = 140
    var listCellWidth: CGFloat = 100
    
    
    
    let listHeaderImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .ianWhiteColor()
        iv.tintColor = UIColor.ianWhiteColor()
        iv.image =  #imageLiteral(resourceName: "noResults_pic").withRenderingMode(.alwaysOriginal)
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        
        
//        iv.layer.cornerRadius = 50/2
//        iv.layer.masksToBounds = true
        return iv
    }()
    
    let emptyCellLabel: UILabel = {
        let label = UILabel()
        label.text = "No Posts"
        label.font = UIFont(name: "Poppins-Bold", size: 20)
        label.adjustsFontSizeToFitWidth = false
        label.textAlignment = NSTextAlignment.center
        label.textColor = UIColor.ianBlackColor()
        //        label.numberOfLines = 0
        return label
    }()
    
    override var isSelected: Bool {
        didSet {
//            self.listNameLabel.textColor = self.isSelected ? UIColor.white : UIColor.ianBlackColor()
//            self.listDetailLabel.textColor = self.isSelected ? UIColor.white : UIColor.darkGray
//            self.cellView.backgroundColor = self.isSelected ? UIColor.ianLegitColor() : UIColor.clear
//            self.layer.borderColor = self.isSelected ? UIColor.ianLegitColor().cgColor : UIColor.gray.cgColor

        }
    }
    
    let cellView = UIView()
    let detailView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.layer.cornerRadius = 5
        self.layer.masksToBounds = true
        self.clipsToBounds = true
        self.layer.borderColor = UIColor.gray.cgColor
        self.layer.borderWidth = 0
        self.layer.applySketchShadow()
        
        addSubview(cellView)
        cellView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        cellView.backgroundColor = UIColor.ianWhiteColor()

        cellView.addSubview(listHeaderImageView)
//        listHeaderImageView.isListBackground = true
        listHeaderImageView.anchor(top: cellView.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 30, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 50, height: 50)
//        listHeaderImageView.heightAnchor.constraint(equalTo: listHeaderImageView.widthAnchor, multiplier: 1, constant: 0).isActive = true
        listHeaderImageView.centerXAnchor.constraint(equalTo: cellView.centerXAnchor).isActive = true
        

        cellView.addSubview(emptyCellLabel)
        emptyCellLabel.anchor(top: listHeaderImageView.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        emptyCellLabel.centerXAnchor.constraint(equalTo: cellView.centerXAnchor).isActive = true
//        emptyCellLabel.centerYAnchor.constraint(equalTo: detailView.centerYAnchor).isActive = true
        emptyCellLabel.sizeToFit()
        
    }
    
    

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

}
