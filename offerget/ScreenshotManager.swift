import Foundation
import ScreenCaptureKit
import AppKit

enum ScreenshotError: Error {
    case noDisplay
    case imageConversionFailed
    case saveFailed(String)
}

class ScreenshotManager {
    static func captureAndSaveToDesktop() async throws {
        let content = try await SCShareableContent.current
        guard let display = content.displays.first else {
            throw ScreenshotError.noDisplay
        }
        
        let config = SCStreamConfiguration()
        config.width = display.width
        config.height = display.height
        
        let image = try await SCScreenshotManager.captureImage(
            contentFilter: SCContentFilter(display: display, excludingWindows: []),
            configuration: config
        )
        
        guard let desktopURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            throw ScreenshotError.saveFailed("无法获取桌面路径")
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let filename = "screenshot_\(dateFormatter.string(from: Date())).png"
        let fileURL = desktopURL.appendingPathComponent(filename)
        
        let imageRep = NSBitmapImageRep(cgImage: image)
        guard let pngData = imageRep.representation(using: .png, properties: [:]) else {
            throw ScreenshotError.imageConversionFailed
        }
        
        do {
            try pngData.write(to: fileURL)
        } catch {
            throw ScreenshotError.saveFailed(error.localizedDescription)
        }
    }
} 