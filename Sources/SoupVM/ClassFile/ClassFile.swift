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

    static let magicNumber: [UInt8] = [0xCA, 0xFE, 0xBA, 0xBE]

    init(bytes: [UInt8]) throws {
        guard Array(bytes[0..<4]) == Self.magicNumber else {
            throw ClassFileError.illegalMagicNumber
        }

        var p = bytes.withUnsafeBytes { $0.baseAddress! }
        p += 4

        self.minorVersion = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
        p += 2
        self.majorVersion = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
        p += 2

        self.constantPoolCount = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
        p += 2

        var constantPool = [ConstantPoolInfo?](repeating: nil, count: Int(self.constantPoolCount - 1))
        for i in 0..<constantPool.count {
            guard let info = ConstantPoolInfo(from: p) else {
                throw ClassFileError.unsupportedConstantPoolInfo(i)
            }
            constantPool[Int(i)] = info
            p += info.size
        }
        self.constantPool = constantPool.compactMap { $0 }

        self.accessFlag = AccessFlag(rawValue: p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian)
        p += 2

        self.thisClassIndex = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
        p += 2

        if constantPool.count <= self.thisClassIndex {
            throw ClassFileError.thisClassIndexOutbound(self.thisClassIndex)
        }
        guard case .class = self.constantPool[Int(self.thisClassIndex - 1)] else {
            throw ClassFileError.thisClassNotClassInfo(self.thisClassIndex)
        }

        self.superClassIndex = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
        p += 2

        if constantPool.count <= self.superClassIndex {
            throw ClassFileError.superClassIndexOutbound(self.superClassIndex)
        }
        if self.superClassIndex != 0 {
            guard case .class = self.constantPool[Int(self.superClassIndex - 1)] else {
                throw ClassFileError.superClassNotClassInfo(self.superClassIndex)
            }
        }

        self.interfacesCount = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
        p += 2

        var interfaces = [UInt16?](repeating: nil, count: Int(self.interfacesCount))
        for i in 0..<interfaces.count {
            let index = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            guard case .class = self.constantPool[Int(index - 1)] else {
                throw ClassFileError.interfaceNotClassInfo(index)
            }
            interfaces[Int(i)] = index
            p += 2
        }
        self.interfaceIndexes = interfaces.compactMap { $0 }

        self.fieldsCount = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
        p += 2

        var fields = [Field?](repeating: nil, count: Int(self.fieldsCount))
        for i in 0..<fields.count {
            let (field, size) = try Field.parse(from: p, with: self.constantPool)
            fields[Int(i)] = field
            p += size
        }
        self.fields = fields.compactMap { $0 }
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
