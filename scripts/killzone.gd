extends Area2D

@onready var timer: Timer = $Timer

func _on_body_entered(body):
	if body is CharacterBody2D:
		print("Player died :(")
		Engine.time_scale = 0.5
		
		# Trigger the player's die animation
		body.die()

		# Start the timer after playing the die animation
		timer.start()

func _on_timer_timeout() -> void:
	Engine.time_scale = 1
	get_tree().reload_current_scene()
