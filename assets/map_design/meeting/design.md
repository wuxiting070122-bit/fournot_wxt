# 会议厅第一版
仅图片设计，未替换运行场景。
构图参考旧工程 Map004 / img/parallaxes/LoungeMorning.png：中央横向长桌、上下各四椅、下方入口、左边柜、右沙发、四周通道。
风格参考当前 assets/bedroom.png：青绿墙纸、同款纹样地砖、米金织物、暖色灯光。
内置 imagegen 生成。结果 meeting-v1.png，1536×1024。
提示词概要：Preserve the original full rectangular meeting lounge layout, central horizontal long table with eight chairs, bottom center entrance, left sideboard and lower right sofa. Use bedroom-reference hand-drawn RPG style, blue-green floral wallpaper and dark teal wainscoting, X/diamond patterned square floor tiles, beige-gold rugs with consistent teal borders, amber lamps. Broad walkable circulation, no characters, no text or UI, full room visible in top-down RPG oblique projection.

## 第二版：轮廓与明暗简化
内置imagegen，参考卧室画法和第一版会议厅构图。预览文件meeting-v2-simple.png，未接入运行场景。
提示词概要：Redraw meeting hall with clean outlined silhouettes, flat teal and beige fills, 2-3 tones per object and clear light-shadow boundaries. Preserve central table with eight chairs, bottom entry, left sideboard and right sofa. Reduce detail75%; three simple serving plates, jug and cups; sideboard only vase and lamp. Plain upholstery and rug borders, sparse wallpaper and simple floor diamonds. No ornate carvings, dense flowers, detailed food or noisy surface textures.

## 第三版：色块表现细节
内置imagegen结合前两版。保留第一版陈设丰富度，减少细碎线稿与粗黑勾边，以颜色、明暗面和少量边缘高光表现细节。输出meeting-v3-color.png，尚未接入游戏。
提示词概要：Combine reference1 atmospheric richness with reference2 clarity. Reduce LINEWORK rather than object richness; thin selective dark-colored silhouettes, interiors defined through painted 3-5-tone color planes and clear light/shadow boundaries. Moderate tableware and serving dishes, food built from colored clusters without individual ink outlines; restrained floral textiles and wallpaper painted at low contrast. Preserve room composition, eight chairs, left sideboard, right sofa, lower entrance, dark teal palette and warm lamps. No heavy black outlines, noisy grunge, characters or UI.

## 第一版会客厅接入与桌面修正
使用内置imagegen，将第一版中央桌面改为两封信、少量散页、两本书，保留蜡烛与大面积留白；保持原房间构图。提示词：Change only central tabletop objects, remove all food and dining ware, replace with sparse envelopes, loose pages, one closed book and one open book, preserve candles, tablecloth and all room geometry, palette and detail. 最终资产meeting-v1-clues.png。已接入meeting_world.gd，源图地砖约72像素，以64/72缩放匹配卧室；碰撞同步缩放，人物不缩放。
