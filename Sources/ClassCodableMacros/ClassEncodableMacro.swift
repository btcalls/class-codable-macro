//
//  ClassEncodableMacro.swift
//  ClassCodable
//
//  Created by Jason Jon Carreos on 10/6/2025.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// MARK: Main

public struct ClassEncodableMacro: MemberMacro {
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
            encodableSyntax(from: members),
        ]
    }
}

extension ClassEncodableMacro: ExtensionMacro {
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

// MARK: Utilities

extension ClassEncodableMacro {
    static func encodableSyntax(from members: MemberBlockItemListSyntax) -> DeclSyntax {
        let propertyMap: [Property] = members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .compactMap { .init(from: $0) }
        
        // Create expected macro structure
        let encodables = propertyMap.map { $0.asEncodable() }
        
        return
            """
            func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: \(raw: ClassCodableMacro.codableKeyName).self)
                \(raw: encodables.joined(separator: "\n"))
            }
            """
    }
}
