import AppKit
import SwiftUI

class LaunchBoardWindow: NSWindow {

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: .borderless, backing: backingStoreType, defer: flag)

        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isMovableByWindowBackground = false
        self.hidesOnDeactivate = false
        
        if let screen = NSScreen.main {
            self.setFrame(screen.frame, display: false)
        }
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
    
    override func mouseDown(with event: NSEvent) {
        let locationInWindow = event.locationInWindow
        if let contentView = self.contentView {
            let locationInContent = contentView.convert(locationInWindow, from: nil)
            if !contentView.bounds.contains(locationInContent) {
                if let appDelegate = NSApp.delegate as? AppDelegate {
                    appDelegate.toggleLaunchpad()
                }
                return
            }
        }
        super.mouseDown(with: event)
    }
}
