import SwiftUI

@main
struct OfferGetApp: App {
    // 注入AppDelegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate) // 共享给视图
        }
        .commands {
            // 添加菜单栏命令
            CommandGroup(replacing: .newItem) {
                Button("截屏") {
                    // 直接使用注入的 appDelegate 实例，这是最可靠的方式
                    appDelegate.captureScreen()
                }.keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }
    }
}
