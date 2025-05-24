# GameManager.gd
extends Node

var score = 0
var initial_lives = 1
var lives = initial_lives 
var max_lives = 3 
var points_for_extra_life = 500

var has_key: bool = false # НОВОЕ: есть ли у игрока ключ

signal score_updated(new_score)
signal lives_updated(new_lives)
signal score_added_for_life(points_value)
signal key_status_updated(player_has_key) # НОВОЕ: сигнал для UI, если нужно отображать ключ

const GameOverMenuScene: PackedScene = preload("res://game_over_menu.tscn") # Убедитесь, что путь к вашей сцене ВЕРНЫЙ!
var game_over_menu_instance: CanvasLayer = null # Будет хранить экземпляр меню

func _ready():
	reset_game_state() 

func add_score(amount: int):
	score += amount
	emit_signal("score_updated", score)

func lose_life():
	lives -= 1
	emit_signal("lives_updated", lives)
	
	if lives <= 0: 
		print("[GameManager] Игрок потерял последнюю жизнь (жизни: {lives})!")
		_show_game_over_ui("Все жизни потеряны")

func trigger_instant_game_over(reason: String = "Неизвестная причина"):
	print("[GameManager] Мгновенный Game Over! Причина: {reason}")
	lives = 0 
	emit_signal("lives_updated", lives)
	_show_game_over_ui(reason)

func _show_game_over_ui(reason_for_log: String):
	print("[GameManager] Запуск UI 'Конец Игры'. Причина: {reason_for_log}")
	print("[GameManager] Текущий счет для передачи: " + str(score))

	# Если экземпляр меню уже существует (маловероятно, но на всякий случай),
	# и он видим, возможно, ничего делать не нужно или нужно обновить.
	# Но лучше предполагать, что мы создаем его заново или показываем существующий скрытый.
	# Для простоты и чистоты, если старый есть, удалим его перед созданием нового.
	if is_instance_valid(game_over_menu_instance):
		print("[GameManager] Найден предыдущий экземпляр GameOverMenu. Удаляю его.")
		game_over_menu_instance.queue_free()
		game_over_menu_instance = null

	if GameOverMenuScene:
		game_over_menu_instance = GameOverMenuScene.instantiate()
		# Добавляем меню в корень дерева сцен, чтобы оно было поверх всего
		get_tree().root.add_child(game_over_menu_instance) 
		print("[GameManager] Экземпляр GameOverMenu создан и добавлен в корень дерева.")
		
		if game_over_menu_instance.has_method("show_screen"):
			game_over_menu_instance.show_screen(score) # Передаем текущий счет
		else:
			print("[GameManager] !!! ОШИБКА: Экземпляр GameOverMenu не имеет метода show_screen()!")
			_fallback_game_over_action() # Аварийное действие
	else:
		print("[GameManager] !!! ОШИБКА: Не удалось загрузить GameOverMenuScene! Проверьте путь в preload.")
		_fallback_game_over_action()


func add_life():
	# ... (код без изменений, как в предыдущей версии) ...
	print("DEBUG: GameManager add_life() ВЫЗВАНА. Жизней до: " + str(lives))
	if lives < max_lives:
		lives += 1
		emit_signal("lives_updated", lives)
		print("DEBUG: GameManager add_life(). Жизнь добавлена. Жизней после: " + str(lives))
	else:
		add_score(points_for_extra_life)
		emit_signal("score_added_for_life", points_for_extra_life)
		print("DEBUG: GameManager add_life(). Максимум жизней. Начислены очки.")


# Эта функция вызывается из GameOverMenu или при инициализации игры
func reset_game_state():
	score = 0
	lives = initial_lives 
	print("GameManager: Состояние игры сброшено. Счет: {score}, Жизни: {lives}")
	emit_signal("score_updated", score)
	emit_signal("lives_updated", lives)

func _fallback_game_over_action(): # Если UI "Конец Игры" не удалось показать
	print("GameManager: _fallback_game_over_action: Аварийный сброс и перезапуск уровня.")
	reset_game_state()
	get_tree().reload_current_scene()

# --- НОВЫЕ ФУНКЦИИ ДЛЯ КЛЮЧА ---
func collect_key():
	if not has_key:
		has_key = true
		emit_signal("key_status_updated", true)
		print("GameManager: Ключ подобран!")
		# Здесь можно проиграть звук подбора ключа

func check_has_key() -> bool:
	return has_key

# Опционально, если ключ одноразовый:
func use_key():
	if has_key:
		has_key = false
		emit_signal("key_status_updated", false)
		print("GameManager: Ключ использован!")
