class_name Apple
extends Area2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return

	set_deferred("monitoring", false)
	GameManager.add_apple()
	$AnimatedSprite2D.play(&"collected")
	$CollectSfx.play()
	await $AnimatedSprite2D.animation_finished
	queue_free()
