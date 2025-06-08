import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

private extension ClassCodableMacro {
    struct Property {
        var id: TokenSyntax
        var type: TypeSyntax
        
        func asParams() -> String {
            return "\(id): \(type)"
        }
        
        func asProperties() -> String {
            return "self.\(id) = \(id)"
        }
    }
}

private extension ClassCodableMacro {
    static func initSyntax(from members: MemberBlockItemListSyntax) -> DeclSyntax {
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
    
    static func casesSyntax(from members: MemberBlockItemListSyntax) -> DeclSyntax {
        let cases = members.compactMap { member -> String? in
            // Check if is a property
            guard
                let propertyName = member
                    .decl.as(VariableDeclSyntax.self)?
                    .bindings.first?
                    .pattern.as(IdentifierPatternSyntax.self)?
                    .identifier.text
            else {
                return nil
            }
            
            // Check for a CodableKey macro on it
            if let customKeyMacro = member.decl.as(VariableDeclSyntax.self)?.attributes.first(
                where: {
                    $0.as(AttributeSyntax.self)?
                        .attributeName.as(IdentifierTypeSyntax.self)?
                        .description == CustomCodableKeyMacro.attributeName
                }
            ) {
                // Uses the value in the Macro
                let customKeyValue = customKeyMacro.as(AttributeSyntax.self)!
                    .arguments!.as(LabeledExprListSyntax.self)!
                    .first!
                    .expression
                
                return "case \(propertyName) = \(customKeyValue)"
            } else {
                return "case \(propertyName)"
            }
        }
        
        return
            """
            private enum CodingKeys: String, CodingKey {
            \(raw: cases.joined(separator: "\n"))
            }
            """
    }
}

public struct ClassCodableMacro: MemberMacro {
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
            initSyntax(from: members),
            casesSyntax(from: members)
        ]
    }
}
