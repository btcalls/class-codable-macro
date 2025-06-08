import SwiftSyntaxMacros
import SwiftCompilerPlugin

@main
struct CodablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ClassCodableMacro.self,
        CustomCodableKeyMacro.self,
    ]
}
