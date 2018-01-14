//
//  WREventCell.swift
//  Pods
//
//  Created by wayfinder on 2017. 4. 30..
//
//

import UIKit

class WREventCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 5
        layer.shadowOpacity = 0
        
        updateColors()
    }
    
    var event: WREvent? {
        didSet {
            if let event = event {
                titleLabel.text = event.title
            }
        }
    }
    
    func updateColors() {
        contentView.backgroundColor = backgroundColorHighlighted()
        titleLabel.textColor = textColorHighlighted()
    }

    func backgroundColorHighlighted() -> UIColor {
        return UIColor(hexString: "4cd864")!
    }

    func textColorHighlighted() -> UIColor {
        return UIColor.white
    }
}
