import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

private struct Property {
    private var binding: PatternBindingSyntax?
    private var attributes: AttributeListSyntax?
    
    var id: TokenSyntax
    var type: TypeSyntax
    
    var name: String {
        return id.text
    }
    
    func asParam() -> String {
        return "\(id): \(type)"
    }
    
    func asProperty() -> String {
        return "self.\(id) = \(id)"
    }
    
    func asCase(custom: ExprSyntax? = nil) -> String {
        if let custom {
            return "case \(name) = \(custom)"
        } else {
            return "case \(name)"
        }
    }
    
    func get(attribute description: String) -> AttributeListSyntax.Element? {
        return attributes?.first(
            where: {
                $0.as(AttributeSyntax.self)?
                    .attributeName.as(IdentifierTypeSyntax.self)?
                    .description == description
            }
        )
    }
}

private extension Property {
    init?(from variable: VariableDeclSyntax) {
        self.binding = variable.bindings.first
        self.attributes = variable.attributes
        
        guard
            let pattern = self.binding?.pattern.as(IdentifierPatternSyntax.self),
            let typeAnnotation = self.binding?.typeAnnotation
        else {
            return nil
        }
        
        self.id = pattern.identifier
        self.type = typeAnnotation.type
    }
}

private extension ClassCodableMacro {
    static func initSyntax(from members: MemberBlockItemListSyntax) -> DeclSyntax {
        let propertyMap: [Property] = members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .compactMap { .init(from: $0) }
        
        // Create expected macro structure
        let params = propertyMap.map { $0.asParam() }
        let properties = propertyMap.map { $0.asProperty() }
        
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
