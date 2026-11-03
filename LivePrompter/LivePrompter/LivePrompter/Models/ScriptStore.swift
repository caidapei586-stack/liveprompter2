import Foundation
import Combine

/// 台词持久化（本地 JSON 文件，存放在 App Documents 目录）
final class ScriptStore: ObservableObject {
    @Published var scripts: [Script] = []
    private let fileURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = docs.appendingPathComponent("scripts.json")
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let arr = try? JSONDecoder().decode([Script].self, from: data) else { return }
        scripts = arr
    }

    func save() {
        if let data = try? JSONEncoder().encode(scripts) {
            try? data.write(to: fileURL)
        }
    }

    func add(_ s: Script) { scripts.append(s); save() }

    func update(_ s: Script) {
        if let i = scripts.firstIndex(where: { $0.id == s.id }) {
            scripts[i] = s; save()
        }
    }

    func delete(_ s: Script) {
        scripts.removeAll { $0.id == s.id }; save()
    }
}
