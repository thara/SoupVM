// attribute_info
enum Attribute {
    case constantValue(valueIndex: UInt16)
    case synthetic
    case deprecated
    case signature(signatureIndex: UInt16)
    case runtimeVisibleAnnotations
    case runtimeInvisibleAnnotations
    case runtimeVisibleTypeAnnotations
    case runtimeInvisibleTypeAnnotations

    init(from p: UnsafeRawPointer, with constantPool: [ConstantPoolInfo]) throws {
        var p = p

        let attributeNameIndex = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
        p += 2

        let attributeLength = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
        p += 2

        guard case .utf8(let attrName) = constantPool[Int(attributeNameIndex - 1)] else {
            throw ClassFileError.attributeNameIndexNotUtf8(attributeNameIndex)
        }

        switch attrName {
        case "ConstantValue":
            guard attributeLength == 2 else {
                throw ClassFileError.invalidAttributeLength(attrName, attributeLength)
            }

            let constantValueIndex = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            p += 2
            switch constantPool[Int(constantValueIndex + 1)] {
            case .long, .float, .double, .integer, .string:
                self = .constantValue(valueIndex: constantValueIndex)
            default:
                throw ClassFileError.attributeInvalidConstantPoolEntryType(constantValueIndex)
            }
        case "Synthetic":
            guard attributeLength == 0 else {
                throw ClassFileError.invalidAttributeLength(attrName, attributeLength)
            }
            self = .synthetic
        case "Deprecated":
            guard attributeLength == 0 else {
                throw ClassFileError.invalidAttributeLength(attrName, attributeLength)
            }
            self = .deprecated
        case "Signature":
            guard attributeLength == 2 else {
                throw ClassFileError.invalidAttributeLength(attrName, attributeLength)
            }
            let signatureIndex = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            p += 2
            guard case .utf8 = constantPool[Int(signatureIndex + 1)] else {
                throw ClassFileError.attributeInvalidConstantPoolEntryType(signatureIndex)
            }
            self = .signature(signatureIndex: signatureIndex)
        default:
            throw ClassFileError.unsupportedAttributeName
        }
    }
}
