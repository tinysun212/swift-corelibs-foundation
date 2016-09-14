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
#elseif os(Linux) || CYGWIN
import Glibc
#endif

extension NSData {

    public struct ReadingOptions : OptionSet {
        public let rawValue : UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        
        public static let dataReadingMappedIfSafe = ReadingOptions(rawValue: UInt(1 << 0))
        public static let dataReadingUncached = ReadingOptions(rawValue: UInt(1 << 1))
        public static let dataReadingMappedAlways = ReadingOptions(rawValue: UInt(1 << 2))
    }

    public struct WritingOptions : OptionSet {
        public let rawValue : UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        
        public static let dataWritingAtomic = WritingOptions(rawValue: UInt(1 << 0))
        public static let dataWritingWithoutOverwriting = WritingOptions(rawValue: UInt(1 << 1))
    }

    public struct SearchOptions : OptionSet {
        public let rawValue : UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        
        public static let backwards = SearchOptions(rawValue: UInt(1 << 0))
        public static let anchored = SearchOptions(rawValue: UInt(1 << 1))
    }

    public struct Base64EncodingOptions : OptionSet {
        public let rawValue : UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        
        public static let encoding64CharacterLineLength = Base64EncodingOptions(rawValue: UInt(1 << 0))
        public static let encoding76CharacterLineLength = Base64EncodingOptions(rawValue: UInt(1 << 1))
        public static let encodingEndLineWithCarriageReturn = Base64EncodingOptions(rawValue: UInt(1 << 4))
        public static let encodingEndLineWithLineFeed = Base64EncodingOptions(rawValue: UInt(1 << 5))
    }

    public struct Base64DecodingOptions : OptionSet {
        public let rawValue : UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        
        public static let ignoreUnknownCharacters = Base64DecodingOptions(rawValue: UInt(1 << 0))
    }
}

private final class _NSDataDeallocator {
    var handler: (UnsafeMutableRawPointer, Int) -> Void = {_,_ in }
}

private let __kCFMutable: CFOptionFlags = 0x01
private let __kCFGrowable: CFOptionFlags = 0x02
private let __kCFMutableVarietyMask: CFOptionFlags = 0x03
private let __kCFBytesInline: CFOptionFlags = 0x04
private let __kCFUseAllocator: CFOptionFlags = 0x08
private let __kCFDontDeallocate: CFOptionFlags = 0x10
private let __kCFAllocatesCollectable: CFOptionFlags = 0x20

open class NSData : NSObject, NSCopying, NSMutableCopying, NSSecureCoding {
    typealias CFType = CFData
    private var _base = _CFInfo(typeID: CFDataGetTypeID())
    private var _length: CFIndex = 0
    private var _capacity: CFIndex = 0
    private var _deallocator: UnsafeMutableRawPointer? = nil // for CF only
    private var _deallocHandler: _NSDataDeallocator? = _NSDataDeallocator() // for Swift
    private var _bytes: UnsafeMutablePointer<UInt8>? = nil
    
    internal var _cfObject: CFType {
        if type(of: self) === NSData.self || type(of: self) === NSMutableData.self {
            return unsafeBitCast(self, to: CFType.self)
        } else {
            let bytePtr = self.bytes.bindMemory(to: UInt8.self, capacity: self.length)
            return CFDataCreate(kCFAllocatorSystemDefault, bytePtr, self.length)
        }
    }
    
    public override required convenience init() {
        let dummyPointer = unsafeBitCast(NSData.self, to: UnsafeMutableRawPointer.self)
        self.init(bytes: dummyPointer, length: 0, copy: false, deallocator: nil)
    }
    
    open override var hash: Int {
        return Int(bitPattern: CFHash(_cfObject))
    }
    
    open override func isEqual(_ object: AnyObject?) -> Bool {
        if let data = object as? NSData {
            return self.isEqual(to: data._swiftObject)
        } else {
            return false
        }
    }
    
    deinit {
        if let allocatedBytes = _bytes {
            _deallocHandler?.handler(allocatedBytes, _length)
        }
        if type(of: self) === NSData.self || type(of: self) === NSMutableData.self {
            _CFDeinit(self._cfObject)
        }
    }
    
    internal init(bytes: UnsafeMutableRawPointer?, length: Int, copy: Bool, deallocator: ((UnsafeMutableRawPointer, Int) -> Void)?) {
        super.init()
        let options : CFOptionFlags = (type(of: self) == NSMutableData.self) ? __kCFMutable | __kCFGrowable : 0x0
        let bytePtr = bytes?.bindMemory(to: UInt8.self, capacity: length)
        if copy {
            _CFDataInit(unsafeBitCast(self, to: CFMutableData.self), options, length, bytePtr, length, false)
            if let handler = deallocator {
                handler(bytes!, length)
            }
        } else {
            if let handler = deallocator {
                _deallocHandler!.handler = handler
            }
            // The data initialization should flag that CF should not deallocate which leaves the handler a chance to deallocate instead
            _CFDataInit(unsafeBitCast(self, to: CFMutableData.self), options | __kCFDontDeallocate, length, bytePtr, length, true)
        }
    }
    
    open var length: Int {
        return CFDataGetLength(_cfObject)
    }

    open var bytes: UnsafeRawPointer {
        return UnsafeRawPointer(CFDataGetBytePtr(_cfObject))
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    open override func mutableCopy() -> Any {
        return mutableCopy(with: nil)
    }
    
    open func mutableCopy(with zone: NSZone? = nil) -> Any {
        return NSMutableData(bytes: UnsafeMutableRawPointer(mutating: bytes), length: length, copy: true, deallocator: nil)
    }

    open func encode(with aCoder: NSCoder) {
        if let aKeyedCoder = aCoder as? NSKeyedArchiver {
            aKeyedCoder._encodePropertyList(self, forKey: "NS.data")
        } else {
            let bytePtr = self.bytes.bindMemory(to: UInt8.self, capacity: self.length)
            aCoder.encodeBytes(bytePtr, length: self.length)
        }
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        if !aDecoder.allowsKeyedCoding {
            if let data = aDecoder.decodeData() {
                self.init(data: data)
            } else {
                return nil
            }
        } else if type(of: aDecoder) == NSKeyedUnarchiver.self || aDecoder.containsValue(forKey: "NS.data") {
            guard let data = aDecoder._decodePropertyListForKey("NS.data") as? NSData else {
                return nil
            }
            self.init(data: data._swiftObject)
        } else {
            let result : Data? = aDecoder.withDecodedUnsafeBufferPointer(forKey: "NS.bytes") {
                guard let buffer = $0 else { return nil }
                return Data(buffer: buffer)
            }

            guard let r = result else { return nil }
            self.init(data: r)
        }
    }
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    private func byteDescription(limit: Int? = nil) -> String {
        var s = ""
        var i = 0
        while i < self.length {
            if i > 0 && i % 4 == 0 {
                // if there's a limit, and we're at the barrier where we'd add the ellipses, don't add a space.
                if let limit = limit, self.length > limit && i == self.length - (limit / 2) { /* do nothing */ }
                else { s += " " }
            }
            let byte = bytes.load(fromByteOffset: i, as: UInt8.self)
            var byteStr = String(byte, radix: 16, uppercase: false)
            if byte <= 0xf { byteStr = "0\(byteStr)" }
            s += byteStr
            // if we've hit the midpoint of the limit, skip to the last (limit / 2) bytes.
            if let limit = limit, self.length > limit && i == (limit / 2) - 1 {
                s += " ... "
                i = self.length - (limit / 2)
            } else {
                i += 1
            }
        }
        return s
    }
    
    override open var debugDescription: String {
        return "<\(byteDescription(limit: 1024))>"
    }
    
    override open var description: String {
        return "<\(byteDescription())>"
    }
    
    override open var _cfTypeID: CFTypeID {
        return CFDataGetTypeID()
    }
}

extension NSData {
    
    public convenience init(bytes: UnsafeRawPointer?, length: Int) {
        self.init(bytes: UnsafeMutableRawPointer(mutating: bytes), length: length, copy: true, deallocator: nil)
    }

    public convenience init(bytesNoCopy bytes: UnsafeMutableRawPointer, length: Int) {
        self.init(bytes: bytes, length: length, copy: false, deallocator: nil)
    }
    
    public convenience init(bytesNoCopy bytes: UnsafeMutableRawPointer, length: Int, freeWhenDone b: Bool) {
        self.init(bytes: bytes, length: length, copy: false) { buffer, length in
            if b {
                free(buffer)
            }
        }
    }

    public convenience init(bytesNoCopy bytes: UnsafeMutableRawPointer, length: Int, deallocator: ((UnsafeMutableRawPointer, Int) -> Void)?) {
        self.init(bytes: bytes, length: length, copy: false, deallocator: deallocator)
    }
    
    
    internal struct NSDataReadResult {
        var bytes: UnsafeMutableRawPointer
        var length: Int
        var deallocator: ((_ buffer: UnsafeMutableRawPointer, _ length: Int) -> Void)?
    }
    
    internal static func readBytesFromFileWithExtendedAttributes(_ path: String, options: ReadingOptions) throws -> NSDataReadResult {
        let fd = _CFOpenFile(path, O_RDONLY)
        if fd < 0 {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
        }
        defer {
            close(fd)
        }

        var info = stat()
        let ret = withUnsafeMutablePointer(to: &info) { infoPointer -> Bool in
            if fstat(fd, infoPointer) < 0 {
                return false
            }
            return true
        }
        
        if !ret {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
        }
        
        let length = Int(info.st_size)
        
        if options.contains(.dataReadingMappedAlways) {
            let data = mmap(nil, length, PROT_READ, MAP_PRIVATE, fd, 0)
            
            // Swift does not currently expose MAP_FAILURE
            if data != UnsafeMutableRawPointer(bitPattern: -1) {
                return NSDataReadResult(bytes: data!, length: length) { buffer, length in
                    munmap(buffer, length)
                }
            }
            
        }
        
        let data = malloc(length)!
        var remaining = Int(info.st_size)
        var total = 0
        while remaining > 0 {
            let amt = read(fd, data.advanced(by: total), remaining)
            if amt < 0 {
                break
            }
            remaining -= amt
            total += amt
        }

        if remaining != 0 {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
        }
        
        return NSDataReadResult(bytes: data, length: length) { buffer, length in
            free(buffer)
        }
    }
    
    public convenience init(contentsOfFile path: String, options readOptionsMask: ReadingOptions) throws {
        let readResult = try NSData.readBytesFromFileWithExtendedAttributes(path, options: readOptionsMask)
        self.init(bytes: readResult.bytes, length: readResult.length, copy: false, deallocator: readResult.deallocator)
    }

    public convenience init?(contentsOfFile path: String) {
        do {
            let readResult = try NSData.readBytesFromFileWithExtendedAttributes(path, options: [])
            self.init(bytes: readResult.bytes, length: readResult.length, copy: false, deallocator: readResult.deallocator)
        } catch {
            return nil
        }
    }

    public convenience init(data: Data) {
        self.init(bytes:data._nsObject.bytes, length: data.count)
    }
    
    public convenience init(contentsOf url: URL, options readOptionsMask: ReadingOptions) throws {
        if url.isFileURL {
            try self.init(contentsOfFile: url.path, options: readOptionsMask)
        } else {
            let session = URLSession(configuration: URLSessionConfiguration.defaultSessionConfiguration())
            let cond = NSCondition()
            var resError: NSError?
            var resData: Data?
            let task = session.dataTaskWithURL(url, completionHandler: { (data: Data?, response: URLResponse?, error: NSError?) -> Void in
                resData = data
                resError = error
                cond.broadcast()
            })
            task.resume()
            cond.wait()
            if resData == nil {
                throw resError!
            }
            self.init(data: resData!)
        }
    }
    
    public convenience init?(contentsOfURL url: URL) {
        do {
            try self.init(contentsOf: url, options: [])
        } catch {
            return nil
        }
    }
}

extension NSData {
    public func getBytes(_ buffer: UnsafeMutableRawPointer, length: Int) {
        let bytePtr = buffer.bindMemory(to: UInt8.self, capacity: length)
        CFDataGetBytes(_cfObject, CFRangeMake(0, length), bytePtr)
    }
    
    public func getBytes(_ buffer: UnsafeMutableRawPointer, range: NSRange) {
        let bytePtr = buffer.bindMemory(to: UInt8.self, capacity: range.length)
        CFDataGetBytes(_cfObject, CFRangeMake(range.location, range.length), bytePtr)
    }
    
    public func isEqual(to other: Data) -> Bool {

        if length != other.count {
            return false
        }
        
        
        return other.withUnsafeBytes { (bytes2: UnsafePointer<Void>) -> Bool in
            let bytes1 = bytes
            return memcmp(bytes1, bytes2, length) == 0
        }
    }
    
    public func subdata(with range: NSRange) -> Data {
        if range.length == 0 {
            return Data()
        }
        if range.location == 0 && range.length == self.length {
            return Data(_bridged: self)
        }
        return Data(bytes: bytes.advanced(by: range.location), count: range.length)
    }

    internal func makeTemporaryFileInDirectory(_ dirPath: String) throws -> (Int32, String) {
        let template = dirPath._nsObject.appendingPathComponent("tmp.XXXXXX")
        let maxLength = Int(PATH_MAX) + 1
        var buf = [Int8](repeating: 0, count: maxLength)
        let _ = template._nsObject.getFileSystemRepresentation(&buf, maxLength: maxLength)
        let fd = mkstemp(&buf)
        if fd == -1 {
            throw _NSErrorWithErrno(errno, reading: false, path: dirPath)
        }
        let pathResult = FileManager.default.string(withFileSystemRepresentation:buf, length: Int(strlen(buf)))
        return (fd, pathResult)
    }

    internal class func writeToFileDescriptor(_ fd: Int32, path: String? = nil, buf: UnsafeRawPointer, length: Int) throws {
        var bytesRemaining = length
        while bytesRemaining > 0 {
            var bytesWritten : Int
            repeat {
                #if os(OSX) || os(iOS)
                    bytesWritten = Darwin.write(fd, buf.advanced(by: length - bytesRemaining), bytesRemaining)
                #elseif os(Linux) || CYGWIN
                    bytesWritten = Glibc.write(fd, buf.advanced(by: length - bytesRemaining), bytesRemaining)
                #endif
            } while (bytesWritten < 0 && errno == EINTR)
            if bytesWritten <= 0 {
                throw _NSErrorWithErrno(errno, reading: false, path: path)
            } else {
                bytesRemaining -= bytesWritten
            }
        }
    }
    
    public func write(toFile path: String, options writeOptionsMask: WritingOptions = []) throws {
        var fd : Int32
        var mode : mode_t? = nil
        let useAuxiliaryFile = writeOptionsMask.contains(.dataWritingAtomic)
        var auxFilePath : String? = nil
        if useAuxiliaryFile {
            // Preserve permissions.
            var info = stat()
            if lstat(path, &info) == 0 {
                mode = info.st_mode
            } else if errno != ENOENT && errno != ENAMETOOLONG {
                throw _NSErrorWithErrno(errno, reading: false, path: path)
            }
            let (newFD, path) = try self.makeTemporaryFileInDirectory(path._nsObject.deletingLastPathComponent)
            fd = newFD
            auxFilePath = path
            fchmod(fd, 0o666)
        } else {
            var flags = O_WRONLY | O_CREAT | O_TRUNC
            if writeOptionsMask.contains(.dataWritingWithoutOverwriting) {
                flags |= O_EXCL
            }
            fd = _CFOpenFileWithMode(path, flags, 0o666)
        }
        if fd == -1 {
            throw _NSErrorWithErrno(errno, reading: false, path: path)
        }
        defer {
            close(fd)
        }

        try self.enumerateByteRangesUsingBlockRethrows { (buf, range, stop) in
            if range.length > 0 {
                do {
                    try NSData.writeToFileDescriptor(fd, path: path, buf: buf, length: range.length)
                    if fsync(fd) < 0 {
                        throw _NSErrorWithErrno(errno, reading: false, path: path)
                    }
                } catch let err {
                    if let auxFilePath = auxFilePath {
                        do {
                            try FileManager.default.removeItem(atPath: auxFilePath)
                        } catch _ {}
                    }
                    throw err
                }
            }
        }
        if let auxFilePath = auxFilePath {
            if rename(auxFilePath, path) != 0 {
                do {
                    try FileManager.default.removeItem(atPath: auxFilePath)
                } catch _ {}
                throw _NSErrorWithErrno(errno, reading: false, path: path)
            }
            if let mode = mode {
                chmod(path, mode)
            }
        }
    }
    
    public func write(toFile path: String, atomically useAuxiliaryFile: Bool) -> Bool {
        do {
            try write(toFile: path, options: useAuxiliaryFile ? .dataWritingAtomic : [])
        } catch {
            return false
        }
        return true
    }
    
    public func write(to url: URL, atomically: Bool) -> Bool {
        if url.isFileURL {
            return write(toFile: url.path, atomically: atomically)
        }
        return false
    }

    ///    Write the contents of the receiver to a location specified by the given file URL.
    ///
    ///    - parameter url:              The location to which the receiver’s contents will be written.
    ///    - parameter writeOptionsMask: An option set specifying file writing options.
    ///
    ///    - throws: This method returns Void and is marked with the `throws` keyword to indicate that it throws an error in the event of failure.
    ///
    ///      This method is invoked in a `try` expression and the caller is responsible for handling any errors in the `catch` clauses of a `do` statement, as described in [Error Handling](https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/Swift_Programming_Language/ErrorHandling.html#//apple_ref/doc/uid/TP40014097-CH42) in [The Swift Programming Language](https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/Swift_Programming_Language/index.html#//apple_ref/doc/uid/TP40014097) and [Error Handling](https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/BuildingCocoaApps/AdoptingCocoaDesignPatterns.html#//apple_ref/doc/uid/TP40014216-CH7-ID10) in [Using Swift with Cocoa and Objective-C](https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/BuildingCocoaApps/index.html#//apple_ref/doc/uid/TP40014216).
    public func write(to url: URL, options writeOptionsMask: WritingOptions = []) throws {
        guard url.isFileURL else {
            let userInfo = [NSLocalizedDescriptionKey : "The folder at “\(url)” does not exist or is not a file URL.", // NSLocalizedString() not yet available
                            NSURLErrorKey             : url.absoluteString] as Dictionary<String, Any>
            throw NSError(domain: NSCocoaErrorDomain, code: 4, userInfo: userInfo)
        }
        try write(toFile: url.path, options: writeOptionsMask)
    }
    
    public func range(of searchData: Data, options mask: SearchOptions = [], in searchRange: NSRange) -> NSRange {
        let dataToFind = searchData._nsObject
        guard dataToFind.length > 0 else {return NSRange(location: NSNotFound, length: 0)}
        guard let searchRange = searchRange.toRange() else {fatalError("invalid range")}
        
        precondition(searchRange.upperBound <= self.length, "range outside the bounds of data")

        let basePtr = self.bytes.bindMemory(to: UInt8.self, capacity: self.length)
        let baseData = UnsafeBufferPointer<UInt8>(start: basePtr, count: self.length)[searchRange]
        let searchPtr = dataToFind.bytes.bindMemory(to: UInt8.self, capacity: dataToFind.length)
        let search = UnsafeBufferPointer<UInt8>(start: searchPtr, count: dataToFind.length)
        
        let location : Int?
        let anchored = mask.contains(.anchored)
        if mask.contains(.backwards) {
            location = NSData.searchSubSequence(search.reversed(), inSequence: baseData.reversed(),anchored : anchored).map {$0.base-search.count}
        } else {
            location = NSData.searchSubSequence(search, inSequence: baseData,anchored : anchored)
        }
        return location.map {NSRange(location: $0, length: search.count)} ?? NSRange(location: NSNotFound, length: 0)
    }
    private static func searchSubSequence<T : Collection, T2 : Sequence>(_ subSequence : T2, inSequence seq: T,anchored : Bool) -> T.Index? where T.Iterator.Element : Equatable, T.Iterator.Element == T2.Iterator.Element, T.SubSequence.Iterator.Element == T.Iterator.Element, T.Indices.Iterator.Element == T.Index {
        for index in seq.indices {
            if seq.suffix(from: index).starts(with: subSequence) {
                return index
            }
            if anchored {return nil}
        }
        return nil
    }
    
    internal func enumerateByteRangesUsingBlockRethrows(_ block: (UnsafeRawPointer, NSRange, UnsafeMutablePointer<Bool>) throws -> Void) throws {
        var err : Swift.Error? = nil
        self.enumerateBytes() { (buf, range, stop) -> Void in
            do {
                try block(buf, range, stop)
            } catch let e {
                err = e
            }
        }
        if let err = err {
            throw err
        }
    }

    public func enumerateBytes(_ block: (UnsafeRawPointer, NSRange, UnsafeMutablePointer<Bool>) -> Void) {
        var stop = false
        withUnsafeMutablePointer(to: &stop) { stopPointer in
            block(bytes, NSMakeRange(0, length), stopPointer)
        }
    }
}

extension NSData : _CFBridgable, _SwiftBridgable {
    typealias SwiftType = Data
    internal var _swiftObject: SwiftType { return Data(_bridged: self) }
    
    public func bridge() -> Data {
        return _swiftObject
    }
}

extension Data : _NSBridgable, _CFBridgable {
    typealias CFType = CFData
    typealias NSType = NSData
    internal var _cfObject: CFType { return _nsObject._cfObject }
    internal var _nsObject: NSType { return _bridgeToObjectiveC() }
    
    public func bridge() -> NSData {
        return _nsObject
    }
}

extension CFData : _NSBridgable, _SwiftBridgable {
    typealias NSType = NSData
    typealias SwiftType = Data
    internal var _nsObject: NSType { return unsafeBitCast(self, to: NSType.self) }
    internal var _swiftObject: SwiftType { return Data(_bridged: self._nsObject) }
}

extension NSMutableData {
    internal var _cfMutableObject: CFMutableData { return unsafeBitCast(self, to: CFMutableData.self) }
}

open class NSMutableData : NSData {

    public required convenience init() {
        self.init(bytes: nil, length: 0)
    }
    
    internal override init(bytes: UnsafeMutableRawPointer?, length: Int, copy: Bool, deallocator: ((UnsafeMutableRawPointer, Int) -> Void)?) {
        super.init(bytes: bytes, length: length, copy: copy, deallocator: deallocator)
    }
    
    open var mutableBytes: UnsafeMutableRawPointer {
        return UnsafeMutableRawPointer(CFDataGetMutableBytePtr(_cfMutableObject))
    }
    
    open override var length: Int {
        get {
            return CFDataGetLength(_cfObject)
        }
        set {
            CFDataSetLength(_cfMutableObject, newValue)
        }
    }
    
    open override func copy(with zone: NSZone? = nil) -> Any {
        return NSData(bytes: bytes, length: length)
    }
}

extension NSData {
    
    /* Create an NSData from a Base-64 encoded NSString using the given options. By default, returns nil when the input is not recognized as valid Base-64.
    */
    public convenience init?(base64Encoded base64String: String, options: Base64DecodingOptions) {
        let encodedBytes = Array(base64String.utf8)
        guard let decodedBytes = NSData.base64DecodeBytes(encodedBytes, options: options) else {
            return nil
        }
        self.init(bytes: decodedBytes, length: decodedBytes.count)
    }
    
    /* Create a Base-64 encoded NSString from the receiver's contents using the given options.
    */
    public func base64EncodedString(_ options: Base64EncodingOptions = []) -> String {
        var decodedBytes = [UInt8](repeating: 0, count: self.length)
        getBytes(&decodedBytes, length: decodedBytes.count)
        let encodedBytes = NSData.base64EncodeBytes(decodedBytes, options: options)
        let characters = encodedBytes.map { Character(UnicodeScalar($0)) }
        return String(characters)
    }
    
    /* Create an NSData from a Base-64, UTF-8 encoded NSData. By default, returns nil when the input is not recognized as valid Base-64.
    */
    public convenience init?(base64Encoded base64Data: Data, options: Base64DecodingOptions) {
        var encodedBytes = [UInt8](repeating: 0, count: base64Data.count)
        base64Data._nsObject.getBytes(&encodedBytes, length: encodedBytes.count)
        guard let decodedBytes = NSData.base64DecodeBytes(encodedBytes, options: options) else {
            return nil
        }
        self.init(bytes: decodedBytes, length: decodedBytes.count)
    }
    
    /* Create a Base-64, UTF-8 encoded NSData from the receiver's contents using the given options.
    */
    public func base64EncodedData(_ options: Base64EncodingOptions = []) -> Data {
        var decodedBytes = [UInt8](repeating: 0, count: self.length)
        getBytes(&decodedBytes, length: decodedBytes.count)
        let encodedBytes = NSData.base64EncodeBytes(decodedBytes, options: options)
        return Data(bytes: encodedBytes, count: encodedBytes.count)
    }
    
    /**
      The ranges of ASCII characters that are used to encode data in Base64.
      */
    private static let base64ByteMappings: [Range<UInt8>] = [
        65 ..< 91,      // A-Z
        97 ..< 123,     // a-z
        48 ..< 58,      // 0-9
        43 ..< 44,      // +
        47 ..< 48,      // /
    ]
    /**
     Padding character used when the number of bytes to encode is not divisible by 3
     */
    private static let base64Padding : UInt8 = 61 // =
    
    /**
        This method takes a byte with a character from Base64-encoded string
        and gets the binary value that the character corresponds to.
     
        - parameter byte:       The byte with the Base64 character.
        - returns:              Base64DecodedByte value containing the result (Valid , Invalid, Padding)
        */
    private enum Base64DecodedByte {
        case valid(UInt8)
        case invalid
        case padding
    }
    private static func base64DecodeByte(_ byte: UInt8) -> Base64DecodedByte {
        guard byte != base64Padding else {return .padding}
        var decodedStart: UInt8 = 0
        for range in base64ByteMappings {
            if range.contains(byte) {
                let result = decodedStart + (byte - range.lowerBound)
                return .valid(result)
            }
            decodedStart += range.upperBound - range.lowerBound
        }
        return .invalid
    }
    
    /**
        This method takes six bits of binary data and encodes it as a character
        in Base64.
 
        The value in the byte must be less than 64, because a Base64 character
        can only represent 6 bits.
 
        - parameter byte:       The byte to encode
        - returns:              The ASCII value for the encoded character.
        */
    private static func base64EncodeByte(_ byte: UInt8) -> UInt8 {
        assert(byte < 64)
        var decodedStart: UInt8 = 0
        for range in base64ByteMappings {
            let decodedRange = decodedStart ..< decodedStart + (range.upperBound - range.lowerBound)
            if decodedRange.contains(byte) {
                return range.lowerBound + (byte - decodedStart)
            }
            decodedStart += range.upperBound - range.lowerBound
        }
        return 0
    }
    
    
    /**
        This method decodes Base64-encoded data.
     
        If the input contains any bytes that are not valid Base64 characters,
        this will return nil.
 
        - parameter bytes:      The Base64 bytes
        - parameter options:    Options for handling invalid input
        - returns:              The decoded bytes.
        */
    private static func base64DecodeBytes(_ bytes: [UInt8], options: Base64DecodingOptions = []) -> [UInt8]? {
        var decodedBytes = [UInt8]()
        decodedBytes.reserveCapacity((bytes.count/3)*2)

        var currentByte : UInt8 = 0
        var validCharacterCount = 0
        var paddingCount = 0
        var index = 0
        
        
        for base64Char in bytes {
            
            let value : UInt8
            
            switch base64DecodeByte(base64Char) {
            case .valid(let v):
                value = v
                validCharacterCount += 1
            case .invalid:
                if options.contains(.ignoreUnknownCharacters) {
                    continue
                } else {
                    return nil
                }
            case .padding:
                paddingCount += 1
                continue
            }
            
            //padding found in the middle of the sequence is invalid
            if paddingCount > 0 {
                return nil
            }
            
            switch index%4 {
            case 0:
                currentByte = (value << 2)
            case 1:
                currentByte |= (value >> 4)
                decodedBytes.append(currentByte)
                currentByte = (value << 4)
            case 2:
                currentByte |= (value >> 2)
                decodedBytes.append(currentByte)
                currentByte = (value << 6)
            case 3:
                currentByte |= value
                decodedBytes.append(currentByte)
            default:
                fatalError()
            }
            
            index += 1
        }
        
        guard (validCharacterCount + paddingCount)%4 == 0 else {
            //invalid character count
            return nil
        }
        return decodedBytes
    }
    
    
    /**
        This method encodes data in Base64.
     
        - parameter bytes:      The bytes you want to encode
        - parameter options:    Options for formatting the result
        - returns:              The Base64-encoding for those bytes.
        */
    private static func base64EncodeBytes(_ bytes: [UInt8], options: Base64EncodingOptions = []) -> [UInt8] {
        var result = [UInt8]()
        result.reserveCapacity((bytes.count/3)*4)
        
        let lineOptions : (lineLength : Int, separator : [UInt8])? = {
            let lineLength: Int
            
            if options.contains(.encoding64CharacterLineLength) { lineLength = 64 }
            else if options.contains(.encoding76CharacterLineLength) { lineLength = 76 }
            else {
                return nil
            }
            
            var separator = [UInt8]()
            if options.contains(.encodingEndLineWithCarriageReturn) { separator.append(13) }
            if options.contains(.encodingEndLineWithLineFeed) { separator.append(10) }
            
            //if the kind of line ending to insert is not specified, the default line ending is Carriage Return + Line Feed.
            if separator.count == 0 {separator = [13,10]}
            
            return (lineLength,separator)
        }()
        
        var currentLineCount = 0
        let appendByteToResult : (UInt8) -> () = {
            result.append($0)
            currentLineCount += 1
            if let options = lineOptions, currentLineCount == options.lineLength {
                result.append(contentsOf: options.separator)
                currentLineCount = 0
            }
        }
        
        var currentByte : UInt8 = 0
        
        for (index,value) in bytes.enumerated() {
            switch index%3 {
            case 0:
                currentByte = (value >> 2)
                appendByteToResult(NSData.base64EncodeByte(currentByte))
                currentByte = ((value << 6) >> 2)
            case 1:
                currentByte |= (value >> 4)
                appendByteToResult(NSData.base64EncodeByte(currentByte))
                currentByte = ((value << 4) >> 2)
            case 2:
                currentByte |= (value >> 6)
                appendByteToResult(NSData.base64EncodeByte(currentByte))
                currentByte = ((value << 2) >> 2)
                appendByteToResult(NSData.base64EncodeByte(currentByte))
            default:
                fatalError()
            }
        }
        //add padding
        switch bytes.count%3 {
        case 0: break //no padding needed
        case 1:
            appendByteToResult(NSData.base64EncodeByte(currentByte))
            appendByteToResult(self.base64Padding)
            appendByteToResult(self.base64Padding)
        case 2:
            appendByteToResult(NSData.base64EncodeByte(currentByte))
            appendByteToResult(self.base64Padding)
        default:
            fatalError()
        }
        return result
    }
}

extension NSMutableData {

    public func append(_ bytes: UnsafeRawPointer, length: Int) {
        let bytePtr = bytes.bindMemory(to: UInt8.self, capacity: length)
        CFDataAppendBytes(_cfMutableObject, bytePtr, length)
    }
    
    public func append(_ other: Data) {
        let otherLength = other.count
        other.withUnsafeBytes {
            append($0, length: otherLength)
        }
        
    }
    
    public func increaseLength(by extraLength: Int) {
        CFDataSetLength(_cfMutableObject, CFDataGetLength(_cfObject) + extraLength)
    }
    
    public func replaceBytes(in range: NSRange, withBytes bytes: UnsafeRawPointer) {
        let bytePtr = bytes.bindMemory(to: UInt8.self, capacity: length)
        CFDataReplaceBytes(_cfMutableObject, CFRangeMake(range.location, range.length), bytePtr, length)
    }
    
    public func resetBytes(in range: NSRange) {
        bzero(mutableBytes.advanced(by: range.location), range.length)
    }
    
    public func setData(_ data: Data) {
        length = data.count
        data.withUnsafeBytes {
            replaceBytes(in: NSMakeRange(0, length), withBytes: $0)
        }
        
    }
    
    public func replaceBytes(in range: NSRange, withBytes replacementBytes: UnsafeRawPointer, length replacementLength: Int) {
        let bytePtr = replacementBytes.bindMemory(to: UInt8.self, capacity: replacementLength)
        CFDataReplaceBytes(_cfMutableObject, CFRangeMake(range.location, range.length), bytePtr, replacementLength)
    }
}

extension NSMutableData {
    
    public convenience init?(capacity: Int) {
        self.init(bytes: nil, length: 0)
    }
    
    public convenience init?(length: Int) {
        self.init(bytes: nil, length: 0)
        self.length = length
    }
}

extension NSData : _StructTypeBridgeable {
    public typealias _StructType = Data
    public func _bridgeToSwift() -> Data {
        return Data._unconditionallyBridgeFromObjectiveC(self)
    }
}
