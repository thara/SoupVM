// attribute_info
enum Attribute {
    case constantValue(valueIndex: UInt16)
    case code(maxStack: UInt16, maxLocals: UInt16, code: [UInt8], exceptionTable: [ExceptionTableEntry], attributes: [Attribute])
    case exceptions(exceptionIndexTable: [UInt16])
    case runtimeVisibleParameterAnnotations(parameterAnnotations: [[Annotation]])
    case synthetic
    case deprecated
    case signature(signatureIndex: UInt16)
    case runtimeVisibleAnnotations(annotations: [Annotation])
    case runtimeInvisibleAnnotations(annotations: [Annotation])
    case runtimeVisibleTypeAnnotations(annotations: [TypeAnnotation])
    case runtimeInvisibleTypeAnnotations(annotations: [TypeAnnotation])
}

typealias AnnotationElementValuePair = (elementNameIndex: UInt16, value: AnnotationElementValue)

enum AnnotationElementValue {
    case constValueIndex(UInt16)
    case enumConstValue(typeNameIndex: UInt16, constNameIndex: UInt16)
    case classInfoIndex(UInt16)
    case annotationValue(Annotation)
    indirect case arrayValue([AnnotationElementValue])
}

struct Annotation {
    var typeIndex: UInt16
    var elementValuePairs: [AnnotationElementValuePair]
}

struct TypeAnnotation {

    enum Target {
        case typeParameter(index: UInt8)
        case superType(index: UInt16)
        case typeParameterBound(typeParameterIndex: UInt8, boundIndex: UInt8)
        case empty
        case formalParameter(index: UInt8)
        case `throws`(index: UInt16)
        case localvar(table: [LocalVariable])
        case `catch`(exceptionTableIndex: UInt16)
        case offset(UInt16)
        case typeArgument(offset: UInt16, typeArgumentIndex: UInt8)

        struct LocalVariable {
            var startPC: UInt16
            var length: UInt16
            var index: UInt16
        }
    }

    struct TypePath {
        var path: [Path]

        struct Path {
            var typePathKind: UInt8
            var typeArgumentIndex: UInt8
        }
    }

    var targetInfo: Target
    var targetPath: TypePath
    var elementValuePairs: [AnnotationElementValuePair]
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
        case "Code":
            let maxStack = self.next(assumingTo: UInt16.self).bigEndian
            let maxLocals = self.next(assumingTo: UInt16.self).bigEndian
            let codeLength = self.next(assumingTo: UInt32.self).bigEndian

            let base = self.assumingMemoryBound(to: UInt8.self)
            let code = Array(UnsafeBufferPointer(start: base, count: Int(codeLength)))
            self += code.count

            let exceptionTableLength = Int(self.next(assumingTo: UInt16.self).bigEndian)
            let exceptionTable = try makeArray(count: exceptionTableLength) {
                try self.nextExceptionTableEntry(with: constantPool)
            }

            let attributeCount = Int(self.next(assumingTo: UInt16.self).bigEndian)
            let attributes = try makeArray(count: attributeCount) {
                try self.nextAttribute(with: constantPool)
            }

            attr = .code(maxStack: maxStack, maxLocals: maxLocals, code: code, exceptionTable: exceptionTable, attributes: attributes)
        case "Exceptions":
            let numberOfExceptions = Int(self.next(assumingTo: UInt16.self).bigEndian)
            let table: [UInt16] = try makeArray(count: numberOfExceptions) {
                let index = self.next(assumingTo: UInt16.self).bigEndian
                guard case .class = constantPool[Int(index + 1)] else {
                    throw ClassFileError.attributeInvalidConstantPoolEntryType(index)
                }
                return index
            }

            attr = .exceptions(exceptionIndexTable: table)
        case "RuntimeVisibleParameterAnnotations":
            let numParameters = Int(self.next(assumingTo: UInt8.self).bigEndian)
            let parameterAnnotations: [[Annotation]] = try makeArray(count: numParameters) {
                let numAnnotations = Int(self.next(assumingTo: UInt16.self).bigEndian)
                return try makeArray(count: numAnnotations) {
                    try nextAnnotation(with: constantPool)
                }
            }

            attr = .runtimeVisibleParameterAnnotations(parameterAnnotations: parameterAnnotations)
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
            let annotations = try makeArray(count: Int(numAnnotations)) { try self.nextAnnotation(with: constantPool) }

            attr = .runtimeVisibleAnnotations(annotations: annotations)
        case "RuntimeInvisibleAnnotations":
            let numAnnotations = self.next(assumingTo: UInt16.self).bigEndian
            let annotations = try makeArray(count: Int(numAnnotations)) { try self.nextAnnotation(with: constantPool) }

            attr = .runtimeInvisibleAnnotations(annotations: annotations)
        case "RuntimeVisibleTypeAnnotations":
            let numAnnotations = self.next(assumingTo: UInt16.self).bigEndian
            let annotations = try makeArray(count: Int(numAnnotations)) { try self.nextTypeAnnotation(with: constantPool) }

            attr = .runtimeVisibleTypeAnnotations(annotations: annotations)
        case "RuntimeInvisibleTypeAnnotations":
            let numAnnotations = self.next(assumingTo: UInt16.self).bigEndian
            let annotations = try makeArray(count: Int(numAnnotations)) { try self.nextTypeAnnotation(with: constantPool) }

            attr = .runtimeInvisibleTypeAnnotations(annotations: annotations)
        default:
            throw ClassFileError.unsupportedAttributeName(attrName)
        }

        return attr
    }
}

// annotations
extension UnsafeRawPointer {
    mutating func nextAnnotation(with constantPool: [ConstantPoolInfo]) throws -> Annotation {
        let typeIndex = self.next(assumingTo: UInt16.self).bigEndian

        let numElementValuePairs = self.next(assumingTo: UInt16.self).bigEndian
        let elementValuePairs: [AnnotationElementValuePair] = try makeArray(count: Int(numElementValuePairs)) {
            let nameIndex = self.next(assumingTo: UInt16.self).bigEndian
            return (elementNameIndex: nameIndex, value: try self.nextAnnotationElementValue(with: constantPool))
        }
        return Annotation(typeIndex: typeIndex, elementValuePairs: elementValuePairs)
    }

    mutating func nextAnnotationElementValue(with constantPool: [ConstantPoolInfo]) throws -> AnnotationElementValue {
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
            let values = try makeArray(count: Int(numValues)) { try self.nextAnnotationElementValue(with: constantPool) }

            return .arrayValue(values)
        default:
            throw ClassFileError.unsupportedAnnotationelementValueTag(tag)
        }
    }
}


// type annotations
extension UnsafeRawPointer {

    mutating func nextTypeAnnotation(with constantPool: [ConstantPoolInfo]) throws -> TypeAnnotation {
        let targetType = self.next(assumingTo: UInt8.self).bigEndian

        let targetInfo: TypeAnnotation.Target
        switch targetType {
        case 0x00, 0x01:
            let index = self.next(assumingTo: UInt8.self).bigEndian
            targetInfo = .typeParameter(index: index)
        case 0x10:
            let index = self.next(assumingTo: UInt16.self).bigEndian
            targetInfo = .superType(index: index)
        case 0x11, 0x12:
            let typeParameterIndex = self.next(assumingTo: UInt8.self).bigEndian
            let boundIndex = self.next(assumingTo: UInt8.self).bigEndian
            targetInfo = .typeParameterBound(typeParameterIndex: typeParameterIndex, boundIndex: boundIndex)
        case 0x13, 0x14, 0x15:
            targetInfo = .empty
        case 0x16:
            let index = self.next(assumingTo: UInt8.self).bigEndian
            targetInfo = .formalParameter(index: index)
        case 0x17:
            let index = self.next(assumingTo: UInt16.self).bigEndian
            targetInfo = .`throws`(index: index)
        case 0x40, 0x41:
            let length = self.next(assumingTo: UInt16.self).bigEndian

            let table: [TypeAnnotation.Target.LocalVariable] = try makeArray(count: Int(length)) {
                let startPC = self.next(assumingTo: UInt16.self).bigEndian
                let length = self.next(assumingTo: UInt16.self).bigEndian
                let index = self.next(assumingTo: UInt16.self).bigEndian
                return .init(startPC: startPC, length: length, index: index)
            }
            targetInfo = .localvar(table: table)
        case 0x42:
            let index = self.next(assumingTo: UInt16.self).bigEndian
            targetInfo = .`catch`(exceptionTableIndex: index)
        case 0x43, 0x44, 0x45, 0x46:
            let value = self.next(assumingTo: UInt16.self).bigEndian
            targetInfo = .offset(value)
        case 0x47, 0x48, 0x49, 0x4A, 0x4B:
            let offset = self.next(assumingTo: UInt16.self).bigEndian
            let index = self.next(assumingTo: UInt8.self).bigEndian
            targetInfo = .typeArgument(offset: offset, typeArgumentIndex: index)
        default:
            throw ClassFileError.unsupportedTypeAnnotationTarget(targetType)
        }

        let pathLength = self.next(assumingTo: UInt8.self).bigEndian
        let path: [TypeAnnotation.TypePath.Path] = try makeArray(count: Int(pathLength)) {
            let typePathKind = self.next(assumingTo: UInt8.self).bigEndian
            let typeArgumentIndex = self.next(assumingTo: UInt8.self).bigEndian
            return .init(typePathKind: typePathKind, typeArgumentIndex: typeArgumentIndex)
        }

        let typePath = TypeAnnotation.TypePath(path: path)

        let numElementValuePairs = self.next(assumingTo: UInt16.self).bigEndian
        let elementValuePairs: [AnnotationElementValuePair] = try makeArray(count: Int(numElementValuePairs)) {
            let nameIndex = self.next(assumingTo: UInt16.self).bigEndian
            return (elementNameIndex: nameIndex, value: try self.nextAnnotationElementValue(with: constantPool))
        }

        return TypeAnnotation(targetInfo: targetInfo, targetPath: typePath, elementValuePairs: elementValuePairs)
    }
}
