extends CanvasLayer


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	get_tree().paused = true
	await get_tree().create_timer(0.5).timeout
	set_process(true)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept"):
		get_tree().paused = false
		GameManager.reset()
		get_tree().reload_current_scene()
