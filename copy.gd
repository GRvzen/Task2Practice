extends Control

# ПРОВЕРЬ: Нажми правой кнопкой на эти узлы в дереве и выбери "Access as Unique Name"
@onready var task_image = %TaskImage
@onready var hint_button = %HintButton
@onready var popup = %ResultPopup
@onready var cat_image = %CatImage
@onready var popup_label = %ResultLabel

# Проверь, чтобы имена кнопок в дереве совпадали (Button1, Button2 и т.д.)
@onready var answer_buttons = [%Button1, %Button2, %Button3, %Button4]

# Ресурсы котиков
var happy_cat = preload("res://assets/happy_cat.png")
var sad_cat = preload("res://assets/sad_cat.png")

var levels = [] 
var correct_button_index = -1

func _ready():
	# 1. Ждем, пока Godot полностью построит дерево узлов
	await get_tree().node_added
	
	# 2. Загружаем JSON
	load_levels_from_json()
	
	# 3. Проверяем, какой ID пришел из Global
	print("Загрузка уровня с ID: ", Global.selected_level_id)
	
	if Global.selected_level_id > 0:
		load_level_by_id(Global.selected_level_id)
	else:
		# Если вдруг ID потерялся, ставим 1 по умолчанию
		load_level_by_id(1)
	
# 1. Загрузка данных из файла
func load_levels_from_json():
	var file_path = "res://assets/levels.json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json_data = JSON.parse_string(file.get_as_text())
		if json_data is Array:
			levels = json_data
	else:
		print("Ошибка: Файл JSON не найден!")

# 2. Поиск нужного уровня в массиве
func load_level_by_id(target_id: int):
	var current_data = null
	
	for lvl in levels:
		if lvl is Dictionary and lvl.has("id"):
			if int(lvl["id"]) == target_id:
				current_data = lvl
				break
	

	if current_data:
		var image_path = current_data["image"]
		var texture = load(image_path) # Загружаем файл по пути из JSON
		
		if texture:
			task_image.texture = texture
			setup_level(texture, current_data["correct"], current_data["wrongs"])
		else:
			print("ОШИБКА: Не удалось найти файл по пути: ", image_path)
	else:
		print("Ошибка: Уровень с ID ", target_id, " не найден в списке!")

# 3. Настройка визуальной части уровня
func setup_level(image_texture: Texture2D, correct_answer: String, wrong_answers: Array):
	if task_image != null:
		task_image.texture = image_texture
		task_image.show()
	
	if hint_button != null:
		hint_button.disabled = false
	
	var all_answers = wrong_answers.duplicate()
	all_answers.append(correct_answer)
	all_answers.shuffle()
	
	for i in range(4):
		var btn = answer_buttons[i]
		
		# Если кнопка существует, настраиваем её
		if btn != null:
			btn.text = all_answers[i]
			btn.visible = true
			
			if all_answers[i] == correct_answer:
				correct_button_index = i
				
			# АВТО-ПОДКЛЮЧЕНИЕ СИГНАЛОВ (чтобы кнопки 100% реагировали)
			# Сначала отключаем старые связи, чтобы не было двойных кликов
			if btn.pressed.is_connected(_on_answer_pressed.bind(i)):
				btn.pressed.disconnect(_on_answer_pressed.bind(i))
			# Подключаем заново
			btn.pressed.connect(_on_answer_pressed.bind(i))

# 4. Логика нажатия на кнопки ответов
func _on_answer_pressed(index: int):
	# Выводим в консоль инфу, чтобы видеть, что клик сработал
	print("---")
	print("Клик по кнопке: ", index)
	print("Правильная кнопка должна быть: ", correct_button_index)
	
	Global.total_attempts += 1
	Global.save_data() # Если у тебя есть эта функция в Global
	
	if index == correct_button_index:
		print("Ответ ВЕРНЫЙ!")
		Global.levels_completed += 1
		show_popup(true)
	else:
		print("Ответ НЕВЕРНЫЙ!")
		show_popup(false)

func show_popup(is_correct: bool):
	if is_correct:
		cat_image.texture = happy_cat
		popup_label.text = "That's right!"
		popup_label.modulate = Color.GREEN
	else:
		cat_image.texture = sad_cat
		popup_label.text = "Try again!"
		popup_label.modulate = Color.RED
	
	popup.popup_centered()


# Полностью замени функцию подсказки на эту:
func _on_hint_button_pressed():
	var hidden_count = 0
	
	for i in range(answer_buttons.size()):
		var btn = answer_buttons[i]
		
		# ЖЕСТКАЯ ПРОВЕРКА: скрываем только если кнопка реально существует
		if btn != null:
			if i != correct_button_index and hidden_count < 2:
				btn.visible = false
				hidden_count += 1
		else:
			print("Внимание: кнопка ", i, " равна null в массиве, пропускаем её.")
			
	if hint_button != null:
		hint_button.disabled = true

# 7. Переход к следующему уровню (кнопка в Popup)
func _on_continue_button_pressed():
	popup.hide()
	# Если ответили правильно, можно либо вернуться в меню, либо включить следующий ID
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_menu_button_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
