extends Control
const Capacity = preload("res://scripts/company_capacity.gd")
const SAVE = "user://savegame.json"
const GREEN = Color("075440")
const GOLD = Color("FFE4A0")
const CREAM = Color("FFF5D9")
var data: Dictionary = {}
var companies: Array = []
var body: VBoxContainer
var nav: HBoxContainer
var groups: VBoxContainer
var tab := 0
var company_scroll: ScrollContainer
const BUSINESS_KEYS = ["mining","exchange","blockchain"]
const BUSINESS_NAMES = ["استخراج","صرافی","بلاکچین"]

func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE)) if FileAccess.file_exists(SAVE) else null
	if parsed is Dictionary and parsed.get("companies") is Array and typeof(parsed.get("balance_usdt")) in [TYPE_INT, TYPE_FLOAT]:
		data = parsed
		companies = data["companies"]
	var root := $Margin/Root
	root.get_node("Header/Stack/Top/Help").pressed.connect(func(): notice("شرکت‌های خود را مدیریت کنید یا با سرمایه خزانه شرکت جدید بسازید."))
	root.get_node("Header/Stack/Top/Menu").pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	var identity := root.get_node("Header/Stack/Identity/Content")
	identity.get_node("Row/HoldingLogo").texture = load("res://assets/profile_holding/holding_logo_%02d.png" % clampi(int(data.get("holding_logo",1)),1,5))
	identity.get_node("Row/Avatar").texture = load("res://assets/profile_holding/avatar_%02d.png" % clampi(int(data.get("avatar",1)),1,6))
	identity.get_node("Row/HoldingInfo/HoldingName").text = str(data.get("holding_name","—"))
	identity.get_node("Row/Person/PlayerName").text = str(data.get("player_name","—"))
	identity.get_node("Cash/Amount").text = money(int(data.get("balance_usdt",0))) if not data.is_empty() else "—"
	var active := 0
	var profit := 0
	for c in companies:
		if c is Dictionary:
			if c.get("status","active") == "active":
				active += 1
			profit += int(c.get("profit_usdt",0))
	root.get_node("Header/Stack/Metrics/Active/Content/Value").text = "%d/9" % Capacity.count(companies)
	root.get_node("Header/Stack/Metrics/Profit/Content/Value").text = money(profit)
	groups = root.get_node("CompanyGroups")
	for i in range(3):
		var group := groups.get_child(i)
		for j in range(3):
			var slot := group.get_node("Content/Slots").get_child(j) as Button
			slot.pressed.connect(open_slot.bind(i,j))
	company_scroll = root.get_node("Scroll")
	body = root.get_node("Scroll/Body")
	nav = root.get_node("Nav")
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
	s.shadow_color = Color(0.08,0.20,0.12,0.16)
	s.shadow_size = 5
	s.shadow_offset = Vector2(0,4)
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
	b.add_theme_font_size_override("font_size",38 if gold else 34)
	b.add_theme_color_override("font_disabled_color",Color("455B45"))
	for state in ["normal","hover","pressed","disabled"]:
		b.add_theme_stylebox_override(state,style(Color("DDAA38") if gold else GREEN))
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		b.add_theme_color_override(state,GREEN if gold else Color.WHITE)
	if gold:
		b.add_theme_stylebox_override("disabled",style(Color("E5D5A5")))
	b.pressed.connect(callback)
	return b

func render() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	for child in nav.get_children():
		nav.remove_child(child)
		child.queue_free()
	groups.visible = tab == 0 and not data.is_empty()
	company_scroll.visible = not groups.visible
	if groups.visible:
		refresh_slots()
	for i in [2,1,0]:
		var b := action(["▥\nهلدینگ","▤\nمالی","♙\nپروفایل"][i],select_tab.bind(i),tab==i)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav.add_child(b)
	if data.is_empty():
		body.add_child(label("فایل ذخیره معتبر نیست. به منوی اصلی بازگردید.",36,GREEN))
		return
	if tab == 0:
		return
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

func group_companies(index: int) -> Array:
	var result: Array = []
	for c in companies:
		if Capacity.occupies_slot(c) and c.get("business","") == BUSINESS_KEYS[index]:
			result.append(c)
	return result

func refresh_slots() -> void:
	for i in range(3):
		var entries := group_companies(i)
		var group := groups.get_child(i)
		group.get_node("Content/Heading").text = ["استخراج رمزارز","صرافی رمزارز","توسعه بلاکچین"][i] + "  |  %d/3" % entries.size()
		for j in range(3):
			var slot := group.get_node("Content/Slots").get_child(j) as Button
			var occupied := j < entries.size()
			var content := slot.get_node("Content")
			content.get_node("Plus").visible = not occupied
			content.get_node("Icon").visible = occupied
			var ink := GREEN if occupied else Color("FFE4A0")
			for n in ["Name","Status","Plus"]:
				content.get_node(n).add_theme_color_override("font_color",ink)
			for state in ["normal","hover","pressed"]:
				var skin := style(CREAM if occupied else Color("176B53"))
				skin.border_color = Color("E9AD32")
				slot.add_theme_stylebox_override(state,skin)
			if occupied:
				var c: Dictionary = entries[j]
				content.get_node("Icon").texture = load("res://assets/profile_holding/holding_logo_%02d.png" % clampi(int(c.get("logo",1)),1,5))
				content.get_node("Name").text = str(c.get("name","—"))
				content.get_node("Status").text = "فعال" if c.get("status","active") == "active" else str(c.get("status"))
			else:
				content.get_node("Name").text = "تأسیس شرکت"
				content.get_node("Status").text = "جایگاه آزاد" if int(data.get("balance_usdt",0)) >= 1000 else "سرمایه ناکافی"

func open_slot(index: int, slot: int) -> void:
	var entries := group_companies(index)
	if slot < entries.size():
		notice("داشبورد اختصاصی شرکت در صحنه ششم ساخته خواهد شد.")
	elif int(data.get("balance_usdt",0)) < 1000:
		notice("موجودی ناکافی؛ حداقل سرمایه لازم ۱٬۰۰۰ USDT")
	elif Capacity.can_create(companies,BUSINESS_KEYS[index]):
		get_tree().change_scene_to_file("res://scenes/establish_company.tscn")
	else:
		notice("ظرفیت تأسیس شرکت تکمیل شده است.")

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

class MetricIcon extends Control:
	var kind := "building"
	func _draw() -> void:
		var ink := Color("075440")
		draw_circle(Vector2(38,38),36,Color("E7D8A4") if kind == "building" else Color("D9EBD9"))
		if kind == "building":
			draw_rect(Rect2(19,20,23,38),ink,false,4)
			draw_rect(Rect2(42,34,15,24),ink,false,4)
			for y in [28,39,50]:
				draw_line(Vector2(26,y),Vector2(35,y),ink,3,true)
			draw_line(Vector2(15,59),Vector2(62,59),ink,4,true)
		else:
			draw_line(Vector2(18,57),Vector2(18,20),ink,3,true)
			draw_line(Vector2(18,57),Vector2(60,57),ink,3,true)
			draw_polyline(PackedVector2Array([Vector2(23,48),Vector2(35,36),Vector2(44,42),Vector2(59,23)]),ink,4,true)
			draw_polyline(PackedVector2Array([Vector2(47,23),Vector2(59,23),Vector2(59,35)]),ink,4,true)
