extends Control
const SAVE = "user://savegame.json"
const NEXT = "res://scenes/holding_dashboard.tscn"
const COSTS = {"small": 1000, "medium": 3000, "large": 6000}
var data: Dictionary = {}
var business := "mining"
var company_size := "small"
var logo_index := 0
var busy := false
var animation: Tween
var swipe_start := Vector2.ZERO
var swiping := false
var step := 0
var step_label: Label
var player_label: Label
var holding_label: Label
var avatar_view: TextureRect
var holding_view: TextureRect
var step_tween: Tween
var completed := false

func _ready() -> void:
	$Mining.pressed.connect(select_business.bind("mining"))
	$Exchange.pressed.connect(select_business.bind("exchange"))
	$Blockchain.pressed.connect(select_business.bind("blockchain"))
	$Small.pressed.connect(select_size.bind("small"))
	$Medium.pressed.connect(select_size.bind("medium"))
	$Large.pressed.connect(select_size.bind("large"))
	$LogoPrev.pressed.connect(change_logo.bind(-1))
	$LogoNext.pressed.connect(change_logo.bind(1))
	$CompanyName.text_changed.connect(func(_text: String): refresh())
	$Create.pressed.connect(advance_step)
	$Help.pressed.connect(func(): notice("نوع و اندازه شرکت را انتخاب کنید. هزینه تأسیس از خزانه هلدینگ کسر می‌شود. تجهیزات و کارکنان جداگانه خریداری می‌شوند."))
	$Back.pressed.connect(go_back)
	data = read_save()
	setup_wizard()
	refresh()
	if data.is_empty():
		$Status.text = "فایل ذخیره نامعتبر است." if FileAccess.file_exists(SAVE) else "ابتدا هلدینگ را ایجاد کنید (F5)."
		push_warning("Holding save unavailable: " + ProjectSettings.globalize_path(SAVE))

func read_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	if parsed is Dictionary and parsed.has("balance_usdt") and parsed.get("companies") is Array:
		if typeof(parsed["balance_usdt"]) in [TYPE_INT, TYPE_FLOAT]:
			return parsed
	return {}

func select_business(value: String) -> void:
	business = value
	refresh()

func select_size(value: String) -> void:
	company_size = value
	refresh()

func refresh() -> void:
	var balance := int(data.get("balance_usdt", 0))
	var cost := int(COSTS[company_size])
	$Balance.text = "موجودی هلدینگ: %d USDT" % balance if not data.is_empty() else "موجودی هلدینگ: —"
	$Cost.text = "هزینه تأسیس: %d USDT" % cost
	if data.is_empty():
		$Remaining.text = "موجودی پس از تأسیس: —"
	elif balance < cost:
		$Remaining.text = "کمبود سرمایه: %d USDT" % (cost - balance)
	else:
		$Remaining.text = "موجودی پس از تأسیس: %d USDT" % (balance - cost)
	for pair in [[$Mining,"mining"],[$Exchange,"exchange"],[$Blockchain,"blockchain"],[$Small,"small"],[$Medium,"medium"],[$Large,"large"]]:
		var button: Button = pair[0]
		var selected: bool = pair[1] == business or pair[1] == company_size
		button.modulate = Color.WHITE
		var style := button.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		style.bg_color = Color("087F69") if selected else Color("075440")
		style.border_color = Color("FFD36A") if selected else Color("B58A39")
		style.set_border_width_all(6 if selected else 3)
		button.add_theme_stylebox_override("normal", style)
	update_wizard_state(balance, cost)

func change_logo(direction: int) -> void:
	logo_index = posmod(logo_index + direction, 5)
	$Logo.texture = load("res://assets/profile_holding/holding_logo_%02d.png" % (logo_index + 1)) as Texture2D
	$LogoCount.text = ""
	for i in range(5):
		$LogoCount.text += "● " if i == logo_index else "○ "
	if animation and animation.is_valid():
		animation.kill()
	$Logo.position.x = 360.0 + direction * 45.0
	$Logo.modulate.a = 0.4
	animation = create_tween().set_parallel(true)
	animation.tween_property($Logo, "position:x", 360.0, 0.2)
	animation.tween_property($Logo, "modulate:a", 1.0, 0.2)

func _input(event: InputEvent) -> void:
	if step == 1 and event is InputEventScreenTouch and event.index == 0:
		if event.pressed:
			swipe_start = event.position
			swiping = $Logo.get_global_rect().has_point(event.position)
		elif swiping:
			swiping = false
			var delta: Vector2 = event.position - swipe_start
			if absf(delta.x) > 45 and absf(delta.x) > absf(delta.y):
				change_logo(1 if delta.x < 0 else -1)

func notice(text: String) -> void:
	$Notice.dialog_text = text
	$Notice.popup_centered(Vector2i(780, 300))

func go_back() -> void:
	if step > 0 and not completed:
		step -= 1
		show_step()
		refresh()
		return
	var target := NEXT if ResourceLoader.exists(NEXT) and not data.is_empty() else "res://scenes/main_menu.tscn"
	get_tree().change_scene_to_file(target)

func create_company() -> void:
	if $Create.disabled:
		return
	var latest := read_save()
	var cost := int(COSTS[company_size])
	if latest.is_empty() or int(latest.get("balance_usdt", 0)) < cost:
		data = latest
		refresh()
		notice("موجودی کافی نیست یا فایل ذخیره معتبر نیست.")
		return
	var company_name: String = $CompanyName.text.strip_edges()
	if company_name.length() < 2 or company_name.length() > 30:
		return
	busy = true
	refresh()
	var companies: Array = latest["companies"]
	companies.append({"id": Crypto.new().generate_random_bytes(16).hex_encode(), "name": company_name, "business": business, "size": company_size, "logo": logo_index + 1, "establishment_cost_usdt": cost, "balance_usdt": 0, "workers": 0, "units": [], "profit_usdt": 0, "status": "active"})
	latest["balance_usdt"] = int(latest["balance_usdt"]) - cost
	var temp := SAVE + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		busy = false
		refresh()
		notice("ذخیره ناموفق بود.")
		return
	file.store_string(JSON.stringify(latest, "\t"))
	file.flush()
	var err := file.get_error()
	file.close()
	if err != OK or DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(SAVE)) != OK:
		busy = false
		refresh()
		notice("ذخیره ناموفق بود؛ دوباره تلاش کنید.")
		return
	data = latest
	completed = true
	refresh()
	if ResourceLoader.exists(NEXT):
		get_tree().change_scene_to_file(NEXT)
	else:
		$Status.text = "شرکت تأسیس شد؛ داشبورد هنوز آماده نیست."


func place(node: Control, x: float, y: float, w: float, h: float) -> void:
	node.position = Vector2(x, y)
	node.size = Vector2(w, h)

func make_label(value: String, x: float, y: float, w: float, h: float, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	place(label, x, y, w, h)
	return label

func make_texture(path: String, x: float, y: float, w: float, h: float) -> TextureRect:
	var view := TextureRect.new()
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(path):
		view.texture = load(path) as Texture2D
	add_child(view)
	place(view, x, y, w, h)
	return view

func setup_wizard() -> void:
	$Title.hide()
	make_texture("res://assets/loading/logo.png", 310, 10, 460, 220)
	place($BalancePlate, 35, 245, 1010, 245)
	avatar_view = make_texture("res://assets/profile_holding/avatar_%02d.png" % clampi(int(data.get("avatar", 1)), 1, 6), 65, 260, 145, 145)
	holding_view = make_texture("res://assets/profile_holding/holding_logo_%02d.png" % clampi(int(data.get("holding_logo", 1)), 1, 5), 565, 270, 125, 125)
	player_label = make_label(str(data.get("player_name", "—")), 215, 270, 330, 115, 38, Color("FFF5D9"))
	holding_label = make_label(str(data.get("holding_name", "—")), 695, 270, 320, 115, 38, Color("FFF5D9"))
	place($Balance, 65, 405, 950, 75)
	step_label = make_label("", 35, 505, 1010, 90, 40, Color("075440"))
	place($BusinessTitle, 35, 605, 1010, 100)
	$BusinessTitle.text = "آینده‌ات را انتخاب کن!"
	for i in range(3):
		var card: Button = [$Mining, $Exchange, $Blockchain][i]
		place(card, 75, 725 + i * 270, 930, 245)
		place(card.get_node("Art"), 25, 10, 225, 225)
		place(card.get_node("Caption"), 260, 20, 640, 205)
	place($Logo, 360, 770, 360, 360)
	place($LogoPrev, 180, 900, 110, 110)
	place($LogoNext, 790, 900, 110, 110)
	place($LogoCount, 200, 1150, 680, 70)
	place($CompanyName, 75, 1260, 930, 120)
	place($SizeTitle, 35, 605, 1010, 100)
	$SizeTitle.text = "از کجا شروع می‌کنی؟"
	for i in range(3):
		var card: Button = [$Small, $Medium, $Large][i]
		place(card, 24 + i * 348, 740, 336, 340)
	place($CostPlate, 55, 1130, 970, 270)
	place($Cost, 75, 1150, 930, 100)
	place($Remaining, 75, 1260, 930, 110)
	place($Create, 75, 1570, 930, 140)
	place($Status, 45, 1730, 990, 130)
	$Status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	show_step(false)

func show_step(animate: bool = true) -> void:
	var groups := [[$Mining, $Exchange, $Blockchain], [$Logo, $LogoPrev, $LogoNext, $LogoCount, $CompanyName], [$SizeTitle, $Small, $Medium, $Large, $CostPlate, $Cost, $Remaining]]
	if step_tween and step_tween.is_valid():
		step_tween.kill()
	if animate:
		step_tween = create_tween().set_parallel(true)
	for i in range(groups.size()):
		for node in groups[i]:
			node.visible = i == step
			node.modulate.a = 1.0
			if animate and i == step:
				node.modulate.a = 0.0
				step_tween.tween_property(node, "modulate:a", 1.0, 0.25)
	$BusinessTitle.visible = step != 2
	$BusinessTitle.text = "آینده‌ات را انتخاب کن!" if step == 0 else "به شرکتت هویت بده!"
	step_label.text = ["۱ از ۳  •  انتخاب کسب‌وکار", "۲ از ۳  •  هویت شرکت", "۳ از ۳  •  اندازه و تأسیس"][step]
	$Create.text = "تأسیس شرکت" if step == 2 else "ادامه"

func update_wizard_state(balance: int, cost: int) -> void:
	var warning := ""
	var length: int = $CompanyName.text.strip_edges().length()
	if data.is_empty():
		warning = "ابتدا هلدینگ معتبر ایجاد کنید."
	elif step == 1 and (length < 2 or length > 30):
		warning = "نام شرکت باید بین ۲ تا ۳۰ حرف باشد."
	elif step == 2 and balance < cost:
		warning = "سرمایه کافی برای این اندازه شرکت ندارید."
	$Create.disabled = busy or completed or not warning.is_empty()
	$Status.text = warning
	$Status.add_theme_color_override("font_color", Color("8B291C"))

func advance_step() -> void:
	if $Create.disabled:
		return
	if step < 2:
		step += 1
		show_step()
		refresh()
	else:
		create_company()
