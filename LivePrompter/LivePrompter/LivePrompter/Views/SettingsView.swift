import SwiftUI
import AVFoundation
import Speech

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var audio: AudioSourceManager

    var body: some View {
        NavigationView {
            Form {
                Section("AI 提词") {
                    TextField("API 地址", text: $settings.aiEndpoint)
                    TextField("模型", text: $settings.aiModel)
                    SecureField("API Key", text: $settings.aiApiKey)
                    Text("兼容 OpenAI Chat Completions 协议的任意端点，例如通义/方舟等。").font(.caption).foregroundColor(.gray)
                }

                Section("语音智能跟读") {
                    Toggle("启用语音跟读", isOn: $settings.useSpeechFollow)
                    Button("请求麦克风 / 语音权限") {
                        AVAudioSession.sharedInstance()
                        // 触发系统授权弹窗
                        SFSpeechRecognizer.requestAuthorization { _ in }
                    }
                }

                Section("收音来源（外接领夹麦 / 声卡）") {
                    Button("刷新可用输入") { audio.refresh() }
                    Picker("选择输入", selection: $audio.selectedUID) {
                        Text("系统默认").tag("")
                        ForEach(audio.inputs) { inp in
                            Text(inp.name).tag(inp.id)
                        }
                    }
                    .onChange(of: audio.selectedUID) { _ in
                        audio.select(audio.selectedUID)
                    }
                    Text("若使用领夹麦或声卡收音，请在此选择对应输入，避免识别不准。").font(.caption).foregroundColor(.gray)
                }

                Section("外观") {
                    ColorField(label: "文字颜色", text: $settings.textColorHex)
                    ColorField(label: "背景颜色", text: $settings.bgColorHex)
                    ColorField(label: "高亮颜色", text: $settings.highlightColorHex)
                    Slider(value: $settings.fontSize, in: 24...80) { Text("字号") }
                    Slider(value: $settings.scrollSpeed, in: 0.5...3) { Text("滚动速度") }
                }
            }
            .navigationTitle("设置")
            .onAppear { audio.refresh() }
        }
    }
}

struct ColorField: View {
    let label: String
    @Binding var text: String
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("#FFFFFF", text: $text).multilineTextAlignment(.trailing)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: text))
                .frame(width: 24, height: 24)
        }
    }
}
