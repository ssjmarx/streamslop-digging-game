## Dumps the pinned 4.7.2 signatures for the step-slide API: body_test_motion
## args, and the PhysicsTestMotionParameters3D / PhysicsTestMotionResult3D
## members -- engine truth before player_controller touches them.
extends SceneTree


## Print the exact pinned signatures, then quit clean.
func _initialize() -> void:
	for m in ClassDB.class_get_method_list("PhysicsServer3D", true):
		if m.name == "body_test_motion":
			print("body_test_motion: ", m)
	for prop in ClassDB.class_get_property_list("PhysicsTestMotionParameters3D", true):
		print("params.", prop.name, " (", prop.type, ")")
	for m in ClassDB.class_get_method_list("PhysicsTestMotionResult3D", true):
		print("result.", m.name, "()")
	quit(0)
