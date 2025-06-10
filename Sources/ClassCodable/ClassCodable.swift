/// A macro that produces the boilerplate code for implementing a `Codable` class instance.
///
/// Generates the initialiser, its `CodingKeys` enum, and its encoding and decoding methods.
@attached(member, names: named(init), named(CodingKeys), named(encode(to:)))
@attached(extension, conformances: Encodable) // TODO: Change to Codable
public macro ClassCodable() = #externalMacro(module: "ClassCodableMacros", type: "ClassCodableMacro")

/// A macro that produces the boilerplate code for implementing a `Codable` class instance.
///
/// Generates the initialiser, its `CodingKeys` enum, and its encoding method.
@attached(member, names: named(init), named(CodingKeys), named(encode(to:)))
@attached(extension, conformances: Encodable)
public macro ClassEncodable() = #externalMacro(module: "ClassCodableMacros", type: "ClassEncodableMacro")

/// A macro to enable custom coding keys when usen in conjunction with the `@ClassCodable` macro.
@attached(peer)
public macro CustomCodableKey(_ key: String) = #externalMacro(module: "ClassCodableMacros", type: "CustomCodableKeyMacro")
