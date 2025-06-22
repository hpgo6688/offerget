import Cocoa
import SwiftUI
import ScreenCaptureKit
import UserNotifications

@main
struct ScreenshotApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}

struct ContentView: View {
    @State private var isMonitoring = false
    @State private var lastScreenshotTime: Date?
    @State private var screenshotCount = 0
    @State private var statusMessage = "准备就绪"
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("后台截屏应用")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("快捷键: ⌘⇧X")
                    .font(.headline)
                Text("状态: \(statusMessage)")
                    .foregroundColor(isMonitoring ? .green : .orange)
                
                if let lastTime = lastScreenshotTime {
                    Text("上次截屏: \(lastTime, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("截屏总数: \(screenshotCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Button(isMonitoring ? "停止监听" : "开始监听") {
                    toggleMonitoring()
                }
                .buttonStyle(.borderedProminent)
                
                Button("测试截屏") {
                    captureScreen()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(30)
        .frame(width: 300)
        .onAppear {
            checkPermissions()
            requestNotificationPermission()
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("通知权限请求失败: \(error)")
            }
        }
    }
    
    func checkPermissions() {
        Task {
            do {
                // 检查屏幕录制权限
                _ = try await SCShareableContent.current
                await MainActor.run {
                    setupGlobalShortcut()
                    statusMessage = "监听中..."
                    isMonitoring = true
                }
            } catch {
                await MainActor.run {
                    statusMessage = "需要屏幕录制权限"
                    showPermissionAlert()
                }
            }
        }
    }
    
    func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "需要屏幕录制权限"
        alert.informativeText = "要使用截屏功能，请在系统偏好设置 > 隐私与安全性 > 屏幕录制中授权此应用。"
        alert.addButton(withTitle: "打开系统偏好设置")
        alert.addButton(withTitle: "取消")
        
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    func toggleMonitoring() {
        if isMonitoring {
            // 停止监听
            statusMessage = "已停止"
            isMonitoring = false
        } else {
            setupGlobalShortcut()
            statusMessage = "监听中..."
            isMonitoring = true
        }
    }
    
    func setupGlobalShortcut() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 7 { // X 键
                captureScreen()
            }
        }
    }
    
    func captureScreen() {
        Task { @MainActor in
            do {
                let content = try await SCShareableContent.current
                
                // 获取主显示器或所有显示器
                let displays = content.displays
                guard !displays.isEmpty else {
                    statusMessage = "未找到显示器"
                    return
                }
                
                // 可以选择截取所有显示器或仅主显示器
                for (index, display) in displays.enumerated() {
                    let configuration = SCStreamConfiguration()
                    configuration.width = display.width
                    configuration.height = display.height
                    configuration.pixelFormat = kCVPixelFormatType_32BGRA
                    
                    let image = try await SCScreenshotManager.captureImage(
                        contentFilter: SCContentFilter(display: display, excludingWindows: []),
                        configuration: configuration
                    )
                    
                    let filename = displays.count > 1 ? "screenshot_display\(index + 1).png" : "screenshot.png"
                    saveImage(image, filename: filename)
                }
                
                // 更新UI状态
                screenshotCount += 1
                lastScreenshotTime = Date()
                statusMessage = "截屏成功"
                
                // 显示通知
                showNotification()
                
            } catch {
                statusMessage = "截屏失败: \(error.localizedDescription)"
                print("截屏失败: \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    func updateStatus(_ message: String) {
        statusMessage = message
        print(message)
    }
    
    func saveImage(_ image: CGImage, filename: String) {
        let bitmapRep = NSBitmapImageRep(cgImage: image)
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            statusMessage = "无法生成PNG数据"
            print("无法生成PNG数据")
            return
        }
        
        let fileManager = FileManager.default
        
        // 使用用户桌面作为默认保存位置，如果指定目录不存在的话
        let desktopURL = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let customDirectory = URL(fileURLWithPath: "/Users/haotian.chen/Develop/snapshot")
        
        let directory: URL
        if fileManager.fileExists(atPath: customDirectory.path) || createDirectory(at: customDirectory) {
            directory = customDirectory
        } else {
            directory = desktopURL.appendingPathComponent("Screenshots")
            _ = createDirectory(at: directory)
        }
        
        // 生成唯一文件名
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let uniqueFilename = "screenshot_\(timestamp).png"
        let filePath = directory.appendingPathComponent(uniqueFilename)
        
        do {
            try pngData.write(to: filePath)
            statusMessage = "已保存到: \(filePath.lastPathComponent)"
            print("已保存到: \(filePath.path)")
        } catch {
            statusMessage = "保存失败: \(error.localizedDescription)"
            print("保存失败: \(error.localizedDescription)")
        }
    }
    
    func createDirectory(at url: URL) -> Bool {
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch {
            print("无法创建目录 \(url.path): \(error)")
            return false
        }
    }
    
    func showNotification() {
        let content = UNMutableNotificationContent()
        content.title = "截屏完成"
        content.body = "屏幕截图已保存"
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知发送失败: \(error)")
            }
        }
    }
}

// 扩展：支持多显示器截屏的辅助方法
extension ContentView {
    func captureAllDisplays() {
        Task {
            do {
                let content = try await SCShareableContent.current
                let displays = content.displays
                
                for (index, display) in displays.enumerated() {
                    let configuration = SCStreamConfiguration()
                    configuration.width = display.width
                    configuration.height = display.height
                    
                    let image = try await SCScreenshotManager.captureImage(
                        contentFilter: SCContentFilter(display: display, excludingWindows: []),
                        configuration: configuration
                    )
                    
                    saveImage(image, filename: "display_\(index + 1)_screenshot.png")
                }
            } catch {
               
//                updateStatus("多显示器截屏失败: \(error.localizedDescription)")
                statusMessage = "多显示器截屏失败: \(error.localizedDescription)"
            }
        }
    }
}
