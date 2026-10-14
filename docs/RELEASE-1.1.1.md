Silde Film Viewer 1.1.1 — 图标边框修复

- 移除图标透明外边距和预绘制的圆角底座，改用铺满画布的不透明底图，由系统处理外侧圆角。
- 保留胶片、齿孔和观片放大镜设计，改善应用列表与 Dock 中的视觉占比。
- 灯箱功能及键盘操作与 1.1.0 一致。

系统要求：macOS 15 或更新。通用安装包包含 Apple Silicon 和 Intel 代码；构建号 4。

安装：下载 universal.zip，解压后将应用复制到 Applications。此版本使用 ad-hoc 签名，没有 Developer ID 签名或 Apple 公证，下载后可能被 Gatekeeper 拦截；请通过 macOS“隐私与安全性”确认可信来源，或使用 Xcode 从源码构建。不要关闭系统安全保护。

发布包附有 SHA256SUMS.txt。EDR 倍率不是 nit 测量，实际亮度和白平衡取决于显示器与系统设置。

代码来自 feature/edr-refactor；main 与 1.1.0 发布保留不变。
