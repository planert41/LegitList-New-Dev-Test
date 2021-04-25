//
//  BounceSelectCell.swift
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
protocol BounceSelectCellDelegate {
    func didSelect(tag: Int?) 
    
}

class BounceSelectCell: UICollectionViewCell {
    
    var delegate: BounceSelectCellDelegate?

    
    let uploadLocations: LightPaddedUILabel = {
        
        let iv = LightPaddedUILabel()
        iv.backgroundColor = .clear
        iv.font = UIFont(name: "Poppins-Regular", size: 13)
        iv.isUserInteractionEnabled = true
        return iv
        
    }()
    
    var cellTag: Int? = nil
    
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
    
    override var isSelected: Bool {
        didSet {
            self.backgroundColor = isSelected ? UIColor.legitColor() : UIColor.white
            self.uploadLocations.textColor = isSelected ? UIColor.white : UIColor.black
        }
    }
    
    @objc func handleBounce(){
        
        self.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        self.isSelected = true
        
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.transform = .identity
            },
                       completion: { (finished: Bool) in
                        self.delegate?.didSelect(tag: self.cellTag)
        }
        )
    
    
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init coder error")
    }
    
}
