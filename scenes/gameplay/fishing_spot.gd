extends Control

# Fishing Gameplay Controller (Fisch-style Reeling & Alert)
# Micro Jam 065 - Everything is Bait!

enum FishingState {
	IDLE,
	CASTING,
	WAITING,
	BITING,
	REELING,
	RESULT,
	ESCAPED
}

var current_state: FishingState = FishingState.IDLE
var pending_fish: Dictionary = {}

# Node references
@onready var water_surface: Control = $WaterArea
@onready var bobber: Control = $Bobber
@onready var bobber_icon: Label = $Bobber/BobberIcon
@onready var alert_icon: Label = $Bobber/AlertIcon
@onready var ripple_ring: Panel = $Bobber/RippleRing
@onready var lbl_prompt: Label = $HUD/LblPrompt

@onready var reeling_hud: Control = $HUD/ReelingHUD
@onready var catch_dialog: Control = $HUD/CatchDialog
@onready var tackle_dialog: Control = $HUD/TackleBoxDialog

@onready var btn_back: Button = $HUD/TopBar/BtnBack
@onready var btn_tackle: Button = $HUD/TopBar/BtnTackle
@onready var lbl_bait_info: Label = $HUD/TopBar/BaitCard/LblBaitInfo

var _bobber_origin_y: float = 0.0
var _anim_time: float = 0.0

func _ready() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_tackle.pressed.connect(_on_tackle_pressed)
	water_surface.gui_input.connect(_on_water_clicked)
	
	reeling_hud.reeling_finished.connect(_on_reeling_finished)
	catch_dialog.dialog_closed.connect(_on_catch_dialog_closed)
	
	if GameManager:
		GameManager.bait_changed.connect(func(_b): _update_bait_display())
		GameManager.inventory_updated.connect(_update_bait_display)
		
	alert_icon.visible = false
	ripple_ring.visible = false
	bobber.visible = false
	reeling_hud.visible = false
	catch_dialog.visible = false
	tackle_dialog.visible = false
	
	_update_bait_display()
	_set_state(FishingState.IDLE)

func _process(delta: float) -> void:
	_anim_time += delta
	
	# Gentle floating animation on bobber in water
	if bobber.visible and current_state == FishingState.WAITING:
		bobber.position.y = _bobber_origin_y + sin(_anim_time * 4.0) * 4.0
		
	if current_state == FishingState.BITING:
		# Exclamation mark jumping pulse
		alert_icon.position.y = -55.0 + sin(_anim_time * 18.0) * 6.0

func _set_state(new_state: FishingState) -> void:
	current_state = new_state
	
	match current_state:
		FishingState.IDLE:
			var has_bait = not GameManager.equipped_bait.is_empty() and GameManager.inventory.get(GameManager.equipped_bait, 0) > 0
			if not has_bait:
				lbl_prompt.text = "💭 \"I should get bait for fish...\""
				lbl_prompt.modulate = Color(1.0, 0.9, 0.65, 0.95)
			else:
				lbl_prompt.text = "Click water to cast line"
				lbl_prompt.modulate = Color(1, 0.95, 0.85, 0.8)
			alert_icon.visible = false
			ripple_ring.visible = false
			bobber.visible = false
		FishingState.CASTING:
			lbl_prompt.text = ""
			alert_icon.visible = false
		FishingState.WAITING:
			lbl_prompt.text = ""
			ripple_ring.visible = true
			alert_icon.visible = false
		FishingState.BITING:
			lbl_prompt.text = ""
		FishingState.REELING:
			lbl_prompt.text = ""
			alert_icon.visible = false
		FishingState.ESCAPED:
			alert_icon.visible = false
			bobber.visible = false

func _on_water_clicked(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
		
	match current_state:
		FishingState.IDLE:
			_cast_line(event.position)
		FishingState.BITING:
			_hook_fish()

func _cast_line(target_pos: Vector2) -> void:
	_set_state(FishingState.CASTING)
	
	# Clamp click within water bounds
	var clamped_x = clamp(target_pos.x, 320.0, 1100.0)
	var clamped_y = clamp(target_pos.y, 420.0, 640.0)
	var final_pos = Vector2(clamped_x, clamped_y)
	
	bobber.position = Vector2(final_pos.x, final_pos.y - 120.0)
	_bobber_origin_y = final_pos.y
	bobber.visible = true
	bobber.modulate.a = 0.0
	
	# Splash arc tween
	var tween = create_tween().set_parallel()
	tween.tween_property(bobber, "position:y", final_pos.y, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(bobber, "modulate:a", 1.0, 0.2)
	
	await tween.finished
	_spawn_water_ripple()
	_set_state(FishingState.WAITING)
	
	# Random wait time until bite
	var wait_duration = randf_range(1.8, 3.8)
	get_tree().create_timer(wait_duration).timeout.connect(func():
		if current_state == FishingState.WAITING:
			_trigger_bite()
	)

func _spawn_water_ripple() -> void:
	ripple_ring.visible = true
	ripple_ring.scale = Vector2(0.2, 0.2)
	ripple_ring.modulate.a = 0.9
	var r_tween = create_tween().set_parallel()
	r_tween.tween_property(ripple_ring, "scale", Vector2(1.6, 0.8), 0.6)
	r_tween.tween_property(ripple_ring, "modulate:a", 0.0, 0.6)

func _trigger_bite() -> void:
	# Roll fish based on equipped bait (or bare hook if none)
	pending_fish = GameManager.roll_fish_bite(GameManager.equipped_bait)
	var tier = pending_fish.get("tier", 1)
	var tier_color = GameManager.TIER_COLORS.get(tier, Color.WHITE)
	
	# Consume 1 bait only if bait is currently equipped
	if not GameManager.equipped_bait.is_empty() and GameManager.inventory.get(GameManager.equipped_bait, 0) > 0:
		GameManager.consume_equipped_bait()
	_update_bait_display()
	
	# Configure exclamation mark '!'
	alert_icon.modulate = tier_color
	alert_icon.visible = true
	alert_icon.scale = Vector2(0.2, 0.2)
	
	var alert_tween = create_tween()
	alert_tween.tween_property(alert_icon, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	alert_tween.tween_property(alert_icon, "scale", Vector2.ONE, 0.1)
	
	# Ripple water violently
	_spawn_water_ripple()
	
	_set_state(FishingState.BITING)
	
	# Auto-hook: Instantly enters reeling minigame without requiring an extra tap!
	get_tree().create_timer(0.4).timeout.connect(func():
		if current_state == FishingState.BITING:
			_hook_fish()
	)

func _hook_fish() -> void:
	if current_state != FishingState.BITING:
		return
	_set_state(FishingState.REELING)
	alert_icon.visible = false
	reeling_hud.start_reeling(pending_fish)

func _fish_escaped(reason: String) -> void:
	_set_state(FishingState.ESCAPED)
	lbl_prompt.text = reason
	lbl_prompt.modulate = Color(1, 0.4, 0.35)
	
	var tween = create_tween()
	tween.tween_property(bobber, "modulate:a", 0.0, 0.4)
	await tween.finished
	bobber.visible = false
	
	get_tree().create_timer(1.2).timeout.connect(func():
		_set_state(FishingState.IDLE)
	)

func _on_reeling_finished(success: bool, fish_data: Dictionary) -> void:
	if success:
		_set_state(FishingState.RESULT)
		bobber.visible = false
		catch_dialog.show_catch(fish_data)
	else:
		_fish_escaped("The line snapped! The fish tore away.")

func _on_catch_dialog_closed(_action: String, _fish_data: Dictionary) -> void:
	_update_bait_display()
	_set_state(FishingState.IDLE)

func _update_bait_display() -> void:
	if not GameManager or not lbl_bait_info:
		return
	var bait_data = GameManager.get_equipped_bait_data()
	var qty = GameManager.inventory.get(GameManager.equipped_bait, 0)
	var has_bait = not bait_data.is_empty() and qty > 0
	if not has_bait:
		lbl_bait_info.text = "🪝 Bare Hook (No Bait)"
	else:
		lbl_bait_info.text = "%s %s (x%d)" % [bait_data.get("icon_symbol", "🎣"), bait_data.get("name", ""), qty]
		
	if current_state == FishingState.IDLE:
		if not has_bait:
			lbl_prompt.text = "💭 \"I should get bait for fish...\""
			lbl_prompt.modulate = Color(1.0, 0.9, 0.65, 0.95)
		else:
			lbl_prompt.text = "Click water to cast line"
			lbl_prompt.modulate = Color(1, 0.95, 0.85, 0.8)

func _on_tackle_pressed() -> void:
	tackle_dialog.open()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/lobby/lobby.tscn")
