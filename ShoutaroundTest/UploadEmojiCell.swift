//
//  UploadEmojiCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/13/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit


protocol UploadEmojiCellDelegate {
    func didTapRatingEmoji(emoji:String)
    func didTapNonRatingEmoji(emoji:String)
}

class UploadEmojiCell: UICollectionViewCell {
    
    var delegate: UploadEmojiCellDelegate?

    let uploadEmojis: UILabel = {
        
        let iv = UILabel()
        iv.backgroundColor = .clear
        iv.font = iv.font.withSize(EmojiSize.width * 0.8)
        iv.isUserInteractionEnabled = true
        iv.adjustsFontSizeToFitWidth = true
        iv.numberOfLines = 0
//        iv.textAlignment = NSTextAlignment.center
        iv.lineBreakMode = NSLineBreakMode.byTruncatingTail
        return iv
        
    }()
    
    var isRatingEmoji: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        backgroundColor = .white
        addSubview(uploadEmojis)
        uploadEmojis.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: frame.width, height: frame.height)
        uploadEmojis.textAlignment = NSTextAlignment.center
        uploadEmojis.center = self.center
        uploadEmojis.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selected)))
        uploadEmojis.alpha = isSelected ? 1 : 0.6

        layer.borderWidth = 1
        layer.borderColor = UIColor.lightGray.cgColor
        layer.cornerRadius = 10
        layer.masksToBounds = true
        
    }
    
    var selectedBackgroundColor = UIColor.ianLegitColor().withAlphaComponent(0.6)
    var selectedBorderColor = UIColor.ianLegitColor().cgColor
    var suggestedBackgroundColor = UIColor.mainBlue().withAlphaComponent(0.2)
    var suggestedBorderColor = UIColor.mainBlue().withAlphaComponent(0.8)

    func setupSelectedView(){
        if !turnOffSelection {
            self.uploadEmojis.alpha = isSelected ? 1 : 0.6
            self.backgroundColor = isSelected ? selectedBackgroundColor : (isSuggested ? suggestedBackgroundColor : UIColor.clear)
            self.layer.borderColor = isSelected ? selectedBorderColor : (isSuggested ? suggestedBackgroundColor.cgColor : UIColor.clear.cgColor)
        }
    }
    
    var turnOffSelection = false
    
    override var isSelected: Bool {
        didSet {
            setupSelectedView()
        }
    }
    
    var isSuggested: Bool = false {
        didSet {
            setupSelectedView()
        }
    }
    
    @objc func selected(){
        self.isSelected = !self.isSelected
        print("Selected  \(self.uploadEmojis.text) \(self.isSelected)")
        if self.isSelected {
            self.uploadEmojis.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
//            UIView.animate(withDuration: 1.0,
//                           delay: 0,
//                           usingSpringWithDamping: 0.2,
//                           initialSpringVelocity: 6.0,
//                           options: .allowUserInteraction,
//                           animations: { [weak self] in
//                            self?.uploadEmojis.transform = .identity
//                            self?.uploadEmojis.layoutIfNeeded()
//
//                },
//                           completion: nil)

            UIView.animate(withDuration: 1.0, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 6, options: .allowUserInteraction) {
//                print("Selected 2 \(self.uploadEmojis.text) \(self.isSelected)")
                self.uploadEmojis.transform = .identity
                self.uploadEmojis.layoutIfNeeded()
//                print("Selected 2 \(self.uploadEmojis.text) \(self.isSelected)")

            } completion: { (com) in
//                print("Bounce Selected \(self.uploadEmojis.text)")
            }
        
        }
    
        guard let emoji = uploadEmojis.text else {return}
        if isRatingEmoji {
            self.delegate?.didTapRatingEmoji(emoji: emoji)
        } else {
            self.delegate?.didTapNonRatingEmoji(emoji: emoji)
        }
    
    }
    
        override func prepareForReuse() {
            self.turnOffSelection = false
        }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init coder error")
    }
    
}
