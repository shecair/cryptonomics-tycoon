extends Control

const ASSETS = "res://assets/profile_holding/"
const SAVE = "user://savegame.json"
const NEXT = "res://scenes/start_company.tscn"
var avatar_index := 0
var logo_index := 0
var animations: Dictionary = {}
var drag_start := Vector2.ZERO
var drag_target := 0
var saved := false

func _ready() -> void:
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

func update_start(_value: String) -> void:
	$Start.disabled = saved or $PlayerName.text.strip_edges().length() < 2 or $HoldingName.text.strip_edges().length() < 2

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
	file.close()
	saved = true
	update_start("")
	if ResourceLoader.exists(NEXT):
		get_tree().change_scene_to_file(NEXT)
	else:
		$Status.text = "هلدینگ ایجاد شد؛ مرحله بعد هنوز آماده نیست."
