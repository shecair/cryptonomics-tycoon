extends Control
const SAVE = "user://savegame.json"
const GREEN = Color("075440")
const GOLD = Color("FFE4A0")
const CREAM = Color("FFF5D9")
var data: Dictionary = {}
var companies: Array = []
var body: VBoxContainer
var nav: HBoxContainer
var create: Button
var tab := 0

func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE)) if FileAccess.file_exists(SAVE) else null
	if parsed is Dictionary and parsed.get("companies") is Array and typeof(parsed.get("balance_usdt")) in [TYPE_INT, TYPE_FLOAT]:
		data = parsed
		companies = data["companies"]
	var bg := picture("res://assets/loading/background.png", Vector2.ZERO)
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)
	var top := HBoxContainer.new()
	root.add_child(top)
	top.add_child(action("؟", func(): notice("شرکت‌های خود را مدیریت کنید یا با سرمایه خزانه شرکت جدید بسازید."), false, Vector2(75,75)))
	var logo := picture("res://assets/loading/logo.png", Vector2(0,150))
	logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(logo)
	top.add_child(action("منو", func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"), false, Vector2(90,75)))
	var identity := panel(root, GREEN)
	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	identity.add_child(row)
	row.add_child(picture("res://assets/profile_holding/holding_logo_%02d.png" % clampi(int(data.get("holding_logo",1)),1,5), Vector2(115,115)))
	var holding := label(str(data.get("holding_name","—")),38,Color.WHITE)
	holding.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holding.clip_text = true
	holding.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(holding)
	var person := VBoxContainer.new()
	person.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(person)
	var player := label(str(data.get("player_name","—")),38,Color.WHITE)
	player.clip_text = true
	player.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	person.add_child(player)
	person.add_child(label("مدیر هلدینگ",28,GOLD))
	row.add_child(picture("res://assets/profile_holding/avatar_%02d.png" % clampi(int(data.get("avatar",1)),1,6),Vector2(125,125)))
	identity.add_child(HSeparator.new())
	var cash := HBoxContainer.new()
	cash.layout_direction = Control.LAYOUT_DIRECTION_RTL
	identity.add_child(cash)
	var amount := label(money(int(data.get("balance_usdt",0))) if not data.is_empty() else "—",55,GOLD)
	amount.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cash.add_child(amount)
	var treasury := label("خزانه هلدینگ",34,GOLD)
	treasury.custom_minimum_size.x = 360
	cash.add_child(treasury)
	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation",20)
	root.add_child(metrics)
	metrics.layout_direction = Control.LAYOUT_DIRECTION_RTL
	var active := 0
	var profit := 0
	for c in companies:
		if c is Dictionary:
			if c.get("status","active") == "active":
				active += 1
			profit += int(c.get("profit_usdt",0))
	for item in [[str(active),"شرکت‌های فعال"],[money(profit),"سود عملیاتی"]]:
		var card := panel(metrics,CREAM)
		card.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_child(label(item[0],48,GREEN))
		card.add_child(label(item[1],32,GREEN))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",22)
	scroll.add_child(body)
	create = action("+ تأسیس شرکت جدید",func(): get_tree().change_scene_to_file("res://scenes/establish_company.tscn"),true)
	root.add_child(create)
	nav = HBoxContainer.new()
	nav.layout_direction = Control.LAYOUT_DIRECTION_RTL
	root.add_child(nav)
	render()

func money(value: int) -> String:
	var raw := str(absi(value))
	var result := ""
	for i in range(raw.length()):
		if i > 0 and (raw.length()-i)%3 == 0:
			result += ","
		result += raw[i]
	return ("-" if value < 0 else "") + result + " USDT"

func picture(path: String, minimum: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.custom_minimum_size = minimum
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(path):
		t.texture = load(path) as Texture2D
	return t

func label(value: String, font: int, color: Color) -> Label:
	var l := Label.new()
	l.text = value
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.add_theme_font_size_override("font_size",font)
	l.add_theme_color_override("font_color",color)
	return l

func style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = Color("DCC88E")
	s.set_border_width_all(3)
	s.set_corner_radius_all(26)
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:
		s.set_content_margin(side,22)
	return s

func panel(parent: Control, color: Color) -> VBoxContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel",style(color))
	parent.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation",12)
	p.add_child(v)
	return v

func action(value: String, callback: Callable, gold: bool = false, minimum: Vector2 = Vector2(0,100)) -> Button:
	var b := Button.new()
	b.text = value
	b.custom_minimum_size = minimum
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size",34)
	for state in ["normal","hover","pressed","disabled"]:
		b.add_theme_stylebox_override(state,style(Color("DDAA38") if gold else GREEN))
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		b.add_theme_color_override(state,GREEN if gold else Color.WHITE)
	b.pressed.connect(callback)
	return b

func render() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	for child in nav.get_children():
		nav.remove_child(child)
		child.queue_free()
	create.visible = tab == 0 and not data.is_empty()
	create.disabled = int(data.get("balance_usdt",0)) < 1000
	for i in [2,1,0]:
		var b := action(["▥\nهلدینگ","▤\nمالی","♙\nپروفایل"][i],select_tab.bind(i),tab==i)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav.add_child(b)
	if data.is_empty():
		body.add_child(label("فایل ذخیره معتبر نیست. به منوی اصلی بازگردید.",36,GREEN))
		return
	if tab == 0:
		var heading := panel(body,CREAM)
		heading.add_child(label("شرکت‌های من  •  " + str(companies.size()),36,GREEN))
		for c in companies:
			if c is Dictionary:
				company_card(c)
		if companies.is_empty():
			body.add_child(label("هنوز شرکتی تأسیس نکرده‌اید.",34,GREEN))
		if int(data.get("balance_usdt",0)) < 1000:
			create.disabled = true
			body.add_child(label("برای تأسیس شرکت حداقل ۱٬۰۰۰ USDT لازم است.",32,Color("8B291C")))
	elif tab == 1:
		var p := panel(body,CREAM)
		p.add_child(label("گزارش مالی هلدینگ",44,GREEN))
		var cost := 0
		var profit := 0
		for c in companies:
			if c is Dictionary:
				cost += int(c.get("establishment_cost_usdt",0))
				profit += int(c.get("profit_usdt",0))
		for item in [["سرمایه اولیه",10000],["هزینه تأسیس شرکت‌ها",cost],["خزانه هلدینگ",int(data.get("balance_usdt",0))],["سود عملیاتی",profit]]:
			p.add_child(label(item[0] + "  |  " + money(item[1]),36,GREEN))
			p.add_child(HSeparator.new())
	else:
		var p := panel(body,CREAM)
		p.add_child(picture("res://assets/profile_holding/avatar_%02d.png" % clampi(int(data.get("avatar",1)),1,6),Vector2(0,280)))
		p.add_child(label(str(data.get("player_name","—")),48,GREEN))
		p.add_child(label("مدیر " + str(data.get("holding_name","—")),36,GREEN))

func select_tab(value: int) -> void:
	tab = value
	render()

func company_card(c: Dictionary) -> void:
	var p := panel(body,CREAM)
	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	p.add_child(row)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(details)
	var company_name := label(str(c.get("name","—")),42,GREEN)
	company_name.clip_text = true
	company_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	details.add_child(company_name)
	var kind := str(c.get("business","mining"))
	var size_name: String = {"small":"کوچک","medium":"متوسط","large":"بزرگ"}.get(str(c.get("size","small")),"—")
	var kind_name: String = {"mining":"استخراج رمزارز","exchange":"صرافی رمزارز","blockchain":"توسعه بلاکچین"}.get(kind,"—")
	details.add_child(label(kind_name + " • " + size_name,32,GREEN))
	details.add_child(label("فعال" if c.get("status","active") == "active" else str(c.get("status")),28,Color("087F69")))
	row.add_child(picture("res://assets/profile_holding/holding_logo_%02d.png" % clampi(int(c.get("logo",1)),1,5),Vector2(125,125)))
	var extra := VBoxContainer.new()
	extra.hide()
	var toggle := action("‹",func(): extra.visible = not extra.visible,false,Vector2(75,80))
	row.add_child(toggle)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			extra.visible = not extra.visible)
	p.add_child(extra)
	extra.add_child(label("هزینه تأسیس: " + money(int(c.get("establishment_cost_usdt",0))),32,GREEN))
	extra.add_child(label("واحدهای راه‌اندازی‌شده: %d از ۹" % (c.get("units",[]) as Array).size(),32,GREEN))
	extra.add_child(action("مدیریت شرکت",func(): notice("داشبورد اختصاصی شرکت در صحنه ششم ساخته خواهد شد."),true))

func notice(value: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.dialog_text = value
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(800,320))
