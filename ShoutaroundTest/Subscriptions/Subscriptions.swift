//
//  Subscriptions.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 5/3/21.
//  Copyright © 2021 Wei Zou Ang. All rights reserved.
//

import Foundation

enum SubPeriod: String {
    case annual
    case monthly
}


struct Subscription: Hashable, Equatable {
    
    var id: String
    var sellerUID: String?
    var buyerUID: String?
    var purchaseDate: Date = Date()
    var firstPurchaseDate: Date = Date()
    var expiryDate: Date = Date()
    var price: Double = 0.0
    var subPeriod: SubPeriod?
    var isActive = false
    var premiumSub = false
    var premiumSubId = false
    var isRenewable = false


    var hashValue: Int { get { return id.hashValue } }

    init(transactionId: String?, dictionary: [String:Any]) {

        
        var tempId = ""
        var transactions = dictionary["transactions"] as? [String: Double] ?? [:]

        if transactionId != nil {
            tempId = transactionId!
        } else if transactions.count > 0 {
            tempId = transactions.sorted { $0.1 < $1.1 }.first!.key
        }
        
        self.id = tempId
        self.sellerUID = dictionary["sellerUID"] as? String ?? ""
//        self.purchaserUID = purchaserUID
        self.buyerUID = dictionary["buyerUID"] as? String ?? ""

        self.firstPurchaseDate = Date(timeIntervalSince1970: dictionary["firstPurchaseDate"] as? Double ?? 0)
        self.purchaseDate = Date(timeIntervalSince1970: dictionary["purchaseDate"] as? Double ?? 0)
        self.expiryDate = Date(timeIntervalSince1970: dictionary["expiryDate"] as? Double ?? 0)
        self.isActive = Date() <= self.expiryDate
        self.price = dictionary["price"] as? Double ?? 0.0
        
        var tempLength = dictionary["subPeriod"] as? String ?? ""
        if tempLength == "annual" {
            self.subPeriod = SubPeriod.annual
        } else if tempLength == "monthly" {
            self.subPeriod = SubPeriod.monthly
        } else {
            self.subPeriod = nil
        }
        
        self.premiumSub = dictionary["premiumSub"] as? Bool ?? false
        self.isRenewable = dictionary["isRenewable"] as? Bool ?? false

    }
}
