import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// MARK: Main

public struct ClassCodableMacro: MemberMacro {
    static let codableKeyName = "CodingKeys"
    
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
            casesSyntax(from: members),
            initSyntax(from: members),
            ClassDecodableMacro.decodableSyntax(from: members),
            ClassEncodableMacro.encodableSyntax(from: members),
        ]
    }
}

extension ClassCodableMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        return [try ExtensionDeclSyntax("extension \(type): Codable {}")]
    }
}

// MARK: Utilities

extension ClassCodableMacro {
    static func initSyntax(from members: MemberBlockItemListSyntax) -> DeclSyntax {
        let propertyMap: [Property] = members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .compactMap { .init(from: $0) }
        
        // Create expected macro structure
        let params = propertyMap.map { $0.asParam() }
        let properties = propertyMap.map { $0.asPropertyInit() }
        
        return
            """
            init(\(raw: params.joined(separator: ", "))) {
                \(raw: properties.joined(separator: "\n"))
            }
            """
    }
    
    static func casesSyntax(from members: MemberBlockItemListSyntax) -> DeclSyntax {
        let cases = members.compactMap { member -> String? in
            // Check if is a property
            guard
                let variable = member.decl.as(VariableDeclSyntax.self),
                let property = Property(from: variable)
            else {
                return nil
            }
            
            // Check for a `CustomCodableKey` macro on it
            if let customKeyMacro = property.get(attribute: CustomCodableKeyMacro.attributeName) {
                // Uses the value in the macro
                let customKeyValue = customKeyMacro.as(AttributeSyntax.self)!
                    .arguments!.as(LabeledExprListSyntax.self)!
                    .first!
                    .expression
                
                return property.asCase(custom: customKeyValue)
            } else {
                return property.asCase()
            }
        }
        
        // Create expected macro structure
        return
            """
            private enum \(raw: Self.codableKeyName): String, CodingKey {
                \(raw: cases.joined(separator: "\n"))
            }
            """
    }
}
