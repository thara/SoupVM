import Foundation

// field_info
struct Field {
    var accessFlags: FieldAccessFlag

    var nameIndex: UInt16
    var descriptorIndex: UInt16

    var attributes: [Attribute]
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

extension UnsafeRawPointer {
    mutating func nextField(with constantPool: [ConstantPoolInfo]) throws -> Field {
        let accessFlags = FieldAccessFlag(rawValue: self.next(assumingTo: UInt16.self).bigEndian)
        let nameIndex = self.next(assumingTo: UInt16.self).bigEndian
        let descriptorIndex = self.next(assumingTo: UInt16.self).bigEndian
        let attributesCount = self.next(assumingTo: UInt16.self).bigEndian

        var attributes = [Attribute?](repeating: nil, count: Int(attributesCount))
        for i in 0..<attributes.count {
            attributes[Int(i)] = try self.nextAttribute(with: constantPool)
        }

        let field = Field(
            accessFlags: accessFlags,
            nameIndex: nameIndex,
            descriptorIndex: descriptorIndex,
            attributes: attributes.compactMap { $0 })
        return field
    }
}
