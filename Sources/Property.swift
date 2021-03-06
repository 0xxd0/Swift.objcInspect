//
//  Property.swift
//
//  Copyright (c) 2018 0xxd0 (https://github.com/0xxd0). All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import ObjectiveC

/// [Property Type String](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html)
extension Property {
    
    public enum TypeEncoding: String {
        /// The property is read-only (readonly).
        case readOnly = "R"
        /// The property is a copy of the value last assigned (copy).
        case copy = "C"
        /// The property is a reference to the value last assigned (retain).
        case retain = "&"
        /// The property is non-atomic (nonatomic).
        case nonatomic = "N"
        // G<name>, The property defines a custom getter selector name. The name follows the G (for example, GcustomGetter,).
        case getter = "G"
        //S<name> The property defines a custom setter selector name. The name follows the S (for example, ScustomSetter:,).
        case setter = "S"
        // The property is dynamic (@dynamic).
        case dynamic = "D"
        //The property is a weak reference (__weak).
        case weak = "W"
        //The property is eligible for garbage collection.
        case gcEligible = "P"
        //  t<encoding> Specifies the type using old-style encoding.
        case typeEncodingOld = "t"
        // Ivar name prefix
        case iVar = "V"
        // T type encoding prefix
        case typeEncoding = "T"
    }
}

/// An class type that represents an Objective-C declared property.
final public class Property: Inspectable<ObjectiveC.objc_property_t> {
    
    /// Returns the name of a property.
    @available(iOS 2.0, macOS 10.5, tvOS 9.0, watchOS 2.0, *)
    public lazy var name: String = {
        return String(cString: property_getName(self.value))
    }()
 
    /// Returns the attribute string of a property.
    /// The format of the attribute string is described in Declared Properties in Objective-C Runtime Programming Guide.
    @available(iOS 2.0, macOS 10.5, tvOS 9.0, watchOS 2.0, *)
    public lazy var attributes: String? = {
        guard let attrs = property_getAttributes(self.value) else {
            return nil
        }
        return String(cString: attrs)
    }()
    
    /// Returns an array of property attributes for a property.
    @available(iOS 4.3, macOS 10.7, tvOS 9.0, watchOS 2.0, *)
    public var attributeList: [objc_property_attribute_t]? {
        var outCount: UInt32 = 0
        guard let list = property_copyAttributeList(value, &outCount) else {
            return nil
        }
        defer {
            free(list)
        }
        var count = Int(outCount)
        var buffer = Array(repeating: list.pointee, count: count)
        autoreleasepool {
            while count >= 1 {
                count -= 1
                buffer[count] = list[count]
            }
        }
        return buffer
    }

    /// Returns the value of a property attribute given the attribute name.
    @available(iOS 4.3, macOS 10.7, tvOS 9.0, watchOS 2.0, *)
    public lazy var attributeValue: ((String) -> String?) = {
        return { [weak self] in
            guard
                self != nil,
                let value = property_copyAttributeValue(self!.value, $0.utf8CString.baseAddress!)
            else { return nil }
            defer {
                free(value)
            }
            return String(cString: value)
        }
    }()
}

extension Property {
    
    var subAttributes: [Substring: Substring] {
        var buffer = [Substring: Substring]()
        return attributes?.split(separator: ",").reduce(buffer, { _, e in
            let split = e.index(after: e.startIndex)
            buffer[e[...split]] = e[split...]
            return buffer
        }) ?? [:]
    }
    
    // FIXME: Optional chain
    public var typeEncoding: String? {
        let s = subAttributes[TypeEncoding.typeEncoding.rawValue.subString]
        return s != nil ? String(s!) : nil
    }
    
    // FIXME: Optional chain
    public var iVar: String? {
        let s = subAttributes[TypeEncoding.iVar.rawValue.subString]
        return s != nil ? String(s!) : nil
    }
    
    ///  t<encoding> Specifies the type using old-style encoding.
    // FIXME: Optional chain
    public var typeEncodingOld: String? {
        let s = subAttributes[TypeEncoding.typeEncodingOld.rawValue.subString]
        return s != nil ? String(s!) : nil
    }
    
    public var getter: String? {
        let s = subAttributes[TypeEncoding.getter.rawValue.subString]
        return s != nil ? String(s!) : nil
    }
    
    /// The property defines a custom setter selector name. The name follows the S (for example, ScustomSetter:,).
    public var setter: String? {
        let s = subAttributes[TypeEncoding.setter.rawValue.subString]
        return s != nil ? String(s!) : nil
    }

    /// The property is read-only (readonly).
    public var isReadOnly: Bool {
        return subAttributes.contains(key: TypeEncoding.readOnly.rawValue.subString)
    }
    
    /// The property is a copy of the value last assigned (copy).
    public var isCopy: Bool {
        return subAttributes.contains(key: TypeEncoding.copy.rawValue.subString)
    }
    
    /// The property is a reference to the value last assigned (retain).
    public var isRetain: Bool {
        return subAttributes.contains(key: TypeEncoding.retain.rawValue.subString)
    }
    
    /// The property is non-atomic (nonatomic).
    public var isNonatomic: Bool {
        return subAttributes.contains(key: TypeEncoding.nonatomic.rawValue.subString)
    }
    
    /// The property defines a custom getter selector name. The name follows the G (for example, GcustomGetter,).
    public var hasNamedGetter: Bool {
        return subAttributes.contains(key: TypeEncoding.getter.rawValue.subString)
    }
    
    /// The property defines a custom setter selector name. The name follows the S (for example, ScustomSetter:,).
    public var hasNamedSetter: Bool {
        return subAttributes.contains(key: TypeEncoding.setter.rawValue.subString)
    }
    
    /// The property is dynamic (@dynamic).
    public var isDynamic: Bool {
        return subAttributes.contains(key: TypeEncoding.dynamic.rawValue.subString)
    }
    
    /// The property is a weak reference (__weak).
    public var isWeak: Bool {
        return subAttributes.contains(key: TypeEncoding.weak.rawValue.subString)
    }
    
    /// The property is eligible for garbage collection.
    public var isGarbageCollectionEligible: Bool {
        return subAttributes.contains(key: TypeEncoding.gcEligible.rawValue.subString)
    }
}

