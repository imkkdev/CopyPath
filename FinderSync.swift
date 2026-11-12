import Cocoa
import FinderSync

class FinderSync: FIFinderSync {

    override init() {
        super.init()
        // 声明观察整个磁盘,否则 Finder 右键时不会询问本扩展
        FIFinderSyncController.default().directoryURLs =
            Set<URL>(arrayLiteral: URL(fileURLWithPath: "/"))
    }

    // MARK: - 右键菜单(顶层显示)

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "复制路径")
        let item = NSMenuItem(title: "复制路径", action: #selector(copyPath(_:)), keyEquivalent: "")
        item.target = self
        menu.addItem(item)
        return menu
    }

    // MARK: - 复制路径

    @objc func copyPath(_ sender: AnyObject?) {
        let controller = FIFinderSyncController.default()

        // 选中了文件/文件夹:复制所有选中项;否则复制当前所在文件夹
        var urls = controller.selectedItemURLs() ?? []
        if urls.isEmpty, let target = controller.targetedURL() {
            urls = [target]
        }
        guard !urls.isEmpty else { return }

        let text = urls.map { $0.path }.joined(separator: "\n")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
