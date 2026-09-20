extends Control

# Stats Dialog Controller
# Displays current total angler stats, modifiers, bait bonuses, and career stats

signal closed()

@onready var btn_close: Button = $PanelContainer/MarginContainer/VBoxContainer/HeaderBox/BtnClose
@onready var lbl_char_name: Label = $PanelContainer/MarginContainer/VBoxContainer/ContentBox/AnglerCard/HBox/VBox/LblCharName
@onready var lbl_char_title: Label = $PanelContainer/MarginContainer/VBoxContainer/ContentBox/AnglerCard/HBox/VBox/LblCharTitle
@onready var char_icon: TextureRect = $PanelContainer/MarginContainer/VBoxContainer/ContentBox/AnglerCard/HBox/CharIcon
@onready var char_icon_fallback: Label = $PanelContainer/MarginContainer/VBoxContainer/ContentBox/AnglerCard/HBox/CharIconFallback

# Stat rows
@onready var lbl_safe_bar: Label = $PanelContainer/MarginContainer/VBoxContainer/ContentBox/StatsGrid/RowBar/VBox/Header/LblValue
@onready var lbl_safe_bar_desc: Label = $PanelContainer/MarginContainer/VBoxContainer/ContentBox/StatsGrid/RowBar/VBox/LblDesc

@onready var lbl_lure: Label = $PanelContainer/MarginContainer/VBoxContainer/ContentBox/StatsGrid/RowLure/VBox/Header/LblValue
@onready var lbl_lure_desc: Label = $PanelContainer/MarginContainer/VBoxContainer/ContentBox/StatsGrid/RowLure/VBox/LblDesc

@onready var lbl_resilience: Label = $PanelContainer/MarginContainer/VBoxContainer/ContentBox/StatsGrid/RowResilience/VBox/Header/LblValue
@onready var lbl_resilience_desc: Label = $PanelContainer/MarginContainer/VBoxContainer/ContentBox/StatsGrid/RowResilience/VBox/LblDesc

@onready var lbl_bait_status: Label = $PanelContainer/MarginContainer/VBoxContainer/ContentBox/StatsGrid/RowBait/VBox/Header/LblValue
@onready var lbl_bait_desc: Label = $PanelContainer/MarginContainer/VBoxContainer/ContentBox/StatsGrid/RowBait/VBox/LblDesc

# Career
@onready var lbl_career_almanac: Label = $PanelContainer/MarginContainer/VBoxContainer/CareerBox/HBox/LblAlmanac
@onready var lbl_career_cahs: Label = $PanelContainer/MarginContainer/VBoxContainer/CareerBox/HBox/LblCahs

func _ready() -> void:
	btn_close.pressed.connect(close)
	if GameManager:
		GameManager.character_changed.connect(func(_c): refresh())
		GameManager.bait_changed.connect(func(_b): refresh())
		GameManager.cahs_changed.connect(func(_c): refresh())
		GameManager.fish_unlocked.connect(func(_f): refresh())

func open() -> void:
	refresh()
	visible = true
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.16)

func close() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.14)
	await tween.finished
	visible = false
	closed.emit()

func refresh() -> void:
	if not GameManager:
		return
		
	var char_id = GameManager.selected_character
	var char_data = GameManager.character_db.get(char_id, GameManager.character_db["none"])
	var mods = GameManager.get_character_modifiers()
	
	# 1. Angler Header
	lbl_char_name.text = char_data.get("name", "None")
	var title_text = char_data.get("desc", "Standard Angler")
	lbl_char_title.text = title_text
	
	var portrait_path: String = char_data.get("portrait", "")
	if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
		char_icon.texture = load(portrait_path)
		char_icon.visible = true
		char_icon_fallback.visible = false
	else:
		char_icon.texture = load("res://assets/textures/icons/icon_wardrobe.svg")
		char_icon.visible = true
		char_icon_fallback.visible = false
		
	# 2. Stats Rows
	# Bar Scale
	var bar_scale: float = mods.get("bar_scale", 1.0)
	var bar_pct: int = int(round(bar_scale * 100))
	if bar_scale > 1.0:
		lbl_safe_bar.text = "%d%% (+%d%% Safe Zone)" % [bar_pct, bar_pct - 100]
		lbl_safe_bar.modulate = Color(0.35, 0.95, 0.55)
		lbl_safe_bar_desc.text = "Expanded catch zone makes reeling significantly easier and forgiving."
	elif bar_scale < 1.0:
		lbl_safe_bar.text = "%d%% (%d%% Precision Zone)" % [bar_pct, bar_pct - 100]
		lbl_safe_bar.modulate = Color(1.0, 0.65, 0.4)
		lbl_safe_bar_desc.text = "Narrower catch bar requires sharper tracking and steady focus."
	else:
		lbl_safe_bar.text = "100% (Standard 140px)"
		lbl_safe_bar.modulate = Color(0.85, 0.9, 1.0)
		lbl_safe_bar_desc.text = "Standard catch bar width with balanced difficulty."
		
	# Lure Speed
	var lure_speed: float = mods.get("lure_speed", 1.0)
	var lure_pct: int = int(round((lure_speed - 1.0) * 100))
	if lure_speed > 1.0:
		lbl_lure.text = "+%d%% Rapid Lure Speed" % lure_pct
		lbl_lure.modulate = Color(0.35, 0.95, 0.55)
		lbl_lure_desc.text = "Fish spot the bait much faster (Bite wait: ~3.2s vs ~8.0s bare hook)."
	else:
		lbl_lure.text = "0% (Standard Lure Speed)"
		lbl_lure.modulate = Color(0.85, 0.9, 1.0)
		lbl_lure_desc.text = "Standard bite rate (~4.4s with bait, ~8.0s without bait)."
		
	# Resilience
	var resilience: float = mods.get("resilience", 1.0)
	var res_pct: int = int(round((resilience - 1.0) * 100))
	if resilience > 1.0:
		lbl_resilience.text = "+%d%% Line Resilience (🛡️ Resilient Grip)" % res_pct
		lbl_resilience.modulate = Color(0.35, 0.95, 0.55)
		lbl_resilience_desc.text = "Tough line tension (-13%/s escape drain) and dampens violent thrashing."
	elif resilience < 1.0:
		lbl_resilience.text = "%d%% Line Resilience (⚠️ Fragile Line)" % res_pct
		lbl_resilience.modulate = Color(1.0, 0.4, 0.4)
		lbl_resilience_desc.text = "Delicate line tension (-30%/s escape drain if fish slips outside)."
	else:
		lbl_resilience.text = "100% (Standard Line Tension)"
		lbl_resilience.modulate = Color(0.85, 0.9, 1.0)
		lbl_resilience_desc.text = "Standard tension loss (-22%/s escape drain outside catch bar)."
		
	# Equipped Bait
	var bait_data = GameManager.get_equipped_bait_data()
	var qty = GameManager.inventory.get(GameManager.equipped_bait, 0)
	if bait_data.is_empty() or qty <= 0:
		lbl_bait_status.text = "Bare Hook (No Bait)"
		lbl_bait_status.modulate = Color(0.9, 0.75, 0.4)
		lbl_bait_desc.text = "Slowest bite speed (6.5 - 9.5s) and 75% chance of snagging lake trash."
	else:
		var bait_name = bait_data.get("name", "Bait")
		var tier = bait_data.get("tier", 1)
		lbl_bait_status.text = "%s (x%d) • Tier %d" % [bait_name, qty, tier]
		lbl_bait_status.modulate = Color(0.4, 0.9, 1.0)
		
		var tags = bait_data.get("tags", [])
		if tags.is_empty() and bait_data.has("preferred_tags"):
			tags = bait_data.get("preferred_tags")
		var tag_str = ", ".join(tags).capitalize() if not tags.is_empty() else "Standard"
		lbl_bait_desc.text = "Traits: %s • Attracts Tier %d & %d fish (Fast %s bites)." % [
			tag_str,
			tier,
			mini(tier + 1, 5),
			"2.5s" if tier >= 3 else ("3.5s" if tier == 2 else "4.5s")
		]

	# 3. Career Stats
	var progress_dict = GameManager.get_almanac_progress()
	var caught = progress_dict.get("caught", 0)
	var total = progress_dict.get("total", 12)
	var pct = int((float(caught) / float(maxi(total, 1))) * 100.0)
	lbl_career_almanac.text = "Almanac: %d / %d (%d%%)" % [caught, total, pct]
	lbl_career_cahs.text = "Balance: %d Cahs" % GameManager.cahs
