@onready var levels_label = %LevelsLabel
@onready var average_label = %AverageLabel

func _ready():
	# проверяем, что узлы существуют, прежде чем писать в них текст
	if levels_label == null or average_label == null:
		print("ОШИБКА: Метки статистики не найдены! Проверь Unique Name (%) в сцене Stats")
		return

	# Вывод пройденных уровней
	levels_label.text = "Пройдено уровней: " + str(Global.levels_completed)
	
	# Расчет среднего количества попыток
	var average = 0.0
	if Global.levels_completed > 0:
		# Используем float для точного расчета
		average = float(Global.total_attempts) / float(Global.levels_completed)
	
	# Вывод среднего значения
	average_label.text = "Среднее кол-во попыток: %.2f" % average

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


extends Node

var save_path = "user://stats.save"

# Данные для статистики
var levels_completed: int = 0
var total_attempts: int = 0

var selected_level_id: int = 1

func _ready():
	load_data()

# Сохранение в JSON
func save_data():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	var data = {
		"levels_completed": levels_completed,
		"total_attempts": total_attempts
	}
	file.store_string(JSON.stringify(data))

# Загрузка данных при старте
func load_data():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		if data:
			levels_completed = data.get("levels_completed", 0)
			total_attempts = data.get("total_attempts", 0)

extends Control1

@onready var task_image = %TaskImage
@onready var hint_button = %HintButton
@onready var popup = %ResultPopup
@onready var cat_image = %CatImage
@onready var popup_label = %ResultLabel
@onready var continue_button = %ContinueButton

@onready var answer_buttons = [%Button1, %Button2, %Button3, %Button4]

var levels = [] 
var correct_button_index = -1

func _ready():
	await get_tree().process_frame
	
	load_levels_from_json()
	
	print("--- Запуск уровня ---")
	print("ID в Global: ", Global.selected_level_id)
	
	if levels.size() == 0:
		print("КРИТИЧЕСКАЯ ОШИБКА: Список уровней пуст! Проверь JSON.")
		return

	load_level_by_id(Global.selected_level_id)

 # Загрузка уровней из json-файла
func load_levels_from_json():
	var file_path = "res://assets/levels.json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json_data = JSON.parse_string(file.get_as_text())
		if json_data is Array:
			levels = json_data
			print("JSON загружен успешно. Количество уровней: ", levels.size())
	else:
		print("Файл не найден: ", file_path)

 #Загрузка данных в уровень по id
func load_level_by_id(target_id: int):
	var current_data = null
	for lvl in levels:
		if int(lvl["id"]) == target_id:
			current_data = lvl
			break
	
	if current_data:
		print("Данные уровня найдены: ", current_data["correct"])
		var texture = load(current_data["image"])
		if texture:
			setup_level(texture, current_data["correct"], current_data["wrongs"])
		else:
			print("Ошибка загрузки текстуры: ", current_data["image"])
	else:
		print("Уровень с ID ", target_id, " не найден в списке!")

 # "создание" уровня
func setup_level(image_texture: Texture2D, correct_answer: String, wrong_answers: Array):
	task_image.texture = image_texture
	hint_button.disabled = false
	
	var all_answers = wrong_answers.duplicate()
	all_answers.append(correct_answer)
	all_answers.shuffle()
	
	print("Перемешанные ответы: ", all_answers)
	
	for i in range(4):
		var btn = answer_buttons[i]
		if btn:
			btn.text = all_answers[i]
			btn.visible = true
			if all_answers[i] == correct_answer:
				correct_button_index = i
			
			# Переподключаем сигналы программно
			if btn.pressed.is_connected(_on_answer_pressed):
				btn.pressed.disconnect(_on_answer_pressed)
			btn.pressed.connect(_on_answer_pressed.bind(i))
		else:
			print("Кнопка ", i, " не найдена!")

 # Нажатие на ответ
func _on_answer_pressed(index: int):
	print("Нажата кнопка: ", index, ". Правильная: ", correct_button_index)
	Global.total_attempts += 1
	
	if index == correct_button_index:
		print("Победа!")
		Global.levels_completed += 1
		Global.save_data() # Убедись, что функция есть в Global.gd
		show_popup(true)
	else:
		print("Промах!")
		show_popup(false)
		
 # Вывод изображения котика при выборе ответа 
func show_popup(is_correct: bool):
	if is_correct:
		cat_image.texture = preload("res://assets/happy_cat.png")
		popup_label.text = "Верно!"
		popup_label.modulate = Color.GREEN
	else:
		cat_image.texture = preload("res://assets/sad_cat.png")
		popup_label.text = "Попробуй еще раз"
		popup_label.modulate = Color.RED
	
	popup.popup_centered()
	
	# Кнопка подсказки
func _on_hint_button_pressed():
	var hidden_count = 0
	
	for i in range(answer_buttons.size()):
		var btn = answer_buttons[i]
		
		# скрываем только если кнопка реально существует
		if btn != null:
			if i != correct_button_index and hidden_count < 2:
				btn.visible = false
				hidden_count += 1
		else:
			print("Внимание: кнопка ", i, " равна null в массиве, пропускаем её.")
			
	if hint_button != null:
		hint_button.disabled = true
		
func _on_menu_button_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_continue_button_pressed():
	if popup:
		popup.hide() #скрыли popup, чтоб он не был виден в уровне
	
	# Увеличиваем ID уровня (переходим на следующий)
	Global.selected_level_id += 1
	
	# Проверяем, не кончились ли уровни
	if Global.selected_level_id > levels.size():
		# Если уровни кончились, переключаемся на статистику
		get_tree().call_deferred("change_scene_to_file", "res://scenes/Stats.tscn")
	else:
		# Если уровни еще есть, то перезагружаем сцену уровня
		get_tree().call_deferred("change_scene_to_file", "res://scenes/Level.tscn")


