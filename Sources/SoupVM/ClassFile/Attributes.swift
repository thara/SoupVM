// attribute_info
enum Attribute {
    case constantValue(valueIndex: UInt16)
    case synthetic
    case deprecated
    case signature(signatureIndex: UInt16)
    case runtimeVisibleAnnotations(annotations: [Annotation])
    case runtimeInvisibleAnnotations(annotations: [Annotation])
    //TODO
    // case runtimeVisibleTypeAnnotations
    // case runtimeInvisibleTypeAnnotations

    static func parse(from base: UnsafeRawPointer, with constantPool: [ConstantPoolInfo]) throws -> (Attribute, Int) {
        var p = base

        let attributeNameIndex = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
        p += 2

        let attributeLength = p.assumingMemoryBound(to: UInt32.self).pointee.bigEndian
        p += 4

        guard case .utf8(let attrName) = constantPool[Int(attributeNameIndex - 1)] else {
            throw ClassFileError.attributeNameIndexNotUtf8(attributeNameIndex)
        }

        let attr: Attribute
        switch attrName {
        case "ConstantValue":
            guard attributeLength == 2 else {
                throw ClassFileError.invalidAttributeLength(attrName, attributeLength)
            }

            let constantValueIndex = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            p += 2
            switch constantPool[Int(constantValueIndex - 1)] {
            case .long, .float, .double, .integer, .string:
                attr = .constantValue(valueIndex: constantValueIndex)
            default:
                throw ClassFileError.attributeInvalidConstantPoolEntryType(constantValueIndex)
            }
        case "Synthetic":
            guard attributeLength == 0 else {
                throw ClassFileError.invalidAttributeLength(attrName, attributeLength)
            }
            attr = .synthetic
        case "Deprecated":
            guard attributeLength == 0 else {
                throw ClassFileError.invalidAttributeLength(attrName, attributeLength)
            }
            attr = .deprecated
        case "Signature":
            guard attributeLength == 2 else {
                throw ClassFileError.invalidAttributeLength(attrName, attributeLength)
            }
            let signatureIndex = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            p += 2
            guard case .utf8 = constantPool[Int(signatureIndex - 1)] else {
                throw ClassFileError.attributeInvalidConstantPoolEntryType(signatureIndex)
            }
            attr = .signature(signatureIndex: signatureIndex)
        case "RuntimeVisibleAnnotations":
            let numAnnotations = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            p += 2

            var annotations = [Annotation?](repeating: nil, count: Int(numAnnotations))
            for i in 0..<annotations.count {
                annotations[i] = try Annotation(from: p, with: constantPool)
            }
            attr = .runtimeVisibleAnnotations(annotations: annotations.compactMap { $0 })
        case "RuntimeInvisibleAnnotations":
            let numAnnotations = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            p += 2

            var annotations = [Annotation?](repeating: nil, count: Int(numAnnotations))
            for i in 0..<annotations.count {
                annotations[i] = try Annotation(from: p, with: constantPool)
            }
            attr = .runtimeInvisibleAnnotations(annotations: annotations.compactMap { $0 })
        default:
            throw ClassFileError.unsupportedAttributeName(attrName)
        }

        return (attr, p - base)
    }
}

struct Annotation {
    var typeIndex: UInt16

    typealias ElementValuePair = (elementNameIndex: UInt16, value: ElementValue)
    var elementValuePairs: [ElementValuePair]

    enum ElementValue {
        case constValueIndex(UInt16)
        case enumConstValue(typeNameIndex: UInt16, constNameIndex: UInt16)
        case classInfoIndex(UInt16)
        case annotationValue(Annotation)
        indirect case arrayValue([ElementValue])
    }

    init(from p: UnsafeRawPointer, with constantPool: [ConstantPoolInfo]) throws {
        var p = p

        let typeIndex = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
        p += 2

        let numElementValuePairs = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
        p += 2

        var pairs = [ElementValuePair?](repeating: nil, count: Int(numElementValuePairs))
        for i in 0..<pairs.count {
            let nameIndex = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            p += 2
            pairs[i] = (elementNameIndex: nameIndex, value: try ElementValue(from: p, with: constantPool))
        }

        self.typeIndex = typeIndex
        self.elementValuePairs = pairs.compactMap { $0 }
    }
}

extension Annotation.ElementValue {

    init(from p: UnsafeRawPointer, with constantPool: [ConstantPoolInfo]) throws {
        var p = p

        let tag = p.assumingMemoryBound(to: UInt8.self).pointee.bigEndian
        p += 1

        switch tag {
        case Character("B").asciiValue, Character("C").asciiValue:
            let index = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            guard case .integer = constantPool[Int(index - 1)] else {
                throw ClassFileError.attributeElementValueInvalidConstantPoolEntryType(index)
            }
            self = .constValueIndex(index)
        case Character("D").asciiValue:
            let index = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            guard case .double = constantPool[Int(index - 1)] else {
                throw ClassFileError.attributeElementValueInvalidConstantPoolEntryType(index)
            }
            self = .constValueIndex(index)
        case Character("F").asciiValue:
            let index = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            guard case .float = constantPool[Int(index - 1)] else {
                throw ClassFileError.attributeElementValueInvalidConstantPoolEntryType(index)
            }
            self = .constValueIndex(index)
        case Character("I").asciiValue:
            let index = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            guard case .integer = constantPool[Int(index - 1)] else {
                throw ClassFileError.attributeElementValueInvalidConstantPoolEntryType(index)
            }
            self = .constValueIndex(index)
        case Character("J").asciiValue:
            let index = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            guard case .long = constantPool[Int(index - 1)] else {
                throw ClassFileError.attributeElementValueInvalidConstantPoolEntryType(index)
            }
            self = .constValueIndex(index)
        case Character("S").asciiValue:
            let index = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            guard case .integer = constantPool[Int(index - 1)] else {
                throw ClassFileError.attributeElementValueInvalidConstantPoolEntryType(index)
            }
            self = .constValueIndex(index)
        case Character("Z").asciiValue:
            let index = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            guard case .integer = constantPool[Int(index - 1)] else {
                throw ClassFileError.attributeElementValueInvalidConstantPoolEntryType(index)
            }
            self = .constValueIndex(index)
        case Character("s").asciiValue:
            let index = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            guard case .utf8 = constantPool[Int(index - 1)] else {
                throw ClassFileError.attributeElementValueInvalidConstantPoolEntryType(index)
            }
            self = .constValueIndex(index)
        case Character("e").asciiValue:
            let typeNameIndex = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            guard case .utf8 = constantPool[Int(typeNameIndex + 1)] else {
                throw ClassFileError.attributeElementValueInvalidConstantPoolEntryType(typeNameIndex)
            }
            let constNameIndex = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            guard case .utf8 = constantPool[Int(constNameIndex + 1)] else {
                throw ClassFileError.attributeElementValueInvalidConstantPoolEntryType(constNameIndex)
            }
            self = .enumConstValue(typeNameIndex: typeNameIndex, constNameIndex: constNameIndex)
        case Character("c").asciiValue:
            let index = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
            guard case .utf8 = constantPool[Int(index + 1)] else {
                throw ClassFileError.attributeElementValueInvalidConstantPoolEntryType(index)
            }
            self = .classInfoIndex(index)
        case Character("@").asciiValue:
            let annotation = try Annotation(from: p, with: constantPool)
            self = .annotationValue(annotation)
        case Character("[").asciiValue:
            let numValues = p.assumingMemoryBound(to: UInt16.self).pointee.bigEndian

            var values = [Self?](repeating: nil, count: Int(numValues))
            for i in 0..<values.count {
                values[i] = try Self(from: p, with: constantPool)
            }
            self = .arrayValue(values.compactMap { $0 })
        default:
            throw ClassFileError.unsupportedAnnotationelementValueTag(tag)
        }
    }
}
