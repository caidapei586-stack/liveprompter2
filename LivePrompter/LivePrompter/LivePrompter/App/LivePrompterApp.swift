import SwiftUI

@main
struct LivePrompterApp: App {
    @StateObject private var scriptStore = ScriptStore()
    @StateObject private var settings = AppSettings.shared
    @StateObject private var audio = AudioSourceManager()
    @StateObject private var engine = PrompterEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(scriptStore)
                .environmentObject(settings)
                .environmentObject(audio)
                .environmentObject(engine)
                .onAppear {
                    engine.speech.requestAuthorization()
                }
        }
    }
}
