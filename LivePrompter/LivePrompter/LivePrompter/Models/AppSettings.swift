import Foundation
import Combine
import UIKit

/// 全局设置（字号、颜色、AI 接口、跟读开关等）
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var fontSize: Double {
        didSet { save() }
    }
    @Published var textColorHex: String {
        didSet { save() }
    }
    @Published var bgColorHex: String {
        didSet { save() }
    }
    @Published var highlightColorHex: String {
        didSet { save() }
    }
    /// 滚动速度倍率（0.5 ~ 3.0）
    @Published var scrollSpeed: Double {
        didSet { save() }
    }
    @Published var useSpeechFollow: Bool {
        didSet { save() }
    }
    @Published var aiEndpoint: String {
        didSet { save() }
    }
    @Published var aiApiKey: String {
        didSet { save() }
    }
    @Published var aiModel: String {
        didSet { save() }
    }

    private init() {
        let d = UserDefaults.standard
        fontSize = d.object(forKey: "fontSize") as? Double ?? 44
        textColorHex = d.string(forKey: "textColorHex") ?? "#FFFFFF"
        bgColorHex = d.string(forKey: "bgColorHex") ?? "#000000"
        highlightColorHex = d.string(forKey: "highlightColorHex") ?? "#FFD60A"
        scrollSpeed = d.object(forKey: "scrollSpeed") as? Double ?? 1.0
        useSpeechFollow = d.object(forKey: "useSpeechFollow") as? Bool ?? true
        aiEndpoint = d.string(forKey: "aiEndpoint") ?? "https://api.openai.com/v1/chat/completions"
        aiApiKey = d.string(forKey: "aiApiKey") ?? ""
        aiModel = d.string(forKey: "aiModel") ?? "gpt-4o-mini"
    }

    func save() {
        let d = UserDefaults.standard
        d.set(fontSize, forKey: "fontSize")
        d.set(textColorHex, forKey: "textColorHex")
        d.set(bgColorHex, forKey: "bgColorHex")
        d.set(highlightColorHex, forKey: "highlightColorHex")
        d.set(scrollSpeed, forKey: "scrollSpeed")
        d.set(useSpeechFollow, forKey: "useSpeechFollow")
        d.set(aiEndpoint, forKey: "aiEndpoint")
        d.set(aiApiKey, forKey: "aiApiKey")
        d.set(aiModel, forKey: "aiModel")
    }
}

extension UIColor {
    convenience init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

extension Color {
    init(hex: String) { self.init(UIColor(hex: hex)) }
}
