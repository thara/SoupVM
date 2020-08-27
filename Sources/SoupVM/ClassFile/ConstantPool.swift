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

    init?(from p: UnsafeRawPointer) {
        switch p.load(as: UInt8.self) {
        case 7:
            let n = (p + 1).assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            self = .`class`(nameIndex: n)
        case 9:
            let classIndex = (p + 1).assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            let nameAndTypeIndex = (p + 3).assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            self = .fieldRef(classIndex: classIndex, nameAndTypeIndex: nameAndTypeIndex)
        case 10:
            let classIndex = (p + 1).assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            let nameAndTypeIndex = (p + 3).assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            self = .methodRef(classIndex: classIndex, nameAndTypeIndex: nameAndTypeIndex)
        case 11:
            let classIndex = (p + 1).assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            let nameAndTypeIndex = (p + 1).assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            self = .interfaceMethodRef(classIndex: classIndex, nameAndTypeIndex: nameAndTypeIndex)
        case 8:
            let stringIndex = (p + 1).assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            self = .string(stringIndex: stringIndex)
        case 3:
            let bytes = (p + 1).assumingMemoryBound(to: UInt32.self).pointee.bigEndian
            self = .integer(bytes: bytes)
        case 4:
            let bytes = (p + 1).assumingMemoryBound(to: UInt32.self).pointee.bigEndian
            self = .float(bytes: bytes)
        case 5:
            let high = (p + 1).assumingMemoryBound(to: UInt32.self).pointee.bigEndian
            let low = (p + 5).assumingMemoryBound(to: UInt32.self).pointee.bigEndian
            self = .long(highBytes: high, lowBytes: low)
        case 6:
            let high = (p + 1).assumingMemoryBound(to: UInt32.self).pointee.bigEndian
            let low = (p + 5).assumingMemoryBound(to: UInt32.self).pointee.bigEndian
            self = .double(highBytes: high, lowBytes: low)
        case 12:
            let nameIndex = (p + 1).assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            let descriptorIndex = (p + 3).assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            self = .nameAndType(nameIndex: nameIndex, descriptorIndex: descriptorIndex)
        case 1:
            let length = (p + 1).assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            let base = (p + 3).assumingMemoryBound(to: UInt8.self)
            let bytes = Array(UnsafeBufferPointer(start: base, count: Int(length)))
            self = .utf8(string: String(decoding: bytes, as: UTF8.self))
        case 15:
            let kind = (p + 1).assumingMemoryBound(to: UInt8.self).pointee.bigEndian
            let index = (p + 2).assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            self = .methodHandle(referenceKind: kind, referenceIndex: index)
        case 16:
            let index = (p + 1).assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            self = .methodType(descriptorIndex: index)
        case 18:
            let bootstrapMethodAttrIndex = (p + 1).assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            let nameAndTypeIndex = (p + 3).assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            self = .invokeDynamic(bootstrapMethodAttrIndex: bootstrapMethodAttrIndex, nameAndTypeIndex: nameAndTypeIndex)
        default:
            return nil
        }
    }

    var size: Int {
        switch self {
        case .`class`:
            return 3
        case .fieldRef, .methodRef, .interfaceMethodRef:
            return 5
        case .string:
            return 3
        case .integer, .float:
            return 5
        case .long, .double:
            return 9
        case .nameAndType:
            return 5
        case .utf8(let bytes):
            return 3 + bytes.count
        case .methodHandle:
            return 4
        case .methodType:
            return 3
        case .invokeDynamic:
            return 5
        }
    }
}
