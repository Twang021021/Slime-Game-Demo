extends Node2D

const SPEED = 100.0
var move_direction = 1  # 1 for right, -1 for left

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var raycast_right = $RayCastRight
@onready var raycast_left = $RayCastLeft
@onready var killZone = $killZone

func _ready():
	# Correct connect function to use Callable in Godot 4
	killZone.connect("body_entered", Callable(self, "_on_killzone_body_entered"))

func _process(delta: float) -> void:
	# Handle automatic movement (patrolling)
	handle_movement()

func handle_movement():
	# Move the enemy along the x-axis
	position.x += move_direction * SPEED * get_process_delta_time()

	# Flip the sprite and use the correct raycast based on movement direction
	if move_direction > 0:
		animated_sprite.flip_h = false
		raycast_right.enabled = true
		raycast_left.enabled = false
		if raycast_right.is_colliding():
			move_direction *= -1  # Reverse direction
	else:
		animated_sprite.flip_h = true
		raycast_right.enabled = false
		raycast_left.enabled = true
		if raycast_left.is_colliding():
			move_direction *= -1  # Reverse direction

func _on_killzone_body_entered(body):
	if body.name == "Player":
		body.die()  # Trigger the player's death
