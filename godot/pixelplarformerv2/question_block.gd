# question_block.gd
extends StaticBody2D

@export var coin_scene: PackedScene 
@export var life_up_scene: PackedScene 

@export_range(0.0, 1.0) var chance_for_life = 0.1 # 10% шанс на выпадение жизни

# Если используете Sprite2D и меняете текстуру:
@export var empty_block_texture: Texture2D 
# @onready var block_sprite: Sprite2D = $BlockSprite # Убедитесь, что имя узла Sprite2D - "BlockSprite"
# Если используете AnimatedSprite2D:
@onready var block_sprite: AnimatedSprite2D = $BlockSprite # И в _ready() block_sprite.play("active")

@onready var item_spawn_point: Marker2D = $ItemSpawnPoint # Узел Marker2D для точки появления предмета

var is_activated = false

func _ready():
	# Если AnimatedSprite2D, запустить начальную анимацию
	if block_sprite is AnimatedSprite2D:
		block_sprite.play("active")

# Эту функцию вызывает игрок, когда ударяет блок снизу
func hit_block_from_below(player_node: Node2D): # Ожидаем узел игрока
	if is_activated:
		# Здесь можно проиграть звук "пустого блока"
		return

	is_activated = true
	
	# Меняем вид блока
	if block_sprite is AnimatedSprite2D:
		block_sprite.play("empty") # Анимация "пустого" блока
	elif empty_block_texture: # Если это Sprite2D и задана текстура пустого блока
		block_sprite.texture = empty_block_texture
	
	# Эффект "подпрыгивания" самого блока QuestionBlock
	var tween = create_tween()
	var original_block_pos = global_position 
	tween.tween_property(self, "global_position", original_block_pos - Vector2(0, 6), 0.07) # Подпрыгнуть
	tween.tween_property(self, "global_position", original_block_pos, 0.07) # Вернуться
	# Здесь можно проиграть звук удара по блоку

	# Решаем, какой предмет выпадет
	var item_to_spawn_scene: PackedScene
	if randf() < chance_for_life: # randf() генерирует случайное число от 0.0 до 1.0
		item_to_spawn_scene = life_up_scene
		print("Из блока выпала жизнь!")
	else:
		item_to_spawn_scene = coin_scene
		print("Из блока выпала монета!")
	
	if item_to_spawn_scene:
		var item_instance = item_to_spawn_scene.instantiate()
		
		# Добавляем предмет на текущий уровень (сцену)
		var current_level = get_tree().current_scene
		if current_level and item_instance:
			current_level.add_child(item_instance) # Добавляем как потомок текущей сцены
			item_instance.global_position = item_spawn_point.global_position # Устанавливаем позицию
		else:
			print("Ошибка: Не удалось добавить предмет на уровень или предмет не был инстанциирован.")
