//
//  WRCurrentTimeIndicator.swift
//
//  Created by wayfinder on 2017. 4. 6..
//  Copyright © 2017년 revo. All rights reserved.
//

import UIKit
import DateToolsSwift

class WRCurrentTimeLayoutAttributes: UICollectionViewLayoutAttributes {
    var timeLabelText: String = ""
}

class WRCurrentTimeIndicator: UICollectionReusableView {
    @IBOutlet weak var timeLbl: UILabel!

    override func apply(_ atts: UICollectionViewLayoutAttributes) {
        super.apply(atts)
        if let atts = atts as? WRCurrentTimeLayoutAttributes {
            self.timeLbl.text = atts.timeLabelText
        }
    }

//    static var dateFormatter = DateFormatter()
//
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        Self.dateFormatter.dateFormat = "h:mm a"
//
//        let timer = Timer(fireAt: Date() + 1.minutes, interval: TimeInterval(60), target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
//        RunLoop.current.add(timer, forMode: .default)
//
//        updateTimer()
//    }
//
//    @objc func updateTimer() {
//        timeLbl.text = Self.dateFormatter.string(from: Date())
//    }
}
