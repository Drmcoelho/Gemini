// MenuBarTunnels — SwiftUI (Xcode project scaffold minimal)
import SwiftUI

@main
struct MenuBarTunnelsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var tunnels: [Tunnel] = [
        Tunnel(name: "DB → clinic", host: "clinic-vm", lport: "5432", rhost: "127.0.0.1", rport: "5432")
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🔌"
        constructMenu()
    }

    func constructMenu() {
        let menu = NSMenu()
        for t in tunnels {
            let item = NSMenuItem(title: t.name + (t.running ? " (on)" : " (off)"), action: #selector(toggleTunnel(_:)), keyEquivalent: "")
            item.representedObject = t
            menu.addItem(item)
        }
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc func toggleTunnel(_ sender: NSMenuItem) {
        guard var t = sender.representedObject as? Tunnel else { return }
        if t.running {
            t.stop()
        } else {
            t.start()
        }
        if let idx = tunnels.firstIndex(where: {$0.id == t.id}) {
            tunnels[idx] = t
        }
        constructMenu()
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }
}

struct Tunnel: Identifiable {
    var id = UUID()
    var name: String
    var host: String
    var lport: String
    var rhost: String
    var rport: String
    var running: Bool = false
    var task: Process? = nil

    mutating func start() {
        let p = Process()
        p.launchPath = "/bin/bash"
        p.arguments = ["-lc", "PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin ~/.local/bin/ssh-tunnel"]
        p.environment = [
            "HOST": host, "LPORT": lport, "RHOST": rhost, "RPORT": rport
        ]
        do {
            try p.run()
            task = p
            running = true
        } catch {
            NSLog("Failed to start tunnel: \(error.localizedDescription)")
        }
    }

    mutating func stop() {
        task?.terminate()
        task = nil
        running = false
    }
}
