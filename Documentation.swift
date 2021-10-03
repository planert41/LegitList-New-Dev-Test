//
//  Documentation.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 6/15/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation

/*
Documentation on post upload
 
 Home Controller Fetch Post Process
 1) Fetches Post Ids
        Current User
            - Fetch Current User based on Auth UID (Firebase - users)
            - Fetches all Post IDs for UID (Firebase - userposts)
            - Checks for duplicate Post IDs
            - Triggers userPostIdFetched
        Followed Users
            - Fetch Following User IDs (Firebase - following)
            - Fetch all Post IDs for Following UIDS (Firebase - userposts)
            - Check for Dup Post IDs
            - Triggers followingPostIdFetched
        Checks User Social Stats
            - Checks Saved Following Count against pulled user ids (Firebase - users - social)
        Triggers finishFetchingFollowingPostIdsNotificationName
 
 2) Finish fetching post Ids, and fetch all posts
        Loops through all fetched post Ids
            - Triggers fetchPostWithPostID
                - Pulls post from cache if exists
                - Retrieves dictionary from Firebase "post"
                    - If no dictionary/doesn't exidst, returns nil
                    - If no creator UID, returns nil
                - Finds User from Firebase "users"
                    - If uid == "" returns nil
                    - if dictionary doesn't exist returns nil
                    - returns created user object
                - Creates post with post values and user object
                - Updates post with social values
                    - Votes, Lists, Messages
                - Returns updated post object
        Appends post object to post array
 
 
 
 
 Main View Controller Process
 1. Setup Views (Map, CollectionView, Navigation Items, Buttons, Notif Centers)
 2. Fetches Current User
 2. View will Appear
    - If No user, presents Login Controller
    - Fetches Current User (List Ids, Location, Posts)
        - Fetches all self and following post ids
        - Fetches all Post items
        - Filter Sort Posts
        - Counts Most Used Emojis for creator
 3. Sets Up Views After fetching User
 
 
 
 */
