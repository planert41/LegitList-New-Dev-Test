//
//  UserSummaryLayout.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/1/20.
//  Copyright © 2020 Wei Zou Ang. All rights reserved.
//

import UIKit

class UserSummaryFlowLayout: UICollectionViewFlowLayout {
    
    // let itemHeight: CGFloat = 50
    
    override init() {
        super.init()
        setupLayout()
        
    }
    
    /**
     Init method
     
     - parameter aDecoder: aDecoder
     
     - returns: self
     */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayout()
    }
    
    /**
     Sets up the layout for the collectionView. 0 distance between each cell, and vertical layout
     */
    func setupLayout() {
        
        guard let collectionview = self.collectionView else {return}
//        let cellWidth = ((collectionview.frame.width) / 2) - 10
//        estimatedItemSize = CGSize(width: cellWidth, height: 30)
        itemSize = CGSize(width: 50, height: 60)
        minimumInteritemSpacing = 5
        minimumLineSpacing = 5
        scrollDirection = .horizontal
        sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
    }
    
//    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
//        return collectionView!.contentOffset
//    }
    
    
    
    
//        func itemWidth() -> CGFloat {
//            return (collectionView!.frame.width/2) - 10
//        }
//
//        func itemHeight() -> CGFloat {
//            return collectionView!.frame.height - 2
//        }
//
//         override var itemSize: CGSize {
//             set {
//                self.itemSize = CGSize(width: itemWidth(), height: 50)
//
//             }
//             get {
//                return CGSize(width: itemWidth(), height: 50)
//             }
//         }
    
    

}
