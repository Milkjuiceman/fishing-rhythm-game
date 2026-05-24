extends Node
## FishRegistry Autoload
## Single source of truth for every fish in the game.
## fish_id must exactly match what RhythmLevelEntry.fish_id is set to in the Inspector.
## Author: Tyler Schauermann
## Date of last update: 05/23/2026

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
		"area": "Intersection Area",
		"fish": [
			{ "fish_id": "intersection_fish_1", "display_name": "Intersection Fish 1" },
			{ "fish_id": "intersection_fish_2", "display_name": "Intersection Fish 2" },
			{ "fish_id": "intersection_fish_3", "display_name": "Intersection Fish 3" },
		]
	},
	{
		"area": "Fjord Area",
		"fish": [
			{ "fish_id": "fjord_fish_1", "display_name": "Fjord Fish 1" },
			{ "fish_id": "fjord_fish_2", "display_name": "Fjord Fish 2" },
			{ "fish_id": "fjord_fish_3", "display_name": "Fjord Fish 3" },
		]
	},
	{
		"area": "Mine Area",
		"fish": [
			{ "fish_id": "mine_fish_1", "display_name": "Mine Fish 1" },
			{ "fish_id": "mine_fish_2", "display_name": "Mine Fish 2" },
			{ "fish_id": "mine_fish_3", "display_name": "Mine Fish 3" },
		]
	},
	{
		"area": "Delta Area",
		"fish": [
			{ "fish_id": "delta_fish_1", "display_name": "Delta Fish 1" },
			{ "fish_id": "delta_fish_2", "display_name": "Delta Fish 2" },
			{ "fish_id": "delta_fish_3", "display_name": "Delta Fish 3" },
		]
	},
]

func get_all_areas() -> Array:
	return FISH_DATA

func get_display_name(fish_id: String) -> String:
	for area in FISH_DATA:
		for fish in area["fish"]:
			if fish["fish_id"] == fish_id:
				return fish["display_name"]
	return fish_id

func get_area(fish_id: String) -> String:
	for area in FISH_DATA:
		for fish in area["fish"]:
			if fish["fish_id"] == fish_id:
				return area["area"]
	return ""
