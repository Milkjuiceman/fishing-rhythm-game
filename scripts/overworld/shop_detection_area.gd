extends Area3D

var popup_scene = preload("res://scenes/ui/boatUpgradePopup.tscn")
var shop_scene = preload("res://scenes/ui/boatUpgradeStore.tscn")
var popup = null
var shop = null
var player_in_area = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# Check if it's a boat (works for Boat, BoatBig, etc.)
	if body is Boat:
		# Create and add the popup message
		popup = popup_scene.instantiate()
		get_tree().root.add_child(popup)
		player_in_area = true

func _on_body_exited(body):
	# Check if it's a boat
	if body is Boat:
		# Remove the popup message
		if popup != null:
			popup.queue_free()
			popup = null
		player_in_area = false

func _process(_delta):
	# When player presses Enter while in the area, open the shop
	if player_in_area and Input.is_action_just_pressed("ui_accept"):
		open_shop()

func open_shop():
	print("Opening shop!")
	
	# Remove the popup message
	if popup != null:
		popup.queue_free()
		popup = null
	
	# Don't open shop if it's already open
	if shop != null:
		return
	
	# Create and add the shop UI
	shop = shop_scene.instantiate()
	get_tree().root.add_child(shop)
	
	# Pause the game while shop is open
	get_tree().paused = true
	
	# Connect to shop's close signal if it exists
	if shop.has_signal("shop_closed"):
		shop.shop_closed.connect(_on_shop_closed)

func _on_shop_closed():
	# Unpause the game
	get_tree().paused = false
	
	# Clean up shop
	if shop != null:
		shop.queue_free()
		shop = null
	
	# Re-show popup if player is still in area
	if player_in_area and popup == null:
		popup = popup_scene.instantiate()
		get_tree().root.add_child(popup)
