import SwiftUI
import CoreText

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public final class FontLoader: @unchecked Sendable {

    public static let shared = FontLoader()

    private var registered: Set<String> = []
    private let queue = DispatchQueue(label: "FontLoader.Queue", attributes: .concurrent)

    private init() {}

    // MARK: - Public API (synchrone)

    /// Enregistre une police par nom de fichier (sans extension) OU par PostScript name déjà présent.
    /// - Parameters:
    ///   - name: Nom de fichier (sans extension) OU PostScript name
    ///   - bundle: Bundle à sonder en priorité (.main par défaut)
    ///   - ext: "ttf" (défaut) ou "otf"
    /// - Returns: PostScript name de la police prête à l'emploi
    @discardableResult
    public func register(_ name: String,
                         from bundle: Bundle = .main,
                         ext: String = "ttf") throws -> String {

        if isRegistered(name) { return name }

        // 1) Fichier dans le bundle fourni
        if let url = bundle.url(forResource: name, withExtension: ext) {
            return try register(from: url)
        }

        // 2) Fichier dans les ressources SPM du package (si utilisées)
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: name, withExtension: ext) {
            return try register(from: url)
        }
        #endif

        // 3) Déjà installée au système ?
        if fontAvailable(named: name) {
            markRegistered(name)
            return name
        }

        throw FontError.notFound(name)
    }

    /// Enregistre une police depuis une URL .ttf/.otf
    /// - Returns: PostScript name
    @discardableResult
    public func register(from url: URL) throws -> String {
        guard let provider = CGDataProvider(url: url as CFURL),
              let cgFont = CGFont(provider),
              let postScriptName = cgFont.postScriptName as String? else {
            throw FontError.invalid(url.lastPathComponent)
        }

        if isRegistered(postScriptName) { return postScriptName }

        let ok = CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        guard ok else { throw FontError.failed(url.lastPathComponent) }

        markRegistered(postScriptName)
        return postScriptName
    }

    /// Vérifie si une police (par PostScript name) est marquée enregistrée.
    public func isRegistered(_ postScriptName: String) -> Bool {
        var result = false
        queue.sync { result = registered.contains(postScriptName) }
        return result
    }

    // MARK: - Internals thread-safety

    private func markRegistered(_ postScriptName: String) {
        queue.async(flags: .barrier) {
            self.registered.insert(postScriptName)
        }
    }

    // MARK: - Errors

    public enum FontError: LocalizedError {
        case notFound(String)
        case failed(String)
        case invalid(String)

        public var errorDescription: String? {
            switch self {
            case .notFound(let f): "Font '\(f)' not found."
            case .failed(let f): "Failed to register font '\(f)'."
            case .invalid(let f): "Invalid font file '\(f)'."
            }
        }
    }
}

// MARK: - Availability helper

private func fontAvailable(named name: String) -> Bool {
    #if canImport(UIKit)
    return UIFont(name: name, size: 12) != nil
    #elseif canImport(AppKit)
    return NSFont(name: name, size: 12) != nil
    #else
    return false
    #endif
}

// MARK: - SwiftUI convenience (synchrone)

public extension Font {
    /// Tente d'enregistrer puis retourne un `Font` SwiftUI (ou nil si échec).
    static func loaded(_ name: String,
                       size: CGFloat,
                       loader: FontLoader = .shared) -> Font? {
        do {
            let ps = try loader.register(name)
            return .custom(ps, size: size)
        } catch {
            #if DEBUG
            print("[FontLoader] ⚠️", error.localizedDescription)
            #endif
            return nil
        }
    }
}

#if canImport(UIKit)
// MARK: - UIKit convenience

public extension UIFont {
    static func loaded(_ name: String,
                       size: CGFloat,
                       loader: FontLoader = .shared) -> UIFont? {
        do {
            let ps = try loader.register(name)
            return UIFont(name: ps, size: size)
        } catch { return nil }
    }
}
#elseif canImport(AppKit)
// MARK: - AppKit convenience

public extension NSFont {
    static func loaded(_ name: String,
                       size: CGFloat,
                       loader: FontLoader = .shared) -> NSFont? {
        do {
            let ps = try loader.register(name)
            return NSFont(name: ps, size: size)
        } catch { return nil }
    }
}
#endif



#Preview("Test") {
    Text("001surah")
        .font(.loaded("sura_names", size: 25))
        .padding()
    Text("007surah")
        .font(.loaded("sura_names", size: 25))
        .padding()
}
