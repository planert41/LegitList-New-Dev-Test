//
//  PurchaseManager.swift
//  calm-mind
//
//  Created by Christopher Ching on 2020-11-25.
//

import Foundation
import RevenueCat

class PurchaseService {
    
    
    static func purchase(productId:String?, successfulPurchase:@escaping (StoreTransaction?) -> Void) {
    
        guard productId != nil else {
            return
        }
        
        var skProduct:StoreProduct?
        
        // Find product based on Id
        Purchases.shared.getProducts([productId!]) { products in
            
            if !products.isEmpty {
                skProduct = products[0]
                
                // Purchase it
                Purchases.shared.purchase(product: skProduct!) { (transaction, purchaseInfo, error, userCancelled) in
                    // If successful purchase...
                    if let err = error as NSError? {
                                    
                        // log error details
                        print("Error: \(err.userInfo)")
                        print("Message: \(err.localizedDescription)")
                        print("Underlying Error: \(err.userInfo[NSUnderlyingErrorKey])")

                        if let error = error as? RevenueCat.ErrorCode {
                            switch error {
                            case .purchaseNotAllowedError:
                                print("Purchases not allowed on this device.")
                            case .purchaseInvalidError:
                                print("Purchase invalid, check payment source.")
                            default:
                                break
                            }
                        } else {
                            // Error is a different type
                        }
                    }
                    
                    if error == nil && !userCancelled {
                        var transId = transaction?.transactionIdentifier
                        print("TRANSID: ", transId)

                        print(transaction)

                        
                        successfulPurchase(transaction)
                    }
                    
                }
            }
        }
    }
    
}
