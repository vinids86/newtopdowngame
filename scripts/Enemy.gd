# Enemy.gd
extends CombatEntity

var attack_hitbox := preload("res://scripts/AttackHitbox.gd").new()

@export var detection_range := 150.0
@export var attack_range := 80.0
@export var target_path := NodePath("/root/Main/Player")

var player: Node = null

func _ready():
	controller = CombatController.new()
	create_sprite()
	create_collision()
	create_attack_hitbox()
	setup_audio()
	setup_combat_controller()

	# Configurações específicas de combate
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
	add_child(attack_hitbox)
