// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

/*

 NSURLSession is a replacement API for NSURLConnection.  It provides
 options that affect the policy of, and various aspects of the
 mechanism by which NSURLRequest objects are retrieved from the
 network.

 An NSURLSession may be bound to a delegate object.  The delegate is
 invoked for certain events during the lifetime of a session, such as
 server authentication or determining whether a resource to be loaded
 should be converted into a download.
 
 NSURLSession instances are threadsafe.

 The default NSURLSession uses a system provided delegate and is
 appropriate to use in place of existing code that uses
 +[NSURLConnection sendAsynchronousRequest:queue:completionHandler:]

 An NSURLSession creates NSURLSessionTask objects which represent the
 action of a resource being loaded.  These are analogous to
 NSURLConnection objects but provide for more control and a unified
 delegate model.
 
 NSURLSessionTask objects are always created in a suspended state and
 must be sent the -resume message before they will execute.

 Subclasses of NSURLSessionTask are used to syntactically
 differentiate between data and file downloads.

 An NSURLSessionDataTask receives the resource as a series of calls to
 the URLSession:dataTask:didReceiveData: delegate method.  This is type of
 task most commonly associated with retrieving objects for immediate parsing
 by the consumer.

 An NSURLSessionUploadTask differs from an NSURLSessionDataTask
 in how its instance is constructed.  Upload tasks are explicitly created
 by referencing a file or data object to upload, or by utilizing the
 -URLSession:task:needNewBodyStream: delegate message to supply an upload
 body.

 An NSURLSessionDownloadTask will directly write the response data to
 a temporary file.  When completed, the delegate is sent
 URLSession:downloadTask:didFinishDownloadingToURL: and given an opportunity 
 to move this file to a permanent location in its sandboxed container, or to
 otherwise read the file. If canceled, an NSURLSessionDownloadTask can
 produce a data blob that can be used to resume a download at a later
 time.

 Beginning with iOS 9 and Mac OS X 10.11, NSURLSessionStream is
 available as a task type.  This allows for direct TCP/IP connection
 to a given host and port with optional secure handshaking and
 navigation of proxies.  Data tasks may also be upgraded to a
 NSURLSessionStream task via the HTTP Upgrade: header and appropriate
 use of the pipelining option of NSURLSessionConfiguration.  See RFC
 2817 and RFC 6455 for information about the Upgrade: header, and
 comments below on turning data tasks into stream tasks.
 */

/* DataTask objects receive the payload through zero or more delegate messages */
/* UploadTask objects receive periodic progress updates but do not return a body */
/* DownloadTask objects represent an active download to disk.  They can provide resume data when canceled. */
/* StreamTask objects may be used to create NSInput and NSOutputStreams, or used directly in reading and writing. */

/*

 NSURLSession is not available for i386 targets before Mac OS X 10.10.

 */

public let NSURLSessionTransferSizeUnknown: Int64 = -1

open class URLSession: NSObject {
    
    /*
     * The shared session uses the currently set global NSURLCache,
     * NSHTTPCookieStorage and NSURLCredentialStorage objects.
     */
    open class func sharedSession() -> URLSession { NSUnimplemented() }
    
    /*
     * Customization of NSURLSession occurs during creation of a new session.
     * If you only need to use the convenience routines with custom
     * configuration options it is not necessary to specify a delegate.
     * If you do specify a delegate, the delegate will be retained until after
     * the delegate has been sent the URLSession:didBecomeInvalidWithError: message.
     */
    public /*not inherited*/ init(configuration: URLSessionConfiguration) { NSUnimplemented() }
    public /*not inherited*/ init(configuration: URLSessionConfiguration, delegate: URLSessionDelegate?, delegateQueue queue: OperationQueue?) { NSUnimplemented() }
    
    open var delegateQueue: OperationQueue { NSUnimplemented() }
    open var delegate: URLSessionDelegate? { NSUnimplemented() }
    /*@NSCopying*/ open var configuration: URLSessionConfiguration { NSUnimplemented() }
    
    /*
     * The sessionDescription property is available for the developer to
     * provide a descriptive label for the session.
     */
    open var sessionDescription: String?
    
    /* -finishTasksAndInvalidate returns immediately and existing tasks will be allowed
     * to run to completion.  New tasks may not be created.  The session
     * will continue to make delegate callbacks until URLSession:didBecomeInvalidWithError:
     * has been issued. 
     *
     * -finishTasksAndInvalidate and -invalidateAndCancel do not
     * have any effect on the shared session singleton.
     *
     * When invalidating a background session, it is not safe to create another background
     * session with the same identifier until URLSession:didBecomeInvalidWithError: has
     * been issued.
     */
    open func finishTasksAndInvalidate() { NSUnimplemented() }
    
    /* -invalidateAndCancel acts as -finishTasksAndInvalidate, but issues
     * -cancel to all outstanding tasks for this session.  Note task 
     * cancellation is subject to the state of the task, and some tasks may
     * have already have completed at the time they are sent -cancel. 
     */
    open func invalidateAndCancel() { NSUnimplemented() }
    
    public func resetWithCompletionHandler(_ completionHandler: () -> Void)  { NSUnimplemented() }/* empty all cookies, cache and credential stores, removes disk files, issues -flushWithCompletionHandler:. Invokes completionHandler() on the delegate queue if not nil. */
    public func flushWithCompletionHandler(_ completionHandler: () -> Void)  { NSUnimplemented() }/* flush storage to disk and clear transient network caches.  Invokes completionHandler() on the delegate queue if not nil. */
    
    public func getTasksWithCompletionHandler(_ completionHandler: ([URLSessionDataTask], [URLSessionUploadTask], [URLSessionDownloadTask]) -> Void)  { NSUnimplemented() }/* invokes completionHandler with outstanding data, upload and download tasks. */
    
    public func getAllTasksWithCompletionHandler(_ completionHandler: ([URLSessionTask]) -> Void)  { NSUnimplemented() }/* invokes completionHandler with all outstanding tasks. */
    
    /* 
     * NSURLSessionTask objects are always created in a suspended state and
     * must be sent the -resume message before they will execute.
     */
    
    /* Creates a data task with the given request.  The request may have a body stream. */
    open func dataTaskWithRequest(_ request: URLRequest) -> URLSessionDataTask { NSUnimplemented() }
    
    /* Creates a data task to retrieve the contents of the given URL. */
    open func dataTaskWithURL(_ url: URL) -> URLSessionDataTask { NSUnimplemented() }
    
    /* Creates an upload task with the given request.  The body of the request will be created from the file referenced by fileURL */
    open func uploadTaskWithRequest(_ request: URLRequest, fromFile fileURL: URL) -> URLSessionUploadTask { NSUnimplemented() }
    
    /* Creates an upload task with the given request.  The body of the request is provided from the bodyData. */
    open func uploadTaskWithRequest(_ request: URLRequest, fromData bodyData: Data) -> URLSessionUploadTask { NSUnimplemented() }
    
    /* Creates an upload task with the given request.  The previously set body stream of the request (if any) is ignored and the URLSession:task:needNewBodyStream: delegate will be called when the body payload is required. */
    open func uploadTaskWithStreamedRequest(_ request: URLRequest) -> URLSessionUploadTask { NSUnimplemented() }
    
    /* Creates a download task with the given request. */
    open func downloadTaskWithRequest(_ request: URLRequest) -> URLSessionDownloadTask { NSUnimplemented() }
    
    /* Creates a download task to download the contents of the given URL. */
    open func downloadTaskWithURL(_ url: URL) -> URLSessionDownloadTask { NSUnimplemented() }
    
    /* Creates a download task with the resume data.  If the download cannot be successfully resumed, URLSession:task:didCompleteWithError: will be called. */
    open func downloadTaskWithResumeData(_ resumeData: Data) -> URLSessionDownloadTask { NSUnimplemented() }
    
    /* Creates a bidirectional stream task to a given host and port.
     */
    open func streamTaskWithHostName(_ hostname: String, port: Int) -> URLSessionStreamTask { NSUnimplemented() }
}

/*
 * NSURLSession convenience routines deliver results to 
 * a completion handler block.  These convenience routines
 * are not available to NSURLSessions that are configured
 * as background sessions.
 *
 * Task objects are always created in a suspended state and 
 * must be sent the -resume message before they will execute.
 */
extension URLSession {
    /*
     * data task convenience methods.  These methods create tasks that
     * bypass the normal delegate calls for response and data delivery,
     * and provide a simple cancelable asynchronous interface to receiving
     * data.  Errors will be returned in the NSURLErrorDomain, 
     * see <Foundation/NSURLError.h>.  The delegate, if any, will still be
     * called for authentication challenges.
     */
    public func dataTaskWithRequest(_ request: URLRequest, completionHandler: (Data?, URLResponse?, NSError?) -> Void) -> URLSessionDataTask { NSUnimplemented() }
    public func dataTaskWithURL(_ url: URL, completionHandler: (Data?, URLResponse?, NSError?) -> Void) -> URLSessionDataTask { NSUnimplemented() }
    
    /*
     * upload convenience method.
     */
    public func uploadTaskWithRequest(_ request: URLRequest, fromFile fileURL: NSURL, completionHandler: (Data?, URLResponse?, NSError?) -> Void) -> URLSessionUploadTask { NSUnimplemented() }
    public func uploadTaskWithRequest(_ request: URLRequest, fromData bodyData: Data?, completionHandler: (Data?, URLResponse?, NSError?) -> Void) -> URLSessionUploadTask { NSUnimplemented() }
    
    /*
     * download task convenience methods.  When a download successfully
     * completes, the NSURL will point to a file that must be read or
     * copied during the invocation of the completion routine.  The file
     * will be removed automatically.
     */
    public func downloadTaskWithRequest(_ request: URLRequest, completionHandler: (NSURL?, URLResponse?, NSError?) -> Void) -> URLSessionDownloadTask { NSUnimplemented() }
    public func downloadTaskWithURL(_ url: NSURL, completionHandler: (NSURL?, URLResponse?, NSError?) -> Void) -> URLSessionDownloadTask { NSUnimplemented() }
    public func downloadTaskWithResumeData(_ resumeData: Data, completionHandler: (NSURL?, URLResponse?, NSError?) -> Void) -> URLSessionDownloadTask { NSUnimplemented() }
}

extension URLSessionTask {
    public enum State: Int {
        
        case running /* The task is currently being serviced by the session */
        case suspended
        case canceling /* The task has been told to cancel.  The session will receive a URLSession:task:didCompleteWithError: message. */
        case completed /* The task has completed and the session will receive no more delegate notifications */
    }
}

/*
 * NSURLSessionTask - a cancelable object that refers to the lifetime
 * of processing a given request.
 */

open class URLSessionTask: NSObject, NSCopying {
    
    public override init() {
        NSUnimplemented()
    }
    
    open override func copy() -> AnyObject {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> AnyObject {
        NSUnimplemented()
    }
    
    open var taskIdentifier: Int { NSUnimplemented() } /* an identifier for this task, assigned by and unique to the owning session */
    /*@NSCopying*/ open var originalRequest: URLRequest? { NSUnimplemented() } /* may be nil if this is a stream task */
    /*@NSCopying*/ open var currentRequest: URLRequest? { NSUnimplemented() } /* may differ from originalRequest due to http server redirection */
    /*@NSCopying*/ open var response: URLResponse? { NSUnimplemented() } /* may be nil if no response has been received */
    
    /* Byte count properties may be zero if no body is expected, 
     * or NSURLSessionTransferSizeUnknown if it is not possible 
     * to know how many bytes will be transferred.
     */
    
    /* number of body bytes already received */
    open var countOfBytesReceived: Int64 { NSUnimplemented() }
    
    /* number of body bytes already sent */
    open var countOfBytesSent: Int64 { NSUnimplemented() }
    
    /* number of body bytes we expect to send, derived from the Content-Length of the HTTP request */
    open var countOfBytesExpectedToSend: Int64 { NSUnimplemented() }
    
    /* number of byte bytes we expect to receive, usually derived from the Content-Length header of an HTTP response. */
    open var countOfBytesExpectedToReceive: Int64 { NSUnimplemented() }
    
    /*
     * The taskDescription property is available for the developer to
     * provide a descriptive label for the task.
     */
    open var taskDescription: String?
    
    /* -cancel returns immediately, but marks a task as being canceled.
     * The task will signal -URLSession:task:didCompleteWithError: with an
     * error value of { NSURLErrorDomain, NSURLErrorCancelled }.  In some 
     * cases, the task may signal other work before it acknowledges the 
     * cancelation.  -cancel may be sent to a task that has been suspended.
     */
    open func cancel() { NSUnimplemented() }
    
    /*
     * The current state of the task within the session.
     */
    open var state: State { NSUnimplemented() }
    
    /*
     * The error, if any, delivered via -URLSession:task:didCompleteWithError:
     * This property will be nil in the event that no error occured.
     */
    /*@NSCopying*/ open var error: NSError? { NSUnimplemented() }
    
    /*
     * Suspending a task will prevent the NSURLSession from continuing to
     * load data.  There may still be delegate calls made on behalf of
     * this task (for instance, to report data received while suspending)
     * but no further transmissions will be made on behalf of the task
     * until -resume is sent.  The timeout timer associated with the task
     * will be disabled while a task is suspended. -suspend and -resume are
     * nestable. 
     */
    open func suspend() { NSUnimplemented() }
    open func resume() { NSUnimplemented() }
    
    /*
     * Sets a scaling factor for the priority of the task. The scaling factor is a
     * value between 0.0 and 1.0 (inclusive), where 0.0 is considered the lowest
     * priority and 1.0 is considered the highest.
     *
     * The priority is a hint and not a hard requirement of task performance. The
     * priority of a task may be changed using this API at any time, but not all
     * protocols support this; in these cases, the last priority that took effect
     * will be used.
     *
     * If no priority is specified, the task will operate with the default priority
     * as defined by the constant NSURLSessionTaskPriorityDefault. Two additional
     * priority levels are provided: NSURLSessionTaskPriorityLow and
     * NSURLSessionTaskPriorityHigh, but use is not restricted to these.
     */
    open var priority: Float
}

public let NSURLSessionTaskPriorityDefault: Float = 0.0 // NSUnimplemented
public let NSURLSessionTaskPriorityLow: Float = 0.0 // NSUnimplemented
public let NSURLSessionTaskPriorityHigh: Float = 0.0 // NSUnimplemented

/*
 * An NSURLSessionDataTask does not provide any additional
 * functionality over an NSURLSessionTask and its presence is merely
 * to provide lexical differentiation from download and upload tasks.
 */
open class URLSessionDataTask: URLSessionTask {
}

/*
 * An NSURLSessionUploadTask does not currently provide any additional
 * functionality over an NSURLSessionDataTask.  All delegate messages
 * that may be sent referencing an NSURLSessionDataTask equally apply
 * to NSURLSessionUploadTasks.
 */
open class URLSessionUploadTask: URLSessionDataTask {
}

/*
 * NSURLSessionDownloadTask is a task that represents a download to
 * local storage.
 */
open class URLSessionDownloadTask: URLSessionTask {
    
    /* Cancel the download (and calls the superclass -cancel).  If
     * conditions will allow for resuming the download in the future, the
     * callback will be called with an opaque data blob, which may be used
     * with -downloadTaskWithResumeData: to attempt to resume the download.
     * If resume data cannot be created, the completion handler will be
     * called with nil resumeData.
     */
    public func cancelByProducingResumeData(_ completionHandler: (Data?) -> Void) { NSUnimplemented() }
}

/*
 * An NSURLSessionStreamTask provides an interface to perform reads
 * and writes to a TCP/IP stream created via NSURLSession.  This task
 * may be explicitly created from an NSURLSession, or created as a
 * result of the appropriate disposition response to a
 * -URLSession:dataTask:didReceiveResponse: delegate message.
 * 
 * NSURLSessionStreamTask can be used to perform asynchronous reads
 * and writes.  Reads and writes are enquened and executed serially,
 * with the completion handler being invoked on the sessions delegate
 * queuee.  If an error occurs, or the task is canceled, all
 * outstanding read and write calls will have their completion
 * handlers invoked with an appropriate error.
 *
 * It is also possible to create NSInputStream and NSOutputStream
 * instances from an NSURLSessionTask by sending
 * -captureStreams to the task.  All outstanding read and writess are
 * completed before the streams are created.  Once the streams are
 * delivered to the session delegate, the task is considered complete
 * and will receive no more messsages.  These streams are
 * disassociated from the underlying session.
 */

open class URLSessionStreamTask: URLSessionTask {
    
    /* Read minBytes, or at most maxBytes bytes and invoke the completion
     * handler on the sessions delegate queue with the data or an error.
     * If an error occurs, any outstanding reads will also fail, and new
     * read requests will error out immediately.
     */
    public func readDataOfMinLength(_ minBytes: Int, maxLength maxBytes: Int, timeout: TimeInterval, completionHandler: (Data?, Bool, NSError?) -> Void) { NSUnimplemented() }
    
    /* Write the data completely to the underlying socket.  If all the
     * bytes have not been written by the timeout, a timeout error will
     * occur.  Note that invocation of the completion handler does not
     * guarantee that the remote side has received all the bytes, only
     * that they have been written to the kernel. */
    public func writeData(_ data: Data, timeout: TimeInterval, completionHandler: (NSError?) -> Void) { NSUnimplemented() }
    
    /* -captureStreams completes any already enqueued reads
     * and writes, and then invokes the
     * URLSession:streamTask:didBecomeInputStream:outputStream: delegate
     * message. When that message is received, the task object is
     * considered completed and will not receive any more delegate
     * messages. */
    open func captureStreams() { NSUnimplemented() }
    
    /* Enqueue a request to close the write end of the underlying socket.
     * All outstanding IO will complete before the write side of the
     * socket is closed.  The server, however, may continue to write bytes
     * back to the client, so best practice is to continue reading from
     * the server until you receive EOF.
     */
    open func closeWrite() { NSUnimplemented() }
    
    /* Enqueue a request to close the read side of the underlying socket.
     * All outstanding IO will complete before the read side is closed.
     * You may continue writing to the server.
     */
    open func closeRead() { NSUnimplemented() }
    
    /*
     * Begin encrypted handshake.  The hanshake begins after all pending 
     * IO has completed.  TLS authentication callbacks are sent to the 
     * session's -URLSession:task:didReceiveChallenge:completionHandler:
     */
    open func startSecureConnection() { NSUnimplemented() }
    
    /*
     * Cleanly close a secure connection after all pending secure IO has 
     * completed.
     */
    open func stopSecureConnection() { NSUnimplemented() }
}

/*
 * Configuration options for an NSURLSession.  When a session is
 * created, a copy of the configuration object is made - you cannot
 * modify the configuration of a session after it has been created.
 *
 * The shared session uses the global singleton credential, cache
 * and cookie storage objects.
 *
 * An ephemeral session has no persistent disk storage for cookies,
 * cache or credentials.
 *
 * A background session can be used to perform networking operations
 * on behalf of a suspended application, within certain constraints.
 */

open class URLSessionConfiguration: NSObject, NSCopying {
    
    public override init() {
        NSUnimplemented()
    }
    
    open override func copy() -> AnyObject {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> AnyObject {
        NSUnimplemented()
    }
    
    open class func defaultSessionConfiguration() -> URLSessionConfiguration { NSUnimplemented() }
    open class func ephemeralSessionConfiguration() -> URLSessionConfiguration { NSUnimplemented() }
    open class func backgroundSessionConfigurationWithIdentifier(_ identifier: String) -> URLSessionConfiguration { NSUnimplemented() }
    
    /* identifier for the background session configuration */
    open var identifier: String? { NSUnimplemented() }
    
    /* default cache policy for requests */
    open var requestCachePolicy: NSURLRequest.CachePolicy
    
    /* default timeout for requests.  This will cause a timeout if no data is transmitted for the given timeout value, and is reset whenever data is transmitted. */
    open var timeoutIntervalForRequest: TimeInterval
    
    /* default timeout for requests.  This will cause a timeout if a resource is not able to be retrieved within a given timeout. */
    open var timeoutIntervalForResource: TimeInterval
    
    /* type of service for requests. */
    open var networkServiceType: URLRequest.NetworkServiceType
    
    /* allow request to route over cellular. */
    open var allowsCellularAccess: Bool
    
    /* allows background tasks to be scheduled at the discretion of the system for optimal performance. */
    open var discretionary: Bool
    
    /* The identifier of the shared data container into which files in background sessions should be downloaded.
     * App extensions wishing to use background sessions *must* set this property to a valid container identifier, or
     * all transfers in that session will fail with NSURLErrorBackgroundSessionRequiresSharedContainer.
     */
    open var sharedContainerIdentifier: String?
    
    /* 
     * Allows the app to be resumed or launched in the background when tasks in background sessions complete
     * or when auth is required. This only applies to configurations created with +backgroundSessionConfigurationWithIdentifier:
     * and the default value is YES.
     */
    
    /* The proxy dictionary, as described by <CFNetwork/CFHTTPStream.h> */
    open var connectionProxyDictionary: [NSObject : AnyObject]?
    
    // TODO: We don't have the SSLProtocol type from Security
    /*
    /* The minimum allowable versions of the TLS protocol, from <Security/SecureTransport.h> */
    open var TLSMinimumSupportedProtocol: SSLProtocol
    
    /* The maximum allowable versions of the TLS protocol, from <Security/SecureTransport.h> */
    open var TLSMaximumSupportedProtocol: SSLProtocol
    */
    
    /* Allow the use of HTTP pipelining */
    open var HTTPShouldUsePipelining: Bool
    
    /* Allow the session to set cookies on requests */
    open var HTTPShouldSetCookies: Bool
    
    /* Policy for accepting cookies.  This overrides the policy otherwise specified by the cookie storage. */
    open var httpCookieAcceptPolicy: HTTPCookie.AcceptPolicy
    
    /* Specifies additional headers which will be set on outgoing requests.
       Note that these headers are added to the request only if not already present. */
    open var HTTPAdditionalHeaders: [NSObject : AnyObject]?
    
    /* The maximum number of simultanous persistent connections per host */
    open var HTTPMaximumConnectionsPerHost: Int
    
    /* The cookie storage object to use, or nil to indicate that no cookies should be handled */
    open var httpCookieStorage: HTTPCookieStorage?
    
    /* The credential storage object, or nil to indicate that no credential storage is to be used */
    open var urlCredentialStorage: URLCredentialStorage?
    
    /* The URL resource cache, or nil to indicate that no caching is to be performed */
    open var urlCache: URLCache?
    
    /* Enable extended background idle mode for any tcp sockets created.    Enabling this mode asks the system to keep the socket open
     *  and delay reclaiming it when the process moves to the background (see https://developer.apple.com/library/ios/technotes/tn2277/_index.html) 
     */
    open var shouldUseExtendedBackgroundIdleMode: Bool
    
    /* An optional array of Class objects which subclass NSURLProtocol.
       The Class will be sent +canInitWithRequest: when determining if
       an instance of the class can be used for a given URL scheme.
       You should not use +[NSURLProtocol registerClass:], as that
       method will register your class with the default session rather
       than with an instance of NSURLSession. 
       Custom NSURLProtocol subclasses are not available to background
       sessions.
     */
    open var protocolClasses: [AnyClass]?
}

/*
 * Disposition options for various delegate messages
 */
extension URLSession {
    public enum AuthChallengeDisposition: Int {
        
        case useCredential /* Use the specified credential, which may be nil */
        case performDefaultHandling /* Default handling for the challenge - as if this delegate were not implemented; the credential parameter is ignored. */
        case cancelAuthenticationChallenge /* The entire request will be canceled; the credential parameter is ignored. */
        case rejectProtectionSpace /* This challenge is rejected and the next authentication protection space should be tried; the credential parameter is ignored. */
    }

    public enum ResponseDisposition: Int {
        
        case cancel /* Cancel the load, this is the same as -[task cancel] */
        case allow /* Allow the load to continue */
        case becomeDownload /* Turn this request into a download */
        case becomeStream /* Turn this task into a stream task */
    }
}

/*
 * NSURLSessionDelegate specifies the methods that a session delegate
 * may respond to.  There are both session specific messages (for
 * example, connection based auth) as well as task based messages.
 */

/*
 * Messages related to the URL session as a whole
 */
public protocol URLSessionDelegate : NSObjectProtocol {
    
    /* The last message a session receives.  A session will only become
     * invalid because of a systemic error or when it has been
     * explicitly invalidated, in which case the error parameter will be nil.
     */
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: NSError?)
    
    /* If implemented, when a connection level authentication challenge
     * has occurred, this delegate will be given the opportunity to
     * provide authentication credentials to the underlying
     * connection. Some types of authentication will apply to more than
     * one request on a given connection to a server (SSL Server Trust
     * challenges).  If this delegate message is not implemented, the 
     * behavior will be to use the default handling, which may involve user
     * interaction. 
     */
    func urlSession(_ session: URLSession, didReceiveChallenge challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
}

extension URLSessionDelegate {
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: NSError?) { }
    func urlSession(_ session: URLSession, didReceiveChallenge challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) { }
}

/* If an application has received an
 * -application:handleEventsForBackgroundURLSession:completionHandler:
 * message, the session delegate will receive this message to indicate
 * that all messages previously enqueued for this session have been
 * delivered.  At this time it is safe to invoke the previously stored
 * completion handler, or to begin any internal updates that will
 * result in invoking the completion handler.
 */

/*
 * Messages related to the operation of a specific task.
 */
public protocol URLSessionTaskDelegate : URLSessionDelegate {
    
    /* An HTTP request is attempting to perform a redirection to a different
     * URL. You must invoke the completion routine to allow the
     * redirection, allow the redirection with a modified request, or
     * pass nil to the completionHandler to cause the body of the redirection 
     * response to be delivered as the payload of this request. The default
     * is to follow redirections. 
     *
     * For tasks in background sessions, redirections will always be followed and this method will not be called.
     */
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: URLRequest, completionHandler: (URLRequest?) -> Void)
    
    /* The task has received a request specific authentication challenge.
     * If this delegate is not implemented, the session specific authentication challenge
     * will *NOT* be called and the behavior will be the same as using the default handling
     * disposition. 
     */
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceiveChallenge challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    
    /* Sent if a task requires a new, unopened body stream.  This may be
     * necessary when authentication has failed for any request that
     * involves a body stream. 
     */
    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: (InputStream?) -> Void)
    
    /* Sent periodically to notify the delegate of upload progress.  This
     * information is also available as properties of the task.
     */
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64)
    
    /* Sent as the last message related to a specific task.  Error may be
     * nil, which implies that no error occurred and this task is complete. 
     */
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: NSError?)
}

extension URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: URLRequest, completionHandler: (URLRequest?) -> Void) { }

    func urlSession(_ session: URLSession, task: URLSessionTask, didReceiveChallenge challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) { }

    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: (InputStream?) -> Void) { }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) { }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: NSError?) { }
}

/*
 * Messages related to the operation of a task that delivers data
 * directly to the delegate.
 */
public protocol URLSessionDataDelegate : URLSessionTaskDelegate {
    
    /* The task has received a response and no further messages will be
     * received until the completion block is called. The disposition
     * allows you to cancel a request or to turn a data task into a
     * download task. This delegate message is optional - if you do not
     * implement it, you can get the response as a property of the task.
     *
     * This method will not be called for background upload tasks (which cannot be converted to download tasks).
     */
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceiveResponse response: URLResponse, completionHandler: (URLSession.ResponseDisposition) -> Void)
    
    /* Notification that a data task has become a download task.  No
     * future messages will be sent to the data task.
     */
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecomeDownloadTask downloadTask: URLSessionDownloadTask)
    
    /*
     * Notification that a data task has become a bidirectional stream
     * task.  No future messages will be sent to the data task.  The newly
     * created streamTask will carry the original request and response as
     * properties.
     *
     * For requests that were pipelined, the stream object will only allow
     * reading, and the object will immediately issue a
     * -URLSession:writeClosedForStream:.  Pipelining can be disabled for
     * all requests in a session, or by the NSURLRequest
     * HTTPShouldUsePipelining property.
     *
     * The underlying connection is no longer considered part of the HTTP
     * connection cache and won't count against the total number of
     * connections per host.
     */
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecomeStreamTask streamTask: URLSessionStreamTask)
    
    /* Sent when data is available for the delegate to consume.  It is
     * assumed that the delegate will retain and not copy the data.  As
     * the data may be discontiguous, you should use 
     * [NSData enumerateByteRangesUsingBlock:] to access it.
     */
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceiveData data: Data)
    
    /* Invoke the completion routine with a valid NSCachedURLResponse to
     * allow the resulting data to be cached, or pass nil to prevent
     * caching. Note that there is no guarantee that caching will be
     * attempted for a given resource, and you should not rely on this
     * message to receive the resource data.
     */
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: (CachedURLResponse?) -> Void)
}

extension URLSessionDataDelegate {

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceiveResponse response: URLResponse, completionHandler: (URLSession.ResponseDisposition) -> Void) { }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecomeDownloadTask downloadTask: URLSessionDownloadTask) { }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecomeStreamTask streamTask: URLSessionStreamTask) { }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: (CachedURLResponse?) -> Void) { }
}

/*
 * Messages related to the operation of a task that writes data to a
 * file and notifies the delegate upon completion.
 */
public protocol URLSessionDownloadDelegate : URLSessionTaskDelegate {
    
    /* Sent when a download task that has completed a download.  The delegate should 
     * copy or move the file at the given location to a new location as it will be 
     * removed when the delegate message returns. URLSession:task:didCompleteWithError: will
     * still be called.
     */
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingToURL location: URL)
    
    /* Sent periodically to notify the delegate of download progress. */
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    
    /* Sent when a download has been resumed. If a download failed with an
     * error, the -userInfo dictionary of the error will contain an
     * NSURLSessionDownloadTaskResumeData key, whose value is the resume
     * data. 
     */
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64)
}

extension URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) { }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) { }

}

public protocol URLSessionStreamDelegate : URLSessionTaskDelegate {
    
    /* Indiciates that the read side of a connection has been closed.  Any
     * outstanding reads complete, but future reads will immediately fail.
     * This may be sent even when no reads are in progress. However, when
     * this delegate message is received, there may still be bytes
     * available.  You only know that no more bytes are available when you
     * are able to read until EOF. */
    func urlSession(_ session: URLSession, readClosedForStreamTask streamTask: URLSessionStreamTask)
    
    /* Indiciates that the write side of a connection has been closed.
     * Any outstanding writes complete, but future writes will immediately
     * fail.
     */
    func urlSession(_ session: URLSession, writeClosedForStreamTask streamTask: URLSessionStreamTask)
    
    /* A notification that the system has determined that a better route
     * to the host has been detected (eg, a wi-fi interface becoming
     * available.)  This is a hint to the delegate that it may be
     * desirable to create a new task for subsequent work.  Note that
     * there is no guarantee that the future task will be able to connect
     * to the host, so callers should should be prepared for failure of
     * reads and writes over any new interface. */
    func urlSession(_ session: URLSession, betterRouteDiscoveredForStreamTask streamTask: URLSessionStreamTask)
    
    /* The given task has been completed, and unopened NSInputStream and
     * NSOutputStream objects are created from the underlying network
     * connection.  This will only be invoked after all enqueued IO has
     * completed (including any necessary handshakes.)  The streamTask
     * will not receive any further delegate messages.
     */
    func urlSession(_ session: URLSession, streamTask: URLSessionStreamTask, didBecomeInputStream inputStream: InputStream, outputStream: NSOutputStream)
}

extension URLSessionStreamDelegate {
    func urlSession(_ session: URLSession, readClosedForStreamTask streamTask: URLSessionStreamTask) { }
    
    func urlSession(_ session: URLSession, writeClosedForStreamTask streamTask: URLSessionStreamTask) { }
    
    func urlSession(_ session: URLSession, betterRouteDiscoveredForStreamTask streamTask: URLSessionStreamTask) { }
    
    func urlSession(_ session: URLSession, streamTask: URLSessionStreamTask, didBecomeInputStream inputStream: InputStream, outputStream: NSOutputStream) { }
}

/* Key in the userInfo dictionary of an NSError received during a failed download. */
public let NSURLSessionDownloadTaskResumeData: String = "" // NSUnimplemented
