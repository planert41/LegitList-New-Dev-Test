//
//  CommonObjects.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/11/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import Cosmos

class TemplateObjects {
    
    class NavBarMapButton: UIButton {
        
        override init(frame: CGRect) {
            super.init(frame: CGRect(x: 0, y: 0, width: 70, height: 30))
            let iconImage = #imageLiteral(resourceName: "map").withRenderingMode(.alwaysTemplate)
            self.setImage(iconImage, for: .normal)
            self.imageView?.contentMode = .scaleAspectFit
            
            self.tintColor = UIColor.ianBlackColor()
            
            self.setTitleColor(UIColor.ianBlackColor(), for: .normal)
            self.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            self.setTitle(" Map ", for: .normal)
            self.contentHorizontalAlignment = .center
            self.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
            
            self.layer.borderColor = UIColor.ianBlackColor().cgColor
            self.layer.borderWidth = 1
            self.layer.cornerRadius = 1
            self.clipsToBounds = true
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class NavGridButton: UIButton {
        
        public var isGridView = false {
            didSet {
                var image = isGridView ? #imageLiteral(resourceName: "grid") : #imageLiteral(resourceName: "listFormat")
                self.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
                self.setTitle(isGridView ? "GRID" : "LIST", for: .normal)
            }
        }
        
        func changeToGrid(){
            
        }
        
        override init(frame: CGRect) {
            super.init(frame: CGRect(x: 0, y: 0, width: 70, height: 30))
            let iconImage = #imageLiteral(resourceName: "grid").withRenderingMode(.alwaysTemplate)

            self.setImage(iconImage, for: .normal)
            self.imageView?.contentMode = .scaleAspectFill

            self.tintColor = UIColor.ianBlackColor()
            
            self.setTitleColor(UIColor.ianBlackColor(), for: .normal)
            self.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            self.setTitle(" GRID ", for: .normal)
            self.contentHorizontalAlignment = .center
            
            self.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
            
            self.layer.cornerRadius = 1
            self.layer.borderColor = UIColor.ianBlackColor().cgColor
            self.layer.borderWidth = 1
            self.clipsToBounds = true
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    
    class NavSearchButton: UIButton {
        
        override init(frame: CGRect) {
            super.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//            self.setImage(#imageLiteral(resourceName: "search_selected").withRenderingMode(.alwaysTemplate), for: .normal)
            self.setImage(#imageLiteral(resourceName: "filter_alt").withRenderingMode(.alwaysTemplate), for: .normal)
            self.tintColor = UIColor.ianBlackColor()

            self.layer.cornerRadius = 1
            self.contentHorizontalAlignment = .center
//            self.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 10)
            self.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)

            self.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
            self.setTitleColor(UIColor.ianBlackColor(), for: .normal)
            self.layer.borderColor = UIColor.ianBlackColor().cgColor
            self.layer.borderWidth = 1
            self.clipsToBounds = true
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class NavShareButton: UIButton {
        
        override init(frame: CGRect) {
            super.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            self.setImage(#imageLiteral(resourceName: "share").withRenderingMode(.alwaysTemplate), for: .normal)
            self.tintColor = UIColor.ianBlackColor()

            self.layer.cornerRadius = 1
            self.contentHorizontalAlignment = .center
//            self.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 10)
            self.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)

            self.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
            self.setTitleColor(UIColor.ianBlackColor(), for: .normal)
            self.layer.borderColor = UIColor.ianBlackColor().cgColor
            self.layer.borderWidth = 0
            self.clipsToBounds = true
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    
    class NavCancelButton: UIButton {
        
        override init(frame: CGRect) {
            super.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            self.setImage(#imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysTemplate), for: .normal)
            self.tintColor = UIColor.ianWhiteColor()
            self.backgroundColor = UIColor.ianBlackColor()
            
            self.layer.cornerRadius = 1
            self.contentHorizontalAlignment = .center
            self.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
            
            self.layer.borderColor = UIColor.ianBlackColor().cgColor
            self.layer.borderWidth = 0
            self.clipsToBounds = true
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    
    class NavBarHomeButton: UIButton {
        
        override init(frame: CGRect) {
            super.init(frame: CGRect(x: 0, y: 0, width: 80, height: 30))
            let iconImage = #imageLiteral(resourceName: "home").withRenderingMode(.alwaysTemplate)
            self.setImage(iconImage, for: .normal)
            self.imageView?.contentMode = .scaleAspectFit
            
            self.tintColor = UIColor.ianWhiteColor()
            
            self.setTitleColor(UIColor.ianWhiteColor(), for: .normal)
            self.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            self.setTitle(" HOME ", for: .normal)
            self.contentHorizontalAlignment = .center
            self.contentEdgeInsets = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
            
            self.backgroundColor = UIColor.ianBlackColor()
            self.layer.borderColor = UIColor.ianBlackColor().cgColor
            self.layer.borderWidth = 1
            self.layer.cornerRadius = 1
            self.clipsToBounds = true
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class createNewListButton: UIButton {
        
        override init(frame: CGRect) {
            super.init(frame: CGRect(x: 0, y: 0, width: 160, height: 30))
            let iconImage = #imageLiteral(resourceName: "createNewList").withRenderingMode(.alwaysOriginal)
            self.setImage(iconImage, for: .normal)
            self.imageView?.contentMode = .scaleAspectFit
            
            self.contentHorizontalAlignment = .center
            self.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            
            self.backgroundColor = UIColor.ianWhiteColor()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class editListButton: UIButton {
        
        override init(frame: CGRect) {
            super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
            let iconImage = #imageLiteral(resourceName: "editList").withRenderingMode(.alwaysOriginal)
            self.setImage(iconImage, for: .normal)
            self.imageView?.contentMode = .scaleAspectFit
            
            self.contentHorizontalAlignment = .center
            self.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            
            self.backgroundColor = UIColor.ianWhiteColor()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class newListNextButton: UIButton {
//
//        var approved = false {
//            didSet {
//                let iconImage = self.approved ? #imageLiteral(resourceName: "nextButton_Selected").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "nextButton").withRenderingMode(.alwaysOriginal)
//
//            }
//        }

        override init(frame: CGRect) {
            super.init(frame: CGRect(x: 0, y: 0, width: 60, height: 55))
            let iconImage = #imageLiteral(resourceName: "nextButton").withRenderingMode(.alwaysOriginal)
            self.setImage(iconImage, for: .normal)
            let sel_iconImage = #imageLiteral(resourceName: "nextButton_Selected").withRenderingMode(.alwaysOriginal)
            self.setImage(sel_iconImage, for: .selected)

            self.imageView?.contentMode = .scaleAspectFit
            
            self.contentHorizontalAlignment = .center
            self.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            
            self.backgroundColor = UIColor.ianWhiteColor()
            self.isSelected = false
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class newListExitButton: UIButton {
        
        override init(frame: CGRect) {
            super.init(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
            self.setImage(#imageLiteral(resourceName: "cancel_black").withRenderingMode(.alwaysOriginal), for: .normal)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class newListBackButton: UIButton {
        
        override init(frame: CGRect) {
            super.init(frame: CGRect(x: 0, y: 0, width: 28, height: 28))
            let attributedString = NSMutableAttributedString(string: "BACK", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor()])
            self.setAttributedTitle(attributedString, for: .normal)
            
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class newListSkipButton: UIButton {
        
        override init(frame: CGRect) {
            super.init(frame: CGRect(x: 0, y: 0, width: 28, height: 28))
            let attributedString = NSMutableAttributedString(string: "SKIP", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor()])
            self.setAttributedTitle(attributedString, for: .normal)
            
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class NavNotificationButton: UIButton {
        
        override init(frame: CGRect) {
            super.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            let iconImage = #imageLiteral(resourceName: "alert").withRenderingMode(.alwaysTemplate)
            self.setImage(iconImage, for: .normal)
            self.imageView?.contentMode = .scaleAspectFit
            
            self.tintColor = UIColor.ianLegitColor()
            
            self.setTitleColor(UIColor.darkLegitColor(), for: .normal)
            self.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            self.setTitle("", for: .normal)
            self.contentHorizontalAlignment = .center
            self.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
            
            self.layer.borderColor = UIColor.ianBlackColor().cgColor
            self.layer.borderWidth = 0
            self.layer.cornerRadius = 1
            self.clipsToBounds = true
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class NavInboxButton: UIButton {
        
        override init(frame: CGRect) {
            super.init(frame: CGRect(x: 0, y: 0, width: 40, height: 30))
//            let iconImage = #imageLiteral(resourceName: "mailbox").withRenderingMode(.alwaysOriginal)
            let iconImage = #imageLiteral(resourceName: "inbox").withRenderingMode(.alwaysTemplate)
            self.setImage(iconImage, for: .normal)
            self.imageView?.contentMode = .scaleAspectFit
            
            self.tintColor = UIColor.darkGray
            
            self.setTitleColor(UIColor.darkLegitColor(), for: .normal)
            self.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            self.setTitle("", for: .normal)
            self.contentHorizontalAlignment = .center
            self.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
            
            self.layer.borderColor = UIColor.ianBlackColor().cgColor
            self.layer.borderWidth = 0
            self.layer.cornerRadius = 1
            self.clipsToBounds = true
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class NavSubscriptionButton: UIButton {
        
        override init(frame: CGRect) {
            super.init(frame: CGRect(x: 0, y: 0, width: 40, height: 30))
//            let iconImage = #imageLiteral(resourceName: "mailbox").withRenderingMode(.alwaysOriginal)
            let iconImage = #imageLiteral(resourceName: "payment").withRenderingMode(.alwaysOriginal)
            self.setImage(iconImage, for: .normal)
            self.imageView?.contentMode = .scaleAspectFit
            
            self.tintColor = UIColor.darkGray
            
            self.setTitleColor(UIColor.darkLegitColor(), for: .normal)
            self.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            self.setTitle("", for: .normal)
            self.contentHorizontalAlignment = .center
            self.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
            
            self.layer.borderColor = UIColor.ianBlackColor().cgColor
            self.layer.borderWidth = 0
            self.layer.cornerRadius = 1
            self.clipsToBounds = true
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    
    class StarRating: CosmosView {

        convenience init(frame: CGRect) {
            self.init(frame: CGRect(x: 0, y: 0, width: 80, height: 30))
            self.settings.fillMode = .half
            self.settings.totalStars = 5
            //        iv.settings.starSize = 30
            self.settings.starSize = 20
            self.settings.updateOnTouch = false
            self.settings.filledImage = #imageLiteral(resourceName: "ian_fullstar").withRenderingMode(.alwaysTemplate)
            self.settings.emptyImage = #imageLiteral(resourceName: "ian_emptystar").withRenderingMode(.alwaysTemplate)
            self.rating = 0
            self.settings.starMargin = 1
        }
        
        
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        
    }
        
    let StarRating: CosmosView = {
        let iv = CosmosView()
        iv.settings.fillMode = .half
        iv.settings.totalStars = 5
        //        iv.settings.starSize = 30
        iv.settings.starSize = 20
        iv.settings.updateOnTouch = false
        iv.settings.filledImage = #imageLiteral(resourceName: "ian_fullstar").withRenderingMode(.alwaysTemplate)
        iv.settings.emptyImage = #imageLiteral(resourceName: "ian_emptystar").withRenderingMode(.alwaysTemplate)
        iv.rating = 0
        iv.settings.starMargin = 1
        return iv
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: POST GRID FORMAT BUTTON

    static var postFormatDelegate: postViewFormatSegmentControlDelegate?

    class func createGridListButton() -> UISegmentedControl {
        
        var sc = UISegmentedControl(items: PostFormatOptions)
        sc.frame = CGRect(x: 0, y: 0, width: 240, height: 30)
        let gridImage = #imageLiteral(resourceName: "grid").withRenderingMode(.alwaysTemplate)
        let listImage = #imageLiteral(resourceName: "listFormat").withRenderingMode(.alwaysTemplate)
        sc.setImage(gridImage, forSegmentAt: 0)
        sc.setImage(listImage, forSegmentAt: 1)
        sc.backgroundColor = UIColor.white
        sc.tintColor = UIColor.oldLegitColor()
        if #available(iOS 13.0, *) {
            sc.selectedSegmentTintColor = UIColor.ianBlackColor()
        }
        
        let unSelectedAttribute = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12), NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor()]
        let selectedAttribute = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.ianWhiteColor()]

        
        sc.setTitleTextAttributes(unSelectedAttribute, for: .normal)
        sc.setTitleTextAttributes(selectedAttribute, for: .selected)
        
        sc.addTarget(TemplateObjects.self, action: #selector(selectPostFormat), for: .valueChanged)

        return sc
        
    }
    
    @objc class func selectPostFormat(sender: UISegmentedControl) {
        let format = PostFormatOptions[sender.selectedSegmentIndex]
        print("Template | \(format) | selectPostFormat")
        TemplateObjects.postFormatDelegate.self?.postFormatSelected(format: format)
        
    }
    
    
    class gridFormatButton: UIButton {
        
        var isGridView: Bool = true
        
        override init(frame: CGRect) {
            super.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            let gridImage = #imageLiteral(resourceName: "grid").withRenderingMode(.alwaysTemplate)
            let listImage = #imageLiteral(resourceName: "listFormat").withRenderingMode(.alwaysTemplate)
            self.setImage(isGridView ? gridImage : listImage, for: .normal)
            self.addTarget(TemplateObjects.self, action: #selector(toggleGridButton), for: .valueChanged)
            self.isUserInteractionEnabled = true
            self.backgroundColor = UIColor.white
            self.tintColor = UIColor.ianBlackColor()
            self.layer.cornerRadius = 5
            self.layer.masksToBounds = true
            self.layer.borderWidth = 1
            self.layer.borderColor = self.tintColor.cgColor
            self.semanticContentAttribute  = .forceLeftToRight
            self.setTitleColor(UIColor.ianBlackColor(), for: .normal)
            self.titleLabel?.font =  UIFont(font: .avenirNextBold, size: 13)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    
    @objc class func toggleGridButton(sender: gridFormatButton) {
        sender.isGridView = !sender.isGridView
        let gridImage = #imageLiteral(resourceName: "grid").withRenderingMode(.alwaysTemplate)
        let listImage = #imageLiteral(resourceName: "listFormat").withRenderingMode(.alwaysTemplate)
        sender.setImage(sender.isGridView ? gridImage : listImage, for: .normal)
        
        let format = PostFormatOptions[sender.isGridView ? 0 : 1]
        print("Template | \(format) | selectPostFormat")
        TemplateObjects.postFormatDelegate.self?.postFormatSelected(format: format)
    }
    

    
    
    // MARK: POST SORT BUTTON
    
    static var postSortDelegate: postSortSegmentControlDelegate?

    class func createPostSortButton() -> UISegmentedControl {
        
        
        var sc = UISegmentedControl(items: HeaderSortOptions)
        sc.backgroundColor = UIColor.white
        sc.tintColor = UIColor.oldLegitColor()
        if #available(iOS 13.0, *) {
//            sc.selectedSegmentTintColor = UIColor.ianBlackColor()
            sc.selectedSegmentTintColor = UIColor.darkGray

        }
        
//        sc.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 14), NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor()], for: .normal)
//        sc.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(font: .avenirNextDemiBold, size: 13), NSAttributedString.Key.foregroundColor: UIColor.ianWhiteColor()], for: .selected)
        
        sc.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 16), NSAttributedString.Key.foregroundColor: UIColor.gray], for: .normal)
        sc.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 15), NSAttributedString.Key.foregroundColor: UIColor.ianWhiteColor()], for: .selected)
        
        sc.addTarget(TemplateObjects.self, action: #selector(selectPostSort), for: .valueChanged)
        sc.selectedSegmentIndex = 0
        self.refreshSort(sender: sc)
        return sc
        
    }
    
    @objc class func selectPostSort(sender: UISegmentedControl) {
        let selectedSort = HeaderSortOptions[sender.selectedSegmentIndex]
        print("Template | \(selectedSort) | selectPostSort")

        self.refreshSort(sender: sender)
        TemplateObjects.postSortDelegate.self?.headerSortSelected(sort: selectedSort)
    }
    
    @objc class func refreshSort(sender: UISegmentedControl) {
        let selectedSort = HeaderSortOptions[sender.selectedSegmentIndex]
        let newTitle = headerSortDictionary[selectedSort]
        

        for (index, sortOptions) in HeaderSortOptions.enumerated()
        {
            var isSelected = (index == sender.selectedSegmentIndex)
            var displayFilter = (isSelected) ? newTitle : sortOptions
            sender.setTitle(displayFilter, forSegmentAt: index)
            sender.setWidth((isSelected) ? 110 : 100, forSegmentAt: index)
        }

    }

}

protocol postViewFormatSegmentControlDelegate {
    func postFormatSelected(format: String)
}

protocol postSortSegmentControlDelegate {
    func headerSortSelected(sort: String)
}
