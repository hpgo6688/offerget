import Cocoa
import HotKey
import UserNotifications
import ScreenCaptureKit

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    // 全局快捷键管理器
    private var hotKey: HotKey?
    private var statusItem: NSStatusItem?
    
    // 启动完成时调用
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 注意：使用 @NSApplicationDelegateAdaptor 时，不需要手动设置 NSApp.delegate
        // SwiftUI 会自动处理这个
        
        setupGlobalHotkey()
        setupStatusBarItem()
        requestPermissions()
    }
    
    // 设置全局快捷键 (Cmd+Shift+6)
    private func setupGlobalHotkey() {
        hotKey = HotKey(key: .six, modifiers: [.command, .shift])
        
        hotKey?.keyDownHandler = { [weak self] in
            self?.captureScreen()
        }
    }
    
    // 创建状态栏图标
    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "camera.aperture", accessibilityDescription: "截屏")
        }
        
        let menu = NSMenu()
        menu.addItem(withTitle: "截屏", action: #selector(captureScreen), keyEquivalent: "s")
        menu.addItem(.separator())
        menu.addItem(withTitle: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem?.menu = menu
    }
    
    // 请求必要权限
    private func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            print("通知权限: \(granted ? "已授权" : "被拒绝")")
        }
        
        // 屏幕录制权限会在首次尝试截屏时由系统自动请求
    }
    
    // 截屏主逻辑
    @objc func captureScreen() {
        Task {
            do {
                try await ScreenshotManager.captureAndSaveToDesktop()
                sendNotification(title: "截屏成功", body: "截图已保存到桌面")
            } catch {
                showAlert(title: "截屏失败", text: error.localizedDescription)
                if error.localizedDescription.contains("TCC") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
                }
            }
        }
    }
    
    // 显示系统通知
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // 显示警告弹窗
    private func showAlert(title: String, text: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = text
            alert.addButton(withTitle: "确定")
            alert.runModal()
        }
    }
}

// 关键扩展：使AppDelegate能在SwiftUI中使用
extension AppDelegate {
    func updateHotkey(key: Key, modifiers: NSEvent.ModifierFlags) {
        hotKey = HotKey(key: key, modifiers: modifiers)
        setupGlobalHotkey()
    }
}
