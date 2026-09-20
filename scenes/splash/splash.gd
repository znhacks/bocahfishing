extends Control

# Splash Screen
# Shows logo + studio name with cinematic fade-in, hold, then fade-out to lobby.

@onready var logo_rect: TextureRect = $Center/VBox/LogoRect
@onready var lbl_studio: Label = $Center/VBox/LblStudio
@onready var fade_overlay: ColorRect = $FadeOverlay

const NEXT_SCENE := "res://scenes/lobby/lobby.tscn"

func _ready() -> void:
	# Start everything invisible; FadeOverlay covers the whole screen
	logo_rect.modulate.a = 0.0
	lbl_studio.modulate.a = 0.0
	fade_overlay.color.a = 1.0
	
	_run_sequence()

func _run_sequence() -> void:
	# ── Phase 1: Fade in background (fast)
	var t1 = create_tween()
	t1.tween_property(fade_overlay, "color:a", 0.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await t1.finished
	
	# ── Phase 2: Logo scales up + fades in
	logo_rect.scale = Vector2(0.88, 0.88)
	logo_rect.pivot_offset = logo_rect.size / 2.0
	var t2 = create_tween().set_parallel(true)
	t2.tween_property(logo_rect, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t2.tween_property(logo_rect, "scale", Vector2.ONE, 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t2.finished
	
	# ── Phase 3: Studio text fades in after a short pause
	await get_tree().create_timer(0.18).timeout
	var t3 = create_tween()
	t3.tween_property(lbl_studio, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE)
	await t3.finished
	
	# ── Phase 4: Hold splash
	await get_tree().create_timer(1.6).timeout
	
	# ── Phase 5: Fade out entire screen, then load lobby
	var t4 = create_tween()
	t4.tween_property(fade_overlay, "color:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await t4.finished
	
	get_tree().change_scene_to_file(NEXT_SCENE)

func _unhandled_input(event: InputEvent) -> void:
	# Allow skipping splash with any key/click after logo is visible
	if logo_rect.modulate.a >= 0.8:
		if event is InputEventKey or event is InputEventMouseButton:
			_skip_to_lobby()

func _skip_to_lobby() -> void:
	# Kill all tweens and jump straight to lobby with quick fade
	get_tree().call_deferred("change_scene_to_file", NEXT_SCENE)
