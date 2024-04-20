import Cocoa
import SwiftUI

class ViewController: NSViewController {
    override func viewDidLoad() {
        
    }
}

class OverlayWindowController: NSWindowController {
    var menubar: NSStatusBar!
    var menubarItem: NSStatusItem!
    var inTermination: Int = 0
    
    override func windowDidLoad() {
        let window = self.window
        window?.backgroundColor = .clear
        window?.hasShadow = false
        window?.level = .screenSaver
        window?.setFrame(NSScreen.main!.frame, display: true)
        window?.title = "TheEffect"
        
        window?.ignoresMouseEvents = true
        NSApp.setActivationPolicy(.accessory)
        
        menubar = NSStatusBar()
        menubarItem = menubar.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = menubarItem.button {
            button.image = NSImage(systemSymbolName: "dot.scope.display", accessibilityDescription: "Control display effects")
            button.title = Renderer.shader.rawValue
            button.action = #selector(menuClicked)
            button.target = self
        }
    }
    
    @objc func menuClicked() {
        if inTermination == 0 {
            let nextIndex: Int = ShaderType.allCases.firstIndex(of: Renderer.shader)! + 1
            
            if nextIndex != ShaderType.allCases.count {
                Renderer.shader = ShaderType.allCases[nextIndex]
                menubarItem.button?.title = Renderer.shader.rawValue
            } else if nextIndex == ShaderType.allCases.count {
                menubarItem.button?.title = String(localized: "Terminate app?")
                menubarItem.button?.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Close")
                inTermination = 1
            }
        } else if inTermination == 1 {
            menubarItem.button?.title = String(localized: "Really?")
            inTermination = 2
        } else if inTermination == 2 {
            menubarItem.button?.title = String(localized: "REALLY?")
            inTermination = 3
        } else {
            NSApp.terminate(self)
        }
    }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
