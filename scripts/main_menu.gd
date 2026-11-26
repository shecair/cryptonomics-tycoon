extends Control

const UI = preload("res://scripts/ui/game_ui.gd")

const SETTINGS_PATH = "user://settings.cfg"
const SAVE_PATH = "user://savegame.json"
const START_PATH = "res://scenes/profile_holding.tscn"
const COMPANY_PATH = "res://scenes/establish_company.tscn"
const CONTINUE_PATH = "res://scenes/holding_dashboard.tscn"
@onready var background: TextureRect = $Background
@onready var menu_panel: Control = $MenuPanel
@onready var crown: TextureRect = $MenuPanel/Crown
@onready var buttons: VBoxContainer = $MenuPanel/Buttons
@onready var start_button: TextureButton = $MenuPanel/Buttons/StartButton
@onready var continue_button: TextureButton = $MenuPanel/Buttons/ContinueButton
@onready var settings_button: TextureButton = $MenuPanel/Buttons/SettingsButton
@onready var about_button: TextureButton = $MenuPanel/Buttons/AboutButton
@onready var exit_button: TextureButton = $MenuPanel/Buttons/ExitButton
@onready var exit_dialog: ConfirmationDialog = $ExitDialog
@onready var about_dialog: AcceptDialog = $AboutDialog
@onready var settings_dialog: ConfirmationDialog = $SettingsDialog
@onready var notice_dialog: AcceptDialog = $NoticeDialog
@onready var music_slider: HSlider = $SettingsDialog/SettingsContent/MusicSlider
@onready var sound_slider: HSlider = $SettingsDialog/SettingsContent/SoundSlider
@onready var language_option: OptionButton = $SettingsDialog/SettingsContent/LanguageOption
@onready var music_label: Label = $SettingsDialog/SettingsContent/MusicLabel
@onready var sound_label: Label = $SettingsDialog/SettingsContent/SoundLabel
@onready var language_label: Label = $SettingsDialog/SettingsContent/LanguageLabel

var menu_buttons: Array[TextureButton] = []
var button_tweens: Dictionary = {}
var animation_finished = false
var music_volume: float = 80.0
var sound_volume: float = 100.0
var language: String = "fa"

func _ready() -> void:
	menu_buttons = [start_button, continue_button, settings_button, about_button, exit_button]
	apply_menu_art()
	language_option.clear()
	language_option.add_item("English", 0)
	language_option.add_item("فارسی", 1)
	load_settings()
	apply_settings()
	setup_dialog_theme()
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	about_button.pressed.connect(_on_about_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	exit_dialog.confirmed.connect(get_tree().quit)
	settings_dialog.confirmed.connect(_save_settings)
	music_slider.value_changed.connect(_update_volume_labels)
	sound_slider.value_changed.connect(_update_volume_labels)
	for button in menu_buttons:
		button.disabled = true
		button.modulate.a = 0.0
		button.button_down.connect(_on_button_down.bind(button))
		button.button_up.connect(_on_button_up.bind(button))
		button.mouse_exited.connect(_on_button_mouse_exited.bind(button))
	background.modulate.a = 0.0
	menu_panel.modulate.a = 0.0
	crown.modulate.a = 0.0
	await get_tree().process_frame
	await play_intro_animation()

func apply_menu_art() -> void:
	var frame := $MenuPanel/PanelFrame as TextureRect
	var patch := NinePatchRect.new()
	patch.texture = preload("res://assets/ui/panels/panel_main.png")
	patch.patch_margin_left = 48
	patch.patch_margin_right = 48
	patch.patch_margin_top = 48
	patch.patch_margin_bottom = 48
	patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_panel.add_child(patch)
	menu_panel.move_child(patch, frame.get_index())
	patch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.hide()
	var families := ["primary", "upgrade", "management", "information", "danger"]
	for i in range(menu_buttons.size()):
		var button := menu_buttons[i]
		var path := "res://assets/ui/buttons/%s/" % families[i]
		button.texture_normal = load(path + "normal.svg") as Texture2D
		button.texture_hover = button.texture_normal
		button.texture_pressed = load(path + "pressed.svg") as Texture2D
		button.texture_disabled = load(path + "disabled.svg") as Texture2D
		var label := button.get_child(1) as Label
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_override("font", UI.bold_persian())
		label.add_theme_font_size_override("font_size", 56)
		label.add_theme_constant_override("outline_size", 3)
		label.add_theme_color_override("font_color", Color("#092E26") if i < 2 else Color("#F9F5E7"))
		label.add_theme_color_override("font_outline_color", Color("#FFE5B4") if i < 2 else Color("#092E26"))

func play_intro_animation() -> void:
	menu_panel.pivot_offset = menu_panel.size / 2.0
	menu_panel.scale = Vector2(0.75, 0.75)
	var crown_position: Vector2 = crown.position
	crown.position.y -= 180.0
	var tween = create_tween()
	tween.tween_property(background, "modulate:a", 1.0, 0.3)
	await tween.finished
	tween = create_tween().set_parallel(true)
	tween.tween_property(menu_panel, "modulate:a", 1.0, 0.4)
	tween.tween_property(menu_panel, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	tween = create_tween().set_parallel(true)
	tween.tween_property(crown, "modulate:a", 1.0, 0.4)
	tween.tween_property(crown, "position", crown_position, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	tween = create_tween().set_parallel(true)
	for i in range(menu_buttons.size()):
		var button = menu_buttons[i]
		button.pivot_offset = button.size / 2.0
		button.scale = Vector2(0.8, 0.8)
		tween.tween_property(button, "modulate:a", 1.0, 0.25).set_delay(i * 0.1)
		tween.tween_property(button, "scale", Vector2.ONE, 0.25).set_delay(i * 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	for button in menu_buttons:
		button.disabled = false
	continue_button.disabled = read_save().is_empty()
	if continue_button.disabled:
		var label := continue_button.get_child(1) as Label
		label.text = tr_menu("No saved game", "بازی ذخیره نشده")
		label.add_theme_font_size_override("font_size", 40)
	animation_finished = true

func _on_button_down(button: TextureButton) -> void:
	if animation_finished and not button.disabled:
		animate_button_scale(button, Vector2(0.95, 0.95), 0.08, Tween.TRANS_QUAD)

func _on_button_up(button: TextureButton) -> void:
	if animation_finished:
		animate_button_scale(button, Vector2.ONE, 0.15, Tween.TRANS_BACK)

func _on_button_mouse_exited(button: TextureButton) -> void:
	if animation_finished and not button.is_pressed():
		_on_button_up(button)

func animate_button_scale(button: TextureButton, target: Vector2, duration: float, transition: Tween.TransitionType) -> void:
	if button_tweens.has(button):
		var old: Tween = button_tweens[button]
		if old.is_valid():
			old.kill()
	var tween = create_tween()
	button_tweens[button] = tween
	button.pivot_offset = button.size / 2.0
	tween.tween_property(button, "scale", target, duration).set_trans(transition).set_ease(Tween.EASE_OUT)

func tr_menu(en: String, fa: String) -> String:
	return fa if language == "fa" else en

func read_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if parsed is Dictionary and parsed.get("companies") is Array and typeof(parsed.get("balance_usdt")) in [TYPE_INT, TYPE_FLOAT]:
		return parsed
	return {}

func _on_start_pressed() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		if read_save().is_empty():
			show_notice(tr_menu("Save is invalid; existing data was preserved.", "فایل ذخیره نامعتبر است؛ اطلاعات موجود حفظ شد."))
		else:
			_on_continue_pressed()
		return
	open_scene(START_PATH)

func _on_continue_pressed() -> void:
	if not read_save().is_empty():
		open_scene(CONTINUE_PATH if ResourceLoader.exists(CONTINUE_PATH) else COMPANY_PATH)

func open_scene(path: String) -> void:
	if not ResourceLoader.exists(path):
		show_notice(tr_menu("This screen is not available yet.", "این صفحه هنوز آماده نشده است."))
		return
	if get_tree().change_scene_to_file(path) != OK:
		show_notice(tr_menu("Unable to open screen.", "باز کردن صفحه ممکن نیست."))

func _on_exit_pressed() -> void:
	exit_dialog.popup_centered(Vector2i(800, 350))

func _on_about_pressed() -> void:
	about_dialog.popup_centered(Vector2i(850, 650))

func _on_settings_pressed() -> void:
	music_slider.value = music_volume
	sound_slider.value = sound_volume
	language_option.select(1 if language == "fa" else 0)
	_update_volume_labels(0.0)
	settings_dialog.popup_centered(Vector2i(850, 700))

func _update_volume_labels(_value: float) -> void:
	music_label.text = tr_menu("Music Volume", "صدای موسیقی") + " — %d%%" % int(music_slider.value)
	sound_label.text = tr_menu("Sound Effects", "جلوه‌های صوتی") + " — %d%%" % int(sound_slider.value)

func load_settings() -> void:
	var config = ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		music_volume = clampf(float(config.get_value("audio", "music", 80.0)), 0, 100)
		sound_volume = clampf(float(config.get_value("audio", "sound", 100.0)), 0, 100)
		language = "en" if config.get_value("general", "language", "fa") == "en" else "fa"

func _save_settings() -> void:
	var config = ConfigFile.new()
	var selected_language = "fa" if language_option.selected == 1 else "en"
	config.set_value("audio", "music", music_slider.value)
	config.set_value("audio", "sound", sound_slider.value)
	config.set_value("general", "language", selected_language)
	if config.save(SETTINGS_PATH) != OK:
		show_notice(tr_menu("Unable to save settings.", "ذخیره تنظیمات ناموفق بود."))
		return
	music_volume = music_slider.value
	sound_volume = sound_slider.value
	language = selected_language
	apply_settings()

func apply_settings() -> void:
	apply_bus("Music", music_volume)
	apply_bus("SFX", sound_volume)
	var en = ["START", "CONTINUE", "SETTINGS", "ABOUT", "EXIT"]
	var fa = ["شروع بازی", "ادامه", "تنظیمات", "درباره بازی", "خروج"]
	for i in range(menu_buttons.size()):
		var label = menu_buttons[i].get_child(1) as Label
		label.text = tr_menu(en[i], fa[i])
		label.add_theme_font_override("font", UI.bold_persian() if language == "fa" else UI.weighted_font(UI.ENGLISH, 700))
		if i == 1 and read_save().is_empty():
			label.text = tr_menu("No saved game", "بازی ذخیره نشده")
			label.add_theme_font_size_override("font_size", 40)
		label.text_direction = Control.TEXT_DIRECTION_RTL if language == "fa" else Control.TEXT_DIRECTION_LTR
	exit_dialog.title = tr_menu("Exit Game", "خروج از بازی")
	exit_dialog.dialog_text = tr_menu("Are you sure you want to exit the game?", "آیا می‌خواهید از بازی خارج شوید؟")
	exit_dialog.ok_button_text = tr_menu("EXIT", "خروج")
	exit_dialog.cancel_button_text = tr_menu("CANCEL", "انصراف")
	about_dialog.title = tr_menu("About Game", "درباره بازی")
	about_dialog.dialog_text = tr_menu("CRYPTONOMICS TYCOON\n\nVersion 0.1.0 — MVP\n\nBuild. Manage. Expand.\n\nPowered by Godot Engine", "CRYPTONOMICS TYCOON\n\nنسخه 0.1.0 — MVP\n\nبسازید، مدیریت کنید و توسعه دهید.\n\nساخته شده با Godot Engine")
	about_dialog.ok_button_text = tr_menu("CLOSE", "بستن")
	settings_dialog.title = tr_menu("Settings", "تنظیمات")
	settings_dialog.ok_button_text = tr_menu("SAVE", "ذخیره")
	settings_dialog.cancel_button_text = tr_menu("CANCEL", "انصراف")
	language_label.text = tr_menu("Language", "زبان")
	music_slider.value = music_volume
	sound_slider.value = sound_volume
	_update_volume_labels(0.0)

func apply_bus(bus_name: String, volume: float) -> void:
	var index = AudioServer.get_bus_index(bus_name)
	if index < 0:
		AudioServer.add_bus()
		index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_mute(index, volume <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume / 100.0, 0.0001)))

func show_notice(message: String) -> void:
	notice_dialog.title = tr_menu("Notice", "پیام")
	notice_dialog.dialog_text = message
	notice_dialog.ok_button_text = tr_menu("CLOSE", "بستن")
	notice_dialog.popup_centered(Vector2i(800, 350))

func setup_dialog_theme() -> void:
	var dialog_theme  = Theme.new()
	dialog_theme.default_font = UI.PERSIAN
	dialog_theme.default_font_size = 32
	var panel = StyleBoxFlat.new()
	panel.bg_color = Color("#075440")
	panel.border_color = Color("#E9AD32")
	panel.set_border_width_all(3)
	panel.set_corner_radius_all(18)
	panel.content_margin_left = 24
	panel.content_margin_right = 24
	panel.content_margin_top = 24
	panel.content_margin_bottom = 24
	dialog_theme.set_stylebox("embedded_border", "Window", panel)
	dialog_theme.set_color("title_color", "Window", Color("e9c77c"))
	dialog_theme.set_font_size("title_font_size", "Window", 32)
	var normal = panel.duplicate() as StyleBoxFlat
	normal.bg_color = Color("#087F69")
	var hover = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#159B80")
	for kind in ["Button", "OptionButton"]:
		dialog_theme.set_stylebox("normal", kind, normal)
		dialog_theme.set_stylebox("hover", kind, hover)
		dialog_theme.set_stylebox("pressed", kind, hover)
		dialog_theme.set_color("font_color", kind, Color("e9c77c"))
	for dialog in [exit_dialog, about_dialog, settings_dialog, notice_dialog]:
		dialog.theme = dialog_theme
