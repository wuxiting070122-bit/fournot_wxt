extends SceneTree
const SOURCES := {"heroine":"painter-sheet-v1.png","linshao":"heiress-sheet-v1.png","shenzhi":"writer-approved.png","wanwan":"student-sheet-v1.png","aye":"../aye_v1/aye-sheet-v3-no-cigarette.png","xiaolu":"../xiaolu_v1/xiaolu-preview-v3.png","laozhou":"../laozhou_v1/laozhou-preview.png","daixingzhe":"../daixingzhe_v1/sheet-v1.png"}
func _initialize() -> void:
	var report := {}
	for id in SOURCES:
		var source := Image.load_from_file(ProjectSettings.globalize_path("res://../assets/character_design/unified_v1/"+SOURCES[id]))
		var atlas := Image.create(384,256,false,Image.FORMAT_RGBA8)
		atlas.fill(Color.TRANSPARENT)
		var regions: Array[Image] = []
		var max_height := 0
		for row in range(4):
			for column in range(6):
				var region := Rect2i(60+column*244,row*250,244,250) if id in ["xiaolu", "laozhou"] else Rect2i(60+column*236,28+row*237,232,237)
				if id == "daixingzhe":
					# The third side poses in the source face the opposite direction.
					var source_row := 3-row if column==2 and row in [1,2] else row
					region = Rect2i(40+column*244,source_row*250,244,250)
				var piece := source.get_region(region)
				for y in range(piece.get_height()):
					for x in range(piece.get_width()):
						var c := piece.get_pixel(x,y)
						c.a = 1.0 if c.a > 0.75 else 0.0
						piece.set_pixel(x,y,c)
				var bounds := piece.get_used_rect()
				assert(bounds.size.x>30 and bounds.size.y>100,"Missing character frame")
				var trimmed := piece.get_region(bounds)
				regions.append(trimmed)
				max_height = maxi(max_height,trimmed.get_height())
		var factor := 56.0 / float(max_height)
		var details: Array = []
		for i in range(regions.size()):
			var frame := regions[i]
			frame.resize(roundi(frame.get_width()*factor),roundi(frame.get_height()*factor),Image.INTERPOLATE_NEAREST)
			assert(frame.get_width() <= 60 and frame.get_height() <= 56)
			var at := Vector2i((i%6)*64+(64-frame.get_width())/2,(i/6)*64+62-frame.get_height())
			atlas.blit_rect(frame,Rect2i(Vector2i.ZERO,frame.get_size()),at)
			details.append({"width":frame.get_width(),"height":frame.get_height(),"baseline":62})
		assert(atlas.save_png("res://assets/characters/"+id+".png")==OK)
		report[id]={"source":SOURCES[id],"cell":[64,64],"columns":6,"rows":4,"frames":details}
	var f := FileAccess.open("res://assets/characters/import_report.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"\t"))
	print("IMPORTED 192 frames: transparent, normalized height, foot baseline62")
	quit()
