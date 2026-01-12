#if canImport(UIKit)
import UIKit

public extension UIFont {
    static func loaded(
        _ name: String,
        size: CGFloat,
        in bundle: Bundle = .main
    ) -> UIFont? {
        do {
            let ps = try FontLoader.shared.register(name, in: bundle)
            return UIFont(name: ps, size: size)
        } catch {
            #if DEBUG
            print("[FontLoader]", error.localizedDescription)
            #endif
            return nil
        }
    }
}

#elseif canImport(AppKit)
import AppKit

public extension NSFont {
    static func loaded(
        _ name: String,
        size: CGFloat,
        loader: FontLoader = .shared
    ) -> NSFont? {
        do {
            let ps = try loader.register(name)
            return NSFont(name: ps, size: size)
        } catch {
            return nil
        }
    }
}
#endif
