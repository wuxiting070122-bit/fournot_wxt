extends Node
## Exercises the actual scene transitions, keyboard movement and TextEdit selection.

var app: Node
var failures: Array[String] = []
var assertions := 0
var output := "res://tests/output"

func check(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)
		push_error("TEST FAILED: " + message)

func frame(count := 2) -> void:
	for i in range(count): await get_tree().physics_frame

func key(code: int, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)

func tap(code: int) -> void:
	key(code,true)
	await frame()
	key(code,false)
	await frame()

func click(point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	get_viewport().push_input(event,true)
	await get_tree().process_frame
	event.pressed = false
	get_viewport().push_input(event,true)
	await frame()

func walk(point: Vector2) -> void:
	var ticks := 0
	while app.world.player.position.distance_to(point) > 9.0 and ticks < 500:
		var offset: Vector2 = point-app.world.player.position
		key(KEY_D,offset.x>5)
		key(KEY_A,offset.x< -5)
		key(KEY_S,offset.y>5)
		key(KEY_W,offset.y< -5)
		await get_tree().physics_frame
		ticks += 1
	for code in [KEY_W,KEY_A,KEY_S,KEY_D]: key(code,false)
	await frame()
	check(ticks<500,"Collision-safe route reached %s" % point)

func snapshot(filename: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(output+"/"+filename+".png")

func skip() -> void:
	if app.dialogue_active:
		app.finish_dialogue()
	await frame()

func select_evidence(id: String, submit := true) -> void:
	var item: Dictionary = {}
	for evidence in app.battle.evidence:
		if evidence.id == id: item = evidence
	app.archive.show_source(item.source)
	var body: String = app.archive.reader.text
	var start: int = body.find(item.quote)
	check(start>=0,"Exact source quote exists for "+id)
	if start<0: return
	var prefix := body.substr(0,start)
	var from_line := prefix.count("\n")
	var from_column := prefix.length()-(prefix.rfind("\n")+1)
	var through := body.substr(0,start+str(item.quote).length())
	var to_line := through.count("\n")
	var to_column := through.length()-(through.rfind("\n")+1)
	app.archive.reader.select(from_line,from_column,to_line,to_column)
	var before: int = app.quotes.size()
	# Capture through the real UI button to verify TextEdit keeps its selection.
	await click(Vector2(530,696))
	check(app.quotes.size()==before+1,"TextEdit selection captured for "+id)
	if submit: app.archive.submit_quote(app.quotes.size()-1)
	await frame()

func run(game: Node) -> void:
	app = game
	var sentences = preload("res://scripts/sentence_selection.gd")
	var sample := "标题\n警方未确认死因，也未确认起火原因。\n他说：“不是我！”下一句。"
	var selected: Dictionary = sentences.resolve(sample, 5, 8)
	check(selected.get("text", "") == "警方未确认死因，也未确认起火原因。", "Partial selection preserves full sentence and negation")
	check(sentences.resolve(sample, 5, sample.length()).has("error"), "Cross-sentence selection rejected")
	check(sentences.spans("他说：‘不是我！’下一句。") .size() == 2, "Closing quotes remain attached to sentence")
	check(sentences.resolve(sample, 0, 0).has("error"), "Empty selection rejected")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	await frame(4)
	await snapshot("01_title")
	for group in range(3):
		app.start_new_game()
		await frame()
		var terminal = app.screen.get_node("IntroTerminal")
		check(terminal.lines.size()==6,"Recap uses six concise memory cards")
		var recap_text := JSON.stringify(terminal.lines)
		for person in ["沈知", "林梢", "小鹿", "老周", "阿野", "晚晚"]:
			check(recap_text.contains(person),"Recap retains " + person)
		terminal.set_process(false)
		for tick in range(4000):
			if app.stage != "intro": break
			terminal._process(0.25)
		await frame()
		check(app.stage=="bedroom","Automatic recap enters bedroom")
		if group == 0:
			check(app.world.player.motion_mode == CharacterBody2D.MOTION_MODE_FLOATING, "Top-down motion uses floating mode")
			app.world.player.position = Vector2(220, 365) * app.world.BEDROOM_SCALE
			key(KEY_A, true)
			await frame(30)
			key(KEY_A, false)
			check(app.world.player.position.x >= 203.0 * app.world.BEDROOM_SCALE, "Bed blocks feet at original tile boundary")
			app.world.player.position = Vector2(300, 240) * app.world.BEDROOM_SCALE
			key(KEY_W, true)
			await frame(30)
			key(KEY_W, false)
			check(app.world.player.position.y >= 203.0 * app.world.BEDROOM_SCALE, "Upper wall blocks feet while sprite overlaps visually")
			app.world.player.position = Vector2(400, 264) * app.world.BEDROOM_SCALE
			key(KEY_D, true)
			await frame(20)
			key(KEY_D, false)
			check(app.world.player.position.x > 430.0 * app.world.BEDROOM_SCALE, "Space below desk remains traversable")
			app.world.player.position = Vector2(235, 450) * app.world.BEDROOM_SCALE
		await walk(Vector2(235,255) * app.world.BEDROOM_SCALE)
		await walk(Vector2(135,255) * app.world.BEDROOM_SCALE)
		if group==0: await snapshot("02_bedroom")
		await tap(KEY_E)
		check(app.stage=="hallway","Door E interaction enters hallway")
		await skip()
		if group==0: await snapshot("03_groups")
		await click(Vector2(1080,350+group*72))
		check(app.group_id==group,"Group choice %d" % group)
		await skip()
		await skip()
		check(app.stage=="cold","Group reaches cold room")
		if group==0:
			await snapshot("04_cold_dark")
			app.world.player.position = Vector2(440,1152)
			app.world.cold = 0.0
			app.world.advance_cold(1.0)
			var normal: float = app.world.cold
			app.world.player.position = Vector2(1100,1460)
			app.world.cold = 0.0
			app.world.advance_cold(1.0)
			check(app.world.cold>normal,"Ice accelerates cold")
			app.toggle_pause()
			var frozen_value: float = app.world.cold
			await frame(20)
			check(app.world.cold==frozen_value,"Pause freezes temperature")
			app.toggle_pause()
			app.world.player.position = Vector2(400,1460)
			app.world.cold = 10.0
			app.world.advance_cold(1.0)
			check(app.world.cold==0.0,"Furnace restores warmth")
		if group==2:
			app.world.player.position = Vector2(440,1152)
			app.world.cold = 99.0
			app.world.advance_cold(1.0)
			check(app.dialogue_active and app.world.failed,"Cold death enters retry dialogue")
			await skip()
			check(app.stage=="cold" and not app.acquired and app.world.cold==0.0,"Retry resets checkpoint")
		await walk(Vector2(400,1340))
		await walk(Vector2(330,1340))
		await tap(KEY_E)
		check(app.world.lights_on,"Switch opens lights")
		await skip()
		await walk(Vector2(440,1340))
		await walk(Vector2(440,1152))
		await walk(Vector2(360,1152))
		await walk(Vector2(360,910))
		await walk(Vector2(620,910))
		await tap(KEY_E)
		check(app.world.ember_box,"Metal ember carrier collected")
		await walk(Vector2(1840,910))
		await walk(Vector2(1840,1130))
		await walk(Vector2(1895,1130))
		await tap(KEY_E)
		await skip()
		check(app.world.door_seen and not app.world.door_open,"Gate requires companions")
		await walk(Vector2(1870,1152))
		await walk(Vector2(440,1152))
		await walk(Vector2(440,1440))
		await tap(KEY_E)
		await skip()
		check(app.world.recruited,"Companions follow")
		await walk(Vector2(400,1460))
		await walk(Vector2(320,1460))
		await tap(KEY_E)
		check(app.world.ember,"Fire acquired")
		await frame(60)
		await walk(Vector2(440,1460))
		await walk(Vector2(440,1152))
		await walk(Vector2(1895,1130))
		await tap(KEY_E)
		await skip()
		await frame(100)
		check(app.world.door_open,"Group opens door")
		check(app.dialogue_active,"Post-door group conversation")
		app.finish_dialogue()
		await walk(Vector2(2130,1130))
		await walk(Vector2(2130,760))
		await walk(Vector2(2180,760))
		await tap(KEY_E)
		check(app.world.second_lit,"Second furnace ignited")
		await frame(120)
		await walk(Vector2(2840,760))
		await walk(Vector2(2840,698))
		await tap(KEY_E)
		check(app.acquired,"Case found inside unmarked cabinet")
		await skip()
		if group==0: await snapshot("05_cold_lit")
		await walk(Vector2(2840,760))
		await walk(Vector2(2130,760))
		await frame(120)
		await walk(Vector2(2130,1130))
		await walk(Vector2(1870,1152))
		await walk(Vector2(440,1152))
		await walk(Vector2(440,1460))
		check(not app.world.failed,"Cold room round trip survives")
		await walk(Vector2(210,1480))
		await tap(KEY_E)
		check(app.stage=="reunion","Exit opens reunion")
		await skip()
		check(app.stage=="meeting" and app.dialogue_active and app.archive==null,"Reunion starts confrontation without duplicate preparation")
		if group==0:
			var longest := 0
			for i in range(app.dialogue_lines.size()):
				if str(app.dialogue_lines[i].text).length()>longest:
					longest = str(app.dialogue_lines[i].text).length()
					app.dialogue_index = i
			app.update_dialogue()
			await frame(18)
			await snapshot("06b_confrontation")
			for i in range(app.dialogue_lines.size()):
				if str(app.dialogue_lines[i].speaker).begins_with("你"):
					app.dialogue_index = i
					break
			app.update_dialogue()
			await frame(18)
			check(app.portraits.portrait.visible and app.portraits.portrait.modulate.r > 0.95, "Heroine portrait bright when speaking")
			check(app.portraits.clip_contents and app.portraits.position.y + app.portraits.size.y == 523, "Portrait clips at dialogue waist line")
			await snapshot("06c_heroine_portrait")
			app.portraits.show_speaker("老周", true)
			await frame(18)
			check(app.portraits.portrait.visible and app.portraits.character_id=="laozhou", "Lawyer uses his supplied portrait")
			app.portraits.show_speaker("旁白", false)
			check(not app.portraits.portrait.visible, "Narration hides portrait")
		await skip()
		check(app.meeting_done and app.notes.contains("他是我父亲请的律师"),"Skip retains mandatory witness record")
		check(app.archive.mode=="prepare","One complete preparation screen follows testimony")
		if group==0: await snapshot("06_clues")
		await click(Vector2(1050,766))
		check(app.archive.mode=="battle","Battle opens after confrontation")
		check(not app.battle.advance(),"Cannot skip an unproven round")
		var rejected: Dictionary = app.battle.submit("social","死罪律师")
		check(rejected.damage==0 and app.battle.resistance==100,"Unrelated keywords cause no damage")
		if group == 0:
			app.archive.show_source("fire")
			var end: int = app.archive.reader.get_line_count() - 1
			app.archive.reader.select(0, 0, end, app.archive.reader.get_line(end).length())
			app.archive.capture_selection()
			check(app.quotes.is_empty(), "Archive rejects multi-sentence capture without filling slot")
		await select_evidence("A1")
		check(preload("res://scripts/sentence_selection.gd").spans(app.quotes[0].text).size() == 1, "Captured excerpt contains exactly one sentence")
		var resistance: int = app.battle.resistance
		app.archive.submit_quote(0)
		check(app.battle.resistance==resistance,"Repeat submission cannot farm damage")
		await click(Vector2(1050,766))
		await skip()
		check(app.battle.round_index==1,"First reasoning gate advances")
		await select_evidence("B1")
		check(not app.battle.gate_complete(),"Anonymous profession alone cannot identify Zhou")
		await select_evidence("B5")
		await click(Vector2(1050,766))
		await skip()
		check(app.battle.round_index==2,"Identity evidence and witness advance round")
		await select_evidence("C3")
		check(not app.battle.won(),"Payment instruction alone cannot win")
		await select_evidence("C5")
		check(app.battle.won() and app.battle.resistance<40,"Full evidence chain persuades")
		if group==0: await snapshot("07_persuasion")
		await click(Vector2(1050,766))
		await skip()
		await skip()
		check(app.stage=="vote" and not app.voted,"Vote requires explicit player confirmation")
		if group==0: await snapshot("08_vote")
		await click(Vector2(320,575))
		await skip()
		check(app.stage=="ending" and app.voted,"Group %d completes ending" % group)
		if group==0: await snapshot("09_ending")
	var report := {"assertions":assertions,"failures":failures,"renderer":DisplayServer.get_name(),"result":"PASS" if failures.is_empty() else "FAIL"}
	var file := FileAccess.open(output+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("SMOKE_TEST "+JSON.stringify(report))
	get_tree().quit(0 if failures.is_empty() else 1)
