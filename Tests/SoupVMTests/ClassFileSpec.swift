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
        }
    }
}
