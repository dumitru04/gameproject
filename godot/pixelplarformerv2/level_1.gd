# level1.gd (или имя вашего скрипта уровня)
extends Node2D # Или Node, в зависимости от вашего корневого узла уровня

@export var level_duration_seconds: float = 180 # 3 минуты по умолчанию, можно менять в инспекторе для каждого уровня

# Путь к вашему узлу UI в сцене уровня. 
# Если UI добавляется как инстанс и всегда называется "UI", это должно сработать.
# Если UI является частью другой сцены или имеет сложный путь, укажите его здесь.
@onready var ui_node = $"/root/Level1/UI" # ПРЕДПОЛОЖЕНИЕ: UI это дочерний узел "UI" для "Level1" который в корне.
										# ИЛИ если UI это autoload: get_node("/root/MyUiAutoloadName")
										# ИЛИ если сцена UI инстанциируется в уровень: $ИмяИнстансаUI

func _ready():
	# Пытаемся найти UI более надежно, если он инстанциирован в текущую сцену
	var actual_ui_node = find_ui_node()

	if actual_ui_node and actual_ui_node.has_method("initialize_level_timer"):
		actual_ui_node.initialize_level_timer(level_duration_seconds)
	else:
		if not actual_ui_node:
			print("Level_ready ({name}): ВНИМАНИЕ! Узел UI не найден. Таймер уровня не будет запущен.")
		else:
			print("Level_ready ({name}): ВНИМАНИЕ! Узел UI найден, но не имеет метода 'initialize_level_timer'.")

func find_ui_node():
	# Попробуем найти узел UI по имени, если он является прямым потомком текущей сцены (уровня)
	var ui = get_node_or_null("UI") # Если инстанс UI в сцене уровня называется "UI"
	if ui:
		return ui
	
	# Если UI - это Autoload, вы бы обращались к нему по имени Autoload, например:
	# if get_tree().root.has_node("UiAutoloadName"):
	#    return get_node("/root/UiAutoloadName")

	# Если путь фиксированный, как вы указали, но может быть не всегда актуален:
	# return get_node_or_null($"/root/Level1/UI") # Используйте с осторожностью
	
	# Безопаснее всего, если UI является частью сцены уровня, 
	# или вы используете сигналы для связи между уровнем и UI.
	# Для простоты пока оставим поиск по имени "UI" как дочернего узла.
	print("Level_find_ui_node ({name}): Ищем узел 'UI' как дочерний.")
	return get_node_or_null("UI")


# Вызывается, когда игрок завершает уровень (не по таймеру)
func level_completed():
	if ui_node and ui_node.level_timer: # Проверяем наличие таймера в UI
		ui_node.level_timer.stop() # Останавливаем таймер уровня
		print("Level ({name}): Уровень пройден, таймер остановлен.")
	# ... (другая логика завершения уровня) ...
