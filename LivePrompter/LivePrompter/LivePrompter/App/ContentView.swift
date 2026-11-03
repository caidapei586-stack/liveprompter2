import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ScriptListView()
                .tabItem { Label("台词", systemImage: "doc.text") }
            TeleprompterView()
                .tabItem { Label("提词", systemImage: "speaker.wave.2") }
            SettingsView()
                .tabItem { Label("设置", systemImage: "gear") }
        }
    }
}
