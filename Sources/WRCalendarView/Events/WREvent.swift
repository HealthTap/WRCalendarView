//
//  WREvent.swift
//  Pods
//
//  Created by wayfinder on 2017. 4. 29..
//
//

import UIKit
import DateToolsSwift

// GP: I convered `WREvent` to a protocol `WREventType` in Jan 2021, but left the original class for backwards compatibility.

public protocol WREventType {
    var id: String { get }
    var startDate: Date { get }
    var endDate: Date { get  }

    // Using these will override the title, color, etc. properties below
    var attributedTitle: NSAttributedString? { get }
    var attributedSubtitle: NSAttributedString? { get }

    // These can be overriden by the attributedTitle type properties above
    var title: String { get }
    var titleColor: UIColor? { get }
    var subtitle: String? { get }
    var subtitleColor: UIColor? { get }

    // Other appearance properties
    var wrapText: Bool { get } // If true, multi-line labels will be used for both the title & subtitle.
    var backgroundColor: UIColor? { get }
    var borderColor: UIColor? { get }
    var opacity: CGFloat? { get }
    var canDrag: Bool { get }
    var cornerRadius: CGFloat { get }
}

public extension WREventType {
    var attributedTitle: NSAttributedString? { nil }
    var attributedSubtitle: NSAttributedString? { nil }
    var title: String { "" }
    var titleColor: UIColor? { nil }
    var subtitle: String? { nil }
    var subtitleColor: UIColor? { nil }

    var wrapText: Bool { false }
    var backgroundColor: UIColor? { nil }
    var borderColor: UIColor? { nil }
    var opacity: CGFloat? { nil }
    var canDrag: Bool { false }
    var cornerRadius: CGFloat { 4 }
}

@available(*, deprecated, message: "WREvent has been deprecated in favour of WREventType.")
open class WREvent: TimePeriod, WREventType {
    open var title: String = ""
    open var attributedTitle: NSAttributedString? = nil // Overrides title if present.
    open var attributedSubtitle: NSAttributedString? = nil
    open var eventId: String = ""
    open var titleColor: UIColor?
    open var backgroundColor: UIColor?
    open var borderColor: UIColor?
    open var opacity: CGFloat?
    open var canDrag: Bool = false
    open var isCancelled: Bool = false // Unused
    open var wrapText: Bool { true }  // For backwards compatibility
    open var subtitle: String?
    open var subtitleColor: UIColor?

    open var id: String { eventId }
    open var startDate: Date { beginning! } // The old
    open var endDate: Date { end!  }

    open class func make(date:Date, chunk: TimeChunk, title: String) -> WREvent {
        let event = WREvent(beginning: date, chunk: chunk)
        event.title = title

        return event
    }
}
