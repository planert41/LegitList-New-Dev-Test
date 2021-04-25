//
//  Comment.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 9/3/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation

struct Comment {
    
    var text: String
    var userId: String
    var user: User
    var creationDate: Date
    var commentId: String

    
    init(key: String, user:User, dictionary: [String:Any]) {
        self.user = user
        self.commentId = key
        self.text = dictionary["text"] as? String ?? ""
        self.userId = dictionary["uid"] as? String ?? ""
        let secondsFrom1970 = dictionary["creationDate"] as? Double ?? 0
        self.creationDate = Date(timeIntervalSince1970: secondsFrom1970)
    }
}
