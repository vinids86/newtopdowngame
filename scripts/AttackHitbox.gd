# AttackHitbox.gd
extends Area2D

var shape := RectangleShape2D.new()
var visual := Sprite2D.new()

const DefenseResult = CombatEntity.DefenseResult

func _init():
	var collision := CollisionShape2D.new()
	shape.size = Vector2(64, 64)
	collision.shape = shape
	add_child(collision)

	visual.texture = preload("res://assets/white_square.png")
	visual.modulate = Color(1, 0, 0, 0.4)
	visual.visible = false
	add_child(visual)

	monitoring = false
	visible = false
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)

func enable(pos: Vector2):
	position = pos
	monitoring = true
	visible = true
	visual.visible = true

func disable():
	monitoring = false
	visible = false
	visual.visible = false

func _ready():
	connect("area_entered", _on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if not monitoring:
		return

	# Valida o alvo
	if not area.is_in_group("hurtbox"):
		return

	var defender = area.get_parent()
	var attacker = get_parent()

	if not defender.has_method("take_damage"):
		return

	# Aplica dano e interpreta resultado
	var result = defender.take_damage(1, attacker)

	if attacker.has("controller"):
		var controller = attacker.controller

		match result:
			DefenseResult.PARRIED:
				controller.on_parried()
			DefenseResult.BLOCKED:
				controller.on_blocked()
			DefenseResult.HIT:
				# nada especial
				pass
