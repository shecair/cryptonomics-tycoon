extends RefCounted
## Shared UI factories. Opt-in only; does not modify existing scenes.
const THEME = preload("res://themes/game_theme.tres")
const PERSIAN = preload("res://assets/ui/fonts/Vazirmatn/Vazirmatn.ttf")
const ENGLISH = preload("res://assets/ui/fonts/Fredoka/Fredoka.ttf")
const MONEY = preload("res://assets/ui/fonts/RobotoMono/RobotoMono.ttf")
const PANELS = ["main", "finance", "stats", "operation", "selection", "warning"]
const FAMILIES = ["primary", "upgrade", "management", "information", "danger", "neutral"]

static func texture_style(path: String, horizontal: float, vertical: float) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(path) as Texture2D
	for side in [SIDE_LEFT, SIDE_RIGHT]:
		style.set_texture_margin(side, horizontal)
		style.set_content_margin(side, 28.0)
	for side in [SIDE_TOP, SIDE_BOTTOM]:
		style.set_texture_margin(side, vertical)
		style.set_content_margin(side, 24.0)
	return style

static func apply_panel(control: Control, kind: String = "main") -> void:
	if not PANELS.has(kind):
		kind = "main"
	control.add_theme_stylebox_override("panel", texture_style("res://assets/ui/panels/panel_%s.png" % kind, 48, 48))

static func bold_persian() -> FontVariation:
	var font := FontVariation.new()
	font.base_font = PERSIAN
	font.variation_opentype = {TextServer.name_to_tag("wght"): 700}
	return font

static func apply_button(button: Button, family: String = "management") -> void:
	if not FAMILIES.has(family):
		family = "management"
	button.theme = THEME
	button.add_theme_font_override("font", bold_persian())
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 100.0)
	var path := "res://assets/ui/buttons/%s/" % family
	for state in ["normal", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, texture_style(path + state + ".svg", 40, 32))
	button.add_theme_stylebox_override("hover", texture_style(path + "normal.svg", 40, 32))
	button.add_theme_stylebox_override("hover_pressed", texture_style(path + "pressed.svg", 40, 32))
	button.add_theme_stylebox_override("focus", texture_style(path + "selected.svg", 40, 32))
	var ink := Color("#354237") if family in ["upgrade", "neutral", "primary"] else Color.WHITE
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, ink)
	button.add_theme_color_override("font_disabled_color", Color("#354237"))

static func set_selected(button: Button, family: String, selected: bool) -> void:
	apply_button(button, family)
	if selected:
		if not FAMILIES.has(family):
			family = "management"
		var style := texture_style("res://assets/ui/buttons/%s/selected.svg" % family, 40, 32)
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)

static func apply_text(label: Label, kind: String = "body") -> void:
	label.add_theme_font_override("font", PERSIAN)
	match kind:
		"money":
			label.add_theme_font_override("font", MONEY)
			label.text_direction = Control.TEXT_DIRECTION_LTR
			label.add_theme_font_size_override("font_size", 56)
			label.add_theme_color_override("font_color", Color("#FFE46D"))
		"english":
			label.add_theme_font_override("font", ENGLISH)
			label.text_direction = Control.TEXT_DIRECTION_LTR
			label.add_theme_font_size_override("font_size", 44)
		"title":
			label.add_theme_font_size_override("font_size", 48)
		"hint":
			label.add_theme_font_size_override("font_size", 28)
		_:
			label.add_theme_font_size_override("font_size", 36)
