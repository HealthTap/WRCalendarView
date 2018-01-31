//
//  ScheduleWeekColumnHeader.swift
//  Argos
//
//  Created by wayfinder on 2017. 4. 2..
//  Copyright © 2017년 Tong. All rights reserved.
//

import UIKit
import DateToolsSwift

class WRColumnHeader: UICollectionReusableView {
    @IBOutlet weak var weekdayLbl: UILabel!
    let calendar = Calendar.current
    let dateFormatter = DateFormatter()
    
    override func awakeFromNib() {
        super.awakeFromNib()
//        dateFormatter.locale = Locale(identifier: "en_US")
    }
    
    var date: Date? {
        didSet {
            if let date = date {
                
                let weekday = calendar.component(.weekday, from: date) - 1
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    let labelText = dateFormatter.shortWeekdaySymbols[weekday].uppercased() + " " + String(calendar.component(.day, from: date))
                    weekdayLbl.text = labelText
                } else {
                    let labelText = dateFormatter.veryShortWeekdaySymbols[weekday].uppercased() + "\n" + String(calendar.component(.day, from: date))
                    weekdayLbl.numberOfLines = 0
                    weekdayLbl.text = labelText
                }
                
                weekdayLbl.textColor = UIColor(hexString: "333333")
                
                if date.isSameDay(date: Date()) {
                    backgroundColor = UIColor(hexString: "f5f8fd")
                } else {
                    backgroundColor = UIColor.white
                }
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        weekdayLbl.text = ""
    }
}
