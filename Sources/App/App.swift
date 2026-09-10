import AppKit
import FinderSync

@main
enum Main {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private var receivedRequest = false
    private let status = NSTextField(labelWithString: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu()
        let appItem = menu.addItem(withTitle: "RightMouseUtility", action: nil, keyEquivalent: "")
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit RightMouseUtility", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        NSApp.mainMenu = menu
        DispatchQueue.main.async { [self] in
            if !receivedRequest { showWindow() }
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        receivedRequest = true
        for url in urls {
            guard let request = CreateRequest(url: url) else { continue }
            create(request)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWindow()
        return true
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        updateStatus()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    private func showWindow() {
        if window == nil { window = makeWindow() }
        updateStatus()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func updateStatus() {
        status.stringValue = FIFinderSyncController.isExtensionEnabled
            ? "Finder extension is enabled." : "Enable the Finder extension to get started."
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 560, height: 290),
                              styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "RightMouseUtility"
        window.isReleasedWhenClosed = false
        window.center()

        let title = NSTextField(labelWithString: "New files. One right-click.")
        title.font = .systemFont(ofSize: 23, weight: .semibold)
        let detail = NSTextField(wrappingLabelWithString:
            "Create TXT, Markdown, and Word files in Finder. Existing files stay safe.")
        detail.textColor = .secondaryLabelColor
        status.font = .systemFont(ofSize: 12)
        let enable = NSButton(title: "Finder Extension Settings", target: self, action: #selector(enableExtension))
        enable.bezelStyle = .rounded

        let buttons = NSStackView()
        buttons.spacing = 8
        for (index, kind) in FileKind.allCases.enumerated() {
            let button = NSButton(title: kind.title + "…", target: self, action: #selector(chooseFolder(_:)))
            button.tag = index
            button.bezelStyle = .rounded
            buttons.addArrangedSubview(button)
        }
        let hint = NSTextField(labelWithString: "Or choose a folder to create a file now.")
        hint.textColor = .secondaryLabelColor
        hint.font = .systemFont(ofSize: 12)
        let stack = NSStackView(views: [title, detail, status, enable, hint, buttons])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        window.contentView?.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: window.contentView!.topAnchor, constant: 28)
        ])
        return window
    }

    @objc private func enableExtension() {
        FIFinderSyncController.showExtensionManagementInterface()
    }

    @objc private func chooseFolder(_ sender: NSButton) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Create"
        if panel.runModal() == .OK, let directory = panel.url {
            create(CreateRequest(target: directory, kind: FileKind.allCases[sender.tag]))
        }
    }

    private func create(_ request: CreateRequest) {
        do {
            let template = Bundle.main.url(forResource: "Doc", withExtension: "docx")
            let file = try FileCreator.create(request, template: template)
            NSWorkspace.shared.activateFileViewerSelecting([file])
        } catch {
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.messageText = "Could Not Create File"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }
}
