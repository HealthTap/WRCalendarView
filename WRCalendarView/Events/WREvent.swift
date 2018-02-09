//
//  WREvent.swift
//  Pods
//
//  Created by wayfinder on 2017. 4. 29..
//
//

import UIKit
import DateToolsSwift

open class WREvent: TimePeriod {
    open var title: String = ""
    open var eventId: String = ""
    open var titleColor: UIColor?
    open var backgroundColor: UIColor?
    open var borderColor: UIColor?
    open var opacity: CGFloat?
    open var canDrag: Bool = false

    open class func make(date:Date, chunk: TimeChunk, title: String) -> WREvent {
        let event = WREvent(beginning: date, chunk: chunk)
        event.title = title
        
        return event
    }
}
