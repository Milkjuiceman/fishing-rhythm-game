extends Control

var rating_scene = preload("uid://wuqf1ag86k")

var is_connected = false

func _on_referee_process(frame_state: FrameState) -> void:
	var scorecard = frame_state.scorecard
	if scorecard and not is_connected:
		scorecard.connect("rating_hit", Callable(self, "show_rating"))
		is_connected = true
		
	

func show_rating(text: String):
	var rating = rating_scene.instantiate()
	rating.text = text
	
	add_child(rating)
	
	var area_size = size
	var label_size = rating.size
	
	var rand_x = randf_range(0, area_size.x - label_size.x)
	var rand_y = randf_range(0, area_size.y - label_size.y)
	
	rating.position = Vector2(rand_x, rand_y)
	
	if text == "Perfect":
		rating.modulate = Color(0, 1, 0)
	elif text == "Good":
		rating.modulate = Color(0.0, 0.0, 2.107, 1.0)
	elif text == "Bad":
		rating.modulate = Color(0.572, 0.0, 0.573, 1.0)
	elif text == "Miss":
		rating.modulate = Color(1.0, 0.0, 0.0, 1.0)
	
	animate_and_destroy(rating)


func animate_and_destroy(label: Label):
	var tween = create_tween()
	
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.parallel().tween_property(label, "position:y", label.position.y - 30, 0.6)
	
	await tween.finished
	label.queue_free()
