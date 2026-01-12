import  Foundation

public enum Errors: LocalizedError {
    case notFound(String)
    case failed(String)
    case invalid(String)

    public var errorDescription: String? {
        switch self {
        case .notFound(let f): "Font '\(f)' not found in App bundle or Package resources."
        case .failed(let f): "Failed to register font '\(f)'."
        case .invalid(let f): "Invalid font file '\(f)'."
        }
    }
}
