import ClassCodable

@ClassCodable
class Person {
    @CustomCodableKey("birth_id")
    var id: String
    var firstName: String
    var lastName: String
    var title: String = "Mr."
    var middleName: String?
}

@ClassEncodable
class Book {
    @CustomCodableKey("birth_id")
    var id: String
    var title: String
}

@ClassDecodable
class Genre {
    var id: String
    var name: String
}
