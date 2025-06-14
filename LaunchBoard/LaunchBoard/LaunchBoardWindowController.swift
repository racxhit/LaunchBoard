import AppKit
import SwiftUI

class LaunchBoardWindowController: NSWindowController {

    convenience init() {
        guard let mainScreen = NSScreen.main else {
            fatalError("No main screen available")
        }
        
        let screenFrame = mainScreen.frame
        
        let window = LaunchBoardWindow(
            contentRect: screenFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        window.setFrame(screenFrame, display: true)
        window.center()
        
        window.contentViewController = NSHostingController(rootView: ContentView())

        self.init(window: window)
    }
    
    override func showWindow(_ sender: Any?) {
        if let screen = NSScreen.main {
            window?.setFrame(screen.frame, display: true)
        }
        super.showWindow(sender)
    }
}
