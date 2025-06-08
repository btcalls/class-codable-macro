public enum ClassCodableError: CustomStringConvertible, Error {
    case onlyApplicableToClass
    
    public var description: String {
        switch self {
        case .onlyApplicableToClass: return "@ClassCodable can only be applied to classes."
        }
    }
}
