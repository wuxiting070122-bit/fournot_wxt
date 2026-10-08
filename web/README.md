# 四非 · Web 版

本目录对应《四非》游戏的 **Godot 4.4 Web 导出**。按作品集提交规范，体积较大的引擎二进制与资源包未随仓库上传，改以**在线试玩链接**提供：

**<https://a573657548d6403ba88635e969816144.app.workbuddy.host>**

## 本目录包含

- `index.html` —— 入口页面
- `index.js` —— 启动脚本
- `index.png` / `index.icon.png` / `index.apple-touch-icon.png` —— 封面与图标
- `index.audio.worklet.js` / `index.audio.position.worklet.js` —— 音频处理模块
- `部署说明.txt` —— 原始部署说明

未包含的两个大文件：`index.wasm`（Godot 引擎，约 41.7 MiB）与 `index.pck`（游戏资源包，约 35.7 MiB）。

## 如何补齐并本地运行

1. 用 **Godot 4.4** 打开仓库根目录的 `project.godot`。
2. 使用已配置好的 Web 导出预设（`export_presets.cfg`）导出到本目录，生成 `index.wasm` 与 `index.pck`。
3. 在本目录执行 `python3 -m http.server 8000`，浏览器访问 `http://localhost:8000`。
   注意：不能直接双击 `index.html`；服务器需将 `.wasm` 以 `application/wasm` 提供。

## 部署为在线试玩（GitHub Pages）

将仓库推送 GitHub 后：`Settings → Pages`，Source 选默认分支、目录选 `/web`，保存即可。发布前先按上节补齐 `index.wasm` / `index.pck`（单文件均小于 100 MiB，无需 LFS）。

## 评测辅助

- 有效信息提交界面有「评测：跳过本关 F8」按钮，也可按 `F8`。
- 连续提交三次错误信息后会显示需要勾画的具体原句。
- 如键盘无响应，请先点击游戏画面使其获得焦点。
- 浏览器存档绑定当前网址与浏览器，清理网站数据或更换网址可能无法继续原存档。

## 验证范围

Godot 4.4 Web Release 导出成功，本地浏览器确认封面加载。尚未完成网页版全流程通关测试。
