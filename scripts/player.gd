class_name Player
extends CharacterBody2D

# -- Signals
signal player_died

# -- State
enum PlayerState { IDLE, RUN, JUMP, DOUBLE_JUMP, FALL, WALL_SLIDE, HIT }

# -- Physics
const GRAVITY := 980.0
const MOVE_SPEED := 300.0
const ACCELERATION := 2000.0
const FRICTION := 1500.0
const AIR_ACCELERATION := 1200.0
const AIR_FRICTION := 800.0
const JUMP_VELOCITY := -380.0
const DOUBLE_JUMP_VELOCITY := -420.0
const MAX_FALL_SPEED := 500.0
const WALL_SLIDE_GRAVITY := 200.0
const WALL_SLIDE_MAX_SPEED := 140.0
const WALL_JUMP_HORIZONTAL := 300.0
const WALL_JUMP_VERTICAL := -350.0
const JUMP_RELEASE_MULTIPLIER := 0.5

# -- Timers
const COYOTE_TIME := 0.1
const JUMP_BUFFER_TIME := 0.1
const WALL_JUMP_LOCKOUT_TIME := 0.2
const HIT_DURATION := 0.4

# -- State variables
var state: PlayerState = PlayerState.IDLE
var has_double_jump: bool = true
var facing_direction: int = 1
var is_wall_jump_locked: bool = false
var _hit_timer: float = 0.0

# -- Buffered input (captured once per frame)
var _horizontal: float = 0.0
var _jump_just_pressed: bool = false
var _jump_held: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer
@onready var wall_jump_lockout_timer: Timer = $WallJumpLockoutTimer
@onready var jump_sfx: AudioStreamPlayer2D = $JumpSfx
@onready var death_sfx: AudioStreamPlayer2D = $DeathSfx


func _ready() -> void:
	coyote_timer.timeout.connect(_on_coyote_timer_timeout)
	jump_buffer_timer.timeout.connect(_on_jump_buffer_timer_timeout)
	wall_jump_lockout_timer.timeout.connect(_on_wall_jump_lockout_timeout)


func _physics_process(delta: float) -> void:
	if state == PlayerState.HIT:
		velocity.y += GRAVITY * delta
		_hit_timer += delta
		if _hit_timer >= HIT_DURATION:
			player_died.emit()
			sprite.hide()
			set_physics_process(false)
		move_and_slide()
		return

	_read_input()
	_update_facing()
	_apply_gravity(delta)
	_dispatch_state(delta)
	move_and_slide()
	_post_move_checks()


func die() -> void:
	if state == PlayerState.HIT:
		return
	state = PlayerState.HIT
	_hit_timer = 0.0
	velocity = Vector2.ZERO
	death_sfx.play()
	sprite.play(&"hit")
	set_process_input(false)
	collision_layer = 0
	collision_mask = 0


func respawn(spawn_position: Vector2) -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	state = PlayerState.IDLE
	has_double_jump = true
	facing_direction = 1
	is_wall_jump_locked = false
	sprite.play(&"idle")
	sprite.show()
	sprite.scale.x = abs(sprite.scale.x)
	collision_layer = 1
	collision_mask = 1
	set_physics_process(true)
	set_process_input(true)


# ---- Input ----

func _read_input() -> void:
	_horizontal = Input.get_axis("move_left", "move_right")
	_jump_just_pressed = Input.is_action_just_pressed("jump")
	_jump_held = Input.is_action_pressed("jump")

	if _jump_just_pressed:
		jump_buffer_timer.start()


func _update_facing() -> void:
	if _horizontal != 0.0:
		facing_direction = signi(_horizontal)
	sprite.scale.x = abs(sprite.scale.x) * facing_direction


# ---- Gravity ----

func _apply_gravity(delta: float) -> void:
	if state == PlayerState.WALL_SLIDE:
		velocity.y += WALL_SLIDE_GRAVITY * delta
		velocity.y = minf(velocity.y, WALL_SLIDE_MAX_SPEED)
		return
	velocity.y += GRAVITY * delta
	velocity.y = minf(velocity.y, MAX_FALL_SPEED)


# ---- State Dispatch ----

func _dispatch_state(delta: float) -> void:
	match state:
		PlayerState.IDLE:
			_process_idle()
		PlayerState.RUN:
			_process_run()
		PlayerState.JUMP:
			_process_jump(delta)
		PlayerState.DOUBLE_JUMP:
			_process_double_jump(delta)
		PlayerState.FALL:
			_process_fall(delta)
		PlayerState.WALL_SLIDE:
			_process_wall_slide()


# ---- IDLE ----

func _process_idle() -> void:
	sprite.play(&"idle")
	_apply_ground_friction()

	if _horizontal != 0.0:
		_transition_to(PlayerState.RUN)
		return

	if not is_on_floor():
		coyote_timer.start()
		_transition_to(PlayerState.FALL)
		return

	if _can_jump():
		_execute_jump()


# ---- RUN ----

func _process_run() -> void:
	sprite.play(&"run")
	_apply_ground_acceleration()

	if _horizontal == 0.0:
		_transition_to(PlayerState.IDLE)
		return

	if not is_on_floor():
		coyote_timer.start()
		_transition_to(PlayerState.FALL)
		return

	if _can_jump():
		_execute_jump()


# ---- JUMP ----

func _process_jump(delta: float) -> void:
	sprite.play(&"jump")
	_apply_air_horizontal(delta)
	_apply_variable_jump()

	if is_on_floor():
		if _horizontal != 0.0:
			_transition_to(PlayerState.RUN)
		else:
			_transition_to(PlayerState.IDLE)
		return

	if _can_wall_slide():
		_transition_to(PlayerState.WALL_SLIDE)
		return

	if _can_double_jump():
		_execute_double_jump()
		return

	if velocity.y > 0.0:
		_transition_to(PlayerState.FALL)


# ---- DOUBLE JUMP ----

func _process_double_jump(delta: float) -> void:
	sprite.play(&"double_jump")
	_apply_air_horizontal(delta)
	_apply_variable_jump()

	if is_on_floor():
		if _horizontal != 0.0:
			_transition_to(PlayerState.RUN)
		else:
			_transition_to(PlayerState.IDLE)
		return

	if _can_wall_slide():
		_transition_to(PlayerState.WALL_SLIDE)
		return

	if velocity.y > 0.0:
		_transition_to(PlayerState.FALL)


# ---- FALL ----

func _process_fall(delta: float) -> void:
	sprite.play(&"fall")
	_apply_air_horizontal(delta)

	if is_on_floor():
		if _consume_jump_buffer():
			_execute_jump()
		elif _horizontal != 0.0:
			_transition_to(PlayerState.RUN)
		else:
			_transition_to(PlayerState.IDLE)
		return

	if _can_wall_slide():
		_transition_to(PlayerState.WALL_SLIDE)
		return

	if _coyote_jump():
		_execute_jump()
		return

	if _can_double_jump():
		_execute_double_jump()


# ---- WALL SLIDE ----

func _process_wall_slide() -> void:
	sprite.play(&"wall_jump")

	if is_on_floor():
		if _horizontal != 0.0:
			_transition_to(PlayerState.RUN)
		else:
			_transition_to(PlayerState.IDLE)
		return

	if not is_on_wall():
		_transition_to(PlayerState.FALL)
		return

	if signi(_horizontal) != -signi(get_wall_normal().x):
		_transition_to(PlayerState.FALL)
		return

	if is_wall_jump_locked:
		return

	if _jump_just_pressed:
		_execute_wall_jump()


# ---- HIT (handled inline in _physics_process) ----


# ---- Movement Helpers ----

func _apply_ground_friction() -> void:
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * get_physics_process_delta_time())


func _apply_ground_acceleration() -> void:
	var target := _horizontal * MOVE_SPEED
	velocity.x = move_toward(velocity.x, target, ACCELERATION * get_physics_process_delta_time())


func _apply_air_horizontal(delta: float) -> void:
	if _horizontal != 0.0:
		var target := _horizontal * MOVE_SPEED
		velocity.x = move_toward(velocity.x, target, AIR_ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, AIR_FRICTION * delta)


func _apply_variable_jump() -> void:
	if not _jump_held and velocity.y < 0.0:
		velocity.y *= JUMP_RELEASE_MULTIPLIER


# ---- Jump Actions ----

func _execute_jump() -> void:
	velocity.y = JUMP_VELOCITY
	has_double_jump = true
	_consume_jump_buffer()
	jump_sfx.play()
	_transition_to(PlayerState.JUMP)


func _execute_double_jump() -> void:
	velocity.y = DOUBLE_JUMP_VELOCITY
	has_double_jump = false
	_consume_jump_buffer()
	jump_sfx.play()
	_transition_to(PlayerState.DOUBLE_JUMP)


func _execute_wall_jump() -> void:
	var wall_normal := get_wall_normal()
	velocity.y = WALL_JUMP_VERTICAL
	velocity.x = wall_normal.x * WALL_JUMP_HORIZONTAL
	facing_direction = -signi(wall_normal.x)
	sprite.scale.x = abs(sprite.scale.x) * facing_direction
	is_wall_jump_locked = true
	wall_jump_lockout_timer.start()
	has_double_jump = true
	jump_sfx.play()
	_transition_to(PlayerState.JUMP)


# ---- Condition Checks ----

func _can_jump() -> bool:
	return _jump_just_pressed


func _can_double_jump() -> bool:
	return _jump_just_pressed and has_double_jump


func _coyote_jump() -> bool:
	return _jump_just_pressed and not coyote_timer.is_stopped()


func _consume_jump_buffer() -> bool:
	if not jump_buffer_timer.is_stopped():
		jump_buffer_timer.stop()
		return true
	return false


func _can_wall_slide() -> bool:
	return (
		is_on_wall()
		and not is_on_floor()
		and _horizontal != 0.0
		and signi(_horizontal) == -signi(get_wall_normal().x)
		and not is_wall_jump_locked
	)


# ---- Post-Move Checks ----

func _post_move_checks() -> void:
	# Update wall-jump lockout: re-enable wall slide when not pressing toward wall
	if is_wall_jump_locked and not is_on_wall():
		is_wall_jump_locked = false
		wall_jump_lockout_timer.stop()


# ---- State Transitions ----

func _transition_to(new_state: PlayerState) -> void:
	state = new_state


# ---- Timer Callbacks ----

func _on_coyote_timer_timeout() -> void:
	pass


func _on_jump_buffer_timer_timeout() -> void:
	pass


func _on_wall_jump_lockout_timeout() -> void:
	is_wall_jump_locked = false
