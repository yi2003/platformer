class_name Checkpoint
extends Area2D

var activated: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if activated or not body is Player:
		return

	activated = true
	GameManager.checkpoint_position = global_position
	sprite.modulate = Color.YELLOW
