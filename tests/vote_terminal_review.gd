extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var vote := preload("res://scripts/vote_terminal.gd").new()
	root.add_child(vote)
	await process_frame
	vote.open_confirmation()
	assert(not is_instance_valid(vote.modal),"Cannot submit without selecting")
	vote.select_target()
	assert(vote.rate > 1.0)
	vote.open_confirmation()
	assert(is_instance_valid(vote.modal))
	assert(vote.amplitude == 46.0)
	await process_frame
	vote.cancel_confirmation()
	assert(vote.selected and not is_instance_valid(vote.modal))
	vote.open_confirmation()
	var commits := [0]
	vote.confirmed.connect(func(): commits[0] += 1)
	vote.commit()
	vote.commit()
	assert(commits[0] == 1,"Confirmation must commit exactly once")
	print("PASS: selection, accelerated pulse, confirmation, cancel and single commit")
	quit()
