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

public func NSTemporaryDirectory() -> String {
    #if os(OSX) || os(iOS)
    var buf = [Int8](repeating: 0, count: 100)
    let r = confstr(_CS_DARWIN_USER_TEMP_DIR, &buf, buf.count)
    if r != 0 && r < buf.count {
        return String(CString: buf, encoding: NSUTF8StringEncoding)!
    }
    #endif
    if let tmpdir = NSProcessInfo.processInfo().environment["TMPDIR"] {
        if !tmpdir.hasSuffix("/") {
            return tmpdir + "/"
        } else {
            return tmpdir
        }
    }
    return "/tmp/"
}

internal extension String {
    
    internal var _startOfLastPathComponent : String.CharacterView.Index {
        precondition(!hasSuffix("/") && length > 1)
        
        let characterView = characters
        let startPos = characterView.startIndex
        let endPos = characterView.endIndex
        var curPos = endPos
        
        // Find the beginning of the component
        while curPos > startPos {
            let prevPos = characterView.index(before: curPos)
            if characterView[prevPos] == "/" {
                break
            }
            curPos = prevPos
        }
        return curPos

    }

    internal var _startOfPathExtension : String.CharacterView.Index? {
        precondition(!hasSuffix("/"))
        
        let characterView = self.characters
        let endPos = characterView.endIndex
        var curPos = endPos
        
        let lastCompStartPos = _startOfLastPathComponent
        
        // Find the beginning of the extension
        while curPos > lastCompStartPos {
            let prevPos = characterView.index(before: curPos)
            let char = characterView[prevPos]
            if char == "/" {
                return nil
            } else if char == "." {
                if lastCompStartPos == prevPos {
                    return nil
                } else {
                    return curPos
                }
            }
            curPos = prevPos
        }
        return nil
    }

    internal var absolutePath: Bool {
        return hasPrefix("~") || hasPrefix("/")
    }
    
    internal func _stringByAppendingPathComponent(_ str: String, doneAppending : Bool = true) -> String {
        if str.length == 0 {
            return self
        }
        if self == "" {
            return "/" + str
        }
        if self == "/" {
            return self + str
        }
        return self + "/" + str
    }
    
    internal func _stringByFixingSlashes(compress : Bool = true, stripTrailing: Bool = true) -> String {
        var result = self
        if compress {
            result.withMutableCharacters { characterView in
                let startPos = characterView.startIndex
                var endPos = characterView.endIndex
                var curPos = startPos
                
                while curPos < endPos {
                    if characterView[curPos] == "/" {
                        var afterLastSlashPos = curPos
                        while afterLastSlashPos < endPos && characterView[afterLastSlashPos] == "/" {
                            afterLastSlashPos = characterView.index(after: afterLastSlashPos)
                        }
                        if afterLastSlashPos != characterView.index(after: curPos) {
                            characterView.replaceSubrange(curPos ..< afterLastSlashPos, with: ["/"])
                            endPos = characterView.endIndex
                        }
                        curPos = afterLastSlashPos
                    } else {
                        curPos = characterView.index(after: curPos)
                    }
                }
            }
        }
        if stripTrailing && result.length > 1 && result.hasSuffix("/") {
            result.remove(at: result.characters.index(before: result.characters.endIndex))
        }
        return result
    }
    
    internal func _stringByRemovingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else {
            return self
        }

        var temp = self
        temp.removeSubrange(startIndex..<prefix.endIndex)
        return temp
    }
    
    internal func _tryToRemovePathPrefix(_ prefix: String) -> String? {
        guard self != prefix else {
            return nil
        }
        
        let temp = _stringByRemovingPrefix(prefix)
        if NSFileManager.defaultManager().fileExists(atPath: temp) {
            return temp
        }
        
        return nil
    }
}

public extension NSString {
    
    public var absolutePath: Bool {
        return hasPrefix("~") || hasPrefix("/")
    }
    
    public static func pathWithComponents(_ components: [String]) -> String {
        var result = ""
        for comp in components.prefix(components.count - 1) {
            result = result._stringByAppendingPathComponent(comp._stringByFixingSlashes(), doneAppending: false)
        }
        if let last = components.last {
            result = result._stringByAppendingPathComponent(last._stringByFixingSlashes(), doneAppending: true)
        }
        return result
    }
    
    public var pathComponents : [String] {
        var result = [String]()
        if length == 0 {
            return result
        } else {
            let characterView = _swiftObject.characters
            var curPos = characterView.startIndex
            let endPos = characterView.endIndex
            if characterView[curPos] == "/" {
                result.append("/")
            }
            
            while curPos < endPos {
                while curPos < endPos && characterView[curPos] == "/" {
                    curPos = characterView.index(after: curPos)
                }
                if curPos == endPos {
                    break
                }
                var curEnd = curPos
                while curEnd < endPos && characterView[curEnd] != "/" {
                    curEnd = characterView.index(after: curEnd)
                }
                result.append(String(characterView[curPos ..< curEnd]))
                curPos = curEnd
            }
        }
        if length > 1 && hasSuffix("/") {
            result.append("/")
        }
        return result
    }
    
    public var lastPathComponent : String {
        let fixedSelf = _stringByFixingSlashes()
        if fixedSelf.length <= 1 {
            return fixedSelf
        }
        
        return String(fixedSelf.characters.suffix(from: fixedSelf._startOfLastPathComponent))
    }
    
    public var stringByDeletingLastPathComponent : String {
        let fixedSelf = _stringByFixingSlashes()
        if fixedSelf == "/" {
            return fixedSelf
        }
        
        switch fixedSelf._startOfLastPathComponent {
        
        // relative path, single component
        case fixedSelf.startIndex:
            return ""
        
        // absolute path, single component
        case fixedSelf.index(after: fixedSelf.startIndex):
            return "/"
        
        // all common cases
        case let startOfLast:
            return String(fixedSelf.characters.prefix(upTo: fixedSelf.index(before: startOfLast)))
        }
    }
    
    internal func _stringByFixingSlashes(compress : Bool = true, stripTrailing: Bool = true) -> String {
        if _swiftObject == "/" {
            return _swiftObject
        }
        
        var result = _swiftObject
        if compress {
            result.withMutableCharacters { characterView in
                let startPos = characterView.startIndex
                var endPos = characterView.endIndex
                var curPos = startPos
                
                while curPos < endPos {
                    if characterView[curPos] == "/" {
                        var afterLastSlashPos = curPos
                        while afterLastSlashPos < endPos && characterView[afterLastSlashPos] == "/" {
                            afterLastSlashPos = characterView.index(after: afterLastSlashPos)
                        }
                        if afterLastSlashPos != characterView.index(after: curPos) {
                            characterView.replaceSubrange(curPos ..< afterLastSlashPos, with: ["/"])
                            endPos = characterView.endIndex
                        }
                        curPos = afterLastSlashPos
                    } else {
                        curPos = characterView.index(after: curPos)
                    }
                }
            }
        }
        if stripTrailing && result.hasSuffix("/") {
            result.remove(at: result.characters.index(before: result.characters.endIndex))
        }
        return result
    }
    
    internal func _stringByAppendingPathComponent(_ str: String, doneAppending : Bool = true) -> String {
        if str.length == 0 {
            return _swiftObject
        }
        if self == "" {
            return "/" + str
        }
        if self == "/" {
            return _swiftObject + str
        }
        return _swiftObject + "/" + str
    }
    
    public func stringByAppendingPathComponent(_ str: String) -> String {
        return _stringByAppendingPathComponent(str)
    }
    
    public var pathExtension : String {
        let fixedSelf = _stringByFixingSlashes()
        if fixedSelf.length <= 1 {
            return ""
        }

        if let extensionPos = fixedSelf._startOfPathExtension {
            return String(fixedSelf.characters.suffix(from: extensionPos))
        } else {
            return ""
        }
    }
    
    public var stringByDeletingPathExtension: String {
        let fixedSelf = _stringByFixingSlashes()
        if fixedSelf.length <= 1 {
            return fixedSelf
        }
        if let extensionPos = (fixedSelf._startOfPathExtension) {
            return String(fixedSelf.characters.prefix(upTo: fixedSelf.characters.index(before: extensionPos)))
        } else {
            return fixedSelf
        }
    }
    
    public func stringByAppendingPathExtension(_ str: String) -> String? {
        if str.hasPrefix("/") || self == "" || self == "/" {
            print("Cannot append extension \(str) to path \(self)")
            return nil
        }
        let result = _swiftObject._stringByFixingSlashes(compress: false, stripTrailing: true) + "." + str
        return result._stringByFixingSlashes()
    }

    public var stringByExpandingTildeInPath: String {
        guard hasPrefix("~") else {
            return _swiftObject
        }

        let endOfUserName = _swiftObject.characters.index(of: "/") ?? _swiftObject.endIndex
        let startOfUserName = _swiftObject.characters.index(after: _swiftObject.characters.startIndex)
        let userName = String(_swiftObject.characters[startOfUserName..<endOfUserName])
        let optUserName: String? = userName.isEmpty ? nil : userName
        
        guard let homeDir = NSHomeDirectoryForUser(optUserName) else {
            return _swiftObject._stringByFixingSlashes(compress: false, stripTrailing: true)
        }
        
        var result = _swiftObject
        result.replaceSubrange(_swiftObject.startIndex..<endOfUserName, with: homeDir)
        result = result._stringByFixingSlashes(compress: false, stripTrailing: true)
        
        return result
    }
    
    public var stringByStandardizingPath: String {
        let expanded = stringByExpandingTildeInPath
        var resolved = expanded.bridge().stringByResolvingSymlinksInPath
        
        let automount = "/var/automount"
        resolved = resolved._tryToRemovePathPrefix(automount) ?? resolved
        return resolved
    }
    
    public var stringByResolvingSymlinksInPath: String {
        var components = pathComponents
        guard !components.isEmpty else {
            return _swiftObject
        }
        
        // TODO: pathComponents keeps final path separator if any. Check that logic.
        if components.last == "/" {
            components.removeLast()
        }
        
        let isAbsolutePath = components.first == "/"
        
        var resolvedPath = components.removeFirst()
        for component in components {
            switch component {
                
            case "", ".":
                break
                
            case ".." where isAbsolutePath:
                resolvedPath = resolvedPath.bridge().stringByDeletingLastPathComponent
                
            default:
                resolvedPath = resolvedPath.bridge().stringByAppendingPathComponent(component)
                if let destination = NSFileManager.defaultManager()._tryToResolveTrailingSymlinkInPath(resolvedPath) {
                    resolvedPath = destination
                }
            }
        }
        
        let privatePrefix = "/private"
        resolvedPath = resolvedPath._tryToRemovePathPrefix(privatePrefix) ?? resolvedPath
        
        return resolvedPath
    }
    
    public func stringsByAppendingPaths(_ paths: [String]) -> [String] {
        if self == "" {
            return paths
        }
        return paths.map(stringByAppendingPathComponent)
    }
    
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public func completePathIntoString(_ outputName: inout NSString?, caseSensitive flag: Bool, matchesIntoArray outputArray: inout [NSString], filterTypes: [String]?) -> Int {
        let path = _swiftObject
        guard !path.isEmpty else {
            return 0
        }
        
        let url = NSURL(fileURLWithPath: path)
        
        let searchAllFilesInDirectory = _stringIsPathToDirectory(path)
        let namePrefix = searchAllFilesInDirectory ? nil : url.lastPathComponent
        let checkFileName = _getFileNamePredicate(namePrefix, caseSensetive: flag)
        let checkExtension = _getExtensionPredicate(filterTypes, caseSensetive: flag)
        
        guard let
            resolvedURL = url._resolveSymlinksInPath(excludeSystemDirs: false),
            urlWhereToSearch = searchAllFilesInDirectory ? resolvedURL : resolvedURL.URLByDeletingLastPathComponent
        else {
            return 0
        }

        var matches = _getNamesAtURL(urlWhereToSearch, prependWith: "", namePredicate: checkFileName, typePredicate: checkExtension)
        
        if matches.count == 1 {
            let theOnlyFoundItem = NSURL(fileURLWithPath: matches[0], relativeToURL: urlWhereToSearch)
            if theOnlyFoundItem.hasDirectoryPath {
                matches = _getNamesAtURL(theOnlyFoundItem, prependWith: matches[0], namePredicate: { _ in true }, typePredicate: checkExtension)
            }
        }
        
        let commonPath = searchAllFilesInDirectory ? path : _ensureLastPathSeparator(stringByDeletingLastPathComponent)
        
        if searchAllFilesInDirectory {
            outputName = "/"
        } else {            
            if let lcp = _longestCommonPrefix(matches, caseSensitive: flag) {
                outputName = (commonPath + lcp).bridge()
            }
        }
        
        outputArray = matches.map({ (commonPath + $0).bridge() })
        
        return matches.count
    }

    internal func _stringIsPathToDirectory(_ path: String) -> Bool {
        if !path.hasSuffix("/") {
            return false
        }
        
        var isDirectory = false
        let exists = NSFileManager.defaultManager().fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory
    }
    
    internal typealias _FileNamePredicate = (String?) -> Bool
    
    internal func _getNamesAtURL(_ filePathURL: NSURL, prependWith: String, namePredicate: _FileNamePredicate, typePredicate: _FileNamePredicate) -> [String] {
        var result: [String] = []
        
        if let enumerator = NSFileManager.defaultManager().enumerator(at: filePathURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants, errorHandler: nil) {
            for item in enumerator.lazy.map({ $0 as! NSURL }) {
                let itemName = item.lastPathComponent
                
                let matchByName = namePredicate(itemName)
                let matchByExtension = typePredicate(item.pathExtension)
                
                if matchByName && matchByExtension {
                    if prependWith.isEmpty {
                        result.append(itemName!)
                    } else {
                        result.append(prependWith.bridge().stringByAppendingPathComponent(itemName!))
                    }
                }
            }
        }
        
        return result
    }
    
    internal func _getExtensionPredicate(_ extensions: [String]?, caseSensetive: Bool) -> _FileNamePredicate {
        guard let exts = extensions else {
            return { _ in true }
        }
        
        if caseSensetive {
            let set = Set(exts)
            return { $0 != nil && set.contains($0!) }
        } else {
            let set = Set(exts.map { $0.lowercased() })
            return { $0 != nil && set.contains($0!.lowercased()) }
        }
    }
    
    internal func _getFileNamePredicate(_ prefix: String?, caseSensetive: Bool) -> _FileNamePredicate {
        guard let thePrefix = prefix else {
            return { _ in true }
        }

        if caseSensetive {
            return { $0 != nil && $0!.hasPrefix(thePrefix) }
        } else {
            return { $0 != nil && $0!.bridge().range(of: thePrefix, options: .caseInsensitiveSearch).location == 0 }
        }
    }
    
    internal func _longestCommonPrefix(_ strings: [String], caseSensitive: Bool) -> String? {
        guard strings.count > 0 else {
            return nil
        }
        
        guard strings.count > 1 else {
            return strings.first
        }
        
        var sequences = strings.map({ $0.characters.makeIterator() })
        var prefix: [Character] = []
        loop: while true {
            var char: Character? = nil
            for (idx, s) in sequences.enumerated() {
                var seq = s
                
                guard let c = seq.next() else {
                    break loop
                }
                
                if char != nil {
                    let lhs = caseSensitive ? char : String(char!).lowercased().characters.first!
                    let rhs = caseSensitive ? c : String(c).lowercased().characters.first!
                    if lhs != rhs {
                        break loop
                    }
                } else {
                    char = c
                }
                
                sequences[idx] = seq
            }
            prefix.append(char!)
        }
        
        return String(prefix)
    }
    
    internal func _ensureLastPathSeparator(_ path: String) -> String {
        if path.hasSuffix("/") || path.isEmpty {
            return path
        }
        
        return path + "/"
    }
    
    public var fileSystemRepresentation : UnsafePointer<Int8> {
        NSUnimplemented()
    }
    
    public func getFileSystemRepresentation(_ cname: UnsafeMutablePointer<Int8>, maxLength max: Int) -> Bool {
        guard self.length > 0 else {
            return false
        }
        
        return CFStringGetFileSystemRepresentation(self._cfObject, cname, max)
    }

}

public enum NSSearchPathDirectory : UInt {
    
    case ApplicationDirectory // supported applications (Applications)
    case DemoApplicationDirectory // unsupported applications, demonstration versions (Demos)
    case DeveloperApplicationDirectory // developer applications (Developer/Applications). DEPRECATED - there is no one single Developer directory.
    case AdminApplicationDirectory // system and network administration applications (Administration)
    case LibraryDirectory // various documentation, support, and configuration files, resources (Library)
    case DeveloperDirectory // developer resources (Developer) DEPRECATED - there is no one single Developer directory.
    case UserDirectory // user home directories (Users)
    case DocumentationDirectory // documentation (Documentation)
    case DocumentDirectory // documents (Documents)
    case CoreServiceDirectory // location of CoreServices directory (System/Library/CoreServices)
    case AutosavedInformationDirectory // location of autosaved documents (Documents/Autosaved)
    case DesktopDirectory // location of user's desktop
    case CachesDirectory // location of discardable cache files (Library/Caches)
    case ApplicationSupportDirectory // location of application support files (plug-ins, etc) (Library/Application Support)
    case DownloadsDirectory // location of the user's "Downloads" directory
    case InputMethodsDirectory // input methods (Library/Input Methods)
    case MoviesDirectory // location of user's Movies directory (~/Movies)
    case MusicDirectory // location of user's Music directory (~/Music)
    case PicturesDirectory // location of user's Pictures directory (~/Pictures)
    case PrinterDescriptionDirectory // location of system's PPDs directory (Library/Printers/PPDs)
    case SharedPublicDirectory // location of user's Public sharing directory (~/Public)
    case PreferencePanesDirectory // location of the PreferencePanes directory for use with System Preferences (Library/PreferencePanes)
    case ApplicationScriptsDirectory // location of the user scripts folder for the calling application (~/Library/Application Scripts/code-signing-id)
    case ItemReplacementDirectory // For use with NSFileManager's URLForDirectory:inDomain:appropriateForURL:create:error:
    case AllApplicationsDirectory // all directories where applications can occur
    case AllLibrariesDirectory // all directories where resources can occur
    case TrashDirectory // location of Trash directory
}

public struct NSSearchPathDomainMask : OptionSet {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let UserDomainMask = NSSearchPathDomainMask(rawValue: 1) // user's home directory --- place to install user's personal items (~)
    public static let LocalDomainMask = NSSearchPathDomainMask(rawValue: 2) // local to the current machine --- place to install items available to everyone on this machine (/Library)
    public static let NetworkDomainMask = NSSearchPathDomainMask(rawValue: 4) // publically available location in the local area network --- place to install items available on the network (/Network)
    public static let SystemDomainMask = NSSearchPathDomainMask(rawValue: 8) // provided by Apple, unmodifiable (/System)
    public static let AllDomainsMask = NSSearchPathDomainMask(rawValue: 0x0ffff) // all domains: all of the above and future items
}

public func NSSearchPathForDirectoriesInDomains(_ directory: NSSearchPathDirectory, _ domainMask: NSSearchPathDomainMask, _ expandTilde: Bool) -> [String] {
    NSUnimplemented()
}

public func NSHomeDirectory() -> String {
    return NSHomeDirectoryForUser(nil)!
}

public func NSHomeDirectoryForUser(_ user: String?) -> String? {
    let userName = user?._cfObject
    guard let homeDir = CFCopyHomeDirectoryURLForUser(userName)?.takeRetainedValue() else {
        return nil
    }
    
    let url: NSURL = homeDir._nsObject
    return url.path
}

public func NSUserName() -> String {
    let userName = CFCopyUserName().takeRetainedValue()
    return userName._swiftObject
}

internal func _NSCreateTemporaryFile(_ filePath: String) throws -> (Int32, String) {
    let template = "." + filePath + ".tmp.XXXXXX"
    let maxLength = Int(PATH_MAX) + 1
    var buf = [Int8](repeating: 0, count: maxLength)
    template._nsObject.getFileSystemRepresentation(&buf, maxLength: maxLength)
    let fd = mkstemp(&buf)
    if fd == -1 {
        throw _NSErrorWithErrno(errno, reading: false, path: filePath)
    }
    let pathResult = NSFileManager.defaultManager().string(withFileSystemRepresentation: buf, length: Int(strlen(buf)))
    return (fd, pathResult)
}

internal func _NSCleanupTemporaryFile(_ auxFilePath: String, _ filePath: String) throws  {
    if rename(auxFilePath, filePath) != 0 {
        do {
            try NSFileManager.defaultManager().removeItem(atPath: auxFilePath)
        } catch _ {
        }
        throw _NSErrorWithErrno(errno, reading: false, path: filePath)
    }
}
