extends Control
## The ID portrait is a connected cutout rig: head, shoulders, and chest.
## Shared seam vertices keep the original pixel artwork closed throughout breathing.
const REGION := Rect2(208,10,34,35)
const ROWS := [0.0,21.0,27.0,35.0]
var pieces: Array[Polygon2D] = []
var phase := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for i in range(3):
		var piece := Polygon2D.new()
		piece.name = ["Head","Shoulders","Chest"][i]
		piece.texture = preload("res://assets/characters/heroine.png")
		piece.uv = PackedVector2Array([
			REGION.position+Vector2(0,ROWS[i]),REGION.position+Vector2(34,ROWS[i]),
			REGION.position+Vector2(34,ROWS[i+1]),REGION.position+Vector2(0,ROWS[i+1])])
		add_child(piece)
		pieces.append(piece)
	resized.connect(update_pose)
	update_pose()

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	phase = fmod(phase+delta*TAU/3.8,TAU)
	update_pose()

func update_pose() -> void:
	if pieces.is_empty(): return
	var fit := minf(size.x/34.0,size.y/35.0)
	var origin := (size-Vector2(34,35)*fit)*0.5
	var breath := (1.0-cos(phase))*0.5
	# Motion is measured in display pixels, not enlarged sprite pixels.
	var rise := [-1.25,-1.25,-0.7,0.0]
	var expansion := [0.0,0.0,0.4,0.0]
	for i in range(3):
		var top := origin+Vector2(0,ROWS[i]*fit+rise[i]*breath)
		var bottom := origin+Vector2(0,ROWS[i+1]*fit+rise[i+1]*breath)
		pieces[i].polygon = PackedVector2Array([
			top+Vector2(-expansion[i]*breath,0),top+Vector2(34*fit+expansion[i]*breath,0),
			bottom+Vector2(34*fit+expansion[i+1]*breath,0),bottom+Vector2(-expansion[i+1]*breath,0)])
