class_name LevelBase
extends Node2D

var game_over_scene := preload("res://scenes/game_over.tscn")

@onready var player: Player = $Player


func _ready() -> void:
	player.player_died.connect(_on_player_died)
	if GameManager.checkpoint_position == Vector2.ZERO:
		GameManager.checkpoint_position = player.global_position


func _on_player_died() -> void:
	GameManager.lose_life()
	await get_tree().create_timer(1.0).timeout

	if GameManager.lives > 0:
		player.respawn(GameManager.checkpoint_position)
	else:
		var game_over := game_over_scene.instantiate()
		add_child(game_over)
