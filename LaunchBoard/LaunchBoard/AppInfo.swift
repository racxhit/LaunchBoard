//
//  AppInfo.swift
//  LaunchBoard
//
//  Created by Rachit Sharma on 13/06/25.
//

import SwiftUI

struct AppInfo: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let icon: NSImage

    // We need to implement Hashable and Equatable manually because NSImage isn't by default.
    // We can just use the app's URL, which is always unique.
    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        lhs.url == rhs.url
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}
