import SwiftUI
import CoreText


/// Thread-safe runtime font registrar supporting
/// App bundle + Swift Package resources
public final class FontLoader: @unchecked Sendable {

    public static let shared = FontLoader()

    private var registered: Set<String> = []
    private let queue = DispatchQueue(label: "FontLoader.Queue", attributes: .concurrent)

    private init() {}

    // MARK: - Public API

    @discardableResult
    public func register(_ name: String, in bundle: Bundle? = .main, extension ext: String = "ttf") throws -> String {

        if isRegistered(name) { return name }

        

        // System font already installed
        if fontAvailable(named: name) {
            markRegistered(name)
            return name
        }
        
        if let bundle,
           let url = bundle.url(forResource: name, withExtension: ext) {
            return try register(from: url)
        }
        
        throw Errors.notFound(name)
    }

    @discardableResult
    public func register(from url: URL) throws -> String {
        guard let provider = CGDataProvider(url: url as CFURL),
              let cgFont = CGFont(provider),
              let postScriptName = cgFont.postScriptName as String? else {
            throw Errors.invalid(url.lastPathComponent)
        }

        if isRegistered(postScriptName) { return postScriptName }

        let ok = CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        guard ok else { throw Errors.failed(url.lastPathComponent) }

        markRegistered(postScriptName)
        return postScriptName
    }

    public func isRegistered(_ postScriptName: String) -> Bool {
        var result = false
        queue.sync { result = registered.contains(postScriptName) }
        return result
    }

    private func markRegistered(_ name: String) {
        queue.async(flags: .barrier) {
            self.registered.insert(name)
        }
    }
}

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

private func fontAvailable(named name: String) -> Bool {
    #if canImport(UIKit)
    return UIFont(name: name, size: 12) != nil
    #elseif canImport(AppKit)
    return NSFont(name: name, size: 12) != nil
    #else
    return false
    #endif
}
