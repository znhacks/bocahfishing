extends Control

# Catch Dialog
# Shows caught fish and gives the option to [Keep] or immediately [Hook as Bait!]
signal dialog_closed(action: String, fish_data: Dictionary)

@onready var lbl_header: Label = $PanelContainer/Margin/VBox/LblHeader
@onready var lbl_icon: Label = $PanelContainer/Margin/VBox/CenterIcon/LblIcon
@onready var lbl_name: Label = $PanelContainer/Margin/VBox/LblName
@onready var lbl_rarity: Label = $PanelContainer/Margin/VBox/LblRarity
@onready var lbl_weight: Label = $PanelContainer/Margin/VBox/LblWeight
@onready var lbl_desc: Label = $PanelContainer/Margin/VBox/LblDesc
@onready var btn_keep: Button = $PanelContainer/Margin/VBox/BtnBox/BtnKeep
@onready var btn_hook: Button = $PanelContainer/Margin/VBox/BtnBox/BtnHook

var current_fish: Dictionary = {}

func _ready() -> void:
	btn_keep.pressed.connect(_on_keep_pressed)
	btn_hook.pressed.connect(_on_hook_pressed)

func show_catch(fish_data: Dictionary) -> void:
	current_fish = fish_data
	var is_fish = (fish_data.get("category", "fish") == "fish")
	var tier = fish_data.get("tier", 1)
	var tier_name = GameManager.TIER_NAMES.get(tier, "Common")
	var tier_color = GameManager.TIER_COLORS.get(tier, Color.WHITE)
	
	if is_fish:
		lbl_header.text = "✨ FISH CAUGHT! ✨"
		var size_range = fish_data.get("size_range", [10.0, 20.0])
		var weight = randf_range(size_range[0], size_range[1])
		lbl_weight.text = "Weight: %.1f kg" % weight
	else:
		lbl_header.text = "📦 LAKE DEBRIS HOOKED! 📦"
		lbl_weight.text = "Lake Junk • Can be used as Bait!"
	
	lbl_icon.text = fish_data.get("icon_symbol", "🐟")
	lbl_name.text = fish_data.get("name", "Fish")
	lbl_name.modulate = tier_color
	
	lbl_rarity.text = "[ %s ]" % tier_name.to_upper()
	lbl_rarity.modulate = tier_color
	
	lbl_desc.text = fish_data.get("desc", "")
	
	visible = true
	modulate.a = 0.0
	scale = Vector2(0.85, 0.85)
	var tween = create_tween().set_parallel()
	tween.tween_property(self, "modulate:a", 1.0, 0.18)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Icon bounce
	var icon_tween = create_tween()
	lbl_icon.scale = Vector2(1.4, 1.4)
	icon_tween.tween_property(lbl_icon, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _close(action: String) -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	await tween.finished
	visible = false
	dialog_closed.emit(action, current_fish)

func _on_keep_pressed() -> void:
	var fish_id = current_fish.get("id", "")
	if not fish_id.is_empty():
		GameManager.add_to_inventory(fish_id, 1)
	_close("keep")

func _on_hook_pressed() -> void:
	var fish_id = current_fish.get("id", "")
	if not fish_id.is_empty():
		GameManager.add_to_inventory(fish_id, 1)
		GameManager.set_equipped_bait(fish_id)
	_close("hook_as_bait")
