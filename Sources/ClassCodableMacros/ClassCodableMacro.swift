import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ClassCodableMacro: MemberMacro {
    private struct Property {
        var id: TokenSyntax
        var type: TypeSyntax
        
        func asParams() -> String {
            return "\(id): \(type)"
        }
        
        func asProperties() -> String {
            return "self.\(id) = \(id)"
        }
    }
    
    private static func initSyntax(from members: MemberBlockItemListSyntax) -> DeclSyntax {
        let propertyDecls = members.compactMap { $0.decl.as(VariableDeclSyntax.self) }
        let bindings = propertyDecls.compactMap { $0.bindings.first }
        let propertyMap: [Property] = bindings.compactMap {
            if let pattern = $0.pattern.as(IdentifierPatternSyntax.self),
               let typeAnnotation = $0.typeAnnotation {
                return .init(
                    id: pattern.identifier,
                    type: typeAnnotation.type
                )
            } else {
                return nil
            }
        }
        
        // Create expected macro structure
        let params = propertyMap
            .map { $0.asParams() }
            .joined(separator: ", ")
        let properties = propertyMap
            .map { $0.asProperties() }
            .joined(separator: "\n")
        
        return
            """
            init(\(raw: params)) {
                \(raw: properties)
            }
            """
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let functionDecl = declaration.as(ClassDeclSyntax.self) else {
            throw ClassCodableError.onlyApplicableToClass
        }
        
        let members = functionDecl.memberBlock.members
        
        return [
            initSyntax(from: members)
        ]
    }
}
