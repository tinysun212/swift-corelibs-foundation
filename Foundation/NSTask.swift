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

extension Task {
    public enum TerminationReason : Int {
        case exit
        case uncaughtSignal
    }
}

private func WEXITSTATUS(_ status: CInt) -> CInt {
    return (status >> 8) & 0xff
}

private var managerThreadRunLoop : RunLoop? = nil
private var managerThreadRunLoopIsRunning = false
private var managerThreadRunLoopIsRunningCondition = NSCondition()

#if os(OSX) || os(iOS)
internal let kCFSocketDataCallBack = CFSocketCallBackType.dataCallBack.rawValue
#endif

private func emptyRunLoopCallback(_ context : UnsafeMutableRawPointer?) -> Void {}


// Retain method for run loop source
private func runLoopSourceRetain(_ pointer : UnsafeRawPointer?) -> UnsafeRawPointer? {
    let ref = Unmanaged<AnyObject>.fromOpaque(pointer!).takeUnretainedValue()
    let retained = Unmanaged<AnyObject>.passRetained(ref)
    return unsafeBitCast(retained, to: UnsafeRawPointer.self)
}

// Release method for run loop source
private func runLoopSourceRelease(_ pointer : UnsafeRawPointer?) -> Void {
    Unmanaged<AnyObject>.fromOpaque(pointer!).release()
}

// Equal method for run loop source

private func runloopIsEqual(_ a : UnsafeRawPointer?, _ b : UnsafeRawPointer?) -> _DarwinCompatibleBoolean {
    
    let unmanagedrunLoopA = Unmanaged<AnyObject>.fromOpaque(a!)
    guard let runLoopA = unmanagedrunLoopA.takeUnretainedValue() as? RunLoop else {
        return false
    }
    
    let unmanagedRunLoopB = Unmanaged<AnyObject>.fromOpaque(a!)
    guard let runLoopB = unmanagedRunLoopB.takeUnretainedValue() as? RunLoop else {
        return false
    }
    
    guard runLoopA == runLoopB else {
        return false
    }
    
    return true
}


// Equal method for task in run loop source
private func nstaskIsEqual(_ a : UnsafeRawPointer?, _ b : UnsafeRawPointer?) -> _DarwinCompatibleBoolean {
    
    let unmanagedTaskA = Unmanaged<AnyObject>.fromOpaque(a!)
    guard let taskA = unmanagedTaskA.takeUnretainedValue() as? Task else {
        return false
    }
    
    let unmanagedTaskB = Unmanaged<AnyObject>.fromOpaque(a!)
    guard let taskB = unmanagedTaskB.takeUnretainedValue() as? Task else {
        return false
    }
    
    guard taskA == taskB else {
        return false
    }
    
    return true
}

open class Task: NSObject {
    private static func setup() {
        struct Once {
            static var done = false
            static let lock = NSLock()
        }
        Once.lock.synchronized {
            if !Once.done {
                let thread = Thread {
                    managerThreadRunLoop = RunLoop.current()
                    var emptySourceContext = CFRunLoopSourceContext()
                    emptySourceContext.version = 0
                    emptySourceContext.retain = runLoopSourceRetain
                    emptySourceContext.release = runLoopSourceRelease
                    emptySourceContext.equal = runloopIsEqual
                    emptySourceContext.perform = emptyRunLoopCallback
                    managerThreadRunLoop!.withUnretainedReference {
                        (refPtr: UnsafeMutablePointer<UInt8>) in
                        emptySourceContext.info = UnsafeMutableRawPointer(refPtr)
                    }
                    
                    CFRunLoopAddSource(managerThreadRunLoop?._cfRunLoop, CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &emptySourceContext), kCFRunLoopDefaultMode)
                    
                    managerThreadRunLoopIsRunningCondition.lock()
                    
                    CFRunLoopPerformBlock(managerThreadRunLoop?._cfRunLoop, kCFRunLoopDefaultMode) {
                        managerThreadRunLoopIsRunning = true
                        managerThreadRunLoopIsRunningCondition.broadcast()
                        managerThreadRunLoopIsRunningCondition.unlock()
                    }
                    
                    managerThreadRunLoop?.run()
                    fatalError("NSTask manager run loop exited unexpectedly; it should run forever once initialized")
                }
                thread.start()
                managerThreadRunLoopIsRunningCondition.lock()
                while managerThreadRunLoopIsRunning == false {
                    managerThreadRunLoopIsRunningCondition.wait()
                }
                managerThreadRunLoopIsRunningCondition.unlock()
                Once.done = true
            }
        }
    }
    
    // Create an NSTask which can be run at a later time
    // An NSTask can only be run once. Subsequent attempts to
    // run an NSTask will raise.
    // Upon task death a notification will be sent
    //   { Name = NSTaskDidTerminateNotification; object = task; }
    //
    
    public override init() {
    
    }
    
    // these methods can only be set before a launch
    open var launchPath: String?
    open var arguments: [String]?
    open var environment: [String : String]? // if not set, use current
    
    open var currentDirectoryPath: String = FileManager.default.currentDirectoryPath
    
    // standard I/O channels; could be either an NSFileHandle or an NSPipe
    open var standardInput: AnyObject? {
        willSet {
            precondition(newValue is Pipe || newValue is FileHandle,
                         "standardInput must be either NSPipe or NSFileHandle")
        }
    }
    open var standardOutput: AnyObject? {
        willSet {
            precondition(newValue is Pipe || newValue is FileHandle,
                         "standardOutput must be either NSPipe or NSFileHandle")
        }
    }
    open var standardError: AnyObject? {
        willSet {
            precondition(newValue is Pipe || newValue is FileHandle,
                         "standardError must be either NSPipe or NSFileHandle")
        }
    }
    
    private var runLoopSourceContext : CFRunLoopSourceContext?
    private var runLoopSource : CFRunLoopSource?
    
    fileprivate weak var runLoop : RunLoop? = nil
    
    private var processLaunchedCondition = NSCondition()
    
    // actions
    open func launch() {
        
        self.processLaunchedCondition.lock()
    
        // Dispatch the manager thread if it isn't already running
        
        Task.setup()
        
        // Ensure that the launch path is set
        
        guard let launchPath = self.launchPath else {
            fatalError()
        }
        
        // Convert the arguments array into a posix_spawn-friendly format
        
        var args = [launchPath]
        if let arguments = self.arguments {
            args.append(contentsOf: arguments)
        }
        
        let argv : UnsafeMutablePointer<UnsafeMutablePointer<Int8>?> = args.withUnsafeBufferPointer {
            let array : UnsafeBufferPointer<String> = $0
            let buffer = UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>.allocate(capacity: array.count + 1)
            buffer.initialize(from: array.map { $0.withCString(strdup) })
            buffer[array.count] = nil
            return buffer
        }
        
        defer {
            for arg in argv ..< argv + args.count {
                free(UnsafeMutableRawPointer(arg.pointee))
            }
            
            argv.deallocate(capacity: args.count + 1)
        }
        
        let envp: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>
        
        if let env = environment {
            let nenv = env.count
            envp = UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>.allocate(capacity: 1 + nenv)
            envp.initialize(from: env.map { strdup("\($0)=\($1)") })
            envp[env.count] = nil
        } else {
            envp = _CFEnviron()
        }

        defer {
            if let env = environment {
                for pair in envp ..< envp + env.count {
                    free(UnsafeMutableRawPointer(pair.pointee))
                }
                envp.deallocate(capacity: env.count + 1)
            }
        }

        var taskSocketPair : [Int32] = [0, 0]
        socketpair(AF_UNIX, _CF_SOCK_STREAM(), 0, &taskSocketPair)
        var context = CFSocketContext()
        context.version = 0
        context.retain = runLoopSourceRetain
        context.release = runLoopSourceRelease
	context.info = Unmanaged.passUnretained(self).toOpaque()
        
        let socket = CFSocketCreateWithNative( nil, taskSocketPair[0], CFOptionFlags(kCFSocketDataCallBack), {
            (socket, type, address, data, info )  in
            
            let task: Task = NSObject.unretainedReference(info!)
            
            task.processLaunchedCondition.lock()
            while task.running == false {
                task.processLaunchedCondition.wait()
            }
            
            task.processLaunchedCondition.unlock()
            
            var exitCode : Int32 = 0
#if CYGWIN
            let exitCodePtrWrapper = withUnsafeMutablePointer(to: &exitCode) {
                exitCodePtr in
                __wait_status_ptr_t(__int_ptr: exitCodePtr)
            }
#endif
            var waitResult : Int32 = 0
            
            repeat {
#if CYGWIN
                waitResult = waitpid( task.processIdentifier, exitCodePtrWrapper, 0)
#else
                waitResult = waitpid( task.processIdentifier, &exitCode, 0)
#endif
            } while ( (waitResult == -1) && (errno == EINTR) )
            
            task.terminationStatus = WEXITSTATUS( exitCode )
            
            // If a termination handler has been set, invoke it on a background thread
            
            if task.terminationHandler != nil {
                let thread = Thread {
                    task.terminationHandler!(task)
                }
                thread.start()
            }
            
            // Set the running flag to false
            
            task.running = false
            
            // Invalidate the source and wake up the run loop, if it's available
            
            CFRunLoopSourceInvalidate(task.runLoopSource)
            if let runLoop = task.runLoop {
                CFRunLoopWakeUp(runLoop._cfRunLoop)
            }
            
            CFSocketInvalidate( socket )
            
            }, &context )
        
        CFSocketSetSocketFlags( socket, CFOptionFlags(kCFSocketCloseOnInvalidate))
        
        let source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, socket, 0)
        CFRunLoopAddSource(managerThreadRunLoop?._cfRunLoop, source, kCFRunLoopDefaultMode)

        // file_actions
        #if os(OSX) || os(iOS) || CYGWIN
            var fileActions: posix_spawn_file_actions_t? = nil
        #else
            var fileActions: posix_spawn_file_actions_t = posix_spawn_file_actions_t()
        #endif
        posix(posix_spawn_file_actions_init(&fileActions))
        defer { posix_spawn_file_actions_destroy(&fileActions) }

        // File descriptors to duplicate in the child process. This allows
        // output redirection to NSPipe or NSFileHandle.
        var adddup2 = [Int32: Int32]()

        // File descriptors to close in the child process. A set so that
        // shared pipes only get closed once. Would result in EBADF on OSX
        // otherwise.
        var addclose = Set<Int32>()

        switch standardInput {
        case let pipe as Pipe:
            adddup2[STDIN_FILENO] = pipe.fileHandleForReading.fileDescriptor
            addclose.insert(pipe.fileHandleForWriting.fileDescriptor)
        case let handle as FileHandle:
            adddup2[STDIN_FILENO] = handle.fileDescriptor
        default: break
        }

        switch standardOutput {
        case let pipe as Pipe:
            adddup2[STDOUT_FILENO] = pipe.fileHandleForWriting.fileDescriptor
            addclose.insert(pipe.fileHandleForReading.fileDescriptor)
        case let handle as FileHandle:
            adddup2[STDOUT_FILENO] = handle.fileDescriptor
        default: break
        }

        switch standardError {
        case let pipe as Pipe:
            adddup2[STDERR_FILENO] = pipe.fileHandleForWriting.fileDescriptor
            addclose.insert(pipe.fileHandleForReading.fileDescriptor)
        case let handle as FileHandle:
            adddup2[STDERR_FILENO] = handle.fileDescriptor
        default: break
        }

        for (new, old) in adddup2 {
            posix(posix_spawn_file_actions_adddup2(&fileActions, old, new))
        }
        for fd in addclose {
            posix(posix_spawn_file_actions_addclose(&fileActions, fd))
        }

        // Launch

        var pid = pid_t()
        posix(posix_spawn(&pid, launchPath, &fileActions, nil, argv, envp))

        // Close the write end of the input and output pipes.
        if let pipe = standardInput as? Pipe {
            pipe.fileHandleForReading.closeFile()
        }
        if let pipe = standardOutput as? Pipe {
            pipe.fileHandleForWriting.closeFile()
        }
        if let pipe = standardError as? Pipe {
            pipe.fileHandleForWriting.closeFile()
        }

        close(taskSocketPair[1])
        
        self.runLoop = RunLoop.current()
        self.runLoopSourceContext = CFRunLoopSourceContext(version: 0,
                                                           info: Unmanaged.passUnretained(self).toOpaque(),
                                                           retain: { return runLoopSourceRetain($0) },
                                                           release: { runLoopSourceRelease($0) },
                                                           copyDescription: nil,
                                                           equal: { return nstaskIsEqual($0, $1) },
                                                           hash: nil,
                                                           schedule: nil,
                                                           cancel: nil,
                                                           perform: { emptyRunLoopCallback($0) }
        )
        
        var runLoopContext = CFRunLoopSourceContext()
        runLoopContext.version = 0
        runLoopContext.retain = runLoopSourceRetain
        runLoopContext.release = runLoopSourceRelease
        runLoopContext.equal = nstaskIsEqual
        runLoopContext.perform = emptyRunLoopCallback
        self.withUnretainedReference {
            (refPtr: UnsafeMutablePointer<UInt8>) in
            runLoopContext.info = UnsafeMutableRawPointer(refPtr)
        }
        self.runLoopSourceContext = runLoopContext
        
        self.runLoopSource = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &runLoopSourceContext!)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopDefaultMode)
        
        running = true
        
        self.processIdentifier = pid
        
        self.processLaunchedCondition.unlock()
        self.processLaunchedCondition.broadcast()
    }
    
    open func interrupt() { NSUnimplemented() } // Not always possible. Sends SIGINT.
    open func terminate()  { NSUnimplemented() }// Not always possible. Sends SIGTERM.
    
    open func suspend() -> Bool { NSUnimplemented() }
    open func resume() -> Bool { NSUnimplemented() }
    
    // status
    open private(set) var processIdentifier: Int32 = -1
    open private(set) var running: Bool = false
    
    open private(set) var terminationStatus: Int32 = 0
    open var terminationReason: TerminationReason { NSUnimplemented() }
    
    /*
    A block to be invoked when the process underlying the NSTask terminates.  Setting the block to nil is valid, and stops the previous block from being invoked, as long as it hasn't started in any way.  The NSTask is passed as the argument to the block so the block does not have to capture, and thus retain, it.  The block is copied when set.  Only one termination handler block can be set at any time.  The execution context in which the block is invoked is undefined.  If the NSTask has already finished, the block is executed immediately/soon (not necessarily on the current thread).  If a terminationHandler is set on an NSTask, the NSTaskDidTerminateNotification notification is not posted for that task.  Also note that -waitUntilExit won't wait until the terminationHandler has been fully executed.  You cannot use this property in a concrete subclass of NSTask which hasn't been updated to include an implementation of the storage and use of it.  
    */
    open var terminationHandler: ((Task) -> Void)?
    open var qualityOfService: NSQualityOfService = .default  // read-only after the task is launched
}

extension Task {
    
    // convenience; create and launch
    open class func launchedTaskWithLaunchPath(_ path: String, arguments: [String]) -> Task {
        let task = Task()
        task.launchPath = path
        task.arguments = arguments
        task.launch()
    
        return task
    }
    
    // poll the runLoop in defaultMode until task completes
    open func waitUntilExit() {
        
        repeat {
            
        } while( self.running == true && RunLoop.current().run(mode: .defaultRunLoopMode, before: Date(timeIntervalSinceNow: 0.05)) )
        
        self.runLoop = nil
    }
}

public let NSTaskDidTerminateNotification: String = "NSTaskDidTerminateNotification"

private func posix(_ code: Int32) {
    switch code {
    case 0: return
    case EBADF: fatalError("POSIX command failed with error: \(code) -- EBADF")
    default: fatalError("POSIX command failed with error: \(code)")
    }
}
