# Silde Film Viewer

A digital film light table for macOS, built with SwiftUI, AppKit and Metal.

Silde Film Viewer 将 Mac 显示器用作胶片观片与翻拍辅助灯箱：黑色背景上显示可移动、可缩放的高亮区域，并根据所在显示器的当前 EDR（扩展动态范围）余量调整输出。它不导入或浏览图片文件，也不能替代经过测量校准的专业光源。

## 下载与安装

[下载 1.1.1](https://github.com/Simon040129/Silde-Film-Viewer/releases/tag/v1.1.1) · [所有版本](https://github.com/Simon040129/Silde-Film-Viewer/releases)

- 系统要求：macOS 15 或更新，支持 Metal 的 Mac。
- `universal.zip` 包含 Apple Silicon 与 Intel 可执行代码。EDR 高亮效果还取决于显示器与系统设置；普通 SDR 显示器不能获得相同的高亮范围。
- 下载并解压，将 `Silde Film Viewer.app` 拖入“应用程序”文件夹后打开。更新前退出旧版，按需保留备份。
- 发布页附有 `SHA256SUMS.txt`，可在下载目录运行 `shasum -a 256 -c SHA256SUMS.txt` 校验安装包。

当前发布包使用 ad-hoc 签名，**没有 Developer ID 签名或 Apple 公证**。如果 macOS 阻止打开，请在确认下载来源后按系统“隐私与安全性”提示处理，或从源码构建；无需关闭系统安全保护。

`main` 保存当前维护中的源码，可能包含发布后的文档或整理提交。需要精确复现安装包版本时，请使用相应版本标签。

## 功能与操作

- 黑色背景，亮区默认水平居中并紧贴画布底边。窗口模式以画布底边为准，窗口全屏后以全屏画布底边为准。
- 顶部控制栏可选择画幅、调整大小与 EDR 倍率、恢复位置，以及展开 RGB 微调。
- 隐藏控制栏后仍保留“显示控制栏”按钮；控制栏采用不透光深色背景，方便在高亮画布上阅读。
- “窗口全屏”控制 macOS 窗口状态；“铺满亮区”让光源覆盖整个画布，两者可以独立切换。铺满时大小调节和位置移动不生效，退出铺满后恢复原有亮区设置。

先点击灯箱区域取得键盘焦点，再使用以下快捷键。滑块等控件获得焦点时，保留其原生键盘行为。

| 操作 | 快捷键或控件 |
| --- | --- |
| 移动亮区 | 方向键，每次 10 个逻辑点 |
| 精细移动 | Shift + 方向键，每次 1 个逻辑点 |
| 缩放亮区 | ⌘+ / ⌘−（⌘= 也可放大），或“大小”滑块 |
| 恢复默认底部居中位置 | C，或“恢复位置”按钮 |
| 隐藏／显示控制栏 | H，或界面上的隐藏／显示按钮 |
| 退出窗口全屏 | Esc；非全屏时 Esc 会显示控制栏 |
| 调整系统屏幕亮度 | macOS 系统亮度键；部分参考模式可能禁用 |

亮区大小为画布内最大适配尺寸的 **10%–100%**，不是屏幕上的实际毫米尺寸。未手动移动时，调整大小或窗口尺寸仍保持贴底；“恢复位置”会重新启用这一默认定位。

当前预设是 **135（3:2）**和 **120（6×9 横向，也是 3:2）**，因此两者目前显示相同的比例。120 的其他画幅尚未实现，选择预设不会自动把屏幕标定为胶片实物尺寸。

## EDR、亮度与白平衡

状态栏显示所在屏幕的当前 EDR 余量，**它是相对倍率，不是 nit 测量**。“EDR 倍率”表示请求的输出强度，实际输出会按可用余量限制；应用不保证达到 1600 nit，也不保证大面积亮区能维持峰值亮度。

RGB 微调用共同倍率限制最高通道，以保留通道比例；“中性白”将三个权重恢复为 1。RGB 调节不等于显示器或翻拍系统的色彩校准。需要稳定翻拍结果时，应固定显示设置及相机白平衡，并按需要使用测量工具验证。

持续亮度、白点／光谱、不同显示器与跨屏行为仍需真机验证。实现依据与已知限制见 [重构记录](docs/REFACTOR.md)。

## 从源码构建与测试

使用 Xcode 16 或更新版本。工程部署目标为 macOS 15，Swift 语言模式为 5；使用 SwiftUI、AppKit、MetalKit，无第三方包依赖。

```bash
git clone https://github.com/Simon040129/Silde-Film-Viewer.git
cd Silde-Film-Viewer
open "Silde Film Viewer.xcodeproj"
```

在 Xcode 中选择 `Silde Film Viewer` scheme 和 My Mac 后运行。若要检查已发布的 1.1.1 源码，可先执行 `git switch --detach v1.1.1`；日常开发请从 `main` 创建功能分支。

命令行构建与现有单元测试：

```bash
xcodebuild -project "Silde Film Viewer.xcodeproj" \
  -scheme "Silde Film Viewer" -configuration Release \
  -derivedDataPath /tmp/SildeFilmViewer-build \
  CODE_SIGNING_ALLOWED=NO build

xcodebuild -project "Silde Film Viewer.xcodeproj" \
  -scheme "Silde Film Viewer" -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath /tmp/SildeFilmViewer-tests \
  -only-testing:'Silde Film ViewerTests' \
  ENABLE_TESTABILITY=YES CODE_SIGNING_ALLOWED=NO test
```

上述命令用于本地编译验证，不生成经过 Apple 公证的分发包。Release 单元测试使用 `@testable` 导入，因此需要 `ENABLE_TESTABILITY=YES`；正式分发归档不使用此开关。

现有 6 项单元测试覆盖亮区默认定位、缩放与窗口尺寸变化、位置恢复、边界、零尺寸／铺满及 EDR 颜色计算。UI 测试目录目前主要是启动模板，不能作为完整交互验证。实际亮度、白平衡、键盘焦点和跨屏效果需要手动测试。

## 项目结构

```text
Silde-Film-Viewer/
├── Silde Film Viewer.xcodeproj/     # Xcode 工程
├── Silde Film Viewer/
│   ├── Silde_Film_ViewerApp.swift   # SildeFilmViewerApp 入口
│   ├── ContentView.swift           # SwiftUI 控制栏与交互界面
│   ├── ViewerState.swift           # 窗口状态、亮区几何与颜色计算
│   ├── MetalEDRView.swift          # AppKit 生命周期、焦点与 Metal 渲染
│   ├── SimpleShader.metal         # 亮区着色器
│   └── Assets.xcassets/            # 正式图标与界面资源
├── Silde Film ViewerTests/         # 单元测试
├── Silde Film ViewerUITests/       # UI 测试模板
├── design/                        # 图标源图、提示词、候选稿与旧素材
├── docs/                          # 重构历史与版本说明
└── .github/workflows/release.yml   # 标签触发的测试、打包与发布
```

当前正式图标源图为 `design/app-icon-fullbleed-v3.png`，采用不透明方形背景，由系统处理最终外形。历史候选与旧图标保留在 `design/`。

## 开发与发布约定

- 在功能分支修改，通过 PR 合并到 `main`，保留可追溯的提交历史。
- `.DS_Store`、`xcuserdata`、编译缓存、归档与测试结果不纳入源码管理；共享工程配置、图标源文件与版本说明需要提交。
- 将构建产物放在项目目录外。若项目位于 OneDrive，避免多台设备同时修改同一份工作区；Git 负责代码版本，OneDrive 负责文件同步。
- 发布前更新工程版本号和构建号，新增 `docs/RELEASE-<版本>.md`，完成验证后创建并推送对应的 `v<版本>` 标签。
- 现有工作流仅在推送 `v*` 标签时运行：先测试，再构建通用归档、添加 ad-hoc 签名，上传 ZIP 和 SHA256 校验文件并发布 Release。普通提交或 PR 合并不会自动发布，也不会自动触发这套测试流程。
- 已发布的版本标签和安装包保持不变；修复通过新版本发布。

版本说明：[1.1.1](docs/RELEASE-1.1.1.md) · [1.1.0](docs/RELEASE-1.1.0.md)

## License

[MIT License](LICENSE)
