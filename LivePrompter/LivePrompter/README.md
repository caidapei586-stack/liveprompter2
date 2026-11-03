# LivePrompter — iOS 直播 AI 提词悬浮窗

一款面向 iPhone 的直播提词 App：
- **悬浮提词**：通过 iOS 画中画（PiP）把提词画面浮在直播间页面之上；
- **AI 提词**：调用兼容 OpenAI 协议的接口，按主题一键生成口播台词；
- **AI 语音智能跟读**：实时识别你的语速，台词随说随滚，停顿 / 放慢实时匹配；
- **外接设备适配**：在设置里选择收音来源（领夹麦 / 声卡），避免识别不准。

---

## ⚠️ 先了解 iOS 的平台限制（重要）

1. **没有“真正的悬浮窗”**。iOS 不允许第三方 App 在别的 App 之上画任意窗口。合规做法就是
   **画中画（PiP）**——把提词内容当成一段“视频”喂给系统 PiP，从而浮在任意界面上。本 App 正是这么做的。
2. **语音跟读在切到直播 App 后可能停止**。iOS 会把后台 App 挂起，`SFSpeechRecognizer` 一般随之停止。
   已开启 `UIBackgroundModes: audio` 做最大努力保活；在屏幕内预览时跟读完全正常，
   悬浮(PiP)状态下若停止更新属于平台限制（可后续用“预渲染整段视频 + 按词 seek”方案规避，见文末）。
3. **必须在真机运行**。PiP 与麦克风在模拟器上不可用，需要一台 iPhone + Mac + Xcode。
4. **App Store 审核风险**。纯 PiP 提词类应用存在被拒可能，个人使用 / TestFlight / 企业分发更安全。

---

## 环境要求

- macOS + Xcode 15 及以上
- 一台 iPhone（iOS 15+）
- Apple 开发者账号（免费账号可用 Xcode 真机调试，证书 7 天有效）
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)（用于生成 `.xcodeproj`）

## 构建与运行

```bash
# 1. 安装 XcodeGen
brew install xcodegen

# 2. 在项目根目录生成 Xcode 工程
cd LivePrompter
xcodegen generate

# 3. 打开工程，真机运行
open LivePrompter.xcodeproj
```

在 Xcode 中：
- 选 **LivePrompter** target → **Signing & Capabilities** → 选你的 Team；
- 把 `project.yml` 里的 `DEVELOPMENT_TEAM` 填上你的 Team ID（可选，Xcode 里设也行）；
- 用数据线连上 iPhone，运行即可。

## 使用流程

1. 「台词」页：点右上角 ✨ 用 **AI 生成**，或点 ➕ 手动编辑；
2. 点某段台词将其载入提词器；
3. 「提词」页：点 **开始提词**（首次会弹麦克风 / 语音识别授权），
   再点 **悬浮窗(PiP)**，画面会缩小成浮窗；
4. 切到直播 App，浮窗停在屏幕上；开口说话，台词会随语速滚动；
5. 「设置」页：调整字号 / 颜色、配置 AI 接口、选择**收音来源**（领夹麦 / 声卡）。

## 目录结构

```
LivePrompter/
├── project.yml                  # XcodeGen 工程描述
└── LivePrompter/
    ├── App/
    │   ├── LivePrompterApp.swift
    │   └── ContentView.swift
    ├── Models/
    │   ├── Script.swift
    │   ├── ScriptStore.swift     # 台词本地持久化
    │   └── AppSettings.swift     # 设置 + 颜色解析
    ├── Services/
    │   ├── PiPManager.swift      # 画中画：把提词渲染成视频帧
    │   ├── SpeechFollower.swift  # 语音识别跟读
    │   ├── AudioSourceManager.swift # 收音来源选择
    │   ├── AIScriptService.swift # AI 生成台词
    │   └── PrompterEngine.swift  # 引擎：拆词 / 滚动 / 渲染
    └── Views/
        ├── ScriptListView.swift
        ├── ScriptEditorView.swift
        ├── AIGenerateView.swift
        ├── TeleprompterView.swift
        └── SettingsView.swift
```

## 后续可增强

- **预渲染整段视频 + 按词 seek**：把整段提词先渲染成一段视频，跟读时通过 `player.seek`
  定位到当前词，并用 `rate` 控制快慢——可彻底摆脱后台语音识别限制，悬浮状态下也能稳定跟读；
- **手动滚动 / 调速按钮**：无语音时也能控制；
- **多语言 / 方言识别**：在 `SpeechFollower` 里切换 `Locale`；
- **云端同步台词**：接入云存储，多设备共享。
