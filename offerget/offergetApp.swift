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
                    AppDelegate.shared().captureScreen()
                }.keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }
    }
}
