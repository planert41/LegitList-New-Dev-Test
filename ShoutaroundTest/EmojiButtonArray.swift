//
//  EmojiButtonArray.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 8/9/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

protocol EmojiButtonArrayDelegate {
    func didTapEmoji(index: Int?, emoji: String)
    func doubleTapEmoji(index: Int?, emoji: String)

}


class EmojiButtonArray: UIView {
    var delegate: EmojiButtonArrayDelegate?
    
    // INPUTS
    var emojiLimit = 3
    var emojiCount: Int = 0 {
        didSet {
            emojiCount = min(emojiLimit, emojiCount)
        }
    }
    var emojiLabels: [String] = [] {
        didSet{
            self.emojiCount = self.emojiLabels.count
//            self.updateEmojiButtons()
////            self.setEmojiButtons()
//            print("Emoji Labels Updated: \(self.emojiLabels)")
        }
    }
    
    var alignment = Alignment.right
    var emojiFontSize: CGFloat? = nil
    var lockEmojiWidthToFrame = true {
        didSet {
            self.emojiWidthFlexible?.isActive = lockEmojiWidthToFrame
        }
    }
    var emojiWidthFlexible: NSLayoutConstraint?
    var emojiArrayWidth: NSLayoutConstraint?

    enum Alignment {
        case left
        case right
    }
    
    
    var stackView = UIStackView()
    
    var emojiButton = UIButton()
    lazy var emojiButton1 = UIButton()
    lazy var emojiButton2 = UIButton()
    lazy var emojiButton3 = UIButton()
    lazy var emojiButton4 = UIButton()
    lazy var emojiButtonArray: [UIButton] = []

    
    @objc func emojiSelected(_ sender: UIButton){
        print(sender)

        let buttonTag = sender.tag
        let emoji = sender.titleLabel?.text
        print("Selected Emoji: \(buttonTag), \(emoji)")
        
        var selectedEmojiIndex: Int?
        if let index = self.emojiLabels.firstIndex(of: emoji!) {
            selectedEmojiIndex = index
        } else {
            selectedEmojiIndex = nil
        }
        
        
        var selectedLabel: UIButton? = UIButton()
        if self.alignment == Alignment.left {
            selectedLabel = self.emojiButtonArray[buttonTag]
        } else if self.alignment == Alignment.right {
            selectedLabel = self.emojiButtonArray.reversed()[buttonTag]
        }
        selectedLabel?.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        selectedLabel?.transform = .identity
            },
                       completion: nil)
        
        delegate?.didTapEmoji(index: selectedEmojiIndex, emoji: emoji!)
    }
    
    @objc func doubleTapEmoji(_ sender: UIButton){
        print(sender)
        let buttonTag = sender.tag
        let emoji = sender.titleLabel?.text
        print("Double Tap Emoji: \(buttonTag), \(emoji)")
        
        var selectedEmojiIndex: Int?
        if let index = self.emojiLabels.firstIndex(of: emoji!) {
            selectedEmojiIndex = index
        } else {
            selectedEmojiIndex = nil
        }
        
        
        var selectedLabel: UIButton? = UIButton()
        if self.alignment == Alignment.left {
            selectedLabel = self.emojiButtonArray[buttonTag]
        } else if self.alignment == Alignment.left {
            selectedLabel = self.emojiButtonArray.reversed()[buttonTag]
        }
        selectedLabel?.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        selectedLabel?.transform = .identity
            },
                       completion: nil)
        
        delegate?.doubleTapEmoji(index: selectedEmojiIndex, emoji: emoji!)
    }
    
    
    
    init(emojis:[String], frame: CGRect){
        super.init(frame:frame)
        self.emojiCount = emojis.count
        self.emojiLabels = Array(emojis.prefix(self.emojiCount))
//        addSubview(stackView)
//        stackView.anchor(top: self.topAnchor, left: self.leftAnchor, bottom: self.bottomAnchor, right: self.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        setEmojiButtons()
    }
    
    func updateEmojiButtons(){
//        print("UPDATE EMOJI BUTTONS")
        self.stackView = UIStackView(arrangedSubviews: [])
        self.stackView.removeFromSuperview()
        for (i,button) in emojiButtonArray.enumerated() {
            button.tag = i
            if i >= self.emojiLabels.count {
                button.setTitle(nil, for: .normal)
            } else {
                button.setTitle(self.emojiLabels[i], for: .normal)
//                print("Button Label \(i) \(button.titleLabel?.text) : \(self.emojiLabels[i])")
            }
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: self.frame.height)
            button.titleLabel?.textAlignment = NSTextAlignment.center
            button.addTarget(self, action: #selector(emojiSelected(_:)), for: .touchUpInside)
            button.addTarget(self, action: #selector(doubleTapEmoji(_:)), for: .touchDownRepeat)
        

        }
        print("Emoji Button Array : \(self.emojiLabels)")

        
    }
    
    func clearAll(){
        self.stackView = UIStackView(arrangedSubviews: [])
        self.stackView.removeFromSuperview()
    }
    
    
    func setEmojiButtons(){
//        print("SET EMOJI BUTTONS")
        let tempEmojiLabels = Array(self.emojiLabels.prefix(self.emojiLimit))
        stackView = UIStackView(arrangedSubviews: [])
        stackView.removeFromSuperview()
        emojiButton1.removeFromSuperview()
        emojiButton2.removeFromSuperview()
        emojiButton3.removeFromSuperview()
        emojiButton4.removeFromSuperview()
        
//        emojiButtonArray = [emojiButton1, emojiButton2, emojiButton3, emojiButton4]
        emojiButtonArray = [emojiButton1, emojiButton2, emojiButton3, emojiButton4]
        emojiButtonArray = Array(emojiButtonArray.prefix(self.emojiLimit))

        var fontSize = emojiFontSize ?? self.frame.height
        
        if self.alignment == Alignment.right {
            for (i,button) in emojiButtonArray.reversed().enumerated() {
                button.tag = i
                if i >= tempEmojiLabels.count {
                    button.setTitle(nil, for: .normal)
                    button.removeFromSuperview()

                } else {
                    button.setTitle(tempEmojiLabels.reversed()[i], for: .normal)
                    button.titleLabel?.font = UIFont.boldSystemFont(ofSize: fontSize)
                    button.titleLabel?.textAlignment = NSTextAlignment.center
                    button.addTarget(self, action: #selector(emojiSelected(_:)), for: .touchUpInside)
                    button.addTarget(self, action: #selector(doubleTapEmoji(_:)), for: .touchDownRepeat)

                    //                print("Button Label \(i) \(button.titleLabel?.text) : \(self.emojiLabels[i])")
                }

            }
        } else if self.alignment == Alignment.left {
            for (i,button) in emojiButtonArray.enumerated() {
                button.tag = i
                if i >= tempEmojiLabels.count {
                    button.setTitle(nil, for: .normal)
                    button.removeFromSuperview()

                } else {
                    button.setTitle(tempEmojiLabels[i], for: .normal)
                    //                print("Button Label \(i) \(button.titleLabel?.text) : \(self.emojiLabels[i])")
                    button.titleLabel?.font = UIFont.boldSystemFont(ofSize: fontSize)
                    button.titleLabel?.textAlignment = NSTextAlignment.center
                    button.addTarget(self, action: #selector(emojiSelected(_:)), for: .touchUpInside)
                    button.addTarget(self, action: #selector(doubleTapEmoji(_:)), for: .touchDownRepeat)

                    button.sizeToFit()

                }

            }
        }

        
//        for (i,button) in emojiButtonArray.enumerated() {
//            if button.titleLabel?.text == nil {
//                button.removeFromSuperview()
//            }
//        }
//        print("BUTTONS: \(emojiButton1.titleLabel?.text) \(emojiButton2.titleLabel?.text)")
//        print("Button Count \(emojiButtonArray.count) : \(self.emojiLabels)")
        stackView = UIStackView(arrangedSubviews: emojiButtonArray)
        stackView.distribution = .fillProportionally
        stackView.backgroundColor = UIColor.clear
        stackView.spacing = 1
        addSubview(stackView)
        stackView.anchor(top: self.topAnchor, left: self.leftAnchor, bottom: self.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        emojiWidthFlexible = stackView.rightAnchor.constraint(equalTo: rightAnchor)
        emojiWidthFlexible?.isActive = self.lockEmojiWidthToFrame
    }
    
    required init?(coder aDecoder: NSCoder) {
        // decode clientName and time if you want
        super.init(coder: aDecoder)
    }
    
    
    
}
