# 🎞 Silde Film Viewer

> A Digital Light Table Powered by Mac XDR Display

Silde Film Viewer 是一个 macOS 上的胶片观片辅助工具，充分利用 Apple XDR/HDR 屏幕的高亮度特性，模拟专业观片灯箱，为胶片摄影师和翻拍爱好者提供便捷、精准的底片观片体验。

---

## 🌟 功能特性 / Features

### ✅ 中文
- 💡 **HDR 高亮模式**：激发 XDR 屏幕峰值亮度（最高可达 1600nit）
- 🖤 **纯黑背景 + 白色高亮区域**，聚焦视觉避免杂光干扰
- 🎞 **支持“135 / 120”胶片画幅切换**，适应不同底片尺寸
- 🔍 **高亮区域支持位置移动、缩放调节**（方向键控制，或 ⌘+/− 快捷键）
- 🚫 **边界限制**：防止亮区超出屏幕可见区域
- 🎛 **简洁 UI 适配翻拍流程**，配合数码相机使用时特别方便

### ✅ English
- 💡 **HDR Highlight Mode**: Activates Mac XDR screen’s peak brightness (up to 1600 nits)
- 🖤 **Full black background with adjustable white highlight region**
- 🎞 **Supports film aspect ratios like 135 (3:2) and 120 (6x9)**
- 🎛 **Movable and scalable highlight window** (arrow keys, ⌘+/−)
- 🚧 **Screen edge clamping** to avoid highlight area overflow
- 📸 **Great for film scanning** when paired with a camera setup

---

## 🖥️ 使用方式 / How to Use

### 1. 安装与启动
- 使用 Xcode 编译并运行项目
- 或将构建产物（`.app`）拷贝到 `/Applications` 直接运行

### 2. 操作方式
- 使用 **方向键** 控制高亮区域位置
- 使用 **⌘ + / ⌘ -** 或界面右侧滑块缩放亮区
- 点击左侧按钮切换胶片画幅（135 / 120）

---

## 📸 使用场景 / Use Cases
- 胶片扫描前对位：利用亮区辅助摆放胶片
- 数码相机翻拍时作为高亮背景光源
- 简易观片灯：直接查看底片密度和画幅

---

## 📂 项目结构 / Project Structure
```
Silde Film Viewer
├── Silde_Film_ViewerApp.swift       # App 入口
├── ContentView.swift                # 主界面，处理 UI 与交互
├── MetalEDRView.swift               # Metal 渲染视图，处理 EDR 渲染
├── SimpleShader.metal               # Metal shader 文件，绘制亮区
├── Assets.xcassets/                 # 图标与资源文件
└── README.md                        # 项目说明文档（当前文件）
```

---

## 🔧 开发与环境 / Development
- macOS 13+
- Xcode 15+
- SwiftUI + Metal + Swift 5.9+

---

## 📦 安装构建 / Build Instructions
```bash
# 克隆项目
$ git clone https://github.com/yourname/SildeFilmViewer.git
$ cd SildeFilmViewer

# 使用 Xcode 打开工程并运行
$ open SildeFilmViewer.xcodeproj
```

---

## 📃 License
MIT License.

---

## 🙌 特别感谢 / Thanks
本项目受 Apple EDR 技术启发。参考 Apple 官方文档、社区项目与 XDR 测试工具。

---

Made with ❤️ for film photographers by [SimonWei].
