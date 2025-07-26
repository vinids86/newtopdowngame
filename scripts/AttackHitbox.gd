extends Area2D

var shape := RectangleShape2D.new()
var visual := Sprite2D.new()
var layer := 1
var mask := 2

enum DefenseResult {
	HIT,
	BLOCKED,
	PARRIED
}

func _init():
	set_collision_layers(layer, mask)  # Garante aplicação imediata
	
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

func set_collision_layers(layer_index: int, mask_index: int):
	layer = layer_index
	mask = mask_index
	set_collision_layer(0) # limpa tudo
	set_collision_mask(0)  # limpa tudo
	set_collision_layer_value(layer_index, true)
	set_collision_mask_value(mask_index, true)

func _ready():
	connect("area_entered", _on_area_entered)

func enable(pos: Vector2):
	position = pos
	monitoring = true
	visible = true
	visual.visible = true

func disable():
	monitoring = false
	visible = false
	visual.visible = false

func _on_area_entered(area: Area2D) -> void:
	if not monitoring:
		return

	var defender = area.get_parent()
	var attacker = get_parent()

	if not defender or not attacker or defender == attacker:
		return

	if not defender.has_method("take_damage"):
		return

	if not _are_opposing_factions(attacker, defender):
		return

	var result = defender.take_damage(1, attacker)
	
	print("🧠 Nome do atacante:", attacker.name)
	print("🧠 Tipo do atacante:", typeof(attacker))
	print("🧠 Classe declarada:", attacker.get_class())
	print("🧠 Script associado:", attacker.get_script())
	print("🧠 Script path:", attacker.get_script().resource_path)


	if "controller" in attacker and attacker.controller:
		match result:
			DefenseResult.PARRIED:
				print("🎯 Ataque foi parryado — chamando on_parried() do ATACANTE")
				print("Script atribuído ao atacante:", attacker.get_script())
				print("Script path real:", attacker.get_script().resource_path)

				var methods = attacker.get_script().get_method_list()
				for m in methods:
					if m.name == "on_parried":
						print("✅ MÉTODO on_parried DEFINIDO EM:", attacker.get_script().resource_path)

				if attacker.has_method("on_parried"):
					print("✅ has_method reconheceu on_parried no atacante")
					attacker.on_parried()
				else:
					print("❌ Script atual não possui on_parried():", attacker.get_script())

			DefenseResult.BLOCKED: 
				print("🛡️ Ataque foi bloqueado — chamando on_blocked() do atacante")
				attacker.controller.on_blocked()

func _are_opposing_factions(a: Node, b: Node) -> bool:
	return (a.is_in_group("player") and b.is_in_group("enemy")) or \
		   (a.is_in_group("enemy") and b.is_in_group("player"))
