extends Control

signal confirmed
const UI = preload("res://scripts/ui.gd")
var phase := 0.0
var selected := false
var modal: Control
var target: Button
var rate := 1.0
var amplitude := 16.0
var status: Label
var locked := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.label(self,"VOTE / 01     表决终端",Rect2(100,125,1080,50),32)
	UI.label(self,"其余五人已表明意向。选择投票对象，再提交确认。",Rect2(100,186,1080,40),20,UI.MUTED)
	UI.label(self,"已表态  /  沈知    林梢    小鹿    阿野    晚晚",Rect2(100,246,1080,40),20,UI.MUTED)
	target = UI.button(self,"老周   /   选择投票对象",Rect2(390,340,690,84),select_target)
	target.name = "VoteTarget"
	target.mouse_entered.connect(func(): if not selected: rate = 1.3)
	target.mouse_exited.connect(func(): if not selected: rate = 1.0)
	target.grab_focus()
	status = UI.label(self,"等待选择 _",Rect2(100,474,1080,42),22,UI.TEAL)
	var submit := UI.button(self,"提交投票  >",Rect2(730,550,350,60),open_confirmation,true)
	submit.name = "ConfirmVote"
	UI.label(self,"代行者：“票数最高的人，出局。”",Rect2(100,657,1080,36),18,UI.MUTED)

func select_target() -> void:
	selected = true
	rate = 2.2
	amplitude = 25.0
	target.text = "[ 已选择 ]  老周"
	status.text = "目标已锁定 / 老周   ·   等待提交 _"

func open_confirmation() -> void:
	if locked or is_instance_valid(modal): return
	if not selected:
		status.text = "请先选择投票对象 _"
		target.grab_focus()
		return
	rate = 2.8
	amplitude = 46.0
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(modal)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0,0,0,0.65)
	modal.add_child(shade)
	UI.panel(modal,Rect2(320,245,640,290))
	UI.label(modal,"CONFIRM / 确认表决",Rect2(350,268,580,38),22,UI.TEAL)
	UI.label(modal,"是否选择投票给老周？",Rect2(350,326,580,50),28)
	UI.label(modal,"确认后，本轮投票将提交。",Rect2(350,383,580,35),18,UI.MUTED)
	var cancel := UI.button(modal,"返回选择",Rect2(350,451,260,54),cancel_confirmation)
	UI.button(modal,"确认投票",Rect2(630,451,300,54),commit,true).name = "CommitVote"
	var pulse := Control.new()
	pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal.add_child(pulse)
	pulse.draw.connect(func():
		var line := PackedVector2Array()
		for i in range(280):
			var t := fposmod(float(i)/140.0-phase,1.0)
			var v := sin(t*TAU*3.0)*exp(-pow((t-0.5)*10.0,2.0))
			line.append(Vector2(360+i*2,426-v*22.0))
		pulse.draw_polyline(line,UI.TEAL,2.0,true)
	)
	cancel.grab_focus()

func cancel_confirmation() -> void:
	if locked: return
	remove_child(modal)
	modal.queue_free()
	modal = null
	rate = 2.2
	amplitude = 25.0
	target.grab_focus()

func commit() -> void:
	if locked: return
	locked = true
	confirmed.emit()

func _input(event: InputEvent) -> void:
	if is_instance_valid(modal) and event.is_action_pressed("ui_cancel"):
		cancel_confirmation()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	phase += delta * rate
	if is_instance_valid(modal): modal.get_child(modal.get_child_count()-1).queue_redraw()
	queue_redraw()

func _draw() -> void:
	# A traveling ECG spike terminates at the candidate, acting as a selection pointer.
	var points := PackedVector2Array()
	for i in range(241):
		var t := fposmod(float(i) / 240.0 - phase,1.0)
		var pulse := 0.0
		if t > 0.65 and t < 0.72: pulse = sin((t-0.65)/0.07*PI)*0.22
		elif t >= 0.76 and t < 0.80: pulse = -(t-0.76)/0.04*0.4
		elif t >= 0.80 and t < 0.84: pulse = lerpf(-0.4,1.0,(t-0.80)/0.04)
		elif t >= 0.84 and t < 0.90: pulse = lerpf(1.0,-0.3,(t-0.84)/0.06)
		elif t >= 0.90 and t < 0.94: pulse = lerpf(-0.3,0.0,(t-0.90)/0.04)
		points.append(Vector2(100+i,382-pulse*amplitude))
	draw_line(Vector2(100,382),Vector2(372,382),Color(0.4,0.7,0.75,0.2),1)
	draw_polyline(points,UI.TEAL,2.0,true)
	draw_colored_polygon(PackedVector2Array([Vector2(379,382),Vector2(366,375),Vector2(366,389)]),UI.TEAL)
	if is_instance_valid(modal):
		# Keep the pulse visible around the modal while it awaits confirmation.
		draw_polyline(points,Color(0.7,0.9,0.95,0.85),3.0,true)
