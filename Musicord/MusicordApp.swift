//
//  MusicordApp.swift
//  Musicord
//
//  Created by tarball on 7/6/23.
//

import Cocoa
import MediaPlayer
import SwiftUI
import SwordRPC
import ServiceManagement

@main
struct MusicordApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    override init() {
        rpc = SwordRPC(appId: "1127028784621703224", autoRegister: true)
        connected = rpc.connect()
    }
    
    var statusBarItem: NSStatusItem?
    var connected = false
    var rpc: SwordRPC
    let menu = NSMenu()
    var launchAtLogin: NSMenuItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))
        guard let MRMediaRemoteRegisterForNowPlayingNotificationsPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteRegisterForNowPlayingNotifications" as CFString) else { return }
        typealias MRMediaRemoteRegisterForNowPlayingNotificationsFunction = @convention(c) (DispatchQueue) -> Void
        let MRMediaRemoteRegisterForNowPlayingNotifications = unsafeBitCast(MRMediaRemoteRegisterForNowPlayingNotificationsPointer, to: MRMediaRemoteRegisterForNowPlayingNotificationsFunction.self)
        guard let MRMediaRemoteGetNowPlayingInfoPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString) else { return }
        typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
        let MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(MRMediaRemoteGetNowPlayingInfoPointer, to: MRMediaRemoteGetNowPlayingInfoFunction.self)
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main, { information in
            guard let artist = information["kMRMediaRemoteNowPlayingInfoArtist"] else { return }
            guard let album = information["kMRMediaRemoteNowPlayingInfoAlbum"] else { return }
            guard let title = information["kMRMediaRemoteNowPlayingInfoTitle"] else { return }
            guard let playing = information["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Int else { return }
            guard let start = information["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double else { return }
            guard let end = information["kMRMediaRemoteNowPlayingInfoDuration"] as? Double else { return }
            guard let track = information["kMRMediaRemoteNowPlayingInfoTrackNumber"] as? Int else { return }
            guard let total = information["kMRMediaRemoteNowPlayingInfoTotalTrackCount"] as? Int else { return }
            var presence = RichPresence()
            presence.details = "\(artist) - \(title)"
            presence.state = "on \(album)"
            presence.assets.largeImage = "applemusic"
            presence.assets.largeText = "Listening to Apple Music"
            presence.timestamps.end = Date().addingTimeInterval(end-start)
            presence.party.size = track
            presence.party.max = total
            if playing == 0 {
                presence.assets.smallImage = "yellow"
                presence.assets.smallText = "Paused"
                presence.timestamps.end = nil
            } else {
                presence.assets.smallImage = "green"
                presence.assets.smallText = "Playing"
            }
            self.rpc.setPresence(presence)
        })
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "kMRMediaRemoteNowPlayingInfoDidChangeNotification"), object: nil, queue: nil) { notification in
            MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main, { information in
                if !self.connected {
                    self.rpc = SwordRPC(appId: "1127028784621703224", autoRegister: true)
                    self.connected = self.rpc.connect()
                }
                guard let artist = information["kMRMediaRemoteNowPlayingInfoArtist"] else { return }
                guard let album = information["kMRMediaRemoteNowPlayingInfoAlbum"] else { return }
                guard let title = information["kMRMediaRemoteNowPlayingInfoTitle"] else { return }
                guard let playing = information["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Int else { return }
                guard let start = information["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double else { return }
                guard let end = information["kMRMediaRemoteNowPlayingInfoDuration"] as? Double else { return }
                guard let track = information["kMRMediaRemoteNowPlayingInfoTrackNumber"] as? Int else { return }
                guard let total = information["kMRMediaRemoteNowPlayingInfoTotalTrackCount"] as? Int else { return }
                var presence = RichPresence()
                presence.details = "\(artist) - \(title)"
                presence.state = "on \(album)"
                presence.assets.largeImage = "applemusic"
                presence.assets.largeText = "Listening to Apple Music"
                presence.timestamps.end = Date().addingTimeInterval(end-start)
                presence.party.size = track
                presence.party.max = total
                if playing == 0 {
                    presence.assets.smallImage = "yellow"
                    presence.assets.smallText = "Paused"
                    presence.timestamps.end = nil
                } else {
                    presence.assets.smallImage = "green"
                    presence.assets.smallText = "Playing"
                }
                self.rpc.setPresence(presence)
            })
        }
        MRMediaRemoteRegisterForNowPlayingNotifications(DispatchQueue.main)
        menu.delegate = self
        menu.removeAllItems()
        launchAtLogin = NSMenuItem(title: "Launch at Login", action: #selector(launchAtLoginSelector), keyEquivalent: "")
        let found = NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "com.tarball.MusicordHelper" }
        launchAtLogin!.state = found ? .on : .off
        menu.addItem(launchAtLogin!)
        menu.addItem(NSMenuItem(title: "Quit Musicord", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let image = NSImage(systemSymbolName: "music.note", accessibilityDescription: nil)
        image?.isTemplate = true
        statusBarItem?.button?.image = image
        statusBarItem?.menu = menu
    }
    
    @objc func launchAtLoginSelector() {
        launchAtLogin!.state = launchAtLogin!.state == .on ? .off : .on
        SMLoginItemSetEnabled("com.tarball.MusicordHelper" as CFString, launchAtLogin!.state == .on ? true : false)
    }
}

struct ContentView: View {
    var body: some View {
        Text("Hello, world!")
            .font(.title)
    }
}
