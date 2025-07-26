extends CombatEntity

var attack_hitbox := preload("res://scripts/AttackHitbox.gd").new()

@export var detection_range := 150.0
@export var attack_range := 80.0
@export var target_path := NodePath("/root/Main/Player")

var player: Node = null

func _ready():
	add_to_group("enemy")

	controller = CombatController.new()
	create_attack_hitbox()
	setup_combat_controller()
	
	create_sprite()
	create_collision()
	create_hurtbox()
	setup_audio()

	controller.attack_startup = 0.6
	controller.attack_duration = 0.4
	controller.attack_cooldown = 0.5
	controller.parry_window = 0.2
	controller.parry_cooldown = 0.5
	controller.post_parry_stun = 0.8

	player = get_node_or_null(target_path)

func _process(delta):
	if not player:
		return

	var distance = global_position.distance_to(player.global_position)

	if controller.can_act() and controller.queued_action == CombatController.ActionType.NONE:
		if distance <= attack_range:
			controller.try_attack()
		elif distance <= detection_range:
			move_toward_player()

	controller._process(delta)

func move_toward_player():
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
	rect.size = Vector2(64, 64)  # Menor que a hitbox para evitar sobreposição
	shape.shape = rect
	shape.position = Vector2.ZERO  # Centralizada

	hurtbox.add_child(shape)
	hurtbox.position = Vector2(0, 0)  # 🔁 Move para trás do ponto onde a hitbox aparece

	hurtbox.set_collision_layer_value(2, true)  # Hurtbox layer
	hurtbox.set_collision_mask_value(1, true)   # Colide com player hitbox
	hurtbox.add_to_group("hurtbox")
	add_child(hurtbox)
