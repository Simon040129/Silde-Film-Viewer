Silde Film Viewer 1.1.0 — EDR 灯箱重构

- 新胶片与观片放大镜图标。
- 默认亮区底部居中，恢复位置按钮及 C 快捷键恢复贴底。
- 修正逻辑点/像素、画幅比例、边界和窗口尺寸变化处理。
- 根据所在显示器的当前 EDR headroom 输出，RGB 微调保持通道比例。
- 不透光控制栏提升高亮背景下可读性；隐藏后有明确恢复按钮。
- 窗口全屏与铺满亮区独立控制；按焦点处理键盘操作。

系统要求：macOS 15 或更新；包含 Apple Silicon 和 Intel 可执行代码。Intel 显示器及 EDR 硬件行为仍需真机验证。

安装：下载 universal.zip，解压并将应用复制到 Applications。此版本仅使用 ad-hoc 签名，没有 Developer ID 签名或 Apple 公证，下载后可能被 Gatekeeper 拦截；请按 macOS 的“隐私与安全性”流程确认可信来源，或使用 Xcode 从源码构建。不要关闭系统安全保护。

操作：点击灯箱后方向键移动，Shift 精细移动，⌘+/− 缩放，C 恢复位置，H 隐藏/显示控制栏，Esc 退出窗口全屏。系统亮度键由 macOS 管理。

验证：优化构建单元测试覆盖 6 个场景；发布流程先测试再构建通用 Release 归档。EDR 倍率不是 nit 测量，不能保证 1600 nit；未完成持续亮度、光谱/白平衡和所有跨屏场景测量。

此发布来自 feature/edr-refactor；main 和旧功能分支保持不变。原图标素材保存在 design/legacy-icons，原代码回退标签为 baseline/main-before-edr-refactor-20261014。
