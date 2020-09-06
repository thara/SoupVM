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
}

extension UnsafeRawPointer {

    mutating func nextAttribute(with constantPool: [ConstantPoolInfo]) throws -> Attribute {
        let attributeNameIndex = self.next(assumingTo: UInt16.self).bigEndian
        let attributeLength = self.next(assumingTo: UInt32.self).bigEndian

        guard case .utf8(let attrName) = constantPool[Int(attributeNameIndex - 1)] else {
            throw ClassFileError.attributeNameIndexNotUtf8(attributeNameIndex)
        }

        let attr: Attribute
        switch attrName {
        case "ConstantValue":
            guard attributeLength == 2 else {
                throw ClassFileError.invalidAttributeLength(attrName, attributeLength)
            }

            let constantValueIndex = self.next(assumingTo: UInt16.self).bigEndian
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
            let signatureIndex = self.next(assumingTo: UInt16.self).bigEndian
            guard case .utf8 = constantPool[Int(signatureIndex - 1)] else {
                throw ClassFileError.attributeInvalidConstantPoolEntryType(signatureIndex)
            }
            attr = .signature(signatureIndex: signatureIndex)
        case "RuntimeVisibleAnnotations":
            let numAnnotations = self.next(assumingTo: UInt16.self).bigEndian

            var annotations = [Annotation?](repeating: nil, count: Int(numAnnotations))
            for i in 0..<annotations.count {
                annotations[i] = try self.nextAnnotation(with: constantPool)
            }
            attr = .runtimeVisibleAnnotations(annotations: annotations.compactMap { $0 })
        case "RuntimeInvisibleAnnotations":
            let numAnnotations = self.next(assumingTo: UInt16.self).bigEndian

            var annotations = [Annotation?](repeating: nil, count: Int(numAnnotations))
            for i in 0..<annotations.count {
                annotations[i] = try self.nextAnnotation(with: constantPool)
            }
            attr = .runtimeInvisibleAnnotations(annotations: annotations.compactMap { $0 })
        default:
            throw ClassFileError.unsupportedAttributeName(attrName)
        }

        return attr
    }

    mutating func nextAnnotation(with constantPool: [ConstantPoolInfo]) throws -> Annotation {
        let typeIndex = self.next(assumingTo: UInt16.self).bigEndian
        let numElementValuePairs = self.next(assumingTo: UInt16.self).bigEndian

        var pairs = [Annotation.ElementValuePair?](repeating: nil, count: Int(numElementValuePairs))
        for i in 0..<pairs.count {
            let nameIndex = self.next(assumingTo: UInt16.self).bigEndian
            pairs[i] = (elementNameIndex: nameIndex, value: try self.nextAnnotationElementValue(with: constantPool))
        }

        return Annotation(typeIndex: typeIndex, elementValuePairs: pairs.compactMap { $0 })
    }

    mutating func nextAnnotationElementValue(with constantPool: [ConstantPoolInfo]) throws -> Annotation.ElementValue {
        let tag = self.next(assumingTo: UInt8.self).bigEndian

        switch tag {
        case Character("B").asciiValue, Character("C").asciiValue:
            let index = self.next(assumingTo: UInt16.self).bigEndian
            guard case .integer = constantPool[Int(index - 1)] else {
                throw ClassFileError.attributeElementValueInvalidConstantPoolEntryType(index)
            }
            return .constValueIndex(index)
        case Character("D").asciiValue:
            let index = self.next(assumingTo: UInt16.self).bigEndian
            guard case .double = constantPool[Int(index - 1)] else {
                throw ClassFileError.attributeElementValueInvalidConstantPoolEntryType(index)
            }
            return .constValueIndex(index)
        case Character("F").asciiValue:
            let index = self.next(assumingTo: UInt16.self).bigEndian
            guard case .float = constantPool[Int(index - 1)] else {
                throw ClassFileError.attributeElementValueInvalidConstantPoolEntryType(index)
            }
            return .constValueIndex(index)
        case Character("I").asciiValue:
            let index = self.next(assumingTo: UInt16.self).bigEndian
            guard case .integer = constantPool[Int(index - 1)] else {
                throw ClassFileError.attributeElementValueInvalidConstantPoolEntryType(index)
            }
            return .constValueIndex(index)
        case Character("J").asciiValue:
            let index = self.next(assumingTo: UInt16.self).bigEndian
            guard case .long = constantPool[Int(index - 1)] else {
                throw ClassFileError.attributeElementValueInvalidConstantPoolEntryType(index)
            }
            return .constValueIndex(index)
        case Character("S").asciiValue:
            let index = self.next(assumingTo: UInt16.self).bigEndian
            guard case .integer = constantPool[Int(index - 1)] else {
                throw ClassFileError.attributeElementValueInvalidConstantPoolEntryType(index)
            }
            return .constValueIndex(index)
        case Character("Z").asciiValue:
            let index = self.next(assumingTo: UInt16.self).bigEndian
            guard case .integer = constantPool[Int(index - 1)] else {
                throw ClassFileError.attributeElementValueInvalidConstantPoolEntryType(index)
            }
            return .constValueIndex(index)
        case Character("s").asciiValue:
            let index = self.next(assumingTo: UInt16.self).bigEndian
            guard case .utf8 = constantPool[Int(index - 1)] else {
                throw ClassFileError.attributeElementValueInvalidConstantPoolEntryType(index)
            }
            return .constValueIndex(index)
        case Character("e").asciiValue:
            let typeNameIndex = self.next(assumingTo: UInt16.self).bigEndian
            guard case .utf8 = constantPool[Int(typeNameIndex + 1)] else {
                throw ClassFileError.attributeElementValueInvalidConstantPoolEntryType(typeNameIndex)
            }
            let constNameIndex = self.next(assumingTo: UInt16.self).bigEndian
            guard case .utf8 = constantPool[Int(constNameIndex + 1)] else {
                throw ClassFileError.attributeElementValueInvalidConstantPoolEntryType(constNameIndex)
            }
            return .enumConstValue(typeNameIndex: typeNameIndex, constNameIndex: constNameIndex)
        case Character("c").asciiValue:
            let index = self.next(assumingTo: UInt16.self).bigEndian
            guard case .utf8 = constantPool[Int(index + 1)] else {
                throw ClassFileError.attributeElementValueInvalidConstantPoolEntryType(index)
            }
            return .classInfoIndex(index)
        case Character("@").asciiValue:
            let annotation = try self.nextAnnotation(with: constantPool)
            return .annotationValue(annotation)
        case Character("[").asciiValue:
            let numValues = self.next(assumingTo: UInt16.self).bigEndian

            var values = [Annotation.ElementValue?](repeating: nil, count: Int(numValues))
            for i in 0..<values.count {
                values[i] = try self.nextAnnotationElementValue(with: constantPool)
            }
            return .arrayValue(values.compactMap { $0 })
        default:
            throw ClassFileError.unsupportedAnnotationelementValueTag(tag)
        }
    }
}
