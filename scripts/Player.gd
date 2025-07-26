# Player.gd
extends CombatEntity

@export var speed := 150.0

var attack_hitbox := preload("res://scripts/AttackHitbox.gd").new()

func _ready():
	controller = CombatController.new()
	setup_combat_controller()
	create_sprite()
	create_collision()
	create_attack_hitbox()
	setup_audio()

	# Configurações específicas de combate
	controller.attack_startup = 0.6
	controller.attack_duration = 0.4
	controller.attack_cooldown = 0.5
	controller.parry_window = 0.2
	controller.parry_cooldown = 1.5
	controller.post_parry_stun = 0.8

func _process(delta):
	handle_input()
	handle_movement()
	controller._process(delta)

func handle_input():
	if Input.is_action_just_pressed("attack"):
		controller.try_attack()
	elif Input.is_action_just_pressed("parry"):
		controller.try_parry()

func handle_movement():
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
	add_child(attack_hitbox)
