import HotKey
import SwiftUI

class HotKeyManager: ObservableObject {
    static let shared = HotKeyManager()
    private var hotKey: HotKey?
    
    private init() {
        setupHotKey()
    }
    
    func setupHotKey() {
        // // 设置快捷键为 Command+Shift+6 (可自定义)
        // hotKey = HotKey(key: .six, modifiers: [.command, .shift])
        
        // hotKey?.keyDownHandler = {
        //     DispatchQueue.main.async {
        //         // 获取主窗口并触发截屏
        //         if let mainWindow = NSApp.windows.first,
        //            let contentView = mainWindow.contentView?.nextResponder as? ContentView {
        //             contentView.captureScreen()
        //         }
        //     }
        // }
    }
    
    func updateHotKey(key: Key, modifiers: NSEvent.ModifierFlags) {
        // hotKey = HotKey(key: key, modifiers: modifiers)
        // setupHotKey()
    }
}