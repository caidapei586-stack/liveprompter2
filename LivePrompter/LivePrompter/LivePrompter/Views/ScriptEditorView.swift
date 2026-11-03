import SwiftUI

struct ScriptEditorView: View {
    @EnvironmentObject var store: ScriptStore
    @State var script: Script
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                TextField("标题", text: $script.title)
                Section("正文") {
                    TextEditor(text: $script.content)
                        .frame(minHeight: 220)
                }
            }
            .navigationTitle("编辑台词")
            .toolbar {
                Button("保存") {
                    script.updatedAt = Date()
                    if store.scripts.contains(where: { $0.id == script.id }) {
                        store.update(script)
                    } else {
                        store.add(script)
                    }
                    dismiss()
                }
            }
        }
    }
}
