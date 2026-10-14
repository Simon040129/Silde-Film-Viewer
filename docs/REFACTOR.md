# EDR 重构记录（2026-10-14）

## 基线与回退

用户确认以 GitHub main `4f610e9` 为基线。独立副本使用 `feature/edr-refactor`；本地标签 `baseline/main-before-edr-refactor-20261014` 保留原版。未修改 OneDrive 原项目、远程分支或 main。

OneDrive 项目当前为 `feature/fullscreen-rgb-backlight` 的 `d4a4fd4`，工作区干净；其本地 `feature/edr-dark-background` 为 `fc5cce5`，比远程多一个提交，原样保留。

## 审查发现

- `MetalEDRView.swift`：中心写死为 (1550,450)，位置和尺寸以 drawable 像素计算，无法维持跨 Retina 缩放一致的逻辑尺寸；NDC 尺寸少乘 2；resize 回调为空；没有真正的边界约束。
- 135 实际矩形为 900:300，120 为 900:550，保存的 aspect 从未使用。此次依 README 将 135 设为 3:2、120 设为 6×9 横向（也是 3:2）；二者只是画幅预设，不代表屏幕上的毫米尺寸。120 还包括其他画幅，待产品确认后扩展。
- 全应用 local event monitor 不区分窗口/控件焦点且处理后仍返回事件；按钮上限 15、键盘上限 5。
- shader 固定 RGB=10，未查询 headroom。RGB 分支最高会到 20，通道裁剪会影响色相。
- RGB 分支的“全屏”实际是铺满 Metal 画布，不是 macOS 窗口全屏。
- AppIcon Contents.json 含未解决的 Git 冲突，涉及两套正式图标。未选择或更换任何一套；保留原文件并记录构建警告。
- README 系统要求与工程不符；工程使用 macOS 15 / Xcode 16；单元测试原本只有空模板。

## API 比较与架构选择

| 技术 | 适合本项目的职责 | 限制/决定 |
|---|---|---|
| SwiftUI | UI、绑定、可访问性、布局 | 已有 HDR Image/allowedDynamicRange 能力，不能简单宣称 SwiftUI 不支持 HDR；但不据此假定普通白色 Shape 等价于可控 EDR 光源。新 API 必须核对可用系统/SDK。 |
| AppKit | 所在窗口、屏幕、first responder、窗口全屏、屏幕变化 | 输入只在灯箱获得焦点后生效，不截获系统亮度键。 |
| Core Image | HDR 图片处理、滤镜、色彩转换，输出到 Metal | 当前只需均匀矩形，加入 CIContext/滤镜链没有收益，留作未来图像功能。 |
| MetalKit / CAMetalLayer | 确定的线性浮点光源、黑背景、按需绘制 | 保留 rgba16Float、extendedLinearDisplayP3、wantsExtendedDynamicRangeContent。 |

`ViewerState` 保存每个窗口的状态；`LightGeometry` 负责可测试的几何和 RGB/headroom 计算；`LightTableView` 负责 AppKit 生命周期和 Metal 提交；`ContentView` 只负责控件。逻辑点直接与 bounds 归一化成 NDC，drawable 像素由 MTKView 管理，不把屏幕点与像素混用。

当前 headroom 用 `maximumExtendedDynamicRangeColorComponentValue`，潜在最大值不能当作当前余量；reference 值仅对参考渲染有意义，可能为 0。通过窗口屏幕、backing、尺寸、全屏和应用屏幕参数通知刷新。RGB 用共同倍率限制最大通道，保留比例。保留按需绘制，避免持续空转。

## 亮度与白平衡

EDR 1.0 是相对 SDR 白，不是固定 nit。具体 XDR 机型的 1600 nit HDR 峰值与 1000 nit 全屏持续规格不能推广到所有屏幕，也不能由 shader=10 保证；亮区面积、温度、设置、供电等需要真机测量。

等值线性 P3 RGB 是所选空间的中性白，不保证透过胶片后的摄影色准或光谱表现。RGB 调整不是色度计校准。翻拍时固定显示预设、关闭影响白点的自动调整并固定相机白平衡，再使用测量工具验证；本应用不擅改系统设置。参考模式可能禁用系统亮度键，这是系统模式限制，不应绕过。

## 阶段与设计方向

1. P0：修几何、边界、焦点作用域、EDR 余量、错误处理，加入纯计算测试。
2. P1：紧凑深色控制栏、画幅/大小/居中、窗口全屏与铺满亮区独立、可隐藏 UI、RGB 折叠面板；保持黑底。
3. P2：真机跨屏、缩放、持续亮度/白点、VoiceOver 与完整键盘回归；确认 120 子画幅及历史缩放手感；图标方案另行审批。

图标方向：现有胶片/灯箱意象，简洁的单张胶片框与亮窗，避免细小齿孔和文字在 16px 下消失。依当前 Apple 模板评估新式分层图标及旧系统 asset catalog，分别验证小尺寸、深色/单色表现。正式图标未改。

## 官方依据

- https://developer.apple.com/videos/play/wwdc2022/10114/ — Core Image、Metal、SwiftUI EDR 协作。
- https://developer.apple.com/documentation/metal/performing-your-own-tone-mapping — 浮点格式、扩展线性色彩空间、EDR layer。
- https://developer.apple.com/documentation/swiftui/view/alloweddynamicrange(_:) — SwiftUI HDR 控制。
- https://developer.apple.com/documentation/appkit/nsscreen/maximumextendeddynamicrangecolorcomponentvalue — 当前余量及屏幕参数通知。
- https://developer.apple.com/documentation/appkit/nsscreen/maximumreferenceextendeddynamicrangecolorcomponentvalue — 参考范围及显示器 tone mapping。
- https://developer.apple.com/documentation/appkit/nsview/converttobacking(_:)-4ra9y — 点与 backing 像素转换。
- https://support.apple.com/en-us/111838 — 具体 MacBook Pro 的峰值/持续亮度规格。
- https://support.apple.com/en-nz/108321 — 参考模式对亮度键等设置的限制。
- https://developer.apple.com/design/human-interface-guidelines/designing-for-macos/ — 窗口、输入、菜单。
- https://developer.apple.com/icon-composer/ — 当前图标制作工具；本机 Xcode 16 尚未采用该工具链。

## 验证边界

本机 Xcode 16.0 / macOS SDK 15.0；联网核验了当前文档，但不能声称已在最新 SDK 编译。原版 Debug 构建通过，有 AppIcon JSON 警告。没有测量实际 nit、白点、光谱或跨显示器真实表现，不能通过编译代替这些测试。

本次重构验证结果：
- Debug `xcodebuild build`：通过；保留既有 AppIcon 无效 JSON 警告。
- `xcodebuild test -only-testing:'Silde Film ViewerTests'`：4 项全部通过（居中/比例、边界/超限缩放、零尺寸/铺满、headroom/RGB 比例）。
- `git diff --check`：通过。
- 未运行 UI 自动化；未验证跨屏实机、长时亮度、系统键、VoiceOver。原 UI 测试为启动模板，不能当作交互验证。

实际修改文件：README.md、ContentView.swift、MetalEDRView.swift、SimpleShader.metal、单元测试；新增 ViewerState.swift 和本记录。旧 MetalViewRepresentable.swift 是未使用的历史实现，保留以避免无关删除。工程配置和正式图标资源均未修改。

## 本机试用修复：默认贴底与控制栏恢复

默认亮区改为水平居中、紧贴画布底边；未手动移动时，缩放或调整窗口仍保持贴底。窗口模式以画布底边为准，窗口全屏后以全屏画布底边为准。居中按钮及 C 快捷键仍执行真正的居中。

控制栏隐藏后，顶部保留带文字的“显示控制栏”按钮；H 快捷键继续可用。补充隐藏按钮的可访问性标签。

验证：Debug 编译和 6 项单元测试通过，包括新增的跨窗口尺寸/缩放贴底及显式居中回归。原有 AppIcon JSON 警告不变。按钮视觉与鼠标操作留待本机试用确认。

## 本机试用修复：高亮背景可读性与恢复位置

控制栏和恢复显示按钮改为不透光深灰底、白色前景及边框，移除会受到 EDR 白色画布影响的半透明材质。“居中”改为“恢复位置”，按钮及 C 均清除手动位置，恢复默认底部居中锚点；缩放/窗口变化继续贴底。

Debug 编译及 6 项单元测试通过，回归覆盖移动后恢复贴底及随后 resize/zoom。实际 EDR 视觉对比度待用户在真机确认。原图标 JSON 冲突警告仍存在。

新图标候选稿保存为 design/app-icon-candidate-v1.png，完整生成提示词见 design/icon-prompt.txt。使用内置 image_gen 生成，已预览主体和构图，尚未替换正式图标或生成生产尺寸资源集。
