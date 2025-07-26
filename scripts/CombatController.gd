# CombatController.gd
class_name CombatController
extends Node

signal hitbox_enabled()
signal hitbox_disabled()
signal play_sound(path: String)

enum CombatState {
	IDLE,
	STARTUP,
	ATTACKING,
	PARRY_ACTIVE
}

enum ActionType {
	NONE,
	ATTACK,
	PARRY
}

@export var attack_startup := 0.4
@export var attack_duration := 0.3
@export var attack_cooldown := 0.5
@export var parry_window := 0.2
@export var parry_cooldown := 0.5
@export var post_parry_stun := 0.8
@export var input_buffer_duration := 0.4

var combat_state: CombatState = CombatState.IDLE
var state_timer: float = 0.0
var status_effects: Dictionary = {}
var owner_node: Node

var queued_action: ActionType = ActionType.NONE
var buffer_timer: float = 0.0

func setup(owner: Node):
	owner_node = owner

func _process(delta):
	for key in status_effects.keys():
		status_effects[key] -= delta
		if status_effects[key] <= 0:
			status_effects.erase(key)

	if buffer_timer > 0:
		buffer_timer -= delta
		if buffer_timer <= 0:
			queued_action = ActionType.NONE

	if state_timer > 0:
		state_timer -= delta
		if state_timer <= 0:
			_end_current_state()

func _end_current_state():
	match combat_state:
		CombatState.STARTUP:
			combat_state = CombatState.ATTACKING
			state_timer = attack_duration
			hitbox_enabled.emit()
			owner_node.modulate = Color.RED
			play_sound.emit("res://sfx/hit.wav")

		CombatState.ATTACKING:
			combat_state = CombatState.IDLE
			hitbox_disabled.emit()
			owner_node.modulate = Color.GRAY
			apply_effect("attack_cooldown", attack_cooldown)

		CombatState.PARRY_ACTIVE:
			combat_state = CombatState.IDLE
			apply_effect("parry_cooldown", parry_cooldown)
			owner_node.modulate = Color.GRAY

	try_execute_buffer()
	apply_effect("attack_cooldown", attack_cooldown)

func apply_effect(name: String, duration: float):
	status_effects[name] = duration

func has_effect(name: String) -> bool:
	return status_effects.has(name)

func try_execute_buffer():
	if has_effect("stunned") or has_effect("attack_cooldown"):
		return

	match queued_action:
		ActionType.ATTACK:
			if try_attack(true):
				queued_action = ActionType.NONE
		ActionType.PARRY:
			if try_parry(true):
				queued_action = ActionType.NONE

func try_attack(from_buffer := false):
	if combat_state == CombatState.IDLE and not has_effect("stunned") and not has_effect("attack_cooldown"):
		combat_state = CombatState.STARTUP
		state_timer = attack_startup
		owner_node.modulate = Color.YELLOW
		return true
	elif not from_buffer:
		queued_action = ActionType.ATTACK
		buffer_timer = input_buffer_duration
	return false

func try_parry(from_buffer := false):
	if combat_state == CombatState.PARRY_ACTIVE:
		return false
	if has_effect("parry_cooldown") or has_effect("stunned"):
		return false

	if combat_state == CombatState.STARTUP:
		combat_state = CombatState.PARRY_ACTIVE
		state_timer = parry_window
		owner_node.modulate = Color.BLUE
		play_sound.emit("res://sfx/parry.wav")
		queued_action = ActionType.NONE
		buffer_timer = 0
		return true

	if combat_state == CombatState.IDLE:
		combat_state = CombatState.PARRY_ACTIVE
		state_timer = parry_window
		owner_node.modulate = Color.BLUE
		play_sound.emit("res://sfx/parry.wav")
		return true
	elif not from_buffer:
		queued_action = ActionType.PARRY
		buffer_timer = input_buffer_duration
	return false

func on_parried():
	apply_effect("stunned", post_parry_stun)
	combat_state = CombatState.IDLE
	state_timer = 0.0
	owner_node.modulate = Color.PURPLE
	play_sound.emit("res://sfx/parry.wav")

func on_blocked():
	play_sound.emit("res://sfx/block.wav")

func can_act() -> bool:
	return combat_state == CombatState.IDLE and not has_effect("stunned") and not has_effect("attack_cooldown")
