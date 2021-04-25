//
//  DataStore.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 5/21/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import Foundation


//class DataStore {
//    private var posts: [Post] = []
//
//    public var numberOfPost: Int {
//        return posts.count
//    }
//
//    public func loadPostId(postId: String?) -> DataLoadOperation? {
//        guard let postId = postId else {return .none}
//
//        let myGroup = DispatchGroup()
//        myGroup.enter()
//        var fetchedPost: Post? = nil {
//            didSet {
//                if let fetchedPost = fetchedPost {
//                    return DataLoadOperation(fetchedPost)
//                }
//            }
//        }
//
//
//        Database.fetchPostWithPostID(postId: postId) { (post, err) in
//            if let err = err {
//                print("DataStore | loadPostId | ERROR | \(postId) | \(err)")
//                myGroup.leave()
//            }
//
//            fetchedPost = post
//            myGroup.leave()
//        }
//
//    }
//
//    public func update(post: Post) {
//        if let index = posts.index(where: { $0.id == post.id }) {
//            posts.replaceSubrange(index...index, with: [post])
//        }
//    }
//}


class DataLoadOperation: Operation {
    var post: Post?
    var loadingCompleteHandler: ((Post) ->Void)?
    
    private let _post: Post
    
    init(_ post: Post) {
        _post = post
    }
    
    override func main() {
//        if isCancelled { return }
//        
//        let randomDelayTime = Int.random(in: 500..<2000)
//        usleep(useconds_t(randomDelayTime * 1000))
        
        if isCancelled { return }
        post = _post
        
        if let loadingCompleteHandler = loadingCompleteHandler {
            DispatchQueue.main.async {
                loadingCompleteHandler(self._post)
            }
        }
    }
}

