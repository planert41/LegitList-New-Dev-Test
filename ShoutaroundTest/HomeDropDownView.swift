//
//  HomeDropDownView.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 5/2/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit


protocol HomeDropDownViewDelegate {
    func dropDownSelected(string: String)
}

class HomeDropDownView: UIView, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    
    public struct Value {
        public let title: String
        public let detail: String
        public var isChecked: Bool
        
        public init(title: String, detail: String, isChecked: Bool = false) {
            self.title = title
            self.detail = detail
            self.isChecked = isChecked
        }
    }
    
    
    var cellHeaders: [String] = HomeFetchOptions
    var cellDetails: [String] = HomeFetchDetails
    
    
    public var values: [Value] = [] {
        didSet {
            self.tableView?.reloadData()
        }
    }
    
    var delegate: HomeDropDownViewDelegate?
    var viewFilter: Filter? {
        didSet{
            self.setupTitleLabel()
        }
    }
    var selectedVar: String = "" {
        didSet {
            self.tableView?.reloadData()
        }
    }
    
    var tapView = UIView()
    
    convenience init() {
        self.init(size: nil)
    }
    
    public required init(size: CGSize? = nil) {
        let screenWidth: CGFloat = UIScreen.main.bounds.width
        let screenHeight: CGFloat = UIScreen.main.bounds.height
        let frame: CGRect = CGRect(x: 0, y: 0, width: screenWidth,
                                   height: screenHeight)
        
        let width: CGFloat = screenWidth - 84
        let height: CGFloat = (30 + 3 * 80)
        var containerFrame: CGRect = CGRect(x: 0, y: 0, width: width, height: height)
        if let size = size {
            containerFrame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        }
        print("Container Frame: ",containerFrame)
        super.init(frame: frame)
        self.initialize(frame: containerFrame)
    }
    
    @objc func viewTapped(){
        print("HomeDropDownView | Outside View Tapped | Dismiss Drop Down")
        self.close()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.initialize(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initialize(frame: CGRect.zero)
    }
    
    var containerView = UIView()
    let tableViewCellIdentifier = "TableViewCell"
    fileprivate var tableView: UITableView?
    fileprivate var headerSeparator: UIView?
    public typealias Completion = ([Int]) -> Void
    let headerView = UIView()
    
    
    var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Show me close by food post by"
        label.font = UIFont.boldSystemFont(ofSize: 25)
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.rgb(red: 249, green: 249, blue: 249)
        label.layer.masksToBounds = true
        return label
    }()
    
    
    fileprivate func initialize(frame: CGRect) {
    
        
        self.containerView = UIView(frame: frame)
        self.containerView.layer.cornerRadius = 30/2
        self.containerView.clipsToBounds = true
        self.tableView = UITableView(frame: CGRect.zero)
        self.headerSeparator = UIView(frame: CGRect.zero)
        
//        self.tableView?.register(HomeDropDownCell.self,
//                                 forCellReuseIdentifier: self.tableViewCellIdentifier)
//        self.tableView?.tableFooterView = UIView()
        self.tableView?.dataSource = self
        self.tableView?.delegate = self
        
        self.setupUI()
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellHeaders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
//        let cell = tableView.dequeueReusableCell(withIdentifier: tableViewCellIdentifier, for: indexPath) as! HomeDropDownCell
        let cell = tableView.dequeueReusableCell(withIdentifier: tableViewCellIdentifier, for: indexPath) as! NewListCell

//        cell.setLabels(header: cellHeaders[indexPath.row], details: cellDetails[indexPath.row])
//        cell.selectedInd.isHidden = !(self.selectedVar == cellHeaders[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        var values = self.values
//        for i in 0..<values.count {
//            values[i].isChecked = false
//        }
//        values[indexPath.row].isChecked = true
//        self.values = values
//
        print("HomeDropDownView | TablewViewCell Select | \(cellHeaders[indexPath.row])")
        self.done()
        self.delegate?.dropDownSelected(string: cellHeaders[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func containerTap(){
        print("Container Tap")
    }
    
    let tempView = UIView()

    var dropDownTrueCenter: Bool = false {
        didSet {
            self.containerView.center = CGPoint(x: self.center.x,
                                                y: self.center.y + (dropDownTrueCenter ? 0 : self.frame.size.height))
        }
    }
    
    
    fileprivate func setupUI() {
        guard let tableView = self.tableView,
            let headerSeparator = self.headerSeparator else {
                return
        }

        tempView.backgroundColor = UIColor.clear
        tempView.isUserInteractionEnabled = true
        tempView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewTapped)))
        self.addSubview(tempView)
        tempView.frame = self.frame
        
        let containerView = self.containerView
        self.addSubview(containerView)
        containerView.backgroundColor = UIColor.blue
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(tableView)
        containerView.addSubview(headerSeparator)
//        containerView.isUserInteractionEnabled = false
//        containerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(containerTap)))
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        headerSeparator.translatesAutoresizingMaskIntoConstraints = false
        
        self.containerView.center = CGPoint(x: self.center.x,
                                            y: self.center.y + (dropDownTrueCenter ? 0 : self.frame.size.height))
        
        //titles
        containerView.addSubview(titleLabel)
        titleLabel.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: nil, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
        titleLabel.sizeToFit()
        
        setupTitleLabel()

        containerView.addSubview(headerSeparator)
        headerSeparator.anchor(top: titleLabel.bottomAnchor, left: containerView.leftAnchor, bottom: nil, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)

        containerView.addSubview(tableView)
        tableView.anchor(top: titleLabel.bottomAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
//        self.tableView?.tableHeaderView = titleLabel
        
//        containerView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    }
    
    
    func setupTitleLabel(){
        let titleString = NSMutableAttributedString()
        let fontSize = 12 as CGFloat
        let fontColor = UIColor.rgb(red: 136, green: 136, blue: 136)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        let tempString = NSAttributedString(string: "Show me ", attributes: [NSAttributedString.Key.foregroundColor: fontColor, NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: fontSize), NSAttributedString.Key.paragraphStyle: paragraph])
        titleString.append(tempString)

        var sortString = " "
        
        if let filterSort = self.viewFilter?.filterSort {
            sortString = filterSort + " "
            let tempSortString = NSAttributedString(string: sortString, attributes: [NSAttributedString.Key.foregroundColor: fontColor, NSAttributedString.Key.font: UIFont(font: .avenirNextBold, size: fontSize), NSAttributedString.Key.paragraphStyle: paragraph])
            titleString.append(tempSortString)
        }

        
        let tempString2 = NSAttributedString(string: "posts by", attributes: [NSAttributedString.Key.foregroundColor: fontColor, NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: fontSize), NSAttributedString.Key.paragraphStyle: paragraph])
        titleString.append(tempString2)
        
        self.titleLabel.attributedText = titleString
        
    }
    
    func setupTitleLabelCustom(string: String?){
        guard let string = string else {return}
        let titleString = NSMutableAttributedString()
        let fontSize = 12 as CGFloat
        let fontColor = UIColor.rgb(red: 136, green: 136, blue: 136)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        let tempString = NSAttributedString(string: string, attributes: [NSAttributedString.Key.foregroundColor: fontColor, NSAttributedString.Key.font: UIFont(font: .avenirNextRegular, size: fontSize), NSAttributedString.Key.paragraphStyle: paragraph])
        titleString.append(tempString)
        
        self.titleLabel.attributedText = titleString
        
    }
    
    internal func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    internal func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let location = touch.location(in: self)
        
        if self.point(inside: location, with: nil) {
            return false
        }
        else {
            return true
        }
    }
    
    let tap = UITapGestureRecognizer(target: self, action: #selector(close))

    open func show() {
        guard let appDelegate = UIApplication.shared.delegate else {
            assertionFailure()
            return
        }
        guard let window = appDelegate.window else {
            assertionFailure()
            return
        }
        
        window?.addSubview(self)
        window?.bringSubviewToFront(self)
        window?.endEditing(true)
//        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(close)))
//        self.bringSubviewToFront(self.containerView)
        self.containerView.center = CGPoint(x: self.center.x, y: -50)
        UIView.animate(withDuration: 0.3, delay: 0.0,
                       usingSpringWithDamping: 0.8, initialSpringVelocity: 0.6,
                       options: .allowAnimatedContent, animations: {
                        self.containerView.center = CGPoint(x: self.center.x, y: 250)
                        self.titleLabel.sizeToFit()
                        self.tableView?.reloadData()
        }) { (isFinished) in
            self.layoutIfNeeded()
            print("Displaying Drop Down")
        }
    }
    
    
    
    @objc open func done() {
        var indexes: [Int] = []
        for i in 0..<self.values.count {
            if self.values[i].isChecked {
                indexes.append(i)
            }
        }
        self.close()
    }
    
    @objc open func close() {
        guard let appDelegate = UIApplication.shared.delegate else {
            assertionFailure()
            return
        }
        guard let window = appDelegate.window else {
            assertionFailure()
            return
        }
        
        
        print("HomeDropView | Closing")
        UIView.animate(withDuration: 0.7, delay: 0.0,
                       usingSpringWithDamping: 1, initialSpringVelocity: 1.0,
                       options: .allowAnimatedContent, animations: {
                        self.containerView.center = CGPoint(x: self.center.x,
                                                             y: self.center.y + self.frame.size.height)
                        self.window?.sendSubviewToBack(self)

        }) { (isFinished) in
//            self.tempView.removeFromSuperview()
//            self.containerView.removeFromSuperview()
        }
    }
    
    
    

}
