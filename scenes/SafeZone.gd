extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_exited(body):
	print("BodyExited: ",body)
	if body.is_in_group("enemy"):
		body.kill();
	pass # Replace with function body.
