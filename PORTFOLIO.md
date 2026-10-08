# 四非（Sifang）· 游戏作品集

本仓库收录《四非》游戏项目的**完整源码**，供评审老师查看代码与体验成品。

- **在线试玩（HTTPS，推荐）**：<https://a573657548d6403ba88635e969816144.app.workbuddy.host>
  首次加载约 78 MiB 运行资源，请等待进度条走完；推荐电脑浏览器 + 键盘鼠标，键盘无响应时先点一下画面获取焦点。

## 目录结构

| 路径 | 内容 |
| --- | --- |
| `project.godot` | Godot 4 工程配置（用 Godot 4.x 打开即可加载整个项目） |
| `scripts/` | GDScript 游戏逻辑源码（核心代码所在） |
| `scenes/` | 场景文件（`.tscn`） |
| `shaders/` | 着色器源码 |
| `tests/` | 自检与评测脚本 |
| `tools/` | 辅助工具脚本 |
| `assets/` | 美术与音频资源（来源与授权见 `ASSET_SOURCES.md`） |
| `data/` `docs/` | 数据与原型文档 |
| `export_presets.cfg` | Godot 导出预设（含 Web 导出配置） |
| `web/` | Web 版入口页与部署说明（二进制包未随仓库提交，见下文） |
| `README.md` `ASSET_SOURCES.md` | 项目原说明与美术资源来源/授权说明 |

## 如何查看代码

1. 安装 **Godot 4.x**（建议 4.4）。
2. 打开 Godot → 「导入」→ 选择本仓库根目录的 `project.godot`。
3. 源码主要在 `scripts/`（GDScript 逻辑）、`scenes/`（场景编排）、`shaders/`（视觉着色器）。

## 关于 `web/` 目录

`web/` 保存了 Godot 4.4 Web 导出的入口页（`index.html`、`index.js`、封面与音频模块）与部署说明；引擎二进制 `index.wasm` 与游戏资源包 `index.pck` 体积较大（合计约 78 MiB），按提交规范未随仓库上传，改以在线试玩链接提供。

如需本地复现 Web 版：用 Godot 4.4 打开工程，按 `export_presets.cfg` 中已配置的 Web 导出预设导出，将产物放入 `web/` 即可；或直接访问上方在线试玩链接。

## 备注

- 本仓库已用 `.gitignore` 排除 Godot 编辑器缓存（`.godot/`）与构建产物，可直接 `git init` 后提交。
- 资源文件最大不足 25 MiB，**无需 Git LFS**；未包含任何密钥或环境变量文件。
- 源码与资源版权归作者所有；美术素材来源与授权见 `ASSET_SOURCES.md`。
