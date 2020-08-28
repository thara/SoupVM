import Foundation

struct ClassFile {
    let minorVersion: UInt16
    let majorVersion: UInt16

    let constantPoolCount: UInt16
    let constantPool: [ConstantPoolInfo]

    let accessFlag: AccessFlag
    let thisClassIndex: UInt16
    let superClassIndex: UInt16

    static let magicNumber: [UInt8] = [0xCA, 0xFE, 0xBA, 0xBE]

    init(bytes: [UInt8]) throws {
        guard Array(bytes[0..<4]) == Self.magicNumber else {
            throw ClassFileError.illegalMagicNumber
        }

        self.minorVersion = bytes.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt16.self).bigEndian }
        self.majorVersion = bytes.withUnsafeBytes { $0.load(fromByteOffset: 6, as: UInt16.self).bigEndian }

        self.constantPoolCount = bytes.withUnsafeBytes { $0.load(fromByteOffset: 8, as: UInt16.self).bigEndian }

        var p = bytes.withUnsafeBytes { $0.baseAddress! + 10 }

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
}

enum ClassFileError: Error {
    case cannotOpen

    case illegalMagicNumber
    case unsupportedConstantPoolInfo(Int)

    case thisClassIndexOutbound(UInt16)
    case thisClassNotClassInfo(UInt16)
    case superClassIndexOutbound(UInt16)
    case superClassNotClassInfo(UInt16)
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
