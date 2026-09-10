import AppKit
import FinderSync
import os

@objc(FinderExtension)
final class FinderExtension: FIFinderSync {
    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        let controller = FIFinderSyncController.default()
        let target: URL?
        switch menuKind {
        case .contextualMenuForContainer, .contextualMenuForSidebar:
            target = controller.targetedURL()
        case .contextualMenuForItems:
            guard let items = controller.selectedItemURLs(), items.count == 1 else { return nil }
            target = items.first
        default:
            return nil
        }
        guard let target, target.isFileURL else { return nil }

        let menu = NSMenu()
        for (index, kind) in FileKind.allCases.enumerated() {
            let item = NSMenuItem(title: kind.title, action: #selector(createFile(_:)), keyEquivalent: "")
            item.target = self
            // Finder copies menu items. Use tags, not representedObject.
            item.tag = index + (menuKind == .contextualMenuForItems ? 2 : 0)
            menu.addItem(item)
        }
        return menu
    }

    @objc private func createFile(_ sender: NSMenuItem) {
        guard (0..<4).contains(sender.tag) else { return }
        let controller = FIFinderSyncController.default()
        let target = sender.tag >= 2 ? controller.selectedItemURLs()?.first : controller.targetedURL()
        guard let target, target.isFileURL else { return }
        let url = CreateRequest(target: target, kind: FileKind.allCases[sender.tag % 2]).url
        let app = Bundle.main.bundleURL.deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        NSWorkspace.shared.open([url], withApplicationAt: app, configuration: configuration) { _, error in
            if let error {
                Logger(subsystem: "com.frankyang.RightMouseUtility.FinderExtension", category: "launch")
                    .error("Could not open the app: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
