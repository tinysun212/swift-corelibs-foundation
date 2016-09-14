// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    import Foundation
    import XCTest
#else
    import SwiftFoundation
    import SwiftXCTest
#endif


class TestNSThread : XCTestCase {
    static var allTests: [(String, (TestNSThread) -> () throws -> Void)] {
        return [
            ("test_currentThread", test_currentThread ),
            ("test_threadStart", test_threadStart),
        ]
    }

    func test_currentThread() {
        let thread1 = Thread.current
        let thread2 = Thread.current
        XCTAssertNotNil(thread1)
        XCTAssertNotNil(thread2)
        XCTAssertEqual(thread1, thread2)
    }
    
    func test_threadStart() {
        var started = false
        let condition = NSCondition()
        let thread = Thread() {
            condition.lock()
            started = true
            condition.broadcast()
            condition.unlock()
        }
        thread.start()
        
        condition.lock()
        if !started {
            condition.wait()
        }
        condition.unlock()
        XCTAssertTrue(started)
    }
}
