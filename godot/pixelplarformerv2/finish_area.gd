extends Area2D

signal player_reached_finish(player_node: Node2D)

func _ready():
    body_entered.connect(_on_body_entered)
    print("[" + name + "] FinishArea ready and waiting for player.")

func _on_body_entered(body: Node2D):
    if body.is_in_group("player") and body.has_method("start_level_complete_sequence"):
        print("[" + name + "] Player reached finish!")
        set_deferred("monitoring", false) 
        set_deferred("monitorable", false)
        emit_signal("player_reached_finish", body)
