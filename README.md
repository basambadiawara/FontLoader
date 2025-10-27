# FontLoader

FontLoader is a lightweight, synchronous, and thread-safe Swift utility for dynamically registering custom fonts on both iOS and macOS at runtime.  
It supports SwiftUI, UIKit, and AppKit out of the box.

---

## ✨ Features

✅ iOS 13+ and macOS 11+ support  
✅ Fully synchronous API — **no async/await needed**  
✅ SwiftUI / UIKit / AppKit helpers included  
✅ Supports fonts stored in:
- Your **app bundle** (`.main`)
- **Swift Package resources** (`Bundle.module`)
✅ Thread-safety managed via concurrent DispatchQueue
