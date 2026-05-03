extends Node

signal apple_collected(total: int)
signal lives_changed(lives: int)

var apples: int = 0
var lives: int = 3
var checkpoint_position: Vector2


func add_apple() -> void:
	apples += 1
	apple_collected.emit(apples)


func lose_life() -> void:
	lives -= 1
	lives_changed.emit(lives)


func reset() -> void:
	apples = 0
	lives = 3
	checkpoint_position = Vector2.ZERO
	apple_collected.emit(0)
	lives_changed.emit(3)
