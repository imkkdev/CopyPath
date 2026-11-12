import AppKit

// 宿主 app 仅作为扩展载体,启动时引导用户到系统设置启用扩展
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
    NSWorkspace.shared.open(url)
}

let alert = NSAlert()
alert.messageText = "「复制路径」已安装"
alert.informativeText = "在「系统设置 → 通用 → 登录项与扩展 → 扩展」中找到「复制路径」,打开开关即可。\n\n之后在 Finder 中右键任意文件或文件夹,菜单最外层会出现「复制路径」。"
alert.addButton(withTitle: "好的")
alert.runModal()
