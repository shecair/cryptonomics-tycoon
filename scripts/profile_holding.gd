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

func _ready() -> void:
	apply_profile_art()
	name_pattern.compile("^[\\p{L}\\p{M}\\p{N}‌ -]+$")
	setup_name_field($PlayerName, "نام بازیکن", 12)
	setup_name_field($HoldingName, "نام هلدینگ", 12)
	$AvatarPrev.pressed.connect(change_item.bind(true, -1))
	$AvatarNext.pressed.connect(change_item.bind(true, 1))
	$LogoPrev.pressed.connect(change_item.bind(false, -1))
	$LogoNext.pressed.connect(change_item.bind(false, 1))
	$PlayerName.text_changed.connect(update_start)
	$HoldingName.text_changed.connect(update_start)
	$Start.pressed.connect(start_game)
	$Back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	$Help.pressed.connect(func(): message("دو نام وارد کنید. آواتار و لوگو اختیاری هستند. سرمایه اولیه هلدینگ ۱۰٬۰۰۰ تتر است."))
	update_start("")

func place(node: Control, x: float, y: float, w: float, h: float) -> void:
	node.position = Vector2(x, y)
	node.size = Vector2(w, h)

func section_panel(y: float, h: float) -> void:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	move_child(panel, $GameLogo.get_index())
	place(panel, 65, y, 950, h)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#075440")
	style.border_color = Color("#E9AD32")
	style.set_border_width_all(3)
	style.set_corner_radius_all(28)
	style.shadow_color = Color(0.02, 0.13, 0.09, 0.25)
	style.shadow_size = 4
	panel.add_theme_stylebox_override("panel", style)
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color("#09634F"), Color("#064538")])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_to = Vector2(0, 1)
	var fill := TextureRect.new()
	fill.texture = texture
	fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(fill)
	place(fill, 28, 4, 894, h - 8)
	# Keep the rounded outer corners and gold border visible.

func guide(value: String, y: float, size_px: int, gold: bool = false) -> void:
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)
	place(label, 90, y, 900, 52)
	UI.apply_text(label, "title" if gold else "body")
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", Color("#FFE46D") if gold else Color("#F9F5E7"))

func section_title(value: String, number: String, y: float) -> void:
	var heading := Label.new()
	heading.text = value
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(heading)
	UI.apply_text(heading, "title")
	heading.add_theme_font_size_override("font_size", 50)
	heading.add_theme_color_override("font_color", Color("#FFE46D"))
	var width := heading.get_minimum_size().x + 12.0
	var left := (1080.0 - width - 82.0) / 2.0
	place(heading, left, y, width, 70)
	var badge := Label.new()
	badge.text = number
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(badge)
	UI.apply_text(badge, "title")
	badge.add_theme_font_size_override("font_size", 40)
	badge.add_theme_color_override("font_color", Color("#092E26"))
	var circle := StyleBoxFlat.new()
	circle.bg_color = Color("#FFE46D")
	circle.set_corner_radius_all(35)
	circle.border_color = Color("#E9AD32")
	circle.set_border_width_all(2)
	badge.add_theme_stylebox_override("normal", circle)
	place(badge, left + width + 12, y, 70, 70)

func apply_profile_art() -> void:
	theme = UI.THEME
	for button in [$AvatarPrev, $AvatarNext, $LogoPrev, $LogoNext]:
		UI.apply_button(button, "management")
		button.add_theme_font_size_override("font_size", 68)
	UI.apply_button($Back, "danger")
	UI.apply_button($Help, "information")
	UI.apply_button($Start, "primary")
	$Start.add_theme_font_size_override("font_size", 44)
	$Start.text = "شروع ماجراجویی"
	$Start.add_theme_color_override("font_disabled_color", Color("#263C34"))
	place($GameLogo, 265, 15, 550, 235)
	place($Title, 65, 246, 950, 76)
	$Title.text = "امپراتوری اقتصادی خودت را بساز!"
	UI.apply_text($Title, "title")
	$Title.add_theme_color_override("font_color", Color("#075440"))
	$Title.add_theme_constant_override("outline_size", 0)
	section_panel(330, 540)
	section_panel(910, 490)
	section_panel(1440, 235)
	section_title("شخصیت خودت را بساز", "۱", 345)
	guide("دوست داری در دنیای کسب‌وکار چه کسی باشی؟", 408, 32)
	section_title("هلدینگ خودت را تأسیس کن", "۲", 925)
	guide("نام و نشان امپراتوری خودت را انتخاب کن.", 988, 32)
	guide("↓", 866, 42, true)
	guide("↓", 1396, 42, true)
	section_title("سرمایه آغاز ماجراجویی", "۳", 1450)
	guide("اولین سرمایه برای ساخت آینده اقتصادی تو!", 1610, 30)
	$AvatarHalo.show()
	place($AvatarHalo, 402, 450, 276, 235)
	var avatar_style := StyleBoxFlat.new()
	avatar_style.bg_color = Color("#087F69")
	avatar_style.border_color = Color("#E9AD32")
	avatar_style.set_border_width_all(3)
	avatar_style.set_corner_radius_all(24)
	$AvatarHalo.add_theme_stylebox_override("panel", avatar_style)
	place($Avatar, 375, 450, 330, 235)
	place($AvatarPrev, 210, 505, 120, 120)
	place($AvatarNext, 750, 505, 120, 120)
	place($AvatarCount, 390, 680, 300, 45)
	place($PlayerName, 115, 738, 850, 102)
	place($HoldingLogo, 430, 1030, 220, 180)
	place($LogoPrev, 275, 1060, 120, 120)
	place($LogoNext, 685, 1060, 120, 120)
	place($LogoCount, 390, 1208, 300, 45)
	place($HoldingName, 115, 1268, 850, 102)
	for field in [$PlayerName, $HoldingName]:
		field.add_theme_font_override("font", UI.weighted_font(UI.PERSIAN, 500))
		field.add_theme_font_size_override("font_size", 40)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#FFF8E6")
		style.border_color = Color("#E9AD32")
		style.set_border_width_all(2)
		style.set_corner_radius_all(20)
		style.content_margin_left = 16
		style.content_margin_right = 16
		field.add_theme_stylebox_override("normal", style)
		var focus := style.duplicate() as StyleBoxFlat
		focus.border_color = Color("#FFE46D")
		focus.set_border_width_all(3)
		field.add_theme_stylebox_override("focus", focus)
	$CapitalPlate.hide()
	$CapitalLabel.hide()
	place($CapitalIcon, 145, 1510, 95, 95)
	$CapitalIcon.texture = load("res://assets/profile_holding/tether_simple.svg") as Texture2D
	var separator := ColorRect.new()
	separator.color = Color("#E9AD32")
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(separator)
	place(separator, 265, 1525, 3, 70)
	place($Capital, 285, 1515, 660, 95)
	UI.apply_text($Capital, "money")
	$Capital.add_theme_constant_override("outline_size", 0)
	place($Start, 105, 1700, 870, 125)
	place($Status, 65, 1830, 950, 65)
	UI.apply_text($Status, "hint")
	$Status.add_theme_font_size_override("font_size", 32)

func setup_name_field(field: LineEdit, caption: String, limit: int) -> void:
	var y := field.position.y
	field.position.y += 10
	field.size = Vector2(540, 70)
	field.max_length = limit
	field.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	field.placeholder_text = ""
	var title := Label.new()
	title.text = caption + ":"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	place(title, 665, y + 10, 290, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI.apply_text(title, "title")
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color("#FFE46D"))
	title.show()
	var hint := Label.new()
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
	place(hint, field.position.x, y + 80, 850, 40)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UI.apply_text(hint, "hint")
	hint.add_theme_font_size_override("font_size", 32)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	field_guides[field] = [title, hint, caption, limit]
	field.focus_entered.connect(func(): refresh_name_field(field))
	field.focus_exited.connect(func(): refresh_name_field(field))
	refresh_name_field(field)

func valid_name(value: String, limit: int) -> bool:
	var clean := value.strip_edges()
	return clean.length() >= 2 and clean.length() <= limit and name_pattern.search(clean) != null

func refresh_name_field(field: LineEdit) -> void:
	var info: Array = field_guides[field]
	var title: Label = info[0]
	var hint: Label = info[1]
	var limit: int = info[3]
	var valid := valid_name(field.text, limit)
	title.visible = true
	field.placeholder_text = ""
	var color := Color("#E9AD32") if field.text.is_empty() else (Color("#65CF23") if valid else Color("#D83C32"))
	var style := field.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	style.border_color = color
	field.add_theme_stylebox_override("normal", style)
	var focus := style.duplicate() as StyleBoxFlat
	focus.set_border_width_all(3)
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
	var original_x := 375.0 if is_avatar else 430.0
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
