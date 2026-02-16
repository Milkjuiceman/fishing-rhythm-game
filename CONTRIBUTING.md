Prerequisites and SetupRequired Tools
- Godot 4.5 - Game engine
- Github - Version control

Initial Setup Steps
- Clone the repository:
- Install Godot 4.5 from godotengine.org
- Open the project in Godot
- Launch Godot 4.5
- Click "Import"
- Navigate to the project directory
- Select project.godot

Run project
- Open Project and click run

Code Review
- We do manual review of each code push

Local Commands for CI/Linting/Formatting
- Since our project uses GDScript in Godot 4.5, we don't have traditional CI pipeline commands, but we maintain code quality through the following local checks.

Manual Linting Checklist
- Before committing, verify your code follows these standards:
  
gdscript# 
var player_speed = 100  # snake_case for variables
func calculate_damage():  # snake_case for functions
const MAX_HEALTH = 100  # CONSTANT_CASE for constants

# Proper indentation 
func _ready():
	if player:
		player.connect("died", self, "_on_player_died")

Branching Expectations
- It is important that when you want to add a feature you must create a new branch in order to do so.

What is our DOD?
- Here is a link you can refrence for our DOD https://docs.google.com/document/d/1xe2NCuPyU2VAraY-pvqrAXdqtqIMJ__RljOLvT759so/edit?usp=sharing 

How to report bugs?
- Go to issues and submit a new issue request

Where to ask for help?
- Contact our project lead at tottenco@oregonstate.edu
