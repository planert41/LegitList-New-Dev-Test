//
//  UserProfilePhotoCell.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/29/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit

protocol GridPhotoCellDelegate {
    func didTapPicture(post:Post)
    
}

class GridPhotoCell: UICollectionViewCell, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    
    var delegate: GridPhotoCellDelegate?
    var post: Post? {
        didSet {
            guard let imageUrl = post?.imageUrl else {return}
//            guard let url = URL(string: imageUrl) else {return}
//            photoImageView.setImageWith(url)
            setupImageCountLabel()
            setupPicturesScroll()
            photoImageView.loadImage(urlString: (post?.imageUrls.first)!)
            
            self.likeCount = post?.likeCount ?? 0
            self.listCount = post?.listCount ?? 0
            self.messageCount = post?.messageCount ?? 0
            
            setupAttributedSocialCount()

        }
    }
    
    var currentImage = 1 {
        didSet {
            setupImageCountLabel()
        }
    }
    
    var imageCount = 0
    
    func setupImageCountLabel(){
        imageCount = (self.post?.imageCount)!
        
        if imageCount == 1 {
            photoCountLabel.isHidden = true
        } else {
            photoCountLabel.isHidden = false
        }
        
        if imageCount > 1 {
            self.photoCountLabel.text = "\(currentImage)\\\(imageCount)"
        } else {
            self.photoCountLabel.text = ""
        }
        photoCountLabel.reloadInputViews()
    }
    
    var socialHide: Bool = true {
        didSet{
            if socialHide{
                self.socialCount.alpha = 0
            } else {
                self.socialCount.alpha = 1
            }
        }
    }
    
    var likeCount: Int = 0
    var listCount: Int = 0
    var messageCount: Int = 0
    
    let photoImageScrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.backgroundColor = .white
        return scroll
    }()
    
    let photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .white
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        
        return iv
        
    }()
    
    let photoCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textColor = UIColor.darkGray
        label.backgroundColor = UIColor.white
        label.layer.cornerRadius = 5
        label.layer.borderWidth = 0
        label.layer.masksToBounds = true
        label.alpha = 0.5
        return label
    }()
    
    var labelFontSize = 10 as CGFloat
    
    var socialCount: UILabel = {
        let label = UILabel()
        label.textAlignment = NSTextAlignment.right
        label.textColor = UIColor.lightGray
        label.backgroundColor = UIColor(white: 0, alpha: 0.4)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        self.backgroundColor = UIColor.clear
        
        // Photo Image
        addSubview(photoImageScrollView)
        photoImageScrollView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.width)
        photoImageScrollView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        photoImageScrollView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
        photoImageScrollView.isPagingEnabled = true
        photoImageScrollView.delegate = self

        photoImageScrollView.contentSize.width = photoImageScrollView.frame.width
        
        
        photoImageView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.width)
        photoImageScrollView.addSubview(photoImageView)
        photoImageView.tag = 0
        


        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(GridPhotoCell.handlePictureTap))
        photoImageScrollView.addGestureRecognizer(TapGesture)
        photoImageScrollView.isUserInteractionEnabled = true
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(GridPhotoCell.handleLongPress(_:)))
        longPress.minimumPressDuration = 0.25
        longPress.delegate = self
        photoImageScrollView.addGestureRecognizer(longPress)
        
        addSubview(photoCountLabel)
        photoCountLabel.anchor(top: photoImageScrollView.topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        photoCountLabel.sizeToFit()
        
        addSubview(socialCount)
        socialCount.anchor(top: nil, left: nil, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 2, paddingRight: 2, width: 0, height: 15)
        socialCount.alpha = 0

    }
    
    func setupPicturesScroll() {
        
        guard let _ = post?.imageUrls else {return}
        
        photoImageScrollView.contentSize.width = photoImageScrollView.frame.width * CGFloat((post?.imageCount)!)
        
        for i in 1 ..< (post?.imageCount)! {
            
            let imageView = CustomImageView()
            imageView.loadImage(urlString: (post?.imageUrls[i])!)
            imageView.backgroundColor = .white
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.isUserInteractionEnabled = true
            
            let xPosition = self.photoImageScrollView.frame.width * CGFloat(i)
            imageView.frame = CGRect(x: xPosition, y: 0, width: photoImageScrollView.frame.width, height: photoImageScrollView.frame.height)
            
            photoImageScrollView.addSubview(imageView)
            
        }
        //        photoImageScrollView.reloadInputViews()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.currentImage = scrollView.currentPage
    }
    
    func setupAttributedSocialCount(){
        
        let imageSize = CGSize(width: labelFontSize, height: labelFontSize)
        
        // Likes
        let attributedText = NSMutableAttributedString(string: String(self.likeCount), attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: labelFontSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.lightGray]))
        let likeImage = NSTextAttachment()
        likeImage.image = #imageLiteral(resourceName: "like_selected").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
        let likeImageString = NSAttributedString(attachment: likeImage)
        attributedText.append(likeImageString)
        
        // Bookmarks
        let bookmarkText = NSMutableAttributedString(string: String(self.listCount), attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: labelFontSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.lightGray]))
        attributedText.append(bookmarkText)
        let bookmarkImage = NSTextAttachment()
        bookmarkImage.image =  #imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
        let bookmarkImageString = NSAttributedString(attachment: bookmarkImage)
        attributedText.append(bookmarkImageString)
        
        // Messages
        let messageText = NSMutableAttributedString(string: String(self.messageCount), attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: labelFontSize), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.lightGray]))
        attributedText.append(messageText)
        let messageImage = NSTextAttachment()
        messageImage.image = #imageLiteral(resourceName: "message_fill").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
        let messageImageString = NSAttributedString(attachment: messageImage)
        attributedText.append(messageImageString)
        
        // Set Label
        socialCount.attributedText = attributedText
        socialCount.sizeToFit()
    }
    
    
    @objc func handlePictureTap() {
        guard let post = post else {return}
        print("Tap Picture")
        delegate?.didTapPicture(post: post)
    }
    @objc  
    func handleLongPress(_ gestureReconizer: UILongPressGestureRecognizer) {

        let animationDuration = 0.25
        
        if socialHide {
            if gestureReconizer.state != UIGestureRecognizer.State.recognized {
                // Fade in Social Counts when held
                UIView.animate(withDuration: animationDuration, animations: { () -> Void in
                    self.socialCount.alpha = 1
                }) { (Bool) -> Void in
                }
            }
            else if gestureReconizer.state != UIGestureRecognizer.State.changed {
                // Fade Out Social Counts when released
                UIView.animate(withDuration: animationDuration, animations: { () -> Void in
                self.socialCount.alpha = 0
                }) { (Bool) -> Void in
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        //Flickering is caused by reused cell having previous photo or loading prior image request
        photoImageScrollView.contentSize.width = photoImageScrollView.frame.width
        currentImage = 1
        photoImageView.image = nil
        photoImageView.cancelImageRequestOperation()
        post = nil
        
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
