extends Resource
class_name RhythmLevelEntry
## A single rhythm level entry for a RipplingWaterSpawner.
## Add these to the spawner's `rhythm_levels` array in the Inspector.

## Path to the rhythm level scene (e.g. "res://scenes/musiclevel/rhythm_level_easy.tscn")
@export_file("*.tscn") var scene_path: String = ""

## Chance (out of 100) that this level is chosen when a water spot spawns.
## All entries on a spawner should add up to 100.
@export_range(0.0, 100.0, 0.5) var chance: float = 100.0

## Unique identifier for the fish this rhythm level rewards when caught.
## Must exactly match a fish_id in FishRegistry's FISH_DATA.
## Example: "fish_1", "fjord_fish_1"
@export var fish_id: String = ""
