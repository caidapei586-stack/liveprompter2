import Foundation
import Combine
import AVFoundation
import UIKit

/// 提词引擎：把台词拆词、维护当前读到第几个词、驱动 PiP 渲染与语音跟读。
final class PrompterEngine: ObservableObject {
    @Published var loadedScript: Script?
    @Published var words: [String] = []
    @Published var currentWordIndex: Int = 0
    @Published var isRunning = false
    @Published var isPiPActive = false
    @Published var recognizedText = ""

    let speech = SpeechFollower()
    let pip = PiPManager()
    private var displayTimer: Timer?

    var settings: AppSettings { AppSettings.shared }

    func load(_ script: Script) {
        loadedScript = script
        let text = script.content
        words = text.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        currentWordIndex = 0
        speech.prepare(script: text)
    }

    func start() {
        guard !words.isEmpty else { return }
        isRunning = true
        speech.start { [weak self] idx in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.currentWordIndex = idx
                self.recognizedText = self.speech.recognizedText
            }
        }
        pip.startPiP()
        startDisplayLoop()
    }

    func stop() {
        isRunning = false
        speech.stop()
        displayTimer?.invalidate()
        displayTimer = nil
        pip.stopPiP()
    }

    private func startDisplayLoop() {
        displayTimer?.invalidate()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1 / 30, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.pip.enqueueFrame { [weak self] ctx, size in
                guard let self = self,
                      let img = self.renderImage(size).cgImage else { return }
                // 像素缓冲是 y 轴向上，绘制图片前做一次垂直翻转使其正向
                ctx.saveGState()
                ctx.translateBy(x: 0, y: size.height)
                ctx.scaleBy(x: 1, y: -1)
                ctx.draw(img, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
                ctx.restoreGState()
            }
        }
    }

    /// 把当前提词画面渲染成 UIImage（屏幕预览与 PiP 共用同一套绘制逻辑）。
    func renderImage(_ size: CGSize) -> UIImage {
        let s = settings
        let fontSize = CGFloat(s.fontSize)
        let lineHeight = fontSize * 1.4
        let centerY = size.height * 0.5
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor(hex: s.bgColorHex).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            guard !words.isEmpty else { return }
            let visible = Int(size.height / lineHeight) + 2
            let start = max(0, currentWordIndex - visible)
            let end = min(words.count, currentWordIndex + visible)

            for i in start..<end {
                let y = centerY + CGFloat(i - currentWordIndex) * lineHeight
                let isCur = (i == currentWordIndex)
                let font = isCur
                    ? UIFont.boldSystemFont(ofSize: fontSize * 1.1)
                    : UIFont.systemFont(ofSize: fontSize)
                let color = isCur
                    ? UIColor(hex: s.highlightColorHex)
                    : UIColor(hex: s.textColorHex)
                let attr: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraph
                ]
                let ns = (words[i] + " ") as NSString
                let w = ns.size(withAttributes: attr).width
                ns.draw(at: CGPoint(x: (size.width - w) / 2, y: y), withAttributes: attr)
            }
        }
    }
}
