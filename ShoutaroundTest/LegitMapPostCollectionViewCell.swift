//
//  LegitMapPostCollectionViewCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/6/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

import Cosmos


protocol LegitMapPostCollectionViewCellDelegate {
    func showEmojiDetail(emoji: String?)
    func didTapLocation(post: Post)
    func didTapUser(post: Post)
    func didTapPicture(post: Post)
    func minimizeCollectionView()
    func togglePost()
}


class LegitMapPostCollectionViewCell: UICollectionViewCell {
    
    let topView = UIView()
    let postInfoView = UIView()
    let bottomView = UIView()
    let topDivider = UIView()
    var delegate: LegitMapPostCollectionViewCellDelegate?
    
    lazy var listCollectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = .white
        return cv
    }()
    let cellId = "cellId"
    
    var listCollectionHeightConstraint:NSLayoutConstraint?
    let listCollectionHeight: CGFloat = 35
    
    
    // Lists
    var postListIds: [String] = []
    var postListNames: [String] = []
    
    // MARK: - POST INPUTS
    var post: Post? {
        didSet {
            setupPicturesScroll()
            setupUserProfileImage()
            setupLocationInfoTop()
            setupPostDetails()
            setupPostLists()

        }
    }
    
    // MARK: - CELL INPUTS
    let userProfileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        return iv
        
    }()
    
    let userProfileImageHeight: CGFloat = 30
    
    let photoImageScrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.backgroundColor = .white
        return scroll
    }()
    
    
    let photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .white
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        return iv
    }()
    
    var currentImage = 1 {
        didSet {
//            setupImageCountLabel()
        }
    }
    
    
    var pageControl : UIPageControl = UIPageControl()

    let locationNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.font = UIFont(name: "Poppins-Regular", size: 16)
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.textColor = UIColor.ianBlackColor()
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        return label
    }()
    
    var emojiArray = EmojiButtonArray(emojis: [], frame: CGRect(x: 0, y: 0, width: 0, height: 15))
    
    let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.rgb(red: 96, green: 96, blue: 96)
        label.textAlignment = NSTextAlignment.left
        return label
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = UIColor.ianBlackColor()
        label.numberOfLines = 1
        label.textAlignment = NSTextAlignment.left
        return label
    }()
    
    let postDetailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ianBlackColor()
        label.numberOfLines = 1
        label.textAlignment = NSTextAlignment.left
        return label
    }()
    
    let minimizeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "downvote").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(didTapMinimizeButton), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        return button
    } ()
    
    
    @objc func didTapMinimizeButton() {
        self.delegate?.minimizeCollectionView()
    }
    
    let ratingEmojiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = UIColor.ianBlackColor()
        label.numberOfLines = 1
        label.textAlignment = NSTextAlignment.left
        return label
    }()
    
    var ratingEmojiLabelWidth: NSLayoutConstraint?
    
//    var starRatingLabel = RatingLabelNew(ratingScore: 0, frame: CGRect.zero)
    let starRating: CosmosView = {
        let iv = CosmosView()
        iv.settings.fillMode = .half
        iv.settings.totalStars = 5
        //        iv.settings.starSize = 30
        iv.settings.starSize = 20
        iv.settings.updateOnTouch = false
        
//        var filled = UIImageView(image: #imageLiteral(resourceName: "new_star").withRenderingMode(.alwaysTemplate))
//        filled.tintColor = UIColor.ianBlackColor()
//
//        var unFilled = UIImageView(image: #imageLiteral(resourceName: "new_star").withRenderingMode(.alwaysTemplate))
//        unFilled.tintColor = UIColor.ianLightGrayColor()
//
//        iv.settings.filledImage = filled.image
//        iv.settings.emptyImage = unFilled.image
        
//        iv.settings.filledImage = #imageLiteral(resourceName: "ian_fullstar").withRenderingMode(.alwaysTemplate)
//        iv.settings.emptyImage = #imageLiteral(resourceName: "ian_emptystar").withRenderingMode(.alwaysTemplate)
        iv.settings.filledImage = #imageLiteral(resourceName: "new_star").withRenderingMode(.alwaysTemplate)
        iv.settings.emptyImage = #imageLiteral(resourceName: "new_star_gray").withRenderingMode(.alwaysTemplate)
        iv.rating = 0
        iv.settings.starMargin = 1
        return iv
    }()
    
    
    let captionTextView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.boldSystemFont(ofSize: 12)
        return tv
    }()
    
    let postDateLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.lightGray
        label.numberOfLines = 0
        return label
    }()
    
    var cellWidth: CGFloat = 0 {
        didSet {
            if cellWidth > 0 {
                cellWidthConstraint?.constant = cellWidth
            }
            cellWidthConstraint?.isActive = (cellWidth > 0.0)
        }
    }
    var cellWidthConstraint:NSLayoutConstraint?
    
    var starRatingHeightConstraint:NSLayoutConstraint?
    let starRatingHeight: CGFloat = 25
    
    var showMinimzeButton = false {
        didSet {
            self.minimizeButton.isHidden = !showMinimzeButton
            self.minimizeButton.isUserInteractionEnabled = showMinimzeButton
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        self.heightAnchor.constraint(equalToConstant: 350).isActive = true
        
        backgroundColor = UIColor.ianWhiteColor()
        addSubview(topView)
        topView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 90)
        cellWidthConstraint = topView.widthAnchor.constraint(equalToConstant: 0)
        cellWidthConstraint?.isActive = false
    
        addSubview(topDivider)
        topDivider.anchor(top: topView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 1)
        topDivider.backgroundColor = UIColor.ianGrayColor()
        
        addSubview(bottomView)
        bottomView.anchor(top: topDivider.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        
    // POPULATE TOP VIEW
        topView.addSubview(photoImageScrollView)
        photoImageScrollView.anchor(top: topView.topAnchor, left: topView.leftAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 75, height: 75)
        photoImageScrollView.isPagingEnabled = true
        photoImageScrollView.delegate = self
        photoImageScrollView.layer.cornerRadius = 2
        photoImageScrollView.clipsToBounds = true
        photoImageScrollView.layer.borderWidth = 0
        photoImageScrollView.layer.borderColor = UIColor.lightGray.cgColor
        
        photoImageScrollView.isUserInteractionEnabled = true
        photoImageScrollView.contentSize.width = photoImageScrollView.frame.width
        
        photoImageScrollView.isUserInteractionEnabled = true
        photoImageScrollView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handlePictureTap)))

        
        photoImageView.frame = CGRect(x: 0, y: 0, width: 75, height: 75)
        photoImageScrollView.addSubview(photoImageView)
        photoImageView.tag = 0
        photoImageView.isUserInteractionEnabled = true
        photoImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handlePictureTap)))
        photoImageView.layer.cornerRadius = 2
        photoImageView.layer.masksToBounds = true
        photoImageView.clipsToBounds = true

//        topView.addSubview(minimizeButton)
//        minimizeButton.anchor(top: topView.topAnchor, left: nil, bottom: nil, right: topView.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 15, height: 15)
//        minimizeButton.isHidden = true
        
        
        addSubview(pageControl)
        pageControl.anchor(top: photoImageScrollView.bottomAnchor, left: photoImageScrollView.leftAnchor, bottom: nil, right: photoImageScrollView.rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 5)
        setupPageControl()
        
        topView.addSubview(postInfoView)
        postInfoView.anchor(top: photoImageScrollView.topAnchor, left: photoImageScrollView.rightAnchor, bottom: photoImageScrollView.bottomAnchor, right: topView.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
        postInfoView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(togglePost)))
        
        
         postInfoView.addSubview(userProfileImageView)
         userProfileImageView.anchor(top: postInfoView.topAnchor, left: nil, bottom: nil, right: postInfoView.rightAnchor, paddingTop: 0, paddingLeft: -10, paddingBottom: 0, paddingRight: 0, width: userProfileImageHeight, height: userProfileImageHeight)
         userProfileImageView.layer.cornerRadius = userProfileImageHeight/2
         userProfileImageView.clipsToBounds = true
         userProfileImageView.layer.borderWidth = 1
         userProfileImageView.layer.borderColor = UIColor.ianWhiteColor().cgColor
        
        
        postInfoView.addSubview(locationNameLabel)
        locationNameLabel.anchor(top: postInfoView.topAnchor, left: postInfoView.leftAnchor, bottom: nil, right: userProfileImageView.leftAnchor, paddingTop: 1, paddingLeft: 0, paddingBottom: 0, paddingRight: 3, width: 0, height: 0)
//        locationNameLabel.rightAnchor.constraint(lessThanOrEqualTo: userProfileImageView.leftAnchor).isActive = true
        locationNameLabel.heightAnchor.constraint(lessThanOrEqualToConstant: 35).isActive = true
        
        let locationTap = UITapGestureRecognizer(target: self, action: #selector(handlePictureTap))
        locationNameLabel.addGestureRecognizer(locationTap)
        locationNameLabel.isUserInteractionEnabled = true
        
        postInfoView.addSubview(distanceLabel)
        distanceLabel.anchor(top: nil, left: nil, bottom: postInfoView.bottomAnchor, right: postInfoView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 3, paddingRight: 0, width: 0, height: 15)

        postInfoView.addSubview(emojiArray)
        emojiArray.anchor(top: locationNameLabel.bottomAnchor, left: locationNameLabel.leftAnchor, bottom: nil, right: nil, paddingTop: 3, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 15)
        emojiArray.delegate = self
        emojiArray.alignment = .left


//        postInfoView.addSubview(distanceLabel)
//        distanceLabel.anchor(top: nil, left: locationNameLabel.leftAnchor, bottom: postInfoView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 15)
//        distanceLabel.bottomAnchor.constraint(lessThanOrEqualTo: postInfoView.bottomAnchor, constant: 1).isActive = true
        
                
        postInfoView.addSubview(ratingEmojiLabel)
        ratingEmojiLabel.anchor(top: nil, left: locationNameLabel.leftAnchor, bottom: nil, right: nil, paddingTop: 3, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        ratingEmojiLabelWidth = ratingEmojiLabel.widthAnchor.constraint(equalToConstant: 0)
        ratingEmojiLabelWidth?.isActive = true
        
        postInfoView.addSubview(starRating)
        starRating.anchor(top: nil, left: ratingEmojiLabel.rightAnchor, bottom: postInfoView.bottomAnchor, right: nil, paddingTop: 3, paddingLeft: 0, paddingBottom: -5, paddingRight: 0, width: 0, height: 0)
        starRatingHeightConstraint = starRating.heightAnchor.constraint(equalToConstant: starRatingHeight)
        starRatingHeightConstraint?.isActive = true
        
        ratingEmojiLabel.centerYAnchor.constraint(equalTo: starRating.centerYAnchor).isActive = true
//        starRating.rightAnchor.constraint(lessThanOrEqualTo: bottomView.rightAnchor).isActive = true
        
        
    // BOTTOM VIEW
        bottomView.addSubview(usernameLabel)
        usernameLabel.anchor(top: bottomView.topAnchor, left: bottomView.leftAnchor, bottom: nil, right: bottomView.rightAnchor, paddingTop: 5, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 20)
        
        let usernameTap = UITapGestureRecognizer(target: self, action: #selector(handleUserTap))
        usernameLabel.addGestureRecognizer(usernameTap)
        usernameLabel.isUserInteractionEnabled = true
        
        bottomView.addSubview(postDetailLabel)
        postDetailLabel.anchor(top: usernameLabel.bottomAnchor, left: bottomView.leftAnchor, bottom: nil, right: nil, paddingTop: 3, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 20)
        postDetailLabel.rightAnchor.constraint(lessThanOrEqualTo: bottomView.rightAnchor).isActive = true
        
//        bottomView.addSubview(starRating)
//        starRating.anchor(top: postDetailLabel.bottomAnchor, left: bottomView.leftAnchor, bottom: nil, right: nil, paddingTop: 3, paddingLeft: 15, paddingBottom: 0, paddingRight: 15, width: 0, height: 0)
//        starRatingHeightConstraint = starRating.heightAnchor.constraint(equalToConstant: starRatingHeight)
//        starRatingHeightConstraint?.isActive = true
//        starRating.rightAnchor.constraint(lessThanOrEqualTo: bottomView.rightAnchor).isActive = true

        
//        bottomView.addSubview(postDateLabel)
//        postDateLabel.anchor(top: nil, left: bottomView.leftAnchor, bottom: bottomView.bottomAnchor, right: nil, paddingTop: 3, paddingLeft: 15, paddingBottom: 5, paddingRight: 15, width: 0, height: 0)
//        postDateLabel.sizeToFit()
        
        setupListCollectionView()
        bottomView.addSubview(listCollectionView)
        listCollectionView.anchor(top: nil, left: bottomView.leftAnchor, bottom: bottomView.bottomAnchor, right: bottomView.rightAnchor, paddingTop: 3, paddingLeft: 15, paddingBottom: 5, paddingRight: 15, width: 0, height: 30)
        listCollectionHeightConstraint = listCollectionView.heightAnchor.constraint(equalToConstant: listCollectionHeight)
        
        
        bottomView.addSubview(captionTextView)
        captionTextView.anchor(top: postDetailLabel.bottomAnchor, left: bottomView.leftAnchor, bottom: listCollectionView.topAnchor, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 15, paddingRight: 15, width: 0, height: 0)
        captionTextView.rightAnchor.constraint(lessThanOrEqualTo: bottomView.rightAnchor).isActive = true

        captionTextView.contentInset = UIEdgeInsets.zero
//        captionTextView.backgroundColor = UIColor.yellow
        captionTextView.textContainer.maximumNumberOfLines = 7
        captionTextView.isEditable = false
        
        let textViewTap = UITapGestureRecognizer(target: self, action: #selector(handleCaptionTap))
        captionTextView.addGestureRecognizer(textViewTap)
        captionTextView.isUserInteractionEnabled = true

        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(togglePost))
        swipeUp.direction = .up
        self.topView.addGestureRecognizer(swipeUp)
        
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(didTapMinimizeButton))
        swipeDown.direction = .down
        self.addGestureRecognizer(swipeDown)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func prepareForReuse() {
        self.post = nil
        self.userProfileImageView.image = UIImage()
        self.currentImage = 1
        self.captionTextView.text = ""
        self.usernameLabel.text = nil
        self.locationNameLabel.text = ""
        let subViews = self.subviews
        self.listCollectionView.reloadData()
        
        // Reused cells removes extra pictures and shrinks back contentsize width. It gets expanded and added back later if >1 pic
        
        for subview in subViews{
            if let img = subview as? CustomImageView {
                img.image = nil
                img.cancelImageRequestOperation()
                if img.tag != 0 {
                    img.removeFromSuperview()
                }
            }
        }
    }
    
    
}

extension LegitMapPostCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegate {
 
    func setupListCollectionView(){
        listCollectionView.register(ListDisplayCell.self, forCellWithReuseIdentifier: cellId)
        let layout = ListDisplayFlowLayout()
        listCollectionView.collectionViewLayout = layout
        listCollectionView.backgroundColor = UIColor.clear
        listCollectionView.isScrollEnabled = true
        listCollectionView.showsHorizontalScrollIndicator = false
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.post?.creatorListId != nil {
            return (self.post?.creatorListId?.count)!
        } else {return 0}
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ListDisplayCell
        
        cell.displayListName = self.postListNames[indexPath.row]
        cell.displayListId = self.postListIds[indexPath.row]
        cell.displayFont = 13
        
        return cell
    }
    
    
}



extension LegitMapPostCollectionViewCell: UIScrollViewDelegate, EmojiButtonArrayDelegate {
    
    
    func didTapEmoji(index: Int?, emoji: String) {
        self.delegate?.showEmojiDetail(emoji: emoji)
    }
    
    func doubleTapEmoji(index: Int?, emoji: String) {
        
    }
    
    
    func setupPageControl(){
        self.pageControl.numberOfPages = (self.post?.imageCount) ?? 0
        self.pageControl.currentPage = 0
        self.pageControl.tintColor = UIColor.lightGray
        self.pageControl.pageIndicatorTintColor = UIColor.lightGray
        self.pageControl.currentPageIndicatorTintColor = UIColor.ianLegitColor()
        self.pageControl.isHidden = (self.pageControl.numberOfPages == 0)
        //        self.pageControl.backgroundColor = UIColor.rgb(red: 68, green: 68, blue: 68)
    }
 
    func setupPicturesScroll() {
        
        guard let _ = post?.imageUrls else {return}
        if (post?.imageCount)! < 1 {
            return
        }
        
        if (post?.images) != nil {
            photoImageView.image = post?.images![0]
        } else {
            photoImageView.loadImage(urlString: (post?.imageUrls.first)!)
        }
        
        photoImageScrollView.contentSize.width = photoImageScrollView.frame.width * CGFloat((post?.imageCount)!)
        
        for i in 1 ..< (post?.imageCount)! {
            
            let imageView = CustomImageView()
            //            guard let images = post?.images else {return}
            
            if let images = post?.images {
                imageView.image = images[i]
            } else {
                imageView.loadImage(urlString: (post?.imageUrls[i])!)
            }
            
            imageView.backgroundColor = .white
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.isUserInteractionEnabled = true
            
            let xPosition = self.photoImageScrollView.frame.width * CGFloat(i)
            imageView.frame = CGRect(x: xPosition, y: 0, width: photoImageScrollView.frame.width, height: photoImageScrollView.frame.height)
            
            photoImageScrollView.addSubview(imageView)
            
        }
        //        photoImageScrollView.reloadInputViews()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.currentImage = scrollView.currentPage
    }
    
    func setupUserProfileImage() {
        guard let profileImageUrl = post?.user.profileImageUrl else {return}
        userProfileImageView.loadImage(urlString: profileImageUrl)
    }
    
    
    func setupLocationInfoTop(){
        setupLocationName()
        setupEmojiArray()
        setupDistance()
        
        
    }
    
    func setupLocationName() {
        // Location Name
        var locationNameDisplay: String? = ""
        var locationNameAttributedString = NSMutableAttributedString()
        
        if let postLocationName = post?.locationName {
            // If no location  name and showing GPS, show the adress instead
            if postLocationName.hasPrefix("GPS"){
                locationNameDisplay?.append((post?.locationAdress)!)
            } else {
                locationNameDisplay?.append(postLocationName.formatName())
            }
        }
        
        ratingEmojiLabel.text = ""
        ratingEmojiLabelWidth?.constant = 0
        
        if let ratingEmoji = self.post?.ratingEmoji {
            if extraRatingEmojis.contains(ratingEmoji) {
//                locationNameDisplay?.append(" \(ratingEmoji)")
                ratingEmojiLabel.text = ratingEmoji
                ratingEmojiLabelWidth?.constant = 25
            }
        }
        
        let attributedTextCaption = NSAttributedString(string: locationNameDisplay!, attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 16)])
        
        locationNameAttributedString.append(attributedTextCaption)
        locationNameLabel.attributedText = locationNameAttributedString
        
        //            locationNameLabel.text = locationNameDisplay
        locationNameLabel.adjustsFontSizeToFitWidth = true
        locationNameLabel.sizeToFit()
    }
    
    func setupEmojiArray(){
        emojiArray.emojiLabels = []
        if let displayEmojis = self.post?.nonRatingEmoji{
//            if displayEmojis.count > 0 {
//                emojiArray.emojiLabels = [displayEmojis[0]]
//            }
            emojiArray.emojiLabels = displayEmojis
        }
        
        //        print("UPDATED EMOJI ARRAY: \(emojiArray.emojiLabels)")
        emojiArray.setEmojiButtons()
        emojiArray.sizeToFit()
    }
    
    func setupDistance(){
        distanceLabel.text = SharedFunctions.formatDistance(inputDistance: post?.distance, inputType: nil, expand: false)
        distanceLabel.adjustsFontSizeToFitWidth = true
        distanceLabel.sizeToFit()
    }
    
    
    func setupPostDetails() {
        
    // USERNAME
        if let username = self.post?.user.username
        {
            self.usernameLabel.text = username
        } else {
            self.usernameLabel.text = nil
        }
        
        
    // POST DETAILS
        var postDetail = ""
        
        guard let post = self.post else {return}
        
        
    // POST AREA
        if let city = self.post?.locationSummaryID
        {
            postDetail = city + ",  "
        }
        
        // Setup Post Date
        let formatter = DateFormatter()
        let calendar = NSCalendar.current
        
        let yearsAgo = calendar.dateComponents([.year], from: post.creationDate, to: Date())
        formatter.dateFormat = "MMM d yyyy"

//        if (yearsAgo.year)! > 0 {
//            formatter.dateFormat = "MMM d yy, h:mm a"
//        } else {
//            formatter.dateFormat = "MMM d, h:mm a"
//        }
        
        let daysAgo =  calendar.dateComponents([.day], from: post.creationDate, to: Date())
        var postDateString: String?
        
        // If Post Date < 7 days ago, show < 7 days, else show date
        if (daysAgo.day)! <= 7 {
            postDateString = post.creationDate.timeAgoDisplay() + "; "
        } else {
            let dateDisplay = formatter.string(from: post.creationDate)
            postDateString = dateDisplay + "; "
        }
        
        let attributedText = NSMutableAttributedString(string: postDateString!, attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)])
        
        postDetail += (postDateString ?? "")

        self.postDetailLabel.text = postDetail

        // Star Rating
        
        let rating = (post.rating) ?? 0
        if rating > 0 {
            starRatingHeightConstraint?.constant = 25
            starRating.isHidden = false
            starRating.rating = rating
        } else{
            starRatingHeightConstraint?.constant = 0
            starRating.isHidden = true
        }
        
        // CAPTION
        setupPostCaption()
        
        // DATES
        setupPostDates()
        
    }
    
    func setupPostCaption() {
        guard let post = self.post else {return}
        
        // Set Up Caption
     
        let attCaption = NSMutableAttributedString(string: "\(post.caption.capitalizingFirstLetter())", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianBlackColor(), NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)])
        
        
        attCaption.append(NSAttributedString(string: " Go to post", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ianLegitColor(), NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 14)]))
        
        self.captionTextView.attributedText = attCaption
        self.captionTextView.sizeToFit()
        
    }
    
    func setupPostDates(){
        guard let post = self.post else {return}
        
        // Setup Post Date
        let formatter = DateFormatter()
        let calendar = NSCalendar.current
        
        let yearsAgo = calendar.dateComponents([.year], from: post.creationDate, to: Date())
        if (yearsAgo.year)! > 0 {
            formatter.dateFormat = "MMM d yy, h:mm a"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }
        
        let daysAgo =  calendar.dateComponents([.day], from: post.creationDate, to: Date())
        var postDateString: String?
        
        // If Post Date < 7 days ago, show < 7 days, else show date
        if (daysAgo.day)! <= 7 {
            postDateString = post.creationDate.timeAgoDisplay()
        } else {
            let dateDisplay = formatter.string(from: post.creationDate)
            postDateString = dateDisplay
        }
        
        let attributedText = NSMutableAttributedString(string: postDateString!, attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)])
        
        self.postDateLabel.attributedText = attributedText
        self.postDateLabel.sizeToFit()
    }
    
    func setupPostLists(){
        self.postListIds = []
        self.postListNames = []
        if self.post?.creatorListId != nil {
            for (key,value) in (self.post?.creatorListId)! {
                if value == legitListName{
                    self.postListIds.append(key)
                    self.postListNames.append(value)
                }
            }
            
            for (key,value) in (self.post?.creatorListId)! {
                if value == bookmarkListName{
                    self.postListIds.append(key)
                    self.postListNames.append(value)
                }
            }
            
            for (key,value) in (self.post?.creatorListId)! {
                if value != legitListName && value != bookmarkListName{
                    self.postListIds.append(key)
                    self.postListNames.append(value)
                }
            }
        }
        self.listCollectionHeightConstraint?.constant = (self.postListIds.count > 0) ? listCollectionHeight : 0
        self.listCollectionView.reloadData()
    }
    
    @objc func handlePictureTap(){
        guard let post = self.post else {return}
        self.delegate?.didTapPicture(post:post)
    }
    
    @objc func handleCaptionTap(){
        guard let post = self.post else {return}
        self.delegate?.didTapPicture(post:post)
    }
    
    
    @objc func handleUserTap(){
        guard let post = self.post else {return}
        self.delegate?.didTapUser(post:post)
    }
    
    func handleLocationTap(){
        guard let post = self.post else {return}
        self.delegate?.didTapLocation(post: post)
    }
    
    @objc func togglePost() {
        self.delegate?.togglePost()
        self.layoutIfNeeded()
        self.updateConstraints()
    }
}
