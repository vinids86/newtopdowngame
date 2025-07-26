extends Node2D

var player
var enemy

func _ready():
	player = preload("res://scripts/Player.gd").new()
	player.name = "Player"
	player.global_position = Vector2(300, 300)
	add_child(player)

	enemy = preload("res://scripts/Enemy.gd").new()
	enemy.global_position = Vector2(300, 150)
	add_child(enemy)

	call_deferred("_link_enemy_target")

func _link_enemy_target():
	enemy.target_path = player.get_path()
