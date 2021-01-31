//
//  WRWeekViewFlowLayout.swift
//  Pods
//
//  Created by wayfinder on 2017. 4. 26..
//
//

import UIKit
import DateToolsSwift

protocol WRWeekViewFlowLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, layout: WRWeekViewFlowLayout, dayForSection section: Int) -> Date
    func collectionView(_ collectionView: UICollectionView, layout: WRWeekViewFlowLayout, startTimeForItemAtIndexPath indexPath: IndexPath) -> Date
    func collectionView(_ collectionView: UICollectionView, layout: WRWeekViewFlowLayout, endTimeForItemAtIndexPath indexPath: IndexPath) -> Date
}

class WRWeekViewFlowLayout: UICollectionViewFlowLayout {
    typealias AttDic = Dictionary<IndexPath, UICollectionViewLayoutAttributes>

    // UI params
    var showColumnHeader: Bool
    var currentTimeViewOffset: CGFloat!
    var hourHeight: CGFloat!
    var rowHeaderWidth: CGFloat!
    var columnHeaderHeight: CGFloat!
    internal private(set) var sectionWidth: CGFloat!
    var hourGridDivisionValue: HourGridDivision!

    var minuteHeight: CGFloat { return hourHeight / 60 }

    let displayHeaderBackgroundAtOrigin = true
    let gridThickness: CGFloat = UIScreen.main.scale == 2 ? 0.5 : 1.0
    let minOverlayZ = 1000  // Allows for 900 items in a section without z overlap issues
    let minCellZ = 100      // Allows for 100 items in a section's background
    let minBackgroundZ = 0

    var maxSectionHeight: CGFloat { return columnHeaderHeight + hourHeight * 24 }
    var currentTimeIndicatorSize: CGSize { return CGSize(width: rowHeaderWidth, height: 10.0) }
    let sectionMargin = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
    let cellMargin = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    let contentsMargin = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    var delegate: WRWeekViewFlowLayoutDelegate?
    var currentTimeComponents: DateComponents {
        if (cachedCurrentTimeComponents[0] != nil) {
            return cachedCurrentTimeComponents[0]!
        }

        cachedCurrentTimeComponents[0] = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        return cachedCurrentTimeComponents[0]!
    }

    var minuteTimer: Timer?

    var currentPageStartDate: Date?
    var currentPageInterval: Int?

    // Attributes
    var cachedDayDateComponents = Dictionary<Int, DateComponents>()
    var cachedCurrentTimeComponents = Dictionary<Int, DateComponents>()
    var cachedStartTimeDateComponents = Dictionary<IndexPath, DateComponents>()
    var cachedEndTimeDateComponents = Dictionary<IndexPath, DateComponents>()
    var registeredDecorationClasses = Dictionary<String, AnyClass>()
    var needsToPopulateAttributesForAllSections = true

    var allAttributes = Array<UICollectionViewLayoutAttributes>()
    var itemAttributes = AttDic()
    var columnHeaderAttributes = AttDic()
    var columnHeaderBackgroundAttributes = AttDic()
    var rowHeaderAttributes = AttDic()
    var rowHeaderBackgroundAttributes = AttDic()
    var verticalGridlineAttributes = AttDic()
    var horizontalGridlineAttributes = AttDic()
    var todayBackgroundAttributes = AttDic()
    var cornerHeaderAttributes = AttDic()
    var currentTimeIndicatorAttributes = AttDic()
    var currentTimeHorizontalGridlineAttributes = AttDic()

    var calendar: Calendar

    // MARK:- Life cycle
    init(showColumnHeader flag: Bool, calendar: Calendar) {
        self.showColumnHeader = flag
        self.calendar = calendar
        super.init()
        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    deinit {
        minuteTimer?.invalidate()
    }

    func initialize() {
        hourHeight = 100
        rowHeaderWidth = 60
        columnHeaderHeight = 40
        currentTimeViewOffset = rowHeaderWidth - columnHeaderHeight
        if !showColumnHeader {
            currentTimeViewOffset = currentTimeViewOffset + columnHeaderHeight
            columnHeaderHeight = 0
        }

        hourGridDivisionValue = .minutes_15

        initializeMinuteTick()
    }

    func initializeMinuteTick() {
        var currentDateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        currentDateComponents.second = 0
        let startDate = calendar.date(from: currentDateComponents) ?? Date()
        minuteTimer = Timer(fireAt: startDate, interval: TimeInterval(60), target: self, selector: #selector(configureCurrentTimeIndicator), userInfo: nil, repeats: true)
        RunLoop.current.add(minuteTimer!, forMode: .default)
    }

    @objc func configureCurrentTimeIndicator() {
        cachedCurrentTimeComponents.removeAll()
        invalidateLayout()
    }

    func setColumnWidth(_ width: CGFloat) {
        self.sectionWidth = width//floor(width - sectionMargin.left - sectionMargin.right)
    }

    // MARK: - UICollectionViewLayout
    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        invalidateLayoutCache()
        prepare()
        super.prepare(forCollectionViewUpdates: updateItems)
    }

    override func finalizeCollectionViewUpdates() {
        for subview in collectionView!.subviews {
            for decorationViewClass in registeredDecorationClasses.values {
                if subview.isKind(of: decorationViewClass) {
                    subview.removeFromSuperview()
                }
            }
        }
        collectionView!.reloadData()
    }

    override func register(_ viewClass: AnyClass?, forDecorationViewOfKind elementKind: String) {
        super.register(viewClass, forDecorationViewOfKind: elementKind)
        registeredDecorationClasses[elementKind] = viewClass
    }

    override func prepare() {
        super.prepare()

        if needsToPopulateAttributesForAllSections {
            prepareHorizontalTileSectionLayoutForSections(NSIndexSet.init(indexesIn:
                NSRange.init(location: 0, length: collectionView!.numberOfSections)))
            needsToPopulateAttributesForAllSections = false
        }

        let needsToPopulateAllAttributes = (allAttributes.count == 0)

        if needsToPopulateAllAttributes {
            allAttributes.append(contentsOf: columnHeaderAttributes.values)
            allAttributes.append(contentsOf: columnHeaderBackgroundAttributes.values)
            allAttributes.append(contentsOf: rowHeaderAttributes.values)
            allAttributes.append(contentsOf: rowHeaderBackgroundAttributes.values)
            allAttributes.append(contentsOf: verticalGridlineAttributes.values)
            allAttributes.append(contentsOf: horizontalGridlineAttributes.values)
            allAttributes.append(contentsOf: todayBackgroundAttributes.values)
            allAttributes.append(contentsOf: cornerHeaderAttributes.values)
            allAttributes.append(contentsOf: currentTimeHorizontalGridlineAttributes.values)
            allAttributes.append(contentsOf: currentTimeIndicatorAttributes.values)
            allAttributes.append(contentsOf: itemAttributes.values)
        }
    }

    func prepareHorizontalTileSectionLayoutForSections(_ sectionIndexes: NSIndexSet) {
        guard collectionView!.numberOfSections != 0 else { return }

        var attributes =  UICollectionViewLayoutAttributes()

        let needsToPopulateItemAttributes = (itemAttributes.count == 0)
        let needsToPopulateVerticalGridlineAttributes = (verticalGridlineAttributes.count == 0)

//        let sectionWidth = sectionMargin.left + self.sectionWidth + sectionMargin.right
        let sectionHeight = nearbyint(hourHeight * 24 + sectionMargin.top + sectionMargin.bottom)
        let calendarGridMinX = rowHeaderWidth + contentsMargin.left
        let calendarGridMinY = columnHeaderHeight + contentsMargin.top
        let calendarGridWidth = collectionViewContentSize.width - rowHeaderWidth - contentsMargin.left - contentsMargin.right

        let calendarContentMinX = rowHeaderWidth + contentsMargin.left + sectionMargin.left
        let calendarContentMinY = columnHeaderHeight + contentsMargin.top + sectionMargin.top
        // row header
        let rowHeaderMinX = fmax(collectionView!.contentOffset.x, 0)

        // row Header Background
        (attributes, rowHeaderBackgroundAttributes) =
            layoutAttributesForDecorationView(at: IndexPath(row: 0, section: 0),
                                              ofKind: DecorationViewKinds.rowHeaderBackground,
                                              withItemCache: rowHeaderBackgroundAttributes)
        attributes.frame = CGRect(x: rowHeaderMinX, y: collectionView!.contentOffset.y,
                                  width: rowHeaderWidth, height: collectionView!.frame.height)
        attributes.zIndex = zIndexForElementKind(DecorationViewKinds.rowHeaderBackground)

        //current time indicator
        (attributes, currentTimeIndicatorAttributes) =
            layoutAttributesForDecorationView(at: IndexPath(row: 0, section: 0),
                                              ofKind: DecorationViewKinds.currentTimeIndicator,
                                              withItemCache: currentTimeIndicatorAttributes)
        let timeY = calendarContentMinX + nearbyint(CGFloat(currentTimeComponents.hour!) * hourHeight
            + CGFloat(currentTimeComponents.minute!) * minuteHeight)

        let currentTimeIndicatorMinY: CGFloat = timeY - nearbyint(currentTimeIndicatorSize.height / 2.0)
        let currentTimeIndicatorMinX: CGFloat = (max(collectionView!.contentOffset.x, 0.0) + (rowHeaderWidth - currentTimeIndicatorSize.width))
        attributes.frame = CGRect(origin: CGPoint(x: currentTimeIndicatorMinX, y: currentTimeIndicatorMinY-currentTimeViewOffset),
                                                      size: currentTimeIndicatorSize)
        attributes.zIndex = zIndexForElementKind(DecorationViewKinds.currentTimeIndicator)

        //current time gridline
        (attributes, currentTimeHorizontalGridlineAttributes) =
            layoutAttributesForDecorationView(at: IndexPath(row: 0, section: 0),
                                              ofKind: DecorationViewKinds.currentTimeGridline,
                                              withItemCache: currentTimeHorizontalGridlineAttributes)
        let currentTimeHorizontalGridlineMinY = timeY - nearbyint(gridThickness / 2.0)
        let currentTimeHorizontalGridlineXOffset = calendarGridMinX + sectionMargin.left
        let currentTimeHorizontalGridlineMinX = max(currentTimeHorizontalGridlineXOffset, collectionView!.contentOffset.x + currentTimeHorizontalGridlineXOffset)
        let currentTimehorizontalGridlineWidth = min(calendarGridWidth, collectionView!.frame.size.width)
        attributes.frame = CGRect(x: currentTimeHorizontalGridlineMinX, y: currentTimeHorizontalGridlineMinY-currentTimeViewOffset,
                                  width: currentTimehorizontalGridlineWidth, height: gridThickness);
        attributes.zIndex = zIndexForElementKind(DecorationViewKinds.currentTimeGridline)

        // column header background
        (attributes, columnHeaderBackgroundAttributes) =
            layoutAttributesForDecorationView(at: IndexPath(row: 0, section: 0),
                                              ofKind: DecorationViewKinds.columnHeaderBackground,
                                              withItemCache: columnHeaderBackgroundAttributes)
        attributes.frame = CGRect(origin: collectionView!.contentOffset,
                                  size: CGSize(width: collectionView!.frame.width,
                                               height: columnHeaderHeight + (collectionView!.contentOffset.y < 0 ? abs(collectionView!.contentOffset.y) : 0 )))
        attributes.zIndex = zIndexForElementKind(DecorationViewKinds.columnHeaderBackground)

        // corner
        (attributes, cornerHeaderAttributes) =
            layoutAttributesForDecorationView(at: IndexPath(row: 0, section: 0),
                                              ofKind: DecorationViewKinds.cornerHeader,
                                              withItemCache: cornerHeaderAttributes)
        attributes.frame = CGRect(origin: collectionView!.contentOffset,
                                  size: CGSize.init(width: rowHeaderWidth, height: columnHeaderHeight-5))
        attributes.zIndex = zIndexForElementKind(DecorationViewKinds.cornerHeader)

        // row header
        for rowHeaderIndex in 0...23 {
            (attributes, rowHeaderAttributes) =
                layoutAttributesForSupplemantaryView(at: IndexPath(item: rowHeaderIndex, section: 0),
                                                     ofKind: SupplementaryViewKinds.rowHeader,
                                                     withItemCache: rowHeaderAttributes)
            let rowHeaderMinY = calendarContentMinY + hourHeight * CGFloat(rowHeaderIndex) - nearbyint(hourHeight / 2.0)
            attributes.frame = CGRect(x: rowHeaderMinX,
                                      y: rowHeaderMinY,
                                      width: rowHeaderWidth,
                                      height: hourHeight)
            attributes.zIndex = zIndexForElementKind(SupplementaryViewKinds.rowHeader)
        }

        // Column Header
        let columnHeaderMinY = fmax(collectionView!.contentOffset.y, 0.0)

        sectionIndexes.enumerate(_:) { (section, stop) in
            let sectionMinX = calendarContentMinX + sectionWidth * CGFloat(section)

            (attributes, columnHeaderAttributes) =
                layoutAttributesForSupplemantaryView(at: IndexPath(item: 0, section: section),
                                                     ofKind: SupplementaryViewKinds.columnHeader,
                                                     withItemCache: columnHeaderAttributes)
            attributes.frame = CGRect(x: sectionMinX, y: columnHeaderMinY,
                                      width: sectionWidth, height: columnHeaderHeight)
            attributes.zIndex = zIndexForElementKind(SupplementaryViewKinds.columnHeader)

            if needsToPopulateVerticalGridlineAttributes {
                layoutVerticalGridLinesAttributes(section: section, sectionX: sectionMinX, calendarGridMinY: calendarGridMinY, sectionHeight: sectionHeight)
                layoutTodayBackgroundAttributes(section: section, sectionX: sectionMinX, calendarStartY: calendarGridMinY, sectionHeight: sectionHeight)
            }

            if needsToPopulateItemAttributes {
                layoutItemsAttributes(section: section, sectionX: sectionMinX, calendarStartY: calendarGridMinY)
            }
        }
        layoutHorizontalGridLinesAttributes(calendarStartX: calendarContentMinX, calendarStartY: calendarContentMinY)
    }

    // MARK: - Layout Attributes
    func layoutItemsAttributes(section: Int, sectionX: CGFloat, calendarStartY: CGFloat) {
        var attributes =  UICollectionViewLayoutAttributes()
        var sectionItemAttributes = [UICollectionViewLayoutAttributes]()

        for item in 0..<collectionView!.numberOfItems(inSection: section) {
            let itemIndexPath = IndexPath(item: item, section: section)
            (attributes, itemAttributes) =
                layoutAttributesForCell(at: itemIndexPath, withItemCache: itemAttributes)

            let itemStartTime = startTimeForIndexPath(itemIndexPath)
            let itemEndTime = endTimeForIndexPath(itemIndexPath)
            let startHourY = CGFloat(itemStartTime.hour!) * hourHeight
            let startMinuteY = CGFloat(itemStartTime.minute!) * minuteHeight

            var endHourY: CGFloat
            let endMinuteY = CGFloat(itemEndTime.minute!) * minuteHeight

            if itemEndTime.day! != itemStartTime.day! {
                endHourY = CGFloat(calendar.maximumRange(of: .hour)!.count) * hourHeight + CGFloat(itemEndTime.hour!) * hourHeight
            } else {
                endHourY = CGFloat(itemEndTime.hour!) * hourHeight
            }

            let itemMinX = nearbyint(sectionX + cellMargin.left + sectionMargin.left)
            let itemMinY = nearbyint(startHourY + startMinuteY + calendarStartY + cellMargin.top)
            let itemMaxX = nearbyint(itemMinX + (sectionWidth - sectionMargin.right - (cellMargin.left + cellMargin.right)))
            let itemMaxY = nearbyint(endHourY + endMinuteY + calendarStartY - cellMargin.bottom)

            attributes.frame = CGRect(x: itemMinX, y: itemMinY,
                                      width: itemMaxX - itemMinX,
                                      height: itemMaxY - itemMinY)
            attributes.zIndex = zIndexForElementKind(SupplementaryViewKinds.defaultCell)

            sectionItemAttributes.append(attributes)
        }

        adjustItemsForOverlap(sectionItemAttributes, inSection: section, sectionMinX: sectionX)
    }

    func layoutTodayBackgroundAttributes(section: Int, sectionX: CGFloat, calendarStartY: CGFloat, sectionHeight: CGFloat) {
        let currentComponents = daysForSection(section)

        if (currentTimeComponents.year == currentComponents.year &&
            currentTimeComponents.month == currentComponents.month &&
            currentTimeComponents.day == currentComponents.day) {
            var attributes: UICollectionViewLayoutAttributes
            (attributes, todayBackgroundAttributes) =
                layoutAttributesForDecorationView(at: IndexPath(item: 0, section: 0),
                                                  ofKind: DecorationViewKinds.todayBackground,
                                                  withItemCache: todayBackgroundAttributes)
            attributes.frame = CGRect(x: sectionX, y: 0, width: sectionWidth, height: sectionHeight + calendarStartY)
            attributes.zIndex = zIndexForElementKind(DecorationViewKinds.todayBackground)
        }
    }

    func layoutVerticalGridLinesAttributes(section: Int, sectionX: CGFloat, calendarGridMinY: CGFloat, sectionHeight: CGFloat) {
        var attributes = UICollectionViewLayoutAttributes()

        (attributes, verticalGridlineAttributes) =
            layoutAttributesForDecorationView(at: IndexPath(item: 0, section: section),
                                              ofKind: DecorationViewKinds.verticalGridline,
                                              withItemCache: verticalGridlineAttributes)
        attributes.frame = CGRect(x: nearbyint(sectionX - gridThickness / 2.0),
                                  y: calendarGridMinY,
                                  width: gridThickness,
                                  height: sectionHeight)
        attributes.zIndex = zIndexForElementKind(DecorationViewKinds.verticalGridline)
    }

    func layoutHorizontalGridLinesAttributes(calendarStartX: CGFloat, calendarStartY: CGFloat) {
        var horizontalGridlineIndex = 0
        let calendarGridWidth = collectionViewContentSize.width - rowHeaderWidth - contentsMargin.left - contentsMargin.right
        var attributes = UICollectionViewLayoutAttributes()

        for hour in 0...23 {
            (attributes, horizontalGridlineAttributes) =
                layoutAttributesForDecorationView(at: IndexPath(item: horizontalGridlineIndex, section: 0),
                                                  ofKind: DecorationViewKinds.horizontalGridline,
                                                  withItemCache: horizontalGridlineAttributes)
            let horizontalGridlineXOffset = calendarStartX + sectionMargin.left
            let horizontalGridlineMinX = fmax(horizontalGridlineXOffset, collectionView!.contentOffset.x + horizontalGridlineXOffset)
            let horizontalGridlineMinY = nearbyint(calendarStartY + (hourHeight * CGFloat(hour))) - (gridThickness / 2.0)
            let horizontalGridlineWidth = fmin(calendarGridWidth, collectionView!.frame.width)

            attributes.frame = CGRect(x: horizontalGridlineMinX,
                                      y: horizontalGridlineMinY,
                                      width: horizontalGridlineWidth,
                                      height: gridThickness)
            attributes.zIndex = zIndexForElementKind(DecorationViewKinds.horizontalGridline)
            horizontalGridlineIndex += 1

            if hourGridDivisionValue.rawValue > 0 {
                horizontalGridlineIndex = drawHourDividersAtGridLineIndex(horizontalGridlineIndex, hour: hour,
                                                                          startX: horizontalGridlineMinX,
                                                                          startY: horizontalGridlineMinY,
                                                                          gridlineWidth: horizontalGridlineWidth)
            }
        }
    }

    func drawHourDividersAtGridLineIndex(_ gridlineIndex: Int, hour: Int, startX calendarStartX: CGFloat,
                                         startY calendarStartY: CGFloat, gridlineWidth: CGFloat) -> Int {
        var _gridlineIndex = gridlineIndex
        var attributes = UICollectionViewLayoutAttributes()
        let numberOfDivisions = 60 / hourGridDivisionValue.rawValue
        let divisionHeight = hourHeight / CGFloat(numberOfDivisions)

        for division in 1..<numberOfDivisions {
            let horizontalGridlineIndexPath = IndexPath(item: _gridlineIndex, section: 0)

            (attributes, horizontalGridlineAttributes) = layoutAttributesForDecorationView(at: horizontalGridlineIndexPath,
                                                                                          ofKind: DecorationViewKinds.horizontalGridline,
                                                                                          withItemCache: horizontalGridlineAttributes)
            let horizontalGridlineMinY = nearbyint(calendarStartY + (divisionHeight * CGFloat(division)) - (gridThickness / 2.0))
            attributes.frame = CGRect(x: calendarStartX, y: horizontalGridlineMinY, width: gridlineWidth, height: gridThickness)
            attributes.alpha = 0.3
            attributes.zIndex = zIndexForElementKind(DecorationViewKinds.horizontalGridline)

            _gridlineIndex += 1

        }
        return _gridlineIndex
    }

    override var collectionViewContentSize: CGSize {
        let size = CGSize(width: rowHeaderWidth + sectionWidth * CGFloat(collectionView!.numberOfSections),
                          height: maxSectionHeight)
        return size
    }

    // MARK: - Layout
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return itemAttributes[indexPath]
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        switch elementKind {
        case SupplementaryViewKinds.columnHeader:
            return columnHeaderAttributes[indexPath]
        case SupplementaryViewKinds.rowHeader:
            return rowHeaderAttributes[indexPath]
        default:
            return nil
        }
    }

    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        switch elementKind {
        case DecorationViewKinds.verticalGridline:
            return verticalGridlineAttributes[indexPath]
        case DecorationViewKinds.horizontalGridline:
            return horizontalGridlineAttributes[indexPath]
        case DecorationViewKinds.rowHeaderBackground:
            return rowHeaderBackgroundAttributes[indexPath]
        case DecorationViewKinds.columnHeaderBackground:
            return columnHeaderBackgroundAttributes[indexPath]
        case DecorationViewKinds.todayBackground:
            return todayBackgroundAttributes[indexPath]
        case DecorationViewKinds.cornerHeader:
            return cornerHeaderAttributes[indexPath]
        default:
            return nil
        }
    }

    // MARK: - Layout
    func layoutAttributesForCell(at indexPath: IndexPath, withItemCache itemCache: AttDic) -> (UICollectionViewLayoutAttributes, AttDic) {
        var layoutAttributes = itemCache[indexPath]

        if layoutAttributes == nil {
            var _itemCache = itemCache
            layoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            _itemCache[indexPath] = layoutAttributes
            return (layoutAttributes!, _itemCache)
        } else {
            return (layoutAttributes!, itemCache)
        }
    }

    private let currentTimeDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter
    }()

    func layoutAttributesForDecorationView(at indexPath: IndexPath,
                                           ofKind kind: String,
                                           withItemCache itemCache: AttDic) -> (UICollectionViewLayoutAttributes, AttDic) {

        let layoutAttributes = (itemCache[indexPath] as? WRCurrentTimeLayoutAttributes) ?? WRCurrentTimeLayoutAttributes(forDecorationViewOfKind: kind, with: indexPath)

        if kind == DecorationViewKinds.currentTimeIndicator {
            currentTimeDateFormatter.timeZone = calendar.timeZone
            let dateString = currentTimeDateFormatter.string(from: Date())
            layoutAttributes.timeLabelText = dateString
        }

        if let startDate = currentPageStartDate, let interval = currentPageInterval,
            (kind == DecorationViewKinds.currentTimeGridline || kind == DecorationViewKinds.currentTimeIndicator) {
            layoutAttributes.isHidden = !startDate.isToday && interval == 1 /* Week view */
        }

        var newCache = itemCache
        newCache[indexPath] = layoutAttributes
        return (layoutAttributes, newCache)
    }

    func layoutAttributesForSupplemantaryView(at indexPath: IndexPath,
                                              ofKind kind: String,
                                              withItemCache itemCache: AttDic) -> (UICollectionViewLayoutAttributes, AttDic) {
        var layoutAttributes = itemCache[indexPath]

        if layoutAttributes == nil {
            var _itemCache = itemCache
            layoutAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: kind, with: indexPath)
            _itemCache[indexPath] = layoutAttributes
            return (layoutAttributes!, _itemCache)
        } else {
            return (layoutAttributes!, itemCache)
        }
    }

    func adjustItemsForOverlap(_ sectionItemAttributes: [UICollectionViewLayoutAttributes], inSection: Int, sectionMinX: CGFloat) {

        // Overlapping events are handled by dividng the column (section) into the number of overlapping events.
        // The earliest event (the top one in the column) is always the full width of the column. The later ones start
        // at an inset from the left edge, and then extend the rest of the way to the right edge. (This is similar to
        // Google calendar behavior). If there are two overlapping events, the later sits above the earlier event and
        // takes up only the left half othe column.  If there are there are three, the second sits above the first and
        // takes up the left two-thirds of the column, and the third sets above the first two and takes up the last
        // one-third.

        // This is a helper type that combines layout attributes with overlapping information.
        class Event {
            // This gives the offset of the drawn event from the left border of the column.  The actual
            // offset in pixels depends on both this parameter and the number of column divisions.
            var offsetIndex: Int = 0

            // The gives the maximum number of events that this event is overlapped with at any point in
            // the column. It is used to calculate the number of required column divisions.
            var maxOverlapDepth: Int = 1

            // The actual layout attributes of this event. We ultimately want to adjust the frame property
            // of these attributes.
            let attributes: UICollectionViewLayoutAttributes

            init(attributes: UICollectionViewLayoutAttributes) {
                self.attributes = attributes
            }

            var maxY: CGFloat { attributes.frame.maxY }
            var minY: CGFloat { attributes.frame.minY }
        }

        // Start by sorting events from top to bottom
        let events = sectionItemAttributes
            .sorted(by: { $0.frame.minY < $1.frame.minY })
            .map{ Event(attributes: $0) }

        guard let firstEvent = events.first else { return }

        // This structure maintains the current stack of currently overlapped events as we
        // go through the loop below.
        // It should be sorted by `stackIndex`
        var overlappingEvents: [Event] = [firstEvent]

        // Take a pass through all the events and capture the required overlap information
        for event in events.dropFirst() {
            // Get all overlapping events for the current loop event. (Note that once a previous
            // event doesn't overlap with the loop event, it cannot overlap with any future loop event.)
            overlappingEvents = overlappingEvents.filter { $0.maxY > event.minY }

            // Find if there is any "gap" in the offset indexes where we can insert this new event.
            let insertionIndex = overlappingEvents.enumerated()
                .first(where: { (idx, event) in event.offsetIndex != idx })
                .map{ (idx, _) in idx }

            // Handle the insertion if there is such a gap; otherwise, append this overlapping event
            if let insertionIndex = insertionIndex {
                event.offsetIndex = insertionIndex
                overlappingEvents.insert(event, at: insertionIndex)
            } else {
                event.offsetIndex = overlappingEvents.count
                overlappingEvents.append(event)
            }

            // The max stack depth for an event is the greater of either the existing overlapped items max stack depth,
            // or the current stack depth.
            let stackDepth =  max(overlappingEvents.map{ $0.maxOverlapDepth }.max()!, overlappingEvents.count)
            overlappingEvents.forEach { $0.maxOverlapDepth = stackDepth }
        }

        // Now configure all event attributes
        events.forEach { event in
            let divisionWidth = nearbyint((sectionWidth - sectionMargin.left - sectionMargin.right) / CGFloat(event.maxOverlapDepth))
            print("\(divisionWidth):  \(sectionWidth - sectionMargin.left - sectionMargin.right) / \(event.maxOverlapDepth)")
            if divisionWidth >= 40 || true {
                assert(event.maxOverlapDepth > event.offsetIndex)
                event.attributes.size.width = divisionWidth * CGFloat(event.maxOverlapDepth - event.offsetIndex) - cellMargin.left - cellMargin.right
                event.attributes.frame.origin.x = sectionMinX + divisionWidth * CGFloat(event.offsetIndex) + cellMargin.left
                event.attributes.zIndex = minCellZ + event.offsetIndex
            } else {
                event.attributes.zIndex = minCellZ + event.offsetIndex
            }
        }

        // Previously, overlapping events were handled by splitting the column into divisions and putting each event
        // into its own divistion. The major difference here is that there is no visual overlap of events, and the
        // entire event is modified, even if there is only a small overlap with another event. That code is commented
        // out below, in case we want to revert to that behaviour.
        //
        //  let divisionWidth = nearbyint(sectionWidth / CGFloat(divisions))
        //                var dividedAttributes = [UICollectionViewLayoutAttributes]()
        //
        //                for divisionAttributes in overlappingItems {
        //                    let itemWidth = divisionWidth - cellMargin.left - cellMargin.right
        //
        //                    // It it hasn't yet been adjusted, perform adjustment
        //                    if !adjustedAttributes.contains(divisionAttributes) {
        //                        var divisionAttributesFrame = divisionAttributes.frame
        //                        divisionAttributesFrame.origin.x = sectionMinX + cellMargin.left
        //                        divisionAttributesFrame.size.width = itemWidth
        //
        //                        // Horizontal Layout
        //                        var adjustments = 1
        //                        for dividedItemAttributes in dividedAttributes {
        //                            if dividedItemAttributes.frame.intersects(divisionAttributesFrame) {
        //                                divisionAttributesFrame.origin.x = sectionMinX + ((divisionWidth * CGFloat(adjustments)) + cellMargin.left)
        //                                adjustments += 1
        //                            }
        //                        }
        //
        //                        // Stacking (lower items stack above higher items, since the title is at the top)
        //                        divisionAttributes.zIndex = sectionZ
        //                        sectionZ += 1
        //
        //                        divisionAttributes.frame = divisionAttributesFrame
        //                        dividedAttributes.append(divisionAttributes)
        //                        adjustedAttributes.insert(divisionAttributes)
        //                    }
        //                 }


//        var adjustedAttributes = Set<UICollectionViewLayoutAttributes>()
//        var sectionZ = minCellZ
//
//        for itemAttributes in sectionItemAttributes {
//            // If an item's already been adjusted, move on to the next one
//            if adjustedAttributes.contains(itemAttributes) {
//                continue
//            }
//
//            // Find the other items that overlap with this item
//            var overlappingItems = [UICollectionViewLayoutAttributes]()
//            let itemFrame = itemAttributes.frame
//
//            overlappingItems.append(contentsOf: sectionItemAttributes.filter {
//                if $0 != itemAttributes {
//                    return itemFrame.intersects($0.frame)
//                } else {
//                    return false
//                }
//            })
//
//
//            // If there's items overlapping, we need to adjust them
//            if overlappingItems.count > 0 {
//                // Add the item we're adjusting to the overlap set
//                overlappingItems.insert(itemAttributes, at: 0)
//                var minY = CGFloat.greatestFiniteMagnitude
//                var maxY = CGFloat.leastNormalMagnitude
//
//                for overlappingItemAttributes in overlappingItems {
//                    if overlappingItemAttributes.frame.minY < minY {
//                        minY = overlappingItemAttributes.frame.minY
//                    }
//                    if overlappingItemAttributes.frame.maxY > maxY {
//                        maxY = overlappingItemAttributes.frame.maxY
//                    }
//                }
//
//                overlappingItems.sort(by: { $0.frame.minY < $1.frame.minY })
//
//                // Determine the number of divisions needed (maximum number of currently overlapping items)
//                var divisions = 1
//
//                for currentY in stride(from: minY, to: maxY, by: 1) {
//                    var numberItemsForCurrentY = 0
//
//                    for overlappingItemAttributes in overlappingItems {
//                        if currentY >= overlappingItemAttributes.frame.minY &&
//                            currentY < overlappingItemAttributes.frame.maxY {
//                            numberItemsForCurrentY += 1
//                        }
//                    }
//                    if numberItemsForCurrentY > divisions {
//                        divisions = numberItemsForCurrentY
//                    }
//                }
//
//                // Adjust the items to have a width of the section size divided by the number of divisions needed
//                let divisionWidth = nearbyint(sectionWidth / CGFloat(divisions))
//                var dividedAttributes = [UICollectionViewLayoutAttributes]()
//
//                for divisionAttributes in overlappingItems {
//                    let itemWidth = divisionWidth - cellMargin.left - cellMargin.right
//
//                    // It it hasn't yet been adjusted, perform adjustment
//                    if !adjustedAttributes.contains(divisionAttributes) {
//                        var divisionAttributesFrame = divisionAttributes.frame
//                        divisionAttributesFrame.origin.x = sectionMinX + cellMargin.left
//                        divisionAttributesFrame.size.width = itemWidth
//
//                        // Horizontal Layout
//                        var adjustments = 1
//                        for dividedItemAttributes in dividedAttributes {
//                            if dividedItemAttributes.frame.intersects(divisionAttributesFrame) {
//                                divisionAttributesFrame.origin.x = sectionMinX + ((divisionWidth * CGFloat(adjustments)) + cellMargin.left)
//                                adjustments += 1
//                            }
//                        }
//
//                        // Stacking (lower items stack above higher items, since the title is at the top)
//                        divisionAttributes.zIndex = sectionZ
//                        sectionZ += 1
//
//                        divisionAttributes.frame = divisionAttributesFrame
//                        dividedAttributes.append(divisionAttributes)
//                        adjustedAttributes.insert(divisionAttributes)
//                    }
//                 }
//            }
//        }
    }

    func invalidateLayoutCache() {
        needsToPopulateAttributesForAllSections = true

        cachedDayDateComponents.removeAll()
        verticalGridlineAttributes.removeAll()
        horizontalGridlineAttributes.removeAll()
        columnHeaderAttributes.removeAll()
        columnHeaderBackgroundAttributes.removeAll()
        rowHeaderAttributes.removeAll()
        rowHeaderBackgroundAttributes.removeAll()
        todayBackgroundAttributes.removeAll()
        cornerHeaderAttributes.removeAll()
        itemAttributes.removeAll()
        allAttributes.removeAll()
    }

    func invalidateItemsCache() {
        itemAttributes.removeAll()
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let visibleSections = NSMutableIndexSet()
        NSIndexSet.init(indexesIn: NSRange.init(location: 0, length: collectionView!.numberOfSections))
            .enumerate(_:) { (section: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                let sectionRect = rectForSection(section)
                if rect.intersects(sectionRect) {
                    visibleSections.add(section)
                }
        }
        prepareHorizontalTileSectionLayoutForSections(visibleSections)

        return allAttributes.filter({ rect.intersects($0.frame) })
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    // MARK: - Section sizing
    func rectForSection(_ section: Int) -> CGRect {
        return CGRect(x: rowHeaderWidth + sectionWidth * CGFloat(section),
                      y: 0,
                      width: sectionWidth,
                      height: collectionViewContentSize.height)
    }

    // MARK: - Delegate Wrapper
    func daysForSection(_ section: Int) -> DateComponents {
        if cachedDayDateComponents[section] != nil {
            return cachedDayDateComponents[section]!
        }

        let day = delegate?.collectionView(collectionView!, layout: self, dayForSection: section)
        guard day != nil else { fatalError() }
        let startOfDay = calendar.startOfDay(for: day!)
        let dayDateComponents = calendar.dateComponents([.year, .month, .day], from: startOfDay)
        cachedDayDateComponents[section] = dayDateComponents
        return dayDateComponents
    }

    func startTimeForIndexPath(_ indexPath: IndexPath) -> DateComponents {
        if cachedStartTimeDateComponents[indexPath] != nil {
            return cachedStartTimeDateComponents[indexPath]!
        } else {
            if let date = delegate?.collectionView(collectionView!, layout: self, startTimeForItemAtIndexPath: indexPath) {
                return calendar.dateComponents([.day, .hour, .minute], from: date)
            } else {
                fatalError()
            }
        }
    }

    func endTimeForIndexPath(_ indexPath: IndexPath) -> DateComponents {
        if cachedEndTimeDateComponents[indexPath] != nil {
            return cachedEndTimeDateComponents[indexPath]!
        } else {
            if let date = delegate?.collectionView(collectionView!, layout: self, endTimeForItemAtIndexPath: indexPath) {
                return calendar.dateComponents([.day, .hour, .minute], from: date)
            } else {
                fatalError()
            }
        }
    }

    // MARK: - Scroll
    func scrollCollectionViewToTime(_ date: Date) {
        let y = max(0, min(CGFloat(date.hour) * hourHeight - 5,
                    collectionView!.contentSize.height - collectionView!.frame.height))
        //didScroll에서 horizontal, vertical scroll이 동시에 되는 것을 막고 있음
        //임시로 처음 current time찾아갈 때만 delegate를 무효화하도록 함
        //더 나은 방법 찾을때까지 임시 유지
        let tempDelegate = collectionView!.delegate
        collectionView!.delegate = nil
        self.collectionView!.contentOffset = CGPoint(x: self.collectionView!.contentOffset.x, y: y)
        collectionView!.delegate = tempDelegate
    }

    // MARK: - Dates
    func dateForTimeRowHeader(at indexPath: IndexPath) -> Date {
        var components = daysForSection(indexPath.section)
        components.hour = indexPath.item
        return calendar.date(from: components)!
    }

    func dateForColumnHeader(at indexPath: IndexPath) -> Date {
        let day = delegate?.collectionView(collectionView!, layout: self, dayForSection: indexPath.section)
        return calendar.startOfDay(for: day!)
    }

    func hourIndexForDate(_ date: Date) -> Int {
        return calendar.component(.hour, from: date)
    }

    // MARK: - z index
    func zIndexForElementKind(_ kind: String) -> Int {
        switch kind {
        case DecorationViewKinds.currentTimeIndicator:
            return minOverlayZ + 10
        case DecorationViewKinds.cornerHeader:
            return minOverlayZ + 9
        case SupplementaryViewKinds.rowHeader:
            return minOverlayZ + 8
        case DecorationViewKinds.rowHeaderBackground:
            return minOverlayZ + 7
        case SupplementaryViewKinds.columnHeader:
            return minOverlayZ + 6
        case DecorationViewKinds.columnHeaderBackground:
            return minOverlayZ + 5
        case DecorationViewKinds.currentTimeGridline:
            return minBackgroundZ + 4
        case DecorationViewKinds.horizontalGridline:
            return minBackgroundZ + 3
        case DecorationViewKinds.verticalGridline:
            return minBackgroundZ + 2
        case DecorationViewKinds.todayBackground:
            return minBackgroundZ
        default:
            return minCellZ
        }
    }
}

