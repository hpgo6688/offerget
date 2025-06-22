import SwiftUI
import ScreenCaptureKit
import UserNotifications

// 修复后的PermissionManager - 确保正确的初始化
@MainActor
class PermissionManager: ObservableObject {
    // 使用明确的初始值，避免内存访问问题
    @Published var screenRecordingStatus: String = "检查中..."
    @Published var notificationStatus: String = "检查中..."
    @Published var hasScreenPermission: Bool = false
    @Published var hasNotificationPermission: Bool = false
    
    // 明确的初始化方法
    init() {
        // 初始化时设置默认值
        self.screenRecordingStatus = "检查中..."
        self.notificationStatus = "检查中..."
        self.hasScreenPermission = false
        self.hasNotificationPermission = false
        
        print("🔧 PermissionManager 初始化完成")
    }
    
    func forceUpdateUI() {
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
    }
    // 异步方法需要从主线程调用
    func checkAllPermissions() {
        print("🔍 开始检查所有权限...")
        print("📍 当前线程: \(Thread.isMainThread ? "主线程" : "后台线程")")
        
        Task { @MainActor in
            print("🔄 在主线程中执行权限检查...")
            await checkScreenRecordingPermission()
            await checkNotificationPermission()
            
            // 添加详细的权限检查日志
            logPermissionStatus()
            print("✅ 权限检查完成")
            
            // 强制UI刷新
                   self.forceUpdateUI()
        }
    }
    
    // 添加权限状态日志函数
    private func logPermissionStatus() {
        print("=== 权限检查报告 ===")
        print("📱 屏幕录制权限: \(hasScreenPermission ? "✅ 已授权" : "❌ 未授权")")
        print("🔔 通知权限: \(hasNotificationPermission ? "✅ 已授权" : "❌ 未授权")")
        
        // 检查哪个权限缺失
        if !hasScreenPermission && !hasNotificationPermission {
            print("⚠️  缺少权限: 屏幕录制 和 通知")
        } else if !hasScreenPermission {
            print("⚠️  缺少权限: 屏幕录制")
        } else if !hasNotificationPermission {
            print("⚠️  缺少权限: 通知")
        } else {
            print("✅ 所有权限已获取")
        }
        print("==================")
        
        // 强制刷新UI
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
    }
    
    // 修复屏幕录制权限检查
//    private func checkScreenRecordingPermission() async {
//        print("🔍 开始检查屏幕录制权限...")
//        do {
//            let content = try await SCShareableContent.current
//            self.hasScreenPermission = !content.displays.isEmpty
//            
//            if self.hasScreenPermission {
//                print("✅ 屏幕录制权限检查成功，找到 \(content.displays.count) 个显示器")
//                self.screenRecordingStatus = "✅ 屏幕录制权限已获取"
//            } else {
//                print("❌ 屏幕录制权限检查失败，未找到可用显示器")
//                self.screenRecordingStatus = "❌ 无可用显示器"
//            }
//        } catch {
//            self.hasScreenPermission = false
//            print("❌ 屏幕录制权限检查出错: \(error.localizedDescription)")
//            
//            if error.localizedDescription.contains("TCC") {
//                print("⚠️  这是TCC权限错误，需要用户手动授权")
//                self.screenRecordingStatus = "❌ 需要屏幕录制权限"
//            } else {
//                self.screenRecordingStatus = "❌ 权限检查失败: \(error.localizedDescription)"
//            }
//        }
//    }
    
    private func checkScreenRecordingPermission() async {
        print("🔍 开始检查屏幕录制权限...")
        do {
            let content = try await SCShareableContent.current
            await MainActor.run {
                self.hasScreenPermission = !content.displays.isEmpty
                
                if self.hasScreenPermission {
                    print("✅ 屏幕录制权限检查成功，找到 \(content.displays.count) 个显示器")
                    self.screenRecordingStatus = "✅ 屏幕录制权限已获取"
                } else {
                    print("❌ 屏幕录制权限检查失败，未找到可用显示器")
                    self.screenRecordingStatus = "❌ 无可用显示器"
                }
            }
        } catch {
            await MainActor.run {
                self.hasScreenPermission = false
                print("❌ 屏幕录制权限检查出错: \(error.localizedDescription)")
                
                if error.localizedDescription.contains("TCC") {
                    print("⚠️  这是TCC权限错误，需要用户手动授权")
                    self.screenRecordingStatus = "❌ 需要屏幕录制权限"
                } else {
                    self.screenRecordingStatus = "❌ 权限检查失败: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // 修复通知权限检查
    private func checkNotificationPermission() async {
        print("🔍 开始检查通知权限...")
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        
        print("📋 通知权限状态: \(settings.authorizationStatus.rawValue)")
        
        switch settings.authorizationStatus {
        case .authorized:
            print("✅ 通知权限已完全授权")
            self.hasNotificationPermission = true
            self.notificationStatus = "✅ 通知权限已获取"
        case .denied:
            print("❌ 通知权限被用户拒绝")
            self.hasNotificationPermission = false
            self.notificationStatus = "❌ 通知权限被拒绝"
        case .notDetermined:
            print("⚠️  通知权限尚未确定，需要请求授权")
            self.hasNotificationPermission = false
            self.notificationStatus = "⚠️ 通知权限未确定"
        case .provisional:
            print("⚠️  通知权限为临时授权状态")
            self.hasNotificationPermission = true
            self.notificationStatus = "⚠️ 通知权限为临时状态"
        case .ephemeral:
            print("⚠️  通知权限为短暂授权状态")
            self.hasNotificationPermission = false
            self.notificationStatus = "⚠️ 通知权限为临时状态"
        @unknown default:
            print("❓ 通知权限状态未知: \(settings.authorizationStatus.rawValue)")
            self.hasNotificationPermission = false
            self.notificationStatus = "❓ 通知权限状态未知"
        }
    }
    
    // 请求通知权限
    func requestNotificationPermission() async {
        print("📝 开始请求通知权限...")
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                print("✅ 用户同意了通知权限")
                self.hasNotificationPermission = true
                self.notificationStatus = "✅ 通知权限已获取"
            } else {
                print("❌ 用户拒绝了通知权限")
                self.hasNotificationPermission = false
                self.notificationStatus = "❌ 用户拒绝了通知权限"
            }
        } catch {
            print("❌ 通知权限请求失败: \(error.localizedDescription)")
            self.hasNotificationPermission = false
            self.notificationStatus = "❌ 通知权限请求失败: \(error.localizedDescription)"
        }
    }
    
    // 打开系统设置
    func openSystemPreferences() {
        print("🔧 打开系统屏幕录制权限设置")
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func openNotificationSettings() {
        print("🔧 打开系统通知权限设置")
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
}



// 修复后的ContentView
struct ContentView: View {
    // 使用State而不是StateObject，避免初始化问题
//    @State private var permissionManager = PermissionManager()
    @StateObject private var permissionManager = PermissionManager()
    @StateObject private var hotKeyManager = HotKeyManager.shared // 添加快捷键管理器
    @State private var statusMessage = ""
    @State private var isCapturing = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("截屏工具")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // 权限状态显示
            VStack(alignment: .leading, spacing: 8) {
                Text(permissionManager.screenRecordingStatus)
                    .foregroundColor(permissionManager.hasScreenPermission ? .green : .red)
                
                Text(permissionManager.notificationStatus)
                    .foregroundColor(permissionManager.hasNotificationPermission ? .green : .orange)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            // 权限设置按钮
            VStack(spacing: 10) {
                if !permissionManager.hasScreenPermission || !permissionManager.hasNotificationPermission {
                    // 添加详细的权限检查日志
                    let _ = logMissingPermissions()
                    
                    if !permissionManager.hasScreenPermission {
                        Button("打开屏幕录制设置") {
                            permissionManager.openSystemPreferences()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    if !permissionManager.hasNotificationPermission {
                        Button("请求通知权限") {
                            Task {
                                await permissionManager.requestNotificationPermission()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    // 权限都正常时显示状态
                    Text("✅ 所有权限已获取")
                        .foregroundColor(.green)
                        .font(.headline)
                }
                
                // 始终显示重新检查按钮
                Button("重新检查权限") {
                    print("🔄 用户点击重新检查权限")
                    print("📍 按钮点击时线程: \(Thread.isMainThread ? "主线程" : "后台线程")")
                    // 方法2: 备用的直接调用
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        print("🔄 备用检查方法执行...")
                        permissionManager.checkAllPermissions()
                    }
                }
                .buttonStyle(.bordered)
            }
            
            // 截屏按钮
            if permissionManager.hasScreenPermission {
                Button(action: {
                    captureScreen()
                }) {
                    HStack {
                        if isCapturing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isCapturing ? "截屏中..." : "开始截屏")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isCapturing)
                .font(.headline)
                .padding()
            }
            
            // 状态消息
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
        .onAppear {
            print("🚀 ContentView 出现，准备检查权限")
            print("📊 应用启动时权限初始状态:")
            print("   - 屏幕录制: \(permissionManager.hasScreenPermission)")
            print("   - 通知权限: \(permissionManager.hasNotificationPermission)")
            
            // 延迟检查权限，避免初始化时的竞态条件
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                permissionManager.checkAllPermissions()
            }

             // 初始化快捷键
            hotKeyManager.setupHotKey()
        }
//        .onAppear {
//                    print("🚀 ContentView 出现，准备检查权限")
//                    permissionManager.checkAllPermissions()
//                }
        // 使用新的 onChange API
        .onChange(of: permissionManager.hasScreenPermission) { oldValue, newValue in
            print("🔄 屏幕录制权限变化，从 \(oldValue) 变为 \(newValue)")
            permissionManager.forceUpdateUI()
        }
        .onChange(of: permissionManager.hasNotificationPermission) { oldValue, newValue in
            print("🔄 通知权限变化，从 \(oldValue) 变为 \(newValue)")
            permissionManager.forceUpdateUI()
        }
    }
    private func handleSaveError(_ error: Error) async {
        await MainActor.run {
            isCapturing = false
            
            let nsError = error as NSError
            switch nsError.code {
            case 403:
                statusMessage = "错误: 无写入权限，请检查系统设置"
                showPermissionAlert()
            case 404:
                statusMessage = "错误: 找不到桌面目录"
            default:
                statusMessage = "保存失败: \(error.localizedDescription)"
            }
        }
    }
    
    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "需要文件访问权限"
        alert.informativeText = "请在系统设置中授予本应用文件访问权限"
        alert.addButton(withTitle: "打开设置")
        alert.addButton(withTitle: "取消")
        
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
        }
    }
    private func saveWithPanel(_ image: CGImage) async {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "screenshot_\(Date().timeIntervalSince1970).png"
        savePanel.allowedContentTypes = [.png]
        
        let response = await savePanel.begin()
        guard response == .OK, let url = savePanel.url else {
            await MainActor.run {
                statusMessage = "用户取消保存"
                isCapturing = false
            }
            return
        }
        
        do {
            let imageRep = NSBitmapImageRep(cgImage: image)
            guard let pngData = imageRep.representation(using: .png, properties: [:]) else {
                throw NSError(domain: "图片转换失败", code: 500)
            }
            try pngData.write(to: url)
            
            await MainActor.run {
                statusMessage = "截图已保存到: \(url.lastPathComponent)"
                isCapturing = false
            }
        } catch {
            await handleSaveError(error)
        }
    }
   
    
    // 添加缺失权限日志函数 - 现在总是会执行
    private func logMissingPermissions() {
        let hasScreen = permissionManager.hasScreenPermission
        let hasNotification = permissionManager.hasNotificationPermission
        
        print("🔍 UI权限状态检查 - 屏幕录制: \(hasScreen ? "✅" : "❌"), 通知: \(hasNotification ? "✅" : "❌")")
        
        if !hasScreen || !hasNotification {
            var missingPermissions: [String] = []
            if !hasScreen { missingPermissions.append("屏幕录制") }
            if !hasNotification { missingPermissions.append("通知") }
            
            print("⚠️  当前缺少权限: \(missingPermissions.joined(separator: ", "))")
        } else {
            print("🎉 所有权限状态正常")
        }
    }
    
    // 新增：总是记录当前权限状态
    private func logCurrentPermissionStatus() {
        let hasScreen = permissionManager.hasScreenPermission
        let hasNotification = permissionManager.hasNotificationPermission
        
        print("📋 当前UI渲染时权限状态:")
        print("   🖥️  屏幕录制: \(hasScreen ? "已授权 ✅" : "未授权 ❌")")
        print("   🔔 通知权限: \(hasNotification ? "已授权 ✅" : "未授权 ❌")")
        print("   📊 整体状态: \(hasScreen && hasNotification ? "完全正常 🎉" : "需要处理 ⚠️")")
    }
    
    func captureScreen() {
        guard !isCapturing else { return }
        
        print("📸 开始截屏流程...")
        isCapturing = true
        statusMessage = "准备截屏..."
        
        Task {
            do {
                print("🔍 获取屏幕内容...")
                let content = try await SCShareableContent.current
                let displays = content.displays
                
                guard let display = displays.first else {
                    print("❌ 未找到可用显示器")
                    await MainActor.run {
                        statusMessage = "未找到可用显示器"
                        isCapturing = false
                    }
                    return
                }
                
                print("✅ 找到显示器: \(display.width)x\(display.height)")
                
                await MainActor.run {
                    statusMessage = "正在截屏..."
                }
                
                let configuration = SCStreamConfiguration()
                configuration.width = display.width
                configuration.height = display.height
                
                print("📸 开始截取屏幕图像...")
                let image = try await SCScreenshotManager.captureImage(
                    contentFilter: SCContentFilter(display: display, excludingWindows: []),
                    configuration: configuration
                )
                
                print("✅ 截屏成功，开始保存...")
                // 保存图片
                await saveImageToDesktop(image)
                
            } catch {
                print("❌ 截屏失败: \(error.localizedDescription)")
                await MainActor.run {
                    statusMessage = "截屏失败: \(error.localizedDescription)"
                    isCapturing = false
                    
                    // 如果是权限问题，重新检查
                    if error.localizedDescription.contains("TCC") {
                        print("⚠️  检测到TCC权限问题，重新检查权限")
                        permissionManager.checkAllPermissions()
                    }
                }
            }
        }
    }
    
    @MainActor
    private func saveImageToDesktop(_ image: CGImage) async {
        do {
            // 1. 使用安全作用域书签获取桌面路径
            // guard let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first else {
            guard let desktopURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
                throw NSError(domain: "无法获取桌面路径", code: 404)
            }
            
            // 2. 检查写入权限
            if !FileManager.default.isWritableFile(atPath: desktopURL.path) {
                throw NSError(domain: "无写入权限", code: 403)
            }
            
            // 3. 创建唯一文件名
            let timestamp = Int(Date().timeIntervalSince1970)
            let imageURL = desktopURL.appendingPathComponent("screenshot_\(timestamp).png")
            
            // 4. 使用安全写入方式
            let imageRep = NSBitmapImageRep(cgImage: image)
            guard let pngData = imageRep.representation(using: .png, properties: [:]) else {
                throw NSError(domain: "图片转换失败", code: 500)
            }
            
            // 5. 实际写入操作
            try pngData.write(to: imageURL, options: [.atomic, .completeFileProtection])
            
            await MainActor.run {
                statusMessage = "截图已保存到: \(imageURL.lastPathComponent)"
                isCapturing = false
            }
            
        } catch {
            await handleSaveError(error)
        }
    }

//    @MainActor
//    private func saveImageToDesktop(_ image: CGImage) async {
//        do {
//            let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
//            let timestamp = Int(Date().timeIntervalSince1970)
//            let imageURL = desktopURL.appendingPathComponent("screenshot_\(timestamp).png")
//            
//            print("💾 保存截图到: \(imageURL.path)")
//            
//            let imageRep = NSBitmapImageRep(cgImage: image)
//            let pngData = imageRep.representation(using: .png, properties: [:])!
//            
//            try pngData.write(to: imageURL)
//            
//            print("✅ 截图保存成功")
//            statusMessage = "截屏成功！已保存到桌面"
//            isCapturing = false
//            
//            // 发送通知
//            if permissionManager.hasNotificationPermission {
//                print("📬 发送成功通知")
//                sendNotification(message: "截屏已保存到桌面")
//            } else {
//                print("⚠️  跳过通知发送，权限不足")
//            }
//            
//        } catch {
//            print("❌ 保存截图失败: \(error.localizedDescription)")
//            statusMessage = "保存失败: \(error.localizedDescription)"
//            isCapturing = false
//        }
//    }
    
    private func sendNotification(message: String) {
        print("📬 准备发送通知: \(message)")
        let content = UNMutableNotificationContent()
        content.title = "截屏完成"
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 通知发送失败: \(error.localizedDescription)")
            } else {
                print("✅ 通知发送成功")
            }
        }
    }
}
