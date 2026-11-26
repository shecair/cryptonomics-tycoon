extends RefCounted
## Opt-in cosmetic animations. Never modifies economy or save data.
const DURATIONS = {"button": 0.12, "selection": 0.20, "tab": 0.18, "production": 0.35, "coin": 0.60, "upgrade": 0.70, "worker": 0.50, "company": 1.20, "airdrop": 1.50, "warning": 0.30, "scene": 0.25}
static var reduced_motion: bool = false

static func begin(control: Control) -> Tween:
	var previous = control.get_meta("_game_ui_tween", null)
	if previous is Tween and previous.is_valid():
		previous.kill()
	if not control.has_meta("_game_ui_base_scale"):
		control.set_meta("_game_ui_base_scale", control.scale)
		control.set_meta("_game_ui_base_color", control.modulate)
	control.scale = control.get_meta("_game_ui_base_scale")
	control.modulate = control.get_meta("_game_ui_base_color")
	control.pivot_offset = control.size * 0.5
	var tween := control.create_tween()
	control.set_meta("_game_ui_tween", tween)
	return tween

static func pulse(control: Control, duration: float, factor: float = 1.08) -> Tween:
	var tween := begin(control)
	var base: Vector2 = control.scale
	if reduced_motion:
		tween.tween_interval(0.01)
		return tween
	tween.tween_property(control, "scale", base * factor, duration * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", base, duration * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tween

static func reveal(control: Control, duration: float) -> Tween:
	var tween := begin(control)
	var base: Color = control.modulate
	if reduced_motion:
		tween.tween_interval(0.01)
		return tween
	control.modulate.a = 0.0
	tween.tween_property(control, "modulate", base, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tween

static func play(control: Control, event: String) -> Tween:
	var duration: float = DURATIONS.get(event, 0.2)
	match event:
		"button":
			return pulse(control, duration, 0.95)
		"selection":
			return pulse(control, duration, 1.04)
		"tab", "scene":
			return reveal(control, duration)
		"production":
			return pulse(control, duration, 1.10)
		"coin":
			return pulse(control, duration, 1.16)
		"upgrade":
			return pulse(control, duration, 1.12)
		"worker":
			return reveal(control, duration)
		"company", "airdrop":
			return pulse(control, duration, 1.10)
		"warning":
			return pulse(control, duration, 1.04)
		_:
			return pulse(control, duration)

static func bind_button(button: BaseButton) -> void:
	if button.has_meta("_game_ui_motion_bound"):
		return
	button.set_meta("_game_ui_motion_bound", true)
	button.button_down.connect(func(): play(button, "button"))

## Use a transient overlay label, not a container-managed persistent label.
static func floating_reward(label: Label, duration: float = 0.6) -> Tween:
	var tween := label.create_tween()
	if reduced_motion:
		tween.tween_interval(duration)
	else:
		tween.set_parallel(true)
		tween.tween_property(label, "position", label.position + Vector2(0, -80), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(label, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(label.queue_free)
	return tween
