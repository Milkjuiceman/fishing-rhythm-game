extends Label3D

func _process(delta):
	var cam = get_viewport().get_camera_3d()
	if cam:
		var dir = (cam.global_transform.origin - global_transform.origin)
		dir.x = 0  # ignore vertical rotation
		look_at(global_transform.origin + dir, Vector3.UP)
