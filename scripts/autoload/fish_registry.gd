extends Node
## FishRegistry Autoload
## Single source of truth for every fish in the game.
## Each fish maps to a unique rhythm level scene.
## Add new fish here as new rhythm levels are created.
## Author: [your name]
## Date of last update: 04/22/2026

# ========================================
# DATA STRUCTURES
# ========================================

## Represents a single fish entry in the encyclopedia.
## fish_id must exactly match what RhythmLevelEntry.fish_id is set to in the Inspector.
const FISH_DATA: Array = [
	{
		"area": "Tutorial Lake",
		"fish": [
			{ "fish_id": "fish_1", "display_name": "Fish 1" },
			{ "fish_id": "fish_2", "display_name": "Fish 2" },
			{ "fish_id": "fish_3", "display_name": "Fish 3" },
		]
	},
	{
		"area": "Second Area",
		"fish": [
			{ "fish_id": "temp_fish_1", "display_name": "Temp Fish 1" },
			{ "fish_id": "temp_fish_2", "display_name": "Temp Fish 2" },
			{ "fish_id": "temp_fish_3", "display_name": "Temp Fish 3" },
			{ "fish_id": "temp_fish_4", "display_name": "Temp Fish 4" },
			{ "fish_id": "temp_fish_5", "display_name": "Temp Fish 5" },
		]
	},
]

# ========================================
# PUBLIC API
# ========================================

## Returns the full FISH_DATA array (all areas and their fish).
func get_all_areas() -> Array:
	return FISH_DATA

## Returns the display name for a given fish_id, or the fish_id itself if not found.
func get_display_name(fish_id: String) -> String:
	for area in FISH_DATA:
		for fish in area["fish"]:
			if fish["fish_id"] == fish_id:
				return fish["display_name"]
	return fish_id

## Returns the area name for a given fish_id, or "" if not found.
func get_area(fish_id: String) -> String:
	for area in FISH_DATA:
		for fish in area["fish"]:
			if fish["fish_id"] == fish_id:
				return area["area"]
	return ""
