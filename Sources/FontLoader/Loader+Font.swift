import SwiftUI

public extension Font {
    static func loaded(_ name: String, size: CGFloat, in bundle: Bundle = .main) -> Font? {
        do {
            let ps = try FontLoader.shared.register(name, in: bundle)
            return .custom(ps, size: size)
        } catch {
            #if DEBUG
            print("[FontLoader]", error.localizedDescription)
            #endif
            return nil
        }
    }
}
