# key_block.gd
extends StaticBody2D

@export var star_scene: PackedScene # Перетащите сюда StarItem.tscn
@export var points_for_opening = 1000

# Для Sprite2D:
# @export var locked_texture: Texture2D 
# @export var opened_texture: Texture2D
# Для AnimatedSprite2D (если используете):
var anim_locked = "locked_key_block"
var anim_opened = "opened_key_block"

@onready var block_sprite_node: Node = $BlockSprite # Может быть Sprite2D или AnimatedSprite2D
@onready var item_spawn_point: Marker2D = $ItemSpawnPoint

var is_opened = false

func _ready():
	# Установка начального вида блока
	if block_sprite_node is AnimatedSprite2D:
		(block_sprite_node as AnimatedSprite2D).play(anim_locked)
		pass # Настройте начальную анимацию в редакторе или здесь

# Этот метод вызывается из player.gd, когда RayCast игрока попадает в блок
func hit_block_from_below(player: Node2D): # player это узел игрока
	if is_opened or not player.is_in_group("player"):                
		return

	print("KeyBlock: Удар головой от игрока " + player.name)
	if GameManager.check_has_key():
		print("KeyBlock: У игрока есть ключ! Открываю блок...")
		_open_block_action()
		# Опционально, если ключ одноразовый:
		GameManager.use_key() 
	else:
		print("KeyBlock: У игрока нет ключа. Блок заперт.")
		_play_locked_feedback() # Эффект "заперто"

func _open_block_action(): # Эта функция вызывается из hit_block_from_below
	is_opened = true
	print("[KeyBlock] _open_block_action: Блок '" + name + "' открывается.")
	
	# Сменить спрайт/анимацию на "открыто" (ваш код здесь)
	if block_sprite_node is AnimatedSprite2D:
		(block_sprite_node as AnimatedSprite2D).play(anim_opened)
		print("[KeyBlock] _open_block_action: (AnimatedSprite2D) Попытка проиграть анимацию открытого блока.")

	# Эффект "подпрыгивания" блока (ваш код здесь)
	var tween = get_tree().create_tween()
	var original_pos = global_position
	tween.tween_property(self, "global_position", original_pos - Vector2(0, 6), 0.07)
	tween.tween_property(self, "global_position", original_pos, 0.07)
	
	GameManager.add_score(points_for_opening)
	print("[KeyBlock] _open_block_action: Начислено {points_for_opening} очков.")

	# --- Проверка и создание звезды ---
	if not item_spawn_point:
		print("[KeyBlock] _open_block_action: !!! ОШИБКА: Узел ItemSpawnPoint не найден! Звезда не может быть создана без точки появления.")
		return # Выходим, если нет точки спавна

	if star_scene: # Проверка 1: Назначена ли сцена звезды в инспекторе?
		print("[KeyBlock] _open_block_action: Сцена звезды (star_scene) НАЗНАЧЕНА. Пытаюсь инстанциировать...")
		var star_instance = star_scene.instantiate() # Проверка 2: Проходит ли инстанцирование?
		
		if not star_instance:
			print("[KeyBlock] _open_block_action: !!! ОШИБКА: Не удалось инстанциировать star_scene! Проверьте сцену звезды.")
			return # Выходим, если инстанцирование не удалось

		print("[KeyBlock] _open_block_action: Звезда успешно инстанциирована: " + str(star_instance.name))
		var current_level = get_tree().current_scene # Проверка 3: Получаем ли текущий уровень?
		
		if not current_level:
			print("[KeyBlock] _open_block_action: !!! ОШИБКА: get_tree().current_scene вернул null! Не могу добавить звезду.")
			return # Выходим, если не можем получить текущую сцену
			
		print("[KeyBlock] _open_block_action: Текущий уровень: " + current_level.name + ". Добавляю звезду как дочерний узел...")
		current_level.add_child(star_instance) # Проверка 4: Добавляется ли звезда на сцену?
		
		# Устанавливаем позицию ПОСЛЕ добавления на сцену, чтобы учесть трансформации родителя, если они есть.
		# Для Marker2D item_spawn_point.global_position это уже мировая позиция.
		star_instance.global_position = item_spawn_point.global_position # Проверка 5: Устанавливается ли позиция?
		print("[KeyBlock] _open_block_action: Звезда '{star_instance.name}' добавлена на уровень '{current_level.name}'. Позиция: {star_instance.global_position}")
		
		# Начальный импульс звезде обрабатывается в ее собственном скрипте (star_item.gd)
	else:
		print("[KeyBlock] _open_block_action: !!! ОШИБКА: Сцена звезды (star_scene) НЕ НАЗНАЧЕНА в инспекторе для этого KeyBlock ('" + name + "')!")
	
	# Блок больше не должен реагировать на удары
	if get_node_or_null("HitDetector"): # Если у вас был Area2D HitDetector
		get_node("HitDetector").set_deferred("monitorable", false)
		print("[KeyBlock] _open_block_action: HitDetector (Area2D) отключен.")

	# Блок больше не должен реагировать на удары
	# Если hit_block_from_below - единственный способ взаимодействия, is_opened достаточно.
	# Если были другие Area2D, их нужно было бы отключить.

func _play_locked_feedback():
	# Небольшая тряска блока и звук "заперто"
	var tween = get_tree().create_tween()
	var original_x = global_position.x
	tween.tween_property(self, "global_position:x", original_x - 2, 0.05)
	tween.tween_property(self, "global_position:x", original_x + 2, 0.05)
	tween.tween_property(self, "global_position:x", original_x, 0.05)
	# Проиграть звук "заперто" (если есть)
	print("KeyBlock: Эффект 'заперто' проигран.")
