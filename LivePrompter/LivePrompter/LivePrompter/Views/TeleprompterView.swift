import SwiftUI
import AVKit
import AVFoundation

/// 提词主界面：屏幕内预览 + 启动 PiP 悬浮窗 + 语音跟读控制。
struct TeleprompterView: View {
    @EnvironmentObject var engine: PrompterEngine
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if let script = engine.loadedScript {
                    Text(script.title).font(.headline)

                    // 屏幕内预览（与 PiP 共用同一套绘制逻辑）
                    TimelineView(.animation) { _ in
                        Canvas { context, size in
                            let img = engine.renderImage(size)
                            context.draw(Image(uiImage: img),
                                         in: CGRect(origin: .zero, size: size))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .cornerRadius(12)

                    // PiP 的显示层必须挂在某个视图层级里（即使不可见），否则无法启动画中画
                    PiPHostView(layer: engine.pip.displayLayer)
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                } else {
                    Text("请先在「台词」中选择或生成一段台词")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                HStack(spacing: 12) {
                    Button(engine.isRunning ? "停止" : "开始提词") {
                        if engine.isRunning {
                            engine.stop()
                        } else {
                            guard engine.loadedScript != nil else { return }
                            engine.speech.requestAuthorization()
                            engine.start()
                        }
                    }
                    .disabled(engine.loadedScript == nil)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(engine.isRunning ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    Button(engine.isPiPActive ? "关闭悬浮窗" : "悬浮窗(PiP)") {
                        if engine.isPiPActive { engine.pip.stopPiP() }
                        else { engine.pip.startPiP() }
                    }
                    .disabled(!engine.pip.isPiPAvailable)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                if engine.isRunning {
                    Text("识别中：\(engine.recognizedText)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .padding(.horizontal)
                }

                VStack(alignment: .leading) {
                    Slider(value: $settings.fontSize, in: 24...80) { Text("字号") }
                    Text("字号：\(Int(settings.fontSize))")
                        .font(.caption).foregroundColor(.gray)
                }
            }
            .padding()
            .navigationTitle("提词")
        }
    }
}

/// 把 PiP 的 AVSampleBufferDisplayLayer 挂到视图层级中。
struct PiPHostView: UIViewRepresentable {
    let layer: AVSampleBufferDisplayLayer

    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.addSublayer(layer)
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        layer.frame = uiView.bounds
    }
}
