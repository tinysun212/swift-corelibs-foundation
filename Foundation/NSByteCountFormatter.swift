// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


extension ByteCountFormatter {
    public struct Units : OptionSet {
        public let rawValue : UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        
        // This causes default units appropriate for the platform to be used. Specifying any units explicitly causes just those units to be used in showing the number.
        public static let useDefault = Units(rawValue: 0)
        //  Specifying any of the following causes the specified units to be used in showing the number.
        public static let useBytes = Units(rawValue: 1 << 0)
        public static let useKB = Units(rawValue: 1 << 1)
        public static let useMB = Units(rawValue: 1 << 2)
        public static let useGB = Units(rawValue: 1 << 3)
        public static let useTB = Units(rawValue: 1 << 4)
        public static let usePB = Units(rawValue: 1 << 5)
        public static let useEB = Units(rawValue: 1 << 6)
        public static let useZB = Units(rawValue: 1 << 7)
        public static let useYBOrHigher = Units(rawValue: 0x0FF << 8)
        // Can use any unit in showing the number.
        public static let useAll = Units(rawValue: 0x0FFFF)
    }

    public enum CountStyle : Int {
        
        // Specifies display of file or storage byte counts. The actual behavior for this is platform-specific; on OS X 10.8, this uses the decimal style, but that may change over time.
        case file
        // Specifies display of memory byte counts. The actual behavior for this is platform-specific; on OS X 10.8, this uses the binary style, but that may change over time.
        case memory
        // The following two allow specifying the number of bytes for KB explicitly. It's better to use one of the above values in most cases.
        case decimal // 1000 bytes are shown as 1 KB
        case binary // 1024 bytes are shown as 1 KB
    }
}

open class ByteCountFormatter : Formatter {
    public override init() {
        super.init()
    }
    
    public required init?(coder: NSCoder) {
        NSUnimplemented()
    }
    
    /* Shortcut for converting a byte count into a string without creating an NSByteCountFormatter and an NSNumber. If you need to specify options other than countStyle, create an instance of NSByteCountFormatter first.
    */
    open class func string(fromByteCount byteCount: Int64, countStyle: ByteCountFormatter.CountStyle) -> String { NSUnimplemented() }
    
    /* Convenience method on string(for:):. Convert a byte count into a string without creating an NSNumber.
    */
    open func stringFromByteCount(_ byteCount: Int64) -> String { NSUnimplemented() }
    
    /* Specify the units that can be used in the output. If NSByteCountFormatterUseDefault, uses platform-appropriate settings; otherwise will only use the specified units. This is the default value. Note that ZB and YB cannot be covered by the range of possible values, but you can still choose to use these units to get fractional display ("0.0035 ZB" for instance).
    */
    open var allowedUnits: Units = .useDefault
    
    /* Specify how the count is displayed by indicating the number of bytes to be used for kilobyte. The default setting is NSByteCountFormatterFileCount, which is the system specific value for file and storage sizes.
    */
    open var countStyle: CountStyle = .file
    
    /* Choose whether to allow more natural display of some values, such as zero, where it may be displayed as "Zero KB," ignoring all other flags or options (with the exception of NSByteCountFormatterUseBytes, which would generate "Zero bytes"). The result is appropriate for standalone output. Default value is YES. Special handling of certain values such as zero is especially important in some languages, so it's highly recommended that this property be left in its default state.
    */
    open var allowsNonnumericFormatting: Bool = true
    
    /* Choose whether to include the number or the units in the resulting formatted string. (For example, instead of 723 KB, returns "723" or "KB".) You can call the API twice to get both parts, separately. But note that putting them together yourself via string concatenation may be wrong for some locales; so use this functionality with care.  Both of these values are YES by default.  Setting both to NO will unsurprisingly result in an empty string.
    */
    open var includesUnit: Bool = true
    open var includesCount: Bool = true
    
    /* Choose whether to parenthetically (localized as appropriate) display the actual number of bytes as well, for instance "723 KB (722,842 bytes)".  This will happen only if needed, that is, the first part is already not showing the exact byte count.  If includesUnit or includesCount are NO, then this setting has no effect.  Default value is NO.
    */
    open var includesActualByteCount: Bool = false
    
    /* Choose the display style. The "adaptive" algorithm is platform specific and uses a different number of fraction digits based on the magnitude (in 10.8: 0 fraction digits for bytes and KB; 1 fraction digits for MB; 2 for GB and above). Otherwise the result always tries to show at least three significant digits, introducing fraction digits as necessary. Default is YES.
    */
    open var isAdaptive: Bool = true
    
    /* Choose whether to zero pad fraction digits so a consistent number of fraction digits are displayed, causing updating displays to remain more stable. For instance, if the adaptive algorithm is used, this option formats 1.19 and 1.2 GB as "1.19 GB" and "1.20 GB" respectively, while without the option the latter would be displayed as "1.2 GB". Default value is NO.
    */
    open var zeroPadsFractionDigits: Bool = false
    
    /* Specify the formatting context for the formatted string. Default is NSFormattingContextUnknown.
    */
    open var formattingContext: Context = .unknown
}

