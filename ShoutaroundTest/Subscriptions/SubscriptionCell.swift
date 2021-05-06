//
//  SubscriptionCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 5/2/21.
//  Copyright © 2021 Wei Zou Ang. All rights reserved.
//

import UIKit

protocol SubscriptionCellDelegate {
    func extTapUserUid(uid: String)
    func didTapPremiumSub()
}


class SubscriptionCell: UITableViewCell {
    var delegate: SubscriptionCellDelegate?

    var displayUserId: String?
    var displayUser: User? {
        didSet {
            setupCell()
        }
    }
    
    var isPremiumAnnualSub = false {
        didSet {
            setupCell()
        }
    }
    
    var isPremiumMonthlySub = false {
        didSet {
            setupCell()
        }
    }
    
    var premiumCell = false {
        didSet {
            setupCell()
        }
    }
    
    func setupPremiumCell() {
        let img = #imageLiteral(resourceName: "full_star_yellow").withRenderingMode(.alwaysOriginal)
        profileImageView.image = img
        profileImageView.layer.borderWidth = 0
        profileImageView.layer.borderColor = UIColor.lightGray.cgColor
//        profileImageView.backgroundColor = (isPremiumAnnualSub || isPremiumMonthlySub) ? UIColor.ianLegitColor() : UIColor.lightGray
        profileImageView.tintColor = UIColor.ianLegitColor()

        var headerText = "Premium "
        if isPremiumAnnualSub {
            headerText += "Annual Subscription"
        } else if isPremiumMonthlySub {
            headerText += "Monthly Subscription"
        }
        
        headerLabel.text = headerText
        headerLabel.sizeToFit()
        subButton.isHidden = !(isPremiumAnnualSub || isPremiumMonthlySub)
        subButton.isUserInteractionEnabled = !subButton.isHidden
    }
    
    func setupUserSubCell() {
        guard let user = displayUser else {return}
        profileImageView.loadImage(urlString: (user.profileImageUrl))
        headerLabel.text = user.username
        headerLabel.sizeToFit()
        subButton.isHidden = true
    }
    
    func clearCell() {
        profileImageView.image = UIImage()
        headerLabel.text = ""
        subHeaderLabel.text = ""
        subButton.isHidden = true
    }
    
    func setupCell() {
        if premiumCell || isPremiumAnnualSub || isPremiumMonthlySub {
            setupPremiumCell()
        } else if displayUser != nil {
            setupUserSubCell()
        } else {
            clearCell()
        }
        setupExpiryDate()
    }
    
    var expiryDate: Date? {
        didSet {
            setupExpiryDate()
        }
    }
    
    func setupExpiryDate() {
        if expiryDate == nil {
            self.subHeaderLabel.text = ""
        } else {
            guard let expiryDate = expiryDate else {return}
            let formatter = DateFormatter()
            let calendar = NSCalendar.current
            formatter.dateFormat = "MMM dd yyyy"
            let dateDisplay = formatter.string(from: expiryDate)
            
            subHeaderLabel.text = "Expires: \(dateDisplay)"
            subHeaderLabel.sizeToFit()
        }
    }
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .white
//        iv.contentMode = .scaleAspectFill
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.clearBackground = true
        return iv
    }()
    
    let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.adjustsFontSizeToFitWidth = true
        label.textColor = .ianBlackColor()
//        label.numberOfLines = 0
        return label
    }()
    
    let subButton: UIButton = {
        let button = UIButton()
//        let listIcon = #imageLiteral(resourceName: "lists").withRenderingMode(.alwaysTemplate)
//        button.setImage(listIcon, for: .normal)
        button.backgroundColor = UIColor.mainBlue()
        button.setTitle("Subscribe", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 13)
        button.isUserInteractionEnabled = false
        button.tintColor = UIColor.ianBlackColor()
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
        return button
    }()
    
    let subHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "Dates"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor.gray
//        label.adjustsFontSizeToFitWidth = true
//        label.numberOfLines = 0
        return label
    }()
    
    let cellView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(cellView)
        cellView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        cellView.backgroundColor = UIColor.lightBackgroundGrayColor()
        cellView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapCell)))
        
        cellView.addSubview(profileImageView)
        profileImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 50, height: 50)
//        profileImageView.widthAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapUser)))
        profileImageView.layer.cornerRadius = 50 / 2
        profileImageView.layer.masksToBounds = true
        profileImageView.clipsToBounds = true
        
        cellView.addSubview(headerLabel)
        headerLabel.anchor(top: profileImageView.topAnchor, left: profileImageView.rightAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 0, width: 0, height: 0)
        
        cellView.addSubview(subHeaderLabel)
        subHeaderLabel.anchor(top: headerLabel.bottomAnchor, left: headerLabel.leftAnchor, bottom: nil, right: nil, paddingTop: 4, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 0, height: 0)
        
        cellView.addSubview(subButton)
        subButton.anchor(top: nil, left: nil, bottom: cellView.bottomAnchor, right: cellView.rightAnchor, paddingTop: 20, paddingLeft: 0, paddingBottom: 20, paddingRight: 10, width: 100, height: 0)
        subButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        subButton.isHidden = true
        subButton.addTarget(self, action: #selector(didTapSubButton), for: .touchUpInside)

    }
    
    @objc func didTapSubButton() {
        self.delegate?.didTapPremiumSub()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func didTapCell() {
        
    }
    
    @objc func didTapUser() {
        if let uid = self.displayUserId {
            self.delegate?.extTapUserUid(uid: uid)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.displayUserId = nil
        self.displayUser = nil
        self.premiumCell = false
        self.isPremiumMonthlySub = false
        self.isPremiumAnnualSub = false
        setupCell()
    }

}
