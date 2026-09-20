extends Node

# Autoload: GameManager
# Bocah Fishing - Everything is Bait!

signal bait_changed(new_bait_id: String)
signal inventory_updated()
signal fish_unlocked(fish_id: String)
signal cahs_changed(new_cahs: int)
signal character_changed(new_char_id: String)
signal time_updated(in_game_time: float)
signal period_changed(new_period: String)

# Day / Night Cycle
# 1 full in-game day (24 hours) = 6 minutes (360 real seconds).
# 1 in-game hour = 15 real seconds.
const CYCLE_DURATION_REAL_SECONDS: float = 360.0
const SECONDS_PER_DAY: float = 86400.0
const TIME_MULTIPLIER: float = SECONDS_PER_DAY / CYCLE_DURATION_REAL_SECONDS # 240.0x

const PERIOD_CONFIG: Dictionary = {
	"day": {
		"name": "Day",
		"icon": "☀️",
		"start_hour": 6.0,
		"end_hour": 18.0,
		"texture_path": "res://assets/textures/day.jpeg"
	},
	"night": {
		"name": "Night",
		"icon": "🌙",
		"start_hour": 18.0,
		"end_hour": 6.0,
		"texture_path": "res://assets/textures/night.jpeg"
	}
}

var in_game_time: float = 21600.0 # 06:00 (Day) default
var current_period: String = "day"
var _cached_period_textures: Dictionary = {}

# Tier Metadata & Colors
const TIER_COLORS = {
	1: Color(0.94, 0.94, 0.94),      # Tier 1: White / Silver (Common)
	2: Color(0.31, 0.98, 0.45),      # Tier 2: Neon Green (Uncommon)
	3: Color(0.22, 0.66, 1.0),       # Tier 3: Sapphire Blue (Rare)
	4: Color(0.75, 0.33, 1.0),       # Tier 4: Amethyst Purple (Epic)
	5: Color(1.0, 0.82, 0.15)        # Tier 5: Radiant Gold (Legendary)
}

const TIER_NAMES = {
	1: "Common",
	2: "Uncommon",
	3: "Rare",
	4: "Epic",
	5: "Legendary"
}

# Master Items Database (Baits & Fish)
var item_db: Dictionary = {
	# --- Starter & Common Baits ---
	"bait_worm": {
		"id": "bait_worm",
		"name": "Earthworm",
		"category": "bait",
		"tier": 1,
		"tags": ["organic", "wiggly"],
		"desc": "A classic fisherman's staple. Loved by nimble small lake fish.",
		"color": Color(0.85, 0.45, 0.45),
		"icon_symbol": "🪱"
	},
	"bait_bread": {
		"id": "bait_bread",
		"name": "Bread Crust",
		"category": "bait",
		"tier": 1,
		"tags": ["sweet", "carbs"],
		"desc": "Leftover breakfast crust. Sweet and fragrant in the water.",
		"color": Color(0.9, 0.75, 0.4),
		"icon_symbol": "🍞"
	},
	"bait_apple": {
		"id": "bait_apple",
		"name": "Red Apple",
		"category": "bait",
		"tier": 1,
		"tags": ["sweet", "fruit"],
		"desc": "Fresh sweet apple slice. Surprisingly attracts curious glistening fish.",
		"color": Color(0.95, 0.25, 0.25),
		"icon_symbol": "🍎"
	},
	"bait_sock": {
		"id": "bait_sock",
		"name": "Soggy Sock",
		"category": "bait",
		"tier": 2,
		"tags": ["junk", "stinky"],
		"desc": "Who knew stinky lost laundry could lure deep bottom-dwellers?",
		"color": Color(0.4, 0.5, 0.6),
		"icon_symbol": "🧦"
	},
	"bait_coin": {
		"id": "bait_coin",
		"name": "Shiny Old Coin",
		"category": "bait",
		"tier": 2,
		"tags": ["shiny", "metal"],
		"desc": "Flashes sunlight through murky waters. Irresistible to inquisitive fish.",
		"color": Color(1.0, 0.85, 0.2),
		"icon_symbol": "🪙"
	},
	"bait_battery": {
		"id": "bait_battery",
		"name": "Rusty Battery",
		"category": "bait",
		"tier": 2,
		"tags": ["electric", "bizarre"],
		"desc": "Emits faint micro-sparks underwater. Attracts shocking anomalies!",
		"color": Color(0.3, 0.8, 0.9),
		"icon_symbol": "🔋"
	},
	"bait_boot": {
		"id": "bait_boot",
		"name": "Old Rubber Boot",
		"category": "bait",
		"tier": 1,
		"tags": ["junk", "rubber"],
		"desc": "A heavy mossy boot dredged from the lake bed. Surprisingly good as heavy bait!",
		"color": Color(0.45, 0.4, 0.35),
		"icon_symbol": "🥾"
	},
	"bait_can": {
		"id": "bait_can",
		"name": "Rusted Tin Can",
		"category": "bait",
		"tier": 1,
		"tags": ["junk", "metal"],
		"desc": "An old crushed tin can. Bottom-dwellers like catfish are drawn to it.",
		"color": Color(0.6, 0.5, 0.4),
		"icon_symbol": "🥫"
	},
	"bait_seaweed": {
		"id": "bait_seaweed",
		"name": "Tangled Lake Weed",
		"category": "bait",
		"tier": 1,
		"tags": ["organic", "plant"],
		"desc": "A slimy clump of green weed pulled from the depths. Plant-eaters adore it.",
		"color": Color(0.3, 0.65, 0.35),
		"icon_symbol": "🌿"
	},

	# --- Tier 1 Fish (Common - White: 1-2 Cahs) ---
	"fish_pebble_guppy": {
		"id": "fish_pebble_guppy",
		"name": "Wild Guppy",
		"category": "fish",
		"tier": 1,
		"price_cahs": 1,
		"time_available": "all",
		"preferred_tags": ["organic", "wiggly"],
		"desc": "A nimble, colorful tropical freshwater swimmer found flitting around lake shallows.",
		"color": Color(0.7, 0.8, 0.85),
		"icon_symbol": "🐟",
		"icon_texture": "res://assets/textures/fish/fish_pebble_guppy.png",
		"size_range": [5.0, 12.0]
	},
	"fish_wader": {
		"id": "fish_wader",
		"name": "Common Minnow",
		"category": "fish",
		"tier": 1,
		"price_cahs": 1,
		"time_available": "day",
		"preferred_tags": ["organic", "carbs"],
		"desc": "An energetic, schooling daytime fish. Makes prime live bait for bigger lake predators!",
		"color": Color(0.6, 0.8, 0.7),
		"icon_symbol": "🐟",
		"icon_texture": "res://assets/textures/fish/fish_wader.png",
		"size_range": [8.0, 16.0]
	},
	"fish_sleepy_carp": {
		"id": "fish_sleepy_carp",
		"name": "Crucian Carp",
		"category": "fish",
		"tier": 1,
		"price_cahs": 2,
		"time_available": "all",
		"preferred_tags": ["sweet", "carbs"],
		"desc": "A hardy, golden-bronze freshwater carp that peacefully grazes on lake weeds day and night.",
		"color": Color(0.8, 0.7, 0.5),
		"icon_symbol": "🐠",
		"icon_texture": "res://assets/textures/fish/fish_sleepy_carp.png",
		"size_range": [18.0, 32.0]
	},

	# --- Tier 2 Fish (Uncommon - Green: 3-4 Cahs) ---
	"fish_mossy_perch": {
		"id": "fish_mossy_perch",
		"name": "Yellow Perch",
		"category": "fish",
		"tier": 2,
		"price_cahs": 3,
		"time_available": "day",
		"preferred_tags": ["organic", "fruit"],
		"desc": "A vibrant golden-yellow game fish with dark vertical bars. Keen visual hunter active in daylight.",
		"color": Color(0.85, 0.8, 0.25),
		"icon_symbol": "🐟",
		"icon_texture": "res://assets/textures/fish/fish_mossy_perch.png",
		"size_range": [22.0, 42.0]
	},
	"fish_lele": {
		"id": "fish_lele",
		"name": "Walking Catfish",
		"category": "fish",
		"tier": 2,
		"price_cahs": 3,
		"time_available": "night",
		"preferred_tags": ["stinky", "junk"],
		"desc": "A nocturnal bottom-dweller with sensory whiskers. Scours the muddy lake bed only under darkness.",
		"color": Color(0.4, 0.38, 0.3),
		"icon_symbol": "🐡",
		"icon_texture": "res://assets/textures/fish/fish_lele.png",
		"size_range": [30.0, 65.0]
	},
	"fish_mas": {
		"id": "fish_mas",
		"name": "Golden Carp",
		"category": "fish",
		"tier": 2,
		"price_cahs": 4,
		"time_available": "day",
		"preferred_tags": ["sweet", "fruit", "shiny"],
		"desc": "A magnificent orange-gold carp that basks in the warm afternoon sunlight.",
		"color": Color(1.0, 0.65, 0.1),
		"icon_symbol": "🐠",
		"icon_texture": "res://assets/textures/fish/fish_mas.png",
		"size_range": [25.0, 50.0]
	},

	# --- Tier 3 Fish (Rare - Blue: 5-6 Cahs) ---
	"fish_glimmer_trout": {
		"id": "fish_glimmer_trout",
		"name": "Rainbow Trout",
		"category": "fish",
		"tier": 3,
		"price_cahs": 5,
		"time_available": "day",
		"preferred_tags": ["shiny", "metal", "organic"],
		"desc": "A swift, prized coldwater predator displaying a radiant pink lateral stripe in clear sunny waters.",
		"color": Color(0.3, 0.7, 0.95),
		"icon_symbol": "🐟",
		"icon_texture": "res://assets/textures/fish/fish_glimmer_trout.png",
		"size_range": [38.0, 72.0]
	},
	"fish_gabus": {
		"id": "fish_gabus",
		"name": "Striped Snakehead",
		"category": "fish",
		"tier": 3,
		"price_cahs": 6,
		"time_available": "night",
		"preferred_tags": ["organic", "shiny"],
		"desc": "A fierce nocturnal ambush predator with specialized air-breathing lungs, stalking the shallows at night.",
		"color": Color(0.3, 0.55, 0.4),
		"icon_symbol": "🦈",
		"icon_texture": "res://assets/textures/fish/fish_gabus.png",
		"size_range": [45.0, 85.0]
	},

	# --- Tier 4 Fish (Epic - Purple: 7-8 Cahs) ---
	"fish_belut_listrik": {
		"id": "fish_belut_listrik",
		"name": "Electric Eel",
		"category": "fish",
		"tier": 4,
		"price_cahs": 7,
		"time_available": "night",
		"preferred_tags": ["electric", "bizarre"],
		"desc": "A legendary nocturnal knifefish that navigates and stuns prey in pitch-black waters with 860V electric shocks.",
		"color": Color(0.7, 0.3, 0.95),
		"icon_symbol": "⚡",
		"icon_texture": "res://assets/textures/fish/fish_belut_listrik.png",
		"size_range": [70.0, 130.0]
	},
	"fish_abyssal_snapper": {
		"id": "fish_abyssal_snapper",
		"name": "Alligator Gar",
		"category": "fish",
		"tier": 4,
		"price_cahs": 8,
		"time_available": "all",
		"preferred_tags": ["junk", "stinky", "shiny"],
		"desc": "A living fossil from the dinosaur era. Armored with diamond-hard ganoid scales and heavy crocodile-like jaws.",
		"color": Color(0.45, 0.5, 0.35),
		"icon_symbol": "🐊",
		"icon_texture": "res://assets/textures/fish/fish_abyssal_snapper.png",
		"size_range": [80.0, 180.0]
	},

	# --- Tier 5 Fish (Legendary - Gold: 10 Cahs) ---
	"fish_raksasa_kuno": {
		"id": "fish_raksasa_kuno",
		"name": "Beluga Sturgeon",
		"category": "fish",
		"tier": 5,
		"price_cahs": 10,
		"time_available": "day",
		"preferred_tags": ["shiny", "electric"],
		"desc": "The undisputed titan of freshwater fish. An ancient armored behemoth that can live over a century.",
		"color": Color(1.0, 0.85, 0.2),
		"icon_symbol": "🐋",
		"icon_texture": "res://assets/textures/fish/fish_raksasa_kuno.png",
		"size_range": [180.0, 380.0]
	},
	"fish_void_guardian": {
		"id": "fish_void_guardian",
		"name": "Giant Wels Catfish",
		"category": "fish",
		"tier": 5,
		"price_cahs": 10,
		"time_available": "night",
		"preferred_tags": ["bizarre", "junk"],
		"desc": "Europe's colossal nocturnal river monster. An apex predator that lurks in deep dark trenches after sundown.",
		"color": Color(0.9, 0.75, 0.3),
		"icon_symbol": "🐟",
		"icon_texture": "res://assets/textures/fish/fish_void_guardian.png",
		"size_range": [200.0, 420.0]
	}
}

const SAVE_PATH: String = "user://bocah_save.json"
const WEB_STORAGE_KEY: String = "bocah_fishing_save_v1"

# Audio Settings
var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0

# Autosave timer
var _autosave_timer: float = 0.0
const AUTOSAVE_INTERVAL: float = 30.0

# Character Database (Skills / Passives)
var character_db: Dictionary = {
	"none": {
		"id": "none",
		"name": "None",
		"cost": 0,
		"portrait": "",
		"desc": "Standard beginner gear. Balanced stats with no buffs or debuffs.",
		"buff_summary": "0% All Stats (Standard)",
		"modifiers": {
			"bar_scale": 1.0,
			"lure_speed": 1.0,
			"resilience": 1.0
		}
	},
	"pak_kumis": {
		"id": "pak_kumis",
		"name": "Pak Kumis",
		"cost": 50,
		"portrait": "res://assets/textures/characters/angler_pak_kumis.png",
		"desc": "Local master with quick-reaction reflexes. Accelerates fish bite interest by 40%.",
		"buff_summary": "+40% Lure Speed",
		"modifiers": {
			"bar_scale": 1.0,
			"lure_speed": 1.4,
			"resilience": 1.0
		}
	},
	"bocah_udik": {
		"id": "bocah_udik",
		"name": "Bocah Udik",
		"cost": 150,
		"portrait": "res://assets/textures/characters/angler_bocah_udik.png",
		"desc": "Patient village boy who knows river bends. Reduces line escape drag and line break penalty.",
		"buff_summary": "+30% Line Resilience",
		"modifiers": {
			"bar_scale": 1.0,
			"lure_speed": 1.0,
			"resilience": 1.3
		}
	},
	"si_bolang": {
		"id": "si_bolang",
		"name": "Si Bolang",
		"cost": 300,
		"portrait": "res://assets/textures/characters/angler_si_bolang.png",
		"desc": "Bold lake wanderer with a wide casting net. Expands the safe catch bar by 25%.",
		"buff_summary": "+25% Catch Bar Safe Zone",
		"modifiers": {
			"bar_scale": 1.25,
			"lure_speed": 1.0,
			"resilience": 1.0
		}
	},
	"mbah_dukun": {
		"id": "mbah_dukun",
		"name": "Mbah Dukun",
		"cost": 600,
		"portrait": "res://assets/textures/characters/angler_mbah_dukun.png",
		"desc": "Mystic elder wielding river amulets. Possesses immense mastery across all angling skills.",
		"buff_summary": "+20% Safe Bar, +30% Lure, +25% Resilience",
		"modifiers": {
			"bar_scale": 1.2,
			"lure_speed": 1.3,
			"resilience": 1.25
		}
	}
}

# Player State
var cahs: int = 0
var selected_character: String = "none"
var unlocked_characters: Array[String] = ["none"]

var equipped_bait: String = "bait_worm"
var inventory: Dictionary = {
	"bait_worm": 1
}

# Unlocked catches for Almanac (initially empty)
var unlocked_catches: Array[String] = []

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_game()

func _ready() -> void:
	_load_period_textures()
	load_game()
	current_period = calculate_period(in_game_time)
	_validate_equipped_bait()
	_setup_web_lifecycle()

func _process(delta: float) -> void:
	in_game_time += delta * TIME_MULTIPLIER
	if in_game_time >= SECONDS_PER_DAY:
		in_game_time = fmod(in_game_time, SECONDS_PER_DAY)
	
	var new_period = calculate_period(in_game_time)
	if new_period != current_period:
		current_period = new_period
		period_changed.emit(current_period)
	
	time_updated.emit(in_game_time)
	
	# Periodic auto-save every 30 seconds
	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		save_game()

func _setup_web_lifecycle() -> void:
	if not OS.has_feature("web"):
		return
	var js = Engine.get_singleton("JavaScriptBridge")
	if not js:
		return
	var script = """
	(function() {
		if (window._bocah_hooks_set) return;
		window._bocah_hooks_set = true;
		var triggerSync = function() {
			if (window.FS && window.FS.syncfs) {
				window.FS.syncfs(false, function(){});
			}
		};
		window.addEventListener('beforeunload', triggerSync);
		window.addEventListener('pagehide', triggerSync);
		window.addEventListener('visibilitychange', function() {
			if (document.visibilityState === 'hidden') triggerSync();
		});
	})();
	"""
	js.eval(script)

func _load_period_textures() -> void:
	for p in PERIOD_CONFIG.keys():
		var path = PERIOD_CONFIG[p].get("texture_path", "")
		if ResourceLoader.exists(path):
			_cached_period_textures[p] = load(path)

func get_current_period_texture() -> Texture2D:
	if _cached_period_textures.has(current_period):
		return _cached_period_textures[current_period]
	var path = PERIOD_CONFIG.get(current_period, {}).get("texture_path", "res://assets/textures/day.jpeg")
	if ResourceLoader.exists(path):
		_cached_period_textures[current_period] = load(path)
		return _cached_period_textures[current_period]
	return null

func calculate_period(time_secs: float) -> String:
	var hour = fmod(time_secs / 3600.0, 24.0)
	if hour >= 6.0 and hour < 18.0:
		return "day"
	else:
		return "night"

func get_time_formatted() -> String:
	var total_minutes = int(in_game_time / 60.0) % 1440
	var hour = int(float(total_minutes) / 60.0)
	var minute = total_minutes % 60
	var config = PERIOD_CONFIG.get(current_period, {"icon": "☀️", "name": "Day"})
	return "%s %02d:%02d" % [config["icon"], hour, minute]

func get_time_clock_only() -> String:
	var total_minutes = int(in_game_time / 60.0) % 1440
	var hour = int(float(total_minutes) / 60.0)
	var minute = total_minutes % 60
	return "%02d:%02d" % [hour, minute]

func get_character_modifiers() -> Dictionary:
	var data = character_db.get(selected_character, character_db["none"])
	return data.get("modifiers", {"bar_scale": 1.0, "lure_speed": 1.0, "resilience": 1.0})

func get_character_prerequisite(char_id: String) -> String:
	match char_id:
		"jia":
			return "none"
		"joe":
			return "jia"
		_:
			return ""

func can_unlock_character(char_id: String) -> bool:
	if not character_db.has(char_id):
		return false
	if unlocked_characters.has(char_id):
		return false
	var prereq = get_character_prerequisite(char_id)
	if not prereq.is_empty() and not unlocked_characters.has(prereq):
		return false
	return true

func buy_character(char_id: String) -> bool:
	if not character_db.has(char_id):
		return false
	if unlocked_characters.has(char_id):
		return select_character(char_id)
	if not can_unlock_character(char_id):
		return false
		
	var cost = character_db[char_id].get("cost", 50)
	if cahs >= cost:
		cahs -= cost
		unlocked_characters.append(char_id)
		selected_character = char_id
		cahs_changed.emit(cahs)
		character_changed.emit(selected_character)
		save_game()
		return true
	return false

func select_character(char_id: String) -> bool:
	if character_db.has(char_id) and unlocked_characters.has(char_id):
		selected_character = char_id
		character_changed.emit(selected_character)
		save_game()
		return true
	return false

func is_character_unlocked(char_id: String) -> bool:
	return unlocked_characters.has(char_id)

func sell_fish(item_id: String, amount: int = 1) -> int:
	var data = get_item_data(item_id)
	if data.is_empty() or data.get("category") != "fish":
		return 0
	var unit_price = data.get("price_cahs", 0)
	if unit_price <= 0:
		return 0
		
	var current_qty = inventory.get(item_id, 0)
	if current_qty <= 0:
		return 0
		
	var to_sell = mini(amount, current_qty)
	var total_earned = to_sell * unit_price
	remove_from_inventory(item_id, to_sell)
	cahs += total_earned
	cahs_changed.emit(cahs)
	save_game()
	return total_earned

func sell_all_fish() -> int:
	var total_earned = 0
	var fish_to_sell: Dictionary = {}
	for item_id in inventory.keys():
		var data = get_item_data(item_id)
		if data.get("category") == "fish":
			var price = data.get("price_cahs", 0)
			if price > 0:
				fish_to_sell[item_id] = inventory[item_id]
				
	for item_id in fish_to_sell.keys():
		var count = fish_to_sell[item_id]
		var price = get_item_data(item_id).get("price_cahs", 0)
		total_earned += count * price
		remove_from_inventory(item_id, count)
		
	if total_earned > 0:
		cahs += total_earned
		cahs_changed.emit(cahs)
		save_game()
	return total_earned

func save_game() -> void:
	var save_data = {
		"version": 2,
		"timestamp": Time.get_unix_time_from_system(),
		"cahs": cahs,
		"selected_character": selected_character,
		"unlocked_characters": unlocked_characters,
		"equipped_bait": equipped_bait,
		"inventory": inventory,
		"unlocked_catches": unlocked_catches,
		"in_game_time": in_game_time,
		"settings": {
			"master_volume": master_volume,
			"music_volume": music_volume,
			"sfx_volume": sfx_volume
		}
	}
	var json_str = JSON.stringify(save_data, "\t")
	
	# 1. Primary Godot user:// storage (FileAccess)
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.flush()
		file.close()
		
	# 2. Web Dual-Storage: Mirror directly to browser localStorage & trigger IDBFS sync
	if OS.has_feature("web"):
		_save_to_web_storage(json_str)

func _save_to_web_storage(json_str: String) -> void:
	if not OS.has_feature("web"):
		return
	var js = Engine.get_singleton("JavaScriptBridge")
	if not js:
		return
	var b64: String = Marshalls.utf8_to_base64(json_str)
	var script = """
	(function() {
		try {
			var raw = decodeURIComponent(escape(atob('%s')));
			localStorage.setItem('%s', raw);
			if (window.FS && window.FS.syncfs) {
				window.FS.syncfs(false, function(err) {
					if (err) console.warn('IDBFS sync warning:', err);
				});
			}
		} catch (e) {
			console.warn('Web storage save error:', e);
		}
	})();
	""" % [b64, WEB_STORAGE_KEY]
	js.eval(script)

func load_game() -> bool:
	var file_data: Dictionary = {}
	var web_data: Dictionary = {}
	
	# 1. Primary: user:// storage
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(content) == OK and typeof(json.get_data()) == TYPE_DICTIONARY:
				file_data = json.get_data()
	
	# 2. Web storage fallback & sync check
	if OS.has_feature("web"):
		var web_str = _load_from_web_storage()
		if web_str != "":
			var web_json = JSON.new()
			if web_json.parse(web_str) == OK and typeof(web_json.get_data()) == TYPE_DICTIONARY:
				web_data = web_json.get_data()
	
	# 3. Choose the most up-to-date or available data
	var chosen_data: Dictionary = {}
	if not file_data.is_empty() and not web_data.is_empty():
		var file_time = float(file_data.get("timestamp", 0.0))
		var web_time = float(web_data.get("timestamp", 0.0))
		if web_time > file_time:
			chosen_data = web_data
		else:
			chosen_data = file_data
	elif not file_data.is_empty():
		chosen_data = file_data
	elif not web_data.is_empty():
		chosen_data = web_data
	else:
		return false
		
	_apply_save_data(chosen_data)
	
	# Auto-heal: If one storage medium was missing, re-save to sync both
	if OS.has_feature("web") and (file_data.is_empty() or web_data.is_empty()):
		save_game()
		
	return true

func _load_from_web_storage() -> String:
	if not OS.has_feature("web"):
		return ""
	var js = Engine.get_singleton("JavaScriptBridge")
	if not js:
		return ""
	var script = """
	(function() {
		try {
			var val = localStorage.getItem('%s');
			if (!val) return '';
			return btoa(unescape(encodeURIComponent(val)));
		} catch (e) {
			console.warn('Web storage load warning:', e);
			return '';
		}
	})()
	""" % WEB_STORAGE_KEY
	var res = js.eval(script)
	if res and typeof(res) == TYPE_STRING and res != "":
		return Marshalls.base64_to_utf8(res)
	return ""

func _apply_save_data(data: Dictionary) -> void:
	cahs = data.get("cahs", data.get("coins", 0))
	selected_character = data.get("selected_character", "none")
	
	var raw_chars = data.get("unlocked_characters", ["none"])
	unlocked_characters.clear()
	for c in raw_chars:
		unlocked_characters.append(str(c))
	if not unlocked_characters.has("none"):
		unlocked_characters.append("none")
		
	inventory = data.get("inventory", {"bait_worm": 1})
	equipped_bait = data.get("equipped_bait", "bait_worm")
	
	var raw_unlocked = data.get("unlocked_catches", [])
	unlocked_catches.clear()
	for id in raw_unlocked:
		unlocked_catches.append(str(id))
		
	in_game_time = float(data.get("in_game_time", 21600.0))
	current_period = calculate_period(in_game_time)
	
	var settings = data.get("settings", {})
	if typeof(settings) == TYPE_DICTIONARY and not settings.is_empty():
		master_volume = float(settings.get("master_volume", 1.0))
		music_volume = float(settings.get("music_volume", 1.0))
		sfx_volume = float(settings.get("sfx_volume", 1.0))
		_apply_audio_volume("Master", master_volume)
		_apply_audio_volume("Music", music_volume)
		_apply_audio_volume("SFX", sfx_volume)

func _apply_audio_volume(bus_name: String, val: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		if val <= 0.001:
			AudioServer.set_bus_mute(bus_idx, true)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(val))

func reset_game_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	if OS.has_feature("web"):
		var js = Engine.get_singleton("JavaScriptBridge")
		if js:
			js.eval("try { localStorage.removeItem('%s'); } catch(e){}" % WEB_STORAGE_KEY)
	cahs = 0
	selected_character = "none"
	unlocked_characters = ["none"]
	inventory = {"bait_worm": 1}
	equipped_bait = "bait_worm"
	unlocked_catches.clear()
	in_game_time = 21600.0
	current_period = calculate_period(in_game_time)
	inventory_updated.emit()
	bait_changed.emit(equipped_bait)
	cahs_changed.emit(cahs)
	character_changed.emit(selected_character)
	period_changed.emit(current_period)
	time_updated.emit(in_game_time)

func _validate_equipped_bait() -> void:
	if equipped_bait.is_empty():
		return
	if not inventory.has(equipped_bait) or inventory[equipped_bait] <= 0:
		equipped_bait = ""
		bait_changed.emit(equipped_bait)

func get_item_data(item_id: String) -> Dictionary:
	return item_db.get(item_id, {})

func get_equipped_bait_data() -> Dictionary:
	return get_item_data(equipped_bait)

func set_equipped_bait(item_id: String) -> bool:
	if item_id.is_empty():
		unequip_bait()
		return true
	if inventory.has(item_id) and inventory[item_id] > 0:
		equipped_bait = item_id
		bait_changed.emit(equipped_bait)
		save_game()
		return true
	return false

func unequip_bait() -> void:
	if not equipped_bait.is_empty():
		equipped_bait = ""
		bait_changed.emit(equipped_bait)
		save_game()

func add_to_inventory(item_id: String, amount: int = 1) -> void:
	if inventory.has(item_id):
		inventory[item_id] += amount
	else:
		inventory[item_id] = amount
	
	if item_db.has(item_id) and item_db[item_id].get("category") == "fish":
		if not unlocked_catches.has(item_id):
			unlocked_catches.append(item_id)
			fish_unlocked.emit(item_id)
			
	inventory_updated.emit()
	save_game()

func remove_from_inventory(item_id: String, amount: int = 1) -> bool:
	if inventory.has(item_id) and inventory[item_id] > 0:
		var current = inventory[item_id]
		var remove_count = mini(amount, current)
		inventory[item_id] -= remove_count
		if inventory[item_id] <= 0:
			inventory.erase(item_id)
			if equipped_bait == item_id:
				var found_new: bool = false
				for k in inventory.keys():
					if inventory[k] > 0:
						set_equipped_bait(k)
						found_new = true
						break
				if not found_new:
					equipped_bait = ""
					bait_changed.emit("")
		inventory_updated.emit()
		save_game()
		return true
	return false

func consume_equipped_bait() -> bool:
	if inventory.has(equipped_bait) and inventory[equipped_bait] > 0:
		inventory[equipped_bait] -= 1
		if inventory[equipped_bait] <= 0:
			inventory.erase(equipped_bait)
			var found_new: bool = false
			for item_id in inventory.keys():
				if inventory[item_id] > 0:
					set_equipped_bait(item_id)
					found_new = true
					break
			if not found_new:
				equipped_bait = ""
				bait_changed.emit("")
		inventory_updated.emit()
		save_game()
		return true
	return false

func is_unlocked(item_id: String) -> bool:
	return unlocked_catches.has(item_id)

func get_almanac_progress() -> Dictionary:
	var total_fishes: int = 0
	var caught_fishes: int = 0
	for item_id in item_db:
		if item_db[item_id].get("category") == "fish":
			total_fishes += 1
			if unlocked_catches.has(item_id):
				caught_fishes += 1
	return {"caught": caught_fishes, "total": total_fishes}

func is_fish_available_now(fish: Dictionary) -> bool:
	var avail = fish.get("time_available", "all")
	if avail == "all" or avail.is_empty():
		return true
	return avail == current_period

# Roll fish bite based on the equipped bait traits and tier
func roll_fish_bite(bait_id: String) -> Dictionary:
	# Bare hook (no bait equipped):
	# 75% chance to hook lake debris/junk, 25% chance to hook a tiny Common fish
	if bait_id.is_empty() or not item_db.has(bait_id):
		var junk_roll = randf()
		if junk_roll < 0.75:
			var junk_keys = ["bait_boot", "bait_can", "bait_seaweed", "bait_sock", "bait_coin", "bait_battery"]
			var valid_junks: Array[Dictionary] = []
			for k in junk_keys:
				if item_db.has(k):
					valid_junks.append(item_db[k])
			if not valid_junks.is_empty():
				valid_junks.shuffle()
				return valid_junks[0]
				
		var common_fish: Array[Dictionary] = []
		for key in item_db:
			var item = item_db[key]
			if item.get("category") == "fish" and item.get("tier") == 1:
				if is_fish_available_now(item):
					common_fish.append(item)
		if not common_fish.is_empty():
			common_fish.shuffle()
			return common_fish[0]
		# Fallback if none found for current period
		for key in item_db:
			if item_db[key].get("category") == "fish" and item_db[key].get("tier") == 1:
				common_fish.append(item_db[key])
		if not common_fish.is_empty():
			common_fish.shuffle()
			return common_fish[0]
			
	var bait_data = get_item_data(bait_id)
	var bait_tier = bait_data.get("tier", 1)
	var bait_category = bait_data.get("category", "bait")
	
	# Determine target fish tier probabilities
	var roll = randf() # 0.0 to 1.0
	var target_tier: int = 1
	
	if bait_category == "fish":
		# Using a fish as bait unlocks high tier catches!
		if bait_tier >= 3:
			# Tier 3/4 fish as bait -> High Epic & Legendary!
			if roll < 0.40:
				target_tier = 5
			elif roll < 0.85:
				target_tier = 4
			else:
				target_tier = 3
		elif bait_tier == 2:
			# Tier 2 fish as bait -> Rare, Epic, or Legendary
			if roll < 0.20:
				target_tier = 5
			elif roll < 0.60:
				target_tier = 4
			else:
				target_tier = 3
		else:
			# Tier 1 fish as bait -> Uncommon to Epic
			if roll < 0.10:
				target_tier = 4
			elif roll < 0.55:
				target_tier = 3
			else:
				target_tier = 2
	else:
		# Regular items
		if bait_tier == 2: # Battery, Coin, Sock
			if roll < 0.15:
				target_tier = 4
			elif roll < 0.50:
				target_tier = 3
			elif roll < 0.85:
				target_tier = 2
			else:
				target_tier = 1
		else: # Common starter baits (worm, bread, apple)
			if roll < 0.05:
				target_tier = 3
			elif roll < 0.35:
				target_tier = 2
			else:
				target_tier = 1
				
	# Pick a fish of target_tier matching current period (day/night)
	var candidates: Array[Dictionary] = []
	for key in item_db:
		var item = item_db[key]
		if item.get("category") == "fish" and item.get("tier") == target_tier:
			if is_fish_available_now(item):
				candidates.append(item)
			
	if candidates.is_empty():
		# Fallback to any fish matching current period
		for key in item_db:
			var item = item_db[key]
			if item.get("category") == "fish" and is_fish_available_now(item):
				candidates.append(item)
				
	if candidates.is_empty():
		# Fallback to any fish
		for key in item_db:
			if item_db[key].get("category") == "fish":
				candidates.append(item_db[key])
				
	candidates.shuffle()
	return candidates[0]
