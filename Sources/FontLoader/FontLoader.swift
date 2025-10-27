import SwiftUI
import CoreText

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A thread-safe runtime font registrar for iOS and macOS.
/// Loads fonts from the app bundle or Swift Package resources
/// and registers them with CoreText so they become immediately
/// available to SwiftUI, UIKit, and AppKit.
public final class FontLoader: @unchecked Sendable {

    /// Shared global instance
    public static let shared = FontLoader()

    /// Thread-safe registered font list (guarded by queue)
    private var registered: Set<String> = []

    /// Concurrent queue to allow thread-safe reads and barrier writes
    private let queue = DispatchQueue(label: "FontLoader.Queue", attributes: .concurrent)

    private init() {}

    // MARK: - Public API (Synchronous)

    /// Registers a font by filename (without extension) or by PostScript name
    /// already known by the system.
    ///
    /// The loader searches in this order:
    /// 1. Provided bundle (default: `.main`)
    /// 2. Swift Package resources (`Bundle.module`) if available
    /// 3. System-available fonts (e.g. installed on device)
    ///
    /// - Parameters:
    ///   - name: Filename without extension OR PostScript name
    ///   - bundle: Bundle to search first (default: main app bundle)
    ///   - ext: Font extension ("ttf" by default)
    /// - Returns: The font PostScript name if successfully registered
    @discardableResult
    public func register(_ name: String,
                         from bundle: Bundle = .main,
                         ext: String = "ttf") throws -> String {

        // Already registered in this runtime session
        if isRegistered(name) { return name }

        // 1️⃣ Check provided bundle for file
        if let url = bundle.url(forResource: name, withExtension: ext) {
            return try register(from: url)
        }

        // 2️⃣ Check Swift Package resources if available
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: name, withExtension: ext) {
            return try register(from: url)
        }
        #endif

        // 3️⃣ Check system availability (already installed)
        if fontAvailable(named: name) {
            markRegistered(name)
            return name
        }

        throw FontError.notFound(name)
    }

    /// Registers a font from a `.ttf` or `.otf` file URL.
    ///
    /// - Parameter url: URL of the font file
    /// - Returns: PostScript name extracted from the font
    @discardableResult
    public func register(from url: URL) throws -> String {
        guard let provider = CGDataProvider(url: url as CFURL),
              let cgFont = CGFont(provider),
              let postScriptName = cgFont.postScriptName as String? else {
            throw FontError.invalid(url.lastPathComponent)
        }

        // Avoid double registration
        if isRegistered(postScriptName) { return postScriptName }

        // Register with CoreText
        let ok = CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        guard ok else { throw FontError.failed(url.lastPathComponent) }

        markRegistered(postScriptName)
        return postScriptName
    }

    /// Returns whether the given font PostScript name is already registered.
    public func isRegistered(_ postScriptName: String) -> Bool {
        var result = false
        queue.sync { result = registered.contains(postScriptName) }
        return result
    }

    // MARK: - Thread Safety

    /// Inserts the PostScript name into the registered set with write barrier
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
            case .notFound(let f): "Font '\(f)' not found in bundle or package resources."
            case .failed(let f): "Failed to register font '\(f)'."
            case .invalid(let f): "Invalid or corrupted font file '\(f)'."
            }
        }
    }
}

// MARK: - System Availability Check

/// Returns true if the font is already available in the OS
private func fontAvailable(named name: String) -> Bool {
    #if canImport(UIKit)
    return UIFont(name: name, size: 12) != nil
    #elseif canImport(AppKit)
    return NSFont(name: name, size: 12) != nil
    #else
    return false
    #endif
}

// MARK: - SwiftUI Convenience API

public extension Font {
    /// Registers the font if needed and returns a SwiftUI `Font`.
    /// Returns nil if the font could not be registered.
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
// MARK: - UIKit Convenience API

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
// MARK: - AppKit Convenience API

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


#Preview {
    Text("001surah")
        .font(.loaded("sura_names", size: 25))
        .padding()

    Text("007surah")
        .font(.loaded("sura_names", size: 25))
        .padding()
}
