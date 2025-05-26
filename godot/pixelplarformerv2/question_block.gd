extends StaticBody2D

@export var coin_scene: PackedScene 
@export var life_up_scene: PackedScene 

@export_range(0.0, 1.0) var chance_for_life = 0.1

@export var empty_block_texture: Texture2D 
@onready var block_sprite: AnimatedSprite2D = $BlockSprite

@onready var item_spawn_point: Marker2D = $ItemSpawnPoint

var is_activated = false

func _ready():
    if block_sprite is AnimatedSprite2D:
        block_sprite.play("active")

func hit_block_from_below(player_node: Node2D):
    if is_activated:
        return

    is_activated = true
    
    GameManager.GM_sfx_block_hit()
    
    if block_sprite is AnimatedSprite2D:
        block_sprite.play("empty")
    elif empty_block_texture:
        block_sprite.texture = empty_block_texture
    
    var tween = create_tween()
    var original_block_pos = global_position 
    tween.tween_property(self, "global_position", original_block_pos - Vector2(0, 6), 0.07)
    tween.tween_property(self, "global_position", original_block_pos, 0.07)

    var item_to_spawn_scene: PackedScene
    if randf() < chance_for_life:
        item_to_spawn_scene = life_up_scene
        print("Life dropped from block!")
    else:
        item_to_spawn_scene = coin_scene
        print("Coin dropped from block!")
    
    if item_to_spawn_scene:
        var item_instance = item_to_spawn_scene.instantiate()
        
        var current_level = get_tree().current_scene
        if current_level and item_instance:
            current_level.add_child(item_instance)
            item_instance.global_position = item_spawn_point.global_position
        else:
            print("Error: Failed to add item to level or item was not instantiated.")
