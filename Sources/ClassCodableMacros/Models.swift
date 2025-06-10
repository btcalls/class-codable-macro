//
//  Models.swift
//  ClassCodable
//
//  Created by Jason Jon Carreos on 10/6/2025.
//

import SwiftSyntax

struct Property {
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

extension Property {
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
