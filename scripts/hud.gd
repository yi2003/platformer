extends CanvasLayer


@onready var label: Label = $Label


func _ready() -> void:
	GameManager.apple_collected.connect(_update)
	GameManager.lives_changed.connect(_update)
	_update(0)


func _update(_total: int) -> void:
	label.text = "Apples: %d   Lives: %d" % [GameManager.apples, GameManager.lives]
