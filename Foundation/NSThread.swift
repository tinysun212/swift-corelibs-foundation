// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


#if os(OSX) || os(iOS)
import Darwin
#elseif os(Linux) || IS_CYGWIN
import Glibc
#endif

import CoreFoundation

private func disposeTLS(_ ctx: UnsafeMutablePointer<Void>?) -> Void {
    Unmanaged<AnyObject>.fromOpaque(OpaquePointer(ctx!)).release()
}

internal class NSThreadSpecific<T: AnyObject> {

    private var NSThreadSpecificKeySet = false
    private var NSThreadSpecificKeyLock = NSLock()
#if IS_CYGWIN
    private var NSThreadSpecificKey : pthread_key_t? = nil
#else
    private var NSThreadSpecificKey = pthread_key_t()
#endif

    private var key: pthread_key_t {
        NSThreadSpecificKeyLock.lock()
        if !NSThreadSpecificKeySet {
            withUnsafeMutablePointer(&NSThreadSpecificKey) { key in
                NSThreadSpecificKeySet = pthread_key_create(key, disposeTLS) == 0
            }
        }
        NSThreadSpecificKeyLock.unlock()
#if IS_CYGWIN
        return NSThreadSpecificKey!
#else
        return NSThreadSpecificKey
#endif
    }
    
    internal func get(_ generator: (Void) -> T) -> T {
        let specific = pthread_getspecific(self.key)
        if specific != nil {
            return Unmanaged<T>.fromOpaque(OpaquePointer(specific!)).takeUnretainedValue()
        } else {
            let value = generator()
            pthread_setspecific(self.key, UnsafePointer<Void>(OpaquePointer(bitPattern: Unmanaged<AnyObject>.passRetained(value))))
            return value
        }
    }
    
    internal func set(_ value: T) {
        let specific = pthread_getspecific(self.key)
        var previous: Unmanaged<T>?
        if specific != nil {
            previous = Unmanaged<T>.fromOpaque(OpaquePointer(specific!))
        }
        if let prev = previous {
            if prev.takeUnretainedValue() === value {
                return
            }
        }
        pthread_setspecific(self.key, UnsafePointer<Void>(OpaquePointer(bitPattern: Unmanaged<AnyObject>.passRetained(value))))
        if let prev = previous {
            prev.release()
        }
    }
}

internal enum _NSThreadStatus {
    case Initialized
    case Starting
    case Executing
    case Finished
}

private func NSThreadStart(_ context: UnsafeMutablePointer<Void>?) -> UnsafeMutablePointer<Void>? {
    let unmanaged: Unmanaged<NSThread> = Unmanaged.fromOpaque(OpaquePointer(context!))
    let thread = unmanaged.takeUnretainedValue()
    NSThread._currentThread.set(thread)
    thread._status = _NSThreadStatus.Executing
    thread.main()
    thread._status = _NSThreadStatus.Finished
    unmanaged.release()
    return nil
}

public class NSThread : NSObject {
    
    static internal var _currentThread = NSThreadSpecific<NSThread>()
    public static func currentThread() -> NSThread {
        return NSThread._currentThread.get() {
            return NSThread(thread: pthread_self())
        }
    }

    /// Alternative API for detached thread creation
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative to creation via selector
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public class func detachNewThread(_ main: (Void) -> Void) {
        let t = NSThread(main)
        t.start()
    }
    
    public class func isMultiThreaded() -> Bool {
        return true
    }
    
    public class func sleepUntilDate(_ date: NSDate) {
        let start_ut = CFGetSystemUptime()
        let start_at = CFAbsoluteTimeGetCurrent()
        let end_at = date.timeIntervalSinceReferenceDate
        var ti = end_at - start_at
        let end_ut = start_ut + ti
        while (0.0 < ti) {
            var __ts__ = timespec(tv_sec: LONG_MAX, tv_nsec: 0)
            if ti < Double(LONG_MAX) {
                var integ = 0.0
                let frac: Double = withUnsafeMutablePointer(&integ) { integp in
                    return modf(ti, integp)
                }
                __ts__.tv_sec = Int(integ)
                __ts__.tv_nsec = Int(frac * 1000000000.0)
            }
            withUnsafePointer(&__ts__) { ts in
                nanosleep(ts, nil)
            }
            ti = end_ut - CFGetSystemUptime()
        }
    }
    
    public class func sleepForTimeInterval(_ interval: NSTimeInterval) {
        var ti = interval
        let start_ut = CFGetSystemUptime()
        let end_ut = start_ut + ti
        while 0.0 < ti {
            var __ts__ = timespec(tv_sec: LONG_MAX, tv_nsec: 0)
            if ti < Double(LONG_MAX) {
                var integ = 0.0
                let frac: Double = withUnsafeMutablePointer(&integ) { integp in
                    return modf(ti, integp)
                }
                __ts__.tv_sec = Int(integ)
                __ts__.tv_nsec = Int(frac * 1000000000.0)
            }
            withUnsafePointer(&__ts__) { ts in
                nanosleep(ts, nil)
            }
            ti = end_ut - CFGetSystemUptime()
        }
    }
    
    public class func exit() {
        pthread_exit(nil)
    }
    
    internal var _main: (Void) -> Void = {}
#if os(OSX) || os(iOS) || IS_CYGWIN
    private var _thread: pthread_t? = nil
#elseif os(Linux)
    private var _thread = pthread_t()
#endif
#if IS_CYGWIN
    internal var _attr : pthread_attr_t? = nil
#else
    internal var _attr = pthread_attr_t()
#endif
    internal var _status = _NSThreadStatus.Initialized
    internal var _cancelled = false
    /// - Note: this differs from the Darwin implementation in that the keys must be Strings
    public var threadDictionary = [String:AnyObject]()
    
    internal init(thread: pthread_t) {
        // Note: even on Darwin this is a non-optional pthread_t; this is only used for valid threads, which are never null pointers.
        _thread = thread
    }
    
    public init(_ main: (Void) -> Void) {
        _main = main
        withUnsafeMutablePointer(&_attr) { attr in
            pthread_attr_init(attr)
        }
    }
    
    public func start() {
        precondition(_status == .Initialized, "attempting to start a thread that has already been started")
        _status = .Starting
        if _cancelled {
            _status = .Finished
            return
        }
        withUnsafeMutablePointers(&_thread, &_attr) { thread, attr in
            let ptr = Unmanaged.passRetained(self)
            pthread_create(thread, attr, NSThreadStart, UnsafeMutablePointer(OpaquePointer(bitPattern: ptr)))
        }
    }
    
    public func main() {
        _main()
    }

    public var stackSize: Int {
        get {
            var size: Int = 0
            return withUnsafeMutablePointers(&_attr, &size) { attr, sz in
                pthread_attr_getstacksize(attr, sz)
                return sz.pointee
            }
        }
        set {
            // just don't allow a stack size more than 1GB on any platform
            var s = newValue
            if (1 << 30) < s {
                s = 1 << 30
            }
            withUnsafeMutablePointer(&_attr) { attr in
                pthread_attr_setstacksize(attr, s)
            }
        }
    }
    
    public var executing: Bool {
        return _status == .Executing
    }

    public var finished: Bool {
        return _status == .Finished
    }
    
    public var cancelled: Bool {
        return _cancelled
    }
    
    public func cancel() {
        _cancelled = true
    }

    public class func callStackReturnAddresses() -> [NSNumber] {
        NSUnimplemented()
    }
    
    public class func callStackSymbols() -> [String] {
        NSUnimplemented()
    }
}
