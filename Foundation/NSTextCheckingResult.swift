// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

/* NSTextCheckingType in this project is limited to regular expressions. */
public struct NSTextCheckingType : OptionSet {
    public let rawValue: UInt64
    public init(rawValue: UInt64) { self.rawValue = rawValue }
    
    public static let RegularExpression = NSTextCheckingType(rawValue: 1 << 10) // regular expression matches
}

public class NSTextCheckingResult : NSObject, NSCopying, NSCoding {
    
    public override init() {
        super.init()
    }
    
    public class func regularExpressionCheckingResultWithRanges(_ ranges: NSRangePointer, count: Int, regularExpression: NSRegularExpression) -> NSTextCheckingResult {
        return _NSRegularExpressionTextCheckingResultResult(ranges: ranges, count: count, regularExpression: regularExpression)
    }

    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    public func encodeWithCoder(_ aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(_ zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
    
    /* Mandatory properties, used with all types of results. */
    public var resultType: NSTextCheckingType { NSUnimplemented() }
    public var range: NSRange { return range(at: 0) }
    /* A result must have at least one range, but may optionally have more (for example, to represent regular expression capture groups).  The range at index 0 always matches the range property.  Additional ranges, if any, will have indexes from 1 to numberOfRanges-1. */
    public func range(at idx: Int) -> NSRange { NSUnimplemented() }
    public var regularExpression: NSRegularExpression? { return nil }
    public var numberOfRanges: Int { return 1 }
}

internal class _NSRegularExpressionTextCheckingResultResult : NSTextCheckingResult {
    var _ranges = [NSRange]()
    let _regularExpression: NSRegularExpression
    init(ranges: NSRangePointer, count: Int, regularExpression: NSRegularExpression) {
        _regularExpression = regularExpression
        super.init()
        let notFound = NSRange(location: NSNotFound,length: 0)
        for i in 0..<count {
            ranges[i].location == kCFNotFound ? _ranges.append(notFound) : _ranges.append(ranges[i])
        }  
    }

    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var resultType: NSTextCheckingType { return .RegularExpression }
    override func range(at idx: Int) -> NSRange { return _ranges[idx] }
    override var numberOfRanges: Int { return _ranges.count }
    override var regularExpression: NSRegularExpression? { return _regularExpression }
}

extension NSTextCheckingResult {
    
    
    
    public func resultByAdjustingRangesWithOffset(_ offset: Int) -> NSTextCheckingResult {
        let count = self.numberOfRanges
        var newRanges = [NSRange]()
        for idx in 0..<count {
           let currentRange = self.range(at: idx)
           if (currentRange.location == NSNotFound) {
              newRanges.append(currentRange)
           } else if ((offset > 0 && NSNotFound - currentRange.location <= offset) || (offset < 0 && currentRange.location < -offset)) {
              NSInvalidArgument(" \(offset) invalid offset for range {\(currentRange.location), \(currentRange.length)}")
           } else {
              newRanges.append(NSRange(location: currentRange.location + offset,length: currentRange.length))
           }
        }
        let result = NSTextCheckingResult.regularExpressionCheckingResultWithRanges(&newRanges, count: count, regularExpression: self.regularExpression!)
        return result
    }
}
