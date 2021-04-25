//
//  LocationHoursViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 5/10/19.
//  Copyright © 2019 Wei Zou Ang. All rights reserved.
//

import UIKit
import SwiftyJSON

class LocationHoursViewController: UIViewController {

    let stackView = UIStackView()
    
    lazy var hoursTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "HOURS"
        label.font = UIFont(name: "Poppins-Regular", size: 30)
        label.backgroundColor = UIColor.white
        label.textColor = UIColor.gray
        label.layer.borderWidth = 0
        label.layer.cornerRadius = 0
        label.layer.masksToBounds = true
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let cancelButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "cancel_red").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(done), for: .touchUpInside)
        return button
    }()
    
    lazy var doneLabel: UILabel = {
        let label = UILabel()
        label.text = "DONE"
        label.font = UIFont(name: "Poppins-Bold", size: 15)
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.ianLegitColor()
        label.layer.borderWidth = 0
        label.layer.cornerRadius = 0
        label.layer.masksToBounds = true
        label.isUserInteractionEnabled = true
        label.textAlignment = .center
        return label
    }()
    
    var hours: [JSON]?
    var hourLabels: [UIView]?
    let titleContainer = UIView()
    let hoursView = UIView()

    func setupViews(){
        self.view.addSubview(hoursView)
        hoursView.anchor(top: view.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 150, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 280, height: 0)
        hoursView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300).isActive = true
        hoursView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        hoursView.backgroundColor = UIColor.white
        
        self.view.addSubview(titleContainer)
        titleContainer.anchor(top: hoursView.topAnchor, left: hoursView.leftAnchor, bottom: nil, right: hoursView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        
        self.view.addSubview(hoursTitleLabel)
        hoursTitleLabel.anchor(top: nil, left: titleContainer.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        hoursTitleLabel.centerYAnchor.constraint(equalTo: titleContainer.centerYAnchor).isActive = true
        
        self.view.addSubview(cancelButton)
        cancelButton.anchor(top: nil, left: nil, bottom: nil, right: titleContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 20, width: 30, height: 30)
        cancelButton.centerYAnchor.constraint(equalTo: titleContainer.centerYAnchor).isActive = true
        
        self.view.addSubview(doneLabel)
        doneLabel.anchor(top: nil, left: hoursView.leftAnchor, bottom: hoursView.bottomAnchor, right: hoursView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
        doneLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(done)))
        
        setupHourLabels()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.rgb(red: 136, green: 136, blue: 136)
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(done)))
        // Do any additional setup after loading the view.
    }
    

    @objc func done(){
        self.dismiss(animated: true) {
        }
    }
    
    func setupHourLabels() {
        guard let hours = self.hours else {return}
        self.hourLabels = []
        
        let today = Date()
        let myCalendar = Calendar(identifier: .gregorian)
        let weekDay = myCalendar.component(.weekday, from: today)
        let todayIndex = weekDay == 1 ? 0 : weekDay - 1
        let googDayIndex = todayIndex == 0 ? 6 : todayIndex - 1
        
        for (index, hour) in hours.enumerated() {
            print(hour)
            let hourString = String(describing: hour)
            let hourStringSplit = hourString.components(separatedBy: ":")
            
            let day = hourStringSplit[0]
            let timeString = String(hourString.suffix(day.count - 1))
            
            let hourView = UIView()
            var dayLabel = UILabel()
            var timeLabel = UILabel()

            hourView.addSubview(dayLabel)
            dayLabel.anchor(top: hourView.topAnchor, left: hourView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 30, paddingBottom: 0, paddingRight: 0, width: 100, height: 20)
            dayLabel.bottomAnchor.constraint(lessThanOrEqualTo: hourView.bottomAnchor).isActive = true
            
            hourView.addSubview(timeLabel)
            timeLabel.anchor(top: hourView.topAnchor, left: dayLabel.rightAnchor, bottom: hourView.bottomAnchor, right: hourView.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            
            let tempDayString = NSMutableAttributedString(string: day, attributes: [NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 16), NSAttributedString.Key.foregroundColor: index == googDayIndex ? UIColor.ianLegitColor() : UIColor.gray])
            dayLabel.attributedText = tempDayString
            dayLabel.sizeToFit()
            
            let tempHourString = NSMutableAttributedString(string: timeString, attributes: [NSAttributedString.Key.font: UIFont(name: "Poppins-Regular", size: 014), NSAttributedString.Key.foregroundColor: index == googDayIndex ? UIColor.ianLegitColor() : UIColor.gray])
            timeLabel.attributedText = tempHourString
            timeLabel.sizeToFit()
            
            self.hourLabels?.append(hourView)
        }
        
        if (self.hourLabels?.count) ?? 0 > 0 {
            guard let hourLabels = self.hourLabels else {return}
            print("Displaying \(hourLabels.count) Day Hours")
            let dayStackView = UIStackView(arrangedSubviews: hourLabels)
            dayStackView.distribution = .fillEqually
            dayStackView.axis = .vertical
            
            self.view.addSubview(dayStackView)
            dayStackView.anchor(top: titleContainer.bottomAnchor, left: hoursView.leftAnchor, bottom: doneLabel.topAnchor, right: hoursView.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 0, height: 0)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
