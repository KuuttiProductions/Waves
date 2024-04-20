//
//  AppDelegate.swift
//  Waves
//
//  Created by Kuutti Taavitsainen on 19.4.2024.
//

import Cocoa

class ViewyController: NSViewController {
    override func viewDidLoad() {
        
    }
}

class OverlayWindowController: NSWindowController {
    override func windowDidLoad() {
        let window = self.window
        window?.backgroundColor = .clear
        window?.hasShadow = false
        window?.level = .screenSaver
        window?.setFrame(NSScreen.main!.frame, display: true)
        
        window?.ignoresMouseEvents = true
    }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

