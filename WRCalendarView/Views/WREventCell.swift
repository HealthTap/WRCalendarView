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
                if let titleColor = event.titleColor {
                    titleLabel.textColor = titleColor
                }
                if let bgColor = event.backgroundColor {
                    contentView.backgroundColor = bgColor
                }
                if let borderColor = event.borderColor {
                    contentView.layer.borderWidth = 1
                    contentView.layer.borderColor = borderColor.cgColor
                }

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
