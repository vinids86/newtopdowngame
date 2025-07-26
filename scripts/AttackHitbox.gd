# AttackHitbox.gd
extends Area2D

var shape := RectangleShape2D.new()
var visual := Sprite2D.new()

func _init():
	# Colisor
	var collision := CollisionShape2D.new()
	shape.size = Vector2(64, 64)
	collision.shape = shape
	add_child(collision)

	# Visual
	visual.texture = preload("res://assets/white_square.png")
	visual.modulate = Color(1, 0, 0, 0.4)
	visual.visible = false
	add_child(visual)

	# Configurações de colisão
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
