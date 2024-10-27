extends Node2D

# Variables
var speed = 60  # Movement speed of the bat
var detection_radius = 200  # Radius to detect the player
var attack_radius = 40  # Radius to trigger the attack animation
var idle_distance = 300  # Distance after which the bat returns to idle
var target_position = Vector2.ZERO  # Target position to fly towards
var is_chasing = false  # State if the bat is chasing the player
var is_attacking = false  # To track if the bat is attacking
var idle_position = Vector2.ZERO  # Position where the bat idles
var y_offset = -30  # Y offset to fly above the player
var return_to_idle_speed = 80  # Speed of the bat when returning to the idle position
var has_woken_up = false  # To track if wake_up animation has played

# Use onready to get the player reference and AnimatedSprite2D
@onready var player: CharacterBody2D = $"../player"  # Adjust this path based on your player location
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D  # Reference to the AnimatedSprite2D node
@onready var raycast: RayCast2D = $RayCast2D  # Raycast to detect the nearest block

# Called when the node enters the scene tree for the first time
func _ready():
	# Store the idle position (assume the position under the top platform is where the bat starts)
	idle_position = position
	sprite.play("idle")  # Start with the idle animation
	raycast.enabled = true  # Enable the raycast to detect collisions

	# Connect the animation_finished signal
	sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))

# Main game loop
func _process(delta):
	if is_player_near():
		if is_player_in_attack_range():
			perform_attack()
		else:
			if not has_woken_up:
				wake_up()  # Start with wake_up animation
			else:
				chase_player(delta)  # Transition to fly after wake_up
	elif is_player_too_far():
		move_to_idle_position(delta)  # Move bat to nearest block above and idle
	else:
		idle(delta)

	# Handle horizontal flipping based on the bat's position relative to the player
	update_sprite_direction()

# Function to handle animation transitions after wake_up is finished
func _on_animation_finished():
	if sprite.animation == "wake_up":
		# After wake_up, if the player is still near, switch to fly
		if is_player_near():
			sprite.play("fly")
		else:
			# If the player is too far, switch to idle
			sprite.play("idle")

# Function to start the wake_up animation
func wake_up():
	if not has_woken_up:
		has_woken_up = true
		sprite.play("wake_up")

# Function to check if the player is within detection range
func is_player_near() -> bool:
	if player:
		var distance_to_player = position.distance_to(player.position)
		return distance_to_player < detection_radius
	return false

# Function to check if the player is within attack range
func is_player_in_attack_range() -> bool:
	if player:
		var distance_to_player = position.distance_to(player.position)
		return distance_to_player < attack_radius
	return false

# Function to check if the player is too far
func is_player_too_far() -> bool:
	if player:
		var distance_to_player = position.distance_to(player.position)
		return distance_to_player > idle_distance
	return false

# Function to chase the player (fly)
func chase_player(delta):
	if player:
		# Fly towards the player's position but stay higher on the Y axis
		target_position = player.position
		target_position.y += y_offset  # Add an offset to fly above the player
		
		var direction = (target_position - position).normalized()
		position += direction * speed * delta

		# If not already playing fly animation, switch to fly
		if sprite.animation != "fly":
			sprite.play("fly")

# Function to idle in place
func idle(delta):
	has_woken_up = false  # Reset wake_up status when bat goes idle
	# If not already playing idle animation, switch to idle
	if sprite.animation != "idle":
		sprite.play("idle")

# Function to perform the attack
func perform_attack():
	if sprite.animation != "attack":
		sprite.play("attack")
	# You can add logic for damage or other attack behaviors here

# Function to update the direction the sprite is facing
func update_sprite_direction():
	if player:
		# If the bat is to the left of the player, it should face right (no flip)
		if position.x > player.position.x:
			sprite.flip_h = false
		# If the bat is to the right of the player, it should face left (flip horizontally)
		else:
			sprite.flip_h = true

# Function to move the bat back to the idle position (nearest block above)
func move_to_idle_position(delta):
	# Set the length and direction of the raycast upwards to find the nearest block
	raycast.target_position = Vector2(0, -100)  # Set the ray to cast upwards
	raycast.force_raycast_update()

	# Block height adjustment
	var block_height = 16  # Adjust this to match the actual height of the block

	# Declare the target_idle_position before the if block
	var target_idle_position = Vector2()

	if raycast.is_colliding():
		# If the raycast detects a block, set the bat's target position to the bottom of the block
		var collision_point = raycast.get_collision_point()
		target_idle_position = Vector2(collision_point.x, collision_point.y + block_height)  # Set the target to the bottom of the block
	else:
		# If no block is found, fall back to a default position above the bat's original idle position
		target_idle_position = idle_position

	var direction = (target_idle_position - position).normalized()
	position += direction * return_to_idle_speed * delta

	# Once the bat reaches the idle position, switch to idle animation
	if position.distance_to(target_idle_position) < 5:  # A small threshold to check proximity to the block
		sprite.play("idle")
		is_chasing = false
