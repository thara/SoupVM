import Foundation

struct ClassFile {
    let minorVersion: UInt16
    let majorVersion: UInt16

    static let magicNumber: [UInt8] = [0xCA, 0xFE, 0xBA, 0xBE]

    init(bytes: [UInt8]) throws {
        guard Array(bytes[0..<4]) == Self.magicNumber else {
            throw ClassFileError.illegalMagicNumber
        }

        self.minorVersion = bytes[4..<6].withUnsafeBytes { $0.load(as: UInt16.self) }.bigEndian
        self.majorVersion = bytes[6..<8].withUnsafeBytes { $0.load(as: UInt16.self) }.bigEndian
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
}
