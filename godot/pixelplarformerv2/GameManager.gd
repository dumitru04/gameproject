# GameManager.gd
extends Node

var score: int = 0
var initial_lives: int = 1 # Игрок по умолчанию имеет 1 жизнь
var lives: int = initial_lives 
var max_lives: int = 3 # Максимум жизней, которые можно собрать
var points_for_extra_life: int = 500
var has_key: bool = false

# ВАЖНО: Замените на актуальные пути к вашим сценам уровней!
var level_scene_paths: Array[String] = [
	"res://level1.tscn", 
	"res://level2.tscn"
	# "res://level3.tscn" 
]
var current_level_index: int = 0
var level_index_at_game_over: int = 0 # Для перезапуска уровня, на котором проиграли

# Сигналы для обновления UI
signal score_updated(new_score: int)
signal lives_updated(new_lives: int)
signal score_added_for_life(points_value: int) # Если жизней максимум, даем очки
signal key_status_updated(player_has_key: bool)

# Предзагрузка сцены меню "Конец Игры"
const GameOverMenuScene: PackedScene = preload("res://game_over_menu.tscn") # Убедитесь, что путь ВЕРНЫЙ!
var game_over_menu_instance: CanvasLayer = null

func _ready():
	print("[GameManager] GameManager готов и автозагружен.")
	# reset_stats() будет вызван через start_new_game() при фактическом запуске игры из главного меню

func add_score(amount: int):
	score += amount
	emit_signal("score_updated", score)

func lose_life():
	print("[GameManager] lose_life вызвана. Жизней было: {lives}")
	lives -= 1
	emit_signal("lives_updated", lives)
	
	if lives < 1: # Если было 0 жизней и игрок получил урон, жизни станут -1
		lives = 0 # Для корректного отображения и логики Game Over
		emit_signal("lives_updated", lives) # Обновляем UI до 0
		print("[GameManager] Игрок потерял все жизни (жизни <= 0).")
		_trigger_game_over_logic("Все жизни потеряны (обычный урон)")
	else:
		print("[GameManager] Игрок потерял жизнь. Осталось: {lives}")
		# Здесь можно добавить логику, если нужно что-то делать при потере жизни, но игра не окончена
		# Например, перезагрузить уровень, если каждая потеря жизни - это рестарт уровня:
		# get_tree().reload_current_scene()

func trigger_instant_game_over(reason: String = "Неизвестная причина"):
	print("[GameManager] Мгновенный Game Over! Причина: {reason}")
	lives = 0 # Устанавливаем жизни в 0 для консистентности
	emit_signal("lives_updated", lives)
	_trigger_game_over_logic(reason)

func _trigger_game_over_logic(reason_for_log: String):
	print("[GameManager] Запуск логики 'Конец Игры'. Причина: {reason_for_log}")
	level_index_at_game_over = current_level_index # Запоминаем уровень, на котором проиграли

	if is_instance_valid(game_over_menu_instance): # Удаляем старый экземпляр, если есть
		print("[GameManager] Найден предыдущий экземпляр GameOverMenu. Удаляю его.")
		game_over_menu_instance.queue_free()
		game_over_menu_instance = null

	if GameOverMenuScene:
		game_over_menu_instance = GameOverMenuScene.instantiate()
		get_tree().root.add_child(game_over_menu_instance) 
		print("[GameManager] Экземпляр GameOverMenu создан и добавлен в корень дерева.")
		
		if game_over_menu_instance.has_method("show_screen"):
			game_over_menu_instance.show_screen(score) # Передаем текущий счет
		else:
			printerr("[GameManager] !!! ОШИБКА: Экземпляр GameOverMenu не имеет метода show_screen()!")
			_fallback_game_over_action() 
	else:
		printerr("[GameManager] !!! ОШИБКА: Не удалось загрузить GameOverMenuScene! Проверьте путь в preload.")
		_fallback_game_over_action()

func add_life():
	if lives < max_lives:
		lives += 1
		emit_signal("lives_updated", lives)
		print("[GameManager] Жизнь добавлена. Всего жизней: {lives}")
	else:
		add_score(points_for_extra_life)
		emit_signal("score_added_for_life", points_for_extra_life)
		print("[GameManager] Максимум жизней ({max_lives}). Начислено {points_for_extra_life} очков.")

func collect_key():
	if not has_key:
		has_key = true
		emit_signal("key_status_updated", true)
		print("[GameManager] Ключ подобран!")

func check_has_key() -> bool:
	return has_key

# Сбрасывает ТОЛЬКО статистику (счет, жизни, ключ). НЕ ТРОГАЕТ current_level_index.
func reset_stats_for_new_attempt():
	score = 0
	lives = initial_lives 
	has_key = false 
	print("[GameManager] Статистика для новой попытки сброшена. Счет: {score}, Жизни: {lives}, Ключ: {has_key}")
	emit_signal("score_updated", score)
	emit_signal("lives_updated", lives)
	emit_signal("key_status_updated", has_key)

# Для НАЧАЛА СОВЕРШЕННО НОВОЙ ИГРЫ (из главного меню или после Game Over -> Restart)
func start_new_game():
	print("[GameManager] Запуск новой игры (start_new_game).")
	current_level_index = 0 # Начинаем с первого уровня
	reset_stats_for_new_attempt() # Сбрасываем статистику (счет, жизни, ключ)
	
	var first_level_path = get_current_level_path()
	if not first_level_path.is_empty():
		print("[GameManager] Загрузка первого уровня: {first_level_path}")
		if get_tree().paused: get_tree().paused = false # Снимаем с паузы, если была
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) # Или MOUSE_MODE_CAPTURED для игры
		var error = get_tree().change_scene_to_file(first_level_path)
		if error != OK:
			printerr("[GameManager] !!! ОШИБКА загрузки первого уровня '{first_level_path}': {error_string(error)}")
	else:
		printerr("[GameManager] !!! ОШИБКА: В level_scene_paths нет уровней для старта!")

# Для перезапуска уровня, на котором игрок проиграл (вызывается из GameOverMenu)
func restart_failed_level():
	print("[GameManager] Перезапуск уровня {level_index_at_game_over} после Game Over.")
	current_level_index = level_index_at_game_over # Восстанавливаем индекс уровня
	reset_stats_for_new_attempt() # Сбрасываем статистику
	
	var level_path = get_current_level_path()
	if not level_path.is_empty():
		print("[GameManager] Загрузка уровня для перезапуска: {level_path}")
		if get_tree().paused: get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) # Или MOUSE_MODE_CAPTURED
		var error = get_tree().change_scene_to_file(level_path)
		if error != OK:
			printerr("[GameManager] !!! ОШИБКА перезапуска уровня '{level_path}': {error_string(error)}")
			start_new_game() # Аварийный запуск новой игры, если не удалось перезапустить текущий
	else:
		printerr("[GameManager] !!! ОШИБКА: Путь к уровню для перезапуска пуст.")
		start_new_game() 

func get_current_level_path() -> String:
	if current_level_index >= 0 and current_level_index < level_scene_paths.size():
		return level_scene_paths[current_level_index]
	printerr("[GameManager] ОШИБКА: current_level_index ({current_level_index}) невалиден для level_scene_paths (размер: {level_scene_paths.size()})!")
	return "" if level_scene_paths.is_empty() else level_scene_paths[0] # Запасной вариант


func go_to_next_level() -> bool: 
	print("[GameManager] go_to_next_level вызвана. Текущий индекс: {current_level_index}")
	var next_idx = current_level_index + 1
	if next_idx < level_scene_paths.size():
		current_level_index = next_idx
		var next_level_path = level_scene_paths[current_level_index]
		print("[GameManager] Переход на следующий уровень: '{next_level_path}' (индекс: {current_level_index})")
		
		has_key = false # Сбрасываем ключ для следующего уровня
		emit_signal("key_status_updated", has_key)
		# Счет и жизни СОХРАНЯЮТСЯ при переходе на следующий уровень

		if get_tree().paused: get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) # Или MOUSE_MODE_CAPTURED
		var error = get_tree().change_scene_to_file(next_level_path)
		if error != OK:
			printerr("[GameManager] !!! ОШИБКА загрузки уровня '{next_level_path}': {error_string(error)}")
			current_level_index -= 1 # Возвращаем индекс, если не удалось загрузить
			return false 
		return true
	else:
		print("[GameManager] Следующий уровень не найден (индекс {next_idx}). Это был последний уровень.")
		return false

func _fallback_game_over_action():
	print("GameManager: _fallback_game_over_action: Аварийный запуск новой игры.")
	start_new_game()
