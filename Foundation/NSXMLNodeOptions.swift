// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


/*!
    @enum Init, input, and output options
    @constant NSXMLNodeIsCDATA This text node is CDATA
    @constant NSXMLNodeExpandEmptyElement This element should be expanded when empty, ie &lt;a>&lt;/a>. This is the default.
    @constant NSXMLNodeCompactEmptyElement This element should contract when empty, ie &lt;a/>
    @constant NSXMLNodeUseSingleQuotes Use single quotes on this attribute or namespace
    @constant NSXMLNodeUseDoubleQuotes Use double quotes on this attribute or namespace. This is the default.
    @constant NSXMLNodeNeverEscapeContents When generating a string representation of an XML document, don't escape the reserved characters '<' and '&' in Text nodes

    @constant NSXMLNodeOptionsNone Use the default options
    @constant NSXMLNodePreserveAll Turn all preservation options on
    @constant NSXMLNodePreserveNamespaceOrder Preserve the order of namespaces
    @constant NSXMLNodePreserveAttributeOrder Preserve the order of attributes
    @constant NSXMLNodePreserveEntities Entities should not be resolved on output
    @constant NSXMLNodePreservePrefixes Prefixes should not be chosen based on closest URI definition
    @constant NSXMLNodePreserveCDATA CDATA should be preserved
    @constant NSXMLNodePreserveEmptyElements Remember whether an empty element was in expanded or contracted form
    @constant NSXMLNodePreserveQuotes Remember whether an attribute used single or double quotes
    @constant NSXMLNodePreserveWhitespace Preserve non-content whitespace
    @constant NSXMLNodePromoteSignificantWhitespace When significant whitespace is encountered in the document, create Text nodes representing it rather than removing it. Has no effect if NSXMLNodePreserveWhitespace is also specified
    @constant NSXMLNodePreserveDTD Preserve the DTD until it is modified
    
    @constant NSXMLDocumentTidyHTML Try to change HTML into valid XHTML
    @constant NSXMLDocumentTidyXML Try to change malformed XML into valid XML
    
    @constant NSXMLDocumentValidate Valid this document against its DTD
 
    @constant NSXMLNodeLoadExternalEntitiesAlways Load all external entities instead of just non-network ones
    @constant NSXMLNodeLoadExternalEntitiesSameOriginOnly Load non-network external entities and external entities from urls with the same domain, host, and port as the document
    @constant NSXMLNodeLoadExternalEntitiesNever Load no external entities, even those that don't require network access

    @constant NSXMLNodePrettyPrint Output this node with extra space for readability
    @constant NSXMLDocumentIncludeContentTypeDeclaration Include a content type declaration for HTML or XHTML
*/

// [FOU-0057] NSXMLNodeOptions should be an OptionSet 
public var NSXMLNodeOptionsNone: Int { return 0 }

// Init
public var NSXMLNodeIsCDATA: Int { return 1 << 0 }
public var NSXMLNodeExpandEmptyElement: Int { return 1 << 1 } // <a></a>
public var NSXMLNodeCompactEmptyElement: Int { return 1 << 2 } // <a/>
public var NSXMLNodeUseSingleQuotes: Int { return 1 << 3 }
public var NSXMLNodeUseDoubleQuotes: Int { return 1 << 4 }
public var NSXMLNodeNeverEscapeContents: Int { return 1 << 5 }

// Tidy
public var NSXMLDocumentTidyHTML: Int { return 1 << 9 }
public var NSXMLDocumentTidyXML: Int { return 1 << 10 }

// Validate
public var NSXMLDocumentValidate: Int { return 1 << 13 }

// External Entity Loading
// Choose only zero or one option. Choosing none results in system-default behavior.
public var NSXMLNodeLoadExternalEntitiesAlways: Int { return 1 << 14 }
public var NSXMLNodeLoadExternalEntitiesSameOriginOnly: Int { return 1 << 15 }
public var NSXMLNodeLoadExternalEntitiesNever: Int { return 1 << 19 }

// Parse
public var NSXMLDocumentXInclude: Int { return 1 << 16 }

// Output
public var NSXMLNodePrettyPrint: Int { return 1 << 17 }
public var NSXMLDocumentIncludeContentTypeDeclaration: Int { return 1 << 18 }

// Fidelity
public var NSXMLNodePreserveNamespaceOrder: Int { return 1 << 20 }
public var NSXMLNodePreserveAttributeOrder: Int { return 1 << 21 }
public var NSXMLNodePreserveEntities: Int { return 1 << 22 }
public var NSXMLNodePreservePrefixes: Int { return 1 << 23 }
public var NSXMLNodePreserveCDATA: Int { return 1 << 24 }
public var NSXMLNodePreserveWhitespace: Int { return 1 << 25 }
public var NSXMLNodePreserveDTD: Int { return 1 << 26 }
public var NSXMLNodePreserveCharacterReferences: Int { return 1 << 27 }
public var NSXMLNodePromoteSignificantWhitespace: Int { return 1 << 28 }
public var NSXMLNodePreserveEmptyElements: Int { return NSXMLNodeExpandEmptyElement | NSXMLNodeCompactEmptyElement }
public var NSXMLNodePreserveQuotes: Int { return NSXMLNodeUseSingleQuotes | NSXMLNodeUseDoubleQuotes }
public var NSXMLNodePreserveAll: Int { return
    NSXMLNodePreserveNamespaceOrder |
    NSXMLNodePreserveAttributeOrder |
    NSXMLNodePreserveEntities |
    NSXMLNodePreservePrefixes |
    NSXMLNodePreserveCDATA |
    NSXMLNodePreserveEmptyElements |
    NSXMLNodePreserveQuotes |
    NSXMLNodePreserveWhitespace |
    NSXMLNodePreserveDTD |
    NSXMLNodePreserveCharacterReferences |
    Int(bitPattern: 0xFFF00000) // high 12 bits 
}

