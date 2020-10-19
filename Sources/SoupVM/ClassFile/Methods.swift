// method_info
struct Method {
    var accessFlags: MethodAccessFlag

    var nameIndex: UInt16
    var descriptorIndex: UInt16

    var attributes: [Attribute]
}

struct MethodAccessFlag: OptionSet {
    let rawValue: UInt16

    static let `public` = MethodAccessFlag(rawValue: 0x0001)
    static let `private` = MethodAccessFlag(rawValue: 0x0002)
    static let protected = MethodAccessFlag(rawValue: 0x0004)
    static let `static` = MethodAccessFlag(rawValue: 0x0008)
    static let final = MethodAccessFlag(rawValue: 0x0010)
    static let synchronized = MethodAccessFlag(rawValue: 0x0020)
    static let bridge = MethodAccessFlag(rawValue: 0x0040)
    static let varargs = MethodAccessFlag(rawValue: 0x0080)
    static let native = MethodAccessFlag(rawValue: 0x0100)
    static let abstract = MethodAccessFlag(rawValue: 0x0400)
    static let strict = MethodAccessFlag(rawValue: 0x0800)
    static let synthetic = MethodAccessFlag(rawValue: 0x1000)
}

extension UnsafeRawPointer {
    mutating func nextMethod(with constantPool: [ConstantPoolInfo]) throws -> Method {
        let accessFlags = MethodAccessFlag(rawValue: self.next(assumingTo: UInt16.self).bigEndian)
        let nameIndex = self.next(assumingTo: UInt16.self).bigEndian
        let descriptorIndex = self.next(assumingTo: UInt16.self).bigEndian

        let attributesCount = self.next(assumingTo: UInt16.self).bigEndian
        let attributes = try makeArray(count: Int(attributesCount)) { try self.nextAttribute(with: constantPool, for: .methodInfo) }

        let field = Method(
            accessFlags: accessFlags,
            nameIndex: nameIndex,
            descriptorIndex: descriptorIndex,
            attributes: attributes)
        return field
    }
}

// for attributes

struct ExceptionTableEntry {
    var startPC: UInt16
    var endPC: UInt16
    var handlerPC: UInt16
    var catchType: UInt16
}

extension UnsafeRawPointer {

    mutating func nextExceptionTableEntry(with constantPool: [ConstantPoolInfo]) throws -> ExceptionTableEntry {
        let startPC = self.next(assumingTo: UInt16.self).bigEndian
        let endPC = self.next(assumingTo: UInt16.self).bigEndian
        let handlerPC = self.next(assumingTo: UInt16.self).bigEndian
        let catchType = self.next(assumingTo: UInt16.self).bigEndian

        guard case .class = constantPool[Int(catchType - 1)] else {
            throw ClassFileError.invalidExceptionTableEntryCatchTypeIndex(catchType)
        }
        return ExceptionTableEntry(
            startPC: startPC,
            endPC: endPC,
            handlerPC: handlerPC,
            catchType: catchType)
    }
}
