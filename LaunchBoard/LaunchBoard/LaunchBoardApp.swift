import SwiftUI
import ServiceManagement

@main
struct LaunchBoardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: LaunchBoardWindowController?
    private var isLaunchpadVisible = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupAutoStart()
        
        windowController = LaunchBoardWindowController()
        
        NSApp.setActivationPolicy(.regular)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(closeLaunchBoardNotification),
            name: NSNotification.Name("CloseLaunchBoard"),
            object: nil
        )
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        toggleLaunchpad()
        return false
    }
    
    private func setupAutoStart() {
        do {
            try SMAppService.mainApp.register()
            print("✅ Auto-start enabled")
        } catch {
            print("❌ Failed to enable auto-start: \(error)")
        }
    }
    
    func toggleLaunchpad() {
        print("🔄 toggleLaunchpad called - current state: \(isLaunchpadVisible)")
        if isLaunchpadVisible {
            hideLaunchpad()
        } else {
            showLaunchpad()
        }
    }
    
    private func showLaunchpad() {
        guard !isLaunchpadVisible else { return }
        
        print("📱 Showing LaunchBoard")
        isLaunchpadVisible = true
        windowController?.showWindow(nil)
        windowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        NotificationCenter.default.post(name: NSNotification.Name("ClearSearch"), object: nil)
    }
    
    private func hideLaunchpad() {
        guard isLaunchpadVisible else { return }
        
        print("🙈 Hiding LaunchBoard")
        isLaunchpadVisible = false
        windowController?.window?.orderOut(nil)
    }
    
    @objc private func closeLaunchBoardNotification() {
        print("📨 Received close notification")
        if isLaunchpadVisible {
            hideLaunchpad()
        }
    }
}
