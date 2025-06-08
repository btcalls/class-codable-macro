import ClassCodable

@ClassCodable
class Person {
    var id: String
    @CustomCodableKey("test")
    var name: String
}
