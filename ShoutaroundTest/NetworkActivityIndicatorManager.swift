//
//  NetworkActivityIndicatorManager.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 5/1/21.
//  Copyright © 2021 Wei Zou Ang. All rights reserved.
//

import UIKit

class NetworkActivityIndicatorManager: NSObject {

    private static var loadingCount = 0

    class func networkOperationStarted() {

        #if os(iOS)
        if loadingCount == 0 {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        loadingCount += 1
        #endif
    }

    class func networkOperationFinished() {
        #if os(iOS)
        if loadingCount > 0 {
            loadingCount -= 1
        }
        if loadingCount == 0 {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
        #endif
    }
}
