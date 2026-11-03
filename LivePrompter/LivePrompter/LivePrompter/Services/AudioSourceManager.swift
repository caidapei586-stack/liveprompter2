import AVFoundation
import Combine

/// 收音来源管理：列出可用输入（内置麦克风 / 外接领夹麦 / 声卡等），
/// 让用户在设置中选择，避免“识别不准”。
final class AudioSourceManager: ObservableObject {
    struct Input: Identifiable, Hashable {
        let id: String
        let name: String
    }

    @Published var inputs: [Input] = []
    @Published var selectedUID: String = ""

    func refresh() {
        let session = AVAudioSession.sharedInstance()
        inputs = (try? session.availableInputs ?? []).map {
            Input(id: $0.uid, name: $0.portName)
        } ?? []
    }

    func select(_ uid: String) {
        selectedUID = uid
        guard !uid.isEmpty else { return }
        let session = AVAudioSession.sharedInstance()
        guard let input = (try? session.availableInputs)?.first(where: { $0.uid == uid }) else { return }
        do {
            try session.setPreferredInput(input)
        } catch {
            print("设置收音来源失败: \(error)")
        }
    }
}
