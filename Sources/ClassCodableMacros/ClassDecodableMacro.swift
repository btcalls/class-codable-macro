import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// MARK: Main

public struct ClassDecodableMacro: MemberMacro {
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
            ClassCodableMacro.casesSyntax(from: members),
            ClassCodableMacro.initSyntax(from: members),
            decodableSyntax(from: members)
        ]
    }
}

extension ClassDecodableMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        return [try ExtensionDeclSyntax("extension \(type): Decodable {}")]
    }
}

// MARK: Utilities

extension ClassDecodableMacro {
    static func decodableSyntax(from members: MemberBlockItemListSyntax) -> DeclSyntax {
        let propertyMap: [Property] = members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .compactMap { .init(from: $0) }
        
        // Create expected macro structure
        let decodables = propertyMap.map { $0.asDecodable() }
        
        return
            """
            required init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: \(raw: ClassCodableMacro.codableKeyName).self)
                \(raw: decodables.joined(separator: "\n"))
            }
            """
    }
}
