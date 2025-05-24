# key_item.gd
extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		GameManager.collect_key()
		queue_free() # Ключ исчезает после подбора
