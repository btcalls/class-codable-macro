import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

private struct Property {
    private var binding: PatternBindingSyntax?
    private var attributes: AttributeListSyntax?
    private var initializer: InitializerClauseSyntax?
    
    var id: TokenSyntax
    var type: TypeSyntax
    
    private var isOptional: Bool {
        return type.is(OptionalTypeSyntax.self)
    }
    
    func asParam() -> String {
        if let value = initializer?.value {
            return "\(id): \(type.trimmed) = \(value)"
        } else if isOptional {
            return "\(id): \(type.trimmed) = nil"
        } else {
            return "\(id): \(type)"
        }
    }
    
    func asPropertyInit() -> String {
        return "self.\(id) = \(id)"
    }
    
    func asCase(custom: ExprSyntax? = nil) -> String {
        if let custom {
            return "case \(id.text) = \(custom)"
        } else {
            return "case \(id.text)"
        }
    }
    
    func asEncodable() -> String {
        if isOptional {
            return "try container.encodeIfPresent(\(id), forKey: .\(id))"
        } else {
            return "try container.encode(\(id), forKey: .\(id))"
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
        self.initializer = self.binding?.initializer
        
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
    
    static func encodableSyntax(from members: MemberBlockItemListSyntax) -> DeclSyntax {
        let propertyMap: [Property] = members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .compactMap { .init(from: $0) }
        
        // Create expected macro structure
        let encodables = propertyMap.map { $0.asEncodable() }
        
        return
            """
            func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: \(raw: Self.codableKeyName).self)
                \(raw: encodables.joined(separator: "\n"))
            }
            """
    }
}

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
            encodableSyntax(from: members),
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
        return [try ExtensionDeclSyntax("extension \(type): Encodable {}")]
    }
}
