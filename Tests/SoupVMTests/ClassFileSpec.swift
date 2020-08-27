import Foundation

import Quick
import Nimble

@testable import SoupVM

class ClassFileSpec: QuickSpec {
    override func spec() {
        describe("initialization") {
            describe("magic number") {
                context("invalid") {
                    let path = "Tests/SoupVMTests/Resources/InvalidMagicNumber.class"

                    it("instantiation failed") {
                        do {
                            _ = try ClassFile(forReadingAtPath: path)
                            fail("invalid magic number passed")
                        } catch {
                            // pass
                        }
                    }
                }

                context("valid") {
                    let path = "Tests/SoupVMTests/Resources/ValidMagicNumber.class"
                    it("instantiation success") {
                        do {
                            _ = try ClassFile(forReadingAtPath: path)
                        } catch let error {
                            fail("\(error)")
                            return
                        }
                    }
                }
            }

            describe("version") {
                let path = "Tests/SoupVMTests/Resources/ValidVersion.class"
                it("returns valid version") {
                    let file = try! ClassFile(forReadingAtPath: path)
                    expect(file.version) == "52.0"
                }
            }

            describe("constantPoolCount") {
                let path = "Tests/SoupVMTests/Resources/ConstantPoolCount.class"
                it("returns valid constant pool count") {
                    let file = try! ClassFile(forReadingAtPath: path)
                    expect(file.constantPoolCount) == 29
                }
            }

            describe("constantPool") {
                let path = "Tests/SoupVMTests/Resources/ConstantPool.class"
                it("parses valid constant pool entries") {
                    let file = try! ClassFile(forReadingAtPath: path)

                    expect(file.constantPool[0]) == .some(.methodRef(classIndex: 6, nameAndTypeIndex: 15))
                    expect(file.constantPool[1]) == .some(.fieldRef(classIndex: 16, nameAndTypeIndex: 17))
                    expect(file.constantPool[2]) == .some(.string(stringIndex: 18))
                    expect(file.constantPool[3]) == .some(.methodRef(classIndex: 19, nameAndTypeIndex: 20))
                    expect(file.constantPool[4]) == .some(.`class`(nameIndex: 21))
                    expect(file.constantPool[5]) == .some(.`class`(nameIndex: 22))
                    expect(file.constantPool[6]) == .some(.utf8(string: "<init>"))
                    expect(file.constantPool[7]) == .some(.utf8(string: "()V"))
                    expect(file.constantPool[8]) == .some(.utf8(string: "Code"))
                    expect(file.constantPool[9]) == .some(.utf8(string: "LineNumberTable"))
                    expect(file.constantPool[10]) == .some(.utf8(string: "main"))
                    expect(file.constantPool[11]) == .some(.utf8(string: "([Ljava/lang/String;)V"))
                    expect(file.constantPool[12]) == .some(.utf8(string: "SourceFile"))
                    expect(file.constantPool[13]) == .some(.utf8(string: "Main.java"))
                    expect(file.constantPool[14]) == .some(.nameAndType(nameIndex: 7, descriptorIndex: 8))
                    expect(file.constantPool[15]) == .some(.`class`(nameIndex: 23))
                    expect(file.constantPool[16]) == .some(.nameAndType(nameIndex: 24, descriptorIndex: 25))
                    expect(file.constantPool[17]) == .some(.utf8(string: "hello"))
                    expect(file.constantPool[18]) == .some(.`class`(nameIndex: 26))
                    expect(file.constantPool[19]) == .some(.nameAndType(nameIndex: 27, descriptorIndex: 28))
                    expect(file.constantPool[20]) == .some(.utf8(string: "Main"))
                    expect(file.constantPool[21]) == .some(.utf8(string: "java/lang/Object"))
                    expect(file.constantPool[22]) == .some(.utf8(string: "java/lang/System"))
                    expect(file.constantPool[23]) == .some(.utf8(string: "out"))
                    expect(file.constantPool[24]) == .some(.utf8(string: "Ljava/io/PrintStream;"))
                    expect(file.constantPool[25]) == .some(.utf8(string: "java/io/PrintStream"))
                    expect(file.constantPool[26]) == .some(.utf8(string: "println"))
                    expect(file.constantPool[27]) == .some(.utf8(string: "(Ljava/lang/String;)V"))
                }
            }
        }
    }
}

extension ConstantPoolInfo: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.`class`(a), .`class`(b)):
            return a == b
        case let (.`fieldRef`(la, lb), .`fieldRef`(ra, rb)):
            return la == ra && lb == rb
        case let (.`methodRef`(la, lb), .`methodRef`(ra, rb)):
            return la == ra && lb == rb
        case let (.`interfaceMethodRef`(la, lb), .`interfaceMethodRef`(ra, rb)):
            return la == ra && lb == rb
        case let (.string(a), .string(b)):
            return a == b
        case let (.integer(a), .integer(b)):
            return a == b
        case let (.float(a), .float(b)):
            return a == b
        case let (.long(la, lb), .long(ra, rb)):
            return la == ra && lb == rb
        case let (.double(la, lb), .double(ra, rb)):
            return la == ra && lb == rb
        case let (.nameAndType(la, lb), .nameAndType(ra, rb)):
            return la == ra && lb == rb
        case let (.utf8(a), .utf8(b)):
            return a == b
        case let (.methodHandle(la, lb), .methodHandle(ra, rb)):
            return la == ra && lb == rb
        case let (.methodType(a), .methodType(b)):
            return a == b
        case let (.invokeDynamic(la, lb), .invokeDynamic(ra, rb)):
            return la == ra && lb == rb
        default:
            return false
        }
    }
}
