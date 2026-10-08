extends SceneTree
const Save = preload("res://scripts/checkpoint.gd")
const PATH := "user://cover_test_checkpoint.json"
var app: Node
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for i in range(count): await process_frame
func click(point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position=point
	event.button_index=MOUSE_BUTTON_LEFT
	event.pressed=true
	root.push_input(event,true)
	await process_frame
	event.pressed=false
	root.push_input(event,true)
	await frames(22)
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/output/cover_"+name+".png")
func run() -> void:
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(PATH+suffix): DirAccess.remove_absolute(PATH+suffix)
	app=load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.checkpoint_path=PATH
	app.show_title()
	await frames(5)
	var cover=app.screen.get_child(0)
	assert(not cover.can_continue)
	await shot("01_intact")
	await click(Vector2(640,400))
	await frames(10)
	await shot("02_breaking")
	await frames(90)
	assert(cover.revealed and not cover.animating)
	await shot("03_menu")
	cover.animating=true
	cover.reflections[0].color.a=0.42
	await frames(2)
	await shot("04_fog_reflection")
	cover.reflections[0].color.a=0
	cover.animating=false
	await click(Vector2(1050,530))
	assert(app.stage=="title")
	await click(Vector2(1050,750))
	assert(is_instance_valid(cover.about))
	cover.about.queue_free()
	cover.about=null
	await frames(3)
	await click(Vector2(1050,325))
	assert(app.stage=="intro")
	app.finish_dialogue()
	app.save_enabled=true
	await frames(3)
	assert(Save.read_save(PATH).stage=="bedroom")
	app.group_id=2
	app.enter_cold(false)
	await frames(3)
	assert(Save.read_save(PATH).stage=="cold")
	app.save_enabled=false
	app.queue_free()
	await frames(3)
	app=load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.checkpoint_path=PATH
	app.show_title()
	await frames(3)
	cover=app.screen.get_child(0)
	assert(cover.can_continue)
	cover.reveal()
	await frames(100)
	await click(Vector2(1050,530))
	assert(app.stage=="cold" and app.group_id==2)
	assert(app.world.cold==0 and not app.acquired)
	var f:=FileAccess.open(PATH,FileAccess.WRITE)
	f.store_string("broken")
	f.close()
	assert(Save.read_save(PATH).stage=="bedroom")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(PATH+suffix): DirAccess.remove_absolute(PATH+suffix)
	print("COVER_REVIEW PASS: click reveal, animation lock, three polygon choices, about, save reload and backup recovery")
	quit()
