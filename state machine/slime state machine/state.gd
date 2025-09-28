extends Node

class_name SlimeState

# Reference to the state machine and slime
var state_machine: SlimeStateMachine = null
var slime: CharacterBody2D = null
var animated_sprite: AnimatedSprite2D = null

# Called when the state is entered
func enter() -> void:
	pass

# Called when the state is exited
func exit() -> void:
	pass

# Called every frame
func update(_delta: float) -> void:
	pass

# Called every physics frame
func physics_update(_delta: float) -> void:
	pass

# Handle damage taken while in this state
func take_damage(_amount: int) -> void:
	pass
