extends CharacterBody2D

# Resultado da defesa
enum DefenseResult {
	HIT,
	BLOCKED,
	PARRIED
}

@export var speed := 150.0
@export var max_hp := 10
var current_hp := max_hp

var attack_hitbox := preload("res://scripts/AttackHitbox.gd").new()
var controller: CombatController
var sprite: Sprite2D
var collision: CollisionShape2D
var audio: AudioStreamPlayer2D

func _ready():
	add_to_group("player")

	controller = CombatController.new()
	create_attack_hitbox()
	setup_combat_controller()

	create_sprite()
	create_collision()
	create_hurtbox()
	setup_audio()

func _process(delta):
	handle_input()
	handle_movement()
	controller._process(delta)

func handle_input():
	if Input.is_action_just_pressed("attack"):
		print("🖱️ Input de ataque detectado!")
		controller.try_attack()
	elif Input.is_action_just_pressed("parry"):
		controller.try_parry()

func handle_movement():
	if controller.combat_state in [CombatController.CombatState.STUNNED, CombatController.CombatState.GUARD_BROKEN, CombatController.CombatState.PARRY_MISS, CombatController.CombatState.PARRY_ACTIVE]:
		velocity = Vector2.ZERO
		return

	var direction = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()

	velocity = direction * speed
	move_and_slide()

func setup_combat_controller():
	add_child(controller)
	controller.setup(self)
	controller.hitbox_enabled.connect(attack_hitbox.enable.bind(Vector2(0, -64)))
	controller.hitbox_disabled.connect(attack_hitbox.disable)
	controller.play_sound.connect(play_sound)

func create_attack_hitbox():
	attack_hitbox = preload("res://scripts/AttackHitbox.gd").new()
	attack_hitbox.set_collision_layers(1, 2)  # Player hitbox (layer 1) colide com enemy hurtbox (layer 2)
	add_child(attack_hitbox)

func create_hurtbox():
	var hurtbox := Area2D.new()
	hurtbox.name = "PlayerHurtbox"
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(64, 64)
	shape.position = Vector2.ZERO
	hurtbox.add_child(shape)
	hurtbox.set_collision_layer_value(4, true)  # Player hurtbox = layer 4
	hurtbox.set_collision_mask_value(3, true)   # Colide com enemy hitbox (layer 3)
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

# Lógica de combate direta (substitui CombatEntity)
func take_damage(amount: int, attacker: Node) -> int:
	if not controller:
		print("❌ Entidade sem controller.")
		return DefenseResult.HIT

	if controller.combat_state == CombatController.CombatState.PARRY_ACTIVE:
		print("⚡ Defesa foi um parry bem-sucedido!")
		controller.did_parry_succeed = true
		return DefenseResult.PARRIED

	elif controller.combat_state in [
		CombatController.CombatState.IDLE,
		CombatController.CombatState.RECOVERING,
		CombatController.CombatState.STUNNED
	]:
		controller.on_blocked()
		return DefenseResult.BLOCKED

	# Leva dano, entra em STUNNED se sobreviver
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
	print("⛔ Player foi parryado! Entrando em GUARD_BROKEN.")
	controller.on_parried()
	
func on_blocked():
	print("🛡️ Player bloqueou o ataque. Entrando em STUNNED.")
	if controller.owner_node == self:
		controller.on_blocked()
	else:
		print("❌ controller.owner_node aponta para outro nó!:", controller.owner_node.name)
	controller.on_blocked()
	
