import SwiftUI

struct AIGenerateView: View {
    @EnvironmentObject var store: ScriptStore
    @EnvironmentObject var settings: AppSettings
    @State private var topic = ""
    @State private var result = ""
    @State private var loading = false
    @State private var errorMsg: String?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("主题") {
                    TextField("例如：新款扫地机器人的卖点口播", text: $topic)
                }
                Button {
                    generate()
                } label: {
                    Text(loading ? "生成中…" : "AI 生成台词")
                }
                .disabled(topic.isEmpty || loading)

                if let errorMsg = errorMsg {
                    Text(errorMsg).foregroundColor(.red).font(.caption)
                }

                Section("生成结果（可编辑）") {
                    TextEditor(text: $result)
                        .frame(minHeight: 220)
                }
            }
            .navigationTitle("AI 提词")
            .toolbar {
                Button("保存并关闭") {
                    if !result.isEmpty {
                        store.add(Script(title: topic.isEmpty ? "AI 台词" : topic, content: result))
                    }
                    dismiss()
                }
            }
        }
    }

    private func generate() {
        loading = true
        errorMsg = nil
        let svc = AIScriptService(endpoint: settings.aiEndpoint,
                                  apiKey: settings.aiApiKey,
                                  model: settings.aiModel)
        svc.generate(topic: topic) { res in
            DispatchQueue.main.async {
                loading = false
                switch res {
                case .success(let text): result = text
                case .failure(let e): errorMsg = e.localizedDescription
                }
            }
        }
    }
}
