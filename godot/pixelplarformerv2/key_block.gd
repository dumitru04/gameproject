extends StaticBody2D

@export var star_scene: PackedScene
@export var points_for_opening = 1000

var anim_locked = "locked_key_block"
var anim_opened = "opened_key_block"

@onready var block_sprite_node: Node = $BlockSprite
@onready var item_spawn_point: Marker2D = $ItemSpawnPoint

var is_opened = false

func _ready():
    if block_sprite_node is AnimatedSprite2D:
        (block_sprite_node as AnimatedSprite2D).play(anim_locked)

func hit_block_from_below(player: Node2D):
    if is_opened or not player.is_in_group("player"):                
        return

    print("KeyBlock: Hit from below by player " + player.name)
    if GameManager.check_has_key():
        print("KeyBlock: Player has key! Opening block...")
        _open_block_action()
        GameManager.use_key() 
    else:
        print("KeyBlock: Player doesn't have key. Block is locked.")
        _play_locked_feedback()

func _open_block_action():
    is_opened = true
    GameManager.GM_sfx_block_hit()
    print("[KeyBlock] _open_block_action: Block '" + name + "' opening.")
    
    if block_sprite_node is AnimatedSprite2D:
        (block_sprite_node as AnimatedSprite2D).play(anim_opened)
        print("[KeyBlock] _open_block_action: (AnimatedSprite2D) Attempting to play opened block animation.")

    var tween = get_tree().create_tween()
    var original_pos = global_position
    tween.tween_property(self, "global_position", original_pos - Vector2(0, 6), 0.07)
    tween.tween_property(self, "global_position", original_pos, 0.07)
    
    GameManager.add_score(points_for_opening)
    print("[KeyBlock] _open_block_action: Awarded {points_for_opening} points.")

    if not item_spawn_point:
        print("[KeyBlock] _open_block_action: !!! ERROR: ItemSpawnPoint node not found! Star cannot be created without spawn point.")
        return

    if star_scene:
        print("[KeyBlock] _open_block_action: Star scene (star_scene) ASSIGNED. Attempting to instantiate...")
        var star_instance = star_scene.instantiate()
        
        if not star_instance:
            print("[KeyBlock] _open_block_action: !!! ERROR: Failed to instantiate star_scene! Check star scene.")
            return

        print("[KeyBlock] _open_block_action: Star successfully instantiated: " + str(star_instance.name))
        var current_level = get_tree().current_scene
        
        if not current_level:
            print("[KeyBlock] _open_block_action: !!! ERROR: get_tree().current_scene returned null! Cannot add star.")
            return
            
        print("[KeyBlock] _open_block_action: Current level: " + current_level.name + ". Adding star as child node...")
        current_level.add_child(star_instance)
        
        star_instance.global_position = item_spawn_point.global_position
        print("[KeyBlock] _open_block_action: Star '{star_instance.name}' added to level '{current_level.name}'. Position: {star_instance.global_position}")
    else:
        print("[KeyBlock] _open_block_action: !!! ERROR: Star scene (star_scene) NOT ASSIGNED in inspector for this KeyBlock ('" + name + "')!")
    
    if get_node_or_null("HitDetector"):
        get_node("HitDetector").set_deferred("monitorable", false)
        print("[KeyBlock] _open_block_action: HitDetector (Area2D) disabled.")

func _play_locked_feedback():
    var tween = get_tree().create_tween()
    var original_x = global_position.x
    tween.tween_property(self, "global_position:x", original_x - 2, 0.05)
    tween.tween_property(self, "global_position:x", original_x + 2, 0.05)
    tween.tween_property(self, "global_position:x", original_x, 0.05)
    print("KeyBlock: 'Locked' feedback effect played.")
