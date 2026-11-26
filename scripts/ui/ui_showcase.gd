extends Control
const UI = preload("res://scripts/ui/game_ui.gd")
const Motion = preload("res://scripts/ui/ui_animations.gd")
var tab_buttons: Array[Button] = []
var body: VBoxContainer
var scroll: ScrollContainer
var status: Label

func _ready() -> void:
	theme = UI.THEME
	var bg := ColorRect.new()
	bg.color = Color("#092E26")
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 36)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 20)
	margin.add_child(root)
	var heading := Label.new()
	heading.text = "UI Showcase • V1.0"
	UI.apply_text(heading, "english")
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(heading)
	var tabs := HBoxContainer.new()
	root.add_child(tabs)
	var group := ButtonGroup.new()
	var names := ["پنل‌ها", "دکمه‌ها", "آیکن‌ها", "فونت‌ها", "حرکت"]
	for i in range(names.size()):
		var b := Button.new()
		b.text = names[i]
		b.toggle_mode = true
		b.button_group = group
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(b)
		UI.apply_button(b, "management")
		tab_buttons.append(b)
		b.add_theme_font_size_override("font_size", 30)
		b.pressed.connect(show_page.bind(i))
		if i == 0:
			b.set_pressed_no_signal(true)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	scroll.add_child(body)
	status = Label.new()
	status.text = "محیط آزمایشی؛ بدون تغییر اطلاعات بازی"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.apply_text(status, "hint")
	root.add_child(status)
	show_page(0)

func title_line(parent: Node, value: String, kind: String = "body") -> Label:
	var l := Label.new()
	l.text = value
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.apply_text(l, kind)
	parent.add_child(l)
	return l

func show_page(index: int) -> void:
	for i in range(tab_buttons.size()):
		UI.apply_button(tab_buttons[i], "upgrade" if i == index else "management")
		if i == index:
			var gold := UI.texture_style("res://assets/ui/buttons/upgrade/normal.svg", 40, 32)
			tab_buttons[i].add_theme_stylebox_override("pressed", gold)
			tab_buttons[i].add_theme_stylebox_override("hover_pressed", gold)
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	scroll.set_deferred("scroll_vertical", 0)
	match index:
		0:
			for kind in UI.PANELS:
				var p := PanelContainer.new()
				p.custom_minimum_size.y = 160
				body.add_child(p)
				UI.apply_panel(p, kind)
				var l := title_line(p, kind, "english")
				l.add_theme_font_override("font", UI.bold_persian())
				if kind == "selection":
					l.add_theme_color_override("font_color", Color("#FFFFFF"))
					l.add_theme_color_override("font_outline_color", Color("#092E26"))
					l.add_theme_constant_override("outline_size", 6)
				if kind == "finance":
					l.add_theme_color_override("font_color", Color("#092E26"))
		1:
			for family in UI.FAMILIES:
				title_line(body, family, "english")
				var row := HBoxContainer.new()
				body.add_child(row)
				for state in ["normal", "selected", "disabled"]:
					var b := Button.new()
					b.text = state
					b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					row.add_child(b)
					UI.set_selected(b, family, state == "selected")
					b.disabled = state == "disabled"
					b.add_theme_font_size_override("font_size", 26)
					Motion.bind_button(b)
					b.pressed.connect(func(): status.text = "Button: " + family + " / " + state)
		2:
			var grid := GridContainer.new()
			grid.columns = 3
			grid.add_theme_constant_override("h_separation", 16)
			grid.add_theme_constant_override("v_separation", 16)
			body.add_child(grid)
			for path in ["finance/treasury", "finance/profit", "finance/loss", "finance/wallet", "finance/reserve", "energy/power", "management/company", "management/worker", "management/manager", "equipment/upgrade", "navigation/home", "navigation/profile", "status/warning", "status/success", "achievements/trophy"]:
				var cell := VBoxContainer.new()
				cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				grid.add_child(cell)
				var pic := TextureRect.new()
				var icon_path := "res://assets/ui/icons/" + path + ".png"
				if not ResourceLoader.exists(icon_path):
					icon_path = "res://assets/ui/icons/" + path + ".svg"
				pic.texture = load(icon_path) as Texture2D
				pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				pic.custom_minimum_size = Vector2(160, 160)
				cell.add_child(pic)
				title_line(cell, path.get_file(), "hint")
		3:
			title_line(body, "مدیریت کسب‌وکار رمزارزی", "title")
			title_line(body, "سرمایه اولیه و درآمد شرکت")
			title_line(body, "Cryptonomics Tycoon", "english")
			title_line(body, "10,000.00 USDT", "money")
			title_line(body, "متن فارسی و English — ۱۲۳۴۵", "hint")
		4:
			var reduced := CheckButton.new()
			reduced.text = "کاهش حرکات گرافیکی"
			reduced.button_pressed = Motion.reduced_motion
			reduced.toggled.connect(func(value: bool): Motion.reduced_motion = value)
			body.add_child(reduced)
			var target := title_line(body, "10,000 USDT", "money")
			target.custom_minimum_size.y = 150
			for event in Motion.DURATIONS:
				var b := Button.new()
				b.text = "%s — %d ms" % [event, int(Motion.DURATIONS[event] * 1000)]
				body.add_child(b)
				UI.apply_button(b, "management")
				b.pressed.connect(func(): Motion.play(target, event))
