# 缓存小扫帚

原生 macOS 悬浮窗开发缓存清理工具，使用 Swift + AppKit，无第三方依赖。

## 构建和运行

需要 macOS 11 或更新版本，以及 Xcode 或 Xcode Command Line Tools。

```sh
bash build.sh --run
```

构建脚本先编译，再运行隔离的临时目录自检，最后对应用进行本地 ad-hoc 签名。输出位于 `build/缓存小扫帚.app`，可在 Finder 中双击，或复制到“应用程序”。这不是 Developer ID 签名或公证发行版。

## 使用

启动后自动扫描固定范围。点击“清理…”并确认后才删除缓存。完成后显示清理量、剩余容量和磁盘可用空间变化。关闭悬浮窗后，点击菜单栏 ✨ →“显示悬浮窗”重新打开；从同一菜单退出应用。

扫描与清理在后台执行，操作期间按钮禁用。建议先退出相关开发工具及正在运行的构建。

## 清理范围

仅清理当前用户下的以下固定目录；不使用管理员权限，不访问云端：

- `Library/Application Support/Codex/Crashpad/pending`
- `.cache/uv`
- `Library/Caches/vscode-cpptools`
- `.gradle/caches`、`.gradle/.tmp`、`.gradle/daemon`
- `.npm/_cacache`、`.npm/_npx`
- `Library/Caches/CocoaPods`、`Yarn`、`electron`、`ms-playwright`、`typescript`

缓存永久删除，不进入废纸篓；之后使用工具时可能需要重新下载、索引或编译。源码、Git 工作树、聊天数据、Codex 对话和 Docker 数据不在范围内。

扫描前拒绝目标或父路径中的符号链接。无权限读取的目录会显示错误并跳过；部分清理失败会报告。容量由 `du -sk` 统计，受 APFS 共享块和其他应用活动影响，不等于磁盘最终释放量。不要在清理期间更改目标目录或链接。

## 自检

`bash build.sh` 自动验证路径约束、符号链接拒绝、容量格式和临时测试目录删除，不删除真实缓存。界面取消流程也可通过“清理…”→“取消”验证。
