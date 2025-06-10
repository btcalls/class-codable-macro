import SwiftSyntaxMacros
import SwiftCompilerPlugin

@main
struct CodablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ClassCodableMacro.self,
        ClassEncodableMacro.self,
        ClassDecodableMacro.self,
        CustomCodableKeyMacro.self,
    ]
}
