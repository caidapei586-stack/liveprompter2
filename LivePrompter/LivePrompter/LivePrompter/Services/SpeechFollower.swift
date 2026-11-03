import Speech
import AVFoundation
import Combine

/// 语音智能跟读：实时识别你说出的内容，与台词逐词匹配，
/// 计算出当前读到了第几个词，驱动提词滚动。
///
/// 注意：iOS 在 App 进入后台（切到直播 App）时通常会挂起语音识别，
/// 因此跟读在悬浮(PiP)状态下可能停止更新——这是平台限制，已在 Info.plist
/// 开启 UIBackgroundModes: audio 做最大努力保活。
final class SpeechFollower: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var isRunning = false
    @Published var recognizedText = ""

    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var scriptLower: [String] = []
    private var currentIndex = 0

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async { self?.isAuthorized = (status == .authorized) }
        }
    }

    func prepare(script: String) {
        scriptLower = script
            .split(whereSeparator: { $0.isWhitespace })
            .map { $0.lowercased() }
        currentIndex = 0
    }

    /// 开始识别；onProgress 回传当前匹配到的词下标。
    func start(onProgress: @escaping (Int) -> Void) {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord,
                                    options: [.mixWithOthers, .allowBluetooth, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("音频会话配置失败: \(error)")
        }

        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN")),
              recognizer.isAvailable else { return }

        request = SFSpeechAudioBufferRecognitionRequest()
        request?.shouldReportPartialResults = true

        let input = audioEngine.inputNode
        let fmt = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: fmt) { [weak self] buf, _ in
            self?.request?.append(buf)
        }
        audioEngine.prepare()
        try? audioEngine.start()

        task = recognizer.recognitionTask(with: request!) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async { self.recognizedText = text }
                self.advance(to: text)
                onProgress(self.currentIndex)
            }
            if error != nil {
                self.stop()
            }
        }
        isRunning = true
    }

    /// 用最近若干词做滑动窗口匹配，定位在台词中的位置。
    private func advance(to transcript: String) {
        let words = transcript
            .lowercased()
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
        guard !words.isEmpty, !scriptLower.isEmpty else { return }

        let window = Array(words.suffix(min(4, words.count)))
        guard window.count <= scriptLower.count else { return }

        var best = currentIndex
        for i in 0...(scriptLower.count - window.count) {
            if scriptLower[i..<i + window.count].elementsEqual(window) {
                best = i + window.count
            }
        }
        currentIndex = best
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        isRunning = false
    }
}
