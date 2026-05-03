class_name Exit
extends Area2D

@export_file("*.tscn") var next_scene: String


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return

	set_deferred("monitoring", false)
	GameManager.checkpoint_position = Vector2.ZERO
	get_tree().change_scene_to_file(next_scene)
