// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

#if os(OSX) || os(iOS)
    import Darwin
#elseif os(Linux) || IS_CYGWIN
    import Glibc
#endif

public class NSUUID : NSObject, NSCopying, NSSecureCoding, NSCoding {
    internal var buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
    
    public override init() {
        _cf_uuid_generate_random(buffer)
    }
    
    public convenience init?(UUIDString string: String) {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
        if _cf_uuid_parse(string, buffer) != 0 {
            return nil
        }
        self.init(UUIDBytes: buffer)
    }
    
    public init(UUIDBytes bytes: UnsafePointer<UInt8>) {
        memcpy(unsafeBitCast(buffer, to: UnsafeMutablePointer<Void>.self), UnsafePointer<Void>(bytes), 16)
    }
    
    public func getUUIDBytes(_ uuid: UnsafeMutablePointer<UInt8>) {
        _cf_uuid_copy(uuid, buffer)
    }
    
    public var UUIDString: String {
        let strPtr = UnsafeMutablePointer<Int8>.allocate(capacity: 37)
        _cf_uuid_unparse_upper(buffer, strPtr)
        return String(cString: strPtr)
    }
    
    public override func copy() -> AnyObject {
        return copy(with: nil)
    }
    
    public func copy(with zone: NSZone? = nil) -> AnyObject {
        return self
    }
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    public convenience required init?(coder: NSCoder) {
        if coder.allowsKeyedCoding {
            let decodedData : Data? = coder.withDecodedUnsafeBufferPointer(forKey: "NS.uuidbytes") {
                guard let buffer = $0 else { return nil }
                return Data(buffer: buffer)
            }

            guard let data = decodedData else { return nil }
            guard data.count == 16 else { return nil }
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
            data.copyBytes(to: buffer, count: 16)
            self.init(UUIDBytes: buffer)
        } else {
            // NSUUIDs cannot be decoded by non-keyed coders
            coder.failWithError(NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.CoderReadCorruptError.rawValue, userInfo: [
                                "NSDebugDescription": "NSUUID cannot be decoded by non-keyed coders"
                                ]))
            return nil
        }
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encodeBytes(buffer, length: 16, forKey: "NS.uuidbytes")
    }
    
    public override func isEqual(_ object: AnyObject?) -> Bool {
        if object === self {
            return true
        } else if let other = object as? NSUUID {
            return _cf_uuid_compare(buffer, other.buffer) == 0
        } else {
            return false
        }
    }
    
    public override var hash: Int {
        return Int(bitPattern: CFHashBytes(buffer, 16))
    }
    
    public override var description: String {
        return UUIDString
    }
}
