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
var dots: Array[Label] = []
var checks: Array[Label] = []
var subtitle: Label
var amount_label: Label

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
	amount_label.text = "%s USDT" % str(balance) if not data.is_empty() else "—"
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
		style.bg_color = Color("087F69") if selected else Color("FFF5D9")
		style.border_color = Color("DDAA38") if selected else Color("DCC88E")
		style.set_border_width_all(6 if selected else 3)
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_stylebox_override("pressed", style)
		for child in button.get_children():
			if child is Label:
				child.add_theme_color_override("font_color", Color("FFFFFF") if selected else Color("075440"))
	for i in range(checks.size()):
		checks[i].visible = ["mining", "exchange", "blockchain"][i] == business and step == 0
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
	$Background.hide()
	var backdrop := ColorRect.new()
	backdrop.color = Color("F5E5B0")
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	move_child(backdrop, 0)
	place(backdrop, 0, 0, 1080, 1920)
	make_label("CRYPTONOMICS", 260, 35, 560, 65, 48, Color("075440"))
	make_label("TYCOON", 260, 100, 560, 65, 48, Color("A87613"))
	place($Back, 900, 55, 110, 85)
	place($Help, 65, 55, 90, 85)
	place($BalancePlate, 65, 215, 950, 320)
	avatar_view = make_texture("res://assets/profile_holding/avatar_%02d.png" % clampi(int(data.get("avatar", 1)), 1, 6), 845, 235, 140, 140)
	holding_view = make_texture("res://assets/profile_holding/holding_logo_%02d.png" % clampi(int(data.get("holding_logo", 1)), 1, 5), 350, 245, 115, 115)
	player_label = make_label(str(data.get("player_name", "—")), 500, 240, 330, 65, 38, Color("FFF5D9"))
	holding_label = make_label(str(data.get("holding_name", "—")), 75, 245, 265, 115, 38, Color("FFF5D9"))
	make_label("مدیر هلدینگ", 500, 305, 330, 65, 30, Color("F5D68B"))
	var line := ColorRect.new()
	line.color = Color("4D8979")
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(line)
	place(line, 95, 405, 890, 3)
	place($Balance, 565, 425, 400, 80)
	$Balance.text = "خزانه هلدینگ"
	amount_label = make_label("", 95, 425, 440, 80, 42, Color("FFE4A0"))
	for i in range(3):
		var x := 850 - i * 365
		var dot := make_label(str(i + 1), x, 570, 90, 90, 42, Color("075440"))
		dots.append(dot)
		make_label(["کسب‌وکار", "هویت شرکت", "تأسیس"][i], x - 80, 660, 250, 60, 30, Color("075440"))
		if i < 2:
			var connector := ColorRect.new()
			connector.color = Color("CDBD8A")
			connector.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(connector)
			place(connector, x - 255, 613, 220, 5)
	step_label = make_label("", 0, 0, 1, 1, 1, Color.TRANSPARENT)
	subtitle = make_label("", 65, 800, 950, 70, 34, Color("526B51"))
	place($BusinessTitle, 35, 720, 1010, 80)
	$BusinessTitle.text = "آینده‌ات را انتخاب کن!"
	for i in range(3):
		var card: Button = [$Mining, $Exchange, $Blockchain][i]
		place(card, 75, 890 + i * 230, 930, 205)
		var art: TextureRect = card.get_node("Art")
		art.show()
		place(art, 715, 15, 175, 175)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		place(card.get_node("Caption"), 180, 10, 520, 185)
		card.get_node("Caption").text = ["استخراج رمزارز", "صرافی رمزارز", "توسعه بلاکچین"][i]
		var check := make_label("✓", 95, 945 + i * 230, 90, 90, 50, Color("F5D68B"))
		checks.append(check)
	place($Logo, 360, 900, 360, 360)
	place($LogoPrev, 180, 1025, 110, 110)
	place($LogoNext, 790, 1025, 110, 110)
	place($LogoCount, 200, 1280, 680, 70)
	place($CompanyName, 75, 1370, 930, 120)
	place($SizeTitle, 35, 720, 1010, 80)
	$SizeTitle.text = "از کجا شروع می‌کنی؟"
	for i in range(3):
		var card: Button = [$Small, $Medium, $Large][i]
		place(card, 24 + i * 348, 890, 336, 340)
	place($CostPlate, 55, 1260, 970, 270)
	place($Cost, 75, 1270, 930, 100)
	place($Remaining, 75, 1380, 930, 110)
	place($Create, 75, 1690, 930, 140)
	place($Status, 45, 1560, 990, 120)
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
	subtitle.text = ["دوست داری در چه حوزه‌ای فعالیت کنی؟", "نام و نشان تجاری خودت را انتخاب کن.", "اندازه شرکت و هزینه تأسیس را بررسی کن."][step]
	for i in range(dots.size()):
		var style := StyleBoxFlat.new()
		style.bg_color = Color("087F69") if i <= step else Color("DCC88E")
		style.set_corner_radius_all(45)
		dots[i].add_theme_stylebox_override("normal", style)
		dots[i].add_theme_color_override("font_color", Color.WHITE if i <= step else Color("72581D"))
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
