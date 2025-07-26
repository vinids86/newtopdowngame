class_name CombatController
extends Node

signal hitbox_enabled()
signal hitbox_disabled()
signal play_sound(path: String)

enum CombatState {
	IDLE,
	STARTUP,
	ATTACKING,
	PARRY_ACTIVE,
	RECOVERING,
	STUNNED,
	GUARD_BROKEN
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
@export var parry_cooldown := 1.5
@export var post_parry_stun := 0.8
@export var input_buffer_duration := 0.4
@export var recovery_duration := 0.3

var combat_state: CombatState = CombatState.IDLE
var state_timer: float = 0.0
var owner_node: Node

var queued_action: ActionType = ActionType.NONE
var buffer_timer: float = 0.0
var status_effects: Dictionary = {}

var transitions := {
	CombatState.IDLE: [CombatState.STARTUP, CombatState.PARRY_ACTIVE],
	CombatState.STARTUP: [CombatState.ATTACKING, CombatState.PARRY_ACTIVE],
	CombatState.ATTACKING: [CombatState.RECOVERING],
	CombatState.RECOVERING: [CombatState.IDLE],
	CombatState.PARRY_ACTIVE: [CombatState.IDLE],
	CombatState.STUNNED: [CombatState.IDLE],
	CombatState.GUARD_BROKEN: [CombatState.IDLE]
}

func setup(owner: Node):
	owner_node = owner

func _process(delta):
	if buffer_timer > 0:
		buffer_timer -= delta
		if buffer_timer <= 0:
			queued_action = ActionType.NONE

	if state_timer > 0:
		state_timer -= delta
		if state_timer <= 0:
			match combat_state:
				CombatState.STARTUP:
					change_state(CombatState.ATTACKING)
				CombatState.ATTACKING:
					change_state(CombatState.RECOVERING)
				CombatState.RECOVERING, CombatState.PARRY_ACTIVE:
					change_state(CombatState.IDLE)
				CombatState.STUNNED:
					change_state(CombatState.IDLE)
				CombatState.GUARD_BROKEN:
					change_state(CombatState.IDLE)

	var expired = []
	for effect_name in status_effects.keys():
		status_effects[effect_name] -= delta
		if status_effects[effect_name] <= 0:
			expired.append(effect_name)

	for effect_name in expired:
		status_effects.erase(effect_name)

func change_state(new_state: CombatState):
	if owner_node.is_in_group("player"):
		var from_name = CombatState.keys()[combat_state]
		var to_name = CombatState.keys()[new_state]
		print("🔄 Tentando transição: %s → %s" % [from_name, to_name])

	if not transitions.get(combat_state, []).has(new_state):
		if owner_node.is_in_group("player"):
			print("❌ Transição inválida: %s → %s" % [
				CombatState.keys()[combat_state],
				CombatState.keys()[new_state]
			])
		return

	_on_exit_state(combat_state)
	combat_state = new_state
	_on_enter_state(combat_state)

func _on_enter_state(state: CombatState):
	match state:
		CombatState.STARTUP:
			state_timer = attack_startup
			owner_node.modulate = Color.YELLOW
		CombatState.ATTACKING:
			state_timer = attack_duration
			hitbox_enabled.emit()
			play_sound.emit("res://sfx/hit.wav")
			owner_node.modulate = Color.RED
		CombatState.PARRY_ACTIVE:
			state_timer = parry_window
			play_sound.emit("res://sfx/parry.wav")
			owner_node.modulate = Color.BLUE
		CombatState.RECOVERING:
			state_timer = recovery_duration
			owner_node.modulate = Color.DARK_GRAY
		CombatState.STUNNED:
			state_timer = post_parry_stun
			owner_node.modulate = Color.PURPLE
			play_sound.emit("res://sfx/parry.wav")
		CombatState.GUARD_BROKEN:
			state_timer = post_parry_stun * 1.5
			owner_node.modulate = Color.DARK_RED
			play_sound.emit("res://sfx/guard_break.wav")
		CombatState.IDLE:
			owner_node.modulate = Color.GRAY
			try_execute_buffer()

func _on_exit_state(state: CombatState):
	if state == CombatState.ATTACKING:
		hitbox_disabled.emit()
	elif state == CombatState.PARRY_ACTIVE:
		apply_effect("parry_cooldown", parry_cooldown)

func apply_effect(name: String, duration: float):
	status_effects[name] = duration

func has_effect(name: String) -> bool:
	return status_effects.has(name)

func try_execute_buffer():
	if not can_act():
		return
	match queued_action:
		ActionType.ATTACK:
			if try_attack(true):
				queued_action = ActionType.NONE
		ActionType.PARRY:
			if try_parry(true):
				queued_action = ActionType.NONE

func try_attack(from_buffer := false):
	if combat_state == CombatState.IDLE:
		change_state(CombatState.STARTUP)
		return true
	elif not from_buffer:
		queued_action = ActionType.ATTACK
		buffer_timer = input_buffer_duration
	return false

func try_parry(from_buffer := false):
	if combat_state in [CombatState.PARRY_ACTIVE, CombatState.STUNNED, CombatState.GUARD_BROKEN]:
		return false

	if has_effect("parry_cooldown"):
		return false

	if combat_state in [CombatState.IDLE, CombatState.STARTUP]:
		change_state(CombatState.PARRY_ACTIVE)
		if not from_buffer:
			queued_action = ActionType.NONE
			buffer_timer = 0
		return true

	if not from_buffer:
		queued_action = ActionType.PARRY
		buffer_timer = input_buffer_duration

	return false

func on_parried():
	change_state(CombatState.GUARD_BROKEN)

func on_blocked():
	change_state(CombatState.RECOVERING)
	play_sound.emit("res://sfx/block.wav")

func on_parry_failed():
	change_state(CombatState.STUNNED)

func can_act() -> bool:
	return combat_state == CombatState.IDLE
