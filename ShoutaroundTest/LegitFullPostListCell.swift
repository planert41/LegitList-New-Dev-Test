//
//  LegitFullPostListCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/20/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

//
//  UploadEmojiCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/13/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit

class LegitFullPostListCell: UICollectionViewCell {
    
    var displayListInput: [String:String]? {
        didSet{
            if (displayListInput?.count)! > 0 {
                for (key,value) in displayListInput! {
                    self.displayListId = key
                    self.displayListName = value
                }
            }
        }
    }
    
    var displayListName: String? {
        didSet {
            setupListName()
        }
    }
    
    var otherUser: Bool = false {
        didSet {
            setupListName()
        }
    }
    
    //    let cellBackgroundColor = UIColor(hexColor: "FE5F55").withAlphaComponent(0.75).cgColor
    
    let cellBackgroundColor = UIColor.otherUserColor().withAlphaComponent(0.5).cgColor
    let cellLegitColor = UIColor.legitColor().withAlphaComponent(0.6).cgColor
    var textColor: UIColor = UIColor.ianBlackColor()
    
    func setupListName(){
        

        
        guard let _ = self.displayListName else {return}
        let attributedListText = NSMutableAttributedString()
        
        let attributedSpace = NSMutableAttributedString(string: " " )
        attributedListText.append(attributedSpace)
        
        let imageSize = CGSize(width: displayFont, height: displayFont)
        textColor = UIColor.white
        
        let bookmarkImage = NSTextAttachment()
        let bookmarkIcon = #imageLiteral(resourceName: "listsHash_vector").withRenderingMode(.alwaysTemplate)
        //            let bookmarkIcon = #imageLiteral(resourceName: "listsHash").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
        bookmarkImage.bounds = CGRect(x: 0, y: (displayList.font.capHeight - bookmarkIcon.size.height).rounded() / 2, width: bookmarkIcon.size.width, height: bookmarkIcon.size.height)
        bookmarkImage.image = bookmarkIcon
        
        let bookmarkImageString = NSAttributedString(attachment: bookmarkImage)
        attributedListText.append(bookmarkImageString)
        
        
        let attributedString = NSAttributedString(string: " " + self.displayListName!, attributes: [NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: displayFont)])
        
        attributedListText.append(attributedString)
        
        // FOR ICON IMAGE
        attributedListText.addAttribute(
            NSAttributedString.Key.foregroundColor,
            value: UIColor.white,
            range: NSMakeRange(0, 2))
        
        self.displayList.attributedText = attributedListText
//        self.displayList.tintColor = UIColor.ianLegitColor()
        self.displayList.tintColor = UIColor.white

        self.displayList.sizeToFit()
        self.bringSubviewToFront(self.displayList)
        self.setNeedsUpdateConstraints()
        self.setNeedsDisplay()
        self.invalidateIntrinsicContentSize()
        self.layoutSubviews()

    }
    
    var displayListId: String?
    var displayTag: Int?
    
    let displayList: LightPaddedUILabel = {
        let iv = LightPaddedUILabel()
        return iv
    }()
    
    var displayFont: CGFloat = 12 {
        didSet{
            displayList.font = UIFont.boldSystemFont(ofSize: self.displayFont)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.frame = self.bounds
        self.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
//        self.contentView.autoresizingMask = .flexibleWidth
//        self.contentView.translatesAutoresizingMaskIntoConstraints = true
    }
    
    override init(frame: CGRect) {
        super.init(frame:frame)
//        self.backgroundColor = UIColor.yellow
//        self.createRectangle()
        
        addSubview(displayList)
        displayList.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 3, paddingLeft: 7, paddingBottom: 3, paddingRight: 7, width: 0, height: 20)
        displayList.textAlignment = NSTextAlignment.center
        displayList.center = self.center
        displayList.backgroundColor = .clear
        displayList.font = UIFont.boldSystemFont(ofSize: self.displayFont)
        displayList.textColor = UIColor.white
//        self.backgroundColor = UIColor.yellow
        
//        layer.borderWidth = 1
//        layer.borderColor = UIColor.rgb(red: 221, green: 221, blue: 221).cgColor
//        layer.backgroundColor = UIColor.white.cgColor
        //        layer.backgroundColor = UIColor(hexColor: "FE5F55").withAlphaComponent(0.75).cgColor
        
//        layer.cornerRadius = 15
//        layer.masksToBounds = true
        
        
    }
    
    
    func createTriangles(){
        
        path.removeAllPoints()
        
        var slant: CGFloat = 5.0
        path.move(to: CGPoint(x: 0.0, y: 0.0))
        path.addLine(to: CGPoint(x: 0.0, y: self.frame.size.height))
        path.addLine(to: CGPoint(x: 0.0 + slant, y: self.frame.size.height))
        path.close()
//        UIColor.ianBlackColor().setFill()
//        path.fill()
        
        let shapeLayer1 = CAShapeLayer()
        shapeLayer1.path = path.cgPath
        shapeLayer1.fillColor = UIColor.ianBlackColor().cgColor
        self.layer.addSublayer(shapeLayer1)
        
        var path2 = UIBezierPath()
        path2.move(to: CGPoint(x: self.frame.size.width, y: 0.0))
        path2.addLine(to: CGPoint(x: self.frame.size.width, y: self.frame.size.height))
        path2.addLine(to: CGPoint(x: self.frame.size.width - slant, y: 0))
        path2.close()
//        UIColor.ianBlackColor().setFill()
//        path2.fill()
        
        let shapeLayer2 = CAShapeLayer()
        shapeLayer2.path = path2.cgPath
        shapeLayer2.fillColor = UIColor.ianLegitColor().cgColor
        self.layer.addSublayer(shapeLayer2)
        
    }
    
    var path = UIBezierPath()
    
    func createRectangle() {
        
        path.removeAllPoints()

        // Initialize the path.
        var slant: CGFloat = 12.0
        
        // Specify the point that the path should start get drawn.
        path.move(to: CGPoint(x: 0.0, y: 0.0))
        
        // Create a line between the starting point and the bottom-left side of the view.
        path.addLine(to: CGPoint(x: 0.0 + slant, y: self.frame.size.height))
        
        // Create the bottom line (bottom-left to bottom-right).
        path.addLine(to: CGPoint(x: self.frame.size.width, y: self.frame.size.height))
        
        // Create the vertical line from the bottom-right to the top-right side.
        path.addLine(to: CGPoint(x: self.frame.size.width - slant, y: 0.0))
        
        // Close the path. This will create the last line automatically.
        path.close()
        
        let shapeLayer1 = CAShapeLayer()
        shapeLayer1.path = path.cgPath
        shapeLayer1.fillColor = UIColor.ianBlackColor().cgColor
        self.layer.addSublayer(shapeLayer1)
        self.layer.addSublayer(displayList.layer)
        
//        UIColor.ianBlackColor().setFill()
//        path.fill()
//
//        UIColor.yellow.setStroke()
//        path.stroke()
        
//        print("\(self.frame.size.width) | \(self.frame.size.height)")
    }
    
    //    override func prepareForReuse() {
    //        layer.backgroundColor = UIColor(hexColor: "FE5F55").withAlphaComponent(0.75).cgColor
    //    }
    
    override func draw(_ rect: CGRect) {
//        self.createTriangles()
        self.createRectangle()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init coder error")
    }
    
    override func layoutSubviews() {
        self.invalidateIntrinsicContentSize()
        self.setNeedsDisplay()
    }
    
    func erasePath(){
        path.removeAllPoints()
        path = UIBezierPath()
        self.setNeedsDisplay()
    }
    
    override func prepareForReuse() {
        self.displayListName = ""
        self.displayList.sizeToFit()
//        path.removeAllPoints()
        self.erasePath()
        self.invalidateIntrinsicContentSize()

//        self.setNeedsDisplay()
    }
    
    
}
