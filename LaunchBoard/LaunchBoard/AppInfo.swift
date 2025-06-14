import SwiftUI
import UniformTypeIdentifiers

struct AppInfo: Identifiable, Hashable, @unchecked Sendable {
    let id = UUID()
    let url: URL
    let name: String
    let icon: NSImage
    var isFolder: Bool = false
    var folderApps: [AppInfo] = []
    var position: CGPoint = .zero

    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        lhs.url == rhs.url
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
    static func createFolder(named: String, containing apps: [AppInfo]) -> AppInfo {
        let folderIcon = NSImage(systemSymbolName: "folder", accessibilityDescription: "Folder") ?? NSImage()
        return AppInfo(
            url: URL(fileURLWithPath: "/folder/\(named)"),
            name: named,
            icon: folderIcon,
            isFolder: true,
            folderApps: apps
        )
    }
}
