# CopyPath — macOS Finder 右键「复制路径」

在 Finder 右键菜单**最外层**添加「复制路径」按钮,一键复制选中文件/文件夹的完整 POSIX 路径。

原生 Finder Sync 扩展实现,免费、无后台驻留、无广告。

## 功能特性

- 右键菜单**最外层**直出,无需像系统那样按住 Option 键
- 支持多选,每个路径一行
- 支持文件、文件夹混合选择
- 在文件夹内空白处右键 = 复制当前文件夹路径
- 侧边栏、桌面同样可用

## 安装

### 方式一:下载编译好的版本

1. 从 [Releases](https://github.com/imkkdev/CopyPath/releases) 下载 `CopyPath.app.zip` 并解压
2. 将 `CopyPath.app` 拖入「应用程序」文件夹(放其他位置也可以)
3. **双击启动一次** CopyPath.app(会弹出安装提示,这一步会让系统注册扩展,不能跳过)

   > 应用未经 Apple 公证,首次打开时 macOS 会弹出「未打开 "CopyPath"」的安全警告。点「完成」(不要点「移到废纸篓」),再打开 **系统设置 → 隐私与安全性**,点底部「仍要打开」;或直接在终端执行:
   >
   > ```bash
   > xattr -rd com.apple.quarantine /Applications/CopyPath.app
   > ```
   >
   > 该命令移除下载时系统打上的隔离标记,不会破坏应用。自行构建(方式二)不经浏览器下载,通常不会遇到此提示。

4. 打开 **系统设置 → 通用 → 登录项与扩展**,在「扩展」区域进入对应分类(Sequoia 下归入「文件提供程序」/「访达」),打开 **CopyPath** 开关
5. 在 Finder 中右键任意文件/文件夹,菜单最外层即可看到「复制路径」

### 方式二:自行构建

需要 Xcode(含命令行工具):

```bash
git clone https://github.com/imkkdev/CopyPath.git
cd CopyPath
swift DrawIcon.swift AppIcon.png   # 可选:重新生成图标
./build.sh                          # 产物在 build/CopyPath.app
```

> `build.sh` 默认使用开发者证书签名(`SIGN` 变量),没有证书的话可将其改为 `-`(ad-hoc)尝试。
> 构建完成后安装步骤同上(启动一次 app → 系统设置里打开开关)。

## 卸载

1. 系统设置 → 通用 → 登录项与扩展 → 扩展,关闭 CopyPath 开关
2. 删除 `CopyPath.app`

## 实现要点(踩坑记录)

给想自己写 Finder 扩展的人省点时间,以下是本项目中实测的系统行为(macOS 15.7 Sequoia):

1. **扩展必须带 App Sandbox 权限**。`pluginkit` 在扫描阶段会直接拒收非沙盒扩展,且静默无提示,只有日志里能看到:
   `pkd: rejecting; Ignoring mis-configured plugin: plug-ins must be sandboxed`
2. **必须显式设置 `directoryURLs`**(如全盘 `/`),否则扩展注册成功、开关也能打开,但 Finder 右键时根本不会询问扩展,菜单不出现
3. **替换 app 后必须重新启动一次宿主 app**,LaunchServices/pkd 才会重新扫描内嵌扩展;仅 `pluginkit -a` 不够
4. 调试利器:
   - `pluginkit -mAD -p com.apple.FinderSync -vvv` 查看所有 Finder 扩展注册状态(`+` 已启用)
   - `log show --predicate 'process == "pkd"' --debug` 看扩展被拒收的具体原因
5. Swift 手搓 appex 的链接入口是 `-Xlinker -e -Xlinker _NSExtensionMain`,不是常规 `main`
6. 本 SDK(macOS 15)中 `FIFinderSync` 以**类**形式导入,直接继承并用 `override func menu(for:)`;不能同时对 `FIFinderSyncController` 和 `FIFinderSync` 做多重继承

## 目录结构

```
CopyPath/
├── FinderSync.swift            # 扩展主体:右键菜单 + 复制逻辑
├── main.swift                  # 宿主 app(引导启用扩展)
├── Info.plist / ExtInfo.plist  # 宿主 / 扩展配置
├── CopyPathExt.entitlements    # App Sandbox 权限(注册的硬性要求)
├── build.sh                    # 一键构建 + 签名 + 组装
├── DrawIcon.swift              # 程序化绘制图标
├── MakeIcon.swift              # 从图片生成图标(抠背景 + 圆角)
└── build/CopyPath.app          # 构建产物
```
