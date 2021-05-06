//
//  PurchaseManager.swift
//  calm-mind
//
//  Created by Christopher Ching on 2020-11-25.
//

import Foundation
import Purchases

class PurchaseService {
    
    
    static func purchase(productId:String?, successfulPurchase:@escaping (SKPaymentTransaction?) -> Void) {
    
        guard productId != nil else {
            return
        }
        
        var skProduct:SKProduct?
        
        // Find product based on Id
        Purchases.shared.products([productId!]) { products in
            
            if !products.isEmpty {
                skProduct = products[0]
                
                // Purchase it
                Purchases.shared.purchaseProduct(skProduct!) { (transaction, purchaseInfo, error, userCancelled) in
                    // If successful purchase...
                    if let err = error as NSError? {
                                    
                        // log error details
                        print("Error: \(err.userInfo)")
                        print("Message: \(err.localizedDescription)")
                        print("Underlying Error: \(err.userInfo[NSUnderlyingErrorKey])")

                        // handle specific errors
                        switch Purchases.ErrorCode(_nsError: err).code {
                        case .purchaseNotAllowedError:
                            print("Purchases not allowed on this device.")
                        case .purchaseInvalidError:
                            print("Purchase invalid, check payment source.")
                        default:
                            break
                        }
                    }
                    
                    if error == nil && !userCancelled {
                        var transId = transaction?.transactionIdentifier
                        var trans = transaction?.original?.transactionIdentifier
                        print("TRANSID: ", transId)

                        print(transaction)

                        
                        successfulPurchase(transaction)
                    }
                    
                }
            }
        }
    }
    
}
