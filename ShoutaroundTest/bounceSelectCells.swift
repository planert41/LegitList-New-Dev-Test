//
//  bounceSelectCells.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 6/29/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import Foundation
//
//  UploadLocationCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/5/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit


class BounceSelectCell: UICollectionViewCell {
    
    let uploadLocations: LightPaddedUILabel = {
        
        let iv = LightPaddedUILabel()
        iv.backgroundColor = .clear
        iv.font = UIFont(name: "Poppins-Regular", size: 13)
        iv.isUserInteractionEnabled = true
        return iv
        
    }()
    
    var bounce = false {
        didSet{
            self.uploadLocations.isUserInteractionEnabled = bounce
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        backgroundColor = .white
        addSubview(uploadLocations)
        uploadLocations.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        uploadLocations.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleBounce)))
        
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.black.cgColor
        layer.cornerRadius = 15
        layer.masksToBounds = true
        
        
    }
    
    func handleBounce(){
        
        self.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.transform = .identity
            },
                       completion: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init coder error")
    }
    
}
