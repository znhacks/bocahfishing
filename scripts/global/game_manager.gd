extends Node

# Autoload: GameManager
# Bocah Fishing - Everything is Bait!

signal bait_changed(new_bait_id: String)
signal inventory_updated()
signal fish_unlocked(fish_id: String)
signal cahs_changed(new_cahs: int)
signal character_changed(new_char_id: String)

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
		"name": "Pebble Guppy",
		"category": "fish",
		"tier": 1,
		"price_cahs": 1,
		"preferred_tags": ["organic", "wiggly"],
		"desc": "A tiny, cheerful swimmer found near sunlit pebbles.",
		"color": Color(0.7, 0.8, 0.85),
		"icon_symbol": "🐟",
		"size_range": [5.0, 12.0]
	},
	"fish_wader": {
		"id": "fish_wader",
		"name": "Lake Minnow",
		"category": "fish",
		"tier": 1,
		"price_cahs": 1,
		"preferred_tags": ["organic", "carbs"],
		"desc": "An energetic little swimmer. Makes prime live bait for bigger fish!",
		"color": Color(0.6, 0.8, 0.7),
		"icon_symbol": "🐟",
		"size_range": [8.0, 16.0]
	},
	"fish_sleepy_carp": {
		"id": "fish_sleepy_carp",
		"name": "Sleepy Carp",
		"category": "fish",
		"tier": 1,
		"price_cahs": 2,
		"preferred_tags": ["sweet", "carbs"],
		"desc": "Calm and slow-moving, it loves lazy morning nibbles.",
		"color": Color(0.8, 0.7, 0.5),
		"icon_symbol": "🐠",
		"size_range": [18.0, 32.0]
	},

	# --- Tier 2 Fish (Uncommon - Green: 3-4 Cahs) ---
	"fish_mossy_perch": {
		"id": "fish_mossy_perch",
		"name": "Mossy Perch",
		"category": "fish",
		"tier": 2,
		"price_cahs": 3,
		"preferred_tags": ["organic", "fruit"],
		"desc": "Camouflaged among lilypads. Bites quickly with playful agility.",
		"color": Color(0.35, 0.75, 0.4),
		"icon_symbol": "🐟",
		"size_range": [22.0, 42.0]
	},
	"fish_lele": {
		"id": "fish_lele",
		"name": "Whiskered Mud Catfish",
		"category": "fish",
		"tier": 2,
		"price_cahs": 3,
		"preferred_tags": ["stinky", "junk"],
		"desc": "Lurks along the muddy lake bed. Drawn to pungent, stinky junk.",
		"color": Color(0.4, 0.38, 0.3),
		"icon_symbol": "🐡",
		"size_range": [30.0, 65.0]
	},
	"fish_mas": {
		"id": "fish_mas",
		"name": "Golden Carp",
		"category": "fish",
		"tier": 2,
		"price_cahs": 4,
		"preferred_tags": ["sweet", "fruit", "shiny"],
		"desc": "Its scales shimmer with golden warmth. Considered good luck by anglers.",
		"color": Color(1.0, 0.65, 0.1),
		"icon_symbol": "🐠",
		"size_range": [25.0, 50.0]
	},

	# --- Tier 3 Fish (Rare - Blue: 5-6 Cahs) ---
	"fish_glimmer_trout": {
		"id": "fish_glimmer_trout",
		"name": "Glimmer Trout",
		"category": "fish",
		"tier": 3,
		"price_cahs": 5,
		"preferred_tags": ["shiny", "metal", "organic"],
		"desc": "A swift, reflective fish that darts like quicksilver.",
		"color": Color(0.3, 0.7, 0.95),
		"icon_symbol": "🐟",
		"size_range": [38.0, 72.0]
	},
	"fish_gabus": {
		"id": "fish_gabus",
		"name": "Hunter Pike",
		"category": "fish",
		"tier": 3,
		"price_cahs": 6,
		"preferred_tags": ["organic", "shiny"],
		"desc": "Fierce freshwater hunter. Highly attracted to live bait like minnows.",
		"color": Color(0.3, 0.55, 0.4),
		"icon_symbol": "🦈",
		"size_range": [45.0, 85.0]
	},

	# --- Tier 4 Fish (Epic - Purple: 7-8 Cahs) ---
	"fish_belut_listrik": {
		"id": "fish_belut_listrik",
		"name": "Neon Storm Eel",
		"category": "fish",
		"tier": 4,
		"price_cahs": 7,
		"preferred_tags": ["electric", "bizarre"],
		"desc": "Glows with bioluminescent current. Attracted to rusty batteries!",
		"color": Color(0.7, 0.3, 0.95),
		"icon_symbol": "⚡",
		"size_range": [70.0, 130.0]
	},
	"fish_abyssal_snapper": {
		"id": "fish_abyssal_snapper",
		"name": "Abyssal Snapper",
		"category": "fish",
		"tier": 4,
		"price_cahs": 8,
		"preferred_tags": ["junk", "stinky", "shiny"],
		"desc": "A prehistoric scavenger from the deepest trenches of the lake.",
		"color": Color(0.55, 0.2, 0.7),
		"icon_symbol": "🐊",
		"size_range": [80.0, 160.0]
	},

	# --- Tier 5 Fish (Legendary - Gold: 10 Cahs) ---
	"fish_raksasa_kuno": {
		"id": "fish_raksasa_kuno",
		"name": "Silent Lake Leviathan",
		"category": "fish",
		"tier": 5,
		"price_cahs": 10,
		"preferred_tags": ["shiny", "electric"],
		"desc": "Ancient mythical titan of the lake. Only bites when apex bait is hooked!",
		"color": Color(1.0, 0.85, 0.2),
		"icon_symbol": "🐉",
		"size_range": [180.0, 350.0]
	},
	"fish_void_guardian": {
		"id": "fish_void_guardian",
		"name": "Ancient Void Guardian",
		"category": "fish",
		"tier": 5,
		"price_cahs": 10,
		"preferred_tags": ["bizarre", "junk"],
		"desc": "A legendary celestial being resting under the dark lake mirror.",
		"color": Color(1.0, 0.75, 0.3),
		"icon_symbol": "✨",
		"size_range": [220.0, 420.0]
	}
}

const SAVE_PATH: String = "user://bocah_save.json"

# Character Database (Skills / Passives)
var character_db: Dictionary = {
	"none": {
		"id": "none",
		"name": "None",
		"cost": 0,
		"portrait": "",
		"desc": "Default angler with standard techniques.",
		"buff_summary": "0% All Stats (Standard)",
		"modifiers": {
			"bar_scale": 1.0,
			"lure_speed": 1.0,
			"resilience": 1.0
		}
	},
	"jia": {
		"id": "jia",
		"name": "Jia",
		"cost": 50,
		"portrait": "res://assets/player/Jia.png",
		"desc": "Energetic & sharp. Sweeps a wider catch zone and lures fish fast.",
		"buff_summary": "+15% Bar Width • +20% Lure Speed • -5% Resilience",
		"modifiers": {
			"bar_scale": 1.15,
			"lure_speed": 1.20,
			"resilience": 0.95
		}
	},
	"joe": {
		"id": "joe",
		"name": "Joe",
		"cost": 50,
		"portrait": "res://assets/player/Joe.png",
		"desc": "Patient & steadfast. Keeps a rock-solid grip against escaping thrashing.",
		"buff_summary": "+10% Lure Speed • +10% Resilience • -10% Bar Width",
		"modifiers": {
			"bar_scale": 0.90,
			"lure_speed": 1.10,
			"resilience": 1.10
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

func _ready() -> void:
	load_game()
	_validate_equipped_bait()

func get_character_modifiers() -> Dictionary:
	var data = character_db.get(selected_character, character_db["none"])
	return data.get("modifiers", {"bar_scale": 1.0, "lure_speed": 1.0, "resilience": 1.0})

func buy_character(char_id: String) -> bool:
	if not character_db.has(char_id):
		return false
	if unlocked_characters.has(char_id):
		return select_character(char_id)
		
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
		"cahs": cahs,
		"selected_character": selected_character,
		"unlocked_characters": unlocked_characters,
		"equipped_bait": equipped_bait,
		"inventory": inventory,
		"unlocked_catches": unlocked_catches
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_str = JSON.stringify(save_data, "\t")
		file.store_string(json_str)
		file.close()

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
		
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(content)
	if parse_result != OK:
		return false
		
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		return false
		
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
		
	return true

func reset_game_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	cahs = 0
	selected_character = "none"
	unlocked_characters = ["none"]
	inventory = {"bait_worm": 1}
	equipped_bait = "bait_worm"
	unlocked_catches.clear()
	inventory_updated.emit()
	bait_changed.emit(equipped_bait)
	cahs_changed.emit(cahs)
	character_changed.emit(selected_character)

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
				
	# Pick a fish of target_tier
	var candidates: Array[Dictionary] = []
	for key in item_db:
		var item = item_db[key]
		if item.get("category") == "fish" and item.get("tier") == target_tier:
			candidates.append(item)
			
	if candidates.is_empty():
		# Fallback to any fish
		for key in item_db:
			if item_db[key].get("category") == "fish":
				candidates.append(item_db[key])
				
	candidates.shuffle()
	return candidates[0]
