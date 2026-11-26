extends Control

const UI = preload("res://scripts/ui/game_ui.gd")

const ASSETS = "res://assets/profile_holding/"
const SAVE = "user://savegame.json"
const NEXT = "res://scenes/establish_company.tscn"
var avatar_index := 0
var logo_index := 0
var animations: Dictionary = {}
var drag_start := Vector2.ZERO
var drag_target := 0
var saved := false
var name_pattern := RegEx.new()
var field_guides: Dictionary = {}
var preview_origins: Dictionary = {}

func _ready() -> void:
	preview_origins[$Avatar] = $Avatar.position.x
	preview_origins[$HoldingLogo] = $HoldingLogo.position.x
	name_pattern.compile("^[\\p{L}\\p{M}\\p{N}‌ -]+$")
	setup_name_field($PlayerName, $PlayerNameLabel, $PlayerNameHint, 12)
	setup_name_field($HoldingName, $HoldingNameLabel, $HoldingNameHint, 12)
	$AvatarPrev.pressed.connect(change_item.bind(true, -1))
	$AvatarNext.pressed.connect(change_item.bind(true, 1))
	$LogoPrev.pressed.connect(change_item.bind(false, -1))
	$LogoNext.pressed.connect(change_item.bind(false, 1))
	$PlayerName.text_changed.connect(update_start)
	$HoldingName.text_changed.connect(update_start)
	$Start.pressed.connect(start_game)
	$SharedHeader/Stack/Top/Menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	$SharedHeader/Stack/Top/Help.pressed.connect(func(): message("دو نام وارد کنید. آواتار و لوگو اختیاری هستند. سرمایه اولیه هلدینگ ۱۰٬۰۰۰ تتر است."))
	update_start("")

func setup_name_field(field: LineEdit, title: Label, hint: Label, limit: int) -> void:
	field_guides[field] = [title, hint, title.text, limit]
	field.focus_entered.connect(func(): refresh_name_field(field))
	field.focus_exited.connect(func(): refresh_name_field(field))
	refresh_name_field(field)

func valid_name(value: String, limit: int) -> bool:
	var clean := value.strip_edges()
	return clean.length() >= 2 and clean.length() <= limit and name_pattern.search(clean) != null

func refresh_name_field(field: LineEdit) -> void:
	var info: Array = field_guides[field]
	var hint: Label = info[1]
	var limit: int = info[3]
	var valid := valid_name(field.text, limit)
	var color := Color("#E9AD32") if field.text.is_empty() else (Color("#65CF23") if valid else Color("#D83C32"))
	var style := field.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	style.border_color = color
	field.add_theme_stylebox_override("normal", style)
	var focus := style.duplicate() as StyleBoxFlat
	field.add_theme_stylebox_override("focus", focus)
	var message_text := "۲ تا %d حرف، عدد یا فاصله" % limit
	if not field.text.is_empty():
		message_text = "✓ نام معتبر است" if valid else "نام نامعتبر؛ حروف، اعداد و فاصله مجازند"
	hint.text = "%s   |   %d/%d" % [message_text, field.text.length(), limit]
	hint.add_theme_color_override("font_color", Color("#FFE5B4") if field.text.is_empty() else (Color("#A8EF80") if valid else Color("#FFB6AB")))

func update_start(_value: String) -> void:
	refresh_name_field($PlayerName)
	refresh_name_field($HoldingName)
	var warning := ""
	if not saved:
		if not valid_name($PlayerName.text, 12):
			warning = "نام بازیکن را کامل کنید."
		elif not valid_name($HoldingName.text, 12):
			warning = "نام هلدینگ را کامل کنید."
	$Start.disabled = saved or not warning.is_empty()
	$Status.text = ""
	if not warning.is_empty():
		var invalid_field: LineEdit = $PlayerName if not valid_name($PlayerName.text, 12) else $HoldingName
		if invalid_field.text.is_empty():
			var hint: Label = field_guides[invalid_field][1]
			hint.text = "نام الزامی است؛ ۲ تا ۱۲ کاراکتر | 0/12"
	$Status.add_theme_color_override("font_color", Color("8B291C"))

func change_item(is_avatar: bool, direction: int) -> void:
	var preview: TextureRect = $Avatar if is_avatar else $HoldingLogo
	var counter: Label = $AvatarCount if is_avatar else $LogoCount
	var count := 6 if is_avatar else 5
	var index := posmod((avatar_index if is_avatar else logo_index) + direction, count)
	if is_avatar:
		avatar_index = index
	else:
		logo_index = index
	var prefix := "avatar_" if is_avatar else "holding_logo_"
	preview.texture = load(ASSETS + prefix + "%02d.png" % (index + 1)) as Texture2D
	counter.text = ""
	for i in range(count):
		counter.text += ("●" if i == index else "○") + (" " if i < count - 1 else "")
	if animations.has(preview):
		animations[preview].kill()
	var original_x: float = preview_origins[preview]
	preview.position.x = original_x + direction * 55.0
	preview.modulate.a = 0.4
	var tween := create_tween().set_parallel(true)
	animations[preview] = tween
	tween.tween_property(preview, "position:x", original_x, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(preview, "modulate:a", 1.0, 0.2)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.index != 0:
			return
		if event.pressed:
			drag_start = event.position
			drag_target = 1 if $Avatar.get_global_rect().has_point(event.position) else (2 if $HoldingLogo.get_global_rect().has_point(event.position) else 0)
		else:
			finish_swipe(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not OS.has_feature("mobile"):
		if event.pressed:
			drag_start = event.position
			drag_target = 1 if $Avatar.get_global_rect().has_point(event.position) else (2 if $HoldingLogo.get_global_rect().has_point(event.position) else 0)
		else:
			finish_swipe(event.position)

func finish_swipe(point: Vector2) -> void:
	var delta := point - drag_start
	if drag_target != 0 and absf(delta.x) > 45.0 and absf(delta.x) > absf(delta.y):
		change_item(drag_target == 1, 1 if delta.x < 0 else -1)
	drag_target = 0

func message(value: String) -> void:
	$Notice.dialog_text = value
	$Notice.popup_centered(Vector2i(780, 300))

func start_game() -> void:
	if $Start.disabled:
		return
	if FileAccess.file_exists(SAVE):
		message("بازی ذخیره‌شده وجود دارد؛ برای حفظ اطلاعات، بازنویسی انجام نشد.")
		return
	var data := {"version": 1, "player_name": $PlayerName.text.strip_edges(), "avatar": avatar_index + 1, "holding_name": $HoldingName.text.strip_edges(), "holding_logo": logo_index + 1, "balance_usdt": 10000, "companies": []}
	var file := FileAccess.open(SAVE, FileAccess.WRITE)
	if file == null:
		message("ذخیره اطلاعات ناموفق بود.")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var err := file.get_error()
	file.close()
	if err != OK:
		message("ذخیره اطلاعات ناموفق بود.")
		return
	saved = true
	update_start("")
	if ResourceLoader.exists(NEXT):
		if get_tree().change_scene_to_file(NEXT) != OK:
			message("هلدینگ ذخیره شد؛ باز کردن مرحله بعد ناموفق بود. از منوی اصلی ادامه دهید.")
	else:
		$Status.text = "هلدینگ ایجاد شد؛ مرحله بعد هنوز آماده نیست."
