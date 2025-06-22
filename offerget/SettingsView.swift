import SwiftUI
import HotKey

struct SettingsView: View {
    @State private var selectedKey: Key = .four
    @State private var modifiers: NSEvent.ModifierFlags = [.command, .shift]
    
    let allKeys: [Key] = [
        .a, .b, .c, .d, .e, .f, .g, .h, .i, .j, .k, .l, .m,
        .n, .o, .p, .q, .r, .s, .t, .u, .v, .w, .x, .y, .z,
        .zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine,
        .f1, .f2, .f3, .f4, .f5, .f6, .f7, .f8, .f9, .f10, .f11, .f12
        // 你可以根据需要继续补充
    ]
    
    var body: some View {
        VStack {
            Text("设置快捷键")
                .font(.headline)
            
            Picker("快捷键:", selection: $selectedKey) {
                ForEach(allKeys, id: \.self) { key in
                    Text(key.description).tag(key)
                }
            }
            
            Toggle("Command", isOn: Binding(
                get: { modifiers.contains(.command) },
                set: { if $0 { modifiers.insert(.command) } else { modifiers.remove(.command) } }
            ))
            
            Toggle("Shift", isOn: Binding(
                get: { modifiers.contains(.shift) },
                set: { if $0 { modifiers.insert(.shift) } else { modifiers.remove(.shift) } }
            ))
            
            Toggle("Option", isOn: Binding(
                get: { modifiers.contains(.option) },
                set: { if $0 { modifiers.insert(.option) } else { modifiers.remove(.option) } }
            ))
            
            Toggle("Control", isOn: Binding(
                get: { modifiers.contains(.control) },
                set: { if $0 { modifiers.insert(.control) } else { modifiers.remove(.control) } }
            ))
            
            Button("保存设置") {
                HotKeyManager.shared.updateHotKey(key: selectedKey, modifiers: modifiers)
            }
        }
        .padding()
    }
}