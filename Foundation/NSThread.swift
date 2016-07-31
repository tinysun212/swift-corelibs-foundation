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

// for some reason having this take a generic causes a crash...
private func _compiler_crash_fix(_ key: _CFThreadSpecificKey, _ value: AnyObject?) {
    _CThreadSpecificSet(key, value)
}

internal class NSThreadSpecific<T: NSObject> {
    private var key = _CFThreadSpecificKeyCreate()
    
    internal func get(_ generator: (Void) -> T) -> T {
        if let specific = _CFThreadSpecificGet(key) {
            return specific as! T
        } else {
            let value = generator()
            _compiler_crash_fix(key, value)
            return value
        }
    }
    
    internal func set(_ value: T) {
        _compiler_crash_fix(key, value)
    }
}

internal enum _NSThreadStatus {
    case initialized
    case starting
    case executing
    case finished
}

private func NSThreadStart(_ context: UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer? {
    let thread: Thread = NSObject.unretainedReference(context!)
    Thread._currentThread.set(thread)
    thread._status = .executing
    thread.main()
    thread._status = .finished
    Thread.releaseReference(context!)
    return nil
}

public class Thread: NSObject {
    
    static internal var _currentThread = NSThreadSpecific<Thread>()
    public static var current: Thread {
        return Thread._currentThread.get() {
            return Thread(thread: pthread_self())
        }
    }

    /// Alternative API for detached thread creation
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative to creation via selector
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public class func detachNewThread(_ main: (Void) -> Void) {
        let t = Thread(main)
        t.start()
    }
    
    public class func isMultiThreaded() -> Bool {
        return true
    }
    
    public class func sleepUntilDate(_ date: Date) {
        let start_ut = CFGetSystemUptime()
        let start_at = CFAbsoluteTimeGetCurrent()
        let end_at = date.timeIntervalSinceReferenceDate
        var ti = end_at - start_at
        let end_ut = start_ut + ti
        while (0.0 < ti) {
            var __ts__ = timespec(tv_sec: LONG_MAX, tv_nsec: 0)
            if ti < Double(LONG_MAX) {
                var integ = 0.0
                let frac: Double = withUnsafeMutablePointer(to: &integ) { integp in
                    return modf(ti, integp)
                }
                __ts__.tv_sec = Int(integ)
                __ts__.tv_nsec = Int(frac * 1000000000.0)
            }
            let _ = withUnsafePointer(to: &__ts__) { ts in
                nanosleep(ts, nil)
            }
            ti = end_ut - CFGetSystemUptime()
        }
    }

    public class func sleepForTimeInterval(_ interval: TimeInterval) {
        var ti = interval
        let start_ut = CFGetSystemUptime()
        let end_ut = start_ut + ti
        while 0.0 < ti {
            var __ts__ = timespec(tv_sec: LONG_MAX, tv_nsec: 0)
            if ti < Double(LONG_MAX) {
                var integ = 0.0
                let frac: Double = withUnsafeMutablePointer(to: &integ) { integp in
                    return modf(ti, integp)
                }
                __ts__.tv_sec = Int(integ)
                __ts__.tv_nsec = Int(frac * 1000000000.0)
            }
            let _ = withUnsafePointer(to: &__ts__) { ts in
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
    internal var _status = _NSThreadStatus.initialized
    internal var _cancelled = false
    /// - Note: this differs from the Darwin implementation in that the keys must be Strings
    public var threadDictionary = [String:AnyObject]()
    
    internal init(thread: pthread_t) {
        // Note: even on Darwin this is a non-optional pthread_t; this is only used for valid threads, which are never null pointers.
        _thread = thread
    }

    public init(_ main: (Void) -> Void) {
        _main = main
        let _ = withUnsafeMutablePointer(to: &_attr) { attr in
            pthread_attr_init(attr)
            pthread_attr_setscope(attr, Int32(PTHREAD_SCOPE_SYSTEM))
            pthread_attr_setdetachstate(attr, Int32(PTHREAD_CREATE_DETACHED))
        }
    }

    public func start() {
        precondition(_status == .initialized, "attempting to start a thread that has already been started")
        _status = .starting
        if _cancelled {
            _status = .finished
            return
        }
#if IS_CYGWIN
        if let attr = self._attr {
            _thread = self.withRetainedReference {
              return _CFThreadCreate(attr, NSThreadStart, $0)
            }
        } else {
            _thread = nil
        }
#else
        _thread = self.withRetainedReference {
            return _CFThreadCreate(self._attr, NSThreadStart, $0)
        }
#endif
    }
    
    public func main() {
        _main()
    }

    public var stackSize: Int {
        get {
            var size: Int = 0
            return withUnsafeMutablePointer(to: &_attr) { attr in
                withUnsafeMutablePointer(to: &size) { sz in
                    pthread_attr_getstacksize(attr, sz)
                    return sz.pointee
                }
            }
        }
        set {
            // just don't allow a stack size more than 1GB on any platform
            var s = newValue
            if (1 << 30) < s {
                s = 1 << 30
            }
            let _ = withUnsafeMutablePointer(to: &_attr) { attr in
                pthread_attr_setstacksize(attr, s)
            }
        }
    }

    public var executing: Bool {
        return _status == .executing
    }

    public var finished: Bool {
        return _status == .finished
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
