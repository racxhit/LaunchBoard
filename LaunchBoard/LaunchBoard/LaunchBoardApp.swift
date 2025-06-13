//
//  LaunchBoardApp.swift
//  LaunchBoard
//
//  Created by Rachit Sharma on 13/06/25.
//

import SwiftUI

@main
struct LaunchBoardApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(HostingWindowFinder(callback: self.setupWindow))
        }
        .windowStyle(.hiddenTitleBar)
    }
    
    private func setupWindow(_ window: NSWindow?) {
        guard let window = window else {
            print("❌ Error: Could not find the window.")
            return
        }

        print("✅ Success! Window found directly. Setting up...")

        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        
        if let screen = NSScreen.main {
            window.setFrame(screen.visibleFrame, display: true)
        }
        
        window.styleMask.remove(.resizable)
    }
}


// MARK: - Hosting Window Finder

struct HostingWindowFinder: NSViewRepresentable {
    // A function to call back when the window is found.
    var callback: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.callback(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
    }
}
