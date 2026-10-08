# 素材来源

- `assets/heroine.png`：用户提供的旧工程 `img/characters/$Heroine.png`。仅使用现有女版主角，按 48×64 帧切分四方向行走。
- `assets/bedroom.png`：用户提供的旧工程 `img/parallaxes/new_home.png`。
- `assets/hallway.png`：用户提供的旧工程 `img/parallaxes/!Hall.png`。
- `assets/bed_foreground.png`：原工程 `img/parallaxes/Bed.png`，床头遮挡层。
- `assets/heroine_portrait.png`：原工程 `img/pictures/Heroine.png`，女主对话立绘。
- `data/map_collisions.json`：从原工程 Map001 / Map002 首事件页的普通优先级、不可穿透事件位置提取。
- 上述图片从旧工程复制，原文件未被修改。作者及最终发行所需授权以用户原始素材来源为准。
- 冷冻室、会议室、人物剪影、冰面、火炉、案卷及界面装饰：本工程用 Godot 图形绘制的占位形状。
- `assets/NotoSansSC.ttf`：Noto Sans SC，Google Fonts 仓库 `ofl/notosanssc/NotoSansSC[wght].ttf`，通过 jsDelivr 镜像取得。SIL Open Font License 1.1，完整许可证附于 `assets/FONT_LICENSE.txt`。
- 剧情与线索数据：本工作区已整理的第一轮投票剧本、六份线索正文及说服规则。

没有复制 RPG Maker 引擎、插件、默认图块、配乐或音效。

## 新增四人立绘

`assets/portraits/` 下的 linshao、shenzhi、heroine、wanwan JPG 分别来自用户本次按顺序提供的大小姐、作家、画家、女学生图片。原图原样复制；白底由 Godot 着色器在显示时透明化，腰线和中心点在 `data/portraits.json` 中配置。JPG 的白底压缩边缘仍可能有少量残留；透明 PNG 可直接替换为更干净的正式素材。

## 分层封面

`assets/cover/` 原样保存用户五张 JPG：character 为第一张人物底图，glass 为第四张裂纹层，light 为第三张光圈遮罩；第二、第五张作为碎裂纹理和最终效果参考。由 Godot 着色器把白底裂纹和白色光圈转换为显示用透明度，原图不改写。破裂扩散、轻震、碎片位移与菜单淡入使用 Tween；光圈在最上方，菜单文字位于光效之上以保留可读性。

## 地图角色动画

`assets/characters/` 下四张 384×256 图集来自用户认可的统一风格生成稿 `assets/character_design/unified_v1/`，通过 Godot 导入脚本按真实角色区域切帧、处理透明边缘、最近邻缩小并统一脚底位置。每格 64×64，四行对应正面/左侧/右侧/背面；前三列行走，后三列待机。导入记录为同目录 `import_report.json`，可重跑 `tools/import_character_sheets.gd`。原始生成稿和旧女主图均保留。

### 男学生立绘（2026-09-29）
- `assets/portraits/aye.jpg`：用户提供的男学生原画，保留手中的烟；对白中居中显示腰部以上，使用既有白底着色器。
- Q 版修订确认稿保存在工程外 `../assets/character_design/aye_v1/aye-sheet-v3-no-cigarette.png`：所有动作帧无烟，后脑保留小发束。尚未替换地图角色，等待用户看图确认。
- `tests/portrait_review.gd` 五位角色立绘及黑暗层级检查通过。

### 男学生动作图接入（2026-09-29，用户确认后）
- 已将确认的无烟、小发束版本导入 `assets/characters/aye.png`，统一为 64×64 单帧、6列4行，脚底基线62。
- 已用于走廊、会议室及选择男学生同行的冷冻室；接入共享四方向行走与待机呼吸动画。
- 五名角色共120帧的动画检查通过，并检查了走廊实际渲染。对白原画仍保留烟。

### 女主播立绘及待确认动作图（2026-09-29）
- 用户原画复制至 `assets/portraits/xiaolu.jpg`，小鹿/鹿雯雯/女主播/女网红对白使用此图；居中、腰部以上、对白层高于黑暗遮罩。
- 六名角色立绘测试通过，检查了女主播实际渲染。
- 动作确认稿：`../assets/character_design/xiaolu_v1/xiaolu-preview.png`，四方向各三帧行走与三帧待机，共24帧；尚未切帧或接入地图，等待用户确认。

### 女主播动作图接入（2026-09-29，用户确认新版后）
- 使用 `../assets/character_design/xiaolu_v1/xiaolu-preview-v3.png`，保留左向包遮挡及背面露黑色裙摆的修订。
- 导入 `assets/characters/xiaolu.png`：64×64单帧，6列4行，共24帧，统一脚底基线62；源图使用独立裁切区域以完整保留高马尾。
- 小鹿在走廊、会议室及对应组队冷冻室使用共享四方向行走与待机呼吸组件；对白原立绘保持不变。
- 六角色144帧动画检查通过，走廊实际渲染检查通过。

### 律师老周立绘与动作确认稿（2026-09-30）
- 用户原画保存为 `assets/portraits/laozhou.jpg`；对白姓名老周/律师/周律师均映射到该立绘，居中半身显示，处于黑暗遮罩上方。
- 七位角色立绘检查通过，已核对老周实际渲染。
- 动作图保存为 `../assets/character_design/laozhou_v1/laozhou-preview.png`，四方向各三帧行走及三帧待机的24帧确认稿；尚未导入地图，等待用户确认。

### 老周动作图接入（2026-09-30，用户确认后）
- 已将 `../assets/character_design/laozhou_v1/laozhou-preview.png` 导入 `assets/characters/laozhou.png`，64×64单帧、6列4行，统一脚底基线62。
- 走廊、会议室和对应组队冷冻室使用老周新像素形象，共享四方向行走及待机呼吸组件。
- 七角色168帧动画检查通过，已核对走廊实际显示。

### 代行者像素形象（2026-09-30）
- 根据确认的代行者立绘生成 `../assets/character_design/daixingzhe_v1/sheet-v1.png`；导入 `assets/characters/daixingzhe.png`，四方向移动/待机，共24帧。
- 侧面移动第三帧按实际朝向互换归组，保持四方向一致。
- 会议桌左侧新增代行者节点，面向桌内，接入待机呼吸。八角色192帧与会议出场检查通过。

### 三位角色立绘替换（2026-09-30）
- 按用户上传顺序替换 aye.jpg（男学生）、heroine.jpg（画家）、wanwan.jpg（女学生），保持既有居中半身配置。
- 原文件备份于 ../assets/character_design/portrait_backups/，替换后文件与用户原图逐字节一致，已重新导入。

### 冷冻室大地图（2026-09-30）
- `assets/cold_large.png`：基于原卧室、走廊风格生成，长方形连接右侧深冷库；长方形上墙统一为闭合窗帘，目标柜已去除可见案卷图案。
- 原图1536×1024，场景按2倍显示，864×624独立视口＋Camera2D跟随。墙柜碰撞按图中边缘标定。
- `scripts/cold_world.gd` 管理协作开门、门前隐藏、双炉、运火、冷风和11个柜子调查点；只有一个柜子提供案卷，普通调查结果使用非模态短提示。
