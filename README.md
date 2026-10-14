# 🎞 Silde Film Viewer

> A Digital Light Table Powered by Mac XDR Display

Silde Film Viewer 是一个 macOS 上的胶片观片辅助工具，充分利用 Apple XDR/HDR 屏幕的高亮度特性，模拟专业观片灯箱，为胶片摄影师和翻拍爱好者提供便捷、精准的底片观片体验。

---

## 🌟 功能特性 / Features

### ✅ 中文
- 💡 **HDR 高亮模式**：按所在屏幕的当前 EDR 余量输出高亮；不保证固定 nit
- 🖤 **纯黑背景 + 白色高亮区域**，聚焦视觉避免杂光干扰
- 🎞 **支持“135 / 120”胶片画幅切换**，适应不同底片尺寸
- 🔍 **高亮区域支持位置移动、缩放调节**（方向键控制，或 ⌘+/− 快捷键）
- 🚫 **边界限制**：防止亮区超出屏幕可见区域
- 🎛 **简洁 UI 适配翻拍流程**，配合数码相机使用时特别方便

### ✅ English
- 💡 **HDR Highlight Mode**: Adapts to the current display EDR headroom; no fixed luminance guarantee
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
- macOS 15+
- Xcode 16+
- SwiftUI + Metal + Swift 5.9+

---

## 📦 安装构建 / Build Instructions
```bash
# 克隆项目
$ git clone https://github.com/Simon040129/Silde-Film-Viewer.git
$ cd Silde-Film-Viewer

# 使用 Xcode 打开工程并运行
$ open "Silde Film Viewer.xcodeproj"
```

---

## 📃 License
MIT License.

---

## 🙌 特别感谢 / Thanks
本项目受 Apple EDR 技术启发。参考 Apple 官方文档、社区项目与 XDR 测试工具。

---

Made with ❤️ for film photographers by [SimonWei].

## 重构分支操作说明

先点击灯箱获取键盘焦点；方向键移动，Shift+方向键精细移动，⌘+/− 缩放，C 恢复到底部居中位置，H 隐藏/显示控制栏，Esc 退出窗口全屏。控件获得焦点时保留其原生键盘行为。系统亮度键由 macOS 处理，部分参考模式可能禁用。

大小表示相对画布的适配比例（10%–100%），不是毫米尺寸。135 与当前 120（6×9 横向）均为 3:2。铺满亮区与窗口全屏相互独立。RGB 微调使用共同倍率限制峰值，不能替代测量校准。

架构、官方依据、原始问题和验证边界见 [重构记录](docs/REFACTOR.md)。
