//
//  AppListViewModel.swift
//  LaunchBoard
//
//  Created by Rachit Sharma on 13/06/25.
//

import SwiftUI
import Combine

@MainActor
class AppListViewModel: ObservableObject {

    @Published var apps: [AppInfo] = []

    func fetchInstalledApps() {
        print("🔍 Starting app search...")

        Task(priority: .userInitiated) {
            let appURLs = findAppURLs()

            var discoveredApps: [AppInfo] = []
            for url in appURLs {
                guard let name = appName(from: url),
                      let icon = appIcon(from: url) else {
                    continue
                }
                discoveredApps.append(AppInfo(url: url, name: name, icon: icon))
            }

            let sortedApps = discoveredApps.sorted { $0.name < $1.name }

            self.apps = sortedApps
            print("✅ Found \(self.apps.count) applications.")
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
