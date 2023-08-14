extends Node3D

@onready var raycasts: Node3D = $Raycasts

# Called when the node enters the scene tree for the first time.
func fire():
	if Input.is_action_just_pressed("fire"):
		for r in raycasts.get_children():
			pass

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
