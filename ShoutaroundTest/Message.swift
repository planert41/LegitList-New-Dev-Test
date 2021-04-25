//
//  Message.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/19/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

class MessageThread {
    let threadID: String
    let creatorUID: String
    let postId: String
    var messageDictionaries: [String: Any]? = [:]
    var threadUsers: [String] = [] // Usernames
    var threadUserUids: [String] = [] // UIDS
    var threadUserDic: [String: String] = [:]
    let creationDate: Date
    var lastCheckDate: Date = Date.distantPast {
        didSet {
            checkRead()
        }
    }
    var messages: [Message] = []
    var lastMessageDate: Date = Date.distantPast
    var isRead: Bool = false
    var userArray: [String: User] = [:]
    
    func checkRead() {
        if self.messages.count > 0 {
            if self.messages.sorted(by: { (m1, m2) -> Bool in
                return m1.creationDate.compare(m2.creationDate) == .orderedDescending
            })[0].senderUID == Auth.auth().currentUser?.uid {
                self.isRead = true
            } else {
                isRead = lastCheckDate > lastMessageDate
            }
        } else {
            isRead = lastCheckDate > lastMessageDate
        }
    }
    
    init(threadID: String, dictionary: [String:Any]) {
        
        let secondsFrom1970 = dictionary["creationDate"] as? Double ?? 0
        self.creationDate = Date(timeIntervalSince1970: secondsFrom1970)
        
        self.threadID = threadID as? String ?? ""
        self.creatorUID = dictionary["creatorUID"] as? String ?? ""
        self.postId = dictionary["postUID"] as? String ?? ""
        
        self.threadUserDic = dictionary["users"] as? [String: String] ?? [:] // UID: Usernames
        for (key,value) in self.threadUserDic {
            self.threadUsers.append(value)
            self.threadUserUids.append(key)
        }
        
        // Set Messages
//        print("fetch Message Dic: ", dictionary["messages"])
        let tempMessageDic = dictionary["messages"] as? [String:Any] ?? [:]
        self.messageDictionaries = tempMessageDic
        self.messages = []

        let sentMsg = dictionary["sentMessage"] as? String ?? ""
        let sentMsgDic = ["creationDate": secondsFrom1970, "creatorUID": self.creatorUID, "message": sentMsg] as [String : Any]
        var firstSentMsg = Message.init(messageID: "first", dictionary: sentMsgDic)
        
        // Check First Message - Sometimes Sent = First Msg
//        self.messages.append(firstSentMsg)

        for (key,value) in tempMessageDic {
            if let value = value as? [String: Any] {
                let tmpMsg = Message.init(messageID: key, dictionary: value)
                if !(tmpMsg.message == sentMsg && tmpMsg.senderUID == self.creatorUID) {
                    self.messages.append(tmpMsg)
                }
                
                if self.lastMessageDate == nil || tmpMsg.creationDate > self.lastMessageDate ?? Date.distantPast {
                    self.lastMessageDate = tmpMsg.creationDate
                    self.isRead = (tmpMsg.senderUID == Auth.auth().currentUser?.uid)
                }
                
            }
        }
//        print("input Message Dic: ", messageDictionaries)
    }
}

struct Message {
    let messageID: String
    let senderUID: String
    let message : String
    let postId: String?
    let creationDate: Date
    var user: User?

    init(messageID: String, dictionary: [String:Any]) {
        
        let secondsFrom1970 = dictionary["creationDate"] as? Double ?? 0
        self.creationDate = Date(timeIntervalSince1970: secondsFrom1970)
        self.messageID = messageID as? String ?? ""
        self.senderUID = dictionary["creatorUID"] as? String ?? ""
        self.message = dictionary["message"] as? String ?? ""
        self.postId = dictionary["postId"] as? String

    }
}
