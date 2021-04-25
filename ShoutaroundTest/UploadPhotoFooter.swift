//
//  UploadPhotoFooter.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 6/9/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

protocol UploadPhotoFooterDelegate {
    func handleNext()
}

class UploadPhotoFooter: UIView {
    
    var delegate: UploadPhotoFooterDelegate?
    var selectedStep = 0 {
        didSet {
            refreshBoxes()
        }
    }
    
    func refreshBoxes(){
        for (index, box) in boxArray.enumerated() {
            box.backgroundColor = (index < selectedStep) ? UIColor.ianLegitColor() : UIColor.clear
            box.textColor = (index < selectedStep) ? UIColor.white : UIColor.gray
            box.layer.borderColor = (index < selectedStep) ? UIColor.clear.cgColor : UIColor.gray.cgColor
            box.layer.borderWidth = (index < selectedStep) ? 0 : 1

        }

    }
    
    var boxArray: [UILabel] = []
    
    let box1: UILabel = {
        let label = UILabel()
        label.text = "1"
        label.textColor = UIColor.white
        label.font = UIFont(font: .avenirNextBold, size: 16)
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.ianLegitColor()
        label.layer.cornerRadius = 2
        return label
    }()
    
    let box2: UILabel = {
        let label = UILabel()
        label.text = "2"
        label.textColor = UIColor.white
        label.font = UIFont(font: .avenirNextBold, size: 16)
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.ianLegitColor()
        label.layer.cornerRadius = 2
        return label
    }()
    
    let box3: UILabel = {
        let label = UILabel()
        label.text = "3"
        label.textColor = UIColor.white
        label.font = UIFont(font: .avenirNextBold, size: 16)
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.ianLegitColor()
        label.layer.cornerRadius = 2
        return label
    }()
    
    // FOLLOW UNFOLLOW BUTTON
    lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont(font: .avenirNextBold, size: 16)
        button.setTitle("Next ", for: .normal)
        button.setImage(#imageLiteral(resourceName: "navShareImage").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.ianLegitColor()
        button.setTitleColor(.ianLegitColor(), for: .normal)
        button.layer.borderColor = UIColor.ianLegitColor().cgColor
        button.layer.borderWidth = 1
        button.backgroundColor = UIColor.white
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        button.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
        button.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        button.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        button.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        return button
    }()
    
    @objc func handleNext(){
        self.delegate?.handleNext()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let cellView = UIView()
        addSubview(cellView)
        cellView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        cellView.backgroundColor = UIColor.white

        let topDiv = UIView()
        topDiv.backgroundColor = UIColor.ianLegitColor()
        addSubview(topDiv)
        topDiv.anchor(top: cellView.topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 2)
        
        addSubview(box1)
        box1.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 25, height: 25)
        box1.centerYAnchor.constraint(equalTo: cellView.centerYAnchor).isActive = true
        
        addSubview(box2)
        box2.anchor(top: nil, left: box1.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 25, height: 25)
        box2.centerYAnchor.constraint(equalTo: cellView.centerYAnchor).isActive = true

        addSubview(box3)
        box3.anchor(top: nil, left: box2.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 25, height: 25)
        box3.centerYAnchor.constraint(equalTo: cellView.centerYAnchor).isActive = true

        boxArray = [box1,box2,box3]
        
        let boxLine = UIView()
        addSubview(boxLine)
        boxLine.anchor(top: nil, left: box1.rightAnchor, bottom: nil, right: box2.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 2)
        boxLine.centerYAnchor.constraint(equalTo: box1.centerYAnchor).isActive = true
        boxLine.backgroundColor = UIColor.ianLegitColor()
        
        let boxLine2 = UIView()
        addSubview(boxLine2)
        boxLine2.anchor(top: nil, left: box2.rightAnchor, bottom: nil, right: box3.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 2)
        boxLine2.centerYAnchor.constraint(equalTo: box1.centerYAnchor).isActive = true
        boxLine2.backgroundColor = UIColor.ianLegitColor()
        
        addSubview(nextButton)
        nextButton.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        nextButton.sizeToFit()
        nextButton.centerYAnchor.constraint(equalTo: cellView.centerYAnchor).isActive = true

        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
}
