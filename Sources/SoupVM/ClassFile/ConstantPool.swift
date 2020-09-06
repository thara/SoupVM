/// cp_info
enum ConstantPoolInfo {
    case `class`(nameIndex: UInt16)
    case fieldRef(classIndex: UInt16, nameAndTypeIndex: UInt16)
    case methodRef(classIndex: UInt16, nameAndTypeIndex: UInt16)
    case interfaceMethodRef(classIndex: UInt16, nameAndTypeIndex: UInt16)
    case string(stringIndex: UInt16)
    case integer(bytes: UInt32)
    case float(bytes: UInt32)
    case long(highBytes: UInt32, lowBytes: UInt32)
    case double(highBytes: UInt32, lowBytes: UInt32)
    case nameAndType(nameIndex: UInt16, descriptorIndex: UInt16)
    case utf8(string: String)
    case methodHandle(referenceKind: UInt8, referenceIndex: UInt16)
    case methodType(descriptorIndex: UInt16)
    case invokeDynamic(bootstrapMethodAttrIndex: UInt16, nameAndTypeIndex: UInt16)

    static func parse(from base: UnsafeRawPointer) throws -> (ConstantPoolInfo, Int) {
        var p = base
        let info: ConstantPoolInfo

        let tag = p.next(assumingTo: UInt8.self)

        switch tag {
        case 7:
            let n = p.next(assumingTo: UInt16.self).bigEndian
            info = .`class`(nameIndex: n)
        case 9:
            let classIndex = p.next(assumingTo: UInt16.self).bigEndian
            let nameAndTypeIndex = p.next(assumingTo: UInt16.self).bigEndian
            info = .fieldRef(classIndex: classIndex, nameAndTypeIndex: nameAndTypeIndex)
        case 10:
            let classIndex = p.next(assumingTo: UInt16.self).bigEndian
            let nameAndTypeIndex = p.next(assumingTo: UInt16.self).bigEndian
            info = .methodRef(classIndex: classIndex, nameAndTypeIndex: nameAndTypeIndex)
        case 11:
            let classIndex = p.next(assumingTo: UInt16.self).bigEndian
            let nameAndTypeIndex = p.next(assumingTo: UInt16.self).bigEndian
            info = .interfaceMethodRef(classIndex: classIndex, nameAndTypeIndex: nameAndTypeIndex)
        case 8:
            let stringIndex = p.next(assumingTo: UInt16.self).bigEndian
            info = .string(stringIndex: stringIndex)
        case 3:
            let bytes = p.next(assumingTo: UInt32.self).bigEndian
            info = .integer(bytes: bytes)
        case 4:
            let bytes = p.next(assumingTo: UInt32.self).bigEndian
            info = .float(bytes: bytes)
        case 5:
            let high = p.next(assumingTo: UInt32.self).bigEndian
            let low = p.next(assumingTo: UInt32.self).bigEndian
            info = .long(highBytes: high, lowBytes: low)
        case 6:
            let high = p.next(assumingTo: UInt32.self).bigEndian
            let low = p.next(assumingTo: UInt32.self).bigEndian
            info = .double(highBytes: high, lowBytes: low)
        case 12:
            let nameIndex = p.next(assumingTo: UInt16.self).bigEndian
            let descriptorIndex = p.next(assumingTo: UInt16.self).bigEndian
            info = .nameAndType(nameIndex: nameIndex, descriptorIndex: descriptorIndex)
        case 1:
            let length = p.next(assumingTo: UInt16.self).bigEndian
            let base = p.assumingMemoryBound(to: UInt8.self)
            let bytes = Array(UnsafeBufferPointer(start: base, count: Int(length)))
            p += bytes.count
            info = .utf8(string: String(decoding: bytes, as: UTF8.self))
        case 15:
            let kind = p.next(assumingTo: UInt8.self).bigEndian
            let index = p.next(assumingTo: UInt16.self).bigEndian
            info = .methodHandle(referenceKind: kind, referenceIndex: index)
        case 16:
            let index = p.next(assumingTo: UInt16.self).bigEndian
            info = .methodType(descriptorIndex: index)
        case 18:
            let bootstrapMethodAttrIndex = p.next(assumingTo: UInt16.self).bigEndian
            let nameAndTypeIndex = p.next(assumingTo: UInt16.self).bigEndian
            info = .invokeDynamic(bootstrapMethodAttrIndex: bootstrapMethodAttrIndex, nameAndTypeIndex: nameAndTypeIndex)
        default:
            throw ClassFileError.unsupportedConstantPoolInfo(Int(tag))
        }

        return (info, p - base)
    }
}
