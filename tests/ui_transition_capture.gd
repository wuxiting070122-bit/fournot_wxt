extends SceneTree

const OUT := "res://../ui_review/frames"
var app: Control
var names: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func settle(ticks := 5) -> void:
	for i in range(ticks): await process_frame

func shot(id: String) -> void:
	await settle(8)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "%s/%s.png" % [OUT,id]
	var error := image.save_png(path)
	assert(error == OK, "Could not save %s" % path)
	names.append(id)
	print("CAPTURE ",id," ",image.get_size())

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await shot("01_封面完整")
	var cover: Control = app.screen.get_child(0)
	cover.reveal()
	await settle(90)
	await shot("02_破碎镜面主菜单")
	cover.show_about()
	await shot("03_关于作品")
	cover.about.queue_free()
	cover.about = null
	await settle()
	app.start_new_game()
	await settle(35)
	await shot("04_前情提要终端")
	app.enter_bedroom()
	await shot("05_卧室探索")
	app.enter_hallway()
	await shot("06_走廊初见对白")
	app.finish_dialogue()
	await shot("07_选择同行者")
	app.choose_group(0)
	await shot("08_队友交谈")
	app.finish_dialogue()
	await shot("09_队友确认")
	app.accept_group()
	await shot("10_冷冻室入场对白")
	app.finish_dialogue()
	await shot("11_冷冻室探索未开灯")
	app.on_interaction("switch")
	await shot("12_冷冻室开灯对白")
	app.finish_dialogue()
	await shot("13_冷冻室探索已开灯")
	app.world.searched = {0:true,1:true,2:true}
	app.world.discover_door()
	await shot("14_同伴发现异常")
	app.finish_dialogue()
	app.toggle_pause()
	await shot("15_设置与人物介绍")
	app.pause_layer.show_history()
	await shot("16_剧情回顾")
	app.toggle_pause()
	app.acquired = true
	app.enter_reunion()
	await shot("17_门外汇合对白")
	app.finish_dialogue()
	await shot("18_会谈对白")
	app.finish_dialogue()
	await shot("19_整理证据")
	app.on_archive_continue()
	await shot("20_第一轮说服")
	app.archive.show_source("lawyer")
	await shot("21_切换证据文档")
	app.close_archive()
	app.persuaded = true
	app.enter_vote()
	await shot("22_投票确认")
	app.confirm_vote()
	await shot("23_投票后对白")
	app.finish_dialogue()
	await shot("24_第一轮结尾")
	print("UI_CAPTURE_DONE ",JSON.stringify(names))
	quit()
