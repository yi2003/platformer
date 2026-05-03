class_name Snail
extends CharacterBody2D

enum State { PATROL, HIT, SHELL }

const MOVE_SPEED := 60.0
const GRAVITY := 980.0
const SHELL_SPEED := 250.0
const HIT_DURATION := 0.3

var state: State = State.PATROL
var direction: int = -1
var can_flip: bool = true

var _hit_timer: float = 0.0
var _flip_cooldown: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stomp_area: Area2D = $StompArea
@onready var body_area: Area2D = $BodyArea
@onready var edge_left: RayCast2D = $EdgeDetectLeft
@onready var edge_right: RayCast2D = $EdgeDetectRight


func _ready() -> void:
	sprite.play(&"walk")
	sprite.scale.x = abs(sprite.scale.x) * -direction
	stomp_area.body_entered.connect(_on_stomp_area_body_entered)
	body_area.body_entered.connect(_on_body_area_body_entered)


func _physics_process(delta: float) -> void:
	match state:
		State.PATROL:
			_process_patrol(delta)
		State.HIT:
			_process_hit(delta)
		State.SHELL:
			_process_shell(delta)

	move_and_slide()

	_flip_cooldown = maxf(0.0, _flip_cooldown - delta)

	if state == State.PATROL and _flip_cooldown <= 0.0:
		var edge := edge_left if direction == -1 else edge_right
		if not edge.is_colliding():
			_flip_direction()

	if is_on_wall():
		velocity.y = maxf(velocity.y, 0.0)
		var moving_into_wall := signi(velocity.x) == -signi(get_wall_normal().x)
		if moving_into_wall:
			if state == State.PATROL and _flip_cooldown <= 0.0:
				_flip_direction()
			elif state == State.SHELL and abs(velocity.x) > 20.0 and _flip_cooldown <= 0.0:
				_bounce_shell()


func _process_patrol(delta: float) -> void:
	velocity.y += GRAVITY * delta
	velocity.x = direction * MOVE_SPEED


func _process_hit(delta: float) -> void:
	velocity.x = 0.0
	velocity.y += GRAVITY * delta
	_hit_timer += delta
	if _hit_timer >= HIT_DURATION:
		state = State.SHELL
		sprite.play(&"shell_idle")


func _process_shell(delta: float) -> void:
	velocity.y += GRAVITY * delta
	velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)


func die() -> void:
	if state != State.PATROL:
		return
	state = State.HIT
	_hit_timer = 0.0
	sprite.play(&"hit")
	stomp_area.set_deferred("monitoring", false)
	body_area.set_deferred("monitoring", false)


func _flip_direction() -> void:
	direction *= -1
	sprite.scale.x = abs(sprite.scale.x) * -direction
	_flip_cooldown = 0.3


func _bounce_shell() -> void:
	direction *= -1
	velocity.x = direction * SHELL_SPEED
	sprite.scale.x = abs(sprite.scale.x) * -direction
	_flip_cooldown = 0.3


func _on_stomp_area_body_entered(body: Node2D) -> void:
	if body is Player and body.velocity.y > 0.0:
		body.velocity.y = -200.0
		die()


func _on_body_area_body_entered(body: Node2D) -> void:
	if body is Player and state == State.PATROL:
		body.die()
	elif body is Player and state == State.SHELL:
		state = State.SHELL
		direction = 1 if body.global_position.x < global_position.x else -1
		velocity.x = direction * SHELL_SPEED
		sprite.play(&"shell_wall_hit")
