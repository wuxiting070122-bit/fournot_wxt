extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.group_id = 0
	app.enter_cold(false)
	var names := ["林梢", "沈知", "你", "晚晚", "阿野", "小鹿", "老周"]
	for i in range(names.size()):
		app.play_dialogue([{"speaker":names[i],"text":"冷冻室 · 立绘与对白层级检查。黑暗只覆盖地图，人物腰线与对话框上沿对齐。"}],func(): pass)
		for tick in range(25): await process_frame
		assert(app.dialog.z_index > app.world.dark.z_index)
		assert(app.portraits.character_id == ["linshao","shenzhi","heroine","wanwan","aye","xiaolu","laozhou"][i])
		assert(app.portraits.clip_contents)
		assert(app.portraits.portrait.material == null)
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://tests/output/portrait_%d.png" % i)
		app.finish_dialogue()
		await process_frame
	print("PORTRAIT_REVIEW PASS: seven speakers, waist clipping and darkness layering")
	quit()
