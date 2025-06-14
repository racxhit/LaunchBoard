import SwiftUI
import Combine

@MainActor
class AppListViewModel: ObservableObject {
    
    private var allApps: [AppInfo] = []
    
    @Published var appPages: [[AppInfo]] = []
    @Published var selectedFolderApps: [AppInfo] = []
    @Published var showingFolderView = false
    @Published var currentFolderName = ""
    
    private let pageSize = 35

    func fetchInstalledApps() {
        print("🔍 Starting app search...")
        
        Task(priority: .userInitiated) {
            let appURLs = findAppURLs()
            var discoveredApps: [AppInfo] = []
            for url in appURLs {
                guard let name = appName(from: url), let icon = appIcon(from: url) else { continue }
                discoveredApps.append(AppInfo(url: url, name: name, icon: icon))
            }
            
            self.allApps = discoveredApps.sorted { $0.name.lowercased() < $1.name.lowercased() }
            self.filterApps(with: "")
            
            print("✅ Found \(self.allApps.count) applications.")
        }
    }
    
    func filterApps(with query: String) {
        let filtered: [AppInfo]
        
        if query.isEmpty {
            filtered = allApps
        } else {
            filtered = allApps.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }
        
        self.appPages = chunkAppsIntoPages(apps: filtered)
    }
    
    func createFolder(from apps: [AppInfo], named folderName: String) {
        let folder = AppInfo.createFolder(named: folderName, containing: apps)
        
        allApps.removeAll { app in
            apps.contains { $0.id == app.id }
        }
        
        allApps.append(folder)
        
        filterApps(with: "")
    }
    
    func addAppToFolder(app: AppInfo, folder: AppInfo) {
        guard folder.isFolder else { return }
        
        if let folderIndex = allApps.firstIndex(where: { $0.id == folder.id }) {
            allApps[folderIndex].folderApps.append(app)
            
            allApps.removeAll { $0.id == app.id }
            
            filterApps(with: "")
        }
    }
    
    func openFolder(_ folder: AppInfo) {
        guard folder.isFolder else { return }
        currentFolderName = folder.name
        selectedFolderApps = folder.folderApps
        showingFolderView = true
    }
    
    func closeFolderView() {
        showingFolderView = false
        selectedFolderApps = []
        currentFolderName = ""
    }
    
    func moveApp(from sourceIndex: Int, to destinationIndex: Int, in pageIndex: Int) {
        guard pageIndex < appPages.count,
              sourceIndex < appPages[pageIndex].count,
              destinationIndex <= appPages[pageIndex].count else { return }
        
        let app = appPages[pageIndex].remove(at: sourceIndex)
        appPages[pageIndex].insert(app, at: destinationIndex)
    }
    
    private func chunkAppsIntoPages(apps: [AppInfo]) -> [[AppInfo]] {
        return stride(from: 0, to: apps.count, by: pageSize).map {
            Array(apps[$0 ..< Swift.min($0 + pageSize, apps.count)])
        }
    }
    
    private func findAppURLs() -> [URL] {
        let fileManager = FileManager.default
        let applicationDirectories = fileManager.urls(for: .applicationDirectory, in: .allDomainsMask)

        var urls: [URL] = []
        for dir in applicationDirectories {
            if let appURLs = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
                urls.append(contentsOf: appURLs)
            }
        }
        return urls.filter { $0.pathExtension == "app" }
    }

    private func appName(from url: URL) -> String? {
        return url.deletingPathExtension().lastPathComponent
    }

    private func appIcon(from url: URL) -> NSImage? {
        return NSWorkspace.shared.icon(forFile: url.path)
    }
}
