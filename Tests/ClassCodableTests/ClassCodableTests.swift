import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(ClassCodableMacros)
import ClassCodableMacros

let testMacros: [String: Macro.Type] = [
    "ClassCodable": ClassCodableMacro.self,
]
#endif

final class ClassCodableTests: XCTestCase {
    func testClassCodableWithCodingKeys() {
        assertMacroExpansion(
        """
        @ClassCodable
        class Test {
            var test1: String
            var test2: Int
        }
        """,
        expandedSource: """
        class Test {
            var test1: String
            var test2: Int
        
            init(test1: String, test2: Int) {
                self.test1 = test1
                self.test2 = test2
            }
        
            private enum CodingKeys: String, CodingKey {
                case test1
                case test2
            }
        }
        """,
        macros: testMacros
        )
    }
    
    func testClassCodableWithCustomKey() {
        assertMacroExpansion(
        """
        @ClassCodable
        class Test {
            var test1: String
            @CustomCodableKey("name")
            var test2: Int
        }
        """,
        expandedSource: """
        class Test {
            var test1: String
            @CustomCodableKey("name")
            var test2: Int
        
            init(test1: String, test2: Int) {
                self.test1 = test1
                self.test2 = test2
            }
        
            private enum CodingKeys: String, CodingKey {
                case test1
                case test2 = "name"
            }
        }
        """,
        macros: testMacros
        )
    }
    
    // MARK: With Diagnostics
    
    func testClassCodableOnStruct() {
        assertMacroExpansion(
        """
        @ClassCodable
        struct Test {
        }
        """,
        expandedSource: """
        struct Test {
        }
        """,
        diagnostics: [
            DiagnosticSpec(
                message: ClassCodableError.onlyApplicableToClass.description,
                line: 1,
                column: 1
            )
        ],
        macros: testMacros
        )
    }
}
