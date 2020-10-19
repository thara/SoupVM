import Foundation

struct ClassEntry {
    var innerClassInfoIndex: UInt16
    var outerClassInfoIndex: UInt16
    var innerNameIndex: UInt16
    var innerClassAccessFlag: InnerClassAccessFlag
}

struct InnerClassAccessFlag: OptionSet {
    let rawValue: UInt16

    static let `public` = InnerClassAccessFlag(rawValue: 0x0001)
    static let `private` = InnerClassAccessFlag(rawValue: 0x0002)
    static let `protected` = InnerClassAccessFlag(rawValue: 0x0004)
    static let `static` = InnerClassAccessFlag(rawValue: 0x0008)
    static let `final` = InnerClassAccessFlag(rawValue: 0x0010)
    static let `interface` = InnerClassAccessFlag(rawValue: 0x0200)
    static let `abstract` = InnerClassAccessFlag(rawValue: 0x0400)
    static let `synthetic` = InnerClassAccessFlag(rawValue: 0x1000)
    static let `annotation` = InnerClassAccessFlag(rawValue: 0x2000)
    static let `enum` = InnerClassAccessFlag(rawValue: 0x4000)
}

extension UnsafeRawPointer {

    mutating func nextClassEntry(with constantPool: [ConstantPoolInfo]) throws -> ClassEntry {
        let innerClassInfoIndex = self.next(assumingTo: UInt16.self).bigEndian
        guard case .class = constantPool[Int(innerClassInfoIndex) + 1] else {
            throw ClassFileError.invalidClassEntryIndex(innerClassInfoIndex)
        }
        let outerClassInfoIndex = self.next(assumingTo: UInt16.self).bigEndian
        if outerClassInfoIndex != 0 {
            // a member of a class or a interface
            guard case .class = constantPool[Int(outerClassInfoIndex) + 1] else {
                throw ClassFileError.invalidClassEntryIndex(outerClassInfoIndex)
            }
        }
        let innerNameIndex = self.next(assumingTo: UInt16.self).bigEndian
        if innerNameIndex != 0 {
            // not anonymous
            guard case .utf8 = constantPool[Int(innerNameIndex) + 1] else {
                throw ClassFileError.invalidClassEntryIndex(outerClassInfoIndex)
            }
        }
        let innerClassAccessFlag = self.next(assumingTo: UInt16.self).bigEndian
        return ClassEntry(
            innerClassInfoIndex: innerClassInfoIndex,
            outerClassInfoIndex: outerClassInfoIndex,
            innerNameIndex: innerNameIndex,
            innerClassAccessFlag: InnerClassAccessFlag(rawValue: innerClassAccessFlag)
        )
    }
}
