import Foundation

import Quick
import Nimble

@testable import SoupVM

class ClassFileSpec: QuickSpec {
    override func spec() {
        describe("initialization") {
            describe("magic number") {
                context("invalid") {
                    do {
                        _ = try ClassFile(bytes: [0xCA, 0xFE, 0xBA, 0xBB])
                        fail("invalid magic number passed")
                    } catch {
                        // pass
                    }
                }

                context("valid") {
                    do {
                        _ = try ClassFile(bytes: [0xCA, 0xFE, 0xBA, 0xBE])
                    } catch {
                        fail("invalid magic number passed")
                    }
                }
            }
        }
    }
}
