//
//  HomePostCellFlowLayout.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 7/24/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

class HomePostCellFlowLayout: UICollectionViewFlowLayout {
    
    let minItemWidth: CGFloat = 40
    
    override init() {
        super.init()
        setupLayout()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayout()
    }
    
    /**
     Sets up the layout for the collectionView. 0 distance between each cell, and vertical layout
     */
    func setupLayout() {
        
        
        var width: CGFloat = 0
        if let _ = collectionView{
            width = (collectionView?.frame.width)!
        } 
        
        var height: CGFloat = 50 //headerview = username userprofileimageview
        height += width  // Picture
        height += 40 + 5    // Action Bar
        height += 25        // Location View
        height += 25 + 5    // Extra Tag Bar
        height += 20    // Date Bar
        
        
        estimatedItemSize = CGSize(width: width, height: height)
        //        itemSize = CGSize(width: 60, height: 30)
//
//        minimumInteritemSpacing = 0
//        minimumLineSpacing = 0
//        scrollDirection = .horizontal
//        sectionInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        
    }
    
//
//    override var collectionViewContentSize: CGSize {
//
//        var size = super.collectionViewContentSize
//        if size.width < minItemWidth {
//            size.width = minItemWidth
//        }
//        return size
//
//    }
    
    //
    //    func itemWidth() -> CGFloat {
    //        return collectionView!.frame.width
    //    }
    //
    //    func itemHeight() -> CGFloat {
    //        return collectionView!.frame.height - 2
    //    }
    
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        return collectionView!.contentOffset
    }
}
