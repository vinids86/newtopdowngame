# CombatEntity.gd
extends CharacterBody2D

class_name CombatEntity

var sprite := Sprite2D.new()
var collision_shape := CollisionShape2D.new()
var audio := AudioStreamPlayer2D.new()

func _ready():
	create_sprite()
	create_collision()
	setup_audio()

func create_sprite():
	sprite.texture = preload("res://assets/white_square.png")
	sprite.modulate = Color.GRAY
	add_child(sprite)

func create_collision():
	var body_shape = RectangleShape2D.new()
	body_shape.size = Vector2(64, 64)
	collision_shape.shape = body_shape
	add_child(collision_shape)

func setup_audio():
	add_child(audio)

func play_sound(path: String):
	var stream = load(path)
	if stream:
		audio.stream = stream
		audio.play()
