extends Area3D
## Shop Detection Area
## Displays interaction prompt when player enters and opens boat upgrade shop on input
## Handles popup visibility and shop UI lifecycle with pause management

# ========================================
# SCENE REFERENCES
# ========================================

var popup_scene = preload("res://scenes/ui/boatUpgradePopup.tscn")
var shop_scene = preload("res://scenes/ui/boatUpgradeStore.tscn")

# ========================================
# VARIABLES
# ========================================

var popup = null  # Current popup instance
var shop = null  # Current shop instance
var player_in_area = false  # Track if player is in shop range
var _current_boat: Boat = null  # Reference to boat for SFX control

# ========================================
# INITIALIZATION
# ========================================

func _ready():
	# Connect collision detection signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

# ========================================
# COLLISION DETECTION
# ========================================

# Show interaction prompt when boat enters area
func _on_body_entered(body):
	# Only respond to boat collisions
	if body is Boat:
		_current_boat = body
		# Display interaction popup
		popup = popup_scene.instantiate()
		get_tree().root.add_child(popup)
		player_in_area = true

# Hide interaction prompt when boat leaves area
func _on_body_exited(body):
	# Only respond to boat collisions
	if body is Boat:
		_current_boat = null
		# Remove popup if it exists
		if popup != null:
			popup.queue_free()
			popup = null
		player_in_area = false

# ========================================
# INPUT HANDLING
# ========================================

func _process(_delta):
	# Open shop when player presses interact key while in area
	if player_in_area and Input.is_action_just_pressed("ui_accept"):
		open_shop()

# ========================================
# SHOP MANAGEMENT
# ========================================

# Open the boat upgrade shop UI
func open_shop():
	print("Opening shop!")
	
	# Stop boat engine sounds when entering shop
	if _current_boat:
		_current_boat.stop_engine_sounds()
	
	# Hide interaction popup
	if popup != null:
		popup.queue_free()
		popup = null
	
	# Prevent opening multiple shop instances
	if shop != null:
		return
	
	# Create and display shop UI
	shop = shop_scene.instantiate()
	get_tree().root.add_child(shop)
	
	# Pause game during shopping
	get_tree().paused = true
	
	# Connect shop close signal for cleanup
	if shop.has_signal("shop_closed"):
		shop.shop_closed.connect(_on_shop_closed)

# Handle shop closing and cleanup
func _on_shop_closed():
	# Resume game
	get_tree().paused = false
	
	# Remove shop UI
	if shop != null:
		shop.queue_free()
		shop = null
	
	# Start boat engine sounds when exiting shop
	if _current_boat:
		_current_boat.start_engine_sounds()
	# Also check if boat changed (from shop purchase)
	elif player_in_area:
		# Try to find the new boat
		var bodies = get_overlapping_bodies()
		for body in bodies:
			if body is Boat:
				_current_boat = body
				_current_boat.start_engine_sounds()
				break
	
	# Restore interaction prompt if player still in area
	if player_in_area and popup == null:
		popup = popup_scene.instantiate()
		get_tree().root.add_child(popup)
