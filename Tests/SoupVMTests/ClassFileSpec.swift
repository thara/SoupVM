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
                            _ = try ClassFile(path: path)
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
                            _ = try ClassFile(path: path)
                        } catch {
                            fail("invalid magic number passed")
                        }
                    }
                }
            }
        }
    }
}
