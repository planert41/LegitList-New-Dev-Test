//
//  CustomImageView.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/29/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import Kingfisher

var imageCache = [String: UIImage]()

class CustomImageView: UIImageView {
    
    var lastURLToLoadImage: String?
    var isListBackground = false {
        didSet {
            self.layoutSubviews()
        }
    }
    
    var clearBackground = false {
        didSet {
            if clearBackground {
                self.backgroundColor = UIColor.clear
            }
        }
    }
    
//    func loadImage(urlString: String) {
//        guard let url = URL(string: urlString) else {return}
//        var urlRequest = URLRequest(url: url)
//        self.cancelImageRequestOperation()
//        self.setImageWith(urlRequest, placeholderImage: nil, success: { (request, response, image) in
//            print("Loaded Image ", request)
//            let photoImage = image?.resizeImageWith(newSize: defaultPhotoResize)
//            self.image = photoImage
//            imageCache[url.absoluteString] = photoImage
//            
//        }, failure: { (request, response, error) in
//            if let error = error {
//                print("Error fetching photo from URL: \(error)")
//            }
//        })
//    }
    
    var backgroundImage = UIImageView()
    
    override func layoutSubviews() {
        self.backgroundColor = UIColor.init(red: 204, green: 204, blue: 204, alpha: 1)
        self.backgroundColor = UIColor.lightGray

        let img = isListBackground ? #imageLiteral(resourceName: "list_color_icon") : #imageLiteral(resourceName: "camera_default")
//        let backImage = #imageLiteral(resourceName: "camera_default").withRenderingMode(.alwaysTemplate)
        let backImage = img.withRenderingMode(.alwaysTemplate)

        let imageWidth = self.frame.width / 3
        backgroundImage = UIImageView(frame: CGRect(x: 0, y: 0, width: imageWidth, height: imageWidth))
        backgroundImage.image = backImage
        backgroundImage.contentMode = .scaleAspectFit
        backgroundImage.tintColor = UIColor.ianGrayColor()
        backgroundImage.backgroundColor = UIColor.clear
        backgroundImage.isHidden = true


        if !self.backgroundImage.isDescendant(of: self) {
            self.addSubview(backgroundImage)
            backgroundImage.center = self.center
        }
        
//        backgroundImage.isHidden = false
    }


    
    func loadImage(urlString: String?){
        // SET DEFAULTS
        
        guard let urlString = urlString else {
            self.backgroundImage.isHidden = false
            return
        }
        
        guard let url = URL(string: urlString) else {
            self.backgroundImage.isHidden = false
            return}
//        self.kf.setImage(with: url)
//        self.kf.indicatorType = .
//        self.kf.setImage(with: url, options: [.transition(.fade(0.2))])
//        backgroundImage.isHidden = false
        self.backgroundColor = UIColor.lightGray
        self.backgroundImage.isHidden = true

        
        self.kf.setImage(with: url, options: [.transition(.fade(0.2))]) { result in
            // `result` is either a `.success(RetrieveImageResult)` or a `.failure(KingfisherError)`
            switch result {
            case .success(let value):
                self.backgroundImage.isHidden = true
//                break
                // The image was set to image view:
//                print(value.image)

                // From where the image was retrieved:
                // - .none - Just downloaded.
                // - .memory - Got from memory cache.
                // - .disk - Got from disk cache.
//                print(value.cacheType)

                // The source object which contains information like `url`.
//                print(value.source)

            case .failure(let error):
//                self.backgroundImage.isHidden = false
                break
//                self.image = backImage
//                self.backgroundImage.isHidden = false
//                self.tintColor = UIColor.ianGrayColor()
//                print(error) // The error happens
            }
        }
    }
        
        
//
//
//        lastURLToLoadImage = urlString
//
//        self.image = nil
//
//        if let cachedImage = imageCache[urlString] {
//            if cachedImage != nil {
//                self.image = cachedImage
//                return
//            }
//        }
//
//        if let cachedImage = imageCache[urlString] {
//            self.image = cachedImage
//            return
//        }
        
//
//        URLSession.shared.dataTask(with: url) { (data, response, err) in
//            if let err = err {
//                print("Failed to fetch post image:", err)
//                return
//            }
//
//            if url.absoluteString != self.lastURLToLoadImage {
//                return
//            }
//
//            guard let imageData = data else {
//                return}
////            let photoImage = UIImage(data: imageData)?.resizeImageWith(newSize: defaultPhotoResize)
//
//            let photoImage = UIImage(data: imageData)?.resizeVI(newSize: defaultPhotoResize)
////            let photoImage = UIImage(data: imageData)
//
////            var origimg: NSData = NSData(data: imageData)
////            print("orig IMG: ",Double(origimg.length)/1024.0)
////
////                        var img90: NSData = NSData(data: UIImageJPEGRepresentation(UIImage(data: imageData)?.resizeImageWith(newSize: defaultPhotoResize)))
////                        print("90 IMG: ",Double(img90.length)/1024.0)
////
////                        var img80: NSData = NSData(data: UIImage(data: UIImageJPEGRepresentation(imageData)?.resizeVI(newSize: defaultPhotoResize)))
////                        print("80 IMG: ",Double(img80.length)/1024.0)
//
//
//            imageCache[url.absoluteString] = photoImage
//
//            DispatchQueue.main.async {
//                self.image = photoImage
//            }
//
//            }.resume()
//    }

    
}
