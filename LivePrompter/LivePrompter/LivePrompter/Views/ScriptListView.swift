import SwiftUI

struct ScriptListView: View {
    @EnvironmentObject var store: ScriptStore
    @EnvironmentObject var engine: PrompterEngine
    @State private var showingEditor = false
    @State private var editing: Script?
    @State private var showingAI = false

    var body: some View {
        NavigationView {
            List {
                ForEach(store.scripts) { s in
                    Button {
                        engine.load(s)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(s.title).font(.headline)
                            Text(s.content.prefix(40))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                    .contextMenu {
                        Button("编辑") { editing = s; showingEditor = true }
                        Button("删除", role: .destructive) { store.delete(s) }
                    }
                }
            }
            .navigationTitle("我的台词")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { editing = Script(); showingEditor = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showingAI = true } label: {
                        Image(systemName: "sparkles")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                if let s = editing { ScriptEditorView(script: s) }
            }
            .sheet(isPresented: $showingAI) { AIGenerateView() }
        }
    }
}
