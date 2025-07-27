extends CharacterBody2D
class_name Enemy

# Resultado da defesa
enum DefenseResult {
	HIT,
	BLOCKED,
	PARRIED
}

@export var max_hp := 10
var current_hp := max_hp

@export var max_stamina := 100.0
var current_stamina := max_stamina

var controller: CombatController
var sprite: Sprite2D
var collision: CollisionShape2D
var audio: AudioStreamPlayer2D

var attack_hitbox := preload("res://scripts/AttackHitbox.gd").new()
@export var detection_range := 150.0
@export var attack_range := 80.0
@export var target_path := NodePath("/root/Main/Player")
var player: Node = null

@export var parry_chance := 0.8

@export var stamina_recovery_rate := 20.0  # unidades por segundo
@export var stamina_recovery_delay := 1.0  # segundos após ação para começar a recuperar
var stamina_recovery_timer := 0.0

var parry_cooldown_timer := 0.0

func _ready():
	add_to_group("enemy")

	controller = CombatController.new()
	controller.parry_window = 0.3
	create_attack_hitbox()
	setup_combat_controller()
	create_sprite()
	create_collision()
	create_hurtbox()
	setup_audio()

	player = get_node_or_null(target_path)

func _process(delta):
	if not player:
		return

	parry_cooldown_timer -= delta

	var distance = global_position.distance_to(player.global_position)

	# Tenta parry se player está perto E em startup
	if distance <= attack_range and parry_cooldown_timer <= 0:
		if player.controller.combat_state == CombatController.CombatState.STARTUP:
			try_parry()

	# Se pode agir, tenta atacar
	if controller.can_act() and controller.queued_action == CombatController.ActionType.NONE:
		if distance <= attack_range:
			controller.try_attack()
		elif distance <= detection_range:
			move_toward_player()

	controller._process(delta)

	if controller.can_act():
		if stamina_recovery_timer <= 0.0:
			current_stamina = clamp(current_stamina + stamina_recovery_rate * delta, 0, max_stamina)
		else:
			stamina_recovery_timer -= delta

func try_parry():
	if randf() <= parry_chance:
		var success = controller.try_parry()
		if success:
			parry_cooldown_timer = 1.0  # evita spammar o parry

func move_toward_player():
	if controller.combat_state in [CombatController.CombatState.STUNNED, CombatController.CombatState.GUARD_BROKEN]:
		velocity = Vector2.ZERO
		return

	var direction = (player.global_position - global_position).normalized()
	velocity = direction * 60
	move_and_slide()

func setup_combat_controller():
	add_child(controller)
	controller.setup(self)
	controller.hitbox_enabled.connect(attack_hitbox.enable.bind(Vector2(0, 64)))
	controller.hitbox_disabled.connect(attack_hitbox.disable)
	controller.play_sound.connect(play_sound)

func create_attack_hitbox():
	attack_hitbox = preload("res://scripts/AttackHitbox.gd").new()
	attack_hitbox.set_collision_layers(3, 4)  # Enemy hitbox (layer 3) colide com player hurtbox (layer 4)
	add_child(attack_hitbox)

func create_hurtbox():
	var hurtbox := Area2D.new()
	hurtbox.name = "EnemyHurtbox"

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(64, 64)
	shape.shape = rect
	shape.position = Vector2.ZERO

	hurtbox.add_child(shape)
	hurtbox.position = Vector2(0, 0)

	hurtbox.set_collision_layer_value(2, true)
	hurtbox.set_collision_mask_value(1, true)
	add_child(hurtbox)

func create_sprite():
	sprite = Sprite2D.new()
	sprite.texture = preload("res://assets/white_square.png")
	sprite.modulate = Color.WHITE
	sprite.centered = true
	add_child(sprite)

func create_collision():
	collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	if sprite and sprite.texture:
		shape.extents = sprite.texture.get_size() / 2
	else:
		shape.extents = Vector2(16, 16)
	collision.shape = shape
	add_child(collision)

func setup_audio():
	audio = AudioStreamPlayer2D.new()
	add_child(audio)

func play_sound(path: String):
	if not audio:
		return
	audio.stream = load(path)
	audio.play()

func take_damage(amount: int, attacker: Node) -> int:
	if not controller:
		print("❌ Entidade sem controller.")
		return DefenseResult.HIT

	if controller.combat_state in [
		CombatController.CombatState.PARRY_ACTIVE,
		CombatController.CombatState.PARRY_SUCCESS,
	]:
		print("⚡ Defesa foi um parry bem-sucedido!")
		controller.did_parry_succeed = true
		return DefenseResult.PARRIED

	elif controller.combat_state in [
		CombatController.CombatState.IDLE,
		CombatController.CombatState.RECOVERING,
		CombatController.CombatState.STUNNED,
		CombatController.CombatState.PARRY_MISS,
	]:
		controller.on_blocked()
		return DefenseResult.BLOCKED

	elif controller.combat_state in [
		CombatController.CombatState.STARTUP,
		CombatController.CombatState.GUARD_BROKEN
	]:
		current_hp -= amount
		if current_hp <= 0:
			die()
		else:
			controller.change_state(CombatController.CombatState.STUNNED)
		return DefenseResult.HIT

	else:
		print("⚠️ Estado de combate inesperado: %s" % controller.combat_state)
		current_hp -= amount
		if current_hp <= 0:
			die()
		return DefenseResult.HIT

func die():
	queue_free()
	print("☠ ", self.name, " morreu.")

func on_parried():
	print("⛔ Enemy foi parryado! Entrando em GUARD_BROKEN.")
	controller.on_parried()

func on_blocked():
	controller.on_blocked()

func has_stamina(amount: float) -> bool:
	return current_stamina >= amount

func consume_stamina(amount: float):
	var previous = current_stamina
	current_stamina = clamp(current_stamina - amount, 0, max_stamina)
	if previous > current_stamina:
		stamina_recovery_timer = stamina_recovery_delay
