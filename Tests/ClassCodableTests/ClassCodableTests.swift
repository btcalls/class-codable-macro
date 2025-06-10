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
    "ClassEncodable": ClassEncodableMacro.self,
    "ClassDecodable": ClassDecodableMacro.self,
]
#endif

final class ClassCodableTests: XCTestCase {
    func testClassEncodableWithConformance() {
        assertMacroExpansion(
        """
        @ClassEncodable
        class Test {
            var test1: String = "Test1"
            @CustomCodableKey("test_2")
            var test2: Int
            var test3: String?
        }
        """,
        expandedSource: """
        class Test {
            var test1: String = "Test1"
            @CustomCodableKey("test_2")
            var test2: Int
            var test3: String?
        
            private enum CodingKeys: String, CodingKey {
                case test1
                case test2 = "test_2"
                case test3
            }
        
            init(test1: String = "Test1", test2: Int, test3: String? = nil) {
                self.test1 = test1
                self.test2 = test2
                self.test3 = test3
            }
        
            func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(test1, forKey: .test1)
                try container.encode(test2, forKey: .test2)
                try container.encodeIfPresent(test3, forKey: .test3)
            }
        }
        
        extension Test: Encodable {
        }
        """,
        macros: testMacros
        )
    }
    
    func testClassDecodableWithConformance() {
        assertMacroExpansion(
        """
        @ClassDecodable
        class Test {
            var test1: String = "Test1"
            @CustomCodableKey("test_2")
            var test2: Int
            var test3: String?
        }
        """,
        expandedSource: """
        class Test {
            var test1: String = "Test1"
            @CustomCodableKey("test_2")
            var test2: Int
            var test3: String?
        
            private enum CodingKeys: String, CodingKey {
                case test1
                case test2 = "test_2"
                case test3
            }
        
            init(test1: String = "Test1", test2: Int, test3: String? = nil) {
                self.test1 = test1
                self.test2 = test2
                self.test3 = test3
            }
        
            required init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                test1 = try container.decode(String.self, forKey: .test1)
                test2 = try container.decode(Int.self, forKey: .test2)
                test3 = try container.decodeIfPresent(String.self, forKey: .test3)
            }
        }
        
        extension Test: Decodable {
        }
        """,
        macros: testMacros
        )
    }
    
    func testClassCodableWithConformance() {
        assertMacroExpansion(
        """
        @ClassCodable
        class Test {
            var test1: String = "Test1"
            @CustomCodableKey("test_2")
            var test2: Int
            var test3: String?
        }
        """,
        expandedSource: """
        class Test {
            var test1: String = "Test1"
            @CustomCodableKey("test_2")
            var test2: Int
            var test3: String?
        
            private enum CodingKeys: String, CodingKey {
                case test1
                case test2 = "test_2"
                case test3
            }
        
            init(test1: String = "Test1", test2: Int, test3: String? = nil) {
                self.test1 = test1
                self.test2 = test2
                self.test3 = test3
            }
        
            required init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                test1 = try container.decode(String.self, forKey: .test1)
                test2 = try container.decode(Int.self, forKey: .test2)
                test3 = try container.decodeIfPresent(String.self, forKey: .test3)
            }
        
            func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(test1, forKey: .test1)
                try container.encode(test2, forKey: .test2)
                try container.encodeIfPresent(test3, forKey: .test3)
            }
        }
        
        extension Test: Codable {
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
        
        extension Test: Codable {
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
