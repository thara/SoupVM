import Foundation

struct ClassFile {
    let minorVersion: UInt16
    let majorVersion: UInt16

    let constantPoolCount: UInt16
    let constantPool: [ConstantPoolInfo]

    let accessFlag: AccessFlag
    let thisClassIndex: UInt16
    let superClassIndex: UInt16

    let interfacesCount: UInt16
    let interfaceIndexes: [UInt16]

    let fieldsCount: UInt16
    let fields: [Field]

    let methodsCount: UInt16
    let methods: [Method]

    let attributesCount: UInt16
    let attributes: [Attribute]

    static let magicNumber: [UInt8] = [0xCA, 0xFE, 0xBA, 0xBE]

    init(bytes: [UInt8]) throws {
        guard Array(bytes[0..<4]) == Self.magicNumber else {
            throw ClassFileError.illegalMagicNumber
        }

        var p = bytes.withUnsafeBytes { $0.baseAddress! }
        p += 4

        self.minorVersion = p.next(assumingTo: UInt16.self).bigEndian
        self.majorVersion = p.next(assumingTo: UInt16.self).bigEndian
        self.constantPoolCount = p.next(assumingTo: UInt16.self).bigEndian

        let constantPool = try makeArray(count: Int(self.constantPoolCount - 1)) { try p.nextConstantPoolInfo() }
        self.constantPool = constantPool

        self.accessFlag = AccessFlag(rawValue: p.next(assumingTo: UInt16.self).bigEndian)
        self.thisClassIndex = p.next(assumingTo: UInt16.self).bigEndian

        if constantPool.count <= self.thisClassIndex {
            throw ClassFileError.thisClassIndexOutbound(self.thisClassIndex)
        }
        guard case .class = self.constantPool[Int(self.thisClassIndex - 1)] else {
            throw ClassFileError.thisClassNotClassInfo(self.thisClassIndex)
        }

        self.superClassIndex = p.next(assumingTo: UInt16.self).bigEndian

        if constantPool.count <= self.superClassIndex {
            throw ClassFileError.superClassIndexOutbound(self.superClassIndex)
        }
        if self.superClassIndex != 0 {
            guard case .class = self.constantPool[Int(self.superClassIndex - 1)] else {
                throw ClassFileError.superClassNotClassInfo(self.superClassIndex)
            }
        }

        self.interfacesCount = p.next(assumingTo: UInt16.self).bigEndian
        self.interfaceIndexes = try makeArray(count: Int(self.interfacesCount)) {
            let index = p.next(assumingTo: UInt16.self).bigEndian
            guard case .class = constantPool[Int(index - 1)] else {
                throw ClassFileError.interfaceNotClassInfo(index)
            }
            return index
        }

        self.fieldsCount = p.next(assumingTo: UInt16.self).bigEndian
        self.fields = try makeArray(count: Int(self.fieldsCount)) { try p.nextField(with: constantPool) }

        self.methodsCount = p.next(assumingTo: UInt16.self).bigEndian
        self.methods = try makeArray(count: Int(self.methodsCount)) { try p.nextMethod(with: constantPool) }

        self.attributesCount = p.next(assumingTo: UInt16.self).bigEndian
        self.attributes = try makeArray(count: Int(self.attributesCount)) { try p.nextAttribute(with: constantPool, for: .classFile) }
    }

    init(forReadingAtPath path: String) throws {
        guard let f = FileHandle(forReadingAtPath: path) else {
            throw ClassFileError.cannotOpen
        }
        defer {
            f.closeFile()
        }
        try self.init(bytes: [UInt8](f.readDataToEndOfFile()))
    }

    var version: String {
        "\(majorVersion).\(minorVersion)"
    }

    var thisClass: ConstantPoolInfo {
        constantPool[Int(thisClassIndex - 1)]
    }

    var superClass: ConstantPoolInfo? {
        0 < superClassIndex ? constantPool[Int(superClassIndex - 1)] : nil
    }

    var interfaces: [ConstantPoolInfo] {
        interfaceIndexes.map { constantPool[Int($0 - 1)] }
    }
}

enum ClassFileError: Error {
    case cannotOpen

    case illegalMagicNumber
    case unsupportedConstantPoolInfo(Int)

    case thisClassIndexOutbound(UInt16)
    case thisClassNotClassInfo(UInt16)
    case superClassIndexOutbound(UInt16)
    case superClassNotClassInfo(UInt16)

    case interfaceNotClassInfo(UInt16)

    case attributeNameIndexNotUtf8(UInt16)
    case unsupportedAttributeName(String)
    case invalidAttributeLength(String, UInt32)

    case attributeInvalidConstantPoolEntryType(UInt16)
    case attributeElementValueInvalidConstantPoolEntryType(UInt16)

    case unsupportedAnnotationelementValueTag(UInt8)

    case unsupportedTypeAnnotationTarget(UInt8)

    case invalidExceptionTableEntryCatchTypeIndex(UInt16)

    case invalidClassEntryIndex(UInt16)

    case invalidBootstrapMethodIndex(UInt16)

    case invalidLocalVariableNameIndex(UInt16)
    case invalidLocalVariableDescriptorIndex(UInt16)

    case invalidLocalVariableTypeNameIndex(UInt16)
    case invalidLocalVariableTypeSignatureIndex(UInt16)
}

struct AccessFlag: OptionSet {
    let rawValue: UInt16

    static let `public` = AccessFlag(rawValue: 0x0001)
    static let final = AccessFlag(rawValue: 0x0010)
    static let `super` = AccessFlag(rawValue: 0x0020)
    static let interface = AccessFlag(rawValue: 0x0200)
    static let abstract = AccessFlag(rawValue: 0x0400)
    static let synthetic = AccessFlag(rawValue: 0x1000)
    static let annotation = AccessFlag(rawValue: 0x2000)
    static let `enum` = AccessFlag(rawValue: 0x4000)
}

extension UnsafeRawPointer {

    mutating func next<T>(assumingTo type: T.Type) -> T {
        let value = self.assumingMemoryBound(to: type).pointee
        self += MemoryLayout<T>.size
        return value
    }
}

func makeArray<T>(count: Int, next: () throws -> T) throws -> [T] {
    var array = [T?](repeating: nil, count: count)
    for i in 0..<count {
        array[Int(i)] = try next()
    }
    return array.compactMap { $0 }
}
