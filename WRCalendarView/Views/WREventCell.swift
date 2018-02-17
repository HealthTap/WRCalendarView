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
        contentView.tag = -1
        updateColors()
    }
    
    var event: WREvent? {
        didSet {
            if let event = event {
                                
                if let titleColor = event.titleColor {
                    titleLabel.textColor = titleColor
                } else {
                    titleLabel.textColor = textColorHighlighted()
                }
                
                if let bgColor = event.backgroundColor {
                    contentView.backgroundColor = bgColor
                } else {
                    contentView.backgroundColor = backgroundColorHighlighted()
                }
                
                if let borderColor = event.borderColor {
                    contentView.layer.borderWidth = 1
                    contentView.layer.borderColor = borderColor.cgColor
                } else {
                    contentView.layer.borderWidth = 0
                }
                
                if let opacity = event.opacity {
                    contentView.alpha = opacity
                } else {
                    contentView.alpha = 1.0
                }
                
                if event.isCancelled {
                    let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: event.title)
                    attributeString.addAttribute(NSAttributedStringKey.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
                    titleLabel.attributedText = attributeString
                    contentView.backgroundColor = UIColor.lightGray
                } else {
                    titleLabel.text = event.title
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
