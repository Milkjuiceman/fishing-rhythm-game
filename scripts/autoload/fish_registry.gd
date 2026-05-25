extends Node
## FishRegistry Autoload
## Single source of truth for every fish in the game.
## fish_id must exactly match what is set on the rhythm level scene's root node.
## Display names follow the format: "(Song Name) Fish"
## Author: Tyler Schauermann
## Date of last update: 05/23/2026

const FISH_DATA: Array = [
	# ── Tutorial Lake ────────────────────────────────────────────────────
	# Scenes: tut_area1, tut_area2, tut_area3, tut_area4
	{
		"area": "Tutorial Lake",
		"fish": [
			{ "fish_id": "lyonesse_fish",              "display_name": "Lyonesse Fish" },
			{ "fish_id": "grand_project_children_fish", "display_name": "Grand Project Children Fish" },
			{ "fish_id": "yellow_forest_fish",         "display_name": "Yellow Forest Fish" },
			{ "fish_id": "rolling_at_5_fish",          "display_name": "Rolling at 5-210 Fish" },
		]
	},
	# ── Intersection Area ────────────────────────────────────────────────
	# Scenes: int_area1, int_area2
	{
		"area": "Intersection Area",
		"fish": [
			{ "fish_id": "new_hope_fish",               "display_name": "New Hope Fish" },
			{ "fish_id": "grand_project_mexican_fish",  "display_name": "Grand Project Mexican Fish" },
		]
	},
	# ── Fjord Area ───────────────────────────────────────────────────────
	# Scenes: fjord1, fjord2, fjord3 (normal) | fjord4, fjord5 (boss)
	{
		"area": "Fjord Area",
		"fish": [
			{ "fish_id": "markalo_disco_fish",          "display_name": "Markalo Goes to the Disco Fish" },
			{ "fish_id": "rgmp_01_fish",                "display_name": "Rgmp_01 Fish" },
		]
	},
	# ── Fjord Bosses ─────────────────────────────────────────────────────
	# Scenes: fjord4 (Rgmp_08), fjord5 (Humble match)
	{
		"area": "Fjord Bosses",
		"fish": [
			{ "fish_id": "child_nightmare_boss",        "display_name": "Child Nightmare Boss" },
			{ "fish_id": "rgmp_08_boss",                "display_name": "Rgmp_08 Boss" },
			{ "fish_id": "humble_match_boss",           "display_name": "Humble Match Boss" },
		]
	},
	# ── Quarry Area ──────────────────────────────────────────────────────
	# Scenes: Quary1 (Rgmp_02), Quary2 (Rgmp_03) (normal) | Quary3 (Rgmp_05) (boss)
	{
		"area": "Quarry Area",
		"fish": [
			{ "fish_id": "rgmp_02_fish",                "display_name": "Rgmp_02 Fish" },
			{ "fish_id": "rgmp_03_fish",                "display_name": "Rgmp_03 Fish" },
		]
	},
	# ── Quarry Bosses ────────────────────────────────────────────────────
	# Scenes: Quary3 (Rgmp_05)
	{
		"area": "Quarry Bosses",
		"fish": [
			{ "fish_id": "rgmp_05_boss",                "display_name": "Rgmp_05 Boss" },
		]
	},
	# ── Delta Area ───────────────────────────────────────────────────────
	# Scenes: Delta1 (Tunetank), Delta2 (Paulyudin), Delta3 (Rgmp_04), Delta4 (Rgmp_06)
	{
		"area": "Delta Area",
		"fish": [
			{ "fish_id": "tunetank_medieval_fish",      "display_name": "Tunetank Medieval Festive Fish" },
			{ "fish_id": "paulyudin_happy_fish",        "display_name": "Paulyudin Happy Fish" },
			{ "fish_id": "rgmp_04_fish",                "display_name": "Rgmp_04 Fish" },
			{ "fish_id": "rgmp_06_fish",                "display_name": "Rgmp_06 Fish" },
		]
	},
	# ── Delta Bosses ─────────────────────────────────────────────────────
	# Scenes: Delta5 (Rgmp_07)
	{
		"area": "Delta Bosses",
		"fish": [
			{ "fish_id": "rgmp_07_boss",                "display_name": "Rgmp_07 Boss (Final)" },
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
