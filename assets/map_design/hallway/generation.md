# 循环走廊美术
使用内置 imagegen 编辑原走廊，以卧室作为色彩参考。
最终资产：assets/hallway_loop.png。原走廊 hallway.png 保留。
首轮：统一青绿色调，地毯上下留白均衡，移除左右封闭墙和楼梯，三个房门，横向循环。
修正：删除地毯上方独立的金色花边，仅保留地毯本身蓝色边纹。

最终修正提示词：
Precise local edit to this exact 1536x1024 game background. Remove ONLY the unnecessary thin independent gold flower ornamental horizontal stripe at y465 to500 (above the beige carpet and below the top row of teal floor tiles). Fill that narrow strip with plain teal floor matching adjacent floor texture and grout, no flowers, no ornamental band. Keep the beige carpet itself including its blue floral edge at y520-550 completely unchanged, as well as its bottom edge y760-800. Preserve exact positions, sizes, colors and details of all three doors, lamps, wall, carpet and all other tiles. Preserve horizontal seamless tiling with no left/right end walls. No added objects, no new decorative bands. Output full same 1536x1024 map.

## 最终地砖修正
继续使用内置imagegen修正蓝色条带，最终图为exec-0d473301-d9e6-4b38-921f-75dee47f08c6.png，覆盖hallway_loop.png。
提示词：
Fix this exact game map 1536x1024. The bare blue horizontal strip immediately above the beige carpet at y460-518 is WRONG. Replace it with the SAME repeating square teal floor tiles with inset X/diamond motifs seen at y354-460 and at y820-916. Tile floor must be continuous: the next row of square X-motif tiles begins at y460 and continues underneath the carpet, so its top half WITH VISIBLE UPPER PORTION OF THE X MOTIF is visible from y460 to518 before being naturally occluded by the carpet starting y519. Keep square tile grid columns aligned with row above, same size, same ornate X motifs, same shading. NO plain blue strip, NO curb, NO narrow brick strip, NO decorative edging outside carpet, NO invented floor material. Preserve carpet exact location y519-800 and its own blue floral border. Preserve walls, doors, lights, whole composition and colors elsewhere. Do not move carpet up to cover error. Maintain horizontal repeatable map full canvas. Only repair the previously incorrect strip with correct patterned tiles.

## 地毯上沿包边
内置imagegen编辑：补齐上侧浅蓝外包边，与下侧花纹加浅蓝边结构对应。最终结果exec-d0a84cec-f935-4e24-b762-6ac4c4a3dbca.png，已替换hallway_loop.png。
提示词：Add a matching continuous pale blue fabric binding strip above the top floral band, same thickness, color and texture as the bottom binding. Top-to-bottom ordering: patterned square floor tiles, pale blue solid carpet binding, floral carpet border, beige carpet field. Preserve map dimensions, doors, lights, walls, exposed patterned tiles and horizontal repeat.

## 包边色彩融合
使用内置imagegen，将上下外包边调整为墙纸同色系的低饱和灰青色。最终文件assets/hallway_loop.png。
提示词：Recolor ONLY the two narrow solid pale blue outer fabric binding strips on the carpet, top y521-534 and bottom y789-802. Make BOTH bindings subdued desaturated gray-teal sampled from wallpaper, approximately #365b60, matte aged textile, softer lower contrast, no glow. Preserve both strips thickness and shape, floral bands, beige carpet, patterned tiles, doors, wallpaper, lamps and horizontal tiling. No overall color grading.
