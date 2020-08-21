import Foundation

struct ClassFile {
    static let magicNumber: [UInt8] = [0xCA, 0xFE, 0xBA, 0xBE]

    init(bytes: [UInt8]) throws {
        guard Array(bytes[0..<4]) == Self.magicNumber else {
            throw ClassFileError.illegalMagicNumber
        }
    }

    init(path: String) throws {
        guard let f = FileHandle(forReadingAtPath: path) else {
            throw ClassFileError.cannotOpen
        }
        defer {
            f.closeFile()
        }
        try self.init(bytes: [UInt8](f.readDataToEndOfFile()))
    }
}

enum ClassFileError: Error {
    case cannotOpen

    case illegalMagicNumber
}
