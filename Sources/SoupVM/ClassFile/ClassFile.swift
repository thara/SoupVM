import Foundation

struct ClassFile {
    let minorVersion: UInt16
    let majorVersion: UInt16

    let constantPoolCount: UInt16
    let constantPool: [ConstantPoolInfo]

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
}

enum ClassFileError: Error {
    case cannotOpen

    case illegalMagicNumber
    case unsupportedConstantPoolInfo(Int)
}
