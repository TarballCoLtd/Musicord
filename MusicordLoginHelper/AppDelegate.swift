//
//  AppDelegate.swift
//  MusicordLoginHelper
//
//  Created by tarball on 7/9/23.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let apps = NSWorkspace.shared.runningApplications
        let running = apps.contains { $0.bundleIdentifier == "com.tarball.MusicordApp" }
        if !running { NSWorkspace.shared.launchApplication("/Applications/Musicord.app") }
    }
}
