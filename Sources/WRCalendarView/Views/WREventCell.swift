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
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabelLeadingConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 5
        layer.shadowOpacity = 0
        contentView.tag = -1
        updateColors()
    }
    
    var event: WREventType? {
        didSet {
            if let event = event {

                if let attributedTitle = event.attributedTitle {
                    titleLabel.attributedText = attributedTitle
                } else {
                    titleLabel.text = event.title
                }

                if let attributedSubTitle = event.attributedSubtitle {
                    subtitleLabel.attributedText = attributedSubTitle
                } else {
                    subtitleLabel.text = event.subtitle
                }

                titleLabel.textColor = event.titleColor ?? textColorHighlighted()
                subtitleLabel.textColor = event.subtitleColor ?? textColorHighlighted()

                titleLabel.numberOfLines = event.wrapText ? 0 : 1
                subtitleLabel.numberOfLines = 0 // event.wrapText ? 0 : 1

                if let image = event.image {
                    imageView.image = image
                    imageView.isHidden = false
                    titleLabelLeadingConstraint.constant = 24
                } else {
                    imageView.image = nil
                    imageView.isHidden = true
                    titleLabelLeadingConstraint.constant = 4
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

                contentView.layer.cornerRadius = event.cornerRadius
                contentView.layer.masksToBounds = true
                backgroundColor = UIColor.clear
                layer.zPosition = {
                    switch event.zPosition {
                    case .normal:
                        return 0
                    case .foreground:
                        return 1
                    case .background:
                        return -1
                    }
                }()
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
