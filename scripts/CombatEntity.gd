extends CharacterBody2D
class_name CombatEntity

# Resultado da defesa
enum DefenseResult {
	HIT,
	BLOCKED,
	PARRIED
}

@export var max_hp := 10
var current_hp := max_hp

var controller: CombatController
var sprite: Sprite2D
var collision: CollisionShape2D
var audio: AudioStreamPlayer2D

func _ready():
	# Espera que o controller seja atribuído no filho
	pass

func take_damage(amount: int, attacker: Node) -> int:
	if not controller:
		print("❌ Entidade sem controller.")
		return DefenseResult.HIT

	if controller.combat_state == CombatController.CombatState.PARRY_ACTIVE:
		print("⚡ Defesa foi um parry bem-sucedido!")
		return DefenseResult.PARRIED

	elif controller.combat_state == CombatController.CombatState.STARTUP:
		controller.on_blocked()
		return DefenseResult.BLOCKED

	else:
		current_hp -= amount
		if current_hp <= 0:
			die()
		return DefenseResult.HIT

func die():
	queue_free()
	print("☠ ", self.name, " morreu.")

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
		var tex_size = sprite.texture.get_size()
		shape.extents = tex_size / 2
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

func on_parried():
	print("⚠️ on_parried() chamado em CombatEntity (override esperado).")
	controller.on_parried()
