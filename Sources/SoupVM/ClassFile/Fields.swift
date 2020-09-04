import Foundation

// field_info
struct Field {
    var accessFlags: FieldAccessFlag

    var nameIndex: UInt16
    var descriptorIndex: UInt16

    var attributes: [Attribute]

    static func parse(from base: UnsafeRawPointer, with constantPool: [ConstantPoolInfo]) throws -> (Field, Int) {
        var p = base
        let accessFlags = FieldAccessFlag(rawValue: p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian)
        p += 2

        let nameIndex = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
        p += 2

        let descriptorIndex = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
        p += 2

        let attributesCount = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
        p += 2

        var attributes = [Attribute?](repeating: nil, count: Int(attributesCount))
        for i in 0..<attributes.count {
            let (attribute, size) = try Attribute.parse(from: p, with: constantPool)
            attributes[Int(i)] = attribute
            p += size
        }

        let field = Field(
            accessFlags: accessFlags,
            nameIndex: nameIndex,
            descriptorIndex: descriptorIndex,
            attributes: attributes.compactMap { $0 })
        return (field, p - base)
    }
}

struct FieldAccessFlag: OptionSet {
    let rawValue: UInt16

    static let `public` = FieldAccessFlag(rawValue: 0x0001)
    static let `private` = FieldAccessFlag(rawValue: 0x0002)
    static let protected = FieldAccessFlag(rawValue: 0x0004)
    static let `static` = FieldAccessFlag(rawValue: 0x0008)
    static let final = FieldAccessFlag(rawValue: 0x0010)
    static let volatile = FieldAccessFlag(rawValue: 0x0040)
    static let transient = FieldAccessFlag(rawValue: 0x0080)
    static let synthetic = FieldAccessFlag(rawValue: 0x1000)
    static let `enum` = FieldAccessFlag(rawValue: 0x4000)
}
