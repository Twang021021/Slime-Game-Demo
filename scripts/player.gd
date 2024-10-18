extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -300.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_alive = true
var is_attacking = false  # Prevents movement during attack

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	if is_alive:
		# Apply gravity
		if not is_on_floor():
			velocity.y += gravity * delta

		# Handle jumping
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			animated_sprite.play("jump")  # Always play jump animation on jump

		# Handle attack (swallow)
		if Input.is_action_just_pressed("attack") and not is_attacking:
			play_swallow_animation()

		# Handle movement if not attacking
		if not is_attacking:
			handle_movement()

		# Apply velocity
		move_and_slide()

		# Handle animation after landing from a jump
		if is_on_floor() and not is_attacking:
			if velocity.x != 0:
				animated_sprite.play("move")
			else:
				animated_sprite.play("idle")
		elif not is_on_floor() and animated_sprite.animation != "jump":
			animated_sprite.play("jump")  # Ensure jump animation plays while in the air

func handle_movement():
	var direction := Input.get_axis("move_left", "move_right")

	if direction != 0:
		velocity.x = direction * SPEED
		animated_sprite.flip_h = direction < 0
		
		# Only play move animation if on the ground
		if is_on_floor() and not is_attacking:
			animated_sprite.play("move")
	else:
		velocity.x = 0
		if is_on_floor() and not is_attacking:
			animated_sprite.play("idle")

func play_swallow_animation():
	is_attacking = true
	animated_sprite.play("swallow")

	# Wait for the attack animation to finish before resuming movement
	await get_tree().create_timer(0.5).timeout  # Adjust the duration to match the length of the "swallow" animation
	is_attacking = false

func die():
	if is_alive:
		is_alive = false
		animated_sprite.play("die")
		await get_tree().create_timer(1.0).timeout  # Adjust to match your death animation duration
		get_tree().reload_current_scene()  # Restart the game after death
