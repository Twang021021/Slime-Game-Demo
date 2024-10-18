extends Node2D

const RUN_SPEED = 50.0
const CHARGE_DISTANCE = 100.0  # Fixed distance to charge during the attack
const CHARGE_SPEED = 100.0  # Speed of the charge
var is_stunned = false
var is_attacking = false
var is_running = false
var charge_distance_remaining = 0.0  # Distance left to charge
var direction_to_player = 0  # Track the direction to the player

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var raycast_right = $RayCast2D_right
@onready var raycast_left = $RayCast2D_left
@onready var killZone = $killZone
@onready var player: CharacterBody2D = $"../Player"  # Reference to the player

func _ready():
	raycast_right.enabled = true
	raycast_left.enabled = true

	# Connect the killzone signal for handling when the player touches the killzone
	if killZone:
		killZone.connect("body_entered", Callable(self, "_on_killzone_body_entered"))

	# Set initial idle animation
	animated_sprite.play("mushroom_idle")

func _process(delta: float) -> void:
	if not is_stunned:
		if is_attacking:
			# Continue charging while attacking
			continue_charge(delta)
		elif detect_player():
			# Run towards the player if detected
			run_towards_player(delta)
		else:
			# Idle when not running or attacking
			if not is_running:
				animated_sprite.play("mushroom_idle")

func detect_player() -> bool:
	return raycast_right.is_colliding() or raycast_left.is_colliding()

func run_towards_player(delta: float):
	is_running = true
	animated_sprite.play("mushroom_run")

	# Calculate the direction to the player (1 for right, -1 for left)
	direction_to_player = sign(player.global_position.x - global_position.x)

	# Move towards the player
	position.x += direction_to_player * RUN_SPEED * delta

	# Flip the sprite based on the direction
	animated_sprite.flip_h = direction_to_player > 0  # Flip only if moving right

	# If the player is close enough, trigger the charge attack
	if abs(player.global_position.x - global_position.x) < 50:
		start_charge_attack()

func start_charge_attack():
	is_running = false
	is_attacking = true

	# Set the initial distance to charge
	charge_distance_remaining = CHARGE_DISTANCE

	# Play the attack animation
	animated_sprite.play("mushroom_attack")

func continue_charge(delta: float):
	# Continue charging if there's charge distance remaining
	if charge_distance_remaining > 0:
		var charge_step = CHARGE_SPEED * delta

		# Decrease the remaining charge distance
		charge_distance_remaining -= charge_step

		# Charge in the direction of the player, using the calculated direction
		position.x += charge_step * direction_to_player

		# Stop attacking once the charge distance is covered
		if charge_distance_remaining <= 0:
			finish_attack()

func finish_attack():
	is_attacking = false
	charge_distance_remaining = 0
	stun_mushroom()

func stun_mushroom():
	is_stunned = true
	animated_sprite.play("mushroom_stun")
	
	# Stun the mushroom for 2 seconds
	await get_tree().create_timer(2.0).timeout
	is_stunned = false

func _on_killzone_body_entered(body):
	if body is CharacterBody2D:
		body.die()  # Trigger the player's death
