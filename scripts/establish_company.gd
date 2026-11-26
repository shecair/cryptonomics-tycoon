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
	$Create.pressed.connect(create_company)
	$Help.pressed.connect(func(): notice("نوع و اندازه شرکت را انتخاب کنید. هزینه تأسیس از خزانه هلدینگ کسر می‌شود. تجهیزات و کارکنان جداگانه خریداری می‌شوند."))
	$Back.pressed.connect(go_back)
	data = read_save()
	refresh()
	if data.is_empty():
		$Status.text = "فایل ذخیره نامعتبر است." if FileAccess.file_exists(SAVE) else "ابتدا هلدینگ را ایجاد کنید (F5)."

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
	$Remaining.text = "موجودی پس از تأسیس: %d USDT" % (balance - cost) if not data.is_empty() else "موجودی پس از تأسیس: —"
	for pair in [[$Mining,"mining"],[$Exchange,"exchange"],[$Blockchain,"blockchain"],[$Small,"small"],[$Medium,"medium"],[$Large,"large"]]:
		var button: Button = pair[0]
		var selected: bool = pair[1] == business or pair[1] == company_size
		button.modulate = Color.WHITE
		var style := button.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		style.bg_color = Color("087F69") if selected else Color("075440")
		style.border_color = Color("FFD36A") if selected else Color("B58A39")
		style.set_border_width_all(6 if selected else 3)
		button.add_theme_stylebox_override("normal", style)
	$Create.disabled = busy or data.is_empty() or balance < cost or $CompanyName.text.strip_edges().length() < 2

func change_logo(direction: int) -> void:
	logo_index = posmod(logo_index + direction, 5)
	$Logo.texture = load("res://assets/profile_holding/holding_logo_%02d.png" % (logo_index + 1)) as Texture2D
	$LogoCount.text = ""
	for i in range(5):
		$LogoCount.text += "● " if i == logo_index else "○ "
	if animation and animation.is_valid():
		animation.kill()
	$Logo.position.x = 435.0 + direction * 45.0
	$Logo.modulate.a = 0.4
	animation = create_tween().set_parallel(true)
	animation.tween_property($Logo, "position:x", 435.0, 0.2)
	animation.tween_property($Logo, "modulate:a", 1.0, 0.2)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.index == 0:
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
	refresh()
	if ResourceLoader.exists(NEXT):
		get_tree().change_scene_to_file(NEXT)
	else:
		$Status.text = "شرکت تأسیس شد؛ داشبورد هنوز آماده نیست."
