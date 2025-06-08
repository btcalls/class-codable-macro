/// A macro that produces the boilerplate code for implementing a `Codable` class instance.
///
/// Generates the initialiser and its `CodingKeys` enum.
@attached(member, names: named(init), named(CodingKeys))
public macro ClassCodable() = #externalMacro(module: "ClassCodableMacros", type: "ClassCodableMacro")
